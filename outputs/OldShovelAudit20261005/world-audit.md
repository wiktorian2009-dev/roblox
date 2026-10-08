# World / combat / machines read-only audit

2026-10-05. Evidence: fresh parent-captured Server sources in sources-0/1/2.json during the user's Play session, canonical PROJECT.md/STATUS.md, Graphify navigation, and parent runtime object inventory. No Studio queries, edits, Play control, persistence checks or publishing by this subtask. All line numbers below refer to each captured source's `source` text, not JSON line numbers.

## P1: Frost King still fights with hidden legacy shovels

- ReplicatedStorage.FrostKingConfig L4-6: Enabled=true, scheduled every 25-40 minutes with MinPlayers=1. This is active content, not archived source.
- ServerScriptService.FrostKingService L46-61: realPower reads EquippedShovels, RNGConfig.ByName and PowerBonus/PowerMult; eventDps returns zero when no shovel is equipped. L64-71: reach still uses orbit radius, ReachMult/SizeMult and Giant item Size. There is no PlowConfig/PlowRegistry branch.
- Same source L571-573: damage is awarded continuously merely by player distance <= Boss.Radius + legacy reach. It never checks vehicle/blade contact, driving or plow power. The current player's hidden Tin Shovel (confirmed by parent runtime capture) therefore still attacks the boss on foot despite the retired orbit graphics. Improving blade/engine/running gear does not improve the event. Players retaining stronger shovels keep an unrelated combat advantage. Removing EquippedShovels before conversion would leave zero-DPS participants unable to reach MinHitSeconds (qualifies L192; FrostKingConfig L42).
- Same source L87-112: rewardRate clamps measured recent income to an estimate made from shovel power, old orbit area/revolution speed and field HP. The reward anchor is unrelated to current equipped plow clearing power/width, even though Activity.Rate now includes vehicle digging. FrostKingConfig L46 sets RateClamp={0.3,3}. The direction and magnitude of the payout distortion depend on the legacy profile and modifiers; no event was newly played during this audit.
- Existing HUD/client's RNGConfig dependency alone is harmless shared sounds: FrostKingClient L241. Actual client mechanics remain on-foot (L889 pushes HumanoidRootPart; hint L125 and jump telegraph checks), rather than a plow combat interaction.

## P2: Forge is still a purchasable shovel-only machine

- Parent runtime inventory confirms Workspace.FrostfallVillage.ShovelForge exists and its billboards still say SHOVEL FORGE.
- ReplicatedStorage.UpgradeConfig L240-245: M_Pet1 is Shovel Forge, Cost=3000, Effect UnlockForge. It remains an ordinary machine unlock.
- ServerScriptService.MachineService L39-71: lists RNGConfig base/mutation recipes from d.Counts, preserves equipped/last copies, consumes legacy shovel Counts and grants a mutation. No Plow.Parts/Build or mode check. L231-240 gates only UnlockForge.
- ReplicatedStorage.MachineConfig L5-10: recipes are 5 normal -> Giant, 10 normal -> Shiny, 10 Giant / 5 Shiny -> Shiny Giant.
- StarterGui.RNGGui.MachinesClient L160-187: still says SHOVEL FORGE / melt spare shovels, and its empty message is "Roll more shovels". L361-367 opens the machine based only on unlock attribute. The new garage pedestal rolls provide parts, not spare shovels. A fresh profile can buy a 3,000 Snow unlock that cannot progress its vehicle; existing profiles can still consume retained shovel copies. Current event coupling means those items are not completely inert, but this feature is inconsistent with the accepted snowplow loop.

## P2 / pre-existing unfinished content: Crafting unlock opens no production recipes

- Parent runtime inventory confirms Workspace.FrostfallVillage.CraftingMachine exists.
- ReplicatedStorage.UpgradeConfig L243: Crafting Machine unlock Cost=1000000.
- ReplicatedStorage.CraftingConfig L12-16 contains only one Enabled=false, TestOnly=true example boost recipe. MachineService L147-149 exposes it only when BalanceTestMode=true; L163-176 yields an empty normal recipe list.
- MachinesClient L275, L287-291: the unlocked panel explicitly shows "New recipes are coming soon". This is a prior placeholder, not proof of a newly broken conversion. It is nevertheless a spending trap in the current progression if advertised as a useful unlock.
- MachineService L154-160, L198-212 still recognizes Shovel rewards but has no PlowPart reward type; no active production recipe presently hits this obsolete branch. Preserve as Legacy/future design code until a real replacement is chosen.

## Converted/shared paths that are not bugs

- ServerScriptService.SnowFieldService L125-201 validates registered active vehicle, driver seat, rider gap, movement speed, unlocked stage, blade stats and tile contact, then pays/rolls treasure from the shared field path. L205 immediately returns to collectPlow when Mode=Snowplow; old armPowers/shovel sweeping L89-104 and L210 onward cannot also run. No double digging path found.
- SnowFieldService L110-123 emits the existing SnowCollected payload (gained, combo, layers, multiplier). DigJuiceClient L98-129 consumes those generic values. Its RNGConfig import is only reused milestone sounds (L53-55), not digging power. HRP-centered effects (L61-75) are cosmetic alignment/design work, not a progression bug.
- World2Activities L33-39 computes fixed tile-equivalent rewards from stage SnowPerPhase/TileScale, pets and SnowMult; L42-67 validates stage, distance and saved cooldown. These contain no old shovel power/roll dependency. The "old-tile units" comment L35 deliberately preserves reward scale after tile resizing.
- Cocoa pricing is based on recent digging income (MachineService L74-94 / MachineConfig L11-19), and pet fusion uses pet copies; both still work with shared vehicle income/pets.
- FrostfallClient L77-78 forwards generic menu interactions. It does not contain a legacy shovel roll action. Decorative snowglobe shovels and recoverable archived models are design/cleanup decisions, not gameplay failures merely because their names mention shovels.

## Integration risk requiring a separate isolated runtime check

FrostKingService Join L674-680 and knockout teleport L261-268 PivotTo only the character, without unseating/despawning a live plow. FrostKingClient L889 applies pushes to HRP, and server Stomp logic L304 / L425-443 assumes jumping characters. By contrast, PlowService garage travel explicitly despawns/unsits L307-309. A seated character's vehicle weld may carry the plow during teleports, and jump/knockback behavior may differ. No JOIN-while-driving failure was confirmed here; this should be tested or integrated deliberately when converting Frost King.
