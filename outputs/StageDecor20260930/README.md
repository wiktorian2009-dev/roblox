# Stage decoration review — 2026-09-30

Installed in Studio Edit place money (94130990350526), Workspace.StageDecor20260930, ArtVersion 5. Not saved or published by this task.

stage-decor-preview-grid.png compares all eight stages. Individual PNGs show representative new scenery in Play; DesertRuins.png shows the final ruins placement previewed before the same transform was committed in Edit.

validation.json describes final Edit geometry: 28 scenes, 503 parts; no field or gate intersections, no invalid physics flags, and support under every scene. scene-snapshot.json inventories the final scene transforms. runtime-check.json records animation/culling and texture checks in isolated Play; the animation source remained unchanged during later placement polish. cleanup.json records the final backup, GUI/camera restoration and disk/live source equality.

Canonical client: game/src/StarterPlayer/StarterPlayerScripts/StageDecorClient.client.luau. Final recoverable art clone: ServerStorage.StageDecor20260930_ArtBackup. Before removing new art, restore the 37 original wall-part transparencies from ServerStorage.StageDecor20260930_WallRecovery records. See STATUS.md for recovery and limitations.
