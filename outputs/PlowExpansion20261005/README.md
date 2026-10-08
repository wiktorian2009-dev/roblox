# Snowplow expansion — 2026-10-05, Claude

Place **money (94130990350526)**, Studio session f765f9ae. Everything below is **live in Studio Edit. Not saved, not published:** no MCP tool can save or publish the place, so use File > Save / Publish in Studio.

## What changed
- **90-part catalog** (30 blades / 30 engines / 30 running gear), including the 8 old ids. Every part has a band (14 world themes), a rarity, an explicit price, real stats and a description. It is generated from `sim/catalog.py` + `sim/final_balance.json` by `sim/gen_lua.py`, and the full table is in `data/catalog_final.json`.
- **New runtime stats:**
  - Engines have `AccelTime`, which sets the hull `Accel` the drive client uses.
  - Top speed is capped at 60 (`C.Drive.TopSpeedCap`).
  - Every field stage has an explicit toughness (`C.Toughness`). Blade efficiency = Soft + (Hard − Soft) × toughness, so soft fields favour wide sweepers and hard fields favour icebreakers.
- **Offer pool (`C.OfferPool`):**
  - Each part's weight = relevance to the player's band × role weight × luck. Relevance by (part band − player band): −3: 0.04, −2: 0.2, −1: 0.85, 0: 1, +1: 0.5, +2: 0.16, +3: 0.05. Older bands get 0.04; parts more than 3 bands ahead are never offered.
  - Luck uses factor = min(2, 1 + 0.25 × log2(luck)), applied as factor^(rank − 3) to Rare and above only.
  - Practical parts (A role, current or previous band) always keep at least 45% of the pool.
  - The card shows the real current probability.
  - **Bad-luck protection:** `p.Dry` counts rolls in a row without a *useful* offer (one that is not owned and is more than 3% better than the best owned part in its slot, measured on the player's newest stage with `C.Score`). After 6 such rolls, the next roll is drawn only from useful parts up to band +1.
  - Prices are fixed per part. An offer keeps the price it was rolled with.
- **Server:**
  - PlowService handles the pool, protection, Band/Luck/Dry in the snapshot, and the starter fallback. Unequip puts the free starter part back, so a plow can always drive.
  - PlowRules fills empty or invalid slots with starter parts and sanitises `Dry`.
  - SnowFieldService uses `C.ToughnessOf`.
- **Clients:**
  - Offer card: real odds, an Accel/Push/Pivot stat line, and a "+X% clearing here vs your …" comparison.
  - Workbench: comparisons on every row and a Pivot/0-top line. The UNEQUIP button is hidden when the starter part is fitted.
  - Parts collection: tabs for BLADES / ENGINES / WHEELS & TRACKS (30 cards each, ordered by band, built only while the panel is open).
- **Models:**
  - 90 Blender part models are in ReplicatedStorage.PlowParts, each with a Root PrimaryPart and Min/Max attributes. The chassis and its attach contract are unchanged.
  - 70 rebuilt pets are in ReplicatedStorage.PetModelOverrides.
  - Golden pets are recoloured at runtime by part role (PetModels.create). The faces and markings keep their colours, and a few sparkles are added. MachineService no longer makes tinted copies.
  - The snow globe shows the new BladeWide, EngineBalanced and GearTracks models.
- **Economy:**
  - Stage costs: Desert 5K, Cursed 3M, Crystal 1.1B, Retro 260B, Jungle 1.6T, Absolute Zero 17T, Portal 600T, Candy 37Qa, Atlantis 230Qa, Toybox 670Qa, Clockwork 3.1Qi, Cloud 29Qi, Cosmic 260Qi.
  - Egg prices, World 2 upgrade prices and rebirth milestones follow their stage. World 1 upgrade prices follow the existing curve, which reads StageConfig.
  - SnowStages TileHP was re-tuned. The previous values are kept as the `PreExpansionTileHP` attribute.
  - Two new achievements: Parts30 and Parts90.

## Why the economy moved
With the original stage costs, simulated plows finished World 1 in about 31 minutes. Upgrades (×1000 Snow) and pets (×50–100) were tuned for the much slower shovels.

I kept snow per layer unchanged. I tuned field HP so that clearing is power-limited but healthy: the power rate is about 35–40% of the coverage/regrowth limit while a stage is being worked. Then I tuned the stage gates so an efficient player spends the target time in each stage (`sim/tune3.py`).

## Balance results
`sim/evaluate.py`, 40 fixed seeds per behaviour (20 for rebirth). These are **model estimates, not human playtests.** Times are in minutes (P10 / median / P90).

| Behaviour | World 1 | World 2 | Parts bought in W1 | First part |
|---|---|---|---|---|
| Efficient engaged | 176 / 215 / 247 | 239 / 276 / 300 | 21 | 0.8 min |
| Casual (72% active) | 313 / 364 / 431 | – | 20 | 7.8 min |
| Ignores rewards | 220 / 251 / 304 | – | 21 | 5.8 min |
| Unlucky (worse of 2 draws) | 197 / 221 / 248 | 432 / 479 / 568 | 24 | 0.7 min |
| Lucky (better of 2 draws) | 163 / 182 / 208 | 240 / 254 / 276 | 20 | 4.7 min |
| Rebirth replay (8 rebirths, keeps parts/pets/upgrades) | 5 / 7 / 13 | – | 1 | – |

- **Efficient player, median arrival per stage (min):** Desert 2.3, Cursed 11, Crystal 29, Retro 53, Jungle 86, Absolute Zero 128, Portal/Sakura 215, Candy 239, Atlantis 284, Toybox 320, Clockwork 382, Cloud 432, Cosmic 490.
- **Useful offers:** a median of 2 rolls between useful offers, P90 6 (the protection threshold). Measured in play time: median 0.3 min, P90 4 min.
- **Meaningful upgrades** (income +15%): median every 2.2 min, P90 16.5 min, longest gap 42 min for efficient players. The longest gap for casual players is 118 min, during the Absolute Zero → Portal save.
- **World 2 assumption:** about 4–5 h for an efficient player, slower than World 1 per stage, with Cosmic as the end. The casual World 1 time (~6 h including 28% idle) is above the 3–5 h band. Active play time for casual players is about 4.4 h.

## Checks run in Studio (isolated Play, BalanceTestMode)
45/45 automatic checks passed.

- **Catalog:**
  - 90 parts, split 30/30/30; all 8 legacy ids preserved.
  - Every part resolves to a template with a Root and assembles on the chassis.
  - All 27,000 combinations give finite stats and Score, both with and without maximum upgrades. Maximum top speed is 60 and maximum footprint 20.8.
  - Malformed builds are handled safely.
- **Save migration:**
  - Old saves keep their parts.
  - Unowned build slots fall back to starter parts.
  - Old offers and reservations keep their stored price; unknown offers are dropped.
- **Offer pool:** the pool sums to 1 for every band and luck value, and practical parts keep at least 45% even at luck 1e9.
- **Real handler:**
  - Garage-only rolling, cooldown, and wallet-independent prices.
  - Not enough Snow, forged token and bad pedestal are all rejected.
  - Buying is atomic; duplicate buys are rejected.
  - Reserve, confirmed replace, and buying the reserved part.
  - Reroll replaces only its pedestal.
  - Bad-luck protection fired.
  - 35 of 40 offers came from the current band ±1.
  - All 90 parts equip in their slot; a wrong slot is rejected; unequip puts the starter part back.
- **Driving and clearing:**
  - Four representative builds drive and park.
  - Driving across the Starter field paid Snow (376 layers in 5 s with a strong engine; 51 layers in 4 s creeping).
- **Rebirth:** keeps all 90 parts and the build, and resets the band.
- **Pets:**
  - All 70 base and 70 Golden models build, with eyes, a gold body and sensible sizes.
  - Fusing 3 Snow Bunnies made a Golden Snow Bunny.
  - Equipped Galaxy Dragon, Golden Snow Bunny and Golden Yeti follow the player in workspace.FollowingPets.

## Not verified
- **Studio screen capture and simulated key presses timed out or did nothing** (the Studio window was probably minimised). So these were not checked by me:
  - in-Roblox screenshots of parts and pets
  - garage card / workbench / collection-tab layout seen in use
  - the hatch reveal visuals
  - touch and controller layouts
- Multiplayer garage offers; the boss fight with new parts (FrostKingService uses `StatsFor`, so it is compatible); real DataStore persistence.
- Treasure rate in long runs; regrowth timing; real human pacing.

## Files
- `parts/`: builders, PlowParts90.blend, fbx/, renders/, manifest.json.
- `pets/`: builders, Pets70.blend, packs/, renders/, manifest.json.
- `ASSET_MANIFEST.json`: every model, its asset id and its Studio path.
- `gallery/index.html`: contact sheets, vehicles, Golden sheet, catalog table and balance results.
- `sim/`: gamedata, model, catalog, sim, tune3, evaluate, gen_lua, final_balance.json, evaluation_*.json.
- `build/`: generated PlowConfig, the edit lists applied live, and the hash check.
- `disk-before/`: the previous mirror copies.

## Recovery
- **Studio:** ServerStorage.PlowExpansionBackup_20261005 holds:
  - the before-sources of 21 scripts, with an OriginalPath attribute
  - the old PlowParts and PetModelOverrides
  - SnowStagesAttributes
  - the old SpinningSnowplow
- Raw imports are in ServerStorage.PlowExpansionImports.
- Restore sources and folders together. Old profiles stay compatible because the ids are unchanged.
