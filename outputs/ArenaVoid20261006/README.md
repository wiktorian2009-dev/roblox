# Arena: void falls + real knockback (2026-10-06, Claude)

wiktor's ask: "make the arena so if u lose u are dropping to void bc bumping is doing nothing".

## Cause (measured in Play, bot rival, before any change)
| Ram | Rival kick (studs/s) | Rival push (studs) |
|---|---|---|
| normal, ~18 studs/s | 17 | ~7.5 |
| BOOST, 46 studs/s | 49 | ~23 |

The server applied exactly the configured values. Network ownership, the anti-cheat and the shields were fine. The pushes were simply too small (Decay 2.2) for a 58-stud ring with walls. A "ring-out" was an instant despawn at r 61.5 while you drove onto solid-looking (non-colliding) snow.

## Changes
- **ArenaConfig.Knock:** Base 14, PerClosing 1.0, NormalMax 40, BoostBase 30, BoostPerClosing 1.2, BoostMax 85, Decay 1.5, MaxVel 90.
- **ArenaConfig.Void:**
  - Edge 63.5, Depth 34, OffTime 2.5, EscapeRadius 110, SlideOff 12, AirMax 28.
  - The practice ring still uses OutRadius / FallDepth.
- **ArenaService:**
  - checkOut (main floor): KO at 34 below the floor, after more than 2.5 s off the floor, or beyond r 110.
  - Attribution uses the moment the vehicle left the floor (offSince).
  - The reason is "fell"; plausibility is skipped while off the floor.
  - Bots and targets fall with gravity: no drive in the air, a slide-off minimum and a sideways cap.
- **ArenaDriveClient:** airborne means no drive, steering or knock bookkeeping, plus the same slide-off and cap.
- **ArenaHudClient:** the KO line now reads "You fell into the void".
- **Art:**
  - pits.py rebuilds the island Rock and Snow (outputs/Arena20261005/models.py Island) with an annular-sector shaft behind each exit: r 63.9–93, ±17°.
  - Uploaded as asset 78190677650536 and swapped in place (same size and CFrame).
  - 20 SpectatorBarrier segments across the exits were moved to the backup. Seated characters collided with them and hung at the lip.
- **Wall choice:** I kept the 4 striped exit gaps. The stands sit 1.5 studs behind the bumper wall all round, so a full-rim drop would mean removing the stands.

## After (real Play, Studio, one client + server bot)
| Test | Result |
|---|---|
| normal ram, 20 studs/s | kick 34, push ~24 studs, striker recoil ~5 studs |
| BOOST ram | kick 85, push ~59 studs |
| normal ram into the 45° pit | rival slides off, tips at r 64, falls 34 studs in ~0.6 s; KO credited (score 1); respawn 4.0 s later with a 2.5 s shield |
| self-fall at 135° | visible fall; reason "fell"; no point; falls +1; respawn 4.0 s later |
| bot BOOSTs the player into the 315° pit | real client knock path; credited to the bot; furthest point r 81 (pit wall at 93) |
| logs | no errors, no anti-cheat flags |

Not tested: two real clients, leaving the seat mid-fall (the existing seat-KO path), the practice ring, phone and gamepad. Also the in-Studio visual: the 3D view didn't render in captures, so I checked with Blender renders (renders/pit_exit45.png) and geometry raycasts.

## Undo
Everything is in ServerStorage.ArenaVoidBackup_20261006:
- old scripts;
- Colliders, AR_WallRing, AR_ExitGates and Markers;
- OldIslandMeshes;
- ExitBarriers (each has an OriginalParent attribute);
- the AR_IslandPits_Import.

Old sources are also on disk in before/.
