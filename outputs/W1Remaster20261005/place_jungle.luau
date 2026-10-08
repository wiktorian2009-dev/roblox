-- place_jungle.luau (Studio, Edit): Frozen jungle temple ruins. Archives old Jungle scenery (with placement info) and places the W1_Jungle pack.
-- Boundaries: J_WallSeg tiles along the old walls' inner face (openings unchanged), one simple box collider per tile.
-- The 36-stud hole in the south wall (x -105..-69, open ledge then a drop into the void) is closed with tiles + collider.
local K = require(game.ServerStorage.W1RemasterKit:Clone())
local AREA = "Jungle"
local Y = 5.1
local CENTER = Vector3.new(-80, Y, 258)
local XMIN, XMAX = -183, 22
local log = {}
local function at(x, z, fx, fz) local p = Vector3.new(x, Y, z); return CFrame.lookAt(p, Vector3.new(fx, Y, fz)) end
local function inZone(p) return p.X > -186 and p.X < 30 and p.Z > 140 and p.Z < 440 end

-- 1) walls
local walls = {}
for _, c in ipairs(workspace:GetChildren()) do
	if c:IsA("Model") and (c.Name == "JungleWall_B" or c.Name == "JungleWall_A" or c.Name == "ClassicNaturalWall") and inZone(c:GetBoundingBox().Position) then table.insert(walls, c) end
end
local tpl = workspace:FindFirstChild("JungleWallTemplates")
if tpl then for _, c in ipairs(tpl:GetChildren()) do if c:IsA("Model") then table.insert(walls, c) end end end
local spans = {S = {}, N = {}}
for _, w in ipairs(walls) do
	local side = w:GetBoundingBox().Position.Z < 258 and "S" or "N"
	for _, p in ipairs(w:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide and p.Position.Y + p.Size.Y / 2 > Y + 1.5 then
			local h = p.Size / 2; local xs, zs = {}, {}
			for _, dx in ipairs({-1, 1}) do for _, dz in ipairs({-1, 1}) do local q = p.CFrame:PointToWorldSpace(Vector3.new(dx * h.X, 0, dz * h.Z)); table.insert(xs, q.X); table.insert(zs, q.Z) end end
			table.insert(spans[side], {x0 = math.min(unpack(xs)), x1 = math.max(unpack(xs)), z0 = math.min(unpack(zs)), z1 = math.max(unpack(zs))})
		end
	end
end
for _, w in ipairs(walls) do K.archive(w, AREA, "jungle boundary wall replaced by J_WallSeg tiles + one WallCollider per tile") end
-- close the south hole (filled span at the neighbours' inner face)
table.insert(spans.S, {x0 = -106, x1 = -68, z0 = 188, z1 = 204})
-- tiles: merge each side's spans into runs (a gap > 3 studs = an opening, kept), split runs into ~14-stud slots.
-- Slot front = mean (1-stud samples) of the innermost old face, so the blocked field area matches the old walls
-- (measured: Jungle_1 9.0% vs 9.7% old, Jungle_2 19.2% vs 18.3% old). One simple 16-deep collider per tile.
local TILE, DEPTH = 14, 12
local nTile = 0
for side, list in pairs(spans) do
	local dirZ = side == "S" and 1 or -1
	table.sort(list, function(a, b) return a.x0 < b.x0 end)
	local runs, cur = {}, nil
	for _, s in ipairs(list) do
		if cur and s.x0 <= cur.x1 + 3 then cur.x1 = math.max(cur.x1, s.x1) else cur = {x0 = s.x0, x1 = s.x1}; table.insert(runs, cur) end
	end
	for _, r in ipairs(runs) do
		local r0, r1 = math.max(r.x0, XMIN), math.min(r.x1, XMAX)
		if r1 - r0 > 4 then
			local k = math.max(1, math.ceil((r1 - r0) / TILE)); local w = (r1 - r0) / k
			for i = 1, k do
				local xa, xb = r0 + (i - 1) * w, r0 + i * w
				local sum, cnt = 0, 0
				for x = xa + 0.5, xb - 0.5, 1 do
					local f
					for _, s in ipairs(list) do if s.x0 <= x and s.x1 >= x then local v = side == "S" and s.z1 or s.z0; if not f or (side == "S" and v > f) or (side == "N" and v < f) then f = v end end end
					if f then sum += f; cnt += 1 end
				end
				local inner = sum / math.max(cnt, 1)
				local sc = w / TILE
				local cz = inner - dirZ * (DEPTH * sc / 2 - 0.6)
				local pos = Vector3.new((xa + xb) / 2, Y - 0.5, cz)
				local m = K.place("J_WallSeg", CFrame.lookAt(pos, pos + Vector3.new(0, 0, dirZ)), AREA, sc * (1 + ((nTile * 37) % 7 - 3) * 0.02), "Walls")
				m:SetAttribute("Side", side); nTile += 1
				K.collider(AREA, CFrame.new(pos.X, Y + 15, inner - dirZ * 8), Vector3.new(w, 30, 16), "WallCollider")
			end
		end
	end
endtable.insert(log, "walls " .. #walls .. " tiles " .. nTile)

-- 2) archive old decor
local na = 0
local function maybe(c, note)
	local p = (c:IsA("Model") and c:GetBoundingBox().Position) or (c:IsA("BasePart") and c.Position)
	if p and inZone(p) then K.archive(c, AREA, note); na += 1 end
end
for _, c in ipairs(workspace:GetChildren()) do
	if ({Bamboo = 1, MossyBoulder = 1, HibiscusBush = 1, Vine = 1})[c.Name] then maybe(c, "loose jungle decor") end
end
for _, fname in ipairs({"BiomeDecor_Jungle", "BiomeDecor_Retro"}) do
	local f = workspace:FindFirstChild(fname)
	if f then for _, c in ipairs(f:GetChildren()) do maybe(c, fname) end end
end
local sd = workspace:FindFirstChild("StageDecor20260930") and workspace.StageDecor20260930:FindFirstChild("Jungle")
if sd then for _, c in ipairs(sd:GetChildren()) do K.archive(c, AREA, "StageDecor20260930 jungle piece replaced by the remaster (waterfall only visually filled the south-wall hole, no collision)"); na += 1 end end
local arv = workspace:FindFirstChild("ARVORE/TREE"); if arv then K.archive(arv, AREA, "classic tree canopy floating over the north wall"); na += 1 end
table.insert(log, "decor " .. na)

-- free-spot helper (no collidable parts, 2 studs clear of fields, keep the gate band x>-5, z 236..284 open)
local fields = {}
for _, z in ipairs(workspace.SnowFieldZones:GetChildren()) do if z:IsA("BasePart") then table.insert(fields, z) end end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {workspace.SnowFieldZones}
local function free(cx, cz, sx, sz)
	for _, p in ipairs(workspace:GetPartBoundsInBox(CFrame.new(cx, Y + 4, cz), Vector3.new(sx, 6, sz), op)) do
		if p.CanCollide and p.Position.Y + p.Size.Y / 2 > Y + 0.5 then return false end
	end
	for _, f in ipairs(fields) do
		local rel = f.CFrame:PointToObjectSpace(Vector3.new(cx, f.Position.Y, cz))
		if math.abs(rel.X) < f.Size.X / 2 + sx / 2 + 2 and math.abs(rel.Z) < f.Size.Z / 2 + sz / 2 + 2 then return false end
	end
	if cx + sx / 2 > -5 and cz + sz / 2 > 236 and cz - sz / 2 < 284 then return false end
	return true
end
local placed = {}
local function put(name, x, z, sx, sz, fx, fz, cols, scale, sub)
	local px, pz = x, z
	if not free(x, z, sx, sz) then
		px = nil
		for r = 2, 10, 2 do for a = 0, 330, 30 do
			local tx, tz = x + math.cos(math.rad(a)) * r, z + math.sin(math.rad(a)) * r
			if not px and free(tx, tz, sx, sz) then px, pz = tx, tz end
		end end
	end
	if not px then table.insert(log, name .. " skipped"); return nil end
	local m = K.place(name, at(px, pz, fx or CENTER.X, fz or CENTER.Z), AREA, scale, sub)
	if cols then K.addColliders(m, AREA, cols) end
	table.insert(placed, name .. string.format("@%.0f,%.0f", px, pz))
	return m
end
local function light(part, col, range, br) if part then local l = Instance.new("PointLight"); l.Color = col; l.Range = range; l.Brightness = br; l.Parent = part end end

-- 3) landmark: the temple in the south-east corner beside the Retro gate, stairs facing west over the fields
local temple = put("J_Temple", 12, 224, 20, 23, -60, 224, {{Vector3.new(0, 3, 0), Vector3.new(22, 6, 20)}, {Vector3.new(0, 9, 0), Vector3.new(17, 6, 15.5)}, {Vector3.new(0, 15, 0), Vector3.new(12.5, 6, 11)}, {Vector3.new(0, 2, -11), Vector3.new(5.2, 4, 3)}}, 0.85)
if temple then
	for _, d in ipairs(temple:GetChildren()) do
		if d.Name == "Eye" or d.Name == "ShrineGlow" then light(d, Color3.fromRGB(124, 255, 178), 16, 1.2) end
		if d.Name == "Flame" then light(d, Color3.fromRGB(255, 190, 110), 12, 1.0) end
	end
	local a = Instance.new("Attachment"); a.Position = Vector3.new(0, 12, 0); a.Parent = temple.PrimaryPart
	local e = Instance.new("ParticleEmitter"); e.Name = "Fireflies"; e.Rate = 5; e.Lifetime = NumberRange.new(2.5, 4); e.Speed = NumberRange.new(0.3, 0.8)
	e.SpreadAngle = Vector2.new(180, 180); e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0)})
	e.Color = ColorSequence.new(Color3.fromRGB(190, 255, 140)); e.LightEmission = 1; e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	a.Parent = temple.PrimaryPart; e.Parent = a
end
local idol = put("J_Idol", 12, 293, 14, 14, -60, 293, {{Vector3.new(0, 7.5, 0), Vector3.new(10, 15, 9)}})
if idol then for _, d in ipairs(idol:GetChildren()) do if d.Name == "Eye" then light(d, Color3.fromRGB(124, 255, 178), 12, 1) end end end
-- 4) lane gateway pillars + plants in the east strip
for _, z in ipairs({244, 271}) do put("J_Pillar", -20, z, 4, 4, -60, 258, {{Vector3.new(0, 6, 0), Vector3.new(3, 12, 3)}}, 1.1) end
put("J_Palm", -19, 224, 4, 4, -60, 224, {{Vector3.new(0, 5, 0), Vector3.new(1.8, 10, 1.8)}}, 1.0, "Plants")
put("J_Palm", -18, 300, 4, 4, -60, 300, {{Vector3.new(0, 5, 0), Vector3.new(1.8, 10, 1.8)}}, 0.9, "Plants")
put("J_Bamboo", -6, 216, 8, 5, -60, 216, {{Vector3.new(0, 6, 0), Vector3.new(4.5, 12, 4.5)}}, 1.0, "Plants")
put("J_Bamboo", -8, 302, 8, 5, -60, 302, {{Vector3.new(0, 6, 0), Vector3.new(4.5, 12, 4.5)}}, 0.9, "Plants")
put("J_Hibiscus", 0, 300, 8, 7, -60, 290, {{Vector3.new(0, 2, 0), Vector3.new(6, 4, 5)}}, 1.0, "Plants")
put("J_Boulder", -12, 289, 8, 6, -60, 280, {{Vector3.new(0, 2.5, 0), Vector3.new(6, 5, 5)}}, 1.0, "Plants")
-- 5) parrots circling over the fields
for i, b in ipairs({{-100, 32, 223, 26}, {-60, 28, 290, 18}, {-150, 34, 260, 14}}) do
	local m = K.place("J_Parrot", CFrame.new(b[1], b[2], b[3]) * CFrame.Angles(0, math.rad(i * 70), 0), AREA, 1.6, "Life")
	m:SetAttribute("StageDecorMotion", "Orbit"); m:SetAttribute("MotionRadius", b[4]); m:SetAttribute("MotionSpeed", 0.35 + i * 0.05); m:SetAttribute("MotionPhase", i * 2)
end
-- 6) background: giant rainforest trees + palms on the south ledge and behind the north wall
for _, c in ipairs({{-140, 166, 1.15, 20}, {-87, 172, 1.0, 70}, {-35, 166, 1.1, 140}, {-165, 350, 1.2, 10}, {-45, 352, 1.1, 200}}) do
	K.place("J_BigTree", CFrame.new(c[1], 0, c[2]) * CFrame.Angles(0, math.rad(c[4]), 0), AREA, c[3], "Background")
end
for _, c in ipairs({{-112, 178, 1.1, 30}, {-62, 176, 1.0, 200}}) do
	K.place("J_Palm", CFrame.new(c[1], Y, c[2]) * CFrame.Angles(0, math.rad(c[4]), 0), AREA, c[3], "Background")
end
table.insert(log, "props " .. #placed .. " (" .. table.concat(placed, ",") .. "); instances " .. #K.scenery(AREA):GetDescendants())
return table.concat(log, "; ")
