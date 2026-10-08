local s = game.ReplicatedStorage.ActivityConfig.Source
local n = 0
local function rep(k, new) local i = s:find(k, 1, true); assert(i, k:sub(1, 60)); local j = s:find('\n', i + 1, true) or (#s + 1)
	if k:find('\n') then j = i + #k end
	s = s:sub(1, i - 1) .. new .. s:sub(j); n += 1 end
local function after(k, new) local i = s:find(k .. '\n', 1, true); assert(i, k:sub(1, 60)); local j = i + #k
	s = s:sub(1, j - 1) .. '\n' .. new .. s:sub(j); n += 1 end
rep([==[	{Id = "Snow2",]==], [==[	{Id = "Snow2", Name = "Snow Hoarder", Text = "Dig 7M snow", Stat = "SnowEarned", Goal = 7000000, Snow = 0.03},]==])
game.ReplicatedStorage.ActivityConfig.Source = s
return 'ActivityConfig ' .. n .. ' edits, ' .. #s .. ' bytes'
