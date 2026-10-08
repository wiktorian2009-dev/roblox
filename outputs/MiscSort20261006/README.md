# Misc upgrades sorted (2026-10-06, Claude)

wiktor: "misc upgrades should be more sorted".

## What changed (ReplicatedStorage.UpgradeConfig, Misc tree only)
- **Only the positions (Q/R) of the 44 Misc tiles changed.** Names, prices, effects, stages and icons are the same, and the upgrade screen looks the same.
- **One wedge per kind off Misc Start.** Each wedge is a two-wide chain with the **cheapest tile next to the centre**, and every tile touches the cheaper one before it, so buying still flows outward (the purchase rule needs an owned neighbour). The wedges:
  - walk speed: 9;
  - pets: 9 pet boosts, 2 pet slots and the Pet Fuser unlock;
  - machines and rewards: Workshop Rewards and the Crafting Machine;
  - friends: 5;
  - eggs: 8;
  - blade reach: 7, World 2.
- **Kinds use the real effects** after the MachineUnlocks overrides: "Pet Care" is really Workshop Rewards, and two tiles are the machine unlocks.
- **Prices can't move.** World 1 prices come from a curve that orders tiles by their ring distance. Every Misc tile keeps its original ring as `PriceRing`, and the curve reads `n.PriceRing or U.Distance(n)`.
- Generator: `misc_sort.py`. It also checks for no overlaps and that all 44 tiles are reachable.

## Tests
- Edit: a fresh copy of the new config vs the saved prices showed 0 differences across all 138 upgrades, with 44/44 Misc tiles reachable.
- Play (runtime): the old (backup) and new configs required side by side gave 0 price differences across all 138.
- Play, with the cheap Misc tiles granted to a test profile (simulated): the MISC board shows the wedges grouped (`screens/misc_sorted.jpg`). The BACK / MISC links work.
- The tutorial's first upgrade lesson uses the Snow tree (Snow Start), which is unchanged.

## Notes
- Old saves keep every upgrade they own (owned is by id). A tile that sits further along a chain than what a player owns needs the cheaper tile before it, as with any new tile.

## Undo
`ServerStorage.MiscSortBackup_20261006.UpgradeConfig` (35641/364755074). Live = disk now: 36622/2024772948.
