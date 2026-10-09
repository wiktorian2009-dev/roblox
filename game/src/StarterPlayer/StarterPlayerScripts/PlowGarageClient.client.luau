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
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("PlowConfig"))
if C.Mode ~= "Snowplow" then return end
local Assembly = require(RS:WaitForChild("PlowAssembly"))
local Api = require(RS:WaitForChild("PlowClientApi"))
local Format = require(RS:WaitForChild("NumberFormat"))
local UILayout = require(RS:WaitForChild("UILayout"))
local TX = require(RS:WaitForChild("UniversalVFX")).Textures
local event = RS:WaitForChild("PlowEvent")
local Reveal = require(RS:WaitForChild("PlowRollReveal")) -- 2026-10-09: the pedestal part-roll reveal (presentation only)
local touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled
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
-- a part model fitted for a pedestal: the same size / centre the pedestal display and the roll reveal use
local function preparePart(id)
	local d = Assembly.PartModel(id)
	if not d then return nil end
	visual(d)
	fitModel(d, 4.6)
	local cf, size = d:GetBoundingBox()
	return d, d:GetPivot():ToObjectSpace(cf), size.Y / 2 + 1.7
end
Reveal.Init({prepare = preparePart})
-- 2026-10-08 (UI audit F26 / F31): the equip window is built by PlowShopClient (PlowShopGui.GarageWindow); nil-safe, so it counts as closed until it exists
local BAY_REACH = 39 -- studs; PlowService refuses Equip / LevelUp farther than this from your bay pivot (its BAY_REACH)
local function garageWindowOpen()
	local pg = player:FindFirstChild("PlayerGui")
	local shop = pg and pg:FindFirstChild("PlowShopGui")
	local w = shop and shop:FindFirstChild("GarageWindow")
	return w ~= nil and w:IsA("GuiObject") and w.Visible
end

------------------------------------------------ inspection panel (read-only)
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "GarageInspectGui", false, true, 102
local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui
local panel = Instance.new("Frame")
panel.Name, panel.AnchorPoint, panel.Position, panel.Size, panel.Visible = "Inspect", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.42, 0.5), false
panel.BackgroundColor3 = WHITE
panel.Active = true -- 2026-10-08 (F26): the panel sinks clicks, so they cannot reach the car ClickDetector behind it
panel:SetAttribute("SnowUIDecor", true)
panel.Parent = gui
do
	local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 1.25; a.Parent = panel
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.06, 0); cr.Parent = panel
	local st = Instance.new("UIStroke"); st.Thickness = 4; st.Color = NAVY; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = panel
	local g = Instance.new("UIGradient"); g.Rotation = 90; g.Color = ColorSequence.new(Color3.fromRGB(72, 132, 215), Color3.fromRGB(30, 62, 130)); g.Parent = panel
end
-- 2026-10-08 (F39): the close button is at least 44x44, so it reaches down to 0.03 H + 44 px, while part row 1 starts at 0.17 H. Phones and short windows
-- (where the normal panel is under ~340 px tall) therefore get a bigger panel, still capped by the 1.25 aspect constraint, so the button never covers the Blade row.
local PANEL_NORMAL, PANEL_BIG, PANEL_MIN_H = UDim2.fromScale(0.42, 0.5), UDim2.fromScale(0.64, 0.92), 340
local function fitPanel()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize
	if not vp or vp.X <= 0 or vp.Y <= 0 then return end
	local normalH = math.min(0.5 * vp.Y, 0.42 * vp.X / 1.25) -- panel height at the normal size under the aspect constraint
	panel.Size = (UILayout.isSmall(vp) or normalH < PANEL_MIN_H) and PANEL_BIG or PANEL_NORMAL
end
do -- created once: re-fit when the viewport changes (rotation, window resize) and when the camera object is replaced
	local viewConn
	local function watchViewport()
		if viewConn then viewConn:Disconnect(); viewConn = nil end
		local cam = workspace.CurrentCamera
		if cam then viewConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel) end
		fitPanel()
	end
	watchViewport()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchViewport)
end
local title = label(panel, 0.03, 0.12); title.Position = UDim2.fromScale(0.05, 0.03); title.Size = UDim2.fromScale(0.72, 0.12) -- 0.72 (was 0.78): keeps the title clear of the 44 px close button on phones
local closeB = Instance.new("TextButton")
closeB.Text, closeB.Font, closeB.TextScaled, closeB.TextColor3 = "X", FONT, true, WHITE
-- 2026-10-08 (F39): right edge stays at 0.96 and the button grows leftwards to a 44x44 touch target on small panels (on desktop 0.1 x 0.12 is already bigger);
-- fitPanel (above) makes the panel tall enough on phones that the button ends above the first part row
closeB.BackgroundColor3, closeB.AnchorPoint, closeB.Position, closeB.Size = Color3.fromRGB(240, 60, 90), Vector2.new(1, 0), UDim2.fromScale(0.96, 0.03), UDim2.fromScale(0.1, 0.12)
closeB.ZIndex = 3 -- above the part rows, which are created after it and would otherwise draw over the larger button
closeB:SetAttribute("SnowUIDecor", true)
do
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.3, 0); cr.Parent = closeB
	local mn = Instance.new("UISizeConstraint"); mn.MinSize = Vector2.new(44, 44); mn.Parent = closeB
end
closeB.Parent = panel
do -- 2026-10-06: snowy image art for the inspection window and its close button
	local SnowArt = require(RS:WaitForChild("SnowArt"))
	SnowArt.SkinPanel(panel); SnowArt.SkinClose(closeB)
end
local rows = {}
for i = 1, #C.Slots do -- task 7: one row per part slot (Blade, Engine, Gear, Body)
	local r = label(panel, 0, 0, 2); r.Position = UDim2.fromScale(0.06, 0.17 + (i - 1) * 0.095); r.Size = UDim2.fromScale(0.88, 0.085); r.TextXAlignment = Enum.TextXAlignment.Left
	rows[i] = r
end
local statRows = {}
for i = 1, 4 do
	local r = label(panel, 0, 0, 1.6); r.Position = UDim2.fromScale(0.06, 0.56 + (i - 1) * 0.095); r.Size = UDim2.fromScale(0.88, 0.08); r.TextXAlignment = Enum.TextXAlignment.Left
	r.TextColor3 = Color3.fromRGB(215, 235, 255)
	statRows[i] = r
end
local inspecting
local function closeInspect() panel.Visible = false; inspecting = nil end
Api.CloseInspect = closeInspect -- 2026-10-08 (F05): the other openers (equip window, offer card, MINI PLOWS, tutorial) close this panel through the Api
closeB.Activated:Connect(closeInspect)
-- public bay build "blade|engine|gear|body" (task 7); older 3-part strings still parse and show the starter body
local function parseBuild(s)
	local f = string.split(tostring(s or ""), "|")
	local b = {}
	for i, slot in ipairs(C.Slots) do if f[i] and f[i] ~= "" and C.Parts[f[i]] and C.Parts[f[i]].Slot == slot then b[slot] = f[i] end end
	if not b.Body and (b.Blade or b.Engine or b.Gear) then b.Body = C.Starter.Body end
	return b
end
-- fills the panel from the bay's public attributes; no open / close side effects, so a live refresh of the inspected bay never touches other panels
local function renderInspect(bay)
	local name = bay:GetAttribute("OwnerName") or ""
	if name == "" then return end
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
end
-- 2026-10-08 (UI audit, review): the panel (DO 102, Active) closes by itself when ANOTHER menu opens, the same 0.25 s edge poll PlowShopClient, MINI PLOWS, the
-- egg screen and the HELP menu use. It is needed because the RNG panels (PETS / SHOP / REWARDS / PARTS / Settings, RNGGui DO 100) and UPGRADES do not call
-- Api.CloseInspect until their Studio patches are installed, so without it Inspect would draw over them and sink their taps. State-based, no DisplayOrder.
local OTHER_MENUS = {"Panels", "UpgradeTree", "GarageWindow", "OfferCard", "EggScreen", "MiniPlow", "HelpMenu"} -- every UILayout.openMenu key except Inspect itself
local ONLY = {} -- ONLY[key] = the `ignore` set for UILayout.openMenu that leaves just that one menu to be tested
for _, k in ipairs(OTHER_MENUS) do
	local ig = {Inspect = true}
	for _, o in ipairs(OTHER_MENUS) do if o ~= k then ig[o] = true end end
	ONLY[k] = ig
end
local function menusOpen() -- { [key] = true } for each other menu showing right now (per key, so one stuck menu cannot hide a newly opened one)
	local s = {}
	for _, k in ipairs(OTHER_MENUS) do s[k] = UILayout.openMenu(playerGui, ONLY[k]) ~= nil end
	return s
end
local seenMenus = {} -- menus already open when the panel opened (re-seeded by openInspect): only a menu that opens AFTER that closes the panel
local function openInspect(bay)
	if (bay:GetAttribute("OwnerName") or "") == "" then return end
	-- 2026-10-08 (F05): one menu at a time (UILayout contract). The RNG panels / Travel / UPGRADES are asked to close over the same bus as PlowShopClient
	-- and MiniPlowClient ("CloseAll" is ignored by listeners that do not know it yet; HELP and MINI PLOWS close themselves by polling UILayout.openMenu),
	-- and the equip window and offer card are closed (no-ops until PlowShopClient overrides them); otherwise they stay open beneath this panel (DO 102 vs 101).
	local pg = player:FindFirstChild("PlayerGui")
	local rng = pg and pg:FindFirstChild("RNGGui")
	local village = rng and rng:FindFirstChild("VillageOpenMenu")
	if village and village:IsA("BindableEvent") then village:Fire("CloseAll") end
	pcall(Api.CloseBuild)
	pcall(Api.CloseCard)
	inspecting = bay -- set after the closes: a re-entrant Api.CloseInspect must not clear it
	renderInspect(bay)
	seenMenus = menusOpen() -- a menu that stays open (an RNG panel whose script ignores "CloseAll" yet) must not close the panel that is opening now
	panel.Visible = true
end
-- one task for the whole script, nothing connected per open; it only does work while the panel shows. The pcall keeps the loop alive if a lookup ever errors.
task.spawn(function()
	while true do
		task.wait(0.25)
		if panel.Visible then
			pcall(function()
				local now, opened = menusOpen(), false
				for k, on in pairs(now) do if on and not seenMenus[k] then opened = true end end
				seenMenus = now
				if opened then closeInspect() end
			end)
		end
	end
end)

------------------------------------------------ bays
local bays = {} -- [bayModel] = entry
local function playReveal(e, key, rank)
	local ped = e.peds[key]
	if not ped then return end
	local big = rank >= C.Shop.BigRevealRank
	local col = RCOL[C.Rarities[rank] and C.Rarities[rank].Id or "Common"] or WHITE
	ped.light.Color, ped.light.Enabled, ped.light.Brightness = col, true, big and 3 or 1.6
	TweenService:Create(ped.light, TweenInfo.new(big and 1.6 or 0.7), {Brightness = 0.8}):Play()
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
		if ped.anim and ped.anim:Alive() then -- 2026-10-09: a roll reveal owns this pedestal until it hands the part over
			ped.l1.Text, ped.l1.TextColor3 = "ROLLING...", ICE
			ped.l2.Text = mine and (Reveal.SkipIsPaid() and "\u{26A1} QUICK ROLLS to skip" or (touchOnly and "tap to skip" or "click to skip")) or ""
			if ped.prompt then ped.prompt.Enabled = mine; ped.baseAction = "Skip"; ped.prompt.ActionText = "Skip"; ped.rollPrompt = false end
			if ped.reroll then ped.reroll.Enabled = false end
			if ped.cd then ped.cd.bb.Enabled = mine end
			continue
		end
		local id = key == "Reserved" and (m:GetAttribute("Reserved") or "") or (m:GetAttribute("Offer" .. key) or "")
		if ownerId == 0 then id = "" end
		if ped.id ~= id then
			ped.id = id
			if ped.display then ped.display:Destroy(); ped.display = nil end
			local d, offset, hover
			if id ~= "" then d, offset, hover = preparePart(id) end
			if d then
				ped.offset, ped.hover, ped.phase = offset, hover, nil
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
				p = (key == "Reserved" and "" or "OFFER  ") .. "\u{2744} " .. Format.Abbreviate(price) .. (snow >= price and "  READY!" or ("  need " .. Format.Abbreviate(math.ceil(price - snow))))
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
			ped.baseAction = def and "Buy / view offer" or (key == "Reserved" and "Check shelf" or "Roll a part")
			ped.prompt.ActionText = ped.baseAction
			ped.rollPrompt = def == nil and key ~= "Reserved" -- the E prompt rolls only on an empty pedestal
		end
		if ped.reroll then ped.reroll.Enabled = mine and def ~= nil end
		if ped.cd then ped.cd.bb.Enabled = mine end
		if ped.bb then ped.bb.MaxDistance = mine and 45 or 16 end
	end
	if e.benchPrompt then e.benchPrompt.Enabled = mine end
	if e.equipHint then e.equipHint.Enabled = mine end
	if e.inspectPrompt then e.inspectPrompt.Enabled = ownerId ~= 0 and not mine end
	-- owner board
	local name = m:GetAttribute("OwnerName") or ""
	e.ownerName.Text = ownerId ~= 0 and name or "FREE BAY"
	if e.ownerBoard then e.ownerBoard.MaxDistance = ownerId ~= 0 and 90 or 25 end -- empty bays don't shout across the garage
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
	if inspecting == m then if ownerId == 0 then closeInspect() else renderInspect(m) end end
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
			local bb = billboard(top, UDim2.fromScale(6.5, 2.2), Vector3.new(0, 7.2, 0), 16) -- 2026-10-06: neighbours' labels only up close
			ped.bb = bb
			ped.l1, ped.l2 = label(bb, 0, 0.55), label(bb, 0.58, 0.4)
			ped.light = Instance.new("PointLight"); ped.light.Range, ped.light.Brightness, ped.light.Enabled = 9, 0.8, false; ped.light.Parent = top
			ped.prompt = prompt(top, "Roll a part", key == "Reserved" and "Reserved shelf" or ("Pedestal " .. key), Enum.KeyCode.E, function()
				if not e.mine then return end
				if ped.anim and ped.anim:Alive() then ped.anim:TrySkip(); return end -- E during a reveal = skip to the same result (Quick Rolls perk)
				local S = Api.State
				if key == "Reserved" then
					if S and S.Reserved then Api.OpenCard("Reserved") else Api.Toast("Nothing reserved yet - RESERVE a part from a pedestal!", ICE) end
				elseif S and S.Offers and S.Offers[key] then Api.OpenCard(key)
				else Api.Roll(key) end
			end)
			ped.prompt.Enabled = false
			if key ~= "Reserved" then
				-- 2026-10-06: roll cooldown pill (your bay only): fills orange with the seconds left, then ROLL READY! in green
				local cb = billboard(top, UDim2.fromScale(4.0, 0.85), Vector3.new(0, 8.8, 0), 45) -- small + soft, owner only
				cb.Name, cb.Enabled = "RollCooldown", false
				local pill = Instance.new("Frame")
				pill.Size, pill.BackgroundColor3, pill.BackgroundTransparency, pill.BorderSizePixel = UDim2.fromScale(1, 1), Color3.fromRGB(43, 74, 122), 0.15, 0
				pill:SetAttribute("SnowUIDecor", true)
				pill.Parent = cb
				do local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.5, 0); cr.Parent = pill; local st = Instance.new("UIStroke"); st.Thickness = 1.5; st.Color = NAVY; st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = pill end
				local fillF = Instance.new("Frame")
				fillF.Size, fillF.BackgroundColor3, fillF.BorderSizePixel = UDim2.fromScale(1, 1), GREEN, 0
				fillF:SetAttribute("SnowUIDecor", true)
				fillF.Parent = pill
				do local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0.5, 0); cr.Parent = fillF end
				local tl = label(pill, 0.08, 0.84, 2); tl.Position = UDim2.fromScale(0.05, 0.08); tl.Size = UDim2.fromScale(0.9, 0.84); tl.ZIndex = 2
				ped.cd = {bb = cb, fill = fillF, text = tl}
				ped.reroll = prompt(top, "Reroll", "Pedestal " .. key, Enum.KeyCode.R, function() if e.mine then Api.Roll(key) end end)
				ped.reroll.UIOffset = Vector2.new(0, 80)
				ped.reroll.Enabled = false
			end
			e.peds[key] = ped
		end
	end
	-- 2026-10-06 (wiktor: "remove work bench just click at the main car to equip something"): your OWN car on the lift opens the
	-- build/equip window (prompt for keyboard/gamepad/touch, plus a ClickDetector for mouse/tap and a small hint). Neighbours keep "Inspect".
	local liftTop = partOf(m, "Lift")
	e.liftTop, e.liftModel = liftTop, m:FindFirstChild("Lift")
	if liftTop then
		e.inspectPrompt = prompt(liftTop, "Inspect build", "Snowplow", Enum.KeyCode.E, function() openInspect(m) end)
		e.inspectPrompt.MaxActivationDistance = 16
		e.inspectPrompt.Enabled = false
		e.benchPrompt = prompt(liftTop, "Equip parts", "Your plow", Enum.KeyCode.E, function() if e.mine then Api.OpenBuild() end end)
		e.benchPrompt.MaxActivationDistance = 16
		e.benchPrompt.Enabled = false
		-- Lift + car preview parts are CanQuery=false (mouse rays pass through), so the click target is an invisible box over the car.
		local box = Instance.new("Part")
		box.Name, box.Size, box.CFrame, box.Transparency = "CarClickBox", Vector3.new(14, 7, 14), liftTop.CFrame + Vector3.new(0, 3.6, 0), 1
		box.Anchored, box.CanCollide, box.CanTouch, box.CanQuery, box.CastShadow = true, false, false, true, false
		box.Parent = e.liftModel or m
		local cd = Instance.new("ClickDetector"); cd.MaxActivationDistance = 40; cd.Parent = box
		cd.MouseClick:Connect(function()
			-- 2026-10-08 (F26): Api.OpenBuild toggles, so a click that reaches the car behind the open equip window must not close it
			-- (nor stack a neighbour's inspect on it). With the window shut, a click on your own car opens it (the card / inspect close with it).
			if garageWindowOpen() then return end
			if e.mine then Api.OpenBuild() elseif (m:GetAttribute("OwnerUserId") or 0) ~= 0 then openInspect(m) end
		end)
		e.carClick = cd
		local hint = billboard(liftTop, UDim2.fromScale(7, 1.1), Vector3.new(0, 7.5, 0), 60)
		hint.Name, hint.Enabled = "EquipHint", false
		local ht = label(hint, 0, 1, 2); ht.Text, ht.TextColor3 = "\u{1F527} Click your car to equip", ICE
		e.equipHint = hint
	end
	local anchor = partOf(m, "OwnerAnchor") or partOf(m, "SignPanel") or liftTop
	local bb = billboard(anchor, UDim2.fromScale(9, 2.6), Vector3.new(0, 2.6, 0), 90)
	e.ownerBoard = bb
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
	for _, ped in pairs(e.peds) do
		if ped.anim and ped.anim:Alive() then ped.anim:Abort() end
		if ped.display then ped.display:Destroy() end
	end
	if inspecting == m then closeInspect() end
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

local lastShown -- roll-timer redraw key (see the cooldown loop below)
Api.Changed.Event:Connect(function() for _, e in pairs(bays) do if e.mine then refreshBay(e) end end; lastShown = nil end)
player:GetAttributeChangedSignal("GarageBay"):Connect(function()
	for _, e in pairs(bays) do refreshBay(e) end
	lastShown = nil -- redraw the roll timer on the new bay
	if myBayIndex() then task.delay(0.6, guide) end
end)

-- the roll reveal happens IN THE WORLD (no pop-up card); neighbours see it too
Api.Revealed = function(key, rank)
	local e = myBay()
	if e then playReveal(e, key, rank) end
end
-- 2026-10-09: your own roll plays the full reveal (PlowRollReveal). PlowShopClient calls RollBegin BEFORE asking the server, then
-- Resolve(partId, rank, onHandoff) with the server's answer, or Abort() when the roll is refused. Returns nil without a bay (old path).
Api.RollBegin = function(key, speed)
	local e = myBay()
	local ped = e and e.peds[key]
	if not ped or key == "Reserved" then return nil end
	if ped.anim and ped.anim:Alive() then ped.anim:Skip() end
	if ped.anim and ped.anim:Alive() then ped.anim:Abort() end
	local h = {}
	local anim
	anim = Reveal.Begin(ped, {
		onSettle = function(model, offset, hover, angle, id)
			if ped.anim ~= anim or not bays[e.model] then model:Destroy(); return end
			ped.anim = nil
			if ped.display then ped.display:Destroy() end
			model.Parent = ped.model
			ped.id, ped.display, ped.offset, ped.hover = id, model, offset, hover
			ped.phase = angle - os.clock() * 0.9 -- the idle spin carries on from the reveal's angle
			refreshBay(e) -- a newer offer on this pedestal (stale reveal) replaces the model here
		end,
		onRelease = function()
			if ped.anim == anim then ped.anim = nil end
			ped.id = nil -- rebuild the display from the bay attributes (the saved offer is untouched)
			if bays[e.model] then refreshBay(e) end
		end,
		onHandoff = function() if h.onHandoff then h.onHandoff() end end,
		speed = speed,
	})
	ped.anim = anim
	ped.display = nil -- the reveal sinks and removes the old part
	ped.id = "\0rolling"
	refreshBay(e)
	h.Resolve = function(id, rank, onHandoff) h.onHandoff = onHandoff; anim:Resolve(id, rank) end
	h.Abort = function() anim:Abort() end
	return h
end
-- Studio-only test hook (absent in live servers): plays the reveal for a chosen part / rarity on your own pedestal WITHOUT asking the
-- server, so no offer, price or odds change; the pedestal snaps back to its real offer afterwards. Args: key, partId, rank, delay, speed.
if RunService:IsStudio() then
	local bf = Instance.new("BindableFunction")
	bf.Name = "RollRevealTest"
	bf.Parent = gui
	bf.OnInvoke = function(key, id, rank, delay, speed)
		if not C.Parts[id or ""] then return "bad part" end
		local h = Api.RollBegin(key, speed)
		if not h then return "no bay" end
		task.delay(delay or 0.2, function() h.Resolve(id, rank, function() Api.Toast("(test) offer card would open now") end) end)
		return "ok"
	end
end
-- neighbours: a smaller reveal on that bay's pedestal (no camera, no card); rare ones also get the quiet chime
event.OnClientEvent:Connect(function(kind, bayIndex, key, rank)
	if kind ~= "BayReveal" or bayIndex == myBayIndex() then return end
	for m, e in pairs(bays) do
		if m:GetAttribute("BayIndex") == bayIndex then
			local ped = e.peds[key]
			if ped and (ped.top.Position - camPos()).Magnitude < 90 then
				local r = tonumber(rank) or 2
				task.delay(0.15, function()
					if not ped.top:IsDescendantOf(workspace) then return end
					Reveal.Mini(ped, r)
					if r >= C.Shop.BigRevealRank then
						local s = Instance.new("Sound")
						s.SoundId, s.Volume, s.RollOffMinDistance, s.RollOffMaxDistance = "rbxassetid://125078105193243", 0.35, 8, 70
						s.Parent = ped.top; s:Play(); Debris:AddItem(s, 5)
					end
				end)
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
					local base = ped.top.CFrame * CFrame.new(0, ped.hover + math.sin(t * 2 + (tonumber(ped.key) or 4)) * 0.25, 0) * CFrame.Angles(0, t * 0.9 + (ped.phase or 0), 0)
					ped.display:PivotTo(base * ped.offset:Inverse())
				end
			end
		end
	end
end)

-- 2026-10-06: visible roll cooldown on your own pedestals (server time from the RollReadyAt attribute; all pedestals share it)
local READY, WAIT = Color3.fromRGB(143, 211, 160), Color3.fromRGB(232, 176, 122) -- soft matte tones (calm style)
RunService.Heartbeat:Connect(function()
	local e = myBay()
	if not e then return end
	local left = math.max(0, (player:GetAttribute("RollReadyAt") or 0) - workspace:GetServerTimeNow())
	local len = math.max(0.1, player:GetAttribute("RollCooldownLen") or C.Shop.RollCooldown)
	local shown = math.floor(os.clock() * 10)
	if shown == lastShown then return end -- update ten times a second at most
	lastShown = shown
	local S = Api.State
	for key, ped in pairs(e.peds) do
		local o = S and S.Offers and S.Offers[key]
		local oleft, paused
		if o and Api.OfferLeft then oleft, paused = Api.OfferLeft(o) end
		local animating = ped.anim and ped.anim:Alive()
		if ped.cd and animating then -- 2026-10-09: the reveal is running: no offer timer yet
			ped.cd.fill.Size, ped.cd.fill.BackgroundColor3 = UDim2.fromScale(1, 1), Color3.fromRGB(143, 190, 230)
			ped.cd.text.Text = "\u{2744} ROLLING"
		elseif ped.cd and oleft then -- 2026-10-06: an offer on this pedestal: calm countdown until it is gone (RESERVE keeps it)
			local total = o.Protected and (C.Shop.ProtectedOfferSeconds or 60) or (C.Shop.OfferSeconds or 30)
			ped.cd.fill.Size = UDim2.fromScale(math.clamp(oleft / total, 0.08, 1), 1)
			ped.cd.fill.BackgroundColor3 = (oleft <= 8 and not paused) and WAIT or Color3.fromRGB(143, 190, 230)
			ped.cd.text.Text = paused and "OFFER - TIMER PAUSED" or ("OFFER GONE IN %ds"):format(math.ceil(oleft))
		elseif ped.cd then
			if left > 0 then
				ped.cd.fill.Size, ped.cd.fill.BackgroundColor3 = UDim2.fromScale(math.clamp(1 - left / len, 0.08, 1), 1), WAIT
				ped.cd.text.Text = ("ROLL IN %.1fs"):format(left)
			else
				ped.cd.fill.Size, ped.cd.fill.BackgroundColor3 = UDim2.fromScale(1, 1), READY
				ped.cd.text.Text = "\u{2744} ROLL READY!"
			end
		end
		local suffix = left > 0 and (" (%.1fs)"):format(left) or ""
		if ped.prompt and ped.rollPrompt and ped.baseAction then ped.prompt.ActionText = ped.baseAction .. suffix end
		if ped.reroll then ped.reroll.ActionText = "Reroll" .. suffix end
	end
end)

-- an open offer card closes when you walk away from your pedestal; the inspection panel closes when you walk away too;
-- 2026-10-08 (F31): so does the equip window (it used to stay open over the screen while the server refused Equip / LevelUp)
task.spawn(function()
	while true do
		task.wait(0.5)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local key = Api.CardTarget()
		local e = myBay()
		local ped = key and e and e.peds[key]
		if hrp and key and (not ped or (hrp.Position - ped.top.Position).Magnitude > 20) then Api.CloseCard() end
		if hrp and inspecting and inspecting.Parent then
			if (hrp.Position - inspecting:GetPivot().Position).Magnitude > 65 then closeInspect() end
		end
		if player:GetAttribute("InGarage") ~= true and panel.Visible then closeInspect() end
		if garageWindowOpen() then
			-- dead, no character yet, or farther from your own bay pivot than the server's BAY_REACH: the window cannot do anything, so close it
			local away = hrp and e and e.model.Parent and (hrp.Position - e.model:GetPivot().Position).Magnitude > BAY_REACH
			if not hrp or (hum and hum.Health <= 0) or away then pcall(Api.CloseBuild) end -- pcall: this loop must outlive a faulty override
		end
	end
end)
player:GetAttributeChangedSignal("InGarage"):Connect(function()
	if player:GetAttribute("InGarage") == true then Api.Toast("Find your bay and press E at a pedestal to roll a part!", ICE) end
end)
