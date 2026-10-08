# Trailer groundwork — 2026-10-06, Claude

Goal (wiktor): a gameplay trailer for the media slot on the game's Roblox page, like the "Build and Kill Zombies" page (real footage, big white PLAY NOW! overlay). Defaults from the coordinator: 16:9, 30 s or less, only what exists now, no prices or buy prompts, `[GAME TITLE]` placeholder. The treatment and shot list come from the cloud design team; nothing is built in Studio yet.

## What exists now (checked in Studio, read-only, place 94130990350526)

- Workspace.StreamingEnabled = **true**. A camera far from the character sees unloaded or low-detail parts, so every shot must first move the player there (TravelService) or call `Player:RequestStreamAroundAsync(pos)` and wait.
- ReplicatedFirst.BiomeLighting grades by **camera position when CameraType is Scriptable** (probe(), line ~128). A scripted camera gets the right biome look for free.
- AFK auto-plow (AfkService + PlowDriveClient autopilot) drives the player's real plow in a lawnmower route over a field and really clears snow. Best source of driving footage without a second velocity writer. **Any keyboard/gamepad press turns AFK off** (AfkDriftClient ~line 125), so no keys may be pressed while a driving shot runs.
- Verity Egg is a SHOP-panel egg only; there is no world model. A shot needs a temporary display model built from ReplicatedStorage.EggModels ("VerityEgg") by the director. The panel itself shows a price, so it is out (no prices).
- Remotes (TravelRemote, AfkRemote…) exist only in Play. Lighting.ClockTime 14.5.
- Old intro cinematic (SnowIntroController etc.) is archived; nothing to reuse live.

## Shot locations (studs; Y = ground)

| Place | Key points |
|---|---|
| Lobby, Frostfall Village | arrival (-167, 4, -282); snow globe (-102, 11, -282); Snowy Egg display (-101, 4, -267); Pet Fuser (-85, 0, -235); Crystal Pavilion (-140, 0, -233); Crafting (-137, 0, -331); village bounds ~215×205 centred (-91, 18, -283) |
| Starter field | centre (35, 0, -288), 21×42 tiles (63×126 studs); travel point (10, 2, -282) |
| Desert | fields (189, 3.5, -259) and (247, 3.5, -226); egg (128, 8, -262) |
| Cursed | fields (311, 3, -55), (225, 3, -43); egg (245, 8, -147) |
| Crystal | fields (283, 4, 159), (231, 4, 234); egg (277, 8, 90) |
| Retro | field (86, 4, 222); egg (162, 8, 214) |
| Jungle | fields (-103, 5, 290), (-104, 5, 223); egg (-6, 9, 261) |
| Absolute Zero | field (-258, 1, 255) 30×85 tiles; egg (-202, 5, 240); portal (-323, 28, 255), 91×75×50 |
| Garage island | island centre (-305, 0, -282); arrival (-386, 3, -282); e.g. Bay_4 root (-233, 0, -237) with pedestals 1-3 at x -216, z -249/-237/-225, lift (-233, 0, -231); Bay_7 root (-329, 0, -327) |
| World 2 islands (travel points) | Sakura (1590, 2, 0), Candy (1950, 4, 18), Atlantis (2224, -10, 32), Toybox (2557, -2, 1), Clockwork (2871, 7, -34), Cloud (3200, 22, 30), Cosmic (3539, 34, 29) |
| World 2 fields | Sakura (1701, 0, ±25); Candy (2021, 4, 26/84); Atlantis (2333, -10, -46)/(2327, -10, 15); Toybox (2650, -2, 14/75); Clockwork (2906, 6, -2)/(3046, 6, -66); Cloud (3248, 22, -4)/(3347, 30, 55); Cosmic (3583, 34, 51)/(3647, 34, -31) |
| Bridges | Sakura bridge prop (1782, 3, 0); Candy WaferBridge (1958, 5, 55); Clockwork canal bridges (2894/2926, 8, -62). Crossings are hidden by fog banks at x 1855, 2175, 2495, 2815, 3135, 3455 by design, so bridge shots should look along an island, not across a crossing. |
| Bumper Arena | sky island centre (-44, 691, 80), 231×125×355 |

Camera CFrames get finalised once the shot list arrives, with an Edit screenshot per shot (camera saved and restored, CameraType back to Fixed).

## Edit framing checks (2026-10-07, Claude; camera restored to Fixed)

- Locked stages show a black paywall wall with "UNLOCK / STAGE LOCKED / Cost: 100" (seen on the Absolute Zero portal, beside the Starter field toward Desert, behind the Crystal Heart, and inside the Candy castle gate). Every stage on screen must be unlocked in the temp profile, or framed so no paywall shows.
- Crystal Heart is workspace.W1Remaster.Crystal.X_Heart (236, 4, 125; crystal top ~y 29); headframe/mine wheel X_Headframe (192, 4, 100). Absolute Zero Heart Engine is Z_HeartEngine (-327, 1, 183); the portal arch faces the field at (-323, 28, 255).
- Candy: the candy path (CandyScenery.Path, z 55, x 1902-2102) runs straight to the castle; camera (1915, 11, 55) looking at (1990, 6, 55) gives a strong centred shot. A "HELP YARD" sign is at the right edge.
- Edit has no snow tiles (they are built in Play), so field framing must be checked in Play.
- StarterGui SHOP shows a "30% OFF" badge; the trailer hides all HUD anyway.

## Planned director (not built yet)

- **Nothing reaches real players.** Everything lives in `ServerStorage.TrailerKit` (never replicated). A tiny `ServerScriptService.TrailerBootstrap` Script returns at once unless `RunService:IsStudio()` **and** `ServerStorage:GetAttribute("TrailerMode") == true`. Only then does it copy the director LocalScript into the player's PlayerGui and create a `TrailerRemote` for Studio-only helpers.
- **Start:** F8 in Play (or Claude sets a player attribute from the MCP). A 3-second black countdown follows so recording can already be running.
- **While it runs:** every PlayerGui ScreenGui disabled (old state remembered), core GUI and top bar off, mouse icon hidden, character controls disabled, camera Scriptable on a RenderStep binding. Shots are keyframed splines (static world paths), follow shots locked to the plow's root, or orbits; each shot streams its area in first.
- **Driving footage:** the server helper puts the plow on the chosen field and switches AFK on; the camera follows. No extra velocity writer.
- **End:** final `[GAME TITLE]` + PLAY NOW! card, then everything restored in a pcall-guarded cleanup (GUIs, core GUI, camera Custom, controls, AFK off). F8 again aborts and restores.
- Test profile: Studio temp profile with `BalanceTestMode`, stages unlocked and a good-looking build granted only inside that test session. No real data touched.
- Backup: the kit only adds new objects; nothing is replaced. A full ServerStorage copy was not taken (58k backup instances, Studio already near its memory limit). If a later shot needs to move or change an existing object, that object gets backed up first.

## Recording on this PC

- Main monitor is **2560×1440 at 180 Hz** (second one 1920×1080). Studio's viewport is larger than 1920×1080, so a 16:9 crop of it downscaled to 1080p is true full-quality 1080p.
- **OBS Studio 32.2.2 is installed** (RTX 4070 SUPER, NVENC). No ffmpeg. NVIDIA overlay (Alt+F9) and Xbox Game Bar (Win+Alt+R) record the whole screen or window including Studio's toolbars, so they would need cropping afterwards; Studio has no built-in video recorder.
- **Recommended: OBS** with a new profile and scene collection "Roblox Trailer" (wiktor's current "Bez tytułu" profile left untouched): canvas and output 1920×1080, 60 fps, NVENC high quality, MP4 to Videos, Window Capture of Roblox Studio cropped to a 16:9 part of the viewport.
- **wiktor's keys:** press the OBS record hotkey, then F8 in Play. The countdown covers the gap; when the PLAY NOW! card fades, press the hotkey again. No key during the run (it would switch AFK off).
- **Zero-key option (needs wiktor's yes):** turn on OBS's built-in local WebSocket server (currently off). Then Claude can start OBS recording and the cinematic together, and wiktor presses nothing.
- **Upload:** wiktor uploads the MP4 in the Creator Dashboard (game > Places/Configure > media/thumbnails, add video) themselves. Roblox's current length/size limit is being checked by the cloud team.
