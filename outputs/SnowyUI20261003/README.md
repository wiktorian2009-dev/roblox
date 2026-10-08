# Snowy GUI — 2026-10-03

Applied to live Roblox Studio place `money` (94130990350526), in Edit. Not saved or published by Codex.

## Result

- Shared snowy PNG panel/card/button treatment for the existing main menus, collections, HUD cards, Rewards, roll/reveal cards, tutorial, interaction prompts and player-facing signs.
- Generated Damage sword and Rewards gift icons; gift, quest, achievement and code category artwork.
- Winter loading illustration, snowflake emblem/progress marker and frosted tip chip.
- Real pet/egg ViewportFrames and existing shovel/treasure art remain in use. Floating egg/chances outer backgrounds remain fully transparent.
- The entire upgrade screen was explicitly excluded by the user. UpgradeTreeClient matches the source captured before this task. HEX is an unused spare PNG, not applied.
- All seven menu close controls now have a visible X. The Rewards list/grid sizing defect was fixed; its original zero-height aspect-constrained containers could collapse.
- Existing button callbacks, roll/equip/hatch/reward logic and progression configuration remain in their original scripts.

## Art and source files

10 PNGs generated with the **built-in image generation tool**, not API mode. Prompts are in [prompts.json](prompts.json). Upload IDs and use status are in [uploaded-assets.json](uploaded-assets.json) and [asset-usage.json](asset-usage.json). The HEX spare is marked unused.

The nine transparent originals are 1254 x 1254 RGBA; the loading background is 1536 x 1024 RGB. Uploaded Roblox square textures are sampled at 1024 pixels, with nine-slice coordinates adjusted accordingly. Button texture sampling uses ImageRectOffset/ImageRectSize; the original PNG was not resampled.

[SnowyUI-PNGs.zip](SnowyUI-PNGs.zip) includes the artwork, prompts and upload/use metadata.

[final-sources.json](final-sources.json) contains the six exact final live sources and canonical mirror paths. [source-hashes.json](source-hashes.json) records verified mirror hashes. Mapped scripts are in game/src; Studio-managed UI/loading scripts are in game/studio-snapshots. The local folder still cannot reconstruct the full place or GUI hierarchy by itself.

## Checked

- All six final sources compile with Studio loadstring.
- Fresh isolated Play: loading illustration, main HUD icons, inventory appearance, snowy cards, Rewards tabs and visible close button.
- Rewards Daily rows have positive dimensions; Quests (4), Achievements (20) and Codes (2) had no collapsed top-level rows. Clicking Rewards Close hides the panel.
- Seven loaded World 1 egg/chances signs retain BackgroundTransparency = 1 on the outer frame.
- A custom Snowy Egg proximity prompt was constructed in Play; full keyboard/touch interaction and purchase/hatch completion were not comprehensively tested.
- UpgradeTreeClient source unchanged; no SnowArt under UpgradeTreeGui in Play.
- Final Play console had no application-script errors. Studio virtual-mouse navigation emitted CoreGui warnings during test automation.
- Codex's Play stopped; BalanceTestMode removed in Edit; temporary LoadingHold absent. This isolates the main progression service only. Saving/persistence was not tested.
- Full mobile/controller layout and every rare reveal/claim/hatch path remain unverified.

Graphify refreshed from game/: **553 nodes, 1071 edges, 50 communities**. It maps mirrored code, not Studio-only geometry or the live GUI hierarchy.

## Recovery and future edits

Before sources and GUI property snapshots are in [before-sources.json](before-sources.json) and [before-gui.json](before-gui.json); live backup StringValues are under ServerStorage.SnowUIBackup20261003. [before-local](before-local) preserves the six prior mirrored files that existed.

To revert, work in Edit and inspect current scripts first so later Claude/Codex changes are not overwritten. Restore the four original modified source scripts from the backup; disable/remove SnowUIClient; remove SnowUIDecor/SnowArt and SnowCloseText decorations; restore replaced Background/Damage/Rewards images and original close/background properties from before-gui.json; show the preserved GiftIcon viewports and Damage.PlaceholderIcon. Remove SnowUI only after no scripts require it. The property snapshot is a recovery reference, not a complete .rbxl export.

Do not run patches.json as an installer: it represents the initial patch preparation, before subsequent rendering/layout fixes. Use final-sources.json for the completed sources. Do not connect a stale Rojo server over this place. No active Rojo connection was verified during this task.

