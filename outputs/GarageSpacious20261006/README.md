# Garage: more space + visible roll cooldown (2026-10-06, Claude)

wiktor's ask: "we need to make garage more spacious and also visible roll cooldown".

## 1. More spacious garage (Studio-only geometry, `enlarge.luau`, run once; guarded by PlowGarage.SpaciousScale = 1.5)
- Everything is scaled **1.5x horizontally** around PlowGarage.LobbyRoot.
  - Structural pieces are stretched in size and position: bay Shell/Colliders/Lift, island, island colliders, and the plaza street tiles.
  - Props keep their size and only move: pedestals, workbench, reserve shelf, lamps, sign, landmark, portals, trees, crates and the GarageArenaPortal.
  - Bay shells and colliders are also **1.25x taller**, for camera room.
- **Bay:** 32 x 31 became **48 x 46**.
  - Turntable diameter 14.6 → 21.9, so the 20.8 widest blade fits on it.
  - Pedestals at x ±17.25, z -12 / 0 / 12; side walls at ±23.7, leaving 2.7 studs between the turntable and the pedestals.
- **Rows:** columns at x ±24 / ±72, rows at z -235 / -325, and the street/plaza between them is **43.5 wide** (was 29). The island is 228 x 150.
- **Fixes after the transform:** the front posts were re-grown to the new height, and a small floor prop was re-grounded.
- **Floor check:** a 5-stud raycast grid over the whole garage found no holes or low spots.
- **Overflow bays:**
  - The SharedGarageTemplates were transformed the same way.
  - PlowService.overflowBay reads the spacing from the OverflowOrigin attributes ColStep 48 / RowOffset 45.
  - It also switches off the east rim colliders when a column is built (pre-existing: the rim wall cut through overflow bays).
- **Code:**
  - PlowService: BAY_REACH 26 → 39.
  - PlowGarageClient: the inspect panel closes at 65 (was 45).
  - PlowTutorialClient: the bay step completes within 22 (was 16).
- **Unchanged:** the lease service and the 8 numbered bays.

## 2. Visible roll cooldown (length unchanged: 2 s x RollCooldownMult 0.6-1)
- **Server:** PlowService.Roll sets the player attributes **RollReadyAt** (server time) and RollCooldownLen. The server still enforces the cooldown ("Rolling too fast").
- **Pedestals** (your bay only):
  - A snowy pill above each roll pedestal fills orange with "ROLL IN 1.4s", then shows green "❄ ROLL READY!".
  - The E/R prompts read "Roll a part (1.4s)" and "Reroll (1.4s)", so desktop, phone and gamepad all see it in the native prompt.
- **Offer card:** the REROLL/ROLL button turns grey and fills while waiting ("REROLL 1.4s"), then pops back to orange.

## Tests (real Play, one client)
- **GoGarage:** bay 1 assigned; arrival lands on the floor.
- **Roll at pedestal 1:** readyIn 1.96 s from server time. All 3 pills and prompts counted down 1.9 → 1.0 → READY. An instant reroll was refused.
- **REROLL button** (card opened directly for the display check): 1.4 s → 0.8 s → 0.3 s, then ready.
- **Workbench prompt:** active at 5 studs. Equip works from every corner of the bigger bay.
- **GoLobby → GoGarage:** round trip OK.
- **Overflow:** 9 test visitors filled bays 2-10. Overflow bays 9 and 10 sit at x 120 with full floor, no overlaps, and the rim opens.
- No errors.

## Not tested / limits
- Screenshots: the Studio 3D view isn't rendering in captures (UI only), so the layout was checked with geometry raycasts.
- The tutorial's arrows were not run end to end; they target the moved parts by name.
- Phone and gamepad on real hardware.

## Undo
- ServerStorage.GarageSpaciousBackup_20261006 holds the old PlowGarage, the GarageArenaPortal, SharedGarageTemplates and the old scripts.
- The old sources are also in before/.
