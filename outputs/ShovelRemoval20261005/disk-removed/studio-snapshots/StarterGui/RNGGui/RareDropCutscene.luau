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
local sg = mk("ScreenGui", {Name = "RareDropGui", DisplayOrder = 100, IgnoreGuiInset = true, ResetOnSpawn = false, Enabled = false,
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

function Cutscene.Play(item, luck)
	if playing or not item then return end
	playing = true
	luck = math.max(luck or 1, 1)
	local S = Config.RareDrop.Sounds
	local itemTier = TIER[item.Rarity] or tierForChance(item.Chance)
	-- start the climb at the tier that is "rare for you" (higher luck = starts higher)
	local startTier = math.min(itemTier, tierForChance(Config.RareDrop.Threshold * luck))
	local steps = itemTier - startTier + 1
	local finalColor = Config.Rarities[ORDER[itemTier]] or WHITE

	player:SetAttribute("MusicDuck", true)
	sg.Parent = player:WaitForChild("PlayerGui")
	sg.Enabled = true
	blur.Parent = workspace.CurrentCamera
	bg.BackgroundColor3 = BLACK

	-- 1) black + start sound; the first step lands when the start sound ends
	play("Start")
	tween(bg, 0.3, {BackgroundTransparency = 0})
	tween(blur, 0.3, {Size = 30})
	task.wait(lengthOf(S.Start, 1.1))

	-- 2) the climb: each step lasts exactly as long as its own sound
	tierLabel.TextTransparency = 0
	tierStroke.Transparency = 0
	for k = 0, steps - 1 do
		local name = ORDER[startTier + k]
		local color = Config.Rarities[name] or WHITE
		local power = (k + 1) / steps
		local def = stepDef(name)
		local last = (k == steps - 1)
		playDef(def, 0.85 + power * 0.3)
		tierLabel.Text = name:upper()
		tierLabel.TextColor3 = color
		tierScale.Scale = 2.6 + power
		tween(tierScale, 0.35, {Scale = 1 + power * 0.35}, Enum.EasingStyle.Back)
		bg.BackgroundColor3 = BLACK:Lerp(color, 0.1 + 0.12 * power)
		tween(bg, 0.5, {BackgroundColor3 = BLACK:Lerp(color, 0.05 + 0.06 * power)})
		shake(0.2 + power * 0.9, 0.4 + power * 0.2)
		shockwave(color, 0.6 + power * 0.9)
		local len = lengthOf(def, 0.85)
		if last then
			-- odds tease appears during the last step; the flash hits when its sound ends
			local tease = math.min(0.35, len * 0.4)
			task.wait(tease)
			oddsLabel.Text = "1 in " .. NumberFormat.Abbreviate(item.Chance)
			tween(oddsLabel, 0.25, {TextTransparency = 0})
			tween(oddsStroke, 0.25, {Transparency = 0})
			task.wait(len - tease)
		else
			task.wait(len)
		end
	end

	-- 3) white flash + reveal sound + shovel
	play("Reveal")
	flash.BackgroundTransparency = 0
	tierLabel.TextTransparency = 1; tierStroke.Transparency = 1
	oddsLabel.TextTransparency = 1; oddsStroke.Transparency = 1
	bg.BackgroundColor3 = BLACK:Lerp(finalColor, 0.18)
	for _, c in ipairs(iconHolder:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	ItemIcon.create(item).Parent = iconHolder
	iconHolder.Visible = true
	iconScale.Scale = 0.2
	raysTint.Color = ColorSequence.new(finalColor:Lerp(WHITE, 0.3))
	rays.GroupTransparency = 0.15
	nameLabel.Text = item.Name:upper()
	nameLabel.TextColor3 = WHITE
	subLabel.Text = ORDER[itemTier]:upper() .. "  •  1 in " .. NumberFormat.Abbreviate(item.Chance)
	subLabel.TextColor3 = finalColor
	tween(flash, 0.9, {BackgroundTransparency = 1})
	tween(iconScale, 0.55, {Scale = 1}, Enum.EasingStyle.Back)
	for _, o in ipairs({nameLabel, subLabel}) do tween(o, 0.4, {TextTransparency = 0}) end
	for _, o in ipairs({nameStroke, subStroke}) do tween(o, 0.4, {Transparency = 0}) end
	shake(1.4, 0.6)
	shockwave(finalColor, 2)

	-- hold: at least the whole reveal sound, longer for rarer tiers
	local hold = math.max(lengthOf(S.Reveal, 1.5) + 0.4, 2.2 + itemTier * 0.35)
	local t0 = os.clock()
	while os.clock() - t0 < hold do
		local t = os.clock() - t0
		rays.Rotation = t * 25
		iconHolder.Rotation = math.sin(t * 2) * 4
		task.wait()
	end

	-- 4) out: the fade lasts as long as the end sound
	play("End")
	local out = math.max(lengthOf(S.End, 0.9), 0.35)
	for _, o in ipairs({nameLabel, subLabel}) do tween(o, out * 0.6, {TextTransparency = 1}) end
	for _, o in ipairs({nameStroke, subStroke}) do tween(o, out * 0.6, {Transparency = 1}) end
	tween(rays, out * 0.6, {GroupTransparency = 1})
	tween(iconScale, out * 0.6, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(bg, out, {BackgroundTransparency = 1})
	tween(blur, out, {Size = 0})
	task.wait(out)
	iconHolder.Visible = false
	sg.Enabled = false
	player:SetAttribute("MusicDuck", false)
	playing = false
end

return Cutscene
