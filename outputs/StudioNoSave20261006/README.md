# Studio Play without API access (2026-10-06, Claude) - save point 30

**Cause of the Frostfall kick:** in a normal Studio Play, every DataStore read failed with `StudioAccessToApisNotAllowed` ("Studio access to APIs is not allowed", error code 7), because the place has "Enable Studio Access to API Services" off. After 4 failed tries, the save-load safety from save point 21 kicked. It was not a profile or data bug.

**Fix:** a change to ServerScriptService.DataService, mirrored to game/src.
- **Only in Studio, and only for that exact error:**
  - stops after the first try and gives the player a temporary fresh profile;
  - `save()` never writes that profile, `SaveNow` returns false, and `LoadedFromStore` is false, so paid grants stay refused;
  - sets the player attribute `StudioNoSave`;
  - shows a small top-right notice, "Studio test: progress won't save", for about 20 s.
- **Everything else is unchanged:** live servers, other errors in Studio and unreadable data still retry 4 times, kick, and write nothing.
- **Test hook (DataLoadTest only):** new switches `ApiOff` (fake that error) and `Studio` (false = behave like a live server).

**Tests (2026-10-06):**
- **Normal Play (no BalanceTestMode, real DataStore):** no kick, the game is playable, and the notice shows.
- **Isolated fake store (BalanceTestMode + DataLoadTest):**
  - live server with the API-off error: kick, 0 writes;
  - live server with a generic failure: kick, 0 writes;
  - Studio with a generic failure: kick, 0 writes;
  - Studio with the API-off error: temporary profile, saves refused, 0 writes;
  - a profile with the new fields (part levels 4, EconomyVersion 2, LevelsVersion 1, Snow 123456789): loads from the store with everything intact and saves.
- The temp script and the test attributes were removed afterwards.

**Undo:** restore `ServerStorage.StudioNoSaveBackup_20261006.DataService`, or use `DataService_before.luau` here.
**Alternative:** turn on Game Settings → Security → "Enable Studio Access to API Services". Studio Play then uses the real save.
