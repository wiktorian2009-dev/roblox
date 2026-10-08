# Plow parts (90) - progress

Status 2026-10-05: DONE. All 90 models are built, reviewed, exported and uploaded.

## Files
- `partlib.py` (shared helpers: shell/blade panels, belts+cleats, tyres/knobs, fans, crystals), `blades.py`, `engines.py`, `gears.py` (one function per model).
- `build_all.py -- [--slots ..] [--only A,B] [--export] [--save] [--tag all]` builds, prints stats, exports `fbx/*.fbx` and saves `PlowParts90.blend` (+ chassis at y=+40).
- `render_sheets.py -- --slots .. --sheets --vehicles --fit --onchassis` makes renders in `renders/`.
- `upload_packs.py` uploads packs (skips ones already in `uploads.json`), registers them, writes `manifest.json`. `--manifest-only` rewrites the manifest.
- `verify_fbx.py` re-imports each pack and checks the Ref marker.

## Packs (assetIds)
Blades_A 113886673574521 | Blades_B 76191038681438 | Engines_A 113757628902695 | Engines_B 102682517293372 | Gears_A 80361867210661 | Gears_B 88481009438593

## Contract notes
- Chassis markers match the brief: AttachBlade (0,-4.30,1.145), AttachEngine (0,3.0,2.595), SeatPos (0,0.95,3.25).
- Fenders (|x| 2.22-3.0, z 2.0-2.3, y -3.57..-1.0 and 1.22..3.79) sit over the wheels, so tyre/track tops are kept at or below 1.97 (not 2.8/3.1). Wheel centres are at y -2.3 / +2.5.
- The seat back (y 1.5-2.4, z up to 3.95) and roll bar (y 2.35-2.65) limit the engine footprint to local y >= -0.5, not -1.25. Engines use y -0.5..+1.4.

## Fixes made during review
- Tris over budget (scoops, Coral, Cumulus, Lollipop, Vine, CaneCrusher, Chunky/Mudder knobs, Gummy cleats, CloudPuff): cut segment counts and dropped knob bevels.
- Pieces under the ground (Cog end plates, Tusk) moved up, and a z-clamp added (blade -1.1, engine 0.05, gear 0).
- Round engines (Snowball, Reactor, ZeroCore, Bubble, Nebula, Leviathan) reached the seat back. They were squashed in Y or moved back.
- Rare/Uncommon engines taller than 3.4 (Pocketwatch, Bubble, 8Bit, Power) were lowered.
- Gears outside |x| 3.6 or y -3.8..3.9 were pulled in. Wide tracks now use xc 3.07, track end wheels y -2.95/+3.05, and big tyres xc 3.05.
- Bamboo tyre was a solid disc that hid its spokes, so it is now a torus. Hover pods and storm pods were made longer to read better. A Leviathan front fin that looked like a star was removed.
- Ref marker names had `.001` suffixes in the FBX. Each marker is now deleted after its export.
- Engine sheet uses a 3/4 REAR camera, because the gameplay camera sits behind the vehicle.
