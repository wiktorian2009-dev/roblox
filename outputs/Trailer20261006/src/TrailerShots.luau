-- TrailerShots (2026-10-06, Claude): DATA for the page trailer (DESIGN rev 2, sections 1, 2.5, 3, 6, 9, 10). Shot list, keys,
-- needs/fallbacks, text cards, the server schedule, the real-plow move plan, warm-up lists and scout anchors. No side effects:
-- Edit can require it and call ValidateShots() (pure; it reads PlowConfig / PetConfig / PassConfig from ReplicatedStorage).
-- Times are seconds after ROLL_A ("tau"). Point specs: a Vector3 (world), or {at = "<anchor>", off = Vector3, a = n, s = n,
-- u = n, v = n, y = n} resolved by TrailerClient (y is measured from the anchor's ground height when it has one), or
-- {lerp = {specA, specB, k}}. ref = "Bay" maps Bay_1 world values into the player's own bay.
local V = Vector3.new
local S = {}
S.Version = "rev2 2026-10-07"

S.Config = {
	StartKey = Enum.KeyCode.F8, SlateMax = 10, WarmPark = 0.6, GateTimeout = 120, ArmLead = 0.7, RollWait = 10,
	PassA = {length = 29.5},
	PassB = {gap = 4.0, shot = "S11_CandyPath", rollB = 33.5, length = 4.0, shift = 8.0}, -- pass B tau 33.5 plays S11 at 25.5
	EndBlack = 0.5, EndMagenta = 0.5, MaxTotal = 37.5 + 1.0, WorldGuiKeep = {},
	UnlockStage = "Candy", -- the one stage the run unlocks on camera (TrailerServer actions.UnlockCandy); its wall is never hidden
	-- TrailerSplit (section 12.7): "1-8" ends after shot 8; "9-11" rolls at shot 9 (= trailer 18.0) and keeps pass B
	Split = {
		full = {from = 0, to = 29.5, passB = true},
		["1-8"] = {from = 0, to = 18.0, passB = false},
		["9-11"] = {from = 18.0, to = 29.5, passB = true},
	},
	-- review fix: the gate distance also covers shot 5 (dist >= max(MinDist, max(speed, PlanSpeed) x (ArmLead + 2.45) + LaneNeed
	-- + LaneEndMargin + 4) ~ 91 studs); 'wide' brakes to min(LaneRun, lane end - LaneEndMargin); MinSpeed sits below AFK cruise
	Gate = {YawErrDeg = 8, YawRate = 0.25, YawWindow = 0.3, MinDist = 53, MinSpeed = 10.5, PlanSpeed = 14.4, PreferMaxX = 45, PreferFor = 60,
		LaneNeed = 38, LaneRun = 45, LaneEndMargin = 4,
		HoldRadius = 3, HoldSpeed = 0.5, HoldYawDeg = 10, Log = 5},
	Drive = {Lookahead = 8, SteerGain = 1.4, BrakeSafety = 0.85, PlanPull = 0.15, StopSlack = 0.4, ArriveRadius = 0.8,
		Early = 1.05, ReverseFactor = 0.55, JoinTol = 0.5, AlignTol = 1.5, AlignYawDeg = 6, NearRadius = 6},
	Puppet = {Kinematic = true, BrakeShare = 0.8, Axle = 3.1, RecordHz = 30},
	Text = {Navy = Color3.fromRGB(20, 40, 85), MaxLine = 0.82, WidthFit = 0.9, SafeShare = 0.98, MinShare = 0.8, ShareStep = 0.005,
		MenuFallback = Vector2.new(64, 64), Magenta = Color3.fromRGB(255, 0, 255)},
	Grade = {Tween = 0.3},
	SnapPulse = 0.25,
	FpsBucket = 0.5,
}

S.Profile = {
	HeroC = {Blade = "blade_katana", Engine = "engine_blossom", Gear = "gear_bamboo", Body = "body_starter"},
	HeroAltBlade = "blade_lotus",
	SwapBlade = "blade_wide",
	Pets = {"Snow Bunny", "Penguin", "Fennec Fox"},
	MiniLevel = 7,
	Upgrades = {"M_Expansion2", "M_Expansion5"},
	BlockEvent = {"LuckyWind", 900},
	OpenStages = {"Starter", "Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Portal"},
	Offer = {slot = "2", part = "blade_wide", price = 120, left = 600},
}

-- scout values (DESIGN marks them "(scout)"): fallbacks when the live object is not found; confirmed in Edit 2026-10-07
-- (critic fixes): G = the Candy "Stage paywall" part (1812, 10.4, 0), ground = CandyGate.Bases top 1.4; Wh = the X_Headframe.Wheel
-- MeshPart; the Sakura-Candy deck lives in World2.Paths20261006.SakuraToCandy (World2.Bridges is empty); Candy ground is y 4.0,
-- the entrance deck top 4.1, WaferBridge deck 4.9 (x 1951-1965). HoldBack 34 put P_hold on the koi-pond bridge crown (1778, 3.6, 0):
-- 8 puts it on flat ground between the bridge foot (x ~1799) and the gate (wall face x ~1811).
S.Anchors = {
	E = V(128, 7.6, -262), Wh = V(192, 25.2, 100), H = V(236, 3.7, 125), HE = V(-327, 1.1, 183), PT = V(-323, 28, 255),
	G = V(1812, 1.4, 0), SakuraArrival = V(1590, 1.5, 0), CandyEntrance = V(1894, 4.1, 55),
	PWait = V(1928, 4, 55), PStop = V(1962, 4.9, 55), Bay1 = CFrame.new(-377, 0.2, -237),
	CandyField = "Candy_1", HoldBack = 8, LegAhead = 10,
	-- leg 1 fallback when PathfindingService fails (critic fix): Sakura's main path (z 0, 8 wide, lanterns at z +-5.8) then the
	-- koi-pond bridge deck (Props.Bridge, crown y 3.9 at x 1782). Edit hull sweeps (5.4 wide, HullClearance 1.1) found no way
	-- AROUND the bridge: north of it the pond corridor to the Pagoda podium is ~6 studs at x 1792, south the KoiShrine, the
	-- BlossomBushA and the SakuraToCandy side walls (z -13.6 from x 1804.5) close it, and hedges seal the garden (x 1810.5,
	-- |z| >= 10). So the way-points keep the plow on the centre line, square onto the bridge and off it before P_hold.
	-- Only points strictly between the leg start and P_hold (along the leg) are used.
	Leg1Via = {V(1700, 0.2, 0), V(1758, 0.2, 0), V(1782, 3.9, 0), V(1800, 0, 0)},
	Paths = {Egg = "StageEggs.StageEggs_Desert", Heart = "W1Remaster.Crystal.X_Heart", Headframe = "W1Remaster.Crystal.X_Headframe",
		Engine = "W1Remaster.AbsoluteZero.Z_HeartEngine", Portal = "AbsoluteZeroPortal", Bridges = "World2.Paths20261006.SakuraToCandy",
		Curtains = "World2.CloudCurtains", Globe = "FrostfallVillage.Snowglobe", EggDisplay = "FrostfallVillage.EggDisplay",
		HelpYards = "ContractYards"},
}

--------------------------------------------------------------------------------------------------------------------------------
-- shots (section 1 and 6). cam types: path, follow, orbit, static, hold.
--------------------------------------------------------------------------------------------------------------------------------
S.Shots = {
	{
		id = "S01_StarterAfk", start = 0.0, dur = 2.4, part = "A", subject = "plow", logY = true,
		grade = {Contrast = 0.04, Saturation = 0.05},
		cam = {type = "follow", posTau = 0.06, yawTau = 0.25, keys = {
			{t = 0, offset = V(0.8, 1.3, -10), look = V(0, 1.6, 0), fov = 60},
			{t = 0.35, offset = V(1.5, 1.8, -7.5), look = V(0, 1.6, 0), fov = 60},
			{t = 0.7, offset = V(1, 5, -2), look = V(0, 1, -4), fov = 64},
			{t = 1, offset = V(0, 11, 4), look = V(0, 0, -10), fov = 62},
		}},
	},
	{
		id = "S02_LobbyPush", start = 2.4, dur = 1.2, part = "A",
		grade = {Brightness = 0.02},
		cam = {type = "path", ease = "InQuad", keys = {
			{t = 0, pos = V(-172, 6.5, -282), look = V(-102, 10, -282), fov = 64},
			{t = 1, pos = V(-114, 11, -282), look = V(-101, 11, -282), fov = 52},
		}},
	},
	{
		id = "S03_Bay", start = 3.6, dur = 2.2, part = "A",
		grade = {Contrast = 0.03},
		cam = {type = "path", ease = "InOutSine", ref = "Bay", keys = {
			{t = 0, pos = V(-366, 9.5, -262), look = V(-368, 3.5, -234), fov = 58},
			{t = 0.55, pos = V(-369, 8, -248), look = V(-362, 5, -238), fov = 48},
			{t = 1, pos = V(-366.5, 6.6, -239.5), look = V(-359.8, 6.2, -237), fov = 34},
		}},
	},
	{
		id = "S04_BayOrbit", start = 5.8, dur = 1.4, part = "A",
		grade = {Contrast = 0.03},
		need = {bladeWide = true},
		cam = {type = "orbit", ease = "InOutSine", ref = "Bay", center = V(-377, 3.2, -231), radius = 13, height = 5.5, lookHeight = 2.6,
			a0 = -125, a1 = -65, fov0 = 50, fov1 = 46},
		fallbacks = {
			{name = "pedestal hold", cam = {type = "hold", fromShot = "S03_Bay", drift = 2}},
		},
	},
	{
		id = "S05_WideLane", start = 7.2, dur = 3.0, part = "A", subject = "plow", logY = true,
		grade = {Contrast = 0.04, Saturation = 0.05},
		need = {flag = "s05ok"},
		cam = {type = "follow", posTau = 0.06, yawTau = 0.25, orbitDeg = {0, 18}, keys = {
			{t = 0, offset = V(-7, 6.5, 13), look = V(0, 0.5, -10), fov = 60},
			{t = 1, offset = V(-9.5, 8.5, 7), look = V(0, 0.5, -14), fov = 62},
		}},
		fallbacks = {
			{name = "starter crane", cam = {type = "static", pos = V(35, 48, -360), look = V(35, 0, -288), fov = 55}},
		},
	},
	{
		id = "S06_DesertEgg", start = 10.2, dur = 3.0, part = "A", subject = "puppet", logY = true, hideReal = true,
		grade = {Saturation = 0.03},
		need = {parts = {at = "E", radius = 40, min = 40}},
		cam = {type = "path", ease = "OutSine", keys = {
			{t = 0, pos = V(150, 10.5, -244), look = V(130, 6, -260), fov = 50},
			{t = 1, pos = V(145, 9, -248), look = V(130.5, 5.5, -259.5), fov = 46},
		}},
		puppet = {name = "HeroC_Desert", track = "Desert", kind = "stop", from = V(150, 0, -280), to = V(136, 0, -266.5),
			heading = V(-0.72, 0, 0.69), enter = 10.7, stop = 12.3},
		fallbacks = {
			{name = "lobby egg", cam = {type = "path", ease = "OutSine", keys = {
				{t = 0, pos = V(-118, 8.5, -265), look = V(-100.8, 6, -267.5), fov = 50},
				{t = 1, pos = V(-110, 6.8, -266.5), look = V(-100.8, 6, -267.5), fov = 46},
			}}},
		},
	},
	{
		id = "S07_Crystal", start = 13.2, dur = 2.6, part = "A", hideReal = true,
		grade = {Saturation = 0.04},
		need = {parts = {at = "H", radius = 60, min = 80}},
		cam = {type = "path", ease = "InOutSine", keys = {
			{t = 0, pos = {at = "Wh", off = V(8, -6, -14)}, look = {at = "Wh"}, fov = 55},
			{t = 0.5, pos = {at = "Wh", off = V(22, 6, -10)}, look = {lerp = {{at = "Wh"}, {at = "H", off = V(0, 16, 0)}, 0.6}}},
			{t = 1, pos = {at = "H", off = V(-24, 20, -26)}, look = {at = "H", off = V(2, 16, 4)}, fov = 52},
		}},
		puppet = {name = "HeroC_Crystal", track = "Crystal", kind = "pass", optional = true,
			from = {at = "H", off = V(34, 0, -28)}, to = {at = "H", off = V(30, 0, 22)}, enter = 13.5, exit = 15.6},
		fallbacks = {
			{name = "crystal pavilion", cam = {type = "path", ease = "InOutSine", keys = {
				{t = 0, pos = V(-140, 22, -240), look = V(-140, 4, -233), fov = 55},
				{t = 1, pos = V(-132, 20, -244), look = V(-140, 4, -233), fov = 52},
			}}},
		},
	},
	{
		id = "S08_AzPortal", start = 15.8, dur = 2.2, part = "A",
		grade = {Brightness = 0.02},
		need = {parts = {at = "PT", radius = 60, min = 80}},
		cam = {type = "path", ease = "InOutQuad", keys = {
			{t = 0, pos = V(-303, 8, 176), look = {at = "HE", off = V(0, 9, 0)}, fov = 56},
			{t = 1, pos = V(-301, 15, 220), look = {at = "PT", off = V(0, -4, 0)}, fov = 50},
		}},
		fallbacks = {
			{name = "crystal hold", cam = {type = "hold", fromShot = "S07_Crystal", drift = 3}},
		},
	},
	{
		id = "S09_CandyGate", start = 18.0, dur = 4.8, part = "B", subject = "plow", logY = true,
		grade = {},
		cam = {type = "path", ease = "InOutSine", clampX = 1815, keys = {
			{t = 0, pos = {at = "G", a = -20, s = 7, y = 5}, look = {at = "G", a = 45, y = 7}, fov = 56},
			{t = 0.45, pos = {at = "G", a = -18, s = 6, y = 7}, look = {at = "G", a = 40, y = 4}},
			{t = 1, pos = {at = "G", a = -13, s = 3, y = 18}, look = {at = "G", a = 70, y = 0}, fov = 60},
		}},
		need = {plowAt = {at = "PHold", radius = 6, by = 19.4}}, -- failing it is fallback (a): the same keys, camera only
		fallbacks = {
			{name = "camera only", sameCam = true},
		},
	},
	{
		id = "S10_Minis", start = 22.8, dur = 2.7, part = "B",
		grade = {Saturation = 0.03},
		need = {minis = {style = "Candy"}},
		cam = {type = "path", ease = "InOutSine", keys = {
			{t = 0, pos = {at = "C", u = -46, v = -38, y = 26}, look = {at = "C", u = -11}, fov = 50},
			{t = 1, pos = {at = "C", u = -36, v = -44, y = 40}, look = {at = "C", u = 9, v = 4}, fov = 48},
		}},
		fallbacks = {
			{name = "puppet minis", need = {field = "Candy_1"}, minis = {field = "Candy_1"}, cam = {type = "path", ease = "InOutSine", frame = "C1", keys = {
				{t = 0, pos = {at = "C1", u = -46, v = -38, y = 26}, look = {at = "C1", u = -11}, fov = 50},
				{t = 1, pos = {at = "C1", u = -36, v = -44, y = 40}, look = {at = "C1", u = 9, v = 4}, fov = 48},
			}}},
			{name = "gate hold", cam = {type = "hold", fromShot = "S09_CandyGate", drift = 3}},
		},
	},
	{
		id = "S11_CandyPath", start = 25.5, dur = 4.0, part = "B", subject = "plow", logY = true,
		grade = {Brightness = -0.03, Contrast = 0.05},
		need = {plowAt = {at = "PWait", to = "PStop", radius = 6, by = 25.1}}, -- review fix: on the P_wait -> P_stop segment (early departure)
		cam = {type = "path", ease = "OutSine", keys = {
			{t = 0, pos = V(1938, 15, 77), look = V(1966, 9, 52), fov = 50},
			{t = 1, pos = V(1944, 13.5, 72), look = V(1966, 8.5, 52), fov = 46},
		}},
		fallbacks = {
			{name = "path push, no plow", sameCam = true},
		},
	},
}

--------------------------------------------------------------------------------------------------------------------------------
-- text (section 9.2). kinds: callout (pop 1.25 -> 1 + fade in, fade out ending at tOut), cardA (pop 1.35 -> 1 then pulse),
-- tagline (pop 0.9 -> 1 + fade 0.2, cut at tOut). size / cy are fractions of the SafeFrame height.
--------------------------------------------------------------------------------------------------------------------------------
S.Cards = {
	{id = "Callout1", kind = "callout", font = "FredokaOne", size = 0.12, tIn = 0.4, tOut = 2.4,
		lines = {{text = "PLOW SNOW", cy = 0.125}, {text = "TO EARN SNOW", cy = 0.255}}},
	{id = "Callout3", kind = "callout", font = "FredokaOne", size = 0.12, tIn = 4.0, tOut = 7.0,
		lines = {{text = "ROLL PARTS", cy = 0.125}, {text = "BUILD YOUR PLOW", cy = 0.255}}},
	{id = "Callout6", kind = "callout", font = "FredokaOne", size = 0.12, tIn = 10.6, tOut = 13.0,
		lines = {{text = "HATCH PETS", cy = 0.19}}},
	{id = "CardA", kind = "cardA", font = "LuckiestGuy", size = 0.27, tIn = 25.9, tOut = 29.5, capLog = true,
		lines = {{text = "PLAY NOW!", cy = 0.24}}},
	{id = "CardATag", kind = "tagline", font = "FredokaOne", size = 0.10, tIn = 26.3, tOut = 29.5,
		lines = {{text = "PLOW SNOW. ROLL PARTS.", cy = 0.45, tIn = 26.3}, {text = "HATCH PETS.", cy = 0.55, tIn = 26.45}}},
	{id = "CardB", kind = "tagline", font = "FredokaOne", size = 0.14, tIn = 33.9, tOut = 37.5,
		lines = {{text = "PLOW SNOW.", cy = 0.20, tIn = 33.9}, {text = "ROLL PARTS.", cy = 0.34, tIn = 34.05}, {text = "HATCH PETS.", cy = 0.48, tIn = 34.2}}},
}
S.AllowedText = {
	["PLOW SNOW"] = true, ["TO EARN SNOW"] = true, ["ROLL PARTS"] = true, ["BUILD YOUR PLOW"] = true, ["HATCH PETS"] = true,
	["PLAY NOW!"] = true, ["PLOW SNOW. ROLL PARTS."] = true, ["HATCH PETS."] = true, ["PLOW SNOW."] = true, ["ROLL PARTS."] = true,
}

--------------------------------------------------------------------------------------------------------------------------------
-- server schedule (section 2.5), tau seconds. part A = supports shots 1-8, part B = shots 9-11 (TrailerSplit filters by it).
-- Done / EndTest / Cap are added by TrailerServer from the content end (38.5 / 40 / 60 for the full run).
--------------------------------------------------------------------------------------------------------------------------------
S.Server = {
	{t = 1.0, action = "Stream", pos = V(128, 8, -262), part = "A"},
	{t = 2.45, action = "AfkOff", part = "A"},
	{t = 2.50, action = "SwapBlade", part = "A"},
	{t = 2.70, action = "Spawn", part = "A"},
	{t = 3.20, action = "SpawnRetry", part = "A"},
	{t = 4.0, action = "Stream", pos = V(236, 10, 125), part = "A"},
	{t = 4.0, action = "Stream", pos = V(192, 10, 100), part = "A"},
	{t = 5.00, action = "PublishBay", part = "A"},
	{t = 6.0, action = "Stream", pos = V(1590, 3, 0), part = "B"},
	{t = 6.0, action = "StreamGate", part = "B"},
	{t = 8.0, action = "Stream", pos = V(-315, 10, 215), part = "A"},
	{t = 9.0, action = "Stream", pos = V(128, 8, -262), part = "A"},
	{t = 10.20, action = "HeroBuild", part = "B"},
	{t = 10.25, action = "Travel", dest = "Sakura", part = "B"},
	{t = 10.90, action = "TravelRetry", dest = "Sakura", part = "B"},
	{t = 11.0, action = "Stream", pos = V(236, 10, 125), part = "A"},
	{t = 11.0, action = "Stream", pos = V(192, 10, 100), part = "A"},
	{t = 12.0, action = "Stream", pos = V(1940, 6, 55), part = "B"},
	{t = 12.0, action = "Stream", pos = V(2021, 4, 55), part = "B"},
	{t = 13.0, action = "Stream", pos = V(-315, 10, 215), part = "A"},
	{t = 18.10, action = "UnlockCandy", part = "B"},
}
S.ServerTail = {Done = 1.0, EndTest = 2.5, Cap = 22.5} -- seconds after the content end (37.5 full run)

--------------------------------------------------------------------------------------------------------------------------------
-- real plow moves (sections 5, 6.5, 6.9, 6.11). 'at' = the spec departure; a route with arriveBy / crossAt departs earlier when
-- the build's own acceleration needs it (never before the previous move started). Inputs only: PlowTestMove / AFK attributes.
--------------------------------------------------------------------------------------------------------------------------------
S.PlowMoves = {
	{id = "afk", at = -1e9, kind = "afk"},
	{id = "join", at = 2.45, kind = "join", store = 2.40, newBy = 4.0, alignedBy = 6.2},
	{id = "wide", at = 6.20, kind = "lane"},
	{id = "stopW1", at = 10.20, kind = "hold"},
	{id = "toHold", at = 10.90, kind = "route", route = "leg1", stop = true, arriveBy = 17.5, waitSpawn = true},
	{id = "cross", at = 19.55, kind = "route", route = "leg2", stop = true, crossAt = {point = "G", t = 20.4}, arriveBy = 23.0},
	{id = "toStop", at = 25.20, kind = "route", route = "leg3", stop = true, arriveBy = 26.5, needNear = "PWait"},
	{id = "back", at = 29.6, kind = "route", route = "leg3back", reverse = true, stop = true, arriveBy = 32.0, needNear = "PStop"},
	{id = "toStopB", at = 32.9, kind = "route", route = "leg3", stop = true, arriveBy = 34.5, needNear = "PWait"},
}

--------------------------------------------------------------------------------------------------------------------------------
-- warm-up (section 2.4 step 2)
--------------------------------------------------------------------------------------------------------------------------------
S.Warm = {
	World1Stream = {V(128, 8, -262), V(236, 10, 125), V(192, 10, 100), V(-315, 10, 215), V(-323, 28, 255)},
	World1Park = {"S02_LobbyPush", "S03_Bay", "S04_BayOrbit", "S06_DesertEgg", "S07_Crystal", "S08_AzPortal"},
	World2Stream = {
		{pos = V(1590, 3, 0), radius = 40, min = 30},
		{at = "G", radius = 40, min = 30},
		{pos = V(1940, 6, 55), radius = 40, min = 30},
		{pos = V(2021, 4, 55), radius = 50, min = 30},
	},
	World2Park = {"S09_CandyGate", "S10_Minis", "S11_CandyPath"},
	PartsWait = 8,
}

--------------------------------------------------------------------------------------------------------------------------------
-- hide list data (section 8)
--------------------------------------------------------------------------------------------------------------------------------
S.Hide = {
	CameraEffects = {"MenuBlur", "HatchBlur", "UpgradeBlur"},
	CameraWeather = "EventWeather",
	DevBoxes = {"Candy_1", "Clockwork_2"},
	FrostKingPrefix = "FrostKing",
	HumanoidKeep = {"TrailerPuppets", "FollowingPets", "MiniPlows", "Snowplows"},
	ShotGeometry = {}, -- [shotId] = {"Workspace.Path.To.Model", ...}: round-0 finds (FROSTFALL letters, padlock geometry) -> LTM 1
}

--------------------------------------------------------------------------------------------------------------------------------
-- ValidateShots (Edit, pure): returns ok, {errors}
--------------------------------------------------------------------------------------------------------------------------------
local function finiteV(v) return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
	and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6 end
local function specOk(p)
	if typeof(p) == "Vector3" then return finiteV(p) end
	if type(p) ~= "table" then return false end
	if p.lerp then return specOk(p.lerp[1]) and specOk(p.lerp[2]) and type(p.lerp[3]) == "number" end
	if type(p.at) ~= "string" then return false end
	if p.off ~= nil and not finiteV(p.off) then return false end
	for _, k in ipairs({"a", "s", "u", "v", "y"}) do
		if p[k] ~= nil and (type(p[k]) ~= "number" or p[k] ~= p[k]) then return false end
	end
	return true
end
local CAM_TYPES = {path = true, follow = true, orbit = true, static = true, hold = true}
local function checkCam(cam, where, errs, ids)
	if type(cam) ~= "table" or not CAM_TYPES[cam.type] then table.insert(errs, where .. ": bad cam type"); return end
	if cam.type == "path" or cam.type == "follow" then
		local keys = cam.keys
		if type(keys) ~= "table" or #keys < 2 then table.insert(errs, where .. ": needs >= 2 keys"); return end
		local last = -1
		for i, k in ipairs(keys) do
			if type(k.t) ~= "number" or k.t <= last or k.t < 0 or k.t > 1 then table.insert(errs, where .. ": key " .. i .. " t not ascending in 0..1") end
			last = k.t or last
			if cam.type == "path" then
				if not specOk(k.pos) or not specOk(k.look) then table.insert(errs, where .. ": key " .. i .. " pos/look") end
			else
				if not finiteV(k.offset) or not finiteV(k.look) then table.insert(errs, where .. ": key " .. i .. " offset/look") end
			end
			if k.fov ~= nil and (type(k.fov) ~= "number" or k.fov < 5 or k.fov > 110) then table.insert(errs, where .. ": key " .. i .. " fov") end
		end
		if keys[1].t ~= 0 or keys[#keys].t ~= 1 then table.insert(errs, where .. ": keys must start at 0 and end at 1") end
		if keys[1].fov == nil then table.insert(errs, where .. ": first key needs a fov") end
	elseif cam.type == "orbit" then
		if not finiteV(cam.center) or type(cam.radius) ~= "number" or type(cam.a0) ~= "number" or type(cam.a1) ~= "number" then
			table.insert(errs, where .. ": orbit fields")
		end
	elseif cam.type == "static" then
		if not specOk(cam.pos) or not specOk(cam.look) or type(cam.fov) ~= "number" then table.insert(errs, where .. ": static fields") end
	elseif cam.type == "hold" then
		if not ids[cam.fromShot or ""] then table.insert(errs, where .. ": hold.fromShot unknown") end
	end
end

function S.ValidateShots()
	local errs = {}
	local RS = game:GetService("ReplicatedStorage")
	local okC, C = pcall(function() return require(RS:FindFirstChild("PlowConfig")) end)
	local okP, PetConfig = pcall(function() return require(RS:FindFirstChild("PetConfig")) end)
	local okX, PassConfig = pcall(function() return require(RS:FindFirstChild("PassConfig")) end)
	if not okC then table.insert(errs, "PlowConfig not readable"); C = nil end
	if not okP then table.insert(errs, "PetConfig not readable"); PetConfig = nil end
	if not okX then table.insert(errs, "PassConfig not readable"); PassConfig = nil end
	-- ids, contiguity, pass A end
	local ids, prevEnd = {}, 0
	for i, s in ipairs(S.Shots) do
		if ids[s.id] then table.insert(errs, "duplicate id " .. tostring(s.id)) end
		ids[s.id] = s
		if math.abs(s.start - prevEnd) > 0.01 then table.insert(errs, s.id .. ": start " .. s.start .. " is not previous end " .. prevEnd) end
		prevEnd = s.start + s.dur
		if s.part ~= "A" and s.part ~= "B" then table.insert(errs, s.id .. ": part") end
		if i == #S.Shots and math.abs(prevEnd - S.Config.PassA.length) > 0.01 then table.insert(errs, "pass A ends at " .. prevEnd .. ", not 29.5") end
	end
	for _, s in ipairs(S.Shots) do
		checkCam(s.cam, s.id, errs, ids)
		for j, f in ipairs(s.fallbacks or {}) do
			if not f.sameCam then checkCam(f.cam, s.id .. " fallback " .. j, errs, ids) end
		end
		if s.puppet then
			local p = s.puppet
			if not specOk(p.from) or not specOk(p.to) then table.insert(errs, s.id .. ": puppet from/to") end
			if p.kind == "stop" and not (p.enter and p.stop and p.enter < p.stop) then table.insert(errs, s.id .. ": puppet enter/stop") end
			if p.kind == "pass" and not (p.enter and p.exit and p.enter < p.exit) then table.insert(errs, s.id .. ": puppet enter/exit") end
		end
	end
	if not ids[S.Config.PassB.shot] then table.insert(errs, "PassB.shot unknown") end
	-- parts: must exist, never Role "P", never in any game pass
	if C then
		local paid = {}
		if PassConfig then for _, pass in ipairs(PassConfig.Passes or {}) do for _, id in ipairs(pass.Parts or {}) do paid[id] = true end end end
		local function part(id, slot)
			local def = C.Parts[id or ""]
			if not def then table.insert(errs, "unknown part " .. tostring(id)); return end
			if slot and def.Slot ~= slot then table.insert(errs, id .. " is not a " .. slot) end
			if def.Role == "P" or paid[id] then table.insert(errs, id .. " is a paid / game-pass part") end
		end
		for slot, id in pairs(S.Profile.HeroC) do part(id, slot) end
		part(S.Profile.SwapBlade, "Blade")
		part(S.Profile.HeroAltBlade, "Blade")
		part(S.Profile.Offer.part, "Blade")
	end
	-- pets: must exist, never from the Verity Egg (or any paid egg)
	if PetConfig then
		local paidPet = {}
		for _, egg in ipairs(PetConfig.Eggs or {}) do
			if egg.Paid or egg.Id == "VerityEgg" then for _, p in ipairs(egg.Pets or {}) do paidPet[p.Name] = true end end
		end
		for _, n in ipairs(S.Profile.Pets) do
			if not (PetConfig.PetByName and PetConfig.PetByName[n]) then table.insert(errs, "unknown pet " .. n) end
			if paidPet[n] or n:find("Verity") then table.insert(errs, "paid pet " .. n) end
		end
	end
	-- text: allowed strings only, nothing below 0.82 of SafeFrame height
	for _, card in ipairs(S.Cards) do
		for _, ln in ipairs(card.lines) do
			if not S.AllowedText[ln.text] then table.insert(errs, card.id .. ": text not allowed: " .. tostring(ln.text)) end
			if type(ln.cy) ~= "number" or ln.cy + card.size / 2 > S.Config.Text.MaxLine then table.insert(errs, card.id .. ": line below 0.82") end
		end
		if not (card.tIn and card.tOut and card.tIn < card.tOut) then table.insert(errs, card.id .. ": tIn/tOut") end
	end
	-- server schedule
	local ACTIONS = {Stream = true, StreamGate = true, AfkOff = true, SwapBlade = true, Spawn = true, SpawnRetry = true, PublishBay = true,
		HeroBuild = true, Travel = true, TravelRetry = true, UnlockCandy = true}
	for i, e in ipairs(S.Server) do
		if not ACTIONS[e.action] then table.insert(errs, "server step " .. i .. ": unknown action " .. tostring(e.action)) end
		if e.action == "Stream" and not finiteV(e.pos) then table.insert(errs, "server step " .. i .. ": pos") end
		if e.part ~= "A" and e.part ~= "B" then table.insert(errs, "server step " .. i .. ": part") end
	end
	local lastAt = -math.huge
	for i, m in ipairs(S.PlowMoves) do
		if m.at < lastAt then table.insert(errs, "plow move " .. i .. " not in order") end
		lastAt = m.at
	end
	return #errs == 0, errs
end

return S
