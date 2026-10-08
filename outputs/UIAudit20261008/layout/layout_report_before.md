# Source-derived layout check

Regenerate: `cd outputs/UIAudit20261008/layout && node check_layout.js --section before --md layout_report_before.md` (exit status 1 = counted overlaps in the AFTER section). Single scenario: `--dump driving@844x390`.

**What this is:** pixel rectangles computed from numbers read out of the Luau sources (see `layout_model.json`, every element cites file:line). **What it is not:** a render of Roblox. It was not run in Studio, it cannot see static Studio frames (listed as unknown and excluded) and a clean result does not prove that input works.

Assumptions: GuiInset 36 px on desktop viewports, 58 px on phone viewports; phones are TouchEnabled without keyboard; ArenaHud treated as inset-respecting (CoreUISafeInsets); MiniPlowGui treated as IgnoreGuiInset=true (copied from the unknown RNGGui); device notch insets 0; Roblox default jump button rect is an assumption (probe only). Overlap tolerance 4 px on both axes.

## BEFORE - BEFORE = git HEAD of game/src + untouched game/studio-snapshots

Counted overlaps (scenario x viewport x pair, tolerance > 4 px on both axes): **106** in **29** distinct element pairs.
Partly off-screen: **5** element/viewport combinations (71 scenario rows). Touch targets below the minimum: **83** element/viewport combinations (289 scenario rows), plus 4 accepted at the dense 40 px allowance.
Known elements checked: 59; unknown (excluded): 10; assumed probes (never counted): 2.

### Overlap count per scenario and viewport

| scenario | 1920x1080 | 1366x768 | 1280x720 | 844x390 | 667x375 | 932x430 | 390x844 | total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| lobby_idle | . | . | . | . | . | . | . | . |
| lobby_offers_open | . | . | . | . | . | . | 1 | 1 |
| lobby_contract_pill | 1 | 1 | 1 | . | . | . | . | 3 |
| contract_announcement | . | . | . | . | . | . | . | . |
| garage_offer_card | . | . | . | . | . | . | . | . |
| garage_equip_window | . | . | . | . | . | . | . | . |
| garage_inspect | . | . | . | . | . | . | . | . |
| driving | . | . | . | . | 1 | . | . | 1 |
| driving_offers_open | . | . | . | . | 1 | . | 2 | 3 |
| driving_contract_tracker | . | . | . | . | 1 | . | . | 1 |
| driving_treasure_toast | . | . | . | 1 | 3 | 1 | 2 | 7 |
| tutorial_step_help_open | . | . | . | . | . | . | . | . |
| tutorial_card_low_help_open | . | . | . | 1 | 1 | 1 | 2 | 5 |
| help_menu_open | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 7 |
| travel_menu_open | . | . | . | . | . | . | . | . |
| offer_details_open | . | . | . | 1 | 1 | . | 3 | 5 |
| offers_mini_plows_open | . | . | . | 1 | 2 | 1 | 1 | 5 |
| offers_inspect_open | . | . | . | . | 1 | . | 1 | 2 |
| offers_egg_screen_open | 1 | 1 | 1 | 1 | 2 | 1 | 4 | 11 |
| boss_pill_contract_tracker | 1 | 1 | 1 | . | . | . | 1 | 4 |
| boss_fight | 3 | 3 | 3 | 1 | 2 | 1 | 1 | 14 |
| upgrades_open | 1 | 1 | 1 | . | . | . | . | 3 |
| arena_prejoin | . | . | . | 2 | 2 | 1 | . | 5 |
| arena_match | . | . | . | 4 | 4 | 3 | 4 | 15 |
| boss_fight_contract_tracker | 3 | 3 | 3 | 1 | 2 | 1 | 1 | 14 |

### Overlaps (counted)

| scenario | viewport | element A (gui, DO) | element B (gui, DO) | overlap px | A rect (x,y w x h) | B rect | notes |
|---|---|---|---|---|---|---|---|
| lobby_contract_pill | 1920x1080 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | HELP REQUEST pill (ContractGui, 55) | 195x64.7 | 212,800.8 320x205.2 | 23,829.4 384x64.7 | B draws above A; children also hit: Pill tap area (pillBtn), Pill mute bell, Offer card 1 |
| help_menu_open | 1920x1080 | HELP menu (PlowTutorial, 200) | HELP REQUEST pill (ContractGui, 55) | 384x64.7 | 23,680.4 422.4x216 | 23,829.4 384x64.7 | A draws above B; children also hit: Pill tap area (pillBtn), Pill mute bell |
| offers_egg_screen_open | 1920x1080 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 62x80.8 | 212,800.8 320x205.2 | 470,241.6 980x640 | B draws above A; children also hit: Offer card 1, OP! badge on offer card 1 (intentional overlap) |
| boss_pill_contract_tracker | 1920x1080 | Contract job tracker (ContractGui, 55) | Frost King JOIN pill (FrostKingGui, 57) | 339.8x75.6 | 1416,317.9 360x340 | 1436.2,324 460.8x75.6 | B draws above A |
| boss_fight | 1920x1080 | DRIVE / EXIT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 213.1x71.3 | 1683.8,828.4 220.8x71.3 | 1513,799.2 384x140.4 | B draws above A |
| boss_fight | 1920x1080 | DRIFT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 184.3x10.8 | 1712.6,756 192x54 | 1513,799.2 384x140.4 | B draws above A |
| boss_fight | 1920x1080 | RECOVER button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 184.3x10.8 | 1712.6,928.8 192x54 | 1513,799.2 384x140.4 | B draws above A |
| upgrades_open | 1920x1080 | UPGRADES legend (UpgradeTreeGui, 150) | UPGRADES hover tooltip (desktop only) (UpgradeTreeGui, 150) | 18x43.2 | 18,1020.8 614.4x43.2 | 614.4,983 691.2x81 | same DisplayOrder |
| boss_fight_contract_tracker | 1920x1080 | DRIVE / EXIT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 213.1x71.3 | 1683.8,828.4 220.8x71.3 | 1513,799.2 384x140.4 | B draws above A |
| boss_fight_contract_tracker | 1920x1080 | DRIFT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 184.3x10.8 | 1712.6,756 192x54 | 1513,799.2 384x140.4 | B draws above A |
| boss_fight_contract_tracker | 1920x1080 | RECOVER button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 184.3x10.8 | 1712.6,928.8 192x54 | 1513,799.2 384x140.4 | B draws above A |
| lobby_contract_pill | 1366x768 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | HELP REQUEST pill (ContractGui, 55) | 138.6x45.4 | 151,569.1 232.2x145.9 | 16.4,592.3 273.2x45.4 | B draws above A; children also hit: Pill tap area (pillBtn), Pill mute bell, Offer card 1 |
| help_menu_open | 1366x768 | HELP menu (PlowTutorial, 200) | HELP REQUEST pill (ContractGui, 55) | 273.2x45.1 | 16.4,483.8 300.5x153.6 | 16.4,592.3 273.2x45.4 | A draws above B; children also hit: Pill tap area (pillBtn), Pill mute bell |
| offers_egg_screen_open | 1366x768 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 123.7x99.1 | 151,569.1 232.2x145.9 | 259.5,130.6 846.9x537.6 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| boss_pill_contract_tracker | 1366x768 | Contract job tracker (ContractGui, 55) | Frost King JOIN pill (FrostKingGui, 57) | 241.8x50.5 | 976.7,233.6 286.9x241.6 | 1021.8,230.4 327.8x53.8 | B draws above A |
| boss_fight | 1366x768 | DRIVE / EXIT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 151.6x50.7 | 1198,589.1 157.1x50.7 | 1076.4,568.3 273.2x99.8 | B draws above A |
| boss_fight | 1366x768 | DRIFT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 131.1x10.5 | 1218.5,534.8 136.6x44 | 1076.4,568.3 273.2x99.8 | B draws above A |
| boss_fight | 1366x768 | RECOVER button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 131.1x10.5 | 1218.5,657.7 136.6x44 | 1076.4,568.3 273.2x99.8 | B draws above A |
| upgrades_open | 1366x768 | UPGRADES legend (UpgradeTreeGui, 150) | UPGRADES hover tooltip (desktop only) (UpgradeTreeGui, 150) | 18x30.7 | 18,721.3 437.1x30.7 | 437.1,694.4 491.8x57.6 | same DisplayOrder |
| boss_fight_contract_tracker | 1366x768 | DRIVE / EXIT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 151.6x50.7 | 1198,589.1 157.1x50.7 | 1076.4,568.3 273.2x99.8 | B draws above A |
| boss_fight_contract_tracker | 1366x768 | DRIFT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 131.1x10.5 | 1218.5,534.8 136.6x44 | 1076.4,568.3 273.2x99.8 | B draws above A |
| boss_fight_contract_tracker | 1366x768 | RECOVER button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 131.1x10.5 | 1218.5,657.7 136.6x44 | 1076.4,568.3 273.2x99.8 | B draws above A |
| lobby_contract_pill | 1280x720 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | HELP REQUEST pill (ContractGui, 55) | 130.4x42.4 | 141,534.2 217.6x136.8 | 15.4,555.8 256x42.4 | B draws above A; children also hit: Pill tap area (pillBtn), Pill mute bell, Offer card 1 |
| help_menu_open | 1280x720 | HELP menu (PlowTutorial, 200) | HELP REQUEST pill (ContractGui, 55) | 256x41.8 | 15.4,447.6 281.6x150 | 15.4,555.8 256x42.4 | A draws above B; children also hit: Pill tap area (pillBtn), Pill mute bell |
| offers_egg_screen_open | 1280x720 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 115.4x92.2 | 141,534.2 217.6x136.8 | 243.2,122.4 793.6x504 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| boss_pill_contract_tracker | 1280x720 | Contract job tracker (ContractGui, 55) | Frost King JOIN pill (FrostKingGui, 57) | 226.6x45.7 | 915.2,220.7 268.8x225.7 | 957.4,216 307.2x50.4 | B draws above A |
| boss_fight | 1280x720 | DRIVE / EXIT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 142.1x47.5 | 1122.6,552.2 147.2x47.5 | 1008.6,532.8 256x93.6 | B draws above A |
| boss_fight | 1280x720 | DRIFT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 122.9x11.2 | 1141.8,500 128x44 | 1008.6,532.8 256x93.6 | B draws above A |
| boss_fight | 1280x720 | RECOVER button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 122.9x11.2 | 1141.8,615.2 128x44 | 1008.6,532.8 256x93.6 | B draws above A |
| upgrades_open | 1280x720 | UPGRADES legend (UpgradeTreeGui, 150) | UPGRADES hover tooltip (desktop only) (UpgradeTreeGui, 150) | 18x28.8 | 18,675.2 409.6x28.8 | 409.6,650 460.8x54 | same DisplayOrder |
| boss_fight_contract_tracker | 1280x720 | DRIVE / EXIT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 142.1x47.5 | 1122.6,552.2 147.2x47.5 | 1008.6,532.8 256x93.6 | B draws above A |
| boss_fight_contract_tracker | 1280x720 | DRIFT button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 122.9x11.2 | 1141.8,500 128x44 | 1008.6,532.8 256x93.6 | B draws above A |
| boss_fight_contract_tracker | 1280x720 | RECOVER button (PlowDriveGui, 51) | Frost King Me (HP) panel (FrostKingGui, 57) | 122.9x11.2 | 1141.8,615.2 128x44 | 1008.6,532.8 256x93.6 | B draws above A |
| driving_treasure_toast | 844x390 | DRIFT button (PlowDriveGui, 51) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 120.8x43.6 | 707.2,232.4 130x54 | 528,192 300x84 | B draws above A |
| tutorial_card_low_help_open | 844x390 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 29.1x89.7 | 211,234 422x92 | 10.1,173.7 230x150 | same DisplayOrder |
| help_menu_open | 844x390 | HELP menu (PlowTutorial, 200) | HELP REQUEST pill (ContractGui, 55) | 230x24.9 | 10.1,173.7 230x150 | 10.1,263.8 354.5x24.9 | A draws above B; children also hit: Pill tap area (pillBtn) |
| offer_details_open | 844x390 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | OfferDetails popup (PassOffersGui, 11) | 11x108 | 113,237 170x110 | 272,45 300x300 | same DisplayOrder; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_mini_plows_open | 844x390 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | MINI PLOWS panel (MiniPlowGui, 6) | 73.7x105.7 | 113,237 170x110 | 209.3,47.3 425.5x295.5 | A draws above B; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_egg_screen_open | 844x390 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 122.6x102.3 | 113,237 170x110 | 160.4,66.3 523.3x273 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| boss_fight | 844x390 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x13.7 | 10.1,325.7 92x32 | 10.1,288.6 287x50.7 | A draws above B |
| arena_prejoin | 844x390 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 150x13.8 | 681.3,124.4 150x120 | 662.5,230.6 168.8x46.5 | same DisplayOrder |
| arena_prejoin | 844x390 | LEAVE ARENA button (ArenaHud, 120) | PAINT button (ArenaHud, 120) | 101.3x16.1 | 10.1,211.2 143.5x46 | 10.1,195.3 101.3x32 | both interactive; same DisplayOrder |
| arena_match | 844x390 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 150x13.8 | 681.3,124.4 150x120 | 662.5,230.6 168.8x46.5 | same DisplayOrder |
| arena_match | 844x390 | Arena standings (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 67.5x60.2 | 681.3,124.4 150x120 | 669.1,184.2 79.7x79.7 | same DisplayOrder |
| arena_match | 844x390 | Arena feed (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 79.7x33.2 | 662.5,230.6 168.8x46.5 | 669.1,184.2 79.7x79.7 | same DisplayOrder |
| arena_match | 844x390 | LEAVE ARENA button (ArenaHud, 120) | PAINT button (ArenaHud, 120) | 101.3x16.1 | 10.1,211.2 143.5x46 | 10.1,195.3 101.3x32 | both interactive; same DisplayOrder |
| boss_fight_contract_tracker | 844x390 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x13.7 | 10.1,325.7 92x32 | 10.1,288.6 287x50.7 | A draws above B |
| driving | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | RECOVER button (PlowDriveGui, 51) | 130x5.3 | 531.7,273 130x54 | 531.7,321.8 130x54 | both interactive; same DisplayOrder |
| driving_offers_open | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | RECOVER button (PlowDriveGui, 51) | 130x5.3 | 531.7,273 130x54 | 531.7,321.8 130x54 | both interactive; same DisplayOrder |
| driving_contract_tracker | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | RECOVER button (PlowDriveGui, 51) | 130x5.3 | 531.7,273 130x54 | 531.7,321.8 130x54 | both interactive; same DisplayOrder |
| driving_treasure_toast | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | RECOVER button (PlowDriveGui, 51) | 130x5.3 | 531.7,273 130x54 | 531.7,321.8 130x54 | both interactive; same DisplayOrder |
| driving_treasure_toast | 667x375 | DRIFT button (PlowDriveGui, 51) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 119.3x44.6 | 531.7,222.4 130x54 | 351,183 300x84 | B draws above A |
| driving_treasure_toast | 667x375 | Dig combo meter (DigJuice, 55) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 36x23.3 | 280,226.5 107x23.3 | 351,183 300x84 | same DisplayOrder |
| tutorial_card_low_help_open | 667x375 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 71.3x86.3 | 166.8,225 333.5x92 | 8,161.3 230x150 | same DisplayOrder |
| help_menu_open | 667x375 | HELP menu (PlowTutorial, 200) | HELP REQUEST pill (ContractGui, 55) | 230x23.8 | 8,161.3 230x150 | 8,254.5 280.1x23.8 | A draws above B; children also hit: Pill tap area (pillBtn), Pill mute bell |
| offer_details_open | 667x375 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | OfferDetails popup (PassOffersGui, 11) | 97.5x110 | 111,225 170x110 | 183.5,37.5 300x300 | same DisplayOrder; children also hit: OfferDetails BUY, Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_mini_plows_open | 667x375 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | MINI PLOWS panel (MiniPlowGui, 6) | 152x104.5 | 111,225 170x110 | 129,45.5 409.1x284.1 | A draws above B; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_mini_plows_open | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | MINI PLOWS panel (MiniPlowGui, 6) | 6.4x54 | 531.7,273 130x54 | 129,45.5 409.1x284.1 | A draws above B |
| offers_inspect_open | 667x375 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Garage Inspect panel (neighbour build) (GarageInspectGui, 102) | 64.7x56.3 | 111,225 170x110 | 216.3,93.8 234.4x187.5 | B draws above A; children also hit: Offer card 1, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_egg_screen_open | 667x375 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 154.3x101.3 | 111,225 170x110 | 126.7,63.8 413.5x262.5 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_egg_screen_open | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 8.6x53.3 | 531.7,273 130x54 | 126.7,63.8 413.5x262.5 | B draws above A |
| boss_fight | 667x375 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x13.1 | 8,313.1 92x32 | 8,277.5 226.8x48.8 | A draws above B |
| boss_fight | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | RECOVER button (PlowDriveGui, 51) | 130x5.3 | 531.7,273 130x54 | 531.7,321.8 130x54 | both interactive; same DisplayOrder |
| arena_prejoin | 667x375 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 133.4x18.6 | 507,121.4 150x120 | 523.6,222.8 133.4x44.4 | same DisplayOrder |
| arena_prejoin | 667x375 | LEAVE ARENA button (ArenaHud, 120) | PAINT button (ArenaHud, 120) | 96x17.5 | 8,202.2 140x46 | 8,187.7 96x32 | both interactive; same DisplayOrder |
| arena_match | 667x375 | Arena standings (ArenaHud, 120) | Arena feed (ArenaHud, 120) | 133.4x18.6 | 507,121.4 150x120 | 523.6,222.8 133.4x44.4 | same DisplayOrder |
| arena_match | 667x375 | Arena standings (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 76.1x62.9 | 507,121.4 150x120 | 522.2,178.5 76.1x76.1 | same DisplayOrder |
| arena_match | 667x375 | Arena feed (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 74.7x31.7 | 523.6,222.8 133.4x44.4 | 522.2,178.5 76.1x76.1 | same DisplayOrder |
| arena_match | 667x375 | LEAVE ARENA button (ArenaHud, 120) | PAINT button (ArenaHud, 120) | 96x17.5 | 8,202.2 140x46 | 8,187.7 96x32 | both interactive; same DisplayOrder |
| boss_fight_contract_tracker | 667x375 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x13.1 | 8,313.1 92x32 | 8,277.5 226.8x48.8 | A draws above B |
| boss_fight_contract_tracker | 667x375 | DRIVE / EXIT button (PlowDriveGui, 51) | RECOVER button (PlowDriveGui, 51) | 130x5.3 | 531.7,273 130x54 | 531.7,321.8 130x54 | both interactive; same DisplayOrder |
| driving_treasure_toast | 932x430 | DRIFT button (PlowDriveGui, 51) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 121.9x41.1 | 794.1,259 130.5x54 | 616,216 300x84 | B draws above A |
| tutorial_card_low_help_open | 932x430 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 8.2x92 | 233,258 466x92 | 11.2,206.9 230x150 | same DisplayOrder |
| help_menu_open | 932x430 | HELP menu (PlowTutorial, 200) | HELP REQUEST pill (ContractGui, 55) | 230x27.9 | 11.2,206.9 230x150 | 11.2,288.6 391.4x27.9 | A draws above B; children also hit: Pill tap area (pillBtn) |
| offers_mini_plows_open | 932x430 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | MINI PLOWS panel (MiniPlowGui, 6) | 52x106.5 | 114,271 170x110 | 232,52.5 468x325 | A draws above B; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_egg_screen_open | 932x430 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 106.9x103.1 | 114,271 170x110 | 177.1,73.1 577.8x301 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| boss_fight | 932x430 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x15.1 | 11.2,359.1 92x32 | 11.2,318.2 316.9x55.9 | A draws above B |
| arena_prejoin | 932x430 | LEAVE ARENA button (ArenaHud, 120) | PAINT button (ArenaHud, 120) | 111.8x12.5 | 11.2,235.2 158.4x46 | 11.2,215.7 111.8x32 | both interactive; same DisplayOrder |
| arena_match | 932x430 | Arena standings (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 59.5x53 | 768,132.4 150x120 | 738.2,199.4 89.3x89.3 | same DisplayOrder |
| arena_match | 932x430 | Arena feed (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 89.3x37.2 | 731.6,251.4 186.4x52.1 | 738.2,199.4 89.3x89.3 | same DisplayOrder |
| arena_match | 932x430 | LEAVE ARENA button (ArenaHud, 120) | PAINT button (ArenaHud, 120) | 111.8x12.5 | 11.2,235.2 158.4x46 | 11.2,215.7 111.8x32 | both interactive; same DisplayOrder |
| boss_fight_contract_tracker | 932x430 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x15.1 | 11.2,359.1 92x32 | 11.2,318.2 316.9x55.9 | A draws above B |
| lobby_offers_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 22.1x101.3 | 109,576.6 170x160.4 | 256.9,624.6 130x101.3 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 2 (intentional overlap) |
| driving_offers_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 22.1x101.3 | 109,576.6 170x160.4 | 256.9,624.6 130x101.3 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 2 (intentional overlap) |
| driving_offers_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIFT button (PlowDriveGui, 51) | 22.1x22.6 | 109,576.6 170x160.4 | 256.9,523.3 130x76 | B draws above A; children also hit: Offer card 1, OP! badge on offer card 1 (intentional overlap) |
| driving_treasure_toast | 390x844 | DRIFT button (PlowDriveGui, 51) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 117.1x25.1 | 256.9,523.3 130x76 | 74,464.4 300x84 | B draws above A |
| driving_treasure_toast | 390x844 | Dig combo meter (DigJuice, 55) | Treasure reward toast (Studio-only script) (TreasureToastGui, 55) | 66.3x14.4 | 161.9,528.7 66.3x14.4 | 74,464.4 300x84 | same DisplayOrder |
| tutorial_card_low_help_open | 390x844 | Tutorial instruction Card (PlowTutorial, 200) | HELP menu (PlowTutorial, 200) | 189.7x109.7 | 45,506.4 300x135 | 4.7,531.7 230x168.8 | same DisplayOrder; children also hit: Card button OK! (okButton steps only) |
| tutorial_card_low_help_open | 390x844 | Tutorial instruction Card (PlowTutorial, 200) | DRIVE / EXIT button (PlowDriveGui, 51) | 88.1x16.9 | 45,506.4 300x135 | 256.9,624.6 130x101.3 | A draws above B |
| help_menu_open | 390x844 | HELP menu (PlowTutorial, 200) | HELP REQUEST pill (ContractGui, 55) | 163.8x59 | 4.7,531.7 230x168.8 | 4.7,545.3 163.8x59 | A draws above B; children also hit: Pill tap area (pillBtn), Pill mute bell |
| offer_details_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | OfferDetails popup (PassOffersGui, 11) | 170x56.4 | 109,576.6 170x160.4 | 45,211 300x422 | same DisplayOrder; children also hit: OfferDetails BUY, OfferDetails CLOSE, Offer card 1, OP! badge on offer card 1 (intentional overlap) |
| offer_details_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 22.1x101.3 | 109,576.6 170x160.4 | 256.9,624.6 130x101.3 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 2 (intentional overlap) |
| offer_details_open | 390x844 | OfferDetails popup (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 88.1x8.4 | 45,211 300x422 | 256.9,624.6 130x101.3 | B draws above A |
| offers_mini_plows_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 22.1x101.3 | 109,576.6 170x160.4 | 256.9,624.6 130x101.3 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 2 (intentional overlap) |
| offers_inspect_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 22.1x101.3 | 109,576.6 170x160.4 | 256.9,624.6 130x101.3 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 2 (intentional overlap) |
| offers_egg_screen_open | 390x844 | HELP pill (PlowTutorial, 200) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 66.7x29.5 | 4.7,704.7 92x38 | 30,143.5 330x590.8 | A draws above B |
| offers_egg_screen_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | DRIVE / EXIT button (PlowDriveGui, 51) | 22.1x101.3 | 109,576.6 170x160.4 | 256.9,624.6 130x101.3 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 2 (intentional overlap) |
| offers_egg_screen_open | 390x844 | Offers column (1.5x Snow, Aurora Wheels cards) (PassOffersGui, 11) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 170x157.6 | 109,576.6 170x160.4 | 30,143.5 330x590.8 | B draws above A; children also hit: Offer card 1, Offer card 2, OP! badge on offer card 1 (intentional overlap), OP! badge on offer card 2 (intentional overlap) |
| offers_egg_screen_open | 390x844 | DRIVE / EXIT button (PlowDriveGui, 51) | Verity EggScreen (DETAILS) (VerityEggGui, 103) | 103.1x101.3 | 256.9,624.6 130x101.3 | 30,143.5 330x590.8 | B draws above A |
| boss_pill_contract_tracker | 390x844 | Contract job tracker (ContractGui, 55) | Frost King JOIN pill (FrostKingGui, 57) | 82.7x35.7 | 148.2,183.8 163.8x283 | 229.3,160.4 156x59.1 | B draws above A |
| boss_fight | 390x844 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x29.5 | 4.7,704.7 92x38 | 4.7,624.6 132.6x109.7 | A draws above B |
| arena_match | 390x844 | Arena standings (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 150x94.3 | 234.2,215.2 150x235.8 | 233.3,356.7 188.6x188.6 | same DisplayOrder |
| arena_match | 390x844 | Arena feed (ArenaHud, 120) | BOOST button (ArenaHud, 120) | 78x78.6 | 306.2,466.7 78x110 | 233.3,356.7 188.6x188.6 | same DisplayOrder |
| arena_match | 390x844 | Arena feed (ArenaHud, 120) | BRACE button (ArenaHud, 120) | 25.9x51.1 | 306.2,466.7 78x110 | 198.4,525.7 133.6x133.6 | same DisplayOrder |
| arena_match | 390x844 | BOOST button (ArenaHud, 120) | BRACE button (ArenaHud, 120) | 98.7x19.6 | 233.3,356.7 188.6x188.6 | 198.4,525.7 133.6x133.6 | both interactive; same DisplayOrder |
| boss_fight_contract_tracker | 390x844 | HELP pill (PlowTutorial, 200) | Frost King Me (HP) panel (FrostKingGui, 57) | 92x29.5 | 4.7,704.7 92x38 | 4.7,624.6 132.6x109.7 | A draws above B |

### Distinct overlapping pairs (which viewports, how many scenarios)

| pair | scenarios x viewports | viewports |
|---|---:|---|
| Offers column (1.5x Snow, Aurora Wheels cards) / HELP REQUEST pill | 3 | 1920x1080, 1366x768, 1280x720 |
| HELP menu / HELP REQUEST pill | 7 | 1920x1080, 1366x768, 1280x720, 844x390, 667x375, 932x430, 390x844 |
| Offers column (1.5x Snow, Aurora Wheels cards) / Verity EggScreen (DETAILS) | 7 | 1920x1080, 1366x768, 1280x720, 844x390, 667x375, 932x430, 390x844 |
| Contract job tracker / Frost King JOIN pill | 4 | 1920x1080, 1366x768, 1280x720, 390x844 |
| DRIVE / EXIT button / Frost King Me (HP) panel | 6 | 1920x1080, 1366x768, 1280x720 |
| DRIFT button / Frost King Me (HP) panel | 6 | 1920x1080, 1366x768, 1280x720 |
| RECOVER button / Frost King Me (HP) panel | 6 | 1920x1080, 1366x768, 1280x720 |
| UPGRADES legend / UPGRADES hover tooltip (desktop only) | 3 | 1920x1080, 1366x768, 1280x720 |
| DRIFT button / Treasure reward toast (Studio-only script) | 4 | 844x390, 667x375, 932x430, 390x844 |
| Tutorial instruction Card / HELP menu | 4 | 844x390, 667x375, 932x430, 390x844 |
| Offers column (1.5x Snow, Aurora Wheels cards) / OfferDetails popup | 3 | 844x390, 667x375, 390x844 |
| Offers column (1.5x Snow, Aurora Wheels cards) / MINI PLOWS panel | 3 | 844x390, 667x375, 932x430 |
| HELP pill / Frost King Me (HP) panel | 8 | 844x390, 667x375, 932x430, 390x844 |
| Arena standings / Arena feed | 4 | 844x390, 667x375 |
| LEAVE ARENA button / PAINT button | 6 | 844x390, 667x375, 932x430 |
| Arena standings / BOOST button | 4 | 844x390, 667x375, 932x430, 390x844 |
| Arena feed / BOOST button | 4 | 844x390, 667x375, 932x430, 390x844 |
| DRIVE / EXIT button / RECOVER button | 6 | 667x375 |
| Dig combo meter / Treasure reward toast (Studio-only script) | 2 | 667x375, 390x844 |
| DRIVE / EXIT button / MINI PLOWS panel | 1 | 667x375 |
| Offers column (1.5x Snow, Aurora Wheels cards) / Garage Inspect panel (neighbour build) | 1 | 667x375 |
| DRIVE / EXIT button / Verity EggScreen (DETAILS) | 2 | 667x375, 390x844 |
| Offers column (1.5x Snow, Aurora Wheels cards) / DRIVE / EXIT button | 6 | 390x844 |
| Offers column (1.5x Snow, Aurora Wheels cards) / DRIFT button | 1 | 390x844 |
| Tutorial instruction Card / DRIVE / EXIT button | 1 | 390x844 |
| OfferDetails popup / DRIVE / EXIT button | 1 | 390x844 |
| HELP pill / Verity EggScreen (DETAILS) | 1 | 390x844 |
| Arena feed / BRACE button | 1 | 390x844 |
| BOOST button / BRACE button | 1 | 390x844 |

### Partly off-screen (known elements)

| scenario | viewport | element | rect | outside by |
|---|---|---|---|---|
| lobby_idle | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| lobby_idle | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| lobby_offers_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| lobby_offers_open | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| lobby_contract_pill | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| lobby_contract_pill | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| contract_announcement | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| garage_offer_card | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| garage_equip_window | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| garage_inspect | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| garage_inspect | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| driving | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| driving | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| driving_offers_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| driving_offers_open | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| driving_contract_tracker | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| driving_treasure_toast | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| driving_treasure_toast | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| tutorial_step_help_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| tutorial_card_low_help_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| help_menu_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| travel_menu_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| offer_details_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| offer_details_open | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| offers_mini_plows_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| offers_mini_plows_open | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| offers_inspect_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| offers_inspect_open | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| offers_egg_screen_open | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| offers_egg_screen_open | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| boss_pill_contract_tracker | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| boss_fight | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| boss_fight | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| boss_fight_contract_tracker | 844x390 | TRAVEL button | 10,363 92x32 | bottom 5 |
| boss_fight_contract_tracker | 844x390 | OFFERS toggle (small screens) | 113,355 120x40 | bottom 5 |
| lobby_idle | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| lobby_idle | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| lobby_offers_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| lobby_offers_open | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| lobby_contract_pill | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| lobby_contract_pill | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| contract_announcement | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| garage_offer_card | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| garage_equip_window | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| garage_inspect | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| garage_inspect | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| driving | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| driving | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| driving_offers_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| driving_offers_open | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| driving_contract_tracker | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| driving_treasure_toast | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| driving_treasure_toast | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| tutorial_step_help_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| tutorial_card_low_help_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| help_menu_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| travel_menu_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| offer_details_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| offer_details_open | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| offers_mini_plows_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| offers_mini_plows_open | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| offers_inspect_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| offers_inspect_open | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| offers_egg_screen_open | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| offers_egg_screen_open | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| boss_pill_contract_tracker | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| boss_fight | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| boss_fight | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| boss_fight_contract_tracker | 667x375 | TRAVEL button | 8,351 92x32 | bottom 8 |
| boss_fight_contract_tracker | 667x375 | OFFERS toggle (small screens) | 111,343 120x40 | bottom 8 |
| arena_match | 390x844 | BOOST button | 233.3,356.7 188.6x188.6 | right 31.9 |

### Touch targets smaller than 44x44 (touch viewports only)

| element | viewport | size w x h | level | scenarios |
|---|---|---|---|---:|
| HELP pill | 844x390 | 92x32 | BELOW | 23 |
| TRAVEL button | 844x390 | 92x32 | BELOW | 22 |
| OFFERS toggle (small screens) | 844x390 | 120x40 | dense-40-accepted | 13 |
| Pill tap area (pillBtn) | 844x390 | 276.5x24.9 | BELOW | 2 |
| Pill mute bell | 844x390 | 60.3x17.9 | BELOW | 2 |
| Announce HELP OUT | 844x390 | 272.8x20.3 | BELOW | 1 |
| Announce LATER | 844x390 | 186x20.3 | BELOW | 1 |
| OfferCard X | 844x390 | 32x26.7 | BELOW | 1 |
| OfferCard BUY | 844x390 | 101.1x36.5 | BELOW | 1 |
| OfferCard RESERVE | 844x390 | 101.1x36.5 | BELOW | 1 |
| OfferCard REROLL | 844x390 | 97.7x36.5 | BELOW | 1 |
| GarageWindow X | 844x390 | 26.8x27.4 | BELOW | 1 |
| Inspect X | 844x390 | 24.4x23.4 | BELOW | 2 |
| Tracker CANCEL | 844x390 | 141.8x10.8 | BELOW | 3 |
| Card button ? HELP | 844x390 | 63.3x15.6 | BELOW | 2 |
| Card button SKIP | 844x390 | 59.1x15.6 | BELOW | 2 |
| Card button OK! (okButton steps only) | 844x390 | 101.3x23.9 | BELOW | 2 |
| OfferDetails BUY | 844x390 | 150x39 | BELOW | 1 |
| OfferDetails CLOSE | 844x390 | 90x39 | BELOW | 1 |
| MINI PLOWS X | 844x390 | 42.5x41.4 | BELOW | 1 |
| EggScreen X | 844x390 | 24.6x35.5 | BELOW | 1 |
| Frost King JOIN pill | 844x390 | 337.6x27.3 | BELOW | 1 |
| UPGRADES close X | 844x390 | 23.4x23.4 | BELOW | 1 |
| PAINT button | 844x390 | 101.3x32 | BELOW | 2 |
| HELP pill | 667x375 | 92x32 | BELOW | 23 |
| TRAVEL button | 667x375 | 92x32 | BELOW | 22 |
| OFFERS toggle (small screens) | 667x375 | 120x40 | dense-40-accepted | 13 |
| Pill tap area (pillBtn) | 667x375 | 218.5x23.8 | BELOW | 2 |
| Pill mute bell | 667x375 | 47.6x17.1 | BELOW | 2 |
| Announce HELP OUT | 667x375 | 264.1x19.4 | BELOW | 1 |
| Announce LATER | 667x375 | 180.1x19.4 | BELOW | 1 |
| OfferCard X | 667x375 | 30.8x25.7 | BELOW | 1 |
| OfferCard BUY | 667x375 | 97.2x35.1 | BELOW | 1 |
| OfferCard RESERVE | 667x375 | 97.2x35.1 | BELOW | 1 |
| OfferCard REROLL | 667x375 | 94x35.1 | BELOW | 1 |
| GarageWindow X | 667x375 | 25.7x26.3 | BELOW | 1 |
| Inspect X | 667x375 | 23.4x22.5 | BELOW | 2 |
| Tracker CANCEL | 667x375 | 112.1x10.3 | BELOW | 3 |
| Card button ? HELP | 667x375 | 50x15.6 | BELOW | 2 |
| Card button SKIP | 667x375 | 46.7x15.6 | BELOW | 2 |
| Card button OK! (okButton steps only) | 667x375 | 80x23.9 | BELOW | 2 |
| OfferDetails BUY | 667x375 | 150x39 | BELOW | 1 |
| OfferDetails CLOSE | 667x375 | 90x39 | BELOW | 1 |
| MINI PLOWS X | 667x375 | 40.9x39.8 | BELOW | 1 |
| EggScreen X | 667x375 | 23.6x34.1 | BELOW | 1 |
| Frost King JOIN pill | 667x375 | 266.8x26.3 | BELOW | 1 |
| UPGRADES close X | 667x375 | 22.5x22.5 | BELOW | 1 |
| PAINT button | 667x375 | 96x32 | BELOW | 2 |
| HELP pill | 932x430 | 92x32 | BELOW | 23 |
| TRAVEL button | 932x430 | 92x32 | BELOW | 22 |
| OFFERS toggle (small screens) | 932x430 | 120x40 | dense-40-accepted | 13 |
| Pill tap area (pillBtn) | 932x430 | 305.3x27.9 | BELOW | 2 |
| Pill mute bell | 932x430 | 66.5x20.1 | BELOW | 2 |
| Announce HELP OUT | 932x430 | 272.8x22.8 | BELOW | 1 |
| Announce LATER | 932x430 | 186x22.8 | BELOW | 1 |
| OfferCard X | 932x430 | 35.3x29.4 | BELOW | 1 |
| OfferCard BUY | 932x430 | 111.5x40.2 | BELOW | 1 |
| OfferCard RESERVE | 932x430 | 111.5x40.2 | BELOW | 1 |
| OfferCard REROLL | 932x430 | 107.7x40.2 | BELOW | 1 |
| GarageWindow X | 932x430 | 29.5x30.2 | BELOW | 1 |
| Inspect X | 932x430 | 26.9x25.8 | BELOW | 2 |
| Tracker CANCEL | 932x430 | 144x12.1 | BELOW | 3 |
| Card button ? HELP | 932x430 | 69.9x15.6 | BELOW | 2 |
| Card button SKIP | 932x430 | 65.2x15.6 | BELOW | 2 |
| Card button OK! (okButton steps only) | 932x430 | 111.8x23.9 | BELOW | 2 |
| OfferDetails BUY | 932x430 | 158.4x39 | BELOW | 1 |
| OfferDetails CLOSE | 932x430 | 95.1x39 | BELOW | 1 |
| EggScreen X | 932x430 | 27.1x39.1 | BELOW | 1 |
| Frost King JOIN pill | 932x430 | 372.8x30.1 | BELOW | 1 |
| UPGRADES close X | 932x430 | 25.8x25.8 | BELOW | 1 |
| PAINT button | 932x430 | 111.8x32 | BELOW | 2 |
| HELP pill | 390x844 | 92x38 | BELOW | 23 |
| TRAVEL button | 390x844 | 92x37 | BELOW | 22 |
| OFFERS toggle (small screens) | 390x844 | 120x40 | dense-40-accepted | 13 |
| Pill mute bell | 390x844 | 27.8x42.4 | BELOW | 2 |
| OfferCard X | 390x844 | 18.5x15.4 | BELOW | 1 |
| OfferCard BUY | 390x844 | 58.5x21.1 | BELOW | 1 |
| OfferCard RESERVE | 390x844 | 58.5x21.1 | BELOW | 1 |
| OfferCard REROLL | 390x844 | 56.6x21.1 | BELOW | 1 |
| GarageWindow X | 390x844 | 19.3x19.7 | BELOW | 1 |
| Inspect X | 390x844 | 16.4x15.7 | BELOW | 2 |
| Tracker CANCEL | 390x844 | 65.5x25.5 | BELOW | 3 |
| Card button ? HELP | 390x844 | 45x23 | BELOW | 2 |
| Card button SKIP | 390x844 | 42x23 | BELOW | 2 |
| Card button OK! (okButton steps only) | 390x844 | 72x35.1 | BELOW | 2 |
| MINI PLOWS X | 390x844 | 33.4x32.5 | BELOW | 1 |
| UPGRADES close X | 390x844 | 23.4x23.4 | BELOW | 1 |

### Top-level elements that start inside the Roblox top-bar zone (information only, not counted; the top-bar buttons are core UI at the screen edges, the centre is usually free)

| element | viewport: top y |
|---|---|
| Tutorial instruction Card | 1920x1080: 27 (inset 36); 1366x768: 19.2 (inset 36); 1280x720: 18 (inset 36); 844x390: 9.8 (inset 58); 667x375: 9.4 (inset 58); 932x430: 10.8 (inset 58); 390x844: 21.1 (inset 58) |
| Frost King boss bar | 1920x1080: 17.3 (inset 36); 1366x768: 12.3 (inset 36); 1280x720: 11.5 (inset 36); 844x390: 6.2 (inset 58); 667x375: 6 (inset 58); 932x430: 6.9 (inset 58); 390x844: 13.5 (inset 58) |
| UPGRADES title | 1920x1080: 27 (inset 36); 1366x768: 19.2 (inset 36); 1280x720: 18 (inset 36); 844x390: 9.8 (inset 58); 667x375: 9.4 (inset 58); 932x430: 10.8 (inset 58); 390x844: 21.1 (inset 58) |
| UPGRADES close X | 1920x1080: 27 (inset 36); 1366x768: 19.2 (inset 36); 1280x720: 18 (inset 36); 844x390: 9.8 (inset 58); 667x375: 9.4 (inset 58); 932x430: 10.8 (inset 58); 390x844: 21.1 (inset 58) |
| Garage equip window (GarageWindow) | 844x390: 31.2 (inset 58); 667x375: 30 (inset 58); 932x430: 34.4 (inset 58) |
| OfferDetails popup | 844x390: 45 (inset 58); 667x375: 37.5 (inset 58) |
| MINI PLOWS panel | 844x390: 47.3 (inset 58); 667x375: 45.5 (inset 58); 932x430: 52.5 (inset 58) |

### Probe overlaps against ASSUMED rects (jump button default, UPGRADES strip fallback band) - NOT counted

| probe | element | viewport | overlap px | probe rect | element rect | scenarios |
|---|---|---|---|---|---|---:|
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 1366x768 | 332x15.2 | 517,676 332x92 | 434.2,276.5 497.7x414.7 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 1280x720 | 332x20 | 474,628 332x92 | 406.7,259.2 466.6x388.8 | 1 |
| Roblox touch jump button (ASSUMED default rect) | DRIVE / EXIT button | 844x390 | 70x39 | 729,300 70x70 | 693.8,285 143.5x54 | 19 |
| UPGRADES strip fallback band (ASSUMED) | Offers column (1.5x Snow, Aurora Wheels cards) | 844x390 | 27x49 | 256,298 332x92 | 113,237 170x110 | 6 |
| UPGRADES strip fallback band (ASSUMED) | Offer card 2 | 844x390 | 27x49 | 256,298 332x92 | 113,295.3 170x51.7 | 6 |
| UPGRADES strip fallback band (ASSUMED) | OP! badge on offer card 2 (intentional overlap) | 844x390 | 37.9x12.3 | 256,298 332x92 | 248.3,288.6 45.6x21.7 | 6 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 844x390 | 332x53 | 256,298 332x92 | 253.5,70.2 337x280.8 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard BUY | 844x390 | 101.1x12.3 | 256,298 332x92 | 267,273.8 101.1x36.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard RESERVE | 844x390 | 101.1x12.3 | 256,298 332x92 | 374.8,273.8 101.1x36.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard REROLL | 844x390 | 97.7x12.3 | 256,298 332x92 | 482.7,273.8 97.7x36.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage equip window (GarageWindow) | 844x390 | 332x37.4 | 256,298 332x92 | 178.6,31.2 486.7x304.2 | 1 |
| Roblox touch jump button (ASSUMED default rect) | RECOVER button | 844x390 | 70x34.3 | 729,300 70x70 | 707.2,335.7 130x54 | 6 |
| UPGRADES strip fallback band (ASSUMED) | Tutorial instruction Card | 844x390 | 332x28 | 256,298 332x92 | 211,234 422x92 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Card button OK! (okButton steps only) | 844x390 | 101.3x20.6 | 256,298 332x92 | 371.4,294.7 101.3x23.9 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails popup | 844x390 | 300x47 | 256,298 332x92 | 272,45 300x300 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails BUY | 844x390 | 150x32 | 256,298 332x92 | 305,291 150x39 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails CLOSE | 844x390 | 90x32 | 256,298 332x92 | 461,291 90x39 | 1 |
| UPGRADES strip fallback band (ASSUMED) | MINI PLOWS panel | 844x390 | 332x44.7 | 256,298 332x92 | 209.3,47.3 425.5x295.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Verity EggScreen (DETAILS) | 844x390 | 332x41.3 | 256,298 332x92 | 160.4,66.3 523.3x273 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Frost King Me (HP) panel | 844x390 | 41.1x41.3 | 256,298 332x92 | 10.1,288.6 287x50.7 | 2 |
| Roblox touch jump button (ASSUMED default rect) | DRIVE / EXIT button | 667x375 | 70x42 | 552,285 70x70 | 531.7,273 130x54 | 19 |
| UPGRADES strip fallback band (ASSUMED) | OFFERS toggle (small screens) | 667x375 | 63.5x32 | 167.5,283 332x92 | 111,343 120x40 | 13 |
| UPGRADES strip fallback band (ASSUMED) | Offers column (1.5x Snow, Aurora Wheels cards) | 667x375 | 113.5x52 | 167.5,283 332x92 | 111,225 170x110 | 6 |
| UPGRADES strip fallback band (ASSUMED) | Offer card 2 | 667x375 | 113.5x51.7 | 167.5,283 332x92 | 111,283.3 170x51.7 | 6 |
| UPGRADES strip fallback band (ASSUMED) | OP! badge on offer card 2 (intentional overlap) | 667x375 | 45.6x15.3 | 167.5,283 332x92 | 246.3,276.6 45.6x21.7 | 6 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 667x375 | 324x54.5 | 167.5,283 332x92 | 171.5,67.5 324x270 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard BUY | 667x375 | 97.2x15.4 | 167.5,283 332x92 | 184.5,263.3 97.2x35.1 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard RESERVE | 667x375 | 97.2x15.4 | 167.5,283 332x92 | 288.1,263.3 97.2x35.1 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard REROLL | 667x375 | 94x15.4 | 167.5,283 332x92 | 391.8,263.3 94x35.1 | 1 |
| Roblox touch jump button (ASSUMED default rect) | Garage equip window (GarageWindow) | 667x375 | 15.5x37.5 | 552,285 70x70 | 99.5,30 468x292.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage equip window (GarageWindow) | 667x375 | 332x39.5 | 167.5,283 332x92 | 99.5,30 468x292.5 | 1 |
| Roblox touch jump button (ASSUMED default rect) | RECOVER button | 667x375 | 70x33.3 | 552,285 70x70 | 531.7,321.8 130x54 | 6 |
| UPGRADES strip fallback band (ASSUMED) | HELP menu | 667x375 | 70.5x28.3 | 167.5,283 332x92 | 8,161.3 230x150 | 3 |
| UPGRADES strip fallback band (ASSUMED) | Tutorial instruction Card | 667x375 | 332x34 | 167.5,283 332x92 | 166.8,225 333.5x92 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Card button OK! (okButton steps only) | 667x375 | 80x23.9 | 167.5,283 332x92 | 293.5,285.7 80x23.9 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails popup | 667x375 | 300x54.5 | 167.5,283 332x92 | 183.5,37.5 300x300 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails BUY | 667x375 | 150x39 | 167.5,283 332x92 | 216.5,283.5 150x39 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails CLOSE | 667x375 | 90x39 | 167.5,283 332x92 | 372.5,283.5 90x39 | 1 |
| UPGRADES strip fallback band (ASSUMED) | MINI PLOWS panel | 667x375 | 332x46.5 | 167.5,283 332x92 | 129,45.5 409.1x284.1 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Verity EggScreen (DETAILS) | 667x375 | 332x43.3 | 167.5,283 332x92 | 126.7,63.8 413.5x262.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Frost King Me (HP) panel | 667x375 | 67.3x43.3 | 167.5,283 332x92 | 8,277.5 226.8x48.8 | 2 |
| Roblox touch jump button (ASSUMED default rect) | DRIVE / EXIT button | 932x430 | 70x31 | 817,340 70x70 | 766.1,317 158.4x54 | 19 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 932x430 | 332x49 | 300,338 332x92 | 280.2,77.4 371.5x309.6 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard BUY | 932x430 | 106.6x4.1 | 300,338 332x92 | 295.1,301.9 111.5x40.2 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard RESERVE | 932x430 | 111.5x4.1 | 300,338 332x92 | 414,301.9 111.5x40.2 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferCard REROLL | 932x430 | 99.1x4.1 | 300,338 332x92 | 532.9,301.9 107.7x40.2 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage equip window (GarageWindow) | 932x430 | 332x31.8 | 300,338 332x92 | 197.7,34.4 536.6x335.4 | 1 |
| Roblox touch jump button (ASSUMED default rect) | RECOVER button | 932x430 | 70x37.1 | 817,340 70x70 | 794.1,372.9 130.5x54 | 6 |
| UPGRADES strip fallback band (ASSUMED) | Tutorial instruction Card | 932x430 | 332x12 | 300,338 332x92 | 233,258 466x92 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Card button OK! (okButton steps only) | 932x430 | 111.8x4.6 | 300,338 332x92 | 410.1,318.7 111.8x23.9 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails popup | 932x430 | 316.9x27 | 300,338 332x92 | 307.6,65 316.9x300 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails BUY | 932x430 | 158.4x12 | 300,338 332x92 | 342.4,311 158.4x39 | 1 |
| UPGRADES strip fallback band (ASSUMED) | OfferDetails CLOSE | 932x430 | 95.1x12 | 300,338 332x92 | 507.2,311 95.1x39 | 1 |
| UPGRADES strip fallback band (ASSUMED) | MINI PLOWS panel | 932x430 | 332x39.5 | 300,338 332x92 | 232,52.5 468x325 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Verity EggScreen (DETAILS) | 932x430 | 332x36.1 | 300,338 332x92 | 177.1,73.1 577.8x301 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Frost King Me (HP) panel | 932x430 | 28.1x36.1 | 300,338 332x92 | 11.2,318.2 316.9x55.9 | 2 |
| UPGRADES strip fallback band (ASSUMED) | TRAVEL button | 390x844 | 67x33 | 29,752 332x92 | 4,748 92x37 | 22 |
| UPGRADES strip fallback band (ASSUMED) | OFFERS toggle (small screens) | 390x844 | 120x33 | 29,752 332x92 | 109,745 120x40 | 13 |
| Roblox touch jump button (ASSUMED default rect) | Garage OfferCard | 390x844 | 17.5x5.6 | 275,754 70x70 | 97.5,597.1 195x162.5 | 1 |
| UPGRADES strip fallback band (ASSUMED) | Garage OfferCard | 390x844 | 195x7.6 | 29,752 332x92 | 97.5,597.1 195x162.5 | 1 |
| Roblox touch jump button (ASSUMED default rect) | RECOVER button | 390x844 | 70x68.9 | 275,754 70x70 | 256.9,746.9 130x76 | 6 |
| UPGRADES strip fallback band (ASSUMED) | RECOVER button | 390x844 | 104.1x70.9 | 29,752 332x92 | 256.9,746.9 130x76 | 6 |
| Roblox touch jump button (ASSUMED default rect) | JOIN MATCH button | 390x844 | 20x11.4 | 275,754 70x70 | 95,694.7 200x70.7 | 1 |
| Roblox touch jump button (ASSUMED default rect) | Arena status line | 390x844 | 17.5x35.4 | 275,754 70x70 | 97.5,781.1 195x35.4 | 2 |

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

- BEFORE: 106 overlaps (scenario x viewport x pair; 29 distinct element pairs), 5 off-screen element/viewport combinations, 83 touch-target (<44, <40 for dense controls) element/viewport combinations

