# World 1 bug sweep — 2026-10-14, Claude (save point 77)

wiktor: "world 1 is having a lot of bugs like. eagle with one wing, holes in map, being able to jump of map, glitched collision etc go look over that".
All changes are **Studio-only** (Edit; no script changed). Not saved or published by me.

## How it was checked
- `w1_scan.luau` (this folder): a walk/jump scan of all of World 1 on a 2-stud grid. It starts from the spawn, every TRAVEL point,
  every Help Yard pad and every field, and follows what a player can do on foot (walk, step up, jump up to 7.2 studs high, running
  jump over gaps up to 8 studs, stand on decor tops, collidable parts count even with CanQuery off). It lists every reachable spot
  next to open void or the area under the map that no collider blocks. Run it in Edit with execute_luau; it only casts rays.
- A second scan looked for visible parts with no collision that a player can stand inside at body height, and for invisible
  colliders in open ground with nothing visible inside them.

## Found and fixed
1. **Eagle with one wing** (workspace.W1Remaster.Desert.D_Hawk). Cause: the 2026-10-05 Blender builder made each wing and the tail
   from one quad plus the same quad reversed; bmesh refuses the second face (partlib.mesh swallows the error), so every wing was a
   single-sided face and the mirrored wing faced the other way: from below you saw one wing, from above the other.
   Fix: `hawk_fix.py` rebuilds the wings and tail as thin closed slabs (same outline, colours, size); uploaded as asset
   96713600068730 and swapped into the live hawk (orbit attributes kept). Checked in Play from below and above: both wings and the
   tail show (screens/hawk_from_below.jpg, hawk_from_above.jpg). No other builder uses that pattern (grep of outputs/*.py).
2. **Being able to walk/jump off the map** — 19 open edges (Desert south edge; where Cursed, Crystal, Retro, Jungle and Desert meet
   their Help Yards; the Starter yard bridge sides; one hub mountain slope; a few single spots).
   Fix: 41 invisible walls (workspace.W1Edges.EdgeFix20261014.Walls, CanCollide on, CanQuery/CanTouch off, from 6 below the floor
   to y 200 so nobody can jump over them from decor) and 2 floor fillers in the cracks between Cursed and the Cursed yard
   (EdgeFix20261014.Fillers, Cursed ground colour/material). No visible walls were added.
3. **Glitched collision** — visible walls and rocks you could walk 4-6 studs into: Retro brick walls (20 parts), Absolute Zero
   glacier walls (15), Jungle walls (13), Jungle temple tiers (4), Cursed walls (4) and crag (1), Crystal walls (3) + the 3 loose
   Crystal X_WallSeg pieces, Desert walls/dunes/sun-gate cart (5), the Frostfall scout igloo (2), Retro house door (1) and the
   snow globe's inner snow (1) — 72 parts now collide (MeshParts use Hull). Parts that overlap a snow field were left alone (19)
   so no field tiles become unreachable; the Desert background mesas were left alone (making them solid let players climb them).
   Each changed part has attributes CollisionFix20261014 / CollisionFixOrigCanCollide / CollisionFixOrigFidelity.
4. **Invisible wall**: Retro's R_PixelHeartCollider stood in open ground with no pixel heart visual (the visual is not in Workspace).
   Moved to ServerStorage.W1BugFixBackup_20261014 (OrigParent attribute).

## Tests (Studio Play, BalanceTestMode, temp profile, PC, all World 1 stages unlocked on the temp profile)
- Scan after the fix: 0 leak spots; spawn still reaches every TRAVEL point, yard pad and field (69,862 reachable spots).
- Walk test at all 19 former leak spots (walk + jump toward the void for 2.6 s): no falls, stopped about 1.5 studs from the edge.
  Control: the same test at the Desert south edge with the new walls switched off on the client fell to y -513.
- Walk-into tests: Retro bricks, a Crystal rock, a glacier, a Jungle wall block and the snow globe stop the player outside; dunes,
  the crag and the igloo are now climbed over instead of walked through.
- No game errors in the console.

## Found, not changed (say if you want these done)
- Sinking: the Help Yard pads and bridges show their snow ~1.4 studs above the floor you stand on, garage bays ~1 stud
  (screens/yard_pad_sinking.jpg). Raising the floors changes where plows and yard jobs sit, so it needs a yard-job test first.
- Walk-through but probably fine: Frostfall pine foliage, presents, penguins; 19 wall pieces that overlap snow fields.
- Some faceted underside rocks poke 0.4-3.6 studs above the floor at stage seams (Jungle/Absolute Zero x~-190, AZ x~-310,
  Starter/Desert x~78). Lowering them could open visible cracks, so they were left.
- A loose Toolbox glass mesh (Workspace.MeshPart, asset 5525454390, 34x17x30 at (56, 8.5, -327)) sits on the Starter field with no
  collision; unknown purpose, left alone.

## Undo
- Edges: delete workspace.W1Edges.EdgeFix20261014.
- Collision: for every part with attribute CollisionFix20261014, set CanCollide = CollisionFixOrigCanCollide and CollisionFidelity =
  CollisionFixOrigFidelity, then clear the three attributes.
- Hawk: move ServerStorage.W1BugFixBackup_20261014.Wing_old / Tail_old back into the D_Hawk model (rename to Wing / Tail) and
  delete the new Wing / Tail.
- Pixel heart collider: move it back to its OrigParent.
