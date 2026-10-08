-- DataService: one place that loads/saves each player's data.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local RebirthConfig = require(game.ReplicatedStorage:WaitForChild("RebirthConfig"))
local StarterShovelRules = require(script.Parent:WaitForChild("StarterShovelRules"))
local PlowRules = require(script.Parent:WaitForChild("PlowRules")) -- 2026-10-04: snowplow parts / build / offers
local DataService = {}
local data = {}
local loaded = Instance.new("BindableEvent")

-- Studio-only clean balance sessions neither load nor save real progress.
-- Set ServerStorage's BalanceTestMode attribute before pressing Play to opt in.
local testMode = game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("BalanceTestMode") == true
local store
if not testMode then pcall(function() store = DataStoreService:GetDataStore("RNGData_v1") end) end

local function defaults(d)
	d.Rebirths = RebirthConfig.Count(d.Rebirths)
	d.Counts = type(d.Counts) == "table" and d.Counts or {}
	d.TotalRolls = tonumber(d.TotalRolls) or 0
	d.Snow = tonumber(d.Snow) or 0
	d.Stages = type(d.Stages) == "table" and d.Stages or {}
	d.Upgrades = type(d.Upgrades) == "table" and d.Upgrades or {}
	d.Settings = type(d.Settings) == "table" and d.Settings or {}
	d.Luck = tonumber(d.Luck) or 1 -- roll luck multiplier (luck upgrades raise this)
	if type(d.Equipped) == "string" then d.Equipped = {d.Equipped} end
	if type(d.Equipped) ~= "table" then d.Equipped = {} end
	StarterShovelRules.Apply(d)
	PlowRules.Apply(d)
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

local function load(player)
	if data[player] then return end
	local saved
	if store then
		local ok, res = pcall(function() return store:GetAsync("u" .. player.UserId) end)
		if ok and type(res) == "table" then saved = res end
	end
	if not player.Parent then return end
	local d = defaults(saved or {})
	data[player] = d
	player:SetAttribute("BalanceTestSession", testMode)
	player:SetAttribute("StarterShovelName", StarterShovelRules.Name)

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	stat(ls, "Snow", d.Snow)
	stat(ls, "Rolls", d.TotalRolls)
	stat(ls, "Rebirths", d.Rebirths)
	ls.Parent = player

	loaded:Fire(player, d)
end

-- Serialize autosave, rebirth, and leave saves so an older write cannot finish last.
local saving, saveAgain = {}, {}
local function save(player)
 if not store or not data[player] then return end
 if saving[player] then
  saveAgain[player] = true
  repeat task.wait() until not saving[player]
  return
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
 until not saveAgain[player]
 saving[player] = nil
end
function DataService.Save(player) save(player) end

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



