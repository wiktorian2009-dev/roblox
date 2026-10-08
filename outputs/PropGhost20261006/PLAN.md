# Ghost props in snow fields: plan (read-only scan, 2026-10-06)

wiktor (relayed): "remove collisons for things like igloo and things that are in snow fields". I'll do it only after his own go line arrives.

## Scan (Edit, workspace.SnowFieldZones, 27 fields)
226 solid parts stand inside a field footprint, from floor+0.8 up to floor+25. By stage:

| World | Stage | Parts |
|---|---|---|
| World 1 | Starter | 1 (the igloo MeshPart at 56,9,-327, 34x17x30) |
| World 1 | Retro | 72 (5 bench/arcade "Model"s at z 286 + remaster colliders) |
| World 1 | Jungle | 7 |
| World 1 | Cursed | 2 |
| World 1 | Crystal | 2 |
| World 1 | Absolute Zero | 2 |
| World 2 | Sakura | 4 |
| World 2 | Candy | 30 |
| World 2 | Atlantis | 42 |
| World 2 | Toybox | 47 |
| World 2 | Cloud | 4 |
| World 2 | Cosmic | 13 |

The Starter igloo is what stopped my test plow at z about -325.

## Rule when it runs
- **Turn off CanCollide and CanQuery** on decorative props fully inside a field (at least 4 studs in from the field box edge). Turning off CanQuery too means the suspension raycasts in PlowDriveClient `ground()` can't climb onto them.
- **Keep CanTouch and prompts as they are**, so touch and prompt behaviour (pickups, treasure, Help-job targets) keeps working.
- **Keep solid:** anything named *Wall*, *Gate*, *Paywall*, *Collider* that touches the field edge, W1Edges, ContractYards, the garage, the arena, travel, floors, and anything reaching the field boundary (props that keep the plow inside a field).
- **Record:** each part's full path and its old CanCollide/CanQuery in ServerStorage.PropGhostBackup_20261006 (a StringValue list), with an undo snippet.
- **Test:** drive through the Starter igloo and a World 2 rock or block.
