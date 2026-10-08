# Pet rebuild (70 base pets) - progress

Owner: Claude pet agent, 2026-10-05. Headless Blender 5.2 only.

## Files
- `petkit.py` shared helpers (heads/face surfaces, eyes+highlights, mouths, ears, tails, wings, voxels, finish/size-fit, auto segment budget).
- `sp_01_snowy.py` .. `sp_14_star.py` one builder per species (14 eggs x 5).
- `build_pets.py` driver: `blender -b --factory-startup -P build_pets.py -- --eggs all|EggA,EggB [--export] [--render] [--labels] [--check] [--sheets] [--blend] [--review KeyA,KeyB]`.
- `render.py` EEVEE tiles + numpy sheet compositing. Tiles in `renders/tiles`, sheets in `renders/`.
- `upload_packs.py` Open Cloud upload + registry + manifest merge.
- Data per egg: `data/<Egg>.json`; packs: `packs/<Egg>_Pets.fbx`.

## Status
- [x] All 70 builders written (batches: Snowy; Desert+Cursed; Crystal/Retro/Jungle/AbsZero; Blossom..Star).
- [x] Renders reviewed per egg + all/small/golden sheets.
- [x] Final export (14 packs, pets at x = 9,18,27,36,45, y=0; marker Ref__Origin__FF00FFNE at origin) + Pets70.blend (egg rows offset y = -10*eggIndex in the .blend only).
- [x] Uploaded 14 packs (uploads.json), appended to asset-registry.json, manifest.json written.
- Tris 312-2442 (avg 1870), max 12 objects. Re-run order: build_pets.py --eggs all --render --check --sheets; --export --blend; upload_packs.py (skips done eggs).

| Egg | assetId |
|---|---|
| SnowyEgg | 72896385049601 |
| DesertEgg | 108642483231678 |
| CursedEgg | 133076257142856 |
| CrystalEgg | 82955266460049 |
| RetroEgg | 74949829376188 |
| JungleEgg | 97099306132342 |
| AbsoluteZeroEgg | 81129343932213 |
| BlossomEgg | 131801273184158 |
| CandyEgg | 129457469997966 |
| PearlEgg | 96615302680441 |
| ToyCapsuleEgg | 75292382371106 |
| GearEgg | 84035752246571 |
| CloudEgg | 106087890776138 |
| StarEgg | 81890738983246 |

## Fix log
- Batch 1: labels rendered edge-on (text not rotated) -> fixed; hard facets on tube legs -> sharp angle 80 deg for organic parts; tri counts 2.2-3.6k -> segment reductions + automatic seg-scale retry (1.0/0.86/0.74/0.64/0.55) until <= 2450 tris.
- Previous eggs stayed visible in later renders -> hide after rendering.
- Camel humps hidden behind head -> head/neck moved forward, humps taller.
- Gem Slime glow core showed as a bruise behind the eye -> core moved low/back.
- Crystal Golem face plate buried in rock head -> pushed forward.
- Tiki Guardian looked grumpy (open mouth read as moustache) -> smile + tusks, softer brows.
- Frost Sprite wings invisible -> tinted ice-blue; Mammoth disc ears -> tucked ears; Phoenix on stilts -> shorter legs, longer plumes, bigger wings.
- Steam Pup / Comet Pup ears stuck out like wings -> hanging floppy ears.
- Blossom Dragon read as a plain pink coil -> chunkier body, white spiky mane along spine + head ruff, crown blossoms, tail blossom fan.
- Galaxy Dragon face patch was inside the head -> moved forward (eyes now on lilac face).
- Rainbow Pegasus stick legs / hidden mane -> chunkier legs, bigger wings, bigger rainbow mane puffs.
- Sugar Dragon frosting cap covered the eyes -> cap raised, fewer/shorter drips.
- Eye clearance check (`--check`, BVH): Penguin (hat brim), Monkey (eye patches), Toy Robot (face plate inside head), Red Panda fixed; all highlights >= 0.04 stud clear of other surfaces.
