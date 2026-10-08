-- BottomBarFX: idle motion, hover, click bounce, aura pulses and icy sparks for the Roll / Auto / Hide buttons.
-- Only things INSIDE the buttons move, so the layout never shifts.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local bar = script.Parent:WaitForChild("BottomBar")
local roll = bar:WaitForChild("RollButton")
local auto = bar:WaitForChild("AutoButton")
local hide = bar:WaitForChild("HideButton")

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function value(v)
	local nv = Instance.new("NumberValue")
	nv.Value = v
	return nv
end

--------------------------------------------------
-- shared: hover + press scale, aura
--------------------------------------------------
local buttons = {}
local function setup(btn, hoverScale)
	local st = {
		btn = btn,
		scale = btn:WaitForChild("UIScale"),
		aura = btn:WaitForChild("Aura"),
		sparks = btn:WaitForChild("Sparks"),
		hover = value(1),   -- 1 -> hoverScale
		press = value(1),   -- 1 -> 0.92
		glow = value(0),    -- 0 idle, 1 hovered
		hovering = false,
	}
	st.auraScale = st.aura:FindFirstChildOfClass("UIScale")
	btn.MouseEnter:Connect(function()
		st.hovering = true
		tween(st.hover, 0.18, {Value = hoverScale}, Enum.EasingStyle.Back)
		tween(st.glow, 0.2, {Value = 1})
	end)
	btn.MouseLeave:Connect(function()
		st.hovering = false
		tween(st.hover, 0.2, {Value = 1})
		tween(st.glow, 0.25, {Value = 0})
		tween(st.press, 0.2, {Value = 1})
	end)
	btn.MouseButton1Down:Connect(function()
		tween(st.press, 0.07, {Value = 0.92})
	end)
	btn.MouseButton1Up:Connect(function()
		tween(st.press, 0.35, {Value = 1}, Enum.EasingStyle.Back)
	end)
	btn.Activated:Connect(function()
		-- touch screens may skip Up; make sure it always bounces back
		task.delay(0.08, function() tween(st.press, 0.35, {Value = 1}, Enum.EasingStyle.Back) end)
	end)
	buttons[btn] = st
	return st
end

local R = setup(roll, 1.06)
local A = setup(auto, 1.08)
local H = setup(hide, 1.08)
local upgradesB = bar:WaitForChild("UpgradesButton")
local UP = setup(upgradesB, 1.08)

local function updateAura(st, t, phase, extra)
	local pulse = (math.sin(t * 2.2 + phase) + 1) / 2 -- 0..1
	local g = st.glow.Value
	st.auraScale.Scale = 1 + pulse * 0.04 + g * 0.08 + (extra or 0)
	for _, ring in ipairs(st.aura:GetChildren()) do
		if ring:IsA("Frame") then
			local base = ring:GetAttribute("BaseT") or 0.85
			ring.BackgroundTransparency = math.clamp(base - pulse * 0.05 - g * 0.12, 0, 1)
		end
	end
end

--------------------------------------------------
-- icy sparks
--------------------------------------------------
local SPARK_COLORS = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 230, 255), Color3.fromRGB(120, 200, 255)}
local function spark(st, big)
	local a = math.random() * math.pi * 2
	local r0 = 0.46
	local s = Instance.new("Frame")
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.BorderSizePixel = 0
	s.BackgroundColor3 = SPARK_COLORS[math.random(#SPARK_COLORS)]
	s.Rotation = 45
	s.ZIndex = 5
	local size = (big and 0.1 or 0.065) * (0.8 + math.random() * 0.4)
	s.Size = UDim2.fromScale(size, size)
	s.Position = UDim2.fromScale(0.5 + math.cos(a) * r0, 0.5 + math.sin(a) * r0)
	local ar = Instance.new("UIAspectRatioConstraint"); ar.Parent = s
	s.Parent = st.sparks
	local r1 = r0 + 0.12 + math.random() * 0.1
	tween(s, 0.7, {Position = UDim2.fromScale(0.5 + math.cos(a) * r1, 0.5 + math.sin(a) * r1 - 0.05), Rotation = 45 + (math.random() - 0.5) * 120,
		BackgroundTransparency = 1, Size = UDim2.fromScale(size * 0.3, size * 0.3)})
	task.delay(0.75, function() s:Destroy() end)
end
for _, st in pairs(buttons) do
	task.spawn(function()
		while st.btn.Parent do
			task.wait(1.2 + math.random() * 1.8)
			if st.btn.Visible then
				spark(st, false)
				if math.random() < 0.35 then task.wait(0.12); spark(st, true) end
			end
		end
	end)
end

--------------------------------------------------
-- DICE: float, 3D tilt, glow pulse, occasional flourish
--------------------------------------------------
local dice = roll:WaitForChild("Dice")
local flourishRot = value(0)
local flourishScale = value(1)
task.spawn(function()
	while roll.Parent do
		task.wait(4 + math.random() * 2.5)
		if math.random() < 0.5 then
			-- quick spin
			tween(flourishScale, 0.12, {Value = 1.08})
			tween(flourishRot, 0.5, {Value = 360}, Enum.EasingStyle.Back).Completed:Wait()
			flourishRot.Value = 0
			tween(flourishScale, 0.25, {Value = 1}, Enum.EasingStyle.Back)
		else
			-- little shake
			for i, ang in ipairs({12, -10, 7, -4, 0}) do
				tween(flourishRot, 0.07, {Value = ang}).Completed:Wait()
			end
		end
		spark(R, true)
	end
end)

--------------------------------------------------
-- AUTO: arrows rotate while ON, breathing while OFF
--------------------------------------------------
local autoIcon = auto:WaitForChild("Icon")
local autoIconScale = autoIcon:WaitForChild("IconScale")
local autoSpin = 0

--------------------------------------------------
-- HIDE: occasional tilt / pulse, brighten on hover, shrink/fade on click
--------------------------------------------------
local hideIcon = hide:WaitForChild("Icon")
local hideIconScale = hideIcon:WaitForChild("IconScale")
local IDLE_TINT, HOVER_TINT = Color3.fromRGB(232, 232, 232), Color3.new(1, 1, 1)
for _, pair in ipairs({{auto, autoIcon}, {hide, hideIcon}}) do
	pair[1].MouseEnter:Connect(function() tween(pair[2], 0.15, {ImageColor3 = HOVER_TINT}) end)
	pair[1].MouseLeave:Connect(function() tween(pair[2], 0.2, {ImageColor3 = IDLE_TINT}) end)
end
hide.Activated:Connect(function()
	tween(hideIconScale, 0.08, {Scale = 0.7})
	tween(hideIcon, 0.08, {ImageTransparency = 0.45}).Completed:Wait()
	tween(hideIconScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
	tween(hideIcon, 0.25, {ImageTransparency = 0})
end)
task.spawn(function()
	while hide.Parent do
		task.wait(3.5 + math.random() * 3)
		if math.random() < 0.5 then
			tween(hideIcon, 0.18, {Rotation = 8}).Completed:Wait()
			tween(hideIcon, 0.18, {Rotation = -6}).Completed:Wait()
			tween(hideIcon, 0.3, {Rotation = 0}, Enum.EasingStyle.Back)
		else
			tween(hideIconScale, 0.15, {Scale = 1.1}).Completed:Wait()
			tween(hideIconScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
		end
	end
end)

--------------------------------------------------
-- per-frame
--------------------------------------------------
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt

	-- dice
	local float = math.sin(t * 1.6) * 4                 -- a few pixels up/down
	local tilt = math.sin(t * 1.1) * 4                  -- gentle left/right tilt
	local depth = 1 + math.sin(t * 1.1 + math.pi / 2) * 0.03 -- fake 3D: slight horizontal squash as it tilts
	dice.Position = UDim2.new(0.5, 0, 0.5, float)
	dice.Rotation = tilt + flourishRot.Value
	dice.Size = UDim2.fromScale(depth * flourishScale.Value, flourishScale.Value)
	R.scale.Scale = R.hover.Value * R.press.Value
	updateAura(R, t, 0, math.max(0, -float) * 0.004)

	-- auto
	local on = auto:GetAttribute("On") == true
	if on then
		autoSpin = (autoSpin + dt * 120) % 360
		autoIcon.Rotation = autoSpin
		A.scale.Scale = A.hover.Value * A.press.Value
	else
		if autoSpin ~= 0 then
			-- settle forward to the nearest upright position instead of spinning back
			local target = autoSpin > 0 and 360 or 0
			autoSpin = 0
			tween(autoIcon, 0.4, {Rotation = target}, Enum.EasingStyle.Back).Completed:Connect(function()
				if auto:GetAttribute("On") ~= true then autoIcon.Rotation = 0 end
			end)
		end
		local breath = 1 + (math.sin(t * 2.5) + 1) / 2 * 0.04 -- 100% -> 104% -> 100%
		A.scale.Scale = breath * A.hover.Value * A.press.Value
	end
	updateAura(A, t, 1.3, on and 0.05 or 0)

	-- hide
	H.scale.Scale = H.hover.Value * H.press.Value
	updateAura(H, t, 2.6)
	UP.scale.Scale = UP.hover.Value * UP.press.Value
	updateAura(UP, t, 3.9)
end)

--------------------------------------------------
-- Third slot: UPGRADES when idle, HIDE ROLL while rolling
--------------------------------------------------
local rootGui = script.Parent
local function swap()
	-- HIDE ROLL only while the big reel is on screen; minimized = Upgrades is available
	local rolling = (rootGui:GetAttribute("Rolling") == true or auto:GetAttribute("On") == true)
		and rootGui:GetAttribute("RollMinimized") ~= true
	local show, gone = (rolling and hide or upgradesB), (rolling and upgradesB or hide)
	if show.Visible and not gone.Visible then return end
	gone.Visible = false
	show.Visible = true
	local st = buttons[show]
	st.press.Value = 0.6
	tween(st.press, 0.35, {Value = 1}, Enum.EasingStyle.Back)
end
rootGui:GetAttributeChangedSignal("Rolling"):Connect(swap)
auto:GetAttributeChangedSignal("On"):Connect(swap)
rootGui:GetAttributeChangedSignal("RollMinimized"):Connect(swap)
swap()
