-- TreasureBook (2026-10-01, Claude; PNG v2): the Treasures collection book. Pictures come from TreasureIcon. Panel = RNGGui.Panels.Treasures, opened by the
-- LeftMenu "Treasures" button through RNGClient's normal panel logic (blur, one panel at a time, Close).
-- Biome tabs, discovered items (name, rarity, quantity), silhouettes, NEW DISCOVERY badges, odds, sound/effects settings.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TC = require(RS:WaitForChild("TreasureConfig"))
local Models = require(RS:WaitForChild("TreasureModels")) -- only the 3D chest fallback for the menu icon
local TreasureIcon = require(RS:WaitForChild("TreasureIcon"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local treasureRemote = RS:WaitForChild("TreasureRemote")
local found = RS:WaitForChild("TreasureFound")
local player = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Panels"):WaitForChild("Treasures")
local button = gui:WaitForChild("LeftMenu"):WaitForChild("Treasures")
local inner = panel:WaitForChild("Inner")

local FONT = Enum.Font.FredokaOne
local NAVY, WHITE = Color3.fromRGB(25, 45, 90), Color3.new(1, 1, 1)
local RED = Color3.fromRGB(235, 60, 70)
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 95, 120)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 230, 130)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 115, 255)),
})

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) mk("UICorner", {CornerRadius = UDim.new(r, 0)}, o) end
local function stroke(o, t, c) return mk("UIStroke", {Thickness = t, Color = c or NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function label(parent, text, props, st)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Font, l.TextScaled, l.TextColor3, l.Text = 1, FONT, true, WHITE, text
	for k, v in pairs(props) do l[k] = v end
	if st ~= false then mk("UIStroke", {Thickness = st or 2.2, Color = NAVY}, l) end
	l.Parent = parent
	return l
end
local function viewport(parent, model, props, camPos)
	local vp = mk("ViewportFrame", {BackgroundTransparency = 1, Ambient = Color3.fromRGB(195, 195, 210), LightColor = WHITE, LightDirection = Vector3.new(-1, -1.2, -1)}, nil)
	for k, v in pairs(props) do vp[k] = v end
	local cam = mk("Camera", {FieldOfView = 40}, vp)
	cam.CFrame = CFrame.lookAt(camPos or Vector3.new(0, 0.3, 4.8), Vector3.zero)
	vp.CurrentCamera = cam
	model.Parent = vp
	vp.Parent = parent
	return vp
end

-- 3D chest icons where the cloned Index art used to be
for _, holder in ipairs({button, panel}) do
	local list = holder:GetDescendants()
	table.insert(list, holder)
	for _, d in ipairs(list) do
		if d:GetAttribute("TreasureIcon") then
			local menuImg = (TC.Images and TC.Images.MenuIcon ~= "") and TC.Images.MenuIcon or nil
			if menuImg then
				mk("ImageLabel", {Name = "ChestIcon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.95, 0.95), ScaleType = Enum.ScaleType.Fit, Image = menuImg, ZIndex = d.ZIndex}, d)
			else -- 3D chest until a MenuIcon PNG is set
				viewport(d, Models.Chest(), {Name = "ChestIcon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.95, 0.95), ZIndex = d.ZIndex}, Vector3.new(2.7, 2.0, 3.7))
			end
		end
	end
end
-- red badge on the menu button: unseen NEW discoveries
local badge = mk("Frame", {Name = "NewBadge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.12), Size = UDim2.fromScale(0.34, 0.34), BackgroundColor3 = RED, Visible = false, ZIndex = 10}, button)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, badge)
round(badge, 1)
stroke(badge, 2.5, WHITE)
local badgeL = label(badge, "!", {Position = UDim2.fromScale(0.15, 0.12), Size = UDim2.fromScale(0.7, 0.76), ZIndex = 11}, 1.5)

-- book layout inside the cloned panel
local content = inner:FindFirstChild("Content")
if content then content.Visible = false end
local book = mk("Frame", {Name = "TreasureBook", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, inner)
-- 2026-10-03 (Claude, alignment pass): the tab row, title row, cards and footer all use the card row's left/right edges
local CARD_W, CARD_GAP, TAB_GAP, TOGGLE_W = 0.18, 0.012, 0.008, 0.18
local ROW_W = 5 * CARD_W + 4 * CARD_GAP -- five treasures per biome
local EDGE = (1 - ROW_W) / 2
local tabs = mk("Frame", {Name = "Tabs", BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.015), Size = UDim2.new(1, 0, 0.115, 0)}, book)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(TAB_GAP, 0), SortOrder = Enum.SortOrder.LayoutOrder}, tabs)
-- 2026-10-03 (Claude, redo): rows = biome tabs | world switch + collection title + settings | cards | footer. Small controls and
-- cards skip SnowUI's frost overlay (its 13 px rim swallowed the tabs and its corners never matched the outlines).
local function nodecor(o) o:SetAttribute("SnowUIDecor", true); return o end
local ROW_B, ROW_B_H, WORLD_W = 0.155, 0.08, 0.15
local title = label(book, "", {Position = UDim2.fromScale(EDGE, ROW_B), Size = UDim2.fromScale(0.4, ROW_B_H), TextXAlignment = Enum.TextXAlignment.Left}, 2.5)
local function toggle(x)
	local b = nodecor(mk("TextButton", {Text = "", AutoButtonColor = true, BackgroundColor3 = WHITE, Position = UDim2.fromScale(x, ROW_B), Size = UDim2.fromScale(TOGGLE_W, ROW_B_H)}, book))
	round(b, 1)
	stroke(b, 2.5)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(214, 226, 244))}, b)
	return b, label(b, "", {Position = UDim2.fromScale(0.08, 0.14), Size = UDim2.fromScale(0.84, 0.72), TextColor3 = NAVY}, false)
end
local soundBtn, soundL = toggle(1 - EDGE - 2 * TOGGLE_W - CARD_GAP)
local fxBtn, fxL = toggle(1 - EDGE - TOGGLE_W)
local grid = mk("Frame", {Name = "Cards", BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.265), Size = UDim2.new(1, 0, 0.59, 0)}, book)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(CARD_GAP, 0), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
local bonuses = {}
for _, r in ipairs(TC.Rarities) do table.insert(bonuses, r.Bonus .. "×") end
local foot = label(book, "", {Position = UDim2.fromScale(EDGE, 0.87), Size = UDim2.fromScale(ROW_W, 0.12), TextWrapped = true, RichText = true, TextColor3 = NAVY}, false)
mk("UITextSizeConstraint", {MaxTextSize = 20}, foot)
foot.Text = ("Every fully dug tile has a <b>1 in %d</b> chance to hide one of this biome's treasures. Rarer finds give more Snow: <b>%s</b> a tile's Snow, boosted by your multipliers. Luck doesn't change these odds. Your first treasure is guaranteed!")
	:format(math.floor(1 / TC.TileChance + 0.5), table.concat(bonuses, ", "))

local data = {Treasures = {}, New = {}, Found = 0}
local current, lastFoundBiome = "Starter", nil
local spinners, tabButtons = {}, {}
local worldLabel -- WORLD 1 / WORLD 2 switch (2026-10-02, Claude); tabs show one world's collections at a time
local seenToken = 0

local function newCount() local n = 0 for _ in pairs(data.New) do n += 1 end return n end
local function updateBadge()
	local n = newCount()
	badge.Visible = n > 0
	badgeL.Text = n > 9 and "9+" or tostring(n)
end
local function ownedIn(b) local n = 0 for _, it in ipairs(b.Items) do if (tonumber(data.Treasures[it.Id]) or 0) > 0 then n += 1 end end return n end
local function newIn(b) for _, it in ipairs(b.Items) do if data.New[it.Id] then return true end end return false end
local function updateToggles()
	soundL.Text = player:GetAttribute("TreasureSoundOff") and "SOUND: OFF" or "SOUND: ON"
	fxL.Text = player:GetAttribute("TreasureReduced") and "EFFECTS: REDUCED" or "EFFECTS: FULL"
end

local function card(item, order)
	local rar = TC.RarityById[item.Rarity]
	local count = tonumber(data.Treasures[item.Id]) or 0
	local owned = count > 0
	local f = nodecor(mk("Frame", {Name = item.Id, LayoutOrder = order, Size = UDim2.fromScale(CARD_W, 0.97), BackgroundColor3 = WHITE}, grid))
	round(f, 0.12)
	stroke(f, 3.5, owned and rar.Color:Lerp(Color3.new(0, 0, 0), 0.35) or Color3.fromRGB(120, 130, 155))
	mk("UIGradient", {Rotation = 90, Color = (not owned) and ColorSequence.new(Color3.fromRGB(220, 226, 238), Color3.fromRGB(176, 186, 206))
		or (item.Rarity == "Mythic" and RAINBOW) or ColorSequence.new(rar.Color:Lerp(WHITE, 0.65), rar.Color:Lerp(WHITE, 0.15))}, f)
	local box = mk("Frame", {Name = "IconBox", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.86, 0.48), BackgroundTransparency = 1, ZIndex = 2}, f)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, box)
	TreasureIcon.Create(item, {Silhouette = not owned, ZIndex = 2}).Parent = box -- undiscovered: dark silhouette / "?"
	if owned then table.insert(spinners, box) end
	label(f, owned and item.Name or "???", {Position = UDim2.fromScale(0.05, 0.56), Size = UDim2.fromScale(0.9, 0.12)}, 2.2)
	local pill = nodecor(mk("Frame", {BackgroundColor3 = WHITE, Position = UDim2.fromScale(0.13, 0.7), Size = UDim2.fromScale(0.74, 0.1)}, f))
	round(pill, 1)
	mk("UIGradient", {Color = item.Rarity == "Mythic" and RAINBOW or ColorSequence.new(rar.Color)}, pill)
	stroke(pill, 2)
	label(pill, string.upper(item.Rarity), {Position = UDim2.fromScale(0.06, 0.1), Size = UDim2.fromScale(0.88, 0.8)}, 1.6)
	label(f, "1 in " .. NumberFormat.Abbreviate(rar.OneIn) .. " tiles", {Position = UDim2.fromScale(0.05, 0.83), Size = UDim2.fromScale(0.9, 0.09), TextColor3 = NAVY}, false)
	if owned then
		local cb = nodecor(mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.84, 0.05), Size = UDim2.fromScale(0.36, 0.1), BackgroundColor3 = Color3.fromRGB(255, 215, 60), ZIndex = 3}, f))
		round(cb, 1)
		stroke(cb, 2.5)
		label(cb, "x" .. NumberFormat.Abbreviate(count), {Position = UDim2.fromScale(0.1, 0.1), Size = UDim2.fromScale(0.8, 0.8), TextColor3 = NAVY, ZIndex = 4}, false)
	end
	if data.New[item.Id] then
		local nb = nodecor(mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.98, 0.1), Rotation = -6, BackgroundColor3 = Color3.fromRGB(255, 220, 60), ZIndex = 5}, f))
		round(nb, 0.5)
		stroke(nb, 2.5)
		label(nb, "NEW DISCOVERY!", {Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), TextColor3 = NAVY, ZIndex = 6}, false)
	end
end

-- 2026-10-03 (Claude, alignment pass): one text size for every visible biome tab name (the longest name decides), so CRYSTAL and
-- ABS. ZERO are not smaller than RETRO. Boxes are measured without UIScale (panel pop-in, selected tab), so the size is stable.
local TextService = game:GetService("TextService")
local lastFit
local function unscaledSize(o)
	local s, p = 1, o
	while p and p ~= gui do
		local u = p:FindFirstChildOfClass("UIScale")
		if u then s *= u.Scale end
		p = p.Parent
	end
	return o.AbsoluteSize / math.max(s, 0.01)
end
local function fitTabNames()
	local labels, key = {}, {}
	for _, tb in pairs(tabButtons) do
		if tb.name and tb.button.Visible then
			local box = unscaledSize(tb.name)
			if box.X < 8 or box.Y < 8 then return end -- not laid out yet
			table.insert(labels, {tb.name, box})
			table.insert(key, math.floor(box.X / 4) .. "x" .. math.floor(box.Y / 4))
		end
	end
	table.sort(key)
	local k = table.concat(key, ",")
	if #labels == 0 or k == lastFit then return end
	lastFit = k
	local best = 32
	for _, e in ipairs(labels) do
		local l, box = e[1], e[2]
		local lo, hi = 6, best
		while lo < hi do
			local mid = math.ceil((lo + hi) / 2)
			local sz = TextService:GetTextSize(l.Text, mid, l.Font, Vector2.new(10000, 10000))
			if sz.X <= box.X - 4 and sz.Y <= box.Y then lo = mid else hi = mid - 1 end
		end
		best = lo
	end
	for _, e in ipairs(labels) do e[1].TextScaled = false; e[1].TextSize = best end
end

local function render()
	for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	table.clear(spinners)
	local b = TC.BiomeById[current]
	local world = b.World or 1
	for id, tb in pairs(tabButtons) do if tb.button then tb.button.Visible = (TC.BiomeById[id].World or 1) == world end end
	-- equal-width tabs that exactly span the card row, whichever world is showing
	local shown = {}
	for _, c in ipairs(tabs:GetChildren()) do if c:IsA("GuiButton") and c.Visible then table.insert(shown, c) end end
	local tabW = (ROW_W - (#shown - 1) * TAB_GAP) / math.max(1, #shown)
	for _, c in ipairs(shown) do c.Size = UDim2.fromScale(tabW, c.Name == current and 1 or 0.86) end
	task.defer(fitTabNames)
	if worldLabel then worldLabel.Text = "WORLD " .. world .. " ⇄" end
	title.Text = string.upper(b.Name) .. "   " .. ownedIn(b) .. "/" .. #b.Items
	for i, it in ipairs(b.Items) do card(it, i) end
	for id, t in pairs(tabButtons) do
		local sel = id == current
		t.stroke.Thickness = sel and 3.5 or 2.5
		t.stroke.Color = sel and WHITE or NAVY
		t.scale.Scale = 1 -- the open tab is taller instead (sized above); scaling pushed the row past the card edges
		t.button.BackgroundColor3 = sel and TC.BiomeById[id].Color or TC.BiomeById[id].Color:Lerp(NAVY, 0.2)
		t.dot.Visible = newIn(TC.BiomeById[id])
		t.count.Text = ownedIn(TC.BiomeById[id]) .. "/" .. #TC.BiomeById[id].Items
	end
	updateToggles()
	updateBadge()
end

-- NEW badges stay visible while you look; they clear on the server after 1.5 s on that tab
local function markSeenSoon()
	seenToken += 1
	local token, biome = seenToken, current
	task.delay(1.5, function()
		if token ~= seenToken or not panel.Visible then return end
		local ids = {}
		for _, it in ipairs(TC.BiomeById[biome].Items) do if data.New[it.Id] then table.insert(ids, it.Id) end end
		if #ids == 0 then return end
		for _, id in ipairs(ids) do data.New[id] = nil end
		updateBadge()
		if tabButtons[biome] then tabButtons[biome].dot.Visible = false end
		pcall(function() treasureRemote:InvokeServer("Seen", ids) end)
	end)
end

for i, b in ipairs(TC.Biomes) do
	local t = nodecor(mk("TextButton", {Name = b.Id, Text = "", LayoutOrder = i, AutoButtonColor = true, BackgroundColor3 = b.Color, Size = UDim2.fromScale(0.1, 0.9)}, tabs))
	round(t, 0.3)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 215, 235))}, t) -- soft top-lit look
	local st = stroke(t, 2.5)
	local scale = mk("UIScale", {Scale = 1}, t)
	local name = label(t, b.Tab, {Position = UDim2.fromScale(0.06, 0.06), Size = UDim2.fromScale(0.88, 0.55)}, 2)
	name:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitTabNames)
	local count = label(t, "", {Position = UDim2.fromScale(0.2, 0.6), Size = UDim2.fromScale(0.6, 0.34)}, 1.6)
	local dot = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.94, 0.1), Size = UDim2.fromScale(0.2, 0.2), BackgroundColor3 = RED, Visible = false, ZIndex = 4}, t)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, dot)
	round(dot, 1)
	stroke(dot, 2, WHITE)
	tabButtons[b.Id] = {stroke = st, scale = scale, dot = dot, count = count, button = t, name = name}
	t.Activated:Connect(function()
		current = b.Id
		render()
		markSeenSoon()
	end)
end
do -- WORLD switch: first button in the tab row, flips to the other world's first collection
	local has2 = false
	for _, b in ipairs(TC.Biomes) do if (b.World or 1) == 2 then has2 = true end end
	if has2 then
		local wb = nodecor(mk("TextButton", {Name = "WorldSwitch", Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(255, 214, 90),
			Position = UDim2.fromScale(EDGE, ROW_B), Size = UDim2.fromScale(WORLD_W, ROW_B_H)}, book))
		round(wb, 1)
		stroke(wb, 2.5)
		mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(232, 214, 168))}, wb)
		title.Position = UDim2.fromScale(EDGE + WORLD_W + CARD_GAP, ROW_B) -- the collection title sits right of the world switch
		worldLabel = label(wb, "WORLD 1 ⇄", {Position = UDim2.fromScale(0.06, 0.15), Size = UDim2.fromScale(0.88, 0.7), TextColor3 = NAVY}, false)
		wb.Activated:Connect(function()
			local cur = TC.BiomeById[current].World or 1
			for _, b in ipairs(TC.Biomes) do if (b.World or 1) ~= cur then current = b.Id; break end end
			render()
			markSeenSoon()
		end)
	end
end

local function saveSettings()
	pcall(function()
		treasureRemote:InvokeServer("Settings", {Sound = not player:GetAttribute("TreasureSoundOff"), Reduced = player:GetAttribute("TreasureReduced") == true})
	end)
end
soundBtn.Activated:Connect(function()
	player:SetAttribute("TreasureSoundOff", not player:GetAttribute("TreasureSoundOff"))
	updateToggles()
	task.spawn(saveSettings)
end)
fxBtn.Activated:Connect(function()
	player:SetAttribute("TreasureReduced", not player:GetAttribute("TreasureReduced"))
	updateToggles()
	task.spawn(saveSettings)
end)

local function fetch()
	local ok, res = pcall(function() return treasureRemote:InvokeServer("Get") end)
	if ok and type(res) == "table" then
		data.Treasures, data.New, data.Found = res.Treasures or {}, res.New or {}, res.Found or 0
		if player:GetAttribute("TreasureSoundOff") == nil then player:SetAttribute("TreasureSoundOff", res.Sound == false) end
		if player:GetAttribute("TreasureReduced") == nil then player:SetAttribute("TreasureReduced", res.Reduced == true) end
		return true
	end
	return false
end

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if not panel.Visible then return end
	if lastFoundBiome then current, lastFoundBiome = lastFoundBiome, nil end
	render()
	task.spawn(function()
		fetch()
		if panel.Visible then render(); markSeenSoon() end
	end)
end)

found.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" or info.Announce or not TC.ById[info.Id] then return end
	data.Treasures[info.Id] = info.Count or ((tonumber(data.Treasures[info.Id]) or 0) + 1)
	if info.New then data.New[info.Id] = true end
	data.Found += 1
	lastFoundBiome = TC.ById[info.Id].Biome
	updateBadge()
	if panel.Visible and lastFoundBiome == current then render() end
end)

RunService.RenderStepped:Connect(function()
	if not panel.Visible or #spinners == 0 then return end
	local t = os.clock()
	for i, box in ipairs(spinners) do if box.Parent then box.Rotation = math.sin(t * 1.6 + i) * 4 end end
end)

render()
task.spawn(function()
	for _ = 1, 10 do if fetch() then break end task.wait(1) end
	updateBadge()
end)
