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
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local fn = RS:WaitForChild("ActivityRemote")
local push = RS:WaitForChild("ActivityPush")
local panel = gui:WaitForChild("Panels"):WaitForChild("Rewards")
local button = gui:WaitForChild("LeftMenu"):WaitForChild("Rewards")
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
local banner = mk("Frame", {Name = "EventBanner", Size = UDim2.fromScale(1, 0.3), BackgroundColor3 = WHITE, Visible = false, LayoutOrder = 1}, hud)
round(banner, 0.25)
outline(banner, 3, DARK)
local bannerGrad = mk("UIGradient", {Rotation = 90}, banner)
local bannerTitle = text(banner, "", {Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.66, 0.5), TextXAlignment = LEFT}, 34)
local bannerText = text(banner, "", {Position = UDim2.fromScale(0.05, 0.56), Size = UDim2.fromScale(0.66, 0.36), TextXAlignment = LEFT}, 22)
local bannerTime = text(banner, "", {Position = UDim2.fromScale(0.72, 0.18), Size = UDim2.fromScale(0.25, 0.64)}, 34)
local pills = {}
for i, kind in ipairs(A.BoostOrder) do
	local k = A.Boosts[kind]
	local p = mk("Frame", {Name = "Boost_" .. kind, Size = UDim2.fromScale(0.72, 0.12), BackgroundColor3 = k.Color, Visible = false, LayoutOrder = 10 + i}, hud)
	round(p, 0.5)
	outline(p, 2, DARK)
	pills[kind] = {frame = p, label = text(p, "", {Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8)}, 24)}
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
		bannerGrad.Color = ColorSequence.new(e.Color:Lerp(WHITE, 0.35), e.Color)
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
local tabBar = mk("Frame", {Name = "RewardTabs", BackgroundTransparency = 1, Position = UDim2.fromScale(0.03, 0.025), Size = UDim2.fromScale(0.94, 0.1)}, inner)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.015, 0),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)
content.AnchorPoint = Vector2.zero
content.Position = UDim2.fromScale(0.03, 0.14)
content.Size = UDim2.fromScale(0.94, 0.83)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.ScrollingDirection = Enum.ScrollingDirection.Y
mk("UIListLayout", {Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, content)
mk("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12)}, content)

local TABS = {
	{Id = "Daily", Text = "🎁 DAILY", Color = Color3.fromRGB(255, 150, 80)},
	{Id = "Quests", Text = "📜 QUESTS", Color = Color3.fromRGB(80, 170, 255)},
	{Id = "Achievements", Text = "🏆 ACHIEVEMENTS", Color = Color3.fromRGB(240, 180, 40)},
	{Id = "Codes", Text = "🔑 CODES", Color = Color3.fromRGB(170, 110, 255)},
}
local current = "Daily"
local tabButtons = {}
for i, t in ipairs(TABS) do
	local b = mk("TextButton", {Name = t.Id, LayoutOrder = i, Size = UDim2.fromScale(0.235, 1), BackgroundColor3 = t.Color, Text = "", AutoButtonColor = true}, tabBar)
	round(b, 0.3)
	outline(b, 2, DARK)
	text(b, t.Text, {Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76)}, 26)
	b.Activated:Connect(function() current = t.Id; render() end)
	tabButtons[t.Id] = b
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
	local f = mk("Frame", {LayoutOrder = order, Size = UDim2.fromScale(1, 0), BackgroundColor3 = color or CARD}, content)
	mk("UIAspectRatioConstraint", {AspectRatio = aspect or 5, DominantAxis = Enum.DominantAxis.Width}, f)
	round(f, 0.16)
	outline(f, 2, DARK)
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
	outline(b, 2, DARK)
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
local function header(order, title, sub, color)
	local h = card(order, 6.5, color)
	text(h, title, {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.92, 0.5), TextXAlignment = LEFT}, 36)
	text(h, sub, {Position = UDim2.fromScale(0.04, 0.6), Size = UDim2.fromScale(0.92, 0.32), TextXAlignment = LEFT}, 22, true)
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

local function renderDaily()
	local dd = state.Daily
	header(1, "🎁 DAILY REWARDS", "Come back every day! Day 7 gives a Super Boost.", Color3.fromRGB(255, 232, 200))
	local grid = mk("Frame", {LayoutOrder = 2, Size = UDim2.fromScale(1, 0), BackgroundTransparency = 1}, content)
	mk("UIAspectRatioConstraint", {AspectRatio = 2.3, DominantAxis = Enum.DominantAxis.Width}, grid)
	mk("UIGridLayout", {CellSize = UDim2.fromScale(0.235, 0.47), CellPadding = UDim2.fromScale(0.018, 0.05),
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}, grid)
	for i, txt in ipairs(dd.Rewards) do
		local claimed = i <= dd.Through
		local isNext = i == dd.NextDay
		local tile = mk("Frame", {LayoutOrder = i, BackgroundColor3 = claimed and Color3.fromRGB(185, 238, 195)
			or (isNext and Color3.fromRGB(255, 222, 130) or CARD)}, grid)
		round(tile, 0.15)
		outline(tile, isNext and 3 or 2, isNext and Color3.fromRGB(240, 140, 30) or DARK)
		text(tile, "DAY " .. i, {Position = UDim2.fromScale(0.05, 0.04), Size = UDim2.fromScale(0.9, 0.26)}, 26)
		text(tile, txt, {Position = UDim2.fromScale(0.06, 0.32), Size = UDim2.fromScale(0.88, 0.42)}, 20, true)
		if claimed then text(tile, "✅", {Position = UDim2.fromScale(0.3, 0.74), Size = UDim2.fromScale(0.4, 0.24)}, 24) end
	end
	local foot = card(3, 6.5)
	if dd.CanClaim then
		actionButton(foot, "CLAIM DAY " .. dd.NextDay .. "!", true, GREEN, function() claim("ClaimDaily") end,
			{Position = UDim2.fromScale(0.2, 0.14), Size = UDim2.fromScale(0.6, 0.72)})
	else
		local _, l = actionButton(foot, "", false, nil, nil, {Position = UDim2.fromScale(0.15, 0.14), Size = UDim2.fromScale(0.7, 0.72)})
		local function upd() l.Text = "Next reward in " .. clock(dd.NextAt - serverNow()) end
		upd()
		table.insert(live, upd)
	end
end

local function renderQuests()
	header(1, "📜 QUESTS", "Finish quests to win boosts and snow!", Color3.fromRGB(212, 232, 255))
	local open = false
	for i, q in ipairs(state.Quests) do
		if not q.Claimed then open = true end
		local done = q.Progress >= q.Goal
		local c = card(1 + i, 4.2, q.Claimed and Color3.fromRGB(215, 240, 220) or CARD)
		text(c, q.Text, {Position = UDim2.fromScale(0.04, 0.07), Size = UDim2.fromScale(0.62, 0.36), TextXAlignment = LEFT}, 30)
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
			text(c, (x.Have and "✅ " or "") .. def.Name, {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.6, 0.42), TextXAlignment = LEFT}, 30)
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
	round(box, 0.3)
	outline(box, 2, DARK)
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
		b.BackgroundTransparency = (id == current) and 0 or 0.4
		local s = b:FindFirstChildOfClass("UIStroke")
		if s then s.Thickness = (id == current) and 3 or 2 end
	end
	if not state then fetch() end
	local pos = content.CanvasPosition
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
	if panel.Visible then fetch(); render() end
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
