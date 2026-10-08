# Rebirths

Added to the connected Roblox Studio place on September 29, 2026. Changes are in Studio and have not been published.

Each rebirth adds 0.50 to the permanent Snow multiplier and 0.25 to permanent luck. These bonuses multiply the corresponding upgrade bonuses. For example, the first rebirth gives 1.5× Snow and 1.25× luck; the second gives 2× Snow and 1.5× luck. The bonuses grow additively rather than compounding each rebirth.

| Rebirth | Required unlocked stage | Snow required |
|---|---|---:|
| 1 | Cursed | 500,000 |
| 2 | Crystal | 25 million |
| 3 | Retro | 1 billion |
| 4 | Jungle | 25 billion |
| 5 | Absolute Zero | 350 billion |
| 6 | Portal | 4 trillion |
| 7–50 | Portal | 4 trillion × (rebirth number − 5)² |

Rebirth resets all Snow, stage unlocks, and purchased upgrades, and returns the player to spawn. Shovels, pets, collection discoveries, settings, and lifetime rolls are retained. Equipped items return to the starting slot limits, retaining the strongest currently equipped items; other items remain owned. There are 50 rebirths available.

The menu displays current and next bonuses, requirements, progress, and exactly what resets. A separate confirmation click is required. Eligibility and resets are checked on the server, including protection against stale duplicate requests.

## Verification

Passed isolated Studio tests for the first two rebirths, cancellation, insufficient currency, missing stage, duplicate requests, keeping collections, resetting upgrades and gates, teleporting to spawn, stacking with new upgrades, actual roll luck, and inventory refresh when an earlier roll finishes. All 50 requirements were checked for finite, increasing costs. Desktop and narrow menu layouts were inspected.

Rebirths are included in the existing saved profile and request an immediate save. Profile serialization and bonus reapplication passed. Persistent saving across a real rejoin remains unverified because Studio API access is disabled. Tests used isolated temporary profiles, leaving existing saved progress untouched. Test mode and temporary helpers were removed, and Studio was returned to Edit mode.

The earlier 3–5 hour first-run estimate predates rebirths. Keeping strong collections makes subsequent runs faster; actual progression with rebirth choices needs player timing before claiming a new completion-time estimate.

Backup: Roblox-rebirth-backup.json contains the pre-change sources and added-instance list for rollback.

