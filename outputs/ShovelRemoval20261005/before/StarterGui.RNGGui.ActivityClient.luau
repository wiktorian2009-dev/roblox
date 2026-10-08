-- ActivityClient (2026-10-02, Claude): the Rewards panel (Daily / Quests / Achievements / Codes), the event banner,
-- active boost timers, toasts and event weather. Server side: ServerScriptService.ActivityService + BoostService.
-- Panel shell = RNGGui.Panels.Rewards, opened by LeftMenu.Rewards through RNGClient's normal panel logic.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local gui = script.Parent
local A = require(RS:WaitForChild("ActivityConfig"))
local SnowUI = require(RS:WaitForChild("SnowUI"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local fn = RS:WaitForChild("ActivityRemote")
local push = RS:WaitForChild("ActivityPush")
local panel = gui:WaitForChild("Panels"):WaitForChild("Rewards")
local button = (gui:FindFirstChild("RightMenu") or gui:WaitForChild("LeftMenu")):WaitForChild("Rewards") -- 2026-10-03: moved to the right side
local inner = panel:WaitForChild("Inner")
local content = inner:WaitForChild("Content")

local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(28, 42, 66)
local TEXT_DARK = Color3.fromRGB(45, 65, 100)
local CARD = Color3.fromRGB(238, 247, 255)
local GREEN = Color3.fromRGB(70, 205, 100)
local GOLD = Color3.fromRGB(255, 200, 60)
local GREY = Color3.fromRGB(150, 160, 178)
local BLUE = Color3.fromRGB(80, 160, 255)
local RED = Color3.fromRGB(255, 110, 110)

--------------------------------------------------
-- small UI helpers
--------------------------------------------------
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function round(o, r) return mk("UICorner", {CornerRadius = UDim.new(r or 0.2, 0)}, o) end
local function outline(o, th, color, mode)
	return mk("UIStroke", {Thickness = th or 2, Color = color or DARK, ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border}, o)
end
local function text(parent, str, props, max, dark)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, Text = str, TextColor3 = dark and TEXT_DARK or WHITE,
		TextScaled = true, TextWrapped = true, Size = UDim2.fromScale(1, 1)}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	if not dark then outline(l, 2, DARK, Enum.ApplyStrokeMode.Contextual) end
	mk("UITextSizeConstraint", {MaxTextSize = max or 32}, l)
	return l
end
local function tween(o, t, goal, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function clock(s)
	s = math.max(0, math.floor(s))
	local h, m = math.floor(s / 3600), math.floor(s % 3600 / 60)
	if h > 0 then return string.format("%dh %02dm", h, m) end
	return string.format("%d:%02d", m, s % 60)
end
local LEFT = Enum.TextXAlignment.Left
-- 2026-10-03 (Claude, redo): tabs, ribbons, buttons and cards in this panel skip SnowUI's automatic frost overlay. Its ~13 px rim
-- swallowed most of a 45 px tab and its corners never matched the outlines, which looked blurry and double-bordered.
local function nodecor(o) o:SetAttribute("SnowUIDecor", true); return o end

--------------------------------------------------
-- TOASTS (queued)
--------------------------------------------------
local toast = mk("TextLabel", {Name = "ActivityToast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromScale(0.55, 0.055), BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "",
	TextColor3 = GOLD, TextTransparency = 1, ZIndex = 40}, gui)
local toastStroke = outline(toast, 3, DARK, Enum.ApplyStrokeMode.Contextual)
toastStroke.Transparency = 1
local queue, showing = {}, false
local function showToast(msg, color)
	if #queue >= 4 then return end
	table.insert(queue, {msg, color or GOLD})
	if showing then return end
	showing = true
	task.spawn(function()
		while #queue > 0 do
			local m = table.remove(queue, 1)
			toast.Text, toast.TextColor3 = m[1], m[2]
			tween(toast, 0.2, {TextTransparency = 0})
			tween(toastStroke, 0.2, {Transparency = 0})
			task.wait(2.6)
			tween(toast, 0.35, {TextTransparency = 1})
			tween(toastStroke, 0.35, {Transparency = 1})
			task.wait(0.4)
		end
		showing = false
	end)
end

--------------------------------------------------
-- RED DOT on the Rewards button (something to claim)
--------------------------------------------------
local dot = mk("TextLabel", {Name = "ClaimDot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.14),
	Size = UDim2.fromScale(0.3, 0.3), BackgroundColor3 = Color3.fromRGB(255, 70, 80), Text = "!", Font = FONT, TextScaled = true,
	TextColor3 = WHITE, Visible = false, ZIndex = 5}, button)
round(dot, 1)
outline(dot, 2, WHITE)
local function updateDot() dot.Visible = player:GetAttribute("ActivityClaimable") == true end
player:GetAttributeChangedSignal("ActivityClaimable"):Connect(updateDot)
updateDot()
task.spawn(function()
	while true do
		if dot.Visible then
			tween(dot, 0.45, {Size = UDim2.fromScale(0.36, 0.36)}, Enum.EasingStyle.Sine)
			task.wait(0.45)
			tween(dot, 0.45, {Size = UDim2.fromScale(0.3, 0.3)}, Enum.EasingStyle.Sine)
			task.wait(0.45)
		else
			task.wait(0.5)
		end
	end
end)

--------------------------------------------------
-- HUD: event banner + active boosts (right side)
--------------------------------------------------
local hud = mk("Frame", {Name = "ActivityHUD", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0.14, 0), Size = UDim2.fromScale(0.25, 0.3)}, gui)
mk("UIListLayout", {Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}, hud)
-- 2026-10-04 (Claude): the banner and the boost chips skip SnowUI's frost overlay (it washed their colours out and its rim ate the
-- small chips) and use a deeper, richer version of their colour, so white text with a navy outline reads clearly.
local function deep(c, k) -- same hue, stronger and darker (k about 0.92 at the top, 0.68 at the bottom)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, math.clamp(s * 0.9 + 0.22, 0, 1), v * k)
end
local function gloss(parent) -- soft highlight strip along the top, like the other chunky buttons
	local g = nodecor(mk("Frame", {Name = "Gloss", BackgroundColor3 = WHITE, BackgroundTransparency = 0.78, BorderSizePixel = 0,
		Position = UDim2.fromScale(0.04, 0.07), Size = UDim2.fromScale(0.92, 0.2)}, parent))
	round(g, 1)
	return g
end
local banner = nodecor(mk("Frame", {Name = "EventBanner", Size = UDim2.fromScale(1, 0.3), BackgroundColor3 = WHITE, Visible = false, LayoutOrder = 1}, hud))
round(banner, 0.25)
outline(banner, 3.5, DARK)
local bannerGrad = mk("UIGradient", {Rotation = 90}, banner)
gloss(banner)
local bannerTitle = text(banner, "", {Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.66, 0.5), TextXAlignment = LEFT}, 34)
local bannerText = text(banner, "", {Position = UDim2.fromScale(0.05, 0.56), Size = UDim2.fromScale(0.66, 0.36), TextXAlignment = LEFT, TextColor3 = Color3.fromRGB(255, 246, 214)}, 24)
local bannerTime = text(banner, "", {Position = UDim2.fromScale(0.72, 0.18), Size = UDim2.fromScale(0.25, 0.64)}, 34)
for _, l in ipairs({bannerTitle, bannerText, bannerTime}) do
	local s = l:FindFirstChildOfClass("UIStroke")
	if s then s.Thickness = 2.6 end
end
local pills = {}
for i, kind in ipairs(A.BoostOrder) do
	local k = A.Boosts[kind]
	local p = nodecor(mk("Frame", {Name = "Boost_" .. kind, Size = UDim2.fromScale(0.8, 0.13), BackgroundColor3 = WHITE, Visible = false, LayoutOrder = 10 + i}, hud))
	round(p, 0.5)
	outline(p, 2.5, DARK)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(deep(k.Color, 0.92), deep(k.Color, 0.68))}, p)
	gloss(p)
	pills[kind] = {frame = p, label = text(p, "", {Position = UDim2.fromScale(0.05, 0.08), Size = UDim2.fromScale(0.9, 0.84)}, 26)}
	local s = pills[kind].label:FindFirstChildOfClass("UIStroke")
	if s then s.Thickness = 2.4 end
end

-- event weather that follows the camera (local only)
local weather
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local function setWeather(effect)
	if weather then weather:Destroy(); weather = nil end
	if not effect then return end
	weather = mk("Part", {Name = "EventWeather", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		CastShadow = false, Transparency = 1, Size = Vector3.new(80, 1, 80)}, workspace.CurrentCamera)
	if effect == "Snow" or effect == "Both" then
		mk("ParticleEmitter", {Name = "Snow", Texture = SPARKLE, Color = ColorSequence.new(WHITE), Size = NumberSequence.new(0.4),
			Lifetime = NumberRange.new(4, 6), Rate = 70, Speed = NumberRange.new(9, 13), EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(12, 12), LightEmission = 0.2, Transparency = NumberSequence.new(0.15)}, weather)
	end
	if effect == "Sparkle" or effect == "Both" then
		mk("ParticleEmitter", {Name = "Luck", Texture = SPARKLE, Color = ColorSequence.new(Color3.fromRGB(120, 255, 140), Color3.fromRGB(255, 225, 90)),
			Size = NumberSequence.new(0.6), Lifetime = NumberRange.new(3, 5), Rate = 25, Speed = NumberRange.new(3, 6),
			EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(50, 50), LightEmission = 0.8,
			RotSpeed = NumberRange.new(-90, 90)}, weather)
	end
end
RunService.RenderStepped:Connect(function()
	if weather then weather.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 28, 0)) end
end)

local function updateEvent(announce)
	local id = RS:GetAttribute("EventId")
	local e = id and A.EventById[id]
	if e then
		banner.Visible = true
		bannerTitle.Text = e.Icon .. " " .. e.Name
		bannerText.Text = e.Text
		bannerGrad.Color = ColorSequence.new(deep(e.Color, 0.92), deep(e.Color, 0.68))
		setWeather(e.Effect)
		if announce then showToast(e.Icon .. " " .. e.Name .. "!  " .. e.Text, e.Color:Lerp(WHITE, 0.3)) end
	else
		banner.Visible = false
		setWeather(nil)
	end
end
RS:GetAttributeChangedSignal("EventId"):Connect(function() updateEvent(true) end)
updateEvent(false)

--------------------------------------------------
-- PANEL
--------------------------------------------------
local state, render
local live = {} -- countdown updaters for the current page

local function call(action, arg)
	local ok, res = pcall(function() return fn:InvokeServer(action, arg) end)
	return ok and res or nil
end
local function setState(s)
	if type(s) == "table" then state = s; state.fetchedAt = os.clock() end
end
local function fetch() setState(call("Get")) end
local function serverNow() return state and (state.Now + (os.clock() - state.fetchedAt)) or os.time() end

-- tabs on top, scrolling list below (inside the cloned panel's Inner)
-- 2026-10-03 (Claude, alignment pass): the tab row and the page cards share the same left/right edges (EDGE px inside the column)
local EDGE = 8
local tabBar = mk("Frame", {Name = "RewardTabs", BackgroundTransparency = 1, Position = UDim2.new(0.03, EDGE, 0.018, 0), Size = UDim2.new(0.94, -2 * EDGE, 0.108, 0)}, inner)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.015, 0), VerticalAlignment = Enum.VerticalAlignment.Center,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)
content.AnchorPoint = Vector2.zero
content.Position = UDim2.fromScale(0.03, 0.14)
content.Size = UDim2.fromScale(0.94, 0.83)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.ScrollingDirection = Enum.ScrollingDirection.Y
mk("UIListLayout", {Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, content)
mk("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, EDGE), PaddingRight = UDim.new(0, EDGE)}, content) -- symmetric; the 7 px scrollbar fits inside the right padding

local TABS = {
	{Id = "Daily", Text = "🎁 DAILY", Color = Color3.fromRGB(255, 150, 80)},
	{Id = "Quests", Text = "📜 QUESTS", Color = Color3.fromRGB(80, 170, 255)},
	{Id = "Achievements", Text = "🏆 ACHIEVEMENTS", Color = Color3.fromRGB(240, 180, 40)},
	{Id = "Codes", Text = "🔑 CODES", Color = Color3.fromRGB(170, 110, 255)},
}
-- 2026-10-03 (Claude, alignment pass): widths are shares of the tab row (they add up to 1 with the three 0.015 gaps), so the row
-- ends exactly at the card edges and "ACHIEVEMENTS" has room to use the same text size as the other tabs.
local TAB_WIDTH = {Daily = 0.2, Quests = 0.215, Achievements = 0.335, Codes = 0.205}
local current = "Daily"
local tabButtons, tabColors = {}, {}
for i, t in ipairs(TABS) do
	local b = nodecor(mk("TextButton", {Name = t.Id, LayoutOrder = i, Size = UDim2.fromScale(TAB_WIDTH[t.Id] or 0.235, 1), BackgroundColor3 = t.Color, Text = "", AutoButtonColor = true}, tabBar))
	round(b, 0.3)
	outline(b, 2.5, DARK)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 215, 235))}, b) -- soft top-lit look
	mk("UIScale", {Scale = 1}, b)
	local icons = {Daily = SnowUI.Assets.rewards, Quests = SnowUI.Assets.quests, Achievements = SnowUI.Assets.achievement, Codes = SnowUI.Assets.codes}
	local ic = SnowUI.Icon(b, icons[t.Id], UDim2.fromScale(0.04, 0.5), UDim2.fromScale(0.2, 0.76), "CategoryIcon")
	ic.AnchorPoint = Vector2.new(0, 0.5)
	local lbl = text(b, string.upper(t.Id), {Position = UDim2.fromScale(0.27, 0.14), Size = UDim2.fromScale(0.68, 0.72)}, 24)
	-- icon inset from the left edge and vertically centred, label fills the rest. Uses the tab's width/height ratio (UIScale
	-- does not change it), so the same look works for every tab width and screen size.
	local function layoutTab()
		local s = b.AbsoluteSize
		if s.X <= 0 or s.Y <= 0 then return end
		local a = s.X / s.Y
		local inset, iconH = 0.12, 0.76
		ic.Position = UDim2.fromScale(inset / a, 0.5)
		ic.Size = UDim2.fromScale(iconH / a, iconH)
		local x = (inset + iconH + 0.06) / a
		lbl.Position = UDim2.fromScale(x, 0.14)
		lbl.Size = UDim2.fromScale(1 - x - inset / a, 0.72)
	end
	b:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTab)
	layoutTab()
	b.Activated:Connect(function() current = t.Id; render() end)
	tabButtons[t.Id] = b
	tabColors[t.Id] = t.Color
end
-- Studio-only test hook (never created in live servers): switch tabs without clicking
if RunService:IsStudio() then
	local hook = Instance.new("BindableEvent")
	hook.Name = "TestSelectTab"
	hook.Event:Connect(function(id) current = id; render() end)
	hook.Parent = panel
end

local function clear()
	live = {}
	for _, c in ipairs(content:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end
local function card(order, aspect, color)
	local f = nodecor(mk("Frame", {LayoutOrder = order, Size = UDim2.fromScale(1, 1), BackgroundColor3 = color or CARD}, content))
	mk("UIAspectRatioConstraint", {AspectRatio = aspect or 5, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize}, f)
	round(f, 0.16)
	outline(f, 3, DARK)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(222, 232, 248))}, f)
	return f
end
local function bar(parent, frac, pos, size, color)
	local bg = mk("Frame", {BackgroundColor3 = Color3.fromRGB(205, 215, 230), Position = pos, Size = size}, parent)
	round(bg, 0.5)
	local fill = mk("Frame", {BackgroundColor3 = color or BLUE, Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)}, bg)
	round(fill, 0.5)
	return bg
end
local function actionButton(parent, str, enabled, color, onClick, props)
	local b = mk("TextButton", {Text = "", AutoButtonColor = enabled, BackgroundColor3 = enabled and (color or GREEN) or GREY}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	round(b, 0.3)
	outline(b, 3, DARK)
	-- 2026-10-03 (Claude): clean button that keeps its real colour (green claim, grey when disabled, purple REDEEM)
	nodecor(b)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 215, 235))}, b)
	local l = text(b, str, {Position = UDim2.fromScale(0.06, 0.14), Size = UDim2.fromScale(0.88, 0.72)}, 30)
	if enabled and onClick then
		local busy = false
		b.Activated:Connect(function()
			if busy then return end
			busy = true
			onClick(b, l)
			busy = false
		end)
	end
	return b, l
end
-- 2026-10-03 (Claude, redo): every page starts with the same bold strip in its tab colour: picture, title, one-line hint
local TAB_ICON = {Daily = SnowUI.Assets.rewards, Quests = SnowUI.Assets.quests, Achievements = SnowUI.Assets.achievement, Codes = SnowUI.Assets.codes}
local function header(order, title, sub, _, reserve)
	local col = tabColors[current] or BLUE
	local w = 0.87 - (reserve or 0)
	local h = nodecor(mk("Frame", {Name = "Header", LayoutOrder = order, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE}, content))
	mk("UIAspectRatioConstraint", {AspectRatio = 9.5, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize}, h)
	round(h, 0.3)
	outline(h, 3, DARK)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(col:Lerp(WHITE, 0.2), col:Lerp(DARK, 0.12))}, h)
	local ic = SnowUI.Icon(h, TAB_ICON[current] or SnowUI.Assets.rewards, UDim2.fromScale(0.012, 0.5), UDim2.fromScale(0.3, 0.86), "HeaderIcon")
	ic.AnchorPoint = Vector2.new(0, 0.5)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, ic)
	text(h, (string.gsub(title, "^[^%w]+", "")), {Name = "Title", Position = UDim2.fromScale(0.105, 0.1), Size = UDim2.fromScale(w, 0.5), TextXAlignment = LEFT}, 34)
	text(h, sub, {Name = "Hint", Position = UDim2.fromScale(0.105, 0.6), Size = UDim2.fromScale(w, 0.3), TextXAlignment = LEFT}, 20)
	return h
end
local function claim(action, arg)
	local res = call(action, arg)
	if type(res) == "table" then
		showToast(res.Msg or "", res.Ok and GREEN or RED)
		setState(res.State)
	end
	render()
end

local renderedTab -- 2026-10-03 (Claude): last tab drawn, so a newly opened tab starts at the top

-- 2026-10-03 (Claude, redo): Daily = a 3 x 2 calendar of days 1-6 plus a tall Day 7 prize card, no scrolling. Each day card has a
-- coloured ribbon (green = claimed, gold = next, blue = later), its reward picture and a short title + duration.
local CELL_W, CELL_H, COL_GAP, ROW_GAP, GRID_W = 0.231, 0.475, 0.016, 0.05, 0.725
local REWARD_ICON = {Snow2 = SnowUI.Assets.snow, Luck2 = SnowUI.Assets.luck, Super = SnowUI.Assets.rewards}
local ICON_SCALE = {Luck2 = 1.5, Super = 1.1} -- the clover/gift pictures have more empty margin than the snowflake
local RIBBON_DONE, RIBBON_NEXT, RIBBON_LATER, RIBBON_PRIZE = Color3.fromRGB(70, 195, 105), Color3.fromRGB(255, 165, 40), Color3.fromRGB(85, 145, 235), Color3.fromRGB(240, 95, 125)
local SLATE = Color3.fromRGB(90, 108, 145)
local function rewardLines(i, txt)
	local def = A.Daily[i] or {}
	local boost = def.Boost and A.Boosts[def.Boost]
	if boost then return boost.Name, math.floor((def.Seconds or 0) / 60 + 0.5) .. " min", def.Boost, boost end
	return (string.gsub(txt or "", "^[^%w]+", "")), nil, nil, nil -- server text without its leading emoji
end
local function dayCard(body, name, pos, size, claimed, isNext, top, bottom)
	local f = nodecor(mk("Frame", {Name = name, Position = pos, Size = size, BackgroundColor3 = WHITE}, body))
	round(f, 0.13)
	outline(f, isNext and 4 or 3, isNext and Color3.fromRGB(240, 130, 20) or DARK)
	mk("UIGradient", {Rotation = 90, Color = claimed and ColorSequence.new(Color3.fromRGB(228, 250, 233), Color3.fromRGB(188, 236, 200))
		or ColorSequence.new(top, bottom)}, f)
	return f
end
local function ribbon(card, label, color, y, h)
	local r = nodecor(mk("Frame", {Name = "Ribbon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, y), Size = UDim2.fromScale(0.86, h),
		BackgroundColor3 = color}, card))
	round(r, 0.5)
	outline(r, 2, DARK)
	text(r, label, {Position = UDim2.fromScale(0.06, 0.08), Size = UDim2.fromScale(0.88, 0.84)}, 24)
	return r
end
local function picture(card, id, k, pos, size)
	local slot = mk("Frame", {Name = "RewardIcon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size}, card)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, slot)
	local img = SnowUI.Icon(slot, id, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(k or 1, k or 1), "Picture")
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	return slot
end
local function dayTile(body, i, txt, dd)
	local claimed, isNext = i <= dd.Through, i == dd.NextDay
	local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
	local card = dayCard(body, "Day" .. i, UDim2.fromScale(col * (CELL_W + COL_GAP), row * (CELL_H + ROW_GAP)), UDim2.fromScale(CELL_W, CELL_H),
		claimed, isNext, WHITE, Color3.fromRGB(222, 236, 255))
	ribbon(card, "DAY " .. i, claimed and RIBBON_DONE or (isNext and RIBBON_NEXT or RIBBON_LATER), 0.07, 0.25)
	if claimed then text(card, "\u{2705}", {Position = UDim2.fromScale(0.8, -0.1), Size = UDim2.fromScale(0.26, 0.34), ZIndex = 4}, 30) end
	local main, sub, kind = rewardLines(i, txt)
	picture(card, (kind and REWARD_ICON[kind]) or SnowUI.Assets.snow, ICON_SCALE[kind], UDim2.fromScale(0.22, 0.65), UDim2.fromScale(0.5, 0.5))
	if sub then
		text(card, main, {Position = UDim2.fromScale(0.4, 0.37), Size = UDim2.fromScale(0.56, 0.3), TextColor3 = DARK}, 26, true)
		text(card, sub, {Position = UDim2.fromScale(0.4, 0.66), Size = UDim2.fromScale(0.56, 0.22), TextColor3 = SLATE}, 20, true)
	else
		text(card, main, {Position = UDim2.fromScale(0.4, 0.45), Size = UDim2.fromScale(0.56, 0.34), TextColor3 = DARK}, 26, true)
	end
end
local function prizeTile(body, i, txt, dd)
	local claimed, isNext = i <= dd.Through, i == dd.NextDay
	local x = GRID_W + COL_GAP
	local card = dayCard(body, "Day" .. i, UDim2.fromScale(x, 0), UDim2.fromScale(1 - x, 1), claimed, isNext,
		Color3.fromRGB(255, 247, 212), Color3.fromRGB(255, 206, 108))
	ribbon(card, "DAY " .. i, claimed and RIBBON_DONE or (isNext and RIBBON_NEXT or RIBBON_PRIZE), 0.04, 0.115)
	if claimed then text(card, "\u{2705}", {Position = UDim2.fromScale(0.74, -0.05), Size = UDim2.fromScale(0.32, 0.17), ZIndex = 4}, 34) end
	local main, sub, kind, boost = rewardLines(i, txt)
	picture(card, (kind and REWARD_ICON[kind]) or SnowUI.Assets.rewards, ICON_SCALE[kind], UDim2.fromScale(0.5, 0.39), UDim2.fromScale(0.66, 0.36))
	text(card, string.upper(main), {Position = UDim2.fromScale(0.05, 0.6), Size = UDim2.fromScale(0.9, 0.13)}, 32)
	if boost and (boost.Snow or 1) > 1 and (boost.Luck or 1) > 1 then
		text(card, string.format("%dx Snow + %dx Luck", boost.Snow, boost.Luck), {Position = UDim2.fromScale(0.06, 0.74), Size = UDim2.fromScale(0.88, 0.1), TextColor3 = DARK}, 22, true)
	end
	if sub then text(card, "for " .. sub, {Position = UDim2.fromScale(0.06, 0.845), Size = UDim2.fromScale(0.88, 0.09), TextColor3 = SLATE}, 20, true) end
end

local function renderDaily()
	local dd = state.Daily
	local h = header(1, "DAILY REWARDS", "Come back every day for a new gift!", nil, 0.37)
	local pos, size = UDim2.fromScale(0.64, 0.17), UDim2.fromScale(0.345, 0.66)
	if dd.CanClaim then
		actionButton(h, "CLAIM DAY " .. dd.NextDay .. "!", true, GREEN, function() claim("ClaimDaily") end, {Position = pos, Size = size})
	else
		local _, l = actionButton(h, "", false, nil, nil, {Position = pos, Size = size})
		local function upd() l.Text = "Next in " .. clock(dd.NextAt - serverNow()) end
		upd()
		table.insert(live, upd)
	end
	local body = mk("Frame", {Name = "DailyBody", LayoutOrder = 2, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, content)
	mk("UIAspectRatioConstraint", {AspectRatio = 3.15, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize}, body)
	local n = #dd.Rewards
	for i, txt in ipairs(dd.Rewards) do
		if i == n and n == 7 then prizeTile(body, i, txt, dd) else dayTile(body, i, txt, dd) end
	end
end

local function renderQuests()
	header(1, "📜 QUESTS", "Finish quests to win boosts and snow!", Color3.fromRGB(212, 232, 255))
	local open = false
	for i, q in ipairs(state.Quests) do
		if not q.Claimed then open = true end
		local done = q.Progress >= q.Goal
		local c = card(1 + i, 4.2, q.Claimed and Color3.fromRGB(215, 240, 220) or CARD)
		text(c, q.Text, {Position = UDim2.fromScale(0.04, 0.07), Size = UDim2.fromScale(0.62, 0.36), TextXAlignment = LEFT, TextColor3 = DARK}, 30, true)
		bar(c, q.Progress / math.max(1, q.Goal), UDim2.fromScale(0.04, 0.48), UDim2.fromScale(0.6, 0.2), done and GREEN or BLUE)
		text(c, NumberFormat.Abbreviate(q.Progress) .. " / " .. NumberFormat.Abbreviate(q.Goal),
			{Position = UDim2.fromScale(0.04, 0.48), Size = UDim2.fromScale(0.6, 0.2)}, 20)
		text(c, "Reward: " .. q.Reward, {Position = UDim2.fromScale(0.04, 0.73), Size = UDim2.fromScale(0.62, 0.22), TextXAlignment = LEFT}, 22, true)
		local pos, size = UDim2.fromScale(0.69, 0.25), UDim2.fromScale(0.28, 0.5)
		if q.Claimed then
			actionButton(c, "CLAIMED ✅", false, nil, nil, {Position = pos, Size = size})
		else
			actionButton(c, done and "CLAIM!" or "IN PROGRESS", done, GREEN, function() claim("ClaimQuest", i) end, {Position = pos, Size = size})
		end
	end
	if not open and (state.NextQuests or 0) > 0 then
		local c = card(20, 6.5, Color3.fromRGB(255, 240, 210))
		local l = text(c, "", {Position = UDim2.fromScale(0.05, 0.15), Size = UDim2.fromScale(0.9, 0.7)}, 32)
		local function upd() l.Text = "⏳ New quests in " .. clock(state.NextQuests - serverNow()) end
		upd()
		table.insert(live, upd)
	end
end

local function renderAchievements()
	local have = 0
	for _, x in ipairs(state.Achievements) do if x.Have then have += 1 end end
	local s, l = player:GetAttribute("AchSnowBonus") or 0, player:GetAttribute("AchLuckBonus") or 0
	header(1, string.format("🏆 ACHIEVEMENTS  %d/%d", have, #A.Achievements),
		string.format("Your bonus forever: +%d%% Snow  +%d%% Luck", math.floor(s * 100 + 0.5), math.floor(l * 100 + 0.5)),
		Color3.fromRGB(255, 238, 190))
	for i, x in ipairs(state.Achievements) do
		local def = A.AchievementById[x.Id]
		if def then
			local c = card(1 + i, 5, x.Have and Color3.fromRGB(200, 243, 208) or CARD)
			text(c, (x.Have and "✅ " or "") .. def.Name, {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.6, 0.42), TextXAlignment = LEFT, TextColor3 = DARK}, 30, true)
			text(c, def.Text, {Position = UDim2.fromScale(0.04, 0.54), Size = UDim2.fromScale(0.6, 0.36), TextXAlignment = LEFT}, 22, true)
			text(c, A.BonusText(def), {Position = UDim2.fromScale(0.66, 0.08), Size = UDim2.fromScale(0.31, 0.4), TextColor3 = GOLD}, 24)
			if not x.Have then
				bar(c, x.Progress / def.Goal, UDim2.fromScale(0.66, 0.56), UDim2.fromScale(0.31, 0.28), GOLD)
				text(c, NumberFormat.Abbreviate(x.Progress) .. " / " .. NumberFormat.Abbreviate(def.Goal),
					{Position = UDim2.fromScale(0.66, 0.56), Size = UDim2.fromScale(0.31, 0.28)}, 18)
			end
		end
	end
end

local function renderCodes()
	header(1, "🔑 CODES", "Type a secret code to get a free reward!", Color3.fromRGB(228, 214, 255))
	local c = card(2, 3.6)
	local box = mk("TextBox", {Name = "CodeBox", PlaceholderText = "Enter code here...", Text = "", ClearTextOnFocus = false, Font = FONT,
		TextScaled = true, TextColor3 = TEXT_DARK, PlaceholderColor3 = GREY, BackgroundColor3 = WHITE,
		Position = UDim2.fromScale(0.05, 0.12), Size = UDim2.fromScale(0.6, 0.4)}, c)
	nodecor(box)
	round(box, 0.3)
	outline(box, 2.5, DARK)
	mk("UITextSizeConstraint", {MaxTextSize = 30}, box)
	local result = text(c, "", {Name = "Result", Position = UDim2.fromScale(0.05, 0.62), Size = UDim2.fromScale(0.9, 0.3)}, 24)
	actionButton(c, "REDEEM", true, Color3.fromRGB(170, 110, 255), function()
		local res = call("Redeem", box.Text)
		if type(res) == "table" then
			result.Text = res.Msg or ""
			result.TextColor3 = res.Ok and GREEN or RED
			if res.Ok then box.Text = ""; setState(res.State) end
		end
	end, {Name = "Redeem", Position = UDim2.fromScale(0.68, 0.12), Size = UDim2.fromScale(0.27, 0.4)})
end

local lastSig
render = function()
	for id, b in pairs(tabButtons) do
		-- 2026-10-03 (Claude): open tab = full colour, white outline, a bit taller; the others = a darker shade of their colour
		-- (white text stays readable). No see-through tabs: 40% transparency turned the gold tab grey-green.
		local sel = id == current
		b.BackgroundTransparency = 0
		b.BackgroundColor3 = sel and tabColors[id] or tabColors[id]:Lerp(DARK, 0.22)
		local s = b:FindFirstChildOfClass("UIStroke")
		if s then s.Thickness = sel and 3 or 2.5; s.Color = sel and WHITE or DARK end
		-- taller instead of scaled: a UIScale here made the list layout push the whole row past the card edges
		b.Size = UDim2.fromScale(TAB_WIDTH[id] or 0.235, sel and 1.12 or 1)
	end
	if not state then fetch() end
	local pos = content.CanvasPosition
	if current ~= renderedTab then pos = Vector2.zero end -- 2026-10-03 (Claude): a newly opened tab starts at the top
	renderedTab = current
	clear()
	if not state then
		text(card(1, 6.5), "Loading...", {Position = UDim2.fromScale(0.1, 0.2), Size = UDim2.fromScale(0.8, 0.6)}, 30)
		return
	end
	if current == "Daily" then renderDaily()
	elseif current == "Quests" then renderQuests()
	elseif current == "Achievements" then renderAchievements()
	else renderCodes() end
	lastSig = HttpService:JSONEncode({state.Daily, state.Quests, state.Achievements, state.NextQuests, current})
	task.defer(function() content.CanvasPosition = pos end)
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then renderedTab = nil; fetch(); render() end
end)

-- live refresh while open (rebuild only when something changed)
task.spawn(function()
	while true do
		task.wait(2.5)
		if panel.Visible and current ~= "Codes" then
			fetch()
			if state and HttpService:JSONEncode({state.Daily, state.Quests, state.Achievements, state.NextQuests, current}) ~= lastSig then render() end
		end
	end
end)

push.OnClientEvent:Connect(function(msg)
	if type(msg) ~= "table" then return end
	if msg.Type == "Achievement" then
		local a = A.AchievementById[msg.Id]
		if a then showToast("🏆 " .. a.Name .. "!  " .. A.BonusText(a), GOLD) end
	elseif msg.Type == "QuestDone" then
		showToast("📜 Quest done! Claim it in REWARDS", Color3.fromRGB(130, 205, 255))
	elseif msg.Type == "NewQuests" then
		showToast("📜 New quests are ready!", Color3.fromRGB(130, 205, 255))
	end
	if panel.Visible then fetch(); render() end
end)

-- timers: event banner, boost pills, page countdowns
task.spawn(function()
	while true do
		local now = workspace:GetServerTimeNow()
		local ends = RS:GetAttribute("EventEnds")
		if banner.Visible and ends then bannerTime.Text = clock(ends - now) end
		for kind, p in pairs(pills) do
			local e = player:GetAttribute("BoostEnds_" .. kind)
			local left = e and (e - now) or 0
			p.frame.Visible = left > 0
			if left > 0 then p.label.Text = A.Boosts[kind].Icon .. " " .. A.Boosts[kind].Name .. "  " .. clock(left) end
		end
		for _, f in ipairs(live) do pcall(f) end
		task.wait(0.25)
	end
end)
