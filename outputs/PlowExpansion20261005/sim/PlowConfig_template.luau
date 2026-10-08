-- PlowConfig: the SNOWPLOW core loop. Parts, odds, prices, cooldowns and vehicle balance all live HERE.
--   ROLL a part offer in the garage -> BUY it with Snow (or RESERVE it) -> EQUIP blade / engine / running gear -> DRIVE through the fields
--   -> earn Snow + treasures -> improve the vehicle -> unlock stages and rebirth.
-- 2026-10-05 (Claude): 90-part catalog (30 blades, 30 engines, 30 running gear), progression-aware offer pool with luck that never removes
-- practical parts, bad-luck protection, engine acceleration, explicit field toughness. Generated from
-- outputs/PlowExpansion20261005/sim (catalog.py + final_balance.json -> gen_lua.py); edit those and regenerate, or edit here carefully.
-- Mode is a fixed identifier used by the existing client/state contract, not a runtime gameplay switch.
local RS = game:GetService("ReplicatedStorage")
local C = {}
C.Mode = "Snowplow" -- fixed current gameplay identifier

C.Shop = {
	RollCooldown = 2.0,   -- base seconds between offer rolls; multiplied by RollCooldownMult (rerolls share the cooldown)
	MinRollCooldownMult = 0.6, -- offer-speed tiles can shorten the base cooldown by at most 40%
	BigRevealRank = 4,    -- rarity rank (Rare = 4) that gets the stronger reveal
	MaxOwned = 99,
	ProtectAfter = 6,     -- bad-luck protection: after 6 rolls in a row without a USEFUL offer, the next roll is drawn only from useful parts
}
C.Rarities = {
	{Id = "Starter", Name = "Starter", Color = Color3.fromRGB(156, 166, 188)},
	{Id = "Common", Name = "Common", Color = Color3.fromRGB(150, 200, 255)},
	{Id = "Uncommon", Name = "Uncommon", Color = Color3.fromRGB(90, 220, 110)},
	{Id = "Rare", Name = "Rare", Color = Color3.fromRGB(80, 140, 255)},
	{Id = "Epic", Name = "Epic", Color = Color3.fromRGB(190, 90, 255)},
	{Id = "Legendary", Name = "Legendary", Color = Color3.fromRGB(255, 196, 46)},
}
C.RarityRank = {}
for i, r in ipairs(C.Rarities) do C.RarityRank[r.Id] = i end
C.Slots = {"Blade", "Engine", "Gear"}
C.Starter = {Blade = "blade_basic", Engine = "engine_starter", Gear = "gear_wheels"} -- free, owned by everyone, can never be lost

-- Price = explicit Snow cost (never depends on the wallet; an offer keeps the price it was rolled with).
-- Band = progression theme (1 Starter ... 7 Absolute Zero, 8 Sakura ... 14 Cosmic). Role: S starter, A practical, B premium, C legendary.
-- Blade: Width (studs), Soft / Hard = clearing multiplier on soft / hard snow (blended by the field's toughness).
-- Engine: Speed (studs/s), Power (clearing power multiplier), AccelTime (seconds from standstill to top speed).
-- Gear: SpeedMult, Traction (less sliding), Turn, Pivot (turning on the spot), Stability (stays upright), PowerMult (pushing power).
C.Parts = {
--@@PARTS@@
}
for id, def in pairs(C.Parts) do def.Id = id; def.Weight = def.Role == "S" and 0 or 1 end -- Weight kept for older readers; odds come from C.OfferPool

-- progression bands = field stages in unlock order
C.Bands = {--@@BANDS@@}
C.BandOfStage = {}
for i, s in ipairs(C.Bands) do C.BandOfStage[s] = i end
-- field toughness 0 (soft powder) .. 1 (hard ice): blade efficiency = Soft + (Hard - Soft) x toughness
C.Toughness = {--@@TOUGH@@}

-- OFFER POOL: relevance to the player's progression band x role weight x luck (rare parts only). The practical group (Common-role parts of
-- the current and previous band) always keeps at least PracticalFloor of the total, so luck can never push practical upgrades out.
C.Offers = {
	Relevance = {--@@REL@@}, -- by (part band - player band); older than -3: 0.04; newer than +3: never offered
	RoleWeight = {A = 1.0, B = 0.42, C = 0.16},
	PracticalFloor = 0.45,
	LuckSlope = 0.25, LuckCap = 2.0, -- luck factor = min(LuckCap, 1 + LuckSlope x log2(luck)); applied as factor^(rank - 3) to Rare+ parts
}
function C.LuckFactor(luck)
	luck = math.max(1, tonumber(luck) or 1)
	return math.min(C.Offers.LuckCap, 1 + C.Offers.LuckSlope * math.log(luck, 2))
end
function C.OfferPool(band, luck)
	band = math.clamp(math.floor(tonumber(band) or 1), 1, #C.Bands)
	local lf, O = C.LuckFactor(luck), C.Offers
	local list, total, prac = {}, 0, 0
	for id, def in pairs(C.Parts) do
		if def.Role ~= "S" then
			local d = def.Band - band
			local rel = O.Relevance[d] or (d < -3 and 0.04 or 0)
			if rel > 0 then
				local rank = C.RarityRank[def.Rarity] or 2
				local w = rel * (O.RoleWeight[def.Role] or 1) * lf ^ math.max(0, rank - 3)
				local practical = def.Role == "A" and (d == 0 or d == -1)
				table.insert(list, {Id = id, W = w, Practical = practical, Rank = rank})
				total += w
				if practical then prac += w end
			end
		end
	end
	if prac > 0 and prac / total < O.PracticalFloor then
		local s = O.PracticalFloor * (total - prac) / ((1 - O.PracticalFloor) * prac)
		total = 0
		for _, e in ipairs(list) do if e.Practical then e.W *= s end total += e.W end
	end
	table.sort(list, function(a, b)
		if a.Rank ~= b.Rank then return a.Rank < b.Rank end
		local da, db = C.Parts[a.Id].Band, C.Parts[b.Id].Band
		if da ~= db then return da < db end
		return a.Id < b.Id
	end)
	for _, e in ipairs(list) do e.P = e.W / total end
	return list
end
-- player band from a stage set ({[stageId] = true}); Sakura opens with the Portal
function C.BandFrom(stages)
	local best = 1
	for i, s in ipairs(C.Bands) do
		if s == "Starter" or (stages and (stages[s] or (s == "Sakura" and stages.Portal))) then best = math.max(best, i) end
	end
	return best
end

C.Drive = {
	AccelTime = 1.6,       -- default seconds from standstill to top speed (engines set their own AccelTime)
	ReverseFactor = 0.55,  -- reverse top speed vs forward
	BrakeFactor = 1.8,     -- braking / changing direction is this much stronger than accelerating
	TurnRate = 2.0,        -- rad/s at full steering (x gear Turn)
	MinTurn = 0.3,         -- steering strength at a standstill for gears without Pivot
	LateralGrip = 9,       -- sideways-slide damping per second at Traction 1
	UprightAssist = 6,     -- how hard the plow rights itself (x gear Stability)
	TopSpeedCap = 60,      -- no build + upgrade combination may exceed this (paths, bridges and the anti-cheat stay valid)
}
C.Vehicle = {
	HullSize = Vector3.new(5.4, 1.6, 7.4), HullClearance = 0.25, -- invisible collision box under the body
	BladeOffset = 6.2,     -- blade footprint centre in front of the hull centre (studs)
	SpawnAhead = 10, RecoverCooldown = 3.5, MaxRiderGap = 16, BoundsY = -150,
}
C.Clearing = {
	BasePower = 4.5,       -- damage per second the Starter loadout deals to every tile under its blade (field HP is in ReplicatedStorage.SnowStages)
	BladeDepth = 2.6,      -- front-to-back size of the blade footprint (studs)
	TileSlack = 0.3,       -- a tile counts as touched when its centre is within footprint + slack x tile size
	SpeedTolerance = 1.6,  -- the server ignores clearing while the plow moves faster than MaxSpeed x this + 8 studs/s
	MaxWidthMult = 1.6,    -- cap for blade width bonuses from upgrades
	ToughLow = 0.3, ToughSpan = 3.0, -- fallback toughness for fields without a C.Toughness entry: clamp((log10(tile HP) - ToughLow) / ToughSpan, 0, 1)
}
function C.ToughnessOf(stageId, tileHP)
	local t = C.Toughness[stageId or ""]
	if t then return t end
	return math.clamp((math.log10(math.max(1, tileHP or 1)) - C.Clearing.ToughLow) / C.Clearing.ToughSpan, 0, 1)
end

-- Upgrade mapping: PowerMult/PowerBonus/SpinMult -> clearing power; SizeMult/ReachMult -> blade width.
-- Width above the safe cap becomes proportional clearing power, so every width purchase remains useful.
-- LuckMult -> offer luck; RollCooldownMult -> pedestal cooldown; WalkSpeed -> vehicle speed (half strength).
local function num(x, d) x = tonumber(x); if not x or x ~= x or x == math.huge or x == -math.huge then return d end return x end
function C.StatsFor(build, mods)
	build, mods = build or {}, mods or {}
	local blade, engine, gear = C.Parts[build.Blade or ""], C.Parts[build.Engine or ""], C.Parts[build.Gear or ""]
	if blade and blade.Slot ~= "Blade" then blade = nil end
	if engine and engine.Slot ~= "Engine" then engine = nil end
	if gear and gear.Slot ~= "Gear" then gear = nil end
	local bs = blade and blade.Stats or {Width = 0, Soft = 0, Hard = 0}
	local es = engine and engine.Stats or {Speed = 0, Power = 0, AccelTime = C.Drive.AccelTime}
	local gs = gear and gear.Stats or {SpeedMult = 0, Traction = 0, Turn = 0, Pivot = 0, Stability = 1, PowerMult = 1}
	local rawWidthMult = math.max(1, num(mods.SizeMult, 1) * num(mods.ReachMult, 1))
	local widthMult = math.min(rawWidthMult, C.Clearing.MaxWidthMult)
	local widthPower = math.max(1, rawWidthMult / C.Clearing.MaxWidthMult)
	local power = (C.Clearing.BasePower * es.Power * gs.PowerMult + num(mods.PowerBonus, 0) * C.Clearing.BasePower) * num(mods.PowerMult, 1) * num(mods.SpinMult, 1) * widthPower
	local top = math.min(C.Drive.TopSpeedCap, es.Speed * gs.SpeedMult * num(mods.SpeedMult, 1))
	local accelTime = math.max(0.5, num(es.AccelTime, C.Drive.AccelTime))
	return {
		Valid = engine ~= nil and gear ~= nil, HasBlade = blade ~= nil,
		MaxSpeed = top, Accel = top / accelTime, AccelTime = accelTime, TurnRate = C.Drive.TurnRate * gs.Turn, Turn = gs.Turn, Pivot = gs.Pivot,
		Traction = gs.Traction, Stability = gs.Stability,
		BladeWidth = bs.Width * widthMult, Soft = bs.Soft, Hard = bs.Hard, ClearPower = (blade and power or 0),
	}
end

-- productive clearing estimate on a stage (layers per second), used for "useful offer" checks and the card comparisons.
-- power-limited rate vs coverage-limited rate (blade width x productive speed), blended with a smooth minimum.
function C.StageHP(stageId)
	local f = RS:FindFirstChild("SnowStages")
	local s = f and f:FindFirstChild(stageId or "")
	return math.max(1, num(s and s:GetAttribute("TileHP"), 1))
end
function C.Score(stats, stageId, tileHP)
	if not stats or not stats.HasBlade or stats.ClearPower <= 0 then return 0 end
	tileHP = tileHP or C.StageHP(stageId)
	local tile, slack = 3, 0.9
	local w = stats.BladeWidth + 2 * slack
	local tough = C.ToughnessOf(stageId, tileHP)
	local eff = stats.Soft + (stats.Hard - stats.Soft) * tough
	local power = (w / tile) * ((C.Clearing.BladeDepth + 2 * slack) / tile) * stats.ClearPower * eff / tileHP
	local handling = 0.42 + 0.32 * stats.Traction + 0.14 * math.min(stats.Pivot, 1) + 0.06 * math.min(stats.Turn or 1, 1.2) / 1.2
	handling = math.clamp(handling - math.min(0.12, 0.6 / math.max(stats.Accel, 1e-6)), 0.3, 0.9)
	local cover = 3 * (w / tile) * (stats.MaxSpeed * handling) / tile
	if power <= 0 or cover <= 0 then return 0 end
	return (power ^ -4 + cover ^ -4) ^ (-1 / 4)
end
return C
