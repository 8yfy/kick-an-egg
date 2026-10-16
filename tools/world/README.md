# tools/world: world remodel tooling (Partner A)

The in-game world is **Luau brick recipes** (`src/shared/Builders/Map/World/Recipes`), so you do not need any of these
tools to build or change the map. Edit a recipe or a zone file and the map rebuilds at server start.

## VFX sprites (in use)

| File | Purpose |
|---|---|
| `sprites.py` | Draws the 20 original particle sprites into `assets/world-vfx/wfx_*.png`.<br>Needs Pillow; run `python tools/world/sprites.py`. |
| `sprite_sheet.py` | Contact sheet of the sprites for review. |
| `upload.py` | Open Cloud uploader for images and models. The key is read from the `ROBLOX_API_KEY` user environment variable and is never printed.<br>Run `python tools/world/upload.py --creator 1340874349 --type Decal assets/world-vfx/*.png --out tools/world/ids/sprites.json`.<br>Then copy the ids into `src/shared/VFX/WorldSprites.luau`. |

## Dev deploy without the Rojo plugin

1. `sh tools/world/deploy.sh` builds `deploy.project.json` (Shared / Server / Client) into Studio's `content/kte/` folder and prints an `rbxasset://` path.
2. Run `deploy.luau` in Studio (command bar or MCP `execute_luau`, Edit) with that path. It swaps the three folders in the open place.

Use this when the Rojo plugin will not reconnect.

## Mesh pipeline (built and verified, **not used in game**)

These tools were built before the classic-brick decision. Nothing in the game references the uploaded meshes.

| Step | Tool |
|---|---|
| 1. Model low-poly kits headless | Blender: `blender/kit.py` (helpers), `lib_*.py` (models), `kits.py` / `build_kit.py` (one FBX per model into `out/`, `global_scale 0.01`).<br>`pipeline_test.py` and `style_test.py` are the first probes. |
| 2. Upload the FBX files as Models | `upload.py --type Model`. |
| 3. Pair names with MeshIds | `pair_ids.py` and `merge_patch.py`, using `ids/*.meshes.txt`. |
| 4. Assemble a model library | `lune/assemble.luau` writes it as an rbxm. Use `MeshContent`, since lune cannot set `MeshId`.<br>`probe.luau` and `inspect.luau` are debugging aids. |

`out/`, `blend/` and `ids/*.studio.txt` are generated and git-ignored.
