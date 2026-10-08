# Trailer director: implementation spec (DESIGN rev 2), 2026-10-07

Architect spec for the self-running page trailer of "Build And Plow Snow" (Studio place "money", 94130990350526). This revision implements the design team's 11-shot brief (BRIEF.md, "The Little Plow's Big Trip", 29.5 s) on top of the groundwork in README.md. Rev 1 (Cosmic / garage roll / hatch draft) is replaced; its engine, Lock/Restore and shot-engine parts are kept where still valid (sections 8, 11).

Override rule: where the brief conflicts with engine or device facts, the facts win. Every conflict is listed in section 15 ("Changes from the brief"). Line numbers are disk lines in `game/src` (live = disk for these scripts per STATUS.md) or `game/studio-snapshots`; with Studio open, use `script_read` line numbers, never `script_grep` ones (off by 2 to 12).

Studio was closed when this was written (v713 published before the PC restart). Coordinates marked **(scout)** come from build scripts or notes, not from a live read, and must be confirmed in rehearsal round 0 (section 14.1).

---

## 0. Ground rules (not negotiable)

- Studio only, temp profile only: ServerStorage.BalanceTestMode = true (DataService L15: no store, never saved). Never touch real data, never publish, never spend Robux.
- One velocity writer for plows: PlowDriveClient's Heartbeat. The trailer only feeds it inputs it already reads: AFK attributes (L255-258) and the Studio test input `PlowTestMove` (L262-265, active only when PlowService sets `RS.PlowTestHooks` in BalanceTestMode, PlowService L19-20). Puppets are anchored visual clones moved by CFrame and have no physics.
- Travel only through TravelService (`ServerStorage.TravelTestHook`, TravelService L103-107) or PlowRegistry (`Spawn`, `Park`, `GoGarage`). Never pivot a seated character.
- Nothing priced, paid or removed on screen: no prices, rebirths, shovels, workbench, game-pass parts (Haunted set, Aurora Wheels), Verity pets.
- Never leave `Workspace.CurrentCamera` Scriptable after a run (Restore + an Edit check, STATUS lesson 2026-10-06).
- No client-to-server call after ROLL. The server runs its own clock from ROLL (`workspace:GetServerTimeNow()`).
- wiktor: by name or they/them.

---

## 1. The trailer at a glance

One Play session records pass A (29.5 s, ends on PLAY NOW!) and pass B (shot 11 again with card B). All times are seconds after ROLL_A.

| # | id | start / dur | Place | Subject (real / puppet) | Text (brief §4) |
|---|---|---|---|---|---|
| 1 | S01_StarterAfk | 0.0 / 2.4 | Starter field | REAL plow, starter build, AFK | PLOW SNOW / TO EARN SNOW, 0.4-2.4 |
| 2 | S02_LobbyPush | 2.4 / 1.2 | Frostfall lantern path → snow globe | camera only | – |
| 3 | S03_Bay | 3.6 / 2.2 | own garage bay (Bay_1) | bay preview (starter blade) + Wide Clearing Blade on Pedestal_2 | ROLL PARTS / BUILD YOUR PLOW, 4.0-7.0 |
| 4 | S04_BayOrbit | 5.8 / 1.4 | same bay | bay preview now wearing blade_wide | (continues) |
| 5 | S05_WideLane | 7.2 / 3.0 | Starter field | REAL plow, wide blade, fresh lane | none (drift text removed, §15) |
| 6 | S06_DesertEgg | 10.2 / 3.0 | Desert egg | PUPPET hero C stops beside the egg | HATCH PETS, 10.6-13.0 |
| 7 | S07_Crystal | 13.2 / 2.6 | Crystal mine wheel → Crystal Heart | PUPPET hero C (optional) | – |
| 8 | S08_AzPortal | 15.8 / 2.2 | Absolute Zero Heart Engine → Portal | camera only | – |
| 9 | S09_CandyGate | 18.0 / 4.8 | Sakura east end, Candy gate | REAL hero C crosses at 20.4; real Candy unlock at 18.1 fades the fog | – |
| 10 | S10_Minis | 22.8 / 2.7 | best field (MiniField, expected Candy) | REAL minis (MiniPlowClient) | – |
| 11 | S11_CandyPath | 25.5 / 4.0 | Candy main path at the wafer bridge | REAL hero C stops at 26.5 | card A: PLAY NOW! 25.9, tagline 26.3 |
| – | black | 29.5 / 4.0 | – | plow reverses to its mark (unseen) | – |
| 11B | S11_CandyPath (B) | 33.5 / 4.0 | same | REAL hero C stops at 34.5 | card B 33.9-37.5 |
| – | end | 37.5 / 1.0 | – | 0.5 s black, 0.5 s magenta, TRAILER_DONE | – |

Cut lists: A = [ROLL_A, ROLL_A + 29.5]. B = [ROLL_A, ROLL_A + 25.5] + [ROLL_B, ROLL_B + 4.0] with ROLL_B = ROLL_A + 33.5.

Real-plow residency: Starter field until 10.25 (shots 1, 5), then Sakura/Candy (shots 9-11). Shots 2-4, 6-8 and 10 are camera shots away from the character. Why shots 6-7 use puppets: section 6.6.

---

## 2. Gating and start

### 2.1 Attributes, set in Edit before F5

| Where | Attribute | Value |
|---|---|---|
| ServerStorage | `BalanceTestMode` | `true` (read once at server start: DataService L15, PlowService L19, TravelService L103, ActivityService L347, ContractService L25) |
| ServerStorage | `TrailerMode` | `"rehearse"` or `"take"` (anything else = inert) |
| ServerStorage | `TrailerToken` | expiry as `os.time()` seconds, e.g. `os.time() + 15*60` when set |
| ServerStorage | `TrailerSplit` (optional) | `"1-8"` or `"9-11"` only if RAM forces a split take (section 12.7) |

All three are set in Edit (with wiktor's consent for Studio writes) immediately before F5, and cleared after the session (section 14.5). Setting them in Play does nothing: modules read them at server start.

### 2.2 ServerScriptService.TrailerBootstrap (Script)

```lua
local RunService = game:GetService("RunService")
local SS = game:GetService("ServerStorage")
if not RunService:IsStudio() then return end
local mode = SS:GetAttribute("TrailerMode")
if mode ~= "rehearse" and mode ~= "take" then return end
local token, now = SS:GetAttribute("TrailerToken"), os.time()
if type(token) ~= "number" or token < now or token > now + 3600 then warn("[Trailer] token missing/expired - inert") return end
if SS:GetAttribute("BalanceTestMode") ~= true then warn("[Trailer] needs BalanceTestMode=true - inert") return end
local kit = SS:FindFirstChild("TrailerKit")
if not kit then warn("[Trailer] TrailerKit missing") return end
local ok, err = pcall(function() require(kit.TrailerServer).Start(kit, mode) end)
if not ok then warn("[Trailer] start failed: " .. tostring(err)) end
```

The token stops a forgotten attribute from auto-running a later Play; IsStudio keeps live servers inert even if the place is saved with the attributes.

### 2.3 Start, manual start, abort

- **Automatic start.** TrailerServer.Start waits for the player's profile (`BalanceTestSession` attribute, DataService L133), runs `Prepare` (section 3), clones the director gui, then sets player attribute `TrailerAuto = mode`. The client director starts on its own once `LoadingScreenActive == false` and `TrailerAuto` is set. Nobody presses anything after F5.
- **Manual start (re-runs in the same Play).** Player attribute `TrailerGo = true`, set on the Server by Claude through the MCP. Only honoured when the client's state is `idle`, `done` or `aborted`.
- **F8 abort.** `UserInputService.InputBegan` with `KeyCode.F8` (no gameProcessed filter) while running: the client restores everything locally at once. Because no client-to-server call is allowed after ROLL, the server does not hear about it; its schedule runs on harmlessly (temp profile) until its cap. After an F8 abort, stop Play (Shift+F5 or MCP).
- **Server-side abort.** Player attribute `TrailerAbort = true` (Claude via MCP). Both sides watch it: the client restores, the server stops its schedule and cleans up.
- Also abort on `Humanoid.Died`, `CharacterRemoving`, `script.Destroying`, and any error in the run (`xpcall`). Restore runs exactly once.

### 2.4 Run order (one Play session)

| Step | What the viewer sees | What happens |
|---|---|---|
| 1 Slate | SafeFrame filled magenta (255, 0, 255), black outside it | Lock (section 8). Lasts until player attribute `CropOK` (server, via MCP) or 10 s. Gives the crop box (section 12.4). |
| 2 Warm-up | black | One world at a time. World 1: pre-ROLL `Stream` requests for the Desert egg, Crystal Heart/headframe and AZ engine/portal (lobby and garage are Persistent), then the camera parks 0.6 s at each first/last key of shots 2, 3, 4, 6, 7, 8. World 2: client sends pre-ROLL `Stream` requests for the Sakura gate, the Candy path and the Candy fields, waits for each `need.parts` check (max 8 s each), then parks the camera at shots 9-11 keys. Pathfinding for the Sakura drive is computed now (section 5.3). |
| 3 Wait for the plow | black, small grey "READY CHECK" (rehearse mode only) | Character on Starter, hull seated, AFK on (Prepare). The client gate (section 6.1) waits for a fresh straight run. Timeout 120 s → abort with reason. |
| 4 Arm | black | Client fires `ArmRoll` (last client-to-server message). Server sets `ROLL_A = GetServerTimeNow() + 0.7`, player attributes `TrailerRollA` and `TrailerRollB = ROLL_A + 33.5`, prints `[Trailer] TRAILER_ROLL_A <serverTime>`. |
| 5 Black | 0.5 s pure black before ROLL_A | cut marker |
| 6 Pass A | shots 1-11 + card A | client timeline from `TrailerRollA`; server schedule (section 2.5) |
| 7 Gap | 4.0 s black (29.5-33.5) | plow reverses to its mark (section 6.11) |
| 8 Pass B | shot 11 + card B (33.5-37.5) | `[Trailer] TRAILER_ROLL_B` printed by the client at its first frame |
| 9 End | 0.5 s black, 0.5 s magenta | client prints `[Trailer] TRAILER_DONE unixms=…`, then Restore |
| 10 Stop | Studio back in Edit | server tries `StudioTestService:EndTest("done")` in pcall at ROLL_A + 40; if Play was started with F5 that call may not be allowed, so Claude stops Play through MCP `start_stop_play` when it sees TRAILER_DONE (or wiktor presses Shift+F5). Server cap: full cleanup at ROLL_A + 60 regardless. |

The client prints `unixms = DateTime.now().UnixTimestampMillis` with every marker (ROLL_A, ROLL_B, DONE, slate start/end) so cut points can be found without ffmpeg (section 13).

### 2.5 Clocks and the server schedule

Both sides use `workspace:GetServerTimeNow()`. The client's shot clock is `t = GetServerTimeNow() - TrailerRollA`. The server schedule (each step `pcall`, logged `[Trailer] t=<x> <action> ok|fail`):

| t | Server action | Code path |
|---|---|---|
| -0.7 | set `TrailerRollA`, `TrailerRollB`; AFK hold already on | – |
| 1.0, 9.0 | stream Desert egg (128, 8, -262) | `player:RequestStreamAroundAsync(pos, 10)` in `task.spawn` |
| 2.45 | AfkOff, clear hold | AfkService `setOff` equivalent (L55-59): AfkPlow/AfkField/AfkLane = nil |
| 2.50 | `d.Plow.Build.Blade = "blade_wide"`; `PlowRegistry.Park(player, "trailer")` | PlowService despawn L189-199 |
| 2.70 | `PlowRegistry.Spawn(player)`; retry once at 3.2 | PlowService L659-665 → spawnVehicle L212-280 (rebuilds from `d.Plow.Build`) |
| 4.0, 11.0 | stream Crystal Heart (236, 10, 125) and headframe (192, 10, 100) | – |
| 5.00 | bay preview swap: `GarageTestHook:Invoke("publish", player, d)` | PlowService L762-783 → publishBay L351-358 → PlowGarageClient swapSlot L181-206 |
| 6.0 | stream Sakura arrival (1590, 3, 0) and Candy gate (1825, 5, gateZ) | – |
| 8.0, 13.0 | stream AZ (-315, 10, 215) | – |
| 10.20 | `d.Plow.Build = HeroC` (all four slots) | section 3 |
| 10.25 | `TravelTestHook:Invoke(player, "Sakura", true)`; retry once at 10.9 | TravelService L39-83: Park, stream, pivot, 0.35 s, Spawn of the saved build |
| 12.0 | stream Candy path (1940, 6, 55) and Candy fields (2021, 4, 55) | – |
| 18.10 | real Candy unlock (section 6.9) | StageService L36-39 steps + AdminHooks.ReapplyStages |
| 38.5 | state `done`, EndEvent, AFK hold cleared | – |
| 40.0 | `StudioTestService:EndTest` attempt | pcall |
| 60.0 | hard cap cleanup | – |

The server never needs the client after ROLL: everything it does is either on its clock or reacts to its own observations (`TrailerAbort`, death, leaving).

---

## 3. Profile prep (`Prepare`, server, before ROLL)

Runs once per Play, in this order, each step in pcall and logged. `d = DataService.Get(player)` read inside the function. Guard: `IsStudio`, valid TrailerMode/Token, `BalanceTestMode == true` and `player:GetAttribute("BalanceTestSession") == true`. The Studio temp profile without BalanceTestMode is refused: the travel/plow/garage test hooks would not exist.

| # | Step | How (code path) |
|---|---|---|
| 1 | Tutorial done | `PlowTestHook:Invoke(player, "TutorialProgress", "Main", "Done", {Status = "done"})`, `task.wait(0.06)` (rate limit, PlowService L740), same for `"Garage"` (L584-608). No `Index` (it logs an analytics funnel step, L604-606). |
| 2 | World 1 + Portal + Sakura open, Candy locked | `d.Stages[id] = true` for Starter, Desert, Cursed, Crystal, Retro, Jungle, AbsoluteZero, Portal (Sakura opens with Portal: StageService isOpen L8-14); `AdminHooks.ReapplyStages:Fire(player)` (L16-23). |
| 3 | Snow for Candy | `d.Snow = StageConfig.ById.Candy.Cost + 1` (410,000,000,001; StageConfig L22) and `DataService.SetStat(player, "Snow", d.Snow)`. Direct write, not AddSnow (AddSnow would raise SnowEarned and could pop quests). |
| 4 | Lobby machines unlocked (no black "LOCKED" silhouettes, MachineLocksClient L13-43) | `d.Upgrades.M_Expansion2 = true`, `d.Upgrades.M_Expansion5 = true` (UpgradeConfig L249-252), `AdminHooks.ReapplyUpgrades:Fire(player)`. Verify in round 0 that ReapplyUpgrades sets `UnlockFuser`/`UnlockCraft`; else frame the machines out (shot 2 does). |
| 5 | Pets: 3 commons a Candy player has | `Snow Bunny`, `Penguin` (Snowy Egg), `Fennec Fox` (Desert Egg) (PetConfig L28-35): `d.Pets[n] = max(1, …)`, `d.PetIndex[n] = true`, `d.EquippedPets = {…}`, attribute `EquippedPets`, `DataRefresh:FireClient`. Base PetSlots = 3 (UpgradeConfig L160), so no slot upgrades. Never a Verity pet. |
| 6 | Parts | Own `blade_wide` and the HeroC parts at level 1 (`d.Plow.Parts[id] = max(1, …)`, `d.Plow.Levels[id] = d.Plow.Levels[id] or 1`). Build = starter set (PlowConfig C.Starter L36). Equipped build never contains game-pass parts (PassConfig L21-31: Haunted set, `gear_aurorawheels`), even though Studio grants the creator's passes to the test profile (STATUS save point 54). |
| 7 | Pedestal offer | `d.Plow.Offers = {["2"] = {Part = "blade_wide", Token = GUID, Price = 120, Seq = 1, Left = 600}}`, pedestals 1 and 3 empty. |
| 8 | Bay without entering the garage | `GarageTestHook:Invoke("assign", player, d)` (PlowService L775-777 → assignBay L359-372). Sets `GarageBay`/`GarageLease`, OwnerUserId, Build, Offer attributes; PlowGarageClient builds the bay preview (refreshPreview L207-235). `InGarage` stays false, so AFK is not blocked (AfkService L45). A lone player gets Bay_1. |
| 9 | Minis a Candy player can own | `d.MiniPlows = {Level = 7, V = 1}`: 5 minis (PlowConfig C.Minis L539-548, level 7 = 190B, below the Candy gate). MiniPlowService picks it up within RateRefresh 4 s (L121-124). Never set Mini* attributes directly. |
| 10 | Blank avatar | `hum:ApplyDescription(Instance.new("HumanoidDescription"))` on the server, before the plow spawns. Server also creates the puppet driver rig: `Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)` → `ReplicatedStorage.TrailerRuntime.DriverRig` (Play-only folder; server-only API). |
| 11 | No random events | `ActivityTestHook:Invoke("Event", nil, "LuckyWind", 900)` (ActivityService L349-355). The scheduler starts an event 90-180 s after server start (ActivityConfig L24-25, ActivityService L333-342) and skips while one runs. LuckyWind has no snowfall; its camera emitters are hidden anyway (section 8). Frost King cannot auto-spawn in BalanceTestMode (FrostKingService L722, FrostKingConfig L50); Help Yard offers are held in BalanceTestMode (ContractService L328, L336). |
| 12 | Seated, AFK on | `TravelTestHook:Invoke(player, "Starter", true)` → `PlowRegistry.Spawn(player)` → AfkOn: copy AfkService L70-72 in order (`AfkField = "Starter"`, `AfkLane = max(3, BladeWidth × 0.8)`, `AfkPlow = true`), checks as AfkService `blocker` (L43-54), then `hold[player] = "Starter"`. The hold re-asserts AFK 0.25 s after it drops (max 6 per 10 s), so a stray key only makes the plow hesitate (AfkDriftClient L121-133 fires `false` on any key or gamepad input). |
| 13 | Done | player attribute `TrailerPrepared = true`; then `TrailerAuto = mode`. |

`HeroC = {Blade = "blade_katana", Engine = "engine_blossom", Gear = "gear_bamboo", Body = "body_starter"}`: the original red cab ("The original red plow cab", PlowConfig L315) with Sakura-band parts (Band 8, none Role "P", none from a pass). Blossom Turbine Speed 39.1 (L183-184). Round 1 checks that it reads well on camera and that MiniField becomes a Candy field with it (section 6.10); alternative blade `blade_lotus`.

The client sets `SuppressEvents = true` locally at Lock (ContractClient L145, FrostKingClient L767, PassClient L274 read it).

---

## 4. Architecture

### 4.1 Objects

```
ServerScriptService
  TrailerBootstrap               Script (section 2.2)
ServerStorage
  TrailerKit                     Folder (never replicates)
    TrailerServer                ModuleScript  Start, Prepare, schedule, pre-ROLL requests, AFK hold, cleanup
    TrailerDirectorGui           ScreenGui  ResetOnSpawn=false, IgnoreGuiInset=true, ScreenInsets=None,
                                            DisplayOrder=1000, ZIndexBehavior=Sibling
      TrailerDirector            LocalScript  loader: start/abort/lifecycle
      TrailerClient              ModuleScript  Lock/Restore, hide list, camera, timeline, plow driver
      TrailerText                ModuleScript  SafeFrame, slate, callouts, cards (section 9)
      TrailerPuppets             ModuleScript  puppet plows, driver, puppet minis (section 7)
      TrailerMath                ModuleScript  easing, Catmull-Rom, springs, pure pursuit; SelfTest()
      TrailerShots               ModuleScript  DATA: Config, Profile, Shots, Cards
      TrailerRefs                ModuleScript  DATA: recorded reference tracks + SeatWeld (round 1 output)
ReplicatedStorage (Play only, created by TrailerServer.Start)
  TrailerRemote                  RemoteEvent
  TrailerRuntime                 Folder: DriverRig
```

Every ModuleScript has no top-level side effects (only `game:GetService` and local functions), so Edit can `require` them for the compile/data check (section 14.2).

### 4.2 Remote protocol (pre-ROLL only)

- Client → server: `TrailerRemote:FireServer("Req", reqId, action, args)`, actions `Stream {pos}` (≤ 10 s, each axis < 10000), `RepublishBay` (garage light, section 6.3), `Ready`, `ArmRoll`. Validation: type, whitelist, Guard, gui present. `ArmRoll` is accepted once per run.
- After `TrailerRollA` is set the client's `request()` refuses to fire and prints `[Trailer] BUG: request after ROLL` (so a violation shows in rehearsal).
- Server → client: player attributes only (`TrailerAuto`, `TrailerRollA`, `TrailerRollB`, `TrailerState`, `TrailerPrepared`, `CropOK`, `TrailerGo`, `TrailerAbort`).
- Claude reads progress from Output (`get_console_output`, client and server prints) and server attributes.

---

## 5. Driving the real plow

### 5.1 AFK (shot 1)

The real AFK autopilot (PlowDriveClient `afkMove` L206-254) drives a lawnmower route over `AfkField`: lanes along the long axis (`alongX = W >= D`), inset `C.Afk.Inset = 4`, lane spacing `AfkLane = 7 × 0.8 = 5.6` for the Basic Blade (width 7, PlowConfig L44-45; LaneShare 0.8, L527-528). Starter build on fresh snow: Starter Engine 24 studs/s × PlowingSpeedFactor 0.6 = 14.4 studs/s (L134, Drive table). 2.4 s ≈ 35 studs: that is the brief's "35+ studs".

### 5.2 Scripted input (shots 5, 9, 11)

The client director writes the local player attribute `PlowTestMove = Vector3.new(steer, 0, -throttle)` (reverse: positive Z), the same move vector AFK and the keyboard produce; PlowDriveClient reads it only while AFK is off and `RS.PlowTestHooks` is set (L255-271). A client-local attribute never replicates, so this is not a server call. Steering: pure pursuit on a waypoint list (lookahead 8 studs, `steer = clamp(1.4 × angle, -1, 1)` like AFK L250-252), throttle from a speed target with a braking profile (`decel ≈ topSpeed / AccelTime × BrakeFactor 2.3`, Drive table), tuned from round 1 logs. Restore sets `PlowTestMove = nil`.

### 5.3 Sakura → Candy route (computed during warm-up)

- `G` = the `Stage paywall` part of the `StagePaywall_Model` whose `Stage` attribute is `"Candy"` (StageClient L72-116 finds the same models). It sits in the Candy arch at Sakura's east end, x ≈ 1825 **(scout)** (STATUS L962 "gates Candy@1825"). `a` = horizontal unit vector from Sakura into Candy (+X side); `s` = right of `a`.
- Leg 1: `PathfindingService:CreatePath({AgentRadius = 4, AgentHeight = 6, AgentCanJump = false})` from 10 studs ahead of `TravelPoints.Sakura` (1590, 2, 0) to `P_hold = G − 34·a` on the ground.
- Leg 2: `P_hold → G → bridge deck → Candy entrance (1894, 7.2, 55) → P_wait (1928, gy, 55)`. Deck waypoints: the invisible walkable deck segments of the Sakura-Candy bridge under `workspace.World2.Bridges` (STATUS L968), top centres sorted along `a`. The starter plow crossed all World 2 links at full speed (STATUS save point 45).
- Leg 3: `P_wait → P_stop (1962, gy, 55)` on Candy's main path over the wafer bridge (1958, 5, 55) across the ChocoRiver **(scout)**.
- `gy` = ground from a downward raycast (exclude Snowplows, characters, FollowingPets).

---

## 6. Shots: feasibility, keys and fallbacks

Key format as rev 1: `path` keys `{t, pos, look, fov}` (world studs, centripetal Catmull-Rom), `follow` keys `{t, offset, look, fov}` in the plow's yaw frame (−Z = front), `orbit {center, radius, height, a0, a1, lookHeight, fov0, fov1}` (0° = +X, 90° = +Z). FOV values are the vertical FOV of the 16:9 crop (FOV correction, section 9.1). Every cut pulses `LightingSnap` (BiomeLighting L204) because BiomeLighting probes the camera while it is Scriptable (L126-138). Values are first guesses to be tuned in round 0.

### 6.1 Shot 1, Starter field, REAL plow on AFK

- Feasible as briefed. The plow is already AFK on Starter after Prepare.
- **Gate (how the lane is picked):** the client recomputes AFK's own route (copy of L213-236) and arms when: the current AFK target is a lane end and the hull heads at it (yaw error < 8°, yaw rate < 0.25 rad/s over 0.3 s); distance to that lane end ≥ max(speed, 14.4) × (0.7 + 2.45) + 38 + 4 + 4 ≈ 91 studs (review fix: shot 5 continues the same lane from the 2.40 point, so the lane must hold both shots); speed ≥ 12 studs/s; preferably hull X < 45 (so the village movers, gated to HRP within 180 studs of the village, FrostfallClient L96-97, run during shot 2; preference dropped after 60 s). Freshness: AFK visits a lane once per sweep (~10 lanes × ~11 s), and Starter tiles regrow one phase per 8 s (SnowStages Starter RegrowSeconds 8, MaxPhase 3), so any lane ahead is full.
- Keys (follow plow, posTau 0.06, yawTau 0.25): `t0 offset (0.8, 1.3, -10) look (0, 1.6, 0) fov 60` → `t0.35 (1.5, 1.8, -7.5)` (camera backs off slower than the plow, so it gains) → `t0.7 (1, 5, -2) look (0, 1, -4) fov 64` → `t1 offset (0, 11, 4) look (0, 0, -10) fov 62` (craned over, looking down the fresh lane).
- Fallback: none needed inside the take; if the gate never arms in 120 s the run aborts before ROLL.

### 6.2 Shot 2, lobby lantern path into the snow globe

- Camera only. Village is Persistent; globe at `FrostfallVillage.Snowglobe` (-102, 11, -282); arrival (-167, 4.7, -282) faces +X along the lantern path.
- Keys (path, ease InQuad = accelerating push): `t0 pos (-172, 6.5, -282) look (-102, 10, -282) fov 64` → `t1 pos (-114, 11, -282) look (-101, 11, -282) fov 52`.
- No FROSTFALL text: the world-GUI rule (section 8) disables every SurfaceGui/BillboardGui. If round 0 finds FROSTFALL as geometry (letters), set `LocalTransparencyModifier = 1` on that model during the shot, or raise the path so it is out of frame. Pet Fuser (-85, 0, -235) and Crafting (-137, 0, -331) are 47-49 studs off the path axis and unlocked in Prepare.
- Fallback: the same path (Persistent area, cannot fail to stream).

### 6.3 Shot 3, garage bay with the blade on the pedestal

- Feasible without entering the garage: Prepare assigned Bay_1 (pivot (-377, 0.2, -237), faces −Z; Pedestal_2 (-359.8, 0.2, -237); Lift (-377, 0.2, -231); README/rev 1 live read). Keys are stored in bay space (`ref = "Bay"`, resolved from `GarageBay`), world values below are for Bay_1.
- Keys (path, ease InOutSine): `t0 pos (-366, 9.5, -262) look (-368, 3.5, -234) fov 58` (front, car on the lift and the pedestal row) → `t0.55 pos (-369, 8, -248) look (-362, 5, -238) fov 48` → `t1 pos (-366.5, 6.6, -239.5) look (-359.8, 6.2, -237) fov 34` (between lift and pedestal, looking +X at the floating blade; the lift is behind the camera).
- From t ≈ 5.0 (u ≈ 0.64) the lift car is ≥ 80° off-axis, so the server's preview swap at 5.00 is not in frame.
- Pedestal 2 light: PlowGarageClient only turns it on during a bay refresh while the camera is within 120 studs (L272), and Prepare's assign refreshes the bay while the camera is elsewhere. So the client sends a pre-ROLL request and the server re-publishes the bay (`GarageTestHook "publish"`) while the warm-up camera is parked in the bay.
- Fallback: same path (garage is Persistent).

### 6.4 Shot 4, orbit, plow now wearing the blade

- The swap is the real equip path minus the bay gate: `d.Plow.Build.Blade = "blade_wide"` (set at 2.50 for the respawn) is published at 5.00 with `GarageTestHook "publish"` → `Build` attribute → PlowGarageClient `refreshPreview` → `swapSlot` (L181-206: new blade drops 5 studs over 0.55 s, gold sparks, sound). By 5.8 it has finished.
- Why not `PlowTestHook "Equip"`: `actions.Equip` (L516-528) calls `bayGate` (L386-399), which requires `InGarage` and the HRP within 39 studs of the bay, and refuses while driving; the character is on the Starter field driving.
- Keys (orbit, ref Lift): `center (-377, 3.2, -231) radius 13 height 5.5 lookHeight 2.6 a0 -125 a1 -65 fov0 50 fov1 46`, ease InOutSine. At a = −65° the pedestals are ~89° off-axis.
- Fallback: if the bay preview still shows the Basic Blade at 5.75 (client checks the `Blade` child's model name), the shot stays on the pedestal close-up (shot 3 end key, held with 2 studs of drift).

### 6.5 Shot 5, wide lane through fresh snow

- **Drift is not feasible.** A drift needs `driftKey`, `driftPad` or `driftTouch` (PlowDriveClient L99-127, start condition L476-480), which only real input sets; there is no attribute path. Input during the take is excluded. Rule "no drift reference = no drift text": the drift move and "DRIFT FOR BONUS SNOW" are dropped (section 15).
- Simpler real move instead: the respawned plow with the Wide Clearing Blade (width 12 vs 7, PlowConfig L44-47) cuts a visibly wider lane straight on from where the AFK lane stopped.
  - 2.40: client stores the old hull CFrame and lane axis.
  - New plow detected (new `Snowplows["Snowplow_"..UserId]` with seated character, ~2.8-3.2): reverse (`PlowTestMove (0, 0, 1)` with heading hold) until the hull is back at the old hull's along-lane position (≈ 10 studs, SpawnAhead 10, PlowConfig L491), so the wide cut joins the narrow lane without a gap.
  - Hold still until 6.20, then full throttle with heading hold along the lane. At 7.2 it is near cruise; by 10.2 it has covered ~38 studs. Review fix: it brakes to a stop at min(45, lane end − 4) studs past the join (lane end = the AFK route's end point ahead, stored at 2.40), and fewer than 42 studs of lane left at 2.40 means the fallback.
- Keys (follow plow): `t0 offset (-7, 6.5, 13) look (0, 0.5, -10) fov 60` → `t1 offset (-9.5, 8.5, 7) look (0, 0.5, -14) fov 62`, `orbitDeg {0, 18}`. The high left rear three-quarter shows the narrow AFK lane behind the join and the wide lane forming.
- Fallback: if no new plow by 4.0 or not aligned by 6.2: static high crane over the Starter field, `pos (35, 48, -360) look (35, 0, -288) fov 55` (lanes visible, no plow claim).

### 6.6 Shot 6, Desert egg: PUPPET hero C stops beside it

- **Why a puppet:** the real plow must be at the Candy gate at 20.4. From Desert that needs a travel at ~13.2 plus a ~235-stud Sakura drive (Sakura arrival (1590, 3, 0) to the gate at x ≈ 1825) at ≤ 39.1 studs/s plus spawn and acceleration: no slack. Travelling to Sakura at 10.25 gives ~6 s of slack. So the real plow cannot also do the Desert stop (rule: puppet only where a real plow cannot do the move).
- Egg `E` = `Workspace.StageEggs.StageEggs_Desert` pivot (128, 7.6, -262) (rev 1 live read); the egg floats only while the camera is within 220 studs (EggFloat L44: camera-gated, so it animates in this shot). Odds/price sign on `HatchAnchor` is a GUI → hidden. No hatch, no pet spawn.
- Puppet path (world, ground from raycast, ~3.5): start `S = (150, g, -280)` heading north-west, stop at `P = (136, g, -266.5)` facing (-0.72, 0, 0.69), 9 studs beside the egg. Enters at 10.7, stops at 12.3, holds to 13.2. Motion = recorded reference track (round 1, section 7.3), else the kinematic profile from PlowConfig.
- Camera keys (path, slow push): `t0 pos (150, 10.5, -244) look (130, 6, -260) fov 50` → `t1 pos (145, 9, -248) look (130.5, 5.5, -259.5) fov 46` (from the north-east looking south-west, away from the Desert fields, whose tiles do not exist this far from the character, SnowFieldClient builds within 170 studs of the HRP).
- Fallback: no reference and kinematic disabled → egg-only push-in (same keys). If the area is not streamed (`need.parts {pos = E, radius = 40, min = 40}`) → hold on the last shot-5 frame is not allowed (plow travels away), so use the lobby egg instead: `FrostfallVillage.EggDisplay` (-100.8, 3.8, -267.5) push-in `pos (-118, 8.5, -265) → (-110, 6.8, -266.5) look (-100.8, 6, -267.5)` (Persistent), no puppet.

### 6.7 Shot 7, Crystal: crane past the mine wheel to the Heart

- Objects exist (W1 remaster, STATUS L498-504; outputs/W1Remaster20261005/README.md "the Crystal Heart … a headframe with a spinning wheel"): `workspace.W1Remaster.Crystal.X_Heart` placed at (236, 3.7, 125) facing (280, 170) (place_crystal.luau L4, L61); `X_Headframe` near (192, 3.7, 100) (L79, free-spot search may move it up to 18 studs), its `Wheel` spins about Z at 0.6 rad/s via StageDecorClient, which animates when the **camera** is within 200 studs (StageDecorClient L29-34). Resolve both at runtime **(scout)**.
- Camera keys (path, ease InOutSine; `Wh` = Wheel position, `H` = Heart pivot): `t0 pos Wh + (8, -6, -14) look Wh fov 55` (low, looking up at the turning wheel) → `t0.5 pos Wh + (22, 6, -10) look lerp(Wh, H + (0, 16, 0), 0.6)` → `t1 pos H + (-24, 20, -26) look H + (2, 16, 4) fov 52`. With the scouted values: t0 ≈ (200, 13, 86), t1 ≈ (212, 23.7, 99).
- Hero C: puppet drives north past the Heart's east side, `H + (34, 0, -28)` → `H + (30, 0, 22)` (≈ (270, g, 97) → (266, g, 147)) from 13.5 to 15.6 at road speed, right of the Heart in the t1 frame. Optional: only with a reference track or the kinematic profile; otherwise camera only.
- Fallback: not streamed (`need.parts {H, 60, 80}`) → Crystal Pavilion in the village (-140, 0, -233): `pos (-140, 22, -240) → (-132, 20, -244) look (-140, 4, -233)` (Persistent).

### 6.8 Shot 8, Absolute Zero: past the Heart Engine to the open Portal

- Objects exist: `workspace.W1Remaster.AbsoluteZero.Z_HeartEngine` at the old FrozenHeartEngine spot, default (-327, 1.1, 183), rings spin about Y (place_az.luau L133-139); `workspace.AbsoluteZeroPortal` (-323, 28, 255) with PortalAnimator (camera-gated 600 studs, L37). The Portal stage is open, so its paywall is faded and non-colliding (StageClient L45-55); that is the "open Portal".
- Keys (path, ease InOutQuad; `HE` = engine pivot, `PT` = portal centre): `t0 pos (-303, 8, 176) look HE + (0, 9, 0) fov 56` → `t1 pos (-301, 15, 220) look PT + (0, -4, 0) fov 50`. Stays east of the S2 divider (x < -276, z 140-175, place_az.luau L3-4) and inside the AbsoluteZero lighting zone (Profiles L31); ends just outside the Portal zone radius 38 (L30).
- Fallback: not streamed (`need.parts {PT, 60, 80}`) → extend shot 7's last key by 2.2 s with 3 studs of drift.

### 6.9 Shot 9, Sakura side of the Candy gate: real unlock, fog fades, plow crosses

- **The unlock really fades the fog:** W2FogClient (L11-42) finds `MistBank_<From>To<Stage>` models in `workspace.World2.CloudCurtains` and, when player attribute `Stage_<Stage>` turns true, tweens every part to Transparency 1 over 2 s (Quad Out) and clears its emitters. Played live in Play (STATUS save point 44, screens/fog_candy_*.jpg). The bank is `MistBank_SakuraToCandy` at x ≈ 1855 **(scout name)**. StageClient fades the gate's paywall wall in 0.6 s and sets CanCollide false locally (L45-55).
- **Real unlock at 18.10 (server):** `if (d.Snow or 0) >= Cost then DataService.AddSnow(player, -Cost) end; d.Stages.Candy = true; AdminHooks.ReapplyStages:Fire(player)` — the same steps as StageService's `UnlockStage` handler (L36-39); that RemoteFunction can only be invoked by a client.
- Camera (path; `G`, `a`, `s`, `gY` from section 5.3): `t0 pos G − 20a + 7s + (0, gY + 5, 0)`, `look G + 45a + (0, gY + 7, 0)`, fov 56 → `t0.45 pos G − 18a + 6s + (0, gY + 7, 0)`, `look G + 40a + (0, gY + 4, 0)` → `t1 pos G − 13a + 3s + (0, gY + 18, 0)`, `look G + 70a + (0, gY, 0)`, fov 60 (camera rises over the arch to the bridge and Candy). Keep camera X ≤ 1815: the "Mist" lighting zone is x 1819-1892 (Profiles L17); Sakura zone is x < 1855 (L23).
- Plow: REAL hero C. Arrives at `P_hold = G − 34a` by ~17 s (travel at 10.25, Sakura spawn ~11.0, ~205 studs), holds; departs 19.55; passes G at ≈ 20.4 ("crosses from 2.4 s"); continues over the deck to P_wait (stops ≈ 22.8-23.2). Pets follow the character (PetFollow, FollowingPets folder), so they are in frame for real.
- The arch paywall's "CANDY KINGDOM 🔒 ❄ price" SurfaceGui is hidden every frame (section 8) from frame one, so no padlock or price shows at 18.0-18.1.
- Fallbacks: (a) plow not at P_hold by 19.4 → camera-only version (fog fade + rise). (b) Rehearsal shows the live fade failing → re-take with Candy unlocked in Prepare ("Candy already open", brief fallback): the fog is then hidden from join (W2FogClient L33) and the shot shows an open crossing.

### 6.10 Shot 10, real minis on the best field

- Real minis: MiniPlowService sets `MiniField`, `MiniBuild`, `MiniCount` (L77-93) for the best unlocked field for the equipped build (L57-68), refreshed every 4 s (L121-124); MiniPlowClient draws your own minis first as anchored scaled copies (Scale 0.38) on a lawnmower loop (MiniPlowClient L3-5, L241-252, L290-348). With HeroC (equipped at 10.20) and Candy open (18.10), MiniField is re-evaluated by about 23.1 at worst (the payout loop refreshes only after 4 s, Tick 1), and MiniPlowClient draws the new fleet up to 1.5 s after that (sync every 1.5 s). The primary variant therefore also needs `<Name>_Mini1` drawn on that field (review fix). Expected: `Candy_1` or `Candy_2` **(confirm in round 1)**; if round 1 shows a Sakura field, change the HeroC blade and re-check.
- Keys (path, relative to the MiniField record from `ReplicatedStorage.SnowFieldData`: centre `C`, long-axis unit `u`, `v` = unit from C toward the main path line z = 55): `t0 pos C − 46u − 38v + (0, 26, 0) look C − 11u` fov 50 → `t1 pos C − 36u − 44v + (0, 40, 0) look C + 9u + 4v` fov 48 (high crane, rising). For Candy_1 (2021, 4, 26), t0 ≈ (1975, 30, -12).
- Snow tiles exist on Candy fields because the character is at P_wait (1928, 55), within 170 studs of both (SnowFieldClient L21-22).
- Fallback: MiniField not a Candy field or `MiniCount` nil → puppet minis (section 7.4) on Candy_1 running MiniPlowClient's own route/pose math with HeroC at scale 0.38. If even that is not ready, extend shot 9's last key with drift.

### 6.11 Shot 11, Candy main path, plow stops, card A; pass B

- REAL hero C: holds at `P_wait (1928, gy, 55)`, departs 25.20, brakes to stop at `P_stop (1962, gy, 55)` at 26.5 (on the wafer bridge (1958, 5, 55) over the ChocoRiver, between Candy_1 and Candy_2) **(scout path name and stop point)**. The Candy entrance (1894, 7.2, 55) was reached on foot by pathfinding (STATUS L971).
- Keys (path, ease OutSine, slow push): `t0 pos (1938, 15, 77) look (1966, 9, 52) fov 50` → `t1 pos (1944, 13.5, 72) look (1966, 8.5, 52) fov 46`. Target: plow and pets between 0.62 and 0.82 of SafeFrame height; round 2 logs the projected screen Y (`Camera:WorldToViewportPoint` → SafeFrame fraction) and look.y is raised or lowered to fit.
- Card A at 25.9 / 26.3 (section 9.3); grade brightness -0.03, contrast +0.05.
- Gap 29.5-33.5: reverse `P_stop → P_wait` with heading hold (Hero C reverse ≈ 39.1 × 0.55 = 21.5 studs/s, ReverseFactor), settle by 33.0.
- Pass B (ROLL_B = 33.5): identical keys and plow move (departs 33.2, stops 34.5); card B (section 9.3).
- Fallback: plow not at P_wait by 25.1 → same keys without the plow (Candy path push) and the cards; pass B then also camera-only.

---

## 7. Puppets

### 7.1 Build

```lua
local Assembly = require(ReplicatedStorage.PlowAssembly)         -- L8-24: Chassis + Blade/Engine/Gear/Body templates
local m = Assembly.Build({Blade = "blade_katana", Engine = "engine_blossom", Gear = "gear_bamboo", Body = "body_starter"})
for _, d in ipairs(m:GetDescendants()) do
  if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery, d.CastShadow = true, false, false, false, true
  elseif d:IsA("Seat") or d:IsA("VehicleSeat") then d.Disabled = true
  elseif d:IsA("LuaSourceContainer") or d:IsA("Sound") then d:Destroy() end
end
m.Name = "TrailerPuppet_HeroC"; m.Parent = workspace.TrailerPuppets   -- client-local folder
```

Explicit part ids only (from `TrailerShots.Profile.HeroC`); never the profile build. The pivot is the ground-level root, like the real plow (`model:PivotTo(rootCF)` with rootCF on the ground, PlowService L223-227). Real plow wheels do not turn (everything is welded to the hull, PlowService L246-254), so a static puppet matches.

### 7.2 Driver

Real plows carry the seated character, so the puppet gets the default R15 driver: clone `ReplicatedStorage.TrailerRuntime.DriverRig` (server-made, blank HumanoidDescription, section 3 step 10), anchor all parts, `Humanoid.DisplayDistanceType = None`, `HealthDisplayType = AlwaysOff`, `EvaluateStateMachine = false`. Pose: an `Animator` plays the sit animation id read from the local character's `Animate.sit.SitAnim.AnimationId` (no hardcoded asset). Place the HRP at `seatCF * C0 * C1:Inverse()`, with `seatCF = m.PrimaryPart.CFrame * m:GetAttribute("SeatPos") * CFrame.new(0, -0.3, 0)` (PlowService L228, L244) and C0/C1 from the real `SeatWeld` recorded in round 1 (TrailerRefs.SeatWeld).

### 7.3 Motion ("as code and references show")

- Preferred: **reference track**. In round 1 the real hero C plow (same build) is travelled to Desert/Crystal and driven along the same path with `PlowTestMove`; the client logs hull CFrame relative to the stop pose at 30 Hz and prints it as JSON; Claude stores it in TrailerRefs. The puppet replays it (CFrame interpolation, `BulkMoveTo`).
- Else: **kinematic** along the path using the build's own numbers: top speed 39.1 (off-field), accel = top / AccelTime 1 × (1 + LowSpeedPull 0.3 near rest), brake = accel × BrakeFactor 2.3, yaw limited by TurnRate 1.6 × gear Turn (Drive table). No drift, no slides.
- Ground follow each frame: downward raycast at front and rear axle (excluding puppets), pitch from the two hits.
- No pets on puppets (pets exist only where PetFollow puts them, with the character), no sounds.

### 7.4 Puppet minis (shot 10 fallback only)

Clones at `C.Minis.Scale` 0.38 of HeroC (same strip), count 5, moved with a copy of MiniPlowClient's `route(fd)` and `pose(f, i, n, t)` (L290-340) and `C.Minis.Speed 8`, `LaneGap 5`, `Hover 0` (PlowConfig L549-551).

### 7.5 Real plow during puppet shots

During shots with puppets, the client sets `LocalTransparencyModifier = 1` on the real plow, character and FollowingPets (they are in World 2 then, so this is only a guard).

---

## 8. Hide list (applied every frame) and Lock/Restore

Everything is recorded on first touch (weak-key tables) and restored in a pcall per item. Re-enables by game scripts are caught by `GetPropertyChangedSignal("Enabled")` handlers (immediate) plus the per-frame pass in the `TrailerCam` RenderStep binding (`RenderPriority.Last`).

| Brief item | Concrete instances / scripts | Action |
|---|---|---|
| Other UI | every `PlayerGui` LayerCollector except TrailerDirectorGui (RNGGui, AfkDriftGui, StageToast, FrostfallToast, GarageInspectGui, PlowTutorial, AdminConsole, AdminToggle, StudioNoSaveNotice, PlayerGui BillboardGuis such as SnowPrompt / PetSign / "+N ❄") | `Enabled = false` |
| Core UI, menu | `StarterGui:SetCoreGuiEnabled(All, false)`; `SetCore("TopbarEnabled", false)` with retries; `MouseIconEnabled = false`. The Roblox menu button cannot be hidden, so the SafeFrame keeps clear of it (section 9.1). | restore per type |
| Chat | CoreGui Chat off; `TextChatService.ChatWindowConfiguration.Enabled`, `ChatInputBarConfiguration.Enabled`, `BubbleChatConfiguration.Enabled = false` | restore |
| Prompts | `ProximityPromptService.Enabled = false` | restore |
| Name tags | every Humanoid in Workspace: `DisplayDistanceType = None`, `HealthDisplayType = AlwaysOff`; BillboardGuis under characters off | restore |
| Tutorial beams | Beams whose Attachment0/1 is under the local character: PlowTutorialClient `TutorialBeamA0` (L258-259), PlowGarageClient `guide()` beam on the HRP (L413-424); call `TutorialDebug "Stop"` once (PlowTutorialClient L989-1005) | `Enabled = false` |
| Help Yard NPCs, other humanoids | Models named `HelperNPC` under `workspace.ContractYards` (ContractService L264-307; normally absent in BalanceTestMode), and any Model with a Humanoid outside {local character, `workspace.TrailerPuppets`, `workspace.FollowingPets`, mini container, `workspace.Snowplows`} | `LocalTransparencyModifier = 1` on BaseParts, Decals Transparency 1, BillboardGuis off |
| World GUIs with names, numbers, prices, timers | every BillboardGui and SurfaceGui under Workspace (except `TrailerShots.Config.WorldGuiKeep`, empty by default). Covers bay owner board + headshot, "YOUR GARAGE" (AlwaysOnTop, MaxDistance 400, PlowGarageClient L388-391), pedestal labels/prices, RollCooldown pills, EquipHint; StageEggs and EggDisplay odds/price/COMING SOON signs (EggFloat L106-112 re-enables them each frame → change handler); `PaywallSurface` on every `Stage paywall`; "MORE WORLDS COMING SOON"; Help Yard and machine signs (MachineLocksClient 🔒 labels); field name signs; FROSTFALL GUI text | `Enabled = false`, tracked via initial scan + `workspace.DescendantAdded` |
| Padlocks | PaywallSurface (above); locked machine silhouettes avoided by Prepare step 4; FROSTFALL / padlock geometry found in round 0 → `LocalTransparencyModifier = 1` per shot | as noted |
| Frost King | cannot spawn in BalanceTestMode (FrostKingService L722); guard: any Workspace model whose name starts with `FrostKing` | `LocalTransparencyModifier = 1` |
| Real plow where a puppet replaces it | section 7.5 | `LocalTransparencyModifier = 1` |
| Dev boxes | direct Workspace children named `Candy_1` (×2) and `Clockwork_2` with a SurfaceGui (rev 1 finding) — Candy_1 matters in shots 10-11 | `LocalTransparencyModifier = 1`, SurfaceGui off |
| Camera effects | `MenuBlur`, `HatchBlur`, `UpgradeBlur` under the camera; all ParticleEmitters under `CurrentCamera.EventWeather` (re-scanned each frame) | `Enabled = false` |
| Music | `SoundService.Music.Volume` saved, set to 0 (no music per brief §6; live game sounds stay) | restore (normally 0.22) |

Other Lock items (from rev 1, kept): controls `GetControls():Disable()` (AFK and PlowTestMove still drive, PlowDriveClient L255-271); `SuppressEvents = true`; camera saved and driven by `BindToRenderStep("TrailerCam", Last, …)` setting `CameraType = Scriptable`, CFrame and FieldOfView every frame (beats PlowDriveClient's FOV lerp L563-570); `TrailerGrade` ColorCorrectionEffect under the camera; `LightingSnap` pulses. Restore: unbind, `CameraType = Custom`, `CameraSubject = Humanoid`, FOV one frame later; `PlowTestMove = nil`; destroy puppets, TrailerGrade; overlay frames hidden; report printed as `[Trailer] restore report <json>`.

---

## 9. SafeFrame, text and cards

### 9.1 SafeFrame

- Inside TrailerDirectorGui (IgnoreGuiInset true, `ScreenInsets = None`), size from the gui's `AbsoluteSize` (= viewport): `fit = min(W, H × 16/9)`, SafeFrame = `0.98 × fit` wide, 16:9, centred.
- Menu-button clearance: take the reserved top-left rect from `GuiService.TopbarInset` (left part, 0 … `TopbarInset.Min.X` × `TopbarInset.Max.Y`; fallback 64 × 64 px). If it intersects the SafeFrame, shrink the 0.98 factor in 0.005 steps until clear. With Studio maximised and panels closed the viewport is wider than 16:9, so the side margins already clear it.
- Four black letterbox frames cover everything outside the SafeFrame.
- FOV correction (rev 1): when the viewport is taller than 16:9, `camera.FieldOfView = 2·atan(tan(fov/2) × viewportH / safeH)` so key FOVs are crop FOVs.
- Magenta slate: a full-opacity Frame (255, 0, 255) exactly filling the SafeFrame (ZIndex top) at the start (until `CropOK` or 10 s) and for 0.5 s at the end.

### 9.2 Text system (brief §4)

TextScaled caps at 100 px, so every text line is a `TextSize = 100` label scaled by a UIScale:

```lua
local function line(text, font, frac, cy)            -- frac, cy: fractions of SafeFrame height
  local holder = Instance.new("Frame")                -- BackgroundTransparency 1, AnchorPoint (0.5, 0.5)
  holder.Position = UDim2.fromScale(0.5, cy)
  local lbl = Instance.new("TextLabel")               -- TextScaled = false, TextSize = 100, white, Text = text
  lbl.Font = font                                     -- Enum.Font.FredokaOne, or Enum.Font.LuckiestGuy for PLAY NOW!
  local st = Instance.new("UIStroke")                 -- Color (20, 40, 85) = game NAVY (PlowGarageClient L20)
  st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
  if not pcall(function() st.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize; st.Thickness = 0.06 end) then st.Thickness = 6 end
  local b = TextService:GetTextBoundsAsync(params(text, font, 100))   -- unscaled size
  holder.Size = UDim2.fromOffset(b.X + 24, b.Y + 12); lbl.Size = UDim2.fromScale(1, 1)
  local s = frac * safeH / 100                         -- 100 px glyph box -> frac of SafeFrame height
  s = math.min(s, 0.9 * safeW / (b.X + 24))            -- fit to 0.9 of SafeFrame width
  local ui = Instance.new("UIScale"); ui.Scale = s     -- pops multiply this: ui.Scale = s * pop
end
```

Recomputed when the SafeFrame changes size. Nothing is placed below 0.82 of SafeFrame height. No title anywhere.

| Element | Font | Size (frac of safeH) | Centre y | Lines | Timing (s after ROLL) | Motion |
|---|---|---|---|---|---|---|
| Callout 1 | FredokaOne | 0.12 | block centre 0.19 (lines 0.125 / 0.255) | PLOW SNOW / TO EARN SNOW | 0.4-2.4 | in: pop 1.25 → 1 (0.15 s, Back Out) + fade 0.1 s; out: fade 0.15 s ending at "to" |
| Callout 3 | FredokaOne | 0.12 | 0.125 / 0.255 | ROLL PARTS / BUILD YOUR PLOW | 4.0-7.0 (spans the 5.8 cut) | same |
| Callout 6 | FredokaOne | 0.12 | 0.19 | HATCH PETS | 10.6-13.0 | same |
| Card A | LuckiestGuy | 0.27 | 0.24 | PLAY NOW! | in 25.9, to 29.5 | pop 1.35 → 1 (0.35 s, Back Out), then pulse 1 ↔ 1.04, period 0.8 s |
| Card A tagline | FredokaOne | 0.10 | 0.45 / 0.55 | PLOW SNOW. ROLL PARTS. / HATCH PETS. | 26.3 / 26.45, to 29.5 | pop 0.9 → 1 + fade 0.2 s |
| Card B | FredokaOne | 0.14 | 0.20 / 0.34 / 0.48 | PLOW SNOW. / ROLL PARTS. / HATCH PETS. | ROLL_B + 0.4 / 0.55 / 0.7, to ROLL_B + 4.0 | pop 0.9 → 1 + fade 0.2 s |

PLAY NOW! at 0.27 × 1080 = 292 px line height; the 0.9-width fit may reduce it (LuckiestGuy is wide); round 2 logs the final cap height in output pixels (target ≥ 200 px).

### 9.3 Look

Per-area BiomeLighting presets come free with the Scriptable camera (zones in Profiles L17-37) and snap on cuts via `LightingSnap`. TrailerGrade adds small deltas only (tweened 0.3 s, never above ±0.05 brightness/contrast, ±0.08 saturation): S01/S05 contrast +0.04, saturation +0.05; S02 brightness +0.02; S03/S04 contrast +0.03; S06 saturation +0.03; S07 saturation +0.04; S08 brightness +0.02; S09 0; S10 saturation +0.03; S11 brightness −0.03, contrast +0.05. No depth of field, no snowflake overlay, no music track (rev 1 items removed).

---

## 10. Data shape (TrailerShots)

```lua
return {
  Config = { StartKey = Enum.KeyCode.F8, SlateMax = 10, WarmPark = 0.6, GateTimeout = 120,
             PassB = { gap = 4.0, shot = "S11_CandyPath" }, MaxTotal = 37.5 + 1.0, WorldGuiKeep = {} },
  Profile = { HeroC = { Blade = "blade_katana", Engine = "engine_blossom", Gear = "gear_bamboo", Body = "body_starter" },
              SwapBlade = "blade_wide", Pets = { "Snow Bunny", "Penguin", "Fennec Fox" }, MiniLevel = 7,
              Upgrades = { "M_Expansion2", "M_Expansion5" }, BlockEvent = { "LuckyWind", 900 } },
  Shots = { --[[ 11 entries as section 6: id, start, dur, type, keys/ref, need, fallback, grade, plow = {...}, puppet = {...} ]] },
  Cards = { Callouts = {...}, A = {...}, B = {...} },   -- section 9.2 table
  Server = { --[[ section 2.5 schedule, data only ]] },
}
```

`ValidateShots` (Edit, pure) checks: unique ids, contiguous starts (each start = previous start + dur, ±0.01), pass A ends at 29.5, valid types/transitions, ≥ 2 keys with ascending t, finite vectors, every part id in `PlowConfig.Parts` and none with Role "P" or in any `PassConfig` pass, pets in PetConfig and none from the Verity Egg, every text string from the allowed set (section 9.2), no text centre below 0.82.

---

## 11. Shot engine (kept from rev 1)

- Clock `t = GetServerTimeNow() − TrailerRollA`; one RenderStep evaluates the current shot at `u = ease(clamp((t − start)/dur))`.
- Types `path`, `follow` (yaw-frame offsets, exponential smoothing `posTau`, angle-wrapped `yawTau`, optional `orbitDeg`), `orbit`, `hold`. Catmull-Rom centripetal (alpha 0.5), FOV/roll linear.
- Transitions: all cuts (`cut` + LightingSnap pulse). The 0.5 s blacks and the slate are separate overlay steps; there are no white flashes (calm brief).
- `need = {parts = {pos, radius, min}, tiles = {field, min}, afk, hull, plowAt = {pos, radius}}` checked at shot start; failure plays `fallback` in the same slot and duration. Never overrun: the timeline is fixed so cut points stay valid.
- Rehearse-mode logging per shot: measured start vs plan, frames and worst 0.5 s FPS, fallback used, subject screen-Y range (shots 1, 5, 6, 9, 11), plow speed, stop error.

---

## 12. Recording plan

### 12.1 Room setup (wiktor)

Studio maximised on the main monitor (2560 × 1440, ~125% scaling), Explorer/Properties/Output panels closed, nothing selected, stats overlays off, Quality Level max. Terminal window behind Studio. Windows Do Not Disturb on. Codex off during Play (brief §7). Free RAM checked before F5 (section 12.7).

### 12.2 OBS: new profile and collection "Trailer" (wiktor's "Bez tytułu" untouched)

Created as new files by the implementer (OBS closed while writing):

- `%APPDATA%\obs-studio\basic\profiles\Trailer\basic.ini`:
  ```ini
  [General]
  Name=Trailer
  [Output]
  Mode=Advanced
  FilenameFormatting=Trailer_take_%CCYY-%MM-%DD_%hh-%mm-%ss
  [AdvOut]
  RecType=Standard
  RecFilePath=C:\Users\wikto\Desktop\Roblox Gra\outputs\Trailer
  RecFormat2=hybrid_mp4
  RecEncoder=obs_nvenc_h264_tex
  RecTracks=1
  [Video]
  BaseCX=2560
  BaseCY=1440
  OutputCX=2560
  OutputCY=1440
  FPSType=0
  FPSCommon=60
  ScaleType=lanczos
  ColorFormat=NV12
  ColorSpace=709
  ColorRange=Partial
  [Audio]
  SampleRate=48000
  ChannelSetup=Stereo
  ```
  Without ffmpeg: `BaseCX/CY` and `OutputCX/CY` = 1920 × 1080 (crop in OBS, section 12.4). `FPSCommon` = 60 or 30 by the rule in 12.5.
- `…\profiles\Trailer\recordEncoder.json`: `{"rate_control":"CQP","cqp":16,"preset2":"p6","tune":"hq","multipass":"qres","profile":"high","bf":2,"keyint_sec":2}`.
- `%APPDATA%\obs-studio\basic\scenes\Trailer.json`: scene "Trailer" with
  - Display Capture (`monitor_capture`, `method` 2 = Windows Graphics Capture, `capture_cursor: false`, `monitor_id` of the 2560 × 1440 main monitor; resolve the id read-only from the monitor device path, and check the OBS log line for 2560x1440 in round 2). Without ffmpeg it carries a Crop/Pad filter (section 12.4) and the transform bounds 1920 × 1080 "scale inner".
  - Application Audio Capture (`wasapi_process_output_capture`, executable `RobloxStudioBeta.exe`, priority "match executable").
  - Desktop audio and mic entries present but muted (no Discord, no system sounds).
  - `"output-timer": {"autoStartRecordTimer": true, "recordTimerHours": 0, "recordTimerMinutes": 5, "recordTimerSeconds": 0}`. **Unverified key for OBS 32**: round 2 checks that recording stops by itself; if not, see 12.3.
- The output folder `outputs\Trailer` is created first (it does not exist yet).
- Launching with `--profile` makes "Trailer" OBS's last-used profile in `user.ini [Basic]` (wiktor's file currently says Profile=Bez tytułu). The launcher backs up `user.ini` to `outputs\Trailer\obs-user.ini.bak`; after wiktor next closes OBS, the four `[Basic]` lines are put back (or wiktor picks the profile in the Profile menu).

### 12.3 Start and stop

- **If wiktor allows the OBS WebSocket (question 1):** OBS started normally with the Trailer profile/collection; Claude sends `StartRecord` before F5, waits for the file to grow, and `StopRecord` after TRAILER_DONE. Password stays in OBS's own config; Claude reads it from `plugin_config\obs-websocket\config.json` only at run time and never prints it.
- **Otherwise:** `Start-Process "C:\Program Files\obs-studio\bin\64bit\obs64.exe" -WorkingDirectory "C:\Program Files\obs-studio\bin\64bit" -ArgumentList '--profile "Trailer" --collection "Trailer" --scene "Trailer" --startrecording --minimize-to-tray --disable-updater --disable-shutdown-check'`, only if no `obs64` process is running (if one is, stop and ask wiktor; never `Stop-Process` OBS). Ready = a new `Trailer_take_*.mp4` in outputs\Trailer that grows for 2 s (timeout 20 s). Recording ends by the Output Timer (5 min). If the timer key does not work: wiktor stops it from the tray icon after "Studio is back in editing".
- **If OBS fails:** with ffmpeg, `ffmpeg -f gdigrab -framerate 60 -i desktop …` (same crop path); otherwise Xbox Game Bar (Win+Alt+R records the focused window, then crop is impossible without ffmpeg, so this is last resort).

### 12.4 Crop from the magenta slate

- **ffmpeg path:** record the full 2560 × 1440 desktop. After the take, extract one slate frame (`ffmpeg -ss <slate+2> -i take.mp4 -frames:v 1 slate.png`), find the bounding box of pixels with R > 200, G < 60, B > 200 (PowerShell System.Drawing, read-only), and use it as `crop=W:H:X:Y` (W/H/X/Y even, W:H checked against 16:9 ± 1 px).
- **No-ffmpeg path:** during the rehearsal slate, one read-only desktop grab (PowerShell, DPI-aware `CopyFromScreen`, saved only to `outputs\Trailer\slate_rehearsal.png`) gives the same box; it is written as the Crop/Pad filter (left/top/right/bottom) on the Display Capture. The take's own slate must match it (same window layout); round 2 compares.

### 12.5 60 or 30 fps

Round 2 runs with OBS recording. If every shot logs a worst-0.5 s FPS ≥ 58, the take records at 60; otherwise `FPSCommon=30`.

### 12.6 The one approved PowerShell script (`outputs\Trailer\run_take.ps1`)

Modes, all read-only except the OBS launch and its own log:
1. `-Launch`: check no OBS process; back up user.ini; create outputs\Trailer; start OBS (12.3); wait for a growing file; print `READY <file>`.
2. `-Watch`: every 2 s append to `outputs\Trailer\watchdog.log`: time, free physical RAM (`Win32_OperatingSystem.FreePhysicalMemory`), RobloxStudioBeta and obs64 working sets, recording file size. Under 1.5 GB free: write `LOW_RAM`. Exit when the recording has stopped growing for 5 s (after having grown) or after 8 min.
3. PowerShell cannot call the Studio MCP, so Claude watches the log: on `LOW_RAM` Claude calls MCP `start_stop_play` (stop) or sets `TrailerAbort = true` on the Server; on `TRAILER_DONE` in Studio Output, Claude stops Play.

Rehearse these exact calls in round 2.

### 12.7 Memory

Studio holds ~18 GB in Edit (STATUS save points 50-52; 32 GB machine). In round 2, if free RAM drops under 3 GB at any point, the take is split: `TrailerSplit = "1-8"` (ROLL at shot 1, ends after shot 8 at 18.0) and a second Play with `"9-11"` (Prepare travels straight to Sakura, HeroC, Candy locked; ROLL at shot 9 = trailer 18.0; pass B unchanged relative to its ROLL). Cuts then join take 1 [0, 18.0] with take 2 [0, 11.5] for A, and take 1 [0, 18.0] + take 2 [0, 7.5] + take 2 pass B [0, 4.0] for B. Before the real take wiktor saves and restarts Studio (fresh memory).

### 12.8 What Claude tells wiktor before the take

"When I say ready, click Studio's title bar once and press F5 once, then touch nothing until Studio is back in editing; if it stays black for 20 s while still playing, press Shift+F5." (If wiktor lets Claude start Play through the MCP, question 3, the first half becomes "touch nothing from now on".)

---

## 13. Cutting and checks

Cut points come from one clock: A = [T_A, T_A + 29.5], B = [T_A, T_A + 25.5] + [T_B, T_B + 4.0], T_B = T_A + 33.5, where T_A is the first frame after the 0.5 s black before ROLL_A in the file.

### 13.1 With ffmpeg (if wiktor allows `winget install Gyan.FFmpeg`)

```powershell
# find T_A / T_B: black intervals; T_A = end of the black interval nearest (ROLL_A unixms - OBS "Recording Start" log time)
$crop = "crop=W:H:X:Y,scale=1920:1080:flags=lanczos,format=yuv420p"   # from 12.4, found FIRST
ffmpeg -i take.mp4 -vf "crop=W:H:X:Y,blackdetect=d=0.3:pic_th=0.98:pix_th=0.05" -an -f null - 2> black.txt   # cropped (review fix)
# A
ffmpeg -y -ss T_A -i take.mp4 -t 29.5 -vf $crop -r FPS -c:v libx264 -preset slow -crf 18 -maxrate 15M -bufsize 30M -c:a aac -b:a 192k -ar 48000 -movflags +faststart Trailer_A.mp4
# B
ffmpeg -y -i take.mp4 -filter_complex "[0:v]trim=start=T_A:duration=25.5,setpts=PTS-STARTPTS[v1];[0:a]atrim=start=T_A:duration=25.5,asetpts=PTS-STARTPTS,afade=t=out:st=25.48:d=0.02[a1];[0:v]trim=start=T_B:duration=4,setpts=PTS-STARTPTS[v2];[0:a]atrim=start=T_B:duration=4,asetpts=PTS-STARTPTS,afade=t=in:d=0.02[a2];[v1][a1][v2][a2]concat=n=2:v=1:a=1[v][a];[v]$crop[vo]" -map "[vo]" -map "[a]" -r FPS -c:v libx264 -preset slow -crf 18 -maxrate 15M -bufsize 30M -c:a aac -b:a 192k -ar 48000 -movflags +faststart Trailer_B.mp4
# silent copies
ffmpeg -y -i Trailer_A.mp4 -c:v copy -an -movflags +faststart Trailer_A_silent.mp4
ffmpeg -y -i Trailer_B.mp4 -c:v copy -an -movflags +faststart Trailer_B_silent.mp4
# checks
ffprobe -v error -show_entries format=duration,size:stream=width,height,r_frame_rate -of json Trailer_A.mp4
ffmpeg -y -i Trailer_A.mp4 -vf "fps=1,scale=640:-2,tile=6x5" -frames:v 1 Trailer_A_sheet.png
ffmpeg -y -i Trailer_A.mp4 -vf fps=1 Trailer_A_full_%02d.png
ffmpeg -y -i Trailer_A.mp4 -vf "fps=1,scale=-2:360" Trailer_A_360_%02d.png
```

### 13.2 Without ffmpeg

- Crop already happened in OBS (12.4), so the file is 1920 × 1080.
- T_A estimate = ROLL_A `unixms` (Studio print) − OBS "Recording Start" time from the newest `%APPDATA%\obs-studio\logs\*.txt` (read-only). Refine with `Windows.Media.Editing`: `MediaComposition.GetThumbnailAsync(t, 64, 36, VideoFramePrecision.NearestFrame)` around the estimate in 1/60 s steps, mean luma < 16 = black; T_A = first non-black frame after the black run. Same for T_B.
- Render with `Windows.Media.Editing` (PowerShell 5.1 WinRT): A = one `MediaClip` with `TrimTimeFromStart = T_A` and `TrimTimeFromEnd` so it lasts 29.5 s; B = two clips (25.5 s + 4.0 s) appended; `RenderToFileAsync` with `MediaEncodingProfile.CreateMp4(VideoEncodingQuality.HD1080p)` (frame rate set to the take's), output to outputs\Trailer. Silent copies: same compositions with `clip.Volume = 0`.
- Last resort: the same numbers for wiktor in Clipchamp ("trim start at T_A s, end at T_A + 29.5 s; for B split at 25.5 s and append T_B … T_B + 4.0").
- Checks without ffprobe: `MediaClip.OriginalDuration`, file size, and a 1 fps thumbnail sheet assembled with System.Drawing.

### 13.3 Acceptance

Duration 29.4-29.6 s, 1920 × 1080, under 100 MB. Full-size 1 fps contact sheet and 360 px grabs show no UI, names, avatars other than the blank driver, prices, padlocks, placeholder text, paid or removed things, Studio chrome, magenta, or white-out. Text readable at 360 px.

---

## 14. Rehearsal, test and cleanup

### 14.1 Round 0, Edit (read-only reads; kit install only with consent = save point 56)

Read and record in TrailerShots: Bay_1 parts; `StageEggs_Desert` pivot and ground Y; `W1Remaster.Crystal.X_Heart`, `X_Headframe.Wheel`; `W1Remaster.AbsoluteZero.Z_HeartEngine`; `AbsoluteZeroPortal` centre; Candy `StagePaywall_Model` paywall CFrame (`G`); Sakura-Candy deck segments under `World2.Bridges`; Candy main path line, wafer bridge, ChocoRiver; `SnowFieldZones` sizes for Starter, Candy_1, Candy_2; `World2.CloudCurtains` bank names; `TravelPoints` Sakura; any FROSTFALL text or padlock geometry near the lantern path. Edit screenshots per shot with the camera saved and restored and CameraType confirmed Fixed (STATUS lesson). Install the kit (backup containers first, brief §7), log save point 56 in STATUS.md and outputs\SAVE_POINTS.md.

### 14.2 Compile/data check (Edit)

`require` TrailerServer, TrailerMath (`SelfTest()`), TrailerClient, TrailerText, TrailerPuppets, TrailerShots, TrailerRefs; `ValidateShots` returns `true, {}`; CameraType unchanged (Fixed).

### 14.3 Round 1, Play, TrailerMode = "rehearse", player attribute `TrailerRefs = true` (references, no OBS needed)

Records: hero C road and field speeds, accel/brake distances; SeatWeld C0/C1; Desert approach track (S → P) and Crystal drive track for the puppets; MiniField/MiniCount 4 s after a Candy unlock with HeroC; whether the live fog fade and gate fade play; Starter AFK lane geometry (W vs D). The brief's other references (roll, hatch, drift) are not used by this cut: roll and hatch are not filmed, drift is dropped.

### 14.4 Round 2, Play, TrailerMode = "rehearse", full run with OBS and the script

Same run as the take. Pass criteria: all shot starts within ±0.05 s of plan; no fallback used (or the fallback accepted); subject screen-Y in range; PLAY NOW! cap height ≥ 200 px in output; worst FPS per shot → 60/30; RAM free ≥ 3 GB (else split, 12.7); `[Trailer] BUG: request after ROLL` never printed; restore report clean (camera Custom then Fixed in Edit, controls, prompts, core GUI, music 0.22, `PlowTestMove` nil, AfkPlow nil, puppets gone); crop box found; trims computed and a test A rendered.

### 14.5 Take and cleanup

wiktor saves and restarts Studio, Claude sets the three attributes (token = now + 15 min), OBS starts, wiktor presses F5 (or Claude, question 3), touch nothing. After TRAILER_DONE: stop Play, check `CurrentCamera.CameraType` is Fixed in Edit, clear `TrailerMode`, `TrailerToken`, `BalanceTestMode`, `TrailerSplit`; move `TrailerKit` and a Disabled `TrailerBootstrap` into `ServerStorage.TrailerKit_Parked` (park_edit clears the four attributes again, BalanceTestMode included, review fix); note in STATUS.md (top handoff) and SAVE_POINTS.md. After wiktor closes OBS for the last time: `record_take.ps1 -RestoreUserIni` (wiktor's OBS profile and scene collection back, review fix). Graphify covers `game/` only; the kit lives in outputs/ and Studio, so no graph rebuild unless sources are copied into `game/`.

### 14.6 Delivery (brief §8)

Reply to wiktor with the 4 paths (A, B, A silent, B silent in outputs\Trailer), lengths, sizes, 2-3 grabs, and: (1) Configure > Places > start place (94130990350526) > Videos may refuse a private game; going public is wiktor's call. (2) Upload B (safer) or A: free, 3 a month. (3) Review takes days; a rejection uses an upload. (4) Never the in-game Video asset upload (2,000 Robux). Sound: live game sounds only; their licence is unconfirmed, the silent copy is safest. Page-video limits (60 s, 1080p, 100 MB, PLAY NOW! possibly treated as promotional) are unverified search snippets.

### 14.7 Files the implementer produces

Under `outputs\Trailer20261006\src\`: `ServerScriptService/TrailerBootstrap.server.lua`, `ServerStorage/TrailerKit/TrailerServer.lua`, `…/TrailerDirectorGui/{TrailerDirector.client.lua, TrailerClient.lua, TrailerText.lua, TrailerPuppets.lua, TrailerMath.lua, TrailerShots.lua, TrailerRefs.lua}`, `manifest.json` (studioPath, className, properties; the ScreenGui properties of section 4.1). Plus `outputs\Trailer\run_take.ps1` and the OBS files of 12.2.

---

## 15. Changes from the brief (for wiktor)

1. **No drift in shot 5, no "DRIFT FOR BONUS SNOW".** A drift needs a held Shift / L1 / DRIFT button (PlowDriveClient L99-127, L476-480); scripts cannot press it, and input during the take is excluded (it also ends AFK, AfkDriftClient L121-133). Shot 5 is now the wide-blade plow cutting a visibly wider lane through fresh snow, without text.
2. **Shots 6 and 7 use a puppet hero C**, not the real plow. The real plow cannot stop at the Desert egg at 12.4 and still reach the Candy gate by 20.4 (travel + ~235-stud drive at ≤ 39 studs/s). It travels to Sakura right after shot 5 (10.25). Puppets replay tracks recorded from the real plow in rehearsal; without a track, shot 6 becomes an egg-only push-in and shot 7 camera-only.
3. **Hero C is equipped at 10.20, before the Sakura travel**, so it is the real plow in shots 9-11 and the model of the minis (brief: 10.3 s, optional).
4. **Blade swap is not the Equip action.** `Equip` requires being in the garage within 39 studs of the bay and not driving (PlowService L386-399, L516-528). The trailer writes the build and re-publishes the bay (`GarageTestHook "publish"`), which plays the game's own swap animation; the real plow is respawned with that blade for shot 5.
5. **Gating attributes are set in Edit before F5**, not on the Server after Play starts: BalanceTestMode and the modules read them at server start. `BalanceTestMode = true` is required.
6. **Candy unlock runs StageService's steps on the server** (pay, set stage, re-publish) instead of the UnlockStage RemoteFunction, which only a client can call. Same visible result.
7. **Gap before pass B is 4.0 s of black, not 0.5 s**, so the plow can reverse to its mark; ROLL_B = ROLL_A + 33.5.
8. **EndTest may not be available** when Play was started with F5; Claude stops Play through the MCP (or wiktor presses Shift+F5).
9. **The RAM watchdog cannot call Studio itself**; it logs, and Claude acts on `LOW_RAM`.
10. **"Sakura bridge head" = the Candy gate at Sakura's east end (x ≈ 1825)**, not the koi-pond bridge (1782, 3, 0); the camera stays at x ≤ 1815 to avoid the Mist lighting zone.
11. **"Candy chocolate path" = Candy's main path at z ≈ 55 over the wafer bridge across the ChocoRiver** (to be confirmed in round 0).
12. **Random events are blocked with LuckyWind**, not left to chance; its effects and every other camera effect are hidden.
13. **No-ffmpeg cutting uses Windows.Media.Editing** (trim, join, mute) with the crop done in OBS; Clipchamp numbers are the last resort.
14. **OBS Output Timer key is unverified for OBS 32**; checked in rehearsal, fallback is stopping from the tray.
15. **Studio's 18 GB footprint**: a split take (shots 1-8, 9-11) is prepared in case rehearsal shows under 3 GB free.

## 16. Open questions for wiktor

1. **OBS WebSocket:** may Claude turn on OBS's local WebSocket server (Tools > WebSocket Server Settings, port 4455, local only)? Yes = Claude starts and stops recording itself and can check it is running. No = OBS is launched from the command line with the Trailer profile and stops by its timer.
2. **ffmpeg:** may Claude install ffmpeg (`winget install Gyan.FFmpeg`, about 100 MB)? Yes = full-screen recording, exact crop from the magenta slate, frame-exact cuts and checks. No = crop set in OBS from the rehearsal and cuts made with Windows' built-in video editing.
3. **Play button:** may Claude start and stop Play through the Studio MCP for the rehearsals and the take? Yes = you press nothing at all. No = you press F5 once when Claude says ready.

---

## Implementation notes (2026-10-07, Claude, implementer)

Sources: `outputs\Trailer20261006\src\` (list, Studio paths and classes in `src\MANIFEST.md` / `manifest.json`). Nothing was written to Studio (it was closed). Not compiled: no Luau analyzer on this PC; static checks only (block/bracket balance, undeclared-identifier scan, all clean). The three .ps1 files parse; `obs_trailer_setup.ps1 -DryRun` ran (main monitor `\\.\DISPLAY2` 2560x1440, its OBS monitor id resolved). Round 0 starts with `install_edit` → multi_edit → `check_edit` (SelfTest + ValidateShots).

Deviations from this spec:
1. **Layout.** Flat `.luau` files (orchestrator list) instead of the 14.7 tree; `run_take.ps1` is split into `obs_trailer_setup.ps1` (writes the 12.2 OBS files), `record_take.ps1` (12.3 launch + 12.6 watchdog) and `cut_takes.ps1` (13). Added `check_edit.luau` (14.2). The ScreenGui keeps this spec's name `TrailerDirectorGui` (the task text said "TrailerGui").
2. **Departures.** 19.55 / 25.20 / 33.20 cannot meet 20.4 / 26.5 / 34.5 with Hero C's acceleration (34 studs from rest take ~1.5 s). Each route move carries `arriveBy` / `crossAt` and departs at min(spec time, latest departure that still arrives, x1.05): about 19.1, 24.9 and 32.9 s. Every move logs start, cruise and stop error.
3. **Walk speed.** M_Expansion2/5 are also the "+1 walk speed" tiles (UpgradeConfig L129, L132), so walk speed 18 gives SpeedMult 1.0625 (PlowService L141): Hero C tops at ~41.5, not 39.1. Round 1 measures it.
4. **Driver rig.** Only the HumanoidRootPart is anchored. The limbs stay unanchored, massless and non-colliding on their Motor6Ds so the sit animation can pose them. Until round 1 records the SeatWeld, the default seat offset is CFrame.new(0, 1.8, 0).
5. **Shot 4 check.** PlowGarageClient renames the swapped part to "Blade", so its model name cannot identify it. The check compares the Blade child's extents with the `blade_wide` template and waits until `Leaving_Blade` is gone.
6. **RepublishBay.** A same-value `publish` fires no attribute change, so it would neither refresh the bay nor relight the pedestal. The server empties pedestal 2 for 0.15 s and then fills it again.
7. **FOV correction** is applied always (`2·atan(tan(fov/2)·H/safeH)`), because the 0.98 SafeFrame is smaller than the viewport even when the viewport is wider than 16:9. The SafeFrame width is rounded down to a multiple of 16 px, so the crop is exactly 16:9.
8. **Values this spec left open.** Orbit = `center + (r·cos a, height, r·sin a)` looking at `center + (0, lookHeight, 0)`, both relative to center. Eases: S06 OutSine, S09 and S10 InOutSine. The wheel is the `Wheel` descendant of `X_Headframe`, with a scout fallback of (192, 19, 100) taken from the 6.7 numbers.
9. **Prepare.**
   - If the Starter travel point would make findSpawn land off the field, the standing, unseated character is turned in place toward the Starter field before `PlowRegistry.Spawn`. Its position does not change, and a seated character is never moved.
   - `AfkField` is the id of the field under the hull (AfkService fieldAt), not the literal "Starter".
   - Re-runs (`TrailerGo`) also clear `Stages.Candy` and `Reserved`.
10. **Restore.** A `PaywallSurface` whose stage is open stays disabled (StageClient). A world GUI goes back to the last value a game script set while it was held off.
11. **Inputs.** `PlowTestMove` is pre-scaled to undo PlowDriveClient's circle-to-square mapping (L426-429), so steer and throttle arrive exactly.
12. **Needs.**
   - S09's `plowAt` is checked at 19.4 (deferred); its fallback keeps the same camera.
   - `need.tiles` is not implemented, because no shot uses it.
   - TrailerSplit is supported. "9-11" drives the plow to P_hold before ROLL and arms when it is stopped there.
13. **Refs mode.** `TrailerRefs` is the player attribute, or ServerStorage `TrailerRefs` set through `arm_edit`. The server drives the legs seat → Desert → Crystal → Candy; the client prints `REF_SEATWELD`, `REF_DRIVE` and `REF_TRACK` JSON and asks for the next leg with `RefsNext`, which is allowed because refs mode has no ROLL.
14. **Unverified until rehearsal.**
   - OBS: the output-timer auto stop, the `monitor_id` match, and the app-audio window string (`Roblox Studio::RobloxStudioBeta.exe`, priority exe).
   - `StudioTestService:EndTest` in F5 Play (a failure is logged).
   - Studio-log marker scanning in record_take / cut_takes is best effort.

## Review fixes (2026-10-07, Claude, fixer)

All in `outputs\Trailer20261006\src\`; nothing written to Studio. The Luau files are still not compiled (no analyzer on this PC); block and bracket balance were re-checked. The .ps1 files parse. The Windows.Media.Editing thumbnail code ran on a local mp4, and `-RestoreUserIni` ran on scratch copies.

1. **BalanceTestMode never reaches a save.** `park_edit` and `uninstall_edit` now clear BalanceTestMode along with the four Trailer* attributes. park_edit errors out if the attribute is still set. **For wiktor (game side, not changed):** `MachineService.server.luau` L90-93 `recipeVisible` checks BalanceTestMode without `RunService:IsStudio()`, unlike DataService and the other readers. A place saved with the attribute set would show TestOnly recipes on live servers. Adding the IsStudio gate is suggested.
2. **Restore records are strong tables.** `saved`, `pgGuis`, `worldGuis`, `beams`, `humanoids` and `hiddenModels` lost `__mode = "k"`, so music volume, name tags, NPC and dev-box parts, and chat configs cannot be re-recorded as hidden. restore() empties them afterwards.
3. **Prepare stops after a cleanup.** `step()` refuses once `run.active` is false. Step 12 re-checks after every yield. begin() runs afkOff and `EndEvent` again when the run was cleaned during Prepare. A TrailerGo that lands while that Prepare is still unwinding is refused, and the attribute is cleared so it can be set again.
4. **Client aborts before ROLL reach the server.** Client.Abort sends `Abort` while `R.rollA` is nil (not in refs mode). The server runs cleanup ("client abort"), which drops AFK and the hold loop and sets state `aborted`, so TrailerGo works again (DESIGN 2.3).
5. **Refs seat leg stops on abort.** setMove is a no-op after Restore, and Restore resets `lastMove`. Both seat-leg loops and the track tail raise "aborted". RunRefs returns once the run is aborted, so PlowTestMove cannot be left set.
6. **Stale TrailerRefsLeg.** begin() clears it before `TrailerRun`, and cleanup clears it unless the run finished as `done`. The client takes only `seat` as the first leg.
7. **S05 join check.** It now runs before the move selection, so `wide` starting at `alignedBy` (6.2) no longer skips it. The check also fails cleanly when no seated new plow exists at 6.2.
8. **'stop' reference tracks** are anchored on the frame where the plow came to rest. The 0.5 s tail is hold padding after the anchor, so the Desert puppet is no longer 0.5 s early.
9. **Shot 5 stays on the field.**
   - storeLane records the AFK lane end ahead.
   - `wide` is a braking stop to min(`LaneRun` 45, lane end − `LaneEndMargin` 4).
   - Fewer than `LaneNeed` + margin (42 studs) left at 2.40 sets `s05ok = false`.
   - The gate distance is now max(53, max(speed, 14.4) × (ArmLead + 2.45) + 38 + 4 + 4) ≈ 91 studs, so arming happens in roughly the first quarter of a ~118-stud Starter lane. **Rehearsal check:** watch the `gate:` log lines for "lane end too close" timeouts.
   - `MinSpeed` dropped from 12 to 10.5 (optional finding). The distance rule uses max(speed, 14.4), so it is not weakened.
10. **Pedestal-2 light.** S03 and S04 find the PointLight on Pedestal_2's top part, force it on through setProp, and re-assert it every frame in hidePass. endShot restores it. The pre-ROLL RepublishBay is kept: it is harmless and no longer needed for the light.
11. **S10 minis.** The primary variant also needs `workspace.MiniPlows["<Name>_Mini1"]` drawn inside the MiniField bounds. While the puppet-minis fallback plays, the real fleet's parts are added to the shot hide list (re-scanned every 10 frames), so two fleets never overlap. The variant is not switched mid-shot, because that would be an extra cut. DESIGN 6.10 timing is corrected.
12. **cut_takes, ffmpeg path.** The crop box is found first. blackdetect then runs on `crop=…,blackdetect=…:pic_th=0.98`. With -Run and no crop box the script exits 3 instead of keeping the estimate.
13. **cut_takes, no-ffmpeg path (DESIGN 13.2).** Windows.Media.Editing thumbnails (64×36, NearestFrame) bisect the frame grid in est ± 1 s for the black→picture edge. That takes about 8 thumbnails, roughly 0.5 s each. `-NoRefine` skips it. If it fails, the script keeps the estimate with a WARNING. PowerShell 5.1 needs `ICollection.Add` called through reflection on `MediaComposition.Clips`.
14. **OBS user.ini.** `record_take.ps1 -RestoreUserIni` refuses while obs64 runs and backs up the current user.ini. It then writes only Profile / ProfileDir / SceneCollection / SceneCollectionFile from the FIRST `obs-user.ini.bak` (UTF-8, no BOM), and refuses if that backup already points at Trailer. The DONE line prints a reminder, and it is listed in MANIFEST and 14.5.

Optional findings applied:
- The text layer is destroyed on Restore, so the AbsoluteSize connection no longer leaks.
- Controls lock also finds the PlayerModule in StarterPlayer and switches off `InputContexts.CharacterContext` through setProp. The method used is logged and the restore report shows it. PlowDriveClient reads AFK and PlowTestMove before the move action. Its keyboard fallback still sees raw keys, which the take excludes anyway.
- S11's `plowAt` checks the P_wait→P_stop segment (`to = "PStop"`), so the early departure no longer logs a false "no plow" fallback.
- During a run a Stepped hook writes the player's own FOV before PlowDriveClient's Heartbeat captures `baseFov`, so its later camRestore cannot bring back a trailer FOV.
- Prepare's travel retries TravelService's "One moment..." / "Already travelling..." for up to 8 s.
- Text pops never exceed the SafeFrame width (PLAY NOW!).
- The cut script grabs the slate frame at the SLATE_START/SLATE_END midpoint, else 0.25 s before TRAILER_DONE, else start + 2 s.
- Crop rounding sizes the box from the even-shifted origin.

Optional findings skipped:
- **TrailerSplit support in cut_takes:** a two-take concat mode is a larger feature, and split takes are only a contingency. If a split is ever recorded, the trim points are computed by hand.
- **Parking a plow left by a late stale travel:** skipped as speculative.
