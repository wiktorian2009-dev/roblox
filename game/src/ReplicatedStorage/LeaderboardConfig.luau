-- LeaderboardConfig (2026-10-09, Claude): the global lobby leaderboards (LeaderboardService / LeaderboardClient).
-- Scores come only from the server-side profile:
--   Snow     = d.SnowEarned  (lifetime Snow from clearing, counted in DataService.AddSnow; spending never lowers it)
--   ArenaKOs = d.Arena.KOs   (ArenaService: knockouts credited to the last valid hitter during a live match)
--   Playtime = d.PlayTime    (seconds in game, counted by LeaderboardService from 2026-10-09 on)
-- Store names are the live OrderedDataStores. Changing a name starts that board from zero.
local L = {}

L.Boards = {
	{Id = "Snow", Title = "TOP SNOW", Sub = "Total Snow cleared", Icon = "❄️", Store = "LB_SnowEarned_v1", Log = true,
		Accent = Color3.fromRGB(124, 224, 255)},
	{Id = "ArenaKOs", Title = "ARENA KOs", Sub = "Knockouts in the Bumper Arena", Icon = "💥", Store = "LB_ArenaKOs_v1",
		Accent = Color3.fromRGB(255, 150, 90)},
	{Id = "Playtime", Title = "PLAYTIME", Sub = "Time played", Icon = "⏱️", Store = "LB_Playtime_v1",
		Accent = Color3.fromRGB(150, 230, 140)},
}
L.ById = {}
for _, b in ipairs(L.Boards) do L.ById[b.Id] = b end

L.Show = 10          -- rows drawn on each board
L.Fetch = 50         -- entries read per refresh (also used to show your own rank up to #50)
L.RefreshEvery = 90  -- seconds between global reads (3 GetSortedAsync per refresh)
L.WriteEvery = 120   -- seconds between a player's score writes (only changed scores are written)
L.Tick = 10          -- seconds between playtime counts / own-score attribute updates

-- Snow passes 1e18 in World 2, beyond what an OrderedDataStore integer can hold exactly, so it is stored as
-- floor(log10(value + 1) * LogScale): order is kept and the value comes back to ~13 significant digits.
L.LogScale = 1e13
L.MaxKey = 9e15 -- stay inside exact double integers

function L.Encode(board, v)
	v = tonumber(v) or 0
	if v ~= v or v == math.huge or v < 0 then return nil end
	local k = board.Log and math.floor(math.log10(v + 1) * L.LogScale) or math.floor(v)
	if k > L.MaxKey then return nil end
	return k
end

function L.Decode(board, k)
	k = tonumber(k) or 0
	if board.Log then
		local v = math.max(0, 10 ^ (k / L.LogScale) - 1) * (1 + 3e-13) -- Encode only rounds down; undo that so 2.0M doesn't read 1.9M
		return v < 1e12 and math.floor(v + 0.5) or v
	end
	return k
end

-- "2d 5h", "5h 12m", "12m", "<1m"
function L.FormatTime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local d, h, m = math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600), math.floor(seconds % 3600 / 60)
	if d > 0 then return string.format("%dd %dh", d, h) end
	if h > 0 then return string.format("%dh %dm", h, m) end
	if m > 0 then return string.format("%dm", m) end
	return "<1m"
end

return L
