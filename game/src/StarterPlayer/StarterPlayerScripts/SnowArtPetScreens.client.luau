-- SnowArtPetScreens (2026-10-06, Claude): SnowArt image art for the script-built buttons of the pet screens, applied at runtime
-- (the Studio-only PetClient / MachinesClient that build them are not edited; this only re-skins what they create):
--   * Inventory (pets): EQUIP (blue) / EQUIPPED (green) pills -> SnowArt buttons; the red "X" unequip badge -> the round close art.
--   * Pet Fuser (Golden), Crafting Machine, Hot Cocoa: row buttons -> green art when ready (FUSE! / CRAFT! / BUY), grey otherwise,
--     following the label text the machine script sets.
--   * The X close buttons of those panels (and the SHOP) -> the round SnowArt close.
--   * Touch-only devices (UIAudit F41, 2026-10-08): the EQUIP / EQUIPPED pill and the unequip X get a minimum size; on short cards the
--     preview / name / boost rows are lifted so the larger pill never covers the +x% text (see skinPetButton / fitCard).
-- The upgrade screen is not touched.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Art = require(RS:WaitForChild("SnowArt"))
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

local READY = {["FUSE!"] = true, ["CRAFT!"] = true, ["BUY"] = true}
local function labelOf(b)
	for _, c in ipairs(b:GetChildren()) do if c:IsA("TextLabel") then return c end end
end

-- inventory pet cards
-- UIAudit F41: PetClient sizes EQUIP at 0.86 x 0.17 and the unequip X at 0.26 x 0.26 (+aspect 1) of the card, so on a phone they shrink to
-- slivers. On touch-only devices give them a floor (40 px, the dense touch target) with a UISizeConstraint; layout only, handlers untouched.
local TOUCH_MIN = 40 -- dense touch target, px
local PILL_BOTTOM, TEXT_GAP = 0.96, 4 -- floored EQUIP pill: bottom edge (card scale) and px kept clear between its top and the text above
local function touchOnly() return UIS.TouchEnabled and not UIS.KeyboardEnabled end
local function minSize(b, w, h)
	if b:FindFirstChild("TouchMinSize") then return end
	local c = Instance.new("UISizeConstraint")
	c.Name, c.MinSize = "TouchMinSize", Vector2.new(w, h)
	c.Parent = b
end
-- PetClient stacks the card as preview (y 0.02-0.46), name (0.46-0.60), "+x% boost" (0.60-0.71), then the pill (0.75-0.92). Once the pill is
-- floored to 40 px (card under ~235 px high) it no longer fits there, so it is bottom-anchored (grows upward) and the rows above are lifted -
-- preview shrinks, name / boost move up - until they end TEXT_GAP above its top: the +x% stat is never covered. Everything is recomputed from the
-- original geometry on each card resize (a taller card gets the PetClient layout back). The connection sits on the card, which PetClient
-- destroys on every refresh, so it never outlives it.
local function fitCard(main, pill)
	local rows, preview = {}, nil
	for _, r in ipairs(main:GetChildren()) do
		if r ~= pill and (r:IsA("ViewportFrame") or r:IsA("TextLabel")) and r.Position.Y.Offset == 0 and r.Size.Y.Offset == 0 then
			local o = {r = r, y = r.Position.Y.Scale, h = r.Size.Y.Scale}
			if r:IsA("ViewportFrame") then preview = o end
			rows[#rows + 1] = o
		end
	end
	local textTop = preview and (preview.y + preview.h - 0.001) or 0 -- text rows = labels stacked under the preview
	local anchor, pos = pill.AnchorPoint, pill.Position
	local function apply()
		local H = main.AbsoluteSize.Y
		if H <= 0 or not pill.Parent then return end
		local floored = pill.Size.Y.Scale * H + pill.Size.Y.Offset < TOUCH_MIN
		local lift = 0
		if floored then
			pill.AnchorPoint = Vector2.new(anchor.X, 1)
			pill.Position = UDim2.new(pos.X.Scale, pos.X.Offset, PILL_BOTTOM, 0)
			local limit = PILL_BOTTOM - (TOUCH_MIN + TEXT_GAP) / H -- lowest card-scale y the text may reach
			for _, o in ipairs(rows) do
				if o ~= preview and o.y >= textTop then lift = math.max(lift, o.y + o.h - limit) end
			end
		else
			pill.AnchorPoint, pill.Position = anchor, pos
		end
		for _, o in ipairs(rows) do
			local r = o.r
			if o == preview then
				r.Size = UDim2.new(r.Size.X.Scale, r.Size.X.Offset, math.max(o.h - lift, math.min(o.h, 0.15)), 0)
			elseif o.y >= textTop then
				r.Position = UDim2.new(r.Position.X.Scale, r.Position.X.Offset, o.y - lift, 0)
			end
		end
	end
	apply()
	main:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply)
end
local function skinPetButton(b)
	if not b:IsA("TextButton") or b:GetAttribute("SnowArtSkinned") then return end
	local l = labelOf(b)
	if not l then return end
	if l.Text == "EQUIP" or l.Text == "EQUIPPED" then
		Art.SkinButton(b) -- colour follows BackgroundColor3 (blue / green)
		if touchOnly() then
			minSize(b, 0, TOUCH_MIN)
			if b.Parent and b.Parent:IsA("GuiObject") then fitCard(b.Parent, b) end
		end
	elseif l.Text == "X" then
		Art.SkinClose(b)
		if touchOnly() then minSize(b, TOUCH_MIN, TOUCH_MIN) end
	end
end
-- machine rows: state from the label text
local function skinMachineButton(b)
	if not b:IsA("TextButton") or b:GetAttribute("SnowArtSkinned") or not b:FindFirstChildOfClass("UIGradient") then return end
	local l = labelOf(b)
	if not l then return end
	local art = Art.SkinButton(b, "grey")
	if not art then return end
	local function upd() art.Image = READY[l.Text] and Art.Images.btn_green or Art.Images.btn_grey end
	upd()
	l:GetPropertyChangedSignal("Text"):Connect(upd)
end

-- EQUIP BEST (2026-10-06): top band of the inventory (where PetClient's hidden tab bar sits). The server picks the strongest pets
-- (PetService "best", rate-limited); PetClient refreshes from the EquippedPets attribute.
local TweenService = game:GetService("TweenService")
local equipRemote = RS:WaitForChild("EquipPet")
local FONT, NAVY = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85)
local function addEquipBest(inv)
	local inner = inv:FindFirstChild("Inner")
	if not inner or inner:FindFirstChild("EquipBest") then return end
	local b = Instance.new("TextButton")
	b.Name, b.Text, b.AutoButtonColor, b.Selectable = "EquipBest", "", true, true
	b.BackgroundColor3 = Color3.fromRGB(70, 200, 105)
	b.AnchorPoint, b.Position, b.Size, b.ZIndex = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.012), UDim2.fromScale(0.34, 0.105), 5
	local l = Instance.new("TextLabel")
	l.Name, l.BackgroundTransparency, l.Font, l.TextScaled, l.Text, l.TextColor3, l.ZIndex = "Label", 1, FONT, true, "EQUIP BEST", Color3.new(1, 1, 1), 6
	l.Position, l.Size = UDim2.fromScale(0.07, 0.17), UDim2.fromScale(0.86, 0.66)
	local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = NAVY; st.Parent = l
	l.Parent = b
	b.Parent = inner
	Art.SkinButton(b, "green")
	Art.IconButton(b, "star")
	local toast = Instance.new("TextLabel")
	toast.Name, toast.BackgroundTransparency, toast.Font, toast.TextScaled, toast.Text, toast.ZIndex = "EquipBestToast", 1, FONT, true, "", 7
	toast.AnchorPoint, toast.Position, toast.Size = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.125), UDim2.fromScale(0.5, 0.06)
	toast.TextTransparency = 1
	local tst = Instance.new("UIStroke"); tst.Thickness = 2; tst.Color = NAVY; tst.Transparency = 1; tst.Parent = toast
	toast.Parent = inner
	local function show(text, color)
		toast.Text, toast.TextColor3 = text, color
		toast.TextTransparency, tst.Transparency = 0, 0
		task.delay(1.4, function()
			if toast.Text ~= text then return end
			TweenService:Create(toast, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			TweenService:Create(tst, TweenInfo.new(0.5), {Transparency = 1}):Play()
		end)
	end
	local busy = false
	b.Activated:Connect(function()
		if busy then return end
		busy = true
		local ok, _, status = pcall(function() return equipRemote:InvokeServer("best") end)
		busy = false
		if not ok then return end
		if status == "ok" then show("Equipped your best pets!", Color3.fromRGB(150, 255, 170))
		elseif status == "same" then show("Already your best!", Color3.fromRGB(255, 232, 140))
		elseif status == "none" then show("Hatch some pets first!", Color3.fromRGB(255, 200, 200)) end
	end)
end

local function watch(root, fn)
	for _, d in ipairs(root:GetDescendants()) do task.defer(fn, d) end
	root.DescendantAdded:Connect(function(d) task.defer(fn, d) end) -- deferred: the label is added right after the button
end

local function attach(rng)
	local panels = rng:WaitForChild("Panels", 30)
	if not panels then return end
	for _, name in ipairs({"Inventory", "Fuser", "Craft", "Cocoa", "Shop"}) do
		local p = panels:FindFirstChild(name)
		local close = p and p:FindFirstChild("Close")
		if close then Art.SkinClose(close) end
	end
	local inv = panels:FindFirstChild("Inventory")
	if inv then addEquipBest(inv) end
	local content = inv and inv:FindFirstChild("Inner") and inv.Inner:WaitForChild("PetContent", 30)
	if content then watch(content, skinPetButton) end
	for _, name in ipairs({"Fuser", "Craft", "Cocoa"}) do
		local p = panels:FindFirstChild(name)
		local inner = p and p:FindFirstChild("Inner")
		if inner then
			watch(inner, function(d)
				if d:IsA("TextButton") and d:FindFirstAncestor("MachinePage") then skinMachineButton(d) end
			end)
		end
	end
end
task.spawn(function()
	local rng = pg:WaitForChild("RNGGui", 60)
	if rng then attach(rng) end
end)
pg.ChildAdded:Connect(function(c) if c.Name == "RNGGui" then task.spawn(attach, c) end end)
