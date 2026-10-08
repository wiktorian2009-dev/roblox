-- PlowConfig: the SNOWPLOW core loop. Parts, odds, prices, cooldowns and vehicle balance all live HERE.
--   ROLL a part offer in the garage -> BUY it with Snow (or RESERVE it) -> EQUIP blade / engine / running gear -> DRIVE through the fields
--   -> earn Snow + treasures -> improve the vehicle -> unlock stages (rebirths were removed on 2026-10-06).
-- 2026-10-05 (Claude): 135-part catalog (45 blades, 45 engines, 45 running gear), progression-aware offer pool with luck that never removes
-- practical parts, bad-luck protection, engine acceleration, explicit field toughness.
-- REBALANCE 2026-10-05: role M = mid-band step between a world's practical A part and its premium B part; blades and gears now grow
-- enough per world to be meaningful upgrades. The parts table is generated from outputs/Rebalance20261005/sim (catalog_spec2 +
-- catalog2 + final_variant.json -> gen_lua2.py, which splices it into this file); regenerate there instead of hand-editing prices.
-- Mode is a fixed identifier used by the existing client/state contract, not a runtime gameplay switch.
local RS = game:GetService("ReplicatedStorage")
local C = {}
C.Mode = "Snowplow" -- fixed current gameplay identifier

C.Shop = {
	RollCooldown = 2.0,   -- base seconds between offer rolls; multiplied by RollCooldownMult (rerolls share the cooldown)
	-- 2026-10-06: a pedestal offer lasts this long (server time) - RESERVE a part to keep it. The timer only runs while you are in the
	-- garage and have finished the tutorial; a bad-luck-protection offer lasts longer, and if it runs out the next roll is protected again.
	OfferSeconds = 30, ProtectedOfferSeconds = 60,
	MinRollCooldownMult = 0.6, -- offer-speed tiles can shorten the base cooldown by at most 40%
	BigRevealRank = 4,    -- rarity rank (Rare = 4) that gets the stronger reveal
	MaxOwned = 99,
	ProtectAfter = 15,    -- bad-luck protection: after 15 rolls in a row without a USEFUL offer, the next roll is drawn only from useful parts (was 6; 2026-10-06 rarer good parts)
	ProtectAffordMinutes = 10, -- rebalance: ...preferring useful parts affordable from Snow in hand + this many minutes of recent Snow/s
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
C.Slots = {"Blade", "Engine", "Gear", "Body"} -- 2026-10-05 (task 7): Body = replaceable visual shell on the invariant chassis frame
C.Starter = {Blade = "blade_basic", Engine = "engine_starter", Gear = "gear_wheels", Body = "body_starter"} -- free, owned by everyone, can never be lost

-- Price = explicit Snow cost (never depends on the wallet; an offer keeps the price it was rolled with).
-- Band = progression theme (1 Starter ... 7 Absolute Zero, 8 Sakura ... 14 Cosmic). Role: S starter, A practical, M mid-band step, B premium, C legendary.
-- Blade: Width (studs), Soft / Hard = clearing multiplier on soft / hard snow (blended by the field's toughness).
-- Engine: Speed (studs/s), Power (clearing power multiplier), AccelTime (seconds from standstill to top speed).
-- Gear: SpeedMult, Traction (less sliding), Turn, Pivot (turning on the spot), Stability (stays upright), PowerMult (pushing power).
C.Parts = {
	blade_basic = {Slot = "Blade", Name = "Basic Blade", Model = "BladeBasic", Rarity = "Starter", Band = 1, Role = "S", Theme = "Snowy Starter", Kind = "straight", Price = 0,
		Desc = "A sturdy steel blade. Free and always yours.", Stats = {Width = 7, Soft = 1, Hard = 1}},
	blade_wide = {Slot = "Blade", Name = "Wide Clearing Blade", Model = "BladeWide", Rarity = "Common", Band = 1, Role = "A", Theme = "Snowy Starter", Kind = "sweeper", Price = 120,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12, Soft = 1.14, Hard = 0.744}},
	blade_frost_scoop = {Slot = "Blade", Name = "Frosty Scoop", Model = "BladeFrostScoop", Rarity = "Uncommon", Band = 1, Role = "C", Theme = "Snowy Starter", Kind = "scoop", Price = 650,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 8.5, Soft = 1.07, Hard = 0.91}},
	blade_dune = {Slot = "Blade", Name = "Dune Sweeper", Model = "BladeDune", Rarity = "Common", Band = 2, Role = "A", Theme = "Desert", Kind = "sweeper", Price = 1600,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 11, Soft = 1.36, Hard = 0.885}},
	blade_ice = {Slot = "Blade", Name = "Reinforced Icebreaker", Model = "BladeIce", Rarity = "Rare", Band = 2, Role = "B", Theme = "Desert", Kind = "icebreaker", Price = 2800,
		Desc = "Narrow armoured edge that smashes hard ice. Premium part for its world.", Stats = {Width = 8.5, Soft = 1.28, Hard = 1.94}},
	blade_grave = {Slot = "Blade", Name = "Grave Digger", Model = "BladeGrave", Rarity = "Uncommon", Band = 3, Role = "A", Theme = "Cursed", Kind = "toothed", Price = 26000,
		Desc = "Teeth bite into hard ice; weaker in soft powder.", Stats = {Width = 9, Soft = 1.29, Hard = 1.76}},
	blade_bonechill = {Slot = "Blade", Name = "Bonechill Scoop", Model = "BladeBonechill", Rarity = "Uncommon", Band = 3, Role = "M", Theme = "Cursed", Kind = "scoop", Price = 180000,
		Desc = "Curved scoop: wide and good in soft snow. A solid step up between its world's starter and premium parts.", Stats = {Width = 9.5, Soft = 1.69, Hard = 1.44}},
	blade_hex = {Slot = "Blade", Name = "Hex Breaker", Model = "BladeHex", Rarity = "Rare", Band = 3, Role = "B", Theme = "Cursed", Kind = "vshape", Price = 1200000,
		Desc = "V-wedge that splits tough snow - great on hard fields. Premium part for its world.", Stats = {Width = 9.5, Soft = 1.65, Hard = 2.09}},
	blade_quartz = {Slot = "Blade", Name = "Quartz Edge", Model = "BladeQuartz", Rarity = "Uncommon", Band = 4, Role = "A", Theme = "Crystal Caves", Kind = "segmented", Price = 1600000,
		Desc = "Segmented plates: steady all-rounder with a hard-ice edge.", Stats = {Width = 10, Soft = 1.69, Hard = 1.83}},
	blade_geodeshovel = {Slot = "Blade", Name = "Geode Shovelhead", Model = "BladeGeodeShovel", Rarity = "Uncommon", Band = 4, Role = "M", Theme = "Crystal Caves", Kind = "segmented", Price = 3500000,
		Desc = "Segmented plates: steady all-rounder with a hard-ice edge. A solid step up between its world's starter and premium parts.", Stats = {Width = 9.5, Soft = 1.81, Hard = 1.96}},
	blade_amethyst = {Slot = "Blade", Name = "Amethyst Wedge", Model = "BladeAmethyst", Rarity = "Rare", Band = 4, Role = "M", Theme = "Crystal Caves", Kind = "vshape", Price = 7500000,
		Desc = "V-wedge that splits tough snow - great on hard fields. A solid step up between its world's starter and premium parts.", Stats = {Width = 9, Soft = 1.83, Hard = 2.32}},
	blade_prism = {Slot = "Blade", Name = "Prism Cleaver", Model = "BladePrism", Rarity = "Rare", Band = 4, Role = "B", Theme = "Crystal Caves", Kind = "crystal", Price = 16000000,
		Desc = "Crystal edge: excellent on hard ice. Premium part for its world.", Stats = {Width = 8.5, Soft = 1.9, Hard = 2.7}},
	blade_pixel = {Slot = "Blade", Name = "Pixel Pusher", Model = "BladePixel", Rarity = "Uncommon", Band = 5, Role = "A", Theme = "Retro World", Kind = "pixel", Price = 22000000,
		Desc = "Blocky and wide: strong in soft snow.", Stats = {Width = 11, Soft = 2.14, Hard = 1.91}},
	blade_joystick = {Slot = "Blade", Name = "Joystick Sweeper", Model = "BladeJoystick", Rarity = "Rare", Band = 5, Role = "M", Theme = "Retro World", Kind = "pixel", Price = 58000000,
		Desc = "Blocky and wide: strong in soft snow. A solid step up between its world's starter and premium parts.", Stats = {Width = 11, Soft = 2.39, Hard = 2.13}},
	blade_arcade = {Slot = "Blade", Name = "Arcade Plow", Model = "BladeArcade", Rarity = "Epic", Band = 5, Role = "B", Theme = "Retro World", Kind = "segmented", Price = 160000000,
		Desc = "Segmented plates: steady all-rounder with a hard-ice edge. Premium part for its world.", Stats = {Width = 9.5, Soft = 2.49, Hard = 2.7}},
	blade_vine = {Slot = "Blade", Name = "Vine Sweeper", Model = "BladeVine", Rarity = "Uncommon", Band = 6, Role = "A", Theme = "Jungle", Kind = "sweeper", Price = 210000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12, Soft = 2.72, Hard = 1.77}},
	blade_canopy = {Slot = "Blade", Name = "Canopy Scoop", Model = "BladeCanopy", Rarity = "Rare", Band = 6, Role = "M", Theme = "Jungle", Kind = "scoop", Price = 450000000,
		Desc = "Curved scoop: wide and good in soft snow. A solid step up between its world's starter and premium parts.", Stats = {Width = 11, Soft = 2.84, Hard = 2.42}},
	blade_tusk = {Slot = "Blade", Name = "Tusk Breaker", Model = "BladeTusk", Rarity = "Epic", Band = 6, Role = "B", Theme = "Jungle", Kind = "toothed", Price = 970000000,
		Desc = "Teeth bite into hard ice; weaker in soft powder. Premium part for its world.", Stats = {Width = 8.5, Soft = 2.7, Hard = 3.67}},
	blade_glacier = {Slot = "Blade", Name = "Glacier Plow", Model = "BladeGlacier", Rarity = "Uncommon", Band = 7, Role = "A", Theme = "Absolute Zero", Kind = "scoop", Price = 1300000000,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 10.5, Soft = 3.04, Hard = 2.59}},
	blade_frostbite = {Slot = "Blade", Name = "Frostbite Cleaver", Model = "BladeFrostbite", Rarity = "Rare", Band = 7, Role = "M", Theme = "Absolute Zero", Kind = "icebreaker", Price = 2600000000,
		Desc = "Narrow armoured edge that smashes hard ice. A solid step up between its world's starter and premium parts.", Stats = {Width = 8.5, Soft = 2.64, Hard = 4.01}},
	blade_polar = {Slot = "Blade", Name = "Polar Sweeper", Model = "BladePolar", Rarity = "Epic", Band = 7, Role = "M", Theme = "Absolute Zero", Kind = "sweeper", Price = 5200000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice. A solid step up between its world's starter and premium parts.", Stats = {Width = 12, Soft = 3.73, Hard = 2.44}},
	blade_zero = {Slot = "Blade", Name = "Absolute Edge", Model = "BladeZero", Rarity = "Epic", Band = 7, Role = "B", Theme = "Absolute Zero", Kind = "icebreaker", Price = 10000000000,
		Desc = "Narrow armoured edge that smashes hard ice. Premium part for its world.", Stats = {Width = 8.5, Soft = 3.05, Hard = 4.63}},
	blade_singularity = {Slot = "Blade", Name = "Zero Point Blade", Model = "BladeSingularity", Rarity = "Legendary", Band = 7, Role = "C", Theme = "Absolute Zero", Kind = "vshape", Price = 200000000000,
		Desc = "V-wedge that splits tough snow - great on hard fields. A legendary saving goal!", Stats = {Width = 10.5, Soft = 3.51, Hard = 4.44}},
	blade_petal = {Slot = "Blade", Name = "Petal Sweeper", Model = "BladePetal", Rarity = "Rare", Band = 8, Role = "A", Theme = "Sakura Garden", Kind = "sweeper", Price = 14000000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12.5, Soft = 3.85, Hard = 2.51}},
	blade_lotus = {Slot = "Blade", Name = "Lotus Wedge", Model = "BladeLotus", Rarity = "Epic", Band = 8, Role = "M", Theme = "Sakura Garden", Kind = "vshape", Price = 34000000000,
		Desc = "V-wedge that splits tough snow - great on hard fields. A solid step up between its world's starter and premium parts.", Stats = {Width = 9.5, Soft = 3.54, Hard = 4.48}},
	blade_katana = {Slot = "Blade", Name = "Katana Blade", Model = "BladeKatana", Rarity = "Epic", Band = 8, Role = "B", Theme = "Sakura Garden", Kind = "straight", Price = 81000000000,
		Desc = "Dependable all-rounder: the same on soft powder and hard ice. Premium part for its world.", Stats = {Width = 9, Soft = 4.2, Hard = 4.2}},
	blade_lollipop = {Slot = "Blade", Name = "Lollipop Scoop", Model = "BladeLollipop", Rarity = "Rare", Band = 9, Role = "A", Theme = "Candy Kingdom", Kind = "scoop", Price = 110000000000,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 10.5, Soft = 4.3, Hard = 3.66}},
	blade_gumdrop = {Slot = "Blade", Name = "Gumdrop Sweeper", Model = "BladeGumdrop", Rarity = "Rare", Band = 9, Role = "M", Theme = "Candy Kingdom", Kind = "sweeper", Price = 180000000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice. A solid step up between its world's starter and premium parts.", Stats = {Width = 11.5, Soft = 4.92, Hard = 3.21}},
	blade_taffy = {Slot = "Blade", Name = "Taffy Breaker", Model = "BladeTaffy", Rarity = "Epic", Band = 9, Role = "M", Theme = "Candy Kingdom", Kind = "toothed", Price = 280000000000,
		Desc = "Teeth bite into hard ice; weaker in soft powder. A solid step up between its world's starter and premium parts.", Stats = {Width = 9, Soft = 4.23, Hard = 5.76}},
	blade_canecrusher = {Slot = "Blade", Name = "Candy Cane Crusher", Model = "BladeCaneCrusher", Rarity = "Epic", Band = 9, Role = "B", Theme = "Candy Kingdom", Kind = "toothed", Price = 440000000000,
		Desc = "Teeth bite into hard ice; weaker in soft powder. Premium part for its world.", Stats = {Width = 9.5, Soft = 4.54, Hard = 6.19}},
	blade_coral = {Slot = "Blade", Name = "Coral Scoop", Model = "BladeCoral", Rarity = "Rare", Band = 10, Role = "A", Theme = "Sunken Atlantis", Kind = "scoop", Price = 600000000000,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 11, Soft = 5.12, Hard = 4.36}},
	blade_reef = {Slot = "Blade", Name = "Reef Splitter", Model = "BladeReef", Rarity = "Epic", Band = 10, Role = "M", Theme = "Sunken Atlantis", Kind = "vshape", Price = 770000000000,
		Desc = "V-wedge that splits tough snow - great on hard fields. A solid step up between its world's starter and premium parts.", Stats = {Width = 9.5, Soft = 5.02, Hard = 6.35}},
	blade_trident = {Slot = "Blade", Name = "Trident Breaker", Model = "BladeTrident", Rarity = "Legendary", Band = 10, Role = "B", Theme = "Sunken Atlantis", Kind = "vshape", Price = 990000000000,
		Desc = "V-wedge that splits tough snow - great on hard fields. A legendary saving goal!", Stats = {Width = 9, Soft = 5.59, Hard = 7.07}},
	blade_brick = {Slot = "Blade", Name = "Building Block Blade", Model = "BladeBrick", Rarity = "Rare", Band = 11, Role = "A", Theme = "Giant Toybox", Kind = "segmented", Price = 1400000000000,
		Desc = "Segmented plates: steady all-rounder with a hard-ice edge.", Stats = {Width = 11.5, Soft = 5.7, Hard = 6.18}},
	blade_crayon = {Slot = "Blade", Name = "Crayon Scraper", Model = "BladeCrayon", Rarity = "Epic", Band = 11, Role = "M", Theme = "Giant Toybox", Kind = "straight", Price = 2300000000000,
		Desc = "Dependable all-rounder: the same on soft powder and hard ice. A solid step up between its world's starter and premium parts.", Stats = {Width = 10, Soft = 6.35, Hard = 6.35}},
	blade_bulldozer = {Slot = "Blade", Name = "Toy Bulldozer", Model = "BladeBulldozer", Rarity = "Legendary", Band = 11, Role = "B", Theme = "Giant Toybox", Kind = "straight", Price = 4000000000000,
		Desc = "Dependable all-rounder: the same on soft powder and hard ice. A legendary saving goal!", Stats = {Width = 10, Soft = 7.07, Hard = 7.07}},
	blade_cog = {Slot = "Blade", Name = "Cog Sweeper", Model = "BladeCog", Rarity = "Rare", Band = 12, Role = "A", Theme = "Clockwork City", Kind = "sweeper", Price = 5400000000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 12, Soft = 7.72, Hard = 5.05}},
	blade_piston = {Slot = "Blade", Name = "Piston Scoop", Model = "BladePiston", Rarity = "Rare", Band = 12, Role = "M", Theme = "Clockwork City", Kind = "scoop", Price = 6500000000000,
		Desc = "Curved scoop: wide and good in soft snow. A solid step up between its world's starter and premium parts.", Stats = {Width = 11, Soft = 7.79, Hard = 6.63}},
	blade_sprocket = {Slot = "Blade", Name = "Sprocket Breaker", Model = "BladeSprocket", Rarity = "Epic", Band = 12, Role = "M", Theme = "Clockwork City", Kind = "mechanical", Price = 7800000000000,
		Desc = "Grinding gears chew through hard ice. A solid step up between its world's starter and premium parts.", Stats = {Width = 9.5, Soft = 7.37, Hard = 9.91}},
	blade_gearbreaker = {Slot = "Blade", Name = "Gearbreaker", Model = "BladeGearbreaker", Rarity = "Legendary", Band = 12, Role = "B", Theme = "Clockwork City", Kind = "mechanical", Price = 9500000000000,
		Desc = "Grinding gears chew through hard ice. A legendary saving goal!", Stats = {Width = 9.5, Soft = 7.92, Hard = 10.6}},
	blade_cumulus = {Slot = "Blade", Name = "Cumulus Sweeper", Model = "BladeCumulus", Rarity = "Rare", Band = 13, Role = "A", Theme = "Cloud Kingdom", Kind = "sweeper", Price = 13000000000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice.", Stats = {Width = 13, Soft = 9.19, Hard = 6}},
	blade_rainbow = {Slot = "Blade", Name = "Rainbow Sweeper", Model = "BladeRainbow", Rarity = "Epic", Band = 13, Role = "M", Theme = "Cloud Kingdom", Kind = "sweeper", Price = 14000000000000,
		Desc = "Extra-wide sweep for soft snow; weaker on hard ice. A solid step up between its world's starter and premium parts.", Stats = {Width = 12.5, Soft = 10.2, Hard = 6.69}},
	blade_thunder = {Slot = "Blade", Name = "Thunder Wedge", Model = "BladeThunder", Rarity = "Legendary", Band = 13, Role = "B", Theme = "Cloud Kingdom", Kind = "vshape", Price = 15000000000000,
		Desc = "V-wedge that splits tough snow - great on hard fields. A legendary saving goal!", Stats = {Width = 9.5, Soft = 9.42, Hard = 11.9}},
	blade_comet = {Slot = "Blade", Name = "Comet Scoop", Model = "BladeComet", Rarity = "Epic", Band = 14, Role = "A", Theme = "Cosmic Sanctuary", Kind = "scoop", Price = 20000000000000,
		Desc = "Curved scoop: wide and good in soft snow.", Stats = {Width = 11.5, Soft = 10.3, Hard = 8.74}},
	blade_galaxy = {Slot = "Blade", Name = "Galaxy Breaker", Model = "BladeGalaxy", Rarity = "Legendary", Band = 14, Role = "B", Theme = "Cosmic Sanctuary", Kind = "cosmic", Price = 29000000000000,
		Desc = "Cosmic edge: strong on every kind of snow. A legendary saving goal!", Stats = {Width = 10.5, Soft = 12.9, Hard = 14.2}},
	engine_starter = {Slot = "Engine", Name = "Starter Engine", Model = "EngineStarter", Rarity = "Starter", Band = 1, Role = "S", Theme = "Snowy Starter", Kind = "compact", Price = 0,
		Desc = "Small but reliable. Free and always yours.", Stats = {Speed = 24, Power = 1, AccelTime = 1.6}},
	engine_snowball = {Slot = "Engine", Name = "Snowball Motor", Model = "EngineSnowball", Rarity = "Common", Band = 1, Role = "A", Theme = "Snowy Starter", Kind = "compact", Price = 300,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 25, Power = 1.55, AccelTime = 1.2}},
	engine_balanced = {Slot = "Engine", Name = "Balanced Engine", Model = "EngineBalanced", Rarity = "Uncommon", Band = 1, Role = "C", Theme = "Snowy Starter", Kind = "twin", Price = 450,
		Desc = "Twin cylinders: balanced power and speed.", Stats = {Speed = 30, Power = 2.07, AccelTime = 1.5}},
	engine_sandrunner = {Slot = "Engine", Name = "Sand Runner", Model = "EngineSandRunner", Rarity = "Common", Band = 2, Role = "A", Theme = "Desert", Kind = "turbine", Price = 1600,
		Desc = "High top speed and instant spin-up, a little less power.", Stats = {Speed = 34.5, Power = 1.63, AccelTime = 1}},
	engine_power = {Slot = "Engine", Name = "Powerful Engine", Model = "EnginePower", Rarity = "Rare", Band = 2, Role = "B", Theme = "Desert", Kind = "industrial", Price = 2800,
		Desc = "Heavy torque and big clearing power, slower to speed up. Premium part for its world.", Stats = {Speed = 28.4, Power = 2.31, AccelTime = 2.1}},
	engine_lantern = {Slot = "Engine", Name = "Lantern Motor", Model = "EngineLantern", Rarity = "Uncommon", Band = 3, Role = "A", Theme = "Cursed", Kind = "compact", Price = 26000,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 25.9, Power = 2.7, AccelTime = 1.2}},
	engine_cauldron = {Slot = "Engine", Name = "Cauldron Burner", Model = "EngineCauldron", Rarity = "Uncommon", Band = 3, Role = "M", Theme = "Cursed", Kind = "industrial", Price = 180000,
		Desc = "Heavy torque and big clearing power, slower to speed up. A solid step up between its world's starter and premium parts.", Stats = {Speed = 27.9, Power = 3.28, AccelTime = 2.1}},
	engine_phantom = {Slot = "Engine", Name = "Phantom V-Twin", Model = "EnginePhantom", Rarity = "Rare", Band = 3, Role = "B", Theme = "Cursed", Kind = "twin", Price = 1200000,
		Desc = "Twin cylinders: balanced power and speed. Premium part for its world.", Stats = {Speed = 31.9, Power = 3.61, AccelTime = 1.5}},
	engine_geode = {Slot = "Engine", Name = "Geode Core", Model = "EngineGeode", Rarity = "Uncommon", Band = 4, Role = "A", Theme = "Crystal Caves", Kind = "crystal", Price = 1600000,
		Desc = "Crystal core: solid power at a steady speed.", Stats = {Speed = 30.4, Power = 4.18, AccelTime = 1.6}},
	engine_shardspinner = {Slot = "Engine", Name = "Shard Spinner", Model = "EngineShardSpinner", Rarity = "Uncommon", Band = 4, Role = "M", Theme = "Crystal Caves", Kind = "turbine", Price = 3500000,
		Desc = "High top speed and instant spin-up, a little less power. A solid step up between its world's starter and premium parts.", Stats = {Speed = 36, Power = 4.37, AccelTime = 1}},
	engine_quartzpiston = {Slot = "Engine", Name = "Quartz Piston", Model = "EngineQuartzPiston", Rarity = "Rare", Band = 4, Role = "M", Theme = "Crystal Caves", Kind = "compact", Price = 7500000,
		Desc = "Light motor that speeds up quickly. A solid step up between its world's starter and premium parts.", Stats = {Speed = 27.7, Power = 4.85, AccelTime = 1.2}},
	engine_reactor = {Slot = "Engine", Name = "Crystal Reactor", Model = "EngineReactor", Rarity = "Rare", Band = 4, Role = "B", Theme = "Crystal Caves", Kind = "crystal", Price = 16000000,
		Desc = "Crystal core: solid power at a steady speed. Premium part for its world.", Stats = {Speed = 32.4, Power = 5.48, AccelTime = 1.6}},
	engine_8bit = {Slot = "Engine", Name = "8-Bit Engine", Model = "Engine8Bit", Rarity = "Uncommon", Band = 5, Role = "A", Theme = "Retro World", Kind = "pixel", Price = 22000000,
		Desc = "Arcade motor: balanced and peppy.", Stats = {Speed = 31.8, Power = 6.04, AccelTime = 1.3}},
	engine_cartridge = {Slot = "Engine", Name = "Cartridge Cruncher", Model = "EngineCartridge", Rarity = "Rare", Band = 5, Role = "M", Theme = "Retro World", Kind = "twin", Price = 58000000,
		Desc = "Twin cylinders: balanced power and speed. A solid step up between its world's starter and premium parts.", Stats = {Speed = 31.8, Power = 6.92, AccelTime = 1.5}},
	engine_arcade = {Slot = "Engine", Name = "Arcade Turbo", Model = "EngineArcade", Rarity = "Epic", Band = 5, Role = "B", Theme = "Retro World", Kind = "turbine", Price = 160000000,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 37.8, Power = 7.67, AccelTime = 1}},
	engine_tiki = {Slot = "Engine", Name = "Tiki Thumper", Model = "EngineTiki", Rarity = "Uncommon", Band = 6, Role = "A", Theme = "Jungle", Kind = "industrial", Price = 210000000,
		Desc = "Heavy torque and big clearing power, slower to speed up.", Stats = {Speed = 28.2, Power = 9.19, AccelTime = 2.1}},
	engine_totem = {Slot = "Engine", Name = "Totem Torque", Model = "EngineTotem", Rarity = "Rare", Band = 6, Role = "M", Theme = "Jungle", Kind = "industrial", Price = 450000000,
		Desc = "Heavy torque and big clearing power, slower to speed up. A solid step up between its world's starter and premium parts.", Stats = {Speed = 29.2, Power = 10.5, AccelTime = 2.1}},
	engine_jturbine = {Slot = "Engine", Name = "Jungle Turbine", Model = "EngineJungleTurbine", Rarity = "Epic", Band = 6, Role = "B", Theme = "Jungle", Kind = "turbine", Price = 970000000,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 38.2, Power = 11.2, AccelTime = 1}},
	engine_cryo = {Slot = "Engine", Name = "Cryo Compressor", Model = "EngineCryo", Rarity = "Uncommon", Band = 7, Role = "A", Theme = "Absolute Zero", Kind = "industrial", Price = 1300000000,
		Desc = "Heavy torque and big clearing power, slower to speed up.", Stats = {Speed = 28.7, Power = 12.8, AccelTime = 2.1}},
	engine_frostpiston = {Slot = "Engine", Name = "Frost Piston", Model = "EngineFrostPiston", Rarity = "Rare", Band = 7, Role = "M", Theme = "Absolute Zero", Kind = "compact", Price = 2600000000,
		Desc = "Light motor that speeds up quickly. A solid step up between its world's starter and premium parts.", Stats = {Speed = 28.4, Power = 13.3, AccelTime = 1.2}},
	engine_glacierv6 = {Slot = "Engine", Name = "Glacier V6", Model = "EngineGlacierV6", Rarity = "Epic", Band = 7, Role = "M", Theme = "Absolute Zero", Kind = "twin", Price = 5200000000,
		Desc = "Twin cylinders: balanced power and speed. A solid step up between its world's starter and premium parts.", Stats = {Speed = 33, Power = 14.8, AccelTime = 1.5}},
	engine_polar = {Slot = "Engine", Name = "Polar Turbine", Model = "EnginePolar", Rarity = "Epic", Band = 7, Role = "B", Theme = "Absolute Zero", Kind = "turbine", Price = 10000000000,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 38.7, Power = 15.7, AccelTime = 1}},
	engine_zerocore = {Slot = "Engine", Name = "Absolute Zero Core", Model = "EngineZeroCore", Rarity = "Legendary", Band = 7, Role = "C", Theme = "Absolute Zero", Kind = "core", Price = 200000000000,
		Desc = "Energy core: high power and high speed. A legendary saving goal!", Stats = {Speed = 37.7, Power = 22, AccelTime = 1.25}},
	engine_lanterntwin = {Slot = "Engine", Name = "Lantern Twin", Model = "EngineLanternTwin", Rarity = "Rare", Band = 8, Role = "A", Theme = "Sakura Garden", Kind = "twin", Price = 14000000000,
		Desc = "Twin cylinders: balanced power and speed.", Stats = {Speed = 32.1, Power = 13.7, AccelTime = 1.5}},
	engine_bonsai = {Slot = "Engine", Name = "Bonsai Drive", Model = "EngineBonsai", Rarity = "Epic", Band = 8, Role = "M", Theme = "Sakura Garden", Kind = "compact", Price = 34000000000,
		Desc = "Light motor that speeds up quickly. A solid step up between its world's starter and premium parts.", Stats = {Speed = 29.1, Power = 15.4, AccelTime = 1.2}},
	engine_blossom = {Slot = "Engine", Name = "Blossom Turbine", Model = "EngineBlossom", Rarity = "Epic", Band = 8, Role = "B", Theme = "Sakura Garden", Kind = "turbine", Price = 81000000000,
		Desc = "High top speed and instant spin-up, a little less power. Premium part for its world.", Stats = {Speed = 39.1, Power = 17.4, AccelTime = 1}},
	engine_gumdrop = {Slot = "Engine", Name = "Gumdrop Motor", Model = "EngineGumdrop", Rarity = "Rare", Band = 9, Role = "A", Theme = "Candy Kingdom", Kind = "compact", Price = 110000000000,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 28.6, Power = 15.2, AccelTime = 1.2}},
	engine_taffytwister = {Slot = "Engine", Name = "Taffy Twister", Model = "EngineTaffyTwister", Rarity = "Rare", Band = 9, Role = "M", Theme = "Candy Kingdom", Kind = "turbine", Price = 180000000000,
		Desc = "High top speed and instant spin-up, a little less power. A solid step up between its world's starter and premium parts.", Stats = {Speed = 38.3, Power = 16.4, AccelTime = 1}},
	engine_cocoa = {Slot = "Engine", Name = "Cocoa Cruiser", Model = "EngineCocoa", Rarity = "Epic", Band = 9, Role = "M", Theme = "Candy Kingdom", Kind = "industrial", Price = 280000000000,
		Desc = "Heavy torque and big clearing power, slower to speed up. A solid step up between its world's starter and premium parts.", Stats = {Speed = 30.9, Power = 19.3, AccelTime = 2.1}},
	engine_sugarv8 = {Slot = "Engine", Name = "Sugar Rush V8", Model = "EngineSugarV8", Rarity = "Epic", Band = 9, Role = "B", Theme = "Candy Kingdom", Kind = "twin", Price = 440000000000,
		Desc = "Twin cylinders: balanced power and speed. Premium part for its world.", Stats = {Speed = 34.6, Power = 20.4, AccelTime = 1.5}},
	engine_bubble = {Slot = "Engine", Name = "Bubble Pump", Model = "EngineBubble", Rarity = "Rare", Band = 10, Role = "A", Theme = "Sunken Atlantis", Kind = "compact", Price = 600000000000,
		Desc = "Light motor that speeds up quickly.", Stats = {Speed = 29.1, Power = 16.6, AccelTime = 1.2}},
	engine_pearldiver = {Slot = "Engine", Name = "Pearl Diver", Model = "EnginePearlDiver", Rarity = "Epic", Band = 10, Role = "M", Theme = "Sunken Atlantis", Kind = "twin", Price = 770000000000,
		Desc = "Twin cylinders: balanced power and speed. A solid step up between its world's starter and premium parts.", Stats = {Speed = 34, Power = 19.3, AccelTime = 1.5}},
	engine_leviathan = {Slot = "Engine", Name = "Leviathan Turbine", Model = "EngineLeviathan", Rarity = "Legendary", Band = 10, Role = "B", Theme = "Sunken Atlantis", Kind = "turbine", Price = 990000000000,
		Desc = "High top speed and instant spin-up, a little less power. A legendary saving goal!", Stats = {Speed = 40, Power = 21.4, AccelTime = 1}},
	engine_windup = {Slot = "Engine", Name = "Wind-up Motor", Model = "EngineWindup", Rarity = "Rare", Band = 11, Role = "A", Theme = "Giant Toybox", Kind = "clockwork", Price = 1400000000000,
		Desc = "Wind-up power with smooth acceleration.", Stats = {Speed = 32.5, Power = 18.6, AccelTime = 1.4}},
	engine_toyrocket = {Slot = "Engine", Name = "Rocket Toy Motor", Model = "EngineToyRocket", Rarity = "Epic", Band = 11, Role = "M", Theme = "Giant Toybox", Kind = "turbine", Price = 2300000000000,
		Desc = "High top speed and instant spin-up, a little less power. A solid step up between its world's starter and premium parts.", Stats = {Speed = 39.5, Power = 20.3, AccelTime = 1}},
	engine_jackbox = {Slot = "Engine", Name = "Jack-in-the-Box Engine", Model = "EngineJackbox", Rarity = "Legendary", Band = 11, Role = "B", Theme = "Giant Toybox", Kind = "industrial", Price = 4000000000000,
		Desc = "Heavy torque and big clearing power, slower to speed up. A legendary saving goal!", Stats = {Speed = 32.5, Power = 25.1, AccelTime = 2.1}},
	engine_pocketwatch = {Slot = "Engine", Name = "Pocketwatch Engine", Model = "EnginePocketwatch", Rarity = "Rare", Band = 12, Role = "A", Theme = "Clockwork City", Kind = "clockwork", Price = 5400000000000,
		Desc = "Wind-up power with smooth acceleration.", Stats = {Speed = 33, Power = 20.2, AccelTime = 1.4}},
	engine_escapement = {Slot = "Engine", Name = "Escapement Drive", Model = "EngineEscapement", Rarity = "Rare", Band = 12, Role = "M", Theme = "Clockwork City", Kind = "clockwork", Price = 6500000000000,
		Desc = "Wind-up power with smooth acceleration. A solid step up between its world's starter and premium parts.", Stats = {Speed = 33.6, Power = 22.1, AccelTime = 1.4}},
	engine_steamregulator = {Slot = "Engine", Name = "Steam Regulator", Model = "EngineSteamRegulator", Rarity = "Epic", Band = 12, Role = "M", Theme = "Clockwork City", Kind = "industrial", Price = 7800000000000,
		Desc = "Heavy torque and big clearing power, slower to speed up. A solid step up between its world's starter and premium parts.", Stats = {Speed = 32.3, Power = 25, AccelTime = 2.1}},
	engine_grandclock = {Slot = "Engine", Name = "Grand Clockwork Core", Model = "EngineGrandClock", Rarity = "Legendary", Band = 12, Role = "B", Theme = "Clockwork City", Kind = "clockwork", Price = 9500000000000,
		Desc = "Wind-up power with smooth acceleration. A legendary saving goal!", Stats = {Speed = 35, Power = 26.5, AccelTime = 1.4}},
	engine_breeze = {Slot = "Engine", Name = "Breeze Turbine", Model = "EngineBreeze", Rarity = "Epic", Band = 13, Role = "A", Theme = "Cloud Kingdom", Kind = "turbine", Price = 13000000000000,
		Desc = "High top speed and instant spin-up, a little less power.", Stats = {Speed = 39.4, Power = 21.1, AccelTime = 1}},
	engine_galerotor = {Slot = "Engine", Name = "Gale Rotor", Model = "EngineGaleRotor", Rarity = "Epic", Band = 13, Role = "M", Theme = "Cloud Kingdom", Kind = "turbine", Price = 14000000000000,
		Desc = "High top speed and instant spin-up, a little less power. A solid step up between its world's starter and premium parts.", Stats = {Speed = 40, Power = 24.1, AccelTime = 1}},
	engine_storm = {Slot = "Engine", Name = "Storm Engine", Model = "EngineStorm", Rarity = "Legendary", Band = 13, Role = "B", Theme = "Cloud Kingdom", Kind = "core", Price = 15000000000000,
		Desc = "Energy core: high power and high speed. A legendary saving goal!", Stats = {Speed = 39.4, Power = 29.3, AccelTime = 1.25}},
	engine_stardrive = {Slot = "Engine", Name = "Star Drive", Model = "EngineStarDrive", Rarity = "Epic", Band = 14, Role = "A", Theme = "Cosmic Sanctuary", Kind = "core", Price = 20000000000000,
		Desc = "Energy core: high power and high speed.", Stats = {Speed = 37.9, Power = 24.3, AccelTime = 1.25}},
	engine_nebula = {Slot = "Engine", Name = "Nebula Reactor", Model = "EngineNebula", Rarity = "Legendary", Band = 14, Role = "B", Theme = "Cosmic Sanctuary", Kind = "core", Price = 29000000000000,
		Desc = "Energy core: high power and high speed. A legendary saving goal!", Stats = {Speed = 39.9, Power = 31.9, AccelTime = 1.25}},
	gear_wheels = {Slot = "Gear", Name = "Snow Wheels", Model = "GearWheels", Rarity = "Starter", Band = 1, Role = "S", Theme = "Snowy Starter", Kind = "smalltires", Price = 0,
		Desc = "Fast and nimble, but they slide. Free and always yours.", Stats = {SpeedMult = 1, Traction = 0.55, Turn = 1, Pivot = 0.15, Stability = 1, PowerMult = 1}},
	gear_chunky = {Slot = "Gear", Name = "Chunky Snow Tires", Model = "GearChunky", Rarity = "Common", Band = 1, Role = "A", Theme = "Snowy Starter", Kind = "bigtires", Price = 220,
		Desc = "Chunky grip and stability with a small push bonus.", Stats = {SpeedMult = 0.95, Traction = 0.72, Turn = 0.9, Pivot = 0.2, Stability = 1.35, PowerMult = 1.01}},
	gear_tracks = {Slot = "Gear", Name = "Tracked Treads", Model = "GearTracks", Rarity = "Uncommon", Band = 1, Role = "C", Theme = "Snowy Starter", Kind = "tracks", Price = 650,
		Desc = "Grippy tracks that turn on the spot and push harder.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 1.08}},
	gear_balloon = {Slot = "Gear", Name = "Dune Balloon Tires", Model = "GearBalloon", Rarity = "Common", Band = 2, Role = "A", Theme = "Desert", Kind = "flotation", Price = 1600,
		Desc = "Balloon tires float on soft snow: stable with extra push.", Stats = {SpeedMult = 0.95, Traction = 0.66, Turn = 0.95, Pivot = 0.25, Stability = 1.6, PowerMult = 1.13}},
	gear_sandcrawler = {Slot = "Gear", Name = "Sandcrawler Tracks", Model = "GearSandcrawler", Rarity = "Rare", Band = 2, Role = "B", Theme = "Desert", Kind = "widetracks", Price = 2800,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. Premium part for its world.", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 1.35}},
	gear_bonewheels = {Slot = "Gear", Name = "Spiked Bone Wheels", Model = "GearBoneWheels", Rarity = "Uncommon", Band = 3, Role = "A", Theme = "Cursed", Kind = "studded", Price = 26000,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 1.23}},
	gear_graverollers = {Slot = "Gear", Name = "Grave Rollers", Model = "GearGraveRollers", Rarity = "Uncommon", Band = 3, Role = "M", Theme = "Cursed", Kind = "bigtires", Price = 180000,
		Desc = "Chunky grip and stability with a small push bonus. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.95, Traction = 0.72, Turn = 0.9, Pivot = 0.2, Stability = 1.35, PowerMult = 1.32}},
	gear_haunted = {Slot = "Gear", Name = "Haunted Treads", Model = "GearHaunted", Rarity = "Rare", Band = 3, Role = "B", Theme = "Cursed", Kind = "tracks", Price = 1200000,
		Desc = "Grippy tracks that turn on the spot and push harder. Premium part for its world.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 1.46}},
	gear_crystalstud = {Slot = "Gear", Name = "Crystal Studded Tires", Model = "GearCrystalStud", Rarity = "Uncommon", Band = 4, Role = "A", Theme = "Crystal Caves", Kind = "studded", Price = 1600000,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 1.35}},
	gear_shardtreads = {Slot = "Gear", Name = "Shard Treads", Model = "GearShardTreads", Rarity = "Uncommon", Band = 4, Role = "M", Theme = "Crystal Caves", Kind = "tracks", Price = 3500000,
		Desc = "Grippy tracks that turn on the spot and push harder. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 1.45}},
	gear_prismskids = {Slot = "Gear", Name = "Prism Skids", Model = "GearPrismSkids", Rarity = "Rare", Band = 4, Role = "M", Theme = "Crystal Caves", Kind = "skis", Price = 7500000,
		Desc = "Ski runners: the fastest glide, very slippery. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 1.15, Traction = 0.42, Turn = 1.1, Pivot = 0.1, Stability = 1.1, PowerMult = 1.47}},
	gear_geodetracks = {Slot = "Gear", Name = "Geode Tracks", Model = "GearGeodeTracks", Rarity = "Rare", Band = 4, Role = "B", Theme = "Crystal Caves", Kind = "compacttracks", Price = 16000000,
		Desc = "Compact tracks: spin on the spot, very agile. Premium part for its world.", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 1.59}},
	gear_pixelwheels = {Slot = "Gear", Name = "Pixel Wheels", Model = "GearPixelWheels", Rarity = "Uncommon", Band = 5, Role = "A", Theme = "Retro World", Kind = "pixel", Price = 22000000,
		Desc = "Blocky wheels: light and nimble.", Stats = {SpeedMult = 1, Traction = 0.7, Turn = 1.05, Pivot = 0.35, Stability = 1.1, PowerMult = 1.47}},
	gear_joypad = {Slot = "Gear", Name = "Joypad Treads", Model = "GearJoypad", Rarity = "Rare", Band = 5, Role = "M", Theme = "Retro World", Kind = "compacttracks", Price = 58000000,
		Desc = "Compact tracks: spin on the spot, very agile. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 1.62}},
	gear_hoverpods = {Slot = "Gear", Name = "Arcade Hover Pods", Model = "GearHoverPods", Rarity = "Epic", Band = 5, Role = "B", Theme = "Retro World", Kind = "hover", Price = 160000000,
		Desc = "Hover pods: fast and spin on the spot, but little grip. Premium part for its world.", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 1.7}},
	gear_mudder = {Slot = "Gear", Name = "Mudder Tires", Model = "GearMudder", Rarity = "Uncommon", Band = 6, Role = "A", Theme = "Jungle", Kind = "bigtires", Price = 210000000,
		Desc = "Chunky grip and stability with a small push bonus.", Stats = {SpeedMult = 0.95, Traction = 0.72, Turn = 0.9, Pivot = 0.2, Stability = 1.35, PowerMult = 1.63}},
	gear_rootcrawler = {Slot = "Gear", Name = "Root Crawlers", Model = "GearRootCrawler", Rarity = "Rare", Band = 6, Role = "M", Theme = "Jungle", Kind = "tracks", Price = 450000000,
		Desc = "Grippy tracks that turn on the spot and push harder. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 1.8}},
	gear_vinecrawler = {Slot = "Gear", Name = "Vine Crawler Tracks", Model = "GearVineCrawler", Rarity = "Epic", Band = 6, Role = "B", Theme = "Jungle", Kind = "widetracks", Price = 970000000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. Premium part for its world.", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 1.98}},
	gear_skis = {Slot = "Gear", Name = "Frost Runners", Model = "GearSkis", Rarity = "Uncommon", Band = 7, Role = "A", Theme = "Absolute Zero", Kind = "skis", Price = 1300000000,
		Desc = "Ski runners: the fastest glide, very slippery.", Stats = {SpeedMult = 1.15, Traction = 0.42, Turn = 1.1, Pivot = 0.1, Stability = 1.1, PowerMult = 1.77}},
	gear_frostbite = {Slot = "Gear", Name = "Frostbite Studs", Model = "GearFrostbite", Rarity = "Rare", Band = 7, Role = "M", Theme = "Absolute Zero", Kind = "studded", Price = 2600000000,
		Desc = "Studs grip hard snow: great traction and extra push. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 1.89}},
	gear_aurora = {Slot = "Gear", Name = "Aurora Glide", Model = "GearAurora", Rarity = "Epic", Band = 7, Role = "M", Theme = "Absolute Zero", Kind = "hover", Price = 5200000000,
		Desc = "Hover pods: fast and spin on the spot, but little grip. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 1.96}},
	gear_glaciertracks = {Slot = "Gear", Name = "Glacier Tracks", Model = "GearGlacierTracks", Rarity = "Epic", Band = 7, Role = "B", Theme = "Absolute Zero", Kind = "widetracks", Price = 10000000000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. Premium part for its world.", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 2.18}},
	gear_zerog = {Slot = "Gear", Name = "Zero-G Hover Rig", Model = "GearZeroG", Rarity = "Legendary", Band = 7, Role = "C", Theme = "Absolute Zero", Kind = "hover", Price = 200000000000,
		Desc = "Hover pods: fast and spin on the spot, but little grip. A legendary saving goal!", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 2.24}},
	gear_bamboo = {Slot = "Gear", Name = "Bamboo Wheels", Model = "GearBamboo", Rarity = "Rare", Band = 8, Role = "A", Theme = "Sakura Garden", Kind = "smalltires", Price = 14000000000,
		Desc = "Nimble and fast, but slides in turns.", Stats = {SpeedMult = 1, Traction = 0.55, Turn = 1, Pivot = 0.15, Stability = 1, PowerMult = 1.94}},
	gear_koifin = {Slot = "Gear", Name = "Koi Fin Rollers", Model = "GearKoiFin", Rarity = "Epic", Band = 8, Role = "M", Theme = "Sakura Garden", Kind = "flotation", Price = 34000000000,
		Desc = "Balloon tires float on soft snow: stable with extra push. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.95, Traction = 0.66, Turn = 0.95, Pivot = 0.25, Stability = 1.6, PowerMult = 2.17}},
	gear_petalglide = {Slot = "Gear", Name = "Petal Glide Runners", Model = "GearPetalGlide", Rarity = "Epic", Band = 8, Role = "B", Theme = "Sakura Garden", Kind = "skis", Price = 81000000000,
		Desc = "Ski runners: the fastest glide, very slippery. Premium part for its world.", Stats = {SpeedMult = 1.15, Traction = 0.42, Turn = 1.1, Pivot = 0.1, Stability = 1.1, PowerMult = 2.26}},
	gear_donut = {Slot = "Gear", Name = "Donut Tires", Model = "GearDonut", Rarity = "Rare", Band = 9, Role = "A", Theme = "Candy Kingdom", Kind = "bigtires", Price = 110000000000,
		Desc = "Chunky grip and stability with a small push bonus.", Stats = {SpeedMult = 0.95, Traction = 0.72, Turn = 0.9, Pivot = 0.2, Stability = 1.35, PowerMult = 2.18}},
	gear_lollipop = {Slot = "Gear", Name = "Lollipop Wheels", Model = "GearLollipop", Rarity = "Rare", Band = 9, Role = "M", Theme = "Candy Kingdom", Kind = "smalltires", Price = 180000000000,
		Desc = "Nimble and fast, but slides in turns. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 1, Traction = 0.55, Turn = 1, Pivot = 0.15, Stability = 1, PowerMult = 2.25}},
	gear_licorice = {Slot = "Gear", Name = "Licorice Tracks", Model = "GearLicorice", Rarity = "Epic", Band = 9, Role = "M", Theme = "Candy Kingdom", Kind = "compacttracks", Price = 280000000000,
		Desc = "Compact tracks: spin on the spot, very agile. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 2.44}},
	gear_gummytreads = {Slot = "Gear", Name = "Gummy Treads", Model = "GearGummyTreads", Rarity = "Epic", Band = 9, Role = "B", Theme = "Candy Kingdom", Kind = "tracks", Price = 440000000000,
		Desc = "Grippy tracks that turn on the spot and push harder. Premium part for its world.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 2.59}},
	gear_shell = {Slot = "Gear", Name = "Shell Wheels", Model = "GearShell", Rarity = "Rare", Band = 10, Role = "A", Theme = "Sunken Atlantis", Kind = "studded", Price = 600000000000,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 2.4}},
	gear_bubblehover = {Slot = "Gear", Name = "Bubble Hover", Model = "GearBubbleHover", Rarity = "Epic", Band = 10, Role = "M", Theme = "Sunken Atlantis", Kind = "hover", Price = 770000000000,
		Desc = "Hover pods: fast and spin on the spot, but little grip. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 2.55}},
	gear_paddle = {Slot = "Gear", Name = "Paddle Tracks", Model = "GearPaddle", Rarity = "Legendary", Band = 10, Role = "B", Theme = "Sunken Atlantis", Kind = "widetracks", Price = 990000000000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. A legendary saving goal!", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 2.9}},
	gear_toybrick = {Slot = "Gear", Name = "Toy Brick Wheels", Model = "GearToyBrick", Rarity = "Rare", Band = 11, Role = "A", Theme = "Giant Toybox", Kind = "smalltires", Price = 1400000000000,
		Desc = "Nimble and fast, but slides in turns.", Stats = {SpeedMult = 1, Traction = 0.55, Turn = 1, Pivot = 0.15, Stability = 1, PowerMult = 2.59}},
	gear_yoyo = {Slot = "Gear", Name = "Yo-yo Wheels", Model = "GearYoyo", Rarity = "Epic", Band = 11, Role = "M", Theme = "Giant Toybox", Kind = "rings", Price = 2300000000000,
		Desc = "Orbit rings: fast, agile and grippy. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 1.05, Traction = 0.8, Turn = 1.1, Pivot = 0.6, Stability = 1.3, PowerMult = 2.86}},
	gear_toytank = {Slot = "Gear", Name = "Toy Tank Tracks", Model = "GearToyTank", Rarity = "Legendary", Band = 11, Role = "B", Theme = "Giant Toybox", Kind = "compacttracks", Price = 4000000000000,
		Desc = "Compact tracks: spin on the spot, very agile. A legendary saving goal!", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 3.11}},
	gear_cogwheels = {Slot = "Gear", Name = "Cog Wheels", Model = "GearCogWheels", Rarity = "Rare", Band = 12, Role = "A", Theme = "Clockwork City", Kind = "studded", Price = 5400000000000,
		Desc = "Studs grip hard snow: great traction and extra push.", Stats = {SpeedMult = 0.95, Traction = 0.9, Turn = 0.95, Pivot = 0.22, Stability = 1.2, PowerMult = 2.91}},
	gear_ratchet = {Slot = "Gear", Name = "Ratchet Treads", Model = "GearRatchet", Rarity = "Rare", Band = 12, Role = "M", Theme = "Clockwork City", Kind = "tracks", Price = 6500000000000,
		Desc = "Grippy tracks that turn on the spot and push harder. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 3.12}},
	gear_pendulum = {Slot = "Gear", Name = "Pendulum Skis", Model = "GearPendulum", Rarity = "Epic", Band = 12, Role = "M", Theme = "Clockwork City", Kind = "skis", Price = 7800000000000,
		Desc = "Ski runners: the fastest glide, very slippery. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 1.15, Traction = 0.42, Turn = 1.1, Pivot = 0.1, Stability = 1.1, PowerMult = 3.16}},
	gear_brasstracks = {Slot = "Gear", Name = "Brass Tracks", Model = "GearBrassTracks", Rarity = "Legendary", Band = 12, Role = "B", Theme = "Clockwork City", Kind = "compacttracks", Price = 9500000000000,
		Desc = "Compact tracks: spin on the spot, very agile. A legendary saving goal!", Stats = {SpeedMult = 0.9, Traction = 0.95, Turn = 1.15, Pivot = 1, Stability = 1.5, PowerMult = 3.42}},
	gear_cloudpuff = {Slot = "Gear", Name = "Cloud Puff Wheels", Model = "GearCloudPuff", Rarity = "Epic", Band = 13, Role = "A", Theme = "Cloud Kingdom", Kind = "flotation", Price = 13000000000000,
		Desc = "Balloon tires float on soft snow: stable with extra push.", Stats = {SpeedMult = 0.95, Traction = 0.66, Turn = 0.95, Pivot = 0.25, Stability = 1.6, PowerMult = 3.25}},
	gear_nimbus = {Slot = "Gear", Name = "Nimbus Treads", Model = "GearNimbus", Rarity = "Epic", Band = 13, Role = "M", Theme = "Cloud Kingdom", Kind = "widetracks", Price = 14000000000000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. A solid step up between its world's starter and premium parts.", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 3.59}},
	gear_stormpods = {Slot = "Gear", Name = "Storm Hover Pods", Model = "GearStormPods", Rarity = "Legendary", Band = 13, Role = "B", Theme = "Cloud Kingdom", Kind = "hover", Price = 15000000000000,
		Desc = "Hover pods: fast and spin on the spot, but little grip. A legendary saving goal!", Stats = {SpeedMult = 1.1, Traction = 0.62, Turn = 1.2, Pivot = 0.9, Stability = 1, PowerMult = 3.67}},
	gear_orbit = {Slot = "Gear", Name = "Orbit Rings", Model = "GearOrbit", Rarity = "Epic", Band = 14, Role = "A", Theme = "Cosmic Sanctuary", Kind = "rings", Price = 20000000000000,
		Desc = "Orbit rings: fast, agile and grippy.", Stats = {SpeedMult = 1.05, Traction = 0.8, Turn = 1.1, Pivot = 0.6, Stability = 1.3, PowerMult = 3.53}},
	gear_meteor = {Slot = "Gear", Name = "Meteor Treads", Model = "GearMeteor", Rarity = "Legendary", Band = 14, Role = "B", Theme = "Cosmic Sanctuary", Kind = "widetracks", Price = 29000000000000,
		Desc = "Wide flotation tracks: the strongest push, slower but rock-steady. A legendary saving goal!", Stats = {SpeedMult = 0.8, Traction = 0.92, Turn = 0.8, Pivot = 0.6, Stability = 2, PowerMult = 4.26}},
	body_starter = {Slot = "Body", Name = "Classic Plow Cab", Model = "BodyStarter", Rarity = "Starter", Band = 1, Role = "S", Theme = "Snowy Starter", Kind = "classic", Price = 0,
		Desc = "The original red plow cab. Free and always yours.", Stats = {Snow = 0}},
	body_frosthauler = {Slot = "Body", Name = "Frost Hauler", Model = "BodyFrostHauler", Rarity = "Common", Band = 1, Role = "A", Theme = "Snowy Starter", Kind = "steady", Price = 150,
		Desc = "Sturdy shell: a little more Snow per tile and steadier on bumps.", Stats = {Snow = 0.0116, Stability = 0.11}},
	body_dunerunner = {Slot = "Body", Name = "Dune Runner", Model = "BodyDuneRunner", Rarity = "Common", Band = 2, Role = "A", Theme = "Desert", Kind = "nimble", Price = 1000,
		Desc = "Light shell: a little more Snow per tile and quicker steering.", Stats = {Snow = 0.023, Turn = 0.036}},
	body_gravehauler = {Slot = "Body", Name = "Grave Hauler", Model = "BodyGraveHauler", Rarity = "Uncommon", Band = 3, Role = "A", Theme = "Cursed", Kind = "grip", Price = 7100,
		Desc = "Grippy shell: a little more Snow per tile and a touch more grip.", Stats = {Snow = 0.0344, Grip = 0.029}},
	body_geodecrawler = {Slot = "Body", Name = "Geode Crawler", Model = "BodyGeodeCrawler", Rarity = "Uncommon", Band = 4, Role = "A", Theme = "Crystal Caves", Kind = "steady", Price = 49000,
		Desc = "Sturdy shell: a little more Snow per tile and steadier on bumps.", Stats = {Snow = 0.0456, Stability = 0.14}},
	body_arcadekart = {Slot = "Body", Name = "Arcade Kart", Model = "BodyArcadeKart", Rarity = "Rare", Band = 5, Role = "A", Theme = "Retro World", Kind = "nimble", Price = 340000,
		Desc = "Light shell: a little more Snow per tile and quicker steering.", Stats = {Snow = 0.0568, Turn = 0.045}},
	body_safari = {Slot = "Body", Name = "Safari Cruiser", Model = "BodySafari", Rarity = "Rare", Band = 6, Role = "A", Theme = "Jungle", Kind = "grip", Price = 2300000,
		Desc = "Grippy shell: a little more Snow per tile and a touch more grip.", Stats = {Snow = 0.0679, Grip = 0.038}},
	body_polartitan = {Slot = "Body", Name = "Polar Titan", Model = "BodyPolarTitan", Rarity = "Epic", Band = 7, Role = "B", Theme = "Absolute Zero", Kind = "titan", Price = 16000000,
		Desc = "Armoured titan shell: more Snow per tile, extra grip and stability. Premium part for its world.", Stats = {Snow = 0.0953, Grip = 0.05, Stability = 0.25}},
	body_pagoda = {Slot = "Body", Name = "Pagoda Wagon", Model = "BodyPagoda", Rarity = "Rare", Band = 8, Role = "A", Theme = "Sakura Garden", Kind = "nimble", Price = 110000000,
		Desc = "Light shell: a little more Snow per tile and quicker steering.", Stats = {Snow = 0.0899, Turn = 0.054}},
	body_sweettruck = {Slot = "Body", Name = "Sweet Truck", Model = "BodySweetTruck", Rarity = "Epic", Band = 9, Role = "A", Theme = "Candy Kingdom", Kind = "grip", Price = 770000000,
		Desc = "Grippy shell: a little more Snow per tile and a touch more grip.", Stats = {Snow = 0.1008, Grip = 0.047}},
	body_reefdiver = {Slot = "Body", Name = "Reef Diver", Model = "BodyReefDiver", Rarity = "Epic", Band = 10, Role = "A", Theme = "Sunken Atlantis", Kind = "steady", Price = 5300000000,
		Desc = "Sturdy shell: a little more Snow per tile and steadier on bumps.", Stats = {Snow = 0.1115, Stability = 0.2}},
	body_toytruck = {Slot = "Body", Name = "Toy Truck", Model = "BodyToyTruck", Rarity = "Epic", Band = 11, Role = "A", Theme = "Giant Toybox", Kind = "nimble", Price = 37000000000,
		Desc = "Light shell: a little more Snow per tile and quicker steering.", Stats = {Snow = 0.1222, Turn = 0.063}},
	body_brasscarriage = {Slot = "Body", Name = "Brass Carriage", Model = "BodyBrassCarriage", Rarity = "Epic", Band = 12, Role = "A", Theme = "Clockwork City", Kind = "grip", Price = 250000000000,
		Desc = "Grippy shell: a little more Snow per tile and a touch more grip.", Stats = {Snow = 0.1329, Grip = 0.056}},
	body_skycruiser = {Slot = "Body", Name = "Sky Cruiser", Model = "BodySkyCruiser", Rarity = "Epic", Band = 13, Role = "A", Theme = "Cloud Kingdom", Kind = "nimble", Price = 1700000000000,
		Desc = "Light shell: a little more Snow per tile and quicker steering.", Stats = {Snow = 0.1434, Turn = 0.069}},
	body_starcruiser = {Slot = "Body", Name = "Star Cruiser", Model = "BodyStarCruiser", Rarity = "Legendary", Band = 14, Role = "B", Theme = "Cosmic Sanctuary", Kind = "cosmic", Price = 12000000000000,
		Desc = "Star shell: the most Snow per tile, with extra grip and steering. A legendary saving goal!", Stats = {Snow = 0.1695, Grip = 0.06, Turn = 0.06}},
}
for id, def in pairs(C.Parts) do def.Id = id; def.Weight = def.Role == "S" and 0 or 1 end -- Weight kept for older readers; odds come from C.OfferPool
-- rebalance 2026-10-05: price of a saved offer / reservation = the price it was rolled with, or the current catalog price if that is lower
-- (catalog price drops are passed on; a shown price never rises)
function C.OfferPrice(o)
	if type(o) ~= "table" then return 0 end
	local stored = tonumber(o.Price) or 0
	local def = C.Parts[o.Part or ""]
	if def and def.Price and def.Price > 0 and (stored <= 0 or def.Price < stored) then return def.Price end
	return stored
end
-- task 8 (2026-10-05): PAID parts come only from game passes (PassService). Role "P": never offered, not part of free-completion counters,
-- not used as the "useful offer" baseline (pity / offers behave exactly as for free players). Defined outside the generated table above.
C.Parts.gear_aurorawheels = {Slot = "Gear", Name = "Aurora Wheels", Model = "GearAuroraWheels", Rarity = "Legendary", Band = 1, Role = "P", Theme = "Premium", Kind = "bigtires", Price = 0,
	Desc = "Premium snow wheels with icy alloy hubs and aurora rims: great grip and turning, strong early pushing power.", Paid = "PremiumWheels",
	Stats = {SpeedMult = 1, Traction = 0.92, Turn = 1.15, Pivot = 0.7, Stability = 1.5, PowerMult = 1.75}}
C.Parts.gear_aurorawheels.Id = "gear_aurorawheels"; C.Parts.gear_aurorawheels.Weight = 0
function C.IsPaid(id) local d = C.Parts[id or ""]; return d ~= nil and d.Role == "P" end
-- rebalance 2026-10-05: price of a saved offer / reservation = the price it was rolled with, or the current catalog price if that is lower
-- (catalog price drops are passed on; a shown price never rises)
function C.OfferPrice(o)
	if type(o) ~= "table" then return 0 end
	local stored = tonumber(o.Price) or 0
	local def = C.Parts[o.Part or ""]
	if def and def.Price and def.Price > 0 and (stored <= 0 or def.Price < stored) then return def.Price end
	return stored
end

-- progression bands = field stages in unlock order
C.Bands = {"Starter", "Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Sakura", "Candy", "Atlantis", "Toybox", "Clockwork", "Cloud", "Cosmic"}
C.BandOfStage = {}
for i, s in ipairs(C.Bands) do C.BandOfStage[s] = i end
-- field toughness 0 (soft powder) .. 1 (hard ice): blade efficiency = Soft + (Hard - Soft) x toughness
C.Toughness = {Starter = 0.05, Desert = 0.2, Cursed = 0.55, Crystal = 0.9, Retro = 0.75, Jungle = 0.3, AbsoluteZero = 0.95, Sakura = 0.15, Candy = 0.5, Atlantis = 0.4, Toybox = 0.65, Clockwork = 0.85, Cloud = 0.1, Cosmic = 0.7}
-- OFFER POOL: relevance to the player's progression band x role weight x luck (rare parts only). The practical group (A and M parts of
-- the current and previous band) always keeps at least PracticalFloor of the total, so luck can never push practical upgrades out.
C.Offers = {
	-- 2026-10-06 (wiktor: "good items should be rarer"): premium / legendary / newer-world parts are much rarer and older-world parts
	-- fill more rolls; bad-luck protection (C.Shop.ProtectAfter 15) still guarantees a useful part. Sim: outputs/OfferRarity20261006.
	Relevance = {[-3] = 0.2, [-2] = 0.7, [-1] = 1, [0] = 1, [1] = 0.22, [2] = 0.05, [3] = 0.015}, -- by (part band - player band); older than -3: 0.04; newer than +3: never offered
	RoleWeight = {A = 0.8, M = 0.6, B = 0.15, C = 0.04}, -- was A 1, M 0.7, B 0.42, C 0.16
	PracticalFloor = 0.25, -- was 0.45
	SlotShare = {Blade = 0.2933, Engine = 0.2933, Gear = 0.2933, Body = 0.12}, -- task 7: category shares of every roll (one body per band)
	FinalBandPremium = 6, -- 2026-10-06 (5-hour game): in the last band (Cosmic) its premium (B) parts show this many times more often
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
		if def.Role ~= "S" and def.Role ~= "P" then -- task 8: paid parts are never offered
			local d = def.Band - band
			local rel = O.Relevance[d] or (d < -3 and 0.04 or 0)
			if rel > 0 then
				local rank = C.RarityRank[def.Rarity] or 2
				local w = rel * (O.RoleWeight[def.Role] or 1) * lf ^ math.max(0, rank - 3)
				if band == #C.Bands and def.Band == band and def.Role == "B" then w *= (O.FinalBandPremium or 1) end
				local practical = (def.Role == "A" or def.Role == "M") and (d == 0 or d == -1)
				table.insert(list, {Id = id, W = w, Practical = practical, Rank = rank})
				total += w
				if practical then prac += w end
			end
		end
	end
	-- task 7: normalise the categories, so the one-per-band bodies neither crowd out the other parts nor vanish
	local slotTot, shareSum = {}, 0
	for _, e in ipairs(list) do local sl = C.Parts[e.Id].Slot; slotTot[sl] = (slotTot[sl] or 0) + e.W end
	for sl in pairs(slotTot) do shareSum += (O.SlotShare[sl] or 0.25) end
	total, prac = 0, 0
	for _, e in ipairs(list) do
		local sl = C.Parts[e.Id].Slot
		e.W *= (O.SlotShare[sl] or 0.25) / shareSum / slotTot[sl]
		total += e.W
		if e.Practical then prac += e.W end
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
	BrakeFactor = 2.3,     -- braking / changing direction is this much stronger than accelerating (2026-10-05: was 1.8 - firmer brakes)
	CoastFactor = 1.4,     -- easing off with no throttle (2026-10-05: used to share BrakeFactor; now a gentler roll-out)
	LowSpeedPull = 0.3,    -- up to +30% acceleration near standstill, fading to 0 at top speed (snappier launches, same top speed)
	AirControl = 0.35,     -- throttle authority while no wheel touches the ground (bumps, kerbs)
	TiltRecover = 1.6,     -- upright assist multiplier while tilted more than ~25 degrees (quicker recovery from bumps)
	-- hold-to-drift (2026-10-05, PlowDriveClient): Left Shift / gamepad L1 / DRIFT button
	Drift = {
		MinSpeed = 0.35, MinSpeedAbs = 9, -- needs forward speed >= max(9, 35% of top speed) to start
		SteerToStart = 0.25,  -- ...and some steering input
		ExitSpeedShare = 0.25, -- ends below 25% of top speed (or on release / leaving the ground)
		Grip = 0.25,          -- sideways grip while fully drifting, x normal (traction still scales it, so grippy gear drifts tighter)
		MaxSlip = 38, SlipCatch = 0.6, -- slip angle (degrees) where the tyres start catching again: no spin-outs
		YawBoost = 0.25,      -- up to +25% turn rate while drifting, capped at TurnRate x (1 + YawBoost)
		RampIn = 6, RampOut = 2.2, -- per second: drift blends in ~0.17 s and grip returns over ~0.45 s
		Drag = 0.12,          -- small speed loss per second while sliding
		ExitCarry = 0.35,     -- share of the sideways speed that swings back to forward when grip returns (never above top speed)
		CameraFov = 4, CameraLean = 2, -- optional camera feedback (off with Reduced motion)
		EngineSound = "rbxassetid://71482635231754", SkidSound = "rbxassetid://103723782639124", -- Creator Store audio (diesel idle loop, dirt skid)
		-- 2026-10-06 drift Snow bonus (server: SnowFieldService). The meter fills only while the client is drifting (PlowDriftSignal) AND the
		-- SERVER's own hull samples agree (speed >= the drift start speed on snow; slide >= BonusMinSlip deg or turn >= BonusMinYaw deg/s)
		-- AND the blade really clears snow; it pays up to +SnowBonus Snow, holds BonusHold s after the drift, then fades over BonusFade s.
		-- Never while AFK. Sim: outputs/Rebalance20261005/sim levels.py LV.Drift.
		SnowBonus = 0.50, BonusFill = 2.5, BonusHold = 1.5, BonusFade = 3, BonusMinSlip = 12, BonusMinYaw = 25,
	},
	TurnRate = 1.6,        -- rad/s at full steering (x gear Turn); 2026-10-05: was 2.0 - calmer, car-like turns
	MinTurn = 0,           -- steering strength at a standstill for gears without Pivot (car-like: wheels need speed to turn; Pivot gears still spin on the spot)
	LateralGrip = 18,      -- sideways-slide damping per second at Traction 1 (2026-10-05: doubled - grips like a car instead of sliding)
	TurnSpeedFull = 0.3,   -- steering reaches full strength at this share of top speed
	HighSpeedTurnLoss = 0.2, -- up to 20% less steering near top speed (wider turns when fast); 2026-10-05: was 0.35
	CornerSlow = 0.2,      -- full-lock steering eases the target speed by up to 20% (W+D used to cut throttle to 71% by accident)
	PlowingSpeedFactor = 0.6, -- top speed while the blade is over a snow field (heavy work); full speed on roads and paths
	-- 2026-10-06: on a field the speed is also capped where one pass still breaks a layer (PlowDriveClient), never below Floor x the
	-- plowing speed; PassShare < 1 would demand more than a layer per pass
	HardSnow = {Floor = 0.25, PassShare = 1, EaseRate = 18}, -- EaseRate: studs/s per second the limit may move (smooth in and out of fresh snow)
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
-- AFK AUTO-PLOW (2026-10-06, Claude; wiktor: "some afk button so it will collect snow afk it should be next to upgrades").
-- AfkService (server) owns it: the toggle only turns on while seated in your plow on an unlocked field (not in the garage, arena,
-- tutorial or a Help job) and turns off on any input, on leaving the field and in those places. PlowDriveClient then drives a
-- lawnmower route over that field (the same single velocity writer). Snow from it pays Rate x the normal blade payout, with no
-- drift and no dig-combo bonus. Nothing is earned offline, and nothing works around Roblox's ~20 min idle disconnect.
-- SOUND (2026-10-06, Claude; wiktor: "we need to add SFX game is quiet now"): every plow volume in one place. Kept moderate (kids/teens).
-- All follow Settings > DriveSoundOn. Ids are public Creator Store audio checked in Play (IsLoaded, TimeLength); swap freely.
C.Sound = {
	EngineIdle = 0.16, EngineThrottle = 0.2,      -- own engine loop: idle + extra at full throttle (pitch follows speed)
	Skid = 0.32,                                   -- drift skid (x drift amount)
	Crunch = 0.28, CrunchBig = 0.42,               -- snow clearing: per payout, louder/deeper with more layers broken at once
	CrunchGap = 0.12,                              -- min seconds between crunches
	CrunchIds = {"rbxassetid://83105511178956", "rbxassetid://18643816569", "rbxassetid://81253534133158"},
	CrunchBigId = "rbxassetid://9118770616",
	OtherEngine = 0.14, OtherMax = 4, OtherRange = 70, -- other players' plows: nearest OtherMax within OtherRange get a quiet engine
}
C.Afk = {Rate = 0.70, -- wiktor 2026-10-06: "afk should make 70 percent of money" (was 0.30)
 ToggleCooldown = 0.75, FieldMargin = 24, LaneShare = 0.8, Inset = 4}
-- MINI PLOWS (2026-10-06, Claude; wiktor: "add automatic collection upgrade like mini version of ur cars driving in ur best field").
-- An upgrade bought with Snow in levels (MINIS button left of UPGRADES). Level n = Levels[n]: Count mini copies of your equipped plow
-- drive by themselves in your best unlocked field; each earns Share x what your plow's build clears there per second
-- (C.MiniBase: power vs coverage, the same formula as the pacing sim), then pets and SnowMult like AFK - no drift, no dig combo.
-- MiniPlowService pays it once a second only while you are in the game (nothing offline). Clearly less than driving: all 5 at
-- the top level = 0.45 of the model rate, about 0.6 of what the plow really clears driving plainly (Play-measured 2026-10-06:
-- model 24 vs real 18.4 Snow/s on Starter), so below AFK (0.70) and far below driving with combo and drift. Prices are explicit Snow amounts
-- written by outputs/Rebalance20261005/sim/gen_minis.py (Frac x a stage gate, so they follow the economy); never wallet-based.
-- Visuals (MiniPlowClient): small anchored copies, no physics, at most MaxShown minis drawn per client (your own first).
C.Minis = {
	Levels = { -- %MINI_LEVELS%
		{Count = 1, Share = 0.06, Cost = 650}, -- 0.12 x Desert gate
		{Count = 2, Share = 0.06, Cost = 8700}, -- 0.1 x Cursed gate
		{Count = 3, Share = 0.06, Cost = 540000}, -- 0.1 x Crystal gate
		{Count = 3, Share = 0.08, Cost = 7300000}, -- 0.1 x Retro gate
		{Count = 4, Share = 0.08, Cost = 71000000}, -- 0.1 x Jungle gate
		{Count = 4, Share = 0.10, Cost = 1900000000}, -- 0.04 x Portal gate
		{Count = 5, Share = 0.10, Cost = 160000000000}, -- 0.08 x Atlantis gate
		{Count = 5, Share = 0.12, Cost = 1400000000000}, -- 0.08 x Clockwork gate
	}, -- %END_MINI_LEVELS%
	PlowingSpeed = 0.6, -- coverage uses top speed x this on a field (C.Drive.PlowingSpeedFactor), like the sim
	Tick = 1, RateRefresh = 4, -- payout every Tick seconds; the field / build rate is recomputed every RateRefresh seconds
	Scale = 0.38, Speed = 8, LaneGap = 5, Hover = 0, -- look: model scale, studs/s along the lanes, lane spacing, extra height of the chassis root over the snow top
	MaxShown = 12, ShowRange = 260, -- drawing cap per client (own minis first, then nearest other players') and range for others' minis
}
function C.MiniLevel(L) return C.Minis.Levels[math.clamp(math.floor(tonumber(L) or 0), 0, #C.Minis.Levels)] end
-- Snow/s one full-share mini earns on a field (before pets and SnowMult): smooth minimum of the power- and coverage-limited layer rates
function C.MiniBase(stats, stageId, tileHP, snowPerPhase)
	if not stats or not stats.HasBlade or (stats.ClearPower or 0) <= 0 then return 0 end
	tileHP = math.max(1, tileHP or C.StageHP(stageId))
	local tile, slack = 3, 0.9
	local w = stats.BladeWidth + 2 * slack
	local tough = C.ToughnessOf(stageId, tileHP)
	local eff = stats.Soft + (stats.Hard - stats.Soft) * tough
	local power = (w / tile) * ((C.Clearing.BladeDepth + 2 * slack) / tile) * stats.ClearPower * eff / tileHP
	local handling = 0.42 + 0.32 * stats.Traction + 0.14 * math.min(stats.Pivot, 1) + 0.06 * math.min(stats.Turn or 1, 1.2) / 1.2
	handling = math.clamp(handling - math.min(0.12, 0.6 / math.max(stats.Accel, 1e-6)), 0.3, 0.9)
	local cover = 3 * (w / tile) * (stats.MaxSpeed * C.Minis.PlowingSpeed * handling) / tile
	if power <= 0 or cover <= 0 then return 0 end
	return (power ^ -4 + cover ^ -4) ^ (-1 / 4) * (snowPerPhase or 1) * (stats.SnowEff or 1)
end
-- PART LEVELS (2026-10-06, Claude; wiktor: "add cheap and good levels to things like plow car body wheels and engine").
-- Every part in all four slots (the free starter set included) levels 1..Max with Snow at the workbench (PlowService "LevelUp").
-- The level belongs to the owned part (d.Plow.Levels[id]), so swapping parts or buying another copy keeps it.
-- Each level: the part's key stat x (1 + Step x (level - 1)) - blade Soft/Hard, engine Power (+ a quarter of it as top speed, still capped),
-- gear PowerMult, body Snow (+ BodyFlat per level so the free cab is worth levelling). Level L -> L+1 costs
-- base x Cost0 x Growth^(L-1), base = the part's price (StarterBase for free parts, PaidBase for pass parts) - explicit prices that never
-- depend on the wallet. 2026-10-06 retune: levels 1-3 stay cheap; from level LateFrom -> LateFrom+1 on, one x LateJump and then
-- x LateGrowth per level; no single level costs more than Cap (990T, nothing past the trillions). World 1 gates went +8% with it.
-- Simulated (outputs/Rebalance20261005/sim/levels.py + gaps.py; README in outputs/PartLevels20261006); keep the sim's LV in sync.
C.Levels = {Max = 10, Step = 0.05, SpeedShare = 0.25, BodyFlat = 0.008, Cost0 = 0.25, Growth = 1.45, StarterBase = 60, PaidBase = 2000,
	LateFrom = 3, LateJump = 10, LateGrowth = 3, Cap = 9.9e14}
function C.LevelOf(levels, id)
	local L = levels and tonumber(levels[id or ""])
	if not L or L ~= L then return 1 end
	return math.clamp(math.floor(L), 1, C.Levels.Max)
end
local lvCache = {}
function C.LevelStats(def, L)
	L = math.clamp(math.floor(tonumber(L) or 1), 1, C.Levels.Max)
	if not def or L <= 1 then return def and def.Stats end
	local key = def.Id .. ":" .. L
	local c = lvCache[key]
	if c then return c end
	c = table.clone(def.Stats or {})
	local m = 1 + C.Levels.Step * (L - 1)
	if def.Slot == "Blade" then c.Soft = (c.Soft or 0) * m; c.Hard = (c.Hard or 0) * m
	elseif def.Slot == "Engine" then c.Power = (c.Power or 0) * m; c.Speed = (c.Speed or 0) * (1 + (m - 1) * C.Levels.SpeedShare)
	elseif def.Slot == "Gear" then c.PowerMult = (c.PowerMult or 1) * m
	elseif def.Slot == "Body" then c.Snow = (c.Snow or 0) * m + C.Levels.BodyFlat * (L - 1) end
	lvCache[key] = c
	return c
end
function C.LevelBase(def)
	if not def then return 0 end
	if def.Role == "P" then return C.Levels.PaidBase end
	return (def.Price or 0) > 0 and def.Price or C.Levels.StarterBase
end
function C.LevelCost(def, L) -- Snow to go from level L to L + 1
	local V = C.Levels
	L = math.max(1, L)
	local f = V.Cost0 * V.Growth ^ (math.min(L, V.LateFrom) - 1)
	if L >= V.LateFrom then f *= V.LateJump * V.LateGrowth ^ (L - V.LateFrom) end
	return math.floor(math.min(C.LevelBase(def) * f, V.Cap) + 0.5)
end
function C.StatsFor(build, mods)
	build, mods = build or {}, mods or {}
	local blade, engine, gear = C.Parts[build.Blade or ""], C.Parts[build.Engine or ""], C.Parts[build.Gear or ""]
	if blade and blade.Slot ~= "Blade" then blade = nil end
	if engine and engine.Slot ~= "Engine" then engine = nil end
	if gear and gear.Slot ~= "Gear" then gear = nil end
	local body = C.Parts[build.Body or ""]
	if body and body.Slot ~= "Body" then body = nil end
	local lv = type(mods.Levels) == "table" and mods.Levels or nil -- 2026-10-06: part levels (owned parts only; nil = level 1)
	local function S(def) return C.LevelStats(def, C.LevelOf(lv, def.Id)) end
	local ys = body and S(body) or {} -- task 7: Snow = +% Snow from clearing; Grip / Turn / Stability = small handling trait (no body = none)
	local bs = blade and S(blade) or {Width = 0, Soft = 0, Hard = 0}
	local es = engine and S(engine) or {Speed = 0, Power = 0, AccelTime = C.Drive.AccelTime}
	local gs = gear and S(gear) or {SpeedMult = 0, Traction = 0, Turn = 0, Pivot = 0, Stability = 1, PowerMult = 1}
	local rawWidthMult = math.max(1, num(mods.SizeMult, 1) * num(mods.ReachMult, 1))
	local widthMult = math.min(rawWidthMult, C.Clearing.MaxWidthMult)
	local widthPower = math.max(1, rawWidthMult / C.Clearing.MaxWidthMult)
	local power = (C.Clearing.BasePower * es.Power * gs.PowerMult + num(mods.PowerBonus, 0) * C.Clearing.BasePower) * num(mods.PowerMult, 1) * num(mods.SpinMult, 1) * widthPower
	local top = math.min(C.Drive.TopSpeedCap, es.Speed * gs.SpeedMult * num(mods.SpeedMult, 1))
	local accelTime = math.max(0.5, num(es.AccelTime, C.Drive.AccelTime))
	return {
		Valid = engine ~= nil and gear ~= nil, HasBlade = blade ~= nil,
		MaxSpeed = top, Accel = top / accelTime, AccelTime = accelTime, TurnRate = C.Drive.TurnRate * (gs.Turn + num(ys.Turn, 0)), Turn = gs.Turn + num(ys.Turn, 0), Pivot = gs.Pivot,
		Traction = math.min(1, gs.Traction + num(ys.Grip, 0)), Stability = gs.Stability + num(ys.Stability, 0), SnowEff = 1 + math.clamp(num(ys.Snow, 0), 0, 1),
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
	return (power ^ -4 + cover ^ -4) ^ (-1 / 4) * (stats.SnowEff or 1) -- task 7: a body's Snow efficiency counts as more productive clearing
end
return C
