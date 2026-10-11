# Importing the original Kick Sack GLBs (one-time, in Roblox Studio)

The game already uses the original GLB geometry as soon as the imports exist (Builders/SackGeometry); until then
it falls back to the part-built remodel. Importing uploads the meshes to your Roblox account, so it has to be done
by you in Studio (imported meshes are allowed: CLAUDE.md hard rule 3).

**One file for all 20 sacks:** `assets/sacks/kick-sacks-all.glb` (6 MB, made by `tools/sacks/combine.py` from the
20 originals in `assets/sacks/glb/`; both gitignored, rebuild with the command in combine.py).

1. Open the place in Studio. **Disconnect the Rojo plugin** while importing.
2. **File > Import 3D**, pick `kick-sacks-all.glb`, keep the defaults (keep the hierarchy, part names and
   materials) and Import. It arrives in Workspace as one model holding Sack_01 .. Sack_20. Check the Output window
   for import warnings. (If Studio refuses the big file, import the 20 files in `assets/sacks/glb/` one by one.)
3. **View > Command Bar**: paste the contents of `tools/sacks/ImportRename.commandbar.lua` and press Enter. It moves
   the sacks to `ReplicatedStorage > SackAssets > Meshes` as `Sack_01` .. `Sack_20`, restores the original part
   names and warns about anything missing.
4. Right-click `ReplicatedStorage > SackAssets` > **Save to File...** and save it as
   `assets/sacks/SackAssets.rbxm` in this repo (so Rojo builds keep the imports). Tell Claude: it adds the one-line
   Rojo mapping and verifies all 20 in Studio.
5. Play. In chat: `/showcase game` shows all 20 the way players see them, `/showcase` shows the package demo
   (strict GLB mode: it errors instead of substituting anything if an import is missing). `/sack <1-20>` switches
   your own gear sack.

## Sprites (VFX textures)

Upload the 13 PNGs in `assets/sack-vfx/` (Studio > View > Asset Manager > Images > Bulk Import) and paste the
image ids into `src/sackmodules/SackTextures.luau` (`IDs`, package VFX) and `src/shared/VFX/SackAura.luau`
(`UPLOADED`, the game's VFX). Until then Studio shows them from a local copy (`tools/preview/stage-art.sh`) and
live servers use Roblox's built-in particle textures.

## Checks

- `SackGeometry.imported()` = 20; each sack model has `GeometrySource = "GLB"` and `MatchedGLBMaterials` > 0.
- Mesh assets must be usable by the experience's owner (import with the account or group that owns the game).
