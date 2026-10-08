# Source-derived layout check

Regenerate: `cd outputs/UIAudit20261008/layout && node check_layout.js --section after --md layout_report_after.md` (exit status 1 = counted overlaps in the AFTER section). Single scenario: `--dump driving@844x390`.

**What this is:** pixel rectangles computed from numbers read out of the Luau sources (see `layout_model.json`, every element cites file:line). **What it is not:** a render of Roblox. It was not run in Studio, it cannot see static Studio frames (listed as unknown and excluded) and a clean result does not prove that input works.

Assumptions: GuiInset 36 px on desktop viewports, 58 px on phone viewports; phones are TouchEnabled without keyboard; ArenaHud treated as inset-respecting (CoreUISafeInsets); MiniPlowGui treated as IgnoreGuiInset=true (copied from the unknown RNGGui); device notch insets 0; Roblox default jump button rect is an assumption (probe only). Overlap tolerance 4 px on both axes.

## AFTER - AFTER = working tree of game/src + PENDING Studio patch copies under outputs/UIAudit20261008/studio-patches

Counted overlaps (scenario x viewport x pair, tolerance > 4 px on both axes): **32** in **16** distinct element pairs.
Partly off-screen: **1** element/viewport combinations (3 scenario rows). Touch targets below the minimum: **3** element/viewport combinations (3 scenario rows), plus 20 accepted at the dense 40 px allowance.
Known elements checked: 59; unknown (excluded): 10; assumed probes (never counted): 2.

### Overlap count per scenario and viewport

| scenario | 1920x1080 | 1366x768 | 1280x720 | 844x390 | 667x375 | 932x430 | 390x844 | total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| lobby_idle | . | . | . | . | . | . | . | . |
| lobby_offers_open | . | . | . | . | . | . | 1 | 1 |
| lobby_contract_pill | . | . | . | . | . | . | . | . |
| contract_announcement | . | . | . | . | . | . | . | . |
| garage_offer_card | . | . | . | . | . | . | 2 | 2 |
| garage_equip_window | . | . | . | . | . | . | . | . |
| garage_inspect | . | . | . | . | . | . | . | . |
| driving | . | . | . | . | . | . | . | . |
| driving_offers_open | . | . | . | . | . | . | . | . |
| driving_contract_tracker | . | . | . | . | . | . | . | . |
| driving_treasure_toast | . | . | . | 1 | 1 | 1 | 1 | 4 |
| tutorial_step_help_open | . | . | . | 1 | 1 | . | . | 2 |
| tutorial_card_low_help_open | . | . | . | 1 | 1 | 1 | . | 3 |
| help_menu_open | . | . | . | . | . | . | . | . |
| travel_menu_open | . | . | . | . | . | . | . | . |
| offer_details_open | . | . | . | 1 | 1 | 1 | 4 | 7 |
| offers_mini_plows_open | . | . | . | . | 1 | . | . | 1 |
| offers_inspect_open | . | . | . | . | 1 | . | . | 1 |
| offers_egg_screen_open | . | . | . | . | 1 | . | 2 | 3 |
| boss_pill_contract_tracker | . | . | . | . | . | . | . | . |
| boss_fight | . | . | . | . | . | . | . | . |
| upgrades_open | 1 | 1 | 1 | . | . | . | 1 | 4 |
| arena_prejoin | . | . | . | 1 | 1 | . | . | 2 |
| arena_match | . | . | . | 1 | 1 | . | . | 2 |
| boss_fight_contract_tracker | . | . | . | . | . | . | . | . |

### Overlaps (counted)

| scenario | viewport | element A (gui, DO) | element B (gui, DO) | overlap px | A rect (x,y w x h) | B rect | notes |
|---|---|---|---|---|---|---|---|
| upgrades_open | 1920x1080 | UPGRADES legend (UpgradeTreeGui, 150) | UPGRADES hover tooltip (desktop only) (UpgradeTreeGui, 150) | 18x43.2 | 18,1020.8 614.4x43.2 | 614.4,983 691.2x81 | same DisplayOrder |
| upgrades_open | 1366x768 | UPGRADES legend (UpgradeTreeGui, 150) | UPGRADES hover tooltip (desktop only) (UpgradeTreeGui, 150) | 18x30.7 | 18,721.3 437.1x30.7 | 437.1,694.4 491.8x57.6 | same DisplayOrder |
| upgrades_open | 1280x720 | UPGRADES legend (UpgradeTreeGui, 150) | UPGRADES hover tooltip (desktop only) (UpgradeTreeGui, 150) | 18x28.8 | 18,675.2 409.6x28.8 | 409.6,650 460.8x54 | same DisplayOrder |
| driving_treasure_toast | 844x390 | Dig combo meter (DigJuice, 55) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 100.6x24.2 | 366.4,235.6 111.2x24.2 | 377,192 300x84 | same DisplayOrder |
| tutorial_step_help_open | 844x390 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 29.1x28.8 | 211,9.8 422x150 | 10.1,131 230x150 | same DisplayOrder |
| tutorial_card_low_help_open | 844x390 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 29.1x105.5 | 211,175.5 422x150 | 10.1,131 230x150 | same DisplayOrder |
| offer_details_open | 844x390 | OFFERS toggle (small screens) (PassOffersGui, 11) | OfferDetails popup (PassOffersGui, 11) | 120x36.5 | 116,334 120x40 | 110,19.5 574x351 | same DisplayOrder; children also hit: OfferDetails BUY |
| arena_prejoin | 844x390 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 150x13.8 | 681.3,124.4 150x120 | 662.5,230.6 168.8x46.5 | same DisplayOrder |
| arena_match | 844x390 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 150x13.8 | 681.3,124.4 150x120 | 662.5,230.6 168.8x46.5 | same DisplayOrder |
| driving_treasure_toast | 667x375 | Dig combo meter (DigJuice, 55) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 107x23.3 | 280,226.5 107x23.3 | 213,183 300x84 | same DisplayOrder |
| tutorial_step_help_open | 667x375 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 71.3x43.4 | 166.8,9.4 333.5x150 | 8,116 230x150 | same DisplayOrder |
| tutorial_card_low_help_open | 667x375 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 71.3x97.3 | 166.8,168.8 333.5x150 | 8,116 230x150 | same DisplayOrder |
| offer_details_open | 667x375 | OFFERS toggle (small screens) (PassOffersGui, 11) | OfferDetails popup (PassOffersGui, 11) | 120x37.3 | 114,319 120x40 | 108,18.8 412x337.5 | same DisplayOrder; children also hit: OfferDetails BUY |
| offers_mini_plows_open | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | MINI PLOWS panel (MiniPlowGui, 6) | 9x44 | 529,233 130x44 | 129,45.5 409.1x284.1 | A draws above B |
| offers_inspect_open | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | Garage Inspect panel (neighbour build) (GarageInspectGui, 102) | 17.9x44 | 529,233 130x44 | 120.1,16.7 426.9x341.5 | B draws above A |
| offers_egg_screen_open | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 11.3x44 | 529,233 130x44 | 126.7,63.8 413.5x262.5 | B draws above A |
| arena_prejoin | 667x375 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 133.4x18.6 | 507,121.4 150x120 | 523.6,222.8 133.4x44.4 | same DisplayOrder |
| arena_match | 667x375 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 133.4x18.6 | 507,121.4 150x120 | 523.6,222.8 133.4x44.4 | same DisplayOrder |
| driving_treasure_toast | 932x430 | Dig combo meter (DigJuice, 55) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 77.3x26.7 | 404.7,259.7 122.6x26.7 | 450,216 300x84 | same DisplayOrder |
| tutorial_card_low_help_open | 932x430 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 8.2x127.5 | 233,193.5 466x150 | 11.2,171 230x150 | same DisplayOrder |
| offer_details_open | 932x430 | OFFERS toggle (small screens) (PassOffersGui, 11) | OfferDetails popup (PassOffersGui, 11) | 120x34.5 | 117,374 120x40 | 111,21.5 646x387 | same DisplayOrder; children also hit: OfferDetails BUY |
| lobby_offers_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 28x41 | 110,582.6 170x160.4 | 252,702 130x44 | B draws above A; children also hit: Offer card 2 |
| garage_offer_card | 390x844 | HELP pill (PlowTutorial, 200) | Garage OfferCard (PlowShopGui, 101) | 14.8x40 | 4.7,704 92x40 | 81.9,571.1 226.2x188.5 | A draws above B; children also hit: OfferCard BUY |
| garage_offer_card | 390x844 | TRAVEL button (TravelGui, 12) | Garage OfferCard (PlowShopGui, 101) | 14.1x8.6 | 4,751 92x40 | 81.9,571.1 226.2x188.5 | B draws above A |
| driving_treasure_toast | 390x844 | Dig combo meter (DigJuice, 55) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 66.3x9.6 | 161.9,528.7 66.3x14.4 | 8,474.5 228x63.8 | same DisplayOrder |
| offer_details_open | 390x844 | HELP pill (PlowTutorial, 200) | OfferDetails popup (PassOffersGui, 11) | 14.7x40 | 4.7,704 92x40 | 82,42.2 300x759.6 | A draws above B |
| offer_details_open | 390x844 | TRAVEL button (TravelGui, 12) | OfferDetails popup (PassOffersGui, 11) | 14x40 | 4,751 92x40 | 82,42.2 300x759.6 | A draws above B |
| offer_details_open | 390x844 | OFFERS toggle (small screens) (PassOffersGui, 11) | OfferDetails popup (PassOffersGui, 11) | 120x40 | 110,751 120x40 | 82,42.2 300x759.6 | same DisplayOrder; children also hit: OfferDetails BUY |
| offer_details_open | 390x844 | OfferDetails popup (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 130x44 | 82,42.2 300x759.6 | 252,702 130x44 | B draws above A; children also hit: OfferDetails BUY, OfferDetails CLOSE |
| offers_egg_screen_open | 390x844 | HELP pill (PlowTutorial, 200) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 66.7x30.3 | 4.7,704 92x40 | 30,143.5 330x590.8 | A draws above B |
| offers_egg_screen_open | 390x844 | DRIVE / EXIT button (PlowDriveGui, 51) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 108x32.3 | 252,702 130x44 | 30,143.5 330x590.8 | B draws above A |
| upgrades_open | 390x844 | UPGRADES title (UpgradeTreeGui, 150) | UPGRADES progress pill (UpgradeTreeGui, 150) | 21x22.6 | 117,21.1 156x67.5 | 18,66 120x42.2 | same DisplayOrder |

### Distinct overlapping pairs (which viewports, how many scenarios)

| pair | scenarios x viewports | viewports |
|---|---:|---|
| UPGRADES legend / UPGRADES hover tooltip (desktop only) | 3 | 1920x1080, 1366x768, 1280x720 |
| Dig combo meter / Treasure reward toast (Studio-only script) | 4 | 844x390, 667x375, 932x430, 390x844 |
| Tutorial instruction Card / HELP menu | 5 | 844x390, 667x375, 932x430 |
| OFFERS toggle (small screens) / OfferDetails popup | 4 | 844x390, 667x375, 932x430, 390x844 |
| Arena standings / Arena feed | 4 | 844x390, 667x375 |
| DRIVE / EXIT button / MINI PLOWS panel | 1 | 667x375 |
| DRIVE / EXIT button / Garage Inspect panel (neighbour build) | 1 | 667x375 |
| DRIVE / EXIT button / Verity EggScreen (DETAILS) | 2 | 667x375, 390x844 |
| Offers column (1.5x Snow, Aurora Wheels cards) / DRIVE / EXIT button | 1 | 390x844 |
| HELP pill / Garage OfferCard | 1 | 390x844 |
| TRAVEL button / Garage OfferCard | 1 | 390x844 |
| HELP pill / OfferDetails popup | 1 | 390x844 |
| TRAVEL button / OfferDetails popup | 1 | 390x844 |
| OfferDetails popup / DRIVE / EXIT button | 1 | 390x844 |
| HELP pill / Verity EggScreen (DETAILS) | 1 | 390x844 |
| UPGRADES title / UPGRADES progress pill | 1 | 390x844 |

### Partly off-screen (known elements)

| scenario | viewport | element | rect | outside by |
|---|---|---|---|---|
| driving_contract_tracker | 390x844 | Contract job tracker | -16,184 260x230 | left 16 |
| boss_pill_contract_tracker | 390x844 | Contract job tracker | -16,227 260x230 | left 16 |
| boss_fight_contract_tracker | 390x844 | Contract job tracker | -16,218 260x230 | left 16 |

### Touch targets smaller than 44x44 (touch viewports only)

| element | viewport | size w x h | level | scenarios |
|---|---|---|---|---:|
| HELP pill | 844x390 | 92x40 | dense-40-accepted | 22 |
| TRAVEL button | 844x390 | 92x40 | dense-40-accepted | 22 |
| OFFERS toggle (small screens) | 844x390 | 120x40 | dense-40-accepted | 9 |
| Card button ? HELP | 844x390 | 84x40 | dense-40-accepted | 2 |
| Card button SKIP | 844x390 | 84x40 | dense-40-accepted | 2 |
| MINI PLOWS X | 844x390 | 42.5x41.4 | BELOW | 1 |
| HELP pill | 667x375 | 92x40 | dense-40-accepted | 22 |
| TRAVEL button | 667x375 | 92x40 | dense-40-accepted | 22 |
| OFFERS toggle (small screens) | 667x375 | 120x40 | dense-40-accepted | 9 |
| Card button ? HELP | 667x375 | 84x40 | dense-40-accepted | 2 |
| Card button SKIP | 667x375 | 84x40 | dense-40-accepted | 2 |
| MINI PLOWS X | 667x375 | 40.9x39.8 | BELOW | 1 |
| HELP pill | 932x430 | 92x40 | dense-40-accepted | 22 |
| TRAVEL button | 932x430 | 92x40 | dense-40-accepted | 22 |
| OFFERS toggle (small screens) | 932x430 | 120x40 | dense-40-accepted | 9 |
| Card button ? HELP | 932x430 | 84x40 | dense-40-accepted | 2 |
| Card button SKIP | 932x430 | 84x40 | dense-40-accepted | 2 |
| HELP pill | 390x844 | 92x40 | dense-40-accepted | 22 |
| TRAVEL button | 390x844 | 92x40 | dense-40-accepted | 22 |
| OFFERS toggle (small screens) | 390x844 | 120x40 | dense-40-accepted | 9 |
| Card button ? HELP | 390x844 | 84x40 | dense-40-accepted | 2 |
| Card button SKIP | 390x844 | 84x40 | dense-40-accepted | 2 |
| MINI PLOWS X | 390x844 | 33.4x32.5 | BELOW | 1 |

### Top-level elements that start inside the Roblox top-bar zone (information only, not counted; the top-bar buttons are core UI at the screen edges, the centre is usually free)

| element | viewport: top y |
|---|---|
| Tutorial instruction Card | 1920x1080: 27 (inset 36); 1366x768: 19.2 (inset 36); 1280x720: 18 (inset 36); 844x390: 9.8 (inset 58); 667x375: 9.4 (inset 58); 932x430: 10.8 (inset 58); 390x844: 21.1 (inset 58) |
| Frost King boss bar | 1920x1080: 17.3 (inset 36); 1366x768: 12.3 (inset 36); 1280x720: 11.5 (inset 36); 844x390: 6.2 (inset 58); 667x375: 6 (inset 58); 932x430: 6.9 (inset 58); 390x844: 13.5 (inset 58) |
| UPGRADES title | 1920x1080: 27 (inset 36); 1366x768: 19.2 (inset 36); 1280x720: 18 (inset 36); 844x390: 9.8 (inset 58); 667x375: 9.4 (inset 58); 932x430: 10.8 (inset 58); 390x844: 21.1 (inset 58) |
| UPGRADES close X | 1920x1080: 27 (inset 36); 1366x768: 19.2 (inset 36); 1280x720: 18 (inset 36); 844x390: 9.8 (inset 58); 667x375: 9.4 (inset 58); 932x430: 10.8 (inset 58); 390x844: 21.1 (inset 58) |
| Garage OfferCard | 844x390: 15.6 (inset 58); 667x375: 15.1 (inset 58); 932x430: 17.2 (inset 58) |
| Garage equip window (GarageWindow) | 844x390: 31.2 (inset 58); 667x375: 30 (inset 58); 932x430: 34.4 (inset 58) |
| Garage Inspect panel (neighbour build) | 844x390: 15.6 (inset 58); 667x375: 16.7 (inset 58); 932x430: 17.2 (inset 58) |
| OfferDetails popup | 844x390: 19.5 (inset 58); 667x375: 18.8 (inset 58); 932x430: 21.5 (inset 58); 390x844: 42.2 (inset 58) |
| MINI PLOWS panel | 844x390: 47.3 (inset 58); 667x375: 45.5 (inset 58); 932x430: 52.5 (inset 58) |

### Probe overlaps against ASSUMED rects (jump button default, UPGRADES strip fallback band) - NOT counted

| probe | element | viewport | overlap px | probe rect | element rect | scenarios |
|---|---|---|---|---|---|---:|
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 1366x768 | 332x15.2 | 517,676 332x92 | 434.2,276.5 497.7x414.7 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 1280x720 | 332x20 | 474,628 332x92 | 406.7,259.2 466.6x388.8 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Offers column (1.5x Snow, Aurora Wheels cards) | 844x390 | 30x28 | 256,298 332x92 | 116,216 170x110 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Offer card 2 | 844x390 | 30x28 | 256,298 332x92 | 116,274.3 170x51.7 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 844x390 | 332x53 | 256,298 332x92 | 220.8,15.6 402.5x335.4 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage equip window (GarageWindow) | 844x390 | 332x37.4 | 256,298 332x92 | 178.6,31.2 486.7x304.2 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage Inspect panel (neighbour build) | 844x390 | 332x76.4 | 256,298 332x92 | 197.8,15.6 448.5x358.8 | 2 |
| UPGRADES strip fallback band (ASSUMED) | Tutorial instruction Card | 844x390 | 332x27.5 | 256,298 332x92 | 211,175.5 422x150 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Card button OK! (okButton steps only) | 844x390 | 110x21.5 | 256,298 332x92 | 367,275.5 110x44 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails popup | 844x390 | 332x72.5 | 256,298 332x92 | 110,19.5 574x351 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails BUY | 844x390 | 204.1x45.6 | 256,298 332x92 | 173.1,307.3 287x45.6 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails CLOSE | 844x390 | 116.4x45.6 | 256,298 332x92 | 471.6,307.3 172.2x45.6 | 1 |
| UPGRADES strip fallback band (ASSUMED) | MINI PLOWS panel | 844x390 | 332x44.7 | 256,298 332x92 | 209.3,47.3 425.5x295.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Verity EggScreen (DETAILS) | 844x390 | 332x41.3 | 256,298 332x92 | 160.4,66.3 523.3x273 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OFFERS toggle (small screens) | 667x375 | 66.5x40 | 167.5,283 332x92 | 114,319 120x40 | 9 |
| UPGRADES strip fallback band (ASSUMED) | Offers column (1.5x Snow, Aurora Wheels cards) | 667x375 | 116.5x28 | 167.5,283 332x92 | 114,201 170x110 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Offer card 2 | 667x375 | 116.5x28 | 167.5,283 332x92 | 114,259.3 170x51.7 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 667x375 | 332x54.5 | 167.5,283 332x92 | 140.1,15.1 386.9x322.4 | 1 |
| Roblox touch jump button (ASSUMED default rect) | Garage equip window (GarageWindow) | 667x375 | 15.5x37.5 | 552,285 70x70 | 99.5,30 468x292.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage equip window (GarageWindow) | 667x375 | 332x39.5 | 167.5,283 332x92 | 99.5,30 468x292.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage Inspect panel (neighbour build) | 667x375 | 332x75.3 | 167.5,283 332x92 | 120.1,16.7 426.9x341.5 | 2 |
| UPGRADES strip fallback band (ASSUMED) | Tutorial instruction Card | 667x375 | 332x35.8 | 167.5,283 332x92 | 166.8,168.8 333.5x150 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Card button OK! (okButton steps only) | 667x375 | 110x29.8 | 167.5,283 332x92 | 278.5,268.8 110x44 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails popup | 667x375 | 332x73.3 | 167.5,283 332x92 | 108,18.8 412x337.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails BUY | 667x375 | 191.8x44 | 167.5,283 332x92 | 153.3,295.4 206x44 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails CLOSE | 667x375 | 123.6x44 | 167.5,283 332x92 | 367.6,295.4 123.6x44 | 1 |
| UPGRADES strip fallback band (ASSUMED) | MINI PLOWS panel | 667x375 | 332x46.5 | 167.5,283 332x92 | 129,45.5 409.1x284.1 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Verity EggScreen (DETAILS) | 667x375 | 332x43.3 | 167.5,283 332x92 | 126.7,63.8 413.5x262.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 932x430 | 332x49 | 300,338 332x92 | 244.1,17.2 443.8x369.8 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage equip window (GarageWindow) | 932x430 | 332x31.8 | 300,338 332x92 | 197.7,34.4 536.6x335.4 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage Inspect panel (neighbour build) | 932x430 | 332x74.8 | 300,338 332x92 | 218.8,17.2 494.5x395.6 | 2 |
| UPGRADES strip fallback band (ASSUMED) | Tutorial instruction Card | 932x430 | 332x5.5 | 300,338 332x92 | 233,193.5 466x150 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails popup | 932x430 | 332x70.5 | 300,338 332x92 | 111,21.5 646x387 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails BUY | 932x430 | 205.1x50.3 | 300,338 332x92 | 182.1,338.8 323x50.3 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails CLOSE | 932x430 | 114x50.3 | 300,338 332x92 | 518,338.8 193.8x50.3 | 1 |
| UPGRADES strip fallback band (ASSUMED) | MINI PLOWS panel | 932x430 | 332x39.5 | 300,338 332x92 | 232,52.5 468x325 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Verity EggScreen (DETAILS) | 932x430 | 332x36.1 | 300,338 332x92 | 177.1,73.1 577.8x301 | 1 |
| UPGRADES strip fallback band (ASSUMED) | TRAVEL button | 390x844 | 67x39 | 29,752 332x92 | 4,751 92x40 | 22 |
| UPGRADES strip fallback band (ASSUMED) | OFFERS toggle (small screens) | 390x844 | 120x39 | 29,752 332x92 | 110,751 120x40 | 9 |
| Roblox touch jump button (ASSUMED default rect) | Garage OfferCard | 390x844 | 33.1x5.6 | 275,754 70x70 | 81.9,571.1 226.2x188.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 390x844 | 226.2x7.6 | 29,752 332x92 | 81.9,571.1 226.2x188.5 | 1 |
| Roblox touch jump button (ASSUMED default rect) | OfferDetails popup | 390x844 | 70x47.8 | 275,754 70x70 | 82,42.2 300x759.6 | 1 |
| Roblox touch jump button (ASSUMED default rect) | OfferDetails CLOSE | 390x844 | 70x9.8 | 275,754 70x70 | 271,665.1 90x98.7 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails popup | 390x844 | 279x49.8 | 29,752 332x92 | 82,42.2 300x759.6 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails BUY | 390x844 | 150x11.8 | 29,752 332x92 | 115,665.1 150x98.7 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails CLOSE | 390x844 | 90x11.8 | 29,752 332x92 | 271,665.1 90x98.7 | 1 |
| Roblox touch jump button (ASSUMED default rect) | JOIN MATCH button | 390x844 | 20x11.4 | 275,754 70x70 | 95,694.7 200x70.7 | 1 |

### Unknown elements (static Studio frames or non-static rects) - listed, EXCLUDED from every result above

| element | why unknown |
|---|---|
| UPGRADES button (BottomBar) | static Studio frame; MINIS/AFK/DriftMeter/tutorial arrows read its live AbsolutePosition |
| MINIS button | MiniPlowClient places it from the live UPGRADES rect (left of UPGRADES); UPGRADES rect unknown |
| AFK button + caption/toast | AfkDriftClient places it from the live UPGRADES rect (right of UPGRADES); UPGRADES rect unknown |
| REWARDS button + Starter Pack square | static Studio frame; PassClient sizes the Starter Pack square from it |
| LeftMenu (incl. GARAGE/LOBBY button, TREASURES, PETS) | static Studio frame |
| SnowCounter / StatIcons / SettingsCorner | static Studio frames (only SettingsCorner touch AnchorPoint (1,0) Position (1,-14,0,14) is in RNGClient.client.luau:70-73; its size is not) |
| ActivityHUD (event banner + boost pills) | snapshot ActivityClient: AnchorPoint (1,0), Position (1,-12,0.14,0), Size (0.25,0.3) of RNGGui, but occupancy depends on active events and RNGGui's inset is unknown; the contract slot reads its visible children live |
| Travel panel (RNGGui.Panels.Travel) | clone of the static Settings panel; rect not in the repo |
| Roblox thumbstick / TouchGui | Roblox core gui, not in the repo |
| Tutorial spotlight / pointer layer | recomputed every frame from the live target rect; not a static layout |

## Limitations

1. Source-derived only: nothing here was run in Studio, no screenshot was taken, no input was tested.
2. Static Studio frames (UPGRADES / MINIS / AFK strip, REWARDS + Starter Pack square, LeftMenu / GARAGE, SnowCounter, SettingsCorner, Travel panel, ActivityHUD) are not in the repo. They are listed as unknown and excluded, so overlaps with them are NOT detected. MINIS and AFK sit on the UPGRADES strip, so they are unknown too.
3. The top-bar inset (36 px desktop / 58 px phone) and phone safe-area insets (assumed 0) are assumptions; Roblox reports different values per device and app version. Re-run with --inset-desktop / --inset-phone to see the sensitivity.
4. ArenaHud sets both IgnoreGuiInset=true and ScreenInsets=CoreUISafeInsets; which wins at runtime is not verified. MiniPlowGui / AfkDriftGui copy the unknown RNGGui.IgnoreGuiInset (assumed true). Use --gui-inset NAME=true|false to test the other reading.
5. The Roblox default jump button rect (size 70 / 120 px) comes from memory; only its left/top fallback is in the repo (UILayout.jumpLeftTop). It is a probe and never counted. The real TouchGui JumpButton is read live by the fixed code and may differ.
6. Dynamic anchoring is modelled for HELP, TRAVEL, the offer column / toggle, the PopupStack column (HELP REQUEST popup only), the touch action column, the contract slot, the Frost King pill / Me card, and the arena touch controls. Popups stacked together, the tutorial spotlight / pointer layer, toasts, billboards and per-frame text are not modelled.
7. The contract slot ignores the ActivityHUD boost pills (their rect is unknown) and uses the fallback strip top (H-92) instead of the live UPGRADES top.
8. UIScale pop-in tweens are assumed finished (scale 1). Text size / clipping is not evaluated, only rectangles.
9. Visibility per scenario is my reading of the cited visibility rules (visibleIn in the model); a scenario that the code cannot actually reach is not flagged.
10. AFTER studio-snapshot scripts (TreasureReveal, UpgradeTreeClient) are the PENDING patch copies; their installation in Studio has not happened.
11. The tutorial scenarios assume the HELP pill stays tappable mid-lesson (its handler has no lesson guard; showStep only closes the menu at the next step) and that PlowTutorialDone is already true (a replay). BEFORE TRAVEL is assumed to find the PlowTutorial HelpPill with its 60 s scan.
12. Sensitivity (measured with this tool): phone inset 36 instead of 58 -> BEFORE 95 / AFTER 38 overlaps; ArenaHud ignoring the inset -> 88 / 34; tolerance 0 px instead of 4 -> 166 / 70 (extra hits are edge-touching or sub-4 px). 390x844 portrait is not a designed layout, its hits are reported but weigh less.

## Summary

- AFTER: 32 overlaps (scenario x viewport x pair; 16 distinct element pairs), 1 off-screen element/viewport combinations, 3 touch-target (<44, <40 for dense controls) element/viewport combinations

