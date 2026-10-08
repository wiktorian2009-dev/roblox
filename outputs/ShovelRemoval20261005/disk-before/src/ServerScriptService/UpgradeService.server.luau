-- UpgradeService: buys hex tiles and turns owned tiles into stats (player attributes) that the other systems read.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local U = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local RebirthConfig = require(ReplicatedStorage:WaitForChild("RebirthConfig"))
local buy = ReplicatedStorage:WaitForChild("BuyUpgrade")
-- ACTIVITIES (2026-10-02, Claude): events, timed boosts and achievement bonuses multiply SnowMult/LuckMult (BoostService)
local okBoosts, Boosts = pcall(function() return require(script.Parent:WaitForChild("BoostService", 10)) end)
if not okBoosts then warn("[UpgradeService] BoostService unavailable: " .. tostring(Boosts)); Boosts = nil end

local friendCount = {}
local lastBuy = {}

local function owned(d)
	local set = {}
	for id, v in pairs(d.Upgrades) do if v and U.ById[id] then set[id] = true end end
	return set
end

local function apply(player)
	local d = DataService.Get(player)
	if not d then return end
	local set = owned(d)
	local stats = U.Calculate(set, friendCount[player] or 0)
 local snow, luck = RebirthConfig.Multipliers(d.Rebirths)
 stats.SnowMult *= snow
 stats.LuckMult *= luck
 if Boosts then
  local okB, bs, bl = pcall(Boosts.Multipliers, player)
  if okB then
   stats.SnowMult *= bs
   stats.LuckMult *= bl
   player:SetAttribute("BoostSnowMult", bs)
   player:SetAttribute("BoostLuckMult", bl)
  end
 end
 player:SetAttribute("Rebirths", RebirthConfig.Count(d.Rebirths))
 player:SetAttribute("RebirthSnowMult", snow)
 player:SetAttribute("RebirthLuckMult", luck)
 DataService.SetStat(player, "Rebirths", RebirthConfig.Count(d.Rebirths))
	for k, v in pairs(stats) do player:SetAttribute(k, v) end
	player:SetAttribute("FriendsHere", friendCount[player] or 0)
	for id in pairs(U.ById) do player:SetAttribute("Up_" .. id, set[id] == true) end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = stats.WalkSpeed end
end

local function recountFriends()
	local list = Players:GetPlayers()
	for _, p in ipairs(list) do
		task.spawn(function()
			local n = 0
			for _, other in ipairs(list) do
				if other ~= p then
					local ok, isFriend = pcall(function() return p:IsFriendsWith(other.UserId) end)
					if ok and isFriend then n += 1 end
				end
			end
			friendCount[p] = n
			apply(p)
		end)
	end
end

DataService.OnLoaded(function(player)
	apply(player)
	player.CharacterAdded:Connect(function() task.defer(apply, player) end)
	recountFriends()
end)
Players.PlayerRemoving:Connect(function(p)
	friendCount[p] = nil
	lastBuy[p] = nil
	task.defer(recountFriends)
end)

buy.OnServerInvoke = function(player, id)
	local d = DataService.Get(player)
	local n = type(id) == "string" and U.ById[id]
	if not d or not n then return false, "Unknown" end
	local now = os.clock()
	if lastBuy[player] and now - lastBuy[player] < 0.15 then return false, "Slow down" end
	lastBuy[player] = now
	local set = owned(d)
	if set[id] then return false, "Owned" end
	local reason = U.LockReason(n, set, d.Stages)
	if reason then return false, reason end
	local cost = U.CostOf(n)
	if d.Snow < cost then return false, "Not enough snow" end
	DataService.AddSnow(player, -cost)
	d.Upgrades[id] = true
	apply(player)
	return true
end

-- admin commands (;upgrades all/reset, ;reset) ask for a re-apply
game:GetService("ServerStorage"):WaitForChild("AdminHooks"):WaitForChild("ReapplyUpgrades").Event:Connect(apply)


