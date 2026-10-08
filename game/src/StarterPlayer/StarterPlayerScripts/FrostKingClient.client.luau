-- FrostKingClient (2026-10-04, Claude): draws THE FROST KING event; FrostKingService (server) decides everything.
-- Snowy GUI (announcement + JOIN, pill, boss bar, personal panel, messages, rewards), world marker, the animated penguin,
-- attack telegraphs (always shown, even with reduced effects), layered VFX from ReplicatedStorage.UniversalVFX, sounds.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("FrostKingConfig"))
local VFX = require(RS:WaitForChild("UniversalVFX"))
local UI = require(RS:WaitForChild("SnowUI"))
local Format = require(RS:WaitForChild("NumberFormat"))
local GameAudio = require(RS:WaitForChild("GameAudio"))
local Assets = RS:WaitForChild("FrostKingAssets")
local event = RS:WaitForChild("FrostKingEvent")
local joinFn = RS:WaitForChild("FrostKingJoin")
local TX = VFX.Textures
local function now() return workspace:GetServerTimeNow() end

local FONT = Enum.Font.FredokaOne
local WHITE, NAVY = Color3.new(1, 1, 1), Color3.fromRGB(20, 40, 85)
local ICE, DANGER, WARN = Color3.fromRGB(150, 225, 255), Color3.fromRGB(255, 70, 80), Color3.fromRGB(255, 190, 60)
local GREEN, GREY = Color3.fromRGB(80, 210, 110), Color3.fromRGB(150, 160, 185)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local settings = {Reduced = false, Shake = true}
pcall(function()
	local q = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	if q > 0 and q <= 3 then settings.Reduced = true end
end)

local ev, st, act, me = nil, nil, nil, nil
local dismissed, lastState = false, nil
local model, rootPart, beakPart = nil, nil, nil
local parts, joints, crownParts, flipperParts = {}, {}, {}, {}
local markerPart, markerText, aura = nil, nil, nil
local tele = {}
local partList, cfList = {}, {}
local display = {pos = nil, dir = Vector3.new(0, 0, -1), speed = 0}
local fxFolder = Instance.new("Folder")
fxFolder.Name = "FrostKingFX"
fxFolder.Parent = workspace

local function smooth(x) x = math.clamp(x, 0, 1); return x * x * (3 - 2 * x) end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function unitFlat(v) local f = flat(v); if f.Magnitude < 1e-3 then return Vector3.new(0, 0, -1) end return f.Unit end
local function bounce(x)
	if x < 1 / 2.75 then return 7.5625 * x * x end
	if x < 2 / 2.75 then x -= 1.5 / 2.75; return 7.5625 * x * x + 0.75 end
	if x < 2.5 / 2.75 then x -= 2.25 / 2.75; return 7.5625 * x * x + 0.9375 end
	x -= 2.625 / 2.75
	return 7.5625 * x * x + 0.984375
end
local function fmtTime(s) s = math.max(0, math.floor(s + 0.5)); return ("%d:%02d"):format(s // 60, s % 60) end
local function NS(a, b) return NumberSequence.new({NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b)}) end
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function decor(o) o:SetAttribute("SnowUIDecor", true); return o end
local function label(parent, text, props)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE, ZIndex = 6}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	mk("UIStroke", {Thickness = 2.5, Color = NAVY}, l)
	return l
end
local function panel(parent, props, kind)
	local f = mk("Frame", {BackgroundColor3 = Color3.fromRGB(200, 232, 255), BorderSizePixel = 0, Visible = false}, parent)
	for k, v in pairs(props) do f[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.12, 0)}, f)
	mk("UIStroke", {Thickness = 3, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
	pcall(UI.Skin, f, kind or "card")
	return f
end
local function button(parent, text, color, props)
	local b = mk("TextButton", {AutoButtonColor = true, BackgroundColor3 = color, Text = "", ZIndex = 6, BorderSizePixel = 0}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, b)
	mk("UIStroke", {Thickness = 2.5, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
	local l = label(b, text, {Name = "Text", Size = UDim2.fromScale(0.9, 0.72), Position = UDim2.fromScale(0.05, 0.14), ZIndex = 7})
	b:SetAttribute("SnowUIDecor", true) -- 2026-10-04: no frost rim on small buttons
	return b, l
end

--------------------------------------------------
-- GUI
--------------------------------------------------
local gui = mk("ScreenGui", {Name = "FrostKingGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 57, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
local ann = panel(gui, {Name = "Announce", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.21), Size = UDim2.fromScale(touch and 0.88 or 0.6, 0.3)}, "panel")
local annScale = mk("UIScale", {Scale = 1}, ann)
local annTitle = label(ann, "\u{2744} THE FROST KING HAS APPEARED!", {Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.92, 0.29)})
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, ICE)}, annTitle)
local annSub = label(ann, "", {Position = UDim2.fromScale(0.06, 0.36), Size = UDim2.fromScale(0.88, 0.17)})
local annTime = label(ann, "", {Position = UDim2.fromScale(0.15, 0.55), Size = UDim2.fromScale(0.7, 0.12), TextColor3 = Color3.fromRGB(255, 232, 150)})
local joinBtn, joinText = button(ann, "JOIN", GREEN, {Position = UDim2.fromScale(0.16, 0.71), Size = UDim2.fromScale(0.4, 0.22)})
local laterBtn = button(ann, "LATER", GREY, {Position = UDim2.fromScale(0.6, 0.71), Size = UDim2.fromScale(0.24, 0.22)})
local pill = panel(gui, {Name = "Pill", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.988, touch and 0.19 or 0.3), Size = UDim2.fromScale(touch and 0.4 or 0.24, 0.07)})
local pillText = label(pill, "", {Position = UDim2.fromScale(0.04, 0.14), Size = UDim2.fromScale(0.6, 0.72), TextXAlignment = Enum.TextXAlignment.Left})
local pillJoin, pillJoinText = button(pill, "JOIN", GREEN, {Position = UDim2.fromScale(0.66, 0.14), Size = UDim2.fromScale(0.31, 0.72)})
local bar = panel(gui, {Name = "BossBar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.016), Size = UDim2.fromScale(touch and 0.74 or 0.46, 0.095)})
label(bar, "\u{1F451} THE FROST KING", {Position = UDim2.fromScale(0.03, 0.07), Size = UDim2.fromScale(0.42, 0.38), TextXAlignment = Enum.TextXAlignment.Left})
local barPhase = label(bar, "PHASE I", {Position = UDim2.fromScale(0.45, 0.07), Size = UDim2.fromScale(0.2, 0.38), TextColor3 = ICE})
local barTime = label(bar, "", {Position = UDim2.fromScale(0.65, 0.07), Size = UDim2.fromScale(0.14, 0.38), TextColor3 = Color3.fromRGB(255, 232, 150)})
local fxBtn, fxText = button(bar, "FX", Color3.fromRGB(120, 180, 255), {Position = UDim2.fromScale(0.8, 0.07), Size = UDim2.fromScale(0.08, 0.38)})
local shakeBtn, shakeText = button(bar, "SHAKE", Color3.fromRGB(120, 180, 255), {Position = UDim2.fromScale(0.89, 0.07), Size = UDim2.fromScale(0.09, 0.38)})
local track = decor(mk("Frame", {Position = UDim2.fromScale(0.03, 0.53), Size = UDim2.fromScale(0.94, 0.36), BackgroundColor3 = Color3.fromRGB(25, 40, 80), BorderSizePixel = 0, ZIndex = 5}, bar))
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, track)
local fill = decor(mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6}, track))
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, fill)
local fillGrad = mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(120, 220, 255), Color3.fromRGB(60, 140, 255))}, fill)
local hpText = label(track, "", {Size = UDim2.fromScale(1, 1), ZIndex = 8})
local mePanel = panel(gui, {Name = "Me", AnchorPoint = touch and Vector2.new(0, 1) or Vector2.new(1, 1), Position = touch and UDim2.fromScale(0.012, 0.87) or UDim2.fromScale(0.988, 0.87), Size = UDim2.fromScale(touch and 0.34 or 0.2, 0.13)})
local meHPTrack = decor(mk("Frame", {Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.24), BackgroundColor3 = Color3.fromRGB(70, 25, 40), BorderSizePixel = 0, ZIndex = 5}, mePanel))
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, meHPTrack)
local meHPFill = decor(mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 110, 130), BorderSizePixel = 0, ZIndex = 6}, meHPTrack))
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, meHPFill)
local meHPText = label(meHPTrack, "", {Size = UDim2.fromScale(1, 1), ZIndex = 8})
local mePart = label(mePanel, "", {Position = UDim2.fromScale(0.05, 0.4), Size = UDim2.fromScale(0.9, 0.26)})
local meReward = label(mePanel, "", {Position = UDim2.fromScale(0.05, 0.68), Size = UDim2.fromScale(0.9, 0.24), TextColor3 = Color3.fromRGB(255, 232, 150)})
local msg = label(gui, "", {Name = "Msg", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.72, 0.09), Visible = false, ZIndex = 20})
local msgScale = mk("UIScale", {Scale = 1}, msg)
local hint = label(gui, "JUMP!", {Name = "Hint", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.3, 0.08), Visible = false, ZIndex = 20, TextColor3 = WARN})
local flashFrame = decor(mk("Frame", {Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = DANGER, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1}, gui))
local rewardPanel = panel(gui, {Name = "Reward", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(touch and 0.8 or 0.46, 0.34), ZIndex = 10}, "panel")
local rewardScale = mk("UIScale", {Scale = 1}, rewardPanel)
local rewardTitle = label(rewardPanel, "", {Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.9, 0.24)})
local rewardLines = label(rewardPanel, "", {Position = UDim2.fromScale(0.07, 0.33), Size = UDim2.fromScale(0.86, 0.4)})
local rewardOk = button(rewardPanel, "OK", GREEN, {Position = UDim2.fromScale(0.35, 0.77), Size = UDim2.fromScale(0.3, 0.17)})

local msgToken = 0
local function showMsg(text, color, seconds)
	msgToken += 1
	local my = msgToken
	msg.Text, msg.TextColor3, msg.Visible = text, color or WHITE, true
	msgScale.Scale = 0.5
	TweenService:Create(msgScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	task.delay(seconds or 2, function() if msgToken == my then msg.Visible = false end end)
end
local function flash(color, from)
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = from or 0.6
	TweenService:Create(flashFrame, TweenInfo.new(0.45), {BackgroundTransparency = 1}):Play()
end

--------------------------------------------------
-- VFX helpers (pooled by Debris, culled by distance, lighter with reduced effects; telegraphs are never reduced)
--------------------------------------------------
local function far(pos)
	local cam = workspace.CurrentCamera
	return (cam.CFrame.Position - (pos or (ev and ev.Center) or cam.CFrame.Position)).Magnitude > C.VFX.CullDistance
end
local function count(n) return settings.Reduced and math.max(1, math.ceil(n / 3)) or n end
local function anchor(pos, life, size)
	local p = mk("Part", {Name = "FKAnchor", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1,
		Size = size or Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(pos)}, fxFolder)
	if life then Debris:AddItem(p, life) end
	return p
end
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.LightInfluence = 0.15
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent
	return e
end
local function puff(pos, color, n, size, speed)
	if far(pos) then return end
	local a = anchor(pos, 3)
	local e = emitter(a, {Texture = TX.smoke, Color = ColorSequence.new(color or WHITE), Size = NS(size or 2, (size or 2) * 2.2), Transparency = NS(0.25, 1),
		Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(speed or 8, (speed or 8) * 1.6), SpreadAngle = Vector2.new(180, 60),
		Acceleration = Vector3.new(0, 3, 0), Drag = 3, Rate = 0, RotSpeed = NumberRange.new(-60, 60), Rotation = NumberRange.new(0, 360)})
	e:Emit(count(n or 12))
end
local function paint(m, color, transp)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p ~= m.PrimaryPart then p.Color = color; p.Material = Enum.Material.Neon; p.Transparency = transp; p.CastShadow = false end
	end
	return m
end
local function ringModel(pos, r, color, transp)
	local m = paint(Assets.TeleRing:Clone(), color, transp or 0.15)
	m.Parent = fxFolder
	m:ScaleTo(math.max(0.02, r / 10))
	m:PivotTo(CFrame.new(pos))
	return m
end
local function coneModel(origin, dir, range, color, transp)
	local m = paint(Assets.TeleCone:Clone(), color, transp)
	m.Parent = fxFolder
	m:ScaleTo(math.max(0.02, range / 10))
	m:PivotTo(CFrame.lookAt(origin, origin + dir))
	return m
end
local function tpart(props)
	local p = mk("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon,
		TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth}, nil)
	for k, v in pairs(props) do p[k] = v end
	p.Parent = fxFolder
	return p
end
local function disc(pos, r, color, transp)
	return tpart({Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, r * 2, r * 2), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Transparency = transp or 0.55})
end
local function addTele(objs, expire, update) table.insert(tele, {objs = objs, expire = expire, update = update}) end
local function ringFade(pos, r0, r1, dur, color)
	if far(pos) then return end
	local m = ringModel(pos, r0, color or ICE, 0.1)
	local mp = m:FindFirstChildWhichIsA("MeshPart")
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not m.Parent then conn:Disconnect(); return end
		local k = math.min(1, (os.clock() - t0) / dur)
		m:ScaleTo(math.max(0.02, (r0 + (r1 - r0) * smooth(k)) / 10))
		m:PivotTo(CFrame.new(pos))
		if mp then mp.Transparency = 0.1 + 0.9 * k end
		if k >= 1 then conn:Disconnect(); m:Destroy() end
	end)
end
local SHARD = Assets.IceShard:FindFirstChildWhichIsA("MeshPart")
local function shards(pos, n, color)
	if far(pos) or not SHARD then return end
	for i = 1, count(n) do
		local s = SHARD:Clone()
		s.Anchored, s.CanCollide, s.CanQuery, s.CanTouch = true, false, false, false
		if color then s.Color = color end
		s.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		s.Parent = fxFolder
		local dir = Vector3.new(math.random() - 0.5, 0.6 + math.random() * 0.6, math.random() - 0.5).Unit
		local goal = pos + dir * (5 + math.random() * 6)
		TweenService:Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(goal) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)}):Play()
		task.delay(0.5, function()
			if s.Parent then TweenService:Create(s, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = CFrame.new(goal.X, (ev and ev.SnowY) or (goal.Y - 4), goal.Z), Transparency = 1}):Play() end
		end)
		Debris:AddItem(s, 1.2)
	end
end
local RD = GameAudio
local STEPS = RD.Steps or {}
local function sid(x, d) return (type(x) == "table" and x.Id) or d end
local SOUNDS = {
	Arrive = {sid(RD.Start, "rbxassetid://77820131187937"), 0.8, 0.8},
	Sting = {sid(STEPS.Secret, "rbxassetid://102456460734361"), 0.9, 0.75},
	Roar = {"rbxasset://sounds/action_falling.mp3", 1, 0.4},
	Slide = {"rbxasset://sounds/action_swim.mp3", 1, 0.6},
	Throw = {"rbxasset://sounds/action_jump.mp3", 0.8, 0.55},
	Impact = {"rbxasset://sounds/action_jump_land.mp3", 1, 0.75},
	Inhale = {"rbxasset://sounds/action_falling.mp3", 0.6, 1.4},
	Breath = {"rbxasset://sounds/action_falling.mp3", 1, 0.55},
	Stomp = {"rbxasset://sounds/action_jump_land.mp3", 1, 0.3},
	Spin = {"rbxasset://sounds/action_swim.mp3", 0.9, 1.5},
	Hurt = {"rbxasset://sounds/action_get_up.mp3", 0.8, 1.1},
	Phase = {sid(STEPS.Mythic, "rbxassetid://102456460734361"), 0.9, 0.85},
	Victory = {sid(RD.Reveal, "rbxassetid://125078105193243"), 1, 1},
	Escape = {sid(RD.End, "rbxassetid://126698655007674"), 0.9, 0.7},
}
local function sound(name, at, pitch)
	local s = SOUNDS[name]
	if not s then return end
	local parent = at and anchor(at, 8) or gui
	local snd = mk("Sound", {SoundId = s[1], Volume = s[2], PlaybackSpeed = s[3] * (pitch or 1), RollOffMinDistance = 30, RollOffMaxDistance = 420}, parent)
	snd:Play()
	Debris:AddItem(snd, 8)
end
local function shake(power, dur)
	if not settings.Shake or not display.pos then return end
	if (workspace.CurrentCamera.CFrame.Position - display.pos).Magnitude > C.VFX.ShakeDistance then return end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local k = 1 - (os.clock() - t0) / dur
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * power * k, (math.random() - 0.5) * power * k, 0)
			RunService.RenderStepped:Wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end
local function gy(v) return Vector3.new(v.X, ev.SnowY + 0.15, v.Z) end
local function bossPos() return display.pos or (ev and ev.Center) or Vector3.zero end

--------------------------------------------------
-- the penguin
--------------------------------------------------
local function buildModel()
	if model then model:Destroy() end
	model = Assets.FrostKing:Clone()
	rootPart = model.PrimaryPart
	local base = rootPart.CFrame
	parts, crownParts, flipperParts, beakPart = {}, {}, {}, nil
	partList, cfList = {}, {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= rootPart then
			local g = p:GetAttribute("Group") or "Body"
			table.insert(parts, {part = p, group = g, rel = base:ToObjectSpace(p.CFrame)})
			if g == "Crown" then table.insert(crownParts, p) end
			if p.Name == "HeadBeak" and not beakPart then beakPart = p end
			if (g == "FlipperL" or g == "FlipperR") and (not flipperParts[g] or p.Size.Magnitude > flipperParts[g].Size.Magnitude) then flipperParts[g] = p end
		end
	end
	for _, g in ipairs({"FlipperL", "FlipperR", "FootL", "FootR", "Head", "Crown"}) do joints[g] = model:GetAttribute("Joint_" .. g) or Vector3.zero end
	model.Parent = fxFolder
end
local function about(j, rx, ry, rz) return CFrame.new(j) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz)) * CFrame.new(-j) end
local function pose()
	local t = now()
	local pos, dir = display.pos, display.dir
	local lean, roll, lift, spin, twist = 0, 0, 0.3 * math.sin(t * 2.1), 0, 0
	local abdL, abdR = 10 + 6 * math.sin(t * 3), 10 + 6 * math.sin(t * 3 + 0.7)
	local swL, swR, hp, hy = 0, 0, 0, 0
	local state = st and st.State or "Arrival"
	local walking = display.speed > 0.8 and state == "Fight"
	if walking then roll = 5 * math.sin(t * 9); lift += math.abs(math.sin(t * 9)) * 0.4 end
	if ev and t < ev.FightAt then -- rise out of the portal during the last 3 seconds of the arrival
		local k = math.clamp((t - (ev.FightAt - 3)) / 3, 0, 1)
		lift = -26 * (1 - k) ^ 2 + 0.5 * math.sin(t * 30) * (1 - k)
	end
	local a = act
	if a and state == "Fight" then
		local u = t - a.T0
		local W, A, R = a.Windup, a.Active, a.Recover
		local k = a.Kind
		if k == "Slide" then
			if u < W then
				local s = smooth(u / W); lean = 16 * s; swL, swR = -40 * s, -40 * s; roll = math.sin(u * 30) * 1.5 * s
			elseif u < W + A then
				pos = a.Data.From:Lerp(a.Data.To, smooth((u - W) / A)); dir = unitFlat(a.Data.To - a.Data.From)
				lean = -80; lift = -1; swL, swR = -95, -95; abdL, abdR = 15, 15
			elseif u < W + A + R then
				local s = smooth((u - W - A) / R)
				pos = a.Data.To; dir = unitFlat(a.Data.To - a.Data.From); lean = -80 * (1 - s); swL, swR = -95 * (1 - s), -95 * (1 - s)
			end
		elseif k == "Barrage" then
			local s = smooth(math.min(1, u / math.max(0.01, W)))
			abdR = 10 + 140 * s; twist = -10 * s
			for _, b in ipairs(a.Data.Balls) do
				local e = t - b.Launch
				if e >= 0 and e < 0.25 then abdR = 150 - 110 * (e / 0.25); swR = 40 * (e / 0.25); twist = 12 end
			end
		elseif k == "Breath" then
			if u < W then
				local s = smooth(u / W); lean = 12 * s; hp = 25 * s; abdL, abdR = 10 + 35 * s, 10 + 35 * s; lift += 0.5 * s
			elseif u < W + A then
				lean = -8; hp = -12; roll = math.sin(u * 40) * 1.2; abdL, abdR = 40, 40
			elseif u < W + A + R then
				local s = smooth((u - W - A) / R); lean = -8 * (1 - s); hp = -12 * (1 - s)
			end
		elseif k == "Stomp" then
			local jump = a.Data.Jump or 0.6
			if u < W - jump then
				local s = smooth(u / math.max(0.01, W - jump)); lift = -1.2 * s; abdL, abdR = 10 + 40 * s, 10 + 40 * s
			elseif u < W then
				local s = (u - (W - jump)) / jump; lift = 13 * math.sin(math.pi * s); abdL, abdR = 150, 150
			elseif u < W + 0.35 then
				lift = -1.4 * (1 - (u - W) / 0.35); abdL, abdR = 30, 30
			end
		elseif k == "Spin" then
			if u < W then
				local s = smooth(u / W); abdL, abdR = 10 + 78 * s, 10 + 78 * s; lift = -0.6 * s; twist = math.sin(u * 20) * 4 * s
			elseif u < W + A then
				local e = u - W; spin = 900 * e * math.min(1, e / 0.3); abdL, abdR = 88, 88; lift = -0.6
			elseif u < W + A + R then
				local e = u - W - A; roll = 9 * math.sin(e * 6); hy = 18 * math.sin(e * 4); lean = 4 * math.sin(e * 5)
			end
		elseif k == "Stagger" then
			local s = math.min(1, u / math.max(0.01, A))
			roll = 7 * math.sin(u * 22) * (1 - s); lean = 14 * math.sin(s * math.pi); hp = 10 * math.sin(s * math.pi)
		end
	end
	local crownPop
	if state == "Defeat" then
		local u = t - (st.EndAt or t)
		lean = 95 * bounce(math.min(1, u / 1.1)); roll = 0; lift = 0
		abdL, abdR = 120 + 20 * math.sin(u * 14), 120 + 20 * math.sin(u * 14 + 1)
		crownPop = u
	elseif state == "Escape" then
		local u = t - (st.EndAt or t)
		lift = u < 0.5 and 6 * math.sin(math.pi * u / 0.5) or -28 * math.min(1, (u - 0.5) / 1.5)
	end
	local rootCF = CFrame.lookAt(pos, pos + dir) * CFrame.new(0, lift, 0) * CFrame.Angles(0, math.rad(twist), 0)
		* CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(lean), 0, math.rad(roll)) * CFrame.new(0, -7, 0) * CFrame.Angles(0, math.rad(spin), 0)
	local jl, jr = joints.FlipperL, joints.FlipperR
	local g = {
		FlipperL = about(jl, swL, 0, (jl.X >= 0 and 1 or -1) * abdL),
		FlipperR = about(jr, swR, 0, (jr.X >= 0 and 1 or -1) * abdR),
		Head = about(joints.Head, hp, hy, 0),
	}
	local stepA = walking and 14 * math.sin(t * 9) or 0
	g.FootL = about(joints.FootL, stepA, 0, 0)
	g.FootR = about(joints.FootR, -stepA, 0, 0)
	g.Crown = g.Head
	if crownPop then
		local u = math.min(crownPop, 1.1)
		g.Crown = g.Head * CFrame.new(0, 9 * u - 6 * u * u, 5 * u) * about(joints.Crown, u * 140, 0, u * 60)
	end
	rootPart.CFrame = rootCF
	for i, e in ipairs(parts) do
		partList[i] = e.part
		local gx = g[e.group]
		cfList[i] = gx and (rootCF * gx * e.rel) or (rootCF * e.rel)
	end
	workspace:BulkMoveTo(partList, cfList, Enum.BulkMoveMode.FireCFrameChanged)
end

--------------------------------------------------
-- telegraphs
--------------------------------------------------
local function telegraphCircle(pos, r, startT, endT)
	local p = gy(pos)
	local d = disc(p, r, DANGER, 0.6)
	local inner = disc(p + Vector3.new(0, 0.03, 0), 0.2, WARN, 0.3)
	local ring = ringModel(p + Vector3.new(0, 0.06, 0), r, WHITE, 0.1)
	addTele({d, inner, ring}, endT, function(t)
		local k = math.clamp((t - startT) / math.max(0.05, endT - startT), 0, 1)
		inner.Size = Vector3.new(0.12, 2 * r * k, 2 * r * k)
		d.Transparency = 0.5 + 0.15 * math.sin(t * 12)
	end)
end
local function telegraphLane(from, to, width, endT)
	local a, b = gy(from), gy(to)
	local len = math.max(1, (b - a).Magnitude)
	local cf = CFrame.lookAt((a + b) / 2, b)
	local body = tpart({Size = Vector3.new(width, 0.12, len), CFrame = cf, Color = DANGER, Transparency = 0.6})
	local e1 = tpart({Size = Vector3.new(0.45, 0.14, len), CFrame = cf * CFrame.new(width / 2, 0.02, 0), Color = WHITE, Transparency = 0.1})
	local e2 = tpart({Size = Vector3.new(0.45, 0.14, len), CFrame = cf * CFrame.new(-width / 2, 0.02, 0), Color = WHITE, Transparency = 0.1})
	local objs = {body, e1, e2}
	local dv = (b - a).Unit
	for i = 1, 3 do table.insert(objs, coneModel(a + dv * (len * i / 4) + Vector3.new(0, 0.05, 0), dv, 3.5, WHITE, 0.2)) end
	addTele(objs, endT, function(t) body.Transparency = 0.5 + 0.15 * math.sin(t * 14) end)
end
local function telegraphCone(origin, dir, range, endT)
	local m = coneModel(gy(origin), dir, range, DANGER, 0.55)
	local mp = m:FindFirstChildWhichIsA("MeshPart")
	addTele({m}, endT, function(t) if mp then mp.Transparency = 0.45 + 0.15 * math.sin(t * 12) end end)
end
local function telegraphStomp(d, endT)
	local c = gy(d.Center)
	local zone = disc(c, d.MaxRadius, WARN, 0.88)
	local slam = disc(c + Vector3.new(0, 0.02, 0), C.Boss.Radius + 2.5, DANGER, 0.55)
	local objs = {zone, slam}
	local rings = {}
	for i, rs in ipairs(d.Rings) do
		local m = ringModel(c + Vector3.new(0, -60, 0), d.Start, ICE, 0.05)
		rings[i] = {m = m, rs = rs}
		table.insert(objs, m)
	end
	addTele(objs, endT, function(t)
		slam.Transparency = t < d.Rings[1] and (0.45 + 0.15 * math.sin(t * 16)) or 1
		for _, r in ipairs(rings) do
			local e = t - r.rs
			local rad = d.Start + d.Speed * e
			if e >= 0 and rad <= d.MaxRadius then
				r.m:ScaleTo(math.max(0.02, rad / 10))
				r.m:PivotTo(CFrame.new(c + Vector3.new(0, 0.12, 0)))
			else
				r.m:PivotTo(CFrame.new(c + Vector3.new(0, -60, 0)))
			end
		end
	end)
end

--------------------------------------------------
-- attack effects
--------------------------------------------------
local function trailOn(part, offA, offB, life, color)
	local a0 = mk("Attachment", {Position = offA}, part)
	local a1 = mk("Attachment", {Position = offB}, part)
	local tr = mk("Trail", {Attachment0 = a0, Attachment1 = a1, Lifetime = life, Color = ColorSequence.new(color or WHITE), Transparency = NS(0.15, 1),
		LightEmission = 0.5, FaceCamera = true, WidthScale = NS(1, 0.2)}, part)
	return function() tr.Enabled = false; Debris:AddItem(tr, life + 0.1); Debris:AddItem(a0, life + 0.1); Debris:AddItem(a1, life + 0.1) end
end
local function impactFX(pos, big)
	sound("Impact", pos, big and 0.7 or 1)
	if far(pos) then return end
	pcall(VFX.Burst, anchor(pos, 3), "Impact", {Color = WHITE, Scale = big and 2.6 or 1.3})
	puff(pos, WHITE, big and 22 or 12, big and 3 or 2, big and 14 or 8)
	ringFade(pos + Vector3.new(0, 0.2, 0), 1, big and 14 or 7, big and 0.7 or 0.5, ICE)
	shards(pos, big and 6 or 4)
end
local function throwBall(b)
	if not ev then return end
	local from = bossPos() + Vector3.new(0, 16, 0)
	local to = gy(b.Target) + Vector3.new(0, 0.6, 0)
	local ball = Assets.Snowball:Clone()
	ball.Parent = fxFolder
	local main = ball.PrimaryPart
	if not settings.Reduced then
		local a0 = mk("Attachment", {Position = Vector3.new(0, 1.3, 0)}, main)
		local a1 = mk("Attachment", {Position = Vector3.new(0, -1.3, 0)}, main)
		mk("Trail", {Attachment0 = a0, Attachment1 = a1, Lifetime = 0.35, Color = ColorSequence.new(WHITE, ICE), Transparency = NS(0.2, 1), LightEmission = 0.4, FaceCamera = true}, main)
	end
	sound("Throw", from)
	local dur = math.max(0.2, b.Land - now())
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ball.Parent then conn:Disconnect(); return end
		local k = math.min(1, (os.clock() - t0) / dur)
		ball:PivotTo(CFrame.new(from:Lerp(to, k) + Vector3.new(0, math.sin(math.pi * k) * 14, 0)) * CFrame.Angles(k * 9, k * 6, 0))
		if k >= 1 then conn:Disconnect(); ball:Destroy(); impactFX(to, false) end
	end)
end
local function breathFX(a)
	if not ev then return end
	sound("Breath", bossPos())
	local dir = a.Data.Dir
	local o = beakPart and (beakPart.Position + dir * 1.5) or (gy(a.Data.Origin) + Vector3.new(0, 13, 0))
	local base = anchor(o, a.Active + 1.5)
	base.CFrame = CFrame.lookAt(o, o + dir + Vector3.new(0, -0.35, 0))
	local att = mk("Attachment", {}, base)
	local e1 = emitter(att, {Texture = TX.streak, EmissionDirection = Enum.NormalId.Front, Color = ColorSequence.new(WHITE, ICE), Size = NS(2, 4.5), Transparency = NS(0.15, 1),
		Lifetime = NumberRange.new(0.55, 0.8), Speed = NumberRange.new(40, 55), SpreadAngle = Vector2.new(26, 12), Rate = settings.Reduced and 30 or 90, LightEmission = 0.8})
	local e2 = emitter(att, {Texture = TX.star, EmissionDirection = Enum.NormalId.Front, Color = ColorSequence.new(WHITE), Size = NS(0.6, 0.2), Transparency = NS(0, 1),
		Lifetime = NumberRange.new(0.6, 1.0), Speed = NumberRange.new(30, 45), SpreadAngle = Vector2.new(30, 15), Rate = settings.Reduced and 15 or 50,
		RotSpeed = NumberRange.new(-120, 120), LightEmission = 1})
	local beams = {}
	if not settings.Reduced then
		for i = -1, 1 do
			local endPos = gy(a.Data.Origin) + (CFrame.Angles(0, math.rad(i * 18), 0) * dir) * a.Data.Range + Vector3.new(0, 1.5, 0)
			local target = anchor(endPos, a.Active + 1.5)
			local b0 = mk("Attachment", {}, base)
			local b1 = mk("Attachment", {}, target)
			table.insert(beams, mk("Beam", {Attachment0 = b0, Attachment1 = b1, Texture = TX.streak, TextureSpeed = 2.5, TextureLength = 6, TextureMode = Enum.TextureMode.Wrap,
				Width0 = 2.5, Width1 = 9, CurveSize0 = 6 * i, CurveSize1 = -4 * i, Color = ColorSequence.new(ICE), Transparency = NS(0.35, 0.85), LightEmission = 0.7, FaceCamera = true}, base))
		end
	end
	task.delay(a.Active, function() e1.Enabled = false; e2.Enabled = false; for _, b in ipairs(beams) do b.Enabled = false end end)
end
local function patchesFX(a)
	for _, p in ipairs(a.Data.Patches) do
		local d = disc(gy(p), a.Data.PatchRadius, Color3.fromRGB(175, 230, 255), 0.35)
		d.Material = Enum.Material.Ice
		if not settings.Reduced then
			emitter(d, {Texture = TX.star, Color = ColorSequence.new(WHITE), Size = NS(0.5, 0), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(1, 3), Rate = 6, LightEmission = 1})
		end
		local untilT = now() + a.Data.PatchSeconds
		addTele({d}, untilT, function(t) local left = untilT - t; d.Transparency = left < 1 and (0.35 + 0.65 * (1 - left)) or 0.35 end)
	end
end
local function spinFX(a)
	sound("Spin", bossPos())
	local stops = {}
	for _, g in ipairs({"FlipperL", "FlipperR"}) do
		local fp = flipperParts[g]
		if fp then
			local s = fp.Size
			local axis = (s.Y >= s.X and s.Y >= s.Z) and Vector3.new(0, 1, 0) or ((s.X >= s.Z) and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 1))
			local long = math.max(s.X, s.Y, s.Z)
			table.insert(stops, trailOn(fp, axis * long * 0.45, axis * long * 0.1, 0.45, ICE))
		end
	end
	local base = rootPart and mk("Attachment", {Position = Vector3.new(0, 1, 0)}, rootPart)
	local swirl = base and emitter(base, {Texture = TX.smoke, Color = ColorSequence.new(WHITE), Size = NS(2, 4), Transparency = NS(0.3, 1), Lifetime = NumberRange.new(0.5, 0.8),
		Speed = NumberRange.new(14, 22), SpreadAngle = Vector2.new(180, 10), Rate = settings.Reduced and 20 or 60, Drag = 3}) or nil
	task.delay(a.Active, function()
		for _, f in ipairs(stops) do f() end
		if swirl then swirl.Enabled = false end
		if base then Debris:AddItem(base, 1.2) end
	end)
end
local function dizzyFX(a)
	if not rootPart then return end
	local att = mk("Attachment", {Position = Vector3.new(0, 23, 0)}, rootPart)
	local e = emitter(att, {Texture = TX.star, Color = ColorSequence.new(Color3.fromRGB(255, 240, 140)), Size = NS(1.2, 0.6), Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(180, 20), Rate = 10, RotSpeed = NumberRange.new(-200, 200), LightEmission = 1})
	task.delay(a.Recover, function() e.Enabled = false; Debris:AddItem(att, 1.3) end)
end
local function staggerFX()
	sound("Phase", bossPos(), 1.1)
	if crownParts[1] then
		local l = mk("PointLight", {Color = ICE, Range = 24, Brightness = 5}, crownParts[1])
		TweenService:Create(l, TweenInfo.new(1.6), {Brightness = 0}):Play()
		Debris:AddItem(l, 1.7)
	end
	puff(bossPos() + Vector3.new(0, 2, 0), WHITE, 16, 3, 10)
end
local function finalAura()
	if aura or not rootPart then return end
	local ok, h = pcall(VFX.Attach, rootPart, "IceAura", {Color = ICE, Scale = 3})
	aura = ok and h or true
	if crownParts[1] then mk("PointLight", {Color = Color3.fromRGB(170, 140, 255), Range = 26, Brightness = 3}, crownParts[1]) end
	for _, p in ipairs(crownParts) do if p.Material == Enum.Material.Neon then p.Color = Color3.fromRGB(190, 150, 255) end end
end
local function at(a, sec, fn) task.delay(math.max(0, a.T0 + sec - now()), function() if act == a then fn() end end) end
local function onAction(a)
	act = a
	if not ev then return end
	local k = a.Kind
	local endT = a.T0 + a.Windup + a.Active
	if k == "Slide" then
		telegraphLane(a.Data.From, a.Data.To, a.Data.Width, endT)
		sound("Roar", bossPos(), 1.15)
		at(a, a.Windup, function()
			sound("Slide", bossPos())
			if not rootPart then return end
			local stops = {trailOn(rootPart, Vector3.new(4.5, 0.5, 0), Vector3.new(4.5, 2, 0), 1.6, WHITE), trailOn(rootPart, Vector3.new(-4.5, 0.5, 0), Vector3.new(-4.5, 2, 0), 1.6, WHITE)}
			local att = mk("Attachment", {Position = Vector3.new(0, 1, -6)}, rootPart)
			local spray = emitter(att, {Texture = TX.smoke, Color = ColorSequence.new(WHITE), Size = NS(2.5, 5), Transparency = NS(0.2, 1), Lifetime = NumberRange.new(0.5, 0.9),
				Speed = NumberRange.new(10, 18), SpreadAngle = Vector2.new(50, 30), EmissionDirection = Enum.NormalId.Top, Rate = settings.Reduced and 25 or 70, Drag = 2})
			local streak = (not settings.Reduced) and emitter(att, {Texture = TX.streak, Color = ColorSequence.new(ICE), Size = NS(1.2, 0.2), Lifetime = NumberRange.new(0.3, 0.5),
				Speed = NumberRange.new(25, 35), SpreadAngle = Vector2.new(30, 10), EmissionDirection = Enum.NormalId.Back, Rate = 40, LightEmission = 1}) or nil
			task.delay(a.Active, function()
				for _, f in ipairs(stops) do f() end
				spray.Enabled = false
				if streak then streak.Enabled = false end
				Debris:AddItem(att, 1.2)
				if ev then puff(gy(a.Data.To), WHITE, 18, 3, 12) end
			end)
		end)
	elseif k == "Barrage" then
		for _, b in ipairs(a.Data.Balls) do
			telegraphCircle(b.Target, a.Data.Radius, a.T0, b.Land)
			at(a, b.Launch - a.T0, function() throwBall(b) end)
		end
	elseif k == "Breath" then
		telegraphCone(a.Data.Origin, a.Data.Dir, a.Data.Range, endT)
		sound("Inhale", bossPos())
		at(a, a.Windup, function() breathFX(a) end)
		at(a, a.Windup + a.Active, function() patchesFX(a) end)
	elseif k == "Stomp" then
		telegraphStomp(a.Data, endT)
		at(a, a.Windup, function()
			sound("Stomp", gy(a.Data.Center))
			impactFX(gy(a.Data.Center), true)
			shake(1.2, 0.35)
		end)
		if a.Data.Rings[2] then at(a, a.Data.Rings[2] - a.T0, function() sound("Stomp", gy(a.Data.Center), 1.15); puff(gy(a.Data.Center), WHITE, 14, 3, 12) end) end
	elseif k == "Spin" then
		local r = a.Data.Radius
		local d = disc(gy(bossPos()), r, DANGER, 0.6)
		local ring = ringModel(gy(bossPos()) + Vector3.new(0, 0.06, 0), r, WHITE, 0.1)
		addTele({d, ring}, endT, function(t)
			local p = gy(bossPos())
			d.CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90))
			ring:PivotTo(CFrame.new(p + Vector3.new(0, 0.06, 0)))
			d.Transparency = 0.5 + 0.15 * math.sin(t * 14)
		end)
		at(a, a.Windup, function() spinFX(a) end)
		at(a, a.Windup + a.Active, function() dizzyFX(a) end)
	elseif k == "Stagger" then
		staggerFX()
	end
end

--------------------------------------------------
-- arrival, marker, defeat, escape
--------------------------------------------------
local function arrivalFX(s)
	local c = Vector3.new(s.Center.X, s.SnowY, s.Center.Z)
	local portal = Assets.IcePortal:Clone()
	portal.Parent = fxFolder
	local base = CFrame.new(c + Vector3.new(0, 0.1, 0))
	portal:PivotTo(base)
	local spinConn
	spinConn = RunService.RenderStepped:Connect(function()
		if not portal.Parent then spinConn:Disconnect(); return end
		portal:PivotTo(base * CFrame.Angles(0, (os.clock() * 0.6) % (2 * math.pi), 0))
	end)
	local pad = anchor(c + Vector3.new(0, 0.3, 0), nil, Vector3.new(16, 0.2, 16))
	local att = mk("Attachment", {}, pad)
	emitter(att, {Texture = TX["rune-circle"], Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NS(17, 17), Lifetime = NumberRange.new(2, 2.4), Rate = settings.Reduced and 0.8 or 1.6, RotSpeed = NumberRange.new(40, 60), Rotation = NumberRange.new(0, 360),
		LightEmission = 1, Color = ColorSequence.new(ICE), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(1, 1)})})
	emitter(pad, {Texture = TX.smoke, Color = ColorSequence.new(WHITE), Size = NS(1.6, 3.5), Transparency = NS(0.4, 1), Lifetime = NumberRange.new(1.2, 2),
		Speed = NumberRange.new(4, 8), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(15, 15), Rate = settings.Reduced and 6 or 18, Acceleration = Vector3.new(0, 3, 0)})
	emitter(pad, {Texture = TX.star, Color = ColorSequence.new(WHITE, ICE), Size = NS(0.6, 0), Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(6, 12),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(20, 20), Rate = settings.Reduced and 8 or 26, LightEmission = 1})
	local pillar = tpart({Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 5, 5), CFrame = CFrame.new(c + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = ICE, Transparency = 0.65})
	local light = mk("PointLight", {Color = ICE, Range = 40, Brightness = 2}, pillar)
	local s0, dur = os.clock(), math.max(1, s.FightAt - now())
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not pillar.Parent then conn:Disconnect(); return end
		local k = math.min(1, (os.clock() - s0) / dur)
		local h = 2 + 46 * k
		pillar.Size = Vector3.new(h, 5 + 3 * k, 5 + 3 * k)
		pillar.CFrame = CFrame.new(c + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		light.Brightness = 1 + 3 * k
	end)
	task.spawn(function()
		while ev and ev.Id == s.Id and now() < s.FightAt do
			ringFade(c + Vector3.new(0, 0.25, 0), 3, 20, 1.4, ICE)
			task.wait(settings.Reduced and 3 or 1.8)
		end
	end)
	task.delay(math.max(0, s.FightAt - 3 - now()), function()
		if not ev or ev.Id ~= s.Id then return end
		sound("Roar", c)
		shake(0.8, 2.6)
		puff(c, WHITE, 30, 4, 16)
	end)
	task.delay(math.max(0, s.FightAt - now()) + 0.3, function()
		if not ev or ev.Id ~= s.Id then return end
		ringFade(c + Vector3.new(0, 0.3, 0), 4, 32, 1.1, WHITE)
		pcall(VFX.Burst, anchor(c + Vector3.new(0, 2, 0), 3), "PowerUp", {Color = ICE, Scale = 2.4})
		if pillar.Parent then pillar:Destroy() end
		if pad.Parent then pad:Destroy() end
		for _, p in ipairs(portal:GetDescendants()) do if p:IsA("BasePart") then TweenService:Create(p, TweenInfo.new(1.2), {Transparency = 1}):Play() end end
		Debris:AddItem(portal, 1.4)
	end)
end
local function makeMarker(s)
	markerPart = anchor(Vector3.new(s.Center.X, s.SnowY + 30, s.Center.Z))
	local bb = mk("BillboardGui", {Name = "FrostKingMarker", Size = UDim2.fromOffset(250, 70), AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 100000, Adornee = markerPart}, markerPart)
	local bg = decor(mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(30, 60, 120), BackgroundTransparency = 0.25, BorderSizePixel = 0}, bb))
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, bg)
	mk("UIStroke", {Thickness = 2, Color = ICE}, bg)
	markerText = label(bg, "\u{2744} FROST KING", {Size = UDim2.fromScale(0.92, 0.84), Position = UDim2.fromScale(0.04, 0.08)})
end
local function defeatFX()
	sound("Victory")
	showMsg("\u{1F3C6} THE FROST KING IS DEFEATED!", Color3.fromRGB(255, 232, 150), 3)
	task.delay(1.1, function()
		if not model or not display.pos or not ev then return end
		local cpos = crownParts[1] and crownParts[1].Position or (display.pos + Vector3.new(0, 20, 0))
		for _, p in ipairs(crownParts) do p.Transparency = 1 end
		shards(cpos, 10, Color3.fromRGB(190, 240, 255))
		pcall(VFX.Burst, anchor(cpos, 3), "PowerUp", {Color = ICE, Scale = 2.6})
		ringFade(gy(display.pos) + Vector3.new(0, 0.3, 0), 2, 28, 1.2, ICE)
		puff(display.pos + Vector3.new(0, 4, 0), WHITE, 26, 4, 16)
		shake(1.2, 0.4)
		sound("Impact", cpos, 1.4)
	end)
	task.delay(3.4, function()
		if not model then return end
		for _, e in ipairs(parts) do TweenService:Create(e.part, TweenInfo.new(1.2), {Transparency = 1}):Play() end
	end)
end
local function escapeFX()
	sound("Escape")
	showMsg("\u{2744} The Frost King escaped...", ICE, 3)
	if display.pos and ev then puff(display.pos, WHITE, 24, 4, 12); ringFade(gy(display.pos) + Vector3.new(0, 0.3, 0), 2, 20, 1.2, ICE) end
end

--------------------------------------------------
-- announcement, JOIN, toggles
--------------------------------------------------
local function busy()
	if player:GetAttribute("IntroActive") or player:GetAttribute("IntroPlaying") then return true end
	local pg = player:FindFirstChild("PlayerGui")
	local rd = pg and pg:FindFirstChild("RareDropGui")
	if rd and rd.Enabled then return true end
	local cam = workspace.CurrentCamera
	local blur = cam and cam:FindFirstChild("HatchBlur")
	if blur and blur.Enabled and blur.Size > 1 then return true end
	return false
end
local function canJoinLocal()
	if not ev then return false end
	if ev.Style == "Starter" then return ev.World ~= 2 end
	return player:GetAttribute("Stage_" .. ev.Style) == true
end
local function refreshJoin()
	local ok = canJoinLocal()
	for _, pair in ipairs({{joinBtn, joinText}, {pillJoin, pillJoinText}}) do
		pair[1].BackgroundColor3 = ok and GREEN or GREY
		pair[2].Text = ok and "JOIN" or "\u{1F512} LOCKED"
	end
	return ok
end
local function showAnnouncement()
	if not ev or dismissed then return end
	if player:GetAttribute("SuppressEvents") == true then return end -- 2026-10-05: an essential tutorial step is showing (the pill still offers JOIN)
	local ok = refreshJoin()
	annSub.Text = ok and ("Giant Penguin spotted in %s!"):format(ev.Name) or ("Giant Penguin spotted in %s! (unlock it to join)"):format(ev.Name)
	ann.Visible = true
	annScale.Scale = 0.55
	TweenService:Create(annScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	sound("Arrive")
	task.delay(0.35, function() sound("Sting") end)
	local my = ev.Id
	task.delay(14, function() if ev and ev.Id == my then ann.Visible = false end end)
end
local function queueAnnouncement()
	local my = ev.Id
	task.spawn(function()
		local waited = 0
		while ev and ev.Id == my and busy() and waited < 90 do task.wait(0.5); waited += 0.5 end
		if ev and ev.Id == my and st and (st.State == "Arrival" or st.State == "Fight") then showAnnouncement() end
	end)
end
local joining = false
local function doJoin()
	if not ev or joining then return end
	if not canJoinLocal() then showMsg(("Unlock %s to join!"):format(ev.Name), WARN, 2.5) return end
	joining = true
	local ok, res, text = pcall(function() return joinFn:InvokeServer("Join") end)
	joining = false
	if ok and res then ann.Visible = false; showMsg("\u{2744} To battle!", ICE, 1.6) else showMsg(tostring((ok and text) or "Couldn't join right now."), WARN, 2.5) end
end
joinBtn.Activated:Connect(doJoin)
pillJoin.Activated:Connect(doJoin)
laterBtn.Activated:Connect(function() ann.Visible = false; dismissed = true end)
rewardOk.Activated:Connect(function() rewardPanel.Visible = false end)
local function refreshToggles()
	fxText.Text = settings.Reduced and "FX LOW" or "FX"
	shakeText.Text = settings.Shake and "SHAKE" or "NO SHAKE"
end
fxBtn.Activated:Connect(function() settings.Reduced = not settings.Reduced; refreshToggles() end)
shakeBtn.Activated:Connect(function() settings.Shake = not settings.Shake; refreshToggles() end)
refreshToggles()
task.spawn(function() -- the existing "reduced effects" choice (Treasures settings) also lowers boss effects
	local tr = RS:WaitForChild("TreasureRemote", 15)
	if not tr then return end
	local ok, d = pcall(function() return tr:InvokeServer("Get") end)
	if ok and type(d) == "table" and d.Reduced then settings.Reduced = true; refreshToggles() end
end)

--------------------------------------------------
-- server messages
--------------------------------------------------
local function cleanupAll()
	for _, e in ipairs(tele) do for _, o in ipairs(e.objs) do if o and o.Parent then o:Destroy() end end end
	tele = {}
	fxFolder:ClearAllChildren()
	model, rootPart, beakPart, markerPart, markerText, aura = nil, nil, nil, nil, nil, nil
	parts, crownParts, flipperParts, partList, cfList = {}, {}, {}, {}, {}
	ann.Visible, pill.Visible, bar.Visible, mePanel.Visible, hint.Visible = false, false, false, false, false
	act, me, ev, st, lastState = nil, nil, nil, nil, nil
	display.pos = nil
end
local function onSpawn(s)
	cleanupAll()
	ev = s
	dismissed = false
	st = {State = "Arrival", Pos = s.Center, Facing = unitFlat(s.Entry - s.Center), Phase = 1, HP = 1, MaxHP = 1, Ends = s.Ends}
	lastState = "Arrival"
	buildModel()
	if now() < s.FightAt then arrivalFX(s) end
	makeMarker(s)
	queueAnnouncement()
end
local function onState(s)
	if not ev then return end
	st = s
	if s.State ~= lastState then
		local prev = lastState
		lastState = s.State
		if s.State == "Defeat" then act = nil; defeatFX()
		elseif s.State == "Escape" then act = nil; escapeFX()
		elseif s.State == "Fight" and prev == "Arrival" then showMsg("\u{2744} THE FROST KING ATTACKS!", ICE, 2) end
	end
	if (s.Phase or 1) >= 3 and s.State == "Fight" then finalAura() end
end
local knockToken = 0
local function onReward(r)
	local lines = {}
	if r.Qualified then
		table.insert(lines, ("+%s \u{2744} Snow"):format(Format.Abbreviate(r.Snow or 0)))
		if r.Treasure then table.insert(lines, "\u{1F48E} Treasure: " .. tostring(r.Treasure)) end
		if r.Boost then
			local nm = r.Boost == "Snow2" and "2x Snow" or (r.Boost == "Luck2" and "2x Luck" or tostring(r.Boost))
			table.insert(lines, ("\u{26A1} %s for %d min"):format(nm, math.floor((r.BoostSeconds or 0) / 60)))
		end
	else
		table.insert(lines, ("Fight longer next time to earn rewards!\n(%d/%d s near the boss, %d/%d s hitting it)"):format(r.Engaged or 0, r.NeedEngaged or 0, r.Hit or 0, r.NeedHit or 0))
	end
	rewardTitle.Text = r.Result == "Victory" and "\u{1F3C6} VICTORY!" or "\u{2744} IT ESCAPED"
	rewardTitle.TextColor3 = r.Result == "Victory" and Color3.fromRGB(255, 232, 150) or ICE
	rewardLines.Text = table.concat(lines, "\n")
	rewardPanel.Visible = true
	rewardScale.Scale = 0.5
	TweenService:Create(rewardScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	if r.Qualified and r.Result == "Victory" then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then pcall(VFX.Burst, hrp, "PowerUp", {Color = Color3.fromRGB(255, 225, 120), Scale = 1.4}) end
	end
	task.delay(9, function() rewardPanel.Visible = false end)
end
event.OnClientEvent:Connect(function(m)
	if type(m) ~= "table" then return end
	local kind = m.T
	if kind == "Spawn" then
		onSpawn(m)
	elseif kind == "State" then
		onState(m)
	elseif kind == "Action" then
		if ev then onAction(m) end
	elseif kind == "Phase" then
		sound("Phase", display.pos)
		showMsg(m.Phase >= 3 and "\u{2744} FINAL PHASE! \u{2744}" or "PHASE II - it's getting angry!", m.Phase >= 3 and Color3.fromRGB(210, 170, 255) or ICE, 2.2)
		if m.Phase >= 3 then finalAura() end
	elseif kind == "Hit" then
		if m.Frost then flash(ICE, 0.82) else flash(DANGER, 0.55); sound("Hurt"); shake(0.5, 0.2) end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and m.Push then hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity * 0.3 + m.Push end
		if me then me.HP = m.HP end
	elseif kind == "Knocked" then
		knockToken += 1
		local my, untilT = knockToken, m.Until
		task.spawn(function()
			while knockToken == my and now() < untilT do
				showMsg(("KNOCKED OUT! Back in %d..."):format(math.ceil(untilT - now())), WARN, 1.1)
				task.wait(1)
			end
		end)
	elseif kind == "Recovered" then
		knockToken += 1
		showMsg("\u{2744} Back in the fight!", ICE, 1.5)
	elseif kind == "Me" then
		me = m
	elseif kind == "Reward" then
		onReward(m.Reward or {})
	elseif kind == "Cleanup" then
		cleanupAll()
	end
end)
task.spawn(function()
	local ok, snap = pcall(function() return joinFn:InvokeServer("Sync") end)
	if ok and type(snap) == "table" and snap.Spawn then
		onSpawn(snap.Spawn)
		if snap.State then onState(snap.State) end
		if snap.Action then onAction(snap.Action) end
	end
end)

--------------------------------------------------
-- every frame
--------------------------------------------------
local function hud()
	local t = now()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local pd = hrp and flat(hrp.Position - ev.Center).Magnitude or math.huge
	local near = pd < math.max(ev.W, ev.D) * 0.7 + 25
	local state = st and st.State or "Arrival"
	local live = state == "Arrival" or state == "Fight"
	if ann.Visible then
		annTime.Text = state == "Arrival" and ("Battle starts in " .. fmtTime(ev.FightAt - t)) or ("Battle in progress \u{2022} " .. fmtTime((st.Ends or t) - t) .. " left")
	end
	pill.Visible = live and not ann.Visible and not near
	if pill.Visible then
		pillText.Text = ("\u{2744} FROST KING \u{2022} %s"):format(state == "Arrival" and fmtTime(ev.FightAt - t) or fmtTime((st.Ends or t) - t))
	end
	bar.Visible = (near or me ~= nil) and (live or state == "Defeat")
	if bar.Visible and st then
		local f = math.clamp((st.HP or 0) / math.max(1, st.MaxHP or 1), 0, 1)
		fill.Size = UDim2.fromScale(state == "Arrival" and 1 or f, 1)
		hpText.Text = state == "Arrival" and "ARRIVING..." or ("%d%%"):format(math.ceil(f * 100))
		local ph = st.Phase or 1
		barPhase.Text = ph >= 3 and "FINAL PHASE" or (ph == 2 and "PHASE II" or "PHASE I")
		barPhase.TextColor3 = ph >= 3 and Color3.fromRGB(210, 170, 255) or ICE
		barTime.Text = state == "Arrival" and fmtTime(ev.FightAt - t) or fmtTime((st.Ends or t) - t)
		fillGrad.Color = ph >= 3 and ColorSequence.new(Color3.fromRGB(205, 150, 255), Color3.fromRGB(125, 70, 255)) or ColorSequence.new(Color3.fromRGB(120, 220, 255), Color3.fromRGB(60, 140, 255))
	end
	mePanel.Visible = me ~= nil and live
	if mePanel.Visible then
		local hpv = math.max(0, me.HP or 0)
		meHPFill.Size = UDim2.fromScale(math.clamp(hpv / (me.MaxHP or 100), 0, 1), 1)
		meHPText.Text = ("\u{2764} %d / %d"):format(math.ceil(hpv), me.MaxHP or 100)
		mePart.Text = me.Qualified and "\u{2714} Qualified for rewards!" or ("Fight %d/%ds \u{2022} Hit %d/%ds"):format(math.floor(me.Engaged or 0), me.NeedEngaged or 0, math.floor(me.Hit or 0), me.NeedHit or 0)
		mePart.TextColor3 = me.Qualified and Color3.fromRGB(160, 255, 170) or WHITE
		meReward.Text = ("Reward \u{2248} %s \u{2744}"):format(Format.Abbreviate(me.Reward or 0))
	end
	if markerPart then
		markerPart.Parent = live and fxFolder or nil
		if markerText then markerText.Text = ("\u{2744} FROST KING\n%s"):format(pd < 1e6 and (math.floor(pd) .. " studs") or ev.Name) end
	end
	local show = false
	if act and act.Kind == "Stomp" and hrp and state == "Fight" then
		local d = flat(hrp.Position - act.Data.Center).Magnitude
		for _, rs in ipairs(act.Data.Rings) do
			local rad = act.Data.Start + act.Data.Speed * (t - rs)
			if t >= rs - 0.6 and d <= act.Data.MaxRadius + 1 and d > rad - 1 and (d - rad) / act.Data.Speed < 0.8 then show = true end
		end
	end
	hint.Visible = show
end
local hudAcc = 0
RunService.RenderStepped:Connect(function(dt)
	if not ev then return end
	if st and st.Pos then
		if not display.pos then display.pos = st.Pos; display.dir = unitFlat(st.Facing or display.dir) end
		local prev = display.pos
		display.pos = display.pos:Lerp(st.Pos, 1 - math.exp(-dt * 6))
		display.dir = unitFlat(display.dir:Lerp(unitFlat(st.Facing or display.dir), 1 - math.exp(-dt * 5)))
		display.speed = flat(display.pos - prev).Magnitude / math.max(dt, 1e-3)
	end
	if model and rootPart and display.pos then pcall(pose) end
	local t = now()
	for i = #tele, 1, -1 do
		local e = tele[i]
		if t >= e.expire then
			for _, o in ipairs(e.objs) do if o and o.Parent then o:Destroy() end end
			table.remove(tele, i)
		elseif e.update then
			pcall(e.update, t)
		end
	end
	hudAcc += dt
	if hudAcc >= 0.1 then hudAcc = 0; pcall(hud) end
end)
