-- NumberFormat: 950 -> "950", 1100 -> "1.1K", 2500000 -> "2.5M", ... up to trillions and beyond.
local NumberFormat = {}

-- edit these to change the letters (e.g. lowercase "k", "m")
NumberFormat.Suffixes = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}

function NumberFormat.Abbreviate(n)
	n = tonumber(n) or 0
	local sign = n < 0 and "-" or ""
	n = math.abs(n)
	if n < 1000 then return sign .. tostring(math.floor(n)) end

	local suffixes = NumberFormat.Suffixes
	local i = math.min(math.floor(math.log10(n) / 3), #suffixes)
	local v = math.floor(n / 10 ^ (i * 3) * 10) / 10 -- round DOWN to 1 decimal
	if v >= 1000 and i < #suffixes then            -- float edge cases like 999,999.99
		i += 1
		v = math.floor(n / 10 ^ (i * 3) * 10) / 10
	end
	local text = (v % 1 == 0) and string.format("%d", v) or string.format("%.1f", v)
	return sign .. text .. suffixes[i]
end

return NumberFormat
