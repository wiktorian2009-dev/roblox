# Old shovel removal — 2026-10-05

Implemented in live Studio Edit, place money (94130990350526). Not saved or published in Studio. No real player-data reset.

The sole active equipment system is snowplows. The old shovel scripts, models, remotes, roll UI, cinematic, Forge and preview were moved into ServerStorage.ShovelRemoval_20261005. Shared Snow, pets, treasures, rewards, stages and existing upgrade artwork remain.

32 sources changed. Quests/leaderstats now count historical + plow rolls, with a one-time migration preserving existing quest progress. Part achievements preserve old IDs and unlocked bonuses. All 138 upgrade IDs/prices/positions/art remain; obsolete effects now improve Snow, offer luck/cooldown. Width overflow improves clearing power; active vehicles refresh after upgrades. Frost King uses plow stats and shared parking. Index shows eight actual parts and Inventory keeps pets. The snow globe displays a complete miniature plow. Admin part/tutorial/reset paths use plow data; the reset command was not executed.

## Verification

server-validation.json records 25 passing checks in an isolated Play session. Tests covered starter parts/no Tin, intro readiness, historical data, quest migration, garage roll/cooldown/purchase, boss strength/reach/rewards, no attack without a blade, live vehicle refresh/parking and rebirth preservation. Runtime part cards had all eight actual models and correct starter ownership. Desktop parts/pets screenshots were reviewed.

The own Play session was stopped, BalanceTestMode removed and the temporary test script removed. Test isolation covers the main DataService only. No real persistence, multiplayer, mobile or full boss encounter was tested. Console gameplay startup showed no application errors; mouse automation produced CoreGUI tool warnings.

Crafting still has no production recipes. Eight current parts do not yet cover full late-stage progression; pacing needs a measured tuning pass and additional parts.

## Files and Graphify

final-sources.json contains exact final live sources. source-mirror-manifest.json records file paths/hashes for 32 mirrored sources. Before disk copies are in disk-before/; obsolete disk files/binaries are in disk-removed/. The latter are outside the graph/Rojo scope. Studio-only GUI hierarchy/world models remain in Studio; this folder is not a full place export.

Graphify extraction + clustering finished: 665 nodes, 1,408 edges, 56 communities. The Lua parser partially extracts AdminService/FrostKingService around Luau syntax; runtime checks provide separate evidence. Rojo's active connection was not verified.

## Recovery

Studio archive ServerStorage.ShovelRemoval_20261005:
- Sources: 94 original source clones, named by full path, OriginalPath attribute.
- Removed: 36 moved roots, named by full path, OriginalPath attribute; disabled scripts have OriginalDisabled.
- GuiHierarchyBeforeRemoval: full RNGGui hierarchy before child removal. It contains already-patched script sources; restore original Sources as well when reverting.

For a full rollback, stop Play, disconnect any stale Rojo writer, verify newer Claude/Codex changes, restore original source clones to their OriginalPath, then return removed objects to their original parents/names and restore OriginalDisabled. The full GUI backup can recover the old UI hierarchy, but must also receive the original source versions. Remove the new miniature SpinningSnowplow if restoring SpinningShovels.

Restore disk-before/ and disk-removed/ deliberately to match the selected Studio recovery state. Do not blindly copy the entire backup over newer work. Historical profile ownership was retained for recovery.

PlowConfig.Mode = "Legacy" is no longer a supported rollback: the old source/object graph must be restored together.

CLAUDE-PROJECT-INSTRUCTIONS.txt is the current copy-paste coordinator Goal text.

