local s = game.ReplicatedStorage.PetConfig.Source
local n = 0
local function rep(k, new) local i = s:find(k, 1, true); assert(i, k:sub(1, 60)); local j = s:find('\n', i + 1, true) or (#s + 1)
	if k:find('\n') then j = i + #k end
	s = s:sub(1, i - 1) .. new .. s:sub(j); n += 1 end
local function after(k, new) local i = s:find(k .. '\n', 1, true); assert(i, k:sub(1, 60)); local j = i + #k
	s = s:sub(1, j - 1) .. '\n' .. new .. s:sub(j); n += 1 end
rep([==[	{Id = "CrystalEgg",]==], [==[	{Id = "CrystalEgg", Name = "Crystal Egg", Cost = 5500000, RequiredStage = "Crystal", Pets = {]==])
rep([==[	{Id = "CursedEgg",]==], [==[	{Id = "CursedEgg", Name = "Cursed Egg", Cost = 20000, RequiredStage = "Cursed", Pets = {]==])
rep([==[	{Id = "RetroEgg",]==], [==[	{Id = "RetroEgg", Name = "Retro Egg", Cost = 94000000, RequiredStage = "Retro", Pets = { -- rebalance 2026-10-05: was 420000000000]==])
rep([==[	{Id = "JungleEgg",]==], [==[	{Id = "JungleEgg", Name = "Jungle Egg", Cost = 1500000000, RequiredStage = "Jungle", Pets = { -- rebalance 2026-10-05: was 2800000000000]==])
rep([==[	{Id = "AbsoluteZeroEgg",]==], [==[	{Id = "AbsoluteZeroEgg", Name = "Absolute Zero Egg", Cost = 5800000000, RequiredStage = "AbsoluteZero", Pets = { -- rebalance 2026-10-05: was 20000000000000]==])
rep([==[	{Id = "BlossomEgg",]==], [==[	{Id = "BlossomEgg", Name = "Blossom Egg", Cost = 8600000000, RequiredStage = "Sakura", Pets = { -- rebalance 2026-10-05: was 60000000000000]==])
rep([==[	{Id = "CandyEgg",]==], [==[	{Id = "CandyEgg", Name = "Candy Egg", Cost = 41000000000, RequiredStage = "Candy", Pets = { -- rebalance 2026-10-05: was 3700000000000000]==])
rep([==[	{Id = "PearlEgg",]==], [==[	{Id = "PearlEgg", Name = "Pearl Egg", Cost = 240000000000, RequiredStage = "Atlantis", Pets = { -- rebalance 2026-10-05: was 23000000000000000]==])
rep([==[	{Id = "ToyCapsuleEgg",]==], [==[	{Id = "ToyCapsuleEgg", Name = "Toy Capsule Egg", Cost = 600000000000, RequiredStage = "Toybox", Pets = { -- rebalance 2026-10-05: was 67000000000000000]==])
rep([==[	{Id = "GearEgg",]==], [==[	{Id = "GearEgg", Name = "Gear Egg", Cost = 860000000000, RequiredStage = "Clockwork", Pets = { -- rebalance 2026-10-05: was 310000000000000000]==])
rep([==[	{Id = "CloudEgg",]==], [==[	{Id = "CloudEgg", Name = "Cloud Egg", Cost = 1600000000000, RequiredStage = "Cloud", Pets = { -- rebalance 2026-10-05: was 2900000000000000000]==])
rep([==[	{Id = "StarEgg",]==], [==[	{Id = "StarEgg", Name = "Star Egg", Cost = 9600000000000, RequiredStage = "Cosmic", Pets = { -- rebalance 2026-10-05: was 26000000000000000000]==])
game.ReplicatedStorage.PetConfig.Source = s
return 'PetConfig ' .. n .. ' edits, ' .. #s .. ' bytes'
