# Build every pair of a zone from its data module (zones/zoneNN_<name>.py), check the rarity part budgets and
# bake them into src/shared/Builders/Models/Baked/ZoneNN.luau (+ assets/blender/pets/ZoneNN.blend).
import importlib
import os

import bpy
from mathutils import Matrix, Vector

from . import anatomy as A
from . import egg as E
from .export import export_zone
from .features import FEATURES
from .plans import PLANS
from .rbx import C3, J, use

# docs/EggPetPlan.md rarity ladder (BaseParts, Root included for pets).
BUDGET = dict(
    Common=dict(pet=(25, 40), egg=(20, 30)),
    Uncommon=dict(pet=(35, 55), egg=(25, 35)),
    Rare=dict(pet=(55, 75), egg=(30, 45)),
    Epic=dict(pet=(75, 110), egg=(45, 60)),
    Legendary=dict(pet=(120, 160), egg=(55, 70)),
    Mythic=dict(pet=(160, 190), egg=(70, 90)),
    Divine=dict(pet=(190, 220), egg=(100, 125)),
    Secret=dict(pet=(220, 400), egg=(130, 200)),
)
SPACING = 12.0


def load(n):
    folder = os.path.join(os.path.dirname(os.path.dirname(__file__)), "zones")
    name = next(f[:-3] for f in os.listdir(folder) if f.startswith("zone%02d_" % n) and f.endswith(".py"))
    return importlib.import_module("zones." + name)


def variant(pair, patch):
    """Deep-merged copy of a pair with an option patch; `features` patches merge by feature name."""
    import copy

    out = copy.deepcopy(pair)

    def merge(a, b):
        for key, v in b.items():
            if key == "features":
                a["features"] = [(f, dict(p, **v[f]) if f in v else p) for f, p in a["features"]]
            elif isinstance(v, dict) and isinstance(a.get(key), dict):
                merge(a[key], v)
            else:
                a[key] = v

    merge(out, patch)
    return out


def _scale(coll, s):
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(s, 4) @ off.inverted() @ ob.matrix_world


def build_pet(pair, offset, name=None):
    pal = A.Pal(pair["palette"])
    k = A.Kit(pal)
    d = pair["pet"]
    coll = use(name or "PK_%s_Pet" % pair["key"], offset)
    ctx = {}
    PLANS[d["plan"]](k, d, ctx)
    for f, params in d.get("features", ()):
        FEATURES[f](k, ctx, **params)
    J("Root")
    if d.get("scale", 1) != 1:
        _scale(coll, d["scale"])
    return coll, pal


def build_egg(pair, offset, name=None):
    pal = A.Pal(pair["palette"])
    k = A.Kit(pal)
    coll = use(name or "PK_%s_Egg" % pair["key"], offset)
    E.build_egg(k, pair["egg"], pair["rarity"])
    if pair["egg"].get("scale", 1) != 1:
        _scale(coll, pair["egg"]["scale"])
    return coll


def check(pair, pet_n, egg_n):
    b = BUDGET[pair["rarity"]]
    pet_n += 1  # BlockBuilder adds the Root part
    msg = []
    for kind, n in (("pet", pet_n), ("egg", egg_n)):
        lo, hi = b[kind]
        if not lo <= n <= hi:
            msg.append("%s %s %d outside %d-%d" % (pair["key"], kind, n, lo, hi))
    return pet_n, msg


def clear(prefix="PK_"):
    for c in [c for c in bpy.data.collections if c.name.startswith(prefix)]:
        for ob in list(c.objects):
            bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.collections.remove(c)


def build_zone(n, keys=None, out=None, save=True, repo=None):
    from . import stage

    Z = load(n)
    clear()
    stage.setup_stage(Z.ZONE.get("ground", "5DAE4A"))
    report, baked = [], []
    for i, pair in enumerate(Z.PAIRS):
        if keys and pair["key"] not in keys:
            continue
        x = (i - (len(Z.PAIRS) - 1) / 2) * SPACING
        pet, pal = build_pet(pair, (x, 0, 0))
        egg = build_egg(pair, (x, 0, -9))
        pn, msg = check(pair, len(pet.objects), len(egg.objects))
        report.append("%s: pet %d, egg %d %s" % (pair["key"], pn, len(egg.objects), "; ".join(msg)))
        baked.append(dict(key=pair["key"], title=pair["title"], palette={k.upper(): v for k, v in pal.d.items()},
                          egg=egg.name, pet=pet.name))
    if not keys:
        path = out or "%s/src/shared/Builders/Models/Baked/Zone%02d.luau" % (repo, n)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        export_zone(path, Z.HEADER, baked)
        if save:
            os.makedirs(repo + "/assets/blender/pets", exist_ok=True)
            bpy.ops.wm.save_as_mainfile(filepath="%s/assets/blender/pets/Zone%02d.blend" % (repo, n), compress=True,
                                        copy=True)
    print("\n".join(report))
    return report


def make_sprites(n, folder):
    Z = load(n)
    for name, fn in Z._sprites().items():
        fn(folder + "vfx_%s.png" % name)
