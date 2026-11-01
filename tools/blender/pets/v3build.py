# V3 benchmark batch (blocks, Frost Serpent method): build a pet and/or its egg in the live Blender scene, render
# review sheets and bake the pair to a BlockBuilder file in KICK_AN_EGG_PET_REMODEL_V3/ (a preview candidate: not
# wired into Models/*; wire it after approval by moving it into Builders/Models/Premium).
#   python -I bmcp.py code v3build.py -- what=SproutPup [kind=pet|egg|both] [views=...] [zoom=1] [res=480]
#   python -I bmcp.py code v3build.py -- what=SproutPup kind=both export=1
# Views follow the vault's silhouette test (side, front three-quarter, high three-quarter, top) plus the pen camera.
import importlib
import json
import os

from mathutils import Vector

from kit import stage
from kit.export import export_luau

what = ARGS.get("what", "SproutPup")
kind = ARGS.get("kind", "pet")
MODS = {"SproutPup": "v3.clover_pup", "MeadowStag": "v3.blossom_stag", "TideSpirit": "v3.reef_crab",
        "HeavenLion": "v3.heaven_lion", "ClockworkTitan": "v3.clockwork_titan", "PrismSeraph": "v3.prism_seraph"}
DIRS = {"SproutPup": "02_SPROUT_PUP", "MeadowStag": "03_MEADOW_STAG", "TideSpirit": "04_TIDE_SPIRIT",
        "PrismSeraph": "11_PRISM_SERAPH", "ClockworkTitan": "12_CLOCKWORK_TITAN", "HeavenLion": "13_HEAVEN_LION"}
OUT = REPO + "/tools/blender/pets/out/v3/"
BATCH = REPO + "/KICK_AN_EGG_PET_REMODEL_V3/"
os.makedirs(OUT, exist_ok=True)

pet_mod = importlib.import_module(MODS[what])
egg_mod = importlib.import_module("v3.eggs_blocks")
built = {}
if kind in ("pet", "both"):
    built["pet"] = pet_mod.build("PK3_%s_Pet" % what, (0, 0, 0))
if kind in ("egg", "both"):
    built["egg"] = egg_mod.build(what, "PK3_%s_Egg" % what, (9 if kind == "both" else 0, 0, 0))


def bounds(coll):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for ob in coll.objects:
        for v in ob.bound_box:
            w = ob.matrix_world @ Vector(v)
            lo, hi = Vector(map(min, lo, w)), Vector(map(max, hi, w))
    return lo, hi


for kk, coll in built.items():
    n = len(coll.objects) + (1 if kk == "pet" else 0)
    lo, hi = bounds(coll)
    print("%s %s: %d BaseParts%s, %.2f tall (studs)" % (what, kk, n, " incl. Root" if kk == "pet" else "", hi.z))

if ARGS.get("render", "1") == "1":
    stage.setup_stage("5DAE4A")
    views = {"front34": (-0.55, 0.35, -0.75), "side": (1, 0.12, 0), "back34": (0.6, 0.45, 0.65),
             "high34": (-0.5, 0.75, -0.55), "top": (0.02, 1, -0.12), "game": (-0.42, 0.55, -0.85),
             "front": (0, 0.15, -1)}
    pick = ARGS.get("views", "front34,side,back34,high34,top").split(",")
    rs = int(ARGS.get("res", "480"))
    for kk, coll in built.items():
        for c in bpy.data.collections:
            if c.name.startswith(("PK3_", "PK_", "FS_", "PREMIUM_")):
                c.hide_render = c.name != coll.name
        lo, hi = bounds(coll)
        ctr = (lo + hi) / 2
        R = max((hi - lo).x, (hi - lo).y, (hi - lo).z)
        tgt = Vector((ctr.x, ctr.z, -ctr.y))  # Roblox coords for the stage helper
        shots = []
        for v in pick:
            d = Vector(views[v]).normalized()
            eye = tgt + d * R * (3.0 if v == "game" else 1.75) * float(ARGS.get("zoom", "1"))
            p = OUT + "%s_%s_%s.png" % (what, kk, v)
            stage.shoot(p, tuple(eye), tuple(tgt), res=(rs, rs), lens=50)
            shots.append(p)
        sheet = OUT + "%s_%s_sheet%s.png" % (what, kk, ARGS.get("tag", ""))
        stage.sheet(shots, len(shots), sheet)
        print(sheet)

if ARGS.get("export") == "1":
    assert "pet" in built and "egg" in built, "export needs kind=both"
    folder = BATCH + DIRS[what] + "/"
    os.makedirs(folder, exist_ok=True)
    pal = dict(egg_mod.PALS[what])
    pal.update(pet_mod.PAL)
    names = {k.upper(): v for k, v in pal.items()}
    names.setdefault("GLINT", "FFFFFF")
    counts = export_luau(folder + "%s.luau" % what, pet_mod.HEADER, names, egg_coll=built["egg"].name,
                         pet_coll=built["pet"].name)
    if ARGS.get("dest") == "premium":  # approved: also bake the game's spec, Builders/Models/Premium/<Key>.luau
        header = pet_mod.HEADER.replace(" V3 (", " (").replace(
            "Preview candidate (KICK_AN_EGG_PET_REMODEL_V3), not wired.", "Premium hero spec (docs/EggPetPlan.md).")
        export_luau(REPO + "/src/shared/Builders/Models/Premium/%s.luau" % what, header, names,
                    egg_coll=built["egg"].name, pet_coll=built["pet"].name)
        print("baked the game spec Premium/%s.luau" % what)
    meta = dict(key=what, version="V3 blocks", concept=pet_mod.CONCEPT, pet_parts=counts["pet"] + 1,
                egg_parts=counts["egg"], joints=sorted({o["rbx_joint"] for o in built["pet"].objects}),
                status="preview candidate, not wired")
    with open(folder + "%s.meta.json" % what, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    os.makedirs(REPO + "/assets/blender/pets", exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=REPO + "/assets/blender/pets/%s_V3.blend" % what, compress=True, copy=True)
    print("exported", folder, counts)
