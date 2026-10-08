--[[ RNG CONFIG — the only place you need to edit to add shovels.
	Chance  = the "1 in N" odds (bigger = rarer)          (PLACEHOLDERS for now)
	Rarity  = key into Config.Rarities (card/tint color)  (PLACEHOLDERS for now)
	Power   = (optional) damage per hit; if missing it comes from Balance.ShovelPower(Chance)
	ImageId = "rbxassetid://..." IMAGE id (not decal id) used in the reel, index and inventory
	3D model = a Model with the same name in ReplicatedStorage > ShovelModels (falls back to a placeholder model)
]]
local Config = {}

Config.Rarities = {
	Common    = Color3.fromRGB(120, 200, 255),
	Uncommon  = Color3.fromRGB(90, 220, 110),
	Rare      = Color3.fromRGB(80, 140, 255),
	Epic      = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
	Mythic    = Color3.fromRGB(255, 70, 110),
	Secret    = Color3.fromRGB(90, 255, 230),
	Divine    = Color3.fromRGB(255, 245, 180),
}

Config.Items = {
	{Name = "Tin Shovel", Chance = 2, Rarity = "Common", ImageId = "rbxassetid://129348119192878"},  -- 01
	{Name = "Copper Shovel", Chance = 4, Rarity = "Common", ImageId = "rbxassetid://77260407017647"},  -- 02
	{Name = "Bronze Shovel", Chance = 9, Rarity = "Common", ImageId = "rbxassetid://112641858495685"},  -- 03
	{Name = "Aluminum Shovel", Chance = 18, Rarity = "Common", ImageId = "rbxassetid://131071755840348"},  -- 04
	{Name = "Zinc Shovel", Chance = 36, Rarity = "Common", ImageId = "rbxassetid://127071208521688"},  -- 05
	{Name = "Nickel Shovel", Chance = 75, Rarity = "Common", ImageId = "rbxassetid://110094280546737"},  -- 06
	{Name = "Reinforced Shovel", Chance = 150, Rarity = "Uncommon", ImageId = "rbxassetid://132509596756991"},  -- 07
	{Name = "Heavy Shovel", Chance = 320, Rarity = "Uncommon", ImageId = "rbxassetid://108717373819770"},  -- 08
	{Name = "Broad Shovel", Chance = 660, Rarity = "Uncommon", ImageId = "rbxassetid://85267447049351"},  -- 09
	{Name = "Pointed Shovel", Chance = 1400, Rarity = "Rare", ImageId = "rbxassetid://120165898169481"},  -- 10
	{Name = "Trench Shovel", Chance = 2800, Rarity = "Rare", ImageId = "rbxassetid://109224909595074"},  -- 11
	{Name = "Square Shovel", Chance = 5800, Rarity = "Rare", ImageId = "rbxassetid://84626812814297"},  -- 12
	{Name = "Serrated Shovel", Chance = 12000, Rarity = "Epic", ImageId = "rbxassetid://83400945121643"},  -- 13
	{Name = "Double Edge Shovel", Chance = 25000, Rarity = "Epic", ImageId = "rbxassetid://122955997844089"},  -- 14
	{Name = "Spiked Shovel", Chance = 51000, Rarity = "Epic", ImageId = "rbxassetid://135016559137517"},  -- 15
	{Name = "Military Shovel", Chance = 100000, Rarity = "Legendary", ImageId = "rbxassetid://75489855466446"},  -- 16
	{Name = "Industrial Shovel", Chance = 220000, Rarity = "Legendary", ImageId = "rbxassetid://116815230602003"},  -- 17
	{Name = "Carbon Shovel", Chance = 450000, Rarity = "Legendary", ImageId = "rbxassetid://120858796752685"},  -- 18
	{Name = "Titanium Shovel", Chance = 920000, Rarity = "Legendary", ImageId = "rbxassetid://91147306931350"},  -- 19
	{Name = "Tungsten Shovel", Chance = 1900000, Rarity = "Mythic", ImageId = "rbxassetid://128653101959251"},  -- 20
	{Name = "Gold Shovel", Chance = 3900000, Rarity = "Mythic", ImageId = "rbxassetid://140442562537951"},  -- 21
	{Name = "Diamond Shovel", Chance = 8100000, Rarity = "Mythic", ImageId = "rbxassetid://71680279391489"},  -- 22
	{Name = "Emerald Shovel", Chance = 17000000, Rarity = "Mythic", ImageId = "rbxassetid://136783967374805"},  -- 23
	{Name = "Ruby Shovel", Chance = 35000000, Rarity = "Mythic", ImageId = "rbxassetid://124241177877624"},  -- 24
	{Name = "Sapphire Shovel", Chance = 71000000, Rarity = "Mythic", ImageId = "rbxassetid://134447576845109"},  -- 25
	{Name = "Crystal Shovel", Chance = 150000000, Rarity = "Secret", ImageId = "rbxassetid://107617173564488"},  -- 27
	{Name = "Frozen Shovel", Chance = 300000000, Rarity = "Secret", ImageId = "rbxassetid://79581909815524"},  -- 28
	{Name = "Molten Shovel", Chance = 630000000, Rarity = "Secret", ImageId = "rbxassetid://136130388677749"},  -- 29
	{Name = "Radioactive Shovel", Chance = 1300000000, Rarity = "Secret", ImageId = "rbxassetid://134710681807021"},  -- 30
	{Name = "Cursed Shovel", Chance = 2700000000, Rarity = "Secret", ImageId = "rbxassetid://87256624130519"},  -- 31
	{Name = "Absolute Zero Shovel", Chance = 5500000000, Rarity = "Secret", ImageId = "rbxassetid://126948008400366"},  -- 32
	{Name = "Rainbow Shovel", Chance = 11000000000, Rarity = "Divine", ImageId = "rbxassetid://82948685241352"},  -- 33
	{Name = "Meteor Shovel", Chance = 23000000000, Rarity = "Divine", ImageId = "rbxassetid://114332579144410"},  -- 34
	{Name = "Angelic Shovel", Chance = 48000000000, Rarity = "Divine", ImageId = "rbxassetid://72640465413720"},  -- 35
	{Name = "Void Shovel", Chance = 100000000000, Rarity = "Divine", ImageId = "rbxassetid://127677515277901"},  -- 36
}

Config.MaxEquipped = 2     -- shovels spinning around a player at once
Config.RollCooldown = 0.9  -- seconds, enforced by the server
Config.BigRollAt = 100000    -- items with Chance >= this get the camera punch when rolled

-- rarity tiers in order, and the odds where each tier starts
Config.RarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine"}
Config.RarityMinChance = {Common = 0, Uncommon = 100, Rare = 1000, Epic = 10000, Legendary = 100000, Mythic = 1000000, Secret = 100000000, Divine = 10000000000}

-- RARE DROP CUTSCENE
-- plays when (odds / player's luck) >= Threshold, so it scales with luck.
-- Sounds: paste any Roblox audio id ("rbxassetid://123") to replace these.
Config.RareDrop = {
	Threshold = 1000,
	Sounds = {
		Start  = {Id = "rbxassetid://77820131187937",  Volume = 1.5},  -- screen cuts to black
		Steps  = {                                                   -- one per rarity step of the climb
			Rare      = {Id = "rbxassetid://102456460734361", Volume = 1.5},
			Epic      = {Id = "rbxassetid://112301259896345", Volume = 1.5},
			Legendary = {Id = "rbxassetid://85230589033767",  Volume = 1.5},
			Mythic    = {Id = "rbxassetid://108417005528759", Volume = 1.5},
			Secret    = {Id = "rbxassetid://118553089210873", Volume = 1.5},
			Divine    = {Id = "rbxassetid://118553089210873", Volume = 1.8},
		},
		Reveal = {Id = "rbxassetid://125078105193243", Volume = 1.8},  -- white flash + shovel appears
		End    = {Id = "rbxassetid://126698655007674", Volume = 1.3},  -- cutscene fades out
	},
}

-- lookup helper
Config.ByName = {}
for _, item in ipairs(Config.Items) do Config.ByName[item.Name] = item end

return Config

