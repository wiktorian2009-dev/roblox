-- PlowConfig: the SNOWPLOW core loop. Parts, odds, prices, cooldowns and vehicle balance all live HERE.
--   ROLL a part offer in the garage -> BUY it with Snow (or RESERVE it) -> EQUIP blade / engine / running gear -> DRIVE through the fields
--   -> earn Snow + treasures -> improve the vehicle -> unlock stages and rebirth.
-- 2026-10-05 (Claude): 90-part catalog (30 blades, 30 engines, 30 running gear), progression-aware offer pool with luck that never removes
-- practical parts, bad-luck protection, engine acceleration, explicit field toughness. Generated from
-- outputs/PlowExpansion20261005/sim (catalog.py + final_balance.json -> gen_lua.py); edit those and regenerate, or edit here carefully.
-- Mode is a fixed identifier used by the existing client/state contract, not a runtime gameplay switch.
local RS = game:GetService("ReplicatedStorage")
local C = {}
C.Mode = "Snowplow" -- fixed current gameplay identifier

C.Shop = {
	RollCooldown = 2.0,   -- base seconds between offer rolls; multiplied by RollCooldownMult (rerolls share the cooldown)
	MinRollCooldownMult = 0.6, -- offer-speed tiles can shorten the base cooldown by at most 40%
	BigRevealRank = 4,    -- rarity rank (Rare = 4) that gets the stronger reveal
	MaxOwned = 99,
	ProtectAfter = 6,     -- bad-luck protection: after 6 rolls in a row without a USEFUL offer, the next roll is drawn only from useful parts
}
C.Rarities = {
	{Id = "Starter", Name = "Starter", Color = Color3.fromRGB(156, 166, 188)},
	{Id = "Common", Name = "Common", Color = Color3.fromRGB(150, 200, 255)},
	{Id = "Uncommon", Name = "Uncommon", Color = Color3.fromRGB(90, 220, 110)},
	{Id = "Rare", Name = "Rare", Color = Color3.fromRGB(80, 140, 255)},
	{Id = "Epic", Name = "Epic", Color = Color3.fromRGB(190, 90, 255)},
	{Id = "Legendary", Name = "Legendary", Color = Color3.fromRGB(255, 196, 46)},
}
C.RarityRank = {}
for i, r in ipairs(C.Rarities) do C.RarityRank[r.Id] = i end
C.Slots = {"Blade", "Engine", "Gear"}
C.Starter = {Blade = "blade_basic", Engine = "engine_starter", Gear = "gear_wheels"} -- free, owned by everyone, can never be lost

-- Price = explicit Snow cost (never depends on the wallet; an offer keeps the price it was rolled with).
-- Band = progression theme (1 Starter ... 7 Absolute Zero, 8 Sakura ... 14 Cosmic). Role: S starter, A practical, B premium, C legendary.
-- Blade: Width (studs), Soft / Hard = clearing multiplier on soft / hard snow (blended by the field's toughness).
-- Engine: Speed (studs/s), Power (clearing power multiplier), AccelTime (seconds from standstill to top speed).
-- Gear: SpeedMult, Traction (less sliding), Turn, Pivot (turning on the spot), Stability (stays upright), PowerMult (pushing power).
C.Parts = {
	blade_basic = {Slot = "Blade", Name = "Basic Blade", Model = "BladeBasic", Rarity = "Starter", Band = 1, Role = "S", Theme = "Snowy Starter", Kind = "straight", Price = 0,
		Desc = "A sturdy steel blade. Free and always yours.", Stats = {Width = 7, Soft = 1, Hard = 1}},
	blade_wide = {Slot = "Blade", Name = "Wide Clearing Blade", Model = "BladeWide", Rarity = "Common", Band = 1, Role = "A", Theme = "Snowy Starter", Kind = "sweeper", Price = 120,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12, Soft = 1.25, Hard = 0.6}},
	blade_frost_scoop = {Slot = "Blade", Name = "Frosty Scoop", Model = "BladeFrostScoop", Rarity = "Uncommon", Band = 1, Role = "C", Theme = "Snowy Starter", Kind = "scoop", Price = 650,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 8.5, Soft = 1.12, Hard = 0.85}},
	blade_dune = {Slot = "Blade", Name = "Dune Sweeper", Model = "BladeDune", Rarity = "Common", Band = 2, Role = "A", Theme = "Desert", Kind = "sweeper", Price = 1500,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 11, Soft = 1.44, Hard = 0.69}},
	blade_ice = {Slot = "Blade", Name = "Reinforced Icebreaker", Model = "BladeIce", Rarity = "Rare", Band = 2, Role = "B", Theme = "Desert", Kind = "icebreaker", Price = 660000,
		Desc = "Narrow armoured edge that smashes hard ice. Premium part for its world.", Stats = {Width = 8.5, Soft = 1.17, Hard = 2.4}},
	blade_grave = {Slot = "Blade", Name = "Grave Digger", Model = "BladeGrave", Rarity = "Uncommon", Band = 3, Role = "A", Theme = "Cursed", Kind = "toothed", Price = 900000,
		Desc = "Teeth bite into hard ice; weaker in soft powder.", Stats = {Width = 9, Soft = 1.12, Hard = 1.92}},
	blade_hex = {Slot = "Blade", Name = "Hex Breaker", Model = "BladeHex", Rarity = "Rare", Band = 3, Role = "B", Theme = "Cursed", Kind = "vshape", Price = 240000000,
		Desc = "V-wedge that splits tough snow - great on hard fields. Premium part for its world.", Stats = {Width = 9.5, Soft = 1.55, Hard = 2.33}},
	blade_quartz = {Slot = "Blade", Name = "Quartz Edge", Model = "BladeQuartz", Rarity = "Uncommon", Band = 4, Role = "A", Theme = "Crystal Caves", Kind = "segmented", Price = 330000000,
		Desc = "Segmented plates: steady all-rounder with a hard-ice edge.", Stats = {Width = 10, Soft = 1.52, Hard = 1.75}},
	blade_prism = {Slot = "Blade", Name = "Prism Cleaver", Model = "BladePrism", Rarity = "Rare", Band = 4, Role = "B", Theme = "Crystal Caves", Kind = "crystal", Price = 57000000000,
		Desc = "Crystal edge: excellent on hard ice. Premium part for its world.", Stats = {Width = 8.5, Soft = 1.69, Hard = 3.07}},
	blade_pixel = {Slot = "Blade", Name = "Pixel Pusher", Model = "BladePixel", Rarity = "Uncommon", Band = 5, Role = "A", Theme = "Retro World", Kind = "pixel", Price = 78000000000,
		Desc = "Blocky and wide: strong in soft snow.", Stats = {Width = 11, Soft = 1.96, Hard = 1.61}},
	blade_arcade = {Slot = "Blade", Name = "Arcade Plow", Model = "BladeArcade", Rarity = "Epic", Band = 5, Role = "B", Theme = "Retro World", Kind = "segmented", Price = 350000000000,
		Desc = "Segmented plates: steady all-rounder with a hard-ice edge. Premium part for its world.", Stats = {Width = 9.5, Soft = 2.28, Hard = 2.62}},
	blade_vine = {Slot = "Blade", Name = "Vine Sweeper", Model = "BladeVine", Rarity = "Uncommon", Band = 6, Role = "A", Theme = "Jungle", Kind = "sweeper", Price = 480000000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12, Soft = 2.51, Hard = 1.21}},
	blade_tusk = {Slot = "Blade", Name = "Tusk Breaker", Model = "BladeTusk", Rarity = "Epic", Band = 6, Role = "B", Theme = "Jungle", Kind = "toothed", Price = 3700000000000,
		Desc = "Teeth bite into hard ice; weaker in soft powder. Premium part for its world.", Stats = {Width = 8.5, Soft = 2.23, Hard = 3.8}},
	blade_glacier = {Slot = "Blade", Name = "Glacier Plow", Model = "BladeGlacier", Rarity = "Uncommon", Band = 7, Role = "A", Theme = "Absolute Zero", Kind = "scoop", Price = 5100000000000,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 10.5, Soft = 2.59, Hard = 1.97}},
	blade_zero = {Slot = "Blade", Name = "Absolute Edge", Model = "BladeZero", Rarity = "Epic", Band = 7, Role = "B", Theme = "Absolute Zero", Kind = "icebreaker", Price = 130000000000000,
		Desc = "Narrow armoured edge that smashes hard ice. Premium part for its world.", Stats = {Width = 8.5, Soft = 2.35, Hard = 4.83}},
	blade_singularity = {Slot = "Blade", Name = "Zero Point Blade", Model = "BladeSingularity", Rarity = "Legendary", Band = 7, Role = "C", Theme = "Absolute Zero", Kind = "vshape", Price = 2e+16,
		Desc = "V-wedge that splits tough snow - great on hard fields. A legendary saving goal!", Stats = {Width = 10.5, Soft = 3.33, Hard = 5}},
	blade_petal = {Slot = "Blade", Name = "Petal Sweeper", Model = "BladePetal", Rarity = "Rare", Band = 8, Role = "A", Theme = "Sakura Garden", Kind = "sweeper", Price = 180000000000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12.5, Soft = 3.33, Hard = 1.6}},
	blade_katana = {Slot = "Blade", Name = "Katana Blade", Model = "BladeKatana", Rarity = "Epic", Band = 8, Role = "B", Theme = "Sakura Garden", Kind = "straight", Price = 8.1e+15,
		Desc = "Dependable all-rounder: the same on soft powder and hard ice. Premium part for its world.", Stats = {Width = 9, Soft = 3.47, Hard = 3.47}},
	blade_lollipop = {Slot = "Blade", Name = "Lollipop Scoop", Model = "BladeLollipop", Rarity = "Rare", Band = 9, Role = "A", Theme = "Candy Kingdom", Kind = "scoop", Price = 1.1e+16,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 10.5, Soft = 3.43, Hard = 2.6}},
	blade_canecrusher = {Slot = "Blade", Name = "Candy Cane Crusher", Model = "BladeCaneCrusher", Rarity = "Epic", Band = 9, Role = "B", Theme = "Candy Kingdom", Kind = "toothed", Price = 5.1e+16,
		Desc = "Teeth bite into hard ice; weaker in soft powder. Premium part for its world.", Stats = {Width = 9.5, Soft = 3.39, Hard = 5.78}},
	blade_coral = {Slot = "Blade", Name = "Coral Scoop", Model = "BladeCoral", Rarity = "Rare", Band = 10, Role = "A", Theme = "Sunken Atlantis", Kind = "scoop", Price = 6.9e+16,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 11, Soft = 3.94, Hard = 2.99}},
	blade_trident = {Slot = "Blade", Name = "Trident Breaker", Model = "BladeTrident", Rarity = "Legendary", Band = 10, Role = "B", Theme = "Sunken Atlantis", Kind = "vshape", Price = 1.5e+17,
		Desc = "V-wedge that splits tough snow - great on hard fields. A legendary saving goal!", Stats = {Width = 9, Soft = 4.13, Hard = 6.19}},
	blade_brick = {Slot = "Blade", Name = "Building Block Blade", Model = "BladeBrick", Rarity = "Rare", Band = 11, Role = "A", Theme = "Giant Toybox", Kind = "segmented", Price = 2e+17,
		Desc = "Segmented plates: steady all-rounder with a hard-ice edge.", Stats = {Width = 11.5, Soft = 4.05, Hard = 4.65}},
	blade_bulldozer = {Slot = "Blade", Name = "Toy Bulldozer", Model = "BladeBulldozer", Rarity = "Legendary", Band = 11, Role = "B", Theme = "Giant Toybox", Kind = "straight", Price = 6.8e+17,
		Desc = "Dependable all-rounder: the same on soft powder and hard ice. A legendary saving goal!", Stats = {Width = 10, Soft = 5.27, Hard = 5.27}},
	blade_cog = {Slot = "Blade", Name = "Cog Sweeper", Model = "BladeCog", Rarity = "Rare", Band = 12, Role = "A", Theme = "Clockwork City", Kind = "sweeper", Price = 9.3e+17,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12, Soft = 5.82, Hard = 2.79}},
	blade_gearbreaker = {Slot = "Blade", Name = "Gearbreaker", Model = "BladeGearbreaker", Rarity = "Legendary", Band = 12, Role = "B", Theme = "Clockwork City", Kind = "mechanical", Price = 6.4e+18,
		Desc = "Grinding gears chew through hard ice. A legendary saving goal!", Stats = {Width = 9.5, Soft = 5.46, Hard = 9.1}},
	blade_cumulus = {Slot = "Blade", Name = "Cumulus Sweeper", Model = "BladeCumulus", Rarity = "Rare", Band = 13, Role = "A", Theme = "Cloud Kingdom", Kind = "sweeper", Price = 8.7e+18,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 13, Soft = 6.69, Hard = 3.21}},
	blade_thunder = {Slot = "Blade", Name = "Thunder Wedge", Model = "BladeThunder", Rarity = "Legendary", Band = 13, Role = "B", Theme = "Cloud Kingdom", Kind = "vshape", Price = 5.7e+19,
		Desc = "V-wedge that splits tough snow - great on hard fields. A legendary saving goal!", Stats = {Width = 9.5, Soft = 6.28, Hard = 9.42}},
	blade_comet = {Slot = "Blade", Name = "Comet Scoop", Model = "BladeComet", Rarity = "Epic", Band = 14, Role = "A", Theme = "Cosmic Sanctuary", Kind = "scoop", Price = 7.8e+19,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 11.5, Soft = 6.89, Hard = 5.23}},
	blade_galaxy = {Slot = "Blade", Name = "Galaxy Breaker", Model = "BladeGalaxy", Rarity = "Legendary", Band = 14, Role = "B", Theme = "Cosmic Sanctuary", Kind = "cosmic", Price = 1.1e+20,
		Desc = "Cosmic edge: strong on every kind of snow. A legendary saving goal!", Stats = {Width = 10.5, Soft = 9.23, Hard = 10.8}},
	engine_starter = {Slot = "Engine", Name = "Starter Engine", Model = "EngineStarter", Rarity = "Starter", Band = 1, Role = "S", Theme = "Snowy Starter", Kind = "compact", Price = 0,
		Desc = "Small but reliable. Free and always yours.", Stats = {Speed = 24, Power = 1, AccelTime = 1.6}},
	engine_snowball = {Slot = "Engine", Name = "Snowball Motor", Model = "EngineSnowball", Rarity = "Common", Band = 1, Role = "A", Theme = "Snowy Starter", Kind = "compact", Price = 300,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 25, Power = 2.02, AccelTime = 1.2}},
	engine_balanced = {Slot = "Engine", Name = "Balanced Engine", Model = "EngineBalanced", Rarity = "Uncommon", Band = 1, Role = "C", Theme = "Snowy Starter", Kind = "twin", Price = 450,
		Desc = "Twin cylinders: balanced power and speed.", Stats = {Speed = 30, Power = 4.5, AccelTime = 1.5}},
	engine_sandrunner = {Slot = "Engine", Name = "Sand Runner", Model = "EngineSandRunner", Rarity = "Common", Band = 2, Role = "A", Theme = "Desert", Kind = "turbine", Price = 1500,
		Desc = "High top speed and instant spin-up, a little less power.", Stats = {Speed = 34.5, Power = 2.58, AccelTime = 1}},
	engine_power = {Slot = "Engine", Name = "Powerful Engine", Model = "EnginePower", Rarity = "Rare", Band = 2, Role = "B", Theme = "Desert", Kind = "industrial", Price = 660000,
		Desc = "Heavy torque and big clearing power, slower to speed up. Premium part for its world.", Stats = {Speed = 28.4, Power = 6.02, AccelTime = 2.1}},
	engine_lantern = {Slot = "Engine", Name = "Lantern Motor", Model = "EngineLantern", Rarity = "Uncommon", Band = 3, Role = "A", Theme = "Cursed", Kind = "compact", Price = 900000,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 25.9, Power = 7.73, AccelTime = 1.2}},
	engine_phantom = {Slot = "Engine", Name = "Phantom V-Twin", Model = "EnginePhantom", Rarity = "Rare", Band = 3, Role = "B", Theme = "Cursed", Kind = "twin", Price = 240000000,
		Desc = "Twin cylinders: balanced power and speed. Premium part for its world.", Stats = {Speed = 31.9, Power = 14.3, AccelTime = 1.5}},
	engine_geode = {Slot = "Engine", Name = "Geode Core", Model = "EngineGeode", Rarity = "Uncommon", Band = 4, Role = "A", Theme = "Crystal Caves", Kind = "crystal", Price = 330000000,
		Desc = "Crystal core: solid power at a steady speed.", Stats = {Speed = 30.4, Power = 23.2, AccelTime = 1.6}},
	engine_reactor = {Slot = "Engine", Name = "Crystal Reactor", Model = "EngineReactor", Rarity = "Rare", Band = 4, Role = "B", Theme = "Crystal Caves", Kind = "crystal", Price = 57000000000,
		Desc = "Crystal core: solid power at a steady speed. Premium part for its world.", Stats = {Speed = 32.4, Power = 39.4, AccelTime = 1.6}},
	engine_8bit = {Slot = "Engine", Name = "8-Bit Engine", Model = "Engine8Bit", Rarity = "Uncommon", Band = 5, Role = "A", Theme = "Retro World", Kind = "pixel", Price = 78000000000,
		Desc = "Arcade motor: balanced and peppy.", Stats = {Speed = 31.8, Power = 54.6, AccelTime = 1.3}},
	engine_arcade = {Slot = "Engine", Name = "Arcade Turbo", Model = "EngineArcade", Rarity = "Epic", Band = 5, Role = "B", Theme = "Retro World", Kind = "turbine", Price = 350000000000,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 37.8, Power = 79.8, AccelTime = 1}},
	engine_tiki = {Slot = "Engine", Name = "Tiki Thumper", Model = "EngineTiki", Rarity = "Uncommon", Band = 6, Role = "A", Theme = "Jungle", Kind = "industrial", Price = 480000000000,
		Desc = "Heavy torque and big clearing power, slower to speed up.", Stats = {Speed = 28.2, Power = 155, AccelTime = 2.1}},
	engine_jturbine = {Slot = "Engine", Name = "Jungle Turbine", Model = "EngineJungleTurbine", Rarity = "Epic", Band = 6, Role = "B", Theme = "Jungle", Kind = "turbine", Price = 3700000000000,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 38.2, Power = 192, AccelTime = 1}},
	engine_cryo = {Slot = "Engine", Name = "Cryo Compressor", Model = "EngineCryo", Rarity = "Uncommon", Band = 7, Role = "A", Theme = "Absolute Zero", Kind = "industrial", Price = 5100000000000,
		Desc = "Heavy torque and big clearing power, slower to speed up.", Stats = {Speed = 28.7, Power = 356, AccelTime = 2.1}},
	engine_polar = {Slot = "Engine", Name = "Polar Turbine", Model = "EnginePolar", Rarity = "Epic", Band = 7, Role = "B", Theme = "Absolute Zero", Kind = "turbine", Price = 130000000000000,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 38.7, Power = 441, AccelTime = 1}},
	engine_zerocore = {Slot = "Engine", Name = "Absolute Zero Core", Model = "EngineZeroCore", Rarity = "Legendary", Band = 7, Role = "C", Theme = "Absolute Zero", Kind = "core", Price = 2e+16,
		Desc = "Energy core: high power and high speed. A legendary saving goal!", Stats = {Speed = 37.7, Power = 862, AccelTime = 1.25}},
	engine_lanterntwin = {Slot = "Engine", Name = "Lantern Twin", Model = "EngineLanternTwin", Rarity = "Rare", Band = 8, Role = "A", Theme = "Sakura Garden", Kind = "twin", Price = 180000000000000,
		Desc = "Twin cylinders: balanced power and speed.", Stats = {Speed = 32.1, Power = 573, AccelTime = 1.5}},
	engine_blossom = {Slot = "Engine", Name = "Blossom Turbine", Model = "EngineBlossom", Rarity = "Epic", Band = 8, Role = "B", Theme = "Sakura Garden", Kind = "turbine", Price = 8.1e+15,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 39.1, Power = 837, AccelTime = 1}},
	engine_gumdrop = {Slot = "Engine", Name = "Gumdrop Motor", Model = "EngineGumdrop", Rarity = "Rare", Band = 9, Role = "A", Theme = "Candy Kingdom", Kind = "compact", Price = 1.1e+16,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 28.6, Power = 948, AccelTime = 1.2}},
	engine_sugarv8 = {Slot = "Engine", Name = "Sugar Rush V8", Model = "EngineSugarV8", Rarity = "Epic", Band = 9, Role = "B", Theme = "Candy Kingdom", Kind = "twin", Price = 5.1e+16,
		Desc = "Twin cylinders: balanced power and speed. Premium part for its world.", Stats = {Speed = 34.6, Power = 1750, AccelTime = 1.5}},
	engine_bubble = {Slot = "Engine", Name = "Bubble Pump", Model = "EngineBubble", Rarity = "Rare", Band = 10, Role = "A", Theme = "Sunken Atlantis", Kind = "compact", Price = 6.9e+16,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 29.1, Power = 1660, AccelTime = 1.2}},
	engine_leviathan = {Slot = "Engine", Name = "Leviathan Turbine", Model = "EngineLeviathan", Rarity = "Legendary", Band = 10, Role = "B", Theme = "Sunken Atlantis", Kind = "turbine", Price = 1.5e+17,
		Desc = "High top speed and instant spin-up, a little less power. A legendary saving goal!", Stats = {Speed = 40, Power = 2640, AccelTime = 1}},
	engine_windup = {Slot = "Engine", Name = "Wind-up Motor", Model = "EngineWindup", Rarity = "Rare", Band = 11, Role = "A", Theme = "Giant Toybox", Kind = "clockwork", Price = 2e+17,
		Desc = "Wind-up power with smooth acceleration.", Stats = {Speed = 32.5, Power = 3190, AccelTime = 1.4}},
	engine_jackbox = {Slot = "Engine", Name = "Jack-in-the-Box Engine", Model = "EngineJackbox", Rarity = "Legendary", Band = 11, Role = "B", Theme = "Giant Toybox", Kind = "industrial", Price = 6.8e+17,
		Desc = "Heavy torque and big clearing power, slower to speed up. A legendary saving goal!", Stats = {Speed = 32.5, Power = 6150, AccelTime = 2.1}},
	engine_pocketwatch = {Slot = "Engine", Name = "Pocketwatch Engine", Model = "EnginePocketwatch", Rarity = "Rare", Band = 12, Role = "A", Theme = "Clockwork City", Kind = "clockwork", Price = 9.3e+17,
		Desc = "Wind-up power with smooth acceleration.", Stats = {Speed = 33, Power = 5420, AccelTime = 1.4}},
	engine_grandclock = {Slot = "Engine", Name = "Grand Clockwork Core", Model = "EngineGrandClock", Rarity = "Legendary", Band = 12, Role = "B", Theme = "Clockwork City", Kind = "clockwork", Price = 6.4e+18,
		Desc = "Wind-up power with smooth acceleration. A legendary saving goal!", Stats = {Speed = 35, Power = 9220, AccelTime = 1.4}},
	engine_breeze = {Slot = "Engine", Name = "Breeze Turbine", Model = "EngineBreeze", Rarity = "Epic", Band = 13, Role = "A", Theme = "Cloud Kingdom", Kind = "turbine", Price = 8.7e+18,
		Desc = "High top speed and instant spin-up, a little less power.", Stats = {Speed = 39.4, Power = 7400, AccelTime = 1}},
	engine_storm = {Slot = "Engine", Name = "Storm Engine", Model = "EngineStorm", Rarity = "Legendary", Band = 13, Role = "B", Theme = "Cloud Kingdom", Kind = "core", Price = 5.7e+19,
		Desc = "Energy core: high power and high speed. A legendary saving goal!", Stats = {Speed = 39.4, Power = 16000, AccelTime = 1.25}},
	engine_stardrive = {Slot = "Engine", Name = "Star Drive", Model = "EngineStarDrive", Rarity = "Epic", Band = 14, Role = "A", Theme = "Cosmic Sanctuary", Kind = "core", Price = 7.8e+19,
		Desc = "Energy core: high power and high speed.", Stats = {Speed = 37.9, Power = 15000, AccelTime = 1.25}},
	engine_nebula = {Slot = "Engine", Name = "Nebula Reactor", Model = "EngineNebula", Rarity = "Legendary", Band = 14, Role = "B", Theme = "Cosmic Sanctuary", Kind = "core", Price = 1.1e+20,
		Desc = "Energy core: high power and high speed. A legendary saving goal!", Stats = {Speed = 39.9, Power = 26000, AccelTime = 1.25}},
	gear_wheels = {Slot = "Gear", Name = "Snow Wheels", Model = "GearWheels", Rarity = "Starter", Band = 1, Role = "S", Theme = "Snowy Starter", Kind = "smalltires", Price = 0,
		Desc = "Fast and nimble, but they slide. Free and always yours.", Stats = {SpeedMult = 1, Traction = 0.55, Turn = 1, Pivot = 0.15, Stability = 1, PowerMult = 1}},
	gear_chunky = {Slot = "Gear", Name = "Chunky Snow Tires", Model = "GearChunky", Rarity = "Common", Band = 1, Role = "A", Theme = "Snowy Starter", Kind = "bigtires", Price = 220,
		Desc = "Chunky grip and stability with a small push bonus.", Stats = {SpeedMult = 0.95, Traction = 0.72, Turn = 0.9, Pivot = 0.2, Stability = 1.35, PowerMult = 1.05}},
	gear_tracks = {Slot = "Gear", Name = "Tracked Treads", Model = "GearTracks", Rarity = "Uncommon", Band = 1, Role = "C", Theme = "Snowy Starter", Kind = "tracks", Price = 650,
		Desc = "Grippy tracks that turn on the spot and push harder.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 1.15}},
	gear_balloon = {Slot = "Gear", Name = "Dune Balloon Tires", Model = "GearBalloon", Rarity = "Common", Band = 2, Role = "A", Theme = "Desert", Kind = "flotation", Price = 1500,
		Desc = "Balloon tires float on soft snow: stable with extra push.", Stats = {SpeedMult = 0.95, Traction = 0.66, Turn = 0.95, Pivot = 0.25, Stability = 1.6, PowerMult = 1.2}},
	gear_sandcrawler = {Slot = "Gear", Name = "Sandcrawler Tracks", Model = "GearSandcrawler", Rarity = "Rare", Band = 2, Role = "B", Theme = "Desert", Kind = "widetracks", Price = 660000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. Premium part for its world.", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 1.49}},
	gear_bonewheels = {Slot = "Gear", Name = "Spiked Bone Wheels", Model = "GearBoneWheels", Rarity = "Uncommon", Band = 3, Role = "A", Theme = "Cursed", Kind = "studded", Price = 900000,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 1.2}},
	gear_haunted = {Slot = "Gear", Name = "Haunted Treads", Model = "GearHaunted", Rarity = "Rare", Band = 3, Role = "B", Theme = "Cursed", Kind = "tracks", Price = 240000000,
		Desc = "Grippy tracks that turn on the spot and push harder. Premium part for its world.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 1.48}},
	gear_crystalstud = {Slot = "Gear", Name = "Crystal Studded Tires", Model = "GearCrystalStud", Rarity = "Uncommon", Band = 4, Role = "A", Theme = "Crystal Caves", Kind = "studded", Price = 330000000,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 1.29}},
	gear_geodetracks = {Slot = "Gear", Name = "Geode Tracks", Model = "GearGeodeTracks", Rarity = "Rare", Band = 4, Role = "B", Theme = "Crystal Caves", Kind = "compacttracks", Price = 57000000000,
		Desc = "Compact tracks: spin on the spot, very agile. Premium part for its world.", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 1.51}},
	gear_pixelwheels = {Slot = "Gear", Name = "Pixel Wheels", Model = "GearPixelWheels", Rarity = "Uncommon", Band = 5, Role = "A", Theme = "Retro World", Kind = "pixel", Price = 78000000000,
		Desc = "Blocky wheels: light and nimble.", Stats = {SpeedMult = 1, Traction = 0.7, Turn = 1.05, Pivot = 0.35, Stability = 1.1, PowerMult = 1.31}},
	gear_hoverpods = {Slot = "Gear", Name = "Arcade Hover Pods", Model = "GearHoverPods", Rarity = "Epic", Band = 5, Role = "B", Theme = "Retro World", Kind = "hover", Price = 350000000000,
		Desc = "Hover pods: fast and spin on the spot, but little grip. Premium part for its world.", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 1.44}},
	gear_mudder = {Slot = "Gear", Name = "Mudder Tires", Model = "GearMudder", Rarity = "Uncommon", Band = 6, Role = "A", Theme = "Jungle", Kind = "bigtires", Price = 480000000000,
		Desc = "Chunky grip and stability with a small push bonus.", Stats = {SpeedMult = 0.95, Traction = 0.72, Turn = 0.9, Pivot = 0.2, Stability = 1.35, PowerMult = 1.47}},
	gear_vinecrawler = {Slot = "Gear", Name = "Vine Crawler Tracks", Model = "GearVineCrawler", Rarity = "Epic", Band = 6, Role = "B", Theme = "Jungle", Kind = "widetracks", Price = 3700000000000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. Premium part for its world.", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 1.95}},
	gear_skis = {Slot = "Gear", Name = "Frost Runners", Model = "GearSkis", Rarity = "Uncommon", Band = 7, Role = "A", Theme = "Absolute Zero", Kind = "skis", Price = 5100000000000,
		Desc = "Ski runners: the fastest glide, very slippery.", Stats = {SpeedMult = 1.15, Traction = 0.42, Turn = 1.1, Pivot = 0.1, Stability = 1.1, PowerMult = 1.46}},
	gear_glaciertracks = {Slot = "Gear", Name = "Glacier Tracks", Model = "GearGlacierTracks", Rarity = "Epic", Band = 7, Role = "B", Theme = "Absolute Zero", Kind = "widetracks", Price = 130000000000000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. Premium part for its world.", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 2.08}},
	gear_zerog = {Slot = "Gear", Name = "Zero-G Hover Rig", Model = "GearZeroG", Rarity = "Legendary", Band = 7, Role = "C", Theme = "Absolute Zero", Kind = "hover", Price = 2e+16,
		Desc = "Hover pods: fast and spin on the spot, but little grip. A legendary saving goal!", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 1.69}},
	gear_bamboo = {Slot = "Gear", Name = "Bamboo Wheels", Model = "GearBamboo", Rarity = "Rare", Band = 8, Role = "A", Theme = "Sakura Garden", Kind = "smalltires", Price = 180000000000000,
		Desc = "Nimble and fast, but slides in turns.", Stats = {SpeedMult = 1, Traction = 0.55, Turn = 1, Pivot = 0.15, Stability = 1, PowerMult = 1.54}},
	gear_petalglide = {Slot = "Gear", Name = "Petal Glide Runners", Model = "GearPetalGlide", Rarity = "Epic", Band = 8, Role = "B", Theme = "Sakura Garden", Kind = "skis", Price = 8.1e+15,
		Desc = "Ski runners: the fastest glide, very slippery. Premium part for its world.", Stats = {SpeedMult = 1.15, Traction = 0.42, Turn = 1.1, Pivot = 0.1, Stability = 1.1, PowerMult = 1.75}},
	gear_donut = {Slot = "Gear", Name = "Donut Tires", Model = "GearDonut", Rarity = "Rare", Band = 9, Role = "A", Theme = "Candy Kingdom", Kind = "bigtires", Price = 1.1e+16,
		Desc = "Chunky grip and stability with a small push bonus.", Stats = {SpeedMult = 0.95, Traction = 0.72, Turn = 0.9, Pivot = 0.2, Stability = 1.35, PowerMult = 1.8}},
	gear_gummytreads = {Slot = "Gear", Name = "Gummy Treads", Model = "GearGummyTreads", Rarity = "Epic", Band = 9, Role = "B", Theme = "Candy Kingdom", Kind = "tracks", Price = 5.1e+16,
		Desc = "Grippy tracks that turn on the spot and push harder. Premium part for its world.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 2.21}},
	gear_shell = {Slot = "Gear", Name = "Shell Wheels", Model = "GearShell", Rarity = "Rare", Band = 10, Role = "A", Theme = "Sunken Atlantis", Kind = "studded", Price = 6.9e+16,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 1.93}},
	gear_paddle = {Slot = "Gear", Name = "Paddle Tracks", Model = "GearPaddle", Rarity = "Legendary", Band = 10, Role = "B", Theme = "Sunken Atlantis", Kind = "widetracks", Price = 1.5e+17,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. A legendary saving goal!", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 2.55}},
	gear_toybrick = {Slot = "Gear", Name = "Toy Brick Wheels", Model = "GearToyBrick", Rarity = "Rare", Band = 11, Role = "A", Theme = "Giant Toybox", Kind = "smalltires", Price = 2e+17,
		Desc = "Nimble and fast, but slides in turns.", Stats = {SpeedMult = 1, Traction = 0.55, Turn = 1, Pivot = 0.15, Stability = 1, PowerMult = 1.89}},
	gear_toytank = {Slot = "Gear", Name = "Toy Tank Tracks", Model = "GearToyTank", Rarity = "Legendary", Band = 11, Role = "B", Theme = "Giant Toybox", Kind = "compacttracks", Price = 6.8e+17,
		Desc = "Compact tracks: spin on the spot, very agile. A legendary saving goal!", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 2.42}},
	gear_cogwheels = {Slot = "Gear", Name = "Cog Wheels", Model = "GearCogWheels", Rarity = "Rare", Band = 12, Role = "A", Theme = "Clockwork City", Kind = "studded", Price = 9.3e+17,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 2.21}},
	gear_brasstracks = {Slot = "Gear", Name = "Brass Tracks", Model = "GearBrassTracks", Rarity = "Legendary", Band = 12, Role = "B", Theme = "Clockwork City", Kind = "compacttracks", Price = 6.4e+18,
		Desc = "Compact tracks: spin on the spot, very agile. A legendary saving goal!", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 2.59}},
	gear_cloudpuff = {Slot = "Gear", Name = "Cloud Puff Wheels", Model = "GearCloudPuff", Rarity = "Epic", Band = 13, Role = "A", Theme = "Cloud Kingdom", Kind = "flotation", Price = 8.7e+18,
		Desc = "Balloon tires float on soft snow: stable with extra push.", Stats = {SpeedMult = 0.95, Traction = 0.66, Turn = 0.95, Pivot = 0.25, Stability = 1.6, PowerMult = 2.52}},
	gear_stormpods = {Slot = "Gear", Name = "Storm Hover Pods", Model = "GearStormPods", Rarity = "Legendary", Band = 13, Role = "B", Theme = "Cloud Kingdom", Kind = "hover", Price = 5.7e+19,
		Desc = "Hover pods: fast and spin on the spot, but little grip. A legendary saving goal!", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 2.47}},
	gear_orbit = {Slot = "Gear", Name = "Orbit Rings", Model = "GearOrbit", Rarity = "Epic", Band = 14, Role = "A", Theme = "Cosmic Sanctuary", Kind = "rings", Price = 7.8e+19,
		Desc = "Orbit rings: fast, agile and grippy.", Stats = {SpeedMult = 1.05, Traction = 0.8, Turn = 1.1, Pivot = 0.6, Stability = 1.3, PowerMult = 2.55}},
	gear_meteor = {Slot = "Gear", Name = "Meteor Treads", Model = "GearMeteor", Rarity = "Legendary", Band = 14, Role = "B", Theme = "Cosmic Sanctuary", Kind = "widetracks", Price = 1.1e+20,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. A legendary saving goal!", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 3.35}},
}
for id, def in pairs(C.Parts) do def.Id = id; def.Weight = def.Role == "S" and 0 or 1 end -- Weight kept for older readers; odds come from C.OfferPool

-- progression bands = field stages in unlock order
C.Bands = {"Starter", "Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Sakura", "Candy", "Atlantis", "Toybox", "Clockwork", "Cloud", "Cosmic"}
C.BandOfStage = {}
for i, s in ipairs(C.Bands) do C.BandOfStage[s] = i end
-- field toughness 0 (soft powder) .. 1 (hard ice): blade efficiency = Soft + (Hard - Soft) x toughness
C.Toughness = {Starter = 0.05, Desert = 0.2, Cursed = 0.55, Crystal = 0.9, Retro = 0.75, Jungle = 0.3, AbsoluteZero = 0.95, Sakura = 0.15, Candy = 0.5, Atlantis = 0.4, Toybox = 0.65, Clockwork = 0.85, Cloud = 0.1, Cosmic = 0.7}
-- OFFER POOL: relevance to the player's progression band x role weight x luck (rare parts only). The practical group (Common-role parts of
-- the current and previous band) always keeps at least PracticalFloor of the total, so luck can never push practical upgrades out.
C.Offers = {
	Relevance = {[-3] = 0.04, [-2] = 0.2, [-1] = 0.85, [0] = 1, [1] = 0.5, [2] = 0.16, [3] = 0.05}, -- by (part band - player band); older than -3: 0.04; newer than +3: never offered
	RoleWeight = {A = 1.0, B = 0.42, C = 0.16},
	PracticalFloor = 0.45,
	LuckSlope = 0.25, LuckCap = 2.0, -- luck factor = min(LuckCap, 1 + LuckSlope x log2(luck)); applied as factor^(rank - 3) to Rare+ parts
}
function C.LuckFactor(luck)
	luck = math.max(1, tonumber(luck) or 1)
	return math.min(C.Offers.LuckCap, 1 + C.Offers.LuckSlope * math.log(luck, 2))
end
function C.OfferPool(band, luck)
	band = math.clamp(math.floor(tonumber(band) or 1), 1, #C.Bands)
	local lf, O = C.LuckFactor(luck), C.Offers
	local list, total, prac = {}, 0, 0
	for id, def in pairs(C.Parts) do
		if def.Role ~= "S" then
			local d = def.Band - band
			local rel = O.Relevance[d] or (d < -3 and 0.04 or 0)
			if rel > 0 then
				local rank = C.RarityRank[def.Rarity] or 2
				local w = rel * (O.RoleWeight[def.Role] or 1) * lf ^ math.max(0, rank - 3)
				local practical = def.Role == "A" and (d == 0 or d == -1)
				table.insert(list, {Id = id, W = w, Practical = practical, Rank = rank})
				total += w
				if practical then prac += w end
			end
		end
	end
	if prac > 0 and prac / total < O.PracticalFloor then
		local s = O.PracticalFloor * (total - prac) / ((1 - O.PracticalFloor) * prac)
		total = 0
		for _, e in ipairs(list) do if e.Practical then e.W *= s end total += e.W end
	end
	table.sort(list, function(a, b)
		if a.Rank ~= b.Rank then return a.Rank < b.Rank end
		local da, db = C.Parts[a.Id].Band, C.Parts[b.Id].Band
		if da ~= db then return da < db end
		return a.Id < b.Id
	end)
	for _, e in ipairs(list) do e.P = e.W / total end
	return list
end
-- player band from a stage set ({[stageId] = true}); Sakura opens with the Portal
function C.BandFrom(stages)
	local best = 1
	for i, s in ipairs(C.Bands) do
		if s == "Starter" or (stages and (stages[s] or (s == "Sakura" and stages.Portal))) then best = math.max(best, i) end
	end
	return best
end

C.Drive = {
	AccelTime = 1.6,       -- default seconds from standstill to top speed (engines set their own AccelTime)
	ReverseFactor = 0.55,  -- reverse top speed vs forward
	BrakeFactor = 1.8,     -- braking / changing direction is this much stronger than accelerating
	TurnRate = 1.6,        -- rad/s at full steering (x gear Turn); 2026-10-05: was 2.0 - calmer, car-like turns
	MinTurn = 0,           -- steering strength at a standstill for gears without Pivot (car-like: wheels need speed to turn; Pivot gears still spin on the spot)
	LateralGrip = 18,      -- sideways-slide damping per second at Traction 1 (2026-10-05: doubled - grips like a car instead of sliding)
	TurnSpeedFull = 0.3,   -- steering reaches full strength at this share of top speed
	HighSpeedTurnLoss = 0.35, -- up to 35% less steering near top speed (wider turns when fast)
	PlowingSpeedFactor = 0.6, -- top speed while the blade is over a snow field (heavy work); full speed on roads and paths
	UprightAssist = 6,     -- how hard the plow rights itself (x gear Stability)
	TopSpeedCap = 60,      -- no build + upgrade combination may exceed this (paths, bridges and the anti-cheat stay valid)
}
C.Vehicle = {
	HullSize = Vector3.new(5.4, 1.6, 7.4), HullClearance = 1.1, -- invisible collision box under the body; 2026-10-05: raised so the suspension rolls over steps up to ~1 stud
	RideStiffness = 14, RideMaxRise = 22, RideMaxFall = 40, RideReach = 4.5, -- client raycast suspension (PlowDriveClient) keeps the box HullClearance above the ground
	BladeOffset = 6.2,     -- blade footprint centre in front of the hull centre (studs)
	SpawnAhead = 10, RecoverCooldown = 3.5, MaxRiderGap = 16, BoundsY = -150,
}
C.Clearing = {
	BasePower = 4.5,       -- damage per second the Starter loadout deals to every tile under its blade (field HP is in ReplicatedStorage.SnowStages)
	BladeDepth = 2.6,      -- front-to-back size of the blade footprint (studs)
	TileSlack = 0.3,       -- a tile counts as touched when its centre is within footprint + slack x tile size
	SpeedTolerance = 1.6,  -- the server ignores clearing while the plow moves faster than MaxSpeed x this + 8 studs/s
	MaxWidthMult = 1.6,    -- cap for blade width bonuses from upgrades
	ToughLow = 0.3, ToughSpan = 3.0, -- fallback toughness for fields without a C.Toughness entry: clamp((log10(tile HP) - ToughLow) / ToughSpan, 0, 1)
}
function C.ToughnessOf(stageId, tileHP)
	local t = C.Toughness[stageId or ""]
	if t then return t end
	return math.clamp((math.log10(math.max(1, tileHP or 1)) - C.Clearing.ToughLow) / C.Clearing.ToughSpan, 0, 1)
end

-- Upgrade mapping: PowerMult/PowerBonus/SpinMult -> clearing power; SizeMult/ReachMult -> blade width.
-- Width above the safe cap becomes proportional clearing power, so every width purchase remains useful.
-- LuckMult -> offer luck; RollCooldownMult -> pedestal cooldown; WalkSpeed -> vehicle speed (half strength).
local function num(x, d) x = tonumber(x); if not x or x ~= x or x == math.huge or x == -math.huge then return d end return x end
function C.StatsFor(build, mods)
	build, mods = build or {}, mods or {}
	local blade, engine, gear = C.Parts[build.Blade or ""], C.Parts[build.Engine or ""], C.Parts[build.Gear or ""]
	if blade and blade.Slot ~= "Blade" then blade = nil end
	if engine and engine.Slot ~= "Engine" then engine = nil end
	if gear and gear.Slot ~= "Gear" then gear = nil end
	local bs = blade and blade.Stats or {Width = 0, Soft = 0, Hard = 0}
	local es = engine and engine.Stats or {Speed = 0, Power = 0, AccelTime = C.Drive.AccelTime}
	local gs = gear and gear.Stats or {SpeedMult = 0, Traction = 0, Turn = 0, Pivot = 0, Stability = 1, PowerMult = 1}
	local rawWidthMult = math.max(1, num(mods.SizeMult, 1) * num(mods.ReachMult, 1))
	local widthMult = math.min(rawWidthMult, C.Clearing.MaxWidthMult)
	local widthPower = math.max(1, rawWidthMult / C.Clearing.MaxWidthMult)
	local power = (C.Clearing.BasePower * es.Power * gs.PowerMult + num(mods.PowerBonus, 0) * C.Clearing.BasePower) * num(mods.PowerMult, 1) * num(mods.SpinMult, 1) * widthPower
	local top = math.min(C.Drive.TopSpeedCap, es.Speed * gs.SpeedMult * num(mods.SpeedMult, 1))
	local accelTime = math.max(0.5, num(es.AccelTime, C.Drive.AccelTime))
	return {
		Valid = engine ~= nil and gear ~= nil, HasBlade = blade ~= nil,
		MaxSpeed = top, Accel = top / accelTime, AccelTime = accelTime, TurnRate = C.Drive.TurnRate * gs.Turn, Turn = gs.Turn, Pivot = gs.Pivot,
		Traction = gs.Traction, Stability = gs.Stability,
		BladeWidth = bs.Width * widthMult, Soft = bs.Soft, Hard = bs.Hard, ClearPower = (blade and power or 0),
	}
end

-- productive clearing estimate on a stage (layers per second), used for "useful offer" checks and the card comparisons.
-- power-limited rate vs coverage-limited rate (blade width x productive speed), blended with a smooth minimum.
function C.StageHP(stageId)
	local f = RS:FindFirstChild("SnowStages")
	local s = f and f:FindFirstChild(stageId or "")
	return math.max(1, num(s and s:GetAttribute("TileHP"), 1))
end
function C.Score(stats, stageId, tileHP)
	if not stats or not stats.HasBlade or stats.ClearPower <= 0 then return 0 end
	tileHP = tileHP or C.StageHP(stageId)
	local tile, slack = 3, 0.9
	local w = stats.BladeWidth + 2 * slack
	local tough = C.ToughnessOf(stageId, tileHP)
	local eff = stats.Soft + (stats.Hard - stats.Soft) * tough
	local power = (w / tile) * ((C.Clearing.BladeDepth + 2 * slack) / tile) * stats.ClearPower * eff / tileHP
	local handling = 0.42 + 0.32 * stats.Traction + 0.14 * math.min(stats.Pivot, 1) + 0.06 * math.min(stats.Turn or 1, 1.2) / 1.2
	handling = math.clamp(handling - math.min(0.12, 0.6 / math.max(stats.Accel, 1e-6)), 0.3, 0.9)
	local cover = 3 * (w / tile) * (stats.MaxSpeed * handling) / tile
	if power <= 0 or cover <= 0 then return 0 end
	return (power ^ -4 + cover ^ -4) ^ (-1 / 4)
end
return C
