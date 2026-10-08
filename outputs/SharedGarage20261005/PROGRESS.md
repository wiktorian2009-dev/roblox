# Shared Garage lobby models - progress

Status 2026-10-05: DONE. All 14 models are built, reviewed in renders, exported as 4 FBX packs and uploaded.

## Files
- `models.py`: one builder per model, using w2lib and partlib helpers. `build.py -- [--only A,B] [--export] [--tiles] [--lobby] [--save]` builds the models, prints stats and contract checks, exports `fbx/*.fbx`, writes renders and saves `SharedGarage.blend`. `scene.py` holds the render helpers and the lobby layout.
- `upload.py` uploads the packs, skipping any already listed in `uploads.json`. It also registers them and writes `manifest.json`. `--manifest-only` rewrites only the manifest.
- Renders: `renders/Models.png`, `Lobby_high.png`, `Lobby_eye.png`, `Lobby_eye2.png`, `Lobby_baylook.png`, and per-model images in `renders/tiles/`.

## Packs (assetIds)
Pack_Bay 84967579506297 | Pack_Island 75601364045847 | Pack_Landmarks 125402282474017 | Pack_Props 89063711027475

## Contract notes
- Bay floor top is at z=0. The paint (border lines, front hazard line, turntable ring r 7.8-8.3) sits at z -0.03..+0.02. The checks found nothing inside the clear zones between z 0.05 and 7.5.
- The bay side dividers are at x=+-15.8, not 15.6, because the reserve pedestal reaches x=15.6. The posts on the +X side are at y -11, 1.5 and 8, outside the pedestal.
- The street lamp is at (15, -13.6), not (15, 0). At y=0, the tile at x=-16 would put the lamp inside PlazaLandmark.
- The island snow top is at z=-0.05 and uses a superellipse with n=6, a=76, b=50. Rim drifts reach z 0.4, but only outside the bay rows. Rocks and crystals stick out up to about 2 studs past +-76/+-50, below z -2.
- The neon parts are named `LampBulb`, so the object names are `<Model>__LampBulb__FFE3A0NE`.
