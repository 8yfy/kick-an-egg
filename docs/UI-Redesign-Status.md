# Kick an Egg: UI redesign status (for Partner A)

**Date:** 2026-10-13

**Figma file:** https://www.figma.com/design/VDqe1QM0L4jWzGavOuVQe7 ("Kick an Egg — UI Redesign (for approval)")

**Status:** design only, waiting for approval. **No game UI has been changed yet.**

## What's in Figma now ("Components" page)

Everything is built from the existing UI code (`Theme.luau`, `Ui.luau`, `Rail.luau`, `KickPanel.luau`, `SackSlot.luau`…) and the real PNGs in `assets/ui-upload`.

- **Foundations:**
  - 59 colour and gradient styles and 10 text styles (Fredoka One), copied from `Theme.luau`;
  - 29 of the game's own images.
- **Trade button:**
  - built exactly like Shop, Index and Rebirth: 250×86, 5 px border, studs, top highlight, 36 px label;
  - turquoise (`Theme.Nav.Trade`) with a new glossy trading-arrows icon;
  - all four buttons have Default, Hover, Pressed, Selected and Disabled states;
  - the current Trade art is shown beside it for comparison.
- **Kick controls:**
  - **KICK:** a native button with Ready, Hover, Pressed, Timing and Locked states.
  - **Auto Kick:** a clear ON/OFF switch.
  - **Meter:** still vertical and slim (44 px), with one fill coloured by the existing timing bands, a Perfect zone and a target marker. Shown at all 7 levels.
  - **Ratings:** MISS, OKAY, GOOD!, GREAT!, EXCELLENT!, PERFECT!
  - **Input hints:** compact hints for each input, e.g. "Tap anywhere to kick!".
- **Equipment and inventory pieces:**
  - **Boxing Sack quick slot:** the key chip sits on the tile corner and the name plate below it, so nothing overlaps. Equipped shows gold. Variants for keyboard, gamepad and touch.
  - **Inventory slot:** 8 states (Default, Hover, Selected, Equipped / In hand, In Pen, Stored, Locked, Empty).
  - **Other pieces:** custom hotbar slot, category tabs, search field, and egg / pet / sack thumbnails.

**Known glitch:** on the "Kick controls" board, the KICK states and the ratings run past the board's right edge. The fix is part of the next build step.

## Not in Figma yet

- the egg-running HUD (Eggs Secured, Zone Progress, Avalanche warning and distance, Home indicator);
- the tutorial kit (straight, curved and down arrows, pointer, highlight border, spotlight, instruction label);
- the Settings rows;
- the seven full-screen desktop and mobile preview screens.

**Why:** the Figma account is on the free Starter plan (View seat), which allows about 20 Figma tool calls a month, and that limit was reached.

The next build step is already written: `tools/figma/03-hud-chase-tutorial-settings.js`. The node IDs are in `tools/figma/ledger.json`.

## Already done in the game (no redesign work needed)

- **Settings:** scrolls properly (ScrollingFrame + UIListLayout + UIPadding); no overlapping rows.
- **Pen owner display:** avatar thumbnail and username only, in a transparent BillboardGui.

## Next steps

1. Get more Figma calls by one of these:
   - upgrade the plan (Professional with a Dev or Full seat);
   - wait for the monthly reset;
   - use the Figma desktop app with a one-off plugin.
2. Finish the remaining components and the seven desktop and mobile previews.
3. The owner approves the previews.
4. Implement only the approved UI changes in Roblox. No gameplay, economy, pet, sound or save-data changes.
