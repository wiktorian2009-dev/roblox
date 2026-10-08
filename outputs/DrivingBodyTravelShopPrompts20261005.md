# Claude prompts — driving, travel, Body slot and paid offers
Prepared 2026-10-05. Run the prompts in order, one at a time. Re-read live sources before each patch; other agents may have changed them. These are requests to implement features, not claims that the features already exist.

 1. Make driving fun and add controlled drifting
```text
Implement better normal-world snowplow driving and deliberate drifting in my existing Roblox game. Do the work, build the feedback, and test it; do not stop at a proposal.

Project folder: C:\Users\wikto\Desktop\Roblox Gra. Live place: money, 94130990350526. Read AGENTS.md, PROJECT.md and the current STATUS.md first. Query the scoped Graphify map, then inspect only relevant current live scripts. Refresh the Studio ID. Re-read affected sources immediately before writing because Codex and Claude may both be working.

Keep the current progression, parts, jobs and arena. Driving should feel responsive, playful and controllable. Beginners must still be able to turn into contract yards, reverse out of corners and cross narrow bridges.

Improve acceleration, braking, reversing, steering smoothing and recovery from small bumps. Preserve existing suspension/step handling and snow-surface slowdown unless a measured adjustment is needed. Keep different engines and running gear meaningful; do not flatten their progression.

Add a hold-to-drift action: Left Shift while driving in the normal world, a clear touch button, and a suitable gamepad binding. Show the current binding. Drifting needs ground contact, enough speed, and steering input. Holding the button while stationary should not spin or launch the vehicle.

Integrate drifting INTO the existing drive controller. PlowDriveClient currently writes AssemblyLinearVelocity and AssemblyAngularVelocity every Heartbeat; adding a competing force or second controller will be overwritten. Reduce lateral grip during a drift, preserve forward momentum, provide bounded yaw assistance, and smoothly restore traction on release. Make the handling frame-rate independent. Tune short controlled slides, countersteering and a satisfying exit; ordinary turns should remain grippy.

Clear drift state on seat exit, death, reset, teleport, loss of focus and controller disconnect. Ignore typing and processed UI input. Gate controls to the correct occupied normal plow. The arena has its own controller and Boost/Brace bindings; leave its normalized competitive physics and knockback unchanged.

Use compact wheel powder, fading skid trails, restrained engine/tire audio and a small optional camera lean/FOV change. Reuse UniversalVFX and existing licensed audio where suitable. Pool/cull effects and stop them when airborne or stationary. Respect effects-volume and reduced-motion settings. No full-screen flashes, excessive shake or permanent trails. Do not award Snow for drifting or introduce an unmeasured speed boost.

Test real desktop input with starter, middle and fast/wide builds: slalom, braking, reverse, drift release, narrow World 2 bridge and NPC yard entry. Check touch layout and gamepad bindings, and ensure legitimate sideways motion does not trigger server speed checks. Record real tests separately from simulated cases.

Preserve backups. Do not interrupt another agent's playtest, reset real data or publish. For your own isolated progression test, follow AGENTS.md BalanceTestMode setup and cleanup. Mirror changed live sources, refresh Graphify, and update STATUS.md with measured behavior and remaining limits.
```

## 2. Add a safe, useful teleporter
```text
Implement free quick travel in my existing snowplow game: a snowy TRAVEL menu and an attractive physical teleporter in the lobby. It should remove tedious walking while preserving stage unlocks.

Use C:\Users\wikto\Desktop\Roblox Gra and Studio place money, 94130990350526. Read AGENTS.md, PROJECT.md and current STATUS.md. Query Graphify, refresh the Studio ID, and verify current live travel, garage, contract and arena sources before editing. Preserve concurrent work.

The menu should list Lobby, My Garage, and all actual stages in the current StageConfig across both worlds. Clearly separate worlds, identify the current destination, and show locked areas with their real unlock requirement. Travel is free after unlocking; no new paid travel requirement. Refresh locks immediately after a purchase or rebirth. Do not resurrect the removed Neon stage or invent destinations.

Use the approved snowy UI style, readable biome icons/names, large touch targets and gamepad navigation. Add a compact HUD button without covering the tutorial, contract tracker or shop. Make a low-poly Blender teleporter pad with a soft icy ring, modest particles, readable label and proximity prompt. Keep paths and vehicle routes clear.

Unify travel through a server-controlled handler with a destination registry. The client sends only a destination ID. Validate unlocks, player state, destination, cooldown and active travel on the server. No arbitrary client CFrames, bypassed gates or duplicate teleports from spam.

Handle vehicles properly: current StageService/FrostfallTravel character pivots are not enough when seated. Park/despawn the old normal plow and safely release its seat BEFORE moving the character. Clear velocities. If the player was driving, restore the same equipped build at a verified clear arrival spot where driving is allowed; in the garage park it and use the existing garage preview flow. Account for wide blades and preserve inventory, offers and reserves.

Route garage entry/exit through the existing bay-lease service. Release a bay when leaving, update world/garage state consistently, and clear stale return positions. Use bounded streaming preparation and recheck the character after yielding. Handle death or disconnect during travel without an orphaned vehicle, stuck camera or busy flag.

Arena visitors must use the arena's existing leave/cleanup path; general travel cannot escape a match or leave arena state behind. For an active NPC job, show one clear cancellation warning, then cancel through the existing contract cleanup before travel. Release its yard and personal snow; never silently duplicate job rewards.

Test lobby↔garage, World 1↔World 2 unlocked stages, locked requests, rebirth relocking, seated travel, wide builds, active contracts, arena restrictions, repeat clicks and respawn during streaming. Check arrivals on safe ground and that driving still works afterward.

Keep recoverable backups, do not stop someone else's test, reset real data or publish. Mirror changed live sources, refresh Graphify and update STATUS.md with what was implemented and actually tested.
```

## 3. Add Body as the fourth vehicle part
```text
Implement BODY as the fourth interchangeable snowplow part category alongside Blade, Engine and Wheels/Tracks. Players should roll an offer, buy or reserve it, and equip it through the existing garage system.

Canonical folder: C:\Users\wikto\Desktop\Roblox Gra. Studio place: money, 94130990350526. Read AGENTS.md, PROJECT.md and current STATUS.md; query scoped Graphify and verify live sources. The latest catalog was 135 parts, 45 per existing category; verify its current count and preserve the newest rebalance rather than rerunning the old 90-part generator.

Create 15 initial Body designs including a free starter, distributed across the current progression bands. Give them distinct chunky, attractive Blender models: readable cabs, bumpers, windows and silhouettes, with sensible attachment clearance. Include humble early bodies and impressive later themed bodies. Build and import the actual models through the established pipeline, save Blender/export sources, and make matching inventory icons or consistent model previews.

Keep one standardized mount/root/seat convention so every body fits existing blades, engines and running gear. Separate the replaceable visual shell from invariant physics root, seat and attachment points. PlowAssembly currently has a fixed chassis shell: replace its visible shell cleanly instead of stacking new bodies over the old cab. Do not let decorations collide with the player, obstruct cameras, float wheels or bury blade mounts.

Give Body a small, bounded useful PvE contribution, such as snow efficiency and a modest handling trait. Show its real effect. Avoid another huge multiplicative power ladder or an unrelated storage mechanic. Integrate the contribution into the real stats, comparisons, useful-offer checks and progression model. Preserve the current non-paid pacing and the advantage of active NPC jobs.

Audit every three-slot assumption, not just C.Slots: starter defaults, catalog/generator, StatsFor/Score, PlowService snapshots and active builds, best-build evaluation, build signatures, public garage build serialization, PlowGarageClient parsing, PlowShopClient comparisons, index tabs, inventory/equip UI, viewports, model assembly, saved offers/reserves, pity and acquisition achievements. Use the CURRENT generator under outputs/Rebalance20261005/sim if it remains authoritative.

The three garage pedestals are OFFER slots, not one pedestal per part category. Keep three offers; Body becomes another possible category. Normalize category probabilities and maintain practical/useful offers across all four slots.

Migrate old three-slot saves idempotently: permanently grant/equip the free starter Body as a safe fallback without resetting anything. Preserve every existing part ID, ownership, Snow, upgrades, pets, reserves and tutorial progress. Old serialized garage builds must still parse. Unequipping Body falls back to the starter. Rebirth preserves bodies like other parts.

Update the build preview and tutorial's parts explanation without restarting completed onboarding. If the verified count is still 135, the free catalog should become 150; calculate counters from actual data rather than hardcoding it.

Arena bodies are cosmetic: maintain normalized speed, weight, handling and collision footprint. Body quality and purchases must not confer arena combat power.

Test migration twice on a copied profile, all four-slot equips, mixed early/late assemblies, another player's read-only garage preview, rolling/buying/reserving Body, rebirth and persistence using the authorized test workflow. Simulate progression with and without Body and tune away new stalls or runaway stacking. Do not claim real persistence was tested unless it was.

Back up sources and replaced shells, preserve concurrent edits, do not interrupt another test or publish/reset real data. Mirror current changes, refresh Graphify and update STATUS.md, PROJECT.md and the current catalog/generator notes.
```

## 4. Add three paid offers on the right of the screen
```text
Implement three attractive paid offers for my existing Roblox snowplow game. Build their snowy UI, visuals, server ownership/grants and tests. Prepare real pass setup where available; never invent pass IDs or pretend unconfigured purchases work.

Folder: C:\Users\wikto\Desktop\Roblox Gra. Place: money, 94130990350526. Read AGENTS.md, PROJECT.md and current STATUS.md, query Graphify, refresh Studio IDs and inspect existing monetization before adding another system. Verify whether Body has been implemented. Preserve the newest economy and all existing entitlements.

My requested DEFAULT prices:
1. 1.5x Snow — 10 Robux, permanent.
2. Starter Pack — 15 Robux, one purchase.
3. Premium Wheels — 50 Robux, permanent.

1.5x Snow:
Apply exactly one x1.5 paid factor to eligible earned Snow through the authoritative reward calculation. Ordinary plow clearing and completed NPC jobs should benefit. Audit treasure/quest/event earnings and document consistent treatment; never boost purchases, refunds, transfers or re-add the factor to already boosted rewards. Preserve jobs' current earnings advantage. A base reward of 100 should become 150 with only this pass, not 225. Explain stacking with pets, upgrades, rebirth and timed boosts.

Starter Pack:
Make a genuinely useful matching early-game vehicle bundle using practical early parts for all four categories if Body exists, plus a modest FIXED Snow grant around 2–3 minutes of unboosted starter collecting. Use the actual current economy to choose the amount. It should improve the start without skipping several biomes or becoming the strongest late-game build. Give it an appealing preview and list the exact contents before purchase.
Parts remain owned through rebirth. Currency is granted once for the profile, not on every join/respawn/rebirth or repeated ownership callback. Persist an idempotent grant marker with the existing profile system. Do not automatically replace better equipped parts; let the player equip the bundle. Handle an already-owned bundle without duplicates.

Premium Wheels:
Create one excellent-looking named wheel set, such as Aurora Wheels, in Blender: chunky tires, icy alloy hubs and restrained aurora accents. Make the actual imported model, icon and garage preview. It should feel very good in PvE through solid traction/turning and useful early-to-mid progression stats while strong free later gear remains worthwhile. Compare measured clearing/job performance before deciding stats. Wheels must fit all bodies, including the starter.
Keep these out of ordinary offer rolls and free-completion requirements. Owning them must not interfere with practical-offer pity. Do not auto-equip over better gear. Arena performance stays normalized; the wheel appearance is cosmetic there.

HUD:
Show three compact snowy offer cards on the RIGHT side, each with clear art, benefit and price. Respect the contract tracker, touch controls, tutorial, boss/arena HUD and open modals. Collapse cleanly on small screens and use the existing arena/tutorial suppression rules. Show owned/loading/unavailable states. Open the Roblox purchase prompt only after an explicit click. No repeated automatic prompts, fake timers, or confusing claimed discounts.

Roblox integration:
Use game passes for these one-time permanent purchases. Create/configure passes for the correct experience if the available tools genuinely support it. Otherwise finish the reviewable assets, descriptions, config and code, leave sales disabled until real IDs are supplied, and provide exact Creator Dashboard setup steps. Do not publish the place just to unblock setup.
Treat 10/15/50 as default prices: obtain the actual current player-facing price through MarketplaceService:GetProductInfoAsync with GamePass info type. Do not hardcode a displayed price that can disagree with regional pricing. Handle failure/not-for-sale honestly.
Check ownership on the server with UserOwnsGamePassAsync after profile loading and on join; handle PromptGamePassPurchaseFinished server-side and verify ownership before granting. Never trust a client purchase remote. Use bounded retries for transient API errors. These are passes, not repeatable developer products; do not put their grants in ProcessReceipt.

Test free/owned/purchase-cancel/API-failure cases, repeat callbacks, rejoin, rebirth, old profiles, better existing gear and four-slot previews. Verify the paid Snow factor once on both clearing and contracts, and confirm equal arena physics. Separate mock/Studio checks from a real Robux purchase. Do not spend Robux to test without explicit authorization.

Preserve backups and concurrent work. Do not interrupt another playtest, reset real data or publish. Mirror changed live sources, refresh Graphify, and update STATUS.md/PROJECT.md with actual pass IDs, setup state, bundle contents, measured rewards and anything still unverified.
```

Reference links for Roblox purchase implementation:
- https://create.roblox.com/docs/production/monetization/passes
- https://create.roblox.com/docs/production/monetization/regional-pricing
- https://create.roblox.com/docs/reference/engine/classes/MarketplaceService

