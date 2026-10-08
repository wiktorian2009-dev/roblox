# Image-based snowy GUI art (2026-10-06, Claude)

wiktor: "things like equip best buttons etc should be maked by an ai image gen and not by script in roblox".

## What I could use
- **No image-generation AI is available on this PC.** No OpenAI / Stability / other image API key is configured. No local model (diffusers/torch) is installed. GIMP 3 is installed, but it doesn't generate images.
- The Studio MCP's generate_texture only re-textures 3D meshes, not UI images.
- **So, as briefed:** I built and rendered the art in **Blender** (`ui_art.py`) as transparent, 9-slice-friendly PNGs, in a chunky cartoon snowy style:
  - 7 colour buttons, 2 tabs, 2 windows (light / deep blue), a round close button and 13 icons (25 images in `png/`).
  - Each has a navy outline, a gradient body, a top gloss, a darker lip and a snow cap.
- Uploaded through Open Cloud as decals (`upload_art.py`); image ids resolved in Studio.
- **IMAGE_PROMPTS.md** has a prompt per piece, plus the sizes and slice rects, so an image AI can replace any of them later. Only the ids in `ReplicatedStorage.SnowArt` need changing.

## Wiring (visual only; scripts still own state and input)
- **New module `ReplicatedStorage.SnowArt`:** SkinButton (colour follows BackgroundColor3, so BUY stays green or grey), SkinPanel, SkinClose, Icon, IconButton. Slice margins scale with the widget size.
- **PlowShopClient:**
  - Every script button: the offer card's BUY / RESERVE / REROLL (with coin / star / reroll icons), the reserve-replace dialog, and the workbench's EQUIP / EQUIPPED / UNEQUIP.
  - The X buttons get the round close art.
  - The offer card and the workbench window get the deep-blue snowy window. The workbench title has a wrench icon.
- **PlowGarageClient:** the inspect panel and its close button.
- **ArenaHudClient:** every arena button (JOIN MATCH, LEAVE ARENA with the door icon, PAINT with the brush icon, intro OK).
- **Not touched:**
  - The upgrade screen (as asked).
  - The main HUD icon buttons, which are already image art.
  - The TRAVEL menu and the feature buttons, which already use Codex's generated art (FeatureUIArt).
  - The GARAGE button, which shows a live 3D preview of your own plow.

## Tests (real Play)
- All 25 images fetch successfully.
- **Real E presses at a bay:** rolled, then opened the offer card. The snowy window, cartoon BUY / RESERVE / REROLL and the round close button render (`screens/offer_card_v1.jpg`). The icons were then made larger.
- **Real E at the workbench:** the window, wrench icon and green EQUIPPED buttons render (`screens/workbench.jpg`).
- No script errors.

## Not tested
- The enlarged in-button icons (fixed after the first screenshot) and the arena buttons, on screen.
- Phone and gamepad.

## Undo
- ServerStorage.GuiArtBackup_20261006 holds the three clients.
- SnowArt is new; deleting it and restoring the clients undoes this.

## Pet screens (2026-10-06, later): `StarterPlayerScripts.SnowArtPetScreens` (new)
- **EQUIP BEST does not exist** anywhere in the game: no script or GUI has it. The pet inventory only has per-pet buttons.
- Skinned at runtime: the Studio-only PetClient / MachinesClient that build these buttons are **not edited**; the new script re-skins what they create.
  - **Inventory:** EQUIP (blue art), EQUIPPED (green art), and the red ✕ unequip badge (round SnowArt close).
  - **Pet Fuser (Golden), Crafting Machine, Hot Cocoa:** row buttons are green art when ready (FUSE! / CRAFT! / BUY) and grey otherwise, following the machine's own label text.
  - **Panel close X** of Inventory, Fuser, Craft, Cocoa and Shop → round SnowArt close.
- **Already image art (untouched):** the left-menu icons (INDEX, INVENTORY, SHOP, REBIRTH, TREASURES), the panel banner icons, and the upgrade screen.
- **Not present:** a Delete button (none in the game) and pet-screen tabs (the TabBar is hidden by PetClient; pets are the only tab).
- **Tests (Play, BalanceTestMode):**
  - Real clicks on ✕ (unequipped Cruelty) and EQUIP (equipped the 2nd Verity) worked; all 5 rebuilt buttons were re-skinned.
  - On a simulated unlocked Fuser with 3 Snow Bunnies, FUSE! was green and NEED 3 grey; a real FUSE! click made a Golden Snow Bunny.
  - No errors.
- **Not tested on screen:** the Craft and Cocoa rows (same code path), phone, gamepad.
- **Undo:** delete SnowArtPetScreens (nothing else changed).

## EQUIP BEST (2026-10-06, later)
- **Where:** a new green SnowArt button with a star icon at the top of the pet inventory (the band where PetClient's hidden tab bar sits), added by `SnowArtPetScreens`.
- **Server** (`PetService`, equip remote action `"best"`):
  - ranks every owned copy by `PetConfig.BoostOf`, the same value the income uses, so the progress-scaled Verity pets and Golden pets count correctly;
  - fills up to the player's slots, using owned copies only;
  - rate-limited to one call per 1.5 s;
  - returns `ok`, `same`, `wait` or `none`.
  - Pets have no locked or "in use" state: the Fuser only takes spare, unequipped copies at the moment it fuses.
- **No-op:** when the equipped set is already as strong as possible (by total boost, so equal-strength pets aren't swapped back and forth), it shows "Already your best!". With no pets: "Hatch some pets first!".
- **Tests (Play, real clicks):**
  - no pets → "Hatch some pets first!";
  - weaker set (2 Snow Bunny + Penguin) with a spare Yeti → Yeti, Penguin, Snow Bunny, "Equipped your best pets!";
  - again → "Already your best!" (unchanged);
  - from nothing equipped, with a Verity and a Golden Snow Bunny owned → Verity, Yeti, Golden Snow Bunny;
  - two quick server calls → the second one is "wait".
  - No errors.
- **Undo:** `ServerStorage.EquipBestBackup_20261006` holds the previous PetService and SnowArtPetScreens.

## Starter Pack card (2026-10-06, wiktor: "make better icon for starter pack" / "line it up over the rewards")
- **New icon:** Blender, `ui_art.py --starterpack`, decal 128222234165928 → image rbxassetid://108336337839177. It shows a gift box with a plow blade and a wheel on a snow pile, with a snowflake for the Snow. Its prompt is in IMAGE_PROMPTS.md; the old icon id is kept in a comment in PassConfig.
- **Placement** (PassClient, `PassConfig` StarterPack `Square = true`):
  - a square card the exact size of the REWARDS button, directly above it in the same column;
  - re-placed every frame from REWARDS' live position, so phone screens and safe areas follow;
  - a gold price/state pill on top;
  - the name underneath, like REWARDS.
  - 1.5x Snow and Aurora Wheels stay in their column to the left.
- **Measured in Play:** same x as REWARDS (−0.7 px), same 124 px size, a 16 px gap, no overlaps. A real click opened the details popup. The card hides with the rest of the offers (arena, intro, tutorial, open menus).
- Screenshot: `screens/starter_pack_card.jpg`.
- **Undo:** `ServerStorage.StarterPackCardBackup_20261006` (PassClient, PassConfig).
- **Not tested:** the phone emulator (I can't switch it on here); the placement follows REWARDS by design.
