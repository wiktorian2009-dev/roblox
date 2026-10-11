# Ability tokens (2026-10-11, Claude, save point 71)

Collectible ability tokens pop out of cleared field snow. Drive (or walk) over one and its power starts at once.

## What is in Studio
| Object | Kind | Notes |
|---|---|---|
| ReplicatedStorage.AbilityConfig | ModuleScript (new) | every number: odds, weights, durations, strengths, pickup radius, expiry, caps, icon ids |
| ServerScriptService.AbilityService | ModuleScript (new) | server owns tokens, buffs, pickup checks; Studio-only `ServerStorage.AbilityTestHook` (BalanceTestMode) |
| StarterPlayerScripts.AbilityTokenClient | LocalScript (new) | draws your own tokens, effects, buff bar, intro line |
| ServerScriptService.SnowFieldService | Script (edited) | one roll per fully cleared tile; Heated Blade / Aurora power; Snow Surge once at payout; ability damage path; Combo Keeper pause |
| StarterPlayerScripts.PlowDriveClient | LocalScript (edited) | Turbo Tracks speed + grip, Heated Blade snow-cap, read from hull attributes (same single controller) |
| StarterPlayerScripts.DigJuiceClient | LocalScript (edited) | combo bar stays full while Combo Keeper runs |
| ReplicatedStorage.AbilityToken | RemoteEvent (made at runtime) | server -> owner only; client -> "pickup", id |

Icons: `icons/*.png` (drawn by `make_icons.py`, uploaded as rbxassetid 125485028269703 Snowburst, 126159164352973 Turbo Tracks,
104868050954985 Heated Blade, 83755404592914 Snow Surge, 81279094953548 Token Magnet, 110220661535974 Combo Keeper,
73760935129387 Snow Lane, 96184791383437 Aurora Patch).

## Rules (AbilityConfig)
- A tile rolls once when its last layer breaks under the player's own blade, in a normal unlocked field. Not AFK, minis, contract yards, arena or boss.
- Odds are time-normalised: chance = 1 - exp(-active seconds since the last roll / 8 s), only after a 7 s cooldown since the last spawn; pity after 28 s of active clearing; max 4 per minute; max 5 on the ground. A wide blade does not make piles (the other tiles of the same pass roll ~0).
- First token for a new profile: Turbo Tracks after 10 cleared tiles, with the one-time line "Drive over ability tokens for temporary powers!" (flag d.Settings.AbilityIntroSeen, the only saved bit).
- Spawn: 11-20 studs ahead of the plow within +-70 degrees, at least 2 tiles from the field border, 7 studs apart, never under the plow.
- Life 15 s, blinks the last 4 s. Pickup radius: max(half blade width, 4) + 3, clamped 6-12 studs (driving), 5 (walking); +2.5 tolerance on client requests.
- Weights: Turbo 22, Heated 20, Surge 18, Combo Keeper 14, Magnet 10, Aurora 7, Snow Lane 5, Snowburst 4.
- Repeat pickups add duration up to a cap (Turbo/Heated/Combo 14 s, Surge/Aurora 16 s, Magnet 10 s); strength never stacks.
- Snowburst: 9-stud circle, 0.9 s of the player's own blade contact per tile. Snow Lane: 30 studs ahead x 6.4 wide, 1.1 s per tile, stops at the field edge or a solid obstacle. Neither can roll new tokens.
- Cleared on respawn, travel (a >70-stud jump), entering a different field, leaving the field by 30+ studs (tokens + aurora), AFK (tokens), leaving the game.

## Recovery
- Turn it off without touching scripts: ServerStorage attribute `AbilityTokensOff = true` (no new tokens; existing ones expire).
- Full undo: put back SnowFieldService, PlowDriveClient and DigJuiceClient from `ServerStorage.AbilityTokensBackup_20261011` (enable the copies), then delete AbilityConfig, AbilityService and AbilityTokenClient.

## Tested (Studio Play, BalanceTestMode, PC, one player, temporary profile; 2026-10-11)
- Fresh profile: the guaranteed first token (Turbo Tracks) and the intro line appeared after the first ~10 cleared tiles (20 s of driving).
- Driving pickup: 4 tokens placed ahead, driven through, all 4 activated; hull got AbilitySpeed 1.15 / AbilityGrip 1.1 / AbilityPower 1.2, ComboKeepUntil set; all removed when they ran out.
- Walking pickup: walked onto a Token Magnet, it activated.
- All eight: Turbo, Heated, Surge, Combo Keeper, Magnet (pulled 3 tokens at 20-25 studs, left one at 45 studs), Aurora (10 s patch), Snow Lane (30 tiles, stops at the field edge: 0 tiles when pointed out of the field), Snowburst (28 tiles in the field, 0 outside any field). No token rolled from ability damage.
- Repeats: Turbo x3 = 14 s (cap), strength unchanged. Surge x3 = 15.5 s (cap 16).
- One-time use: 50 server-side pickups of one token = 1 activation; 50 for an out-of-reach token = 0; 300 forged client requests (wrong ids, wrong types, "grant") = 301 rejected, nothing granted.
- Expiry: a token disappeared at 15.4 s. Cleanup: TRAVEL Lobby cleared tokens, buffs, aurora and hull attributes; dying cleared everything; walking from Starter into the Frostfall snow yard cleared everything.
- No errors from the game in the Output during either Play session (only my own test-command mistake).

## Measured income (starter build, Starter field, bot driving a fixed snake route, Aurora Night event x1.5 active the whole time)
| Run (90 s) | Snow | Tokens spawned | Picked up |
|---|---|---|---|
| off | 1844 | - | - |
| off | 1862 | - | - |
| off | 1877 | - | - |
| on, bot swerves to every token | 808 | 5 | 3 |
| on, bot swerves to every token | 2089 | 4 | 3 |
| on, route only (picks up what it passes) | 2029 | 5 | 1 |
| on, route only | 2144 | 3 | 1 |
- Drop rate after tuning: 3-5 tokens per 90 s of active clearing = one every 18-30 s (target 15-25 s). Before tuning it was 1-2 per minute.
- The bot's token chasing is crude (one run circled and lost half its Snow), so these runs show the drop rate and that nothing breaks, not a precise gain. Expected gain from the effect sizes and weights, if a player collects most tokens: about +5% Snow (Surge +15% for 10 s, Heated/Aurora +15-20% power, Turbo +15% speed, rare Snow Lane / Snowburst = a few seconds of clearing each). Off runs were within 2% of each other; the two route-only on runs were +9% and +15%, more than one pickup each can explain, so treat them as noise.
- Not measured: intermediate and late builds (drops are time-based and every effect is a percentage or "seconds of your own blade", so the gain should be similar; not verified). Jobs: tokens never drop in contract yards and Surge/Heated/Aurora do not apply there, so job pay is unchanged (jobs pay 2x-2.5x field clearing per PROJECT.md).
- Not tested: two players (ownership is per player by design: the server only sends your tokens and only accepts your ids), phones / touch / small screens, a real keyboard drive, sound volume by ear, the last small HUD nudge (buff bar 6 px higher, intro line at 19% height) which was made after the Play test.
