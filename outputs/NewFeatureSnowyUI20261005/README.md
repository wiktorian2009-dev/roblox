# Snowy feature GUI and icons — 2026-10-05

Installed permanently in Edit in place 94130990350526 (`money`). Not published.

## Result

- TRAVEL uses a generated icy portal icon on the HUD and menu header. Existing travel locks, warning/confirm behavior and destinations remain intact.
- DRIFT, EXIT and RECOVER have matching PNG icons and a thin winter rim. DRIVE uses the plow recovery icon until seated; the button then switches to the exit doorway icon. Existing key, gamepad and hold inputs remain.
- SPIN uses the new snowy prize-wheel artwork on the menu and header. The functional reward wheel and its spin animation are preserved.
- Three paid-offer cards and the details popup use matching artwork and rims. Sales remain disabled, IDs remain nil, and COMING SOON remains. Pass prices/grants were not changed.
- Contract announcement, available pill, tracker and buttons have blue winter styling. Real NPC thumbnails and live objective/timer/reward data remain. Offers now hide while the contract announcement or tracker is visible, avoiding the overlap shown by the user.
- Earlier pending upgrade artwork was also installed: 20 assets and all 138 upgrade IDs. See ../UpgradeIconsRemaster20261005/README.md.

Only these feature controls are styled through FeatureUIArt; the existing SnowUI helper was not globally changed. Semantic green/red/grey/purple fill colors remain. Decorative images do not capture input.

## Artwork

Built-in imagegen; new transparent images without visual-reference input. Full prompts and source paths are in generation-results.json and the gallery. Nine icons are 512×512 RGBA, plus a 1024×540 transparent reusable rim. Originals are preserved unchanged. Export processing only crops transparent padding, uniformly scales and pads.

[Open the PNG gallery](gallery/index.html). [Contact sheet](preview-grid.png).

| Key | Roblox image ID |
|---|---|
| teleport | 100711932796017 |
| drift | 101962507757419 |
| exit | 93108001168663 |
| recover | 74283059200242 |
| spin | 75831282782683 |
| snow-pass | 118980978543857 |
| starter-pack | 109621099381649 |
| aurora-wheels | 106686963600706 |
| contracts | 137445702736979 |
| hud-frame | 98043688858057 |

The rim samples ImageRectOffset(0,78), ImageRectSize(1024,386), with SliceCenter(240,90,784,306). Its responsive extent protects the white caps and aligns the native fill. This corrected an inset/stretch artifact found in the first playtest. One border remains after successful preload; native strokes provide a fallback on loading failure.

## Verification

All 10 new images and all 20 upgrade images returned ContentProvider Success; temporary preload labels were destroyed. Nine final live scripts compile through Studio loadstring. All 138 current upgrade IDs resolve, with no mismatched actual node images.

A fresh isolated Play used BalanceTestMode set in Edit. Actual mouse input opened/closed Travel, Spin, upgrade board and the Starter Pack details. Driving seated the starter plow, changed DRIVE to EXIT, exposed DRIFT/RECOVER, and returned to DRIVE on exit. Pointer press/release on DRIFT and RECOVER were checked; driving physics were not changed or broadly retested.

Contract screenshots use explicit mock Offer/Accepted/Ended payloads delivered through existing client handlers. Six objectives, timer, progress, reward, thumbnail and card suppression rendered correctly; no server job was created and no rewards were granted. Actual job completion was not tested in this artwork task.

Screenshots: screenshots/. Machine-readable results: qa.json. The console showed no application GUI errors; virtual mouse movement logged CoreGUI warnings and one read-only QA snippet had a corrected nil test-field error.

Own Play is stopped. BalanceTestMode and NewFeatureUITestOwner are removed in Edit. Own upload helper is stopped. No publishing, real purchase or DataStore persistence test; physical touch/gamepad devices were not tested.

## Sources and recovery

Fresh Edit captures: final-sources.json; UTF-8 SHA-256: source-hashes.json; main upgrade icon property: final-gui-properties.json. Nine relevant mirrors were refreshed:
- game/src/ReplicatedStorage: FeatureUIArt, UpgradeIconArt, PassConfig.
- game/src/StarterPlayer/StarterPlayerScripts: TravelClient, ContractClient, PlowDriveClient, PassClient.
- game/studio-snapshots/StarterGui/RNGGui: WheelClient (new snapshot), UpgradeTreeClient.

default.project.json and Rojo scope are unchanged. GUI/geometry remain Studio-managed. The mirror is not a complete place export. Graphify was rebuilt code-only and clustered without labels: 977 nodes, 2,059 edges, 69 communities. UpgradeTreeClient remains partially extracted around Luau syntax; its live compilation passed.

Recovery: ServerStorage.NewFeatureSnowyUIBackup_20261005 contains the six original scripts. ServerStorage.UpgradeIconRemasterBackup_20261005 holds the earlier upgrade client/icon. Disk sources replaced by mirroring are in before-mirrors/. before-sources.json captures the pre-install baseline.

install-edit.luau contains the corrected helper and guards against replay on this already-installed place. patches.json includes all six script changes. Do not overwrite future live sources with these full captures; compare and re-read the affected source first.

