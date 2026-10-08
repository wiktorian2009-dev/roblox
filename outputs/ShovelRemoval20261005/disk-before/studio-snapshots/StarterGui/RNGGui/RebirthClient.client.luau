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
local function box(parent, name, pos, size, color)
	return make("Frame", {Name = name, Position = pos, Size = size, BackgroundColor3 = color or WHITE, BorderSizePixel = 0}, parent)
end

-- HEADER: icon, next level, subtitle, done pill
local header = box(content, "Header", S(0, 0), S(1, 0.15)); header.BackgroundTransparency = 1
make("ImageLabel", {Name = "Badge", Image = ICON_REBIRTH, BackgroundTransparency = 1, Size = S(0.1, 1), ScaleType = Enum.ScaleType.Fit}, header)
local countLabel = text(header, "Count", "NEXT: REBIRTH 1", {Position = S(0.11, -0.02), Size = S(0.6, 0.62),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PURPLE}, 34)
local subtitle = text(header, "Subtitle", "", {Position = S(0.11, 0.6), Size = S(0.62, 0.4),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C(70, 80, 120)}, 18)
local donePill = box(header, "DonePill", S(0.74, 0.14), S(0.26, 0.72), PURPLE)
corner(donePill, UDim.new(1, 0)); outline(donePill, 2.5, NAVY, true); gradient(donePill, C(185, 120, 255), PURPLE)
local doneLabel = text(donePill, "Done", "0 / 50 DONE", {Position = S(0.08, 0.14), Size = S(0.84, 0.72), TextColor3 = WHITE}, 22, 1.5)

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
local track = box(content, "Progress", S(0.39, 0.49), S(0.61, 0.14), C(205, 220, 240))
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
pill("Keep", 0, "✓ KEEP: shovels • pets • index", GREEN_BG, GREEN_TXT)
pill("Reset", 0.51, "RESET: snow • stages • upgrades", RED_BG, RED_TXT)

-- BUTTONS
local buy = make("TextButton", {Name = "RebirthButton", Text = "", AutoButtonColor = false, Position = S(0.12, 0.81), Size = S(0.76, 0.19),
	BackgroundColor3 = WHITE, BorderSizePixel = 0}, content)
corner(buy, UDim.new(0.35, 0)); outline(buy, 3, NAVY, true)
local buyGrad = gradient(buy, C(190, 120, 255), PURPLE)
local buyScale = make("UIScale", {Scale = 1}, buy)
local buyText = text(buy, "Label", "REBIRTH!", {Position = S(0.05, 0.1), Size = S(0.9, 0.8), TextColor3 = WHITE}, 34, 2.5)
local cancel = make("TextButton", {Name = "CancelRebirth", Text = "", AutoButtonColor = true, Position = S(0, 0.81), Size = S(0.3, 0.19),
	BackgroundColor3 = C(150, 160, 185), BorderSizePixel = 0, Visible = false}, content)
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
	local stageOk = req ~= nil and player:GetAttribute("Stage_" .. req.Stage) == true
	local have = snow()
	ready = raw ~= nil and req ~= nil and stageOk and have >= req.Cost
	if req then
		local st = Stages.ById[req.Stage]
		local sname = st and st.Name or req.Stage
		requirement.Text = stageOk and ("✓ " .. sname) or ("🔒 Unlock " .. sname)
		requirement.TextColor3 = stageOk and GREEN_TXT or C(160, 95, 10)
		reqChip.BackgroundColor3 = stageOk and GREEN_BG or C(255, 244, 214)
		reqStroke.Color = stageOk and GREEN_LINE or C(230, 160, 40)
		price.Text = "Snow " .. Format.Abbreviate(have) .. " / " .. Format.Abbreviate(req.Cost)
		local k = math.clamp(have / req.Cost, 0, 1)
		fill.Size = S(k, 1)
		fill.Visible = k > 0.002
		fillGrad.Color = k >= 1 and ColorSequence.new(C(150, 240, 170), C(50, 185, 95)) or ColorSequence.new(C(140, 225, 255), C(60, 160, 240))
	else
		requirement.Text = "✓ All milestones done!"
		requirement.TextColor3 = GREEN_TXT
		reqChip.BackgroundColor3 = GREEN_BG
		reqStroke.Color = GREEN_LINE
		price.Text = "Enjoy your permanent bonuses!"
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
		or confirming and "Extra equip slots reset too. Your items stay in your inventory."
		or ready and "You're ready! Start over stronger - bonuses are permanent."
		or "Start over stronger - your bonuses are permanent!"
	subtitle.TextColor3 = feedback ~= "" and (feedbackGood and GREEN_TXT or RED_TXT) or confirming and RED_TXT or C(70, 80, 120)
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
	if not req or player:GetAttribute("Stage_" .. req.Stage) ~= true or snow() < req.Cost then shake() return end
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
for _, s in ipairs(Stages.Order) do player:GetAttributeChangedSignal("Stage_" .. s.Id):Connect(function() if panel.Visible then refresh() end end) end
task.spawn(function() player:WaitForChild("leaderstats"):WaitForChild("Snow").Changed:Connect(function() if panel.Visible then refresh() end end) end)
gui:SetAttribute("RebirthMenuOpen", panel.Visible)
refresh()
