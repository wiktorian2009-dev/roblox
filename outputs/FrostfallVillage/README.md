# Frostfall Village

> Historical report for the first, additive version. The user subsequently approved replacing the original lobby, and that migration was installed. Read ../../STATUS.md for current coordinates, backups, interrupted-test cleanup and remaining checks. The Preview.jpg and BuildVillage.luau below describe the earlier layout.

Installed in the open Roblox Studio place `money` (place 94130990350526).

An additive winter lobby centered at (-440, 9, -282). The original lobby remains intact. Enter using the FROSTFALL gate at (-119, 1.5, -283), beside the original lobby path. MAIN LOBBY returns to the old lobby; ADVENTURE goes to the original starter snow field.

Features: upgrade workshop, pet lodge, shop, rebirth pavilion, interactive snow globe, lanterns and festival lights, starter snow yard, and six jumping pads ending at a lookout with a cosmetic snow celebration.

## Verification

- Original map: all 7,959 BaseParts retained; sum of original positions and sizes unchanged.
- Gate to village, return to main lobby, and original-field travel exercised with the normal E prompt.
- Upgrade, Pets, Shop, and Rebirth menus opened via their prompts and closed using existing buttons.
- Paths from arrival into all three hut interiors found successfully.
- Frost Hop completed using the starter character's normal 16 WalkSpeed and 7.2 JumpHeight.
- Snow yard built 135 tiles; a starter shovel changed 8 tiles and collected 19 snow during the isolated test.
- Globe and lookout celebrations emitted 26 temporary flakes, then cleaned up.
- Testing used the existing BalanceTestMode; it was removed before returning to Edit mode.
- Final cosmetic corrections: triangular gables, visible lantern glass, supported light garland, side windows and shop sign.

## Added instances

- Workspace.FrostfallVillage
- Workspace.FrostfallVillageGate
- Workspace.SnowFieldZones.FrostfallSnowYard
- ServerScriptService.FrostfallTravel
- StarterPlayer.StarterPlayerScripts.FrostfallClient
- StarterGui.RNGGui.VillageOpenMenu
- ServerStorage.FrostfallOriginals (script backups and original geometry metrics)

Existing RNGClient, PetClient, and UpgradeTreeClient received small menu-event hooks. Their original sources are in ServerStorage.FrostfallOriginals and ../Frostfall-lobby-backup.json. Patched sources are in ../Frostfall-menu-patches.json.

The build file reproduces the new geometry in a place without FrostfallVillage. It is not a full place file and intentionally refuses to overwrite an existing village. Current changes are in Studio; this work did not publish the place.
