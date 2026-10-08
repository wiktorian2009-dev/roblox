-- AfkService (2026-10-06, Claude): the AFK auto-plow toggle (wiktor: "some afk button so it will collect snow afk it should be next to upgrades").
-- The server owns the state (player attribute AfkPlow + AfkField / AfkLane for the client's route). It turns on only while the player
-- sits in their own plow on an unlocked snow field, outside the garage, the arena, the tutorial and Help jobs, and turns off as soon
-- as any of that stops being true or the client reports input. Payouts while on: SnowFieldService pays PlowConfig.Afk.Rate x the
-- blade's normal Snow (no drift, no dig combo). Nothing runs offline and nothing here touches Roblox's idle disconnect.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local PlowConfig = require(RS:WaitForChild("PlowConfig"))
local SF = require(RS:WaitForChild("SnowFields"))
local PlowRegistry = require(script.Parent:WaitForChild("PlowRegistry"))
local ContractRegistry = require(script.Parent:WaitForChild("ContractRegistry"))
local A = PlowConfig.Afk

local remote = RS:FindFirstChild("AfkRemote") or Instance.new("RemoteEvent")
remote.Name = "AfkRemote"; remote.Parent = RS

local last = {}
local function seatedPlow(player)
	local v = PlowRegistry.Active[player]
	if not v or not v.hull or not v.hull.Parent or not v.seat then return nil end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or hum.SeatPart ~= v.seat then return nil end
	return v
end
local function inJob(player)
	local f = ContractRegistry.Fields[player]
	return f ~= nil and next(f) ~= nil
end
-- the unlocked World field under the hull (margin = how far outside the field still counts while already on)
local function fieldAt(player, pos, margin)
	for _, f in ipairs(SF.Fields) do
		if not f.Style or f.Style == "Starter" or player:GetAttribute("Stage_" .. f.Style) == true then
			local o = SF.Origin(f)
			local lx, lz = pos.X - o.X, pos.Z - o.Z
			local w, d = f.Width * SF.TileSize, f.Depth * SF.TileSize
			if lx > -margin and lz > -margin and lx < w + margin and lz < d + margin and math.abs(pos.Y - o.Y) < 14 then return f end
		end
	end
	return nil
end
-- why AFK can't run right now (nil = it can)
local function blocker(player, margin)
	if player:GetAttribute("IntroActive") == true or player:GetAttribute("PlowTutorialDone") ~= true then return "Finish the tutorial first." end
	if player:GetAttribute("InGarage") == true then return "AFK doesn't work in the garage." end
	if player:GetAttribute("InArenaIsland") == true then return "AFK doesn't work in the arena." end
	if inJob(player) then return "AFK doesn't work during a Help job." end
	local v = seatedPlow(player)
	if not v then return "Get in your plow first." end
	if not (v.stats and v.stats.HasBlade) then return "Your plow needs a blade." end
	local f = fieldAt(player, v.hull.Position, margin)
	if not f then return "Drive onto a snow field first." end
	return nil, f, v
end
local function setOff(player, why)
	if player:GetAttribute("AfkPlow") ~= true then return end
	player:SetAttribute("AfkPlow", nil); player:SetAttribute("AfkField", nil); player:SetAttribute("AfkLane", nil)
	if why then remote:FireClient(player, false, why) end
end

remote.OnServerEvent:Connect(function(player, want)
	if type(want) ~= "boolean" then return end
	local now = os.clock()
	if (last[player] or 0) > now - A.ToggleCooldown then return end
	last[player] = now
	if not want then setOff(player) return end
	if player:GetAttribute("AfkPlow") == true then return end
	local why, f, v = blocker(player, 0)
	if why then remote:FireClient(player, false, why) return end
	player:SetAttribute("AfkField", f.Id)
	player:SetAttribute("AfkLane", math.max(3, (v.stats.BladeWidth or 6) * A.LaneShare))
	player:SetAttribute("AfkPlow", true)
	remote:FireClient(player, true, "AFK auto-plow on: " .. math.floor(A.Rate * 100 + 0.5) .. "% Snow. Any input turns it off.")
end)

-- watchdog: AFK ends the moment its conditions break (seat, garage, arena, tutorial, Help job, leaving the field)
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("AfkPlow") == true then
				local why = blocker(p, A.FieldMargin)
				if why then setOff(p, "AFK off: " .. why) end
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
