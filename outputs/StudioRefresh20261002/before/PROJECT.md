# Roblox game — shared project brief

## Identity and working location

- Roblox Studio place: `money`, place ID **94130990350526**.
- Working folder: `C:\Users\wikto\Desktop\Roblox Gra`.
- The actual game is in Studio. This folder holds notes, builders and selected sources in game/, not a full game export. See the Rojo section below for sync limits. Claude and Codex conversation histories do not synchronize.
- Read STATUS.md for the latest state and blockers. It supersedes historical task reports.

## Accepted direction

A bright, cartoony snow-digging/RNG simulator for kids and teens. Roll shovels, collect Snow, buy upgrades, collect pets, unlock biomes and rebirth. Use readable silhouettes, colorful landmarks, playful feedback and varied activities. Extend the experience through meaningful progression and discovery, rather than simply slower grinding.

- Target for a new player without paid boosts: approximately **3–5 hours of active play to reach Absolute Zero**. This is a design target; the original simulation predates rebirths and is not a measured human playthrough.
- Art: chunky, rounded, simple attractive 3D models; snowy ground, icy blue shadows and warm hut lighting.
- Stage decorations: user requested **Blender models across all eight stages**, 2026-10-01. Latest prepared pack is `outputs/StageBlender20261001/AllStages.fbx` with editable AllStages.blend and a measured placement plan. Import/placement is pending; it reuses the 19 warm DesertLife models and adds 25 models for the biome scenes. Preserve the approved lobby and recoverable original scenery. See the latest STATUS.md entry before installing.
- GUI: only the floating egg/chances panel should have a transparent outer background. Preserve the rest of the existing UI unless requested.
- User approved **Frostfall Village**, then explicitly asked to replace the old lobby with it. Do not restore the comparison gate/old lobby as the active design. Keep the archived old assets recoverable.
- User disliked the earlier egg redesign. Do not treat those eggs as approved or silently reinstall them. New Blender biome eggs now replace that earlier design in FrostfallVillage.EggDisplay; see STATUS.md for current configuration and tests.
- User wants real in-game implementations, not just prompts or promises.

## Current systems and important files

| Area | Installed behavior / where to inspect |
|---|---|
| Progression | Upgrades across Snow, Rolls and Misc (UpgradeConfig currently defines 86 tiles: Snow 26, Rolls 25, Misc 35; older notes said 105); explicit prices and stage locks. `UpgradeConfig`, `Balance`, `StageConfig` in ReplicatedStorage. Details: `outputs/Balance-notes.md`. |
| Rebirth | Permanent +0.50 Snow multiplier and +0.25 luck per rebirth, additive growth, 50 cap. Resets Snow/stages/upgrades; keeps owned pets/shovels/discoveries. `RebirthConfig`, ServerScriptService `RebirthService`/`RebirthRules`. Details: `outputs/Rebirth-notes.md`. |
| Pets/eggs | Shared procedural pet models in `PetModels`; `PetConfig`, `PetService`, `PetClient`, `EggModels`. Hatching requires a world Model named for an EggById entry. Seven Blender egg meshes now form the lobby display; Snowy/Desert/Cursed/Crystal are configured for hatching, Retro/Jungle/AbsoluteZero remain coming soon. EggFloat animates shells/VFX; PetClient clones Shell for hatch previews and shows nearest odds panel. Earlier procedural models remain fallback/recovery. |
| Snow fields | Edit-time boxes in Workspace.SnowFieldZones become replicated `SnowFieldData` when Play starts; zones are removed at runtime. `SnowFields`, `SnowFieldService`, `SnowFieldClient`. |
| Buried Treasures | Fully dug tiles roll 1/100 for a biome treasure (5 rarities, 7 sets x 5 items); Snow bonus about 6% of digging income; first find guaranteed; collection survives rebirth. `TreasureConfig`, `TreasureModels` (RS), `TreasureService` (SSS, hooked from SnowFieldService), StarterGui `TreasureReveal`/`TreasureBook`, LeftMenu.Treasures + Panels.Treasures. Added 2026-10-01 (Claude). |
| Intro | 7.9 s storyboard cinematic in the lobby: sky fall, snow landing, shovel discovery, grab, two-handed overhead victory, shovel close-up, seamless handoff to the gameplay camera. `SnowIntroController` + `SnowIntroRig` + `SnowIntroArt` (ReplicatedStorage), `SnowIntro` bootstrap, `SnowIntroService` (server; Tin Shovel grant stays in `StarterShovelRules`/`DataService`). Camera on the west side of `FrostfallVillage.IntroOrigin`. Once per join; Skip supported; Studio I replay (HoldAt scrub for debugging). A snowy `ReplicatedFirst.LoadingScreen` covers the join and fades out as the cinematic starts (Studio-only until ReplicatedFirst is mapped in Rojo). |
| Tutorial | `StarterPlayer.StarterPlayerScripts.TutorialClient`; roll, collect 10 Snow, open upgrades. Now prefers FrostfallSnowYard. |
| Lobby | Workspace.FrostfallVillage; `FrostfallClient`, `FrostfallTravel`; `RNGGui.VillageOpenMenu` opens existing menus. Main-lobby origin (-105, 0.24, -282), facing east into the original field. |
| Upgrades UI | `StarterGui.RNGGui.UpgradeTreeClient` (Studio-only, v2 2026-10-01, user-requested): one page, all trees on one hex map (LAYOUT rotations/offsets in the script), yellow hubs + SNOW/ROLLS/MISC buttons with red badges, reveal = owned + attached + "?" ring, one tap buys, flashing green = can buy, flashing red = can't, toned blue = owned. ScreenGui name UpgradeTreeGui is used by TutorialClient. Old version: ServerStorage.UpgradeTreeClient_Backup20261001. |
| Roll sound | Studio-only StarterGui.RNGGui.RollController: crisp prize-wheel clicks (existing asset 12221976, EQ, default volume 0.32), pitch follows reel speed and RollAnimScale/FastRolls, deeper landing click, 55% volume in mini mode. RollTickVolume / RollTickOff control both sounds; rare cutscenes suppress this layer. Read-only Graphify snapshot in game/studio-snapshots/StarterGui/RNGGui/RollController.client.luau. |
| Stage scenery | Workspace.StageDecor20260930: 28 themed scenes across all eight stages. StageDecorClient animates only nearby props and culls particles; motion kinds (attribute StageDecorMotion): default bob, Water, Sway, Orbit, Roll (MotionAmount/Speed/Phase/Radius). Preserve field/gate clearance and the wall-recovery records described in STATUS.md. |
| Map props (3D) | 58 cartoony low-poly props for all 7 biomes, made in Blender with a shared colour atlas (real 3D meshes, not flat decals - user decision). Source/exports: `outputs/Props2026/` (`<Biome>Props.fbx` + `.blend`, `INDEX.md` with stud sizes, `manifest.json`; regenerate with `prop_lib.py` + `props_<biome>.py`). Imported into Studio 2026-09-30: `Workspace.PropsLibrary2026` holds 7 anchored Models (one per biome), staged in the sky near (-98, 1861, 0..240); clone props from there. FBX exports must use `global_scale=0.01` (first import was 100x too big). **Desert (2026-10-01):** the pastel library props and the part-built canyon were both rejected (archived in ServerStorage); the user also cleared most older Desert decor. Direction now: a living desert from the Blender pack `outputs/DesertLife2026/` (warm saturated palette, smooth shapes, plants + animals), placed under StageDecor20260930.Desert so it can move. Lesson: match the warm sandstone style; avoid the icy-tinted Props2026 atlas for warm biomes. Other six biomes not yet placed. Grouped originals live in `ServerStorage.PropsLibrary2026`; the 58 props as separate placeable models are on the Studio-only shelf `Workspace.PropPalette` (north of the Desert, removed at runtime by its RemoveAtRuntime script). |

Frostfall includes upgrade workshop, pet lodge, shop, rebirth pavilion, interactive snow globe, starter snow yard and the Frost Hop jumping route. The original leaderboard was relocated into it. The old lobby is archived in **ServerStorage.OldLobbyBackup**, with parent references and before-change snapshots.

## Practical conventions

- Inspect the connected Studio and its current scripts; another assistant or the user may have changed them.
- Workspace contains duplicate folder names such as GeneratedMap. Do not assume a dot path uniquely identifies a map object.
- Preserve server validation for currency, purchases, hatching, stages and rebirths. Preserve existing ownership and upgrade IDs.
- Test-mode attribute: `ServerStorage.BalanceTestMode`. It isolates the main progression profile only in Studio; remove it in Edit after testing.
- Plugin-executed module requires can have different caches from game Scripts. For tests that must seed the actual running DataService, use a temporary server Script in an isolated Play session and remove it afterward.
- Most visual/task source snapshots are under `outputs/`; scratch builders are under `work/`. Old installation scripts are not safe to blindly rerun over a modified place.
- Changes being visible in Studio does not prove the place was saved or published. State those separately.


## Rojo source location

Use `C:\Users\wikto\Desktop\Roblox Gra\game` as the canonical source folder. Its default.project.json maps ReplicatedStorage, ServerScriptService and StarterPlayerScripts; StarterGui, Workspace, ServerStorage and ReplicatedFirst are not mapped. Verify each affected live source before edits and after delivery; do not assume Studio edits sync back.

Earlier SnowIntroController file edits reached Studio automatically from this shared folder, but the new StageDecorClient file required manual installation on 2026-09-30. An old success is not proof of a current Rojo connection or new-file syncing. The Documents ca/game copy is historical; consult the latest STATUS.md before changing synchronization.

## Code navigation with Graphify
Graphify is installed locally, with project-scoped Codex and Claude Code skills. Query graphify-out/graph.json for relevant code before reading full sources. Scan scope is game/ only; run Refresh-Graph.ps1 to refresh. The graph excludes binary models and Studio-only objects and is not a substitute for live verification.


## Studio-only egg source snapshots
Graphify also indexes game/studio-snapshots/: EggDisplay/EggFloat and StarterGui/RNGGui/PetClient, captured from Play/Server on 2026-09-30. These are read-only reference copies outside the Rojo mapping. Verify and refresh them from Studio after egg UI/VFX script changes; Refresh-Graph.ps1 only rebuilds from disk. Binary meshes are not mapped by Graphify.


Lobby geometry repair: all three cabins have closed rear gables; walkways use continuous joined ice geometry. Snowglobe displays clones of the existing Gold Shovel and Absolute Zero Shovel with the original spin behavior. Recovery details are in STATUS.md.


Intro direction: camera-led seven-second arrival in the real Frostfall lobby. Sweeping descent, shovel close-up, hero arc and rising gameplay handoff; reduced character flailing, no temporary scenery/sky swap or face overlay. Skip and Studio I replay retained.


Starter shovel: intro uses the existing Tin Shovel model (least rare RNGConfig item). Server grants one per profile when first eligible, preserves existing copies and better equipment, and records StarterShovelGranted. Client animation completion must not grant another copy.
