-- RareAnnounceClient (2026-10-04, Claude): when anyone rolls a very rare shovel (RNGHandler fires RareRollAnnounce), everyone
-- gets a banner at the top, a chat line, and a rarity-coloured aura appears around the lucky player for 12 seconds.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local Config = require(RS:WaitForChild("RNGConfig"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local player = Players.LocalPlayer
local event = RS:WaitForChild("RareRollAnnounce")
local FONT, WHITE, NAVY = Enum.Font.FredokaOne, Color3.new(1, 1, 1), Color3.fromRGB(25, 45, 90)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local gui = mk("ScreenGui", {Name = "RareAnnounce", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 58}, player:WaitForChild("PlayerGui"))
local banner = mk("Frame", {Name = "Banner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.12), Size = UDim2.fromScale(0.6, 0.07),
	BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false}, gui)
banner:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, banner)
local stroke = mk("UIStroke", {Thickness = 3, Color = NAVY}, banner)
local grad = mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(240, 150, 30))}, banner)
local label = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = "", TextColor3 = WHITE,
	Position = UDim2.fromScale(0.03, 0.1), Size = UDim2.fromScale(0.94, 0.8), ZIndex = 2}, banner)
mk("UIStroke", {Thickness = 2.5, Color = NAVY}, label)
local revealId = (Config.RareDrop and Config.RareDrop.Sounds and Config.RareDrop.Sounds.Reveal and Config.RareDrop.Sounds.Reveal.Id) or "rbxassetid://125078105193243"
local shimmer = mk("Sound", {SoundId = revealId, Volume = 0.35}, gui)

local queue, showing = {}, false
local function showBanner(text, color)
	table.insert(queue, {text = text, color = color})
	if showing then return end
	showing = true
	task.spawn(function()
		while #queue > 0 do
			local e = table.remove(queue, 1)
			label.Text = e.text
			grad.Color = ColorSequence.new(e.color:Lerp(WHITE, 0.35), e.color)
			stroke.Color = e.color:Lerp(Color3.new(0, 0, 0), 0.5)
			banner.Position = UDim2.fromScale(0.5, -0.12)
			banner.Visible = true
			TweenService:Create(banner, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.235)}):Play()
			shimmer:Play()
			task.wait(4.5)
			TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, -0.12)}):Play()
			task.wait(0.4)
			banner.Visible = false
		end
		showing = false
	end)
end
local function chat(msg)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local ch = channels and channels:FindFirstChild("RBXGeneral")
		if ch then ch:DisplaySystemMessage(msg) end
	end)
	pcall(function() game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {Text = msg, Color = Color3.fromRGB(255, 220, 120), Font = Enum.Font.GothamBold}) end)
end
local VFX = require(RS:WaitForChild("UniversalVFX"))
local auras = {}
local function aura(plr, color, rarity)
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if auras[plr] then pcall(function() auras[plr]:Destroy() end) end
	-- rarer = flashier preset from the VFX pack
	local preset = (rarity == "Secret" or rarity == "Divine") and "ElectricAura" or ((rarity == "Legendary" or rarity == "Mythic") and "MagicAura" or "IceAura")
	local ok, h = pcall(VFX.Attach, hrp, preset, {Color = color, Scale = 1.1})
	if ok then auras[plr] = h end
	pcall(VFX.Burst, hrp, "PowerUp", {Color = color, Scale = 1.2})
	local l = mk("PointLight", {Name = "RareAuraLight", Color = color, Range = 12, Brightness = 1.4}, hrp)
	task.delay(12, function()
		if ok and auras[plr] == h then h:SetEnabled(false); task.delay(2, function() pcall(function() h:Destroy() end) end); auras[plr] = nil end
		if l.Parent then TweenService:Create(l, TweenInfo.new(2), {Brightness = 0}):Play(); task.delay(2, function() l:Destroy() end) end
	end)
end

event.OnClientEvent:Connect(function(name, itemName, chance)
	-- rank by the real odds (mutated shovels keep their base rarity name, but 1 in 24M is not just "Rare")
	local rarity = "Rare"
	for _, n in ipairs(Config.RarityOrder or {}) do
		if (tonumber(chance) or 0) >= ((Config.RarityMinChance and Config.RarityMinChance[n]) or 0) then rarity = n end
	end
	local color = Config.Rarities[rarity] or Color3.fromRGB(255, 215, 90)
	local text = ("\u{1F389} %s rolled a %s %s!  (1 in %s)"):format(tostring(name), rarity:upper(), tostring(itemName), NumberFormat.Abbreviate(tonumber(chance) or 0))
	chat(text)
	local who = Players:FindFirstChild(name)
	if who then aura(who, color, rarity) end
	-- the roller's own cutscene is playing: their banner comes a little later so it doesn't fight the reveal
	task.delay(name == player.Name and 4.5 or 0.6, function() showBanner(text, color) end)
end)
