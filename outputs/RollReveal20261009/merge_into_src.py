# Applies the 2026-10-09 part-roll reveal edits (made live in Studio) to the game/src copies, which also carry the
# not-yet-installed UI-audit changes (2026-10-08). Same anchors and replacements as the Studio edits. Run from the project root.
import sys

SRC = "game/src/"
G = SRC + "StarterPlayer/StarterPlayerScripts/PlowGarageClient.client.luau"
S = SRC + "StarterPlayer/StarterPlayerScripts/PlowShopClient.client.luau"
A = SRC + "ReplicatedStorage/PlowClientApi.luau"

EDITS = {
G: [
('local Debris = game:GetService("Debris")\n', 'local Debris = game:GetService("Debris")\nlocal UIS = game:GetService("UserInputService")\n'),
('local event = RS:WaitForChild("PlowEvent")\n', 'local event = RS:WaitForChild("PlowEvent")\nlocal Reveal = require(RS:WaitForChild("PlowRollReveal")) -- 2026-10-09: the pedestal part-roll reveal (presentation only)\nlocal touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled\n'),
('local function myBayIndex() return player:GetAttribute("GarageBay") end\n', '''local function myBayIndex() return player:GetAttribute("GarageBay") end
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
'''),
('''	for key, ped in pairs(e.peds) do
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
		end''', '''	for key, ped in pairs(e.peds) do
		if ped.anim and ped.anim:Alive() then -- 2026-10-09: a roll reveal owns this pedestal until it hands the part over
			ped.l1.Text, ped.l1.TextColor3 = "ROLLING...", ICE
			ped.l2.Text = mine and (touchOnly and "tap to skip" or "click to skip") or ""
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
		end'''),
('				p = "\\u{2744} " .. Format.Abbreviate(price) .. (snow >= price and "  READY!" or ("  need " .. Format.Abbreviate(math.ceil(price - snow))))',
 '				p = (key == "Reserved" and "" or "OFFER  ") .. "\\u{2744} " .. Format.Abbreviate(price) .. (snow >= price and "  READY!" or ("  need " .. Format.Abbreviate(math.ceil(price - snow))))'),
('				if not e.mine then return end\n				local S = Api.State', '				if not e.mine then return end\n				if ped.anim and ped.anim:Alive() then ped.anim:Skip(); return end -- E during a reveal = skip to the same result\n				local S = Api.State'),
('	if e.preview then e.preview:Destroy() end\n	for _, ped in pairs(e.peds) do if ped.display then ped.display:Destroy() end end',
 '	if e.preview then e.preview:Destroy() end\n	for _, ped in pairs(e.peds) do\n		if ped.anim and ped.anim:Alive() then ped.anim:Abort() end\n		if ped.display then ped.display:Destroy() end\n	end'),
('''event.OnClientEvent:Connect(function(kind, bayIndex, key, rank)
	if kind ~= "BayReveal" or bayIndex == myBayIndex() then return end
	for m, e in pairs(bays) do
		if m:GetAttribute("BayIndex") == bayIndex then
			if e.peds[key] and (e.peds[key].top.Position - camPos()).Magnitude < 90 then
				task.delay(0.15, function() playReveal(e, key, tonumber(rank) or 2) end)
			end
		end
	end
end)''', '''-- 2026-10-09: your own roll plays the full reveal (PlowRollReveal). PlowShopClient calls RollBegin BEFORE asking the server, then
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
	ped.id = "\\0rolling"
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
end)'''),
('* CFrame.Angles(0, t * 0.9, 0)\n					ped.display:PivotTo(base * ped.offset:Inverse())', '* CFrame.Angles(0, t * 0.9 + (ped.phase or 0), 0)\n					ped.display:PivotTo(base * ped.offset:Inverse())'),
('		if ped.cd and oleft then', '''		local animating = ped.anim and ped.anim:Alive()
		if ped.cd and animating then -- 2026-10-09: the reveal is running: no offer timer yet
			ped.cd.fill.Size, ped.cd.fill.BackgroundColor3 = UDim2.fromScale(1, 1), Color3.fromRGB(143, 190, 230)
			ped.cd.text.Text = "\\u{2744} ROLLING"
		elseif ped.cd and oleft then'''),
],
S: [
('		hdrText.Text = isRes and "YOUR RESERVED PART" or ("PEDESTAL " .. target .. " - FOR SALE!")', '		hdrText.Text = isRes and "YOUR RESERVED PART" or ("OFFER - PEDESTAL " .. target)'),
('''local function reveal(rank)
	local big = rank >= C.Shop.BigRevealRank
	local col = RCOL[C.Rarities[rank].Id]
''', '''local function reveal(rank, quiet) -- quiet (2026-10-09): the pedestal reveal already celebrated; the card only pops in
	local big = rank >= C.Shop.BigRevealRank
	local col = RCOL[C.Rarities[rank].Id]
	if quiet then
		cardScale.Scale = 0.9
		TweenService:Create(cardScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		glow.ImageTransparency = 0.65
		TweenService:Create(glow, TweenInfo.new(0.5), {ImageTransparency = 0.82}):Play()
		vp.Ambient, vp.LightColor = Color3.fromRGB(175, 175, 195), WHITE
		return
	end
'''),
('''local function doRoll(key, inCard)
	key = key or target
	local r = call("Roll", key)
	if r.ok then
		refreshAll()
		if inCard then''', '''-- 2026-10-09: the pedestal reveal (PlowRollReveal via Api.RollBegin) starts before the server call and only shows a part once the
-- server's answer is in; its handoff opens this card with BUY / RESERVE. One request per pedestal at a time; a refused roll undoes it.
local rolling = {}
local function doRoll(key, inCard)
	key = key or target
	if rolling[key] then return end
	rolling[key] = true
	local cardWasOpen = card.Visible and target or nil -- any open card (this or another pedestal) steps aside for the reveal
	local h = Api.RollBegin and Api.RollBegin(key)
	if h and cardWasOpen then card.Visible = false end -- the new offer's card comes at the handoff
	local r = call("Roll", key)
	rolling[key] = nil
	local o = r.ok and state and state.Offers and state.Offers[key]
	if h then
		if o then
			refreshAll()
			local rank = r.rank or 2
			h.Resolve(o.Part, rank, function()
				if player:GetAttribute("InGarage") ~= true then return end
				local now = state and state.Offers and state.Offers[key]
				if not now or now.Token ~= o.Token then return end -- a newer roll or a purchase replaced it
				target = key
				showCard(true)
				reveal(rank, true)
			end)
			return
		end
		h.Abort()
		if cardWasOpen then target = cardWasOpen; showCard(true) end
	end
	if r.ok then
		refreshAll()
		if inCard then'''),
('hdrText.Text = ("PEDESTAL %s - %s"):format(target, paused and "TIMER PAUSED"', 'hdrText.Text = ("OFFER %s - %s"):format(target, paused and "TIMER PAUSED"'),
],
A: [
('Api.CardTarget = function() return nil end', 'Api.RollBegin = function() return nil end -- (slotKey) 2026-10-09: start the pedestal reveal; returns {Resolve(partId, rank, onHandoff), Abort()} or nil\nApi.CardTarget = function() return nil end'),
],
}

ok = True
for path, edits in EDITS.items():
    raw = open(path, "rb").read().decode("utf-8")
    crlf = "\r\n" in raw
    s = raw.replace("\r\n", "\n")
    for old, new in edits:
        n = s.count(old)
        if n != 1:
            print("ANCHOR", n, path, repr(old[:70])); ok = False; continue
        s = s.replace(old, new, 1)
    if "--dry" not in sys.argv and ok:
        out = s.replace("\n", "\r\n") if crlf else s
        open(path, "wb").write(out.encode("utf-8"))
    print(path, "crlf" if crlf else "lf", len(s))
print("OK" if ok else "FAILED (nothing written for failing files)")
