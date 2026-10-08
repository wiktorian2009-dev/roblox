-- TravelService (2026-10-05, Claude): free quick travel (TRAVEL menu + lobby teleporter pad).
-- The client sends ONLY a destination id ("Travel", id, confirm). Everything else is decided here: the destination must exist in
-- TravelConfig, be unlocked (Stage_<Id> attributes from StageService), the player must be alive, not mid-intro, not on the arena
-- island (the arena has its own LEAVE ARENA cleanup), not already travelling, and outside the cooldown.
-- Vehicles: a driven plow is parked through PlowRegistry.Park (unseats + destroys) BEFORE the character moves; after arrival the
-- same saved build is spawned again through PlowRegistry.Spawn (PlowService's normal spawn path). The garage always goes through
-- PlowService's bay lease (PlowRegistry.GoGarage / LeaveGarage). An active NPC job is only cancelled after the player confirmed,
-- through ContractRegistry.Cancel (the normal cleanup: yard + personal snow released, no reward).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlowRegistry = require(script.Parent:WaitForChild("PlowRegistry"))
local ContractRegistry = require(script.Parent:WaitForChild("ContractRegistry"))
local T = require(RS:WaitForChild("TravelConfig"))

local remote = RS:FindFirstChild("TravelRemote") or Instance.new("RemoteFunction")
remote.Name = "TravelRemote"
remote.Parent = RS
local points = workspace:WaitForChild("TravelPoints", 30)

local busy, last = {}, {}
local function fail(msg, extra) local r = extra or {}; r.ok = false; r.msg = msg; return r end

-- where is the player now? (garage, or the nearest arrival point of their world)
local function currentId(player)
	if player:GetAttribute("InGarage") then return "Garage" end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (hrp and points) then return nil end
	local best, bestD
	for _, p in ipairs(points:GetChildren()) do
		if p:IsA("BasePart") then
			local dd = (p.Position - hrp.Position).Magnitude
			if not bestD or dd < bestD then best, bestD = p.Name, dd end
		end
	end
	return bestD and bestD < 160 and best or nil
end

local function travel(player, id, confirm)
	local dest = type(id) == "string" and T.ById[id]
	if not dest then return fail("Unknown destination.") end
	local d = DataService.Get(player)
	if not d then return fail("Your data is still loading...") end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return fail("Wait until you respawn.") end
	if player:GetAttribute("IntroActive") then return fail("Finish the intro first!") end
	if player:GetAttribute("InArenaIsland") then return fail("You're at the arena - tap LEAVE ARENA first.") end
	if not T.Unlocked(player, dest) then return fail("Locked - " .. T.Requirement(dest) .. ".") end
	if dest.Id == "Garage" and player:GetAttribute("InGarage") then return fail("You're already in your garage!") end
	-- an active NPC job: one clear warning, then the normal cancellation (never a reward)
	if ContractRegistry.HasJob(player) then
		if confirm ~= true then return fail("Travelling cancels your current job (no reward). Tap again to go.", {needConfirm = true}) end
		ContractRegistry.Cancel(player)
	end
	if dest.Id == "Garage" then
		local r = PlowRegistry.GoGarage(player)
		return r
	end
	local point = points and points:FindFirstChild(dest.Id)
	if not point then return fail("That destination isn't ready yet.") end
	local wasDriving = PlowRegistry.Active[player] ~= nil
	if player:GetAttribute("InGarage") then PlowRegistry.LeaveGarage(player) end
	if wasDriving and PlowRegistry.Park then PlowRegistry.Park(player, "travel") end
	if hum.SeatPart then hum.Sit = false end
	-- bounded streaming wait, then re-check the character (it may have died or respawned meanwhile)
	pcall(function() player:RequestStreamAroundAsync(point.Position, T.StreamTimeout) end)
	if player.Character ~= char or hum.Health <= 0 or not hrp.Parent then return fail("Travel cancelled.") end
	if hum.SeatPart then hum.Sit = false; task.wait() end
	char:PivotTo(point.CFrame + Vector3.new(0, 3, 0))
	hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	player:SetAttribute("World", point:GetAttribute("World") or dest.World or 1)
	local msg = dest.Id == "Lobby" and "Back in the lobby!" or ("Welcome to " .. dest.Name .. "!")
	if wasDriving then -- bring the same build back where driving is allowed
		task.wait(0.35)
		if player.Character == char and hum.Health > 0 then
			local ok, r = pcall(PlowRegistry.Spawn, player)
			if not (ok and type(r) == "table" and r.ok) then msg ..= " Tap DRIVE to get your plow." end
		end
	end
	return {ok = true, msg = msg, at = dest.Id}
end

local function handle(player, action, id, confirm)
	if action == "Where" then return {ok = true, at = currentId(player)} end
	if action ~= "Travel" then return fail("Bad request") end
	if busy[player] then return fail("Already travelling...") end
	local now = os.clock()
	if last[player] and now - last[player] < T.Cooldown then return fail("One moment...") end
	busy[player] = true
	local ok, res = pcall(travel, player, id, confirm == true)
	busy[player] = nil
	if not ok then warn("[TravelService] " .. tostring(res)); return fail("Travel failed - try again.") end
	if type(res) == "table" and res.ok then last[player] = os.clock() end
	if type(res) == "table" then res.at = res.at or currentId(player) end
	return res
end
remote.OnServerInvoke = handle
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; last[p] = nil end)

-- Studio isolated tests only
if game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("BalanceTestMode") == true then
	local hook = Instance.new("BindableFunction"); hook.Name = "TravelTestHook"
	hook.OnInvoke = function(player, id, confirm) return handle(player, "Travel", id, confirm) end
	hook.Parent = game:GetService("ServerStorage")
end
