# Leaderboards: Snow, Arena KOs, Playtime (2026-10-09, Claude)

wiktor: "lets make working leaderbords of snow/kills on arena/playtime".

## What players see
Three snowy wooden boards stand in the hub's west gap between Bay 1 and Bay 2, facing the lobby centre (workspace.Leaderboards, a Persistent model).
- Each board shows the global **top 10** (rank medal, avatar, display name, score), a **YOU** row with your own score and rank (up to #50), and "Updates in 45s".
- **TOP SNOW** = total Snow cleared, all time (d.SnowEarned). Spending never lowers it. Wheel, Frost King and machine prizes don't count, the same rule as quests.
- **ARENA KOs** = knockouts in the Bumper Arena (d.Arena.KOs): the last valid hitter in a live match gets the KO. Bots and practice don't count. This counter has existed since the arena launched.
- **PLAYTIME** = time in game, counted by the server from this update on (new d.PlayTime). Everyone starts at 0; earlier playtime was never recorded.

## How it works
- ReplicatedStorage.LeaderboardConfig: the boards, store names, top 10 / fetch 50, refresh 90 s, write 120 s.
- ServerScriptService.LeaderboardService:
  - Scores come from the server profile only.
  - Every 10 s it counts playtime and sets the player attributes LB_Snow / LB_ArenaKOs / LB_Playtime (for the YOU row).
  - It writes each changed score every 2 min, on leave and on shutdown, with UpdateAsync. That keeps the higher of the stored and new value, so a stale server can't lower a score.
  - Every 90 s it reads the top 50 of each board and resolves names with UserService.
  - It publishes JSON to ReplicatedStorage.LeaderboardData.
- StarterPlayerScripts.LeaderboardClient draws a SurfaceGui on each Board_*.Screen (BoardId attribute).
- OrderedDataStores: LB_SnowEarned_v1, LB_ArenaKOs_v1, LB_Playtime_v1.
  - Snow passes 1e18, so it is stored as floor(log10(v+1)·1e13). That keeps the order and about 13 digits.
- Budget per server: 3 GetSortedAsync per 90 s, and at most 3 UpdateAsync per player per 2 min. Writes skip a round if the UpdateAsync budget is below 4.

## Safety
- Only profiles really loaded from the DataStore are published (DataService.LoadedFromStore). A temporary or failed profile never posts a score.
- Studio never writes the live stores. It can read them when API access is on.
- BalanceTestMode swaps in in-memory stores, driven by ServerStorage.LeaderboardTestHook (Seed / Write / Refresh / Store / AddPlaytime).
- DataService is unchanged. d.PlayTime is a new field saved with the profile.

## Tested (Studio Play, BalanceTestMode, PC)
- In-memory boards were seeded with 7 Snow, 4 KO and 4 playtime entries (classic public accounts, test store only). The own playtime was set through the hook.
- Server JSON: correct order, decoded Snow 420Qi / 13Qi / 2.5Qa / 9.8T, and names resolved.
- Client:
  - All 3 boards drew the right rows with avatars and medals.
  - The own row was highlighted on PLAYTIME (#3, 3h 12m), and the YOU row showed "#3 3h 13m".
  - The footer read "Studio test board (not saved) · Updates in 41s".
- Screenshot: screens/boards_test_data.jpg.
- Encode/decode was checked in Edit for 0, 1, 999, 1000, 1.2M, 2M, 1.3e19 and 4.2e20.

## Not tested
- Real OrderedDataStores: writes and reads in a live server, and names of real players.
- Several players, phones, and the 50+ rank text.
- A real arena KO feeding the board. KOs come from the existing counter.

## Undo
- Disable or delete the three scripts and move workspace.Leaderboards to ServerStorage.
- The stores keep their data in Roblox. Nothing else depends on them.
- Builder: build_boards.luau (stages the model), then ../HubRing20261009/after_apply.luau places it.
