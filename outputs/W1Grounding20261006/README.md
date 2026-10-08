# World 1 grounded (2026-10-06, Claude)

wiktor: "Try to make player on first world that he isnt on some stupild levitating baseplates fields are most eye catching bc they have no walls". Done after his go-ahead ("go ahead: ground world 1, ...").

## What changed
- **Roblox Terrain under and around all of World 1:** the lobby, the garage, every field and every Help Yard (x −600…560, z −560…600; 4-stud voxels, written by WriteVoxels).
- **Every outer edge gets:**
  - a hidden shelf under the slab edge (no floating edge or underside shows);
  - a **low ~2–3 stud bank** in the stage's own material: snow (lobby, Starter, Retro), sand (Desert), slate (Cursed), glacier (Crystal, Absolute Zero), leafy grass (Jungle); deeper layers are rock / sandstone / basalt / ground;
  - then calm slopes down to a snowy valley and **low hills** in the distance. No tall walls, no glow.
- **Invisible colliders on the banks:** 730 `W1Grounding.Barriers` parts, 18 studs tall, CanQuery off. Nobody can drive or jump off an edge and go around the stage gates over the new ground.
- **Seams between slabs** are filled flush. **The garage overflow side** (west of x −449) is left low and open for the overflow bays.
- **Left alone:** the arena (in the sky) and World 2.

## Checks
- **Driving surfaces:** all 17,956 driving cells, plus 2,757 floor cells under arches and props (for example the Desert Sun Gate), have terrain at least 0.3 studs **below** the floor. No step was added to any driving surface, and the entrances, gates, Help Yards, garage junction and field tiles are unchanged.
  - The first build poked up to 5 studs through thin floors (smooth-terrain bulge). It was rebuilt lower and re-verified.
- **Colliders:**
  - None sits over a floor; rim cells with a real floor beneath are left open.
  - 108 rim cells stay open where a driving-height floor runs under the lobby's southern mountains, which block those spots themselves.
- **Play:** a character walked and jumped straight at 13 random outer edges and was **held at all 13**, ending on the bank about 7 studs out.

## Screens (`screens/`)
before_ / after_ pairs: wide1 and wide2 (aerial), plus lobby, Starter, Desert and Jungle at eye level. In the after shots, the Jungle Help Yard sits on jungle grass instead of floating, and the Desert edge is a dune.

## Not tested
- Driving a 20.8-stud blade through every entrance. Not needed by construction (driving surfaces are untouched and verified), but not done.
- Multiplayer and the phone view.
- From very high up, the terrain block's outer edge is a straight cut.

## Undo
- `ServerStorage.W1GroundingBackup_20261006.TerrainBefore`: the area was empty before, so clearing the terrain there restores it.
- Delete `workspace.W1Grounding`.
- Scan data: `ServerStorage.W1GroundingWork`.
