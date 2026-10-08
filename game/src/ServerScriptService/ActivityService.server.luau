-- ActivityService (2026-10-02, Claude): server-wide events, daily rewards, quests, achievements and promo codes.
-- Rewards are personal timed boosts (BoostService) or Snow worth N minutes of the player's recent digging,
-- so they stay useful at every stage. Every check happens here; the client only asks (ActivityRemote).
-- Profile: d.Activity (see BoostService.Sanitize). Lifetime snow: d.SnowEarned (counted in DataService.AddSnow).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local DataService = require(script.Parent:WaitForChild("DataService"))
local Boosts = require(script.Parent:WaitForChild("BoostService"))
local A = require(RS:WaitForChild("ActivityConfig"))
local PlowConfig = require(RS:WaitForChild("PlowConfig"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))

-- PROMO CODES (server only, players can't read this). Add codes here: CODE = reward, same format as ActivityConfig.Daily.
-- Each player can use each code once. Players may type them in any letter case.
local CODES = {
	FROSTFALL = {Boost = "Snow2", Seconds = 900},
	LUCKY = {Boost = "Luck2", Seconds = 900},
	SNOWDAY = {SnowMinutes = 5},
}

local function remote(class, name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = RS end
	return r
end
local fn = remote("RemoteFunction", "ActivityRemote")
local push = remote("RemoteEvent", "ActivityPush")

local rng = Random.new()
local track = {}    -- [player] = {earned = last SnowEarned seen, reward = reward snow to leave out of the speed}
local lastCall = {}

local function nice(x)
	x = math.max(1, x)
	if x < 100 then return math.floor(x + 0.5) end
	local e = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / e + 0.5) * e
end

-- every stat quests/achievements use, straight from the saved profile (none of them reset on rebirth)
local function stats(d)
	local a = d.Activity
	local plow = type(d.Plow) == "table" and d.Plow or {}
	local plowRolls = math.max(0, tonumber(plow.Rolls) or 0)
	-- Existing Roll quests recorded starts against TotalRolls alone. Shift their starts once
	-- by the current plow count so the switch to combined lifetime rolls preserves progress.
	if (tonumber(a.PlowStatsVersion) or 0) < 1 then
		for _, q in ipairs(a.Quests or {}) do
			if q.Id == "Roll" then q.Start = (tonumber(q.Start) or 0) + plowRolls end
		end
		a.PlowStatsVersion = 1
	end
	local hatches = 0
	for _, n in pairs(d.Pets or {}) do hatches += tonumber(n) or 0 end
	local parts = 0
	for id, n in pairs(plow.Parts or {}) do
		if PlowConfig.Parts[id] and (tonumber(n) or 0) > 0 then parts += 1 end
	end
	local pets = 0
	local PC = require(RS:WaitForChild("PetConfig"))
	for name, v in pairs(d.PetIndex or {}) do
		local p = PC.PetByName[name]
		if v and not (p and p.Paid) then pets += 1 end -- 2026-10-06: paid (Verity Egg) pets don't count towards pet achievements
	end
	return {
		Rolls = (tonumber(d.TotalRolls) or 0) + plowRolls,
		SnowEarned = tonumber(d.SnowEarned) or 0,
		Hatches = hatches,
		Treasures = tonumber(d.TreasureFound) or 0,
		PartsOwned = parts,
		PetsFound = pets,
		Rebirths = tonumber(d.Rebirths) or 0,
		World2 = a.World2 and 1 or 0,
		QuestsDone = a.QuestsDone,
	}
end

local function snowFor(a, minutes) return nice(math.max(100, (a.Rate or 0) * 60 * minutes)) end

local function rewardText(a, r)
	if r.SnowMinutes then return "❄️ " .. NumberFormat.Abbreviate(snowFor(a, r.SnowMinutes)) .. " Snow" end
	return A.RewardText(r)
end

local function grant(player, d, r)
	if r.Boost then
		Boosts.Add(player, r.Boost, r.Seconds)
		return A.RewardText(r)
	elseif r.SnowMinutes then
		local amount = snowFor(d.Activity, r.SnowMinutes)
		local t = track[player]
		if t then t.reward += amount end
		DataService.AddSnow(player, amount)
		return "❄️ +" .. NumberFormat.Abbreviate(amount) .. " Snow"
	end
	return ""
end

--------------------------------------------------
-- DAILY
--------------------------------------------------
-- returns canClaim, nextDay, nextClaimTime, claimedThrough (for the 7 tiles)
local function daily(a)
	local now = os.time()
	local last = a.Daily.Last
	local lost = last > 0 and now - last > A.DailyStreakReset
	local can = last == 0 or now - last >= A.DailyCooldown
	local nextDay = (lost or a.Daily.Day >= #A.Daily) and 1 or a.Daily.Day + 1
	local through = (lost or (can and nextDay == 1)) and 0 or a.Daily.Day
	return can, nextDay, last + A.DailyCooldown, through
end

--------------------------------------------------
-- QUESTS
--------------------------------------------------
local function shuffled(list)
	local t = table.clone(list)
	for i = #t, 2, -1 do
		local j = rng:NextInteger(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function newQuests(d)
	local a = d.Activity
	local st = stats(d)
	local defs = shuffled(A.Quests)
	local order = {}
	for i = 1, #A.QuestRewards do order[i] = i end
	order = shuffled(order)
	local list = {}
	for i = 1, math.min(A.QuestSlots, #defs) do
		local q = defs[i]
		local goal
		if q.Minutes then
			goal = nice(math.max(150, a.Rate * 60 * q.Minutes[rng:NextInteger(1, #q.Minutes)]))
		else
			goal = q.Amounts[rng:NextInteger(1, #q.Amounts)]
		end
		table.insert(list, {Id = q.Id, Goal = goal, Start = st[q.Stat] or 0, Reward = order[((i - 1) % #order) + 1], Claimed = false, Done = false})
	end
	a.Quests = list
	a.NextQuests = 0
end

local function questProgress(q, st)
	local def = A.QuestById[q.Id]
	if not def then return 0, def end
	return math.clamp((st[def.Stat] or 0) - (tonumber(q.Start) or 0), 0, q.Goal), def
end

--------------------------------------------------
-- STATE FOR THE CLIENT
--------------------------------------------------
local function snapshot(d)
	local a = d.Activity
	local st = stats(d)
	local can, nextDay, nextAt, through = daily(a)
	local dailyList = {}
	for i, r in ipairs(A.Daily) do dailyList[i] = rewardText(a, r) end
	local quests = {}
	for _, q in ipairs(a.Quests) do
		local prog, def = questProgress(q, st)
		if def then
			table.insert(quests, {Text = string.format(def.Text, NumberFormat.Abbreviate(q.Goal)), Progress = prog, Goal = q.Goal,
				Claimed = q.Claimed == true, Reward = rewardText(a, A.QuestRewards[q.Reward] or A.QuestRewards[1])})
		end
	end
	local ach = {}
	for i, x in ipairs(A.Achievements) do
		ach[i] = {Id = x.Id, Have = a.Achievements[x.Id] == true, Progress = math.min(st[x.Stat] or 0, x.Goal)}
	end
	return {Now = os.time(), Daily = {CanClaim = can, NextDay = nextDay, NextAt = nextAt, Through = through, Rewards = dailyList},
		Quests = quests, NextQuests = a.NextQuests, Achievements = ach}
end

--------------------------------------------------
-- TICK: speed, quests, achievements, red dot
--------------------------------------------------
local function tick(player, dt)
	local d, a = Boosts.Profile(player)
	if not a then return end
	local t = track[player]
	if not t then t = {earned = tonumber(d.SnowEarned) or 0, reward = 0}; track[player] = t end
	if player:GetAttribute("World") == 2 or (type(d.Stages) == "table" and d.Stages.Portal == true) then a.World2 = true end
	local st = stats(d)

	-- recent digging speed (snow per second, ~5 minute average), without reward snow
	local gained = math.max(0, st.SnowEarned - t.earned - t.reward)
	t.earned, t.reward = st.SnowEarned, 0
	a.Rate += (gained / dt - a.Rate) * math.min(1, dt / 300)

	-- quests: first set at once, later sets after the refresh wait
	local allClaimed = #a.Quests > 0
	for _, q in ipairs(a.Quests) do if not q.Claimed then allClaimed = false end end
	if #a.Quests == 0 then
		newQuests(d)
	elseif allClaimed and os.time() >= a.NextQuests then
		newQuests(d)
		push:FireClient(player, {Type = "NewQuests"})
	end
	local claimable = false
	for _, q in ipairs(a.Quests) do
		local prog, def = questProgress(q, st)
		if def and not q.Claimed and prog >= q.Goal then
			claimable = true
			if not q.Done then
				q.Done = true
				push:FireClient(player, {Type = "QuestDone", Text = string.format(def.Text, NumberFormat.Abbreviate(q.Goal))})
			end
		end
	end

	-- achievements (permanent bonuses)
	local unlocked = false
	for _, x in ipairs(A.Achievements) do
		if not a.Achievements[x.Id] and (st[x.Stat] or 0) >= x.Goal then
			a.Achievements[x.Id] = true
			unlocked = true
			push:FireClient(player, {Type = "Achievement", Id = x.Id})
		end
	end
	if unlocked then Boosts.Refresh(player) end

	if daily(a) then claimable = true end
	if player:GetAttribute("ActivityClaimable") ~= claimable then player:SetAttribute("ActivityClaimable", claimable) end
end

DataService.OnLoaded(function(player)
	local d = DataService.Get(player)
	if not d then return end
	Boosts.Sanitize(d)
	stats(d) -- migrate saved quest starts immediately, before the first new garage roll
	track[player] = {earned = tonumber(d.SnowEarned) or 0, reward = 0}
end)
Players.PlayerRemoving:Connect(function(p) track[p] = nil; lastCall[p] = nil end)

task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(1)
		local now = os.clock()
		local dt = math.max(0.5, now - last)
		last = now
		for _, p in ipairs(Players:GetPlayers()) do
			if DataService.Get(p) then
				local ok, err = pcall(tick, p, dt)
				if not ok then warn("[ActivityService] " .. tostring(err)) end
			end
		end
	end
end)

--------------------------------------------------
-- REMOTE
--------------------------------------------------
fn.OnServerInvoke = function(player, action, arg)
	local d, a = Boosts.Profile(player)
	if not d or not a then return nil end
	if action == "Get" then return snapshot(d) end
	local now = os.clock()
	if lastCall[player] and now - lastCall[player] < 0.4 then return {Ok = false, Msg = "Slow down!"} end
	lastCall[player] = now

	if action == "ClaimDaily" then
		local can, day = daily(a)
		if not can then return {Ok = false, Msg = "Come back later for your next reward!"} end
		a.Daily.Day = day
		a.Daily.Last = os.time()
		local text = grant(player, d, A.Daily[day])
		return {Ok = true, Msg = "Day " .. day .. ": " .. text, State = snapshot(d)}

	elseif action == "ClaimQuest" then
		local q = a.Quests[tonumber(arg) or 0]
		if not q or q.Claimed then return {Ok = false, Msg = "That quest is not available."} end
		local prog = questProgress(q, stats(d))
		if prog < q.Goal then return {Ok = false, Msg = "Finish the quest first!"} end
		q.Claimed = true
		a.QuestsDone += 1
		local text = grant(player, d, A.QuestRewards[q.Reward] or A.QuestRewards[1])
		local all = true
		for _, x in ipairs(a.Quests) do if not x.Claimed then all = false end end
		if all then a.NextQuests = os.time() + A.QuestRefresh end
		return {Ok = true, Msg = "Quest reward: " .. text, State = snapshot(d)}

	elseif action == "Redeem" then
		local code = type(arg) == "string" and arg or ""
		code = string.upper(string.gsub(code, "%s", "")):sub(1, 30)
		local r = CODES[code]
		if not r then return {Ok = false, Msg = "That code doesn't exist."} end
		if a.Codes[code] then return {Ok = false, Msg = "You already used this code."} end
		a.Codes[code] = true
		local text = grant(player, d, r)
		return {Ok = true, Msg = "Code redeemed! " .. text, State = snapshot(d)}
	end
	return nil
end

--------------------------------------------------
-- SERVER EVENTS
--------------------------------------------------
local current, token = nil, 0
local function endEvent()
	current = nil
	RS:SetAttribute("EventId", nil)
	RS:SetAttribute("EventEnds", nil)
	Boosts.SetEvent(1, 1)
	push:FireAllClients({Type = "EventEnd"})
end
local function runEvent(e, duration)
	token += 1
	local mine = token
	duration = duration or e.Duration
	current = e
	RS:SetAttribute("EventId", e.Id)
	RS:SetAttribute("EventEnds", workspace:GetServerTimeNow() + duration)
	Boosts.SetEvent(e.Snow, e.Luck)
	push:FireAllClients({Type = "EventStart", Id = e.Id})
	task.delay(duration, function() if token == mine then endEvent() end end)
end
local function pickEvent()
	local total = 0
	for _, e in ipairs(A.Events) do total += e.Weight end
	local r = rng:NextNumber() * total
	for _, e in ipairs(A.Events) do
		r -= e.Weight
		if r <= 0 then return e end
	end
	return A.Events[1]
end
task.spawn(function()
	task.wait(rng:NextNumber(A.FirstEventDelay[1], A.FirstEventDelay[2]))
	while true do
		if not current then
			local e = pickEvent()
			runEvent(e)
			task.wait(e.Duration)
		end
		task.wait(rng:NextNumber(A.EventGap[1], A.EventGap[2]))
	end
end)

--------------------------------------------------
-- STUDIO TEST HOOK (isolated BalanceTestMode sessions only)
--------------------------------------------------
if RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true then
	local hook = Instance.new("BindableFunction")
	hook.Name = "ActivityTestHook"
	hook.OnInvoke = function(action, player, x, y)
		if action == "Event" then
			local e = A.EventById[x]
			if e then runEvent(e, y or 20); return true end
		elseif action == "EndEvent" then
			token += 1; endEvent(); return true
		end
		local d, a
		if player then d, a = Boosts.Profile(player) end
		if not a then return nil end
		if action == "Snapshot" then
			return snapshot(d)
		elseif action == "FinishQuests" then
			local st = stats(d)
			for _, q in ipairs(a.Quests) do
				local def = A.QuestById[q.Id]
				if def then q.Start = (st[def.Stat] or 0) - q.Goal end
			end
			return true
		elseif action == "Raw" then
			return {Boosts = table.clone(a.Boosts), Achievements = table.clone(a.Achievements), QuestsDone = a.QuestsDone,
				Rate = a.Rate, NextQuests = a.NextQuests, SnowEarned = d.SnowEarned, Snow = d.Snow}
		end
		return nil
	end
	hook.Parent = SS
end
