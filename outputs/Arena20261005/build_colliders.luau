-- build_colliders.luau (Studio, Edit): Snowplow Bumper Arena collision layout (simple, deliberate collision geometry).
-- Re-runnable: rebuilds workspace.SnowplowArena.Colliders / Barriers / Markers only (visual Blender models live in .Art).
local RS = game:GetService("ReplicatedStorage")
local A = require(RS.ArenaConfig)
local root = workspace:FindFirstChild("SnowplowArena") or Instance.new("Model")
root.Name = "SnowplowArena"; root.Parent = workspace
for _, n in ipairs({"Colliders", "Barriers", "Markers"}) do local f = root:FindFirstChild(n); if f then f:Destroy() end end
local col = Instance.new("Folder"); col.Name = "Colliders"; col.Parent = root
local bar = Instance.new("Folder"); bar.Name = "Barriers"; bar.Parent = root
local mk = Instance.new("Folder"); mk.Name = "Markers"; mk.Parent = root
local ICE, SNOW, WALL = Color3.fromRGB(200, 232, 255), Color3.fromRGB(246, 250, 255), Color3.fromRGB(90, 150, 230)

local function part(parent, name, size, cf, props)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic; p.Color = SNOW
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent
	return p
end
local function disc(parent, name, center, r, h, props)
	-- vertical cylinder whose TOP is at center.Y
	return part(parent, name, Vector3.new(h, r * 2, r * 2), CFrame.new(center - Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		(function() local t = props or {}; t.Shape = Enum.PartType.Cylinder; return t end)())
end
local function inGap(deg, gaps, halfDeg)
	for _, g in ipairs(gaps) do
		local d = math.abs(((deg - g) + 180) % 360 - 180)
		if d < halfDeg then return true end
	end
	return false
end
local function ring(parent, name, center, r0, r1, y0, y1, stepDeg, gaps, gapHalfDeg, props)
	local rm = (r0 + r1) / 2
	local n = 0
	for a = stepDeg / 2, 360, stepDeg do
		local lo, hi = a - stepDeg / 2, a + stepDeg / 2
		if not (inGap(lo + 0.01, gaps, gapHalfDeg) or inGap(hi - 0.01, gaps, gapHalfDeg) or inGap(a, gaps, gapHalfDeg)) then
			local rad = math.rad(a)
			local len = 2 * r1 * math.tan(math.rad(stepDeg / 2)) + 0.2
			local p = center + Vector3.new(math.cos(rad) * rm, (y0 + y1) / 2, math.sin(rad) * rm)
			local cf = CFrame.lookAt(p, Vector3.new(center.X, p.Y, center.Z))
			n += 1
			part(parent, name .. "_" .. n, Vector3.new(len, y1 - y0, r1 - r0), cf, props)
		end
	end
	return n
end

local C0, PR = A.Center, A.Practice
-- main fighting floor (top at C0.Y) - reaches 2 studs past the exit line, then the island edge drops away
disc(col, "ArenaFloor", C0, A.OutRadius + 2, 4, {Color = ICE, Material = Enum.Material.Ice})
-- bumper wall ring with 4 exit gaps (ExitWidth at the wall line)
local gapHalf = math.deg(math.asin((A.ExitWidth / 2) / (A.WallInner + 1.5)))
ring(col, "BumperWall", C0, A.WallInner, A.WallInner + 3, 0, 4.2, 6, A.Exits, gapHalf, {Color = WALL})
-- exit posts (warning colours) either side of every gap
for _, g in ipairs(A.Exits) do
	for _, s in ipairs({-1, 1}) do
		local rad = math.rad(g + s * gapHalf)
		local p = C0 + Vector3.new(math.cos(rad), 0, math.sin(rad)) * (A.WallInner + 1.5)
		part(col, "ExitPost", Vector3.new(3.2, 6, 3.2), CFrame.new(p + Vector3.new(0, 3, 0)), {Color = Color3.fromRGB(255, 200, 40)})
	end
	local rad = math.rad(g)
	local mp = C0 + Vector3.new(math.cos(rad), 0, math.sin(rad)) * (A.WallInner + 1.5)
	local m = part(mk, "Exit_" .. g, Vector3.new(1, 1, 1), CFrame.lookAt(mp, Vector3.new(C0.X, mp.Y, C0.Z)), {Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false})
	m:SetAttribute("ArenaExit", g)
end
-- spawn pad markers
for i = 1, #A.PadAngles do
	local cf = A.PadCFrame(i)
	local m = part(mk, "Pad_" .. i, Vector3.new(1, 1, 1), cf, {Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false})
	m:SetAttribute("ArenaPad", i)
end
-- practice ring
disc(col, "PracticeFloor", PR.Center, PR.OutRadius + 2, 4, {Color = ICE, Material = Enum.Material.Ice})
local pgap = math.deg(math.asin((PR.ExitWidth / 2) / (PR.Radius + 1)))
ring(col, "PracticeWall", PR.Center, PR.Radius, PR.Radius + 2, 0, 3.6, 10, {PR.Exit}, pgap, {Color = WALL})
-- arrival plaza + walkway to the stands (spectators)
local plazaTop = A.Plaza.Y
part(col, "PlazaFloor", Vector3.new(70, 4, 40), CFrame.new(A.Plaza - Vector3.new(0, 2, 0)), {Color = SNOW})
local arrival = part(mk, "Arrival", Vector3.new(1, 1, 1), CFrame.lookAt(A.Plaza + Vector3.new(0, 3, 6), A.Center + Vector3.new(0, 3, 0)), {Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false})
-- walkway straight north from the plaza, then a ramp up into the south stands
local wx = C0.X
local sIn, sOut = A.OutRadius + 4, A.OutRadius + 26 -- stands inner / outer radius
local rampLen = 24
local walkEnd = C0.Z - sOut - rampLen
part(col, "Walkway", Vector3.new(14, 4, walkEnd - (A.Plaza.Z + 20)), CFrame.new(Vector3.new(wx, plazaTop - 2, (walkEnd + A.Plaza.Z + 20) / 2)), {Color = SNOW})
local rampAng = math.atan2(5, rampLen)
part(col, "StandsRamp", Vector3.new(14, 1, math.sqrt(rampLen ^ 2 + 25) + 0.6),
	CFrame.new(Vector3.new(wx, plazaTop + 2.5 - 0.5, walkEnd + rampLen / 2)) * CFrame.Angles(-rampAng, 0, 0), {Color = SNOW})
-- stands: raised ring (top 5 above the floor) outside the barrier, open at the exits (spectators can't reach the floor)
ring(col, "Stands", C0, sIn, A.OutRadius + 26, -4, 5, 6, A.Exits, gapHalf + 6, {Color = Color3.fromRGB(235, 242, 252)})
-- spectator barrier: tall invisible ring (stops people, never vehicles - collision group ArenaWalkBlock)
ring(bar, "SpectatorBarrier", C0, A.OutRadius + 3, A.OutRadius + 4, 0, 14, 6, {}, 0, {Transparency = 1, CollisionGroup = "ArenaWalkBlock"})
ring(bar, "PracticeBarrier", PR.Center, PR.OutRadius + 1, PR.OutRadius + 2, 0, 10, 10, {}, 0, {Transparency = 1, CollisionGroup = "ArenaWalkBlock"})
-- hidden box for knocked-out drivers (anchored under the island while their vehicle respawns)
part(mk, "RespawnBox", Vector3.new(4, 1, 4), CFrame.new(C0 + Vector3.new(0, -40, 0)), {Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false})
return "ok"
