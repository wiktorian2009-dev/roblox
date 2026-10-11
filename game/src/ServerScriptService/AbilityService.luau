-- AbilityService (2026-10-11, Claude): server side of ABILITY TOKENS (numbers: ReplicatedStorage.AbilityConfig).
-- Owns token identity, type, position, expiry, eligibility, pickup distance and buffs. Clients only draw tokens and ask to pick
-- one up by id; the server checks owner + distance from the player's character or their own seated plow, and consumes it once.
-- Drops come only from SnowFieldService's direct blade clearing in normal, unlocked fields (no AFK, minis, contracts, arena, boss).
-- Damage from abilities goes back through SnowFieldService (Bind) and never rolls new tokens. Nothing here is saved, except the
-- one-time intro flag (d.Settings.AbilityIntroSeen). Kill switch: ServerStorage attribute AbilityTokensOff = true.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local AC = require(ReplicatedStorage:WaitForChild("AbilityConfig"))
local SF = require(ReplicatedStorage:WaitForChild("SnowFields"))
local PlowConfig = require(ReplicatedStorage:WaitForChild("PlowConfig"))
local PlowRegistry = require(script.Parent:WaitForChild("PlowRegistry"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local M = {}
local DROP, PICK, AB = AC.Drop, AC.Pickup, AC.Abilities
local TS = SF.TileSize

local remote = ReplicatedStorage:FindFirstChild("AbilityToken") or Instance.new("RemoteEvent")
remote.Name = "AbilityToken"; remote.Parent = ReplicatedStorage

local fieldById = {}
for _, f in ipairs(SF.Fields) do fieldById[f.Id] = {def = f, origin = SF.Origin(f)} end

local api -- set by SnowFieldService: {hit = function(player, fieldId, indices, seconds) -> tilesHit, touchCombo = function(player, now)}
function M.Bind(t) api = t end

local rng = Random.new()
local nextId = 0
local P = {} -- P[player] = state
local stats = {spawns = 0, pickups = 0, magnet = 0, expired = 0, cleared = 0, rejected = 0, abilityTiles = 0, surgeSnow = 0, byType = {}}
M.Stats = stats

local function off() return ServerStorage:GetAttribute("AbilityTokensOff") == true end
local function now() return workspace:GetServerTimeNow() end

local function state(player)
	local s = P[player]
	if not s then
		s = {tokens = {}, count = 0, buffs = {}, aurora = nil, lastSpawn = -1e9, spawnTimes = {}, activeRoll = 0, activeSpawn = 0,
			lastActive = -1e9, tiles = 0, field = nil, lastPos = nil, reqWindow = 0, reqCount = 0}
		P[player] = s
	end
	return s
end

local function fieldAt(pos, margin)
	margin = margin or 0
	for id, e in pairs(fieldById) do
		local f, o = e.def, e.origin
		local lx, lz = pos.X - o.X, pos.Z - o.Z
		if lx >= -margin and lz >= -margin and lx <= f.Width * TS + margin and lz <= f.Depth * TS + margin and math.abs(pos.Y - o.Y) < 16 then
			return id, e
		end
	end
	return nil
end

-- the player's legitimate pickup bodies: their seated plow (hull + blade point) and/or their character's root
local function bodies(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return nil end
	local v = PlowRegistry.Active[player]
	if v and v.hull and v.hull.Parent and v.seat and hum.SeatPart == v.seat then
		local bw = (v.stats and v.stats.BladeWidth) or 6
		local r = math.clamp(math.max(bw / 2, 4) + PICK.VehiclePad, PICK.VehicleMin, PICK.VehicleMax)
		local cf = v.hull.CFrame
		return {cf.Position, cf:PointToWorldSpace(Vector3.new(0, 0, -PlowConfig.Vehicle.BladeOffset))}, r, cf, true, v
	end
	return {root.Position}, PICK.Walk, root.CFrame, false, v
end

local function send(player, ...) if player.Parent then remote:FireClient(player, ...) end end

local function publishBuffs(player, s)
	local t = now()
	local out = {}
	for id, e in pairs(s.buffs) do if e > t then out[id] = e end end
	local aur = s.aurora
	if aur and aur.ends > t then out.AuroraPatch = aur.ends end
	send(player, "buffs", out, aur and aur.ends > t and {pos = aur.pos, r = AB.AuroraPatch.Radius} or nil)
	local keep = out.ComboKeeper
	player:SetAttribute("ComboKeepUntil", keep)
end

local function removeToken(player, s, id, reason)
	local tk = s.tokens[id]
	if not tk then return nil end
	s.tokens[id] = nil
	s.count -= 1
	send(player, "remove", id, reason)
	return tk
end

local function clearTokens(player, s, reason)
	for id in pairs(s.tokens) do removeToken(player, s, id, reason or "clear"); stats.cleared += 1 end
end

local function clearAll(player, s, reason)
	clearTokens(player, s, reason)
	local had = next(s.buffs) ~= nil or s.aurora ~= nil
	s.buffs, s.aurora = {}, nil
	if had then publishBuffs(player, s) end
	player:SetAttribute("ComboKeepUntil", nil)
end
M.ClearAll = function(player, reason) local s = P[player]; if s then clearAll(player, s, reason) end end

-- ===== buffs read by SnowFieldService / the driving stats =====
local function active(s, id, t) local e = s and s.buffs[id]; return e ~= nil and e > (t or now()) end
function M.PowerMult(player, bladePos, fieldId)
	local s = P[player]
	if not s then return 1 end
	local t, m = now(), 1
	if active(s, "HeatedBlade", t) then m += AB.HeatedBlade.Power end
	local a = s.aurora
	if a and a.ends > t and a.fieldId == fieldId and bladePos then
		if Vector3.new(bladePos.X - a.pos.X, 0, bladePos.Z - a.pos.Z).Magnitude <= AB.AuroraPatch.Radius then m += AB.AuroraPatch.Power end
	end
	return m
end
function M.SnowBonus(player) local s = P[player]; return (s and active(s, "SnowSurge")) and AB.SnowSurge.Snow or 0 end
function M.SpeedMult(player) local s = P[player]; return (s and active(s, "TurboTracks")) and AB.TurboTracks.Speed or 1 end
function M.NoteSurge(extra) stats.surgeSnow += extra end

-- ===== drops =====
local function pickType()
	local r = rng:NextNumber() * AC.TotalWeight
	for _, id in ipairs(AC.Order) do
		r -= AB[id].Weight
		if r <= 0 then return id end
	end
	return AC.Order[1]
end

local function spotFor(s, e, hullCF)
	local f, o = e.def, e.origin
	local inset = DROP.EdgeInsetTiles
	local function ok(pos)
		local tx, tz = math.floor((pos.X - o.X) / TS), math.floor((pos.Z - o.Z) / TS)
		if tx < inset or tz < inset or tx > f.Width - 1 - inset or tz > f.Depth - 1 - inset then return nil end
		local c = SF.TileCenter(f, tx, tz)
		for _, tk in pairs(s.tokens) do
			if Vector3.new(tk.pos.X - c.X, 0, tk.pos.Z - c.Z).Magnitude < DROP.MinSpacing then return nil end
		end
		return Vector3.new(c.X, o.Y + DROP.FloatHeight, c.Z)
	end
	local look = Vector3.new(hullCF.LookVector.X, 0, hullCF.LookVector.Z)
	look = look.Magnitude > 1e-3 and look.Unit or Vector3.new(0, 0, -1)
	for _ = 1, 14 do
		local a = math.rad(rng:NextNumber(-DROP.SpawnCone, DROP.SpawnCone))
		local dir = CFrame.Angles(0, a, 0):VectorToWorldSpace(look)
		local p = ok(hullCF.Position + dir * rng:NextNumber(DROP.SpawnMin, DROP.SpawnMax))
		if p then return p end
	end
	for _ = 1, 14 do -- anywhere reachable in this field, not right under the plow
		local x = rng:NextInteger(inset, math.max(inset, f.Width - 1 - inset))
		local z = rng:NextInteger(inset, math.max(inset, f.Depth - 1 - inset))
		local c = SF.TileCenter(f, x, z)
		local d = Vector3.new(c.X - hullCF.X, 0, c.Z - hullCF.Z).Magnitude
		if d >= 9 and d <= 40 then
			local p = ok(c)
			if p then return p end
		end
	end
	return nil
end

local function spawnToken(player, s, e, hullCF, forced, kind)
	local pos = spotFor(s, e, hullCF)
	if not pos then return nil end
	local t = now()
	nextId += 1
	local id = nextId
	local tk = {id = id, kind = kind or pickType(), pos = pos, fieldId = e.def.Id, born = t, expires = t + DROP.Lifetime}
	s.tokens[id] = tk
	s.count += 1
	s.lastSpawn = t
	table.insert(s.spawnTimes, t)
	s.activeRoll, s.activeSpawn = 0, 0
	stats.spawns += 1
	stats.byType[tk.kind] = (stats.byType[tk.kind] or 0) + 1
	send(player, "spawn", {id = id, kind = tk.kind, pos = pos, expires = tk.expires, life = DROP.Lifetime, blink = DROP.BlinkAt, forced = forced == true})
	return tk
end

-- called by SnowFieldService once per tile whose LAST layer broke under the player's own blade in a normal, unlocked field
function M.TileCleared(player, f, hullCF)
	if off() or player:GetAttribute("AfkPlow") == true or player:GetAttribute("IntroActive") then return end
	local e = fieldById[f.Id]
	if not e then return end
	local s = state(player)
	local t = now()
	s.lastActive = t
	s.tiles += 1
	if s.count >= DROP.MaxVisible or t - s.lastSpawn < DROP.MinGap then return end
	local n = 0
	for i = #s.spawnTimes, 1, -1 do
		if t - s.spawnTimes[i] < 60 then n += 1 else table.remove(s.spawnTimes, i) end
	end
	if n >= DROP.PerMinute then return end
	local d = DataService.Get(player)
	if d and d.Settings and d.Settings.AbilityIntroSeen ~= true then
		if s.tiles >= DROP.FirstAfterTiles then
			local tk = spawnToken(player, s, e, hullCF, true, "TurboTracks") -- a friendly, easy-to-feel first power
			if tk then d.Settings.AbilityIntroSeen = true; send(player, "intro", AC.IntroText) end
		end
		return
	end
	local chance = 1 - math.exp(-s.activeRoll / DROP.MeanSeconds)
	local forced = s.activeSpawn >= DROP.PitySeconds
	s.activeRoll = 0 -- this tile rolled; the rest of the same pass rolls ~0
	if forced or rng:NextNumber() < chance then spawnToken(player, s, e, hullCF, forced) end
end

-- ===== activation =====
local function laneTiles(e, start, dir, length, halfW)
	local f, o = e.def, e.origin
	local rows = {}
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local steps = math.floor(length / TS)
	for k = 1, steps do
		local c = start + dir * (k * TS)
		local tx, tz = math.floor((c.X - o.X) / TS), math.floor((c.Z - o.Z) / TS)
		if tx < 0 or tz < 0 or tx > f.Width - 1 or tz > f.Depth - 1 then break end -- stops at the field boundary
		local row, seen = {}, {}
		for w = -halfW, halfW, TS * 0.5 do
			local p = c + right * w
			local x, z = math.floor((p.X - o.X) / TS), math.floor((p.Z - o.Z) / TS)
			if x >= 0 and z >= 0 and x < f.Width and z < f.Depth then
				local i = z * f.Width + x + 1
				if not seen[i] then seen[i] = true; table.insert(row, i) end
			end
		end
		table.insert(rows, {pos = c, tiles = row})
	end
	return rows
end

local function obstacleDistance(player, from, dir, length)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {}
	if player.Character then table.insert(ex, player.Character) end
	local v = PlowRegistry.Active[player]
	if v and v.model then table.insert(ex, v.model) elseif v and v.hull then table.insert(ex, v.hull.Parent) end
	params.FilterDescendantsInstances = ex
	params.RespectCanCollide = true
	local hit = workspace:Raycast(from + Vector3.new(0, 2.5, 0), dir * length, params)
	return hit and (hit.Position - (from + Vector3.new(0, 2.5, 0))).Magnitude or length
end

local function activate(player, s, tk)
	local def = AB[tk.kind]
	local t = now()
	local list, _, cf = bodies(player)
	if def.Kind == "buff" then
		local cur = s.buffs[tk.kind]
		local cap = t + (def.MaxStack or def.Duration)
		s.buffs[tk.kind] = (cur and cur > t) and math.min(cur + def.Duration, cap) or t + def.Duration
	elseif tk.kind == "AuroraPatch" then
		local cur = s.aurora
		local ends = (cur and cur.ends > t) and math.min(cur.ends + def.Duration, t + def.MaxStack) or t + def.Duration
		local e = fieldById[tk.fieldId]
		local floorY = e and e.origin.Y or (tk.pos.Y - DROP.FloatHeight)
		s.aurora = {pos = Vector3.new(tk.pos.X, floorY, tk.pos.Z), fieldId = tk.fieldId, ends = ends}
	elseif api and list then
		local fid, e = fieldAt(cf.Position, 2)
		if fid and fid == tk.fieldId then
			if tk.kind == "Snowburst" then
				local f, o = e.def, e.origin
				local c, r = cf.Position, def.Radius
				local idx = {}
				local x0, x1 = math.max(0, math.floor((c.X - r - o.X) / TS)), math.min(f.Width - 1, math.floor((c.X + r - o.X) / TS))
				local z0, z1 = math.max(0, math.floor((c.Z - r - o.Z) / TS)), math.min(f.Depth - 1, math.floor((c.Z + r - o.Z) / TS))
				for x = x0, x1 do
					for z = z0, z1 do
						local tc = SF.TileCenter(f, x, z)
						if Vector3.new(tc.X - c.X, 0, tc.Z - c.Z).Magnitude <= r then table.insert(idx, z * f.Width + x + 1) end
					end
				end
				stats.abilityTiles += api.hit(player, fid, idx, def.Seconds) or 0
				send(player, "fx", "Snowburst", {pos = Vector3.new(c.X, o.Y, c.Z), r = r})
			elseif tk.kind == "SnowLane" then
				local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
				look = look.Magnitude > 1e-3 and look.Unit or Vector3.new(0, 0, -1)
				local start = Vector3.new(list[#list].X, e.origin.Y, list[#list].Z)
				local len = math.min(def.Length, obstacleDistance(player, start, look, def.Length))
				local rows = laneTiles(e, start, look, len, def.HalfWidth)
				send(player, "fx", "SnowLane", {start = start, dir = look, len = #rows * TS, step = def.StepTime})
				task.spawn(function()
					for _, row in ipairs(rows) do
						if not player.Parent or P[player] ~= s then return end
						stats.abilityTiles += api.hit(player, fid, row.tiles, def.Seconds) or 0
						task.wait(def.StepTime)
					end
				end)
			end
		end
	end
	if def.Kind ~= "instant" then publishBuffs(player, s) end
	send(player, "activated", tk.kind, tk.pos)
end

local function inReach(list, r, pos)
	for _, b in ipairs(list) do
		local d = Vector3.new(b.X - pos.X, 0, b.Z - pos.Z).Magnitude
		if d <= r and math.abs(b.Y - pos.Y) < 12 then return true end
	end
	return false
end

local function consume(player, s, id, reason)
	local tk = removeToken(player, s, id, reason) -- one-time: gone from the table before anything is granted
	if not tk then return false end
	if reason == "magnet" then stats.magnet += 1 else stats.pickups += 1 end
	activate(player, s, tk)
	return true
end

remote.OnServerEvent:Connect(function(player, op, id)
	if op ~= "pickup" or type(id) ~= "number" then return end
	local s = P[player]
	if not s then return end
	local t = os.clock()
	if t - s.reqWindow > 1 then s.reqWindow, s.reqCount = t, 0 end
	s.reqCount += 1
	if s.reqCount > 25 then stats.rejected += 1 return end -- spam guard
	local tk = s.tokens[id]
	if not tk then stats.rejected += 1 return end -- unknown, someone else's, or already consumed
	local list, r = bodies(player)
	if not list or not inReach(list, r + PICK.Slack, tk.pos) then stats.rejected += 1 return end
	consume(player, s, id, "pick")
end)

-- ===== tick: expiry, server-side proximity pickup, magnet, cleanup on travel / field change / respawn, hull stats =====
local function hullAttrs(player, s, t)
	local v = PlowRegistry.Active[player]
	local hull = v and v.hull
	if not hull or not hull.Parent then return end
	local turbo = active(s, "TurboTracks", t)
	local want = turbo and AB.TurboTracks.Speed or nil
	if hull:GetAttribute("AbilitySpeed") ~= want then
		hull:SetAttribute("AbilitySpeed", want)
		hull:SetAttribute("AbilityGrip", turbo and AB.TurboTracks.Grip or nil)
	end
	local heat = active(s, "HeatedBlade", t) and (1 + AB.HeatedBlade.Power) or nil
	if hull:GetAttribute("AbilityPower") ~= heat then hull:SetAttribute("AbilityPower", heat) end
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.2 then return end
	local step = acc
	acc = 0
	local t = now()
	for player, s in pairs(P) do
		if not player.Parent then continue end
		-- active clearing time feeds the drop odds (only after the cooldown) and the pity timer
		if t - s.lastActive <= DROP.ActiveHold then
			s.activeSpawn += step
			if t - s.lastSpawn >= DROP.MinGap then s.activeRoll += step end
		end
		for id, tk in pairs(s.tokens) do
			if tk.expires <= t then removeToken(player, s, id, "expire"); stats.expired += 1 end
		end
		local list, r, cf = bodies(player)
		if list then
			-- travel (a big jump), or a different field than last time: tokens and temporary powers end
			local fid = fieldAt(cf.Position, 2)
			if s.lastPos and (cf.Position - s.lastPos).Magnitude > 70 then clearAll(player, s, "travel")
			elseif fid and s.field and fid ~= s.field then clearAll(player, s, "field") end
			s.lastPos = cf.Position
			if fid then s.field = fid
			elseif s.field and s.count > 0 then
				local e = fieldById[s.field]
				local o = e.origin
				local lx, lz = cf.X - o.X, cf.Z - o.Z
				local W, D = e.def.Width * TS, e.def.Depth * TS
				local out = math.max(-lx, lz - D, lx - W, -lz, 0)
				if out > 30 then clearTokens(player, s, "left"); s.aurora = nil; publishBuffs(player, s) end
			end
			if player:GetAttribute("AfkPlow") == true and s.count > 0 then clearTokens(player, s, "afk") end
			local magnet = active(s, "TokenMagnet", t)
			for id, tk in pairs(s.tokens) do
				if inReach(list, r, tk.pos) then consume(player, s, id, "pick")
				elseif magnet and inReach(list, AB.TokenMagnet.Radius, tk.pos) then consume(player, s, id, "magnet") end
			end
		end
		if active(s, "ComboKeeper", t) and api and api.touchCombo then api.touchCombo(player, t) end
		-- buffs that ran out
		local changed = false
		for id, e in pairs(s.buffs) do if e <= t then s.buffs[id] = nil; changed = true end end
		if s.aurora and s.aurora.ends <= t then s.aurora = nil; changed = true end
		if changed then publishBuffs(player, s) end
		hullAttrs(player, s, t)
	end
end)

local function hookCharacter(player)
	player.CharacterAdded:Connect(function()
		local s = P[player]
		if s then clearAll(player, s, "respawn"); s.lastPos = nil; s.field = nil end
	end)
end
Players.PlayerAdded:Connect(function(p) state(p); hookCharacter(p) end)
for _, p in ipairs(Players:GetPlayers()) do state(p); hookCharacter(p) end
Players.PlayerRemoving:Connect(function(p) P[p] = nil end)

-- Studio-only test hook (BalanceTestMode): spawn / grant / inspect without touching anything players can reach
if RunService:IsStudio() then
	task.defer(function()
		local hook = Instance.new("BindableFunction")
		hook.Name = "AbilityTestHook"
		hook.OnInvoke = function(op, player, a, b)
			if ServerStorage:GetAttribute("BalanceTestMode") ~= true then return "BalanceTestMode is off" end
			if op == "Stats" then return stats end
			local s = player and state(player)
			if op == "Spawn" then -- a = kind, b = optional Vector3 offset from the plow/character (else a normal spot)
				local list, _, cf = bodies(player)
				if not list then return "no body" end
				local fid, e = fieldAt(cf.Position, 2)
				if not fid then return "not on a field" end
				if b then
					nextId += 1
					local floorY = e.origin.Y
					local p = cf.Position + b
					local tk = {id = nextId, kind = a or pickType(), pos = Vector3.new(p.X, floorY + DROP.FloatHeight, p.Z), fieldId = fid, born = now(), expires = now() + DROP.Lifetime}
					s.tokens[tk.id] = tk; s.count += 1; stats.spawns += 1
					send(player, "spawn", {id = tk.id, kind = tk.kind, pos = tk.pos, expires = tk.expires, life = DROP.Lifetime, blink = DROP.BlinkAt})
					return tk.id
				end
				local tk = spawnToken(player, s, e, cf, true, a)
				return tk and tk.id or "no spot"
			elseif op == "Grant" then -- activate a kind directly (as if picked up where the player is)
				local list, _, cf = bodies(player)
				local fid = list and fieldAt(cf.Position, 2)
				activate(player, s, {kind = a, pos = list and list[1] or Vector3.zero, fieldId = fid})
				return true
			elseif op == "Pickup" then -- exercise the client request path from the server: a = id
				local tk = s.tokens[a]
				if not tk then return false end
				local list, r = bodies(player)
				if not list or not inReach(list, r + PICK.Slack, tk.pos) then return false end
				return consume(player, s, a, "pick")
			elseif op == "State" then
				local tk = {}
				for id, x in pairs(s.tokens) do tk[#tk + 1] = {id = id, kind = x.kind, pos = x.pos, left = x.expires - now()} end
				local bf = {}
				for id, e in pairs(s.buffs) do bf[id] = e - now() end
				return {tokens = tk, count = s.count, buffs = bf, aurora = s.aurora and (s.aurora.ends - now()) or nil, tiles = s.tiles,
					activeRoll = s.activeRoll, activeSpawn = s.activeSpawn, field = s.field}
			elseif op == "Clear" then clearAll(player, s, "test"); return true
			elseif op == "ResetIntro" then
				local d = DataService.Get(player)
				if d then d.Settings.AbilityIntroSeen = nil end
				s.tiles = 0
				return true
			end
			return "unknown op"
		end
		hook.Parent = ServerStorage
	end)
end

return M
