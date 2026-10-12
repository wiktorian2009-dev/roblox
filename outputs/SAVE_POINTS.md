# Ctrl+S points (collected for the end of the queue, 2026-10-05)

Nothing below has been saved in Studio yet (wiktor is away; no publish).

1. Tutorial v2: PlowTutorialClient + support edits (PlowService, PlowShopClient, PlowDriveClient, FrostKingClient). Backup: ServerStorage.PlowExpansionBackup_20261005.Tutorial_before.
2. Snowplow Bumper Arena: new scripts (ArenaConfig, ArenaService, ArenaDriveClient, ArenaHudClient), edits to PlowService / ContractService / ContractRegistry / PlowDriveClient / PlowTutorialClient, workspace.SnowplowArena (Studio-only geometry + imported meshes), workspace.ArenaPortals, ServerStorage.ArenaBuilt, collision groups ArenaVehicle / ArenaWalkBlock. Backup: ServerStorage.ArenaBackup_20261005.Scripts_before. Art can be re-imported from asset ids in outputs/Arena20261005/manifest.json.
3. World 1 remaster: workspace.W1Remaster (all 7 areas, Studio-only geometry + colliders), ServerStorage.W1RemasterBuilt / W1RemasterImports / W1RemasterKit, archives in ServerStorage.W1RemasterBackup_20261005 (old scenery moved out of workspace), Crystal floor recolour, StageDecorClient edit (mirrored), BiomeLighting.Profiles edit (Studio-only, snapshot in game/studio-snapshots). Packs can be re-inserted from outputs/W1Remaster20261005/manifest.json and rebuilt with place_<biome>.luau.
4. Rebalance + 45 parts:
   - Script edits (all mirrored in game/src): PlowConfig (135 parts), StageConfig, PetConfig, UpgradeConfig, ActivityConfig, ContractConfig, ContractService, PlowService.
   - Studio-only: 45 new models in ReplicatedStorage.PlowParts, the raw packs in ServerStorage.PlowExpansionImports.Rebalance, and the backups ServerStorage.RebalanceBackup_20261005.
   - The models can be re-inserted from outputs/Rebalance20261005/manifest.json (packs Blades_C / Engines_C / Gears_C).

5. Drive feel + drift: PlowDriveClient, PlowConfig (C.Drive / C.Drive.Drift), PlowService (shift-lock pause), SettingsService (DriveSoundOn / ReducedMotion). All are mirrored. Backup: ServerStorage.DriveFeelBackup_20261005.

6. Free quick travel:
   - New scripts: TravelService, TravelConfig, TravelClient. Edited: PlowService (Registry.Spawn / GoGarage / LeaveGarage). All are mirrored.
   - Studio-only: workspace.TravelPad (the Blender pad, plus its SurfaceGui sign, prompt and sparkles), workspace.TravelPoints (16 arrival parts) and ServerStorage.TravelImports (the raw pack plus the assembled TravelPad template).
   - Rebuild path: TravelPoints with outputs/Travel20261005/travel_points.luau; the pad from asset 132785570016808.
   - Backup: ServerStorage.TravelBackup_20261005.

7. Body (150 parts):
   - Scripts, all mirrored: PlowConfig, PlowAssembly, PlowService, SnowFieldService, ContractService, PlowGarageClient, PlowShopClient, PlowTutorialClient, StageConfig, PetConfig, UpgradeConfig, ActivityConfig, and RNGClient (Studio-only, snapshot updated).
   - Studio-only: the split ReplicatedStorage.PlowParts.Chassis, the 15 body models (BodyStarter + 14), and the raw pack in ServerStorage.PlowExpansionImports.Bodies.
   - Backup: ServerStorage.BodyBackup_20261005 (Scripts_before, Chassis_before). Bodies can be re-imported from asset 113098509806776 (outputs/Body20261005/manifest.json).

8. Paid offers:
   - New scripts: PassConfig, PassService, PassClient. Edited: PlowConfig (gear_aurorawheels), PlowService, UpgradeService, ActivityConfig, and RNGClient (Studio-only, snapshot updated). All are mirrored.
   - Studio-only: ReplicatedStorage.PlowParts.GearAuroraWheels and the raw pack in ServerStorage.PlowExpansionImports.Passes.
   - Backup: ServerStorage.PassesBackup_20261005.
   - After saving: follow outputs/Passes20261005/README.md (create the passes, paste the ids, SalesEnabled = true, publish, then turn sales on).

9. Arena void falls (2026-10-06):
   - Scripts, all mirrored: ArenaConfig, ArenaService, ArenaDriveClient, ArenaHudClient.
   - Studio-only: workspace.SnowplowArena.Art.AR_Island Rock + Snow swapped for the pit meshes (asset 78190677650536); 20 SpectatorBarrier segments in the exit gaps moved to ServerStorage.ArenaVoidBackup_20261006.ExitBarriers.
   - Backup: ServerStorage.ArenaVoidBackup_20261006 (old scripts, Colliders, wall/gate art, Markers, OldIslandMeshes). Undo the art by moving OldIslandMeshes back.

10. Garage 1.5x + roll timer (2026-10-06):
   - Scripts, all mirrored: PlowService, PlowGarageClient, PlowShopClient, PlowTutorialClient.
   - Studio-only: the transformed workspace.PlowGarage (1.5x), workspace.ArenaPortals.GarageArenaPortal (moved), and ServerStorage.SharedGarageTemplates (scaled).
   - Backup: ServerStorage.GarageSpaciousBackup_20261006.

11. Garage calm + open pass (2026-10-06):
   - New open shell in all bays and in the overflow template; lowered colliders; matte pedestals.
   - PlowGarageClient is mirrored.
   - Backup: ServerStorage.GarageCalmBackup_20261006.

12. Economy rescale (2026-10-06):
   - Configs: StageConfig, PlowConfig, UpgradeConfig, PetConfig, RebirthConfig, ActivityConfig, DataService.
   - New ServerScriptService.EconomyMigration (all mirrored).
   - Studio-only: SnowStages attributes.
   - Backup: ServerStorage.EconomyRescaleBackup_20261006.

13. Offer expiry (2026-10-06):
   - PlowConfig, PlowRules, PlowService, PlowShopClient, PlowGarageClient (all mirrored).
   - Backup: ServerStorage.OfferExpiryBackup_20261006.

14. Rarer good parts (2026-10-06): PlowConfig (offer odds + ProtectAfter 15), mirrored. Backup: ServerStorage.OfferRarityBackup_20261006.

15. Open-rim arena (2026-10-06): ArenaConfig and ArenaHudClient (mirrored); Studio-only workspace.SnowplowArena changes. Backup: ServerStorage.ArenaOpenBackup_20261006.

16. Garage in the lobby (2026-10-06): PlowService (mirrored); Studio-only workspace.PlowGarage moved, mountains, GarageArenaPortal removed. Backup: ServerStorage.GarageLobbyBackup_20261006.

17. GUI art (2026-10-06): new ReplicatedStorage.SnowArt + PlowShopClient, PlowGarageClient, ArenaHudClient (all mirrored). Backup: ServerStorage.GuiArtBackup_20261006.

18. Tutorial spotlight (2026-10-06): PlowTutorialClient + SnowArt (both mirrored). Backup: ServerStorage.TutorialSpotlightBackup_20261006.

19. Verity Egg (2026-10-06):
   - New ProductService and VerityEggClient.
   - PetConfig, PassConfig, EggModels, DataService, PetService, ActivityService, and 5 income scripts (all mirrored).
   - Studio-only: 5 models in PetModelOverrides.
   - Backup: ServerStorage.VerityEggBackup_20261006.

20. Pet-screen buttons (2026-10-06): new StarterPlayerScripts.SnowArtPetScreens (mirrored). Nothing replaced, so no backup is needed; delete it to undo.

21. Save-load safety (2026-10-06): DataService (mirrored). Backup: ServerStorage.DataLoadFixBackup_20261006.

22. EQUIP BEST (2026-10-06): PetService + SnowArtPetScreens (mirrored). Backup: ServerStorage.EquipBestBackup_20261006.

23. Starter Pack card above REWARDS (2026-10-06): PassClient + PassConfig (mirrored), new icon decal. Backup: ServerStorage.StarterPackCardBackup_20261006.
   (World 1 grounding, corner stats and TRAVEL/HELP are still refused by this PC's permission check: no save point.)

24. Misc upgrades sorted (2026-10-06): UpgradeConfig (mirrored; positions only, prices proven identical). Backup: ServerStorage.MiscSortBackup_20261006.

25. Popup stack (2026-10-06): new StarterPlayerScripts.PopupStack (mirrored). Nothing replaced; delete it to undo.

26. Part levels (2026-10-06): PlowConfig, PlowRules, PlowService, PlowShopClient, ContractService, FrostKingService (all mirrored). Backup: ServerStorage.PartLevelsBackup_20261006.

27. World 1 grounded (2026-10-06): Studio-only Terrain + workspace.W1Grounding (colliders). Backup: ServerStorage.W1GroundingBackup_20261006. (Undone by 31.)

28. Corner stats removed (2026-10-06): Studio-only RNGGui.StatIcons + LuckDisplay deleted. Backup: ServerStorage.CornerStatsBackup_20261006.
29. TRAVEL under HELP (2026-10-06): TravelClient (mirrored). Backup: ServerStorage.TravelHelpStackBackup_20261006.
30. Studio Play without API access (2026-10-06): DataService (mirrored). In Studio only, the "Studio access to APIs is not allowed" error gives a temporary unsaved profile + a "Studio test: progress won't save" notice instead of the kick. Backup: ServerStorage.StudioNoSaveBackup_20261006.
31. World 1 Help-Yard edges (2026-10-06): Studio-only. The grounding terrain is cleared and workspace.W1Grounding moved to backup; new workspace.W1Edges (snow rim, rock underside, 16-stud invisible colliders). Backup: ServerStorage.W1EdgeBackup_20261006. This replaces save point 27's terrain.
32. Part-level price retune (2026-10-06): PlowConfig (level curve) + StageConfig (World 1 gates x1.08), both mirrored. Backup: ServerStorage.LevelCurveBackup_20261006.
33. World 1 edges option 3 (2026-10-06): Studio-only workspace.W1Edges.Walls (waist-high snow-capped rock walls) + W1Edges.Underside (faceted island underside); SnowRim replaced. Script: outputs/W1Edges20261006/build_option3.luau. Backup: ServerStorage.W1EdgeBackup_20261006.Option3Before.
34. Drift Snow bonus (2026-10-06): PlowConfig (C.Drive.Drift.SnowBonus 0.10), SnowFieldService, PlowDriveClient (drift signal), all mirrored. Backup: ServerStorage.DriftAfkBackup_20261006.
36. Taller field walls (2026-10-06): Studio-only W1Edges.Walls rebuilt as ~8 stud continuous snow-capped rock walls (197 segments + caps) on every open World 1 field edge. Script outputs/W1Edges20261006/build_tallwalls.luau. Backup: ServerStorage.W1EdgeBackup_20261006.TallWallsBefore. Garage-island walls: none added (its only open floor edge is the overflow side, which stays open).
56. Trailer kit (2026-10-07, Claude): new ServerScriptService.TrailerBootstrap (Script) + ServerStorage.TrailerKit (TrailerServer, TrailerDirectorGui with 7 scripts). Inert unless IsStudio + ServerStorage TrailerMode/TrailerToken/BalanceTestMode are set. Sources: outputs/Trailer20261006/src (byte-identical). Undo: run src/uninstall_edit.luau (or delete those two objects); nothing existing was changed.
55. Offers beside HELP (2026-10-06, wiktor): PassClient offer column anchored bottom-left right of HELP / TRAVEL, following their live position; hidden while the HELP menu is open. Mirrored (18227 bytes). Undo: save point 54 layout (COLUMN_POS 0.175/0.6, AnchorPoint 0,0); pre-54 version in ServerStorage.OffersEggsPassesBackup_20261006.PassClient.
54. Pass ids + offers on the left + eggs in stages (2026-10-06, wiktor): PassConfig ids (StarterPack 2005917909, PremiumWheels 2006727868, SnowBoost 2008364500; sales OFF; Verity "pass" 2007075863 noted, not wired), PassClient (cards moved to the left box, OP flair, owned-state race fix), PetClient (StageEggs lookup), all mirrored. Studio-only: Workspace.StageEggs (6 World 1 eggs moved out of FrostfallVillage.EggDisplay). Backup: ServerStorage.OffersEggsPassesBackup_20261006 (PassConfig, PassClient, PetClient, full EggDisplay).
53. Starter Pack = Haunted set (2026-10-06, wiktor): PassConfig StarterPack now grants all 10 Cursed-theme parts, no Desert set, no 3,000 Snow; price 15, sales still OFF. Mirrored (live = disk 3985 bytes). Backup: ServerStorage.StarterPackHauntedBackup_20261006.PassConfig.
52. 5-hour economy (2026-10-06, wiktor): StageConfig (13 gates), PlowConfig (139 part prices, mini level prices, C.Offers.FinalBandPremium 6 + one line in C.OfferPool), PetConfig (13 egg prices), UpgradeConfig (28 World 2 prices), ActivityConfig (3 Snow goals). All mirrored (emit5h.py). Backup: ServerStorage.FiveHourBackup_20261006 (+ disk outputs/FiveHour20261006/before). Details: outputs/FiveHour20261006/README.md.
51. Mini plows (2026-10-06, wiktor): new MiniPlowService (server), MiniPlowClient (MINIS button + panel + the minis), RemoteFunction ReplicatedStorage.MiniPlowRemote (made at runtime), PlowConfig C.Minis + C.MiniLevel + C.MiniBase. Profile adds d.MiniPlows {Level, V=1}. All mirrored. Backup: ServerStorage.MiniPlowsBackup_20261006 (PlowConfig before). Undo: delete the two scripts, restore PlowConfig.
52. 5-hour economy (2026-10-06, wiktor "game can done in like 5 hours f2p"): StageConfig (12 gates), PlowConfig (part prices, mini level prices and shares, Minis.Hover 0, C.Offers.FinalBandPremium 6 + one line in C.OfferPool), PetConfig (egg prices), UpgradeConfig (28 World 2 prices), ActivityConfig (Snow1-3 goals 20K/7M/200M). Re-tuned once after an independent review (final variant tuned5h_f.json). All mirrored and hash-checked (written by outputs/Rebalance20261005/sim/emit5h.py). Backup: ServerStorage.FiveHourBackup_20261006 + outputs/FiveHour20261006/before. Report: outputs/FiveHour20261006/README.md.
51. Mini plows (2026-10-06; review fixes: closed loop path, per-stage snow height, placement inset, hidden on the arena island, admin reset clears levels; AfkDriftClient placement inset fixed too; WheelService/WheelConfig now mirrored in game/src): new MiniPlowService (server: MiniPlowRemote "Buy", payout once a second), new MiniPlowClient (MINIS button left of UPGRADES, panel, the little plows), PlowConfig C.Minis / C.MiniLevel / C.MiniBase. Profile field d.MiniPlows = {Level}. All mirrored. Backup: ServerStorage.MiniPlowsBackup_20261006 (PlowConfig before). Undo: delete the two scripts + ReplicatedStorage.MiniPlowRemote and restore PlowConfig.
50. Rebirths removed (2026-10-06, wiktor): moved into ServerStorage.RebirthsBackup_20261006.Moved (each has OrigPath): RebirthService, RebirthRules, RebirthConfig, RequestRebirth, RNGGui.RebirthClient, LeftMenu.RebirthButton, Panels.Rebirth, and the lobby pavilion's REBIRTH sign + prompt (the pavilion stays as decor, renamed CrystalPavilion). Edited (copies in .ScriptsBefore): DataService (no Rebirths leaderstat; old d.Rebirths kept), UpgradeService (no rebirth multiplier), WheelService + WheelConfig (Studio-only; same grant keys), ActivityConfig (Rebirth1/2 achievements out), PassConfig/PlowConfig text, LoadingScreen tip, PopupStack, FrostfallClient. Mirrored; removed sources archived in outputs/Rebirths20261006/removed.
49. Workbench removed, click your car to equip (2026-10-06): PlowGarageClient (an invisible CarClickBox with a ClickDetector over your own lift car opens the equip window; also an "Equip parts" prompt for keyboard/gamepad/touch and a "Click your car to equip" hint; neighbours' cars only open Inspect), PlowTutorialClient (the equip step points at YOUR CAR), PassConfig (text). All mirrored. The 10 workbench models were moved, not deleted, into ServerStorage.WorkbenchBackup_20261006.Moved (each has an OriginalParent attribute), and the old scripts are in the same backup. Undo: move each Moved/Workbench_* back to its OriginalParent and restore the 3 scripts.
48. Verity egg + pets redone (2026-10-06): PetConfig (Look.Orb on the 5 Verity pets; chances/boosts unchanged), PetModels (glowing emoji orbs, built ahead of PetModelOverrides), EggModels (yellow smiley Verity egg). All mirrored. Backup: ServerStorage.VerityEggBackup_20261006b. Undo: remove the Orb fields (animals return), or restore the 3 scripts from the backup.
47. Walls undone (2026-10-06, wiktor's request): Studio-only. workspace.HelpYardWalls (14 yards, 900 objects) and workspace.W2Edges (598 parts) moved, not deleted, into ServerStorage.WallsUndoBackup_20261006; each folder has OriginalParent=Workspace. Undo: drag both folders back into Workspace. W1Edges untouched.
46. Sound (2026-10-06): PlowConfig C.Sound (all volumes and ids), PlowDriveClient (engine and skid read C.Sound; idle engine 0.10 → 0.16), and new PlowSoundClient (snow crunch per payout incl. AFK, whoosh on big bursts, quiet engines on the 4 nearest other plows). All mirrored. Backup: ServerStorage.SoundBackup_20261006.
45. World 2 paths rebuilt (2026-10-06): Studio-only.
   - New workspace.World2.Paths20261006: 6 decks, 24 studs wide with 2.2 stud curbs and posts, in each old bridge's colours (rainbow stripes for Clockwork→Cloud), 1,211 parts.
   - The old 10-stud bridges moved to ServerStorage.W2PathsBackup_20261006.BridgesRemoved.
   - The 6 World 2 gates are scaled 1.8× (paywalls now 26–28 wide).
   - Invisible gate and west boundaries are cut to leave 26-stud gaps, including AtlantisWestS, which used to block the Candy→Atlantis bridge end.
   - W2Edges walls in the mouths are removed (58 pieces).
   - Backups: Bridges, Boundaries, Gates, W2Edges in W2PathsBackup_20261006.
   - Follow-up: 455 invisible SideCollider parts (2×24 studs, overlapping) on both deck sides, except inside the arrival island.
44. World 2 fog clears on unlock (2026-10-06): new StarterPlayerScripts.W2FogClient (mirrored). Each World2.CloudCurtains.MistBank_<A>To<B> fades out (2 s) when Stage_<B> unlocks and stays hidden on rejoin. Nothing else replaced; delete the script to undo. (Save point 43 was also updated with the fresh-snow-only cap: SnowFieldClient + PlowDriveClient.)
43. Speed scales with snow hardness (2026-10-06): PlowConfig (C.Drive.HardSnow), PlowService (hull ClearPower/Soft/Hard attributes), PlowDriveClient (on-field speed cap = speed where one pass breaks a layer, floor 25% of plowing speed). All mirrored. Backup: ServerStorage.HardSnowBackup_20261006.
42. AFK 70% + drift +50% + last three yard walls (2026-10-06):
   - PlowConfig (mirrored): C.Afk.Rate 0.70, C.Drive.Drift.SnowBonus 0.50. Backup: ServerStorage.AfkDrift70Backup_20261006.
   - Studio-only: 130 wall pieces added on the Cursed, Crystal and Desert yards where the side faces a drop or void; sides on walkable ground stay open.
   - The last W1Edges coplanar pairs are nudged.
41. Help Yard z-fighting fixed (2026-10-06): Studio-only.
   - Wall segments and snow caps had identical thickness and overlapped at every joint, so their faces shared a plane. Neighbours now get different thicknesses and base heights (±0.04–0.08 stud), and caps are sunk 0.06 into their own wall. 1,732 pieces in HelpYardWalls, W2Edges and W1Edges.Walls; 274 corner pieces nudged 0.06.
   - The Cursed, Crystal and Desert yard pads (TintGround mesh) were coplanar with the stage ground and are raised 0.05 (original Y kept as attribute ZFightOrigY).
   - Scan: 0 coplanar pairs on yards and World 2, 2 left in World 1.
   - Backup: ServerStorage.ZFightBackup_20261006.
40. World 2 walls checked by eye and fixed (2026-10-06): W2Edges trimmed to 323 segments.
   - Removed 52 standing on props (all of Sakura's first pass sat on blossom hills), 24 already covered by scenery, and 32 inside the Toybox (its toy-box sides are the wall).
   - Sakura rebuilt from GardenGround's edge: 52 segments plus 4 32-stud colliders.
   - First pass kept in ServerStorage.W2EdgeBackup_20261006.W2EdgesFirstPass.
39. Help Yard + World 2 walls (2026-10-06): Studio-only workspace.HelpYardWalls (all 14 yards: ~8 stud snow-capped walls in each yard's rock colour on the rim lines + 32-stud invisible colliders; gate/bridge gap kept) and workspace.W2Edges (382 wall segments on the real floor edge along World 2's existing 40-stud Boundaries: Toybox, Clockwork, Cloud, Cosmic, Candy, Atlantis, a little Sakura). Nothing existing changed; delete those two folders to undo (note in ServerStorage.W2EdgeBackup_20261006).
38. Garage island walls (2026-10-06): Studio-only, 67 ~8 stud snow-capped rock wall segments (GarageIsland attribute) on the front (z -358) and back (z -206) floor edges + east end, outside the tan bay fences, plus 292 invisible 32-stud colliders (taller because the garage's own 8-stud RimSouth/RimNorth let players climb). Open: overflow side x < -400, lobby junction, teleporter pad, arena portal. Backup: ServerStorage.W1EdgeBackup_20261006.GarageWallsBefore.
37. Props in snow fields go non-solid (2026-10-06): 205 parts CanCollide/CanQuery off (Starter 1 igloo, Retro 68, Sakura 4, Candy 30, Atlantis 38, Toybox 47, Cloud 4, Cosmic 13); CanTouch kept. Undo list: ServerStorage.PropGhostBackup_20261006 (ObjectValues + OldCollide/OldQuery), snippet in outputs/PropGhost20261006/ghost_props.luau.
35. AFK auto-plow (2026-10-06): new AfkService + AfkDriftClient, PlowConfig C.Afk, PlowDriveClient autopilot, SnowFieldService AFK payout, all mirrored. Backup: ServerStorage.DriftAfkBackup_20261006 (delete the two new scripts to undo).

**One Ctrl+S in Studio saves every item above.** Then publish only when you're ready: nothing was published by me.

Note: at about 15:30 the Studio MCP connection came back with a new id (c7cec63dâ€¦) holding the same place. It had reloaded a state from a little earlier, so I re-installed my last edits and checked them against disk. Everything listed above was present after that.

All scripts are mirrored in game/src, so scripts survive even without a save; Studio-only geometry (arena island, remaster scenery) is lost if Studio closes unsaved.

60. Egg toast outline + World 1 walls after World 2 (2026-10-09, Claude): PetClient (egg 'need X snow' toast outline fades) and StageClient (walls re-apply open state when they stream back in), mirrored. Backup: ServerStorage.EggToastTravelFix_20261009.
61. Part-roll reveal remake (2026-10-09, Claude): new ReplicatedStorage.PlowRollReveal; PlowGarageClient, PlowShopClient, PlowClientApi edited (merged into game/src). Backup: ServerStorage.RollRevealBackup_20261009. Details: outputs/RollReveal20261009/README.md.
62. Quick Rolls pass gate on the reveal skip (2026-10-09, Claude): PassConfig (QuickRolls perk, Id nil), PassService (checks perks), PlowRollReveal, PlowGarageClient; mirrored. Backup: ServerStorage.QuickRollsBackup_20261009. With Id nil nothing changes for players.
63. Livelier egg hatch (2026-10-09, Claude): StarterGui.RNGGui.PetClient hatch section only (drop-in, knocks with cracks and squash, hop, shell chips + rarity stars, bouncy pet with hop/spin, reduced-motion path). Snapshot refreshed. Backup: ServerStorage.EggHatchBackup_20261009.
64. Leaderboards (2026-10-09, Claude): new LeaderboardConfig, LeaderboardService, LeaderboardClient (mirrored) + Studio-only workspace.Leaderboards (3 boards in the hub's west gap). Details: outputs/Leaderboards20261009/README.md.
65. Garage ring around the lobby (2026-10-09, Claude): Studio-only workspace.HubRing, the 8 bays and 16 mountains moved, old garage island / 39 mountains / lobby west rim moved to ServerStorage.HubRingBackup_20261009 (undo: outputs/HubRing20261009/hub_ring.luau MODE "undo"); PlowService + PlowTutorialClient edited (mirrored; backup ServerStorage.HubRingScriptsBackup_20261009).
66. Open lobby, garages in clear view (2026-10-09, Claude): Studio-only. Pet Fuser + TravelPad east of the plaza by the snow yard; Crafting, arena portal, Crystal Pavilion in the back of three gaps between bays (2 mountains moved out); pines, rocks, mounds, lanterns, benches, string lights, snowmen and the frozen pond moved out of the bay lanes. Backup + undo: ServerStorage.HubOpenBackup_20261009, outputs/HubOpen20261009/hub_open.luau MODE "undo". No script changed.
67. Paths lead to the garages (2026-10-09 evening, Claude): Studio-only. The old trident ice walk (ContinuousIceWalk + ContinuousSnowBorder, in ServerStorage.HubPathsBackup_20261009.Removed) is replaced by FrostfallVillage.Walkways.SpokeIceWalk / SpokeSnowBorder: a path from the plaza to each of the 8 bays, a ring path in front of them, the spawn avenue, a snow-yard link and branches into the Crafting / portal / Pavilion gaps. Undo: outputs/HubOpen20261009/hub_paths.luau MODE "undo". No script changed.
68. Mountain wall around the hub (2026-10-10, Claude): Studio-only workspace.HubMountainWall, 29 copies of SnowyMountain (8 gap fillers, 13 ridge, 8 canyon walls along the west gap). East opening and the extra-garage street stay clear; nothing existing moved. Undo: outputs/HubOpen20261009/hub_mountains.luau MODE "undo" (folder -> ServerStorage.HubMountainWallBackup_20261010). No script changed.

69. Speed-run fix: buy toast (2026-10-10, Claude): StarterPlayerScripts.PlowShopClient, after BUY the toast said "Equip it at the WORKBENCH!" (no workbench since the click-the-car equip); now "Click your car to equip it!". Mirrored in game/src (that file already says it right). Backup: ServerStorage.SpeedRunFixBackup_20261010.PlowShopClient_before.
70. Speed-run fix: hub plaza rocks (2026-10-10, Claude): Studio-only. 13 W1Edges.Underside rock blocks poked up through the hub floor (one hid the left half of the FROSTFALL sign, others stood on paths near Bay 3/5 and the plaza). Each was lowered just under the floor. Undo: each part's attribute SpeedRunOrigCF (also listed as CFrameValues in ServerStorage.SpeedRunFixBackup_20261010.HubUndersideMoved); set CFrame back to it.
71. Ability tokens (2026-10-11, Claude): new ReplicatedStorage.AbilityConfig, ServerScriptService.AbilityService (ModuleScript), StarterPlayerScripts.AbilityTokenClient; SnowFieldService, PlowDriveClient, DigJuiceClient edited; 8 icons uploaded. Mirrored in game/src. Backup: ServerStorage.AbilityTokensBackup_20261011 (the 3 edited scripts). Off switch: ServerStorage attribute AbilityTokensOff = true. Details: outputs/AbilityTokens20261011/README.md.
72. World 2 new fields (2026-10-13, Claude): Studio-only. wiktor's 3 boxes moved from Workspace root into Workspace.SnowFieldZones as Candy_3, Candy_4, Clockwork_3 (position/size unchanged; OrigName attribute). Backup: ServerStorage.NewW2FieldsBackup_20261013. Undo: move back to Workspace, rename to OrigName.
73. Supporter Gift (2026-10-13, Claude): new ReplicatedStorage.CommunityRewardConfig, ServerScriptService.CommunityRewardService, StarterPlayerScripts.CommunityRewardClient; PetConfig (SupporterGift / Frosty Pal) and EggModels edited. Mirrored in game/src. Backup: ServerStorage.CommunityRewardBackup_20261013. Details: outputs/W2FieldsAndGroupGift20261013/README.md.
