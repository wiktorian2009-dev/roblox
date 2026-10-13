# Release event: 2x Snow for 24 h — 2026-10-13, Claude (save point 74)

wiktor: "give every player 2x snow of 24h its and release event".

## What it does
- One global 24 h window: every player in every server gets 2x Snow. Thin banner above the Snow counter:
  `❄ RELEASE EVENT  2x SNOW  23h 59m left` (minutes:seconds in the last hour). Gone when the event ends.
- Start time: the first live (published) server that runs this code stores "now" once in DataStore
  `ReleaseEvent` / key `Launch2026`; all later servers read the same value. So the 24 h begin when you publish.
  For an exact start instead, set `ReleaseEventConfig.StartOverride` (Unix seconds UTC, e.g. 1792195200 = 2026-10-17 00:00 UTC).
- Stacking: the 2x multiplies everything else (pets incl. Frosty Pal, 1.5x pass, upgrades, ability tokens, 2x boosts from
  rewards/gift, random SNOWSTORM events). A SNOWSTORM during the release gives 4x for its 3 minutes.
- Off switch: `ReleaseEventConfig.Enabled = false`. A second event later: change `StoreKey` (or set `StartOverride`).
- Studio Play never touches the DataStore: it previews a 24 h window starting at Play, or uses ServerStorage attribute
  `ReleaseEventTestStart` (Unix seconds) to test the end.

## Files (Studio, mirrored in game/src)
- new `ReplicatedStorage.ReleaseEventConfig`, `ServerScriptService.ReleaseEventService`, `StarterPlayerScripts.ReleaseEventClient`
- edited `ServerScriptService.BoostService`: `release` factor in `B.Multipliers`, `B.SetRelease`, `B.ReleaseMultiplier`
  (reaches SnowMult through UpgradeService, the same path as the SNOWSTORM event).
- Backup: `ServerStorage.ReleaseEventBackup_20261013.BoostService` (before the edit).
- Undo: delete the 3 new scripts and restore BoostService from the backup (or just set Enabled = false).

## Tested (Studio Play, BalanceTestMode, temp profile, PC, one player)
- Preview window: banner shows "23h 59m left" above the Snow counter, under the tutorial card, nothing overlapped (banner.jpg).
- Ending: with ReleaseEventTestStart set so 60 s were left, the countdown ran to 0, the server printed "ended",
  the banner disappeared and the player's SnowMult went 3 -> 1.5 (1.5x pass x 2 -> 1.5x pass).
- No errors in the output. BalanceTestMode and ReleaseEventTestStart removed afterwards.
- Not tested: the real DataStore path (only runs in a published game), several servers agreeing, phones, a full field payout
  measured by hand (payouts read SnowMult, the same as the SNOWSTORM event).
