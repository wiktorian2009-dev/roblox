# Graph Report - Roblox Gra  (2026-10-07)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1085 nodes · 2227 edges · 73 communities (45 shown, 28 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 112 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46

## God Nodes (most connected - your core abstractions)
1. `ball()` - 31 edges
2. `onAction()` - 25 edges
3. `DataService.Get()` - 23 edges
4. `block()` - 19 edges
5. `cyl()` - 19 edges
6. `mk()` - 17 edges
7. `NumberFormat.Abbreviate()` - 17 edges
8. `refreshGarage()` - 17 edges
9. `ell()` - 16 edges
10. `sound()` - 13 edges

## Surprising Connections (you probably didn't know these)
- `renderAchievements()` --calls--> `A.BonusText()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/ActivityClient.client.luau → src/ReplicatedStorage/ActivityConfig.luau
- `onTileClick()` --calls--> `U.CostOf()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/UpgradeTreeClient.client.luau → src/ReplicatedStorage/UpgradeConfig.luau
- `showTip()` --calls--> `NumberFormat.Abbreviate()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/UpgradeTreeClient.client.luau → src/ReplicatedStorage/NumberFormat.luau
- `renderAchievements()` --calls--> `NumberFormat.Abbreviate()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/ActivityClient.client.luau → src/ReplicatedStorage/NumberFormat.luau
- `renderQuests()` --calls--> `NumberFormat.Abbreviate()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/ActivityClient.client.luau → src/ReplicatedStorage/NumberFormat.luau

## Import Cycles
- None detected.

## Communities (73 total, 28 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.10
Nodes (62): about(), addTele(), anchor(), arrivalFX(), at(), bossPos(), bounce(), breathFX() (+54 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (52): openViaPrevious(), U.Available(), U.Calculate(), U.CostOf(), U.Distance(), U.LockReason(), U.Neighbours(), apply() (+44 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (53): C.LevelBase(), C.LevelCost(), C.LevelOf(), C.LuckFactor(), C.MiniBase(), C.MiniLevel(), C.OfferPool(), C.OfferPrice() (+45 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (48): A.PaintById(), addParticipant(), aliveIn(), applyKnock(), approachSpeed(), arenaData(), broadcast(), checkOut() (+40 more)

### Community 4 - "Community 4"
Cohesion: 0.07
Nodes (27): T.Requirement(), T.Unlocked(), cleanOffer(), Rules.Apply(), currentId(), fail(), handle(), travel() (+19 more)

### Community 5 - "Community 5"
Cohesion: 0.17
Nodes (39): B.bell(), B.bone(), B.button(), B.candle(), B.cartridge(), B.claw(), B.cluster(), B.coin() (+31 more)

### Community 6 - "Community 6"
Cohesion: 0.09
Nodes (27): S.Previous(), equipBest(), hatch(), publish(), rollPet(), scan(), setupEgg(), slotsFor() (+19 more)

### Community 7 - "Community 7"
Cohesion: 0.11
Nodes (31): burst(), close(), dropCounter(), dropRoll(), fitTo(), float(), goBack(), hexShape() (+23 more)

### Community 8 - "Community 8"
Cohesion: 0.10
Nodes (24): PetConfig.BoostOf(), PetConfig.Multiplier(), PetConfig.RefBoost(), upd(), TC.BiomeFor(), collect(), flush(), flushOne() (+16 more)

### Community 9 - "Community 9"
Cohesion: 0.14
Nodes (32): accept(), accessible(), avatarTemplate(), cleanup(), contractHP(), eligible(), expectedJob(), finish() (+24 more)

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (25): A.BonusText(), A.RewardText(), NumberFormat.Abbreviate(), daily(), endEvent(), grant(), newQuests(), nice() (+17 more)

### Community 11 - "Community 11"
Cohesion: 0.11
Nodes (23): afterLoad(), Art.Icon(), Art.Skin(), buildGuidance(), buildTracker(), button(), clearGuidance(), edge() (+15 more)

### Community 12 - "Community 12"
Cohesion: 0.14
Nodes (26): canBuy(), label(), makeSquare(), mk(), openDetails(), opFlair(), placeSquares(), priceText() (+18 more)

### Community 13 - "Community 13"
Cohesion: 0.18
Nodes (24): abilityButton(), ask(), buildExitMarks(), burst(), button(), clearPointers(), corner(), feedLine() (+16 more)

### Community 14 - "Community 14"
Cohesion: 0.13
Nodes (17): C.BandFrom(), actions.Drive(), actions.GoGarage(), actions.GoLobby(), actions.LevelUp(), actions.Recover(), actions.TutorialProgress(), bestScore() (+9 more)

### Community 15 - "Community 15"
Cohesion: 0.23
Nodes (20): actionButton(), bar(), call(), card(), claim(), fetch(), header(), mk() (+12 more)

### Community 16 - "Community 16"
Cohesion: 0.18
Nodes (16): button(), chip(), emptyNote(), frame(), grad(), image(), makePage(), mk() (+8 more)

### Community 17 - "Community 17"
Cohesion: 0.20
Nodes (20): ball(), gem(), line(), M.create(), p(), button(), confetti(), face() (+12 more)

### Community 18 - "Community 18"
Cohesion: 0.12
Nodes (14): afkMove(), ask(), attachFx(), bindCharacter(), camRestore(), clearDrift(), directInput(), draw() (+6 more)

### Community 19 - "Community 19"
Cohesion: 0.19
Nodes (21): billboard(), camPos(), finishAnim(), fitModel(), guide(), label(), myBay(), myBayIndex() (+13 more)

### Community 20 - "Community 20"
Cohesion: 0.17
Nodes (13): estimateRate(), eventDps(), flat(), hdist(), nice(), plowStats(), reach(), realPower() (+5 more)

### Community 21 - "Community 21"
Cohesion: 0.17
Nodes (11): clear(), pose(), refresh(), route(), showButton(), snow(), snowTop(), sync() (+3 more)

### Community 22 - "Community 22"
Cohesion: 0.24
Nodes (14): card(), label(), markSeenSoon(), mk(), newCount(), newIn(), ownedIn(), render() (+6 more)

### Community 23 - "Community 23"
Cohesion: 0.24
Nodes (15): DataService.AddSnow(), DataService.SetStat(), cocoaList(), copies(), craft(), craftList(), drink(), drinkPrice() (+7 more)

### Community 24 - "Community 24"
Cohesion: 0.31
Nodes (14): attach(), buildCard(), button(), hex(), label(), mk(), pct(), petView() (+6 more)

### Community 25 - "Community 25"
Cohesion: 0.21
Nodes (9): added(), addField(), apply(), buildVisual(), getStyle(), heightOf(), lockDown(), tileCenter() (+1 more)

### Community 26 - "Community 26"
Cohesion: 0.24
Nodes (9): DataService.Save(), DataService.SaveNow(), defaults(), inStudio(), kick(), load(), save(), stat() (+1 more)

### Community 27 - "Community 27"
Cohesion: 0.46
Nodes (12): box(), diamond(), ear(), ell(), golden(), M.create(), orb(), orbFace() (+4 more)

### Community 28 - "Community 28"
Cohesion: 0.32
Nodes (11): bounce(), closeAll(), hidePanel(), label(), mk(), partCard(), render(), setBlur() (+3 more)

### Community 29 - "Community 29"
Cohesion: 0.36
Nodes (12): burst(), fxPart(), hue(), lowPriority(), mk(), playSound(), pushReveal(), pushToast() (+4 more)

### Community 30 - "Community 30"
Cohesion: 0.21
Nodes (6): pick(), probe(), resolve(), split(), studioHook(), write()

### Community 31 - "Community 31"
Cohesion: 0.23
Nodes (7): amount(), isAdmin(), onPlayer(), run(), enabledChain(), find(), shown()

### Community 32 - "Community 32"
Cohesion: 0.26
Nodes (7): boosting(), bracing(), myModel(), seated(), serverWindow(), shielded(), useAbility()

### Community 33 - "Community 33"
Cohesion: 0.39
Nodes (11): folder(), K.addColliders(), K.archive(), K.backup(), K.built(), K.collider(), K.footprint(), K.place() (+3 more)

### Community 34 - "Community 34"
Cohesion: 0.24
Nodes (4): blocker(), fieldAt(), inJob(), seatedPlow()

### Community 35 - "Community 35"
Cohesion: 0.25
Nodes (9): PetConfig.RollPet(), DataService.Get(), DataService.LoadedFromStore(), enterOnFoot(), canSell(), grantEgg(), processReceipt(), productFor() (+1 more)

### Community 36 - "Community 36"
Cohesion: 0.33
Nodes (8): A.Icon(), A.IconButton(), A.SkinButton(), A.SkinClose(), A.SkinPanel(), fit(), quiet(), skinLayer()

### Community 37 - "Community 37"
Cohesion: 0.36
Nodes (9): B.Add(), B.Multipliers(), B.Permanent(), B.Personal(), B.Profile(), B.Refresh(), B.Sanitize(), B.SetEvent() (+1 more)

### Community 38 - "Community 38"
Cohesion: 0.35
Nodes (10): hill(), load(), make(), mark(), outline(), round(), snowflake(), step() (+2 more)

### Community 39 - "Community 39"
Cohesion: 0.38
Nodes (9): apply(), M.Attach(), M.Hex(), M.Icon(), M.Skin(), M.SnowBackground(), M.StyleTree(), rootOf() (+1 more)

### Community 40 - "Community 40"
Cohesion: 0.36
Nodes (7): colors(), M.Attach(), M.Burst(), M.MakePreset(), n(), ring(), scaled()

### Community 41 - "Community 41"
Cohesion: 0.52
Nodes (5): checkAll(), checkOwned(), grant(), onFinished(), reapplyUpgrades()

### Community 42 - "Community 42"
Cohesion: 0.53
Nodes (4): setup(), spark(), tween(), value()

### Community 44 - "Community 44"
Cohesion: 0.83
Nodes (3): claim(), setup(), snowFor()

### Community 45 - "Community 45"
Cohesion: 0.83
Nodes (3): mute(), onPlayer(), watch()

## Knowledge Gaps
- **28 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `NumberFormat.Abbreviate()` connect `Community 10` to `Community 1`, `Community 6`, `Community 7`, `Community 44`, `Community 12`, `Community 15`, `Community 22`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `pick()` connect `Community 1` to `Community 36`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `amount()` connect `Community 31` to `Community 2`, `Community 35`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Are the 22 inferred relationships involving `DataService.Get()` (e.g. with `amount()` and `join()`) actually correct?**
  _`DataService.Get()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.10085933966530981 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05480769230769231 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.0745637228979376 - nodes in this community are weakly interconnected._