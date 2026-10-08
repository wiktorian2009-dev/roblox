# One shared popup stack (2026-10-06, Claude)

wiktor: "if 3 messages on screen pop up like rebirth, snow king, and help friend one should go down and the older one down".

## What it does (new `StarterPlayerScripts.PopupStack`; no popup script edited)
- **Placement:** the short top-of-screen messages now share one column. The **newest is on top** and older ones are pushed down, so nothing overlaps.
- **Each popup keeps its own look, pop-in and lifetime.** Its own script still shows and hides it. The stack only moves it while it is up and gives back its original position when it goes.
- **Stacked:**
  - HELP REQUEST (HELP OUT / LATER);
  - the Frost King announcement (JOIN / LATER);
  - REBIRTH READY;
  - the help-job toast;
  - reward / quest / achievement toasts;
  - the egg "not enough Snow" toast;
  - garage toasts, including "An offer ran out";
  - the mythic treasure announcement;
  - the Frostfall, World 2 and stage-unlock toasts.
- **Cap:** at most 4 popups or 70% of the screen. When it's full, the **oldest plain toast fades first**. Popups with buttons are never hidden by the stack.
- **Tutorial:** while the tutorial card is up, the column starts below it.
- **Left where they are, on purpose:**
  - the right-edge treasure toast;
  - the arena banner;
  - the Frost King battle text (centre);
  - the tutorial flash;
  - toasts inside open panels.

## Tests (Play)
- **Real** help request (test hook) and **real** Frost King spawn (test hook). Both were held back by the tutorial's event suppression during setup, so for the stacking test I showed their real frames directly (simulated trigger). Order:
  1. HELP REQUEST;
  2. REBIRTH READY;
  3. Frost King;
  4. a real garage toast.
- **Result:** newest on top, in order (toast 68–131 px, Frost King 140–485, Rebirth 494–597, Help Request 605–905), with no overlaps (`screens/popup_stack.jpg`).
- **Real click on LATER** in the stacked help request: it parked into its pill, its original position was restored, and the others stayed stacked.
- **With the tutorial card up**, the column started below the card (card bottom 148 px, first popup at 238).

## Not tested
The phone emulator. The column is placed in pixels from the screen top, so it adapts.

## Undo
Delete `PopupStack`; nothing else was changed.
