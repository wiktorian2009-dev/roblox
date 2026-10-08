-- TravelConfig (2026-10-05, Claude): destination registry for free quick travel (TravelService / TravelClient).
-- Built from StageConfig.Order, so every real stage of both worlds is listed and nothing else (no removed stages).
-- Arrival points are the parts in workspace.TravelPoints (same names as the ids here; outputs/Travel20261005/travel_points.luau).
-- The client only ever sends a destination id; the server validates everything.
local RS = game:GetService("ReplicatedStorage")
local S = require(RS:WaitForChild("StageConfig"))

local T = {}
T.Cooldown = 2.5          -- seconds between travels (server)
T.StreamTimeout = 6       -- bounded RequestStreamAroundAsync wait before moving the character
T.Icons = {
	Lobby = "\u{1F3E0}", Garage = "\u{1F527}", Starter = "\u{2744}\u{FE0F}", Desert = "\u{1F3DC}\u{FE0F}", Cursed = "\u{1F480}", Crystal = "\u{1F48E}",
	Retro = "\u{1F579}\u{FE0F}", Jungle = "\u{1F334}", AbsoluteZero = "\u{1F9CA}", Portal = "\u{1F300}", Sakura = "\u{1F338}", Candy = "\u{1F36C}",
	Atlantis = "\u{1F41A}", Toybox = "\u{1F9F8}", Clockwork = "\u{2699}\u{FE0F}", Cloud = "\u{2601}\u{FE0F}", Cosmic = "\u{1F30C}",
}
T.WorldNames = {[1] = "WORLD 1 - FROSTFALL", [2] = "WORLD 2 - SAKURA & BEYOND"}

-- hubs first, then every stage in unlock order
T.List = {
	{Id = "Lobby", Name = "Lobby", World = 1, Kind = "Hub"},
	{Id = "Garage", Name = "My Garage", World = 1, Kind = "Garage"},
}
for _, s in ipairs(S.Order) do
	table.insert(T.List, {Id = s.Id, Name = s.Name, World = s.World or 1, Kind = "Stage", Stage = s.Id})
end
T.ById = {}
for i, d in ipairs(T.List) do d.Order = i; T.ById[d.Id] = d end

-- is this destination open for a player? (Stage_<Id> attributes are set by the server's StageService)
function T.Unlocked(player, dest)
	if not dest then return false end
	if dest.Kind ~= "Stage" or dest.Stage == "Starter" then return true end
	return player:GetAttribute("Stage_" .. dest.Stage) == true
end

-- the real unlock requirement, worded for the menu
function T.Requirement(dest)
	if not dest or dest.Kind ~= "Stage" then return "" end
	local s = S.ById[dest.Stage]
	if not s then return "" end
	local prev = S.Previous and S.Previous(s.Id)
	if (s.Cost or 0) == 0 and prev then return "Opens with " .. prev.Name end
	return string.format("Unlock at its gate: %s Snow", require(RS:WaitForChild("NumberFormat")).Abbreviate(s.Cost or 0)) .. ((prev and prev.Id ~= "Starter") and (" (after " .. prev.Name .. ")") or "")
end

return T
