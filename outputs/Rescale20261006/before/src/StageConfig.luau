-- 2026-10-02 balance pass v2 (Claude): fast start, slower late game. With events/quests/daily/achievements World 1 takes ~4 h for an efficient engaged player, ~5 h casual (model). Older copies: ServerStorage.BalanceBackups
-- 2026-10-05 (Claude, snowplow expansion): stage gates re-measured for the 90-part snowplow economy (outputs/PlowExpansion20261005/sim:
-- efficient engaged player ~3.6 h World 1, ~4.6 h World 2; model estimates, not playtests). Previous values: ServerStorage.PlowExpansionBackup_20261005.
-- STAGES in unlock order. Cost is in snow. Each lock wall in Workspace has a "Stage" attribute = one of these Ids.
local S = {}
S.Order = {
	{Id = "Starter",      Name = "Starter",              Cost = 0},
	{Id = "Desert",       Name = "Desert",               Cost = 5000}, -- was 2.5K
	{Id = "Cursed",       Name = "Cursed Biome",         Cost = 3060000}, -- was 250K -- task 7 body nudge x1.020
	{Id = "Crystal",      Name = "Crystal Caves",        Cost = 1140000000}, -- was 8M (2026-10-03: 54M) -- task 7 body nudge x1.036
	{Id = "Retro",        Name = "Retro World",          Cost = 191000000000}, -- was 250M -- rebalance 2026-10-05: was 260000000000 -- task 7 body nudge x1.061
	{Id = "Jungle",       Name = "Jungle",               Cost = 2380000000000}, -- was 8B -- rebalance 2026-10-05: was 1600000000000 -- task 7 body nudge x1.082
	{Id = "AbsoluteZero", Name = "Absolute Zero",        Cost = 24200000000000}, -- was 250B -- rebalance 2026-10-05: was 17000000000000 -- task 7 body nudge x1.100
	{Id = "Portal",       Name = "Absolute Zero Portal", Cost = 784000000000000}, -- was 150T -- rebalance 2026-10-05: was 600000000000000 -- task 7 body nudge x1.120
	-- WORLD 2 (2026-10-02): Cost 0 = opens automatically with the previous stage (StageService.isOpen)
	{Id = "Sakura",       Name = "Sakura Garden",        Cost = 0, World = 2},
	-- 2026-10-03 (Claude): World 2 prices from the progression model (work/world2-balance, schedule C: model estimates, not playtests).
	{Id = "Candy",        Name = "Candy Kingdom",        Cost = 68400000000000000, World = 2}, -- was 300T -- rebalance 2026-10-05: was 37000000000000000 -- task 7 body nudge x1.140
	{Id = "Atlantis",     Name = "Sunken Atlantis",      Cost = 429000000000000000, World = 2}, -- was 10Qa -- rebalance 2026-10-05: was 230000000000000000 -- task 7 body nudge x1.159
	{Id = "Toybox",       Name = "Giant Toybox",         Cost = 1300000000000000000, World = 2}, -- was 60Qa -- rebalance 2026-10-05: was 670000000000000000 -- task 7 body nudge x1.182
	{Id = "Clockwork",    Name = "Clockwork City",       Cost = 6000000000000000000, World = 2}, -- was 360Qa -- rebalance 2026-10-05: was 3100000000000000000 -- task 7 body nudge x1.200
	{Id = "Cloud",        Name = "Cloud Kingdom",        Cost = 56100000000000000000, World = 2}, -- was 2.2Qi -- rebalance 2026-10-05: was 29000000000000000000 -- task 7 body nudge x1.220
	{Id = "Cosmic",       Name = "Cosmic Sanctuary",     Cost = 521000000000000000000, World = 2}, -- was 13Qi; final World 2 stage (Neon dropped 2026-10-03) -- rebalance 2026-10-05: was 260000000000000000000 -- task 7 body nudge x1.240
}
S.ById = {}
for i, s in ipairs(S.Order) do s.Index = i; S.ById[s.Id] = s end
function S.Previous(id)
	local s = S.ById[id]
	return s and S.Order[s.Index - 1] or nil
end
return S

