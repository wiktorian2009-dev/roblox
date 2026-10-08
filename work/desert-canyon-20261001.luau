-- Desert canyon formations (Claude, 2026-10-01). Replaces the rejected scattered-prop pass (v7).
-- Run in Roblox Studio EDIT mode. Destroys and rebuilds ONLY Workspace.DesertCanyon20261001.
-- Style: Sandstone parts in the exact SandWall_A palette (base 194,112,61 / light 224,145,76 / dark strata 130,70,49 / sand 227,176,100).
-- Solid pieces (cores, shoulders, spire segments, bridge span, boulders) have vertical faces >= 16 studs and boulders <= 8 tall,
-- so with JumpHeight 7.2 nothing is climbable. Bands, caps, wedges and the wall rim are non-solid / non-query.
-- Layout: canyon gate (2 buttes + rock bridge over the entrance path at x~121), plaza hoodoo, 2 east-wall mesas on the field edge,
-- south hoodoo garden beside the oasis, south corner mesa, rim build-up standing on every SandWall_A MainCliff top.
local ws = workspace
local CHS = game:GetService("ChangeHistoryService")
local FOLDER = "DesertCanyon20261001"
local old = ws:FindFirstChild(FOLDER); if old then old:Destroy() end
local root = Instance.new("Folder"); root.Name = FOLDER
root:SetAttribute("Note", "Desert canyon formations (Claude 2026-10-01). Sandstone parts matching SandWall_A. Solid: cores/shoulders/spire segments/bridge span/boulders (faces >=16 studs, boulders <=8 tall, not climbable). Non-solid: bands, caps, wedges, rim. Delete this folder to remove.")
local C = {base = Color3.fromRGB(194, 112, 61), light = Color3.fromRGB(224, 145, 76), dark = Color3.fromRGB(130, 70, 49), sand = Color3.fromRGB(227, 176, 100)}
local rng = Random.new(20261001)
local GROUND = 3.5
local function jitter(c, a) local d = rng:NextNumber(-a, a) / 255; return Color3.new(math.clamp(c.R + d, 0, 1), math.clamp(c.G + d, 0, 1), math.clamp(c.B + d * 0.8, 0, 1)) end
local function addPart(m, name, shape, size, cf, color, solid, mat)
	local p
	if shape == "Wedge" then p = Instance.new("WedgePart") else
		p = Instance.new("Part")
		if shape == "Ball" then p.Shape = Enum.PartType.Ball end
	end
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = jitter(color, 5); p.Material = mat or Enum.Material.Sandstone
	p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false; p.CanCollide = solid; if not solid then p.CanQuery = false end
	p.Parent = m
	return p
end
local function boulders(m, base, hw, hd, count, avoid)
	for _ = 1, count do
		for _ = 1, 16 do
			local ang = rng:NextNumber(0, math.pi * 2)
			local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local wdir = base:VectorToWorldSpace(dir)
			local ok = true
			if avoid then for _, a in ipairs(avoid) do if wdir:Dot(a) > 0.35 then ok = false end end end
			if ok then
				local sy = rng:NextNumber(4, 8); local sx = rng:NextNumber(6, 11); local sz = rng:NextNumber(6, 11)
				addPart(m, "BaseRock", "Ball", Vector3.new(sx, sy, sz), base * CFrame.new(dir.X * (hw + sx * 0.15), sy * 0.32, dir.Z * (hd + sz * 0.15)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), C.base, true)
				break
			end
		end
	end
end
local function jaggedTop(m, cf, w, d, n)
	for _ = 1, n do
		local s = Vector3.new(rng:NextNumber(0.25, 0.45) * w, rng:NextNumber(5, 11), rng:NextNumber(0.35, 0.6) * d)
		addPart(m, "JaggedTop", "Wedge", s, cf * CFrame.new(rng:NextNumber(-0.3, 0.3) * w, s.Y / 2 - 0.5, rng:NextNumber(-0.25, 0.25) * d) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 90 + rng:NextNumber(-15, 15)), 0), C.light, false)
	end
end
local function sandSkirt(m, base, w, d) addPart(m, "SandSkirt", "Block", Vector3.new(w + 7, 1.2, d + 7), base * CFrame.new(0, 0.1, 0), C.sand, false, Enum.Material.Sand) end
local function butte(name, x, z, w, d, h, yaw, opt)
	opt = opt or {}
	local m = Instance.new("Model"); m.Name = name
	local base = CFrame.new(x, GROUND, z) * CFrame.Angles(0, math.rad(yaw), 0)
	addPart(m, "Core", "Block", Vector3.new(w, h, d), base * CFrame.new(0, h / 2 - 0.6, 0), C.base, true)
	local sh = math.max(18, h * 0.55); local sx = opt.shoulderSide or 1
	addPart(m, "Shoulder", "Block", Vector3.new(w * 0.5, sh, d * 0.82), base * CFrame.new(sx * w * 0.45, sh / 2 - 0.6, d * 0.12), C.base, true)
	addPart(m, "Strata", "Block", Vector3.new(w * 0.5 + 0.8, 2.0, d * 0.82 + 0.8), base * CFrame.new(sx * w * 0.45, sh * 0.55, d * 0.12), C.dark, false)
	addPart(m, "ShoulderTop", "Block", Vector3.new(w * 0.5 + 1.6, 2.2, d * 0.82 + 1.6), base * CFrame.new(sx * w * 0.45, sh - 0.2, d * 0.12), C.light, false)
	for _, b in ipairs({{0.30, C.dark, 2.4}, {0.55, C.light, 1.8}, {0.80, C.dark, 2.0}}) do
		addPart(m, "Strata", "Block", Vector3.new(w + 0.8, b[3], d + 0.8), base * CFrame.new(0, h * b[1], 0), b[2], false)
	end
	local cap = base * CFrame.new(0, h + 0.6, 0)
	addPart(m, "Cap", "Block", Vector3.new(w + 2.4, 3.0, d + 2.4), cap, C.light, false)
	jaggedTop(m, cap * CFrame.new(0, 1.5, 0), w, d, opt.wedges or 3)
	for _, sgn in ipairs({-1, 1}) do
		addPart(m, "UpperRock", "Ball", Vector3.new(rng:NextNumber(7, 11), rng:NextNumber(8, 13), rng:NextNumber(8, 12)), cap * CFrame.new(sgn * w * 0.32, 2, rng:NextNumber(-0.2, 0.2) * d), C.base, false)
	end
	boulders(m, base, w / 2, d / 2, opt.boulders or 5, opt.avoid)
	sandSkirt(m, base, w, d)
	m.Parent = root
	return m
end
local function spire(name, x, z, r, h, yaw, avoid)
	local m = Instance.new("Model"); m.Name = name
	local base = CFrame.new(x, GROUND, z) * CFrame.Angles(0, math.rad(yaw), 0)
	local h1 = math.max(18, h * 0.45); local h2 = h * 0.32; local h3 = h - h1 - h2
	addPart(m, "Seg1", "Block", Vector3.new(2 * r, h1, 1.8 * r), base * CFrame.new(0, h1 / 2 - 0.6, 0), C.base, true)
	addPart(m, "Band", "Block", Vector3.new(2 * r + 0.8, 2.2, 1.8 * r + 0.8), base * CFrame.new(0, h1 * 0.55, 0), C.dark, false)
	local c2 = base * CFrame.new(r * 0.12, h1 + h2 / 2 - 0.6, 0) * CFrame.Angles(0, math.rad(14), 0)
	addPart(m, "Seg2", "Block", Vector3.new(1.55 * r, h2, 1.45 * r), c2, C.light, true)
	addPart(m, "Band", "Block", Vector3.new(1.55 * r + 0.7, 1.8, 1.45 * r + 0.7), c2 * CFrame.new(0, -h2 * 0.15, 0), C.dark, false)
	local c3 = base * CFrame.new(-r * 0.1, h1 + h2 + h3 / 2 - 0.6, r * 0.05) * CFrame.Angles(0, math.rad(-12), 0)
	addPart(m, "Seg3", "Block", Vector3.new(1.15 * r, h3, 1.1 * r), c3, C.base, true)
	addPart(m, "CapRock", "Ball", Vector3.new(2.3 * r, 1.1 * r, 2.1 * r), base * CFrame.new(-r * 0.1, h - 0.6 + r * 0.35, 0) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0), C.dark, false)
	boulders(m, base, r, r * 0.9, 4, avoid)
	sandSkirt(m, base, 2 * r, 1.8 * r)
	m.Parent = root
	return m
end
local N_, S_, E_, W_ = Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0)
butte("GateButteN", 121, -303, 22, 16, 46, 3, {shoulderSide = 1, avoid = {S_, N_}})
butte("GateButteS", 121, -257, 22, 16, 42, -4, {shoulderSide = 1, avoid = {N_}})
do
	local m = Instance.new("Model"); m.Name = "GateBridge"
	local cf = CFrame.new(121, 38.5, -280)
	addPart(m, "Span", "Block", Vector3.new(14, 9, 44), cf, C.base, true)
	addPart(m, "Strata", "Block", Vector3.new(14.8, 2.0, 44.2), cf * CFrame.new(0, -1.5, 0), C.dark, false)
	addPart(m, "SpanTop", "Block", Vector3.new(16, 2.6, 40), cf * CFrame.new(0, 5.4, 0), C.light, false)
	jaggedTop(m, cf * CFrame.new(0, 6.5, 0), 14, 30, 3)
	for _, zz in ipairs({-9, 0, 9}) do
		addPart(m, "UnderRock", "Ball", Vector3.new(rng:NextNumber(8, 12), rng:NextNumber(4, 6), rng:NextNumber(7, 10)), cf * CFrame.new(rng:NextNumber(-2, 2), -4.6, zz), C.base, false)
	end
	m.Parent = root
end
spire("PlazaHoodoo", 146, -307, 4.5, 40, 8, {S_})
butte("EastPillarA", 258, -250, 12, 12, 30, 4, {shoulderSide = -1, boulders = 3, wedges = 2})
butte("EastMesaB", 257, -232, 14, 13, 34, -3, {shoulderSide = -1, boulders = 3, wedges = 2})
spire("SouthSpire", 163, -191, 5, 48, 10)
spire("SouthHoodoo2", 177, -197, 4, 34, -18)
butte("SouthCornerMesa", 189, -160, 12, 12, 30, -32, {shoulderSide = -1, boulders = 3, wedges = 2, avoid = {E_, S_}})
local rimFolder = Instance.new("Folder"); rimFolder.Name = "WallRim"
local CENTER = Vector3.new(190, 0, -250)
for _, w in ipairs(ws:GetChildren()) do
	if w.Name == "SandWall_A" and w:IsA("Model") then
		local cliff = w:FindFirstChild("MainCliff")
		if cliff then
			local bcf, bsize = w:GetBoundingBox()
			local peakTop = bcf.Y + bsize.Y / 2
			local cf = cliff.CFrame; local sz = cliff.Size
			local cliffTop = cf.Y + (math.abs(cf.UpVector.Y) * sz.Y) / 2
			local toC = (CENTER - cf.Position) * Vector3.new(1, 0, 1)
			local outward = toC:Dot(cf.LookVector) >= 0 and 1 or -1
			local flat = CFrame.new(cf.Position) * CFrame.fromMatrix(Vector3.zero, Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit, Vector3.yAxis)
			local m = Instance.new("Model"); m.Name = "Rim"
			local L = sz.X; local n = L > 44 and 3 or 2
			for k = 1, n do
				local lx = (-L / 2 + 6) + (k - 0.5) * ((L - 12) / n) + rng:NextNumber(-2.5, 2.5)
				local rise = rng:NextNumber(8, 17)
				local tall = (k == 2 and rng:NextNumber() < 0.4)
				local bw, bd = rng:NextNumber(10, 15), rng:NextNumber(8, 10.5)
				if tall then rise = rng:NextNumber(20, 28); bw = bw * 0.7 end
				local bottom = cliffTop - 1
				local bh = (peakTop - bottom) + rise
				local pc = flat * CFrame.new(lx, 0, outward * rng:NextNumber(1, 2.5))
				pc = CFrame.new(pc.X, bottom + bh / 2, pc.Z) * pc.Rotation * CFrame.Angles(0, math.rad(rng:NextNumber(-7, 7)), 0)
				addPart(m, "RimRock", "Block", Vector3.new(bw, bh, bd), pc, C.base, false)
				addPart(m, "RimStrata", "Block", Vector3.new(bw + 0.6, 1.8, bd + 0.6), CFrame.new(pc.X, peakTop + rise * 0.35, pc.Z) * pc.Rotation, C.dark, false)
				local capc = CFrame.new(pc.X, bottom + bh + 0.8, pc.Z) * pc.Rotation
				addPart(m, "RimCap", "Block", Vector3.new(bw + 1.6, 2.2, bd + 1.6), capc, C.light, false)
				for _ = 1, (tall and 1 or 2) do
					local s = Vector3.new(rng:NextNumber(0.25, 0.45) * bw, rng:NextNumber(4, 9), rng:NextNumber(0.35, 0.6) * bd)
					addPart(m, "JaggedTop", "Wedge", s, capc * CFrame.new(rng:NextNumber(-0.3, 0.3) * bw, s.Y / 2 + 0.6, rng:NextNumber(-0.2, 0.2) * bd) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 90), 0), C.light, false)
				end
			end
			m.Parent = rimFolder
		end
	end
end
rimFolder.Parent = root
root.Parent = ws
pcall(function() CHS:SetWaypoint("After desert canyon v2") end)
local total = 0; for _, d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then total += 1 end end
return "built " .. FOLDER .. " with " .. total .. " parts"
