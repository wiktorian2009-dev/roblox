-- 2026-10-02 balance pass v2 (Claude): fast start, slower late game. With events/quests/daily/achievements World 1 takes ~4 h for an efficient engaged player, ~5 h casual (model). Older copies: ServerStorage.BalanceBackups
-- 2026-10-05 (Claude, snowplow expansion): stage gates re-measured for the 90-part snowplow economy (outputs/PlowExpansion20261005/sim:
-- efficient engaged player ~3.6 h World 1, ~4.6 h World 2; model estimates, not playtests). Previous values: ServerStorage.PlowExpansionBackup_20261005.
-- STAGES in unlock order. Cost is in snow. Each lock wall in Workspace has a "Stage" attribute = one of these Ids.
-- RESCALE 2026-10-06 (Claude): one gentle curve, nothing above the trillions (outputs/Rebalance20261005/sim: compress.py +
-- tune_gates.py -> rescale_final.json -> emit_rescale.py). Old profiles are converted once by ServerScriptService.EconomyMigration.
local S = {}
S.Order = {
	{Id = "Starter",      Name = "Starter",              Cost = 0},
	{Id = "Desert",       Name = "Desert",               Cost = 5000}, -- was 2.5K -- rescale 2026-10-06: was 5K
	{Id = "Cursed",       Name = "Cursed Biome",         Cost = 550000}, -- was 250K -- task 7 body nudge x1.020 -- rescale 2026-10-06: was 3.06M
	{Id = "Crystal",      Name = "Crystal Caves",        Cost = 31000000}, -- was 8M (2026-10-03: 54M) -- task 7 body nudge x1.036 -- rescale 2026-10-06: was 1.14B
	{Id = "Retro",        Name = "Retro World",          Cost = 780000000}, -- was 250M -- rebalance 2026-10-05: was 260000000000 -- task 7 body nudge x1.061 -- rescale 2026-10-06: was 191B
	{Id = "Jungle",       Name = "Jungle",               Cost = 4000000000}, -- was 8B -- rebalance 2026-10-05: was 1600000000000 -- task 7 body nudge x1.082 -- rescale 2026-10-06: was 2.38T
	{Id = "AbsoluteZero", Name = "Absolute Zero",        Cost = 14000000000}, -- was 250B -- rebalance 2026-10-05: was 17000000000000 -- task 7 body nudge x1.100 -- rescale 2026-10-06: was 24.2T
	{Id = "Portal",       Name = "Absolute Zero Portal", Cost = 110000000000}, -- was 150T -- rebalance 2026-10-05: was 600000000000000 -- task 7 body nudge x1.120 -- rescale 2026-10-06: was 784T
	-- WORLD 2 (2026-10-02): Cost 0 = opens automatically with the previous stage (StageService.isOpen)
	{Id = "Sakura",       Name = "Sakura Garden",        Cost = 0, World = 2},
	-- 2026-10-03 (Claude): World 2 prices from the progression model (work/world2-balance, schedule C: model estimates, not playtests).
	{Id = "Candy",        Name = "Candy Kingdom",        Cost = 850000000000, World = 2}, -- was 300T -- rebalance 2026-10-05: was 37000000000000000 -- task 7 body nudge x1.140 -- rescale 2026-10-06: was 68400T
	{Id = "Atlantis",     Name = "Sunken Atlantis",      Cost = 2700000000000, World = 2}, -- was 10Qa -- rebalance 2026-10-05: was 230000000000000000 -- task 7 body nudge x1.159 -- rescale 2026-10-06: was 429000T
	{Id = "Toybox",       Name = "Giant Toybox",         Cost = 6700000000000, World = 2}, -- was 60Qa -- rebalance 2026-10-05: was 670000000000000000 -- task 7 body nudge x1.182 -- rescale 2026-10-06: was 1.3e+06T
	{Id = "Clockwork",    Name = "Clockwork City",       Cost = 17000000000000, World = 2}, -- was 360Qa -- rebalance 2026-10-05: was 3100000000000000000 -- task 7 body nudge x1.200 -- rescale 2026-10-06: was 6e+06T
	{Id = "Cloud",        Name = "Cloud Kingdom",        Cost = 51000000000000, World = 2}, -- was 2.2Qi -- rebalance 2026-10-05: was 29000000000000000000 -- task 7 body nudge x1.220 -- rescale 2026-10-06: was 5.61e+07T
	{Id = "Cosmic",       Name = "Cosmic Sanctuary",     Cost = 330000000000000, World = 2}, -- was 13Qi; final World 2 stage (Neon dropped 2026-10-03) -- rebalance 2026-10-05: was 260000000000000000000 -- task 7 body nudge x1.240 -- rescale 2026-10-06: was 5.21e+08T
}
S.ById = {}
for i, s in ipairs(S.Order) do s.Index = i; S.ById[s.Id] = s end
function S.Previous(id)
	local s = S.ById[id]
	return s and S.Order[s.Index - 1] or nil
end
return S

