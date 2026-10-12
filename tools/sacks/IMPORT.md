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
4. Save the place (Ctrl+S), or right-click `ReplicatedStorage > SackAssets` > **Save to File...** as
   `assets/sacks/SackAssets.rbxm`. From a saved place, extract it with
   `lune run tools/sacks/extract-sackassets.luau KickTheEgg.rbxl assets/sacks/SackAssets.rbxm`.
5. **Restore the original part names.** One import de-duplicates names across all 20 sacks (`ceiling_mount3`,
   `chain_link_03`, `..._Node`), so SackColors and SackAura can't find most parts. Fix the rbxm by geometry
   (each part's world bounds against its GLB node's; one 180° yaw for the whole import, worst match 0.06 studs):
   ```
   "<Blender>/4.5/python/bin/python.exe" -I tools/sacks/glb_nodes.py assets/sacks/glb <tmp>/glb-node-bounds.json
   lune run tools/sacks/fix-import-names.luau assets/sacks/SackAssets.rbxm <tmp>/glb-node-bounds.json
   ```
6. `default.project.json` maps `ReplicatedStorage.SackAssets` to that rbxm, so every Rojo build and sync has the
   imports. Reconnect Rojo (or rebuild the place) to replace the importer-named copy in your open session.

The committed `assets/sacks/SackAssets.rbxm` is the result of these steps (20 sacks, 1,900 MeshParts, all names
restored). Redo them only for a fresh import, e.g. from a different account or group.

## Inspecting (Studio only, chat)

- `/showroom`: one sack at a time in front of you: PREV / NEXT (or the , and . keys), VFX on/off, VIEW game (what
  players see) / package (SackModel, 10 studs/m), ORBIT camera. The info line says whether the geometry is the
  original GLB import and how many parts got their original GLB material.
- `/showcase game`: all 20 the way players see them. `/showcase`: the package demo (SackModel + SackVFX, strict GLB
  mode once imported). `/showcase basic`: the package's own simpler effects (SackVFXBasic) for comparison.
- `/sack <1-20>`: your own gear sack. `/cash <amount>`: money.

## Sprites (VFX textures)

**Uploaded** (Krono808, 2026-10-12, Creator Hub > Development items > Images; all 13 load in Studio). The ids are in
`src/shared/VFX/SackAura.luau` (`UPLOADED`, the effects the game and SackModules/SackVFX use) and
`src/sackmodules/SackTextures.luau` (`IDs`, SackVFXBasic). Use the **Image** ids (asset type 1), not the Decal ids
the upload panel shows. To re-upload (e.g. under a group that owns the game): upload the 13 PNGs in
`assets/sack-vfx/` and replace the ids. Without ids, Studio shows a local copy (`tools/preview/stage-art.sh`) and
live servers fall back to Roblox's built-in particles with a warning per sprite.

## Checks

- `SackGeometry.imported()` = 20; sack models carry `GeometrySource = "GLB"` and `MatchedGLBMaterials` equal to
  their part count (server tests check tiers 1, 7, 17 and 20).
- Mesh assets must be usable by the experience's owner (import with the account or group that owns the game).
