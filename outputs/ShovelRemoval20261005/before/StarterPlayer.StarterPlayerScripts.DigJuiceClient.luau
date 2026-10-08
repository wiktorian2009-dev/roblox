-- DigJuiceClient (2026-10-04, Claude): makes digging feel good. Listens to SnowCollected (gained, combo, layers, mult) from
-- SnowFieldService and adds a combo meter above the dice, a crunch sound whose pitch rises with the combo, snow bursts around
-- the player and callouts (MEGA DIG!, COMBO x10!, MAX COMBO!). Visual/audio only - the server owns every number.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local collected = RS:WaitForChild("SnowCollected")
local Config = require(RS:WaitForChild("RNGConfig"))

local COMBO_WINDOW, COMBO_MAX = 2.5, 20
local FONT = Enum.Font.FredokaOne
local NAVY = Color3.fromRGB(25, 45, 90)
local WHITE = Color3.new(1, 1, 1)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local gui = mk("ScreenGui", {Name = "DigJuice", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 55}, player:WaitForChild("PlayerGui"))
-- combo meter above the dice
local meter = mk("Frame", {Name = "Combo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.635), Size = UDim2.fromScale(0.17, 0.062),
	BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false}, gui)
meter:SetAttribute("SnowUIDecor", true)
mk("UIAspectRatioConstraint", {AspectRatio = 4.6}, meter)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, meter)
mk("UIStroke", {Thickness = 3, Color = NAVY}, meter)
local grad = mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(45, 120, 230))}, meter)
local meterScale = mk("UIScale", {Scale = 1}, meter)
local comboText = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = WHITE,
	Position = UDim2.fromScale(0.05, 0.08), Size = UDim2.fromScale(0.9, 0.6), ZIndex = 2}, meter)
mk("UIStroke", {Thickness = 2, Color = NAVY}, comboText)
local track = mk("Frame", {BackgroundColor3 = Color3.fromRGB(20, 40, 90), BackgroundTransparency = 0.35, BorderSizePixel = 0,
	Position = UDim2.fromScale(0.08, 0.72), Size = UDim2.fromScale(0.84, 0.16), ZIndex = 2}, meter)
track:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, track)
local fill = mk("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3}, track)
fill:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, fill)
-- centre callout
local callout = mk("TextLabel", {Name = "Callout", BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = WHITE,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.11), Visible = false, ZIndex = 5}, gui)
mk("UIStroke", {Thickness = 4, Color = NAVY}, callout)
local calloutScale = mk("UIScale", {Scale = 1}, callout)

-- sounds: the built-in footstep as a crunch, plus the game's own cutscene sounds for milestones
local function sound(id, volume, speed) return mk("Sound", {SoundId = id, Volume = volume, PlaybackSpeed = speed or 1}, gui) end
local crunch = sound("rbxasset://sounds/action_footsteps_plastic.mp3", 0.3)
local rd = (Config.RareDrop and Config.RareDrop.Sounds) or {}
local shimmer = sound(rd.Reveal and rd.Reveal.Id or "rbxassetid://125078105193243", 0.5, 1.2)
local bass = sound(rd.Steps and rd.Steps.Rare and rd.Steps.Rare.Id or "rbxassetid://102456460734361", 0.45)

-- snow bursts from the VFX pack (UniversalVFX): Impact on gains, PowerUp on MEGA DIG, Embers while at max combo
local VFX = require(RS:WaitForChild("UniversalVFX"))
local function hrpPart() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local lastBurst = 0
local function digBurst(scale)
	local hrp = hrpPart()
	if not hrp or os.clock() - lastBurst < 0.18 then return end
	lastBurst = os.clock()
	pcall(VFX.Burst, hrp, "Impact", {Color = Color3.fromRGB(225, 246, 255), Scale = scale, Quality = 0.6, Offset = Vector3.new(0, -2.4, 0)})
end
local maxFx
local function setMaxFx(on)
	local hrp = hrpPart()
	if on and hrp and not (maxFx and maxFx.Root.Parent == hrp) then
		local ok, h = pcall(VFX.Attach, hrp, "Embers", {Color = Color3.fromRGB(255, 160, 230), Scale = 1.2})
		if ok then maxFx = h end
	elseif not on and maxFx then
		pcall(function() maxFx:Destroy() end)
		maxFx = nil
	end
end

local lastGain, lastCrunch, prevCombo = 0, 0, 0
local avgGain, lastMega = nil, 0
local function tierColors(combo)
	if combo >= COMBO_MAX then return Color3.fromRGB(255, 170, 230), Color3.fromRGB(200, 60, 200) end
	if combo >= 10 then return Color3.fromRGB(255, 225, 120), Color3.fromRGB(240, 150, 30) end
	return Color3.fromRGB(120, 200, 255), Color3.fromRGB(45, 120, 230)
end
local function showCallout(text, color)
	callout.Text, callout.TextColor3, callout.Visible, callout.TextTransparency = text, color, true, 0
	calloutScale.Scale = 0.4
	TweenService:Create(calloutScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	task.delay(0.75, function()
		if callout.Text == text then
			TweenService:Create(callout, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
			task.delay(0.3, function() if callout.Text == text then callout.Visible = false end end)
		end
	end)
end

collected.OnClientEvent:Connect(function(gained, combo, layers, mult)
	combo, layers, mult = tonumber(combo) or 0, tonumber(layers) or 0, tonumber(mult) or 1
	-- MEGA DIG = a payout at least 4x your recent average, at most once every 10 s (2026-10-04 v2)
	local g = tonumber(gained) or 0
	local isMega = avgGain ~= nil and g >= avgGain * 4 and os.clock() - lastMega > 10
	avgGain = avgGain and (avgGain * 0.9 + g * 0.1) or g
	if isMega then lastMega = os.clock() end
	lastGain = os.clock()
	if os.clock() - lastCrunch > 0.14 then
		lastCrunch = os.clock()
		crunch.PlaybackSpeed = 0.8 + math.min(combo, COMBO_MAX) * 0.025 + math.random() * 0.06
		crunch:Play()
	end
	digBurst(0.4 + math.min(combo, COMBO_MAX) * 0.025)
	if combo >= 1 then
		local a, b = tierColors(combo)
		grad.Color = ColorSequence.new(a, b)
		comboText.Text = (combo >= COMBO_MAX and "MAX COMBO x%.2f" or "COMBO x%.2f"):format(mult)
		meter.Visible = true
		meterScale.Scale = 1.12
		TweenService:Create(meterScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end
	if isMega then
		showCallout("MEGA DIG!", Color3.fromRGB(255, 230, 120))
		bass:Play()
		local h = hrpPart()
		if h then pcall(VFX.Burst, h, "PowerUp", {Color = Color3.fromRGB(255, 225, 120), Scale = 1}) end
	elseif combo >= COMBO_MAX and prevCombo < COMBO_MAX then
		showCallout("MAX COMBO! x2 SNOW", Color3.fromRGB(255, 170, 230))
		shimmer:Play()
	elseif combo > prevCombo and combo % 5 == 0 and combo < COMBO_MAX then
		showCallout(("COMBO x%.2f!"):format(mult), Color3.fromRGB(255, 225, 120))
		shimmer:Play()
	end
	setMaxFx(combo >= COMBO_MAX)
	prevCombo = combo
end)
-- the timer bar drains; the meter hides when the combo expires
RunService.Heartbeat:Connect(function()
	if not meter.Visible then return end
	local left = COMBO_WINDOW - (os.clock() - lastGain)
	if left <= 0 then
		meter.Visible = false
		prevCombo = 0
		setMaxFx(false)
		return
	end
	fill.Size = UDim2.fromScale(math.clamp(left / COMBO_WINDOW, 0, 1), 1)
end)
