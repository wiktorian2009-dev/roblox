# World 2 fields fix + Supporter Gift — 2026-10-13, Claude (save points 72-73)

## 1. wiktor's new World 2 snow fields (sp 72, Studio-only)
Cause: the three boxes wiktor placed (two copies of `Candy_1`, one `Clockwork_2`) sat in **Workspace root**, not in
`Workspace.SnowFieldZones`. SnowFields only reads that folder, so in Play they were never fields and stayed as blue boxes.

Fix: moved (not resized, not moved in space) into SnowFieldZones with unique names:
| new name | was | centre | size (tiles) |
|---|---|---|---|
| Candy_3 | Candy_1 (root) | 1926.0, 5, 24.9 | 15 x 14 |
| Candy_4 | Candy_1 (root) | 1926.6, 5, 82.5 | 15 x 14 |
| Clockwork_3 | Clockwork_2 (root) | 2974.6, 7, -74.5 | 19 x 9 |
Each keeps its Stage attribute, so values (TileHP, Snow per layer) come from the stage like the other fields. Attributes
`OrigName` / `AddedBy` on each. Backup copies: `ServerStorage.NewW2FieldsBackup_20261013`.
Undo: move the three back to Workspace and rename them to OrigName.

Tested (Play, BalanceTestMode, temp profile, stage attributes set): all 3 registered in SnowFieldData and rendered
(210 / 210 / 266 tiles); scripted plow drive with a temporary TileHP=2 override on just the new boxes (removed after):
snow went down, Snow paid (Candy_3, Candy_4, Clockwork_3), ability-token intro spawned and was picked up on Candy_3,
AbilityService reports the field as Candy_3. No errors. Not tested: real keyboard drive on a real W2 build, phones.

Noticed, not changed: an enabled default `Workspace.Script` prints "Hello world!" on every start (a second copy of the
placeholder Claude disabled on 2026-10-03). Harmless; delete it if you don't need it.

## 2. Supporter Gift for joining the group (sp 73)
- Group: **10506641** = the group that owns this experience (game.CreatorId, read in Studio). In CommunityRewardConfig.GroupId.
- Like: Roblox has no API to see who liked a game, so step 1 is a reminder only and never gates the claim.
- Prize (once per profile, saved in `d.Community.Claimed`): exclusive **Frosty Pal** pet (Legendary, progress-scaled
  1.15 x the best regular Legendary of the eggs the player unlocked; +22% at the start; Verity pets stay stronger), auto-equipped
  if a slot is free + Snow worth 10 minutes of recent clearing (min 2,500) + **2x Snow for 15 min**. Plays the normal hatch reveal.
- Server: `ServerScriptService.CommunityRewardService` checks membership (GroupService:GetGroupsAsync, not cached, so a player
  who joins mid-session counts; Player:IsInGroup fallback). Refuses when the save did not load (nothing can be claimed on a
  profile that will not save). Saves right after the claim.
- Client: `StarterPlayerScripts.CommunityRewardClient` = purple **FREE PET!** pill under REWARDS/SPIN (hidden until the plow
  tutorial is done, gone after claiming) + small card: prize, 1 like reminder, 2 JOIN (GroupService:PromptJoinAsync), CLAIM.
- Edited: `PetConfig` (new egg entry SupporterGift with Paid = true: never in the world, not Golden-able, not counted for pet
  achievements), `EggModels` (purple reveal egg colours). Backup: `ServerStorage.CommunityRewardBackup_20261013`.
- New: `ReplicatedStorage.CommunityRewardConfig`. All mirrored in game/src.

Tested (Play, BalanceTestMode, temp profile, PC): real group check found wiktor's account in the group and the claim gave the pet,
2.5K Snow, the 2x Snow timer and the Frosty Pal hatch reveal; 2nd claim refused ("already got"), Snow unchanged; spam refused;
non-member (mocked) refused with a message on the card; clicks on the pill / CLAIM by mouse input; card layout checked on a
1920-wide screen (screens/). JOIN: the click called Roblox's join prompt, which my test tools could not see or close, so a real tap
still needs checking. Not tested: phones, a real non-member account, the saved record after a real rejoin.
Undo: delete the 3 new scripts, restore PetConfig/EggModels from the backup (players who claimed keep a pet named Frosty Pal
that no longer exists in PetConfig, so keep the PetConfig entry if anyone claimed).

## Follow-up 2026-10-13: polish + flat +100% Snow
wiktor: "polish the ui and also make pet ad +100% snow". Frosty Pal Boost = 1.0 (flat). CommunityRewardClient v2 (old copy in the backup folder as CommunityRewardClient_v1). Screens: screens/gift_card_v2.jpg. Tested by clicks in Play (BalanceTestMode, temp profile).
