# Rebalance 2026-10-05: before vs after (simulation)

Model estimates from outputs/Rebalance20261005/sim (40 seeds per World 1 behaviour, 20 for World 2), not human playtests.
Value buyer = buys the best income gain per Snow and saves for clearly better items; legacy = the old egg-first spender.
'Gap' = minutes between purchases that raise income by >= 10%; 'unavailable' = longest stretch without an obtainable,
affordable (within 10 min of income) part or upgrade.

## Summary per behaviour

| Behaviour | W1 min before -> after (median, P90) | Longest gap per player med/P90 | Unavailable P90 | First part min | Parts bought W1 | Job pay vs collecting |
|---|---|---|---|---|---|---|
| efficient | 175 / 194 -> **143 / 153** | 21.6 / 28.5 -> **13.9 / 19.9** | 8.2 -> **3.0** | 2.2 -> **2.2** | 25.0 -> **29.0** | 0.64 -> **2.0** |
| casual | 235 / 258 -> **218 / 250** | 25.6 / 39.4 -> **20.4 / 28.0** | 24.8 -> **4.6** | 2.2 -> **9.0** | 21.0 -> **25.0** | 0.64 -> **2.0** |
| noRewards | 201 / 246 -> **227 / 246** | 20.7 / 39.2 -> **19.9 / 33.3** | 7.3 -> **1.7** | 1.9 -> **2.1** | 24.0 -> **29.0** | 0 -> **0** |
| jobs | 176 / 191 -> **140 / 150** | 19.2 / 29.2 -> **12.9 / 16.7** | 8.1 -> **3.0** | 2.2 -> **2.2** | 26.0 -> **29.0** | 0.64 -> **2.0** |
| unlucky | 235 / 263 -> **195 / 213** | 19.6 / 34.3 -> **15.8 / 26.1** | 7.5 -> **6.7** | 2.1 -> **2.1** | 28.0 -> **35.0** | 0.64 -> **2.0** |
| lucky | 146 / 162 -> **131 / 142** | 15.8 / 23.4 -> **12.7 / 18.2** | 4.4 -> **2.9** | 2.1 -> **2.1** | 22.0 -> **23.0** | 0.64 -> **2.0** |
| boosted | 111 / 125 -> **96 / 105** | 12.6 / 18.1 -> **10.1 / 14.8** | 3.1 -> **2.9** | 2.3 -> **2.3** | 23.0 -> **23.5** | 0.64 -> **2.0** |
| legacy:efficient | 253 / 313 -> **234 / 270** | 46.4 / 56.6 -> **41.5 / 56.8** | 11.1 -> **3.4** | 2.0 -> **2.0** | 24.0 -> **28.5** | 0.64 -> **2.0** |
| legacy:casual | 409 / 465 -> **368 / 435** | 68.2 / 141.8 -> **60.8 / 79.5** | 11.3 -> **7.7** | 2.0 -> **2.0** | 21.0 -> **26.0** | 0.64 -> **2.0** |
| legacy:noRewards | 287 / 318 -> **321 / 392** | 45.7 / 69.3 -> **58.4 / 78.5** | 8.7 -> **5.2** | 7.6 -> **2.0** | 22.0 -> **29.0** | 0 -> **0** |

World 2 (Sakura -> Cosmic, value buyer): 277 min median (P90 311) -> **282 min (P90 341)**. Rebirth World 1 replay: 5.3 -> **5.3** min.

## Offers (value buyer, efficient)

| | Before | After |
|---|---|---|
| usefulShare | not logged | 0.446 |
| affordableUsefulShare | not logged | 0.222 |
| duplicateShare | not logged | 0.261 |
| longest dry streak (max) | not logged | 6 |
| slot share | not logged | {'Engine': 0.34, 'Blade': 0.334, 'Gear': 0.326} |

## Per stage: efficient

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 1.7 / 3.8 -> **1.6 / 3.8** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.3 -> 1.8 | 0.69 -> 1.97 |
| Desert | 4.8 -> **4.6** | 2.5 / 3.9 -> **2.4 / 3.5** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.2 -> 1.7 | 0.69 -> 1.99 |
| Cursed | 13.8 -> **13.7** | 4.2 / 6.6 -> **3.6 / 5.4** | Balanced Engine 450 (0.0 min) | Balanced Engine 450 (0.0 min) | 5.3 -> 2.3 | 0.69 -> 2.0 |
| Crystal | 31.9 -> **27.5** | 19.5 / 28.5 -> **6.9 / 10.7** | Hex Breaker 240M (0.2 min) | Sandcrawler Tracks 660K (0.0 min) | 6.8 -> 4.0 | 0.69 -> 2.0 |
| Retro | 100.1 -> **55.7** | 8.2 / 9.6 -> **8.1 / 10.0** | Arcade Turbo 350B (3.9 min) | Cartridge Cruncher 160B (2.5 min) | 12.8 -> 5.2 | 0.69 -> 2.0 |
| Jungle | 120.4 -> **86.8** | 8.0 / 10.8 -> **8.5 / 14.4** | Tiki Thumper 480B (1.6 min) | Totem Torque 1.8T (3.5 min) | 12.3 -> 6.6 | 0.69 -> 2.0 |
| AbsoluteZero | 146.8 -> **113.4** | 7.0 / 9.3 -> **6.6 / 10.0** | Cryo Compressor 5.1T (1.3 min) | Petal Sweeper 210T (102.8 min) | 12.3 -> None | 0.69 -> 2.0 |
| Sakura | 175.0 -> **143.4** | 0.3 / 0.9 -> **0.4 / 0.7** | Lantern Twin 180T (0.2 min) | Vine Crawler Tracks 4.8T (0.0 min) | 9.5 -> 2.5 | 0.69 -> 2.0 |

## Per stage: casual

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 2.9 / 4.1 -> **3.0 / 4.5** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.3 -> 1.8 | 0.69 -> 1.97 |
| Desert | 7.1 -> **7.1** | 4.7 / 6.4 -> **3.7 / 5.8** | Snowball Motor 300 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.5 -> 1.5 | 0.69 -> 1.98 |
| Cursed | 18.7 -> **17.4** | 5.4 / 8.0 -> **5.6 / 8.5** | Reinforced Icebreaker 660K (0.1 min) | Balanced Engine 450 (0.0 min) | 5.1 -> 4.0 | 0.69 -> 2.0 |
| Crystal | 42.7 -> **41.1** | 23.1 / 35.4 -> **13.4 / 22.6** | Haunted Treads 240M (0.1 min) | Phantom V-Twin 240M (0.2 min) | 8.8 -> 5.5 | 0.69 -> 2.0 |
| Retro | 136.2 -> **87.7** | 10.7 / 15.4 -> **14.0 / 18.3** | 8-Bit Engine 78B (1.0 min) | Cartridge Cruncher 160B (2.6 min) | 6.3 -> 5.2 | 0.69 -> 2.0 |
| Jungle | 165.2 -> **131.6** | 9.3 / 17.1 -> **13.0 / 19.9** | Tiki Thumper 480B (1.2 min) | Totem Torque 1.8T (4.1 min) | 4.5 -> 11.1 | 0.69 -> 2.0 |
| AbsoluteZero | 197.2 -> **176.5** | 11.1 / 16.1 -> **9.9 / 14.8** | Cryo Compressor 5.1T (0.9 min) | Vine Crawler Tracks 4.8T (1.2 min) | 12.3 -> 6.5 | 0.69 -> 2.0 |
| Sakura | 235.5 -> **218.8** | 0.2 / 1.7 -> **0.3 / 0.8** | Vine Crawler Tracks 3.7T (0.0 min) | Polar Sweeper 54T (0.1 min) | 5.6 -> 2.9 | 0.69 -> 2.0 |

## Per stage: noRewards

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 2.4 / 3.6 -> **2.5 / 4.6** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.3 -> 1.8 | 0.69 -> 1.97 |
| Desert | 5.8 -> **5.9** | 3.2 / 5.1 -> **3.4 / 4.9** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.3 -> 1.5 | 0.69 -> 1.98 |
| Cursed | 15.9 -> **16.8** | 5.1 / 6.9 -> **5.3 / 8.0** | Balanced Engine 450 (0.0 min) | Dune Sweeper 1.5K (0.0 min) | 5.3 -> 2.4 | 0.69 -> 2.0 |
| Crystal | 38.1 -> **42.4** | 19.6 / 39.2 -> **18.5 / 33.3** | Reinforced Icebreaker 660K (0.0 min) | Geode Core 330M (0.2 min) | 6.1 -> 6.3 | 0.69 -> 2.0 |
| Retro | 116.7 -> **129.3** | 7.9 / 10.8 -> **7.4 / 14.9** | Prism Cleaver 57B (0.8 min) | Prism Cleaver 40B (0.6 min) | 4.2 -> 2.8 | 0.69 -> 2.0 |
| Jungle | 139.6 -> **157.7** | 8.9 / 14.2 -> **8.6 / 16.0** | Tusk Breaker 3.7T (5.1 min) | Tiki Thumper 660B (1.1 min) | 6.7 -> 3.5 | 0.69 -> 2.0 |
| AbsoluteZero | 165.5 -> **186.0** | 8.3 / 14.5 -> **11.0 / 14.5** | Vine Crawler Tracks 3.7T (1.5 min) | Vine Crawler Tracks 4.8T (0.9 min) | 3.8 -> 2.6 | 0.69 -> 2.0 |
| Sakura | 201.8 -> **227.6** | 0.2 / 0.7 -> **0.2 / 0.6** | Cryo Compressor 5.1T (0.0 min) | Frostbite Cleaver 19T (0.0 min) | 3.5 -> 3.1 | 0.69 -> 2.0 |

## Per stage: world2

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 1.9 / 3.8 -> **1.9 / 3.8** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.3 -> 1.8 | 0.69 -> 1.97 |
| Desert | 5.1 -> **5.1** | 2.6 / 4.6 -> **2.4 / 3.2** | Snowball Motor 300 (0.0 min) | Snowball Motor 300 (0.0 min) | 1.5 -> 1.8 | 0.69 -> 2.0 |
| Cursed | 14.6 -> **14.7** | 4.5 / 7.5 -> **3.4 / 6.0** | Reinforced Icebreaker 660K (0.1 min) | Reinforced Icebreaker 660K (0.1 min) | 6.6 -> 4.3 | 0.69 -> 2.0 |
| Crystal | 35.5 -> **29.2** | 19.7 / 29.5 -> **7.5 / 8.8** | Reinforced Icebreaker 660K (0.0 min) | Haunted Treads 240M (0.2 min) | 6.4 -> 4.7 | 0.69 -> 2.0 |
| Retro | 101.9 -> **56.3** | 7.5 / 9.8 -> **8.1 / 10.9** | Arcade Turbo 350B (3.7 min) | Geode Tracks 40B (0.8 min) | 12.8 -> 4.7 | 0.69 -> 2.0 |
| Jungle | 120.1 -> **86.5** | 7.7 / 10.8 -> **8.2 / 13.1** | Tusk Breaker 3.7T (5.6 min) | Tiki Thumper 660B (2.1 min) | 6.7 -> 5.1 | 0.69 -> 2.0 |
| AbsoluteZero | 149.0 -> **114.5** | 7.3 / 12.0 -> **6.8 / 9.6** | Polar Turbine 130T (14.6 min) | Polar Sweeper 54T (8.4 min) | None -> 6.3 | 0.69 -> 2.0 |
| Sakura | 179.9 -> **143.4** | 12.2 / 18.2 -> **9.6 / 14.2** | Polar Turbine 130T (0.3 min) | Frostbite Cleaver 19T (0.1 min) | 3.6 -> 2.6 | 0.69 -> 2.0 |
| Candy | 217.3 -> **184.5** | 16.5 / 25.5 -> **11.0 / 18.1** | Sugar Rush V8 51Qa (4.9 min) | Absolute Zero Core 33Qa (3.0 min) | 8.3 -> 5.8 | 0.69 -> 2.0 |
| Atlantis | 250.4 -> **214.3** | 13.6 / 24.8 -> **13.7 / 18.7** | Trident Breaker 150Qa (4.7 min) | Toy Bulldozer 1.1Qi (36.1 min) | 9.4 -> None | 0.69 -> 2.0 |
| Toybox | 304.1 -> **253.7** | 18.3 / 30.9 -> **12.5 / 20.8** | Jack-in-the-Box Engine 680Qa (3.0 min) | Toy Bulldozer 1.1Qi (9.3 min) | 7.4 -> 8.5 | 0.69 -> 2.0 |
| Clockwork | 341.2 -> **313.4** | 25.2 / 36.1 -> **25.8 / 41.0** | Gearbreaker 6.4Qi (4.8 min) | Gearbreaker 10Qi (7.3 min) | 3.7 -> 6.2 | 0.69 -> 2.0 |
| Cloud | 404.3 -> **369.8** | 17.7 / 41.8 -> **14.4 / 18.5** | Cumulus Sweeper 8.7Qi (0.7 min) | Cumulus Sweeper 14Qi (1.7 min) | 3.4 -> 15.5 | 0.69 -> 2.0 |
| Cosmic | 451.3 -> **426.8** | 0.1 / 0.9 -> **0.1 / 0.9** | Thunder Wedge 57Qi (0.4 min) | none | 3.4 -> None | 0.69 -> 2.0 |

