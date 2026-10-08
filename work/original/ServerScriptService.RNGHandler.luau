-- RNGHandler: rolling + equipping shovels. Data lives in DataService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))
local Config = require(ReplicatedStorage:WaitForChild("RNGConfig"))
local Balance = require(ReplicatedStorage:WaitForChild("Balance"))
local remote = ReplicatedStorage:WaitForChild("RollRNG")
local getInventory = ReplicatedStorage:WaitForChild("GetInventory")
local equipRemote = ReplicatedStorage:WaitForChild("EquipShovel")

local MAX_EQUIPPED = (Config.MaxEquipped or 2) + 1 -- absolute max (with the 3rd Shovel upgrade)
local function slotsFor(player) return player:GetAttribute("ShovelSlots") or Config.MaxEquipped or 2 end
local lastRoll, lastEquip = {}, {}

-- rarest first, each at its own "1 in N"
local sorted = table.clone(Config.Items)
table.sort(sorted, function(a, b) return a.Chance > b.Chance end)
local function roll(luck)
	luck = luck or 1
	for _, item in ipairs(sorted) do
		if item.Chance > 1 and math.random() < luck / item.Chance then return item.Name end
	end
	return sorted[#sorted].Name
end

local function copies(list, name)
	local n = 0
	for _, e in ipairs(list) do if e == name then n += 1 end end
	return n
end

-- equipped list is published as an attribute; clients draw the spinner from it
local function publish(player, d)
	player:SetAttribute("EquippedShovels", table.concat(d.Equipped, ","))
end

local function sanitize(d)
	local clean = {}
	for _, name in ipairs(d.Equipped) do
		if Config.ByName[name] and copies(clean, name) < (d.Counts[name] or 0) and #clean < MAX_EQUIPPED then
			table.insert(clean, name)
		end
	end
	d.Equipped = clean
end

DataService.OnLoaded(function(player, d)
	sanitize(d)
	publish(player, d)
end)

Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
	lastEquip[player] = nil
end)

getInventory.OnServerInvoke = function(player)
	local d = DataService.Get(player)
	return d and {Counts = d.Counts, Equipped = d.Equipped}
end

remote.OnServerEvent:Connect(function(player)
	local d = DataService.Get(player)
	if not d then return end
	local now = os.clock()
	if lastRoll[player] and now - lastRoll[player] < Config.RollCooldown * (player:GetAttribute("RollAnimScale") or 1) then return end
	lastRoll[player] = now

	-- luck = base * upgrades/friends * equipped shovels (each gives Balance.ShovelLuck)
	local shovelLuck = 0
	for _, name in ipairs(d.Equipped) do
		local it = Config.ByName[name]
		if it then shovelLuck += Balance.ShovelLuck(it.Chance) end
	end
	local luck = (d.Luck or 1) * (player:GetAttribute("LuckMult") or 1) * math.max(1, shovelLuck)
	player:SetAttribute("TotalLuck", luck)
	local result = roll(luck)
	d.Counts[result] = (d.Counts[result] or 0) + 1
	d.TotalRolls += 1
	DataService.SetStat(player, "Rolls", d.TotalRolls)

	if #d.Equipped == 0 then
		table.insert(d.Equipped, result)
		task.delay(3.8, function()
			if DataService.Get(player) == d then publish(player, d) end
		end)
	end

	-- Double Roll upgrade: chance for a bonus shovel
	local extra
	if math.random() < (player:GetAttribute("DoubleRollChance") or 0) then
		extra = roll(luck)
		d.Counts[extra] = (d.Counts[extra] or 0) + 1
	end
	remote:FireClient(player, result, d.Counts, d.Equipped, luck, extra)
end)

equipRemote.OnServerInvoke = function(player, action, name)
	local d = DataService.Get(player)
	if not d then return nil end
	local now = os.clock()
	if lastEquip[player] and now - lastEquip[player] < 0.25 then return d.Equipped end
	lastEquip[player] = now
	if type(name) ~= "string" or not Config.ByName[name] then return d.Equipped end

	if action == "equip" then
		if copies(d.Equipped, name) < (d.Counts[name] or 0) then
			if #d.Equipped >= slotsFor(player) then table.remove(d.Equipped, 1) end
			table.insert(d.Equipped, name)
		end
	elseif action == "unequip" then
		for i = #d.Equipped, 1, -1 do
			if d.Equipped[i] == name then table.remove(d.Equipped, i) break end
		end
	end
	publish(player, d)
	return d.Equipped
end

