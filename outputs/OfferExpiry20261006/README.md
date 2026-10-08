# Offers expire after 30 s (2026-10-06, Claude)

wiktor: "rolls stays only for 30 second so reserve make sense".

## Rules (server-authoritative, PlowService)
- **Lifetime:** a pedestal offer lasts **30 s** (C.Shop.OfferSeconds), using server time (ExpiresAt).
  - A server loop (every 0.5 s, and before every garage action) clears expired offers, updates the public bay, and fires PlowEvent "OfferExpired".
  - Buying or reserving an expired offer fails with "That offer is gone - roll a new one!".
- **Reserving** a part takes it off the clock: the reserve shelf never expires.
- **Pauses:** the timer only runs **inside the garage after the tutorial**. Outside the garage, or during the tutorial's garage lesson, it is paused and the offer keeps its remaining seconds (Left).
- **Old profiles:** saved offers from older profiles, and offers that were ticking when a player left, get a fresh 30 s window when the timer next runs (PlowRules). Nothing expires while you are offline.
- **Bad-luck protection:** a protected roll lasts **60 s** (ProtectedOfferSeconds). If it still runs out unbought, the protection counter is restored, so the next roll is protected again.
- **Unchanged:** the roll cooldown, the lower-price rule (C.OfferPrice) and the reserve flow.

## UI (calm style)
- **Pedestal pill** (owner only): "OFFER GONE IN 23s" with a draining soft-blue fill, which turns soft orange in the last 8 s. It reads "OFFER - TIMER PAUSED" while paused, and the roll countdown / ROLL READY! when the pedestal is empty.
- **Offer card:** the header reads "PEDESTAL 2 - GONE IN 23s - RESERVE IT?", with a thin draining bar under it.
- **Expiry:** a toast reads "An offer ran out - RESERVE a part to keep it!".

## Tests (real Play, BalanceTestMode, removed afterwards)
- **During the tutorial:** a rolled offer stays paused (Left = 30 after 3.5 s).
- **After TutorialDone:** the timer runs. A real **E press** rolled pedestal 2, and the pills read "OFFER GONE IN 22s / 23s".
- **At 30 s:** both offers were cleared on the server, two OfferExpired events arrived, and the bay attributes emptied. Buying with the old token was refused, and the pill went back to ROLL READY!.
- **Reserve:** the reserved part has no timer.
- **Outside the garage:** 4 s in the garage, then the lobby, leaves Left = 25.4. Six seconds later it is still 25.4, and back in the garage it ends in 24.1 s.
- **Protected roll (Dry 7):** Protected = true with a 60 s window. When it expired, Dry was restored to 6 and the next roll was protected again (60 s).

## Not tested
- A screenshot: the Studio 3D view was not rendering in captures.
- A real phone or gamepad.
- The full tutorial run with the paused timer.

## Undo
ServerStorage.OfferExpiryBackup_20261006 holds PlowConfig, PlowRules, PlowService, PlowShopClient and PlowGarageClient.
