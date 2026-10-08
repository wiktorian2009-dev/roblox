-- PassClient (2026-10-05, Claude, task 8): three compact snowy offer cards on the RIGHT side of the HUD (PassConfig).
-- Card click -> details popup with the exact contents -> BUY opens the Roblox purchase prompt (only after that explicit click, only
-- when sales are on and the pass is really for sale). Prices come from MarketplaceService:GetProductInfoAsync (regional pricing);
-- no fake timers or discounts. States: loading / owned / coming soon (no id, sales off or not for sale) / price.
-- Hidden on the arena island, during the intro / first tutorial, during events (SuppressEvents) and while a menu panel is open.
-- Small screens: the column collapses into one "OFFERS" button. Granting is server-side only (PassService).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local P = require(RS:WaitForChild("PassConfig"))
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
	local l = mk("TextLabel", {BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = text, TextColor3 = WHITE}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	stroke(l, 2)
	return l
end

local gui = mk("ScreenGui", {Name = "PassOffersGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 11}, pg)
-- left of the REWARDS / SPIN icons, below the top-right event banner and above DRIVE / EXIT (measured on the live HUD 2026-10-05)
local column = mk("Frame", {Name = "Offers", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.9, -6, 0.38, 0), Size = UDim2.new(0.135, 0, 0.245, 0)}, gui)
mk("UIListLayout", {Padding = UDim.new(0.03, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right}, column)
mk("UISizeConstraint", {MinSize = Vector2.new(170, 150), MaxSize = Vector2.new(300, 290)}, column)
local toggle = mk("TextButton", {Name = "OffersToggle", Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.9, -6, 0.38, 0), Size = UDim2.fromOffset(120, 40), BackgroundColor3 = Color3.fromRGB(255, 200, 70), Visible = false}, gui)
toggle:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, toggle); stroke(toggle, 3)
label(toggle, "\u{2B50} OFFERS", {Size = UDim2.fromScale(0.86, 0.72), Position = UDim2.fromScale(0.07, 0.14)})

-- details popup
local pop = mk("Frame", {Name = "OfferDetails", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.34, 0.5), BackgroundColor3 = Color3.fromRGB(52, 102, 190), Visible = false}, gui)
pop:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.06, 0)}, pop); stroke(pop, 4)
mk("UISizeConstraint", {MinSize = Vector2.new(300, 300)}, pop)
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(80, 140, 225), Color3.fromRGB(32, 64, 135))}, pop)
local popIcon = mk("ImageLabel", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.04, 0.05), Size = UDim2.fromScale(0.3, 0.3), ScaleType = Enum.ScaleType.Fit}, pop)
mk("UIAspectRatioConstraint", {AspectRatio = 1}, popIcon)
local popTitle = label(pop, "", {Position = UDim2.fromScale(0.36, 0.06), Size = UDim2.fromScale(0.52, 0.13), TextXAlignment = Enum.TextXAlignment.Left})
local popPrice = label(pop, "", {Position = UDim2.fromScale(0.36, 0.2), Size = UDim2.fromScale(0.52, 0.09), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 230, 140)})
local popList = mk("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.06, 0.38), Size = UDim2.fromScale(0.88, 0.4)}, pop)
mk("UIListLayout", {Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder}, popList)
local popBuy = mk("TextButton", {Name = "Buy", Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.36, 0.95), Size = UDim2.fromScale(0.5, 0.13), BackgroundColor3 = Color3.fromRGB(70, 200, 105), Selectable = true}, pop)
popBuy:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, popBuy); stroke(popBuy, 3)
local popBuyText = label(popBuy, "BUY", {Size = UDim2.fromScale(0.86, 0.7), Position = UDim2.fromScale(0.07, 0.15)})
local popClose = mk("TextButton", {Name = "Close", Text = "", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.78, 0.95), Size = UDim2.fromScale(0.3, 0.13), BackgroundColor3 = Color3.fromRGB(235, 90, 100), Selectable = true}, pop)
popClose:SetAttribute("SnowUIDecor", true)
mk("UICorner", {CornerRadius = UDim.new(0.3, 0)}, popClose); stroke(popClose, 3)
label(popClose, "CLOSE", {Size = UDim2.fromScale(0.86, 0.7), Position = UDim2.fromScale(0.07, 0.15)})
popClose.Activated:Connect(function() pop.Visible = false end)

local owned, info, cards = {}, {}, {}
local current
local function priceText(pass)
	if owned[pass.Key] then return "OWNED \u{2713}" end
	local i = info[pass.Key]
	if not P.SalesEnabled or not pass.Id or (i and i.ForSale == false) then return "COMING SOON" end
	if i == nil then return "..." end
	if i.Failed then return "UNAVAILABLE" end
	return "\u{E002} " .. tostring(i.Price) -- Robux glyph + the real player-facing price
end
local function canBuy(pass)
	local i = info[pass.Key]
	return P.SalesEnabled and pass.Id ~= nil and not owned[pass.Key] and i ~= nil and i.ForSale == true and not i.Failed
end
local function refresh()
	for key, c in pairs(cards) do
		c.price.Text = priceText(c.pass)
		c.frame.BackgroundColor3 = owned[key] and Color3.fromRGB(40, 110, 80) or c.pass.Color:Lerp(Color3.fromRGB(30, 60, 120), 0.45)
	end
	if current and pop.Visible then
		popPrice.Text = priceText(current)
		local ok = canBuy(current)
		popBuy.AutoButtonColor = ok
		popBuy.BackgroundColor3 = ok and Color3.fromRGB(70, 200, 105) or Color3.fromRGB(150, 158, 175)
		popBuyText.Text = owned[current.Key] and "OWNED" or (ok and "BUY" or "COMING SOON")
	end
end
local function openDetails(pass)
	current = pass
	popIcon.Image = pass.Icon or ""
	popTitle.Text = pass.Name
	for _, c in ipairs(popList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
	for i, line in ipairs(pass.Details or {}) do
		label(popList, "\u{2022} " .. line, {Size = UDim2.fromScale(1, 0.15), LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(230, 240, 255)})
	end
	pop.Visible = true
	refresh()
end
popBuy.Activated:Connect(function()
	if current and canBuy(current) then MPS:PromptGamePassPurchase(player, current.Id) end -- explicit click only; the server verifies + grants
end)

for i, pass in ipairs(P.Passes) do
	local f = mk("TextButton", {Name = pass.Key, Text = "", AutoButtonColor = true, Size = UDim2.fromScale(1, 0.31), LayoutOrder = i, BackgroundColor3 = pass.Color, Selectable = true}, column)
	f:SetAttribute("SnowUIDecor", true)
	mk("UICorner", {CornerRadius = UDim.new(0.22, 0)}, f); stroke(f, 3)
	mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 205, 230))}, f)
	local icon = mk("ImageLabel", {BackgroundTransparency = 1, Image = pass.Icon or "", Position = UDim2.fromScale(0.02, 0.06), Size = UDim2.fromScale(0.3, 0.88), ScaleType = Enum.ScaleType.Fit}, f)
	label(f, pass.Name, {Position = UDim2.fromScale(0.33, 0.06), Size = UDim2.fromScale(0.64, 0.34), TextXAlignment = Enum.TextXAlignment.Left})
	label(f, pass.Benefit, {Position = UDim2.fromScale(0.33, 0.4), Size = UDim2.fromScale(0.64, 0.24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(225, 238, 255)})
	local price = label(f, "...", {Position = UDim2.fromScale(0.33, 0.66), Size = UDim2.fromScale(0.64, 0.28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 232, 140)})
	cards[pass.Key] = {frame = f, price = price, pass = pass, icon = icon}
	f.Activated:Connect(function() openDetails(pass) end)
end

-- real prices (regional) + ownership; never prompts automatically
task.spawn(function()
	for _, pass in ipairs(P.Passes) do
		if pass.Id and P.SalesEnabled then
			local ok, res
			for attempt = 1, 3 do
				ok, res = pcall(function() return MPS:GetProductInfoAsync(pass.Id, Enum.InfoType.GamePass) end)
				if ok then break end
				task.wait(attempt)
			end
			info[pass.Key] = ok and {Price = res.PriceInRobux, ForSale = res.IsForSale == true and res.PriceInRobux ~= nil} or {Failed = true}
		else
			info[pass.Key] = {ForSale = false}
		end
	end
	refresh()
end)
local function pullOwned()
	local ok, res = pcall(function() return remote:InvokeServer("State") end)
	if ok and type(res) == "table" and res.owned then owned = res.owned end
	refresh()
end
for _, pass in ipairs(P.Passes) do player:GetAttributeChangedSignal("Pass_" .. pass.Key):Connect(function() owned[pass.Key] = player:GetAttribute("Pass_" .. pass.Key) == true; refresh() end) end
if event then event.OnClientEvent:Connect(function(kind, key) if kind == "Granted" then owned[key] = true; refresh() end end) end
task.spawn(pullOwned)

-- visibility: respect the arena / intro / tutorial / boss-event HUD and open menu panels; collapse on small screens
local expanded = false
toggle.Activated:Connect(function() expanded = not expanded end)
local function panelsOpen()
	local rng = pg:FindFirstChild("RNGGui")
	local panels = rng and rng:FindFirstChild("Panels")
	if panels then for _, p in ipairs(panels:GetChildren()) do if p:IsA("GuiObject") and p.Visible then return true end end end
	local shop = pg:FindFirstChild("PlowShopGui")
	if shop then
		local w = shop:FindFirstChild("GarageWindow"); local card = shop:FindFirstChild("OfferCard")
		if (w and w.Visible) or (card and card.Visible) then return true end
	end
	return false
end
game:GetService("RunService").RenderStepped:Connect(function()
	local hide = player:GetAttribute("InArenaIsland") == true or player:GetAttribute("IntroActive") == true or player:GetAttribute("PlowTutorialDone") ~= true
		or player:GetAttribute("SuppressEvents") == true or panelsOpen()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local small = vp.X < 1000 or vp.Y < 560
	toggle.Visible = not hide and small
	column.Visible = not hide and (not small or expanded)
	if small then column.Position = UDim2.new(0.9, -6, 0.38, 48) else column.Position = UDim2.new(0.9, -6, 0.38, 0) end
	if hide and pop.Visible then pop.Visible = false end
end)
