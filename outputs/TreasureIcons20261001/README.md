# Treasure icons — PNG art pack (2026-10-01, Claude)

The Buried Treasures system is PNG-ready. Every treasure picture (in-world reveal, reward toast, collection book,
silhouettes) is drawn from ONE table: `ReplicatedStorage.TreasureConfig` -> `TC.Images`. Until an id is filled in,
the game shows a colourful emoji placeholder; nothing else needs to change.

## Make
36 transparent PNGs, 1024x1024, file names and prompts in `manifest.json` / `prompts.txt`
(35 treasures: 7 biomes x Common/Rare/Epic/Legendary/Mythic, plus `treasure_MenuIcon.png` for the TREASURES button).

Style (same as the existing upgrade icons): one chunky glossy cartoon object, bright colours, soft shading, clean dark
outline, centred with ~8% padding, fully transparent background, NO text, no frame, no ground shadow. Keep the
silhouette clear: undiscovered items are shown as the same PNG tinted dark. Do not bake rarity glows into the art;
the game adds rarity colours, glow discs, rings and sparkles itself.

## Install
1. Upload the PNGs (Decal/Image) and note each asset id.
2. Fill `assetId` in manifest.json (optional record) and paste ids into `TC.Images` in Studio
   (template: `TreasureImageIds_template.lua`). Format: `FrostButton = "rbxassetid://123456789",`.
3. Play: reveal, toast and book switch to the PNGs automatically. MenuIcon replaces the 3D chest on the button/banner.
