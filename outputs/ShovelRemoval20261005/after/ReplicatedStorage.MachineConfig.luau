-- MachineConfig: Hot Cocoa and Pet Fuser settings (MachineService does the work, MachinesClient shows the panels).
local M = {}
-- HOT COCOA MACHINE (Supply Hut): timed boosts bought with Snow. Price = Snow worth PriceMinutes of your recent digging,
-- so it is fair at every stage (MinSnowPerMinute is the floor for brand-new players). Boost time stacks (max 1 hour).
M.Cocoa = {
	MinSnowPerMinute = 50,
	Drinks = {
		{Id = "Snowy", Name = "Snowy Cocoa", Boost = "Snow2", Seconds = 600, PriceMinutes = 6, Color = Color3.fromRGB(110, 200, 255), Icon = "snow"},
		{Id = "Lucky", Name = "Lucky Cocoa", Boost = "Luck2", Seconds = 600, PriceMinutes = 5, Color = Color3.fromRGB(105, 220, 125), Icon = "luck"},
		{Id = "Super", Name = "Super Cocoa", Boost = "Super", Seconds = 300, PriceMinutes = 6, Color = Color3.fromRGB(255, 195, 70),  Icon = "rewards"},
	},
}
-- PET FUSER (Pet Lodge): Need spare copies of the same pet -> 1 Golden version (PetConfig.GoldenMult x boost). Equipped pets are
-- never used.
M.Fuser = {Need = 3}
return M
