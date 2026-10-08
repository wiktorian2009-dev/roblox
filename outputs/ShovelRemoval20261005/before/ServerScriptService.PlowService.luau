-- PlowService (2026-10-04, Claude): server side of the snowplow loop.
--   * personal part offers (roll / buy / reserve / reroll), owned parts and the selected build - saved through DataService (data.Plow)
--   * garage equip / unequip, and the vehicle itself (spawn at a safe spot, seat, cleanup, recover)
--   * field clearing is done by SnowFieldService from the vehicle registered in PlowRegistry
-- Every request is validated here; clients only ask. Studio tests: ServerStorage.BalanceTestMode = true.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local C = require(RS:WaitForChild("PlowConfig"))
if C.Mode ~= "Snowplow" then return end
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
	local function pub(o) if not o then return nil end return {Part = o.Part, Token = o.Token, Price = o.Price} end
	local parts = {}
	for id, n in pairs(p.Parts) do parts[id] = n end
	return {Mode = C.Mode, Parts = parts, Build = {Blade = p.Build.Blade, Engine = p.Build.Engine, Gear = p.Build.Gear},
		Offers = {["1"] = pub(p.Offers["1"]), ["2"] = pub(p.Offers["2"]), ["3"] = pub(p.Offers["3"])}, Reserved = pub(p.Reserved), InGarage = player:GetAttribute("InGarage") == true, Snow = d.Snow, Cooldown = math.max(0, (cooldown[player] or 0) - os.clock()),
		Driving = Registry.Active[player] ~= nil, TutorialDone = p.TutorialDone == true}
end
local function pickPart(player, d)
	local luck = math.max(1, (tonumber(d.Luck) or 1) * (player:GetAttribute("LuckMult") or 1))
	local ids = {}
	for id, def in pairs(C.Parts) do if def.Weight > 0 then table.insert(ids, id) end end
	table.sort(ids)
	local w, total = {}, 0
	for _, id in ipairs(ids) do
		local def = C.Parts[id]
		w[id] = def.Weight * luck ^ (C.Shop.LuckExponent * math.max(0, RANK[def.Rarity] - 2))
		total += w[id]
	end
	local r = rng:NextNumber() * total
	for _, id in ipairs(ids) do r -= w[id]; if r <= 0 then return id end end
	return ids[#ids]
end

--------------------------------------------------
-- the vehicle
--------------------------------------------------
local function mods(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local ws = hum and hum.WalkSpeed or 16
	return {PowerMult = player:GetAttribute("PowerMult") or 1, PowerBonus = player:GetAttribute("PowerBonus") or 0, SizeMult = player:GetAttribute("SizeMult") or 1,
		ReachMult = player:GetAttribute("ReachMult") or 1, SpinMult = player:GetAttribute("SpinMult") or 1, SpeedMult = 1 + math.clamp(ws / 16 - 1, 0, 1) * 0.5}
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
local function spawnVehicle(player, d, p)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return fail("Wait until you respawn.") end
	if player:GetAttribute("IntroActive") then return fail("Finish the intro first!") end
	if hum.SeatPart then return fail("You're already sitting somewhere.") end
	local build = p.Build
	if not (build.Engine and build.Gear) then return fail("Your snowplow needs an engine and running gear - open the GARAGE!") end
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
	hull.CFrame = rootCF * CFrame.new(0, C.Vehicle.HullClearance + hs.Y / 2, 0)
	hull.CanCollide, hull.CanQuery, hull.CanTouch = true, false, false
	hull.CollisionGroup = "PlowVehicle"
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
	hull:SetAttribute("Traction", stats.Traction); hull:SetAttribute("Stability", stats.Stability); hull:SetAttribute("Pivot", stats.Pivot)
	model.Parent = folder
	local v = {model = model, hull = hull, seat = seat, stats = stats, build = {Blade = build.Blade, Engine = build.Engine, Gear = build.Gear},
		safeCF = hull.CFrame, spawnedAt = os.clock(), flags = 0, conns = {}}
	Registry.Active[player] = v
	player:SetAttribute("PlowDriving", true)
	table.insert(v.conns, hum.Died:Connect(function() despawn(player, "died") end))
	seat:Sit(hum)
	local t0 = os.clock()
	while os.clock() - t0 < 1.0 and hum.SeatPart ~= seat and Registry.Active[player] == v do task.wait(0.05) end
	if Registry.Active[player] ~= v then return fail("Couldn't hop in - try again.") end
	if hum.SeatPart ~= seat then despawn(player, "seat failed"); return fail("Couldn't hop in - try again.") end
	pcall(function() hull:SetNetworkOwner(player) end)
	table.insert(v.conns, hum.Seated:Connect(function(active) if not active then task.defer(despawn, player, "exit") end end))
	ev:FireClient(player, "Spawned")
	return {ok = true, driving = true}
end

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
	if (cooldown[player] or 0) > os.clock() then return fail("Rolling too fast - one moment!") end
	cooldown[player] = os.clock() + C.Shop.RollCooldown
	local id = pickPart(player, d)
	p.Seq += 1
	p.Rolls += 1
	p.Offers[slot] = {Part = id, Token = HttpService:GenerateGUID(false), Price = C.Parts[id].Price, Seq = p.Seq}
	player:SetAttribute("PlowOffered", true)
	return {ok = true, rolled = true, slot = slot, rank = RANK[C.Parts[id].Rarity]}
end
actions.Reroll = actions.Roll
function actions.Buy(player, d, p, which, token)
	if which ~= "Reserved" and not SLOTS[which] then return fail("Bad request") end
	local o = which == "Reserved" and p.Reserved or p.Offers[which]
	if type(token) ~= "string" or not o or o.Token ~= token then return fail("That offer is gone - roll a new one!", {stale = true}) end
	local def = C.Parts[o.Part]
	if not def then
		if which == "Reserved" then p.Reserved = nil else p.Offers[which] = nil end
		return fail("That part no longer exists.")
	end
	local price = o.Price
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
	return {ok = true, bought = o.Part, msg = "Bought " .. def.Name .. "!"}
end
function actions.Reserve(player, d, p, slot, token, confirm)
	slot = tostring(slot or "")
	if not SLOTS[slot] then return fail("Bad request") end
	local o = p.Offers[slot]
	if type(token) ~= "string" or not o or o.Token ~= token then return fail("That offer is gone - roll a new one!", {stale = true}) end
	if p.Reserved and confirm ~= true then return fail("Replace your reserved part?", {needConfirm = true}) end
	p.Reserved = o
	p.Offers[slot] = nil
	return {ok = true, msg = "Reserved " .. C.Parts[o.Part].Name .. "!"}
end
function actions.Equip(player, d, p, slot, id)
	if type(slot) ~= "string" or type(id) ~= "string" then return fail("Bad request") end
	local def = C.Parts[id]
	if not def or def.Slot ~= slot or not table.find(C.Slots, slot) then return fail("That part doesn't fit that slot.") end
	if (p.Parts[id] or 0) < 1 then return fail("You don't own that part.") end
	if Registry.Active[player] then return fail("Park your snowplow first (EXIT), then change parts.") end
	p.Build[slot] = id
	player:SetAttribute("PlowEquipped", true)
	return {ok = true, msg = def.Name .. " equipped!"}
end
function actions.Unequip(player, d, p, slot)
	if type(slot) ~= "string" or not table.find(C.Slots, slot) then return fail("Bad request") end
	if Registry.Active[player] then return fail("Park your snowplow first (EXIT), then change parts.") end
	p.Build[slot] = nil
	return {ok = true, msg = "Unequipped - the part stays in your inventory."}
end
function actions.Drive(player, d, p)
	if player:GetAttribute("InGarage") then return fail("Go back to the lobby to drive - tap LOBBY!") end
	if Registry.Active[player] then despawn(player, "exit"); return {ok = true, driving = false} end
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
function actions.TutorialDone(player, d, p) p.TutorialDone = true; return {ok = true} end

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
function actions.GoGarage(player, d, p)
	if player:GetAttribute("InGarage") then return fail("You're already in the garage!") end
	if player:GetAttribute("IntroActive") then return fail("Finish the intro first!") end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return fail("Wait until you respawn.") end
	local arrival = garageArrival()
	if not arrival then return fail("The garage isn't open yet.") end
	if Registry.Active[player] then despawn(player, "garage") end
	if hum.SeatPart then hum.Sit = false end
	returnCF[player] = hrp.CFrame
	pcall(function() player:RequestStreamAroundAsync(arrival.Position) end)
	if not char.Parent or hum.Health <= 0 then return fail("Try again.") end
	player:SetAttribute("InGarage", true)
	char:PivotTo(arrival.CFrame)
	return {ok = true, msg = "Welcome to the Garage! Roll parts on the pedestals."}
end
function actions.GoLobby(player, d, p)
	if not player:GetAttribute("InGarage") then return fail("You're not in the garage.") end
	local char = player.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return fail("Wait until you respawn.") end
	local cf = returnCF[player] or lobbySpawn()
	pcall(function() player:RequestStreamAroundAsync(cf.Position) end)
	player:SetAttribute("InGarage", false)
	returnCF[player] = nil
	char:PivotTo(cf + Vector3.new(0, 2, 0))
	return {ok = true, msg = "Back in the lobby!"}
end
local function watchGarage(pl)
	pl:SetAttribute("InGarage", false)
	pl.CharacterAdded:Connect(function() pl:SetAttribute("InGarage", false); returnCF[pl] = nil end)
end
Players.PlayerAdded:Connect(watchGarage)
for _, pl in ipairs(Players:GetPlayers()) do watchGarage(pl) end
Players.PlayerRemoving:Connect(function(pl) returnCF[pl] = nil end)
task.spawn(function() -- fell off the island, or was teleported away by an event
	while true do
		task.wait(1)
		local arrival = garageArrival()
		for _, pl in ipairs(Players:GetPlayers()) do
			if arrival and pl:GetAttribute("InGarage") then
				local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					if (hrp.Position - arrival.Position).Magnitude > 220 then pl:SetAttribute("InGarage", false)
					elseif hrp.Position.Y < arrival.Position.Y - 25 then hrp.CFrame = arrival.CFrame end
				end
			end
		end
	end
end)

local function handle(player, action, a, b, c)
	if type(action) ~= "string" then return fail("Bad request") end
	local d = DataService.Get(player)
	if not d or not d.Plow then return fail("Your data is still loading...") end
	if action ~= "State" then
		if (lastCall[player] or 0) > os.clock() - 0.05 then return fail("Slow down!") end
		lastCall[player] = os.clock()
	end
	local handler = actions[action]
	if not handler then return fail("Unknown action") end
	local ok, res = pcall(handler, player, d, d.Plow, a, b, c)
	if not ok then warn("[PlowService] " .. action .. ": " .. tostring(res)); return fail("Something went wrong - try again.") end
	if type(res) == "table" then res.state = snapshot(player, d) end
	return res
end

fn.OnServerInvoke = handle
if TEST then -- isolated Studio tests only: lets a server test script call the real handler (ServerStorage.PlowTestHook)
	local hook = Instance.new("BindableFunction"); hook.Name = "PlowTestHook"; hook.Parent = SS
	hook.OnInvoke = function(player, action, a, b, c) return handle(player, action, a, b, c) end
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
