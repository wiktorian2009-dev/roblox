# Verity Egg — exclusive paid egg (2026-10-06, Claude)

wiktor: "lets add some exclusive op egg for 49 robux in shop that is discounted from 69 and i have verity pet falsity pet cruelty pet lord verity pet RAINBOW VERITY that is 1%".

**Nothing was published, no Robux were spent, and no product id was invented.** Sales are **OFF** (COMING SOON) until the product exists. wiktor's steps are in `outputs/Passes20261005/README.md` → "Verity Egg".

## The pets (new: none existed in the place, backups or on disk)
- Five new cartoony pets, built with the same Blender kit as the 70 pets (`outputs/PlowExpansion20261005/pets/sp_15_verity.py`, `build_pets.py --eggs VerityEgg`):
  - **Verity**: a cream lion cub with a gold halo and a truth gem.
  - **Falsity**: a purple fox with a party mask pushed up on its head.
  - **Cruelty**: a grumpy-cute red dragon pup with horns, bat wings and one little fang.
  - **Lord Verity**: a crowned golden lion with a white mane and a red cape.
  - **Rainbow Verity**: a white winged lion with a rainbow mane and a glowing halo.
- Eye check passed, 1,962–2,304 tris, at most 12 parts each.
- Pack uploaded as asset 139949289988901 (`pets/uploads.json`, manifest now 75 pets). Imported into `ReplicatedStorage.PetModelOverrides` (Studio-only, also in `ServerStorage.PlowExpansionImports.BuiltPets`).
- Renders are in `renders/`.

## Odds and strength (PetConfig, one table for the roll and the display)
| Pet | Rarity | Chance | Boost |
|---|---|---|---|
| Verity | Epic | 44% | 1.3 × ref |
| Falsity | Epic | 30% | 1.6 × ref |
| Cruelty | Legendary | 18% | 2.0 × ref |
| Lord Verity | Legendary | 7% | 2.6 × ref |
| Rainbow Verity | Mythic (new rarity colour) | 1% | 4.0 × ref |

- **ref** is the best regular Legendary boost among the eggs this player has unlocked (`PetConfig.RefBoost`). So the pets are "OP at the same point of the game" anywhere:
  - start: +25% … +77%;
  - Crystal: +84% … +258%;
  - all worlds: +1222% … +3760%.
- Rainbow Verity (37.6 at the end) beats every pet in the game, including Golden Galaxy Dragon (18.8).
- Non-payers' pacing is unchanged. The economy caps (gates up to 660T) are untouched. Arena stats don't use pets.
- **No Golden variants:** the Pet Fuser skips these pets. Paid pets don't count towards pet achievements.
- Clients show the live per-player boost (inventory, hatch reveal, egg screen). The server uses `PetConfig.Multiplier(pets, player)` in all five income paths: clearing, jobs, treasures, World 2 activities and boss estimates.

## Purchase flow (server-side, Developer Product)
- **`ServerScriptService.ProductService`** (new) is the game's only `ProcessReceipt`. It returns NotProcessedYet when:
  - the product is unknown;
  - the player is not in the server;
  - the profile is not loaded;
  - the profile did not load from the DataStore. New `DataService.LoadedFromStore`: a profile that fell back to a blank one after a failed GetAsync never receives paid items.
- **Granting:**
  - the pet is rolled on the server from the egg's Chance table;
  - the PurchaseId is recorded in `d.Receipts`, and `PurchaseGranted` is returned only after `DataService.SaveNow` confirms the write;
  - if the save fails, the record stays "unsaved" and the retry only saves again, never rolling again;
  - a repeat PurchaseId returns Granted without a second pet;
  - history is capped at 300 records.
- **Prompting:** a purchase starts only from an explicit BUY click, through `ProductRemote "Prompt"`. The server checks that sales are on, a real id is set, the player isn't restricted and the profile is loaded, then calls `PromptProductPurchase`.
- **PolicyService:** `GetPolicyInfoForPlayerAsync` (3 tries), using `ArePaidRandomItemsRestricted` → attribute `PaidRandomRestricted`. If the answer is unknown, the player is treated as restricted. Restricted players:
  - don't see the egg (the shop shows its old placeholder);
  - are refused by the server even with sales on.
- **After purchase:** the normal PetClient hatch reveal plays (new Verity Egg look in EggModels: gold band and truth gem).

## Shop UI (`StarterPlayerScripts.VerityEggClient`, new; SnowArt)
- The SHOP panel was a placeholder ("Shop opening soon! New shovels…"). The client now fills `Shop.Inner` at runtime; the Studio panel itself isn't edited.
- **Card:**
  - an upright egg preview and EXCLUSIVE;
  - the price "R$ 69" struck through → "R$ 49", with a -29% pill;
  - **every outcome with its odds on the card**, before any purchase ("YOU GET ONE OF:", with pet thumbnails);
  - **DETAILS** and BUY (or COMING SOON).
- **Egg screen (DETAILS):** five pet tiles with 3D models, rarity, odds and current boost; the rules line ("1 pet per egg • never Golden • boosts grow…"); BUY and a round close.
- Prices and the tag come from `PassConfig.Products.VerityEgg` (Price 49, WasPrice 69, ShowSale). The real price comes from GetProductInfoAsync once an id exists, and the sale display only shows while the real price is 49.

## Tests (Play, BalanceTestMode; receipts and policy through `ServerStorage.ProductTestHook`)
- **Receipts:**
  - first receipt → PurchaseGranted, one pet (Cruelty);
  - the same PurchaseId again → Granted, still one pet;
  - forced save failure → NotProcessedYet, record unsaved; the retry → Granted with the same single pet (no re-roll);
  - unknown product → NotProcessedYet.
- **Real PolicyService call in Studio:** not restricted.
- **Simulated restriction:**
  - the card is hidden, the placeholder shows, the egg screen closes;
  - with sales switched on in Play memory with a fake id, the Prompt was refused as "restricted";
  - an unknown key → "unknown";
  - with sales off → "soon".
- **Simulated 200,000 rolls:** 44.14 / 30.10 / 17.76 / 6.98 / 1.02% (config 44/30/18/7/1, sum 100). No Golden Verity pets exist.
- **Real clicks:** the SHOP button opened the card (`screens/shop_card.jpg`), DETAILS opened the egg screen (`screens/egg_screen.jpg`), and close buttons work. A receipt played the hatch reveal "Verity, Epic +25%" (`screens/hatch_reveal.jpg`). No script errors.
- **Fixed during testing:**
  - the egg preview lay on its side (pivot now on the shell);
  - the odds-row thumbnails were too thin;
  - the egg screen was behind the SHOP panel (DisplayOrder 103).

## Not tested
- A real purchase and a real `ArePaidRandomItemsRestricted = true` account (no product id, no Robux).
- Phone and gamepad layout (scale-based, not seen).
- Two players.

## Paid random items: findings for wiktor (nothing changed)
- **The 14 Snow eggs** already show every pet's odds as a percentage on their world signs, before hatching. Those odds are read from the same PetConfig table the server rolls from, and every egg sums to 100. Undiscovered pets show as silhouettes, but their % is still shown.
- **The Starter Pack pass grants 3,000 Snow for Robux.** That Snow can be spent on the Snow eggs (random), so under Roblox's rules the Snow eggs may count as paid random items. They are **not** PolicyService-gated today. I left the Starter Pack and the Snow eggs as they are; that's wiktor's call. Options:
  - stop granting Snow in the pack;
  - gate the Snow eggs for restricted players;
  - accept the risk.
- **Pre-existing DataService risk** (not changed beyond the receipt guard): if `GetAsync` fails, `load()` starts a blank profile, and autosave can then overwrite the real one. Paid grants now refuse such profiles. The general case should get a proper fix (kick or retry instead of a blank profile).

## Undo
- `ServerStorage.VerityEggBackup_20261006` holds the 11 previous scripts: PetConfig, PassConfig, EggModels, DataService, PetService, ActivityService, ContractService, FrostKingService, SnowFieldService, TreasureService, World2Activities.
- Delete ProductService, VerityEggClient and the 5 Verity models in PetModelOverrides.
