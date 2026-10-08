-- SnowFieldService: PERSONAL fields with tile HP.
-- Each tile has a phase (0-3 layers left) and HP for its top layer.
-- Every shovel arm that sweeps over a tile deals its Power as damage; at 0 HP the layer breaks and pays out.
-- Updates are sent only to the owning player as triples: index, phase, hpPercent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent:WaitForChild("DataService"))
local SF = require(ReplicatedStorage:WaitForChild("SnowFields"))
local Config = require(ReplicatedStorage:WaitForChild("RNGConfig"))
local Balance = require(ReplicatedStorage:WaitForChild("Balance"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local updateEvent = ReplicatedStorage:WaitForChild("SnowFieldUpdate")
local syncFunc = ReplicatedStorage:WaitForChild("SnowFieldSync")
local collectedEvent = ReplicatedStorage:WaitForChild("SnowCollected")

local TICK = 0.2
local TS = SF.TileSize
local SPEED = SF.Spinner.Speed
local R_IN, R_OUT = SF.Spinner.Inner, SF.Spinner.Outer
local TWO_PI = math.pi * 2
local MAX = SF.MaxPhase

local defs = {}
for _, f in ipairs(SF.Fields) do
	defs[f.Id] = {def = f, origin = SF.Origin(f), maxHP = math.max(1, f.TileHP or 1)}
end

-- states[player][fieldId] = {phases = {}, hp = {}, pending = {}}
local states = {}
local function getStates(player)
	local st = states[player]
	if not st then
		st = {}
		for id, d in pairs(defs) do
			local n = d.def.Width * d.def.Depth
			st[id] = {phases = table.create(n, MAX), hp = table.create(n, d.maxHP), pending = {}}
		end
		states[player] = st
	end
	return st
end

local lastTime = {}
Players.PlayerRemoving:Connect(function(p)
	states[p] = nil
	lastTime[p] = nil
end)

local function pct(hp, maxHP) return math.clamp(math.floor(hp / maxHP * 100 + 0.5), 0, 100) end

syncFunc.OnServerInvoke = function(player)
	local out = {}
	for id, s in pairs(getStates(player)) do
		local maxHP = defs[id].maxHP
		local hp = table.create(#s.hp, 100)
		for i, v in ipairs(s.hp) do hp[i] = pct(v, maxHP) end
		out[id] = {p = table.concat(s.phases), h = hp}
	end
	return out
end

local function flush(player, st)
	for id, s in pairs(st) do
		if next(s.pending) then
			local maxHP = defs[id].maxHP
			local flat = {}
			for i in pairs(s.pending) do
				flat[#flat + 1] = i
				flat[#flat + 1] = s.phases[i]
				flat[#flat + 1] = pct(s.hp[i], maxHP)
			end
			s.pending = {}
			updateEvent:FireClient(player, id, flat)
		end
	end
end

-- damage per arm, from each equipped shovel's Power
local function armPowers(player)
	local attr = player:GetAttribute("EquippedShovels")
	local list = {}
	if not attr or attr == "" then return list end
	for name in attr:gmatch("[^,]+") do
		local item = Config.ByName[name]
		table.insert(list, item and (item.Power or Balance.ShovelPower(item.Chance)) or 1)
	end
	return list
end

local function collect(player, st, now)
	local prev = lastTime[player]
	lastTime[player] = now
	if not prev then return end
	local powers = armPowers(player)
	local spd = SPEED * (player:GetAttribute("SpinMult") or 1)
	local rOut = R_OUT * (player:GetAttribute("ReachMult") or 1)
	local bonus = player:GetAttribute("PowerBonus") or 0
	local pmult = player:GetAttribute("PowerMult") or 1
	local n = #powers
	if n == 0 then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local sweep = math.min((now - prev) * spd, TWO_PI)
	local pos = root.Position
	local gained = 0

	for id, d in pairs(defs) do
		local f, origin, maxHP = d.def, d.origin, d.maxHP
		if f.Style and f.Style ~= "Starter" and player:GetAttribute("Stage_" .. f.Style) ~= true then continue end -- stage locked
		local lx, lz = pos.X - origin.X, pos.Z - origin.Z
		if lx > -rOut and lz > -rOut and lx < f.Width * TS + rOut and lz < f.Depth * TS + rOut
			and math.abs(pos.Y - origin.Y) < 9 then
			local s = st[id]
			local x0 = math.max(0, math.floor((lx - rOut) / TS))
			local x1 = math.min(f.Width - 1, math.floor((lx + rOut) / TS))
			local z0 = math.max(0, math.floor((lz - rOut) / TS))
			local z1 = math.min(f.Depth - 1, math.floor((lz + rOut) / TS))
			for k = 0, n - 1 do
				local dmg = (powers[k + 1] + bonus) * pmult
				local a0 = prev * spd + k * (TWO_PI / n) + (player.UserId % 7)
				for x = x0, x1 do
					for z = z0, z1 do
						local i = z * f.Width + x + 1
						if s.phases[i] > 0 then
							local dx = origin.X + (x + 0.5) * TS - pos.X
							local dz = origin.Z + (z + 0.5) * TS - pos.Z
							local d2 = dx * dx + dz * dz
							if d2 >= R_IN * R_IN and d2 <= rOut * rOut
								and (math.atan2(dz, dx) - a0) % TWO_PI <= sweep then
								local hp = s.hp[i] - dmg
								local p = s.phases[i]
								-- strong shovels can break several layers in one hit
								while hp <= 0 and p > 0 do
									p -= 1
									gained += f.SnowPerPhase
									hp += maxHP
								end
								if p == 0 then hp = maxHP end
								s.phases[i] = p
								s.hp[i] = hp
								s.pending[i] = true
							end
						end
					end
				end
			end
		end
	end

	if gained > 0 then
		-- equipped pets boost the snow you earn
		local pets = {}
		for n in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(pets, n) end
		gained = math.max(1, math.floor(gained * (1 + (PetConfig.Multiplier(pets) - 1) * (player:GetAttribute("PetBoostMult") or 1)) * (player:GetAttribute("SnowMult") or 1) + 0.5))
		DataService.AddSnow(player, gained)
		collectedEvent:FireClient(player, gained)
	end
end

local function regrow(st)
	for id, s in pairs(st) do
		local d = defs[id]
		local chance = 1 / d.def.RegrowSeconds
		for i, p in ipairs(s.phases) do
			if p < MAX and math.random() < chance then
				s.phases[i] = p + 1
				s.hp[i] = d.maxHP
				s.pending[i] = true
			end
		end
	end
end

local acc, regrowAcc = 0, 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	regrowAcc += dt
	if acc < TICK then return end
	acc = 0
	local doRegrow = regrowAcc >= 1
	if doRegrow then regrowAcc = 0 end
	local now = workspace:GetServerTimeNow()
	for _, player in ipairs(Players:GetPlayers()) do
		local st = getStates(player)
		collect(player, st, now)
		if doRegrow then regrow(st) end
		flush(player, st)
	end
end)

