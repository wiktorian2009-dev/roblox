-- CommunityRewardService (2026-10-13, Claude): the free one-time SUPPORTER GIFT (CommunityRewardConfig) for joining the game's group.
-- * Membership is checked here on the server (GroupService:GetGroupsAsync, which is not cached, so a player who joins mid-session
--   is seen; Player:IsInGroup as the fallback). The client only asks (CommunityRewardRemote) and can never grant anything.
-- * The like is honor-system (Roblox exposes no "did this player like the game" API). Since 2026-10-14 (wiktor: players joined but
--   didn't like) the claim requires the client's like confirmation (card step 1, tap + countdown + confirm); recorded as LikeAck.
-- * Saved once per profile: d.Community.Claimed = os.time(), written with an immediate save. Profiles that did not come from the
--   store (Studio with API access off) cannot claim, so a gift can never be given on a profile that will not be saved.
-- * Prize: the exclusive Frosty Pal pet (auto-equipped when a slot is free) + Snow worth ~10 minutes of clearing + 15 min 2x Snow.
-- * Studio isolated tests (ServerStorage.BalanceTestMode): ServerStorage.CommunityRewardTestHook mocks membership and reads the record.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local GroupService = game:GetService("GroupService")
local DataService = require(script.Parent:WaitForChild("DataService"))
local Boosts = require(script.Parent:WaitForChild("BoostService"))
local CFG = require(RS:WaitForChild("CommunityRewardConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local A = require(RS:WaitForChild("ActivityConfig"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local TEST = RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true

local remote = RS:FindFirstChild("CommunityRewardRemote") or Instance.new("RemoteFunction")
remote.Name = "CommunityRewardRemote"; remote.Parent = RS
local hatchedEvent = RS:WaitForChild("PetHatched")

local function groupId()
	if CFG.GroupId then return CFG.GroupId end
	if game.CreatorType == Enum.CreatorType.Group then return game.CreatorId end
	return nil
end
RS:SetAttribute("CommunityGroupId", groupId())

local mock = {} -- TEST only: [player] = true / false (membership), nil = ask Roblox
local cache = {} -- [player] = {at = os.clock(), member = bool}
local function isMember(player, fresh)
	local gid = groupId()
	if not gid then return false end
	if TEST and mock[player] ~= nil then return mock[player] end
	local c = cache[player]
	if c and (c.member or (not fresh and os.clock() - c.at < 20)) then return c.member end
	local member
	local ok, groups = pcall(GroupService.GetGroupsAsync, GroupService, player.UserId)
	if ok and type(groups) == "table" then
		member = false
		for _, g in ipairs(groups) do if g.Id == gid then member = true break end end
	else
		local ok2, res = pcall(player.IsInGroup, player, gid)
		if ok2 then member = res == true end
	end
	if member == nil then return false end -- both calls failed: say "not yet", the player can tap CHECK again
	cache[player] = {at = os.clock(), member = member}
	return member
end

local function record(d)
	d.Community = type(d.Community) == "table" and d.Community or {}
	return d.Community
end
local function state(player, fresh)
	local d = DataService.Get(player)
	if not d then return {ok = false} end
	local claimed = record(d).Claimed ~= nil
	local member = true
	if not claimed then member = isMember(player, fresh) end
	return {ok = true, claimed = claimed, groupId = groupId(), member = member}
end

local function snowAmount(d)
	local a = type(d.Activity) == "table" and d.Activity or {}
	local x = math.max(CFG.SnowMin, (tonumber(a.Rate) or 0) * 60 * CFG.SnowMinutes)
	if x >= 100 then local e = 10 ^ (math.floor(math.log10(x)) - 1); x = math.floor(x / e + 0.5) * e end -- round like the quest rewards
	return x
end

local busy = {}
local function claim(player, liked)
	local d = DataService.Get(player)
	if not d then return {ok = false, msg = "Still loading - try again in a moment."} end
	local rec = record(d)
	if rec.Claimed then return {ok = false, msg = "You already got your gift - thank you!", claimed = true} end
	if not DataService.LoadedFromStore(player) then return {ok = false, msg = "Your save isn't loaded, so the gift can't be kept. Rejoin and try again."} end
	if not groupId() then return {ok = false, msg = "The gift isn't available right now."} end
	if liked ~= true then return {ok = false, msg = "Like the game first (step 1), then tap CLAIM!"} end -- honor-system (no Roblox like API), but required
	if not isMember(player, true) then return {ok = false, msg = "Join the group first, then tap CLAIM!"} end
	local pet = PetConfig.PetByName[CFG.Pet]
	if not pet then return {ok = false, msg = "The gift isn't available right now."} end

	rec.Claimed, rec.Group, rec.LikeAck, rec.V = os.time(), groupId(), os.time(), 2 -- marked first: nothing below can run twice for this profile
	local isNew = not d.PetIndex[pet.Name]
	d.PetIndex[pet.Name] = true
	d.Pets[pet.Name] = (d.Pets[pet.Name] or 0) + 1
	local slots = player:GetAttribute("PetSlots") or PetConfig.MaxEquipped or 3
	if #d.EquippedPets < slots then table.insert(d.EquippedPets, pet.Name) end
	local snow = snowAmount(d)
	DataService.AddSnow(player, snow)
	if Boosts.Add and A.Boosts[CFG.Boost] then pcall(Boosts.Add, player, CFG.Boost, CFG.BoostSeconds) end
	player:SetAttribute("CommunityGiftClaimed", true)
	player:SetAttribute("EquippedPets", table.concat(d.EquippedPets, ","))
	task.spawn(DataService.SaveNow, player)
	hatchedEvent:FireClient(player, "Hatched", CFG.Egg, pet.Name, isNew, d.Pets, d.EquippedPets, d.PetIndex)
	local boost = A.Boosts[CFG.Boost]
	return {ok = true, claimed = true, pet = pet.Name, snow = snow,
		msg = "Thanks for joining! " .. pet.Name .. " + \u{2744}\u{FE0F} " .. NumberFormat.Abbreviate(snow) .. " Snow"
			.. (boost and (" + " .. boost.Name .. " for " .. math.floor(CFG.BoostSeconds / 60) .. " min") or "")}
end

local lastCall = {}
remote.OnServerInvoke = function(player, action, liked)
	local now = os.clock()
	if action ~= "State" then
		if lastCall[player] and now - lastCall[player] < 1.5 then return {ok = false, msg = "Slow down!"} end
		lastCall[player] = now
	end
	if action == "State" then return state(player, false)
	elseif action == "Check" then return state(player, true)
	elseif action == "Claim" then
		if busy[player] then return {ok = false, msg = "One moment..."} end
		busy[player] = true
		local ok, res = pcall(claim, player, liked == true)
		busy[player] = nil
		if not ok then warn("[CommunityReward] " .. tostring(res)); return {ok = false, msg = "Something went wrong - try again."} end
		return res
	end
	return {ok = false}
end

DataService.OnLoaded(function(player)
	local d = DataService.Get(player)
	if d then player:SetAttribute("CommunityGiftClaimed", record(d).Claimed ~= nil) end
end)
Players.PlayerRemoving:Connect(function(p) mock[p], cache[p], lastCall[p], busy[p] = nil, nil, nil, nil end)

if TEST then
	local hook = Instance.new("BindableFunction"); hook.Name = "CommunityRewardTestHook"
	hook.OnInvoke = function(op, player, value)
		if op == "Mock" then mock[player] = value; cache[player] = nil; return true
		elseif op == "Data" then local d = DataService.Get(player); return d and table.clone(record(d)) or nil
		elseif op == "Claim" then lastCall[player] = nil; return claim(player, value ~= false)
		elseif op == "Reset" then -- temp test profile only (BalanceTestMode never touches the real store)
			local d = DataService.Get(player); if d then d.Community = nil end
			player:SetAttribute("CommunityGiftClaimed", false); return true
		end
		return nil
	end
	hook.Parent = SS
end
