-- AdminService: ;commands in chat or through the F2 admin console. Everything is checked here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent:WaitForChild("DataService"))
local PlowConfig = require(ReplicatedStorage:WaitForChild("PlowConfig"))
local PlowRules = require(script.Parent:WaitForChild("PlowRules"))
local Registry = require(script.Parent:WaitForChild("PlowRegistry"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local SnowFields = require(ReplicatedStorage:WaitForChild("SnowFields"))
local U = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local AdminConfig = require(ServerStorage:WaitForChild("AdminConfig"))
local cmdEvent = ReplicatedStorage:WaitForChild("AdminCommand")
local refreshEvent = ReplicatedStorage:WaitForChild("DataRefresh")
local reapply = ServerStorage:WaitForChild("AdminHooks"):WaitForChild("ReapplyUpgrades")
local consoleTemplate = ServerStorage:WaitForChild("AdminConsole")

local PREFIX = AdminConfig.Prefix or ";"

local function isAdmin(p)
	if RunService:IsStudio() then return true end
	if game.CreatorType == Enum.CreatorType.User and p.UserId == game.CreatorId then return true end
	return table.find(AdminConfig.Admins, p.UserId) ~= nil
end

--------------------------------------------------
-- helpers
--------------------------------------------------
local SUFFIX = {k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18}
local function amount(s)
	if not s then return nil end
	s = s:lower():gsub(",", "")
	local num, suf = s:match("^(%-?[%d%.]+)(%a*)$")
	num = tonumber(num)
	if not num then return nil end
	if suf ~= "" then
		if not SUFFIX[suf] then return nil end
		num *= SUFFIX[suf]
	end
	return num
end

local function targets(caller, s)
	if not s or s == "" or s:lower() == "me" then return {caller} end
	if s:lower() == "all" then return Players:GetPlayers() end
	local q = s:lower()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q then return {p} end
	end
	return {}
end

-- Finds a part or pet by its name.
local function find(list, q)
	q = (q or ""):lower()
	if q == "" then return nil end
	for _, it in ipairs(list) do if it.Name:lower() == q then return it end end
	for _, it in ipairs(list) do if it.Name:lower():sub(1, #q) == q then return it end end
	for _, it in ipairs(list) do if it.Name:lower():find(q, 1, true) then return it end end
	return nil
end

local allPets = {}
for _, egg in ipairs(PetConfig.Eggs) do for _, p in ipairs(egg.Pets) do table.insert(allPets, p) end end

local function refresh(p) refreshEvent:FireClient(p) end

--------------------------------------------------
-- commands
--------------------------------------------------
local COMMANDS = {}
local ORDER = {}
local function command(name, usage, fn)
	COMMANDS[name] = {usage = usage, fn = fn}
	table.insert(ORDER, name)
end

command("help", "help", function(caller)
	local lines = {}
	for _, n in ipairs(ORDER) do table.insert(lines, PREFIX .. COMMANDS[n].usage) end
	return table.concat(lines, "\n")
end)

command("snow", "snow <amount> [player]  (1k 2.5m 3b 1t) - give snow", function(caller, args)
	local n = amount(args[1]); if not n then return nil, "Usage: " .. PREFIX .. "snow 1m" end
	local out = {}
	for _, p in ipairs(targets(caller, args[2])) do
		DataService.AddSnow(p, n)
		table.insert(out, p.Name)
	end
	return "Gave " .. NumberFormat.Abbreviate(n) .. " snow to " .. table.concat(out, ", ")
end)

command("setsnow", "setsnow <amount> [player] - set snow exactly", function(caller, args)
	local n = amount(args[1]); if not n then return nil, "Usage: " .. PREFIX .. "setsnow 0" end
	for _, p in ipairs(targets(caller, args[2])) do
		local d = DataService.Get(p)
		if d then DataService.AddSnow(p, n - d.Snow) end
	end
	return "Snow set to " .. NumberFormat.Abbreviate(n)
end)

command("part", "part <id/name> [count] [player] - give a vehicle part", function(caller, args)
	local list = {}
	for id, def in pairs(PlowConfig.Parts) do table.insert(list, {Id=id, Name=def.Name}) end
	local it = PlowConfig.Parts[args[1] or ""] and {Id=args[1], Name=PlowConfig.Parts[args[1]].Name} or find(list,args[1])
	if not it then return nil, "Unknown vehicle part" end
	local count = math.clamp(math.floor(amount(args[2]) or 1), 1, PlowConfig.Shop.MaxOwned)
	for _, p in ipairs(targets(caller,args[3])) do
		local d = DataService.Get(p)
		if d then d.Plow.Parts[it.Id] = math.min(PlowConfig.Shop.MaxOwned,(d.Plow.Parts[it.Id] or 0)+count); refresh(p) end
	end
	return "Gave " .. count .. "x " .. it.Name
end)

command("pet", "pet <name> [count] [player] - give a pet", function(caller, args)
	local pet = find(allPets, args[1]); if not pet then return nil, "No pet called '" .. tostring(args[1]) .. "'" end
	local count = math.max(1, math.floor(amount(args[2]) or 1))
	for _, p in ipairs(targets(caller, args[3])) do
		local d = DataService.Get(p)
		if d then
			d.Pets[pet.Name] = (d.Pets[pet.Name] or 0) + count
			d.PetIndex[pet.Name] = true
			refresh(p)
		end
	end
	return "Gave " .. count .. "x " .. pet.Name
end)

command("luck", "luck <multiplier> [player] - set base luck (1 = normal)", function(caller, args)
	local n = amount(args[1]); if not n or n <= 0 then return nil, "Usage: " .. PREFIX .. "luck 1000" end
	for _, p in ipairs(targets(caller, args[2])) do
		local d = DataService.Get(p)
		if d then d.Luck = n end
	end
	return "Base luck set to " .. NumberFormat.Abbreviate(n) .. "x"
end)

command("upgrades", "upgrades all|reset [player] - unlock or clear all upgrade tiles", function(caller, args)
	local mode = (args[1] or ""):lower()
	if mode ~= "all" and mode ~= "reset" then return nil, "Usage: " .. PREFIX .. "upgrades all  /  " .. PREFIX .. "upgrades reset" end
	for _, p in ipairs(targets(caller, args[2])) do
		local d = DataService.Get(p)
		if d then
			d.Upgrades = {}
			if mode == "all" then for id in pairs(U.ById) do d.Upgrades[id] = true end end
			reapply:Fire(p)
		end
	end
	return mode == "all" and "Unlocked every upgrade tile" or "Cleared all upgrade tiles"
end)

command("speed", "speed <number> [player] - walk speed until respawn", function(caller, args)
	local n = amount(args[1]); if not n then return nil, "Usage: " .. PREFIX .. "speed 50" end
	for _, p in ipairs(targets(caller, args[2])) do
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = n end
	end
	return "Walk speed set to " .. n
end)

command("tp", "tp <field / stage / player> - teleport yourself", function(caller, args)
	local q = (args[1] or ""):lower()
	local root = caller.Character and caller.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil, "No character" end
	for _, f in ipairs(SnowFields.Fields) do
		if f.Id:lower() == q or (f.Style or ""):lower() == q or f.Id:lower():sub(1, #q) == q then
			caller.Character:PivotTo(CFrame.new(f.Center + Vector3.new(0, 5, 0)))
			return "Teleported to field " .. f.Id
		end
	end
	local t = targets(caller, args[1])[1]
	if t and t ~= caller and t.Character then
		caller.Character:PivotTo(t.Character:GetPivot() * CFrame.new(3, 0, 0))
		return "Teleported to " .. t.Name
	end
	if q == "spawn" then
		local sp = workspace:FindFirstChildOfClass("SpawnLocation")
		if sp then caller.Character:PivotTo(sp.CFrame + Vector3.new(0, 4, 0)); return "Teleported to spawn" end
	end
	local names = {}
	for _, f in ipairs(SnowFields.Fields) do table.insert(names, f.Id) end
	return nil, "Unknown place. Fields: " .. table.concat(names, ", ") .. ", spawn, or a player name"
end)

command("stages", "stages all|reset [player] - unlock or lock every stage", function(caller, args)
	local mode = (args[1] or ""):lower()
	if mode ~= "all" and mode ~= "reset" then return nil, "Usage: " .. PREFIX .. "stages all  /  " .. PREFIX .. "stages reset" end
	local S = require(ReplicatedStorage:WaitForChild("StageConfig"))
	for _, p in ipairs(targets(caller, args[2])) do
		local d = DataService.Get(p)
		if d then
			d.Stages = {}
			if mode == "all" then for _, st in ipairs(S.Order) do d.Stages[st.Id] = true end end
			ServerStorage.AdminHooks.ReapplyStages:Fire(p)
		end
	end
	return mode == "all" and "Unlocked every stage" or "Locked every stage"
end)

command("tutorial", "tutorial [player] - play the tutorial again", function(caller, args)
	for _, p in ipairs(targets(caller, args[1])) do
		local d = DataService.Get(p)
		if d then d.Plow.TutorialDone = false end
		p:SetAttribute("PlowTutorialDone", false)
		p:SetAttribute("PlowOffered", false)
		p:SetAttribute("PlowBought", false)
		p:SetAttribute("PlowEquipped", false)
		ReplicatedStorage.PlowEvent:FireClient(p, "TutorialReset")
	end
	return "Tutorial restarted"
end)

command("reset", "reset [player] - reset current game progress (careful!)", function(caller, args)
	for _, p in ipairs(targets(caller, args[1])) do
		local d = DataService.Get(p)
		if d then
			Registry.Park(p, "reset")
			d.Pets, d.EquippedPets, d.PetIndex, d.Upgrades, d.Settings, d.Stages = {}, {}, {}, {}, {}, {}
			d.Plow = nil
			PlowRules.Apply(d)
			d.TotalRolls, d.Luck, d.Rebirths = 0, 1, 0
			DataService.AddSnow(p, -d.Snow)
			DataService.SetStat(p, "Rolls", 0)
			p:SetAttribute("PlowTutorialDone", false)
			p:SetAttribute("PlowOffered", false)
			p:SetAttribute("PlowBought", false)
			p:SetAttribute("PlowEquipped", false)
			ReplicatedStorage.PlowEvent:FireClient(p, "TutorialReset")
			p:SetAttribute("EquippedPets", "")
			ServerStorage.AdminHooks.ReapplyStages:Fire(p)
			reapply:Fire(p)
			refresh(p)
		end
	end
	return "Progress reset"
end)

--------------------------------------------------
-- running commands
--------------------------------------------------
local function run(player, msg)
	if type(msg) ~= "string" or msg:sub(1, #PREFIX) ~= PREFIX then return end
	if not isAdmin(player) then return end
	local args = {}
	for w in msg:sub(#PREFIX + 1):gmatch("%S+") do table.insert(args, w) end
	local name = table.remove(args, 1)
	local cmd = name and COMMANDS[name:lower()]
	if not cmd then
		cmdEvent:FireClient(player, "Unknown command. Type " .. PREFIX .. "help", false)
		return
	end
	local ok, result, err = pcall(cmd.fn, player, args)
	if not ok then
		cmdEvent:FireClient(player, "Error: " .. tostring(result), false)
	elseif result then
		cmdEvent:FireClient(player, result, true)
	else
		cmdEvent:FireClient(player, err or "Failed", false)
	end
end

cmdEvent.OnServerEvent:Connect(run)

local function onPlayer(p)
	p.Chatted:Connect(function(msg) run(p, msg) end)
	if isAdmin(p) then
		local gui = consoleTemplate:Clone()
		gui.Parent = p:WaitForChild("PlayerGui")
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end


