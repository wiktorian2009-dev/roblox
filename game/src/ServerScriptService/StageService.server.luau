-- StageService: per-player stage unlocks (bought with snow, in order). Publishes Stage_<Id> attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local S = require(ReplicatedStorage:WaitForChild("StageConfig"))
local unlock = ReplicatedStorage:WaitForChild("UnlockStage")

local function isOpen(d, id)
	if id == "Starter" or d.Stages[id] == true then return true end
	-- Cost 0 stages (World 2's first stage) open together with the stage before them (2026-10-02)
	local s = S.ById[id]
	local prev = (s and s.Cost == 0) and S.Previous(id) or nil
	return prev ~= nil and isOpen(d, prev.Id)
end

local function publish(player)
	local d = DataService.Get(player)
	if not d then return end
	for _, s in ipairs(S.Order) do player:SetAttribute("Stage_" .. s.Id, isOpen(d, s.Id)) end
end

DataService.OnLoaded(function(player) publish(player) end)
ServerStorage:WaitForChild("AdminHooks"):WaitForChild("ReapplyStages").Event:Connect(publish)

local last = {}
unlock.OnServerInvoke = function(player, id)
	local d = DataService.Get(player)
	local s = type(id) == "string" and S.ById[id]
	if not d or not s then return false, "Unknown stage" end
	local now = os.clock()
	if last[player] and now - last[player] < 0.3 then return false, "Slow down" end
	last[player] = now
	if isOpen(d, id) then return false, "Already unlocked" end
	local prev = S.Previous(id)
	if prev and not isOpen(d, prev.Id) then return false, "Unlock " .. prev.Name .. " first" end
	if d.Snow < s.Cost then return false, "Not enough snow" end
	DataService.AddSnow(player, -s.Cost)
	d.Stages[id] = true
	publish(player)
	return true
end

--------------------------------------------------
-- WORLD TRAVEL (2026-10-02, Claude): Absolute Zero Portal (needs stage Portal) <-> World 2 arrival plaza.
-- Markers live in Workspace.WorldTravel: World1PortalTrigger, World1Arrival, World2ReturnTrigger, World2Arrival.
--------------------------------------------------
local Players = game:GetService("Players")
local travelFolder = workspace:FindFirstChild("WorldTravel")
local busy = {}
local function travel(player, arrival)
	if busy[player] or not arrival then return end
	local char = player.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	busy[player] = true
	pcall(function() player:RequestStreamAroundAsync(arrival.Position, 8) end)
	char:PivotTo(arrival.CFrame + Vector3.new(0, 3, 0))
	player:SetAttribute("World", arrival.Name == "World2Arrival" and 2 or 1)
	task.delay(1, function() busy[player] = nil end)
end
local function addPrompt(trigger, actionText, objectText, arrivalName, needStage)
	if not trigger then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TravelPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = trigger
	prompt.Triggered:Connect(function(player)
		if needStage and player:GetAttribute("Stage_" .. needStage) ~= true then return end
		travel(player, travelFolder:FindFirstChild(arrivalName))
	end)
end
if travelFolder then
	addPrompt(travelFolder:FindFirstChild("World1PortalTrigger"), "Enter", "World 2: Sakura Garden", "World2Arrival", "Portal")
	addPrompt(travelFolder:FindFirstChild("World2ReturnTrigger"), "Return", "World 1: Frostfall", "World1Arrival", nil)
	-- respawning while in World 2 puts you back on its plaza
	local function watch(p)
		p.CharacterAdded:Connect(function()
			if p:GetAttribute("World") == 2 then
				-- 2026-10-04 (Claude): only if World 2 is still unlocked (after a rebirth it isn't) - otherwise you stay in World 1
				if p:GetAttribute("Stage_Portal") ~= true then p:SetAttribute("World", 1) return end
				task.wait(0.3)
				busy[p] = nil
				travel(p, travelFolder:FindFirstChild("World2Arrival"))
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do watch(p) end
end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
