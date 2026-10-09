-- PassClient (2026-10-05, Claude, task 8): compact snowy offer cards on the HUD (PassConfig); since 2026-10-06 on the LEFT with OP flair.
-- Card click -> details popup with the exact contents -> BUY opens the Roblox purchase prompt (only after that explicit click, only
-- when sales are on and the pass is really for sale). Prices come from MarketplaceService:GetProductInfoAsync (regional pricing);
-- no fake timers or discounts. States: loading / owned / coming soon (no id, sales off or not for sale) / tap to retry (price lookup
-- failed; a tap and a 30 s timer run it again) / price.
-- Hidden on the arena island, during the intro / first tutorial, during events (SuppressEvents) and while any menu is open
-- (UILayout.openMenu: RNG panels, UPGRADES, garage, egg screen, MINI PLOWS, HELP menu).
-- Small screens: the column collapses into one "OFFERS" button (folds away again when a card is picked or driving starts);
-- the details popup is then 0.8 x 0.9 of the screen with a scrolling, wrapped contents list (text never below 12 px).
-- Granting is server-side only (PassService).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local P = require(RS:WaitForChild("PassConfig"))
local Art = require(RS:WaitForChild("FeatureUIArt"))
local UILayout = require(RS:WaitForChild("UILayout"))
local remote = RS:WaitForChild("PassRemote", 30)
local event = RS:WaitForChild("PassEvent", 30)
local pg = player:WaitForChild("PlayerGui")
local FONT, NAVY, WHITE = Enum.Font.FredokaOne, Color3.fromRGB(20, 40, 85), Color3.new(1, 1, 1)

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function stroke(o, t) return mk("UIStroke", {Thickness = t or 2.5, Color = NAVY, ApplyStrokeMode = o:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border}, o) end
local function label(parent, text, props)
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE, ZIndex = 4}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	stroke(l, 2)
	return l
end

local gui = mk("ScreenGui", {Name = "PassOffersGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 11}, pg)
-- 2026-10-06 (wiktor's marked screenshot: "place the offers here", then "more to the left bottom just on the side of help"): the offer
-- cards moved from the right side to the bottom-left, standing right beside the HELP / TRAVEL stack with their bottom level with
-- TRAVEL's. They follow those buttons' live position every frame (helpAnchor); COLUMN_POS is only the fallback before they exist.
local COLUMN_POS = UDim2.new(0.11, 0, 0.93, 0)
local column = mk("Frame", {Name = "Offers", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = COLUMN_POS, Size = UDim2.new(0.17, 0, 0.19, 0)}, gui)
mk("UIListLayout", {Padding = UDim.new(0.06, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left}, column)
mk("UISizeConstraint", {MinSize = Vector2.new(170, 110), MaxSize = Vector2.new(320, 210)}, column)
local toggle = mk("TextButton", {Name = "OffersToggle", Text = "", AnchorPoint = Vector2.new(0, 1), Position = COLUMN_POS, Size = UDim2.fromOffset(120, 40), BackgroundColor3 = Color3.fromRGB(255, 200, 70), Visible = false}, gui)
toggle:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, toggle); stroke(toggle, 3)
Art.Skin(toggle)
Art.Icon(toggle, "starter-pack", UDim2.fromScale(0.035, 0.1), UDim2.fromScale(0.2, 0.8), "FeatureOffersIcon")
label(toggle, "OFFERS", {Size = UDim2.fromScale(0.7, 0.72), Position = UDim2.fromScale(0.26, 0.14)})

-- details popup
-- Active = true: a click on the popup's blank space is sunk here and never reaches the garage car ClickDetector behind it.
-- Phones / short windows (UILayout.isSmall) get the big popup; the render loop below switches between the two sizes.
-- On small screens the width is capped to the area left of the touch action column (applyPopSize in the render loop), so the popup
-- never covers DRIVE / DRIFT / RECOVER or the jump button; POP_SIZE_SMALL only supplies the 0.9 height.
local POP_SIZE, POP_SIZE_SMALL, POP_MIN = UDim2.fromScale(0.34, 0.5), UDim2.fromScale(0.8, 0.9), 300
local pop = mk("Frame", {Name = "OfferDetails", Active = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = POP_SIZE, BackgroundColor3 = Color3.fromRGB(52, 102, 190), Visible = false}, gui)
pop:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.06, 0)}, pop); stroke(pop, 4)
mk("UISizeConstraint", {MinSize = Vector2.new(POP_MIN, POP_MIN)}, pop)
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(80, 140, 225), Color3.fromRGB(32, 64, 135))}, pop)
Art.Skin(pop)
local popIcon = mk("ImageLabel", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.3, 0.3), ScaleType = Enum.ScaleType.Fit}, pop)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, popIcon)
local popTitle = label(pop, "", {Position = UDim2.fromScale(0.36, 0.06), Size = UDim2.fromScale(0.52, 0.13), TextXAlignment = Enum.TextXAlignment.Left})
local popPrice = label(pop, "", {Position = UDim2.fromScale(0.36, 0.2), Size = UDim2.fromScale(0.52, 0.09), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 230, 140)})
-- contents list: a Y-scrolling list so wrapped rows keep a readable size (UITextSizeConstraint MinTextSize 12) instead of shrinking
-- to fit. Rows are offset-high (layoutRows) because the canvas sizes itself (AutomaticCanvasSize), so no Scale-Y children here.
local POP_ROW_GAP, POP_ROW_MIN, POP_ROW_MAX = 2, 26, 44
local popList = mk("ScrollingFrame", {Name = "Contents", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromScale(0.06, 0.38), Size = UDim2.fromScale(0.88, 0.42),
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 4, ScrollBarImageColor3 = WHITE, VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar}, pop)
mk("UIListLayout", {Padding = UDim.new(0, POP_ROW_GAP), SortOrder = Enum.SortOrder.LayoutOrder}, popList)
local function layoutRows()
	local rows = {}
	for _, c in ipairs(popList:GetChildren()) do if c:IsA("TextLabel") then table.insert(rows, c) end end
	if #rows == 0 then return end
	-- as tall as the window allows when everything fits, never below POP_ROW_MIN (two lines of 12 px); beyond that the list scrolls
	local rh = math.clamp(math.floor((popList.AbsoluteSize.Y - POP_ROW_GAP * (#rows - 1)) / #rows), POP_ROW_MIN, POP_ROW_MAX)
	for _, r in ipairs(rows) do r.Size = UDim2.new(1, 0, 0, rh) end
end
popList:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutRows) -- popup resized (phone <-> desktop, window resize); connected once
-- BUY / CLOSE keep a 44 px touch height (UILayout.MIN_TOUCH); bottoms stay at 0.95 so they grow upwards
local popBuy = mk("TextButton", {Name = "Buy", Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.36, 0.95), Size = UDim2.fromScale(0.5, 0.13), BackgroundColor3 = Color3.fromRGB(70, 200, 105), Selectable = true}, pop)
popBuy:SetAttribute("SnowUIDecor", true)
mk("UISizeConstraint", {MinSize = Vector2.new(0, UILayout.MIN_TOUCH)}, popBuy)
mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, popBuy); stroke(popBuy, 3)
Art.Skin(popBuy)
local popBuyText = label(popBuy, "BUY", {Size = UDim2.fromScale(0.86, 0.7), Position = UDim2.fromScale(0.07, 0.15)})
local popClose = mk("TextButton", {Name = "Close", Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.78, 0.95), Size = UDim2.fromScale(0.3, 0.13), BackgroundColor3 = Color3.fromRGB(235, 90, 100), Selectable = true}, pop)
popClose:SetAttribute("SnowUIDecor", true)
mk("UISizeConstraint", {MinSize = Vector2.new(0, UILayout.MIN_TOUCH)}, popClose)
mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, popClose); stroke(popClose, 3)
Art.Skin(popClose)
label(popClose, "CLOSE", {Size = UDim2.fromScale(0.86, 0.7), Position = UDim2.fromScale(0.07, 0.15)})
popClose.Activated:Connect(function() pop.Visible = false end)

local owned, info, cards = {}, {}, {}
local current
local expanded = false -- phones: the OFFERS list is open (declared here because openDetails folds it away)
-- why a pass cannot be bought right now, or nil when it has a real price. COMING SOON only when it truly is not for sale
-- (no id, sales off, ForSale == false); a running lookup is LOADING..., a failed one is TAP TO RETRY.
local function unavailableText(pass)
	local i = info[pass.Key]
	if not P.SalesEnabled or not pass.Id or (i and i.ForSale == false) then return "COMING SOON" end
	if i == nil then return "LOADING..." end
	if i.Failed then return "TAP TO RETRY" end
	return nil
end
local function priceText(pass)
	if owned[pass.Key] then return "OWNED \u{2713}" end
	return unavailableText(pass) or ("\u{E002} " .. tostring(info[pass.Key].Price)) -- Robux glyph + the real player-facing price
end
local function canBuy(pass)
	local i = info[pass.Key]
	return P.SalesEnabled and pass.Id ~= nil and not owned[pass.Key] and i ~= nil and i.ForSale == true and not i.Failed
end
local function refresh()
	for key, c in pairs(cards) do
		c.price.Text = priceText(c.pass)
		c.frame.BackgroundColor3 = owned[key] and Color3.fromRGB(40, 110, 80) or c.pass.Color:Lerp(Color3.fromRGB(26, 60, 108), 0.18)
	end
	if current and pop.Visible then
		popPrice.Text = priceText(current)
		local ok = canBuy(current)
		local i = info[current.Key]
		local retry = not owned[current.Key] and i ~= nil and i.Failed == true -- the button reads TAP TO RETRY and re-runs the lookup
		popBuy.AutoButtonColor = ok or retry
		popBuy.BackgroundColor3 = ok and Color3.fromRGB(70, 200, 105) or Color3.fromRGB(150, 158, 175)
		popBuyText.Text = owned[current.Key] and "OWNED" or (ok and "BUY" or unavailableText(current) or "COMING SOON")
	end
end

-- price lookup (regional price + for-sale flag) for one pass. A failed lookup stays {Failed = true} (TAP TO RETRY) and is run again by a
-- card tap / popup open / BUY tap (retryLookup) and by the 30 s timer below. One lookup per key at a time. Never prompts a purchase.
local looking, lastTry = {}, {}
local function lookup(pass)
	if looking[pass.Key] then return end
	if not (pass.Id and P.SalesEnabled) then info[pass.Key] = {ForSale = false}; refresh(); return end
	looking[pass.Key] = true
	if info[pass.Key] ~= nil then info[pass.Key] = nil; refresh() end -- a retry shows LOADING... again
	local ok, res
	for attempt = 1, 3 do
		ok, res = pcall(function() return MPS:GetProductInfoAsync(pass.Id, Enum.InfoType.GamePass) end)
		if ok then break end
		if attempt < 3 then task.wait(attempt) end
	end
	if ok and type(res) == "table" then
		info[pass.Key] = {Price = res.PriceInRobux, ForSale = res.IsForSale == true and res.PriceInRobux ~= nil}
	else
		info[pass.Key] = {Failed = true}
	end
	lastTry[pass.Key] = os.clock()
	looking[pass.Key] = nil
	refresh()
end
local function retryLookup(pass)
	local i = info[pass.Key]
	if i and i.Failed and not owned[pass.Key] and not looking[pass.Key] then task.spawn(lookup, pass) end
end

local function openDetails(pass)
	current = pass
	expanded = false -- on phones the OFFERS list folds away as soon as a card is picked
	popIcon.Image = pass.Icon or ""
	popTitle.Text = pass.Name
	popList.CanvasPosition = Vector2.zero
	for _, c in ipairs(popList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
	for i, line in ipairs(pass.Details or {}) do
		local row = label(popList, "\u{2022} " .. line, {Size = UDim2.new(1, 0, 0, POP_ROW_MIN), LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextColor3 = Color3.fromRGB(230, 240, 255)})
		mk("UITextSizeConstraint", {MinTextSize = UILayout.MIN_TEXT, MaxTextSize = 24}, row)
	end
	layoutRows()
	pop.Visible = true
	retryLookup(pass) -- opening the popup after a failed lookup tries again
	refresh()
end
popBuy.Activated:Connect(function()
	if current and canBuy(current) then MPS:PromptGamePassPurchase(player, current.Id) -- explicit click only; the server verifies + grants
	elseif current then retryLookup(current) end -- TAP TO RETRY
end)

-- OP flair (2026-10-06, wiktor: "add flashy OP text"): a pulsing tilted "OP!" badge, a gold title with a white shine sweeping
-- across it, and a border that glows gold. The words come from PassConfig (Name / Hype) so they stay true to what the pass gives.
local GOLD = Color3.fromRGB(255, 214, 70)
local shine = {}
local function opFlair(f, badgePos, badgeRot, title, frameStroke)
	local badge = mk("Frame", {Name = "OPBadge", AnchorPoint = Vector2.new(0.5, 0.5), Position = badgePos, Size = UDim2.fromScale(0.3, 0.42), Rotation = badgeRot, BackgroundColor3 = Color3.fromRGB(255, 60, 90), ZIndex = 6}, f)
	badge:SetAttribute("SnowUIDecor", true)
	mk("UIAspectRatioConstraint", {AspectRatio = 2.1}, badge)
	mk("UICorner", {CornerRadius = UDim.new(0.4, 0)}, badge); stroke(badge, 2.5)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 140, 50), Color3.fromRGB(225, 25, 110))}, badge)
	label(badge, "OP!", {Size = UDim2.fromScale(0.86, 0.78), Position = UDim2.fromScale(0.07, 0.11), ZIndex = 7})
	local grad
	if title then
		title.TextColor3 = WHITE
		grad = mk("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(0.42, GOLD),
			ColorSequenceKeypoint.new(0.5, WHITE), ColorSequenceKeypoint.new(0.58, GOLD), ColorSequenceKeypoint.new(1, GOLD)})}, title)
	end
	table.insert(shine, {badge = badge, scale = mk("UIScale", {}, badge), rot = badgeRot, grad = grad, stroke = frameStroke, phase = #shine * 1.7})
end
local function animateFlair()
	local t = os.clock()
	for _, s in ipairs(shine) do
		local k = t * 2.4 + s.phase
		s.scale.Scale = 1 + 0.1 * math.max(0, math.sin(k * 1.5)) -- quick heartbeat pulse
		s.badge.Rotation = s.rot + 5 * math.sin(k)
		if s.grad then s.grad.Offset = Vector2.new(((t * 0.55 + s.phase * 0.3) % 1.9) - 0.95, 0) end
		if s.stroke then s.stroke.Color = NAVY:Lerp(GOLD, 0.5 + 0.5 * math.sin(k * 0.8)) end
	end
end

-- 2026-10-06 (wiktor: "make better icon for starter pack" / "line it up over the rewards"): a Square pass (the Starter Pack) is a card
-- exactly the size of the REWARDS button, standing right above it in the same column; it is placed every frame from REWARDS' live
-- position, so it stays lined up on every screen size and safe area. The other offers keep their column.
local squares = {}
local function makeSquare(pass)
	local f = mk("TextButton", {Name = pass.Key, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, Selectable = true, Visible = false, ZIndex = 3}, gui)
	f:SetAttribute("SnowUIDecor", true)
	mk("ImageLabel", {Name = "Icon", BackgroundTransparency = 1, Image = pass.Icon or "", ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromScale(-0.06, -0.04), Size = UDim2.fromScale(1.12, 0.86), ZIndex = 3}, f)
	local title = label(f, "STARTER PACK", {Position = UDim2.fromScale(-0.1, 0.74), Size = UDim2.fromScale(1.2, 0.22)})
	opFlair(f, UDim2.fromScale(0.04, 0.3), -14, title, nil)
	local pill = mk("Frame", {Name = "Price", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.06), Size = UDim2.fromScale(0.98, 0.25), BackgroundColor3 = Color3.fromRGB(255, 196, 46), ZIndex = 4}, f)
	pill:SetAttribute("SnowUIDecor", true)
	mk("UICorner", {CornerRadius = UDim.new(1, 0)}, pill); stroke(pill, 2.5)
	local price = label(pill, "...", {Position = UDim2.fromScale(0.08, 0.1), Size = UDim2.fromScale(0.84, 0.8), ZIndex = 5})
	f.Activated:Connect(function() openDetails(pass) end)
	f.MouseEnter:Connect(function() TweenService:Create(f, TweenInfo.new(0.12), {Rotation = -4}):Play() end)
	f.MouseLeave:Connect(function() TweenService:Create(f, TweenInfo.new(0.12), {Rotation = 0}):Play() end)
	squares[pass.Key] = f
	cards[pass.Key] = {frame = f, price = price, pass = pass}
end
-- bottom-left corner for the offer column: just right of HELP (PlowTutorial.HelpPill), bottom level with TRAVEL (TravelGui.TravelButton)
local function helpAnchor()
	local tut = pg:FindFirstChild("PlowTutorial")
	local help = tut and tut:FindFirstChild("HelpPill")
	if not (help and help.AbsoluteSize.X > 4) then return COLUMN_POS end
	local tg = pg:FindFirstChild("TravelGui")
	local travel = tg and tg:FindFirstChild("TravelButton")
	local hp, hs = help.AbsolutePosition - gui.AbsolutePosition, help.AbsoluteSize -- same frame conversion as placeSquares
	local bottom = hp.Y + hs.Y
	if travel and travel.Visible and travel.AbsoluteSize.Y > 4 then
		bottom = math.max(bottom, travel.AbsolutePosition.Y - gui.AbsolutePosition.Y + travel.AbsoluteSize.Y)
	end
	return UDim2.fromOffset(math.floor(hp.X + hs.X + math.max(10, hs.Y * 0.35)), math.floor(bottom))
end
local function shownChain(o)
	while o and not o:IsA("LayerCollector") do
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return o ~= nil and o.Enabled
end
local function placeSquares(hide)
	local rng = pg:FindFirstChild("RNGGui")
	local rm = rng and rng:FindFirstChild("RightMenu")
	local rewards = rm and rm:FindFirstChild("Rewards")
	local ok = rewards and shownChain(rewards) and rewards.AbsoluteSize.X > 4
	for _, f in pairs(squares) do
		f.Visible = (not hide) and ok == true
		if f.Visible then
			local p, s = rewards.AbsolutePosition - gui.AbsolutePosition, rewards.AbsoluteSize -- AbsolutePosition is global; offsets are in this gui's frame
			f.Size = UDim2.fromOffset(s.X, s.Y)
			f.Position = UDim2.fromOffset(p.X, p.Y - math.max(8, s.Y * 0.12)) -- bottom edge a small gap above REWARDS
		end
	end
end

for i, pass in ipairs(P.Passes) do
	if pass.Square then makeSquare(pass); continue end
	local f = mk("TextButton", {Name = pass.Key, Text = "", AutoButtonColor = true, Size = UDim2.fromScale(1, 0.47), LayoutOrder = i, BackgroundColor3 = pass.Color, Selectable = true}, column)
	f:SetAttribute("SnowUIDecor", true)
	mk("UICorner", {CornerRadius = UDim.new(0.22, 0)}, f)
	local border = stroke(f, 3)
	Art.Skin(f)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 205, 230))}, f)
	local icon = mk("ImageLabel", {BackgroundTransparency = 1, Image = pass.Icon or "", ZIndex = 3, Position = UDim2.fromScale(0.02, 0.06), Size = UDim2.fromScale(0.3, 0.88), ScaleType = Enum.ScaleType.Fit}, f)
	local title = label(f, pass.Name, {Position = UDim2.fromScale(0.33, 0.06), Size = UDim2.fromScale(0.5, 0.34), TextXAlignment = Enum.TextXAlignment.Left})
	label(f, pass.Hype or pass.Benefit, {Position = UDim2.fromScale(0.33, 0.4), Size = UDim2.fromScale(0.64, 0.25), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 245, 200)})
	opFlair(f, UDim2.fromScale(0.93, 0.08), 12, title, border)
	local price = label(f, "...", {Position = UDim2.fromScale(0.33, 0.66), Size = UDim2.fromScale(0.64, 0.28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 232, 140)})
	cards[pass.Key] = {frame = f, price = price, pass = pass, icon = icon}
	f.Activated:Connect(function() openDetails(pass) end)
end

-- real prices (regional) + ownership; never prompts automatically. Every pass looks itself up (refresh() after each one), and a
-- failed lookup is tried again every 30 s for the whole session (a tap on the card / popup / BUY retries at once).
for _, pass in ipairs(P.Passes) do task.spawn(lookup, pass) end
task.spawn(function()
	while true do
		task.wait(10)
		for _, pass in ipairs(P.Passes) do
			if os.clock() - (lastTry[pass.Key] or 0) >= 30 then retryLookup(pass) end
		end
	end
end)
local function pullOwned()
	local ok, res = pcall(function() return remote:InvokeServer("State") end)
	-- merge, never replace: a reply computed before the server's grant can arrive after the Pass_ attribute already flipped
	-- (seen in Play 2026-10-06: the owner's cards stayed COMING SOON)
	if ok and type(res) == "table" and res.owned then
		for k, v in pairs(res.owned) do owned[k] = v == true or player:GetAttribute("Pass_" .. k) == true end
	end
	refresh()
end
for _, pass in ipairs(P.Passes) do player:GetAttributeChangedSignal("Pass_" .. pass.Key):Connect(function() owned[pass.Key] = player:GetAttribute("Pass_" .. pass.Key) == true; refresh() end) end
if event then event.OnClientEvent:Connect(function(kind, key) if kind == "Granted" then owned[key] = true; refresh() end end) end
task.spawn(pullOwned)

-- visibility: respect the arena / intro / tutorial / boss-event HUD and open menus; collapse on small screens
toggle.Activated:Connect(function() expanded = not expanded end)
-- driving starts: fold the OFFERS list away and close the details popup (Active, 0.8 x 0.9 on phones) so neither sits over the
-- thumbstick area or sinks touches there (the toggle stays; PlowDriveGui draws above this gui, so DRIVE can be tapped with the popup open)
player:GetAttributeChangedSignal("PlowDriving"):Connect(function()
	if player:GetAttribute("PlowDriving") == true then
		expanded = false
		pop.Visible = false
	end
end)
local function panelsOpen()
	-- Keep paid cards clear of the active job tracker shown in the same HUD area.
	local contracts = pg:FindFirstChild("ContractGui")
	if contracts then
		local tracker, announce = contracts:FindFirstChild("Tracker"), contracts:FindFirstChild("Announce")
		if (tracker and tracker.Visible) or (announce and announce.Visible) then return true end
	end
	-- one menu at a time: RNG panels (incl. Travel), UPGRADES tree, garage window / card / inspect, egg screen, MINI PLOWS and the
	-- HELP menu (opens right above the cards' corner). State-based, so cards and the details popup wait without a DisplayOrder change.
	return UILayout.openMenu(pg) ~= nil
end
local popSmall, popVpX, popClear -- which popup size / viewport width / left clearance is applied (nil until the first frame)
-- right edge of HELP (PlowTutorial.HelpPill) and TRAVEL (TravelGui.TravelButton) in this gui's space: both draw ABOVE this gui (DisplayOrder 200 / 12 vs 11),
-- so a popup spanning them would hide its own left edge behind them and put BUY under HELP.
local function leftClear()
	local x = 0
	local tut = pg:FindFirstChild("PlowTutorial")
	local help = tut and tut:FindFirstChild("HelpPill")
	if help and help:IsA("GuiObject") and help.AbsoluteSize.X > 4 then x = math.max(x, help.AbsolutePosition.X - gui.AbsolutePosition.X + help.AbsoluteSize.X) end
	local tg = pg:FindFirstChild("TravelGui")
	local travel = tg and tg:FindFirstChild("TravelButton")
	if travel and travel:IsA("GuiObject") and travel.Visible and travel.AbsoluteSize.X > 4 then
		x = math.max(x, travel.AbsolutePosition.X - gui.AbsolutePosition.X + travel.AbsoluteSize.X)
	end
	return x
end
-- small screens: 0.9 of the height and up to 0.8 of the width, but only inside the free area between HELP / TRAVEL (clear, from leftClear) and the
-- touch action column (UILayout.touchColLeft), a GAP each side. MinSize POP_MIN still applies: when that is wider than the free area
-- (portrait 390, which is not a designed layout) the popup is pushed back on screen instead.
local function applyPopSize(vp, small, clear)
	if not small then
		pop.Size, pop.Position = POP_SIZE, UDim2.fromScale(0.5, 0.5)
		return
	end
	local colLeft = UILayout.touchColLeft(vp.X)
	local left = math.max(UILayout.GAP, (clear or 0) + UILayout.GAP)
	local w = math.max(POP_MIN, math.min(0.8 * vp.X, colLeft - UILayout.GAP - left))
	local cx = math.min(left + w / 2, vp.X - UILayout.GAP - w / 2)
	pop.Size = UDim2.new(0, math.floor(w), POP_SIZE_SMALL.Y.Scale, 0)
	pop.Position = UDim2.new(0, math.floor(cx), 0.5, 0)
end
game:GetService("RunService").RenderStepped:Connect(function()
	local hide = player:GetAttribute("InArenaIsland") == true or player:GetAttribute("IntroActive") == true or player:GetAttribute("PlowTutorialDone") ~= true
		or player:GetAttribute("SuppressEvents") == true or panelsOpen()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local small = UILayout.isSmall(vp) -- vp.X < 1000 or vp.Y < 560
	local clear = small and leftClear() or 0
	if small ~= popSmall or vp.X ~= popVpX or math.abs(clear - (popClear or 0)) > 1 then popSmall, popVpX, popClear = small, vp.X, clear; applyPopSize(vp, small, clear) end -- re-applied on resize and when HELP / TRAVEL move
	toggle.Visible = not hide and small
	column.Visible = not hide and (not small or expanded)
	local corner = helpAnchor()
	toggle.Position = corner
	column.Position = small and corner - UDim2.fromOffset(0, 48) or corner -- on small screens the opened cards sit above the button
	placeSquares(hide)
	if not hide then animateFlair() end
	if hide and pop.Visible then pop.Visible = false end
end)
