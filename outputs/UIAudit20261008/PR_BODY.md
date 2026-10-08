## UI audit 2026-10-08: overlapping HUD, stacked menus, stale UI and phone-size controls

Source-only fixes for overlapping, mis-sized and stale UI in the snowplow game, plus labelled patch copies for the Studio-only scripts. **Nothing was run in Roblox Studio, no screenshot was taken and no device was used.** This is a cloud-session change: it still has to be synced into Studio with Rojo, the Studio patches installed by hand, and the checks in `outputs/UIAudit20261008/STUDIO_VERIFICATION_CHECKLIST.md` run before anyone calls it working.

Nothing was published, merged, purchased or reset. No real player data was touched, no Robux purchase was made, and no publish was attempted.

Full report: `outputs/UIAudit20261008/README.md` (findings table, refuted/deferred findings, open items, layout results, patch table).

### Numbers

- 69 findings filed: 46 confirmed (15 high, 31 medium), 22 unverified (low), 1 refuted (F29), 0 contested.
- Of the 46 confirmed: **30 fixed in `game/src`**, **9 partly fixed**, **6 patch-only** (Studio scripts, INSTALL PENDING), **1 deferred** (F45, a static Studio frame). Five unverified findings are also deferred (F49, F51, F55, F62, F63).
- 16 source files modified, 1 new (`game/src/ReplicatedStorage/UILayout.luau`), `git diff --stat`: +1545/-284 in the 16 modified files. 7 Studio patch copies. Nothing under `game/studio-snapshots/`, `game/src/ServerScriptService/`, or any config/remote definition was changed.

### Concrete UI problems addressed

1. **Contract UI covering offers and controls (F01, F16, F14, F50).** The HELP REQUEST pill sat on the offer cards and ate their taps. Pill and tracker now share one top-right slot below the Frost King pill and Activity pills; on phones the slot sits left of the touch action column. Contract popup/tracker buttons are 44 px on touch.
2. **Shop cards vs HELP/TRAVEL/open menus (F17, F18, F37).** TRAVEL follows the HELP pill (no 60 s scan); the HELP menu is Active and closes itself when a lesson starts, driving starts or another menu opens; HELP and TRAVEL are clamped inside the screen on short phones.
3. **Driving controls overlapping HUD (F02, F03, F19, F40; F20 as patch).** Phone DRIFT/DRIVE/RECOVER are one 44 px column placed from the live jump button; the Frost King "Me" panel no longer hides DRIVE/EXIT/DRIFT/RECOVER on desktop; Arena touch buttons are stacked or anchored from the jump button.
4. **Several incompatible menus open together (F04-F07, F21-F25).** A shared, state-based `UILayout.openMenu` lets offers, popups and announcements wait for any open menu (RNG panels, UPGRADES, garage window/card/inspect, egg screen, MINI PLOWS, HELP). Garage card, equip window and inspect close each other; the Verity DETAILS screen is Active and closes with the Shop, other panels, the garage, the arena or driving; TRAVEL and MINI PLOWS close other menus.
5. **Stale tutorial pointers (F10, F22, F53).** The EQUIP step scrolls its row into view, and no dim or ring is drawn for a target that is hidden or under the UPGRADES page; the touch card resets and tests its real height.
6. **Invisible frames intercepting input (F08, F26, F27, F28).** Garage card/window/inspect and OfferDetails sink input; the own-car click is ignored while the equip window is visible; four transparent blockers fill the tutorial spotlight ring; Pedestal E and R prompts no longer render at the same spot; PlowDriveClient ignores F/ButtonY while the loading screen is up.
7. **UI left visible (F30-F34; F09, F35, F36 as patches).** AFK hides on the arena island; the equip window closes when you walk away from your bay; the HELP REQUEST popup hides when the offer expires; Frost King boss bar and Me panel show only at the fight.
8. **Text and touch targets on small screens (F10-F14, F37-F44, F46).** Two-line equip rows, wrapped offer text with an 11-12 px floor, 40-44 px buttons, scrollable offer details with a retry on failed price lookups.
9. **Classes 5, 8 and 10:** the audit confirmed no defect filed under these classes (item 5 above is related tutorial-spotlight work). That is not proof they are fine: duplicate connections and leaked input locks are not verified at runtime. New polling and listeners were written to connect once, and the checklist repeats open/close cycles and checks that movement and camera still work after every close.

### What changed and why

- **New `ReplicatedStorage.UILayout`** (134 lines, no requires, nothing created): touch/small-screen tests, the single touch-column geometry, `jumpLeftTop` and `openMenu`. Used instead of per-script copies so every screen asks the same question.
- **Approach:** anchors, `UIListLayout`, `UISizeConstraint`/`UITextSizeConstraint`, scrolling and `ScreenInsets`. No new UI framework. No `DisplayOrder` change was used as the only fix for shared space.
- **`PlowClientApi`:** `CloseBuild` and `CloseInspect` no-op stubs, overridden by `PlowShopClient` and `PlowGarageClient`.
- **Touch-only values** (44 px, column geometry, small-screen layouts) keep desktop values unchanged, except the desktop-visible `PlowShopClient` changes listed below.
- **Preserved:** remote names, callbacks, prices, rewards, ownership checks, server validation, economy, monetization and player data (no server file changed), the approved snowy artwork, the upgrade-screen layout, the transparent egg/chances panel background, and the accepted STATUS.md decisions (offer cards bottom-left beside HELP and flush with TRAVEL and hidden while HELP is open, MINIS left of UPGRADES, centred MINIS/UPGRADES/AFK line, compact HELP/AFK, phone driving via `CharacterContext.MoveAction`, own-car click opens the equip window, no workbench, no rebirths or shovel, no Neon in World 2).
- Per-file summary and findings per file: README section 11.

### Checks actually performed (static and arithmetic only)

- **Luau parser and analyzer** (`outputs/UIAudit20261008/tools/luau_check.py`): the 17 changed or new source files have 0 syntax errors, and the analyzer reports 54 diagnostics against a baseline of 57 for the same files (no new kinds; ArenaHudClient, FrostKingClient and TravelClient each lost one). The 7 patch copies have 0 syntax errors and no more diagnostics than their snapshots. This proves syntax and undefined names only.
- **Source-derived layout model** (`outputs/UIAudit20261008/layout/`, run with plain Node): 25 scenarios x 7 viewports; counted overlaps 106 (29 distinct pairs) before, 32 (16 pairs) after; touch targets below minimum 83 -> 3 combinations. Rectangles computed from numbers copied out of the code; static Studio frames are excluded. It is not a render and not a Studio result.
- **Plain-Luau arithmetic test** of `UILayout` with fake instances (writer's note): geometry and the `openMenu` order/ignore logic only.
- **Patch check** (reviewer): `ActivityClient.client.luau.patch` dry-ran against an older Studio copy (`outputs/ShovelRemoval20261005/before/StarterGui.RNGGui.ActivityClient.luau`); hunks 2 and 3 apply with offsets and the result passes the Luau check.
- **Source review rounds** by independent reviewers (reading the code, arithmetic on sizes), followed by two repair rounds.
- `git diff --stat` cross-check of the changed file list; confirmed no change under `game/studio-snapshots/`, `ServerScriptService` or config modules.

**Not performed:** no Studio, no Play, no BalanceTestMode run, no Rojo sync, no screenshots, no device emulator, no real phone, no controller, no safe-area device, no multiplayer, no persistence, no publish.

### Snapshot patches requiring manual installation (INSTALL PENDING)

`game/studio-snapshots/**` was not edited. Each patch copy has a `UIAUDIT 20261008 PATCH - INSTALL PENDING` first line and a `.patch` diff, under `outputs/UIAudit20261008/studio-patches/`. To install: open the live Studio script, diff it against the snapshot and the patch, and re-apply on top of the live source (do not overwrite newer Studio edits).

| Patch copy | Studio script | Findings |
|---|---|---|
| `StarterGui/RNGGui/RNGClient.client.luau` (install first) | `StarterGui.RNGGui.RNGClient` | F04, F24 |
| `StarterGui/RNGGui/UpgradeTreeClient.client.luau` | `StarterGui.RNGGui.UpgradeTreeClient` | F24, F60 |
| `StarterGui/RNGGui/PetClient.client.luau` | `StarterGui.RNGGui.PetClient` | F09, F15, F36, F47, F56 |
| `StarterGui/RNGGui/ActivityClient.client.luau` (apply the hunks only, not the whole file) | `StarterGui.RNGGui.ActivityClient` | F67 |
| `StarterGui/RNGGui/WheelClient.client.luau` | `StarterGui.RNGGui.WheelClient` | F68 |
| `StarterGui/RNGGui/TreasureReveal.client.luau` | `StarterGui.RNGGui.TreasureReveal` | F20 |
| `ReplicatedFirst/LoadingScreen.client.luau` | `ReplicatedFirst.LoadingScreen` | F28, F35 |

Until the RNGClient and UpgradeTreeClient patches are installed, F04 (stuck blur / two menus), the RNG-panel part of F18 and F24 keep their old behaviour; the new `game/src` code falls back to the old path.

### Remaining runtime and device verification

Everything. In particular:
- Rojo sync and the 10 scripts that `WaitForChild("UILayout")` without a timeout (they stall if the new ModuleScript is not synced).
- Phone landscape at 844x390 and 667x375, portrait, a real phone (touch, thumbstick, notch/safe area; `ScreenInsets = DeviceSafeInsets` and the jump-button path are unverified), and a controller.
- Whether the Studio device emulator reports a keyboard and therefore keeps the desktop layout.
- Unverified assumptions: `TextTruncate` with `TextScaled`, the `SizeOffset` direction for the R prompt, UIListLayout/AutomaticSize results, and the unknown static RNGGui frames.
- BalanceTestMode (set in Edit before Play, removed after) and the camera rule (never leave `CameraType` Scriptable) are in the checklist.

### Open items and behaviour changes to review

- **Follow-up fixes after the workflow's last review round (static checks + layout model only, not re-reviewed by reviewers):** the three `FrostKingClient` major items (touch boss bar vs popup column and contract slot; announcement now waits for the tutorial card on touch; pill waits for open menus) via `FrostKingClient`, `PopupStack` and `ContractClient.layoutSlot`, and the `PassClient` OfferDetails popup, which now stays clear of HELP/TRAVEL.
- Accepted residual overlaps (README section 13): the patched treasure toast can cross the dig-combo meter on phones for a few seconds (it moved off the DRIVE column); modal panels reach the phone action column at 667x375; the tutorial card vs the HELP menu if HELP is tapped mid-step.
- `PlowShopClient` changes that also apply on **desktop**: equip rows are 112 px (were 62), the rarity bar is 4 px (was 8), and the sentence "A solid step up between its world's starter and premium parts." is removed from offer descriptions. Accept, or restrict to `UILayout.isSmall()`.
- Not done: F32 "hide the pill when the offer's world differs" (no client-side world field); F22 covers only the UPGRADES page; F45 and five unverified findings deferred (README section 9). F29 was refuted.
- The full list of reviewer-reported minor items is in README section 10.

### Test plan

- [ ] Run `outputs/UIAudit20261008/STUDIO_VERIFICATION_CHECKLIST.md` parts A-K (desktop 1920x1080 and 1280x720, phone landscape 844x390 and 667x375, portrait, real phone, controller).
- [ ] Install the 7 Studio patches by hand and run part H.
- [ ] Remove `ServerStorage.BalanceTestMode` in Edit afterwards and confirm `Workspace.Camera.CameraType` is not Scriptable.
- [ ] Update STATUS.md with the measured results and refresh `game/studio-snapshots` after the Studio installs.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01FU6WAF2TJzV5gsuXPpm4mu
