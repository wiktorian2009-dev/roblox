-- PassConfig (2026-10-05, Claude, task 8): the three paid offers (game passes) shown on the right side of the HUD.
-- SALES ARE OFF until the passes exist in the Creator Dashboard for THIS experience and the place with PassService is published:
--   1. create the passes (see outputs/Passes20261005/README.md - exact steps), 2. paste each pass id into Id below,
--   3. publish, 4. set SalesEnabled = true, publish again, then turn "Item for sale" on in the dashboard.
-- Ids are never invented: Id = nil shows the card as "COMING SOON" and never prompts a purchase.
-- Prices are NOT hardcoded on the cards: the client reads the real player-facing price with GetProductInfoAsync (regional pricing).
-- 2026-10-06 (wiktor's Creator Dashboard): pass ids filled in and checked with GetProductInfoAsync(GamePass) - names match, all
-- "not for sale" today. SalesEnabled stays false until wiktor asks to start selling.
-- 2026-10-07 (wiktor: "yes i do want to start selling"): SalesEnabled = true. The dashboard already has all three on sale
-- (1.5x Snow 14, Starter Pack 14, Aurora Wheels 45 Robux, read with GetProductInfoAsync). Undo: set it back to false and publish.
-- Hype = the flashy line on the HUD card (PassClient); it must stay true to what the pass gives (no invented prices or discounts).
local P = {}
P.SalesEnabled = true
P.Passes = {
	{
		Key = "SnowBoost", Name = "1.5x Snow", Id = 2008364500, DefaultPrice = 10, Icon = "rbxassetid://118980978543857",
		Benefit = "x1.5 Snow forever", Hype = "\u{1F525} x1.5 SNOW FOREVER", Color = Color3.fromRGB(110, 190, 255),
		Details = {"x1.5 Snow from clearing snow and finished jobs", "also treasures, World 2 chests and quest Snow", "applied once - stacks with upgrades, pets and timed boosts"},
	},
	{
		-- Icon 2026-10-06: SnowArt gift box + blade + wheel on a snow pile (outputs/UIArt20261006 icon_starterpack; was rbxassetid://109621099381649)
		Key = "StarterPack", Name = "Starter Pack", Id = 2005917909, DefaultPrice = 15, Icon = "rbxassetid://108336337839177", Square = true,
		-- 2026-10-06 (wiktor: "buff starter pack remove the snow and give full haunted pack"): all 10 Haunted (Cursed-theme) parts at level 1,
		-- replacing the Desert set (each Haunted part beats the Desert one in its slot) and the 3,000 Snow. Old: ServerStorage.StarterPackHauntedBackup_20261006.
		Benefit = "Full Haunted part set - 10 parts", Hype = "10 HAUNTED PARTS", Color = Color3.fromRGB(255, 170, 90),
		Parts = {"blade_grave", "blade_bonechill", "blade_hex", "engine_lantern", "engine_cauldron", "engine_phantom",
			"gear_bonewheels", "gear_graverollers", "gear_haunted", "body_gravehauler"},
		Details = {"3 blades: Grave Digger, Bonechill Scoop, Hex Breaker", "3 engines: Lantern Motor, Cauldron Burner, Phantom V-Twin", "3 wheels: Spiked Bone Wheels, Grave Rollers, Haunted Treads", "Grave Hauler body", "parts stay yours forever - equip them by clicking your car in the garage"},
	},
	{
		Key = "PremiumWheels", Name = "Aurora Wheels", Id = 2006727868, DefaultPrice = 50, Icon = "rbxassetid://106686963600706",
		Benefit = "Premium wheels, yours forever", Hype = "\u{26A1} x1.75 PUSH POWER", Color = Color3.fromRGB(160, 120, 255),
		Parts = {"gear_aurorawheels"},
		Details = {"great grip (92%) and turning", "x1.75 pushing power - strong early, free later gear still beats it", "fits every body; cosmetic in the arena"},
	},
}
P.ByKey, P.ById = {}, {}
for _, p in ipairs(P.Passes) do
	P.ByKey[p.Key] = p
	if p.Id then P.ById[p.Id] = p end
end
-- QUICK ROLLS (2026-10-09, wiktor: "make click to skip trigger game pass payment for quicker rolls"): a perk pass, NOT a HUD card
-- (kept out of P.Passes). Owners skip the garage part-roll reveal with a click / tap / E (same server result). Others who click
-- during a reveal get this pass's purchase prompt (once per roll, at most every few seconds); the reveal keeps playing.
-- Reduced motion and players where paid random items are restricted always skip for free. Presentation only: rolls, odds, pity,
-- cooldown and prices are identical with or without it. Id = nil: skipping stays free for everyone and nothing is ever prompted -
-- create the pass in the Creator Dashboard, paste its id here, publish (outputs/RollReveal20261009/README.md).
P.QuickRolls = {Key = "QuickRolls", Name = "Quick Rolls", Id = nil, Benefit = "Skip the part-roll animation"}
P.Perks = {P.QuickRolls} -- passes checked and granted by PassService but never drawn as HUD cards
for _, p in ipairs(P.Perks) do
	P.ByKey[p.Key] = p
	if p.Id then P.ById[p.Id] = p end
end
P.SnowMult = 1.5 -- the 1.5x Snow pass factor (UpgradeService folds it into SnowMult exactly once)

-- DEVELOPER PRODUCTS (2026-10-06, Claude): repeatable purchases granted by ProductService.ProcessReceipt (server roll, saved before
-- PurchaseGranted, idempotent per PurchaseId). SALES ARE OFF until wiktor creates the product and pastes its id
-- (outputs/Passes20261005/README.md, "Verity Egg"). Id = nil shows COMING SOON and never prompts.
-- Price is what the product is created at (only that is ever charged; the card shows the real price from GetProductInfoAsync).
-- WasPrice / SaleTag are display only: the struck-through "was" price and the -% tag show when ShowSale is true AND the real
-- price equals Price; set ShowSale = false to switch the sale display off.
-- 2026-10-07 (wiktor's dashboard screenshot): Developer Product "Verity EGG" 3717000202 created (49 Robux) -> Id set, sales on.
-- ShowSale off: the egg never sold at 69, so a struck-through "was 69" / -29% would be a made-up discount.
P.ProductSalesEnabled = true
P.Products = {
	VerityEgg = {
		-- 2026-10-06: the dashboard item "Verity egg" (2007075863) is a GAME PASS, not a developer product. A pass can be bought only
		-- once, and ProcessReceipt never fires for passes, so it is NOT used as Id here (the card stays COMING SOON).
		-- To sell repeatable eggs, create a Developer Product (Monetization > Developer Products) and paste ITS id into Id.
		Key = "VerityEgg", Name = "Verity Egg", Id = 3717000202, DashboardPassId = 2007075863, Price = 49, WasPrice = 69, ShowSale = false, Egg = "VerityEgg",
		Benefit = "Exclusive OP pets - 1 pet per egg",
	},
}
P.ProductById = {}
for _, p in pairs(P.Products) do
	if p.Id then P.ProductById[p.Id] = p end
	p.SaleTag = math.floor((1 - p.Price / p.WasPrice) * 100 + 0.5) -- 49 / 69 -> 29 (shown as -29%)
end
return P
