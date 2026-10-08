--[[ UPGRADE TREES (hexagon honeycomb, Pet Simulator style)
	Each tree has hex tiles on an axial grid (Q, R). Q goes right, R goes down-right.
	The 6 neighbours of (q, r): (q+1,r) (q-1,r) (q,r+1) (q,r-1) (q+1,r-1) (q-1,r+1)
	A tile can be bought when it touches a tile you own (the Center tile is always buyable).
	Effect = {Stat, Add} or {Stat, Mul}. Stats: SnowMult, PowerBonus, PowerMult, ReachMult, SpinMult, ShovelSlots,
	LuckMult, RollAnimScale, DoubleRollChance, EggDiscount, PetSlots, WalkSpeed, FriendBoost.
	Icon = "rbxassetid://..." (optional; text only when empty).
	Cost = tree BaseCost * Growth ^ (distance from center) * (CostMult or 1)   (or set Cost directly)
]]
local U = {}

U.Trees = {
	{Id = "Snow", Name = "SNOW", Color = Color3.fromRGB(110, 200, 255), BaseCost = 50, Growth = 7, Nodes = {
		{Id = "S_Center",  Name = "Snow Start",   Q = 0,  R = 0,  Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow", Center = true},
		{Id = "S_Gain1",   Name = "Snow Gain",    Q = 1,  R = 0,  Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow"},
		{Id = "S_Gain2",   Name = "More Snow",    Q = 2,  R = 0,  Effect = {"SnowMult", 0.15, "Mul"}, Text = "x1.15 snow"},
		{Id = "S_Gain3",   Name = "Snow Pile",    Q = 3,  R = 0,  Effect = {"SnowMult", 0.25, "Mul"}, Text = "x1.25 snow"},
		{Id = "S_Deep",    Name = "Deep Snow",    Q = 4,  R = 0,  Effect = {"SnowMult", 0.25, "Mul"}, Text = "x1.25 snow"},
		{Id = "S_Storm",   Name = "Snowstorm",    Q = 4,  R = -1, Effect = {"SnowMult", 0.5, "Mul"}, Text = "x1.5 snow"},
		{Id = "S_Blizzard",Name = "Blizzard",     Q = 5,  R = -1, Effect = {"SnowMult", 1, "Mul"}, Text = "x2 snow", CostMult = 4},
		{Id = "S_Fresh",   Name = "Fresh Powder", Q = 0,  R = 1,  Effect = {"SnowMult", 0.1, "Mul"}, Text = "x1.1 snow"},
		{Id = "S_Rush",    Name = "Powder Rush",  Q = 1,  R = 1,  Effect = {"SnowMult", 0.25, "Mul"}, Text = "x1.25 snow"},
		{Id = "S_Sharp",   Name = "Sharp Edges",  Q = 0,  R = -1, Effect = {"PowerMult", 0.25, "Mul"}, Text = "x1.25 shovel damage"},
		{Id = "S_Heavy",   Name = "Heavy Hits",   Q = 0,  R = -2, Effect = {"PowerMult", 0.25, "Mul"}, Text = "x1.25 shovel damage"},
		{Id = "S_Swing",   Name = "Power Swing",  Q = -1, R = -2, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 shovel damage"},
		{Id = "S_Crush",   Name = "Crushing Blow",Q = 1,  R = -3, Effect = {"PowerMult", 1, "Mul"}, Text = "x2 shovel damage", CostMult = 3},
		{Id = "S_Arms",    Name = "Longer Arms",  Q = -1, R = 1,  Effect = {"ReachMult", 0.10}, Text = "+10% reach"},
		{Id = "S_Wide",    Name = "Wide Reach",   Q = -2, R = 2,  Effect = {"ReachMult", 0.10}, Text = "+10% reach"},
		{Id = "S_Quick",   Name = "Quick Spin",   Q = -1, R = 2,  Effect = {"SpinMult", 0.15}, Text = "+15% spin speed"},
		{Id = "S_Turbo",   Name = "Turbo Spin",   Q = -2, R = 3,  Effect = {"SpinMult", 0.15}, Text = "+15% spin speed"},
		{Id = "S_Third",   Name = "+1 Shovel",    Q = -3, R = 3,  Effect = {"ShovelSlots", 1}, Text = "Equip a 3rd shovel", CostMult = 20},
	}},
	{Id = "Rolls", Name = "ROLLS", Color = Color3.fromRGB(255, 190, 60), BaseCost = 75, Growth = 7, Nodes = {
		{Id = "R_Center",  Name = "Roll Start",   Q = 0,  R = 0,  Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck", Center = true},
		{Id = "R_Luck1",   Name = "Luck",         Q = 1,  R = 0,  Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck"},
		{Id = "R_Luck2",   Name = "Luckier",      Q = 2,  R = 0,  Effect = {"LuckMult", 0.15, "Mul"}, Text = "x1.15 luck"},
		{Id = "R_Charm",   Name = "Lucky Charm",  Q = 3,  R = 0,  Effect = {"LuckMult", 0.25, "Mul"}, Text = "x1.25 luck"},
		{Id = "R_BigLuck", Name = "Big Luck",     Q = 3,  R = -1, Effect = {"LuckMult", 0.25, "Mul"}, Text = "x1.25 luck"},
		{Id = "R_Mega",    Name = "Mega Luck",    Q = 4,  R = -1, Effect = {"LuckMult", 1, "Mul"}, Text = "x2 luck", CostMult = 3},
		{Id = "R_Ultra",   Name = "Ultra Luck",   Q = 5,  R = -2, Effect = {"LuckMult", 2, "Mul"}, Text = "x3 luck", CostMult = 10},
		{Id = "R_Clover1", Name = "Four Leaf",    Q = 0,  R = 1,  Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck"},
		{Id = "R_Clover2", Name = "Clover Patch", Q = 1,  R = 1,  Effect = {"LuckMult", 0.15, "Mul"}, Text = "x1.15 luck"},
		{Id = "R_Field",   Name = "Clover Field", Q = 1,  R = 2,  Effect = {"LuckMult", 0.5, "Mul"}, Text = "x1.5 luck"},
		{Id = "R_Quick1",  Name = "Quick Roll",   Q = 0,  R = -1, Effect = {"RollAnimScale", -0.10}, Text = "-10% roll time"},
		{Id = "R_Quick2",  Name = "Quicker Roll", Q = -1, R = -1, Effect = {"RollAnimScale", -0.10}, Text = "-10% roll time"},
		{Id = "R_Speedy",  Name = "Speedy Dice",  Q = -1, R = -2, Effect = {"RollAnimScale", -0.10}, Text = "-10% roll time"},
		{Id = "R_Double1", Name = "Double Roll",  Q = -1, R = 1,  Effect = {"DoubleRollChance", 0.05}, Text = "5% bonus roll"},
		{Id = "R_Double2", Name = "Double Luck",  Q = -2, R = 1,  Effect = {"DoubleRollChance", 0.05}, Text = "+5% bonus roll"},
		{Id = "R_Double3", Name = "Two Of A Kind",Q = -2, R = 2,  Effect = {"DoubleRollChance", 0.05}, Text = "+5% bonus roll"},
		{Id = "R_Double4", Name = "Lucky Doubles",Q = -3, R = 2,  Effect = {"DoubleRollChance", 0.10}, Text = "+10% bonus roll", CostMult = 4},
	}},
	{Id = "Misc", Name = "MISC", Color = Color3.fromRGB(130, 225, 120), BaseCost = 60, Growth = 6, Nodes = {
		{Id = "M_Center",  Name = "Misc Start",   Q = 0,  R = 0,  Effect = {"WalkSpeed", 1}, Text = "+1 walk speed", Center = true},
		{Id = "M_Walk1",   Name = "Walk Speed",   Q = 1,  R = 0,  Effect = {"WalkSpeed", 2}, Text = "+2 walk speed"},
		{Id = "M_Walk2",   Name = "Fast Feet",    Q = 2,  R = 0,  Effect = {"WalkSpeed", 2}, Text = "+2 walk speed"},
		{Id = "M_Sprint",  Name = "Sprinter",     Q = 3,  R = -1, Effect = {"WalkSpeed", 3}, Text = "+3 walk speed", CostMult = 2},
		{Id = "M_Friend1", Name = "Friend Boost", Q = 0,  R = -1, Effect = {"FriendBoost", 0.05}, Text = "+5% snow & luck per friend here"},
		{Id = "M_Friend2", Name = "Best Friends", Q = 0,  R = -2, Effect = {"FriendBoost", 0.05}, Text = "+5% per friend here"},
		{Id = "M_Squad",   Name = "Squad Goals",  Q = 1,  R = -3, Effect = {"FriendBoost", 0.05}, Text = "+5% per friend here", CostMult = 2},
		{Id = "M_Egg1",    Name = "Egg Discount", Q = -1, R = 1,  Effect = {"EggDiscount", 0.05}, Text = "-5% egg price"},
		{Id = "M_Egg2",    Name = "Egg Deals",    Q = -2, R = 1,  Effect = {"EggDiscount", 0.05}, Text = "-5% egg price"},
		{Id = "M_Egg3",    Name = "Egg Sale",     Q = -2, R = 2,  Effect = {"EggDiscount", 0.10}, Text = "-10% egg price"},
		{Id = "M_Egg4",    Name = "Egg Bargain",  Q = -3, R = 2,  Effect = {"EggDiscount", 0.10}, Text = "-10% egg price", CostMult = 2},
		{Id = "M_Pet1",    Name = "Pet Care",     Q = 0,  R = 1,  Effect = {"WalkSpeed", 1}, Text = "+1 walk speed"},
		{Id = "M_Equip1",  Name = "+1 Pet Equip", Q = 0,  R = 2,  Effect = {"PetSlots", 1}, Text = "Equip 1 more pet", CostMult = 10},
		{Id = "M_Equip2",  Name = "+1 Pet Equip", Q = 1,  R = 2,  Effect = {"PetSlots", 1}, Text = "Equip 1 more pet", CostMult = 40},
	}},
}

-- base values of every stat
U.Base = {SnowMult = 1, PowerBonus = 0, PowerMult = 1, ReachMult = 1, SpinMult = 1, ShovelSlots = 2, LuckMult = 1,
	RollAnimScale = 1, DoubleRollChance = 0, EggDiscount = 0, PetSlots = 3, WalkSpeed = 16, FriendBoost = 0}
U.Limits = {RollAnimScale = {0.4, 1}, EggDiscount = {0, 0.5}, DoubleRollChance = {0, 0.5}}

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
-- can this tile be bought, given a set of owned ids?
function U.Available(n, owned)
	if owned[n.Id] then return false end
	if n.Center then return true end
	for _, nb in ipairs(U.Neighbours(n)) do
		if owned[nb.Id] then return true end
	end
	return false
end

return U

