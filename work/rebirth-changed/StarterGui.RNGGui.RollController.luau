-- RollController: vertical reel, full / minimized modes, auto-roll.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("RNGConfig"))
local ItemIcon = require(ReplicatedStorage:WaitForChild("ItemIcon"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local remote = ReplicatedStorage:WaitForChild("RollRNG")
local Cutscene = require(script.Parent:WaitForChild("RareDropCutscene"))

local gui = script.Parent
local stage = gui:WaitForChild("RollStage")
local aspect = stage:WaitForChild("Aspect")
local slotsFrame = stage:WaitForChild("Slots")
local glow = stage:WaitForChild("Glow")
local glowScale = glow:WaitForChild("UIScale")
local rays = stage:WaitForChild("Rays")
local pointerL, pointerR = stage:WaitForChild("PointerL"), stage:WaitForChild("PointerR")
local dim = gui:WaitForChild("RollDim")
local rollFinished = gui:WaitForChild("RollFinished")
local bottom = gui:WaitForChild("BottomBar")
local rollB, autoB, hideB = bottom:WaitForChild("RollButton"), bottom:WaitForChild("AutoButton"), bottom:WaitForChild("HideButton")

local FONT = Enum.Font.FredokaOne
local BLACK = Color3.fromRGB(10, 10, 12)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(90, 255, 90)
local FADED = Color3.fromRGB(80, 80, 92)

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

--------------------------------------------------
-- MODES
--------------------------------------------------
local MODES = {
	full = {anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromScale(0.5, 0.45), size = UDim2.fromScale(0.6, 0.78),
		aspect = 0.5, slot = 0.2, range = 3},
	mini = {anchor = Vector2.new(0.5, 0), pos = UDim2.fromScale(0.5, 0.01), size = UDim2.fromScale(0.3, 0.27),
		aspect = 0.8, slot = 1 / 3.1, range = 1},
}
local minimized = false
local mode = MODES.full

local blur = Instance.new("BlurEffect")
blur.Name = "RollBlur"
blur.Size = 0
blur.Parent = workspace.CurrentCamera

local function updateBackdrop(instant)
	local on = stage.Visible and not minimized
	local t = instant and 0 or 0.25
	tween(blur, t, {Size = on and 22 or 0})
	tween(dim, t, {BackgroundTransparency = on and 0.5 or 1})
end

local function applyMode()
	mode = minimized and MODES.mini or MODES.full
	stage.AnchorPoint = mode.anchor
	stage.Position = mode.pos
	stage.Size = mode.size
	aspect.AspectRatio = mode.aspect
	glow.Size = UDim2.fromScale(1, mode.slot * 1.7)
	rays.Size = UDim2.fromScale(1, mode.slot * 2.6)
	for _, p in ipairs({pointerL, pointerR}) do p.Size = UDim2.fromScale(0.14, mode.slot * 0.42) end
	updateBackdrop(true)
end

--------------------------------------------------
-- REEL (7 recycled slots; slot for absolute index j = slots[j % 7])
--------------------------------------------------
local NSLOTS = 7
local slots = {}
local seq = {}

local function label(parent, props, st)
	local l = Instance.new("TextLabel")
	l.Font = FONT; l.TextScaled = true; l.TextColor3 = WHITE; l.BackgroundTransparency = 1; l.Text = ""
	for k, v in pairs(props) do l[k] = v end
	local s = Instance.new("UIStroke"); s.Thickness = st; s.Color = BLACK; s.LineJoinMode = Enum.LineJoinMode.Round; s.Parent = l
	l.Parent = parent
	return l
end

for i = 1, NSLOTS do
	local cg = Instance.new("CanvasGroup")
	cg.Name = "Slot" .. i
	cg.BackgroundTransparency = 1
	cg.AnchorPoint = Vector2.new(0.5, 0.5)
	cg.Visible = false
	local sc = Instance.new("UIScale"); sc.Parent = cg
	local odds = label(cg, {Name = "Odds", Position = UDim2.fromScale(0.25, 0.03), Size = UDim2.fromScale(0.5, 0.2), TextColor3 = GREEN}, 3)
	local holder = Instance.new("Frame")
	holder.Name = "IconHolder"; holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5); holder.Position = UDim2.fromScale(0.5, 0.48); holder.Size = UDim2.fromScale(0.6, 0.5)
	holder.Parent = cg
	local name = label(cg, {Name = "ItemName", Position = UDim2.fromScale(0.04, 0.73), Size = UDim2.fromScale(0.92, 0.25)}, 4)
	cg.Parent = slotsFrame
	slots[i] = {cg = cg, scale = sc, odds = odds, holder = holder, name = name, item = nil, pop = 1}
end

-- visual filler items: common ones appear more often, like the real odds
local weightTotal = 0
for _, it in ipairs(Config.Items) do weightTotal += 1 / it.Chance end
local function randomItem()
	local n = math.random() * weightTotal
	for _, it in ipairs(Config.Items) do
		n -= 1 / it.Chance
		if n <= 0 then return it end
	end
	return Config.Items[1]
end
local function itemAt(j)
	if not seq[j] then seq[j] = randomItem() end
	return seq[j]
end

local function setItem(s, item)
	s.item = item
	s.odds.Text = "1 in " .. NumberFormat.Abbreviate(item.Chance)
	s.name.Text = string.upper(item.Name)
	s.holder:ClearAllChildren()
	ItemIcon.create(item).Parent = s.holder
end

local posValue = Instance.new("NumberValue")
posValue.Value = 0
local lastPos, speed = 0, 0

local function render()
	local pos = posValue.Value
	local base = math.floor(pos + 0.5)
	local range = mode.range
	local used = {}
	local motion = math.clamp(speed / 35, 0, 1)
	for j = base - range, base + range do
		local s = slots[(j % NSLOTS) + 1]
		used[s] = true
		local item = itemAt(j)
		if s.item ~= item then setItem(s, item) end
		local d = j - pos
		local ad = math.abs(d)
		s.cg.Visible = true
		s.cg.Size = UDim2.fromScale(1, mode.slot)
		s.cg.Position = UDim2.fromScale(0.5, 0.5 + d * mode.slot)
		-- fade + darken with distance, extra transparency when moving fast (motion blur feel)
		local fade = math.clamp(ad / (range + 0.5), 0, 1)
		s.cg.GroupTransparency = math.clamp(fade * 0.92 + motion * (ad < 0.5 and 0.25 or 0.45), 0, 1)
		s.cg.GroupColor3 = WHITE:Lerp(FADED, math.clamp(ad * 1.2, 0, 1))
		s.scale.Scale = (1 - math.min(ad, 2) * 0.17) * s.pop
	end
	for _, s in ipairs(slots) do
		if not used[s] then s.cg.Visible = false end
	end
end

RunService.RenderStepped:Connect(function(dt)
	local p = posValue.Value
	speed = math.abs(p - lastPos) / math.max(dt, 1e-3)
	lastPos = p
	rays.Rotation = (rays.Rotation + dt * 20) % 360
	if stage.Visible then render() end
end)

--------------------------------------------------
-- ROLL
--------------------------------------------------
local rolling, rollId, lastFire = false, 0, 0
local waiting
remote.OnClientEvent:Connect(function(result, counts, equipped, luck)
	if waiting then waiting(result, counts, equipped, luck) end
end)

local camera = workspace.CurrentCamera
local punching = false
local function fovPunch()
	if punching then return end
	punching = true
	local base = camera.FieldOfView
	tween(camera, 0.08, {FieldOfView = base - 6}).Completed:Wait()
	tween(camera, 0.35, {FieldOfView = base}, Enum.EasingStyle.Back).Completed:Wait()
	punching = false
end

local function showStage()
	gui:SetAttribute("Rolling", true)
	if not stage.Visible then
		stage.Visible = true
		render()
		updateBackdrop()
	end
end
local function hideStage()
	gui:SetAttribute("Rolling", false)
	stage.Visible = false
	updateBackdrop()
end

local function doRoll()
	if rolling or gui:GetAttribute("RebirthMenuOpen") then return end
	rolling = true
	rollId += 1
	local myId = rollId

	local animScale = game.Players.LocalPlayer:GetAttribute("RollAnimScale") or 1
	local gap = (Config.RollCooldown * animScale + 0.1) - (os.clock() - lastFire)
	if gap > 0 then task.wait(gap) end

	local result, counts, equipped, luck
	waiting = function(r, c, e, l) result, counts, equipped, luck = r, c, e, l end
	lastFire = os.clock()
	remote:FireServer()

	showStage()
	tween(rays, 0.2, {GroupTransparency = 0.55})
	tween(glowScale, 0.2, {Scale = 1})

	-- creep the reel while the server answers
	local t0 = os.clock()
	while result == nil and os.clock() - t0 < 3 do
		posValue.Value += 0.15
		task.wait()
	end
	waiting = nil
	if not result then
		rolling = false
		hideStage()
		return
	end

	local fast = gui:GetAttribute("FastRolls")
	local base = math.floor(posValue.Value + 0.5)
	local dist = fast and 8 or (26 + math.random(0, 6))
	local target = base + dist
	for j = base + 1, target + 4 do seq[j] = randomItem() end
	seq[target] = Config.ByName[result] or Config.Items[1]
	for j in pairs(seq) do
		if j < base - 10 then seq[j] = nil end -- keep memory tiny
	end

	-- decelerate, overshoot a touch, settle back onto the winner
	local wonItem = Config.ByName[result]
	if Cutscene.ShouldPlay(wonItem, luck) then
		-- RARE: reel starts, then the screen cuts to black for the cutscene
		local tw = tween(posValue, 3.1, {Value = target + 0.22}, Enum.EasingStyle.Quint)
		task.wait(0.9)
		Cutscene.Play(wonItem, luck)
		tw:Cancel()
		posValue.Value = target
	else
		tween(posValue, fast and 0.7 or 3.1 * animScale, {Value = target + 0.22}, Enum.EasingStyle.Quint).Completed:Wait()
		tween(posValue, 0.35, {Value = target}, Enum.EasingStyle.Back).Completed:Wait()
	end

	-- winner!
	local win = slots[(target % NSLOTS) + 1]
	local popV = Instance.new("NumberValue")
	popV.Value = 1.3
	popV.Changed:Connect(function(v) win.pop = v end)
	win.pop = 1.3
	tween(popV, 0.4, {Value = 1}, Enum.EasingStyle.Back).Completed:Connect(function() popV:Destroy(); win.pop = 1 end)
	glowScale.Scale = 1.5
	tween(glowScale, 0.5, {Scale = 1.2}, Enum.EasingStyle.Back)
	rays.GroupTransparency = 0
	tween(rays, 1.2, {GroupTransparency = 0.3})
	if (Config.ByName[result] and Config.ByName[result].Chance or 0) >= Config.BigRollAt then
		task.spawn(fovPunch)
	end

	rollFinished:Fire(result, counts, equipped)
	rolling = false

	task.delay(1.8, function()
		if rollId == myId and not rolling then hideStage() end
	end)
end

--------------------------------------------------
-- BUTTONS
--------------------------------------------------
local function bounce(btn)
	local s = btn:FindFirstChildOfClass("UIScale")
	if not s then return end
	btn.MouseEnter:Connect(function() tween(s, 0.12, {Scale = 1.1}) end)
	btn.MouseLeave:Connect(function() tween(s, 0.12, {Scale = 1}) end)
	btn.MouseButton1Down:Connect(function() tween(s, 0.08, {Scale = 0.88}) end)
	btn.MouseButton1Up:Connect(function() tween(s, 0.25, {Scale = 1.1}, Enum.EasingStyle.Back) end)
end
-- hover/click/idle visuals for these buttons live in BottomBarFX

rollB.Activated:Connect(function() task.spawn(doRoll) end)

local auto = false
local autoLabel = autoB:WaitForChild("Label")
autoB.Activated:Connect(function()
	auto = not auto
	autoB:SetAttribute("On", auto)
	autoLabel.Text = auto and 'AUTO-ROLL <font color="#5AFF5A">ON</font>' or "AUTO-ROLL OFF"
	if auto then
		task.spawn(function()
			while auto do
				doRoll()
				task.wait(0.7 * (game.Players.LocalPlayer:GetAttribute("RollAnimScale") or 1))
			end
		end)
	end
end)

local hideLabel = hideB:WaitForChild("Label")

-- tapping the minimized reel at the top brings the full roll back
local expandHit = Instance.new("TextButton")
expandHit.Name = "ExpandHit"
expandHit.Text = ""
expandHit.BackgroundTransparency = 1
expandHit.Size = UDim2.fromScale(1, 1)
expandHit.ZIndex = 20
expandHit.Visible = false
expandHit.Parent = stage
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(0.5, 0)
hint.Position = UDim2.fromScale(0.5, 1.01)
hint.Size = UDim2.fromScale(0.9, 0.13)
hint.Font = FONT
hint.TextScaled = true
hint.Text = "▼ tap to show"
hint.TextColor3 = Color3.fromRGB(220, 235, 255)
hint.ZIndex = 20
local hs = Instance.new("UIStroke"); hs.Thickness = 2; hs.Color = BLACK; hs.Parent = hint
hint.Parent = expandHit

local function setMinimized(v)
	minimized = v
	hideLabel.Text = minimized and "SHOW ROLL" or "HIDE ROLL"
	expandHit.Visible = minimized
	gui:SetAttribute("RollMinimized", minimized)
	applyMode()
end
hideB.Activated:Connect(function() setMinimized(not minimized) end)
expandHit.Activated:Connect(function() setMinimized(false) end)

applyMode()

-- STUDIO ONLY: press P to preview the rare-drop cutscene with a random rare shovel
if RunService:IsStudio() then
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.P or Cutscene.IsPlaying() then return end
		local pool = {}
		for _, it in ipairs(Config.Items) do
			if Cutscene.ShouldPlay(it, 1) then table.insert(pool, it) end
		end
		if #pool > 0 then task.spawn(Cutscene.Play, pool[math.random(#pool)], 1) end
	end)
end

-- DOUBLE ROLL: little banner when the upgrade gives a bonus shovel
do
	local toast = Instance.new("TextLabel")
	toast.Name = "DoubleRollToast"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.fromScale(0.5, 0.14)
	toast.Size = UDim2.fromScale(0.45, 0.06)
	toast.BackgroundTransparency = 1
	toast.Font = Enum.Font.FredokaOne
	toast.TextScaled = true
	toast.TextColor3 = Color3.fromRGB(255, 215, 80)
	toast.TextTransparency = 1
	toast.ZIndex = 30
	local st = Instance.new("UIStroke"); st.Thickness = 3; st.Transparency = 1; st.Parent = toast
	toast.Parent = gui
	remote.OnClientEvent:Connect(function(_, _, _, _, extra)
		if not extra then return end
		task.delay(3.4 * (game.Players.LocalPlayer:GetAttribute("RollAnimScale") or 1), function()
			toast.Text = "🎲 DOUBLE ROLL!  +" .. extra
			toast.TextTransparency = 0; st.Transparency = 0
			task.wait(2)
			tween(toast, 0.4, {TextTransparency = 1})
			tween(st, 0.4, {Transparency = 1})
		end)
	end)
end

