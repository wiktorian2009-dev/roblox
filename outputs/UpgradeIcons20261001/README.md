# Upgrade icon PNG pack — 2026-10-01

46 newly generated transparent PNGs: the main Upgrades button, 10 Snow upgrades and all 35 Misc upgrades. Six existing Snow PNGs are included unchanged with "-existing" filenames. Existing shovel-size, luck and dice artwork was preserved.

Every PNG is an individual asset. The new artwork matches the glossy cartoon style of upgrades_icon/quick spin.png. No text is baked into the new icons; the existing GUI supplies names, prices and states.

## Current installation
- Live place: money (94130990350526).
- Main icon: StarterGui.RNGGui.BottomBar.UpgradesButton.Icon, rbxassetid://87279285340022; PlaceholderIcon hidden.
- 51 new Icon fields added to ReplicatedStorage.UpgradeConfig (45 new art + 6 existing local art); all 86 nodes now have icons.
- Canonical game/src/ReplicatedStorage/UpgradeConfig.luau matches the verified live source. Prices, effects, stage locks, ownership IDs and upgrade layout were preserved.
- Backups: ServerStorage.UpgradeIconBackup20261001 contains OriginalMainIcon and OriginalUpgradeConfig; before/after config sources are also saved here.
- Existing UpgradeTreeClient uses n.Icon; its current v3 source is copied here for reference and in game/studio-snapshots/ for Graphify only. Do not edit the snapshot expecting Studio sync.

## Files
- manifest.json: every filename, upgrade ID, original generated file, upload ID and prompt.
- commonPrompt + each job's prompt reconstructs the submitted imagegen prompt. Style reference: C:/Users/wikto/Desktop/Roblox Gra/upgrades_icon/quick spin.png.
- asset-map.json: upload IDs for all 51 individual icons and the main button.
- preview-grid.png: overview of the 46 new icons.
- qa.json: actual pixel sizes, RGBA alpha extrema and visible bounds. Bounds ignore alpha <=16 (nearly transparent edge specks); original PNG alpha is preserved.
- UpgradeIcons.zip: PNGs plus this README, manifest, asset map and QA report.

## Verification
46/46 new PNGs are square RGBA with genuine transparency and visible artwork clear of the edges. The current UpgradeConfig compiles and contains 86 icons. All 52 uploaded images returned Success when preloaded through ImageLabel instances in Edit. Passing raw ID strings to PreloadAsync returned Failure for both new and old working images, so that check was replaced with the typed ImageLabel check.

No Play session, progression/persistence test, save or game publishing was performed by this task. Review the upgrade screen in the next Play session, especially on a phone-sized viewport. Individual source helpers in this folder are task records, not recurring sync tools.

