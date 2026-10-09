# Open lobby: every garage bay in clear view (2026-10-09, Claude)

wiktor: "i think the lobby block off garages to much maybe we should rearange".

Before: the old village dressing still stood between the plaza and the bays. A ring of pines, snow mounds, rocks and hut drifts sat at r 66-91. The Crafting machine stood in front of Bay 3 and the Crystal Pavilion in front of Bay 4. The Pet Fuser stood in front of Bay 8, the TravelPad in front of Bay 1 and the arena portal in front of Bay 2. The bays are low and flat, so from the plaza you mostly saw trees and machines (screens/before_*.jpg).

After: the plaza is an open snowfield. From the plaza edge each of the 8 bays has a clear "lane" (the view from the plaza to the bay's open side, at least 12 studs wide). The lobby features stand beside the lanes, not in them (screens/compare_*.jpg).

## What moved (Studio, Edit; nothing deleted, nothing saved or published by me)
Script: hub_open.luau (MODE "plan" / "apply" / "undo"). Every placement is checked against the lanes, the bays, the snow yard, the spawn, the boards, the ice peaks and the other pieces.
- **Pet Fuser:** east, south of the snow yard (a 326, r 66), facing the plaza.
- **TravelPad:** east, north of the snow yard (a 32, r 63), facing the plaza.
- **Crafting machine:** in the wide back of the gap between Bay 3 and Bay 1 (gap 141.67, r 141.5). The walk path along that gap is kept free.
- **Bumper Arena portal:** in the gap between Bay 2 and Bay 4 (218.33, r 128.5), with a free path. The arena's return portal now drops you 10 studs in front of it.
- **Crystal Pavilion:** in the gap between Bay 4 and Bay 6 (251, r 137.5).
- **Mountains:** the two behind the Crafting / Pavilion gaps went from r 165 to r 178 / 176.
- **Trees (8 F_Pine + 13 SnowPine):**
  - groves of 3-4 in the gaps Bay 7|5, Bay 5|3 and Bay 6|8;
  - one pine at the NE ice peak;
  - one pine behind each of Bays 1, 4, 5, 7, 8; two behind Bay 3 and two behind Bay 6.
  - The F_Pine trunk colliders moved with their trees.
- **Lanterns:** 6 now stand in the narrow strips between the lanes at r 38-42; the 2 by the spawn stay.
- **Benches:** 4 in the strips at r 46-49, facing the globe. Lantern and bench colliders moved with them.
- **Festival string lights:** the poles moved 23.2 studs west, onto the strips at r 50.
- **Snow mounds, rocks and hut drifts:**
  - between bay corners at the gap mouths;
  - at the feet of the gap groves;
  - at the outer end of the strips;
  - behind the bays and at the east edges;
  - one ice rock stayed where it was.
- **Snowmen:** the two snowmen + presents groups moved beside the TravelPad (NE) and the Pet Fuser (SE).
- **Frozen pond:** the pond with its 4 penguins, small mounds and ice rock (15 pieces) moved behind the spawn, in front of the leaderboards. Seen from the spawn it stays below the board panels.
- **Presents:** loose presents went to the strips and the east; the 4 by the scout camp stayed.
- **Removed into the backup:** an invisible pine-trunk collider with no tree. It stood in Bay 5's lane.
- **Cliff facets:** the 6 tall facets of the old village rim showed as flat blue slabs; they now sit 0.02 above the floor top. One SnowPine that used to stand on the ice walk now sits on the snow.

Not moved: bays, spawn, travel points, leaderboards, snow yard, egg display, snow globe, ice paths, ring floor, scout camp, ice peaks. No script changed.

## Checks
- **Edit:**
  - Lane audit: no visible part taller than 1.3 studs and no invisible collider in any lane.
  - No moved part reaches into a bay.
  - Every moved piece has floor under it.
  - Eye-level screens from the plaza edge toward all 8 bays, the spawn (east and NE), the Crafting gap, the pond and a tree gap.
- **Play** (Studio, BalanceTestMode, PC, one player, temp profile):
  - Bays: walked from the spawn into each of the 8 bays and got exactly that bay (GarageBay 1-8). After each, LOBBY (GoLobby) put me back at the spawn with the bay released.
  - GARAGE: put me inside Bay 1 at bay-local z -17 and I stayed InGarage.
  - TRAVEL: Lobby / My Garage (inside Bay 1) / Starter / Lobby all worked. Requests closer than ~2 s apart answer "One moment...", as before.
  - DRIVE at the spawn: the plow spawned 10 studs ahead and seated me; leaving the seat despawned it.
  - Prompts:
    - TravelPad: fired from 8.5 studs. The menu stays closed during the first tutorial (TravelClient rule for new players).
    - Arena portal: fired from 5.7 studs, took me to the arena; its return portal brought me back in front of the new portal, outside any bay.
    - Crafting: fired from 12.8 studs in its gap ("Locked" on a new profile).
    - Pet Fuser: fired from 6.8 studs. At 11.9 studs, next to the snow yard's "Travel" prompt (13 studs from the Fuser's), it did not fire, likely because only one E prompt shows at a time.
  - Leaderboards render with test data; the penguins stay under the panels.
  - No console errors.
  - Screens: screens/play_*.jpg.
- **Not tested:** a real keyboard E press, phones, more than one player, overflow bays (9+ visitors), a full tutorial run, driving the whole route to the field.

## Undo
Run hub_open.luau with MODE "undo". It puts every object listed in ServerStorage.HubOpenBackup_20261009.Moved back at its OrigPivot, including the colliders, mountains, cliff facets and string lights. It also returns the orphan collider from .Removed to W1Remaster.Frostfall.Colliders.

MODE "apply" can be re-run safely, because it always starts from the original pivots in the backup.
