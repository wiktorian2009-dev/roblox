-- WheelService (2026-10-03, Claude): the Lucky Wheel. Every newly unlocked stage gives 1 free spin.
-- The server picks and grants the prize; WheelClient only animates. Stage unlocks are read from StageService's Stage_<Id>
-- attributes, so no other script changed. Profile: d.Wheel = {Spins, Total, Granted = {["<StageId>@<rebirths>"] = true}}.
-- Wheel Snow goes onto the balance but NOT into SnowEarned, so it doesn't count as digging (quests, achievements, dig speed).
-- Slices and weights: ReplicatedStorage.WheelConfig.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local Boosts = require(script.Parent:WaitForChild("BoostService"))
local Stages = require(RS:WaitForChild("StageConfig"))
-- 2026-10-06 (Claude): rebirths removed; the grant key keeps the old "<StageId>@<rebirths>" format so saved grants still match
local A = require(RS:WaitForChild("ActivityConfig"))
local W = require(RS:WaitForChild("WheelConfig"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))

local fn = Instance.new("RemoteFunction")
fn.Name = "WheelRemote"
fn.Parent = RS
local rng = Random.new()

local function nice(x) -- 2 significant digits, like the Daily rewards
	x = math.max(1, x)
	if x < 100 then return math.floor(x + 0.5) end
	local e = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / e + 0.5) * e
end

local function wheelOf(d)
	local w = type(d.Wheel) == "table" and d.Wheel or {}
	w.Spins = math.max(0, math.floor(tonumber(w.Spins) or 0))
	w.Total = math.max(0, math.floor(tonumber(w.Total) or 0))
	if type(w.Granted) ~= "table" then w.Granted = {} end
	d.Wheel = w
	return w
end

local function snowFor(d, minutes) -- ActivityService keeps d.Activity.Rate = recent digging speed (Snow per second)
	local a = type(d.Activity) == "table" and d.Activity or {}
	return nice(math.max((W.MinSnowPerMinute or 50) * minutes, (tonumber(a.Rate) or 0) * 60 * minutes))
end

local function prizeInfo(d, s)
	if s.SnowMinutes then
		local amount = snowFor(d, s.SnowMinutes)
		local t = "+" .. NumberFormat.Abbreviate(amount)
		return {Kind = s.Jackpot and "Jackpot" or "Snow", Text = t, Sub = s.Jackpot and "JACKPOT!" or "SNOW", Long = t .. " Snow", Amount = amount}
	elseif s.Boost then
		local b = A.Boosts[s.Boost]
		local name = b and b.Name or s.Boost
		local mins = math.floor((s.Seconds or 0) / 60 + 0.5)
		return {Kind = s.Boost, Text = s.Boost == "Super" and "SUPER" or string.upper(name), Sub = mins .. " MIN", Long = name .. " for " .. mins .. " min"}
	end
	return {Kind = "?", Text = "?", Sub = "", Long = "?"}
end

local function prizes(d)
	local list = {}
	for i, s in ipairs(W.Segments) do list[i] = prizeInfo(d, s) end
	return list
end

local function publish(player, w) player:SetAttribute("WheelSpins", w.Spins) end

-- 1 spin for every stage you unlock. Free stages (Starter, Sakura) don't count.
local function check(player)
	local d = DataService.Get(player)
	if not d then return end
	local w = wheelOf(d)
	local rb = math.max(0, math.floor(tonumber(d.Rebirths) or 0))
	for _, s in ipairs(Stages.Order) do
		if (s.Cost or 0) > 0 and player:GetAttribute("Stage_" .. s.Id) == true then
			local key = s.Id .. "@" .. rb
			if not w.Granted[key] then
				w.Granted[key] = true
				w.Spins += 1
				w.Total += 1
			end
		end
	end
	publish(player, w)
end

DataService.OnLoaded(function(player)
	for _, s in ipairs(Stages.Order) do
		player:GetAttributeChangedSignal("Stage_" .. s.Id):Connect(function() check(player) end)
	end
	task.delay(1, check, player) -- stages already open (existing players get those spins once)
end)

local function pick()
	local total = 0
	for _, s in ipairs(W.Segments) do total += math.max(0, s.Weight or 1) end
	local r = rng:NextNumber() * total
	for i, s in ipairs(W.Segments) do
		r -= math.max(0, s.Weight or 1)
		if r <= 0 then return i end
	end
	return #W.Segments
end

local lastSpin = {}
Players.PlayerRemoving:Connect(function(p) lastSpin[p] = nil end)

fn.OnServerInvoke = function(player, action)
	local d = DataService.Get(player)
	if not d then return nil end
	local w = wheelOf(d)
	if action == "Get" then
		return {Ok = true, Spins = w.Spins, Prizes = prizes(d)}
	elseif action == "Spin" then
		local now = os.clock()
		if lastSpin[player] and now - lastSpin[player] < (W.SpinSeconds or 4) then
			return {Ok = false, Msg = "The wheel is still spinning!", Spins = w.Spins}
		end
		if w.Spins <= 0 then
			return {Ok = false, Msg = "No spins left - unlock a new stage to get one!", Spins = 0}
		end
		lastSpin[player] = now
		local i = pick()
		local s = W.Segments[i]
		local info = prizeInfo(d, s)
		w.Spins -= 1
		if s.SnowMinutes then
			d.Snow = (tonumber(d.Snow) or 0) + info.Amount
			DataService.SetStat(player, "Snow", d.Snow)
		elseif s.Boost then
			Boosts.Add(player, s.Boost, s.Seconds)
		end
		publish(player, w)
		return {Ok = true, Index = i, Prize = info, Spins = w.Spins, Prizes = prizes(d)}
	end
	return nil
end
