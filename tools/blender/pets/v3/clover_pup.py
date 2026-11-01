# 01 Sprout Pup V3 "Clover Pup" (Meadow, Common), Roblox primitives only (blocks like the Frost Serpent; studs on top
# faces). A lucky charm puppy: the ears are clover leaflets (two lobes = a heart, pale inside), the raised tail is a
# clover heart on a curled stem, a four-leaf clover sprouts from the stepped crown, a lucky clover mark sits on its
# back and a glowing four-leaf charm hangs on its collar. Chibi rules (vault "Chibi Character Rules in Practice"):
# the head is the dominant mass, eyes below the middle with a big pupil and a glint, chubby cream cheeks, blush, a
# small "w" mouth with a tongue peeking out, brows that tilt up (curious), nothing pointing up like a horn.
# Line of action: chest up, head cocked. Joints: Body, Head, ArmL/R, LegL/R (hinges), Tail.
from mathutils import Vector

from kit import anatomy as A
from kit.rbx import CF, J, cf, look, use

PAL = dict(main="4CBF4A", dark="2E8B3A", light="FFF0D0", glow="72F25A", crown="6FD66A", ink="1C2A1E",
           blush="FF9DB5", tongue="FF7A8A", pale="A8E89A")
CONCEPT = "Clover Pup: lucky charm puppy, clover-leaflet ears, four-leaf clover on the crown, clover-heart tail"
HEADER = '''--!strict
-- 01 Sprout Pup V3 "Clover Pup" (Meadow, Common). Preview candidate (KICK_AN_EGG_PET_REMODEL_V3), not wired.
-- Pet: a chibi lucky-charm puppy: stepped head, eyes below the middle, chubby cheeks, clover-heart ears framing the
--      face, a four-leaf clover sprouting from the crown, a lucky clover mark on its back, a glowing clover charm on
--      its collar, a raised clover-heart tail on a curled stem.
-- Egg: cream base under a clover-green cap with a pinked leaf rim, a clover heart on every face, a paw print and a
--      four-leaf clover with a lucky gem on top.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/clover_pup.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''


def _clover(k, name, centre, up, fwd, size, gap, col, mid=None, tilt=0.34):
    """Four separate diamond leaves round a centre, cupped up; optional pale midrib on each leaf."""
    rt = up.cross(fwd).normalized()
    fwd = rt.cross(up).normalized()
    for i, (a, b) in enumerate(((1, 0), (0, 1), (-1, 0), (0, -1))):
        out = (rt * a + fwd * b).normalized()
        c = look(centre + out * gap, (up * (1 - tilt) - out * tilt).normalized(), out) * cf(ry=45)
        k.p("%s%d" % (name, i + 1), (size, 0.1, size), c, col)
        if mid:
            k.p("%sVein%d" % (name, i + 1), (size * 0.16, 0.12, size * 0.7), c * cf(ry=-45) * CF((0, 0.01, 0)), mid,
                studs=False)


def build(name="PK3_SproutPup_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: chest raised (line of action), cream belly and chest tuft, collar with a glowing clover charm -----
    J("Body")
    k.p("Torso", (1.85, 1.3, 2.2), cf((0, 1.38, 0.3), 6, 0, 0), "main")
    k.p("Rump", (1.6, 0.42, 1.0), cf((0, 2.08, 0.82), 6, 0, 0), "main")  # a stepped back, like the head's crown
    k.p("Belly", (1.45, 0.95, 0.14), cf((0, 1.28, -0.84), 6, 0, 0), "light")
    k.p("ChestTuft", (0.9, 0.5, 0.36), cf((0, 1.72, -0.9), 180 + 6, 0, 0), "light", shape="Wedge")
    k.p("Collar", (1.95, 0.24, 0.5), cf((0, 1.86, -0.72), 6, 0, 0), "dark", studs=False)
    charm_c = Vector((0, 1.52, -1.08))
    for i, (dx, dy) in enumerate(((0, 0.11), (0.11, 0), (0, -0.11), (-0.11, 0))):
        k.p("Charm%d" % (i + 1), (0.14, 0.14, 0.06), CF(charm_c + Vector((dx, dy, 0))) * cf(rz=45), "glow",
            material="Neon")
    _clover(k, "BackMark", Vector((0, 2.32, 0.82)), Vector((0, 1, 0)), Vector((0, 0, -1)), 0.3, 0.24, "dark", tilt=0)

    # ---- head: the dominant mass, cocked 7 degrees ------------------------------------------------------------
    J("Head")
    H = A.Frame(k, CF(Vector((0, 3.02, -0.92))) * cf(rz=7, ry=-5))
    H.p("Skull", (2.5, 2.0, 2.05), (0, 0, 0), "main")
    H.p("Crown", (2.15, 0.34, 1.75), (0, 1.16, 0.05), "crown")
    for sx, sd in A.SIDES:  # chubby cream cheeks round the muzzle (face shape, not a flat front)
        H.p("CheekPuff" + sd, (0.62, 0.62, 0.42), (sx * 0.86, -0.62, -0.92), "light")
        H.p("Brow" + sd, (0.42, 0.1, 0.08), (sx * 0.58, 0.42, -1.06), "dark", rz=-sx * 14, studs=False)
    H.p("Muzzle", (1.12, 0.6, 0.5), (0, -0.52, -1.25), "light")
    H.p("Nose", (0.46, 0.26, 0.18), (0, -0.27, -1.55), "ink", studs=False)
    H.p("NoseShine", (0.14, 0.07, 0.04), (-0.08, -0.2, -1.65), "glint", material="Neon", studs=False)
    for sx, sd in A.SIDES:  # a small "w" mouth
        H.p("Mouth" + sd, (0.24, 0.06, 0.05), (sx * 0.1, -0.66, -1.51), "ink", rz=sx * 25, studs=False)
    H.p("Tongue", (0.24, 0.2, 0.12), (0.14, -0.84, -1.43), "tongue", rx=-20, studs=False)
    A.eyes(H, "cute", 0.6, -0.04, -1.025 - 0.02, 0.5, 0.62, look_in=0.05)
    for sx, sd in A.SIDES:
        H.p("Cheek" + sd, (0.36, 0.18, 0.06), (sx * 0.86, -0.4, -1.15), "blush", studs=False)
    # the lucky charm: a four-leaf clover sprouting from the crown, leaning back (reads from above too)
    stem0, stem1 = H.pt((0, 1.3, 0.2)), H.pt((0, 1.78, 0.42))
    k.seg("CloverStem", stem0, stem1, 0.14, 0.14, "dark")
    up = (stem1 - stem0).normalized()
    _clover(k, "Clover", stem1 + up * 0.1, up, H.vec((0, 0, -1)), 0.32, 0.3, "dark", mid="pale")
    # clover-leaflet ears: two lobes make a heart, pale inside, framing the face
    for sx, sd in A.SIDES:
        root = H.pt((sx * 1.22, 0.62, -0.32))
        d = H.vec((sx * 0.5, -0.86, -0.08)).normalized()
        side = H.vec((0, 0, 1)).cross(d).normalized()
        nrm = d.cross(side).normalized()
        k.p("EarStem" + sd, (0.2, 0.3, 0.2), look(root + d * 0.1, d, nrm), "dark")
        for j, s in enumerate((-1, 1)):
            c = look(root + d * 0.85 + side * s * 0.3, d, nrm) * cf(rz=45)
            k.p("Ear%s%d" % (sd, j + 1), (0.86, 0.86, 0.16), c, "dark" if j == 0 else "main")
            inner = sx * nrm.x > 0
            k.p("EarIn%s%d" % (sd, j + 1), (0.5, 0.5, 0.06), c * CF((0, 0, 0.1 if inner else -0.1)), "pale",
                studs=False)

    # ---- legs: stubby, hinged at the hip, cream paws with a toe groove -------------------------------------------
    for joint, x, z in (("ArmL", -0.52, -0.5), ("ArmR", 0.52, -0.5), ("LegL", -0.58, 0.95), ("LegR", 0.58, 0.95)):
        k.hinge(joint, (x, 1.0, z))
        tag = joint[-1] + joint[:3]
        k.p("Leg" + tag, (0.6, 0.72, 0.6), CF(Vector((x, 0.66, z))), "main")
        k.p("Paw" + tag, (0.74, 0.32, 0.84), CF(Vector((x, 0.16, z - 0.08))), "light")
        k.p("Toes" + tag, (0.06, 0.18, 0.06), CF(Vector((x, 0.2, z - 0.52))), "dark", studs=False)
        k.p("Toes2" + tag, (0.06, 0.18, 0.06), CF(Vector((x + 0.18, 0.2, z - 0.5))), "dark", studs=False)

    # ---- tail: a curled stem (the pivot first) ending in a raised clover heart --------------------------------
    J("Tail")
    base = Vector((0, 1.78, 1.38))
    p1 = base + Vector((0, 0.42, 0.3))
    p2 = p1 + Vector((0, 0.36, -0.05))
    k.seg("TailStem", base, p1, 0.24, 0.24, "dark")
    k.seg("TailStem2", p1, p2, 0.2, 0.2, "dark")
    d = (p2 - p1).normalized()
    side = Vector((1, 0, 0))
    nrm = d.cross(side).normalized()
    for j, s in enumerate((-1, 1)):
        c = look(p2 + d * 0.36 + side * s * 0.18, d, nrm) * cf(rz=45)
        k.p("TailLeaf%d" % (j + 1), (0.52, 0.52, 0.14), c, "main" if j == 0 else "dark")
        k.p("TailVein%d" % (j + 1), (0.3, 0.3, 0.16), c, "pale", studs=False)
    J("Root")
    return coll
