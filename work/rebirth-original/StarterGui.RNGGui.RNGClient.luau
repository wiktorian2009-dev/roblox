-- RNGClient: side menu, panels, Index/Inventory cards, equip buttons, settings.
-- Rolling itself lives in RollController.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("RNGConfig"))
local ItemIcon = require(ReplicatedStorage:WaitForChild("ItemIcon"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local getInventory = ReplicatedStorage:WaitForChild("GetInventory")
local equipRemote = ReplicatedStorage:WaitForChild("EquipShovel")

local gui = script.Parent
local menu = gui:WaitForChild("LeftMenu")
local panels = gui:WaitForChild("Panels")
local rollFinished = gui:WaitForChild("RollFinished")

local FONT = Enum.Font.FredokaOne
local OUTLINE = Color3.fromRGB(25, 45, 90)
local WHITE = Color3.new(1, 1, 1)
local MAX_EQUIPPED = Config.MaxEquipped or 2

local counts = {}
local equipped = {}
local refresh -- forward declaration

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function lighten(c, a) return c:Lerp(WHITE, a) end
local function darken(c, a) return c:Lerp(Color3.new(0, 0, 0), a) end

local function bounce(btn)
	local s = btn:FindFirstChildOfClass("UIScale")
	if not s then return end
	btn.MouseEnter:Connect(function() tween(s, 0.12, {Scale = 1.1}) end)
	btn.MouseLeave:Connect(function() tween(s, 0.12, {Scale = 1}) end)
	btn.MouseButton1Down:Connect(function() tween(s, 0.08, {Scale = 0.88}) end)
	btn.MouseButton1Up:Connect(function() tween(s, 0.25, {Scale = 1.1}, Enum.EasingStyle.Back) end)
end

--------------------------------------------------
-- PANELS
--------------------------------------------------
local blur = Instance.new("BlurEffect")
blur.Name = "MenuBlur"
blur.Size = 0
blur.Parent = workspace.CurrentCamera

local openPanel = nil
local function showPanel(p)
	local s = p:FindFirstChildOfClass("UIScale")
	p.Visible = true
	s.Scale = 0.5
	tween(s, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
end
local function hidePanel(p)
	local s = p:FindFirstChildOfClass("UIScale")
	tween(s, 0.12, {Scale = 0.5}, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
		if openPanel ~= p then p.Visible = false end
	end)
end
local function setBlur(on) tween(blur, 0.25, {Size = on and 16 or 0}) end

local function togglePanel(name)
	local target = panels:FindFirstChild(name)
	if not target then return end
	if openPanel then hidePanel(openPanel) end
	if openPanel == target then
		openPanel = nil
		setBlur(false)
		return
	end
	openPanel = target
	showPanel(target)
	setBlur(true)
end
local function closeAll()
	if openPanel then
		hidePanel(openPanel)
		openPanel = nil
		setBlur(false)
	end
end

local menuButtons = menu:GetChildren()
local settingsCorner = gui:FindFirstChild("SettingsCorner")
if settingsCorner then
	for _, x in ipairs(settingsCorner:GetChildren()) do table.insert(menuButtons, x) end
	-- phones/tablets have the jump button bottom-right, so put Settings top-right there
	if game:GetService("UserInputService").TouchEnabled then
		settingsCorner.AnchorPoint = Vector2.new(1, 0)
		settingsCorner.Position = UDim2.new(1, -14, 0, 14)
	end
end
for _, b in ipairs(menuButtons) do
	if b:IsA("ImageButton") then
		bounce(b)
		b.Activated:Connect(function() togglePanel(b:GetAttribute("Panel")) end)
	end
end
for _, p in ipairs(panels:GetChildren()) do
	local c = p:FindFirstChild("Close")
	if c then
		bounce(c)
		c.Activated:Connect(closeAll)
	end
end

--------------------------------------------------
-- EQUIPPING
--------------------------------------------------
local function copiesEquipped(name)
	local n = 0
	for _, e in ipairs(equipped) do if e == name then n += 1 end end
	return n
end

local busy = false
local function sendEquip(action, name)
	if busy then return end
	busy = true
	local ok, res = pcall(function() return equipRemote:InvokeServer(action, name) end)
	busy = false
	if ok and type(res) == "table" then
		equipped = res
		refresh()
	end
end

--------------------------------------------------
-- CARDS
--------------------------------------------------
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(p, s) mk("UICorner", {CornerRadius = UDim.new(s, 0)}, p) end
local function label(parent, t, props, st)
	local l = mk("TextLabel", {Font = FONT, TextScaled = true, TextColor3 = WHITE, BackgroundTransparency = 1, Text = t}, nil)
	for k, v in pairs(props) do l[k] = v end
	if st ~= false then mk("UIStroke", {Thickness = st or 2.5, Color = OUTLINE}, l) end
	l.Parent = parent
	return l
end
local function smallButton(parent, props, color, text)
	local b = mk("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = color}, parent)
	for k, v in pairs(props) do b[k] = v end
	round(b, 1)
	mk("UIStroke", {Thickness = 3, Color = OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
	local s = mk("UIScale", {Scale = 1}, b)
	label(b, text, {Position = UDim2.fromScale(0.08, 0.14), Size = UDim2.fromScale(0.84, 0.72)}, 2)
	b.MouseEnter:Connect(function() tween(s, 0.12, {Scale = 1.08}) end)
	b.MouseLeave:Connect(function() tween(s, 0.12, {Scale = 1}) end)
	b.MouseButton1Down:Connect(function() tween(s, 0.08, {Scale = 0.9}) end)
	return b
end

local function card(parent, order, item, count, locked, mode)
	local color = locked and Color3.fromRGB(165, 172, 190) or (Config.Rarities[item.Rarity] or Color3.fromRGB(180, 180, 190))

	local holder = mk("Frame", {BackgroundTransparency = 1, LayoutOrder = order}, nil)
	local scale = mk("UIScale", {Scale = 1}, holder)
	local shadow = mk("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.78,
		Position = UDim2.new(0, 0, 0, 6), Size = UDim2.fromScale(1, 1)}, holder)
	round(shadow, 0.16)

	local main = mk("Frame", {Name = "Main", BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1)}, holder)
	round(main, 0.16)
	mk("UIGradient", {Color = ColorSequence.new(lighten(color, 0.55), color), Rotation = 90}, main)
	local stroke = mk("UIStroke", {Thickness = 4, Color = darken(color, 0.45), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, main)

	if locked then
		label(main, "?", {Position = UDim2.fromScale(0.1, 0.05), Size = UDim2.fromScale(0.8, 0.43)}, 3)
	else
		local iconBox = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.15, 0.05), Size = UDim2.fromScale(0.7, 0.43)}, main)
		ItemIcon.create(item).Parent = iconBox
	end
	label(main, locked and "???" or item.Name, {Position = UDim2.fromScale(0.06, 0.5), Size = UDim2.fromScale(0.88, 0.19)}, 2.5)

	if mode == "inventory" then
		local on = copiesEquipped(item.Name)
		local canAdd = on < count
		local eb = smallButton(main, {Name = "EquipButton", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.73),
			Size = UDim2.fromScale(0.86, 0.18)}, canAdd and Color3.fromRGB(60, 150, 255) or Color3.fromRGB(70, 200, 90),
			canAdd and "EQUIP" or "EQUIPPED")
		eb.Activated:Connect(function()
			if canAdd then sendEquip("equip", item.Name) end
		end)
		if on > 0 then
			stroke.Color = Color3.fromRGB(60, 230, 90)
			stroke.Thickness = 6
			local x = smallButton(holder, {Name = "UnequipButton", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.12, 0.07),
				Size = UDim2.fromScale(0.26, 0.26)}, Color3.fromRGB(235, 70, 80), "X")
			mk("UIAspectRatioConstraint", {AspectRatio = 1}, x)
			x.Activated:Connect(function() sendEquip("unequip", item.Name) end)
			if on > 1 then
				label(main, "ON x" .. on, {Position = UDim2.fromScale(0.25, 0.36), Size = UDim2.fromScale(0.5, 0.12),
					TextColor3 = Color3.fromRGB(120, 255, 130)}, 2.5)
			end
		end
	else
		local pill = mk("Frame", {BackgroundColor3 = OUTLINE, BackgroundTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.74), Size = UDim2.fromScale(0.82, 0.16)}, main)
		round(pill, 1)
		label(pill, "1 in " .. NumberFormat.Abbreviate(item.Chance), {Position = UDim2.fromScale(0.1, 0.14), Size = UDim2.fromScale(0.8, 0.72),
			TextColor3 = Color3.fromRGB(110, 255, 110)}, false)
	end

	if not locked and item.Chance >= 10 then
		local shine = mk("Frame", {BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1), Active = false}, main)
		round(shine, 0.16)
		local g = mk("UIGradient", {Rotation = 25, Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1)})}, shine)
		TweenService:Create(g, TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 1),
			{Offset = Vector2.new(1, 0)}):Play()
	end

	if count and count > 0 then
		local badge = mk("Frame", {BackgroundColor3 = Color3.fromRGB(255, 215, 60), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.86, 0.07), Size = UDim2.fromScale(0.38, 0.17)}, holder)
		round(badge, 1)
		mk("UIStroke", {Thickness = 3, Color = OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, badge)
		label(badge, "x" .. count, {Position = UDim2.fromScale(0.12, 0.12), Size = UDim2.fromScale(0.76, 0.76), TextColor3 = OUTLINE}, false)
	end

	main.MouseEnter:Connect(function() tween(scale, 0.15, {Scale = 1.04}, Enum.EasingStyle.Back) end)
	main.MouseLeave:Connect(function() tween(scale, 0.15, {Scale = 1}) end)
	holder.Parent = parent
end

local function clear(sc)
	for _, c in ipairs(sc:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end

refresh = function()
	local idx = panels.Index.Inner.Content
	local inv = panels.Inventory.Inner.Content
	clear(idx); clear(inv)
	local owned = 0
	for i, item in ipairs(Config.Items) do
		local n = counts[item.Name] or 0
		if n > 0 then
			owned += 1
			card(idx, i, item, n, false, "index")
			card(inv, i, item, n, false, "inventory")
		else
			card(idx, i, item, 0, true, "index")
		end
	end
	if owned == 0 then
		label(inv, "Roll to find your first shovel! ❄", {Size = UDim2.new(1, 0, 0, 50)}, 3)
	end
	panels.Index.Banner.Title.Text = ("INDEX %d/%d"):format(owned, #Config.Items)
	if panels.Inventory:GetAttribute("Tab") ~= "Pets" then panels.Inventory.Banner.Title.Text = ("INVENTORY %d/%d"):format(#equipped, game.Players.LocalPlayer:GetAttribute("ShovelSlots") or MAX_EQUIPPED) end
end

rollFinished.Event:Connect(function(_, newCounts, newEquipped)
	if newCounts then counts = newCounts end
	if type(newEquipped) == "table" then equipped = newEquipped end
	refresh()
end)

--------------------------------------------------
-- SETTINGS (shared with RollController via attribute)
--------------------------------------------------
gui:SetAttribute("FastRolls", false)
local tog = panels.Settings.Inner.Content.SkipRow.SkipAnim
local knob = tog.Knob
tog.Activated:Connect(function()
	local on = not gui:GetAttribute("FastRolls")
	gui:SetAttribute("FastRolls", on)
	tween(knob, 0.2, {Position = on and UDim2.fromScale(0.54, 0.5) or UDim2.fromScale(0.06, 0.5)}, Enum.EasingStyle.Back)
	tween(tog, 0.2, {BackgroundColor3 = on and Color3.fromRGB(80, 210, 110) or Color3.fromRGB(190, 196, 212)})
end)

--------------------------------------------------
-- LOAD SAVED DATA
--------------------------------------------------
refresh()
task.spawn(function()
	for _ = 1, 20 do
		local ok, res = pcall(function() return getInventory:InvokeServer() end)
		if ok and type(res) == "table" then
			counts = res.Counts or {}
			equipped = res.Equipped or {}
			break
		end
		task.wait(0.5)
	end
	refresh()
end)

-- admin commands changed our shovels: reload
ReplicatedStorage:WaitForChild("DataRefresh").OnClientEvent:Connect(function()
	local ok, res = pcall(function() return getInventory:InvokeServer() end)
	if ok and type(res) == "table" then
		counts = res.Counts or {}
		equipped = res.Equipped or {}
		refresh()
	end
end)

