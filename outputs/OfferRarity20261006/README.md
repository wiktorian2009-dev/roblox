# Good parts rarer (2026-10-06, Claude)

wiktor: "good items should be rarer bc when i tested the game most of things i could even think about with my budget".

## Measured first: after the rescale, with the new 30 s expiry, at the old odds (efficient value buyer, 16 seeds)
- 42% of rolls were useful and 29% were useful and affordable.
- 26% of rolls were premium (B/C) parts.
- Bad-luck protection fired after only 6 dry rolls, which is about 12 s at a 2 s cooldown.
- The rescale alone did not fix the complaint: expiry even raised the affordable share, because stale offers no longer sit on the pedestals.

## Change (PlowConfig C.Offers + C.Shop; the card odds are the same C.OfferPool the server samples)
| | Before | After |
|---|---|---|
| Role weight A / M / B / C | 1 / 0.7 / 0.42 / 0.16 | **0.8 / 0.6 / 0.15 / 0.04** |
| Relevance: older -3 / -2 / -1 | 0.04 / 0.2 / 0.85 | **0.2 / 0.7 / 1.0** |
| Relevance: newer +1 / +2 / +3 | 0.5 / 0.16 / 0.05 | **0.22 / 0.05 / 0.015** |
| Practical floor | 45% | **25%** |
| Bad-luck protection after | 6 dry rolls | **15** |

## Result (simulation, 40 seeds, rescale + expiry + new odds vs the rescale alone)
| Behaviour | Useful rolls | Useful + affordable | Longest dry streak |
|---|---|---|---|
| efficient | 39% → **27%** | 26% → **22%** | 6 → 15 (pity) |
| casual | 43% → **33%** | 27% → 27% | 6 → 15 |
| no rewards | 35% → **24%** | 23% → **19%** | 17 → 15 |
| unlucky | 26% → **15%** | 22% → **14%** | 6 → 15 |
| World 2 | 25% → **17%** | 18% → **14%** | max 110 → 93 |

Premium parts are about **14%** of rolls (was 26–27%).

Pacing:
- World 1: efficient 146 min, casual 215, no rewards 212, unlucky 216.
- World 2: 275 min. Rebirth replay: 5.3 min.
- Longest stretch with nothing affordable, P90: 2.9 / 4.9 / 7.4 / 3.2 min.

So there are no multi-hour droughts. Protection still hands out a useful part after at most 15 dry rolls (about 30 s of rolling).

Real Play check: 45 real rolls at band 1 matched the displayed pool within noise. A parts made up 98% observed vs 90% expected; C parts 2% vs 3%.

The generator variant (sim/rescale_final.json, "Offers" + "OfferExpiry") holds the same values, so future sims match the live odds.

## Undo
ServerStorage.OfferRarityBackup_20261006 holds PlowConfig.
