-- 2026-10-02 balance pass v2 (Claude): fast start, slower late game. With events/quests/daily/achievements World 1 takes ~4 h for an efficient engaged player, ~5 h casual (model). Older copies: ServerStorage.BalanceBackups
-- PET CONFIG: eggs, their 5 pets, odds (%), rarity, snow boost and look.
-- 2026-10-05 (Claude, snowplow expansion): egg prices follow the re-measured stage costs (same ratio to their stage as before); pets, odds and
-- boosts unchanged. All 70 pets have new Blender models in ReplicatedStorage.PetModelOverrides (Golden variants are recoloured at runtime).
-- 2026-10-01: Retro, Jungle and Absolute Zero eggs added (all 7 lobby eggs hatchable).
-- Boost 0.05 = +5% snow. Equipped pets' boosts add together.
-- Look is used to build a low-poly pet. To use your OWN model instead, put a Model with the
-- pet's exact name into ReplicatedStorage > PetModelOverrides.
-- RESCALE 2026-10-06 (Claude): egg prices follow the new stage gates; pet boosts compressed (b -> ((1+3b)^c-1)/3, c = 0.58)
-- so income grows gently (old values: ServerStorage.EconomyRescaleBackup_20261006).
local PetConfig = {}

PetConfig.MaxEquipped = 3

PetConfig.Rarities = {
	Common    = Color3.fromRGB(170, 180, 195),
	Uncommon  = Color3.fromRGB(90, 220, 110),
	Rare      = Color3.fromRGB(80, 150, 255),
	Epic      = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
	Mythic    = Color3.fromRGB(255, 95, 205), -- 2026-10-06: Rainbow Verity (Verity Egg)
}

local function c(r, g, b) return Color3.fromRGB(r, g, b) end

PetConfig.Eggs = {
	{Id = "SnowyEgg", Name = "Snowy Egg", Cost = 450, RequiredStage = "Starter", Pets = {
		{Name = "Snow Bunny",  Chance = 45, Rarity = "Common",    Boost = 0.0281, Look = {Body = c(245, 248, 255), Ears = "long", Extras = {"tail"}}},
		{Name = "Penguin",     Chance = 30, Rarity = "Common",    Boost = 0.0443, Look = {Body = c(40, 45, 60), Belly = c(250, 250, 250), Accent = c(255, 170, 40), Ears = "none", Extras = {"beak", "flippers"}}},
		{Name = "Arctic Fox",  Chance = 15, Rarity = "Uncommon",  Boost = 0.0651, Look = {Body = c(235, 242, 252), Belly = c(255, 255, 255), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Polar Bear",  Chance = 8,  Rarity = "Rare",      Boost = 0.1045, Look = {Body = c(250, 250, 245), Ears = "round", Size = 1.25, Extras = {"snout"}}},
		{Name = "Yeti",        Chance = 2,  Rarity = "Legendary", Boost = 0.1933, Look = {Body = c(215, 235, 255), Belly = c(120, 170, 230), Ears = "none", Size = 1.35, Extras = {"horns", "glow"}, Glow = c(150, 220, 255)}},
	}},
	{Id = "DesertEgg", Name = "Desert Egg", Cost = 3200, RequiredStage = "Desert", Pets = {
		{Name = "Fennec Fox",  Chance = 45, Rarity = "Common",    Boost = 0.0548, Look = {Body = c(235, 190, 130), Belly = c(255, 240, 215), Ears = "huge", Extras = {"bigtail"}}},
		{Name = "Camel",       Chance = 30, Rarity = "Common",    Boost = 0.0802, Look = {Body = c(205, 160, 100), Ears = "round", Extras = {"hump", "snout"}}},
		{Name = "Sand Lizard", Chance = 15, Rarity = "Uncommon",  Boost = 0.1139, Look = {Body = c(215, 175, 80), Belly = c(245, 225, 160), Ears = "none", Extras = {"longtail", "spikes"}, SpikeColor = c(180, 120, 50)}},
		{Name = "Scarab",      Chance = 8,  Rarity = "Rare",      Boost = 0.1721, Look = {Body = c(40, 150, 140), Belly = c(255, 200, 60), Ears = "none", Material = "Metal", Extras = {"horns", "wings"}, Accent = c(255, 200, 60)}},
		{Name = "Sphinx Cat",  Chance = 2,  Rarity = "Legendary", Boost = 0.3092, Look = {Body = c(240, 200, 120), Belly = c(255, 235, 180), Ears = "pointy", Extras = {"crown", "glow"}, Accent = c(40, 90, 200), Glow = c(255, 210, 90)}},
	}},
	{Id = "CrystalEgg", Name = "Crystal Egg", Cost = 5500000, RequiredStage = "Crystal", Pets = {
		{Name = "Gem Slime",      Chance = 45, Rarity = "Common",    Boost = 0.1503, Look = {Body = c(110, 210, 255), Ears = "none", Material = "Glass", Transparency = 0.2, NoFeet = true, Extras = {"gem"}}},
		{Name = "Crystal Bunny",  Chance = 30, Rarity = "Common",    Boost = 0.2016, Look = {Body = c(200, 235, 255), Ears = "long", Extras = {"spikes"}, SpikeColor = c(90, 200, 255)}},
		{Name = "Prism Bird",     Chance = 15, Rarity = "Uncommon",  Boost = 0.3952, Look = {Body = c(150, 200, 255), Belly = c(255, 255, 255), Accent = c(255, 180, 230), Ears = "none", Extras = {"beak", "wings"}}},
		{Name = "Crystal Golem",  Chance = 8,  Rarity = "Rare",      Boost = 0.2723, Look = {Body = c(70, 90, 130), Belly = c(90, 200, 255), Ears = "none", Size = 1.3, Extras = {"spikes", "glow"}, SpikeColor = c(80, 220, 255), Glow = c(80, 220, 255)}},
		{Name = "Diamond Dragon", Chance = 2,  Rarity = "Legendary", Boost = 0.6449, Look = {Body = c(170, 240, 255), Belly = c(255, 255, 255), Ears = "none", Material = "Glass", Size = 1.35, Extras = {"horns", "wings", "longtail", "glow"}, Accent = c(90, 210, 255), Glow = c(120, 230, 255)}},
	}},
	{Id = "CursedEgg", Name = "Cursed Egg", Cost = 20000, RequiredStage = "Cursed", Pets = {
		{Name = "Shadow Bat",  Chance = 45, Rarity = "Common",    Boost = 0.0949, Look = {Body = c(55, 45, 75), Eyes = c(255, 60, 90), Ears = "pointy", NoFeet = true, Extras = {"wings"}}},
		{Name = "Ghost",       Chance = 30, Rarity = "Common",    Boost = 0.1278, Look = {Body = c(235, 225, 255), Transparency = 0.3, Eyes = c(40, 20, 60), Ears = "none", NoFeet = true, Extras = {"wisp"}}},
		{Name = "Imp",         Chance = 15, Rarity = "Uncommon",  Boost = 0.1849, Look = {Body = c(170, 60, 90), Belly = c(230, 120, 140), Ears = "pointy", Extras = {"horns", "longtail"}, Accent = c(40, 20, 30)}},
		{Name = "Shadow Wolf", Chance = 8,  Rarity = "Rare",      Boost = 0.2723, Look = {Body = c(45, 35, 60), Belly = c(90, 60, 120), Eyes = c(200, 80, 255), Ears = "pointy", Size = 1.25, Extras = {"bigtail", "snout", "glow"}, Glow = c(170, 70, 255)}},
		{Name = "Void Demon",  Chance = 2,  Rarity = "Legendary", Boost = 0.4744, Look = {Body = c(30, 20, 45), Belly = c(120, 40, 200), Eyes = c(255, 90, 255), Ears = "none", Size = 1.4, Extras = {"horns", "wings", "halo", "glow"}, Accent = c(190, 70, 255), Glow = c(190, 70, 255)}},
	}},
	{Id = "RetroEgg", Name = "Retro Egg", Cost = 94000000, RequiredStage = "Retro", Pets = { -- rebalance 2026-10-05: was 420000000000
		{Name = "Pixel Cat",     Chance = 45, Rarity = "Common",    Boost = 0.2338, Look = {Body = c(255, 125, 200), Belly = c(255, 225, 240), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Arcade Bot",    Chance = 30, Rarity = "Common",    Boost = 0.3092, Look = {Body = c(125, 135, 160), Belly = c(80, 230, 255), Eyes = c(80, 255, 160), Ears = "none", Extras = {"horns", "gem"}}},
		{Name = "Neon Frog",     Chance = 15, Rarity = "Uncommon",  Boost = 0.4115, Look = {Body = c(90, 235, 110), Belly = c(230, 255, 170), Ears = "none", Extras = {"glow"}, Glow = c(120, 255, 140)}},
		{Name = "Synth Fox",     Chance = 8,  Rarity = "Rare",      Boost = 0.5907, Look = {Body = c(70, 215, 255), Belly = c(255, 90, 205), Ears = "pointy", Extras = {"bigtail", "glow"}, Glow = c(70, 215, 255)}},
		{Name = "Glitch Dragon", Chance = 2,  Rarity = "Legendary", Boost = 0.934, Look = {Body = c(150, 70, 255), Belly = c(70, 255, 230), Accent = c(255, 90, 205), Ears = "none", Size = 1.35, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(200, 100, 255)}},
	}},
	{Id = "JungleEgg", Name = "Jungle Egg", Cost = 1500000000, RequiredStage = "Jungle", Pets = { -- rebalance 2026-10-05: was 2800000000000
		{Name = "Tree Frog",     Chance = 45, Rarity = "Common",    Boost = 0.3445, Look = {Body = c(85, 210, 95), Belly = c(255, 205, 80), Eyes = c(200, 40, 40), Ears = "none"}},
		{Name = "Monkey",        Chance = 30, Rarity = "Common",    Boost = 0.4434, Look = {Body = c(150, 95, 55), Belly = c(235, 195, 150), Ears = "round", Extras = {"longtail", "snout"}}},
		{Name = "Toucan",        Chance = 15, Rarity = "Uncommon",  Boost = 0.5907, Look = {Body = c(35, 35, 45), Belly = c(255, 240, 220), Accent = c(255, 150, 30), Ears = "none", Extras = {"beak", "wings"}}},
		{Name = "Jaguar",        Chance = 8,  Rarity = "Rare",      Boost = 0.8434, Look = {Body = c(240, 180, 60), Belly = c(255, 235, 190), Ears = "round", Size = 1.2, Extras = {"longtail", "snout"}}},
		{Name = "Tiki Guardian", Chance = 2,  Rarity = "Legendary", Boost = 1.3311, Look = {Body = c(130, 85, 50), Belly = c(90, 205, 120), Accent = c(255, 200, 60), Ears = "none", Size = 1.35, Extras = {"crown", "glow"}, Glow = c(120, 255, 150)}},
	}},
	{Id = "AbsoluteZeroEgg", Name = "Absolute Zero Egg", Cost = 5800000000, RequiredStage = "AbsoluteZero", Pets = { -- rebalance 2026-10-05: was 20000000000000
		{Name = "Frost Sprite",     Chance = 45, Rarity = "Common",    Boost = 0.5046, Look = {Body = c(175, 232, 255), Transparency = 0.2, Ears = "none", NoFeet = true, Extras = {"wisp", "wings"}}},
		{Name = "Ice Seal",         Chance = 30, Rarity = "Common",    Boost = 0.6449, Look = {Body = c(205, 225, 245), Belly = c(250, 252, 255), Ears = "none", Extras = {"flippers", "snout"}}},
		{Name = "Snow Owl",         Chance = 15, Rarity = "Uncommon",  Boost = 0.8434, Look = {Body = c(245, 248, 255), Belly = c(210, 230, 250), Accent = c(255, 190, 60), Ears = "pointy", Extras = {"beak", "wings"}}},
		{Name = "Glacier Mammoth",  Chance = 8,  Rarity = "Rare",      Boost = 1.1814, Look = {Body = c(140, 180, 220), Belly = c(220, 240, 255), Ears = "round", Size = 1.35, Extras = {"horns", "snout"}}},
		{Name = "Absolute Phoenix", Chance = 2,  Rarity = "Legendary", Boost = 1.8228, Look = {Body = c(120, 220, 255), Belly = c(255, 255, 255), Accent = c(200, 150, 255), Ears = "none", Size = 1.35, Extras = {"wings", "longtail", "halo", "glow"}, Glow = c(140, 230, 255)}},
	}},
	-- WORLD 2 (2026-10-02, Claude). Models: Blender pets in ReplicatedStorage.PetModelOverrides (Look = fallback only).
	-- 2026-10-03: egg = 10% of its stage price (Sakura: of Portal); pet boosts x1.45 per World 2 egg (progression model, work/world2-balance).
	{Id = "BlossomEgg", Name = "Blossom Egg", Cost = 8600000000, RequiredStage = "Sakura", Pets = { -- rebalance 2026-10-05: was 60000000000000
		{Name = "Koi",            Chance = 45, Rarity = "Common",    Boost = 0.6971,  Look = {Body = c(255, 246, 238), Belly = c(255, 122, 46), Ears = "none", NoFeet = true}},
		{Name = "Blossom Bunny",  Chance = 30, Rarity = "Common",    Boost = 0.8665,  Look = {Body = c(255, 247, 250), Ears = "long", Extras = {"tail"}}},
		{Name = "Red Panda",      Chance = 15, Rarity = "Uncommon",  Boost = 1.1224,  Look = {Body = c(217, 87, 43), Belly = c(255, 241, 224), Ears = "round", Extras = {"bigtail"}}},
		{Name = "Crane",          Chance = 8,  Rarity = "Rare",      Boost = 1.5556,  Look = {Body = c(255, 255, 255), Accent = c(232, 56, 61), Ears = "none", Extras = {"beak", "wings"}}},
		{Name = "Blossom Dragon", Chance = 2,  Rarity = "Legendary", Boost = 2.3733, Look = {Body = c(255, 159, 201), Belly = c(255, 233, 214), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 217, 240)}},
	}},
	{Id = "CandyEgg", Name = "Candy Egg", Cost = 41000000000, RequiredStage = "Candy", Pets = { -- rebalance 2026-10-05: was 3700000000000000
		{Name = "Gummy Bear",        Chance = 45, Rarity = "Common",    Boost = 0.9118,  Look = {Body = c(255, 77, 109), Ears = "round", Transparency = 0.1}},
		{Name = "Marshmallow Bunny", Chance = 30, Rarity = "Common",    Boost = 1.1224,  Look = {Body = c(255, 248, 244), Ears = "long", Extras = {"tail"}}},
		{Name = "Cupcake Cat",       Chance = 15, Rarity = "Uncommon",  Boost = 1.4545,  Look = {Body = c(255, 179, 209), Belly = c(143, 232, 200), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Candy Fox",         Chance = 8,  Rarity = "Rare",      Boost = 1.9836,  Look = {Body = c(255, 169, 77), Belly = c(255, 243, 220), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Sugar Dragon",      Chance = 2,  Rarity = "Legendary", Boost = 3.0079, Look = {Body = c(143, 232, 200), Belly = c(255, 243, 220), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 156, 203)}},
	}},
	{Id = "PearlEgg", Name = "Pearl Egg", Cost = 240000000000, RequiredStage = "Atlantis", Pets = { -- rebalance 2026-10-05: was 23000000000000000
		{Name = "Crab",                Chance = 45, Rarity = "Common",    Boost = 1.1814,  Look = {Body = c(255, 111, 76), Ears = "none", Extras = {"snout"}}},
		{Name = "Seahorse",            Chance = 30, Rarity = "Common",    Boost = 1.4545,  Look = {Body = c(255, 201, 74), Ears = "none", NoFeet = true, Extras = {"longtail"}}},
		{Name = "Turtle",              Chance = 15, Rarity = "Uncommon",  Boost = 1.8527,  Look = {Body = c(126, 211, 106), Belly = c(255, 240, 200), Ears = "none", Extras = {"flippers"}}},
		{Name = "Manta Ray",           Chance = 8,  Rarity = "Rare",      Boost = 2.5231, Look = {Body = c(23, 96, 122), Belly = c(255, 248, 238), Ears = "none", NoFeet = true, Extras = {"wings", "longtail"}}},
		{Name = "Ancient Sea Serpent", Chance = 2,  Rarity = "Legendary", Boost = 3.7946, Look = {Body = c(47, 196, 178), Belly = c(255, 240, 200), Ears = "none", Size = 1.3, Extras = {"crown", "longtail", "glow"}, Glow = c(233, 255, 255)}},
	}},
	{Id = "ToyCapsuleEgg", Name = "Toy Capsule Egg", Cost = 600000000000, RequiredStage = "Toybox", Pets = { -- rebalance 2026-10-05: was 67000000000000000
		{Name = "Teddy Bear",     Chance = 45, Rarity = "Common",    Boost = 1.5223,  Look = {Body = c(181, 118, 63), Belly = c(232, 195, 154), Ears = "round"}},
		{Name = "Toy Duck",       Chance = 30, Rarity = "Common",    Boost = 1.8527,  Look = {Body = c(255, 210, 63), Ears = "none", Extras = {"snout"}}},
		{Name = "Wind-up Mouse",  Chance = 15, Rarity = "Uncommon",  Boost = 2.3606, Look = {Body = c(199, 203, 214), Ears = "round", Extras = {"tail"}}},
		{Name = "Toy Robot",      Chance = 8,  Rarity = "Rare",      Boost = 3.2006, Look = {Body = c(184, 194, 214), Ears = "none", Material = "Metal", Extras = {"glow"}, Glow = c(127, 233, 255)}},
		{Name = "Plush Dinosaur", Chance = 2,  Rarity = "Legendary", Boost = 4.7801, Look = {Body = c(111, 210, 122), Belly = c(207, 245, 192), Ears = "none", Size = 1.3, Extras = {"longtail", "glow"}, Glow = c(255, 242, 168)}},
	}},
	{Id = "GearEgg", Name = "Gear Egg", Cost = 860000000000, RequiredStage = "Clockwork", Pets = { -- rebalance 2026-10-05: was 310000000000000000
		{Name = "Brass Beetle",     Chance = 45, Rarity = "Common",    Boost = 1.955,  Look = {Body = c(224, 176, 74), Ears = "none", Material = "Metal"}},
		{Name = "Clockwork Bird",   Chance = 30, Rarity = "Common",    Boost = 2.3606, Look = {Body = c(63, 191, 180), Belly = c(246, 231, 200), Ears = "none", Extras = {"wings"}}},
		{Name = "Steam Pup",        Chance = 15, Rarity = "Uncommon",  Boost = 2.997, Look = {Body = c(208, 122, 72), Belly = c(246, 231, 200), Ears = "round", Extras = {"tail"}}},
		{Name = "Gear Fox",         Chance = 8,  Rarity = "Rare",      Boost = 4.0334, Look = {Body = c(255, 138, 61), Belly = c(246, 231, 200), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Clockwork Dragon", Chance = 2,  Rarity = "Legendary", Boost = 6.0016, Look = {Body = c(63, 191, 180), Belly = c(246, 231, 200), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 226, 160)}},
	}},
	{Id = "CloudEgg", Name = "Cloud Egg", Cost = 1600000000000, RequiredStage = "Cloud", Pets = { -- rebalance 2026-10-05: was 2900000000000000000
		{Name = "Cloud Lamb",      Chance = 45, Rarity = "Common",    Boost = 2.4862, Look = {Body = c(247, 249, 255), Ears = "round"}},
		{Name = "Cloud Kitten",    Chance = 30, Rarity = "Common",    Boost = 2.997, Look = {Body = c(207, 228, 255), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Thunder Owl",     Chance = 15, Rarity = "Uncommon",  Boost = 3.7852, Look = {Body = c(111, 127, 208), Belly = c(217, 222, 255), Ears = "pointy", Extras = {"wings"}}},
		{Name = "Rainbow Pegasus", Chance = 8,  Rarity = "Rare",      Boost = 5.0712, Look = {Body = c(247, 249, 255), Ears = "pointy", Extras = {"wings", "tail"}}},
		{Name = "Sky Whale",       Chance = 2,  Rarity = "Legendary", Boost = 7.5165, Look = {Body = c(143, 208, 255), Belly = c(247, 249, 255), Ears = "none", Size = 1.3, NoFeet = true, Extras = {"longtail", "glow"}, Glow = c(255, 242, 168)}},
	}},
	{Id = "StarEgg", Name = "Star Egg", Cost = 9600000000000, RequiredStage = "Cosmic", Pets = { -- rebalance 2026-10-05: was 26000000000000000000
		{Name = "Comet Pup",     Chance = 45, Rarity = "Common",    Boost = 3.1479,  Look = {Body = c(169, 216, 255), Ears = "round", Extras = {"tail"}}},
		{Name = "Moon Bunny",    Chance = 30, Rarity = "Common",    Boost = 3.7852,  Look = {Body = c(241, 236, 255), Ears = "long", Extras = {"tail"}}},
		{Name = "Astro Cat",     Chance = 15, Rarity = "Uncommon",  Boost = 4.764,  Look = {Body = c(255, 174, 92), Ears = "pointy", Extras = {"tail"}}},
		{Name = "Nebula Fox",    Chance = 8,  Rarity = "Rare",      Boost = 6.3588,  Look = {Body = c(199, 125, 255), Belly = c(243, 230, 255), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Galaxy Dragon", Chance = 2,  Rarity = "Legendary", Boost = 9.3993, Look = {Body = c(60, 46, 143), Belly = c(185, 166, 255), Ears = "none", Size = 1.3, Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 246, 200)}},
	}},
	-- VERITY EGG (2026-10-06, Claude): exclusive paid egg, sold only in the SHOP for Robux (PassConfig.Products.VerityEgg, ProductService).
	-- Never in the world (no hatch prompt), never Golden (the Fuser skips these pets), one pet per purchase rolled on the server from
	-- exactly this table; the shop shows the same Chance values (sum = 100). Boosts scale with progress: Scale x the best regular
	-- Legendary boost of the eggs this player has unlocked (PetConfig.RefBoost), so they stay clearly stronger than any regular pet at
	-- the same point of the game and Rainbow Verity (x4) beats every pet, Golden ones (x2) included. Non-payers are unaffected.
	{Id = "VerityEgg", Name = "Verity Egg", Cost = 0, Paid = true, Pets = {
		-- 2026-10-06 (wiktor: "veritys look like ... marbles with faces"): Look.Orb = glowing emoji orb (PetModels builds it ahead of the
		-- old Blender animals in PetModelOverrides). Remove the Orb field to bring the animals back. Names/chances/boosts unchanged.
		{Name = "Verity",         Chance = 44, Rarity = "Epic",      Scale = 1.3, Look = {Body = c(255, 214, 40), Orb = {Face = "grin"}, Belly = c(255, 255, 255), Ears = "round", Extras = {"halo", "glow"}, Glow = c(127, 227, 255)}},
		{Name = "Falsity",        Chance = 30, Rarity = "Epic",      Scale = 1.6, Look = {Body = c(240, 60, 60), Orb = {Face = "smile"}, Belly = c(241, 230, 255), Ears = "pointy", Extras = {"bigtail"}}},
		{Name = "Cruelty",        Chance = 18, Rarity = "Legendary", Scale = 2.0, Look = {Body = c(70, 205, 75), Orb = {Face = "angry"}, Belly = c(255, 217, 194), Ears = "none", Extras = {"horns", "wings", "longtail", "glow"}, Glow = c(255, 154, 60)}},
		{Name = "Lord Verity",    Chance = 7,  Rarity = "Legendary", Scale = 2.6, Look = {Body = c(255, 190, 30), Orb = {Face = "grin", Crown = true}, Belly = c(255, 240, 208), Ears = "round", Size = 1.3, Extras = {"crown", "glow"}, Glow = c(127, 227, 255)}},
		{Name = "Rainbow Verity", Chance = 1,  Rarity = "Mythic",    Scale = 4.0, Look = {Body = c(255, 90, 160), Orb = {Face = "grin", Rainbow = true, Sparkle = true, Size = 1.15}, Belly = c(255, 243, 251), Ears = "round", Size = 1.35, Extras = {"wings", "halo", "glow"}, Glow = c(255, 232, 138)}},
	}},
	-- SUPPORTER GIFT (2026-10-13, Claude): free one-time thank-you for joining the game's group (CommunityRewardService). Never in the
	-- world, never sold, never Golden (Paid = true keeps it out of eggs stands, the Fuser and pet achievements). Progress-scaled like the
	-- Verity pets but below them: 1.15 x the best regular Legendary of the eggs this player has unlocked, so it stays useful all game.
	{Id = "SupporterGift", Name = "Supporter Gift", Cost = 0, Paid = true, Gift = true, Pets = {
		{Name = "Frosty Pal", Chance = 100, Rarity = "Legendary", Scale = 1.15, Look = {Body = c(240, 248, 255), Belly = c(150, 205, 255), Ears = "long", Size = 1.15, Extras = {"wings", "crown", "glow"}, Accent = c(255, 205, 60), Glow = c(150, 220, 255)}},
	}},
}

PetConfig.PetByName, PetConfig.EggById = {}, {}
for _, egg in ipairs(PetConfig.Eggs) do
	PetConfig.EggById[egg.Id] = egg
	for _, pet in ipairs(egg.Pets) do
		pet.Egg = egg.Id
		if egg.Paid then pet.Paid, pet.NoGolden = true, true end
		PetConfig.PetByName[pet.Name] = pet
	end
end

-- 2026-10-06: progress-scaled boosts (Verity Egg pets). Unlocked = "Starter" or the server-set Stage_<Id> attribute.
function PetConfig.RefBoost(player)
	local best = 0
	for _, egg in ipairs(PetConfig.Eggs) do
		local st = egg.RequiredStage
		if not egg.Paid and (st == nil or st == "Starter" or (player and player:GetAttribute("Stage_" .. st) == true)) then
			for _, p in ipairs(egg.Pets) do
				if p.Rarity == "Legendary" and (p.Boost or 0) > best then best = p.Boost end
			end
		end
	end
	return best
end
function PetConfig.BoostOf(pet, player)
	if pet.Scale then return pet.Scale * PetConfig.RefBoost(player) end
	return pet.Boost or 0
end
for _, pet in pairs(PetConfig.PetByName) do
	if pet.Scale then pet.Boost = PetConfig.BoostOf(pet, nil) end -- placeholder (starter level); per-player value via BoostOf
end
-- one weighted roll from an egg's own Chance table (the shop's odds come from the same table)
function PetConfig.RollPet(egg, rng)
	local total = 0
	for _, p in ipairs(egg.Pets) do total += p.Chance end
	local r = (rng and rng:NextNumber() or math.random()) * total
	for _, p in ipairs(egg.Pets) do
		r -= p.Chance
		if r <= 0 then return p end
	end
	return egg.Pets[#egg.Pets]
end
-- 2026-10-03 (Claude): Golden pets, made in the Pet Lodge's Pet Fuser (3 of the same pet -> 1 Golden pet with GoldenMult x boost).
-- They are not in any egg (not hatchable) and are never added to the pet index; everything else treats them as normal pets.
PetConfig.GoldenMult = 2
PetConfig.GoldenOf = {}
do
	local base = {}
	for _, pet in pairs(PetConfig.PetByName) do if not pet.NoGolden then table.insert(base, pet) end end
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

-- total snow multiplier for a list of equipped pet names (player: needed for the progress-scaled Verity pets)
function PetConfig.Multiplier(names, player)
	local m = 1
	for _, n in ipairs(names) do
		local p = PetConfig.PetByName[n]
		if p then m += PetConfig.BoostOf(p, player) end
	end
	return m
end

-- clients: keep the scaled pets' Boost (shown in the inventory, index and hatch reveal) at the local player's real value
if game:GetService("RunService"):IsClient() then
	local lp = game:GetService("Players").LocalPlayer
	if lp then
		local function upd()
			for _, pet in pairs(PetConfig.PetByName) do if pet.Scale then pet.Boost = PetConfig.BoostOf(pet, lp) end end
		end
		upd()
		lp.AttributeChanged:Connect(function(a) if a:sub(1, 6) == "Stage_" then upd() end end)
	end
end

return PetConfig

