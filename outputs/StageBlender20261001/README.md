# Blender scenery for every stage

Created in Blender 5.2.2 LTS, 2026-10-01. **Prepared assets, not yet installed in the game.**

44 textured meshes / 75,818 triangles across Starter, Desert, Cursed, Crystal, Retro, Jungle, Absolute Zero and Portal. Includes 25 new meshes plus 19 meshes reused from Claude's DesertLife pack, with its original files preserved. Main Blender source: `AllStages.blend`. Regenerator: `../../work/build-stage-blender-20261001.py`.

## Import once

1. Stop Play in Studio and use **File → Import 3D**.
2. Select `C:\Users\wikto\Desktop\Roblox Gra\outputs\StageBlender20261001\AllStages.fbx`.
3. Keep the separate meshes and textures enabled. Keep the imported root named **AllStages**. Import/upload it into the open `money` place.
4. Tell Codex the import is finished. Codex can check the imported dimensions, textures and facing direction, then place the scenery and test it.

The combined FBX is about 1.7 MB. Its palette texture is embedded; `LifeAtlas.png` is also beside it. Optional individual stage FBX files are included, but the combined file needs only one import. Do not import the old Props2026 or DesertLife files again for this pack.

Expected sizes in Studio: snowman **4.85 × 5.30 × 3.07 studs**, igloo **11.40 × 4.78 × 13.20**, arcade **4.40 × 6.70 × 4.25**. FBX export uses `global_scale=0.01`, following the scale correction already tested on the earlier props. Actual Studio importer settings still need checking.

## Placement and recovery

`placement-plan.json`: 56 composed placements, about 86,770 instanced triangles. The Portal halo is supplied as an extra mesh and is not placed over the existing gate. The approved Frostfall lobby is outside the plan.

`install-after-import.luau`: self-contained installer, **DRY_RUN=true**. It requires every imported mesh and texture, checks proportions, validates current field/gate bounds and ground support, then reports readiness. Codex should inspect mesh facing, remaining scenery overlaps and Jungle wall coverage before changing DRY_RUN to false. On commit it archives the current StageDecor20260930 in ServerStorage and preserves the imported mesh library. It does not change progression, publish the place or reset data. Existing Jungle wall-recovery records must remain recoverable.

## Evidence and remaining checks

- Eight rendered biome previews and an extra Desert landmarks preview inspected. Oasis water occlusion, pine snow caps and Jungle cliff shape corrected.
- `export-verification.json`: independent FBX re-import passed for all 44 names, dimensions in the baked Y-up basis, 75,818 triangles, UVs and loaded texture images.
- `layout-verification.json`: no planned footprint conflicts with fields enlarged by 2 studs or gates enlarged by 6 studs; includes allowances for planned movement and verifies ground coverage against the recorded live geometry.
- Installer template syntax compiled in a temporary client-only ModuleScript during the user's existing Play session. The temporary module was removed; installer body was not executed.
- **Pending:** Studio import, actual texture/scale/facing inspection, live placement preflight, screenshots of placed scenery, Jungle wall fit, isolated Play movement checks and device performance. No live scenery changed, saved or published by this task.

The previews show the models under Blender lighting. Roblox lighting will look different; final in-game placement remains to be checked.
