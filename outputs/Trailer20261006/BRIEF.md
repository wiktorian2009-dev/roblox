# Design team brief (relayed by the coordinator, 2026-10-06 23:04Z)

Source: cloud ultracode run (research, 3 concepts, judges, synthesis, adversarial reviews). Winner: "The Little Plow's Big Trip", 29.5 s, 11 shots. Coordinator notes:
- Claude's engine and device findings (README.md, DESIGN.md) win where they differ; tell wiktor what changed.
- wiktor's dashboard names the game "Build And Plow Snow". Cards stay title-free (the page shows the name).
- Roblox page-video facts (60 s cap, 1920x1080, under 100 MB, 3 free uploads a month, private games refused, PLAY NOW! possibly rejected as promotional) come from search snippets only: unverified.
- The full treatment (with ffmpeg commands) is in project files this PC cannot read; ask the coordinator for a named section if needed.

## 1 Goal
29.5 s page trailer, real Studio Play footage, 1920x1080 H.264 MP4: bright, calm, truthful, readable muted on a phone. One Play session: pass A ending on PLAY NOW!, then the end shot again with card B (tagline only, safer). Deliver A, B and silent copies.

## 2 Keep the groundwork
Claude's engine and device findings win where they differ.

## 3 Shots (start / length, s)
1. 0 / 2.4 Starter field: REAL plow on AFK (starter build) charges a low camera that backs off and cranes over; roll with 35+ studs of straight fresh snow ahead. Text "PLOW SNOW / TO EARN SNOW" 0.4-2.4.
2. 2.4 / 1.2 Lobby: fast push up the lantern path into the snow globe; no FROSTFALL text or padlocks.
3. 3.6 / 2.2 Unnamed bay: parked plow, starter blade; wider common blade on the pedestal. Text "ROLL PARTS / BUILD YOUR PLOW" 4.0-7.0.
4. 5.8 / 1.4 Orbit, plow now wearing that blade (swap on the cut).
5. 7.2 / 3.0 Starter field off the AFK lanes: wider lane, drift at 0.9 s. Text "DRIFT FOR BONUS SNOW" 8.1-10.0.
6. 10.2 / 3.0 Desert egg: plow stops beside it, no pet spawn. Text "HATCH PETS" 10.6-13.0.
7. 13.2 / 2.6 Crystal: crane past the mine wheel to the Heart; hero C (red cab, stronger real build).
8. 15.8 / 2.2 Absolute Zero: push past the Heart Engine to the open Portal.
9. 18.0 / 4.8 Sakura bridge head: Candy's fog really fades from 0.1 s; plow crosses from 2.4 s, camera rises. Fallback: Candy already open.
10. 22.8 / 2.7 Real minis on the best field, high crane. Fallback: puppet minis.
11. 25.5 / 4.0 Candy chocolate path: plow stops at 1.0 s, slow push, subjects at 0.62-0.82 of frame height. Fallback: Starter field.
Rule: anything not matched to code or a real reference = simpler move; no drift reference = no drift text.

## 4 Text and look
All text in a SafeFrame: centred 16:9, 98% of the largest fit, clear of the menu button. TextScaled caps at 100 px: use TextSize 100 and UIScale = font size x SafeFrame height / 100, fit to 0.9 width; pops multiply it. Font size / centre y (fractions of SafeFrame height): callouts 0.12 / 0.19; card A: PLAY NOW! 0.27 / 0.24 (letters 200+ px), tagline 0.10 at 0.45 / 0.55; card B: tagline 0.14 in three lines at 0.20 / 0.34 / 0.48; nothing below 0.82. White text, navy stroke (ApplyStrokeMode/ScaledSize); FredokaOne, PLAY NOW! in LuckiestGuy. Tagline "PLOW SNOW. ROLL PARTS." / "HATCH PETS." One timeline from ROLL; PLAY NOW! at 25.9 s; no title. Look: per-area lighting presets per cut, small deltas.

## 5 Director
- Gate: Claude's gate plus TrailerMode (rehearse/take) and an expiring os.time() token, set on the Server after Play starts (else in Edit).
- Before ROLL the helper sets the temp profile (no DataStore writes) via game admin functions: tutorial done; World 1, Portal, Sakura open; Snow for Candy; minis a Candy player can own; 3 common pets; starter parts, no Aurora Wheels or Haunted part; blank HumanoidDescription; SuppressEvents; seated, AFK on. Then its own clock from ROLL (GetServerTimeNow): equip hero C's parts at 10.3 s (optional, for the minis); Candy unlock at 18.1 s; focus areas streamed 4+ s ahead; EndTest after DONE, cap ROLL_A + 60 s. No client-to-server calls after ROLL; skip shots that never stream in.
- Order: magenta slate = SafeFrame (until CropOK or 10 s); warm-up one world at a time; wait for the plow; 0.5 s black, TRAILER_ROLL_A, pass A; 0.5 s black, TRAILER_ROLL_B, shot 11 + card B; 0.5 s black; 0.5 s magenta; TRAILER_DONE; undo.
- Puppets: anchored, stripped assembler clones (explicit part ids) moving as code and references show; default R15 driver if real plows have one. Pets only where the pet code puts them, never Verity.
- Hide locally each frame: other UI, chat, prompts, name tags, tutorial beams; every Help Yard NPC and non-puppet humanoid; world GUIs with names, numbers, prices or timers; padlocks, Frost King; the real plow where a puppet replaces it.
- Rehearsal = the same run, recorded; round 1 first films real references (roll, equip, hatch, drift via MCP input, minis).

## 6 Recording
- Studio maximised in front, panels closed, terminal behind, Do Not Disturb, OBS cursor off. OBS profile/collection/scene "Trailer", Display Capture: with ffmpeg (present or permitted) record full screen and crop from the take's magenta frames, else Crop/Pad to the rehearsal box. 60 fps if every shot logged 58+ fps with OBS on, else 30. Output to outputs\Trailer; audio: Studio only (Application Audio Capture).
- Start before F5: obs-websocket StartRecord if wiktor allowed it, else launch obs64.exe (bin\64bit) --profile/--collection/--scene Trailer --startrecording --minimize-to-tray --disable-updater, ended by the Output Timer (autoStartRecordTimer). Ready once a new file grows; never Stop-Process OBS. One approved PowerShell script: OBS, RAM watchdog (under 1.5 GB free: start_stop_play or TrailerAbort), DONE wait; rehearse these exact calls.
- Tell wiktor: "When I say ready, click Studio's title bar once and press F5 once, then touch nothing until Studio is back in editing; if it stays black for 20 s while still playing, press Shift+F5." (Claude's key if not F5; none if Claude starts Play.) If OBS fails: ffmpeg, else Game Bar.
- Cut at the black marks: A = 29.5 s from ROLL_A; B = A's first 25.5 s + 4 s from ROLL_B; crop to 1920x1080, CRF 18, 15 Mbps max, yuv420p, +faststart; -an silent copies. No ffmpeg: Windows.Media.Editing or Clipchamp numbers for wiktor. Check 29.4-29.6 s, 1920x1080, under 100 MB; full-size 1 fps contact sheet and 360 px grabs show no UI, names, avatars, prices, padlocks, placeholder text, paid or removed things, chrome, white-out.
- Sound: live game Sounds only; no music, voice or effects; keep a SoundId only if Roblox or wiktor made it; tell wiktor the licence is unconfirmed (silent copy safest).

## 7 Safety
Never restart Studio yourself. Back up the kit's containers (not the map) in ServerStorage and log the save point (STATUS.md, outputs\SAVE_POINTS.md). Ask wiktor to keep Codex off during Play. Show nothing priced, paid, removed or real; never publish, upload or spend Robux. Before the take wiktor saves and restarts Studio; under 3 GB free in rehearsal, split shots 1-8 and 9-11. After the take, park the kit disabled in ServerStorage.TrailerKit_Parked and clear the attributes. Refer to wiktor by name or they/them.

## 8 Deliver
Reply with 4 paths, lengths, sizes, 2-3 grabs, and: (1) Configure > Places > start place (94130990350526) > Videos may refuse a private game; going public is wiktor's call. (2) Upload B (safer) or A: free, 3 a month. (3) Review takes days; rejections use an upload. (4) Never the in-game Video asset upload (2,000 Robux).
