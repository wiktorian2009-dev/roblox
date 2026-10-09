-- hub_mountains.luau (2026-10-10, Claude) - wiktor: "place the wall from this mountains around garages/lobby".
-- Closes the ring of snowy mountains around the hub (garages + lobby) with copies of the existing SnowyMountain model:
--   * gap fillers where the sky showed between the mountains behind the bays (seen from the plaza)
--   * a taller outer ridge behind them, so the wall reads as one range from anywhere in the hub
--   * canyon walls along both sides of the west gap: that gap stays clear because extra garage bays are built there when more
--     than 8 players are in the garage at once (PlowGarage.OverflowOrigin, columns grow west, |z+282| <= 92)
-- The east opening to the snow fields stays open. Nothing existing moves; every new mountain is in workspace.HubMountainWall.
-- Run in Studio EDIT.  MODE "plan" (report) / "apply" (refuses if the folder exists) / "undo" (folder -> ServerStorage backup)
local MODE = "plan"

local SS = game:GetService("ServerStorage")
local FOLDER, BACKUP = "HubMountainWall", "HubMountainWallBackup_20261010"
local C = Vector3.new(-100, 0, -282)
local rng = Random.new(20261010)

local function rad(a) return math.rad(a) end
local function U(a) return Vector3.new(math.cos(rad(a)), 0, -math.sin(rad(a))) end
local function at(a, r) return C + U(a) * r end
local function flat(p) return Vector3.new(p.X, 0, p.Z) end
local function polar(p) local dx, dz = p.X - C.X, p.Z - C.Z return math.sqrt(dx * dx + dz * dz), (math.deg(math.atan2(-dz, dx)) + 360) % 360 end

if MODE == "undo" then
	local f = workspace:FindFirstChild(FOLDER)
	if not f then return "nothing to undo" end
	local bk = SS:FindFirstChild(BACKUP) or Instance.new("Folder")
	bk.Name = BACKUP; bk.Parent = SS
	f.Parent = bk
	return "moved workspace." .. FOLDER .. " into ServerStorage." .. BACKUP
end

-- source model: the 36-wide SnowyMountain (every hub mountain uses the same mesh)
local src
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "SnowyMountain" and c:IsA("Model") then
		local _, s = c:GetBoundingBox()
		if not src or math.abs(s.X - 36) < math.abs(select(2, src:GetBoundingBox()).X - 36) then src = c end
	end
end
assert(src, "no SnowyMountain to copy")
local _, srcSize = src:GetBoundingBox()

-- things the mountains must keep away from
local existing = {}
local function addExisting(m)
	local cf, s = m:GetBoundingBox()
	table.insert(existing, {c = flat(cf.Position), R = s.X * 0.42})
end
for _, c in ipairs(workspace:GetChildren()) do if c.Name == "SnowyMountain" then addExisting(c) end end
for _, c in ipairs(workspace.FrostfallVillage.MountainBackdrop:GetChildren()) do addExisting(c) end
for _, c in ipairs(workspace["lobby walls"]:GetChildren()) do addExisting(c) end
local keepOut = {} -- trees, gap buildings behind the bays
for _, inst in ipairs({workspace.FrostfallVillage.CraftingMachine, workspace.FrostfallVillage.CrystalPavilion, workspace.ArenaPortals.LobbyArenaPortal}) do
	local cf, s = inst:GetBoundingBox()
	table.insert(keepOut, {c = flat(cf.Position), R = math.max(s.X, s.Z) * 0.71, name = inst.Name})
end
for _, d in ipairs(workspace.FrostfallLobbyDecor.Props:GetChildren()) do
	if d.Name == "SnowPine" then table.insert(keepOut, {c = flat(d.Position), R = math.max(d.Size.X, d.Size.Z) / 2, name = "pine"}) end
end
for _, d in ipairs(workspace.W1Remaster.Frostfall.Pines:GetChildren()) do
	local cf = d:GetPivot()
	table.insert(keepOut, {c = flat(cf.Position), R = 4, name = "pine"})
end
local function inOverflow(p, R) -- the west street of extra garage bays
	return p.X - R < -258 and math.abs(p.Z - C.Z) < 92 + R + 4
end
local function why(p, R)
	local r, a = polar(p)
	if r - R < 156 then return "inside the hub floor" end
	if inOverflow(p, R) then return "extra-garage street" end
	local east = (a < 22 or a > 338)
	if east and r < 420 then return "east opening" end
	for _, k in ipairs(keepOut) do if (flat(p) - k.c).Magnitude < k.R + R + 2 then return "next to " .. k.name end end
	return nil
end

--------------------------------------------------------------------------------------------------
-- placements {a, r, width} (width = base diameter of the model's bounding box)
--------------------------------------------------------------------------------------------------
local P = {}
local function add(a, r, w, tag) table.insert(P, {a = a, r = r, w = w, tag = tag}) end
-- 1) fillers for the sky gaps between the mountains behind the bays (gap centres seen from the plaza)
add(55, 196, 40, "gap"); add(68, 192, 46, "gap"); add(85, 196, 44, "gap"); add(134, 196, 44, "gap")
add(227, 195, 48, "gap"); add(242, 196, 44, "gap"); add(260, 192, 40, "gap"); add(276, 196, 44, "gap")
-- 2) outer ridge, taller, staggered between the fillers
for _, s in ipairs({{48, 222, 54}, {62, 228, 60}, {78, 222, 58}, {96, 226, 62}, {112, 220, 56}, {126, 228, 60}, {140, 222, 54},
		{220, 224, 56}, {234, 228, 62}, {249, 222, 58}, {264, 228, 62}, {280, 222, 56}, {295, 236, 60}}) do
	add(s[1], s[2], s[3], "ridge")
end
-- 3) canyon walls on both sides of the west gap (x from -270 to -450, |z+282| ~ 125-150)
for i, x in ipairs({-292, -338, -386, -436}) do
	local dz = 128 + (i % 2) * 14
	for _, side in ipairs({-1, 1}) do
		local p = Vector3.new(x + rng:NextNumber(-6, 6), 0, C.Z + side * (dz + rng:NextNumber(-5, 5)))
		local r, a = polar(p)
		add(a, r, 46 + rng:NextNumber(0, 16), "canyon")
	end
end
-- (no distant range across the west gap: with 60-player servers the extra-garage street can grow far west)

local report, fails = {}, {}
for _, m in ipairs(P) do
	local p = at(m.a, m.r)
	local R = m.w * 0.42
	m.pos = p
	local w = why(p, R)
	if w then table.insert(fails, string.format("%s a %.1f r %.0f w %.0f: %s", m.tag, m.a, m.r, m.w, w)) end
end
table.insert(report, string.format("%d new mountains (source %s, %.0f wide)", #P, src:GetFullName(), srcSize.X))
for _, f in ipairs(fails) do table.insert(report, "PROBLEM: " .. f) end
if MODE == "plan" then return table.concat(report, "\n") end
if MODE ~= "apply" then return "unknown MODE" end
if #fails > 0 then return table.concat(report, "\n") .. "\nNOT APPLIED" end
if workspace:FindFirstChild(FOLDER) then return "already applied - undo first" end

local folder = Instance.new("Folder")
folder.Name = FOLDER
folder:SetAttribute("Note", "hub_mountains.luau 2026-10-10 (outputs/HubOpen20261009): copies of SnowyMountain; MODE undo moves this folder to ServerStorage." .. BACKUP)
local BASE_Y = -30 -- the hub floats: the cones reach down to y -30 so no sky shows between the rim and a mountain's foot
for i, m in ipairs(P) do
	local c = src:Clone()
	c:ScaleTo(c:GetScale() * (m.w / srcSize.X))
	c:PivotTo(CFrame.new(m.pos) * CFrame.Angles(0, rad(rng:NextNumber(0, 360)), 0))
	local cf, s = c:GetBoundingBox()
	c:PivotTo(c:GetPivot() + Vector3.new(0, -1 - (cf.Y - s.Y / 2), 0)) -- base 1 stud under the floor top, like the others
	-- extend the cone downward: scale by 1 + D/h and drop the base to BASE_Y (same silhouette above the floor, same top)
	cf, s = c:GetBoundingBox()
	local D = (cf.Y - s.Y / 2) - BASE_Y
	c:ScaleTo(c:GetScale() * (1 + D / s.Y))
	cf, s = c:GetBoundingBox()
	c:PivotTo(c:GetPivot() + Vector3.new(0, BASE_Y - (cf.Y - s.Y / 2), 0))
	c:SetAttribute("WallPart", m.tag)
	c.Parent = folder
	if i % 10 == 0 then task.wait() end
end
folder.Parent = workspace
return table.concat(report, "\n") .. "\nAPPLIED"
