-- WheelClient (2026-10-03, Claude): the Lucky Wheel panel = RNGGui.Panels.Wheel, opened by LeftMenu.Wheel through RNGClient's
-- normal panel logic. You get a free spin for every newly unlocked stage. WheelService (server) picks and grants the prize;
-- this script only draws and animates. Slices come from ReplicatedStorage.WheelConfig.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local W = require(RS:WaitForChild("WheelConfig"))
local SnowUI = require(RS:WaitForChild("SnowUI"))
local player = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Panels"):WaitForChild("Wheel")
local inner = panel:WaitForChild("Inner")
local menuButton = (gui:FindFirstChild("RightMenu") or gui:WaitForChild("LeftMenu")):WaitForChild("Wheel") -- 2026-10-03: moved to the right side
local remote = RS:WaitForChild("WheelRemote")

local FONT = Enum.Font.FredokaOne
local NAVY = Color3.fromRGB(25, 45, 90)
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 205, 60)
local RED = Color3.fromRGB(235, 70, 80)
local N = #W.Segments
local SEG = 360 / N

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
-- everything in this panel skips SnowUI's automatic frost overlay (same clean style as the other menus)
local function frame(parent, props)
	local f = mk("Frame", {BorderSizePixel = 0}, nil)
	f:SetAttribute("SnowUIDecor", true)
	for k, v in pairs(props) do f[k] = v end
	f.Parent = parent
	return f
end
local function round(o, r) mk("UICorner", {CornerRadius = UDim.new(r or 0.5, 0)}, o) return o end
local function outline(o, t, c) return mk("UIStroke", {Thickness = t, Color = c or NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function grad(o, a, b) return mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(a, b)}, o) end
local function text(parent, str, props, max, st)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, Text = str, TextScaled = true, TextWrapped = true, TextColor3 = WHITE, Size = UDim2.fromScale(1, 1)}, nil)
	for k, v in pairs(props or {}) do l[k] = v end
	if st ~= false then mk("UIStroke", {Thickness = st or 2, Color = NAVY}, l) end
	mk("UITextSizeConstraint", {MaxTextSize = max or 30}, l)
	l.Parent = parent
	return l
end
local function button(parent, props)
	local b = mk("TextButton", {Text = "", AutoButtonColor = true, BorderSizePixel = 0}, nil)
	b:SetAttribute("SnowUIDecor", true)
	for k, v in pairs(props) do b[k] = v end
	b.Parent = parent
	return b
end

-- A wheel face. GUI has no wedge shape, so every slice is filled with thin spokes: an invisible full-diameter arm turned around
-- the centre with its top half coloured (Roblox turns frames around their middle, which sits on the wheel's centre).
local function face(parent, step, labelled, z0)
	local rotor = frame(parent, {Name = "Rotor", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = z0})
	local function arm(angle, width, color, name, z)
		local a = frame(rotor, {Name = name, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(width, 1), Rotation = angle, ZIndex = z})
		if color then frame(a, {BackgroundColor3 = color, Size = UDim2.fromScale(1, 0.5), ZIndex = z}) end
		return a
	end
	local width = math.sin(math.rad(step) / 2) * 1.3 -- a little wider than the gap between spokes at the rim
	for i, s in ipairs(W.Segments) do
		local a0 = (i - 1) * SEG
		local a = a0 + step / 2
		while a < a0 + SEG do arm(a, width, s.Color, "Spoke", z0); a += step end
	end
	for i = 0, N - 1 do arm(i * SEG, 0.014, WHITE, "Divider", z0 + 1) end
	local labels = {}
	if labelled then
		for i, s in ipairs(W.Segments) do
			local slot = arm((i - 0.5) * SEG, 0.3, nil, "Slice" .. i, z0 + 2)
			local icon = mk("ImageLabel", {Name = "Icon", BackgroundTransparency = 1, Image = SnowUI.Assets[s.Icon] or SnowUI.Assets.snow, ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.11), Size = UDim2.fromScale(0.6, 0.12), ZIndex = z0 + 2}, nil)
			icon:SetAttribute("SnowUIDecor", true)
			icon.Parent = slot
			local main = text(slot, "", {Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.21), Size = UDim2.fromScale(1, 0.075), ZIndex = z0 + 2}, 26)
			local sub = text(slot, "", {Name = "Sub", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.27), Size = UDim2.fromScale(0.9, 0.045), ZIndex = z0 + 2}, 16, 1.5)
			labels[i] = {main = main, sub = sub}
		end
	end
	return rotor, labels
end

--------------------------------------------------
-- PANEL
--------------------------------------------------
local content = inner:FindFirstChild("Content")
if content then content.Visible = false end
local banner = panel:FindFirstChild("Banner")
if banner and banner:FindFirstChild("Title") then banner.Title.Text = "LUCKY WHEEL" end
local function miniWheel(parent, z, pos, size)
	local disc = frame(parent, {Name = "MiniWheel", BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, ZIndex = z})
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, disc)
	round(disc, 0.5); outline(disc, 2.5); grad(disc, Color3.fromRGB(255, 226, 120), Color3.fromRGB(235, 160, 40))
	local box = frame(disc, {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.84, 0.84), ZIndex = z})
	local rotor = face(box, 7.5, false, z + 1)
	local hub = frame(disc, {BackgroundColor3 = RED, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.24, 0.24), ZIndex = z + 4})
	round(hub, 0.5); outline(hub, 1.5, WHITE)
	local pin = frame(disc, {BackgroundColor3 = RED, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.17, 0.17), Rotation = 45, ZIndex = z + 5})
	round(pin, 0.2); outline(pin, 1.5, WHITE)
	return rotor
end
local bannerIcon = banner and banner:FindFirstChild("Icon")
if bannerIcon then bannerIcon.Image = ""; miniWheel(bannerIcon, 2, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.8)) end

local page = frame(inner, {Name = "WheelPage", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
-- the wheel (left half)
local holder = frame(page, {Name = "Wheel", BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.005, 0.5), Size = UDim2.fromScale(0.5, 1), ZIndex = 1})
mk("UIAspectRatioConstraint", {AspectRatio = 1}, holder)
round(holder, 0.5); outline(holder, 4); grad(holder, Color3.fromRGB(255, 226, 120), Color3.fromRGB(235, 160, 40))
local faceBox = frame(holder, {Name = "Face", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.86), ZIndex = 1})
local rotor, labels = face(faceBox, 2.5, true, 2)
local ring = frame(holder, {Name = "Ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.865, 0.865), ZIndex = 6})
round(ring, 0.5); outline(ring, 4)
local bulbs = {}
for k = 0, 15 do
	local a = math.rad(k * 22.5)
	local b = frame(holder, {Name = "Bulb", BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + 0.466 * math.sin(a), 0.5 - 0.466 * math.cos(a)), Size = UDim2.fromScale(0.042, 0.042), ZIndex = 6})
	round(b, 0.5); outline(b, 1.5)
	bulbs[k + 1] = b
end
local hub = button(holder, {Name = "Hub", BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.21, 0.21), ZIndex = 7})
round(hub, 0.5); outline(hub, 3, WHITE); grad(hub, Color3.fromRGB(255, 120, 120), Color3.fromRGB(215, 50, 60))
text(hub, "SPIN", {Position = UDim2.fromScale(0.12, 0.25), Size = UDim2.fromScale(0.76, 0.5), ZIndex = 8}, 30)
local pointer = frame(holder, {Name = "Pointer", BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.035), Size = UDim2.fromScale(0.09, 0.09), Rotation = 45, ZIndex = 9})
round(pointer, 0.18); outline(pointer, 3, WHITE); grad(pointer, Color3.fromRGB(255, 110, 110), Color3.fromRGB(205, 40, 55))

-- info column (right)
local info = frame(page, {Name = "Info", BackgroundTransparency = 1, Position = UDim2.fromScale(0.535, 0.02), Size = UDim2.fromScale(0.455, 0.96)})
local card = frame(info, {Name = "SpinsCard", BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 0.34)})
round(card, 0.18); outline(card, 3); grad(card, WHITE, Color3.fromRGB(215, 230, 250))
text(card, "FREE SPINS", {Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.9, 0.28), TextColor3 = NAVY}, 28, false)
local count = text(card, "0", {Position = UDim2.fromScale(0.05, 0.34), Size = UDim2.fromScale(0.9, 0.6), TextColor3 = GOLD}, 72, 3)
local hint = text(info, "", {Position = UDim2.fromScale(0, 0.37), Size = UDim2.fromScale(1, 0.16)}, 22)
local spinButton = button(info, {Name = "SpinButton", BackgroundColor3 = WHITE, Position = UDim2.fromScale(0.04, 0.56), Size = UDim2.fromScale(0.92, 0.2)})
round(spinButton, 0.3); outline(spinButton, 3)
local spinGrad = grad(spinButton, Color3.fromRGB(120, 235, 140), Color3.fromRGB(40, 175, 80))
local spinLabel = text(spinButton, "SPIN!", {Position = UDim2.fromScale(0.05, 0.12), Size = UDim2.fromScale(0.9, 0.76)}, 46, 3)
local result = frame(info, {Name = "Result", BackgroundColor3 = WHITE, Position = UDim2.fromScale(0, 0.8), Size = UDim2.fromScale(1, 0.2), Visible = false})
round(result, 0.25); outline(result, 3); grad(result, Color3.fromRGB(255, 248, 215), Color3.fromRGB(255, 214, 120))
local resultScale = mk("UIScale", {Scale = 1}, result)
local resultIcon = mk("ImageLabel", {BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromScale(0.03, 0.1), Size = UDim2.fromScale(0.2, 0.8)}, nil)
resultIcon:SetAttribute("SnowUIDecor", true)
resultIcon.Parent = result
local resultText = text(result, "", {Position = UDim2.fromScale(0.25, 0.1), Size = UDim2.fromScale(0.72, 0.8), TextXAlignment = Enum.TextXAlignment.Left}, 30)

-- menu button: a small wheel (there is no wheel picture asset) that turns while you have spins, plus a count badge
menuButton.Image = ""
local miniRotor = miniWheel(menuButton, 2, UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.68, 0.68))
local badge = frame(menuButton, {Name = "SpinBadge", BackgroundColor3 = Color3.fromRGB(255, 70, 80), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.14), Size = UDim2.fromScale(0.32, 0.32), Visible = false, ZIndex = 9})
mk("UIAspectRatioConstraint", {AspectRatio = 1}, badge)
round(badge, 0.5); outline(badge, 2, WHITE)
local badgeLabel = text(badge, "1", {Position = UDim2.fromScale(0.15, 0.12), Size = UDim2.fromScale(0.7, 0.76), ZIndex = 10}, 30, 1.5)

-- toast when you earn a spin
local toast = mk("TextLabel", {Name = "WheelToast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.27), Size = UDim2.fromScale(0.55, 0.05),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = GOLD, TextTransparency = 1, ZIndex = 40}, gui)
local toastStroke = mk("UIStroke", {Thickness = 3, Color = NAVY, Transparency = 1}, toast)
local toastToken = 0
local function showToast(msg)
	toastToken += 1
	local mine = toastToken
	toast.Text = msg
	toast.TextTransparency, toastStroke.Transparency = 0, 0
	task.delay(3, function()
		if mine ~= toastToken then return end
		TweenService:Create(toast, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		TweenService:Create(toastStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
	end)
end

--------------------------------------------------
-- STATE
--------------------------------------------------
local spins, spinning, rotation = 0, false, 0
local ICON = {Snow = SnowUI.Assets.snow, Jackpot = SnowUI.Assets.rewards, Snow2 = SnowUI.Assets.snow, Luck2 = SnowUI.Assets.luck, Super = SnowUI.Assets.rewards}

local function setSpins(n)
	spins = math.max(0, tonumber(n) or 0)
	count.Text = tostring(spins)
	badge.Visible = spins > 0
	badgeLabel.Text = spins > 9 and "9+" or tostring(spins)
	local can = spins > 0 and not spinning
	spinGrad.Color = can and ColorSequence.new(Color3.fromRGB(120, 235, 140), Color3.fromRGB(40, 175, 80))
		or ColorSequence.new(Color3.fromRGB(190, 198, 214), Color3.fromRGB(140, 150, 172))
	spinLabel.Text = spinning and "SPINNING..." or (spins > 0 and "SPIN!" or "NO SPINS")
	hint.Text = spins > 0 and ("You have " .. spins .. (spins == 1 and " free spin!" or " free spins!"))
		or "Unlock a new stage to get a free spin!"
end

local function showPrizes(list)
	if type(list) ~= "table" then return end
	for i, l in ipairs(labels) do
		local p = list[i]
		if p then l.main.Text = p.Text or ""; l.sub.Text = p.Sub or "" end
	end
end

local function fetch()
	local ok, res = pcall(function() return remote:InvokeServer("Get") end)
	if ok and type(res) == "table" and res.Ok then showPrizes(res.Prizes); setSpins(res.Spins) end
end

local CONFETTI = {Color3.fromRGB(255, 220, 60), Color3.fromRGB(90, 255, 130), Color3.fromRGB(80, 190, 255), Color3.fromRGB(255, 90, 170), Color3.fromRGB(190, 120, 255)}
local function confetti()
	for i = 1, 16 do
		local ang = math.rad(i * 22.5 + math.random(-8, 8))
		local piece = frame(holder, {BackgroundColor3 = CONFETTI[i % #CONFETTI + 1], AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.035, 0.05), Rotation = math.random(0, 90), ZIndex = 12})
		round(piece, 0.3)
		local dist = 0.45 + math.random() * 0.2
		TweenService:Create(piece, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(0.5 + math.sin(ang) * dist, 0.5 - math.cos(ang) * dist),
			Rotation = piece.Rotation + 200, BackgroundTransparency = 1}):Play()
		task.delay(0.85, function() piece:Destroy() end)
	end
end

local function showResult(p)
	if type(p) ~= "table" then return end
	result.Visible = true
	resultIcon.Image = ICON[p.Kind] or SnowUI.Assets.rewards
	resultText.Text = (p.Kind == "Jackpot" and "JACKPOT! " or "YOU WON ") .. (p.Long or p.Text or "")
	resultScale.Scale = 0.6
	TweenService:Create(resultScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
end

local function spin()
	if spinning then return end
	if spins <= 0 then
		hint.Text = "Unlock a new stage to get a free spin!"
		return
	end
	spinning = true
	setSpins(spins)
	result.Visible = false
	local ok, res = pcall(function() return remote:InvokeServer("Spin") end)
	if not (ok and type(res) == "table" and res.Ok and res.Index) then
		spinning = false
		setSpins(type(res) == "table" and res.Spins or spins)
		if type(res) == "table" and res.Msg then hint.Text = res.Msg end
		return
	end
	-- land the chosen slice under the pointer: slice i's middle sits at (i - 0.5) * SEG degrees on the rotor
	local mid = (res.Index - 0.5) * SEG
	local jitter = (math.random() - 0.5) * SEG * 0.6
	local target = rotation - (rotation % 360) - mid + jitter
	while target < rotation + 360 * 5 do target += 360 end
	local tw = TweenService:Create(rotor, TweenInfo.new(W.SpinSeconds or 4.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Rotation = target})
	tw:Play()
	tw.Completed:Wait()
	rotation = target
	spinning = false
	showPrizes(res.Prizes)
	setSpins(player:GetAttribute("WheelSpins") or res.Spins)
	showResult(res.Prize)
	confetti()
end
spinButton.Activated:Connect(spin)
hub.Activated:Connect(spin)

-- bulbs blink (faster while spinning); the menu wheel turns slowly while you have spins
task.spawn(function()
	local on = false
	while true do
		task.wait(spinning and 0.12 or 0.5)
		if panel.Visible then
			on = not on
			for i, b in ipairs(bulbs) do b.BackgroundColor3 = ((i % 2 == 0) == on) and Color3.fromRGB(255, 240, 140) or WHITE end
		end
	end
end)
RunService.RenderStepped:Connect(function(dt)
	miniRotor.Rotation = (miniRotor.Rotation + dt * (spins > 0 and 70 or 22)) % 360 -- 2026-10-03: always turns slowly, faster with free spins
end)

local known = player:GetAttribute("WheelSpins")
player:GetAttributeChangedSignal("WheelSpins"):Connect(function()
	local n = player:GetAttribute("WheelSpins") or 0
	setSpins(n)
	if known == nil and n > 0 then
		showToast("You have " .. n .. (n == 1 and " free spin" or " free spins") .. " on the Lucky Wheel!")
	elseif known ~= nil and n > known then
		showToast(n - known == 1 and "NEW STAGE! You earned a FREE SPIN!" or ("You earned " .. (n - known) .. " FREE SPINS!"))
	end
	known = n
end)
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then result.Visible = false; task.spawn(fetch) end
end)
setSpins(player:GetAttribute("WheelSpins") or 0)
task.spawn(fetch)
