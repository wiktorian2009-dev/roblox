# Rebalance 2026-10-05: before vs after (simulation)

Model estimates from outputs/Rebalance20261005/sim (40 seeds per World 1 behaviour, 20 for World 2), not human playtests.
Value buyer = buys the best income gain per Snow and saves for clearly better items; legacy = the old egg-first spender.
'Gap' = minutes between purchases that raise income by >= 10%; 'unavailable' = longest stretch without an obtainable,
affordable (within 10 min of income) part or upgrade.

## Summary per behaviour

| Behaviour | W1 min before -> after (median, P90) | Longest gap per player med/P90 | Unavailable P90 | First part min | Parts bought W1 | Job pay vs collecting |
|---|---|---|---|---|---|---|
| efficient | 141 / 158 -> **139 / 153** | 13.0 / 19.1 -> **11.8 / 14.1** | 2.9 -> **3.6** | 2.2 -> **2.0** | 31.0 -> **27.5** | 2.0 -> **2.0** |
| casual | 217 / 242 -> **213 / 234** | 21.1 / 29.2 -> **15.6 / 23.6** | 6.7 -> **11.6** | 9.1 -> **8.9** | 27.0 -> **26.0** | 2.0 -> **2.0** |
| noRewards | 224 / 248 -> **211 / 232** | 19.4 / 33.8 -> **15.2 / 20.3** | 1.9 -> **9.5** | 2.0 -> **2.0** | 32.0 -> **31.0** | 0 -> **0** |
| jobs | 140 / 151 -> **139 / 152** | 13.0 / 19.8 -> **11.0 / 14.1** | 3.0 -> **2.9** | 2.2 -> **2.0** | 30.0 -> **27.5** | 2.0 -> **2.0** |
| unlucky | 191 / 209 -> **213 / 234** | 17.0 / 25.6 -> **23.5 / 38.5** | 8.2 -> **4.4** | 2.1 -> **2.1** | 38.0 -> **31.0** | 2.0 -> **2.0** |
| lucky | 126 / 138 -> **125 / 146** | 11.7 / 17.2 -> **10.5 / 16.6** | 2.6 -> **3.0** | 2.1 -> **6.1** | 24.5 -> **25.0** | 2.0 -> **2.0** |
| boosted | 95 / 105 -> **85 / 96** | 9.1 / 12.4 -> **8.2 / 10.1** | 2.9 -> **2.9** | 2.3 -> **2.1** | 26.0 -> **23.0** | 2.0 -> **2.0** |
| legacy:efficient | 235 / 265 -> **205 / 227** | 40.0 / 53.0 -> **30.6 / 44.2** | 4.3 -> **9.8** | 2.0 -> **7.6** | 31.5 -> **33.0** | 2.0 -> **2.0** |
| legacy:casual | 379 / 428 -> **291 / 307** | 56.7 / 77.9 -> **40.5 / 54.6** | 11.8 -> **22.3** | 2.0 -> **1.9** | 28.0 -> **28.5** | 2.0 -> **2.0** |
| legacy:noRewards | 331 / 383 -> **310 / 367** | 58.0 / 78.3 -> **42.9 / 55.9** | 4.7 -> **17.6** | 2.0 -> **1.9** | 32.0 -> **34.0** | 0 -> **0** |

World 2 (Sakura -> Cosmic, value buyer): 297 min median (P90 330) -> **266 min (P90 289)**. Rebirth World 1 replay: 5.3 -> **5.3** min.

## Offers (value buyer, efficient)

| | Before | After |
|---|---|---|
| usefulShare | 0.429 | 0.385 |
| affordableUsefulShare | 0.22 | 0.26 |
| duplicateShare | 0.253 | 0.244 |
| longest dry streak (max) | 6 | 6 |
| slot share | {'Engine': 0.3, 'Gear': 0.291, 'Blade': 0.291, 'Body': 0.119} | {'Gear': 0.294, 'Engine': 0.294, 'Blade': 0.297, 'Body': 0.114} |

## Per stage: efficient

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 1.6 / 3.8 -> **1.2 / 2.6** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.9 -> 1.7 | 1.97 -> 1.97 |
| Desert | 4.7 -> **4.6** | 2.4 / 3.3 -> **2.1 / 3.6** | Snowball Motor 300 (0.0 min) | Balanced Engine 450 (0.0 min) | 1.8 -> 2.1 | 2.0 -> 2.0 |
| Cursed | 13.4 -> **13.9** | 3.6 / 5.3 -> **3.7 / 5.2** | Reinforced Icebreaker 670K (0.2 min) | Tracked Treads 650 (0.0 min) | 3.3 -> 2.9 | 2.0 -> 2.0 |
| Crystal | 28.5 -> **28.9** | 8.0 / 10.9 -> **7.5 / 9.1** | Grave Rollers 15M (0.0 min) | Hex Breaker 6.8M (0.2 min) | 4.1 -> 3.3 | 2.0 -> 2.0 |
| Retro | 55.9 -> **61.0** | 8.2 / 10.8 -> **6.0 / 9.1** | Geode Tracks 42B (0.7 min) | Geode Tracks 170M (1.6 min) | 4.7 -> 5.1 | 2.0 -> 2.0 |
| Jungle | 88.0 -> **86.0** | 8.1 / 10.7 -> **6.2 / 9.0** | Arcade Plow 520B (1.3 min) | Jungle Turbine 3.1B (3.2 min) | 6.8 -> 8.8 | 2.0 -> 2.0 |
| AbsoluteZero | 115.8 -> **110.8** | 6.1 / 8.0 -> **7.0 / 10.9** | Cryo Compressor 7.3T (1.6 min) | Jungle Turbine 3.1B (1.1 min) | 14.6 -> 3.6 | 2.0 -> 2.0 |
| Sakura | 141.6 -> **139.9** | 0.5 / 0.8 -> **0.5 / 1.0** | Cryo Compressor 7.3T (0.0 min) | Cryo Compressor 4.2B (0.1 min) | 2.2 -> 3.2 | 2.0 -> 2.0 |

## Per stage: casual

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 3.1 / 4.5 -> **2.2 / 3.2** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.9 -> 1.7 | 1.97 -> 1.97 |
| Desert | 7.2 -> **7.5** | 4.1 / 6.3 -> **3.1 / 6.0** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.6 -> 1.7 | 1.98 -> 1.98 |
| Cursed | 18.7 -> **20.6** | 5.1 / 7.8 -> **5.2 / 7.8** | Tracked Treads 650 (0.0 min) | Balanced Engine 450 (0.0 min) | 2.9 -> 1.9 | 2.0 -> 2.0 |
| Crystal | 39.8 -> **43.7** | 14.3 / 23.0 -> **10.5 / 15.7** | Hex Breaker 250M (0.1 min) | Lantern Motor 160K (0.0 min) | 4.0 -> 2.7 | 2.0 -> 2.0 |
| Retro | 86.6 -> **89.6** | 12.1 / 16.7 -> **10.8 / 14.7** | Geode Tracks 42B (0.6 min) | Hex Breaker 6.8M (0.1 min) | 3.1 -> 4.7 | 2.0 -> 2.0 |
| Jungle | 131.4 -> **130.2** | 11.9 / 20.4 -> **9.9 / 14.9** | Totem Torque 1.9T (3.6 min) | Arcade Hover Pods 880M (1.1 min) | 7.8 -> 4.0 | 2.0 -> 2.0 |
| AbsoluteZero | 173.3 -> **176.3** | 10.2 / 17.7 -> **8.1 / 12.3** | Root Crawlers 1.9T (0.5 min) | Polar Sweeper 13B (5.1 min) | 6.3 -> 6.9 | 2.0 -> 2.0 |
| Sakura | 217.3 -> **213.4** | 0.3 / 0.8 -> **0.1 / 0.8** | Polar Sweeper 60T (0.2 min) | Polar Sweeper 13B (0.5 min) | 2.8 -> 2.4 | 2.0 -> 2.0 |

## Per stage: noRewards

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 2.4 / 4.1 -> **1.6 / 4.2** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.9 -> 1.7 | 1.97 -> 1.97 |
| Desert | 6.0 -> **7.1** | 3.4 / 5.1 -> **3.1 / 4.4** | Snowball Motor 300 (0.0 min) | Snowball Motor 300 (0.0 min) | 1.8 -> 2.1 | 2.0 -> 2.0 |
| Cursed | 16.5 -> **19.4** | 5.3 / 8.5 -> **5.1 / 6.6** | Reinforced Icebreaker 670K (0.0 min) | Dune Sweeper 1.5K (0.0 min) | 2.9 -> 1.8 | 2.0 -> 2.0 |
| Crystal | 42.3 -> **48.2** | 17.0 / 33.8 -> **9.9 / 13.0** | Amethyst Wedge 8.5B (2.3 min) | Haunted Treads 6.8M (0.2 min) | 5.9 -> 2.8 | 2.0 -> 2.0 |
| Retro | 117.2 -> **93.3** | 8.4 / 15.3 -> **10.2 / 12.3** | Quartz Piston 8.5B (0.1 min) | Polar Titan 34M (0.1 min) | 3.2 -> 5.0 | 2.0 -> 2.0 |
| Jungle | 147.5 -> **129.9** | 9.6 / 17.8 -> **9.2 / 12.6** | Jungle Turbine 5.3T (5.4 min) | Jungle Turbine 3.1B (3.5 min) | 7.2 -> 8.8 | 2.0 -> 2.0 |
| AbsoluteZero | 181.0 -> **170.5** | 10.2 / 15.2 -> **9.9 / 15.5** | Vine Crawler Tracks 5.3T (1.5 min) | Polar Sweeper 13B (1.9 min) | 5.4 -> 5.0 | 2.0 -> 2.0 |
| Sakura | 224.7 -> **211.6** | 0.2 / 0.3 -> **0.1 / 0.8** | Frostbite Cleaver 21T (0.0 min) | Polar Turbine 24B (0.7 min) | 2.2 -> 3.3 | 2.0 -> 2.0 |

## Per stage: world2

| Stage | Arrive med (before -> after) | Longest gap in stage med/P90 (before -> after) | Cheapest +10%% part at entry: before | after | Rolls to affordable useful offer (b -> a) | Job vs collecting (b -> a) |
|---|---|---|---|---|---|---|
| Starter | 0.0 -> **0.0** | 2.2 / 3.8 -> **1.3 / 1.9** | Wide Clearing Blade 120 (0.0 min) | Wide Clearing Blade 120 (0.0 min) | 1.9 -> 1.7 | 1.97 -> 1.97 |
| Desert | 5.4 -> **4.0** | 2.5 / 3.1 -> **2.7 / 5.1** | Snowball Motor 300 (0.0 min) | Tracked Treads 650 (0.0 min) | 1.8 -> 2.5 | 2.0 -> 2.0 |
| Cursed | 15.1 -> **14.0** | 3.3 / 5.0 -> **3.3 / 4.8** | Reinforced Icebreaker 670K (0.1 min) | Balanced Engine 450 (0.0 min) | 4.0 -> 2.1 | 2.0 -> 2.0 |
| Crystal | 29.6 -> **24.9** | 7.9 / 12.8 -> **7.1 / 13.3** | Hex Breaker 250M (0.5 min) | Reinforced Icebreaker 18K (0.0 min) | 9.1 -> 2.2 | 2.0 -> 2.0 |
| Retro | 55.4 -> **63.1** | 8.2 / 9.7 -> **7.0 / 8.8** | Prism Cleaver 42B (1.1 min) | Joystick Sweeper 450M (1.7 min) | 5.3 -> 4.4 | 2.0 -> 2.0 |
| Jungle | 86.9 -> **90.6** | 8.4 / 13.2 -> **6.6 / 8.7** | Totem Torque 1.9T (3.9 min) | Vine Crawler Tracks 3.1B (4.0 min) | 14.2 -> 11.8 | 2.0 -> 2.0 |
| AbsoluteZero | 112.8 -> **112.3** | 7.1 / 10.4 -> **6.3 / 11.1** | Polar Sweeper 60T (9.7 min) | Jungle Turbine 3.1B (0.5 min) | 4.3 -> 3.2 | 2.0 -> 2.0 |
| Sakura | 143.7 -> **141.9** | 11.8 / 16.5 -> **9.5 / 13.8** | Frost Piston 21T (0.1 min) | Polar Sweeper 13B (0.3 min) | 2.7 -> 3.3 | 2.0 -> 2.0 |
| Candy | 185.4 -> **181.5** | 11.9 / 21.9 -> **7.1 / 12.1** | Blossom Turbine 15Qa (1.2 min) | Gumdrop Sweeper 340B (2.0 min) | 4.7 -> 3.7 | 2.0 -> 2.0 |
| Atlantis | 213.9 -> **210.6** | 15.7 / 23.6 -> **14.4 / 17.4** | Toy Bulldozer 1.3Qi (30.9 min) | Building Block Blade 2T (5.5 min) | 79.1 -> 33.0 | 2.0 -> 2.0 |
| Toybox | 262.9 -> **247.3** | 13.4 / 25.6 -> **15.5 / 22.9** | Toy Bulldozer 1.3Qi (9.0 min) | Toy Tank Tracks 3.7T (5.3 min) | 9.2 -> 16.1 | 2.0 -> 2.0 |
| Clockwork | 316.7 -> **314.9** | 16.9 / 32.8 -> **7.7 / 11.4** | Gearbreaker 12Qi (8.5 min) | Gearbreaker 11T (3.3 min) | 6.0 -> 8.5 | 2.0 -> 2.0 |
| Cloud | 358.8 -> **343.8** | 14.7 / 24.0 -> **12.5 / 16.4** | Cumulus Sweeper 17Qi (1.8 min) | Storm Engine 73T (9.8 min) | 9.0 -> 7.8 | 2.0 -> 2.0 |
| Cosmic | 434.9 -> **409.9** | 0.1 / 0.9 -> **0.1 / 1.1** | none | none | None -> None | 2.0 -> 2.0 |

