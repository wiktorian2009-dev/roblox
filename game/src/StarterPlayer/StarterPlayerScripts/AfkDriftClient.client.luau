-- AfkDriftClient (2026-10-06, Claude): the AFK auto-plow button (right next to UPGRADES, SnowArt look) and the drift Snow bonus meter.
-- The server decides everything (AfkService / SnowFieldService); this only asks, shows and reports input:
--   * AFK: tap to ask the server; the button turns green while the player attribute AfkPlow is on. Any key, gamepad button, stick
--     or tap on the world turns it off again. Roblox may still disconnect idle players after ~20 minutes - we say so, and nothing
--     here works around it.
--   * Drift meter: reads the DriftMeter attribute (0..100) the server sets while a slide clears snow; shows "+x% SNOW".
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local C = require(RS:WaitForChild("PlowConfig"))
local SnowArt = require(RS:WaitForChild("SnowArt"))
local CleanControls = require(RS:WaitForChild("CleanControls"))
local remote = RS:WaitForChild("AfkRemote")
local BONUS = (C.Drive.Drift and C.Drive.Drift.SnowBonus) or 0.1
local RATE = (C.Afk and C.Afk.Rate) or 0.3

local gui = Instance.new("ScreenGui")
gui.Name = "AfkDriftGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 5; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local rng = pg:WaitForChild("RNGGui", 30)
gui.IgnoreGuiInset = rng and rng.IgnoreGuiInset or false
gui.Parent = pg

local FONT = Enum.Font.FredokaOne
local function label(parent, text, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Font = FONT; t.TextScaled = true; t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Color = Color3.fromRGB(20, 40, 70); s.Parent = t
	for k, v in pairs(props or {}) do t[k] = v end
	t.Parent = parent
	return t
end

-- AFK button ----------------------------------------------------------------------------------------------------------------------
local btn = Instance.new("TextButton")
btn.Name = "AfkButton"; btn.Text = ""; btn.AutoButtonColor = true
btn:SetAttribute("SnowUIDecor", true)
btn.BackgroundColor3 = Color3.fromRGB(70, 150, 245)
btn.Size = UDim2.fromOffset(96, 52); btn.AnchorPoint = Vector2.new(0, 0.5)
btn.Position = UDim2.new(0.5, 70, 1, -60)
btn.Parent = gui
CleanControls.Apply(btn)
local title = label(btn, "AFK", {Name = "Label", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.8, 0.46), ZIndex = 3})
local sub = label(btn, "AUTO-PLOW", {Name = "Sub", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromScale(0.82, 0.26), ZIndex = 3})

-- caption above the button: what it does + the Roblox idle note (always shown while on; on hover otherwise)
local cap = Instance.new("Frame")
cap.Name = "AfkCaption"; cap.AnchorPoint = Vector2.new(0.5, 1); cap.Size = UDim2.fromOffset(250, 46)
cap.BackgroundColor3 = Color3.fromRGB(18, 30, 52); cap.BackgroundTransparency = 0.25; cap.Visible = false; cap.Parent = gui
Instance.new("UICorner", cap).CornerRadius = UDim.new(0, 10)
local capTop = label(cap, "", {Position = UDim2.fromScale(0.04, 0.06), Size = UDim2.fromScale(0.92, 0.48)})
local capNote = label(cap, "Roblox may disconnect you after 20 min idle", {Position = UDim2.fromScale(0.04, 0.56), Size = UDim2.fromScale(0.92, 0.36), TextColor3 = Color3.fromRGB(190, 215, 245)})

-- toast for server answers ("Drive onto a snow field first.", "AFK off: ...")
local toast = label(gui, "", {Name = "AfkToast", AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(320, 26), Visible = false})
local toastId = 0
local function say(text)
	toastId += 1; local my = toastId
	toast.Text = text; toast.TextTransparency = 0; toast.Visible = btn.Visible -- 2026-10-08: no floating toast while the button is hidden (arena island / bar hidden)
	task.delay(3, function()
		if my ~= toastId then return end
		TweenService:Create(toast, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
		task.wait(0.65); if my == toastId then toast.Visible = false end
	end)
end

-- placement: directly to the right of UPGRADES, same vertical centre (live position, so it follows any resolution / layout)
local upgrades
local function place()
	upgrades = upgrades or pg:FindFirstChild("UpgradesButton", true)
	if upgrades and upgrades:IsA("GuiObject") then
		local ap, as = upgrades.AbsolutePosition - gui.AbsolutePosition, upgrades.AbsoluteSize -- 2026-10-06: screen space -> this gui's space (top-bar inset)
		local h = math.clamp(as.Y * 0.62, 40, 64)
		btn.Size = UDim2.fromOffset(math.floor(h * 1.85), math.floor(h))
		btn.Position = UDim2.fromOffset(ap.X + as.X + math.max(8, as.X * 0.08), ap.Y + as.Y / 2)
	end
	local bp, bs = btn.AbsolutePosition - gui.AbsolutePosition, btn.AbsoluteSize
	cap.Position = UDim2.fromOffset(bp.X + bs.X / 2, bp.Y - 6)
	toast.Position = UDim2.fromOffset(bp.X + bs.X / 2, bp.Y - 58)
end
-- (the task that finds UPGRADES and wires place() / showButton() lives at the end of the file, after the meter exists)
btn:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)

local function on() return player:GetAttribute("AfkPlow") == true end
local hovering = false
local function refresh()
	local a = on()
	btn.BackgroundColor3 = a and Color3.fromRGB(70, 200, 105) or Color3.fromRGB(70, 150, 245)
	title.Text = a and "AFK ON" or "AFK"
	sub.Text = a and "TAP TO STOP" or "AUTO-PLOW"
	capTop.Text = a and ("Auto-plowing: " .. math.floor(RATE * 100 + 0.5) .. "% Snow") or "Auto-plow this field while AFK"
	cap.Visible = btn.Visible and (a or hovering)
end
player:GetAttributeChangedSignal("AfkPlow"):Connect(refresh)
btn.MouseEnter:Connect(function() hovering = true; refresh() end)
btn.MouseLeave:Connect(function() hovering = false; refresh() end)
refresh()

local lastAsk = 0
btn.Activated:Connect(function()
	if os.clock() - lastAsk < 0.8 then return end
	lastAsk = os.clock()
	remote:FireServer(not on())
end)
remote.OnClientEvent:Connect(function(_, msg) if type(msg) == "string" and msg ~= "" then say(msg) end end)

-- any player input ends AFK (the AFK button itself is handled by its own click)
local function stop()
	if on() and os.clock() - lastAsk > 0.3 then lastAsk = os.clock(); remote:FireServer(false) end
end
UIS.InputBegan:Connect(function(input, processed)
	if not on() then return end
	local t = input.UserInputType
	if t == Enum.UserInputType.Keyboard or t.Name:find("^Gamepad") then stop()
	elseif (t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2) and not processed then stop() end
end)
UIS.InputChanged:Connect(function(input)
	if on() and input.KeyCode == Enum.KeyCode.Thumbstick1 and input.Position.Magnitude > 0.35 then stop() end
end)

-- drift meter ---------------------------------------------------------------------------------------------------------------------
local meter = Instance.new("Frame")
meter.Name = "DriftMeter"; meter.AnchorPoint = Vector2.new(0.5, 1); meter.Size = UDim2.fromOffset(190, 30)
meter.Position = UDim2.new(0.5, 0, 1, -128); meter.BackgroundColor3 = Color3.fromRGB(18, 30, 52); meter.BackgroundTransparency = 0.3
meter.Visible = false; meter.Parent = gui
Instance.new("UICorner", meter).CornerRadius = UDim.new(0, 10)
local fill = Instance.new("Frame")
fill.Name = "Fill"; fill.BackgroundColor3 = Color3.fromRGB(120, 150, 255); fill.Size = UDim2.fromScale(0, 1); fill.Parent = meter
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 10)
local mText = label(meter, "", {Position = UDim2.fromScale(0.04, 0.1), Size = UDim2.fromScale(0.92, 0.8), ZIndex = 2})
local function drawMeter()
	local m = (player:GetAttribute("DriftMeter") or 0) / 100
	meter.Visible = m > 0 and not on() and btn.Visible
	if m <= 0 then return end
	fill.Size = UDim2.fromScale(math.clamp(m, 0.06, 1), 1)
	mText.Text = string.format("DRIFT  +%d%% SNOW", math.floor(m * BONUS * 100 + 0.5))
	if upgrades then
		local ap = upgrades.AbsolutePosition - gui.AbsolutePosition
		meter.Position = UDim2.fromOffset(ap.X + upgrades.AbsoluteSize.X / 2, ap.Y - 8)
	end
end
player:GetAttributeChangedSignal("DriftMeter"):Connect(drawMeter)
player:GetAttributeChangedSignal("AfkPlow"):Connect(drawMeter)

-- visibility + wiring (2026-10-08) ------------------------------------------------------------------------------------------------
-- Same rule as MiniPlowClient.showButton: the AFK button is shown only while the bottom bar (UPGRADES) is shown. The Bumper Arena
-- island hides that bar (ArenaHudClient HIDE list) and sets InArenaIsland, and AfkService refuses AFK there anyway, so the button,
-- its caption, its toast and the drift meter all hide with it instead of floating over the arena HUD. Placement / server stay as they were.
local function showButton()
	local bar = upgrades and upgrades.Parent
	local vis = upgrades ~= nil and upgrades.Visible and not (bar and bar:IsA("GuiObject") and not bar.Visible) and player:GetAttribute("InArenaIsland") ~= true
	btn.Visible = vis
	if vis then
		place()
		refresh(); drawMeter()
	else
		hovering = false -- MouseLeave never fires on a hidden button
		cap.Visible = false; toast.Visible = false; meter.Visible = false
	end
end
local barConn
local function watchBar()
	if barConn then barConn:Disconnect(); barConn = nil end
	local bar = upgrades and upgrades.Parent
	if bar and bar:IsA("GuiObject") then barConn = bar:GetPropertyChangedSignal("Visible"):Connect(showButton) end
	showButton()
end
task.spawn(function()
	for _ = 1, 60 do
		place()
		if upgrades then break end
		task.wait(0.5)
	end
	if upgrades then
		upgrades:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
		upgrades:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		upgrades:GetPropertyChangedSignal("Visible"):Connect(showButton)
		upgrades.AncestryChanged:Connect(function() watchBar(); place() end)
		watchBar()
	end
end)
player:GetAttributeChangedSignal("InArenaIsland"):Connect(showButton)
showButton()
