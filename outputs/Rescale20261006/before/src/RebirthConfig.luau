-- 2026-10-02 balance pass v2 (Claude): fast start, slower late game. With events/quests/daily/achievements World 1 takes ~4 h for an efficient engaged player, ~5 h casual (model). Older copies: ServerStorage.BalanceBackups
-- Permanent, additive bonuses keep repeat runs faster without exponential runaway.
local R = {}
R.MaxRebirths = 50
R.SnowPerRebirth = 0.50
R.LuckPerRebirth = 0.25
-- 2026-10-05 (Claude, snowplow expansion): milestone costs follow the re-measured stage costs (same ratio to their stage as before).
R.Milestones = {
 {Stage = "Cursed", Cost = 720000},
 {Stage = "Crystal", Cost = 2500000000},
 {Stage = "Retro", Cost = 1350000000000},
 {Stage = "Jungle", Cost = 9000000000000},
 {Stage = "AbsoluteZero", Cost = 60000000000000},
 {Stage = "Portal", Cost = 200000000000000},
}
function R.Count(value)
 if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return 0 end
 return math.clamp(math.floor(value), 0, R.MaxRebirths)
end
function R.Multipliers(count)
 count = R.Count(count)
 return 1 + count * R.SnowPerRebirth, 1 + count * R.LuckPerRebirth
end
function R.Requirement(count)
 count = R.Count(count)
 if count >= R.MaxRebirths then return nil end
 local level = count + 1
 local tier = R.Milestones[math.min(level, #R.Milestones)]
 local repeats = math.max(1, level - #R.Milestones + 1)
 return {Level = level, Stage = tier.Stage, Cost = tier.Cost * repeats * repeats}
end
return R
