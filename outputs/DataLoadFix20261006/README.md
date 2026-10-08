# Never save a blank profile over a real one (2026-10-06, Claude)

Found while building the Verity Egg receipts. Before this fix:
- if `GetAsync` failed when a player joined, `DataService.load()` quietly started a **blank profile**;
- autosave, leaving or rebirth could then **overwrite the player's real save** with it.

## Fix (ServerScriptService.DataService)
- **Load:** up to 4 tries with backoff (2 s, 4 s, 6 s).
- **Unreadable data:** stored data that isn't a profile table counts as a failed load and is never overwritten.
- **Still failing after all tries:**
  - no profile is created, so `save()` has nothing to write and ProductService / PassService can't grant;
  - attribute `DataLoadFailed`;
  - a warning in the server log;
  - kick with "Couldn't load your save - please rejoin. Your progress is safe."
- **New players** (nothing stored) start exactly as before.
- `DataService.LoadedFromStore` (used by receipts) is false for failed loads.
- **Test seam:** only when the ServerStorage `DataLoadTest` attribute is on in an isolated BalanceTestMode session.
  - It uses an in-memory fake store, so the real DataStore is never touched.
  - It logs kicks instead of kicking, and exposes `ServerStorage.DataLoadTestHook`.

## Tests (Play, BalanceTestMode + DataLoadTest; fake store only)
- **Join with nothing stored:** new profile, normal start, nothing written.
- **Stored save (1,234 Snow), 2 simulated failures, then success:** loaded on the 3rd try with 1,234 Snow.
- **Permanent failure:**
  - not loaded, `DataLoadFailed`, friendly kick logged, 4 tries;
  - a save attempt returned false, and a Verity Egg receipt returned NotProcessedYet;
  - **0 writes**.
- **Afterwards:** the stored save was still the real one (1,234 Snow) and loads again once the store works.
- **Unreadable stored data** ("garbage"): treated as failed, 0 writes, kick logged.
- **Genuinely new player** again: fresh profile (0 Snow).

## Not tested
A real DataStore outage, which can't be simulated against the real store without touching it.

## Undo
`ServerStorage.DataLoadFixBackup_20261006.DataService` holds the previous version (6213/2115957021). Live = disk now: 9393/1949148856.
