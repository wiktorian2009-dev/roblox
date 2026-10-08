# Props2026 - 3D props for the map (Blender -> Roblox)

Built 2026-09-30 with `prop_lib.py` + `props_<biome>.py` (Blender 5.2). **Status: all 7 sets imported into Studio on 2026-09-30 (Workspace.PropsLibrary2026, rescaled x0.01, anchored); NOT yet placed on the map; Claude did not save or publish the place.**

- One FBX per biome, props laid out in a row (16-20 studs apart), all sharing one colour atlas (`PropAtlas.png`, embedded in each FBX).
- Size: 1 Blender unit = 1 stud. Pivot = centre of the base (sits on the ground). Fronts face -Z in Roblox (= -Y in Blender). **Checked in Studio 2026-09-30:** rotation 0, pivot at the base, texture + colours fine. The first import came in 100x too big because Blender's FBX export writes centimetres; `export_fbx` now uses `global_scale=0.01` and all 7 FBX were re-exported (old ones kept in `_old_scale100x/`). The copies already in Studio were fixed with `Model:ScaleTo(0.01)`.
- Each `.blend` next to the FBX is the editable source. Re-generate everything by running the `props_*.py` builders from `prop_lib.py`.

## Import into Studio
1. In Studio: File > Import (or Asset Manager > Bulk Import), pick one `*Props.fbx`. Do NOT use the Creator Hub web upload panel - it rejects .fbx as 'Invalid file type'.
2. Import as one Model, keep the texture. Each prop becomes a MeshPart named like the table below.
3. Move the props you want out of the Model, set `Anchored = true`, and drop them on the map.

## Frostfall / Snowy - `SnowProps.fbx`

| Prop | Triangles | Size W x D x H (studs) |
|---|---:|---|
| SnowPine | 2480 | 8.7 x 9.2 x 14.5 |
| Snowman | 2026 | 8.6 x 5.0 x 10.3 |
| SnowMound | 2308 | 12.8 x 9.8 x 10.4 |
| IceRock | 430 | 10.0 x 6.1 x 5.2 |
| Present | 1172 | 4.9 x 4.7 x 5.5 |
| Penguin | 2398 | 5.4 x 3.9 x 6.5 |

## Desert - `DesertProps.fbx`

| Prop | Triangles | Size W x D x H (studs) |
|---|---:|---|
| Saguaro | 1342 | 8.5 x 5.4 x 12.1 |
| BarrelCactus | 1474 | 6.0 x 5.9 x 8.7 |
| PalmTree | 2260 | 13.9 x 13.8 x 15.5 |
| RockStack | 440 | 10.8 x 6.1 x 9.7 |
| SandstoneArch | 780 | 15.5 x 5.0 x 13.5 |
| StepPyramid | 486 | 14.0 x 14.0 x 12.4 |
| ClayVase | 836 | 7.2 x 6.3 x 8.6 |
| Tumbleweed | 2760 | 5.0 x 5.0 x 4.9 |
| Agave | 1364 | 13.1 x 12.9 x 2.9 |

## Cursed - `CursedProps.fbx`

| Prop | Triangles | Size W x D x H (studs) |
|---|---:|---|
| DeadTree | 788 | 9.2 x 6.0 x 14.6 |
| TombstoneRound | 744 | 5.4 x 3.1 x 6.6 |
| TombstoneCross | 844 | 4.7 x 3.4 x 6.3 |
| Pumpkin | 704 | 7.6 x 7.9 x 6.2 |
| Cauldron | 2146 | 10.1 x 7.6 x 6.7 |
| Ghost | 1292 | 7.7 x 5.7 x 6.3 |
| IronFence | 570 | 13.6 x 1.2 x 7.8 |
| Candles | 620 | 6.5 x 6.6 x 5.6 |

## Crystal Caves - `CrystalProps.fbx`

| Prop | Triangles | Size W x D x H (studs) |
|---|---:|---|
| CrystalClusterCyan | 230 | 10.1 x 8.6 x 12.2 |
| CrystalClusterPurple | 230 | 10.1 x 8.6 x 12.5 |
| CrystalClusterPink | 230 | 10.1 x 8.6 x 12.6 |
| CrystalSpire | 140 | 11.3 x 8.5 x 18.5 |
| GlowMushrooms | 1920 | 12.0 x 6.3 x 5.6 |
| Stalagmites | 420 | 9.6 x 8.3 x 11.9 |
| GemBoulder | 310 | 9.6 x 7.1 x 9.0 |
| CrystalArch | 160 | 16.4 x 5.4 x 13.1 |
| FloatingCrystal | 412 | 8.8 x 6.2 x 12.8 |

## Jungle - `JungleProps.fbx`

| Prop | Triangles | Size W x D x H (studs) |
|---|---:|---|
| BananaPlant | 1712 | 17.3 x 17.3 x 12.0 |
| GiantLeafPlant | 812 | 13.2 x 14.5 x 3.1 |
| Fern | 2140 | 13.0 x 12.9 x 6.4 |
| Toadstools | 1974 | 12.2 x 6.8 x 5.6 |
| HibiscusBush | 3048 | 9.4 x 8.1 x 6.4 |
| TikiTotem | 1376 | 5.8 x 6.0 x 12.6 |
| MossyBoulder | 780 | 10.1 x 6.8 x 5.8 |
| Bamboo | 4572 | 9.0 x 8.3 x 12.5 |
| LilyPad | 1780 | 9.2 x 9.1 x 2.0 |

## Retro World - `RetroProps.fbx`

| Prop | Triangles | Size W x D x H (studs) |
|---|---:|---|
| PixelHeart | 2392 | 12.0 x 2.0 x 11.5 |
| PixelStar | 1624 | 11.0 x 2.0 x 10.0 |
| PixelCoin | 2208 | 12.0 x 1.5 x 12.0 |
| PixelCloud | 1928 | 11.5 x 2.0 x 8.5 |
| PixelTree | 2136 | 11.0 x 2.0 x 12.0 |
| PixelAlien | 2304 | 10.0 x 2.0 x 12.0 |
| PixelGem | 1728 | 11.0 x 2.0 x 11.0 |
| PixelSun | 2272 | 12.0 x 1.5 x 11.0 |
| ArcadeCabinet | 732 | 6.4 x 6.4 x 12.6 |

## Absolute Zero - `AbsoluteZeroProps.fbx`

| Prop | Triangles | Size W x D x H (studs) |
|---|---:|---|
| IceSpikes | 378 | 11.8 x 9.6 x 13.2 |
| FrozenPine | 676 | 9.3 x 9.2 x 15.1 |
| IceBoulder | 100 | 10.9 x 7.1 x 5.8 |
| RuneObelisk | 398 | 7.4 x 7.4 x 19.2 |
| IceArch | 560 | 17.5 x 4.5 x 9.8 |
| FrostBush | 376 | 10.1 x 7.9 x 6.2 |
| FloatingShards | 116 | 10.0 x 8.1 x 14.0 |
| IceCube | 836 | 6.1 x 5.9 x 7.4 |

## Scale check (whole file as the Importer shows it, studs)
If the Importer's File Geometry panel shows roughly these numbers, 1 Blender unit = 1 stud is right. Wildly different (x0.01, x100, x3.6...) means the export scale needs fixing - tell Claude.

| File | Props | Width x Height x Depth |
|---|---:|---|
| SnowProps.fbx | 6 | ~87 x 16 x 10 |
| DesertProps.fbx | 9 | ~155 x 16 x 14 |
| CursedProps.fbx | 8 | ~134 x 15 x 8 |
| CrystalProps.fbx | 9 | ~154 x 18 x 9 |
| JungleProps.fbx | 9 | ~157 x 15 x 17 |
| RetroProps.fbx | 9 | ~121 x 13 x 6 |
| AbsoluteZeroProps.fbx | 8 | ~149 x 20 x 10 |
