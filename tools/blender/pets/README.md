# Frost Serpent: Blender source for a block-data hero pet

The Frost Serpent (pair 23, Legendary) is modelled in Blender, but **only from Roblox primitives**. Every Blender object
is one BlockBuilder part: a unit Block / Wedge / Ball / Cylinder in Roblox axes. So the scene is exactly what
`BlockBuilder` builds in game, and the shipped model stays block data (CLAUDE.md rule 3). There are no meshes and
no uploads for the model.

| File | What it does |
|---|---|
| `fs_lib.py` | Roblox <-> Blender axes (Roblox +Y up, front -Z; Blender z-up), CFrame helpers, unit primitive meshes, materials. Parts carry `rbx_*` custom properties (shape, joint, material, colour, studs, transparency, order). Also stepped crystals, any-triangle-from-two-wedges, and Catmull-Rom / arc-length curve helpers. |
| `fs_serpent.py` | The pet. A spine curve (a ground coil of 1.15 turns rising in an S) sampled into 24 studded segments with belly plates and dorsal wedges. Also the head (antlers, mane, frills, whiskers, almond eyes, teeth), arms, wings (shoulder-elbow-wrist, four fingers, six glass membranes), a chest core and hidden joint hinges. Built at scale 1.15. |
| `fs_egg.py` | The egg. `Shell<n>` layers identical to `Sculpt.eggShell` (4.8 x 3.6), a frost cap with a drip line, a coil spiralling up the shell, a snow line, and antlers with a crown crystal. |
| `fs_export.py` | Bakes the `FS_Egg` / `FS_Pet` collections into `Premium/FrostSerpent.luau` (`S.part` calls, palette constants, CRLF). |
| `fs_textures.py` | Draws the six original VFX sprites with numpy: `vfx_frost_{sigil,rune_ring,spark,flake,mist,cube}.png`. |
| `fs_scene.py` | Preview stage (sun, sky, grass), camera shots and numpy contact sheets. |
| `build.py` / `preview.py` | Drivers: rebuild + export + save `assets/blender/FrostSerpent.blend`, or turntable renders into `out/`. |
| `bmcp.py` | Sends scripts to the live Blender GUI through the MCP for Blender add-on (127.0.0.1:9876). This is the same bridge the Blender MCP server uses. |

## Rebuild

1. Open Blender 5.2 with the "MCP for Blender" add-on enabled. Its server auto-starts on port 9876, telemetry off.
2. From this folder:

   ```sh
   python -I bmcp.py code fs_lib.py fs_scene.py fs_serpent.py fs_egg.py fs_export.py fs_textures.py build.py
   ```

   With the Blender MCP server connected you can instead paste the same files, in that order, into
   `execute_blender_code`. Define `REPO` first.
3. Format the baked file. StyLua needs a few passes on generated tables:

   ```sh
   stylua --line-endings Windows src/shared/Builders/Models/Premium/FrostSerpent.luau
   ```

4. Check it in Studio: build the egg and pet with `BlockBuilder.build`. The server tests also check the rarity ladder
   (85-173 parts), the egg shell size and the effect recipe.

## Constraints the model respects

- Part count: 170 BaseParts including Root. That is more than Tide Spirit (Epic) and fewer than Quetzal Phoenix
  (Mythic), as the hero ladder test requires.
- Joints: `Coil`, `Body`, `Head`, `ArmL/R`, `WingL/R`. Each group's first part is its hinge: an invisible `Hinge*`
  part, or the wing's shoulder ball. `Anim/Pet` switches to its serpent poses when a rig has a `Coil` motor: the coil
  stays put while the body sways and the head, wings and arms ride along.
- Eyes follow the Kit convention (`EyeL/R`, `GlintL/R`, plus `PupilL/R`), so blinking works.
- Palette (approved "Glacier"): hide #2F7FE0, armour #163E9A, frost white #E6F6FF, ice crystal #9EEBFF (Glass),
  membranes #6CC2F7 / #CBEFFF (Glass), eye glow #4FE8FF (Neon). Neon is used only on eyes, the core, beads and
  crystal tips.
