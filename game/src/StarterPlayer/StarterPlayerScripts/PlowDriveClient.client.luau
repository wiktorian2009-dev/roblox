-- PlowDriveClient (2026-10-04, Claude): driving controls + DRIVE / RECOVER buttons for the snowplow.
-- PC: WASD / arrows / gamepad stick, F = drive / exit, R = recover. Mobile: the normal thumbstick steers, the on-screen buttons do the rest.
-- The server owns spawning, seating, digging and rewards; this script only moves the plow we have network ownership of, and draws the powder spray.
-- 2026-10-05 (Claude, drive feel + drift): hold-to-drift is part of THIS controller (one Heartbeat writes the velocities): Left Shift,
-- gamepad L1 or the DRIFT button. It needs ground contact, speed and steering; lowers sideways grip, keeps momentum, bounded yaw help,
-- smooth grip return. Tuning: PlowConfig C.Drive.Drift. Wheel powder, fading skid trails, engine/skid audio and a small camera lean
-- follow the Settings toggles DriveSoundOn / ReducedMotion. Drifting never awards Snow and never exceeds the build's top speed.
-- 2026-10-08 (Claude, UI audit F02 / F28 / F40): on touch, DRIFT / DRIVE (EXIT) / RECOVER sit in ONE bottom-right column (TouchColumn, a
-- UIListLayout; hidden buttons collapse) anchored just above Roblox's jump button (read live from PlayerGui.TouchGui, with the Roblox
-- defaults as fallback), so they never cover the jump button or each other, and the gui uses DeviceSafeInsets. Desktop layout is unchanged.
-- The F / Y and R actions and the on-screen buttons do nothing while the loading screen is up (it does not sink input).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("PlowConfig"))
local Art = require(RS:WaitForChild("FeatureUIArt"))
local UILayout = require(RS:WaitForChild("UILayout"))
if C.Mode ~= "Snowplow" then return end
local TX = require(RS:WaitForChild("UniversalVFX")).Textures
local remote = RS:WaitForChild("PlowRemote")
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)

local pg = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "PlowDriveGui", false, true, 51
if touch then gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end -- notches / rounded corners on phones
gui.Parent = pg

-- touch only: ONE column for DRIFT / DRIVE (EXIT) / RECOVER, bottom-right, right edge 8 px in, bottom 8 px above Roblox's jump button.
-- Hidden buttons collapse (UIListLayout skips them). The frame is transparent and not Active, so it never takes input itself.
local column
if touch then
	column = Instance.new("Frame")
	column.Name, column.BackgroundTransparency, column.BorderSizePixel, column.Active = "TouchColumn", 1, 0, false
	column.AnchorPoint, column.Size, column.AutomaticSize = Vector2.new(1, 1), UDim2.fromOffset(130, 0), Enum.AutomaticSize.Y
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.SortOrder, list.Padding = Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, UDim.new(0, UILayout.COL_GAP)
	list.HorizontalAlignment, list.VerticalAlignment = Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom
	list.Parent = column
	column.Parent = gui

	local function layoutColumn()
		local size = gui.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then -- not laid out yet: the camera viewport is the same size on a phone
			local vcam = workspace.CurrentCamera
			size = vcam and vcam.ViewportSize or size
			if size.X <= 0 or size.Y <= 0 then return end
		end
		local _, jumpTop = UILayout.jumpLeftTop(pg, gui) -- Roblox's jump button in this gui's space (fallback: the Roblox defaults)
		column.Size = UDim2.fromOffset(UILayout.touchColW(size.X), 0)
		column.Position = UDim2.fromOffset(size.X - UILayout.COL_EDGE, jumpTop - UILayout.GAP)
	end

	-- relayout triggers, each connected ONCE: this gui's size, the camera viewport, and the jump button (watched when it appears)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutColumn)
	gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(layoutColumn)
	local camConn
	local function watchCamera()
		if camConn then camConn:Disconnect(); camConn = nil end
		local vcam = workspace.CurrentCamera
		if vcam then camConn = vcam:GetPropertyChangedSignal("ViewportSize"):Connect(layoutColumn) end
		layoutColumn()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	local jumpConns, jumpWatched = {}, nil
	local function watchJump()
		local touchGui = pg:FindFirstChild("TouchGui")
		local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
		if not (jump and jump:IsA("GuiObject")) or jump == jumpWatched then return end
		for _, c in ipairs(jumpConns) do c:Disconnect() end -- a new JumpButton replaces the old one: never keep two sets of connections
		table.clear(jumpConns)
		jumpWatched = jump
		for _, prop in ipairs({"AbsolutePosition", "AbsoluteSize", "Visible"}) do
			table.insert(jumpConns, jump:GetPropertyChangedSignal(prop):Connect(layoutColumn))
		end
		table.insert(jumpConns, jump.AncestryChanged:Connect(layoutColumn))
		if touchGui:IsA("ScreenGui") then table.insert(jumpConns, touchGui:GetPropertyChangedSignal("Enabled"):Connect(layoutColumn)) end
		layoutColumn()
	end
	pg.ChildAdded:Connect(function(ch) if ch.Name == "TouchGui" then watchJump() end end)
	pg.DescendantAdded:Connect(function(d) if d.Name == "JumpButton" then watchJump() end end)
	watchCamera()
	watchJump()
end

local function makeButton(name, label, color, pos, size, order)
	local b = Instance.new("TextButton")
	b.Name, b.Text, b.AnchorPoint, b.Position, b.Size = name, "", Vector2.new(1, 0.5), pos, size
	if touch and order then -- a list item of TouchColumn: full column width, 44 high, the list owns the position
		b.AnchorPoint, b.Position, b.Size, b.LayoutOrder = Vector2.zero, UDim2.new(), UDim2.new(1, 0, 0, UILayout.COL_BTN_H), order
	end
	b.BackgroundColor3, b.BorderSizePixel, b.AutoButtonColor = color, 0, true
	b:SetAttribute("SnowUIDecor", true)
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.3, 0); cr.Parent = b
	local s = Instance.new("UIStroke"); s.Thickness = 3; s.Color = NAVY; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = b
	local g = Instance.new("UIGradient"); g.Rotation = 90; g.Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 215, 235)); g.Parent = b
	local l = Instance.new("TextLabel")
	l.Name, l.BackgroundTransparency, l.Font, l.TextScaled, l.Text = "Label", 1, FONT, true, label
	l.TextColor3, l.Position, l.Size = WHITE, UDim2.fromScale(0.25, 0.12), UDim2.fromScale(0.72, 0.76)
	l.ZIndex = b.ZIndex + 4
	l.Parent = b
	local ls = Instance.new("UIStroke"); ls.Thickness = 2.2; ls.Color = NAVY; ls.Parent = l
	if touch then local tc = Instance.new("UITextSizeConstraint"); tc.MinTextSize = UILayout.MIN_TEXT; tc.Parent = l end -- never below 12 px
	local sc = Instance.new("UISizeConstraint"); sc.MinSize = Vector2.new(touch and 130 or 118, UILayout.MIN_TOUCH); sc.Parent = b -- 44 high (touch: 130 wide = the column's minimum width)
	b.Parent = (touch and order) and column or gui
	Art.Skin(b)
	local symbol = name == "Drift" and "drift" or (name == "Recover" and "recover" or "recover")
	Art.Icon(b, symbol, UDim2.fromScale(0.025, 0.11), UDim2.fromScale(0.21, 0.78), "FeatureDriveIcon")
	return b, l
end
-- pos / size are the desktop values; on touch the last argument (LayoutOrder in TouchColumn: DRIFT 1, DRIVE / EXIT 2, RECOVER 3) replaces them
local drive, driveLabel = makeButton("Drive", "DRIVE", Color3.fromRGB(70, 200, 105), UDim2.fromScale(0.992, 0.8), UDim2.fromScale(0.115, 0.066), 2)
local recover = makeButton("Recover", touch and "RECOVER" or "RECOVER [R]", Color3.fromRGB(250, 150, 50), UDim2.fromScale(0.992, 0.885), UDim2.fromScale(0.1, 0.05), 3)
recover.Visible = false
local msg = Instance.new("TextLabel")
msg.Name, msg.BackgroundTransparency, msg.Font, msg.TextScaled, msg.Text = "Msg", 1, FONT, true, ""
msg.AnchorPoint, msg.Position, msg.Size, msg.TextColor3, msg.TextTransparency = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.68), UDim2.fromScale(0.5, 0.06), Color3.fromRGB(255, 225, 140), 1
msg.Parent = gui
local msgStroke = Instance.new("UIStroke"); msgStroke.Thickness = 2.5; msgStroke.Color = NAVY; msgStroke.Transparency = 1; msgStroke.Parent = msg
local msgToken = 0
local function say(text)
	msgToken += 1
	local my = msgToken
	msg.Text, msg.TextTransparency, msgStroke.Transparency = text, 0, 0
	task.delay(2.6, function()
		if msgToken ~= my then return end
		TweenService:Create(msg, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(msgStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
	end)
end
local function refreshButtons()
	local driving = player:GetAttribute("PlowDriving") == true
	driveLabel.Text = driving and (touch and "EXIT" or "EXIT [F]") or (touch and "DRIVE" or "DRIVE [F]")
	drive.BackgroundColor3 = driving and Color3.fromRGB(235, 90, 100) or Color3.fromRGB(70, 200, 105)
	local symbol = drive:FindFirstChild("FeatureDriveIcon")
	if symbol then symbol.Image = Art.Assets[driving and "exit" or "recover"] end
	recover.Visible = driving and player:GetAttribute("InGarage") ~= true
	drive.Visible = player:GetAttribute("InGarage") ~= true and player:GetAttribute("InArenaIsland") ~= true -- no plow on the garage / arena islands
	if player:GetAttribute("InArenaIsland") ~= true then -- the arena sets its own camera distance
		player.CameraMinZoomDistance = driving and 24 or 0.5 -- the camera pulls back so you can see your plow
	end
end
player:GetAttributeChangedSignal("PlowDriving"):Connect(refreshButtons)
player:GetAttributeChangedSignal("InGarage"):Connect(refreshButtons)
player:GetAttributeChangedSignal("InArenaIsland"):Connect(refreshButtons)
refreshButtons()
local busy = false
-- 2026-10-08 (F28): the loading screen (ReplicatedFirst) does not sink input, so F / Y / R and the on-screen buttons must wait for it
local function loadingActive() return player:GetAttribute("LoadingScreenActive") == true end
local function ask(action)
	if busy or loadingActive() then return end
	busy = true
	local ok, res = pcall(function() return remote:InvokeServer(action) end)
	busy = false
	if ok and type(res) == "table" and res.ok == false and res.msg then say(res.msg) end
end
drive.Activated:Connect(function() ask("Drive") end)
recover.Activated:Connect(function() ask("Recover") end)
CAS:BindAction("PlowDrive", function(_, state) if state == Enum.UserInputState.Begin and not loadingActive() and player:GetAttribute("InArenaIsland") ~= true then task.spawn(ask, "Drive") end return Enum.ContextActionResult.Pass end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonY) -- 2026-10-05: Y on a controller too
CAS:BindAction("PlowRecover", function(_, state) if state == Enum.UserInputState.Begin and not loadingActive() and player:GetAttribute("InGarage") ~= true and player:GetAttribute("InArenaIsland") ~= true then task.spawn(ask, "Recover") end return Enum.ContextActionResult.Pass end, false, Enum.KeyCode.R)

-- hold-to-drift input (2026-10-05). Polled by the Heartbeat below; never sunk, so other systems keep their keys.
-- Ignored while typing, in the Roblox menu, or (gamepad) while a GUI element is selected.
local DR = C.Drive.Drift or {}
local driftKey, driftPad, driftTouch = false, false, false
local usingPad = false
local function releaseDrift() driftKey, driftPad, driftTouch = false, false, false end
local driftBtn, driftLabel = makeButton("Drift", "DRIFT", Color3.fromRGB(120, 150, 255), UDim2.fromScale(0.992, 0.725), UDim2.fromScale(0.1, 0.05), 1)
driftBtn.Visible = false
local function driftHint()
	driftLabel.Text = touch and "DRIFT" or (usingPad and "DRIFT (L1)" or "DRIFT [SHIFT]")
end
driftHint()
driftBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then driftTouch = true end
end)
driftBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then driftTouch = false end
end)
driftBtn.MouseLeave:Connect(function() if not touch then driftTouch = false end end)
local function typing() return UIS:GetFocusedTextBox() ~= nil or GuiService.MenuIsOpen end
UIS.InputBegan:Connect(function(input, processed)
	local t = input.UserInputType
	if t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseButton1 then if usingPad then usingPad = false; driftHint() end
	elseif t.Name:find("^Gamepad") then if not usingPad then usingPad = true; driftHint() end end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		if not typing() then driftKey = true end
	elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
		if not processed and not typing() and GuiService.SelectedObject == nil then driftPad = true end
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then driftKey = false elseif input.KeyCode == Enum.KeyCode.ButtonL1 then driftPad = false end
end)
UIS.TextBoxFocused:Connect(releaseDrift)
UIS.WindowFocusReleased:Connect(releaseDrift)
UIS.GamepadDisconnected:Connect(function() driftPad = false end)
GuiService.MenuOpened:Connect(releaseDrift)

-- settings (saved by SettingsService): DriveSoundOn (default on), ReducedMotion (default off; the treasure book's reduced effects count too)
local setSetting = RS:FindFirstChild("SetSetting")
local function reducedMotion() return player:GetAttribute("ReducedMotion") == true or player:GetAttribute("TreasureReduced") == true end
local function driveSoundOn() return player:GetAttribute("DriveSoundOn") ~= false end
task.spawn(function() -- two extra rows in the Settings panel, cloned from the music row so they match its look
	local content = player:WaitForChild("PlayerGui"):WaitForChild("RNGGui", 30)
	content = content and content:WaitForChild("Panels", 10)
	content = content and content:WaitForChild("Settings", 10)
	content = content and content:WaitForChild("Inner", 10)
	content = content and content:WaitForChild("Content", 10)
	local proto = content and content:WaitForChild("MusicRow", 10)
	if not proto then return end
	for i, def in ipairs({{"DriveSoundRow", "\u{1F50A} Drive sounds", "DriveSoundOn", true}, {"ReducedMotionRow", "\u{1F300} Reduced motion", "ReducedMotion", false}}) do
		if content:FindFirstChild(def[1]) then continue end
		local row = proto:Clone()
		row.Name, row.LayoutOrder = def[1], proto.LayoutOrder + i
		local label = row:FindFirstChildWhichIsA("TextLabel")
		if label then label.Text = def[2] end
		local tog = row:FindFirstChildWhichIsA("TextButton")
		if not tog then row:Destroy() continue end
		tog.Name = def[3] .. "Toggle"
		local knob = tog:FindFirstChild("Knob")
		local function isOn() local v = player:GetAttribute(def[3]); if v == nil then return def[4] end return v == true end
		local function draw()
			local on = isOn()
			if knob then knob.Position = on and UDim2.fromScale(0.54, 0.5) or UDim2.fromScale(0.06, 0.5) end
			tog.BackgroundColor3 = on and Color3.fromRGB(80, 210, 110) or Color3.fromRGB(190, 196, 212)
		end
		row.Parent = content
		draw()
		player:GetAttributeChangedSignal(def[3]):Connect(draw)
		tog.Activated:Connect(function()
			local on = not isOn()
			player:SetAttribute(def[3], on)
			if setSetting then setSetting:FireServer(def[3], on) end
		end)
	end
end)

-- input: the standard PlayerModule move vector (keyboard, thumbstick, gamepad); Studio tests may inject PlowTestMove
-- 2026-10-05 (Claude, drive fix): newer Roblox builds load the PlayerModule from StarterPlayer instead of PlayerScripts, so the old
-- WaitForChild in PlayerScripts never found it and the plow got no input. Look in both places, and fall back to reading the
-- keyboard / gamepad directly if the module is unavailable.
-- 2026-10-07 (Claude, phone fix): the current PlayerModule uses the Input Action System. require() returns a table without
-- GetControls, so `controls` stayed nil and only the keyboard / gamepad fallback worked: phone thumbsticks did nothing. The touch
-- thumbsticks (and keys / gamepad) now feed InputContexts.CharacterContext.MoveAction, so read that action's state as well.
local controls, moveAction
task.spawn(function()
	local t0 = os.clock()
	while not (controls or moveAction) and os.clock() - t0 < 30 do
		local ps = player:FindFirstChild("PlayerScripts")
		local pm = (ps and ps:FindFirstChild("PlayerModule")) or game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
		if pm and pm:IsA("ModuleScript") then
			local ctx = pm:FindFirstChild("InputContexts")
			local cc = ctx and ctx:FindFirstChild("CharacterContext")
			local a = cc and cc:FindFirstChild("MoveAction")
			if a and a:IsA("InputAction") then moveAction = a end
			local ok, m = pcall(require, pm)
			if ok and type(m) == "table" and m.GetControls then controls = m:GetControls() end
		end
		if not (controls or moveAction) then task.wait(0.5) end
	end
end)
local KEYS = {[Enum.KeyCode.W] = Vector3.new(0, 0, -1), [Enum.KeyCode.Up] = Vector3.new(0, 0, -1), [Enum.KeyCode.S] = Vector3.new(0, 0, 1), [Enum.KeyCode.Down] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0), [Enum.KeyCode.Left] = Vector3.new(-1, 0, 0), [Enum.KeyCode.D] = Vector3.new(1, 0, 0), [Enum.KeyCode.Right] = Vector3.new(1, 0, 0)}
local function directInput()
	local v = Vector3.zero
	if not UIS:GetFocusedTextBox() then
		for key, dir in pairs(KEYS) do if UIS:IsKeyDown(key) then v += dir end end
	end
	for _, st in ipairs(UIS:GetGamepadState(Enum.UserInputType.Gamepad1)) do
		if st.KeyCode == Enum.KeyCode.Thumbstick1 and st.Position.Magnitude > 0.15 then v += Vector3.new(st.Position.X, 0, -st.Position.Y) end
	end
	return v.Magnitude > 1 and v.Unit or v
end
-- AFK auto-plow (2026-10-06): while the server has set AfkPlow, a lawnmower route over the field in AfkField stands in for the stick.
-- It only produces the same move vector the keys would, so this Heartbeat stays the one velocity writer. AfkService turns it off.
local SFmod
local afk = {key = nil, route = nil, i = 1}
local function afkMove()
	local id = player:GetAttribute("AfkField")
	local model = workspace:FindFirstChild("Snowplows") and workspace.Snowplows:FindFirstChild("Snowplow_" .. player.UserId)
	local hull = model and model.PrimaryPart
	if not id or not hull then return nil end
	if not SFmod then SFmod = require(RS:WaitForChild("SnowFields")) end
	local key = id .. ":" .. tostring(player:GetAttribute("AfkLane"))
	if afk.key ~= key then
		local f
		for _, x in ipairs(SFmod.Fields) do if x.Id == id then f = x end end
		if not f then return nil end
		local o, ts = SFmod.Origin(f), SFmod.TileSize
		local W, D, inset = f.Width * ts, f.Depth * ts, C.Afk.Inset
		local lane = math.max(3, player:GetAttribute("AfkLane") or 6)
		local alongX = W >= D
		local len, across = alongX and W or D, alongX and D or W
		local route, k = {}, 0
		local a = inset
		while a <= across - inset + 0.01 do
			local p0, p1 = inset, len - inset
			if k % 2 == 1 then p0, p1 = p1, p0 end
			for _, p in ipairs({p0, p1}) do
				route[#route + 1] = alongX and Vector3.new(o.X + p, o.Y, o.Z + a) or Vector3.new(o.X + a, o.Y, o.Z + p)
			end
			a += lane; k += 1
		end
		if #route == 0 then route = {f.Center} end
		-- start at the closest point of the route
		local best, bd = 1, math.huge
		for i, q in ipairs(route) do local dd = (Vector3.new(q.X, 0, q.Z) - Vector3.new(hull.Position.X, 0, hull.Position.Z)).Magnitude if dd < bd then best, bd = i, dd end end
		afk.key, afk.route, afk.i = key, route, best
	end
	local cf = hull.CFrame
	local target = afk.route[afk.i]
	local to = Vector3.new(target.X - cf.X, 0, target.Z - cf.Z)
	if to.Magnitude < 6 then
		afk.i = afk.i % #afk.route + 1
		target = afk.route[afk.i]; to = Vector3.new(target.X - cf.X, 0, target.Z - cf.Z)
	end
	if to.Magnitude < 1e-3 then return Vector3.zero end
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
	local right = Vector3.new(-look.Z, 0, look.X)
	local dir = to.Unit
	local ang = math.atan2(dir:Dot(right), dir:Dot(look))
	local steer = math.clamp(ang * 1.4, -1, 1)
	local throttle = math.abs(ang) > 1.3 and 0.35 or (math.abs(ang) > 0.5 and 0.55 or 0.85)
	return Vector3.new(steer, 0, -throttle)
end
local function moveVector()
	if player:GetAttribute("AfkPlow") == true then
		local v = afkMove()
		if v then return v end
	else
		afk.key = nil
	end
	if RS:GetAttribute("PlowTestHooks") then
		local t = player:GetAttribute("PlowTestMove")
		if typeof(t) == "Vector3" then return t end
	end
	if controls then
		local ok, v = pcall(function() return controls:GetMoveVector() end)
		if ok and v and v.Magnitude > 0.01 then return v end
	end
	if moveAction then -- Vector2: X = right, Y = forward
		local ok, s = pcall(moveAction.GetState, moveAction)
		if ok and typeof(s) == "Vector2" and s.Magnitude > 0.01 then return Vector3.new(s.X, 0, -s.Y) end
	end
	return directInput()
end

-- powder spray
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture, e.Rate, e.LightEmission, e.LightInfluence, e.Drag = TX.smoke, 0, 0.2, 0.3, 2
	e.Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 232, 255))
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent
	return e
end
local function attachFx(model)
	local out = {}
	local blade = model:FindFirstChild("Blade")
	local bladeRoot = blade and blade:FindFirstChild("Root")
	if bladeRoot then
		local a = Instance.new("Attachment"); a.Position = Vector3.new(0, -0.7, -2.4); a.Parent = bladeRoot
		out.blade = emitter(a, {Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(55, 25), Acceleration = Vector3.new(0, 4, 0),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3.4)}),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})})
	end
	local b = Instance.new("Attachment"); b.Position = Vector3.new(0, -0.3, 4.2); b.Parent = model.PrimaryPart
	out.rear = emitter(b, {Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(30, 20), Acceleration = Vector3.new(0, 2, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.4)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1)})})
	-- drift feedback (2026-10-05): compact powder at the rear wheels + short fading skid trails, made once per plow (pooled)
	local hull = model.PrimaryPart
	local gy = -(hull.Size.Y / 2 + C.Vehicle.HullClearance - 0.08) -- ground level under the hull
	out.wheels, out.trails = {}, {}
	for _, x in ipairs({-2.3, 2.3}) do
		local w = Instance.new("Attachment"); w.Name = "DriftPowder"; w.Position = Vector3.new(x, gy + 0.25, 3.1); w.Parent = hull
		table.insert(out.wheels, emitter(w, {Lifetime = NumberRange.new(0.35, 0.65), Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(40, 15),
			Acceleration = Vector3.new(0, 3, 0), EmissionDirection = Enum.NormalId.Back,
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.8)}),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})}))
		local a0 = Instance.new("Attachment"); a0.Name = "SkidA"; a0.Position = Vector3.new(x - 0.4, gy, 3.1); a0.Parent = hull
		local a1 = Instance.new("Attachment"); a1.Name = "SkidB"; a1.Position = Vector3.new(x + 0.4, gy, 3.1); a1.Parent = hull
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1, tr.Lifetime, tr.MinLength, tr.FaceCamera = a0, a1, 1.3, 0.2, false
		tr.Color = ColorSequence.new(Color3.fromRGB(150, 175, 205))
		tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1)})
		tr.LightInfluence, tr.Enabled = 1, false
		tr.Parent = hull
		table.insert(out.trails, tr)
	end
	local function loop(id, vol)
		local s = Instance.new("Sound"); s.SoundId, s.Looped, s.Volume = id, true, 0
		s.RollOffMaxDistance, s.RollOffMinDistance = 90, 12
		s.Parent = hull
		return s
	end
	out.engine = loop(DR.EngineSound or "rbxassetid://71482635231754")
	out.skid = loop(DR.SkidSound or "rbxassetid://103723782639124")
	return out
end

local folder = workspace:WaitForChild("Snowplows")
local fx, fxFor
-- 2026-10-05 (Claude, car handling): raycast suspension + field detection
local fields = {}
task.spawn(function()
	local ok, SF = pcall(require, RS:WaitForChild("SnowFields"))
	if ok and SF then
		local ts = SF.TileSize or 3
		for _, f in ipairs(SF.Fields or {}) do
			if typeof(f.Center) == "Vector3" then
				local hp = math.max(tonumber(f.TileHP) or 1, 1e-6)
				table.insert(fields, {c = f.Center, hx = (f.Width or 0) * ts / 2, hz = (f.Depth or 0) * ts / 2, hp = hp, tough = C.ToughnessOf(f.Style, hp), ts = ts})
			end
		end
	end
end)
local function onField(p)
	for _, f in ipairs(fields) do
		if math.abs(p.X - f.c.X) <= f.hx and math.abs(p.Z - f.c.Z) <= f.hz and math.abs(p.Y - f.c.Y) < 10 then return f end
	end
	return nil
end
local rideParams = RaycastParams.new()
rideParams.FilterType = Enum.RaycastFilterType.Exclude
rideParams.CollisionGroup = "PlowVehicle" -- only what the hull really collides with (players / other plows are ignored)
rideParams.RespectCanCollide = true
local CORNERS = {Vector3.new(-2.3, 0, -3.1), Vector3.new(2.3, 0, -3.1), Vector3.new(-2.3, 0, 3.1), Vector3.new(2.3, 0, 3.1)}
local function ground(hull, cf)
	rideParams.FilterDescendantsInstances = {folder, player.Character}
	local reach = 1.5 + hull.Size.Y / 2 + C.Vehicle.HullClearance + C.Vehicle.RideReach
	local sumY, n, normal = 0, 0, Vector3.zero
	for _, c in ipairs(CORNERS) do
		local o = cf:PointToWorldSpace(c) + Vector3.new(0, 1.5, 0)
		local hit = workspace:Raycast(o, Vector3.new(0, -reach, 0), rideParams)
		if hit and hit.Normal.Y > 0.55 then sumY += hit.Position.Y; n += 1; normal += hit.Normal end
	end
	if n == 0 then return nil end
	return sumY / n, normal.Unit
end
-- smoothing (2026-10-05): throttle and steering ease toward the input instead of snapping; yaw ramps too
local sThrottle, sSteer, sYaw = 0, 0, 0
local THROTTLE_RAMP, STEER_RAMP, YAW_RAMP = 3.5, 5, 8
local function approach(cur, target, rate, dt)
	return cur + math.clamp(target - cur, -rate * dt, rate * dt)
end
-- drift state (cleared on seat exit, death, respawn, teleport, focus loss)
local drifting, driftAmt, driftDir = false, 0, 0
local lastPos, baseFov, camLean = nil, nil, 0
local function clearDrift()
	drifting, driftAmt, driftDir, lastPos = false, 0, 0, nil
	releaseDrift()
end
local function bindCharacter(char)
	clearDrift()
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then hum.Died:Connect(clearDrift) end
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then task.spawn(bindCharacter, player.Character) end
-- (shift-lock is paused by the server while PlowDriving is set - PlowService - because Shift is the drift key)
local cam = workspace.CurrentCamera
local function camRestore()
	cam = workspace.CurrentCamera
	if baseFov and cam then cam.FieldOfView = baseFov end
	baseFov, camLean = nil, 0
end
-- tiny camera lean during a drift (skipped with reduced motion); applied after the default camera each frame
RunService:BindToRenderStep("PlowDriftLean", Enum.RenderPriority.Camera.Value + 1, function()
	if camLean ~= 0 and workspace.CurrentCamera then workspace.CurrentCamera.CFrame *= CFrame.Angles(0, 0, camLean) end
end)

local driftSent, driftSentAt = false, 0
local snowCap -- smoothed hard-snow speed limit (studs/s)
local function idle()
	if driftSent then driftSent = false; local sig = RS:FindFirstChild("PlowDriftSignal"); if sig then sig:FireServer(false) end end
	if fx then
		for _, e in ipairs(fx.wheels or {}) do e.Rate = 0 end
		for _, t in ipairs(fx.trails or {}) do t.Enabled = false end
		if fx.engine then fx.engine:Stop() end
		if fx.skid then fx.skid:Stop() end
	end
	fxFor, fx = nil, nil
	sThrottle, sSteer, sYaw = 0, 0, 0
	if drifting or driftAmt > 0 then clearDrift() end
	camRestore()
	driftBtn.Visible = false
end
RunService.Heartbeat:Connect(function(dt)
	local model = folder:FindFirstChild("Snowplow_" .. player.UserId)
	local hull = model and model.PrimaryPart
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not (hull and hum and hum.Health > 0 and hum.SeatPart and hum.SeatPart.Parent == model) or player:GetAttribute("InArenaIsland") == true then
		if fxFor or driftBtn.Visible or baseFov then idle() end
		return
	end
	if fxFor ~= model then fxFor = model; fx = attachFx(model); clearDrift() end
	driftBtn.Visible = true
	dt = math.min(dt, 1 / 20)
	local mv = moveVector()
	-- 2026-10-05: the PlayerModule normalises W+D to (0.707, -0.707), which used to cut throttle to 71% in every turn. Map the circle back to
	-- a square, so full keys give full throttle AND full steering; partial stick input keeps its size.
	local m = math.max(math.abs(mv.X), math.abs(mv.Z))
	if m > 1e-3 then mv = mv * math.min(mv.Magnitude / m, 1.42) end
	-- releasing the key eases off faster than pressing it, so stops feel responsive
	local tIn, sIn = math.clamp(-mv.Z, -1, 1), math.clamp(mv.X, -1, 1)
	sThrottle = approach(sThrottle, tIn, (math.abs(tIn) < math.abs(sThrottle) or tIn * sThrottle < 0) and THROTTLE_RAMP * 2 or THROTTLE_RAMP, dt)
	sSteer = approach(sSteer, sIn, (math.abs(sIn) < math.abs(sSteer) or sIn * sSteer < 0) and STEER_RAMP * 1.6 or STEER_RAMP, dt)
	local throttle, steer = sThrottle, sSteer
	local maxSpeed, accel = hull:GetAttribute("MaxSpeed") or 20, hull:GetAttribute("Accel") or 12
	local traction, turnRate = hull:GetAttribute("Traction") or 0.6, hull:GetAttribute("TurnRate") or 2
	local pivot, stability = hull:GetAttribute("Pivot") or 0.2, hull:GetAttribute("Stability") or 1
	-- 2026-10-11 ability tokens (server-set on the hull, AbilityService): Turbo Tracks = speed + a little grip. Same single controller.
	maxSpeed *= hull:GetAttribute("AbilitySpeed") or 1
	traction = math.min(1, traction * (hull:GetAttribute("AbilityGrip") or 1))
	local cf = hull.CFrame
	-- a sudden jump (teleport, recover, respawn) ends any drift
	if lastPos and (cf.Position - lastPos).Magnitude > math.max(40, maxSpeed * 2 * dt + 20) then clearDrift() end
	lastPos = cf.Position
	local fullSpeed = maxSpeed
	local bladePos = cf:PointToWorldSpace(Vector3.new(0, 0, -C.Vehicle.BladeOffset))
	local fld = onField(bladePos)
	-- only while fresh snow is really under the blade: cleared lanes and paths on a field drive at full speed (2026-10-06)
	if fld and shared.SnowFreshIn then
		local r = hull.Size.X / 2 + 1
		if not shared.SnowFreshIn(bladePos.X, bladePos.Z, r, r) then fld = nil end
	end
	local fieldCap = fullSpeed
	if fld then
		maxSpeed *= C.Drive.PlowingSpeedFactor -- heavy work: slower in the snow
		-- 2026-10-06 hard snow (wiktor: "scalling speed with snow hardness"): a tile only breaks a layer if it stays under the blade long
		-- enough, so cap the speed on this field at the speed where one pass breaks a layer (footprint x power x efficiency / tile HP).
		-- Hard snow or a weak plow = slower, but it never has to stop; the floor keeps weak plows moving (damage carries over between passes).
		local cp, soft, hard = hull:GetAttribute("ClearPower"), hull:GetAttribute("Soft"), hull:GetAttribute("Hard")
		if cp and soft and hard then
			local HS = C.Drive.HardSnow
			local eff = soft + (hard - soft) * fld.tough
		cp *= hull:GetAttribute("AbilityPower") or 1 -- Heated Blade: the server breaks layers faster, so the snow cap follows
			local vBreak = (C.Clearing.BladeDepth + 2 * C.Clearing.TileSlack * fld.ts) * cp * eff / fld.hp * HS.PassShare
			maxSpeed = math.clamp(vBreak, maxSpeed * HS.Floor, maxSpeed)
		end
		fieldCap = maxSpeed
	end
	-- ease the limit in and out so crossing from snow to a cleared lane (or back) never jerks
	snowCap = snowCap and (snowCap + math.clamp(fieldCap - snowCap, -C.Drive.HardSnow.EaseRate * dt, C.Drive.HardSnow.EaseRate * dt)) or fieldCap
	maxSpeed = snowCap
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
	local right = Vector3.new(-look.Z, 0, look.X)
	local vel = hull.AssemblyLinearVelocity
	local fwd, lat = vel:Dot(look), vel:Dot(right)
	local groundY, normal = ground(hull, cf)
	local grounded = groundY ~= nil

	-- drift: starts with the button held, on the ground, moving forward fast enough, while steering; ends on release, in the air or when slow
	local held = (driftKey or driftPad or driftTouch) and not typing()
	local minS = math.max(DR.MinSpeedAbs or 9, fullSpeed * (DR.MinSpeed or 0.35))
	if not drifting then
		if held and grounded and fwd > minS and math.abs(sIn) >= (DR.SteerToStart or 0.25) then drifting, driftDir = true, (sIn > 0 and 1 or -1) end
	elseif not held or not grounded or Vector3.new(vel.X, 0, vel.Z).Magnitude < fullSpeed * (DR.ExitSpeedShare or 0.25) then
		drifting = false
	end
	driftAmt = approach(driftAmt, drifting and 1 or 0, drifting and (DR.RampIn or 6) or (DR.RampOut or 2.8), dt)

	-- engine: a little extra pull at low speed (the build's AccelTime still decides how quick it is); braking is firmer than coasting
	local target = throttle * maxSpeed * (throttle < 0 and C.Drive.ReverseFactor or 1)
	-- full-lock corners ease the target speed a little (tight turns into yards), except while drifting
	target *= 1 - (C.Drive.CornerSlow or 0) * math.abs(steer) * (1 - driftAmt)
	local braking, coasting = target * fwd < 0, math.abs(target) < math.abs(fwd) and target * fwd >= 0
	local rate
	if braking then rate = accel * C.Drive.BrakeFactor
	elseif coasting then rate = accel * (C.Drive.CoastFactor or C.Drive.BrakeFactor) * (1 - 0.6 * driftAmt) -- a drift carries its momentum
	else rate = accel * (1 + (C.Drive.LowSpeedPull or 0) * (1 - math.clamp(math.abs(fwd) / fullSpeed, 0, 1))) end
	if not grounded then rate *= C.Drive.AirControl or 0.35 end
	fwd += math.clamp(target - fwd, -rate * dt, rate * dt)
	-- sideways grip (frame-rate independent). A drift lowers it; past MaxSlip the tyres catch again so the plow can't spin out.
	local k = traction * C.Drive.LateralGrip * (1 - driftAmt * (1 - (DR.Grip or 0.14)))
	local slip = math.deg(math.atan2(math.abs(lat), math.max(math.abs(fwd), 1)))
	if slip > (DR.MaxSlip or 50) then k += (slip - (DR.MaxSlip or 50)) * (DR.SlipCatch or 0.6) end
	if not grounded then k *= 0.25 end
	local lat0 = lat
	lat *= math.exp(-k * dt)
	if not drifting and driftAmt > 0 then -- leaving a drift: part of the sideways speed swings back to forward, never above top speed
		fwd = math.clamp(fwd + (math.abs(lat0) - math.abs(lat)) * (DR.ExitCarry or 0.35), -maxSpeed, math.max(maxSpeed, fwd))
	end
	if driftAmt > 0 then
		local drag = math.exp(-(DR.Drag or 0.12) * driftAmt * dt)
		fwd, lat = fwd * drag, lat * drag
	end
	local planar = look * fwd + right * lat
	if driftAmt > 0 and planar.Magnitude > fullSpeed then planar = planar.Unit * fullSpeed end -- a slide never goes faster than the build's top speed
	-- suspension: hold the collision box HullClearance above the ground under the four corners, so small steps, path slabs and
	-- kerbs lift the plow instead of stopping it (anything taller than the clearance - walls, gates, barriers - still blocks it)
	local vy = vel.Y
	if grounded then
		local want = groundY + C.Vehicle.HullClearance + hull.Size.Y / 2
		vy = math.clamp((want - cf.Position.Y) * C.Vehicle.RideStiffness, -C.Vehicle.RideMaxFall, C.Vehicle.RideMaxRise)
	end
	hull.AssemblyLinearVelocity = Vector3.new(planar.X, vy, planar.Z)
	-- car steering: needs speed (Pivot gears still turn on the spot), full at TurnSpeedFull x top speed, a bit wider when going fast
	local speedFactor = math.clamp(math.abs(fwd) / (fullSpeed * C.Drive.TurnSpeedFull), math.max(C.Drive.MinTurn, pivot), 1)
	speedFactor *= 1 - C.Drive.HighSpeedTurnLoss * math.clamp((math.abs(fwd) / fullSpeed - 0.6) / 0.4, 0, 1)
	local yaw = -steer * turnRate * speedFactor * (fwd < -0.5 and -1 or 1)
	if driftAmt > 0 then -- bounded yaw help: turns in tighter while drifting; countersteering (steer against the slide) eases it out
		yaw *= 1 + (DR.YawBoost or 0.55) * driftAmt
		local cap = turnRate * (1 + (DR.YawBoost or 0.55))
		yaw = math.clamp(yaw, -cap, cap)
	end
	if not grounded then yaw *= 0.4 end
	sYaw = approach(sYaw, yaw, YAW_RAMP * math.max(1, turnRate) * (drifting and 1.3 or 1), dt)
	-- the body follows the ground (pitch / roll on slopes and steps) instead of always staying level; harder when badly tilted (bump recovery)
	local up = normal or Vector3.yAxis
	local tilt = cf.UpVector:Dot(up)
	local assist = C.Drive.UprightAssist * stability * (tilt < 0.9 and (C.Drive.TiltRecover or 1.6) or 1)
	hull.AssemblyAngularVelocity = Vector3.new(0, sYaw, 0) + cf.UpVector:Cross(up) * assist

	-- feedback: powder / trails / sound only on the ground and when moving
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local moving = grounded and speed > 2
	if fx then
		if fx.blade then fx.blade.Rate = moving and math.clamp(speed * 2.2, 0, 42) or 0 end
		if fx.rear then fx.rear.Rate = moving and math.clamp(speed * 1.1, 0, 22) or 0 end
		local sliding = moving and driftAmt > 0.25
		local reduced = reducedMotion()
		for _, e in ipairs(fx.wheels or {}) do e.Rate = sliding and math.clamp(speed * 1.4 * driftAmt, 0, reduced and 10 or 26) or 0 end
		for _, t in ipairs(fx.trails or {}) do t.Enabled = sliding end
		local soundOn = driveSoundOn()
		if fx.engine then
			if soundOn then
				if not fx.engine.IsPlaying then fx.engine:Play() end
				fx.engine.Volume = C.Sound.EngineIdle + C.Sound.EngineThrottle * math.abs(throttle)
				fx.engine.PlaybackSpeed = 0.85 + 0.45 * math.clamp(speed / fullSpeed, 0, 1)
			elseif fx.engine.IsPlaying then fx.engine:Stop() end
		end
		if fx.skid then
			local want = (soundOn and sliding) and C.Sound.Skid * driftAmt * math.clamp(slip / 25, 0.3, 1) or 0
			if want > 0.01 then
				if not fx.skid.IsPlaying then fx.skid:Play() end
				fx.skid.Volume = want
			elseif fx.skid.IsPlaying then fx.skid:Stop() end
		end
		-- camera: +up to 4 FOV and ~2 degrees of lean while drifting (off with reduced motion)
		cam = workspace.CurrentCamera
		if cam then
			if not baseFov then baseFov = cam.FieldOfView end
			local wantFov = reduced and baseFov or baseFov + (DR.CameraFov or 4) * driftAmt * math.clamp(speed / fullSpeed, 0, 1)
			cam.FieldOfView += (wantFov - cam.FieldOfView) * (1 - math.exp(-6 * dt))
			camLean = reduced and 0 or -driftDir * math.rad(DR.CameraLean or 2) * driftAmt
		end
	end
	hull:SetAttribute("Drift", driftAmt > 0.05 and math.floor(driftAmt * 100 + 0.5) / 100 or nil) -- read by tests / other clients' effects
	-- drift Snow bonus (2026-10-06): tell the server we're drifting (a hint only - SnowFieldService checks the hull itself); ~3 msgs/s max
	local dnow = drifting and driftAmt > 0.5
	if dnow ~= driftSent or (dnow and os.clock() - driftSentAt > 0.4) then
		driftSent, driftSentAt = dnow, os.clock()
		local sig = RS:FindFirstChild("PlowDriftSignal")
		if sig then sig:FireServer(dnow) end
	end
end)
