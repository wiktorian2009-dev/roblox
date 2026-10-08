-- SnowFieldService: PERSONAL fields with tile HP.
-- Each tile has a phase (0-3 layers left) and HP for its top layer.
-- The snowplow blade deals clearing damage to each contacted tile; at 0 HP the layer breaks and pays out.
-- Updates are sent only to the owning player as triples: index, phase, hpPercent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent:WaitForChild("DataService"))
local SF = require(ReplicatedStorage:WaitForChild("SnowFields"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local treasureModule = script.Parent:FindFirstChild("TreasureService")
local okTreasures, Treasures = false, nil
if treasureModule then okTreasures, Treasures = pcall(require, treasureModule) end
if not okTreasures then warn("[SnowFieldService] TreasureService unavailable: " .. tostring(Treasures)); Treasures = nil end
local treasureWarned = false
local updateEvent = ReplicatedStorage:WaitForChild("SnowFieldUpdate")
local syncFunc = ReplicatedStorage:WaitForChild("SnowFieldSync")
local collectedEvent = ReplicatedStorage:WaitForChild("SnowCollected")
local PlowConfig = require(ReplicatedStorage:WaitForChild("PlowConfig"))
local PlowRegistry = require(script.Parent:WaitForChild("PlowRegistry"))

local TICK = 0.2
local TS = SF.TileSize
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

Players.PlayerRemoving:Connect(function(p)
	states[p] = nil
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

-- Dig combo (2026-10-04, Claude, v2): grows with TIME spent digging without a pause, not per payout. Level n needs
-- COMBO_SECONDS * n^1.25 s (level 10 ~45 s, max level 20 = x2 Snow ~1 min 45 s); a COMBO_WINDOW pause resets it.
local COMBO_WINDOW, COMBO_STEP, COMBO_MAX, COMBO_SECONDS = 2.5, 0.05, 20, 2.5
local combos = {}
game:GetService("Players").PlayerRemoving:Connect(function(p) combos[p] = nil end)

-- Only the vehicle's blade clears fields. Everything is computed here from the server's own copy of the build,
-- the replicated hull position and the clock - nothing the client reports.
local function payoutPlow(player, gained, layers, now)
	local pets = {}
	for n in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(pets, n) end
	gained = math.max(1, math.floor(gained * (1 + (PetConfig.Multiplier(pets) - 1) * (player:GetAttribute("PetBoostMult") or 1)) * (player:GetAttribute("SnowMult") or 1) + 0.5))
	local c = combos[player] or {start = now, last = 0, count = 0}
	if now - c.last > COMBO_WINDOW then c.start = now end
	c.last = now
	c.count = math.min(COMBO_MAX, math.floor(((now - c.start) / COMBO_SECONDS) ^ 0.8))
	combos[player] = c
	local comboMult = 1 + c.count * COMBO_STEP
	gained = math.floor(gained * comboMult + 0.5)
	player:SetAttribute("Combo", c.count)
	DataService.AddSnow(player, gained)
	collectedEvent:FireClient(player, gained, c.count, layers, comboMult)
end
local function collect(player, st, now)
	if player:GetAttribute("IntroActive") then return end
	local v = PlowRegistry.Active[player]
	if not v or not v.hull or not v.hull.Parent then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or hum.SeatPart ~= v.seat then v.lastCF = nil return end
	local cf = v.hull.CFrame
	if (root.Position - cf.Position).Magnitude > PlowConfig.Vehicle.MaxRiderGap then v.lastCF = nil return end
	local prevCF, prevT = v.lastCF, v.lastT
	v.lastCF, v.lastT = cf, now
	if not prevCF then return end
	local dt = now - prevT
	if dt < 0.02 or dt > 1.2 then return end
	local move = Vector3.new(cf.X - prevCF.X, 0, cf.Z - prevCF.Z).Magnitude
	local stats, CL = v.stats, PlowConfig.Clearing
	if move / dt > stats.MaxSpeed * CL.SpeedTolerance + 8 then v.flags = (v.flags or 0) + 1 return end -- implausible movement: no clearing this tick
	if not stats.HasBlade or stats.ClearPower <= 0 then return end
	local W, off = stats.BladeWidth, PlowConfig.Vehicle.BladeOffset
	local half, halfD = W / 2 + TS * CL.TileSlack, CL.BladeDepth / 2 + TS * CL.TileSlack
	local K = math.clamp(math.ceil(move / (TS * 0.5)) + 1, 1, 12)
	local slice = dt / K
	local gained, layers = 0, 0
	for id, d in pairs(defs) do
		local f, origin, maxHP = d.def, d.origin, d.maxHP
		if f.Style and f.Style ~= "Starter" and player:GetAttribute("Stage_" .. f.Style) ~= true then continue end -- stage locked
		local lx, lz = cf.X - origin.X, cf.Z - origin.Z
		local m = W + off + 8
		if lx > -m and lz > -m and lx < f.Width * TS + m and lz < f.Depth * TS + m and math.abs(cf.Y - origin.Y) < 14 then
			local s = st[id]
			local tough = math.clamp((math.log10(maxHP) - CL.ToughLow) / CL.ToughSpan, 0, 1)
			local dmgPerSlice = stats.ClearPower * (stats.Soft + (stats.Hard - stats.Soft) * tough) * slice
			local contact = {}
			for k = 1, K do
				local c = prevCF:Lerp(cf, k / K)
				local lv = c.LookVector
				local fl = math.sqrt(lv.X * lv.X + lv.Z * lv.Z)
				if fl > 1e-3 then
					local fx, fz = lv.X / fl, lv.Z / fl
					local rx, rz = -fz, fx
					local cx, cz = c.X + fx * off - origin.X, c.Z + fz * off - origin.Z
					local hx = math.abs(rx) * half + math.abs(fx) * halfD
					local hz = math.abs(rz) * half + math.abs(fz) * halfD
					local x0, x1 = math.max(0, math.floor((cx - hx) / TS)), math.min(f.Width - 1, math.floor((cx + hx) / TS))
					local z0, z1 = math.max(0, math.floor((cz - hz) / TS)), math.min(f.Depth - 1, math.floor((cz + hz) / TS))
					for x = x0, x1 do
						for z = z0, z1 do
							local i = z * f.Width + x + 1
							if s.phases[i] > 0 then
								local dx, dz = (x + 0.5) * TS - cx, (z + 0.5) * TS - cz
								if math.abs(dx * fx + dz * fz) <= halfD and math.abs(dx * rx + dz * rz) <= half then contact[i] = (contact[i] or 0) + 1 end
							end
						end
					end
				end
			end
			for i, n in pairs(contact) do
				local hp = s.hp[i] - dmgPerSlice * n
				local p = s.phases[i]
				while hp <= 0 and p > 0 do p -= 1; gained += f.SnowPerPhase; layers += 1; hp += maxHP end
				if p == 0 then
					hp = maxHP
					if Treasures then
						local x, z = (i - 1) % f.Width, math.floor((i - 1) / f.Width)
						local okT, errT = pcall(Treasures.TileCleared, player, f, SF.TileCenter(f, x, z))
						if not okT and not treasureWarned then treasureWarned = true; warn("[Treasures] " .. tostring(errT)) end
					end
				end
				s.phases[i] = p
				s.hp[i] = hp
				s.pending[i] = true
			end
		end
	end
	if gained > 0 then payoutPlow(player, gained, layers, now) end
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

