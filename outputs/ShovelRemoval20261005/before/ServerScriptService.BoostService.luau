-- BoostService (2026-10-02, Claude): extra Snow/Luck multipliers from server events, personal timed boosts
-- (daily rewards, quests, codes) and permanent achievement bonuses.
-- UpgradeService.apply() multiplies SnowMult/LuckMult by B.Multipliers(player), so everything that already reads
-- those attributes (digging, treasures, rolling, the luck HUD) picks the boosts up automatically.
-- Profile field: d.Activity (sanitized here). Timed boosts only count down while the player is in the game.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local A = require(RS:WaitForChild("ActivityConfig"))

local B = {}
local event = {Snow = 1, Luck = 1}

function B.Sanitize(d)
	if type(d) ~= "table" then return nil end
	local a = type(d.Activity) == "table" and d.Activity or {}
	a.Boosts = type(a.Boosts) == "table" and a.Boosts or {}
	for kind, sec in pairs(a.Boosts) do
		if not A.Boosts[kind] or type(sec) ~= "number" or sec ~= sec or sec <= 0 then
			a.Boosts[kind] = nil
		else
			a.Boosts[kind] = math.min(sec, A.MaxBoostSeconds)
		end
	end
	a.Achievements = type(a.Achievements) == "table" and a.Achievements or {}
	a.Codes = type(a.Codes) == "table" and a.Codes or {}
	a.Quests = type(a.Quests) == "table" and a.Quests or {}
	a.Daily = type(a.Daily) == "table" and a.Daily or {}
	a.Daily.Day = tonumber(a.Daily.Day) or 0
	a.Daily.Last = tonumber(a.Daily.Last) or 0
	a.NextQuests = tonumber(a.NextQuests) or 0
	a.QuestsDone = tonumber(a.QuestsDone) or 0
	a.World2 = a.World2 == true
	a.Rate = tonumber(a.Rate) or 0
	if a.Rate ~= a.Rate or a.Rate < 0 or a.Rate == math.huge then a.Rate = 0 end
	d.Activity = a
	return a
end

-- always the live profile (OnLoaded hands later joiners a copy, so never keep that one)
function B.Profile(player)
	local d = DataService.Get(player)
	if d and type(d.Activity) ~= "table" then B.Sanitize(d) end
	return d, d and d.Activity
end

function B.Permanent(a)
	local s, l = 0, 0
	for id, have in pairs(a.Achievements) do
		local ach = have and A.AchievementById[id]
		if ach then s += ach.Snow or 0; l += ach.Luck or 0 end
	end
	return s, l
end

function B.Personal(a)
	local s, l = 1, 1
	for kind, sec in pairs(a.Boosts) do
		local k = A.Boosts[kind]
		if k and sec > 0 then s = math.max(s, k.Snow); l = math.max(l, k.Luck) end
	end
	return s, l
end

function B.Multipliers(player)
	local snow, luck = event.Snow, event.Luck
	local _, a = B.Profile(player)
	if a then
		local ps, pl = B.Personal(a)
		local qs, ql = B.Permanent(a)
		snow *= ps * (1 + qs)
		luck *= pl * (1 + ql)
	end
	return snow, luck
end

local function publish(player, a)
	local now = workspace:GetServerTimeNow()
	for kind in pairs(A.Boosts) do
		local sec = a and a.Boosts[kind]
		player:SetAttribute("BoostEnds_" .. kind, (sec and sec > 0) and (now + sec) or nil)
	end
	local s, l = 0, 0
	if a then s, l = B.Permanent(a) end
	player:SetAttribute("AchSnowBonus", s)
	player:SetAttribute("AchLuckBonus", l)
end

-- recompute this player's stats (UpgradeService listens to AdminHooks.ReapplyUpgrades)
function B.Refresh(player)
	local _, a = B.Profile(player)
	publish(player, a)
	local hooks = SS:FindFirstChild("AdminHooks")
	local ev = hooks and hooks:FindFirstChild("ReapplyUpgrades")
	if ev then ev:Fire(player) end
end

function B.Add(player, kind, seconds)
	local _, a = B.Profile(player)
	if not a or not A.Boosts[kind] or type(seconds) ~= "number" or seconds <= 0 then return false end
	a.Boosts[kind] = math.min(A.MaxBoostSeconds, (a.Boosts[kind] or 0) + seconds)
	B.Refresh(player)
	return true
end

function B.SetEvent(snow, luck)
	event.Snow, event.Luck = snow or 1, luck or 1
	for _, p in ipairs(Players:GetPlayers()) do
		if DataService.Get(p) then B.Refresh(p) end
	end
end

function B.EventMultipliers() return event.Snow, event.Luck end

-- countdown (only while in the game)
task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(1)
		local now = os.clock()
		local dt = now - last
		last = now
		for _, p in ipairs(Players:GetPlayers()) do
			local d = DataService.Get(p)
			local a = d and d.Activity
			if type(a) == "table" and type(a.Boosts) == "table" and next(a.Boosts) then
				local expired = false
				for kind, sec in pairs(a.Boosts) do
					sec -= dt
					if sec <= 0 then a.Boosts[kind] = nil; expired = true else a.Boosts[kind] = sec end
				end
				if expired then B.Refresh(p) end
			end
		end
	end
end)

DataService.OnLoaded(function(player)
	local d = DataService.Get(player)
	if d then B.Sanitize(d); B.Refresh(player) end
end)

return B
