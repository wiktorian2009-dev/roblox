-- PlowShopClient (2026-10-04, Claude; garage pedestals 2026-10-05): the offer card (BUY / RESERVE / REROLL), the build window and the GARAGE
-- teleport button. Offers are rolled on the pedestals of the garage place (PlowGarageClient); the server rolls them, sets prices and checks everything.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("PlowConfig"))
if C.Mode ~= "Snowplow" then return end
local Assembly = require(RS:WaitForChild("PlowAssembly"))
local Format = require(RS:WaitForChild("NumberFormat"))
local Api = require(RS:WaitForChild("PlowClientApi"))
local TX = require(RS:WaitForChild("UniversalVFX")).Textures
local remote, event = RS:WaitForChild("PlowRemote"), RS:WaitForChild("PlowEvent")
local pg = player:WaitForChild("PlayerGui")
local rng = pg:WaitForChild("RNGGui")
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({RS:WaitForChild("PlowParts")}) end) end) -- no blank previews on the first roll

local FONT = Enum.Font.FredokaOne
local WHITE, NAVY = Color3.new(1, 1, 1), Color3.fromRGB(20, 40, 85)
local GREEN, BLUE, ORANGE, GREY, ICE = Color3.fromRGB(70, 200, 105), Color3.fromRGB(70, 150, 245), Color3.fromRGB(250, 150, 50), Color3.fromRGB(130, 140, 165), Color3.fromRGB(150, 225, 255)
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function round(o, r) return mk("UICorner", {CornerRadius = UDim.new(r or 0.2, 0)}, o) end
local function outline(o, th, col) return mk("UIStroke", {Thickness = th or 2.5, Color = col or NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function text(parent, str, props, th)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, Text = str, TextColor3 = WHITE, TextScaled = true, Size = UDim2.fromScale(1, 1)}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	mk("UIStroke", {Thickness = th or 2, Color = NAVY}, l)
	return l
end
local function button(parent, str, color, props)
	local b = mk("TextButton", {Text = "", AutoButtonColor = true, BackgroundColor3 = color, BorderSizePixel = 0}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	b:SetAttribute("SnowUIDecor", true)
	round(b, 0.28); outline(b, 3)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 215, 235))}, b)
	text(b, str, {Name = "Label", Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76)}, 2.2)
	return b
end

local RANK, RCOL = {}, {}
for i, r in ipairs(C.Rarities) do RANK[r.Id] = i; RCOL[r.Id] = r.Color end
local state
-- 2026-10-05 (Claude): odds shown are the REAL probabilities of the player's current offer pool (C.OfferPool: progression band + luck)
local function poolOdds()
	local odds = {}
	for _, e in ipairs(C.OfferPool(state and state.Band or 1, state and state.Luck or 1)) do odds[e.Id] = e.P end
	return odds
end
local function pctText(p)
	if p >= 0.1 then return ("%d%%"):format(math.floor(p * 100 + 0.5)) end
	if p >= 0.001 then return ("%.1f%%"):format(p * 100) end
	return ("%.2f%%"):format(p * 100)
end
local function chanceText(id)
	local def = C.Parts[id]
	if def.Role == "S" then return "Free starter part" end
	local p = poolOdds()[id]
	return p and ("Roll chance now: " .. pctText(p)) or "Not in your current offers"
end
local function brief(id)
	local d = C.Parts[id]
	local s = d.Stats
	if d.Slot == "Blade" then return ("Width %g  |  Soft x%g  |  Hard x%g"):format(s.Width, s.Soft, s.Hard)
	elseif d.Slot == "Engine" then return ("Speed %g  |  Power x%s  |  0-top %gs"):format(s.Speed, Format.Abbreviate(s.Power), s.AccelTime or C.Drive.AccelTime)
	elseif d.Slot == "Body" then -- task 7: real effect of the shell
		local t = {("+%d%% Snow per tile"):format(math.floor((s.Snow or 0) * 100 + 0.5))}
		if s.Grip then table.insert(t, ("+%d%% grip"):format(math.floor(s.Grip * 100 + 0.5))) end
		if s.Turn then table.insert(t, ("+%d%% steering"):format(math.floor(s.Turn * 100 + 0.5))) end
		if s.Stability then table.insert(t, ("+%d%% stability"):format(math.floor(s.Stability * 100 + 0.5))) end
		return table.concat(t, "  |  ")
	end
	return ("Speed x%g  |  Grip %d%%  |  Push x%g  |  Pivot %d%%"):format(s.SpeedMult, math.floor(s.Traction * 100 + 0.5), s.PowerMult, math.floor(s.Pivot * 100 + 0.5))
end
local function snowNow()
	local ls = player:FindFirstChild("leaderstats")
	local s = ls and ls:FindFirstChild("Snow")
	return s and s.Value or 0
end
local function clientMods()
	return {PowerMult = player:GetAttribute("PowerMult") or 1, PowerBonus = player:GetAttribute("PowerBonus") or 0, SizeMult = player:GetAttribute("SizeMult") or 1,
		ReachMult = player:GetAttribute("ReachMult") or 1, SpinMult = player:GetAttribute("SpinMult") or 1}
end
-- actual productive-clearing comparison on the player's newest stage (same formula the server uses for useful offers)
local function compareText(id)
	if not state or not state.Build then return "" end
	local def = C.Parts[id]
	if state.Build[def.Slot] == id then return "Equipped on your plow" end
	local stage = C.Bands[state.Band or 1]
	local m = clientMods()
	local cur = C.Score(C.StatsFor(state.Build, m), stage)
	local nb = {Blade = state.Build.Blade, Engine = state.Build.Engine, Gear = state.Build.Gear, Body = state.Build.Body}
	nb[def.Slot] = id
	local new = C.Score(C.StatsFor(nb, m), stage)
	if cur <= 0 then return "" end
	local pct = (new / cur - 1) * 100
	local pctS = math.abs(pct) >= 1000 and ("x%s"):format(Format.Abbreviate(math.floor(new / cur + 0.5))) or ((pct >= 0 and "+" or "") .. math.floor(pct + 0.5) .. "%")
	return ("%s clearing here vs your %s"):format(pctS, C.Parts[state.Build[def.Slot]] and C.Parts[state.Build[def.Slot]].Name or "part")
end
local refreshAll
local function call(action, a, b, c)
	-- 2026-10-05: every request carries the current garage-bay lease, so a request made for an earlier bay visit is refused
	local ok, res = pcall(function() return remote:InvokeServer(action, a, b, c, player:GetAttribute("GarageLease")) end)
	if ok and type(res) == "table" then
		if res.state then state = res.state; Api.State = state; Api.Changed:Fire() end
		return res
	end
	return {ok = false, msg = "Connection problem - try again."}
end

local gui = mk("ScreenGui", {Name = "PlowShopGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 101, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
local toastL = text(gui, "", {Name = "Toast", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.24), Size = UDim2.fromScale(0.5, 0.055), TextTransparency = 1, ZIndex = 30}, 2.5)
local toastStroke = toastL:FindFirstChildOfClass("UIStroke"); toastStroke.Transparency = 1
local toastToken = 0
local function toast(str, col)
	toastToken += 1
	local my = toastToken
	toastL.Text, toastL.TextColor3, toastL.TextTransparency, toastStroke.Transparency = str, col or Color3.fromRGB(255, 225, 140), 0, 0
	task.delay(2.8, function()
		if toastToken ~= my then return end
		TweenService:Create(toastL, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(toastStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
	end)
end
local function sfx(id, vol, speed)
	local s = mk("Sound", {SoundId = id, Volume = vol or 0.5, PlaybackSpeed = speed or 1}, gui)
	s:Play()
	task.delay(4, function() s:Destroy() end)
end

-- 3D previews (the real Blender models), slowly orbiting
local previews = {}
local function visible(o)
	while o and o ~= pg do
		if o:IsA("GuiObject") and not o.Visible then return false end
		if o:IsA("ScreenGui") and not o.Enabled then return false end
		o = o.Parent
	end
	return true
end
local function setPreview(vp, model, distMul)
	vp:ClearAllChildren()
	if not model then previews[vp] = nil return end
	model.Parent = vp
	local cf, size = model:GetBoundingBox()
	local cam = mk("Camera", {FieldOfView = 35}, vp)
	vp.CurrentCamera = cam
	previews[vp] = {cam = cam, center = cf.Position, dist = math.max(size.X, size.Y, size.Z) * (distMul or 1.7) + 2, h = size.Y * 0.18}
end
RunService.RenderStepped:Connect(function()
	local a = os.clock() * 0.7
	for vp, e in pairs(previews) do
		if vp.Parent and visible(vp) then
			e.cam.CFrame = CFrame.lookAt(e.center + Vector3.new(math.sin(a) * e.dist, e.h + e.dist * 0.3, math.cos(a) * e.dist), e.center)
		end
	end
end)
local function viewport(parent, props)
	local vp = mk("ViewportFrame", {BackgroundColor3 = Color3.fromRGB(24, 48, 96), BackgroundTransparency = 0.15, Ambient = Color3.fromRGB(175, 175, 195), LightColor = WHITE, LightDirection = Vector3.new(-1, -1.4, -1)}, parent)
	for k, v in pairs(props or {}) do vp[k] = v end
	round(vp, 0.08)
	return vp
end

------------------------------------------------ the offer card (for one pedestal, or the reserved shelf)
local target = "1"
local card = mk("Frame", {Name = "OfferCard", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.fromScale(0.5, touch and 0.72 or 0.54), BackgroundColor3 = WHITE, Visible = false}, gui)
card:SetAttribute("SnowUIDecor", true)
mk("UIAspectRatioConstraint", {AspectRatio = 1.2, AspectType = Enum.AspectType.FitWithinMaxSize}, card)
round(card, 0.07); outline(card, 4)
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(72, 132, 215), Color3.fromRGB(30, 62, 130))}, card)
local cardScale = mk("UIScale", {Scale = 1}, card)
local hdr = mk("Frame", {Position = UDim2.fromScale(0.03, 0.025), Size = UDim2.fromScale(0.82, 0.095), BackgroundColor3 = ICE}, card)
hdr:SetAttribute("SnowUIDecor", true); round(hdr, 0.3); outline(hdr, 2.5)
local hdrText = text(hdr, "", {Position = UDim2.fromScale(0.04, 0.1), Size = UDim2.fromScale(0.92, 0.8)})
local closeB = button(card, "X", Color3.fromRGB(240, 60, 90), {Position = UDim2.fromScale(0.875, 0.025), Size = UDim2.fromScale(0.095, 0.095)})
local glow = mk("ImageLabel", {BackgroundTransparency = 1, Image = TX.glow, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.26, 0.34), Size = UDim2.fromScale(0.62, 0.62), ImageTransparency = 0.8, ZIndex = 1}, card)
local vp = viewport(card, {Position = UDim2.fromScale(0.04, 0.14), Size = UDim2.fromScale(0.44, 0.4), ZIndex = 2})
local nameL = text(card, "", {Position = UDim2.fromScale(0.51, 0.14), Size = UDim2.fromScale(0.46, 0.105), TextXAlignment = Enum.TextXAlignment.Left})
local rarPill = mk("Frame", {Position = UDim2.fromScale(0.51, 0.255), Size = UDim2.fromScale(0.27, 0.07), BackgroundColor3 = ICE}, card)
rarPill:SetAttribute("SnowUIDecor", true); round(rarPill, 0.5); outline(rarPill, 2)
local rarL = text(rarPill, "", {Position = UDim2.fromScale(0.06, 0.1), Size = UDim2.fromScale(0.88, 0.8)}, 1.8)
local slotL = text(card, "", {Position = UDim2.fromScale(0.8, 0.255), Size = UDim2.fromScale(0.17, 0.07), TextColor3 = ICE}, 1.8)
local chanceL = text(card, "", {Position = UDim2.fromScale(0.51, 0.33), Size = UDim2.fromScale(0.46, 0.055), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 232, 150)}, 1.8)
local descL = text(card, "", {Position = UDim2.fromScale(0.51, 0.39), Size = UDim2.fromScale(0.46, 0.05), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(215, 235, 255)}, 1.5)
local statL = text(card, "", {Position = UDim2.fromScale(0.51, 0.445), Size = UDim2.fromScale(0.46, 0.05), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE}, 1.5)
local compareL = text(card, "", {Position = UDim2.fromScale(0.51, 0.5), Size = UDim2.fromScale(0.46, 0.05), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(150, 255, 170)}, 1.5)
local priceL = text(card, "", {Name = "Price", Position = UDim2.fromScale(0.04, 0.565), Size = UDim2.fromScale(0.3, 0.085), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 232, 150)})
local needL = text(card, "", {Position = UDim2.fromScale(0.36, 0.565), Size = UDim2.fromScale(0.61, 0.085), TextXAlignment = Enum.TextXAlignment.Right}, 2)
local track = mk("Frame", {Position = UDim2.fromScale(0.04, 0.66), Size = UDim2.fromScale(0.93, 0.04), BackgroundColor3 = Color3.fromRGB(20, 38, 80)}, card)
track:SetAttribute("SnowUIDecor", true); round(track, 0.5); outline(track, 2)
local fill = mk("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = GREEN, BorderSizePixel = 0}, track)
fill:SetAttribute("SnowUIDecor", true); round(fill, 0.5)
local buyB = button(card, "BUY", GREEN, {Name = "BuyButton", Position = UDim2.fromScale(0.04, 0.725), Size = UDim2.fromScale(0.3, 0.13)})
local resB = button(card, "RESERVE", BLUE, {Name = "ReserveButton", Position = UDim2.fromScale(0.36, 0.725), Size = UDim2.fromScale(0.3, 0.13)})
local rerB = button(card, "REROLL", ORANGE, {Position = UDim2.fromScale(0.68, 0.725), Size = UDim2.fromScale(0.29, 0.13)})
local resStrip = mk("Frame", {Position = UDim2.fromScale(0.03, 0.88), Size = UDim2.fromScale(0.94, 0.1), BackgroundColor3 = Color3.fromRGB(28, 56, 112)}, card)
resStrip:SetAttribute("SnowUIDecor", true); round(resStrip, 0.25); outline(resStrip, 2)
local resText = text(resStrip, "", {Position = UDim2.fromScale(0.03, 0.08), Size = UDim2.fromScale(0.68, 0.84), TextXAlignment = Enum.TextXAlignment.Left}, 1.8)
local resBuy = button(resStrip, "BUY", GREEN, {Position = UDim2.fromScale(0.74, 0.1), Size = UDim2.fromScale(0.23, 0.8)})
local resBar = mk("Frame", {Position = UDim2.fromScale(0.03, 0.86), Size = UDim2.fromScale(0.68, 0.1), BackgroundColor3 = Color3.fromRGB(20, 38, 80)}, resStrip)
resBar:SetAttribute("SnowUIDecor", true); round(resBar, 0.5)
local resFill = mk("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = BLUE, BorderSizePixel = 0}, resBar)
resFill:SetAttribute("SnowUIDecor", true); round(resFill, 0.5)
local confirm = mk("Frame", {Position = UDim2.fromScale(0.12, 0.3), Size = UDim2.fromScale(0.76, 0.4), BackgroundColor3 = Color3.fromRGB(24, 44, 96), Visible = false, ZIndex = 20}, card)
confirm:SetAttribute("SnowUIDecor", true); round(confirm, 0.1); outline(confirm, 3)
local confirmText = text(confirm, "", {Position = UDim2.fromScale(0.06, 0.08), Size = UDim2.fromScale(0.88, 0.5), ZIndex = 21})
local yesB = button(confirm, "REPLACE", ORANGE, {Position = UDim2.fromScale(0.06, 0.64), Size = UDim2.fromScale(0.42, 0.26), ZIndex = 21})
local noB = button(confirm, "KEEP OLD", GREY, {Position = UDim2.fromScale(0.52, 0.64), Size = UDim2.fromScale(0.42, 0.26), ZIndex = 21})
local flash = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 25, Active = false}, card)
flash:SetAttribute("SnowUIDecor", true); round(flash, 0.07)

local function offerNow()
	if not state then return nil end
	if target == "Reserved" then return state.Reserved end
	return state.Offers and state.Offers[target] or nil
end
local shownKey
local function refreshCard()
	if not state then return end
	local o, r = offerNow(), state.Reserved
	local isRes = target == "Reserved"
	local snow = snowNow()
	for _, g in ipairs({vp, nameL, rarPill, slotL, chanceL, descL, statL, compareL, priceL, needL, track, glow, buyB}) do g.Visible = o ~= nil end
	resB.Visible = o ~= nil and not isRes
	rerB.Visible = not isRes
	rerB.Label.Text = o and "REROLL" or "ROLL"
	if o then
		local def = C.Parts[o.Part]
		local col = RCOL[def.Rarity]
		hdr.BackgroundColor3 = col:Lerp(NAVY, 0.3)
		nameL.Text, rarL.Text, slotL.Text, chanceL.Text = def.Name, def.Rarity:upper(), def.Slot:upper(), chanceText(o.Part)
		rarPill.BackgroundColor3 = col:Lerp(NAVY, 0.25)
		descL.Text, statL.Text = def.Desc, brief(o.Part)
		compareL.Text = compareText(o.Part)
		compareL.TextColor3 = compareL.Text:sub(1, 1) == "-" and Color3.fromRGB(255, 170, 150) or Color3.fromRGB(150, 255, 170)
		priceL.Text = "\u{2744} " .. Format.Abbreviate(o.Price)
		local owned = state.Parts[o.Part] or 0
		if snow >= o.Price then
			needL.Text, needL.TextColor3 = owned > 0 and ("Ready! (you own " .. owned .. ")") or "Ready to buy!", Color3.fromRGB(150, 255, 170)
		else
			needL.Text, needL.TextColor3 = "You need " .. Format.Abbreviate(math.ceil(o.Price - snow)) .. " more Snow", Color3.fromRGB(255, 190, 120)
		end
		fill.Size = UDim2.fromScale(o.Price <= 0 and 1 or math.clamp(snow / o.Price, 0, 1), 1)
		fill.BackgroundColor3 = snow >= o.Price and GREEN or ORANGE
		buyB.BackgroundColor3 = snow >= o.Price and GREEN or GREY
		glow.ImageColor3 = col
		if shownKey ~= target .. o.Token then
			shownKey = target .. o.Token
			setPreview(vp, Assembly.PartModel(o.Part), 1.15)
		end
		hdrText.Text = isRes and "YOUR RESERVED PART" or ("PEDESTAL " .. target .. " - FOR SALE!")
	else
		shownKey = nil
		setPreview(vp, nil)
		hdr.BackgroundColor3 = ICE
		hdrText.Text = isRes and "NOTHING RESERVED" or ("PEDESTAL " .. target .. " - ROLL IT!")
	end
	if r and not isRes then
		local def = C.Parts[r.Part]
		resStrip.Visible = true
		resText.Text = ("\u{2B50} %s  \u{2744}%s  %s"):format(def.Name, Format.Abbreviate(r.Price), snow >= r.Price and "READY!" or ("need " .. Format.Abbreviate(math.ceil(r.Price - snow))))
		resFill.Size = UDim2.fromScale(r.Price <= 0 and 1 or math.clamp(snow / r.Price, 0, 1), 1)
		resBuy.BackgroundColor3 = snow >= r.Price and GREEN or GREY
	else
		resStrip.Visible = false
	end
end

local function reveal(rank)
	local big = rank >= C.Shop.BigRevealRank
	local col = RCOL[C.Rarities[rank].Id]
	cardScale.Scale = big and 0.78 or 0.93
	TweenService:Create(cardScale, TweenInfo.new(big and 0.45 or 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	glow.ImageTransparency = big and 0.1 or 0.65
	TweenService:Create(glow, TweenInfo.new(big and 1.8 or 0.5), {ImageTransparency = big and 0.5 or 0.82}):Play()
	vp.Ambient = big and Color3.fromRGB(235, 235, 255) or Color3.fromRGB(175, 175, 195)
	vp.LightColor = big and col:Lerp(WHITE, 0.45) or WHITE
	if big then
		flash.BackgroundColor3 = col:Lerp(WHITE, 0.6); flash.BackgroundTransparency = 0.35
		TweenService:Create(flash, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
		sfx("rbxassetid://125078105193243", 0.55, 1)
	else
		sfx("rbxassetid://12221976", 0.5, 1.5)
	end
end

local function showCard(on) card.Visible = on; if on then confirm.Visible = false; refreshCard() end end
closeB.Activated:Connect(function() showCard(false) end)
local function doRoll(key, inCard)
	key = key or target
	local r = call("Roll", key)
	if r.ok then
		refreshAll()
		if inCard then -- rerolled from the open card: it stays open
			target = key
			showCard(true)
			reveal(r.rank or 2)
		else -- rolled at the pedestal: no pop-up - the part appears on its pedestal (E there opens the offer, R rerolls)
			Api.Revealed(key, r.rank or 2)
			local o = state and state.Offers and state.Offers[key]
			if o then
				local def = C.Parts[o.Part]
				toast(("%s - %s  \u{2744}%s"):format(def.Name, def.Rarity, Format.Abbreviate(o.Price)), RCOL[def.Rarity]:Lerp(WHITE, 0.3))
			end
		end
	else
		toast(r.msg or "Couldn't roll.", Color3.fromRGB(255, 190, 120))
	end
end
rerB.Activated:Connect(function() doRoll(target, true) end)
local function afterBuy(r)
	if r.ok then showCard(false); sfx("rbxassetid://12221976", 0.6, 0.9); toast(r.msg .. " Equip it at the WORKBENCH!", Color3.fromRGB(150, 255, 170)) else toast(r.msg or "Couldn't buy.", Color3.fromRGB(255, 190, 120)) end
	refreshAll()
end
buyB.Activated:Connect(function()
	local o = offerNow()
	if o then afterBuy(call("Buy", target, o.Token)) end
end)
resBuy.Activated:Connect(function()
	if state and state.Reserved then afterBuy(call("Buy", "Reserved", state.Reserved.Token)) end
end)
resB.Activated:Connect(function()
	local o = offerNow()
	if not o then return end
	local r = call("Reserve", target, o.Token, false)
	if r.needConfirm then
		confirmText.Text = ("Replace your reserved %s with %s?"):format(C.Parts[state.Reserved.Part].Name, C.Parts[o.Part].Name)
		confirm.Visible = true
	elseif r.ok then showCard(false); toast(r.msg, Color3.fromRGB(150, 220, 255)) else toast(r.msg or "Couldn't reserve.", Color3.fromRGB(255, 190, 120)) end
	refreshAll()
end)
yesB.Activated:Connect(function()
	confirm.Visible = false
	local o = offerNow()
	if not o then return end
	local r = call("Reserve", target, o.Token, true)
	if r.ok then showCard(false) end
	toast(r.msg or "Couldn't reserve.", r.ok and Color3.fromRGB(150, 220, 255) or Color3.fromRGB(255, 190, 120))
	refreshAll()
end)
noB.Activated:Connect(function() confirm.Visible = false end)

------------------------------------------------ the build window (opened at the workbench)
local garage, gl = nil, {}
local function buildSignature(b) return tostring(b.Blade) .. "|" .. tostring(b.Engine) .. "|" .. tostring(b.Gear) end
local function refreshGarage()
	if not garage or not state then return end
	local b = state.Build
	local sig = buildSignature(b)
	if gl.sig ~= sig then
		gl.sig = sig
		setPreview(gl.vp, Assembly.Build(b), 1.35)
	end
	local st = C.StatsFor(b, clientMods())
	local lines = {
		("Top speed: %d   In snow: %d"):format(math.floor(st.MaxSpeed + 0.5), math.floor(st.MaxSpeed * (C.Drive.PlowingSpeedFactor or 1) + 0.5)), ("Clearing power: %s"):format(st.ClearPower < 100 and ("%.1f"):format(st.ClearPower) or Format.Abbreviate(math.floor(st.ClearPower + 0.5))),
		("Blade width: %.1f"):format(st.BladeWidth), ("Soft snow: x%.1f   Hard snow: x%.1f"):format(st.Soft, st.Hard),
		("Grip: %d%%   Pivot: %d%%   0-top: %.1fs"):format(math.floor(st.Traction * 100 + 0.5), math.floor(st.Pivot * 100 + 0.5), st.AccelTime or C.Drive.AccelTime),
	}
	for i, l in ipairs(gl.stats) do l.Text = lines[i] or "" end
	gl.warn.Text = (st.Valid and "") or "Needs an engine and running gear to drive!"
	gl.list:ClearAllChildren()
	mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, gl.list)
	local order = 0
	for _, slot in ipairs(C.Slots) do
		order += 1
		local head = mk("Frame", {Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, LayoutOrder = order}, gl.list)
		text(head, slot:upper(), {Size = UDim2.fromScale(0.5, 1), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE})
		local un = button(head, "UNEQUIP", GREY, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromScale(0.3, 0.8)})
		un.Visible = b[slot] ~= nil and b[slot] ~= C.Starter[slot]
		un.Activated:Connect(function()
			local r = call("Unequip", slot)
			toast(r.msg or "", r.ok and Color3.fromRGB(150, 220, 255) or Color3.fromRGB(255, 190, 120)); refreshAll()
		end)
		local ids = {}
		for id, def in pairs(C.Parts) do if def.Slot == slot and (state.Parts[id] or 0) > 0 then table.insert(ids, id) end end
		table.sort(ids, function(x, y) return C.Parts[x].Price < C.Parts[y].Price end)
		for _, id in ipairs(ids) do
			order += 1
			local def = C.Parts[id]
			local equipped = b[slot] == id
			local row = mk("Frame", {Size = UDim2.new(1, -8, 0, 62), BackgroundColor3 = equipped and Color3.fromRGB(40, 110, 80) or Color3.fromRGB(34, 66, 128), LayoutOrder = order}, gl.list)
			row:SetAttribute("SnowUIDecor", true); round(row, 0.18); outline(row, 2.5, equipped and GREEN or NAVY)
			mk("Frame", {Size = UDim2.new(0, 8, 1, -10), Position = UDim2.new(0, 6, 0, 5), BackgroundColor3 = RCOL[def.Rarity], BorderSizePixel = 0}, row):SetAttribute("SnowUIDecor", true)
			text(row, def.Name .. ((state.Parts[id] or 0) > 1 and ("  x" .. state.Parts[id]) or ""), {Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.6, 0.48), TextXAlignment = Enum.TextXAlignment.Left})
			text(row, brief(id) .. (equipped and "" or ("   " .. compareText(id))), {Position = UDim2.fromScale(0.05, 0.56), Size = UDim2.fromScale(0.62, 0.36), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(205, 225, 250)}, 1.4)
			local eb = button(row, equipped and "EQUIPPED" or "EQUIP", equipped and GREEN or BLUE, {Name = "Equip_" .. id, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.27, 0.7)})
			eb.Activated:Connect(function()
				if equipped then return end
				local r = call("Equip", slot, id)
				toast(r.msg or "", r.ok and Color3.fromRGB(150, 255, 170) or Color3.fromRGB(255, 190, 120)); refreshAll()
			end)
		end
	end
	gl.list.CanvasSize = UDim2.new(0, 0, 0, 0)
	gl.list.AutomaticCanvasSize = Enum.AutomaticSize.Y
end
local function buildGarageWindow()
	garage = mk("Frame", {Name = "GarageWindow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.9, 0.78), BackgroundColor3 = WHITE, Visible = false}, gui)
	garage:SetAttribute("SnowUIDecor", true)
	mk("UIAspectRatioConstraint", {AspectRatio = 1.6, AspectType = Enum.AspectType.FitWithinMaxSize}, garage)
	round(garage, 0.05); outline(garage, 4)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(72, 132, 215), Color3.fromRGB(30, 62, 130))}, garage)
	text(garage, "\u{1F527} WORKBENCH", {Position = UDim2.fromScale(0.04, 0.02), Size = UDim2.fromScale(0.45, 0.1), TextXAlignment = Enum.TextXAlignment.Left})
	local x = button(garage, "X", Color3.fromRGB(240, 60, 90), {Position = UDim2.fromScale(0.925, 0.02), Size = UDim2.fromScale(0.055, 0.09)})
	x.Activated:Connect(function() garage.Visible = false end)
	gl.vp = viewport(garage, {Position = UDim2.fromScale(0.03, 0.13), Size = UDim2.fromScale(0.45, 0.5)})
	local sf = mk("Frame", {Position = UDim2.fromScale(0.03, 0.65), Size = UDim2.fromScale(0.45, 0.32), BackgroundColor3 = Color3.fromRGB(24, 48, 100)}, garage)
	sf:SetAttribute("SnowUIDecor", true); round(sf, 0.08); outline(sf, 2.5)
	gl.stats = {}
	for i = 1, 5 do gl.stats[i] = text(sf, "", {Position = UDim2.fromScale(0.05, 0.04 + (i - 1) * 0.15), Size = UDim2.fromScale(0.9, 0.14), TextXAlignment = Enum.TextXAlignment.Left}, 1.6) end
	gl.warn = text(sf, "", {Position = UDim2.fromScale(0.05, 0.8), Size = UDim2.fromScale(0.9, 0.15), TextColor3 = Color3.fromRGB(255, 190, 120)}, 1.6)
	gl.list = mk("ScrollingFrame", {Position = UDim2.fromScale(0.5, 0.13), Size = UDim2.fromScale(0.47, 0.84), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new()}, garage)
end
local function openBuild()
	if not garage then buildGarageWindow() end
	garage.Visible = not garage.Visible
	if garage.Visible then card.Visible = false; call("State"); refreshGarage() end
end

------------------------------------------------ GARAGE button (left menu, 6th cell) = teleport to the garage place and back
local lm = rng:FindFirstChild("LeftMenu") or rng:FindFirstChild("RightMenu")
local gb = mk("ImageButton", {Name = "Garage", BackgroundTransparency = 1, LayoutOrder = 99}, lm or gui)
if not lm then gb.AnchorPoint, gb.Position, gb.Size = Vector2.new(1, 0.5), UDim2.fromScale(0.99, 0.66), UDim2.fromOffset(120, 120) end
local gvp = viewport(gb, {Position = UDim2.fromScale(0.1, 0.0), Size = UDim2.fromScale(0.8, 0.7), BackgroundTransparency = 1, Active = false})
local gbLabel = text(gb, "GARAGE", {Position = UDim2.fromScale(0, 0.72), Size = UDim2.fromScale(1, 0.26)}, 2.5)
local fade = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 50, Active = false}, gui)
fade:SetAttribute("SnowUIDecor", true)
local tpBusy = false
local function goToggle()
	if tpBusy then return end
	tpBusy = true
	TweenService:Create(fade, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
	task.wait(0.28)
	local r = call(player:GetAttribute("InGarage") == true and "GoLobby" or "GoGarage")
	if not r.ok then toast(r.msg or "Can't teleport right now.", Color3.fromRGB(255, 190, 120)) end
	task.wait(0.4)
	TweenService:Create(fade, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	tpBusy = false
end
gb.Activated:Connect(function() task.spawn(goToggle) end)
local function onGarageChanged()
	local inG = player:GetAttribute("InGarage") == true
	gbLabel.Text = inG and "LOBBY" or "GARAGE"
	if not inG then
		card.Visible = false
		if garage then garage.Visible = false end
	end
end
player:GetAttributeChangedSignal("InGarage"):Connect(onGarageChanged)
onGarageChanged()

local gbSig
function refreshAll()
	refreshCard()
	refreshGarage()
	if state and gbSig ~= buildSignature(state.Build) then
		gbSig = buildSignature(state.Build)
		setPreview(gvp, Assembly.Build(state.Build), 1.25)
	end
	Api.Changed:Fire()
end
Api.OpenCard = function(key) target = key; showCard(true) end
Api.Roll = function(key) doRoll(key, card.Visible and target == key) end
Api.CardTarget = function() return card.Visible and target or nil end
Api.CloseCard = function() showCard(false) end
Api.OpenBuild = openBuild
Api.Go = function() task.spawn(goToggle) end
Api.Toast = toast

event.OnClientEvent:Connect(function(kind, a)
	if kind == "Despawned" and a == "died" then toast("Your snowplow was parked. Press DRIVE to continue!", ICE) end
end)
local lastRefresh = 0
task.spawn(function()
	local ls = player:WaitForChild("leaderstats"); local s = ls:WaitForChild("Snow")
	s.Changed:Connect(function()
		if os.clock() - lastRefresh > 0.25 then lastRefresh = os.clock(); if card.Visible then refreshCard() end; Api.Changed:Fire() end
	end)
end)
call("State")
refreshAll()
