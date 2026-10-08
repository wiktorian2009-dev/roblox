-- UpgradeTreeClient: full-screen hexagon upgrade trees (picker -> tree), drag to pan, wheel to zoom.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local U = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local buyRemote = ReplicatedStorage:WaitForChild("BuyUpgrade")
local player = Players.LocalPlayer
local openButton = script.Parent:WaitForChild("BottomBar"):WaitForChild("UpgradesButton")

local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(15, 20, 35)
local SQ3 = math.sqrt(3)
local R = 56              -- hex radius (px)
local GAP = 5             -- space between hexes

-- tile colours
local OWNED_FILL = Color3.fromRGB(70, 165, 255)
local AVAIL_FILL = Color3.fromRGB(45, 80, 160)
local LOCK_FILL  = Color3.fromRGB(40, 45, 62)
local CENTER_FILL = Color3.fromRGB(235, 55, 85)

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
local function ownedSet()
	local set = {}
	for id in pairs(U.ById) do if player:GetAttribute("Up_" .. id) == true then set[id] = true end end
	return set
end

-- a pointy-top hexagon made of 3 rotated rectangles
local function hex(parent, radius, color, z, name)
	local h = mk("Frame", {Name = name or "Hex", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(radius * SQ3, radius * 2), BackgroundTransparency = 1, ZIndex = z}, parent)
	for _, rot in ipairs({0, 60, 120}) do
		mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(radius * SQ3, radius),
			Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z}, h)
	end
	return h
end
local function setHexColor(h, color, transparency)
	for _, r in ipairs(h:GetChildren()) do
		if r:IsA("Frame") then
			r.BackgroundColor3 = color
			if transparency then r.BackgroundTransparency = transparency end
		end
	end
end

--------------------------------------------------
-- SCREEN
--------------------------------------------------
local sg = mk("ScreenGui", {Name = "UpgradeTreeGui", DisplayOrder = 60, IgnoreGuiInset = true, ResetOnSpawn = false, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
local bg = mk("Frame", {Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(18, 22, 30), BackgroundTransparency = 0.04,
	BorderSizePixel = 0, Active = true}, sg)
local board = mk("Frame", {Name = "Board", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1}, bg)
local boardScale = mk("UIScale", {Scale = 1}, board)

local title = text(bg, "", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.03), Size = UDim2.fromScale(0.4, 0.07)}, 4)
local snowLabel = text(bg, "", {AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 20, 0.04, 0), Size = UDim2.fromScale(0.2, 0.055),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(150, 225, 255)}, 3)
local completed = text(bg, "", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.985), Size = UDim2.fromScale(0.3, 0.04)}, 3)

-- bottom buttons
local function bigButton(name, label, color, xScale)
	local b = mk("TextButton", {Name = name, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(xScale, 0.93),
		Size = UDim2.fromScale(0.13, 0.08), BackgroundColor3 = color, ZIndex = 5}, bg)
	mk("UIAspectRatioConstraint", {AspectRatio = 2.4}, b)
	mk("UICorner", {CornerRadius = UDim.new(0.35, 0)}, b)
	mk("UIStroke", {Thickness = 4, Color = DARK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
	mk("UIGradient", {Color = ColorSequence.new(color:Lerp(WHITE, 0.3), color), Rotation = 90}, b)
	local sc = mk("UIScale", {Scale = 1}, b)
	text(b, label, {Position = UDim2.fromScale(0.1, 0.12), Size = UDim2.fromScale(0.8, 0.76), ZIndex = 6}, 4)
	b.MouseEnter:Connect(function() tween(sc, 0.12, {Scale = 1.06}, Enum.EasingStyle.Back) end)
	b.MouseLeave:Connect(function() tween(sc, 0.12, {Scale = 1}) end)
	b.MouseButton1Down:Connect(function() tween(sc, 0.07, {Scale = 0.92}) end)
	b.MouseButton1Up:Connect(function() tween(sc, 0.3, {Scale = 1}, Enum.EasingStyle.Back) end)
	return b
end
local exitB = bigButton("Exit", "Exit", Color3.fromRGB(240, 40, 90), 0.42)
local backB = bigButton("Back", "Back", Color3.fromRGB(90, 215, 255), 0.58)

-- info card (above the buttons)
local card = mk("Frame", {Name = "Info", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.83), Size = UDim2.fromScale(0.34, 0.11),
	BackgroundColor3 = Color3.fromRGB(28, 36, 58), Visible = false, ZIndex = 5}, bg)
mk("UIAspectRatioConstraint", {AspectRatio = 5}, card)
mk("UICorner", {CornerRadius = UDim.new(0.25, 0)}, card)
mk("UIStroke", {Thickness = 3, Color = Color3.fromRGB(110, 200, 255), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, card)
local cardName = text(card, "", {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.6, 0.38), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6}, 3)
local cardDesc = text(card, "", {Position = UDim2.fromScale(0.04, 0.52), Size = UDim2.fromScale(0.6, 0.32), TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(170, 235, 170), ZIndex = 6}, 2)
local buyB = mk("TextButton", {Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.3, 0.72),
	BackgroundColor3 = Color3.fromRGB(70, 200, 90), ZIndex = 6}, card)
mk("UICorner", {CornerRadius = UDim.new(0.4, 0)}, buyB)
mk("UIStroke", {Thickness = 3, Color = DARK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, buyB)
local buyScale = mk("UIScale", {Scale = 1}, buyB)
local buyText = text(buyB, "", {Position = UDim2.fromScale(0.08, 0.14), Size = UDim2.fromScale(0.84, 0.72), ZIndex = 7}, 2.5)

local blur = Instance.new("BlurEffect")
blur.Name = "UpgradeBlur"
blur.Size = 0

--------------------------------------------------
-- TILES
--------------------------------------------------
local currentTree = nil
local tiles = {}          -- [id] = tile table
local selected = nil
local refresh

local function hexPos(q, r)
	local s = R + GAP
	return Vector2.new(s * SQ3 * (q + r / 2), s * 1.5 * r)
end

local function makeTile(parent, n, pos, radius, colorAccent)
	local holder = mk("Frame", {Name = n.Id or n.Name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(radius * SQ3, radius * 2), BackgroundTransparency = 1, ZIndex = 2}, parent)
	local scale = mk("UIScale", {Scale = 1}, holder)
	local glow = hex(holder, radius + 7, colorAccent, 2, "Glow")
	setHexColor(glow, colorAccent, 0.75)
	local border = hex(holder, radius, WHITE, 3, "Border")
	local fillGroup = mk("CanvasGroup", {Name = "Fill", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(radius * SQ3, radius * 2), BackgroundTransparency = 1, ZIndex = 4}, holder)
	local fill = hex(fillGroup, radius - 5, OWNED_FILL, 4, "FillHex")
	mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 185, 205)), Rotation = 90}, fillGroup)
	-- icon slot (shown when the node has an Icon)
	local icon = mk("ImageLabel", {Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromScale(0.7, 0.5), ScaleType = Enum.ScaleType.Fit, Image = n.Icon or "", Visible = (n.Icon or "") ~= "", ZIndex = 5}, holder)
	local hasIcon = icon.Visible
	local name = text(holder, n.Name, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, hasIcon and 0.7 or 0.46),
		Size = UDim2.fromScale(0.82, hasIcon and 0.22 or 0.34), TextWrapped = true, ZIndex = 6}, 2.5)
	local price = text(holder, "", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, hasIcon and 0.86 or 0.72),
		Size = UDim2.fromScale(0.7, 0.16), TextColor3 = Color3.fromRGB(255, 225, 90), ZIndex = 6}, 2.5)
	local hit = mk("TextButton", {Name = "Hit", Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.95, 0.8), ZIndex = 8}, holder)
	return {holder = holder, scale = scale, glow = glow, border = border, fill = fill, fillGroup = fillGroup, name = name, price = price, hit = hit, node = n}
end

local function clearBoard()
	for _, c in ipairs(board:GetChildren()) do
		if not c:IsA("UIScale") then c:Destroy() end
	end
	tiles = {}
	selected = nil
	card.Visible = false
end

local function openTree(tree)
	clearBoard()
	currentTree = tree
	title.Text = tree.Name .. " UPGRADES"
	title.TextColor3 = tree.Color
	backB.Visible = true
	completed.Visible = true
	board.Position = UDim2.fromScale(0.5, 0.45)
	boardScale.Scale = 1
	for _, n in ipairs(tree.Nodes) do
		local t = makeTile(board, n, hexPos(n.Q, n.R), R, tree.Color)
		tiles[n.Id] = t
		t.hit.MouseEnter:Connect(function() tween(t.scale, 0.12, {Scale = 1.08}, Enum.EasingStyle.Back) end)
		t.hit.MouseLeave:Connect(function() tween(t.scale, 0.12, {Scale = 1}) end)
		t.hit.Activated:Connect(function()
			selected = n
			refresh()
		end)
	end
	refresh()
end

--------------------------------------------------
-- PICKER (choose a tree)
--------------------------------------------------
local function openPicker()
	clearBoard()
	currentTree = nil
	title.Text = "UPGRADES"
	title.TextColor3 = WHITE
	backB.Visible = false
	completed.Visible = false
	board.Position = UDim2.fromScale(0.5, 0.47)
	boardScale.Scale = 1
	local set = ownedSet()
	for i, tree in ipairs(U.Trees) do
		local done = 0
		for _, n in ipairs(tree.Nodes) do if set[n.Id] then done += 1 end end
		local t = makeTile(board, {Name = tree.Name, Id = "Pick_" .. tree.Id}, Vector2.new((i - 2) * 270, 0), 115, tree.Color)
		setHexColor(t.fill, tree.Color:Lerp(Color3.new(0, 0, 0), 0.25))
		t.name.TextSize = 40
		t.price.Text = done .. "/" .. #tree.Nodes
		t.price.TextColor3 = WHITE
		t.hit.MouseEnter:Connect(function() tween(t.scale, 0.12, {Scale = 1.06}, Enum.EasingStyle.Back) end)
		t.hit.MouseLeave:Connect(function() tween(t.scale, 0.12, {Scale = 1}) end)
		t.hit.Activated:Connect(function() openTree(tree) end)
	end
end

--------------------------------------------------
-- REFRESH
--------------------------------------------------
refresh = function()
	snowLabel.Text = "❄ " .. NumberFormat.Abbreviate(snow())
	if not currentTree then return end
	local set = ownedSet()
	local done = 0
	for id, t in pairs(tiles) do
		local n = t.node
		local have = set[id]
		local avail = U.Available(n, set)
		if have then done += 1 end
		if have then
			setHexColor(t.fill, n.Center and CENTER_FILL or OWNED_FILL)
			setHexColor(t.border, WHITE)
			t.glow.Visible = true
			t.fillGroup.GroupTransparency = 0
			t.name.TextTransparency = 0
			t.price.Text = ""
		elseif avail then
			setHexColor(t.fill, n.Center and CENTER_FILL or AVAIL_FILL)
			setHexColor(t.border, currentTree.Color)
			t.glow.Visible = false
			t.fillGroup.GroupTransparency = 0
			t.name.TextTransparency = 0
			t.price.Text = "❄ " .. NumberFormat.Abbreviate(U.CostOf(n))
			t.price.TextColor3 = snow() >= U.CostOf(n) and Color3.fromRGB(255, 225, 90) or Color3.fromRGB(255, 120, 120)
		else
			setHexColor(t.fill, LOCK_FILL)
			setHexColor(t.border, Color3.fromRGB(70, 78, 98))
			t.glow.Visible = false
			t.fillGroup.GroupTransparency = 0.1
			t.name.TextTransparency = 0.45
			t.price.Text = ""
		end
		t.holder.ZIndex = (selected == n) and 3 or 2
	end
	completed.Text = done .. "/" .. #currentTree.Nodes .. " Completed!"

	-- info card
	local n = selected
	card.Visible = n ~= nil
	if n then
		cardName.Text = n.Name
		cardName.TextColor3 = currentTree.Color
		cardDesc.Text = n.Text or ""
		local cost = U.CostOf(n)
		if set[n.Id] then
			buyText.Text = "OWNED ✓"
			buyB.BackgroundColor3 = Color3.fromRGB(90, 110, 150)
		elseif not U.Available(n, set) then
			buyText.Text = "🔒 LOCKED"
			buyB.BackgroundColor3 = Color3.fromRGB(90, 95, 115)
		elseif snow() >= cost then
			buyText.Text = "BUY  ❄ " .. NumberFormat.Abbreviate(cost)
			buyB.BackgroundColor3 = Color3.fromRGB(70, 200, 90)
		else
			buyText.Text = "❄ " .. NumberFormat.Abbreviate(cost)
			buyB.BackgroundColor3 = Color3.fromRGB(200, 70, 80)
		end
	end
end

local busy = false
buyB.Activated:Connect(function()
	local n = selected
	if busy or not n then return end
	busy = true
	buyScale.Scale = 0.9
	tween(buyScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
	local ok, res = pcall(function() return buyRemote:InvokeServer(n.Id) end)
	busy = false
	if ok and res == true and tiles[n.Id] then
		local t = tiles[n.Id]
		t.scale.Scale = 1.3
		tween(t.scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
		-- neighbours that just became available pop a little
		task.delay(0.1, function()
			for _, nb in ipairs(U.Neighbours(n)) do
				local tt = tiles[nb.Id]
				if tt then
					tt.scale.Scale = 1.12
					tween(tt.scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
				end
			end
		end)
	end
	refresh()
end)

--------------------------------------------------
-- PAN + ZOOM
--------------------------------------------------
local dragging, dragStart, boardStart
bg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		boardStart = board.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not sg.Enabled then return end
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		board.Position = UDim2.new(boardStart.X.Scale, boardStart.X.Offset + d.X, boardStart.Y.Scale, boardStart.Y.Offset + d.Y)
	elseif input.UserInputType == Enum.UserInputType.MouseWheel and currentTree then
		boardScale.Scale = math.clamp(boardScale.Scale + input.Position.Z * 0.08, 0.5, 1.5)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--------------------------------------------------
-- OPEN / CLOSE
--------------------------------------------------
local function open()
	sg.Enabled = true
	blur.Parent = workspace.CurrentCamera
	tween(blur, 0.25, {Size = 18})
	openPicker()
	refresh()
end
local function close()
	sg.Enabled = false
	tween(blur, 0.2, {Size = 0})
	clearBoard()
end
openButton.Activated:Connect(function()
	if sg.Enabled then close() else open() end
end)
exitB.Activated:Connect(close)
backB.Activated:Connect(openPicker)

for id in pairs(U.ById) do
	player:GetAttributeChangedSignal("Up_" .. id):Connect(function() if sg.Enabled then refresh() end end)
end
task.spawn(function()
	local stat = player:WaitForChild("leaderstats"):WaitForChild("Snow")
	stat.Changed:Connect(function() if sg.Enabled then refresh() end end)
end)

