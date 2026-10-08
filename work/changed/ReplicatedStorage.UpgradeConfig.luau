-- Progression v2: 105 upgrades. IDs are preserved so existing purchases remain owned.
-- Cost and RequiredStage describe progression; Q/R only describe the visual layout.
-- Add Icon = "rbxassetid://..." to any node when its artwork is ready.
local U = {}
U.Trees = {
	{Id = "Snow", Name = "SNOW", Color = Color3.fromRGB(110, 200, 255), Nodes = {
		{Id = "S_Center", Name = "Snow Start", Q = 0, R = 0, Text = "x1.1 snow", RequiredStage = "Starter", Cost = 38, Center = true, Effect = {"SnowMult", 0.1, "Mul"}},
		{Id = "S_Gain1", Name = "Snow Gain", Q = 1, R = 0, Text = "x1.1 snow", RequiredStage = "Starter", Cost = 143, Effect = {"SnowMult", 0.1, "Mul"}},
		{Id = "S_Gain2", Name = "More Snow", Q = 2, R = 0, Text = "x1.15 snow", RequiredStage = "Desert", Cost = 8000, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Gain3", Name = "Snow Pile", Q = 3, R = 0, Text = "x1.25 snow", RequiredStage = "Cursed", Cost = 195000, Effect = {"SnowMult", 0.25, "Mul"}},
		{Id = "S_Deep", Name = "Deep Snow", Q = 4, R = 0, Text = "x1.25 snow", RequiredStage = "Crystal", Cost = 7000000, Effect = {"SnowMult", 0.25, "Mul"}},
		{Id = "S_Storm", Name = "Snowstorm", Q = 4, R = -1, Text = "x1.5 snow", RequiredStage = "Crystal", Cost = 13300000, Effect = {"SnowMult", 0.5, "Mul"}},
		{Id = "S_Blizzard", Name = "Blizzard", Q = 5, R = -1, Text = "x2 snow", RequiredStage = "Retro", Cost = 480000000, Effect = {"SnowMult", 1, "Mul"}},
		{Id = "S_Fresh", Name = "Fresh Powder", Q = 0, R = 1, Text = "x1.1 snow", RequiredStage = "Starter", Cost = 98, Effect = {"SnowMult", 0.1, "Mul"}},
		{Id = "S_Rush", Name = "Powder Rush", Q = 1, R = 1, Text = "x1.25 snow", RequiredStage = "Desert", Cost = 5000, Effect = {"SnowMult", 0.25, "Mul"}},
		{Id = "S_Sharp", Name = "Sharp Edges", Q = 0, R = -1, Text = "x1.25 shovel damage", RequiredStage = "Starter", Cost = 98, Effect = {"PowerMult", 0.25, "Mul"}},
		{Id = "S_Heavy", Name = "Heavy Hits", Q = 0, R = -2, Text = "x1.25 shovel damage", RequiredStage = "Desert", Cost = 8000, Effect = {"PowerMult", 0.25, "Mul"}},
		{Id = "S_Swing", Name = "Power Swing", Q = -1, R = -2, Text = "x1.5 shovel damage", RequiredStage = "Cursed", Cost = 195000, Effect = {"PowerMult", 0.5, "Mul"}},
		{Id = "S_Crush", Name = "Crushing Blow", Q = 1, R = -3, Text = "x2 shovel damage", RequiredStage = "Cursed", Cost = 150000, Effect = {"PowerMult", 1, "Mul"}},
		{Id = "S_Arms", Name = "Longer Arms", Q = -1, R = 1, Text = "+10% reach", RequiredStage = "Starter", Cost = 120, Effect = {"ReachMult", 0.1}},
		{Id = "S_Wide", Name = "Wide Reach", Q = -2, R = 2, Text = "+10% reach", RequiredStage = "Desert", Cost = 5000, Effect = {"ReachMult", 0.1}},
		{Id = "S_Quick", Name = "Quick Spin", Q = -1, R = 2, Text = "+15% spin speed", RequiredStage = "Desert", Cost = 6500, Effect = {"SpinMult", 0.15}},
		{Id = "S_Turbo", Name = "Turbo Spin", Q = -2, R = 3, Text = "+15% spin speed", RequiredStage = "Cursed", Cost = 285000, Effect = {"SpinMult", 0.15}},
		{Id = "S_Third", Name = "+1 Shovel", Q = -3, R = 3, Text = "Equip a 3rd shovel", RequiredStage = "Crystal", Cost = 33600000, Effect = {"ShovelSlots", 1}},
		{Id = "S_Expansion1", Name = "Packed Powder", Q = 1, R = -1, Text = "x1.15 snow", RequiredStage = "Desert", Cost = 4000, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Expansion2", Name = "Snow Sacks", Q = -1, R = 0, Text = "x1.15 snow", RequiredStage = "Desert", Cost = 5750, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Expansion3", Name = "Deep Cut", Q = 1, R = -2, Text = "x1.15 shovel damage", RequiredStage = "Desert", Cost = 7500, Effect = {"PowerMult", 0.15, "Mul"}},
		{Id = "S_Expansion4", Name = "Wide Sweep", Q = 2, R = -2, Text = "+5% reach", RequiredStage = "Cursed", Cost = 277500, Effect = {"ReachMult", 0.05}},
		{Id = "S_Expansion5", Name = "Frost Fortune", Q = -1, R = -1, Text = "x1.15 snow", RequiredStage = "Cursed", Cost = 120000, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Expansion6", Name = "Ice Breaker", Q = 2, R = -1, Text = "x1.15 shovel damage", RequiredStage = "Cursed", Cost = 172500, Effect = {"PowerMult", 0.15, "Mul"}},
		{Id = "S_Expansion7", Name = "Swift Sweep", Q = -2, R = 0, Text = "+5% spin speed", RequiredStage = "Crystal", Cost = 10500000, Effect = {"SpinMult", 0.05}},
		{Id = "S_Expansion8", Name = "Crystal Cache", Q = -2, R = 1, Text = "x1.15 snow", RequiredStage = "Crystal", Cost = 12950000, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Expansion9", Name = "Crystal Edge", Q = 0, R = 2, Text = "x1.15 shovel damage", RequiredStage = "Crystal", Cost = 5600000, Effect = {"PowerMult", 0.15, "Mul"}},
		{Id = "S_Expansion10", Name = "Retro Riches", Q = 0, R = -3, Text = "x1.15 snow", RequiredStage = "Retro", Cost = 345000000, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Expansion11", Name = "Pixel Power", Q = 2, R = -3, Text = "x1.15 shovel damage", RequiredStage = "Retro", Cost = 450000000, Effect = {"PowerMult", 0.15, "Mul"}},
		{Id = "S_Expansion12", Name = "Jungle Haul", Q = 3, R = -3, Text = "x1.15 snow", RequiredStage = "Retro", Cost = 555000000, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Expansion13", Name = "Long Sweep", Q = 3, R = -2, Text = "+5% reach", RequiredStage = "Jungle", Cost = 12800000000, Effect = {"ReachMult", 0.05}},
		{Id = "S_Expansion14", Name = "Polar Power", Q = -2, R = -1, Text = "x1.15 shovel damage", RequiredStage = "Jungle", Cost = 18400000000, Effect = {"PowerMult", 0.15, "Mul"}},
		{Id = "S_Expansion15", Name = "Frozen Fortune", Q = 3, R = -1, Text = "x1.15 snow", RequiredStage = "Jungle", Cost = 24000000000, Effect = {"SnowMult", 0.15, "Mul"}},
		{Id = "S_Expansion16", Name = "Arctic Spin", Q = -3, R = 0, Text = "+5% spin speed", RequiredStage = "AbsoluteZero", Cost = 1110000000000, Effect = {"SpinMult", 0.05}},
		{Id = "S_Expansion17", Name = "Snow Mastery", Q = -3, R = 1, Text = "x1.15 snow", RequiredStage = "AbsoluteZero", Cost = 480000000000, Effect = {"SnowMult", 0.15, "Mul"}},
	}},
	{Id = "Rolls", Name = "ROLLS", Color = Color3.fromRGB(255, 190, 60), Nodes = {
		{Id = "R_Center", Name = "Roll Start", Q = 0, R = 0, Text = "x1.1 luck", RequiredStage = "Starter", Cost = 38, Center = true, Effect = {"LuckMult", 0.1, "Mul"}},
		{Id = "R_Luck1", Name = "Luck", Q = 1, R = 0, Text = "x1.1 luck", RequiredStage = "Starter", Cost = 143, Effect = {"LuckMult", 0.1, "Mul"}},
		{Id = "R_Luck2", Name = "Luckier", Q = 2, R = 0, Text = "x1.15 luck", RequiredStage = "Desert", Cost = 8000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Charm", Name = "Lucky Charm", Q = 3, R = 0, Text = "x1.25 luck", RequiredStage = "Cursed", Cost = 195000, Effect = {"LuckMult", 0.25, "Mul"}},
		{Id = "R_BigLuck", Name = "Big Luck", Q = 3, R = -1, Text = "x1.25 luck", RequiredStage = "Cursed", Cost = 150000, Effect = {"LuckMult", 0.25, "Mul"}},
		{Id = "R_Mega", Name = "Mega Luck", Q = 4, R = -1, Text = "x2 luck", RequiredStage = "Crystal", Cost = 13300000, Effect = {"LuckMult", 1, "Mul"}},
		{Id = "R_Ultra", Name = "Ultra Luck", Q = 5, R = -2, Text = "x3 luck", RequiredStage = "Retro", Cost = 390000000, Effect = {"LuckMult", 2, "Mul"}},
		{Id = "R_Clover1", Name = "Four Leaf", Q = 0, R = 1, Text = "x1.1 luck", RequiredStage = "Starter", Cost = 98, Effect = {"LuckMult", 0.1, "Mul"}},
		{Id = "R_Clover2", Name = "Clover Patch", Q = 1, R = 1, Text = "x1.15 luck", RequiredStage = "Desert", Cost = 5000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Field", Name = "Clover Field", Q = 1, R = 2, Text = "x1.5 luck", RequiredStage = "Cursed", Cost = 195000, Effect = {"LuckMult", 0.5, "Mul"}},
		{Id = "R_Quick1", Name = "Quick Roll", Q = 0, R = -1, Text = "-10% roll time", RequiredStage = "Starter", Cost = 98, Effect = {"RollAnimScale", -0.1}},
		{Id = "R_Quick2", Name = "Quicker Roll", Q = -1, R = -1, Text = "-10% roll time", RequiredStage = "Desert", Cost = 5000, Effect = {"RollAnimScale", -0.1}},
		{Id = "R_Speedy", Name = "Speedy Dice", Q = -1, R = -2, Text = "-10% roll time", RequiredStage = "Cursed", Cost = 195000, Effect = {"RollAnimScale", -0.1}},
		{Id = "R_Double1", Name = "Double Roll", Q = -1, R = 1, Text = "5% bonus roll", RequiredStage = "Starter", Cost = 120, Effect = {"DoubleRollChance", 0.05}},
		{Id = "R_Double2", Name = "Double Luck", Q = -2, R = 1, Text = "+5% bonus roll", RequiredStage = "Desert", Cost = 6500, Effect = {"DoubleRollChance", 0.05}},
		{Id = "R_Double3", Name = "Two Of A Kind", Q = -2, R = 2, Text = "+5% bonus roll", RequiredStage = "Desert", Cost = 5000, Effect = {"DoubleRollChance", 0.05}},
		{Id = "R_Double4", Name = "Lucky Doubles", Q = -3, R = 2, Text = "+10% bonus roll", RequiredStage = "Cursed", Cost = 285000, Effect = {"DoubleRollChance", 0.1}},
		{Id = "R_Expansion1", Name = "Lucky Flakes", Q = 1, R = -1, Text = "x1.15 luck", RequiredStage = "Desert", Cost = 4000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion2", Name = "Lucky Streak", Q = -1, R = 0, Text = "x1.15 luck", RequiredStage = "Desert", Cost = 5750, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion3", Name = "Twin Dice", Q = 0, R = -2, Text = "+2.5% bonus roll chance", RequiredStage = "Desert", Cost = 7500, Effect = {"DoubleRollChance", 0.025}},
		{Id = "R_Expansion4", Name = "Sand Charm", Q = 1, R = -2, Text = "x1.15 luck", RequiredStage = "Cursed", Cost = 277500, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion5", Name = "Quick Hands", Q = 2, R = -2, Text = "-2.5% roll time", RequiredStage = "Cursed", Cost = 120000, Effect = {"RollAnimScale", -0.025}},
		{Id = "R_Expansion6", Name = "Cursed Charm", Q = 2, R = -1, Text = "x1.15 luck", RequiredStage = "Cursed", Cost = 172500, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion7", Name = "Fortune Finder", Q = -2, R = 0, Text = "x1.15 luck", RequiredStage = "Crystal", Cost = 10500000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion8", Name = "Gem Fortune", Q = -1, R = 2, Text = "x1.15 luck", RequiredStage = "Crystal", Cost = 12950000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion9", Name = "Double Gems", Q = 0, R = 2, Text = "+2.5% bonus roll chance", RequiredStage = "Crystal", Cost = 5600000, Effect = {"DoubleRollChance", 0.025}},
		{Id = "R_Expansion10", Name = "Pixel Luck", Q = 0, R = -3, Text = "x1.15 luck", RequiredStage = "Retro", Cost = 345000000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion11", Name = "Retro Fortune", Q = 1, R = -3, Text = "x1.15 luck", RequiredStage = "Retro", Cost = 450000000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion12", Name = "Twin Pixels", Q = 2, R = -3, Text = "+2.5% bonus roll chance", RequiredStage = "Retro", Cost = 555000000, Effect = {"DoubleRollChance", 0.025}},
		{Id = "R_Expansion13", Name = "Jungle Charm", Q = 3, R = -3, Text = "x1.15 luck", RequiredStage = "Jungle", Cost = 12800000000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion14", Name = "Fortune Trail", Q = 3, R = -2, Text = "x1.15 luck", RequiredStage = "Jungle", Cost = 18400000000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion15", Name = "Frost Luck", Q = -2, R = -1, Text = "x1.15 luck", RequiredStage = "Jungle", Cost = 24000000000, Effect = {"LuckMult", 0.15, "Mul"}},
		{Id = "R_Expansion16", Name = "Swift Dice", Q = -3, R = 0, Text = "-2.5% roll time", RequiredStage = "AbsoluteZero", Cost = 1110000000000, Effect = {"RollAnimScale", -0.025}},
		{Id = "R_Expansion17", Name = "Twin Frost", Q = -3, R = 1, Text = "+2.5% bonus roll chance", RequiredStage = "AbsoluteZero", Cost = 480000000000, Effect = {"DoubleRollChance", 0.025}},
		{Id = "R_Expansion18", Name = "Fortune Mastery", Q = 2, R = 1, Text = "x1.15 luck", RequiredStage = "AbsoluteZero", Cost = 690000000000, Effect = {"LuckMult", 0.15, "Mul"}},
	}},
	{Id = "Misc", Name = "MISC", Color = Color3.fromRGB(130, 225, 120), Nodes = {
		{Id = "M_Center", Name = "Misc Start", Q = 0, R = 0, Text = "+1 walk speed", RequiredStage = "Starter", Cost = 38, Center = true, Effect = {"WalkSpeed", 1}},
		{Id = "M_Walk1", Name = "Walk Speed", Q = 1, R = 0, Text = "+2 walk speed", RequiredStage = "Starter", Cost = 143, Effect = {"WalkSpeed", 2}},
		{Id = "M_Walk2", Name = "Fast Feet", Q = 2, R = 0, Text = "+2 walk speed", RequiredStage = "Desert", Cost = 8000, Effect = {"WalkSpeed", 2}},
		{Id = "M_Sprint", Name = "Sprinter", Q = 3, R = -1, Text = "+3 walk speed", RequiredStage = "Cursed", Cost = 150000, Effect = {"WalkSpeed", 3}},
		{Id = "M_Friend1", Name = "Friend Boost", Q = 0, R = -1, Text = "+5% snow & luck per friend here", RequiredStage = "Starter", Cost = 98, Effect = {"FriendBoost", 0.05}},
		{Id = "M_Friend2", Name = "Best Friends", Q = 0, R = -2, Text = "+5% per friend here", RequiredStage = "Desert", Cost = 8000, Effect = {"FriendBoost", 0.05}},
		{Id = "M_Squad", Name = "Squad Goals", Q = 1, R = -3, Text = "+5% per friend here", RequiredStage = "Cursed", Cost = 150000, Effect = {"FriendBoost", 0.05}},
		{Id = "M_Egg1", Name = "Egg Discount", Q = -1, R = 1, Text = "-5% egg price", RequiredStage = "Starter", Cost = 120, Effect = {"EggDiscount", 0.05}},
		{Id = "M_Egg2", Name = "Egg Deals", Q = -2, R = 1, Text = "-5% egg price", RequiredStage = "Desert", Cost = 6500, Effect = {"EggDiscount", 0.05}},
		{Id = "M_Egg3", Name = "Egg Sale", Q = -2, R = 2, Text = "-10% egg price", RequiredStage = "Desert", Cost = 5000, Effect = {"EggDiscount", 0.1}},
		{Id = "M_Egg4", Name = "Egg Bargain", Q = -3, R = 2, Text = "-10% egg price", RequiredStage = "Cursed", Cost = 285000, Effect = {"EggDiscount", 0.1}},
		{Id = "M_Pet1", Name = "Pet Care", Q = 0, R = 1, Text = "+1 walk speed", RequiredStage = "Starter", Cost = 98, Effect = {"WalkSpeed", 1}},
		{Id = "M_Equip1", Name = "+1 Pet Equip", Q = 0, R = 2, Text = "Equip 1 more pet", RequiredStage = "Crystal", Cost = 33600000, Effect = {"PetSlots", 1}},
		{Id = "M_Equip2", Name = "+1 Pet Equip", Q = 1, R = 2, Text = "Equip 1 more pet", RequiredStage = "Retro", Cost = 1170000000, Effect = {"PetSlots", 1}},
		{Id = "M_Expansion1", Name = "Pet Treats", Q = 1, R = -1, Text = "+10% pet snow bonuses", RequiredStage = "Desert", Cost = 4000, Effect = {"PetBoostMult", 0.1}},
		{Id = "M_Expansion2", Name = "Warm Boots", Q = -1, R = 0, Text = "+1 walk speed", RequiredStage = "Desert", Cost = 5750, Effect = {"WalkSpeed", 1}},
		{Id = "M_Expansion3", Name = "Egg Coupons", Q = 1, R = -2, Text = "+2.5% egg price", RequiredStage = "Desert", Cost = 7500, Effect = {"EggDiscount", 0.025}},
		{Id = "M_Expansion4", Name = "Pet Training", Q = 2, R = -2, Text = "+10% pet snow bonuses", RequiredStage = "Desert", Cost = 9250, Effect = {"PetBoostMult", 0.1}},
		{Id = "M_Expansion5", Name = "Sandy Steps", Q = -1, R = -1, Text = "+1 walk speed", RequiredStage = "Cursed", Cost = 120000, Effect = {"WalkSpeed", 1}},
		{Id = "M_Expansion6", Name = "Egg Savings", Q = 2, R = -1, Text = "+2.5% egg price", RequiredStage = "Cursed", Cost = 172500, Effect = {"EggDiscount", 0.025}},
		{Id = "M_Expansion7", Name = "Pet Bond", Q = -2, R = 0, Text = "+10% pet snow bonuses", RequiredStage = "Cursed", Cost = 225000, Effect = {"PetBoostMult", 0.1}},
		{Id = "M_Expansion8", Name = "Trail Boots", Q = 1, R = 1, Text = "+1 walk speed", RequiredStage = "Crystal", Cost = 12950000, Effect = {"WalkSpeed", 1}},
		{Id = "M_Expansion9", Name = "Team Spirit", Q = -1, R = 2, Text = "+2.5% snow & luck per friend", RequiredStage = "Crystal", Cost = 5600000, Effect = {"FriendBoost", 0.025}},
		{Id = "M_Expansion10", Name = "Gem Treats", Q = 0, R = -3, Text = "+10% pet snow bonuses", RequiredStage = "Crystal", Cost = 8050000, Effect = {"PetBoostMult", 0.1}},
		{Id = "M_Expansion11", Name = "Crystal Steps", Q = 2, R = -3, Text = "+1 walk speed", RequiredStage = "Crystal", Cost = 10500000, Effect = {"WalkSpeed", 1}},
		{Id = "M_Expansion12", Name = "Egg Vouchers", Q = 3, R = -3, Text = "+2.5% egg price", RequiredStage = "Retro", Cost = 555000000, Effect = {"EggDiscount", 0.025}},
		{Id = "M_Expansion13", Name = "Pixel Treats", Q = -1, R = -2, Text = "+10% pet snow bonuses", RequiredStage = "Retro", Cost = 240000000, Effect = {"PetBoostMult", 0.1}},
		{Id = "M_Expansion14", Name = "Retro Steps", Q = 3, R = -2, Text = "+1 walk speed", RequiredStage = "Retro", Cost = 345000000, Effect = {"WalkSpeed", 1}},
		{Id = "M_Expansion15", Name = "Egg Club", Q = -2, R = -1, Text = "+2.5% egg price", RequiredStage = "Jungle", Cost = 24000000000, Effect = {"EggDiscount", 0.025}},
		{Id = "M_Expansion16", Name = "Jungle Treats", Q = -3, R = 0, Text = "+10% pet snow bonuses", RequiredStage = "Jungle", Cost = 29600000000, Effect = {"PetBoostMult", 0.1}},
		{Id = "M_Expansion17", Name = "Explorer Boots", Q = 3, R = 0, Text = "+1 walk speed", RequiredStage = "Jungle", Cost = 12800000000, Effect = {"WalkSpeed", 1}},
		{Id = "M_Expansion18", Name = "Teamwork", Q = -3, R = 1, Text = "+2.5% snow & luck per friend", RequiredStage = "Jungle", Cost = 18400000000, Effect = {"FriendBoost", 0.025}},
		{Id = "M_Expansion19", Name = "Frost Treats", Q = 2, R = 1, Text = "+10% pet snow bonuses", RequiredStage = "AbsoluteZero", Cost = 900000000000, Effect = {"PetBoostMult", 0.1}},
		{Id = "M_Expansion20", Name = "Arctic Boots", Q = -3, R = 3, Text = "+1 walk speed", RequiredStage = "AbsoluteZero", Cost = 1110000000000, Effect = {"WalkSpeed", 1}},
		{Id = "M_Expansion21", Name = "Pet Mastery", Q = -2, R = 3, Text = "+10% pet snow bonuses", RequiredStage = "AbsoluteZero", Cost = 480000000000, Effect = {"PetBoostMult", 0.1}},
	}},
}
U.Base = {SpinMult = 1, WalkSpeed = 16, ShovelSlots = 2, PetSlots = 3, PowerBonus = 0, EggDiscount = 0, LuckMult = 1, FriendBoost = 0, RollAnimScale = 1, ReachMult = 1, DoubleRollChance = 0, SnowMult = 1, PowerMult = 1, PetBoostMult = 1}
U.Limits = {EggDiscount = {0, 0.5}, DoubleRollChance = {0, 0.5}, RollAnimScale = {0.6, 1}, ReachMult = {1, 1.5}, SpinMult = {1, 1.6}, WalkSpeed = {16, 40}, PetBoostMult = {1, 2}, FriendBoost = {0, 0.2}}
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
-- A client and the server use the same stage and adjacency rules.
function U.LockReason(n, owned, stages)
 if owned[n.Id] then return "Owned" end
 local stage = n.RequiredStage or "Starter"
 if stage ~= "Starter" and not (stages and stages[stage]) then
  return "Unlock " .. (({Cursed = "Cursed Biome", Crystal = "Crystal Caves", Retro = "Retro World", AbsoluteZero = "Absolute Zero"})[stage] or stage) .. " first"
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
return U
