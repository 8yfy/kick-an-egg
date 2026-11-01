# The Burrow Monarch (Zone 1 Meadow, Mythic): a massive subterranean beast, Roblox primitives only (Frost Serpent
# method). An original mole-badger with the long ears of the reference: low and broad, a huge shoulder hump, colossal
# forelimbs with gold-banded forearms and enormous cream digging claws, short heavy hind legs. A broad head with a
# burrowing snout, whiskers, heavy brows over glowing amber eyes and long ears lit amber inside; a crown of twisting
# roots with sprouting leaves around a gold band and an amber gem. Green earthen armour plates with gold rims and leaf
# emblems over the back, moss, a cream fur ruff, glowing amber veins and amber mineral gems.
# Joints: Body, Head, EarL/R, ArmL/R (the digging forelimbs), LegL/R, Tail, Rocks (floating chunks).
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use
from v3 import top_parts as T

NAME, RARITY = "The Burrow Monarch", "Mythic"
PAL = dict(main="6E4126", main2="5C3620", dark="3A2214", light="F2E4C8", glow="FFAE2E", fur="F2E4C8",
           fur2="E2CFAA", claw="F4ECD8", claw2="D9CBAA", armour="3F7E35", armour2="2D5E27", moss="7FB548",
           gold="E3A933", gold2="B8862A", amber="FF9A1F", stone="8C8578", root="5A3A22", leaf="7FC24A",
           nose="3A1E18", ear="F0A868", eye="FFB02E", ink="140A06")
CONCEPT = "The Burrow Monarch: a massive mole-badger with long ears, root-and-gold crown, colossal claws, leaf armour"
HEADER = '''--!strict
-- The Burrow Monarch (Zone 1 Meadow, Mythic). Preview candidate (KickAnEgg_PremiumPets/Zone01_Meadow), not wired.
-- Pet: a massive mole-badger: a huge shoulder hump, colossal forelimbs with enormous cream digging claws, a broad head
--      with a burrowing snout, whiskers and glowing amber eyes, long ears lit amber inside, a crown of roots around a
--      gold band and an amber gem, green earthen armour plates with gold rims and leaf emblems, moss, a cream ruff and
--      glowing amber veins, floating rocks. Joints: Body, Head, EarL/R, ArmL/R, LegL/R, Tail, Rocks.
-- Egg: an imposing earthen egg of stone plates with roots, moss, glowing amber cracks and a root-and-gold crown.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/burrow_monarch.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.15


def emblem(k, name, centre, normal, size, up=(0, 1, 0)):
    """A leaf emblem: a gold diamond with a green leaf and a gold vein laid on it."""
    f = T.plane_frame(centre, normal, up)
    k.p(name + "Frame", (size, size, 0.12), f * cf(rz=45), "gold", studs=False)
    k.p(name + "Field", (size * 0.78, size * 0.78, 0.14), f * CF((0, 0, 0.01)) * cf(rz=45), "armour2", studs=False)
    k.p(name + "Leaf", (size * 0.32, size * 0.8, 0.16), f * CF((0, 0, 0.02)), "leaf", studs=False)
    k.p(name + "Vein", (size * 0.06, size * 0.7, 0.18), f * CF((0, 0, 0.03)), "gold", studs=False)


def armour(k, name, centre, normal, w, h, up=(0, 1, 0)):
    """An earthen armour plate: a green slab, a darker inset, gold rim bars, a leaf emblem."""
    f = T.plane_frame(centre, normal, up)
    k.p(name, (w, h, 0.3), f, "armour")
    k.p(name + "Inset", (w * 0.8, h * 0.78, 0.32), f * CF((0, 0, 0.02)), "armour2", studs=False)
    for sy in (-1, 1):
        k.p("%sRimH%d" % (name, sy + 1), (w + 0.1, 0.14, 0.34), f * CF((0, sy * h / 2, 0.02)), "gold", studs=False)
    for sx in (-1, 1):
        k.p("%sRimV%d" % (name, sx + 1), (0.14, h, 0.34), f * CF((sx * w / 2, 0, 0.02)), "gold", studs=False)
    emblem(k, name + "Emblem", f.point((0, 0, 0.18)), normal, min(w, h) * 0.5, up=up)


def build(name="Z1_BurrowMonarch_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a huge shoulder hump, a low torso and haunches; armour, moss, a cream ruff ----------------------------
    J("Body")
    k.hinge("Body", (0, 2.4, 0.4))
    k.p("Shoulders", (3.7, 2.5, 2.0), CF(Vector((0, 3.0, -1.0))) * cf(rx=-8), "main")
    k.p("Hump", (2.9, 0.7, 1.7), CF(Vector((0, 4.35, -0.85))) * cf(rx=-8), "main2")
    k.p("Torso", (3.1, 2.0, 2.4), CF(Vector((0, 2.5, 0.95))), "main2")
    k.p("Haunches", (3.0, 1.9, 1.5), CF(Vector((0, 2.3, 2.45))), "main")
    k.p("Belly", (2.4, 0.45, 3.6), CF(Vector((0, 1.38, 0.6))), "fur2", studs=False)
    # the armour: a saddle plate over the back and a plate on each flank (they shift with the dig)
    armour(k, "Saddle", (0, 3.75, 0.85), (0, 1, 0.12), 2.5, 2.1, up=(0, 0, -1))
    for sx, sd in A.SIDES:
        armour(k, "Flank" + sd, (sx * 1.62, 2.75, 1.05), (sx, 0.3, 0), 1.9, 1.5)
    for i, (x, z) in enumerate(((-1.1, -0.2), (1.15, -0.35), (-0.9, 2.1), (1.0, 2.2), (0.0, 2.6))):  # moss tufts
        k.p("Moss%d" % (i + 1), (0.7, 0.32, 0.6), CF(Vector((x, 3.5 - 0.25 * (z > 2), z))) * cf(ry=25 * i),
            "moss", studs=False)
    # the ruff: layered cream fur tufts round the neck and chest
    for i, (x, y, z, ang) in enumerate(((0, 3.5, -2.05, 0), (-0.85, 3.15, -1.9, -30), (0.85, 3.15, -1.9, 30),
                                        (-1.45, 2.6, -1.6, -50), (1.45, 2.6, -1.6, 50), (-0.5, 2.5, -2.1, -15),
                                        (0.5, 2.5, -2.1, 15), (0, 2.1, -2.0, 0))):
        d = Vector((math.sin(math.radians(ang)) * 0.5, -0.55, -1)).normalized()
        k.p("Ruff%d" % (i + 1), (0.75, 0.75, 0.55), look(Vector((x, y, z)), d, (0, 0, -1)) * cf(ry=45),
            "fur" if i % 2 == 0 else "fur2", studs=False)
    # shingled fur over the shoulder hump and the neck, darker towards the back
    for row, (z, y, xs) in enumerate(((-1.75, 4.25, (-0.95, -0.32, 0.32, 0.95)), (-1.2, 4.6, (-1.1, -0.37, 0.37, 1.1)),
                                       (-0.6, 4.55, (-0.85, 0.0, 0.85)))):
        for j, x in enumerate(xs):
            d = Vector((x * 0.25, -0.35, 1)).normalized()
            k.p("Fur%d_%d" % (row + 1, j + 1), (0.72, 0.18, 0.95), look(Vector((x, y, z)), Vector((x * 0.3, 1, -0.25)),
                                                                     d) * cf(ry=45), "main2" if (row + j) % 2 else
                "dark", studs=False)
    # gold-rimmed pauldrons over the shoulders
    for sx, sd in A.SIDES:
        f = T.plane_frame((sx * 1.95, 3.75, -1.15), (sx, 0.6, -0.15))
        k.p("Pauldron" + sd, (1.7, 1.4, 0.35), f, "armour")
        k.p("PauldronRim" + sd, (1.85, 0.16, 0.4), f * CF((0, 0.7, 0.02)), "gold", studs=False)
        k.p("PauldronRim2" + sd, (1.85, 0.16, 0.4), f * CF((0, -0.7, 0.02)), "gold", studs=False)
        k.p("PauldronGem" + sd, (0.42, 0.42, 0.42), f * CF((0, 0, 0.2)) * cf(rz=45), "amber", material="Neon",
            studs=False)
        # a cream side ruff below the pauldron
        k.p("SideRuff" + sd, (0.5, 1.0, 1.3), CF(Vector((sx * 1.9, 2.3, -1.85))) * cf(rz=sx * 15), "fur",
            studs=False)
    # stone mineral chunks breaking through the back between the plates
    for i, (x, y, z, sz) in enumerate(((-0.8, 4.0, 2.2, 0.55), (0.9, 3.95, 2.0, 0.48), (0.2, 4.15, 2.45, 0.42),
                                       (-1.25, 3.55, 0.0, 0.44))):
        k.p("Stone%d" % (i + 1), (sz, sz * 1.2, sz), CF(Vector((x, y, z))) * cf(rx=20 * i, ry=35, rz=15), "stone")
    # a big gold-framed amber diamond on the chest, glowing veins along the shoulders
    k.p("ChestGemSet", (0.95, 0.95, 0.16), CF(Vector((0, 2.85, -2.33))) * cf(rz=45), "gold", studs=False)
    k.p("ChestGemRim", (0.8, 0.8, 0.18), CF(Vector((0, 2.85, -2.35))) * cf(rz=45), "gold2", studs=False)
    k.p("ChestGem", (0.62, 0.62, 0.2), CF(Vector((0, 2.85, -2.38))) * cf(rz=45), "amber", material="Neon",
        studs=False)
    k.p("ChestGemCore", (0.26, 0.26, 0.22), CF(Vector((0, 2.85, -2.41))) * cf(rz=45), "glow", material="Neon",
        studs=False)
    for sx in (-1, 1):  # cream fur tufts round the rump
        for j, (y, z) in enumerate(((3.1, 3.2), (2.4, 3.3), (3.6, 2.95))):
            k.p("RumpFur%d_%d" % (sx + 2, j + 1), (0.75, 0.7, 0.6), CF(Vector((sx * 0.85, y, z))) *
                cf(rx=-20, rz=sx * 15), "fur2" if j % 2 else "fur", studs=False)
    armour(k, "RumpPlate", (0, 3.45, 2.75), (0, 0.65, 0.75), 1.9, 1.2, up=(0, 0.6, -0.8))
    for sx, sd in A.SIDES:
        k.seg("Vein%s1" % sd, (sx * 1.86, 3.9, -1.6), (sx * 1.88, 2.6, -0.6), 0.1, 0.1, "amber", material="Neon",
              studs=False)
        k.seg("Vein%s2" % sd, (sx * 1.88, 2.6, -0.6), (sx * 1.85, 1.9, -1.2), 0.1, 0.1, "amber", material="Neon",
              studs=False)

    # ---- tail: a cream tuft ------------------------------------------------------------------------------------------
    J("Tail")
    k.hinge("Tail", (0, 2.8, 3.15))
    k.p("Tail", (1.3, 1.15, 0.9), CF(Vector((0, 2.95, 3.4))) * cf(rx=20), "fur")
    k.p("TailMid", (1.0, 0.9, 0.7), CF(Vector((0, 3.35, 3.8))) * cf(rx=35), "fur2")
    k.p("TailTip", (0.7, 0.6, 0.5), CF(Vector((0, 3.7, 4.05))) * cf(rx=50), "fur", studs=False)
    for sx in (-1, 1):
        k.p("TailTuft%d" % (sx + 2), (0.55, 0.6, 0.55), CF(Vector((sx * 0.55, 3.0, 3.65))) * cf(rz=sx * 30), "fur2",
            studs=False)

    # ---- floating rocks: chunks of earth hovering round the Monarch, each with a glowing amber chip --------------
    J("Rocks")
    k.hinge("Rocks", (0, 3.0, 0.4))
    for i, (x, y, z, sz) in enumerate(((-3.0, 4.4, -1.2, 0.55), (3.1, 4.8, 0.2, 0.45), (-2.7, 3.2, 1.9, 0.4),
                                       (2.6, 3.4, 2.4, 0.5), (0.4, 5.6, 1.6, 0.36), (-1.4, 5.2, -2.6, 0.42))):
        k.p("Rock%d" % (i + 1), (sz, sz * 0.85, sz), CF(Vector((x, y, z))) * cf(rx=25 * i, ry=40 + 15 * i, rz=20),
            "stone")
        k.p("RockChip%d" % (i + 1), (sz * 0.4, sz * 0.4, sz * 0.4), CF(Vector((x, y + sz * 0.42, z))) * cf(ry=45),
            "amber", material="Neon", studs=False)

    # ---- head: a broad skull, a burrowing snout, whiskers, glowing eyes under heavy brows, the crown ----------------
    J("Head")
    k.hinge("Head", (0, 3.1, -1.9))
    H = A.Frame(k, CF(Vector((0, 3.15, -2.85))) * cf(rx=8), s=1.0)
    H.p("Skull", (2.0, 1.5, 1.5), (0, 0.1, 0), "main")
    H.p("Brow", (1.9, 0.38, 0.5), (0, 0.55, -0.62), "main2", studs=False)
    H.p("Muzzle", (1.3, 0.9, 1.0), (0, -0.3, -0.95), "fur2")
    H.p("Snout", (0.8, 0.6, 0.6), (0, -0.25, -1.6), "fur")
    H.p("Nose", (0.6, 0.38, 0.26), (0, -0.12, -1.95), "nose", studs=False)
    H.p("Mouth", (0.7, 0.08, 0.06), (0, -0.62, -1.5), "ink", studs=False)
    for sx, sd in A.SIDES:
        H.p("Tooth" + sd, (0.2, 0.32, 0.1), (sx * 0.12, -0.78, -1.45), "claw", studs=False)
        H.p("Cheek" + sd, (0.5, 0.95, 1.0), (sx * 0.95, -0.25, -0.45), "fur", rz=sx * 12)
        H.p("Socket" + sd, (0.52, 0.3, 0.08), (sx * 0.52, 0.25, -0.78), "ink", rz=-sx * 16, studs=False)
        H.p("Eye" + sd, (0.4, 0.18, 0.06), (sx * 0.52, 0.25, -0.83), "eye", rz=-sx * 16, material="Neon",
            studs=False)
        H.p("Pupil" + sd, (0.12, 0.17, 0.05), (sx * 0.46, 0.25, -0.87), "ink", rz=-sx * 16, studs=False)
        H.p("Glint" + sd, (0.07, 0.07, 0.04), (sx * 0.6, 0.3, -0.89), "light", material="Neon", studs=False)
        H.p("BrowRidge" + sd, (0.7, 0.18, 0.3), (sx * 0.52, 0.48, -0.75), "dark", rz=sx * 18, studs=False)
        for w in range(3):  # whiskers
            a = H.pt((sx * 0.45, -0.28 - 0.1 * w, -1.55))
            b = H.pt((sx * 1.45, -0.18 - 0.22 * w, -1.65 + 0.15 * w))
            k.seg("Whisker%s%d" % (sd, w + 1), a, b, 0.05, 0.05, "claw", studs=False)
    # the crown: a gold band with an amber gem, twisting roots rising round the head with leaf sprouts
    H.p("CrownBand", (1.7, 0.24, 1.4), (0, 0.85, 0.05), "gold", studs=False)
    H.p("CrownGemSet", (0.62, 0.62, 0.16), (0, 1.05, -0.68), "gold", rz=45, studs=False)
    H.p("CrownGem", (0.44, 0.44, 0.18), (0, 1.05, -0.72), "amber", rz=45, material="Neon", studs=False)
    for i, (x, z, lean) in enumerate(((-0.7, -0.4, -0.5), (0.7, -0.4, 0.5), (-0.55, 0.45, -0.7), (0.55, 0.45, 0.7),
                                      (-0.25, -0.55, -0.15), (0.25, -0.55, 0.15))):
        base = H.pt((x, 0.9, z))
        pts = A.branch(k, "CrownRoot%d" % (i + 1), base, [(H.vec((lean, 1, 0.1)), 0.55),
                                                          (H.vec((lean * 1.6, 0.8, 0.25)), 0.45)], "root", w0=0.2,
                       taper=0.75)
        k.p("Sprout%d" % (i + 1), (0.34, 0.12, 0.26), look(pts[-1], H.vec((lean, 1, 0))) * cf(rz=30), "leaf",
            studs=False)

    # ---- ears: long, rising up and back, lit amber inside ------------------------------------------------------------
    for sx, sd in A.SIDES:
        J("Ear" + sd)
        base = H.pt((sx * 0.62, 0.95, 0.35))
        k.hinge("Ear" + sd, base)
        d = H.vec((sx * 0.35, 1, 0.45)).normalized()
        nrm = H.vec((sx * 0.4, 0, -1))
        k.p("Ear" + sd, (0.62, 2.2, 0.28), look(base + d * 1.1, d, nrm), "main", studs=False)
        k.p("EarTip" + sd, (0.44, 0.44, 0.26), look(base + d * 2.2, d, nrm) * cf(rz=45), "main", studs=False)
        k.p("EarInner" + sd, (0.36, 1.8, 0.1), look(base + d * 1.1 + nrm.normalized() * 0.12, d, nrm), "ear",
            studs=False)
        k.p("EarGlow" + sd, (0.1, 1.5, 0.08), look(base + d * 1.1 + nrm.normalized() * 0.18, d, nrm), "glow",
            material="Neon", studs=False)

    # ---- forelimbs: colossal, gold-banded forearms, enormous cream claws --------------------------------------------
    for sx, sd in A.SIDES:
        J("Arm" + sd)
        sh = Vector((sx * 1.7, 2.9, -1.3))
        k.hinge("Arm" + sd, sh)
        elbow = Vector((sx * 2.05, 1.6, -1.6))
        k.p("Shoulder" + sd, (1.4, 1.6, 1.6), CF(sh), "main2")
        k.seg("UpperArm" + sd, sh, elbow, 1.3, 1.3, "main")
        k.seg("Forearm" + sd, elbow, Vector((sx * 2.1, 0.5, -2.05)), 1.25, 1.25, "main2")
        k.p("Bracer" + sd, (1.42, 0.4, 1.42), CF(Vector((sx * 2.08, 1.15, -1.8))) * cf(rx=-20), "gold")
        k.p("BracerBand" + sd, (1.46, 0.16, 1.46), CF(Vector((sx * 2.08, 0.9, -1.88))) * cf(rx=-20), "armour",
            studs=False)
        k.p("Paw" + sd, (1.6, 0.75, 1.6), CF(Vector((sx * 2.1, 0.38, -2.2))), "main")
        for r in range(2):  # roots wrapped round the forearm, with a leaf sprout
            k.p("ArmRoot%s%d" % (sd, r + 1), (1.38, 0.16, 1.38),
                CF(Vector((sx * 2.07, 1.55 + 0.32 * r, -1.68))) * cf(rx=-20, ry=18 * (r * 2 - 1)), "root",
                studs=False)
        k.p("ArmSprout" + sd, (0.4, 0.12, 0.3), CF(Vector((sx * 2.7, 1.95, -1.6))) * cf(rz=-sx * 35), "leaf",
            studs=False)
        k.p("MossBand" + sd, (1.5, 0.32, 1.5), CF(Vector((sx * 2.09, 0.75, -1.95))) * cf(rx=-20), "moss")
        k.p("MossBandTop" + sd, (1.1, 0.16, 1.1), CF(Vector((sx * 2.09, 0.94, -1.92))) * cf(rx=-20), "leaf",
            studs=False)
        for j, (a, b) in enumerate((((sx * 2.74, 1.45, -1.5), (sx * 2.76, 1.0, -1.85)),
                                    ((sx * 2.76, 1.0, -1.85), (sx * 2.72, 0.55, -1.95)),
                                    ((sx * 2.0, 1.4, -2.38), (sx * 2.25, 1.0, -2.5)),
                                    ((sx * 2.25, 1.0, -2.5), (sx * 2.05, 0.6, -2.62)))):
            k.seg("ArmCrack%s%d" % (sd, j + 1), a, b, 0.09, 0.08, "amber", material="Neon", studs=False)
        for c in range(4):  # four great digging claws, two segments each, curving down at the tips
            x = sx * 2.1 + (c - 1.5) * 0.36
            b0 = Vector((x, 0.45, -2.85))
            b1 = b0 + Vector((0, -0.05, -0.85))
            b2 = b1 + Vector((0, -0.35, -0.45))
            k.seg("Claw%s%d" % (sd, c + 1), b0, b1, 0.3, 0.32, "claw")
            k.p("Knuckle%s%d" % (sd, c + 1), (0.36, 0.22, 0.3), CF(b0 + Vector((0, 0.18, 0.15))), "gold",
                studs=False)
            k.seg("ClawTip%s%d" % (sd, c + 1), b1 - Vector((0, 0, 0.05)), b2, 0.2, 0.22, "claw2")

    # ---- hind legs: short and heavy, three claws ---------------------------------------------------------------------
    for sx, sd in A.SIDES:
        J("Leg" + sd)
        hip = Vector((sx * 1.35, 2.1, 2.4))
        k.hinge("Leg" + sd, hip)
        k.p("Thigh" + sd, (1.2, 1.5, 1.6), CF(hip + Vector((sx * 0.15, -0.25, 0))), "main")
        k.p("Shin" + sd, (0.95, 1.0, 1.0), CF(Vector((sx * 1.5, 0.75, 2.2))), "main2")
        k.p("Foot" + sd, (1.1, 0.4, 1.4), CF(Vector((sx * 1.5, 0.2, 1.95))), "main")
        for c in range(3):
            x = sx * 1.5 + (c - 1) * 0.34
            k.seg("HindClaw%s%d" % (sd, c + 1), (x, 0.22, 1.3), (x, 0.08, 0.9), 0.22, 0.22, "claw", studs=False)

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
