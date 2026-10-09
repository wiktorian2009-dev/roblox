-- hub_open.luau (2026-10-09, Claude) - wiktor: "i think the lobby block off garages to much maybe we should rearange".
-- Opens the view and the walk from the Frostfall plaza to all 8 garage bays of the hub ring (workspace.HubRing, PlowGarage.Bays):
--   * every bay keeps a clear LANE: the view cone from the plaza edge on its axis to its open side (at least 12 studs wide);
--   * trees, rocks and snow piles that stood in the lanes go to the gaps between bays, behind the bays and to the east edges;
--   * Pet Fuser + TravelPad go east, either side of the snow yard (the way to the fields);
--   * Crafting, the Bumper Arena portal and the Crystal Pavilion stand in the wide back part of three gaps between bays;
--   * lanterns + benches mark the narrow strips between lanes; the frozen pond and its penguins move behind the spawn.
-- Bays, spawn, leaderboards, travel points, the snow yard and the ring floor do not move. Nothing is deleted.
-- Run in Studio EDIT (MCP execute_luau or the command bar).
--   MODE "plan"  : validate the layout, change nothing
--   MODE "apply" : first run backs up every original pivot; every run moves things from their ORIGINAL pivot (re-runnable)
--   MODE "undo"  : put everything back from ServerStorage.HubOpenBackup_20261009
local MODE = "plan"

local SS = game:GetService("ServerStorage")
local BACKUP = "HubOpenBackup_20261009"
local C = Vector3.new(-100, 0, -282)                                    -- lobby centre (snow globe)
local BAY = {158, 202, 125.33, 234.67, 92.67, 267.33, 60, 300}         -- Bay_1..8 axis angles (0 = east, 90 = -Z)
local R_FRONT, R_BACK, BAY_HW = 97, 142, 24.2                           -- bay open side, back wall, half width

local function rad(a) return math.rad(a) end
local function U(a) return Vector3.new(math.cos(rad(a)), 0, -math.sin(rad(a))) end  -- outward
local function V(a) return Vector3.new(-math.sin(rad(a)), 0, -math.cos(rad(a))) end -- sideways (toward larger angles)
local function at(a, r, o) return C + U(a) * r + V(a) * (o or 0) end
local function flat(p) return Vector3.new(p.X, 0, p.Z) end
local function polar(p) local dx, dz = p.X - C.X, p.Z - C.Z return math.sqrt(dx * dx + dz * dz), (math.deg(math.atan2(-dz, dx)) + 360) % 360 end
local function angDist(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
local function floorTop(p) return polar(p) < 89 and 0.24 or 0.14 end -- village snow / ring floor
local function getPivot(i) return i:IsA("Model") and i:GetPivot() or i.CFrame end
local function setPivot(i, cf) if i:IsA("Model") then i:PivotTo(cf) else i.CFrame = cf end end
local function radiusOf(i)
	local _, s
	if i:IsA("Model") then _, s = i:GetBoundingBox() else s = i.Size end
	return math.max(s.X, s.Z) / 2
end

--------------------------------------------------------------------------------------------------
-- rules (what must stay clear)
--------------------------------------------------------------------------------------------------
local function laneHW(t) return math.max(6, BAY_HW * (t - 28) / 69 + 1.5) end
local function laneHit(p, R)
	local rel = flat(p) - C
	for i, a in ipairs(BAY) do
		local t, d = rel:Dot(U(a)), math.abs(rel:Dot(V(a)))
		if t > 22 - R and t < R_FRONT + R and d < laneHW(math.clamp(t, 22, R_FRONT)) + R then return "lane " .. i end
	end
end
local function bayHit(p, R)
	local rel = flat(p) - C
	for i, a in ipairs(BAY) do
		local t, d = rel:Dot(U(a)), math.abs(rel:Dot(V(a)))
		if t > R_FRONT - R - 0.6 and t < R_BACK + R + 0.6 and d < BAY_HW + R + 0.6 then return "bay " .. i end
	end
end
local FIXED = { -- {x, z, R} circles and {x0, x1, z0, z1} rects that stay where they are
	{rect = {-76.5, -19.5, -300, -264}, why = "snow yard"},
	{rect = {-31, -29, -307, -257}, why = "yard fence"},
	{c = Vector3.new(-66, 0, -304), R = 1.6, why = "goal post"}, {c = Vector3.new(-66, 0, -260), R = 1.6, why = "goal post"},
	{rect = {-26.5, 6, -307, -257}, why = "field path"},
	{rect = {-26, -4, -320, -302}, why = "scout camp"},
	{c = Vector3.new(-16, 0, -257), R = 5, why = "sled"}, {c = Vector3.new(-6, 0, -267), R = 4, why = "trail sign"},
	{c = Vector3.new(-17, 0, -336), R = 18, why = "ice peak"}, {c = Vector3.new(-17, 0, -228), R = 18, why = "ice peak"},
	{c = Vector3.new(-167, 0, -282), R = 7, why = "spawn"},
	{rect = {-240.5, -233, -301.5, -262.5}, why = "leaderboards"},
	{c = Vector3.new(-160, 0, -273), R = 1.5, why = "avenue lantern"}, {c = Vector3.new(-160, 0, -291), R = 1.5, why = "avenue lantern"},
}
local function fixedHit(p, R)
	for _, f in ipairs(FIXED) do
		if f.c then
			if (flat(p) - f.c).Magnitude < f.R + R then return f.why end
		else
			local x0, x1, z0, z1 = table.unpack(f.rect)
			local cx, cz = math.clamp(p.X, x0, x1), math.clamp(p.Z, z0, z1)
			if Vector2.new(p.X - cx, p.Z - cz).Magnitude < R then return f.why end
		end
	end
end
local MOUNTAINS = {} -- filled below: {c, R}
local function areaHit(p, R, opts)
	local r, a = polar(p)
	if r < 27 + R then return "plaza" end
	local east = angDist(a, 0) < 45
	if east and r + R > 86 then return "village edge" end
	if r + R > 158 then return "ring rim" end
	if not east and r > 87 and math.min(angDist(a, 45), angDist(a, 315)) < 5 then -- the ring's east ends (RingEnd walls)
		local rel = flat(p) - C
		for _, e in ipairs({45, 315}) do if math.abs(rel:Dot(V(e))) < 2.5 + R and rel:Dot(U(e)) > 85 then return "ring end" end end
	end
	if angDist(a, 180) < 25 and r > 22 and r < 76 and math.abs((flat(p) - C):Dot(V(180))) < 5 + R then return "spawn avenue" end
	if not (opts and opts.pathOK) then -- walking paths from the plaza to the Crafting machine and the arena portal (gaps 141.67 / 218.33)
		local rel = flat(p) - C
		for s, stop in pairs({[141.67] = 130.5, [218.33] = 123.5}) do -- the path ends at the front of the machine / portal
			local t = rel:Dot(U(s))
			if t > 28 and t < stop and math.abs(rel:Dot(V(s))) < 3 + R then return "path to the gap" end
		end
	end
	if not (opts and opts.mountainsOK) then
		for _, m in ipairs(MOUNTAINS) do if (flat(p) - m.c).Magnitude < m.R + R then return "mountain" end end
	end
end

--------------------------------------------------------------------------------------------------
-- collect
--------------------------------------------------------------------------------------------------
local village = workspace:FindFirstChild("FrostfallVillage")
local decor = workspace:FindFirstChild("FrostfallLobbyDecor") and workspace.FrostfallLobbyDecor:FindFirstChild("Props")
local ff = workspace:FindFirstChild("W1Remaster") and workspace.W1Remaster:FindFirstChild("Frostfall")
assert(village and decor and ff, "lobby folders missing")
local bk = SS:FindFirstChild(BACKUP)

local entries = {} -- {inst, kind, orig}
local byInst = {}
local function add(inst, kind)
	if not inst or byInst[inst] then return end
	local e = {inst = inst, kind = kind}
	table.insert(entries, e); byInst[inst] = e
	return e
end
for _, c in ipairs(decor:GetChildren()) do
	local k = c.Name
	if k == "SnowMound" then k = (c:IsA("BasePart") and c.CanCollide and math.max(c.Size.X, c.Size.Z) > 4.2) and "mound" or "smallmound" end
	if k == "Snowman" then k = (c.Size.Y > 8) and "snowmanBig" or "snowmanSmall" end
	add(c, k)
end
for _, c in ipairs(ff.Pines:GetChildren()) do add(c, "F_Pine") end
for _, c in ipairs(ff.Lanterns:GetChildren()) do add(c, "F_Lantern") end
for _, c in ipairs(ff.Benches:GetChildren()) do add(c, "F_Bench") end
for _, n in ipairs({"PetFuser", "CraftingMachine", "CrystalPavilion", "StringLights"}) do add(village:FindFirstChild(n), n) end
add(workspace:FindFirstChild("TravelPad"), "TravelPad")
add(workspace:FindFirstChild("ArenaPortals") and workspace.ArenaPortals:FindFirstChild("LobbyArenaPortal"), "ArenaPortal")
-- the two mountains behind the Crafting / Pavilion gaps (seams 141.67 and 251, r 165)
local MOUNTAIN_PUSH = {[141.67] = 178, [251] = 176}
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "SnowyMountain" and c:IsA("Model") then
		local cf, s = c:GetBoundingBox()
		local r, a = polar(cf.Position)
		for seam, newR in pairs(MOUNTAIN_PUSH) do
			if angDist(a, seam) < 2 and math.abs(r - 165) < 3 then local e = add(c, "Mountain"); e.seam = seam; e.newR = newR end
		end
	end
end
-- original pivots: from the backup when it exists (so re-runs start from the same layout)
local origOf = {}
if bk then
	for _, v in ipairs(bk.Moved:GetChildren()) do if v:IsA("ObjectValue") and v.Value then origOf[v.Value] = v:GetAttribute("OrigPivot") end end
end
for _, e in ipairs(entries) do e.orig = origOf[e.inst] or getPivot(e.inst) end
-- colliders that belong to the W1Remaster pines / lanterns / benches (matched by ORIGINAL position)
local colliders, orphan = {}, nil
for _, col in ipairs(ff.Colliders:GetChildren()) do
	if col:IsA("BasePart") then
		local orig = origOf[col] or col.CFrame
		local want = col.Name == "F_PineCollider" and "F_Pine" or col.Name == "F_LanternCollider" and "F_Lantern" or col.Name == "F_BenchCollider" and "F_Bench"
		local best, bd
		for _, e in ipairs(entries) do
			if e.kind == want then
				local d = (flat(orig.Position) - flat(e.orig.Position)).Magnitude
				if not bd or d < bd then best, bd = e, d end
			end
		end
		local lim = want == "F_Pine" and 1.5 or want == "F_Lantern" and 2.5 or 6
		if best and bd <= lim then table.insert(colliders, {inst = col, owner = best, orig = orig})
		elseif want == "F_Pine" then orphan = col end
	end
end
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "SnowyMountain" and not byInst[c] then local cf, s = c:GetBoundingBox(); table.insert(MOUNTAINS, {c = flat(cf.Position), R = s.X / 2 * 0.78}) end
end
for _, c in ipairs(village.MountainBackdrop:GetChildren()) do local cf, s = c:GetBoundingBox(); table.insert(MOUNTAINS, {c = flat(cf.Position), R = s.X / 2 * 0.78}) end
for _, e in ipairs(entries) do if e.kind == "Mountain" then local _, s = e.inst:GetBoundingBox(); table.insert(MOUNTAINS, {c = flat(at(e.seam, e.newR)), R = s.X / 2 * 0.78}) end end

--------------------------------------------------------------------------------------------------
-- undo
--------------------------------------------------------------------------------------------------
if MODE == "undo" then
	if not bk then return "no backup" end
	local n = 0
	for _, v in ipairs(bk.Moved:GetChildren()) do
		if v:IsA("ObjectValue") and v.Value and v:GetAttribute("OrigPivot") then setPivot(v.Value, v:GetAttribute("OrigPivot")); n += 1 end
	end
	for _, c in ipairs(bk.Removed:GetChildren()) do
		local path = c:GetAttribute("HubOpenOrigParent")
		local cur = game
		for _, name in ipairs(string.split(path or "", ".")) do cur = cur and (cur == game and (name == "Workspace" and workspace or game:FindFirstChild(name)) or cur:FindFirstChild(name)) end
		if cur then c.Parent = cur; n += 1 end
	end
	return "undone: " .. n .. " objects back in their original place"
end

--------------------------------------------------------------------------------------------------
-- plan targets
--------------------------------------------------------------------------------------------------
local placed = {}   -- circles {c, R, name} of everything placed so far (for overlap tests)
local rects = {}    -- oriented boxes of the big pieces {cf, hx, hz}
local report, fails = {}, {}
local target = {}   -- [entry] = CFrame
local function log(s) table.insert(report, s) end
local function rectHit(p, R)
	for _, b in ipairs(rects) do
		local l = b.cf:PointToObjectSpace(Vector3.new(p.X, b.cf.Y, p.Z))
		local cx, cz = math.clamp(l.X, -b.hx, b.hx), math.clamp(l.Z, -b.hz, b.hz)
		if Vector2.new(l.X - cx, l.Z - cz).Magnitude < R + 0.8 then return "next to " .. b.name end
	end
end
local function circleHit(p, R, ignore)
	for _, c in ipairs(placed) do
		if not (ignore and ignore[c.name]) and (flat(p) - c.c).Magnitude < c.R + R + 0.4 then return "touches " .. c.name end
	end
end
local function why(p, R, opts)
	return laneHit(p, R) or bayHit(p, R) or areaHit(p, R, opts) or fixedHit(p, R) or rectHit(p, R) or circleHit(p, R, opts and opts.ignore)
end
local function yawCF(pos, e, faceCentre, jitter)
	local y = e.orig.Y + floorTop(pos) - floorTop(e.orig.Position)
	local p = Vector3.new(pos.X, y, pos.Z)
	if faceCentre then
		local cf = CFrame.lookAt(p, Vector3.new(C.X, y, C.Z))
		return jitter and cf * CFrame.Angles(0, rad(jitter), 0) or cf
	end
	return CFrame.new(p) * e.orig.Rotation
end
-- place one entry on a slot (a, r, o) in the slot's own frame; nudges outward/sideways until the spot is clear
local function placeOn(e, a, r, o, how)
	local R = (how and how.R) or radiusOf(e.inst) * 0.92
	local tries = {{0, 0}}
	for _, dr in ipairs({1.5, -1.5, 3, -3, 4.5, -4.5, 6, -6}) do table.insert(tries, {dr, 0}) end
	for _, dr in ipairs({0, 1.5, -1.5, 3, -3, 4.5, -4.5}) do for _, d0 in ipairs({1.5, -1.5, 3, -3, 4.5, -4.5}) do table.insert(tries, {dr, d0}) end end
	for _, t in ipairs(tries) do
		local p = at(a, r + t[1], (o or 0) + t[2])
		local w = why(p, R, how)
		if not w then
			local cf
			if how and how.face then cf = yawCF(p, e, true, how.jitter)
			elseif how and how.randomYaw then cf = CFrame.new(p.X, e.orig.Y + floorTop(p) - floorTop(e.orig.Position), p.Z) * CFrame.Angles(0, rad(how.randomYaw), 0) * e.orig.Rotation
			else cf = yawCF(p, e, false) end
			target[e] = cf
			table.insert(placed, {c = flat(p), R = R, name = e.inst.Name .. "#" .. (how and how.tag or "")})
			return true
		end
	end
	local w = why(at(a, r, o), R, how)
	table.insert(fails, string.format("%s (%s) at a %.1f r %.1f o %.1f: %s", e.inst.Name, e.kind, a, r, o or 0, tostring(w)))
	return false
end
local function byKind(kind)
	local t = {}
	for _, e in ipairs(entries) do if e.kind == kind then table.insert(t, e) end end
	table.sort(t, function(x, y) local _, ax = polar(x.orig.Position); local _, ay = polar(y.orig.Position); return ax < ay end)
	return t
end
local used = {}
local function take(list) for _, e in ipairs(list) do if not used[e] then used[e] = true return e end end end

-- 1) big pieces (fixed spots, facing the plaza centre)
local BIG = {
	{kind = "PetFuser", a = 326, r = 66, hx = 12.4, hz = 12.4},
	{kind = "TravelPad", a = 32, r = 63, hx = 9.6, hz = 9.6},
	{kind = "CraftingMachine", a = 141.67, r = 141.5, hx = 11.4, hz = 9.8},
	{kind = "ArenaPortal", a = 218.33, r = 128.5, hx = 9.4, hz = 3.6},
	{kind = "CrystalPavilion", a = 251, r = 137.5, hx = 10.1, hz = 10.1},
}
for _, b in ipairs(BIG) do
	local e = byKind(b.kind)[1]
	if e then
		used[e] = true
		local p = at(b.a, b.r)
		local cf = yawCF(p, e, true)
		target[e] = cf
		-- check the box corners against lanes / bays / fixed things / mountains
		for _, sx in ipairs({-1, -0.5, 0, 0.5, 1}) do for _, sz in ipairs({-1, -0.5, 0, 0.5, 1}) do
			local q = cf * Vector3.new(sx * b.hx, 0, sz * b.hz)
			local w = laneHit(q, 0) or bayHit(q, 0.4) or areaHit(q, 0) or fixedHit(q, 0)
			if w then table.insert(fails, b.kind .. " corner " .. sx .. "," .. sz .. ": " .. w) end
		end end
		table.insert(rects, {cf = cf, hx = b.hx, hz = b.hz, name = b.kind})
		log(string.format("%s -> a %.1f r %.1f (%.1f, %.1f)", b.kind, b.a, b.r, p.X, p.Z))
	end
end
for _, e in ipairs(byKind("StringLights")) do used[e] = true; target[e] = e.orig + Vector3.new(-23.2, 0, 0) end -- poles to r 50 in strips 141.67 / 218.33
for _, e in ipairs(byKind("Mountain")) do
	used[e] = true
	local cf, s = e.inst:GetBoundingBox()
	local _, a = polar(e.orig.Position)
	local r0 = polar(cf.Position)
	if origOf[e.inst] then r0 = polar((e.orig * e.inst:GetPivot():Inverse() * cf).Position) end -- re-run: radius of the ORIGINAL box
	target[e] = e.orig + U(a) * (e.newR - r0)
end
-- the pole sites of the moved string lights
table.insert(placed, {c = flat(at(141.67, 50)), R = 0.8, name = "festival pole"}); table.insert(placed, {c = flat(at(218.33, 50)), R = 0.8, name = "festival pole"})

-- 2) groups that move together: the frozen pond scene (west gap, behind the spawn), snowmen with presents
local function groupMove(members, centre, to, turn, name, groupR)
	for _, e in ipairs(members) do
		used[e] = true
		local rel = CFrame.new(flat(centre)):Inverse() * e.orig
		local cf = CFrame.new(flat(to)) * CFrame.Angles(0, rad(turn), 0) * rel
		local dy = floorTop(cf.Position) - floorTop(e.orig.Position)
		target[e] = cf + Vector3.new(0, dy, 0)
		local p = cf.Position
		local R = radiusOf(e.inst) * 0.8
		local w = laneHit(p, R) or bayHit(p, R) or fixedHit(p, R) or rectHit(p, R) or areaHit(p, R)
		if w then table.insert(fails, name .. " member " .. e.inst.Name .. ": " .. w) end
	end
	table.insert(placed, {c = flat(to), R = groupR or 7, name = name})
end
local pondE = byKind("FrozenPond")[1]
if pondE then
	local pc = pondE.orig.Position
	local members = {pondE}
	for _, e in ipairs(entries) do
		if e ~= pondE and (e.kind == "Penguin" or e.kind == "smallmound" or e.kind == "IceRock") and (flat(e.orig.Position) - flat(pc)).Magnitude < 11.5 then table.insert(members, e) end
	end
	groupMove(members, pc, at(180, 105.5), 90, "pond scene", 12)
	log("pond scene: " .. #members .. " pieces -> behind the spawn (a 180 r 105.5)")
end
local function nearGroup(kinds, centre, radius)
	local m = {}
	for _, e in ipairs(entries) do
		if not used[e] and kinds[e.kind] and (flat(e.orig.Position) - flat(centre)).Magnitude < radius then table.insert(m, e) end
	end
	return m
end
local SNOW_KINDS = {snowmanBig = true, snowmanSmall = true, Present = true}
-- NE snowmen + three presents (stood in Bay 7's lane) -> next to the TravelPad
local g1c = Vector3.new(-59.5, 0, -332.5)
local g1 = nearGroup(SNOW_KINDS, g1c, 7)
groupMove(g1, g1c, at(42, 44.5), -25, "snowmen NE", 6.5)
-- plaza snowmen + two presents (stood in Bay 3's lane) -> next to the Pet Fuser
local g2c = Vector3.new(-122.5, 0, -307.5)
local g2 = nearGroup(SNOW_KINDS, g2c, 6)
groupMove(g2, g2c, at(319, 44.5), 145, "snowmen SE", 6)
log(string.format("snowman groups: %d + %d pieces", #g1, #g2))

-- 3) lanterns (6 into the strips between lanes, the 2 by the spawn stay), benches (face the globe)
local STRIPS = {76.33, 109, 141.67, 218.33, 251, 283.67}
local LANTERN_R = {[76.33] = 40.5, [109] = 38.5, [141.67] = 42, [218.33] = 39, [251] = 41.5, [283.67] = 38}
local lanterns = byKind("F_Lantern")
for _, e in ipairs(lanterns) do
	local r, a = polar(e.orig.Position)
	if math.abs(r - 61) < 2 and angDist(a, 180) < 12 then used[e] = true; target[e] = e.orig; table.insert(placed, {c = flat(e.orig.Position), R = 1.2, name = "avenue lantern"}) end
end
for _, s in ipairs(STRIPS) do
	local best, bd
	for _, e in ipairs(lanterns) do if not used[e] then local _, a = polar(e.orig.Position); local d = angDist(a, s); if not bd or d < bd then best, bd = e, d end end end
	if best then used[best] = true; placeOn(best, s, LANTERN_R[s], 0, {R = 1.1, tag = "lantern", pathOK = true}) end
end
local BENCH = {{76.33, 48.5}, {109, 47.5}, {283.67, 48}, {251, 46.5}}
for i, e in ipairs(byKind("F_Bench")) do
	local b = BENCH[i]
	if b then used[e] = true; placeOn(e, b[1], b[2], 0, {R = 4.1, face = true, tag = "bench"}) end
end

-- 4) pines: small ones in the narrow front of the gaps, bigger ones further back / behind the bays / east edges
local pines = {}
for _, e in ipairs(entries) do if (e.kind == "SnowPine" or e.kind == "F_Pine") and not used[e] then table.insert(pines, e) end end
table.sort(pines, function(x, y) return radiusOf(x.inst) < radiusOf(y.inst) end)
local PINE_SLOTS = {
	-- {angle, r, side offset, frame: "seam" (a = gap angle) / "bay" (a = bay angle) / "polar"}
	{76.33, 111, 0}, {109, 110.5, 0.8}, {283.67, 111.5, -0.6},                       -- gap fronts (narrow)
	{76.33, 125.5, -4.6}, {76.33, 128.5, 5.2}, {109, 126.5, 4.6}, {283.67, 124.5, 4.8}, {283.67, 128, -5},
	{40, 78, 0}, {158, 151.5, -10},                                                  -- east edge by the ice peak, behind Bay 1
	{76.33, 141, -1.5}, {109, 139.5, -3.5}, {283.67, 141.5, 2},                      -- gap backs
	{125.33, 152, -15}, {125.33, 155, 9}, {267.33, 151, 13}, {267.33, 154.5, -9},    -- behind bays
	{234.67, 152.5, 11}, {60, 151.5, -12}, {92.67, 153, 7}, {300, 152, -13},
}
for i, slot in ipairs(PINE_SLOTS) do
	local e = pines[i]
	if e then used[e] = true; placeOn(e, slot[1], slot[2], slot[3], {R = radiusOf(e.inst) * 0.78, randomYaw = (i * 47) % 360, tag = "pine"}) end
end
for i = #PINE_SLOTS + 1, #pines do table.insert(fails, "no slot for pine " .. pines[i].inst.Name) end

-- the presents beside the scout camp belong to that scene: they stay
for _, e in ipairs(entries) do
	if not used[e] and e.kind == "Present" and (flat(e.orig.Position) - Vector3.new(-28, 0, -312)).Magnitude < 6 then
		used[e] = true; target[e] = e.orig; table.insert(placed, {c = flat(e.orig.Position), R = 1.6, name = "scout present"})
	end
end

-- 5) rocks, drifts and snow mounds (anything not placed yet): gap mouths, gap backs, strips, behind bays, east edges
local MID_SLOTS = {
	{76.33, 101, 0}, {109, 101, 0}, {283.67, 101, 0},                                 -- gap mouths (low pieces between bay corners)
	{76.33, 135.5, 8.5}, {109, 121, -6.5}, {109, 133, 8}, {283.67, 137, -9.5}, {283.67, 118.5, 4.8},
	{76.33, 61, 0}, {109, 62, 0.5}, {283.67, 60, -0.5},                               -- outer end of the decorated strips
	{125.33, 150, 2}, {125.33, 148.5, 18}, {234.67, 149, -6}, {234.67, 150, 19}, {92.67, 149, -9}, {92.67, 151, 18},
	{267.33, 149, 2}, {60, 149.5, 4}, {60, 151, 16}, {300, 149.5, 6}, {300, 151, 18}, {202, 150.5, -14}, {158, 150.5, 14},
	{36, 70, 0}, {324, 82, 0}, {26, 81, 0}, {41, 61, 0}, {319, 62, 0},                  -- east edges
}
local mids = {}
for _, e in ipairs(entries) do
	if not used[e] and (e.kind == "mound" or e.kind == "IceRock" or e.kind == "HutDrift" or e.kind == "smallmound") then table.insert(mids, e) end
end
table.sort(mids, function(x, y) return radiusOf(x.inst) < radiusOf(y.inst) end)
local si = 1
for _, e in ipairs(mids) do
	-- leave pieces that already stand somewhere fine (not in a lane, a bay or on the paths)
	local p = e.orig.Position
	local R = radiusOf(e.inst) * 0.8
	if not why(p, R) then used[e] = true; target[e] = e.orig; table.insert(placed, {c = flat(p), R = R, name = e.inst.Name .. "#kept"})
	else
		local slot = MID_SLOTS[si]; si += 1
		if slot then used[e] = true; placeOn(e, slot[1], slot[2], slot[3], {R = R, randomYaw = (si * 61) % 360, tag = "mid"})
		else table.insert(fails, "no slot for " .. e.inst.Name) end
	end
end

-- 6) whatever small decor is left (presents, penguins): keep if fine, else into the decorated strips / east
local SMALL_SLOTS = {{76.33, 56, 0}, {109, 56.5, -0.8}, {283.67, 55.5, 0.6}, {76.33, 65, 0.5}, {283.67, 66, 0}, {109, 68, 0},
	{28, 73, 0}, {331, 74, 0}, {22, 70, 0}, {337, 70, 0}}
local sj = 1
for _, e in ipairs(entries) do
	if not used[e] then
		local p = e.orig.Position
		local R = radiusOf(e.inst) * 0.8
		if not why(p, R) then used[e] = true; target[e] = e.orig; table.insert(placed, {c = flat(p), R = R, name = e.inst.Name .. "#kept"})
		else
			local slot = SMALL_SLOTS[sj]; sj += 1
			if slot then used[e] = true; placeOn(e, slot[1], slot[2], slot[3], {R = R, randomYaw = (sj * 73) % 360, tag = "small"})
			else table.insert(fails, "no slot for " .. e.inst.Name .. " (" .. e.kind .. ")") end
		end
	end
end

-- summary
local moved, kept = 0, 0
for _, e in ipairs(entries) do
	if target[e] then if (target[e].Position - e.orig.Position).Magnitude > 0.05 then moved += 1 else kept += 1 end end
end
log(string.format("entries %d: move %d, stay %d; colliders %d; orphan pine collider %s", #entries, moved, kept, #colliders, orphan and orphan:GetFullName() or "none"))
for _, f in ipairs(fails) do log("PROBLEM: " .. f) end
if MODE == "plan" then return table.concat(report, "\n") end
if MODE ~= "apply" then return "unknown MODE" end
if #fails > 0 then return table.concat(report, "\n") .. "\nNOT APPLIED (fix the problems first)" end

--------------------------------------------------------------------------------------------------
-- apply
--------------------------------------------------------------------------------------------------
local fresh = not bk
if fresh then
	bk = Instance.new("Folder"); bk.Name = BACKUP
	bk:SetAttribute("Note", "hub_open.luau 2026-10-09 (outputs/HubOpen20261009). MODE undo puts every listed object back at OrigPivot.")
	local mv = Instance.new("Folder"); mv.Name = "Moved"; mv.Parent = bk
	local rm = Instance.new("Folder"); rm.Name = "Removed"; rm.Parent = bk
end
local function remember(inst, cf) -- every object is recorded once, with the pivot it had before the first apply
	if origOf[inst] then return end
	local v = Instance.new("ObjectValue"); v.Name = inst.Name; v.Value = inst; v:SetAttribute("OrigPivot", cf); v.Parent = bk.Moved
	origOf[inst] = cf
end
for _, e in ipairs(entries) do remember(e.inst, e.orig) end
for _, c in ipairs(colliders) do remember(c.inst, c.orig) end
if fresh then bk.Parent = SS end
local n = 0
for _, e in ipairs(entries) do
	if target[e] then setPivot(e.inst, target[e]); n += 1 end
	if n % 40 == 0 then task.wait() end
end
for _, c in ipairs(colliders) do
	local t = target[c.owner]
	if t then c.inst.CFrame = t * c.owner.orig:Inverse() * c.orig end
end
-- the invisible trunk collider of a pine that no longer exists stood in Bay 5's lane: into the backup
if orphan and orphan.Parent ~= bk.Removed then orphan:SetAttribute("HubOpenOrigParent", orphan.Parent:GetFullName()); orphan.Parent = bk.Removed end
-- decor that stood on the ice walk (top 0.49) would float on the ring floor: settle it onto the snow
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include
floorParams.FilterDescendantsInstances = {village.Island.SnowGround, workspace.HubRing.SnowFloor}
for _, e in ipairs(entries) do
	local inst = e.inst
	if inst:IsA("BasePart") and inst.Parent == decor and target[e] then
		local hit = workspace:Raycast(Vector3.new(inst.Position.X, 40, inst.Position.Z), Vector3.new(0, -80, 0), floorParams)
		if hit then
			local low = math.huge
			for _, sx in ipairs({-0.5, 0.5}) do for _, sy in ipairs({-0.5, 0.5}) do for _, sz in ipairs({-0.5, 0.5}) do
				low = math.min(low, (inst.CFrame * Vector3.new(sx * inst.Size.X, sy * inst.Size.Y, sz * inst.Size.Z)).Y)
			end end end
			if low - hit.Position.Y > 0.08 then inst.CFrame -= Vector3.new(0, low - hit.Position.Y + 0.05, 0) end
		end
	end
end
-- the six tall cliff facets of the old village rim poke 0.6 stud out of the ring floor as flat blue slabs: sink them to 0.02
for _, d in ipairs(village.Island:GetChildren()) do
	if d.Name == "CliffFacet" then
		local _, a = polar(d.Position)
		if angDist(a, 0) > 45 then
			if not origOf[d] then remember(d, d.CFrame) end
			local orig = origOf[d]
			local top = -math.huge
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				top = math.max(top, (orig * Vector3.new(sx * d.Size.X / 2, sy * d.Size.Y / 2, sz * d.Size.Z / 2)).Y)
			end end end
			if top > 0.1 then d.CFrame = orig - Vector3.new(0, top - 0.02, 0) end
		end
	end
end
return table.concat(report, "\n") .. "\nAPPLIED (" .. n .. " objects + " .. #colliders .. " colliders)"
