-- ArenaHudClient (2026-10-05, Claude): Snowplow Bumper Arena UI + feedback. Only active on the arena island (InArenaIsland).
-- Timer / your score / compact standings, JOIN + LEAVE ARENA, BOOST + BRACE with cooldowns (keyboard, controller, big touch
-- buttons clear of the thumbstick and safe areas), knockout + respawn messages with an overview camera, spawn-shield indicator,
-- results card, first-time intro (points at the ability buttons and the exits), exit danger markers, restrained impact effects.
-- Movement and abilities live in ArenaDriveClient; the server (ArenaService) decides every hit, knockout and score.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local A = require(RS:WaitForChild("ArenaConfig"))
local remote = RS:WaitForChild("ArenaRemote")
local event = RS:WaitForChild("ArenaEvent")
local folder = workspace:WaitForChild("ArenaVehicles")
local okTX, VFX = pcall(function() return require(RS:WaitForChild("UniversalVFX", 5)) end)
local TX = okTX and VFX and VFX.Textures or {}
local now = function() return workspace:GetServerTimeNow() end
local driveApi = script.Parent:WaitForChild("ArenaDriveClient"):WaitForChild("ArenaDriveApi", 10)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local GREEN, RED, BLUE, GOLD, ORANGE = Color3.fromRGB(70, 200, 105), Color3.fromRGB(235, 90, 100), Color3.fromRGB(70, 150, 245), Color3.fromRGB(255, 205, 70), Color3.fromRGB(255, 150, 50)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function stroke(o, t) mk("UIStroke", {Thickness = t or 2.5, Color = NAVY, ApplyStrokeMode = o:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border}, o) end
local function corner(o, r) mk("UICorner", {CornerRadius = UDim.new(r or 0.3, 0)}, o) end
local function label(parent, text, props)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = WHITE, Text = text or ""}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	stroke(l, 2.2)
	return l
end
local function button(parent, name, text, color, props)
	local b = mk("TextButton", {Name = name, Text = "", AutoButtonColor = true, BackgroundColor3 = color, BorderSizePixel = 0}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	b:SetAttribute("SnowUIDecor", true)
	corner(b, 0.3); stroke(b, 3)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 215, 235))}, b)
	local l = label(b, text, {Name = "Label", Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76)})
	return b, l
end

local gui = mk("ScreenGui", {Name = "ArenaHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 120, Enabled = false,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))

-- top: phase + timer + your score
local top = mk("Frame", {Name = "Timer", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.015), Size = UDim2.fromScale(0.26, 0.105),
	BackgroundColor3 = Color3.fromRGB(18, 73, 122), BackgroundTransparency = 0.08}, gui)
corner(top, 0.25); stroke(top, 3)
mk("UISizeConstraint", {MinSize = Vector2.new(250, 70)}, top)
local phaseL = label(top, "", {Name = "Phase", Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.92, 0.32), TextColor3 = Color3.fromRGB(190, 225, 255)})
local timeL = label(top, "", {Name = "Time", Position = UDim2.fromScale(0.04, 0.36), Size = UDim2.fromScale(0.5, 0.58), TextXAlignment = Enum.TextXAlignment.Left})
local scoreL = label(top, "", {Name = "Score", Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.46, 0.58), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = GOLD})
local shieldBar = mk("Frame", {Name = "Shield", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 6), Size = UDim2.fromScale(0.8, 0.3),
	BackgroundColor3 = Color3.fromRGB(120, 200, 255), Visible = false}, top)
corner(shieldBar, 0.5); stroke(shieldBar, 2)
local shieldFill = mk("Frame", {Name = "Fill", BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1)}, shieldBar)
corner(shieldFill, 0.5)
label(shieldBar, "PROTECTED", {Size = UDim2.fromScale(1, 1), ZIndex = 2})

-- right: compact standings
local board = mk("Frame", {Name = "Standings", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.985, 0.2), Size = UDim2.fromScale(0.16, 0.3),
	BackgroundTransparency = 1}, gui)
mk("UISizeConstraint", {MinSize = Vector2.new(150, 120)}, board)
mk("UIListLayout", {Padding = UDim.new(0.015, 0), SortOrder = Enum.SortOrder.LayoutOrder}, board)
local rows = {}
for i = 1, 6 do
	local r = mk("Frame", {Name = "Row" .. i, Size = UDim2.fromScale(1, 0.14), BackgroundColor3 = Color3.fromRGB(18, 73, 122), BackgroundTransparency = 0.15, LayoutOrder = i, Visible = false}, board)
	corner(r, 0.35); stroke(r, 2)
	local n = label(r, "", {Name = "Name", Position = UDim2.fromScale(0.05, 0.12), Size = UDim2.fromScale(0.7, 0.76), TextXAlignment = Enum.TextXAlignment.Left})
	local s = label(r, "", {Name = "Score", Position = UDim2.fromScale(0.75, 0.12), Size = UDim2.fromScale(0.2, 0.76), TextColor3 = GOLD})
	rows[i] = {frame = r, name = n, score = s}
end
local feed = mk("Frame", {Name = "Feed", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.985, 0.52), Size = UDim2.fromScale(0.2, 0.14), BackgroundTransparency = 1}, gui)
mk("UIListLayout", {Padding = UDim.new(0.04, 0), VerticalAlignment = Enum.VerticalAlignment.Top}, feed)

-- bottom-left: leave + paint
local leaveB = button(gui, "LeaveButton", "LEAVE ARENA", RED, {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0.012, touch and 0.6 or 0.97), Size = UDim2.fromScale(touch and 0.17 or 0.12, touch and 0.075 or 0.06)})
mk("UISizeConstraint", {MinSize = Vector2.new(touch and 140 or 120, touch and 46 or 38)}, leaveB)
local paintB, paintL = button(gui, "PaintButton", "PAINT", BLUE, {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0.012, touch and 0.51 or 0.9), Size = UDim2.fromScale(touch and 0.12 or 0.085, touch and 0.06 or 0.05)})
mk("UISizeConstraint", {MinSize = Vector2.new(96, 32)}, paintB)

-- bottom-centre: join + status
local joinB, joinL = button(gui, "JoinButton", "JOIN MATCH", GREEN, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.fromScale(0.2, 0.09)})
mk("UISizeConstraint", {MinSize = Vector2.new(200, 56)}, joinB)
local statusL = label(gui, "", {Name = "Status", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.965), Size = UDim2.fromScale(0.5, 0.045), TextColor3 = Color3.fromRGB(230, 242, 255)})

-- bottom-right: abilities (big round touch buttons above the jump-button area)
local function abilityButton(name, text, color, pos, size)
	local b = mk("TextButton", {Name = name, Text = "", AutoButtonColor = true, BackgroundColor3 = color, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size,
		SizeConstraint = Enum.SizeConstraint.RelativeYY}, gui)
	corner(b, 0.5); stroke(b, 3.5)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 215, 235))}, b)
	local cd = mk("Frame", {Name = "Cooldown", BackgroundColor3 = Color3.fromRGB(10, 20, 45), BackgroundTransparency = 0.35, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), ZIndex = 2}, b)
	corner(cd, 0.5)
	local l = label(b, text, {Name = "Label", Position = UDim2.fromScale(0.12, 0.26), Size = UDim2.fromScale(0.76, 0.34), ZIndex = 3})
	local k = label(b, "", {Name = "Key", Position = UDim2.fromScale(0.25, 0.6), Size = UDim2.fromScale(0.5, 0.2), ZIndex = 3, TextColor3 = Color3.fromRGB(230, 240, 255)})
	local t = label(b, "", {Name = "Secs", Position = UDim2.fromScale(0.2, 0.2), Size = UDim2.fromScale(0.6, 0.6), ZIndex = 4, Visible = false})
	return {button = b, cd = cd, label = l, key = k, secs = t}
end
local boostU = abilityButton("BoostButton", "BOOST", ORANGE, touch and UDim2.fromScale(0.84, 0.5) or UDim2.fromScale(0.9, 0.8), touch and UDim2.fromScale(0.24, 0.24) or UDim2.fromScale(0.15, 0.15))
local braceU = abilityButton("BraceButton", "BRACE", BLUE, touch and UDim2.fromScale(0.68, 0.68) or UDim2.fromScale(0.8, 0.88), touch and UDim2.fromScale(0.17, 0.17) or UDim2.fromScale(0.11, 0.11))

-- centre: banner + respawn
local banner = label(gui, "", {Name = "Banner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.6, 0.08), TextTransparency = 1})
local bannerStroke = banner:FindFirstChildOfClass("UIStroke")
local sub = label(gui, "", {Name = "Sub", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromScale(0.5, 0.05), TextTransparency = 1})
local subStroke = sub:FindFirstChildOfClass("UIStroke")
local bannerToken = 0
local function flash(text, color, subText, dur)
	bannerToken += 1
	local my = bannerToken
	banner.Text, banner.TextColor3, banner.TextTransparency, bannerStroke.Transparency = text, color or WHITE, 0, 0
	sub.Text, sub.TextTransparency, subStroke.Transparency = subText or "", subText and 0 or 1, subText and 0 or 1
	banner.Size = UDim2.fromScale(0.5, 0.065)
	TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = UDim2.fromScale(0.6, 0.08)}):Play()
	task.delay(dur or 2, function()
		if bannerToken ~= my then return end
		for _, o in ipairs({banner, sub}) do TweenService:Create(o, TweenInfo.new(0.4), {TextTransparency = 1}):Play() end
		TweenService:Create(bannerStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
		TweenService:Create(subStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
	end)
end
local function feedLine(text)
	local l = label(feed, text, {Size = UDim2.fromScale(1, 0.3), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(230, 240, 255)})
	task.delay(4, function() TweenService:Create(l, TweenInfo.new(0.5), {TextTransparency = 1}):Play(); Debris:AddItem(l, 0.6) end)
	local kids = {}
	for _, c in ipairs(feed:GetChildren()) do if c:IsA("TextLabel") then table.insert(kids, c) end end
	if #kids > 3 then kids[1]:Destroy() end
end

-- results card
local results = mk("Frame", {Name = "Results", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.36, 0.5),
	BackgroundColor3 = Color3.fromRGB(18, 73, 122), Visible = false}, gui)
corner(results, 0.06); stroke(results, 3.5)
mk("UISizeConstraint", {MinSize = Vector2.new(300, 260)}, results)
local resTitle = label(results, "ROUND OVER", {Position = UDim2.fromScale(0.05, 0.03), Size = UDim2.fromScale(0.9, 0.13), TextColor3 = GOLD})
local resList = mk("Frame", {Position = UDim2.fromScale(0.06, 0.18), Size = UDim2.fromScale(0.88, 0.62), BackgroundTransparency = 1}, results)
mk("UIListLayout", {Padding = UDim.new(0.02, 0)}, resList)
local resNote = label(results, "", {Position = UDim2.fromScale(0.05, 0.84), Size = UDim2.fromScale(0.9, 0.1), TextColor3 = Color3.fromRGB(200, 225, 255)})

-- intro card
local intro = mk("Frame", {Name = "Intro", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromScale(0.42, 0.2),
	BackgroundColor3 = Color3.fromRGB(18, 73, 122), Visible = false, ZIndex = 5}, gui)
corner(intro, 0.12); stroke(intro, 3.5)
mk("UISizeConstraint", {MinSize = Vector2.new(320, 130)}, intro)
local introTitle = label(intro, "", {Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.9, 0.36), TextColor3 = GOLD, ZIndex = 6})
local introText = label(intro, "", {Position = UDim2.fromScale(0.05, 0.42), Size = UDim2.fromScale(0.9, 0.26), ZIndex = 6})
local introOk = button(intro, "OkButton", "OK!", GREEN, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromScale(0.26, 0.22), ZIndex = 6})
local pointers = {}
local function pointerAt(target, text)
	local p = mk("Frame", {Name = "Pointer", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(120, 90), ZIndex = 7}, gui)
	local arrow = mk("TextLabel", {BackgroundTransparency = 1, Text = "\u{25BC}", Font = FONT, TextScaled = true, TextColor3 = GOLD, Size = UDim2.fromScale(1, 0.6), Position = UDim2.fromScale(0, 0.4), ZIndex = 7}, p)
	stroke(arrow, 3)
	label(p, text, {Size = UDim2.fromScale(1, 0.4), ZIndex = 7, TextColor3 = GOLD})
	local ring = mk("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 7}, gui)
	corner(ring, 0.5)
	mk("UIStroke", {Thickness = 4, Color = GOLD}, ring)
	table.insert(pointers, {frame = p, ring = ring, target = target})
end
local function clearPointers() for _, p in ipairs(pointers) do p.frame:Destroy(); p.ring:Destroy() end table.clear(pointers) end

-- world: exit danger markers (always readable, brighter when you're close to one)
local exitMarks = {}
local function buildExitMarks()
	for _, m in ipairs(exitMarks) do m.gui:Destroy() end
	table.clear(exitMarks)
	for _, g in ipairs(A.Exits) do
		local rad = math.rad(g)
		local p = A.Center + Vector3.new(math.cos(rad), 0, math.sin(rad)) * (A.WallInner + 1.5) + Vector3.new(0, 9, 0)
		local anchor = mk("Part", {Name = "ExitMark", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(p)}, workspace.CurrentCamera)
		local bb = mk("BillboardGui", {Size = UDim2.fromOffset(150, 60), AlwaysOnTop = false, MaxDistance = 260, LightInfluence = 0}, anchor)
		local t = label(bb, "\u{26A0} EXIT", {Size = UDim2.fromScale(1, 1), TextColor3 = Color3.fromRGB(255, 210, 60)})
		table.insert(exitMarks, {gui = anchor, label = t, pos = p})
	end
end

-- impacts: compact ice burst + thump; boosted hits are bigger, blocked hits show a shield ring
local fxPart = mk("Part", {Name = "ArenaFx", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one}, workspace.CurrentCamera)
local function burst(pos, big, color)
	local a = mk("Attachment", {WorldPosition = pos}, fxPart)
	local e = mk("ParticleEmitter", {Texture = TX.smoke or "rbxasset://textures/particles/smoke_main.dds", Rate = 0, Lifetime = NumberRange.new(0.35, 0.7),
		Speed = NumberRange.new(big and 18 or 9, big and 30 or 16), SpreadAngle = Vector2.new(70, 40), Drag = 4, LightEmission = 0.3,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, big and 1.8 or 1.1), NumberSequenceKeypoint.new(1, big and 4 or 2.4)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1)}),
		Color = ColorSequence.new(WHITE, color or Color3.fromRGB(190, 230, 255))}, a)
	e:Emit(big and 26 or 12)
	local s = mk("Sound", {SoundId = "rbxassetid://12221976", Volume = big and 0.9 or 0.45, PlaybackSpeed = big and 0.55 or 0.8, RollOffMaxDistance = 160}, a)
	s:Play()
	Debris:AddItem(a, 1.2)
end
local function flashVehicle(userId, color)
	local m = folder:FindFirstChild("Arena_" .. tostring(userId))
	if not m then return end
	local h = mk("Highlight", {FillColor = color, FillTransparency = 0.45, OutlineTransparency = 0.2, OutlineColor = WHITE, DepthMode = Enum.HighlightDepthMode.Occluded}, m)
	Debris:AddItem(h, 0.18)
end
local shake = 0
RunService:BindToRenderStep("ArenaShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if shake <= 0 then return end
	shake = math.max(0, shake - dt)
	local k = shake * 1.6
	local cam = workspace.CurrentCamera
	cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0)
end)

-- state
local state = {phase = "Idle", standings = {}}
local joined = false
local pendingConfirm = 0
local respawnAt
local camHeld = false
local function myHull()
	local m = folder:FindFirstChild("Arena_" .. player.UserId)
	return m and m.PrimaryPart
end
local function fmtTime(s) s = math.max(0, math.ceil(s)); return string.format("%d:%02d", s // 60, s % 60) end
local function inputKind()
	local t = UIS:GetLastInputType()
	if t == Enum.UserInputType.Touch then return "touch" end
	if t.Name:find("Gamepad") then return "pad" end
	return "keys"
end
local function refreshKeys()
	local k = inputKind()
	boostU.key.Text = k == "pad" and "R1" or (k == "keys" and "SPACE" or "")
	braceU.key.Text = k == "pad" and "L1" or (k == "keys" and "Q" or "")
end
UIS.LastInputTypeChanged:Connect(refreshKeys)
refreshKeys()

local function ask(action, ...)
	local ok, res = pcall(function(...) return remote:InvokeServer(action, ...) end, ...)
	return ok and type(res) == "table" and res or {ok = false}
end
local function setCameraOverview(on)
	local cam = workspace.CurrentCamera
	if on then
		camHeld = true
		cam.CameraType = Enum.CameraType.Scriptable
		local c = A.Center
		TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {CFrame = CFrame.lookAt(c + Vector3.new(0, 70, -95), c)}):Play()
	elseif camHeld then
		camHeld = false
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
	end
end
local function renderStandings()
	local st = state.standings or {}
	for i, r in ipairs(rows) do
		local s = st[i]
		r.frame.Visible = s ~= nil and (state.phase ~= "Idle")
		if s then
			r.name.Text = i .. ". " .. s.name
			r.score.Text = tostring(s.score)
			r.frame.BackgroundColor3 = s.userId == player.UserId and Color3.fromRGB(40, 120, 70) or Color3.fromRGB(18, 73, 122)
		end
	end
	local mine = 0
	for _, s in ipairs(st) do if s.userId == player.UserId then mine = s.score end end
	scoreL.Text = joined and state.phase ~= "Idle" and ("YOU: " .. mine) or ""
end

local introStep = 0
local function showIntro(step)
	introStep = step
	clearPointers()
	if step == 1 then
		introTitle.Text = "Ram rivals. Use BOOST. Push them out!"
		introText.Text = touch and "Steer with the stick. Tap BOOST to charge, BRACE to resist a hit." or "Drive with WASD. BOOST = Space, BRACE = Q (controller: R1 / L1)."
		pointerAt(boostU.button, "BOOST")
		pointerAt(braceU.button, "BRACE")
	elseif step == 2 then
		introTitle.Text = "Watch the EXITS!"
		introText.Text = "Pushed through a striped exit gap = knocked out (back in 4 s). The pusher scores!"
		for _, m in ipairs(exitMarks) do m.label.TextColor3 = Color3.fromRGB(255, 120, 60) end
	end
	intro.Visible = true
end
introOk.Activated:Connect(function()
	if introStep == 1 then showIntro(2) else
		intro.Visible = false; clearPointers(); introStep = 0
		task.spawn(ask, "Intro")
	end
end)

local function refreshJoin()
	local hull = myHull()
	joinB.Visible = not joined
	local s = state
	if not joined then
		joinL.Text = os.clock() < pendingConfirm and "TAP AGAIN TO JOIN" or "JOIN MATCH"
		statusL.Text = s.phase == "Active" and ("Match in progress - " .. (s.count or 0) .. "/" .. A.Players.Max .. " drivers. Join to practise and play the next round!") or
			("Drivers: " .. (s.count or 0) .. "/" .. A.Players.Max .. " - watch from the stands or join!")
	else
		local zone = hull and hull:GetAttribute("Zone")
		if zone == "practice" then statusL.Text = "Practice ring - you're in the next round (" .. (s.waiting or 0) .. " waiting)"
		elseif s.phase == "Idle" then statusL.Text = "Waiting for another driver - practise on the targets!"
		else statusL.Text = "" end
	end
end
joinB.Activated:Connect(function()
	local r = ask("Join", os.clock() < pendingConfirm) -- the second tap within 6 s confirms
	if r.needConfirm then
		pendingConfirm = os.clock() + 6
		joinL.Text = "TAP AGAIN TO JOIN"
		flash("Joining cancels your Help Yard job", GOLD, r.msg, 3)
		return
	end
	pendingConfirm = 0
	if r.ok then joined = true; if r.msg then flash(r.msg, GOLD, nil, 3) end end
	refreshJoin()
end)
leaveB.Activated:Connect(function() ask("Leave") end)
paintB.Activated:Connect(function()
	local cur = player:GetAttribute("ArenaPaint") or "Classic"
	local idx = 1
	for i, p in ipairs(A.Paints) do if p.Id == cur then idx = i end end
	for k = 1, #A.Paints do
		local p = A.Paints[(idx + k - 1) % #A.Paints + 1]
		local r = ask("Paint", p.Id)
		if r.ok then flash("Paint: " .. p.Name, p.Color, nil, 1.5) return end
	end
	flash("Win arena matches to unlock paints!", GOLD, nil, 2)
end)
boostU.button.Activated:Connect(function() if driveApi then driveApi:Invoke("Use", "Boost") end end)
braceU.button.Activated:Connect(function() if driveApi then driveApi:Invoke("Use", "Brace") end end)

event.OnClientEvent:Connect(function(kind, d)
	if not gui.Enabled and kind ~= "State" then return end
	d = type(d) == "table" and d or {}
	if kind == "State" then
		state = d
		renderStandings(); refreshJoin()
	elseif kind == "Impact" then
		if typeof(d.pos) ~= "Vector3" then return end
		local mine = d.striker == player.UserId or d.victim == player.UserId
		burst(d.pos + Vector3.new(0, 1.5, 0), d.boosted, d.blocked and GOLD or (d.boosted and Color3.fromRGB(120, 190, 255) or nil))
		if d.victim ~= 0 then flashVehicle(d.victim, d.blocked and GOLD or (d.boosted and Color3.fromRGB(120, 190, 255) or WHITE)) end
		if d.victim == player.UserId then shake = math.max(shake, d.boosted and 0.3 or 0.12) end
		if mine and d.blocked then flash("BLOCKED!", GOLD, d.victim == player.UserId and "BRACE saved you" or "They braced!", 1.2)
		elseif d.striker == player.UserId and d.boosted then flash("BOOST HIT!", Color3.fromRGB(150, 210, 255), nil, 1) end
	elseif kind == "KO" then
		flash("You knocked out " .. tostring(d.victim) .. "!", GOLD, "+1 point", 2.2)
	elseif kind == "KnockedOut" then
		respawnAt = d.respawnAt
		flash("Knocked out! Returning...", RED, d.by and ("by " .. d.by) or (d.reason == "out" and "You left the ring" or nil), 2.5)
		setCameraOverview(true)
	elseif kind == "Spawned" then
		respawnAt = nil
		setCameraOverview(false)
		joined = true; refreshJoin()
		if player:GetAttribute("ArenaIntroDone") ~= true and introStep == 0 then task.delay(0.4, function() if gui.Enabled and introStep == 0 then showIntro(1) end end)
		elseif d.zone == "practice" then flash("Practice ring", BLUE, "Bump the targets out while you wait", 2) end
	elseif kind == "Feed" then
		feedLine(d.by and (d.by .. " \u{2192} " .. tostring(d.victim)) or (tostring(d.victim) .. " fell out"))
	elseif kind == "TargetOut" then
		flash("Target out!", GREEN, "Nice push - now try a real rival", 1.4)
	elseif kind == "RoundStart" then
		results.Visible = false
		if joined then flash("GO!", GREEN, "Ram rivals. Use BOOST. Push them out!", 2) end
	elseif kind == "Results" then
		for _, c in ipairs(resList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
		local winners = d.winners or {}
		resTitle.Text = #winners == 0 and "ROUND OVER - NO KNOCKOUTS" or (d.tie and ("TIE: " .. table.concat(winners, " & ")) or ("WINNER: " .. tostring(winners[1])))
		for i, r in ipairs(d.rows or {}) do
			if i > 8 then break end
			label(resList, string.format("%d. %s   %d KO%s%s", i, r.name, r.score, r.score == 1 and "" or "s", r.won and "  \u{1F451}" or ""),
				{Size = UDim2.fromScale(1, 0.11), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = r.won and GOLD or WHITE})
		end
		resNote.Text = d.legit and "Counted toward arena rewards" or (d.reason == "players" and "Not enough drivers - this round didn't count" or "Friendly round - needs 2+ active drivers who really fight to count")
		results.Visible = true
		task.delay(A.Round.Results, function() results.Visible = false end)
	elseif kind == "Unlocked" then
		flash("UNLOCKED: " .. tostring(d.title), GOLD, d.paint and ("New bumper paint: " .. d.paint) or d.name, 3.5)
	elseif kind == "Toast" then
		flash(tostring(d.text or ""), WHITE, nil, 2.5)
	end
end)

-- scoreboard crown screens (world SurfaceGuis): timer + leader from the island's attributes
local screenT = 0
local function updateScreens()
	local isl = workspace:FindFirstChild("SnowplowArena")
	local signs = isl and isl:FindFirstChild("Signs")
	if not signs then return end
	local ph, leader = isl:GetAttribute("Phase") or "Idle", isl:GetAttribute("Leader") or ""
	local left = (isl:GetAttribute("PhaseEnds") or 0) - now()
	local txt
	if ph == "Active" then txt = fmtTime(left) .. "\n" .. (leader ~= "" and ("\u{1F451} " .. leader) or "FIGHT!")
	elseif ph == "Countdown" then txt = "NEXT ROUND\n" .. fmtTime(left)
	elseif ph == "Results" then txt = "WINNER\n" .. (leader ~= "" and leader or "NO KNOCKOUTS")
	else txt = "SNOWPLOW\nBUMPER ARENA" end
	for _, s in ipairs(signs:GetChildren()) do
		if s:GetAttribute("ArenaScreen") then local tl = s:FindFirstChild("Text", true); if tl and tl.Text ~= txt then tl.Text = txt end end
	end
end
-- per-frame: timer, cooldowns, shield, exit danger, intro pointers
RunService.RenderStepped:Connect(function()
	if not gui.Enabled then return end
	local t = now()
	if os.clock() - screenT > 0.25 then screenT = os.clock(); updateScreens() end
	local s = state
	local left = (s.endsAt or 0) - t
	if s.phase == "Active" then phaseL.Text = "ROUND " .. (s.round or 1); timeL.Text = fmtTime(left)
	elseif s.phase == "Countdown" then phaseL.Text = "NEXT ROUND IN"; timeL.Text = fmtTime(left)
	elseif s.phase == "Results" then phaseL.Text = "RESULTS"; timeL.Text = fmtTime(left)
	else phaseL.Text = "FREE PRACTICE"; timeL.Text = (s.count or 0) .. "/" .. A.Players.Max end
	if respawnAt then
		local r = respawnAt - t
		if r > 0 then sub.Text = "Back in " .. math.ceil(r) .. "..."; sub.TextTransparency = 0; subStroke.Transparency = 0 end
	end
	local hull = myHull()
	local driving = hull ~= nil and joined
	for _, u in ipairs({{boostU, "Boost", A.Boost.Cooldown}, {braceU, "Brace", A.Brace.Cooldown}}) do
		local ui, kind, cdMax = u[1], u[2], u[3]
		ui.button.Visible = driving
		if driving and driveApi then
			local left2, active = driveApi:Invoke("Cooldown", kind)
			ui.cd.Size = UDim2.fromScale(1, math.clamp(left2 / cdMax, 0, 1))
			ui.secs.Visible = left2 > 0.05 and not active
			ui.secs.Text = tostring(math.ceil(left2))
			ui.label.Visible = not ui.secs.Visible
			ui.button.BackgroundColor3 = active and WHITE or (kind == "Boost" and ORANGE or BLUE)
		end
	end
	local sh = hull and (hull:GetAttribute("ShieldUntil") or 0) - t or 0
	shieldBar.Visible = sh > 0
	if sh > 0 then shieldFill.Size = UDim2.fromScale(math.clamp(sh / A.Respawn.Shield, 0, 1), 1) end
	-- exits: brighter + "DANGER" when your vehicle is close to one
	for _, m in ipairs(exitMarks) do
		local near = hull and (Vector3.new(hull.Position.X, 0, hull.Position.Z) - Vector3.new(m.pos.X, 0, m.pos.Z)).Magnitude < 20
		m.label.Visible = near or introStep == 2 -- the gates carry real EXIT signs; this is the close-range danger warning
		m.label.Text = near and "\u{26A0} DANGER - EXIT" or "\u{26A0} EXIT"
		m.label.TextColor3 = near and Color3.fromRGB(255, 90, 60) or (introStep == 2 and Color3.fromRGB(255, 120, 60) or Color3.fromRGB(255, 210, 60))
	end
	for _, p in ipairs(pointers) do
		local o = p.target
		local vis = o.Visible
		p.frame.Visible, p.ring.Visible = vis, vis
		if vis then
			local pos, size = o.AbsolutePosition - gui.AbsolutePosition, o.AbsoluteSize
			local bob = math.sin(os.clock() * 6) * 6
			p.frame.Position = UDim2.fromOffset(pos.X + size.X / 2, pos.Y - 6 + bob)
			local pulse = 1 + 0.08 * math.sin(os.clock() * 5)
			p.ring.Position = UDim2.fromOffset(pos.X + size.X / 2, pos.Y + size.Y / 2)
			p.ring.Size = UDim2.fromOffset(size.X * 1.15 * pulse, size.Y * 1.15 * pulse)
		end
	end
end)

-- the main game HUD (menus, upgrade bar, boost icons, event banner) is hidden on the island so nothing covers the fight; restored on leave
local HIDE = {"LeftMenu", "BottomBar", "StatIcons", "RightMenu", "ActivityHUD"}
local hidden = {}
local function hideMainHud(on)
	local rng = player.PlayerGui:FindFirstChild("RNGGui")
	if on then
		for _, n in ipairs(HIDE) do
			local o = rng and rng:FindFirstChild(n)
			if o and o:IsA("GuiObject") and o.Visible then hidden[o] = true; o.Visible = false end
		end
	else
		for o in pairs(hidden) do if o.Parent then o.Visible = true end end
		table.clear(hidden)
	end
end
task.spawn(function() -- other scripts may re-show an element (e.g. a new event banner) while you're on the island
	while true do task.wait(0.5); if gui.Enabled then hideMainHud(true) end end
end)
-- island on/off: camera distance, HUD, intro, cleanup
local function onIsland()
	local on = player:GetAttribute("InArenaIsland") == true
	gui.Enabled = on
	hideMainHud(on)
	if on then
		buildExitMarks()
		player.CameraMinZoomDistance = 26
		player.CameraMaxZoomDistance = math.max(player.CameraMaxZoomDistance, 60)
		local r = ask("State")
		if r.ok then state = r.state; joined = r.joined == true end
		renderStandings(); refreshJoin()
		task.delay(0.3, function() -- arrival: look toward the arena (the camera keeps its old heading after a teleport)
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not (hrp and gui.Enabled) or myHull() then return end
			local fwd = Vector3.new(A.Center.X - hrp.Position.X, 0, A.Center.Z - hrp.Position.Z).Unit
			workspace.CurrentCamera.CFrame = CFrame.lookAt(hrp.Position - fwd * 22 + Vector3.new(0, 9, 0), hrp.Position + fwd * 30)
		end)
	else
		joined = false
		intro.Visible = false; clearPointers(); results.Visible = false
		for _, m in ipairs(exitMarks) do m.gui:Destroy() end
		table.clear(exitMarks)
		setCameraOverview(false)
		player.CameraMinZoomDistance = 0.5
	end
end
player:GetAttributeChangedSignal("InArenaIsland"):Connect(onIsland)
onIsland()
-- leaving the match (not the island) or being removed by the server: show JOIN again
folder.ChildRemoved:Connect(function(m)
	if m.Name == "Arena_" .. player.UserId and gui.Enabled then
		task.delay(0.5, function()
			if not myHull() and not respawnAt then local r = ask("State"); if r.ok then joined = r.joined == true; refreshJoin() end end
		end)
	end
end)
