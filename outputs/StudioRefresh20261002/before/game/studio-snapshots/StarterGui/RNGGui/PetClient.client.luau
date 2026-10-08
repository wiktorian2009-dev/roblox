-- READ-ONLY SNAPSHOT: captured from Studio Play/Server, 2026-09-30. Not Rojo-mapped.
-- Live source: StarterGui.RNGGui.PetClient. Verify Edit source before changes.
-- PetClient: PETS tab in the inventory + egg hatch animation.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local PetModels = require(ReplicatedStorage:WaitForChild("PetModels"))
local EggModels = require(ReplicatedStorage:WaitForChild("EggModels"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local hatchedEvent = ReplicatedStorage:WaitForChild("PetHatched")
local equipRemote = ReplicatedStorage:WaitForChild("EquipPet")
local getPets = ReplicatedStorage:WaitForChild("GetPets")

local gui = script.Parent
local panel = gui:WaitForChild("Panels"):WaitForChild("Inventory")
local inner = panel:WaitForChild("Inner")
local shovelContent = inner:WaitForChild("Content")
local petContent = inner:WaitForChild("PetContent")
local tabBar = inner:WaitForChild("TabBar")
local title = panel:WaitForChild("Banner"):WaitForChild("Title")

local FONT = Enum.Font.FredokaOne
local OUTLINE = Color3.fromRGB(25, 45, 90)
local WHITE = Color3.new(1, 1, 1)
local MAX = PetConfig.MaxEquipped

local pets, equipped, discovered = {}, {}, {}
local updateSigns = function() end
local tab = "Shovels"
local refresh

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
local function round(p, s) mk("UICorner", {CornerRadius = UDim.new(s, 0)}, p) end
local function label(parent, t, props, st)
	local l = mk("TextLabel", {Font = FONT, TextScaled = true, TextColor3 = WHITE, BackgroundTransparency = 1, Text = t}, nil)
	for k, v in pairs(props) do l[k] = v end
	if st ~= false then mk("UIStroke", {Thickness = st or 2.5, Color = OUTLINE}, l) end
	l.Parent = parent
	return l
end

-- 3D pet preview inside a frame
local function viewport(parent, petName, props)
	local vp = mk("ViewportFrame", {BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 210),
		LightColor = WHITE, LightDirection = Vector3.new(-0.4, -1, -0.6)}, nil)
	for k, v in pairs(props) do vp[k] = v end
	local m = PetModels.create(petName)
	m:PivotTo(CFrame.new())
	m.Parent = vp
	local _, size = m:GetBoundingBox()
	local dist = math.max(size.X, size.Y) * 1.7 + 1.5
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(dist * 0.45, dist * 0.25, -dist), Vector3.new(0, 0, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
	return vp, m
end

--------------------------------------------------
-- TABS
--------------------------------------------------
local function setTab(t)
	tab = t
	panel:SetAttribute("Tab", t)
	shovelContent.Visible = t == "Shovels"
	petContent.Visible = t == "Pets"
	for _, b in ipairs(tabBar:GetChildren()) do
		if b:IsA("TextButton") then
			b.BackgroundColor3 = (b.Name == t .. "Tab") and Color3.fromRGB(60, 150, 255) or Color3.fromRGB(150, 165, 190)
		end
	end
	if t == "Pets" then refresh() else
		-- let RNGClient's title come back
		local n = 0
		for _ in (Players.LocalPlayer:GetAttribute("EquippedShovels") or ""):gmatch("[^,]+") do n += 1 end
		title.Text = ("INVENTORY %d/%d"):format(n, Players.LocalPlayer:GetAttribute("ShovelSlots") or 2)
	end
end
tabBar:WaitForChild("ShovelsTab").Activated:Connect(function() setTab("Shovels") end)
tabBar:WaitForChild("PetsTab").Activated:Connect(function() setTab("Pets") end)
gui:WaitForChild("VillageOpenMenu").Event:Connect(function(name)
 if name == "Pets" then setTab("Pets") end
end)

--------------------------------------------------
-- PET CARDS
--------------------------------------------------
local function copies(name)
	local n = 0
	for _, e in ipairs(equipped) do if e == name then n += 1 end end
	return n
end

local busy = false
local function send(action, name)
	if busy then return end
	busy = true
	local ok, res = pcall(function() return equipRemote:InvokeServer(action, name) end)
	busy = false
	if ok and type(res) == "table" then equipped = res; refresh() end
end

local function smallButton(parent, props, color, text)
	local b = mk("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = color}, parent)
	for k, v in pairs(props) do b[k] = v end
	round(b, 1)
	mk("UIStroke", {Thickness = 3, Color = OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
	label(b, text, {Position = UDim2.fromScale(0.08, 0.14), Size = UDim2.fromScale(0.84, 0.72)}, 2)
	return b
end

local function card(order, pet, count)
	local color = PetConfig.Rarities[pet.Rarity] or WHITE
	local holder = mk("Frame", {BackgroundTransparency = 1, LayoutOrder = order}, nil)
	local shadow = mk("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.78, Position = UDim2.new(0, 0, 0, 6), Size = UDim2.fromScale(1, 1)}, holder)
	round(shadow, 0.16)
	local main = mk("Frame", {BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1)}, holder)
	round(main, 0.16)
	mk("UIGradient", {Color = ColorSequence.new(color:Lerp(WHITE, 0.55), color), Rotation = 90}, main)
	local stroke = mk("UIStroke", {Thickness = 4, Color = color:Lerp(Color3.new(0, 0, 0), 0.45), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, main)
	viewport(main, pet.Name, {Position = UDim2.fromScale(0.05, 0.02), Size = UDim2.fromScale(0.9, 0.44)})
	label(main, pet.Name, {Position = UDim2.fromScale(0.05, 0.46), Size = UDim2.fromScale(0.9, 0.14)}, 2.5)
	label(main, "+" .. math.floor(pet.Boost * 100 + 0.5) .. "% ❄", {Position = UDim2.fromScale(0.15, 0.6), Size = UDim2.fromScale(0.7, 0.11),
		TextColor3 = Color3.fromRGB(150, 255, 150)}, 2.5)

	local on = copies(pet.Name)
	local canAdd = on < count
	local eb = smallButton(main, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.75), Size = UDim2.fromScale(0.86, 0.17)},
		canAdd and Color3.fromRGB(60, 150, 255) or Color3.fromRGB(70, 200, 90), canAdd and "EQUIP" or "EQUIPPED")
	eb.Activated:Connect(function() if canAdd then send("equip", pet.Name) end end)
	if on > 0 then
		stroke.Color = Color3.fromRGB(60, 230, 90)
		stroke.Thickness = 6
		local x = smallButton(holder, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.12, 0.07), Size = UDim2.fromScale(0.26, 0.26)},
			Color3.fromRGB(235, 70, 80), "X")
		mk("UIAspectRatioConstraint", {AspectRatio = 1}, x)
		x.Activated:Connect(function() send("unequip", pet.Name) end)
	end
	local badge = mk("Frame", {BackgroundColor3 = Color3.fromRGB(255, 215, 60), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.86, 0.07), Size = UDim2.fromScale(0.38, 0.17)}, holder)
	round(badge, 1)
	mk("UIStroke", {Thickness = 3, Color = OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, badge)
	label(badge, "x" .. count, {Position = UDim2.fromScale(0.12, 0.12), Size = UDim2.fromScale(0.76, 0.76), TextColor3 = OUTLINE}, false)
	holder.Parent = petContent
end

refresh = function()
	for _, c in ipairs(petContent:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local order, any = 0, false
	for _, egg in ipairs(PetConfig.Eggs) do
		for _, pet in ipairs(egg.Pets) do
			order += 1
			local n = pets[pet.Name] or 0
			if n > 0 then any = true; card(order, pet, n) end
		end
	end
	if not any then
		label(petContent, "Open an egg to get your first pet! 🥚", {Size = UDim2.new(1, 0, 0, 50)}, 3)
	end
	if tab == "Pets" then
		title.Text = ("PETS %d/%d"):format(#equipped, Players.LocalPlayer:GetAttribute("PetSlots") or MAX)
	end
end

--------------------------------------------------
-- HATCH ANIMATION
--------------------------------------------------
local overlay = mk("Frame", {Name = "HatchOverlay", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, -80), Size = UDim2.new(1, 0, 1, 80), Visible = false, ZIndex = 20}, gui)
local stage = mk("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47),
	Size = UDim2.fromScale(0.5, 0.6), ZIndex = 21}, overlay)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, stage)
local flash = mk("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 25}, overlay)
local topText = label(overlay, "", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.6, 0.07), ZIndex = 22}, 3)
local nameText = label(overlay, "", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.74), Size = UDim2.fromScale(0.6, 0.09), ZIndex = 22}, 4)
local subText = label(overlay, "", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.84), Size = UDim2.fromScale(0.5, 0.05), ZIndex = 22}, 3)

local blur = Instance.new("BlurEffect")
blur.Name = "HatchBlur"
blur.Size = 0
blur.Parent = workspace.CurrentCamera

-- New 2026 egg art: clone the Shell mesh from the lobby EggDisplay; old procedural eggs are the fallback.
local function eggArt(eggId)
	local display = workspace:FindFirstChild("EggDisplay", true)
	local src = display and display:FindFirstChild(eggId)
	local shell = src and src:FindFirstChild("Shell")
	if shell and shell:IsA("MeshPart") then
		local m = Instance.new("Model")
		m.Name = eggId
		local c = shell:Clone()
		c.Anchored = true
		c.PivotOffset = CFrame.new() -- imported meshes carry a 90-degree pivot; keep the egg upright
		c.CFrame = CFrame.new()
		c.Parent = m
		m.PrimaryPart = c
		return m
	end
	return EggModels.create(eggId)
end

local playing = false
local function playHatch(eggId, petName, isNew)
	playing = true
	for _, c in ipairs(stage:GetChildren()) do if c:IsA("ViewportFrame") then c:Destroy() end end
	topText.Text, nameText.Text, subText.Text = "", "", ""
	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	tween(overlay, 0.25, {BackgroundTransparency = 0.45})
	tween(blur, 0.25, {Size = 18})

	-- the egg: a clone of the real egg model if possible
	local eggVp = mk("ViewportFrame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 21,
		Ambient = Color3.fromRGB(200, 200, 210), LightColor = WHITE, LightDirection = Vector3.new(-0.4, -1, -0.6)}, stage)
	local eggModel = eggArt(eggId)
	eggModel:PivotTo(CFrame.new())
	eggModel.Parent = eggVp
	local _, size = eggModel:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * 0.15, -math.max(size.X, size.Y) * 2.2), Vector3.new(0, 0, 0))
	cam.Parent = eggVp
	eggVp.CurrentCamera = cam
	topText.Text = "Hatching..."

	-- shake harder and harder
	local t0 = os.clock()
	while os.clock() - t0 < 1.6 do
		local k = (os.clock() - t0) / 1.6
		eggModel:PivotTo(CFrame.Angles(0, 0, math.sin(os.clock() * (18 + k * 30)) * (0.08 + k * 0.28)))
		task.wait()
	end

	-- pop!
	flash.BackgroundTransparency = 0
	tween(flash, 0.5, {BackgroundTransparency = 1})
	eggVp:Destroy()
	local pet = PetConfig.PetByName[petName]
	local color = pet and PetConfig.Rarities[pet.Rarity] or WHITE
	local vp, model = viewport(stage, petName, {Size = UDim2.fromScale(1, 1), ZIndex = 21})
	local popScale = mk("UIScale", {Scale = 0.3}, stage)
	tween(popScale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
	topText.Text = isNew and "NEW PET!" or "You hatched"
	topText.TextColor3 = isNew and Color3.fromRGB(255, 230, 90) or WHITE
	nameText.Text = petName
	nameText.TextColor3 = color
	subText.Text = (pet and pet.Rarity or "") .. "  •  +" .. math.floor((pet and pet.Boost or 0) * 100 + 0.5) .. "% ❄"
	subText.TextColor3 = WHITE

	local t1 = os.clock()
	while os.clock() - t1 < 2.4 do
		model:PivotTo(CFrame.Angles(0, (os.clock() - t1) * 1.5, 0))
		task.wait()
	end
	tween(overlay, 0.3, {BackgroundTransparency = 1})
	tween(blur, 0.3, {Size = 0})
	task.wait(0.3)
	popScale:Destroy()
	vp:Destroy()
	overlay.Visible = false
	topText.Text, nameText.Text, subText.Text = "", "", ""
	playing = false
end

-- "not enough snow" toast
local toast = label(gui, "", {Name = "Toast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromScale(0.5, 0.06), TextColor3 = Color3.fromRGB(255, 110, 110), TextTransparency = 1, ZIndex = 30}, 3)
local toastStroke = toast:FindFirstChildOfClass("UIStroke")
local function showToast(text)
	toast.Text = text
	toast.TextTransparency = 0
	toastStroke.Transparency = 0
	tween(toast, 0.6, {TextTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Delay = 0
	task.delay(1.2, function()
		tween(toast, 0.5, {TextTransparency = 1})
		tween(toastStroke, 0.5, {Transparency = 1})
	end)
end

hatchedEvent.OnClientEvent:Connect(function(kind, eggId, a, b, c, d, e)
	if kind == "NotEnough" then
		toast.TextTransparency = 0
		showToast("You need " .. NumberFormat.Abbreviate(a) .. " ❄ to open this egg!")
	elseif kind == "Hatched" then
		pets = c or pets
		equipped = d or equipped
		discovered = e or discovered
		if not playing then task.spawn(playHatch, eggId, a, b) end
		task.delay(4.6, function() updateSigns(a) end) -- light up after the reveal
		refresh()
	end
end)

-- when the server changes equipped pets (e.g. auto-equip), keep the tab in sync
Players.LocalPlayer:GetAttributeChangedSignal("EquippedPets"):Connect(function()
	local list = {}
	for n in (Players.LocalPlayer:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(list, n) end
	equipped = list
	if tab == "Pets" then refresh() end
end)

-- initial load
task.spawn(function()
	for _ = 1, 20 do
		local ok, res = pcall(function() return getPets:InvokeServer() end)
		if ok and type(res) == "table" then
			pets = res.Pets or {}
			equipped = res.Equipped or {}
			discovered = res.Index or {}
			updateSigns()
			break
		end
		task.wait(0.5)
	end
	refresh()
end)

--------------------------------------------------
-- EGG SIGNS: mini pets, black until discovered
--------------------------------------------------
local signs = {} -- [eggId] = {slots = {[petName] = {vp, scale}}}

-- black silhouette until discovered; `justFound` lights up with a pop
updateSigns = function(justFound)
	for _, entry in pairs(signs) do
		for name, slot in pairs(entry.slots) do
			local known = discovered[name] == true
			if known and name == justFound then
				slot.vp.ImageColor3 = Color3.new(0, 0, 0)
				tween(slot.vp, 0.6, {ImageColor3 = WHITE})
				slot.scale.Scale = 1.35
				tween(slot.scale, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
			else
				slot.vp.ImageColor3 = known and WHITE or Color3.new(0, 0, 0)
			end
		end
	end
end

local function makeSign(prompt)
	local part = prompt.Parent
	if not part then return end
	local model = part:FindFirstAncestorOfClass("Model")
	while model and not PetConfig.EggById[model.Name] do model = model:FindFirstAncestorOfClass("Model") end
	if not model then return end
	local egg = PetConfig.EggById[model.Name]
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	if pg:FindFirstChild("PetSign_" .. egg.Id) then return end
	local _, size = model:GetBoundingBox()

	local bb = Instance.new("BillboardGui")
	bb.Name = "PetSign_" .. egg.Id
	bb.Adornee = part
	bb.Size = UDim2.fromOffset(270, 205)
	bb.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 4.8, 0)
	-- lobby row eggs (Shell on a pedestal): sit the panel just above the egg itself
	local shellPart = model:FindFirstChild("Shell")
	if shellPart and shellPart:IsA("BasePart") then
		local eggTop = shellPart.Position.Y + shellPart.Size.Y / 2 - part.Position.Y
		bb.StudsOffsetWorldSpace = Vector3.new(0, eggTop + 1.3, 0)
		bb.SizeOffset = Vector2.new(0, 0.5)
	end
	bb.MaxDistance = 1000
	bb.Enabled = false -- shown by the proximity loop below
	bb.LightInfluence = 0
	bb.ResetOnSpawn = false

	local frame = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 30, 55), BackgroundTransparency = 1}, bb)
	mk("UICorner", {CornerRadius = UDim.new(0, 16)}, frame)
	-- Transparent outer panel; preserve pet tiles, text, odds and layout.
	label(frame, egg.Name:upper() .. "  •  " .. NumberFormat.Abbreviate(egg.Cost) .. " ❄", {Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 26)}, 2)

	local grid = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 38), Size = UDim2.new(1, -16, 1, -44)}, frame)
	mk("UIGridLayout", {CellSize = UDim2.fromOffset(76, 78), CellPadding = UDim2.fromOffset(8, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, grid)

	local entry = {slots = {}, bb = bb, part = part, shown = false, scale = mk("UIScale", {Scale = 0}, frame)}
	for i, pet in ipairs(egg.Pets) do
		local color = PetConfig.Rarities[pet.Rarity] or WHITE
		local cell = mk("Frame", {BackgroundTransparency = 1, LayoutOrder = i}, grid)
		local tile = mk("Frame", {BackgroundColor3 = color, Size = UDim2.new(1, 0, 0, 58)}, cell)
		mk("UICorner", {CornerRadius = UDim.new(0, 12)}, tile)
		mk("UIGradient", {Color = ColorSequence.new(color:Lerp(WHITE, 0.5), color), Rotation = 90}, tile)
		mk("UIStroke", {Thickness = 2.5, Color = OUTLINE}, tile)
		local scale = mk("UIScale", {Scale = 1}, tile)
		local vp = viewport(tile, pet.Name, {Size = UDim2.fromScale(1, 1)})
		label(cell, pet.Chance .. "%", {Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 0, 20)}, 2)
		entry.slots[pet.Name] = {vp = vp, scale = scale}
	end
	signs[egg.Id] = entry
	bb.Parent = pg
	updateSigns()
end

local function watch(d)
	if d:IsA("ProximityPrompt") and d.Name == "HatchPrompt" then task.defer(makeSign, d) end
end
for _, d in ipairs(workspace:GetDescendants()) do watch(d) end
workspace.DescendantAdded:Connect(watch)

-- egg signs only show when you're close; they pop in and shrink away
local SHOW_DISTANCE = 25
local HIDE_DISTANCE = 30
task.spawn(function()
	while true do
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		-- eggs stand close together in the lobby row: only the nearest egg's sign may show
		local nearest, nearestDist = nil, math.huge
		for _, entry in pairs(signs) do
			if entry.bb and entry.part and entry.part.Parent and hrp then
				local d = (hrp.Position - entry.part.Position).Magnitude
				if d < nearestDist then nearest, nearestDist = entry, d end
			end
		end
		for _, entry in pairs(signs) do
			if entry.bb and entry.part and entry.part.Parent then
				local dist = hrp and (hrp.Position - entry.part.Position).Magnitude or math.huge
				if entry ~= nearest then dist = math.huge end
				if not entry.shown and dist < SHOW_DISTANCE then
					entry.shown = true
					entry.bb.Enabled = true
					entry.scale.Scale = 0
					tween(entry.scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
				elseif entry.shown and dist > HIDE_DISTANCE then
					entry.shown = false
					local tw = tween(entry.scale, 0.2, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					tw.Completed:Connect(function()
						if not entry.shown then entry.bb.Enabled = false end
					end)
				end
			end
		end
		task.wait(0.15)
	end
end)

-- admin commands changed our pets: reload
ReplicatedStorage:WaitForChild("DataRefresh").OnClientEvent:Connect(function()
	local ok, res = pcall(function() return getPets:InvokeServer() end)
	if ok and type(res) == "table" then
		pets = res.Pets or {}
		equipped = res.Equipped or {}
		discovered = res.Index or {}
		refresh()
		updateSigns()
	end
end)
