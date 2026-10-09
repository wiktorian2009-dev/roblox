-- PlowService (2026-10-04, Claude): server side of the snowplow loop.
--   * personal part offers (roll / buy / reserve / reroll), owned parts and the selected build - saved through DataService (data.Plow)
--   * garage equip / unequip, and the vehicle itself (spawn at a safe spot, seat, cleanup, recover)
--   * field clearing is done by SnowFieldService from the vehicle registered in PlowRegistry
-- Every request is validated here; clients only ask. Studio tests: ServerStorage.BalanceTestMode = true.
-- 2026-10-05 (Claude): 90-part catalog. Offers come from C.OfferPool (progression band + luck, practical floor) with bad-luck protection
-- (p.Dry counts rolls in a row without a useful offer). Unequip returns a slot to its free starter part, so a plow can always drive.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local C = require(RS:WaitForChild("PlowConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Registry = require(script.Parent:WaitForChild("PlowRegistry"))
local Assembly = require(RS:WaitForChild("PlowAssembly"))
local Format = require(RS:WaitForChild("NumberFormat"))
local TEST = RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true
if TEST then RS:SetAttribute("PlowTestHooks", true) end
local rng = Random.new()

local function remote(class, name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = RS end
	return r
end
local fn, ev = remote("RemoteFunction", "PlowRemote"), remote("RemoteEvent", "PlowEvent")
local folder = workspace:FindFirstChild("Snowplows") or Instance.new("Folder")
folder.Name = "Snowplows"; folder.Parent = workspace

-- vehicles never block other players: vehicles and characters live in groups that do not collide with each other
for _, name in ipairs({"PlowVehicle", "PlowPlayers"}) do pcall(function() PhysicsService:RegisterCollisionGroup(name) end) end
pcall(function() PhysicsService:CollisionGroupSetCollidable("PlowVehicle", "PlowPlayers", false) end)
local function groupCharacter(char)
	for _, d in ipairs(char:GetDescendants()) do if d:IsA("BasePart") then d.CollisionGroup = "PlowPlayers" end end
	char.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then d.CollisionGroup = "PlowPlayers" end end)
end
local function watchPlayer(pl)
	-- 2026-10-05 (drift): Left Shift is the drift key while driving, so Roblox shift-lock is paused while seated (only the server may set this)
	pl:GetAttributeChangedSignal("PlowDriving"):Connect(function()
		pcall(function() pl.DevEnableMouseLock = pl:GetAttribute("PlowDriving") ~= true and game:GetService("StarterPlayer").EnableMouseLockOption end)
	end)
	pl.CharacterAdded:Connect(groupCharacter)
	if pl.Character then groupCharacter(pl.Character) end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, pl in ipairs(Players:GetPlayers()) do watchPlayer(pl) end

local RANK = {}
for i, r in ipairs(C.Rarities) do RANK[r.Id] = i end
local cooldown, lastCall = {}, {}
local function fail(msg, extra) local r = extra or {}; r.ok = false; r.msg = msg; return r end

--------------------------------------------------
-- shop state
--------------------------------------------------
local function snapshot(player, d)
	local p = d.Plow
	local function pub(o) if not o then return nil end return {Part = o.Part, Token = o.Token, Price = C.OfferPrice(o), ExpiresAt = o.ExpiresAt, Left = o.Left, Protected = o.Protected} end
	local parts = {}
	for id, n in pairs(p.Parts) do parts[id] = n end
	local levels = {}
	for id, L in pairs(type(p.Levels) == "table" and p.Levels or {}) do levels[id] = L end
	return {Mode = C.Mode, Parts = parts, Levels = levels, Build = {Blade = p.Build.Blade, Engine = p.Build.Engine, Gear = p.Build.Gear, Body = p.Build.Body},
		Offers = {["1"] = pub(p.Offers["1"]), ["2"] = pub(p.Offers["2"]), ["3"] = pub(p.Offers["3"])}, Reserved = pub(p.Reserved), InGarage = player:GetAttribute("InGarage") == true, Snow = d.Snow, Cooldown = math.max(0, (cooldown[player] or 0) - os.clock()),
		Driving = Registry.Active[player] ~= nil, TutorialDone = p.TutorialDone == true, Tutorial = type(p.Tutorial) == "table" and p.Tutorial or nil,
		Band = C.BandFrom(type(d.Stages) == "table" and d.Stages or {}), Luck = math.max(1, (tonumber(d.Luck) or 1) * (player:GetAttribute("LuckMult") or 1)), Dry = p.Dry or 0}
end
local mods
local function playerLuck(player, d)
	return math.max(1, (tonumber(d.Luck) or 1) * (player:GetAttribute("LuckMult") or 1))
end
local function playerBand(d)
	return C.BandFrom(type(d.Stages) == "table" and d.Stages or {})
end
-- best owned build for the player's current stage, and whether a part would improve productive clearing there
local function bestScore(p, stage, m, slot, candidate)
	local best = 0
	local build = {Blade = p.Build.Blade or C.Starter.Blade, Engine = p.Build.Engine or C.Starter.Engine, Gear = p.Build.Gear or C.Starter.Gear, Body = p.Build.Body or C.Starter.Body}
	if candidate then build[slot] = candidate; return C.Score(C.StatsFor(build, m), stage) end
	for id, n in pairs(p.Parts) do
		local def = C.Parts[id]
		if def and def.Slot == slot and n > 0 and def.Role ~= "P" then -- task 8: paid (game pass) parts are not the useful-offer baseline
			build[slot] = id
			best = math.max(best, C.Score(C.StatsFor(build, m), stage))
		end
	end
	return best
end
local function isUseful(player, d, id)
	local p, def = d.Plow, C.Parts[id]
	if not def or (p.Parts[id] or 0) > 0 then return false end
	local stage = C.Bands[playerBand(d)]
	local m = mods(player)
	return bestScore(p, stage, m, def.Slot, id) > bestScore(p, stage, m, def.Slot) * 1.03
end
-- rebalance 2026-10-05: Snow the player can reasonably earn soon (in hand + ProtectAffordMinutes of recent validated Snow/s), used so
-- bad-luck protection hands out a useful part they can actually afford instead of an hours-away showpiece
local okBoosts, Boosts = pcall(function() return require(script.Parent:WaitForChild("BoostService", 10)) end)
if not okBoosts then Boosts = nil end
local function soonBudget(player, d)
	local rate = 0
	if Boosts then
		local ok, _, a = pcall(Boosts.Profile, player)
		if ok and type(a) == "table" then rate = tonumber(a.Rate) or 0 end
	end
	if rate ~= rate or rate == math.huge then rate = 0 end
	return math.max(0, tonumber(d.Snow) or 0) + rate * 60 * (C.Shop.ProtectAffordMinutes or 10)
end
local function pickPart(player, d)
	local pool = C.OfferPool(playerBand(d), playerLuck(player, d))
	local protected = false
	if (d.Plow.Dry or 0) >= C.Shop.ProtectAfter then
		local band, use, cheap = playerBand(d), {}, {}
		local budget = soonBudget(player, d)
		for _, e in ipairs(pool) do
			if C.Parts[e.Id].Band <= band + 1 and isUseful(player, d, e.Id) then
				table.insert(use, e)
				if C.Parts[e.Id].Price <= budget then table.insert(cheap, e) end
			end
		end
		if #cheap > 0 then pool, protected = cheap, true elseif #use > 0 then pool, protected = use, true end
	end
	local total = 0
	for _, e in ipairs(pool) do total += e.W end
	local r = rng:NextNumber() * total
	local id = pool[#pool].Id
	for _, e in ipairs(pool) do r -= e.W; if r <= 0 then id = e.Id break end end
	return id, protected
end

--------------------------------------------------
-- the vehicle
--------------------------------------------------
function mods(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local ws = hum and hum.WalkSpeed or 16
	local d = DataService.Get(player)
	return {PowerMult = player:GetAttribute("PowerMult") or 1, PowerBonus = player:GetAttribute("PowerBonus") or 0, SizeMult = player:GetAttribute("SizeMult") or 1,
		ReachMult = player:GetAttribute("ReachMult") or 1, SpinMult = player:GetAttribute("SpinMult") or 1, SpeedMult = 1 + math.clamp(ws / 16 - 1, 0, 1) * 0.5,
		Levels = d and d.Plow and d.Plow.Levels or nil} -- 2026-10-06: part levels feed every server stat / useful-offer check
end
local function flat(v, fallback)
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.1 and f.Unit or fallback
end
local function findSpawn(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local look = flat(hrp.CFrame.LookVector, Vector3.new(0, 0, -1))
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {char, folder}
	local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {char, folder}
	local best
	for _, ang in ipairs({0, 40, -40, 80, -80, 125, -125, 180}) do
		local dir = CFrame.Angles(0, math.rad(ang), 0):VectorToWorldSpace(look)
		local hit = workspace:Raycast(hrp.Position + dir * C.Vehicle.SpawnAhead + Vector3.new(0, 10, 0), Vector3.new(0, -40, 0), rp)
		if hit and hit.Normal.Y > 0.9 then
			local pos = hit.Position
			local center = pos + Vector3.new(0, 2.4, 0)
			local blocked = false
			for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.lookAt(center, center + dir), Vector3.new(7.5, 3.4, 11), op)) do
				if part.CanCollide then blocked = true break end
			end
			local cf = CFrame.lookAt(pos, pos + dir)
			if not blocked then return cf end
			best = best or cf
		end
	end
	local p0 = hrp.Position - Vector3.new(0, 2.8, 0) + look * 6
	return best or CFrame.lookAt(p0, p0 + look)
end

local despawn
local function recover(player, v)
	local hull = v.hull
	if not hull or not hull.Parent then return end
	local cf = v.safeCF or hull.CFrame
	local look = flat(cf.LookVector, Vector3.new(0, 0, -1))
	local pos = cf.Position + Vector3.new(0, 4, 0)
	pcall(function() hull:SetNetworkOwner(nil) end)
	v.model:PivotTo(CFrame.lookAt(pos, pos + look))
	hull.AssemblyLinearVelocity = Vector3.zero
	hull.AssemblyAngularVelocity = Vector3.zero
	v.lastCF, v.flipSince = nil, nil
	task.delay(0.3, function()
		if hull.Parent and Registry.Active[player] == v then pcall(function() hull:SetNetworkOwner(player) end) end
	end)
end
function despawn(player, reason)
	local v = Registry.Active[player]
	if not v then return end
	Registry.Active[player] = nil
	for _, c in ipairs(v.conns or {}) do c:Disconnect() end
	player:SetAttribute("PlowDriving", false)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart == v.seat then hum.Sit = false end
	if v.model then v.model:Destroy() end
	ev:FireClient(player, "Despawned", reason)
end
-- Park before teleports; recompute vehicle stats when upgrades change.
Registry.Park = despawn
Registry.Refresh = function(player)
	local v = Registry.Active[player]
	if not v or not v.hull or not v.hull.Parent then return end
	local stats = C.StatsFor(v.build, mods(player))
	v.stats = stats
	for _, key in ipairs({"MaxSpeed", "Accel", "TurnRate", "Traction", "Stability", "Pivot", "ClearPower", "Soft", "Hard"}) do -- 2026-10-06: clearing stats for the client's hard-snow speed cap
		v.hull:SetAttribute(key, stats[key])
	end
	ev:FireClient(player, "StatsChanged")
end
local function spawnVehicle(player, d, p)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return fail("Wait until you respawn.") end
	if hum.SeatPart then return fail("You're already sitting somewhere.") end
	local build = p.Build
	for _, slot in ipairs(C.Slots) do -- a missing or unknown part falls back to the free starter part
		if not (C.Parts[build[slot] or ""] and (p.Parts[build[slot]] or 0) > 0) then build[slot] = C.Starter[slot] end
	end
	local stats = C.StatsFor(build, mods(player))
	local rootCF = findSpawn(char)
	local ok, model = pcall(Assembly.Build, build)
	if not ok or not model then return fail("The snowplow parts are missing - tell the developer.") end
	model.Name = "Snowplow_" .. player.UserId
	model:PivotTo(rootCF)
	local seatRel = model:GetAttribute("SeatPos")
	local hs = C.Vehicle.HullSize
	local hull = Instance.new("Part")
	hull.Name = "Hull"; hull.Size = hs; hull.Transparency = 1
	local spawnHullCF = rootCF * CFrame.new(0, C.Vehicle.HullClearance + hs.Y / 2, 0)
	hull.CFrame = spawnHullCF
	hull.CanCollide, hull.CanQuery, hull.CanTouch = true, false, false
	hull.CollisionGroup = "PlowVehicle"
	-- 2026-10-05 (Claude, drive fix): the hull must be the assembly root. Otherwise the driver's HumanoidRootPart becomes the root when
	-- they sit, the seat weld drags the whole plow down to the standing character's height and the hull ends up stuck under the floor.
	hull.RootPriority = 127
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0, 0, 100, 1)
	hull.Parent = model
	local seat = Instance.new("Seat")
	seat.Name = "DriverSeat"; seat.Size = Vector3.new(2.4, 0.6, 2.4); seat.Transparency = 1
	seat.CanCollide, seat.CanQuery, seat.CanTouch = false, false, false
	seat.CFrame = model.PrimaryPart.CFrame * (seatRel or CFrame.new(0, 3, 1)) * CFrame.new(0, -0.3, 0)
	seat.Parent = model
	local function weld(part)
		local w = Instance.new("WeldConstraint"); w.Part0 = hull; w.Part1 = part; w.Parent = part
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= hull then
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, false, true
			weld(part)
		end
	end
	model.PrimaryPart = hull
	hull.Anchored = false
	hull:SetAttribute("OwnerUserId", player.UserId)
	hull:SetAttribute("MaxSpeed", stats.MaxSpeed); hull:SetAttribute("Accel", stats.Accel); hull:SetAttribute("TurnRate", stats.TurnRate)
	hull:SetAttribute("ClearPower", stats.ClearPower); hull:SetAttribute("Soft", stats.Soft); hull:SetAttribute("Hard", stats.Hard) -- 2026-10-06: hard-snow speed cap (PlowDriveClient)
	hull:SetAttribute("Traction", stats.Traction); hull:SetAttribute("Stability", stats.Stability); hull:SetAttribute("Pivot", stats.Pivot)
	model.Parent = folder
	local v = {model = model, hull = hull, seat = seat, stats = stats, build = {Blade = build.Blade, Engine = build.Engine, Gear = build.Gear, Body = build.Body},
		safeCF = hull.CFrame, spawnedAt = os.clock(), flags = 0, conns = {}}
	Registry.Active[player] = v
	player:SetAttribute("PlowDriving", true)
	table.insert(v.conns, hum.Died:Connect(function() despawn(player, "died") end))
	seat:Sit(hum)
	local t0 = os.clock()
	while os.clock() - t0 < 1.0 and hum.SeatPart ~= seat and Registry.Active[player] == v do task.wait(0.05) end
	if Registry.Active[player] ~= v then return fail("Couldn't hop in - try again.") end
	if hum.SeatPart ~= seat then despawn(player, "seat failed"); return fail("Couldn't hop in - try again.") end
	-- put the (now seated) plow back on its spawn spot: moving the root moves the whole assembly, driver included
	hull.CFrame = spawnHullCF
	hull.AssemblyLinearVelocity, hull.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	v.safeCF = spawnHullCF
	pcall(function() hull:SetNetworkOwner(player) end)
	table.insert(v.conns, hum.Seated:Connect(function(active) if not active then task.defer(despawn, player, "exit") end end))
	ev:FireClient(player, "Spawned")
	return {ok = true, driving = true}
end

--------------------------------------------------
-- shared garage lobby (2026-10-05, Claude): everyone in a server visits the same garage; each visitor leases one bay.
-- A bay only shows PUBLIC info (owner name + part ids of build / offers / reserve) as attributes; tokens, Snow and the
-- inventory stay private. Leases change on every assign/release, so a request sent for an earlier lease is refused.
-- Saved offers / reserve / build belong to the player, never to the bay. Works with the old single garage too (no Bays folder).
--------------------------------------------------
local Garage = {bays = {}, byPlayer = {}, seq = 0}
local reqLease -- lease the client sent with the current request (set by handle; handlers do not yield before reading it)
local BAY_REACH, PEDESTAL_REACH = 39, 14 -- 2026-10-06: bays are 1.5x larger (48 x 45 studs)
local function garageRoot() return workspace:FindFirstChild("PlowGarage") end
local function sharedMode() local g = garageRoot(); return g ~= nil and g:FindFirstChild("Bays") ~= nil end
local function registerBays()
	local g = garageRoot()
	local f = g and g:FindFirstChild("Bays")
	if not f then return end
	for _, m in ipairs(f:GetChildren()) do
		local i = m:GetAttribute("BayIndex")
		if type(i) == "number" and not Garage.bays[i] then Garage.bays[i] = {index = i, model = m, lease = 0} end
	end
end
-- overflow bays (more visitors than main bays): modular columns of two facing bays + a street tile, built on demand
local function overflowBay(i)
	local tpl = SS:FindFirstChild("SharedGarageTemplates")
	local bayTpl = tpl and tpl:FindFirstChild("Bay")
	local g = garageRoot()
	local f = g and g:FindFirstChild("Bays")
	local anchor = g and g:FindFirstChild("OverflowOrigin")
	if not (bayTpl and f and anchor) then return nil end
	local k = i - 9
	local col, side = k // 2, k % 2
	local step, row = anchor:GetAttribute("ColStep") or 32, anchor:GetAttribute("RowOffset") or 30 -- set by the garage layout (1.5x since 2026-10-06)
	local colCF = anchor.CFrame * CFrame.new(col * step, 0, 0)
	local cf = side == 0 and colCF * CFrame.new(0, 0, row) or colCF * CFrame.new(0, 0, -row) * CFrame.Angles(0, math.pi, 0)
	local m = bayTpl:Clone()
	m.Name = "Bay_" .. i
	m:SetAttribute("BayIndex", i); m:SetAttribute("Overflow", true)
	m:PivotTo(cf)
	m.Parent = f
	if side == 0 then
		local holder = g:FindFirstChild("Overflow") or Instance.new("Folder", g)
		holder.Name = "Overflow"
		-- the east rim colliders stand where the overflow columns attach (they used to cut through overflow bays): open them
		local cols = g:FindFirstChild("Colliders")
		local open = string.split(anchor:GetAttribute("OpenRims") or "RimEastN,RimEastS", ",") -- 2026-10-06: overflow grows west (OpenRims = "RimWest")
		for _, n in ipairs(open) do local w = cols and cols:FindFirstChild(n); if w then w.CanCollide = false end end
		for _, piece in ipairs(tpl:GetChildren()) do
			if piece:GetAttribute("OverflowPiece") then
				local c = piece:Clone(); c.Name = piece.Name .. "_" .. col
				c:PivotTo(colCF * (piece:GetAttribute("Offset") or CFrame.new()))
				c.Parent = holder
			end
		end
	end
	Garage.bays[i] = {index = i, model = m, lease = 0}
	return Garage.bays[i]
end
local function freeBay()
	registerBays()
	local ids = {}
	for i in pairs(Garage.bays) do table.insert(ids, i) end
	table.sort(ids)
	for _, i in ipairs(ids) do
		local b = Garage.bays[i]
		if not b.owner and b.model.Parent then return b end
	end
	local n = math.max((ids[#ids] or 0) + 1, 9)
	if n > math.max(Players.MaxPlayers, 8) + 2 then return nil end
	return overflowBay(n)
end
local function publishBay(player, d)
	local bay = Garage.byPlayer[player]
	if not bay or bay.owner ~= player or not d or not d.Plow then return end
	local p, m = d.Plow, bay.model
	m:SetAttribute("Build", ("%s|%s|%s|%s"):format(p.Build.Blade or "", p.Build.Engine or "", p.Build.Gear or "", p.Build.Body or "")) -- task 7: 4th field = body (old 3-field strings still parse)
	for _, k in ipairs({"1", "2", "3"}) do m:SetAttribute("Offer" .. k, p.Offers[k] and p.Offers[k].Part or "") end
	m:SetAttribute("Reserved", p.Reserved and p.Reserved.Part or "")
end
local function assignBay(player, d, prefer) -- prefer: a free bay the player walked into (hub ring, 2026-10-09)
	local bay = Garage.byPlayer[player]
	if bay and bay.owner == player then return bay end
	if prefer and not prefer.owner and prefer.model.Parent then bay = prefer else bay = freeBay() end
	if not bay then return nil end
	Garage.seq += 1
	bay.owner, bay.lease = player, Garage.seq
	Garage.byPlayer[player] = bay
	local m = bay.model
	m:SetAttribute("OwnerUserId", player.UserId); m:SetAttribute("OwnerName", player.DisplayName); m:SetAttribute("Lease", bay.lease)
	player:SetAttribute("GarageBay", bay.index); player:SetAttribute("GarageLease", bay.lease)
	publishBay(player, d)
	return bay
end
local function releaseBay(player)
	local bay = Garage.byPlayer[player]
	Garage.byPlayer[player] = nil
	player:SetAttribute("GarageBay", nil); player:SetAttribute("GarageLease", nil)
	if not bay or bay.owner ~= player then return end
	Garage.seq += 1
	bay.owner, bay.lease = nil, Garage.seq
	local m = bay.model
	for _, k in ipairs({"OwnerName", "Build", "Offer1", "Offer2", "Offer3", "Reserved"}) do m:SetAttribute(k, "") end
	m:SetAttribute("OwnerUserId", 0); m:SetAttribute("Lease", bay.lease)
end
Registry.ReleaseBay = releaseBay
-- owner, lease and distance check for every garage action (the server never trusts a client-named bay or owner)
local function bayGate(player, partName, reach)
	if not sharedMode() then return true end
	local bay = Garage.byPlayer[player]
	if not bay or bay.owner ~= player or not player:GetAttribute("InGarage") then return false, "Go to your own garage bay first!" end
	if reqLease ~= nil and reqLease ~= bay.lease then return false, "Your garage changed - try again." end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local obj = partName and bay.model:FindFirstChild(partName)
	local at = obj and (obj:IsA("Model") and (obj:FindFirstChild("Top") or obj.PrimaryPart) or obj)
	local pos = (at and at:IsA("BasePart")) and at.Position or bay.model:GetPivot().Position
	if not hrp or (hrp.Position - pos).Magnitude > (reach or BAY_REACH) then
		return false, partName and "Walk up to that pedestal first." or "Walk back into your garage bay first."
	end
	return true, bay
end

--------------------------------------------------
-- offer expiry (2026-10-06): pedestal offers last C.Shop.OfferSeconds (server time). The timer only runs while the player is in the
-- garage and has finished the tutorial; otherwise it is paused (Left = seconds remaining). A bad-luck-protection offer lasts
-- ProtectedOfferSeconds, and if it still runs out, the next roll is protected again (it can't be lost to the clock).
--------------------------------------------------
local function offerTimerRuns(player, p) return player:GetAttribute("InGarage") == true and p.TutorialDone == true end
local function syncOfferTimers(player, d)
	local p = d and d.Plow
	if not p or type(p.Offers) ~= "table" then return false end
	local run, t, gone = offerTimerRuns(player, p), workspace:GetServerTimeNow(), nil
	for _, k in ipairs({"1", "2", "3"}) do
		local o = p.Offers[k]
		if o then
			if run then
				if not o.ExpiresAt then o.ExpiresAt = t + (tonumber(o.Left) or C.Shop.OfferSeconds); o.Left = nil end
				if t >= o.ExpiresAt then
					if o.Protected then p.Dry = math.max(p.Dry or 0, C.Shop.ProtectAfter) end
					p.Offers[k] = nil
					gone = gone or {}; table.insert(gone, k)
				end
			elseif o.ExpiresAt then
				o.Left = math.max(1, o.ExpiresAt - t); o.ExpiresAt = nil
			end
		end
	end
	if gone then
		publishBay(player, d)
		ev:FireClient(player, "OfferExpired", table.concat(gone, ","))
	end
	return gone ~= nil
end
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, pl in ipairs(Players:GetPlayers()) do
			local d = DataService.Get(pl)
			if d then pcall(syncOfferTimers, pl, d) end
		end
	end
end)

--------------------------------------------------
-- remote actions
--------------------------------------------------
local actions = {}
function actions.State() return {ok = true} end
local SLOTS = {["1"] = true, ["2"] = true, ["3"] = true}
function actions.Roll(player, d, p, slot)
	slot = tostring(slot or "1")
	if not SLOTS[slot] then return fail("Bad request") end
	if not player:GetAttribute("InGarage") then return fail("Parts are rolled on the pedestals in the GARAGE - tap GARAGE to teleport there!") end
	local okBay, why = bayGate(player, "Pedestal_" .. slot, PEDESTAL_REACH)
	if not okBay then return fail(why) end
	if (cooldown[player] or 0) > os.clock() then return fail("Rolling too fast - one moment!") end
	local cd = C.Shop.RollCooldown * math.clamp(player:GetAttribute("RollCooldownMult") or 1, 0.6, 1)
	cooldown[player] = os.clock() + cd
	-- 2026-10-06: the visible roll timer runs off this server time (pedestal prompts, pedestal pill, REROLL button)
	player:SetAttribute("RollReadyAt", workspace:GetServerTimeNow() + cd); player:SetAttribute("RollCooldownLen", cd)
	local id, protected = pickPart(player, d)
	if isUseful(player, d, id) then p.Dry = 0 else p.Dry = (p.Dry or 0) + 1 end
	p.Seq += 1
	p.Rolls += 1
	DataService.SetStat(player, "Rolls", (d.TotalRolls or 0) + p.Rolls)
	local o = {Part = id, Token = HttpService:GenerateGUID(false), Price = C.Parts[id].Price, Seq = p.Seq, Protected = protected or nil}
	local secs = protected and C.Shop.ProtectedOfferSeconds or C.Shop.OfferSeconds
	if offerTimerRuns(player, p) then o.ExpiresAt = workspace:GetServerTimeNow() + secs else o.Left = secs end
	p.Offers[slot] = o
	player:SetAttribute("PlowOffered", true)
	publishBay(player, d)
	local bay = Garage.byPlayer[player]
	if bay then ev:FireAllClients("BayReveal", bay.index, slot, RANK[C.Parts[id].Rarity]) end -- neighbours see the reveal (part id is public on the bay)
	return {ok = true, rolled = true, slot = slot, rank = RANK[C.Parts[id].Rarity], protected = protected}
end
actions.Reroll = actions.Roll
function actions.Buy(player, d, p, which, token)
	if which ~= "Reserved" and not SLOTS[which] then return fail("Bad request") end
	local okBay, why = bayGate(player)
	if not okBay then return fail(why) end
	local o = which == "Reserved" and p.Reserved or p.Offers[which]
	if type(token) ~= "string" or not o or o.Token ~= token then return fail("That offer is gone - roll a new one!", {stale = true}) end
	local def = C.Parts[o.Part]
	if not def then
		if which == "Reserved" then p.Reserved = nil else p.Offers[which] = nil end
		return fail("That part no longer exists.")
	end
	local price = C.OfferPrice(o) -- saved offers never cost more than the current catalog price (price drops are passed on)
	if type(d.Snow) ~= "number" or d.Snow ~= d.Snow or d.Snow < price then
		local short = math.ceil(price - (tonumber(d.Snow) or 0))
		return fail("You need " .. Format.Abbreviate(short) .. " more Snow", {short = short})
	end
	if (p.Parts[o.Part] or 0) >= C.Shop.MaxOwned then return fail("You own the maximum of this part.") end
	-- deduct + grant + clear in one step (no yield in between): a duplicate or forged request can never buy twice
	d.Snow -= price
	DataService.SetStat(player, "Snow", d.Snow)
	p.Parts[o.Part] = (p.Parts[o.Part] or 0) + 1
	if which == "Reserved" then p.Reserved = nil else p.Offers[which] = nil end
	player:SetAttribute("PlowBought", true)
	publishBay(player, d)
	return {ok = true, bought = o.Part, msg = "Bought " .. def.Name .. "!"}
end
function actions.Reserve(player, d, p, slot, token, confirm)
	slot = tostring(slot or "")
	if not SLOTS[slot] then return fail("Bad request") end
	local okBay, why = bayGate(player)
	if not okBay then return fail(why) end
	local o = p.Offers[slot]
	if type(token) ~= "string" or not o or o.Token ~= token then return fail("That offer is gone - roll a new one!", {stale = true}) end
	if p.Reserved and confirm ~= true then return fail("Replace your reserved part?", {needConfirm = true}) end
	o.ExpiresAt, o.Left, o.Protected = nil, nil, nil -- the reserve shelf never expires
	p.Reserved = o
	p.Offers[slot] = nil
	player:SetAttribute("PlowReserved", true)
	publishBay(player, d)
	return {ok = true, msg = "Reserved " .. C.Parts[o.Part].Name .. "!"}
end
function actions.Equip(player, d, p, slot, id)
	if type(slot) ~= "string" or type(id) ~= "string" then return fail("Bad request") end
	local def = C.Parts[id]
	if not def or def.Slot ~= slot or not table.find(C.Slots, slot) then return fail("That part doesn't fit that slot.") end
	if (p.Parts[id] or 0) < 1 then return fail("You don't own that part.") end
	if Registry.Active[player] then return fail("Park your snowplow first (EXIT), then change parts.") end
	local okBay, why = bayGate(player)
	if not okBay then return fail(why) end
	p.Build[slot] = id
	player:SetAttribute("PlowEquipped", true)
	publishBay(player, d)
	return {ok = true, msg = def.Name .. " equipped!"}
end
function actions.Unequip(player, d, p, slot)
	if type(slot) ~= "string" or not table.find(C.Slots, slot) then return fail("Bad request") end
	if Registry.Active[player] then return fail("Park your snowplow first (EXIT), then change parts.") end
	local okBay, why = bayGate(player)
	if not okBay then return fail(why) end
	p.Build[slot] = C.Starter[slot] -- never leave a slot empty: the free starter part goes back in
	publishBay(player, d)
	return {ok = true, msg = "Unequipped - your free " .. C.Parts[C.Starter[slot]].Name .. " is back on. The part stays in your inventory."}
end
-- 2026-10-06 part levels: Snow only, at the workbench (same bay check as equipping), owned parts only, rate-limited; the level stays
-- with the part id (C.Levels / C.LevelCost). Saved with the profile like every other d.Plow change.
local lastLevel = {}
function actions.LevelUp(player, d, p, id)
	if type(id) ~= "string" then return fail("Bad request") end
	local def = C.Parts[id]
	if not def then return fail("Unknown part.") end
	if (p.Parts[id] or 0) < 1 then return fail("You don't own that part.") end
	local okBay, why = bayGate(player)
	if not okBay then return fail(why) end
	local now = os.clock()
	if (lastLevel[player] or 0) > now - 0.35 then return fail("Slow down!") end
	lastLevel[player] = now
	p.Levels = type(p.Levels) == "table" and p.Levels or {}
	local L = C.LevelOf(p.Levels, id)
	if L >= C.Levels.Max then return fail(def.Name .. " is already at max level " .. C.Levels.Max .. "!") end
	local cost = C.LevelCost(def, L)
	if (tonumber(d.Snow) or 0) < cost then
		local short = cost - (tonumber(d.Snow) or 0)
		return fail("You need " .. Format.Abbreviate(math.ceil(short)) .. " more Snow", {short = short})
	end
	DataService.AddSnow(player, -cost)
	p.Levels[id] = L + 1
	if Registry.Active[player] then Registry.Refresh(player) end
	return {ok = true, msg = def.Name .. " is now level " .. (L + 1) .. (L + 1 >= C.Levels.Max and " (MAX)!" or "!"), level = L + 1}
end
Players.PlayerRemoving:Connect(function(pl) lastLevel[pl] = nil end)
function actions.Drive(player, d, p)
	if player:GetAttribute("InGarage") then return fail("Go back to the lobby to drive - tap LOBBY!") end
	if Registry.Active[player] then despawn(player, "exit"); return {ok = true, driving = false} end
	if player:GetAttribute("InArenaIsland") then return fail("Your snowplow is parked while you're at the arena - tap LEAVE ARENA first.") end -- 2026-10-05 (arena)
	return spawnVehicle(player, d, p)
end
function actions.Recover(player)
	local v = Registry.Active[player]
	if not v then return fail("You're not driving.") end
	if (v.recoverAt or 0) > os.clock() then return fail("Recover is cooling down...") end
	v.recoverAt = os.clock() + C.Vehicle.RecoverCooldown
	recover(player, v)
	return {ok = true, msg = "Snowplow recovered!"}
end
function actions.TutorialDone(player, d, p) p.TutorialDone = true; player:SetAttribute("PlowTutorialDone", true); return {ok = true} end
-- 2026-10-05 (Claude): tutorial v2 checkpoints + step timings for playtest analysis (whitelisted, size-bounded; never touches progress or
-- ownership). Main lesson done / skipped / legacy also sets TutorialDone. Each step is also logged to the Creator Dashboard onboarding funnel.
local TUT_LESSONS = {Main = true, Garage = true}
local TUT_STATUS = {done = true, skipped = true, legacy = true, reserved = true, replay = true}
function actions.TutorialProgress(player, d, p, lesson, step, info)
	if not TUT_LESSONS[lesson] or type(step) ~= "string" or #step > 24 or not step:match("^[%w_]+$") then return fail("Bad request") end
	info = type(info) == "table" and info or {}
	local t = type(p.Tutorial) == "table" and p.Tutorial or {}
	t.Version = 2
	t.Steps = type(t.Steps) == "table" and t.Steps or {}
	local key = lesson .. "." .. step
	local count = 0
	for _ in pairs(t.Steps) do count += 1 end
	if t.Steps[key] or count < 40 then
		local old = type(t.Steps[key]) == "table" and t.Steps[key] or {}
		local secs, hints = tonumber(info.Secs), tonumber(info.Hints)
		t.Steps[key] = {S = secs and math.clamp(math.floor(secs * 10 + 0.5) / 10, 0, 36000) or old.S, H = hints and math.clamp(math.floor(hints), 0, 99) or old.H, N = math.min(99, (tonumber(old.N) or 0) + 1)}
	end
	if TUT_STATUS[info.Status] and info.Status ~= "replay" then t[lesson] = info.Status end
	t.Checkpoint = key
	p.Tutorial = t
	if lesson == "Main" and (info.Status == "done" or info.Status == "skipped" or info.Status == "legacy") then
		p.TutorialDone = true; player:SetAttribute("PlowTutorialDone", true)
	end
	if type(info.Index) == "number" then
		pcall(function() game:GetService("AnalyticsService"):LogOnboardingFunnelStepEvent(player, math.clamp(math.floor(info.Index), 1, 40), key) end)
	end
	return {ok = true}
end

--------------------------------------------------
-- the garage place (workspace.PlowGarage, built from the Blender garage kit)
--------------------------------------------------
local returnCF = {}
local function garageArrival()
	local g = workspace:FindFirstChild("PlowGarage")
	return g and g:FindFirstChild("Arrival")
end
local function lobbySpawn()
	local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	return sp and (sp.CFrame * CFrame.new(0, 4, 0)) or CFrame.new(0, 10, 0)
end
-- 2026-10-09 (hub ring): the bays stand in a ring around the lobby, open side toward the lobby centre. Arriving = standing just
-- inside your bay's open side, facing the lift and the pedestals.
local function bayArrival(bay)
	local m = bay and bay.model
	if not (m and m.Parent) then return nil end
	return m:GetPivot() * CFrame.new(0, 3, -17) * CFrame.Angles(0, math.pi, 0)
end
function actions.GoGarage(player, d, p)
	if player:GetAttribute("InGarage") then return fail("You're already in the garage!") end
	if player:GetAttribute("InArenaIsland") then return fail("Tap LEAVE ARENA first, then visit the garage.") end -- 2026-10-05 (arena)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return fail("Wait until you respawn.") end
	local shared = sharedMode()
	local arrival = garageArrival()
	if not shared and not arrival then return fail("The garage isn't open yet.") end
	if Registry.Active[player] then despawn(player, "garage") end
	if hum.SeatPart then hum.Sit = false end
	local bay = shared and assignBay(player, d)
	if shared and not bay then return fail("Every garage bay is busy - try again in a moment!") end
	local target = (bay and bayArrival(bay)) or (arrival and arrival.CFrame)
	if not target then releaseBay(player); return fail("The garage isn't open yet.") end
	returnCF[player] = hrp.CFrame
	pcall(function() player:RequestStreamAroundAsync(target.Position) end)
	if not char.Parent or hum.Health <= 0 then releaseBay(player); return fail("Try again.") end
	player:SetAttribute("InGarage", true)
	-- a little sideways spread so two arrivals never land inside each other
	local spread = bay and CFrame.new((rng:NextNumber() - 0.5) * 6, 0, 0) or CFrame.new()
	char:PivotTo(target * spread)
	return {ok = true, msg = bay and ("Welcome to your garage: Bay " .. bay.index .. "!") or "Welcome to the Garage! Roll parts on the pedestals."}
end
function actions.GoLobby(player, d, p)
	if not player:GetAttribute("InGarage") then return fail("You're not in the garage.") end
	local char = player.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return fail("Wait until you respawn.") end
	local cf = returnCF[player] or lobbySpawn()
	pcall(function() player:RequestStreamAroundAsync(cf.Position) end)
	player:SetAttribute("InGarage", false)
	releaseBay(player)
	returnCF[player] = nil
	char:PivotTo(cf + Vector3.new(0, 2, 0))
	return {ok = true, msg = "Back in the lobby!"}
end
-- 2026-10-05 (travel): TravelService moves players through these, so vehicles and garage bays always use this one path
-- (the spawn path re-assembles the player's saved build, so new part slots work there automatically)
Registry.Spawn = function(player)
	local d = DataService.Get(player)
	if not d or not d.Plow then return fail("Your data is still loading...") end
	if player:GetAttribute("InGarage") then return fail("Go back to the lobby to drive - tap LOBBY!") end
	if Registry.Active[player] then return {ok = true, driving = true} end
	return spawnVehicle(player, d, d.Plow)
end
Registry.GoGarage = function(player)
	local d = DataService.Get(player)
	if not d or not d.Plow then return fail("Your data is still loading...") end
	return actions.GoGarage(player, d, d.Plow)
end
Registry.LeaveGarage = function(player) -- the caller moves the character itself
	if not player:GetAttribute("InGarage") then return end
	player:SetAttribute("InGarage", false)
	releaseBay(player)
	returnCF[player] = nil
end
local function watchGarage(pl)
	pl:SetAttribute("InGarage", false)
	pl.CharacterAdded:Connect(function() pl:SetAttribute("InGarage", false); releaseBay(pl); returnCF[pl] = nil end)
end
Players.PlayerAdded:Connect(watchGarage)
for _, pl in ipairs(Players:GetPlayers()) do watchGarage(pl) end
Players.PlayerRemoving:Connect(function(pl) releaseBay(pl); returnCF[pl] = nil end)
-- 2026-10-09 (hub ring, wiktor: "the lobby became garages and lobby itself"): the bays stand in a ring around the Frostfall lobby.
-- Walking into a bay enters the garage (you get that bay if it is free, else the first free one); walking out of the bays leaves it
-- after a short grace. The bay itself is kept RELEASE_AFTER seconds longer, so stepping out to the plaza and back keeps your bay.
-- GARAGE / TRAVEL "My Garage" teleport you into your bay. Overflow streets/annexes (more than 8 visitors) count as garage too.
-- (2026-10-06 version: the whole garage island west of the lobby was the garage; Colliders.IslandTop still works as a fallback.)
local LEAVE_GRACE, RELEASE_AFTER = 2.5, 30
local outsideSince = {}
local function bayAt(pos)
	registerBays()
	for _, b in pairs(Garage.bays) do
		local m = b.model
		if m and m.Parent then
			local l = m:GetPivot():PointToObjectSpace(pos)
			if math.abs(l.X) < 25.5 and math.abs(l.Z) < 24 and l.Y > -30 and l.Y < 60 then return b end
		end
	end
	return nil
end
local function insideGarage(pos)
	if bayAt(pos) then return true end
	local g = garageRoot()
	local ov = g and g:FindFirstChild("Overflow")
	if ov then
		for _, piece in ipairs(ov:GetChildren()) do
			if piece:IsA("Model") then
				local cf, size = piece:GetBoundingBox()
				local l = cf:PointToObjectSpace(pos)
				if math.abs(l.X) < size.X / 2 and math.abs(l.Z) < size.Z / 2 and l.Y > -30 and l.Y < 60 then return true end
			end
		end
	end
	local top = g and g:FindFirstChild("Colliders") and g.Colliders:FindFirstChild("IslandTop")
	if not top then return false end
	local p = top.CFrame:PointToObjectSpace(pos)
	return math.abs(p.X) < top.Size.X / 2 and math.abs(p.Z) < top.Size.Z / 2 and p.Y > -30 and p.Y < 60
end
local function enterOnFoot(pl, pos)
	if pl:GetAttribute("InGarage") or pl:GetAttribute("InArenaIsland") or pl:GetAttribute("IntroActive") or Registry.Active[pl] then return end
	local d = DataService.Get(pl)
	if not d or not d.Plow then return end
	local shared = sharedMode()
	local bay = shared and assignBay(pl, d, bayAt(pos))
	if shared and not bay then return end
	returnCF[pl] = nil -- LOBBY / the return portal then go to the lobby spawn
	pl:SetAttribute("InGarage", true)
end
task.spawn(function() -- walk-in / walk-out, and a rescue for anyone who falls out of a bay
	while true do
		task.wait(0.5)
		local arrival = garageArrival()
		for _, pl in ipairs(Players:GetPlayers()) do
			local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
			local hum = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local inside = insideGarage(hrp.Position)
				local bay = Garage.byPlayer[pl]
				local home = (bay and bay.owner == pl and bayArrival(bay)) or (arrival and arrival.CFrame)
				if pl:GetAttribute("InGarage") then
					if inside then
						outsideSince[pl] = nil
						if home and hrp.Position.Y < home.Y - 28 then hrp.CFrame = home end
					else
						outsideSince[pl] = outsideSince[pl] or os.clock()
						if os.clock() - outsideSince[pl] > LEAVE_GRACE or (home and (hrp.Position - home.Position).Magnitude > 1500) then
							pl:SetAttribute("InGarage", false); returnCF[pl] = nil
						end
					end
				elseif inside and not hum.SeatPart then
					outsideSince[pl] = nil
					enterOnFoot(pl, hrp.Position)
				elseif bay and bay.owner == pl and outsideSince[pl] and os.clock() - outsideSince[pl] > RELEASE_AFTER then
					outsideSince[pl] = nil
					releaseBay(pl) -- out of the garage for a while: the bay goes back to the pool
				end
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(pl) outsideSince[pl] = nil end)

local function handle(player, action, a, b, c, lease)
	if type(action) ~= "string" then return fail("Bad request") end
	reqLease = type(lease) == "number" and lease or nil
	local d = DataService.Get(player)
	if not d or not d.Plow then return fail("Your data is still loading...") end
	if action ~= "State" then
		if (lastCall[player] or 0) > os.clock() - 0.05 then return fail("Slow down!") end
		lastCall[player] = os.clock()
	end
	local handler = actions[action]
	if not handler then return fail("Unknown action") end
	syncOfferTimers(player, d) -- an expired offer is gone before any buy / reserve is checked
	local ok, res = pcall(handler, player, d, d.Plow, a, b, c)
	if not ok then warn("[PlowService] " .. action .. ": " .. tostring(res)); return fail("Something went wrong - try again.") end
	reqLease = nil
	if type(res) == "table" then
		res.state = snapshot(player, d)
		local bay = Garage.byPlayer[player]
		res.state.Bay, res.state.Lease = bay and bay.index or nil, bay and bay.lease or nil
	end
	return res
end

fn.OnServerInvoke = handle
if TEST then -- isolated Studio tests only: lets a server test script call the real handler (ServerStorage.PlowTestHook)
	local hook = Instance.new("BindableFunction"); hook.Name = "PlowTestHook"; hook.Parent = SS
	hook.OnInvoke = function(player, action, a, b, c, lease) return handle(player, action, a, b, c, lease) end
	-- isolated tests only: drive the bay manager with stand-in visitors (multi-visitor assignment / lease / overflow checks)
	local gh = Instance.new("BindableFunction"); gh.Name = "GarageTestHook"; gh.Parent = SS
	local proxies = {}
	local function proxy(f) -- a Folder stands in for a visitor (Bindables cannot carry Player-like tables with methods)
		if typeof(f) ~= "Instance" or f:IsA("Player") then return f end
		local p = proxies[f]
		if not p then
			p = {UserId = f:GetAttribute("UserId") or -1, DisplayName = f.Name, Name = f.Name}
			function p:SetAttribute(k, v) f:SetAttribute(k, v) end
			function p:GetAttribute(k) return f:GetAttribute(k) end
			proxies[f] = p
		end
		return p
	end
	gh.OnInvoke = function(op, who, d, x, y)
		who = proxy(who)
		if op == "assign" then local b = assignBay(who, d); return b and b.index, b and b.lease end
		if op == "release" then releaseBay(who); return true end
		if op == "publish" then publishBay(who, d); return true end
		if op == "gate" then return bayGate(who, x, y) end
		if op == "setLease" then reqLease = d; return true end
		return nil
	end
end

Players.PlayerRemoving:Connect(function(pl) despawn(pl, "left"); cooldown[pl], lastCall[pl] = nil, nil end)
Players.PlayerAdded:Connect(function(pl) pl.CharacterRemoving:Connect(function() despawn(pl, "respawn") end) end)
for _, pl in ipairs(Players:GetPlayers()) do pl.CharacterRemoving:Connect(function() despawn(pl, "respawn") end) end
task.spawn(function() -- bookkeeping: lost seat, death, falling out of the world, flipped plows
	while true do
		task.wait(0.4)
		for player, v in pairs(Registry.Active) do
			local ok, err = pcall(function()
				local hull = v.hull
				if not hull or not hull.Parent or not v.model.Parent then despawn(player, "gone") return end
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then despawn(player, "died") return end
				if hum.SeatPart ~= v.seat and os.clock() - v.spawnedAt > 1.5 then despawn(player, "exit") return end
				if hull.Position.Y < C.Vehicle.BoundsY then v.safeCF = v.safeCF or hull.CFrame; recover(player, v) return end
				local up = hull.CFrame.UpVector.Y
				if up > 0.9 then
					v.safeCF, v.flipSince = hull.CFrame, nil
				elseif up < 0.35 then
					v.flipSince = v.flipSince or os.clock()
					if os.clock() - v.flipSince > 2.5 then recover(player, v) end
				end
			end)
			if not ok then warn("[PlowService] vehicle check: " .. tostring(err)) end
		end
	end
end)

