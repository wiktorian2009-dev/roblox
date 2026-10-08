-- place_frost.luau (Studio, Edit): Frostfall Village. The approved layout stays: machines, egg display, rebirth pavilion, snowglobe,
-- walkways, string lights, travel CFrameValues, garage, arena portal, spawn, mountain meshes and FrostfallLobbyDecor meshes are untouched.
-- Only the part-built props are swapped in place (same pivot/yaw, old collidable parts kept as invisible colliders, old lights copied),
-- and background landmarks are added outside the mountain ring.
local K = require(game.ServerStorage.W1RemasterKit:Clone())
local AREA = "Frostfall"
local V = workspace.FrostfallVillage
local log = {}
local function copyColliders(inst, name)
	local n = 0
	for _, p in ipairs(inst:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then K.collider(AREA, p.CFrame, p.Size, name); n += 1 end
	end
	return n
end
local function swap(old, newName, sub, extra)
	assert(not old:GetAttribute("VillageMotion"), "animated village item - leave it")
	local cf, s = old:GetBoundingBox()
	local piv = old:GetPivot()
	local _, yaw = piv:ToEulerAnglesYXZ()
	-- stand on the village ground (some old props were sunk below it); fall back to the old bbox bottom
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.GeneratedMap, V.Island}
	local hit = workspace:Raycast(Vector3.new(piv.X, 40, piv.Z), Vector3.new(0, -80, 0), rp)
	local base = CFrame.new(piv.X, hit and hit.Position.Y or (cf.Y - s.Y / 2), piv.Z) * CFrame.Angles(0, yaw, 0)
	local m = K.place(newName, base, AREA, extra and extra.scale, sub)
	local nc = copyColliders(old, newName .. "Collider")
	-- carry over lights (lanterns) onto the new glowing part
	for _, l in ipairs(old:GetDescendants()) do
		if l:IsA("PointLight") or l:IsA("SpotLight") then local g = m:FindFirstChild(extra and extra.glow or "WarmGlass") or m.PrimaryPart; l:Clone().Parent = g end
	end
	K.archive(old, AREA, "part-built village prop replaced in place by " .. newName .. " (" .. nc .. " colliders kept)")
	return m
end
local n = {}
for _, c in ipairs(V:GetChildren()) do
	if c.Name == "SnowPine" then swap(c, "F_Pine", "Pines", {scale = 1.0}); n.pine = (n.pine or 0) + 1
	elseif c.Name == "VillageLantern" then swap(c, "F_Lantern", "Lanterns", {scale = 0.93, glow = "WarmGlass"}); n.lantern = (n.lantern or 0) + 1
	elseif c.Name == "VillageBench" then swap(c, "F_Bench", "Benches"); n.bench = (n.bench or 0) + 1 end
end
table.insert(log, string.format("pines %d lanterns %d benches %d", n.pine or 0, n.lantern or 0, n.bench or 0))
-- warm light for lanterns that had none
for _, m in ipairs(K.scenery(AREA).Lanterns:GetChildren()) do
	local g = m:FindFirstChild("WarmGlass")
	if g and not g:FindFirstChildWhichIsA("PointLight") then local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 200, 120); l.Range = 12; l.Brightness = 0.9; l.Parent = g end
end
-- the Sept-30 scout props (non-collidable) -> Blender versions in the same spots
local sd = workspace.StageDecor20260930:FindFirstChild("Starter")
if sd then
	for _, pair in ipairs({{"SnowScoutCamp", "F_ScoutCamp"}, {"SnowTrailMarkers", "F_TrailSign"}, {"ExpeditionSled", "F_Sled"}}) do
		local old = sd:FindFirstChild(pair[1])
		if old then
			local m = swap(old, pair[2], "Scout", {glow = "LampGlow"})
			if pair[2] == "F_ScoutCamp" then
				local ember = m:FindFirstChild("Ember")
				if ember then
					local a = Instance.new("Attachment"); a.Position = Vector3.new(0, 0.8, 0); a.Parent = ember
					local e = Instance.new("ParticleEmitter"); e.Name = "Smoke"; e.Rate = 3; e.Lifetime = NumberRange.new(3, 4.5); e.Speed = NumberRange.new(1.5, 2.5)
					e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 3)})
					e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1)})
					e.Color = ColorSequence.new(Color3.fromRGB(225, 232, 240)); e.Acceleration = Vector3.new(0.4, 0.2, 0); e.Parent = a
					local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 150, 80); l.Range = 14; l.Brightness = 1.2; l.Parent = ember
				end
			end
			for _, d in ipairs(m:GetChildren()) do if d.Name == "LampGlow" and not d:FindFirstChildWhichIsA("PointLight") then local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 200, 120); l.Range = 10; l.Brightness = 0.8; l.Parent = d end end
		end
	end
end
-- background landmark: a lookout tower on the south peak (-134,-370) of the mountain ring (outside the ring is void, so no groves there);
-- the rock knoll sits over the peak tip (top 42.2)
local tower = K.place("F_Watchtower", CFrame.new(-133.6, 37.5, -370.4) * CFrame.Angles(0, math.rad(15), 0), AREA, 0.8, "Background")
local lan = tower:FindFirstChild("Lantern"); if lan then local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 200, 120); l.Range = 22; l.Brightness = 1.2; l.Parent = lan end
local pen = tower:FindFirstChild("Pennant"); if pen then pen:SetAttribute("StageDecorMotion", "Sway"); pen:SetAttribute("MotionAmount", 0.15); pen:SetAttribute("MotionSpeed", 2.0) end
table.insert(log, "instances " .. #K.scenery(AREA):GetDescendants())
return table.concat(log, "; ")
