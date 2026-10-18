# Floating shop labels

`Controllers/ShopLabelController.luau` adds local BillboardGuis above `Map.SafeZone.BoxingSackShop` and `PetSellingStand`: **SACK SHOP** in cream/gold and **SELL PETS** in cream/mint. FredokaOne text, a dark outline and world-sized canvases match the existing game. No images/uploads or server changes are needed.

The labels sit four studs above the tallest shop geometry, including the sack shop's glove and the pet stand's paw sign. Discovery runs twice per second and raises the label if more roof geometry streams in. Removed shops/signs clear their display; rediscovered shops recreate it. Start is idempotent and Destroy removes the binding and displays.

Each rendered frame, the label requires both its anchor and storefront sign in the camera's viewport. Both the player-to-shop and camera-to-label distances must be at most **150 studs**. BillboardGui.MaxDistance provides the same rendering limit; AlwaysOnTop=false lets world geometry occlude the text. Existing physical shop signs, NPCs, prompts, camera controls and pen displays are unchanged.

Verification on 2026-10-18:
- Fresh single-player Studio session: **14 checks passed**, seven per shop: near visibility, exact text, depth/occlusion flag, look-away hiding, distant-camera hiding, distant-player hiding and reappearance on returning.
- Both labels visually reviewed together above the roof decorations.
- Source formatted with StyLua; Rojo binary/XML packaging checked. Current build has 286 matching source scripts and no QA/probe scripts.
- Studio returned to Edit, TestService.NumberOfPlayers=0. Multiplayer was not started. Previous Shift Lock and pen-wave fixes are included; their separate suites were not rerun for this label-only addition.

Deliverable: `outputs/KickTheEgg-ShopLabels.rbxl` outside the repository. Published/mobile-device visuals and actual network streaming have not been separately tested.
