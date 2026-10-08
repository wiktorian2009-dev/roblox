--[[ SHOVEL MODEL BUILDER
	Builds every shovel's 3D model into ReplicatedStorage > ShovelModels from the DESIGNS table below.
	Rebuild after editing (Command Bar):
		require(game.ServerStorage.ShovelModelBuilder:Clone()).Build()
	Model layout: grip at +Y, blade at -Y, blade face = Z. PrimaryPart "Handle" = the shaft (used by the spinner).
]]
local Builder = {}

local SP, METAL, WOOD, NEON, GLASS, ICE = Enum.Material.SmoothPlastic, Enum.Material.Metal, Enum.Material.Wood, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Ice
local BASALT, SAND, MARBLE, FOIL = Enum.Material.Basalt, Enum.Material.Sand, Enum.Material.Marble, Enum.Material.Foil
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local PI = math.pi
local TOP = -0.74 -- where the blade starts

--------------------------------------------------
-- PRIMITIVES
--------------------------------------------------
local M -- model being built
local function part(name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = name
	if props and props.Shape then p.Shape = props.Shape end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or SP
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Massless = true; p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if props then for k, v in pairs(props) do if k ~= "Shape" then p[k] = v end end end
	p.Parent = M
	return p
end
local function ball(name, d, pos, color, mat, props)
	props = props or {}
	props.Shape = Enum.PartType.Ball
	return part(name, Vector3.new(d, d, d), CFrame.new(pos), color, mat, props)
end
local function wedge(name, size, cf, color, mat, props)
	local w = Instance.new("WedgePart")
	w.Name = name; w.Size = size; w.CFrame = cf; w.Color = color; w.Material = mat or SP
	w.Anchored = true; w.CanCollide = false; w.CanQuery = false; w.CanTouch = false; w.Massless = true; w.CastShadow = false
	if props then for k, v in pairs(props) do w[k] = v end end
	w.Parent = M
	return w
end
-- flat isosceles triangle in the blade plane; base centered at (bx,by), apex at distance h in direction ang
local function tri(name, bx, by, z, ang, hw, h, thick, color, mat, props)
	local base = CFrame.new(bx, by, z) * CFrame.Angles(0, 0, ang - PI / 2)
	for _, s in ipairs({1, -1}) do
		wedge(name, Vector3.new(thick, h, hw), base * CFrame.fromMatrix(Vector3.new(s * hw / 2, h / 2, 0), Vector3.new(0, 0, s), Vector3.new(0, 1, 0)), color, mat, props)
	end
end
-- 3D spike (two crossed blades); Y axis of cf = spike direction
local function spike(name, cf, h, hw, color, mat, props)
	for b = 0, 1 do
		local bcf = cf * CFrame.Angles(0, b * PI / 2, 0)
		for s = 0, 1 do
			local c = bcf * CFrame.new(0, h / 2, s == 0 and -hw / 2 or hw / 2)
			if s == 1 then c = c * CFrame.Angles(0, PI, 0) end
			wedge(name, Vector3.new(hw * 0.9, h, hw), c, color, mat, props)
		end
	end
end
local function emitter(p, kind, color)
	local e = Instance.new("ParticleEmitter")
	e.Name = kind
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Color = ColorSequence.new(color)
	if kind == "Sparkle" then
		e.Rate = 7; e.Lifetime = NumberRange.new(0.5, 0.9); e.Speed = NumberRange.new(0.3, 0.8); e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.28), NumberSequenceKeypoint.new(1, 0)})
	elseif kind == "Fire" then
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Rate = 14; e.Lifetime = NumberRange.new(0.3, 0.6); e.Speed = NumberRange.new(0.8, 1.6)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0)})
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
		e.Acceleration = Vector3.new(0, 3, 0)
	elseif kind == "Smoke" then
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.LightEmission = 0.3
		e.Rate = 5; e.Lifetime = NumberRange.new(0.8, 1.3); e.Speed = NumberRange.new(0.3, 0.7)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.1)})
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})
		e.Acceleration = Vector3.new(0, 1.5, 0)
	elseif kind == "Snow" then
		e.Rate = 6; e.Lifetime = NumberRange.new(0.8, 1.3); e.Speed = NumberRange.new(0.2, 0.5); e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = Vector3.new(0, -2, 0)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.08)})
	end
	e.Parent = p
end
local function light(p, color, range)
	local l = Instance.new("PointLight")
	l.Color = color; l.Range = range or 7; l.Brightness = 1.4; l.Shadows = false
	l.Parent = p
end

--------------------------------------------------
-- BLADE SHAPES: width, straight height, tip height, thickness
--------------------------------------------------
local SHAPES = {
	shield  = {W = 1.36, RH = 0.72, TH = 0.62, Tip = "shield"},
	square  = {W = 1.3,  RH = 1.12, TH = 0,    Tip = "flat"},
	broad   = {W = 1.78, RH = 0.74, TH = 0.46, Tip = "round", Flare = 1.04},
	pointed = {W = 1.12, RH = 0.44, TH = 1.12, Tip = "point"},
	trench  = {W = 0.9,  RH = 1.05, TH = 0.5,  Tip = "shield"},
	heavy   = {W = 1.48, RH = 0.8,  TH = 0.56, T = 0.2, Tip = "round", Flare = 1.05},
	gem     = {W = 1.28, RH = 0.0,  TH = 1.28, Gem = true},
}

--------------------------------------------------
-- HIGH-POLY BLADE HELPERS
--------------------------------------------------
-- any 3D triangle from two wedges (thickness along the triangle's normal)
local function triangle(name, a, b, c, thick, color, mat)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then c, a = a, c
	elseif acd > bcd and acd > abd then a, b = b, a end
	ab, ac, bc = b - a, c - a, c - b
	local cr = ac:Cross(ab)
	if cr.Magnitude < 1e-6 then return end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	if height < 0.002 then return end
	local l1, l2 = math.abs(ab:Dot(back)), math.abs(ac:Dot(back))
	if l1 > 0.002 then wedge(name, Vector3.new(thick, height, l1), CFrame.fromMatrix((a + b) / 2, right, up, back), color, mat) end
	if l2 > 0.002 then wedge(name, Vector3.new(thick, height, l2), CFrame.fromMatrix((a + c) / 2, -right, up, -back), color, mat) end
end

local function curve(p0, p1, p2, n)
	local pts = {}
	for i = 1, n do
		local t = i / n
		local u = 1 - t
		table.insert(pts, Vector2.new(u * u * p0.X + 2 * u * t * p1.X + t * t * p2.X, u * u * p0.Y + 2 * u * t * p1.Y + t * t * p2.Y))
	end
	return pts
end

-- right-half outline of a blade: from top-center, around the side, to the bottom tip
local function outline(sh, hw, top)
	local RH, TH = sh.RH, sh.TH
	local bottom = top - RH - TH
	local pts = {}
	if sh.Gem then
		local mid = top - 0.36
		pts = {Vector2.new(0, top), Vector2.new(hw * 0.3, top - 0.05), Vector2.new(hw * 0.75, top - 0.2), Vector2.new(hw, mid)}
		for _, p in ipairs(curve(Vector2.new(hw, mid), Vector2.new(hw * 0.62, mid - TH * 0.3), Vector2.new(0, bottom), 6)) do table.insert(pts, p) end
		return pts, bottom
	end
	local flare = sh.Flare or 1
	table.insert(pts, Vector2.new(0, top))
	table.insert(pts, Vector2.new(hw - 0.08, top))
	for _, p in ipairs(curve(Vector2.new(hw - 0.08, top), Vector2.new(hw, top), Vector2.new(hw, top - 0.08), 2)) do table.insert(pts, p) end
	local sideEnd = Vector2.new(hw * flare, top - RH)
	for i = 1, 2 do
		local t = i / 3
		table.insert(pts, Vector2.new(hw + (hw * flare - hw) * t, top - 0.08 - (RH - 0.08) * t))
	end
	table.insert(pts, sideEnd)
	if TH <= 0.01 then
		bottom = top - RH - 0.16
		for _, p in ipairs(curve(sideEnd, Vector2.new(hw * flare, bottom), Vector2.new(hw * flare - 0.2, bottom), 4)) do table.insert(pts, p) end
		table.insert(pts, Vector2.new(0, bottom))
	else
		local tip = sh.Tip or "shield"
		local ctrl
		if tip == "point" then ctrl = Vector2.new(hw * 0.5, top - RH - TH * 0.45)
		elseif tip == "round" then ctrl = Vector2.new(hw * flare * 0.98, bottom + TH * 0.12)
		else ctrl = Vector2.new(hw * flare * 0.82, top - RH - TH * 0.55) end
		for _, p in ipairs(curve(sideEnd, ctrl, Vector2.new(0, bottom), 7)) do table.insert(pts, p) end
	end
	return pts, bottom
end

-- fills one half of the blade (s = 1 right, -1 left) with triangles, curved into a scoop (dish) or a gem bulge
local function fillHalf(pts, s, hw, dish, bulge, thick, color, mat, name, simple)
	local function P(x, y)
		local z = dish * (x / hw) ^ 2
		if bulge then z = -bulge * (1 - math.abs(x) / hw) end
		return Vector3.new(s * x, y, z)
	end
	for i = 1, #pts - 1 do
		local A, B = pts[i], pts[i + 1]
		if simple then
			triangle(name, P(A.X, A.Y), P(B.X, B.Y), P(0, B.Y), thick, color, mat)
			triangle(name, P(A.X, A.Y), P(0, B.Y), P(0, A.Y), thick, color, mat)
		else
			local ax, bx = A.X / 2, B.X / 2
			triangle(name, P(A.X, A.Y), P(B.X, B.Y), P(bx, B.Y), thick, color, mat)
			triangle(name, P(A.X, A.Y), P(bx, B.Y), P(ax, A.Y), thick, color, mat)
			triangle(name, P(ax, A.Y), P(bx, B.Y), P(0, B.Y), thick, color, mat)
			triangle(name, P(ax, A.Y), P(0, B.Y), P(0, A.Y), thick, color, mat)
		end
	end
end

-- merges all parts of a temp model into one mesh (UnionOperation); keeps the wedges if CSG fails
local function mergeInto(target, tmp, name, mat, props)
	local parts = tmp:GetChildren()
	tmp.Parent = workspace
	local first = table.remove(parts, 1)
	local ok, u = pcall(function()
		return first:UnionAsync(parts, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Precise)
	end)
	if ok and u then
		u.Name = name
		u.UsePartColor = false
		u.Material = mat
		u.Anchored = true; u.CanCollide = false; u.CanQuery = false; u.CanTouch = false; u.CastShadow = false; u.Massless = true
		if props then for k, v in pairs(props) do u[k] = v end end
		u.Parent = target
		tmp:Destroy()
		return u
	end
	warn("[ShovelModelBuilder] union failed for " .. name .. ": " .. tostring(u))
	table.insert(parts, 1, first)
	for _, p in ipairs(parts) do
		if props then for k, v in pairs(props) do p[k] = v end end
		p.Parent = target
	end
	tmp:Destroy()
	return first
end

--------------------------------------------------
-- BUILD ONE SHOVEL
--------------------------------------------------
local function build(d)
	M = Instance.new("Model")
	M.Name = d.Name
	local metal = d.Metal
	local trim = d.Trim or metal:Lerp(WHITE, 0.15)
	local accent = d.Accent or trim:Lerp(BLACK, 0.25)
	local metalMat = d.MetalMat or METAL
	local mp = d.Shiny and {Reflectance = d.Shiny} or nil
	local sh = SHAPES[d.Shape or "shield"]
	local W, RH, TH, T = sh.W, sh.RH, sh.TH, d.T or sh.T or 0.12
	local bladeColor, bladeMat = d.Blade or metal, d.BladeMat or metalMat
	local bp = {Reflectance = d.Shiny or 0, Transparency = d.BladeTransparency or 0}
	local edge = d.Edge or bladeColor:Lerp(WHITE, 0.4)
	local edgeMat = d.EdgeMat or bladeMat
	local ridge = d.Ridge or bladeColor:Lerp(BLACK, 0.22)
	local zf = {-(T / 2 + 0.025), T / 2 + 0.025}
	local bottomY = TOP - RH - TH

	---------------- GRIP ----------------
	local gripColor, gripMat = d.Grip or metal, d.GripMat or metalMat
	if d.GripType == "T" then
		part("GripTop", Vector3.new(1.15, 0.26, 0.26), CFrame.new(0, 1.62, 0), gripColor, gripMat, mp)
		part("ShaftTop", Vector3.new(0.18, 0.45, 0.18), CFrame.new(0, 1.4, 0), d.Shaft or rgb(140, 90, 55), d.ShaftMat or WOOD)
		for s = -1, 1, 2 do part("GripCap", Vector3.new(0.14, 0.32, 0.32), CFrame.new(s * 0.6, 1.62, 0), trim, metalMat, mp) end
		if d.Wrap then part("GripWrap", Vector3.new(0.7, 0.32, 0.32), CFrame.new(0, 1.62, 0), d.Wrap, SP) end
	else
		part("GripTop", Vector3.new(1.0, 0.24, 0.26), CFrame.new(0, 2.05, 0), gripColor, gripMat, mp)
		for s = -1, 1, 2 do
			part("GripSide", Vector3.new(0.22, 0.86, 0.26), CFrame.new(s * 0.25, 1.75, 0) * CFrame.Angles(0, 0, -s * 0.695), gripColor, gripMat, mp)
			part("GripCap", Vector3.new(0.3, 0.3, 0.3), CFrame.new(s * 0.5, 2.05, 0) * CFrame.Angles(0, 0, PI / 4), trim, metalMat, mp)
		end
		if d.Wrap then part("GripWrap", Vector3.new(0.62, 0.3, 0.32), CFrame.new(0, 2.05, 0), d.Wrap, SP) end
	end
	part("TopCollar", Vector3.new(0.34, 0.3, 0.34), CFrame.new(0, 1.36, 0), trim, metalMat, mp)
	part("TopRing", Vector3.new(0.38, 0.07, 0.38), CFrame.new(0, 1.19, 0), accent, metalMat, mp)

	---------------- SHAFT ----------------
	local handle = part("Handle", Vector3.new(0.2, 1.72, 0.2), CFrame.new(0, 0.36, 0), d.Shaft or rgb(140, 90, 55), d.ShaftMat or WOOD, d.ShaftProps)
	if d.ShaftWrap then
		for _, y in ipairs({0.95, 0.72}) do part("ShaftWrap", Vector3.new(0.24, 0.14, 0.24), CFrame.new(0, y, 0), d.ShaftWrap, SP) end
	end
	if d.ShaftRings then
		for _, y in ipairs({0.45, 0.05}) do part("ShaftRing", Vector3.new(0.26, 0.07, 0.26), CFrame.new(0, y, 0), accent, metalMat, mp) end
	end
	part("BottomCollar", Vector3.new(0.34, 0.26, 0.34), CFrame.new(0, -0.55, 0), trim, metalMat, mp)
	part("BottomRing", Vector3.new(0.38, 0.07, 0.38), CFrame.new(0, -0.39, 0), accent, metalMat, mp)
	part("Socket", Vector3.new(0.3, 0.26, 0.24), CFrame.new(0, -0.74, 0), trim, metalMat, mp)
	for _, z in ipairs(zf) do tri("SocketTaper", 0, -0.86, z, -PI / 2, 0.18, 0.32, 0.05, trim, metalMat, mp) end

	---------------- BLADE (high-poly, merged into meshes) ----------------
	local hw = W / 2
	local pts, bottom = outline(sh, hw, TOP)
	bottomY = bottom
	local H = TOP - bottom
	local dish = sh.Gem and 0 or (d.Dish or 0.1)
	local bulge = sh.Gem and 0.12 or 0
	-- depth of a decoration so it never touches the curved blade:
	-- side -1 = front, 1 = back; layer 0,1,2... = stacking order; xmin/xmax = the |x| range it covers
	local function surf(x) return dish * (x / hw) ^ 2 - bulge * (1 - math.min(math.abs(x), hw) / hw) end
	local function Z(side, layer, thick, xmin, xmax)
		local base = side < 0 and (surf(xmin or 0) - T / 2) or (surf(math.min(xmax or 0, hw)) + T / 2)
		return base + side * (0.015 + layer * 0.035 + thick / 2)
	end
	local keep = M
	-- main plate
	local tmp = Instance.new("Model")
	M = tmp
	for _, s in ipairs({1, -1}) do fillHalf(pts, s, hw, dish, sh.Gem and bulge or nil, T, bladeColor, bladeMat, "Blade", false) end
	-- beveled rim (slightly bigger, thinner, behind the plate)
	local rimTmp = Instance.new("Model")
	M = rimTmp
	local e = 0.08
	local rimPts = {}
	for _, p in ipairs(pts) do table.insert(rimPts, Vector2.new(p.X * (hw + e) / hw, TOP - 0.03 - (TOP - p.Y) * (H + e - 0.03) / H)) end
	for _, s in ipairs({1, -1}) do fillHalf(rimPts, s, hw + e, dish, nil, T * 0.55, edge, edgeMat, "BladeRim", true) end
	M = keep
	local blade = mergeInto(M, tmp, "Blade", bladeMat, bp)
	mergeInto(M, rimTmp, "BladeRim", edgeMat, nil)

	if sh.Gem then
		for _, s in ipairs({-1, 1}) do
			part("GemShine", Vector3.new(0.05, H * 0.55, 0.03), CFrame.new(-hw * 0.3, TOP - H * 0.35, Z(s, 1, 0.03, hw * 0.1, hw * 0.5)) * CFrame.Angles(0, 0, 0.35), WHITE, NEON, {Transparency = 0.4})
		end
	else
		-- center ridge on both faces
		for _, s in ipairs({-1, 1}) do tri("Ridge", 0, TOP - 0.05, Z(s, 2, 0.05, 0, 0.12), -PI / 2, 0.12, H * 0.8, 0.05, ridge, bladeMat, {Transparency = bp.Transparency}) end
		-- foot treads on the shoulders
		for _, s in ipairs({1, -1}) do
			local x = s * (hw - 0.26)
			part("Tread", Vector3.new(0.36, 0.08, T + 0.12), CFrame.new(x, TOP - 0.03, dish * ((hw - 0.26) / hw) ^ 2), edge, edgeMat)
		end
	end

	---------------- DETAILS (layered, never touching another surface) ----------------
	local SIDES = {-1, 1}
	local edgeZ = surf(hw)
	local function rectY(f) return TOP - RH * f end
	if d.Rivets then
		for _, s in ipairs(SIDES) do
			part("RivetPlate", Vector3.new(0.36, 0.42, 0.04), CFrame.new(0, TOP - 0.2, Z(s, 0, 0.04, 0, 0.18)), trim, metalMat, mp)
			for _, y in ipairs({TOP - 0.09, TOP - 0.31}) do ball("Rivet", 0.12, Vector3.new(0, y, Z(s, 3, 0.12, 0, 0.06)), accent, metalMat) end
		end
	end
	if d.Bolts and RH > 0 then
		for _, s in ipairs(SIDES) do
			for _, sx in ipairs({-1, 1}) do
				local x = W / 2 - 0.15
				for _, y in ipairs({TOP - 0.14, rectY(1) + 0.12}) do
					ball("Bolt", 0.12, Vector3.new(sx * x, y, Z(s, 3, 0.12, x - 0.06, x + 0.06)), d.BoltColor or accent, metalMat)
				end
			end
		end
	end
	if d.Plate and RH > 0 then
		for _, s in ipairs(SIDES) do
			part("ArmorPlate", Vector3.new(W * 0.7, RH * 0.55, 0.04), CFrame.new(0, rectY(0.42), Z(s, 0, 0.04, 0, W * 0.35)), d.Plate, metalMat, mp)
		end
	end
	if d.Teeth or d.Spikes then
		local big = d.Spikes
		local th, h = big and 0.12 or 0.08, big and 0.32 or 0.15
		local col = d.SpikeColor or bladeColor
		local sideN = big and 2 or 3
		for _, s in ipairs({1, -1}) do
			for k = 1, sideN do
				local y = TOP - 0.1 - (RH - 0.16) * (k - 0.5) / sideN
				tri("Tooth", s * (hw + 0.02), y, edgeZ, s == 1 and 0 or PI, th, h, T * 0.9, col, bladeMat)
			end
			if TH > 0 then
				local ang = math.atan2(-(W / 2), s * TH)
				for _, t in ipairs(big and {0.35, 0.72} or {0.2, 0.5, 0.8}) do
					local x = hw * (1 - t)
					tri("Tooth", s * x, TOP - RH - TH * t, surf(x), ang, th, h, T * 0.9, col, bladeMat)
				end
			end
		end
		if big then
			tri("Spike", 0, bottomY + 0.05, 0, -PI / 2, 0.1, 0.4, T * 0.9, col, bladeMat)
			for _, s in ipairs({1, -1}) do tri("Spike", s * (hw - 0.06), TOP, edgeZ, PI / 2 + s * -0.6, 0.1, 0.35, T * 0.9, col, bladeMat) end
		end
	end
	if d.DoubleEdge then
		for _, s in ipairs({1, -1}) do
			tri("Prong", s * (hw + 0.02), TOP - RH + 0.08, edgeZ, -PI / 2 + s * 0.75, 0.14, 0.5, T * 0.9, edge, edgeMat)
		end
	end
	if d.Patina and RH > 0 then
		for _, s in ipairs(SIDES) do
			for _, p in ipairs({{-0.35, 0.3, 0.22, 0.16}, {0.3, 0.6, 0.18, 0.2}, {-0.1, 0.85, 0.15, 0.12}}) do
				local ax = math.abs(p[1])
				part("Patina", Vector3.new(p[3], p[4], 0.03), CFrame.new(p[1], rectY(p[2]), Z(s, 0, 0.03, math.max(0, ax - p[3] / 2), ax + p[3] / 2)), d.Patina, SAND)
			end
		end
	end
	if d.Weave and RH > 0 then
		for _, s in ipairs(SIDES) do
			for i = 0, 3 do for j = 0, 2 do
				if (i + j) % 2 == 0 then
					local x = -W / 2 + W / 8 + i * W / 4
					local ax = math.abs(x)
					part("Weave", Vector3.new(W / 4 - 0.05, RH / 3 - 0.05, 0.03), CFrame.new(x, TOP - RH / 6 - j * RH / 3, Z(s, 0, 0.03, math.max(0, ax - W / 8), ax + W / 8)), d.Weave, SP)
				end
			end end
		end
	end
	if d.Hazard and RH > 0 then
		for _, s in ipairs(SIDES) do
			for i = 0, 5 do
				local x = -W / 2 + W / 12 + i * W / 6
				local ax = math.abs(x)
				part("Hazard", Vector3.new(W / 6, 0.16, 0.035), CFrame.new(x, TOP - 0.12, Z(s, 0, 0.035, math.max(0, ax - W / 12), ax + W / 12)),
					i % 2 == 0 and rgb(250, 200, 40) or rgb(25, 25, 25), SP)
			end
		end
	end
	if d.Bands then
		local cols = d.Bands
		for _, s in ipairs(SIDES) do
			for i, c in ipairs(cols) do
				part("Band", Vector3.new(W * 0.96, RH / #cols, 0.03), CFrame.new(0, TOP - RH / #cols * (i - 0.5), Z(s, 0, 0.03, 0, hw)), c, SP)
			end
			for k, c in ipairs(d.TipBands or {}) do
				local f = 1 - (k - 1) * 0.28
				tri("TipBand", 0, TOP - RH, Z(s, k, 0.03, 0, hw * f), -PI / 2, hw * 0.96 * f, TH * 0.95 * f, 0.03, c, SP)
			end
		end
	end
	if d.Cracks then
		local rnd = Random.new(#d.Name * 7)
		for _, s in ipairs(SIDES) do
			for i = 1, 7 do
				local y = TOP - 0.12 - rnd:NextNumber() * (RH + TH * 0.6)
				local maxX = (y > TOP - RH) and (hw - 0.18) or math.max(0.05, hw * (1 - (TOP - RH - y) / math.max(TH, 0.01)) - 0.18)
				local x = (rnd:NextNumber() * 2 - 1) * maxX
				local ax = math.abs(x)
				part("Crack", Vector3.new(0.05, 0.18 + rnd:NextNumber() * 0.22, 0.03), CFrame.new(x, y, Z(s, 1 + (i % 2), 0.03, math.max(0, ax - 0.2), ax + 0.2)) * CFrame.Angles(0, 0, rnd:NextNumber() * PI), d.Cracks, NEON)
			end
		end
	end
	if d.Drips then
		for _, p in ipairs({{0, bottomY - 0.12, 0.16}, {hw + 0.03, TOP - RH * 0.8, 0.12}, {-hw - 0.03, TOP - RH * 0.5, 0.11}, {0.25, bottomY + 0.3, 0.1}}) do
			ball("Drip", p[3], Vector3.new(p[1], p[2], surf(p[1])), d.Drips, NEON)
		end
	end
	if d.Runes then
		for _, s in ipairs(SIDES) do
			for _, y in ipairs({TOP - 0.22, TOP - 0.47, TOP - 0.72}) do
				part("Rune", Vector3.new(0.14, 0.14, 0.03), CFrame.new(0, y, Z(s, 3, 0.03, 0, 0.1)) * CFrame.Angles(0, 0, PI / 4), d.Runes, NEON)
			end
			for _, sx in ipairs({1, -1}) do
				part("Rune", Vector3.new(0.05, 0.3, 0.03), CFrame.new(sx * 0.34, TOP - 0.35, Z(s, 1, 0.03, 0.25, 0.43)) * CFrame.Angles(0, 0, sx * 0.4), d.Runes, NEON)
				part("Rune", Vector3.new(0.05, 0.22, 0.03), CFrame.new(sx * 0.3, TOP - 0.62, Z(s, 1, 0.03, 0.22, 0.38)) * CFrame.Angles(0, 0, -sx * 0.4), d.Runes, NEON)
			end
		end
	end
	if d.Thorns then
		for i, y in ipairs({1.0, 0.6, 0.2, -0.2}) do
			spike("Thorn", CFrame.new(0, y, 0) * CFrame.Angles(0, i * 2.1, 0) * CFrame.Angles(0, 0, -PI / 2.6), 0.32, 0.1, d.Thorns, metalMat)
		end
	end
	if d.Core then
		local cy = sh.Gem and (TOP - 0.36) or (TOP - RH * 0.55)
		for _, s in ipairs(SIDES) do
			ball("Core", 0.3, Vector3.new(0, cy, Z(s, 3, 0.3, 0, 0.15)), d.Core, NEON)
			if d.Trefoil then
				for k = 0, 2 do
					local a = k * 2 * PI / 3 + PI / 2
					part("Trefoil", Vector3.new(0.2, 0.26, 0.03), CFrame.new(math.cos(a) * 0.3, cy + math.sin(a) * 0.3, Z(s, 1, 0.03, 0, 0.45)) * CFrame.Angles(0, 0, a - PI / 2), d.Core, NEON)
				end
			end
		end
	end
	if d.Crystals then
		local col, mat = d.Crystals, d.CrystalMat or GLASS
		local cp = {Transparency = 0.1}
		for _, s in ipairs({1, -1}) do
			spike("Crystal", CFrame.new(s * (hw - 0.05), TOP - RH * 0.35, edgeZ) * CFrame.Angles(0, 0, -s * 1.0), 0.6, 0.2, col, mat, cp)
			spike("Crystal", CFrame.new(s * (hw - 0.1), TOP - RH * 0.85, surf(hw - 0.1)) * CFrame.Angles(0, 0, -s * 1.35), 0.42, 0.15, col, mat, cp)
			spike("Crystal", CFrame.new(s * 0.18, -0.6, 0) * CFrame.Angles(0, 0, -s * 0.5), 0.45, 0.15, col, mat, cp)
		end
		if d.BigCrystals then
			for _, s in ipairs({1, -1}) do
				spike("Crystal", CFrame.new(s * 0.1, 1.3, 0) * CFrame.Angles(0, 0, -s * 0.9), 0.55, 0.16, col, mat, cp)
				spike("Crystal", CFrame.new(s * (hw - 0.1), TOP - RH * 0.6, surf(hw - 0.1)) * CFrame.Angles(0, 0, -s * 1.6), 0.75, 0.22, col, mat, cp)
			end
			spike("Crystal", CFrame.new(0, bottomY + 0.1, 0) * CFrame.Angles(PI, 0, 0), 0.55, 0.2, col, mat, cp)
		end
	end
	if d.Icicles then
		for _, p in ipairs({{-hw + 0.05, TOP - RH, 0.35}, {hw - 0.05, TOP - RH, 0.3}, {0.12, -0.7, 0.28}, {-0.12, -0.7, 0.22}, {0.14, 1.15, 0.25}}) do
			local z = (p[2] < -0.72) and surf(p[1]) or 0
			spike("Icicle", CFrame.new(p[1], p[2], z) * CFrame.Angles(PI, 0, 0), p[3], 0.1, d.Icicles, ICE, {Transparency = 0.05})
		end
	end
	if d.Frost then
		for _, p in ipairs({{0, 1.44, 0.4, 0.14}, {0, -0.49, 0.41, 0.12}, {0.15, 2.19, 0.5, 0.1}, {0, 0.6, 0.27, 0.1}}) do
			part("Frost", Vector3.new(p[3], p[4], p[3]), CFrame.new(p[1], p[2], 0), d.Frost, SAND)
		end
	end
	if d.Wings then
		for _, s in ipairs({1, -1}) do
			for k = 0, 2 do
				part("Feather", Vector3.new(0.75 - k * 0.15, 0.2, 0.06 + k * 0.012), CFrame.new(s * (0.45 + k * 0.08), -0.58 - k * 0.14, k * 0.02) * CFrame.Angles(0, 0, s * (0.55 - k * 0.25)),
					d.Wings, SP)
			end
			part("WingTrim", Vector3.new(0.7, 0.07, 0.1), CFrame.new(s * 0.45, -0.48, 0) * CFrame.Angles(0, 0, s * 0.55), trim, metalMat, mp)
		end
	end
	if d.Halo then
		for k = 0, 11 do
			local a = k * PI / 6
			part("Halo", Vector3.new(0.26, 0.07, 0.07), CFrame.new(math.cos(a) * 0.45, 2.55, math.sin(a) * 0.45) * CFrame.Angles(0, -a + PI / 2, 0), d.Halo, NEON)
		end
	end
	if d.GripGem then
		for _, z in ipairs({-0.19, 0.19}) do
			part("GripGem", Vector3.new(0.18, 0.18, 0.06), CFrame.new(0, 1.36, z) * CFrame.Angles(0, 0, PI / 4), d.GripGem, NEON)
		end
	end
	if d.Chunks then
		for _, p in ipairs({{hw + 0.35, TOP - 0.2, 0.28}, {-hw - 0.3, TOP - RH * 0.7, 0.22}, {0.2, bottomY - 0.35, 0.2}}) do
			part("RockChunk", Vector3.new(p[3], p[3] * 0.8, p[3]), CFrame.new(p[1], p[2], 0) * CFrame.Angles(0.5, 0.7, 0.3), d.Blade or metal, BASALT)
		end
	end

	---------------- FX ----------------
	if d.Glow then light(blade, d.Glow, d.GlowRange or 7) end
	for _, fx in ipairs(d.Particles or {}) do emitter(blade, fx[1], fx[2]) end

	local hl = Instance.new("Highlight")
	hl.Name = "Outline"
	hl.FillTransparency = 1
	hl.OutlineColor = BLACK
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = M

	M.PrimaryPart = handle
	M.WorldPivot = handle.CFrame
	local built = M
	M = nil
	return built
end

--------------------------------------------------
-- DESIGNS (names must match RNGConfig)
--------------------------------------------------
local WD, DARKWOOD, BLK = rgb(150, 98, 58), rgb(95, 60, 38), rgb(28, 28, 32)
local RAINBOW = {rgb(255, 70, 70), rgb(255, 160, 50), rgb(255, 230, 70), rgb(80, 220, 100), rgb(70, 150, 255), rgb(170, 90, 255)}

Builder.DESIGNS = {
	{Name = "Tin Shovel",          Metal = rgb(200, 202, 208), Shaft = WD, Shiny = 0.05},
	{Name = "Copper Shovel",       Metal = rgb(205, 112, 62), Edge = rgb(245, 160, 100), Shaft = DARKWOOD, Patina = rgb(80, 170, 140), Shiny = 0.08},
	{Name = "Bronze Shovel",       Metal = rgb(170, 112, 62), Edge = rgb(215, 160, 95), Shaft = WD, Rivets = true, Shiny = 0.08},
	{Name = "Aluminum Shovel",     Metal = rgb(218, 222, 230), Edge = rgb(250, 250, 255), Shaft = WD, Wrap = BLK, Shiny = 0.12},
	{Name = "Zinc Shovel",         Metal = rgb(150, 172, 195), Edge = rgb(205, 220, 235), Shaft = WD, ShaftWrap = rgb(60, 70, 90)},
	{Name = "Nickel Shovel",       Metal = rgb(198, 192, 178), Edge = rgb(232, 228, 214), Shaft = DARKWOOD, Rivets = true, Shiny = 0.1},
	{Name = "Reinforced Shovel",   Metal = rgb(150, 155, 162), Plate = rgb(185, 190, 198), Bolts = true, Shaft = WD, Wrap = BLK, ShaftRings = true},
	{Name = "Heavy Shovel",        Metal = rgb(92, 96, 104), Shape = "heavy", Edge = rgb(150, 155, 165), Bolts = true, Rivets = true, Shaft = DARKWOOD, Wrap = BLK, ShaftRings = true},
	{Name = "Broad Shovel",        Metal = rgb(150, 155, 162), Shape = "broad", Edge = rgb(200, 205, 212), Shaft = WD, Bolts = true},
	{Name = "Pointed Shovel",      Metal = rgb(185, 188, 194), Shape = "pointed", Edge = rgb(235, 238, 245), Shaft = WD, ShaftWrap = BLK, Shiny = 0.1},
	{Name = "Trench Shovel",       Metal = rgb(72, 74, 80), Shape = "trench", GripType = "T", Edge = rgb(130, 134, 142), Shaft = DARKWOOD, Wrap = BLK, Rivets = true},
	{Name = "Square Shovel",       Metal = rgb(140, 143, 150), Shape = "square", Edge = rgb(190, 195, 202), Shaft = WD, Bolts = true, ShaftRings = true},
	{Name = "Serrated Shovel",     Metal = rgb(160, 165, 172), Teeth = true, Edge = rgb(215, 220, 228), Shaft = rgb(170, 100, 55), Rivets = true, Wrap = BLK},
	{Name = "Double Edge Shovel",  Metal = rgb(175, 180, 190), DoubleEdge = true, Edge = rgb(240, 245, 255), Shaft = WD, Wrap = rgb(150, 30, 30), Shiny = 0.15},
	{Name = "Spiked Shovel",       Metal = rgb(80, 84, 92), Spikes = true, SpikeColor = rgb(170, 175, 185), Edge = rgb(140, 145, 155), Shaft = DARKWOOD, Wrap = rgb(160, 30, 30), Thorns = rgb(120, 125, 135)},
	{Name = "Military Shovel",     Metal = rgb(92, 102, 62), Grip = BLK, GripType = "T", Edge = rgb(135, 145, 95), Shaft = rgb(70, 78, 48), ShaftMat = SP, Wrap = BLK, Rivets = true, Bolts = true, ShaftRings = true},
	{Name = "Industrial Shovel",   Metal = rgb(140, 145, 152), Shape = "broad", Hazard = true, Bolts = true, BoltColor = rgb(250, 200, 40), Edge = rgb(195, 200, 210), Grip = rgb(250, 200, 40), Shaft = BLK, ShaftMat = SP, ShaftRings = true},
	{Name = "Carbon Shovel",       Metal = rgb(34, 34, 38), MetalMat = SP, Weave = rgb(58, 58, 66), Edge = rgb(90, 92, 102), Shaft = BLK, ShaftMat = SP, Wrap = rgb(200, 30, 30), Shiny = 0.15},
	{Name = "Titanium Shovel",     Metal = rgb(170, 190, 212), Shape = "pointed", Edge = rgb(225, 238, 252), Shaft = rgb(185, 140, 90), Wrap = rgb(30, 45, 80), ShaftRings = true, Shiny = 0.2},
	{Name = "Tungsten Shovel",     Metal = rgb(58, 60, 68), Shape = "heavy", Edge = rgb(115, 120, 132), Grip = BLK, Shaft = BLK, ShaftMat = SP, Bolts = true, Rivets = true, ShaftRings = true, Shiny = 0.1},
	{Name = "Gold Shovel",         Metal = rgb(240, 188, 45), Edge = rgb(255, 230, 120), Trim = rgb(255, 215, 80), Shaft = DARKWOOD, GripGem = rgb(230, 30, 60), Rivets = true, ShaftRings = true, Shiny = 0.25,
		Particles = {{"Sparkle", rgb(255, 225, 120)}}},
	{Name = "Diamond Shovel",      Metal = rgb(210, 235, 245), Shape = "gem", Blade = rgb(190, 245, 255), BladeMat = GLASS, BladeTransparency = 0.15, Edge = rgb(230, 255, 255), EdgeMat = NEON,
		Trim = rgb(235, 240, 250), Shaft = rgb(230, 235, 245), ShaftMat = SP, GripGem = rgb(150, 240, 255), Shiny = 0.2, Glow = rgb(170, 240, 255), Particles = {{"Sparkle", WHITE}}},
	{Name = "Emerald Shovel",      Metal = rgb(235, 190, 60), Shape = "gem", Blade = rgb(40, 200, 110), BladeMat = GLASS, BladeTransparency = 0.1, Edge = rgb(120, 255, 170), EdgeMat = NEON,
		Shaft = DARKWOOD, GripGem = rgb(60, 230, 130), Shiny = 0.2, Glow = rgb(80, 255, 150), Particles = {{"Sparkle", rgb(140, 255, 180)}}},
	{Name = "Ruby Shovel",         Metal = rgb(235, 190, 60), Shape = "gem", Blade = rgb(220, 30, 60), BladeMat = GLASS, BladeTransparency = 0.1, Edge = rgb(255, 110, 130), EdgeMat = NEON,
		Shaft = DARKWOOD, GripGem = rgb(255, 50, 80), Shiny = 0.2, Glow = rgb(255, 70, 100), Particles = {{"Sparkle", rgb(255, 150, 170)}}},
	{Name = "Sapphire Shovel",     Metal = rgb(215, 220, 232), Shape = "gem", Blade = rgb(40, 90, 230), BladeMat = GLASS, BladeTransparency = 0.1, Edge = rgb(120, 170, 255), EdgeMat = NEON,
		Shaft = rgb(40, 50, 90), ShaftMat = SP, GripGem = rgb(80, 140, 255), Shiny = 0.2, Glow = rgb(90, 140, 255), Particles = {{"Sparkle", rgb(150, 190, 255)}}},
	{Name = "Crystal Shovel",      Metal = rgb(120, 200, 255), MetalMat = GLASS, Blade = rgb(120, 210, 255), BladeMat = GLASS, BladeTransparency = 0.15, Edge = rgb(170, 240, 255), EdgeMat = NEON,
		Crystals = rgb(110, 210, 255), Shaft = rgb(70, 140, 210), ShaftMat = GLASS, Glow = rgb(120, 220, 255), Particles = {{"Sparkle", rgb(170, 235, 255)}}},
	{Name = "Frozen Shovel",       Metal = rgb(175, 225, 250), MetalMat = ICE, Blade = rgb(185, 232, 255), BladeMat = ICE, BladeTransparency = 0.1, Edge = rgb(235, 250, 255),
		Icicles = rgb(210, 245, 255), Frost = rgb(245, 250, 255), Shaft = rgb(120, 170, 210), ShaftMat = ICE, Glow = rgb(170, 230, 255), Particles = {{"Snow", WHITE}}},
	{Name = "Molten Shovel",       Metal = rgb(45, 35, 32), MetalMat = BASALT, Blade = rgb(50, 36, 32), BladeMat = BASALT, Edge = rgb(255, 120, 30), EdgeMat = NEON, Cracks = rgb(255, 130, 30),
		Drips = rgb(255, 150, 40), Trim = rgb(70, 50, 45), Shaft = rgb(40, 30, 28), ShaftMat = BASALT, Glow = rgb(255, 120, 40), Particles = {{"Fire", rgb(255, 140, 50)}}},
	{Name = "Radioactive Shovel",  Metal = rgb(55, 60, 55), Blade = rgb(50, 58, 50), Edge = rgb(120, 255, 60), EdgeMat = NEON, Core = rgb(140, 255, 70), Trefoil = true, Hazard = true,
		Shaft = rgb(40, 44, 40), ShaftMat = SP, ShaftWrap = rgb(120, 255, 60), Glow = rgb(120, 255, 60), Particles = {{"Sparkle", rgb(150, 255, 90)}, {"Smoke", rgb(120, 255, 60)}}},
	{Name = "Cursed Shovel",       Metal = rgb(62, 32, 82), Blade = rgb(58, 28, 80), Edge = rgb(200, 70, 255), EdgeMat = NEON, Runes = rgb(230, 90, 255), Thorns = rgb(40, 20, 55),
		Spikes = true, SpikeColor = rgb(80, 40, 105), Shaft = rgb(35, 20, 45), ShaftMat = SP, Glow = rgb(190, 70, 255), Particles = {{"Smoke", rgb(170, 60, 230)}}},
	{Name = "Absolute Zero Shovel", Metal = rgb(150, 225, 255), MetalMat = GLASS, Blade = rgb(160, 235, 255), BladeMat = GLASS, BladeTransparency = 0.1, Edge = rgb(120, 230, 255), EdgeMat = NEON,
		Crystals = rgb(130, 225, 255), CrystalMat = GLASS, BigCrystals = true, Icicles = rgb(210, 245, 255), Frost = WHITE, Core = rgb(160, 240, 255),
		Shaft = rgb(90, 170, 220), ShaftMat = ICE, Glow = rgb(120, 230, 255), GlowRange = 9, Particles = {{"Sparkle", rgb(190, 245, 255)}, {"Snow", WHITE}}},
	{Name = "Rainbow Shovel",      Metal = rgb(250, 250, 255), Blade = WHITE, BladeMat = SP, Bands = RAINBOW, TipBands = {rgb(80, 220, 100), rgb(70, 150, 255), rgb(170, 90, 255)},
		Edge = rgb(255, 255, 255), EdgeMat = NEON, Trim = rgb(255, 120, 200), Shaft = rgb(255, 255, 255), ShaftMat = SP, ShaftWrap = rgb(255, 120, 200), GripGem = rgb(120, 220, 255),
		Glow = rgb(255, 200, 255), Particles = {{"Sparkle", rgb(255, 150, 230)}, {"Sparkle", rgb(140, 220, 255)}}},
	{Name = "Meteor Shovel",       Metal = rgb(60, 45, 40), MetalMat = BASALT, Blade = rgb(62, 46, 40), BladeMat = BASALT, Shape = "heavy", Edge = rgb(255, 90, 30), EdgeMat = NEON,
		Cracks = rgb(255, 100, 30), Chunks = true, Spikes = true, SpikeColor = rgb(70, 50, 45), Shaft = rgb(45, 32, 30), ShaftMat = BASALT, Glow = rgb(255, 100, 40), GlowRange = 9,
		Particles = {{"Fire", rgb(255, 120, 40)}, {"Smoke", rgb(90, 70, 60)}}},
	{Name = "Angelic Shovel",      Metal = rgb(250, 245, 235), MetalMat = MARBLE, Blade = rgb(252, 250, 245), BladeMat = MARBLE, Edge = rgb(255, 210, 80), EdgeMat = METAL, Trim = rgb(255, 210, 80),
		Wings = rgb(255, 255, 255), Halo = rgb(255, 225, 110), Shaft = rgb(245, 240, 230), ShaftMat = MARBLE, ShaftRings = true, GripGem = rgb(120, 220, 255), Shiny = 0.1,
		Glow = rgb(255, 230, 150), Particles = {{"Sparkle", rgb(255, 235, 150)}}},
	{Name = "Void Shovel",         Metal = rgb(18, 10, 30), MetalMat = SP, Blade = rgb(10, 5, 20), BladeMat = SP, Shape = "pointed", Edge = rgb(170, 60, 255), EdgeMat = NEON,
		Core = rgb(200, 90, 255), Runes = rgb(170, 60, 255), Spikes = true, SpikeColor = rgb(25, 12, 40), Thorns = rgb(30, 15, 50), Shaft = rgb(15, 8, 25), ShaftMat = SP,
		ShaftWrap = rgb(170, 60, 255), Glow = rgb(170, 60, 255), GlowRange = 9, Particles = {{"Smoke", rgb(120, 40, 200)}, {"Sparkle", rgb(210, 140, 255)}}},
}

function Builder.Build(onlyNames)
	local RS = game:GetService("ReplicatedStorage")
	local folder = RS:FindFirstChild("ShovelModels") or Instance.new("Folder")
	folder.Name = "ShovelModels"
	folder.Parent = RS
	local ok, fail = 0, {}
	local only
	if onlyNames then only = {} for _, n in ipairs(onlyNames) do only[n] = true end end
	for _, d in ipairs(Builder.DESIGNS) do
		if only and not only[d.Name] then continue end
		local good, res = pcall(build, d)
		if good then
			local old = folder:FindFirstChild(d.Name)
			if old then old:Destroy() end
			res.Parent = folder
			ok += 1
		else
			table.insert(fail, d.Name .. ": " .. tostring(res))
		end
	end
	return ok, fail
end

return Builder
