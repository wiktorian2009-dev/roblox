# 5-hour game: rebirths out, rebalance, mini plows (2026-10-06, Claude)

wiktor: "remove rebirths rebalance everything so game can done in like 5 hours f2p and add automatic collection upgrade like mini version of ur cars driving in ur best field".

## Rebirths (save point 50)
Everything moved into `ServerStorage.RebirthsBackup_20261006` (Moved = objects with OrigPath, ScriptsBefore = edited scripts). Old saves keep `d.Rebirths`; nothing is wiped. Disk copies of removed sources (incl. RequestRebirth.model.json): `outputs/Rebirths20261006/removed`.

## Economy (save point 52)
- Tuned in the sim so the casual free player (no paid boosts) reaches Cosmic and owns the four top parts in ~5 h.
- Files in `outputs/Rebalance20261005/sim/`: `eval5h.py` (whole-game eval), `tune5h.py` (gate tuner, casual targets), `minis.py` (mini plows in the sim), `emit5h.py` (writes game/src; re-run safe), final variant `tuned5h_f.json`. `FINAL_B` in model.py = live `C.Offers.FinalBandPremium`. Studio was patched with `outputs/FiveHour20261006/make_patch2.py` output and verified byte-for-byte against disk.
- Changed: 12 stage gates (Desert kept), 133 part prices (they follow the gates), 12 egg prices, 28 World 2 upgrade prices, the Snow2 achievement goal (Snow1-3 = 20K / 7M / 200M), mini level prices, and `C.Offers.FinalBandPremium = 6` (in Cosmic its 4 premium parts show 6x more often, about 1 in 20 rolls each). World 1 upgrades follow StageConfig; part-level prices follow part prices. Pet boosts, fields, AFK 0.70, drift +50%, jobs, treasures unchanged.
- Gates (live before -> now): Desert 5.4K, Cursed 594K -> 130K, Crystal 33.5M -> 7.5M, Retro 842M -> 58M, Jungle 4.32B -> 880M, Absolute Zero 15.1B -> 4.9B, Portal 119B -> 86B, Candy 850B -> 410B, Atlantis 2.7T -> 2.4T, Toybox 6.7T -> 6T, Clockwork 17T -> 8.6T, Cloud 51T -> 16T, Cosmic 330T -> 96T. Top parts 150T -> 42T (body 17T).
- Backups: `ServerStorage.FiveHourBackup_20261006` (pre-economy copies; `.FirstPass_v1` = the first pass before the review re-tune); disk `outputs/FiveHour20261006/before/` (pre-economy, PlowConfig includes the mini block) and `before2/` (first pass).

### Sim, 16 seeds, minutes (median / p90). DONE = reached Cosmic and owns the 4 top parts. Estimates, not playtests.
| Profile | Before DONE | After DONE | After World 1 | After Cosmic | Longest wait for a +6% buy (to Cosmic) |
|---|---|---|---|---|---|
| efficient | 291 / 307 | **165 / 182** | 63 | 151 | 16.5 -> 11.6 |
| casual | 716 / 771 | **303 / 328** | 114 | 275 | 81.8 -> 25.2 |
| no rewards | 586 / 631 | **276 / 287** | 109 | 265 | 54.9 -> 17.0 |
| jobs | 279 / 296 | 160 / 170 | 62 | 147 | 16.5 -> 11.3 |
| unlucky | 480 / 534 | 234 / 253 | 73 | 213 | 42.8 -> 26.5 |
| lucky | 256 / 272 | 144 / 152 | 56 | 132 | 15.0 -> 9.7 |
| boosted (paid) | 245 / 257 | 138 / 142 | 53 | 127 | 13.3 -> 8.6 |
| simple buyer, efficient | 502 / 566 | 241 / 255 | 71 | 223 | 47.2 -> 23.2 |
| simple buyer, casual | 840+ (3/16 done) | 431 / 455 | 135 | 366 | 60.2 -> 35.4 |
| simple buyer, no rewards | 840+ (0/16 done) | 476 / 524 | 137 | 452 | 102.6 -> 61.2 |

- Cadence after: a +6% improvement every 0.4-0.6 min in the first hour (median), every 2-5 min in the last hour; the longest stretch with nothing affordable within 10 minutes is 2-3 min for every profile (was up to 43 min).
- Weak spots left: casual / no-rewards players still have single waits of ~17-25 min (p90 ~37) in World 2 between big buys, though smaller buys keep coming. Casual first part ~9.5 min is the known sim artefact (7-minute garage visits); the efficient sim buys its first part at ~2 min.
- Caveat on "Before": the sim prices World 1 eggs / parts / Sakura-row upgrades from the gates, so its Before run charged up to ~15% more than the live game did (live had only the gates at x1.08). After-sim and live now agree exactly.
- Logs: `outputs/Rebalance20261005/results/eval5h_before16b.log`, `eval5h_after16f.log` (earlier passes: `eval5h_before16.log`, `eval5h_after16.log`, `eval5h_after16e.log`).

## Mini plows (save point 51)
- MINIS button left of UPGRADES (hidden with the bottom bar, e.g. on the arena island) opens a small panel (level, minis, Snow/s, next level, BUY/UPGRADE).
- 8 levels: 1 mini at 5% up to 5 minis at 9% each of what your build clears per second in your best unlocked field (`C.MiniBase`, same formula as the sim), then pets and SnowMult like AFK; no drift, no combo. Paid once a second by `MiniPlowService` only while you're in the game with the tutorial done. Prices: 650, 13K, 750K, 5.8M, 88M, 3.4B, 190B, 690B.
- Play-measured on Starter with the starter plow: all 5 minis 11.9 Snow/s; AFK plow 12.9; plain driving ~18.4 (before dig combo and drift). The first version (6-12%) gave 15.8, more than AFK, so the shares were lowered and the economy re-tuned.
- Visuals (`MiniPlowClient`): scaled copies (0.38) of your equipped plow, anchored, no collisions, blade first on a closed lawnmower loop over that field (no jumps), resting on the stage's snow height, with a small snow spray; your own first, then nearby players', at most 12 drawn per client; 46 parts per mini. Instances stayed flat in a 10 s check.
- In the sim the minis are ~32% of a casual player's Snow and ~20% of an efficient player's.
- Undo: delete MiniPlowService, MiniPlowClient, ReplicatedStorage.MiniPlowRemote; restore PlowConfig / AfkDriftClient / AdminService from `ServerStorage.MiniPlowsBackup_20261006`.

## Independent review (35 agents: 5 reviewers + 2 skeptics per finding)
Fixed: mini path teleport at the loop wrap, fixed 2.4 snow height, MINIS/AFK placement ignoring the GUI inset (AFK sat higher than UPGRADES), MINIS staying on the arena island, admin `reset` keeping mini levels, leftover RequestRebirth.model.json, emit5h re-run halving the Snow goals, sim not paying minis during buys/travel and over-paying them in jobs, sim achievement goals out of date, disk backup of PlowConfig missing the mini block, README gate count.
