-- TreasureService (2026-10-01, Claude): Buried Treasures, fully server-side (RNG, ownership, Snow rewards).
-- SnowFieldService calls TileCleared(player, field, tilePos) whenever one of the player's tiles is dug down to 0 layers.
-- Each call: first-find guarantee, else TreasureConfig.TileChance -> rarity by weight -> that biome's item for the rarity.
-- Award: Snow bonus = rarity Bonus x one full tile's Snow x the player's Snow multipliers; the item enters d.Treasures.
-- Profile fields (saved with the rest of the profile; rebirth keeps them): Treasures, TreasureNew, TreasureFound, TreasureDug.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local DataService = require(script.Parent:WaitForChild("DataService"))
local TC = require(RS:WaitForChild("TreasureConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local SF = require(RS:WaitForChild("SnowFields"))

local function remote(class, name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = RS end
	return r
end
local foundEvent = remote("RemoteEvent", "TreasureFound")
local treasureRemote = remote("RemoteFunction", "TreasureRemote")

local T = {}
local recent = {}
local rng = Random.new()

local function sanitize(d)
	d.Treasures = type(d.Treasures) == "table" and d.Treasures or {}
	d.TreasureNew = type(d.TreasureNew) == "table" and d.TreasureNew or {}
	d.TreasureFound = tonumber(d.TreasureFound) or 0
	d.TreasureDug = tonumber(d.TreasureDug) or 0
	d.Settings = type(d.Settings) == "table" and d.Settings or {}
end
-- OnLoaded hands later joiners a COPY of the profile (BindableEvent), so always work on DataService.Get(player).
local function profile(player)
	local d = DataService.Get(player)
	if d and type(d.Treasures) ~= "table" then sanitize(d) end
	return d
end
DataService.OnLoaded(function(player)
	local d = profile(player)
	if d then player:SetAttribute("TreasuresFound", d.TreasureFound) end
end)
Players.PlayerRemoving:Connect(function(p) recent[p] = nil end)

-- same multipliers SnowFieldService applies to dug Snow (pets x pet boosts x SnowMult incl. upgrades, rebirths, friends)
local function snowMultiplier(player)
	local pets = {}
	for n in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(pets, n) end
	return (1 + (PetConfig.Multiplier(pets, player) - 1) * (player:GetAttribute("PetBoostMult") or 1)) * (player:GetAttribute("SnowMult") or 1)
end

local function pickRarity()
	local r = rng:NextNumber() * TC.TotalWeight
	for _, rar in ipairs(TC.Rarities) do
		r -= rar.Weight
		if r <= 0 then return rar end
	end
	return TC.Rarities[1]
end

-- 2026-10-04 (Claude): fields are tougher (TileHP and SnowPerPhase x TileScale on each SnowStages stage), so a cleared tile rolls
-- TileScale x more often and a treasure's Snow bonus is divided by TileScale: treasures keep their old pace and value.
local function tileScale(field)
	local stages = game:GetService("ReplicatedStorage"):FindFirstChild("SnowStages")
	local st = field and field.Style and stages and stages:FindFirstChild(field.Style)
	return math.max(1, (st and st:GetAttribute("TileScale")) or 1)
end

local function award(player, d, item, field, pos, guaranteed)
	local rar = TC.RarityById[item.Rarity]
	local tileSnow = ((field and field.SnowPerPhase) or 1) / tileScale(field) * SF.MaxPhase
	local bonus = math.max(1, math.floor(tileSnow * rar.Bonus * snowMultiplier(player) + 0.5))
	local count = (tonumber(d.Treasures[item.Id]) or 0) + 1
	local isNew = count == 1
	d.Treasures[item.Id] = count
	if isNew then d.TreasureNew[item.Id] = true end
	d.TreasureFound += 1
	DataService.AddSnow(player, bonus)
	player:SetAttribute("TreasuresFound", d.TreasureFound)
	foundEvent:FireClient(player, {Id = item.Id, New = isNew, Count = count, Snow = bonus, Pos = pos, First = guaranteed == true})
	if rar.Announce then
		for _, other in ipairs(Players:GetPlayers()) do
			local root = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - pos).Magnitude <= TC.AnnounceRadius then
				foundEvent:FireClient(other, {Id = item.Id, Announce = true, Finder = player.DisplayName, Pos = pos})
			end
		end
	end
	return bonus
end

function T.TileCleared(player, field, pos)
	local d = profile(player)
	if not d then return end
	local biome = TC.BiomeFor(field and field.Style)
	if d.TreasureFound == 0 then
		d.TreasureDug += 1
		if d.TreasureDug >= TC.GuaranteeAfterTiles then
			award(player, d, biome.ByRarity.Common, field, pos, true)
			return
		end
	end
	if rng:NextNumber() >= math.min(0.5, TC.TileChance * tileScale(field)) then return end
	local now = os.clock()
	local r = recent[player]
	if not r or now - r.t > 1 then r = {t = now, n = 0}; recent[player] = r end
	if r.n >= TC.MaxPerSecond then return end
	r.n += 1
	award(player, d, biome.ByRarity[pickRarity().Id], field, pos, false)
end

-- 2026-10-04 (Claude): Frost King boss reward - one random treasure of that field's biome (normal rarity weights)
function T.GrantRandom(player, style, field)
	local d = profile(player)
	if not d then return nil end
	local biome = TC.BiomeFor(style)
	local item = biome and biome.ByRarity[pickRarity().Id]
	if not item then return nil end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local pos = root and (root.Position + root.CFrame.LookVector * 5 - Vector3.new(0, 2.5, 0)) or Vector3.zero
	award(player, d, item, field or {Style = style, SnowPerPhase = 1}, pos, false)
	return item
end

treasureRemote.OnServerInvoke = function(player, action, arg)
	local d = profile(player)
	if not d then return nil end
	if action == "Get" then
		return {Treasures = d.Treasures, New = d.TreasureNew, Found = d.TreasureFound,
			Sound = d.Settings.TreasureSound ~= false, Reduced = d.Settings.TreasureReduced == true}
	elseif action == "Seen" and type(arg) == "table" then
		for _, id in ipairs(arg) do if type(id) == "string" then d.TreasureNew[id] = nil end end
		return true
	elseif action == "Settings" and type(arg) == "table" then
		if type(arg.Sound) == "boolean" then d.Settings.TreasureSound = arg.Sound end
		if type(arg.Reduced) == "boolean" then d.Settings.TreasureReduced = arg.Reduced end
		return true
	end
	return nil
end

-- Studio isolated tests only (BalanceTestMode): ServerStorage.TreasureTestHook:Invoke(action, player, ...)
if RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true then
	local hook = Instance.new("BindableFunction")
	hook.Name = "TreasureTestHook"
	hook.OnInvoke = function(action, player, a, b)
		local d = player and profile(player)
		if not d then return nil end
		if action == "Force" then
			local item = TC.ById[a]
			if not item then return nil end
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local pos = b or (root and (root.Position + root.CFrame.LookVector * 6 - Vector3.new(0, 2.5, 0))) or Vector3.zero
			return award(player, d, item, {SnowPerPhase = 1}, pos, false)
		elseif action == "Data" then
			return {Treasures = table.clone(d.Treasures), New = table.clone(d.TreasureNew), Found = d.TreasureFound, Dug = d.TreasureDug, Snow = d.Snow, Rebirths = d.Rebirths}
		end
		return nil
	end
	hook.Parent = SS
end

return T
