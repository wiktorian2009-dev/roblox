-- RareDropCutscene: black screen -> rarity climbs tier by tier (bass hit + shake each step) -> white flash -> shovel reveal.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("RNGConfig"))
local ItemIcon = require(ReplicatedStorage:WaitForChild("ItemIcon"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer

local Cutscene = {}
local FONT = Enum.Font.FredokaOne
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local ORDER = Config.RarityOrder
local TIER = {}
for i, n in ipairs(ORDER) do TIER[n] = i end

local function tierForChance(c)
	local best = 1
	for i, n in ipairs(ORDER) do
		if c >= (Config.RarityMinChance[n] or 0) then best = i end
	end
	return best
end

function Cutscene.ShouldPlay(item, luck)
	return item ~= nil and item.Chance / math.max(luck or 1, 1) >= Config.RareDrop.Threshold
end

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
-- UI (built once)
--------------------------------------------------
-- 2026-10-04 (Claude): DisplayOrder 200 = above the Upgrades page (150) and its roll overlay (151), so a rare drop is seen while you roll there
local sg = mk("ScreenGui", {Name = "RareDropGui", DisplayOrder = 200, IgnoreGuiInset = true, ResetOnSpawn = false, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, nil)
local bg = mk("Frame", {Name = "Black", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0}, sg)

-- light rays (reveal)
local rays = mk("CanvasGroup", {Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromScale(1.3, 1.3), BackgroundTransparency = 1, GroupTransparency = 1}, sg)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, rays)
for i = 0, 11 do
	local r = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.07, 1),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Rotation = i * 15}, rays)
	mk("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)})}, r)
end
local raysTint = mk("UIGradient", {Color = ColorSequence.new(WHITE)}, rays)

-- shockwave ring
local ring = mk("Frame", {Name = "Ring", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.1, 0.1),
	BackgroundTransparency = 1}, sg)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, ring)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, ring)
local ringStroke = mk("UIStroke", {Thickness = 10, Color = WHITE, Transparency = 1}, ring)

-- tier text
local tierLabel = mk("TextLabel", {Name = "Tier", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.8, 0.2),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = WHITE, TextTransparency = 1}, sg)
local tierStroke = mk("UIStroke", {Thickness = 6, Color = BLACK, Transparency = 1}, tierLabel)
local tierScale = mk("UIScale", {Scale = 1}, tierLabel)
local oddsLabel = mk("TextLabel", {Name = "Odds", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.57), Size = UDim2.fromScale(0.4, 0.07),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = Color3.fromRGB(110, 255, 110), TextTransparency = 1}, sg)
local oddsStroke = mk("UIStroke", {Thickness = 4, Color = BLACK, Transparency = 1}, oddsLabel)

-- reveal
local iconHolder = mk("Frame", {Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(0.45, 0.45),
	BackgroundTransparency = 1, Visible = false}, sg)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, iconHolder)
local iconScale = mk("UIScale", {Scale = 1}, iconHolder)
local nameLabel = mk("TextLabel", {Name = "ItemName", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.7, 0.1),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = WHITE, TextTransparency = 1}, sg)
local nameStroke = mk("UIStroke", {Thickness = 5, Color = BLACK, Transparency = 1}, nameLabel)
local subLabel = mk("TextLabel", {Name = "Sub", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.81), Size = UDim2.fromScale(0.5, 0.055),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = WHITE, TextTransparency = 1}, sg)
local subStroke = mk("UIStroke", {Thickness = 3, Color = BLACK, Transparency = 1}, subLabel)

local flash = mk("Frame", {Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10}, sg)

local blur = Instance.new("BlurEffect")
blur.Name = "RareDropBlur"
blur.Size = 0
-- 2026-10-04 (Claude) remake: 3D shovel reveal, confetti, NEW badge, tap-to-skip
local UIS = game:GetService("UserInputService")
local templates = ReplicatedStorage:FindFirstChild("ShovelModels")
local confetti = mk("Frame", {Name = "Confetti", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6}, sg)
local newBadge = mk("TextLabel", {Name = "NewBadge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.16), Size = UDim2.fromScale(0.42, 0.075),
	BackgroundColor3 = Color3.fromRGB(255, 215, 60), BorderSizePixel = 0, Font = FONT, TextScaled = true, Text = "\u{2728} NEW DISCOVERY! \u{2728}", TextColor3 = Color3.fromRGB(60, 35, 10), Visible = false, ZIndex = 7}, sg)
newBadge:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, newBadge)
mk("UIStroke", {Thickness = 4, Color = Color3.fromRGB(120, 70, 10)}, newBadge)
local badgeScale = mk("UIScale", {Scale = 1}, newBadge)
local skipHint = mk("TextLabel", {Name = "SkipHint", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0.4, 0.04),
	BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "tap to continue", TextColor3 = WHITE, TextTransparency = 1, ZIndex = 7}, sg)
local skipStroke = mk("UIStroke", {Thickness = 2, Color = BLACK, Transparency = 1}, skipHint)
-- the real 3D shovel in a viewport (falls back to the 2D icon)
local function show3D(item)
	local t = templates and (templates:FindFirstChild(item.Base or item.Name) or templates:FindFirstChild(item.Name))
	if not t then ItemIcon.create(item).Parent = iconHolder return nil end
	local vp = mk("ViewportFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 170, 190), LightColor = WHITE, LightDirection = Vector3.new(-1, -1, -2)}, iconHolder)
	local m = t:Clone()
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("Highlight") then d:Destroy() end end
	m:PivotTo(CFrame.new())
	m.Parent = vp
	local cf, size = m:GetBoundingBox()
	local cam = mk("Camera", {FieldOfView = 35}, vp)
	local dist = math.max(size.X, size.Y, size.Z) * 1.7 + 0.5
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.1, dist), cf.Position)
	vp.CurrentCamera = cam
	return m, cf.Position
end
local function burstConfetti(color, n)
	local palette = {color, color:Lerp(WHITE, 0.5), Color3.fromRGB(255, 215, 90), WHITE, Color3.fromRGB(120, 220, 255)}
	for i = 1, n do
		local p = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(math.random(8, 16), math.random(10, 22)),
			BackgroundColor3 = palette[math.random(#palette)], BorderSizePixel = 0, Rotation = math.random(0, 360), ZIndex = 6}, confetti)
		p:SetAttribute("SnowUIDecor", true)
		local a = math.random() * 2 * math.pi
		local r = 0.25 + math.random() * 0.4
		local life = 1.1 + math.random() * 0.8
		tween(p, life, {Position = UDim2.fromScale(0.5 + math.cos(a) * r * 0.6, 0.45 + math.sin(a) * r + 0.25), Rotation = p.Rotation + math.random(-540, 540), BackgroundTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(life + 0.05, function() p:Destroy() end)
	end
end

-- 2026-10-04 (Claude) v3: rising odds counter + layers from the VFX pack (UniversalVFX textures)
local VFX = require(ReplicatedStorage:WaitForChild("UniversalVFX"))
local TX = VFX.Textures
local function sprite(name, tex, size, z, square)
	local i = mk("ImageLabel", {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(size, size),
		BackgroundTransparency = 1, Image = TX[tex], ImageTransparency = 1, ZIndex = z}, sg)
	i:SetAttribute("SnowUIDecor", true)
	if square ~= false then mk("UIAspectRatioConstraint", {AspectRatio = 1}, i) end
	return i
end
local glowSprite = sprite("Glow", "glow", 1.15, 2)
local rune = sprite("Rune", "rune-circle", 0.55, 3)
local shock = sprite("Shock", "shockwave", 0.2, 4)
local bolts = {}
for i = 1, 3 do bolts[i] = sprite("Bolt" .. i, "lightning", 0.3, 5) end
local streaks = {}
for i = 1, 14 do
	local s = sprite("Streak" .. i, "streak", 0.02, 3, false)
	s.Size = UDim2.fromScale(0.012, 0.12)
	streaks[i] = {img = s, a = (i / 14) * math.pi * 2 + math.random() * 0.2, o = math.random()}
end
-- stacking: background < glow < rune/streaks < rays < shock < bolts < confetti < shovel < text < badge < flash
rays.ZIndex = 3; ring.ZIndex = 4; confetti.ZIndex = 6; iconHolder.ZIndex = 7
tierLabel.ZIndex = 8; oddsLabel.ZIndex = 8; nameLabel.ZIndex = 8; subLabel.ZIndex = 8; skipHint.ZIndex = 8; newBadge.ZIndex = 9
-- layout for the counter: rarity name on top, the big number in the middle
tierLabel.Position, tierLabel.Size = UDim2.fromScale(0.5, 0.29), UDim2.fromScale(0.5, 0.085)
oddsLabel.AnchorPoint, oddsLabel.Position, oddsLabel.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.45), UDim2.fromScale(0.78, 0.16)
local counterScale = mk("UIScale", {Scale = 1}, oddsLabel)
local tickSound = mk("Sound", {Name = "CounterTick", SoundId = "rbxassetid://12221976", Volume = 0.55}, sg)
local function resetFx()
	for _, o in ipairs({glowSprite, rune, shock}) do o.ImageTransparency = 1 end
	for _, b in ipairs(bolts) do b.ImageTransparency = 1 end
	for _, s in ipairs(streaks) do s.img.ImageTransparency = 1 end
	rune.Size = UDim2.fromScale(0.5, 0.5)
end
local function shockSprite(color)
	shock.ImageColor3 = color:Lerp(WHITE, 0.3)
	shock.Size = UDim2.fromScale(0.15, 0.15)
	shock.ImageTransparency = 0.05
	tween(shock, 0.45, {Size = UDim2.fromScale(1.35, 1.35), ImageTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end
local function lightningFlash(color)
	for _, b in ipairs(bolts) do
		local a = math.random() * math.pi * 2
		b.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.17, 0.45 + math.sin(a) * 0.28)
		b.Rotation = math.deg(a) + 90 + math.random(-20, 20)
		b.ImageColor3 = color:Lerp(WHITE, 0.35)
		b.ImageTransparency = 0
		tween(b, 0.28, {ImageTransparency = 1})
	end
end
local function updateStreaks(now, p, color)
	for _, s in ipairs(streaks) do
		local c = (now * (0.9 + 2.6 * p) + s.o) % 1
		local r = 0.12 + c * 0.42
		s.img.Position = UDim2.fromScale(0.5 + math.cos(s.a) * r * 0.62, 0.45 + math.sin(s.a) * r)
		s.img.Rotation = math.deg(s.a) + 90
		s.img.Size = UDim2.fromScale(0.012, 0.08 + 0.12 * p)
		s.img.ImageColor3 = color:Lerp(WHITE, 0.45)
		s.img.ImageTransparency = math.clamp(0.35 + c * 0.65 - p * 0.15, 0, 1)
	end
end
local function hideStreaks() for _, s in ipairs(streaks) do tween(s.img, 0.2, {ImageTransparency = 1}) end end
local function starBurst(color, n)
	for i = 1, n do
		local st = sprite("Star", "star", 0.045 + math.random() * 0.04, 6)
		st.Parent = confetti
		st.ImageColor3 = color:Lerp(WHITE, math.random() * 0.6)
		st.ImageTransparency = 0
		local a = math.random() * math.pi * 2
		local r = 0.22 + math.random() * 0.3
		local life = 0.9 + math.random() * 0.7
		tween(st, life, {Position = UDim2.fromScale(0.5 + math.cos(a) * r * 0.62, 0.45 + math.sin(a) * r), Rotation = math.random(-200, 200), ImageTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(life + 0.05, function() st:Destroy() end)
	end
end

--------------------------------------------------
-- SOUND + SHAKE
--------------------------------------------------
-- cached Sound per id (so we know each file's real length for timing)
local cache = {}
local function soundFor(def)
	if not def or not def.Id or def.Id == "" then return nil end
	local s = cache[def.Id]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = def.Id
		s.Parent = sg
		cache[def.Id] = s
	end
	return s
end
local function lengthOf(def, fallback)
	local s = soundFor(def)
	if s and s.IsLoaded and s.TimeLength > 0 then return s.TimeLength / (def.Speed or 1) end
	return fallback or 0.8
end
local function playDef(def, volMul)
	local s = soundFor(def)
	if not s then return end
	s.PlaybackSpeed = def.Speed or 1
	s.Volume = (def.Volume or 1) * (volMul or 1)
	s.TimePosition = 0
	s:Play()
end
local function play(key, volMul) playDef(Config.RareDrop.Sounds[key], volMul) end
local function stepDef(tierName)
	local steps = Config.RareDrop.Sounds.Steps or {}
	return steps[tierName] or steps.Rare
end

-- preload everything when the player joins
task.spawn(function()
	local S = Config.RareDrop.Sounds
	local list = {}
	for _, key in ipairs({"Start", "Reveal", "End"}) do table.insert(list, soundFor(S[key])) end
	for _, def in pairs(S.Steps or {}) do table.insert(list, soundFor(def)) end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
end)

local shakeConn
local function shake(power, duration)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if shakeConn then shakeConn:Disconnect() end
	local t0 = os.clock()
	shakeConn = RunService.RenderStepped:Connect(function()
		local k = 1 - (os.clock() - t0) / duration
		if k <= 0 then
			hum.CameraOffset = Vector3.zero
			shakeConn:Disconnect()
			shakeConn = nil
			return
		end
		hum.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * power * k
	end)
end

local function shockwave(color, size)
	ring.Size = UDim2.fromScale(0.1, 0.1)
	ringStroke.Color = color
	ringStroke.Transparency = 0
	ringStroke.Thickness = 12
	tween(ring, 0.6, {Size = UDim2.fromScale(size, size)})
	tween(ringStroke, 0.6, {Transparency = 1, Thickness = 2})
end

--------------------------------------------------
-- PLAY (yields until finished)
--------------------------------------------------
local playing = false
function Cutscene.IsPlaying() return playing end

function Cutscene.Play(item, luck, isNew)
	if playing or not item then return end
	playing = true
	luck = math.max(luck or 1, 1)
	local S = Config.RareDrop.Sounds
	local itemTier = TIER[item.Rarity] or tierForChance(item.Chance)
	local finalColor = Config.Rarities[ORDER[itemTier]] or WHITE
	local skipped = false
	local skipConn = UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then skipped = true end
	end)
	player:SetAttribute("MusicDuck", true)
	sg.Parent = player:WaitForChild("PlayerGui")
	sg.Enabled = true
	blur.Parent = workspace.CurrentCamera
	newBadge.Visible = false
	skipHint.TextTransparency = 1; skipStroke.Transparency = 1
	resetFx()

	-- 1) dark screen + start sound
	bg.BackgroundColor3 = BLACK
	play("Start")
	tween(bg, 0.25, {BackgroundTransparency = 0})
	tween(blur, 0.25, {Size = 30})
	shake(0.4, 0.25)
	task.wait(math.min(lengthOf(S.Start, 1.1), 0.55))

	-- 2) THE COUNTER: "1 in N" races up to the real odds; each new rarity it passes = colour change, bass hit, shockwave, lightning
	local target = math.max(item.Chance, 2)
	local logT = math.log10(target)
	local duration = math.clamp(0.8 + logT * 0.27, 1.1, 3.6)
	tierLabel.Text, oddsLabel.Text = "", "1 in 1"
	tierLabel.TextTransparency, tierStroke.Transparency = 0, 0
	oddsLabel.TextTransparency, oddsStroke.Transparency = 0, 0
	oddsLabel.TextColor3 = WHITE
	rune.ImageTransparency, glowSprite.ImageTransparency = 0.35, 0.6
	local t0, prevT, nextTick, lastTier = os.clock(), os.clock(), 0, 0
	while true do
		local now = os.clock()
		local dt = now - prevT
		prevT = now
		local p = math.min((now - t0) / duration, 1)
		if skipped and now - t0 > 0.35 then p = 1 end
		local value = (p >= 1) and target or math.max(1, math.floor(10 ^ ((p ^ 1.3) * logT) + 0.5))
		oddsLabel.Text = "1 in " .. NumberFormat.Abbreviate(value)
		local ti = tierForChance(value)
		local color = Config.Rarities[ORDER[ti]] or WHITE
		if ti ~= lastTier then
			lastTier = ti
			tierLabel.Text = ORDER[ti]:upper()
			tierLabel.TextColor3 = color
			tierScale.Scale = 1.9
			tween(tierScale, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
			rune.ImageColor3, glowSprite.ImageColor3 = color, color
			bg.BackgroundColor3 = BLACK:Lerp(color, 0.16 + ti * 0.012)
			if ti > 1 then
				playDef(stepDef(ORDER[ti]), 0.8 + ti * 0.04)
				shockSprite(color)
				lightningFlash(color)
				shockwave(color, 0.7 + ti * 0.15)
				shake(0.25 + ti * 0.12, 0.3)
			end
		end
		if now >= nextTick then
			tickSound.PlaybackSpeed = 0.9 + p * 1.0
			tickSound:Play()
			nextTick = now + (0.11 - 0.08 * p)
			counterScale.Scale = 1.09
			tween(counterScale, 0.07, {Scale = 1})
		end
		rune.Rotation += dt * (35 + 380 * p)
		rune.Size = UDim2.fromScale(0.48 + 0.3 * p, 0.48 + 0.3 * p)
		glowSprite.ImageTransparency = math.clamp(0.7 - 0.35 * p + math.sin(now * 22) * 0.05, 0, 1)
		updateStreaks(now, p, color)
		if p >= 1 then break end
		task.wait()
	end
	-- slam on the real number
	oddsLabel.TextColor3 = finalColor:Lerp(WHITE, 0.25)
	counterScale.Scale = 1.7
	tween(counterScale, 0.3, {Scale = 1.15}, Enum.EasingStyle.Back)
	shockSprite(finalColor)
	lightningFlash(finalColor)
	shake(1.0, 0.35)
	hideStreaks()
	task.wait(skipped and 0.25 or 0.55)

	-- 3) white flash + reveal: the real 3D shovel spins inside the rune circle; confetti + stars
	play("Reveal")
	flash.BackgroundTransparency = 0
	tierLabel.TextTransparency = 1; tierStroke.Transparency = 1
	oddsLabel.TextTransparency = 1; oddsStroke.Transparency = 1
	bg.BackgroundColor3 = BLACK:Lerp(finalColor, 0.22)
	for _, c in ipairs(iconHolder:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local model, centre = show3D(item)
	iconHolder.Visible = true
	iconScale.Scale = 0.2
	raysTint.Color = ColorSequence.new(finalColor:Lerp(WHITE, 0.3))
	rays.GroupTransparency = 0.15
	rune.ImageColor3, rune.ImageTransparency = finalColor, 0.45
	tween(rune, 0.5, {Size = UDim2.fromScale(0.62, 0.62)}, Enum.EasingStyle.Back)
	glowSprite.ImageColor3, glowSprite.ImageTransparency = finalColor, 0.45
	nameLabel.Text = item.Name:upper()
	nameLabel.TextColor3 = WHITE
	subLabel.Text = ORDER[itemTier]:upper() .. "  \u{2022}  1 in " .. NumberFormat.Abbreviate(item.Chance)
	subLabel.TextColor3 = finalColor
	if isNew then
		newBadge.Visible = true
		badgeScale.Scale = 0.3
		tween(badgeScale, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
	end
	tween(flash, 0.7, {BackgroundTransparency = 1})
	tween(iconScale, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
	for _, o in ipairs({nameLabel, subLabel}) do tween(o, 0.35, {TextTransparency = 0}) end
	for _, o in ipairs({nameStroke, subStroke}) do tween(o, 0.35, {Transparency = 0}) end
	shake(1.4, 0.5)
	shockwave(finalColor, 2)
	shockSprite(finalColor)
	burstConfetti(finalColor, 46)
	starBurst(finalColor, 16)
	task.delay(0.9, function()
		if playing then tween(skipHint, 0.3, {TextTransparency = 0.25}); tween(skipStroke, 0.3, {Transparency = 0.25}) end
	end)
	skipped = false
	local hold = math.max(lengthOf(S.Reveal, 1.5) + 0.2, 1.9 + itemTier * 0.25)
	local h0, hprev, nextStars = os.clock(), os.clock(), os.clock() + 0.6
	while os.clock() - h0 < hold and not (skipped and os.clock() - h0 > 0.8) do
		local now = os.clock()
		local t, dt = now - h0, now - hprev
		hprev = now
		rays.Rotation = t * 25
		rune.Rotation += dt * 30
		iconHolder.Rotation = math.sin(t * 2) * 3
		glowSprite.ImageTransparency = 0.45 + math.sin(t * 3) * 0.08
		if model and centre then model:PivotTo(CFrame.new(centre) * CFrame.Angles(0, t * 1.5, 0) * CFrame.new(-centre)) end
		if now >= nextStars then nextStars = now + 0.5; starBurst(finalColor, 4) end
		task.wait()
	end
	skipConn:Disconnect()

	-- 4) out: fade, then a real 3D burst from the VFX pack around you in the world
	play("End")
	local out = math.max(lengthOf(S.End, 0.9), 0.35)
	for _, o in ipairs({nameLabel, subLabel, skipHint}) do tween(o, out * 0.6, {TextTransparency = 1}) end
	for _, o in ipairs({nameStroke, subStroke, skipStroke}) do tween(o, out * 0.6, {Transparency = 1}) end
	for _, o in ipairs({rune, glowSprite}) do tween(o, out * 0.6, {ImageTransparency = 1}) end
	tween(rays, out * 0.6, {GroupTransparency = 1})
	tween(iconScale, out * 0.6, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(bg, out, {BackgroundTransparency = 1})
	tween(blur, out, {Size = 0})
	task.delay(out * 0.5, function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			pcall(VFX.Burst, hrp, "PowerUp", {Color = finalColor, Scale = 1.3})
			pcall(VFX.Burst, hrp, "Impact", {Color = finalColor, Scale = 1.6, Offset = Vector3.new(0, -2.6, 0)})
		end
	end)
	task.wait(out)
	iconHolder.Visible = false
	newBadge.Visible = false
	sg.Enabled = false
	player:SetAttribute("MusicDuck", false)
	playing = false
end

return Cutscene
