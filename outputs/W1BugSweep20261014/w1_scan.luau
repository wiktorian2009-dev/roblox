-- w1_scan.luau (2026-10-14, Claude): World 1 walk/jump scan. Run in Studio EDIT with execute_luau (read-only; it only casts rays).
-- Finds every spot a player can reach on foot (walking, step-ups and running jumps up to 7.2 studs high / 8 studs far) from the
-- spawn, TRAVEL points, Help Yard pads and field centres, then lists "leaks": reachable spots next to open void or the area under
-- the map (below y -15) that no collider blocks. Paywalls are treated as open (players walk through them once they buy the stage).
--   _G.W1.run(_G.W1.seeds()); _G.W1.cluster()  -> _G.W1.leaks / _G.W1.clusters (0 after the 2026-10-14 fix)
-- Grid: 2 studs. Collidable parts count even when CanQuery is false (RaycastParams.RespectCanCollide = true).
-- A spot counts as standable when the surface faces up (normal.Y > 0.3) and has 4.6 studs of headroom.
local W = {}
_G.W1 = W
W.step = 2
W.x0, W.x1, W.z0, W.z1 = -480, 480, -580, 480
W.nx = math.floor((W.x1 - W.x0) / W.step) + 1
W.nz = math.floor((W.z1 - W.z0) / W.step) + 1
W.JUMP = 6.8      -- highest step-up a jump reaches (JumpHeight 7.2 minus a margin)
W.HEAD = 4.6      -- headroom needed to stand
W.UNDER = -15     -- landing below this = under the map

function W.params()
	local rp = RaycastParams.new()
	rp.RespectCanCollide = true
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {}
	for _, m in ipairs(workspace:GetChildren()) do
		if m.Name == "StagePaywall_Model" or m.Name == "SnowFieldZones" or m.Name == "SnowplowArena" or m.Name == "World2" then table.insert(ex, m) end
	end
	rp.FilterDescendantsInstances = ex
	return rp
end
function W.reset() W.cache = {}; W.rp = W.params() end
function W.key(ix, iz) return iz * W.nx + ix end
function W.pos(ix, iz) return W.x0 + ix * W.step, W.z0 + iz * W.step end

-- all collidable top surfaces in one column, top-down, each with its headroom
function W.surfaces(ix, iz)
	local k = W.key(ix, iz)
	local c = W.cache[k]
	if c then return c end
	local x, z = W.pos(ix, iz)
	local list, y = {}, 260
	for _ = 1, 10 do
		local r = workspace:Raycast(Vector3.new(x, y, z), Vector3.new(0, -(y + 700), 0), W.rp)
		if not r then break end
		list[#list + 1] = {y = r.Position.Y, part = r.Instance, ny = r.Normal.Y}
		y = r.Position.Y - 0.06
		if r.Position.Y < -300 then break end
	end
	for i, s in ipairs(list) do
		if i == 1 then s.head = 1e9 else
			local up = workspace:Raycast(Vector3.new(x, s.y + 0.06, z), Vector3.new(0, 40, 0), W.rp)
			s.head = up and (up.Position.Y - s.y) or 1e9
		end
	end
	W.cache[k] = list
	return list
end
-- the surface a walker at height h lands on in a column: highest standable surface no higher than h + JUMP
function W.landing(ix, iz, h)
	for i, s in ipairs(W.surfaces(ix, iz)) do
		if s.y <= h + W.JUMP and s.head >= W.HEAD and s.ny > 0.3 then return i, s end
	end
	return nil
end
-- a wall blocks a step when both a low (body) and a high (above a jump) probe hit something
function W.blocked(ax, az, h, bx, bz)
	local d = Vector3.new(bx - ax, 0, bz - az)
	d = d.Unit * (d.Magnitude + 0.6)
	local r1 = workspace:Raycast(Vector3.new(ax, h + 2.5, az), d, W.rp)
	if not r1 then return false end
	return workspace:Raycast(Vector3.new(ax, h + 7.6, az), d, W.rp) ~= nil, r1.Instance
end
-- a column holds a wall for a walker at h when a solid that starts below h+4 rises above h+JUMP
function W.wallIn(ix, iz, h)
	local list = W.surfaces(ix, iz)
	for i, s in ipairs(list) do
		if s.y > h + W.JUMP then
			local nxt = list[i + 1]
			local bottom
			if nxt then bottom = nxt.y + math.min(nxt.head, 1e6)
			else
				local x, z = W.pos(ix, iz)
				local up = workspace:Raycast(Vector3.new(x, -400, z), Vector3.new(0, s.y + 399, 0), W.rp)
				bottom = up and up.Position.Y or s.y
			end
			if bottom <= h + 4.0 then return true end
		end
	end
	return false
end
-- open void for a walker at h: no surface at all between UNDER and h + JUMP
function W.voidFor(ix, iz, h)
	for _, s in ipairs(W.surfaces(ix, iz)) do
		if s.y <= h + W.JUMP and s.y >= W.UNDER then return false end
	end
	return true
end

function W.seeds()
	local s = {Vector3.new(-167, 3, -282)}
	for _, d in ipairs(workspace.TravelPoints:GetDescendants()) do if d:IsA("BasePart") and d.Position.X < 1000 then s[#s + 1] = d.Position + Vector3.new(0, 3, 0) end end
	for _, y in ipairs(workspace.ContractYards:GetChildren()) do
		local pad = y:FindFirstChild("Pad")
		local p = pad and (pad:IsA("Model") and pad:GetPivot().Position or pad.Position)
		if p and p.X < 1000 then s[#s + 1] = p + Vector3.new(0, 4, 0) end
	end
	for _, z in ipairs(workspace.SnowFieldZones:GetChildren()) do if z:IsA("BasePart") and z.Position.X < 1000 then s[#s + 1] = z.Position + Vector3.new(0, 3, 0) end end
	return s
end

function W.run(seeds)
	W.reset()
	local visited, queue, head, leaks, reached = {}, {}, 1, {}, 0
	local function push(jx, jz, lj)
		local nk = W.key(jx, jz) * 16 + lj
		if not visited[nk] then visited[nk] = true; queue[#queue + 1] = {jx, jz, lj} end
	end
	for _, p in ipairs(seeds) do
		local ix = math.floor((p.X - W.x0) / W.step + 0.5)
		local iz = math.floor((p.Z - W.z0) / W.step + 0.5)
		for i, s in ipairs(W.surfaces(ix, iz)) do
			if s.y <= p.Y + 3 and s.head >= W.HEAD then push(ix, iz, i); break end
		end
	end
	local dirs = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	while head <= #queue do
		local n = queue[head]; head += 1
		local ix, iz, li = n[1], n[2], n[3]
		local s = W.surfaces(ix, iz)[li]
		local h = s.y
		reached += 1
		local ax, az = W.pos(ix, iz)
		for di, d in ipairs(dirs) do
			local jx, jz = ix + d[1], iz + d[2]
			if jx >= 0 and jx < W.nx and jz >= 0 and jz < W.nz then
				local bx, bz = W.pos(jx, jz)
				if not W.blocked(ax, az, h, bx, bz) then
					local lj, sj = W.landing(jx, jz, h)
					if lj and sj.y >= W.UNDER then push(jx, jz, lj)
					elseif W.voidFor(jx, jz, h) and not W.wallIn(jx, jz, h) then
						local ck = W.key(ix, iz)
						leaks[ck] = leaks[ck] or {ix = ix, iz = iz, h = h, part = s.part, dirs = {}}
						leaks[ck].dirs[di] = true
						-- a running jump can still clear a short gap (up to 8 studs)
						for m = 2, 4 do
							local kx, kz = ix + d[1] * m, iz + d[2] * m
							if kx < 0 or kz < 0 or kx >= W.nx or kz >= W.nz then break end
							local cx, cz = W.pos(kx, kz)
							if W.blocked(ax, az, h, cx, cz) then break end
							local lk, sk = W.landing(kx, kz, h - 1.5)
							if lk and sk.y >= W.UNDER then push(kx, kz, lk); break end
						end
					end
				end
			end
		end
		if head % 30000 == 0 then task.wait() end
	end
	W.leaks, W.visited, W.reached = leaks, visited, reached
	return reached
end

-- group leak cells that touch each other (within 2 cells)
function W.cluster()
	local seen, clusters = {}, {}
	for k, L in pairs(W.leaks) do
		if not seen[k] then
			local c = {cells = {}, n = 0}
			local stack = {L}
			seen[k] = true
			while #stack > 0 do
				local cur = table.remove(stack)
				c.n += 1; c.cells[#c.cells + 1] = cur
				for dx = -2, 2 do for dz = -2, 2 do
					local kk = W.key(cur.ix + dx, cur.iz + dz)
					local nb = W.leaks[kk]
					if nb and not seen[kk] then seen[kk] = true; stack[#stack + 1] = nb end
				end end
			end
			clusters[#clusters + 1] = c
		end
	end
	table.sort(clusters, function(a, b) return a.n > b.n end)
	W.clusters = clusters
	return clusters
end

W.run(W.seeds())
W.cluster()
local n = 0 for _ in pairs(W.leaks) do n += 1 end
return string.format("reached=%d leakCells=%d clusters=%d", W.reached, n, #W.clusters)
