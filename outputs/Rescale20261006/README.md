# Economy rescale: nothing above the trillions, small steps (2026-10-06, Claude)

wiktor: "we dont need to have amounts exceeding trillions just lower it down everything" (+ "still big jumps").

## Method (outputs/Rebalance20261005/sim)
- **`compress.py`:** every growth multiplier is raised to the power **c = 0.58**. That covers:
  - field SnowPerPhase and TileHP, relative to the Starter field;
  - engine Power, gear PowerMult and blade Soft/Hard;
  - every ×(1+a) Snow or clearing-power upgrade, which becomes ×(1+a)^c in 0.05 steps;
  - pet boosts, as ((1+3b)^c−1)/3;
  - body Snow, and Snow per rebirth (0.5 → 0.22).

  Income therefore grows far more gently over the game. The starting values are unchanged, so the start plays the same.
- **`tune_gates.py --all`:** all 13 gates are re-tuned until the simulated efficient player reaches every stage at the same minute the previous economy produced (eval_final150).
- **Prices that follow the gates:** parts, World 1 upgrades (the curve), World 2 upgrades, eggs and rebirth milestones.
- **Smoothing:**
  - Desert premium parts are priced at 17.6K (BPriceShare 0.032).
  - Body prices are spaced evenly from 150 to 60T (×7.8 per step).
- **Regenerating:** variant `sim/rescale_final.json`. `gen_lua2.py` (default variant now) and `emit_rescale.py` write the live files. A regeneration cannot bring the old scale back: the old-scale variant is `final_variant.json`, and the emitter always starts from the stored old-scale reference values.
- **Measuring "meaningful":** progress is compressed, so "meaningful" is measured as the same share of the income journey (+10%^c ≈ +5.7%). The raw +10% numbers are kept too (eval_rescale2raw.json).

## Gates (before → after)
Desert 5K → **5K**, Cursed 3.06M → **550K**, Crystal 1.14B → **31M**, Retro 191B → **780M**, Jungle 2.38T → **4B**, Absolute Zero 24.2T → **14B**, Portal 784T → **110B**, Candy 68.4Qa → **850B**, Atlantis 429Qa → **2.7T**, Toybox 1.3Qi → **6.7T**, Clockwork 6Qi → **17T**, Cloud 56.1Qi → **51T**, Cosmic 521Qi → **330T**.

The largest amounts now are the last World 2 upgrade (**660T**), the Cosmic gate (330T), the top part (150T), the Star egg (33T) and the 50th rebirth (~150T). T is the biggest suffix shown.

## Part steps (LADDERS.md has the full ladders)
| Slot | Biggest neighbour step | Median step |
|---|---|---|
| Blade / Engine / Gear | ×447 → **×12** | ×1.85 → **×1.38** |
| Body | ×605 → **×8.1** | ×12.9 → **×7.8** |

## Pacing (simulation, 40 seeds; full tables in BEFORE_AFTER_sim.md)
| Behaviour | World 1 min (median) | Longest gap P90 | Unavailable P90 |
|---|---|---|---|
| efficient | 141 → **139** | 19.1 → **14.1** | 2.9 → **3.6** |
| casual | 217 → **213** | 29.2 → **23.6** | 6.7 → **11.6** |
| no rewards | 224 → **211** | 33.8 → **20.3** | 1.9 → **9.5** |
| unlucky | 191 → **213** | 25.6 → **38.5** | 8.2 → **4.4** |
| boosted | 95 → **85** | 12.4 → **10.1** | 2.9 → **2.9** |

- **World 2:** 297 → **266 min**. Rebirth World 1 replay: 5.3 min.
- **Jobs:** still 2.0× collecting.
- **First part:** about 2 min.
- **Weak spots:** with the raw +10% bar, the casual player's unavailable P90 is 20.6 min and the unlucky player's longest gap P90 is about 40 min. These are the places to watch in task 2 (part rarity), which re-runs the sims.

## Old saves: ServerScriptService.EconomyMigration (versioned, d.EconomyVersion = 2)
- **Converted once:** Snow, lifetime Snow, the recent Snow/s, "Dig" quest goals (progress kept) and job bonus Snow. Values map log-linearly between matching old and new gates; amounts below the Desert gate are unchanged.
- **Re-priced:** saved offers and the reservation, with C.OfferPrice (the lower price wins).
- **Kept as they are:** parts, pets, stages, rebirths, upgrades and settings.
- **New profiles** start at version 2 and are never converted.
- **Tests (Studio, Play):** I used three copied old-scale profiles. Studio has no API access, so the real saved profile couldn't be read.

  | Profile | Snow | Lifetime Snow | Saved offer | Reservation |
  |---|---|---|---|---|
  | Desert | 3.2K → 3.2K | — | — | — |
  | Jungle | 1.2T → 1.5B | 9T → 6.3B | 480B → 660M | 3.7T → 3.1B |
  | Cloud | 30Qi → 48T | — | — | — |

  - The quest kept 50% progress.
  - A second Apply changed nothing.
  - A fresh profile is not converted.

## Real Play tests (BalanceTestMode, removed afterwards)
- All configs load. The maxima listed above were confirmed in a fresh server.
- Upgrade texts updated themselves (e.g. "x1.7 snow").
- A fresh profile gets EconomyVersion 2.
- The Desert gate fails at 4,999 and opens at exactly 5,000; Cursed is refused with no Snow.
- Garage roll: Snowball Motor at 300 matches the catalog price. Buying fails at 299 ("You need 1 more Snow") and succeeds at 300.
- The starter build and starter field are unchanged: ClearPower 4.5, speed 24, width 7, field Snow 2, HP 1.6.

## Not tested
- The real saved profile (Studio API access is off).
- Mid- and late-game income on real fields; the model was not calibrated by real driving there.
- Every GUI screen at the new numbers.

## Starter Pack
Starter income is unchanged (~24 Snow/s raw), so its **3,000 Snow** is still about 2 minutes of starter collecting. I left it at 3,000.

## Undo
- Studio: ServerStorage.EconomyRescaleBackup_20261006 holds the configs, SnowStages, the original DataService, PlowRules, UpgradeService and PlowService.
- Disk: outputs/Rescale20261006/before (configs, generator, data).
- Old World 2 field values: rescale_report.json lists the new values; the old ones are OLD_FIELD in sim/emit_rescale.py.
