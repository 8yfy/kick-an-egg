# Kick Sacks: importing the original GLBs into Roblox Studio (one-time)

The game uses the ORIGINAL GLB geometry as soon as the imports exist (`Builders/SackGeometry` for the gear sack
and base stands, `SackModules/SackModel` for the package API); until then it falls back to the part-built remodel.
Importing uploads the meshes to your Roblox account, so only you can do it, in Studio. Imported meshes are allowed
(CLAUDE.md hard rule 3).

## Files

- `assets/sacks/KickSacks_ALL_20.glb` (7 MB): all 20 sacks in one file, built by `tools/sacks/merge_glb.py`.
  The merge is lossless: glTF JSON + binary concatenated with offsets, nothing re-exported. Each sack's original
  nodes sit under a group `Sack_01` .. `Sack_20`. **Pivots/offsets: none.** Every group has an identity transform,
  so each sack keeps its own source origin (the bag bottom, metres, Y up, front +Z); all 20 overlap at the origin
  in the file, exactly as in their 20 source files. The validator checks, per sack, that node names, transforms,
  materials (incl. KHR_materials_clearcoat / emissive_strength) and the geometry bytes are identical.
- `assets/sacks/glb/kick-sack-NN-*.glb`: the 20 originals (backups; also importable one by one).
  Both are gitignored (large binaries); rebuild the merged file with
  `"<Blender>/4.5/python/bin/python.exe" -I tools/sacks/merge_glb.py assets/sacks/glb assets/sacks/KickSacks_ALL_20.glb`.

## Steps

1. Open the place in Studio. **Disconnect the Rojo plugin** while importing.
2. **File > Import 3D**, pick `KickSacks_ALL_20.glb`, keep the defaults (keep hierarchy, part names, materials)
   and Import. Check the Output window for warnings. If Studio refuses the big file, import the 20 originals in
   `assets/sacks/glb/` one by one.
3. **View > Command Bar**: paste `tools/sacks/ImportRename.commandbar.lua`, press Enter. It moves the sacks to
   `ReplicatedStorage > SackAssets > Meshes` as `Sack_01` .. `Sack_20` and reports `20 of 20`.
4. Right-click `ReplicatedStorage > SackAssets` > **Save to File...** as `assets/sacks/SackAssets.rbxm` in this repo
   (so Rojo builds keep the imports). Tell Claude: it adds the one-line Rojo mapping and verifies all 20 in Studio.

## Inspecting (Studio only, chat)

- `/showroom`: one sack at a time in front of you: PREV / NEXT (or the , and . keys), VFX on/off, VIEW game (what
  players see) / package (SackModel, 10 studs/m), ORBIT camera. The info line says whether the geometry is the
  original GLB import and how many parts got their original GLB material.
- `/showcase game`: all 20 the way players see them. `/showcase`: the package demo (SackModel + SackVFX, strict GLB
  mode once imported). `/showcase basic`: the package's own simpler effects (SackVFXBasic) for comparison.
- `/sack <1-20>`: your own gear sack. `/cash <amount>`: money.

## Sprites (VFX textures)

Upload the 13 PNGs in `assets/sack-vfx/` (View > Asset Manager > Images > Bulk Import) and paste the ids into
`src/shared/VFX/SackAura.luau` (`UPLOADED`, the effects the game and SackModules/SackVFX use) and
`src/sackmodules/SackTextures.luau` (`IDs`, SackVFXBasic). Until then Studio shows them from a local copy
(`tools/preview/stage-art.sh`) and live servers fall back to Roblox's built-in particles with a warning per sprite.

## Checks

- `SackGeometry.imported()` = 20; sack models carry `GeometrySource = "GLB"` and `MatchedGLBMaterials` > 0.
- Mesh assets must be usable by the experience's owner (import with the account or group that owns the game).
