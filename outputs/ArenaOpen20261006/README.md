# Arena: no walls, the whole rim is a drop (2026-10-06, Claude)

wiktor: "on arena there should be no walls just absolute madness and falling of an edge on whole radius of circle arena".

## Changes
- **Smaller floor:** a floating disc, radius 63.5 → **45** (`arena_open.py`, asset 125034015981681).
  - A bold **red/white edge band** runs all the way round, with a thin yellow line inside it.
  - The pads are matte, at **r 26** (19 studs from the edge).
  - The floor collider is 90 wide.
- **Void ring:** the island Rock and Snow have a full **void ring** cut from r 45.4 to 64.6, just inside the stands. A falling car drops into open sky everywhere; the old exit pits are now part of this ring.
- **Removed** (to ServerStorage.ArenaOpenBackup_20261006.RemovedFromLive):
  - all 40 bumper walls and the 8 exit posts;
  - the wall-ring art and the exit gates;
  - the exit signs and Exit_* markers.
- **Restored:** the 20 spectator-barrier segments across the old exits (at r 65, walkers only). They no longer block cars, which fall before r 62.
- **The stands stay well clear:** their inner face is at r 65. The air cap means the furthest a fall reaches is about r 60–62.
- **ArenaConfig:**
  - FloorRadius / WallInner / Void.Edge 45, PadRadius 26, Exits {} (so there are no exit markers).
  - The KO rules are unchanged: 34 studs below the floor, more than 2.5 s off the floor, or beyond r 110.
- **HUD:** the intro step now reads "Watch the EDGE! No walls! Pushed off the red & white edge = you fall…".
- **Practice ring:** unchanged (its own small ring, radius ring-out).

## Tests (real Play, BalanceTestMode, removed afterwards)
- Both the player and the bot spawned at r 26.0.
- A normal ram toward 0°, a former wall direction, pushed the rival off at r 45. It fell 34 studs (furthest point r 60), the KO was credited and the score went to 1.
- A self-fall at 200° (another former wall) was a clean drop: the KO registered, falls +1, no point, then the respawn.
- No errors and no anti-cheat flags.

## Not tested
- A screenshot (the Studio 3D view was not rendering).
- Two real clients.
- Phone and gamepad.
