# Three paid offers (game passes) — task 8, 2026-10-05, Claude

Nothing was published, no Robux were spent, and no pass is for sale.

## Setup state: passes NOT created yet
- My Open Cloud key can **read** this experience's passes (universe 10768102325 currently has none) but cannot create them. POST answered "403 Scope not authorized".
- I did not change key permissions. So, following your fallback:
  - `PassConfig.SalesEnabled = false`;
  - every `Id = nil` (no invented ids);
  - the cards show **COMING SOON** and never open a purchase prompt.
- Ready to use: create_passes.py can do the creation with sales OFF once a key has the `game-pass:write` scope. It's idempotent and writes passes.json with the real ids.

## Creator Dashboard steps (exact)
1. Open create.roblox.com → Creations → your experience **money** (place 94130990350526) → **Monetization → Passes** → **Create a Pass**.
2. Create three passes. Use these images from `outputs/Passes20261005/renders`; the descriptions are in create_passes.py.

   | Pass | Image | Description summary |
   |---|---|---|
   | 1.5x Snow | icon_snow15.png | x1.5 Snow forever from clearing and finished jobs (also treasures, chests, quest Snow); applied once |
   | Starter Pack | icon_starterpack.png | Full Haunted set: all 10 Cursed-theme parts, no Snow (changed 2026-10-06, see STATUS.md save point 53) |
   | Aurora Wheels | icon_aurorawheels.png | premium wheels: great grip and turning, strong early-to-mid pushing power |

3. Leave **Item for sale OFF** for now. Copy each pass ID from its URL or settings page.
4. In Studio, open `ReplicatedStorage.PassConfig`:
   - paste the IDs into `Id =` for SnowBoost, StarterPack and PremiumWheels;
   - set `SalesEnabled = true`;
   - press **Ctrl+S**, then **Publish**.
5. Back in the dashboard, turn **Item for sale** on for each pass. Default prices are **10 / 15 / 50 Robux**; set regional pricing if you like. The cards always show the real player price from `GetProductInfoAsync`.
6. Optional, after publishing: buy each pass once on a test account to confirm the grant.

## What is implemented
- **PassConfig** (ReplicatedStorage): pass registry with keys, names, ids, default prices, benefits, exact contents, icons and SalesEnabled.
- **PassService** (server). Never trusts the client:
  - checks ownership with `UserOwnsGamePassAsync` after the profile loads (4 attempts with backoff);
  - handles `PromptGamePassPurchaseFinished` and re-verifies ownership before granting;
  - no ProcessReceipt — these are passes.
  - Grants are idempotent and saved in `d.Passes`:
    - **1.5x Snow**: attribute `PassSnowMult = 1.5`, folded into `SnowMult` **once** in UpgradeService.
    - **Starter Pack**: the four parts, added only if missing and never auto-equipped, plus **3,000 Snow once per profile** (marker `StarterSnow`). That's about 2.5 minutes of unboosted starter collecting (the starter build measured 19–24 Snow/s).
    - **Aurora Wheels**: part `gear_aurorawheels` (Role "P").
- **Snow treatment** (×1.5 applied exactly once):
  - Gets ×1.5: plow clearing (including job tiles), finished jobs (the reward comes from the player's measured or estimated rate, which includes SnowMult, so jobs keep their 2× edge), treasures, World 2 chests and quest "Snow minutes".
  - Never multiplied: purchases, refunds or admin transfers (they use AddSnow directly, outside SnowMult).
  - Stacking is multiplicative with upgrades, pets, rebirth and timed boosts, with the pass counted once. Boosts still apply once at job payout.
- **Aurora Wheels** (Blender: paidgear.py, pack Gears_P asset 87199415786727).
  - Stats: grip 0.92, turn 1.15, pivot 0.7, stability 1.5, push ×1.75.
  - Measured: about 1% faster World 1, clearly faster early (arrives at Cursed about 2 min earlier, efficient model). From Crystal's premium gear (2.22) onward, free gear is better, so later gear stays worthwhile.
  - Paid parts: never offered; not counted in "PARTS x/150", the Index or the "own all parts" achievement; never the useful-offer baseline, so pity works as for free players.
  - Fits all 15 bodies; cosmetic in the arena (normalised hull and stats).
- **Starter Pack measured** (12 seeds): World 1 efficient 146 → 138 min, casual 218 → 208. Reaches Cursed at about 7 min instead of 12, then normal pacing (no biome skipping).
- **1.5x Snow measured**: World 1 efficient 146 → 105, casual 218 → 174.
- **HUD (PassClient).**
  - Three compact snowy cards to the left of REWARDS/SPIN, below the event banner and above DRIVE. Each has icon, name, benefit and the real price, or OWNED, "...", UNAVAILABLE or COMING SOON.
  - A click opens a details popup with the exact contents. BUY prompts only after that explicit click and only when it can really be bought.
  - Hidden on the arena island, in the intro and tutorial (SuppressEvents) and while a menu panel or the workbench is open.
  - Collapses into one "⭐ OFFERS" toggle on small screens.
  - No timers, discounts or auto-prompts.

## Tests (Studio, Play with BalanceTestMode, removed afterwards; ownership mocked through ServerStorage.PassTestHook, a temporary helper script existed only during Play)
- Free player: no attributes, SnowMult 1, cards show COMING SOON, BUY disabled.
- A cancelled purchase callback granted nothing.
- 3 mocked API failures were recovered by the retries, then the grant happened.
- 1.5x Snow:
  - SnowMult 1 → 1.5 exactly; repeated checks and callbacks did not stack (still 1.5).
  - The job rate went exactly ×1.5 (18.15 → 27.225); the reward 3,000 → 4,400 is ×1.47 only because of round-number display.
- Starter Pack:
  - Snow 0 → 3,000 on the first grant, and still 3,000 after a repeat callback and a rejoin check.
  - An already-owned Dune Sweeper was not duplicated; the other three parts were added.
  - A better equipped gear (Hover Pods) stayed equipped.
- Aurora Wheels: owned, not auto-equipped, not in the offer pool, assembles with every body (15/15).
- Rebirth: Snow reset, no Starter Snow re-grant, parts kept, SnowMult recomputed with the pass once.
- The GUI cards and details popup render (screenshots captured in this session).

## Not tested
- A real Robux purchase, a real ownership API answer and real regional prices: there are no pass ids yet and Robux spending isn't authorised.
- The small-screen collapse on a real phone (logic only).

## Verity Egg — developer product (added 2026-10-06, Claude)
This is a repeatable purchase, so it is a **Developer Product**, not a pass. The code is in place with **sales OFF** and **no id**; the shop card shows COMING SOON and the server refuses to prompt.

1. Open create.roblox.com, then Creations, then **money** (place 94130990350526), then **Monetization**, then **Developer Products**, then **Create a Developer Product**.
2. Fill it in:
   - Name **Verity Egg**;
   - price **49 Robux** (only this is ever charged);
   - icon: `outputs/VerityEgg20261006/renders/verity_egg_icon.png` (or any Verity pet tile from `outputs/PlowExpansion20261005/pets/renders/tiles/`);
   - description: "One exclusive OP pet: Verity 44%, Falsity 30%, Cruelty 18%, Lord Verity 7%, Rainbow Verity 1%."
   - Save, then copy the **product id**.
3. In Studio, open `ReplicatedStorage.PassConfig`:
   - paste the id into `Products.VerityEgg.Id = <id>`;
   - set `P.ProductSalesEnabled = true`;
   - press **Ctrl+S**, then **Publish**.
4. The card then shows the real price. The struck-through 69 and the -29% tag only show while the real price is 49. To switch the sale display off, set `ShowSale = false`.
5. Optional: buy one on a test account. You should see the hatch reveal and a new pet in the inventory, and the PurchaseId recorded in the profile's `Receipts`.
