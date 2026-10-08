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
	-- WORLD 2 (2026-10-02, Claude): World = 2 puts a set behind the treasure book's WORLD switch. Icons are Blender renders.
	{Id = "Sakura", Tab = "SAKURA", Name = "Blossom Keepsakes", World = 2, Color = C(255, 150, 195), Items = {
		{Id = "BlossomPetal",    Name = "Blossom Petal",  Rarity = "Common",    Shape = "heart", A = C(255, 156, 198), B = C(255, 227, 239)},
		{Id = "PaperFan",        Name = "Paper Fan",      Rarity = "Rare",      Shape = "shell", A = C(255, 127, 176), B = C(255, 240, 246)},
		{Id = "JadeTeacup",      Name = "Jade Teacup",    Rarity = "Epic",      Shape = "bell",  A = C(79, 181, 138), B = C(255, 201, 74)},
		{Id = "GoldenKoiStatue", Name = "Golden Koi",     Rarity = "Legendary", Shape = "idol",  A = C(255, 201, 74), B = C(111, 211, 230)},
		{Id = "EternalSakura",   Name = "Eternal Sakura", Rarity = "Mythic",    Shape = "opal",  A = C(255, 184, 218), B = C(255, 242, 168)},
	}},
	{Id = "Candy", Tab = "CANDY", Name = "Sweet Treats", World = 2, Color = C(255, 127, 176), Items = {
		{Id = "GummyDrop",      Name = "Gummy Drop",            Rarity = "Common",    Shape = "gem",     A = C(255, 77, 109), B = C(255, 154, 174)},
		{Id = "SwirlLollipop",  Name = "Swirl Lollipop",        Rarity = "Rare",      Shape = "coin",    A = C(255, 127, 176), B = C(255, 255, 255)},
		{Id = "GoldenBonbon",   Name = "Golden Bonbon",         Rarity = "Epic",      Shape = "orb",     A = C(255, 201, 74), B = C(255, 77, 109)},
		{Id = "ChocolateCrown", Name = "Chocolate Crown",       Rarity = "Legendary", Shape = "crown",   A = C(122, 74, 46), B = C(255, 243, 220)},
		{Id = "RainbowCrystal", Name = "Rainbow Sugar Crystal", Rarity = "Mythic",    Shape = "cluster", A = C(255, 127, 176), B = C(143, 211, 255)},
	}},
	{Id = "Atlantis", Tab = "ATLANTIS", Name = "Ocean Relics", World = 2, Color = C(63, 208, 212), Items = {
		{Id = "SpiralSeashell",   Name = "Spiral Seashell",   Rarity = "Common",    Shape = "shell",  A = C(255, 214, 176), B = C(255, 158, 138)},
		{Id = "StarfishCharm",    Name = "Starfish Charm",    Rarity = "Rare",      Shape = "star",   A = C(255, 138, 92), B = C(255, 201, 74)},
		{Id = "PearlNecklace",    Name = "Pearl Necklace",    Rarity = "Epic",      Shape = "orb",    A = C(255, 248, 238), B = C(255, 184, 214)},
		{Id = "GoldenTrident",    Name = "Golden Trident",    Rarity = "Legendary", Shape = "totem",  A = C(255, 201, 74), B = C(63, 208, 212)},
		{Id = "AtlanteanCrystal", Name = "Atlantean Crystal", Rarity = "Mythic",    Shape = "core",   A = C(127, 244, 240), B = C(255, 201, 74)},
	}},
	{Id = "Toybox", Tab = "TOYBOX", Name = "Toy Treasures", World = 2, Color = C(255, 154, 60), Items = {
		{Id = "WoodenBlock",     Name = "Wooden Block",        Rarity = "Common",    Shape = "cube",   A = C(227, 168, 102), B = C(255, 75, 75)},
		{Id = "SpinningTopT",    Name = "Spinning Top",        Rarity = "Rare",      Shape = "orb",    A = C(255, 75, 75), B = C(255, 210, 63)},
		{Id = "WindupKey",       Name = "Wind-up Key",         Rarity = "Epic",      Shape = "totem",  A = C(255, 201, 74), B = C(224, 163, 37)},
		{Id = "RockingHorse",    Name = "Golden Rocking Horse", Rarity = "Legendary", Shape = "idol",   A = C(255, 201, 74), B = C(255, 75, 75)},
		{Id = "MusicBox",        Name = "Rainbow Music Box",   Rarity = "Mythic",    Shape = "core",   A = C(156, 107, 255), B = C(255, 154, 213)},
	}},
	{Id = "Clockwork", Tab = "CLOCKWORK", Name = "Clockwork Curios", World = 2, Color = C(224, 176, 74), Items = {
		{Id = "BrassCog",        Name = "Brass Cog",           Rarity = "Common",    Shape = "star",   A = C(217, 165, 74), B = C(63, 191, 180)},
		{Id = "PocketWatch",     Name = "Pocket Watch",        Rarity = "Rare",      Shape = "orb",    A = C(255, 201, 74), B = C(255, 255, 255)},
		{Id = "SteamWhistle",    Name = "Steam Whistle",       Rarity = "Epic",      Shape = "totem",  A = C(217, 165, 74), B = C(63, 191, 180)},
		{Id = "Gyroscope",       Name = "Golden Gyroscope",    Rarity = "Legendary", Shape = "idol",   A = C(255, 201, 74), B = C(63, 191, 180)},
		{Id = "Hourglass",       Name = "Hourglass of Time",   Rarity = "Mythic",    Shape = "core",   A = C(180, 140, 255), B = C(255, 201, 74)},
	}},
	{Id = "Cloud", Tab = "CLOUD", Name = "Sky Treasures", World = 2, Color = C(143, 208, 255), Items = {
		{Id = "CloudPuff",       Name = "Smiling Cloud Puff",  Rarity = "Common",    Shape = "orb",    A = C(247, 249, 255), B = C(226, 219, 255)},
		{Id = "SilverFeather",   Name = "Silver Feather",      Rarity = "Rare",      Shape = "totem",  A = C(232, 238, 248), B = C(201, 211, 230)},
		{Id = "RainbowPrism",    Name = "Rainbow Prism",       Rarity = "Epic",      Shape = "core",   A = C(233, 247, 255), B = C(177, 151, 252)},
		{Id = "GoldenHarp",      Name = "Golden Harp",         Rarity = "Legendary", Shape = "idol",   A = C(255, 210, 90), B = C(255, 243, 196)},
		{Id = "SunCrown",        Name = "Crown of the Sun",    Rarity = "Mythic",    Shape = "star",   A = C(255, 210, 90), B = C(255, 230, 128)},
	}},
	{Id = "Cosmic", Tab = "COSMIC", Name = "Cosmic Wonders", World = 2, Color = C(126, 91, 239), Items = {
		{Id = "StardustJar",     Name = "Jar of Stardust",     Rarity = "Common",    Shape = "orb",    A = C(216, 244, 255), B = C(169, 139, 255)},
		{Id = "Meteorite",       Name = "Glowing Meteorite",   Rarity = "Rare",      Shape = "cube",   A = C(90, 78, 140), B = C(255, 176, 96)},
		{Id = "MoonCrystal",     Name = "Moon Crystal",        Rarity = "Epic",      Shape = "core",   A = C(203, 184, 255), B = C(255, 210, 90)},
		{Id = "GoldenAstrolabe", Name = "Golden Astrolabe",    Rarity = "Legendary", Shape = "idol",   A = C(255, 210, 90), B = C(169, 139, 255)},
		{Id = "GalaxyHeart",     Name = "Heart of the Galaxy", Rarity = "Mythic",    Shape = "star",   A = C(106, 63, 216), B = C(127, 233, 255)},
	}},
}
-- PNG ICONS (2026-10-01): paste uploaded image ids here, e.g. FrostButton = "rbxassetid://123456789".
-- Empty = colourful emoji placeholder. Every GUI and the in-world reveal pick these up automatically.
-- Art spec, prompts and file names: outputs/TreasureIcons20261001/ in the project folder (transparent PNG, centred, no text).
TC.Images = {
	MenuIcon = "rbxassetid://105113026947158",
	FrostButton = "rbxassetid://109723918599269",
	SnowflakeCharm = "rbxassetid://139415027763561",
	IcicleBell = "rbxassetid://126773841167442",
	FrozenWatch = "rbxassetid://135132172883718",
	HeartOfWinter = "rbxassetid://134691793098580",
	TinyBone = "rbxassetid://77775334771157",
	AmmoniteShell = "rbxassetid://72454878295255",
	RaptorClaw = "rbxassetid://139854741779969",
	GoldenScarab = "rbxassetid://124356745983551",
	DragonSkull = "rbxassetid://111350001452413",
	SpookyCandle = "rbxassetid://85402999219659",
	GhostLantern = "rbxassetid://101686619019494",
	CursedMask = "rbxassetid://99355040667476",
	CrystalBall = "rbxassetid://138016704672915",
	PhantomCrown = "rbxassetid://128757749993890",
	QuartzChip = "rbxassetid://113746322604324",
	Sapphire = "rbxassetid://102451277874448",
	AmethystCluster = "rbxassetid://125590266042158",
	PrismDiamond = "rbxassetid://138122923515640",
	StarlightOpal = "rbxassetid://85732087601035",
	PixelCoin = "rbxassetid://79949125833310",
	ArcadeToken = "rbxassetid://95640875316732",
	GameCartridge = "rbxassetid://92593956607890",
	GoldenJoystick = "rbxassetid://130357109848691",
	GlitchCube = "rbxassetid://133569084579066",
	ClayIdol = "rbxassetid://117194026150304",
	JadeMask = "rbxassetid://85045672596829",
	GoldenTotem = "rbxassetid://136930286122766",
	SunMedallion = "rbxassetid://76784373950664",
	EmeraldSkull = "rbxassetid://102517903809272",
	CometShard = "rbxassetid://98333681124349",
	FrozenStar = "rbxassetid://91227146450850",
	NebulaOrb = "rbxassetid://133594279551757",
	CryoPlanet = "rbxassetid://78590231237652",
	AbsoluteCore = "rbxassetid://89043923486970",
	-- World 2 (2026-10-02, Claude, Blender renders)
	BlossomPetal = "rbxassetid://73635057157131",
	PaperFan = "rbxassetid://113422678955796",
	JadeTeacup = "rbxassetid://84386347032947",
	GoldenKoiStatue = "rbxassetid://81786813082429",
	EternalSakura = "rbxassetid://134209208393091",
	GummyDrop = "rbxassetid://97297997944960",
	SwirlLollipop = "rbxassetid://87127884094421",
	GoldenBonbon = "rbxassetid://74556024904252",
	ChocolateCrown = "rbxassetid://125455778493343",
	RainbowCrystal = "rbxassetid://100777338157612",
	SpiralSeashell = "rbxassetid://132815611871816",
	StarfishCharm = "rbxassetid://121740450627528",
	PearlNecklace = "rbxassetid://79717924439989",
	GoldenTrident = "rbxassetid://101270188457121",
	AtlanteanCrystal = "rbxassetid://128672071326975",
	WoodenBlock = "rbxassetid://107859067123209", SpinningTopT = "rbxassetid://129665311931065", WindupKey = "rbxassetid://131475141209975",
	RockingHorse = "rbxassetid://105638386258236", MusicBox = "rbxassetid://98454880872067",
	BrassCog = "rbxassetid://133491296254918", PocketWatch = "rbxassetid://135550439948904", SteamWhistle = "rbxassetid://105895755355498",
	Gyroscope = "rbxassetid://72849291166890", Hourglass = "rbxassetid://130613567826098",
	CloudPuff = "rbxassetid://114560773286345", SilverFeather = "rbxassetid://88901710271225", RainbowPrism = "rbxassetid://85608216622473",
	GoldenHarp = "rbxassetid://89481470349933", SunCrown = "rbxassetid://104523280360877",
	StardustJar = "rbxassetid://86490790858895", Meteorite = "rbxassetid://72076278908927", MoonCrystal = "rbxassetid://140385465560290",
	GoldenAstrolabe = "rbxassetid://109131514631639", GalaxyHeart = "rbxassetid://85477572614999",
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
	BlossomPetal = "🌸", PaperFan = "🪭", JadeTeacup = "🍵", GoldenKoiStatue = "🐟", EternalSakura = "🌺",
	GummyDrop = "🍬", SwirlLollipop = "🍭", GoldenBonbon = "🍫", ChocolateCrown = "👑", RainbowCrystal = "🌈",
	SpiralSeashell = "🐚", StarfishCharm = "⭐", PearlNecklace = "📿", GoldenTrident = "🔱", AtlanteanCrystal = "💎",
	WoodenBlock = "🧱", SpinningTopT = "🪀", WindupKey = "🔑", RockingHorse = "🐴", MusicBox = "🎶",
	BrassCog = "⚙️", PocketWatch = "⌚", SteamWhistle = "📯", Gyroscope = "🌀", Hourglass = "⏳",
	CloudPuff = "☁️", SilverFeather = "🪶", RainbowPrism = "🌈", GoldenHarp = "🎵", SunCrown = "👑",
	StardustJar = "✨", Meteorite = "☄️", MoonCrystal = "🌙", GoldenAstrolabe = "🧭", GalaxyHeart = "🌌",
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
