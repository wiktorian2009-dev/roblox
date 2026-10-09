-- LeaderboardService (2026-10-09, Claude): global leaderboards for Snow cleared, Arena KOs and Playtime (LeaderboardConfig).
-- * Scores come only from the server-side profile (DataService); clients never send a score.
-- * Playtime: d.PlayTime (seconds) is counted here every L.Tick while the profile is loaded (new field, starts at 0).
-- * Writes: each player's changed scores every L.WriteEvery, on leave and on shutdown. Lifetime stats only grow, so a write
--   keeps the larger of the stored and the new value (a server with an older profile can't lower a score).
-- * Only profiles really loaded from the DataStore are published (DataService.LoadedFromStore): a temporary or failed
--   profile never posts a 0 or a test number.
-- * Studio never writes to the live stores (it only reads them, when API access is on). Isolated Studio tests
--   (ServerStorage.BalanceTestMode) use in-memory stores instead; ServerStorage.LeaderboardTestHook (bottom) drives them.
-- * Clients read ReplicatedStorage.LeaderboardData (one JSON StringValue per board, NextRefresh attribute) and the
--   player attributes LB_<Id> (own score); StarterPlayerScripts.LeaderboardClient draws workspace.Leaderboards.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local UserService = game:GetService("UserService")

local DataService = require(script.Parent:WaitForChild("DataService"))
local L = require(RS:WaitForChild("LeaderboardConfig"))

local IS_STUDIO = RunService:IsStudio()
local TEST = IS_STUDIO and SS:GetAttribute("BalanceTestMode") == true
local CAN_WRITE = TEST or not IS_STUDIO
local now = function() return workspace:GetServerTimeNow() end

--------------------------------------------------
-- stores (live OrderedDataStores, or in-memory ones in isolated Studio tests)
--------------------------------------------------
local function memoryStore()
	local s = {data = {}}
	function s:UpdateAsync(key, fn)
		local new = fn(self.data[key])
		if new ~= nil then self.data[key] = new end
		return new
	end
	function s:GetSortedAsync(ascending, size)
		local list = {}
		for k, v in pairs(self.data) do table.insert(list, {key = k, value = v}) end
		table.sort(list, function(a, b)
			if a.value == b.value then return a.key < b.key end
			if ascending then return a.value < b.value end
			return a.value > b.value
		end)
		local page = {}
		for i = 1, math.min(size, #list) do page[i] = list[i] end
		return {GetCurrentPage = function() return page end}
	end
	return s
end

local stores, storeError = {}, nil
for _, b in ipairs(L.Boards) do
	if TEST then
		stores[b.Id] = memoryStore()
	else
		local ok, res = pcall(function() return DataStoreService:GetOrderedDataStore(b.Store) end)
		if ok then stores[b.Id] = res else storeError = tostring(res) end
	end
end

local function budget(...)
	if TEST then return 100 end
	local least = math.huge
	for _, kind in ipairs({...}) do
		local ok, n = pcall(function() return DataStoreService:GetRequestBudgetForRequestType(kind) end)
		least = math.min(least, ok and n or 0)
	end
	return least
end

--------------------------------------------------
-- scores from the profile
--------------------------------------------------
local function scores(d)
	local arena = type(d.Arena) == "table" and d.Arena or nil
	return {
		Snow = tonumber(d.SnowEarned) or 0,
		ArenaKOs = arena and tonumber(arena.KOs) or 0,
		Playtime = tonumber(d.PlayTime) or 0,
	}
end

-- playtime: counted on the server while the profile is loaded
local lastCount = {}
local function countPlaytime(player)
	local d = DataService.Get(player)
	local t = os.clock()
	if not d then lastCount[player] = nil; return end
	local last = lastCount[player]
	lastCount[player] = t
	if last then d.PlayTime = (tonumber(d.PlayTime) or 0) + math.clamp(t - last, 0, 3 * L.Tick) end
end

-- own scores for the board footer ("YOU")
local function showOwn(player, s)
	for id, v in pairs(s) do
		local shown = id == "Playtime" and math.floor(v) or v
		if player:GetAttribute("LB_" .. id) ~= shown then player:SetAttribute("LB_" .. id, shown) end
	end
end

--------------------------------------------------
-- writes
--------------------------------------------------
local written = {} -- [userId] = {[boardId] = last written key}
local function canPublish(player)
	if not CAN_WRITE then return false end
	if TEST then return DataService.Get(player) ~= nil end
	return DataService.LoadedFromStore(player)
end

local function publish(userId, s)
	local w = written[userId] or {}
	written[userId] = w
	for _, b in ipairs(L.Boards) do
		local store, key = stores[b.Id], L.Encode(b, s[b.Id])
		if store and key and key >= 1 and w[b.Id] ~= key then
			if budget(Enum.DataStoreRequestType.UpdateAsync, Enum.DataStoreRequestType.SetIncrementSortedAsync) < 4 then return end -- leave room for profile saves; retried next round
			local ok, err = pcall(function()
				store:UpdateAsync(tostring(userId), function(old)
					old = tonumber(old) or 0
					if old >= key then return nil end -- never lower a stored score
					return key
				end)
			end)
			if ok then w[b.Id] = key else warn("[Leaderboards] write " .. b.Id .. " failed: " .. tostring(err)) end
		end
	end
end

local nextWrite = {}
local function playerLoop()
	while true do
		task.wait(L.Tick)
		for _, p in ipairs(Players:GetPlayers()) do
			countPlaytime(p)
			local d = DataService.Get(p)
			if d then
				local s = scores(d)
				showOwn(p, s)
				if canPublish(p) and now() >= (nextWrite[p] or 0) then
					nextWrite[p] = now() + L.WriteEvery
					publish(p.UserId, s)
				end
			end
		end
	end
end

DataService.OnLoaded(function(player, d)
	lastCount[player] = os.clock()
	nextWrite[player] = now() + 20 -- first write shortly after joining (scores from before this update show up then)
	showOwn(player, scores(d))
end)

Players.PlayerRemoving:Connect(function(player)
	countPlaytime(player)
	local d = DataService.Get(player)
	if d and canPublish(player) then publish(player.UserId, scores(d)) end
	lastCount[player], nextWrite[player] = nil, nil
	written[player.UserId] = nil
end)

game:BindToClose(function()
	if not CAN_WRITE then return end
	for _, p in ipairs(Players:GetPlayers()) do
		countPlaytime(p)
		local d = DataService.Get(p)
		if d and canPublish(p) then task.spawn(publish, p.UserId, scores(d)) end
	end
	task.wait(2)
end)

--------------------------------------------------
-- reads (global top lists) -> ReplicatedStorage.LeaderboardData
--------------------------------------------------
local folder = RS:FindFirstChild("LeaderboardData") or Instance.new("Folder")
folder.Name = "LeaderboardData"
local values = {}
for _, b in ipairs(L.Boards) do
	local v = folder:FindFirstChild(b.Id) or Instance.new("StringValue")
	v.Name = b.Id
	v.Value = v.Value ~= "" and v.Value or HttpService:JSONEncode({list = {}, note = "Loading..."})
	v.Parent = folder
	values[b.Id] = v
end
folder.Parent = RS

local names = {} -- [userId] = {name, time}
local function resolveNames(ids)
	local want = {}
	for _, id in ipairs(ids) do
		local p = Players:GetPlayerByUserId(id)
		if p then names[id] = {p.DisplayName, os.clock()}
		elseif id > 0 and (not names[id] or os.clock() - names[id][2] > 3600) then table.insert(want, id) end
	end
	if #want > 0 then
		local ok, infos = pcall(function() return UserService:GetUserInfosByUserIdsAsync(want) end)
		if ok and type(infos) == "table" then
			for _, info in ipairs(infos) do names[info.Id] = {info.DisplayName or info.Username, os.clock()} end
		end
		for _, id in ipairs(want) do
			if not names[id] then -- fallback, one by one (only the drawn rows ask for names)
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
				if ok2 and n then names[id] = {n, os.clock()} end
			end
		end
	end
end

local last = {} -- [boardId] = last good list (kept when a read fails)
local function refresh()
	for _, b in ipairs(L.Boards) do
		local store, list, note = stores[b.Id], nil, nil
		if not store then
			note = IS_STUDIO and "Leaderboards load in the live game" or "Leaderboards are offline right now"
		elseif budget(Enum.DataStoreRequestType.GetSortedAsync) < 1 then
			note = nil -- keep the previous list this round
		else
			local ok, res = pcall(function() return store:GetSortedAsync(false, L.Fetch):GetCurrentPage() end)
			if ok then
				list = {}
				for i, e in ipairs(res) do
					local id = tonumber(e.key)
					if id then table.insert(list, {r = i, u = id, v = L.Decode(b, e.value)}) end
				end
			else
				local msg = tostring(res)
				if IS_STUDIO and (msg:find("Studio access to APIs", 1, true) or msg:find("StudioAccessToApisNotAllowed", 1, true)) then
					note = "Leaderboards load in the live game"
				else
					warn("[Leaderboards] read " .. b.Id .. " failed: " .. msg)
				end
			end
		end
		if list then last[b.Id] = list end
		local shown = list or last[b.Id] or {}
		local ids = {}
		for i = 1, math.min(L.Show, #shown) do table.insert(ids, shown[i].u) end
		resolveNames(ids)
		for i = 1, math.min(L.Show, #shown) do local e = shown[i]; e.n = names[e.u] and names[e.u][1] or ("Player " .. e.u) end
		if TEST then note = note or "Studio test board (not saved)" end
		values[b.Id].Value = HttpService:JSONEncode({list = shown, note = note, at = now()})
	end
	folder:SetAttribute("NextRefresh", now() + L.RefreshEvery)
end

task.spawn(playerLoop)
task.spawn(function()
	task.wait(TEST and 2 or 8)
	while true do
		local ok, err = pcall(refresh)
		if not ok then warn("[Leaderboards] refresh error: " .. tostring(err)) end
		task.wait(L.RefreshEvery)
	end
end)
if storeError and not IS_STUDIO then warn("[Leaderboards] stores unavailable: " .. storeError) end

--------------------------------------------------
-- isolated Studio tests only (BalanceTestMode): ServerStorage.LeaderboardTestHook:Invoke(op, ...)
--   "Seed", boardId, {{userId, value}, ...}  -> put raw scores into the in-memory store
--   "Write", player                          -> publish the player's scores now
--   "Refresh"                                 -> read all boards now; returns {boardId = decoded JSON}
--   "Store", boardId                          -> raw keys in the in-memory store
--   "AddPlaytime", player, seconds            -> add to d.PlayTime (to check the time format)
--------------------------------------------------
if TEST then
	local hook = Instance.new("BindableFunction")
	hook.Name = "LeaderboardTestHook"
	hook.OnInvoke = function(op, a, c)
		if op == "Seed" then
			local b = L.ById[a]
			for _, pair in ipairs(c or {}) do stores[a].data[tostring(pair[1])] = L.Encode(b, pair[2]) end
			return true
		elseif op == "Write" then
			local d = DataService.Get(a)
			if not d then return false end
			written[a.UserId] = nil
			publish(a.UserId, scores(d))
			return true
		elseif op == "Refresh" then
			refresh()
			local out = {}
			for id, v in pairs(values) do out[id] = HttpService:JSONDecode(v.Value) end
			return out
		elseif op == "Store" then
			return table.clone(stores[a].data)
		elseif op == "AddPlaytime" then
			local d = DataService.Get(a)
			if not d then return false end
			d.PlayTime = (tonumber(d.PlayTime) or 0) + (tonumber(c) or 0)
			return d.PlayTime
		end
	end
	hook.Parent = SS
end
