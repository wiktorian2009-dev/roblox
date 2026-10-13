-- ReleaseEventConfig (2026-10-13, Claude): the RELEASE EVENT, 2x Snow for every player for 24 hours.
-- * One global window for the whole game, not per player. ReleaseEventService (server) finds the start time:
--   1. C.StartOverride when set (an exact start, Unix seconds UTC; e.g. 1792195200 = 2026-10-17 00:00 UTC),
--   2. otherwise the first live server that runs this code stores "now" once in the DataStore C.StoreName / C.StoreKey,
--      and every later server reads that same value, so all servers agree.
--   Studio Play never reads or writes that DataStore: it previews a window that starts when Play starts
--   (or at ServerStorage attribute ReleaseEventTestStart, Unix seconds, to test the end).
-- * Stacking: the 2x multiplies everything else (pets, passes, upgrades, ability tokens, 2x boosts, server events),
--   through BoostService -> UpgradeService SnowMult, like the random SNOWSTORM event does.
-- * Turn it off: C.Enabled = false. Run a second event later: change C.StoreKey (or set C.StartOverride).
local C = {}

C.Enabled = true
C.SnowMultiplier = 2
C.Duration = 24 * 3600     -- seconds
C.StartOverride = nil      -- Unix seconds (UTC) or nil = start on first live server
C.StoreName = "ReleaseEvent"
C.StoreKey = "Launch2026"

C.Title = "RELEASE EVENT"
C.Boost = "2x SNOW"

return C
