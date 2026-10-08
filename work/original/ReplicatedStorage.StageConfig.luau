-- STAGES in unlock order. Cost is in snow. Each lock wall in Workspace has a "Stage" attribute = one of these Ids.
local S = {}
S.Order = {
	{Id = "Starter",      Name = "Starter",              Cost = 0},
	{Id = "Desert",       Name = "Desert",               Cost = 250},
	{Id = "Cursed",       Name = "Cursed Biome",         Cost = 5000},
	{Id = "Crystal",      Name = "Crystal Caves",        Cost = 150000},
	{Id = "Retro",        Name = "Retro World",          Cost = 5000000},
	{Id = "Jungle",       Name = "Jungle",               Cost = 150000000},
	{Id = "AbsoluteZero", Name = "Absolute Zero",        Cost = 5000000000},
	{Id = "Portal",       Name = "Absolute Zero Portal", Cost = 250000000000},
}
S.ById = {}
for i, s in ipairs(S.Order) do s.Index = i; S.ById[s.Id] = s end
function S.Previous(id)
	local s = S.ById[id]
	return s and S.Order[s.Index - 1] or nil
end
return S

