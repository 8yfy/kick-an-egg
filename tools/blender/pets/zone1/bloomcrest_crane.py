# Bloomcrest Crane (Zone 1 Meadow, Legendary): a magnificent tall crane, Roblox primitives only (Frost Serpent
# method). Majestic: a pearl-white body carried high, a long S-curved neck, a slim head with a gold mask, a glowing gold
# eye, a long gold beak and a pink lotus crest with a glowing core; a lotus brooch on the breast. The wings are the
# showpiece: raised and swept back, each a gold-edged arm carrying layered rows of feather plates (green coverts, blush
# secondaries, pearl primaries with pink tips) that fan wider towards the hand; a long sweep of pink, pearl and gold
# tail feathers; long charcoal-brown legs with gold bands, a backward ankle and gold feet.
# Joints: Body, Neck, Head, WingL/R (the shoulder: Bloomwing Display raises and fans them), LegL/R, Tail.
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use

NAME, RARITY = "Bloomcrest Crane", "Legendary"
PAL = dict(main="FFF6EA", main2="F5E9D6", dark="6B4A3A", light="FFFFFF", glow="FFD45A", pink="FF86B4",
           pink2="F2639E", blush="FFB3CF", leaf="6CC23A", leaf2="4FA83A", gold="F5B935", gold2="D99A22",
           lotus="FF7EB6", lotus2="FFB0D0", core="FFE58A", leg="7A4A26", eye="FFD24A", ink="1E140E")
CONCEPT = "Bloomcrest Crane: a pearl-white crane, lotus crest, gold mask and beak, layered blush-and-pearl wings"
HEADER = '''--!strict
-- Bloomcrest Crane (Zone 1 Meadow, Legendary). Preview candidate (KickAnEgg_PremiumPets/Zone01_Meadow), not wired.
-- Pet: a pearl-white crane: a long S-curved neck, a gold mask, glowing gold eye and long gold beak, a pink lotus crest
--      with a glowing core and a lotus brooch; raised wings with a gold leading edge and layered rows of feather
--      plates (green coverts, blush secondaries, pearl primaries with pink tips); a long pink-pearl-gold tail sweep;
--      long legs with gold bands and gold feet. Joints: Body, Neck, Head, WingL/R, LegL/R, Tail.
-- Egg: a tall pearl egg with pink feather plates, gold trim, green leaves and a lotus crest.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/bloomcrest_crane.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.1


def feather(k, name, base, d, length, width, col, tip=None, normal=(0, 1, 0), thick=0.12):
    """A feather plate: a long blade and a pointed tip (a square turned 45 degrees), the tip in its own colour."""
    d = Vector(d).normalized()
    b = Vector(base)
    n = Vector(normal)
    n = (n - d * n.dot(d)).normalized()
    k.p(name, (width, length * 0.8, thick), look(b + d * length * 0.4, d, n), col, studs=False)
    e = width * 0.7071
    k.p(name + "Tip", (e, e, thick * 0.95), look(b + d * length * 0.8, d, n) * cf(rz=45), tip or col, studs=False)


def lotus(k, name, centre, up, size, petal="lotus", petal2="lotus2", core="core"):
    """A lotus: an inner and an outer ring of pointed petals round a glowing core."""
    up = Vector(up).normalized()
    side = up.cross(Vector((0, 0, 1)) if abs(up.z) < 0.9 else Vector((1, 0, 0))).normalized()
    fwd = up.cross(side)
    c = Vector(centre)
    for ring, (n, tilt, ln, col, ph) in enumerate(((6, 0.55, size, petal, 0.0), (5, 0.25, size * 0.8, petal2, 0.5))):
        for i in range(n):
            a = 2 * math.pi * (i + ph) / n
            out = side * math.cos(a) + fwd * math.sin(a)
            d = (up + out * (1 / max(tilt, 0.05)) * 0.35).normalized() if ring == 0 else (up * 1.3 + out * 0.4)
            feather(k, "%sPetal%d_%d" % (name, ring + 1, i + 1), c + out * size * 0.12, d, ln, size * 0.42, col,
                    normal=out)
    k.p(name + "Core", (size * 0.36, size * 0.36, size * 0.36), CF(c + up * size * 0.25) * cf(rx=45, ry=45), core,
        material="Neon", studs=False)


def build(name="Z1_BloomcrestCrane_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a full pearl body carried high, breast forward, layered back feathers, a lotus brooch ------------------
    J("Body")
    k.hinge("Body", (0, 3.8, 0.3))
    k.p("Breast", (1.85, 1.85, 1.6), CF(Vector((0, 4.2, -0.55))) * cf(rx=-22), "main")
    k.p("Belly", (1.75, 1.45, 1.9), CF(Vector((0, 3.7, 0.55))) * cf(rx=-12), "main2")
    k.p("Back", (1.55, 0.45, 2.4), CF(Vector((0, 4.6, 0.3))) * cf(rx=-12), "main")
    k.p("Rump", (1.35, 1.05, 1.0), CF(Vector((0, 3.85, 1.55))) * cf(rx=-25), "main")
    for i, (x, z) in enumerate(((-0.45, -0.3), (0.45, -0.3), (-0.5, 0.5), (0.5, 0.5), (0.0, 1.15))):  # back feathers
        feather(k, "BackFeather%d" % (i + 1), (x, 4.9 - 0.12 * z, z - 0.35), (x * 0.3, -0.3, 1), 1.1, 0.7,
                "main2" if i % 2 else "light", tip="blush", normal=(x * 0.4, 1, 0.25))
    k.p("BreastPlate", (1.15, 1.1, 0.12), CF(Vector((0, 4.25, -1.4))) * cf(rx=-22), "gold", studs=False)
    lotus(k, "Brooch", (0, 4.3, -1.52), (0, 0.2, -1), 0.62)

    # ---- tail: a long sweep of pink, pearl and gold feathers ----------------------------------------------------------
    J("Tail")
    k.hinge("Tail", (0, 3.9, 1.65))
    for i, (x, ln, col, tip, drop) in enumerate(((0, 3.6, "pink", "gold", 1.0), (-0.35, 3.3, "light", "pink2", 1.1),
                                                 (0.35, 3.3, "light", "pink2", 1.1),
                                                 (-0.7, 2.9, "pink2", "gold", 1.25), (0.7, 2.9, "pink2", "gold", 1.25),
                                                 (-0.2, 3.0, "blush", "pink", 1.35), (0.2, 3.0, "blush", "pink", 1.35))):
        d = Vector((x * 0.45, -drop, 1))
        feather(k, "TailFeather%d" % (i + 1), (x * 0.4, 3.85 - 0.08 * i, 1.6), d, ln, 0.42 if i == 0 else 0.36, col,
                tip=tip, normal=(x * 0.3, 1, 0.3))

    # ---- wings: raised in a V and swept back; a gold leading edge over dense, overlapping rows of feather plates -----
    for sx, sd in A.SIDES:
        J("Wing" + sd)
        S = Vector((sx * 0.7, 4.65, -0.2))
        k.hinge("Wing" + sd, S)
        E = S + Vector((sx * 1.05, 1.45, 0.65))  # elbow
        W = E + Vector((sx * 0.95, 1.3, 0.75))  # wrist
        T = W + Vector((sx * 0.55, 0.6, 0.75))  # hand tip
        k.p("Shoulder" + sd, (0.7, 0.7, 0.7), CF(S), "main", shape="Ball")
        for i, (a, b, w) in enumerate(((S, E, 0.55), (E, W, 0.46), (W, T, 0.36))):
            k.seg("WingBone%s%d" % (sd, i + 1), a, b, w, w * 0.8, "main")
            k.seg("WingEdge%s%d" % (sd, i + 1), a + Vector((sx * 0.08, w * 0.42, -0.15)),
                  b + Vector((sx * 0.08, w * 0.42, -0.15)), w * 0.42, w * 0.5, "gold", studs=False)
        arm = (S, E, W, T)

        def along(t):
            seg_t = t * 3
            i = min(2, int(seg_t))
            return arm[i].lerp(arm[i + 1], seg_t - i)

        face = (sx, 0.3, -0.6)  # the sail faces out and a little forward: it reads from the side and the front
        # primaries: long pearl plates with pink tips at the hand, fanning from back to back-and-down
        for i in range(7):
            t = 0.7 + 0.3 * i / 6
            d = Vector((sx * 0.25, 0.15 - 0.17 * (6 - i), 1)).normalized()
            feather(k, "Primary%s%d" % (sd, i + 1), along(t), d, 2.5 + 0.2 * i, 0.8, "light" if i % 2 else "main",
                    tip="pink", normal=face)
        # secondaries: blush and pink, hanging from the forearm like a curtain
        for i in range(7):
            t = 0.3 + 0.42 * i / 6
            d = Vector((sx * 0.08, -0.85 + 0.05 * i, 0.55)).normalized()
            feather(k, "Secondary%s%d" % (sd, i + 1), along(t), d, 2.3, 0.8, "pink" if i % 2 else "blush",
                    tip="pink2", normal=face)
        # coverts: shorter green and gold-tipped plates over the top of the secondaries
        for i in range(7):
            t = 0.05 + 0.62 * i / 6
            d = Vector((sx * 0.08, -0.9, 0.45)).normalized()
            feather(k, "Covert%s%d" % (sd, i + 1), along(t) + Vector((sx * 0.1, 0.1, 0)), d, 1.2, 0.72,
                    "leaf" if i % 2 == 0 else "leaf2", tip="gold", normal=face)
        lotus(k, "WingLotus" + sd, along(0.68) + Vector((sx * 0.2, 0.15, -0.1)), (sx, 0.5, -0.1), 0.5)

    # ---- neck: a long S-curve -------------------------------------------------------------------------------------------
    J("Neck")
    k.hinge("Neck", (0, 4.6, -1.0))
    A.spine(k, "Neck", [(0, 4.5, -0.95), (0, 5.4, -1.45), (0, 6.35, -1.25), (0, 7.2, -1.45), (0, 7.85, -1.95)], 7,
            [(0, 0.62), (1, 0.42)], [(0, 0.62), (1, 0.42)], col=("main", "main2"), stretch=1.15)
    k.p("NeckGold", (0.5, 0.18, 0.5), look(Vector((0, 5.0, -1.25)), (0, 1, -0.5)), "gold", studs=False)
    k.p("Collar", (1.05, 0.26, 1.0), look(Vector((0, 4.72, -1.1)), (0, 1, -0.45)), "gold", studs=False)
    k.p("CollarTrim", (1.12, 0.08, 1.06), look(Vector((0, 4.6, -1.06)), (0, 1, -0.45)), "gold2", studs=False)

    # ---- head: a gold mask, a glowing eye, a long gold beak, the lotus crest --------------------------------------------
    J("Head")
    k.hinge("Head", (0, 7.85, -1.95))
    H = A.Frame(k, CF(Vector((0, 8.05, -2.2))) * cf(rx=-8), s=1.0)
    H.p("Skull", (0.6, 0.62, 0.85), (0, 0, 0), "main")
    H.p("Mask", (0.66, 0.3, 0.6), (0, 0.06, -0.18), "gold", studs=False)
    H.p("MaskTip", (0.42, 0.22, 0.3), (0, 0.02, -0.55), "gold2", studs=False)
    A.eyes(H, "side", 0.34, 0.08, -0.12, 0.24, 0.13, iris="eye")
    pts = [H.pt((0, -0.05, -0.55)), H.pt((0, -0.12, -1.25)), H.pt((0, -0.2, -1.85))]
    k.seg("Beak1", pts[0], pts[1], 0.3, 0.28, "gold")
    k.seg("Beak2", pts[1], pts[2], 0.18, 0.16, "gold2")
    k.seg("BeakLine", H.pt((0, -0.13, -0.6)), H.pt((0, -0.16, -1.5)), 0.32, 0.03, "dark", studs=False)
    lotus(k, "Crest", H.pt((0, 0.4, 0.08)), H.vec((0, 1, 0.3)), 0.95)
    for sx, sd in A.SIDES:  # two long plumes trailing back from the crest
        feather(k, "Plume" + sd, H.pt((sx * 0.15, 0.3, 0.3)), H.vec((sx * 0.2, 0.25, 1)), 1.3, 0.22, "pink2",
                tip="gold", normal=H.vec((0, 1, 0)))

    # ---- legs: long, charcoal-brown, gold bands, the ankle bending back, gold feet --------------------------------------
    for sx, sd in A.SIDES:
        J("Leg" + sd)
        hip = Vector((sx * 0.38, 3.35, 0.45))
        k.hinge("Leg" + sd, hip)
        ankle = Vector((sx * 0.42, 1.65, 0.75))
        foot = Vector((sx * 0.45, 0.2, 0.45))
        k.p("Thigh" + sd, (0.55, 0.8, 0.65), CF(hip + Vector((0, -0.25, 0))), "main2")
        k.seg("Shank" + sd, hip + Vector((0, -0.45, 0)), ankle, 0.32, 0.32, "leg")
        k.seg("Tarsus" + sd, ankle, foot, 0.28, 0.28, "leg")
        k.p("Ankle" + sd, (0.42, 0.36, 0.42), CF(ankle), "gold", studs=False)
        k.p("Band" + sd, (0.42, 0.42, 0.42), CF(ankle.lerp(foot, 0.4)), "gold", studs=False)
        k.p("FootPad" + sd, (0.5, 0.2, 0.55), CF(foot + Vector((0, -0.08, -0.1))), "gold", studs=False)
        for t, d in enumerate(((-0.35, -1), (0, -1), (0.35, -1), (0, 1))):  # three toes forward, one back
            dd = Vector((d[0], 0, d[1])).normalized()
            ln = 0.75 if d[1] < 0 else 0.4
            k.seg("Toe%s%d" % (sd, t + 1), foot + Vector((0, -0.08, 0)), foot + Vector((0, -0.12, 0)) + dd * ln,
                  0.18, 0.16, "gold", studs=False)

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
