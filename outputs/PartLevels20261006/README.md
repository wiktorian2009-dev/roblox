# Part levels (2026-10-06, Claude)

## Price retune (save point 32): this replaces the old cost line below
- **Curve** (`PlowConfig C.Levels`): Cost0 0.25, Growth 1.45 up to level 3, then ×10 (LateJump) for 3→4 and ×3 (LateGrowth) per level after that, capped at 990T per level (Cap). +5% per level and max level 10 are unchanged.
  - **Basic Blade** (levels 1→2 … 9→10): 15, 22, 315, 946, 2.8K, 8.5K, 25.5K, 76.6K, 230K.
  - **Top part** (gear_meteor, 150T): 37.5T, 54.4T, 788T, then 990T (the cap) for every step from 4→5 to 9→10.
  - **Pass part** (gear_aurorawheels): 500, 725, 10.5K, … 7.7M.
- **World 1 gates are 8% pricier** (StageConfig, Desert to Portal): 5.4K, 594K, 33.5M, 842M, 4.32B, 15.1B, 118.8B. UpgradeConfig's curve reads these, so World 1 upgrades rise with them, as in the sim.
- **Why +8% and not more:** cheap levels 1–3 always shorten World 1 for a value buyer. Gates of +12% / +15% / +18% reached 142/209, 147/212 and 154/222, but made the longest casual wait 3.7–3.9 minutes longer than the no-levels baseline, past the 1.5-minute limit. So the fallback was chosen: cheap levels with gates +8%.
- **Sim, 40 seeds** (levels.py, `rescale_w1x108.json`). The no-levels baseline on the same code is 150 / 214 / 289 / 281.

| | Efficient W1 | Casual W1 | Simple-buyer W1 | World 2 | Longest gap, eff / casual |
|---|---|---|---|---|---|
| No levels (baseline) | 150 | 214 | 289 | 281 | 12.6 / 21.1 |
| **Live now** | **143** | **206** | **271** | **233** | 13.5 / 24.1 |

- **Play check (BalanceTestMode):** Basic Blade levels bought at 15, 22, 315 and 946 Snow, exactly the config's prices.
- **Undo:** `ServerStorage.LevelCurveBackup_20261006` (PlowConfig, StageConfig, UpgradeConfig), or the disk copies in `curve_before/`.

wiktor: "Also add cheap and good levels to things like plow car body wheels and engine".

## What it is
- **Which parts:** every part in all four slots (blade, engine, running gear / wheels, body) levels **1 → 10**, including the free starter set. The cost is **Snow only**.
- **Where:** each part row at the **garage workbench** has a gold **LV n ↑ ❄cost** button, using the SnowArt look; the name shows "Lv n". The upgrade screen and the HUD are untouched.
- **What a level does:** the part's key stat ×(1 + 5% × (level − 1)), so level 10 = ×1.45.
  - Blades: Soft and Hard efficiency.
  - Engines: power, plus a quarter of the step as top speed (the 60 cap still applies).
  - Gear: pushing power.
  - Bodies: their Snow bonus, plus +0.8% Snow per level, so the free cab is worth levelling too.
  - On the starter build, one level = **+5% clearing**.
- **Cost:** level L → L+1 costs the part's price × 25% × 1.45^(L−1). Free parts use a 60-Snow base and pass parts a 2,000 base. Prices are fixed and never depend on the wallet.
  - Basic Blade: 15, 22, 32, 46, 66, 96, 139, 202, 293.
  - The top part's last level: ~733T, so nothing goes past the trillions.
- **Ownership:** the level belongs to the owned part (`d.Plow.Levels[id]`). Swapping parts or buying another copy keeps it.
- **Where levels count:** every server stat (driving, clearing payouts, jobs, Frost King estimates), the offer card's "+x% vs your part" comparison, the workbench stats, and bad-luck protection's "useful offer" check. Levelled parts are the baseline, so protection ranks parts correctly.

## Files
- `PlowConfig`: `C.Levels`, `LevelOf`, `LevelStats` (cached), `LevelCost`; `StatsFor` reads `mods.Levels`.
- `PlowRules`: sanitises levels. **Versioned, idempotent migration:** `LevelsVersion 1` starts every owned part at level 1. It only runs for profiles that really loaded; the save-safety fix never builds failed loads.
- `PlowService`:
  - `mods(player).Levels`;
  - `snapshot.Levels`;
  - **`actions.LevelUp`**: owned part, same garage-bay check as Equip, max level, Snow check, 0.35 s rate limit, stats refresh if driving.
- `PlowShopClient`: the LEVEL buttons; `clientMods().Levels`.
- `ContractService`, `FrostKingService`: levels in their stat mods.
- **Sim:** `outputs/Rebalance20261005/sim/levels.py` (mirrors the Lua) and `gaps.py`.

## Simulation (estimates, not playtests; full log `sim_levels_40seeds.log`)
40 seeds, live economy (rescale + expiry + rarity). World 1 minutes, median:

| Behaviour | Before | With levels |
|---|---|---|
| efficient | 146 | 119 |
| casual | 215 | **182 (3.0 h)** |
| no rewards | 212 | 184 |
| unlucky | 216 | 166 |
| simpler buyer, casual | ~288 | 229 |
| boosted (paid) | ~85–91 | 74 |

- World 2: 266 → 199 min. Rebirth replay: 5.1 min.

**Longest wait between improvements**, in minutes (16 seeds, same seeds before and after; `gaps.py`). Cells are median / p90.

| Buyer | Wait for | Before | With levels |
|---|---|---|---|
| efficient | any +2% | 8.6 / 13.6 | 8.3 / 10.7 |
| efficient | +10% | 16.7 / 23.0 | 16.0 / 20.7 |
| casual | any +2% | 19.1 / 22.8 | 16.3 / 26.5 |
| casual | +10% | 21.3 / 29.8 | 24.2 / 40.1 |
| simpler buyer | any +2% | 24.2 / 40.0 | 22.7 / 32.4 |
| simpler buyer | +10% | 54.2 / 71.5 | 54.8 / 68.3 |

**Honest read:**
- Waits get shorter almost everywhere.
- The exception is the **casual value buyer**: in the model, it spends on levels, so its waits for **+10%** purchases get longer, and its p90 for any +2% grows by about 4 minutes.
- World 1 stays at about 3 hours for casual play, and at 3.8 hours for the simpler buyer.
- The efficient player is now at about 2 hours; it was already 2.4 hours.
- Paid offers stay optional: they still speed things up by the same share.
- Levels shorten World 1 by roughly 15–20%. If wiktor wants the old length back, the stage gates can be re-tuned with `tune_gates.py`.

## Tests (Play, BalanceTestMode, real clicks at the workbench)
- **Migration** (copied old profile): 6 owned parts → level 1, `LevelsVersion` 1. A second Apply kept an existing level 4. Bad data was cleaned (99 → 10, unknown parts dropped, NaN dropped).
- **Not enough Snow:** "You need 15 more Snow", no change.
- **Level up** (1,000 test Snow): Basic Blade → Lv 2, Snow 1,000 → 985.
- **Two clicks 120 ms apart:** exactly one level (→ Lv 3, Snow 963).
- **Swap:** EQUIP Wide Clearing Blade, then EQUIP Basic Blade again → still Lv 3.
- **Max** (engine set to 9, simulated): click → "Starter Engine is now level 10 (MAX)!" (Snow 963 → 670, cost 293). A further click → "max level"; the server also refuses ("already at max level 10").
- **Server refuses** a part you don't own and a bad argument, with no Snow spent.
- The workbench stats show levelled values (top speed 27, clearing power 6.5 at engine Lv 10), and the offer comparison uses the levelled blade (`screens/workbench_levels.jpg`).

## Not tested / not included
- **Index:** shows part ownership counts only, with no stats, so nothing to change. There is no EQUIP BEST for parts; the pet EQUIP BEST is unaffected.
- **The bottom-left power readout** (LuckDisplay, Studio-only) still shows unlevelled power. It's queued for removal (blocked on this PC).
- Phone layout of the LEVEL buttons; a real save round-trip (no DataStore in isolated tests).

## Undo
`ServerStorage.PartLevelsBackup_20261006` holds the six previous scripts. Levels already saved in profiles are harmless without the feature.
