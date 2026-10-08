-- MachineService: Hot Cocoa, Pet Fuser and Crafting. The server checks and does everything;
-- MachinesClient only shows the panels. After a change it fires
-- the existing DataRefresh event, so the Inventory and Pet screens reload. Recipes and prices: ReplicatedStorage.MachineConfig.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local Boosts = require(script.Parent:WaitForChild("BoostService"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local A = require(RS:WaitForChild("ActivityConfig"))
local M = require(RS:WaitForChild("MachineConfig"))
local refreshEvent = RS:WaitForChild("DataRefresh")
local GoldenOf = PetConfig.GoldenOf or {}

local fn = Instance.new("RemoteFunction")
fn.Name = "MachineRemote"
fn.Parent = RS

local function copies(list, name)
	local n = 0
	for _, x in ipairs(list or {}) do if x == name then n += 1 end end
	return n
end
local function nice(x) -- 2 significant digits
	x = math.max(1, x)
	if x < 100 then return math.floor(x + 0.5) end
	local e = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / e + 0.5) * e
end

---------------- HOT COCOA MACHINE ----------------
local function drinkPrice(d, dr)
	local a = type(d.Activity) == "table" and d.Activity or {}
	local perMinute = math.max(M.Cocoa.MinSnowPerMinute or 50, (tonumber(a.Rate) or 0) * 60)
	return nice(perMinute * dr.PriceMinutes)
end
local function cocoaList(d)
	local list = {}
	for i, dr in ipairs(M.Cocoa.Drinks) do
		local b = A.Boosts[dr.Boost]
		list[i] = {Index = i, Name = dr.Name, Effect = (b and b.Name or dr.Boost) .. " for " .. math.floor(dr.Seconds / 60 + 0.5) .. " min", Price = drinkPrice(d, dr)}
	end
	return list
end
local function drink(player, d, i)
	local dr = M.Cocoa.Drinks[tonumber(i) or 0]
	if not dr then return false, "Unknown drink" end
	local price = drinkPrice(d, dr)
	if (tonumber(d.Snow) or 0) < price then return false, "Not enough Snow for " .. dr.Name end
	DataService.AddSnow(player, -price)
	Boosts.Add(player, dr.Boost, dr.Seconds)
	return true, "Yum! " .. dr.Name .. " is active."
end

---------------- PET FUSER ----------------
local function sparePets(d, name) -- equipped pets are never used
	return math.max(0, (d.Pets[name] or 0) - copies(d.EquippedPets, name))
end
local function fuserList(d)
	local list = {}
	for name, n in pairs(d.Pets) do
		local golden = GoldenOf[name]
		local pet = PetConfig.PetByName[name]
		if (tonumber(n) or 0) > 0 and golden and pet then
			table.insert(list, {From = name, To = golden, Need = M.Fuser.Need, Have = n, Spare = sparePets(d, name),
				Boost = pet.Boost, GoldenBoost = PetConfig.PetByName[golden].Boost, Rarity = pet.Rarity})
		end
	end
	table.sort(list, function(a, b) if a.Boost ~= b.Boost then return a.Boost > b.Boost end return a.From < b.From end)
	return list
end
local function fuse(player, d, from)
	local golden = type(from) == "string" and GoldenOf[from]
	if not golden then return false, "That pet can't be fused" end
	local need = M.Fuser.Need
	if sparePets(d, from) < need then return false, ("You need %d spare %s (equipped pets don't count)"):format(need, from) end
	d.Pets[from] -= need
	if d.Pets[from] <= 0 then d.Pets[from] = nil end
	d.Pets[golden] = (d.Pets[golden] or 0) + 1
	refreshEvent:FireClient(player)
	return true, "You made a " .. golden .. "!", golden
end

-- golden copies of hand-made pet models (PetModels looks these up by pet name)
local overrides = RS:FindFirstChild("PetModelOverrides")
if overrides then
	for _, m in ipairs(overrides:GetChildren()) do
		local gname = "Golden " .. m.Name
		if PetConfig.PetByName[gname] and not overrides:FindFirstChild(gname) then
			local g = m:Clone()
			g.Name = gname
			for _, p in ipairs(g:GetDescendants()) do
				if p:IsA("BasePart") then p.Color = p.Color:Lerp(Color3.fromRGB(255, 200, 55), 0.65) end
			end
			g.Parent = overrides
		end
	end
end

---------------- CRAFTING MACHINE (2026-10-03, Claude) ----------------
local CraftingConfig = require(RS:WaitForChild("CraftingConfig"))
local TreasureConfig = require(RS:WaitForChild("TreasureConfig"))
local ServerStorage = game:GetService("ServerStorage")
local function recipeVisible(r)
	if r.Enabled ~= false then return true end
	return r.TestOnly == true and ServerStorage:GetAttribute("BalanceTestMode") == true -- example recipes: isolated tests only
end
local function spareTreasure(d, id) -- the last copy always stays in the Treasure Book
	return math.max(0, (tonumber((d.Treasures or {})[id]) or 0) - 1)
end
local function rewardValid(rw)
	if type(rw) ~= "table" then return false end
	if rw.Kind == "Boost" then return A.Boosts[rw.Boost] ~= nil end
	if rw.Kind == "Pet" then return PetConfig.PetByName[rw.Pet] ~= nil end
	if rw.Kind == "Treasure" then return TreasureConfig.ById[rw.Treasure] ~= nil end
	if rw.Kind == "Snow" then return (tonumber(rw.Amount) or 0) > 0 end
	return false
end
local function craftList(d)
	local list = {}
	for i, r in ipairs(CraftingConfig.Recipes or {}) do
		if recipeVisible(r) and rewardValid(r.Reward) then
			local items, can = {}, (tonumber(d.Snow) or 0) >= (r.Snow or 0)
			for id, need in pairs(r.Treasures or {}) do
				local have = spareTreasure(d, id)
				table.insert(items, {Id = id, Need = need, Have = have})
				if have < need then can = false end
			end
			table.sort(items, function(x, y) return x.Id < y.Id end)
			table.insert(list, {Index = i, Id = r.Id, Name = r.Name, Text = r.Text, Snow = r.Snow or 0, Items = items, Can = can, Reward = r.Reward.Kind})
		end
	end
	local mats = {}
	for id, n in pairs(d.Treasures or {}) do
		local spare = math.max(0, (tonumber(n) or 0) - 1)
		if spare > 0 and TreasureConfig.ById[id] then table.insert(mats, {Id = id, Spare = spare}) end
	end
	table.sort(mats, function(x, y) return x.Id < y.Id end)
	return list, mats
end
local function craft(player, d, index)
	local r = (CraftingConfig.Recipes or {})[tonumber(index) or 0]
	if not (r and recipeVisible(r) and rewardValid(r.Reward)) then return false, "That recipe isn't ready yet" end
	if (tonumber(d.Snow) or 0) < (r.Snow or 0) then return false, "Not enough Snow" end
	for id, need in pairs(r.Treasures or {}) do
		if spareTreasure(d, id) < need then
			local t = TreasureConfig.ById[id]
			return false, ("You need %d spare %s"):format(need, t and t.Name or id)
		end
	end
	if (r.Snow or 0) > 0 then DataService.AddSnow(player, -r.Snow) end
	for id, need in pairs(r.Treasures or {}) do d.Treasures[id] -= need end
	local rw = r.Reward
	if rw.Kind == "Boost" then
		Boosts.Add(player, rw.Boost, rw.Seconds or 600)
	elseif rw.Kind == "Pet" then
		d.Pets[rw.Pet] = (d.Pets[rw.Pet] or 0) + 1
		d.PetIndex = d.PetIndex or {}; d.PetIndex[rw.Pet] = true
	elseif rw.Kind == "Treasure" then
		d.TreasureNew = d.TreasureNew or {}
		if (tonumber(d.Treasures[rw.Treasure]) or 0) == 0 then d.TreasureNew[rw.Treasure] = true end
		d.Treasures[rw.Treasure] = (tonumber(d.Treasures[rw.Treasure]) or 0) + 1
	elseif rw.Kind == "Snow" then
		d.Snow = (tonumber(d.Snow) or 0) + rw.Amount -- a prize, not digging income (same as the Lucky Wheel)
		DataService.SetStat(player, "Snow", d.Snow)
	end
	refreshEvent:FireClient(player)
	return true, "You crafted " .. (r.Name or r.Id) .. "!"
end

local busy = {}
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
fn.OnServerInvoke = function(player, action, a, b)
	local d = DataService.Get(player)
	if not d then return {Ok = false, Msg = "Still loading..."} end
	d.Pets = d.Pets or {}
	d.EquippedPets = d.EquippedPets or {}
	if action == "Drink" or action == "Fuse" or action == "Craft" then
		local now = os.clock()
		if busy[player] and now - busy[player] < 0.4 then return {Ok = false, Msg = "Slow down!"} end
		busy[player] = now
	end
	-- 2026-10-04 (Claude): the machines are locked until you own their unlock upgrade (UpgradeConfig.MachineUnlocks)
	local need = ({FuserList = "UnlockFuser", Fuse = "UnlockFuser", CraftList = "UnlockCraft", Craft = "UnlockCraft"})[action]
	if need and (tonumber(player:GetAttribute(need)) or 0) < 1 then
		return {Ok = false, Locked = true, Msg = "Locked - unlock it in the Upgrades tree!", List = {}}
	end
	if action == "CocoaList" then
		return {Ok = true, List = cocoaList(d), Snow = d.Snow}
	elseif action == "Drink" then
		local ok, msg = drink(player, d, a)
		return {Ok = ok, Msg = msg, List = cocoaList(d), Snow = d.Snow}
	elseif action == "FuserList" then
		return {Ok = true, List = fuserList(d), Mult = PetConfig.GoldenMult or 2}
	elseif action == "Fuse" then
		local ok, msg, made = fuse(player, d, a)
		return {Ok = ok, Msg = msg, Made = made, List = fuserList(d), Mult = PetConfig.GoldenMult or 2}
	elseif action == "CraftList" then
		local list, mats = craftList(d)
		return {Ok = true, List = list, Mats = mats, Snow = d.Snow}
	elseif action == "Craft" then
		local ok, msg = craft(player, d, a)
		local list, mats = craftList(d)
		return {Ok = ok, Msg = msg, List = list, Mats = mats, Snow = d.Snow}
	end
	return {Ok = false, Msg = "Unknown"}
end
