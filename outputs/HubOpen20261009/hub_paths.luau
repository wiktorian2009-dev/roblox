-- hub_paths.luau (2026-10-09, Claude) - wiktor: "Make layout diffrent so paths will lead to garages".
-- Replaces the old village ice walk (one trident-shaped union that led to the old village spots) with a path network
-- that leads to the garages of the hub ring:
--   * a straight ice path from the plaza to the open side of each of the 8 bays (along the bay's clear lane)
--   * a ring path in front of the bays (r 82-90) from Bay 7 round the west to Bay 8, crossing the spawn avenue
--   * the spawn avenue (plaza -> spawn -> ring), a short link from the plaza to the snow yard
--   * narrow branches from the ring into the gaps with the Crafting machine, the arena portal and the Crystal Pavilion
-- Same look as the old walk: Ice (132,200,232) on a Snow border (238,245,252), top 0.49 / 0.435, not solid, not queryable.
-- The old ContinuousIceWalk + ContinuousSnowBorder move to ServerStorage.HubPathsBackup_20261009 (nothing is deleted).
-- Run in Studio EDIT.  MODE "build" (refuses if already built) / "undo".
local MODE = "build"

local SS = game:GetService("ServerStorage")
local BACKUP = "HubPathsBackup_20261009"
local C = Vector3.new(-100, 0, -282)
local BAY = {158, 202, 125.33, 234.67, 92.67, 267.33, 60, 300}
local ICE_COLOR, SNOW_COLOR = Color3.fromRGB(132, 200, 232), Color3.fromRGB(238, 245, 252)
local ICE_TOP, ICE_T = 0.49, 0.40       -- ice slab reaches below both floors (village 0.24, ring 0.14): no gap at the edges
local SNOW_TOP, SNOW_T = 0.435, 0.535
local W, B = 10, 0.6                     -- path width, snow border per side
local BRANCH_W = 5
local RING_IN, RING_OUT, RING_END = 82, 90, 52 -- ring path radii; it spans RING_END .. 360-RING_END through the west
local walkways = workspace.FrostfallVillage.Walkways

local function rad(a) return math.rad(a) end
local function U(a) return Vector3.new(math.cos(rad(a)), 0, -math.sin(rad(a))) end
local function at(a, r, y) return C + U(a) * r + Vector3.new(0, y or 0, 0) end

if MODE == "undo" then
	local bk = SS:FindFirstChild(BACKUP)
	if not bk then return "no backup" end
	for _, n in ipairs({"SpokeIceWalk", "SpokeSnowBorder"}) do
		local u = walkways:FindFirstChild(n)
		if u then u.Parent = bk.Built end
	end
	for _, c in ipairs(bk.Removed:GetChildren()) do c.Parent = walkways end
	return "undone: old ice walk back, new paths in " .. BACKUP .. ".Built"
end
if MODE ~= "build" then return "unknown MODE" end
if walkways:FindFirstChild("SpokeIceWalk") then return "already built - undo first" end

local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	return p
end
-- a straight strip along angle a from radius r0 to r1
local function strip(a, r0, r1, width, top, thick)
	local mid = at(a, (r0 + r1) / 2, top - thick / 2)
	return newPart({Size = Vector3.new(width, thick, r1 - r0), CFrame = CFrame.lookAt(mid, mid + U(a))})
end
-- ring sector: annulus rIn..rOut with the east wedge [-endA, endA] cut out
local function ring(rIn, rOut, endA, top, thick)
	local y = top - thick / 2
	local disc = newPart({Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, rOut * 2, rOut * 2), CFrame = CFrame.new(C.X, y, C.Z) * CFrame.Angles(0, 0, rad(90))})
	local hole = newPart({Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick + 2, rIn * 2, rIn * 2), CFrame = CFrame.new(C.X, y, C.Z) * CFrame.Angles(0, 0, rad(90))})
	local S = 260
	local cuts = {hole}
	for _, beta in ipairs({-(endA - 45), endA - 45}) do -- two 90-degree corner squares cover [-endA, endA]
		local c = newPart({Size = Vector3.new(S, thick + 4, S), CFrame = CFrame.new(C + U(beta) * (S / math.sqrt(2)) + Vector3.new(0, y, 0)) * CFrame.Angles(0, rad(beta + 45), 0)})
		table.insert(cuts, c)
	end
	disc.Parent = workspace
	for _, c in ipairs(cuts) do c.Parent = workspace end
	local ok, u = pcall(function() return disc:SubtractAsync(cuts, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Precise) end)
	disc:Destroy()
	for _, c in ipairs(cuts) do c:Destroy() end
	if not ok or not u then error("ring CSG failed: " .. tostring(u)) end
	return u
end
local function layer(name, widen, top, thick, color, material)
	local w, bw = W + 2 * widen, BRANCH_W + 2 * widen
	local pieces = {}
	for _, a in ipairs(BAY) do table.insert(pieces, strip(a, 21, 96.6, w, top, thick)) end      -- plaza -> bay open side
	table.insert(pieces, strip(180, 21, (RING_IN + RING_OUT) / 2, w, top, thick))               -- spawn avenue -> ring
	table.insert(pieces, strip(0, 21, 28.5, w, top, thick))                                     -- plaza -> snow yard
	table.insert(pieces, strip(141.67, (RING_IN + RING_OUT) / 2, 131, bw, top, thick))           -- ring -> Crafting
	table.insert(pieces, strip(218.33, (RING_IN + RING_OUT) / 2, 123.5, bw, top, thick))         -- ring -> arena portal
	table.insert(pieces, strip(251, (RING_IN + RING_OUT) / 2, 126.5, bw, top, thick))            -- ring -> Crystal Pavilion
	local base = ring(RING_IN - widen, RING_OUT + widen, RING_END - widen / ((RING_IN + RING_OUT) / 2) * 180 / math.pi, top, thick)
	base.Parent = workspace
	for _, p in ipairs(pieces) do p.Parent = workspace end
	local ok, u = pcall(function() return base:UnionAsync(pieces, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Precise) end)
	base:Destroy()
	for _, p in ipairs(pieces) do p:Destroy() end
	if not ok or not u then error(name .. " union failed: " .. tostring(u)) end
	u.Name = name; u.Anchored = true; u.CanCollide = false; u.CanQuery = false; u.CanTouch = false; u.CastShadow = false
	u.UsePartColor = true; u.Color = color; u.Material = material
	return u
end

local ice = layer("SpokeIceWalk", 0, ICE_TOP, ICE_T, ICE_COLOR, Enum.Material.Ice)
task.wait()
local snow = layer("SpokeSnowBorder", B, SNOW_TOP, SNOW_T, SNOW_COLOR, Enum.Material.Snow)
-- backup + swap
local bk = SS:FindFirstChild(BACKUP)
if not bk then
	bk = Instance.new("Folder"); bk.Name = BACKUP
	bk:SetAttribute("Note", "hub_paths.luau 2026-10-09 (outputs/HubOpen20261009). Removed = the old village ice walk; MODE undo swaps back.")
	local r = Instance.new("Folder"); r.Name = "Removed"; r.Parent = bk
	local b = Instance.new("Folder"); b.Name = "Built"; b.Parent = bk
	bk.Parent = SS
end
for _, n in ipairs({"ContinuousIceWalk", "ContinuousSnowBorder"}) do
	local old = walkways:FindFirstChild(n)
	if old then old.Parent = bk.Removed end
end
snow.Parent = walkways
ice.Parent = walkways
return string.format("built: %s (size %s), %s (size %s); old walk in %s.Removed", ice.Name, tostring(ice.Size), snow.Name, tostring(snow.Size), BACKUP)
