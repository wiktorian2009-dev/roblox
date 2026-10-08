-- 2026-10-02 balance pass v2 (Claude): fast start, slower late game. With events/quests/daily/achievements World 1 takes ~4 h for an efficient engaged player, ~5 h casual (model). Older copies: ServerStorage.BalanceBackups
-- PET CONFIG: eggs, their 5 pets, odds (%), rarity, snow boost and look.
-- 2026-10-05 (Claude, snowplow expansion): egg prices follow the re-measured stage costs (same ratio to their stage as before); pets, odds and
-- boosts unchanged. All 70 pets have new Blender models in ReplicatedStorage.PetModelOverrides (Golden variants are recoloured at runtime).
-- 2026-10-01: Retro, Jungle and Absolute Zero eggs added (all 7 lobby eggs hatchable).
-- Boost 0.05 = +5% snow. Equipped pets' boosts add together.
-- Look is used to build a low-poly pet. To use your OWN model instead, put a Model with the
-- pet's exact name into ReplicatedStorage > PetModelOverrides.
local PetConfig = {}

PetConfig.MaxEquipped = 3

PetConfig.Rarities = {
	Common    = Color3.fromRGB(170, 180, 195),
	Uncommon  = Color3.fromRGB(90, 220, 110),
	Rare      = Color3.fromRGB(80, 150, 255),
	Epic      = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
}

local function c(r, g, b) return Color3.fromRGB(r, g, b) end

PetConfig.Eggs = {
	{Id = "SnowyEgg", Name = "Snowy Egg", Cost = 450, RequiredStage = "Starter", Pets = {
		{Name = "Snow Bunny",  Chance = 45, Rarity = "Common",    Boost = 0.05, Look = {Body = c(245, 248, 255), Ears = "long", Extras = {"tail"}}},
		{Name = "Penguin",     Chance = 30, Rarity = "Common",    Boost = 0.08, Look = {Body = c(40, 45, 60), Belly = c(250, 250, 250), Accent = c(255, 170, 40), Ears = "none", Extras = {"beak", "flippers"}}},
		{Name = "Arctic Fox",  Chance = 15, Rarity = "Uncommon",  Boost = 0.12, Look = {Body = c(235, 242, 252), Belly = c(255, 255, 255), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Polar Bear",  Chance = 8,  Rarity = "Rare",      Boost = 0.20, Look = {Body = c(250, 250, 245), Ears = "round", Size = 1.25, Extras = {"snout"}}},
		{Name = "Yeti",        Chance = 2,  Rarity = "Legendary", Boost = 0.40, Look = {Body = c(215, 235, 255), Belly = c(120, 170, 230), Ears = "none", Size = 1.35, Extras = {"horns", "glow"}, Glow = c(150, 220, 255)}},
	}},
	{Id = "DesertEgg", Name = "Desert Egg", Cost = 3000, RequiredStage = "Desert", Pets = {
		{Name = "Fennec Fox",  Chance = 45, Rarity = "Common",    Boost = 0.10, Look = {Body = c(235, 190, 130), Belly = c(255, 240, 215), Ears = "huge", Extras = {"bigtail"}}},
		{Name = "Camel",       Chance = 30, Rarity = "Common",    Boost = 0.15, Look = {Body = c(205, 160, 100), Ears = "round", Extras = {"hump", "snout"}}},
		{Name = "Sand Lizard", Chance = 15, Rarity = "Uncommon",  Boost = 0.22, Look = {Body = c(215, 175, 80), Belly = c(245, 225, 160), Ears = "none", Extras = {"longtail", "spikes"}, SpikeColor = c(180, 120, 50)}},
		{Name = "Scarab",      Chance = 8,  Rarity = "Rare",      Boost = 0.35, Look = {Body = c(40, 150, 140), Belly = c(255, 200, 60), Ears = "none", Material = "Metal", Extras = {"horns", "wings"}, Accent = c(255, 200, 60)}},
		{Name = "Sphinx Cat",  Chance = 2,  Rarity = "Legendary", Boost = 0.70, Look = {Body = c(240, 200, 120), Belly = c(255, 235, 180), Ears = "pointy", Extras = {"crown", "glow"}, Accent = c(40, 90, 200), Glow = c(255, 210, 90)}},
	}},
	{Id = "CrystalEgg", Name = "Crystal Egg", Cost = 830000000, RequiredStage = "Crystal", Pets = {
		{Name = "Gem Slime",      Chance = 45, Rarity = "Common",    Boost = 0.30, Look = {Body = c(110, 210, 255), Ears = "none", Material = "Glass", Transparency = 0.2, NoFeet = true, Extras = {"gem"}}},
		{Name = "Crystal Bunny",  Chance = 30, Rarity = "Common",    Boost = 0.42, Look = {Body = c(200, 235, 255), Ears = "long", Extras = {"spikes"}, SpikeColor = c(90, 200, 255)}},
		{Name = "Prism Bird",     Chance = 15, Rarity = "Uncommon",  Boost = 0.95, Look = {Body = c(150, 200, 255), Belly = c(255, 255, 255), Accent = c(255, 180, 230), Ears = "none", Extras = {"beak", "wings"}}},
		{Name = "Crystal Golem",  Chance = 8,  Rarity = "Rare",      Boost = 0.60, Look = {Body = c(70, 90, 130), Belly = c(90, 200, 255), Ears = "none", Size = 1.3, Extras = {"spikes", "glow"}, SpikeColor = c(80, 220, 255), Glow = c(80, 220, 255)}},
		{Name = "Diamond Dragon", Chance = 2,  Rarity = "Legendary", Boost = 1.80, Look = {Body = c(170, 240, 255), Belly = c(255, 255, 255), Ears = "none", Material = "Glass", Size = 1.35, Extras = {"horns", "wings", "longtail", "glow"}, Accent = c(90, 210, 255), Glow = c(120, 230, 255)}},
	}},
	{Id = "CursedEgg", Name = "Cursed Egg", Cost = 470000, RequiredStage = "Cursed", Pets = {
		{Name = "Shadow Bat",  Chance = 45, Rarity = "Common",    Boost = 0.18, Look = {Body = c(55, 45, 75), Eyes = c(255, 60, 90), Ears = "pointy", NoFeet = true, Extras = {"wings"}}},
		{Name = "Ghost",       Chance = 30, Rarity = "Common",    Boost = 0.25, Look = {Body = c(235, 225, 255), Transparency = 0.3, Eyes = c(40, 20, 60), Ears = "none", NoFeet = true, Extras = {"wisp"}}},
		{Name = "Imp",         Chance = 15, Rarity = "Uncommon",  Boost = 0.38, Look = {Body = c(170, 60, 90), Belly = c(230, 120, 140), Ears = "pointy", Extras = {"horns", "longtail"}, Accent = c(40, 20, 30)}},
		{Name = "Shadow Wolf", Chance = 8,  Rarity = "Rare",      Boost = 0.60, Look = {Body = c(45, 35, 60), Belly = c(90, 60, 120), Eyes = c(200, 80, 255), Ears = "pointy", Size = 1.25, Extras = {"bigtail", "snout", "glow"}, Glow = c(170, 70, 255)}},
		{Name = "Void Demon",  Chance = 2,  Rarity = "Legendary", Boost = 1.20, Look = {Body = c(30, 20, 45), Belly = c(120, 40, 200), Eyes = c(255, 90, 255), Ears = "none", Size = 1.4, Extras = {"horns", "wings", "halo", "glow"}, Accent = c(190, 70, 255), Glow = c(190, 70, 255)}},
	}},
	{Id = "RetroEgg", Name = "Retro Egg", Cost = 310000000000, RequiredStage = "Retro", Pets = { -- rebalance 2026-10-05: was 420000000000
		{Name = "Pixel Cat",     Chance = 45, Rarity = "Common",    Boost = 0.50, Look = {Body = c(255, 125, 200), Belly = c(255, 225, 240), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Arcade Bot",    Chance = 30, Rarity = "Common",    Boost = 0.70, Look = {Body = c(125, 135, 160), Belly = c(80, 230, 255), Eyes = c(80, 255, 160), Ears = "none", Extras = {"horns", "gem"}}},
		{Name = "Neon Frog",     Chance = 15, Rarity = "Uncommon",  Boost = 1.00, Look = {Body = c(90, 235, 110), Belly = c(230, 255, 170), Ears = "none", Extras = {"glow"}, Glow = c(120, 255, 140)}},
		{Name = "Synth Fox",     Chance = 8,  Rarity = "Rare",      Boost = 1.60, Look = {Body = c(70, 215, 255), Belly = c(255, 90, 205), Ears = "pointy", Extras = {"bigtail", "glow"}, Glow = c(70, 215, 255)}},
		{Name = "Glitch Dragon", Chance = 2,  Rarity = "Legendary", Boost = 3.00, Look = {Body = c(150, 70, 255), Belly = c(70, 255, 230), Accent = c(255, 90, 205), Ears = "none", Size = 1.35, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(200, 100, 255)}},
	}},
	{Id = "JungleEgg", Name = "Jungle Egg", Cost = 4200000000000, RequiredStage = "Jungle", Pets = { -- rebalance 2026-10-05: was 2800000000000
		{Name = "Tree Frog",     Chance = 45, Rarity = "Common",    Boost = 0.80, Look = {Body = c(85, 210, 95), Belly = c(255, 205, 80), Eyes = c(200, 40, 40), Ears = "none"}},
		{Name = "Monkey",        Chance = 30, Rarity = "Common",    Boost = 1.10, Look = {Body = c(150, 95, 55), Belly = c(235, 195, 150), Ears = "round", Extras = {"longtail", "snout"}}},
		{Name = "Toucan",        Chance = 15, Rarity = "Uncommon",  Boost = 1.60, Look = {Body = c(35, 35, 45), Belly = c(255, 240, 220), Accent = c(255, 150, 30), Ears = "none", Extras = {"beak", "wings"}}},
		{Name = "Jaguar",        Chance = 8,  Rarity = "Rare",      Boost = 2.60, Look = {Body = c(240, 180, 60), Belly = c(255, 235, 190), Ears = "round", Size = 1.2, Extras = {"longtail", "snout"}}},
		{Name = "Tiki Guardian", Chance = 2,  Rarity = "Legendary", Boost = 5.00, Look = {Body = c(130, 85, 50), Belly = c(90, 205, 120), Accent = c(255, 200, 60), Ears = "none", Size = 1.35, Extras = {"crown", "glow"}, Glow = c(120, 255, 150)}},
	}},
	{Id = "AbsoluteZeroEgg", Name = "Absolute Zero Egg", Cost = 29000000000000, RequiredStage = "AbsoluteZero", Pets = { -- rebalance 2026-10-05: was 20000000000000
		{Name = "Frost Sprite",     Chance = 45, Rarity = "Common",    Boost = 1.30, Look = {Body = c(175, 232, 255), Transparency = 0.2, Ears = "none", NoFeet = true, Extras = {"wisp", "wings"}}},
		{Name = "Ice Seal",         Chance = 30, Rarity = "Common",    Boost = 1.80, Look = {Body = c(205, 225, 245), Belly = c(250, 252, 255), Ears = "none", Extras = {"flippers", "snout"}}},
		{Name = "Snow Owl",         Chance = 15, Rarity = "Uncommon",  Boost = 2.60, Look = {Body = c(245, 248, 255), Belly = c(210, 230, 250), Accent = c(255, 190, 60), Ears = "pointy", Extras = {"beak", "wings"}}},
		{Name = "Glacier Mammoth",  Chance = 8,  Rarity = "Rare",      Boost = 4.20, Look = {Body = c(140, 180, 220), Belly = c(220, 240, 255), Ears = "round", Size = 1.35, Extras = {"horns", "snout"}}},
		{Name = "Absolute Phoenix", Chance = 2,  Rarity = "Legendary", Boost = 8.00, Look = {Body = c(120, 220, 255), Belly = c(255, 255, 255), Accent = c(200, 150, 255), Ears = "none", Size = 1.35, Extras = {"wings", "longtail", "halo", "glow"}, Glow = c(140, 230, 255)}},
	}},
	-- WORLD 2 (2026-10-02, Claude). Models: Blender pets in ReplicatedStorage.PetModelOverrides (Look = fallback only).
	-- 2026-10-03: egg = 10% of its stage price (Sakura: of Portal); pet boosts x1.45 per World 2 egg (progression model, work/world2-balance).
	{Id = "BlossomEgg", Name = "Blossom Egg", Cost = 78000000000000, RequiredStage = "Sakura", Pets = { -- rebalance 2026-10-05: was 60000000000000
		{Name = "Koi",            Chance = 45, Rarity = "Common",    Boost = 2.00,  Look = {Body = c(255, 246, 238), Belly = c(255, 122, 46), Ears = "none", NoFeet = true}},
		{Name = "Blossom Bunny",  Chance = 30, Rarity = "Common",    Boost = 2.70,  Look = {Body = c(255, 247, 250), Ears = "long", Extras = {"tail"}}},
		{Name = "Red Panda",      Chance = 15, Rarity = "Uncommon",  Boost = 3.90,  Look = {Body = c(217, 87, 43), Belly = c(255, 241, 224), Ears = "round", Extras = {"bigtail"}}},
		{Name = "Crane",          Chance = 8,  Rarity = "Rare",      Boost = 6.30,  Look = {Body = c(255, 255, 255), Accent = c(232, 56, 61), Ears = "none", Extras = {"beak", "wings"}}},
		{Name = "Blossom Dragon", Chance = 2,  Rarity = "Legendary", Boost = 12.00, Look = {Body = c(255, 159, 201), Belly = c(255, 233, 214), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 217, 240)}},
	}},
	{Id = "CandyEgg", Name = "Candy Egg", Cost = 6800000000000000, RequiredStage = "Candy", Pets = { -- rebalance 2026-10-05: was 3700000000000000
		{Name = "Gummy Bear",        Chance = 45, Rarity = "Common",    Boost = 2.90,  Look = {Body = c(255, 77, 109), Ears = "round", Transparency = 0.1}},
		{Name = "Marshmallow Bunny", Chance = 30, Rarity = "Common",    Boost = 3.90,  Look = {Body = c(255, 248, 244), Ears = "long", Extras = {"tail"}}},
		{Name = "Cupcake Cat",       Chance = 15, Rarity = "Uncommon",  Boost = 5.70,  Look = {Body = c(255, 179, 209), Belly = c(143, 232, 200), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Candy Fox",         Chance = 8,  Rarity = "Rare",      Boost = 9.10,  Look = {Body = c(255, 169, 77), Belly = c(255, 243, 220), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Sugar Dragon",      Chance = 2,  Rarity = "Legendary", Boost = 17.40, Look = {Body = c(143, 232, 200), Belly = c(255, 243, 220), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 156, 203)}},
	}},
	{Id = "PearlEgg", Name = "Pearl Egg", Cost = 43000000000000000, RequiredStage = "Atlantis", Pets = { -- rebalance 2026-10-05: was 23000000000000000
		{Name = "Crab",                Chance = 45, Rarity = "Common",    Boost = 4.20,  Look = {Body = c(255, 111, 76), Ears = "none", Extras = {"snout"}}},
		{Name = "Seahorse",            Chance = 30, Rarity = "Common",    Boost = 5.70,  Look = {Body = c(255, 201, 74), Ears = "none", NoFeet = true, Extras = {"longtail"}}},
		{Name = "Turtle",              Chance = 15, Rarity = "Uncommon",  Boost = 8.20,  Look = {Body = c(126, 211, 106), Belly = c(255, 240, 200), Ears = "none", Extras = {"flippers"}}},
		{Name = "Manta Ray",           Chance = 8,  Rarity = "Rare",      Boost = 13.20, Look = {Body = c(23, 96, 122), Belly = c(255, 248, 238), Ears = "none", NoFeet = true, Extras = {"wings", "longtail"}}},
		{Name = "Ancient Sea Serpent", Chance = 2,  Rarity = "Legendary", Boost = 25.20, Look = {Body = c(47, 196, 178), Belly = c(255, 240, 200), Ears = "none", Size = 1.3, Extras = {"crown", "longtail", "glow"}, Glow = c(233, 255, 255)}},
	}},
	{Id = "ToyCapsuleEgg", Name = "Toy Capsule Egg", Cost = 130000000000000000, RequiredStage = "Toybox", Pets = { -- rebalance 2026-10-05: was 67000000000000000
		{Name = "Teddy Bear",     Chance = 45, Rarity = "Common",    Boost = 6.10,  Look = {Body = c(181, 118, 63), Belly = c(232, 195, 154), Ears = "round"}},
		{Name = "Toy Duck",       Chance = 30, Rarity = "Common",    Boost = 8.20,  Look = {Body = c(255, 210, 63), Ears = "none", Extras = {"snout"}}},
		{Name = "Wind-up Mouse",  Chance = 15, Rarity = "Uncommon",  Boost = 11.90, Look = {Body = c(199, 203, 214), Ears = "round", Extras = {"tail"}}},
		{Name = "Toy Robot",      Chance = 8,  Rarity = "Rare",      Boost = 19.20, Look = {Body = c(184, 194, 214), Ears = "none", Material = "Metal", Extras = {"glow"}, Glow = c(127, 233, 255)}},
		{Name = "Plush Dinosaur", Chance = 2,  Rarity = "Legendary", Boost = 36.60, Look = {Body = c(111, 210, 122), Belly = c(207, 245, 192), Ears = "none", Size = 1.3, Extras = {"longtail", "glow"}, Glow = c(255, 242, 168)}},
	}},
	{Id = "GearEgg", Name = "Gear Egg", Cost = 600000000000000000, RequiredStage = "Clockwork", Pets = { -- rebalance 2026-10-05: was 310000000000000000
		{Name = "Brass Beetle",     Chance = 45, Rarity = "Common",    Boost = 8.90,  Look = {Body = c(224, 176, 74), Ears = "none", Material = "Metal"}},
		{Name = "Clockwork Bird",   Chance = 30, Rarity = "Common",    Boost = 11.90, Look = {Body = c(63, 191, 180), Belly = c(246, 231, 200), Ears = "none", Extras = {"wings"}}},
		{Name = "Steam Pup",        Chance = 15, Rarity = "Uncommon",  Boost = 17.30, Look = {Body = c(208, 122, 72), Belly = c(246, 231, 200), Ears = "round", Extras = {"tail"}}},
		{Name = "Gear Fox",         Chance = 8,  Rarity = "Rare",      Boost = 27.80, Look = {Body = c(255, 138, 61), Belly = c(246, 231, 200), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Clockwork Dragon", Chance = 2,  Rarity = "Legendary", Boost = 53.10, Look = {Body = c(63, 191, 180), Belly = c(246, 231, 200), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 226, 160)}},
	}},
	{Id = "CloudEgg", Name = "Cloud Egg", Cost = 5600000000000000000, RequiredStage = "Cloud", Pets = { -- rebalance 2026-10-05: was 2900000000000000000
		{Name = "Cloud Lamb",      Chance = 45, Rarity = "Common",    Boost = 12.90, Look = {Body = c(247, 249, 255), Ears = "round"}},
		{Name = "Cloud Kitten",    Chance = 30, Rarity = "Common",    Boost = 17.30, Look = {Body = c(207, 228, 255), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Thunder Owl",     Chance = 15, Rarity = "Uncommon",  Boost = 25.10, Look = {Body = c(111, 127, 208), Belly = c(217, 222, 255), Ears = "pointy", Extras = {"wings"}}},
		{Name = "Rainbow Pegasus", Chance = 8,  Rarity = "Rare",      Boost = 40.30, Look = {Body = c(247, 249, 255), Ears = "pointy", Extras = {"wings", "tail"}}},
		{Name = "Sky Whale",       Chance = 2,  Rarity = "Legendary", Boost = 77.00, Look = {Body = c(143, 208, 255), Belly = c(247, 249, 255), Ears = "none", Size = 1.3, NoFeet = true, Extras = {"longtail", "glow"}, Glow = c(255, 242, 168)}},
	}},
	{Id = "StarEgg", Name = "Star Egg", Cost = 52000000000000000000, RequiredStage = "Cosmic", Pets = { -- rebalance 2026-10-05: was 26000000000000000000
		{Name = "Comet Pup",     Chance = 45, Rarity = "Common",    Boost = 18.70,  Look = {Body = c(169, 216, 255), Ears = "round", Extras = {"tail"}}},
		{Name = "Moon Bunny",    Chance = 30, Rarity = "Common",    Boost = 25.10,  Look = {Body = c(241, 236, 255), Ears = "long", Extras = {"tail"}}},
		{Name = "Astro Cat",     Chance = 15, Rarity = "Uncommon",  Boost = 36.40,  Look = {Body = c(255, 174, 92), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Nebula Fox",    Chance = 8,  Rarity = "Rare",      Boost = 58.40,  Look = {Body = c(199, 125, 255), Belly = c(243, 230, 255), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Galaxy Dragon", Chance = 2,  Rarity = "Legendary", Boost = 111.70, Look = {Body = c(60, 46, 143), Belly = c(185, 166, 255), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 246, 200)}},
	}},
}

PetConfig.PetByName, PetConfig.EggById = {}, {}
for _, egg in ipairs(PetConfig.Eggs) do
	PetConfig.EggById[egg.Id] = egg
	for _, pet in ipairs(egg.Pets) do
		pet.Egg = egg.Id
		PetConfig.PetByName[pet.Name] = pet
	end
end
-- 2026-10-03 (Claude): Golden pets, made in the Pet Lodge's Pet Fuser (3 of the same pet -> 1 Golden pet with GoldenMult x boost).
-- They are not in any egg (not hatchable) and are never added to the pet index; everything else treats them as normal pets.
PetConfig.GoldenMult = 2
PetConfig.GoldenOf = {}
do
	local base = {}
	for _, pet in pairs(PetConfig.PetByName) do table.insert(base, pet) end
	for _, pet in ipairs(base) do
		local g = table.clone(pet)
		g.Name = "Golden " .. pet.Name
		g.Boost = pet.Boost * PetConfig.GoldenMult
		g.Golden, g.Base, g.Chance = true, pet.Name, 0
		local look = table.clone(pet.Look or {})
		look.Body, look.Belly, look.Transparency = c(255, 200, 55), c(255, 236, 160), nil
		local extras = table.clone(look.Extras or {})
		if not table.find(extras, "glow") then table.insert(extras, "glow") end
		if not table.find(extras, "crown") then table.insert(extras, "crown") end
		look.Extras, look.Glow = extras, c(255, 225, 120)
		g.Look = look
		PetConfig.PetByName[g.Name] = g
		PetConfig.GoldenOf[pet.Name] = g.Name
	end
end

-- total snow multiplier for a list of equipped pet names
function PetConfig.Multiplier(names)
	local m = 1
	for _, n in ipairs(names) do
		local p = PetConfig.PetByName[n]
		if p then m += p.Boost end
	end
	return m
end

return PetConfig

