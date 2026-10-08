# Egg and pet redesign

Updated the connected Roblox Studio place, money, on September 29, 2026. Not published.

- Rebuilt all 20 pets as rounded toy-style companions with clear faces and species details.
- Replaced the four eggs with matching Snowy, Desert, Cursed and Crystal designs on their existing stands.
- The same pet designs appear in the inventory, following the player, in the egg odds previews and during hatching.
- The egg/chances panel has a transparent outer background. Pet tiles, chance text, discovery silhouettes and the existing layout are preserved. The pet inventory appearance is unchanged.
- Pet names, prices, chances, boosts, saved ownership and progression rules are unchanged.

Verified all 20 models build with centered bounds and no collision. Visually inspected the full set, close-up models, in-game inventory and egg panels. An isolated play test confirmed three followers, all four signs with five previews each, and a real Snowy Egg hatch: 450 Snow deducted, one pet awarded, animation completed. Existing saved progress was not used or reset. Temporary test helpers were removed and Studio was returned to Edit mode.

Original egg models and modified scripts are retained in ServerStorage > PetArtBackup_20260929. Each egg has an OriginalParent reference to its original stand folder. The source backup is also in Pet-redesign-source-backup.json. The added ReplicatedStorage.EggModels module supplies both world and hatch egg visuals.
