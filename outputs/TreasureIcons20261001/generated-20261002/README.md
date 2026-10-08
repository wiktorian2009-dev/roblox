# Treasure icons — generated 2026-10-02

This pack contains the 35 Buried Treasures icons and the Treasures menu chest, generated individually with the built-in image_gen tool. Subjects and IDs follow Claude's original manifest in the parent folder.

Art: glossy cartoon objects with dark outlines, colorful highlights, transparent backgrounds, and distinct silhouettes. Rarity glows stay in the existing runtime effects. Original generated PNGs are preserved without resizing, cropping, or alpha replacement. The prompt asks for 1024-square images; qa.json records the actual delivered dimensions.

Files:
- 36 treasure_*.png originals, named by TreasureConfig ID.
- generation-manifest.json: exact prompts, names, biomes, rarities, source paths and Roblox image IDs.
- asset-map.json: TreasureConfig ID to uploaded Roblox image ID.
- preview-grid.png: a labeled contact sheet for review.
- qa.json: dimensions, alpha checks, visible bounds and file sizes.
- TreasureConfig.before.luau / TreasureConfig.after.luau: recovery and installed-source records.
- verification.json: Studio verification results.
- TreasureIcons.zip: PNGs, preview, prompts, mapping and documentation.

Installed in live Studio: all 36 uploaded image IDs are assigned in ReplicatedStorage.TreasureConfig.TC.Images. All 35 collection pictures across seven tabs and the menu chest loaded in an isolated Play check; natural digging used the new artwork. Before/after configuration copies and verification.json record the checks. Recovery also exists at ServerStorage.TreasureConfig_BeforePNGIcons20261002. The place was not saved or published.

Only TC.Images changed. Collection IDs, probabilities, Snow bonuses, save data, rarity effects and game UI layout remain as before. The other treasure source modules are still Studio-only; this task synchronized TreasureConfig only.

