-- FrostKingService (2026-10-04, Claude): THE FROST KING - a rare co-op boss event. A giant penguin appears in a random snow field;
-- players may JOIN (stage unlocks respected), fight on foot with strength from their equipped snowplow build, and every qualifying fighter earns personal rewards.
-- The server owns everything: schedule, field choice, boss state, attack timing + hit tests, damage, participation and rewards.
-- FrostKingClient only draws it. Tunables: ReplicatedStorage.FrostKingConfig.
-- Studio tests (ServerStorage.BalanceTestMode = true): ServerStorage.FrostKingTestHook:Invoke("Start", {Field = id, Arrival = s, Target = s}) etc.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local C = require(RS:WaitForChild("FrostKingConfig"))
local SF = require(RS:WaitForChild("SnowFields"))
local StageConfig = require(RS:WaitForChild("StageConfig"))
local PlowConfig = require(RS:WaitForChild("PlowConfig"))
local PlowRegistry = require(script.Parent:WaitForChild("PlowRegistry"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Boosts = require(script.Parent:WaitForChild("BoostService"))
local okT, Treasures = pcall(function() return require(script.Parent:WaitForChild("TreasureService", 10)) end)
if not okT then Treasures = nil end

local TEST = RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true
local rng = Random.new()
local function now() return workspace:GetServerTimeNow() end
local function remote(class, name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = RS end
	return r
end
local event = remote("RemoteEvent", "FrostKingEvent")
local joinFn = remote("RemoteFunction", "FrostKingJoin")

local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function hdist(a, b) return flat(a - b).Magnitude end
local function unitFlat(v) local f = flat(v); if f.Magnitude < 1e-3 then return Vector3.new(0, 0, -1) end return f.Unit end
local function smooth(x) x = math.clamp(x, 0, 1); return x * x * (3 - 2 * x) end
local function nice(x)
	if x < 100 then return math.floor(x + 0.5) end
	local e = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / e + 0.5) * e
end

--------------------------------------------------
-- player power, reach and reward rate
--------------------------------------------------
-- Use the real driving stats when seated; otherwise use the owned garage build and current upgrade modifiers.
local function plowStats(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local v = PlowRegistry.Active[player]
	if v and v.hull and v.hull.Parent and hum and hum.SeatPart == v.seat and v.stats then return v.stats end
	local d = DataService.Get(player)
	if not d then return PlowConfig.StatsFor({}, {}) end
	local p = type(d.Plow) == "table" and d.Plow or {}
	local saved = type(p.Build) == "table" and p.Build or {}
	local owned = type(p.Parts) == "table" and p.Parts or {}
	local build = {}
	for slot, starter in pairs(PlowConfig.Starter) do
		local id = saved[slot]
		local def = PlowConfig.Parts[id]
		if def and def.Slot == slot and (id == starter or (tonumber(owned[id]) or 0) > 0) then build[slot] = id end
	end
	local ws = hum and hum.WalkSpeed or 16
	return PlowConfig.StatsFor(build, {
		PowerMult = player:GetAttribute("PowerMult") or 1, PowerBonus = player:GetAttribute("PowerBonus") or 0,
		SizeMult = player:GetAttribute("SizeMult") or 1, ReachMult = player:GetAttribute("ReachMult") or 1,
		SpinMult = player:GetAttribute("SpinMult") or 1, SpeedMult = 1 + math.clamp(ws / 16 - 1, 0, 1) * 0.5,
	})
end
local function realPower(player)
	local stats = plowStats(player)
	if not stats.Valid or not stats.HasBlade then return 0 end
	return math.max(0, stats.ClearPower * stats.Hard)
end
-- Ice-clearing strength is log-scaled + capped: beginners matter and better builds never end the fight instantly.
local function eventDps(player)
	local power = realPower(player)
	if power <= 0 then return 0 end
	return C.Power.Base * math.clamp(1 + C.Power.LogStep * math.log10(math.max(1, power)), 1, C.Power.MaxMult)
end
-- Fight on foot after parking; the equipped blade's reach remains part of the build's event strength.
local function reach(player)
	local stats = plowStats(player)
	if not stats.Valid or not stats.HasBlade then return 0 end
	return PlowConfig.Vehicle.BladeOffset + stats.BladeWidth / 2
end
local function stageAttr(style, attr)
	local stages = RS:FindFirstChild("SnowStages")
	local st = stages and stages:FindFirstChild(style)
	return st and st:GetAttribute(attr)
end
-- permanent Snow multiplier (upgrades x rebirth x achievements) and the temporary one (timed boosts x server events)
local function snowMults(player)
	local bs = math.max(player:GetAttribute("BoostSnowMult") or 1, 1e-6)
	local qs = 0
	local _, a = Boosts.Profile(player)
	if a then qs = Boosts.Permanent(a) or 0 end
	return (player:GetAttribute("SnowMult") or 1) / bs * (1 + qs), math.max(1, bs / (1 + qs))
end
-- theoretical active-digging Snow/s at the best unlocked field: the safe fallback and the clamp anchor
local function estimateRate(player)
	local spl, hp = stageAttr("Starter", "SnowPerPhase") or 1, stageAttr("Starter", "TileHP") or 1
	for _, s in ipairs(StageConfig.Order) do
		if player:GetAttribute("Stage_" .. s.Id) == true then
			local v = stageAttr(s.Id, "SnowPerPhase")
			if v and v > spl then spl, hp = v, stageAttr(s.Id, "TileHP") or hp end
		end
	end
	local stats, clearing = plowStats(player), PlowConfig.Clearing
	if not stats.Valid or not stats.HasBlade then return 0 end
	local slack = SF.TileSize * clearing.TileSlack
	local tiles = math.max(1, (stats.BladeWidth + slack * 2) * (clearing.BladeDepth + slack * 2) / (SF.TileSize ^ 2))
	local tough = math.clamp((math.log10(math.max(1, hp)) - clearing.ToughLow) / clearing.ToughSpan, 0, 1)
	local power = stats.ClearPower * (stats.Soft + (stats.Hard - stats.Soft) * tough)
	local layers = math.min(power * tiles / math.max(1, hp), C.Rewards.MaxLayersPerSecond)
	local pets = {}
	for n in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(pets, n) end
	local petF = 1 + (PetConfig.Multiplier(pets) - 1) * (player:GetAttribute("PetBoostMult") or 1)
	return layers * spl * petF * (snowMults(player)) * C.Rewards.ActiveShare
end
-- the existing recent-digging speed (ActivityService a.Rate) without temporary boosts, kept inside a sane band around the estimate
local function rewardRate(player)
	local est = estimateRate(player)
	local _, temp = snowMults(player)
	local _, a = Boosts.Profile(player)
	local recent = a and (tonumber(a.Rate) or 0) / temp or 0
	if recent ~= recent then recent = 0 end
	if recent > 0 and est > 0 then return math.clamp(recent, est * C.Rewards.RateClamp[1], est * C.Rewards.RateClamp[2]) end
	return math.max(est, recent)
end
local function rewardSnow(rate) return nice(math.max(C.Rewards.MinSnow, rate * 60 * C.Rewards.SnowMinutes)) end

--------------------------------------------------
-- fields
--------------------------------------------------
local function infoOf(f)
	local ts = SF.TileSize
	local style = f.Style or "Starter"
	local stage = StageConfig.ById[style]
	local w, d = f.Width * ts, f.Depth * ts
	local groundY = f.Center.Y + 1
	local cx, cz = f.Center.X, f.Center.Z
	local info = {Id = f.Id, Def = f, Style = style, World = (stage and stage.World) or 1, W = w, D = d,
		Name = style == "Starter" and "the Starter Field" or ((stage and stage.Name) or style),
		GroundY = groundY, SnowY = groundY + C.Field.SnowTop, Center = Vector3.new(cx, groundY + C.Field.SnowTop, cz),
		Bounds = {minX = cx - w / 2, maxX = cx + w / 2, minZ = cz - d / 2, maxZ = cz + d / 2}}
	info.Entry = w >= d and Vector3.new(info.Bounds.minX + 5, groundY + 5, cz) or Vector3.new(cx, groundY + 5, info.Bounds.minZ + 5)
	return info
end
-- never bypass stage unlocks: Starter is open to everyone, everything else needs its stage
local function accessible(player, info)
	if info.Style == "Starter" then return info.World ~= 2 end
	return player:GetAttribute("Stage_" .. info.Style) == true
end
local lastFieldId
local function chooseField(forceId)
	local players = Players:GetPlayers()
	local list = {}
	for _, f in ipairs(SF.Fields) do
		local info = infoOf(f)
		if forceId then
			if f.Id == forceId then return info end
		elseif info.W >= C.Field.MinWidth and info.D >= C.Field.MinDepth then
			local n = 0
			for _, p in ipairs(players) do if accessible(p, info) then n += 1 end end
			table.insert(list, {info = info, n = n})
		end
	end
	local best = -1
	for _, e in ipairs(list) do best = math.max(best, e.n) end
	local pool = {}
	for _, e in ipairs(list) do if e.n == best then table.insert(pool, e.info) end end
	if C.Field.AvoidPrevious and #pool > 1 and lastFieldId then
		for i = #pool, 1, -1 do if pool[i].Id == lastFieldId then table.remove(pool, i) end end
	end
	if #pool == 0 then return nil end
	return pool[rng:NextInteger(1, #pool)]
end

--------------------------------------------------
-- boss state
--------------------------------------------------
local boss = nil
local joinCooldown = {}
local lastRewards = {}
local nextSpawnAt = 0

local function arenaPad() return C.Field.Margin + C.Boss.Radius end
local function clampArena(p, pad)
	local b = boss.info.Bounds
	pad = pad or 0
	return Vector3.new(math.clamp(p.X, b.minX + pad, b.maxX - pad), boss.info.SnowY, math.clamp(p.Z, b.minZ + pad, b.maxZ - pad))
end
local function inArena(pos)
	local b = boss.info.Bounds
	return pos.X >= b.minX - 4 and pos.X <= b.maxX + 4 and pos.Z >= b.minZ - 4 and pos.Z <= b.maxZ + 4 and math.abs(pos.Y - boss.info.GroundY) < 20
end
local function rootOf(player)
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if r and h and h.Health > 0 then return r, h end
	return nil
end
local function hpShare(dps)
	local target = boss and boss.target or C.TargetSeconds
	return target * C.Uptime * C.Power.Base * (math.max(dps, C.Power.Base) / C.Power.Base) ^ C.Power.HPExponent
end
local function qualifies(p) return p.engaged >= C.Rewards.MinEngagedSeconds and p.hit >= C.Rewards.MinHitSeconds end
local function factorOf(p) return math.clamp(p.engaged / C.Rewards.FullEngagedSeconds, C.Rewards.PartialFloor, 1) end

local function participant(player)
	local p = boss.parts[player]
	if p then return p end
	PlowRegistry.Park(player) -- first entry only: the arena's dodges and knockback happen on foot
	p = {player = player, joined = now(), hp = C.Player.HP, invuln = 0, knockedUntil = 0, dmg = 0, hit = 0, engaged = 0,
		dps = eventDps(player), rate = rewardRate(player), refreshAt = now() + C.Power.DpsRefreshSeconds, rewarded = false}
	boss.parts[player] = p
	if boss.state == "Fight" and boss.placeholder then
		-- nobody was here when the fight began: the first fighter replaces the placeholder health (same % left)
		boss.placeholder = false
		local frac = boss.hp / math.max(1, boss.maxHP)
		boss.maxHP = math.max(C.Health.MinHP, hpShare(p.dps))
		boss.initialMax = boss.maxHP
		boss.hp = boss.maxHP * frac
	elseif boss.state == "Fight" then
		-- a late joiner adds health for the time that is left, smoothed in over time (see update)
		local remaining = math.clamp((boss.combatEnds - now()) / boss.combatSeconds, 0, 1)
		boss.pendingHP += hpShare(p.dps) * remaining * C.Health.JoinShare
	end
	return p
end

local function stateMsg()
	local n = 0
	for _, p in pairs(boss.parts) do if not p.fake then n += 1 end end
	return {T = "State", State = boss.state, HP = boss.hp, MaxHP = boss.maxHP, Phase = boss.phase, Pos = boss.pos, Facing = boss.facing,
		FightAt = boss.fightAt, Ends = boss.combatEnds, N = n, Recovering = boss.recovering, EndAt = boss.endAt, Result = boss.result}
end
local function actionMsg(a)
	return {T = "Action", Kind = a.Kind, T0 = a.T0, Windup = a.Windup, Active = a.Active, Recover = a.Recover, Data = a.Data, Phase = a.Phase}
end
local function spawnMsg()
	local i = boss.info
	return {T = "Spawn", Id = boss.id, FieldId = i.Id, Name = i.Name, Style = i.Style, World = i.World, Center = i.Center, W = i.W, D = i.D,
		GroundY = i.GroundY, SnowY = i.SnowY, Entry = i.Entry, FightAt = boss.fightAt, Ends = boss.combatEnds, Bounds = i.Bounds}
end

local function spawnBoss(opts)
	if boss then return nil, "A Frost King is already here." end
	opts = opts or {}
	local info = chooseField(opts.Field)
	if not info then return nil, "No valid field." end
	local t = now()
	local arrival = opts.Arrival or (TEST and C.Test.ArrivalSeconds) or C.ArrivalSeconds
	local combat = opts.Combat or C.CombatSeconds
	boss = {id = math.floor(t * 1000) % 1000000000, info = info, state = "Arrival", phase = 1, parts = {}, patches = {}, pendingHP = 0,
		pos = info.Center, facing = unitFlat(info.Entry - info.Center), fightAt = t + arrival, combatSeconds = combat,
		combatEnds = t + arrival + combat, target = opts.Target or C.TargetSeconds, hp = 1, maxHP = 1, initialMax = 1,
		nextActionAt = 0, lastState = 0, lastMe = 0, recovering = false}
	event:FireAllClients(spawnMsg())
	event:FireAllClients(stateMsg())
	return info.Name
end

local function startFight()
	boss.state = "Fight"
	local total = 0
	for _, p in pairs(boss.parts) do total += hpShare(p.dps) end
	boss.placeholder = total <= 0
	if total <= 0 then total = hpShare(C.Power.Base) end
	boss.maxHP = math.max(C.Health.MinHP, total)
	boss.hp = boss.maxHP
	boss.initialMax = boss.maxHP
	boss.nextActionAt = now() + 2.5
	event:FireAllClients(stateMsg())
end

local function teleportToEntry(player)
	PlowRegistry.Park(player)
	local r = rootOf(player)
	if not r or not boss then return end
	local spot = boss.info.Entry + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
	pcall(function() player:RequestStreamAroundAsync(spot, 6) end)
	if not boss or not player.Character then return end
	r.AssemblyLinearVelocity = Vector3.zero
	player.Character:PivotTo(CFrame.lookAt(spot, Vector3.new(boss.pos.X, spot.Y, boss.pos.Z)))
end
-- every boss hit: invulnerability afterwards (no stun-lock); at 0 event health you are knocked out to the arena edge and recover
local function hitPlayer(p, dmg, push)
	local t = now()
	if p.fake or p.knockedUntil > t or p.invuln > t then return false end
	p.hp -= dmg
	p.invuln = t + C.Player.Invulnerable
	local knocked = p.hp <= 0
	event:FireClient(p.player, {T = "Hit", Damage = dmg, HP = math.max(0, p.hp), Push = push, Knocked = knocked})
	if knocked then
		p.hp = 0
		p.knockedUntil = t + C.Player.KnockoutSeconds
		p.invuln = p.knockedUntil + C.Player.RespawnInvulnerable
		task.spawn(teleportToEntry, p.player)
		event:FireClient(p.player, {T = "Knocked", Until = p.knockedUntil})
	end
	return true
end
local function eachTarget(fn)
	local t = now()
	for pl, p in pairs(boss.parts) do
		if not p.fake and p.knockedUntil <= t then
			local r = rootOf(pl)
			if r and inArena(r.Position) then fn(pl, p, r) end
		end
	end
end
local function focusPoint()
	local best, bd
	eachTarget(function(_, _, r)
		local d = hdist(r.Position, boss.pos)
		if not bd or d < bd then best, bd = r.Position, d end
	end)
	return best
end
local function grounded(p, r) return (r.Position.Y - (p.baseY or r.Position.Y)) < C.Attacks.Stomp.JumpClear end

--------------------------------------------------
-- attacks (all timing is broadcast; clients telegraph from the same data)
--------------------------------------------------
local function startAction(kind)
	local ph = C.Phases[boss.phase]
	local A = C.Attacks[kind]
	local t0 = now()
	local function w(x) return math.max(C.MinWarning, x / ph.Speed) end
	local focus = focusPoint() or boss.info.Center
	local dir = unitFlat(focus - boss.pos)
	local a = {Kind = kind, T0 = t0, Phase = boss.phase, Data = {}, hit = {}, ringHit = {}, pending = {}}
	if kind ~= "Stagger" then boss.facing = dir end
	if kind == "Slide" then
		a.Windup, a.Active, a.Recover = w(A.Windup), A.Dash, A.Recover
		local from = boss.pos
		local to = clampArena(from + dir * A.Length, arenaPad())
		a.Data = {From = from, To = to, Width = A.Width, Repeat = (ph.Final and not boss.slideRepeat) and 1 or 0}
	elseif kind == "Barrage" then
		local n = A.Count[boss.phase] or A.Count[#A.Count]
		a.Windup, a.Recover = w(A.Windup), A.Recover
		a.Active = (n - 1) * A.Interval + A.Flight
		local targets = {}
		eachTarget(function(_, _, r) table.insert(targets, r.Position) end)
		local balls = {}
		for i = 1, n do
			local base = #targets > 0 and targets[(i - 1) % #targets + 1] or (boss.pos + Vector3.new(rng:NextNumber(-18, 18), 0, rng:NextNumber(-18, 18)))
			local off = Vector3.new(rng:NextNumber(-A.Spread, A.Spread), 0, rng:NextNumber(-A.Spread, A.Spread))
			local launch = t0 + a.Windup + (i - 1) * A.Interval
			table.insert(balls, {Target = clampArena(base + off, 2), Launch = launch, Land = launch + A.Flight})
		end
		a.Data = {Balls = balls, Radius = A.Radius}
	elseif kind == "Breath" then
		a.Windup, a.Active, a.Recover = w(A.Windup), A.Duration, A.Recover
		local origin = boss.pos + dir * (C.Boss.Radius - 1)
		local patches = {}
		for i = 1, A.Patches do
			local dist = A.Range * (0.3 + 0.55 * (i - 1) / math.max(1, A.Patches - 1))
			local side = Vector3.new(-dir.Z, 0, dir.X) * rng:NextNumber(-dist * 0.3, dist * 0.3)
			table.insert(patches, clampArena(origin + dir * dist + side, 2))
		end
		a.Data = {Origin = origin, Dir = dir, Range = A.Range, HalfAngle = A.HalfAngle, Patches = patches, PatchRadius = A.PatchRadius, PatchSeconds = A.PatchSeconds}
	elseif kind == "Stomp" then
		a.Windup, a.Recover = w(A.Windup), A.Recover
		local rings = {t0 + a.Windup}
		if ph.Final then table.insert(rings, t0 + a.Windup + A.SecondRingDelay) end
		a.Active = (rings[#rings] - rings[1]) + (A.MaxRadius - C.Boss.Radius) / A.RingSpeed
		a.Data = {Rings = rings, Speed = A.RingSpeed, MaxRadius = A.MaxRadius, Start = C.Boss.Radius, Width = A.RingWidth, Center = boss.pos, Jump = A.Jump}
	elseif kind == "Spin" then
		a.Windup, a.Active, a.Recover = w(A.Windup), A.Duration, A.Recover
		a.Data = {Radius = ph.Final and A.FinalRadius or A.Radius}
	else -- Stagger: a readable pause + bonus-damage window on phase change
		a.Windup, a.Active, a.Recover = 0, C.StaggerSeconds, 0
	end
	boss.act = a
	event:FireAllClients(actionMsg(a))
end

local function processAction(a, t)
	local u = t - a.T0
	local A = C.Attacks[a.Kind]
	local W, ACT = a.Windup, a.Active
	if a.Kind == "Slide" then
		if u >= W and u <= W + ACT then
			boss.pos = a.Data.From:Lerp(a.Data.To, smooth((u - W) / ACT))
			boss.facing = unitFlat(a.Data.To - a.Data.From)
			eachTarget(function(pl, p, r)
				if not a.hit[pl] and hdist(r.Position, boss.pos) <= C.Boss.Radius + 1.5 then
					a.hit[pl] = true
					local side = Vector3.new(-boss.facing.Z, 0, boss.facing.X)
					if side:Dot(flat(r.Position - boss.pos)) < 0 then side = -side end
					hitPlayer(p, A.Damage, side * A.Push + Vector3.new(0, 30, 0))
				end
			end)
		elseif u > W + ACT and not a.landed then
			a.landed = true
			boss.pos = a.Data.To
		end
	elseif a.Kind == "Barrage" then
		for _, b in ipairs(a.Data.Balls) do
			if not b.done and t >= b.Land then
				b.done = true
				eachTarget(function(_, p, r)
					if hdist(r.Position, b.Target) <= a.Data.Radius then hitPlayer(p, A.Damage, unitFlat(r.Position - b.Target) * A.Push + Vector3.new(0, 35, 0)) end
				end)
			end
		end
	elseif a.Kind == "Breath" then
		if u >= W and u <= W + ACT then
			local o, dir = a.Data.Origin, a.Data.Dir
			local cosA = math.cos(math.rad(a.Data.HalfAngle))
			eachTarget(function(pl, p, r)
				if a.hit[pl] then return end
				local v = flat(r.Position - o)
				local d = v.Magnitude
				if d <= a.Data.Range and (d < 2 or v.Unit:Dot(dir) >= cosA) then
					a.hit[pl] = true
					hitPlayer(p, A.Damage, dir * A.Push + Vector3.new(0, 25, 0))
				end
			end)
		elseif u > W + ACT and not a.patched then
			a.patched = true
			for _, pos in ipairs(a.Data.Patches) do table.insert(boss.patches, {Pos = pos, R = a.Data.PatchRadius, Until = t + a.Data.PatchSeconds}) end
		end
	elseif a.Kind == "Stomp" then
		local d0 = a.Data
		if not a.slammed and t >= d0.Rings[1] then
			a.slammed = true
			eachTarget(function(_, p, r)
				if hdist(r.Position, d0.Center) <= C.Boss.Radius + 2.5 then hitPlayer(p, A.Damage, unitFlat(r.Position - d0.Center) * A.Push + Vector3.new(0, 40, 0)) end
			end)
		end
		local life = (d0.MaxRadius - d0.Start) / d0.Speed
		for k, rs in ipairs(d0.Rings) do
			local e = t - rs
			if e >= 0 and e <= life then
				local rad = d0.Start + d0.Speed * e
				a.ringHit[k] = a.ringHit[k] or {}
				eachTarget(function(pl, p, r)
					if a.ringHit[k][pl] then return end
					-- jump over the ring (airborne players are safe) or stay beyond its reach
					if math.abs(hdist(r.Position, d0.Center) - rad) <= d0.Width / 2 + 0.8 then
						if not grounded(p, r) then
							a.ringHit[k][pl] = true -- cleared it
						elseif not a.pending[pl] then
							a.pending[pl] = {t = t, k = k} -- lag forgiveness: a jump seen up to JumpGrace later still counts
						end
					end
				end)
			end
		end
		for pl, pend in pairs(a.pending) do
			local p = boss.parts[pl]
			local r = p and rootOf(pl)
			if not p or not r or a.ringHit[pend.k][pl] then
				a.pending[pl] = nil
			elseif not grounded(p, r) then
				a.ringHit[pend.k][pl] = true; a.pending[pl] = nil
			elseif t - pend.t >= C.Attacks.Stomp.JumpGrace then
				a.ringHit[pend.k][pl] = true; a.pending[pl] = nil
				hitPlayer(p, A.Damage, unitFlat(r.Position - d0.Center) * A.Push + Vector3.new(0, 45, 0))
			end
		end
	elseif a.Kind == "Spin" then
		if u >= W and u <= W + ACT then
			eachTarget(function(pl, p, r)
				if not a.hit[pl] and hdist(r.Position, boss.pos) <= a.Data.Radius then
					a.hit[pl] = true
					hitPlayer(p, A.Damage, unitFlat(r.Position - boss.pos) * A.Push + Vector3.new(0, 30, 0))
				end
			end)
		end
	end
	return u >= W + ACT + a.Recover
end
local function pickAttack()
	if boss.force then local k = boss.force; boss.force = nil; return k end
	local pool = C.Phases[boss.phase].Pool
	local choices = {}
	for _, k in ipairs(pool) do if k ~= boss.lastKind then table.insert(choices, k) end end
	if #choices == 0 then choices = pool end
	return choices[rng:NextInteger(1, #choices)]
end

--------------------------------------------------
-- rewards + end
--------------------------------------------------
local function grantRewards(p, result)
	local player = p.player
	local out = {Result = result, Qualified = qualifies(p), Engaged = math.floor(p.engaged), Hit = math.floor(p.hit), Damage = math.floor(p.dmg),
		NeedEngaged = C.Rewards.MinEngagedSeconds, NeedHit = C.Rewards.MinHitSeconds}
	if not out.Qualified then return out end
	local d = DataService.Get(player)
	if not d then out.Qualified = false; return out end
	local share = result == "Victory" and 1 or C.Rewards.EscapeShare
	local snow = nice(math.max(C.Rewards.MinSnow, rewardSnow(p.rate) * factorOf(p) * share))
	d.Snow += snow -- straight to Snow like the Lucky Wheel, so it can't inflate the digging-speed average
	DataService.SetStat(player, "Snow", d.Snow)
	out.Snow = snow
	if result == "Victory" then
		if Treasures and Treasures.GrantRandom and rng:NextNumber() < C.Rewards.TreasureChance then
			local ok, item = pcall(Treasures.GrantRandom, player, boss.info.Style, boss.info.Def)
			if ok and item then out.Treasure = item.Name or item.Id end
		end
		if rng:NextNumber() < C.Rewards.BoostChance then
			local kind = C.Rewards.Boosts[rng:NextInteger(1, #C.Rewards.Boosts)]
			local ok, res = pcall(Boosts.Add, player, kind, C.Rewards.BoostSeconds)
			if ok and res ~= false then out.Boost = kind; out.BoostSeconds = C.Rewards.BoostSeconds end
		end
	end
	return out
end
local function cleanup()
	if not boss then return end
	lastFieldId = boss.info.Id
	boss = nil
	event:FireAllClients({T = "Cleanup"})
	nextSpawnAt = now() + rng:NextNumber(C.Schedule.MinMinutes, C.Schedule.MaxMinutes) * 60
end
local function finish(result)
	if not boss or boss.state == "Defeat" or boss.state == "Escape" then return end
	boss.state = result == "Victory" and "Defeat" or "Escape"
	boss.result = result
	boss.endAt = now()
	boss.act = nil
	boss.patches = {}
	local me = boss
	event:FireAllClients(stateMsg())
	task.delay(result == "Victory" and C.DefeatSeconds or 2, function()
		if boss ~= me then return end
		lastRewards = {}
		for pl, p in pairs(me.parts) do
			if not p.fake and not p.rewarded and pl.Parent == Players then
				p.rewarded = true -- once per encounter, set before granting
				local ok, r = pcall(grantRewards, p, result)
				if not ok then warn("[FrostKing] reward failed: " .. tostring(r)); r = {Result = result, Qualified = false, Error = true} end
				lastRewards[pl.Name] = r
				event:FireClient(pl, {T = "Reward", Reward = r})
			end
		end
		task.delay(C.CleanupSeconds, function() if boss == me then cleanup() end end)
	end)
end

--------------------------------------------------
-- main loop
--------------------------------------------------
local function update(dt)
	if not boss then return end
	local t = now()
	if boss.state == "Arrival" or boss.state == "Fight" then
		for _, pl in ipairs(Players:GetPlayers()) do
			if not boss.parts[pl] then
				local r = rootOf(pl)
				if r and inArena(r.Position) and accessible(pl, boss.info) then participant(pl) end
			end
		end
	end
	if boss.state == "Arrival" then
		if t >= boss.fightAt then startFight() end
	elseif boss.state == "Fight" then
		if boss.pendingHP > 0 then
			local step = math.min(boss.pendingHP, boss.initialMax * C.Health.MaxGrowthPerMinute / 60 * dt)
			boss.pendingHP -= step; boss.maxHP += step; boss.hp += step
		end
		local anyone = false
		for pl, p in pairs(boss.parts) do
			if p.fake then
				local dmg = p.dps * C.Uptime * dt
				boss.hp -= dmg; p.dmg += dmg; p.engaged += dt; p.hit += dt * C.Uptime
			else
				if p.knockedUntil > 0 and t >= p.knockedUntil then
					p.knockedUntil = 0
					p.hp = C.Player.HP
					event:FireClient(pl, {T = "Recovered", HP = p.hp})
				end
				if t >= p.refreshAt then
					p.refreshAt = t + C.Power.DpsRefreshSeconds
					p.dps += (eventDps(pl) - p.dps) * 0.3
				end
				local r = rootOf(pl)
				if r and p.knockedUntil <= t and inArena(r.Position) then
					anyone = true
					p.baseY = p.baseY and math.min(r.Position.Y, p.baseY + dt * 1.5) or r.Position.Y
					local d = hdist(r.Position, boss.pos)
					if d <= C.Rewards.EngageRange then p.engaged += dt end
					if p.dps > 0 and d <= C.Boss.Radius + reach(pl) then
						local dmg = p.dps * dt * (boss.recovering and C.Power.RecoveryBonus or 1)
						boss.hp -= dmg; p.dmg += dmg; p.hit += dt
					end
				end
			end
		end
		boss.emptySince = (not anyone) and (boss.emptySince or t) or nil
		if #boss.patches > 0 then
			boss.patchTick = (boss.patchTick or 0) + dt
			if boss.patchTick >= C.Attacks.Breath.PatchTick then
				boss.patchTick = 0
				for i = #boss.patches, 1, -1 do
					local pa = boss.patches[i]
					if t >= pa.Until then
						table.remove(boss.patches, i)
					else
						eachTarget(function(pl, p, r)
							if hdist(r.Position, pa.Pos) <= pa.R and p.invuln <= t then
								p.hp = math.max(1, p.hp - C.Attacks.Breath.PatchDamage) -- frost chills but never knocks out on its own
								event:FireClient(pl, {T = "Hit", Damage = C.Attacks.Breath.PatchDamage, HP = p.hp, Frost = true})
							end
						end)
					end
				end
			end
		end
		boss.recovering = false
		if boss.act then
			local a = boss.act
			local done = processAction(a, t)
			local u = t - a.T0
			boss.recovering = (a.Kind == "Spin" and u > a.Windup + a.Active) or a.Kind == "Stagger"
			if done then
				boss.act = nil
				boss.lastKind = a.Kind
				local ph = C.Phases[boss.phase]
				if a.Kind == "Slide" and (a.Data.Repeat or 0) > 0 then
					boss.slideRepeat = true
					startAction("Slide")
					boss.slideRepeat = false
				elseif boss.pendingStagger then
					boss.pendingStagger = false
					startAction("Stagger")
				else
					boss.nextActionAt = t + rng:NextNumber(ph.Rest[1], ph.Rest[2])
				end
			end
		else
			local focus = focusPoint()
			if focus then
				local dir = unitFlat(focus - boss.pos)
				boss.facing = dir
				local d = hdist(focus, boss.pos)
				if d > C.Boss.KeepDistance then boss.pos = clampArena(boss.pos + dir * math.min(C.Boss.MoveSpeed * dt, d - C.Boss.KeepDistance), arenaPad()) end
				if t >= boss.nextActionAt then startAction(pickAttack()) end
			end
		end
		local f = boss.hp / math.max(1, boss.maxHP)
		local ph = (f <= C.Phases[3].Below and 3) or (f <= C.Phases[2].Below and 2) or 1
		if ph > boss.phase then
			boss.phase = ph
			event:FireAllClients({T = "Phase", Phase = ph})
			if boss.act then boss.pendingStagger = true else startAction("Stagger") end
		end
		if boss.hp <= 0 then
			boss.hp = 0
			finish("Victory")
		elseif t >= boss.combatEnds then
			finish("Escape")
		elseif boss.emptySince and t - boss.emptySince >= C.EmptyEscapeSeconds then
			finish("Escape")
		end
	end
	if not boss then return end
	if t - boss.lastState >= 0.2 then
		boss.lastState = t
		event:FireAllClients(stateMsg())
	end
	if t - boss.lastMe >= 1 then
		boss.lastMe = t
		for pl, p in pairs(boss.parts) do
			if not p.fake and typeof(pl) == "Instance" then
				event:FireClient(pl, {T = "Me", HP = p.hp, MaxHP = C.Player.HP, Engaged = p.engaged, Hit = p.hit, Qualified = qualifies(p),
					NeedEngaged = C.Rewards.MinEngagedSeconds, NeedHit = C.Rewards.MinHitSeconds, Reward = nice(rewardSnow(p.rate) * factorOf(p)),
					Knocked = p.knockedUntil > t and p.knockedUntil or nil, Damage = math.floor(p.dmg)})
			end
		end
	end
end

joinFn.OnServerInvoke = function(player, action)
	if action == "Sync" then
		if not boss then return nil end
		return {Spawn = spawnMsg(), State = stateMsg(), Action = boss.act and actionMsg(boss.act) or nil}
	end
	if not boss or (boss.state ~= "Arrival" and boss.state ~= "Fight") then return false, "There is no Frost King to fight right now." end
	if not accessible(player, boss.info) then return false, ("Unlock %s first!"):format(boss.info.Name) end
	if player:GetAttribute("IntroActive") then return false, "Finish the intro first!" end
	local r = rootOf(player)
	if not r then return false, "Wait until you respawn." end
	if (joinCooldown[player] or 0) > os.clock() then return false, "One moment..." end
	joinCooldown[player] = os.clock() + 3
	PlowRegistry.Park(player)
	local spot = boss.info.Entry + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
	pcall(function() player:RequestStreamAroundAsync(spot, 8) end)
	if not boss or not player.Character then return false, "The Frost King is gone." end
	r.AssemblyLinearVelocity = Vector3.zero
	player.Character:PivotTo(CFrame.lookAt(spot, Vector3.new(boss.pos.X, spot.Y, boss.pos.Z)))
	player:SetAttribute("World", boss.info.World)
	participant(player)
	return true, "Good luck!"
end

Players.PlayerRemoving:Connect(function(p)
	joinCooldown[p] = nil
	if boss then boss.parts[p] = nil end -- leaving gives no reward and never lowers the boss health
end)
local function watch(p)
	p.CharacterAdded:Connect(function()
		local part = boss and boss.parts[p]
		if part then part.hp = C.Player.HP; part.knockedUntil = 0; part.baseY = nil end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

nextSpawnAt = now() + rng:NextNumber(C.Schedule.MinMinutes, C.Schedule.MaxMinutes) * 60
task.spawn(function()
	while true do
		task.wait(5)
		if C.Enabled and not boss and now() >= nextSpawnAt and not (TEST and not C.Test.AutoSpawn) and #Players:GetPlayers() >= C.Schedule.MinPlayers then
			local ok, err = pcall(spawnBoss)
			if not ok then warn("[FrostKing] spawn failed: " .. tostring(err)) end
			if not boss then nextSpawnAt = now() + 120 end
		end
	end
end)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then return end
	local step = math.min(acc, 0.5)
	acc = 0
	local ok, err = pcall(update, step)
	if not ok then warn("[FrostKing] " .. tostring(err)) end
end)

-- Studio isolated tests only (BalanceTestMode)
if TEST then
	local hook = SS:FindFirstChild("FrostKingTestHook") or Instance.new("BindableFunction")
	hook.Name = "FrostKingTestHook"
	hook.OnInvoke = function(action, a)
		if action == "Start" then
			return spawnBoss(a)
		elseif action == "State" then
			if not boss then return {Active = false} end
			local parts = {}
			for pl, p in pairs(boss.parts) do
				parts[p.fake and p.name or pl.Name] = {DPS = p.dps, Damage = p.dmg, Engaged = p.engaged, Hit = p.hit, HP = p.hp, Rate = p.rate,
					Knocked = p.knockedUntil > now(), Qualified = qualifies(p), Preview = nice(rewardSnow(p.rate or 0) * factorOf(p))}
			end
			return {Active = true, State = boss.state, Field = boss.info.Name, FieldId = boss.info.Id, HP = boss.hp, MaxHP = boss.maxHP, Phase = boss.phase,
				Action = boss.act and boss.act.Kind, Pos = boss.pos, Parts = parts, EndsIn = boss.combatEnds - now(), FightIn = boss.fightAt - now(),
				Pending = boss.pendingHP, Patches = #boss.patches, Entry = boss.info.Entry}
		elseif action == "Attack" then
			if boss then boss.force = a; boss.nextActionAt = 0 end
			return boss ~= nil
		elseif action == "SetHP" then
			if boss and boss.state == "Fight" then boss.hp = boss.maxHP * a end
			return boss ~= nil
		elseif action == "Fake" then
			if not boss then return false end
			local dps = C.Power.Base * math.clamp(1 + C.Power.LogStep * math.log10(math.max(1, a or 1)), 1, C.Power.MaxMult)
			local fake = {fake = true, name = "Fake" .. rng:NextInteger(100, 999), dps = dps, dmg = 0, hit = 0, engaged = 0, hp = 100, knockedUntil = 0, invuln = 0, rate = 0}
			boss.parts[fake.name] = fake
			if boss.state == "Fight" and boss.placeholder then
				boss.placeholder = false
				boss.maxHP = math.max(C.Health.MinHP, hpShare(dps)); boss.initialMax = boss.maxHP; boss.hp = boss.maxHP
			elseif boss.state == "Fight" then
				local rem = math.clamp((boss.combatEnds - now()) / boss.combatSeconds, 0, 1)
				boss.pendingHP += hpShare(dps) * rem * C.Health.JoinShare
			end
			return fake.name, dps, hpShare(dps)
		elseif action == "Unfake" then
			if boss then for k in pairs(boss.parts) do if type(k) == "string" then boss.parts[k] = nil end end end
			return true
		elseif action == "End" then
			if boss then finish(a or "Escape") end
			return true
		elseif action == "Cleanup" then
			cleanup()
			return true
		elseif action == "Rewards" then
			return lastRewards
		elseif action == "Act" then -- the current attack (timing + data) for hit/dodge tests
			if not boss or not boss.act then return nil end
			local x = boss.act
			return {Kind = x.Kind, T0 = x.T0, Windup = x.Windup, Active = x.Active, Recover = x.Recover, Data = x.Data, Now = now(), Facing = boss.facing, Pos = boss.pos}
		elseif action == "Config" then -- tweak a tunable for a test: Invoke("Config", {"Rewards", "MinEngagedSeconds", 5})
			C[a[1]][a[2]] = a[3]
			return true
		elseif action == "Rate" then
			local power = realPower(a)
			return {Rate = rewardRate(a), Estimate = estimateRate(a), Snow = rewardSnow(rewardRate(a)), DPS = eventDps(a), Power = power, Reach = reach(a), HPShare = hpShare(eventDps(a))}
		end
		return nil
	end
	hook.Parent = SS
end
