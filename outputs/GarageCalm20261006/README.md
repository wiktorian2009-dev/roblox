# Garage: calm + open (2026-10-06, Claude)

wiktor's feedback: "they are to flashy and still i feel claustro phobic".

## Changes
- **New open-air bay shell** (`bay_open.py`, asset 134431933723151), 48 x 45. It replaces the stretched roofed shell in all 8 bays and in the overflow template.
  - Removed: the roof, header beam, rafters, hanging lamps and corner pillars.
  - Waist-high snowy fences (2.4) and a low back wall (2.7).
  - Matte painted floor lines; tool chest and crate on the floor.
  - The BAY sign now stands on a slim post at the entrance (local x +21, z -21.5), facing the street; the SignPanel SurfaceGui was moved onto it.
- **Colliders:** side walls 2.4 high, back wall 2.7, corner posts removed.
  - Nothing collidable inside a bay rises above 3 studs, so nothing pushes the camera in.
  - The hanging-lamp PointLights are off.
- **Calmer materials:**
  - Pedestal neon dot strips are hidden.
  - Pedestal rings are matte soft blue (soft gold on the reserve shelf), the only accent.
  - Lift neon post caps are matte grey-blue and the yellow hazard ring is muted sand.
  - The workbench screen is matte.
  - Reveal lights: 0.8, with a peak of 3 instead of 9.
- **Billboards:**
  - Neighbours' pedestal labels only show within 16 studs; yours within 45.
  - Roll pills are smaller and softer (4 x 0.85, matte green / orange, no pulse) and owner only.
  - Empty bays' FREE BAY boards only show within 25 studs.
- **Scripts:** PlowGarageClient only. It is mirrored, live = disk 26669 / 963046259.

## Tests (real Play, real camera)
- `screens/in_bay.jpg`: standing in Bay 1 looking at the pedestals. Sky, street and distance are visible, there is nothing overhead, and the small READY pills show.
- `screens/street_sign.jpg`: from the street, "BAY 1" reads clearly on the post.
- Roll still works at the pedestal.
- The earlier tests (leases, overflow, workbench, return portal) are unaffected: geometry under props is unchanged and the floor is the same size.

## Undo
- ServerStorage.GarageCalmBackup_20261006 holds the garage and templates before this pass.
- RemovedParts holds the old shells and posts, plus the import.
