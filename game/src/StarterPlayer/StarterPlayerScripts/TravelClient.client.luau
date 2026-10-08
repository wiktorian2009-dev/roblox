-- TravelClient (2026-10-05, Claude): the snowy TRAVEL menu + the compact TRAVEL button next to HELP + the lobby pad prompt.
-- Lists Lobby, My Garage and every stage of StageConfig (TravelConfig), split by world, marks the current spot and shows the real
-- unlock requirement of locked stages. Sends only a destination id to the server (TravelRemote); the server validates and moves you.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local T = require(RS:WaitForChild("TravelConfig"))
local Art = require(RS:WaitForChild("FeatureUIArt"))
local remote = RS:WaitForChild("TravelRemote", 30)
if not remote then return end
local pg = player:WaitForChild("PlayerGui")
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function stroke(o, t, c) return mk("UIStroke", {Thickness = t or 2.5, Color = c or NAVY, ApplyStrokeMode = o:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border}, o) end
local function label(parent, text, props)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE, ZIndex = 3}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	stroke(l, 2, NAVY)
	return l
end

------------------------------------------------ HUD button (under HELP)
local hud = mk("ScreenGui", {Name = "TravelGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 12}, pg)
local btn = mk("TextButton", {Name = "TravelButton", Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(110, 175, 255),
	AnchorPoint = Vector2.new(0, 0), Size = UDim2.fromOffset(170, 42), Position = UDim2.new(0.11, 0, 0.84, 0), Visible = false, Selectable = true}, hud)
btn:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, btn)
stroke(btn, 3)
Art.Skin(btn)
Art.Icon(btn, "teleport", UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.18, 0.84), "FeatureTravelIcon")
label(btn, "TRAVEL", {Name = "TravelLabel", Size = UDim2.fromScale(0.73, 0.72), Position = UDim2.fromScale(0.23, 0.14)})
local helpBtn
local function placeButton()
	if helpBtn and helpBtn.Parent and helpBtn.AbsoluteSize.X > 0 then
		-- use the same top-bar inset rules as HELP's ScreenGui, so both share one coordinate space
		local sg = helpBtn:FindFirstAncestorOfClass("ScreenGui")
		if sg then
			hud.IgnoreGuiInset = sg.IgnoreGuiInset
			pcall(function() hud.ScreenInsets = sg.ScreenInsets end)
		end
		local ap, as = helpBtn.AbsolutePosition, helpBtn.AbsoluteSize
		-- 2026-10-06 (wiktor: "travel and help should be placed on each other"): TRAVEL stands directly UNDER HELP, same width and
		-- height, small even gap (was beside it). The HELP REQUEST pill (when up) stays above HELP, so the column reads pill / HELP / TRAVEL.
		btn.Size = UDim2.fromOffset(math.floor(as.X), math.floor(as.Y))
		-- AbsolutePosition is measured below the top bar even in an IgnoreGuiInset gui, so add the inset back for Position
		local top = hud.IgnoreGuiInset and GuiService:GetGuiInset().Y or 0
		local gap = math.max(6, math.floor(as.Y * 0.18))
		btn.Position = UDim2.fromOffset(math.floor(ap.X), math.floor(ap.Y + as.Y + gap + top))
	end
end
task.spawn(function() -- the HELP button is made at runtime by the tutorial; follow it so TRAVEL never overlaps it on any screen size
	for _ = 1, 120 do
		for _, d in ipairs(pg:GetDescendants()) do
			if (d:IsA("TextButton") or d:IsA("ImageButton")) and d ~= btn and d.Visible then
				local txt = d:IsA("TextButton") and d.Text or ""
				local child = d:FindFirstChildWhichIsA("TextLabel")
				-- the bottom-left HUD HELP button (not the tutorial card's small "? HELP" at the top)
				local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
				local bottomLeft = d.AbsolutePosition.Y > vp.Y * 0.55 and d.AbsolutePosition.X < vp.X * 0.3
				if bottomLeft and (txt:upper():find("HELP") or (child and child.Text:upper():find("HELP"))) and d.AbsoluteSize.X > 0 then helpBtn = d break end
			end
		end
		if helpBtn then break end
		task.wait(0.5)
	end
	if helpBtn then
		helpBtn:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeButton)
		helpBtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)
		placeButton()
	end
end)
local function hudVisible()
	return player:GetAttribute("PlowTutorialDone") == true and player:GetAttribute("InArenaIsland") ~= true and player:GetAttribute("IntroActive") ~= true
end
local function refreshHud() btn.Visible = hudVisible() end
for _, a in ipairs({"PlowTutorialDone", "InArenaIsland", "IntroActive"}) do player:GetAttributeChangedSignal(a):Connect(refreshHud) end
refreshHud()

------------------------------------------------ the menu (built from the Settings panel so it matches the snowy panels)
local panel, content, toast, rows = nil, nil, nil, {}
local current, pendingConfirm = nil, nil
local refresh -- defined below (rows call it after a travel attempt)
local function buildPanel()
	if panel then return panel end
	local rng = pg:WaitForChild("RNGGui", 20)
	local panels = rng and rng:WaitForChild("Panels", 10)
	local proto = panels and panels:WaitForChild("Settings", 10)
	if proto then
		panel = proto:Clone()
		panel.Name = "Travel"; panel.Visible = false
		local title = panel:FindFirstChild("Title", true)
		if title then title.Text = "TRAVEL" end
		local banner = panel:FindFirstChild("Banner")
		local icon = banner and banner:FindFirstChild("Icon")
		if icon then icon.Visible = false end
		if banner then
			Art.Icon(banner, "teleport", UDim2.fromScale(0.035, 0.05), UDim2.fromScale(0.15, 0.9), "FeatureTravelIcon")
		end
		content = panel:FindFirstChild("Content", true)
		for _, c in ipairs(content:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local close = panel:FindFirstChild("Close")
		if close then close.Activated:Connect(function() panel.Visible = false end) end
		panel.Parent = panels
	else -- fallback (no Settings panel): plain frame
		local sg = mk("ScreenGui", {Name = "TravelMenu", ResetOnSpawn = false}, pg)
		panel = mk("Frame", {Name = "Travel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.7), BackgroundColor3 = Color3.fromRGB(60, 120, 210), Visible = false}, sg)
		mk("UICorner", {CornerRadius = UDim.new(0.04, 0)}, panel)
		Art.Skin(panel)
		content = mk("ScrollingFrame", {Size = UDim2.fromScale(0.94, 0.86), Position = UDim2.fromScale(0.03, 0.1), BackgroundTransparency = 1}, panel)
		mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, content)
		local x = mk("TextButton", {Text = "X", Size = UDim2.fromScale(0.08, 0.08), Position = UDim2.fromScale(0.91, 0.01), Font = FONT, TextScaled = true}, panel)
		x.Activated:Connect(function() panel.Visible = false end)
	end
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	toast = label(panel, "", {Name = "TravelToast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.fromScale(0.8, 0.05), TextColor3 = Color3.fromRGB(255, 230, 150), ZIndex = 5})
	local order = 0
	local lastWorld
	for _, dest in ipairs(T.List) do
		if dest.World ~= lastWorld then
			lastWorld = dest.World
			order += 1
			local head = mk("Frame", {Name = "World" .. dest.World, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = order}, content)
			label(head, T.WorldNames[dest.World] or ("WORLD " .. dest.World), {Size = UDim2.fromScale(1, 0.8), Position = UDim2.fromScale(0, 0.1), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(190, 230, 255)})
		end
		order += 1
		local row = mk("Frame", {Name = dest.Id, Size = UDim2.new(1, 0, 0, touch and 78 or 68), LayoutOrder = order, BackgroundColor3 = Color3.fromRGB(34, 66, 128)}, content)
		row:SetAttribute("SnowUIDecor", true)
		mk("UICorner", {CornerRadius = UDim.new(0.22, 0)}, row)
		stroke(row, 2.5)
		Art.Skin(row)
		local name = label(row, (T.Icons[dest.Id] or "") .. "  " .. dest.Name, {Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.03, 0.08), TextXAlignment = Enum.TextXAlignment.Left})
		local info = label(row, "", {Size = UDim2.fromScale(0.62, 0.32), Position = UDim2.fromScale(0.03, 0.6), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(205, 225, 250)})
		local go = mk("TextButton", {Name = "Go", Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.26, 0.74),
			BackgroundColor3 = Color3.fromRGB(70, 200, 105), AutoButtonColor = true, Selectable = true}, row)
		go:SetAttribute("SnowUIDecor", true)
		mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, go)
		stroke(go, 3)
		Art.Skin(go)
		local goText = label(go, "GO", {Size = UDim2.fromScale(0.84, 0.7), Position = UDim2.fromScale(0.08, 0.15)})
		rows[dest.Id] = {row = row, name = name, info = info, go = go, goText = goText, dest = dest}
		go.Activated:Connect(function()
			if not T.Unlocked(player, dest) or current == dest.Id then return end
			local confirm = pendingConfirm and pendingConfirm.id == dest.Id and os.clock() < pendingConfirm.untilT
			goText.Text = "..."
			local ok, res = pcall(function() return remote:InvokeServer("Travel", dest.Id, confirm) end)
			if ok and type(res) == "table" and res.needConfirm then
				pendingConfirm = {id = dest.Id, untilT = os.clock() + 8}
				toast.Text = res.msg
				goText.Text = "SURE?"
				return
			end
			pendingConfirm = nil
			if ok and type(res) == "table" and res.ok then
				current = res.at or dest.Id
				toast.Text = res.msg or ""
				panel.Visible = false
			else
				toast.Text = (ok and type(res) == "table" and res.msg) or "Travel failed - try again."
			end
			refresh()
		end)
	end
	return panel
end

function refresh()
	if not panel then return end
	for id, r in pairs(rows) do
		local open = T.Unlocked(player, r.dest)
		local here = current == id
		r.row.BackgroundColor3 = here and Color3.fromRGB(40, 110, 80) or (open and Color3.fromRGB(34, 66, 128) or Color3.fromRGB(70, 78, 98))
		r.info.Text = here and "YOU ARE HERE" or (open and (id == "Garage" and "Roll, buy and equip parts" or "Free travel") or ("\u{1F512} " .. T.Requirement(r.dest)))
		r.go.Visible = open and not here
		r.go.Selectable = r.go.Visible
		if not (pendingConfirm and pendingConfirm.id == id) then r.goText.Text = "GO" end
	end
end

local function open()
	if not hudVisible() and player:GetAttribute("PlowTutorialDone") ~= true then return end
	buildPanel()
	if player:GetAttribute("InArenaIsland") then return end
	local ok, res = pcall(function() return remote:InvokeServer("Where") end)
	current = ok and type(res) == "table" and res.at or nil
	pendingConfirm = nil
	toast.Text = ""
	refresh()
	if panel.Parent and panel.Parent.Name == "Panels" then for _, p in ipairs(panel.Parent:GetChildren()) do if p:IsA("GuiObject") and p ~= panel then p.Visible = false end end end
	panel.Visible = true
	if UIS.GamepadEnabled and UIS:GetLastInputType().Name:find("^Gamepad") then
		for _, dest in ipairs(T.List) do local r = rows[dest.Id]; if r and r.go.Visible then GuiService.SelectedObject = r.go break end end
	end
end
btn.Activated:Connect(function() if panel and panel.Visible then panel.Visible = false else open() end end)
PPS.PromptTriggered:Connect(function(prompt) if prompt.Name == "TravelPadPrompt" then open() end end)
-- locks refresh at once after a stage purchase or a rebirth
for _, dest in ipairs(T.List) do
	if dest.Kind == "Stage" then player:GetAttributeChangedSignal("Stage_" .. dest.Stage):Connect(function() if panel and panel.Visible then refresh() end end) end
end
player:GetAttributeChangedSignal("InGarage"):Connect(function() if panel and panel.Visible then current = player:GetAttribute("InGarage") and "Garage" or current; refresh() end end)
player:GetAttributeChangedSignal("InArenaIsland"):Connect(function() if player:GetAttribute("InArenaIsland") and panel then panel.Visible = false end end)
