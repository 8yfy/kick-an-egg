# Check renders (Blender EEVEE, sunny stage, grass) of a zone's pets and eggs into tools/blender/pets/out/
# (gitignored). Studs only show in Studio; final approval shots come from Studio.
#   python -I bmcp.py code preview.py -- what=zone1 [keys=SproutPup] [views=front34,side,back34] [build=0]
#   python -I bmcp.py code preview.py -- what=frost
import os

from kit import stage, zone

OUT = REPO + "/tools/blender/pets/out/"
os.makedirs(OUT, exist_ok=True)
what = ARGS.get("what", "zone1")
VIEWS = {"front34": (-10, 6.8, -12.5), "side": (16, 5, -0.5), "back34": (10.5, 7.5, 11), "front": (0, 5, -16)}
views = ARGS.get("views", "front34,side,back34").split(",")
res = int(ARGS.get("res", "560"))

if what == "frost":
    from heroes import frost_serpent as fs

    zone.clear("FS_")
    stage.setup_stage()
    fs.build_serpent("FS_Pet", (0, 0, 0))
    fs.build_egg("FS_Egg", (10, 0, 0))
    targets = [("FS_Pet", (0, 0, 0), 4.2, 1.0), ("FS_Egg", (10, 0, 0), 2.6, 0.62)]
    tag = "frost_serpent"
else:
    Z = zone.load(int(what.replace("zone", "")))
    keys = ARGS.get("keys")
    keys = keys.split(",") if keys else [p["key"] for p in Z.PAIRS]
    targets = []
    if ARGS.get("options") == "1":  # A/B matters of taste: pets side by side, labelled
        zone.clear()
        stage.setup_stage(Z.ZONE.get("ground", "5DAE4A"))
        for pair in Z.PAIRS:
            for opt, patch in [("A", {})] + sorted(getattr(Z, "OPTIONS", {}).get(pair["key"], {}).items()):
                if pair["key"] not in keys or (opt == "A" and pair["key"] not in getattr(Z, "OPTIONS", {})):
                    continue
                pet, _ = zone.build_pet(zone.variant(pair, patch), (0, 0, 0), "PK_%s_%s" % (pair["key"], opt))
                h = max((o.matrix_world.translation.z + o.dimensions.z / 2 for o in pet.objects), default=3)
                targets.append((pet.name, (0, 0, 0), h * 0.47, 0.12 + h * 0.085))
        views = ARGS.get("views", "front34,side").split(",")
        keys = ["options"]
    elif ARGS.get("build", "1") != "0":
        zone.build_zone(int(what.replace("zone", "")), keys, save=False, repo=REPO)
    for key in keys if keys != ["options"] else ():
        pet = bpy.data.collections["PK_%s_Pet" % key]
        egg = bpy.data.collections["PK_%s_Egg" % key]
        h = max((o.matrix_world.translation.z + o.dimensions.z / 2 for o in pet.objects), default=3)
        targets.append((pet.name, tuple(pet["rbx_offset"]), h * 0.47, 0.12 + h * 0.085))
        targets.append((egg.name, tuple(egg["rbx_offset"]), 2.4, 0.55))
    tag = what + ("_" + "_".join(keys) if ARGS.get("keys") or keys == ["options"] else "")
shots = []
for name, off, ty, zoom in targets:
    stage.only([name])
    for v in views:
        e = VIEWS[v]
        p = OUT + "%s_%s.png" % (name, v)
        stage.shoot(p, (off[0] + e[0] * zoom, e[1] * zoom * 0.9 + ty * 0.4, off[2] + e[2] * zoom), (off[0], ty, off[2]),
                    res=(res, res), lens=45)
        shots.append(p)
stage.sheet(shots, len(views) * 2, OUT + "%s_sheet.png" % tag)
print(OUT + "%s_sheet.png" % tag)
