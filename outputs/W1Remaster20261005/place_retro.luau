-- place_retro.luau (Studio, Edit): Snowy toy-brick arcade district. Archives old Retro scenery (with placement info) and places the W1_Retro pack.
-- The ClassicNaturalWall boundaries are replaced body-by-body (one invisible collider per old WallBody, same CFrame/size), so every
-- opening stays exactly where it was. The stray yaw-19 duplicate wall that cut across Retro_2 and the yard bridge is archived.
local K = require(game.ServerStorage.W1RemasterKit:Clone())
local AREA = "Retro"
local Y = 3.8
local CENTER = Vector3.new(96, Y, 250)
local XMIN = 20 -- wall bodies west of this belong to the Jungle pass
local log = {}
local function at(x, z, fx, fz) local p = Vector3.new(x, Y, z); return CFrame.lookAt(p, Vector3.new(fx, Y, fz)) end

-- move the given parts of an old model into a backup Model (keeps CFrames; records origin)
local function archiveParts(model, parts, label)
	local holder = Instance.new("Model"); holder.Name = label
	holder:SetAttribute("OrigParent", model:GetFullName()); holder:SetAttribute("OrigName", model.Name)
	holder:SetAttribute("OrigPivot", model:GetPivot()); holder:SetAttribute("ArchiveNote", "Retro-side parts of " .. model.Name .. " (rest stays for the Jungle pass)")
	for _, p in ipairs(parts) do p:SetAttribute("OrigParentPath", p.Parent:GetFullName()); p.Parent = holder end
	holder.Parent = K.backup(AREA)
end

-- 1) boundary walls
local walls = {}
for _, c in ipairs(workspace:GetChildren()) do if c.Name == "ClassicNaturalWall" and c:IsA("Model") then table.insert(walls, c) end end
local nCol, nTile = 0, 0
for _, w in ipairs(walls) do
	local _, yaw = w:GetPivot():ToEulerAnglesYXZ()
	if math.abs(math.deg(yaw) - 19) < 3 then
		K.archive(w, AREA, "stray rotated duplicate of the north wall: cut across Retro_2 and blocked the Yard_Retro bridge")
	else
		local bodies, mine = {}, {}
		for _, p in ipairs(w:GetDescendants()) do
			if p:IsA("BasePart") and p.Position.X >= XMIN then
				table.insert(mine, p)
				if p.Name:match("^WallBody") then table.insert(bodies, p) end
			end
		end
		-- exact colliders
		for _, b in ipairs(bodies) do K.collider(AREA, b.CFrame, b.Size, "WallCollider"); nCol += 1 end
		-- visual runs along X (gap > 3 studs splits a run)
		table.sort(bodies, function(a, b) return a.Position.X < b.Position.X end)
		local runs, cur = {}, nil
		for _, b in ipairs(bodies) do
			local x0, x1 = b.Position.X - b.Size.X / 2, b.Position.X + b.Size.X / 2
			if cur and x0 <= cur.x1 + 3 then cur.x1 = math.max(cur.x1, x1); table.insert(cur.b, b)
			else cur = {x0 = x0, x1 = x1, b = {b}}; table.insert(runs, cur) end
		end
		for _, r in ipairs(runs) do
			local a, z = r.b[1].Position, r.b[#r.b].Position
			local dir = Vector3.new(z.X - a.X, 0, z.Z - a.Z); dir = dir.Magnitude > 1 and dir.Unit or Vector3.xAxis
			local p0 = Vector3.new(a.X, 0, a.Z) - dir * (a.X - r.x0); local p1 = Vector3.new(z.X, 0, z.Z) + dir * (r.x1 - z.X)
			local len = (p1 - p0).Magnitude
			local k = math.max(1, math.ceil(len / 24)); local tile = len / k
			local n = Vector3.new(-dir.Z, 0, dir.X); if n:Dot(CENTER - (p0 + p1) / 2) < 0 then n = -n end
			for i = 1, k do
				local c = p0 + dir * ((i - 0.5) * tile); local pos = Vector3.new(c.X, Y - 0.4, c.Z)
				local m = K.place("R_WallSeg", CFrame.lookAt(pos, pos + n), AREA, (tile / 24) * (1 + ((i * 37) % 7 - 3) * 0.02), "Walls")
				m:SetAttribute("ReplacesWall", w:GetFullName()); nTile += 1
			end
		end
		archiveParts(w, mine, "ClassicNaturalWall_RetroPart")
	end
end
table.insert(log, "walls " .. #walls .. " colliders " .. nCol .. " tiles " .. nTile)

-- 2) archive old decor: both overlapping Classic House copies, the observatory hill, the loose classic tree and the retro panels
local na = 0
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "Classic House" then K.archive(c, AREA, "classic house (duplicate pair) replaced by R_Block buildings; it blocked the Retro_2/yard lane"); na += 1
	elseif c.Name == "Retro" and c:IsA("Model") then K.archive(c, AREA, "observatory hill replaced by R_ArcadeTower in the same footprint"); na += 1
	elseif (c.Name == "GRAMA/GRASS" or c.Name == "MADEIRA/WOOD") then
		local p = c.Position; if p.X > XMIN and p.X < 170 and p.Z > 140 and p.Z < 440 then K.archive(c, AREA, "classic tree"); na += 1 end
	end
end
local bd = workspace:FindFirstChild("BiomeDecor_Retro")
if bd then for _, c in ipairs(bd:GetChildren()) do
	local p = c:IsA("Model") and c:GetBoundingBox().Position or c.Position
	if p.X >= XMIN then K.archive(c, AREA, "BiomeDecor_Retro"); na += 1 end
end end
table.insert(log, "decor " .. na)

-- free-spot helper (no collidable parts, 2 studs clear of fields)
local fields = {}
for _, z in ipairs(workspace.SnowFieldZones:GetChildren()) do if z:IsA("BasePart") then table.insert(fields, z) end end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {workspace.SnowFieldZones}
local function free(cx, cz, sx, sz)
	for _, p in ipairs(workspace:GetPartBoundsInBox(CFrame.new(cx, Y + 4, cz), Vector3.new(sx, 6, sz), op)) do
		if p.CanCollide and p.Position.Y + p.Size.Y / 2 > Y + 0.5 then return false end
	end
	for _, f in ipairs(fields) do
		local rel = f.CFrame:PointToObjectSpace(Vector3.new(cx, f.Position.Y, cz))
		if math.abs(rel.X) < f.Size.X / 2 + sx / 2 + 2 and math.abs(rel.Z) < f.Size.Z / 2 + sz / 2 + 2 then return false end
	end
	-- keep the vehicle lane field1 -> plank gap -> Retro_2 -> yard bridge open
	if cx + sx / 2 > 57 and cx - sx / 2 < 122 and cz + sz / 2 > 258 and cz - sz / 2 < 350 then return false end
	return true
end
local placed = {}
local function put(name, x, z, sx, sz, fx, fz, cols, scale, sub)
	local px, pz = x, z
	if not free(x, z, sx, sz) then
		px = nil
		for r = 3, 15, 3 do for a = 0, 330, 30 do
			local tx, tz = x + math.cos(math.rad(a)) * r, z + math.sin(math.rad(a)) * r
			if not px and free(tx, tz, sx, sz) then px, pz = tx, tz end
		end end
	end
	if not px then table.insert(log, name .. " skipped"); return nil end
	local m = K.place(name, at(px, pz, fx or CENTER.X, fz or CENTER.Z), AREA, scale, sub)
	if cols then K.addColliders(m, AREA, cols) end
	table.insert(placed, name)
	return m
end
local function gui(part, text, size, col, model)
	if not part then return end
	-- pick the face whose normal points along the model front (FBX parts arrive with arbitrary local axes)
	local look = (model or part.Parent):GetPivot().LookVector
	local best, bd = Enum.NormalId.Front, -2
	for _, id in ipairs(Enum.NormalId:GetEnumItems()) do local d = part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id)):Dot(look); if d > bd then best, bd = id, d end end
	local sg = Instance.new("SurfaceGui"); sg.Face = best; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40; sg.LightInfluence = 0
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Text = text; t.Font = Enum.Font.FredokaOne
	t.TextScaled = true; t.TextColor3 = col or Color3.fromRGB(255, 220, 90); t.Parent = sg
	sg.Parent = part
	return sg
end

-- 3) landmark: the arcade tower takes the old observatory hill footprint (x 40..84, z 201..217) against the south wall, facing the fields
local tower = K.place("R_ArcadeTower", at(62, 208, 62, 260), AREA)
K.addColliders(tower, AREA, {{Vector3.new(0, 15, 0), Vector3.new(17, 30, 14)}})
K.collider(AREA, CFrame.new(62, Y + 5, 209), Vector3.new(44, 10, 16), "ArcadeFootprintCollider") -- same blocked area as the old hill
local coin = tower:FindFirstChild("BigCoin"); if coin then coin:SetAttribute("StageDecorMotion", "Spin"); coin:SetAttribute("MotionAxis", "Y"); coin:SetAttribute("MotionSpeed", 1.2) end
gui(tower:FindFirstChild("MarqueeFace"), "ARCADE", nil, nil, tower)
local mq = tower:FindFirstChild("Marquee"); if mq then local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 210, 120); l.Range = 22; l.Brightness = 1.4; l.Parent = mq end
for _, x in ipairs({46, 78}) do
	local m = K.place("R_Arcades", at(x, 205, x, 260), AREA, 1.1)
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Scr" then local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(90, 240, 255); l.Range = 8; l.Brightness = 0.8; l.Parent = d end end
end
-- 4) the block-town quarter where the classic house stood (west of the lane) + a tower in the east pocket
local a = put("R_BlockA", 35, 300, 15, 13, 35, 250, {{Vector3.new(0, 10, 0), Vector3.new(14, 20, 12)}})
local b = put("R_BlockB", 50, 306, 13, 15, 50, 250, {{Vector3.new(0, 10, 0), Vector3.new(12, 20, 12)}})
if b then gui(b:FindFirstChild("SignFace"), "TOYS", nil, nil, b) end
put("R_BlockC", 158, 305, 13, 13, 120, 300, {{Vector3.new(0, 12, 0), Vector3.new(9, 24, 9)}})
-- the arrow points to the viewer's left (verified in Studio), so the sign stands west of the lane and points east into it
local sign = put("R_Sign", 50, 291, 10, 2, 50, 230, {{Vector3.new(0, 4.5, 0), Vector3.new(0.8, 9, 0.8)}})
if sign then gui(sign:FindFirstChild("SignFace"), "YARD", nil, Color3.fromRGB(255, 255, 255), sign) end
-- 5) sculptures + voxel trees along the strip between the fields and the plank row
local heart = put("R_PixelHeart", 38, 272, 9, 6, 60, 240, {{Vector3.new(0, 5, 0), Vector3.new(6, 10, 3)}})
local ghost = put("R_PixelGhost", 145, 268, 9, 4, 110, 240, {{Vector3.new(0, 4, 0), Vector3.new(7, 8, 1.6)}}, 1.2, "Life")
if ghost then ghost:SetAttribute("StageDecorMotion", "Bob"); ghost:SetAttribute("MotionAmount", 0.6); ghost:SetAttribute("MotionSpeed", 1.1) end
local top = put("R_SpinTop", 161, 289, 10, 10, 120, 240, {{Vector3.new(0, 4, 0), Vector3.new(9, 8, 9)}}, 0.75, "Life")
if top then top:SetAttribute("StageDecorMotion", "Spin"); top:SetAttribute("MotionAxis", "Y"); top:SetAttribute("MotionSpeed", 0.8) end
for _, t in ipairs({{28, 266}, {30, 283}, {140, 282}, {30, 312}, {108, 268}}) do
	put("R_VoxelTree", t[1], t[2], 6, 6, CENTER.X, CENTER.Z, {{Vector3.new(0, 3, 0), Vector3.new(2, 6, 2)}}, 1.1, "Trees")
end
-- 6) background: giant toy-block stacks outside the walls
for _, c in ipairs({{120, 150, 0.9, 20}, {40, 155, 1.0, -15}, {158, 385, 0.8, 40}, {40, 350, 0.85, 10}}) do
	K.place("R_GiantBlocks", CFrame.new(c[1], 0, c[2]) * CFrame.Angles(0, math.rad(c[4]), 0), AREA, c[3], "Background")
end
table.insert(log, "props " .. #placed .. " (" .. table.concat(placed, ",") .. "); instances " .. #K.scenery(AREA):GetDescendants())
return table.concat(log, "; ")
