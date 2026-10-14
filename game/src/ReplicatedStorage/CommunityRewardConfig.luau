-- CommunityRewardConfig (2026-10-13, Claude): the free one-time SUPPORTER GIFT for joining the game's Roblox group.
-- * The group half is checked on the SERVER (CommunityRewardService). Roblox has no API that tells a game whether a player liked
--   it, so the like is honor-system: since 2026-10-14 the card makes it its own step (tap, short countdown, confirm) and CLAIM waits for it.
-- * Saved once per profile (d.Community.Claimed); it can never be claimed twice. Nothing here costs Robux.
local C = {}

-- The group that owns this experience (game.CreatorId, CreatorType Group, read in Studio 2026-10-13). Change it to use another group.
-- nil = fall back to the experience owner's group at runtime (and hide the gift when the game is owned by a user).
C.GroupId = 10506641

-- the prize (all given together, once)
C.Pet = "Frosty Pal"          -- exclusive pet (PetConfig egg "SupporterGift"); auto-equipped when a slot is free
C.Egg = "SupporterGift"       -- egg id used for the hatch reveal
C.SnowMinutes = 10            -- Snow worth this many minutes of the player's recent clearing speed ...
C.SnowMin = 2500              -- ... but never less than this
C.Boost = "Snow2"             -- timed boost (ActivityConfig.Boosts)
C.BoostSeconds = 900          -- 15 minutes

C.Title = "FREE SUPPORTER GIFT"
C.LikeText = "Tap the \u{1F44D} on the game page - it helps a lot!"
C.JoinText = "Join our group"
C.PillText = "FREE PET!"
C.LikeNudgeAfter = 480       -- seconds of play before the one-per-session like reminder for players who already claimed

return C
