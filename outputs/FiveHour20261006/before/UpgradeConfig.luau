-- 2026-10-02 balance pass v2 (Claude): fast start, slower late game. With events/quests/daily/achievements World 1 takes ~4 h for an efficient engaged player, ~5 h casual (model). Older copies: ServerStorage.BalanceBackups
-- Progression v2: 105 upgrades. IDs are preserved so existing purchases remain owned.
-- Snowplow upgrades keep existing purchase IDs, positions, prices and artwork.
-- LuckMult boosts part offers; RollCooldownMult shortens the pedestal cooldown.
-- Blade width is capped for safe clearing; excess width increases clearing power instead.
-- Cost and RequiredStage describe progression; Q/R only describe the visual layout.
-- Add Icon = "rbxassetid://..." to any node when its artwork is ready.
local U = {}
U.Trees = {
	{Id = "Snow", Name = "SNOW", Color = Color3.fromRGB(110, 200, 255), BaseCost = 50, Growth = 7, Nodes = {
		{Id = "S_Center", Name = "Snow Start", Q = 0, R = 0, Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow", Center = true, Icon = "rbxassetid://123475556201859"},
		{Id = "S_Gain1", Name = "Snow Gain", Q = 1, R = 0, Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow", Icon = "rbxassetid://105040215830765"},
		{Id = "S_Gain2", Name = "More Snow", Q = 2, R = 0, Effect = {"SnowMult", 0.15, "Mul"}, Text = "x1.15 snow", Icon = "rbxassetid://103725419453858"},
		{Id = "S_Gain3", Name = "Snow Pile", Q = 3, R = 0, Effect = {"SnowMult", 0.25, "Mul"}, Text = "x1.25 snow", Icon = "rbxassetid://124996955608433"},
		{Id = "S_Deep", Name = "Deep Snow", Q = 4, R = 0, Effect = {"SnowMult", 0.25, "Mul"}, Text = "x1.25 snow", Icon = "rbxassetid://131672223099434"},
		{Id = "S_Storm", Name = "Snowstorm", Q = 4, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", Icon = "rbxassetid://79915799667169"},
		{Id = "S_Blizzard", Name = "Blizzard", Q = 5, R = -1, Effect = {"SnowMult", 1, "Mul"}, Text = "x2 snow", CostMult = 4, Icon = "rbxassetid://133647988298430"},
		{Id = "S_Fresh", Name = "Fresh Powder", Q = 0, R = 1, Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow", Icon = "rbxassetid://123365452410146"},
		{Id = "S_Rush", Name = "Powder Rush", Q = 1, R = 1, Effect = {"SnowMult", 0.25, "Mul"}, Text = "x1.25 snow", Icon = "rbxassetid://86159020766166"},
		{Id = "S_Sharp", Name = "Sharp Edges", Q = 0, R = -1, Effect = {"PowerMult", 0.25, "Mul"}, Text = "x1.25 clearing power", Icon = "rbxassetid://88396818256494"},
		{Id = "S_Heavy", Name = "Heavy Hits", Q = 0, R = -2, Effect = {"PowerMult", 0.25, "Mul"}, Text = "x1.25 clearing power", Icon = "rbxassetid://126452827773697"},
		{Id = "S_Swing", Name = "Power Sweep", Q = -1, R = -2, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", Icon = "rbxassetid://130505359203868"},
		{Id = "S_Crush", Name = "Crushing Blow", Q = 1, R = -3, Effect = {"PowerMult", 1, "Mul"}, Text = "x2 clearing power", CostMult = 3, Icon = "rbxassetid://95515443709296"},
		{Id = "S_Quick", Name = "Quick Clearing", Q = 0, R = 2, Effect = {"SpinMult", 0.15}, Text = "+15% clearing speed", Icon = "rbxassetid://113767999233566"},
		{Id = "S_Turbo", Name = "Turbo Clearing", Q = 0, R = 3, Effect = {"SpinMult", 0.15}, Text = "+15% clearing speed", Icon = "rbxassetid://99774561784389"},
		{Id = "S_Third", Name = "Snow Crew", Q = -1, R = 3, Effect = {"SnowMult", 0.15, "Mul"}, Text = "x1.15 snow", CostMult = 20, Icon = "rbxassetid://113684057278608"},
		{Id = "S_Size1", Name = "Wider Blade I", Q = -1, R = 1, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://127232371950782"},
		{Id = "S_Size2", Name = "Wider Blade II", Q = -1, R = 2, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://104727447841125"},
		{Id = "S_Size3", Name = "Wider Blade III", Q = -2, R = 2, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://131456238471965"},
		{Id = "S_Size4", Name = "Wider Blade IV", Q = -2, R = 3, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://87556604641604"},
		{Id = "S_Size5", Name = "Wider Blade V", Q = -3, R = 3, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://94266678186706"},
		{Id = "S_Size6", Name = "Wider Blade VI", Q = -3, R = 4, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://77143044227391"},
		{Id = "S_Size7", Name = "Wider Blade VII", Q = -4, R = 4, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://120267984209832"},
		{Id = "S_Size8", Name = "Wider Blade VIII", Q = -4, R = 5, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://134088287054458"},
		{Id = "S_Size9", Name = "Wider Blade IX", Q = -5, R = 5, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://128880797000767"},
		{Id = "S_Size10", Name = "Wider Blade X", Q = -5, R = 6, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", Icon = "rbxassetid://109631617606961", CostMult = 3},
		{Id = "S_Avalanche", Name = "Avalanche", Q = 6, R = -1, Effect = {"SnowMult", 1, "Mul"}, Text = "x2 snow", RequiredStage = "AbsoluteZero", Cost = 2200000000000, Icon = "rbxassetid://133647988298430"},
		{Id = "S_Glacier", Name = "Glacier Heart", Q = 7, R = -1, Effect = {"SnowMult", 1.5, "Mul"}, Text = "x2.5 snow", RequiredStage = "Portal", Cost = 250000000000000, Icon = "rbxassetid://79915799667169"},
		{Id = "S_FrostCore", Name = "Frost Core", Q = 8, R = -1, Effect = {"SnowMult", 2, "Mul"}, Text = "x3 snow", RequiredStage = "Portal", Cost = 620000000000000, Icon = "rbxassetid://131672223099434"},
		-- 2026-10-05 (Claude, snowplow expansion): World 2 prices below follow the re-measured stage costs (same ratio to their stage); World 1 prices
		-- follow the curve at the bottom, which reads StageConfig. Effects, IDs, positions and art unchanged; no stage locks.
		-- WORLD 2 (2026-10-03, Claude): per stage x1.5 snow / x1.5 damage / luck / +6% size; cost = 2.0 / 1.6 / 1.0 / 1.3 x that stage's price (Sakura: Portal). Progression model: work/world2-balance.
		{Id = "W2_BlossomBreeze", Name = "Blossom Breeze", Q = 9, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", RequiredStage = "Sakura", Cost = 220000000000, Icon = "rbxassetid://79915799667169"},
		{Id = "W2_SugarRush", Name = "Sugar Rush", Q = 10, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", RequiredStage = "Candy", Cost = 1700000000000, Icon = "rbxassetid://131672223099434"},
		{Id = "W2_TideSurge", Name = "Tide Surge", Q = 11, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", RequiredStage = "Atlantis", Cost = 5400000000000, Icon = "rbxassetid://79915799667169"},
		{Id = "W2_ToyChest", Name = "Toy Chest", Q = 12, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", RequiredStage = "Toybox", Cost = 13000000000000, Icon = "rbxassetid://79915799667169"},
		{Id = "W2_TickTockSnow", Name = "Tick-Tock Snow", Q = 13, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", RequiredStage = "Clockwork", Cost = 34000000000000, Icon = "rbxassetid://79915799667169"},
		{Id = "W2_CloudBurst", Name = "Cloud Burst", Q = 14, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", RequiredStage = "Cloud", Cost = 100000000000000, Icon = "rbxassetid://79915799667169"},
		{Id = "W2_StarBurst", Name = "Star Burst", Q = 15, R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow", RequiredStage = "Cosmic", Cost = 660000000000000, Icon = "rbxassetid://79915799667169"},
		{Id = "S_Titan", Name = "Titan Sweep", Q = 2, R = -4, Effect = {"PowerMult", 1, "Mul"}, Text = "x2 clearing power", RequiredStage = "AbsoluteZero", Cost = 1800000000000, Icon = "rbxassetid://95515443709296"},
		{Id = "S_Meteor", Name = "Meteor Strike", Q = 3, R = -5, Effect = {"PowerMult", 1.5, "Mul"}, Text = "x2.5 clearing power", RequiredStage = "Portal", Cost = 190000000000000, Icon = "rbxassetid://130505359203868"},
		{Id = "S_Glacial", Name = "Glacial Fury", Q = 4, R = -6, Effect = {"PowerMult", 2, "Mul"}, Text = "x3 clearing power", RequiredStage = "Portal", Cost = 500000000000000, Icon = "rbxassetid://126452827773697"},
		{Id = "W2_PetalStrike", Name = "Petal Strike", Q = 5, R = -6, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", RequiredStage = "Sakura", Cost = 180000000000, Icon = "rbxassetid://130505359203868"},
		{Id = "W2_CandyCrush", Name = "Candy Crush", Q = 6, R = -7, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", RequiredStage = "Candy", Cost = 1400000000000, Icon = "rbxassetid://126452827773697"},
		{Id = "W2_CoralCrusher", Name = "Coral Crusher", Q = 7, R = -8, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", RequiredStage = "Atlantis", Cost = 4300000000000, Icon = "rbxassetid://130505359203868"},
		{Id = "W2_BlockBuster", Name = "Block Buster", Q = 8, R = -9, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", RequiredStage = "Toybox", Cost = 11000000000000, Icon = "rbxassetid://130505359203868"},
		{Id = "W2_GearGrinder", Name = "Gear Grinder", Q = 9, R = -10, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", RequiredStage = "Clockwork", Cost = 27000000000000, Icon = "rbxassetid://130505359203868"},
		{Id = "W2_ThunderStrike", Name = "Thunder Strike", Q = 10, R = -11, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", RequiredStage = "Cloud", Cost = 81000000000000, Icon = "rbxassetid://130505359203868"},
		{Id = "W2_MeteorStrike", Name = "Meteor Strike", Q = 11, R = -12, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 clearing power", RequiredStage = "Cosmic", Cost = 530000000000000, Icon = "rbxassetid://130505359203868"},
	}},
	{Id = "Rolls", Name = "ROLLS", Color = Color3.fromRGB(255, 190, 60), BaseCost = 75, Growth = 4.5, Nodes = {
		{Id = "R_Luck1", Name = "Lucky Start", Q = 0, R = 0, Effect = {"LuckMult", 0.1}, Text = "+10% luck", Icon = "rbxassetid://74613534440214", Center = true},
		{Id = "R_Luck2", Name = "Four Leaf", Q = 1, R = 0, Effect = {"LuckMult", 0.1}, Text = "+10% luck", Icon = "rbxassetid://135947304140304"},
		{Id = "R_Luck3", Name = "Clover Bunch", Q = 1, R = -1, Effect = {"LuckMult", 0.1}, Text = "+10% luck", Icon = "rbxassetid://114594217802990"},
		{Id = "R_Luck4", Name = "Lucky Leaf", Q = 2, R = -1, Effect = {"LuckMult", 0.1}, Text = "+10% luck", Icon = "rbxassetid://82230156041586"},
		{Id = "R_Luck5", Name = "Clover Coin", Q = 2, R = 0, Effect = {"LuckMult", 0.1}, Text = "+10% luck", Icon = "rbxassetid://108405377877908"},
		{Id = "R_Luck6", Name = "Horseshoe", Q = 3, R = -1, Effect = {"LuckMult", 0.25}, Text = "+25% luck", Icon = "rbxassetid://130847433715579"},
		{Id = "R_Luck7", Name = "Golden Clover", Q = 3, R = -2, Effect = {"LuckMult", 0.25}, Text = "+25% luck", Icon = "rbxassetid://132120945342976"},
		{Id = "R_Luck8", Name = "Gold Luck", Q = 4, R = -2, Effect = {"LuckMult", 0.25}, Text = "+25% luck", Icon = "rbxassetid://92901021126921"},
		{Id = "R_Luck9", Name = "Lucky Charm", Q = 4, R = -1, Effect = {"LuckMult", 0.25}, Text = "+25% luck", Icon = "rbxassetid://126126306847172"},
		{Id = "R_Luck10", Name = "Shining Clover", Q = 5, R = -2, Effect = {"LuckMult", 0.25}, Text = "+25% luck", Icon = "rbxassetid://136971141646296"},
		{Id = "R_Luck11", Name = "Emerald Luck", Q = 5, R = -3, Effect = {"LuckMult", 0.5}, Text = "+50% luck", Icon = "rbxassetid://90693813824115"},
		{Id = "R_Luck12", Name = "Glowing Clover", Q = 6, R = -3, Effect = {"LuckMult", 0.5}, Text = "+50% luck", Icon = "rbxassetid://93889434381128"},
		{Id = "R_Luck13", Name = "Clover Treasure", Q = 6, R = -2, Effect = {"LuckMult", 0.5}, Text = "+50% luck", Icon = "rbxassetid://88867850851423"},
		{Id = "R_Luck14", Name = "Golden Horseshoe", Q = 7, R = -3, Effect = {"LuckMult", 0.5}, Text = "+50% luck", Icon = "rbxassetid://130100089903162"},
		{Id = "R_Luck15", Name = "Radiant Clover", Q = 7, R = -4, Effect = {"LuckMult", 0.5}, Text = "+50% luck", Icon = "rbxassetid://109104895950200"},
		{Id = "R_Luck16", Name = "Ruby Clover", Q = 8, R = -4, Effect = {"LuckMult", 1}, Text = "+100% luck", Icon = "rbxassetid://107650237435847"},
		{Id = "R_Luck17", Name = "Crimson Luck", Q = 8, R = -3, Effect = {"LuckMult", 1}, Text = "+100% luck", Icon = "rbxassetid://107165717932897"},
		{Id = "R_Luck18", Name = "Fortune Coin", Q = 9, R = -4, Effect = {"LuckMult", 1}, Text = "+100% luck", Icon = "rbxassetid://124687350359002"},
		{Id = "R_Luck19", Name = "Blazing Luck", Q = 9, R = -5, Effect = {"LuckMult", 1}, Text = "+100% luck", Icon = "rbxassetid://92923836695787"},
		{Id = "R_Luck20", Name = "Legendary Luck", Q = 10, R = -5, Effect = {"LuckMult", 3}, Text = "+300% luck", Icon = "rbxassetid://111610549461352", CostMult = 5},
		{Id = "R_Dice1", Name = "Quick Offers", Q = -1, R = 0, Effect = {"RollCooldownMult", -0.1}, Text = "-10% offer cooldown", Icon = "rbxassetid://102874154480737"},
		{Id = "R_Dice2", Name = "Quicker Offers", Q = -2, R = 0, Effect = {"RollCooldownMult", -0.1}, Text = "-10% offer cooldown", Icon = "rbxassetid://106145240377808"},
		{Id = "R_Dice3", Name = "Speedy Offers", Q = -3, R = 1, Effect = {"RollCooldownMult", -0.1}, Text = "-10% offer cooldown", Icon = "rbxassetid://75892482060074"},
		{Id = "R_Dice4", Name = "Snow Bonus", Q = -2, R = 1, Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow", Icon = "rbxassetid://136937260810509"},
		{Id = "R_Dice5", Name = "Better Snow Bonus", Q = -3, R = 2, Effect = {"SnowMult", 0.15, "Mul"}, Text = "x1.15 snow", Icon = "rbxassetid://93129986364028", CostMult = 4},
		{Id = "R_Triple", Name = "Snow Jackpot", Q = -1, R = 1, Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow", RequiredStage = "Jungle", Cost = 45000000000, Icon = "rbxassetid://93129986364028"},
		{Id = "R_Gold1", Name = "Golden Offers", Q = -4, R = 2, Effect = {"LuckMult", 0.15}, Text = "+15% luck", RequiredStage = "Jungle", Cost = 27000000000, Icon = "rbxassetid://82230206975104", IconTint = Color3.fromRGB(255, 205, 60)},
		{Id = "R_Gold2", Name = "Gilded Offers", Q = -5, R = 3, Effect = {"LuckMult", 0.2}, Text = "+20% luck", RequiredStage = "Jungle", Cost = 54000000000, Icon = "rbxassetid://82230206975104", IconTint = Color3.fromRGB(255, 205, 60)},
		{Id = "R_Gold3", Name = "Shining Offers", Q = -6, R = 4, Effect = {"LuckMult", 0.25}, Text = "+25% luck", RequiredStage = "Jungle", Cost = 110000000000, Icon = "rbxassetid://82230206975104", IconTint = Color3.fromRGB(255, 205, 60)},
		{Id = "R_Gold4", Name = "Golden Fortune", Q = -7, R = 5, Effect = {"LuckMult", 0.3}, Text = "+30% luck", RequiredStage = "AbsoluteZero", Cost = 880000000000, Icon = "rbxassetid://82230206975104", IconTint = Color3.fromRGB(255, 205, 60)},
		{Id = "R_Gold5", Name = "Gold Rush", Q = -8, R = 6, Effect = {"LuckMult", 0.4}, Text = "+40% luck", RequiredStage = "AbsoluteZero", Cost = 1800000000000, Icon = "rbxassetid://82230206975104", IconTint = Color3.fromRGB(255, 205, 60)},
		{Id = "R_Gold6", Name = "Midas Offers", Q = -9, R = 7, Effect = {"LuckMult", 0.5}, Text = "+50% luck", RequiredStage = "Portal", Cost = 75000000000000, Icon = "rbxassetid://82230206975104", IconTint = Color3.fromRGB(255, 205, 60)},
		{Id = "R_Rain1", Name = "Rainbow Offers", Q = -3, R = 3, Effect = {"LuckMult", 0.75}, Text = "+75% luck", RequiredStage = "AbsoluteZero", Cost = 1200000000000, Icon = "rbxassetid://82230206975104", IconRainbow = true},
		{Id = "R_Rain2", Name = "Prism Offers", Q = -3, R = 4, Effect = {"LuckMult", 1}, Text = "+100% luck", RequiredStage = "AbsoluteZero", Cost = 2200000000000, Icon = "rbxassetid://82230206975104", IconRainbow = true},
		{Id = "R_Rain3", Name = "Spectrum Offers", Q = -3, R = 5, Effect = {"LuckMult", 1.25}, Text = "+125% luck", RequiredStage = "AbsoluteZero", Cost = 4000000000000, Icon = "rbxassetid://82230206975104", IconRainbow = true},
		{Id = "R_Rain4", Name = "Aurora Offers", Q = -3, R = 6, Effect = {"LuckMult", 1.5}, Text = "+150% luck", RequiredStage = "Portal", Cost = 100000000000000, Icon = "rbxassetid://82230206975104", IconRainbow = true},
		{Id = "R_Rain5", Name = "Starlight Offers", Q = -3, R = 7, Effect = {"LuckMult", 2}, Text = "+200% luck", RequiredStage = "Portal", Cost = 190000000000000, Icon = "rbxassetid://82230206975104", IconRainbow = true},
		{Id = "R_Rain6", Name = "Cosmic Offers", Q = -3, R = 8, Effect = {"LuckMult", 2.5}, Text = "+250% luck", RequiredStage = "Portal", Cost = 380000000000000, Icon = "rbxassetid://82230206975104", IconRainbow = true},
		{Id = "R_Hyper", Name = "Rapid Offers", Q = -4, R = 1, Effect = {"RollCooldownMult", -0.1}, Text = "-10% offer cooldown", RequiredStage = "AbsoluteZero", Cost = 1000000000000, Icon = "rbxassetid://75892482060074"},
		{Id = "R_Luck21", Name = "Mythic Luck", Q = 11, R = -5, Effect = {"LuckMult", 5}, Text = "+500% luck", RequiredStage = "AbsoluteZero", Cost = 2000000000000, Icon = "rbxassetid://111610549461352"},
		{Id = "R_Luck22", Name = "Cosmic Luck", Q = 12, R = -6, Effect = {"LuckMult", 7.5}, Text = "+750% luck", RequiredStage = "Portal", Cost = 120000000000000, Icon = "rbxassetid://92923836695787"},
		{Id = "W2_KoiFortune", Name = "Koi Fortune", Q = 13, R = -6, Effect = {"LuckMult", 4}, Text = "+400% luck", RequiredStage = "Sakura", Cost = 110000000000, Icon = "rbxassetid://92923836695787"},
		{Id = "W2_LuckyLollipop", Name = "Lucky Lollipop", Q = 14, R = -7, Effect = {"LuckMult", 5}, Text = "+500% luck", RequiredStage = "Candy", Cost = 850000000000, Icon = "rbxassetid://111610549461352"},
		{Id = "W2_PearlLuck", Name = "Pearl Luck", Q = 15, R = -8, Effect = {"LuckMult", 6}, Text = "+600% luck", RequiredStage = "Atlantis", Cost = 2700000000000, Icon = "rbxassetid://92923836695787"},
		{Id = "W2_LuckyToyDice", Name = "Lucky Toy Dice", Q = 16, R = -9, Effect = {"LuckMult", 7}, Text = "+700% luck", RequiredStage = "Toybox", Cost = 6700000000000, Icon = "rbxassetid://92923836695787"},
		{Id = "W2_LuckyClockwork", Name = "Lucky Clockwork", Q = 17, R = -10, Effect = {"LuckMult", 8}, Text = "+800% luck", RequiredStage = "Clockwork", Cost = 17000000000000, Icon = "rbxassetid://92923836695787"},
		{Id = "W2_RainbowLuck", Name = "Rainbow Luck", Q = 18, R = -11, Effect = {"LuckMult", 9}, Text = "+900% luck", RequiredStage = "Cloud", Cost = 51000000000000, Icon = "rbxassetid://92923836695787"},
		{Id = "W2_CosmicLuck", Name = "Cosmic Luck", Q = 19, R = -12, Effect = {"LuckMult", 12}, Text = "+1200% luck", RequiredStage = "Cosmic", Cost = 330000000000000, Icon = "rbxassetid://92923836695787"},
	}},
	-- 2026-10-06 (Claude, "misc upgrades should be more sorted"): Misc re-laid by kind - one wedge each (walk speed, pet boosts,
	-- pet slots, friends, eggs, blade reach), cheapest next to Misc Start; positions only (outputs/MiscSort20261006/misc_sort.py)
	{Id = "Misc", Name = "MISC", Color = Color3.fromRGB(130, 225, 120), Nodes = {
		{Id = "M_Center", Name = "Misc Start", Q = 0, R = 0, PriceRing = 0, Text = "+1 walk speed", RequiredStage = "Starter", Cost = 38, Center = true, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://113047023211112"},
		{Id = "M_Walk1", Name = "Walk Speed", Q = 1, R = 0, PriceRing = 1, Text = "+2 walk speed", RequiredStage = "Starter", Cost = 143, Effect = {"WalkSpeed", 2}, Icon = "rbxassetid://114695132674308"},
		{Id = "M_Walk2", Name = "Fast Feet", Q = 2, R = -1, PriceRing = 2, Text = "+2 walk speed", RequiredStage = "Desert", Cost = 1000, Effect = {"WalkSpeed", 2}, Icon = "rbxassetid://113848289406776"},
		{Id = "M_Sprint", Name = "Sprinter", Q = 2, R = 0, PriceRing = 3, Text = "+3 walk speed", RequiredStage = "Cursed", Cost = 19000, Effect = {"WalkSpeed", 3}, Icon = "rbxassetid://132498630260521"},
		{Id = "M_Friend1", Name = "Friend Boost", Q = -1, R = 0, PriceRing = 1, Text = "+5% snow & luck per friend here", RequiredStage = "Starter", Cost = 98, Effect = {"FriendBoost", 0.05}, Icon = "rbxassetid://131355488400635"},
		{Id = "M_Friend2", Name = "Best Friends", Q = -2, R = 1, PriceRing = 2, Text = "+5% per friend here", RequiredStage = "Desert", Cost = 1000, Effect = {"FriendBoost", 0.05}, Icon = "rbxassetid://102947421379601"},
		{Id = "M_Squad", Name = "Squad Goals", Q = -2, R = 0, PriceRing = 3, Text = "+5% per friend here", RequiredStage = "Cursed", Cost = 19000, Effect = {"FriendBoost", 0.05}, Icon = "rbxassetid://126438571587621"},
		{Id = "M_Egg1", Name = "Egg Discount", Q = -1, R = 1, PriceRing = 1, Text = "-5% egg price", RequiredStage = "Starter", Cost = 120, Effect = {"EggDiscount", 0.05}, Icon = "rbxassetid://118146985927338"},
		{Id = "M_Egg2", Name = "Egg Deals", Q = -2, R = 2, PriceRing = 2, Text = "-5% egg price", RequiredStage = "Desert", Cost = 810, Effect = {"EggDiscount", 0.05}, Icon = "rbxassetid://88430606212732"},
		{Id = "M_Egg3", Name = "Egg Sale", Q = -1, R = 2, PriceRing = 2, Text = "-10% egg price", RequiredStage = "Desert", Cost = 620, Effect = {"EggDiscount", 0.1}, Icon = "rbxassetid://134519000870363"},
		{Id = "M_Egg4", Name = "Egg Bargain", Q = -3, R = 4, PriceRing = 3, Text = "-10% egg price", RequiredStage = "Cursed", Cost = 36000, Effect = {"EggDiscount", 0.1}, Icon = "rbxassetid://126600758916916"},
		{Id = "M_Pet1", Name = "Pet Care", Q = 0, R = -1, PriceRing = 1, Text = "+1 walk speed", RequiredStage = "Starter", Cost = 98, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://133360929439713"},
		{Id = "M_Equip1", Name = "+1 Pet Equip", Q = 3, R = -3, PriceRing = 2, Text = "Equip 1 more pet", RequiredStage = "Crystal", Cost = 24000000, Effect = {"PetSlots", 1}, Icon = "rbxassetid://80699553071835"},
		{Id = "M_Equip2", Name = "+1 Pet Equip", Q = 4, R = -5, PriceRing = 3, Text = "Equip 1 more pet", RequiredStage = "Retro", Cost = 1600000000, Effect = {"PetSlots", 1}, Icon = "rbxassetid://85255303008088"},
		{Id = "M_Expansion1", Name = "Pet Treats", Q = 1, R = -1, PriceRing = 1, Text = "+10% pet snow bonuses", RequiredStage = "Desert", Cost = 500, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://109909993977311"},
		{Id = "M_Expansion2", Name = "Warm Boots", Q = 2, R = -2, PriceRing = 1, Text = "+1 walk speed", RequiredStage = "Desert", Cost = 720, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://105647738212501"},
		{Id = "M_Expansion3", Name = "Egg Coupons", Q = -2, R = 3, PriceRing = 2, Text = "+2.5% egg price", RequiredStage = "Desert", Cost = 940, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://104972298203092"},
		{Id = "M_Expansion4", Name = "Pet Training", Q = 1, R = -2, PriceRing = 2, Text = "+10% pet snow bonuses", RequiredStage = "Desert", Cost = 1200, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://79029305509084"},
		{Id = "M_Expansion5", Name = "Sandy Steps", Q = -1, R = -1, PriceRing = 2, Text = "+1 walk speed", RequiredStage = "Cursed", Cost = 15000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://111530968258890"},
		{Id = "M_Expansion6", Name = "Egg Savings", Q = -3, R = 3, PriceRing = 2, Text = "+2.5% egg price", RequiredStage = "Cursed", Cost = 22000, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://73053118854334"},
		{Id = "M_Expansion7", Name = "Pet Bond", Q = 2, R = -3, PriceRing = 2, Text = "+10% pet snow bonuses", RequiredStage = "Cursed", Cost = 28000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://99622744607605"},
		{Id = "M_Expansion8", Name = "Trail Boots", Q = 3, R = -1, PriceRing = 2, Text = "+1 walk speed", RequiredStage = "Crystal", Cost = 9300000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://95506938773367"},
		{Id = "M_Expansion9", Name = "Team Spirit", Q = -3, R = 1, PriceRing = 2, Text = "+2.5% snow & luck per friend", RequiredStage = "Crystal", Cost = 4000000, Effect = {"FriendBoost", 0.025}, Icon = "rbxassetid://131945738368827"},
		{Id = "M_Expansion10", Name = "Gem Treats", Q = 3, R = -4, PriceRing = 3, Text = "+10% pet snow bonuses", RequiredStage = "Crystal", Cost = 5800000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://129125768535975"},
		{Id = "M_Expansion11", Name = "Crystal Steps", Q = 3, R = 0, PriceRing = 3, Text = "+1 walk speed", RequiredStage = "Crystal", Cost = 7600000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://105092601357868"},
		{Id = "M_Expansion12", Name = "Egg Vouchers", Q = -4, R = 4, PriceRing = 3, Text = "+2.5% egg price", RequiredStage = "Retro", Cost = 740000000, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://128017941266641"},
		{Id = "M_Expansion13", Name = "Pixel Treats", Q = 4, R = -4, PriceRing = 3, Text = "+10% pet snow bonuses", RequiredStage = "Retro", Cost = 320000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://117492538200985"},
		{Id = "M_Expansion14", Name = "Retro Steps", Q = 4, R = -1, PriceRing = 3, Text = "+1 walk speed", RequiredStage = "Retro", Cost = 460000000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://109419778031012"},
		{Id = "M_Expansion15", Name = "Egg Club", Q = -4, R = 5, PriceRing = 3, Text = "+2.5% egg price", RequiredStage = "Jungle", Cost = 43000000000, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://110152835076568"},
		{Id = "M_Expansion16", Name = "Jungle Treats", Q = 5, R = -5, PriceRing = 3, Text = "+10% pet snow bonuses", RequiredStage = "Jungle", Cost = 53000000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://84028465501957"},
		{Id = "M_Expansion17", Name = "Explorer Boots", Q = 4, R = 0, PriceRing = 3, Text = "+1 walk speed", RequiredStage = "Jungle", Cost = 23000000000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://139306879688755"},
		{Id = "M_Expansion18", Name = "Teamwork", Q = -3, R = 0, PriceRing = 3, Text = "+2.5% snow & luck per friend", RequiredStage = "Jungle", Cost = 33000000000, Effect = {"FriendBoost", 0.025}, Icon = "rbxassetid://88055533648249"},
		{Id = "M_Expansion19", Name = "Frost Treats", Q = 6, R = -6, PriceRing = 3, Text = "+10% pet snow bonuses", RequiredStage = "AbsoluteZero", Cost = 2200000000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://127461719739257"},
		{Id = "M_Expansion20", Name = "Arctic Boots", Q = 5, R = -1, PriceRing = 3, Text = "+1 walk speed", RequiredStage = "AbsoluteZero", Cost = 2800000000000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://116542572902797"},
		{Id = "M_Expansion21", Name = "Pet Mastery", Q = 5, R = -6, PriceRing = 3, Text = "+10% pet snow bonuses", RequiredStage = "AbsoluteZero", Cost = 1200000000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://79870618462425"},
		{Id = "M_Feast", Name = "Treat Feast", Q = 6, R = -7, PriceRing = 3, Effect = {"PetBoostMult", 0.2}, Text = "+20% pet snow bonuses", RequiredStage = "Portal", Cost = 110000000000000, Icon = "rbxassetid://79870618462425"},
		{Id = "W2_KoiCompanions", Name = "Blossom Reach", Q = 0, R = 1, PriceRing = 3, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", RequiredStage = "Sakura", Cost = 140000000000, Icon = "rbxassetid://127232371950782"},
		{Id = "W2_SweetFriends", Name = "Sugar Reach", Q = 1, R = 1, PriceRing = 4, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", RequiredStage = "Candy", Cost = 1100000000000, Icon = "rbxassetid://104727447841125"},
		{Id = "W2_TidalReach", Name = "Tidal Reach", Q = 0, R = 2, PriceRing = 5, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", RequiredStage = "Atlantis", Cost = 3500000000000, Icon = "rbxassetid://131456238471965"},
		{Id = "W2_GiantToys", Name = "Giant Toys", Q = 1, R = 2, PriceRing = 6, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", RequiredStage = "Toybox", Cost = 8700000000000, Icon = "rbxassetid://131456238471965"},
		{Id = "W2_SpringReach", Name = "Spring Reach", Q = 0, R = 3, PriceRing = 7, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", RequiredStage = "Clockwork", Cost = 22000000000000, Icon = "rbxassetid://131456238471965"},
		{Id = "W2_SkyReach", Name = "Sky Reach", Q = 1, R = 3, PriceRing = 8, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", RequiredStage = "Cloud", Cost = 67000000000000, Icon = "rbxassetid://131456238471965"},
		{Id = "W2_GalaxyReach", Name = "Galaxy Reach", Q = 0, R = 4, PriceRing = 9, Effect = {"SizeMult", 0.06}, Text = "+6% blade width; overflow boosts power", RequiredStage = "Cosmic", Cost = 430000000000000, Icon = "rbxassetid://131456238471965"},
		{Id = "M_PortalBoots", Name = "Portal Boots", Q = 5, R = 0, PriceRing = 4, Effect = {"WalkSpeed", 2}, Text = "+2 walk speed", RequiredStage = "Portal", Cost = 88000000000000, Icon = "rbxassetid://116542572902797"},
	}},
}
U.Base = {SizeMult = 1, SpinMult = 1, WalkSpeed = 16, PetSlots = 3, PowerBonus = 0, EggDiscount = 0, LuckMult = 1, FriendBoost = 0, RollCooldownMult = 1, ReachMult = 1, SnowMult = 1, PowerMult = 1, PetBoostMult = 1}
U.Limits = {EggDiscount = {0, 0.5}, RollCooldownMult = {0.6, 1}, ReachMult = {1, 1.5}, SpinMult = {1, 1.6}, WalkSpeed = {16, 40}, PetBoostMult = {1, 2}, FriendBoost = {0, 0.2}}
-- lookups
U.ById, U.TreeById = {}, {}
for _, tree in ipairs(U.Trees) do
	U.TreeById[tree.Id] = tree
	tree.ByPos = {}
	for _, n in ipairs(tree.Nodes) do
		n.Tree = tree.Id
		U.ById[n.Id] = n
		tree.ByPos[n.Q .. "," .. n.R] = n
	end
end

local DIRS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, -1}, {-1, 1}}
function U.Neighbours(n)
	local tree = U.TreeById[n.Tree]
	local out = {}
	for _, d in ipairs(DIRS) do
		local nb = tree.ByPos[(n.Q + d[1]) .. "," .. (n.R + d[2])]
		if nb then table.insert(out, nb) end
	end
	return out
end
function U.Distance(n) return math.max(math.abs(n.Q), math.abs(n.R), math.abs(n.Q + n.R)) end
function U.CostOf(n)
	if n.Cost then return n.Cost end
	local tree = U.TreeById[n.Tree]
	return math.floor(tree.BaseCost * tree.Growth ^ U.Distance(n) * (n.CostMult or 1) + 0.5)
end
-- 2026-10-02 (Claude): Cost-0 stages (World 2 Sakura) open together with the stage before them, exactly like StageService.isOpen.
local StageConfig = require(script.Parent:WaitForChild("StageConfig"))
local function openViaPrevious(stage, stages)
	local s = StageConfig.ById[stage]
	while s and s.Cost == 0 do
		local prev = StageConfig.Previous(s.Id)
		if not prev then return false end
		if stages and stages[prev.Id] then return true end
		s = prev
	end
	return false
end
-- A client and the server use the same stage and adjacency rules.
function U.LockReason(n, owned, stages)
 if owned[n.Id] then return "Owned" end
 local stage = n.RequiredStage or "Starter"
 if stage ~= "Starter" and not (stages and stages[stage]) and not openViaPrevious(stage, stages) then
  return "Unlock " .. (({Cursed = "Cursed Biome", Crystal = "Crystal Caves", Retro = "Retro World", AbsoluteZero = "Absolute Zero", Portal = "Absolute Zero Portal"})[stage] or (StageConfig.ById[stage] and StageConfig.ById[stage].Name) or stage) .. " first"
 end
 if n.Center then return nil end
 for _, nb in ipairs(U.Neighbours(n)) do if owned[nb.Id] then return nil end end
 return "Buy a connected tile first"
end
function U.Available(n, owned, stages) return U.LockReason(n, owned, stages) == nil end
function U.Calculate(owned, friends)
 local stats, mults = table.clone(U.Base), {}
 for id, has in pairs(owned) do
  local n = has and U.ById[id]
  if n and n.Effect then
   local e = n.Effect
   if e[3] == "Mul" then mults[e[1]] = (mults[e[1]] or 1) * (1 + e[2])
   else stats[e[1]] = (stats[e[1]] or 0) + e[2] end
  end
 end
 for k, m in pairs(mults) do stats[k] *= m end
 for k, lim in pairs(U.Limits) do stats[k] = math.clamp(stats[k], lim[1], lim[2]) end
 local friendMult = 1 + stats.FriendBoost * math.clamp(friends or 0, 0, 3)
 stats.SnowMult *= friendMult
 stats.LuckMult *= friendMult
 return stats
end
-- 2026-10-04 (Claude, pacing v3 - user: "even out and boost upgrades"):
--  * NO upgrade is blocked by a stage.
--  * World 1 prices follow ONE smooth curve: upgrades are ordered by tier (old stage lock, or ring for the Snow/Rolls trees), then
--    ring, then old price, and priced from PriceStart up to PriceEnd geometrically (~25% more per step). PriceEnd = 1/4 of the stage
--    after Absolute Zero, capped at 31x Absolute Zero, so a pricey Portal can't create a price wall. World 2 (W2_) prices unchanged.
--  * World 1 snow, clearing power, luck and size upgrades are 30% stronger (descriptions rewritten to match).
--  * Two tiles unlock the pet/crafting machines; the former forge tile improves Snow rewards.
U.RingTier = {
	Snow  = {[2] = "Desert", [3] = "Cursed", [4] = "Crystal", [5] = "Retro", [6] = "Jungle"},
	Rolls = {[2] = "Desert", [3] = "Cursed", [4] = "Crystal", [5] = "Crystal", [6] = "Retro", [7] = "Retro", [8] = "Jungle", [9] = "Jungle", [10] = "AbsoluteZero"},
}
U.PriceStart = 15
-- RESCALE 2026-10-06 (Claude): every x(1+a) Snow / clearing-power upgrade becomes x(1+a)^Compress (0.05 steps) so income grows gently;
-- World 2 prices follow the new stage gates (outputs/Rebalance20261005/sim/emit_rescale.py).
U.Compress = 0.58
U.BoostWorld1 = 1.3
U.MachineUnlocks = {
	M_Pet1 = {Name = "Workshop Rewards", Text = "x1.15 snow", Effect = {"SnowMult", 0.15, "Mul"}, Cost = 3000, IconFrom = "S_Heavy"},
	M_Expansion2 = {Name = "Pet Fuser", Text = "Unlocks the Pet Fuser in the lobby", Effect = {"UnlockFuser", 1}, Cost = 60000, IconFrom = "M_Equip1"},
	M_Expansion5 = {Name = "Crafting Machine", Text = "Unlocks the Crafting Machine in the lobby", Effect = {"UnlockCraft", 1}, Cost = 1000000, IconFrom = "M_Egg3"},
}
U.Base.UnlockFuser, U.Base.UnlockCraft = 0, 0
do
	local function nice(x) -- 2 significant digits
		if x < 100 then return math.floor(x + 0.5) end
		local e = 10 ^ (math.floor(math.log10(x)) - 1)
		return math.floor(x / e + 0.5) * e
	end
	local function fmt(x) return (string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")) end
	local function step(x) if x < 1 then return math.max(0.05, math.floor(x / 0.05 + 0.5) * 0.05) end return math.floor(x / 0.5 + 0.5) * 0.5 end
	-- the machine unlocks (fixed prices, not on the curve)
	for id, props in pairs(U.MachineUnlocks) do
		local n = U.ById[id]
		if n then
			local src = props.IconFrom and U.ById[props.IconFrom]
			n.Name, n.Text, n.Effect, n.Cost = props.Name, props.Text, props.Effect, props.Cost
			if src and src.Icon then n.Icon = src.Icon end
			n.FixedPrice = true
		end
	end
	-- one smooth curve for World 1
	local rank = {}
	for i, s in ipairs(StageConfig.Order) do rank[s.Id] = i end
	local items = {}
	for id, n in pairs(U.ById) do
		if not id:find("^W2_") and not n.FixedPrice then
			local map = U.RingTier[n.Tree]
			local tier = n.RequiredStage or (map and map[U.Distance(n)]) or "Starter"
			table.insert(items, {n = n, t = rank[tier] or 1, d = n.PriceRing or U.Distance(n), c = U.CostOf(n)}) -- 2026-10-06: PriceRing = ring before the Misc re-sort
		end
	end
	table.sort(items, function(a, b)
		if a.t ~= b.t then return a.t < b.t end
		if a.d ~= b.d then return a.d < b.d end
		if a.c ~= b.c then return a.c < b.c end
		return a.n.Id < b.n.Id
	end)
	local azCost, after = 2.5e11, nil
	for i, s in ipairs(StageConfig.Order) do
		if s.Id == "AbsoluteZero" then azCost = s.Cost; after = StageConfig.Order[i + 1] end
	end
	local p0 = U.PriceStart
	local p1 = 0.25 * math.min(after and after.Cost > 0 and after.Cost or azCost * 31, azCost * 31)
	U.PriceEnd = p1
	for k, it in ipairs(items) do
		it.n.Cost = nice(p0 * (p1 / p0) ^ ((k - 1) / math.max(#items - 1, 1)))
	end
	-- boost: World 1 snow / damage / luck / size upgrades are 30% stronger
	for id, n in pairs(U.ById) do
		local e = n.Effect
		if e and not id:find("^W2_") and not n.FixedPrice then
			if (e[1] == "SnowMult" or e[1] == "PowerMult") and e[3] == "Mul" then
				e[2] = step(e[2] * U.BoostWorld1)
				n.Text = (n.Text or ""):gsub("^x[%d%.]+", "x" .. fmt(1 + e[2]))
			elseif e[1] == "LuckMult" and e[3] == nil then
				e[2] = step(e[2] * U.BoostWorld1)
				n.Text = (n.Text or ""):gsub("^%+[%d%.]+%%", "+" .. fmt(e[2] * 100) .. "%%")
			elseif e[1] == "SizeMult" and e[3] == nil then
				e[2] = 0.08
				n.Text = (n.Text or ""):gsub("^%+[%d%.]+%%", "+8%%")
			end
		end
	end
	-- rescale: compress every multiplicative Snow / clearing-power effect (World 1 after its boost, World 2, machine tiles)
	for id, n in pairs(U.ById) do
		local e = n.Effect
		if e and e[3] == "Mul" and (e[1] == "SnowMult" or e[1] == "PowerMult") and U.Compress and U.Compress < 1 then
			e[2] = math.max(0.05, math.floor(((1 + e[2]) ^ U.Compress - 1) / 0.05 + 0.5) * 0.05)
			n.Text = (n.Text or ""):gsub("^x[%d%.]+", "x" .. fmt(1 + e[2]))
		end
	end
	for _, n in pairs(U.ById) do n.RequiredStage = nil end -- no stage locks on upgrades
end

return U
