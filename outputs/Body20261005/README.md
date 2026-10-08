# BODY: the fourth snowplow part (task 7, 2026-10-05, Claude)

Nothing was published. Backups: ServerStorage.BodyBackup_20261005 (Scripts_before with 13 scripts, and Chassis_before = the original chassis with its shell).

## What changed
- **Catalog: 135 → 150 parts.** 45 blades, 45 engines, 45 wheels/tracks and 15 bodies; every old id is kept.
  - The authoritative generator is still outputs/Rebalance20261005/sim: data/catalog_spec3.py (the 135 parts plus BODIES) → sim/catalog2.py → sim/final_variant.json → sim/gen_lua2.py. The 135-part variant is kept as final_variant_135.json.
- **Frame vs shell.**
  - `ReplicatedStorage.PlowParts.Chassis` is now the invariant frame: Root, seat cushion and back, steering wheel, and the Attach_Blade / Engine / Gear / Body attach points. Attach_Body is identity.
  - The old shell became the free starter body `BodyStarter` (Classic Plow Cab, unchanged look).
  - PlowAssembly mounts the body at the chassis root and falls back to the starter body when none is given.
- **Fit for every combination.** Every body keeps these zones clear:
  - the driver well;
  - the rear engine bay (|x| < 1.7, z 2.15–4.85, y ≥ 2.7);
  - the blade zone (nothing in front of z −4.3);
  - the wheels (|x| > 2.6 below y 1.9).

  Bodies are at most 7.6 tall. The check is vertex-level in Blender (check_zones.py): all clear except a single armour-rock vertex of Geode Crawler at the edge of the engine bay. Visual parts never collide.
- **15 bodies (Blender pack Bodies_A, asset 113098509806776).** Sources: bodies.py, build_bodies.py, blend/Bodies_A.blend, fbx/Bodies_A.fbx, upload_bodies.py. Preview sheet: renders/bodies_models.png.

  | Band | Body | Rarity | Price | Effect |
  |---|---|---|---|---|
  | 1 | Classic Plow Cab (starter) | Starter | free | – |
  | 1 | Frost Hauler | Common | 150 | +2% Snow, +11% stability |
  | 2 | Dune Runner | Common | 380 | +4% Snow, +3.6% steering |
  | 3 | Grave Hauler | Uncommon | 230K | +6% Snow, +2.9% grip |
  | 4 | Geode Crawler | Uncommon | 85M | +8% Snow, +14% stability |
  | 5 | Arcade Kart | Rare | 14B | +10% Snow, +4.5% steering |
  | 6 | Safari Cruiser | Rare | 180B | +12% Snow, +3.8% grip |
  | 7 | Polar Titan (premium) | Epic | 68T | +17% Snow, +5% grip, +25% stability |
  | 8 | Pagoda Wagon | Rare | 60T | +16% Snow, +5.4% steering |
  | 9 | Sweet Truck | Epic | 5.2Qa | +18% Snow, +4.7% grip |
  | 10 | Reef Diver | Epic | 32Qa | +20% Snow, +20% stability |
  | 11 | Toy Truck | Epic | 98Qa | +22% Snow, +6.3% steering |
  | 12 | Brass Carriage | Epic | 450Qa | +24% Snow, +5.6% grip |
  | 13 | Sky Cruiser | Epic | 4.2Qi | +26% Snow, +6.9% steering |
  | 14 | Star Cruiser (legendary) | Legendary | 92Qi | +31% Snow, +6% grip, +6% steering |

- **Effect (small, bounded, real).**
  - Snow is +% Snow from plow clearing, including job tiles. It is applied once in SnowFieldService before pets, boosts and combo, and the job reward estimate includes it too.
  - Grip and steering add to the gear's traction and turn; stability adds to stability. They are capped small, so drift tuning stays controllable.
  - C.Score includes the Snow efficiency, so useful-offer checks, pity and the card comparisons count a better body. Cards show the real effect ("+16% Snow per tile | +5% steering").
- **Offers.** The three pedestals stay offer slots. C.Offers.SlotShare normalises each roll to Blade / Engine / Gear 29.3% each and Body 12% (one body per band). The practical-part floor is unchanged.
- **Pacing kept.** Body Snow raises income, so every gate from Cursed onward rises by the bonus a player typically owns there (+2% at Cursed up to +24% at Cosmic). Stage eggs and World 2 upgrades follow their stage. Existing part prices follow their gate too (+2% to +24%). Saved offers and reserves never cost more than the price shown (C.OfferPrice).
- **Migration.** PlowRules already handles any slot list: an old three-slot save gets `body_starter` owned and equipped, and everything else is kept.
  - Kept: parts, build, offers with their stored prices, reserve, tutorial, rolls, bad-luck counter, Snow, upgrades and pets.
  - Unequipping a body goes back to the starter; rebirth keeps bodies.
  - The bay's public build is now "blade|engine|gear|body"; old three-field strings still parse and show the starter body.
- **UI.**
  - The Index has a BODIES tab and tabs fit any slot count.
  - "PARTS x/150" is counted from the catalog.
  - The workbench and the garage inspect panel list four slots, and the tutorial's parts tip mentions bodies.
  - Achievements: Parts135 is now "Own 135 different plow parts", and the new PartsAll "Own all N plow parts" uses the real catalog count (150).
- **Arena.** Bodies are cosmetic there: ArenaService never reads part stats; hull, footprint, speed and handling stay normalised.

## Simulation (40 seeds; outputs/Rebalance20261005/results)
16-seed check during tuning (World 1 median minutes for efficient / casual / no-rewards, then World 2):

| Variant | Efficient | Casual | No rewards | World 2 |
|---|---|---|---|---|
| Without bodies | 146 | 218 | 230 | 281 |
| First tuning (+4% Snow per band, cheap bodies) | 128 | 194 | 210 | 223 |
| **Final** (+2% per band, +3% premium, gates nudged) | **143** | **218** | **226** | **290** |

The first tuning was too fast, so the final variant keeps the pacing within a few percent of the version without bodies.

Full 40-seed run of the final 150-part game (results/eval_final150.json):
- World 1: efficient 141, casual 217, no rewards 224 min (the 135-part rebalance had 143 / 218 / 227).
- World 2: 297 min (was 282).
- Rebirth replay: 5.3 min.

## Tests (real Studio, Play with BalanceTestMode, removed afterwards; a temporary helper script existed only during Play)
- **Migration of a copied old three-slot profile through the real PlowRules, run twice.** The second run made 0 structural changes. body_starter was granted and equipped. Hex/Lantern/Bone build, Lantern ×2, both offers at their stored prices, the 40B reserve, tutorial done, rolls 41, dry 2, Snow, upgrades and pets were all kept.
- **Fresh profile:** Build.Body is body_starter.
- **Real handlers:**
  - Buying Frost Hauler at 150 and equipping it into Body works; putting a body into the Blade slot is refused.
  - Reserving Star Cruiser shows its price. Unequipping Body goes back to the starter and the body stays owned.
- **Bay and previews:**
  - The bay publishes "blade_basic|engine_starter|gear_wheels|body_frosthauler", and the bay preview shows the Frost Hauler shell.
  - An old three-field string on another bay previews with the starter body (the read-only neighbour path).
- **Rolls:** 22 real rolls gave 8 blades, 6 engines, 7 gears and 1 body (about 12% expected). The pool shares are 29/29/29/12% in bands 1, 5, 9 and 14.
- **Rebirth** through the real remote kept the owned body, the reserve and the equipped body.
- **Driving:** the plow carries the Frost Hauler shell, with stats SnowEff 1.02 and stability +0.11; the score is ×1.02.
- **Assembly:** 75/75 assemblies built with all four slots (60 random mixes, plus all 15 bodies on a late build).
- **GUI:** the Index BODIES tab shows 15 cards with real prices and "PARTS x/150". The tab order bug (alphabetical) is fixed in code but not re-captured.
- PartsAll reads "Own all 150 plow parts".
- No script errors.

## Not tested
- **Real DataStore persistence.** Test mode doesn't load or save real data, so a real save and reload of a body was not done.
- **A second real player** viewing a garage; the neighbour preview was checked through a local bay attribute.
- **How the bodies look in 3D in Studio** (the viewport wasn't rendering); see the Blender preview sheet.
- **A measured in-game Snow payout difference** with a body; it is verified through stats and code only.
