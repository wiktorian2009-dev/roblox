-- ProductService (2026-10-06, Claude): developer products (PassConfig.Products) - currently the Verity Egg.
-- * The ONLY MarketplaceService.ProcessReceipt in the game. Per receipt:
--     unknown product / player not here / profile not loaded or not loaded from the store -> NotProcessedYet (Roblox retries later);
--     PurchaseId already recorded and saved -> PurchaseGranted (never granted twice);
--     otherwise roll the pet ON THE SERVER from PetConfig (the same table the shop shows), record the PurchaseId in d.Receipts,
--     save, and return PurchaseGranted only when the save reached the DataStore. A failed save keeps the record as unsaved, so the
--     retry saves again instead of rolling again (a purchase is never lost or doubled).
-- * Paid random items: PolicyService:GetPolicyInfoForPlayerAsync -> ArePaidRandomItemsRestricted. Restricted (or unknown after
--   retries) players get the PaidRandomRestricted attribute = true: the shop hides the egg and the server refuses to prompt them.
-- * Purchases start only from the client's explicit BUY click through ProductRemote "Prompt"; the server checks sales on, a real
--   product id, not restricted, profile loaded, then calls PromptProductPurchase. Nothing here can grant without a receipt.
-- * Studio isolated tests (ServerStorage.BalanceTestMode): ServerStorage.ProductTestHook feeds fake receipts / policy / save failures.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local MPS = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local RunService = game:GetService("RunService")
local DataService = require(script.Parent:WaitForChild("DataService"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local P = require(RS:WaitForChild("PassConfig"))
local TEST = RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true
local rng = Random.new()
local MAX_EQUIP = PetConfig.MaxEquipped + 2

local remote = RS:FindFirstChild("ProductRemote") or Instance.new("RemoteFunction")
remote.Name = "ProductRemote"; remote.Parent = RS
local hatchedEvent = RS:WaitForChild("PetHatched")

local test = {policy = {}, failSaves = 0, ids = {}} -- TEST only
local function productFor(id) return P.ProductById[id] or test.ids[id] end

--------------------------------------------------
-- policy (paid random items)
--------------------------------------------------
local function checkPolicy(player)
	if TEST and test.policy[player] ~= nil then player:SetAttribute("PaidRandomRestricted", test.policy[player]); return end
	for attempt = 1, 3 do
		local ok, res = pcall(function() return PolicyService:GetPolicyInfoForPlayerAsync(player) end)
		if ok and type(res) == "table" then
			player:SetAttribute("PaidRandomRestricted", res.ArePaidRandomItemsRestricted == true)
			return
		end
		if not player.Parent then return end
		task.wait(attempt * 2)
	end
	player:SetAttribute("PaidRandomRestricted", true) -- unknown: treat as restricted (hidden, never prompted)
end
Players.PlayerAdded:Connect(checkPolicy)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(checkPolicy, p) end

--------------------------------------------------
-- grant (inside the receipt)
--------------------------------------------------
local function save(player)
	if TEST and test.failSaves > 0 then test.failSaves -= 1; return false end
	return DataService.SaveNow(player)
end
local function grantEgg(player, d, product, purchaseId)
	local egg = PetConfig.EggById[product.Egg]
	if not egg then return nil end
	local pet = PetConfig.RollPet(egg, rng)
	local isNew = not d.PetIndex[pet.Name]
	d.PetIndex[pet.Name] = true
	d.Pets[pet.Name] = (d.Pets[pet.Name] or 0) + 1
	local slots = math.min(player:GetAttribute("PetSlots") or PetConfig.MaxEquipped, MAX_EQUIP)
	if #d.EquippedPets < slots then table.insert(d.EquippedPets, pet.Name) end
	-- keep the receipt history bounded: drop the oldest saved records beyond 300 (Roblox stops retrying long before that)
	local n, oldest, oldestT = 0, nil, math.huge
	for k, r in pairs(d.Receipts) do
		n += 1
		if r.Saved and (r.T or 0) < oldestT then oldest, oldestT = k, r.T or 0 end
	end
	if n >= 300 and oldest then d.Receipts[oldest] = nil end
	d.Receipts[purchaseId] = {Product = product.Key, Pet = pet.Name, T = os.time(), Saved = false}
	return pet, isNew
end
local function processReceipt(info)
	local product = productFor(info.ProductId)
	if not product then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local d = player and DataService.Get(player)
	if not d or not DataService.LoadedFromStore(player) then return Enum.ProductPurchaseDecision.NotProcessedYet end
	d.Receipts = type(d.Receipts) == "table" and d.Receipts or {}
	local id = tostring(info.PurchaseId)
	local rec = d.Receipts[id]
	local pet, isNew
	if not rec then
		pet, isNew = grantEgg(player, d, product, id)
		if not pet then return Enum.ProductPurchaseDecision.NotProcessedYet end
		rec = d.Receipts[id]
	end
	if not rec.Saved then
		rec.Saved = true -- written into the same save; a failed write leaves the in-memory record and the retry saves again
		if not save(player) then
			rec.Saved = false
			warn("[ProductService] receipt " .. id .. " not saved yet; Roblox will retry")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	if pet then
		player:SetAttribute("EquippedPets", table.concat(d.EquippedPets, ","))
		hatchedEvent:FireClient(player, "Hatched", product.Egg, pet.Name, isNew, d.Pets, d.EquippedPets, d.PetIndex)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
MPS.ProcessReceipt = processReceipt

--------------------------------------------------
-- explicit purchase prompt (server-checked)
--------------------------------------------------
local lastPrompt = {}
local function canSell(player, product)
	if not product then return false, "unknown" end
	if not P.ProductSalesEnabled or not product.Id then return false, "soon" end
	if player:GetAttribute("PaidRandomRestricted") ~= false then return false, "restricted" end
	if not DataService.Get(player) then return false, "loading" end
	return true
end
remote.OnServerInvoke = function(player, action, key)
	if action == "State" then
		local product = P.Products[key]
		local ok, why = canSell(player, product)
		return {ok = true, canBuy = ok, why = why, salesEnabled = P.ProductSalesEnabled == true}
	elseif action == "Prompt" then
		local product = type(key) == "string" and P.Products[key]
		local ok, why = canSell(player, product)
		if not ok then return {ok = false, why = why} end
		local now = os.clock()
		if lastPrompt[player] and now - lastPrompt[player] < 2 then return {ok = false, why = "wait"} end
		lastPrompt[player] = now
		MPS:PromptProductPurchase(player, product.Id)
		return {ok = true}
	end
	return {ok = false}
end
Players.PlayerRemoving:Connect(function(p) lastPrompt[p] = nil; test.policy[p] = nil end)

if TEST then
	local hook = Instance.new("BindableFunction"); hook.Name = "ProductTestHook"
	hook.OnInvoke = function(op, player, a, b, c)
		if op == "Policy" then test.policy[player] = a == true; checkPolicy(player); return player:GetAttribute("PaidRandomRestricted")
		elseif op == "FailSaves" then test.failSaves = tonumber(a) or 0; return true
		elseif op == "Receipt" then -- a = fake product id (registered for product key b), c = PurchaseId; returns the decision name
			if b then test.ids[a] = P.Products[b] end
			return processReceipt({ProductId = a, PlayerId = player.UserId, PurchaseId = c}).Name
		elseif op == "Data" then
			local d = DataService.Get(player)
			return d and {Receipts = d.Receipts and table.clone(d.Receipts) or {}, Pets = table.clone(d.Pets), Equipped = table.clone(d.EquippedPets)}
		end
	end
	hook.Parent = SS
end
