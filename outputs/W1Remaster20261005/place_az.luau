-- place_az.luau (Studio, Edit): Absolute Zero + portal plaza. Archives the part-built ice scenery (with placement info) and places the W1_Az pack.
-- Boundary: the 512-part cliff ring is tiled with Z_CliffSeg/B per side; one simple collider per tile at the mean old inner face
-- (openings - Jungle gate, yard pocket - unchanged; measured blocked field area AZ 9.0% vs 8.2% old). S2 (x<-276, z~161) is a divider between the portal plaza and the yard pocket:
-- its tiles are centred and the collider spans both old faces. Objects replaced in place keep their old collidable parts as invisible colliders.
-- Kept as-is: AbsoluteZeroPortal (functional, animated), AbsoluteZeroBiome.VFX (ambient lights + snow), AbsoluteZeroBiome.Entrance
-- (outside the ring beside the Jungle corner pillar), the grass connector strip at x -193.
local K = require(game.ServerStorage.W1RemasterKit:Clone())
local AREA = "AbsoluteZero"
local Y = 1.1
local AZ = workspace.AbsoluteZeroBiome
local log = {}
local function at(x, z, fx, fz, y) local p = Vector3.new(x, y or Y, z); return CFrame.lookAt(p, Vector3.new(fx, y or Y, fz)) end
local function copyColliders(inst, name)
	local n = 0
	for _, p in ipairs(inst:IsA("BasePart") and {inst} or inst:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide and p.Position.Y + p.Size.Y / 2 > Y + 1.5 then K.collider(AREA, p.CFrame, p.Size, name); n += 1 end
	end
	return n
end

-- 1) boundary ring
local SIDES = {
	W = {axis = "Z", inward = 1}, E = {axis = "Z", inward = -1, toBack = true}, -- E collider stops at the old outer face (Jungle field behind it)
	N = {axis = "X", inward = -1}, S1 = {axis = "X", inward = 1}, S2 = {axis = "X", inward = 1, divider = true},
}
local function sideOf(p)
	if p.X < -335 then return "W" elseif p.X > -190 then return "E" elseif p.Z > 378 then return "N"
	elseif p.X < -276 and p.Z > 140 and p.Z < 175 then return "S2" elseif p.Z < 140 then return "S1" end
end
local spans = {W = {}, E = {}, N = {}, S1 = {}, S2 = {}}
local function addSpans(folder)
	for _, p in ipairs(folder:GetDescendants()) do
		-- only parts standing on the ground can block a vehicle (floating snow caps / spikes on top are ignored)
		if p:IsA("BasePart") and p.CanCollide and p.Position.Y + p.Size.Y / 2 > Y + 1.5 and p.Position.Y - p.Size.Y / 2 < Y + 6 then
			local s = sideOf(p.Position)
			if s then
				local h = p.Size / 2; local xs, zs = {}, {}
				for _, dx in ipairs({-1, 1}) do for _, dz in ipairs({-1, 1}) do local q = p.CFrame:PointToWorldSpace(Vector3.new(dx * h.X, 0, dz * h.Z)); table.insert(xs, q.X); table.insert(zs, q.Z) end end
				local x0, x1, z0, z1 = math.min(unpack(xs)), math.max(unpack(xs)), math.min(unpack(zs)), math.max(unpack(zs))
				if SIDES[s].axis == "X" then table.insert(spans[s], {a0 = x0, a1 = x1, lo = z0, hi = z1}) else table.insert(spans[s], {a0 = z0, a1 = z1, lo = x0, hi = x1}) end
			end
		end
	end
end
addSpans(AZ.Walls); addSpans(AZ.Ruins)
local TILE, DEPTH = 14, 12
local nTile = 0
for s, def in pairs(SIDES) do
	local list = spans[s]
	table.sort(list, function(a, b) return a.a0 < b.a0 end)
	local runs, cur = {}, nil
	for _, sp in ipairs(list) do
		if cur and sp.a0 <= cur.a1 + 3 then cur.a1 = math.max(cur.a1, sp.a1) else cur = {a0 = sp.a0, a1 = sp.a1}; table.insert(runs, cur) end
	end
	for _, r in ipairs(runs) do
		if r.a1 - r.a0 > 4 then
			local k = math.max(1, math.ceil((r.a1 - r.a0) / TILE)); local w = (r.a1 - r.a0) / k
			for i = 1, k do
				local aa, ab = r.a0 + (i - 1) * w, r.a0 + i * w
				local sf, sb, cnt = 0, 0, 0
				for a = aa + 0.5, ab - 0.5, 1 do
					local f, b
					for _, sp in ipairs(list) do if sp.a0 <= a and sp.a1 >= a then
						local fv = def.inward > 0 and sp.hi or sp.lo; local bv = def.inward > 0 and sp.lo or sp.hi
						if not f or (def.inward > 0 and fv > f) or (def.inward < 0 and fv < f) then f = fv end
						if not b or (def.inward > 0 and bv < b) or (def.inward < 0 and bv > b) then b = bv end
					end end
					if f then sf += f; sb += b; cnt += 1 end
				end
				if cnt > 0 then
					local front, back = sf / cnt, sb / cnt
					local sc = w / TILE
					local c = def.divider and (front + back) / 2 or front - def.inward * (DEPTH * sc / 2 - 0.6)
					local along = (aa + ab) / 2
					local pos = def.axis == "X" and Vector3.new(along, Y - 0.5, c) or Vector3.new(c, Y - 0.5, along)
					local dir = def.axis == "X" and Vector3.new(0, 0, def.inward) or Vector3.new(def.inward, 0, 0)
					local name = (nTile % 3 == 2) and "Z_CliffSegB" or "Z_CliffSeg"
					local m = K.place(name, CFrame.lookAt(pos, pos + dir), AREA, sc * (1 + ((nTile * 37) % 7 - 3) * 0.025), "Walls")
					m:SetAttribute("Side", s); nTile += 1
					local depth = (def.divider or def.toBack) and math.max(4, math.abs(front - back)) or 16
					local cc = (def.divider or def.toBack) and (front + back) / 2 or front - def.inward * 8
					local ccf = def.axis == "X" and CFrame.new(along, Y + 15, cc) or CFrame.new(cc, Y + 15, along)
					K.collider(AREA, ccf, def.axis == "X" and Vector3.new(w, 30, depth) or Vector3.new(depth, 30, w), "WallCollider")
				end
			end
		end
	end
end
K.archive(AZ.Walls, AREA, "ice cliff ring (512 parts) replaced by Z_CliffSeg/B tiles + one WallCollider per tile")
K.archive(AZ.Ruins, AREA, "frozen ruins embedded in the south wall (their footprint is inside the S1 tile colliders)")
K.archive(AZ.Decorations, AREA, "icicles/snow shelves/cracks that decorated the old cliff ring")
table.insert(log, "tiles " .. nTile)

-- 2) archive the other old scenery (objects replaced in place keep their collidable parts as colliders)
local na = 0
local crystalSpots = {}
-- two tower clusters in the west wall (z ~210 and ~304)
crystalSpots = {210, 304}
copyColliders(AZ.Crystals, "CrystalTowerCollider")
K.archive(AZ.Crystals, AREA, "crystal tower clusters replaced by Z_CrystalTower in the same spots"); na += 1
local pine = workspace:FindFirstChild("FrozenPine")
local pinePos, pineH
if pine then local cf, s = pine:GetBoundingBox(); pinePos, pineH = cf.Position, s.Y; copyColliders(pine, "FrozenPineCollider"); K.archive(pine, AREA, "frozen pine replaced by Z_FrozenPine"); na += 1 end
local sd = workspace:FindFirstChild("StageDecor20260930")
local old = {}
for _, fname in ipairs({"AbsoluteZero", "Portal"}) do
	local f = sd and sd:FindFirstChild(fname)
	if f then for _, c in ipairs(f:GetChildren()) do old[c.Name] = c:GetBoundingBox().Position; K.archive(c, AREA, "StageDecor20260930 " .. fname .. " piece replaced by its W1_Az counterpart"); na += 1 end end
end
local bd = workspace:FindFirstChild("BiomeDecor_AbsoluteZero")
if bd then for _, c in ipairs(bd:GetChildren()) do K.archive(c, AREA, "BiomeDecor_AbsoluteZero"); na += 1 end end
table.insert(log, "decor " .. na)

local function light(part, col, range, br) if part then local l = Instance.new("PointLight"); l.Color = col; l.Range = range; l.Brightness = br; l.Parent = part end end
local CYAN = Color3.fromRGB(127, 233, 255)
local function sparkle(model, y, rate)
	local a = Instance.new("Attachment"); a.Position = Vector3.new(0, y, 0); a.Parent = model.PrimaryPart
	local e = Instance.new("ParticleEmitter"); e.Name = "Sparkle"; e.Rate = rate or 4; e.Lifetime = NumberRange.new(1.5, 2.5); e.Speed = NumberRange.new(0.4, 1.2)
	e.SpreadAngle = Vector2.new(180, 180); e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)})
	e.Color = ColorSequence.new(Color3.fromRGB(210, 250, 255), Color3.fromRGB(185, 166, 255)); e.LightEmission = 1
	e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume; e.Parent = a
end

-- 3) landmarks in the old spots
if pinePos then
	local m = K.place("Z_FrozenPine", CFrame.new(pinePos.X, Y, pinePos.Z) * CFrame.Angles(0, math.rad(20), 0), AREA, math.clamp(pineH / 46, 0.7, 1.4))
	local st = m:FindFirstChild("Star"); light(st, CYAN, 18, 1)
end
for _, zc in ipairs(crystalSpots) do
	local m = K.place("Z_CrystalTower", at(-350, zc, -258, zc), AREA, 1.1)
	light(m:FindFirstChild("Core"), CYAN, 24, 1.2); sparkle(m, 20, 5)
end
local heartPos = old.FrozenHeartEngine or Vector3.new(-327, 0, 183)
local heart = K.place("Z_HeartEngine", at(heartPos.X, heartPos.Z, -258, heartPos.Z), AREA, 0.95)
K.addColliders(heart, AREA, {{Vector3.new(0, 1.6, 0), Vector3.new(16, 3.2, 16)}, {Vector3.new(0, 9, 0), Vector3.new(14, 14, 3)}, {Vector3.new(0, 9, 0), Vector3.new(3, 14, 14)}})
for _, d in ipairs(heart:GetChildren()) do
	if d.Name == "Ring" then d:SetAttribute("StageDecorMotion", "Spin"); d:SetAttribute("MotionAxis", "Y"); d:SetAttribute("MotionSpeed", 0.5) end
	if d.Name == "HeartCore" then light(d, CYAN, 26, 1.4) end
end
sparkle(heart, 11, 6)
local camp = K.place("Z_Camp", at((old.PolarResearchCamp or Vector3.new(-197, 0, 341)).X, (old.PolarResearchCamp or Vector3.new(-197, 0, 341)).Z, -258, 341), AREA)
K.addColliders(camp, AREA, {{Vector3.new(3, 2.5, 1), Vector3.new(10, 5, 8.5)}, {Vector3.new(-5, 1.2, -3), Vector3.new(5, 2.4, 3)}})
light(camp:FindFirstChild("MastLight"), Color3.fromRGB(255, 120, 90), 10, 0.8)
for _, b in ipairs({{"FrostBeacon1", -324, 332}, {"FrostBeacon2", -192, 178}}) do
	local m = K.place("Z_Beacon", at(b[2], b[3], -258, 255), AREA, 1.0, "Beacons")
	K.addColliders(m, AREA, {{Vector3.new(0, 5, 0), Vector3.new(2.6, 10, 2.6)}})
	light(m:FindFirstChild("Lamp"), CYAN, 16, 1)
end
-- portal plaza: guardians + aurora banners where the old ones stood, facing the field
for _, g in ipairs({{"PortalGuardian1", 215}, {"PortalGuardian2", 295}}) do
	local p = old[g[1]] or Vector3.new(-311, 0, g[2])
	local m = K.place("Z_Guardian", at(p.X, p.Z, -258, p.Z), AREA, 1.1, "Portal")
	K.addColliders(m, AREA, {{Vector3.new(0, 6, 0), Vector3.new(5.2, 12, 5.2)}})
	for _, d in ipairs(m:GetChildren()) do if d.Name == "SpearTip" then light(d, CYAN, 10, 0.8) end end
end
for _, b in ipairs({{"AuroraBanner1", 224}, {"AuroraBanner2", 289}}) do
	local p = old[b[1]] or Vector3.new(-312, 0, b[2])
	local m = K.place("Z_Banner", at(p.X, p.Z, -258, p.Z), AREA, 1.0, "Portal")
	K.addColliders(m, AREA, {{Vector3.new(0, 8, 0), Vector3.new(0.8, 16, 0.8)}})
	for _, d in ipairs(m:GetChildren()) do if d.Name == "Cloth" or d.Name == "Cloth2" then d:SetAttribute("StageDecorMotion", "Sway"); d:SetAttribute("MotionAmount", 0.06); d:SetAttribute("MotionSpeed", 1.4) end end
end
local ruins = K.place("Z_Ruins", at(-326, 366, -258, 366), AREA, 1.0)
K.addColliders(ruins, AREA, {{Vector3.new(0, 5, 0), Vector3.new(15, 10, 3.4)}})
-- penguins (Bob) by the camp and the heart engine
for i, p in ipairs({{-201, 328}, {-188, 356}, {-312, 172}, {-310, 196}, {-206, 352}}) do
	local m = K.place("Z_Penguin", at(p[1], p[2], -258, 255), AREA, 1.3, "Life")
	m:SetAttribute("StageDecorMotion", "Bob"); m:SetAttribute("MotionAmount", 0.35); m:SetAttribute("MotionSpeed", 2.2 + i * 0.3); m:SetAttribute("MotionPhase", i)
end
table.insert(log, "instances " .. #K.scenery(AREA):GetDescendants())
return table.concat(log, "; ")
