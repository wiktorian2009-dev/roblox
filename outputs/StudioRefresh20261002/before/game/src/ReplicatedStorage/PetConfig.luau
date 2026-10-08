-- PET CONFIG: eggs, their 5 pets, odds (%), rarity, snow boost and look.
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
	{Id = "DesertEgg", Name = "Desert Egg", Cost = 12000, RequiredStage = "Desert", Pets = {
		{Name = "Fennec Fox",  Chance = 45, Rarity = "Common",    Boost = 0.10, Look = {Body = c(235, 190, 130), Belly = c(255, 240, 215), Ears = "huge", Extras = {"bigtail"}}},
		{Name = "Camel",       Chance = 30, Rarity = "Common",    Boost = 0.15, Look = {Body = c(205, 160, 100), Ears = "round", Extras = {"hump", "snout"}}},
		{Name = "Sand Lizard", Chance = 15, Rarity = "Uncommon",  Boost = 0.22, Look = {Body = c(215, 175, 80), Belly = c(245, 225, 160), Ears = "none", Extras = {"longtail", "spikes"}, SpikeColor = c(180, 120, 50)}},
		{Name = "Scarab",      Chance = 8,  Rarity = "Rare",      Boost = 0.35, Look = {Body = c(40, 150, 140), Belly = c(255, 200, 60), Ears = "none", Material = "Metal", Extras = {"horns", "wings"}, Accent = c(255, 200, 60)}},
		{Name = "Sphinx Cat",  Chance = 2,  Rarity = "Legendary", Boost = 0.70, Look = {Body = c(240, 200, 120), Belly = c(255, 235, 180), Ears = "pointy", Extras = {"crown", "glow"}, Accent = c(40, 90, 200), Glow = c(255, 210, 90)}},
	}},
	{Id = "CrystalEgg", Name = "Crystal Egg", Cost = 8000000, RequiredStage = "Crystal", Pets = {
		{Name = "Gem Slime",      Chance = 45, Rarity = "Common",    Boost = 0.30, Look = {Body = c(110, 210, 255), Ears = "none", Material = "Glass", Transparency = 0.2, NoFeet = true, Extras = {"gem"}}},
		{Name = "Crystal Bunny",  Chance = 30, Rarity = "Common",    Boost = 0.42, Look = {Body = c(200, 235, 255), Ears = "long", Extras = {"spikes"}, SpikeColor = c(90, 200, 255)}},
		{Name = "Prism Bird",     Chance = 15, Rarity = "Uncommon",  Boost = 0.95, Look = {Body = c(150, 200, 255), Belly = c(255, 255, 255), Accent = c(255, 180, 230), Ears = "none", Extras = {"beak", "wings"}}},
		{Name = "Crystal Golem",  Chance = 8,  Rarity = "Rare",      Boost = 0.60, Look = {Body = c(70, 90, 130), Belly = c(90, 200, 255), Ears = "none", Size = 1.3, Extras = {"spikes", "glow"}, SpikeColor = c(80, 220, 255), Glow = c(80, 220, 255)}},
		{Name = "Diamond Dragon", Chance = 2,  Rarity = "Legendary", Boost = 1.80, Look = {Body = c(170, 240, 255), Belly = c(255, 255, 255), Ears = "none", Material = "Glass", Size = 1.35, Extras = {"horns", "wings", "longtail", "glow"}, Accent = c(90, 210, 255), Glow = c(120, 230, 255)}},
	}},
	{Id = "CursedEgg", Name = "Cursed Egg", Cost = 300000, RequiredStage = "Cursed", Pets = {
		{Name = "Shadow Bat",  Chance = 45, Rarity = "Common",    Boost = 0.18, Look = {Body = c(55, 45, 75), Eyes = c(255, 60, 90), Ears = "pointy", NoFeet = true, Extras = {"wings"}}},
		{Name = "Ghost",       Chance = 30, Rarity = "Common",    Boost = 0.25, Look = {Body = c(235, 225, 255), Transparency = 0.3, Eyes = c(40, 20, 60), Ears = "none", NoFeet = true, Extras = {"wisp"}}},
		{Name = "Imp",         Chance = 15, Rarity = "Uncommon",  Boost = 0.38, Look = {Body = c(170, 60, 90), Belly = c(230, 120, 140), Ears = "pointy", Extras = {"horns", "longtail"}, Accent = c(40, 20, 30)}},
		{Name = "Shadow Wolf", Chance = 8,  Rarity = "Rare",      Boost = 0.60, Look = {Body = c(45, 35, 60), Belly = c(90, 60, 120), Eyes = c(200, 80, 255), Ears = "pointy", Size = 1.25, Extras = {"bigtail", "snout", "glow"}, Glow = c(170, 70, 255)}},
		{Name = "Void Demon",  Chance = 2,  Rarity = "Legendary", Boost = 1.20, Look = {Body = c(30, 20, 45), Belly = c(120, 40, 200), Eyes = c(255, 90, 255), Ears = "none", Size = 1.4, Extras = {"horns", "wings", "halo", "glow"}, Accent = c(190, 70, 255), Glow = c(190, 70, 255)}},
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

