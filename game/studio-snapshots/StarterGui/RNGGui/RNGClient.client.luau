-- Main menus and the snowplow parts collection. Inventory is owned by PetClient.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local C = require(RS:WaitForChild("PlowConfig"))
local Assembly = require(RS:WaitForChild("PlowAssembly"))
local Api = require(RS:WaitForChild("PlowClientApi"))
local Format = require(RS:WaitForChild("NumberFormat"))
local remote = RS:WaitForChild("PlowRemote")
local player = Players.LocalPlayer
local gui = script.Parent
local menu = gui:WaitForChild("LeftMenu")
local panels = gui:WaitForChild("Panels")
local FONT, WHITE, OUTLINE = Enum.Font.FredokaOne, Color3.new(1, 1, 1), Color3.fromRGB(25, 45, 90)

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function bounce(btn)
	local s = btn:FindFirstChildOfClass("UIScale")
	if not s then return end
	btn.MouseEnter:Connect(function() tween(s, 0.12, {Scale = 1.1}) end)
	btn.MouseLeave:Connect(function() tween(s, 0.12, {Scale = 1}) end)
	btn.MouseButton1Down:Connect(function() tween(s, 0.08, {Scale = 0.88}) end)
	btn.MouseButton1Up:Connect(function() tween(s, 0.25, {Scale = 1.1}, Enum.EasingStyle.Back) end)
end
local blur = Instance.new("BlurEffect")
blur.Name, blur.Size, blur.Parent = "MenuBlur", 0, workspace.CurrentCamera
local openPanel
local function showPanel(p)
	local s = p:FindFirstChildOfClass("UIScale")
	p.Visible = true
	if s then s.Scale = 0.5; tween(s, 0.35, {Scale = 1}, Enum.EasingStyle.Back) end
end
local function hidePanel(p)
	local s = p:FindFirstChildOfClass("UIScale")
	if s then
		tween(s, 0.12, {Scale = 0.5}, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
			if openPanel ~= p then p.Visible = false end
		end)
	else p.Visible = false end
end
local function setBlur(on) tween(blur, 0.25, {Size = on and 16 or 0}) end
local function togglePanel(name)
	local target = panels:FindFirstChild(name or "")
	if not target then return end
	if openPanel then hidePanel(openPanel) end
	if openPanel == target then openPanel = nil; setBlur(false); return end
	openPanel = target
	showPanel(target)
	setBlur(true)
end
local function closeAll()
	if openPanel then hidePanel(openPanel); openPanel = nil; setBlur(false) end
end
gui:WaitForChild("VillageOpenMenu").Event:Connect(function(name)
	if name == "Upgrades" then closeAll(); return end
	if name == "Pets" then name = "Inventory" end
	local target = panels:FindFirstChild(name or "")
	if target and openPanel ~= target then togglePanel(name) end
end)
local menuButtons = menu:GetChildren()
local rightMenu = gui:FindFirstChild("RightMenu")
if rightMenu then for _, x in ipairs(rightMenu:GetChildren()) do table.insert(menuButtons, x) end end
local settingsCorner = gui:FindFirstChild("SettingsCorner")
if settingsCorner then
	for _, x in ipairs(settingsCorner:GetChildren()) do table.insert(menuButtons, x) end
	if game:GetService("UserInputService").TouchEnabled then
		settingsCorner.AnchorPoint = Vector2.new(1, 0)
		settingsCorner.Position = UDim2.new(1, -14, 0, 14)
	end
end
for _, b in ipairs(menuButtons) do
	if b:IsA("ImageButton") then bounce(b); b.Activated:Connect(function() togglePanel(b:GetAttribute("Panel")) end) end
end
for _, p in ipairs(panels:GetChildren()) do
	local close = p:FindFirstChild("Close")
	if close then bounce(close); close.Activated:Connect(closeAll) end
end
local function menuText(name, value)
	local b = menu:FindFirstChild(name)
	local l = b and b:FindFirstChild("Label")
	if l and (l:IsA("TextLabel") or l:IsA("TextButton")) then l.Text = value end
end
menuText("IndexButton", "PARTS")
menuText("InventoryButton", "PETS")

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function label(parent, name, text, pos, size, color)
	local l = mk("TextLabel", {Name = name, Text = text, Font = FONT, TextScaled = true, TextWrapped = true,
		TextColor3 = color or WHITE, BackgroundTransparency = 1, Position = pos, Size = size}, parent)
	mk("UIStroke", {Thickness = 2, Color = OUTLINE}, l)
	mk("UITextSizeConstraint", {MaxTextSize = 22}, l)
	return l
end
local colors = {}
for _, r in ipairs(C.Rarities) do colors[r.Id] = r.Color end
-- 2026-10-05 (Claude): 90-part collection, one tab per slot (30 cards each), ordered by world band; cards are only built while the panel is open.
local ids, slotOrder = {}, {}
local ROLE_ORDER = {S = 0, A = 1, M = 1.5, C = 2, B = 3} -- task 7: mid-band (M) parts right after the practical ones
for i, slot in ipairs(C.Slots) do slotOrder[slot] = i end
for id, def in pairs(C.Parts) do if def.Role ~= "P" then table.insert(ids, id) end end -- task 8: paid (game pass) parts are not part of the free collection
table.sort(ids, function(a, b)
	local x, y = C.Parts[a], C.Parts[b]
	if x.Slot ~= y.Slot then return (slotOrder[x.Slot] or 99) < (slotOrder[y.Slot] or 99) end
	if (x.Band or 0) ~= (y.Band or 0) then return (x.Band or 0) < (y.Band or 0) end
	if (ROLE_ORDER[x.Role] or 9) ~= (ROLE_ORDER[y.Role] or 9) then return (ROLE_ORDER[x.Role] or 9) < (ROLE_ORDER[y.Role] or 9) end
	return a < b
end)
local index = panels:WaitForChild("Index")
local inner = index:WaitForChild("Inner")
local content = inner:WaitForChild("Content")
local lastSignature
local slotFilter = "Blade"
local tabs = {}
local tabBar = mk("Frame", {Name = "SlotTabs", BackgroundTransparency = 1, Position = UDim2.fromScale(0.02, 0.01), Size = UDim2.fromScale(0.96, 0.105)}, inner)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, tabBar) -- task 7: slot order, not alphabetical
local render
for i, slot in ipairs(C.Slots) do
	local b = mk("TextButton", {Name = slot, Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(70, 150, 245), Size = UDim2.fromScale((0.96 - 0.02 * (#C.Slots - 1)) / #C.Slots, 1), LayoutOrder = i}, tabBar) -- task 7: tabs fit any number of slots
	b:SetAttribute("SnowUIDecor", true)
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, b)
	mk("UIStroke", {Thickness = 3, Color = OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
	local l = label(b, "Label", ({Blade = "BLADES", Engine = "ENGINES", Gear = "WHEELS & TRACKS", Body = "BODIES"})[slot] or slot:upper(), UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.9, 0.76))
	tabs[slot] = b
	b.Activated:Connect(function()
		slotFilter = slot; lastSignature = nil
		render(Api.State)
	end)
end
local function partCard(id, order, state)
	local def = C.Parts[id]
	local count = math.max(0, tonumber(state.Parts and state.Parts[id]) or 0)
	local owned = count > 0
	local equipped = state.Build and state.Build[def.Slot] == id
	local color = owned and (colors[def.Rarity] or WHITE) or Color3.fromRGB(150, 160, 185)
	local holder = mk("Frame", {Name = id, BackgroundTransparency = 1, LayoutOrder = order}, content)
	holder:SetAttribute("PartId", id)
	holder:SetAttribute("Owned", owned)
	holder:SetAttribute("Equipped", equipped == true)
	local main = mk("Frame", {Name = "Main", BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1)}, holder)
	main:SetAttribute("SnowUIDecor", true)
	mk("UICorner", {CornerRadius = UDim.new(0.16, 0)}, main)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(color:Lerp(WHITE, 0.55), color)}, main)
	mk("UIStroke", {Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = equipped and Color3.fromRGB(60, 230, 90) or color:Lerp(Color3.new(0, 0, 0), 0.45)}, main)
	local vp = mk("ViewportFrame", {Name = "PartPreview", BackgroundTransparency = 1, Position = UDim2.fromScale(0.08, 0.03),
		Size = UDim2.fromScale(0.84, 0.43), Ambient = Color3.fromRGB(200, 200, 210), LightColor = WHITE,
		LightDirection = Vector3.new(-0.4, -1, -0.6)}, main)
	local model = Assembly.PartModel(id)
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then d:Destroy()
			elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanTouch = false end
		end
		model:PivotTo(CFrame.new())
		model.Parent = vp
		local cf, size = model:GetBoundingBox()
		local dist = math.max(size.X, size.Y, size.Z) * 1.7 + 1
		local cam = mk("Camera", {FieldOfView = 40, CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.45, dist * 0.3, -dist), cf.Position)}, vp)
		vp.CurrentCamera = cam
	else label(main, "MissingPreview", "?", UDim2.fromScale(0.1, 0.03), UDim2.fromScale(0.8, 0.4)) end
	label(main, "Name", def.Name, UDim2.fromScale(0.04, 0.48), UDim2.fromScale(0.92, 0.16))
	label(main, "Category", (def.Theme or def.Slot) .. " · " .. def.Rarity, UDim2.fromScale(0.05, 0.65), UDim2.fromScale(0.9, 0.1))
	label(main, "Status", equipped and "EQUIPPED" or owned and ("OWNED x" .. count) or "NOT OWNED",
		UDim2.fromScale(0.05, 0.77), UDim2.fromScale(0.9, 0.1), equipped and Color3.fromRGB(140, 255, 150) or WHITE)
	label(main, "Price", def.Price == 0 and "FREE STARTER" or (Format.Abbreviate(def.Price) .. " Snow"),
		UDim2.fromScale(0.05, 0.88), UDim2.fromScale(0.9, 0.08))
end
function render(state)
	if type(state) ~= "table" or type(state.Parts) ~= "table" then return end
	local key, owned = {slotFilter}, 0
	for _, id in ipairs(ids) do
		local n = tonumber(state.Parts[id]) or 0
		if n > 0 then owned += 1 end
		if C.Parts[id].Slot == slotFilter then table.insert(key, id .. ":" .. n .. ":" .. tostring(state.Build and state.Build[C.Parts[id].Slot] == id)) end
	end
	index.Banner.Title.Text = ("PARTS %d/%d"):format(owned, #ids)
	for slot, b in pairs(tabs) do b.BackgroundColor3 = slot == slotFilter and Color3.fromRGB(70, 200, 105) or Color3.fromRGB(70, 150, 245) end
	if not index.Visible then return end -- build the cards when the panel opens
	local signature = table.concat(key, "|")
	if signature == lastSignature then return end
	lastSignature = signature
	for _, c in ipairs(content:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local order = 0
	for _, id in ipairs(ids) do
		if C.Parts[id].Slot == slotFilter then order += 1; partCard(id, order, state) end
	end
end
Api.Changed.Event:Connect(function() render(Api.State) end)
render(Api.State)
task.spawn(function()
	for _ = 1, 20 do
		local ok, res = pcall(function() return remote:InvokeServer("State") end)
		if ok and type(res) == "table" and res.state then render(res.state); return end
		task.wait(0.5)
	end
	index.Banner.Title.Text = "PARTS - RECONNECTING"
end)
index:GetPropertyChangedSignal("Visible"):Connect(function()
	if index.Visible then render(Api.State) end
end)
