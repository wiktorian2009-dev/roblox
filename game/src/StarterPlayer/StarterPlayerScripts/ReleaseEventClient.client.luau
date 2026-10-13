-- ReleaseEventClient (2026-10-13, Claude): thin RELEASE EVENT banner with the time left, sitting just above the Snow counter
-- (RNGGui.SnowCounter; top centre if that is missing - the top centre is used by the tutorial card and the boss bar).
-- * Shown only while ReplicatedStorage attributes ReleaseEventStarts / ReleaseEventEnds (set by ReleaseEventService) say the
--   event is on; gone when it ends. Display only, never blocks taps.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local C = require(RS:WaitForChild("ReleaseEventConfig"))
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local GOLD, ICE = Color3.fromRGB(255, 220, 90), Color3.fromRGB(150, 210, 255)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local gui = mk("ScreenGui", {Name = "ReleaseEventGui", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 5,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, pg)
local pill = mk("Frame", {Name = "Banner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = NAVY, BackgroundTransparency = 0.15,
	Active = false}, gui)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, pill)
local stroke = mk("UIStroke", {Thickness = 1.5, Color = ICE, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, pill)
mk("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, pill)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}, pill)
local function part(order, text, color)
	return mk("TextLabel", {LayoutOrder = order, BackgroundTransparency = 1, Font = FONT, Text = text, TextColor3 = color,
		TextSize = 18, Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X}, pill)
end
part(1, "\u{2744}\u{FE0F} " .. C.Title, WHITE)
local boost = part(2, C.Boost, GOLD)
local timeLeft = part(3, "", ICE)
timeLeft.Font = Enum.Font.GothamBold
timeLeft.TextSize = 15

-- gentle pulse on the 2x so it catches the eye without flashing
TweenService:Create(boost, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{TextColor3 = Color3.fromRGB(255, 245, 190)}):Play()
TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{Transparency = 0.6}):Play()

local function fmt(sec)
	sec = math.max(0, math.floor(sec))
	local h, m, s = sec // 3600, (sec // 60) % 60, sec % 60
	if h > 0 then return string.format("%dh %02dm left", h, m) end
	return string.format("%d:%02d left", m, s)
end

-- follow the Snow counter (it is scale-sized, so re-check every tick)
local function place()
	local rng = pg:FindFirstChild("RNGGui")
	local counter = rng and rng:FindFirstChild("SnowCounter")
	if not (counter and counter:IsA("GuiObject")) then
		gui.IgnoreGuiInset = false
		pill.AnchorPoint, pill.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 6)
		return true
	end
	if not (counter.Visible and rng.Enabled) then return false end -- HUD hidden (full-screen menu): hide with it
	gui.IgnoreGuiInset = rng.IgnoreGuiInset
	local bg = counter:FindFirstChild("Background")
	local top = math.min(counter.AbsolutePosition.Y, bg and bg:IsA("GuiObject") and bg.AbsolutePosition.Y or math.huge)
	pill.AnchorPoint = Vector2.new(0, 1)
	local origin = gui.AbsolutePosition -- the ScreenGui's own origin (e.g. 0, -58 when it ignores the top bar)
	pill.Position = UDim2.fromOffset(counter.AbsolutePosition.X - origin.X + 8, top - origin.Y - 6)
	return true
end

while true do
	local starts, ends = RS:GetAttribute("ReleaseEventStarts"), RS:GetAttribute("ReleaseEventEnds")
	local now = workspace:GetServerTimeNow()
	local on = type(starts) == "number" and type(ends) == "number" and now >= starts and now < ends
	if on then timeLeft.Text = fmt(ends - now); on = place() end
	gui.Enabled = on
	task.wait(1)
end
