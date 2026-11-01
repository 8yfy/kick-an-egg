# The First Seed (Zone 1 Meadow, Secret): the primordial root guardian, built to the user's reference
# (images/13.webp), Roblox primitives only (Frost Serpent method). A broad bark torso rising out of a root ball and
# carried on six great arching roots plus a mass of smaller and trailing roots, all lit by green veins, moss on the
# arches and grass at the feet; heavy moss slabs over the shoulders; a chest of layered, gold-rimmed ivory plates with
# gold leaf glyphs round a large glowing leaf-shaped seed core in a gold frame, under a gold collar; three long ivory
# plates per side fanning from the shoulders like folded wings, gold-rimmed with leaf emblems; a bone-ivory deer-skull
# mask with glowing green eyes and big branching horns covered in glowing leaves; a large double gold halo with runes,
# a star and side diamonds behind the head.
# Joints: Body, Core (the seed pulses), Head, HaloRing, PlateL/R (shoulder plates), ArmL/R, RootL/R, LegL/R (the six roots).
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use
from v3 import top_parts as T

NAME, RARITY = "The First Seed", "Secret"
PAL = dict(main="6E4426", main2="5A361E", dark="472A17", light="F5D9A8", glow="8CFF4A", bark="6E4426",
           bark2="5A361E", bark3="472A17", bark4="7E5230", ivory="F5D9A8", ivory2="E8C690", gold="E8BE4A",
           gold2="B8902E", goldglow="FFE27A", halo="F5CF5A", core="8CFF4A", core2="E6FFB8", vein="7DFF5A",
           moss="5FB33A", moss2="8FD44A", grass="7ACF3E", leafglow="9CFF5A", eye="8CFF4A", ink="141008")
CONCEPT = "The First Seed: a root guardian on six glowing roots, ivory-plated seed core, skull mask, branch horns, halo"
HEADER = '''--!strict
-- The First Seed (Zone 1 Meadow, Secret). Zone 1 Meadow roster (Config/Pets).
-- Pet: a primordial root guardian: a broad bark torso on a root ball, six great arching roots and a mass of smaller
--      roots lit by green veins, heavy moss on the shoulders, a chest of layered gold-rimmed ivory plates round a
--      large glowing seed core, three long ivory wing plates per side with gold leaf emblems, a bone-ivory deer-skull
--      mask with glowing green eyes, big branching horns covered in glowing leaves and a large double gold halo.
--      Joints: Body, Core, Head, HaloRing, PlateL/R, ArmL/R, RootL/R, LegL/R.
-- Egg: a bark egg set with gold-rimmed ivory plates round a big glowing green core, glowing sprouts on top.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/first_seed.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 0.9


def glowleaf(k, name, base, d, length, width, normal=(0, 1, 0), col="leafglow"):
    """A glowing leaf: a Neon blade with a diamond tip (A.leaf's shape, lit)."""
    d = Vector(d).normalized()
    base = Vector(base)
    k.p(name, (width, length * 0.84, 0.1), look(base + d * (length * 0.42), d, normal), col, material="Neon",
        studs=False)
    e = width * 0.7071
    k.p(name + "Tip", (e, e, 0.1), look(base + d * (length * 0.84), d, normal) * cf(rz=45), col, material="Neon",
        studs=False)


def leaf_glyph(k, name, f, size, col="gold"):
    """A gold leaf glyph laid on a plate frame f (local Z out)."""
    k.p(name, (size * 0.32, size, 0.08), f * CF((0, 0, 0.02)), col, studs=False)
    k.p(name + "Tip", (size * 0.24, size * 0.24, 0.08), f * CF((0, size * 0.5, 0.02)) * cf(rz=45), col, studs=False)
    for sy in (-1, 1):
        k.p("%sVein%d" % (name, sy + 2), (size * 0.36, 0.05, 0.1), f * CF((sy * size * 0.12, size * 0.05, 0.03)) *
            cf(rz=sy * 35), "gold2", studs=False)


def root(k, name, pts, widths, veins=2, cols=("bark", "bark2")):
    """A root through pts, thick to thin, with a glowing vein along the top of its first segments."""
    P = [Vector(p) for p in pts]
    for i, w in enumerate(widths):
        d = (P[i + 1] - P[i]).normalized()
        k.seg("%s%d" % (name, i + 1), P[i] - d * 0.1, P[i + 1] + d * 0.1, w, w, cols[i % len(cols)])
        if i < veins:
            up = Vector((0, 1, 0)) - d * d.y
            off = up.normalized() * (w * 0.5 + 0.02)
            k.seg("%sVein%d" % (name, i + 1), P[i] + off + d * 0.15, P[i + 1] + off - d * 0.1, 0.1, 0.06, "vein",
                  material="Neon", studs=False)
    return P


def grass(k, name, at, n=3):
    """A small tuft of grass blades."""
    for i in range(n):
        a = 2 * math.pi * i / n
        k.p("%s%d" % (name, i + 1), (0.12, 0.45 + 0.12 * (i % 2), 0.06),
            CF(Vector(at) + Vector((math.cos(a) * 0.15, 0.22, math.sin(a) * 0.15))) *
            cf(ry=math.degrees(a), rz=15 * (i - 1)), "grass", studs=False)


def build(name="Z1_FirstSeed_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a root ball, a broad bark torso with green veins, heavy moss on the shoulders -------------------------
    J("Body")
    k.hinge("Body", (0, 4.6, 0))
    k.p("RootBall", (2.8, 0.9, 2.4), CF(Vector((0, 2.15, 0.3))), "bark3")
    k.p("Pelvis", (3.3, 1.5, 2.8), CF(Vector((0, 3.0, 0.3))), "bark2")
    k.p("Torso", (2.9, 3.0, 2.1), CF(Vector((0, 5.0, 0))), "bark")
    k.p("Shoulders", (3.7, 1.1, 2.2), CF(Vector((0, 6.85, 0))), "bark2")
    k.p("BackPlate", (2.4, 2.4, 0.3), CF(Vector((0, 5.1, 1.12))), "bark3", studs=False)
    for sx in (-1, 1):  # bark plates and branching green veins down the flanks
        for j, (z, y, h) in enumerate(((-0.55, 4.9, 2.0), (0.45, 5.25, 2.3))):
            k.p("Grain%d_%d" % (sx + 2, j + 1), (0.16, h, 0.36), CF(Vector((sx * 1.47, y, z))) * cf(rx=5 * (-1) ** j),
                ("bark3", "bark4")[j], studs=False)
        for j, (a, b) in enumerate((((sx * 1.5, 3.9, 0.7), (sx * 1.52, 4.9, 0.15)),
                                    ((sx * 1.52, 4.9, 0.15), (sx * 1.5, 6.0, 0.55)),
                                    ((sx * 1.52, 4.9, 0.15), (sx * 1.5, 5.5, -0.75)))):
            k.seg("TorsoVein%d_%d" % (sx + 2, j + 1), a, b, 0.09, 0.08, "vein", material="Neon", studs=False)
        k.p("Moss%d" % (sx + 2), (1.7, 0.6, 2.1), CF(Vector((sx * 1.15, 7.65, 0.05))), "moss")
        k.p("MossTop%d" % (sx + 2), (1.1, 0.4, 1.4), CF(Vector((sx * 1.2, 8.1, 0.2))), "moss2")
        for j, z in enumerate((-0.6, 0.55)):
            k.p("MossHang%d_%d" % (sx + 2, j + 1), (0.2, 0.9 + 0.3 * j, 0.6), CF(Vector((sx * 1.9, 7.0 - 0.15 * j, z))),
                "moss", studs=False)
    k.p("MossBack", (1.3, 0.5, 1.5), CF(Vector((0, 7.6, 0.55))), "moss2")
    k.p("MossBackHang", (1.2, 1.1, 0.2), CF(Vector((0, 6.9, 1.2))), "moss", studs=False)
    for j, x in enumerate((-0.7, 0.05, 0.75)):
        k.p("BackGrain%d" % (j + 1), (0.3, 2.3 - 0.4 * (j % 2), 0.16), CF(Vector((x, 5.0, 1.32))), "bark4",
            studs=False)
    k.seg("BackVein", (0.4, 3.9, 1.33), (-0.25, 6.2, 1.33), 0.09, 0.08, "vein", material="Neon", studs=False)
    # the chest: layered gold-rimmed ivory plates with leaf glyphs round the core, a gold collar above
    f = T.plane_frame((0, 4.95, -1.1), (0, 0.05, -1))
    k.p("Collar", (2.9, 0.3, 0.32), f * CF((0, 2.1, 0.02)), "gold", studs=False)
    k.p("CollarTrim", (2.6, 0.12, 0.36), f * CF((0, 1.92, 0.04)), "gold2", studs=False)
    for i, (x, y, w, h, rz) in enumerate(((-1.02, 1.2, 0.9, 0.82, 24), (1.02, 1.2, 0.9, 0.82, -24),
                                          (-1.36, 0.32, 0.78, 0.88, 8), (1.36, 0.32, 0.78, 0.88, -8),
                                          (-1.36, -0.6, 0.78, 0.88, -8), (1.36, -0.6, 0.78, 0.88, 8),
                                          (-0.98, -1.45, 0.9, 0.78, -24), (0.98, -1.45, 0.9, 0.78, 24),
                                          (0, 1.62, 1.4, 0.5, 0), (0, -1.9, 1.05, 0.48, 0))):
        pf = f * CF((x, y, 0.02)) * cf(rz=rz)
        k.p("ChestBack%d" % (i + 1), (w + 0.14, h + 0.14, 0.18), pf * CF((0, 0, -0.03)), "gold2", studs=False)
        k.p("ChestPlate%d" % (i + 1), (w, h, 0.24), pf, "ivory", studs=False)
        k.p("ChestInset%d" % (i + 1), (w * 0.7, h * 0.66, 0.26), pf * CF((0, -0.02, 0.02)), "ivory2", studs=False)
        k.p("ChestRim%d" % (i + 1), (w + 0.08, 0.1, 0.28), pf * CF((0, h / 2, 0.01)), "gold", studs=False)
        if i < 8:
            k.p("ChestGlyph%d" % (i + 1), (0.12, 0.4, 0.08), pf * CF((0, -0.03, 0.16)), "gold", studs=False)
            k.p("ChestGlyphTip%d" % (i + 1), (0.12, 0.12, 0.08), pf * CF((0, 0.2, 0.16)) * cf(rz=45), "gold",
                studs=False)
    tips = [f.point(v) for v in ((0, 1.3, 0.13), (0.85, 0, 0.13), (0, -1.3, 0.13), (-0.85, 0, 0.13))]
    for i in range(4):  # the gold frame round the core
        a, b = tips[i], tips[(i + 1) % 4]
        d = (b - a).normalized()
        k.seg("CoreFrame%d" % (i + 1), a - d * 0.1, b + d * 0.1, 0.2, 0.22, "gold", up_hint=f.vec((0, 0, 1)),
              studs=False)
    for i, v in enumerate(((0, 1.38), (0, -1.38))):
        k.p("CoreFrameGem%d" % (i + 1), (0.26, 0.26, 0.26), f * CF((v[0], v[1], 0.16)) * cf(rz=45), "goldglow",
            material="Neon", studs=False)

    # ---- the seed core: a large glowing leaf-diamond with a bright inner facet and veins -----------------------------
    J("Core")
    k.hinge("Core", (0, 4.95, -0.9))
    for nm, sc, col, z in (("Core", 1.0, "core", 0.1), ("CoreFacet", 0.5, "core2", 0.17)):
        a, b = f.point((-0.75 * sc, 0, z)), f.point((0.75 * sc, 0, z))
        k.tri(nm + "Top", a, b, f.point((0, 1.18 * sc, z)), 0.22, col, material="Neon")
        k.tri(nm + "Bottom", a, b, f.point((0, -1.18 * sc, z)), 0.22, col, material="Neon")
    k.p("CoreVein", (0.07, 1.7, 0.1), f * CF((0, 0, 0.3)), "core2", material="Neon", studs=False)
    for sx in (-1, 1):
        k.p("CoreVeinSide%d" % (sx + 2), (0.05, 0.5, 0.1), f * CF((sx * 0.2, 0.15, 0.3)) * cf(rz=-sx * 40), "core2",
            material="Neon", studs=False)

    # ---- shoulder plates: three long ivory plates per side fanning out like folded wings -----------------------------
    for sx, sd in A.SIDES:
        J("Plate" + sd)
        k.hinge("Plate" + sd, (sx * 1.85, 7.1, 0))
        for i, (a, b, w) in enumerate((((sx * 2.0, 7.25, -0.55), (sx * 3.65, 4.0, -1.0), 1.45),
                                       ((sx * 2.1, 6.85, 0.55), (sx * 3.95, 3.8, 1.05), 1.2),
                                       ((sx * 1.95, 6.5, 1.35), (sx * 3.2, 4.3, 2.1), 0.9))):
            a, b = Vector(a), Vector(b)
            pf = look((a + b) / 2, b - a, (sx, 0.35, 0))
            ln = (b - a).length
            nm = "Plate%s%d" % (sd, i + 1)
            k.p(nm, (w, ln, 0.28), pf, "ivory", studs=False)
            k.p(nm + "Point", (w * 0.71, w * 0.71, 0.28), pf * CF((0, -ln / 2, 0)) * cf(rz=45), "ivory", studs=False)
            k.p(nm + "Inset", (w * 0.72, ln * 0.78, 0.3), pf * CF((0, 0.05, 0.02)), "ivory2", studs=False)
            for e in (-1, 1):
                k.p("%sRim%d" % (nm, e + 2), (0.12, ln, 0.34), pf * CF((e * w / 2, 0, 0.02)), "gold", studs=False)
            k.p(nm + "RimTop", (w + 0.1, 0.14, 0.34), pf * CF((0, ln / 2, 0.02)), "gold", studs=False)
            leaf_glyph(k, nm + "Emblem", pf * CF((0, -0.1, 0.17)) * cf(rz=180), 0.85 if i == 0 else 0.68)

    # ---- head: a bone-ivory deer-skull mask, glowing green eyes, big branching horns covered in glowing leaves -----
    J("Head")
    k.hinge("Head", (0, 7.6, -0.5))
    k.p("Neck", (1.3, 1.0, 1.2), CF(Vector((0, 7.75, -0.6))), "bark")
    H = A.Frame(k, CF(Vector((0, 8.4, -1.15))) * cf(rx=-22), s=1.2)
    H.p("Mask", (1.3, 1.0, 1.1), (0, 0, 0), "ivory")
    H.p("MaskBrow", (1.45, 0.3, 0.55), (0, 0.42, -0.3), "ivory2", studs=False)
    H.p("MaskCrest", (0.45, 0.5, 0.6), (0, 0.65, -0.05), "ivory", studs=False)
    H.p("Snout", (0.75, 0.55, 1.05), (0, -0.28, -0.95), "ivory")
    H.p("SnoutTip", (0.5, 0.4, 0.55), (0, -0.36, -1.6), "ivory2", studs=False)
    H.p("NasalRidge", (0.26, 0.12, 1.2), (0, 0.02, -1.05), "ivory2", studs=False)
    H.p("Jaw", (0.9, 0.3, 0.95), (0, -0.62, -0.5), "bark", studs=False)
    for sx in (-1, 1):
        H.p("Nostril%d" % (sx + 2), (0.06, 0.1, 0.22), (sx * 0.26, -0.36, -1.62), "ink", studs=False)
        H.p("CheekPlate%d" % (sx + 2), (0.25, 0.6, 0.75), (sx * 0.63, -0.2, -0.3), "ivory2", rz=sx * 12,
            studs=False)
        H.p("Socket%d" % (sx + 2), (0.4, 0.28, 0.06), (sx * 0.33, 0.1, -0.56), "ink", rz=-sx * 15, studs=False)
        H.p("Eye%d" % (sx + 2), (0.3, 0.14, 0.06), (sx * 0.33, 0.1, -0.6), "eye", rz=-sx * 15, material="Neon",
            studs=False)
    H.p("BrowGem", (0.22, 0.22, 0.08), (0, 0.42, -0.6), "core", rz=45, material="Neon", studs=False)
    for sx, sd in A.SIDES:
        base = H.pt((sx * 0.4, 0.5, 0.05))
        pts = A.branch(k, "Horn" + sd, base, (((sx * 0.5, 1, 0.15), 0.85), ((sx * 1, 0.7, 0.05), 1.0),
                                              ((sx * 0.7, 1, -0.05), 0.8), ((sx * 0.3, 1, 0), 0.55)), "bark",
                       w0=0.38, taper=0.8)
        ta = A.branch(k, "HornTineA" + sd, pts[1], (((sx, 0.3, -0.35), 0.7), ((sx * 0.4, 1, 0), 0.4)), "bark2",
                      w0=0.22)
        tb = A.branch(k, "HornTineB" + sd, pts[2], (((sx * 0.3, 1, 0.4), 0.7),), "bark2", w0=0.2)
        tc = A.branch(k, "HornTineC" + sd, pts[3], (((sx, 0.5, 0), 0.55),), "bark2", w0=0.17)
        for i, (p, d) in enumerate(((pts[4], (sx * 0.2, 1, -0.1)), (pts[4], (sx, 0.4, 0.2)),
                                    (pts[3], (-sx * 0.4, 1, 0.3)), (ta[2], (sx * 0.3, 1, -0.3)),
                                    (ta[1], (sx, 0.1, -0.5)), (ta[1], (sx * 0.5, -0.4, 0.3)), (tb[1], (0, 1, 0.3)),
                                    (tb[1], (sx, 0.5, 0.4)), (tc[1], (sx, 0.6, -0.2)), (tc[1], (sx * 0.6, -0.3, 0.2)),
                                    (pts[2], (sx * 0.6, 0.2, -0.7)), (pts[1], (-sx * 0.2, 1, -0.4)))):
            d = Vector(d)
            glowleaf(k, "HornLeaf%s%d" % (sd, i + 1), p, d, 0.7 if i < 8 else 0.55, 0.38,
                     normal=d.cross(Vector((0, 0, 1))).cross(d) + Vector((0, 0, -0.3)))

    # ---- the halo: a large double gold ring with glowing runes, a star on top and diamonds at the sides ------------
    J("HaloRing")  # not "Halo": Anim/Spin would spin a joint by that name about Y
    hc = Vector((0, 9.2, 0.5))
    k.hinge("HaloRing", hc)
    T.ring(k, "Halo", hc, (0, 0, 1), 2.2, 26, 0.24, 0.26, ("halo", "gold"), studs=False)
    T.ring(k, "HaloInner", hc + Vector((0, 0, -0.02)), (0, 0, 1), 1.92, 18, 0.1, 0.08, "goldglow", mat="Neon",
           studs=False)
    for i in range(10):
        a = 2 * math.pi * (i + 0.5) / 10
        p = hc + Vector((math.cos(a) * 2.2, math.sin(a) * 2.2, -0.14))
        k.p("HaloRune%d" % (i + 1), (0.12, 0.09, 0.06), look(p, Vector((-math.sin(a), math.cos(a), 0)), (0, 0, -1)),
            "goldglow", material="Neon", studs=False)
    T.star4(k, "HaloStar", hc + Vector((0, 2.5, -0.05)), (0, 0, -1), 0.65, "goldglow", core="halo")
    for sx in (-1, 1):
        k.p("HaloDiamond%d" % (sx + 2), (0.36, 0.36, 0.2), CF(hc + Vector((sx * 2.25, 0, -0.05))) * cf(rz=45),
            "halo", studs=False)
        k.p("HaloDiamondGlow%d" % (sx + 2), (0.18, 0.18, 0.24), CF(hc + Vector((sx * 2.25, 0, -0.07))) * cf(rz=45),
            "goldglow", material="Neon", studs=False)

    # ---- six great roots: thick, arching high and out, running along the ground; moss, veins, grass, rootlets -------
    for sx, sd in A.SIDES:
        for joint, pts in (("Arm" + sd, ((0.95, 2.9, -0.8), (2.1, 4.0, -1.7), (3.2, 3.0, -2.6), (3.7, 1.0, -3.0),
                                         (4.3, 0.3, -3.5))),
                           ("Root" + sd, ((1.25, 2.8, 0.2), (2.7, 3.9, 0.3), (3.9, 2.8, 0.4), (4.4, 0.9, 0.5),
                                          (5.1, 0.3, 0.6))),
                           ("Leg" + sd, ((0.95, 2.9, 1.3), (2.05, 3.85, 2.3), (2.95, 2.8, 3.2), (3.35, 0.9, 3.7),
                                         (3.85, 0.3, 4.3)))):
            J(joint)
            k.hinge(joint, (sx * pts[0][0], pts[0][1], pts[0][2]))
            P = root(k, joint, [(sx * x, y, z) for x, y, z in pts], (1.3, 1.1, 0.88, 0.66), veins=3)
            k.p(joint + "Knob", (1.2, 1.15, 1.2), CF(P[1]) * cf(ry=30), "bark3")
            k.p(joint + "Moss", (1.1, 0.28, 1.2), CF(P[1] + Vector((0, 0.66, 0))) * cf(ry=30), "moss2", studs=False)
            k.p(joint + "MossLow", (0.7, 0.22, 0.8), CF(P[3] + Vector((0, 0.42, 0))) * cf(ry=20), "moss", studs=False)
            out = Vector((P[4].x - P[3].x, 0, P[4].z - P[3].z)).normalized()
            for t, ang in enumerate((-40, 40)):
                c, s_ = math.cos(math.radians(ang)), math.sin(math.radians(ang))
                dd = Vector((out.x * c - out.z * s_, 0, out.x * s_ + out.z * c))
                b = P[3] + Vector((0, -0.3, 0)) + dd * 0.2
                k.seg("%sRootlet%d" % (joint, t + 1), b, Vector((b.x, 0.12, b.z)) + dd * 0.8, 0.26, 0.22, "bark",
                      studs=False)
            grass(k, joint + "Grass", Vector((P[4].x, 0, P[4].z)) + out * 0.3)

    # ---- the root mass: smaller roots between the great ones and two long roots trailing behind (they stay put) ----
    J("Body")
    k.p("RootFlare", (2.3, 0.9, 2.0), CF(Vector((0, 1.3, 0.3))) * cf(ry=12), "bark2")
    k.p("RootFlare2", (1.7, 0.85, 1.5), CF(Vector((0, 0.45, 0.3))) * cf(ry=-10), "bark3")
    for sx in (-1, 1):
        k.seg("FlareVein%d" % (sx + 2), (sx * 0.4, 0.2, -0.47), (sx * 0.15, 1.7, -0.72), 0.09, 0.06, "vein",
              material="Neon", studs=False)
    for i, (sx, sz) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        root(k, "SmallRoot%d" % (i + 1), ((sx * 0.8, 1.2, 0.3 + sz * 0.75), (sx * 1.75, 0.4, 0.3 + sz * 1.55),
                                          (sx * 2.5, 0.22, 0.3 + sz * 2.2)), (0.72, 0.5), veins=1)
    for sx in (-1, 1):
        P = root(k, "TrailRoot%d" % (sx + 2), ((sx * 0.55, 2.5, 1.5), (sx * 0.85, 1.7, 3.0), (sx * 1.05, 0.55, 4.3),
                                              (sx * 1.2, 0.28, 5.4)), (0.95, 0.75, 0.55), veins=2)
        grass(k, "TrailGrass%d" % (sx + 2), Vector((P[3].x, 0, P[3].z)))

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
