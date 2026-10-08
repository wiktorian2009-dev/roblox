-- Desert biome 3D-prop placement (Claude, 2026-10-01). Final layout = Version 7, seed 20260930.
-- Run in Roblox Studio EDIT mode (execute_luau / command bar). Needs Workspace.PropsLibrary2026.DesertProps.
-- DRY = true only simulates and prints counts. Set DRY = false to build: it destroys and recreates ONLY
-- Workspace.DesertProps20260930 (its own folder) and sets undo waypoints. It never touches walls, gates,
-- fields, existing decor, scripts, the library or the Frostfall lobby. Props are Anchored with
-- CanCollide/CanQuery/CanTouch = false (same precedent as StageDecor20260930).
-- Method: 2-stud grid from live raycasts / overlap queries; interior by flood fill from the field middle;
-- existing decor (including CanQuery=false parts) rasterised from part bounding boxes; wall/gate distance fields.
-- Tweak: SEED, TYPES caps and scale ranges, FIELD_CORE, LANDMARKS regions, ROUNDS, PLAZA.
local DRY = true
local SEED = 20260930
local ws = game:GetService("Workspace")
local CHS = game:GetService("ChangeHistoryService")
local X0, X1, Z0, Z1, S = 88, 292, -360, -144, 2
local COLS = math.floor((X1 - X0) / S) + 1
local ROWS = math.floor((Z1 - Z0) / S) + 1
local N = COLS * ROWS
local function idx(c, r) return r * COLS + c + 1 end
local function toCell(x, z) return math.floor((x - X0) / S + 0.5), math.floor((z - Z0) / S + 0.5) end
local out = {}
local function log(s) out[#out + 1] = s end
local CENTER = Vector3.new(190, 0, -250)
local old = ws:FindFirstChild("DesertProps20260930"); if old and not DRY then old:Destroy() end
local lib = ws.PropsLibrary2026.DesertProps

local groundParts, walls, gates = {}, {}, {}
for _, ch in ipairs(ws:GetChildren()) do
	if ch.Name == "GeneratedMap" then
		local st = ch:FindFirstChild("Stages")
		if st then for _, d in ipairs(st:GetDescendants()) do if d:IsA("BasePart") then groundParts[#groundParts + 1] = d end end end
	elseif ch.Name == "SandWall_A" and ch:IsA("Model") then
		for _, d in ipairs(ch:GetDescendants()) do if d:IsA("BasePart") then walls[#walls + 1] = d end end
	elseif ch.Name == "StagePaywall_Model" then
		for _, d in ipairs(ch:GetDescendants()) do if d:IsA("BasePart") then gates[#gates + 1] = d end end
	end
end
local ignore = {}
for _, t in ipairs({groundParts, walls, gates}) do for _, p in ipairs(t) do ignore[p] = true end end
local ignoreRoots = {ws.SnowFieldZones, ws.PropsLibrary2026}
local function inc(list) local p = OverlapParams.new(); p.FilterType = Enum.RaycastFilterType.Include; p.FilterDescendantsInstances = list; return p end
local opW, opG = inc(walls), inc(gates)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = groundParts
local ground, gy = table.create(N, false), table.create(N, 0)
local wallC, gateC, decorC, fieldC = table.create(N, false), table.create(N, false), table.create(N, false), table.create(N, false)
for r = 0, ROWS - 1 do
	for c = 0, COLS - 1 do
		local i = idx(c, r); local x, z = X0 + c * S, Z0 + r * S
		local hit = ws:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), rp)
		if hit and hit.Normal.Y > 0.7 then
			ground[i] = true; gy[i] = hit.Position.Y
			local box = CFrame.new(x, 18, z)
			if #ws:GetPartBoundsInBox(box, Vector3.new(S, 26, S), opW) > 0 then wallC[i] = true end
			if #ws:GetPartBoundsInBox(box, Vector3.new(S, 26, S), opG) > 0 then gateC[i] = true end
		end
	end
end
local decorList = {}
for _, d in ipairs(ws:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsA("Terrain") and not ignore[d] then
		local cf, sz = d.CFrame, d.Size * 0.5
		local rx, uy, lz = cf.RightVector, cf.UpVector, cf.LookVector
		local hx = math.abs(rx.X) * sz.X + math.abs(uy.X) * sz.Y + math.abs(lz.X) * sz.Z
		local hy = math.abs(rx.Y) * sz.X + math.abs(uy.Y) * sz.Y + math.abs(lz.Y) * sz.Z
		local hz = math.abs(rx.Z) * sz.X + math.abs(uy.Z) * sz.Y + math.abs(lz.Z) * sz.Z
		local p = cf.Position
		if p.X + hx > X0 - 6 and p.X - hx < X1 + 6 and p.Z + hz > Z0 - 6 and p.Z - hz < Z1 + 6 and p.Y - hy < 32 and p.Y + hy > 3 then
			local skip = false
			for _, root in ipairs(ignoreRoots) do if d:IsDescendantOf(root) then skip = true; break end end
			if not skip and not (hy * 2 < 1.2 and p.Y + hy < 6.5) and not (d.Transparency >= 0.98 and not d.CanCollide) then
				decorList[#decorList + 1] = {x0 = p.X - hx, x1 = p.X + hx, z0 = p.Z - hz, z1 = p.Z + hz}
			end
		end
	end
end
local DECOR_PAD = 1.2
for _, o in ipairs(decorList) do
	local c0, r0 = toCell(o.x0 - DECOR_PAD, o.z0 - DECOR_PAD); local c1, r1 = toCell(o.x1 + DECOR_PAD, o.z1 + DECOR_PAD)
	for r = math.max(r0, 0), math.min(r1, ROWS - 1) do for c = math.max(c0, 0), math.min(c1, COLS - 1) do decorC[idx(c, r)] = true end end
end
for _, f in ipairs({ws.SnowFieldZones.Desert_1, ws.SnowFieldZones.Desert_2}) do
	for r = 0, ROWS - 1 do for c = 0, COLS - 1 do
		if math.abs(X0 + c * S - f.Position.X) <= f.Size.X / 2 and math.abs(Z0 + r * S - f.Position.Z) <= f.Size.Z / 2 then fieldC[idx(c, r)] = true end
	end end
end
local blocked = table.create(N, false)
for i = 1, N do blocked[i] = (not ground[i]) or wallC[i] or gateC[i] or decorC[i] end
local function dtransform(src)
	local d = table.create(N, 1e9)
	for i = 1, N do if src[i] then d[i] = 0 end end
	local W2 = 1.41421356
	for r = 0, ROWS - 1 do for c = 0, COLS - 1 do
		local i = r * COLS + c + 1; local v = d[i]
		if c > 0 then local a = d[i - 1] + 1; if a < v then v = a end end
		if r > 0 then
			local a = d[i - COLS] + 1; if a < v then v = a end
			if c > 0 then a = d[i - COLS - 1] + W2; if a < v then v = a end end
			if c < COLS - 1 then a = d[i - COLS + 1] + W2; if a < v then v = a end end
		end
		d[i] = v
	end end
	for r = ROWS - 1, 0, -1 do for c = COLS - 1, 0, -1 do
		local i = r * COLS + c + 1; local v = d[i]
		if c < COLS - 1 then local a = d[i + 1] + 1; if a < v then v = a end end
		if r < ROWS - 1 then
			local a = d[i + COLS] + 1; if a < v then v = a end
			if c < COLS - 1 then a = d[i + COLS + 1] + W2; if a < v then v = a end end
			if c > 0 then a = d[i + COLS - 1] + W2; if a < v then v = a end end
		end
		d[i] = v
	end end
	for i = 1, N do d[i] = d[i] * S end
	return d
end
local wallD, gateD = dtransform(wallC), dtransform(gateC)
local inside = table.create(N, false)
local sc, sr = toCell(190, -250)
local found = false
for rad = 0, 25 do
	for dr = -rad, rad do for dc = -rad, rad do
		local c, r = sc + dc, sr + dr
		if c >= 0 and c < COLS and r >= 0 and r < ROWS and not blocked[idx(c, r)] then sc, sr = c, r; found = true; break end
	end if found then break end end
	if found then break end
end
local q, head = {idx(sc, sr)}, 1
inside[q[1]] = true
while head <= #q do
	local i = q[head]; head += 1
	local c, r = (i - 1) % COLS, (i - 1) // COLS
	if c + 1 < COLS then local j = i + 1; if not inside[j] and not blocked[j] then inside[j] = true; q[#q + 1] = j end end
	if c > 0 then local j = i - 1; if not inside[j] and not blocked[j] then inside[j] = true; q[#q + 1] = j end end
	if r + 1 < ROWS then local j = i + COLS; if not inside[j] and not blocked[j] then inside[j] = true; q[#q + 1] = j end end
	if r > 0 then local j = i - COLS; if not inside[j] and not blocked[j] then inside[j] = true; q[#q + 1] = j end end
end
local insideCells = {}
local NSEC = 12
local sectorCells = {}; for s = 1, NSEC do sectorCells[s] = {} end
for i = 1, N do
	if inside[i] then
		insideCells[#insideCells + 1] = i
		if wallD[i] <= 17 then
			local c, r = (i - 1) % COLS, (i - 1) // COLS
			local ang = math.atan2((Z0 + r * S) - CENTER.Z, (X0 + c * S) - CENTER.X)
			local s = math.min(NSEC, math.floor((ang + math.pi) / (2 * math.pi) * NSEC) + 1)
			table.insert(sectorCells[s], i)
		end
	end
end

local rng = Random.new(SEED)
-- rb = ground blocking radius, rv = visual radius, wf = wall clearance as a fraction of rv, cap = max count
local TYPES = {
	RockStack = {rb = 3.4, rv = 4.0, wf = 0.2, wallOK = true, tris = 440, cap = 60},
	Saguaro = {rb = 1.8, rv = 3.4, wf = 0.9, face = true, tris = 1342, cap = 28},
	BarrelCactus = {rb = 2.8, rv = 3.0, wf = 0.95, face = true, tris = 1474, cap = 18},
	PalmTree = {rb = 2.0, rv = 5.5, wf = 0.75, face = true, tilt = true, tris = 2260, cap = 15},
	SandstoneArch = {rb = 5.5, rv = 7.0, wf = 0.85, face = true, tris = 780, cap = 4},
	StepPyramid = {rb = 6.0, rv = 7.0, wf = 0.95, face = true, tris = 486, cap = 3},
	ClayVase = {rb = 2.4, rv = 2.6, wf = 0.95, tris = 836, cap = 6},
	Tumbleweed = {rb = 1.9, rv = 2.0, wf = 0.95, tris = 2760, cap = 6},
	Agave = {rb = 2.2, rv = 5.5, wf = 0.45, tris = 1364, cap = 26},
}
local FIELD_CORE = 16 -- inside a snow field, props must stay within this many studs of a wall
local occ, placed, counts = table.create(N, false), {}, {}
local function reserved(x, z) return x < 104 or (x < 160 and math.abs(z + 280) < 11) end
local function footprintFree(x, z, rad, minWall, allowWall, gateNeed)
	if reserved(x, z) then return false end
	local cc, rr = toCell(x, z)
	if cc < 0 or rr < 0 or cc >= COLS or rr >= ROWS then return false end
	local ci = idx(cc, rr)
	if not inside[ci] or wallD[ci] < minWall or gateD[ci] < gateNeed then return false end
	if fieldC[ci] and wallD[ci] > FIELD_CORE then return false end
	local c0, r0 = toCell(x - rad, z - rad); local c1, r1 = toCell(x + rad, z + rad)
	if c0 < 0 or r0 < 0 or c1 >= COLS or r1 >= ROWS then return false end
	local fx, fz = (x - X0) / S, (z - Z0) / S; local rr2 = (rad / S) ^ 2
	for r = r0, r1 do for c = c0, c1 do
		local dc, dr = c - fx, r - fz
		if dc * dc + dr * dr <= rr2 then
			local i = idx(c, r)
			if occ[i] or gateC[i] then return false end
			if not inside[i] and not (allowWall and (wallC[i] or (ground[i] and not decorC[i]))) then return false end
		end
	end end
	return true
end
local function occupy(x, z, rad)
	local c0, r0 = toCell(x - rad, z - rad); local c1, r1 = toCell(x + rad, z + rad)
	local fx, fz = (x - X0) / S, (z - Z0) / S; local rr2 = (rad / S) ^ 2
	for r = math.max(r0, 0), math.min(r1, ROWS - 1) do for c = math.max(c0, 0), math.min(c1, COLS - 1) do
		local dc, dr = c - fx, r - fz
		if dc * dc + dr * dr <= rr2 then occ[idx(c, r)] = true end
	end end
end
local function put(tname, k, x, z)
	local T = TYPES[tname]
	if (counts[tname] or 0) >= T.cap then return false end
	local rad = T.rb * k
	if not footprintFree(x, z, rad, T.rv * k * T.wf, T.wallOK, 9 + 0.3 * T.rv * k) then return false end
	local cc, rr = toCell(x, z)
	local yaw, tilt = nil, 0
	if T.face then local _, y = CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(CENTER.X, 0, CENTER.Z)):ToOrientation(); yaw = y + math.rad(rng:NextNumber(-25, 25))
	else yaw = rng:NextNumber(0, math.pi * 2) end
	if T.tilt then tilt = math.rad(rng:NextNumber(8, 14)) end
	placed[#placed + 1] = {type = tname, k = k, x = x, z = z, y = gy[idx(cc, rr)], yaw = yaw, tilt = tilt}
	counts[tname] = (counts[tname] or 0) + 1
	occupy(x, z, rad * 1.05)
	return true
end
do local hx, hz, k = 116, -280, 2.6; local cc, rr = toCell(hx, hz) -- hero arch framing the entrance path
	placed[#placed + 1] = {type = "SandstoneArch", k = k, x = hx, z = hz, y = gy[idx(cc, rr)], yaw = math.rad(90), tilt = 0, hero = true}; counts.SandstoneArch = 1
	for _, sgn in ipairs({-1, 1}) do occupy(hx, hz + sgn * 4.4 * k, 4.4 * k * 0.9) end end
local THEMES = {
	Rocks = {extra = 9, anchor = {"RockStack", 1.8, 2.6}, sats = {{"RockStack", 1.3, 2.0, 3}, {"Agave", 1.0, 1.5, 1}, {"Saguaro", 1.3, 1.8, 1}}},
	Cactus = {extra = 9, anchor = {"Saguaro", 1.9, 2.6}, sats = {{"Saguaro", 1.3, 2.0, 2}, {"BarrelCactus", 1.3, 2.0, 2}, {"RockStack", 1.4, 2.1, 2}, {"Agave", 1.0, 1.4, 1}}},
	Palms = {extra = 9, anchor = {"PalmTree", 1.4, 2.0}, sats = {{"PalmTree", 1.1, 1.6, 2}, {"BarrelCactus", 1.2, 1.8, 1}, {"ClayVase", 1.4, 2.0, 1}, {"RockStack", 1.4, 2.0, 2}}},
	Ruins = {anchor = {"StepPyramid", 1.8, 2.4}, sats = {{"ClayVase", 1.5, 2.2, 1}, {"RockStack", 1.6, 2.4, 3}, {"Agave", 1.0, 1.4, 1}, {"Saguaro", 1.2, 1.7, 1}}},
	Gateway = {anchor = {"SandstoneArch", 2.0, 2.6}, sats = {{"RockStack", 1.8, 2.6, 3}, {"Saguaro", 1.4, 1.9, 1}, {"Agave", 1.0, 1.4, 1}}},
}
local centers, themeCount = {}, {}
local function far(x, z, sp) for _, c in ipairs(centers) do if (c[1] - x) ^ 2 + (c[2] - z) ^ 2 < sp ^ 2 then return false end end return true end
local function buildCluster(theme, x, z, k)
	local T = THEMES[theme]; local aT = TYPES[T.anchor[1]]; local rad = aT.rb * k
	if not put(T.anchor[1], k, x, z) then return false end
	centers[#centers + 1] = {x, z}; themeCount[theme] = (themeCount[theme] or 0) + 1
	for _, sat in ipairs(T.sats) do for _ = 1, sat[4] do for _ = 1, 24 do
		local ang = rng:NextNumber(0, math.pi * 2); local sT = TYPES[sat[1]]; local sk = rng:NextNumber(sat[2], sat[3])
		local dist = rad + sT.rb * sk * 0.9 + rng:NextNumber(0, 3.5)
		if put(sat[1], sk, x + math.cos(ang) * dist, z + math.sin(ang) * dist) then break end
	end end end
	return true
end
-- landmark pass: ziggurats + a second arch on open ground (plaza flanks, south yard), not on the fields
local LANDMARKS = {
	{"Ruins", 108, 156, -318, -296}, {"Ruins", 108, 156, -266, -242}, {"Gateway", 150, 214, -198, -150}, {"Ruins", 150, 214, -198, -150},
}
local lmDone = {}
for _, lm in ipairs(LANDMARKS) do
	for _ = 1, 400 do
		local x = X0 + 2 * math.floor((lm[2] - X0) / 2 + rng:NextNumber(0, (lm[3] - lm[2]) / 2))
		local z = Z0 + 2 * math.floor((lm[4] - Z0) / 2 + rng:NextNumber(0, (lm[5] - lm[4]) / 2))
		if far(x, z, 24) and buildCluster(lm[1], x, z, rng:NextNumber(THEMES[lm[1]].anchor[2], THEMES[lm[1]].anchor[3])) then lmDone[#lmDone + 1] = lm[1] .. string.format("(%.0f,%.0f)", x, z); break end
	end
end
-- wall clusters (rocks / cactus groves / palm groves)
local bag = {"Rocks", "Cactus", "Rocks", "Palms", "Rocks", "Cactus", "Rocks", "Palms", "Cactus", "Rocks"}
local clusters, attempts = 0, 0
while clusters < 40 and attempts < 16000 do
	attempts += 1
	local theme = bag[((clusters + attempts // 350) % #bag) + 1]
	local T = THEMES[theme]; local aT = TYPES[T.anchor[1]]
	local k = rng:NextNumber(T.anchor[2], T.anchor[3]); local minW = aT.rv * k * aT.wf
	local i = insideCells[rng:NextInteger(1, #insideCells)]
	if wallD[i] >= minW and wallD[i] <= minW + T.extra then
		local c, r = (i - 1) % COLS, (i - 1) // COLS; local x, z = X0 + c * S, Z0 + r * S
		if far(x, z, 12) and buildCluster(theme, x, z, k) then clusters += 1 end
	end
end
-- sector sweep: two rounds (big props, then small), round-robin around the whole wall so every stretch gets coverage
local ROUNDS = {
	{name = "big", per = 5, bag = {{"PalmTree", 1.1, 1.7, 2}, {"Saguaro", 1.5, 2.2, 4}, {"RockStack", 1.6, 2.6, 4}, {"BarrelCactus", 1.3, 2.0, 2}}},
	{name = "small", per = 6, bag = {{"Agave", 0.9, 1.4, 3}, {"RockStack", 1.2, 1.9, 4}, {"BarrelCactus", 1.2, 1.6, 2}, {"ClayVase", 1.3, 1.8, 1}, {"Tumbleweed", 1.0, 1.3, 1}}},
}
local filled, secCount = 0, {}
for s = 1, NSEC do secCount[s] = 0 end
for _, rd in ipairs(ROUNDS) do
	local rbag = {}; for _, f in ipairs(rd.bag) do for _ = 1, f[4] do rbag[#rbag + 1] = f end end
	for s = 1, NSEC do
		local cells = sectorCells[s]; local got = 0
		for _ = 1, 500 do
			if got >= rd.per or #cells == 0 then break end
			local i = cells[rng:NextInteger(1, #cells)]
			local c, r = (i - 1) % COLS, (i - 1) // COLS; local f = rbag[rng:NextInteger(1, #rbag)]
			if put(f[1], rng:NextNumber(f[2], f[3]), X0 + c * S, Z0 + r * S) then got += 1; filled += 1; secCount[s] += 1 end
		end
	end
end
-- plaza pass: heavy masses flanking the entrance path (the path itself stays clear)
local PLAZA = {{"RockStack", 1.7, 2.7, 8}, {"Saguaro", 1.6, 2.4, 3}, {"PalmTree", 1.3, 1.8, 2}, {"BarrelCactus", 1.3, 2.0, 2}, {"Agave", 1.0, 1.6, 2}, {"ClayVase", 1.5, 2.2, 1}}
local plazaBag = {}; for _, f in ipairs(PLAZA) do for _ = 1, f[4] do plazaBag[#plazaBag + 1] = f end end
local plaza, pt = 0, 0
while plaza < 30 and pt < 9000 do
	pt += 1
	local x = X0 + 2 * rng:NextInteger(9, 35)
	local z = Z0 + 2 * rng:NextInteger(22, 58)
	if math.abs(z + 280) >= 14 then
		local f = plazaBag[rng:NextInteger(1, #plazaBag)]
		if put(f[1], rng:NextNumber(f[2], f[3]), x, z) then plaza += 1 end
	end
end
-- a few loose accents, off the snow fields
local accents, aTries = 0, 0
local accentTypes = {{"Tumbleweed", 1.0, 1.5}, {"Agave", 0.9, 1.3}, {"RockStack", 1.4, 2.2}, {"BarrelCactus", 1.0, 1.5}}
while accents < 6 and aTries < 3000 do
	aTries += 1
	local i = insideCells[rng:NextInteger(1, #insideCells)]
	if not fieldC[i] and wallD[i] >= 14 and wallD[i] <= 70 then
		local c, r = (i - 1) % COLS, (i - 1) // COLS; local x, z = X0 + c * S, Z0 + r * S; local a = accentTypes[rng:NextInteger(1, #accentTypes)]
		if far(x, z, 14) and put(a[1], rng:NextNumber(a[2], a[3]), x, z) then accents += 1; centers[#centers + 1] = {x, z} end
	end
end
local byType, tris, nField, nWall = {}, 0, 0, 0
for _, p in ipairs(placed) do
	byType[p.type] = (byType[p.type] or 0) + 1; tris += TYPES[p.type].tris
	local cc, rr = toCell(p.x, p.z); local i = idx(cc, rr)
	if fieldC[i] then nField += 1 end; if wallD[i] <= 17 then nWall += 1 end
end
local parts = {}; for t, n in pairs(byType) do parts[#parts + 1] = t .. "=" .. n end; table.sort(parts)
log(string.format("PLACED %d props (%d wall clusters, %d sweep, %d plaza, %d accents, hero arch + landmarks: %s) | %s", #placed, clusters, filled, plaza, accents, table.concat(lmDone, " "), table.concat(parts, " ")))
log(string.format("est. triangles %d | on snow fields %d | within 17 studs of a wall %d | sweep per 30-degree sector: %s", tris, nField, nWall, table.concat(secCount, ",")))
if not DRY then
	pcall(function() CHS:SetWaypoint("Before desert props v7") end)
	local folder = Instance.new("Folder"); folder.Name = "DesertProps20260930"
	folder:SetAttribute("PropSet", "Desert"); folder:SetAttribute("Seed", SEED); folder:SetAttribute("Version", 7)
	folder:SetAttribute("Note", "Clones of PropsLibrary2026.DesertProps, non-colliding/non-query like StageDecor20260930. Delete this folder to remove them.")
	local made = 0
	for _, p in ipairs(placed) do
		local src = lib[p.type]; local c = src:Clone()
		c.Size = src.Size * p.k
		local po = src.PivotOffset; local spo = CFrame.new(po.Position * p.k) * po.Rotation
		c.PivotOffset = spo
		c.CFrame = (CFrame.new(p.x, p.y - 0.15, p.z) * CFrame.Angles(0, p.yaw, 0) * CFrame.Angles(-p.tilt, 0, 0)) * spo:Inverse()
		c.Anchored = true; c.CanCollide = false; c.CanQuery = false; c.CanTouch = false
		c.Name = p.type; c.Parent = folder; made += 1
	end
	folder.Parent = ws
	pcall(function() CHS:SetWaypoint("After desert props v7") end)
	log("BUILT " .. made .. " MeshParts into Workspace.DesertProps20260930 (v7)")
end
return table.concat(out, "\n")
