-- W1RemasterKit (ServerStorage ModuleScript, Studio Edit tooling only - never required by game scripts). 2026-10-05, Claude.
-- World 1 remaster helpers: post-process imported Blender packs, archive old scenery with placement info, place new models,
-- replace an old boundary wall by tiling new segments into its footprint + one simple invisible collider (openings stay identical).
local SS = game:GetService("ServerStorage")
local K = {}
local MATS = {SP="SmoothPlastic",NE="Neon",GL="Glass",ME="Metal",FO="Foil",WO="Wood",IC="Ice",SA="Sand",GR="Grass",CO="Concrete",PL="Plastic",MA="Marble",SL="Slate",FA="Fabric",PE="Pebble",BR="Brick",CB="Cobblestone",GN="Granite",WP="WoodPlanks",SN="Snow",LI="Limestone",SS="Sandstone",RO="Rock"}

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
	return f
end
K.folder = folder
function K.built() return folder(SS, "W1RemasterBuilt") end
function K.backup(area) return folder(folder(SS, "W1RemasterBackup_20261005"), area) end
function K.scenery(area) return folder(folder(workspace, "W1Remaster"), area) end

-- imported pack (ServerStorage.W1RemasterImports[pack]) -> one Model per Blender model in W1RemasterBuilt (Root = model origin)
function K.postProcess(pack, spacing)
	spacing = spacing or 120
	local pk = SS.W1RemasterImports[pack]
	for _, d in ipairs(pk:GetDescendants()) do if d:IsA("PackageLink") then d:Destroy() end end
	local ref = pk:FindFirstChild("Ref__Origin__FF00FFNE", true)
	local pcf = ref.CFrame
	local groups, order = {}, {}
	for _, d in ipairs(pk:GetDescendants()) do
		if d:IsA("BasePart") and d ~= ref then
			local mdl, part, code = d.Name:match("^(.-)__(.-)__(.+)$")
			if mdl then
				if not groups[mdl] then groups[mdl] = {}; table.insert(order, mdl) end
				table.insert(groups[mdl], {d, part, code})
			end
		end
	end
	local out = K.built()
	-- the model's index in the pack is recovered from its X position (models are spaced along Blender X)
	local made = {}
	for _, mdl in ipairs(order) do
		local list = groups[mdl]
		local cx = Vector3.zero
		for _, e in ipairs(list) do cx += e[1].Position end
		cx /= #list -- full 3D centroid: the pack may arrive rotated
		local o = out:FindFirstChild(mdl); if o then o:Destroy() end
		local m = Instance.new("Model"); m.Name = mdl
		m:SetAttribute("Pack", pack)
		for _, e in ipairs(list) do
			local d, part, code = e[1], e[2], e[3]
			local hex, mat, tr = code:sub(1, 6), code:sub(7, 8), code:match("T(%d+)$")
			d.Color = Color3.fromHex(hex); d.Material = Enum.Material[MATS[mat] or "SmoothPlastic"]
			d.Transparency = tr and tonumber(tr) / 100 or 0
			d.Name = part; d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false
			d.Parent = m
		end
		table.insert(made, {m = m, cx = cx})
	end
	-- Blender X = i*spacing  ->  Roblox local X = -(i*spacing) relative to the ref
	for _, e in ipairs(made) do
		local localX = pcf:PointToObjectSpace(e.cx).X
		local slot = math.floor(localX / spacing + 0.5) * spacing -- the model's origin = its spacing slot in the ref frame
		local root = Instance.new("Part"); root.Name = "Root"; root.Size = Vector3.new(0.2, 0.2, 0.2); root.Transparency = 1
		root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
		root.CFrame = pcf * CFrame.new(slot, 0, 0); root.Parent = e.m
		e.m.PrimaryPart = root
		e.m:PivotTo(CFrame.new(0, -3000, #out:GetChildren() * 300))
		e.m.Parent = out
	end
	return #made
end

-- archive: move into ServerStorage.W1RemasterBackup_20261005[area], recording where it came from (CFrame is kept as-is)
function K.archive(inst, area, note)
	inst:SetAttribute("OrigParent", inst.Parent:GetFullName())
	inst:SetAttribute("OrigName", inst.Name)
	if inst:IsA("Model") then inst:SetAttribute("OrigPivot", inst:GetPivot()) elseif inst:IsA("BasePart") then inst:SetAttribute("OrigPivot", inst.CFrame) end
	if note then inst:SetAttribute("ArchiveNote", note) end
	inst.Parent = K.backup(area)
	return inst
end

-- place a built model: cf = floor-level CFrame (LookVector = the model's front), optional uniform scale
function K.place(name, cf, area, scale, sub)
	local tpl = K.built():FindFirstChild(name)
	assert(tpl, "missing built model " .. name)
	local m = tpl:Clone()
	if scale and math.abs(scale - 1) > 1e-3 then m:ScaleTo(scale) end
	m:PivotTo(cf)
	local parent = K.scenery(area)
	if sub then parent = folder(parent, sub) end
	m.Parent = parent
	return m
end

function K.collider(area, cf, size, name)
	local p = Instance.new("Part")
	p.Name = name or "Boundary"; p.Size = size; p.CFrame = cf; p.Anchored = true; p.Transparency = 1
	p.CanCollide = true; p.CanQuery = true; p.CanTouch = false; p.CastShadow = false
	p.Parent = folder(K.scenery(area), "Colliders")
	return p
end

-- simple deliberate collision for a placed model: boxes given in the model's local frame (Roblox axes; 1 = model scale)
function K.addColliders(model, area, boxes)
	local piv = model:GetPivot()
	local s = model:GetScale()
	for _, b in ipairs(boxes) do
		local cf = piv * CFrame.new(b[1] * s) * CFrame.Angles(0, math.rad(b[3] or 0), 0)
		K.collider(area, cf, b[2] * s, model.Name .. "Collider")
	end
end

-- footprint of an old wall: centre on the ground, yaw-only frame with X = long axis, length, thickness, height, bottom Y
function K.footprint(old)
	local cf, s
	if old:IsA("Model") then cf, s = old:GetBoundingBox() else cf, s = old.CFrame, old.Size end
	local lx = cf.RightVector; local lz = cf.LookVector
	local fx = Vector3.new(lx.X, 0, lx.Z); local fz = Vector3.new(lz.X, 0, lz.Z)
	local long, len, thick
	if s.X >= s.Z then long, len, thick = fx, s.X, s.Z else long, len, thick = fz, s.Z, s.X end
	long = long.Magnitude > 0.01 and long.Unit or Vector3.xAxis
	return {center = cf.Position, long = long, len = len, thick = thick, height = s.Y, bottom = cf.Position.Y - s.Y / 2}
end

-- replace an old wall with tiled segments facing `inward` (a world point inside the playable area)
-- opts: names = {"SegA","SegB"} (cycled), design = segment design length, depth = design depth, minHeight, colliderHeight, sink
function K.replaceWall(old, area, inward, opts)
	local f = K.footprint(old)
	local n = Vector3.new(-f.long.Z, 0, f.long.X)
	local toIn = Vector3.new(inward.X - f.center.X, 0, inward.Z - f.center.Z)
	if n:Dot(toIn) < 0 then n = -n end
	local k = math.max(1, math.ceil(f.len / (opts.maxTile or 30)))
	local tile = f.len / k
	local scale = tile / opts.design
	local y = f.bottom - (opts.sink or 0.4)
	local placed = {}
	for i = 1, k do
		local c = f.center + f.long * ((i - 0.5) * tile - f.len / 2)
		local pos = Vector3.new(c.X, y, c.Z)
		local name = opts.names[(i - 1) % #opts.names + 1]
		local m = K.place(name, CFrame.lookAt(pos, pos + n), area, scale * (opts.scaleJitter and (1 + ((i * 37) % 7 - 3) * 0.015) or 1), "Walls")
		m:SetAttribute("ReplacesWall", old:GetFullName())
		table.insert(placed, m)
	end
	local ch = opts.colliderHeight or math.max(16, f.height)
	K.collider(area, CFrame.lookAt(Vector3.new(f.center.X, f.bottom + ch / 2, f.center.Z), Vector3.new(f.center.X, f.bottom + ch / 2, f.center.Z) + n), Vector3.new(f.len, ch, math.max(4, math.min(f.thick, opts.depth * scale))), "WallCollider")
	K.archive(old, area, "boundary wall replaced by " .. #placed .. " " .. table.concat(opts.names, "/") .. " segments + WallCollider")
	return placed
end

return K
