-- after_apply.luau (2026-10-09, Claude): the two steps run in EDIT right after hub_ring.luau MODE "apply".
-- 1) Trim the ring's south-east end, which ran under the Starter Help Yard pad (x >= 0, z -182..-120): CSG-subtract the box
--    x > -4 / z > -200 from the three floor layers, remove the rim pieces standing in it, and close the cut with a straight
--    collider + snow balls along x = -4 (z -186.2 .. -151).
-- 2) Put the leaderboards (staged as ServerStorage.Leaderboards by ../Leaderboards20261009/build_boards.luau) into the ring's
--    west gap between Bay 1 and Bay 2, facing the lobby centre.
-- Undo: hub_ring.luau MODE "undo" moves workspace.HubRing (with these edits) into the backup; move workspace.Leaderboards back to
-- ServerStorage (or anywhere) yourself.
local ring = workspace.HubRing
local X_CUT, Z_MIN = -4, -200
local function inCut(p) return p.X > X_CUT - 0.5 and p.Z > Z_MIN end
for _, name in ipairs({"SnowFloor", "IceShelf", "RockBase"}) do
	local u = ring:FindFirstChild(name)
	local box = Instance.new("Part")
	box.Anchored = true; box.Transparency = 1
	box.Size = Vector3.new(400, 40, 400)
	box.CFrame = CFrame.new(X_CUT + 200, -5, Z_MIN + 200)
	box.Parent = workspace
	local nu = u:SubtractAsync({box}, Enum.CollisionFidelity.PreciseConvexDecomposition, Enum.RenderFidelity.Precise)
	box:Destroy()
	nu.Name = u.Name; nu.Anchored = true; nu.UsePartColor = true; nu.Color = u.Color; nu.Material = u.Material; nu.CanCollide = u.CanCollide
	nu.Parent = ring
	u:Destroy()
end
for _, f in ipairs({ring.SnowRim, ring.EdgeRocks, ring.Colliders}) do
	for _, p in ipairs(f:GetChildren()) do
		if p:IsA("BasePart") and inCut(p.Position) then p:Destroy() end
	end
end
local z0, z1 = -186.2, -151.0
local c = Instance.new("Part")
c.Name = "YardSide"; c.Anchored = true; c.Transparency = 1; c.CanCollide = true; c.CanTouch = false; c.CastShadow = false
c.Size = Vector3.new(2, 16, (z1 - z0) + 4); c.CFrame = CFrame.new(X_CUT + 1, 8.14, (z0 + z1) / 2)
c.Parent = ring.Colliders
local rng = Random.new(91009)
for z = z0 + 1, z1 - 1, 2.2 do
	local s = rng:NextNumber(1.7, 2.3)
	local b = Instance.new("Part")
	b.Name = "Snowball"; b.Shape = Enum.PartType.Ball; b.Size = Vector3.new(s, s, s); b.Anchored = true
	b.CFrame = CFrame.new(X_CUT - 0.6, 0.39, z); b.Color = Color3.fromRGB(243, 252, 255); b.Material = Enum.Material.SmoothPlastic
	b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.CastShadow = false
	b.Parent = ring.SnowRim
end

local lb = game:GetService("ServerStorage"):FindFirstChild("Leaderboards")
if lb then
	lb:PivotTo(CFrame.lookAt(Vector3.new(-236, 0.14, -282), Vector3.new(-100, 0.14, -282)))
	lb.Parent = workspace
end
return "done"
