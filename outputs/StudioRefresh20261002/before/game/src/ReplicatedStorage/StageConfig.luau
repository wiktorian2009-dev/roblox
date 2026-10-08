-- STAGES in unlock order. Cost is in snow. Each lock wall in Workspace has a "Stage" attribute = one of these Ids.
local S = {}
S.Order = {
	{Id = "Starter",      Name = "Starter",              Cost = 0},
	{Id = "Desert",       Name = "Desert",               Cost = 20000},
	{Id = "Cursed",       Name = "Cursed Biome",         Cost = 2000000},
	{Id = "Crystal",      Name = "Crystal Caves",        Cost = 75000000},
	{Id = "Retro",        Name = "Retro World",          Cost = 3000000000},
	{Id = "Jungle",       Name = "Jungle",               Cost = 75000000000},
	{Id = "AbsoluteZero", Name = "Absolute Zero",        Cost = 1000000000000},
	{Id = "Portal",       Name = "Absolute Zero Portal", Cost = 12000000000000},
}
S.ById = {}
for i, s in ipairs(S.Order) do s.Index = i; S.ById[s.Id] = s end
function S.Previous(id)
	local s = S.ById[id]
	return s and S.Order[s.Index - 1] or nil
end
return S

