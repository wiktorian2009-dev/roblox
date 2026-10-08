-- MiniPlowService (2026-10-06, Claude; wiktor: "add automatic collection upgrade like mini version of ur cars driving in ur best field").
-- The server owns the MINI PLOWS upgrade: buying levels (MiniPlowRemote "Buy", explicit Snow prices from PlowConfig.Minis) and the payout.
-- Payout: once per C.Minis.Tick while the player is in the game with a loaded profile and the tutorial done:
--   Count x Share x C.MiniBase(equipped build, best unlocked field) -> pets and SnowMult exactly like the AFK payout (no drift, no combo)
--   -> DataService.AddSnow. Fractions carry over between ticks. Nothing is paid offline; leaving clears the state.
-- Public attributes for the client: MiniLevel, MiniCount, MiniField (field id), MiniBuild (part ids), MiniRate (Snow/s now).
-- Profile: d.MiniPlows = {Level = n} (v1).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))
local C = require(RS:WaitForChild("PlowConfig"))
local SF = require(RS:WaitForChild("SnowFields"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local M = C.Minis

local remote = RS:FindFirstChild("MiniPlowRemote") or Instance.new("RemoteFunction")
remote.Name = "MiniPlowRemote"; remote.Parent = RS

local acc, cache, lastAsk = {}, {}, {}

local function profile(player)
	local d = DataService.Get(player)
	if not d then return nil end
	if type(d.MiniPlows) ~= "table" then d.MiniPlows = {} end
	local mp = d.MiniPlows
	mp.Level = math.clamp(math.floor(tonumber(mp.Level) or 0), 0, #M.Levels)
	mp.V = 1
	return d, mp
end

-- the saved, equipped build with part levels and the upgrade modifiers (the same stats the plow drives with)
local function buildOf(d)
	local p = type(d.Plow) == "table" and d.Plow or {}
	local saved = type(p.Build) == "table" and p.Build or {}
	local owned = type(p.Parts) == "table" and p.Parts or {}
	local build = {}
	for slot, starter in pairs(C.Starter) do
		local id = saved[slot]
		local def = C.Parts[id or ""]
		build[slot] = (def and def.Slot == slot and (id == starter or (tonumber(owned[id]) or 0) > 0)) and id or starter
	end
	return build, type(p.Levels) == "table" and p.Levels or nil
end
local function statsOf(player, d)
	local build, levels = buildOf(d)
	local ws = 16
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then ws = hum.WalkSpeed end
	return C.StatsFor(build, {
		PowerMult = player:GetAttribute("PowerMult") or 1, PowerBonus = player:GetAttribute("PowerBonus") or 0,
		SizeMult = player:GetAttribute("SizeMult") or 1, ReachMult = player:GetAttribute("ReachMult") or 1,
		SpinMult = player:GetAttribute("SpinMult") or 1, SpeedMult = 1 + math.clamp(ws / 16 - 1, 0, 1) * 0.5, Levels = levels,
	}), build
end

-- best unlocked field for this build (highest one-mini Snow/s; a stage's biggest field is where the minis drive)
local function bestField(player, stats)
	local best, bestF, area = 0, nil, 0
	for _, f in ipairs(SF.Fields) do
		local st = f.Style or "Starter"
		if st == "Starter" or player:GetAttribute("Stage_" .. st) == true then
			local v = C.MiniBase(stats, st, f.TileHP, f.SnowPerPhase)
			local a = f.Width * f.Depth
			if v > best * 1.0001 or (bestF and math.abs(v - best) <= best * 1e-4 and a > area) then best, bestF, area = v, f, a end
		end
	end
	return best, bestF
end

local function multipliers(player)
	local pets = {}
	for n in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(pets, n) end
	return (1 + (PetConfig.Multiplier(pets, player) - 1) * (player:GetAttribute("PetBoostMult") or 1)) * (player:GetAttribute("SnowMult") or 1)
end

local function refresh(player)
	local d, mp = profile(player)
	if not d then return nil end
	local lv = C.MiniLevel(mp.Level)
	local c = {level = mp.Level, count = lv and math.min(lv.Count, 5) or 0, share = lv and lv.Share or 0, t = os.clock()}
	if c.count > 0 then
		local stats, build = statsOf(player, d)
		local base, f = bestField(player, stats)
		c.base, c.field = base, f
		c.build = (build.Blade or "") .. "," .. (build.Engine or "") .. "," .. (build.Gear or "") .. "," .. (build.Body or "")
	end
	cache[player] = c
	player:SetAttribute("MiniLevel", c.level)
	player:SetAttribute("MiniCount", c.count > 0 and c.count or nil)
	player:SetAttribute("MiniField", c.field and c.field.Id or nil)
	player:SetAttribute("MiniBuild", c.build)
	player:SetAttribute("MiniRate", c.count > 0 and (c.base or 0) * c.count * c.share * multipliers(player) or nil)
	return c
end

remote.OnServerInvoke = function(player, action)
	if action ~= "Buy" then return false, "Unknown" end
	local now = os.clock()
	if (lastAsk[player] or 0) > now - 0.35 then return false, "Slow down" end
	lastAsk[player] = now
	local d, mp = profile(player)
	if not d then return false, "Your save is still loading." end
	local nxt = M.Levels[mp.Level + 1]
	if not nxt then return false, "Mini plows are maxed!" end
	local cost = nxt.Cost
	if (tonumber(d.Snow) or 0) < cost then return false, "Not enough Snow" end
	DataService.AddSnow(player, -cost)
	mp.Level += 1
	acc[player] = acc[player] or 0
	refresh(player)
	return true, mp.Level
end

DataService.OnLoaded(function(player) refresh(player) end)
Players.PlayerRemoving:Connect(function(p) acc[p], cache[p], lastAsk[p] = nil, nil, nil end)

-- payout loop (only players in this server; nothing accrues while away)
task.spawn(function()
	while true do
		task.wait(M.Tick)
		for _, p in ipairs(Players:GetPlayers()) do
			local c = cache[p]
			if not c or os.clock() - c.t > M.RateRefresh then c = refresh(p) end
			if c and c.count > 0 and (c.base or 0) > 0 and p:GetAttribute("PlowTutorialDone") == true and p:GetAttribute("IntroActive") ~= true then
				local gain = c.base * c.count * c.share * M.Tick * multipliers(p) + (acc[p] or 0)
				local whole = math.floor(gain)
				acc[p] = gain - whole
				if whole >= 1 then DataService.AddSnow(p, whole) end
			end
		end
	end
end)
