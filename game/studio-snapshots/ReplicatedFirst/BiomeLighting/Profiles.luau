-- Profiles for ReplicatedFirst.BiomeLighting (per-area client lighting) - lighting pass 2026-10-01.
-- Zones are checked in order and the first match wins. Box = XZ range [Min, Max); Circle = Center + Radius.
-- Outside every zone the current lighting is kept, so gaps between areas never pop.
-- The edit-time Lighting service is set to the Frostfall profile (what players see before this runs).
local C = Color3.fromRGB
local M = {}

M.Default = "Frostfall"
M.WalkBlend = 2.5    -- seconds to blend when walking into a new area
M.JumpBlend = 1.0    -- seconds to blend after a teleport or respawn
M.JumpDistance = 40  -- probe moving farther than this between frames counts as a teleport
M.Dwell = 0.25       -- a new area must persist this long before blending (no flicker at borders)

M.Zones = {
	-- World 2 (2026-10-03, Claude): winding layout - each stage is a 260-stud island, then a 60-stud bridge (stride 320 along +X); islands are offset in Z and Y.
	-- 2026-10-03 (Claude): MIST on every crossing between islands (listed first, so they win); with the cloud curtains the next map stays hidden.
	{Name = "Mist", Min = Vector2.new(1819, -300), Max = Vector2.new(1892, 300)}, -- 2026-10-03 resize: islands 234 long, bridges 86
	{Name = "Mist", Min = Vector2.new(2139, -300), Max = Vector2.new(2212, 300)},
	{Name = "Mist", Min = Vector2.new(2459, -300), Max = Vector2.new(2532, 300)},
	{Name = "Mist", Min = Vector2.new(2779, -300), Max = Vector2.new(2852, 300)},
	{Name = "Mist", Min = Vector2.new(3099, -300), Max = Vector2.new(3172, 300)},
	{Name = "Mist", Min = Vector2.new(3419, -300), Max = Vector2.new(3492, 300)},
	{Name = "Sakura", Min = Vector2.new(1540, -300), Max = Vector2.new(1855, 300)}, -- arrival plaza + Sakura Garden
	{Name = "Candy", Min = Vector2.new(1855, -300), Max = Vector2.new(2175, 300)},
	{Name = "Atlantis", Min = Vector2.new(2175, -300), Max = Vector2.new(2495, 300)},
	{Name = "Toybox", Min = Vector2.new(2495, -300), Max = Vector2.new(2815, 300)},
	{Name = "Clockwork", Min = Vector2.new(2815, -300), Max = Vector2.new(3135, 300)},
	{Name = "Cloud", Min = Vector2.new(3135, -300), Max = Vector2.new(3455, 300)},
	{Name = "Cosmic", Min = Vector2.new(3455, -300), Max = Vector2.new(4000, 300)}, -- 2026-10-03: Neon dropped, Cosmic moved into its slot (x 3498-3732)
	{Name = "Portal", Center = Vector2.new(-317, 255), Radius = 38},
	{Name = "AbsoluteZero", Min = Vector2.new(-700, 60), Max = Vector2.new(-183, 700)},
	{Name = "Jungle", Min = Vector2.new(-183, 140), Max = Vector2.new(24, 700)},
	{Name = "Retro", Min = Vector2.new(24, 140), Max = Vector2.new(169, 700)},
	{Name = "Crystal", Min = Vector2.new(169, 69), Max = Vector2.new(700, 700)},
	{Name = "Cursed", Min = Vector2.new(150, -155), Max = Vector2.new(700, 69)},
	{Name = "Desert", Min = Vector2.new(84, -700), Max = Vector2.new(700, -155)},
	{Name = "Frostfall", Min = Vector2.new(-700, -700), Max = Vector2.new(84, -120)}, -- lobby + Starter field
}

M.Profiles = {
	-- World 2 Sakura Garden: soft spring light, pink blossom haze, warm sun on the red wood.
	Sakura = {
		Brightness = 2.9, ExposureCompensation = -0.04,
		Ambient = C(132, 116, 126), OutdoorAmbient = C(170, 150, 170),
		ColorShift_Top = C(255, 236, 236), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.9, EnvironmentSpecularScale = 0.6, ShadowSoftness = 0.2,
		Atmosphere = {Density = 0.24, Offset = 0.15, Color = C(250, 222, 236), Decay = C(236, 176, 210), Glare = 0.25, Haze = 1.2},
		Bloom = {Intensity = 0.45, Size = 24, Threshold = 2.1},
		SunRays = {Intensity = 0.02, Spread = 0.14},
		Grade = {Brightness = 0.02, Contrast = 0.05, Saturation = 0.14, TintColor = C(255, 247, 250)},
	},
	-- Clean snow, cool blue shadows, warm sun so the cozy lamps and huts read warm.
	Frostfall = {
		Brightness = 2.7, ExposureCompensation = -0.08,
		Ambient = C(124, 118, 126), OutdoorAmbient = C(132, 156, 196),
		ColorShift_Top = C(255, 246, 232), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 0.85, ShadowSoftness = 0.18,
		Atmosphere = {Density = 0.26, Offset = 0.18, Color = C(214, 229, 246), Decay = C(160, 190, 226), Glare = 0.15, Haze = 1},
		Bloom = {Intensity = 0.45, Size = 22, Threshold = 2.1},
		SunRays = {Intensity = 0.012, Spread = 0.12},
		Grade = {Brightness = 0.01, Contrast = 0.06, Saturation = 0.12, TintColor = C(250, 252, 255)},
	},
	-- Warm sunlight, clear sandstone colors, light sandy haze.
	Desert = {
		Brightness = 3, ExposureCompensation = -0.02,
		Ambient = C(132, 116, 100), OutdoorAmbient = C(178, 150, 118),
		ColorShift_Top = C(255, 228, 184), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.75, EnvironmentSpecularScale = 0.5, ShadowSoftness = 0.15,
		Atmosphere = {Density = 0.27, Offset = 0.12, Color = C(242, 216, 174), Decay = C(236, 172, 112), Glare = 0.45, Haze = 1.6},
		Bloom = {Intensity = 0.4, Size = 22, Threshold = 2.2},
		SunRays = {Intensity = 0.03, Spread = 0.16},
		Grade = {Brightness = 0.02, Contrast = 0.07, Saturation = 0.16, TintColor = C(255, 248, 236)},
	},
	-- Mysterious purple, but bright enough to dig comfortably.
	Cursed = {
		Brightness = 2, ExposureCompensation = 0.12,
		Ambient = C(102, 84, 132), OutdoorAmbient = C(126, 100, 168),
		ColorShift_Top = C(208, 182, 255), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.45, EnvironmentSpecularScale = 0.6, ShadowSoftness = 0.25,
		Atmosphere = {Density = 0.34, Offset = 0.1, Color = C(152, 120, 198), Decay = C(98, 62, 152), Glare = 0, Haze = 2},
		Bloom = {Intensity = 0.55, Size = 24, Threshold = 1.7},
		SunRays = {Intensity = 0, Spread = 0.1},
		Grade = {Brightness = 0, Contrast = 0.1, Saturation = 0.06, TintColor = C(238, 228, 255)},
	},
	-- Colorful lavender/teal air, crystals pop with controlled glow.
	Crystal = {
		Brightness = 2.5, ExposureCompensation = 0,
		Ambient = C(126, 118, 152), OutdoorAmbient = C(150, 148, 206),
		ColorShift_Top = C(242, 234, 255), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.9, EnvironmentSpecularScale = 1, ShadowSoftness = 0.18,
		Atmosphere = {Density = 0.25, Offset = 0.15, Color = C(206, 200, 246), Decay = C(142, 176, 240), Glare = 0.3, Haze = 1.3},
		Bloom = {Intensity = 0.6, Size = 24, Threshold = 1.8},
		SunRays = {Intensity = 0.01, Spread = 0.12},
		Grade = {Brightness = 0, Contrast = 0.07, Saturation = 0.18, TintColor = C(249, 247, 255)},
	},
	-- Clear air and punchy contrast for playful neon accents.
	Retro = {
		Brightness = 2.7, ExposureCompensation = 0,
		Ambient = C(132, 116, 142), OutdoorAmbient = C(166, 142, 192),
		ColorShift_Top = C(255, 242, 250), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.75, EnvironmentSpecularScale = 0.8, ShadowSoftness = 0.15,
		Atmosphere = {Density = 0.2, Offset = 0.1, Color = C(250, 208, 236), Decay = C(192, 132, 255), Glare = 0.25, Haze = 1},
		Bloom = {Intensity = 0.6, Size = 20, Threshold = 1.8},
		SunRays = {Intensity = 0.01, Spread = 0.1},
		Grade = {Brightness = 0, Contrast = 0.12, Saturation = 0.22, TintColor = C(255, 250, 255)},
	},
	-- Warm green humidity with readable shadows. 2026-10-05 (Claude, W1 remaster): exposure -0.03 / contrast 0.09 so the carved temple stone keeps its detail.
	Jungle = {
		Brightness = 2.6, ExposureCompensation = -0.03,
		Ambient = C(112, 124, 100), OutdoorAmbient = C(132, 160, 118),
		ColorShift_Top = C(255, 238, 196), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.75, EnvironmentSpecularScale = 0.55, ShadowSoftness = 0.2,
		Atmosphere = {Density = 0.3, Offset = 0.15, Color = C(200, 230, 178), Decay = C(130, 174, 98), Glare = 0.25, Haze = 1.6},
		Bloom = {Intensity = 0.4, Size = 22, Threshold = 2.1},
		SunRays = {Intensity = 0.02, Spread = 0.14},
		Grade = {Brightness = 0, Contrast = 0.09, Saturation = 0.16, TintColor = C(247, 255, 241)},
	},
	-- Crisp icy blues and bright snow; exposure kept down so snow keeps its detail. 2026-10-05 (Claude): bloom threshold 2.2 so the cyan cores glow.
	AbsoluteZero = {
		Brightness = 2.8, ExposureCompensation = -0.12,
		Ambient = C(120, 130, 152), OutdoorAmbient = C(138, 172, 222),
		ColorShift_Top = C(238, 246, 255), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ShadowSoftness = 0.15,
		Atmosphere = {Density = 0.22, Offset = 0.1, Color = C(216, 236, 255), Decay = C(152, 202, 255), Glare = 0.25, Haze = 0.8},
		Bloom = {Intensity = 0.35, Size = 20, Threshold = 2.2},
		SunRays = {Intensity = 0.015, Spread = 0.12},
		Grade = {Brightness = 0.01, Contrast = 0.09, Saturation = 0.06, TintColor = C(243, 250, 255)},
	},
	-- Magical focal point: soft violet air, restrained glow.
	Portal = {
		Brightness = 2.5, ExposureCompensation = -0.05,
		Ambient = C(124, 122, 162), OutdoorAmbient = C(140, 150, 216),
		ColorShift_Top = C(230, 222, 255), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.9, EnvironmentSpecularScale = 1, ShadowSoftness = 0.18,
		Atmosphere = {Density = 0.24, Offset = 0.1, Color = C(212, 212, 255), Decay = C(166, 152, 255), Glare = 0.3, Haze = 1},
		Bloom = {Intensity = 0.5, Size = 22, Threshold = 2},
		SunRays = {Intensity = 0.012, Spread = 0.12},
		Grade = {Brightness = 0, Contrast = 0.09, Saturation = 0.12, TintColor = C(245, 243, 255)},
	},
	-- WORLD 2 (2026-10-02, Claude): bright and readable; effects stay restrained.
	Mist = {
		Brightness = 2.6, ExposureCompensation = 0.05,
		Ambient = C(160, 160, 172), OutdoorAmbient = C(196, 200, 216),
		ColorShift_Top = C(240, 242, 250), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.7, EnvironmentSpecularScale = 0.4, ShadowSoftness = 0.4,
		Atmosphere = {Density = 0.45, Offset = 0, Color = C(238, 241, 250), Decay = C(222, 226, 242), Glare = 0, Haze = 2.0},
		Bloom = {Intensity = 0.35, Size = 24, Threshold = 2.2},
		SunRays = {Intensity = 0, Spread = 0.1},
		Grade = {Brightness = 0.03, Contrast = 0, Saturation = 0.02, TintColor = C(248, 249, 255)},
	},
	Candy = {
		Brightness = 3.0, ExposureCompensation = -0.02,
		Ambient = C(140, 120, 132), OutdoorAmbient = C(186, 160, 182),
		ColorShift_Top = C(255, 238, 244), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.9, EnvironmentSpecularScale = 0.6, ShadowSoftness = 0.2,
		Atmosphere = {Density = 0.22, Offset = 0.15, Color = C(255, 226, 240), Decay = C(255, 186, 220), Glare = 0.25, Haze = 1},
		Bloom = {Intensity = 0.45, Size = 24, Threshold = 2.1},
		SunRays = {Intensity = 0.02, Spread = 0.14},
		Grade = {Brightness = 0.02, Contrast = 0.05, Saturation = 0.18, TintColor = C(255, 248, 252)},
	},
	Atlantis = {
		Brightness = 2.4, ExposureCompensation = 0,
		Ambient = C(92, 138, 148), OutdoorAmbient = C(112, 178, 190),
		ColorShift_Top = C(190, 245, 255), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.8, EnvironmentSpecularScale = 0.7, ShadowSoftness = 0.3,
		Atmosphere = {Density = 0.38, Offset = 0.1, Color = C(150, 228, 236), Decay = C(56, 160, 186), Glare = 0, Haze = 2.2},
		Bloom = {Intensity = 0.5, Size = 26, Threshold = 1.9},
		SunRays = {Intensity = 0.06, Spread = 0.3},
		Grade = {Brightness = 0.01, Contrast = 0.06, Saturation = 0.1, TintColor = C(228, 250, 255)},
	},
	Toybox = {
		Brightness = 3.0, ExposureCompensation = -0.04,
		Ambient = C(132, 126, 120), OutdoorAmbient = C(162, 162, 172),
		ColorShift_Top = C(255, 244, 228), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 0.7, ShadowSoftness = 0.15,
		Atmosphere = {Density = 0.18, Offset = 0.2, Color = C(236, 240, 255), Decay = C(190, 206, 236), Glare = 0.1, Haze = 0.6},
		Bloom = {Intensity = 0.4, Size = 22, Threshold = 2.2},
		SunRays = {Intensity = 0.015, Spread = 0.12},
		Grade = {Brightness = 0.02, Contrast = 0.07, Saturation = 0.2, TintColor = C(255, 255, 255)},
	},
	Clockwork = {
		Brightness = 2.6, ExposureCompensation = -0.02,
		Ambient = C(130, 112, 92), OutdoorAmbient = C(172, 146, 120),
		ColorShift_Top = C(255, 226, 182), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.85, EnvironmentSpecularScale = 0.9, ShadowSoftness = 0.2,
		Atmosphere = {Density = 0.3, Offset = 0.12, Color = C(240, 214, 178), Decay = C(196, 148, 108), Glare = 0.2, Haze = 1.4},
		Bloom = {Intensity = 0.5, Size = 24, Threshold = 2},
		SunRays = {Intensity = 0.03, Spread = 0.16},
		Grade = {Brightness = 0.01, Contrast = 0.08, Saturation = 0.1, TintColor = C(255, 245, 232)},
	},
	Cloud = {
		Brightness = 3.2, ExposureCompensation = -0.06,
		Ambient = C(150, 150, 170), OutdoorAmbient = C(190, 196, 232),
		ColorShift_Top = C(255, 246, 236), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 0.6, ShadowSoftness = 0.25,
		Atmosphere = {Density = 0.2, Offset = 0.25, Color = C(236, 240, 255), Decay = C(204, 192, 255), Glare = 0.3, Haze = 0.8},
		Bloom = {Intensity = 0.5, Size = 24, Threshold = 2.1},
		SunRays = {Intensity = 0.03, Spread = 0.2},
		Grade = {Brightness = 0.02, Contrast = 0.04, Saturation = 0.1, TintColor = C(250, 250, 255)},
	},
	Neon = {
		Brightness = 1.4, ExposureCompensation = 0.1,
		Ambient = C(70, 70, 120), OutdoorAmbient = C(84, 90, 150),
		ColorShift_Top = C(150, 170, 255), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.5, EnvironmentSpecularScale = 0.9, ShadowSoftness = 0.3,
		Atmosphere = {Density = 0.32, Offset = 0.08, Color = C(90, 96, 170), Decay = C(150, 70, 190), Glare = 0, Haze = 1.6},
		Bloom = {Intensity = 0.6, Size = 24, Threshold = 1.6},
		SunRays = {Intensity = 0, Spread = 0.1},
		Grade = {Brightness = 0, Contrast = 0.1, Saturation = 0.18, TintColor = C(238, 236, 255)},
	},
	Cosmic = {
		Brightness = 1.7, ExposureCompensation = 0.08,
		Ambient = C(92, 82, 132), OutdoorAmbient = C(112, 100, 172),
		ColorShift_Top = C(214, 200, 255), ColorShift_Bottom = C(0, 0, 0),
		EnvironmentDiffuseScale = 0.55, EnvironmentSpecularScale = 0.8, ShadowSoftness = 0.3,
		Atmosphere = {Density = 0.34, Offset = 0.1, Color = C(124, 104, 204), Decay = C(64, 44, 144), Glare = 0.2, Haze = 1.8},
		Bloom = {Intensity = 0.6, Size = 26, Threshold = 1.7},
		SunRays = {Intensity = 0.01, Spread = 0.12},
		Grade = {Brightness = 0.01, Contrast = 0.09, Saturation = 0.14, TintColor = C(240, 234, 255)},
	},
}

return M
