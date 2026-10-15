# Figma UI redesign: state of the build

**File:** https://www.figma.com/design/VDqe1QM0L4jWzGavOuVQe7 ("Kick an Egg — UI Redesign (for approval)"). It is in krono kronos's drafts on the Starter plan.

The file is built with the Figma MCP `use_figma` tool (Plugin API JavaScript). The Starter plan with a View seat allows about **20 Figma MCP calls per month**. That limit was reached on **2026-10-13**, after batches 01 and 02 below.

## Done (page "Components")

| Batch | Contents |
|---|---|
| 01 | **Styles:** 59 paint styles (Theme.luau colours and gradients, rarity, meter bands) and 10 KTE text styles (Fredoka One).<br>**Art:** 29 real PNGs from `assets/ui-upload` as `Art/<key>` components.<br>**Shared pieces:** `Fx/Studs` tile layer, new SVG icons (trade arrows, auto-kick cycle, pointer, mouse, magnifier, checker flag, warning, avalanche front, egg marker, house, home arrow, check, sparkle) and `Tutorial/Arrow Straight / Down / Curved`.<br>**Component sets:** `HUD/Nav Button` (Shop / Index / Rebirth / Trade × 5 states), `Button` (5 styles × 4 states), `Close Button`. |
| 02 | **Kick:** `Kick/Kick Button` (5), `Kick/Auto Kick` (Off / On), `Kick/Meter` (7 levels, slim, one fill), `Kick/Rating` (6), `Kick/Hint` (4 inputs).<br>**Equipment and inventory:** `Equipment/Sack Slot` (Away / Out × Keyboard / Gamepad / Touch), `Inventory/Slot` (8 states), `Quickbar/Slot` (3), `Inventory/Tab` (3), `Inventory/Search` (3), `Thumb` (Egg / Pet × 8 rarities), `Thumb Sack` (6). |

## Not built yet

1. **Batch 03** (`03-hud-chase-tutorial-settings.js`, ready to run as one `use_figma` call):
   - fixes the "Kick controls" board overflow;
   - adds `Progress Bar`, `Panel/Window`, `Settings/Row`;
   - adds the egg-running HUD: `Chase/Eggs Secured`, `Chase/Zone Progress`, `Chase/Avalanche`, `Chase/Run Banner`, `Chase/Home Indicator`;
   - adds the tutorial kit: `Tutorial/Instruction`, `Tutorial/Highlight Border`, `Tutorial/Spotlight`, `Tutorial/World Marker`, `Tutorial/Skip`.
2. **Batch 04:** composed approval screens on the "Desktop previews" page (1920×1080, the game's design resolution).
3. **Batch 05:** composed approval screens on the "Mobile & tablet previews" page (phone at 2× of 844×390, plus a tablet inventory).

**Thumbnails:** the `Thumb` components are flat stand-ins. The owner wants the real 3D models. `model-renders/` holds Studio renders of all 79 eggs and 79 pets, made with `sh tools/preview/preview.sh Models desktop out.png <1-4>` (1-2 = eggs, 3-4 = pets) using the same camera as `Ui.petArt` / `Ui.eggArt`. When Figma calls are available again:
1. Crop each cell.
2. Upload the crops with `upload_assets`.
3. Swap them into `Thumb` and the inventory previews.

Node IDs are in `ledger.json`. Every batch removes and rebuilds its own boards by name, so it is safe to re-run.
