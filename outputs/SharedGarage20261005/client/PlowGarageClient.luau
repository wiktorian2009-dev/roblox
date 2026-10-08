-- PlowGarageClient (2026-10-05, Claude): the SHARED garage lobby as this player sees it.
-- Every bay in workspace.PlowGarage.Bays publishes public attributes (OwnerUserId, OwnerName, Lease, Build, Offer1..3, Reserved);
-- this script renders all of them for everyone: the owner's assembled snowplow on the turntable (real Blender parts via PlowAssembly)
-- with a short workshop animation when a part changes, the parts floating over each bay's pedestals and reserve shelf, and the
-- owner's name + avatar above the bay. Only YOUR bay gets the E / R prompts and the workbench prompt (the server enforces
-- ownership, lease and distance anyway); other bays get a read-only INSPECT prompt. Your bay is marked "YOUR GARAGE".
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
local event = RS:WaitForChild("PlowEvent")
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local GREEN, ICE = Color3.fromRGB(110, 235, 140), Color3.fromRGB(150, 225, 255)
local RCOL = {}
for _, r in ipairs(C.Rarities) do RCOL[r.Id] = r.Color end
local NEAR, FAR = 120, 220 -- animate/bob only within NEAR studs of the camera; hide floating parts beyond FAR
local function snowNow()
	local ls = player:FindFirstChild("leaderstats")
	local s = ls and ls:FindFirstChild("Snow")
	return s and s.Value or 0
end
local function camPos() local cam = workspace.CurrentCamera; return cam and cam.CFrame.Position or Vector3.zero end
local function visual(m)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery, d.CastShadow = true, false, false, false, false
		elseif d:IsA("LuaSourceContainer") then d:Destroy() end
	end
	return m
end
local function prompt(parent, action, object, key, onTrigger)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText, pp.ObjectText, pp.KeyboardKeyCode = action, object, key or Enum.KeyCode.E
	pp.HoldDuration, pp.MaxActivationDistance, pp.RequiresLineOfSight = 0, 11, false
	pp.Parent = parent
	pp.Triggered:Connect(onTrigger)
	return pp
end
local function label(bb, y, h, size)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Font, l.TextScaled, l.TextColor3 = 1, FONT, true, WHITE
	l.Position, l.Size = UDim2.fromScale(0, y), UDim2.fromScale(1, h)
	l.Parent = bb
	local s = Instance.new("UIStroke"); s.Thickness = size or 2.5; s.Color = NAVY; s.Parent = l
	return l
end
local function billboard(adornee, size, offset, maxDist)
	local bb = Instance.new("BillboardGui")
	bb.Size, bb.StudsOffset, bb.AlwaysOnTop, bb.MaxDistance, bb.LightInfluence = size, offset, false, maxDist or 70, 0
	bb.Adornee = adornee
	bb.Parent = adornee
	return bb
end
local function partOf(m, name)
	local o = m:FindFirstChild(name)
	if not o then return nil end
	if o:IsA("BasePart") then return o end
	return o:FindFirstChild("Top") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart", true)
end
local function fitModel(m, maxSize)
	local _, size = m:GetBoundingBox()
	local s = math.clamp(maxSize / math.max(size.X, size.Y, size.Z), 0.15, 1.7)
	if s ~= 1 then m:ScaleTo(s) end
end
local function myBayIndex() return player:GetAttribute("GarageBay") end

------------------------------------------------ inspection panel (read-only)
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "GarageInspectGui", false, true, 102
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name, panel.AnchorPoint, panel.Position, panel.Size, panel.Visible = "Inspect", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.42, 0.5), false
panel.BackgroundColor3 = WHITE
panel:SetAttribute("SnowUIDecor", true)
panel.Parent = gui
do
	local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 1.25; a.Parent = panel
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.06, 0); cr.Parent = panel
	local st = Instance.new("UIStroke"); st.Thickness = 4; st.Color = NAVY; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = panel
	local g = Instance.new("UIGradient"); g.Rotation = 90; g.Color = ColorSequence.new(Color3.fromRGB(72, 132, 215), Color3.fromRGB(30, 62, 130)); g.Parent = panel
end
local title = label(panel, 0.03, 0.12); title.Position = UDim2.fromScale(0.05, 0.03); title.Size = UDim2.fromScale(0.78, 0.12)
local closeB = Instance.new("TextButton")
closeB.Text, closeB.Font, closeB.TextScaled, closeB.TextColor3 = "X", FONT, true, WHITE
closeB.BackgroundColor3, closeB.Position, closeB.Size = Color3.fromRGB(240, 60, 90), UDim2.fromScale(0.86, 0.03), UDim2.fromScale(0.1, 0.12)
closeB:SetAttribute("SnowUIDecor", true)
do local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.3, 0); cr.Parent = closeB end
closeB.Parent = panel
local rows = {}
for i = 1, 3 do
	local r = label(panel, 0, 0, 2); r.Position = UDim2.fromScale(0.06, 0.18 + (i - 1) * 0.12); r.Size = UDim2.fromScale(0.88, 0.1); r.TextXAlignment = Enum.TextXAlignment.Left
	rows[i] = r
end
local statRows = {}
for i = 1, 4 do
	local r = label(panel, 0, 0, 1.6); r.Position = UDim2.fromScale(0.06, 0.56 + (i - 1) * 0.095); r.Size = UDim2.fromScale(0.88, 0.08); r.TextXAlignment = Enum.TextXAlignment.Left
	r.TextColor3 = Color3.fromRGB(215, 235, 255)
	statRows[i] = r
end
local inspecting
closeB.Activated:Connect(function() panel.Visible = false; inspecting = nil end)
local function parseBuild(s)
	local b, e, g = tostring(s or ""):match("^([^|]*)|([^|]*)|([^|]*)$")
	return {Blade = b ~= "" and b or nil, Engine = e ~= "" and e or nil, Gear = g ~= "" and g or nil}
end
local function openInspect(bay)
	local name = bay:GetAttribute("OwnerName") or ""
	if name == "" then return end
	inspecting = bay
	local build = parseBuild(bay:GetAttribute("Build"))
	title.Text = name .. "'s snowplow"
	for i, slot in ipairs(C.Slots) do
		local def = C.Parts[build[slot] or ""]
		rows[i].Text = def and ("%s:  %s  (%s)"):format(slot == "Gear" and "Running gear" or slot, def.Name, def.Rarity) or (slot .. ":  -")
		rows[i].TextColor3 = def and RCOL[def.Rarity]:Lerp(WHITE, 0.45) or WHITE
	end
	local st = C.StatsFor(build, {}) -- base part stats (upgrades are private)
	statRows[1].Text = ("Top speed %d   In snow %d"):format(math.floor(st.MaxSpeed + 0.5), math.floor(st.MaxSpeed * (C.Drive.PlowingSpeedFactor or 1) + 0.5))
	statRows[2].Text = ("Clearing power %s (before upgrades)"):format(Format.Abbreviate(math.floor(st.ClearPower + 0.5)))
	statRows[3].Text = ("Blade width %.1f   Soft x%.2f   Hard x%.2f"):format(st.BladeWidth, st.Soft, st.Hard)
	statRows[4].Text = ("Grip %d%%   Pivot %d%%   0-top %.1fs"):format(math.floor(st.Traction * 100 + 0.5), math.floor(st.Pivot * 100 + 0.5), st.AccelTime or 1.6)
	panel.Visible = true
end

------------------------------------------------ bays
local bays = {} -- [bayModel] = entry
local function playReveal(e, key, rank)
	local ped = e.peds[key]
	if not ped then return end
	local big = rank >= C.Shop.BigRevealRank
	local col = RCOL[C.Rarities[rank] and C.Rarities[rank].Id or "Common"] or WHITE
	ped.light.Color, ped.light.Enabled, ped.light.Brightness = col, true, big and 9 or 4
	TweenService:Create(ped.light, TweenInfo.new(big and 1.6 or 0.7), {Brightness = 2}):Play()
	local att = Instance.new("Attachment"); att.Position = Vector3.new(0, 2.6, 0); att.Parent = ped.top
	local pe = Instance.new("ParticleEmitter")
	pe.Texture, pe.Color, pe.Rate, pe.Lifetime, pe.Speed, pe.SpreadAngle = TX.glow, ColorSequence.new(col), 0, NumberRange.new(0.8, 1.4), NumberRange.new(10, 18), Vector2.new(180, 180)
	pe.Size, pe.LightEmission, pe.Drag = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0)}), 1, 3
	pe.Parent = att
	pe:Emit(big and 60 or 20)
	local mine = e.model:GetAttribute("BayIndex") == myBayIndex()
	if mine or big then -- neighbours only hear the rare ones, quietly and with distance roll-off
		local s = Instance.new("Sound")
		s.SoundId = big and "rbxassetid://125078105193243" or "rbxassetid://12221976"
		s.Volume, s.PlaybackSpeed = mine and (big and 0.7 or 0.5) or 0.35, big and 1 or 1.5
		s.RollOffMinDistance, s.RollOffMaxDistance = 8, mine and 120 or 70
		s.Parent = ped.top
		s:Play()
		Debris:AddItem(s, 5)
	end
	Debris:AddItem(att, 3)
end

-- the public snowplow preview + equip animation
local ANIM = 0.55
local function finishAnim(e, slot)
	local a = e.anims[slot]
	if not a then return end
	e.anims[slot] = nil
	if a.old and a.old.Parent then a.old:Destroy() end
end
local function slotCF(e, slot)
	local ch = e.preview
	local attach = ch and ch:GetAttribute("Attach_" .. slot)
	return ch and ch.PrimaryPart and attach and ch.PrimaryPart.CFrame * attach or nil
end
local function swapSlot(e, slot, id)
	finishAnim(e, slot) -- a newer change replaces the running animation immediately
	local ch = e.preview
	local old = ch:FindFirstChild(slot)
	local def = C.Parts[id or ""]
	local tpl = def and RS:WaitForChild("PlowParts"):FindFirstChild(def.Model)
	local new = tpl and visual(tpl:Clone())
	if old then old.Name = "Leaving_" .. slot end
	if new then new.Name = slot; new.Parent = ch end
	local target = slotCF(e, slot)
	if new and target then new:PivotTo(target * CFrame.new(0, 5, 0)) end
	e.anims[slot] = {old = old, new = new, t0 = os.clock()}
	local root = ch.PrimaryPart
	if root and (root.Position - camPos()).Magnitude < NEAR then
		local att = Instance.new("Attachment"); att.Parent = root
		if target then att.WorldPosition = target.Position + Vector3.new(0, 1.2, 0) end
		local pe = Instance.new("ParticleEmitter")
		pe.Texture, pe.Rate, pe.Lifetime, pe.Speed, pe.SpreadAngle = TX.spark or TX.glow, 0, NumberRange.new(0.4, 0.8), NumberRange.new(4, 9), Vector2.new(180, 180)
		pe.Color, pe.LightEmission, pe.Size = ColorSequence.new(Color3.fromRGB(255, 230, 150)), 0.8, NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
		pe.Parent = att
		task.delay(ANIM * 0.8, function() if pe.Parent then pe:Emit(18) end end)
		Debris:AddItem(att, 2.5)
		local s = Instance.new("Sound"); s.SoundId, s.Volume, s.PlaybackSpeed, s.RollOffMaxDistance = "rbxassetid://12221976", 0.25, 0.8, 50
		s.Parent = root; s:Play(); Debris:AddItem(s, 3)
	end
end
local function refreshPreview(e)
	local sig = e.model:GetAttribute("Build") or ""
	local owner = (e.model:GetAttribute("OwnerUserId") or 0) ~= 0
	if not owner or sig == "" then
		if e.preview then e.preview:Destroy(); e.preview = nil end
		for slot in pairs(e.anims) do finishAnim(e, slot) end
		e.sig, e.build = nil, nil
		return
	end
	if e.sig == sig then return end
	local build = parseBuild(sig)
	if not e.preview or not e.build or e.ownerSig ~= e.model:GetAttribute("Lease") then
		-- new owner (or first time): build the whole plow at once, no animation
		if e.preview then e.preview:Destroy() end
		for slot in pairs(e.anims) do e.anims[slot] = nil end
		local ok, m = pcall(Assembly.Build, build)
		if ok and m then
			e.preview = visual(m)
			e.preview.Name = "BayPreview"
			e.preview.Parent = e.liftModel or e.model
		end
		e.ownerSig = e.model:GetAttribute("Lease")
	else
		for _, slot in ipairs(C.Slots) do
			if build[slot] ~= e.build[slot] then swapSlot(e, slot, build[slot]) end
		end
	end
	e.sig, e.build = sig, build
end

local function refreshBay(e)
	local m = e.model
	local ownerId = m:GetAttribute("OwnerUserId") or 0
	local mine = ownerId ~= 0 and ownerId == player.UserId and m:GetAttribute("BayIndex") == myBayIndex()
	local snow = snowNow()
	e.mine = mine
	for key, ped in pairs(e.peds) do
		local id = key == "Reserved" and (m:GetAttribute("Reserved") or "") or (m:GetAttribute("Offer" .. key) or "")
		if ownerId == 0 then id = "" end
		if ped.id ~= id then
			ped.id = id
			if ped.display then ped.display:Destroy(); ped.display = nil end
			local d = id ~= "" and Assembly.PartModel(id)
			if d then
				visual(d)
				fitModel(d, 4.6)
				local cf, size = d:GetBoundingBox()
				ped.offset, ped.hover = d:GetPivot():ToObjectSpace(cf), size.Y / 2 + 1.7
				d.Parent = ped.model
				ped.display = d
				ped.display:PivotTo(ped.top.CFrame * CFrame.new(0, ped.hover, 0) * ped.offset:Inverse())
			end
		end
		local def = C.Parts[id]
		if def then
			ped.l1.Text, ped.l1.TextColor3 = def.Name, RCOL[def.Rarity]:Lerp(WHITE, 0.4)
			local p = def.Rarity .. "  \u{2744} " .. Format.Abbreviate(def.Price)
			if mine then
				-- prices are fixed: what you pay is the stored offer price (same as the catalog price when it was rolled)
				local S = Api.State
				local o = S and (key == "Reserved" and S.Reserved or (S.Offers and S.Offers[key]))
				local price = o and o.Price or def.Price
				p = "\u{2744} " .. Format.Abbreviate(price) .. (snow >= price and "  READY!" or ("  need " .. Format.Abbreviate(math.ceil(price - snow))))
			end
			ped.l2.Text = p
			ped.light.Color, ped.light.Enabled = RCOL[def.Rarity], (ped.top.Position - camPos()).Magnitude < NEAR
		else
			ped.l1.Text, ped.l1.TextColor3 = key == "Reserved" and "RESERVED SHELF" or "EMPTY PEDESTAL", Color3.fromRGB(190, 215, 245)
			ped.l2.Text = mine and (key == "Reserved" and "RESERVE a part to save it" or "Press E to ROLL a part!") or ""
			ped.light.Enabled = false
		end
		if ped.prompt then
			ped.prompt.Enabled = mine
			ped.prompt.ActionText = def and "Buy / view offer" or (key == "Reserved" and "Check shelf" or "Roll a part")
		end
		if ped.reroll then ped.reroll.Enabled = mine and def ~= nil end
	end
	if e.benchPrompt then e.benchPrompt.Enabled = mine end
	if e.inspectPrompt then e.inspectPrompt.Enabled = ownerId ~= 0 and not mine end
	-- owner board
	local name = m:GetAttribute("OwnerName") or ""
	e.ownerName.Text = ownerId ~= 0 and name or "FREE BAY"
	e.ownerName.TextColor3 = mine and GREEN or WHITE
	e.yours.Visible = mine
	if e.avatarFor ~= ownerId then
		e.avatarFor = ownerId
		e.avatar.Image = ""
		if ownerId ~= 0 then
			task.spawn(function()
				local ok, img = pcall(function() return Players:GetUserThumbnailAsync(ownerId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
				if ok and e.avatarFor == ownerId then e.avatar.Image = img end
			end)
		end
	end
	refreshPreview(e)
	if inspecting == m then if ownerId == 0 then panel.Visible = false; inspecting = nil else openInspect(m) end end
end

local function setupBay(m)
	if bays[m] then return end
	local e = {model = m, peds = {}, anims = {}}
	bays[m] = e
	for _, key in ipairs({"1", "2", "3", "Reserved"}) do
		local holder = m:WaitForChild("Pedestal_" .. key, 10)
		local top = holder and partOf(m, "Pedestal_" .. key)
		if top then
			local ped = {key = key, top = top, model = holder}
			local bb = billboard(top, UDim2.fromScale(6.5, 2.2), Vector3.new(0, 7.2, 0), 60)
			ped.l1, ped.l2 = label(bb, 0, 0.55), label(bb, 0.58, 0.4)
			ped.light = Instance.new("PointLight"); ped.light.Range, ped.light.Brightness, ped.light.Enabled = 12, 2, false; ped.light.Parent = top
			ped.prompt = prompt(top, "Roll a part", key == "Reserved" and "Reserved shelf" or ("Pedestal " .. key), Enum.KeyCode.E, function()
				if not e.mine then return end
				local S = Api.State
				if key == "Reserved" then
					if S and S.Reserved then Api.OpenCard("Reserved") else Api.Toast("Nothing reserved yet - RESERVE a part from a pedestal!", ICE) end
				elseif S and S.Offers and S.Offers[key] then Api.OpenCard(key)
				else Api.Roll(key) end
			end)
			ped.prompt.Enabled = false
			if key ~= "Reserved" then
				ped.reroll = prompt(top, "Reroll", "Pedestal " .. key, Enum.KeyCode.R, function() if e.mine then Api.Roll(key) end end)
				ped.reroll.UIOffset = Vector2.new(0, 80)
				ped.reroll.Enabled = false
			end
			e.peds[key] = ped
		end
	end
	local bench = partOf(m, "Workbench")
	if bench then e.benchPrompt = prompt(bench, "Open workbench", "Equip & check your plow", Enum.KeyCode.E, function() if e.mine then Api.OpenBuild() end end); e.benchPrompt.Enabled = false end
	local liftTop = partOf(m, "Lift")
	e.liftTop, e.liftModel = liftTop, m:FindFirstChild("Lift")
	if liftTop then
		e.inspectPrompt = prompt(liftTop, "Inspect build", "Snowplow", Enum.KeyCode.E, function() openInspect(m) end)
		e.inspectPrompt.MaxActivationDistance = 16
		e.inspectPrompt.Enabled = false
	end
	local anchor = partOf(m, "OwnerAnchor") or partOf(m, "SignPanel") or liftTop
	local bb = billboard(anchor, UDim2.fromScale(9, 2.6), Vector3.new(0, 2.6, 0), 140)
	e.avatar = Instance.new("ImageLabel")
	e.avatar.BackgroundTransparency, e.avatar.Size, e.avatar.Position = 1, UDim2.fromScale(0.26, 1), UDim2.fromScale(0, 0)
	e.avatar.Parent = bb
	do local a = Instance.new("UIAspectRatioConstraint"); a.Parent = e.avatar; local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.5, 0); cr.Parent = e.avatar end
	e.ownerName = label(bb, 0.1, 0.8); e.ownerName.Position = UDim2.fromScale(0.28, 0.1); e.ownerName.Size = UDim2.fromScale(0.72, 0.8); e.ownerName.TextXAlignment = Enum.TextXAlignment.Left
	local yb = billboard(anchor, UDim2.fromScale(8, 1.6), Vector3.new(0, 5, 0), 400)
	yb.AlwaysOnTop = true
	e.yours = label(yb, 0, 1, 3); e.yours.Text, e.yours.TextColor3 = "\u{2B50} YOUR GARAGE \u{2B50}", GREEN
	e.yours.Visible = false
	for _, attr in ipairs({"OwnerUserId", "OwnerName", "Lease", "Build", "Offer1", "Offer2", "Offer3", "Reserved"}) do
		m:GetAttributeChangedSignal(attr):Connect(function() refreshBay(e) end)
	end
	refreshBay(e)
end
local function cleanupBay(m)
	local e = bays[m]
	if not e then return end
	bays[m] = nil
	if e.preview then e.preview:Destroy() end
	for _, ped in pairs(e.peds) do if ped.display then ped.display:Destroy() end end
	if inspecting == m then panel.Visible = false; inspecting = nil end
end

local function myBay()
	local i = myBayIndex()
	if not i then return nil end
	for m, e in pairs(bays) do if m:GetAttribute("BayIndex") == i then return e end end
	return nil
end

-- guide cue: a short glowing beam from you to your bay when you arrive
local function guide()
	local e = myBay()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (e and hrp and e.liftTop) then return end
	local a0 = Instance.new("Attachment"); a0.Parent = hrp
	local a1 = Instance.new("Attachment"); a1.Parent = e.liftTop; a1.Position = Vector3.new(0, 3, 0)
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1, beam.Width0, beam.Width1, beam.FaceCamera = a0, a1, 0.6, 0.6, true
	beam.Texture, beam.TextureSpeed, beam.TextureLength, beam.LightEmission = TX.glow, 1.5, 2, 1
	beam.Color = ColorSequence.new(GREEN, Color3.fromRGB(255, 240, 150))
	beam.Parent = hrp
	Debris:AddItem(beam, 7); Debris:AddItem(a0, 7); Debris:AddItem(a1, 7)
	Api.Toast(("Your garage is BAY %d - follow the glow!"):format(e.model:GetAttribute("BayIndex") or 0), GREEN)
end

local function watchFolder()
	local garage = workspace:WaitForChild("PlowGarage", 60)
	local folder = garage and garage:WaitForChild("Bays", 60)
	if not folder then return end
	folder.ChildAdded:Connect(function(m) task.spawn(setupBay, m) end)
	folder.ChildRemoved:Connect(cleanupBay)
	for _, m in ipairs(folder:GetChildren()) do task.spawn(setupBay, m) end
	local portal = garage:FindFirstChild("ReturnPad")
	local top = portal and partOf(garage, "ReturnPad")
	if top then prompt(top, "Back to the lobby", "Return portal", Enum.KeyCode.E, function() Api.Go() end) end
end
task.spawn(watchFolder)

Api.Changed.Event:Connect(function() for _, e in pairs(bays) do if e.mine then refreshBay(e) end end end)
player:GetAttributeChangedSignal("GarageBay"):Connect(function()
	for _, e in pairs(bays) do refreshBay(e) end
	if myBayIndex() then task.delay(0.6, guide) end
end)

-- the roll reveal happens IN THE WORLD (no pop-up card); neighbours see it too
Api.Revealed = function(key, rank)
	local e = myBay()
	if e then playReveal(e, key, rank) end
end
event.OnClientEvent:Connect(function(kind, bayIndex, key, rank)
	if kind ~= "BayReveal" or bayIndex == myBayIndex() then return end
	for m, e in pairs(bays) do
		if m:GetAttribute("BayIndex") == bayIndex then
			if e.peds[key] and (e.peds[key].top.Position - camPos()).Magnitude < 90 then
				task.delay(0.15, function() playReveal(e, key, tonumber(rank) or 2) end)
			end
		end
	end
end)

-- animation + turntables + bobbing parts (only near the camera)
RunService.RenderStepped:Connect(function()
	local t, cam = os.clock(), camPos()
	for _, e in pairs(bays) do
		local near = e.liftTop and (e.liftTop.Position - cam).Magnitude < NEAR
		if e.preview and e.liftTop and e.preview.PrimaryPart then
			-- the plow faces the plaza and only sways gently: a full spin of the widest blade would sweep through the pedestals
			local sway = near and math.sin(t * 0.5 + (e.model:GetAttribute("BayIndex") or 0)) * math.rad(8) or 0
			e.preview:PivotTo(e.liftTop.CFrame * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, sway, 0))
			for slot, a in pairs(e.anims) do
				local k = math.clamp((t - a.t0) / ANIM, 0, 1)
				local ease = 1 - (1 - k) ^ 3
				local target = slotCF(e, slot)
				if target then
					if a.new and a.new.Parent then a.new:PivotTo(target * CFrame.new(0, (1 - ease) * 5, 0)) end
					if a.old and a.old.Parent then
						a.old:PivotTo(target * CFrame.new(0, -ease * 1.5, ease * 2.5))
						for _, d in ipairs(a.old:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = ease end end
					end
				end
				if k >= 1 then finishAnim(e, slot) end
			end
		end
		for _, ped in pairs(e.peds) do
			if ped.display and ped.offset then
				local d = (ped.top.Position - cam).Magnitude
				if d < NEAR then
					local base = ped.top.CFrame * CFrame.new(0, ped.hover + math.sin(t * 2 + (tonumber(ped.key) or 4)) * 0.25, 0) * CFrame.Angles(0, t * 0.9, 0)
					ped.display:PivotTo(base * ped.offset:Inverse())
				end
			end
		end
	end
end)

-- an open offer card closes when you walk away from your pedestal; the inspection panel closes when you walk away too
task.spawn(function()
	while true do
		task.wait(0.5)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local key = Api.CardTarget()
		local e = myBay()
		local ped = key and e and e.peds[key]
		if hrp and key and (not ped or (hrp.Position - ped.top.Position).Magnitude > 20) then Api.CloseCard() end
		if hrp and inspecting and inspecting.Parent then
			if (hrp.Position - inspecting:GetPivot().Position).Magnitude > 45 then panel.Visible = false; inspecting = nil end
		end
		if player:GetAttribute("InGarage") ~= true and panel.Visible then panel.Visible = false; inspecting = nil end
	end
end)
player:GetAttributeChangedSignal("InGarage"):Connect(function()
	if player:GetAttribute("InGarage") == true then Api.Toast("Find your bay and press E at a pedestal to roll a part!", ICE) end
end)
