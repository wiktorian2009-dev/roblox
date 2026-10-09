-- PassService (2026-10-05, Claude, task 8): game-pass ownership and grants for the three paid offers (PassConfig).
-- * Ownership is checked ON THE SERVER with MarketplaceService:UserOwnsGamePassAsync (bounded retries) after the profile loads,
--   and again after PromptGamePassPurchaseFinished(purchased = true) before granting. No client remote can grant anything.
-- * Grants are idempotent and persist in the profile (d.Passes): the Starter Pack Snow is given once per profile (marker StarterSnow),
--   parts are only added when missing (never duplicated, never auto-equipped), 1.5x Snow is the PassSnowMult attribute that
--   UpgradeService folds into SnowMult exactly once.
-- * Passes are not developer products: nothing here uses ProcessReceipt.
-- * Studio isolated tests (ServerStorage.BalanceTestMode): ServerStorage.PassTestHook mocks ownership / API failures / purchase callbacks.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local MPS = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local DataService = require(script.Parent:WaitForChild("DataService"))
local P = require(RS:WaitForChild("PassConfig"))
local TEST = RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true

local remote = RS:FindFirstChild("PassRemote") or Instance.new("RemoteFunction")
remote.Name = "PassRemote"; remote.Parent = RS
local event = RS:FindFirstChild("PassEvent") or Instance.new("RemoteEvent")
event.Name = "PassEvent"; event.Parent = RS

local mock = {}   -- TEST only: [player] = {owned = {Key = true}, fail = n}
local function ownsOnce(player, pass)
	if TEST and mock[player] then
		local m = mock[player]
		if (m.fail or 0) > 0 then m.fail -= 1; error("mock UserOwnsGamePassAsync failure") end
		return m.owned[pass.Key] == true
	end
	if not pass.Id then return false end
	return MPS:UserOwnsGamePassAsync(player.UserId, pass.Id)
end
-- bounded retries for transient API errors; returns owned, known (known = false when every attempt failed)
local function checkOwned(player, pass)
	for attempt = 1, 4 do
		local ok, res = pcall(ownsOnce, player, pass)
		if ok then return res == true, true end
		if not player.Parent then return false, false end
		task.wait(TEST and 0.05 or attempt * 1.5)
	end
	return false, false
end

local function reapplyUpgrades(player)
	local hooks = SS:FindFirstChild("AdminHooks")
	local ev = hooks and hooks:FindFirstChild("ReapplyUpgrades")
	if ev then ev:Fire(player) end
end

local function grant(player, pass)
	local d = DataService.Get(player)
	if not d or not d.Plow then return false end
	d.Passes = type(d.Passes) == "table" and d.Passes or {}
	local new = d.Passes[pass.Key] == nil
	if new then d.Passes[pass.Key] = os.time() end
	if pass.Key == "SnowBoost" then
		if player:GetAttribute("PassSnowMult") ~= P.SnowMult then
			player:SetAttribute("PassSnowMult", P.SnowMult)
			reapplyUpgrades(player)
		end
	end
	for _, id in ipairs(pass.Parts or {}) do
		if (tonumber(d.Plow.Parts[id]) or 0) < 1 then d.Plow.Parts[id] = 1 end -- never duplicated, never auto-equipped
	end
	if pass.Snow and not d.Passes.StarterSnow then -- once per profile (not on rejoin / respawn / rebirth / repeated callbacks)
		d.Passes.StarterSnow = os.time()
		DataService.AddSnow(player, pass.Snow)
	end
	local first = player:GetAttribute("Pass_" .. pass.Key) ~= true
	player:SetAttribute("Pass_" .. pass.Key, true)
	if first then event:FireClient(player, "Granted", pass.Key, new) end
	return true
end

local ALL = table.clone(P.Passes) -- 2026-10-09: HUD passes + perk passes (Quick Rolls: Pass_QuickRolls, nothing else to grant)
for _, p in ipairs(P.Perks or {}) do table.insert(ALL, p) end
local function checkAll(player)
	for _, pass in ipairs(ALL) do
		task.spawn(function()
			local owned, known = checkOwned(player, pass)
			if owned then grant(player, pass) end
			if not known then player:SetAttribute("PassCheckFailed", true) end
		end)
	end
end
DataService.OnLoaded(function(player) checkAll(player) end)

local function onFinished(player, pass, purchased)
	if not (pass and purchased) then return end
	local owned = checkOwned(player, pass) -- verify with Roblox before granting
	if owned then grant(player, pass) end
end
MPS.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	onFinished(player, P.ById[passId], purchased)
end)

remote.OnServerInvoke = function(player, action)
	if action == "State" then
		local owned = {}
		for _, pass in ipairs(P.Passes) do owned[pass.Key] = player:GetAttribute("Pass_" .. pass.Key) == true end
		return {ok = true, owned = owned, salesEnabled = P.SalesEnabled == true}
	end
	return {ok = false}
end
Players.PlayerRemoving:Connect(function(p) mock[p] = nil end)

if TEST then
	local hook = Instance.new("BindableFunction"); hook.Name = "PassTestHook"
	hook.OnInvoke = function(op, player, key, value)
		mock[player] = mock[player] or {owned = {}, fail = 0}
		local m = mock[player]
		if op == "Mock" then m.owned[key] = value == true; return true
		elseif op == "Fail" then m.fail = tonumber(key) or 0; return true
		elseif op == "Recheck" then checkAll(player); task.wait(0.5); return true
		elseif op == "Finished" then onFinished(player, P.ByKey[key], value == true); return true
		elseif op == "Data" then local d = DataService.Get(player); return d and d.Passes and table.clone(d.Passes) or {}
		end
		return nil
	end
	hook.Parent = SS
end
