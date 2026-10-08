-- Progression v2: 105 upgrades. IDs are preserved so existing purchases remain owned.
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
		{Id = "S_Sharp", Name = "Sharp Edges", Q = 0, R = -1, Effect = {"PowerMult", 0.25, "Mul"}, Text = "x1.25 shovel damage", Icon = "rbxassetid://88396818256494"},
		{Id = "S_Heavy", Name = "Heavy Hits", Q = 0, R = -2, Effect = {"PowerMult", 0.25, "Mul"}, Text = "x1.25 shovel damage", Icon = "rbxassetid://126452827773697"},
		{Id = "S_Swing", Name = "Power Swing", Q = -1, R = -2, Effect = {"PowerMult", 0.5, "Mul"}, Text = "x1.5 shovel damage", Icon = "rbxassetid://130505359203868"},
		{Id = "S_Crush", Name = "Crushing Blow", Q = 1, R = -3, Effect = {"PowerMult", 1, "Mul"}, Text = "x2 shovel damage", CostMult = 3, Icon = "rbxassetid://95515443709296"},
		{Id = "S_Quick", Name = "Quick Spin", Q = 0, R = 2, Effect = {"SpinMult", 0.15}, Text = "+15% spin speed", Icon = "rbxassetid://113767999233566"},
		{Id = "S_Turbo", Name = "Turbo Spin", Q = 0, R = 3, Effect = {"SpinMult", 0.15}, Text = "+15% spin speed", Icon = "rbxassetid://99774561784389"},
		{Id = "S_Third", Name = "+1 Shovel", Q = -1, R = 3, Effect = {"ShovelSlots", 1}, Text = "Equip a 3rd shovel", CostMult = 20, Icon = "rbxassetid://113684057278608"},
		{Id = "S_Size1", Name = "Bigger Shovel I", Q = -1, R = 1, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://127232371950782"},
		{Id = "S_Size2", Name = "Bigger Shovel II", Q = -1, R = 2, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://104727447841125"},
		{Id = "S_Size3", Name = "Bigger Shovel III", Q = -2, R = 2, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://131456238471965"},
		{Id = "S_Size4", Name = "Bigger Shovel IV", Q = -2, R = 3, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://87556604641604"},
		{Id = "S_Size5", Name = "Bigger Shovel V", Q = -3, R = 3, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://94266678186706"},
		{Id = "S_Size6", Name = "Bigger Shovel VI", Q = -3, R = 4, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://77143044227391"},
		{Id = "S_Size7", Name = "Bigger Shovel VII", Q = -4, R = 4, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://120267984209832"},
		{Id = "S_Size8", Name = "Bigger Shovel VIII", Q = -4, R = 5, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://134088287054458"},
		{Id = "S_Size9", Name = "Bigger Shovel IX", Q = -5, R = 5, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://128880797000767"},
		{Id = "S_Size10", Name = "Bigger Shovel X", Q = -5, R = 6, Effect = {"SizeMult", 0.06}, Text = "+6% shovel size & reach", Icon = "rbxassetid://109631617606961", CostMult = 3},
	}},
	{Id = "Rolls", Name = "ROLLS", Color = Color3.fromRGB(255, 190, 60), BaseCost = 75, Growth = 4.5, Nodes = {
		{Id = "R_Luck1", Name = "Lucky Start", Q = 0, R = 0, Effect = {"LuckMult", 0.05, "Mul"}, Text = "x1.05 luck", Icon = "rbxassetid://74613534440214", Center = true},
		{Id = "R_Luck2", Name = "Four Leaf", Q = 1, R = 0, Effect = {"LuckMult", 0.05, "Mul"}, Text = "x1.05 luck", Icon = "rbxassetid://135947304140304"},
		{Id = "R_Luck3", Name = "Clover Bunch", Q = 1, R = -1, Effect = {"LuckMult", 0.05, "Mul"}, Text = "x1.05 luck", Icon = "rbxassetid://114594217802990"},
		{Id = "R_Luck4", Name = "Lucky Leaf", Q = 2, R = -1, Effect = {"LuckMult", 0.05, "Mul"}, Text = "x1.05 luck", Icon = "rbxassetid://82230156041586"},
		{Id = "R_Luck5", Name = "Clover Coin", Q = 2, R = 0, Effect = {"LuckMult", 0.05, "Mul"}, Text = "x1.05 luck", Icon = "rbxassetid://108405377877908"},
		{Id = "R_Luck6", Name = "Horseshoe", Q = 3, R = -1, Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck", Icon = "rbxassetid://130847433715579"},
		{Id = "R_Luck7", Name = "Golden Clover", Q = 3, R = -2, Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck", Icon = "rbxassetid://132120945342976"},
		{Id = "R_Luck8", Name = "Gold Luck", Q = 4, R = -2, Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck", Icon = "rbxassetid://92901021126921"},
		{Id = "R_Luck9", Name = "Lucky Charm", Q = 4, R = -1, Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck", Icon = "rbxassetid://126126306847172"},
		{Id = "R_Luck10", Name = "Shining Clover", Q = 5, R = -2, Effect = {"LuckMult", 0.1, "Mul"}, Text = "x1.1 luck", Icon = "rbxassetid://136971141646296"},
		{Id = "R_Luck11", Name = "Emerald Luck", Q = 5, R = -3, Effect = {"LuckMult", 0.15, "Mul"}, Text = "x1.15 luck", Icon = "rbxassetid://90693813824115"},
		{Id = "R_Luck12", Name = "Glowing Clover", Q = 6, R = -3, Effect = {"LuckMult", 0.15, "Mul"}, Text = "x1.15 luck", Icon = "rbxassetid://93889434381128"},
		{Id = "R_Luck13", Name = "Clover Treasure", Q = 6, R = -2, Effect = {"LuckMult", 0.15, "Mul"}, Text = "x1.15 luck", Icon = "rbxassetid://88867850851423"},
		{Id = "R_Luck14", Name = "Golden Horseshoe", Q = 7, R = -3, Effect = {"LuckMult", 0.15, "Mul"}, Text = "x1.15 luck", Icon = "rbxassetid://130100089903162"},
		{Id = "R_Luck15", Name = "Radiant Clover", Q = 7, R = -4, Effect = {"LuckMult", 0.15, "Mul"}, Text = "x1.15 luck", Icon = "rbxassetid://109104895950200"},
		{Id = "R_Luck16", Name = "Ruby Clover", Q = 8, R = -4, Effect = {"LuckMult", 0.25, "Mul"}, Text = "x1.25 luck", Icon = "rbxassetid://107650237435847"},
		{Id = "R_Luck17", Name = "Crimson Luck", Q = 8, R = -3, Effect = {"LuckMult", 0.25, "Mul"}, Text = "x1.25 luck", Icon = "rbxassetid://107165717932897"},
		{Id = "R_Luck18", Name = "Fortune Coin", Q = 9, R = -4, Effect = {"LuckMult", 0.25, "Mul"}, Text = "x1.25 luck", Icon = "rbxassetid://124687350359002"},
		{Id = "R_Luck19", Name = "Blazing Luck", Q = 9, R = -5, Effect = {"LuckMult", 0.25, "Mul"}, Text = "x1.25 luck", Icon = "rbxassetid://92923836695787"},
		{Id = "R_Luck20", Name = "Legendary Luck", Q = 10, R = -5, Effect = {"LuckMult", 1, "Mul"}, Text = "x2 luck", Icon = "rbxassetid://111610549461352", CostMult = 5},
		{Id = "R_Dice1", Name = "Quick Roll", Q = -1, R = 0, Effect = {"RollAnimScale", -0.1}, Text = "-10% roll time", Icon = "rbxassetid://102874154480737"},
		{Id = "R_Dice2", Name = "Quicker Roll", Q = -2, R = 0, Effect = {"RollAnimScale", -0.1}, Text = "-10% roll time", Icon = "rbxassetid://106145240377808"},
		{Id = "R_Dice3", Name = "Speedy Dice", Q = -3, R = 1, Effect = {"RollAnimScale", -0.1}, Text = "-10% roll time", Icon = "rbxassetid://75892482060074"},
		{Id = "R_Dice4", Name = "Double Roll", Q = -2, R = 1, Effect = {"DoubleRollChance", 0.1}, Text = "10% bonus roll", Icon = "rbxassetid://136937260810509"},
		{Id = "R_Dice5", Name = "Lucky Doubles", Q = -3, R = 2, Effect = {"DoubleRollChance", 0.15}, Text = "+15% bonus roll", Icon = "rbxassetid://93129986364028", CostMult = 4},
	}},
	{Id = "Misc", Name = "MISC", Color = Color3.fromRGB(130, 225, 120), Nodes = {
		{Id = "M_Center", Name = "Misc Start", Q = 0, R = 0, Text = "+1 walk speed", RequiredStage = "Starter", Cost = 38, Center = true, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://113047023211112"},
		{Id = "M_Walk1", Name = "Walk Speed", Q = 1, R = 0, Text = "+2 walk speed", RequiredStage = "Starter", Cost = 143, Effect = {"WalkSpeed", 2}, Icon = "rbxassetid://114695132674308"},
		{Id = "M_Walk2", Name = "Fast Feet", Q = 2, R = 0, Text = "+2 walk speed", RequiredStage = "Desert", Cost = 8000, Effect = {"WalkSpeed", 2}, Icon = "rbxassetid://113848289406776"},
		{Id = "M_Sprint", Name = "Sprinter", Q = 3, R = -1, Text = "+3 walk speed", RequiredStage = "Cursed", Cost = 150000, Effect = {"WalkSpeed", 3}, Icon = "rbxassetid://132498630260521"},
		{Id = "M_Friend1", Name = "Friend Boost", Q = 0, R = -1, Text = "+5% snow & luck per friend here", RequiredStage = "Starter", Cost = 98, Effect = {"FriendBoost", 0.05}, Icon = "rbxassetid://131355488400635"},
		{Id = "M_Friend2", Name = "Best Friends", Q = 0, R = -2, Text = "+5% per friend here", RequiredStage = "Desert", Cost = 8000, Effect = {"FriendBoost", 0.05}, Icon = "rbxassetid://102947421379601"},
		{Id = "M_Squad", Name = "Squad Goals", Q = 1, R = -3, Text = "+5% per friend here", RequiredStage = "Cursed", Cost = 150000, Effect = {"FriendBoost", 0.05}, Icon = "rbxassetid://126438571587621"},
		{Id = "M_Egg1", Name = "Egg Discount", Q = -1, R = 1, Text = "-5% egg price", RequiredStage = "Starter", Cost = 120, Effect = {"EggDiscount", 0.05}, Icon = "rbxassetid://118146985927338"},
		{Id = "M_Egg2", Name = "Egg Deals", Q = -2, R = 1, Text = "-5% egg price", RequiredStage = "Desert", Cost = 6500, Effect = {"EggDiscount", 0.05}, Icon = "rbxassetid://88430606212732"},
		{Id = "M_Egg3", Name = "Egg Sale", Q = -2, R = 2, Text = "-10% egg price", RequiredStage = "Desert", Cost = 5000, Effect = {"EggDiscount", 0.1}, Icon = "rbxassetid://134519000870363"},
		{Id = "M_Egg4", Name = "Egg Bargain", Q = -3, R = 2, Text = "-10% egg price", RequiredStage = "Cursed", Cost = 285000, Effect = {"EggDiscount", 0.1}, Icon = "rbxassetid://126600758916916"},
		{Id = "M_Pet1", Name = "Pet Care", Q = 0, R = 1, Text = "+1 walk speed", RequiredStage = "Starter", Cost = 98, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://133360929439713"},
		{Id = "M_Equip1", Name = "+1 Pet Equip", Q = 0, R = 2, Text = "Equip 1 more pet", RequiredStage = "Crystal", Cost = 33600000, Effect = {"PetSlots", 1}, Icon = "rbxassetid://80699553071835"},
		{Id = "M_Equip2", Name = "+1 Pet Equip", Q = 1, R = 2, Text = "Equip 1 more pet", RequiredStage = "Retro", Cost = 1170000000, Effect = {"PetSlots", 1}, Icon = "rbxassetid://85255303008088"},
		{Id = "M_Expansion1", Name = "Pet Treats", Q = 1, R = -1, Text = "+10% pet snow bonuses", RequiredStage = "Desert", Cost = 4000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://109909993977311"},
		{Id = "M_Expansion2", Name = "Warm Boots", Q = -1, R = 0, Text = "+1 walk speed", RequiredStage = "Desert", Cost = 5750, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://105647738212501"},
		{Id = "M_Expansion3", Name = "Egg Coupons", Q = 1, R = -2, Text = "+2.5% egg price", RequiredStage = "Desert", Cost = 7500, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://104972298203092"},
		{Id = "M_Expansion4", Name = "Pet Training", Q = 2, R = -2, Text = "+10% pet snow bonuses", RequiredStage = "Desert", Cost = 9250, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://79029305509084"},
		{Id = "M_Expansion5", Name = "Sandy Steps", Q = -1, R = -1, Text = "+1 walk speed", RequiredStage = "Cursed", Cost = 120000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://111530968258890"},
		{Id = "M_Expansion6", Name = "Egg Savings", Q = 2, R = -1, Text = "+2.5% egg price", RequiredStage = "Cursed", Cost = 172500, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://73053118854334"},
		{Id = "M_Expansion7", Name = "Pet Bond", Q = -2, R = 0, Text = "+10% pet snow bonuses", RequiredStage = "Cursed", Cost = 225000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://99622744607605"},
		{Id = "M_Expansion8", Name = "Trail Boots", Q = 1, R = 1, Text = "+1 walk speed", RequiredStage = "Crystal", Cost = 12950000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://95506938773367"},
		{Id = "M_Expansion9", Name = "Team Spirit", Q = -1, R = 2, Text = "+2.5% snow & luck per friend", RequiredStage = "Crystal", Cost = 5600000, Effect = {"FriendBoost", 0.025}, Icon = "rbxassetid://131945738368827"},
		{Id = "M_Expansion10", Name = "Gem Treats", Q = 0, R = -3, Text = "+10% pet snow bonuses", RequiredStage = "Crystal", Cost = 8050000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://129125768535975"},
		{Id = "M_Expansion11", Name = "Crystal Steps", Q = 2, R = -3, Text = "+1 walk speed", RequiredStage = "Crystal", Cost = 10500000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://105092601357868"},
		{Id = "M_Expansion12", Name = "Egg Vouchers", Q = 3, R = -3, Text = "+2.5% egg price", RequiredStage = "Retro", Cost = 555000000, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://128017941266641"},
		{Id = "M_Expansion13", Name = "Pixel Treats", Q = -1, R = -2, Text = "+10% pet snow bonuses", RequiredStage = "Retro", Cost = 240000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://117492538200985"},
		{Id = "M_Expansion14", Name = "Retro Steps", Q = 3, R = -2, Text = "+1 walk speed", RequiredStage = "Retro", Cost = 345000000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://109419778031012"},
		{Id = "M_Expansion15", Name = "Egg Club", Q = -2, R = -1, Text = "+2.5% egg price", RequiredStage = "Jungle", Cost = 24000000000, Effect = {"EggDiscount", 0.025}, Icon = "rbxassetid://110152835076568"},
		{Id = "M_Expansion16", Name = "Jungle Treats", Q = -3, R = 0, Text = "+10% pet snow bonuses", RequiredStage = "Jungle", Cost = 29600000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://84028465501957"},
		{Id = "M_Expansion17", Name = "Explorer Boots", Q = 3, R = 0, Text = "+1 walk speed", RequiredStage = "Jungle", Cost = 12800000000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://139306879688755"},
		{Id = "M_Expansion18", Name = "Teamwork", Q = -3, R = 1, Text = "+2.5% snow & luck per friend", RequiredStage = "Jungle", Cost = 18400000000, Effect = {"FriendBoost", 0.025}, Icon = "rbxassetid://88055533648249"},
		{Id = "M_Expansion19", Name = "Frost Treats", Q = 2, R = 1, Text = "+10% pet snow bonuses", RequiredStage = "AbsoluteZero", Cost = 900000000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://127461719739257"},
		{Id = "M_Expansion20", Name = "Arctic Boots", Q = -3, R = 3, Text = "+1 walk speed", RequiredStage = "AbsoluteZero", Cost = 1110000000000, Effect = {"WalkSpeed", 1}, Icon = "rbxassetid://116542572902797"},
		{Id = "M_Expansion21", Name = "Pet Mastery", Q = -2, R = 3, Text = "+10% pet snow bonuses", RequiredStage = "AbsoluteZero", Cost = 480000000000, Effect = {"PetBoostMult", 0.1}, Icon = "rbxassetid://79870618462425"},
	}},
}
U.Base = {SizeMult = 1, SpinMult = 1, WalkSpeed = 16, ShovelSlots = 2, PetSlots = 3, PowerBonus = 0, EggDiscount = 0, LuckMult = 1, FriendBoost = 0, RollAnimScale = 1, ReachMult = 1, DoubleRollChance = 0, SnowMult = 1, PowerMult = 1, PetBoostMult = 1}
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
