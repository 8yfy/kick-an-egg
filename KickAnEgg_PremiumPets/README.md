# Kick an Egg: premium pets (Heavenly Lion, Prism Seraph, Clockwork Titan)

Three top-tier pets built to the user's concept images (`KICK_AN_EGG_PET_REMODEL_V3/00_REFERENCES`) in a "premium bricky
fantasy" style. They are made of chamfered geometric blocks, wedges, faceted crystals and plates, then merged into
optimized meshes with palette textures, a rig and three animations each. Every number below was measured from the
exported files.

**Status:** preview candidates waiting for approval. Nothing is wired into the game. The game still builds these pets
from BlockBuilder block data (`KICK_AN_EGG_PET_REMODEL_V3/11-13`), which is the same design. CLAUDE.md rule 3 says pets
stay block data unless both partners agree, so switching the game to these meshes is a decision for Partners A and B.

## Folder layout

```
KickAnEgg_PremiumPets/
  HeavenlyLion/ PrismSeraph/ ClockworkTitan/
    <Name>.blend          editable scene: the rig, the meshes, 3 actions, a camera and a light
    <Name>.fbx            rigged and skinned meshes, all 3 animations, embedded textures
    <Name>.glb            the same content as glTF 2.0 (Y up)
    Textures/             palette maps (see RobloxIntegration/MaterialSetup)
    Animations/           one armature-only FBX per clip (for Roblox's Animation Editor), a 4-frame strip per clip,
                          clip data (json)
    Previews/             hero 3/4, front, side, rear, gameplay distance, turnaround, Studio pen capture
    build.json            per-mesh joint, kind, colours, part and triangle counts, bone pivots (Roblox studs)
    validation.json       re-import check of the .fbx and the .glb
    RobloxPreview_<Name>.json  per-mesh triangles and colours, used to build the meshes in Studio for the preview
  RobloxIntegration/
    MaterialSetup/        how each mesh kind maps to Roblox materials
    AnimationNotes/       bones, clips and how to bring them into Roblox
    VFXSpecifications/    the matching PetFx effect layers
    studio_pen_all_three.jpg
```

## The pets

Sizes are in studs (1 Blender unit = 1 stud), width × height × depth. The pivot is the centre between the feet at
ground level, and the pet faces -Z (Roblox front).

| | Heavenly Lion | Prism Seraph | Clockwork Titan |
|---|---|---|---|
| Identity | majestic, royal, radiant | ethereal, crystalline, floating | massive, industrial, ancient |
| Size (W × H × D) | 6.7 × 10.7 × 10.4 | 12.1 × 12.1 (top; it floats about 1.1 above the ground) × 8.6 | 7.3 × 9.5 × 3.0 |
| Triangles | 16,568 | 17,616 | 16,748 |
| Meshes | 14 (7 solid, 7 glow) | 22 (7 solid, 8 glow, 7 crystal) | 20 (14 solid, 6 glow) |
| Materials | 2 (Solid, Glow) | 3 (Solid, Glow, Crystal) | 2 (Solid, Glow) |
| Bones | 8: Root, Body, Head, ArmL/R (front legs), LegL/R, Tail | 9: Root, Body, Head, ArmL/R, WingL/R, Halo, Orbit | 15: Root, Body, Head, ArmL/R, LegL/R, HeartHands, Gear1-7 |
| Clips | Idle 72 f, Walk 32 f, Special 60 f | Idle 72 f, Float 48 f, Special 60 f | Idle 72 f, Walk 40 f, Special 60 f |
| Source parts | 444 | 445 | 332 + 24 Roman numerals |

All three are inside the 8,000-18,000 triangle target.

### Signature features from the references

- **Heavenly Lion.**
  - Heroic quadruped: pillar legs, forearm and haunch mass, wide paws with gold claws.
  - A fierce lion face: wide short muzzle, heavy brow over glowing gold eyes, fangs, a gold diamond crest with a star.
  - A sunburst mane of layered rhombus scales (ivory, gold, glowing gold) with a crest, a collar and a chest bib.
  - The radiant chest star, wing-like flares off the shoulders, star and sun medallions, gold bracers.
  - A banded S-tail ending in a feathered sun, and a halo arc.
- **Prism Seraph.**
  - A floating armoured angel knight: a visor helm with glowing eyes and a gem crown, layered pauldrons, gauntlets
    with gold rings.
  - A star-heart chest crystal and tabards with crystal points.
  - Wings of faceted kite-shaped crystal feathers in six prism hues, each with a glowing core, on white and gold
    supports.
  - A halo arc with stars and a ring.
  - Orbiting diamond crystals and gold stars on their own bone.
- **Clockwork Titan.**
  - A brass and dark-iron colossus: a glowing amber clock heart ringed by gears, its hands on their own bone.
  - Seven chest gears, each on its own bone.
  - Shoulder clocks with Roman numerals, spired pauldrons, pistons and joint gears.
  - Burgundy banners with gold gear emblems, amber vents, heavy fists and boots, a helm with a glowing visor.

## How the meshes are built

- **Source.** The Blender scripts in `tools/blender/pets/v3/` build each pet from Roblox-style primitives (blocks,
  wedges, cylinders), the same data the game's BlockBuilder uses.
- **Pipeline.** `tools/blender/pets/premium.py` turns that build into the deliverables:
  - **Bevel:** every block, wedge and cylinder edge sharper than 30° gets a one-segment chamfer of up to 0.06 studs.
    Thin plates get a proportionally smaller one. Studs are dropped.
  - **Merge:** one mesh per bone and kind (Solid, Glow, Crystal), so pieces that move together are one draw call.
  - **Palette textures:** UVs point at 32 px cells of a 256 × 256 palette, so colours never split a mesh. Solid meshes
    get colour, metalness and roughness maps. Gold and brass are metallic; iron is semi-metallic.
  - **Rig:** bones sit at the BlockBuilder joint pivots and use the same names as the game's Motor6Ds. Skinning is
    rigid: each mesh is 100% weighted to its bone. Spinning parts (clock hands, gears) get their own bones.
  - **Animations:** procedural keyframes, sampled every 4 frames at 30 fps. Loops repeat seamlessly, and spinning
    parts complete a whole turn per loop.
- **Rebuild everything:**

```bash
cd tools/blender/pets
python -I bmcp.py code premium.py -- what=HeavenLion steps=build,anim,export,validate,preview
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python blend_scene.py -- ../../../KickAnEgg_PremiumPets/HeavenlyLion HeavenlyLion
```

(`what=PrismSeraph` / `ClockworkTitan`. The live Blender needs the MCP add-on on port 9876. Previews render as PNG;
`to_jpg.py` converts them to JPEG for the repo. `blend_scene.py` writes
the clean `.blend` in a background Blender, because writing a Scene with `bpy.data.libraries.write` crashes Blender 5.2.)

## Export settings

- **FBX:**
  - Axes: forward `Z`, up `Y`, so the pet's front comes out as -Z.
  - `FBX_SCALE_ALL`, no leaf bones, deform bones only, flat face normals.
  - Every action baked as a take; textures embedded (`path_mode=COPY`).
  - The per-clip files in `Animations/` carry one take each.
- **GLB:** Y up, skins, `ACTIONS` animation mode. The export first removes any other pet's actions, because that mode
  exports every compatible action in the file. Metalness and roughness are packed into one glTF metallic-roughness
  texture.

## Validation (`validation.json`)

Both files were re-imported into Blender and compared with the source:

| | Lion FBX / GLB | Seraph FBX / GLB | Titan FBX / GLB |
|---|---|---|---|
| Skinned meshes | 14 / 14 | 22 / 22 | 20 / 20 |
| Triangles | 16,568 / 16,568 | 17,616 / 17,616 | 16,748 / 16,748 |
| Bones | 8 / 8 | 9 / 9 | 15 / 15 |
| Clips | 3 / 3 | 3 / 3 | 3 / 3 |
| Size matches the source | yes / yes | yes / yes | yes / yes |

- **The `.blend` files** were reopened in a separate Blender: each has one scene, the rig, the meshes, 3 actions, and
  textures resolving to `//Textures/`.
- **Roblox Studio:** each pet's exported geometry was built from `RobloxPreview_<Name>.json` with `EditableMesh` and
  placed in a real pen under game lighting (`Previews/*_studio_pen.jpg`). That confirmed the geometry, placement,
  vertex colours and the Neon and Glass splits. It did not exercise the FBX/GLB importer, textures, the rig or clip
  import (next section).

## Known issues and open points

- **Roblox 3D Importer not yet run.** File > Import 3D can't be driven from a script. The .fbx/.glb still need one
  manual import to confirm scale, SurfaceAppearance textures and the skinned rig. The import scale should give the
  sizes in the table above.
- **Glow meshes use one palette texture for several glow colours** (MaterialSetup has the fallback if Neon ignores it).
- **Overlapping pieces.** Each merged mesh is a kitbash of closed pieces that overlap, rather than a single boolean
  shell. That renders correctly. Use Box or Hull collision (pets are non-colliding in pens anyway).
- **EditableMesh winding.** Roblox's EditableMesh treats the opposite triangle winding as front-facing, so the Studio
  preview loader flips each triangle. The FBX/GLB files use standard winding.
- **Not wired.** The mesh pets are not hooked into `Models.pet()`, the pens or the inventory. See AnimationNotes for
  the two ways to do it, and the CLAUDE.md rule 3 decision above.
