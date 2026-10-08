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
local player = Players.LocalPlayer
local P = require(RS:WaitForChild("PassConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local PetModels = require(RS:WaitForChild("PetModels"))
local EggModels = require(RS:WaitForChild("EggModels"))
local Art = require(RS:WaitForChild("SnowArt"))
local remote = RS:WaitForChild("ProductRemote", 60)
local pg = player:WaitForChild("PlayerGui")
local PRODUCT = P.Products.VerityEgg
local EGG = PetConfig.EggById[PRODUCT.Egg]
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)
local GOLD, ICE, GREEN, GREY, BLUE = Color3.fromRGB(255, 220, 90), Color3.fromRGB(190, 225, 255), Color3.fromRGB(70, 200, 105), Color3.fromRGB(130, 140, 165), Color3.fromRGB(70, 150, 245)
local ROBUX = "\u{E002}"

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
	BackgroundColor3 = Color3.fromRGB(40, 80, 160), Visible = false, ZIndex = 2}, sg)
mk("UICorner", {CornerRadius = UDim.new(0.05, 0)}, screen)
mk("UISizeConstraint", {MinSize = Vector2.new(330, 260), MaxSize = Vector2.new(980, 640)}, screen)
Art.SkinPanel(screen, "dark")
label(screen, "VERITY EGG", {Position = UDim2.fromScale(0.05, 0.05), Size = UDim2.fromScale(0.6, 0.1), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD})
local screenPrice = label(screen, "", {RichText = true, Position = UDim2.fromScale(0.05, 0.15), Size = UDim2.fromScale(0.5, 0.07), TextXAlignment = Enum.TextXAlignment.Left})
local close = mk("TextButton", {Name = "Close", Text = "X", BackgroundColor3 = Color3.fromRGB(235, 80, 90), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.97, 0.03),
	Size = UDim2.fromScale(0.09, 0.13), SizeConstraint = Enum.SizeConstraint.RelativeYY, Selectable = true, ZIndex = 6}, screen)
Art.SkinClose(close)
local row = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.25), Size = UDim2.fromScale(0.92, 0.5), ZIndex = 3}, screen)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.012, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, row)
local boostLabels = {}
for i, pet in ipairs(EGG.Pets) do
	local col = PetConfig.Rarities[pet.Rarity] or WHITE
	local tile = mk("Frame", {BackgroundColor3 = col:Lerp(Color3.fromRGB(20, 40, 85), 0.55), BackgroundTransparency = 0.15, Size = UDim2.fromScale(0.19, 1), LayoutOrder = i, ZIndex = 3}, row)
	mk("UICorner", {CornerRadius = UDim.new(0.1, 0)}, tile)
	mk("UIStroke", {Thickness = 2.5, Color = col}, tile)
	petView(tile, pet.Name, {Position = UDim2.fromScale(0.05, 0.02), Size = UDim2.fromScale(0.9, 0.56)})
	label(tile, pet.Name, {Position = UDim2.fromScale(0.04, 0.58), Size = UDim2.fromScale(0.92, 0.12), TextColor3 = col})
	label(tile, pet.Rarity:upper(), {Position = UDim2.fromScale(0.1, 0.7), Size = UDim2.fromScale(0.8, 0.08), TextColor3 = ICE})
	label(tile, pet.Chance .. "%", {Position = UDim2.fromScale(0.1, 0.78), Size = UDim2.fromScale(0.8, 0.12), TextColor3 = WHITE})
	boostLabels[pet.Name] = label(tile, "", {Position = UDim2.fromScale(0.04, 0.9), Size = UDim2.fromScale(0.92, 0.09), TextColor3 = Color3.fromRGB(150, 255, 170)})
end
label(screen, "1 pet per egg  \u{2022}  never Golden  \u{2022}  boosts grow with every world you unlock  \u{2022}  Rainbow Verity is the strongest pet in the game",
	{Position = UDim2.fromScale(0.05, 0.77), Size = UDim2.fromScale(0.9, 0.06), TextColor3 = ICE, TextWrapped = true})
local screenBuy, screenBuyL = button(screen, "BUY", GREEN, {Name = "Buy", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0.34, 0.12)})
close.Activated:Connect(function() screen.Visible = false end)

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

-- attach to the SHOP panel (re-attach if RNGGui is rebuilt)
local function attach()
	local rng = pg:FindFirstChild("RNGGui")
	local shop = rng and rng:FindFirstChild("Panels") and rng.Panels:FindFirstChild("Shop")
	local inner = shop and shop:FindFirstChild("Inner")
	if not inner then return end
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
