# Graph Report - Roblox Gra  (2026-10-14)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1388 nodes · 2883 edges · 93 communities (53 shown, 40 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 154 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `284dcb04`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56

## God Nodes (most connected - your core abstractions)
1. `ball()` - 31 edges
2. `DataService.Get()` - 30 edges
3. `onAction()` - 25 edges
4. `refreshGarage()` - 20 edges
5. `NumberFormat.Abbreviate()` - 19 edges
6. `block()` - 19 edges
7. `cyl()` - 19 edges
8. `mk()` - 18 edges
9. `hatchSequence()` - 18 edges
10. `ell()` - 16 edges

## Surprising Connections (you probably didn't know these)
- `renderAchievements()` --calls--> `A.BonusText()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/ActivityClient.client.luau → src/ReplicatedStorage/ActivityConfig.luau
- `pct()` --calls--> `NumberFormat.Abbreviate()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/MachinesClient.client.luau → src/ReplicatedStorage/NumberFormat.luau
- `showToast()` --calls--> `NumberFormat.Abbreviate()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/TreasureReveal.client.luau → src/ReplicatedStorage/NumberFormat.luau
- `onTileClick()` --calls--> `NumberFormat.Abbreviate()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/UpgradeTreeClient.client.luau → src/ReplicatedStorage/NumberFormat.luau
- `showTip()` --calls--> `NumberFormat.Abbreviate()`  [INFERRED]
  studio-snapshots/StarterGui/RNGGui/UpgradeTreeClient.client.luau → src/ReplicatedStorage/NumberFormat.luau

## Import Cycles
- None detected.

## Communities (93 total, 40 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.08
Nodes (77): shown(), UILayout.jumpLeftTop(), UILayout.openMenu(), UILayout.rectIn(), UILayout.touchColLeft(), UILayout.touchColW(), viewport(), about() (+69 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (65): C.LevelBase(), C.LevelCost(), C.LevelOf(), C.LuckFactor(), C.MiniBase(), C.MiniLevel(), C.OfferPool(), C.OfferPrice() (+57 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (55): UILayout.isTouch(), openViaPrevious(), U.Available(), U.LockReason(), U.Neighbours(), arrowShape(), call(), cardButton() (+47 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (48): A.PaintById(), addParticipant(), aliveIn(), applyKnock(), approachSpeed(), arenaData(), broadcast(), checkOut() (+40 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (36): amount(), isAdmin(), onPlayer(), run(), equipBest(), hatch(), publish(), rollPet() (+28 more)

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (35): PetConfig.BoostOf(), PetConfig.Multiplier(), PetConfig.RefBoost(), upd(), A.Icon(), A.IconButton(), A.SkinButton(), A.SkinClose() (+27 more)

### Community 6 - "Community 6"
Cohesion: 0.11
Nodes (41): Anim:Abort(), Anim:Bob(), Anim:Cleanup(), Anim:Finish(), Anim:Handoff(), Anim:Hit(), Anim:NextPreview(), Anim:Now() (+33 more)

### Community 7 - "Community 7"
Cohesion: 0.10
Nodes (38): hill(), load(), make(), mark(), outline(), round(), snowflake(), step() (+30 more)

### Community 8 - "Community 8"
Cohesion: 0.09
Nodes (31): afterLoad(), Art.Icon(), Art.Skin(), buildGuidance(), buildTracker(), button(), clearGuidance(), edge() (+23 more)

### Community 9 - "Community 9"
Cohesion: 0.17
Nodes (39): B.bell(), B.bone(), B.button(), B.candle(), B.cartridge(), B.claw(), B.cluster(), B.coin() (+31 more)

### Community 10 - "Community 10"
Cohesion: 0.10
Nodes (34): U.CostOf(), U.Distance(), burst(), close(), dropCounter(), dropRoll(), fitTo(), float() (+26 more)

### Community 11 - "Community 11"
Cohesion: 0.10
Nodes (27): A.BonusText(), A.RewardText(), L.FormatTime(), NumberFormat.Abbreviate(), daily(), endEvent(), grant(), newQuests() (+19 more)

### Community 12 - "Community 12"
Cohesion: 0.18
Nodes (29): actionButton(), bar(), call(), card(), claim(), dayCard(), dayTile(), deep() (+21 more)

### Community 13 - "Community 13"
Cohesion: 0.14
Nodes (32): accept(), accessible(), avatarTemplate(), cleanup(), contractHP(), eligible(), expectedJob(), finish() (+24 more)

### Community 14 - "Community 14"
Cohesion: 0.14
Nodes (29): billboard(), camPos(), cleanupBay(), closeInspect(), finishAnim(), fitModel(), fitPanel(), garageWindowOpen() (+21 more)

### Community 15 - "Community 15"
Cohesion: 0.16
Nodes (27): abilityButton(), ask(), buildExitMarks(), burst(), button(), clearPointers(), corner(), feedLine() (+19 more)

### Community 16 - "Community 16"
Cohesion: 0.11
Nodes (20): apply(), M.Attach(), M.Hex(), M.Icon(), M.Skin(), M.SnowBackground(), M.StyleTree(), rootOf() (+12 more)

### Community 17 - "Community 17"
Cohesion: 0.15
Nodes (24): activate(), active(), bodies(), clearAll(), clearTokens(), consume(), fieldAt(), hookCharacter() (+16 more)

### Community 18 - "Community 18"
Cohesion: 0.12
Nodes (20): C.BandFrom(), actions.Drive(), actions.GoGarage(), actions.GoLobby(), actions.LevelUp(), actions.Recover(), actions.TutorialProgress(), bayArrival() (+12 more)

### Community 19 - "Community 19"
Cohesion: 0.11
Nodes (18): afkMove(), ask(), attachFx(), bindCharacter(), camRestore(), clearDrift(), directInput(), draw() (+10 more)

### Community 20 - "Community 20"
Cohesion: 0.17
Nodes (17): button(), chip(), emptyNote(), frame(), grad(), image(), makePage(), mk() (+9 more)

### Community 21 - "Community 21"
Cohesion: 0.16
Nodes (19): S.Previous(), T.Requirement(), T.Unlocked(), addPrompt(), isOpen(), publish(), travel(), watch() (+11 more)

### Community 22 - "Community 22"
Cohesion: 0.20
Nodes (20): ball(), gem(), line(), M.create(), p(), button(), confetti(), face() (+12 more)

### Community 23 - "Community 23"
Cohesion: 0.19
Nodes (20): attach(), buildCard(), button(), hex(), hideEgg(), label(), menusOpen(), mk() (+12 more)

### Community 24 - "Community 24"
Cohesion: 0.20
Nodes (21): attachTo(), iconImage(), iconInto(), intro(), makeToken(), mk(), now(), playKind() (+13 more)

### Community 25 - "Community 25"
Cohesion: 0.19
Nodes (20): apply(), boostText(), button(), glow(), isFavorited(), label(), markFaved(), mk() (+12 more)

### Community 26 - "Community 26"
Cohesion: 0.22
Nodes (16): canBuy(), label(), layoutRows(), lookup(), makeSquare(), mk(), openDetails(), opFlair() (+8 more)

### Community 27 - "Community 27"
Cohesion: 0.21
Nodes (17): card(), fitTabNames(), label(), markSeenSoon(), mk(), newCount(), newIn(), nodecor() (+9 more)

### Community 28 - "Community 28"
Cohesion: 0.17
Nodes (13): estimateRate(), eventDps(), flat(), hdist(), nice(), plowStats(), reach(), realPower() (+5 more)

### Community 29 - "Community 29"
Cohesion: 0.24
Nodes (15): DataService.AddSnow(), DataService.SetStat(), cocoaList(), copies(), craft(), craftList(), drink(), drinkPrice() (+7 more)

### Community 30 - "Community 30"
Cohesion: 0.25
Nodes (12): L.Decode(), L.Encode(), DataService.Get(), budget(), canPublish(), countPlaytime(), playerLoop(), publish() (+4 more)

### Community 31 - "Community 31"
Cohesion: 0.32
Nodes (13): burst(), fxPart(), hue(), lowPriority(), mk(), playSound(), pushReveal(), pushToast() (+5 more)

### Community 32 - "Community 32"
Cohesion: 0.24
Nodes (9): DataService.Save(), DataService.SaveNow(), defaults(), inStudio(), kick(), load(), save(), stat() (+1 more)

### Community 33 - "Community 33"
Cohesion: 0.46
Nodes (12): box(), diamond(), ear(), ell(), golden(), M.create(), orb(), orbFace() (+4 more)

### Community 34 - "Community 34"
Cohesion: 0.29
Nodes (10): B.Add(), B.Multipliers(), B.Permanent(), B.Personal(), B.Profile(), B.Refresh(), B.Sanitize(), B.SetEvent() (+2 more)

### Community 35 - "Community 35"
Cohesion: 0.32
Nodes (11): bounce(), closeAll(), hidePanel(), label(), mk(), partCard(), render(), setBlur() (+3 more)

### Community 36 - "Community 36"
Cohesion: 0.21
Nodes (5): findStart(), storedStart(), claim(), setup(), snowFor()

### Community 37 - "Community 37"
Cohesion: 0.21
Nodes (6): pick(), probe(), resolve(), split(), studioHook(), write()

### Community 38 - "Community 38"
Cohesion: 0.26
Nodes (7): boosting(), bracing(), myModel(), seated(), serverWindow(), shielded(), useAbility()

### Community 39 - "Community 39"
Cohesion: 0.39
Nodes (11): folder(), K.addColliders(), K.archive(), K.backup(), K.built(), K.collider(), K.footprint(), K.place() (+3 more)

### Community 40 - "Community 40"
Cohesion: 0.25
Nodes (6): cleanOffer(), Rules.Apply(), currentId(), fail(), handle(), travel()

### Community 41 - "Community 41"
Cohesion: 0.36
Nodes (7): drawMeter(), on(), place(), refresh(), showButton(), stop(), watchBar()

### Community 42 - "Community 42"
Cohesion: 0.31
Nodes (7): PetConfig.RollPet(), DataService.LoadedFromStore(), canSell(), grantEgg(), processReceipt(), productFor(), save()

### Community 43 - "Community 43"
Cohesion: 0.36
Nodes (7): colors(), M.Attach(), M.Burst(), M.MakePreset(), n(), ring(), scaled()

### Community 44 - "Community 44"
Cohesion: 0.36
Nodes (7): check(), nice(), prizeInfo(), prizes(), publish(), snowFor(), wheelOf()

### Community 45 - "Community 45"
Cohesion: 0.36
Nodes (7): colors(), M.Attach(), M.Burst(), M.MakePreset(), n(), ring(), scaled()

### Community 46 - "Community 46"
Cohesion: 0.36
Nodes (5): digBurst(), hrpPart(), mk(), setMaxFx(), sound()

### Community 47 - "Community 47"
Cohesion: 0.67
Nodes (6): claim(), groupId(), isMember(), record(), snowAmount(), state()

### Community 48 - "Community 48"
Cohesion: 0.52
Nodes (5): checkAll(), checkOwned(), grant(), onFinished(), reapplyUpgrades()

### Community 49 - "Community 49"
Cohesion: 0.53
Nodes (4): blocker(), fieldAt(), inJob(), seatedPlow()

### Community 51 - "Community 51"
Cohesion: 0.53
Nodes (4): setup(), spark(), tween(), value()

### Community 52 - "Community 52"
Cohesion: 0.60
Nodes (4): U.Calculate(), apply(), owned(), recountFriends()

### Community 55 - "Community 55"
Cohesion: 0.83
Nodes (3): mute(), onPlayer(), watch()

## Knowledge Gaps
- **40 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `NumberFormat.Abbreviate()` connect `Community 11` to `Community 4`, `Community 36`, `Community 7`, `Community 10`, `Community 12`, `Community 44`, `Community 47`, `Community 20`, `Community 27`, `Community 31`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **Are the 29 inferred relationships involving `DataService.Get()` (e.g. with `M.TileCleared()` and `amount()`) actually correct?**
  _`DataService.Get()` has 29 INFERRED edges - model-reasoned connections that need verification._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.07708521529659741 - nodes in this community are weakly interconnected._
- **Why does `DataService.Get()` connect `Community 30` to `Community 32`, `Community 1`, `Community 34`, `Community 3`, `Community 4`, `Community 5`, `Community 36`, `Community 40`, `Community 42`, `Community 44`, `Community 13`, `Community 47`, `Community 48`, `Community 17`, `Community 18`, `Community 52`, `Community 21`, `Community 28`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06368011847463902 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05413469735720375 - nodes in this community are weakly interconnected._
- **Should `Community 3` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._