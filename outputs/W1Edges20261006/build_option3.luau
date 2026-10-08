-- build_option3.luau (2026-10-06, Claude) - PREPARED, NOT RUN. Run in the Edit DataModel (command bar / execute_luau) only after wiktor picks.
-- Option 1 = WALLS only, 2 = UNDERSIDE only, 3 = both (set OPTION below).
--   WALLS: low natural rock walls, snow-capped, about waist height (3 studs over the floor), along every open edge run that W1Edges
--          already found. They sit just OUTSIDE the floor edge (on the collider line), so no driving surface gets a step. Entrances,
--          Help Yard bridges, stage gates and the garage junction are floor-to-floor, so they get no wall by construction.
--   UNDERSIDE: a big faceted island underside under every World 1 area (fields, paths, lobby), like the Help Yard pads' cone:
--          stacked layers, each one cell (4 studs) smaller per side than the one above, ~5 studs deeper, in the stage's rock colour,
--          with WedgePart facets on each layer's rim. The old shallow W1Edges.RockUnderside strip is replaced.
-- Unchanged: W1Edges.Colliders + SnowRim, Help Yard pads, gates, garage (+overflow side), arena, World 2, all driving surfaces.
-- Backup first: clones W1Edges into ServerStorage.W1EdgeBackup_20261006.Option3Before.
local OPTION = 3
local SS = game.ServerStorage
local bk = SS.W1EdgeBackup_20261006
local E = workspace.W1Edges
if not bk:FindFirstChild("Option3Before") then local c = E:Clone(); c.Name = "Option3Before"; c.Parent = bk end

local w = SS.W1GroundingWork
local K, M = w.Kinds.Value, w.Mats_1.Value
local H = {} do local i = 0 for s in (w.Heights.Value .. ","):gmatch("([^,]*),") do i += 1; H[i] = tonumber(s) end end
local X0, Z0, C, NX, NZ = -600, -560, 4, 290, 290
local COL = {S = {127,146,172}, D = {192,138,82}, C = {58,47,77}, Y = {106,143,194}, R = {107,122,134}, J = {108,98,72}, A = {94,127,168}}
local SNOW = Color3.fromRGB(246, 250, 255)
local rng = Random.new(31)
local function idx(ix, iz) if ix < 0 or iz < 0 or ix >= NX or iz >= NZ then return nil end return iz * NX + ix + 1 end
local function vis(cls, parent, name, size, cf, color)
	local p = Instance.new(cls); p.Name = name; p.Anchored = true; p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = Enum.Material.SmoothPlastic; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent
	return p
end
local function tint(c3, v) return Color3.new(math.clamp(c3.R * (1 + v), 0, 1), math.clamp(c3.G * (1 + v), 0, 1), math.clamp(c3.B * (1 + v), 0, 1)) end
local function skip(x, z) -- garage + overflow, Help Yards (their own pads), anything above y 6 is handled by the h<6 test
	if x > -449 and x < -179 and z > -372 and z < -192 then return true end
	if x < -400 and z > -372 and z < -192 then return true end
	for _, y in ipairs(workspace.ContractYards:GetChildren()) do
		local cf, sz = y:GetBoundingBox()
		if math.abs(x - cf.X) < sz.X / 2 + 6 and math.abs(z - cf.Z) < sz.Z / 2 + 6 then return true end
	end
	return false
end

-- WALLS: one rock block per 2-stud collider piece group (merged into 4-8 stud chunks), on the collider's line
if OPTION == 1 or OPTION == 3 then
	local fW = E:FindFirstChild("Walls") or Instance.new("Folder"); fW.Name = "Walls"; fW:ClearAllChildren(); fW.Parent = E
	for _, c in ipairs(E.Colliders:GetChildren()) do
		local alongX = c.Size.X > c.Size.Z
		local floorY = c.Position.Y - c.Size.Y / 2
		local x, z = c.Position.X, c.Position.Z
		local mi = idx(math.floor((x - X0) / C), math.floor((z - Z0) / C))
		local col = COL[mi and M:sub(mi, mi) or "S"] or COL.S
		local hgt = rng:NextNumber(2.6, 3.4) -- waist height for a 5-stud character
		local len = (alongX and c.Size.X or c.Size.Z) + 0.6
		local size = alongX and Vector3.new(len, hgt + 1.2, 2.2) or Vector3.new(2.2, hgt + 1.2, len)
		local rock = vis("Part", fW, "Wall", size, CFrame.new(x, floorY + hgt / 2 - 0.6, z) * CFrame.Angles(0, math.rad(rng:NextNumber(-2, 2)), 0), tint(Color3.fromRGB(col[1], col[2], col[3]), rng:NextNumber(-0.08, 0.08)))
		rock.CastShadow = true
		local capSize = alongX and Vector3.new(len + 0.2, 0.6, 2.6) or Vector3.new(2.6, 0.6, len + 0.2)
		vis("Part", fW, "WallSnow", capSize, CFrame.new(x, floorY + hgt + 0.25, z), SNOW).CastShadow = false
	end
	E.SnowRim.Parent = nil -- the wall caps replace the snowball rim (kept in Option3Before)
end

-- UNDERSIDE: stepped, faceted island cone under all World 1 floor
if OPTION == 2 or OPTION == 3 then
	local fU = E:FindFirstChild("Underside") or Instance.new("Folder"); fU.Name = "Underside"; fU:ClearAllChildren(); fU.Parent = E
	E.RockUnderside:ClearAllChildren()
	-- solid footprint = walk cells under y 6 that are not skipped
	local foot = {}
	for iz = 0, NZ - 1 do for ix = 0, NX - 1 do
		local i = idx(ix, iz)
		if K:sub(i, i) == "1" and H[i] < 6 and not skip(X0 + (ix + 0.5) * C, Z0 + (iz + 0.5) * C) then foot[i] = H[i] end
	end end
	local layer, depth = foot, 0
	for L = 1, 12 do
		-- erode by one cell (4-neighbour)
		local nxt, n = {}, 0
		for i, h in pairs(layer) do
			local ix, iz = (i - 1) % NX, (i - 1) // NX
			local ok = true
			for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do local j = idx(ix + d[1], iz + d[2]); if not j or not layer[j] then ok = false end end
			if ok then nxt[i] = h; n += 1 end
		end
		local thick = rng:NextNumber(4.5, 6)
		-- greedy row merge of this layer's cells into boxes (same letter), top at (row floor - depth)
		for iz = 0, NZ - 1 do
			local ix = 0
			while ix < NX do
				local i = idx(ix, iz)
				if layer[i] then
					local m, top, x1 = M:sub(i, i), layer[i], ix
					while x1 + 1 < NX and layer[idx(x1 + 1, iz)] and M:sub(idx(x1 + 1, iz), idx(x1 + 1, iz)) == m do x1 += 1; top = math.min(top, layer[idx(x1, iz)]) end
					local col = COL[m] or COL.S
					local y0 = top - 0.4 - depth
					vis("Part", fU, "Layer" .. L, Vector3.new((x1 - ix + 1) * C + 0.2, thick, C + 0.2),
						CFrame.new(X0 + (ix + x1 + 1) / 2 * C, y0 - thick / 2, Z0 + (iz + 0.5) * C),
						tint(Color3.fromRGB(col[1], col[2], col[3]), -0.04 * L + rng:NextNumber(-0.04, 0.04)))
					ix = x1 + 1
				else ix += 1 end
			end
		end
		-- facets: a sloped wedge on every rim cell of this layer (cells that will not exist in the next layer), so steps read as rock faces
		for i, h in pairs(layer) do
			if not nxt[i] then
				local ix, iz = (i - 1) % NX, (i - 1) // NX
				for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
					local j = idx(ix + d[1], iz + d[2])
					if not j or not layer[j] then
						local o = Vector3.new(d[1], 0, d[2]); local a = Vector3.new(-o.Z, 0, o.X)
						local col = COL[M:sub(i, i)] or COL.S
						local cen = Vector3.new(X0 + (ix + 0.5) * C - d[1] * 0.6, h - 0.4 - depth - thick / 2, Z0 + (iz + 0.5) * C - d[2] * 0.6)
						local p = vis("WedgePart", fU, "Facet" .. L, Vector3.new(C + 0.3, thick, 3.2),
							CFrame.fromMatrix(cen, a, Vector3.yAxis) * CFrame.Angles(math.pi, 0, 0), tint(Color3.fromRGB(col[1], col[2], col[3]), -0.04 * L - 0.05))
						p.CastShadow = false
					end
				end
			end
		end
		depth += thick
		if n == 0 then break end
		layer = nxt
	end
end
return string.format("walls=%d underside=%d", E:FindFirstChild("Walls") and #E.Walls:GetChildren() or 0, E:FindFirstChild("Underside") and #E.Underside:GetChildren() or 0)
