# Rebuild pets + eggs in the live Blender scene and bake them to BlockBuilder block data (Luau).
#   python -I bmcp.py code build.py -- what=zone1               # zones/zone01_*.py -> Models/Baked/Zone01.luau
#   python -I bmcp.py code build.py -- what=zone1 keys=SproutPup  # rebuild only those pairs in Blender (no bake)
#   python -I bmcp.py code build.py -- what=frost               # heroes/frost_serpent.py -> Premium/FrostSerpent.luau
# Options: out=<path> bakes somewhere else (identity checks), save=0 skips the .blend, textures=1 redraws sprites.
# Then format the Luau with StyLua (README.md).
import os

from kit import sprites, stage

what = ARGS.get("what", "zone1")
save = ARGS.get("save", "1") != "0"

if what == "frost":
    from heroes import frost_serpent as fs
    from kit.export import export_luau

    for c in [c for c in bpy.data.collections if c.name.startswith("FS_")]:
        for ob in list(c.objects):
            bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.collections.remove(c)
    stage.setup_stage()
    fs.build_serpent("FS_Pet", (0, 0, 0))
    fs.build_egg("FS_Egg", (8, 0, 0))
    G = fs.PALETTES["glacier"]
    names = {"HIDE": G["HIDE"], "HIDE2": G["HIDE2"], "ARMOR": G["ARMOR"], "WHITE": G["WHITE"], "ICE": G["ICE"],
             "TIP": G["TIP"], "MEM_D": G["MEM_D"], "MEM_L": G["MEM_L"], "EYE": G["EYE"], "SOCKET": G["SOCKET"],
             "PUPIL": G["PUPIL"], "FANG": G["FANG"], "SHELL": fs.EGG_SHELL, "GLINT": "FFFFFF"}
    HEADER = '''--!strict
-- 23 Frost Serpent (Snowy Peaks, Legendary). Replaces the Ice Dragon; the pet id stays `ice_dragon` (saves).
-- Hero model (docs/EggPetPlan.md): a glacier-blue serpent coiled on the ground and rising in an S to a long
-- studded head with antlers, a crystal mane, an almond-eyed "cool" face and two-tone glass wings.
-- Egg: blue shell under a white frost cap whose edge drips down the shell, a serpent coil spiralling up it with
--      crystal fins, a snow line at the base and two small antlers either side of a crown crystal.
-- BAKED FILE: modelled in Blender from Roblox primitives (assets/blender/FrostSerpent.blend) and exported by
-- tools/blender/pets (heroes/frost_serpent.py, see its README). Change the model there and re-export, not by hand.
-- Joints: Coil, Body, Head, ArmL/ArmR, WingL/WingR; each group starts with its hinge (Anim/Pet serpent poses).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
    out = ARGS.get("out", REPO + "/src/shared/Builders/Models/Premium/FrostSerpent.luau")
    print(export_luau(out, HEADER, names, G))
    if save:
        os.makedirs(REPO + "/assets/blender", exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=REPO + "/assets/blender/FrostSerpent.blend", compress=True, copy=True)
    if ARGS.get("textures") == "1":
        sprites.make_all(REPO + "/assets/pet-vfx/")
else:
    from kit import zone as Z

    n = int(what.replace("zone", ""))
    keys = ARGS.get("keys")
    Z.build_zone(n, keys.split(",") if keys else None, out=ARGS.get("out"), save=save, repo=REPO)
    if ARGS.get("textures") == "1":
        Z.make_sprites(n, REPO + "/assets/pet-vfx/")
print("built", what)
