-- 2026-10-02 balance pass v2 (Claude): fast start, slower late game. With events/quests/daily/achievements World 1 takes ~4 h for an efficient engaged player, ~5 h casual (model). Older copies: ServerStorage.BalanceBackups
-- STAGES in unlock order. Cost is in snow. Each lock wall in Workspace has a "Stage" attribute = one of these Ids.
local S = {}
S.Order = {
	{Id = "Starter",      Name = "Starter",              Cost = 0},
	{Id = "Desert",       Name = "Desert",               Cost = 2500},
	{Id = "Cursed",       Name = "Cursed Biome",         Cost = 250000},
	{Id = "Crystal",      Name = "Crystal Caves",        Cost = 8000000}, -- 2026-10-03 (user: World 1 fast) was 54M,
	{Id = "Retro",        Name = "Retro World",          Cost = 250000000}, -- was 4B,
	{Id = "Jungle",       Name = "Jungle",               Cost = 8000000000}, -- was 135B,
	{Id = "AbsoluteZero", Name = "Absolute Zero",        Cost = 250000000000}, -- was 2.5T,
	{Id = "Portal",       Name = "Absolute Zero Portal", Cost = 150000000000000},
	-- WORLD 2 (2026-10-02): Cost 0 = opens automatically with the previous stage (StageService.isOpen)
	{Id = "Sakura",       Name = "Sakura Garden",        Cost = 0, World = 2},
	-- 2026-10-03 (Claude): World 2 prices from the progression model (work/world2-balance, schedule C: model estimates, not playtests).
	{Id = "Candy",        Name = "Candy Kingdom",        Cost = 300000000000000, World = 2},
	{Id = "Atlantis",     Name = "Sunken Atlantis",      Cost = 10000000000000000, World = 2},
	{Id = "Toybox",       Name = "Giant Toybox",         Cost = 60000000000000000, World = 2},
	{Id = "Clockwork",    Name = "Clockwork City",       Cost = 360000000000000000, World = 2},
	{Id = "Cloud",        Name = "Cloud Kingdom",        Cost = 2200000000000000000, World = 2},
	{Id = "Cosmic",       Name = "Cosmic Sanctuary",     Cost = 13000000000000000000, World = 2}, -- final World 2 stage (Neon dropped 2026-10-03)
}
S.ById = {}
for i, s in ipairs(S.Order) do s.Index = i; S.ById[s.Id] = s end
function S.Previous(id)
	local s = S.ById[id]
	return s and S.Order[s.Index - 1] or nil
end
return S

