-- ActivityConfig (2026-10-02, Claude): timed events, daily rewards, quests and achievements.
-- Shared by ServerScriptService.ActivityService / BoostService (server) and StarterGui.RNGGui.ActivityClient.
-- Promo codes are NOT here (clients can read ReplicatedStorage); they live in ServerScriptService.ActivityService.
local A = {}

-- BOOSTS: personal timed boosts. Getting a boost you already have adds time (up to MaxBoostSeconds).
-- Personal boosts don't multiply each other (the best Snow and best Luck count), but they DO multiply with events.
-- Timers only run while the player is in the game.
A.MaxBoostSeconds = 3600
A.Boosts = {
	Snow2 = {Name = "2x Snow", Icon = "❄️", Snow = 2, Luck = 1, Color = Color3.fromRGB(110, 200, 255)},
	Luck2 = {Name = "2x Luck", Icon = "🍀", Snow = 1, Luck = 2, Color = Color3.fromRGB(90, 225, 120)},
	Super = {Name = "Super Boost", Icon = "⭐", Snow = 2, Luck = 2, Color = Color3.fromRGB(255, 200, 60)},
}
A.BoostOrder = {"Super", "Snow2", "Luck2"}

-- EVENTS: server-wide, one at a time, picked at random by Weight.
A.EventGap = {600, 900}        -- seconds between events
A.FirstEventDelay = {90, 180}  -- after a server starts
A.Events = {
	{Id = "Snowstorm", Name = "SNOWSTORM", Text = "2x Snow for everyone!", Icon = "🌨️", Snow = 2, Luck = 1, Duration = 180, Weight = 3, Color = Color3.fromRGB(110, 190, 255), Effect = "Snow"},
	{Id = "LuckyWind", Name = "LUCKY WIND", Text = "2x Luck for everyone!", Icon = "🍀", Snow = 1, Luck = 2, Duration = 180, Weight = 3, Color = Color3.fromRGB(80, 210, 110), Effect = "Sparkle"},
	{Id = "Aurora", Name = "AURORA NIGHT", Text = "2x Snow AND 2x Luck!", Icon = "🌌", Snow = 2, Luck = 2, Duration = 120, Weight = 1, Color = Color3.fromRGB(170, 110, 255), Effect = "Both"},
}

-- DAILY REWARDS: one claim per day (20 h cooldown), 7-day streak; missing 48 h restarts at day 1.
-- SnowMinutes = Snow worth that many minutes of the player's recent digging (so it fits every stage).
A.DailyCooldown = 20 * 3600
A.DailyStreakReset = 48 * 3600
A.Daily = {
	{Boost = "Snow2", Seconds = 600},
	{Boost = "Luck2", Seconds = 600},
	{SnowMinutes = 5},
	{Boost = "Snow2", Seconds = 1200},
	{Boost = "Luck2", Seconds = 1200},
	{SnowMinutes = 10},
	{Boost = "Super", Seconds = 1800},
}

-- QUESTS: QuestSlots at a time, each with one reward from QuestRewards (one of each per set).
-- When the whole set is claimed, the next set arrives after QuestRefresh seconds.
A.QuestSlots = 3
A.QuestRefresh = 30 * 60
A.Quests = {
	{Id = "Roll", Text = "Roll %s times", Stat = "Rolls", Amounts = {25, 40, 60}},
	{Id = "Dig", Text = "Dig %s snow", Stat = "SnowEarned", Minutes = {3, 4, 5}}, -- goal = minutes of recent digging
	{Id = "Hatch", Text = "Hatch %s pets", Stat = "Hatches", Amounts = {3, 5, 8}},
	{Id = "Treasure", Text = "Find %s buried treasures", Stat = "Treasures", Amounts = {1, 2, 3}},
}
A.QuestRewards = {
	{Boost = "Snow2", Seconds = 300},
	{Boost = "Luck2", Seconds = 300},
	{SnowMinutes = 2},
}

-- ACHIEVEMENTS: unlock automatically and give a PERMANENT bonus (Snow/Luck = +fraction, added together).
A.Achievements = {
	{Id = "Rolls1", Name = "First Spins", Text = "Roll 100 times", Stat = "Rolls", Goal = 100, Luck = 0.02},
	{Id = "Rolls2", Name = "Dice Fan", Text = "Roll 1,000 times", Stat = "Rolls", Goal = 1000, Luck = 0.03},
	{Id = "Rolls3", Name = "Dice Master", Text = "Roll 5,000 times", Stat = "Rolls", Goal = 5000, Luck = 0.05},
	{Id = "Snow1", Name = "Snow Collector", Text = "Dig 100K snow", Stat = "SnowEarned", Goal = 1e5, Snow = 0.02},
	{Id = "Snow2", Name = "Snow Hoarder", Text = "Dig 1B snow", Stat = "SnowEarned", Goal = 1e9, Snow = 0.03},
	{Id = "Snow3", Name = "Avalanche Maker", Text = "Dig 1T snow", Stat = "SnowEarned", Goal = 1e12, Snow = 0.05},
	{Id = "Hatch1", Name = "Pet Friend", Text = "Hatch 10 pets", Stat = "Hatches", Goal = 10, Snow = 0.02},
	{Id = "Hatch2", Name = "Pet Keeper", Text = "Hatch 100 pets", Stat = "Hatches", Goal = 100, Snow = 0.03},
	{Id = "Treasure1", Name = "Lucky Digger", Text = "Find 10 treasures", Stat = "Treasures", Goal = 10, Snow = 0.02},
	{Id = "Treasure2", Name = "Treasure Hunter", Text = "Find 100 treasures", Stat = "Treasures", Goal = 100, Snow = 0.03},
	{Id = "Shovels1", Name = "Shovel Spotter", Text = "Discover 10 shovels", Stat = "ShovelsFound", Goal = 10, Luck = 0.02},
	{Id = "Shovels2", Name = "Shovel Expert", Text = "Discover 20 shovels", Stat = "ShovelsFound", Goal = 20, Luck = 0.03},
	{Id = "Pets1", Name = "Pet Spotter", Text = "Discover 10 pets", Stat = "PetsFound", Goal = 10, Snow = 0.02},
	{Id = "Pets2", Name = "Pet Expert", Text = "Discover 25 pets", Stat = "PetsFound", Goal = 25, Snow = 0.03},
	{Id = "Rebirth1", Name = "Fresh Start", Text = "Rebirth once", Stat = "Rebirths", Goal = 1, Snow = 0.02},
	{Id = "Rebirth2", Name = "Reborn", Text = "Rebirth 5 times", Stat = "Rebirths", Goal = 5, Snow = 0.03},
	{Id = "World2", Name = "World Traveler", Text = "Reach World 2", Stat = "World2", Goal = 1, Snow = 0.05, Luck = 0.05},
	{Id = "Quests1", Name = "Helper", Text = "Complete 10 quests", Stat = "QuestsDone", Goal = 10, Luck = 0.02},
	{Id = "Quests2", Name = "Hero of Frostfall", Text = "Complete 50 quests", Stat = "QuestsDone", Goal = 50, Luck = 0.03},
}

-- lookups
A.AchievementById, A.EventById, A.QuestById = {}, {}, {}
for i, a in ipairs(A.Achievements) do a.Order = i; A.AchievementById[a.Id] = a end
for _, e in ipairs(A.Events) do A.EventById[e.Id] = e end
for _, q in ipairs(A.Quests) do A.QuestById[q.Id] = q end

-- "❄️ 2x Snow for 5 min" (SnowMinutes rewards are turned into an amount by the server)
function A.RewardText(r)
	if r.Boost then
		local b = A.Boosts[r.Boost]
		return string.format("%s %s for %d min", b.Icon, b.Name, math.floor(r.Seconds / 60 + 0.5))
	elseif r.SnowMinutes then
		return string.format("❄️ %d min of Snow", r.SnowMinutes)
	end
	return "?"
end

-- "+2% Snow  +5% Luck"
function A.BonusText(a)
	local t = {}
	if a.Snow then table.insert(t, string.format("+%d%% Snow", math.floor(a.Snow * 100 + 0.5))) end
	if a.Luck then table.insert(t, string.format("+%d%% Luck", math.floor(a.Luck * 100 + 0.5))) end
	return table.concat(t, "  ")
end

return A
