-- place_cursed.luau (Studio, Edit): Haunted winter settlement. Archives old Cursed scenery (with placement info) and places the W1_Cursed pack.
local K = require(game.ServerStorage.W1RemasterKit:Clone())
local AREA = "Cursed"
local Y = 3.1
local CENTER = Vector3.new(268, Y, -40)
local function inZ(p) return p.X >= 150 and p.X < 420 and p.Z >= -155 and p.Z < 69 end
local log = {}
local function at(x, z, fx, fz) local p = Vector3.new(x, Y, z); return CFrame.lookAt(p, Vector3.new(fx, Y, fz)) end

-- 1) the chapel landmark takes the footprint of the north-east wall (305, 41): it IS part of the boundary there
local chapelWall
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "CursedWall_A" and c:IsA("Model") then local p = c:GetBoundingBox().Position; if math.abs(p.X - 305) < 3 and math.abs(p.Z - 41) < 3 then chapelWall = c end end
end
if chapelWall then
	local f = K.footprint(chapelWall)
	local chapel = K.place("C_Chapel", CFrame.lookAt(Vector3.new(f.center.X, Y, f.center.Z), Vector3.new(CENTER.X, Y, f.center.Z)), AREA)
	K.collider(AREA, CFrame.lookAt(Vector3.new(f.center.X, f.bottom + 15, f.center.Z), Vector3.new(CENTER.X, f.bottom + 15, f.center.Z)), Vector3.new(f.len, 30, f.thick), "WallCollider")
	K.archive(chapelWall, AREA, "boundary wall replaced by the C_Chapel landmark + WallCollider")
end

-- 2) the other boundary walls -> broken gothic wall segments + one invisible collider each
local walls = {}
for _, c in ipairs(workspace:GetChildren()) do
	if c:IsA("Model") and (c.Name:match("^CursedWall_") or c.Name == "SandWall_A" or c.Name == "CrystalWall_C") and inZ(c:GetBoundingBox().Position) then table.insert(walls, c) end
end
local tpl = workspace:FindFirstChild("CursedWallTemplates")
if tpl then for _, c in ipairs(tpl:GetChildren()) do if c:IsA("Model") and inZ(c:GetBoundingBox().Position) then table.insert(walls, c) end end end
for _, w in ipairs(walls) do
	K.replaceWall(w, AREA, CENTER, {names = {"C_WallSeg", "C_WallSegB", "C_WallSeg"}, design = 28, depth = 14, maxTile = 28, scaleJitter = true, colliderHeight = 30})
end
table.insert(log, "walls " .. #walls)

-- 3) iron fences: new wrought-iron runs in the same footprints
local nf = 0
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "IronFence" and inZ(c:IsA("Model") and c:GetBoundingBox().Position or c.Position) then
		local f = K.footprint(c)
		local n = Vector3.new(-f.long.Z, 0, f.long.X)
		if n:Dot(CENTER - f.center) < 0 then n = -n end
		local pos = Vector3.new(f.center.X, Y, f.center.Z)
		local m = K.place("C_Fence", CFrame.lookAt(pos, pos + n), AREA, f.len / 14, "Fences")
		K.collider(AREA, CFrame.lookAt(pos + Vector3.new(0, 2, 0), pos + Vector3.new(0, 2, 0) + n), Vector3.new(f.len, 4, 1.2), "FenceCollider")
		K.archive(c, AREA, "iron fence replaced by C_Fence + FenceCollider"); nf += 1
	end
end
table.insert(log, "fences " .. nf)

-- 4) archive the old decor in the Cursed zone
local na = 0
local function maybe(c, note)
	local p = c:IsA("Model") and c:GetBoundingBox().Position or (c:IsA("BasePart") and c.Position)
	if p and inZ(p) then K.archive(c, AREA, note); na += 1 end
end
for _, c in ipairs(workspace:GetChildren()) do
	if ({DeadTree = 1, DarkShard = 1, DarkShardTip = 1, Candles = 1})[c.Name] then maybe(c, "loose cursed decor") end
end
for _, fname in ipairs({"CursedStageDecor", "BiomeDecor_Cursed"}) do
	local f = workspace:FindFirstChild(fname)
	if f then for _, c in ipairs(f:GetChildren()) do if c:IsA("Model") or c:IsA("BasePart") then maybe(c, fname) end end end
end
local cbd = workspace:FindFirstChild("CursedBiomeDecor")
if cbd then for _, d in ipairs(cbd:GetDescendants()) do if (d:IsA("BasePart") or d:IsA("Model")) and d.Parent:IsA("Folder") then maybe(d, "CursedBiomeDecor") end end end
table.insert(log, "decor archived " .. na)

-- 5) composition: graveyard + pumpkin patch + a crooked lane of cottages between the fields, arch in the north pocket
local graves = K.place("C_Graves", at(270, -108, 200, -108), AREA)
K.addColliders(graves, AREA, {{Vector3.new(-9, 2.5, 0), Vector3.new(6, 5, 7)}, {Vector3.new(0, 1.5, 0), Vector3.new(16, 3, 8)}})
local pumpk = K.place("C_Pumpkins", at(270, -45, 200, -45), AREA)
K.addColliders(pumpk, AREA, {{Vector3.new(0, 1, 0), Vector3.new(11, 2, 7)}, {Vector3.new(-5.5, 3.5, 2.5), Vector3.new(2, 7, 2)}})
for _, c in ipairs({{270, 5, 270, -40, 1.0}, {268, 33, 250, -10, 0.9}}) do
	local m = K.place("C_Cottage", at(c[1], c[2], c[3], c[4]), AREA, c[5])
	K.addColliders(m, AREA, {{Vector3.new(0, 6, 0), Vector3.new(13, 12, 11)}})
	local ch = m:FindFirstChild("Chimney")
	if ch then
		local a = Instance.new("Attachment"); a.Position = Vector3.new(0, ch.Size.Y / 2, 0); a.Parent = ch
		local e = Instance.new("ParticleEmitter"); e.Name = "Smoke"; e.Rate = 2; e.Lifetime = NumberRange.new(3, 4); e.Speed = NumberRange.new(1.5, 2.5)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3.4)})
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
		e.Color = ColorSequence.new(Color3.fromRGB(190, 175, 215)); e.Acceleration = Vector3.new(0.5, 0.3, 0); e.Parent = a
	end
end
local arch = K.place("C_Arch", at(262, 58, 262, 0), AREA)
K.addColliders(arch, AREA, {{Vector3.new(8, 9, 0), Vector3.new(4.4, 18, 4.4)}, {Vector3.new(-8, 6, 0), Vector3.new(4.4, 12, 4.4)}})
for _, t in ipairs({{262, -80, 30}, {281, -18, 200}, {284, 20, 120}, {256, -132, 300}}) do
	local m = K.place("C_DeadTree", CFrame.new(t[1], Y, t[2]) * CFrame.Angles(0, math.rad(t[3]), 0), AREA, 1.25)
	K.addColliders(m, AREA, {{Vector3.new(0, 4, 0), Vector3.new(2.6, 8, 2.6)}})
end
for i, l in ipairs({{256, -92}, {285, -70}, {256, -30}, {285, -5}, {256, 22}}) do -- (two lamps in the narrow east strip were removed after the corridor check)
	local m = K.place("C_Lamp", CFrame.new(l[1], Y, l[2]) * CFrame.Angles(0, math.rad(i * 80), 0), AREA, 1.0, "Lamps")
	K.addColliders(m, AREA, {{Vector3.new(0, 3.5, 0), Vector3.new(1.4, 7, 1.4)}})
	local g = m:FindFirstChild("Lamp")
	if g then local pl = Instance.new("PointLight"); pl.Color = Color3.fromRGB(130, 255, 170); pl.Range = 14; pl.Brightness = 1; pl.Parent = g end
end
for i, g in ipairs({{272, -112, 10}, {298, 26, 13}, {262, 46, 11}}) do
	local m = K.place("C_Ghost", CFrame.new(g[1], Y + g[3], g[2]) * CFrame.Angles(0, math.rad(i * 110), 0), AREA, 1.4, "Life")
	m:SetAttribute("StageDecorMotion", "Bob"); m:SetAttribute("MotionAmount", 1.2); m:SetAttribute("MotionSpeed", 0.9); m:SetAttribute("MotionPhase", i * 1.7)
end
-- background crags + spires outside the boundary (east side, and the inner side of the map)
for _, c in ipairs({{398, -15, 1.1, 20}, {405, -125, 1.25, -40}, {385, 65, 1.0, 70}, {145, -70, 1.15, 160}, {150, 15, 0.95, 110}}) do
	K.place("C_Crag", CFrame.new(c[1], 0, c[2]) * CFrame.Angles(0, math.rad(c[4]), 0), AREA, c[3], "Background")
end
table.insert(log, "instances " .. #K.scenery(AREA):GetDescendants())
return table.concat(log, "; ")
