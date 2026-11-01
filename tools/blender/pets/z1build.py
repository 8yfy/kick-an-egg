# Zone 1 Meadow production batch (2026-11-01, the user's 8-pet handoff): build a Meadow pet and/or its egg in the
# live Blender scene from Roblox primitives (the Frost Serpent method), render review sheets and bake the pair to a
# BlockBuilder file in KickAnEgg_PremiumPets/Zone01_Meadow/<Name>/ (a preview candidate: nothing is wired into
# Models/* or Config until the user approves).
#   python -I bmcp.py code z1build.py -- what=Piproot [kind=pet|egg|both] [views=...] [zoom=1] [res=480] [tag=]
#   python -I bmcp.py code z1build.py -- what=Piproot kind=both export=1
import importlib
import json
import os

from mathutils import Vector

from kit import stage
from kit.export import export_luau

# model key -> (module, folder name)
PETS = {
    "Piproot": ("zone1.piproot", "Piproot"),
    "HoneybackBeetle": ("zone1.honeyback_beetle", "HoneybackBeetle"),
    "Crownstag": ("zone1.crownstag", "Crownstag"),
    "ThistlebackHedgehog": ("zone1.thistleback_hedgehog", "ThistlebackHedgehog"),
    "BloomcrestCrane": ("zone1.bloomcrest_crane", "BloomcrestCrane"),
    "BurrowMonarch": ("zone1.burrow_monarch", "BurrowMonarch"),
    "WalkingOrchard": ("zone1.walking_orchard", "WalkingOrchard"),
    "FirstSeed": ("zone1.first_seed", "FirstSeed"),
}
what = ARGS.get("what", "Piproot")
kind = ARGS.get("kind", "pet")
OUT = REPO + "/tools/blender/pets/out/z1/"
ZONE = REPO + "/KickAnEgg_PremiumPets/Zone01_Meadow/"
os.makedirs(OUT, exist_ok=True)

pet_mod = importlib.import_module(PETS[what][0])
egg_mod = importlib.import_module("zone1.eggs")
built = {}
if kind in ("pet", "both"):
    built["pet"] = pet_mod.build("Z1_%s_Pet" % what, (0, 0, 0))
if kind in ("egg", "both"):
    built["egg"] = egg_mod.build(what, "Z1_%s_Egg" % what, (12 if kind == "both" else 0, 0, 0))


def bounds(coll):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for ob in coll.objects:
        if ob.get("rbx_transparency", 0) >= 0.99:
            continue
        for v in ob.bound_box:
            w = ob.matrix_world @ Vector(v)
            lo, hi = Vector(map(min, lo, w)), Vector(map(max, hi, w))
    return lo, hi


for kk, coll in built.items():
    n = len(coll.objects) + (1 if kk == "pet" else 0)
    lo, hi = bounds(coll)
    size = hi - lo
    print("%s %s: %d BaseParts%s, %.2f wide x %.2f tall x %.2f long, lowest %.2f (studs)" % (
        what, kk, n, " incl. Root" if kk == "pet" else "", size.x, hi.z, size.y, lo.z))

if ARGS.get("render", "1") == "1":
    stage.setup_stage("5DAE4A")
    views = {"front34": (-0.55, 0.35, -0.75), "side": (1, 0.12, 0), "back34": (0.6, 0.45, 0.65),
             "high34": (-0.5, 0.75, -0.55), "top": (0.02, 1, -0.12), "game": (-0.42, 0.55, -0.85),
             "front": (0, 0.15, -1), "back": (0, 0.2, 1), "side34": (-0.85, 0.3, -0.4)}
    pick = ARGS.get("views", "front34,front,side,back34").split(",")
    rs = int(ARGS.get("res", "480"))
    for kk, coll in built.items():
        for c in bpy.data.collections:
            if c.name.startswith(("PK3_", "PK_", "FS_", "PREMIUM_", "Z1_")):
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
    folder = ZONE + PETS[what][1] + "/"
    os.makedirs(folder + "Source", exist_ok=True)
    pal = dict(egg_mod.PALS[what])
    pal.update(pet_mod.PAL)
    names = {k.upper(): v for k, v in pal.items()}
    names.setdefault("GLINT", "FFFFFF")
    counts = export_luau(folder + "%s.luau" % what, pet_mod.HEADER, names, egg_coll=built["egg"].name,
                         pet_coll=built["pet"].name)
    lo, hi = bounds(built["pet"])
    meta = dict(key=what, name=pet_mod.NAME, rarity=pet_mod.RARITY, zone="Meadow", concept=pet_mod.CONCEPT,
                pet_parts=counts["pet"] + 1, egg_parts=counts["egg"],
                pet_size_studs=[round(x, 2) for x in (hi - lo)],
                joints=sorted({o["rbx_joint"] for o in built["pet"].objects}),
                egg_joints=sorted({o["rbx_joint"] for o in built["egg"].objects}),
                status="model approved by the user 2026-11-01; not wired into the game yet")
    with open(folder + "%s.meta.json" % what, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    bpy.ops.wm.save_as_mainfile(filepath=folder + "Source/%s_blocks.blend" % what, compress=True, copy=True)
    print("exported", folder, counts)
