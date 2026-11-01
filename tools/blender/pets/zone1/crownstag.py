# Crownstag (Zone 1 Meadow, Rare): a blossoming crowned stag built to the user's reference (images/9.webp), Roblox
# primitives only (Frost Serpent method). A sturdy chestnut stag of studded blocks with cream patches, a big shaggy
# cream ruff down the throat and chest, cream socks and chunky gold hooves; a leafy mantle with pink five-petal flowers
# over the shoulders; a fluffy cream tail carried up; a chestnut head with cream cheeks and jaw, glowing gold eyes,
# big ears and a gold crown with a pink gem; wide branching antlers spreading to the sides, flowering pink at the tips
# among green leaves.
# Joints: Body, Neck, Head (antlers, ears, crown ride it), ArmL/R (front legs), LegL/R (hind legs), Tail.
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use

NAME, RARITY = "Crownstag", "Rare"
PAL = dict(main="8C4A24", main2="7A3F1E", dark="5A2E14", light="F4E3C4", glow="FFE066", cream="F4E3C4",
           cream2="E6CFA4", antler="6B3E22", antler2="5A3219", leaf="5FB544", leaf2="3E8E34", blossom="FF7EB6",
           blossom2="FFA6CF", bloomcore="FFC93C", gold="F0B93A", gold2="C48E22", gem="FF4FA0", nose="241A16",
           eye="FFD24A", ink="1E140E")
CONCEPT = "Crownstag: a chestnut stag with a shaggy cream ruff, wide flowering antlers, a gold crown with a pink gem"
HEADER = '''--!strict
-- Crownstag (Zone 1 Meadow, Rare). Zone 1 Meadow roster (Config/Pets).
-- Pet: a sturdy chestnut stag with cream patches, a big shaggy cream ruff down the throat and chest, cream socks and
--      gold hooves, a leafy mantle with pink flowers, a fluffy cream tail carried up, glowing gold eyes, big ears, a
--      gold crown with a pink gem and wide branching antlers flowering pink among green leaves.
--      Joints: Body, Neck, Head, ArmL/R, LegL/R, Tail.
-- Egg: a cream egg wrapped by chestnut branches with pink flowers and leaves, a gold crown with a pink gem on top.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/crownstag.py, zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.15


def flower(k, name, at, normal, size, petal="blossom", petal2="blossom2", centre="bloomcore"):
    """A five-petal flower facing `normal`: five petals round a glowing centre (6 parts)."""
    n = Vector(normal).normalized()
    c = look(Vector(at), n, (0, 1, 0) if abs(n.y) < 0.9 else (0, 0, 1))
    for i in range(5):
        a = 72 * i
        r = math.radians(a)
        k.p("%sPetal%d" % (name, i + 1), (size * 0.46, 0.1, size * 0.5),
            c * CF((math.sin(r) * size * 0.3, 0, -math.cos(r) * size * 0.3)) * cf(ry=-a),
            petal if i % 2 else petal2, studs=False)
    k.p(name + "Centre", (size * 0.34, 0.14, size * 0.34), c * CF((0, 0.03, 0)) * cf(ry=45), centre,
        material="Neon", studs=False)


def antler(k, sx, sd, base):
    """One antler: a thick beam spreading wide to the side with tines; pink flowers open at the tips, leaves at the
    forks."""
    pts = A.branch(k, "Antler" + sd, base, [((sx * 0.6, 1, 0.15), 0.7), ((sx * 1.0, 0.55, 0.2), 0.8),
                                             ((sx * 0.9, 0.7, 0.05), 0.75), ((sx * 0.8, 0.35, -0.05), 0.6)],
                   "antler", w0=0.26, taper=0.86)
    tines = ((1, (sx * 0.2, 1, -0.6), 0.6), (2, (sx * 0.15, 1, 0.3), 0.65), (3, (sx * 0.3, 1, -0.4), 0.55))
    ends = []
    for i, (j, d, ln) in enumerate(tines):
        dd = Vector(d).normalized()
        k.seg("Tine%s%d" % (sd, i + 1), pts[j], pts[j] + dd * ln, 0.16, 0.16, "antler2")
        ends.append((pts[j] + dd * ln, dd))
    ends.append((pts[-1], (pts[-1] - pts[-2]).normalized()))
    for i, (p, d) in enumerate(ends):
        flower(k, "AntlerFlower%s%d" % (sd, i + 1), p + d * 0.08, d + Vector((0, 0.4, -0.3)), 0.6 if i != 1 else 0.5)
    for i, (j, d) in enumerate(((1, (sx * 0.7, 0.2, 0.6)), (2, (sx * 0.4, -0.3, -0.8)), (3, (sx * 0.6, 0.3, 0.7)),
                                (4, (sx * 0.2, -0.4, -0.8)))):
        A.leaf(k, "AntlerLeaf%s%d" % (sd, i + 1), pts[j], d, 0.6, 0.34, "leaf" if i % 2 else "leaf2", thick=0.1,
               normal=(0, 1, 0.2))


def build(name="Z1_Crownstag_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a deep chest, barrel and hips of studded chestnut with cream patches; the shaggy cream ruff -----------
    J("Body")
    k.hinge("Body", (0, 2.3, 0.2))
    k.p("Chest", (1.5, 1.5, 1.35), CF(Vector((0, 2.4, -0.95))), "main")
    k.p("Barrel", (1.35, 1.25, 1.4), CF(Vector((0, 2.45, 0.3))), "main2")
    k.p("Hips", (1.45, 1.4, 1.2), CF(Vector((0, 2.55, 1.45))), "main")
    k.p("Withers", (1.1, 0.35, 1.15), CF(Vector((0, 3.25, -0.85))), "main2", studs=False)
    k.p("Belly", (1.0, 0.25, 2.7), CF(Vector((0, 1.72, 0.25))), "cream", studs=False)
    for sx in (-1, 1):  # cream patches on the flanks and hips
        for j, (y, z, h, w) in enumerate(((2.7, 0.35, 0.42, 0.7), (2.8, 1.55, 0.45, 0.55))):
            x = sx * (0.69 if z < 0.9 else 0.74)
            k.p("Patch%d_%d" % (sx + 2, j + 1), (0.06, h, w), CF(Vector((x, y, z))), "cream", studs=False)
    k.p("RumpPatch", (0.8, 0.08, 0.55), CF(Vector((0, 3.27, 1.6))), "cream", studs=False)
    for i, (y, w, z, col) in enumerate(((3.0, 1.3, -1.68, "cream"), (2.62, 1.36, -1.72, "cream2"),
                                        (2.25, 1.2, -1.7, "cream"), (1.9, 0.9, -1.62, "cream2"),
                                        (1.6, 0.55, -1.5, "cream"))):
        for sx in (-1, 1):  # two tilted blocks per row make the fur shaggy
            k.p("Ruff%d_%d" % (i + 1, sx + 2), (w * 0.58, 0.48, 0.34), CF(Vector((sx * w * 0.22, y, z))) *
                cf(rx=20, rz=sx * 10), col if sx < 0 else ("cream2" if col == "cream" else "cream"), studs=False)
    # the mantle: leaves over the shoulders and withers with pink flowers
    for i, (x, z, d, col) in enumerate(((-0.5, -1.05, (-0.95, -0.5, 0.1), "leaf"), (0.5, -1.05, (0.95, -0.5, 0.1),
                                                                                       "leaf2"),
                                        (-0.45, -0.45, (-0.85, -0.6, 0.45), "leaf2"),
                                        (0.45, -0.45, (0.85, -0.6, 0.45), "leaf"),
                                        (0.0, -0.15, (0, -0.15, 1), "leaf"), (0.0, -1.4, (0, -0.4, -1), "leaf2"),
                                        (-0.55, 0.2, (-0.8, -0.55, 0.6), "leaf"), (0.55, 0.2, (0.8, -0.55, 0.6),
                                                                                    "leaf2"))):
        dn = Vector(d).normalized()
        A.leaf(k, "Mantle%d" % (i + 1), (x, 3.32, z), d, 1.0, 0.6, col, thick=0.12,
               normal=(Vector((0, 1, 0)) - dn * dn.y).normalized())
    for i, (x, z, sz) in enumerate(((-0.5, -0.95, 0.62), (0.45, -0.55, 0.58), (0.05, -1.3, 0.5))):
        flower(k, "MantleFlower%d" % (i + 1), (x, 3.48, z), (x * 0.6, 1, 0.1), sz)

    # ---- neck: carried high, the cream ruff continuing up the throat ----------------------------------------------------
    J("Neck")
    k.hinge("Neck", (0, 2.95, -1.2))
    k.seg("NeckLow", (0, 2.75, -1.15), (0, 3.6, -1.55), 0.85, 0.9, "main")
    k.seg("NeckHigh", (0, 3.45, -1.5), (0, 4.15, -1.8), 0.7, 0.76, "main2")
    for i, (y, z, w) in enumerate(((3.35, -1.85, 0.7), (3.75, -2.02, 0.6), (4.05, -2.12, 0.5))):
        k.p("NeckRuff%d" % (i + 1), (w, 0.45, 0.3), CF(Vector((0, y, z))) * cf(rx=25), "cream" if i % 2 else "cream2",
            studs=False)

    # ---- head: chestnut with cream cheeks and jaw, glowing gold eyes, big ears, the gold crown, the antlers ---------
    J("Head")
    k.hinge("Head", (0, 4.1, -1.8))
    H = A.Frame(k, CF(Vector((0, 4.35, -2.05))) * cf(rx=-12), s=1.05)
    H.p("Skull", (0.8, 0.72, 0.85), (0, 0, 0), "main")
    H.p("Forehead", (0.64, 0.22, 0.55), (0, 0.38, -0.1), "main2", studs=False)
    H.p("Muzzle", (0.56, 0.5, 0.75), (0, -0.12, -0.72), "main")
    H.p("MuzzleTip", (0.48, 0.42, 0.3), (0, -0.16, -1.15), "cream", studs=False)
    H.p("Nose", (0.3, 0.18, 0.12), (0, -0.04, -1.32), "nose", studs=False)
    H.p("Jaw", (0.5, 0.2, 0.75), (0, -0.4, -0.7), "cream", studs=False)
    for sx in (-1, 1):
        H.p("Cheek%d" % (sx + 2), (0.12, 0.36, 0.55), (sx * 0.38, -0.22, -0.45), "cream", studs=False)
    A.eyes(H, "side", 0.41, 0.06, -0.22, 0.28, 0.18, iris="eye", rx=0)
    for sx, sd in A.SIDES:
        A.leaf(k, "Ear" + sd, H.pt((sx * 0.4, 0.2, 0.3)), H.vec((sx * 1, 0.45, 0.35)), 0.78, 0.4, "main",
               thick=0.12, normal=H.vec((0, 0.3, -1)), vein="cream")
    # the crown: a gold band, five points, a pink gem at the front
    H.p("Crown", (0.9, 0.16, 0.95), (0, 0.36, 0.0), "gold", studs=False)
    H.p("CrownTrim", (0.96, 0.06, 1.0), (0, 0.28, 0.0), "gold2", studs=False)
    for i, (x, z, h) in enumerate(((-0.34, -0.36, 0.28), (-0.17, -0.44, 0.36), (0.0, -0.48, 0.46), (0.17, -0.44, 0.36),
                                   (0.34, -0.36, 0.28))):
        H.p("CrownPoint%d" % (i + 1), (0.16, h, 0.16), (x, 0.42 + h / 2, z), "gold", rz=45, studs=False)
    H.p("CrownGem", (0.26, 0.26, 0.12), (0, 0.55, -0.52), "gem", rz=45, material="Neon", studs=False)
    for sx, sd in A.SIDES:
        antler(k, sx, sd, H.pt((sx * 0.26, 0.42, 0.08)))

    # ---- legs: chestnut upper legs, cream socks, chunky gold hooves -----------------------------------------------------
    for sx, sd in A.SIDES:
        A.limb(k, "Arm" + sd, [(sx * 0.45, 2.05, -0.95), (sx * 0.48, 1.15, -1.0), (sx * 0.48, 0.38, -1.05)],
               (0.46, 0.36), ("main", "cream"))
        k.p("ArmKnee" + sd, (0.42, 0.24, 0.42), CF(Vector((sx * 0.48, 1.15, -1.0))), "cream2", studs=False)
        k.p("ArmHoof" + sd, (0.5, 0.36, 0.56), CF(Vector((sx * 0.48, 0.18, -1.1))), "gold", studs=False)
        k.p("ArmHoofFront" + sd, (0.42, 0.2, 0.12), CF(Vector((sx * 0.48, 0.12, -1.4))), "gold2", studs=False)
        A.limb(k, "Leg" + sd, [(sx * 0.48, 2.25, 1.45), (sx * 0.52, 1.45, 1.25), (sx * 0.52, 0.95, 1.7),
                               (sx * 0.52, 0.38, 1.6)], (0.58, 0.4, 0.36), ("main", "main2", "cream"))
        k.p("LegHoof" + sd, (0.5, 0.36, 0.56), CF(Vector((sx * 0.52, 0.18, 1.55))), "gold", studs=False)
        k.p("LegHoofFront" + sd, (0.42, 0.2, 0.12), CF(Vector((sx * 0.52, 0.12, 1.25))), "gold2", studs=False)

    # ---- tail: a fluffy cream plume carried up --------------------------------------------------------------------------
    J("Tail")
    k.hinge("Tail", (0, 2.95, 2.0))
    for i, (y, z, s, rx, col) in enumerate(((3.0, 2.15, 0.5, 20, "main"), (3.3, 2.4, 0.62, 35, "cream"),
                                            (3.68, 2.55, 0.58, 15, "cream2"), (4.0, 2.48, 0.46, -10, "cream"),
                                            (4.22, 2.3, 0.32, -30, "cream2"))):
        k.p("Tail%d" % (i + 1), (s * 1.05, s, s), CF(Vector((0, y, z))) * cf(rx=rx), col, studs=False)
    for sx in (-1, 1):
        k.p("TailTuft%d" % (sx + 2), (0.3, 0.4, 0.34), CF(Vector((sx * 0.3, 3.5, 2.55))) * cf(rz=sx * 25), "cream",
            studs=False)

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
