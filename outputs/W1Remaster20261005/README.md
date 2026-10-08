# World 1 remaster (2026-10-05)

Every World 1 area was rebuilt with Blender packs from the shared pipeline (w2lib / partlib / w1lib). The old scenery is archived with placement info. Balance, fields, payouts, stage IDs, gates, prices, pets, eggs, treasures, rebirths, upgrades, the shared garage, contract yards, tutorial destinations and boss/event spots are unchanged. Nothing was published.

## Files
- `w1lib.py` holds the shared helpers. The biome modules are `desert.py`, `cursed.py`, `crystal.py`, `retro.py`, `jungle.py`, `az.py` and `frost.py`.
- Build: `blender -b --factory-startup -P build_w1.py -- --biome <module> [--tiles] [--export] [--save]`
- Upload: `upload_w1.py -- --packs W1_<Biome>`. This writes `uploads.json` and `manifest.json` (asset IDs and per-model slots).
- `fbx/` holds the exports, `renders/` the model sheets and `screenshots/` the Studio and Play captures.
- `W1RemasterKit.luau` (ServerStorage, Edit-time tooling only) has: postProcess, archive, place, collider, addColliders, footprint and replaceWall.
- `place_<biome>.luau` are the Studio Edit scripts that were run, kept in sync with the final state.

## Studio layout
- New scenery: `Workspace.W1Remaster.<Area>`, with Walls, Colliders and feature subfolders. Colliders are simple invisible boxes.
- Built templates: `ServerStorage.W1RemasterBuilt` (76 models). Raw imported packs: `ServerStorage.W1RemasterImports`.
- Backup: `ServerStorage.W1RemasterBackup_20261005.<Area>`. Every archived object carries OrigParent, OrigName, OrigPivot and ArchiveNote. `Scripts_before` holds StageDecorClient and the BiomeLighting Profiles as they were before this pass.
- Motion: StageDecorClient now also animates `Workspace.W1Remaster` (Bob, Sway, Orbit, Spin), and particle culling covers every root.

## Pack asset IDs
| Pack | Asset ID |
|---|---|
| W1_Desert | 96907718230310 |
| W1_Cursed | 80401928440380 |
| W1_Crystal | 125227580689852 |
| W1_Retro | 81138864154444 |
| W1_Jungle | 78329843452409 |
| W1_Az | 130525681033714 |
| W1_Frost | 127758437009490 |

## What changed per area
- **Desert**
  - 12 walls became sandstone cliff segments; 41 decor items archived.
  - New: SunGate, ziggurat, camp, oasis, ruins, obelisks, swaying palms, an orbiting hawk, and mesas/dunes in the background.
- **Cursed**
  - 11 walls became gothic wall segments; the chapel landmark fills one wall footprint.
  - 6 iron fences replaced; 263 decor items archived.
  - New: graves, pumpkins, smoking cottages, arch, dead trees, green lamps, bobbing ghosts, crags.
- **Crystal**
  - Floor recoloured (OrigColor attribute saved).
  - 10 walls became slate/crystal cliffs; 67 decor items archived.
  - New: the Crystal Heart (sparkles and light), a headframe with a spinning wheel, mining props and caves.
- **Retro** (snowy toy-brick arcade)
  - The old walls were replaced body by body: each kept WallBody became an exact collider, so the openings are unchanged.
  - Archived: the stray yaw-19 duplicate wall, both overlapping Classic House copies and the observatory hill. The arcade tower now stands in the hill's footprint, with the same blocked area.
  - Yard_Retro was unreachable before (the house and the duplicate wall blocked it) and is now reachable.
- **Jungle** (frozen temple ruins)
  - Walls were tiled, with one collider per tile at the old wall's average inner face. Blocked field area: Jungle_1 9.0% vs 9.7% before, Jungle_2 19.2% vs 18.6% before.
  - Closed the 36-stud hole in the south wall. Before, only a non-colliding waterfall covered it, and it opened onto a drop into the void.
  - New: temple with fireflies, idol, lane pillars, palms, bamboo, hibiscus, parrots, big trees in the background.
- **Absolute Zero + portal plaza**
  - The 512-part cliff ring became glacier cliff tiles; blocked field area 9.0% vs 8.2% before.
  - In place: frozen pine, two crystal towers, Heart Engine (spinning rings), research camp, beacons, guardians, aurora banners, ruins, penguins.
  - Kept as-is: AbsoluteZeroPortal, the VFX folder and the Entrance.
- **Frostfall**
  - The approved village was kept: machines, egg display, rebirth pavilion, snowglobe/mini snowplow display, walkways, string lights, travel CFrameValues, mountain meshes and the lobby decor meshes.
  - Swapped in place, with their old colliders kept: 9 pines, 8 lanterns, 4 benches, and the scout camp (campfire smoke), trail sign and sled.
  - Added a watchtower on the south peak.

## Checks
- Real, in Play: a starter plow drove into Yard_Retro (including through the plank gap), Yard_Jungle, Yard_AbsoluteZero, Yard_Desert, Yard_Cursed and Yard_Crystal. It also drove the Jungle lane.
- Real, in Play: a walk-path to the Retro yard; the BiomeLighting zone switches; 34 animated objects registered; 0 server and 0 client errors or warnings. Village prompts (13), travel CFrameValues, the egg display, spawn, portal and arena portals were all present.
- Simulated: 21-26-stud corridor boxes clear on every gate-field-yard lane, plus the field blocked-area comparisons above.
