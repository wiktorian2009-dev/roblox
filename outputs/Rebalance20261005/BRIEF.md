# Task 4 brief (relayed 2026-10-05 10:16, wiktor's message verbatim inside)

<relay from="coordinator" session="session_01Qww9bMYTbjvnRU8NiLs4wP" current-time="2026-10-05T10:16:47Z">
  The note below was written by the coordinator session, a Claude session, not by your user.
  <note>
      QUEUED FOURTH TASK from wiktor. They wrote it in the project chat at 10:15, so you didn't receive it. Their full message is quoted verbatim below. It's an economy rebalance plus 45 new parts.
      
      ORDER:
      1) The Snowplow Bumper Arena you are building now.
      2) The World 1 remaster.
      3) This rebalance and catalog expansion.
      Start it only after the remaster is finished, tested and reported to me. One writer for the game at a time.
      
      When you start it, re-read the live catalog and the economy scripts first. By then they will include the arena's separate config and any remaster changes, so reconcile with those and don't overwrite them. The 90-part catalog and the contract bonus (about 30 s of income, fixed when the job is offered) are from earlier today.
      
      wiktor is away on their phone, so keep going without waiting for them. I'll relay anything they answer. Same rules as before:
      - Don't publish.
      - Remind me (not wiktor) when a Ctrl+S matters.
      - Keep simulated results clearly separate from real tests.
      
      wiktor's message, verbatim:
      """
      Rebalance my Roblox snowplow game and expand the part catalog.
      
      The current progression has enormous price jumps. My screenshot shows examples like:
      - Dune Sweeper: 1.5K Snow → Reinforced Icebreaker: 660K.
      - Grave Digger: 900K → Hex Breaker: 240M.
      - Quartz Edge: 330M → Prism Cleaver: 57B.
      
      Players need a smoother progression with useful purchases between these milestones. I want a stable economy, regular improvements and exciting rare rolls without huge stretches of repetitive collecting.
      
      IMPLEMENT this in the game. Add 15 MORE parts of EACH type:
      - 15 new blades.
      - 15 new engines.
      - 15 new running-gear parts: wheels, tracks, skis or hover systems.
      
      The expected current catalog is 30 per type / 90 total. The completed catalog should contain 45 per type / 135 total. Verify the live catalog first and reconcile any newer work without overwriting it.
      
      Make the new models in Blender and import them using the established pipeline.
      
      Work through the complete implementation, balancing and verification. Resolve routine decisions yourself.
      
      1. READ AND VERIFY THE CURRENT PROJECT
      
      Canonical folder:
      C:\Users\wikto\Desktop\Roblox Gra
      
      Read AGENTS.md, PROJECT.md and the latest entry at the TOP of STATUS.md.
      
      Verify the connected Studio session:
      money — place ID 94130990350526.
      
      Query Graphify for the relevant economy, offer, vehicle and progression relationships. Inspect current live sources before editing.
      
      Relevant systems include:
      - PlowConfig and its catalog generator.
      - PlowService and PlowRules.
      - Vehicle assembly and driving.
      - SnowFieldService.
      - StageConfig and stage attributes.
      - UpgradeConfig / UpgradeService.
      - Pets, eggs, treasures and rebirths.
      - ContractConfig / ContractService.
      - Activities, quests, achievements and temporary boosts.
      - Garage offers, reservations, workbench and collection UI.
      
      Older handoff entries may be outdated. Re-read affected live sources immediately before applying changes because another agent may be working.
      
      2. DIAGNOSE THE REAL BOTTLENECKS
      
      Audit both World 1 and World 2.
      
      Large Snow prices alone do not establish a progression problem: compare prices with the income players can actually earn at that point.
      
      Produce a before table for each stage showing:
      - Representative entry build and developed build.
      - Normal-field Snow per active minute.
      - Field health, toughness and clearing throughput.
      - Cheapest obtainable, meaningful improvement.
      - Minutes required to earn that improvement.
      - Expected rolls/time to receive an appropriate offer.
      - Gate cost and approximate saving time.
      - Job income and availability.
      - Expected stage arrival and departure times.
      
      Inspect the existing simulation carefully. Its earlier report recorded long gaps between meaningful improvements, including a 42-minute gap for an efficient player. Determine whether those gaps still exist in the current game.
      
      Include actual driving speed in snow, turning, regrowth, garage visits, spending on eggs/upgrades and offer randomness. Do not assume perfect continuous clearing or immediate access to every desired part.
      
      3. CREATE A SMOOTHER PROGRESSION
      
      Tune the entire relationship between:
      - Field income.
      - Part prices and performance.
      - Stage gates.
      - Upgrade prices and effects.
      - Eggs and pet multipliers.
      - Rebirth benefits and milestones.
      - Treasures, activities and jobs.
      - Offer availability.
      
      Do not fix everything by dividing all prices by one number or multiplying all rewards.
      
      Use these starting targets, then refine them with measurements:
      - First useful paid part within roughly 1–3 active minutes.
      - Early ordinary improvements approximately every 2–4 minutes.
      - Midgame improvements approximately every 3–6 minutes.
      - Later improvements approximately every 5–8 minutes.
      
      Count genuinely useful improvements across parts and upgrades. A tiny stat increase or cosmetic purchase does not resolve a progression gap.
      
      Investigate and fix stretches exceeding approximately 10 active minutes without an obtainable, reasonably affordable improvement. Longer saving goals can exist alongside smaller useful goals.
      
      Keep World 1 around the accepted 3–5 active hours for a new player without paid boosts. Achieve this through varied, steadily rewarding progression rather than one enormous final saving wall.
      
      Preserve World 2 as a substantial continuation. Do not make its first few purchases invalidate every World 1 build instantly.
      
      Players should not need to buy every part or complete the collection to progress.
      
      4. PLACE THE 45 NEW PARTS AT THE GAPS
      
      Distribute the additions according to measured bottlenecks. Do not put one in every biome automatically or add everything at the end.
      
      Create intermediate purchases between practical entry equipment and expensive aspirational equipment.
      
      Reprice existing parts where necessary. Adding intermediate parts alone may not resolve the current curve.
      
      Each new part needs:
      - A permanent unique ID.
      - Name and short understandable description.
      - Category and biome/theme.
      - Rarity and actual offer weight.
      - Fixed Snow price.
      - Real stats and a clear purpose.
      - Blender model and working preview.
      - Correct mounting information and bounds.
      
      Include useful specializations:
      - Blades: wider soft-snow clearing, stronger compact blades, icebreakers, balanced scoops.
      - Engines: acceleration, efficient working speed, balanced performance.
      - Running gear: turning, grip, maneuverability, tracks and specialized movement where supported.
      
      Use existing working mechanics. Do not invent unused stats just to make cards look different.
      
      Compare complete builds on representative fields and jobs. Account for speed caps, width caps, diminishing returns and the interaction between blade power, width, engine and gear.
      
      An ordinary upgrade should produce a noticeable benefit. A specialist can be a sidegrade if its advantage is clear and measurable.
      
      Avoid expensive parts that are barely stronger, and avoid one dominant part that makes several later purchases pointless.
      
      5. KEEP RNG EXCITING AND PRACTICAL
      
      Preserve the core:
      ROLL AN OFFER → BUY OR RESERVE → EQUIP → CLEAR SNOW.
      
      Rolling must never grant ownership automatically.
      
      Prices must remain explicit and independent of wallet size.
      
      Keep exciting rare offers, including occasional future goals players cannot buy immediately. Also maintain a reliable supply of practical improvements.
      
      Review the current practical-offer floor and bad-luck protection after expansion. Forty-five additional parts must not dilute useful offers until upgrading becomes harder.
      
      Measure:
      - Useful offers.
      - Affordable or reasonably earnable useful offers.
      - Duplicates.
      - Long dry streaks.
      - Offer availability for each category.
      - Luck effects at low and high progression.
      - Behavior when a player already owns the strongest practical choices.
      
      A pity roll should not repeatedly produce a theoretically stronger part that takes hours to afford.
      
      Preserve transparent, accurate displayed odds. Server selection and UI odds must agree.
      
      Handle existing offers and reservations safely. Do not silently increase a price already shown to a player. Define and test a compatible policy for saved offers when catalog prices change.
      
      6. MAKE JOBS CLEARLY WORTH DOING
      
      Preserve my request that NPC clearing jobs pay significantly better than ordinary collecting.
      
      If that rebalance is not implemented yet, include it here.
      
      Starting targets:
      - Standard jobs: approximately 2× ordinary collecting income per minute.
      - More demanding jobs: approximately 2.5×.
      
      Compare the full job cycle:
      travel + interaction + clearing + completion/return.
      
      Include Snow already earned from clearing job tiles when calculating the completion bonus.
      
      Estimate and snapshot rewards using validated ordinary-field earning power and expected job duration. Do not reward deliberate waiting or feed previous contract rewards back into their own baseline.
      
      Apply boosts consistently and only once.
      
      Model the actual job schedule and yard capacity. Do not assume unlimited back-to-back jobs.
      
      Players who ignore jobs must still progress reasonably, while players who complete them should feel a clear advantage.
      
      7. BUILD AND INTEGRATE THE MODELS
      
      Create all 45 new models in Blender using the established export/import pipeline.
      
      Use attractive, chunky, low-poly shapes with distinct silhouettes. Avoid making every addition a recolored copy.
      
      Keep mounting positions, scale and collision behavior compatible with existing vehicles.
      
      Do not make every stronger blade physically wider. Respect current vehicle clearance and width limits.
      
      Integrate every addition into:
      - The server catalog.
      - Offer pools and odds.
      - Purchase and reservation flows.
      - Ownership and profile validation.
      - Equip/unequip and vehicle assembly.
      - Garage displays and workbench.
      - Collection/index categories.
      - Real model previews or the established icon system.
      
      Replace hardcoded catalog counts with counts derived from the valid catalog where appropriate. Verify that the index shows the correct owned count out of 135 and that each category contains 45 parts.
      
      Preserve existing achievement IDs and earned rewards. Review new total-dependent goals without revoking progress.
      
      Keep Blender sources, exports, upload IDs and a manifest in a new outputs folder. Update the authoritative catalog/balance generator so a later regeneration cannot restore the old economy.
      
      8. VERIFY THE BALANCE AND IMPLEMENTATION
      
      Run reproducible simulations across multiple random seeds, including:
      - Efficient and casual active play.
      - Collecting-only play.
      - Players regularly completing jobs.
      - Players ignoring optional rewards.
      - Unlucky offer streaks.
      - High luck and boosted players.
      - Mixed-category builds.
      - Rebirth.
      - World 2 progression.
      
      Report median and slower-run results, stage times, purchase cadence and the longest period without a meaningful improvement.
      
      Separate active play from idle time. State assumptions and distinguish simulations from real playtests.
      
      In isolated Studio tests, verify:
      - Exactly 135 valid parts, split 45/45/45.
      - Existing IDs and ownership preserved.
      - All 45 new parts purchase and equip correctly.
      - Valid build combinations produce finite, sensible stats.
      - Starter fallback remains available.
      - Offer odds and pity behavior remain correct.
      - Purchases are atomic and cannot duplicate rewards.
      - Saved offers/reservations migrate safely.
      - Normal fields and jobs pay correctly.
      - Boosts are not applied twice.
      - Rebirth preserves the intended collections and build ownership.
      - Index, garage and workbench show the actual parts and prices.
      
      Perform representative real driving and purchase tests at early, middle and late progression. Inspect the GUI rather than relying only on data tables.
      
      Follow AGENTS.md for BalanceTestMode and cleanup. Do not reset real player data or claim persistence/multiplayer/device checks that were not performed.
      
      9. FINISH WITH EVIDENCE
      
      Refresh affected live source mirrors and snapshots, then update Graphify.
      
      Update STATUS.md with implementation, tests, remaining issues and recovery information. Update PROJECT.md for lasting balance decisions.
      
      Provide:
      - Before/after stage affordability tables.
      - Before/after progression estimates.
      - Purchase-cadence and longest-gap results.
      - The 45 additions grouped by category.
      - Screenshots or a model gallery.
      - Backup and asset-source locations.
      - Accurate saved/published state.
      
      Preserve unrelated map, tutorial, garage, pets, contracts and arena work. Do not publish without my instruction.
      
      The outcome should be a 135-part game where players can regularly earn a useful improvement, rare offers remain exciting, jobs are worthwhile and progression through both worlds feels consistent.
      """
  </note>
</relay>