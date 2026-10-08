-- World2Activities (2026-10-02, Claude): small optional World 2 discoveries, all validated here.
-- A point is any Model/BasePart under Workspace.World2 with attribute Activity = <Id> from ACT below.
-- Checks: stage unlocked (server-set Stage_<Id>), player within 16 studs, per-player cooldown saved in the profile (d.W2Activities).
-- Snow rewards = N fully dug tiles of that stage (3 layers x SnowPerPhase) x the player's live snow/pet multipliers.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local BoostService = require(script.Parent:WaitForChild("BoostService"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local NumberFormat = require(RS:WaitForChild("NumberFormat"))
local notice = RS:FindFirstChild("World2Notice") or Instance.new("RemoteEvent")
notice.Name = "World2Notice"
notice.Parent = RS

local ACT = {
	KoiShrine  = {Stage = "Sakura", Action = "Make a wish", Object = "Koi Shrine",  Cooldown = 1200, Boost = "Luck2", Seconds = 150,
		Text = "The golden koi blesses you: 2x Luck for 2.5 minutes!"},
	SugarChest = {Stage = "Candy",  Action = "Open",        Object = "Sugar Chest", Cooldown = 900,  Tiles = 250,
		Text = "Sugar Chest: +%s Snow!"},
	GiantClam  = {Stage = "Atlantis", Action = "Open",      Object = "Giant Clam",  Cooldown = 1500, Boost = "Super", Seconds = 60,
		Text = "The giant clam shares its pearl: Super Boost (2x Snow & Luck) for 1 minute!"},
	PrizeBox   = {Stage = "Toybox", Action = "Open",        Object = "Prize Box",   Cooldown = 1200, Boost = "Snow2", Seconds = 120,
		Text = "Surprise! The prize box gives you 2x Snow for 2 minutes!"},
	ClockCrank = {Stage = "Clockwork", Action = "Wind up",   Object = "Clock Crank", Cooldown = 900,  Tiles = 300,
		Text = "Tick-tock! The Clock Crank pays out +%s Snow!"},
	SkyBell    = {Stage = "Cloud", Action = "Ring",         Object = "Sky Bell",    Cooldown = 1200, Boost = "Luck2", Seconds = 180,
		Text = "Ding! The Sky Bell blesses you: 2x Luck for 3 minutes!"},
	StarAltar  = {Stage = "Cosmic", Action = "Make a wish", Object = "Star Altar",  Cooldown = 1800, Boost = "Super", Seconds = 120,
		Text = "Your wish comes true: Super Boost (2x Snow & Luck) for 2 minutes!"},
}

local last = {}
local function snowFor(player, stageId, tiles)
	local st = RS.SnowStages:FindFirstChild(stageId)
	local spp = st and (st:GetAttribute("SnowPerPhase") or 1) / math.max(1, st:GetAttribute("TileScale") or 1) or 1 -- 2026-10-04: rewards stay in old-tile units
	local pets = {}
	for n in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(pets, n) end
	local petF = 1 + (PetConfig.Multiplier(pets, player) - 1) * (player:GetAttribute("PetBoostMult") or 1)
	return math.floor(tiles * 3 * spp * petF * (player:GetAttribute("SnowMult") or 1) + 0.5)
end

local function claim(player, id, part)
	local a = ACT[id]
	local d = a and DataService.Get(player)
	if not d then return end
	if last[player] and os.clock() - last[player] < 1 then return end
	last[player] = os.clock()
	if player:GetAttribute("Stage_" .. a.Stage) ~= true then notice:FireClient(player, "Unlock this stage first!", false) return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - part.Position).Magnitude > 16 then return end
	d.W2Activities = type(d.W2Activities) == "table" and d.W2Activities or {}
	local now = os.time()
	local left = a.Cooldown - (now - (tonumber(d.W2Activities[id]) or 0))
	if left > 0 then
		notice:FireClient(player, ("%s is recharging: %d:%02d"):format(a.Object, left // 60, left % 60), false)
		return
	end
	d.W2Activities[id] = now
	if a.Boost then
		BoostService.Add(player, a.Boost, a.Seconds)
		notice:FireClient(player, a.Text, true)
	elseif a.Tiles then
		local amount = snowFor(player, a.Stage, a.Tiles)
		DataService.AddSnow(player, amount)
		notice:FireClient(player, a.Text:format(NumberFormat.Abbreviate(amount)), true)
	end
end

local function setup(obj)
	local id = obj:GetAttribute("Activity")
	local a = id and ACT[id]
	if not a or obj:GetAttribute("ActivityReady") then return end
	local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
	if not part then return end
	obj:SetAttribute("ActivityReady", true)
	local p = Instance.new("ProximityPrompt")
	p.Name = "ActivityPrompt"
	p.ActionText = a.Action
	p.ObjectText = a.Object
	p.HoldDuration = 0.5
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = part
	p.Triggered:Connect(function(plr) claim(plr, id, part) end)
end

local w2 = workspace:WaitForChild("World2")
for _, d in ipairs(w2:GetDescendants()) do if d:GetAttribute("Activity") then setup(d) end end
w2.DescendantAdded:Connect(function(d) if d:GetAttribute("Activity") then task.defer(setup, d) end end)
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)

-- STUDIO TEST HOOK (isolated BalanceTestMode sessions only; Claude 2026-10-03): ServerStorage.W2PlaytestHook:Invoke(action, player, arg)
-- Test-mode sessions neither load nor save real data (see DataService), so this cannot touch real progress.
if game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("BalanceTestMode") == true then
	local hook = Instance.new("BindableFunction"); hook.Name = "W2PlaytestHook"
	hook.OnInvoke = function(action, player, arg)
		local d = player and DataService.Get(player)
		if not d then return nil end
		if action == "AddSnow" then DataService.AddSnow(player, tonumber(arg) or 0); return d.Snow end
		if action == "Info" then
			local pets, list = 0, {}
			for n, c in pairs(d.Pets or {}) do pets += c; table.insert(list, n .. " x" .. c) end
			local st = {}
			for k, v in pairs(d.Stages or {}) do if v then table.insert(st, k) end end
			table.sort(st)
			local act = {}
			for k in pairs(d.W2Activities or {}) do table.insert(act, k) end
			return {Snow = d.Snow, Stages = table.concat(st, ","), Pets = pets, PetList = table.concat(list, ", "), W2Act = table.concat(act, ",")}
		end
		return nil
	end
	hook.Parent = game:GetService("ServerStorage")
end
