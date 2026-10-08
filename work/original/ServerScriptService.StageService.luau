-- StageService: per-player stage unlocks (bought with snow, in order). Publishes Stage_<Id> attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local S = require(ReplicatedStorage:WaitForChild("StageConfig"))
local unlock = ReplicatedStorage:WaitForChild("UnlockStage")

local function isOpen(d, id) return id == "Starter" or d.Stages[id] == true end

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

