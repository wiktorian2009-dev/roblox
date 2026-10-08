# Trailer kit manifest (2026-10-07, Claude)

Source files for the page-trailer director (DESIGN.md rev 2). Studio push order: run `install_edit.luau` (containers only), push each
source below with `multi_edit`, run `check_edit.luau`, then `arm_edit.luau` right before F5. After the take: stop Play,
`disarm_edit.luau`, `park_edit.luau` (it clears BalanceTestMode too, so a skipped disarm cannot reach the save). Kit install /
park are Studio writes: wiktor's consent, save point 56. Last teardown step, after wiktor closes OBS: `record_take.ps1 -RestoreUserIni`.

## Studio objects

| File | Studio path | Class | Properties |
|---|---|---|---|
| TrailerBootstrap.server.luau | ServerScriptService.TrailerBootstrap | Script | Enabled = true (RunContext Legacy) |
| TrailerServer.luau | ServerStorage.TrailerKit.TrailerServer | ModuleScript | |
| (container) | ServerStorage.TrailerKit | Folder | never replicates |
| (container) | ServerStorage.TrailerKit.TrailerDirectorGui | ScreenGui | ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = None, DisplayOrder = 1000, ZIndexBehavior = Sibling, Enabled = true |
| TrailerDirector.client.luau | ServerStorage.TrailerKit.TrailerDirectorGui.TrailerDirector | LocalScript | runs only after TrailerServer clones the gui into PlayerGui |
| TrailerClient.luau | ServerStorage.TrailerKit.TrailerDirectorGui.TrailerClient | ModuleScript | Lock/Restore, hide list, camera, shot engine, plow driver, refs recorder |
| TrailerText.luau | ServerStorage.TrailerKit.TrailerDirectorGui.TrailerText | ModuleScript | SafeFrame, letterbox, slate, black, cards |
| TrailerPuppets.luau | ServerStorage.TrailerKit.TrailerDirectorGui.TrailerPuppets | ModuleScript | puppet plows, driver, puppet minis |
| TrailerMath.luau | ServerStorage.TrailerKit.TrailerDirectorGui.TrailerMath | ModuleScript | pure maths, SelfTest() |
| TrailerShots.luau | ServerStorage.TrailerKit.TrailerDirectorGui.TrailerShots | ModuleScript | DATA + ValidateShots() (also required by TrailerServer) |
| TrailerRefs.luau | ServerStorage.TrailerKit.TrailerDirectorGui.TrailerRefs | ModuleScript | DATA filled from round 1 (REF_* lines) |

Play-only objects made by TrailerServer.Start: `ReplicatedStorage.TrailerRemote` (RemoteEvent), `ReplicatedStorage.TrailerRuntime`
(Folder) with `DriverRig` (blank R15 Model). Client-local: `Workspace.TrailerPuppets` (Folder), `Camera.TrailerGrade`
(ColorCorrectionEffect).

## Studio attributes

| Where | Attribute | Set by |
|---|---|---|
| ServerStorage | BalanceTestMode = true, TrailerMode = "rehearse"/"take", TrailerToken = os.time() expiry, TrailerSplit ("1-8"/"9-11", optional), TrailerRefs (optional) | arm_edit (Edit, before F5); cleared by disarm_edit |
| Player (server, via MCP) | CropOK, TrailerGo, TrailerAbort | Claude during Play |
| Player (server, by TrailerServer) | TrailerState, TrailerPrepared, TrailerAuto, TrailerRun, TrailerSplit, TrailerRefs, TrailerRollA, TrailerRollB, TrailerRefsLeg | TrailerServer |
| Player (client-local) | PlowTestMove, SuppressEvents, LightingSnap | TrailerClient (restored at the end) |

## Edit snippets (MCP execute_luau, Edit only)

| File | Does |
|---|---|
| install_edit.luau | backs up existing kit containers, creates Folder / ScreenGui / empty script objects (placeholder source), prints |
| check_edit.luau | read-only compile/data check: requires every module, SelfTest, ValidateShots, gui properties, no placeholders, camera unchanged |
| arm_edit.luau | sets BalanceTestMode, TrailerMode, TrailerToken (+ TrailerSplit / TrailerRefs) after a preflight, prints them |
| disarm_edit.luau | clears those attributes, sets a Scriptable Edit camera back to Fixed, prints before/after |
| park_edit.luau | moves TrailerKit and a disabled TrailerBootstrap into ServerStorage.TrailerKit_Parked, clears the trailer attributes and BalanceTestMode |
| uninstall_edit.luau | removes TrailerKit and TrailerBootstrap (parked copy and backups kept unless flagged), clears the attributes and BalanceTestMode |

## PowerShell helpers (local PC)

| File | Does |
|---|---|
| obs_trailer_setup.ps1 | writes the NEW OBS profile + scene collection "Trailer" (refuses while OBS runs; never touches "Bez tytulu"); -NoFfmpeg for the crop-in-OBS path; -DryRun |
| record_take.ps1 | launches OBS with the Trailer profile and --startrecording, READY on a new growing file, RAM watchdog (read-only polling), Studio-log markers, STATUS lines; `-RestoreUserIni` puts the four [Basic] profile/collection keys back from the first obs-user.ini.bak (OBS closed) |
| cut_takes.ps1 | T_A / T_B from the ROLL_A unixms and the OBS log; ffmpeg: crop from the slate, then blackdetect on the cropped picture, commands (run with -Run); no ffmpeg: Windows.Media.Editing black-run refinement, then the trim points |

`manifest.json` holds the same Studio table in machine-readable form.
