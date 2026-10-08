-- FrostKingConfig (2026-10-04, Claude): THE FROST KING co-op boss event. Every tunable lives here.
-- Server: ServerScriptService.FrostKingService. Client: StarterPlayerScripts.FrostKingClient. Models: ReplicatedStorage.FrostKingAssets.
local C = {}
C.Enabled = true
-- how often (random minutes between events) and how long
C.Schedule = {MinMinutes = 25, MaxMinutes = 40, MinPlayers = 1}
C.ArrivalSeconds = 30          -- announcement -> fight: time to JOIN or walk over
C.CombatSeconds = 240          -- fight time limit; after this the boss escapes
C.TargetSeconds = 200          -- health is sized so the fighters present need about this long
C.Uptime = 0.55                -- share of the fight players can really hit (the rest is dodging/approaching)
C.DefeatSeconds = 4            -- defeat tumble before rewards
C.CleanupSeconds = 7           -- reward screen time before the arena clears
C.EmptyEscapeSeconds = 45      -- nobody fighting for this long -> it escapes early
C.MinWarning = 0.9             -- no telegraph is ever shorter than this (seconds)
C.StaggerSeconds = 1.8         -- phase-change stagger (bonus-damage window)
-- arena: any snow field this big; SnowTop = height of full snow above the field box
C.Field = {MinWidth = 42, MinDepth = 42, Margin = 5, SnowTop = 1.6, AvoidPrevious = true}
C.Boss = {Radius = 7.5, MoveSpeed = 7, KeepDistance = 15} -- stops just outside a basic shovel's reach: step in to hit
-- fairness: event damage/s = Base x clamp(1 + LogStep x log10(real shovel power), 1, MaxMult)
-- health per fighter = TargetSeconds x Uptime x Base x (dps/Base)^HPExponent, so better gear finishes faster but never instantly
C.Power = {Base = 10, LogStep = 0.55, MaxMult = 4, HPExponent = 0.5, RecoveryBonus = 1.6, DpsRefreshSeconds = 10}
C.Health = {MinHP = 600, JoinShare = 0.8, MaxGrowthPerMinute = 1.0}
-- player event health (separate from character health: no deaths, no respawns)
C.Player = {HP = 100, Invulnerable = 1.6, KnockoutSeconds = 6, RespawnInvulnerable = 3}
C.Attacks = {
	Slide   = {Windup = 1.7, Dash = 1.0, Recover = 1.3, Length = 58, Width = 11, Damage = 30, Push = 70},
	Barrage = {Windup = 1.0, Count = {4, 6, 8}, Interval = 0.38, Flight = 1.6, Radius = 6, Spread = 5, Recover = 1.2, Damage = 22, Push = 45},
	Breath  = {Windup = 1.9, Duration = 1.8, Recover = 1.2, Range = 32, HalfAngle = 30, Damage = 30, Push = 55,
			   Patches = 3, PatchRadius = 5, PatchSeconds = 6, PatchDamage = 4, PatchTick = 0.5},
	Stomp   = {Windup = 1.5, Jump = 0.6, RingSpeed = 15, MaxRadius = 34, RingWidth = 3, JumpClear = 1.2, JumpGrace = 0.35, SecondRingDelay = 0.9,
			   Recover = 1.0, Damage = 28, Push = 60},
	Spin    = {Windup = 1.3, Duration = 2.2, Radius = 15, FinalRadius = 17, Recover = 3.0, Damage = 25, Push = 65},
}
-- HalfAngle must stay 30: the TeleCone mesh is built as a 60-degree sector
C.Phases = {
	{Below = 1.01, Pool = {"Barrage", "Slide", "Spin"}, Rest = {3.0, 4.0}, Speed = 1.0},
	{Below = 0.65, Pool = {"Barrage", "Slide", "Spin", "Breath", "Stomp"}, Rest = {2.6, 3.4}, Speed = 1.1},
	{Below = 0.30, Pool = {"Barrage", "Slide", "Spin", "Breath", "Stomp"}, Rest = {2.2, 3.0}, Speed = 1.2, Final = true},
}
C.Rewards = {
	SnowMinutes = 5, MinSnow = 100,
	MinEngagedSeconds = 40, MinHitSeconds = 8,    -- to qualify: this long near the boss AND this long actually hitting it
	FullEngagedSeconds = 90, PartialFloor = 0.5, -- full Snow at 90 s near the boss, never less than half once qualified
	EngageRange = 46, EscapeShare = 0.2,          -- escape: qualified fighters still get 20%
	TreasureChance = 0.4, BoostChance = 0.35, Boosts = {"Snow2", "Luck2"}, BoostSeconds = 300,
	RateClamp = {0.3, 3}, ActiveShare = 0.6, MaxLayersPerSecond = 30,
}
C.VFX = {CullDistance = 260, ShakeDistance = 70}
-- Studio isolated tests only (ServerStorage.BalanceTestMode = true): shorter arrival, no automatic spawns
C.Test = {ArrivalSeconds = 10, AutoSpawn = false}
return C
