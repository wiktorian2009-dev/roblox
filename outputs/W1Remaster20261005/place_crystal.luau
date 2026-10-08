-- place_crystal.luau (Studio, Edit): Icy crystal quarry. Archives old Crystal scenery (with placement info) and places the W1_Crystal pack.
local K = require(game.ServerStorage.W1RemasterKit:Clone())
local AREA = "Crystal"
local Y = 3.7
local CENTER = Vector3.new(245, Y, 170)
local function inZ(p) return p.X >= 169 and p.X < 420 and p.Z >= 69 and p.Z < 440 end
local log = {}

-- floor: the near-black slate becomes a mid blue-grey so the pale ice and crystals read
local floors = workspace.GeneratedMap.Stages:FindFirstChild("crystal biome")
if floors then for _, p in ipairs(floors:GetDescendants()) do if p:IsA("BasePart") then p:SetAttribute("OrigColor", p.Color); p.Color = Color3.fromRGB(96, 110, 138) end end end

-- 1) boundary walls -> fractured slate cliffs with embedded crystals (every third tile carries a mine tunnel)
local walls = {}
for _, c in ipairs(workspace:GetChildren()) do
	if c:IsA("Model") and c.Name:match("^CrystalWall_") and inZ(c:GetBoundingBox().Position) then table.insert(walls, c) end
end
for _, c in ipairs(workspace.CrystalWallTemplates:GetChildren()) do if c:IsA("Model") then table.insert(walls, c) end end
for i, w in ipairs(walls) do
	K.replaceWall(w, AREA, CENTER, {names = (i % 3 == 0) and {"X_WallSeg", "X_WallSegB"} or {"X_WallSeg"}, design = 28, depth = 14, maxTile = 28, scaleJitter = true, colliderHeight = 30})
end
table.insert(log, "walls " .. #walls)

-- 2) archive old decor
local na = 0
for _, c in ipairs(workspace:GetChildren()) do
	if ({CrystalArch = 1, Crystal = 1, CrystalCluster = 1, CrystalSpire = 1, GemBoulder = 1})[c.Name] then
		local p = c:IsA("Model") and c:GetBoundingBox().Position or c.Position
		if inZ(p) then K.archive(c, AREA, "crystal decor replaced by the remaster"); na += 1 end
	end
end
local bd = workspace:FindFirstChild("BiomeDecor_Crystal")
if bd then for _, c in ipairs(bd:GetChildren()) do K.archive(c, AREA, "BiomeDecor_Crystal"); na += 1 end end
table.insert(log, "decor " .. na)

-- helpers: free-spot search (no collidable parts, 2 studs clear of fields)
local fields = {}
for _, z in ipairs(workspace.SnowFieldZones:GetChildren()) do if z:IsA("BasePart") then table.insert(fields, z) end end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {workspace.SnowFieldZones}
local function free(cx, cz, sx, sz)
	for _, p in ipairs(workspace:GetPartBoundsInBox(CFrame.new(cx, Y + 4, cz), Vector3.new(sx, 6, sz), op)) do
		if p.CanCollide and p.Position.Y > Y + 0.5 then return false end
	end
	for _, f in ipairs(fields) do
		local rel = f.CFrame:PointToObjectSpace(Vector3.new(cx, f.Position.Y, cz))
		if math.abs(rel.X) < f.Size.X / 2 + sx / 2 + 2 and math.abs(rel.Z) < f.Size.Z / 2 + sz / 2 + 2 then return false end
	end
	return true
end
local function spot(cx, cz, sx, sz)
	if free(cx, cz, sx, sz) then return cx, cz end
	for r = 3, 18, 3 do for a = 0, 330, 30 do
		local x, z = cx + math.cos(math.rad(a)) * r, cz + math.sin(math.rad(a)) * r
		if free(x, z, sx, sz) then return x, z end
	end end
	return nil
end
local function at(x, z, fx, fz) local p = Vector3.new(x, Y, z); return CFrame.lookAt(p, Vector3.new(fx, Y, fz)) end

-- 3) composition: the Crystal Heart dominates the entry plaza from the Cursed gate; mining kit around it
local heart = K.place("X_Heart", at(236, 125, 280, 170), AREA)
K.addColliders(heart, AREA, {{Vector3.new(0, 4, 0), Vector3.new(24, 8, 20)}, {Vector3.new(0, 20, 0), Vector3.new(12, 30, 12)}, {Vector3.new(15, 15, -6), Vector3.new(3, 30, 3)}})
local sparks = Instance.new("Attachment"); sparks.Position = Vector3.new(0, 20, 0); sparks.Parent = heart.PrimaryPart
local e = Instance.new("ParticleEmitter"); e.Name = "Sparkle"; e.Rate = 6; e.Lifetime = NumberRange.new(1.5, 2.5); e.Speed = NumberRange.new(0.5, 1.5)
e.SpreadAngle = Vector2.new(180, 180); e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
e.Color = ColorSequence.new(Color3.fromRGB(200, 250, 255), Color3.fromRGB(230, 160, 255)); e.LightEmission = 1
e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume; sparks.Parent = heart.PrimaryPart; e.Parent = sparks
local core = heart:FindFirstChild("HeartCore")
if core then local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(150, 235, 255); l.Range = 30; l.Brightness = 1.2; l.Parent = core end
local placedList = {}
local function put(name, x, z, sx, sz, fx, fz, cols, scale, sub)
	local px, pz = spot(x, z, sx, sz)
	if not px then table.insert(log, name .. " skipped"); return nil end
	local m = K.place(name, at(px, pz, fx or CENTER.X, fz or CENTER.Z), AREA, scale, sub)
	if cols then K.addColliders(m, AREA, cols) end
	table.insert(placedList, name)
	return m
end
local hf = put("X_Headframe", 192, 100, 10, 8, 245, 140, {{Vector3.new(0, 9, 0), Vector3.new(8, 18, 6)}})
if hf then local w = hf:FindFirstChild("Wheel"); if w then w:SetAttribute("StageDecorMotion", "Spin"); w:SetAttribute("MotionAxis", "Z"); w:SetAttribute("MotionSpeed", 0.6) end end
put("X_Cart", 240, 92, 9, 5, 300, 92, {{Vector3.new(0, 1.6, 0), Vector3.new(4, 3.2, 3)}})
put("X_Crates", 212, 86, 8, 6, 245, 140, {{Vector3.new(0, 1.5, 0), Vector3.new(6, 3, 4)}})
put("X_BigCrystal", 182, 80, 11, 9, 245, 140, {{Vector3.new(0, 4, 0), Vector3.new(6, 8, 5)}})
put("X_Cluster", 300, 210, 6, 6, 280, 150, {{Vector3.new(0, 2, 0), Vector3.new(4, 4, 4)}})
put("X_Cluster", 262, 160, 6, 6, 240, 120, {{Vector3.new(0, 2, 0), Vector3.new(4, 4, 4)}}, 0.8)
for _, l in ipairs({{252, 98}, {204, 150}, {255, 158}, {300, 80}}) do
	local m = put("X_Lamp", l[1], l[2], 2.5, 2.5, CENTER.X, CENTER.Z, {{Vector3.new(0, 3, 0), Vector3.new(1, 6, 1)}}, 1.2, "Lamps")
	if m then local g = m:FindFirstChild("Lamp"); if g then local pl = Instance.new("PointLight"); pl.Color = Color3.fromRGB(255, 214, 140); pl.Range = 14; pl.Brightness = 1; pl.Parent = g end end
end
-- supported walkway along the inner east edge of the extension (on the floor, beside the boundary)
put("X_Trestle", 262, 285, 6, 25, 200, 285, {{Vector3.new(0, 4, 0), Vector3.new(24, 8, 4)}})
-- background quarry cliffs with glowing cave mouths
for _, c in ipairs({{235, 352, 0, 1.3}, {345, 270, -50, 1.2}, {360, 70, -110, 1.15}, {300, 340, -20, 1.0}}) do
	K.place("X_Cave", at(c[1], c[2], CENTER.X, CENTER.Z) * CFrame.new(0, -Y, 0), AREA, c[4], "Background")
end
table.insert(log, "props " .. #placedList .. "; instances " .. #K.scenery(AREA):GetDescendants())
return table.concat(log, "; ")
