-- CommunityRewardClient (2026-10-13, Claude): the FREE PET pill under the REWARDS / SPIN buttons and the small SUPPORTER GIFT card.
-- * Card: the prize (Frosty Pal + Snow + 2x Snow), step 1 "like the game" (a reminder only - Roblox can't tell a game who liked
--   it, so it never gates anything), step 2 JOIN (GroupService:PromptJoinAsync, then the server re-checks), CLAIM.
-- * The server decides everything (CommunityRewardService); this script only shows state and asks. After a claim the usual
--   hatch reveal plays (PetClient) and the pill goes away for good (attribute CommunityGiftClaimed).
-- * Hidden until the plow tutorial is done, so new players are not distracted during it.
-- * v2 (2026-10-13, wiktor: "polish the ui"): dimmed backdrop + pop-in, glowing pet stage with a turning sunburst and a gold
--   "+100% SNOW" badge, prize chips with one text size, numbered steps that tick green, pulsing CLAIM, two-line pill with a wiggle.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GroupService = game:GetService("GroupService")
local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local CFG = require(RS:WaitForChild("CommunityRewardConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local PetModels = require(RS:WaitForChild("PetModels"))
local A = require(RS:WaitForChild("ActivityConfig"))
local Art = require(RS:WaitForChild("SnowArt"))
local remote = RS:WaitForChild("CommunityRewardRemote", 60)
if not remote then return end
local pg = player:WaitForChild("PlayerGui")
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local GOLD, ICE, GREEN, GREY, BLUE, PURPLE = Color3.fromRGB(255, 220, 90), Color3.fromRGB(190, 225, 255), Color3.fromRGB(70, 200, 105),
	Color3.fromRGB(130, 140, 165), Color3.fromRGB(70, 150, 245), Color3.fromRGB(160, 110, 255)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local PET = PetConfig.PetByName[CFG.Pet]
if not PET then return end
local RARITY = PetConfig.Rarities and PetConfig.Rarities[PET.Rarity] or GOLD
local function boostText() return "+" .. math.floor(PetConfig.BoostOf(PET, player) * 100 + 0.5) .. "% SNOW" end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
-- TextScaled text with a size cap, so lines of one kind keep one size instead of each filling its own box
local function label(parent, text, props, maxSize)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE, ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	mk("UIStroke", {Thickness = 2, Color = NAVY}, l)
	if maxSize then mk("UITextSizeConstraint", {MaxTextSize = maxSize, MinTextSize = 9}, l) end
	return l
end
local function button(parent, text, color, props, maxSize)
	local b = mk("TextButton", {Text = "", AutoButtonColor = true, BackgroundColor3 = color, Selectable = true, ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, b)
	local l = label(b, text, {Name = "Label", Size = UDim2.fromScale(0.86, 0.62), Position = UDim2.fromScale(0.07, 0.17), ZIndex = 6}, maxSize)
	Art.SkinButton(b)
	return b, l
end
local function round(o, r) return mk("UICorner", {CornerRadius = UDim.new(r or 0.25, 0)}, o) end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local spinners = {}
local function petView(parent, props, dist)
	local vp = mk("ViewportFrame", {BackgroundTransparency = 1, Ambient = Color3.fromRGB(205, 205, 220), LightColor = WHITE, LightDirection = Vector3.new(-0.4, -1, -0.6), ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do vp[k] = v end
	local model = PetModels.create(PET.Name)
	model:PivotTo(CFrame.new())
	model.Parent = vp
	local _, size = model:GetBoundingBox()
	local cam = mk("Camera", {FieldOfView = 34}, vp)
	cam.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * 0.18, -math.max(size.X, size.Y, size.Z) * (dist or 1.6)), Vector3.new())
	vp.CurrentCamera = cam
	table.insert(spinners, {vp = vp, model = model, base = model:GetPivot(), t = math.random() * 6})
	return vp
end
-- soft glow disc behind a pet (no image asset: a round frame with a fading gradient)
local function glow(parent, color, props)
	local g = mk("Frame", {BackgroundColor3 = color, BackgroundTransparency = 0.35, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4}, parent)
	for k, v in pairs(props or {}) do g[k] = v end
	round(g, 1)
	mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1)}), Rotation = 90}, g)
	return g
end
-- slowly turning sunburst made of thin rays (cheap, no asset)
local function sunburst(parent, color, props)
	local holder = mk("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3}, parent)
	for k, v in pairs(props or {}) do holder[k] = v end
	for i = 0, 5 do
		local ray = mk("Frame", {BackgroundColor3 = color, BackgroundTransparency = 0.72, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.12, 1), Rotation = i * 30, ZIndex = 3}, holder)
		mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)}), Rotation = 90}, ray)
	end
	return holder
end

--------------------------------------------------
-- pill (below the REWARDS / SPIN buttons on the right)
--------------------------------------------------
local hud = mk("ScreenGui", {Name = "CommunityGiftHud", ResetOnSpawn = false, DisplayOrder = 99, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, pg)
local pill = button(hud, CFG.PillText, PURPLE, {Name = "GiftPill", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(170, 52)})
pill.Label.Position, pill.Label.Size = UDim2.fromScale(0.36, 0.1), UDim2.fromScale(0.58, 0.5)
local pillSub = label(pill, boostText() .. " PET", {Name = "Sub", Position = UDim2.fromScale(0.36, 0.56), Size = UDim2.fromScale(0.58, 0.3), TextColor3 = GOLD, ZIndex = 6})
local pillGlow = glow(pill, Color3.fromRGB(255, 240, 170), {Position = UDim2.fromScale(0.17, 0.42), Size = UDim2.fromScale(1.15, 1.15), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 6})
petView(pill, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.17, 0.36), Size = UDim2.fromScale(1.35, 1.35), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 7}, 1.45)
local dot = label(pill, "!", {Name = "Dot", BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(240, 60, 90), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.97, 0.1), Size = UDim2.fromScale(0.42, 0.42), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 8})
round(dot, 1)
mk("UIStroke", {Thickness = 2, Color = WHITE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, dot)
local pillScale = mk("UIScale", {}, pill)
-- a short wiggle + bounce every few seconds (calmer than a constant pulse)
task.spawn(function()
	while pill.Parent do
		task.wait(4)
		if hud.Enabled then
			tween(pillScale, 0.12, {Scale = 1.08})
			for _, r in ipairs({-6, 5, -3, 0}) do tween(pill, 0.09, {Rotation = r}); task.wait(0.09) end
			tween(pillScale, 0.2, {Scale = 1}, Enum.EasingStyle.Back)
		end
	end
end)

local function placePill()
	local rnggui = pg:FindFirstChild("RNGGui")
	local rm = rnggui and rnggui:FindFirstChild("RightMenu")
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local h = math.clamp(math.floor(vp.Y * 0.055), 46, 62)
	pill.Size = UDim2.fromOffset(math.floor(h * 3.2), h)
	if rm and rm.AbsoluteSize.Y > 0 then
		-- AbsolutePosition is measured below the top bar; this ScreenGui ignores the inset, so add it back
		local inset = GuiService:GetGuiInset().Y
		-- under the lowest thing in the right menu (the SPIN button's label hangs below its cell)
		local bottom = rm.AbsolutePosition.Y + rm.AbsoluteSize.Y
		for _, d in ipairs(rm:GetDescendants()) do
			if d:IsA("GuiObject") and d.Visible and d.AbsoluteSize.Y > 0 then bottom = math.max(bottom, d.AbsolutePosition.Y + d.AbsoluteSize.Y) end
		end
		pill.Position = UDim2.fromOffset(rm.AbsolutePosition.X + rm.AbsoluteSize.X, bottom + inset + math.floor(h * 0.45))
	else
		pill.Position = UDim2.new(0.988, 0, 0.66, 0)
	end
end

--------------------------------------------------
-- card
--------------------------------------------------
local sg = mk("ScreenGui", {Name = "CommunityGiftGui", ResetOnSpawn = false, DisplayOrder = 103, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, pg)
local backdrop = mk("TextButton", {Name = "Backdrop", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1), Selectable = false, ZIndex = 1}, sg)
local card = mk("Frame", {Name = "GiftCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.46, 0.62),
	BackgroundColor3 = Color3.fromRGB(40, 80, 160), Active = true, ZIndex = 2}, sg)
round(card, 0.05)
mk("UISizeConstraint", {MinSize = Vector2.new(340, 330), MaxSize = Vector2.new(760, 580)}, card)
Art.SkinPanel(card, "dark")
local cardScale = mk("UIScale", {}, card)
label(card, CFG.Title, {Name = "Title", Position = UDim2.fromScale(0.05, 0.045), Size = UDim2.fromScale(0.74, 0.085), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD}, 44)
label(card, "Join our group and get an exclusive pet - free!", {Name = "Subtitle", Position = UDim2.fromScale(0.05, 0.13), Size = UDim2.fromScale(0.74, 0.045),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE}, 22)
local close = mk("TextButton", {Name = "Close", Text = "X", BackgroundColor3 = Color3.fromRGB(235, 80, 90), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.97, 0.03),
	Size = UDim2.fromScale(0.1, 0.11), SizeConstraint = Enum.SizeConstraint.RelativeYY, Selectable = true, ZIndex = 6}, card)
Art.SkinClose(close)
mk("UISizeConstraint", {MinSize = touch and Vector2.new(44, 44) or Vector2.zero}, close)

-- prize: the pet on a glowing stage (left), the prize chips (right)
local stage = mk("Frame", {Name = "PetStage", BackgroundColor3 = RARITY:Lerp(NAVY, 0.35), Position = UDim2.fromScale(0.05, 0.2), Size = UDim2.fromScale(0.33, 0.43), ClipsDescendants = true, ZIndex = 3}, card)
round(stage, 0.1)
mk("UIStroke", {Thickness = 3, Color = RARITY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, stage)
mk("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 170)), Rotation = 90}, stage)
local rays = sunburst(stage, Color3.fromRGB(255, 245, 200), {Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(1.5, 1.5), SizeConstraint = Enum.SizeConstraint.RelativeXX})
glow(stage, Color3.fromRGB(255, 250, 220), {Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.85, 0.85), SizeConstraint = Enum.SizeConstraint.RelativeXX})
petView(stage, {Position = UDim2.fromScale(0.09, 0.0), Size = UDim2.fromScale(0.82, 0.66)}, 1.7)
label(stage, PET.Name, {Position = UDim2.fromScale(0.05, 0.63), Size = UDim2.fromScale(0.9, 0.13), TextColor3 = WHITE}, 30)
local badge = mk("Frame", {Name = "Badge", BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromScale(0.8, 0.15), ZIndex = 5}, stage)
round(badge, 0.5)
mk("UIStroke", {Thickness = 2, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, badge)
local badgeText = label(badge, "\u{2744} " .. boostText(), {Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76), TextColor3 = WHITE, ZIndex = 6}, 26)
local tag = label(card, "EXCLUSIVE", {Name = "Tag", BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(240, 60, 90), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.33, 0.215), Size = UDim2.fromScale(0.15, 0.045), Rotation = 12, ZIndex = 7}, 18)
round(tag, 0.4)

local boost = A.Boosts[CFG.Boost]
local chipBoost
local chips = {
	{"\u{1F43E}", PET.Name .. " pet", ""},
	{"\u{2744}\u{FE0F}", "Snow bonus", "a big pile of Snow right away"},
	boost and {"\u{26A1}", boost.Name .. " boost", math.floor(CFG.BoostSeconds / 60) .. " minutes"} or nil,
}
for i, c in ipairs(chips) do
	local chip = mk("Frame", {Name = "Chip" .. i, BackgroundColor3 = NAVY, BackgroundTransparency = 0.3, Position = UDim2.fromScale(0.41, 0.2 + (i - 1) * 0.147),
		Size = UDim2.fromScale(0.54, 0.127), ZIndex = 3}, card)
	round(chip, 0.3)
	mk("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(110, 150, 220), Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, chip)
	local icon = label(chip, c[1], {Position = UDim2.fromScale(0.02, 0.12), Size = UDim2.fromScale(0.16, 0.76)}, 34)
	icon:FindFirstChildOfClass("UIStroke").Enabled = false
	label(chip, c[2], {Position = UDim2.fromScale(0.19, 0.08), Size = UDim2.fromScale(0.78, 0.5), TextXAlignment = Enum.TextXAlignment.Left}, 26)
	local sub = label(chip, c[3], {Position = UDim2.fromScale(0.19, 0.56), Size = UDim2.fromScale(0.78, 0.34), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE}, 18)
	if i == 1 then chipBoost = sub end
end
local function showBoost()
	local t = boostText()
	badgeText.Text, pillSub.Text = "\u{2744} " .. t, t .. " PET"
	chipBoost.Text = t:lower() .. ", only from this gift"
end
showBoost()

-- steps
local function stepRow(y, num, title, sub, wide)
	local row = mk("Frame", {Name = "Step" .. num, BackgroundColor3 = NAVY, BackgroundTransparency = 0.3, Position = UDim2.fromScale(0.05, y), Size = UDim2.fromScale(0.9, 0.105), ZIndex = 3}, card)
	round(row, 0.35)
	local circle = mk("Frame", {Name = "Num", BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.015, 0.5), Size = UDim2.fromScale(0.78, 0.78),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 4}, row)
	round(circle, 1)
	mk("UIStroke", {Thickness = 2, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, circle)
	local n = label(circle, num, {Name = "Text", Position = UDim2.fromScale(0.15, 0.12), Size = UDim2.fromScale(0.7, 0.76)}, 30)
	label(row, title, {Position = UDim2.fromScale(0.1, 0.07), Size = UDim2.fromScale(wide and 0.86 or 0.6, 0.5), TextXAlignment = Enum.TextXAlignment.Left}, 26)
	label(row, sub, {Position = UDim2.fromScale(0.1, 0.56), Size = UDim2.fromScale(wide and 0.86 or 0.6, 0.36), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE}, 18)
	return row, circle, n
end
stepRow(0.665, "1", "Like the game \u{1F44D}", CFG.LikeText, true)
local joinRow, joinCircle, joinNum = stepRow(0.785, "2", CFG.JoinText, "Get group news, updates and this gift")
local joinBtn = button(joinRow, "JOIN", BLUE, {Name = "Join", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.985, 0.5), Size = UDim2.fromScale(0.26, 0.78)}, 28)
local claimBtn, claimLabel = button(card, "CLAIM", GREY, {Name = "Claim", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromScale(0.4, 0.1)}, 34)
mk("UISizeConstraint", {MinSize = touch and Vector2.new(0, 44) or Vector2.zero}, claimBtn)
local claimScale = mk("UIScale", {}, claimBtn)
local msg = label(card, "", {Name = "Message", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.632), Size = UDim2.fromScale(0.9, 0.0), TextColor3 = GOLD}, 22)

--------------------------------------------------
-- state
--------------------------------------------------
local member, claimed, busy = false, player:GetAttribute("CommunityGiftClaimed") == true, false
local function setMsg(t, col)
	msg.Text, msg.TextColor3 = t or "", col or GOLD
	msg.Size = UDim2.fromScale(0.9, (t and t ~= "") and 0.032 or 0)
end
local function render()
	joinBtn.Label.Text = member and "JOINED" or "JOIN"
	joinBtn.BackgroundColor3 = member and GREEN or BLUE
	joinCircle.BackgroundColor3 = member and GREEN or GOLD
	joinNum.Text = member and "\u{2713}" or "2"
	claimBtn.BackgroundColor3 = member and GREEN or GREY
	claimLabel.Text = member and "CLAIM GIFT!" or "JOIN FIRST"
end
local function apply(res)
	if type(res) ~= "table" or not res.ok then return end
	member = res.member == true
	if res.claimed then claimed = true end
	render()
end
local function refreshHud()
	local show = not claimed and RS:GetAttribute("CommunityGroupId") ~= nil and player:GetAttribute("PlowTutorialDone") == true
		and player:GetAttribute("IntroActive") ~= true
	hud.Enabled = show
	if show then placePill() end
	if claimed then sg.Enabled = false end
end

local function open()
	if sg.Enabled then return end
	sg.Enabled = true
	setMsg("")
	render()
	backdrop.BackgroundTransparency = 1
	cardScale.Scale = 0.82
	tween(backdrop, 0.2, {BackgroundTransparency = 0.45})
	tween(cardScale, 0.32, {Scale = 1}, Enum.EasingStyle.Back)
	task.spawn(function() apply(remote:InvokeServer("Check")) end)
end
local function shut()
	if not sg.Enabled then return end
	tween(backdrop, 0.15, {BackgroundTransparency = 1})
	tween(cardScale, 0.15, {Scale = 0.85}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.15, function() sg.Enabled = false end)
end
pill.Activated:Connect(function() if sg.Enabled then shut() else open() end end)
close.Activated:Connect(shut)
backdrop.Activated:Connect(shut)

joinBtn.Activated:Connect(function()
	if busy or member then return end
	busy = true
	local gid = RS:GetAttribute("CommunityGroupId")
	local ok = gid and pcall(function() GroupService:PromptJoinAsync(gid) end)
	if not ok then setMsg("Open the game page and tap the group name to join!", ICE) end
	task.wait(0.5)
	apply(remote:InvokeServer("Check"))
	if member then setMsg("Thanks for joining! Tap CLAIM GIFT \u{1F381}", GREEN) end
	busy = false
end)
claimBtn.Activated:Connect(function()
	if busy then return end
	busy = true
	if not member then apply(remote:InvokeServer("Check")) end
	if not member then
		setMsg("Join the group first, then tap CLAIM!", GOLD)
		for _, x in ipairs({-0.02, 0.02, -0.01, 0}) do tween(joinRow, 0.06, {Position = UDim2.fromScale(0.05 + x, 0.785)}); task.wait(0.06) end
	else
		claimLabel.Text = "..."
		local res = remote:InvokeServer("Claim")
		if type(res) == "table" and res.ok then
			claimed = true
			shut()
			refreshHud()
		else
			setMsg(type(res) == "table" and res.msg or "Try again in a moment.", GOLD)
			if type(res) == "table" and res.claimed then claimed = true; refreshHud() end
			render()
		end
	end
	busy = false
end)

player:GetAttributeChangedSignal("CommunityGiftClaimed"):Connect(function()
	if player:GetAttribute("CommunityGiftClaimed") == true then claimed = true end
	refreshHud()
end)
player:GetAttributeChangedSignal("PlowTutorialDone"):Connect(refreshHud)
player:GetAttributeChangedSignal("IntroActive"):Connect(refreshHud)
player.AttributeChanged:Connect(function(a) if a:sub(1, 6) == "Stage_" then showBoost() end end) -- in case the pet is ever progress-scaled again
RS:GetAttributeChangedSignal("CommunityGroupId"):Connect(refreshHud)
task.spawn(function()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() if hud.Enabled then placePill() end end) end
	local rnggui = pg:WaitForChild("RNGGui", 30)
	local rm = rnggui and rnggui:WaitForChild("RightMenu", 30)
	if rm then
		rm:GetPropertyChangedSignal("AbsolutePosition"):Connect(function() if hud.Enabled then placePill() end end)
		rm:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if hud.Enabled then placePill() end end)
	end
	refreshHud()
	task.wait(2); refreshHud() -- the right menu settles its layout after the first frames
end)
task.spawn(function() apply(remote:InvokeServer("State")); refreshHud() end)

-- pets turn slowly and bob; the pill glow breathes; the sunburst turns; CLAIM breathes when it can be claimed
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for _, s in ipairs(spinners) do
		local gui = s.vp:FindFirstAncestorOfClass("ScreenGui")
		if gui and gui.Enabled then
			s.t += dt
			s.model:PivotTo(s.base * CFrame.new(0, math.sin(s.t * 2.2) * 0.12, 0) * CFrame.Angles(0, s.t * 0.9, 0))
		end
	end
	if hud.Enabled then pillGlow.BackgroundTransparency = 0.45 + math.sin(t * 2.4) * 0.15 end
	if sg.Enabled then
		rays.Rotation = (t * 12) % 360
		claimScale.Scale = member and (1 + math.sin(t * 4) * 0.035) or 1
	end
end)
