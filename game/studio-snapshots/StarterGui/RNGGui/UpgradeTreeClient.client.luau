-- UpgradeTreeClient v3 (Claude, 2026-10-01): one upgrade branch on one page.
-- * Snow + Rolls form ONE branch that grows from Snow Start; a short stone path leads from Snow Start to Lucky Start.
-- * The yellow MISC hexagon is a link into the Misc tree; the yellow BACK hexagon returns. No other yellow hubs.
-- * Only owned tiles, the tiles attached to them and a ring of "?" tiles are shown; every purchase reveals more.
-- * One tap buys. Flashing green = can buy, flashing red = can't (price or stage lock), toned blue = owned.
-- * The HUD snow counter (RNGGui.SnowCounter) is lifted in front of this page while it is open (no second counter).
-- Server rules unchanged (UpgradeService). Lucky Start is still a start tile on the server; this UI offers it once Snow Start is owned.
-- Older versions: ServerStorage.UpgradeTreeClient_Backup20261001 (picker) and ServerStorage.UpgradeTreeClient_v2_Backup (three hubs).
-- Bigger icons (2026-10-01): icons fill most of the tile; the name may sit slightly on the icon's lower edge
-- (thicker outline keeps it readable). Before this change: ServerStorage.UpgradeTreeClient_BeforeBigIcons20261001.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local U = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local IconArt = require(ReplicatedStorage:WaitForChild("UpgradeIconArt"))
local StageConfig = require(ReplicatedStorage:WaitForChild("StageConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local buyRemote = ReplicatedStorage:WaitForChild("BuyUpgrade")
local player = Players.LocalPlayer
local openButton = script.Parent:WaitForChild("BottomBar"):WaitForChild("UpgradesButton")

local FONT = Enum.Font.LuckiestGuy
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(14, 18, 32)
local SQ3 = math.sqrt(3)
local R = 60      -- hex radius in px before zoom
local GAP = 5
local GLOWBASE = Color3.fromRGB(30, 30, 72) -- glow/shine are solid colours (see-through overlapping rects would draw a star pattern)
-- tile layout when the upgrade has an icon (fractions of the tile): big icon on top, name may overlap its lower edge
local ICON_POS, ICON_SIZE = UDim2.fromScale(0.5, 0.385), UDim2.fromScale(0.86, 0.64)
local ICON_NAME_POS, ICON_NAME_SIZE = UDim2.fromScale(0.5, 0.675), UDim2.fromScale(0.88, 0.17)
local ICON_SUB_POS, ICON_SUB_SIZE = UDim2.fromScale(0.5, 0.825), UDim2.fromScale(0.72, 0.13)

local STYLE = {
	owned   = {fill = Color3.fromRGB(70, 122, 200),  shine = 0.84, border = Color3.fromRGB(150, 195, 250)},
	buy     = {fill = Color3.fromRGB(30, 215, 85),   shine = 0.7,  border = Color3.fromRGB(220, 255, 220), glow = Color3.fromRGB(90, 255, 130)},
	cant    = {fill = Color3.fromRGB(235, 50, 72),   shine = 0.74, border = Color3.fromRGB(255, 205, 210), glow = Color3.fromRGB(255, 70, 95)},
	mystery = {fill = Color3.fromRGB(44, 50, 70),    shine = 0.93, border = Color3.fromRGB(80, 88, 116)},
	link    = {fill = Color3.fromRGB(255, 196, 36),  shine = 0.62, border = WHITE, glow = Color3.fromRGB(255, 215, 80)},
}

-- MAIN view: Snow + Rolls in one grid (Snow Start at 0,0). Each tree is rotated in 60-degree steps (keeps hex neighbours)
-- and shifted; the trees never touch, so nothing looks attached that is not. Found by an offline search over all layouts.
local MAIN = {
	Snow  = {rot = 1, q = 0, r = 0},
	Rolls = {rot = 3, q = 0, r = -5},  -- Lucky Start sits at (0,-5)
}
local BRIDGE = {{0, -1}, {0, -2}, {0, -3}, {0, -4}}  -- stone path Snow Start -> Lucky Start
local MISC_LINK = {1, 0}                            -- yellow link next to Snow Start
local MISC = {rot = 0, q = 0, r = 0}                -- MISC view: Misc tree on its own

local function rotate(q, r, k) for _ = 1, k do q, r = -r, q + r end return q, r end
local function hexPos(q, r) local s = R + GAP; return Vector2.new(s * SQ3 * (q + r / 2), s * 1.5 * r) end
local function viewOf(n) return n.Tree == "Misc" and "Misc" or "Main" end
local function nodeCell(n)
	local L = n.Tree == "Misc" and MISC or MAIN[n.Tree]
	local q, r = rotate(n.Q, n.R, L.rot)
	return q + L.q, r + L.r
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
local function text(parent, t, props, stroke)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = WHITE, Text = t}, nil)
	for k, v in pairs(props) do l[k] = v end
	if stroke ~= false then mk("UIStroke", {Thickness = stroke or 2.5, Color = DARK, LineJoinMode = Enum.LineJoinMode.Round}, l) end
	l.Parent = parent
	return l
end
local function snow()
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Snow") and ls.Snow.Value or 0
end
local function stageSet()
	local stages = {Starter = true}
	-- 2026-10-02 (Claude): every stage in StageConfig (World 2 stages included), not a fixed World 1 list
	for _, s in ipairs(StageConfig.Order) do if s.Id ~= "Starter" then stages[s.Id] = player:GetAttribute("Stage_" .. s.Id) == true end end
	return stages
end
local function ownedSet()
	local set = {}
	for id in pairs(U.ById) do if player:GetAttribute("Up_" .. id) == true then set[id] = true end end
	return set
end

-- pointy-top hexagon made of 3 rotated rectangles; returns holder + its 3 rects
local function hexShape(parent, radius, color, z, name)
	local h = mk("Frame", {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(radius * SQ3, radius * 2), BackgroundTransparency = 1, ZIndex = z}, parent)
	local rects = {}
	for i, rot in ipairs({0, 60, 120}) do
		rects[i] = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(radius * SQ3, radius),
			Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z}, h)
	end
	return h, rects
end
local function paint(rects, color, transparency)
	for _, r in ipairs(rects) do
		r.BackgroundColor3 = color
		if transparency then r.BackgroundTransparency = transparency end
	end
end

--------------------------------------------------
-- SCREEN
--------------------------------------------------
local sg = mk("ScreenGui", {Name = "UpgradeTreeGui", DisplayOrder = 150, IgnoreGuiInset = true, ResetOnSpawn = false, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
local bg = mk("Frame", {Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.12, -- 2026-10-03: slightly see-through
	BorderSizePixel = 0, Active = true, ZIndex = 1}, sg)
mk("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 38, 120)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(24, 30, 72)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 32))}), Rotation = 90}, bg)
local boards = {}
for _, v in ipairs({"Main", "Misc"}) do
	local b = mk("Frame", {Name = v .. "Board", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1, Visible = v == "Main"}, bg)
	boards[v] = {frame = b, scale = mk("UIScale", {Scale = 1}, b)}
end
local view = "Main"

local title = text(bg, "UPGRADES", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.025), Size = UDim2.fromScale(0.4, 0.08), ZIndex = 20}, 4)
mk("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 70)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 160))}), Rotation = 0}, title)
text(bg, "Tap a green hexagon to buy it - each one you buy reveals the ones attached to it", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.11),
	Size = UDim2.fromScale(0.62, 0.032), TextColor3 = Color3.fromRGB(205, 220, 255), ZIndex = 20}, 2)

local progressPill = mk("Frame", {AnchorPoint = Vector2.new(0, 0), Size = UDim2.fromScale(0.15, 0.05), BackgroundColor3 = Color3.fromRGB(130, 90, 230), ZIndex = 20}, bg)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, progressPill)
mk("UIStroke", {Thickness = 3, Color = DARK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, progressPill)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(175, 145, 245), Color3.fromRGB(130, 90, 230)), Rotation = 90}, progressPill)
local progressLabel = text(progressPill, "", {Position = UDim2.fromScale(0.08, 0.14), Size = UDim2.fromScale(0.84, 0.72), ZIndex = 21}, 2.5)
local function placeTopLeft()
	progressPill.Position = UDim2.new(0, 18, 0, GuiService:GetGuiInset().Y + 8) -- below Roblox's own top bar
end
placeTopLeft()

local closeB = mk("TextButton", {Name = "Close", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0.025, 0),
	Size = UDim2.fromScale(0.06, 0.06), BackgroundColor3 = Color3.fromRGB(240, 50, 80), ZIndex = 22}, bg)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, closeB)
mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, closeB)
mk("UIStroke", {Thickness = 4, Color = DARK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, closeB)
text(closeB, "X", {Position = UDim2.fromScale(0.15, 0.14), Size = UDim2.fromScale(0.7, 0.74), ZIndex = 23}, 3)
local closeScale = mk("UIScale", {Scale = 1}, closeB)
closeB.MouseEnter:Connect(function() tween(closeScale, 0.12, {Scale = 1.1}, Enum.EasingStyle.Back) end)
closeB.MouseLeave:Connect(function() tween(closeScale, 0.12, {Scale = 1}) end)

-- legend (bottom left)
local legend = mk("Frame", {Name = "Legend", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -16), Size = UDim2.fromScale(0.32, 0.04), BackgroundTransparency = 1, ZIndex = 20}, bg)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
	Padding = UDim.new(0.015, 0), VerticalAlignment = Enum.VerticalAlignment.Center}, legend)
for i, e in ipairs({{"buy", "Can buy"}, {"cant", "Can't buy"}, {"owned", "Owned"}, {"mystery", "Hidden"}}) do
	local item = mk("Frame", {LayoutOrder = i, Size = UDim2.fromScale(0.235, 1), BackgroundTransparency = 1, ZIndex = 20}, legend)
	local dot = mk("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(0.16, 0.8), BackgroundColor3 = STYLE[e[1]].fill, ZIndex = 21}, item)
	mk("UIAspectRatioConstraint", {AspectRatio = 1}, dot)
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, dot)
	mk("UIStroke", {Thickness = 2, Color = WHITE}, dot)
	text(item, e[2], {Position = UDim2.fromScale(0.2, 0.1), Size = UDim2.fromScale(0.8, 0.8), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21}, 2)
end

-- tooltip (desktop hover)
local tip = mk("Frame", {Name = "Tooltip", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromScale(0.36, 0.075),
	BackgroundColor3 = Color3.fromRGB(26, 32, 56), Visible = false, ZIndex = 25}, bg)
mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, tip)
local tipStroke = mk("UIStroke", {Thickness = 3, Color = WHITE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, tip)
local tipName = text(tip, "", {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.92, 0.46), ZIndex = 26}, 2.5)
local tipDesc = text(tip, "", {Position = UDim2.fromScale(0.04, 0.56), Size = UDim2.fromScale(0.92, 0.36), TextColor3 = Color3.fromRGB(200, 225, 255), ZIndex = 26}, 2)

local blur = Instance.new("BlurEffect")
blur.Name = "UpgradeBlur"
blur.Size = 0

local buySound = mk("Sound", {Name = "BuySound", SoundId = "rbxassetid://15675059323", Volume = 0.45}, script)
local denySound = mk("Sound", {Name = "DenySound", SoundId = "rbxassetid://12221976", Volume = 0.35, PlaybackSpeed = 0.6}, script)

--------------------------------------------------
-- TILES (created once, shown/hidden by refresh)
--------------------------------------------------
local tiles, links, pathTiles = {}, {}, {}
local pulsing = {}
local refresh, switchView
local hovered

local function newTile(id, pos, n, parent)
	local mappedIcon = IconArt.Resolve(n)
	local holder = mk("Frame", {Name = id, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(R * SQ3, R * 2), BackgroundTransparency = 1, ZIndex = 2, Visible = false}, parent)
	local t = {id = id, node = n, holder = holder, pos = pos, state = "hidden", phase = math.random() * 6.28}
	t.scale = mk("UIScale", {Scale = 1}, holder)
	t.glow, t.glowRects = hexShape(holder, R + 10, WHITE, 1, "Glow")
	t.border, t.borderRects = hexShape(holder, R, WHITE, 2, "Border")
	t.fill, t.fillRects = hexShape(holder, R - 5, WHITE, 3, "Fill")
	t.shine, t.shineRects = hexShape(holder, (R - 5) * 0.8, WHITE, 4, "Shine") -- concentric inner hexagon
	t.icon = mk("ImageLabel", {Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = ICON_POS,
		Size = ICON_SIZE, ScaleType = Enum.ScaleType.Fit, Image = mappedIcon or (n and n.Icon) or "", ZIndex = 5, Visible = false}, holder)
	if n and n.IconTint and not mappedIcon then t.icon.ImageColor3 = n.IconTint end
	if n and n.IconRainbow and not mappedIcon then
		mk("UIGradient", {Rotation = 35, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 95, 120)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 190, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 230, 120)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 115, 255))})}, t.icon)
	end
	t.name = text(holder, "", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.86, 0.27), TextWrapped = true, ZIndex = 6}, 2.5)
	t.nameStroke = t.name:FindFirstChildOfClass("UIStroke")
	t.sub = text(holder, "", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.74, 0.15), ZIndex = 6}, 2.5)
	t.q = text(holder, "?", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.6, 0.56),
		TextColor3 = Color3.fromRGB(150, 160, 192), ZIndex = 6, Visible = false}, 3)
	t.hit = mk("TextButton", {Name = "Hit", Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.95, 0.8), ZIndex = 9}, holder)
	return t
end

local function setLook(t, state, nameText, subText, subColor, showIcon)
	local st = STYLE[state]
	paint(t.fillRects, st.fill, 0)
	paint(t.borderRects, st.border, 0)
	paint(t.shineRects, st.fill:Lerp(WHITE, 1 - st.shine), 0)
	if st.glow then paint(t.glowRects, GLOWBASE:Lerp(st.glow, 0.5), 0); t.glow.Visible = true else t.glow.Visible = false end
	local mystery = state == "mystery"
	t.q.Visible = mystery
	t.name.Visible = not mystery
	t.icon.Visible = showIcon and not mystery
	t.name.Text = nameText or ""
	t.sub.Text = subText or ""
	t.sub.Visible = not mystery and (subText or "") ~= ""
	t.sub.TextColor3 = subColor or WHITE
	if t.nameStroke then t.nameStroke.Thickness = t.icon.Visible and 3 or 2.5 end
	if t.icon.Visible then
		t.name.Position = ICON_NAME_POS; t.name.Size = ICON_NAME_SIZE
		t.sub.Position = ICON_SUB_POS; t.sub.Size = ICON_SUB_SIZE
	else
		t.name.Position = UDim2.fromScale(0.5, 0.42); t.name.Size = UDim2.fromScale(0.86, 0.27)
		t.sub.Position = UDim2.fromScale(0.5, 0.68); t.sub.Size = UDim2.fromScale(0.74, 0.15)
	end
end

local function float(t, msg, color)
	local board = t.holder.Parent
	local l = text(board, msg, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(t.pos.X, t.pos.Y - R * 0.8), Size = UDim2.fromOffset(R * 4, R * 0.55),
		TextColor3 = color, ZIndex = 40}, 3)
	tween(l, 1.0, {Position = UDim2.fromOffset(t.pos.X, t.pos.Y - R * 1.7), TextTransparency = 1})
	local s = l:FindFirstChildOfClass("UIStroke")
	if s then tween(s, 1.0, {Transparency = 1}) end
	task.delay(1.05, function() l:Destroy() end)
end
local function shake(t)
	local base = UDim2.fromOffset(t.pos.X, t.pos.Y)
	for i, dx in ipairs({-9, 9, -7, 7, -3, 0}) do
		task.delay(i * 0.035, function() t.holder.Position = base + UDim2.fromOffset(dx, 0) end)
	end
end
local CONFETTI = {Color3.fromRGB(255, 220, 60), Color3.fromRGB(90, 255, 130), Color3.fromRGB(80, 190, 255), Color3.fromRGB(255, 90, 170), Color3.fromRGB(255, 140, 50)}
local function burst(t)
	local board = t.holder.Parent
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2 + math.random() * 0.4
		local d = R * (1.1 + math.random() * 0.9)
		local c = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(t.pos.X, t.pos.Y), Size = UDim2.fromOffset(10, 10),
			Rotation = math.random(0, 90), BackgroundColor3 = CONFETTI[(i % #CONFETTI) + 1], BorderSizePixel = 0, ZIndex = 35}, board)
		mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, c)
		tween(c, 0.6, {Position = UDim2.fromOffset(t.pos.X + math.cos(a) * d, t.pos.Y + math.sin(a) * d), Rotation = c.Rotation + 180, BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
		task.delay(0.65, function() c:Destroy() end)
	end
end

local function showTip(t)
	hovered = t
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return end
	local n = t.node
	if t.isLink then
		tipName.Text = t.linkTitle
		tipName.TextColor3 = STYLE.link.fill
		tipDesc.Text = t.linkDesc
		tipStroke.Color = STYLE.link.fill
	elseif t.state == "mystery" then
		tipName.Text = "???"
		tipName.TextColor3 = Color3.fromRGB(170, 180, 210)
		tipDesc.Text = "Buy a hexagon attached to it to reveal it"
		tipStroke.Color = STYLE.mystery.border
	else
		tipName.Text = n.Name
		tipName.TextColor3 = U.TreeById[n.Tree].Color
		local extra = t.state == "owned" and "Owned" or (t.lock or ("Cost: " .. NumberFormat.Abbreviate(U.CostOf(n)) .. " snow"))
		tipDesc.Text = (n.Text or "") .. "   |   " .. extra
		tipStroke.Color = STYLE[t.state].fill
	end
	tip.Visible = true
end
local function hideTip(t)
	if hovered == t then hovered = nil; tip.Visible = false end
end

local busy = false
local lastFeedback = {}
local function onTileClick(t)
	local n = t.node
	local now = os.clock()
	if t.state ~= "buy" and lastFeedback[t] and now - lastFeedback[t] < 0.3 then return end
	lastFeedback[t] = now
	if t.state == "buy" then
		if busy then return end
		busy = true
		local ok, res, reason = pcall(function() return buyRemote:InvokeServer(n.Id) end)
		busy = false
		if ok and res == true then
			buySound:Play()
			t.scale.Scale = 1.35
			tween(t.scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
			burst(t)
			float(t, n.Text or "Bought!", Color3.fromRGB(120, 255, 150))
			refresh(true)
		else
			denySound:Play()
			shake(t)
			float(t, tostring((ok and reason) or "Try again"), Color3.fromRGB(255, 120, 130))
			refresh(false)
		end
	elseif t.state == "cant" then
		denySound:Play()
		shake(t)
		local need = U.CostOf(n) - snow()
		float(t, t.lock or ("Need " .. NumberFormat.Abbreviate(math.max(need, 0)) .. " more snow"), Color3.fromRGB(255, 120, 130))
	elseif t.state == "mystery" then
		shake(t)
		float(t, "Buy one next to it first", Color3.fromRGB(190, 200, 225))
	end
end

-- build all upgrade tiles once
local TOTAL = 0
local used = {}
for _, tree in ipairs(U.Trees) do
	for _, n in ipairs(tree.Nodes) do
		TOTAL += 1
		local q, r = nodeCell(n)
		local v = viewOf(n)
		local key = v .. ":" .. q .. "," .. r
		if used[key] then warn("UpgradeTreeClient: tiles overlap at", key, used[key], n.Id) end
		used[key] = n.Id
		local t = newTile(n.Id, hexPos(q, r), n, boards[v].frame)
		t.view = v
		tiles[n.Id] = t
		t.hit.MouseEnter:Connect(function() tween(t.scale, 0.12, {Scale = 1.08}, Enum.EasingStyle.Back); showTip(t) end)
		t.hit.MouseLeave:Connect(function() tween(t.scale, 0.12, {Scale = 1}); hideTip(t) end)
		t.hit.Activated:Connect(function() onTileClick(t) end)
	end
end
for _, c in ipairs(BRIDGE) do
	if used["Main:" .. c[1] .. "," .. c[2]] then warn("UpgradeTreeClient: path stone overlaps a tile at", c[1], c[2]) end
end

-- stone path Snow Start -> Lucky Start (decorative, appears with Lucky Start)
for i, c in ipairs(BRIDGE) do
	local pos = hexPos(c[1], c[2])
	local holder = mk("Frame", {Name = "PathStone" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(R * SQ3, R * 2), BackgroundTransparency = 1, ZIndex = 1, Visible = false}, boards.Main.frame)
	local sc = mk("UIScale", {Scale = 1}, holder)
	hexShape(holder, R * 0.5, Color3.fromRGB(240, 230, 255), 1, "Rim")
	hexShape(holder, R * 0.4, Color3.fromRGB(160, 130, 240), 2, "Core")
	hexShape(holder, R * 0.22, Color3.fromRGB(210, 195, 255), 3, "Dot")
	table.insert(pathTiles, {holder = holder, scale = sc, shown = false})
end

-- yellow links: MISC (main view, next to Snow Start) and BACK (misc view, fixed on screen)
local function makeLink(id, parent, pos, label, linkTitle, linkDesc, target)
	local t = newTile(id, pos, nil, parent)
	t.isLink = true
	t.linkTitle = linkTitle
	t.linkDesc = linkDesc
	setLook(t, "link", label, "", WHITE, false)
	local badge = mk("Frame", {Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.84, 0.15), Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Color3.fromRGB(230, 30, 60), ZIndex = 12, Visible = false}, t.holder)
	mk("UICorner", {CornerRadius = UDim.new(1, 0)}, badge)
	mk("UIStroke", {Thickness = 3, Color = WHITE}, badge)
	t.badge = badge
	t.badgeLabel = text(badge, "0", {Position = UDim2.fromScale(0.14, 0.14), Size = UDim2.fromScale(0.72, 0.72), ZIndex = 13}, 2)
	t.hit.MouseEnter:Connect(function() tween(t.scale, 0.12, {Scale = 1.08}, Enum.EasingStyle.Back); showTip(t) end)
	t.hit.MouseLeave:Connect(function() tween(t.scale, 0.12, {Scale = 1}); hideTip(t) end)
	t.hit.Activated:Connect(function()
		t.scale.Scale = 0.88
		tween(t.scale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
		switchView(target)
	end)
	links[id] = t
	return t
end
local miscLink = makeLink("Link_Misc", boards.Main.frame, hexPos(MISC_LINK[1], MISC_LINK[2]), "MISC", "MISC UPGRADES", "Pets, eggs, expansions and more - tap to open", "Misc")
local backLink = makeLink("Link_Back", bg, Vector2.zero, "BACK", "BACK", "Return to the main upgrades", "Main")
backLink.holder.AnchorPoint = Vector2.new(0, 0)
backLink.holder.ZIndex = 20
backLink.holder.Size = UDim2.fromOffset(R * SQ3 * 0.9, R * 2 * 0.9)
backLink.scale.Scale = 0.9

-- 2026-10-03 (Claude): preload every image in the upgrade tree (all upgrade icons) and its sounds in the background right
-- after the tiles are built (during the intro), so the first open shows every icon at once instead of popping them in.
task.spawn(function()
	local list = {buySound, denySound}
	for _, d in ipairs(sg:GetDescendants()) do
		if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image ~= "" then table.insert(list, d) end
	end
	local t0 = os.clock()
	local ok = pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
	script:SetAttribute("PreloadedAssets", #list)
	script:SetAttribute("PreloadSeconds", math.floor((os.clock() - t0) * 100) / 100)
	script:SetAttribute("PreloadOk", ok)
end)

local function placeBack()
	backLink.holder.Position = UDim2.new(0, 18, 0, GuiService:GetGuiInset().Y + 70)
end
placeBack()

--------------------------------------------------
-- VIEW FIT
--------------------------------------------------
local function visiblePoints(v)
	local pts = {}
	for _, t in pairs(tiles) do
		if t.view == v and t.state ~= "hidden" then table.insert(pts, t.pos) end
	end
	if v == "Main" and miscLink.holder.Visible then table.insert(pts, miscLink.pos) end
	if #pts == 0 then table.insert(pts, Vector2.zero) end
	return pts
end
local function fitTo(v, animated)
	local b = boards[v]
	local points = visiblePoints(v)
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	for _, p in ipairs(points) do
		minX = math.min(minX, p.X); maxX = math.max(maxX, p.X); minY = math.min(minY, p.Y); maxY = math.max(maxY, p.Y)
	end
	local viewSize = bg.AbsoluteSize
	if viewSize.X < 10 then viewSize = workspace.CurrentCamera.ViewportSize end
	local w, h = (maxX - minX) + R * 2.6, (maxY - minY) + R * 2.8
	local s = math.clamp(math.min(viewSize.X * 0.84 / w, viewSize.Y * 0.58 / h), math.clamp(viewSize.X / 1450, 0.6, 0.95), 1.15)
	local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
	local target = UDim2.new(0.5, -cx * s, 0.5, -cy * s)
	if animated then
		tween(b.frame, 0.5, {Position = target}, Enum.EasingStyle.Quint)
		tween(b.scale, 0.5, {Scale = s}, Enum.EasingStyle.Quint)
	else
		b.frame.Position = target
		b.scale.Scale = s
	end
end

--------------------------------------------------
-- REFRESH
--------------------------------------------------
refresh = function(animate)
	local owned, stages, money = ownedSet(), stageSet(), snow()
	local states, done = {}, 0
	local snowStart = owned["S_Center"] == true
	for id in pairs(owned) do states[id] = "owned"; done += 1 end
	local frontier = {}
	for id, n in pairs(U.ById) do
		if not owned[id] then
			local front
			if id == "R_Luck1" then front = snowStart          -- the branch: Lucky Start opens once Snow Start is owned
			elseif n.Center then front = true                  -- Snow Start, Misc Start
			else
				for _, nb in ipairs(U.Neighbours(n)) do if owned[nb.Id] then front = true; break end end
			end
			if front then table.insert(frontier, n) end
		end
	end
	local lockText, miscGreen = {}, 0
	for _, n in ipairs(frontier) do
		local reason = U.LockReason(n, owned, stages)
		if n.Id == "R_Luck1" and reason ~= nil and not n.RequiredStage then reason = nil end
		if reason == nil and money >= U.CostOf(n) then
			states[n.Id] = "buy"
			if n.Tree == "Misc" then miscGreen += 1 end
		else
			states[n.Id] = "cant"
			if reason then
				local st = StageConfig.ById and StageConfig.ById[n.RequiredStage]
				lockText[n.Id] = "Unlock " .. ((st and st.Name) or n.RequiredStage or "the next area") .. " first"
			end
		end
	end
	for _, n in ipairs(frontier) do
		for _, nb in ipairs(U.Neighbours(n)) do if not states[nb.Id] then states[nb.Id] = "mystery" end end
	end

	progressLabel.Text = done .. " / " .. TOTAL .. " owned"
	table.clear(pulsing)
	for id, t in pairs(tiles) do
		local st = states[id] or "hidden"
		local prev = t.state
		t.state = st
		if st == "hidden" then
			t.holder.Visible = false
		else
			local n = t.node
			local hasIcon = (t.icon.Image or "") ~= ""
			t.lock = lockText[id]
			if st == "owned" then
				setLook(t, st, n.Name, n.Text, Color3.fromRGB(205, 230, 255), hasIcon)
			elseif st == "buy" then
				setLook(t, st, n.Name, "❄ " .. NumberFormat.Abbreviate(U.CostOf(n)), WHITE, hasIcon)
				table.insert(pulsing, t)
			elseif st == "cant" then
				local stg = StageConfig.ById and n.RequiredStage and StageConfig.ById[n.RequiredStage]
				local sub = t.lock and ("🔒 " .. ((stg and stg.Name) or n.RequiredStage or "")) or ("❄ " .. NumberFormat.Abbreviate(U.CostOf(n)))
				setLook(t, st, n.Name, sub, Color3.fromRGB(255, 235, 120), hasIcon)
				table.insert(pulsing, t)
			else
				setLook(t, st, "", "", WHITE, false)
			end
			t.holder.Visible = true
			if animate and prev == "hidden" then
				t.scale.Scale = 0.15
				tween(t.scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
			end
		end
	end
	-- stone path + MISC link grow out of Snow Start (also shown if older saves already own Rolls/Misc tiles)
	local anyRolls, anyMisc, miscOwned = false, false, 0
	for id in pairs(owned) do
		local n = U.ById[id]
		if n and n.Tree == "Rolls" then anyRolls = true end
		if n and n.Tree == "Misc" then anyMisc = true; miscOwned += 1 end
	end
	local showPath = snowStart or anyRolls
	for i, p in ipairs(pathTiles) do
		if showPath and not p.shown then
			p.shown = true
			p.holder.Visible = true
			if animate then
				p.scale.Scale = 0.1
				task.delay(i * 0.08, function() tween(p.scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back) end)
			end
		elseif not showPath then
			p.shown = false
			p.holder.Visible = false
		end
	end
	local showMisc = snowStart or anyMisc
	local wasHidden = not miscLink.holder.Visible
	miscLink.holder.Visible = showMisc
	if showMisc and wasHidden and animate then
		miscLink.scale.Scale = 0.15
		tween(miscLink.scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
	end
	miscLink.sub.Text = miscOwned .. "/" .. #U.TreeById.Misc.Nodes
	miscLink.sub.Visible = true
	miscLink.badge.Visible = miscGreen > 0
	miscLink.badgeLabel.Text = tostring(miscGreen)
	backLink.holder.Visible = view == "Misc"
	if hovered then showTip(hovered) end
end

switchView = function(v)
	view = v
	for name, b in pairs(boards) do b.frame.Visible = name == v end
	title.Text = v == "Misc" and "MISC UPGRADES" or "UPGRADES"
	tip.Visible = false
	hovered = nil
	refresh(false)
	local b = boards[v]
	fitTo(v, false)
	local s = b.scale.Scale
	b.scale.Scale = s * 0.8
	tween(b.scale, 0.35, {Scale = s}, Enum.EasingStyle.Back)
end

-- flashing: green/red tiles pulse their glow and brighten; yellow links breathe
local pulseConn
local function startPulse()
	if pulseConn then return end
	pulseConn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for _, t in ipairs(pulsing) do
			local st = STYLE[t.state]
			if st and st.glow then
				local a = 0.5 + 0.5 * math.sin(now * (t.state == "buy" and 5.5 or 4) + t.phase)
				local g = GLOWBASE:Lerp(st.glow, 0.25 + 0.65 * a)
				for _, r in ipairs(t.glowRects) do r.BackgroundColor3 = g end
				local c = st.fill:Lerp(WHITE, 0.22 * a)
				for _, r in ipairs(t.fillRects) do r.BackgroundColor3 = c end
				local s2 = c:Lerp(WHITE, 1 - st.shine)
				for _, r in ipairs(t.shineRects) do r.BackgroundColor3 = s2 end
			end
		end
		for _, l in pairs(links) do
			local a = 0.5 + 0.5 * math.sin(now * 2.2 + l.phase)
			local g = GLOWBASE:Lerp(STYLE.link.glow, 0.3 + 0.5 * a)
			for _, r in ipairs(l.glowRects) do r.BackgroundColor3 = g end
			if l.badge.Visible then l.badge.Size = UDim2.fromOffset(34 + 4 * a, 34 + 4 * a) end
		end
	end)
end
local function stopPulse()
	if pulseConn then pulseConn:Disconnect(); pulseConn = nil end
end

--------------------------------------------------
-- PAN + ZOOM
--------------------------------------------------
local dragging, dragStart, boardStart
bg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		boardStart = boards[view].frame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not sg.Enabled then return end
	local b = boards[view]
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		b.frame.Position = UDim2.new(boardStart.X.Scale, boardStart.X.Offset + d.X, boardStart.Y.Scale, boardStart.Y.Offset + d.Y)
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		b.scale.Scale = math.clamp(b.scale.Scale + input.Position.Z * 0.08, 0.3, 1.6)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
local pinchStart
UserInputService.TouchPinch:Connect(function(_, scale, _, state)
	if not sg.Enabled then return end
	local b = boards[view]
	if state == Enum.UserInputState.Begin or not pinchStart then pinchStart = b.scale.Scale end
	b.scale.Scale = math.clamp(pinchStart * scale, 0.3, 1.6)
	if state == Enum.UserInputState.End then pinchStart = nil end
end)

--------------------------------------------------
-- HUD SNOW COUNTER IN FRONT OF THE PAGE
--------------------------------------------------
local lifted
local function liftCounter()
	if lifted then return end
	local rng = player.PlayerGui:FindFirstChild("RNGGui")
	local c = rng and rng:FindFirstChild("SnowCounter")
	if c then
		lifted = {counter = c, parent = rng}
		c.Parent = sg -- same full-screen inset settings, so it stays exactly where it was, just in front
	end
end
local function dropCounter()
	if not lifted then return end
	local c, p = lifted.counter, lifted.parent
	lifted = nil
	if c and c.Parent == sg then
		if p and p.Parent then c.Parent = p else c:Destroy() end
	end
end

--------------------------------------------------
-- ROLL CONTROLS IN FRONT OF THIS PAGE (2026-10-04, Claude)
--------------------------------------------------
-- While this page is open the dice / auto-roll bar and the roll reel sit on their own screen just above it, so you can keep
-- rolling while you buy. The reel is forced to its small version at the top and has nothing clickable (RollController), so clicks
-- go straight through it to the upgrade tiles. The side menus behind the page are hidden meanwhile (they only ghost through it).
local rollOverlay = mk("ScreenGui", {Name = "UpgradeRollOverlay", DisplayOrder = 151, IgnoreGuiInset = true, ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
pcall(function() rollOverlay.ScreenInsets = script.Parent.ScreenInsets end)
local liftedRoll
local function liftRoll()
	if liftedRoll then return end
	local rngGui = script.Parent
	local bar, reel = rngGui:FindFirstChild("BottomBar"), rngGui:FindFirstChild("RollStage")
	if not (bar and reel) then return end
	liftedRoll = {bar = bar, reel = reel, parent = rngGui}
	rngGui:SetAttribute("RollForceMini", true)
	reel.Parent = rollOverlay
	bar.Parent = rollOverlay
end
local function dropRoll()
	if not liftedRoll then return end
	local l = liftedRoll
	liftedRoll = nil
	if l.parent and l.parent.Parent then
		l.parent:SetAttribute("RollForceMini", false)
		l.reel.Parent = l.parent
		l.bar.Parent = l.parent
	end
end
local hiddenHud = {}
local function hideHud()
	for _, name in ipairs({"LeftMenu", "RightMenu", "SettingsCorner"}) do
		local o = script.Parent:FindFirstChild(name)
		if o and o:IsA("GuiObject") and o.Visible then
			o.Visible = false
			table.insert(hiddenHud, o)
		end
	end
end
local function showHud()
	for _, o in ipairs(hiddenHud) do if o.Parent then o.Visible = true end end
	hiddenHud = {}
end

--------------------------------------------------
-- OPEN / CLOSE
--------------------------------------------------
local function open()
	sg.Enabled = true
	placeTopLeft()
	placeBack()
	liftCounter()
	liftRoll()
	hideHud()
	blur.Parent = workspace.CurrentCamera
	tween(blur, 0.25, {Size = 18})
	view = "Main"
	for name, b in pairs(boards) do b.frame.Visible = name == view end
	title.Text = "UPGRADES"
	refresh(false)
	fitTo(view, false)
	startPulse()
end
local function close()
	sg.Enabled = false
	dropCounter()
	dropRoll()
	showHud()
	tween(blur, 0.2, {Size = 0})
	tip.Visible = false
	hovered = nil
	stopPulse()
end
openButton.Activated:Connect(function()
	if sg.Enabled then close() else open() end
end)
closeB.Activated:Connect(close)
script.Parent:WaitForChild("VillageOpenMenu").Event:Connect(function(name)
	if name == "Upgrades" then open() elseif sg.Enabled then close() end
end)

-- BACK (2026-10-04, Claude): Esc on the keyboard / B on a gamepad = back. Misc board -> main board, main board -> close the page.
-- (Esc normally opens Roblox's own menu: while this page is open that menu is closed again right away and Esc just goes back.)
local lastBack = 0
local function goBack()
	if not sg.Enabled then return end
	if os.clock() - lastBack < 0.3 then return end -- one key press can arrive twice (menu event + key event)
	lastBack = os.clock()
	if view ~= "Main" then switchView("Main") else close() end
end
GuiService.MenuOpened:Connect(function()
	if not sg.Enabled then return end
	pcall(function() GuiService:SetMenuIsOpen(false) end)
	goBack()
end)
UserInputService.InputBegan:Connect(function(input)
	if sg.Enabled and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then goBack() end
end)

-- live updates while open (snow changes often while digging: refresh at most 5x per second)
local pending = false
local function requestRefresh()
	if not sg.Enabled or pending then return end
	pending = true
	task.delay(0.2, function() pending = false; if sg.Enabled then refresh(true) end end)
end
for id in pairs(U.ById) do player:GetAttributeChangedSignal("Up_" .. id):Connect(requestRefresh) end
task.spawn(function()
	local stat = player:WaitForChild("leaderstats"):WaitForChild("Snow")
	stat.Changed:Connect(requestRefresh)
end)
for _, s in ipairs(StageConfig.Order) do
	if s.Id ~= "Starter" then player:GetAttributeChangedSignal("Stage_" .. s.Id):Connect(requestRefresh) end
end
