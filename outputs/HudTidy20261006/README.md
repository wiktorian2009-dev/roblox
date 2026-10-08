# Corner stats removed + TRAVEL / HELP stacked (2026-10-06, Claude)

Done after wiktor's go-ahead: "go ahead: ... remove the corner stats, stack travel and help ...".

## Corner stats (save point 28)
- **Removed:** `StarterGui.RNGGui.StatIcons` (the clover "1x" part-offer luck, the sword "4.5" clearing power and their hover box) and the LocalScript `RNGGui.LuckDisplay` that drove it.
- **Nothing else referenced them**, except ArenaHudClient's hide list, which looks them up nil-safely. No errors in Output.
- The snapshot copy moved to `removed/`.
- The bottom-left corner is free now, which also gives the phone thumbstick more room.
- **Undo:** `ServerStorage.CornerStatsBackup_20261006` (both objects; drag back into RNGGui).

## TRAVEL / HELP (save point 29)
- **New layout:** one left column, top to bottom:
  1. **HELP REQUEST pill** (with the mute bell, when a request is parked);
  2. **? HELP**;
  3. **TRAVEL**.
- TRAVEL now stands directly under HELP, at exactly the same width and height, with a small gap. It used to sit beside HELP.
- `TravelClient` places it from HELP's live position, so it stays aligned on every screen size and inset.
- **Measured** (2554×1153): HELP 904–956, TRAVEL 965–1016, same x and width. The help-request pill at 832–900 sits above. No overlaps.
- **Real clicks:** LATER parked the help request into its pill; TRAVEL opens the travel panel (it toggles); ? HELP opens its menu.
- **Not tested:** the phone emulator. The column follows HELP, which is unchanged.
- **Undo:** `ServerStorage.TravelHelpStackBackup_20261006.TravelClient`.

Screenshot: `screens/hud_after.jpg`.
