# Studio verification checklist - UI audit 2026-10-08

For the developer, in Roblox Studio (place `money`, 94130990350526). **Nothing below has been done yet.** The fixes were written in a cloud session with no Studio, no screenshot and no device, so every row is open until you tick it. Read `README.md` first (findings, open items, patch table).

How to use: work top to bottom. Part A must be finished before any Play check. In the **Result** column write `P` (pass), `F` (fail, add a note) or `N/A` (could not be triggered, say why). A row that is marked "known gap" may fail; record what you see.

Finding IDs (F01...) refer to `README.md` section 5. Device codes:

| Code | Device |
|---|---|
| D1 / D2 | Desktop window at 1920x1080 / 1280x720, mouse and keyboard |
| PL1 / PL2 | Studio device emulator, phone landscape 844x390 / 667x375 (932x430 optional) |
| PP | Emulator portrait 390x844 (not a designed layout: only check that nothing is unreachable or stuck) |
| RP | A real phone, touch input |
| GP | A controller (gamepad) |

Tip: confirm the viewport with `print(workspace.CurrentCamera.ViewportSize)` on the client (command bar in the client context during Play).

## 0. Rules for the whole session

- **Do not publish.** Do not save over the place unless you decide to keep the changes.
- **Never complete a real Robux purchase.** Open BUY / DETAILS flows only as far as the prompt, then cancel. (When last documented, `outputs/NewFeatureSnowyUI20261005/README.md`, pass sales were disabled with nil IDs and COMING SOON; do not rely on that, check the current state.)
- **Do not run `;reset`, `;upgrades reset` or `;stages reset`** (AdminService.server.luau lines 142, 189, 217). Other admin commands are fine in an isolated profile: `;snow 1m`, `;setsnow`, `;part <id/name>`, `;pet`, `;tp`, `;tutorial` (replays the tutorial). In Studio everyone counts as admin; the console opens with F2.
- **Camera rule (STATUS.md lines 3-12):** never leave `Workspace.Camera.CameraType` on Scriptable. If you take screenshots, save CurrentCamera's CameraType, CFrame and CameraSubject first, restore them afterwards, and read CameraType back at the end. In Edit it must be Fixed. Never use screenshot-tool camera arguments in Edit; check framing in Play only.
- **BalanceTestMode (AGENTS.md):** set `ServerStorage.BalanceTestMode = true` as a boolean attribute **in Edit, before Play**. It isolates the main progression DataService only (not every third-party system) and starts a fresh profile, so the tutorial runs. Stop Play and **remove the attribute in Edit** afterwards. If Studio disconnects, write the cleanup down as pending. Do not claim persistence or publishing was tested.
- If a Studio-only helper is used (for example a `NumberValue` named `LoadingHold` inside ReplicatedFirst to keep the loading screen up), remove it afterwards.

## A. Setup (Edit mode), in this order

| # | Step | Expected | Result |
|---|---|---|---|
| A1 | Confirm the connected place is `money` (94130990350526) and you are on branch `claude/relaxed-faraday-060hsn` with the audit changes. | Correct place and branch. | |
| A2 | **Before syncing**, compare each of the 16 modified scripts in Studio with git HEAD, because the repo is only a mirror and the live Studio script may be newer (AGENTS.md: do not overwrite newer changes). For each path in `git diff --name-only`, run `git show HEAD:<path>` and diff it against the live Source. | Live equals HEAD for each. If one differs, merge the audit change by hand instead of letting Rojo overwrite it; write the script name in Notes. | |
| A3 | Sync `game/src` into Studio with Rojo: from the canonical `game/` folder run `rojo serve default.project.json`, connect the Studio plugin and **review the proposed diff** before accepting (PROJECT.md: never connect the historical `ca/game` copy). | Diff shows exactly 16 changed scripts plus one new ModuleScript `ReplicatedStorage.UILayout`; nothing is deleted from Studio-only instances (the project ignores unknown instances). | |
| A4 | Check `ReplicatedStorage.UILayout` exists as a ModuleScript. Ten client scripts `WaitForChild("UILayout")` with no timeout: ContractClient, PassClient, PlowDriveClient, PlowTutorialClient, PlowShopClient, PlowGarageClient, MiniPlowClient, VerityEggClient, FrostKingClient, ArenaHudClient. | Present. If missing, those ten scripts stall and the whole HUD behaves wrongly. | |
| A5 | Check `ReplicatedStorage.PlowClientApi` has `CloseBuild` and `CloseInspect` (stubs, +4 lines). | Present. | |
| A6 | Install the 7 Studio patches (table below). For each: open the live script, diff against `game/studio-snapshots/<path>`, then against the patch copy; replace Source only if live equals the snapshot, otherwise re-apply the `.patch` hunks by hand. **ActivityClient: hunks only.** Install RNGClient first, then UpgradeTreeClient. | Each patch applied; the `UIAUDIT ... INSTALL PENDING` header line is removed only when you accept it as installed. | |
| A7 | In Edit, read `Workspace.Camera.CameraType`. | Not Scriptable (Fixed). | |
| A8 | Set `ServerStorage.BalanceTestMode = true` (boolean attribute). Optionally set Studio's output filter to show errors and warnings. | Attribute present; Play will start a fresh isolated profile. | |
| A9 | Prepare the device emulator presets for PL1 (844x390) and PL2 (667x375) and portrait PP (Test tab > device emulator; add a custom device if needed). | Viewport prints the intended size. | |

Patch install tracker (paths under `outputs/UIAudit20261008/studio-patches/`):

| # | Patch copy | Target Studio script | Findings | Installed (date, who) | Result |
|---|---|---|---|---|---|
| A6a | `StarterGui/RNGGui/RNGClient.client.luau` | `StarterGui.RNGGui.RNGClient` | F04, F24 | | |
| A6b | `StarterGui/RNGGui/UpgradeTreeClient.client.luau` | `StarterGui.RNGGui.UpgradeTreeClient` | F24, F60 | | |
| A6c | `StarterGui/RNGGui/PetClient.client.luau` | `StarterGui.RNGGui.PetClient` | F09, F15, F36, F47, F56 | | |
| A6d | `StarterGui/RNGGui/ActivityClient.client.luau` | `StarterGui.RNGGui.ActivityClient` (hunks only) | F67 | | |
| A6e | `StarterGui/RNGGui/WheelClient.client.luau` | `StarterGui.RNGGui.WheelClient` | F68 | | |
| A6f | `StarterGui/RNGGui/TreasureReveal.client.luau` | `StarterGui.RNGGui.TreasureReveal` | F20 | | |
| A6g | `ReplicatedFirst/LoadingScreen.client.luau` | `ReplicatedFirst.LoadingScreen` | F28, F35 | | |

If you cannot install every patch, still run parts B-G: rows that depend on a patch say so and may fail by design until it is installed.

## B. Smoke test (D1, then PL1)

| # | Step | Expected | Result |
|---|---|---|---|
| B1 | Press Play (BalanceTestMode on). Watch the Output window until the tutorial card appears. | No red errors from the 17 changed scripts; no "Infinite yield possible" for `UILayout` or `PlowClientApi`. | |
| B2 | Open and close every menu once (SHOP, PETS, REWARDS, TRAVEL, UPGRADES, MINI PLOWS, HELP). | Each opens and closes; blur is gone after each close. | |
| B3 | In PL1, check the touch layout appears (DRIVE column, 44 px buttons). The layout keys off `TouchEnabled and not KeyboardEnabled`. | Touch layout shown. If the emulator reports a keyboard and the desktop layout stays, use RP for all touch rows and note it. | |

## C. Desktop (D1 1920x1080 and D2 1280x720)

Contract and Frost King timing: the first contract offer arrives 90-150 s after the tutorial and then every 240-420 s (ContractConfig.Offer); an offer lasts 150 s. A Frost King event comes every 25-40 min (FrostKingConfig.Schedule). In the isolated session you can use the server-side hooks `ServerStorage.ContractTestHook` (`Invoke("Offer", player)`, `"Expire"`, `"Finish"`; ContractService.server.luau line 645) and `ServerStorage.FrostKingTestHook` (`Invoke("Start", {Field = id, Arrival = s, Target = s})`; FrostKingService.server.luau line 741; field ids in `ReplicatedStorage.SnowFields`). They exist only with BalanceTestMode, and need the Studio command bar in the server context. If that does not work, wait for the natural schedule or mark N/A.

### C1. Contracts, offers and Frost King (class 1, 2, 7)

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| C1.1 | Finish the tutorial, wait for a contract offer. | HELP REQUEST pill appears in the top-right slot below the Roblox top bar, below the Frost King pill/Me and any Activity boost pills; it does not overlap the bottom-left offer cards, HELP or TRAVEL. | F01, F16, F50 | |
| C1.2 | With the pill showing, click each offer card (1.5x Snow, Aurora Wheels, Starter Pack). | The details popup opens every time; no click is eaten by the pill. | F01 | |
| C1.3 | Open SHOP, then close it. Repeat with UPGRADES, MINI PLOWS, TRAVEL and the HELP menu. | The HELP REQUEST popup never opens over an open menu; it opens (or the pill stays) after the menu closes. | F23, F21 | |
| C1.4 | Open the popup, then let the offer expire (or `Invoke("Expire", player)`). | Popup hides at expiry; no dead HELP OUT left on screen. | F33 | |
| C1.5 | Accept a job. Tap CANCEL once, wait 3-4 s. | Label shows SURE? then returns to CANCEL by itself; the next job starts with CANCEL. | F59 | |
| C1.6 | With the job active, tap GARAGE. | Tracker and waypoint beam are hidden in the garage and return when you leave. | F58, F32 | |
| C1.7 | Check pill/tracker visibility in the garage, on the Bumper Arena island and while a Frost King announcement or boss bar is up. | Hidden in each. Known gap: the pill is not hidden when the offer's world differs from yours. | F32 | |
| C1.8 | Frost King: start an event, stay out of the fight. Open SHOP when the announcement is due. | The announcement waits for the menu and appears after it closes; it does not time out unseen. | F23 | |
| C1.9 | Frost King: JOIN and enter the fight. | "Me" HP panel at the lower right (anchor 1,1 at 0.86/0.87), not covering DRIVE/EXIT, DRIFT or RECOVER; boss bar at the top. | F03 | |
| C1.10 | Leave the fight, enter the garage, go to the arena island. | Boss bar and Me hide; the FK pill hides on the island; JOIN on the island answers "Leave the arena first!". | F34, F25 | |

### C2. Tutorial and HELP (class 2, 5, 6, 9)

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| C2.1 | Run the tutorial from the start (fresh profile or `;tutorial`). At a click-step, click the tiles/buttons right next to the highlighted target (MINIS, AFK, neighbours), within about 76 px. | Neighbouring clicks do nothing (four transparent blockers); the target itself works. | F27 | |
| C2.2 | Garage lesson EQUIP step with enough parts (`;part`) that the target row is out of the visible list. | The list scrolls the row into view; the dim/ring sits on a visible button; if the row cannot be shown there is no dim, ring or click-lock. | F10 | |
| C2.3 | DRIVE step. | The arrow points at the DRIVE button (PlowDriveGui). In the garage the step text/label says LOBBY where that is the button. | F02 regression, F54 | |
| C2.4 | Open HELP, click the gaps inside the HELP menu. | Gap clicks do nothing (menu is Active); they do not open the HELP REQUEST popup or toggle MUTE. | F48 | |
| C2.5 | With HELP open: start a lesson via REPLAY; separately start driving; separately open SHOP. | HELP closes on each (the poll takes up to 0.25 s). Offer cards are hidden while HELP is open. | F18 | |
| C2.6 | With SHOP (or another RNG panel) open, tap HELP. | Other menus close first. Before the RNGClient patch the RNG panel may stay open: known gap. | F18 | |
| C2.7 | Open UPGRADES, then try HELP > REPLAY. | The HELP pill is hidden while the UPGRADES page is open; no pointer is shown for a target that is not under the page. | F22 | |
| C2.8 | The legacy 25 s UPGRADES tip, if it appears. | No dead HELP button; SKIP is hidden. | F61 | |
| C2.9 | Tutorial card position after a step that moved it. | The card returns to its default slot on the next step. | F53 | |
| C2.10 | Reserve a part you cannot yet afford, earn Snow in another menu or while driving until it is affordable. | The garage lesson does not start while you are driving, in a menu or in the arena; it starts when you are idle. Known gap: the Main to Garage auto-chain is not gated. | F64 | |

### C3. Menus that must exclude each other (class 4, 6)

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| C3.1 | Garage: open the pedestal offer card, then click your own car. Then reverse. | Equip window and card never show together; the card does not open hidden behind the window. | F05 | |
| C3.2 | Press E on a neighbour's car while the equip window is open. | Window and card close; only the inspect panel shows. | F05 | |
| C3.3 | Click inside the equip window, the card and the inspect panel (not on buttons). | Clicks do not reach the invisible car ClickDetector or toggle windows. | F26 | |
| C3.4 | Open the equip window, walk more than about 39 studs from your bay (or die). | Window closes within about 0.5 s. A click at the edge of the car's 40-stud range may flicker (known). | F31 | |
| C3.5 | Open the offer details popup (OfferDetails) and click empty areas inside it. | Does not click through to the world. | F26 | |
| C3.6 | Offers or OfferDetails while MINI PLOWS, the egg screen, garage inspect or UPGRADES is open. | Offers/popups wait; they come back after the menu closes. | F21 | |
| C3.7 | Open MINIS, then open SHOP, the garage window, UPGRADES, HELP. And tap MINIS while another menu is open. | MINI PLOWS closes (within about 0.25 s) when another menu opens; a MINIS tap closes the other menus first; a second MINIS tap closes the panel. | F21 | |
| C3.8 | Verity egg: open the egg DETAILS screen from the Shop. Click behind it; close the Shop; open another panel; enter the garage; start driving. | Screen blocks clicks behind it; it hides in each of those cases. | F06 | |
| C3.9 | Verity hatch (needs a Verity BUY, which is Robux): do not buy. If you can fire the hatch event visually without a purchase, check that the reveal is not drawn under DETAILS. Otherwise mark N/A. | Reveal visible; DETAILS hidden. | F07 | |
| C3.10 | TRAVEL with the equip window, card, inspect panel, egg screen or MINI PLOWS open. | They close first; only Travel shows. | F04 | |
| C3.11 | TRAVEL while an RNG panel is open, then close Travel in each way (X, GO, TRAVEL toggle). **Needs the RNGClient patch** (RNGGui attribute `CloseAllBus`). | One panel at a time; blur gone after every close; no stuck blur. Before the patch: record the old behaviour. | F04 | |
| C3.12 | UPGRADES with SHOP/PETS open, then with OfferDetails, HELP, MINI PLOWS, the garage window and the egg screen open. **Needs both patches** (RNGClient, UpgradeTreeClient). | Each closes when the tree opens; blur gone; the tree itself stays open. | F24 | |
| C3.13 | Open and close each menu 20 times in a row. | No duplicated toasts, sounds or actions; no growing Output spam. New poll loops are meant to be created once. | class 8 | |
| C3.14 | After closing each menu: walk (WASD), jump, drag the camera. | Movement and camera always work; no invisible overlay eats input. | class 10 | |

### C4. HUD, driving and arena (class 3, 7, 9)

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| C4.1 | Lobby layout at D1 and D2: HELP, TRAVEL, offer cards, MINIS, UPGRADES, AFK. | Offer cards bottom-left right of HELP, bottom flush with TRAVEL; hidden while HELP is open; MINIS left of UPGRADES; MINIS/UPGRADES/AFK centred on one line. (Accepted STATUS decisions: nothing may have moved.) | preserve | |
| C4.2 | AFK button on the arena island, in the garage, and during the loading screen. | AFK hides with the same rule as MINIS (not on the island); returns in the lobby; its DRIFT meter hides with it. | F30 | |
| C4.3 | Enter the Bumper Arena, leave mid-intro, come back. | The first-time intro plays again. | F57 | |
| C4.4 | Pedestal with an offer: both prompts. | E (view offer) and R (Reroll) show as two separate cards, one card height apart, both clickable. Note whether R is below or above E; if above, flip the sign in `SnowUIClient.offsetSize()`. | F08 | |
| C4.5 | Offers: price labels in an unpublished place. | LOADING..., then TAP TO RETRY or COMING SOON; tapping retries; the label flickers briefly every 30 s (known). No purchase prompt appears without a click on BUY. | F46 | |
| C4.6 | Travel with a contract job running; open the confirm. | Warning toast readable; first GO tap shows SURE?, it resets after about 3 s and when another row arms. | F44 | |
| C4.7 | HELP and TRAVEL buttons sit together; wait over a minute after joining. | TRAVEL stays directly above HELP (it follows the HELP pill, no 60 s limit). Hard to force: note N/A if you cannot delay the pill. | F17 | |
| C4.8 | Equip window / offer card: scroll through parts; buy and equip one part with Snow in the isolated profile. | Rows readable; buying and equipping behave and charge as before; no price changed. | F12, F13, F39, preserve | |
| C4.9 | Equip window rows and offer card description on D1/D2 (these changes are not phone-only). | Rows are 112 px high (were 62); the description no longer ends with "A solid step up between its world's starter and premium parts."; rarity bar 4 px. **Decide whether to accept or restrict to small screens.** | README section 10 | |

## D. Phone landscape emulator (PL1 844x390, then PL2 667x375)

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| D1 | Drive: press DRIVE, then check the three touch buttons. | One column of DRIFT, DRIVE/EXIT, RECOVER, each at least 44 px high (min 130x44), placed left of Roblox's jump button, not on it, and inside the screen at the bottom. Tap each. | F02, F40 | |
| D2 | Tap DRIVE once, wait for the plow to spawn. | EXIT appears where DRIVE was and RECOVER is a separate button. Do not double-tap: a fast second tap can hit RECOVER (known). | F40 | |
| D3 | Drive with the left thumbstick. | The plow steers (phone driving reads `InputContexts.CharacterContext.MoveAction`; accepted decision, not changed). | preserve | |
| D4 | Tutorial DRIVE step. | The arrow finds the DRIVE button inside `PlowDriveGui.TouchColumn`. | F02 regression | |
| D5 | HELP, TRAVEL and the OFFERS toggle. | HELP about y 287 at 844x390 and TRAVEL ends at about y 374 (16 px above the edge); all fully on screen; 40 px minimum height. | F37 | |
| D6 | OFFERS toggle: open the list, pick a card; open it again and start driving. | The list folds after a card pick and when driving starts. | F52 | |
| D7 | Open the offer details popup. | Scrolling, wrapped list, text at least 12 px, BUY/CLOSE at least 44 px high; popup stays between HELP/TRAVEL and the DRIVE column (follow-up fix: `PassClient.leftClear`), never under the HELP pill; hides when driving starts. Check at 844x390 and 667x375 that BUY and CLOSE are fully tappable and the text still fits the narrower popup. | F38, F21 | |
| D8 | Contract popup (offer or `Invoke("Offer")`). | Min 320x220, left of the DRIVE column; HELP OUT/LATER/CANCEL/bell at least 44 px; waits while a menu or the tutorial card is up. | F14, F01, F23 | |
| D9 | Contract tracker with a job that has many rows. | Rows 11 px text, the list scrolls; fits above the UPGRADES strip. | F14 | |
| D10 | Tutorial card. | Card at least 300x150, HELP/SKIP easy to tap, OK 110x44, text at least 11 px. Check two-line hints for clipping (known risk). | F11 | |
| D11 | Open HELP during a lesson. | HELP menu opens above the pill; it may overlap the card's lower-left (known). | F18 | |
| D12 | Garage: offer card, equip window, inspect panel. | X and BUY/RESERVE/REROLL at least 44 px with gaps; equip rows two-line; left stats short and readable (about 11 px or more); inspect X does not cover the first part row; card opens above everything it should. Look at the card's top where the tutorial card can cover it. | F12, F13, F39 | |
| D13 | Equip window width at 667x375. | May reach the DRIVE column area (about 38 px): record it. | README section 10 | |
| D14 | Verity egg screen. | Close X 44x44, BUY at least 44 px, tile labels not clipped (look at "Rainbow Verity" and the boost text); screen does not cover the DRIVE column. | F42, F06 | |
| D15 | Frost King on touch: announcement, JOIN/LATER, fight, FX/SHAKE, reward OK. | Announce/Reward stay left of the DRIVE column; JOIN/LATER/OK/FX/SHAKE at least 44 px; Me panel under the boss bar; FK pill sits above the column. | F43, F03, F16 | |
| D16 | Frost King boss bar vs toasts, the contract slot and the Frost King announcement. | Fixed in the follow-up (README section 10, item 1; static checks only): PopupStack and the contract slot start below the boss bar; on touch the bar hides while the announcement is up. Record whether any toast, tracker or popup still touches the bar. | F16 | |
| D17 | Frost King announcement while the tutorial card is up; FK pill while a menu is open. | Fixed in the follow-up (items 2 and 3; static checks only): on touch the announcement waits for the card and comes back after it closes; the pill hides while any menu except the HELP menu is open. Record what happens. | F23 | |
| D18 | Bumper Arena touch HUD. | LEAVE ARENA bottom-left with PAINT above it, no overlap; BOOST and BRACE bottom-right, left of the jump button; intro OK at least 120x44; Status text does not run under BRACE. | F19, F40 | |
| D19 | Arena Status text, Results card, intro card. | Known residual: the long spectator line is small; Results may overlap BOOST at 667x375; the intro card covers the Timer. Record. | F19 | |
| D20 | Pet inventory (PETS). | EQUIP pill about 40 px high and the unequip X about 40 px; name and boost text not covered on short cards; X not clipped at the first row/column. | F41 | |
| D21 | Travel toast and confirm. | Toast at least 12 px, readable; may overlap the last row: record. | F44 | |
| D22 | MINI PLOWS panel. | Close X is about 41x40 px (pre-existing); check it is tappable. | known | |
| D23 | Treasure toast while driving, then Mythic announce (patch F20 installed). | Toast stays left of the column and does not cover DRIFT. It may cross the dig-combo meter: record. | F20 | |
| D24 | After every close in this part: thumbstick, jump, camera drag. | Always work. | class 10 | |

## E. Phone portrait (PP 390x844)

Not a designed layout. Only check that nothing is unreachable and nothing locks input.

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| E1 | Open each menu and popup once (offer details, equip window, egg screen, MINI PLOWS, UPGRADES, contract popup, treasure toast, Mythic announce). | Every close button can be tapped; nothing is cut off so far that it cannot be closed; thumbstick works afterwards. Known: the contract tracker starts 16 px left of the edge; overlaps with offers/DRIVE exist. | F20, F38 | |

## F. Real phone (RP) - touch input

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| F1 | Repeat D1-D4 on a real phone, landscape. On a phone with a notch or rounded corners, check the DRIVE column against the jump button and the screen edge. | Column clear of the jump button and inside the safe area. `ScreenInsets = DeviceSafeInsets` on PlowDriveGui is unverified and may move the column relative to other screens. | F02, F40 | |
| F2 | Thumbstick, jump and camera drag while the contract popup, offer details popup, egg screen, hatch reveal and loading screen are/were up. | Thumbstick never swallowed after those close. (The PetClient patch deliberately does not make the hatch overlay Active.) | class 10, F56 | |
| F3 | Tap targets: HELP/SKIP, X buttons, BUY/RESERVE/REROLL, JOIN/LATER, EQUIP pill. | Comfortable with a thumb; no mis-taps on neighbours. | class 9 | |
| F4 | Text legibility of the offer details, equip window, tracker and tutorial card at arm's length. | Readable. | class 9 | |

## G. Controller (GP)

| # | Steps | Expected | Findings | Result |
|---|---|---|---|---|
| G1 | Verity egg screen: open, press B, open again, close with X, close by closing the Shop. | B closes it only while shown; afterwards B does not stay bound (no dead B). | F06 | |
| G2 | Close every menu and popup with the controller. | Every one can be closed; movement works afterwards. | class 10 | |
| G3 | F / ButtonY drive binding, before and after the loading screen fades. | Ignored while the loading screen is up, works afterwards. | F28 | |
| G4 | Note that keyboard hints still show on a controller and RECOVER has no pad binding. | Known and deferred. | F62 | |

## H. Checks that depend on the Studio patches (after part A6)

| # | Patch | Steps | Expected | Findings | Result |
|---|---|---|---|---|---|
| H1 | RNGClient | In Play, look at RNGGui's attributes. | `CloseAllBus = true`. | F04 | |
| H2 | RNGClient | Open TRAVEL, open SHOP, press each panel's Close. | Every panel closes; the cloned Travel panel's Close works; blur never sticks. | F04 | |
| H3 | UpgradeTreeClient | Open UPGRADES from the bottom bar and from any Frostfall prompt; close with X. | Page opens and stays open; a "CloseAll" in the first 0.5 s does not close it; later ones do. X is 44x44. | F24, F60 | |
| H4 | UpgradeTreeClient | PL2 (667x375): progress pill and legend. | Pill about 120x28 clear of the hint text; legend in 2x2 on small screens, text readable. | F60 | |
| H5 | PetClient | Try to spend Snow you do not have in the pet screens. | Toast shows, no Output error, text and outline fade together; a newer toast cancels the older fade. | F09 | |
| H6 | PetClient | Fuse/obtain a Golden pet (`;pet`, machine). | Golden card appears after its base card in the inventory. | F15 | |
| H7 | PetClient | Walk away from an egg and back (egg streams out and in). | The floating chances panel is rebuilt; its transparent outer background is unchanged. | F36 | |
| H8 | PetClient | Two hatches within 4.6 s (isolated profile). | Both get a reveal (queue of up to 3; later ones can lag up to about 14 s). | F47 | |
| H9 | PetClient | Cause an error inside a hatch (if you can) or interrupt a reveal. | Overlay and blur are cleaned up. | F56 | |
| H10 | ActivityClient | Type in the Codes box while a quest/achievement push arrives. | The box is not destroyed. If the first fetch failed and you sit on CODES, a push may not redraw: known. | F67 | |
| H11 | WheelClient | Start a spin and close the wheel during the 4.5 s spin. | A "YOU WON ..." toast appears. | F68 | |
| H12 | TreasureReveal | Find a treasure while driving on a phone; trigger a Mythic announce. | See D23 and E1. | F20 | |
| H13 | LoadingScreen | Tap the screen and HUD buttons while it is up. | Taps do not reach the HUD. | F28 | |
| H14 | LoadingScreen | Use a `LoadingHold` NumberValue (remove afterwards) or a slow connection so load runs long. | The screen fades by the 40 s cap even if the load itself hangs. | F35 | |

## I. Preserved behaviour (regression sweep)

| # | Check | Expected | Result |
|---|---|---|---|
| I1 | Offer cards on D1/D2: bottom-left, right of HELP, bottom flush with TRAVEL; hidden while HELP is open. | As before (STATUS decision). | |
| I2 | MINIS left of UPGRADES; MINIS/UPGRADES/AFK centred on one line; HELP and AFK compact, no thick snow strips crowding labels. | As before. | |
| I3 | Click your own car. | Opens the equip window; there is no workbench; the title and buy toast say no WORKBENCH. | |
| I4 | No rebirth or shovel UI; no Neon in World 2. | As before. | |
| I5 | Part prices, upgrade costs, offer prices and rewards. | Same values as before; no server script, config or remote was changed in this branch. | |
| I6 | Upgrade screen layout. | Unchanged except the F60 sizes once the patch is installed. | |
| I7 | Floating egg/chances panel. | Outer background still transparent. | |
| I8 | Snowy artwork and styling on every edited screen. | Unchanged. | |

## J. Cleanup and sign-off

| # | Step | Result |
|---|---|---|
| J1 | Stop Play (your own session only). | |
| J2 | In Edit, remove `ServerStorage.BalanceTestMode`; remove any temporary `LoadingHold` or test helper. | |
| J3 | Read `Workspace.Camera.CameraType` back; it must not be Scriptable. | |
| J4 | If you accept the patches and the Rojo sync: refresh `game/studio-snapshots` from Studio, update STATUS.md with measured results, and refresh Graphify (neither was done by the audit). | |
| J5 | Record what could not be tested (real phone, controller, persistence, multiplayer, publishing) in STATUS.md. | |

## K. Results summary (fill in)

| Section | Rows | Pass | Fail | N/A | Notes |
|---|---:|---:|---:|---:|---|
| A Setup | | | | | |
| B Smoke | | | | | |
| C Desktop | | | | | |
| D Phone landscape | | | | | |
| E Phone portrait | | | | | |
| F Real phone | | | | | |
| G Controller | | | | | |
| H Patch-dependent | | | | | |
| I Preserved behaviour | | | | | |
