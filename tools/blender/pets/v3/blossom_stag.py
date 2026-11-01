# 03 Meadow Stag V3 "Blossom Stag" (Meadow, Rare), Roblox primitives only (Frost Serpent method, studs on top faces).
# An elegant, slightly proud forest stag: a segmented spine-curve body (deep chest, tucked waist, round rump) dappled
# cream like a fawn, a neck rising forward, the head held high and turned a little. The antlers are the centerpiece
# (vault hierarchy: primary body, antlers the big secondary): wide tapering bark beams with three tines each, pale
# velvet tips, a moss collar at each base, blossoms with glowing cores nested in the forks and new leaves opening on
# the tines. Moss mantle on the withers draping down the shoulders, with leaves and two little mushrooms growing on
# it; cream chest ruff, white rump and tail flag, calm half-lidded eyes under a brow, nostrils, pale inner ears,
# dewclaws and hocks. Joints: Body, Head, ArmL/R, LegL/R, Tail.
from mathutils import Vector

from kit import anatomy as A
from kit.rbx import CF, J, cf, look, use

PAL = dict(main="C08A55", main2="B07B48", dark="4E3424", light="F6E6C8", moss="5FA544", moss2="4C8F36",
           glow="9CFF7A", velvet="E9D3B0", petal="FFF6EC", inner="F2C9B8", ink="2A1B12", cap="E8664F")
CONCEPT = "Blossom Stag: forest stag, blossoming bark antlers with moss collars and velvet tips, moss mantle"
HEADER = '''--!strict
-- 03 Meadow Stag V3 "Blossom Stag" (Meadow, Rare). Preview candidate (KICK_AN_EGG_PET_REMODEL_V3), not wired.
-- Pet: an elegant dappled forest stag on a segmented spine-curve body; wide bark antlers with three tines, velvet tips,
--      moss collars, blossoms with glowing cores in the forks and opening leaves; a moss mantle with leaves and two
--      mushrooms; cream ruff, white rump, half-lidded eyes, nostrils, dewclaws.
-- Egg: fawn terraces with cream dapples, a moss band in bloom, bark branches climbing the shell, mushrooms at the
--      base, velvet antler nubs and the Rare band.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/blossom_stag.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''


def _bloom(k, name, at, nrm, size, up_hint):
    c = look(at + nrm * 0.06, nrm, up_hint)
    k.p(name, (size, 0.1, size), c * cf(ry=45), "petal", studs=False)
    k.p(name + "B", (size * 0.72, 0.1, size * 0.72), c * CF((0, 0.03, 0)), "petal", studs=False)  # 8-point flower
    k.p(name + "Core", (size * 0.4, 0.14, size * 0.4), c * CF((0, 0.07, 0)), "glow", material="Neon")


def build(name="PK3_MeadowStag_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: five segments along the spine, dappled flanks ------------------------------------------------------
    J("Body")
    k.hinge("Body", (0, 2.7, 0.1))
    segs = A.spine(k, "Body", [(0, 2.62, 1.35), (0, 2.6, 0.7), (0, 2.66, 0.0), (0, 2.8, -0.6), (0, 2.96, -1.12)], 5,
                   [(0, 1.25), (0.45, 1.08), (1, 1.36)], [(0, 1.12), (0.45, 0.98), (1, 1.34)],
                   col=("main", "main2"), stretch=1.2)
    for g in segs[3:]:
        k.p("Belly%d" % (g["i"] + 1), (g["w"] * 0.62, 0.14, g["len"] * 0.98), g["f"] * CF((0, -g["t"] / 2 - 0.05, 0)),
            "light", studs=False)
    k.p("Rump", (0.96, 0.84, 0.14), CF(Vector((0, 2.56, 1.46))), "light", studs=False)
    for sx, sd in A.SIDES:  # cream dapples along the flanks, uneven (rhythm)
        for i, (y, z, s) in enumerate(((2.95, 0.95, 0.22), (2.72, 0.42, 0.18), (3.0, -0.05, 0.2))):
            k.p("Dapple%s%d" % (sd, i + 1), (0.06, s, s * 1.2), CF(Vector((sx * 0.6, y, z))), "light", studs=False)
    k.p("Ruff", (0.9, 0.62, 0.46), CF(Vector((0, 2.42, -1.58))) * cf(rx=180), "light", shape="Wedge")
    k.p("Ruff2", (0.64, 0.44, 0.34), CF(Vector((0, 2.02, -1.5))) * cf(rx=180), "light", shape="Wedge")
    for sx, sd in A.SIDES:
        k.p("RuffSide" + sd, (0.36, 0.5, 0.3), CF(Vector((sx * 0.42, 2.3, -1.45))) * cf(rx=180, ry=sx * 25), "light",
            shape="Wedge")
    # moss mantle over the withers, draping down the shoulders, leaves and two mushrooms growing on it
    for g in segs[3:]:
        k.p("Mantle%d" % (g["i"] + 1), (g["w"] * 1.12, 0.22, g["len"] * 1.08), g["f"] * CF((0, g["t"] / 2 + 0.08, 0)),
            "moss")
    for sx, sd in A.SIDES:
        k.p("Drape" + sd, (0.18, 0.5, 0.9), CF(Vector((sx * 0.7, 2.98, -0.7))) * cf(rz=-sx * 12), "moss2",
            studs=False)
    g = segs[4]
    top = g["f"].point((0, g["t"] / 2 + 0.2, 0))
    for i, (sx, lean) in enumerate(((-1, -25), (1, 30))):
        c = CF(top + Vector((sx * 0.28, 0.08, 0.1 * sx))) * cf(rz=lean, ry=sx * 30)
        k.p("MossLeaf%d" % (i + 1), (0.12, 0.5, 0.3), c, "moss", shape="Wedge")
    for i, (x, z, h) in enumerate(((0.32, -0.25, 0.28), (-0.22, -0.45, 0.2))):
        base = segs[3]["f"].point((x, segs[3]["t"] / 2 + 0.18, z))
        k.p("Stem%d" % (i + 1), (0.09, h, 0.09), CF(base + Vector((0, h / 2, 0))), "petal", studs=False)
        k.p("Cap%d" % (i + 1), (0.26, 0.12, 0.26), CF(base + Vector((0, h + 0.03, 0))) * cf(ry=45), "cap",
            studs=False)

    # ---- head: neck up and forward, long head held high, turned a little ---------------------------------------
    J("Head")
    k.hinge("Head", (0, 3.05, -1.25))
    k.seg("Neck1", (0, 2.95, -1.15), (0, 3.9, -1.66), 0.74, 0.8, "main")
    k.seg("Neck2", (0, 3.75, -1.6), (0, 4.6, -1.9), 0.62, 0.66, "main2")
    k.p("Throat", (0.4, 1.0, 0.12), look(Vector((0, 3.75, -1.98)), Vector((0, 1, -0.5)), Vector((0, 0.5, 1))) * CF((0, 0, -0.04)),
        "light", studs=False)
    H = A.Frame(k, CF(Vector((0, 4.82, -2.08))) * cf(ry=8, rx=-4))
    H.p("Skull", (0.96, 0.88, 1.06), (0, 0, 0), "main")
    H.p("Snout", (0.68, 0.56, 0.86), (0, -0.2, -0.74), "main", rx=-12)
    H.p("SnoutRidge", (0.5, 0.18, 0.7), (0, 0.12, -0.7), "main2", rx=-12, studs=False)
    H.p("Nose", (0.34, 0.18, 0.12), (0, -0.08, -1.15), "ink", rx=-12, studs=False)
    for sx, sd in A.SIDES:
        H.p("Nostril" + sd, (0.07, 0.07, 0.04), (sx * 0.1, -0.12, -1.22), "glint", rx=-12, studs=False)
    H.p("Jaw", (0.58, 0.16, 0.86), (0, -0.48, -0.7), "light", rx=-12, studs=False)
    H.p("ChinTuft", (0.3, 0.2, 0.16), (0, -0.6, -0.42), "light", shape="Wedge", rx=180, studs=False)
    A.eyes(H, "side", 0.49, 0.1, -0.08, 0.36, 0.24, socket=False)
    for sx, sd in A.SIDES:  # calm, slightly proud: an upper lid over the top third of each eye, a brow above
        H.p("Lid" + sd, (0.06, 0.1, 0.44), (sx * 0.52, 0.2, -0.08), "main2", rx=-6, studs=False)
        H.p("Brow" + sd, (0.12, 0.12, 0.5), (sx * 0.46, 0.34, -0.1), "main2", rx=-8, rz=sx * 15, studs=False)
        root = H.pt((sx * 0.36, 0.3, 0.4))
        d = H.vec((sx * 0.95, 0.35, 0.25)).normalized()
        nrm = H.vec((0, 0.4, -1))
        c = look(root + d * 0.38, d, nrm)
        k.p("Ear" + sd, (0.36, 0.8, 0.12), c, "main", shape="Wedge")
        k.p("EarIn" + sd, (0.2, 0.48, 0.05), c * CF((0, -0.08, -0.07)), "inner", shape="Wedge", studs=False)

    # ---- antlers: tapering bark beams, three tines, velvet tips, moss collars, blossoms and leaves in the forks ----
    for sx, sd in A.SIDES:
        m = lambda v: H.pt((sx * v[0], v[1], v[2]))
        b = [m(p) for p in ((0.24, 0.44, 0.18), (0.62, 0.95, 0.38), (1.15, 1.42, 0.3), (1.52, 1.85, 0.05),
                             (1.6, 2.22, -0.25))]
        widths = (0.24, 0.2, 0.16, 0.13)
        for i in range(4):
            d = (b[i + 1] - b[i]).normalized()
            k.seg("Antler%s%d" % (sd, i + 1), b[i] - d * 0.06, b[i + 1] + d * 0.06, widths[i], widths[i],
                  "velvet" if i == 3 else "dark")
        tines = ((1, (0.7, 1.58, -0.14), 0.13), (2, (1.4, 2.02, 0.55), 0.11), (3, (1.98, 2.18, 0.22), 0.1))
        for i, (j, tip, w) in enumerate(tines):
            k.seg("Tine%s%d" % (sd, i + 1), b[j], m(tip), w, w, "dark")
            d = (m(tip) - b[j]).normalized()
            k.p("Velvet%s%d" % (sd, i + 1), (w * 0.9, 0.24, w * 0.9), look(m(tip) + d * 0.09, d), "velvet")
        k.p("MossCollar" + sd, (0.38, 0.24, 0.38), look(b[0] + (b[1] - b[0]) * 0.18, b[1] - b[0]) * cf(ry=45), "moss")
        k.p("MossCollar2" + sd, (0.28, 0.2, 0.28), look(b[2] + (b[3] - b[2]) * 0.1, b[3] - b[2]) * cf(ry=20), "moss2")
        up = H.vec((0, 1, 0))
        for i, (at, n, s) in enumerate(((b[2], (0.3, 0.6, -0.75), 0.5), (b[1] + (b[2] - b[1]) * 0.5,
                                                                          (0.6, 0.4, -0.7), 0.36),
                                        (b[3], (0.2, 0.7, -0.6), 0.4))):
            _bloom(k, "Bloom%s%d" % (sd, i + 1), at, H.vec((sx * n[0], n[1], n[2])).normalized(), s, up)
        for i, (j, dv) in enumerate(((3, (0.8, 0.2, 0.6)), (2, (-0.2, 0.5, 0.85)))):  # new leaves opening
            c = look(b[j] + m(dv) * 0 + H.vec((sx * dv[0], dv[1], dv[2])).normalized() * 0.25,
                     H.vec((sx * dv[0], dv[1], dv[2])), up) * cf(rz=45)
            k.p("Leaf%s%d" % (sd, i + 1), (0.24, 0.24, 0.07), c, "moss", studs=False)

    # ---- legs: shoulder, forearm, knee, hoof with dewclaws; haunch, hock, shin -----------------------------------
    for sx, sd in A.SIDES:
        k.hinge("Arm" + sd, (sx * 0.38, 2.45, -0.95))
        k.seg("UpperArm" + sd, (sx * 0.38, 2.6, -0.95), (sx * 0.38, 1.55, -1.02), 0.4, 0.44, "main")
        k.seg("LowerArm" + sd, (sx * 0.38, 1.6, -1.02), (sx * 0.38, 0.32, -0.98), 0.26, 0.28, "main2")
        k.p("Knee" + "Arm" + sd, (0.32, 0.26, 0.32), CF(Vector((sx * 0.38, 1.12, -1.0))), "main")
        k.p("Sock" + "Arm" + sd, (0.3, 0.16, 0.32), CF(Vector((sx * 0.38, 0.38, -0.98))), "light", studs=False)
        k.p("Hoof" + "Arm" + sd, (0.34, 0.3, 0.42), CF(Vector((sx * 0.38, 0.15, -1.04))), "dark")
        k.p("Dew" + "Arm" + sd, (0.1, 0.12, 0.1), CF(Vector((sx * 0.38, 0.42, -0.82))), "dark", studs=False)
        k.hinge("Leg" + sd, (sx * 0.42, 2.6, 1.0))
        k.seg("UpperLeg" + sd, (sx * 0.42, 2.85, 1.05), (sx * 0.42, 1.55, 0.78), 0.5, 0.62, "main")
        k.seg("LowerLeg" + sd, (sx * 0.42, 1.65, 0.82), (sx * 0.42, 0.32, 1.05), 0.26, 0.28, "main2")
        k.p("Hock" + sd, (0.3, 0.3, 0.34), CF(Vector((sx * 0.42, 1.55, 0.86))), "main")
        k.p("Sock" + "Leg" + sd, (0.3, 0.16, 0.32), CF(Vector((sx * 0.42, 0.38, 1.04))), "light", studs=False)
        k.p("Hoof" + "Leg" + sd, (0.34, 0.3, 0.42), CF(Vector((sx * 0.42, 0.15, 1.0))), "dark")
        k.p("Dew" + "Leg" + sd, (0.1, 0.12, 0.1), CF(Vector((sx * 0.42, 0.42, 1.22))), "dark", studs=False)

    # ---- tail: a short white flag ----------------------------------------------------------------------------------
    J("Tail")
    k.seg("TailStem", (0, 2.92, 1.5), (0, 3.12, 1.72), 0.22, 0.22, "main")
    k.p("TailFlag", (0.3, 0.42, 0.16), look(Vector((0, 3.2, 1.82)), Vector((0, 0.8, 0.6)), Vector((0, 0.6, -0.8))),
        "light", shape="Wedge")
    k.p("TailTop", (0.24, 0.3, 0.1), look(Vector((0, 3.24, 1.74)), Vector((0, 0.8, 0.6)), Vector((0, 0.6, -0.8))),
        "main2", studs=False)
    J("Root")
    return coll
