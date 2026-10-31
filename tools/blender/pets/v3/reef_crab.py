# 07 Tide Spirit V3 "Reef Crab Knight" (Sandy Beach, Epic), Roblox primitives only (Frost Serpent method, studs on
# top faces). A sea-blue crab knight: a wide armoured carapace (square shape language: stable, a knight) stepped narrow
# at the back, layered armour bands, wedge chamfers and an uneven spiky rim; a glass wave crest rising off its back
# like a breaking wave (the Epic silhouette change) with a pearl set before it; barnacles and a starfish on the shell;
# a coral-and-scallop-shell helmet with an anemone; glowing pearl eyes on ringed stalks; fiddler-crab asymmetry (one
# huge toothed claw with armour bands and a pearl, one small one); six jointed walking legs splayed out low.
# Joints: Body, Head, ArmL/R (claws), LegL/R (three legs each).
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use

PAL = dict(main="1F78D6", main2="1A68BD", dark="0F4C9C", light="F3E2B8", turq="25C6C4", coral="FF7F6B",
           coral2="E85F55", glow="5CF2FF", ink="0B1F3A", pearl="F2FBFF", glass="9FF0FF", tip="E6FDFF", star="FFB347")
CONCEPT = "Reef Crab Knight: armoured sea-blue fiddler crab, coral-and-shell helmet, pearl eyes, glass wave crest"
HEADER = '''--!strict
-- 07 Tide Spirit V3 "Reef Crab Knight" (Sandy Beach, Epic). Preview candidate (KICK_AN_EGG_PET_REMODEL_V3), not wired.
-- Pet: an armoured sea-blue fiddler crab: a stepped carapace with layered bands, chamfers and an uneven spiky rim, a
--      glass wave crest with a pearl, barnacles and a starfish, a coral-and-scallop helmet with an anemone, glowing
--      pearl eyes on ringed stalks, one huge toothed claw and one small one, six jointed legs splayed low.
-- Egg: deep-blue to turquoise terraces, a scallop shell on the front, coral up both sides, barnacles and a starfish,
--      little claw nubs, a glass wave fin, a pearl in a shell cup on top, foam at the base and the Epic band.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/reef_crab.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''


def starfish(k, name, centre, nrm, size, col):
    """Five wedge arms round a small centre, lying on a surface with normal `nrm`."""
    N = Vector(nrm).normalized()
    up = Vector((0, 0, 1)) if abs(N.z) < 0.9 else Vector((1, 0, 0))
    base = look(Vector(centre), N, up)
    k.p(name, (size * 0.42, 0.1, size * 0.42), base * cf(ry=36), col, studs=False)
    for i in range(5):
        k.p("%s%d" % (name, i + 1), (size * 0.24, 0.1, size * 0.5),
            base * cf(ry=i * 72) * CF((0, 0, -size * 0.36)), col, shape="Wedge", studs=False)


def build(name="PK3_TideSpirit_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- carapace ------------------------------------------------------------------------------------------------
    J("Body")
    k.hinge("Body", (0, 1.75, 0.1))
    # stepped outline seen from above: wide at the front, narrower at the back (a crab, not a box)
    k.p("Carapace", (3.0, 0.9, 1.45), CF(Vector((0, 1.75, -0.3))), "main")
    k.p("CarapaceBack", (2.3, 0.86, 1.05), CF(Vector((0, 1.75, 0.92))), "main")
    k.p("Plate", (2.2, 0.32, 1.9), CF(Vector((0, 2.36, 0.2))), "turq")
    for i, (z, w) in enumerate(((-0.45, 2.5), (0.25, 2.3), (0.92, 1.9))):  # layered armour bands across the back
        k.p("Band%d" % (i + 1), (w, 0.14, 0.18), CF(Vector((0, 2.56, z))), "main2", studs=False)
    k.p("RimFront", (3.0, 0.42, 0.5), CF(Vector((0, 2.16, -0.92))), "main2", shape="Wedge", studs=False)
    k.p("RimBack", (2.3, 0.42, 0.5), CF(Vector((0, 2.16, 1.36))) * cf(ry=180), "main2", shape="Wedge", studs=False)
    for sx, sd in A.SIDES:
        k.p("Rim" + sd, (1.45, 0.42, 0.5), CF(Vector((sx * 1.47, 2.16, -0.3))) * cf(ry=-sx * 90), "main2",
            shape="Wedge", studs=False)
        k.p("RimCorner" + sd, (0.9, 0.42, 0.5), CF(Vector((sx * 1.3, 2.16, 0.62))) * cf(ry=-sx * 135), "main2",
            shape="Wedge", studs=False)
        k.p("Pauldron" + sd, (0.62, 0.36, 1.0), CF(Vector((sx * 1.56, 1.62, -0.25))) * cf(rz=sx * 20), "dark")
        k.p("PauldronTrim" + sd, (0.66, 0.1, 1.04), CF(Vector((sx * 1.6, 1.82, -0.25))) * cf(rz=sx * 20), "pearl",
            studs=False)
        for j, (z, h) in enumerate(((-0.75, 0.32), (0.05, 0.42))):  # side spikes
            k.p("SideSpike%s%d" % (sd, j + 1), (0.26, h, 0.26),
                CF(Vector((sx * 1.62, 2.26 + h / 2, z))) * cf(rz=-sx * 30), "dark", shape="Wedge", studs=False)
    for i, (x, h) in enumerate(((-1.2, 0.34), (-0.72, 0.46), (-0.24, 0.4), (0.24, 0.52), (0.72, 0.42),
                                (1.2, 0.32))):  # spiky front rim: uneven spikes (rhythm, vault)
        k.p("Spike%d" % (i + 1), (0.26, h, 0.28), CF(Vector((x, 2.3 + h / 2, -1.08))) * cf(rx=-25), "dark",
            shape="Wedge", studs=False)
    k.p("Belly", (2.6, 0.3, 2.0), CF(Vector((0, 1.2, 0.12))), "light", studs=False)
    for i, z in enumerate((-0.45, 0.15, 0.75)):
        k.p("BellyPlate%d" % (i + 1), (1.6 - 0.25 * i, 0.08, 0.42), CF(Vector((0, 1.03, z))), "light", studs=False)
    # glass wave crest: five crystals rising off the back and leaning back like a breaking wave, a pearl before it
    for i, (x, h, lean) in enumerate(((-0.62, 0.7, 0.45), (-0.32, 1.05, 0.6), (0.0, 1.4, 0.72), (0.34, 1.0, 0.58),
                                      (0.62, 0.65, 0.42))):
        k.crystal("Crest%d" % (i + 1), (x, 2.5, 0.6), (x * 0.4, 1, lean), h, 0.3, n=2)
    k.p("CrestPearl", (0.34, 0.34, 0.34), CF(Vector((0, 2.72, 0.05))), "pearl", shape="Ball", material="Neon")
    k.p("CrestPearlCup", (0.5, 0.12, 0.5), CF(Vector((0, 2.56, 0.05))) * cf(ry=45), "coral", studs=False)
    for i, (x, z, s) in enumerate(((-0.92, 0.85, 0.34), (-0.7, 1.1, 0.24), (0.98, 0.6, 0.3), (0.8, 0.88, 0.2))):
        k.p("Barnacle%d" % (i + 1), (0.22, s, s), CF(Vector((x, 2.6, z))) * cf(rz=90), "pearl", shape="Cylinder",
            studs=False)
    starfish(k, "Star", (0.75, 2.58, -0.55), (0, 1, 0), 0.62, "star")

    # ---- head: face, mandibles, pearl eyes on ringed stalks, coral-and-scallop helmet with an anemone -----------
    J("Head")
    k.hinge("Head", (0, 1.95, -1.1))
    k.p("Face", (1.5, 0.62, 0.3), CF(Vector((0, 1.82, -1.32))), "dark", studs=False)
    k.p("Visor", (1.6, 0.14, 0.38), CF(Vector((0, 2.16, -1.36))), "coral", studs=False)
    for sx, sd in A.SIDES:
        k.p("Mandible" + sd, (0.24, 0.32, 0.3), CF(Vector((sx * 0.22, 1.5, -1.5))) * cf(ry=180), "light",
            shape="Wedge", studs=False)
        k.p("Palp" + sd, (0.14, 0.24, 0.14), CF(Vector((sx * 0.5, 1.56, -1.5))) * cf(rz=sx * 20), "coral",
            studs=False)
        base, top = Vector((sx * 0.42, 2.2, -1.2)), Vector((sx * 0.56, 2.95, -1.38))
        k.seg("Stalk" + sd, base, top, 0.18, 0.18, "main2")
        k.p("StalkRing" + sd, (0.26, 0.08, 0.26), CF(base + (top - base) * 0.55), "pearl", studs=False)
        e = top + Vector((0, 0.18, 0))
        k.p("EyeRim" + sd, (0.48, 0.16, 0.48), CF(e + Vector((0, -0.22, 0))), "dark", studs=False)
        k.p("Eye" + sd, (0.4, 0.44, 0.4), CF(e), "pearl", material="Neon")
        k.p("Pupil" + sd, (0.12, 0.3, 0.06), CF(e + Vector((0, -0.02, -0.21))), "ink", studs=False)
        k.p("Glint" + sd, (0.09, 0.09, 0.04), CF(e + Vector((sx * 0.09, 0.11, -0.24))), "glint", material="Neon")
    for i, a in enumerate((-44, -22, 0, 22, 44)):  # scallop shell helmet: five ribs fanning up the forehead
        c = CF(Vector((0, 2.42, -1.24))) * cf(rz=a) * CF((0, 0.32, 0))
        k.p("Scallop%d" % (i + 1), (0.24, 0.68 if i == 2 else 0.6, 0.16), c, "coral" if i % 2 else "pearl",
            studs=False)
    for i, (a, b, w) in enumerate((((0, 2.62, -1.0), (-0.22, 3.25, -0.95), 0.16),
                                   ((-0.1, 3.05, -0.97), (-0.42, 3.4, -1.0), 0.1),
                                   ((0.04, 2.7, -1.0), (0.3, 3.1, -0.85), 0.12),
                                   ((0.22, 2.98, -0.9), (0.42, 3.3, -0.98), 0.09),
                                   ((-0.2, 3.22, -0.96), (-0.12, 3.55, -0.9), 0.08))):
        k.seg("Coral%d" % (i + 1), a, b, w, w, "coral" if i % 2 == 0 else "coral2")
    for i, (x, z) in enumerate(((0.55, -0.85), (0.68, -0.72), (0.5, -0.68))):  # a sea anemone tuft beside it
        k.seg("Anemone%d" % (i + 1), (x, 2.58, z), (x + 0.05 * (i - 1), 2.95, z - 0.05), 0.1, 0.1, "glass")

    # ---- claws: fiddler asymmetry, ArmR huge (toothed, banded, a pearl), ArmL small ------------------------------
    for sx, sd, sc in ((-1, "L", 0.7), (1, "R", 1.25)):
        J("Arm" + sd)
        sh = Vector((sx * 1.3, 1.65, -0.85))
        k.hinge("Arm" + sd, sh)
        el = sh + Vector((sx * 0.42, 0.02, -0.4)) * sc
        wr = el + Vector((-sx * 0.1, 0.2, -0.42)) * sc
        k.seg("UpperArm" + sd, sh, el, 0.3 * sc, 0.3 * sc, "main")
        k.p("Elbow" + sd, (0.36 * sc, 0.36 * sc, 0.36 * sc), CF(el), "dark")
        k.seg("Forearm" + sd, el, wr, 0.34 * sc, 0.34 * sc, "main2")
        k.p("ArmBand" + sd, (0.4 * sc, 0.12 * sc, 0.4 * sc), look((el + wr) / 2, wr - el), "pearl", studs=False)
        palm = wr + Vector((0, 0.05, -0.32)) * sc
        k.p("Palm" + sd, (0.78 * sc, 0.7 * sc, 0.82 * sc), CF(palm) * cf(ry=sx * 10), "main")
        k.p("PalmBand" + sd, (0.82 * sc, 0.16 * sc, 0.2 * sc), CF(palm + Vector((0, 0, 0.3)) * sc) * cf(ry=sx * 10),
            "dark", studs=False)
        tipc = palm + Vector((0, 0.16, -0.62)) * sc
        k.p("Pincer" + sd, (0.44 * sc, 0.32 * sc, 0.62 * sc), CF(tipc) * cf(ry=sx * 10 + 180, rx=8), "coral",
            shape="Wedge", studs=False)
        k.p("Thumb" + sd, (0.36 * sc, 0.26 * sc, 0.5 * sc), CF(palm + Vector((0, -0.2, -0.55)) * sc)
            * cf(ry=sx * 10, rz=180, rx=-8), "coral", shape="Wedge", studs=False)
        k.p("ClawSpike" + sd, (0.16 * sc, 0.3 * sc, 0.16 * sc), CF(palm + Vector((sx * 0.2, 0.38, 0.1)) * sc)
            * cf(rz=-sx * 20), "dark", shape="Wedge", studs=False)
        if sd == "R":
            for t in range(3):  # teeth along the big pincer
                k.p("Tooth%d" % (t + 1), (0.1, 0.14, 0.1), CF(palm + Vector((0.04, -0.02, -0.4 - 0.18 * t)) * sc),
                    "pearl", studs=False)
            k.p("ClawCoral", (0.18, 0.5, 0.18), CF(palm + Vector((-0.2, 0.5, 0.15))) * cf(rz=15), "coral",
                studs=False)
            k.p("ClawPearl", (0.3, 0.3, 0.3), CF(palm + Vector((0.12, 0.48, 0.3))), "pearl", shape="Ball",
                material="Neon")  # a knight's pearl set in the big claw

    # ---- legs: three per side, jointed (thigh, shin, pointed tip), knee arched high, splayed low ---------------------
    for sx, sd in A.SIDES:
        J("Leg" + sd)
        k.hinge("Leg" + sd, (sx * 1.3, 1.5, 0.35))
        for i, z in enumerate((-0.25, 0.35, 0.95)):
            hip = Vector((sx * 1.3, 1.5, z))
            knee = hip + Vector((sx * 0.62, 0.62, 0.1 * (i - 1)))
            ankle = Vector((knee.x + sx * 0.72, 0.85, knee.z + 0.16 * (i - 1)))
            foot = Vector((ankle.x + sx * 0.22, 0.42, ankle.z + 0.06 * (i - 1)))
            k.seg("Thigh%s%d" % (sd, i + 1), hip, knee, 0.24, 0.24, "main")
            k.p("Knee%s%d" % (sd, i + 1), (0.28, 0.28, 0.28), CF(knee), "dark")
            k.seg("Shin%s%d" % (sd, i + 1), knee, ankle, 0.2, 0.2, "main2")
            k.p("LegTip%s%d" % (sd, i + 1), (0.18, 0.5, 0.18), look((ankle + foot) / 2, ankle - foot), "dark",
                shape="Wedge", studs=False)
    J("Root")
    for ob in coll.objects:  # sit low: the whole crab drops 0.4 (the legs above end at y = 0.42)
        ob.matrix_world.translation.z -= 0.4
    # rarer reads bigger: Epic scale 1.35 about the feet (as the Frost Serpent's 1.15)
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(1.35, 4) @ off.inverted() @ ob.matrix_world
    return coll
