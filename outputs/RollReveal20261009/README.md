# Part-roll reveal remake (2026-10-09, Claude, save point 61)

Presentation only. The server roll (PlowService actions.Roll: part, price, odds, pity, cooldown, offer timer, BayReveal event) is untouched.

## What a roll looks like now (your own pedestal)
| Phase | Time | What happens |
|---|---|---|
| Activation | 0-0.3 s | Pedestal ring mesh goes neon cyan, flat cyan ring decal, cyan light, 12-puff snow dust, the old part sinks 2.2 studs and fades, camera FOV pushes in 10% (70 -> 63). |
| Buildup | 0.3-1.1 s | Rotating icy rune halo, ~10/s ice sparkles, frosted-ice DECORATIVE previews (Glass, one ice colour, no rarity colour) picked uniformly from your real offer pool, one per slot in turn, at 0.11-0.22 s intervals with a rising tick. Keeps going (0.24 s ticks) until the server answers; gives up after 8 s. |
| Reveal | from max(1.1 s, answer) | Real part rises from -0.8 with an overshoot, a short 70-degree turn settling into the normal idle spin, one expanding rarity-coloured ring, a star burst (6-28 by rarity), light flash, rarity accent sound. Epic: short rising light column. Legendary: 0.4 s navy silhouette first, then colour, stars + two aurora ribbons, a 1.4 s 32-degree camera orbit. |
| Handoff | Common-Rare ~1.75 s, Epic ~1.9 s, Legendary ~2.5 s after the press | FOV back, then the existing offer card opens (header "OFFER - PEDESTAL n", name, rarity, slot, roll chance, price, "You need X more Snow" or "Ready to buy!", BUY / RESERVE / REROLL with their old callbacks). The part becomes the normal pedestal display without a jump. |

Neighbours (other bays within 90 studs): a small ring + burst + light on that pedestal (`Mini`), quiet chime only for rank >= 4. Their camera never moves.

Reduced motion (Settings ReducedMotion, or TreasureReduced): no camera change, no preview cycling, no overshoot/turn, about 0.8 s after the answer.
Skip: E on the pedestal during the reveal, or a click / tap in the world. Same result, no change to roll speed or odds.
Sounds: existing ids only (tick 12221976, GameAudio Start / Reveal / Steps.Epic / Steps.Legendary), one reusable Sound per kind per pedestal (no stacking). Muted by RNGGui attribute RollTickOff, scaled by RollTickVolume, or player attribute RollSoundOff. (There is no general SFX setting in the game.)

## Files
- NEW `ReplicatedStorage.PlowRollReveal` (ModuleScript) = `game/src/ReplicatedStorage/PlowRollReveal.luau` = `src/PlowRollReveal.luau` (byte-identical, 26016 chars).
- `StarterPlayerScripts.PlowGarageClient`: preparePart (shared fitting), refreshBay holds a pedestal while its reveal runs ("ROLLING..." / "click to skip", pill "ROLLING"), E = skip, Api.RollBegin, Studio-only test hook, neighbour Mini, idle spin phase, "OFFER" on your pedestal price label, cleanupBay aborts reveals.
- `StarterPlayerScripts.PlowShopClient`: doRoll (one request per pedestal at a time; reveal starts before the call, resolves with the server answer, aborts on refusal; any open card steps aside and comes back at the handoff or after a refusal), reveal(rank, quiet), OFFER headers.
- `ReplicatedStorage.PlowClientApi`: RollBegin stub.
- Repo: the same edits were merged into the game/src copies with `merge_into_src.py` (they also hold the not-yet-installed 2026-10-08 UI audit), so a later Rojo sync of that audit keeps the reveal. Those merged files were NOT compiled (no luau binaries on this PC); the Studio versions compile.

## Studio test hook (inert outside Studio)
`PlayerGui.GarageInspectGui.RollRevealTest:Invoke(key, partId, rank, delay, speed)` plays the reveal on your own pedestal with no server call (no offer, price or odds change); the pedestal snaps back to its real offer afterwards. `speed` < 1 = slow motion for screenshots.

## Quick Rolls pass (save point 62)
Skipping becomes the perk of a game pass once `PassConfig.QuickRolls.Id` is set (now nil = free skip, no prompts). Owners skip with click / tap / E; non-owners get the pass's purchase prompt (once per roll, at most every 5 s) and the reveal keeps playing. Always free with reduced motion and where paid random items are restricted. Backup: ServerStorage.QuickRollsBackup_20261009.
To switch it on (dashboard steps unverified): Creator Dashboard > this experience > Monetization > Passes > create "Quick Rolls" (image, description "Skip the part-roll animation"), set it on sale with a price, copy its id, then put it in `PassConfig.QuickRolls.Id` (or send it to Claude) and publish.

## Recovery
ServerStorage.RollRevealBackup_20261009 holds the original PlowGarageClient, PlowShopClient (disabled) and PlowClientApi. Restore them to StarterPlayerScripts / ReplicatedStorage (enable the scripts) and delete ReplicatedStorage.PlowRollReveal.
