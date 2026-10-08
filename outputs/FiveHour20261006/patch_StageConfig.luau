local s = game.ReplicatedStorage.StageConfig.Source
local n = 0
local function rep(k, new) local i = s:find(k, 1, true); assert(i, k:sub(1, 60)); local j = s:find('\n', i + 1, true) or (#s + 1)
	if k:find('\n') then j = i + #k end
	s = s:sub(1, i - 1) .. new .. s:sub(j); n += 1 end
local function after(k, new) local i = s:find(k .. '\n', 1, true); assert(i, k:sub(1, 60)); local j = i + #k
	s = s:sub(1, j - 1) .. '\n' .. new .. s:sub(j); n += 1 end
rep([==[	{Id = "Cursed",]==], [==[	{Id = "Cursed",       Name = "Cursed Biome",         Cost = 130000}, -- 2026-10-06 levels retune: x1.08, was 550K -- -- was 250K -- task 7 body nudge x1.020 -- rescale 2026-10-06: was 3.06M -- 5h 2026-10-06: was 594K]==])
rep([==[	{Id = "Crystal",]==], [==[	{Id = "Crystal",      Name = "Crystal Caves",        Cost = 7500000}, -- 2026-10-06 levels retune: x1.08, was 31M -- -- was 8M (2026-10-03: 54M) -- task 7 body nudge x1.036 -- rescale 2026-10-06: was 1.14B -- 5h 2026-10-06: was 33.5M]==])
rep([==[	{Id = "Retro",]==], [==[	{Id = "Retro",        Name = "Retro World",          Cost = 58000000}, -- 2026-10-06 levels retune: x1.08, was 780M -- -- was 250M -- rebalance 2026-10-05: was 260000000000 -- task 7 body nudge x1.061 -- rescale 2026-10-06: was 191B -- 5h 2026-10-06: was 842M]==])
rep([==[	{Id = "Jungle",]==], [==[	{Id = "Jungle",       Name = "Jungle",               Cost = 880000000}, -- 2026-10-06 levels retune: x1.08, was 4B -- -- was 8B -- rebalance 2026-10-05: was 1600000000000 -- task 7 body nudge x1.082 -- rescale 2026-10-06: was 2.38T -- 5h 2026-10-06: was 4.32B]==])
rep([==[	{Id = "AbsoluteZero",]==], [==[	{Id = "AbsoluteZero", Name = "Absolute Zero",        Cost = 4900000000}, -- 2026-10-06 levels retune: x1.08, was 14B -- -- was 250B -- rebalance 2026-10-05: was 17000000000000 -- task 7 body nudge x1.100 -- rescale 2026-10-06: was 24.2T -- 5h 2026-10-06: was 15.1B]==])
rep([==[	{Id = "Portal",]==], [==[	{Id = "Portal",       Name = "Absolute Zero Portal", Cost = 86000000000}, -- 2026-10-06 levels retune: x1.08, was 110B -- -- was 150T -- rebalance 2026-10-05: was 600000000000000 -- task 7 body nudge x1.120 -- rescale 2026-10-06: was 784T -- 5h 2026-10-06: was 119B]==])
rep([==[	{Id = "Candy",]==], [==[	{Id = "Candy",        Name = "Candy Kingdom",        Cost = 410000000000, World = 2}, -- was 300T -- rebalance 2026-10-05: was 37000000000000000 -- task 7 body nudge x1.140 -- rescale 2026-10-06: was 68400T -- 5h 2026-10-06: was 850B]==])
rep([==[	{Id = "Atlantis",]==], [==[	{Id = "Atlantis",     Name = "Sunken Atlantis",      Cost = 2400000000000, World = 2}, -- was 10Qa -- rebalance 2026-10-05: was 230000000000000000 -- task 7 body nudge x1.159 -- rescale 2026-10-06: was 429000T -- 5h 2026-10-06: was 2.7T]==])
rep([==[	{Id = "Toybox",]==], [==[	{Id = "Toybox",       Name = "Giant Toybox",         Cost = 6000000000000, World = 2}, -- was 60Qa -- rebalance 2026-10-05: was 670000000000000000 -- task 7 body nudge x1.182 -- rescale 2026-10-06: was 1.3e+06T -- 5h 2026-10-06: was 6.7T]==])
rep([==[	{Id = "Clockwork",]==], [==[	{Id = "Clockwork",    Name = "Clockwork City",       Cost = 8600000000000, World = 2}, -- was 360Qa -- rebalance 2026-10-05: was 3100000000000000000 -- task 7 body nudge x1.200 -- rescale 2026-10-06: was 6e+06T -- 5h 2026-10-06: was 17T]==])
rep([==[	{Id = "Cloud",]==], [==[	{Id = "Cloud",        Name = "Cloud Kingdom",        Cost = 16000000000000, World = 2}, -- was 2.2Qi -- rebalance 2026-10-05: was 29000000000000000000 -- task 7 body nudge x1.220 -- rescale 2026-10-06: was 5.61e+07T -- 5h 2026-10-06: was 51T]==])
rep([==[	{Id = "Cosmic",]==], [==[	{Id = "Cosmic",       Name = "Cosmic Sanctuary",     Cost = 96000000000000, World = 2}, -- was 13Qi; final World 2 stage (Neon dropped 2026-10-03) -- rebalance 2026-10-05: was 260000000000000000000 -- task 7 body nudge x1.240 -- rescale 2026-10-06: was 5.21e+08T -- 5h 2026-10-06: was 330T]==])
game.ReplicatedStorage.StageConfig.Source = s
return 'StageConfig ' .. n .. ' edits, ' .. #s .. ' bytes'
