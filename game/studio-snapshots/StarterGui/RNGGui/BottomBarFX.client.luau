-- BottomBarFX: preserve upgrade-button hover, bounce, icy sparks and aura.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local bar = script.Parent:WaitForChild("BottomBar")
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


local upgrades = bar:WaitForChild("UpgradesButton")
local UP = setup(upgrades, 1.08)
upgrades.Visible = true
local function updateAura(st, t)
    local pulse = (math.sin(t * 2.2) + 1) / 2
    local g = st.glow.Value
    if st.auraScale then st.auraScale.Scale = 1 + pulse * 0.04 + g * 0.08 end
    for _, ring in ipairs(st.aura:GetChildren()) do
        if ring:IsA("Frame") then
            ring.BackgroundTransparency = math.clamp((ring:GetAttribute("BaseT") or 0.85) - pulse * 0.05 - g * 0.12, 0, 1)
        end
    end
end
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


RunService.RenderStepped:Connect(function()
    if not upgrades.Visible then return end
    UP.scale.Scale = UP.hover.Value * UP.press.Value
    updateAura(UP, os.clock())
end)
