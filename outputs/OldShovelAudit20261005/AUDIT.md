# Old shovel system dependency audit — 2026-10-05

The active snowplow conversion is incomplete. The main field-clearing path uses vehicles correctly, but Rewards, the boss, some upgrades, equipment menus and the arrival cinematic still depend on legacy shovels.

This was a **read-only audit** of place **94130990350526 (money)**, Studio session **f765f9ae-69f1-4bbd-bcda-9462a0f440bb**. Studio was already in Play; this audit did not start or stop it. No game source, player data, assets or publishing were changed.

## Evidence and limits

- Graphify was queried first for navigation; live sources were then captured from the running Server datamodel.
- Screened **100 game-owned source instances** outside Roblox core scripts and archived backup code. **47** contain direct shovel, old-roll or mode references; indirect shared consumers were also checked. The inventories include two identically named Workspace.Script instances.
- Inventoried **134 archived/backup source instances** without rereading their code.
- Compared the running client's PlayerGui/PlayerScripts sources with their templates: no mismatch among comparable copies.
- Inspected current GUI visibility, player attributes, legacy asset containers, world displays and machine prompts.
- Re-read nine key live sources at the end: PlowService, RNGHandler, ActivityService, FrostKingService, UpgradeService, UpgradeConfig, PlowConfig, RNGClient and MachineService were unchanged from the captured versions.
- **No interaction tests** were performed: no purchases, rolls, equipping, boss joins, resets or rebirths. Saved Edit state, real persistence, multiplayer and publishing were not verified. Source-proven problems and test-needed risks are distinguished below.
- The existing test had BalanceTestMode=true and a player marked BalanceTestSession. These belong to the existing session and were left untouched.

Source paths and line numbers below refer to the captured live source text, not the one-line JSON container. Full captured sources are in sources-0.json, sources-1.json and sources-2.json; reference-hits.json lists matching lines.

## Problems affecting the active snowplow game

| Priority | System | Finding and player impact | Evidence |
|---|---|---|---|
| P1 | Rewards / rolls | Garage Roll and Reroll increment only Plow.Rolls. Rewards and the Rolls leaderboard still use TotalRolls. Roll quests and three roll achievements do not advance through normal snowplow play. Three quests are chosen from four templates, so 75% of fresh sets contain the unavailable Roll objective; every quest must be claimed before refresh. | PlowService:209–222, ActivityService:58,120–142,186–193,274–275, ActivityConfig:44–49,58–60, DataService:62, RNGHandler:79,101–102 |
| P1 | Frost King combat and rewards | Boss damage, attack reach and the estimated income used to clamp rewards still derive from EquippedShovels. Hits are awarded by proximity, without blade contact or plow power. The captured profile has hidden Tin equipped; improving engine/blade/gear will not improve its boss combat. Retained rare shovels give an unrelated advantage. Removing shovel equipment before conversion would cause zero DPS. | FrostKingService:46–71,87–112,192,571–573; FrostKingConfig:4–6,42,46 |
| P2 | Upgrade purchases | Twenty upgrade nodes are still sold for Snow although their effects are explicitly Legacy-only: another shovel slot, roll speed, double rolls and Golden/Rainbow rolls. They do not change garage offer cooldown or results. | UpgradeConfig:26,80–98; UpgradeService:77–93; PlowConfig:69–84; PlowService:213–218 |
| P2 | Discovery achievements | Discover 10/20 shovels still counts distinct bases in Counts. Purchased parts go into Plow.Parts. New players cannot earn these through the new loop; the current part catalog has only eight parts, so simply renaming the same thresholds is insufficient. | ActivityConfig:68–69; ActivityService:47–54,62; PlowService:241; StarterShovelRules:9–16 |
| P2 | Inventory / Index | Both menu buttons are visible. Index displays shovel mutation catalogs, and Inventory defaults to Shovels. EQUIP/unequip still edits real legacy equipment through EquipShovel; that equipment continues to affect the boss. These are active controls, rather than merely unused assets. Preserve the Pets tab when replacing them. | RNGClient:108–112,132–140,215–227,276–280,361–398; PetClient:30,90–104; RNGHandler:71–74,126–145; client-state.json |
| P2 | Intro / loading | The old falling-and-finding-Tin cinematic still runs in Snowplow mode, and loading tips advertise tapping dice for shovels. Runtime attributes confirm an approximately 7.91-second completed intro with Tin. StarterShovelRules also grants/equips Tin during data initialization. | SnowIntro:22–24; SnowIntroController:152,423–453; SnowIntroService:55–60; LoadingScreen:18,172–176; DataService:29,57 |
| P2 | Shovel Forge | The 3,000 Snow unlock and enabled world prompt still open a forge that consumes spare Counts and grants shovel mutations. Garage rolls cannot supply those ingredients. Existing profiles can still alter their hidden legacy gear, but this does not upgrade the vehicle. | UpgradeConfig:241; MachineConfig:5–10; MachineService:39–71,231–240; MachinesClient:160–187,361–367; object-state.json |

The twenty ineffective upgrade IDs are:

- S_Third
- R_Dice1, R_Dice2, R_Dice3, R_Hyper
- R_Dice4, R_Dice5, R_Triple
- R_Gold1 through R_Gold6
- R_Rain1 through R_Rain6

Historical ownership is deliberately preserved by PlowConfig. The issue is offering these effects for new purchases without a useful current-mode effect or clear mode policy.

## Related integration issues

| Priority | Finding | Evidence / qualification |
|---|---|---|
| P2 | Mapped damage, width and speed upgrades do not refresh an already spawned vehicle. | PlowService:152,184–187 computes and stores vehicle stats at spawn. UpgradeService changes player attributes but not the registry; SnowFieldService:142–158 uses the cached stats. Exiting and using DRIVE again recomputes them. Snow/pet payout multipliers are read live. Purchase while seated was not exercised. |
| P2 | Additional size tiles can promise width but add none after the x1.6 cap. | PlowConfig:65,78 caps SizeMult × ReachMult. UpgradeConfig:301–303 gives each World 1 size tile +0.08; the eighth already reaches 1.64. The ninth/tenth, and seven World 2 +0.06 size tiles for a maxed profile, then add zero blade width. The cap is intentional; sales/descriptions need to account for it. |
| P2, pre-existing placeholder | The 1M Snow Crafting Machine unlock has no production recipes. | UpgradeConfig:243; CraftingConfig:12–16 has only a disabled test example; MachineService:147–176 and MachinesClient:275,287–291 yield a coming-soon panel in normal play. Shovel crafting reward support remains dormant; no current production recipe calls it. The world Craft prompt remains enabled. |
| P3 | Admin commands still target the old tutorial/equipment model. | AdminService:104–113 gives Counts, not parts; :199–205 resets Settings.TutorialDone, not Plow.TutorialDone; :208–223 says reset ALL progress but leaves the Plow table intact. These commands were inspected, never executed. |
| P3 | Rebirth and damage helper text still refers to shovels. | RebirthClient:119,193 promises that shovels stay; LuckDisplay:59 says better shovels hit harder. Rebirth actually preserves the Plow table too, so the text needs to reflect current equipment. |

## Dependencies to handle carefully during cleanup

- **Intro completion handshake:** PlowTutorialClient:81 waits for IntroActive to become exactly false. SnowIntroService:19,55 is its only writer. Removing or disabling the intro without replacing this initialization/completion contract could strand the new tutorial. The current happy path completed; a failure-path stall was not reproduced. LoadingScreen:218 also waits for IntroPlaying/IntroReady, with a timeout.
- **Boss travel while driving:** FrostKing Join and knockout teleport the character without explicitly unseating/despawning the plow (FrostKingService:261–268,674–680). Jump and knockback still assume walking players. Test these while seated during the event conversion. RebirthService:55 also teleports the character and warrants a seated-plow check; no failure is claimed here.
- **Dice-counter startup ordering:** DiceMeter:73–76 can enable legacy Golden/Rainbow counters, but PlowShopClient:320–321 suppresses visibility when the holder already exists. Counters were hidden in the captured client. A late-created holder can miss that one-time lookup; this is a source-level race, not an observed visual bug.
- **Pets share Inventory:** Converting or hiding the whole Inventory would also remove valid pet controls unless they are preserved.
- **BottomBarFX owns shared Upgrades visuals:** It still animates hidden legacy dice/Auto controls, but also implements useful Upgrades and Hide behavior. Split its responsibilities before disabling it.
- **Existing quest starts use legacy counters:** A change to the Roll statistic must migrate saved quest Start values deliberately; simply switching to Plow.Rolls can misread existing progress.

## Already converted or safe to retain

| System | Current status |
|---|---|
| Field clearing | SnowFieldService:204–205 routes Snowplow mode directly to collectPlow. The old shovel-arm sweep is only reached by Legacy. No simultaneous shovel/vehicle clearing path was found. |
| Orbiting shovels | ShovelOrbit:3 exits immediately in Snowplow mode. |
| Old shovel rolls | RNGHandler:79 rejects RollRNG in Snowplow mode. GetInventory/EquipShovel remain active and are listed above. |
| Old tutorial | TutorialClient:3 exits; PlowTutorialClient uses the garage flow and Plow.TutorialDone. |
| Bottom Roll / Auto | PlowShopClient:316–318 hides the authored buttons and suppresses later visibility changes. Captured runtime confirms hidden Roll. |
| Snow, pets, combo and treasures | Shared payout and treasure hooks are reused by collectPlow. DigJuiceClient listens to generic SnowCollected values; its RNGConfig import is shared sound reuse. |
| Offer luck / boosts | PlowService:63 uses effective LuckMult, including upgrades, rebirth, boosts and already earned achievement bonuses. |
| Lucky Wheel, Cocoa, Pet Fuser, World 2 activities | These use Snow, stage rewards, shared boosts or pets; no retired shovel-equipment dependency was found in their active reward paths. |
| Rebirth | RebirthRules retains equipment/upgrades and resets Snow/stages. Plow parts/build/offers remain untouched; old shovel sanitization remains compatible with Legacy restoration. Source review does not prove real persistence. |
| Data / backups | Counts, Equipped, TotalRolls, the legacy starter and archives support the accepted Legacy rollback. Preserve them during conversion. |
| Rare shovel reel / announcements | RollController, RareDropCutscene and RareAnnounceClient remain, but the normal producer is behind the guarded legacy roll handler. Current part offers do not trigger these. Studio P preview still invokes the old rare-shovel cutscene. |
| Fast Rolls setting | Still edits the old reel preference; current garage reveals do not consume it. Low-priority UI cleanup. |
| SnowUI / ItemIcon / shared sound helpers | A shovel reference alone is not proof of a gameplay bug. SnowUI remains shared UI infrastructure; generic consumers should survive cleanup. |

## Legacy assets and world content

Confirmed runtime inventory:

- ReplicatedStorage.ShovelModels: **50 direct children**, **1,636 descendants**.
- ServerStorage.LegacyArchive_2026-10-04: **7 direct children**, **1,643 descendants**.
- Workspace.FrostfallVillage.Snowglobe.SpinningShovels still displays **Gold Shovel** and **Absolute Zero Shovel**, with SourceModel attributes referring to ShovelModels.
- Workspace.ShovelPreview contains **35 shovel models**.
- Workspace.FrostfallVillage.ShovelForge still displays SHOVEL FORGE and an enabled Forge shovels prompt.
- Workspace.FrostfallVillage.CraftingMachine has an enabled CRAFTING MACHINE prompt.
- ServerStorage.ShovelModelBuilder and the older UpgradePacingV1_StageLocks_2026-10-03.UpgradeConfig are stored helper/history modules, not automatically running server scripts.
- Old Remote/Bindable contracts remain: RollRNG, GetInventory, EquipShovel, RareRollAnnounce and GUI RollFinished/FastRolls. They are still wired to the legacy UI and event consumers.

These decorative models and backup containers are **not failures simply because they exist**. Replace active lobby branding/displays if desired, but retain recoverable originals. ShovelModels currently still serves the intro and rare-preview code; deleting it now is unsafe for those paths.

## Cleanup order

1. Fix garage Roll quest/achievement/leaderstat accounting, including saved quest starts.
2. Convert Frost King combat and reward scaling to the equipped plow; handle seated travel.
3. Define replacements for the twenty ineffective upgrade effects, obsolete shovel achievements and Forge unlock. Preserve prior ownership and Legacy data.
4. Convert Inventory/Index into current equipment/collections while preserving Pets.
5. Update the intro, loading and tutorial handshake together.
6. Refresh cached vehicle stats, account for capped width purchases and update remaining labels/settings.
7. Archive or replace active shovel displays and obsolete listeners after their consumers are converted.
8. Validate the resulting flow in an isolated test, then refresh Studio snapshots and Graphify after code changes.

No fixes, saving or publishing were performed by this audit. The next action is a scoped conversion, starting with Rewards and the boss.

