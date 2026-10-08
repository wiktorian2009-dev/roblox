-- DiceMeter (Claude, 2026-10-01): Golden / Rainbow dice counters above the roll button + a banner when one lands.
-- Rules live on the server (RNGHandler): every Nth lifetime roll (leaderstats Rolls) gets x GoldenLuck / x RainbowLuck.
-- Intervals and multipliers come from upgrade tiles via player attributes GoldenEvery, RainbowEvery, GoldenLuck, RainbowLuck.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script.Parent
local bar = gui:WaitForChild("BottomBar")
local remote = RS:WaitForChild("RollRNG")

local FONT = Enum.Font.FredokaOne
local C = Color3.fromRGB
local NAVY, WHITE = C(31, 35, 76), C(255, 255, 255)
local GOLD = ColorSequence.new(C(255, 236, 130), C(238, 160, 25))
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C(255, 95, 120)), ColorSequenceKeypoint.new(0.2, C(255, 170, 60)),
	ColorSequenceKeypoint.new(0.4, C(255, 232, 80)), ColorSequenceKeypoint.new(0.6, C(110, 228, 125)),
	ColorSequenceKeypoint.new(0.8, C(90, 170, 255)), ColorSequenceKeypoint.new(1, C(195, 115, 255)),
})

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

-- counters, placed just above the bottom bar (same ScreenGui, so positions line up)
local holder = mk("Frame", {Name = "DiceCounters", AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1,
	Size = UDim2.fromOffset(300, 30), Visible = false}, gui)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, holder)
local SnowUI = require(game:GetService("ReplicatedStorage"):WaitForChild("SnowUI"))
local function pill(name, order, seq)
	local f = mk("Frame", {Name = name, LayoutOrder = order, Size = UDim2.fromOffset(142, 30), BackgroundColor3 = WHITE, Visible = false}, holder)
	f:SetAttribute("SnowUIDecor", true) -- 2026-10-04 (Claude): small pills skip the frost overlay
	mk("UICorner", {CornerRadius = UDim.new(1, 0)}, f)
	mk("UIStroke", {Thickness = 2.5, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
	local grad = mk("UIGradient", {Color = seq}, f)
	local die = SnowUI.Icon(f, "rbxassetid://82230206975104", UDim2.fromScale(0.04, 0.09), UDim2.fromScale(0.16, 0.82), "DiceIcon")
	mk("UIGradient", {Color = seq, Rotation = 30}, die)
	local label = mk("TextLabel", {Name = "Label", BackgroundTransparency = 1, Position = UDim2.fromScale(0.23, 0.12), Size = UDim2.fromScale(0.72, 0.76),
		Font = FONT, TextScaled = true, TextColor3 = WHITE, Text = ""}, f)
	mk("UIStroke", {Thickness = 2, Color = NAVY}, label)
	return {frame = f, label = label, grad = grad, scale = mk("UIScale", {Scale = 1}, f), nextUp = false}
end
local gold = pill("Golden", 1, GOLD)
local rainbow = pill("Rainbow", 2, RAINBOW)

local function place()
	local rel = bar.AbsolutePosition - gui.AbsolutePosition
	holder.Position = UDim2.fromOffset(rel.X + bar.AbsoluteSize.X / 2, rel.Y - 6)
end
bar:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
place()

local function rollsDone()
	local ls = player:FindFirstChild("leaderstats")
	local v = ls and ls:FindFirstChild("Rolls")
	return v and v.Value or 0
end
local function setPill(p, every, word, mult)
	if every <= 0 then p.frame.Visible = false p.nextUp = false return false end
	p.frame.Visible = true
	local left = every - (rollsDone() % every)
	p.nextUp = left == 1
	p.label.Text = p.nextUp and (word .. " NEXT! x" .. mult) or (word .. " IN " .. left)
	return true
end
local function refresh()
	local g = setPill(gold, math.floor(player:GetAttribute("GoldenEvery") or 0), "GOLDEN", player:GetAttribute("GoldenLuck") or 3)
	local r = setPill(rainbow, math.floor(player:GetAttribute("RainbowEvery") or 0), "RAINBOW", player:GetAttribute("RainbowLuck") or 10)
	holder.Visible = g or r
end

RunService.RenderStepped:Connect(function()
	if not holder.Visible then return end
	local t = os.clock()
	rainbow.grad.Offset = Vector2.new(math.sin(t * 0.8) * 0.25, 0)
	for _, p in ipairs({gold, rainbow}) do
		p.scale.Scale = p.nextUp and (1 + 0.06 * (0.5 + 0.5 * math.sin(t * 6))) or 1
	end
end)

-- banner when a special roll lands
local bannerGui = mk("ScreenGui", {Name = "DiceBannerGui", DisplayOrder = 60, IgnoreGuiInset = true, ResetOnSpawn = false}, player:WaitForChild("PlayerGui"))
local banner = mk("Frame", {Name = "Banner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34), Size = UDim2.fromScale(0.36, 0.09),
	BackgroundColor3 = WHITE, Visible = false}, bannerGui)
mk("UIAspectRatioConstraint", {AspectRatio = 5.2}, banner)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, banner)
mk("UIStroke", {Thickness = 4, Color = NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, banner)
local bannerGrad = mk("UIGradient", {Color = GOLD}, banner)
local bannerText = mk("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.14), Size = UDim2.fromScale(0.9, 0.72),
	Font = FONT, TextScaled = true, TextColor3 = WHITE, Text = ""}, banner)
mk("UIStroke", {Thickness = 3, Color = NAVY}, bannerText)
local bannerScale = mk("UIScale", {Scale = 1}, banner)
local shown = 0
local function pop(seq, text)
	shown += 1
	local id = shown
	bannerGrad.Color = seq
	bannerText.Text = text
	banner.Visible = true
	bannerScale.Scale = 0.3
	TweenService:Create(bannerScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	task.delay(2.4, function()
		if shown ~= id then return end
		local tw = TweenService:Create(bannerScale, TweenInfo.new(0.2), {Scale = 0})
		tw:Play()
		tw.Completed:Wait()
		if shown == id then banner.Visible = false end
	end)
end
local function showBanner(kind, mult)
	pop(kind == "Rainbow" and RAINBOW or GOLD, (kind == "Rainbow" and "RAINBOW ROLL! x" or "GOLDEN ROLL! x") .. mult .. " LUCK")
end

-- Mutations (2026-10-01): banner when the roll reveal lands on a Giant / Shiny shovel
local Config = require(RS:WaitForChild("RNGConfig"))
local BLUE = ColorSequence.new(C(140, 220, 255), C(60, 120, 255))
-- 2026-10-03 (Claude): banner numbers come from RNGConfig (Giant used to say a fixed "x2 SIZE")
local function num(x) local s = ("%.1f"):format(x); return (s:gsub("%.0$", "")) end
local SHINY_P = num(Config.MutationById.Shiny.PowerMult)
local GIANT_S = num(Config.MutationById.Giant.SizeMult)
gui:WaitForChild("RollFinished").Event:Connect(function(result)
	local item = Config.ByName[result]
	local m = item and item.Mutation
	if not m then return end
	if m == "Shiny Giant" then pop(RAINBOW, "SHINY GIANT! x" .. SHINY_P .. " POWER x" .. GIANT_S .. " SIZE")
	elseif m == "Shiny" then pop(GOLD, "SHINY! x" .. SHINY_P .. " POWER")
	else pop(BLUE, "GIANT! x" .. GIANT_S .. " SIZE") end
end)

remote.OnClientEvent:Connect(function(_, _, _, _, _, special)
	if special == "Golden" then showBanner("Golden", player:GetAttribute("GoldenLuck") or 3)
	elseif special == "Rainbow" then showBanner("Rainbow", player:GetAttribute("RainbowLuck") or 10) end
	task.defer(refresh)
end)
for _, a in ipairs({"GoldenEvery", "RainbowEvery", "GoldenLuck", "RainbowLuck"}) do
	player:GetAttributeChangedSignal(a):Connect(refresh)
end
task.spawn(function()
	player:WaitForChild("leaderstats"):WaitForChild("Rolls").Changed:Connect(refresh)
	refresh()
end)
refresh()
