-- PassConfig (2026-10-05, Claude, task 8): the three paid offers (game passes) shown on the right side of the HUD.
-- SALES ARE OFF until the passes exist in the Creator Dashboard for THIS experience and the place with PassService is published:
--   1. create the passes (see outputs/Passes20261005/README.md - exact steps), 2. paste each pass id into Id below,
--   3. publish, 4. set SalesEnabled = true, publish again, then turn "Item for sale" on in the dashboard.
-- Ids are never invented: Id = nil shows the card as "COMING SOON" and never prompts a purchase.
-- Prices are NOT hardcoded on the cards: the client reads the real player-facing price with GetProductInfoAsync (regional pricing).
local P = {}
P.SalesEnabled = false
P.Passes = {
	{
		Key = "SnowBoost", Name = "1.5x Snow", Id = nil, DefaultPrice = 10, Icon = "rbxassetid://118980978543857",
		Benefit = "x1.5 Snow forever", Color = Color3.fromRGB(110, 190, 255),
		Details = {"x1.5 Snow from clearing snow and finished jobs", "also treasures, World 2 chests and quest Snow", "applied once - stacks with upgrades, pets, rebirth and timed boosts"},
	},
	{
		Key = "StarterPack", Name = "Starter Pack", Id = nil, DefaultPrice = 15, Icon = "rbxassetid://109621099381649",
		Benefit = "Desert part set + 3,000 Snow", Color = Color3.fromRGB(255, 170, 90),
		Parts = {"blade_dune", "engine_sandrunner", "gear_balloon", "body_dunerunner"}, Snow = 3000, -- Snow once per profile (about 2.5 min of starter collecting)
		Details = {"Dune Sweeper blade", "Sand Runner engine", "Dune Balloon Tires", "Dune Runner body", "3,000 Snow (once)", "parts stay yours through rebirth - equip them in the workbench"},
	},
	{
		Key = "PremiumWheels", Name = "Aurora Wheels", Id = nil, DefaultPrice = 50, Icon = "rbxassetid://106686963600706",
		Benefit = "Premium wheels, yours forever", Color = Color3.fromRGB(160, 120, 255),
		Parts = {"gear_aurorawheels"},
		Details = {"great grip (92%) and turning", "x1.75 pushing power - strong early, free later gear still beats it", "fits every body; cosmetic in the arena"},
	},
}
P.ByKey, P.ById = {}, {}
for _, p in ipairs(P.Passes) do
	P.ByKey[p.Key] = p
	if p.Id then P.ById[p.Id] = p end
end
P.SnowMult = 1.5 -- the 1.5x Snow pass factor (UpgradeService folds it into SnowMult exactly once)
return P
