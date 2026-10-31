# 79 Prism Seraph V3 (Rainbow Heaven, Secret), Roblox primitives only (Frost Serpent method, studs on top faces).
# Built to the user's reference (2026-10-31): an armoured white-and-gold angel knight hovering in a symmetric pose. A
# white helm with a dark visor and glowing cyan eyes, a gold crown of spikes and a tall prism crystal; a white chest
# with gold trims and a big glowing four-point star with a crystal behind it; heavy layered pauldrons, segmented
# arms with gold cuffs, gold rings round the forearms with stars, big gauntlets; a waist of armour plates and long
# tabard panels with gold edges ending in crystal tips (no legs: it floats); two great wings of white armour plates and
# long iridescent prism crystals fanning up and down; a gold halo arc with stars and a small spinning halo; prism
# shards and gold stars floating round it. Palette: white, gold, iridescent prism glass, cyan eye glow.
# Joints: Body, Head, ArmL/R, WingL/R, Halo, Orbit.
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use
from v3 import top_parts as T

PRISM = ("FF8FCB", "8FC8FF", "FFE57A", "B59BFF", "7FF0CF", "FFB88A")
PAL = dict(main="F5F3FA", main2="DCD8E6", dark="1E1A2E", light="FFFFFF", glow="FFE38A", gold="E0B24E",
           gold2="C4932F", eye="7FE8FF", glass="E2D6FF", tip="FFFFFF", visor="1E1A2E")
CONCEPT = "Prism Seraph: armoured white-gold angel knight, prism crystal wings, star heart, halo arcs, floating crystals"
HEADER = '''--!strict
-- 79 Prism Seraph V3 (Rainbow Heaven, Secret). Preview candidate (KICK_AN_EGG_PET_REMODEL_V3), not wired.
-- Pet: an armoured white-and-gold angel knight hovering (the user's reference): a helm with a dark visor, cyan eyes, a
--      gold spike crown and a prism crystal; a glowing star on the chest; layered pauldrons; gauntlets with gold rings
--      and stars; tabard panels ending in crystals; two great wings of armour plates and faceted crystal feathers
--      in six prism hues with glowing cores; a halo arc with stars, a spinning halo, floating diamond crystals and
--      stars.
-- Egg: pearl terraces, a band of prism crystals, gold bands, a glowing star on the front, prism crystals on top, the
--      Secret band, a halo arc with stars and orbiting shards.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/prism_seraph.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.1


def prism(k, name, base, d, length, width, col, n=2):
    """A long prism crystal: tinted glass body and a glowing tip in the same hue (n=3 adds a mid section)."""
    k.crystal(name, Vector(base), Vector(d), length, width, n=n, body=col, tip=col, hint=(0, 0, 1))


def blade(k, name, base, d, length, width, col, face=(0, 0, -1), mid=0.32):
    """A faceted crystal feather (the reference's wings): a kite of tinted glass, widest at `mid` of its length (0.5 is
    a floating diamond) and facing `face`, with a glowing core along its axis."""
    d = Vector(d).normalized()
    n = Vector(face)
    n = (n - d * n.dot(d)).normalized()
    side = n.cross(d).normalized()
    b = Vector(base)
    m = b + d * length * mid
    lft, rgt, tip = m - side * width / 2, m + side * width / 2, b + d * length
    k.tri(name + "A", b, lft, rgt, 0.2, col, material="Glass", transp=0.2)
    k.tri(name + "B", lft, tip, rgt, 0.2, col, material="Glass", transp=0.2)
    k.seg(name + "Core", b + d * 0.12, b + d * length * 0.78, 0.08, 0.26, col, up_hint=tuple(n), material="Neon",
          studs=False)


def build(name="PK3_PrismSeraph_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: chest with the star heart, waist plates, tabard panels with crystal tips (floats: nothing below 0.6) ---
    J("Body")
    k.hinge("Body", (0, 5.4, 0))
    k.p("Chest", (2.0, 1.7, 1.3), CF(Vector((0, 6.0, 0))), "main")
    k.p("ChestUpper", (2.2, 0.5, 1.4), CF(Vector((0, 6.95, 0))), "main2")
    k.p("Collar", (1.3, 0.3, 1.1), CF(Vector((0, 7.3, 0))), "gold", studs=False)
    for sx, sd in A.SIDES:
        k.p("ChestTrim" + sd, (0.12, 1.6, 0.1), CF(Vector((sx * 0.72, 6.0, -0.68))), "gold", studs=False)
        k.p("Rib" + sd, (0.5, 0.12, 0.08), CF(Vector((sx * 0.55, 5.45, -0.68))) * cf(rz=sx * 20), "gold",
            studs=False)
    k.crystal("HeartPrism", (0, 6.0, -0.55), (0, 1, 0.1), 1.4, 0.42, n=3, body="glass", tip="tip")
    T.star4(k, "HeartStar", (0, 6.15, -0.82), (0, 0, -1), 0.95, "glow", core="light")
    k.p("Waist", (1.5, 0.7, 1.05), CF(Vector((0, 4.85, 0))), "main2")
    k.p("Belt", (1.7, 0.22, 1.2), CF(Vector((0, 5.18, 0))), "gold", studs=False)
    for i, (x, z, ry) in enumerate(((0, -0.6, 0), (0, 0.6, 180), (-0.8, 0, -90), (0.8, 0, 90))):  # hip plates
        k.p("HipPlate%d" % (i + 1), (0.9, 0.9, 0.14), CF(Vector((x, 4.45, z))) * cf(ry=ry, rx=-12), "main")
    panels = (("Front", 0.0, -0.7, 0.75, 3.1, 0), ("SideL", -0.75, -0.45, 0.5, 2.7, 14), ("SideR", 0.75, -0.45, 0.5,
                                                                                            2.7, -14))
    for nm, x, z, w, h, rz in panels:
        top = Vector((x, 4.65, z))
        f = CF(top) * cf(rz=rz)
        k.p("Tabard" + nm, (w, h, 0.1), f * CF((0, -h / 2, 0)), "main", studs=False)
        for sx in (-1, 1):
            k.p("TabardEdge%s%d" % (nm, (sx + 1) // 2), (0.1, h, 0.12), f * CF((sx * (w / 2), -h / 2, -0.01)), "gold",
                studs=False)
        tipc = f.point((0, -h - 0.05, 0))
        prism(k, "TabardTip" + nm, tipc + Vector((0, 0.35, 0)), (0, -1, 0), 0.9, w * 0.55, PRISM[len(nm) % 6], n=2)
        T.star4(k, "TabardStar" + nm, f.point((0, -h * 0.4, -0.08)), (0, 0, -1), 0.24 if nm != "Front" else 0.32,
                "glow", core="light")

    # ---- halo arc with stars behind the head, a small spinning halo above it ----------------------------------------
    hc = Vector((0, 8.25, 0.65))
    for i in range(17):
        a = math.radians(-30 + i * (240 / 16))
        p = hc + Vector((math.cos(a), math.sin(a), 0)) * 2.1
        k.p("Arc%d" % (i + 1), (0.46, 0.14, 0.16), look(p, Vector((0, 0, 1)), Vector((math.cos(a), math.sin(a), 0)))
            * cf(ry=90), "gold" if i % 2 else "glow", material="SmoothPlastic" if i % 2 else "Neon", studs=False)
    for i, a in enumerate((90, 160, 20)):
        r = math.radians(a)
        T.star4(k, "ArcStar%d" % (i + 1), hc + Vector((math.cos(r), math.sin(r), 0)) * 2.1 + Vector((0, 0, -0.05)),
                (0, 0, -1), 0.6 if a == 90 else 0.42, "gold", core="light", mat="SmoothPlastic")
    J("Halo")
    sh_c = Vector((0, 8.95, 0.0))
    T.hub(k, "Halo", sh_c, (0, 1, 0))
    T.ring(k, "Halo", sh_c, (0, 1, 0), 0.75, 12, 0.1, 0.14, "glow", mat="Neon")

    # ---- head: white helm, dark visor with cyan eyes, gold spike crown, tall prism crystal ---------------------------
    J("Head")
    k.hinge("Head", (0, 7.4, 0.0))
    k.p("Helm", (1.05, 1.15, 1.05), CF(Vector((0, 8.0, 0.0))), "main")
    k.p("Visor", (0.78, 0.55, 0.1), CF(Vector((0, 7.92, -0.53))), "visor", studs=False)
    k.p("VisorRim", (0.86, 0.1, 0.12), CF(Vector((0, 8.22, -0.55))), "gold", studs=False)
    k.p("Chin", (0.72, 0.28, 0.4), CF(Vector((0, 7.5, -0.42))), "main2", studs=False)
    for sx, sd in A.SIDES:
        k.p("Eye" + sd, (0.16, 0.12, 0.05), CF(Vector((sx * 0.18, 7.96, -0.6))) * cf(rz=-sx * 12), "eye",
            material="Neon")
        k.p("Pupil" + sd, (0.06, 0.08, 0.04), CF(Vector((sx * 0.16, 7.96, -0.63))), "light", material="Neon",
            studs=False)
        k.p("Glint" + sd, (0.04, 0.04, 0.03), CF(Vector((sx * 0.24, 8.0, -0.64))), "glint", material="Neon",
            studs=False)
        k.p("HelmWing" + sd, (0.14, 0.6, 0.5), CF(Vector((sx * 0.6, 8.15, 0.05))) * cf(rz=-sx * 25), "gold",
            shape="Wedge", studs=False)
    for i, (x, h) in enumerate(((0, 0.0), (-0.3, 0.42), (0.3, 0.42), (-0.48, 0.3), (0.48, 0.3))):
        if i == 0:
            continue
        T.spire(k, "Crown%d" % i, (x, 8.55, -0.3), h, 0.16, "gold", "glow")
    prism(k, "CrownPrism", (0, 8.5, -0.1), (0, 1, 0.05), 1.5, 0.48, "FFE9FF", n=3)

    # ---- arms: layered pauldrons, segmented arms, gold cuffs, rings with stars, gauntlets ----------------------------
    for sx, sd in A.SIDES:
        J("Arm" + sd)
        sh = Vector((sx * 1.25, 6.8, 0.0))
        k.hinge("Arm" + sd, sh)
        k.p("Pauldron" + sd, (1.2, 0.85, 1.35), CF(Vector((sx * 1.55, 7.05, 0.0))) * cf(rz=-sx * 12), "main")
        k.p("Pauldron2" + sd, (1.0, 0.5, 1.15), CF(Vector((sx * 1.7, 6.6, 0.0))) * cf(rz=-sx * 18), "main2")
        k.p("PauldronGold" + sd, (1.24, 0.12, 1.4), CF(Vector((sx * 1.55, 7.5, 0.0))) * cf(rz=-sx * 12), "gold",
            studs=False)
        k.crystal("PauldronPrism" + sd, (sx * 1.6, 7.4, 0.0), (sx * 0.4, 1, 0), 0.7, 0.26, n=2,
                  body=PRISM[1 if sx < 0 else 3], tip="tip")
        el = Vector((sx * 1.85, 5.6, -0.2))
        k.p("UpperArm" + sd, (0.62, 1.0, 0.66), CF((sh + el) / 2 + Vector((sx * 0.25, -0.15, 0))), "main2")
        k.p("Elbow" + sd, (0.58, 0.58, 0.58), CF(el), "gold", shape="Ball")
        k.p("Gauntlet" + sd, (0.82, 1.15, 0.86), CF(Vector((sx * 1.95, 4.85, -0.3))), "main")
        k.p("GauntletPlate" + sd, (0.88, 0.5, 0.92), CF(Vector((sx * 1.95, 5.15, -0.3))), "main2")
        k.p("Cuff" + sd, (0.92, 0.16, 0.96), CF(Vector((sx * 1.95, 4.42, -0.3))), "gold", studs=False)
        k.p("Hand" + sd, (0.72, 0.62, 0.76), CF(Vector((sx * 1.95, 3.98, -0.32))), "main")
        for j, dx in enumerate((-0.22, 0.0, 0.22)):
            k.p("Finger%s%d" % (sd, j + 1), (0.18, 0.36, 0.2), CF(Vector((sx * 1.95 + dx, 3.62, -0.55))), "main2",
                studs=False)
        rc = Vector((sx * 1.95, 4.9, -0.3))
        T.ring(k, "ArmRing" + sd, rc, (0, 1, 0), 0.82, 10, 0.08, 0.12, "gold", studs=False)
        T.star4(k, "ArmStar" + sd, rc + Vector((sx * 0.85, 0, -0.3)), (sx, 0, -0.5), 0.3, "glow", core="light")

    # ---- wings: white armour plates along a raised arm, faceted crystal feather-blades fanning up and down ---------
    for sx, sd in A.SIDES:
        J("Wing" + sd)
        S = Vector((sx * 0.6, 6.9, 0.65))
        k.p("WingRoot" + sd, (0.5, 0.5, 0.5), CF(S), "gold", shape="Ball")
        E = S + Vector((sx * 1.4, 0.9, 0.35))
        W = E + Vector((sx * 1.3, 0.55, 0.15))
        for j, (a, b, w) in enumerate(((S, E, 0.55), (E, W, 0.46))):
            k.seg("WingArm%s%d" % (sd, j + 1), a, b, w, 0.42, "main")
            k.seg("WingPlate%s%d" % (sd, j + 1), a + Vector((0, 0.22, -0.05)), b + Vector((0, 0.22, -0.05)), w * 1.25,
                  0.16, "main2", studs=False)
            k.seg("WingGold%s%d" % (sd, j + 1), a + Vector((0, -0.24, -0.08)), b + Vector((0, -0.24, -0.08)), 0.12,
                  0.12, "gold", studs=False)
        for j in range(6):  # white armour feathers hanging under the arm
            t = (j + 0.5) / 6
            base = S.lerp(W, t) + Vector((0, -0.35, 0.05))
            d = Vector((sx * 0.35, -1, 0.2)).normalized()
            k.p("Plume%s%d" % (sd, j + 1), (0.42, 1.05 - 0.08 * j, 0.14), look(base + d * 0.45, d, Vector((0, 0, 1))),
                "main" if j % 2 == 0 else "main2", studs=False)
        ups = ((0.15, 1.0, 2.6), (0.5, 1.0, 3.0), (0.85, 0.85, 3.2), (1.0, 0.45, 3.0), (1.0, 0.05, 2.6),
               (0.95, -0.3, 2.2))
        for j, (dx, dy, ln) in enumerate(ups):  # the great prism feathers from the wrist and forearm
            base = W.lerp(E, 0.12 * j)
            blade(k, "Prism%s%d" % (sd, j + 1), base, (sx * dx, dy, 0.15), ln, 0.95, PRISM[j % 6])
        for j, (dx, dy, ln) in enumerate(((0.3, 1.0, 1.7), (0.7, 0.9, 1.9), (0.95, 0.5, 1.9), (1.0, 0.05, 1.6),
                                          (0.85, -0.4, 1.4))):  # an inner row of shorter crystals (depth, layering)
            base = W.lerp(E, 0.5 + 0.1 * j) + Vector((0, 0.1, -0.25))
            blade(k, "InnerPrism%s%d" % (sd, j + 1), base, (sx * dx, dy, 0.05), ln, 0.7, PRISM[(j + 2) % 6])
        for j, (dx, dy, ln) in enumerate(((0.75, -0.75, 2.2), (0.5, -1.0, 2.4), (0.25, -1.0, 2.0), (0.05, -1.0, 1.6))):
            base = E.lerp(S, 0.28 * j) + Vector((0, -0.2, 0))
            blade(k, "LowPrism%s%d" % (sd, j + 1), base, (sx * dx, dy, 0.2), ln, 0.8, PRISM[(j + 3) % 6])

    # ---- floating prism shards and gold stars (Orbit) -----------------------------------------------------------------
    oc = Vector((0, 5.2, 0))
    T.hub(k, "Orbit", oc, (0, 1, 0))
    for i in range(14):
        a = 2 * math.pi * i / 14 + 0.2
        p = oc + Vector((math.cos(a) * 3.8, 1.4 * math.sin(2 * a) - 0.6 * (i % 2), math.sin(a) * 3.8))
        if i % 2 == 0:
            blade(k, "Shard%d" % (i + 1), p - Vector((0, 0.75, 0)), (0, 1, 0), 1.5, 0.78, PRISM[i % 6],
                  face=(math.cos(a), 0, math.sin(a)), mid=0.5)
        else:
            T.star4(k, "FloatStar%d" % (i + 1), p, (math.cos(a), 0, math.sin(a)), 0.3, "gold", core="glow",
                    mat="SmoothPlastic")
    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
