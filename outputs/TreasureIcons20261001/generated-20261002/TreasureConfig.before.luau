-- TreasureConfig (2026-10-01, Claude; PNG-ready v2): Buried Treasures, shared by TreasureService (server) and the treasure GUIs.
-- Every fully dug tile rolls once: TileChance to hold a treasure, then a rarity by Weight; each biome has one item per rarity.
-- Snow bonus = rarity Bonus x one full tile's Snow (SnowPerPhase x 3 layers) x the player's Snow multipliers.
-- Average ~6% of digging income (1% x 5.97). Luck, dice and mutations do not change treasure odds.
local C = Color3.fromRGB
local TC = {}
TC.TileChance = 1 / 100
TC.GuaranteeAfterTiles = 3   -- a player's very first treasure is guaranteed on their 3rd fully dug tile
TC.MaxPerSecond = 3          -- safety cap for extreme digging speeds
TC.AnnounceRadius = 150      -- Mythic finds are announced to players this close
TC.Rarities = {
	{Id = "Common",    Weight = 70,  Bonus = 2,   Color = C(170, 205, 240)},
	{Id = "Rare",      Weight = 20,  Bonus = 6,   Color = C(70, 160, 255)},
	{Id = "Epic",      Weight = 7,   Bonus = 16,  Color = C(185, 95, 255)},
	{Id = "Legendary", Weight = 2.5, Bonus = 50,  Color = C(255, 200, 45)},
	{Id = "Mythic",    Weight = 0.5, Bonus = 200, Color = C(255, 95, 200), Announce = true},
}
TC.Biomes = {
	{Id = "Starter", Tab = "STARTER", Name = "Frozen Trinkets", Color = C(120, 200, 255), Items = {
		{Id = "FrostButton",    Name = "Frost Button",        Rarity = "Common",    Shape = "button",    A = C(150, 215, 255), B = C(235, 248, 255)},
		{Id = "SnowflakeCharm", Name = "Snowflake Charm",     Rarity = "Rare",      Shape = "snowflake", A = C(200, 240, 255), B = C(90, 180, 255)},
		{Id = "IcicleBell",     Name = "Icicle Bell",         Rarity = "Epic",      Shape = "bell",      A = C(160, 225, 255), B = C(255, 215, 90)},
		{Id = "FrozenWatch",    Name = "Frozen Pocket Watch", Rarity = "Legendary", Shape = "watch",     A = C(255, 205, 80), B = C(205, 240, 255)},
		{Id = "HeartOfWinter",  Name = "Heart of Winter",     Rarity = "Mythic",    Shape = "heart",     A = C(120, 215, 255), B = C(255, 255, 255)},
	}},
	{Id = "Desert", Tab = "DESERT", Name = "Fossils", Color = C(240, 185, 95), Items = {
		{Id = "TinyBone",       Name = "Tiny Bone",      Rarity = "Common",    Shape = "bone",   A = C(245, 235, 210), B = C(225, 205, 165)},
		{Id = "AmmoniteShell",  Name = "Ammonite Shell", Rarity = "Rare",      Shape = "shell",  A = C(225, 170, 110), B = C(255, 225, 170)},
		{Id = "RaptorClaw",     Name = "Raptor Claw",    Rarity = "Epic",      Shape = "claw",   A = C(240, 225, 195), B = C(110, 80, 60)},
		{Id = "GoldenScarab",   Name = "Golden Scarab",  Rarity = "Legendary", Shape = "scarab", A = C(255, 195, 50), B = C(40, 170, 160)},
		{Id = "DragonSkull",    Name = "Dragon Skull",   Rarity = "Mythic",    Shape = "skull",  A = C(250, 240, 220), B = C(255, 110, 60), Horns = true},
	}},
	{Id = "Cursed", Tab = "CURSED", Name = "Haunted Relics", Color = C(170, 110, 255), Items = {
		{Id = "SpookyCandle",   Name = "Spooky Candle",        Rarity = "Common",    Shape = "candle",  A = C(150, 110, 210), B = C(120, 255, 140)},
		{Id = "GhostLantern",   Name = "Ghost Lantern",        Rarity = "Rare",      Shape = "lantern", A = C(70, 60, 95), B = C(120, 255, 230)},
		{Id = "CursedMask",     Name = "Cursed Mask",          Rarity = "Epic",      Shape = "mask",    A = C(140, 70, 200), B = C(255, 90, 160), Horns = true},
		{Id = "CrystalBall",    Name = "Witch's Crystal Ball", Rarity = "Legendary", Shape = "orb",     A = C(190, 140, 255), B = C(110, 80, 60), Stand = true},
		{Id = "PhantomCrown",   Name = "Phantom Crown",        Rarity = "Mythic",    Shape = "crown",   A = C(205, 175, 255), B = C(120, 255, 220)},
	}},
	{Id = "Crystal", Tab = "CRYSTAL", Name = "Gemstones", Color = C(110, 220, 255), Items = {
		{Id = "QuartzChip",      Name = "Quartz Chip",      Rarity = "Common",    Shape = "gem",     A = C(255, 190, 220), B = C(255, 240, 250), Small = true},
		{Id = "Sapphire",        Name = "Sapphire",         Rarity = "Rare",      Shape = "gem",     A = C(60, 120, 255), B = C(160, 200, 255)},
		{Id = "AmethystCluster", Name = "Amethyst Cluster", Rarity = "Epic",      Shape = "cluster", A = C(175, 95, 255), B = C(120, 105, 130)},
		{Id = "PrismDiamond",    Name = "Prism Diamond",    Rarity = "Legendary", Shape = "gem",     A = C(235, 250, 255), B = C(255, 140, 220), Big = true},
		{Id = "StarlightOpal",   Name = "Starlight Opal",   Rarity = "Mythic",    Shape = "opal",    A = C(225, 240, 255), B = C(150, 255, 230)},
	}},
	{Id = "Retro", Tab = "RETRO", Name = "Pixel Artifacts", Color = C(255, 120, 200), Items = {
		{Id = "PixelCoin",      Name = "Pixel Coin",      Rarity = "Common",    Shape = "coin",      A = C(255, 205, 60), B = C(255, 240, 150), Pixels = true},
		{Id = "ArcadeToken",    Name = "Arcade Token",    Rarity = "Rare",      Shape = "coin",      A = C(170, 90, 255), B = C(90, 230, 255)},
		{Id = "GameCartridge",  Name = "Game Cartridge",  Rarity = "Epic",      Shape = "cartridge", A = C(110, 115, 135), B = C(255, 90, 170)},
		{Id = "GoldenJoystick", Name = "Golden Joystick", Rarity = "Legendary", Shape = "joystick",  A = C(255, 200, 60), B = C(255, 70, 80)},
		{Id = "GlitchCube",     Name = "Glitch Cube",     Rarity = "Mythic",    Shape = "cube",      A = C(60, 40, 110), B = C(80, 255, 230)},
	}},
	{Id = "Jungle", Tab = "JUNGLE", Name = "Ancient Treasures", Color = C(110, 210, 110), Items = {
		{Id = "ClayIdol",       Name = "Clay Idol",      Rarity = "Common",    Shape = "idol",      A = C(205, 120, 80), B = C(245, 200, 150)},
		{Id = "JadeMask",       Name = "Jade Mask",      Rarity = "Rare",      Shape = "mask",      A = C(70, 190, 120), B = C(255, 205, 70)},
		{Id = "GoldenTotem",    Name = "Golden Totem",   Rarity = "Epic",      Shape = "totem",     A = C(255, 195, 60), B = C(60, 170, 110)},
		{Id = "SunMedallion",   Name = "Sun Medallion",  Rarity = "Legendary", Shape = "medallion", A = C(255, 200, 50), B = C(255, 120, 50)},
		{Id = "EmeraldSkull",   Name = "Emerald Skull",  Rarity = "Mythic",    Shape = "skull",     A = C(70, 230, 140), B = C(255, 215, 80), Glass = true},
	}},
	{Id = "AbsoluteZero", Tab = "ABS. ZERO", Name = "Frozen Cosmic Relics", Color = C(150, 200, 255), Items = {
		{Id = "CometShard",     Name = "Comet Shard",        Rarity = "Common",    Shape = "shard",  A = C(170, 220, 255), B = C(255, 255, 255)},
		{Id = "FrozenStar",     Name = "Frozen Star",        Rarity = "Rare",      Shape = "star",   A = C(200, 235, 255), B = C(120, 200, 255)},
		{Id = "NebulaOrb",      Name = "Nebula Orb",         Rarity = "Epic",      Shape = "orb",    A = C(150, 90, 255), B = C(255, 120, 220), Ring = true},
		{Id = "CryoPlanet",     Name = "Cryo Planet",        Rarity = "Legendary", Shape = "planet", A = C(120, 200, 255), B = C(230, 245, 255)},
		{Id = "AbsoluteCore",   Name = "Absolute Zero Core", Rarity = "Mythic",    Shape = "core",   A = C(170, 240, 255), B = C(120, 140, 255)},
	}},
}
-- PNG ICONS (2026-10-01): paste uploaded image ids here, e.g. FrostButton = "rbxassetid://123456789".
-- Empty = colourful emoji placeholder. Every GUI and the in-world reveal pick these up automatically.
-- Art spec, prompts and file names: outputs/TreasureIcons20261001/ in the project folder (transparent PNG, centred, no text).
TC.Images = {
	MenuIcon = "", -- chest on the TREASURES button and book banner
	FrostButton = "", SnowflakeCharm = "", IcicleBell = "", FrozenWatch = "", HeartOfWinter = "",
	TinyBone = "", AmmoniteShell = "", RaptorClaw = "", GoldenScarab = "", DragonSkull = "",
	SpookyCandle = "", GhostLantern = "", CursedMask = "", CrystalBall = "", PhantomCrown = "",
	QuartzChip = "", Sapphire = "", AmethystCluster = "", PrismDiamond = "", StarlightOpal = "",
	PixelCoin = "", ArcadeToken = "", GameCartridge = "", GoldenJoystick = "", GlitchCube = "",
	ClayIdol = "", JadeMask = "", GoldenTotem = "", SunMedallion = "", EmeraldSkull = "",
	CometShard = "", FrozenStar = "", NebulaOrb = "", CryoPlanet = "", AbsoluteCore = "",
}
-- placeholders shown until a PNG id is filled in
TC.Emoji = {
	FrostButton = "🔘", SnowflakeCharm = "❄️", IcicleBell = "🔔", FrozenWatch = "⏱️", HeartOfWinter = "💙",
	TinyBone = "🦴", AmmoniteShell = "🐚", RaptorClaw = "🦖", GoldenScarab = "🐞", DragonSkull = "💀",
	SpookyCandle = "🕯️", GhostLantern = "🏮", CursedMask = "🎭", CrystalBall = "🔮", PhantomCrown = "👑",
	QuartzChip = "💗", Sapphire = "🔷", AmethystCluster = "💜", PrismDiamond = "💎", StarlightOpal = "🌈",
	PixelCoin = "💰", ArcadeToken = "🎟️", GameCartridge = "🎮", GoldenJoystick = "🕹️", GlitchCube = "👾",
	ClayIdol = "🗿", JadeMask = "💚", GoldenTotem = "🏆", SunMedallion = "☀️", EmeraldSkull = "☠️",
	CometShard = "☄️", FrozenStar = "⭐", NebulaOrb = "🌌", CryoPlanet = "🌐", AbsoluteCore = "💫",
}
TC.RarityById, TC.ById, TC.BiomeById, TC.TotalWeight = {}, {}, {}, 0
for i, r in ipairs(TC.Rarities) do r.Order = i; TC.RarityById[r.Id] = r; TC.TotalWeight += r.Weight end
for _, b in ipairs(TC.Biomes) do
	TC.BiomeById[b.Id] = b
	b.ByRarity = {}
	for _, it in ipairs(b.Items) do
		it.Biome = b.Id; TC.ById[it.Id] = it; b.ByRarity[it.Rarity] = it
		it.Image = ((TC.Images[it.Id] or "") ~= "") and TC.Images[it.Id] or nil
		it.Emoji = TC.Emoji[it.Id] or "✨"
	end
end
-- odds per fully dug tile, as "1 in N"
for _, r in ipairs(TC.Rarities) do r.OneIn = math.floor(1 / (TC.TileChance * r.Weight / TC.TotalWeight) + 0.5) end
-- which collection a field belongs to (Portal fields share the cosmic set)
function TC.BiomeFor(style)
	if style == "Portal" then return TC.BiomeById.AbsoluteZero end
	return TC.BiomeById[style or "Starter"] or TC.BiomeById.Starter
end
return TC

