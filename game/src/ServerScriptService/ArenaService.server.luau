-- ArenaService (2026-10-05, Claude): Snowplow Bumper Arena - an optional 2-8 player ring-out mode on its own sky island.
-- The server owns match state, participants, ability windows, contact detection, knockback amounts, ring-outs, scores, respawns and
-- (cosmetic) rewards. Clients only ask (Join / Leave / Boost / Brace / Paint / Intro) and drive their own arena vehicle.
--
-- Physics / network ownership: each arena vehicle is owned by its driver (responsive steering, same model as the normal plow).
-- Arena vehicles never collide physically with each other (collision group ArenaVehicle). Instead the server checks every pair's
-- footprints each Heartbeat; a valid contact (same match, both alive and unshielded, plausible speeds, closing speed, pair cooldown)
-- produces a bounded knockback that the server sends to the victim's owner ("Knock"), where ArenaDriveClient adds it to its own drive
-- velocity and decays it - so the drive loop can never overwrite it. Each client also separates its own vehicle from others locally,
-- so vehicles never pass through each other while the server decides the hit. Training targets and Studio test bots are server-owned.
-- Arena vehicles are NOT in PlowRegistry: no snow clearing, no contract progress, no normal speed checks.
--
-- Studio tests (ServerStorage.BalanceTestMode = true): ServerStorage.ArenaTestHook:Invoke(op, ...) - see bottom of file.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local A = require(RS:WaitForChild("ArenaConfig"))
local C = require(RS:WaitForChild("PlowConfig"))
local Assembly = require(RS:WaitForChild("PlowAssembly"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Registry = require(script.Parent:WaitForChild("PlowRegistry"))
local Contracts = require(script.Parent:WaitForChild("ContractRegistry"))
local TEST = RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true
local V, K = A.Vehicle, A.Knock

local function remote(class, name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = RS end
	return r
end
local fn = remote("RemoteFunction", "ArenaRemote")
local event = remote("RemoteEvent", "ArenaEvent")

for _, g in ipairs({"ArenaVehicle", "ArenaWalkBlock", "PlowPlayers", "PlowVehicle"}) do pcall(function() PhysicsService:RegisterCollisionGroup(g) end) end
pcall(function()
	PhysicsService:CollisionGroupSetCollidable("ArenaVehicle", "ArenaVehicle", false) -- contacts are resolved by the server (see top)
	PhysicsService:CollisionGroupSetCollidable("ArenaVehicle", "PlowPlayers", false)
	PhysicsService:CollisionGroupSetCollidable("ArenaVehicle", "PlowVehicle", false)
	PhysicsService:CollisionGroupSetCollidable("ArenaWalkBlock", "ArenaVehicle", false) -- spectator barriers stop people, not vehicles
	PhysicsService:CollisionGroupSetCollidable("ArenaWalkBlock", "PlowVehicle", false)
end)

local folder = workspace:FindFirstChild("ArenaVehicles") or Instance.new("Folder")
folder.Name = "ArenaVehicles"; folder.Parent = workspace
local now = function() return workspace:GetServerTimeNow() end
local rng = Random.new()

--------------------------------------------------
-- profile (d.Arena v1): cosmetic progress only
--------------------------------------------------
local function arenaData(d)
	local a = type(d.Arena) == "table" and d.Arena or {}
	a.V = 1
	a.KOs, a.Matches, a.Wins = tonumber(a.KOs) or 0, tonumber(a.Matches) or 0, tonumber(a.Wins) or 0
	a.Unlocked = type(a.Unlocked) == "table" and a.Unlocked or {}
	a.Seen = type(a.Seen) == "table" and a.Seen or {}
	a.Paint = type(a.Paint) == "string" and a.Paint or "Classic"
	a.Title = type(a.Title) == "string" and a.Title or nil
	a.Intro = a.Intro == true
	a.Day, a.DayCount = type(a.Day) == "string" and a.Day or "", tonumber(a.DayCount) or 0
	d.Arena = a
	return a
end
local function paintUnlocked(a, id)
	local p = A.PaintById(id)
	return p.Id == id and (p.Unlock == nil or a.Unlocked[p.Unlock] == true)
end
local function titleOf(a)
	if a.Title then for _, ac in ipairs(A.Achievements) do if ac.Title == a.Title and a.Unlocked[ac.Id] then return a.Title end end end
	local best
	for _, ac in ipairs(A.Achievements) do if a.Unlocked[ac.Id] then best = ac.Title end end
	return best
end
local function publicStats(player, a)
	player:SetAttribute("ArenaTitle", titleOf(a) or "")
	player:SetAttribute("ArenaWins", a.Wins)
end

--------------------------------------------------
-- island + arena world references
--------------------------------------------------
local function island() return workspace:FindFirstChild("SnowplowArena") end
local function lobbySpawn()
	local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	return sp and (sp.CFrame * CFrame.new(0, 4, 0)) or CFrame.new(0, 10, 0)
end
local function plazaCF()
	local isl = island()
	local a = isl and isl:FindFirstChild("Arrival", true)
	if a and a:IsA("BasePart") then return a.CFrame end
	return CFrame.lookAt(A.Plaza + Vector3.new(0, 3, 0), A.Center + Vector3.new(0, 3, 0))
end
local function zoneInfo(zone)
	if zone == "practice" then return A.Practice.Center, A.Practice.OutRadius end
	return A.Center, A.OutRadius
end
local function planar(v) return Vector3.new(v.X, 0, v.Z) end

--------------------------------------------------
-- state
--------------------------------------------------
local P = {}          -- [player or bot table] = participant
local visitors = {}   -- [player] = {returnCF, suppressSet}
local targets = {}    -- server-owned training targets
local match = {phase = "Idle", id = nil, endsAt = 0, phaseEnds = 0, hits = 0, startedAt = 0, round = 0}
local pairCD = {}
local lastReq = {}
local lastStateSent = 0
local uidSeq = 0
local function newUid() uidSeq += 1; return uidSeq end

local function participants(zone)
	local out = {}
	for _, p in pairs(P) do if not zone or p.zone == zone then table.insert(out, p) end end
	return out
end
local function countZone(zone)
	local n = 0
	for _, p in pairs(P) do if p.zone == zone then n += 1 end end
	return n
end
local function nameOf(p) return p.player and p.player.DisplayName or p.name or "Rival" end
local function fire(p, ...) if p.player then event:FireClient(p.player, ...) end end

--------------------------------------------------
-- arena vehicle: player's cosmetic build + one normalized footprint
--------------------------------------------------
local function tint(model, color)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name:sub(1, 4) == "Tint" then d.Color = color end
	end
end
local function placeholderBumper(model, root)
	-- used only if ServerStorage.ArenaBuilt.AR_Bumper is missing: four rounded rails around the footprint
	local fp, oz = V.Footprint, V.FootprintOffsetZ
	local bm = Instance.new("Model"); bm.Name = "Bumper"
	local function rail(size, offset)
		local p = Instance.new("Part"); p.Name = "TintBumper"; p.Shape = Enum.PartType.Block; p.Size = size
		p.Material = Enum.Material.SmoothPlastic; p.CFrame = root.CFrame * CFrame.new(offset); p.Parent = bm
	end
	rail(Vector3.new(fp.X, 1.1, 1.1), Vector3.new(0, 1.2, oz - fp.Z / 2 + 0.55))
	rail(Vector3.new(fp.X, 1.1, 1.1), Vector3.new(0, 1.2, oz + fp.Z / 2 - 0.55))
	rail(Vector3.new(1.1, 1.1, fp.Z - 2.2), Vector3.new(-fp.X / 2 + 0.55, 1.2, oz))
	rail(Vector3.new(1.1, 1.1, fp.Z - 2.2), Vector3.new(fp.X / 2 - 0.55, 1.2, oz))
	bm.Parent = model
end
local function normalizeBlade(model)
	local root = model.PrimaryPart
	local blade = model:FindFirstChild("Blade")
	if not (root and blade and blade:IsA("Model")) then return end
	local cf, s = blade:GetBoundingBox()
	local rel = root.CFrame:PointToObjectSpace(cf.Position)
	local piv = root.CFrame:PointToObjectSpace(blade:GetPivot().Position)
	local k = 1
	local halfW = math.max(math.abs(rel.X - s.X / 2), math.abs(rel.X + s.X / 2))
	if halfW > V.BladeMaxHalfWidth then k = math.min(k, V.BladeMaxHalfWidth / halfW) end
	local front = rel.Z - s.Z / 2
	if front < V.BladeMaxFront and piv.Z - front > 0.1 then k = math.min(k, (piv.Z - V.BladeMaxFront) / (piv.Z - front)) end
	if k < 0.999 then pcall(function() blade:ScaleTo(blade:GetScale() * k) end) end
end
local function buildVehicle(build, paintId, label)
	local ok, model = pcall(Assembly.Build, build)
	if not ok or not model then model = Assembly.Build(C.Starter) end
	normalizeBlade(model)
	local root = model.PrimaryPart
	local tpl = SS:FindFirstChild("ArenaBuilt") and SS.ArenaBuilt:FindFirstChild("AR_Bumper")
	if tpl then
		local b = tpl:Clone(); b.Name = "Bumper"
		b:PivotTo(root.CFrame * CFrame.new(0, 0, V.FootprintOffsetZ))
		b.Parent = model
	else
		placeholderBumper(model, root)
	end
	tint(model, A.PaintById(paintId).Color)
	local fp = V.Footprint
	local hull = Instance.new("Part")
	hull.Name = "Hull"; hull.Size = fp; hull.Transparency = 1
	hull.CFrame = root.CFrame * CFrame.new(0, V.Clearance + fp.Y / 2, V.FootprintOffsetZ)
	hull.CanCollide, hull.CanQuery, hull.CanTouch = true, false, false
	hull.CollisionGroup = "ArenaVehicle"
	hull.RootPriority = 127
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0, 0, 100, 1)
	hull.Parent = model
	local seat = Instance.new("Seat")
	seat.Name = "DriverSeat"; seat.Size = Vector3.new(2.4, 0.6, 2.4); seat.Transparency = 1
	seat.CanCollide, seat.CanQuery, seat.CanTouch = false, false, false
	seat.CFrame = root.CFrame * (model:GetAttribute("SeatPos") or CFrame.new(0, 3, 1)) * CFrame.new(0, -0.3, 0)
	seat.Parent = model
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= hull then
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, false, true
			local w = Instance.new("WeldConstraint"); w.Part0 = hull; w.Part1 = part; w.Parent = part
		end
	end
	model.PrimaryPart = hull
	hull.Anchored = false
	-- name tag: name + arena title (readable, small)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Tag"; bb.Size = UDim2.fromOffset(160, 40); bb.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0); bb.MaxDistance = 140; bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Name = "Name"; t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Font = Enum.Font.FredokaOne; t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1); t.Text = label or ""
	local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = Color3.fromRGB(20, 40, 85); st.Parent = t
	t.Parent = bb; bb.Parent = hull
	return model, hull, seat
end

--------------------------------------------------
-- spawn pads
--------------------------------------------------
local function pickPad(p)
	local best, bestScore
	local zone = p.zone
	local n = zone == "practice" and #A.Practice.Pads or #A.PadAngles
	for i = 1, n do
		local cf = zone == "practice" and A.PracticePadCFrame(i) or A.PadCFrame(i)
		local nearest, blocked = math.huge, false
		for _, o in pairs(P) do
			if o ~= p and o.zone == zone and o.hull and o.hull.Parent then
				local d = (planar(o.hull.Position - cf.Position)).Magnitude
				if d < 12 then blocked = true end
				if o.state == "alive" then nearest = math.min(nearest, d) end
			end
		end
		for _, t in ipairs(targets) do
			if t.zone == zone and t.hull and t.hull.Parent and (planar(t.hull.Position - cf.Position)).Magnitude < 12 then blocked = true end
		end
		local score = (blocked and -1000 or 0) + math.min(nearest, 200) + rng:NextNumber(0, 3)
		if not bestScore or score > bestScore then best, bestScore = cf, score end
	end
	return best
end

--------------------------------------------------
-- participant vehicle lifecycle
--------------------------------------------------
local function setAttrs(p)
	local h = p.hull
	if not (h and h.Parent) then return end
	h:SetAttribute("Life", p.life); h:SetAttribute("Zone", p.zone)
	h:SetAttribute("ShieldUntil", p.shieldUntil); h:SetAttribute("BoostUntil", p.boostUntil); h:SetAttribute("BraceUntil", p.braceUntil)
	h:SetAttribute("BoostReady", p.boostReady); h:SetAttribute("BraceReady", p.braceReady)
end
local function despawnVehicle(p)
	for _, c in ipairs(p.conns or {}) do c:Disconnect() end
	p.conns = {}
	if p.model then p.model:Destroy() end
	p.model, p.hull, p.seat = nil, nil, nil
end
local koParticipant -- forward
local function holdCharacter(p)
	-- while respawning: park the character in the stands box (anchored) so it never falls off the island
	local char = p.player and p.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart then hum.Sit = false end
	local isl = island()
	local box = isl and isl:FindFirstChild("RespawnBox", true)
	local cf = box and box:IsA("BasePart") and box.CFrame or CFrame.new(A.Center + Vector3.new(0, 40, 0))
	task.defer(function()
		if hrp.Parent then char:PivotTo(cf); hrp.Anchored = true end
	end)
end
local function releaseCharacter(p)
	local char = p.player and p.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = false end
end
local function spawnParticipant(p)
	despawnVehicle(p)
	local cf = pickPad(p)
	local d = p.player and DataService.Get(p.player)
	local a = d and arenaData(d)
	local build = d and d.Plow and d.Plow.Build or C.Starter
	local label = nameOf(p)
	local title = a and titleOf(a)
	if title then label = label .. "\n" .. title end
	local model, hull, seat = buildVehicle(build, a and a.Paint or p.paint or "Classic", label)
	model.Name = "Arena_" .. (p.player and p.player.UserId or p.id)
	model:PivotTo(cf * CFrame.new(0, V.Clearance + V.Footprint.Y / 2, 0)) -- the pivot is the hull: the footprint sits centred on the pad
	local spawnHullCF = hull.CFrame
	hull:SetAttribute("OwnerUserId", p.player and p.player.UserId or 0)
	p.model, p.hull, p.seat = model, hull, seat
	p.life += 1
	p.state = "alive"
	p.shieldUntil = now() + A.Respawn.Shield
	p.boostUntil, p.braceUntil = 0, 0
	p.lastHit, p.knockVel, p.flags, p.vh, p.knockHist = nil, Vector3.zero, {}, {}, {}
	p.pendingKnock, p.lastCmd, p.mh, p.offSince = nil, nil, {}, nil
	p.lastPos, p.lastPosT = hull.Position, now()
	setAttrs(p)
	model.Parent = folder
	if p.bot then
		pcall(function() hull:SetNetworkOwner(nil) end)
		fire(p, "Spawned", {life = p.life, shieldUntil = p.shieldUntil, zone = p.zone})
		return true
	end
	local char = p.player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then despawnVehicle(p); p.state = "respawning"; return false end
	hrp.Anchored = false
	if hum.SeatPart then hum.Sit = false end
	char:PivotTo(seat.CFrame + Vector3.new(0, 2, 0))
	seat:Sit(hum)
	local t0 = os.clock()
	while os.clock() - t0 < 1 and hum.SeatPart ~= seat and p.model == model do task.wait(0.05) end
	if p.model ~= model then return false end
	if hum.SeatPart ~= seat then despawnVehicle(p); p.state = "respawning"; return false end
	hull.CFrame = spawnHullCF
	hull.AssemblyLinearVelocity, hull.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	pcall(function() hull:SetNetworkOwner(p.player) end)
	local life = p.life
	table.insert(p.conns, hum.Seated:Connect(function(active)
		if not active then task.defer(function() if p.life == life and p.state == "alive" then koParticipant(p, "seat") end end) end
	end))
	table.insert(p.conns, hum.Died:Connect(function() if p.life == life and p.state == "alive" then koParticipant(p, "died") end end))
	fire(p, "Spawned", {life = p.life, shieldUntil = p.shieldUntil, zone = p.zone})
	return true
end
local function scheduleRespawn(p, delay)
	local life = p.life
	p.respawnToken = (p.respawnToken or 0) + 1
	local token = p.respawnToken
	p.respawnAt = now() + delay
	task.delay(delay, function()
		if P[p.key] ~= p or p.state ~= "respawning" or p.life ~= life or p.respawnToken ~= token then return end
		-- the character may be respawning after a reset: wait (bounded) for a living one
		if p.player then
			local t0 = os.clock()
			while os.clock() - t0 < 8 do
				local ch = p.player.Character
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 and ch:FindFirstChild("HumanoidRootPart") then break end
				task.wait(0.25)
			end
			if P[p.key] ~= p or p.respawnToken ~= token then return end
		end
		releaseCharacter(p)
		if not spawnParticipant(p) and P[p.key] == p and p.respawnToken == token then scheduleRespawn(p, 1) end
	end)
end

--------------------------------------------------
-- rewards (cosmetic; idempotent per match id; legitimate participation only)
--------------------------------------------------
local function unlockCheck(player, a)
	for _, ac in ipairs(A.Achievements) do
		if not a.Unlocked[ac.Id] and (a[ac.Stat] or 0) >= ac.Need then
			a.Unlocked[ac.Id] = true
			local paint
			for _, pt in ipairs(A.Paints) do if pt.Unlock == ac.Id then paint = pt end end
			if paint then a.Paint = paint.Id end
			event:FireClient(player, "Unlocked", {name = ac.Name, title = ac.Title, paint = paint and paint.Name or nil})
		end
	end
	publicStats(player, a)
end
local function grantKO(p)
	if not p.player or not (match.phase == "Active" and p.zone == "match") then return end
	local d = DataService.Get(p.player)
	if not d then return end
	local a = arenaData(d)
	a.KOs += 1
	unlockCheck(p.player, a)
end
local function grantResult(p, won)
	local d = p.player and DataService.Get(p.player)
	if not d or not match.id then return false end
	local a = arenaData(d)
	if a.Seen[match.id] then return false end -- a repeated result message never grants twice
	local day = os.date("!%Y%m%d")
	if a.Day ~= day then a.Day, a.DayCount = day, 0 end
	if a.DayCount >= A.Reward.DailyCap then return false end
	a.Seen[match.id] = true
	local keys = {}
	for k in pairs(a.Seen) do table.insert(keys, k) end
	if #keys > 20 then for i = 1, #keys - 20 do a.Seen[keys[i]] = nil end end
	a.DayCount += 1
	a.Matches += 1
	if won then a.Wins += 1 end
	unlockCheck(p.player, a)
	return true
end

--------------------------------------------------
-- knockouts
--------------------------------------------------
function koParticipant(p, reason)
	if p.state ~= "alive" then return end -- one departure = one knockout (duplicates are rejected here)
	p.state = "respawning"
	local credit
	local h = p.lastHit
	local leftAt = p.offSince or now() -- a fall is credited from the moment the vehicle left the floor, not when it hit the KO depth
	if h and leftAt - h.t <= K.Attribution and match.phase == "Active" and p.zone == "match" then
		local by = h.by
		if P[by.key] == by and by.zone == "match" and by ~= p then credit = by end
	end
	if credit then
		credit.score += 1; credit.kos += 1
		fire(credit, "KO", {victim = nameOf(p)})
		grantKO(credit)
	else
		p.falls += 1
	end
	if match.phase == "Active" and p.zone == "match" then p.deaths += 1 end
	p.lastHit = nil
	local pos = p.hull and p.hull.Position
	despawnVehicle(p)
	holdCharacter(p)
	fire(p, "KnockedOut", {by = credit and nameOf(credit) or nil, reason = reason, respawnAt = now() + A.Respawn.Delay})
	event:FireAllClients("Feed", {victim = nameOf(p), by = credit and nameOf(credit) or nil, pos = pos})
	scheduleRespawn(p, A.Respawn.Delay)
end

--------------------------------------------------
-- training targets (server-owned pucks)
--------------------------------------------------
local function targetHome(zone, i)
	if zone == "practice" then
		local c = A.Practice.Center
		local spots = {Vector3.new(0, 0, -8), Vector3.new(-9, 0, 10), Vector3.new(9, 0, 10)}
		return c + spots[(i - 1) % #spots + 1]
	end
	local a = math.rad(90 + (i - 1) * 120)
	return A.Center + Vector3.new(math.cos(a), 0, math.sin(a)) * 16
end
local function spawnTarget(t)
	if t.model then t.model:Destroy() end
	local tpl = SS:FindFirstChild("ArenaBuilt") and SS.ArenaBuilt:FindFirstChild("AR_Target")
	local model
	if tpl then model = tpl:Clone() else
		model = Instance.new("Model")
		local body = Instance.new("Part"); body.Name = "Body"; body.Shape = Enum.PartType.Cylinder; body.Size = Vector3.new(3.2, 6.4, 6.4)
		body.Color = Color3.fromRGB(255, 200, 60); body.CFrame = CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90)); body.Parent = model
		model.PrimaryPart = body
	end
	model.Name = "ArenaTarget"
	local hull = Instance.new("Part")
	hull.Name = "Hull"; hull.Size = Vector3.new(7, 1.6, 7); hull.Transparency = 1
	hull.CanCollide, hull.CanQuery, hull.CanTouch = true, false, false
	hull.CollisionGroup = "ArenaVehicle"; hull.RootPriority = 127
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0, 0, 100, 1)
	local home = targetHome(t.zone, t.i)
	local cf = CFrame.new(home + Vector3.new(0, V.Clearance + 0.8, 0))
	model:PivotTo(CFrame.new(home))
	hull.CFrame = cf
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, false, true
			local w = Instance.new("WeldConstraint"); w.Part0 = hull; w.Part1 = part; w.Parent = part
		end
	end
	hull.Parent = model
	model.PrimaryPart = hull
	model.Parent = folder
	pcall(function() hull:SetNetworkOwner(nil) end)
	t.model, t.hull, t.state, t.knockVel, t.lastHit, t.vh = model, hull, "alive", Vector3.zero, nil, {}
	hull:SetAttribute("Zone", t.zone); hull:SetAttribute("Target", true)
end
local function ensureTargets(zone, n)
	local have = 0
	for i = #targets, 1, -1 do
		local t = targets[i]
		if t.zone == zone then
			have += 1
			if have > n then if t.model then t.model:Destroy() end table.remove(targets, i) end
		end
	end
	for i = have + 1, n do
		local t = {kind = "target", key = {}, uid = newUid(), zone = zone, i = i, life = 0}
		table.insert(targets, t)
		spawnTarget(t)
	end
end

--------------------------------------------------
-- match flow
--------------------------------------------------
local function standings()
	local list = {}
	for _, p in pairs(P) do
		if p.zone == "match" then table.insert(list, {name = nameOf(p), score = p.score, kos = p.kos, falls = p.falls, userId = p.player and p.player.UserId or 0, key = p}) end
	end
	table.sort(list, function(x, y)
		if x.score ~= y.score then return x.score > y.score end
		if x.falls ~= y.falls then return x.falls < y.falls end
		return x.name < y.name
	end)
	return list
end
local function stateMsg()
	local st = standings()
	local out = {}
	for i, s in ipairs(st) do out[i] = {name = s.name, score = s.score, userId = s.userId} end
	return {phase = match.phase, endsAt = match.phaseEnds, id = match.id, round = match.round, standings = out,
		count = countZone("match"), max = A.Players.Max, min = A.Players.Min, waiting = countZone("practice")}
end
local function broadcast()
	lastStateSent = os.clock()
	local msg = stateMsg()
	for pl in pairs(visitors) do event:FireClient(pl, "State", msg) end
	local isl = island() -- the scoreboard crown's screens read these (ArenaHudClient)
	if isl then
		local top = msg.standings[1]
		isl:SetAttribute("Phase", match.phase); isl:SetAttribute("PhaseEnds", match.phaseEnds); isl:SetAttribute("Drivers", msg.count)
		isl:SetAttribute("Leader", top and top.score > 0 and (top.name .. "  " .. top.score) or "")
	end
end
local function moveToZone(p, zone)
	if p.zone == zone then return end
	p.zone = zone
	if p.state == "alive" then p.state = "respawning"; despawnVehicle(p); holdCharacter(p) end
	scheduleRespawn(p, 0.2)
end
local function fillFromWaiting()
	local queue = {}
	for _, p in pairs(P) do if p.zone == "practice" then table.insert(queue, p) end end
	table.sort(queue, function(x, y) return x.joinedAt < y.joinedAt end)
	for _, p in ipairs(queue) do
		if countZone("match") >= A.Players.Max then break end
		moveToZone(p, "match")
		fire(p, "Toast", {text = "You're in! The next round starts soon."})
	end
end
local function setPhase(phase, dur)
	match.phase = phase
	match.phaseEnds = now() + (dur or 0)
	broadcast()
end
local function startRound()
	ensureTargets("match", 0)
	match.id = HttpService:GenerateGUID(false)
	match.round += 1
	match.hits = 0
	match.startedAt = now()
	for _, p in pairs(P) do
		if p.zone == "match" then
			p.score, p.kos, p.falls, p.deaths, p.activeTime, p.hits = 0, 0, 0, 0, 0, 0
			p.state = "respawning"; p.lastHit = nil; despawnVehicle(p); holdCharacter(p)
			scheduleRespawn(p, 0) -- everyone starts on a pad with a fresh shield
		end
	end
	table.clear(pairCD)
	setPhase("Active", A.Round.Duration)
	event:FireAllClients("RoundStart", {id = match.id})
end
local function endRound(reason)
	local st = standings()
	local top = st[1] and st[1].score or 0
	local eligible = 0
	for _, s in ipairs(st) do if (s.key.activeTime or 0) >= A.Reward.MinActive then eligible += 1 end end
	local roundLen = now() - match.startedAt
	local legit = reason == "time" and eligible >= A.Players.Min and match.hits >= A.Reward.MinMatchHits and roundLen >= A.Reward.MinRoundSeconds
	local winners, rows = {}, {}
	for i, s in ipairs(st) do
		local won = top > 0 and s.score == top
		if won then table.insert(winners, s.name) end
		local granted = false
		if legit and (s.key.activeTime or 0) >= A.Reward.MinActive and not s.key.bot then granted = grantResult(s.key, won) end
		rows[i] = {name = s.name, score = s.score, kos = s.kos, falls = s.falls, won = won, counted = granted}
	end
	event:FireAllClients("Results", {id = match.id, rows = rows, winners = winners, tie = #winners > 1, legit = legit, reason = reason})
	match.lastResult = {id = match.id, rows = rows, winners = winners, legit = legit, reason = reason}
	setPhase("Results", A.Round.Results)
end
local function addParticipant(player, bot)
	local key = player or bot
	local p = {key = key, uid = newUid(), player = player, bot = bot and true or nil, id = bot and bot.id or nil, name = bot and bot.name or nil,
		zone = "match", state = "respawning", life = 0, score = 0, kos = 0, falls = 0, deaths = 0, hits = 0, activeTime = 0,
		joinedAt = os.clock(), shieldUntil = 0, boostUntil = 0, braceUntil = 0, boostReady = 0, braceReady = 0, conns = {}, knockVel = Vector3.zero, flags = {}}
	if bot then p.paint = "Frost" end
	-- full match / late arrivals wait (and practise) in the practice ring
	local full = countZone("match") >= A.Players.Max
	local late = match.phase == "Active" and (match.phaseEnds - now()) < A.Round.LateJoinMinLeft
	if full or late or match.phase == "Results" then p.zone = "practice" end
	P[key] = p
	return p
end
local function removeParticipant(p, reason)
	if P[p.key] ~= p then return end
	-- leaving / disconnecting right after an opponent's hit still scores for them (no escaping an imminent knockout)
	if p.state == "alive" and p.lastHit and now() - p.lastHit.t <= K.Attribution then koParticipant(p, reason or "left") end
	P[p.key] = nil
	despawnVehicle(p)
	releaseCharacter(p)
	broadcast()
end

--------------------------------------------------
-- visiting the island, joining and leaving
--------------------------------------------------
local function setVisitor(player, on, returnCF)
	if on then
		local v = visitors[player] or {}
		v.returnCF = v.returnCF or returnCF
		if player:GetAttribute("SuppressEvents") ~= true then player:SetAttribute("SuppressEvents", true); v.suppressSet = true end
		visitors[player] = v
		player:SetAttribute("InArenaIsland", true)
		local d = DataService.Get(player)
		if d then local a = arenaData(d); publicStats(player, a); player:SetAttribute("ArenaIntroDone", a.Intro); player:SetAttribute("ArenaPaint", a.Paint) end
		event:FireClient(player, "State", stateMsg())
	else
		local v = visitors[player]
		visitors[player] = nil
		player:SetAttribute("InArenaIsland", false)
		if v and v.suppressSet and player:GetAttribute("SuppressEvents") == true then player:SetAttribute("SuppressEvents", nil) end
	end
end
local function visit(player, fromCF)
	if visitors[player] then return true end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return false, "Wait until you respawn." end
	if player:GetAttribute("IntroActive") then return false, "Finish the intro first!" end
	if not island() then return false, "The arena isn't open yet." end
	local returnCF = fromCF or hrp.CFrame
	if player:GetAttribute("InGarage") then -- leaving the garage: free the bay (offers / reserve / build stay saved)
		player:SetAttribute("InGarage", false)
		pcall(function() Registry.ReleaseBay(player) end)
		returnCF = lobbySpawn()
	end
	pcall(function() Registry.Park(player, "arena") end)
	if hum.SeatPart then hum.Sit = false end
	local cf = plazaCF()
	pcall(function() player:RequestStreamAroundAsync(cf.Position, 6) end)
	if player.Character ~= char or hum.Health <= 0 then return false, "Try again." end
	setVisitor(player, true, returnCF)
	char:PivotTo(cf * CFrame.new(rng:NextNumber(-6, 6), 0, rng:NextNumber(-3, 3)))
	hrp.AssemblyLinearVelocity = Vector3.zero
	return true
end
local function leaveIsland(player)
	local p = P[player]
	if p then removeParticipant(p, "left") end
	local v = visitors[player]
	setVisitor(player, false)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
		local cf = (v and v.returnCF) or lobbySpawn()
		pcall(function() player:RequestStreamAroundAsync(cf.Position, 6) end)
		if char.Parent then char:PivotTo(cf + Vector3.new(0, 2, 0)); hrp.AssemblyLinearVelocity = Vector3.zero end
	end
	return true
end
local function join(player, confirm)
	if not visitors[player] then return {ok = false, msg = "Visit the arena first."} end
	if P[player] then return {ok = true, already = true} end
	local d = DataService.Get(player)
	if not d then return {ok = false, msg = "Your data is still loading..."} end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return {ok = false, msg = "Wait until you respawn."} end
	-- an active Help Yard job ends through its normal cancellation (asked first)
	local job = Contracts.HasJob and Contracts.HasJob(player)
	if job then
		if confirm ~= true then return {ok = false, needConfirm = true, msg = "Joining the arena cancels your Help Yard job. Join anyway?"} end
		pcall(Contracts.Cancel, player)
	end
	pcall(function() Registry.Park(player, "arena") end)
	local p = addParticipant(player)
	scheduleRespawn(p, 0)
	broadcast()
	return {ok = true, zone = p.zone, msg = p.zone == "practice" and "The match is full or almost over - practise here, you're in the next round!" or nil}
end

--------------------------------------------------
-- abilities (server windows; the client predicts the movement)
--------------------------------------------------
local function ability(player, kind, life)
	local p = P[player]
	if not p or p.state ~= "alive" then return {ok = false} end
	if type(life) ~= "number" or life ~= p.life then return {ok = false, stale = true} end -- a request from before a respawn / an earlier match
	local t = now()
	if kind == "Boost" then
		if t < p.boostReady then return {ok = false, ready = p.boostReady} end
		p.boostUntil, p.boostReady = t + A.Boost.Duration, t + A.Boost.Cooldown
		if t < p.shieldUntil then p.shieldUntil = t end -- attacking ends your spawn protection
	else
		if t < p.braceReady then return {ok = false, ready = p.braceReady} end
		p.braceUntil, p.braceReady = t + A.Brace.Duration, t + A.Brace.Cooldown
	end
	setAttrs(p)
	event:FireAllClients("Ability", {userId = player.UserId, kind = kind, untilT = kind == "Boost" and p.boostUntil or p.braceUntil})
	return {ok = true, untilT = kind == "Boost" and p.boostUntil or p.braceUntil, ready = kind == "Boost" and p.boostReady or p.braceReady}
end

fn.OnServerInvoke = function(player, action, a1, a2)
	if type(action) ~= "string" then return {ok = false} end
	local t = os.clock()
	if (lastReq[player] or 0) > t - 0.08 then return {ok = false, msg = "Slow down!"} end
	lastReq[player] = t
	if action == "State" then return {ok = true, state = stateMsg(), visitor = visitors[player] ~= nil, joined = P[player] ~= nil}
	elseif action == "Join" then return join(player, a1 == true)
	elseif action == "LeaveMatch" then local p = P[player]; if p then removeParticipant(p, "left") end; return {ok = true}
	elseif action == "Leave" then leaveIsland(player); return {ok = true}
	elseif action == "Boost" or action == "Brace" then return ability(player, action, a1)
	elseif action == "Paint" then
		local d = DataService.Get(player)
		if not d or type(a1) ~= "string" then return {ok = false} end
		local a = arenaData(d)
		if not paintUnlocked(a, a1) then return {ok = false, msg = "Locked - win arena matches to unlock paints!"} end
		a.Paint = a1; player:SetAttribute("ArenaPaint", a1)
		local p = P[player]
		if p and p.model then tint(p.model, A.PaintById(a1).Color) end
		return {ok = true}
	elseif action == "Intro" then
		local d = DataService.Get(player)
		if d then arenaData(d).Intro = true; player:SetAttribute("ArenaIntroDone", true) end
		return {ok = true}
	end
	return {ok = false}
end

--------------------------------------------------
-- contact detection + knockback (server-authoritative)
--------------------------------------------------
local function footprint(e)
	local h = e.hull
	local cf = h.CFrame
	local look = planar(cf.LookVector); look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
	local right = Vector3.new(-look.Z, 0, look.X)
	return planar(h.Position), look, right, h.Size.X / 2, h.Size.Z / 2
end
-- separating-axis test of two rectangles in the XZ plane; returns the contact normal (A -> B) and the gap (negative = overlap)
local function rectGap(ca, la, ra, wa, da, cb, lb, rb, wb, db)
	local best, bestN
	local d = cb - ca
	for _, ax in ipairs({la, ra, lb, rb}) do
		local pa = wa * math.abs(ra:Dot(ax)) + da * math.abs(la:Dot(ax))
		local pb = wb * math.abs(rb:Dot(ax)) + db * math.abs(lb:Dot(ax))
		local dist = math.abs(d:Dot(ax))
		local gap = dist - (pa + pb)
		if not best or gap > best then best, bestN = gap, (d:Dot(ax) >= 0 and ax or -ax) end
	end
	return best, bestN
end
-- recent velocity history: a driver's client stops its own vehicle the moment it touches another (local separation), and that stop
-- replicates together with the contact - so the server judges an impact by each vehicle's approach speed over the last HIST seconds.
local HIST = 0.3
local function recordVel(e, t)
	local h = e.vh or {}
	e.vh = h
	table.insert(h, {t = t, v = planar(e.hull.AssemblyLinearVelocity)})
	while h[1] and t - h[1].t > HIST do table.remove(h, 1) end
end
local function approachSpeed(e, n)
	local best = -math.huge
	for _, s in ipairs(e.vh or {}) do best = math.max(best, s.v:Dot(n)) end
	if best == -math.huge then best = planar(e.hull.AssemblyLinearVelocity):Dot(n) end
	return best
end
local function recentMax(e)
	local m = 0
	for _, s in ipairs(e.vh or {}) do m = math.max(m, s.v.Magnitude) end
	return m
end
local function isBoosting(e, t) return e.kind ~= "target" and t < (e.boostUntil or 0) end
local function isBracing(e, t) return e.kind ~= "target" and t < (e.braceUntil or 0) end
local function isShielded(e, t) return e.kind ~= "target" and t < (e.shieldUntil or 0) end
-- plausible top speed. Latency-aware: the owner applies a knock about half a round trip after the server sends it and the server sees
-- the result another half later, so the biggest knock of the last KNOCK_GRACE seconds is allowed in full (not the decayed estimate),
-- and a boost keeps its allowance for BOOST_GRACE seconds after its window while the vehicle slows down.
local KNOCK_GRACE, BOOST_GRACE = 1.5, 0.8
local function speedLimit(e, t)
	if e.kind == "target" then return K.MaxVel + 10 end
	local top = t < (e.boostUntil or 0) + BOOST_GRACE and A.Boost.Speed or V.MaxSpeed
	local kmax = e.knockVel and e.knockVel.Magnitude or 0
	for _, k in ipairs(e.knockHist or {}) do if t - k.t <= KNOCK_GRACE then kmax = math.max(kmax, k.m) end end
	return top * A.AntiCheat.SpeedSlack + math.min(kmax, K.MaxVel) + A.AntiCheat.SpeedPad
end
local function applyKnock(e, vec)
	if vec.Magnitude < 0.01 then return end
	if e.bot then -- same order as ArenaDriveClient: applied after the next drive read-back
		e.pendingKnock = (e.pendingKnock or Vector3.zero) + vec
		return
	end
	if e.kind == "target" then
		local kv = e.knockVel + vec
		if kv.Magnitude > K.MaxVel then kv = kv.Unit * K.MaxVel end
		e.knockVel = kv
		return
	end
	local kv = (e.knockVel or Vector3.zero) + vec
	if kv.Magnitude > K.MaxVel then kv = kv.Unit * K.MaxVel end
	e.knockVel = kv -- server estimate (speed plausibility); the owner applies the real one
	local hist = e.knockHist or {}
	e.knockHist = hist
	local t = now()
	table.insert(hist, {t = t, m = kv.Magnitude})
	while hist[1] and t - hist[1].t > KNOCK_GRACE do table.remove(hist, 1) end
	fire(e, "Knock", {v = vec, life = e.life})
end
local function contacts(list, t)
	for i = 1, #list do
		local a = list[i]
		for j = i + 1, #list do
			local b = list[j]
			if not (a.kind == "target" and b.kind == "target") then
				local ca, la, ra, wa, da = footprint(a)
				local cb, lb, rb, wb, db = footprint(b)
				if (cb - ca).Magnitude < 20 then
					local gap, n = rectGap(ca, la, ra, wa, da, cb, lb, rb, wb, db)
					if gap <= K.Contact and not (isShielded(a, t) or isShielded(b, t)) then
						local key = a.uid < b.uid and (a.uid * 100000 + b.uid) or (b.uid * 100000 + a.uid)
						local aA, aB = math.max(-5, approachSpeed(a, n)), math.max(-5, approachSpeed(b, -n))
						local closing = aA + aB
						if closing >= K.MinClosing and (pairCD[key] or 0) <= t then
							-- validation: plausible speeds for both (a modified client can't fake a monster hit)
							if recentMax(a) > speedLimit(a, t) or recentMax(b) > speedLimit(b, t) then
								pairCD[key] = t + K.PairCooldown
							else
								pairCD[key] = t + K.PairCooldown
								local striker, victim, nn = a, b, n
								if aB > aA then striker, victim, nn = b, a, -n end
								local sLook = striker == a and la or lb
								local frontal = sLook:Dot(nn) >= K.FrontalDot and math.max(aA, aB) >= K.MinClosing * 0.5
								local boosted, blocked, mag = false, false, 0
								if frontal then
									boosted = isBoosting(striker, t)
									if boosted then mag = math.clamp(K.BoostBase + K.BoostPerClosing * closing, 0, K.BoostMax)
									else mag = math.clamp(K.Base + K.PerClosing * closing, 0, K.NormalMax) end
									if isBracing(victim, t) then mag *= A.Brace.KnockMult; blocked = true end
									applyKnock(victim, nn * mag)
									applyKnock(striker, -nn * mag * (boosted and K.BoostRecoil or K.Recoil))
									if boosted and striker.kind ~= "target" then striker.boostUntil = t; setAttrs(striker) end
									if victim.kind ~= "target" or striker.kind ~= "target" then
										victim.lastHit = {by = striker, t = t}
									end
									if striker.hits then striker.hits += 1 end
									if victim.kind ~= "target" and striker.kind ~= "target" and match.phase == "Active" and a.zone == "match" then match.hits += 1 end
								else
									mag = K.Scrape
									applyKnock(a, -n * K.Scrape); applyKnock(b, n * K.Scrape)
								end
								local pos = (ca + cb) / 2 + Vector3.new(0, a.hull.Position.Y, 0)
								event:FireAllClients("Impact", {pos = pos, n = nn, mag = mag, boosted = boosted, blocked = blocked,
									striker = striker.player and striker.player.UserId or 0, victim = victim.player and victim.player.UserId or 0})
							end
						end
					end
				end
			end
		end
	end
end

--------------------------------------------------
-- server simulation for targets / Studio test bots (server-owned assemblies)
--------------------------------------------------
local rideParams = RaycastParams.new()
rideParams.FilterType = Enum.RaycastFilterType.Exclude
rideParams.FilterDescendantsInstances = {folder}
local function holdHeight(hull)
	local hit = workspace:Raycast(hull.Position + Vector3.new(0, 2, 0), Vector3.new(0, -10, 0), rideParams)
	if not hit then return nil end -- airborne (off the edge): gravity takes over
	local want = hit.Position.Y + V.Clearance + hull.Size.Y / 2
	return math.clamp((want - hull.Position.Y) * V.RideStiffness, -40, 22)
end
local function simTarget(t, dt)
	local h = t.hull
	if not (h and h.Parent) then return end
	t.knockVel *= math.exp(-K.Decay * dt)
	local vy = holdHeight(h)
	if not vy then -- falling: momentum + gravity only (sideways speed capped like vehicles)
		local pv = planar(h.AssemblyLinearVelocity)
		if pv.Magnitude > A.Void.AirMax then pv = pv.Unit * A.Void.AirMax; h.AssemblyLinearVelocity = Vector3.new(pv.X, h.AssemblyLinearVelocity.Y, pv.Z) end
		return
	end
	h.AssemblyLinearVelocity = Vector3.new(t.knockVel.X, vy, t.knockVel.Z)
	h.AssemblyAngularVelocity = Vector3.new(0, h.AssemblyAngularVelocity.Y * 0.9, 0) + h.CFrame.UpVector:Cross(Vector3.yAxis) * 6
end
local function simBot(p, dt)
	local h = p.hull
	if not (h and h.Parent) then return end
	local t = now()
	local cf = h.CFrame
	local look = planar(cf.LookVector).Unit
	-- chase the nearest alive opponent (simple test driver)
	local goal, gd
	for _, o in pairs(P) do
		if o ~= p and o.zone == p.zone and o.state == "alive" and o.hull and o.hull.Parent then
			local d = (planar(o.hull.Position - h.Position)).Magnitude
			if not gd or d < gd then goal, gd = o, d end
		end
	end
	local throttle, steer = 0, 0
	if p.botMode == "chase" and goal then
		local to = planar(goal.hull.Position - h.Position).Unit
		local cross = look:Cross(to).Y
		steer = math.clamp(-cross * 3, -1, 1); throttle = 1
		if gd < 24 and look:Dot(to) > 0.95 and t >= p.boostReady then p.boostUntil, p.boostReady = t + A.Boost.Duration, t + A.Boost.Cooldown; setAttrs(p) end
	elseif p.botMode == "brace" and goal and gd < 16 and t >= p.braceReady then
		p.braceUntil, p.braceReady = t + A.Brace.Duration, t + A.Brace.Cooldown; setAttrs(p)
	end
	if p.botMove then throttle, steer = p.botMove.X, p.botMove.Y end
	local pv = planar(h.AssemblyLinearVelocity)
	local vy = holdHeight(h)
	if not vy then -- falling (same rule as ArenaDriveClient): no driving in the air, momentum + gravity only
		if p.pendingKnock then pv += planar(p.pendingKnock); p.pendingKnock = nil end
		local zc = zoneInfo(p.zone)
		local out = planar(h.Position - zc)
		if out.Magnitude > 1 then
			local along = pv:Dot(out.Unit)
			if along < A.Void.SlideOff then pv += out.Unit * (A.Void.SlideOff - along) end
		end
		if pv.Magnitude > A.Void.AirMax then pv = pv.Unit * A.Void.AirMax end
		h.AssemblyLinearVelocity = Vector3.new(pv.X, h.AssemblyLinearVelocity.Y, pv.Z)
		p.knockVel, p.lastCmd = Vector3.zero, nil
		return
	end
	if p.knockVel.Magnitude > 0.1 and p.lastCmd then -- a wall absorbed part of the push: take it out of the knockback (no rebound)
		local kd = p.knockVel.Unit
		local lost = (p.lastCmd - pv):Dot(kd)
		if lost > 0 then p.knockVel -= kd * math.min(lost, p.knockVel.Magnitude) end
	end
	local vel = pv - p.knockVel
	local fwd = vel:Dot(look)
	local right = Vector3.new(-look.Z, 0, look.X)
	local lat = vel:Dot(right)
	local maxS = V.MaxSpeed * (t < p.braceUntil and A.Brace.SpeedMult or 1)
	local target, rate = throttle * maxS, V.Accel
	if t < p.boostUntil then target, rate = A.Boost.Speed, A.Boost.Accel end
	fwd += math.clamp(target - fwd, -rate * dt, rate * dt)
	lat *= math.max(0, 1 - V.LateralGrip * dt)
	p.knockVel *= math.exp(-K.Decay * dt)
	if p.pendingKnock then p.knockVel += p.pendingKnock; p.pendingKnock = nil end
	if p.knockVel.Magnitude > K.MaxVel then p.knockVel = p.knockVel.Unit * K.MaxVel end
	local pl = look * fwd + right * lat + p.knockVel
	p.lastCmd = pl
	h.AssemblyLinearVelocity = Vector3.new(pl.X, vy, pl.Z)
	h.AssemblyAngularVelocity = Vector3.new(0, -steer * V.TurnRate, 0) + cf.UpVector:Cross(Vector3.yAxis) * 6
end

--------------------------------------------------
-- main loop: contacts, ring-outs, plausibility, phases
--------------------------------------------------
local function aliveIn(zone)
	local list = {}
	for _, p in pairs(P) do if p.zone == zone and p.state == "alive" and p.hull and p.hull.Parent then table.insert(list, p) end end
	for _, t in ipairs(targets) do if t.zone == zone and t.state == "alive" and t.hull and t.hull.Parent then table.insert(list, t) end end
	return list
end
local function checkOut(e, zone)
	local c, out = zoneInfo(zone)
	local pos = e.hull.Position
	local r = (planar(pos - c)).Magnitude
	if zone == "practice" then return r > out or pos.Y < c.Y - A.FallDepth end
	-- main floor: a pushed-off vehicle falls into the exit pit for real; the knockout comes when it is well below the island top.
	-- Anything else off the floor (stuck, hovering, flung far) is out after OffTime / past EscapeRadius, so a fall always ends at the respawn.
	local VD = A.Void
	if pos.Y < c.Y - VD.Depth or r > VD.EscapeRadius then return true end
	if r > VD.Edge or pos.Y < c.Y - 2 then
		e.offSince = e.offSince or now()
		return now() - e.offSince > VD.OffTime
	end
	e.offSince = nil
	return false
end
local function targetOut(t)
	t.state = "out"; t.offSince = nil
	local by = t.lastHit and now() - t.lastHit.t <= K.Attribution and t.lastHit.by
	if by and by.player then fire(by, "TargetOut", {}) end
	if t.model then t.model:Destroy() end
	t.model, t.hull = nil, nil
	task.delay(A.Targets.RespawnDelay, function()
		for _, x in ipairs(targets) do if x == t then spawnTarget(t) return end end
	end)
end
local function plausibility(p, t, dt)
	-- impossible movement: speed far above the arena cap or a teleport-sized jump -> put the vehicle back on a pad
	local h = p.hull
	local pos = h.Position
	local lim = speedLimit(p, t)
	-- touching another vehicle: the owner's local separation (max 18 studs/s) may add speed before the server sees the contact
	for _, e in ipairs(aliveIn(p.zone)) do
		if e ~= p and e.hull and (planar(e.hull.Position - pos)).Magnitude < 18 then lim += 20 break end
	end
	local moved = (planar(pos - p.lastPos)).Magnitude
	local elapsed = math.max(1 / 60, t - p.lastPosT)
	-- replicated positions can arrive in bursts on a laggy connection: allow up to 0.25 s of travel per server frame (+12 studs)
	local speed = planar(h.AssemblyLinearVelocity).Magnitude
	-- distance over a sliding 1 s window closes the gap a per-frame burst allowance would leave (position stepping with zero velocity)
	local mh = p.mh or {}
	p.mh = mh
	table.insert(mh, {t = t, d = moved})
	while mh[1] and t - mh[1].t > 1 do table.remove(mh, 1) end
	local sum = 0
	for _, m in ipairs(mh) do sum += m.d end
	local bad = speed > lim or moved > lim * math.max(elapsed, 0.25) + 12 or sum > lim + 25
	p.lastPos, p.lastPosT = pos, t
	if not bad then return end
	p.lastFlag = string.format("speed %.1f moved %.1f in %.3fs (%.0f in 1 s), limit %.1f", speed, moved, elapsed, sum, lim)
	table.insert(p.flags, t)
	while p.flags[1] and t - p.flags[1] > A.AntiCheat.FlagWindow do table.remove(p.flags, 1) end
	if #p.flags >= A.AntiCheat.Flags then
		warn("[ArenaService] implausible movement from " .. nameOf(p) .. " - vehicle reset (" .. tostring(p.lastFlag) .. ")")
		p.flags = {}
		p.state = "respawning"; p.lastHit = nil
		despawnVehicle(p); holdCharacter(p)
		scheduleRespawn(p, 1)
	end
end
RunService.Heartbeat:Connect(function(dt)
	local t = now()
	for _, tg in ipairs(targets) do if tg.state == "alive" then simTarget(tg, dt) end end
	for _, p in pairs(P) do
		if p.state == "alive" and p.hull and p.hull.Parent then
			if p.bot then simBot(p, dt) else p.knockVel = (p.knockVel or Vector3.zero) * math.exp(-K.Decay * dt) end
		end
	end
	for _, zone in ipairs({"match", "practice"}) do
		local list = aliveIn(zone)
		for _, e in ipairs(list) do recordVel(e, t) end
		contacts(list, t)
		for _, e in ipairs(list) do
			if e.state == "alive" and e.hull and e.hull.Parent then
				if checkOut(e, zone) then
					if e.kind == "target" then targetOut(e) else koParticipant(e, zone == "match" and "fell" or "out") end
				elseif e.kind ~= "target" and not e.bot and not e.offSince then -- a falling vehicle keeps its launch speed (no false speed flags)
					plausibility(e, t, dt)
				end
			end
		end
	end
	if match.phase == "Active" then
		for _, p in pairs(P) do if p.zone == "match" then p.activeTime = (p.activeTime or 0) + dt end end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		local t = now()
		local n = countZone("match")
		if match.phase == "Idle" then
			ensureTargets("match", n > 0 and A.Targets.MainIdle or 0)
			if n >= A.Players.Min then setPhase("Countdown", A.Round.Countdown) end
		elseif match.phase == "Countdown" then
			ensureTargets("match", A.Targets.MainIdle)
			fillFromWaiting()
			if countZone("match") < A.Players.Min then setPhase("Idle")
			elseif t >= match.phaseEnds then startRound() end
		elseif match.phase == "Active" then
			if n < A.Players.Min then endRound("players")
			elseif t >= match.phaseEnds then endRound("time") end
		elseif match.phase == "Results" then
			if t >= match.phaseEnds then
				match.id = nil
				fillFromWaiting()
				if countZone("match") >= A.Players.Min then setPhase("Countdown", A.Round.Countdown) else setPhase("Idle") end
			end
		end
		ensureTargets("practice", countZone("practice") > 0 and A.Targets.Practice or 0)
		if os.clock() - lastStateSent > 1 then broadcast() end
		-- island guard: visitors who fell, or were teleported away by something else (boss event, rebirth, admin)
		local isl = island()
		for pl in pairs(visitors) do
			local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
			if hrp and isl and not hrp.Anchored then
				local d = (hrp.Position - A.Center).Magnitude
				local p = P[pl]
				if d > 600 then
					if p then removeParticipant(p, "left") end
					setVisitor(pl, false)
				elseif hrp.Position.Y < A.Center.Y - 40 and not (p and p.state == "alive") then
					pl.Character:PivotTo(plazaCF() + Vector3.new(0, 2, 0))
				end
			end
		end
	end
end)

--------------------------------------------------
-- portals (lobby / garage / island return) + player lifecycle
--------------------------------------------------
local promptCD = {}
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, player)
	local kind = prompt:GetAttribute("ArenaPortal")
	if not kind then return end
	if (promptCD[player] or 0) > os.clock() then return end
	promptCD[player] = os.clock() + 1.5
	local res, msg
	if kind == "Return" then res = leaveIsland(player) else
		local anchor = prompt.Parent
		local back = anchor:IsA("BasePart") and (anchor.CFrame * CFrame.new(0, 2, -8)) or nil
		res, msg = visit(player, back)
	end
	if not res and msg then event:FireClient(player, "Toast", {text = msg}) end
end)
Players.PlayerRemoving:Connect(function(pl)
	local p = P[pl]
	if p then removeParticipant(p, "disconnect") end
	visitors[pl] = nil; lastReq[pl] = nil; promptCD[pl] = nil
end)
local function watch(pl)
	pl:SetAttribute("InArenaIsland", false)
	pl.CharacterAdded:Connect(function(char)
		local p = P[pl]
		if p then
			-- reset / death mid-match: the knockout was already processed; bring the new character back for the respawn
			task.defer(function()
				local hrp = char:WaitForChild("HumanoidRootPart", 5)
				if hrp and P[pl] == p and p.state == "respawning" then holdCharacter(p) end
			end)
		elseif visitors[pl] then
			task.defer(function()
				local hrp = char:WaitForChild("HumanoidRootPart", 5)
				if hrp and visitors[pl] then char:PivotTo(plazaCF()) end
			end)
		end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, pl in ipairs(Players:GetPlayers()) do watch(pl) end
DataService.OnLoaded(function(player, d) local a = arenaData(d); publicStats(player, a) end)

--------------------------------------------------
-- Studio test hook (isolated BalanceTestMode sessions only)
--------------------------------------------------
if TEST then
	local hook = Instance.new("BindableFunction"); hook.Name = "ArenaTestHook"; hook.Parent = SS
	local bots = {}
	hook.OnInvoke = function(op, a1, a2, a3)
		if op == "State" then
			local list = {}
			for _, p in pairs(P) do
				table.insert(list, {name = nameOf(p), zone = p.zone, state = p.state, life = p.life, score = p.score, kos = p.kos, falls = p.falls,
					hits = p.hits, active = math.floor((p.activeTime or 0) * 10) / 10, pos = p.hull and p.hull.Position or nil,
					shield = math.max(0, (p.shieldUntil or 0) - now()), knock = p.knockVel and p.knockVel.Magnitude or 0})
			end
			return {phase = match.phase, left = match.phaseEnds - now(), id = match.id, hits = match.hits, round = match.round, participants = list,
				targets = #targets, last = match.lastResult}
		elseif op == "AddBot" then
			local id = -(#bots + 1)
			local bot = {id = id, name = a1 or ("TestRival" .. -id)}
			table.insert(bots, bot)
			local p = addParticipant(nil, bot)
			p.botMode = a2 or "idle"
			scheduleRespawn(p, 0)
			return id
		elseif op == "Bot" then -- a1 = bot id, a2 = field, a3 = value (botMode / botMove Vector2(throttle, steer) / place CFrame)
			for _, p in pairs(P) do
				if p.bot and p.id == a1 then
					if a2 == "place" and p.hull then p.model:PivotTo(a3 * CFrame.new(0, V.Clearance + V.Footprint.Y / 2, 0)); p.hull.AssemblyLinearVelocity = Vector3.zero
					elseif a2 == "boost" then local t = now(); p.boostUntil, p.boostReady = t + A.Boost.Duration, t + A.Boost.Cooldown; setAttrs(p)
					elseif a2 == "brace" then local t = now(); p.braceUntil, p.braceReady = t + A.Brace.Duration, t + A.Brace.Cooldown; setAttrs(p)
					elseif a2 == "shieldOff" then p.shieldUntil = 0; setAttrs(p)
					else p[a2] = a3 end
					return true
				end
			end
			return false
		elseif op == "RemoveBot" then
			for _, p in pairs(P) do if p.bot and p.id == a1 then removeParticipant(p, "left") return true end end
			return false
		elseif op == "PlaceMe" then -- a1 = player, a2 = floor CFrame: test placement that the movement check knows about
			local p = P[a1]; if not (p and p.hull) then return false end
			pcall(function() p.hull:SetNetworkOwner(nil) end)
			p.model:PivotTo(a2 * CFrame.new(0, V.Clearance + V.Footprint.Y / 2, 0))
			p.hull.AssemblyLinearVelocity = Vector3.zero
			p.lastPos, p.lastPosT, p.flags, p.vh, p.mh = p.hull.Position, now(), {}, {}, {}
			task.delay(0.25, function() if p.hull and p.hull.Parent then pcall(function() p.hull:SetNetworkOwner(a1) end); p.lastPos, p.lastPosT = p.hull.Position, now() end end)
			return true
		elseif op == "Score" then -- a1 = bot id, a2 = score (tie / winner checks)
			for _, p in pairs(P) do if p.bot and p.id == a1 then p.score = a2; return true end end
			return false
		elseif op == "Phase" then -- jump the timer: a1 = seconds left in the current phase
			match.phaseEnds = now() + (a1 or 0); broadcast(); return match.phase
		elseif op == "Visit" then return visit(a1)
		elseif op == "Join" then return join(a1, a2)
		elseif op == "Leave" then return leaveIsland(a1)
		elseif op == "KO" then -- a1 = player: simulate a duplicate departure report
			local p = P[a1]; if p then koParticipant(p, "test"); koParticipant(p, "test-duplicate") end; return p and p.state
		elseif op == "Grant" then -- replay the last result for a player (idempotency check)
			local p = P[a1]; if not p then return "no participant" end
			return grantResult(p, a2 == true)
		elseif op == "Data" then
			local d = DataService.Get(a1); return d and arenaData(d)
		end
	end
end
