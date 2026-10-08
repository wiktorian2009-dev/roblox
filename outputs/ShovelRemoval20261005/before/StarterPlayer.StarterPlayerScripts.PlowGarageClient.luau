-- PlowGarageClient (2026-10-05, Claude): the garage PLACE as the player sees it. Your personal offers float above the three roll pedestals
-- and the gold reserve shelf (E opens or rolls), the lift turns your current plow, the workbench opens the build window, the return pad leads back.
-- Everything shown here is local to you: other players see their own parts on their own pedestals.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("PlowConfig"))
if C.Mode ~= "Snowplow" then return end
local Assembly = require(RS:WaitForChild("PlowAssembly"))
local Api = require(RS:WaitForChild("PlowClientApi"))
local Format = require(RS:WaitForChild("NumberFormat"))
local TX = require(RS:WaitForChild("UniversalVFX")).Textures
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local RCOL = {}
for _, r in ipairs(C.Rarities) do RCOL[r.Id] = r.Color end
local function snowNow()
	local ls = player:FindFirstChild("leaderstats")
	local s = ls and ls:FindFirstChild("Snow")
	return s and s.Value or 0
end

local peds, lift, built = {}, nil, false
local function prompt(parent, action, object, onTrigger)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText, pp.ObjectText, pp.KeyboardKeyCode = action, object, Enum.KeyCode.E
	pp.HoldDuration, pp.MaxActivationDistance, pp.RequiresLineOfSight = 0, 12, false
	pp.Parent = parent
	pp.Triggered:Connect(onTrigger)
	return pp
end
local function billboard(top)
	local bb = Instance.new("BillboardGui")
	bb.Size, bb.StudsOffset, bb.AlwaysOnTop, bb.MaxDistance, bb.LightInfluence = UDim2.fromScale(6.5, 2.2), Vector3.new(0, 7.2, 0), false, 70, 0
	bb.Adornee = top
	bb.Parent = top
	local function label(y, h)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency, l.Font, l.TextScaled, l.TextColor3 = 1, FONT, true, WHITE
		l.Position, l.Size = UDim2.fromScale(0, y), UDim2.fromScale(1, h)
		l.Parent = bb
		local s = Instance.new("UIStroke"); s.Thickness = 2.5; s.Color = NAVY; s.Parent = l
		return l
	end
	return label(0, 0.55), label(0.58, 0.4)
end
local function build()
	if built then return end
	local garage = workspace:WaitForChild("PlowGarage", 20)
	if not garage then return end
	built = true
	for _, key in ipairs({"1", "2", "3", "Reserved"}) do
		local model = garage:WaitForChild("Pedestal_" .. key, 15)
		local top = model and model:WaitForChild("Top", 15)
		if top then
			local e = {key = key, top = top, model = model}
			e.l1, e.l2 = billboard(top)
			e.light = Instance.new("PointLight"); e.light.Range, e.light.Brightness, e.light.Enabled = 14, 2, false; e.light.Parent = top
			e.prompt = prompt(top, "Roll a part", key == "Reserved" and "Reserved shelf" or ("Pedestal " .. key), function()
				local S = Api.State
				if key == "Reserved" then
					if S and S.Reserved then Api.OpenCard("Reserved") else Api.Toast("Nothing reserved yet - RESERVE a part from a pedestal!", Color3.fromRGB(150, 220, 255)) end
				elseif S and S.Offers and S.Offers[key] then Api.OpenCard(key)
				else Api.Roll(key) end
			end)
			if key ~= "Reserved" then
				e.reroll = prompt(top, "Reroll", "Pedestal " .. key, function() Api.Roll(key) end)
				e.reroll.KeyboardKeyCode = Enum.KeyCode.R
				e.reroll.UIOffset = Vector2.new(0, 80)
				e.reroll.Enabled = false
			end
			peds[key] = e
		end
	end
	local wb = garage:WaitForChild("Workbench", 15)
	if wb and wb:FindFirstChild("Top") then prompt(wb.Top, "Open workbench", "Equip & check your plow", function() Api.OpenBuild() end) end
	local pad = garage:WaitForChild("ReturnPad", 15)
	if pad and pad:FindFirstChild("Top") then prompt(pad.Top, "Back to the lobby", "Return pad", function() Api.Go() end) end
	local lm = garage:WaitForChild("Lift", 15)
	if lm and lm:FindFirstChild("Top") then lift = {top = lm.Top, model = lm} end
end
local function fitModel(m, maxSize)
	local _, size = m:GetBoundingBox()
	local s = math.clamp(maxSize / math.max(size.X, size.Y, size.Z), 0.15, 1.7)
	if s ~= 1 then m:ScaleTo(s) end
end
local function refresh()
	local S = Api.State
	if not S or not built then return end
	local snow = snowNow()
	for key, e in pairs(peds) do
		local o = key == "Reserved" and S.Reserved or (S.Offers and S.Offers[key])
		local tok = o and o.Token
		if e.token ~= tok then
			e.token = tok
			if e.display then e.display:Destroy(); e.display = nil end
			if o then
				local m = Assembly.PartModel(o.Part)
				if m then
					fitModel(m, 4.8)
					local cf, size = m:GetBoundingBox()
					e.offset, e.hover = m:GetPivot():ToObjectSpace(cf), size.Y / 2 + 1.7
					m.Parent = e.model
					e.display = m
				end
			end
		end
		if o then
			local def = C.Parts[o.Part]
			local col = RCOL[def.Rarity]
			e.l1.Text, e.l1.TextColor3 = def.Name, col:Lerp(WHITE, 0.4)
			local p = "\u{2744} " .. Format.Abbreviate(o.Price)
			e.l2.Text = snow >= o.Price and (p .. "  READY!") or (p .. "  need " .. Format.Abbreviate(math.ceil(o.Price - snow)))
			e.light.Color, e.light.Enabled = col, true
			e.prompt.ActionText = "Buy / view offer"
			if e.reroll then e.reroll.Enabled = true end
		else
			e.l1.Text, e.l1.TextColor3 = key == "Reserved" and "RESERVED SHELF" or "EMPTY PEDESTAL", Color3.fromRGB(190, 215, 245)
			e.l2.Text = key == "Reserved" and "RESERVE a part to save it" or "Press E to ROLL a part!"
			e.light.Enabled = false
			e.prompt.ActionText = key == "Reserved" and "Check shelf" or "Roll a part"
			if e.reroll then e.reroll.Enabled = false end
		end
	end
	if lift then
		local b = S.Build
		local sig = tostring(b.Blade) .. "|" .. tostring(b.Engine) .. "|" .. tostring(b.Gear)
		if lift.sig ~= sig then
			lift.sig = sig
			if lift.display then lift.display:Destroy() end
			local m = Assembly.Build(b)
			fitModel(m, 11)
			local cf, size = m:GetBoundingBox()
			lift.offset, lift.hover = m:GetPivot():ToObjectSpace(cf), size.Y / 2 + 0.3
			m.Parent = lift.model
			lift.display = m
		end
	end
end
RunService.RenderStepped:Connect(function()
	if not built then return end
	local t = os.clock()
	for _, e in pairs(peds) do
		if e.display and e.offset then
			local base = e.top.CFrame * CFrame.new(0, e.hover + math.sin(t * 2 + (tonumber(e.key) or 4)) * 0.25, 0) * CFrame.Angles(0, t * 0.9, 0)
			e.display:PivotTo(base * e.offset:Inverse())
		end
	end
	if lift and lift.display then
		local base = lift.top.CFrame * CFrame.new(0, lift.hover, 0) * CFrame.Angles(0, t * 0.35, 0)
		lift.display:PivotTo(base * lift.offset:Inverse())
	end
end)
Api.Changed.Event:Connect(refresh)
local function enter()
	task.spawn(function() build(); refresh() end)
end
player:GetAttributeChangedSignal("InGarage"):Connect(function()
	if player:GetAttribute("InGarage") == true then
		enter()
		Api.Toast("Walk up to a pedestal and press E to roll a part!", Color3.fromRGB(150, 225, 255))
	end
end)
if player:GetAttribute("InGarage") == true then enter() end

-- the roll reveal happens IN THE WORLD: a light pulse, a glowing burst and a sound at the pedestal (no pop-up card)
Api.Revealed = function(key, rank)
	local e = peds[key]
	if not e then return end
	local big = rank >= C.Shop.BigRevealRank
	local col = RCOL[C.Rarities[rank].Id]
	e.light.Color, e.light.Enabled, e.light.Brightness = col, true, big and 10 or 5
	TweenService:Create(e.light, TweenInfo.new(big and 1.6 or 0.7), {Brightness = 2}):Play()
	local att = Instance.new("Attachment"); att.Position = Vector3.new(0, 2.6, 0); att.Parent = e.top
	local pe = Instance.new("ParticleEmitter")
	pe.Texture, pe.Color, pe.Rate, pe.Lifetime, pe.Speed, pe.SpreadAngle = TX.glow, ColorSequence.new(col), 0, NumberRange.new(0.8, 1.4), NumberRange.new(10, 18), Vector2.new(180, 180)
	pe.Size, pe.LightEmission, pe.Drag = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0)}), 1, 3
	pe.Parent = att
	pe:Emit(big and 70 or 24)
	local s = Instance.new("Sound")
	s.SoundId, s.Volume, s.PlaybackSpeed, s.RollOffMaxDistance = big and "rbxassetid://125078105193243" or "rbxassetid://12221976", big and 0.7 or 0.5, big and 1 or 1.5, 120
	s.Parent = e.top
	s:Play()
	Debris:AddItem(att, 3); Debris:AddItem(s, 5)
end
-- an open offer card closes by itself when you walk away from its pedestal
task.spawn(function()
	while true do
		task.wait(0.5)
		local key = Api.CardTarget()
		local e = key and peds[key]
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if e and hrp and (hrp.Position - e.top.Position).Magnitude > 20 then Api.CloseCard() end
	end
end)

