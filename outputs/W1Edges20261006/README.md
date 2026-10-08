# World 1 field edges, Help Yard style (2026-10-06, Claude) - save point 31

wiktor: "we have misunderstanging i didnt want terrain i just wanted to not gave edges like it was with help yards". He asked for this himself: "install the DataService fix, remove the World 1 grounding terrain and colliders, and build Help-Yard-style edges on the World 1 fields".

## Removed (the World 1 grounding from save point 27)
- **All grounding terrain** in x -600..564, z -560..604, y -64..44: valley, hills, banks and shelves. A sampled re-read finds 0 terrain voxels left.
- **workspace.W1Grounding** (730 invisible barriers). It is moved, not deleted.
- **Backup:** `ServerStorage.W1EdgeBackup_20261006`:
  - `GroundingTerrain` (a TerrainRegion; paste it at voxel corner -150,-16,-140 to restore);
  - `W1Grounding`;
  - `EdgeCells` / `EdgeRefined` (the edge scan).
- `ServerStorage.W1GroundingWork` is kept, as asked.

## Added: `workspace.W1Edges` (Studio-only)
This copies the Help Yard pads: a bumpy snow rim on top, a tapered faceted rock underside below, and invisible rim colliders.
- **SnowRim:** 916 white snowballs (about 1.7-2.3 studs), set just outside the floor edge, as on the yard pads. They are visual only (CanCollide/CanQuery/CanTouch off).
- **RockUnderside:** 308 flipped WedgeParts (SmoothPlastic). Their flat tops sit under the floor edge and they taper inward 8-16 studs down. Each stage uses its own Help Yard rock/curb colour:
  - Starter and lobby: 127,146,172
  - Desert: 192,138,82
  - Cursed: 58,47,77
  - Crystal: 106,143,194
  - Retro: 107,122,134
  - Jungle: 108,98,72
  - Absolute Zero: 94,127,168
- **Colliders:** 931 invisible 2-stud pieces. Each one's inner face sits 0.2 studs past the local floor edge, found by raycast.
  - They are **16 studs tall**. The yards' 8-stud rims are jumpable: in Play, a character jumping at an 8-stud collider got over it at 15 of 15 edges.
- **Where edges go:** only where a driving floor meets open air, in 52 straight runs. Edges against walls, mountains or props get nothing.
- **Left alone:** the Help Yard pads (they already have their own edge), the garage and its overflow side (x < -400, z -372..-192), floor tops above y 6 (garage roof, portal, castle tops), thin seams between slabs, the arena, World 2, the stage gates, Help Yard gates and the garage junction.

## Checks
- **No collider stands on a driving surface.** 0 floor hits across the whole footprint of every collider. Four corner pieces that touched floor were removed, and nothing visual sits on a floor, so no step was added to any driving surface.
- **Play:** a character walked and jumped straight at 16 random edges in 8 stages and was held at all 16.
- **Not done: driving the widest blade through the entrances.** Entrances are floor-to-floor, so no edge part is anywhere near them (shown by the floor-hit check above), but I didn't drive it.
- **Screens** (`screens/`): before_ (still with the grounding terrain) and after_ shots of the lobby, Starter, Desert and Jungle at eye level, plus wide2, the Desert edge from outside and the Cursed edge at eye level. `helpyard_reference.jpg` shows the Help Yard edge this copies. The pre-grounding look is in outputs/W1Grounding20261006/screens/before_*.

## Undo
- Delete `workspace.W1Edges`.
- To bring the grounding back: move `W1EdgeBackup_20261006.W1Grounding` to workspace, then `workspace.Terrain:PasteRegion(GroundingTerrain, Vector3int16.new(-150,-16,-140), true)`.
