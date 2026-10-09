--[[ UIAUDIT 20261008 PATCH - INSTALL PENDING. Targets Studio script: StarterGui.RNGGui.TreasureReveal. Based on the snapshot captured from Studio on 2026-10-02; re-read the live script in Studio before installing and re-apply on top of any newer edits. Not installed. ]]
-- TreasureReveal (2026-10-01, Claude; PNG v2): Buried Treasures reveal + reward toasts (presentation only).
-- Treasure pictures come from TreasureIcon (PNG ids in TreasureConfig.Images, emoji placeholders until then).
-- TreasureService (server) decides finds, rewards and ownership. One 3D reveal at a time, capped queues,
-- one toast at a time, effects scale with rarity. Settings (player attributes kept in sync by the Treasures
-- book and saved on the server): TreasureSoundOff, TreasureReduced.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")
local TC = require(RS:WaitForChild("TreasureConfig"))
local TreasureIcon = require(RS:WaitForChild("TreasureIcon"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local found = RS:WaitForChild("TreasureFound")
local treasureRemote = RS:WaitForChild("TreasureRemote")
local player = Players.LocalPlayer

local FONT = Enum.Font.FredokaOne
local NAVY, WHITE = Color3.fromRGB(25, 45, 90), Color3.new(1, 1, 1)
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 95, 120)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 230, 130)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 115, 255)),
})
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
-- existing game sounds: soft Reveal shimmer for Commons, roll-reveal stingers (trimmed + faded) for the rarer finds
local SOUNDS = {
	Common    = {Id = "rbxassetid://125078105193243", Volume = 0.22, Speed = 1.5,  Len = 0.5}, -- soft shimmer (game Reveal sound)
	Rare      = {Id = "rbxassetid://102456460734361", Volume = 0.4,  Speed = 1.1,  Len = 1.2},
	Epic      = {Id = "rbxassetid://112301259896345", Volume = 0.45, Speed = 1,    Len = 1.6},
	Legendary = {Id = "rbxassetid://85230589033767",  Volume = 0.5,  Speed = 1,    Len = 2.4},
	Mythic    = {Id = "rbxassetid://108417005528759", Volume = 0.55, Speed = 1,    Len = 3.2},
}
local STYLE = {
	Common    = {Rise = 0.3,  Hover = 0.3,  Fly = 0.32, Sparks = 6,  Ring = 4,   Beads = 14, Light = 0,   Hold = 1.5},
	Rare      = {Rise = 0.36, Hover = 0.55, Fly = 0.36, Sparks = 12, Ring = 5.5, Beads = 18, Light = 1.2, Hold = 1.8},
	Epic      = {Rise = 0.4,  Hover = 0.85, Fly = 0.4,  Sparks = 22, Ring = 7,   Beads = 22, Light = 1.8, Hold = 2.1, Burst = true},
	Legendary = {Rise = 0.45, Hover = 1.3,  Fly = 0.45, Sparks = 28, Ring = 9,   Beads = 24, Light = 2.4, Hold = 2.5, Rays = true, Stars = true},
	Mythic    = {Rise = 0.5,  Hover = 1.9,  Fly = 0.5,  Sparks = 34, Ring = 11,  Beads = 28, Light = 3,   Hold = 3.0, Rays = true, Stars = true, Rainbow = true},
}
local MAX_REVEALS, MAX_TOASTS, MAX_DISTANCE = 4, 3, 90

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function reduced() return player:GetAttribute("TreasureReduced") == true end
local function hue(t, k) return Color3.fromHSV((t * 0.45 + (k or 0)) % 1, 0.6, 1) end

-- load the saved settings once (the book keeps them in sync afterwards)
task.spawn(function()
	for _ = 1, 10 do
		local ok, res = pcall(function() return treasureRemote:InvokeServer("Get") end)
		if ok and type(res) == "table" then
			if player:GetAttribute("TreasureSoundOff") == nil then player:SetAttribute("TreasureSoundOff", res.Sound == false) end
			if player:GetAttribute("TreasureReduced") == nil then player:SetAttribute("TreasureReduced", res.Reduced == true) end
			return
		end
		task.wait(1)
	end
end)

local fxFolder = mk("Folder", {Name = "TreasureFX"}, workspace)

local function playSound(rarity, volumeScale)
	if player:GetAttribute("TreasureSoundOff") then return end
	local s = SOUNDS[rarity]
	local snd = mk("Sound", {SoundId = s.Id, Volume = s.Volume * (volumeScale or 1), PlaybackSpeed = s.Speed}, SoundService)
	snd:Play()
	task.delay(s.Len, function()
		TweenService:Create(snd, TweenInfo.new(0.35), {Volume = 0}):Play()
		task.wait(0.4)
		snd:Destroy()
	end)
end

local function fxPart(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Size = Vector3.new(0.3, 0.3, 0.3)
	for k, v in pairs(props) do p[k] = v end
	p.Parent = fxFolder
	return p
end

local function burst(pos, texture, colorSeq, count, size, speed, life, gravity)
	local a = fxPart({Transparency = 1, Size = Vector3.new(0.4, 0.4, 0.4), CFrame = CFrame.new(pos)})
	local e = mk("ParticleEmitter", {Enabled = false, Rate = 0, Texture = texture, Color = colorSeq, LightEmission = (texture == SPARKLE) and 1 or 0,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}),
		Lifetime = NumberRange.new(life * 0.6, life), Speed = NumberRange.new(speed * 0.5, speed), SpreadAngle = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, -gravity, 0), EmissionDirection = Enum.NormalId.Top}, a)
	e:Emit(count)
	task.delay(life + 0.3, function() a:Destroy() end)
end

-- glowing ring of beads that expands across the ground under the treasure
local function ringBurst(pos, color, diameter, count, delay)
	task.delay(delay or 0, function()
		local beads = {}
		for i = 1, count do beads[i] = fxPart({Shape = Enum.PartType.Ball, Size = Vector3.new(0.28, 0.28, 0.28), Color = color or hue(0, i / count)}) end
		local t0 = os.clock()
		while true do
			local a = math.clamp((os.clock() - t0) / 0.65, 0, 1)
			local r = 0.6 + (diameter / 2 - 0.6) * (1 - (1 - a) ^ 3)
			for i, b in ipairs(beads) do
				local ang = i / count * math.pi * 2
				b.CFrame = CFrame.new(pos + Vector3.new(math.cos(ang) * r, 0.3, math.sin(ang) * r))
				b.Transparency = 0.1 + 0.9 * a
			end
			if a >= 1 then break end
			RunService.RenderStepped:Wait()
		end
		for _, b in ipairs(beads) do b:Destroy() end
	end)
end

local function revealModel(entry)
	local info, item, rar = entry.info, entry.item, entry.rar
	local st = STYLE[item.Rarity]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local pos = typeof(info.Pos) == "Vector3" and info.Pos or nil
	if not root or not pos or (root.Position - pos).Magnitude > MAX_DISTANCE then return end
	local red = reduced()
	local colorSeq = st.Rainbow and RAINBOW or ColorSequence.new(rar.Color, WHITE)
	-- 1) a short puff of snow + rarity sparkles
	burst(pos + Vector3.new(0, 0.6, 0), SMOKE, ColorSequence.new(Color3.fromRGB(245, 250, 255)), red and 5 or 10, 1.0, 9, 0.6, 18)
	if not red then burst(pos + Vector3.new(0, 0.8, 0), SPARKLE, colorSeq, st.Sparks, 0.45, 9, 0.9, 6) end
	if st.Burst and not red then burst(pos + Vector3.new(0, 1.2, 0), SPARKLE, ColorSequence.new(Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 180, 255)), 18, 0.6, 12, 0.7, 2) end
	-- 2) the treasure picture pops out, flips and hovers on a rarity glow (billboard, always faces the camera)
	local holder = fxPart({Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(pos)})
	local bb = mk("BillboardGui", {Size = UDim2.fromScale(0.1, 0.1), LightInfluence = 0, MaxDistance = 220, ResetOnSpawn = false}, holder)
	local glow = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.1, 1.1),
		BackgroundColor3 = st.Rainbow and WHITE or rar.Color, BackgroundTransparency = red and 0.75 or 0.45, ZIndex = 1}, bb)
	mk("UICorner", {CornerRadius = UDim.new(1, 0)}, glow)
	mk("UIStroke", {Thickness = 3, Color = WHITE, Transparency = 0.3}, glow)
	local glowGrad = st.Rainbow and mk("UIGradient", {Color = RAINBOW}, glow) or nil
	local iconBox = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2}, bb)
	TreasureIcon.Create(item, {ZIndex = 2}).Parent = iconBox
	if st.Light > 0 then mk("PointLight", {Brightness = red and st.Light * 0.6 or st.Light, Range = 9, Color = rar.Color}, holder) end
	-- 3) a glowing ring expands beneath it
	ringBurst(pos, (not st.Rainbow) and rar.Color or nil, st.Ring * (red and 0.7 or 1), red and 12 or st.Beads, 0)
	if (st.Rays or st.Stars) and not red then ringBurst(pos, (not st.Rainbow) and rar.Color or nil, st.Ring * 1.35, st.Beads, 0.28) end
	local extras = {}
	if st.Rays and not red then
		for i = 1, 6 do extras[#extras + 1] = {ray = true, i = i, p = fxPart({Size = Vector3.new(0.16, 2.8, 0.16), Transparency = 0.4,
			Color = st.Rainbow and hue(0, i / 6) or Color3.fromRGB(255, 215, 90)})} end
	end
	if st.Stars and not red then
		for i = 1, 4 do extras[#extras + 1] = {i = i, p = fxPart({Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4),
			Color = st.Rainbow and hue(0, i / 4) or Color3.fromRGB(255, 245, 200)})} end
	end
	playSound(item.Rarity)
	local BASE = 3.4 -- studs
	local start, top = pos + Vector3.new(0, 0.6, 0), pos + Vector3.new(0, 5.2, 0) -- hovers above head height so the player never hides it
	local hover = red and math.min(st.Hover, 0.35) or st.Hover
	local t0, finished = os.clock(), false
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local center, size, flip, tilt = top, BASE, 1, 0
		if t < st.Rise then
			local a = t / st.Rise
			local e = TweenService:GetValue(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			center = start:Lerp(top, e)
			size = BASE * math.clamp(e, 0.05, 1.15)
			flip = math.abs(math.cos(a * math.pi * 2)) -- two quick flips while it pops out
		elseif t < st.Rise + hover then
			local h = t - st.Rise
			center = top + Vector3.new(0, math.sin(h * 4) * 0.16, 0)
			tilt = math.sin(h * 3) * 6
		else
			-- 4) it flies to the player and shrinks into the reward toast
			local a = math.clamp((t - st.Rise - hover) / st.Fly, 0, 1)
			local e = TweenService:GetValue(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local target = (root.Parent and root.Position or top) + Vector3.new(0, 1, 0)
			center = top:Lerp(target, e)
			size = BASE * (1 - 0.85 * e)
			if a >= 1 then finished = true end
		end
		holder.CFrame = CFrame.new(center)
		bb.Size = UDim2.new(size, 0, size, 0)
		iconBox.Size = UDim2.fromScale(math.max(flip, 0.06), 1)
		iconBox.Rotation = tilt
		if glowGrad then glowGrad.Rotation = (t * 90) % 360 end
		local leaving = t > st.Rise + hover
		for _, x in ipairs(extras) do
			if leaving then
				x.p.Transparency = 1
			elseif x.ray then
				x.p.CFrame = CFrame.new(center) * CFrame.Angles(0, x.i / 6 * math.pi * 2 + t * 0.9, 0) * CFrame.Angles(math.rad(62), 0, 0) * CFrame.new(0, 1.9, 0)
				x.p.Transparency = 0.4 + 0.15 * math.sin(t * 3 + x.i)
			else
				local b = t * 2.4 + x.i / 4 * math.pi * 2
				x.p.CFrame = CFrame.new(center + Vector3.new(math.cos(b) * 2.1, 0.25 + math.sin(t * 3 + x.i) * 0.3, math.sin(b) * 2.1))
			end
		end
	end)
	local deadline = os.clock() + st.Rise + hover + st.Fly + 2
	while not finished and os.clock() < deadline do task.wait() end
	conn:Disconnect()
	for _, x in ipairs(extras) do x.p:Destroy() end
	holder:Destroy()
	if root.Parent then burst(root.Position + Vector3.new(0, 1, 0), SPARKLE, colorSeq, red and 3 or 8, 0.3, 4, 0.5, 0) end
end

--------------------------------------------------
-- REWARD TOAST (one at a time, right side)
--------------------------------------------------
local toastGui = mk("ScreenGui", {Name = "TreasureToastGui", DisplayOrder = 55, IgnoreGuiInset = true, ResetOnSpawn = false}, player:WaitForChild("PlayerGui"))
local HIDDEN, SHOWN = UDim2.new(1, 340, 0.6, 0), UDim2.new(1, -16, 0.6, 0)
local toast = mk("Frame", {Name = "Toast", AnchorPoint = Vector2.new(1, 0.5), Position = HIDDEN, Size = UDim2.fromOffset(300, 84), BackgroundColor3 = WHITE, Visible = false}, toastGui)
mk("UICorner", {CornerRadius = UDim.new(0.25, 0)}, toast)
mk("UIStroke", {Thickness = 3.5, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, toast)
local toastGrad = mk("UIGradient", {Rotation = 90}, toast)
local iconHolder = mk("Frame", {Name = "Icon", BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(68, 68)}, toast)
local function text(parent, props, stroke)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Font, l.TextScaled, l.TextColor3, l.TextXAlignment = 1, FONT, true, WHITE, Enum.TextXAlignment.Left
	for k, v in pairs(props) do l[k] = v end
	if stroke ~= false then mk("UIStroke", {Thickness = stroke or 2.2, Color = NAVY}, l) end
	l.Parent = parent
	return l
end
local nameL = text(toast, {Position = UDim2.fromOffset(84, 7), Size = UDim2.fromOffset(204, 30)})
local rarPill = mk("Frame", {Position = UDim2.fromOffset(84, 44), Size = UDim2.fromOffset(96, 26), BackgroundColor3 = WHITE}, toast)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, rarPill)
mk("UIStroke", {Thickness = 2, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, rarPill)
local rarGrad = mk("UIGradient", {}, rarPill)
local rarL = text(rarPill, {Position = UDim2.fromScale(0.08, 0.12), Size = UDim2.fromScale(0.84, 0.76), TextXAlignment = Enum.TextXAlignment.Center}, 1.8)
local snowL = text(toast, {Position = UDim2.fromOffset(186, 42), Size = UDim2.fromOffset(104, 30), TextXAlignment = Enum.TextXAlignment.Right})
local countL = text(toast, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, -12), Size = UDim2.fromOffset(60, 24), TextXAlignment = Enum.TextXAlignment.Right})
local newBadge = mk("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(8, -2), Size = UDim2.fromOffset(150, 26), Rotation = -4, BackgroundColor3 = Color3.fromRGB(255, 220, 60), Visible = false}, toast)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, newBadge)
mk("UIStroke", {Thickness = 2.5, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, newBadge)
text(newBadge, {Text = "NEW DISCOVERY!", Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76), TextColor3 = NAVY, TextXAlignment = Enum.TextXAlignment.Center}, false)
local hintL = text(toast, {Position = UDim2.new(0, 10, 1, 4), Size = UDim2.fromOffset(280, 20), Visible = false, Text = "Your first treasure! Open TREASURES to see it."}, 2)

-- UIAUDIT: on touch the toast must stop left of the DRIFT/DRIVE/RECOVER column that PlowDriveClient builds in PlowDriveGui
-- (colW = max(130, floor(0.17 * W)) wide, 8 px from the right edge) plus a 16 px gap, so its right edge is W-(colW+24).
-- Both guis use DeviceSafeInsets on touch, so W (this gui's AbsoluteSize) and the column share one coordinate space.
-- A toast wider than the free space is scaled down (children are fixed-offset). Desktop keeps the old 16 px inset, scale 1.
local toastScale = mk("UIScale", {Scale = 1}, toast)
local baseInsets
pcall(function() baseInsets = toastGui.ScreenInsets end)
local toastHolding = false -- true while the toast rests at SHOWN, so a resize can re-snap it
local function refreshToastShown()
	local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
	pcall(function()
		local want = touch and Enum.ScreenInsets.DeviceSafeInsets or baseInsets
		if want and toastGui.ScreenInsets ~= want then toastGui.ScreenInsets = want end
	end)
	if not touch then
		SHOWN, toastScale.Scale = UDim2.new(1, -16, 0.6, 0), 1
		return
	end
	local w = toastGui.AbsoluteSize.X
	if w <= 0 then -- not laid out yet: the camera viewport is the same size on a phone
		local cam = workspace.CurrentCamera
		w = cam and cam.ViewportSize.X or 0
	end
	local colW = math.max(130, math.floor(0.17 * w))
	SHOWN = UDim2.new(1, -(colW + 24), 0.6, 0)
	toastScale.Scale = w > 0 and math.clamp((w - (colW + 24) - 8) / toast.Size.X.Offset, 0.5, 1) or 1
end
toastGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() -- connected once
	refreshToastShown()
	if toastHolding and toast.Visible then toast.Position = SHOWN end
end)
refreshToastShown()

local toastQueue, mergedN, mergedSnow = {}, 0, 0
local function showToast(entry)
	toastHolding = false
	refreshToastShown() -- also picks up a keyboard/touch change since the last toast
	iconHolder:ClearAllChildren()
	if entry.merged then
		TreasureIcon.Create({Image = TC.Images and TC.Images.MenuIcon or nil, Emoji = "🎁"}).Parent = iconHolder
		nameL.Text = "+" .. entry.merged .. " MORE TREASURES"
		rarL.Text = "FOUND"
		rarGrad.Color = ColorSequence.new(Color3.fromRGB(170, 205, 240))
		toastGrad.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255), Color3.fromRGB(175, 210, 245))
		snowL.Text = "+" .. NumberFormat.Abbreviate(entry.snow) .. " ❄"
		countL.Text = ""
		newBadge.Visible, hintL.Visible = false, false
	else
		local info, item, rar = entry.info, entry.item, entry.rar
		TreasureIcon.Create(item).Parent = iconHolder
		nameL.Text = item.Name
		rarL.Text = string.upper(item.Rarity)
		rarGrad.Color = item.Rarity == "Mythic" and RAINBOW or ColorSequence.new(rar.Color)
		toastGrad.Color = item.Rarity == "Mythic" and RAINBOW or ColorSequence.new(rar.Color:Lerp(WHITE, 0.6), rar.Color:Lerp(WHITE, 0.1))
		snowL.Text = "+" .. NumberFormat.Abbreviate(info.Snow or 0) .. " ❄"
		countL.Text = "x" .. tostring(info.Count or 1)
		newBadge.Visible = info.New == true
		hintL.Visible = info.First == true
	end
	toast.Visible = true
	toast.Position = HIDDEN
	local slideIn = TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Position = SHOWN})
	slideIn:Play()
	local hold = entry.hold or 1.8
	if #toastQueue > 0 then hold = math.min(hold, 1.1) end
	task.wait(0.35)
	slideIn:Cancel()
	toast.Position = SHOWN -- lands on the current SHOWN even if the screen was resized during the slide
	toastHolding = true
	task.wait(hold)
	toastHolding = false
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = HIDDEN}):Play()
	task.wait(0.28)
	toast.Visible = false
end
local function lowPriority(e) return not e.info.New and e.rar.Order <= 2 end
local function pushToast(entry)
	entry.hold = STYLE[entry.item.Rarity].Hold
	if #toastQueue >= MAX_TOASTS then
		for i, e in ipairs(toastQueue) do
			if lowPriority(e) then table.remove(toastQueue, i); mergedN += 1; mergedSnow += e.info.Snow or 0; break end
		end
		if #toastQueue >= MAX_TOASTS and lowPriority(entry) then mergedN += 1; mergedSnow += entry.info.Snow or 0; return end
	end
	table.insert(toastQueue, entry)
end
task.spawn(function()
	while true do
		local e = table.remove(toastQueue, 1)
		if e then
			local ok, err = pcall(showToast, e)
			if not ok then warn("[TreasureReveal] toast: " .. tostring(err)) end
		elseif mergedN > 0 then
			local n, s = mergedN, mergedSnow
			mergedN, mergedSnow = 0, 0
			pcall(showToast, {merged = n, snow = s, hold = 1.5})
		else
			task.wait(0.1)
		end
	end
end)

--------------------------------------------------
-- REVEAL QUEUE (one 3D reveal at a time; low-rarity repeats skip the 3D part when busy)
--------------------------------------------------
local revealQueue = {}
local function pushReveal(info)
	local item = TC.ById[info.Id]
	if not item then return end
	local entry = {info = info, item = item, rar = TC.RarityById[item.Rarity]}
	if #revealQueue >= MAX_REVEALS then
		if lowPriority(entry) then pushToast(entry) return end
		for i, e in ipairs(revealQueue) do
			if lowPriority(e) then table.remove(revealQueue, i); pushToast(e); break end
		end
	end
	table.insert(revealQueue, entry)
end
task.spawn(function()
	while true do
		local e = table.remove(revealQueue, 1)
		if e then
			local ok, err = pcall(revealModel, e)
			if not ok then warn("[TreasureReveal] " .. tostring(err)) end
			pushToast(e)
		else
			task.wait(0.1)
		end
	end
end)

--------------------------------------------------
-- MYTHIC ANNOUNCEMENT (finds by nearby players)
--------------------------------------------------
local ann = mk("Frame", {Name = "Announce", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.26, 0), Size = UDim2.new(0.9, 0, 0, 48), BackgroundColor3 = WHITE, Visible = false}, toastGui)
-- UIAUDIT: 90% of the screen width, capped at the original 440x48, so a narrow (portrait) screen no longer clips the pill
mk("UISizeConstraint", {MaxSize = Vector2.new(440, 48)}, ann)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, ann)
mk("UIStroke", {Thickness = 3, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, ann)
mk("UIGradient", {Color = RAINBOW}, ann)
local annL = text(ann, {Position = UDim2.fromScale(0.04, 0.14), Size = UDim2.fromScale(0.92, 0.72), TextXAlignment = Enum.TextXAlignment.Center})
local annScale = mk("UIScale", {Scale = 1}, ann)
local annQueue = {}
task.spawn(function()
	while true do
		local a = table.remove(annQueue, 1)
		local item = a and TC.ById[a.Id]
		if item then
			annL.Text = "✨ " .. tostring(a.Finder) .. " found a MYTHIC " .. item.Name .. "! ✨"
			ann.Visible = true
			annScale.Scale = 0.4
			TweenService:Create(annScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
			playSound("Legendary", 0.6)
			task.wait(3)
			TweenService:Create(annScale, TweenInfo.new(0.2), {Scale = 0}):Play()
			task.wait(0.22)
			ann.Visible = false
		else
			task.wait(0.2)
		end
	end
end)

found.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then return end
	if info.Announce then
		if #annQueue < 2 then table.insert(annQueue, info) end
		return
	end
	pushReveal(info)
end)
