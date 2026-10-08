# Drive feel + hold-to-drift (2026-10-05, Claude)

Nothing was published. Backups of the old scripts are in ServerStorage.DriveFeelBackup_20261005 (PlowDriveClient, PlowConfig, SettingsService and PlowService, as they were before this task).

## What changed
- **One controller.** Drift lives inside PlowDriveClient's single Heartbeat, which writes the velocities; nothing else competes with it. Tuning is in PlowConfig `C.Drive` and `C.Drive.Drift`.
- **Input fix (an old bug).** The PlayerModule normalises W+D to (0.707, −0.707), so every turn silently cut throttle to 71%. The move vector is now mapped from circle back to square: full keys give full throttle and full steering, and a partial stick keeps its size.
  - To keep yard entry tight for beginners, full-lock steering eases target speed by up to 20% (`CornerSlow`), and high-speed steering loss dropped from 0.35 to 0.2.
- **Handling:**
  - Launch: up to +30% pull near standstill (`LowSpeedPull`). Top speed and each engine's AccelTime are unchanged.
  - Braking is firmer (BrakeFactor 1.8 → 2.3); coasting is gentler (`CoastFactor` 1.4).
  - Air control is 35%, and upright assist is ×1.6 when tilted more than 25° (bump recovery).
  - Sideways grip uses exponential decay, which is frame-rate independent.
  - Suspension and snow slowdown are unchanged.
- **Drift** (hold Left Shift, gamepad L1, or the DRIFT button):
  - It starts only on the ground, moving forward at ≥ max(9, 35% of top speed), with some steering. Holding it while stationary does nothing (tested).
  - While drifting:
    - sideways grip drops to 0.25× (traction still scales it, so grippy gear drifts tighter);
    - coasting loss drops 60%;
    - yaw gets up to +25% help, bounded;
    - past 38° slip the tyres catch again, so the plow can't spin out.
  - On release, grip returns over about 0.45 s, and 35% of the sideways speed swings back to forward. It never exceeds the build's top speed, and planar speed is capped during a slide. No Snow is awarded and there is no speed boost.
  - Drift clears on seat exit, death or respawn, any jump over 40 studs (teleport or recover), window focus loss, typing, opening the Roblox menu, and gamepad disconnect.
  - Gamepad drift is ignored while a GUI element is selected. The drift client does nothing on the arena island; ArenaDriveClient and ArenaConfig are untouched.
- **Bindings:**
  - The DRIFT button appears only while driving and shows the current binding: "DRIFT [SHIFT]", "DRIFT (L1)", or "DRIFT" on touch.
  - Gamepad B was rejected because Roblox reserves it for core UI.
  - The server pauses Roblox shift-lock while PlowDriving is set (PlowService), because Shift is the drift key. It restores StarterPlayer.EnableMouseLockOption afterwards.
- **Feedback** (pooled, made once per plow):
  - compact powder at the rear wheels;
  - two short fading skid trails (1.3 s lifetime);
  - existing blade and rear spray, now off when airborne or stopped;
  - an engine loop (Creator Store "Diesel engine idle loop" 71482635231754) and a skid loop ("Tire dirt skid/screech" 103723782639124) at low volumes;
  - up to +4 FOV and about 2° camera lean while drifting.
- **Settings:** new Settings rows "Drive sounds" (DriveSoundOn) and "Reduced motion" (ReducedMotion), saved by SettingsService. Reduced motion, or the treasure book's reduced effects, turns off FOV and lean and limits the powder.

## Tests
**Real (Play with BalanceTestMode, removed afterwards; temporary test pad, helper script and test hook existed only during Play):**

Keyboard on a flat test pad:

| Build | 0 → top | Drift (1.2 s hold) | Normal slalom | Brake |
|---|---|---|---|---|
| Starter (24 studs/s) | about 1.4 s | turns 112°, max slip 35°, speed ≈ 23 → back to 24 | 19 studs/s, about 85°/s, radius about 14 studs | 24 → 0 in about 0.6 s; reverse 13.2 |
| Mid, Jungle M parts (tracks, traction 0.95) | — | turns 97°, slip 19° (tighter, keeps speed) | — | — |
| Fast/wide, Cloud B parts (hover, 43 studs/s) | 0 → 43 in about 1.2 s | turns 146°, slip 39° (slippery hover gear, as designed) | — | 34 → 0 in about 0.4 s |

Before the cap was added, the fast build's slide speed reached 46 against its 43.3 top speed. Planar speed is now capped at top speed during a slide; that last change is code-verified only, not re-driven.

Other real checks:
- Countersteer flick (right, then left) works, and grip returns cleanly.
- Holding Shift + D while stationary gives only the normal pivot-gear turn (0.24 rad/s), with no drift and no launch.
- Exit (F) mid-drift: FOV 70, no lean, button hidden, shift-lock restored. Death mid-drift: vehicle cleaned up, FOV 70, button hidden.
- Starter field drift at snow speed (14.4): the slide and countersteer worked, and Snow kept paying (415 → 507), so the server speed check does not block legitimate slides.
- The World 2 Cloud→Cosmic arched bridge (10 studs wide, curved, rising 12 studs) was crossed by the mid build at 70% throttle and the fast build at full throttle, using the controller's test input (PlowTestMove). Steering was scripted, the physics was real.
- Starter yard entry (Yard_Starter): a 90° turn into the lane, through the gate and in, in 3.4 s with no stuck frames, then reversed out about 20 studs in 3 s.
- Both sounds load (9.7 s and 1.8 s). Two trails and three hull emitters were created.
- Desktop button layout does not overlap (DRIFT / EXIT / RECOVER).

**Not tested for real:**
- A physical gamepad. The test tool cannot send gamepad input, and L1 is wired the same way as Shift.
- A touch device. Touch layout positions were only checked numerically.
- How the skid trails look (3D doesn't render in Play captures at the sky pad).
- The fast build's top-speed cap after the last edit.
