-- ContractService (2026-10-05, Claude): NPC CLEARING CONTRACTS ("Help Yards"). Optional short jobs: an announcement offers a job at a
-- nearby Help Yard (one per stage, workspace.ContractYards), the requester NPC looks like one of the player's Roblox friends (cosmetic only),
-- the player clears the marked snow with the real snowplow (SnowFieldService + ContractRegistry: same blade footprint, speed checks and stage
-- locks; contract snow never regrows and never drops treasure) and earns ordinary Snow per layer plus a modest completion bonus.
-- The server owns everything: schedule, instance ids, yard leases, objectives, progress, completion, reward, expiry and cleanup.
-- Clients only display state and send {action, instanceId}. Tunables + layouts: ReplicatedStorage.ContractConfig.
-- Studio tests (ServerStorage.BalanceTestMode = true): ServerStorage.ContractTestHook:Invoke(op, player, ...).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")

local CFG = require(RS:WaitForChild("ContractConfig"))
local SF = require(RS:WaitForChild("SnowFields"))
local StageConfig = require(RS:WaitForChild("StageConfig"))
local PlowConfig = require(RS:WaitForChild("PlowConfig"))
local PetConfig = require(RS:WaitForChild("PetConfig"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlowRegistry = require(script.Parent:WaitForChild("PlowRegistry"))
local Registry = require(script.Parent:WaitForChild("ContractRegistry"))
local okB, Boosts = pcall(function() return require(script.Parent:WaitForChild("BoostService", 10)) end)
if not okB then Boosts = nil end

local TEST = RunService:IsStudio() and SS:GetAttribute("BalanceTestMode") == true
local rng = Random.new()
local function now() return workspace:GetServerTimeNow() end
local function remote(class, name)
	local r = RS:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = RS end
	return r
end
local event = remote("RemoteEvent", "ContractEvent")
local request = remote("RemoteFunction", "ContractRequest")
local fieldData = RS:FindFirstChild("ContractFieldData") or Instance.new("Folder")
fieldData.Name = "ContractFieldData"; fieldData.Parent = RS
local prefabs = SS:WaitForChild("ContractPrefabs")
local built = SS:WaitForChild("ContractBuilt")
local TS = SF.TileSize

local function nice(x)
	if x < 100 then return math.floor(x + 0.5) end
	local e = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / e + 0.5) * e
end
local function stageAttr(style, attr)
	local stages = RS:FindFirstChild("SnowStages")
	local st = stages and stages:FindFirstChild(style)
	return st and st:GetAttribute(attr)
end
local function stageName(id)
	local s = StageConfig.ById and StageConfig.ById[id]
	return id == "Starter" and "Frostfall" or (s and s.Name) or id
end

--------------------------------------------------
-- yards (leased sites)
--------------------------------------------------
local yards = {}
local yardFolder = workspace:WaitForChild("ContractYards", 30)
if yardFolder then
	for _, m in ipairs(yardFolder:GetChildren()) do
		local anchor = m:FindFirstChild("Anchor")
		if anchor and m:GetAttribute("Stage") then
			table.insert(yards, {model = m, stage = m:GetAttribute("Stage"), world = m:GetAttribute("World") or 1, cf = anchor.CFrame, lease = 0, inst = nil})
		end
	end
end
local function accessible(player, yard)
	if (player:GetAttribute("World") or 1) ~= yard.world then return false end
	if yard.stage == "Starter" then return true end
	return player:GetAttribute("Stage_" .. yard.stage) == true
end
local function rootPos(player)
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return r and r.Position
end

--------------------------------------------------
-- player power + validated earning potential (same model as the Frost King rewards)
--------------------------------------------------
local function plowStats(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local v = PlowRegistry.Active[player]
	if v and v.hull and v.hull.Parent and hum and hum.SeatPart == v.seat and v.stats then return v.stats end
	local d = DataService.Get(player)
	local p = d and type(d.Plow) == "table" and d.Plow or {}
	local saved = type(p.Build) == "table" and p.Build or {}
	local owned = type(p.Parts) == "table" and p.Parts or {}
	local build = {}
	for slot, starter in pairs(PlowConfig.Starter) do
		local id = saved[slot]
		local def = PlowConfig.Parts[id]
		if def and def.Slot == slot and (id == starter or (tonumber(owned[id]) or 0) > 0) then build[slot] = id else build[slot] = starter end
	end
	local ws = hum and hum.WalkSpeed or 16
	return PlowConfig.StatsFor(build, {
		PowerMult = player:GetAttribute("PowerMult") or 1, PowerBonus = player:GetAttribute("PowerBonus") or 0,
		SizeMult = player:GetAttribute("SizeMult") or 1, ReachMult = player:GetAttribute("ReachMult") or 1,
		SpinMult = player:GetAttribute("SpinMult") or 1, SpeedMult = 1 + math.clamp(ws / 16 - 1, 0, 1) * 0.5,
		Levels = type(p.Levels) == "table" and p.Levels or nil, -- 2026-10-06: part levels
	})
end
local function snowMults(player)
	local bs = math.max(player:GetAttribute("BoostSnowMult") or 1, 1e-6)
	local qs = 0
	if Boosts then
		local ok, _, a = pcall(Boosts.Profile, player)
		if ok and a then qs = Boosts.Permanent(a) or 0 end
	end
	return (player:GetAttribute("SnowMult") or 1) / bs * (1 + qs), math.max(1, bs / (1 + qs))
end
local function petFactor(player)
	local pets = {}
	for n in (player:GetAttribute("EquippedPets") or ""):gmatch("[^,]+") do table.insert(pets, n) end
	return 1 + (PetConfig.Multiplier(pets, player) - 1) * (player:GetAttribute("PetBoostMult") or 1)
end
-- Snow/s the player can validly earn at this stage (theoretical active clearing, kept in a band around recent real digging)
local function rewardRate(player, stage)
	local spl, hp = stageAttr(stage, "SnowPerPhase") or 1, stageAttr(stage, "TileHP") or 1
	local stats = plowStats(player)
	if not stats.Valid or not stats.HasBlade then return 0 end
	local CL = PlowConfig.Clearing
	local slack = TS * CL.TileSlack
	local tiles = math.max(1, (stats.BladeWidth + slack * 2) * (CL.BladeDepth + slack * 2) / (TS ^ 2))
	local tough = PlowConfig.ToughnessOf(stage, hp)
	local power = stats.ClearPower * (stats.Soft + (stats.Hard - stats.Soft) * tough)
	local layers = math.min(power * tiles / math.max(1, hp), CFG.Reward.MaxLayersPerSecond)
	local perm, temp = snowMults(player)
	local est = layers * spl * petFactor(player) * perm * CFG.Reward.ActiveShare * (stats.SnowEff or 1) -- task 7: body Snow efficiency
	local recent = 0
	if Boosts then
		local ok, _, a = pcall(Boosts.Profile, player)
		if ok and a then recent = (tonumber(a.Rate) or 0) / temp end
	end
	if recent ~= recent then recent = 0 end
	if recent > 0 and est > 0 then return math.clamp(recent, est * CFG.Reward.RateClamp[1], est * CFG.Reward.RateClamp[2]) end
	return math.max(est, recent)
end
-- expected job cycle for this scene and build (rebalance 2026-10-05): clearing seconds from zone area / (blade swath x lane speed),
-- plus travel and interaction. Returns total seconds and clearing seconds.
local function expectedJob(player, t)
	local R = CFG.Reward
	local stats = plowStats(player)
	local area = 0
	for _, z in ipairs(t.Zones) do area += math.abs((z.Rect[3] - z.Rect[1]) * (z.Rect[4] - z.Rect[2])) end
	local w = math.max(1, (stats.BladeWidth or 0) + 2 * TS * PlowConfig.Clearing.TileSlack)
	local handling = 0.42 + 0.32 * (stats.Traction or 0) + 0.14 * math.min(stats.Pivot or 0, 1) + 0.06 * math.min(stats.Turn or 1, 1.2) / 1.2
	handling = math.clamp(handling - math.min(0.12, 0.6 / math.max(stats.Accel or 1, 1e-6)), 0.3, 0.9)
	local v = math.max(3, (stats.MaxSpeed or 0) * (PlowConfig.Drive.PlowingSpeedFactor or 1) * handling * R.LaneSpeedShare)
	local tc = math.clamp(area / (w * v) * R.Passes * (R.Demand[t.Id] or 1), R.ClearSeconds[1], R.ClearSeconds[2])
	return tc + R.TravelSeconds + R.OverheadSeconds, tc
end
-- per-tile HP for this player's job: the stage value, kept between shares of the player's own blade power (snapshotted)
local function contractHP(player, stage)
	local base = stageAttr(stage, "TileHP") or 1
	local stats = plowStats(player)
	local p = (stats.ClearPower or 0) * (stats.Soft or 1)
	if p <= 0 then return base end
	return math.clamp(base, p * CFG.Difficulty.MinPowerShare, p * CFG.Difficulty.MaxPowerShare)
end

--------------------------------------------------
-- friend NPCs (cosmetic)
--------------------------------------------------
local friendCache = {} -- [userId] = {t, list = {{Id, DisplayName}}}
local templates, templateOrder = {}, {}
local function friendsOf(userId)
	local c = friendCache[userId]
	if c and os.clock() - c.t < CFG.NPC.FriendCacheSeconds then return c.list end
	local list = {}
	local ok, pages = pcall(function() return Players:GetFriendsAsync(userId) end)
	if ok and pages then
		for _ = 1, CFG.NPC.MaxFriendPages do
			local okP, page = pcall(function() return pages:GetCurrentPage() end)
			if not okP then break end
			for _, f in ipairs(page) do
				if type(f.Id) == "number" and f.Id > 0 then table.insert(list, {Id = f.Id, DisplayName = f.DisplayName or f.Username or "Friend"}) end
			end
			if pages.IsFinished then break end
			if not pcall(function() pages:AdvanceToNextPageAsync() end) then break end
		end
	end
	friendCache[userId] = {t = os.clock(), list = list, ok = ok}
	return list
end
local function pickFriend(player, st)
	if player.UserId <= 0 then return nil end
	local list = friendsOf(player.UserId)
	if #list == 0 then return nil end
	local recent = {}
	for _, id in ipairs(st.recentFriends) do recent[id] = true end
	local pool = {}
	for _, f in ipairs(list) do if not recent[f.Id] then table.insert(pool, f) end end
	if #pool == 0 then pool = list end
	local f = pool[rng:NextInteger(1, #pool)]
	table.insert(st.recentFriends, 1, f.Id)
	while #st.recentFriends > CFG.NPC.AvoidRecent do table.remove(st.recentFriends) end
	return f
end
-- avatar model for a friend, with a timeout; nil = use the winter resident
local function avatarTemplate(userId)
	if templates[userId] then return templates[userId] end
	local result, done = nil, false
	task.spawn(function()
		local ok, m = pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(userId) end)
		if ok and m then result = m end
		done = true
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < CFG.NPC.LoadTimeout do task.wait(0.1) end
	if not result then return nil end
	templates[userId] = result
	table.insert(templateOrder, userId)
	while #templateOrder > CFG.NPC.TemplateCache do
		local old = table.remove(templateOrder, 1)
		if templates[old] then templates[old]:Destroy(); templates[old] = nil end
	end
	return result
end
local residentTemplate
local function resident()
	if residentTemplate then return residentTemplate end
	local F = CFG.NPC.Fallback
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor, desc.LeftArmColor, desc.RightArmColor = F.Skin, F.Coat, F.Coat
	desc.TorsoColor, desc.LeftLegColor, desc.RightLegColor = F.Coat, F.Pants, F.Pants
	local ok, m = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not ok or not m then return nil end
	local head = m:FindFirstChild("Head")
	local function wear(name, offset)
		local acc = built:FindFirstChild(name)
		if not (acc and head) then return end
		local c = acc:Clone()
		c:PivotTo(head.CFrame * offset)
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
				local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = p; w.Parent = p
			end
		end
		c.Parent = m
	end
	wear("WinterHat", CFrame.new(0, head.Size.Y * 0.18, 0))
	wear("Scarf", CFrame.new(0, -head.Size.Y * 0.55, 0))
	residentTemplate = m
	return m
end
local function playAnim(npc, which, looped)
	local hum = npc:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local set = CFG.NPC.Anim[hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"]
	local a = Instance.new("Animation"); a.AnimationId = set[which]
	local ok, track = pcall(function() return animator:LoadAnimation(a) end)
	if ok and track then track.Looped = looped and true or false; track:Play(0.25); return track end
end
local function say(npc, text)
	local bb = npc:FindFirstChild("HelperBubble", true)
	local l = bb and bb:FindFirstChild("Line", true)
	if l then l.Text = text end
end
local function spawnNPC(inst)
	local tpl = inst.npc.userId > 0 and templates[inst.npc.userId] or nil
	tpl = tpl or resident()
	if not tpl then return end
	local m = tpl:Clone()
	m.Name = "HelperNPC"
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		elseif d:IsA("LuaSourceContainer") then d:Destroy() end
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	local hrp = m:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then m:Destroy(); return end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hrp.Anchored = true
	local t = inst.type
	local pos = inst.yard.cf:PointToWorldSpace(Vector3.new(t.NPC[1], 0, t.NPC[2]))
	local look = inst.yard.cf.Position
	m:PivotTo(CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z)))
	-- stand on the pad: lowest body part (accessories such as tails or capes are ignored)
	local bottom = math.huge
	for _, d in ipairs(m:GetChildren()) do
		if d:IsA("BasePart") and d ~= hrp then bottom = math.min(bottom, d.Position.Y - d.Size.Y / 2) end
	end
	if bottom == math.huge then bottom = hrp.Position.Y - hrp.Size.Y / 2 - hum.HipHeight end
	m:PivotTo(m:GetPivot() + Vector3.new(0, inst.yard.cf.Y - bottom, 0))
	-- name tag: friend's display name + an explicit NPC label (game-written dialogue, never a real message)
	local head = m:FindFirstChild("Head") or hrp
	local bb = Instance.new("BillboardGui"); bb.Name = "HelperBubble"; bb.Size = UDim2.fromOffset(240, 96); bb.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	bb.MaxDistance = 120; bb.LightInfluence = 0; bb.Adornee = head
	local function lbl(name, y, h, size, color, text)
		local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Size = UDim2.new(1, 0, h, 0); l.Position = UDim2.new(0, 0, y, 0)
		l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.TextColor3 = color; l.Text = text
		local s = Instance.new("UIStroke"); s.Thickness = size; s.Color = Color3.fromRGB(20, 40, 85); s.Parent = l
		l.Parent = bb; return l
	end
	lbl("Line", 0, 0.42, 2, Color3.fromRGB(255, 244, 200), t.Line)
	lbl("Name", 0.44, 0.32, 2.5, Color3.new(1, 1, 1), inst.npc.name)
	lbl("Tag", 0.76, 0.22, 1.5, Color3.fromRGB(150, 225, 255), "NPC helper")
	bb.Parent = m
	m:SetAttribute("ContractInstance", inst.id)
	m.Parent = inst.yard.model:FindFirstChild("Scene") or inst.yard.model
	-- an anchored, non-colliding humanoid would drop into FallingDown (limp, with the newer constraint-based avatar joints): freeze its state
	hum.EvaluateStateMachine = false
	hum:ChangeState(Enum.HumanoidStateType.Running)
	inst.npcModel = m
	playAnim(m, "Idle", true)
	task.spawn(function()
		while inst.npcModel == m and m.Parent and inst.status == "active" do
			task.wait(rng:NextNumber(7, 12))
			if inst.npcModel == m and inst.status == "active" then playAnim(m, "Wave", false) end
		end
	end)
end

--------------------------------------------------
-- instances
--------------------------------------------------
local states = {}
local function stateOf(player)
	local st = states[player]
	if not st then
		st = {next = now() + rng:NextNumber(CFG.Offer.FirstDelay[1], CFG.Offer.FirstDelay[2]) * (TEST and 0 or 1) + (TEST and 1e9 or 0),
			recentTypes = {}, recentFriends = {}, lastReq = 0, away = 0}
		states[player] = st
	end
	return st
end
local function scheduleNext(st, scale)
	st.next = now() + rng:NextNumber(CFG.Offer.Interval[1], CFG.Offer.Interval[2]) * (scale or 1)
	if TEST and st.testHold then st.next = now() + 1e9 end
end
local function groupsPayload(inst)
	local out = {}
	for _, g in ipairs(inst.type.Groups) do
		local s = inst.groups[g.Key]
		table.insert(out, {Key = g.Key, Label = g.Label, Total = s and s.total or 0, Cleared = s and s.cleared or 0, Done = s and s.done or false})
	end
	return out
end
local function offerPayload(inst)
	local t = inst.type
	return {Id = inst.id, Type = t.Id, Name = t.Name, Icon = t.Icon, Line = t.Line, Hint = t.Hint, NpcName = inst.npc.name, NpcUserId = inst.npc.userId,
		IsFriend = inst.npc.userId > 0, Stage = inst.yard.stage, StageName = stageName(inst.yard.stage), Reward = inst.reward, Expires = inst.expires,
		Yard = inst.yard.model.Name, Gate = inst.yard.cf:PointToWorldSpace(Vector3.new(0, 0, -30))}
end
local function jobPayload(inst)
	local p = offerPayload(inst)
	p.Status, p.Deadline, p.Groups = inst.status, inst.deadline, groupsPayload(inst)
	p.Waypoint = inst.npcModel and inst.npcModel:GetPivot().Position or inst.yard.cf:PointToWorldSpace(Vector3.new(inst.type.NPC[1], 0, inst.type.NPC[2]))
	p.Zones = {}
	for _, z in ipairs(inst.zones or {}) do table.insert(p.Zones, {Group = z.group, Center = z.center, W = z.w * TS, D = z.d * TS}) end
	return p
end

local function removeFields(inst)
	local mine = Registry.Fields[inst.player]
	for _, z in ipairs(inst.zones or {}) do
		if mine then mine[z.id] = nil end
		local c = fieldData:FindFirstChild(z.id)
		if c then c:Destroy() end
	end
	if mine and next(mine) == nil then Registry.Fields[inst.player] = nil end
end
local function releaseYard(inst)
	local y = inst.yard
	if y and y.inst == inst then
		y.inst = nil
		y.lease += 1
		y.model:SetAttribute("BusyFor", nil)
	end
end
local function cleanup(inst, reason, keepSchedule)
	if inst.status == "ended" then return end
	local wasActive = inst.status == "active" or inst.status == "done"
	inst.status = "ended"
	removeFields(inst)
	if inst.scene then inst.scene:Destroy(); inst.scene = nil end
	if inst.npcModel then inst.npcModel:Destroy(); inst.npcModel = nil end
	releaseYard(inst)
	local st = states[inst.player]
	if st then
		if st.offer == inst then st.offer = nil end
		if st.job == inst then st.job = nil end
		if not keepSchedule then scheduleNext(st, wasActive and 1 or 0.6) end
	end
	if inst.player.Parent then event:FireClient(inst.player, "Ended", inst.id, reason) end
end

-- make an offer: reserve a free accessible yard nearby, pick the friend, snapshot reward + difficulty
local function makeOffer(player, forceType, forceStage)
	local st = stateOf(player)
	if st.offer or st.job or st.making then return false, "busy" end
	st.making = true
	local pos = rootPos(player)
	local best, bestD
	for _, y in ipairs(yards) do
		if not y.inst and accessible(player, y) and (not forceStage or y.stage == forceStage) then
			local d = pos and (pos - y.cf.Position).Magnitude or 1e6
			if (forceStage or d <= CFG.Offer.NearbyStuds) and (not bestD or d < bestD) then best, bestD = y, d end
		end
	end
	if not best then st.making = false; st.next = now() + CFG.Offer.RetryNoSite; return false, "no free yard" end
	local types = {}
	for _, t in ipairs(CFG.Types) do
		if not table.find(st.recentTypes, t.Id) then table.insert(types, t) end
	end
	local t = forceType and CFG.ById[forceType] or types[rng:NextInteger(1, #types)]
	local inst = {id = Http:GenerateGUID(false), player = player, type = t, yard = best, status = "offered", groups = {}}
	best.inst = inst; best.lease += 1; inst.lease = best.lease
	best.model:SetAttribute("BusyFor", player.UserId)
	table.insert(st.recentTypes, 1, t.Id)
	while #st.recentTypes > 2 do table.remove(st.recentTypes) end
	-- friend (cosmetic), with fallback
	local f = not st.noFriends and pickFriend(player, st) or nil
	local name, uid = CFG.NPC.Fallback.Name, 0
	if f and avatarTemplate(f.Id) then name, uid = f.DisplayName, f.Id end
	inst.npc = {name = name, userId = uid}
	-- snapshot reward + difficulty now (equipment changes or spending Snow later cannot change them)
	inst.rate = rewardRate(player, best.stage)
	local cycle, tc = expectedJob(player, t)
	local mult = CFG.Reward.Demanding[t.Id] and CFG.Reward.DemandingMult or CFG.Reward.Mult
	inst.expect = cycle
	inst.reward = nice(math.max(CFG.Reward.MinSnow, inst.rate * CFG.Reward.BonusSeconds, inst.rate * (mult * cycle - CFG.Reward.TileShare * tc)))
	inst.hp = contractHP(player, best.stage)
	st.making = false
	if not player.Parent or best.inst ~= inst then releaseYard(inst); return false, "gone" end
	inst.expires = now() + CFG.Offer.Lifetime
	st.offer = inst
	event:FireClient(player, "Offer", offerPayload(inst))
	return true, inst.id
end

local function finish(inst)
	if inst.status ~= "active" then return end
	inst.status = "done"
	local player = inst.player
	local d = DataService.Get(player)
	-- rebalance 2026-10-05: the reward is snapshotted without temporary Snow boosts; the boost active at completion is applied here
	-- exactly once, so a boosted job still pays ~2x boosted collecting (job tiles already pay through the normal boosted payout)
	local _, temp = snowMults(player)
	local pay = (temp > 1 and temp == temp and temp < math.huge) and nice(inst.reward * temp) or inst.reward
	inst.paid = pay
	if d then
		DataService.AddSnow(player, pay)
		local cs = type(d.Contracts) == "table" and d.Contracts or {}
		cs.Version = 1
		cs.Completed = (tonumber(cs.Completed) or 0) + 1
		cs.ByType = type(cs.ByType) == "table" and cs.ByType or {}
		cs.ByType[inst.type.Id] = (tonumber(cs.ByType[inst.type.Id]) or 0) + 1
		cs.BonusSnow = (tonumber(cs.BonusSnow) or 0) + pay
		d.Contracts = cs
		player:SetAttribute("ContractsCompleted", cs.Completed)
	end
	if inst.scene then inst.scene:SetAttribute("Completed", true) end
	if inst.npcModel then say(inst.npcModel, inst.type.Thanks); playAnim(inst.npcModel, "Cheer", false) end
	inst.finishedAt = now()
	event:FireClient(player, "Completed", inst.id, pay, inst.type.Thanks, inst.npc.name, os.clock() - (inst.startClock or os.clock()))
	removeFields(inst)
	task.delay(CFG.Job.Viewing, function() cleanup(inst, "Finished") end)
end
local function tileCleared(inst, zone)
	if inst.status ~= "active" then return end
	local g = inst.groups[zone.group]
	if not g or g.done then return end
	g.cleared += 1
	if g.cleared >= g.need then
		g.done = true
		if inst.scene then inst.scene:SetAttribute("Done_" .. zone.group, true) end
		event:FireClient(inst.player, "GroupDone", inst.id, zone.group)
	end
	if inst.scene then inst.scene:SetAttribute("G_" .. zone.group, math.min(1, g.cleared / g.need)) end
	inst.dirty = true
	for _, s in pairs(inst.groups) do if not s.done then return end end
	finish(inst)
end

local function accept(player, id)
	local st = stateOf(player)
	local inst = st.offer
	if not inst or inst.id ~= id or inst.status ~= "offered" then return {ok = false, msg = "That request is no longer available."} end
	if now() > inst.expires then cleanup(inst, "Expired"); return {ok = false, msg = "That request expired."} end
	if st.job then return {ok = false, msg = "Finish your current job first."} end
	if inst.yard.inst ~= inst or inst.yard.lease ~= inst.lease then return {ok = false, msg = "That yard is busy - try the next request."} end
	if not accessible(player, inst.yard) then return {ok = false, msg = "You can't reach that yard right now."} end
	local prefab = prefabs:FindFirstChild(inst.type.Id)
	if not prefab then cleanup(inst, "Unavailable"); return {ok = false, msg = "That job is unavailable."} end
	-- scene
	local scene = prefab:Clone()
	scene.Name = "Scene_" .. inst.type.Id
	scene:SetAttribute("ContractInstance", inst.id); scene:SetAttribute("OwnerUserId", player.UserId); scene:SetAttribute("ContractType", inst.type.Id)
	scene:PivotTo(inst.yard.cf)
	scene.Parent = inst.yard.model:FindFirstChild("Scene") or inst.yard.model
	inst.scene = scene
	-- personal snow fields (one per zone rectangle)
	local stage = inst.yard.stage
	-- softer-than-stage tiles pay proportionally less per layer (same Snow per unit of blade work as the normal fields)
	local spp = (stageAttr(stage, "SnowPerPhase") or 1) * math.min(1, inst.hp / math.max(1e-6, stageAttr(stage, "TileHP") or 1))
	local mine = Registry.Fields[player] or {}
	Registry.Fields[player] = mine
	inst.zones = {}
	local short = inst.id:sub(1, 8)
	for zi, z in ipairs(inst.type.Zones) do
		local center, w, d = CFG.ZoneWorld(inst.yard.cf, z.Rect, TS)
		local fid = ("CT_%s_%d"):format(short, zi)
		local maxHP = math.max(1e-6, inst.hp * (z.HPMult or 1))
		local def = {Id = fid, Name = inst.type.Name, Center = center, Width = w, Depth = d, SnowPerPhase = spp, RegrowSeconds = 1e9, TileHP = maxHP,
			Style = z.Style or stage, Stage = stage, StyleFolder = z.Style and "Contract" or nil, NoFloor = true, OwnerUserId = player.UserId}
		local zone = {id = fid, group = z.Group, center = center, w = w, d = d}
		local n = w * d
		local entry = {def = def, origin = SF.Origin(def), maxHP = maxHP, tough = z.Tough or PlowConfig.ToughnessOf(stage, maxHP),
			s = {phases = table.create(n, SF.MaxPhase), hp = table.create(n, maxHP), pending = {}}}
		entry.onTile = function() tileCleared(inst, zone) end
		mine[fid] = entry
		local cfg = Instance.new("Configuration"); cfg.Name = fid
		for k, v in pairs(def) do cfg:SetAttribute(k, v) end
		cfg:SetAttribute("Group", z.Group); cfg:SetAttribute("ContractInstance", inst.id)
		cfg.Parent = fieldData
		table.insert(inst.zones, zone)
		local g = inst.groups[z.Group] or {total = 0, cleared = 0, done = false}
		g.total += n
		inst.groups[z.Group] = g
	end
	for _, g in pairs(inst.groups) do g.need = math.max(1, math.ceil(g.total * CFG.Job.Tolerance)) end
	inst.status = "active"
	inst.deadline = now() + CFG.Job.Deadline
	inst.startClock = os.clock()
	st.offer, st.job, st.away = nil, inst, 0
	spawnNPC(inst)
	local payload = jobPayload(inst)
	event:FireClient(player, "Accepted", payload) -- every device of this player shows the same job (the requester also gets it as the reply)
	return {ok = true, job = payload}
end

request.OnServerInvoke = function(player, action, id, value)
	if type(action) ~= "string" then return {ok = false} end
	local st = stateOf(player)
	local t = os.clock()
	if t - st.lastReq < 0.25 then return {ok = false, msg = "One moment..."} end
	st.lastReq = t
	if action == "Sync" then
		return {ok = true, offer = st.offer and st.offer.status == "offered" and offerPayload(st.offer) or nil,
			job = st.job and (st.job.status == "active") and jobPayload(st.job) or nil, muted = player:GetAttribute("ContractMute") == true}
	elseif action == "Accept" then
		if type(id) ~= "string" then return {ok = false} end
		return accept(player, id)
	elseif action == "Cancel" then
		local inst = (st.job and st.job.id == id and st.job) or (st.offer and st.offer.id == id and st.offer)
		if not inst or inst.status == "done" or inst.status == "ended" then return {ok = false, msg = "Nothing to cancel."} end
		cleanup(inst, inst.status == "offered" and "Declined" or "Cancelled")
		return {ok = true}
	elseif action == "Mute" then
		local d = DataService.Get(player)
		local v = value == true
		if d then d.Settings = type(d.Settings) == "table" and d.Settings or {}; d.Settings.ContractMute = v end
		player:SetAttribute("ContractMute", v)
		return {ok = true, muted = v}
	end
	return {ok = false}
end
-- 2026-10-05 (Claude, arena): other systems end a job only through this normal cancellation (ArenaService asks the player first)
Registry.HasJob = function(player) local st = states[player]; return st ~= nil and st.job ~= nil and st.job.status == "active" end
Registry.Cancel = function(player)
	local st = states[player]
	local j = st and st.job
	if j and j.status == "active" then cleanup(j, "Cancelled") return true end
	return false
end

--------------------------------------------------
-- schedule, expiry, deadlines, abandonment, stage locks
--------------------------------------------------
local function eligible(player)
	if not CFG.Enabled or not DataService.Get(player) then return false end
	if player:GetAttribute("IntroActive") or player:GetAttribute("InGarage") or player:GetAttribute("InArenaIsland") then return false end
	if player:GetAttribute("PlowTutorialDone") ~= true then return false end
	return rootPos(player) ~= nil
end
task.spawn(function()
	while true do
		task.wait(1)
		local t = now()
		for _, player in ipairs(Players:GetPlayers()) do
			local st = states[player]
			if st then
				local o, j = st.offer, st.job
				if o and o.status == "offered" and t > o.expires then cleanup(o, "Expired") end
				if j and j.status == "active" then
					if t > j.deadline then cleanup(j, "TimeUp")
					elseif j.yard.stage ~= "Starter" and player:GetAttribute("Stage_" .. j.yard.stage) ~= true then cleanup(j, "StageLocked")
					else
						local pos = rootPos(player)
						local far = (player:GetAttribute("World") or 1) ~= j.yard.world or (pos and (pos - j.yard.cf.Position).Magnitude > CFG.Job.AbandonDistance)
						st.away = far and st.away + 1 or 0
						if st.away > CFG.Job.AbandonGrace then cleanup(j, "Abandoned") end
					end
					if j.dirty and j.status == "active" then j.dirty = false; event:FireClient(player, "Progress", j.id, groupsPayload(j)) end
				end
				if not st.offer and not st.job and not st.making and t >= st.next and eligible(player) then
					task.spawn(makeOffer, player)
				end
			elseif DataService.Get(player) then
				stateOf(player)
			end
		end
	end
end)
-- faster progress updates while driving (the 1 s loop is the fallback)
RunService.Heartbeat:Connect(function()
	for player, st in pairs(states) do
		local j = st.job
		if j and j.dirty and j.status == "active" and (j.lastPush or 0) + 0.3 < os.clock() then
			j.dirty, j.lastPush = false, os.clock()
			event:FireClient(player, "Progress", j.id, groupsPayload(j))
		end
	end
end)
DataService.OnLoaded(function(player, d)
	local s = type(d.Settings) == "table" and d.Settings or {}
	player:SetAttribute("ContractMute", s.ContractMute == true)
	local cs = type(d.Contracts) == "table" and d.Contracts or nil
	player:SetAttribute("ContractsCompleted", cs and tonumber(cs.Completed) or 0)
	stateOf(player)
end)
Players.PlayerRemoving:Connect(function(player)
	local st = states[player]
	if st then
		if st.offer then cleanup(st.offer, "Left", true) end
		if st.job then cleanup(st.job, "Left", true) end
	end
	Registry.Fields[player] = nil
	states[player] = nil
	friendCache[player.UserId] = nil
end)

--------------------------------------------------
-- isolated Studio tests only
--------------------------------------------------
if TEST then
	local hook = Instance.new("BindableFunction"); hook.Name = "ContractTestHook"; hook.Parent = SS
	hook.OnInvoke = function(op, player, a, b)
		local st = player and stateOf(player)
		if op == "Offer" then st.testHold = true; return makeOffer(player, a, b)
		elseif op == "Accept" then return accept(player, a)
		elseif op == "Info" then
			local i = st.job or st.offer
			if not i then return {none = true, next = st.next - now()} end
			return {id = i.id, status = i.status, type = i.type.Id, yard = i.yard.stage, reward = i.reward, hp = i.hp, rate = i.rate, npc = i.npc,
				groups = groupsPayload(i), lease = i.lease, yardLease = i.yard.lease, expires = i.expires and i.expires - now(), deadline = i.deadline and i.deadline - now()}
		elseif op == "Expire" then if st.offer then st.offer.expires = now() - 1 end; if st.job then st.job.deadline = now() - 1 end; return true
		elseif op == "Hold" then st.testHold = a ~= false; st.next = a ~= false and now() + 1e9 or now(); return true
		elseif op == "Friends" then local l = friendsOf(a or player.UserId); return #l, friendCache[a or player.UserId].ok
		elseif op == "Fields" then local n = 0; for _ in pairs(Registry.Fields[player] or {}) do n += 1 end; return n
		elseif op == "Yards" then local out = {}; for _, y in ipairs(yards) do table.insert(out, y.stage .. ":" .. tostring(y.inst and y.inst.player.Name)) end; return out
		elseif op == "Rate" then return rewardRate(player, a), contractHP(player, a)
		elseif op == "NoFriends" then st.noFriends = a ~= false; return true
		elseif op == "Finish" then local i = st.job; if not i then return nil end; finish(i); return i.paid, i.reward -- isolated tests: pay out the accepted job
		end
	end
end
