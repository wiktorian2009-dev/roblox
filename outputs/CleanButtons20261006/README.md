# HELP and AFK button cleanup — 2026-10-06

Installed in Edit in place 94130990350526. Not published.

The user rejected thick white SnowArt strips on the HELP menu and AFK AUTO-PLOW button. These specific controls now use CleanControls: native rounded fills, a subtle gradient, one thin border and padded readable labels. Garage Lesson uses a stronger blue fill for white text; Close uses soft slate. HELP stays gold; AFK keeps its existing blue/green state.

Shared SnowArt and the active tutorial card/spotlight are unchanged. Tutorial replay callbacks, AFK requests, input cancellation, idle notice, placement next to UPGRADES and drift bonus logic are preserved. No new PNGs or gameplay/economy changes were needed.

## Checks

- Fresh isolated Play: actual HELP opens the menu, CLOSE closes it, and GARAGE LESSON launches the real Garage Intro/card.
- The actual AFK button reached its existing server guard: "Finish the tutorial first." Actual AFK earning was not retested in this presentation task.
- The rejected SnowArtSkin layers are absent on all scoped controls, which retain native opaque fills.
- Three final scripts compile in Studio; visual preview: preview.jpg.
- Own Play stopped. BalanceTestMode and CleanButtonsTestOwner removed in Edit. Real persistence and publishing were not tested.
- Console had no errors in the changed GUI scripts. It also reported an unrelated PortalAnimator wait for Center and a virtual mouse/CoreGUI warning; the portal issue remains outside this visual fix.

## Recovery and handoff

ServerStorage.CleanButtonsBackup_20261006 contains the two pre-change clients. Original mirrored files are in before-mirrors/.

final-sources.json and source-hashes.json capture CleanControls, PlowTutorialClient and AfkDriftClient. These three relevant mirrors were refreshed; Rojo mapping scope is unchanged. install-edit.luau is a guarded one-time installer and deliberately refuses replay after installation. Other newer Claude sources were preserved.

Graphify refreshed code-only and clustered without labels: 1,069 nodes, 2,214 edges, 75 communities. It is a navigation aid, not a complete Studio export or compiler.

