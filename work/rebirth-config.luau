-- Permanent, additive bonuses keep repeat runs faster without exponential runaway.
local R = {}
R.MaxRebirths = 50
R.SnowPerRebirth = 0.50
R.LuckPerRebirth = 0.25
R.Milestones = {
 {Stage = "Cursed", Cost = 500000},
 {Stage = "Crystal", Cost = 25000000},
 {Stage = "Retro", Cost = 1000000000},
 {Stage = "Jungle", Cost = 25000000000},
 {Stage = "AbsoluteZero", Cost = 350000000000},
 {Stage = "Portal", Cost = 4000000000000},
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
