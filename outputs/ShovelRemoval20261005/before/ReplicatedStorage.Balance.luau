-- BALANCE: core scaling formulas (tweak exponents to make progression faster/slower).
local Balance = {}

-- shovel damage per hit, from its odds (1 in N). Set Power on a shovel in RNGConfig to override.
--   1 in 2 -> 1   | 1 in 1K -> 77 | 1 in 1M -> 6K | 1 in 1B -> 467K | 1 in 100B -> 8.5M
-- 2026-10-01: raised 0.42 -> 0.63 when shovel luck was removed, so shovel power over play time stays close to before.
Balance.PowerExponent = 0.63
function Balance.ShovelPower(chance)
	return math.max(1, math.floor(chance ^ Balance.PowerExponent))
end

-- Shovels no longer give luck (2026-10-01): luck comes from upgrade tiles (+%), rebirths and friends.
-- Kept as a neutral x1 so any older caller still works.
function Balance.ShovelLuck(_chance)
	return 1
end

return Balance

