-- BALANCE: core scaling formulas (tweak exponents to make progression faster/slower).
local Balance = {}

-- shovel damage per hit, from its odds (1 in N). Set Power on a shovel in RNGConfig to override.
--   1 in 2 -> 1   | 1 in 1K -> 18 | 1 in 1M -> 330 | 1 in 1B -> 6K | 1 in 100B -> 40K
Balance.PowerExponent = 0.42
function Balance.ShovelPower(chance)
	return math.max(1, math.floor(chance ^ Balance.PowerExponent))
end

-- luck each EQUIPPED shovel gives (added up, then multiplied with every other luck source)
-- Diminishing shovel luck reduces the runaway rare-shovel -> more-luck feedback loop.
Balance.LuckExponent = 0.33
function Balance.ShovelLuck(chance)
	return chance ^ Balance.LuckExponent
end

return Balance

