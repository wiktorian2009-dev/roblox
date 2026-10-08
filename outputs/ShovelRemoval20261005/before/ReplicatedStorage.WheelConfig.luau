-- WheelConfig (2026-10-03, Claude): the Lucky Wheel. You get 1 free spin for every newly unlocked stage (again after each rebirth).
-- 8 equal slices. Weight = how often the server picks a slice (all 1 = every slice equally likely, so what you see is fair).
-- SnowMinutes = Snow worth that many minutes of your recent digging (same formula as the Daily rewards), so prizes fit every stage.
-- Boost = a personal timed boost from ActivityConfig.Boosts (Snow2 / Luck2 / Super) lasting Seconds.
local W = {}
W.SpinSeconds = 4.5 -- how long the wheel spins on screen; the server refuses another spin sooner than this
W.MinSnowPerMinute = 50 -- floor for new players (no digging speed yet), so bigger slices still show bigger prizes
W.Segments = {
	{Id = "Snow2m",  SnowMinutes = 2,                 Weight = 1, Color = Color3.fromRGB(110, 200, 255), Icon = "snow"},
	{Id = "Luck",    Boost = "Luck2", Seconds = 600,  Weight = 1, Color = Color3.fromRGB(105, 220, 125), Icon = "luck"},
	{Id = "Snow3m",  SnowMinutes = 3,                 Weight = 1, Color = Color3.fromRGB(255, 170, 80),  Icon = "snow"},
	{Id = "SnowX2",  Boost = "Snow2", Seconds = 300,  Weight = 1, Color = Color3.fromRGB(160, 140, 255), Icon = "snow"},
	{Id = "Snow2mB", SnowMinutes = 2,                 Weight = 1, Color = Color3.fromRGB(255, 130, 185), Icon = "snow"},
	{Id = "Super",   Boost = "Super", Seconds = 300,  Weight = 1, Color = Color3.fromRGB(255, 210, 70),  Icon = "rewards"},
	{Id = "Snow4m",  SnowMinutes = 4,                 Weight = 1, Color = Color3.fromRGB(90, 215, 215),  Icon = "snow"},
	{Id = "Jackpot", SnowMinutes = 10, Jackpot = true, Weight = 1, Color = Color3.fromRGB(255, 90, 95),  Icon = "rewards"},
}
return W
