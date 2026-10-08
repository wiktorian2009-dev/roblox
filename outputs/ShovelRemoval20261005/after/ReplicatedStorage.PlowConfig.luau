-- PlowConfig: the SNOWPLOW core loop. Parts, odds, prices, cooldowns and vehicle balance all live HERE.
--   ROLL a part offer -> BUY it with Snow (or RESERVE it) -> BUILD a snowplow in the garage -> DRIVE through the fields -> earn Snow + treasures.
-- Vehicles dig and parts come from rolled offers. Removed gameplay remains recoverable in the archival snapshots.
-- Mode is a fixed identifier used by the existing client/state contract, not a runtime gameplay switch.
local C = {}
C.Mode = "Snowplow" -- fixed current gameplay identifier

C.Shop = {
	RollCooldown = 2.0,   -- base seconds between offer rolls; multiplied by RollCooldownMult (rerolls share the cooldown)
	MinRollCooldownMult = 0.6, -- four offer-speed tiles can shorten the base cooldown by at most 40%
	LuckExponent = 0.35,  -- weight x luck^(exponent x (rank - 2)): luck makes rarer parts likelier; it never changes a price
	BigRevealRank = 4,    -- rarity rank (Rare = 4) that gets the stronger reveal
	MaxOwned = 99,
}
C.Rarities = {
	{Id = "Starter", Name = "Starter", Color = Color3.fromRGB(156, 166, 188)},
	{Id = "Common", Name = "Common", Color = Color3.fromRGB(150, 200, 255)},
	{Id = "Uncommon", Name = "Uncommon", Color = Color3.fromRGB(90, 220, 110)},
	{Id = "Rare", Name = "Rare", Color = Color3.fromRGB(80, 140, 255)},
	{Id = "Epic", Name = "Epic", Color = Color3.fromRGB(190, 90, 255)},
}
C.Slots = {"Blade", "Engine", "Gear"}
C.Starter = {Blade = "blade_basic", Engine = "engine_starter", Gear = "gear_wheels"} -- free, owned by everyone, can never be lost

-- Price = explicit Snow cost (never depends on the wallet). Weight 0 = never offered (starter parts). Odds = Weight / total weight.
-- Blade: Width (studs), Soft/Hard = clearing multiplier on soft / tough snow. Engine: Speed (studs/s), Power (clearing power multiplier).
-- Gear: SpeedMult, Traction (less sliding), Turn, Pivot (turning on the spot), Stability (stays upright), PowerMult.
C.Parts = {
	blade_basic = {Slot = "Blade", Name = "Basic Blade", Model = "BladeBasic", Rarity = "Starter", Weight = 0, Price = 0,
		Desc = "A sturdy steel blade.", Stats = {Width = 7, Soft = 1.0, Hard = 1.0}},
	blade_wide = {Slot = "Blade", Name = "Wide Clearing Blade", Model = "BladeWide", Rarity = "Common", Weight = 40, Price = 120,
		Desc = "Sweeps a huge swath of soft snow, but struggles with hard ice.", Stats = {Width = 12, Soft = 1.0, Hard = 0.7}},
	blade_ice = {Slot = "Blade", Name = "Reinforced Icebreaker", Model = "BladeIce", Rarity = "Rare", Weight = 8, Price = 2800,
		Desc = "Narrower, but smashes through tough snow and ice.", Stats = {Width = 8.5, Soft = 0.9, Hard = 5.5}},
	engine_starter = {Slot = "Engine", Name = "Starter Engine", Model = "EngineStarter", Rarity = "Starter", Weight = 0, Price = 0,
		Desc = "Small but reliable.", Stats = {Speed = 24, Power = 1.0}},
	engine_balanced = {Slot = "Engine", Name = "Balanced Engine", Model = "EngineBalanced", Rarity = "Uncommon", Weight = 22, Price = 450,
		Desc = "Faster and much stronger. A solid upgrade.", Stats = {Speed = 32, Power = 4.5}},
	engine_power = {Slot = "Engine", Name = "Powerful Engine", Model = "EnginePower", Rarity = "Epic", Weight = 3, Price = 9500,
		Desc = "Roaring power and top speed. A real saving goal!", Stats = {Speed = 40, Power = 14}},
	gear_wheels = {Slot = "Gear", Name = "Snow Wheels", Model = "GearWheels", Rarity = "Starter", Weight = 0, Price = 0,
		Desc = "Fast and nimble, but they slide.", Stats = {SpeedMult = 1.0, Traction = 0.55, Turn = 1.0, Pivot = 0.15, Stability = 1.0, PowerMult = 1.0}},
	gear_tracks = {Slot = "Gear", Name = "Tracked Treads", Model = "GearTracks", Rarity = "Uncommon", Weight = 16, Price = 650,
		Desc = "Grippy and steady, turns on the spot. A little slower.", Stats = {SpeedMult = 0.85, Traction = 0.95, Turn = 0.9, Pivot = 0.75, Stability = 1.7, PowerMult = 1.15}},
}

C.Drive = {
	AccelTime = 1.6,       -- seconds from standstill to top speed
	ReverseFactor = 0.55,  -- reverse top speed vs forward
	BrakeFactor = 1.8,     -- braking / changing direction is this much stronger than accelerating
	TurnRate = 2.0,        -- rad/s at full steering (x gear Turn)
	MinTurn = 0.3,         -- steering strength at a standstill for gears without Pivot
	LateralGrip = 9,       -- sideways-slide damping per second at Traction 1
	UprightAssist = 6,     -- how hard the plow rights itself (x gear Stability)
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
	ToughLow = 0.3, ToughSpan = 3.0, -- toughness of a field = clamp((log10(tile HP) - ToughLow) / ToughSpan, 0, 1)
}

-- Upgrade mapping: PowerMult/PowerBonus/SpinMult -> clearing power; SizeMult/ReachMult -> blade width.
-- Width above the safe cap becomes proportional clearing power, so every width purchase remains useful.
-- LuckMult -> offer luck; RollCooldownMult -> pedestal cooldown; WalkSpeed -> vehicle speed (half strength).
function C.StatsFor(build, mods)
	mods = mods or {}
	local blade, engine, gear = C.Parts[build.Blade or ""], C.Parts[build.Engine or ""], C.Parts[build.Gear or ""]
	local bs = blade and blade.Stats or {Width = 0, Soft = 0, Hard = 0}
	local es = engine and engine.Stats or {Speed = 0, Power = 0}
	local gs = gear and gear.Stats or {SpeedMult = 0, Traction = 0, Turn = 0, Pivot = 0, Stability = 1, PowerMult = 1}
	local rawWidthMult = math.max(1, (mods.SizeMult or 1) * (mods.ReachMult or 1))
	local widthMult = math.min(rawWidthMult, C.Clearing.MaxWidthMult)
	local widthPower = math.max(1, rawWidthMult / C.Clearing.MaxWidthMult)
	local power = (C.Clearing.BasePower * es.Power * gs.PowerMult + (mods.PowerBonus or 0) * C.Clearing.BasePower) * (mods.PowerMult or 1) * (mods.SpinMult or 1) * widthPower
	local top = es.Speed * gs.SpeedMult * (mods.SpeedMult or 1)
	return {
		Valid = engine ~= nil and gear ~= nil, HasBlade = blade ~= nil,
		MaxSpeed = top, Accel = top / C.Drive.AccelTime, TurnRate = C.Drive.TurnRate * gs.Turn, Pivot = gs.Pivot, Traction = gs.Traction, Stability = gs.Stability,
		BladeWidth = bs.Width * widthMult, Soft = bs.Soft, Hard = bs.Hard, ClearPower = (blade and power or 0),
	}
end
return C
