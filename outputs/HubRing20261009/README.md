# Garage ring around the lobby (2026-10-09, Claude)

wiktor: "having lobby is having no point lets move garages to make almost a circle shape so the lobby became garages and lobby itself".

## What changed (Studio, Edit; nothing saved or published by me)
- **Bays:** the 8 garage bays now stand in a near-circle around the Frostfall village, with their open sides facing the village centre (-100, -282).
  - Bay_1 and Bay_2 are next to the spawn on the west side, then the bays go outward on both sides.
  - Angles (0° = east toward the fields, 90° = -Z): Bay_1 158, Bay_2 202, Bay_3 125.3, Bay_4 234.7, Bay_5 92.7, Bay_6 267.3, Bay_7 60, Bay_8 300.
  - Each bay's open side is 97 studs from the centre; the bays are 48 × 45 as before.
- **Openings:** the east sector (-45..45°) stays open, so the snow fields and the Starter connection are unchanged. The west gap between Bay_1 and Bay_2 holds the leaderboards and the path to overflow bays.
- **workspace.HubRing** (new, Persistent):
  - A snow ring floor out to radius 162, at top 0.14 (the village snow is 0.24, the bay floors 0.20). The icy shelf and rock base copy the village's layers. Each is one CSG union with the east sector cut out.
  - Edge rocks, a snow-ball rim, and invisible 16-stud colliders (RingRim / RingEnd / YardSide).
  - The south-east end is trimmed square at x = -4, so it stops before the Starter Help Yard pad.
- **Mountains:** the lobby's mountain wall moved out behind the bays.
  - 16 mountains were moved to slots behind and between the bays (radius 165-202). The four lobby ice peaks frame the ends, and the two peaks at the opening turned to ±33°.
  - The watchtower moved with its mountain.
  - 39 mountains that stood around the old garage island or had no slot went to the backup.
- **Old garage island:** Island, Plaza, Props, ReturnPad, LobbyRoot and Colliders went to the backup.
  - The lobby's old west rim went too: 164 W1Edges pieces, 21 EdgeSnow pieces, and 1 garage-wall collider.
  - 21 CliffFacets under the new floor were lowered 0.45.
  - PlowGarage keeps its Bays, plus:
    - Arrival, moved to (-160, 3.4, -282) as a fallback.
    - OverflowOrigin at (-286, 0.2, -282), facing +Z. Columns grow west from the west gap, and OpenRims = "RimWestGap".
    - A new Colliders folder holding RimWestGap.

## Code (live = disk)
- **PlowService**:
  - Walking into a bay enters the garage, and you get **that** bay if it is free.
  - Walking out clears InGarage after 2.5 s, and the bay is kept 30 s more, so stepping out to the plaza and back keeps it.
  - GARAGE / TRAVEL "My Garage" teleport you just inside your bay's open side, facing the pedestals.
  - Overflow streets count as garage.
  - The old IslandTop / Arrival still work as fallbacks.
- **PlowTutorialClient**, GARAGE 7: the marker sits just outside your bay, and the step completes once you are out of it.
  - The disk file also holds the uninstalled UI-audit changes, so the live and disk versions still differ there.
- **Script backup:** ServerStorage.HubRingScriptsBackup_20261009 (old PlowService and PlowTutorialClient, disabled).

## Tested (Studio Play, BalanceTestMode, PC, one player)
- Walked into Bay 4 from the plaza: InGarage on, GarageBay 4 (the bay walked into, not the first free one).
- Walked out: InGarage off after about 3 s, bay kept. Walked into and out of Bay 6, then waited 32 s: the bay was released.
- GoGarage while holding Bay 4: arrived at bay-local (-1.2, 3, -17), and InGarage stayed on. GoLobby went back and released the bay.
- TRAVEL:
  - "My Garage" → Bay 1, inside its open side.
  - "Starter" → the field. InGarage turned off and the bay was released.
  - "Lobby" → the spawn.
- DRIVE in the plaza spawned the plow.
- Raycasts: ring floor at 0.14 everywhere in the span, bay floors at 0.20, no floor in the east sector, and the boards' posts on the floor.
- No console errors.
- Screens:
  - screens/aerial_from_east.jpg
  - screens/spawn_looking_west.jpg (boards between Bay 1 and Bay 2)
  - screens/inside_bay3_looking_out.jpg
  - ../Leaderboards20261009/screens/boards_test_data.jpg

## Not tested
- More than 8 garage visitors (overflow bays west of the gap).
- A full tutorial run (GARAGE lesson).
- Driving around the whole ring.
- Phones and multiplayer.
- The arena portal, the TravelPad prompt and World 2, beyond the fact that their positions didn't change.

## Undo
1. Run hub_ring.luau with MODE "undo". It moves every object back from ServerStorage.HubRingBackup_20261009 (Moved = ObjectValue + OrigPivot, Removed = HubOrigParent) and puts workspace.HubRing and the RimWestGap folder into the backup.
2. Copy the sources from ServerStorage.HubRingScriptsBackup_20261009 back into PlowService and PlowTutorialClient. The new code also works with the old layout, so this step is optional.
3. Move workspace.Leaderboards somewhere else if the west gap goes away.

Files: hub_ring.luau (plan / apply / undo) and after_apply.luau (yard trim + boards).
