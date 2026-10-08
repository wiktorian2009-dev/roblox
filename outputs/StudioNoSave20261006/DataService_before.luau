-- DataService: one place that loads/saves each player's data.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local RebirthConfig = require(game.ReplicatedStorage:WaitForChild("RebirthConfig"))
local PlowRules = require(script.Parent:WaitForChild("PlowRules")) -- 2026-10-04: snowplow parts / build / offers
local EconomyMigration = require(script.Parent:WaitForChild("EconomyMigration")) -- 2026-10-06: old-scale profiles -> rescaled economy (once)
local PlowConfig = require(game.ReplicatedStorage:WaitForChild("PlowConfig"))
local DataService = {}
local data = {}
local loaded = Instance.new("BindableEvent")

-- Studio-only clean balance sessions neither load nor save real progress.
-- Set ServerStorage's BalanceTestMode attribute before pressing Play to opt in.
local testMode = game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("BalanceTestMode") == true
local store
if not testMode then pcall(function() store = DataStoreService:GetDataStore("RNGData_v1") end) end
-- 2026-10-06 (Claude): isolated tests can swap in an in-memory fake store (ServerStorage attribute DataLoadTest) to simulate load
-- failures. It never touches the real DataStore and only exists in BalanceTestMode sessions.
local fake
if testMode and game:GetService("ServerStorage"):GetAttribute("DataLoadTest") == true then
	fake = {data = {}, fail = 0, permanent = false, gets = 0, writes = {}, kicks = {}}
	store = {
		GetAsync = function(_, key)
			fake.gets += 1
			if fake.permanent or fake.fail > 0 then fake.fail -= 1; error("simulated GetAsync failure") end
			return fake.data[key]
		end,
		SetAsync = function(_, key, value) table.insert(fake.writes, key); fake.data[key] = value end,
	}
end
local LOAD_TRIES = 4
local function kick(player, msg)
	if fake then table.insert(fake.kicks, player.UserId .. ": " .. msg); return end
	player:Kick(msg)
end

local function defaults(d)
	d.Rebirths = RebirthConfig.Count(d.Rebirths)
	-- Historical shovel ownership/equipment remain stored for recovery; current gameplay uses d.Plow.
	d.Counts = type(d.Counts) == "table" and d.Counts or {}
	d.TotalRolls = tonumber(d.TotalRolls) or 0
	d.Snow = tonumber(d.Snow) or 0
	d.Stages = type(d.Stages) == "table" and d.Stages or {}
	d.Upgrades = type(d.Upgrades) == "table" and d.Upgrades or {}
	d.Settings = type(d.Settings) == "table" and d.Settings or {}
	d.Luck = tonumber(d.Luck) or 1 -- roll luck multiplier (luck upgrades raise this)
	if type(d.Equipped) == "string" then d.Equipped = {d.Equipped} end
	if type(d.Equipped) ~= "table" then d.Equipped = {} end
	PlowRules.Apply(d)
	EconomyMigration.Apply(d, PlowConfig) -- versioned + idempotent (no-op for current-scale profiles)
	d.Pets = type(d.Pets) == "table" and d.Pets or {}
	d.EquippedPets = type(d.EquippedPets) == "table" and d.EquippedPets or {}
	d.PetIndex = type(d.PetIndex) == "table" and d.PetIndex or {}
	for name, n in pairs(d.Pets) do if n > 0 then d.PetIndex[name] = true end end
	return d
end

local function stat(ls, name, value)
	-- 2026-10-03 (Claude): Snow uses a NumberValue - World 2 balances pass IntValue's ~9.2e18 limit (Cosmic costs 1.3e19), which showed 0 on the HUD
	local v = Instance.new(name == "Snow" and "NumberValue" or "IntValue")
	v.Name = name
	v.Value = value
	v.Parent = ls
end

local loadOk = {} -- 2026-10-06: true when the profile really came from the store (or is genuinely new) - paid grants require it
local function load(player)
	if data[player] then return end
	local saved
	if store then
		-- 2026-10-06 (Claude): retry with backoff; if the save still can't be read, never start (or save) a blank profile over the real one:
		-- no profile is created (so nothing is saved and nothing can be bought) and the player is asked to rejoin.
		-- No stored data at all (nil) is a genuinely new player and starts fresh as before.
		local ok, res
		for attempt = 1, LOAD_TRIES do
			ok, res = pcall(function() return store:GetAsync("u" .. player.UserId) end)
			if ok and (res == nil or type(res) == "table") then break end
			if ok then ok = false; res = "stored data is not a table" end -- unreadable: treat as a failed load, never overwrite it
			if not player.Parent then return end
			if attempt < LOAD_TRIES then task.wait(fake and 0.05 or attempt * 2) end
		end
		if not ok then
			loadOk[player] = false
			warn("[DataService] Couldn't load " .. player.UserId .. " after " .. LOAD_TRIES .. " tries: " .. tostring(res) .. " - not loaded, nothing will be saved")
			player:SetAttribute("DataLoadFailed", true)
			kick(player, "Couldn't load your save - please rejoin. Your progress is safe.")
			return
		end
		if type(res) == "table" then saved = res end
		loadOk[player] = true
	else
		loadOk[player] = testMode
	end
	if not player.Parent then return end
	local fresh = saved or {EconomyVersion = EconomyMigration.VERSION} -- a brand-new profile is already on the current scale
	local d = defaults(fresh)
	data[player] = d
	player:SetAttribute("BalanceTestSession", testMode)
	player:SetAttribute("IntroActive", false)
	player:SetAttribute("IntroReady", true)
	player:SetAttribute("IntroPlaying", false)
	player:SetAttribute("PlowTutorialDone", d.Plow.TutorialDone == true)

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	stat(ls, "Snow", d.Snow)
	stat(ls, "Rolls", d.TotalRolls + (d.Plow.Rolls or 0))
	stat(ls, "Rebirths", d.Rebirths)
	ls.Parent = player

	loaded:Fire(player, d)
end

-- Serialize autosave, rebirth, and leave saves so an older write cannot finish last.
local saving, saveAgain, lastOk = {}, {}, {}
local function save(player)
 if not store or not data[player] then return false end
 if saving[player] then
  saveAgain[player] = true
  repeat task.wait() until not saving[player]
  return lastOk[player] == true -- the in-flight save ran again with the latest data
 end
 saving[player] = true
 repeat
  saveAgain[player] = nil
  local snapshot = game.HttpService:JSONDecode(game.HttpService:JSONEncode(data[player]))
  local ok, err
  for attempt = 1, 3 do
   ok, err = pcall(function() store:SetAsync("u" .. player.UserId, snapshot) end)
   if ok then break end
   if attempt < 3 then task.wait(attempt) end
  end
  if not ok then warn("[DataService] Save failed: " .. tostring(err)) end
  lastOk[player] = ok
 until not saveAgain[player]
 saving[player] = nil
 return lastOk[player] == true
end
function DataService.Save(player) save(player) end
-- 2026-10-06 (Claude, developer-product receipts): write now and report whether it reached the DataStore.
-- Isolated Studio tests (BalanceTestMode) have no store and count as saved.
function DataService.SaveNow(player)
	if not data[player] then return false end
	if not store then return testMode end
	return save(player)
end
function DataService.LoadedFromStore(player) return loadOk[player] == true end

-- isolated load-failure tests only (DataLoadTest): configure the fake store, reload a player, read what was written
if fake then
	local hook = Instance.new("BindableFunction"); hook.Name = "DataLoadTestHook"
	hook.OnInvoke = function(op, player, a)
		if op == "Fail" then fake.fail = tonumber(a) or 0; fake.permanent = false; return true
		elseif op == "Permanent" then fake.permanent = a == true; return true
		elseif op == "Seed" then fake.data["u" .. player.UserId] = a; return true -- a = stored profile table (or nil = new player)
		elseif op == "Reload" then -- drop the in-memory profile WITHOUT saving it, then run the normal join load again
			data[player] = nil; loadOk[player] = nil
			local ls = player:FindFirstChild("leaderstats"); if ls then ls:Destroy() end
			player:SetAttribute("DataLoadFailed", nil)
			fake.gets = 0
			load(player)
			local d = data[player]
			return {loaded = d ~= nil, fromStore = loadOk[player], snow = d and d.Snow, gets = fake.gets, failed = player:GetAttribute("DataLoadFailed")}
		elseif op == "TrySave" then return save(player)
		elseif op == "Log" then return {writes = table.clone(fake.writes), kicks = table.clone(fake.kicks), stored = fake.data["u" .. player.UserId] ~= nil}
		end
	end
	hook.Parent = game:GetService("ServerStorage")
end

function DataService.Get(player)
	return data[player]
end

-- run callback for every player whose data is loaded (now and in the future)
function DataService.OnLoaded(callback)
	for p, d in pairs(data) do task.spawn(callback, p, d) end
	return loaded.Event:Connect(callback)
end

function DataService.SetStat(player, name, value)
	local ls = player:FindFirstChild("leaderstats")
	local v = ls and ls:FindFirstChild(name)
	if v then v.Value = value end
end

function DataService.AddSnow(player, amount)
	local d = data[player]
	if not d then return end
	d.Snow += amount
	if amount > 0 then d.SnowEarned = (tonumber(d.SnowEarned) or 0) + amount end -- lifetime snow for quests/achievements (2026-10-02)
	DataService.SetStat(player, "Snow", d.Snow)
end

Players.PlayerAdded:Connect(load)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(load, p) end
Players.PlayerRemoving:Connect(function(player)
	save(player)
	data[player] = nil
	loadOk[player], lastOk[player] = nil, nil
end)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do save(p) end
end)
task.spawn(function() -- autosave
	while true do
		task.wait(120)
		for _, p in ipairs(Players:GetPlayers()) do task.spawn(save, p) end
	end
end)

return DataService



