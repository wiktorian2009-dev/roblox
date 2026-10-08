-- PetService: opening eggs (ProximityPrompt), owning & equipping pets. Everything validated here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local hatchedEvent = ReplicatedStorage:WaitForChild("PetHatched")
local equipRemote = ReplicatedStorage:WaitForChild("EquipPet")
local getPets = ReplicatedStorage:WaitForChild("GetPets")

local MAX = PetConfig.MaxEquipped + 2 -- absolute max (with the +1 Pet Equip upgrades)
local function slotsFor(player) return player:GetAttribute("PetSlots") or PetConfig.MaxEquipped end
local HATCH_COOLDOWN = 2.2
local lastHatch, lastEquip = {}, {}

local function copies(list, name)
	local n = 0
	for _, e in ipairs(list) do if e == name then n += 1 end end
	return n
end

local function publish(player, d)
	player:SetAttribute("EquippedPets", table.concat(d.EquippedPets, ","))
end

DataService.OnLoaded(function(player, d)
	local clean = {}
	for _, name in ipairs(d.EquippedPets) do
		if PetConfig.PetByName[name] and copies(clean, name) < (d.Pets[name] or 0) and #clean < MAX then
			table.insert(clean, name)
		end
	end
	d.EquippedPets = clean
	publish(player, d)
end)

Players.PlayerRemoving:Connect(function(p) lastHatch[p] = nil; lastEquip[p] = nil end)

local function rollPet(egg)
	local total = 0
	for _, p in ipairs(egg.Pets) do total += p.Chance end
	local r = math.random() * total
	for _, p in ipairs(egg.Pets) do
		r -= p.Chance
		if r <= 0 then return p end
	end
	return egg.Pets[1]
end

local function hatch(player, egg, eggPart)
	local d = DataService.Get(player)
	if not d or egg.Paid then return end -- 2026-10-06: paid eggs (Verity Egg) are only granted by ProductService receipts
	-- 2026-10-02 (Claude): Cost-0 stages (World 2 Sakura) open through the previous stage, so d.Stages has no entry for them.
	-- StageService sets Stage_<Id> on the server from the same profile (client changes never replicate back).
	if egg.RequiredStage and egg.RequiredStage ~= "Starter" and d.Stages[egg.RequiredStage] ~= true
		and player:GetAttribute("Stage_" .. egg.RequiredStage) ~= true then return end
	local now = os.clock()
	if lastHatch[player] and now - lastHatch[player] < HATCH_COOLDOWN then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - eggPart.Position).Magnitude > 20 then return end
	local cost = math.floor(egg.Cost * (1 - (player:GetAttribute("EggDiscount") or 0)) + 0.5)
	if d.Snow < cost then
		hatchedEvent:FireClient(player, "NotEnough", egg.Id, cost)
		return
	end
	lastHatch[player] = now
	DataService.AddSnow(player, -cost)
	local pet = rollPet(egg)
	local isNew = not d.PetIndex[pet.Name]
	d.PetIndex[pet.Name] = true
	d.Pets[pet.Name] = (d.Pets[pet.Name] or 0) + 1
	if #d.EquippedPets < slotsFor(player) then
		table.insert(d.EquippedPets, pet.Name)
		task.delay(2.5, function() if DataService.Get(player) == d then publish(player, d) end end)
	end
	hatchedEvent:FireClient(player, "Hatched", egg.Id, pet.Name, isNew, d.Pets, d.EquippedPets, d.PetIndex)
end

--------------------------------------------------
-- EGG PROMPTS + ODDS SIGNS
--------------------------------------------------
local function rarityHex(r)
	local c = PetConfig.Rarities[r] or Color3.new(1, 1, 1)
	return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end

local function setupEgg(model, egg)
	if model:GetAttribute("EggReady") or egg.Paid then return end
	model:SetAttribute("EggReady", true)
	local main = model.PrimaryPart
	if not main then
		local biggest = 0
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p.Size.Magnitude > biggest then biggest = p.Size.Magnitude; main = p end
		end
	end
	if not main then return end
	local _, size = model:GetBoundingBox()

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HatchPrompt"
	prompt.ActionText = "Open (" .. NumberFormat.Abbreviate(egg.Cost) .. " ❄)"
	prompt.ObjectText = egg.Name
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = main
	prompt.Triggered:Connect(function(player) hatch(player, egg, main) end)

	-- the odds sign is drawn by each client (PetClient) so undiscovered pets can be silhouettes
end

local function scan()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and PetConfig.EggById[d.Name] then setupEgg(d, PetConfig.EggById[d.Name]) end
	end
end
scan()
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("Model") and PetConfig.EggById[d.Name] then task.defer(setupEgg, d, PetConfig.EggById[d.Name]) end
end)

--------------------------------------------------
-- REMOTES
--------------------------------------------------
getPets.OnServerInvoke = function(player)
	local d = DataService.Get(player)
	return d and {Pets = d.Pets, Equipped = d.EquippedPets, Index = d.PetIndex}
end

-- 2026-10-06 (Claude): EQUIP BEST - the strongest owned pets (by the same BoostOf the income uses, so progress-scaled Verity pets and
-- Golden pets rank correctly), up to the player's slots. Only owned copies count; fusing takes spare copies at the moment it runs,
-- so there is no "in use" state to respect. Returns status "ok" / "same" / "wait" / "none".
local lastBest = {}
local function equipBest(player, d)
	local now = os.clock()
	if lastBest[player] and now - lastBest[player] < 1.5 then return d.EquippedPets, "wait" end
	lastBest[player] = now
	local list = {}
	for name, n in pairs(d.Pets) do
		local pet = PetConfig.PetByName[name]
		if pet then
			local b = PetConfig.BoostOf(pet, player)
			for _ = 1, math.min(tonumber(n) or 0, MAX) do table.insert(list, {name = name, b = b}) end
		end
	end
	if #list == 0 then return d.EquippedPets, "none" end
	table.sort(list, function(a, b) if a.b ~= b.b then return a.b > b.b end return a.name < b.name end)
	local best, bestSum, curSum = {}, 0, 0
	for i = 1, math.min(#list, slotsFor(player), MAX) do best[i] = list[i].name; bestSum += list[i].b end
	for _, n in ipairs(d.EquippedPets) do local p = PetConfig.PetByName[n]; if p then curSum += PetConfig.BoostOf(p, player) end end
	-- already as strong as it gets (equal-strength pets are never swapped back and forth)
	if #best == #d.EquippedPets and bestSum <= curSum + 1e-9 then return d.EquippedPets, "same" end
	d.EquippedPets = best
	publish(player, d)
	return d.EquippedPets, "ok"
end
Players.PlayerRemoving:Connect(function(p) lastBest[p] = nil end)

equipRemote.OnServerInvoke = function(player, action, name)
	local d = DataService.Get(player)
	if not d then return nil end
	if action == "best" then return equipBest(player, d) end
	local now = os.clock()
	if lastEquip[player] and now - lastEquip[player] < 0.25 then return d.EquippedPets end
	lastEquip[player] = now
	if type(name) ~= "string" or not PetConfig.PetByName[name] then return d.EquippedPets end
	if action == "equip" then
		if copies(d.EquippedPets, name) < (d.Pets[name] or 0) then
			if #d.EquippedPets >= slotsFor(player) then table.remove(d.EquippedPets, 1) end
			table.insert(d.EquippedPets, name)
		end
	elseif action == "unequip" then
		for i = #d.EquippedPets, 1, -1 do
			if d.EquippedPets[i] == name then table.remove(d.EquippedPets, i) break end
		end
	end
	publish(player, d)
	return d.EquippedPets
end

