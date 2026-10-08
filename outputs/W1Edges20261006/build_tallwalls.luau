-- build_tallwalls.luau (2026-10-06, Claude) - run in Edit only after wiktor's line. Backs up W1Edges first (TallWallsBefore).
-- 1) Garage/lobby island: adds 2-stud invisible colliders (16 tall) on its open edges (overflow side x < -430 stays open).
-- 2) Replaces W1Edges.Walls with ~8 stud continuous snow-capped rock walls along every collider line (fields + garage island),
--    inner face 0.2 stud past the floor edge (never on a driving surface). Entrances / gates / junction / portals are floor-to-floor
--    or have no collider, so they stay open.
local SS = game.ServerStorage
local bk = SS.W1EdgeBackup_20261006
local E = workspace.W1Edges
if not bk:FindFirstChild("TallWallsBefore") then local c = E:Clone(); c.Name = "TallWallsBefore"; c.Parent = bk end
local w = SS.W1GroundingWork
local K, M = w.Kinds.Value, w.Mats_1.Value
local H = {} do local i = 0 for s in (w.Heights.Value .. ","):gmatch("([^,]*),") do i += 1; H[i] = tonumber(s) end end
local X0, Z0, C, NX, NZ = -600, -560, 4, 290, 290
local COL = {S = {127,146,172}, D = {192,138,82}, C = {58,47,77}, Y = {106,143,194}, R = {107,122,134}, J = {108,98,72}, A = {94,127,168}}
local SNOW = Color3.fromRGB(246, 250, 255)
local rng = Random.new(808)
local function idx(ix, iz) if ix < 0 or iz < 0 or ix >= NX or iz >= NZ then return nil end return iz * NX + ix + 1 end
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local ex = {workspace.Terrain, E}; for _, n in ipairs({"World2", "SnowplowArena", "SnowfallEmitter"}) do local o = workspace:FindFirstChild(n); if o then ex[#ex + 1] = o end end
rp.FilterDescendantsInstances = ex
local function floorAt(x, z, h) local r = workspace:Raycast(Vector3.new(x, h + 6, z), Vector3.new(0, -9, 0), rp); return r and r.Normal.Y > 0.8 and math.abs(r.Position.Y - h) < 1.5 end

-- 1) garage island colliders
local added = 0
do
	local outer = {} -- outer void flood fill
	local q = {}
	for ix = 0, NX - 1 do for _, iz in ipairs({0, NZ - 1}) do local i = idx(ix, iz); if K:sub(i, i) == "0" then outer[i] = true; q[#q + 1] = {ix, iz} end end end
	for iz = 0, NZ - 1 do for _, ix in ipairs({0, NX - 1}) do local i = idx(ix, iz); if K:sub(i, i) == "0" and not outer[i] then outer[i] = true; q[#q + 1] = {ix, iz} end end end
	local h = 1
	while h <= #q do local c = q[h]; h += 1
		for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do local j = idx(c[1] + d[1], c[2] + d[2]); if j and not outer[j] and K:sub(j, j) == "0" then outer[j] = true; q[#q + 1] = {c[1] + d[1], c[2] + d[2]} end end
	end
	for iz = 0, NZ - 1 do for ix = 0, NX - 1 do
		local i = idx(ix, iz)
		local x, z = X0 + (ix + 0.5) * C, Z0 + (iz + 0.5) * C
		if K:sub(i, i) == "1" and H[i] < 6 and x > -430 and x < -179 and z > -372 and z < -192 then
			for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
				local j = idx(ix + d[1], iz + d[2])
				local seam = false; for s = 2, 4 do local k = idx(ix + d[1] * s, iz + d[2] * s); if k and K:sub(k, k) == "1" then seam = true end end
				if j and outer[j] and not seam then
					-- local floor edge along d, two 2-stud pieces per cell
					for _, lat in ipairs({-1, 1}) do
						local last
						for o = -2, 8, 0.25 do
							local px, pz = x + d[1] * o + (d[1] == 0 and lat or 0), z + d[2] * o + (d[2] == 0 and lat or 0)
							if floorAt(px, pz, H[i]) then last = o end
						end
						if last then
							local off = last + 0.8
							local p = Instance.new("Part"); p.Name = "Rim"; p.Anchored = true; p.Transparency = 1; p.CanCollide = true; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
							p.Size = d[1] ~= 0 and Vector3.new(1.2, 16, 2.05) or Vector3.new(2.05, 16, 1.2)
							p.Position = Vector3.new(x + d[1] * off + (d[1] == 0 and lat or 0), H[i] + 8, z + d[2] * off + (d[2] == 0 and lat or 0))
							p:SetAttribute("GarageIsland", true)
							p.Parent = E.Colliders; added += 1
						end
					end
				end
			end
		end
	end end
end

-- 2) tall walls along every collider line
local fW = E:FindFirstChild("Walls") or Instance.new("Folder"); fW.Name = "Walls"; fW:ClearAllChildren(); fW.Parent = E
local groups = {}
for _, c in ipairs(E.Colliders:GetChildren()) do
	local alongX = c.Size.X > c.Size.Z
	local key = (alongX and "x" or "z") .. string.format("%.1f:%.0f", alongX and c.Position.Z or c.Position.X, (c.Position.Y - 8) * 2)
	groups[key] = groups[key] or {alongX = alongX, list = {}}
	table.insert(groups[key].list, c)
end
local nW = 0
for _, g in pairs(groups) do
	table.sort(g.list, function(a, b) return (g.alongX and a.Position.X or a.Position.Z) < (g.alongX and b.Position.X or b.Position.Z) end)
	-- contiguous runs
	local runs, cur = {}, nil
	for _, c in ipairs(g.list) do
		local a0 = (g.alongX and c.Position.X or c.Position.Z) - (g.alongX and c.Size.X or c.Size.Z) / 2
		local a1 = a0 + (g.alongX and c.Size.X or c.Size.Z)
		if cur and a0 - cur.a1 <= 0.4 then cur.a1 = a1 else cur = {a0 = a0, a1 = a1, c = c}; runs[#runs + 1] = cur end
	end
	for _, r in ipairs(runs) do
		local c = r.c
		local floorY = c.Position.Y - c.Size.Y / 2
		local nrm = g.alongX and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
		local mid = (r.a0 + r.a1) / 2
		local base = g.alongX and Vector3.new(mid, floorY, c.Position.Z) or Vector3.new(c.Position.X, floorY, mid)
		local plus, minus = 0, 0
		for t = -0.4, 0.4, 0.2 do
			local s = r.a0 + (r.a1 - r.a0) * (t + 0.5)
			local b2 = g.alongX and Vector3.new(s, floorY, c.Position.Z) or Vector3.new(c.Position.X, floorY, s)
			if floorAt(b2.X + nrm.X * 2.5, b2.Z + nrm.Z * 2.5, floorY) then plus += 1 end
			if floorAt(b2.X - nrm.X * 2.5, b2.Z - nrm.Z * 2.5, floorY) then minus += 1 end
		end
		local out = plus > minus and -nrm or nrm
		local mi = idx(math.floor((base.X - X0) / C), math.floor((base.Z - Z0) / C))
		local col = COL[mi and M:sub(mi, mi) or "S"] or COL.S
		local c3 = Color3.fromRGB(col[1], col[2], col[3])
		-- segments 8-14 studs, slightly overlapping, height 7.5-8.5: one joined run that still reads as natural rock
		local s = r.a0
		while s < r.a1 - 0.05 do
			local L = math.min(r.a1 - s, rng:NextNumber(8, 14)); if r.a1 - (s + L) < 3 then L = r.a1 - s end
			local hgt = rng:NextNumber(7.5, 8.5)
			local cen = (g.alongX and Vector3.new(s + L / 2, 0, c.Position.Z) or Vector3.new(c.Position.X, 0, s + L / 2)) + out * 0.6
			local size = g.alongX and Vector3.new(L + 0.5, hgt + 1.5, 2.4) or Vector3.new(2.4, hgt + 1.5, L + 0.5)
			local v = rng:NextNumber(-0.07, 0.07)
			local p = Instance.new("Part"); p.Name = "Wall"; p.Anchored = true; p.Size = size
			p.CFrame = CFrame.new(cen.X, floorY + hgt / 2 - 0.75, cen.Z)
			p.Color = Color3.new(math.clamp(c3.R * (1 + v), 0, 1), math.clamp(c3.G * (1 + v), 0, 1), math.clamp(c3.B * (1 + v), 0, 1))
			p.Material = Enum.Material.SmoothPlastic; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Parent = fW
			local cap = Instance.new("Part"); cap.Name = "WallSnow"; cap.Anchored = true; cap.CanCollide = false; cap.CanQuery = false; cap.CanTouch = false; cap.CastShadow = false
			cap.Size = g.alongX and Vector3.new(L + 0.7, 0.8, 2.9) or Vector3.new(2.9, 0.8, L + 0.7)
			cap.CFrame = CFrame.new(cen.X, floorY + hgt + 0.3, cen.Z); cap.Color = SNOW; cap.Material = Enum.Material.SmoothPlastic; cap.Parent = fW
			nW += 1; s += L
		end
	end
end
return string.format("garage colliders added=%d walls=%d", added, nW)
