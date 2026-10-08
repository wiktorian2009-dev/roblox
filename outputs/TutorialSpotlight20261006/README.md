# Tutorial spotlight (2026-10-06, Claude)

wiktor: "tutorial should make screen darker and higlight and point thing u need to do".

## What changed (PlowTutorialClient, SnowArt)
- **Click steps** (DRIVE, UPGRADES, the upgrade hex, X, GARAGE, BUY / RESERVE, EQUIP):
  - A soft dark dim (black, 55%) covers the screen, with a feathered rounded cut-out around the target.
  - The dim is 4 Active frames around the cut-out, so mouse and touch only reach the target (plus the tutorial card with HELP / SKIP, and the HELP pill). Keys like F still work.
  - A slow-pulsing gold ring (about 0.5 Hz, no flashing) and a gently bobbing gold arrow mark the target.
- **Drive / walk steps** (snow, your bay, pedestals, workbench, lobby exit):
  - A light dim (32%) that never blocks input or the camera.
  - The cut-out follows the target's marker while it's on screen. When it's off screen or behind the camera, an arrow sits at the screen edge.
- **OK cards** (intro, done): light dim only. The returning-player UPGRADES tip uses the light dim too, so it never blocks anyone.
- **The overlay always clears:**
  - the target is missing or hidden;
  - the character dies or resets (it returns after respawn);
  - a loading screen is up;
  - the card closes (step done, SKIP, lesson end, arena pause).
  - It fades in and out (eased, about 0.15 s), never a pop.
- **Gamepad:** while a click step shows, GuiService.SelectedObject is kept on the highlighted button, unless the selection is on the tutorial's own HELP / SKIP. It is released when the step ends.
- **SnowArt skin:**
  - the card and HELP menu use the deep-blue snowy window;
  - HELP is a gold pill, SKIP blue, OK green; the menu buttons are green, blue and grey; the HELP pill is gold;
  - the pointer and edge arrows (and the 3D marker's arrow) are a new gold SnowArt arrow image.
  - New art: `tut_arrow` (Blender, ui_art.py `--arrow`) and `tut_spot` (cut-out, spot_art.py, plain Python). Both are in SnowArt.Images and IMAGE_PROMPTS.md.
- **Garage lesson retargeted to the lobby garage:** GARAGE 7 now says "Walk out of the garage, back into the lobby - or tap LOBBY". It points at the lobby seam (PlowGarage.Colliders.LobbyJoin, east). It completes once you step out past the seam or InGarage clears; the old ReturnPad is at the far west end now.
- **Fix found in testing:** if an offer expires (30 s) while its card is open, the card shows "expired" with no BUY / RESERVE, and the lesson used to sit on "Waiting for RESERVE". It now says "That offer expired - roll again!" and goes back to Card / Roll.
- Card buttons are now named Help / Skip / Ok.
- The upgrade screen's look is untouched (it is only dimmed around the target).

## Tests (Play, BalanceTestMode, fresh test profile)
Real input = Studio's virtual mouse and keyboard on the live client.
- **Main lesson, start to finish:**
  - real click on OK;
  - DRIVE spotlight: a real click on UPGRADES was **blocked**, then a real click on DRIVE started driving;
  - Field / Earn: real W/S driving under the light dim, real snow clearing. *Simulated:* the plow was moved next to the field from the server, because a snowglobe pedestal blocked the scripted route;
  - real click on UPGRADES opened the screen, real click on the SNOW START hex bought it (Up_S_Center), real click on X closed it;
  - Try passed with real driving, then Done.
- **Garage lesson, start to finish** (second session, with 5000 test Snow granted by a temporary Play-only helper):
  - real GARAGE click; the walk to the bay was simulated (Humanoid:MoveTo);
  - real E to roll, real E to open the card;
  - real BUY click, real E at the workbench, real EQUIP click (light → click spotlight switch);
  - the walk out east was simulated (pathfinding), and the step completed at the lobby seam;
  - real DRIVE click, then Done; the overlay fully cleared afterwards.
- **RESERVE spotlight:** on the card (0 Snow), only RESERVE is lit. The offer expired before the click, and the overlay cleared itself. That exposed the stall fixed above (re-test after the fix: the BUY path passed; the expiry path itself was not re-run).
- **SKIP:** two real clicks (SKIP → SURE?). Lesson stopped, overlay frames hidden, card hidden, HELP pill kept, SuppressEvents cleared.
- **Reset mid-step** (Bay step, Health = 0): the overlay faded out and stayed clear while dead. After respawn (outside the garage) the lesson stepped back to GARAGE with its spotlight.
- **Off-screen target** (camera turned away in Bay): an edge arrow plus the YOUR BAY tag, with a light dim and no cut-out.
- Screens: the captures in this session (card / DRIVE / hex / offer card / EQUIP). No script errors in Output.

## Not tested
- **Phone emulator:** Studio's device emulator can't be switched on through the tools I have.
  - The layout uses the same safe positions as before. The dim covers the full screen (IgnoreGuiInset).
  - During click steps the thumbstick is blocked by design; drive and walk steps never block.
- **Gamepad selection:** Studio's simulated DPad arrives as keyboard input, so the SelectedObject path is untested.
- The offer-expired fallback, re-run after the fix.

## Undo
- ServerStorage.TutorialSpotlightBackup_20261006 holds the previous PlowTutorialClient (52283/1050246276) and SnowArt (6826/1188421906). Disk copies are in `backup/`.
- Live = disk now: PlowTutorialClient 59204/178764834, SnowArt 7058/2036601008.
