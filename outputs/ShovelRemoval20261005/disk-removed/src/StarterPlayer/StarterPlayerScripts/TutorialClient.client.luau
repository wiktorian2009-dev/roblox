-- TutorialClient: first-time tutorial (white text on a smooth dark box + gliding arrows).
-- Starts once per player after the intro. Set the player attribute "IntroPlaying" = true while an intro plays.
if require(game:GetService("ReplicatedStorage"):WaitForChild("PlowConfig")).Mode == "Snowplow" then return end -- 2026-10-04 (Claude): snowplows replace the old tutorial (see PlowTutorialClient) (set PlowConfig.Mode = "Legacy" to restore it)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local setSetting = ReplicatedStorage:WaitForChild("SetSetting")
local pg = player:WaitForChild("PlayerGui")
local rngGui = pg:WaitForChild("RNGGui")
local camera = workspace.CurrentCamera

local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

--------------------------------------------------
-- UI
--------------------------------------------------
local sg = mk("ScreenGui", {Name = "Tutorial", ResetOnSpawn = false, DisplayOrder = 45, IgnoreGuiInset = true, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)

-- message box
local box = mk("Frame", {Name = "Box", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 5}, sg)
mk("UICorner", {CornerRadius = UDim.new(0, 18)}, box)
mk("UIPadding", {PaddingLeft = UDim.new(0, 26), PaddingRight = UDim.new(0, 26), PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14)}, box)
local boxScale = mk("UIScale", {Scale = 1}, box)
local label = mk("TextLabel", {Name = "Text", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
	Font = FONT, TextColor3 = WHITE, TextSize = 28, Text = "", RichText = true, ZIndex = 6}, box)
-- 2026-10-04 (Claude): a clean pill. The automatic frost overlay used to cover the lower half of the label ("Skip" looked like "SKID").
local skip = mk("TextButton", {Name = "Skip", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 12), Size = UDim2.fromOffset(104, 38),
	BackgroundColor3 = WHITE, BackgroundTransparency = 0, AutoButtonColor = true, Font = FONT, TextSize = 20, TextColor3 = Color3.fromRGB(25, 45, 90),
	Text = "SKIP", ZIndex = 6}, box)
skip:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, skip)
mk("UIStroke", {Thickness = 3, Color = Color3.fromRGB(25, 45, 90), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, skip)
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(190, 218, 248))}, skip)

-- scale text with the screen
local function fitText()
	label.TextSize = math.clamp(math.floor(camera.ViewportSize.Y * 0.032), 18, 34)
	skip.Size = UDim2.fromOffset(math.max(96, math.floor(label.TextSize * 3.3)), math.max(36, math.floor(label.TextSize * 1.25)))
	skip.TextSize = math.max(18, math.floor(label.TextSize * 0.7))
end
fitText()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitText)

-- smooth arrow (rounded shaft + chevron head); the arrow's TIP is at the centre of its frame
local function makeArrow(parent, len, thick)
	local a = mk("Frame", {Name = "Arrow", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(len * 2, len * 2), ZIndex = 7}, parent)
	local function bar(x, y, w, rot, color, z, tr)
		local b = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, thick),
			Rotation = rot, BackgroundColor3 = color, BackgroundTransparency = tr or 0, BorderSizePixel = 0, ZIndex = z}, a)
		mk("UICorner", {CornerRadius = UDim.new(1, 0)}, b)
	end
	local head = len * 0.45
	local ang = math.rad(40)
	for _, layer in ipairs({{3, Color3.new(0, 0, 0), 7, 0.6}, {0, WHITE, 8, 0}}) do -- soft shadow, then white
		local o, col, z, tr = layer[1], layer[2], layer[3], layer[4]
		bar(len - len * 0.45 + o, len + o, len * 0.9, 0, col, z, tr)
		bar(len - head / 2 * math.cos(ang) + o, len - head / 2 * math.sin(ang) + o, head, 40, col, z, tr)
		bar(len - head / 2 * math.cos(ang) + o, len + head / 2 * math.sin(ang) + o, head, -40, col, z, tr)
	end
	return a
end
local uiArrow = makeArrow(sg, 60, 12)
uiArrow.Visible = false

-- world arrow (floating over a place) + glowing trail from the player
local worldPart = mk("Part", {Name = "TutorialTarget", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1,
	Size = Vector3.new(1, 1, 1)}, nil)
local worldAtt = mk("Attachment", {}, worldPart)
-- 2026-10-04 (Claude): AlwaysOnTop billboards never render in this place
local bb = mk("BillboardGui", {Name = "WorldArrow", Size = UDim2.fromOffset(160, 160), AlwaysOnTop = false, LightInfluence = 0,
	StudsOffsetWorldSpace = Vector3.new(0, 9, 0)}, worldPart)
local worldArrow = makeArrow(bb, 45, 11)
worldArrow.Position = UDim2.fromScale(0.5, 0.75)
worldArrow.Rotation = 90 -- pointing down
local beam = mk("Beam", {FaceCamera = true, Width0 = 1.4, Width1 = 1.4, LightEmission = 1, LightInfluence = 0, Segments = 20,
	Color = ColorSequence.new(Color3.fromRGB(160, 230, 255)), Transparency = NumberSequence.new(0.35), Attachment1 = worldAtt, Enabled = false}, worldPart)

--------------------------------------------------
-- helpers
--------------------------------------------------
local target -- GuiObject the UI arrow points at
local worldOn = false
local t0 = 0

local function say(text)
	label.Text = text
	boxScale.Scale = 0.85
	tween(boxScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
end
local function pointAt(gui)
	target = gui
	uiArrow.Visible = gui ~= nil
end
local function pointWorld(pos)
	if pos then
		worldPart.Position = pos
		worldPart.Parent = workspace
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local a0 = hrp:FindFirstChild("TutorialAtt") or mk("Attachment", {Name = "TutorialAtt", Position = Vector3.new(0, -2.5, 0)}, hrp)
			beam.Attachment0 = a0
			beam.Enabled = true
		end
		worldOn = true
	else
		worldPart.Parent = nil
		beam.Enabled = false
		worldOn = false
	end
end

RunService.RenderStepped:Connect(function()
	if not sg.Enabled then return end
	t0 += 1 / 60
	-- UI arrow glides next to its target and bounces toward it
	if target and target.Parent and target.Visible and target.AbsoluteSize.Magnitude > 0 then
		uiArrow.Visible = true
		local c = target.AbsolutePosition + target.AbsoluteSize / 2 + Vector2.new(0, game:GetService("GuiService"):GetGuiInset().Y)
		local screen = camera.ViewportSize / 2
		local dir = (screen - c)
		dir = dir.Magnitude > 1 and dir.Unit or Vector2.new(0, -1)
		local r = math.max(target.AbsoluteSize.X, target.AbsoluteSize.Y) / 2 + 12
		local bounce = (math.sin(t0 * 6) + 1) * 7
		local tip = c + dir * (r + bounce)
		local goal = UDim2.fromOffset(tip.X, tip.Y)
		uiArrow.Position = uiArrow.Position:Lerp(goal, 0.25)
		uiArrow.Rotation = math.deg(math.atan2(-dir.Y, -dir.X))
	elseif target then
		uiArrow.Visible = false
	end
	if worldOn then
		worldArrow.Position = UDim2.new(0.5, 0, 0.75, -math.abs(math.sin(t0 * 5)) * 18)
		beam.Transparency = NumberSequence.new(0.3 + (math.sin(t0 * 4) + 1) * 0.15)
	end
end)

--------------------------------------------------
-- STEPS
--------------------------------------------------
local running = false
local cancelled = false

local function waitUntil(fn)
	while not fn() do
		if cancelled then return false end
		task.wait(0.1)
	end
	return not cancelled
end

local function finish()
	pointAt(nil)
	pointWorld(nil)
	tween(box, 0.3, {BackgroundTransparency = 1})
	tween(label, 0.3, {TextTransparency = 1})
	task.wait(0.3)
	sg.Enabled = false
	box.BackgroundTransparency = 0.35
	label.TextTransparency = 0
	running = false
	player:SetAttribute("TutorialDone", true)
	setSetting:FireServer("TutorialDone", true)
end

local function run()
	if running then return end
	running = true
	cancelled = false
	-- Wait for startup too: IntroPlaying is still nil while the avatar loads.
	local intro = player.PlayerScripts:FindFirstChild("SnowIntro")
	if intro and intro.Enabled then
		if not waitUntil(function() return player:GetAttribute("IntroReady") == true end) then return end
	end
	if not waitUntil(function() return player:GetAttribute("IntroPlaying") ~= true end) then return end
	task.wait(1)
	if not waitUntil(function() return player:GetAttribute("IntroPlaying") ~= true end) then return end
	sg.Enabled = true

	local bottom = rngGui:WaitForChild("BottomBar")
	local rollB = bottom:WaitForChild("RollButton")
	local upB = bottom:WaitForChild("UpgradesButton")

	-- 1) roll
	say("Your "..(player:GetAttribute("StarterShovelName") or "Tin Shovel").." is ready!\nTap the dice to roll another shovel!")
	pointAt(rollB)
	local rolled = false
	local conn = rngGui:WaitForChild("RollFinished").Event:Connect(function() rolled = true end)
	if not waitUntil(function() return rolled end) then conn:Disconnect() return end
	conn:Disconnect()

	-- 2) the spinner
	pointAt(nil)
	say("Nice! Your shovel spins around you ❄")
	task.wait(2.8)
	if cancelled then return end

	-- 3) dig in the snow field
	local SF = require(ReplicatedStorage:WaitForChild("SnowFields"))
	local field
	for _, f in ipairs(SF.Fields) do if f.Id == "FrostfallSnowYard" then field = f break end end
	if not field then
		for _, f in ipairs(SF.Fields) do if f.Id == "Starter" or f.Style == "Starter" then field = f break end end
	end
	local snow = player:WaitForChild("leaderstats"):WaitForChild("Snow")
	local start = snow.Value
	local GOAL = 10
	if field then pointWorld(field.Center + Vector3.new(0, 1, 0)) end
	local function progress() return math.clamp(snow.Value - start, 0, GOAL) end
	say("Walk into the snow to dig!  0/" .. GOAL .. " ❄")
	local c2 = snow.Changed:Connect(function()
		label.Text = "Walk into the snow to dig!  " .. progress() .. "/" .. GOAL .. " ❄"
	end)
	if not waitUntil(function() return progress() >= GOAL end) then c2:Disconnect() return end
	c2:Disconnect()
	pointWorld(nil)

	-- 4) upgrades
	say("Great! Spend snow on upgrades!")
	pointAt(upB)
	local tree = pg:WaitForChild("UpgradeTreeGui", 30)
	if not waitUntil(function() return tree and tree.Enabled end) then return end
	pointAt(nil)

	-- 5) done
	say("Roll rarer shovels and unlock new areas.\nHave fun!")
	task.wait(3.2)
	finish()
end

skip.Activated:Connect(function()
	cancelled = true
	finish()
end)

local function check()
	if player:GetAttribute("TutorialDone") == false and not running then task.spawn(run) end
end
player:GetAttributeChangedSignal("TutorialDone"):Connect(check)
check()

