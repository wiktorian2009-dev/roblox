# Upgrade icon remaster — 2026-10-05

## State
Installed permanently in Edit in place 94130990350526 after the user stopped Play. UpgradeIconArt, UpgradeTreeClient and the main Upgrades button use the artwork. The art installation preserved economy/layout/callbacks. Not published. Later source changes are recorded in the latest STATUS.md; captures here describe the 2026-10-05 installation.

20 AI-generated transparent art assets are exported as 512x512 RGBA PNGs in icons/. Originals are copied without changes to originals/. The gallery shows the images, their full generation prompts and the upgrade IDs each serves.
Generation mode: new image / transparent background; no visual reference image. All artwork used the built-in imagegen tool. Export processing only removes fully transparent border, uniformly scales and pads; it does not draw, recolor or remove an opaque background.

## Files
- gallery/index.html — visual gallery with prompts and affected IDs.
- preview-grid.png — contact sheet.
- assets.json — dimensions, alpha and edge QA.
- generation-results.json — prompts and original generated image locations.
- asset-map.json — 20 real uploaded Roblox image IDs plus the 138-node image map.
- node-art.json — upgrade ID to art-family key.
- live-before.json — source/effective-node capture from the beginning of the task, a reference rather than a later overwrite source.
- UpgradeIconArt.luau — presentation-only module ready for ReplicatedStorage.
- UpgradeTreeClient.prepared.client.luau — preview of six guarded icon-rendering replacements. Do not overwrite newer live GUI source with this full preview.
- install-edit.luau — actual installer: requires Edit and the right place, rereads the live GUI source, validates six exact single-match anchors before any writes, and makes a recoverable ServerStorage backup.
- preload-check.json — client ContentProvider result for all 20 uploaded images.

## Installed integration
UpgradeIconArt resolves node icons in UpgradeTreeClient. Legacy tint/rainbow gradients are suppressed for full-color PNGs and preserved for fallback old art. The existing BottomBar.UpgradesButton.Icon uses the new menu PNG.
All 138 known node IDs are mapped, with effect-family fallback for newly added nodes. UpgradeConfig effects, costs, adjacency, IDs, positions, callbacks, purchases and layout stay unchanged.

## Verification
- All 20 PNG exports: 512x512 RGBA, true alpha 0–255, edge alpha 0 and at least 33px padding at the visible-alpha threshold.
- Read-only visual QA passed at 64/80px on owned blue, affordable green and unavailable red backgrounds; final elite/cosmic variants remain distinct.
- All 20 actual uploaded images returned Success through typed ImageLabel ContentProvider preload on the current client. Unparented temporary ImageLabels were destroyed afterward; no test UI/data/source was altered.
- Installation re-read Edit source and validated all six single-match art replacements. Both installed scripts compiled in Studio.
- Fresh isolated Play: real UPGRADES opened/closed; all 138 config IDs resolved, actual icon assignments had no mismatches, and all 20 typed preloads returned Success. No upgrade purchase or persistence test.
- The earlier parser/Play-blocked preparation is superseded by installation. Screenshots and detailed QA: ../NewFeatureSnowyUI20261005/. Installed captures: final-sources.json, source-hashes.json, final-gui-properties.json.

## Recovery and next action
Backup: ServerStorage.UpgradeIconRemasterBackup_20261005. The guarded installer intentionally aborts on this installed place; do not blindly replay it or overwrite newer sources with the prepared GUI.

Fresh installed sources were mirrored to UpgradeIconArt.luau and the Studio-managed UpgradeTreeClient snapshot; Rojo scope was preserved. Graphify was refreshed. Own isolated Play was stopped and BalanceTestMode removed in Edit. Actual upgrade buying and real persistence remain separate.

