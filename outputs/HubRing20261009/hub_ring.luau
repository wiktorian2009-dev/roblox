-- hub_ring.luau (2026-10-09, Claude) - wiktor: "having lobby is having no point lets move garages to make almost a circle shape
-- so the lobby became garages and lobby itself".
-- The 8 garage bays move into a near-circle around the Frostfall lobby (open to the east, where the snow fields are) on a new snow
-- ring floor, so the lobby and the garages are one space. Run in Studio EDIT (MCP execute_luau / command bar).
--   MODE "plan"  : report only, changes nothing
--   MODE "apply" : backs up, then builds (refuses if a backup already exists)
--   MODE "undo"  : puts everything back from ServerStorage.HubRingBackup_20261009 (the ring floor is moved into the backup)
-- Nothing is deleted: removed objects go to ServerStorage.HubRingBackup_20261009.Removed (attribute HubOrigParent = old parent path),
-- moved objects are listed in .Moved (ObjectValue -> instance, attribute OrigPivot).
local MODE = "plan"

local SS = game:GetService("ServerStorage")
local BACKUP_NAME = "HubRingBackup_20261009"
local C = Vector3.new(-100, 0, -282)       -- lobby centre (FrostfallVillage.Island)
local Y_TOP = 0.14                          -- ring floor top (lobby snow 0.24, bay floors 0.20)
local R_VILLAGE = 89                        -- lobby snow disc radius
local R_E, BAY_D, BAY_HW = 97, 45, 24.2     -- bay entrance radius, bay depth, bay half width
local R_OUT = 162                           -- ring floor radius
local END_ANG = 45                          -- ring spans END_ANG .. 360 - END_ANG (the east sector stays open)
-- angle: 0 = +X (east, the fields), 90 = -Z. Bay_1/Bay_2 nearest the spawn (west), then outward.
local BAY_ANG = {158, 202, 125.33, 234.67, 92.67, 267.33, 60, 300}
local GAP_ANG = 180                         -- west gap: path to the overflow bays (built on demand)
local GAP_HALF = 12                         -- half-angle of the overflow opening collider (the 45-stud street is about +-8 deg)
local OVERFLOW_CF = CFrame.new(C.X - R_OUT - 24, 0.2, C.Z) * CFrame.Angles(0, math.pi, 0) -- LookVector +Z, columns grow west

local function rad(a) return math.rad(a) end
local function at(a, r, y) return Vector3.new(C.X + r * math.cos(rad(a)), y or 0, C.Z - r * math.sin(rad(a))) end
local function polar(p)
	local dx, dz = p.X - C.X, p.Z - C.Z
	return math.sqrt(dx * dx + dz * dz), (math.deg(math.atan2(-dz, dx)) + 360) % 360
end
local function angDist(a, b) local d = math.abs(a - b) % 360; return d > 180 and 360 - d or d end
local function inSpan(a) return a >= END_ANG and a <= 360 - END_ANG end
local function bayCF(a)
	local p = at(a, R_E + BAY_D / 2, 0.2)
	return CFrame.lookAt(p, Vector3.new(C.X, 0.2, C.Z))
end
local BAY_CFS = {}
for i, a in ipairs(BAY_ANG) do BAY_CFS[i] = bayCF(a) end

-- circle (xz centre, radius) vs a bay footprint (+margin)
local function hitsBay(center, r, margin)
	for _, cf in ipairs(BAY_CFS) do
		local p = cf:PointToObjectSpace(Vector3.new(center.X, cf.Y, center.Z))
		local hx, hz = BAY_HW + margin, BAY_D / 2 + margin
		local cx, cz = math.clamp(p.X, -hx, hx), math.clamp(p.Z, -hz, hz)
		if (Vector2.new(p.X - cx, p.Z - cz)).Magnitude < r then return true end
	end
	return false
end
-- circle vs the ring floor (sector END_ANG..360-END_ANG, radius R_OUT)
local function hitsRing(center, r)
	local d, a = polar(center)
	if d - r > R_OUT then return false end
	if inSpan(a) then return d + r > R_VILLAGE - 2 end
	local gap = math.min(angDist(a, END_ANG), angDist(a, 360 - END_ANG))
	return d * math.sin(rad(gap)) < r
end
-- the overflow corridor (columns of bays west of the ring)
local function hitsOverflow(center, r)
	return center.X - r < C.X - R_OUT + 4 and math.abs(center.Z - C.Z) < 95 + r and center.X + r > C.X - R_OUT - 600
end
local OLD_GARAGE = {x0 = -445, x1 = -185, z0 = -382, z1 = -184}
local function inOldGarage(p) return p.X > OLD_GARAGE.x0 and p.X < OLD_GARAGE.x1 and p.Z > OLD_GARAGE.z0 and p.Z < OLD_GARAGE.z1 end

local function bbox(inst)
	if inst:IsA("Model") then return inst:GetBoundingBox() end
	if inst:IsA("BasePart") then return inst.CFrame, inst.Size end
end
local function getPivot(inst) if inst:IsA("Model") then return inst:GetPivot() end return inst.CFrame end
local function setPivot(inst, cf) if inst:IsA("Model") then inst:PivotTo(cf) else inst.CFrame = cf end end

--------------------------------------------------
-- collect
--------------------------------------------------
local report = {}
local function log(s) table.insert(report, s) end
local g = workspace:FindFirstChild("PlowGarage")
local bays = {}
if g and g:FindFirstChild("Bays") then
	for _, m in ipairs(g.Bays:GetChildren()) do
		local i = m:GetAttribute("BayIndex")
		if type(i) == "number" and i >= 1 and i <= 8 then bays[i] = m end
	end
end

-- mountains: every top-level SnowyMountain, the "lobby walls" mountains and the lobby's ice peaks
local mountains = {}
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "SnowyMountain" then table.insert(mountains, c) end
	if c.Name == "lobby walls" then for _, cc in ipairs(c:GetChildren()) do if cc.Name == "SnowyMountain" then table.insert(mountains, cc) end end end
end
local backdrop = workspace:FindFirstChild("FrostfallVillage") and workspace.FrostfallVillage:FindFirstChild("MountainBackdrop")
local framePeaks = {} -- the two ice peaks that frame the east opening: turned a little toward the fields
if backdrop then
	for _, c in ipairs(backdrop:GetChildren()) do
		if c.Name == "IcePeak_2" or c.Name == "IcePeak_8" then table.insert(framePeaks, c) else table.insert(mountains, c) end
	end
end

local moveM, keepM, backupM = {}, {}, {}
for _, m in ipairs(mountains) do
	local cf, size = bbox(m)
	local r = math.max(size.X, size.Z) / 2 * 0.85
	local info = {inst = m, center = cf.Position, r = r, bottom = cf.Position.Y - size.Y / 2, size = size}
	local _, a = polar(cf.Position)
	-- mountains in the open east sector that only touch a ring end stay where they are (they frame the opening)
	if hitsBay(cf.Position, r, 2) or (inSpan(a) and hitsRing(cf.Position, r)) then table.insert(moveM, info)
	elseif inOldGarage(cf.Position) or hitsOverflow(cf.Position, r) then table.insert(backupM, info)
	else table.insert(keepM, info) end
end

-- slots for the mountains that have to move: behind the bays, in the back gaps between bays, and at the two ring ends
local slots = {}
for i, a in ipairs(BAY_ANG) do
	if i > 2 then table.insert(slots, {a = a, r = 176}) end
end
table.insert(slots, {a = 146, r = 178}); table.insert(slots, {a = 214, r = 178})
for _, a in ipairs({76.33, 109, 141.67, 218.33, 251, 283.67}) do table.insert(slots, {a = a, r = 165}) end
table.insert(slots, {a = 50, r = 172}); table.insert(slots, {a = 310, r = 172})

local free = table.clone(moveM)
local placements = {}
local PREFER = {[50] = "IcePeak_9", [60] = "IcePeak_10", [300] = "IcePeak_0", [310] = "IcePeak_1"} -- the lobby's ice peaks keep framing the east
for _, s in ipairs(slots) do
	local best, bi
	for i, info in ipairs(free) do
		if PREFER[s.a] and info.inst.Name == PREFER[s.a] then best, bi = -1, i break end
	end
	if not bi then
		for i, info in ipairs(free) do
			local _, a = polar(info.center)
			local d = angDist(a, s.a)
			if not best or d < best then best, bi = d, i end
		end
	end
	if bi then
		local info = table.remove(free, bi)
		local r = s.r
		while r < 215 do
			local c = at(s.a, r, 0)
			if not hitsBay(c, info.r, 2) and not hitsOverflow(c, info.r) and polar(c) - info.r > R_E + BAY_D + 1 then break end
			r += 2
		end
		local target = at(s.a, r, 0)
		table.insert(placements, {info = info, slot = s, r = r, target = target})
	end
end
for _, info in ipairs(free) do table.insert(backupM, info) end

-- objects riding on moved mountains (the watchtower on the north mountain)
local riders = {}
local bg = workspace:FindFirstChild("W1Remaster") and workspace.W1Remaster:FindFirstChild("Frostfall") and workspace.W1Remaster.Frostfall:FindFirstChild("Background")
if bg then
	for _, c in ipairs(bg:GetChildren()) do
		local cf = bbox(c)
		if cf then
			for _, pl in ipairs(placements) do
				local d = Vector2.new(cf.X - pl.info.center.X, cf.Z - pl.info.center.Z).Magnitude
				if d < pl.info.r + 2 then table.insert(riders, {inst = c, pl = pl}) break end
			end
		end
	end
end

-- W1Edges pieces inside the ring (the lobby's old west rim, walls and colliders)
local edgeParts = {}
if workspace:FindFirstChild("W1Edges") then
	for _, d in ipairs(workspace.W1Edges:GetDescendants()) do
		if d:IsA("BasePart") then
			local r, a = polar(d.Position)
			if (r > R_VILLAGE - 8 and r < R_OUT + 30 and a >= END_ANG - 4 and a <= 364 - END_ANG) or (inOldGarage(d.Position) and r > R_VILLAGE - 8) then
				table.insert(edgeParts, d)
			end
		end
	end
end
-- lobby edge snow inside the ring span (would sit between the village and the bays)
local edgeSnow, facets = {}, {}
local isl = workspace:FindFirstChild("FrostfallVillage") and workspace.FrostfallVillage:FindFirstChild("Island")
if isl then
	for _, c in ipairs(isl:GetChildren()) do
		local _, a = polar(c.Position)
		if c.Name == "EdgeSnow" and inSpan(a) then table.insert(edgeSnow, c) end
		if c.Name == "CliffFacet" and inSpan(a) then table.insert(facets, c) end
	end
end
-- the old garage island (everything but the bays, the arrival and the overflow anchor)
local oldGarage = {}
if g then
	for _, c in ipairs(g:GetChildren()) do
		if c.Name ~= "Bays" and c.Name ~= "Arrival" and c.Name ~= "OverflowOrigin" then table.insert(oldGarage, c) end
	end
end
-- anything else that would end up inside a bay (report only)
local blockers = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d.Transparency < 0.95 and d.Position.Y > -20 and d.Position.Y < 60 and math.abs(polar(d.Position) - 125) < 45
		and hitsBay(d.Position, 0.5, 1)
		and not d:IsDescendantOf(g or workspace.Terrain) then
		local skip = (isl and d:IsDescendantOf(isl)) or (workspace:FindFirstChild("W1Edges") and d:IsDescendantOf(workspace.W1Edges))
		if not skip then for _, m in ipairs(mountains) do if d:IsDescendantOf(m) then skip = true break end end end
		if not skip then blockers[d:GetFullName()] = true end
	end
end

log(string.format("bays found: %d", #bays))
log(string.format("mountains: %d move to slots, %d to backup, %d untouched; slots %d", #placements, #backupM, #keepM, #slots))
for _, pl in ipairs(placements) do
	local _, a0 = polar(pl.info.center)
	log(string.format("  move %s from ang %.0f r %.0f -> slot ang %.1f r %d (radius %.0f)", pl.info.inst:GetFullName(), a0, polar(pl.info.center), pl.slot.a, pl.r, pl.info.r))
end
for _, info in ipairs(backupM) do local d, a = polar(info.center); log(string.format("  backup %s ang %.0f r %.0f", info.inst:GetFullName(), a, d)) end
log(string.format("riders: %d; W1Edges parts to backup: %d; lobby EdgeSnow to backup: %d; CliffFacets lowered: %d; old garage pieces to backup: %d",
	#riders, #edgeParts, #edgeSnow, #facets, #oldGarage))
local nb = 0
for k in pairs(blockers) do nb += 1; if nb <= 40 then log("  inside a new bay: " .. k) end end
log("objects inside new bay footprints: " .. nb)

if MODE == "plan" then return table.concat(report, "\n") end

--------------------------------------------------
-- undo
--------------------------------------------------
if MODE == "undo" then
	local bk = SS:FindFirstChild(BACKUP_NAME)
	if not bk then return "no backup" end
	local n = 0
	for _, v in ipairs(bk.Moved:GetChildren()) do
		if v:IsA("ObjectValue") and v.Value then setPivot(v.Value, v:GetAttribute("OrigPivot")); n += 1 end
	end
	local function resolve(path)
		local cur = game
		for _, name in ipairs(string.split(path, ".")) do
			if cur == game and name == "Workspace" then cur = workspace
			elseif cur == game then cur = game:GetService(name)
			else cur = cur and cur:FindFirstChild(name) end
		end
		return cur
	end
	-- the ring's PlowGarage.Colliders (only RimWestGap) goes first, so the old Colliders folder is the only one again
	local newCols = g and g:FindFirstChild("Colliders")
	if newCols and newCols:FindFirstChild("RimWestGap") then newCols.Name = "RingColliders"; newCols.Parent = bk end
	for _, c in ipairs(bk.Removed:GetChildren()) do
		local parent = resolve(c:GetAttribute("HubOrigParent") or "")
		if parent then c.Parent = parent; n += 1 end
	end
	local ring = workspace:FindFirstChild("HubRing")
	if ring then ring.Parent = bk end
	return "undone: " .. n .. " objects restored (scripts are restored separately)"
end

--------------------------------------------------
-- apply
--------------------------------------------------
if MODE ~= "apply" then return "unknown MODE" end
if SS:FindFirstChild(BACKUP_NAME) then return "backup already exists - undo first or rename it" end
if #bays ~= 8 then return "expected 8 bays, found " .. #bays end
local bk = Instance.new("Folder"); bk.Name = BACKUP_NAME
local moved = Instance.new("Folder"); moved.Name = "Moved"; moved.Parent = bk
local removed = Instance.new("Folder"); removed.Name = "Removed"; removed.Parent = bk
bk:SetAttribute("Note", "hub_ring.luau apply 2026-10-09. MODE undo restores (outputs/HubRing20261009).")
bk.Parent = SS
local function remember(inst)
	local v = Instance.new("ObjectValue"); v.Name = inst.Name; v.Value = inst
	v:SetAttribute("OrigPivot", getPivot(inst)); v.Parent = moved
end
local function stash(inst)
	inst:SetAttribute("HubOrigParent", inst.Parent:GetFullName())
	inst.Parent = removed
end

-- 1) the ring first (CSG can fail - nothing has been touched yet then): snow floor, icy shelf, rock base (east sector cut out), edge rocks, snow rim, invisible rim colliders
local ring = Instance.new("Model"); ring.Name = "HubRing"
ring.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local function newPart(cls, props, parent)
	local p = Instance.new(cls)
	p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end
local S = 260
local function cutter()
	-- a square turned 45 deg with one corner on the lobby centre covers exactly the east sector (-45..45 deg)
	return newPart("Part", {Size = Vector3.new(S, 40, S), CFrame = CFrame.new(C.X + S / math.sqrt(2), -5, C.Z) * CFrame.Angles(0, rad(45), 0), Transparency = 1}, nil)
end
local function layer(name, radius, top, thick, color, material)
	local disc = newPart("Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, radius * 2, radius * 2),
		CFrame = CFrame.new(C.X, top - thick / 2, C.Z) * CFrame.Angles(0, 0, rad(90)), Color = color, Material = material}, workspace)
	local cut = cutter(); cut.Parent = workspace
	local ok, u = pcall(function() return disc:SubtractAsync({cut}, Enum.CollisionFidelity.PreciseConvexDecomposition, Enum.RenderFidelity.Precise) end)
	cut:Destroy()
	if not ok or not u then disc.Parent = nil; error("CSG failed for " .. name .. ": " .. tostring(u)) end
	disc:Destroy()
	u.Name = name; u.Anchored = true; u.UsePartColor = true; u.Color = color; u.Material = material
	u.Parent = ring
	return u
end
local floorU = layer("SnowFloor", R_OUT, Y_TOP, 0.9, Color3.fromRGB(238, 245, 252), Enum.Material.Snow)
layer("IceShelf", R_OUT + 1, Y_TOP - 0.3, 3.2, Color3.fromRGB(100, 165, 190), Enum.Material.SmoothPlastic)
layer("RockBase", R_OUT + 2, Y_TOP - 0.5, 9, Color3.fromRGB(29, 55, 83), Enum.Material.Slate)
floorU.CanCollide = true
task.wait()

local rng = Random.new(20261009)
local rocks = Instance.new("Folder"); rocks.Name = "EdgeRocks"; rocks.Parent = ring
for a = END_ANG + 2, 360 - END_ANG - 2, 5 do
	local p = at(a, R_OUT + 0.5, Y_TOP - 5.2 - rng:NextNumber(0, 1.5))
	newPart("Part", {Name = "EdgeRock", Size = Vector3.new(rng:NextNumber(9, 13), rng:NextNumber(8, 11), rng:NextNumber(6, 8)),
		CFrame = CFrame.lookAt(p, Vector3.new(C.X, p.Y, C.Z)) * CFrame.Angles(rad(rng:NextNumber(-6, 6)), 0, rad(rng:NextNumber(-8, 8))),
		Color = Color3.fromRGB(72, 124, 153):Lerp(Color3.fromRGB(58, 98, 128), rng:NextNumber()), Material = Enum.Material.SmoothPlastic,
		CanCollide = false, CanQuery = false, CanTouch = false}, rocks)
end

local snowRim = Instance.new("Folder"); snowRim.Name = "SnowRim"; snowRim.Parent = ring
local function ball(p)
	local s = rng:NextNumber(1.7, 2.3)
	newPart("Part", {Name = "Snowball", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), CFrame = CFrame.new(p),
		Color = Color3.fromRGB(243, 252, 255), Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false}, snowRim)
end
local arcLen = R_OUT * rad(360 - 2 * END_ANG)
local nArc = math.floor(arcLen / 2.2)
for i = 0, nArc do
	local a = END_ANG + (360 - 2 * END_ANG) * i / nArc
	ball(at(a, R_OUT - 0.6, Y_TOP + 0.25))
end
for _, a in ipairs({END_ANG, 360 - END_ANG}) do
	for r = R_VILLAGE + 1, R_OUT - 1, 2.2 do
		local p = at(a, r, Y_TOP + 0.25)
		local side = a < 180 and -1 or 1 -- toward the open sector
		local t = Vector3.new(-math.sin(rad(a)), 0, -math.cos(rad(a))) * side * 0.6
		ball(p + t)
	end
end
task.wait()

local cols = Instance.new("Folder"); cols.Name = "Colliders"; cols.Parent = ring
local function collider(name, cf, size, parent)
	return newPart("Part", {Name = name, CFrame = cf, Size = size, Transparency = 1, CanCollide = true, CanQuery = false, CanTouch = false, CastShadow = false}, parent or cols)
end
for a = END_ANG, 360 - END_ANG - 4, 4 do
	local mid = a + 2
	if angDist(mid, GAP_ANG) > GAP_HALF - 2 then
		local p = at(mid, R_OUT + 1, 8 + Y_TOP)
		collider("RingRim", CFrame.lookAt(p, Vector3.new(C.X, p.Y, C.Z)), Vector3.new(2 * (R_OUT + 1) * math.sin(rad(2)) + 0.6, 16, 2))
	end
end
-- the overflow street opening: one collider that PlowService opens (OverflowOrigin.OpenRims) when overflow bays are built
local gapLen = 2 * (R_OUT + 1) * math.sin(rad(GAP_HALF)) + 0.6
local gapPart = collider("RimWestGap", CFrame.lookAt(at(GAP_ANG, R_OUT + 1, 8 + Y_TOP), Vector3.new(C.X, 8 + Y_TOP, C.Z)), Vector3.new(gapLen, 16, 2), nil)
for _, a in ipairs({END_ANG, 360 - END_ANG}) do
	local side = a < 180 and -1 or 1
	local out = Vector3.new(-math.sin(rad(a)), 0, -math.cos(rad(a))) * side
	for r = R_VILLAGE - 2, R_OUT - 4, 10 do
		local p = at(a, r + 5, 8 + Y_TOP) + out * 1
		collider("RingEnd", CFrame.lookAt(p, p + (at(a, r + 10, 0) - at(a, r, 0)).Unit), Vector3.new(2, 16, 10.6))
	end
end
-- 2) backups / removals
for _, c in ipairs(oldGarage) do stash(c) end
for _, d in ipairs(edgeParts) do stash(d) end
for _, d in ipairs(edgeSnow) do stash(d) end
for _, info in ipairs(backupM) do stash(info.inst) end
task.wait()

-- 3) moves
for i, m in ipairs(bays) do remember(m); m:PivotTo(BAY_CFS[i]) end
for _, pl in ipairs(placements) do
	local inst = pl.info.inst
	remember(inst)
	local dy = -1.0 - pl.info.bottom
	local delta = Vector3.new(pl.target.X - pl.info.center.X, dy, pl.target.Z - pl.info.center.Z)
	setPivot(inst, getPivot(inst) + delta)
	pl.delta = delta
end
for _, rd in ipairs(riders) do remember(rd.inst); setPivot(rd.inst, getPivot(rd.inst) + rd.pl.delta) end
for _, p in ipairs(framePeaks) do
	remember(p)
	local cf = getPivot(p)
	local d, a = polar(cf.Position)
	local na = a < 180 and 33 or 327
	local np = at(na, d, cf.Y)
	setPivot(p, cf + (np - Vector3.new(cf.X, cf.Y, cf.Z)))
end
for _, f in ipairs(facets) do remember(f); f.CFrame = f.CFrame - Vector3.new(0, 0.45, 0) end
local arrival = g:FindFirstChild("Arrival")
if arrival then remember(arrival); arrival.CFrame = CFrame.lookAt(Vector3.new(-160, 3.4, -282), Vector3.new(-100, 3.4, -282)) end
local oo = g:FindFirstChild("OverflowOrigin")
if oo then remember(oo); oo.CFrame = OVERFLOW_CF; oo:SetAttribute("OpenRims", "RimWestGap") end
task.wait()

-- 4) the overflow opening collider lives in PlowGarage.Colliders (PlowService opens it by name), then the ring goes live
local gcols = Instance.new("Folder"); gcols.Name = "Colliders"; gcols.Parent = g
gapPart.Parent = gcols
ring.Parent = workspace
return table.concat(report, "\n") .. "\nAPPLIED"
