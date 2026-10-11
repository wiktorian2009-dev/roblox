-- AbilityConfig (2026-10-11, Claude): ABILITY TOKENS that pop out of cleared field snow. One place for every number:
-- drop odds, weights, durations, strengths, pickup radius, expiry and caps. Server: AbilityService (owns tokens + buffs).
-- Client: AbilityTokenClient (draws tokens, effects and the buff bar). Nothing here is saved; tokens and buffs are temporary.
local A = {}

-- DROPS: a cleared tile rolls once, when its last layer breaks (never per damage tick or layer).
-- The roll is time-normalised so big blades don't make piles: chance = 1 - exp(-activeSecondsSinceLastRoll / MeanSeconds),
-- so the first tile cleared in a tick carries the odds and the other tiles of the same pass roll ~0.
A.Drop = {
	MeanSeconds = 8,       -- average active clearing time after MinGap until a token (target: one every 15-25 s of active clearing)
	MinGap = 7,            -- server cooldown between two spawns for one player (s)
	PitySeconds = 28,      -- after this much ACTIVE clearing without a token, the next cleared tile always drops one
	ActiveHold = 2.5,      -- a tick counts as "active clearing" if a tile of a normal field broke within this many seconds (starter plows break ~1 tile/s)
	PerMinute = 4,         -- per-player budget: at most this many spawns in any 60 s
	MaxVisible = 5,        -- per-player cap on tokens on the ground (expiry frees capacity)
	FirstAfterTiles = 10,  -- a new player's first token is guaranteed after this many cleared tiles (discoverability)
	Lifetime = 15,         -- seconds on the ground
	BlinkAt = 4,           -- the last seconds blink gently
	SpawnMin = 11, SpawnMax = 20, -- studs from the plow, in front of it (never under the vehicle)
	SpawnCone = 70,        -- degrees either side of the plow's heading
	EdgeInsetTiles = 2,    -- keep this many tiles away from the field's border (walls, rims)
	MinSpacing = 7,        -- studs between two of the player's tokens
	FloatHeight = 2.6,     -- hover height above the field floor
}

-- PICKUP: from the plow hull (driving) or the character (walking). Radius follows the real vehicle footprint, clamped.
A.Pickup = {
	VehiclePad = 3,        -- radius = max(half blade width, 4) + pad
	VehicleMin = 6, VehicleMax = 12,
	Walk = 5,
	Slack = 2.5,           -- extra server tolerance on client requests (latency)
	RequestEvery = 0.1,    -- client: min time between requests for one token
}

-- ABILITIES. Weight = drop share (utility common, spectacular area effects rare). Durations refresh on repeat pickups up to MaxStack
-- seconds; strength never stacks. Sizes are studs; damage is "seconds of the player's normal blade contact" per tile, bounded.
A.Order = {"TurboTracks", "HeatedBlade", "SnowSurge", "ComboKeeper", "TokenMagnet", "AuroraPatch", "SnowLane", "Snowburst"}
A.Abilities = {
	TurboTracks = {Name = "Turbo Tracks", Tip = "+15% speed, a bit more grip", Weight = 22, Duration = 8, MaxStack = 14,
		Speed = 1.15, Grip = 1.1, Color = Color3.fromRGB(70, 200, 255), Kind = "buff"},
	HeatedBlade = {Name = "Heated Blade", Tip = "+20% clearing power", Weight = 20, Duration = 8, MaxStack = 14,
		Power = 0.20, Color = Color3.fromRGB(255, 150, 60), Kind = "buff"},
	SnowSurge = {Name = "Snow Surge", Tip = "+15% Snow from field clearing", Weight = 18, Duration = 10, MaxStack = 16,
		Snow = 0.15, Color = Color3.fromRGB(150, 225, 255), Kind = "buff"},
	ComboKeeper = {Name = "Combo Keeper", Tip = "Your combo won't fade", Weight = 14, Duration = 8, MaxStack = 14,
		Color = Color3.fromRGB(120, 160, 255), Kind = "buff"},
	TokenMagnet = {Name = "Token Magnet", Tip = "Pulls in your tokens", Weight = 10, Duration = 6, MaxStack = 10,
		Radius = 32, Color = Color3.fromRGB(110, 235, 230), Kind = "buff"},
	AuroraPatch = {Name = "Aurora Patch", Tip = "+15% power inside the patch", Weight = 7, Duration = 10, MaxStack = 16,
		Radius = 10, Power = 0.15, Color = Color3.fromRGB(150, 255, 190), Kind = "zone"},
	SnowLane = {Name = "Snow Lane", Tip = "A wave clears a lane ahead", Weight = 5, Length = 30, HalfWidth = 3.2,
		Seconds = 1.1, StepTime = 0.05, Color = Color3.fromRGB(110, 190, 255), Kind = "instant"},
	Snowburst = {Name = "Snowburst", Tip = "An icy pulse around you", Weight = 4, Radius = 9,
		Seconds = 0.9, Color = Color3.fromRGB(200, 240, 255), Kind = "instant"},
}
-- Icons (uploaded PNGs, 256x256, source: outputs/AbilityTokens20261011/make_icons.py). Empty = a plain coloured fallback badge.
A.Icons = {
	TurboTracks = "rbxassetid://126159164352973", HeatedBlade = "rbxassetid://104868050954985",
	SnowSurge = "rbxassetid://83755404592914", ComboKeeper = "rbxassetid://110220661535974",
	TokenMagnet = "rbxassetid://81279094953548", AuroraPatch = "rbxassetid://96184791383437",
	SnowLane = "rbxassetid://73760935129387", Snowburst = "rbxassetid://125485028269703",
}

A.IntroText = "Drive over ability tokens for temporary powers!"
A.TotalWeight = 0
for _, id in ipairs(A.Order) do A.TotalWeight += A.Abilities[id].Weight end

return A
