# Free quick travel: TRAVEL menu + lobby teleporter (2026-10-05, Claude)

Nothing was published. The PlowService backup from before this task is ServerStorage.TravelBackup_20261005.PlowService.

## What it is
- **TRAVEL button.** A compact snowy pill next to the bottom-left HELP button. It follows HELP's position on any screen size and is hidden until the plow tutorial is done, on the arena island and during the intro.
- **Lobby teleporter pad.** `workspace.TravelPad` sits 28 studs from the spawn and 20 studs off the spawn→field drive lane. Its prompt ("Open travel", E / gamepad X) opens the same menu.
  - The pad is a Blender model: octagon stone pad, frosted ice top, glowing rune circle, a soft floating icy ring and four crystal pillars. Pack W1_Travel, asset 132785570016808.
  - It has a "🧭 TRAVEL" SurfaceGui sign and modest sparkles (UniversalVFX star, rate 5).
  - Collision is on the stone, ice and pillars only.
- **Menu.**
  - Built from the approved Settings panel, so it matches the snowy panels.
  - Contents: Lobby, My Garage, then every stage in StageConfig under the headers "WORLD 1 - FROSTFALL" and "WORLD 2 - SAKURA & BEYOND". Nothing is invented and the removed Neon stage is not listed.
  - The current spot is marked "YOU ARE HERE". Locked stages show the real requirement, e.g. "🔒 Unlock at its gate: 60Qa Snow (after Sakura Garden)" or "Opens with Absolute Zero Portal".
  - Locks refresh at once from the Stage_* attributes after a purchase or rebirth.
  - Rows are 68 px (78 on touch) with large GO buttons. The first GO is selected when the menu is opened with a gamepad.
  - Travel is free.
- **Server (TravelService).** One handler, `TravelRemote:InvokeServer("Travel", id, confirm)`; the client sends only a destination id. The server checks:
  - the destination is in TravelConfig and unlocked;
  - the player is alive and not in the intro;
  - the player is not on the arena island ("tap LEAVE ARENA first" – the arena's own cleanup);
  - not already there, not already travelling (the busy flag is always cleared), and the 2.5 s cooldown has passed.
- **Vehicles.**
  - A driven plow is parked through PlowRegistry.Park (unseat and destroy) before the character moves, and velocities are cleared.
  - After arrival the same saved build is spawned again through PlowRegistry.Spawn (PlowService's normal spawn path, so a future Body slot works too).
  - The garage always goes through PlowService's bay lease (PlowRegistry.GoGarage). Leaving it releases the bay and clears the stale return position.
  - Streaming waits use a bounded RequestStreamAroundAsync (6 s), and the character is re-checked after yielding.
- **NPC jobs.** The first request answers with one clear warning: "Travelling cancels your current job (no reward). Tap again to go." The second tap cancels the job through ContractRegistry.Cancel, the normal cleanup that frees the yard and the personal snow, with no reward.
- **Arrival points.** `workspace.TravelPoints` holds 16 invisible, non-colliding parts.
  - World 1 stages: just behind each gate, beside the stage's field, on flat ground with a clear 9×6×14-stud box.
  - World 2 stages: on the side the bridge arrives from.
  - Lobby, Starter, Portal and Sakura reuse the existing markers.
  - Generator: travel_points.luau.

## Tests (real, Play with BalanceTestMode, removed afterwards; temporary helper script existed only during Play)
- Locked Desert: "Locked - Unlock at its gate: 5K Snow."
- Lobby → My Garage leased bay 1. "Already in your garage" was refused. Garage → Candy released the bay (Bay_1 owner 0) and cleared InGarage.
- Seated with a wide, fast build (Cumulus 13-wide blade, Storm engine, Storm hover pods), travelled to all 16 destinations. Each time:
  - the old plow was parked;
  - the same build respawned seated;
  - the hull sat at normal ride height (1.6–1.8 studs) over real ground;
  - World was set to 1 or 2 correctly.
- After arrival the plow drove 42.8 studs in 1.5 s with the controller's test input.
- Seated → Garage parked the plow and leased a bay.
- Two parallel requests: one travelled, the other got "Already travelling...". Within 2.5 s: "One moment...". An unknown id was refused.
- Active Road job → first request gave needConfirm with the warning and the job stayed active. Confirm cancelled it: fields 4 → 0, yard freed, Snow unchanged (no reward).
- Arena: entered through the real lobby arena portal (E). Travel was refused with "tap LEAVE ARENA first" and the player stayed on the island. ArenaRemote "Leave" then worked, and the TRAVEL button came back.
- Rebirth through the real RequestRebirth remote relocked everything: Cosmic shows "420Qi Snow (after Cloud Kingdom)" and Starter still works.
- GUI:
  - The real TRAVEL click opens the menu (World 1 and World 2 sections, YOU ARE HERE, lock texts).
  - A real GO click on Desert travelled there and closed the menu.
  - The pad prompt (real E) opens the menu.
  - The button sits beside HELP (screenshots/).
- Death mid-travel: in Studio, streaming returned instantly, so the travel finished before the kill. The next travel worked, so the busy flag doesn't stick. The "character changed after streaming" re-check is code-verified only.

## Not tested
- A physical touch device or gamepad.
- Slow-streaming conditions (the real-server streaming delay).
- How the pad looks in 3D (Studio renders were black while the window was minimised; the Blender render is in screenshots/pad_render.png).
- Multiple real players at once.
