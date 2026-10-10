# Kick Sack remodel port

The 20 Kick Sack models in `src/shared/Builders/Models/Sacks/Tier01..20.luau` are generated from the
"Kick Sacks VFX Remodel" bundle (`web/sacks.js`, a three.js scene). `port.js` walks every mesh of every
tier and writes BlockBuilder rows (blocks, cylinders, balls): rings around the bag become bands, other
rings become segments or plates, cones become stepped cylinders, stars become arms. 1 m = 6.5 studs, the
origin is the hub where the straps meet, and the front is turned to -Z. Mesh names are kept, because
`src/shared/VFX/SackAura.luau` (the bundle's effects) finds glowing parts and wings by name.

To re-run after the web model changes:

1. Serve the bundle's `web/` folder on localhost so its page can also accept `POST /save/<file>` and
   write the body to a folder. Any small static server works.
2. Open `Kick Sacks.html`, paste `port.js` into the browser console and wait for the report
   (`tier:rows ...`).
3. Copy each saved `TierNN.luau` into `src/shared/Builders/Models/Sacks/`, wrapped like the existing
   files: the `R(...)` row constructor at the top, and the rows between `-- stylua: ignore start/end`.
4. Run `sh tools/run-tests.sh`: it builds all 20 sacks.

The bundle's particle textures are in `assets/sack-vfx/`. Upload them (Studio: Asset Manager > Bulk
Import) and put the ids in `UPLOADED` at the top of `src/shared/VFX/SackAura.luau`; until then the
effects use Roblox's built-in particle textures.
