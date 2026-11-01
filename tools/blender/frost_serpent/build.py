# Rebuild the Frost Serpent pet + egg in the live Blender scene, bake them into the BlockBuilder table
# (src/shared/Builders/Models/Premium/FrostSerpent.luau) and save assets/blender/FrostSerpent.blend.
# Run from this folder (REPO is prepended by bmcp.py):
#   python -I bmcp.py code fs_lib.py fs_scene.py fs_serpent.py fs_egg.py fs_export.py fs_textures.py build.py
# then format the Luau file with StyLua (see README.md). TEXTURES = True also redraws assets/pet-vfx/vfx_frost_*.png.
import os

TEXTURES = False

for c in [c for c in bpy.data.collections if c.name.startswith("FS_")]:
    for ob in list(c.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    bpy.data.collections.remove(c)
setup_stage()
build_serpent("FS_Pet", (0, 0, 0))
build_egg("FS_Egg", (8, 0, 0))
G = PALETTES["glacier"]
names = {"HIDE": G["HIDE"], "HIDE2": G["HIDE2"], "ARMOR": G["ARMOR"], "WHITE": G["WHITE"], "ICE": G["ICE"],
         "TIP": G["TIP"], "MEM_D": G["MEM_D"], "MEM_L": G["MEM_L"], "EYE": G["EYE"], "SOCKET": G["SOCKET"],
         "PUPIL": G["PUPIL"], "FANG": G["FANG"], "SHELL": EGG_SHELL, "GLINT": "FFFFFF"}
HEADER = '''--!strict
-- 23 Frost Serpent (Snowy Peaks, Legendary). Replaces the Ice Dragon; the pet id stays `ice_dragon` (saves).
-- Hero model (docs/EggPetPlan.md): a glacier-blue serpent coiled on the ground and rising in an S to a long
-- studded head with antlers, a crystal mane, an almond-eyed "cool" face and two-tone glass wings.
-- Egg: blue shell under a white frost cap whose edge drips down the shell, a serpent coil spiralling up it with
--      crystal fins, a snow line at the base and two small antlers either side of a crown crystal.
-- BAKED FILE: modelled in Blender from Roblox primitives (assets/blender/FrostSerpent.blend) and exported by
-- tools/blender/frost_serpent (see its README). Change the model there and re-export instead of editing by hand.
-- Joints: Coil, Body, Head, ArmL/ArmR, WingL/WingR; each group starts with its hinge (Anim/Pet serpent poses).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
print(export_luau(REPO + "/src/shared/Builders/Models/Premium/FrostSerpent.luau", HEADER, names, G))
os.makedirs(REPO + "/assets/blender", exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=REPO + "/assets/blender/FrostSerpent.blend", compress=True, copy=True)
if TEXTURES:
    make_all(REPO + "/assets/pet-vfx/")
print("built")
