# Piproot (Zone 1 Meadow, Common): a cheerful botanical frog, Roblox primitives only (Frost Serpent method, studs on
# top faces). A frog first: a broad flat head with raised square eyes, a wide smiling mouth with a pink tongue, a
# cream throat and belly, big folded hind legs with long cream toes, short front legs. The botany sits on top of
# that anatomy: layered leaf armour down the back, a two-leaf sprout on the head, two small white flowers.
# Joints: Body, Head, Jaw (the croak opens it), Throat (the croak sac pushes out), ArmL/R (front legs), LegL/R
# (hind legs, folded; the hop extends them).
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use

NAME, RARITY = "Piproot", "Common"
PAL = dict(main="7CCF2E", main2="6BBE24", dark="3E9A2A", light="B5E85A", glow="8CFF5A", cream="F2E6C4",
           cream2="E3D3A8", tongue="F07A8E", mouth="5A2430", flower="FFFFFF", flower2="F2F2EA", pollen="FFC93C", eye="F6F6F6",
           ink="141414")
CONCEPT = "Piproot: a cheerful botanical frog, leaf-armoured back, two-leaf sprout, raised square eyes, pink-tongued smile"
HEADER = '''--!strict
-- Piproot (Zone 1 Meadow, Common). Zone 1 Meadow roster (Config/Pets).
-- Pet: a cheerful botanical frog: broad flat head, raised square eyes, a wide smile with a pink tongue, cream throat
--      and belly, big folded hind legs with long cream toes, short front legs, layered leaf armour down the back, a
--      two-leaf sprout and two small white flowers. Joints: Body, Head, Jaw, Throat, ArmL/R, LegL/R.
-- Egg: cream shell under overlapping leaf plates, small white flowers and the two-leaf sprout on top.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/piproot.py, zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.2


def build(name="Z1_Piproot_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a squat frog torso, tilted up at the front, cream belly; leaf armour down the back --------------
    J("Body")
    k.hinge("Body", (0, 1.2, 0.2))
    k.p("Torso", (2.3, 1.25, 2.3), CF(Vector((0, 1.3, 0.35))) * cf(rx=-12), "main")
    k.p("Belly", (1.9, 0.9, 1.9), CF(Vector((0, 0.78, 0.25))) * cf(rx=-12), "cream", studs=False)
    k.p("Rump", (2.0, 0.9, 0.7), CF(Vector((0, 1.05, 1.45))) * cf(rx=-25), "main2")
    k.p("Chest", (1.9, 1.05, 0.55), CF(Vector((0, 1.15, -0.85))) * cf(rx=-12), "cream")
    k.p("ChestLow", (1.5, 0.45, 0.5), CF(Vector((0, 0.6, -0.7))), "cream2", studs=False)
    # leaf armour: four overlapping rows of big leaves lying on the back like shingles, sweeping back and out
    rows = [(-0.45, 2.12, (-0.55, 0.55), 1.25, 0.8), (0.1, 2.05, (-0.95, 0, 0.95), 1.3, 0.78),
            (0.7, 1.9, (-0.6, 0.6), 1.25, 0.76), (1.2, 1.62, (-0.95, 0, 0.95), 1.05, 0.7)]
    n = 0
    for ri, (z, y, xs, ln, w) in enumerate(rows):
        for j, x in enumerate(xs):
            n += 1
            d = Vector((x * 0.42, -0.2, 1)).normalized()
            nrm = Vector((x * 0.55, 1, 0.12)).normalized()
            col = ("dark", "main", "light", "dark")[(ri + j) % 4]
            A.leaf(k, "Leaf%d" % n, (x, y - abs(x) * 0.22, z), d, ln, w, col, thick=0.16, normal=nrm,
                   vein="dark" if col != "dark" else "main2")
    from zone1.crownstag import flower
    for i, (p, n, sz) in enumerate((((-0.62, 2.05, 0.15), (-0.35, 1, 0.1), 0.68), ((0.78, 1.72, 0.95), (0.4, 1, 0.3),
                                                                                  0.6),
                                    ((0.15, 1.95, -0.35), (0.1, 1, -0.2), 0.55))):
        flower(k, "Flower%d" % (i + 1), p, n, sz, petal="flower", petal2="flower2", centre="pollen")

    # ---- throat sac: tucked under the chin, the croak pushes it out ----------------------------------------------
    J("Throat")
    k.hinge("Throat", (0, 1.35, -1.0))
    k.p("ThroatSac", (1.25, 0.95, 0.9), CF(Vector((0, 1.32, -1.12))), "cream", studs=False)

    # ---- head: broad and flat, raised eyes, a wide mouth ----------------------------------------------------------
    J("Head")
    k.hinge("Head", (0, 1.95, -0.7))
    k.p("Skull", (2.5, 0.75, 1.8), CF(Vector((0, 2.25, -1.25))), "main")
    k.p("Brow", (2.3, 0.3, 0.35), CF(Vector((0, 2.45, -2.05))), "main2", studs=False)
    k.p("UpperLip", (2.35, 0.32, 0.4), CF(Vector((0, 1.98, -2.1))), "light", studs=False)
    k.p("Nostrils", (0.7, 0.08, 0.06), CF(Vector((0, 2.18, -2.33))), "dark", studs=False)
    k.p("MouthBack", (2.0, 0.42, 1.2), CF(Vector((0, 1.72, -1.45))), "mouth", studs=False)
    for sx, sd in A.SIDES:
        k.p("Cheek" + sd, (0.42, 0.75, 1.2), CF(Vector((sx * 1.12, 1.95, -1.3))), "main2", studs=False)
        # the frog smile: the lip line wraps round to the cheeks and curls up at the corners
        k.p("SmileSide" + sd, (0.08, 0.1, 1.1), CF(Vector((sx * 1.34, 1.84, -1.45))), "mouth", studs=False)
        k.p("SmileCurl" + sd, (0.08, 0.1, 0.3), CF(Vector((sx * 1.34, 1.92, -0.88))) * cf(rx=-35), "mouth",
            studs=False)
        # raised eyes: a green turret, a white square, a big black pupil and a glint
        k.p("EyeTurret" + sd, (0.95, 0.75, 0.9), CF(Vector((sx * 0.78, 2.85, -1.45))), "main")
        k.p("EyeRim" + sd, (1.0, 0.16, 0.95), CF(Vector((sx * 0.78, 3.2, -1.45))), "light", studs=False)
        k.p("Eye" + sd, (0.74, 0.62, 0.06), CF(Vector((sx * 0.78, 2.86, -1.92))), "eye", studs=False)
        k.p("Pupil" + sd, (0.52, 0.5, 0.06), CF(Vector((sx * 0.74, 2.83, -1.96))), "ink", studs=False)
        k.p("Glint" + sd, (0.17, 0.17, 0.05), CF(Vector((sx * 0.62, 2.97, -2.0))), "eye", material="Neon",
            studs=False)
    # the sprout: a stem, a little bud and two leaves
    top = Vector((0, 2.62, -1.15))
    k.seg("SproutStem", top, top + Vector((0, 0.8, 0.12)), 0.22, 0.22, "dark")
    k.seg("SproutStem2", top + Vector((0, 0.78, 0.12)), top + Vector((0.08, 1.45, 0.05)), 0.18, 0.18, "main")
    bud = top + Vector((0.08, 1.45, 0.05))
    k.p("SproutBud", (0.28, 0.28, 0.28), CF(bud) * cf(rx=45, ry=45), "light", studs=False)
    for sx, sd in A.SIDES:
        A.leaf(k, "Sprout" + sd, bud - Vector((0, 0.05, 0)), (sx * 0.9, 0.45, 0.05), 1.45, 0.85, "light", thick=0.12,
               normal=(0, 0, -1), vein="main")

    # ---- jaw: cream lower jaw and the pink tongue (the croak drops it) ---------------------------------------------
    J("Jaw")
    k.hinge("Jaw", (0, 1.6, -0.75))
    jh = Vector((0, 1.6, -0.75))
    R = CF(jh) * cf(rx=-20) * CF(-jh)  # modelled with the mouth open in a smile, as in the reference
    k.p("LowerJaw", (2.3, 0.42, 1.6), R * CF(Vector((0, 1.38, -1.4))), "cream", studs=False)
    k.p("Chin", (1.9, 0.25, 0.3), R * CF(Vector((0, 1.48, -2.15))), "cream2", studs=False)
    k.p("Tongue", (1.1, 0.18, 1.05), R * CF(Vector((0, 1.63, -1.72))) * cf(rx=8), "tongue", studs=False)

    # ---- front legs: short, a lime band, three cream toes -----------------------------------------------------------
    for sx, sd in A.SIDES:
        J("Arm" + sd)
        sh = Vector((sx * 0.85, 1.15, -0.95))
        k.hinge("Arm" + sd, sh)
        hand = Vector((sx * 1.0, 0.32, -1.35))
        k.seg("Arm" + sd, sh, hand, 0.55, 0.55, "main")
        k.p("ArmBand" + sd, (0.62, 0.18, 0.62), CF(sh.lerp(hand, 0.6)), "light", studs=False)
        k.p("Hand" + sd, (0.7, 0.3, 0.55), CF(Vector((sx * 1.02, 0.17, -1.5))), "main2", studs=False)
        for t, dx in enumerate((-0.24, 0, 0.24)):
            k.p("Toe%s%d" % (sd, t + 1), (0.2, 0.26, 0.38), CF(Vector((sx * 1.02 + dx, 0.13, -1.86))), "cream",
                studs=False)

    # ---- hind legs: a big rounded thigh, the shin folded under it, a long foot with cream toes ----------------------
    for sx, sd in A.SIDES:
        J("Leg" + sd)
        hip = Vector((sx * 1.05, 1.0, 0.85))
        k.hinge("Leg" + sd, hip)
        k.p("Thigh" + sd, (1.1, 1.25, 1.65), CF(Vector((sx * 1.42, 0.95, 0.7))) * cf(rx=-10), "main")
        k.p("ThighTop" + sd, (1.0, 0.25, 1.4), CF(Vector((sx * 1.42, 1.62, 0.6))) * cf(rx=-10), "light", studs=False)
        k.p("Knee" + sd, (0.95, 0.9, 0.6), CF(Vector((sx * 1.45, 0.75, -0.15))), "main2", studs=False)
        k.p("Shin" + sd, (0.8, 0.45, 1.8), CF(Vector((sx * 1.55, 0.25, 0.55))), "dark")
        k.p("Foot" + sd, (0.95, 0.3, 0.9), CF(Vector((sx * 1.62, 0.15, -0.55))), "main2", studs=False)
        for t, dx in enumerate((-0.3, 0, 0.3)):
            k.p("HindToe%s%d" % (sd, t + 1), (0.24, 0.28, 0.55), CF(Vector((sx * 1.62 + dx, 0.14, -1.18))), "cream",
                studs=False)

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))  # scale about the feet
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
