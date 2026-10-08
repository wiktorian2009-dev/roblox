-- MachinesClient (2026-10-03, Claude): panels for the three lobby machines - Shovel Forge, Hot Cocoa Machine, Pet Fuser
-- (RNGGui.Panels.Forge / Cocoa / Fuser). The machines' prompts open them through the normal panel logic (VillageOpenMenu);
-- MachineService (server) does all the work. Also gives the 3D machines a little local animation.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Prompts = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local Config = require(RS:WaitForChild("RNGConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local PetModels = require(RS:WaitForChild("PetModels"))
local SnowUI = require(RS:WaitForChild("SnowUI"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local M = require(RS:WaitForChild("MachineConfig"))
local player = Players.LocalPlayer
local gui = script.Parent
local panels = gui:WaitForChild("Panels")
local openMenu = gui:WaitForChild("VillageOpenMenu")
local remote = RS:WaitForChild("MachineRemote")

local FONT = Enum.Font.FredokaOne
local NAVY = Color3.fromRGB(25, 45, 90)
local WHITE = Color3.new(1, 1, 1)
local SLATE = Color3.fromRGB(90, 108, 145)
local GREY_A, GREY_B = Color3.fromRGB(190, 198, 214), Color3.fromRGB(140, 150, 172)
local LEFT = Enum.TextXAlignment.Left
local MUT_COLOR = {Giant = Color3.fromRGB(60, 150, 255), Shiny = Color3.fromRGB(240, 175, 20), ["Shiny Giant"] = Color3.fromRGB(175, 95, 255)}

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
-- everything here skips SnowUI's automatic frost overlay (same clean style as the other menus)
local function frame(parent, props)
	local f = mk("Frame", {BorderSizePixel = 0}, nil)
	f:SetAttribute("SnowUIDecor", true)
	for k, v in pairs(props) do f[k] = v end
	f.Parent = parent
	return f
end
local function round(o, r) mk("UICorner", {CornerRadius = UDim.new(r or 0.5, 0)}, o) return o end
local function outline(o, t, c) return mk("UIStroke", {Thickness = t, Color = c or NAVY, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function grad(o, a, b) return mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(a, b)}, o) end
local function text(parent, str, props, max, st)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, Text = str, TextScaled = true, TextWrapped = true, TextColor3 = WHITE, Size = UDim2.fromScale(1, 1)}, nil)
	for k, v in pairs(props or {}) do l[k] = v end
	if st ~= false then mk("UIStroke", {Thickness = st or 2, Color = NAVY}, l) end
	mk("UITextSizeConstraint", {MaxTextSize = max or 30}, l)
	l.Parent = parent
	return l
end
local function button(parent, props)
	local b = mk("TextButton", {Text = "", AutoButtonColor = true, BorderSizePixel = 0}, nil)
	b:SetAttribute("SnowUIDecor", true)
	for k, v in pairs(props) do b[k] = v end
	b.Parent = parent
	return b
end
local function image(parent, id, pos, size)
	local i = mk("ImageLabel", {BackgroundTransparency = 1, Image = id or "", ScaleType = Enum.ScaleType.Fit, Position = pos, Size = size}, nil)
	i:SetAttribute("SnowUIDecor", true)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, i)
	i.Parent = parent
	return i
end
local function petIcon(parent, name, pos, size)
	local vp = mk("ViewportFrame", {BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 210), LightColor = WHITE, LightDirection = Vector3.new(-1, -1, -1), Position = pos, Size = size}, nil)
	vp:SetAttribute("SnowUIDecor", true)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, vp)
	vp.Parent = parent
	local ok, model = pcall(PetModels.create, name)
	if ok and model then
		model.Parent = vp
		local cf, sz = model:GetBoundingBox()
		local look = model:GetPivot().LookVector
		local dist = math.max(sz.X, sz.Y, sz.Z) * 2 + 0.5
		local cam = mk("Camera", {FieldOfView = 35}, vp)
		cam.CFrame = CFrame.lookAt(cf.Position + look * dist + Vector3.new(0, dist * 0.25, 0), cf.Position)
		vp.CurrentCamera = cam
	end
	return vp
end
local function call(...)
	local args = table.pack(...)
	local ok, res = pcall(function() return remote:InvokeServer(table.unpack(args, 1, args.n)) end)
	if ok and type(res) == "table" then return res end
	return {Ok = false, Msg = "Try again in a moment"}
end
local function clear(o) for _, c in ipairs(o:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
local tokens = {}
local function flash(label, base, msg, good)
	local t = (tokens[label] or 0) + 1
	tokens[label] = t
	label.Text = msg
	label.TextColor3 = good and Color3.fromRGB(205, 255, 215) or Color3.fromRGB(255, 220, 225)
	task.delay(3, function() if tokens[label] == t then label.Text = base; label.TextColor3 = WHITE end end)
end
local function setButton(b, label, on, a, z, str)
	label.Text = str
	b:FindFirstChildOfClass("UIGradient").Color = on and ColorSequence.new(a, z) or ColorSequence.new(GREY_A, GREY_B)
end

-- shared page: coloured header strip (emoji, title, hint) + list area
local function makePage(name, title, hint, emoji, color, scroll)
	local panel = panels:WaitForChild(name)
	local inner = panel:WaitForChild("Inner")
	local old = inner:FindFirstChild("Content")
	if old then old.Visible = false end
	local banner = panel:FindFirstChild("Banner")
	local icon = banner and banner:FindFirstChild("Icon")
	if icon then icon.Image = ""; text(icon, emoji, {Position = UDim2.fromScale(0.1, 0.1), Size = UDim2.fromScale(0.8, 0.8)}, 100, false) end
	local root = frame(inner, {Name = "MachinePage", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
	local head = frame(root, {Name = "Header", BackgroundColor3 = WHITE, Position = UDim2.fromScale(0.02, 0.02), Size = UDim2.fromScale(0.96, 0.17)})
	round(head, 0.3); outline(head, 3); grad(head, color:Lerp(WHITE, 0.2), color:Lerp(NAVY, 0.12))
	text(head, emoji, {Position = UDim2.fromScale(0.01, 0.1), Size = UDim2.fromScale(0.09, 0.8)}, 60, false)
	text(head, title, {Position = UDim2.fromScale(0.11, 0.08), Size = UDim2.fromScale(0.87, 0.5), TextXAlignment = LEFT}, 34)
	local hintL = text(head, hint, {Position = UDim2.fromScale(0.11, 0.58), Size = UDim2.fromScale(0.87, 0.32), TextXAlignment = LEFT}, 20)
	local area
	if scroll then
		area = mk("ScrollingFrame", {Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromScale(0.02, 0.22), Size = UDim2.fromScale(0.96, 0.76),
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 7, ScrollBarImageColor3 = WHITE}, root)
		mk("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12)}, area)
		mk("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, area)
	else
		area = frame(root, {Name = "Area", BackgroundTransparency = 1, Position = UDim2.fromScale(0.02, 0.22), Size = UDim2.fromScale(0.96, 0.76)})
	end
	return panel, area, hintL, hint
end
local function row(list, order)
	local r = frame(list, {Name = "Row", LayoutOrder = order, BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1)})
	mk("UIAspectRatioConstraint", {AspectRatio = 7.4, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize}, r)
	round(r, 0.25); outline(r, 3); grad(r, WHITE, Color3.fromRGB(222, 232, 248))
	return r
end
local function rowButton(r, a, z)
	local b = button(r, {BackgroundColor3 = WHITE, Position = UDim2.fromScale(0.8, 0.17), Size = UDim2.fromScale(0.185, 0.66)})
	round(b, 0.3); outline(b, 3); grad(b, a, z)
	local l = text(b, "", {Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76)}, 26)
	return b, l
end
local function emptyNote(list, msg)
	local f = frame(list, {Name = "Empty", BackgroundTransparency = 1, LayoutOrder = 1, Size = UDim2.fromScale(1, 1)})
	mk("UIAspectRatioConstraint", {AspectRatio = 5, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize}, f)
	text(f, msg, {}, 26)
end
local function sortReady(list)
	for i, e in ipairs(list) do e.Order = i end
	table.sort(list, function(a, b)
		local ra, rb = a.Spare >= a.Need, b.Spare >= b.Need
		if ra ~= rb then return ra end
		return a.Order < b.Order
	end)
end

--------------------------------------------------
-- SHOVEL FORGE
--------------------------------------------------
local FORGE_A, FORGE_Z = Color3.fromRGB(255, 185, 90), Color3.fromRGB(240, 120, 40)
local forgePanel, forgeList, forgeHint, forgeBase = makePage("Forge", "SHOVEL FORGE", "Melt spare shovels into a rarer one! Equipped shovels and your last copy are safe.", "\u{1F528}", Color3.fromRGB(255, 140, 60), true)
local renderForge
renderForge = function(res)
	clear(forgeList)
	local list = res and res.List or {}
	if #list == 0 then emptyNote(forgeList, "Roll more shovels - you need spare copies to forge!") return end
	sortReady(list)
	for i, e in ipairs(list) do
		local r = row(forgeList, i)
		local from, to = Config.ByName[e.From], Config.ByName[e.To]
		image(r, from and from.ImageId, UDim2.fromScale(0.012, 0.1), UDim2.fromScale(0.12, 0.8))
		text(r, e.Need .. " x " .. e.From, {Position = UDim2.fromScale(0.105, 0.12), Size = UDim2.fromScale(0.29, 0.44), TextXAlignment = LEFT, TextColor3 = NAVY}, 24, false)
		text(r, ("You have %d (%d spare)"):format(e.Have, e.Spare), {Position = UDim2.fromScale(0.105, 0.56), Size = UDim2.fromScale(0.29, 0.3), TextXAlignment = LEFT, TextColor3 = SLATE}, 18, false)
		text(r, "\u{2192}", {Position = UDim2.fromScale(0.4, 0.2), Size = UDim2.fromScale(0.05, 0.6), TextColor3 = NAVY}, 40, false)
		image(r, to and to.ImageId, UDim2.fromScale(0.455, 0.1), UDim2.fromScale(0.12, 0.8))
		text(r, e.To, {Position = UDim2.fromScale(0.548, 0.12), Size = UDim2.fromScale(0.245, 0.44), TextXAlignment = LEFT, TextColor3 = NAVY}, 22, false)
		text(r, string.upper(e.ToMutation or ""), {Position = UDim2.fromScale(0.548, 0.56), Size = UDim2.fromScale(0.245, 0.3), TextXAlignment = LEFT, TextColor3 = MUT_COLOR[e.ToMutation] or SLATE}, 18, 1.5)
		local ready = e.Spare >= e.Need
		local b, l = rowButton(r, FORGE_A, FORGE_Z)
		setButton(b, l, ready, FORGE_A, FORGE_Z, ready and "FORGE!" or ("NEED " .. e.Need))
		b.Activated:Connect(function()
			local res2 = call("Forge", e.Recipe, e.From)
			flash(forgeHint, forgeBase, res2.Msg or "", res2.Ok)
			if res2.List then renderForge(res2) end
		end)
	end
end
forgePanel:GetPropertyChangedSignal("Visible"):Connect(function() if forgePanel.Visible then renderForge(call("ForgeList")) end end)

--------------------------------------------------
-- HOT COCOA MACHINE
--------------------------------------------------
local BUY_A, BUY_Z = Color3.fromRGB(120, 235, 140), Color3.fromRGB(40, 175, 80)
local cocoaPanel, cocoaArea, cocoaHint, cocoaBase = makePage("Cocoa", "HOT COCOA", "Warm drinks give you a boost! The price is a few minutes of your own digging.", "\u{2615}", Color3.fromRGB(190, 120, 70), false)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.025, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, cocoaArea)
local lastCocoa
local renderCocoa
renderCocoa = function(res)
	lastCocoa = res
	clear(cocoaArea)
	local snow = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Snow") and player.leaderstats.Snow.Value or tonumber(res and res.Snow) or 0
	for i, e in ipairs(res and res.List or {}) do
		local dr = M.Cocoa.Drinks[i] or {}
		local color = dr.Color or Color3.fromRGB(200, 150, 100)
		local c = frame(cocoaArea, {Name = "Drink" .. i, LayoutOrder = i, BackgroundColor3 = WHITE, Size = UDim2.fromScale(0.31, 0.97)})
		round(c, 0.12); outline(c, 3); grad(c, color:Lerp(WHITE, 0.72), color:Lerp(WHITE, 0.35))
		text(c, "\u{2615}", {Position = UDim2.fromScale(0.15, 0.03), Size = UDim2.fromScale(0.7, 0.36)}, 100, false)
		image(c, SnowUI.Assets[dr.Icon or "snow"], UDim2.fromScale(0.64, 0.24), UDim2.fromScale(0.24, 0.17))
		text(c, e.Name, {Position = UDim2.fromScale(0.05, 0.41), Size = UDim2.fromScale(0.9, 0.12), TextColor3 = NAVY}, 28, false)
		text(c, e.Effect, {Position = UDim2.fromScale(0.05, 0.54), Size = UDim2.fromScale(0.9, 0.1), TextColor3 = SLATE}, 20, false)
		text(c, "\u{2744} " .. NumberFormat.Abbreviate(e.Price), {Position = UDim2.fromScale(0.05, 0.65), Size = UDim2.fromScale(0.9, 0.12), TextColor3 = NAVY}, 28, false)
		local b = button(c, {BackgroundColor3 = WHITE, Position = UDim2.fromScale(0.08, 0.8), Size = UDim2.fromScale(0.84, 0.15)})
		round(b, 0.3); outline(b, 3); grad(b, BUY_A, BUY_Z)
		local l = text(b, "", {Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76)}, 26)
		local can = snow >= e.Price
		setButton(b, l, can, BUY_A, BUY_Z, can and "BUY" or "NOT ENOUGH")
		b.Activated:Connect(function()
			local res2 = call("Drink", i)
			flash(cocoaHint, cocoaBase, res2.Msg or "", res2.Ok)
			if res2.List then renderCocoa(res2) end
		end)
	end
end
cocoaPanel:GetPropertyChangedSignal("Visible"):Connect(function() if cocoaPanel.Visible then renderCocoa(call("CocoaList")) end end)
task.spawn(function() -- buttons follow your Snow while the panel is open
	local stats = player:WaitForChild("leaderstats", 60)
	local snow = stats and stats:WaitForChild("Snow", 60)
	if not snow then return end
	local pending = false
	snow.Changed:Connect(function()
		if pending or not cocoaPanel.Visible or not lastCocoa then return end
		pending = true
		task.delay(0.5, function() pending = false; if cocoaPanel.Visible and lastCocoa then renderCocoa(lastCocoa) end end)
	end)
end)

--------------------------------------------------
-- PET FUSER
--------------------------------------------------
local FUSE_A, FUSE_Z = Color3.fromRGB(255, 225, 110), Color3.fromRGB(235, 165, 30)
local fuserPanel, fuserList, fuserHint, fuserBase = makePage("Fuser", "PET FUSER", "Fuse 3 of the same pet into a GOLDEN pet with 2x boost! Equipped pets are safe.", "\u{2728}", Color3.fromRGB(235, 175, 40), true)
local function pct(x) return "+" .. NumberFormat.Abbreviate(math.floor(x * 100 + 0.5)) .. "%" end
local renderFuser
renderFuser = function(res)
	clear(fuserList)
	local list = res and res.List or {}
	if #list == 0 then emptyNote(fuserList, "Hatch pets at the eggs - 3 of the same pet make a Golden one!") return end
	sortReady(list)
	for i, e in ipairs(list) do
		local r = row(fuserList, i)
		petIcon(r, e.From, UDim2.fromScale(0.012, 0.06), UDim2.fromScale(0.12, 0.88))
		text(r, e.Need .. " x " .. e.From, {Position = UDim2.fromScale(0.105, 0.12), Size = UDim2.fromScale(0.29, 0.44), TextXAlignment = LEFT, TextColor3 = NAVY}, 24, false)
		text(r, ("You have %d (%d spare)"):format(e.Have, e.Spare), {Position = UDim2.fromScale(0.105, 0.56), Size = UDim2.fromScale(0.29, 0.3), TextXAlignment = LEFT, TextColor3 = SLATE}, 18, false)
		text(r, "\u{2192}", {Position = UDim2.fromScale(0.4, 0.2), Size = UDim2.fromScale(0.05, 0.6), TextColor3 = NAVY}, 40, false)
		petIcon(r, e.To, UDim2.fromScale(0.455, 0.06), UDim2.fromScale(0.12, 0.88))
		text(r, e.To, {Position = UDim2.fromScale(0.548, 0.12), Size = UDim2.fromScale(0.245, 0.44), TextXAlignment = LEFT, TextColor3 = Color3.fromRGB(205, 140, 10)}, 22, 1.5)
		text(r, pct(e.Boost) .. "  \u{2192}  " .. pct(e.GoldenBoost) .. " snow", {Position = UDim2.fromScale(0.548, 0.56), Size = UDim2.fromScale(0.245, 0.3), TextXAlignment = LEFT, TextColor3 = SLATE}, 18, false)
		local ready = e.Spare >= e.Need
		local b, l = rowButton(r, FUSE_A, FUSE_Z)
		setButton(b, l, ready, FUSE_A, FUSE_Z, ready and "FUSE!" or ("NEED " .. e.Need))
		b.Activated:Connect(function()
			local res2 = call("Fuse", e.From)
			flash(fuserHint, fuserBase, res2.Msg or "", res2.Ok)
			if res2.List then renderFuser(res2) end
		end)
	end
end
fuserPanel:GetPropertyChangedSignal("Visible"):Connect(function() if fuserPanel.Visible then renderFuser(call("FuserList")) end end)

--------------------------------------------------
-- CRAFTING MACHINE (2026-10-03, Claude): recipes come from ReplicatedStorage.CraftingConfig via MachineService
--------------------------------------------------
local TreasureConfig = require(RS:WaitForChild("TreasureConfig"))
local CRAFT_A, CRAFT_Z = Color3.fromRGB(125, 205, 255), Color3.fromRGB(45, 120, 230)
local REWARD_EMOJI = {Boost = "\u{26A1}", Shovel = "\u{2744}\u{FE0F}", Pet = "\u{1F43E}", Treasure = "\u{1F48E}", Snow = "\u{2744}\u{FE0F}"}
local craftPanel, craftList, craftHint, craftBase = makePage("Craft", "CRAFTING MACHINE", "Turn spare treasures and Snow into new things! Your last copy of each treasure is always kept.", "\u{1F6E0}\u{FE0F}", Color3.fromRGB(60, 150, 230), true)
local function treasureIcon(parent, id, pos, size)
	local img = TreasureConfig.Images and TreasureConfig.Images[id]
	if img then return image(parent, img, pos, size) end
	return text(parent, (TreasureConfig.Emoji and TreasureConfig.Emoji[id]) or "?", {Position = pos, Size = size}, 30, false)
end
local function treasureName(id) local t = TreasureConfig.ById[id]; return t and t.Name or id end
local function sized(f, ratio) mk("UIAspectRatioConstraint", {AspectRatio = ratio, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize}, f) end
local renderCraft
renderCraft = function(res)
	clear(craftList)
	local list, mats = (res and res.List) or {}, (res and res.Mats) or {}
	if #list == 0 then
		local f = frame(craftList, {Name = "Soon", LayoutOrder = 1, BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1)})
		sized(f, 5.4); round(f, 0.22); outline(f, 3); grad(f, WHITE, Color3.fromRGB(222, 236, 252))
		text(f, "\u{2728} New recipes are coming soon!", {Position = UDim2.fromScale(0.04, 0.12), Size = UDim2.fromScale(0.92, 0.42), TextColor3 = NAVY}, 32, false)
		text(f, "Keep digging for treasures - you will craft with them here.", {Position = UDim2.fromScale(0.04, 0.58), Size = UDim2.fromScale(0.92, 0.28), TextColor3 = SLATE}, 22, false)
	end
	for i, r in ipairs(list) do
		local row = frame(craftList, {Name = "Recipe", LayoutOrder = i, BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1)})
		sized(row, 6.2); round(row, 0.22); outline(row, 3); grad(row, WHITE, Color3.fromRGB(222, 236, 252))
		text(row, REWARD_EMOJI[r.Reward] or "\u{2728}", {Position = UDim2.fromScale(0.012, 0.1), Size = UDim2.fromScale(0.09, 0.8)}, 54, false)
		text(row, r.Name or r.Id, {Position = UDim2.fromScale(0.11, 0.1), Size = UDim2.fromScale(0.3, 0.42), TextXAlignment = LEFT, TextColor3 = NAVY}, 24, false)
		text(row, r.Text or "", {Position = UDim2.fromScale(0.11, 0.55), Size = UDim2.fromScale(0.3, 0.32), TextXAlignment = LEFT, TextColor3 = SLATE}, 18, false)
		local chips = frame(row, {Name = "Cost", BackgroundTransparency = 1, Position = UDim2.fromScale(0.42, 0.14), Size = UDim2.fromScale(0.37, 0.72)})
		mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.03, 0), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, chips)
		local function chip(order, drawIcon, label, ok)
			local c = frame(chips, {Name = "Chip", LayoutOrder = order, BackgroundColor3 = ok and Color3.fromRGB(215, 250, 222) or Color3.fromRGB(255, 222, 226), Size = UDim2.fromScale(0.23, 1)})
			round(c, 0.25); outline(c, 2, ok and Color3.fromRGB(60, 160, 90) or Color3.fromRGB(200, 70, 80))
			drawIcon(c)
			text(c, label, {Position = UDim2.fromScale(0.05, 0.62), Size = UDim2.fromScale(0.9, 0.34), TextColor3 = NAVY}, 18, false)
		end
		local order = 0
		for _, it in ipairs(r.Items or {}) do
			order += 1
			chip(order, function(c) treasureIcon(c, it.Id, UDim2.fromScale(0.25, 0.04), UDim2.fromScale(0.5, 0.58)) end, ("%d/%d"):format(math.min(it.Have, it.Need), it.Need), it.Have >= it.Need)
		end
		if (r.Snow or 0) > 0 then
			order += 1
			chip(order, function(c) text(c, "\u{2744}\u{FE0F}", {Position = UDim2.fromScale(0.25, 0.04), Size = UDim2.fromScale(0.5, 0.58)}, 40, false) end, NumberFormat.Abbreviate(r.Snow), (tonumber(res.Snow) or 0) >= r.Snow)
		end
		local b, l = rowButton(row, CRAFT_A, CRAFT_Z)
		setButton(b, l, r.Can, CRAFT_A, CRAFT_Z, r.Can and "CRAFT!" or "NEED MORE")
		b.Activated:Connect(function()
			local res2 = call("Craft", r.Index)
			flash(craftHint, craftBase, res2.Msg or "", res2.Ok)
			if res2.List then renderCraft(res2) end
		end)
	end
	local head = frame(craftList, {Name = "MatsHead", LayoutOrder = 1000, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
	sized(head, 16)
	text(head, ("YOUR MATERIALS    \u{2744}\u{FE0F} %s Snow"):format(NumberFormat.Abbreviate(tonumber(res and res.Snow) or 0)), {TextXAlignment = LEFT}, 24)
	if #mats == 0 then
		local f = frame(craftList, {Name = "NoMats", LayoutOrder = 1001, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
		sized(f, 12)
		text(f, "No spare treasures yet - find duplicates while digging!", {}, 22)
	else
		local grid = frame(craftList, {Name = "Mats", LayoutOrder = 1001, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
		mk("UIGridLayout", {CellSize = UDim2.new(0.18, 0, 0, 96), CellPadding = UDim2.new(0.025, 0, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
		for i, m in ipairs(mats) do
			local cell = frame(grid, {Name = m.Id, LayoutOrder = i, BackgroundColor3 = WHITE})
			round(cell, 0.18); outline(cell, 2); grad(cell, WHITE, Color3.fromRGB(222, 236, 252))
			treasureIcon(cell, m.Id, UDim2.fromScale(0.22, 0.04), UDim2.fromScale(0.56, 0.6))
			text(cell, "x" .. m.Spare, {Position = UDim2.fromScale(0.62, 0.02), Size = UDim2.fromScale(0.36, 0.28), TextColor3 = NAVY}, 20, false)
			text(cell, treasureName(m.Id), {Position = UDim2.fromScale(0.04, 0.66), Size = UDim2.fromScale(0.92, 0.3), TextColor3 = SLATE}, 15, false)
		end
	end
end
craftPanel:GetPropertyChangedSignal("Visible"):Connect(function() if craftPanel.Visible then renderCraft(call("CraftList")) end end)

--------------------------------------------------
-- the 3D machines: prompts open the panels; small local animation
--------------------------------------------------
-- 2026-10-04 (Claude): locked machines (no unlock upgrade yet) show a hint instead of opening
local UNLOCK_ATTR = {Forge = "UnlockForge", Fuser = "UnlockFuser", Craft = "UnlockCraft"}
local UNLOCK_NAME = {Forge = "Shovel Forge", Fuser = "Pet Fuser", Craft = "Crafting Machine"}
local lockToast = text(gui, "", {Name = "MachineLockToast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.235), Size = UDim2.fromScale(0.55, 0.06),
	TextColor3 = Color3.fromRGB(255, 225, 120), Visible = false, ZIndex = 30}, 34, 3)
local lockToken = 0
local function showLock(m)
	lockToken += 1
	local my = lockToken
	lockToast.Text = "\u{1F512} Unlock the " .. (UNLOCK_NAME[m] or "machine") .. " in UPGRADES!"
	lockToast.Visible = true
	task.delay(2.2, function() if lockToken == my then lockToast.Visible = false end end)
end
Prompts.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then return end
	local m = prompt:GetAttribute("Machine")
	if not m then return end
	local attr = UNLOCK_ATTR[m]
	if attr and (tonumber(player:GetAttribute(attr)) or 0) < 1 then showLock(m) return end
	openMenu:Fire(m)
end)
task.spawn(function()
	local village = workspace:WaitForChild("FrostfallVillage", 60)
	if not village then return end
	task.wait(2)
	local function topMachine(o) while o and o.Parent ~= village do o = o.Parent end return o end
	local movers, spinners = {}, {}
	for _, p in ipairs(village:GetDescendants()) do
		if p:IsA("BasePart") and (p:GetAttribute("MachineBob") or p:GetAttribute("MachineGlow")) then
			table.insert(movers, {part = p, base = p.CFrame, phase = math.random() * 6, machine = topMachine(p)})
		end
		-- 2026-10-03 (Claude): models with MachineRotate (deg/s) turn around their pivot's X axis (the Shovel Forge gear)
		if p:IsA("Model") and p:GetAttribute("MachineRotate") then
			table.insert(spinners, {model = p, base = p:GetPivot(), speed = math.rad(p:GetAttribute("MachineRotate")), machine = topMachine(p)})
		end
	end
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		for _, s in ipairs(spinners) do if not (s.machine and s.machine:GetAttribute("LocalLocked")) then s.model:PivotTo(s.base * CFrame.Angles(t * s.speed, 0, 0)) end end
		for _, m in ipairs(movers) do
			if m.machine and m.machine:GetAttribute("LocalLocked") then continue end
			if m.part:GetAttribute("MachineBob") then
				m.part.CFrame = m.base * CFrame.new(0, math.sin(t * 2 + m.phase) * 0.25, 0) * CFrame.Angles(0, t * (m.part:GetAttribute("MachineSpin") or 0), 0)
			else
				m.part.Transparency = 0.1 + 0.15 * (0.5 + 0.5 * math.sin(t * 9 + m.phase))
			end
		end
	end)
end)
