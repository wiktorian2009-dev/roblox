-- place_desert.luau (Studio, Edit): Frozen Desert Outpost. Archives old Desert scenery (with placement info) and places the W1_Desert pack.
local K = require(game.ServerStorage.W1RemasterKit:Clone())
local AREA = "Desert"
local Y = 3.5 -- Desert floor top
local CENTER = Vector3.new(190, Y, -262)
local function inDesert(p) return p.X >= 84 and p.X < 420 and p.Z >= -420 and p.Z < -155 end
local log = {}

-- 1) boundary walls -> layered sandstone cliff segments + one invisible collider each (footprints and openings unchanged)
local walls = {}
for _, c in ipairs(workspace:GetChildren()) do
	if (c.Name == "SandWall_A" or c.Name == "CursedWall_B") and c:IsA("Model") and inDesert(c:GetBoundingBox().Position) then table.insert(walls, c) end
end
local tpl = workspace:FindFirstChild("SandWallTemplates")
if tpl then for _, c in ipairs(tpl:GetChildren()) do if c:IsA("Model") and inDesert(c:GetBoundingBox().Position) then table.insert(walls, c) end end end
for _, w in ipairs(walls) do
	K.replaceWall(w, AREA, CENTER, {names = {"D_CliffSeg", "D_CliffSegB"}, design = 28, depth = 16, maxTile = 28, scaleJitter = true, colliderHeight = 30})
end
table.insert(log, "walls replaced " .. #walls)

-- 2) archive old interior decor (palms, rock stacks, pyramid, vase, stray cursed decor that sat in the Desert)
local n = 0
for _, c in ipairs(workspace:GetChildren()) do
	if ({PalmTree = 1, RockStack = 1, ["Ancient Egyptian Pyramid"] = 1, ClayVase = 1})[c.Name] then
		local p = c:IsA("Model") and c:GetBoundingBox().Position or c.Position
		if inDesert(p) then K.archive(c, AREA, "desert decor replaced by the remaster"); n += 1 end
	end
end
local cbd = workspace:FindFirstChild("CursedBiomeDecor")
if cbd then
	for _, d in ipairs(cbd:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Model")) and d.Parent:IsA("Folder") then
			local p = d:IsA("Model") and d:GetBoundingBox().Position or d.Position
			if inDesert(p) then K.archive(d, AREA, "cursed decor that sat inside the Desert"); n += 1 end
		end
	end
end
table.insert(log, "decor archived " .. n)

-- 3) new composition (front = LookVector)
local function at(x, z, faceX, faceZ) local p = Vector3.new(x, Y, z); return CFrame.lookAt(p, Vector3.new(faceX, Y, faceZ)) end
-- landmark: ruined Sun Gate at the north-west corner (old giant rock stack), seen from the Starter gate and the fields
local sun = K.place("D_SunGate", at(168, -180, 200, -262), AREA)
K.addColliders(sun, AREA, {
	{Vector3.new(17, 17, 0), Vector3.new(11, 34, 11)}, {Vector3.new(-17, 15, 0), Vector3.new(11, 30, 11)},
	{Vector3.new(24.75, 13, -2), Vector3.new(8.5, 26, 12)}, {Vector3.new(-12.5, 6, -7.5), Vector3.new(16, 12, 9)},
})
-- half-buried ziggurat where the old pyramid stood, stairs toward the fields
local zig = K.place("D_Ziggurat", at(246, -298, 180, -298), AREA)
K.addColliders(zig, AREA, {{Vector3.new(-1, 3.5, 2), Vector3.new(42, 7, 42)}, {Vector3.new(0, 9, 0), Vector3.new(26, 6, 26)}, {Vector3.new(0, 14.75, 0), Vector3.new(18, 5.5, 18)}})
-- explorers' camp + frozen oasis + ruins along the west strip (the entry lane z -280..-235 stays open)
local camp = K.place("D_Camp", at(118, -323, 160, -280), AREA)
K.addColliders(camp, AREA, {{Vector3.new(8, 2.5, 3), Vector3.new(7, 5, 7)}, {Vector3.new(-2, 2.5, 6), Vector3.new(8, 5, 8)}, {Vector3.new(10.5, 1.5, -4.5), Vector3.new(5, 3, 5)}, {Vector3.new(-12.5, 1.1, -1.7), Vector3.new(5, 2.2, 3)}})
K.place("D_Oasis", at(120, -214, 120, -260), AREA)
local ruins = K.place("D_Ruins", at(106, -301, 106, -250), AREA) -- (moved south after the corridor check: the entry lane z -285..-235 stays clear)
K.addColliders(ruins, AREA, {{Vector3.new(8, 5.5, -4), Vector3.new(3.4, 11, 3.4)}, {Vector3.new(3.5, 3.5, -5), Vector3.new(3.4, 7, 3.4)}, {Vector3.new(-1.5, 6.75, -4.5), Vector3.new(3.4, 13.5, 3.4)},
	{Vector3.new(-7, 3, 2), Vector3.new(9, 6, 10)}, {Vector3.new(7.5, 1.6, 4.5), Vector3.new(8, 3.2, 3.4)}})
for _, p in ipairs({{100, -206}, {100, -352}}) do
	local o = K.place("D_Obelisk", at(p[1], p[2], 160, -280), AREA)
	K.addColliders(o, AREA, {{Vector3.new(0, 8, 0), Vector3.new(6, 16, 6)}})
end
local palms = {{104, -203, 0.95, 20}, {137, -224, 1.1, 140}, {101, -228, 0.8, 250}, {133, -336, 1.0, 80}}
for _, p in ipairs(palms) do
	local pos = Vector3.new(p[1], Y, p[2])
	local m = K.place("D_FrozenPalm", CFrame.new(pos) * CFrame.Angles(0, math.rad(p[4]), 0), AREA, p[3])
	K.addColliders(m, AREA, {{Vector3.new(0, 5, 0), Vector3.new(2.4, 10, 2.4)}})
	m:SetAttribute("StageDecorMotion", "Sway"); m:SetAttribute("MotionAmount", 0.012); m:SetAttribute("MotionSpeed", 0.7); m:SetAttribute("MotionPhase", p[4] / 50)
end
-- background: broad mesas and wind dunes outside the boundary (no collision needed: unreachable)
for i, p in ipairs({{170, -440, 1.2, 10}, {300, -425, 1.0, -25}, {405, -320, 1.15, 60}, {400, -190, 0.95, 95}, {60, -445, 0.9, 30}}) do
	K.place("D_Mesa", CFrame.new(Vector3.new(p[1], 0, p[2])) * CFrame.Angles(0, math.rad(p[4]), 0), AREA, p[3], "Background")
end
for i, p in ipairs({{150, -372, 0}, {232, -366, 8}, {305, -335, 40}, {330, -150, -20}}) do
	K.place("D_Dune", CFrame.new(Vector3.new(p[1], Y - 1, p[2])) * CFrame.Angles(0, math.rad(p[3]), 0), AREA, 1.1, "Background")
end
-- life: a hawk circling over the dig site, campfire smoke
local hawk = K.place("D_Hawk", CFrame.new(200, 58, -250), AREA, 1.4)
hawk:SetAttribute("StageDecorMotion", "Orbit"); hawk:SetAttribute("MotionRadius", 46); hawk:SetAttribute("MotionSpeed", 0.32); hawk:SetAttribute("MotionAmount", 4)
local fire = camp:FindFirstChild("FireGlow")
if fire then
	local a = Instance.new("Attachment"); a.Position = Vector3.new(0, 1, 0); a.Parent = fire
	local e = Instance.new("ParticleEmitter"); e.Name = "Smoke"; e.Rate = 3; e.Lifetime = NumberRange.new(3, 4.5); e.Speed = NumberRange.new(2, 3.5)
	e.SpreadAngle = Vector2.new(12, 12); e.Acceleration = Vector3.new(0.6, 0.4, 0)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4.5)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})
	e.Color = ColorSequence.new(Color3.fromRGB(210, 210, 215)); e.LightEmission = 0; e.Parent = a
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 160, 80); l.Range = 14; l.Brightness = 1.2; l.Parent = fire
end
table.insert(log, "placed " .. #K.scenery(AREA):GetDescendants() .. " instances")
return table.concat(log, "; ")
