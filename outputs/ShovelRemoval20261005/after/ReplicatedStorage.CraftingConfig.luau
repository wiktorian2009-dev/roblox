-- CraftingConfig (2026-10-03, Claude): recipes for the Crafting Machine in Frostfall Village (MachineService checks and crafts).
-- A recipe costs Snow and/or treasures. Only SPARE treasures are used: the last copy of each treasure always stays in the
-- Treasure Book. The Craft panel builds itself from this list. Enabled = false hides a recipe.
-- Reward kinds:
--   {Kind = "Boost",    Boost = "Snow2" | "Luck2" | "Super", Seconds = 600}
--   {Kind = "Pet",      Pet = "<pet name from PetConfig>"}
--   {Kind = "Treasure", Treasure = "<treasure id from TreasureConfig>"}
--   {Kind = "Snow",     Amount = 1000}
-- Treasure ids come from TreasureConfig (e.g. FrostButton, SnowflakeCharm, IcicleBell, FrozenWatch, HeartOfWinter).
local C = {}
C.Recipes = {
	-- Real recipes get added here later. This example only appears in isolated tests (BalanceTestMode):
	{Id = "ExampleLuckGlobe", Name = "Lucky Snow Globe", Text = "2x Luck for 15 minutes", Snow = 500,
		Treasures = {FrostButton = 2}, Reward = {Kind = "Boost", Boost = "Luck2", Seconds = 900}, Enabled = false, TestOnly = true},
}
return C
