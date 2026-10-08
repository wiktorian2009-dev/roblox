-- RebirthClient v2 (Claude, 2026-10-01): the Rebirth menu now uses the game's icy panel art (same as Shop/Inventory)
-- with a visual layout: next-level header, reward cards (now -> next), requirement checklist with a chunky progress
-- bar, keep/reset pills and a pulsing button with the same two-step confirm. (Milestone strip removed on request.)
-- Rules and server calls are unchanged (RebirthConfig, RequestRebirth). Old version: ServerStorage.RebirthClient_Before20261001.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local R = require(RS:WaitForChild("RebirthConfig"))
local Stages = require(RS:WaitForChild("StageConfig"))
local Format = require(RS:WaitForChild("NumberFormat"))
local request = RS:WaitForChild("RequestRebirth")
local gui = script.Parent
local panel = gui:WaitForChild("Panels"):WaitForChild("Rebirth")
local inner = panel:WaitForChild("Inner")
local content = inner:WaitForChild("Content")

local FONT = Enum.Font.FredokaOne
local C = Color3.fromRGB
local S = UDim2.fromScale
local WHITE = C(255, 255, 255)
local NAVY = C(31, 35, 76)
local PURPLE = C(120, 60, 215)
local GREEN_TXT, GREEN_BG, GREEN_LINE = C(30, 130, 70), C(220, 248, 228), C(60, 175, 100)
local RED_TXT, RED_BG = C(190, 50, 75), C(255, 228, 232)
local ICON_REBIRTH = "rbxassetid://88092085513174"
local ICON_SNOW = "rbxassetid://83244601927288"
local ICON_LUCK = "rbxassetid://74613534440214"

-- same icy frame as the other menus, a little larger for the extra info (aspect kept so the art is not stretched)
panel.Size = S(0.7, 0.8)
inner.Size = S(0.83, 0.665) -- 2026-10-03 (Claude, redo): same inner height as the other panels (no empty band at the bottom)
local cap = Instance.new("UISizeConstraint"); cap.MaxSize = Vector2.new(1100, 710); cap.Parent = panel
inner.BackgroundTransparency = 1
for _, c in ipairs(content:GetChildren()) do c:Destroy() end
content.CanvasSize = UDim2.new()
content.AutomaticCanvasSize = Enum.AutomaticSize.None
content.ScrollingEnabled = false
content.ScrollBarThickness = 0
content.BackgroundTransparency = 1
content.ClipsDescendants = false

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) return make("UICorner", {CornerRadius = r or UDim.new(0.25, 0)}, o) end
local function outline(o, t, color, border)
	return make("UIStroke", {Thickness = t, Color = color or NAVY, LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = border and Enum.ApplyStrokeMode.Border or Enum.ApplyStrokeMode.Contextual}, o)
end
local function gradient(o, a, b) return make("UIGradient", {Color = ColorSequence.new(a, b), Rotation = 90}, o) end
local function text(parent, name, t, props, maxSize, strokeThickness)
	local l = make("TextLabel", {Name = name, Text = t, Font = FONT, TextScaled = true, TextWrapped = true,
		BackgroundTransparency = 1, TextColor3 = NAVY}, parent)
	for k, v in pairs(props) do l[k] = v end
	make("UITextSizeConstraint", {MaxTextSize = maxSize or 30, MinTextSize = 8}, l)
	if strokeThickness then outline(l, strokeThickness, NAVY) end
	return l
end
-- 2026-10-03 (Claude, redo): every box skips SnowUI's frost overlay (its rim and mismatched corners made this menu look messy)
local function box(parent, name, pos, size, color)
	local f = make("Frame", {Name = name, Position = pos, Size = size, BackgroundColor3 = color or WHITE, BorderSizePixel = 0}, parent)
	f:SetAttribute("SnowUIDecor", true)
	return f
end

-- HEADER: a solid purple strip (purple text on the blue panel was unreadable): icon, next level, subtitle, done pill
local header = box(content, "Header", S(0, 0), S(1, 0.16), WHITE)
corner(header, UDim.new(0.3, 0)); outline(header, 3, NAVY, true); gradient(header, C(175, 115, 255), C(112, 58, 205))
make("ImageLabel", {Name = "Badge", Image = ICON_REBIRTH, BackgroundTransparency = 1, Position = S(0.01, 0.06), Size = S(0.1, 0.88), ScaleType = Enum.ScaleType.Fit}, header)
local countLabel = text(header, "Count", "NEXT: REBIRTH 1", {Position = S(0.12, 0.07), Size = S(0.58, 0.5),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE}, 32, 2)
local subtitle = text(header, "Subtitle", "", {Position = S(0.12, 0.58), Size = S(0.6, 0.33),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE}, 18, 1.5)
local donePill = box(header, "DonePill", S(0.735, 0.2), S(0.25, 0.6), WHITE)
corner(donePill, UDim.new(1, 0)); outline(donePill, 2.5, NAVY, true)
local doneLabel = text(donePill, "Done", "0 / 50 DONE", {Position = S(0.08, 0.14), Size = S(0.84, 0.72), TextColor3 = PURPLE}, 22)

-- REWARD CARDS: icon, title, now -> next, +delta chip
local function rewardCard(name, x, icon, title, light, dark)
	local card = box(content, name, S(x, 0.18), S(0.49, 0.27), dark)
	corner(card, UDim.new(0.22, 0)); outline(card, 3, NAVY, true); gradient(card, light, dark)
	make("ImageLabel", {Name = "Icon", Image = icon, BackgroundTransparency = 1, Position = S(0.02, 0.08), Size = S(0.22, 0.84),
		ScaleType = Enum.ScaleType.Fit}, card)
	text(card, "Title", title, {Position = S(0.26, 0.06), Size = S(0.72, 0.3), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE}, 20, 1.5)
	local now = text(card, "Now", "x1", {Position = S(0.26, 0.42), Size = S(0.17, 0.46), TextColor3 = C(228, 238, 255)}, 28, 1.5)
	text(card, "Arrow", "→", {Position = S(0.43, 0.42), Size = S(0.09, 0.46), TextColor3 = WHITE}, 28, 1.5)
	local value = text(card, "Value", "x1.5", {Position = S(0.52, 0.36), Size = S(0.27, 0.58), TextColor3 = C(255, 226, 90)}, 40, 2)
	local chip = box(card, "Plus", S(0.8, 0.45), S(0.18, 0.4), WHITE); corner(chip, UDim.new(1, 0))
	local plus = text(chip, "PlusText", "+0.5", {Position = S(0.08, 0.12), Size = S(0.84, 0.76), TextColor3 = dark}, 20)
	return now, value, plus
end
local snowNow, snowBonus, snowPlus = rewardCard("SnowBonus", 0, ICON_SNOW, "SNOW INCOME", C(110, 200, 255), C(45, 130, 230))
local luckNow, luckBonus, luckPlus = rewardCard("LuckBonus", 0.51, ICON_LUCK, "ROLL LUCK", C(120, 225, 130), C(40, 165, 85))

-- REQUIREMENTS: stage chip + chunky snow progress bar
local reqChip = box(content, "Requirement", S(0, 0.49), S(0.37, 0.14), C(255, 244, 214))
corner(reqChip, UDim.new(0.3, 0))
local reqStroke = outline(reqChip, 2.5, C(230, 160, 40), true)
local requirement = text(reqChip, "RequirementText", "", {Position = S(0.05, 0.12), Size = S(0.9, 0.76), TextColor3 = C(160, 95, 10)}, 22)
reqChip.Visible = false -- 2026-10-04 (Claude): no stage requirement any more
local track = box(content, "Progress", S(0, 0.49), S(1, 0.14), C(205, 220, 240))
corner(track, UDim.new(1, 0)); outline(track, 2.5, NAVY, true)
local fill = box(track, "Fill", S(0, 0), S(0, 1), WHITE); corner(fill, UDim.new(1, 0))
local fillGrad = gradient(fill, C(140, 225, 255), C(60, 160, 240))
local price = text(track, "Price", "", {Position = S(0.04, 0.12), Size = S(0.92, 0.76), TextColor3 = WHITE, ZIndex = 3}, 22, 2)

-- KEEP / RESET pills
local function pill(name, x, t, bg, fg)
	local f = box(content, name, S(x, 0.67), S(0.49, 0.1), bg)
	corner(f, UDim.new(1, 0)); outline(f, 2, fg, true)
	text(f, "Text", t, {Position = S(0.04, 0.1), Size = S(0.92, 0.8), TextColor3 = fg}, 18)
	return f
end
pill("Keep", 0, "✓ KEEP: upgrades • parts • pets", GREEN_BG, GREEN_TXT) -- 2026-10-03 (Claude): upgrades are kept now
pill("Reset", 0.51, "RESET: snow • stages", RED_BG, RED_TXT)

-- BUTTONS
local buy = make("TextButton", {Name = "RebirthButton", Text = "", AutoButtonColor = false, Position = S(0.12, 0.81), Size = S(0.76, 0.19),
	BackgroundColor3 = WHITE, BorderSizePixel = 0}, content)
buy:SetAttribute("SnowUIDecor", true)
corner(buy, UDim.new(0.35, 0)); outline(buy, 3, NAVY, true)
local buyGrad = gradient(buy, C(190, 120, 255), PURPLE)
local buyScale = make("UIScale", {Scale = 1}, buy)
local buyText = text(buy, "Label", "REBIRTH!", {Position = S(0.05, 0.1), Size = S(0.9, 0.8), TextColor3 = WHITE}, 34, 2.5)
local cancel = make("TextButton", {Name = "CancelRebirth", Text = "", AutoButtonColor = true, Position = S(0, 0.81), Size = S(0.3, 0.19),
	BackgroundColor3 = C(150, 160, 185), BorderSizePixel = 0, Visible = false}, content)
cancel:SetAttribute("SnowUIDecor", true)
corner(cancel, UDim.new(0.35, 0)); outline(cancel, 3, NAVY, true)
text(cancel, "Label", "CANCEL", {Position = S(0.06, 0.12), Size = S(0.88, 0.76), TextColor3 = WHITE}, 28, 2)

-- STATE
local confirming, expected, busy, ready = false, nil, false, false
local feedback, feedbackGood = "", false
local function mult(n)
	local s = ("%.2f"):format(n)
	s = s:gsub("0+$", "")
	s = s:gsub("%.$", "")
	return "x" .. s
end
local function snow()
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Snow") and ls.Snow.Value or 0
end
local pulseConn
local function setPulse(on)
	if on and not pulseConn then
		pulseConn = RunService.RenderStepped:Connect(function()
			buyScale.Scale = 1 + 0.035 * (0.5 + 0.5 * math.sin(os.clock() * 4.5))
		end)
	elseif not on and pulseConn then
		pulseConn:Disconnect(); pulseConn = nil; buyScale.Scale = 1
	end
end

local function refresh()
	local raw = player:GetAttribute("Rebirths")
	local count = R.Count(raw)
	local req = R.Requirement(count)
	local a, b = R.Multipliers(count)
	local na, nb = R.Multipliers(req and req.Level or count)
	snowNow.Text, snowBonus.Text, snowPlus.Text = mult(a), mult(na), "+" .. mult(na - a):sub(2)
	luckNow.Text, luckBonus.Text, luckPlus.Text = mult(b), mult(nb), "+" .. mult(nb - b):sub(2)
	snowPlus.Parent.Visible, luckPlus.Parent.Visible = req ~= nil, req ~= nil
	doneLabel.Text = count .. " / " .. R.MaxRebirths .. " DONE"
	countLabel.Text = req and ("NEXT: REBIRTH " .. req.Level) or "MAX REBIRTH!"
	local have = snow()
	ready = raw ~= nil and req ~= nil and have >= req.Cost -- 2026-10-04 (Claude): no stage requirement, only the Snow cost
	if req then
		price.Text = "Snow " .. Format.Abbreviate(have) .. " / " .. Format.Abbreviate(req.Cost)
		local k = math.clamp(have / req.Cost, 0, 1)
		fill.Size = S(k, 1)
		fill.Visible = k > 0.002
		fillGrad.Color = k >= 1 and ColorSequence.new(C(150, 240, 170), C(50, 185, 95)) or ColorSequence.new(C(140, 225, 255), C(60, 160, 240))
	else
		price.Text = "All milestones done! Enjoy your permanent bonuses!"
		fill.Size = S(1, 1); fill.Visible = true
		fillGrad.Color = ColorSequence.new(C(150, 240, 170), C(50, 185, 95))
	end
	if confirming and (expected ~= count or not ready) then confirming = false end
	cancel.Visible = confirming
	buy.Position = confirming and S(0.33, 0.81) or S(0.12, 0.81)
	buy.Size = confirming and S(0.67, 0.19) or S(0.76, 0.19)
	buyText.Text = busy and "REBIRTHING..." or confirming and "CONFIRM RESET" or not req and "MAX REBIRTH" or ready and "REBIRTH!" or "NOT READY YET"
	buyGrad.Color = (ready and confirming) and ColorSequence.new(C(255, 125, 145), C(205, 50, 85))
		or ready and ColorSequence.new(C(190, 120, 255), PURPLE)
		or ColorSequence.new(C(178, 185, 204), C(132, 140, 165))
	subtitle.Text = feedback ~= "" and feedback
		or confirming and "Snow and stages reset. Upgrades, vehicle parts and pets stay!"
		or ready and "You're ready! Start over stronger - bonuses are permanent."
		or "Start over stronger - your bonuses are permanent!"
	subtitle.TextColor3 = feedback ~= "" and (feedbackGood and C(190, 255, 205) or C(255, 205, 215)) or confirming and C(255, 205, 215) or WHITE -- light colours on the purple strip
	setPulse(panel.Visible and ready and not busy and not confirming)
end

local function shake()
	local base = buy.Position
	for i, dx in ipairs({-0.012, 0.012, -0.008, 0.008, 0}) do
		task.delay(i * 0.04, function() if not confirming then buy.Position = base + S(dx, 0) end end)
	end
end
local CONFETTI = {C(255, 220, 60), C(90, 255, 130), C(80, 190, 255), C(255, 90, 170), C(190, 120, 255)}
local function confetti()
	local origin = Vector2.new(0.5, 0.9)
	for i = 1, 18 do
		local ang = math.rad(200 + (i / 18) * 140)
		local dist = 0.18 + math.random() * 0.25
		local piece = box(content, "Confetti", S(origin.X, origin.Y), S(0.018, 0.03), CONFETTI[i % #CONFETTI + 1])
		piece.AnchorPoint = Vector2.new(0.5, 0.5); piece.Rotation = math.random(0, 90); piece.ZIndex = 10
		corner(piece, UDim.new(0.3, 0))
		TweenService:Create(piece, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Position = S(origin.X + math.cos(ang) * dist, origin.Y + math.sin(ang) * dist * 1.6),
			Rotation = piece.Rotation + 220, BackgroundTransparency = 1}):Play()
		task.delay(0.75, function() piece:Destroy() end)
	end
end

buy.Activated:Connect(function()
	if busy then return end
	local count = R.Count(player:GetAttribute("Rebirths"))
	local req = R.Requirement(count)
	if not req or snow() < req.Cost then shake() return end
	if not confirming then confirming = true expected = count feedback = "" refresh() return end
	busy = true refresh()
	local ok, success, message = pcall(function() return request:InvokeServer(expected) end)
	busy = false confirming = false
	feedback = ok and tostring(message or "Please try again.") or "Connection problem. Please try again."
	feedbackGood = false
	if ok and success then
		feedback = "REBIRTH COMPLETE! Your permanent boosts are active."
		feedbackGood = true
		local scale = panel:FindFirstChildOfClass("UIScale")
		if scale then scale.Scale = 0.94 TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play() end
		confetti()
	end
	refresh()
end)
cancel.Activated:Connect(function() confirming = false feedback = "" refresh() end)
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	gui:SetAttribute("RebirthMenuOpen", panel.Visible)
	confirming = false feedback = ""
	if panel.Visible then refresh() else setPulse(false) end
end)
player:GetAttributeChangedSignal("Rebirths"):Connect(refresh)
task.spawn(function() player:WaitForChild("leaderstats"):WaitForChild("Snow").Changed:Connect(function() if panel.Visible then refresh() end end) end)
gui:SetAttribute("RebirthMenuOpen", panel.Visible)
refresh()

--------------------------------------------------
-- NOTIFICATION (2026-10-04, Claude): tell the player when the next rebirth is affordable
--------------------------------------------------
-- 1) a pulsing red "!" on the REBIRTH menu button for as long as you can afford it
-- 2) a purple banner once per rebirth level and session (tap it to open the Rebirth menu); it waits for intros, cutscenes and the Upgrades page
do
	local menuButton = gui:WaitForChild("LeftMenu"):WaitForChild("RebirthButton")
	local dot = make("TextLabel", {Name = "ReadyDot", AnchorPoint = Vector2.new(0.5, 0.5), Position = S(0.86, 0.14), Size = S(0.3, 0.3),
		BackgroundColor3 = C(255, 70, 80), Text = "!", Font = FONT, TextScaled = true, TextColor3 = WHITE, Visible = false, ZIndex = 6}, menuButton)
	make("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
	make("UIStroke", {Thickness = 2, Color = WHITE}, dot)
	local banner = make("TextButton", {Name = "RebirthReadyBanner", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0), Position = S(0.5, 0.3),
		Size = S(0.46, 0.09), BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, ZIndex = 40}, gui)
	banner:SetAttribute("SnowUIDecor", true)
	make("UICorner", {CornerRadius = UDim.new(0.3, 0)}, banner)
	make("UIStroke", {Thickness = 3, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, banner)
	make("UIGradient", {Rotation = 90, Color = ColorSequence.new(C(190, 120, 255), PURPLE)}, banner)
	local bannerScale = make("UIScale", {Scale = 1}, banner)
	local bannerTitle = make("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "\u{1F504} REBIRTH READY!", TextColor3 = WHITE,
		Position = S(0.04, 0.06), Size = S(0.92, 0.5), ZIndex = 41}, banner)
	make("UIStroke", {Thickness = 2.5, Color = NAVY}, bannerTitle)
	local bannerSub = make("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "Tap here to start over stronger", TextColor3 = C(238, 228, 255),
		Position = S(0.04, 0.58), Size = S(0.92, 0.34), ZIndex = 41}, banner)
	make("UIStroke", {Thickness = 2, Color = NAVY}, bannerSub)

	local function blocked()
		if player:GetAttribute("IntroActive") or player:GetAttribute("IntroPlaying") then return true end
		local pg = player:FindFirstChild("PlayerGui")
		local rd = pg and pg:FindFirstChild("RareDropGui")
		if rd and rd.Enabled then return true end
		local upg = pg and pg:FindFirstChild("UpgradeTreeGui")
		return upg ~= nil and upg.Enabled
	end
	local function canRebirth()
		local raw = player:GetAttribute("Rebirths")
		local count = R.Count(raw)
		local req = R.Requirement(count)
		return raw ~= nil and req ~= nil and snow() >= req.Cost, count
	end
	local announced, token = nil, 0
	local function announce()
		token += 1
		local my = token
		task.spawn(function()
			local waited = 0
			while blocked() and waited < 120 do task.wait(0.5); waited += 0.5 end
			if token ~= my or panel.Visible or not canRebirth() then return end
			banner.Visible = true
			bannerScale.Scale = 0.4
			TweenService:Create(bannerScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			task.wait(7)
			if token ~= my then return end
			TweenService:Create(bannerScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play()
			task.wait(0.3)
			if token == my then banner.Visible = false end
		end)
	end
	local function check()
		local can, count = canRebirth()
		dot.Visible = can
		if can and announced ~= count then
			announced = count
			announce()
		end
	end
	banner.Activated:Connect(function()
		token += 1
		banner.Visible = false
		local openMenu = gui:FindFirstChild("VillageOpenMenu")
		if openMenu then openMenu:Fire("Rebirth") end
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then token += 1; banner.Visible = false end
	end)
	player:GetAttributeChangedSignal("Rebirths"):Connect(check)
	task.spawn(function() player:WaitForChild("leaderstats"):WaitForChild("Snow").Changed:Connect(check) end)
	task.spawn(function() -- the "!" pulses like the one on the Rewards button
		while true do
			if dot.Visible then
				TweenService:Create(dot, TweenInfo.new(0.45, Enum.EasingStyle.Sine), {Size = S(0.36, 0.36)}):Play()
				task.wait(0.45)
				TweenService:Create(dot, TweenInfo.new(0.45, Enum.EasingStyle.Sine), {Size = S(0.3, 0.3)}):Play()
				task.wait(0.45)
			else
				task.wait(0.5)
			end
		end
	end)
	check()
end
