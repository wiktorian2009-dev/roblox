# Snow RNG progression rebalance

Applied directly to Roblox Studio place **money** (94130990350526), September 29, 2026. Target: a new player reaches **Absolute Zero in approximately 3–5 hours of active play**. Changes are in Studio; the live game has not been published.

## Changes

- Expanded upgrades from **49 to 105**: 35 Snow, 35 Rolls, 35 Misc. All 49 existing upgrade IDs remain valid.
- Added 56 upgrades covering snow income, shovel damage, reach, spin, luck, bonus rolls, roll speed, movement, egg discounts, friend boosts, and pet snow bonuses.
- Upgrade prices are explicit and upgrades unlock by stage. Tree position no longer determines cost. The hex UI shows the required stage and preserves empty artwork slots.
- Shovel luck now scales as odds^0.33 rather than odds^0.4. Damage scaling remains odds^0.42.
- Server roll cooldown is 2.4 seconds, reduced to 1.56 seconds with all roll-speed upgrades. Faster visual settings do not bypass the server cooldown.
- Egg prices are 450 / 12K / 300K / 8M for Snowy / Desert / Cursed / Crystal. Hatching requires the corresponding stage.
- Pet-training upgrades increase the snow bonus from equipped pets. They do not multiply the base income when no pets are equipped.
- Fixed the upgrade screen appearing behind the HUD, fitted expanded trees to the screen, and widened the purchase information card.

## Stage costs and estimated arrival times

Times are cumulative from a fresh profile. Two typical simulation scenarios are shown, not guaranteed completion times.

| Stage | Snow cost | Continuous collection, fast roll visuals | Slower collection, normal visuals |
|---|---:|---:|---:|
| Desert | 20K | 5 min | 7 min |
| Cursed Biome | 2M | 19 min | 26 min |
| Crystal Caves | 75M | 45 min | 62 min |
| Retro World | 3B | 94 min | 124 min |
| Jungle | 75B | 145 min | 190 min |
| Absolute Zero | 1T | 228 min | 296 min |
| Absolute Zero Portal | 12T | 359 min | 473 min |

The portal remains an additional endgame objective beyond reaching Absolute Zero. Faster farming routes and lucky drops can finish sooner; less efficient play can take longer.

## Verification

- 240 simulated fresh profiles across three play styles for the final balance, plus 240 baseline profiles. Simulations model rolling, equipping the strongest shovels, buying connected upgrades, egg spending, stage costs, and estimated harvesting throughput.
- All 105 nodes have unique IDs and positions and can be reached by their required stage.
- In a real Studio playtest, bought all 105 upgrades through the normal purchase remote and unlocked all seven paid stages in order. All resulting stats matched the configuration.
- Confirmed rejection of duplicate purchases, unknown IDs, stage-locked upgrades, out-of-order stages, and insufficient funds.
- Fifteen immediate roll requests produced one roll.
- A locked Desert field yielded zero snow; the same field after unlocking yielded 260 snow over four seconds with two Pointed Shovels.
- Moving through fresh Desert snow with two Pointed Shovels yielded 7,880 snow over 21.0 seconds, about 375 per second. This informed the simulation's harvesting estimate.
- Checked the final upgrade screen in a desktop playtest. Mobile layout rules were adjusted but a mobile-device playtest was not run.

These are short functional playtests plus an approximate economy simulation, not a completed 3–5 hour human playthrough. The model omits travel delays, rare-drop cutscene delays, some field depletion, and individual purchasing choices. Actual retention and pacing still need player feedback.

An existing time-played leaderboard reported a Studio API-access warning. No new gameplay script errors appeared. Production saving was not exercised during these tests.

## Existing progress and safe balance testing

No player saves were reset. Existing shovels, upgrades, snow, admin-granted luck, and stage unlocks remain, so an established/admin-boosted profile will not follow fresh-player pacing.

For an optional fresh test: before pressing Play, add a boolean attribute named `BalanceTestMode` to `ServerStorage` and set it to true. In Studio only, this starts the main progression profile from zero and prevents it from loading or saving real progression. Stop Play and remove that attribute afterward. Normal saving uses the existing data-store name. The attribute was removed after this task, and Studio was returned to Edit mode.

The companion `Roblox-balance-backup.json` contains the ten original script sources for rollback. It contains no player data. Restore only these script sources to revert this rebalance.
