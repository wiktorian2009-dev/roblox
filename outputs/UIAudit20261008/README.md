# UI audit 2026-10-08 - snowplow game (branch claude/relaxed-faraday-060hsn)

Cloud-session audit of overlapping, mis-sized and stale UI. **Nothing in this folder was run in Roblox Studio, no screenshot was taken, no device was used.** Every result below is either a static Luau check, a source-derived rectangle model, or a reading of the code. Whether a fix works on screen is still to be verified by the developer with `STUDIO_VERIFICATION_CHECKLIST.md`.

Nothing was published, merged, purchased or reset. The source edits are uncommitted working-tree changes on top of `b6d2bb7` ("Initial project import"). Nothing under `game/studio-snapshots/` was edited.

## 1. Summary

| Item | Count |
|---|---:|
| Findings filed | 69 (F01-F69) |
| Confirmed | 46 (15 high, 31 medium; F29 is not among them) |
| Contested | 0 |
| Unverified (all low) | 22 (F48-F69) |
| Refuted | 1 (F29) |
| Confirmed, fixed in `game/src` (yes) | 30 |
| Confirmed, partly fixed | 9 (F04, F16, F18, F22, F23, F24, F28, F32, F38) |
| Confirmed, Studio-only script: patch written, INSTALL PENDING | 6 (F09, F15, F20, F35, F36, F47) |
| Confirmed, deferred | 1 (F45) |
| Unverified findings also deferred | 5 (F49, F51, F55, F62, F63) |
| Source files changed | 16 modified + 1 new (`game/src/ReplicatedStorage/UILayout.luau`, 134 lines); `git diff --stat`: 16 files, +1545/-284 (the new file is untracked and not in that figure) |
| Studio patch copies (INSTALL PENDING) | 7 scripts, under `outputs/UIAudit20261008/studio-patches/` |
| Layout model overlaps (BEFORE -> AFTER) | 106 -> 32 counted overlaps; 29 -> 16 distinct pairs (source-derived, not a render) |

What is still open, in one paragraph: several fixes that only take effect once the RNGClient / UpgradeTreeClient Studio patches are installed, a list of minor reviewer items (section 10), 16 residual layout-model overlaps (section 13; mostly modal panels reaching the phone action column and the undesigned portrait layout), and every runtime and device check. The three major `FrostKingClient` review items and the OfferDetails popup regression that were still open after the workflow were fixed in a follow-up (section 10).

## 2. Scope and method

**Scope.** Ten priority problem classes: (1) contract trackers/announcements covering offers and controls, (2) shop cards interfering with HELP/TRAVEL/tutorials/open menus, (3) driving controls overlapping essential HUD buttons, (4) several incompatible menus open together, (5) tutorial arrows on stale positions, (6) invisible frames/decorative images intercepting input, (7) UI left visible after respawn/travel/vehicle exit/contract cancel, (8) duplicate interfaces or event connections after repeated opening, (9) clipped text, tiny touch targets, fixed layouts on small screens, (10) close buttons leaving movement or input locked.

**Method.** Findings were produced by reading the sources, then verified, fixed by writers, source-reviewed by independent reviewers, repaired (two rounds) and re-checked with the static tools. The fix rules were: prefer anchors, layout containers, size constraints, padding, scrolling and safe-area handling; do not use a higher `DisplayOrder` as the only answer to two controls sharing space; keep intentional overlaps such as badges; keep remote names, callbacks, prices, rewards, ownership checks and server validation; keep the approved snowy art and the upgrade-screen layout.

**What was possible in the cloud session**
- Reading and editing Rojo-mapped sources in `game/src/**` (`game/default.project.json` maps only ReplicatedStorage, ServerScriptService and StarterPlayerScripts).
- Real Luau parsing and analysis (`luau-compile`, `luau-analyze`) through `tools/luau_check.py`.
- A hand-built rectangle model of the code-built screens (`layout/`).
- Writing labelled patch copies of Studio-only scripts.

**What was NOT possible**
- No Roblox Studio, no Rojo connection, no Blender, no MCP connection to Roblox. The Rojo sync of these edits into Studio has not happened.
- No Play session, so no runtime error was seen or ruled out, and no `BalanceTestMode` test was run.
- No screenshots; no device emulator; no real phone, tablet or controller; no safe-area (notch) device.
- The static GUI inside `StarterGui.RNGGui` (SnowCounter, LeftMenu/RightMenu, the BottomBar with UPGRADES, REWARDS and the Starter Pack square, SettingsCorner, the Settings panel that Travel clones, ActivityHUD) is not in the repo. Its positions and sizes could not be determined, and no fix guesses at them; where code needed them, it reads them live at runtime (for example UPGRADES' `AbsolutePosition`).
- Studio-only scripts (`StarterGui.RNGGui.*` LocalScripts, `ReplicatedFirst.LoadingScreen`) can only be fixed as patch copies. Those are PENDING.

**Line numbers.** The "audit cites" in section 5 are lines in the pre-change source (git HEAD) as quoted by the audit. They shift in the edited working tree. Snapshot cites refer to `game/studio-snapshots/...`, which are read-only reference copies of Studio, last captured on or around 2026-10-02 (see section 12 for why the base date cannot be trusted).

## 3. Tooling

| Tool | Path | What it proves | What it does NOT prove |
|---|---|---|---|
| Luau static check | `outputs/UIAudit20261008/tools/luau_check.py` (needs `LUAU_BIN` = a directory with `luau-compile` and `luau-analyze`) | Real syntax errors; analyzer diagnostics after filtering Roblox-global noise; a leftover "Unknown global" for a non-Roblox name (likely typo or undefined variable) | Layout, input, runtime behaviour, anything involving Roblox types |
| Baseline | `outputs/UIAudit20261008/baseline_luau_check.json` | The pre-change diagnostics per file (0 syntax errors anywhere) so a new diagnostic is visible | - |
| Layout checker | `outputs/UIAudit20261008/layout/check_layout.js` + `layout_model.json` + `layout_report_before.md` / `layout_report_after.md` | Rectangle overlaps, off-screen parts and touch targets under 44 px (40 px for dense controls), computed from numbers copied by hand out of the sources (each element cites file:line), for 25 scenarios x 7 viewports | Not a render of Roblox; not run in Studio; no text clipping, tutorial spotlight, toasts or billboards; static Studio frames are excluded; a clean result does not prove input works |
| `git diff --stat` | repo | Cross-check of the changed file list | - |

Regenerate: `LUAU_BIN=<dir> python3 -I outputs/UIAudit20261008/tools/luau_check.py <files...>` from the repo root; `cd outputs/UIAudit20261008/layout && node check_layout.js --section both --quiet` (add `--md FILE` to write a report; exit status 1 means counted overlaps remain in AFTER).

## 4. How to read the findings table

- **Sev**: severity from the audit. **Class**: priority class 1-10; `0` means the finding is a functional UI defect outside the ten classes (F15, F46, F47).
- **Fixed?**
  - `yes` - the change in `game/src` covers the finding as written. Checked statically only.
  - `partly` - part is fixed in `game/src`, but a named sub-case still depends on a pending Studio patch or a reviewer-reported gap is open.
  - `no - patch` - the script exists only in Studio; a PENDING patch copy was written; nothing in `game/src` changes the behaviour.
  - `no - deferred` - not changed (reason in section 9).
- Path prefixes: `SPS/` = `game/src/StarterPlayer/StarterPlayerScripts/<Name>.client.luau`; `RS/` = `game/src/ReplicatedStorage/<Name>.luau`; `SSS/` = `game/src/ServerScriptService/<Name>.server.luau`; `SNAP/` = `game/studio-snapshots/StarterGui/RNGGui/<Name>.client.luau`; `SNAP-RF/` = `game/studio-snapshots/ReplicatedFirst/<Name>.client.luau`.

## 5. Confirmed findings

| ID | Sev | Class | Audit cites (HEAD lines) | Fixed? | Outcome |
|---|---|---:|---|---|---|
| F01 | high | 1 | SPS/ContractClient:99-103,337-338; SPS/PassClient:167-179,252-271; RS/ContractConfig:14-19 | yes | HELP REQUEST pill ate offer-card taps. Pill and tracker now share one top-right slot (recomputed every RenderStepped) away from the bottom-left offer cards. `PassClient.panelsOpen` now defers to `UILayout.openMenu`. |
| F02 | high | 3 | SPS/PlowDriveClient:41-49,73-74 | yes | Phone DRIVE sat on Roblox's jump button. Touch DRIFT/DRIVE/RECOVER now live in one `TouchColumn` placed left of the live jump button (`UILayout.jumpLeftTop`). Tutorial DRIVE lookups made recursive (`FindFirstChild("Drive", true)`) so the arrow still resolves. |
| F03 | high | 3 | SPS/FrostKingClient:115,949-957; SPS/PlowDriveClient:48-49,102 | yes | Desktop "Me" HP panel moved to AnchorPoint (1,1) at (0.86,0.87); touch Me sits under the boss bar; PopupStack clears a top-centre Me panel. Layout model: 3 DRIVE/DRIFT/RECOVER-vs-Me overlaps on each desktop viewport -> 0. |
| F04 | high | 4 | SPS/TravelClient:93-123,191-206; SNAP/RNGClient:31-81 | partly | TravelClient now opens/closes through RNGClient's bus (`VillageOpenMenu` "Travel"/"CloseAll") and closes the garage family, egg screen, MINI PLOWS and HELP menu. It only uses the bus when RNGGui has attribute `CloseAllBus=true`, which the PENDING RNGClient patch sets. Until installed the old path (sibling hiding, possible stuck blur) runs. |
| F05 | high | 4 | SPS/PlowShopClient:178,328,475-498; SPS/PlowGarageClient:121-138,278-285 | yes | Offer card, equip window and inspect panel are now mutually exclusive: `closeOthers()` in PlowShopClient, `Api.CloseBuild`/`Api.CloseInspect` (stubs in PlowClientApi, overridden in the two clients), `openInspect` closes build and card first. |
| F06 | high | 4 | SPS/VerityEggClient:91-103,119,152-155,180-199 | yes | EggScreen is Active; hides when Shop closes, another Panels child opens, InGarage/InArenaIsland turns true, driving starts, or a 0.25 s poll sees another menu. Gamepad B bound only while the screen shows. DisplayOrder 103 kept. |
| F07 | high | 4 | SPS/VerityEggClient:91-95,157; SNAP/PetClient:178-190 | yes | `PetHatched` with kind "Hatched" hides the DETAILS screen so the reveal is not drawn under it. Prompt, receipt, odds and price untouched. |
| F08 | high | 6 | SPS/SnowUIClient:20-33,58; SPS/PlowGarageClient:278-285,324-351 | yes | SnowUIClient prompt cards now honour `ProximityPrompt.UIOffset` through `BillboardGui.SizeOffset`, so the R (Reroll) card is one card height from E. Sign convention (R below E) is unverified in Studio: flip it in `offsetSize()` if R lands above. |
| F09 | high | 7 | SNAP/PetClient:298-315 | no - patch | PetClient patch removes the early tween that assigned `.Delay` (throws) and fades text and stroke together after a 1.2 s hold. INSTALL PENDING. |
| F10 | high | 9 | SPS/PlowTutorialClient:119-148,207-215,675-694; SPS/PlowShopClient:433-492 | yes | `scrollIntoView` brings the EQUIP row into its list; a target under 50 % inside its ScrollingFrame window counts as missing (no dim, no ring, no click-lock). |
| F11 | high | 9 | SPS/PlowTutorialClient:68-97,502-504 | yes | Touch card min 300x150, HELP/SKIP 84x40, OK 110x44, 11 px text floor; two long hints shortened. Open minor: two-line hints may still clip in the 20 px hint label. |
| F12 | high | 9 | SPS/PlowShopClient:33-38,448-469,476-492 | yes | Equip rows are two-line (112 px, was 62 px, on every device); small screens get a short stat set (`setStats`) after review found the first version left the stats at about 7 px. `TextTruncate` combined with `TextScaled` is unverified. |
| F13 | high | 9 | SPS/PlowShopClient:33-38,178-180,197-199 | yes | Offer card description wraps; stat/compare lines keep an 11 px floor and truncate with an ellipsis on phones, so long Gear/Body stat lines lose information there. |
| F14 | high | 9 | SPS/ContractClient:85-96,99-119 | yes | 44 px HELP OUT/LATER/CANCEL/bell; Announce min 320x220; touch tracker rows 14 px high with 11 px text and scrolling (a 6-row Market job scrolls). |
| F15 | high | 0 | SNAP/PetClient:149-160; RS/PetConfig:184-206; SSS/MachineService:71-79 | no - patch | PetClient patch lays out a Golden card after each base card (LayoutOrder order*2 and order*2+1). Assumes the static PetContent grid sorts by LayoutOrder (not in repo). INSTALL PENDING. |
| F16 | medium | 1 | SPS/ContractClient:105-119,144-150; SPS/FrostKingClient:100-102,934-937 | partly | Desktop: contract slot sits below the Frost King pill/Me and the ActivityHUD pills. Touch: FK pill follows the jump button. Open: the touch boss bar (56 px min, bottom at about 62 px) overlaps the contract slot/popup column by about 2-20 px (section 10). |
| F17 | medium | 2 | SPS/TravelClient:33-35,61-81; SPS/PlowTutorialClient:929-946 | yes | The 60 s scan for HELP is replaced by `WaitForChild("PlowTutorial")` then `HelpPill` (no timeout; harmless if it never appears). |
| F18 | medium | 2 | SPS/PlowTutorialClient:182-187,905-908,969-973; SPS/PlowShopClient:178-181; SPS/PassClient:259-261 | partly | HelpMenu is Active, closes on lesson start, driving, or another menu opening (0.25 s edge poll); a pill tap closes other menus first; offers hide while it is open. RNG panels only close after the RNGClient patch (live RNGClient ignores "CloseAll"). No outside-tap dismissal. |
| F19 | medium | 3 | SPS/ArenaHudClient:69-72,81-110,151-157 | yes | Touch LEAVE ARENA and PAINT share one bottom-left stack; BOOST (88 px) and BRACE (72 px) are pixel buttons anchored from the live jump button; intro OK min 120x44. Residual minors: Status text still small, intro card covers the Timer, Results card overlaps BOOST at 667x375. |
| F20 | medium | 3 | SNAP/TreasureReveal:214-216,336; SPS/PlowDriveClient:102 | no - patch | TreasureReveal patch puts the touch toast's right edge at W-(colW+24), with a UIScale when narrower than 300 px; Announce is 0.9W capped at 440x48. Layout model still shows a toast vs dig-combo-meter overlap of about 100 px. INSTALL PENDING. |
| F21 | medium | 4 | SPS/PassClient:252-285; SPS/MiniPlowClient:64-69,154-155; SPS/VerityEggClient:91-92; SPS/PlowGarageClient:76-80 | yes | One state-based test, `UILayout.openMenu`, covers Panels, UPGRADES, garage window, offer card, inspect, egg screen, MINI PLOWS and HELP menu. MiniPlowClient closes the other menus on a MINIS tap and polls. |
| F22 | medium | 4 | SPS/PlowTutorialClient:175-196,505-511,795-803,905-908 | partly | HELP pill hidden while UpgradeTreeGui is enabled; no dim/pointer for a target not under it. Other full-screen windows (garage, egg, RNG panels) are not generically detected - the pill tap closes them instead. |
| F23 | medium | 4 | SPS/ContractClient:144-150,235-252; SPS/FrostKingClient:742-785; SPS/PassClient:252-271 | partly | Contract popup and FK announcement wait for every open menu (including HELP) and re-open. Open: FK announcement does not wait for the tutorial card on touch; FK pill ignores open menus (section 10). |
| F24 | medium | 4 | SNAP/UpgradeTreeClient:120-123,693-743; SNAP/RNGClient:58-77; SPS/PassClient:252-285 | partly | In `game/src`: offers/popups wait for UpgradeTreeGui. PENDING patches: RNGClient closes its panel and blur when the tree is enabled; UpgradeTreeClient `open()` closes HELP, egg, MINI PLOWS, garage family. Install both. |
| F25 | medium | 4 | SPS/FrostKingClient:787-796,934-937; SPS/ArenaHudClient:69-72 | yes | FK pill hidden on the arena island; `doJoin` refuses with "Leave the arena first!" before any remote call. |
| F26 | medium | 6 | SPS/PlowShopClient:178-183,476-497; SPS/PlowGarageClient:79-98,367-373; SPS/PassClient:50 | yes | OfferCard, GarageWindow, Inspect and OfferDetails are Active; the own-car click is ignored only while the GarageWindow is visible (otherwise it still calls `Api.OpenBuild()`). |
| F27 | medium | 6 | SPS/PlowTutorialClient:105-149; SPS/MiniPlowClient:53-62; SPS/AfkDriftClient:76-79 | yes | Four transparent Active ZIndex-4 blockers fill the ring around the click target (click mode only). |
| F28 | medium | 6 | SNAP-RF/LoadingScreen:14-15,61-66; SPS/PlowDriveClient:93 | partly | `game/src`: PlowDriveClient ignores the F/ButtonY binding and on-screen DRIVE/RECOVER while attribute `LoadingScreenActive` is true (the snapshot sets it). PENDING patch: Root CanvasGroup `Active=true`. |
| F30 | medium | 7 | SPS/AfkDriftClient:39-111; SPS/MiniPlowClient:63-69; SPS/ArenaHudClient:462-479; SSS/AfkService:43-50 | yes | `showButton()` uses MINIS' rule (UPGRADES shown, bar visible, not on the arena island). The DRIFT meter hides with it, and the button stays hidden if UpgradesButton is never found. |
| F31 | medium | 7 | SPS/PlowShopClient:521-528; SPS/PlowGarageClient:536-550; SSS/PlowService:386-398 | yes | The 0.5 s watcher closes the equip window when dead, no HumanoidRootPart, or more than 39 studs from the own bay pivot. A click at the 40-stud ClickDetector edge can flicker open/closed. |
| F32 | medium | 7 | SPS/ContractClient:144-150,243,285,335-337 | partly | Pill/tracker hidden in the garage, during FK UI, on the arena island and while a menu is open. NOT done: hiding the pill when the offer's world no longer matches (no world field is known client-side). |
| F33 | medium | 7 | SPS/ContractClient:250,267-269,325,336-339 | yes | The popup hides on expiry and on Ended, keyed by the shown offer id. |
| F34 | medium | 7 | SPS/FrostKingClient:816-825,938-957 | yes | Boss bar and Me panel show only at the fight, never in the garage or arena island. |
| F35 | medium | 7 | SNAP-RF/LoadingScreen:15,162-221 | no - patch | LoadingScreen patch runs `load()` in `task.spawn(pcall(...))`; the 40 s cap now covers the load itself. INSTALL PENDING. |
| F36 | medium | 7 | SNAP/PetClient:372-386,427-465 | no - patch | PetClient patch rebinds the chances sign in `makeSign` when its part is gone. Depends on how StageEggs streams. INSTALL PENDING. |
| F37 | medium | 9 | SPS/PlowTutorialClient:175-181; SPS/TravelClient:43-60; SPS/PassClient:166-181 | yes | HELP pill y = min(0.835H, H-(2h+gap+16)); writer arithmetic at 844x390: HELP y 287, TRAVEL bottom 374 (16 px margin). 1080p/720p unchanged. |
| F38 | medium | 9 | SPS/PassClient:27-32,50-67,101-111; RS/PassConfig:28-34 | partly | Small-screen popup 0.8x0.9 (width capped left of the action column), scrolling wrapped list at MinTextSize 12, BUY/CLOSE min 44. Open: layout model shows the popup still overlapping HELP, TRAVEL and the OFFERS toggle (92x40 / 120x40 each) at 844x390, 667x375, 932x430 and 390x844. |
| F39 | medium | 9 | SPS/PlowShopClient:188,206-208,237-249,435,484; SPS/PlowGarageClient:90-95 | yes | 44 px card X, BUY, RESERVE, REROLL (12 px gaps); 40 px shelf/confirm/UNEQUIP; inspect X 44x44 with `fitPanel` so it does not cover the first part row. |
| F40 | medium | 9 | SPS/PlowDriveClient:24-26,41-49,102; SPS/ArenaHudClient:50-51 | yes | One 44 px-high column; `gui.ScreenInsets = DeviceSafeInsets`. The safe-inset effect is unverified (it may shift the column relative to other screens on a notched phone). |
| F41 | medium | 9 | SNAP/PetClient:129-138; SPS/SnowArtPetScreens:19-28 | yes | Fixed in `game/src` only: touch-only EQUIP pill and unequip X get 40 px minimums; `fitCard()` lifts the name/boost rows on short cards. **No PetClient card re-layout patch was written**, despite an earlier note calling it pending. |
| F42 | medium | 9 | SPS/VerityEggClient:92-117 | yes | Touch Close 44x44, screen BUY min 120x44, small-screen layout under 600 px width, tile labels MinTextSize 11 (may wrap; unverified). Shop-card DETAILS and card BUY (Studio-sized parent) did not get 44 px minimums. |
| F43 | medium | 9 | SPS/FrostKingClient:92-131 | yes | 44 px floors on JOIN/LATER/OK/FX/SHAKE; boss bar min 56; Me min 52; Announce and Reward capped left of the action column on touch. |
| F44 | medium | 9 | SPS/TravelClient:127,153-173 | yes | Travel toast bottom-anchored, wrapped, min 36 px, 12 px text; "SURE?" resets on expiry and when another row arms. Overlap with the last list row cannot be ruled out (Settings clone rect not in repo). |
| F45 | medium | 9 | SNAP/ActivityClient:201-203,221-230; SNAP/WheelClient:84-85,143-146 | no - deferred | Panel Size is a static Studio frame; not patched blind. |
| F46 | medium | 0 | SPS/PassClient:76-100,220-235 | yes | Price labels read LOADING... / TAP TO RETRY / COMING SOON; retry on tap and every 30 s. Prices still come from the live product lookup; the explicit-click `PromptGamePassPurchase` is unchanged. Retry flips the label briefly and never stops (extra lookups in an unpublished place). |
| F47 | medium | 0 | SNAP/PetClient:260-295,316-322; SSS/PetService:14 | no - patch | PetClient patch queues up to 3 pending reveals. Reveals can lag the hatch by up to about 14 s; a fourth pending result is dropped (its sign still lights). INSTALL PENDING. |

## 6. Coverage of the ten priority classes

| Class | Confirmed findings | Note |
|---|---|---|
| 1 Contract trackers/announcements covering offers/controls | F01, F16 | |
| 2 Shop cards vs HELP/TRAVEL/tutorials/menus | F17, F18 | |
| 3 Driving controls vs HUD buttons | F02, F03, F19, F20 | |
| 4 Incompatible menus open together | F04, F05, F06, F07, F21, F22, F23, F24, F25 | |
| 5 Stale tutorial arrows | none confirmed | Related: F10, F22, F27 (tutorial spotlight). Unverified F53 (card relocation) was also fixed. |
| 6 Invisible frames/images intercepting input | F08, F26, F27, F28 | |
| 7 UI visible after respawn/travel/vehicle exit/cancel | F09, F30-F36 | |
| 8 Duplicate interfaces/connections after repeated opening | none confirmed | New code was written to connect once (poll loops, layout listeners). Not verified at runtime; the checklist repeats open/close cycles. |
| 9 Clipped text, tiny targets, fixed layouts | F10-F14, F37-F45 | |
| 10 Close buttons leaving input locked | none confirmed | The checklist verifies movement/camera after every close. |
| Outside the ten classes | F15, F46, F47 | |

## 7. Contested and unverified findings

**Contested:** none.

**Unverified (F48-F69, all low severity).** These were not independently confirmed. Writers fixed the ones that were low-risk and additive; the rest were deferred (section 9). Nothing here is claimed as verified.

| ID | Title (short) | Disposition |
|---|---|---|
| F48 | HELP menu non-Active over contract pill | Fixed in `PlowTutorialClient` (HelpMenu `Active=true`); the pill also moved to the top-right slot. |
| F49 | Treasure toast over contract tracker bottom | Deferred. |
| F50 | Activity boost pills over contract tracker | Fixed in `ContractClient` (slot sits below ActivityHUD pills, read live). |
| F51 | Tutorial card covers touch offer card header | Deferred. |
| F52 | OFFERS list never auto-collapses on phones | Fixed in `PassClient` (folds on card pick and when driving starts). |
| F53 | Card relocation never reset | Fixed in `PlowTutorialClient` (reset on showStep/stopLesson, touch low slot, real card height). |
| F54 | Drive step labels LOBBY button as DRIVE | Fixed in `PlowTutorialClient` (label and text when InGarage). |
| F55 | "Garage" lookup can resolve to Travel row | Deferred (depends on Studio child order). |
| F56 | Hatch overlay non-Active scrim, no error cleanup | Partly, in the PENDING PetClient patch: `pcall` + `resetHatch` added; `overlay.Active=true` was deliberately NOT applied (review: it would swallow touches for every reveal). |
| F57 | Leaving arena mid-intro skips intro later | Fixed in `ArenaHudClient` (`onIsland(false)` resets `introStep`). |
| F58 | Job tracker and waypoint remain after GARAGE | Fixed in `ContractClient` (hidden in the garage). |
| F59 | CANCEL label stays SURE? | Fixed in `ContractClient` (resets after 3.05 s). |
| F60 | UPGRADES close 23 px, legend/pill 16-19 px | PENDING UpgradeTreeClient patch (Close 44x44, pill 120x28, legend 2x2 on small screens). |
| F61 | Legacy TIP shows dead HELP button / SKIP skips garage lesson | Partly in `PlowTutorialClient`: HELP/SKIP hidden on the tip; not rewired to dismiss only the tip. |
| F62 | Gamepad shows keyboard hints, RECOVER unbound | Deferred. |
| F63 | Treasure book text shrinks on small panels | Deferred. |
| F64 | Reserved-part resume loops start click-locked lessons | Partly in `PlowTutorialClient` (both loops wait until idle). The Main -> Garage auto-chain is still not gated by idle (review). |
| F65 | Workbench/GARAGE previews ignore Body changes | Fixed in `PlowShopClient` (Body added to the signature). |
| F66 | "WORKBENCH" wording after removal | Fixed in `PlowShopClient`. |
| F67 | Quest push rebuilds Rewards page, destroys CodeBox | PENDING ActivityClient patch (render skipped on the Codes tab). |
| F68 | Closing Lucky Wheel during spin hides the prize | PENDING WheelClient patch ("YOU WON ..." toast when the panel is closed). |
| F69 | WheelToast not in PopupStack | Fixed in `PopupStack` (WheelToast added to WATCH, non-sticky). |

## 8. Refuted

| ID | Title | Reason |
|---|---|---|
| F29 | Arena pause/resume restarts a mid-lesson step with an empty ctx and can kill the runner | The nil-arithmetic crash at tutorial STEP 3 does not occur in the normal flow. `Earn.done` (PlowTutorialClient line 528 at HEAD) is `ctx.goal == nil or (snow() >= U.CostOf(ctx.goal) and collects - ctx.collects0 >= 3)` and `and` short-circuits. Mid-Earn, snow is below the goal cost (S_Center costs 50). The arena grants no Snow (ArenaService `grantResult` 372-389 only counts stats), so after resume `snow() >= cost` is false and `ctx.collects0` is never read. `back()` (line 526) then returns "Drive" and `Field.enter` (line 513) sets `collects0`. Reaching the throw needs 25+ Snow in 2 payouts at Starter SnowPerPhase 2, which is not reachable for a new player. No change made. |

## 9. Deferred

| ID | Reason |
|---|---|
| F45 | Rewards/Wheel panel Size is a Studio static frame (not in repo); cannot be patched blind. |
| F49 | Unverified-low and brief (2.5-5 s). The F20 patch moves the touch toast out of the DRIVE column and the tracker bottom is capped; the residual overlap has no safe spot. |
| F51 | Unverified-low. Moving the tutorial card for the offer card risks the target-slot logic. |
| F55 | Low confidence; depends on Studio child order, not demonstrated. |
| F62 | Unverified-low cosmetic. A pad-button binding may clash with gamepad defaults and cannot be tested here. |
| F63 | Low confidence; Treasures panel size is a Studio static frame. |

## 10. Open review items and known residual risks

After the workflow's two repair rounds, three **major** review items remained, all in `SPS/FrostKingClient.client.luau`. They were fixed in a follow-up by hand (static checks only, not re-reviewed by the workflow's reviewers; same Luau checker, 0 syntax errors):

1. **Boss bar vs popup column (touch)** - the touch bar is at least 56 px high. `PopupStack` now starts its column below `FrostKingGui.BossBar` while it is visible (`bossBar.AbsolutePosition.Y < 0.3H`), and `ContractClient.layoutSlot` floors the top-right slot at the bar bottom + 8. On touch the bar also hides while the Frost King announcement is up (`bar.Visible = ... and not (touch and ann.Visible)`).
2. **Announcement ignores the tutorial card (touch)** - `FrostKingClient` has its own `lessonCardUp()` (same test as ContractClient); `busy()` returns true while the card is up on touch and `hud()` steps the announcement aside and re-queues it.
3. **FK pill ignores open menus** - `pill.Visible` now also requires `UILayout.openMenu(pg, {HelpMenu = true}) == nil`, like ContractClient's pill (the bottom-left HELP menu never reaches it).

A fourth defect, found by the layout model after the workflow: the enlarged OfferDetails popup (0.8W on phones, `PassClient`) spanned HELP and TRAVEL, which draw above it (DisplayOrder 200 / 12 vs 11), so BUY could sit under HELP. `PassClient.leftClear()` now keeps the popup right of both buttons and left of the touch action column (re-applied when they move). The model also gained a boss-fight + contract-tracker scenario.

**Other open items** (reviewer-reported, not repaired; all minor unless marked):
- `PassClient`: the OfferDetails popup now stays clear of HELP / TRAVEL (follow-up above) but is narrower on phones; verify it still fits its text in Studio. Price retry flickers LOADING.../TAP TO RETRY every 30 s. Offer-card Hype labels have no `MinTextSize` (pre-existing).
- `PlowShopClient`: the equip window (0.9x0.78) reaches 38 px into the touch column at 667x375; small offer card collapses at 390x844; tutorial card hides the top of the small offer card on phones; `TextTruncate` + `TextScaled` combination unverified. **Desktop-visible changes:** equip rows are 112 px (were 62), the rarity bar is 4 px (was 8), and `descL.Text = ((def.Desc or ""):gsub("%s*A solid step up between its world's starter and premium parts%.%s*$", ""))` (line 301) removes that sentence from every offer description on every device. Accept or restrict it to `UILayout.isSmall()`.
- `PlowDriveClient`: `ScreenInsets = DeviceSafeInsets` may give this gui a different width than other screens on notched phones; after tapping DRIVE, RECOVER appears where DRIVE was, so a quick second tap hits RECOVER; `releaseDrift` runs only when drifting (pre-existing).
- `PlowTutorialClient`: 20 px touch hint label may clip two-line hints; the touch low slot (0.45H) can cover the top of the MINIS/UPGRADES/AFK strip; HELP menu opened mid-lesson overlaps the card on phones; a pill tap with an RNG panel open leaves it open until the RNGClient patch is installed; the Main -> Garage auto-chain is not gated by idle.
- `ContractClient`: tracker not hidden on the arena island; F32 world check not done.
- `TravelClient`: fallback `TravelMenu` (no Settings clone) keeps a 0.08x0.08 close X, and `UILayout.openMenu` does not test it; `closeTravel` could close a different menu opened during RNGClient's 0.12 s hide tween.
- `VerityEggClient`: window (0.62Wx0.7H) covers about 41 px of the bottom strip at 844x390 and is now Active; MinTextSize 11 tile labels may wrap at 667x375.
- `ArenaHudClient`: Status text (TextScaled, 17 px high) still reads about 9 px for the long spectator line; intro card covers the Timer; Results card overlaps BOOST at 667x375.
- `UILayout`: its header says ancestors are checked for visibility; `jumpLeftTop` only checks the jump button's own Visible/size and `TouchGui.Enabled`. `openMenu` allocates a table per call (called every frame from PassClient).
- `PlowGarageClient`: title shrinks below 12 px for long names; 40-stud click vs 39-stud watcher flicker.
- `SnowUIClient`: R-below-E sign unverified.
- `MiniPlowClient`: MINI PLOWS X is about 41x40 px (pre-existing, below 44); panel stays open when driving starts.
- Repairs after review were checked by the static tools only; they were not re-read except for `PlowGarageClient` and `FrostKingClient`. The follow-up edits (FrostKingClient, PopupStack, ContractClient, PassClient) were checked by the static tools and the layout model only.

## 11. Per-file change summary

`git diff --numstat` against HEAD, plus the new file. All paths under `game/src/`.

| File | +/- | Findings | Notes and risks |
|---|---|---|---|
| `ReplicatedStorage/UILayout.luau` (new, 134 lines) | +134 | F02, F19, F21, F23, F40 (helper) | Constants (MIN_TOUCH 44, MIN_TOUCH_DENSE 40, GAP 8, MARGIN 16, MIN_TEXT 12, COL_* touch column) and read-only helpers `isTouch`, `isSmall`, `touchColW`, `touchColLeft`, `rectIn`, `jumpLeftTop`, `openMenu`. **Untracked: must ship with the rest.** Ten scripts do `require(RS:WaitForChild("UILayout"))` with no timeout and stall if it is missing: ContractClient, PassClient, PlowDriveClient, PlowTutorialClient, PlowShopClient, PlowGarageClient, MiniPlowClient, VerityEggClient, FrostKingClient, ArenaHudClient. |
| `ReplicatedStorage/PlowClientApi.luau` | +4/-0 | F05 | No-op `Api.CloseBuild`, `Api.CloseInspect`; overridden by PlowShopClient and PlowGarageClient. |
| `StarterPlayerScripts/PlowDriveClient.client.luau` | +82/-10 | F02, F28, F40 | `TouchColumn`, safe insets, loading guard. Touch only; desktop values unchanged. |
| `StarterPlayerScripts/ContractClient.client.luau` | +236/-53 | F01, F14, F16, F23, F32, F33, F50, F58, F59 | Shared slot, 44 px touch targets, popup waits for menus and the touch tutorial card. |
| `StarterPlayerScripts/PlowTutorialClient.client.luau` | +237/-41 | F10, F11, F18, F22, F27, F37, F48, F53, F54, F61, F64 | Per-frame HUD clamp, Active HelpMenu, blockers, scroll-into-view, recursive Drive lookup. Analyzer: 21 diagnostics, same as baseline. |
| `StarterPlayerScripts/PassClient.client.luau` | +121/-43 | F21, F24 (src half), F26, F38, F46, F52 | `panelsOpen` -> `UILayout.openMenu`; OfferDetails Active, scaling and scrolling; price retry; popup hides when driving starts. |
| `StarterPlayerScripts/MiniPlowClient.client.luau` | +35/-1 | F21 | `closeOtherMenus()` on MINIS tap; one 0.25 s poll created once. |
| `StarterPlayerScripts/TravelClient.client.luau` | +73/-30 | F04, F17, F44 | `menuBus()`/`closeTravel()`, `closeOtherMenus()`, HELP lookup via WaitForChild, readable toast. Requires PlowClientApi. F04 needs the RNGClient patch. |
| `StarterPlayerScripts/PlowShopClient.client.luau` | +178/-41 | F05, F12, F13, F26, F31 (Api), F39, F65, F66 | `closeOthers()`, edge poll, short phone stats, 44 px buttons. See desktop-visible changes in section 10. |
| `StarterPlayerScripts/PlowGarageClient.client.luau` | +112/-14 | F05, F26, F31, F39 | `Api.CloseInspect`, `renderInspect`, `fitPanel`, 0.5 s bay watcher, inspect edge poll, 44 px X. |
| `StarterPlayerScripts/SnowUIClient.client.luau` | +9/-1 | F08 | `offsetSize(prompt)` -> `SizeOffset`; refreshed on `UIOffset` change. |
| `StarterPlayerScripts/VerityEggClient.client.luau` | +155/-7 | F06, F07, F42 | Active screen, `wirePanels()`, `PetHatched` hide, driving/menu poll, gamepad B, small-screen layout. |
| `StarterPlayerScripts/FrostKingClient.client.luau` | +108/-16 | F03, F16, F23, F25, F34, F43 | Desktop Me anchor, touch layout under the live BossBar, `capPanels()`, menu-aware announcement. Three open review items (section 10). |
| `StarterPlayerScripts/ArenaHudClient.client.luau` | +81/-13 | F19, F57 | Touch stack and anchors from the jump button; intro reset. |
| `StarterPlayerScripts/AfkDriftClient.client.luau` | +44/-14 | F30 | `showButton()`; the UPGRADES finder moved to the end of the file. |
| `StarterPlayerScripts/PopupStack.client.luau` | +8/-0 | F03, F69 | WheelToast in WATCH; column floors at a touch-top-centre Me panel. |
| `StarterPlayerScripts/SnowArtPetScreens.client.luau` | +62/-0 | F41 | `touchOnly()`, `minSize()` helper, `fitCard()`. |

Confirmed unchanged by `git diff --stat`: `ServerScriptService/**`, every config module, every remote definition, `PassConfig`, `PetConfig`, `default.project.json`, `STATUS.md`, and everything under `game/studio-snapshots/`.

## 12. Studio snapshot patches (INSTALL PENDING)

Each patch folder holds the patched copy (first line is a `UIAUDIT 20261008 PATCH - INSTALL PENDING` header) and a unified diff against the read-only snapshot. Paths below are under `outputs/UIAudit20261008/studio-patches/`.

| Patch copy (+ `.patch`) | Studio script it targets | Findings | Status | Lines (+/-) | Analyzer (snapshot -> patch) | Install notes |
|---|---|---|---|---|---:|---|
| `StarterGui/RNGGui/RNGClient.client.luau` | `StarterGui.RNGGui.RNGClient` | F04, F24 | INSTALL PENDING | +35/-3 | 2 -> 1 | Sets attribute `CloseAllBus=true` on RNGGui (last), handles `VillageOpenMenu` "CloseAll", hides any other visible Panels child, wires the cloned Travel panel's Close, closes on `UpgradeTreeGui.Enabled`. **Install first.** Forced close skips the 0.12 s hide tween. |
| `StarterGui/RNGGui/UpgradeTreeClient.client.luau` | `StarterGui.RNGGui.UpgradeTreeClient` | F24, F60 | INSTALL PENDING | +79/-4 | 1 -> 1 | Needs the RNGClient patch. Deviation: a "CloseAll" within 0.5 s of `open()` is ignored (`OPEN_ECHO_WINDOW`); later ones close the page. Close 44x44, pill 120x28, legend 2x2 on small screens. |
| `StarterGui/RNGGui/PetClient.client.luau` | `StarterGui.RNGGui.PetClient` | F09, F15, F36, F47, F56 | INSTALL PENDING | +86/-22 | 0 -> 0 | `overlay.Active=true` deliberately omitted. Queue of 3 can lag reveals by up to about 14 s. |
| `StarterGui/RNGGui/ActivityClient.client.luau` | `StarterGui.RNGGui.ActivityClient` | F67 | INSTALL PENDING | +8/-2 | 0 -> 0 | **Do not paste the whole file.** A review found the Studio script has newer restyling than the snapshot; apply only the three `.patch` hunks. Known narrow regression: if the first fetch failed and the player sits on CODES, a push no longer redraws. |
| `StarterGui/RNGGui/WheelClient.client.luau` | `StarterGui.RNGGui.WheelClient` | F68 | INSTALL PENDING | +6/-0 | 4 -> 4 | Closed-panel prize toast always reads "YOU WON ..." (no JACKPOT prefix). |
| `StarterGui/RNGGui/TreasureReveal.client.luau` | `StarterGui.RNGGui.TreasureReveal` | F20 | INSTALL PENDING | +47/-3 | 1 -> 1 | Touch toast right edge, UIScale below 300 px, Announce cap. Viewport change mid-slide applies from the next toast. |
| `ReplicatedFirst/LoadingScreen.client.luau` | `ReplicatedFirst.LoadingScreen` | F28, F35 | INSTALL PENDING | +18/-5 | 1 -> 1 | Root `Active=true`; load in `task.spawn(pcall(load))` with `loadDone`. A Studio-only `LoadingHold` of about 37 s or more can race the cap. |

Analyzer counts were re-run by the docs writer (7 patch copies: 0 syntax errors, 8 diagnostics in total, none beyond the snapshot baselines).

**How to install each patch (manually, in Studio)**
1. In Studio, open the target script from the table (for example `StarterGui.RNGGui.RNGClient`). Copy its live `Source` to a scratch file.
2. Diff the live source against the repo snapshot `game/studio-snapshots/<same path>`. The snapshot is only a reference copy and the capture date in the patch headers (2026-10-02) is approximate: for example WheelClient's own header is dated 2026-10-03 and STATUS.md line 437 records that nine mirrors, including WheelClient, were refreshed around 2026-10-05, so Studio may be newer than the snapshot.
3. Diff the live source against the patch copy, or read the `.patch` hunks. If live equals the snapshot, you may replace the Source with the patch copy (except ActivityClient - hunks only). If live has drifted, re-apply the hunks by hand on top of the live source; never overwrite newer Studio edits (AGENTS.md).
4. Remove the `UIAUDIT ... INSTALL PENDING` header line only when you consider the patch installed.
5. Install order: RNGClient, UpgradeTreeClient, then the rest in any order. After installing, refresh `game/studio-snapshots` from Studio and record it in STATUS.md (not done here).

## 13. Layout check results and limitations

Re-run by the docs writer with `node check_layout.js --section both --quiet`:
- **BEFORE** (git HEAD `game/src` + untouched snapshots): 106 counted overlaps, 29 distinct element pairs; 5 partly off-screen element/viewport combinations; 83 touch-target combinations below 44 px (40 px dense).
- **AFTER** (working tree + PENDING patch copies of TreasureReveal and UpgradeTreeClient): 32 counted overlaps, 16 distinct pairs; 1 partly off-screen combination; 3 touch-target combinations below minimum, plus 20 accepted at the dense 40 px allowance (HELP, TRAVEL, OFFERS toggle, tutorial card HELP/SKIP).
- Model: 25 scenarios x 7 viewports (1920x1080, 1366x768, 1280x720, 844x390, 667x375, 932x430, 390x844 portrait - not a designed layout, so its hits weigh less); 59 known elements, 10 unknown (excluded), 2 assumed probes (never counted). The reports were regenerated after the follow-up edits (24 scenarios + the boss-fight / contract-tracker scenario added later).

**Remaining AFTER overlaps (16 pairs)**

| Pair | Where | Meaning |
|---|---|---|
| UPGRADES legend / hover tooltip | desktop, 18 px | Snapshot script, unchanged by the patch. |
| Dig combo meter / treasure toast | phones, up to about 100 px | The patched toast moved left of the action column onto the combo meter. |
| Tutorial card / HELP menu | phones | Only if HELP is tapped mid-step (pill has no lesson guard). |
| Arena standings / feed | 844x390, 667x375, 13-18 px | Unchanged from BEFORE. |
| DRIVE column / MINI PLOWS panel, Inspect panel, Egg screen | 667x375, 9-18 px | Modal panels reach the column. |
| Offers column / DRIVE; popup / DRIVE; HELP, TRAVEL / OfferCard; HELP / Egg; tree title / pill | 390x844 portrait only | Not a designed layout. |

BEFORE-only pairs that are gone from AFTER include offers column vs HELP REQUEST pill (desktop), HELP REQUEST pill vs HELP menu, FK Me vs DRIVE/DRIFT/RECOVER (desktop), DRIFT vs treasure toast, LEAVE ARENA vs PAINT, arena standings/feed vs BOOST, DRIVE vs RECOVER, HELP pill vs FK Me, and offers column vs MINI PLOWS / Inspect panel.

**Limitations**
1. Source-derived only: no Studio, no screenshot, no input test.
2. Static Studio frames (UPGRADES strip including MINIS and AFK, REWARDS and Starter Pack square, LeftMenu/GARAGE, SnowCounter, SettingsCorner, Travel panel, ActivityHUD) are excluded, so overlaps with them are not detected. The contract slot ignores the ActivityHUD pills and uses a fallback strip top of H-92.
3. Assumed values: top-bar inset 36 px (desktop) and 58 px (phone), notch insets 0, ArenaHud inset-respecting, MiniPlowGui IgnoreGuiInset=true, jump-button size from memory (probe only). Sensitivity (re-measured after the follow-up): phone inset 36 gives BEFORE 109 / AFTER 32; ArenaHud treated as IgnoreGuiInset=true gives 102 / 28; tolerance 0 px instead of 4 gives 187 / 67.
4. Rectangles only: no text clipping, tutorial spotlight/pointers, toasts, billboards or per-frame text. Frost King Msg/Hint/Reward, the Announce/Reward width caps, Arena results/intro cards, Dig callout and SnowPrompt billboards are not modelled.
5. Scenario visibility is the author's reading of the code; UIScale pop-ins are assumed finished.
6. The model's numbers were copied by hand; a later source edit is not picked up unless the model is updated.

## 14. Static check results

Re-run by the docs writer on 2026-10-08 with `luau_check.py`:
- 17 changed/new source files: **0 syntax errors**. Analyzer diagnostics: 54 in total against a baseline of 57 for the same files (ArenaHudClient 3 -> 2, FrostKingClient 2 -> 1, TravelClient 2 -> 1; all others equal); `UILayout.luau` 0. After ignoring line numbers embedded in message text (PlowTutorialClient and SnowArtPetScreens "ImplicitReturn ... explicit return at line N"), no new diagnostic appears.
- 7 patch copies: **0 syntax errors**, 8 diagnostics in total, equal to or below each snapshot's baseline.
- This proves syntax and a class of undefined-name mistakes only.

## 15. Not done, not claimed

- Not run in Studio: nothing. Not tested on any device: nothing. No Rojo sync. No snapshot refresh. Graphify not refreshed. `STATUS.md` and `PROJECT.md` not edited.
- Not claimed: that any overlap is gone on screen, that any text is legible, that touch input or safe areas behave, that any Studio patch works.
- Not changed by design: economy, prices, rewards, remote names, ownership checks, server validation, player data, the approved snowy art, the upgrade-screen layout (except the pending F60 sizes), the transparent outer background of the floating egg/chances panel, the accepted STATUS.md decisions (offer cards bottom-left beside HELP and flush with TRAVEL, MINIS left of UPGRADES, centred MINIS/UPGRADES/AFK line, compact HELP/AFK, phone driving via `CharacterContext.MoveAction`, own-car click opens the equip window, no workbench, no rebirths/shovel, no Neon in World 2).

## 16. Files in this folder

- `README.md` (this report), `STUDIO_VERIFICATION_CHECKLIST.md`, `PR_BODY.md`
- `baseline_luau_check.json`, `tools/luau_check.py`
- `layout/` - `check_layout.js`, `layout_model.json`, `layout_report_before.md`, `layout_report_after.md`
- `studio-patches/` - 7 patch copies + 7 `.patch` diffs
