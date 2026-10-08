-- TreasureModels (2026-10-01, Claude): chunky procedural 3D treasures for TreasureConfig items (+ the menu chest).
-- Build(item) returns an anchored, non-colliding Model about 2 studs across; PrimaryPart "Root" sits at its centre.
local M = {}
local SMOOTH, NEON = Enum.Material.SmoothPlastic, Enum.Material.Neon
local CF, ANG, R = CFrame.new, CFrame.Angles, math.rad
local FACE = ANG(0, R(90), 0)  -- cylinder axis (X) turned to face forward (Z)
local UP = ANG(0, 0, R(90))    -- cylinder axis (X) turned upright (Y)
local DARK = Color3.fromRGB(45, 40, 60)
local WHITE = Color3.new(1, 1, 1)

local function part(m, name, shape, size, color, cf, mat, tr)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = mat or SMOOTH
	p.Transparency = tr or 0
	p.CFrame = cf or CF()
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end
local function ball(m, n, d, c, cf, mat, tr) return part(m, n, Enum.PartType.Ball, Vector3.new(d, d, d), c, cf, mat, tr) end
local function block(m, n, s, c, cf, mat, tr) return part(m, n, Enum.PartType.Block, s, c, cf, mat, tr) end
local function cyl(m, n, len, d, c, cf, mat, tr) return part(m, n, Enum.PartType.Cylinder, Vector3.new(len, d, d), c, cf, mat, tr) end
local function ell(m, n, s, c, cf, mat, tr)
	local p = block(m, n, s, c, cf, mat, tr)
	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.Sphere
	sm.Parent = p
	return p
end
local function beads(m, n, radius, count, d, c, cf, mat)
	for i = 1, count do
		local a = i / count * math.pi * 2
		ball(m, n .. i, d, c, cf * CF(math.cos(a) * radius, math.sin(a) * radius, 0), mat)
	end
end
local function shade(c, k) return c:Lerp(Color3.new(0, 0, 0), k) end

local B = {}
function B.button(m, it)
	cyl(m, "Disc", 0.4, 1.9, it.A, FACE)
	cyl(m, "Rim", 0.46, 1.3, it.B, FACE)
	for _, o in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
		ball(m, "Hole", 0.3, shade(it.A, 0.45), CF(o[1] * 0.23, o[2] * 0.23, 0.17))
		ball(m, "HoleBack", 0.3, shade(it.A, 0.45), CF(o[1] * 0.23, o[2] * 0.23, -0.17))
	end
end
function B.snowflake(m, it)
	ball(m, "Hub", 0.62, it.B, CF(), NEON)
	for i = 0, 2 do block(m, "Arm" .. i, Vector3.new(0.26, 2.1, 0.26), it.A, ANG(0, 0, R(60 * i))) end
	for i = 0, 5 do
		local a = R(60 * i)
		ball(m, "Tip" .. i, 0.4, it.B, CF(math.sin(a) * 1.05, math.cos(a) * 1.05, 0))
		block(m, "Twig" .. i, Vector3.new(0.16, 0.5, 0.16), it.A, CF(math.sin(a) * 0.62, math.cos(a) * 0.62, 0) * ANG(0, 0, -a + R(90)))
	end
end
function B.bell(m, it)
	ell(m, "Dome", Vector3.new(1.55, 1.75, 1.55), it.A, CF(0, 0.1, 0), SMOOTH, 0.08)
	cyl(m, "Lip", 0.32, 1.95, it.A, CF(0, -0.62, 0) * UP)
	cyl(m, "Band", 0.22, 1.62, it.B, CF(0, -0.25, 0) * UP)
	ball(m, "Clapper", 0.5, it.B, CF(0, -0.88, 0), NEON)
	ball(m, "Knob", 0.42, it.B, CF(0, 1.02, 0))
end
function B.watch(m, it)
	cyl(m, "Case", 0.46, 1.85, it.A, FACE)
	cyl(m, "Face", 0.5, 1.45, it.B, FACE)
	block(m, "HourHand", Vector3.new(0.13, 0.45, 0.06), DARK, CF(0, 0.2, 0.27))
	block(m, "MinuteHand", Vector3.new(0.1, 0.62, 0.06), DARK, CF(0.24, 0.12, 0.27) * ANG(0, 0, R(-60)))
	ball(m, "Pin", 0.16, it.A, CF(0, 0, 0.27))
	cyl(m, "Stem", 0.36, 0.34, it.A, CF(0, 1.05, 0) * UP)
	ball(m, "Bow", 0.42, it.A, CF(0, 1.32, 0))
	for i = 1, 4 do ball(m, "Chain" .. i, 0.2, it.A, CF(0.18 + i * 0.2, 1.42 - i * 0.12, 0)) end
end
function B.heart(m, it)
	ball(m, "LobeL", 1.15, it.A, CF(-0.4, 0.3, 0), SMOOTH, 0.05)
	ball(m, "LobeR", 1.15, it.A, CF(0.4, 0.3, 0), SMOOTH, 0.05)
	block(m, "Point", Vector3.new(1.12, 1.12, 0.9), it.A, CF(0, -0.2, 0) * ANG(0, 0, R(45)), SMOOTH, 0.05)
	ball(m, "Core", 0.62, it.B, CF(0, 0.12, 0.38), NEON)
	for i = 1, 3 do ball(m, "Frost" .. i, 0.22, WHITE, CF(-0.6 + i * 0.3, 0.75 + (i % 2) * 0.08, 0.3)) end
end
function B.bone(m, it)
	local tilt = ANG(0, 0, R(30))
	cyl(m, "Shaft", 1.5, 0.42, it.A, tilt)
	for _, sx in ipairs({-1, 1}) do
		for _, sy in ipairs({-1, 1}) do ball(m, "Knob", 0.55, it.B, tilt * CF(sx * 0.78, sy * 0.2, 0)) end
	end
end
function B.shell(m, it)
	cyl(m, "Back", 0.3, 1.65, shade(it.A, 0.15), CF(0, 0, -0.12) * FACE)
	for i = 0, 7 do
		local a, r = i * 0.95, 0.12 + i * 0.1
		ball(m, "Coil" .. i, 0.3 + i * 0.075, (i % 2 == 0) and it.A or it.B, CF(math.cos(a) * r, math.sin(a) * r, 0.12))
	end
end
function B.claw(m, it)
	ell(m, "Root", Vector3.new(0.75, 0.7, 0.6), it.A, CF(-0.25, -0.75, 0))
	ell(m, "Mid", Vector3.new(0.6, 0.85, 0.5), it.A, CF(-0.05, -0.15, 0) * ANG(0, 0, R(-18)))
	ell(m, "Upper", Vector3.new(0.48, 0.8, 0.42), it.A, CF(0.22, 0.45, 0) * ANG(0, 0, R(-35)))
	ell(m, "Tip", Vector3.new(0.3, 0.6, 0.3), it.B, CF(0.55, 0.9, 0) * ANG(0, 0, R(-55)))
	cyl(m, "Band", 0.2, 0.8, Color3.fromRGB(200, 150, 70), CF(-0.25, -0.5, 0) * UP)
end
function B.scarab(m, it)
	ell(m, "Body", Vector3.new(1.25, 1.55, 0.8), it.A, CF(0, -0.15, 0))
	ell(m, "WingL", Vector3.new(0.62, 1.25, 0.3), it.B, CF(-0.31, -0.2, 0.32) * ANG(0, 0, R(6)))
	ell(m, "WingR", Vector3.new(0.62, 1.25, 0.3), it.B, CF(0.31, -0.2, 0.32) * ANG(0, 0, R(-6)))
	ball(m, "Head", 0.62, it.A, CF(0, 0.78, 0.05))
	ball(m, "Gem", 0.3, Color3.fromRGB(255, 80, 90), CF(0, 0.82, 0.3), NEON)
	for _, s in ipairs({-1, 1}) do
		for j = 0, 2 do cyl(m, "Leg", 0.55, 0.12, it.A, CF(s * 0.68, -0.55 + j * 0.42, 0) * ANG(0, 0, R(s * (20 - j * 20)))) end
	end
end
function B.skull(m, it)
	local tr = it.Glass and 0.12 or 0
	ball(m, "Cranium", 1.6, it.A, CF(0, 0.22, 0), SMOOTH, tr)
	ell(m, "Jaw", Vector3.new(1.1, 0.62, 1.0), it.A, CF(0, -0.52, 0.16), SMOOTH, tr)
	local eye, eyeMat = (it.Glass and it.B or DARK), (it.Glass and NEON or SMOOTH)
	ell(m, "EyeL", Vector3.new(0.42, 0.48, 0.3), eye, CF(-0.33, 0.22, 0.66), eyeMat)
	ell(m, "EyeR", Vector3.new(0.42, 0.48, 0.3), eye, CF(0.33, 0.22, 0.66), eyeMat)
	ell(m, "Nose", Vector3.new(0.18, 0.22, 0.2), DARK, CF(0, -0.08, 0.76))
	for i = -1, 1 do block(m, "Tooth", Vector3.new(0.16, 0.18, 0.12), WHITE, CF(i * 0.2, -0.42, 0.64)) end
	if it.Horns then
		ell(m, "HornL", Vector3.new(0.32, 1.05, 0.32), it.B, CF(-0.62, 0.95, -0.15) * ANG(0, 0, R(28)))
		ell(m, "HornR", Vector3.new(0.32, 1.05, 0.32), it.B, CF(0.62, 0.95, -0.15) * ANG(0, 0, R(-28)))
	end
end
function B.candle(m, it)
	cyl(m, "Dish", 0.2, 1.4, Color3.fromRGB(90, 80, 110), CF(0, -0.82, 0) * UP)
	cyl(m, "Wax", 1.3, 0.85, it.A, CF(0, -0.05, 0) * UP)
	for i = 1, 3 do ball(m, "Drip" .. i, 0.26, it.A, CF(math.cos(i * 2.1) * 0.4, 0.45 - i * 0.12, math.sin(i * 2.1) * 0.4)) end
	block(m, "Wick", Vector3.new(0.08, 0.22, 0.08), DARK, CF(0, 0.7, 0))
	ell(m, "Flame", Vector3.new(0.38, 0.62, 0.38), it.B, CF(0, 1.05, 0), NEON)
end
function B.lantern(m, it)
	cyl(m, "Top", 0.25, 1.15, it.A, CF(0, 0.82, 0) * UP)
	cyl(m, "Base", 0.25, 1.25, it.A, CF(0, -0.82, 0) * UP)
	for _, o in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do block(m, "Bar", Vector3.new(0.12, 1.5, 0.12), it.A, CF(o[1] * 0.42, 0, o[2] * 0.42)) end
	ball(m, "Ghost", 0.78, it.B, CF(0, -0.02, 0), NEON, 0.1)
	ball(m, "EyeL", 0.14, DARK, CF(-0.13, 0.05, 0.35))
	ball(m, "EyeR", 0.14, DARK, CF(0.13, 0.05, 0.35))
	ball(m, "Hook", 0.28, it.A, CF(0, 1.1, 0))
end
function B.mask(m, it)
	ell(m, "Face", Vector3.new(1.6, 1.95, 0.6), it.A, CF())
	ell(m, "EyeL", Vector3.new(0.4, 0.28, 0.2), DARK, CF(-0.36, 0.25, 0.27))
	ell(m, "EyeR", Vector3.new(0.4, 0.28, 0.2), DARK, CF(0.36, 0.25, 0.27))
	ell(m, "Mouth", Vector3.new(0.6, 0.18, 0.2), DARK, CF(0, -0.48, 0.25))
	ell(m, "Brow", Vector3.new(1.3, 0.22, 0.25), it.B, CF(0, 0.58, 0.2))
	ball(m, "GemL", 0.22, it.B, CF(-0.5, -0.18, 0.24), NEON)
	ball(m, "GemR", 0.22, it.B, CF(0.5, -0.18, 0.24), NEON)
	if it.Horns then
		ell(m, "HornL", Vector3.new(0.3, 0.95, 0.3), it.B, CF(-0.58, 1.02, 0) * ANG(0, 0, R(24)))
		ell(m, "HornR", Vector3.new(0.3, 0.95, 0.3), it.B, CF(0.58, 1.02, 0) * ANG(0, 0, R(-24)))
	else
		cyl(m, "EarL", 0.22, 0.55, it.B, CF(-0.85, 0, 0) * FACE)
		cyl(m, "EarR", 0.22, 0.55, it.B, CF(0.85, 0, 0) * FACE)
	end
end
function B.orb(m, it)
	if it.Stand then
		cyl(m, "Stand", 0.45, 1.0, it.B, CF(0, -0.92, 0) * UP)
		ball(m, "Claw", 0.32, it.B, CF(0, -0.62, 0))
	end
	ball(m, "Orb", 1.5, it.A, CF(0, 0.08, 0), SMOOTH, 0.22)
	ball(m, "Swirl", 0.8, it.B, CF(0, 0.08, 0), NEON, 0.25)
	if it.Ring then beads(m, "Ring", 1.05, 16, 0.2, it.B, ANG(R(72), 0, R(12)), NEON) end
end
function B.crown(m, it)
	beads(m, "Band", 0.78, 14, 0.36, it.A, CF(0, -0.35, 0) * ANG(R(90), 0, 0), SMOOTH)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		ell(m, "Spike" .. i, Vector3.new(0.3, 0.95, 0.3), it.A, CF(math.cos(a) * 0.74, 0.15, math.sin(a) * 0.74), SMOOTH, 0.12)
		ball(m, "Tip" .. i, 0.28, it.B, CF(math.cos(a) * 0.74, 0.68, math.sin(a) * 0.74), NEON)
	end
	ball(m, "Jewel", 0.42, it.B, CF(0, -0.35, 0.8), NEON)
end
function B.gem(m, it)
	local s = it.Small and 0.78 or (it.Big and 1.18 or 0.98)
	block(m, "Gem", Vector3.new(1.25, 1.25, 1.25) * s, it.A, ANG(R(45), 0, R(45)) * ANG(0, R(45), 0), SMOOTH, 0.12)
	ball(m, "Core", 0.7 * s, it.B, CF(), NEON, 0.2)
	ball(m, "Glint", 0.18 * s + 0.05, WHITE, CF(-0.25 * s, 0.35 * s, 0.45 * s), NEON)
end
function B.cluster(m, it)
	ell(m, "Rock", Vector3.new(1.7, 0.6, 1.3), it.B, CF(0, -0.78, 0))
	local spec = {{0, 0, 0, 0.5, 1.7, 0}, {-0.48, -0.15, 0.1, 0.38, 1.15, 26}, {0.5, -0.2, -0.05, 0.38, 1.25, -24}, {0.12, -0.3, 0.42, 0.32, 0.9, 12}, {-0.15, -0.3, -0.4, 0.3, 0.85, -10}}
	for i, c in ipairs(spec) do
		block(m, "Crystal" .. i, Vector3.new(c[4], c[5], c[4]), it.A, CF(c[1], c[2] - 0.5 + c[5] / 2, c[3]) * ANG(0, R(45), R(c[6])), SMOOTH, 0.08)
	end
	ball(m, "Glow", 0.6, it.A, CF(0, -0.2, 0), NEON, 0.3)
end
function B.opal(m, it)
	ell(m, "Opal", Vector3.new(1.3, 1.75, 0.9), it.A, CF(), SMOOTH, 0.08)
	ell(m, "Fire", Vector3.new(0.85, 1.2, 0.6), it.B, CF(0, 0, 0.14), NEON, 0.35)
	beads(m, "Setting", 1.0, 14, 0.2, Color3.fromRGB(255, 215, 90), CF(), SMOOTH)
	ball(m, "Spark", 0.2, WHITE, CF(-0.25, 0.45, 0.42), NEON)
end
function B.coin(m, it)
	cyl(m, "Coin", 0.36, 1.85, it.A, FACE)
	cyl(m, "Inner", 0.42, 1.3, it.B, FACE)
	if it.Pixels then
		for _, o in ipairs({{0, 0}, {0, 1}, {0, -1}, {1, 0}, {-1, 0}}) do
			block(m, "Pixel", Vector3.new(0.24, 0.24, 0.5), shade(it.A, 0.25), CF(o[1] * 0.26, o[2] * 0.26, 0))
		end
	else
		ball(m, "Star", 0.5, it.A, CF(), NEON)
	end
end
function B.cartridge(m, it)
	block(m, "Shell", Vector3.new(1.55, 1.75, 0.36), it.A)
	block(m, "Label", Vector3.new(1.15, 0.95, 0.4), it.B, CF(0, 0.22, 0))
	block(m, "Grip", Vector3.new(1.55, 0.28, 0.42), shade(it.A, 0.25), CF(0, -0.7, 0))
	for i = -2, 2 do block(m, "Pin", Vector3.new(0.14, 0.2, 0.3), Color3.fromRGB(255, 210, 80), CF(i * 0.26, -0.92, 0)) end
	ball(m, "Star", 0.3, WHITE, CF(0, 0.25, 0.2), NEON)
end
function B.joystick(m, it)
	block(m, "Base", Vector3.new(1.65, 0.5, 1.25), it.A, CF(0, -0.78, 0))
	cyl(m, "Stick", 1.05, 0.26, Color3.fromRGB(70, 70, 85), CF(0, -0.08, 0) * UP)
	ball(m, "Knob", 0.78, it.B, CF(0, 0.6, 0))
	cyl(m, "Button1", 0.16, 0.32, it.B, CF(0.5, -0.47, 0.25) * UP)
	cyl(m, "Button2", 0.16, 0.32, Color3.fromRGB(80, 200, 255), CF(0.5, -0.47, -0.2) * UP)
end
function B.cube(m, it)
	local rot = ANG(R(18), R(35), 0)
	block(m, "Cube", Vector3.new(1.3, 1.3, 1.3), it.A, rot)
	local h = 0.65
	for axis = 1, 3 do
		for _, s1 in ipairs({-1, 1}) do
			for _, s2 in ipairs({-1, 1}) do
				local size, off
				if axis == 1 then size, off = Vector3.new(1.4, 0.1, 0.1), Vector3.new(0, s1 * h, s2 * h)
				elseif axis == 2 then size, off = Vector3.new(0.1, 1.4, 0.1), Vector3.new(s1 * h, 0, s2 * h)
				else size, off = Vector3.new(0.1, 0.1, 1.4), Vector3.new(s1 * h, s2 * h, 0) end
				block(m, "Edge", size, it.B, rot * CF(off), NEON)
			end
		end
	end
	for i = 1, 4 do block(m, "Glitch" .. i, Vector3.new(0.22, 0.22, 0.22), (i % 2 == 0) and it.B or Color3.fromRGB(255, 80, 200), CF(math.cos(i * 1.7) * 1.05, math.sin(i * 2.3) * 0.8, 0.5), NEON) end
end
function B.idol(m, it)
	ell(m, "Body", Vector3.new(1.15, 1.2, 0.95), it.A, CF(0, -0.45, 0))
	ball(m, "Head", 0.98, it.A, CF(0, 0.45, 0))
	ball(m, "EyeL", 0.17, DARK, CF(-0.2, 0.5, 0.43))
	ball(m, "EyeR", 0.17, DARK, CF(0.2, 0.5, 0.43))
	ell(m, "Belly", Vector3.new(0.62, 0.58, 0.3), it.B, CF(0, -0.45, 0.36))
	ell(m, "ArmL", Vector3.new(0.35, 0.6, 0.35), it.A, CF(-0.6, -0.35, 0) * ANG(0, 0, R(-20)))
	ell(m, "ArmR", Vector3.new(0.35, 0.6, 0.35), it.A, CF(0.6, -0.35, 0) * ANG(0, 0, R(20)))
	cyl(m, "Headband", 0.18, 1.0, it.B, CF(0, 0.75, 0) * UP)
end
function B.totem(m, it)
	for i = 0, 2 do
		local y = -0.72 + i * 0.66
		cyl(m, "Seg" .. i, 0.64, 1.05, (i % 2 == 0) and it.A or shade(it.A, 0.18), CF(0, y, 0) * UP)
		ball(m, "EyeL" .. i, 0.18, DARK, CF(-0.2, y + 0.08, 0.48))
		ball(m, "EyeR" .. i, 0.18, DARK, CF(0.2, y + 0.08, 0.48))
		block(m, "Mouth" .. i, Vector3.new(0.4, 0.1, 0.1), it.B, CF(0, y - 0.15, 0.5))
	end
	ell(m, "WingL", Vector3.new(0.75, 0.3, 0.4), it.B, CF(-0.7, 0.75, 0) * ANG(0, 0, R(15)))
	ell(m, "WingR", Vector3.new(0.75, 0.3, 0.4), it.B, CF(0.7, 0.75, 0) * ANG(0, 0, R(-15)))
	ball(m, "Gem", 0.3, it.B, CF(0, 1.05, 0), NEON)
end
function B.medallion(m, it)
	cyl(m, "Disc", 0.36, 1.5, it.A, FACE)
	cyl(m, "Center", 0.42, 0.85, it.B, FACE)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		ell(m, "Ray" .. i, Vector3.new(0.32, 0.5, 0.26), it.A, CF(math.cos(a) * 0.98, math.sin(a) * 0.98, 0) * ANG(0, 0, a - math.pi / 2))
	end
	ball(m, "Gem", 0.36, WHITE, CF(0, 0, 0.12), NEON)
end
function B.shard(m, it)
	block(m, "Shard", Vector3.new(0.7, 1.7, 0.7), it.A, ANG(R(15), R(45), R(25)), SMOOTH, 0.1)
	ball(m, "Glow", 0.5, it.B, CF(), NEON, 0.2)
	for i = 1, 4 do ball(m, "Trail" .. i, 0.38 - i * 0.06, it.A, CF(-0.45 - i * 0.28, -0.35 - i * 0.22, 0), NEON, 0.15 + i * 0.15) end
end
function B.star(m, it)
	ball(m, "Center", 0.85, it.A)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 + math.pi / 2
		ell(m, "Point" .. i, Vector3.new(0.48, 1.1, 0.42), it.A, CF(math.cos(a) * 0.62, math.sin(a) * 0.62, 0) * ANG(0, 0, a - math.pi / 2))
	end
	ball(m, "Core", 0.45, it.B, CF(0, 0, 0.3), NEON)
end
function B.planet(m, it)
	ball(m, "Planet", 1.45, it.A)
	ell(m, "Stripe", Vector3.new(1.5, 0.32, 1.5), it.B, CF(0, 0.22, 0))
	beads(m, "Ring", 1.12, 18, 0.18, it.B, ANG(R(75), 0, R(15)), NEON)
	ball(m, "Moon", 0.36, Color3.fromRGB(240, 245, 255), CF(1.05, 0.85, 0))
end
function B.core(m, it)
	ball(m, "Heart", 1.0, it.A, CF(), NEON, 0.05)
	ball(m, "Shell", 1.45, it.B, CF(), SMOOTH, 0.62)
	beads(m, "RingA", 1.05, 14, 0.17, it.A, ANG(R(90), 0, 0), NEON)
	beads(m, "RingB", 1.05, 14, 0.17, it.B, ANG(0, R(90), R(35)), NEON)
end

local function newModel(name)
	local m = Instance.new("Model")
	m.Name = name
	local root = block(m, "Root", Vector3.new(0.2, 0.2, 0.2), WHITE, CF())
	root.Transparency = 1
	m.PrimaryPart = root
	return m
end
function M.Build(item)
	local m = newModel(item.Id)
	;(B[item.Shape] or B.gem)(m, item)
	return m
end
function M.Chest()
	local m = newModel("TreasureChest")
	local wood, gold = Color3.fromRGB(175, 108, 58), Color3.fromRGB(255, 205, 70)
	block(m, "Box", Vector3.new(2.0, 1.1, 1.3), wood, CF(0, -0.35, 0))
	cyl(m, "Lid", 2.0, 1.3, shade(wood, 0.08), CF(0, 0.2, 0))
	block(m, "BandL", Vector3.new(0.22, 1.8, 1.42), gold, CF(-0.62, -0.03, 0))
	block(m, "BandR", Vector3.new(0.22, 1.8, 1.42), gold, CF(0.62, -0.03, 0))
	block(m, "Lock", Vector3.new(0.4, 0.48, 0.22), gold, CF(0, -0.08, 0.68))
	ball(m, "Gem", 0.3, Color3.fromRGB(90, 200, 255), CF(0, 0.5, 0.55), NEON)
	return m
end
M.Shapes = B
return M
