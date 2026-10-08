# Data and progression audit — live source snapshot, 2026-10-05

Read-only review of fresh `sources-0.json` and `sources-1.json`, with Graphify used only for navigation. `ReplicatedStorage.PlowConfig:6` selects `Snowplow`. No Studio mutations or runtime tests performed by this audit. References below are exact live script paths and one-based source line numbers.

## Conversion gaps

### P1 — Garage rolls cannot finish roll quests, blocking quest-set refresh

- `ServerScriptService.PlowService:209–220`: `actions.Roll` increments only `p.Rolls` at line 217. It neither updates `d.TotalRolls` nor publishes the leaderstat. Reroll aliases this action at line 222.
- `ServerScriptService.ActivityService:58`: the shared quest/achievement statistic `Rolls` reads only `d.TotalRolls`.
- `ServerScriptService.RNGHandler:79` exits the old roll handler in Snowplow mode; the old increment and leaderstat publication at lines 101–102 can never run from a garage roll.
- `ReplicatedStorage.ActivityConfig:45` still offers `Roll 25/40/60 times`; three quests are selected from four definitions (`ActivityConfig:42,44–49`; `ActivityService:120–133`). Thus 75% of newly generated sets contain the unavailable roll quest.
- Progress subtracts the recorded start from the same old statistic (`ActivityService:139–142`), and a new set requires every quest claimed (`ActivityService:186–193,274–275`). A set containing Roll therefore stays stuck through normal Snowplow play, even after the other two rewards are claimed.
- The same mismatch freezes the visible Rolls leaderstat (`DataService:62`) and three roll achievements (`ActivityConfig:58–60`), which together promise +10% permanent luck.

Fix direction: preserve the legacy counter and data; use a deliberate current-mode or combined lifetime counter for the Rewards/leaderstat contract, including migration of already active quest starts. Simply switching stats for existing quests can misinterpret their saved `Start` values.

### P2 — Twenty active upgrade tiles charge Snow for effects ignored by Snowplow

- `ReplicatedStorage.PlowConfig:69–71` explicitly says the old effects remain owned and only matter in Legacy. Keeping historical ownership is intentional compatibility.
- `ServerScriptService.UpgradeService:77–93` still allows purchase of every `U.ById` node, deducts Snow at line 90 and grants ownership at line 91 without a mode filter.
- `ReplicatedStorage.UpgradeConfig:26,80–98` still advertises the effects. The 20 nodes are `S_Third`; `R_Dice1`, `R_Dice2`, `R_Dice3`, `R_Hyper`; `R_Dice4`, `R_Dice5`, `R_Triple`; `R_Gold1` through `R_Gold6`; `R_Rain1` through `R_Rain6`.
- Offer rolling uses a fixed `C.Shop.RollCooldown` (`PlowConfig:9`, `PlowService:213–214`) and a single part selection (`PlowService:215–218`); it reads none of `RollAnimScale`, `DoubleRollChance`, `GoldenEvery` or `RainbowEvery`.
- Stats mapping (`PlowConfig:78–84`; `PlowService:81–85`) reads no ShovelSlots.

Impact: players can spend Snow on faster, double, Golden/Rainbow rolls or another shovel slot and get no benefit in the active loop. Existing purchases should stay recoverable for Legacy; current sales and descriptions need a mode policy. The Forge unlock is a further old-only sale (`UpgradeConfig:241`) tied to the machine conversion reviewed separately.

### P2 — Shovel discovery achievements remain attached to retired collectibles

- `ReplicatedStorage.ActivityConfig:68–69` advertises discovering 10 and 20 shovels, awarding a combined +5% permanent luck.
- `ServerScriptService.ActivityService:47–54,62` counts distinct base shovels from `d.Counts`, resolving names through RNGConfig. Buying plow parts modifies only `p.Parts` (`PlowService:241`).
- A new Snowplow profile gets the one compatibility starter shovel (`DataService:29`; `StarterShovelRules:9–16`), and ordinary old shovel rolls are disabled (`RNGHandler:79`). Normal plow progress does not advance these achievements.

Impact: unavailable achievement goals and rewards remain in Rewards. Keep already unlocked achievement bonuses and legacy collection data; the active objectives need replacement or hiding. A direct 10/20-part replacement also needs new goals because the current catalog contains only eight parts.

## Related integration issues

### P2 — Active vehicle does not pick up purchased damage, width or speed upgrades

- `PlowService:152` computes `C.StatsFor` only while spawning a vehicle; the result is stored as `v.stats` at line 187 and hull speed/handling attributes at lines 184–185.
- `UpgradeService:21–46,90–92` updates player attributes and walking speed after purchase, but never refreshes the vehicle/registry.
- `SnowFieldService:142–158` uses cached `v.stats` for power/width/speed validation. No second writer to `v.stats` or other server call to `StatsFor` exists in the captured current server sources.

Impact: an upgrade bought while driving is owned but its mapped power/width/speed applies only after exit and a new DRIVE. SnowMult/pets are read live at payout (`SnowFieldService:111–113`) so those still apply immediately. This is a source-proven integration gap; actual UI purchase while seated was not exercised by this audit.

### P2 — Late size purchases can provide zero blade-width increase

- `PlowConfig:65,78` caps size × reach at 1.6.
- Ten World 1 size nodes are still offered (`UpgradeConfig:27–36`); the final config turns each into +0.08 (`UpgradeConfig:301–303`). Eight reach a raw multiplier of 1.64, already capped; the ninth and tenth add nothing.
- Seven World 2 +0.06 size nodes (`UpgradeConfig:146–152`) also add no width for a build already at this cap.

The cap itself is intentional. The inconsistency is continuing to sell additional width with a description promising an increase when the mapped stat cannot increase. Keep this separate from a decision to raise the cap.

### P3 — Administrator tutorial/reset commands still target only the old loop

- `AdminService:199–205` restarts `d.Settings.TutorialDone` / the old TutorialDone attribute, while the plow tutorial stores `p.TutorialDone` (`PlowService:285`, sanitized by `PlowRules:41`).
- `AdminService:208–220` claims to wipe ALL progress but does not clear `d.Plow` (parts, build, offers, reservation, rolls and tutorial completion survive). This is also an existing incomplete reset for other later systems, so do not present all of it as a new shovel conversion defect.

These commands were not run. Updating reset behavior requires deliberate user authorization; the audit only identifies the mismatch.

## Intentional compatibility / already converted

- `DataService:20–30,57,62` retains Counts, TotalRolls, Equipped and the starter shovel while initializing independent `d.Plow`. This is compatible with the accepted restorable Legacy mode, not a reason to delete existing player data.
- `PlowRules:17–41` validates parts/build and preserves independent offer/reservation/roll state; old single offers migrate to pedestal 1 at line 36. Whole-profile save serialization (`DataService:81–84`) includes the Plow table. This source inspection does not test real persistence.
- `RebirthRules:40–51` retains upgrades, Counts, pets and rolls and resets Snow/stages; it does not touch Plow parts/build/offers. Retaining permanent equipment is consistent with the old rebirth contract. Its old shovel sanitization (`RebirthRules:43`; `RebirthService:45`) is compatibility, not evidence that normal snowplow clearing uses shovels.
- `SnowFieldService:204–205` selects exactly one clearing path; current vehicle damage comes from PlowConfig (`SnowFieldService:142–158`), with live Snow/pet payout and the shared treasure hook (`SnowFieldService:111–123,189–192`). Old shovel arm code at lines 88–98 is only reached by Legacy collection.
- `UpgradeService:25–35` retains rebirth, boost and achievement Snow/Luck multipliers. `PlowService:63` reads the same effective LuckMult for part offers, so Daily, codes, timed events and previously earned achievement bonuses already affect the current loop.
- `WheelService` has no shovel Inventory/Equipped/Counts/TotalRolls dependency: spins come from stage attributes (`64–88`), outcomes are Snow or the shared boosts (`42–53,123–128`). Keeping the Lucky Wheel is not a legacy shovel bug.

## Recommended order

1. Fix the Roll quest/counter contract and migrate active starts.
2. Define which active upgrade tiles/objectives replace the retired shovel ones while preserving saved ownership and Legacy.
3. Refresh active vehicle stats when mapped upgrades change, and address saturated width sales.
4. Update admin-only tutorial/reset semantics separately, without running resets.

