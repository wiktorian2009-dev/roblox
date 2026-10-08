# Garage moved into the lobby (2026-10-06, Claude)

wiktor: "i would transfer garage to lobby and fuse it together cleanly".

## Where and why
- The Frostfall lobby is a floating island (radius about 95 around (−100, −282)) packed with the village, fields and machines, and ringed by snowy mountains. The open ground inside it (about 70×130) cannot hold 8 spacious 48×45 bays.
- So the whole calm, open garage, island included, moved down to lobby level, flush against the lobby's **west edge**. That is right beside the **TravelPad (−145, −304)** and the **lobby arena portal (−152, −258)**. The garage centre is at (−305, 0.2, −282).
- **The join:**
  - The garage street (z −304..−260) runs straight into the lobby through the garage island's east opening.
  - I removed the two mountains that blocked it and nudged the two outer ones aside, so they now frame the entrance.
  - An invisible flat walkway and a snow strip cover the 3-stud seam between the islands.
  - The ground is continuous at y 0.2.
- **Kept clear:** the snow fields, the Starter field, the Help Yard and the village are all east, so nothing on the drivable paths or the tutorial routes changed.
- **Old sky garage:** the island at y 700 is gone from the live map (backup below). Nothing is left at the old spot.

## Behaviour
- **Walking in** from the lobby enters the garage: the bay is assigned and InGarage is set. **Walking out** leaves it after an 8 s grace (PlowService). Players seated in a plow never trigger it.
- **Unchanged:** GARAGE, TRAVEL "My Garage" (PlowRegistry.GoGarage) and the tutorial's garage lesson still teleport to the arrival plaza. The return portal and LOBBY still go back. Leases, bays, prompts, pedestals, workbench, shelf and turntable work as before.
- **Overflow bays** now grow **west**, past the garage's own plaza: OverflowOrigin (−449, 0.2, −282) is turned 180°, and its OpenRims attribute is "RimWest". The code reads the rim names from that attribute.
- **Arena portals:** the garage's own arena portal is removed, since the lobby arena portal is about 60 studs away. The arena's "Visit" handles players coming from the garage as before.

## Tests (real Play)
- **Walk-in:** walking west from the lobby spawn entered the garage at x −205 after 2.4 s (bay 1), and a roll at Bay_1 worked.
- **Walk-out:** walking back out cleared InGarage and released the bay after 9.4 s.
- **TRAVEL "My Garage"** from the Starter field landed on the arrival plaza with InGarage set and bay 1.
- **GoLobby** returned to where I came from. **GARAGE (GoGarage)** landed on solid ground at the plaza.
- **First attempt:** the character fell into the 3-stud seam. That is fixed (walkway + 5-stud shift) and re-tested.

## Not tested
- A full tutorial run.
- The overflow layout on the west side: no Play test with more than 8 visitors after the move.
- A screenshot (the 3D view is not rendering in captures).

## Undo
- ServerStorage.GarageLobbyBackup_20261006 holds the old PlowGarage, the GarageArenaPortal, SharedGarageTemplates and the scripts.
- RemovedFromLobby holds the two mountains and the garage arena portal. The two nudged mountains moved +12 / −16 studs in z.
