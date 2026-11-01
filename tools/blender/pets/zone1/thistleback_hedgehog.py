# Thistleback Hedgehog (Zone 1 Meadow, Epic): a leaf-armoured hedgehog built to the user's reference (images/7.webp,
# "Thornback Hedgehog"), Roblox primitives only (Frost Serpent method). A round brown hedgehog with a tan face, snout
# and belly, a determined look under brown brows, big round ears and a dark nose; a big dome coat of layered green
# leaf plates pointing back, long cream thorn cones standing out of it, brown vines winding over it with red berry
# clusters and white flowers; short chunky legs wrapped in root bands with little leaves, cream toes.
# Joints: Body, Quills (the coat: it bristles for Thistle Guard), Head, ArmL/R, LegL/R.
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use

NAME, RARITY = "Thistleback Hedgehog", "Epic"
PAL = dict(main="7A4A26", main2="6A3E1F", dark="4E2E16", light="E8C08A", glow="FFE066", tan="E8C08A",
           tan2="D9AC72", cream="F2E2C2", thorn="F4D99C", thorn2="E8C27A", leaf="4FA83A", leaf2="6CC23A",
           leaf3="8FD44A", leaf4="2E7A2A", vine="7A4A26", berry="D8283A", berry2="F04A55", flower="FFFFFF",
           flower2="F2F2EA", pollen="FFC93C", nose="2A1A12", eye="FFFFFF", ink="1A0F08")
CONCEPT = "Thistleback Hedgehog: a round hedgehog under a dome of leaf plates and cream thorns, vines and berries"
HEADER = '''--!strict
-- Thistleback Hedgehog (Zone 1 Meadow, Epic). Zone 1 Meadow roster (Config/Pets).
-- Pet: a round brown hedgehog with a tan face, snout and belly, a determined look, big round ears, a dome coat of
--      layered green leaf plates with long cream thorn cones, brown vines with red berries and white flowers, short
--      legs wrapped in root bands, cream toes. Joints: Body, Quills, Head, ArmL/R, LegL/R.
-- Egg: a tan egg under green leaf plates and a brown vine net, cream thorns, white flowers and red berries.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/thistleback_hedgehog.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.15

C0 = Vector((0, 2.0, 0.55))  # the coat: an ellipsoid of these radii
CR = Vector((1.9, 1.75, 2.15))


def on_coat(az, el, lift=0.0):
    """Point and normal on the coat at azimuth az (0 = front, towards the head) and elevation el (degrees)."""
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.cos(e) * math.sin(a), math.sin(e), -math.cos(e) * math.cos(a)))
    p = C0 + Vector((d.x * CR.x, d.y * CR.y, d.z * CR.z))
    n = Vector(((p - C0).x / CR.x ** 2, (p - C0).y / CR.y ** 2, (p - C0).z / CR.z ** 2)).normalized()
    return p + n * lift, n


def thorn(k, name, base, d, length, width=0.42):
    """A long cream thorn cone: three stepped, diamond-turned blocks tapering smoothly to a point."""
    d = Vector(d).normalized()
    c = look(Vector(base), d, (0, 0, 1) if abs(d.z) < 0.9 else (1, 0, 0)) * cf(ry=45)
    k.p(name, (width, length * 0.42, width), c * CF((0, length * 0.21, 0)), "thorn", studs=False)
    k.p(name + "Mid", (width * 0.7, length * 0.36, width * 0.7), c * CF((0, length * 0.55, 0)), "thorn", studs=False)
    k.p(name + "Tip", (width * 0.4, length * 0.3, width * 0.4), c * CF((0, length * 0.84, 0)), "thorn2",
        studs=False)


def berries(k, name, at, n=3):
    at = Vector(at)
    for b in range(n):
        k.p("%s%d" % (name, b + 1), (0.26, 0.26, 0.26),
            CF(at + Vector((0.17 * (b - 1), 0.12 * (b == 1), 0.1 * (b % 2)))) * cf(ry=20 * b),
            "berry" if b % 2 == 0 else "berry2", studs=False)


def build(name="Z1_ThistlebackHedgehog_Pet", offset=(0, 0, 0)):
    from zone1.crownstag import flower

    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a round brown body with a tan belly ------------------------------------------------------------------
    J("Body")
    k.hinge("Body", (0, 1.4, 0.3))
    k.p("Torso", (2.6, 1.7, 3.0), CF(Vector((0, 1.55, 0.4))), "main")
    k.p("Chest", (2.1, 1.3, 0.6), CF(Vector((0, 1.45, -1.25))), "tan")
    k.p("Belly", (2.0, 0.35, 2.5), CF(Vector((0, 0.78, 0.4))), "tan", studs=False)
    k.p("Rump", (2.2, 1.2, 0.5), CF(Vector((0, 1.6, 2.05))), "main2", studs=False)

    # ---- the coat: leaf plates layered over a dark dome, cream thorns, vines with berries and flowers ---------------
    J("Quills")
    k.hinge("Quills", (0, 2.2, -0.2))
    for j, (y, w, h, d) in enumerate(((1.55, 3.3, 0.6, 3.9), (2.15, 3.5, 0.6, 4.1), (2.75, 3.1, 0.6, 3.7),
                                      (3.25, 2.4, 0.5, 2.9), (3.62, 1.5, 0.35, 1.9))):
        k.p("Coat%d" % (j + 1), (w, h, d), CF(Vector((0, y, C0.z))), "leaf4")
    n = 0
    for el, count, ln, wd in ((-14, 13, 1.2, 0.72), (8, 13, 1.25, 0.72), (28, 12, 1.2, 0.7), (48, 10, 1.1, 0.66), (67, 7, 1.0, 0.62),
                              (84, 3, 0.9, 0.58)):
        for i in range(count):
            az = 360 * (i + 0.5 * (((el + 20) // 20) % 2)) / count
            if el < 40 and (az < 40 or az > 320):
                continue  # the head sits here
            p, nrm = on_coat(az, el, 0.04)
            back = Vector((0, -0.25, 1)) - nrm * Vector((0, -0.25, 1)).dot(nrm)
            if back.length < 0.2:
                back = Vector((0, 0, 1))
            d = (back.normalized() + nrm * 0.35).normalized()
            n += 1
            A.leaf(k, "CoatLeaf%d" % n, p - d * 0.25, d, ln, wd, ("leaf", "leaf2", "leaf4", "leaf3")[n % 4],
                   thick=0.14, normal=nrm)
    for i, (az, el, ln) in enumerate(((60, 22, 1.0), (110, 26, 1.15), (160, 20, 1.05), (200, 22, 1.05),
                                      (250, 26, 1.15), (300, 22, 1.0), (40, 50, 1.15), (100, 52, 1.3),
                                      (180, 48, 1.2), (260, 52, 1.3), (320, 50, 1.15), (0, 70, 1.25),
                                      (90, 72, 1.25), (180, 74, 1.2), (270, 72, 1.25), (0, 90, 1.3))):
        p, nrm = on_coat(az, el, -0.05)
        thorn(k, "Thorn%d" % (i + 1), p, nrm + Vector((0, 0, 0.7)), ln * 1.15, 0.52 if ln > 1.1 else 0.46)
    for v, path in enumerate((((330, 30), (300, 50), (250, 62), (200, 58), (160, 45)),
                              ((40, 32), (75, 52), (120, 66), (160, 76)),
                              ((210, 20), (240, 36), (280, 30)))):
        pts = [on_coat(a, e, 0.18)[0] for a, e in path]
        for i in range(len(pts) - 1):
            d = (pts[i + 1] - pts[i]).normalized()
            k.seg("Vine%d_%d" % (v + 1, i + 1), pts[i] - d * 0.06, pts[i + 1] + d * 0.06, 0.2, 0.2, "vine",
                  studs=False)
        mid, nrm = on_coat(*path[1], 0.3)
        berries(k, "Berry%d_" % (v + 1), mid)
    for i, (az, el) in enumerate(((330, 58), (105, 40))):
        p, nrm = on_coat(az, el, 0.22)
        flower(k, "Flower%d" % (i + 1), p, nrm, 0.75, petal="flower", petal2="flower2", centre="pollen")
    berries(k, "Berry4_", on_coat(150, 62, 0.3)[0])

    # ---- head: brown with a tan face and snout, a dark nose, determined eyes, big round ears --------------------------
    J("Head")
    k.hinge("Head", (0, 1.7, -1.4))
    k.p("Head", (1.75, 1.45, 1.35), CF(Vector((0, 1.95, -1.95))), "main")
    k.p("Face", (1.45, 0.95, 0.12), CF(Vector((0, 1.7, -2.65))), "tan", studs=False)
    k.p("Snout", (0.78, 0.6, 0.85), CF(Vector((0, 1.55, -3.0))), "tan")
    k.p("SnoutTip", (0.56, 0.45, 0.45), CF(Vector((0, 1.58, -3.55))), "tan2")
    k.p("Nose", (0.42, 0.34, 0.28), CF(Vector((0, 1.66, -3.88))), "nose", studs=False)
    k.p("Mouth", (0.46, 0.06, 0.06), CF(Vector((0, 1.32, -3.4))), "ink", studs=False)
    F = A.Frame(k, CF(Vector((0, 0, 0))))
    A.eyes(F, "cute", 0.42, 2.08, -2.66, 0.38, 0.42, iris="eye", rz=0)
    for sx, sd in A.SIDES:
        k.p("Brow" + sd, (0.5, 0.14, 0.1), CF(Vector((sx * 0.42, 2.38, -2.68))) * cf(rz=sx * 18), "dark",
            studs=False)
        k.p("Ear" + sd, (0.8, 0.8, 0.28), CF(Vector((sx * 0.85, 2.65, -1.75))) * cf(rz=-sx * 20, ry=sx * 15), "main")
        k.p("EarInner" + sd, (0.48, 0.48, 0.1), CF(Vector((sx * 0.85, 2.62, -1.9))) * cf(rz=-sx * 20, ry=sx * 15),
            "tan", studs=False)
    for i, (x, d) in enumerate(((-0.3, (-0.4, 0.5, 1)), (0.3, (0.4, 0.5, 1)), (0.0, (0, 0.6, 1)))):
        A.leaf(k, "HeadLeaf%d" % (i + 1), (x, 2.62, -2.0), d, 1.0, 0.6, ("leaf2", "leaf", "leaf3")[i], thick=0.14,
               normal=(0, 1, -0.3))

    # ---- legs: short and chunky, root bands with little leaves, cream toes ---------------------------------------------
    for sx, sd in A.SIDES:
        for joint, z in (("Arm" + sd, -0.95), ("Leg" + sd, 1.55)):
            J(joint)
            hip = Vector((sx * 0.95, 1.2, z))
            k.hinge(joint, hip)
            k.p("Leg" + joint, (0.85, 1.1, 0.95), CF(Vector((sx * 1.0, 0.65, z))), "main")
            k.p("Band" + joint, (0.98, 0.22, 1.08), CF(Vector((sx * 1.0, 0.75, z))) * cf(ry=12), "dark", studs=False)
            k.p("BandLeaf" + joint, (0.3, 0.08, 0.2), CF(Vector((sx * 1.45, 0.85, z - 0.2))) * cf(rz=-sx * 30), "leaf3",
                studs=False)
            for t in (-1, 0, 1):
                k.p("Toe%s%d" % (joint, t + 2), (0.26, 0.24, 0.36), CF(Vector((sx * 1.0 + t * 0.28, 0.12, z - 0.48))),
                    "cream", studs=False)

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
