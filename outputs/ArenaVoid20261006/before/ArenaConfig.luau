-- ArenaConfig (2026-10-05, Claude): Snowplow Bumper Arena tuning. Separate from PlowConfig on purpose: arena performance is
-- normalized (every vehicle gets these stats), so parts, upgrades, pets, rebirths and boosts never change who wins a bump.
-- Values are prototype values tuned in Studio tests (see STATUS.md); all speeds in studs/s, times in seconds.
local A = {}

A.Version = 1
A.Center = Vector3.new(-40, 700, 150)    -- top surface of the main fighting floor (world)
A.Plaza = Vector3.new(-40, 700, -58)     -- arrival plaza / return portal (island south end)
A.FloorRadius = 58                       -- drivable floor inside the bumper wall
A.WallInner = 58                         -- bumper wall inner radius
A.OutRadius = 61.5                       -- planar distance from Center that counts as a ring-out (only reachable through an exit)
A.FallDepth = 8                          -- this far below the floor also counts as out
A.Exits = {45, 135, 225, 315}            -- exit gap directions (degrees, measured from +X toward +Z); walls (and pads) on the cardinals
A.ExitWidth = 20                         -- opening width of each exit gap (studs)
A.PadRadius = 38                         -- spawn pads, two per quadrant, facing the centre
A.PadAngles = {344, 16, 74, 106, 164, 196, 254, 286}
A.Practice = {Center = Vector3.new(-112, 700, 8), Radius = 24, OutRadius = 27.5, Exit = 180, ExitWidth = 16, Pads = {{-12, 8}, {12, 8}}}
A.Targets = {MainIdle = 3, Practice = 2, RespawnDelay = 3}

A.Players = {Min = 2, Max = 8}
A.Round = {Countdown = 8, Duration = 150, Results = 8, LateJoinMinLeft = 40}
A.Respawn = {Delay = 4, Shield = 2.5}

-- one normalized vehicle for everyone (footprint = the visible bumper ring)
A.Vehicle = {
	Footprint = Vector3.new(8.6, 1.6, 13.2), -- hull collision box (W, H, L)
	FootprintOffsetZ = -1.6,                 -- hull centre relative to the chassis root (front = -Z)
	Clearance = 1.1,                         -- hull bottom above the floor
	MaxSpeed = 26, Accel = 26, Brake = 52, Reverse = 0.55,
	TurnRate = 2.5, MinTurn = 0.35, TurnSpeedFull = 0.35, LateralGrip = 9,
	BladeMaxHalfWidth = 3.9, BladeMaxFront = -7.9, -- cosmetic blades are scaled to fit inside the bumper
	RideStiffness = 14,
}
A.Boost = {Duration = 0.6, Cooldown = 8, Speed = 46, Accel = 140}
A.Brace = {Duration = 0.85, Cooldown = 7, KnockMult = 0.35, SpeedMult = 0.6}
A.Knock = {
	MinClosing = 4,        -- closing speed below this is just touching (no hit)
	Base = 8, PerClosing = 0.55, NormalMax = 24,
	BoostBase = 12, BoostPerClosing = 0.8, BoostMax = 55,
	FrontalDot = 0.55,     -- striker's front must face the victim this much to count as a frontal ram
	Recoil = 0.25, BoostRecoil = 0.15,
	Scrape = 6,            -- side-by-side scrape: small symmetric push
	Decay = 2.2,           -- knockback velocity decays by exp(-Decay * t)
	MaxVel = 60,           -- accumulated knockback velocity cap
	PairCooldown = 0.45,   -- one hit per pair per this many seconds (grinding contact never repeats hits)
	Attribution = 4,       -- a ring-out within this many seconds of an opponent's valid hit scores for them
	Contact = 0.6,         -- server contact margin (studs) between footprints
}
A.AntiCheat = {SpeedSlack = 1.15, SpeedPad = 6, Flags = 3, FlagWindow = 2}

-- cosmetic rewards only (no Snow, no power). Rewards need legitimate participation.
A.Reward = {MinActive = 60, MinRoundSeconds = 90, MinMatchHits = 4, DailyCap = 30}
A.Paints = {
	{Id = "Classic", Name = "Classic Red", Color = Color3.fromRGB(226, 72, 61)},
	{Id = "Frost", Name = "Frost Blue", Color = Color3.fromRGB(80, 170, 255), Unlock = "FirstMatch"},
	{Id = "Gold", Name = "Champion Gold", Color = Color3.fromRGB(255, 200, 60), Unlock = "FirstWin"},
	{Id = "Inferno", Name = "Inferno", Color = Color3.fromRGB(255, 110, 40), Unlock = "Wins5"},
	{Id = "Aurora", Name = "Aurora", Color = Color3.fromRGB(150, 255, 190), Unlock = "Wins15"},
}
A.Achievements = {
	{Id = "FirstKO", Name = "First knockout", Title = "Bumper Rookie", Stat = "KOs", Need = 1},
	{Id = "FirstMatch", Name = "First completed match", Title = "Arena Regular", Stat = "Matches", Need = 1},
	{Id = "FirstWin", Name = "First win", Title = "Arena Champion", Stat = "Wins", Need = 1},
	{Id = "Wins5", Name = "5 wins", Title = "Ice Gladiator", Stat = "Wins", Need = 5},
	{Id = "Wins15", Name = "15 wins", Title = "Arena Legend", Stat = "Wins", Need = 15},
}

function A.PaintById(id)
	for _, p in ipairs(A.Paints) do if p.Id == id then return p end end
	return A.Paints[1]
end
-- world CFrame of spawn pad i (on the floor, facing the centre)
function A.PadCFrame(i)
	local a = math.rad(A.PadAngles[(i - 1) % #A.PadAngles + 1])
	local p = A.Center + Vector3.new(math.cos(a), 0, math.sin(a)) * A.PadRadius
	return CFrame.lookAt(p, Vector3.new(A.Center.X, p.Y, A.Center.Z))
end
function A.PracticePadCFrame(i)
	local pr = A.Practice
	local o = pr.Pads[(i - 1) % #pr.Pads + 1]
	local p = pr.Center + Vector3.new(o[1], 0, o[2])
	return CFrame.lookAt(p, Vector3.new(pr.Center.X, p.Y, pr.Center.Z))
end
return A
