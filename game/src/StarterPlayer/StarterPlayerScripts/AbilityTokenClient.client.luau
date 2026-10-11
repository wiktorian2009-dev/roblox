-- AbilityTokenClient (2026-10-11, Claude): draws the player's OWN ability tokens (the server sends only yours), asks the server to pick
-- one up when the plow or the character is close, plays the short pickup / activation effects and shows the compact buff bar.
-- The server (AbilityService) decides everything: type, position, expiry, distance, buffs. Numbers: ReplicatedStorage.AbilityConfig.
-- Reduced motion (ReducedMotion / TreasureReduced): no bounce or bob, fewer particles. Sounds follow the sound settings.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local AC = require(RS:WaitForChild("AbilityConfig"))
local GameAudio = require(RS:WaitForChild("GameAudio"))
local remote = RS:WaitForChild("AbilityToken")
local AB, DROP, PICK = AC.Abilities, AC.Drop, AC.Pickup

local NAVY = Color3.fromRGB(28, 44, 78)
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.FredokaOne

local function reduced() return player:GetAttribute("ReducedMotion") == true or player:GetAttribute("TreasureReduced") == true end
local function soundOn() return player:GetAttribute("DriveSoundOn") ~= false and player:GetAttribute("SfxOff") ~= true end
local function now() return workspace:GetServerTimeNow() end
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local world = mk("Folder", {Name = "AbilityTokensLocal"}, workspace)

local function plowModel()
	local f = workspace:FindFirstChild("Snowplows") -- same folder PlowDriveClient drives
	return f and f:FindFirstChild("Snowplow_" .. player.UserId)
end
-- the seated plow's hull, else nil
local function seatedHull()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local m = plowModel()
	if hum and m and hum.SeatPart and hum.SeatPart:IsDescendantOf(m) then return m.PrimaryPart, m end
	return nil
end
local function rootPart() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end

-- ===== icons =====
local function iconImage(kind)
	local id = AC.Icons[kind]
	return (id and id ~= "") and id or nil
end
-- a token face / HUD icon: the uploaded icon, or (only if missing) a plain coloured badge with the ability's initial
local function iconInto(parent, kind, z)
	local def = AB[kind]
	local img = iconImage(kind)
	if img then
		return mk("ImageLabel", {BackgroundTransparency = 1, Image = img, Size = UDim2.fromScale(1, 1), ZIndex = z or 1, ScaleType = Enum.ScaleType.Fit}, parent)
	end
	local f = mk("Frame", {BackgroundColor3 = def.Color, Size = UDim2.fromScale(1, 1), ZIndex = z or 1}, parent)
	mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
	mk("UIStroke", {Color = NAVY, Thickness = 3}, f)
	mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = def.Name:sub(1, 1), TextScaled = true, Font = FONT,
		TextColor3 = WHITE, ZIndex = (z or 1) + 1}, f)
	return f
end

-- ===== sounds =====
local SND = {
	TurboTracks = {GameAudio.Steps.Rare, 1.45}, HeatedBlade = {GameAudio.Steps.Epic, 0.85}, SnowSurge = {GameAudio.Reveal, 1.35},
	ComboKeeper = {GameAudio.Steps.Rare, 1.1}, TokenMagnet = {GameAudio.Start, 1.6}, AuroraPatch = {GameAudio.Steps.Legendary, 1.05},
	SnowLane = {GameAudio.Steps.Mythic, 1.25}, Snowburst = {GameAudio.End, 0.95},
}
local soundHolder = mk("Folder", {Name = "AbilitySounds"}, script)
local function playKind(kind, vol)
	if not soundOn() then return end
	local d = SND[kind]
	if not d or not d[1] then return end
	local s = mk("Sound", {SoundId = d[1].Id, Volume = (vol or 0.55), PlaybackSpeed = d[2]}, soundHolder)
	s:Play()
	Debris:AddItem(s, 4)
end

-- ===== tokens =====
local tokens = {} -- id -> {model, coin, ring, kind, pos, born, expires, lastAsk}
local function makeToken(t)
	local def = AB[t.kind]
	local m = mk("Model", {Name = "Token_" .. t.id})
	local coin = mk("Part", {Name = "Coin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.55, 4.4, 4.4), Anchored = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(245, 250, 255), CFrame = CFrame.new(t.pos)}, m)
	-- a thin coloured rim so it reads against white snow
	local rim = mk("Part", {Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.45, 4.8, 4.8), Anchored = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic,
		Color = def.Color, CFrame = CFrame.new(t.pos)}, m)
	for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
		local g = mk("SurfaceGui", {Face = face, CanvasSize = Vector2.new(256, 256), LightInfluence = 0, Brightness = 1.2,
			SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, coin)
		local holder = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(0.92, 0.92), Position = UDim2.fromScale(0.04, 0.04)}, g)
		iconInto(holder, t.kind, 2)
	end
	-- soft ground marker under it (readable from the driving camera)
	local floorY = t.pos.Y - DROP.FloatHeight
	local ring = mk("Part", {Name = "Marker", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 5.2, 5.2), Anchored = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Transparency = 0.6,
		Color = def.Color, CFrame = CFrame.new(t.pos.X, floorY + 0.15, t.pos.Z) * CFrame.Angles(0, 0, math.rad(90))}, m)
	m.Parent = world
	return {model = m, coin = coin, rim = rim, ring = ring, kind = t.kind, pos = t.pos, floorY = floorY, born = os.clock(),
		expires = t.expires, life = t.life or DROP.Lifetime, blink = t.blink or DROP.BlinkAt, lastAsk = 0, spin = math.random() * 6}
end

local function puff(pos, color, n, size)
	if reduced() then n = math.max(1, math.floor(n / 3)) end
	local a = mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one * 0.2,
		CFrame = CFrame.new(pos)}, world)
	local e = mk("ParticleEmitter", {Rate = 0, Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(180, 180),
		Color = ColorSequence.new(color), Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size or 0.9), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new(0.1, 1), Acceleration = Vector3.new(0, -18, 0), Texture = "rbxasset://textures/particles/sparkles_main.dds",
		LightEmission = 0.3}, a)
	e:Emit(n)
	Debris:AddItem(a, 1)
end

local function removeToken(id, reason)
	local tk = tokens[id]
	if not tk then return end
	tokens[id] = nil
	local m = tk.model
	if reason == "clear" or reason == "left" or reason == "afk" or not m.Parent then m:Destroy() return end
	if reason == "magnet" then
		-- thin curved trail toward the plow, then gone
		local hull = seatedHull() or rootPart()
		local a0 = mk("Attachment", {}, tk.coin)
		local tr = mk("Trail", {Attachment0 = a0, Lifetime = 0.25, Color = ColorSequence.new(AB.TokenMagnet.Color), WidthScale = NumberSequence.new(0.35, 0),
			Transparency = NumberSequence.new(0.2, 1), FaceCamera = true}, tk.coin)
		local a1 = mk("Attachment", {Position = Vector3.new(0, 0, 0.6)}, tk.coin); tr.Attachment1 = a1
		local start = tk.coin.Position
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = math.min(1, (os.clock() - t0) / 0.3)
			local target = hull and hull.Parent and hull.Position or start
			local mid = (start + target) / 2 + Vector3.new(0, 4, 0)
			local p = start:Lerp(mid, k):Lerp(mid:Lerp(target, k), k)
			tk.coin.CFrame = CFrame.new(p) * CFrame.Angles(0, k * 8, 0)
			tk.rim.CFrame = tk.coin.CFrame
			tk.ring.Transparency = 0.6 + 0.4 * k
			if k >= 1 then conn:Disconnect(); m:Destroy() end
		end)
		return
	end
	local fade = reason == "expire" and 0.35 or 0.2
	local grow = reason == "pick" and 1.35 or 0.4
	if reason == "pick" then puff(tk.coin.Position, AB[tk.kind].Color, 10, 0.8) end
	for _, p in ipairs({tk.coin, tk.rim, tk.ring}) do
		TweenService:Create(p, TweenInfo.new(fade), {Transparency = 1, Size = p.Size * (p == tk.ring and 1 or grow)}):Play()
	end
	for _, g in ipairs(tk.coin:GetChildren()) do if g:IsA("SurfaceGui") then g.Enabled = false end end
	Debris:AddItem(m, fade + 0.05)
end

-- per frame: pop + one bounce, then hover and rotate; blink near expiry; ask the server when close
RunService.RenderStepped:Connect(function()
	if not next(tokens) then return end
	local t = os.clock()
	local rm = reduced()
	local hull = seatedHull()
	local root = rootPart()
	local bodies, r = {}, PICK.Walk
	if hull then
		table.insert(bodies, hull.Position)
		table.insert(bodies, hull.CFrame:PointToWorldSpace(Vector3.new(0, 0, -hull.Size.Z / 2 - 2)))
		r = math.clamp(math.max(hull.Size.X / 2, 4) + PICK.VehiclePad, PICK.VehicleMin, PICK.VehicleMax)
	elseif root then
		table.insert(bodies, root.Position)
	end
	local srv = now()
	local cam = workspace.CurrentCamera
	for id, tk in pairs(tokens) do
		local age = t - tk.born
		local h = DROP.FloatHeight
		local y
		if rm then y = tk.floorY + h
		elseif age < 0.32 then local k = age / 0.32; y = tk.floorY + 0.4 + (h + 1.4 - 0.4) * (1 - (1 - k) ^ 2) -- pop out of the snow
		elseif age < 0.6 then local k = (age - 0.32) / 0.28; y = tk.floorY + h + 1.4 * (1 - k * k) -- fall back
		elseif age < 0.85 then local k = (age - 0.6) / 0.25; y = tk.floorY + h + 0.5 * math.sin(k * math.pi) -- one small bounce
		else y = tk.floorY + h + 0.25 * math.sin((age - 0.85) * 2.2) end -- gentle hover
		-- turns to face the camera and sways +-35 degrees (a full spin hid the icon edge-on half the time)
		tk.spin += (rm and 0.6 or 1.8) / 60
		local here = Vector3.new(tk.pos.X, y, tk.pos.Z)
		local camPos = cam.CFrame.Position
		local face = Vector3.new(camPos.X, y, camPos.Z)
		if (face - here).Magnitude < 0.1 then face = here + Vector3.new(0, 0, 1) end
		local cf = CFrame.lookAt(here, face) * CFrame.Angles(0, math.rad(35) * math.sin(tk.spin), 0) * CFrame.Angles(0, math.rad(90), 0)
		tk.coin.CFrame = cf
		tk.rim.CFrame = cf
		local left = tk.expires - srv
		local tr = 0
		if left < tk.blink then tr = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(t * (rm and 4 or 9))) end -- gentle blink
		tk.coin.Transparency, tk.rim.Transparency = tr, tr
		for _, g in ipairs(tk.coin:GetChildren()) do if g:IsA("SurfaceGui") then g.Brightness = 1.2 * (1 - tr) end end
		-- ask for pickup (the server checks distance again with its own numbers and also picks up by itself)
		if t - tk.lastAsk >= PICK.RequestEvery then
			for _, b in ipairs(bodies) do
				if Vector3.new(b.X - tk.pos.X, 0, b.Z - tk.pos.Z).Magnitude <= r and math.abs(b.Y - tk.pos.Y) < 12 then
					tk.lastAsk = t
					remote:FireServer("pickup", id)
					break
				end
			end
		end
	end
end)

-- ===== effects (short, capped, cleaned up) =====
local fxFolder = mk("Folder", {Name = "AbilityFx"}, world)
local buffFx = {} -- kind -> cleanup function
local function stopBuffFx(kind) local f = buffFx[kind]; if f then buffFx[kind] = nil; pcall(f) end end

local function ringPulse(center, radius, color, dur, thick)
	local p = mk("Part", {Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Material = Enum.Material.Neon, Color = color, Transparency = 0.35, Size = Vector3.new(thick or 0.15, 1, 1),
		CFrame = CFrame.new(center + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))}, fxFolder)
	TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(thick or 0.15, radius * 2, radius * 2), Transparency = 1}):Play()
	Debris:AddItem(p, dur + 0.05)
end

local function attachTo(part, props) return mk("Attachment", props or {}, part) end

local START = {}
START.TurboTracks = function(hull)
	local a0 = attachTo(hull, {Position = Vector3.new(-hull.Size.X / 2 + 0.4, -hull.Size.Y / 2 + 0.3, hull.Size.Z / 2)})
	local a1 = attachTo(hull, {Position = Vector3.new(-hull.Size.X / 2 + 0.4, -hull.Size.Y / 2 + 0.9, hull.Size.Z / 2)})
	local b0 = attachTo(hull, {Position = Vector3.new(hull.Size.X / 2 - 0.4, -hull.Size.Y / 2 + 0.3, hull.Size.Z / 2)})
	local b1 = attachTo(hull, {Position = Vector3.new(hull.Size.X / 2 - 0.4, -hull.Size.Y / 2 + 0.9, hull.Size.Z / 2)})
	local items = {a0, a1, b0, b1}
	for _, pr in ipairs({{a0, a1}, {b0, b1}}) do
		table.insert(items, mk("Trail", {Attachment0 = pr[1], Attachment1 = pr[2], Lifetime = 0.28, Color = ColorSequence.new(Color3.fromRGB(90, 220, 255)),
			Transparency = NumberSequence.new(0.25, 1), LightEmission = 0.4}, hull))
	end
	if not reduced() then
		table.insert(items, mk("ParticleEmitter", {Rate = 5, Lifetime = NumberRange.new(0.25, 0.4), Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(30, 30),
			Color = ColorSequence.new(Color3.fromRGB(210, 245, 255)), Size = NumberSequence.new(0.35, 0), EmissionDirection = Enum.NormalId.Back,
			Texture = "rbxasset://textures/particles/sparkles_main.dds", LightEmission = 0.5}, a0))
	end
	return function() for _, x in ipairs(items) do x:Destroy() end end
end
START.HeatedBlade = function(hull, model)
	local z = -hull.Size.Z / 2 - 1.2
	local edge = mk("Part", {Name = "HeatEdge", Anchored = false, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true, CastShadow = false,
		Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 140, 50), Transparency = 0.45, Size = Vector3.new(hull.Size.X * 0.95, 0.12, 0.12),
		CFrame = hull.CFrame * CFrame.new(0, -hull.Size.Y / 2 + 0.15, z)}, fxFolder)
	mk("WeldConstraint", {Part0 = edge, Part1 = hull}, edge)
	local a = attachTo(edge)
	local steam = mk("ParticleEmitter", {Rate = reduced() and 2 or 7, Lifetime = NumberRange.new(0.6, 1.0), Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Top, Color = ColorSequence.new(Color3.fromRGB(255, 235, 220)), Size = NumberSequence.new(0.5, 1.4),
		Transparency = NumberSequence.new(0.55, 1), Shape = Enum.ParticleEmitterShape.Box, LightEmission = 0.1}, a)
	local melt = mk("ParticleEmitter", {Rate = reduced() and 1 or 4, Lifetime = NumberRange.new(0.3, 0.5), Speed = NumberRange.new(2, 4),
		Color = ColorSequence.new(Color3.fromRGB(255, 190, 120)), Size = NumberSequence.new(0.25, 0), Acceleration = Vector3.new(0, -14, 0)}, a)
	return function() edge:Destroy(); steam:Destroy(); melt:Destroy() end
end
START.SnowSurge = function(hull)
	local a = attachTo(hull, {Position = Vector3.new(0, hull.Size.Y / 2 + 2.5, 0)})
	local e = mk("ParticleEmitter", {Rate = reduced() and 3 or 9, Lifetime = NumberRange.new(0.5, 0.7), Speed = NumberRange.new(5, 7),
		Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Color = ColorSequence.new(Color3.fromRGB(200, 240, 255), Color3.fromRGB(110, 190, 255)), Size = NumberSequence.new(0.4, 0.1),
		Transparency = NumberSequence.new(0.1, 1), Texture = "rbxasset://textures/particles/sparkles_main.dds", LightEmission = 0.6}, a)
	return function() a:Destroy() end
end
START.ComboKeeper = function(hull)
	local parts = {}
	local n = reduced() and 3 or 5
	for i = 1, n do
		-- small snowflakes: a chunky white six-armed star built from thin parts (no emoji)
		local b = mk("Model", {Name = "Flake"}, fxFolder)
		local p = mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon,
			Color = Color3.fromRGB(200, 215, 255), Size = Vector3.new(0.18, 0.18, 1.1)}, b)
		for k = 1, 2 do
			local q = p:Clone(); q.Name = "Arm" .. k; q.Parent = b
		end
		parts[i] = {p, b}
	end
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		if not hull.Parent then return end
		local a = (os.clock() - t0) * (reduced() and 0.8 or 2.2)
		for i, pb in ipairs(parts) do
			local ang = a + i * math.pi * 2 / n
			local base = CFrame.lookAt(hull.Position + Vector3.new(math.cos(ang) * 4.2, hull.Size.Y / 2 + 1.6 + 0.3 * math.sin(ang * 2), math.sin(ang) * 4.2), hull.Position)
			pb[1].CFrame = base * CFrame.Angles(0, math.rad(90), 0)
			local arm1, arm2 = pb[2]:FindFirstChild("Arm1"), pb[2]:FindFirstChild("Arm2")
			if arm1 then arm1.CFrame = base * CFrame.Angles(0, math.rad(90), math.rad(60)) end
			if arm2 then arm2.CFrame = base * CFrame.Angles(0, math.rad(90), math.rad(-60)) end
		end
	end)
	return function() conn:Disconnect(); for _, pb in ipairs(parts) do pb[1]:Destroy(); pb[2]:Destroy() end end
end
START.TokenMagnet = function(hull)
	local a = attachTo(hull, {Position = Vector3.new(0, hull.Size.Y / 2 + 0.6, 0)})
	local e = mk("ParticleEmitter", {Rate = reduced() and 1 or 3, Lifetime = NumberRange.new(0.6), Speed = NumberRange.new(0), Size = NumberSequence.new(0.3, 2.6),
		Color = ColorSequence.new(AB.TokenMagnet.Color), Transparency = NumberSequence.new(0.5, 1), Texture = "rbxasset://textures/particles/sparkles_main.dds",
		LockedToPart = true, LightEmission = 0.4}, a)
	return function() a:Destroy() end
end

-- Aurora Patch: a readable ground ring + low translucent ribbons at a fixed spot (never covers the field or the view)
local aurora
local function setAurora(info)
	if aurora and (not info or (aurora.pos - info.pos).Magnitude > 0.5) then aurora.cleanup(); aurora = nil end
	if not info or aurora then return end
	local pos, r = info.pos, info.r
	local items = {}
	local ring = mk("Part", {Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Material = Enum.Material.Neon, Color = Color3.fromRGB(140, 255, 200), Transparency = 0.55, Size = Vector3.new(0.12, r * 2, r * 2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))}, fxFolder)
	local inner = mk("Part", {Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 255, 225), Transparency = 0.82, Size = Vector3.new(0.1, r * 2 - 1.2, r * 2 - 1.2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.24, 0)) * CFrame.Angles(0, 0, math.rad(90))}, fxFolder)
	table.insert(items, ring); table.insert(items, inner)
	local cols = {Color3.fromRGB(120, 255, 190), Color3.fromRGB(110, 200, 255), Color3.fromRGB(200, 140, 255)}
	local anchor = mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(pos)}, fxFolder)
	table.insert(items, anchor)
	for i = 1, 3 do
		local ang = i * math.pi * 2 / 3
		local a0 = attachTo(anchor, {Position = Vector3.new(math.cos(ang) * r * 0.85, 1.2 + i * 0.5, math.sin(ang) * r * 0.85)})
		local a1 = attachTo(anchor, {Position = Vector3.new(math.cos(ang + 2.1) * r * 0.85, 1.2 + i * 0.5, math.sin(ang + 2.1) * r * 0.85)})
		mk("Beam", {Attachment0 = a0, Attachment1 = a1, Width0 = 1.6, Width1 = 1.6, CurveSize0 = 4, CurveSize1 = -4, FaceCamera = true, LightEmission = 0.6,
			Color = ColorSequence.new(cols[i], cols[i % 3 + 1]), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1)}),
			TextureSpeed = reduced() and 0 or 0.4}, anchor)
	end
	aurora = {pos = pos, cleanup = function() for _, x in ipairs(items) do x:Destroy() end end}
end

local INSTANT = {}
INSTANT.Snowburst = function(d)
	ringPulse(d.pos, d.r, Color3.fromRGB(190, 235, 255), reduced() and 0.25 or 0.45, 0.25)
	if not reduced() then task.delay(0.08, function() ringPulse(d.pos, d.r * 0.7, Color3.fromRGB(240, 250, 255), 0.35, 0.12) end) end
	puff(d.pos + Vector3.new(0, 1.2, 0), Color3.fromRGB(245, 250, 255), 14, 1.6) -- chunky snow puffs
	puff(d.pos + Vector3.new(0, 2, 0), Color3.fromRGB(170, 225, 255), 6, 0.5) -- a few sparkling fragments
end
INSTANT.SnowLane = function(d)
	local n = math.floor(d.len / 3)
	task.spawn(function()
		for k = 1, n do
			local p = d.start + d.dir * (k * 3)
			ringPulse(p, 3.4, Color3.fromRGB(140, 205, 255), 0.35, 0.12)
			if k % 2 == 0 then puff(p + Vector3.new(0, 1, 0), Color3.fromRGB(240, 248, 255), 3, 0.9) end
			task.wait(d.step)
		end
	end)
end

-- ===== buff bar (compact: icons + seconds, tooltip on hover / tap) =====
local pg = player:WaitForChild("PlayerGui")
local gui = mk("ScreenGui", {Name = "AbilityHud", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 54, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
-- just above the MINIS / UPGRADES / AFK row, below the combo meter: clear of the tutorial card (top), the left/right menus and the drive buttons
local bar = mk("Frame", {Name = "Buffs", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.83, -8),
	Size = UDim2.fromOffset(300, 46), Visible = false}, gui)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder}, bar)
local tip = mk("TextLabel", {Name = "Tip", BackgroundColor3 = NAVY, BackgroundTransparency = 0.15, TextColor3 = WHITE, Font = Enum.Font.GothamMedium,
	TextSize = 13, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), AnchorPoint = Vector2.new(0.5, 0), Visible = false, ZIndex = 10}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 6)}, tip)
mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, tip)
local tipToken = 0
local function showTip(slot, kind, hold)
	tipToken += 1
	local my = tipToken
	tip.Text = AB[kind].Name .. ": " .. AB[kind].Tip
	tip.AnchorPoint = Vector2.new(0.5, 1)
	tip.Position = UDim2.fromOffset(slot.AbsolutePosition.X + slot.AbsoluteSize.X / 2, slot.AbsolutePosition.Y - 4) -- above the slot
	tip.Visible = true
	if hold then task.delay(hold, function() if tipToken == my then tip.Visible = false end end) end
end

local slots = {}
local ends = {}
local function slotFor(kind)
	local s = slots[kind]
	if s then return s end
	local def = AB[kind]
	local f = mk("TextButton", {Name = kind, Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(240, 248, 255), BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(40, 46), LayoutOrder = table.find(AC.Order, kind) or 9}, bar)
	mk("UICorner", {CornerRadius = UDim.new(0, 8)}, f)
	mk("UIStroke", {Color = def.Color, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
	local ic = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(5, 2)}, f)
	iconInto(ic, kind, 2)
	local tl = mk("TextLabel", {Name = "Time", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 13), Position = UDim2.new(0, 0, 1, -14), Text = "",
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = NAVY, ZIndex = 3}, f)
	f.MouseEnter:Connect(function() showTip(f, kind) end)
	f.MouseLeave:Connect(function() tip.Visible = false end)
	f.Activated:Connect(function() showTip(f, kind, 2) end)
	s = {frame = f, time = tl}
	slots[kind] = s
	return s
end

local function refreshBuffFx()
	local hull, model = seatedHull()
	local t = now()
	for _, kind in ipairs({"TurboTracks", "HeatedBlade", "SnowSurge", "ComboKeeper", "TokenMagnet"}) do
		local on = (ends[kind] or 0) > t and hull ~= nil
		if on and not buffFx[kind] then
			local ok, cleanup = pcall(START[kind], hull, model)
			if ok then buffFx[kind] = cleanup end
		elseif not on and buffFx[kind] then stopBuffFx(kind) end
	end
end

RunService.Heartbeat:Connect(function()
	local t = now()
	local any = false
	for kind, e in pairs(ends) do
		local s = slotFor(kind)
		local left = e - t
		if left > 0 then
			any = true
			s.frame.Visible = true
			s.time.Text = math.ceil(left) .. "s"
		else
			ends[kind] = nil
			s.frame:Destroy()
			slots[kind] = nil
			tip.Visible = false
		end
	end
	bar.Visible = any
	refreshBuffFx()
end)

-- ===== intro (once per profile, sent by the server with the first token) =====
local function intro(text)
	local f = mk("TextLabel", {Name = "AbilityIntro", BackgroundColor3 = NAVY, TextColor3 = WHITE, Font = FONT, TextSize = 20,
		Text = text, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 38), AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.19, 0), ZIndex = 8, TextTransparency = 1, BackgroundTransparency = 1}, gui)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, f)
	mk("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, f)
	TweenService:Create(f, TweenInfo.new(0.25), {TextTransparency = 0, BackgroundTransparency = 0.12}):Play()
	task.delay(4.5, function()
		TweenService:Create(f, TweenInfo.new(0.4), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
		Debris:AddItem(f, 0.5)
	end)
end

remote.OnClientEvent:Connect(function(op, a, b)
	if op == "spawn" then
		if tokens[a.id] then return end
		tokens[a.id] = makeToken(a)
		if not reduced() then puff(a.pos - Vector3.new(0, DROP.FloatHeight - 0.5, 0), Color3.fromRGB(245, 250, 255), 6, 0.9) end
	elseif op == "remove" then
		removeToken(a, b)
	elseif op == "buffs" then
		for kind in pairs(ends) do if not a[kind] then ends[kind] = 0 end end
		for kind, e in pairs(a) do ends[kind] = e end
		setAurora(b)
	elseif op == "activated" then
		playKind(a, 0.55)
		local hull = seatedHull() or rootPart()
		if hull and AB[a].Kind ~= "instant" then ringPulse(hull.Position - Vector3.new(0, 1.5, 0), 5, AB[a].Color, 0.3, 0.12) end
	elseif op == "fx" then
		local f = INSTANT[a]
		if f then pcall(f, b) end
	elseif op == "intro" then
		intro(a)
	end
end)

-- respawn / leaving the plow: buff visuals follow the hull, so they are rebuilt or dropped by refreshBuffFx
player.CharacterAdded:Connect(function()
	for kind in pairs(buffFx) do stopBuffFx(kind) end
end)
