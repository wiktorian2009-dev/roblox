-- VerityEggClient (2026-10-06, Claude): the Verity Egg in the SHOP panel (RNGGui.Panels.Shop) + its egg screen (DETAILS).
-- * Built at runtime inside Shop.Inner (the panel's "opening soon" placeholder is hidden while the egg shows; the Studio panel itself
--   is not edited). SnowArt look: deep-blue snowy window, cartoon BUY / DETAILS buttons, round close.
-- * Paid random item rules: every outcome and its odds (%) are on the card itself, before any purchase, read from PetConfig - the
--   table ProductService rolls from (sum 100). DETAILS opens the egg screen with all five pets, rarity, odds and current boost.
-- * Price: the real price from GetProductInfoAsync once the product exists; the struck-through "was" price and the -% tag come
--   from PassConfig (ShowSale) and only show when the real price equals the configured Price. Only that price is ever charged.
-- * Hidden for players whose PaidRandomRestricted attribute isn't false (PolicyService, server-set). BUY asks the server to prompt
--   (ProductRemote "Prompt"); the server refuses when sales are off, there's no id, or the player is restricted. The pet is rolled and
--   granted only by ProductService.ProcessReceipt; PetClient plays the usual hatch reveal.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local P = require(RS:WaitForChild("PassConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local PetModels = require(RS:WaitForChild("PetModels"))
local EggModels = require(RS:WaitForChild("EggModels"))
local Art = require(RS:WaitForChild("SnowArt"))
local UILayout = require(RS:WaitForChild("UILayout"))
local remote = RS:WaitForChild("ProductRemote", 60)
local pg = player:WaitForChild("PlayerGui")
local PRODUCT = P.Products.VerityEgg
local EGG = PetConfig.EggById[PRODUCT.Egg]
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local GOLD, ICE, GREEN, GREY, BLUE = Color3.fromRGB(255, 220, 90), Color3.fromRGB(190, 225, 255), Color3.fromRGB(70, 200, 105), Color3.fromRGB(130, 140, 165), Color3.fromRGB(70, 150, 245)
local ROBUX = "\u{E002}"
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled -- same test as the other client scripts

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function label(parent, text, props)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE, ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	mk("UIStroke", {Thickness = 2, Color = NAVY}, l)
	return l
end
local function button(parent, text, color, props)
	local b = mk("TextButton", {Text = "", AutoButtonColor = true, BackgroundColor3 = color, Selectable = true, ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, b)
	local l = label(b, text, {Name = "Label", Size = UDim2.fromScale(0.86, 0.66), Position = UDim2.fromScale(0.07, 0.17), ZIndex = 6})
	Art.SkinButton(b)
	return b, l
end
local function hex(c) return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255) end
local function pct(v) return "+" .. math.floor(v * 100 + 0.5) .. "%" end

-- 3D previews (same models as the inventory / hatch reveal)
local spinners = {}
local function view(parent, model, props)
	local vp = mk("ViewportFrame", {BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 215), LightColor = WHITE, LightDirection = Vector3.new(-0.4, -1, -0.6), ZIndex = 5}, parent)
	for k, v in pairs(props or {}) do vp[k] = v end
	local shell = model:FindFirstChild("Shell") -- eggs: pivot on the shell so the egg stands upright (as PetClient's hatch reveal does)
	if shell and shell:IsA("BasePart") then model.PrimaryPart = shell end
	model:PivotTo(CFrame.new())
	model.Parent = vp
	local _, size = model:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 34
	cam.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * 0.12, -math.max(size.X, size.Y, size.Z) * 2.1), Vector3.new())
	cam.Parent = vp
	vp.CurrentCamera = cam
	table.insert(spinners, {vp = vp, model = model})
	return vp
end
local function petView(parent, name, props) return view(parent, PetModels.create(name), props) end

--------------------------------------------------
-- state: price, sales, policy
--------------------------------------------------
local info = {} -- Price / ForSale / Failed
local server = {canBuy = false, why = "soon"}
local function salesOn() return P.ProductSalesEnabled == true and PRODUCT.Id ~= nil end
local function restricted() return player:GetAttribute("PaidRandomRestricted") ~= false end
local function priceRich()
	local price = info.Price or PRODUCT.Price
	local sale = PRODUCT.ShowSale and price == PRODUCT.Price and PRODUCT.WasPrice and PRODUCT.WasPrice > price
	local s = ('<font color="#FFE88A">%s %d</font>'):format(ROBUX, price)
	if sale then s = ('<font color="#B8C4DA"><s>%s %d</s></font>  '):format(ROBUX, PRODUCT.WasPrice) .. s end
	return s, sale
end

--------------------------------------------------
-- egg screen (DETAILS)
--------------------------------------------------
-- DisplayOrder 103: above the RNGGui (100) panels, below the upgrade screen and the tutorial
local sg = mk("ScreenGui", {Name = "VerityEggGui", ResetOnSpawn = false, DisplayOrder = 103, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
local screen = mk("Frame", {Name = "EggScreen", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.62, 0.7),
	BackgroundColor3 = Color3.fromRGB(40, 80, 160), Visible = false, Active = true, ZIndex = 2}, sg) -- Active: clicks on the window's art never reach the menu/card BUY underneath
mk("UICorner", {CornerRadius = UDim.new(0.05, 0)}, screen)
mk("UISizeConstraint", {MinSize = Vector2.new(330, 260), MaxSize = Vector2.new(980, 640)}, screen)
Art.SkinPanel(screen, "dark")
label(screen, "VERITY EGG", {Position = UDim2.fromScale(0.05, 0.05), Size = UDim2.fromScale(0.6, 0.1), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD})
local screenPrice = label(screen, "", {RichText = true, Position = UDim2.fromScale(0.05, 0.15), Size = UDim2.fromScale(0.5, 0.07), TextXAlignment = Enum.TextXAlignment.Left})
local close = mk("TextButton", {Name = "Close", Text = "X", BackgroundColor3 = Color3.fromRGB(235, 80, 90), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.97, 0.03),
	Size = UDim2.fromScale(0.09, 0.13), SizeConstraint = Enum.SizeConstraint.RelativeYY, Selectable = true, ZIndex = 6}, screen)
Art.SkinClose(close)
mk("UISizeConstraint", {MinSize = touch and Vector2.new(44, 44) or Vector2.zero}, close) -- touch: never smaller than a 44px target
local row = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.25), Size = UDim2.fromScale(0.92, 0.5), ZIndex = 3}, screen)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.012, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, row)
local boostLabels = {}
local tileLabels = {} -- per tile: name / rarity / chance / boost (re-laid out by applyLayout on small screens)
for i, pet in ipairs(EGG.Pets) do
	local col = PetConfig.Rarities[pet.Rarity] or WHITE
	local tile = mk("Frame", {BackgroundColor3 = col:Lerp(Color3.fromRGB(20, 40, 85), 0.55), BackgroundTransparency = 0.15, Size = UDim2.fromScale(0.19, 1), LayoutOrder = i, ZIndex = 3}, row)
	mk("UICorner", {CornerRadius = UDim.new(0.1, 0)}, tile)
	mk("UIStroke", {Thickness = 2.5, Color = col}, tile)
	petView(tile, pet.Name, {Position = UDim2.fromScale(0.05, 0.02), Size = UDim2.fromScale(0.9, 0.56)})
	local nameL = label(tile, pet.Name, {Position = UDim2.fromScale(0.04, 0.58), Size = UDim2.fromScale(0.92, 0.12), TextColor3 = col})
	local rarityL = label(tile, pet.Rarity:upper(), {Position = UDim2.fromScale(0.1, 0.7), Size = UDim2.fromScale(0.8, 0.08), TextColor3 = ICE})
	local chanceL = label(tile, pet.Chance .. "%", {Position = UDim2.fromScale(0.1, 0.78), Size = UDim2.fromScale(0.8, 0.12), TextColor3 = WHITE})
	local boostL = label(tile, "", {Position = UDim2.fromScale(0.04, 0.9), Size = UDim2.fromScale(0.92, 0.09), TextColor3 = Color3.fromRGB(150, 255, 170)})
	boostLabels[pet.Name] = boostL
	tileLabels[#tileLabels + 1] = {name = nameL, rarity = rarityL, chance = chanceL, boost = boostL}
	for _, l in ipairs({nameL, rarityL, chanceL, boostL}) do mk("UITextSizeConstraint", {MinTextSize = 11}, l) end -- TextScaled never shrinks below 11
end
local caption = label(screen, "1 pet per egg  \u{2022}  never Golden  \u{2022}  boosts grow with every world you unlock  \u{2022}  Rainbow Verity is the strongest pet in the game",
	{Position = UDim2.fromScale(0.05, 0.77), Size = UDim2.fromScale(0.9, 0.06), TextColor3 = ICE, TextWrapped = true})
local screenBuy, screenBuyL = button(screen, "BUY", GREEN, {Name = "Buy", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0.34, 0.12)})
mk("UISizeConstraint", {MinSize = touch and Vector2.new(120, 44) or Vector2.zero}, screenBuy) -- touch: BUY keeps a 44px-high target (anchored bottom-centre, so it grows upward)
close.Activated:Connect(function() screen.Visible = false end)

-- small windows / phones: the long caption goes, the tile text gets more of the tile height, the X becomes a fixed 44x44 in the corner
-- per tile label: key, x, width, then {y, height} normal and {y, height} small
local TILE_ROWS = {
	{"name", 0.04, 0.92, 0.58, 0.12, 0.58, 0.12},
	{"rarity", 0.1, 0.8, 0.7, 0.08, 0.7, 0.09},
	{"chance", 0.1, 0.8, 0.78, 0.12, 0.79, 0.10},
	{"boost", 0.04, 0.92, 0.9, 0.09, 0.89, 0.10},
}
local lastSmall
local function applyLayout()
	local w = screen.AbsoluteSize.X
	if w <= 0 then return end -- not laid out yet; the Visible handler below tries again when the screen opens
	local small = w < 600
	if small == lastSmall then return end
	lastSmall = small
	caption.Visible = not small
	row.Position = small and UDim2.fromScale(0.04, 0.22) or UDim2.fromScale(0.04, 0.25)
	row.Size = small and UDim2.fromScale(0.92, 0.58) or UDim2.fromScale(0.92, 0.5)
	for _, tl in ipairs(tileLabels) do
		for _, r in ipairs(TILE_ROWS) do
			local l = tl[r[1]]
			local y, h = r[small and 6 or 4], r[small and 7 or 5]
			l.Position, l.Size = UDim2.fromScale(r[2], y), UDim2.fromScale(r[3], h)
		end
	end
	close.AnchorPoint = Vector2.new(1, 0)
	if small then
		close.SizeConstraint = Enum.SizeConstraint.RelativeXY
		close.Size = UDim2.fromOffset(44, 44)
		close.Position = UDim2.new(1, -8, 0, 8)
	else
		close.SizeConstraint = Enum.SizeConstraint.RelativeYY
		close.Size = UDim2.fromScale(0.09, 0.13)
		close.Position = UDim2.fromScale(0.97, 0.03)
	end
end
applyLayout()
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)

-- every way the screen hides (X, B, shop/other panel, other menu, garage/arena/driving, hatch) is just Visible = false; the B action and the menu poll live exactly while it shows
local BACK_ACTION = "VerityEggBack"
local function onBack(_, state)
	if state == Enum.UserInputState.Begin then screen.Visible = false end
	return Enum.ContextActionResult.Sink
end
local function hideEgg() screen.Visible = false end

-- one menu at a time (UILayout contract): the screen (103) draws over the garage window / offer card (PlowShopGui 101), the inspect panel (102) and
-- sits next to UPGRADES (150) and the HELP / MINI PLOWS panels, so it closes itself when ANOTHER menu opens (state-based, no DisplayOrder involved).
-- RNG panels are watched through wirePanels below; this poll covers every other UILayout.openMenu key. A menu that was already open when the screen
-- opened is left to its own script (it closes itself when it sees the egg screen open), so only a menu that opens AFTER the screen opens closes it.
local OTHER_MENUS = {"UpgradeTree", "GarageWindow", "OfferCard", "Inspect", "MiniPlow", "HelpMenu"}
local ONLY = {} -- ONLY[key] = the `ignore` set for UILayout.openMenu that leaves just that one menu to be tested
for _, k in ipairs(OTHER_MENUS) do
	local ig = {Panels = true, EggScreen = true}
	for _, o in ipairs(OTHER_MENUS) do if o ~= k then ig[o] = true end end
	ONLY[k] = ig
end
local function menusOpen() -- { [key] = true } for each other menu showing right now (per key, so one stuck menu cannot hide a newly opened one)
	local s = {}
	for _, k in ipairs(OTHER_MENUS) do s[k] = UILayout.openMenu(pg, ONLY[k]) ~= nil end
	return s
end
local pollId = 0 -- bumped on every show / hide: a loop from an earlier opening stops at its next tick, so there is never more than one
local function pollMenus()
	pollId += 1
	local my = pollId
	if not screen.Visible then return end
	local seen = menusOpen()
	task.spawn(function()
		while true do
			task.wait(0.25)
			if my ~= pollId or not screen.Visible then return end
			local now = menusOpen()
			for k, on in pairs(now) do
				if on and not seen[k] then
					hideEgg()
					return
				end
			end
			seen = now
		end
	end)
end

screen:GetPropertyChangedSignal("Visible"):Connect(function()
	if screen.Visible then
		applyLayout()
		CAS:BindAction(BACK_ACTION, onBack, false, Enum.KeyCode.ButtonB)
	else
		CAS:UnbindAction(BACK_ACTION)
	end
	pollMenus()
end)
for _, a in ipairs({"InGarage", "InArenaIsland", "PlowDriving"}) do -- garage / arena island / vehicle start: nothing of the shop stays up
	player:GetAttributeChangedSignal(a):Connect(function() if player:GetAttribute(a) == true then hideEgg() end end)
end
-- the paid hatch reveal (PetClient, RNGGui DisplayOrder 100) plays under this screen (103): get out of its way once the pet is granted
task.spawn(function()
	local hatched = RS:WaitForChild("PetHatched", 30)
	if hatched and hatched:IsA("RemoteEvent") then
		hatched.OnClientEvent:Connect(function(kind, eggId)
			if kind == "Hatched" and (eggId == nil or eggId == PRODUCT.Egg) then hideEgg() end
		end)
	end
end)

--------------------------------------------------
-- the shop card
--------------------------------------------------
local card, cardPrice, cardTag, cardBuy, cardBuyL
local function buildCard(inner)
	if inner:FindFirstChild("VerityEggCard") then return end
	card = mk("Frame", {Name = "VerityEggCard", BackgroundColor3 = Color3.fromRGB(40, 80, 160), Position = UDim2.fromScale(0.03, 0.03), Size = UDim2.fromScale(0.94, 0.94), ZIndex = 4}, inner)
	mk("UICorner", {CornerRadius = UDim.new(0.06, 0)}, card)
	Art.SkinPanel(card, "dark")
	view(card, EggModels.create(PRODUCT.Egg), {Position = UDim2.fromScale(0.03, 0.1), Size = UDim2.fromScale(0.34, 0.55)})
	label(card, "EXCLUSIVE", {Position = UDim2.fromScale(0.05, 0.66), Size = UDim2.fromScale(0.3, 0.07), TextColor3 = Color3.fromRGB(255, 140, 220)})
	label(card, "VERITY EGG", {Position = UDim2.fromScale(0.4, 0.06), Size = UDim2.fromScale(0.56, 0.11), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD})
	label(card, PRODUCT.Benefit, {Position = UDim2.fromScale(0.4, 0.17), Size = UDim2.fromScale(0.56, 0.06), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE})
	cardPrice = label(card, "", {RichText = true, Position = UDim2.fromScale(0.4, 0.24), Size = UDim2.fromScale(0.38, 0.09), TextXAlignment = Enum.TextXAlignment.Left})
	cardTag = mk("Frame", {BackgroundColor3 = Color3.fromRGB(240, 60, 90), Position = UDim2.fromScale(0.8, 0.245), Size = UDim2.fromScale(0.15, 0.08), ZIndex = 5}, card)
	mk("UICorner", {CornerRadius = UDim.new(1, 0)}, cardTag)
	label(cardTag, "-" .. PRODUCT.SaleTag .. "%", {Size = UDim2.fromScale(0.86, 0.8), Position = UDim2.fromScale(0.07, 0.1), ZIndex = 6})
	-- every outcome with its odds, before purchase (same table the server rolls from)
	label(card, "YOU GET ONE OF:", {Position = UDim2.fromScale(0.4, 0.35), Size = UDim2.fromScale(0.56, 0.055), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ICE})
	local list = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.4, 0.41), Size = UDim2.fromScale(0.56, 0.36), ZIndex = 4}, card)
	mk("UIListLayout", {Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder}, list)
	local total = 0
	for i, pet in ipairs(EGG.Pets) do
		total += pet.Chance
		local col = PetConfig.Rarities[pet.Rarity] or WHITE
		local r = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.18), LayoutOrder = i, ZIndex = 4}, list)
		petView(r, pet.Name, {Size = UDim2.fromScale(1.3, 1.3), Position = UDim2.fromScale(0, -0.15), SizeConstraint = Enum.SizeConstraint.RelativeYY})
		label(r, ('<font color="%s">%s</font>'):format(hex(col), pet.Name), {RichText = true, Position = UDim2.fromScale(0.11, 0), Size = UDim2.fromScale(0.64, 1), TextXAlignment = Enum.TextXAlignment.Left})
		label(r, pet.Chance .. "%", {Position = UDim2.fromScale(0.76, 0), Size = UDim2.fromScale(0.24, 1), TextXAlignment = Enum.TextXAlignment.Right})
	end
	assert(total == 100, "Verity Egg odds must sum to 100")
	local det = button(card, "DETAILS", BLUE, {Name = "Details", Position = UDim2.fromScale(0.04, 0.8), Size = UDim2.fromScale(0.3, 0.13)})
	cardBuy, cardBuyL = button(card, "BUY", GREEN, {Name = "Buy", Position = UDim2.fromScale(0.4, 0.8), Size = UDim2.fromScale(0.56, 0.13)})
	det.Activated:Connect(function() screen.Visible = true end)
	cardBuy.Activated:Connect(function() if server.canBuy then remote:InvokeServer("Prompt", PRODUCT.Key) end end)
end
screenBuy.Activated:Connect(function() if server.canBuy then remote:InvokeServer("Prompt", PRODUCT.Key) end end)

local function refresh()
	local rich, sale = priceRich()
	local ok = server.canBuy and not restricted()
	local txt = ok and "BUY" or "COMING SOON"
	for _, pair in ipairs({{cardBuy, cardBuyL}, {screenBuy, screenBuyL}}) do
		local b, l = pair[1], pair[2]
		if b then
			b.BackgroundColor3 = ok and GREEN or GREY
			b.AutoButtonColor = ok
			l.Text = txt
		end
	end
	if cardPrice then cardPrice.Text = rich; cardTag.Visible = sale end
	screenPrice.Text = rich
	for _, pet in ipairs(EGG.Pets) do
		local l = boostLabels[pet.Name]
		if l then l.Text = pct(PetConfig.BoostOf(pet, player)) .. " Snow now" end
	end
end

-- the egg screen belongs to the SHOP panel: it closes when Shop hides, when any other panel (PETS, TRAVEL, ...) shows, or when Shop is rebuilt.
-- wired once per Panels/Shop pair (attach() runs again on every restriction change / RNGGui rebuild, so the old connections are dropped first)
local wired = {panels = nil, shop = nil, conns = {}}
local function unwire()
	for _, c in ipairs(wired.conns) do c:Disconnect() end
	table.clear(wired.conns)
	wired.panels, wired.shop = nil, nil
end
local function watchPanel(p, shop)
	if not p:IsA("GuiObject") then return end
	table.insert(wired.conns, p:GetPropertyChangedSignal("Visible"):Connect(function()
		if p == shop then
			if not p.Visible then hideEgg() end
		elseif p.Visible then
			hideEgg()
		end
	end))
	if p ~= shop and p.Visible then hideEgg() end
end
local function wirePanels(panels, shop)
	if wired.panels == panels and wired.shop == shop then return end
	unwire()
	hideEgg() -- a rebuilt RNGGui leaves nothing for the old screen to belong to
	wired.panels, wired.shop = panels, shop
	for _, p in ipairs(panels:GetChildren()) do watchPanel(p, shop) end
	table.insert(wired.conns, panels.ChildAdded:Connect(function(p) watchPanel(p, shop) end))
	table.insert(wired.conns, shop.AncestryChanged:Connect(function() if not shop:IsDescendantOf(panels) then hideEgg() end end))
end

-- attach to the SHOP panel (re-attach if RNGGui is rebuilt)
local function attach()
	local rng = pg:FindFirstChild("RNGGui")
	local panels = rng and rng:FindFirstChild("Panels")
	local shop = panels and panels:FindFirstChild("Shop")
	local inner = shop and shop:FindFirstChild("Inner")
	if not inner then return end
	wirePanels(panels, shop)
	buildCard(inner)
	local hide = restricted()
	card.Visible = not hide
	local content = inner:FindFirstChild("Content")
	if content then content.Visible = hide end -- the placeholder only shows when the egg can't
	if hide then screen.Visible = false end
	refresh()
end
task.spawn(function()
	local rng = pg:WaitForChild("RNGGui", 60)
	if rng then rng:WaitForChild("Panels", 30) end
	attach()
end)
pg.ChildAdded:Connect(function(c) if c.Name == "RNGGui" then task.delay(1, attach) end end)
player:GetAttributeChangedSignal("PaidRandomRestricted"):Connect(attach)
player.AttributeChanged:Connect(function(a) if a:sub(1, 6) == "Stage_" then refresh() end end)

-- server state + real price (never prompts by itself)
local function pull()
	local ok, res = pcall(function() return remote:InvokeServer("State", PRODUCT.Key) end)
	if ok and type(res) == "table" then server = res end
	if salesOn() and not info.Price and not info.Failed then
		local got, r
		for attempt = 1, 3 do
			got, r = pcall(function() return MPS:GetProductInfoAsync(PRODUCT.Id, Enum.InfoType.Product) end)
			if got then break end
			task.wait(attempt)
		end
		info = got and {Price = r.PriceInRobux} or {Failed = true}
	end
	refresh()
end
task.spawn(pull)
player:GetAttributeChangedSignal("PaidRandomRestricted"):Connect(function() task.spawn(pull) end)
MPS.PromptProductPurchaseFinished:Connect(function() task.spawn(pull) end)

-- gentle spin for the previews (only while visible)
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, s in ipairs(spinners) do
		if s.vp.Parent and s.vp:FindFirstAncestorWhichIsA("LayerCollector") and s.vp.Visible then
			s.model:PivotTo(CFrame.Angles(0, math.sin(t * 0.8) * 0.6, 0))
		end
	end
end)
