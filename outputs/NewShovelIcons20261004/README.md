# New shovel icons — 2026-10-04

14 new shovel icons generated with the built-in image generation tool, using the actual Blender model renders as reference:
Wooden, Iron, Steel, Snowplow, Icicle, Candy Cane, Frost Fang, Viking, Steampunk, Platinum, Amethyst, Aurora, Plasma and Galaxy.

The icons use the same diagonal pose and a consistent chunky cartoony style. Their silhouettes, model palettes and accessories are preserved. Plasma shows the cyan core/lavender trim from its actual front face (the original render showed its back).
Final game copies are transparent 512 x 512 PNGs. Original generated files and original model-render references are retained separately.
Generation prompts and reference paths: prompts.json.

## Usage in the game
RNGConfig.Items[].ImageId is the shared image source for ItemIcon.create. The index, inventory, roll reel and rare-drop visuals use that renderer. Giant/Shiny variants inherit the base ImageId when RNGConfig builds them.
This change only replaces the fourteen new shovel icon bindings. Odds, rarities, power, sizes, rewards, the 3D models, other existing icons and GUI layouts retain their current definitions.

## Files and recovery
- icons/: selected game PNGs.
- originals/: original generated outputs.
- references/: Blender renders used for faithful shape/palette reference.
- assets.json: dimensions, alpha bounds and file sizes.
- uploaded-assets.json / icon-changes.json: Roblox IDs and before/after icon bindings.
- before-RNGConfig.luau: initial live source, before inspection/generation.
- final-RNGConfig.luau / source-hash.json: completed exact live source and canonical mirror hash.
- icon-test.client.luau / runtime-checks.json: production-renderer and mutation inheritance check.
- NewShovelIcons-PNGs.zip: artwork, prompts and asset metadata.

For recovery, inspect the current RNGConfig and restore just the ImageId values from icon-changes.json; do not overwrite later code or balancing with the entire older source. A live backup of the source immediately before applying the patch is retained in ServerStorage.
No publishing or player data reset is included.

## State
See installation-status.json for the final installed/tested state.

