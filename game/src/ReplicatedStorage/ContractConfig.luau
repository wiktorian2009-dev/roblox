-- ContractConfig (2026-10-05, Claude): NPC CLEARING CONTRACTS ("Help Yards").
-- Each stage has one Help Yard (workspace.ContractYards.Yard_<Stage>): a 72 x 60 stud pad beside its fields. A yard is leased to ONE
-- contract instance at a time; the scene prefab (ServerStorage.ContractPrefabs.<Id>) is placed on it and the snow zones below become
-- personal snow fields of the owner (cleared by the real snowplow blade in SnowFieldService; they never regrow).
-- Layout coordinates are YARD-LOCAL studs: origin = pad top centre, -Z = the gate (entrance, towards the stage), +X = right when
-- looking in through the gate. Every zone edge lies on the 3-stud tile grid. Rect = {x0, z0, x1, z1}.
local C = {}

C.Enabled = true
C.Pad = {W = 72, D = 60, GateHalf = 15} -- pad size; the gate opening is x = -15..15 at z = -30

-- schedule (seconds)
C.Offer = {
	FirstDelay = {90, 150},     -- first offer after joining (after the tutorial)
	Interval = {240, 420},      -- 4-7 min between offers (counted from the last offer ending)
	Lifetime = 150,             -- an offer stays available (popup + indicator) this long
	RetryNoSite = 45,           -- no free yard nearby: try again later instead of showing an offer that cannot be accepted
	NearbyStuds = 900,          -- the yard must be in your world and roughly this close
}
C.Job = {
	Deadline = 300,             -- 5 min to finish after accepting
	AbandonDistance = 650,      -- further than this from the yard (or another world) ...
	AbandonGrace = 75,          -- ... for this long abandons the job
	Viewing = 8,                -- the finished scene stays this long before cleanup
	Tolerance = 0.92,           -- each objective needs this share of its tiles fully cleared (never the last speck)
}
-- completion bonus (rebalance 2026-10-05): a job pays Mult x ordinary collecting for its whole expected cycle (travel + clearing +
-- interaction), DemandingMult for the harder scenes. Snapshotted when the offer is made from the player's validated Snow/s at the yard's
-- stage (temporary boosts divided out, so a boost never counts twice) and the expected clearing time of this scene with this build;
-- the Snow the job tiles themselves pay (TileShare of normal per second) is subtracted. Never below BonusSeconds of Snow/s.
C.Reward = {BonusSeconds = 30, MinSnow = 25, RateClamp = {0.5, 1.6}, ActiveShare = 0.75, MaxLayersPerSecond = 40,
	Mult = 2.0, DemandingMult = 2.5, Demanding = {Market = true, Pump = true, Workshop = true},
	TravelSeconds = 35, OverheadSeconds = 20, TileShare = 0.8, ClearSeconds = {35, 240}, Passes = 1.4, LaneSpeedShare = 0.75,
	Demand = {Road = 1.15, Market = 1.15, Parking = 1.1, Pump = 1.35, Workshop = 1.25}, -- turning / ice factor per scene
}
-- contract tile toughness: stage TileHP, kept between these shares of the player's own per-tile blade power so a weak build can
-- finish in 1-3 min and a far stronger build still needs a pass (snapshotted). When the tiles are made softer than the stage, Snow per
-- layer is scaled down by the same factor, so a job never pays more per blade-second than the stage's normal fields.
-- Hard zones (ice) use Tough = 1 so Hard-rated blades shine.
C.Difficulty = {MinPowerShare = 0.12, MaxPowerShare = 0.16}

-- Friend NPCs are cosmetic only (never used for validation, rewards or difficulty).
C.NPC = {
	FriendCacheSeconds = 1800, MaxFriendPages = 6, AvoidRecent = 3, TemplateCache = 24, LoadTimeout = 6,
	Anim = {
		R15 = {Idle = "rbxassetid://507766388", Wave = "rbxassetid://507770239", Cheer = "rbxassetid://507770677"},
		R6 = {Idle = "rbxassetid://180435571", Wave = "rbxassetid://128777973", Cheer = "rbxassetid://129423030"},
	},
	Fallback = {Name = "Winter Resident", Skin = Color3.fromRGB(234, 184, 146), Coat = Color3.fromRGB(226, 72, 61), Pants = Color3.fromRGB(59, 63, 74)},
}

-- biome tints for the yard pad / gate / accents (by stage id)
C.Biome = {
	Starter = {Ground = "F2F7FF", Rock = "7F92AC", Accent = "E2483D", Trim = "FFD23A"},
	Desert = {Ground = "F1D9A6", Rock = "C08A52", Accent = "2FA7A0", Trim = "FFE7B0"},
	Cursed = {Ground = "5D4A78", Rock = "3A2F4D", Accent = "B65CFF", Trim = "D7C2FF"},
	Crystal = {Ground = "D8ECFF", Rock = "6A8FC2", Accent = "57D8FF", Trim = "C9F4FF"},
	Retro = {Ground = "8BD35E", Rock = "6B7A86", Accent = "FF5DA2", Trim = "FFE14D"},
	Jungle = {Ground = "6FB55A", Rock = "6C6248", Accent = "FF8A3D", Trim = "FFE08A"},
	AbsoluteZero = {Ground = "E8F6FF", Rock = "5E7FA8", Accent = "3FA9FF", Trim = "FFFFFF"},
	Sakura = {Ground = "FFE6EF", Rock = "9C7F8E", Accent = "FF7FAE", Trim = "FFFFFF"},
	Candy = {Ground = "FFF0F6", Rock = "D98BB5", Accent = "FF4F8B", Trim = "7FE3FF"},
	Atlantis = {Ground = "E9DDBE", Rock = "4F8A9C", Accent = "2FC6C0", Trim = "FFE7A8"},
	Toybox = {Ground = "FFE58A", Rock = "4F7BD6", Accent = "FF4B4B", Trim = "4BD66F"},
	Clockwork = {Ground = "D9C7A3", Rock = "7A5A3C", Accent = "D59A3A", Trim = "F2E3C2"},
	Cloud = {Ground = "FFFFFF", Rock = "B8C7E0", Accent = "7FB2FF", Trim = "FFE9A8"},
	Cosmic = {Ground = "3A3F7A", Rock = "232655", Accent = "B07CFF", Trim = "7FF5FF"},
}

-- The eight contracts. Groups = the sub-objectives shown in the tracker (all are required). Zones = snow rectangles; a group may
-- span several zones. Tough / HPMult override the stage values for that zone (the ice patch). NPC = where the requester stands
-- (off every lane), facing the yard centre.
C.Types = {
	{
		Id = "Road", Name = "Blocked Neighborhood Road", Icon = "\u{1F6E3}", Line = "My road is completely covered!",
		Thanks = "The whole street can get out again - thank you!",
		Hint = "Clear the road from the gate to the cottages. Wide blades help on the broad stretch; steer well through the bends.",
		NPC = {-27, -24},
		Groups = {
			{Key = "R1", Label = "Entry stretch"}, {Key = "R2", Label = "First bend"},
			{Key = "R3", Label = "Side lane"}, {Key = "R4", Label = "Last bend"},
		},
		Zones = {
			{Group = "R1", Rect = {-12, -30, 12, -9}},
			{Group = "R2", Rect = {-12, -9, 27, 3}},
			{Group = "R3", Rect = {15, 3, 27, 18}},
			{Group = "R4", Rect = {-27, 18, 27, 27}},
		},
	},
	{
		Id = "Cottages", Name = "Snowbound Cottages", Icon = "\u{1F3E0}", Line = "We can't get out of our houses!",
		Thanks = "Doors open, porches lit - you're a hero!",
		Hint = "Clear each cottage's driveway and door path - any order.",
		NPC = {-27, -15},
		Groups = {{Key = "H1", Label = "Red cottage"}, {Key = "H2", Label = "Blue cottage"}, {Key = "H3", Label = "Green cottage"}},
		Zones = {
			{Group = "H1", Rect = {-30, -9, -18, 12}}, {Group = "H1", Rect = {-27, 12, -21, 15}},
			{Group = "H2", Rect = {-6, -9, 6, 12}}, {Group = "H2", Rect = {-3, 12, 3, 15}},
			{Group = "H3", Rect = {18, -9, 30, 12}}, {Group = "H3", Rect = {21, 12, 27, 15}},
		},
	},
	{
		Id = "Market", Name = "Market Stall Rescue", Icon = "\u{1F6CD}", Line = "The market opens soon, but the stalls are buried!",
		Thanks = "Stalls are open - the market is saved!",
		Hint = "Clear the entrance, the walking lanes and the front of every stall.",
		NPC = {-27, -24},
		Groups = {
			{Key = "Entry", Label = "Main entrance"}, {Key = "Lanes", Label = "Walking lanes"},
			{Key = "S1", Label = "Cocoa stall"}, {Key = "S2", Label = "Toy stall"}, {Key = "S3", Label = "Fruit stall"}, {Key = "S4", Label = "Scarf stall"},
		},
		Zones = {
			{Group = "Entry", Rect = {-9, -30, 9, -12}},
			{Group = "Lanes", Rect = {-33, -12, 33, -3}},
			{Group = "Lanes", Rect = {-6, -3, 6, 9}},
			{Group = "Lanes", Rect = {-33, -3, -21, 9}},
			{Group = "Lanes", Rect = {21, -3, 33, 9}},
			{Group = "S1", Rect = {-33, 9, -21, 18}}, {Group = "S2", Rect = {-15, 9, -3, 18}},
			{Group = "S3", Rect = {3, 9, 15, 18}}, {Group = "S4", Rect = {21, 9, 33, 18}},
		},
	},
	{
		Id = "Parking", Name = "Snowy Parking Lot", Icon = "\u{1F697}", Line = "Customers can't reach the shop!",
		Thanks = "Customers are rolling in - the shop is open!",
		Hint = "Clear the driving aisle, the marked parking spaces and the exit lane. The exit always counts!",
		NPC = {-27, -24},
		Groups = {{Key = "Aisle", Label = "Driving aisle"}, {Key = "Spaces", Label = "Marked parking spaces"}, {Key = "Exit", Label = "Exit lane"}},
		Zones = {
			{Group = "Aisle", Rect = {-6, -30, 6, 12}},
			{Group = "Spaces", Rect = {-24, -12, -18, -3}}, {Group = "Spaces", Rect = {-12, -12, -6, -3}},
			{Group = "Spaces", Rect = {6, -12, 12, -3}}, {Group = "Spaces", Rect = {18, -12, 24, -3}},
			{Group = "Exit", Rect = {6, 3, 36, 15}},
		},
	},
	{
		Id = "BusStop", Name = "Bus Stop Cleanup", Icon = "\u{1F68C}", Line = "The bus needs somewhere safe to stop!",
		Thanks = "Here comes the bus - right on time!",
		Hint = "Clear the approach lane, the pull-in bay and the footpath to the shelter.",
		NPC = {-33, 6},
		Groups = {{Key = "Approach", Label = "Approach lane"}, {Key = "Bay", Label = "Pull-in bay"}, {Key = "Path", Label = "Footpath"}},
		Zones = {
			{Group = "Approach", Rect = {-3, -21, 36, -9}},
			{Group = "Bay", Rect = {-27, -15, -3, -3}},
			{Group = "Path", Rect = {-21, -3, -12, 12}},
		},
	},
	{
		Id = "Crates", Name = "Buried Supply Crates", Icon = "\u{1F4E6}", Line = "Our supplies disappeared under the snow!",
		Thanks = "All three crates found - the camp is saved!",
		Hint = "Dig out the three marked crates. They rise as you clear them.",
		NPC = {27, 24},
		Groups = {{Key = "C1", Label = "Crate 1"}, {Key = "C2", Label = "Crate 2"}, {Key = "C3", Label = "Crate 3"}},
		Zones = {
			{Group = "C1", Rect = {-30, -18, -15, -3}},
			{Group = "C2", Rect = {12, -12, 27, 3}},
			{Group = "C3", Rect = {-12, 3, 3, 18}},
		},
	},
	{
		Id = "Pump", Name = "Frozen Water-Pump Yard", Icon = "\u{1F6B0}", Line = "The water pump is blocked by thick ice!",
		Thanks = "Water is flowing again - wonderful!",
		Hint = "Open the access route, then break the thick ice in front of the pump. Ice-breaker blades are much faster here.",
		NPC = {-30, 21},
		Groups = {{Key = "Access", Label = "Access route"}, {Key = "Ice", Label = "Thick ice patch"}},
		Zones = {
			{Group = "Access", Rect = {-9, -30, 9, -12}},
			{Group = "Access", Rect = {-24, -12, 24, 0}},
			{Group = "Access", Rect = {-24, 0, -9, 15}},
			{Group = "Access", Rect = {9, 0, 24, 15}},
			{Group = "Ice", Rect = {-9, 0, 9, 12}, Tough = 1, HPMult = 1.6, Style = "ContractIce"},
		},
	},
	{
		Id = "Workshop", Name = "Workshop Delivery Yard", Icon = "\u{1F69A}", Line = "We need room for the next delivery!",
		Thanks = "The delivery made it - doors open!",
		Hint = "Clear the access route, the turning area and both loading bays. Tracks and sharp steering shine here.",
		NPC = {30, -24},
		Groups = {{Key = "Access", Label = "Access route"}, {Key = "Turn", Label = "Turning area"}, {Key = "L1", Label = "Loading bay 1"}, {Key = "L2", Label = "Loading bay 2"}},
		Zones = {
			{Group = "Access", Rect = {-9, -30, 9, -15}},
			{Group = "Turn", Rect = {-27, -15, 27, 3}},
			{Group = "L1", Rect = {-21, 3, -9, 18}},
			{Group = "L2", Rect = {9, 3, 21, 18}},
		},
	},
}
C.ById = {}
for i, t in ipairs(C.Types) do
	t.Index = i
	C.ById[t.Id] = t
	t.GroupIndex = {}
	for gi, g in ipairs(t.Groups) do t.GroupIndex[g.Key] = gi end
end

-- yard-local rect -> world-aligned field centre + width/depth in tiles (yards are rotated by multiples of 90 degrees only)
function C.ZoneWorld(yardCF, rect, tile)
	local x0, z0, x1, z1 = rect[1], rect[2], rect[3], rect[4]
	local a = yardCF:PointToWorldSpace(Vector3.new(x0, 0, z0))
	local b = yardCF:PointToWorldSpace(Vector3.new(x1, 0, z1))
	local minX, maxX, minZ, maxZ = math.min(a.X, b.X), math.max(a.X, b.X), math.min(a.Z, b.Z), math.max(a.Z, b.Z)
	local w = math.floor((maxX - minX) / tile + 0.5)
	local d = math.floor((maxZ - minZ) / tile + 0.5)
	return Vector3.new((minX + maxX) / 2, a.Y, (minZ + maxZ) / 2), w, d
end

return C
