# The Walking Orchard (Zone 1 Meadow, Divine): a sacred orchard stag built to the user's reference (images/12.webp),
# Roblox primitives only (Frost Serpent method). A long, deep-chested stag of studded bark blocks with a patchwork of
# bark plates: thick tree-trunk legs with gold knee guards, gold ankle bands, chunky gold hooves and root toes; a dense
# leafy mantle with white blossoms and berries over the back and down the flanks; a cream bib and collar above a
# cream-framed gold sacred crest with a glowing tree on the deep chest; a thick neck; a brown deer head with a cream
# muzzle and blaze and glowing gold eyes; two huge gnarled antlers branching out to the sides, each carrying a broad
# stepped leaf canopy hung all round with faceted red gem fruit on gold stems, smaller leaf clusters on the inner
# tines, hanging vines and gold crystals along the branches; a long gnarled root-branch tail with gold crystal tips.
# Joints: Body, Neck, Head, AntlerL/R (the canopies sway), ArmL/R, LegL/R, Tail.
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use
from v3 import top_parts as T

NAME, RARITY = "The Walking Orchard", "Divine"
PAL = dict(main="7A4A2A", main2="6B3F22", dark="4A2C17", light="A66E3E", glow="FFD45A", bark="7A4A2A",
           bark2="6B3F22", bark3="55331C", bark4="8E5A33", cream="F2DFBC", cream2="E3CBA0", leaf="3E9B35",
           leaf2="6CC23A", leaf3="9BE04F", leaf4="2C7A2C", flower="FFFFFF", pollen="FFD34E", berry="E8344A",
           fruit="D8203A", fruit2="FF5468", fruitglow="FF3355", gold="F2B632", gold2="C98F1E", goldglow="FFE27A",
           crystal="FFE066", eye="FFD45A", nose="2A1A10", ink="1A0E06")
CONCEPT = "The Walking Orchard: a sacred bark stag whose antlers grow into fruit-laden canopies, gold crest and hooves"
HEADER = '''--!strict
-- The Walking Orchard (Zone 1 Meadow, Divine). Preview candidate (KickAnEgg_PremiumPets/Zone01_Meadow), not wired.
-- Pet: a sacred orchard stag of studded bark blocks: thick tree-trunk legs with gold knee guards, gold hooves and root
--      toes, a dense leafy mantle with white blossoms and berries, a cream bib over a gold crest with a glowing tree,
--      a deer head with a cream muzzle and glowing gold eyes, huge gnarled antlers carrying broad stepped leaf
--      canopies hung with faceted red gem fruit, hanging vines and gold crystals, a long root-branch tail.
--      Joints: Body, Neck, Head, AntlerL/R, ArmL/R, LegL/R, Tail.
-- Egg: a cream egg wrapped in branches with leaves, blossoms and red gem fruit, a gold crest with a glowing tree and a
--      crown of branches with a gem fruit on top.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/walking_orchard.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 0.85


def gem_fruit(k, name, at, size, stem=0.35):
    """A faceted red gem fruit on a gold stem: a diamond-turned body whose glowing core breaks through every face as a
    lit facet, lighter top facets and a leaf."""
    at = Vector(at)
    k.p(name, (size, size * 0.9, size), CF(at) * cf(ry=45), "fruit", studs=False)
    k.p(name + "Glow", (size * 0.8, size * 0.62, size * 0.8), CF(at), "fruitglow", material="Neon", studs=False)
    k.p(name + "Facet", (size * 0.7, size * 0.28, size * 0.7), CF(at + Vector((0, size * 0.48, 0))), "fruit2",
        studs=False)
    k.p(name + "Point", (size * 0.55, size * 0.24, size * 0.55), CF(at - Vector((0, size * 0.5, 0))) * cf(ry=45),
        "fruit", studs=False)
    top = at + Vector((0, size * 0.6, 0))
    if stem > 0:
        k.seg(name + "Stem", top - Vector((0, 0.05, 0)), top + Vector((0, stem, 0)), 0.08, 0.08, "gold", studs=False)
    k.p(name + "Leaf", (0.36, 0.08, 0.2), CF(top + Vector((0.16, 0.12, 0))) * cf(rz=-25), "leaf2", studs=False)


def gnarl(k, name, base, steps, w0, taper=0.84, cols=("bark", "bark2")):
    """A gnarled branch: segments through `steps` (direction, length) with a knot block at every bend."""
    pts = [Vector(base)]
    w = w0
    for i, (d, ln) in enumerate(steps):
        a = pts[-1]
        b = a + Vector(d).normalized() * ln
        dd = (b - a).normalized()
        k.seg("%s%d" % (name, i + 1), a - dd * 0.05, b + dd * 0.05, w, w * 0.92, cols[i % len(cols)])
        if i < len(steps) - 1:
            k.p("%sKnot%d" % (name, i + 1), (w * 1.18, w * 1.18, w * 1.18), CF(b) * cf(ry=30 * i + 15), "bark3",
                studs=False)
        pts.append(b)
        w *= taper
    return pts


def deck_canopy(k, name, centre, size, ry=0):
    """A broad stepped leaf canopy (a bonsai crown): a wide deck, two narrower tiers, a crown block and darker drop
    blocks round the rim. Returns the rim radius (x, z) and the deck's underside height."""
    c = Vector(centre)
    w, h, d = size
    k.p(name, (w, h, d), CF(c) * cf(ry=ry), "leaf")
    k.p(name + "Tier2", (w * 0.8, h * 0.8, d * 0.8), CF(c + Vector((0.05, h * 0.85, -0.05))) * cf(ry=ry + 8), "leaf2")
    k.p(name + "Tier3", (w * 0.55, h * 0.7, d * 0.55), CF(c + Vector((-0.1, h * 1.55, 0.08))) * cf(ry=ry - 6), "leaf3")
    k.p(name + "Crown", (w * 0.28, h * 0.6, d * 0.28), CF(c + Vector((0.05, h * 2.1, 0))) * cf(ry=ry + 20), "leaf2")
    for i in range(6):
        a = 2 * math.pi * (i + 0.5) / 6 + math.radians(ry)
        p = c + Vector((math.sin(a) * w * 0.4, -h * 0.45, -math.cos(a) * d * 0.4))
        k.p("%sDrop%d" % (name, i + 1), (w * 0.3, h * 0.7, d * 0.3), CF(p) * cf(ry=ry + 30 * i),
            "leaf4" if i % 2 else "leaf")
    return (w * 0.5, d * 0.5), c.y - h * 0.5


def build(name="Z1_WalkingOrchard_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a long, deep-chested torso of studded bark with a patchwork of bark plates ----------------------------
    J("Body")
    k.hinge("Body", (0, 4.2, 0.3))
    k.p("Chest", (2.9, 2.9, 2.2), CF(Vector((0, 4.3, -1.9))), "bark")
    k.p("ChestFront", (2.5, 2.4, 0.6), CF(Vector((0, 4.2, -3.2))), "bark2")
    k.p("Barrel", (3.1, 2.6, 2.6), CF(Vector((0, 4.15, 0.45))), "bark2")
    k.p("Hips", (2.9, 2.7, 2.1), CF(Vector((0, 4.3, 2.6))), "bark")
    k.p("Rump", (2.4, 1.7, 0.6), CF(Vector((0, 4.6, 3.9))), "bark2")
    k.p("Belly", (2.4, 0.5, 5.2), CF(Vector((0, 2.75, 0.3))), "bark3", studs=False)
    for sx in (-1, 1):  # bark plates patching the flanks
        for j, (y, z, w, h) in enumerate(((3.7, -1.9, 0.9, 0.8), (4.6, -1.2, 0.8, 0.7), (3.6, -0.2, 1.0, 0.7),
                                          (4.5, 0.75, 0.9, 0.8), (3.7, 1.75, 0.8, 0.75), (4.6, 2.7, 0.9, 0.7))):
            x = sx * (1.47 if -2.9 < z < -0.9 else 1.57 if -0.9 <= z < 1.6 else 1.47)
            k.p("BarkPlate%d_%d" % (sx + 2, j + 1), (0.16, h, w), CF(Vector((x, y, z))) * cf(rx=7 * (-1) ** j),
                ("bark3", "bark4")[j % 2], studs=False)
    # a cream bib running up the chest to the neck, and a cream collar over the crest
    k.p("Bib", (1.6, 1.0, 0.35), CF(Vector((0, 5.35, -3.45))), "cream", studs=False)
    k.p("Bib2", (1.3, 0.7, 0.35), CF(Vector((0, 6.0, -3.35))), "cream2", studs=False)
    for sx in (-1, 1):
        k.p("Collar%d" % (sx + 2), (1.2, 0.36, 0.3), CF(Vector((sx * 0.55, 4.95, -3.55))) * cf(rz=-sx * 22), "cream",
            studs=False)
    # the sacred crest: a cream-framed gold shield with a glowing tree
    f = T.plane_frame((0, 3.95, -3.55), (0, 0.08, -1))
    k.p("CrestFrame", (1.85, 1.45, 0.2), f, "cream", studs=False)
    k.p("CrestFramePoint", (1.3, 1.3, 0.2), f * CF((0, -0.7, 0)) * cf(rz=45), "cream", studs=False)
    k.p("Crest", (1.55, 1.2, 0.26), f * CF((0, 0.03, 0.03)), "gold", studs=False)
    k.p("CrestPoint", (1.06, 1.06, 0.26), f * CF((0, -0.68, 0.03)) * cf(rz=45), "gold", studs=False)
    k.p("CrestField", (1.25, 0.95, 0.28), f * CF((0, 0.05, 0.04)), "gold2", studs=False)
    for nm, size, pos, rz in (("Trunk", (0.16, 0.9), (0, -0.3), 0), ("Crown", (0.22, 0.22), (0, 0.48), 45),
                              ("BranchL", (0.1, 0.48), (-0.17, 0.2), 35), ("BranchR", (0.1, 0.48), (0.17, 0.2), -35),
                              ("BoughL", (0.09, 0.36), (-0.36, 0.08), 62), ("BoughR", (0.09, 0.36), (0.36, 0.08), -62),
                              ("LeafL", (0.18, 0.18), (-0.38, 0.34), 45), ("LeafR", (0.18, 0.18), (0.38, 0.34), 45),
                              ("RootL", (0.08, 0.32), (-0.15, -0.8), 40), ("RootR", (0.08, 0.32), (0.15, -0.8), -40)):
        k.p("Tree" + nm, (size[0], size[1], 0.3), f * CF((pos[0], pos[1], 0.06)) * cf(rz=rz), "goldglow",
            material="Neon", studs=False)
    # the leafy mantle: two layers of leaf plates draped over the back and flanks, a spine row, blossoms, berries
    for j, z in enumerate((-2.3, -1.45, -0.6, 0.25, 1.1, 1.95, 2.8, 3.6)):
        for sx in (-1, 1):
            A.leaf(k, "Mantle%d_%d" % (sx + 2, j + 1), (sx * 0.4, 5.62, z), (sx, -0.5, 0.12), 1.55, 0.88,
                   ("leaf", "leaf2", "leaf4")[(j + (sx > 0)) % 3], thick=0.14, normal=(sx * 0.45, 1, 0))
            A.leaf(k, "Drape%d_%d" % (sx + 2, j + 1), (sx * 1.45, 5.1, z + 0.4), (sx * 0.4, -1, 0.1), 1.25, 0.76,
                   ("leaf2", "leaf3", "leaf")[(j + (sx > 0)) % 3], thick=0.12, normal=(sx, 0.25, 0))
    for j, z in enumerate((-1.9, -1.0, -0.1, 0.8, 1.7, 2.6, 3.4)):
        A.leaf(k, "SpineLeaf%d" % (j + 1), (0, 5.78, z), (0, 0.25, 1), 1.05, 0.8, "leaf3" if j % 2 else "leaf2",
               thick=0.14, normal=(0, 1, 0))
    for i, (x, z, sz) in enumerate(((-0.8, -1.9, 0.6), (0.9, -0.8, 0.55), (-0.65, 0.5, 0.55), (0.75, 1.6, 0.6),
                                    (0.0, 2.9, 0.5), (-1.35, -0.4, 0.45), (1.3, 2.6, 0.45), (-0.9, 3.4, 0.45))):
        A.blossom(k, "Blossom%d" % (i + 1), (x, 6.0, z), (x * 0.3, 1, 0), sz, petal="flower", centre="pollen")
    for i, (x, z) in enumerate(((0.4, -2.4), (-1.0, 0.0), (1.05, 1.0), (-0.45, 2.25))):
        for b in range(3):
            k.p("Berry%d_%d" % (i + 1, b + 1), (0.24, 0.24, 0.24),
                CF(Vector((x + 0.18 * (b - 1), 5.92 + 0.13 * (b == 1), z + 0.1 * (b % 2)))), "berry", studs=False)

    # ---- legs: thick tree-trunk columns, gold knee guards, gold ankle bands, chunky gold hooves, root toes -----------
    for sx, sd in A.SIDES:
        for joint, H, K, F, widths in (("Arm" + sd, (sx * 1.05, 3.4, -1.95), (sx * 1.1, 1.8, -2.05),
                                         (sx * 1.1, 0.65, -2.0), (1.4, 1.2)),
                                        ("Leg" + sd, (sx * 1.05, 3.6, 2.6), (sx * 1.15, 1.95, 3.05),
                                         (sx * 1.1, 0.65, 2.75), (1.6, 1.2))):
            H, K, F = Vector(H), Vector(K), Vector(F)
            A.limb(k, joint, [H, K, F], widths, ("bark", "bark2"))
            if joint.startswith("Leg"):
                k.p("Thigh" + joint, (1.55, 2.0, 1.9), CF(Vector((sx * 1.1, 3.5, 2.55))), "bark")
            else:
                k.p("Shoulder" + joint, (1.5, 1.6, 1.6), CF(Vector((sx * 1.1, 3.6, -1.95))), "bark")
            for j, (dy, dz) in enumerate(((0.55, -0.4), (-0.35, 0.35))):  # bark plates on the leg
                k.p("LegPlate%s%d" % (joint, j + 1), (0.14, 0.6, 0.55),
                    CF(K.lerp(H, 0.5) + Vector((sx * widths[0] * 0.52, dy, dz))), ("bark3", "bark4")[j],
                    studs=False)
            k.p("KneeGuard" + joint, (widths[1] + 0.3, 0.36, widths[1] + 0.3), CF(K + Vector((0, 0.3, 0))), "gold",
                studs=False)
            k.p("KneeTrim" + joint, (widths[1] + 0.38, 0.1, widths[1] + 0.38), CF(K + Vector((0, 0.52, 0))), "gold2",
                studs=False)
            k.p("Hoof" + joint, (1.5, 0.6, 1.65), CF(Vector((F.x, 0.3, F.z - 0.05))), "gold")
            k.p("HoofCap" + joint, (1.3, 0.12, 1.45), CF(Vector((F.x, 0.66, F.z - 0.05))), "gold2", studs=False)
            for t in (-1, 0, 1):
                a = Vector((F.x + t * 0.45, 0.2, F.z - 0.7))
                k.seg("Toe%s%d" % (joint, t + 2), a, a + Vector((t * 0.3, -0.1, -0.5)), 0.3, 0.26, "bark",
                      studs=False)
            for j, d in enumerate(((sx * 0.45, -1, -0.3), (sx * 0.45, -1, 0.35))):
                A.leaf(k, "LegLeaf%s%d" % (joint, j + 1), H + Vector((sx * 0.7, 0.35, 0.3 * (j * 2 - 1))), d, 1.0,
                       0.55, ("leaf2", "leaf")[j], thick=0.12, normal=(sx, 0.2, 0))

    # ---- neck: thick and leaning forward, the cream bib running up its front, a leafy mane ---------------------------
    J("Neck")
    k.hinge("Neck", (0, 5.2, -2.6))
    k.seg("Neck", (0, 4.9, -2.5), (0, 6.25, -3.55), 2.0, 1.8, "bark", up_hint=(0, 0, -1))
    k.p("NeckTop", (1.8, 1.0, 1.6), CF(Vector((0, 6.15, -3.45))), "bark2")
    k.seg("Throat", (0, 5.6, -3.6), (0, 6.25, -4.2), 1.1, 0.3, "cream", up_hint=(0, 0, -1), studs=False)
    for i in range(5):
        A.leaf(k, "Mane%d" % (i + 1), (0, 6.65 - 0.35 * i, -3.1 + 0.25 * i), (0, 0.25, 1), 1.05, 0.72,
               ("leaf2", "leaf", "leaf3")[i % 3], thick=0.14, normal=(0, 1, 0.2))

    # ---- head: brown with a cream muzzle and blaze, glowing gold eyes, leaf ears ------------------------------------
    J("Head")
    k.hinge("Head", (0, 6.3, -3.8))
    H = A.Frame(k, CF(Vector((0, 6.8, -4.35))) * cf(rx=-14), s=1.4)
    H.p("Skull", (1.35, 1.15, 1.35), (0, 0, 0), "bark")
    H.p("Brow", (1.45, 0.32, 0.6), (0, 0.45, -0.42), "bark2", studs=False)
    H.p("Blaze", (0.42, 0.85, 0.1), (0, 0.22, -0.7), "cream", studs=False)
    H.p("Muzzle", (0.9, 0.72, 0.95), (0, -0.28, -1.05), "cream")
    H.p("MuzzleTop", (0.62, 0.2, 0.8), (0, 0.12, -1.0), "bark", studs=False)
    H.p("Nose", (0.52, 0.28, 0.18), (0, -0.08, -1.55), "nose", studs=False)
    H.p("Mouth", (0.56, 0.06, 0.06), (0, -0.5, -1.48), "ink", studs=False)
    for sx in (-1, 1):
        H.p("Cheek%d" % (sx + 2), (0.28, 0.5, 0.65), (sx * 0.62, -0.3, -0.5), "cream2", studs=False)
    A.eyes(H, "side", 0.68, 0.12, -0.35, 0.38, 0.24, iris="eye", socket=True)
    for sx, sd in A.SIDES:
        A.leaf(k, "Ear" + sd, H.pt((sx * 0.6, 0.42, 0.25)), H.vec((sx, 0.35, 0.3)), 0.95, 0.44, "bark",
               thick=0.14, normal=H.vec((0, 1, 0.2)), vein="cream")

    # ---- antlers: huge gnarled branches spreading to the sides, each carrying a broad stepped canopy hung with gem
    #      fruit, leaf clusters on the inner tines, hanging vines and gold crystals ------------------------------------
    for sx, sd in A.SIDES:
        J("Antler" + sd)
        base = H.pt((sx * 0.42, 0.55, 0.15))
        k.hinge("Antler" + sd, base)
        pts = gnarl(k, "Antler" + sd, base, (((sx * 0.9, 0.8, 0.1), 0.95), ((sx * 1.3, 0.35, 0.2), 1.3),
                                             ((sx * 1.3, 0.2, -0.1), 1.3), ((sx * 0.9, 0.5, 0.05), 0.9)), 0.8)
        # tines: a forward one with a crystal, an upright one carrying a leaf cluster, a back one with a crystal, and
        # two props under the canopy
        tf = gnarl(k, "TineF" + sd, pts[1], (((sx * 0.25, 1, -0.6), 0.8), ((sx * 0.1, 1, -0.2), 0.5)), 0.36)
        k.crystal("CrystalF" + sd, tf[2], Vector((sx * 0.1, 1, -0.2)), 0.65, 0.26, body="crystal", tip="goldglow")
        tu = gnarl(k, "TineU" + sd, pts[2], (((sx * 0.1, 1, 0.3), 0.9), ((-sx * 0.2, 1, 0.1), 0.55)), 0.4)
        tb = gnarl(k, "TineB" + sd, pts[2], (((sx * 0.35, 0.7, 0.9), 0.85),), 0.32)
        k.crystal("CrystalB" + sd, tb[1], Vector((sx * 0.35, 0.7, 0.9)), 0.55, 0.24, body="crystal", tip="goldglow")
        for j, (d, ln) in enumerate((((sx * 0.3, 1, -0.4), 0.7), ((sx * 0.2, 1, 0.5), 0.75))):
            gnarl(k, "Prop%s%d" % (sd, j + 1), pts[3], ((d, ln),), 0.36)
        k.crystal("CrystalM" + sd, pts[3] + Vector((0, 0.2, 0)), Vector((sx * 0.4, 0.6, -0.6)), 0.5, 0.22,
                  body="crystal", tip="goldglow")
        k.crystal("CrystalTip" + sd, pts[4], Vector((sx, 0.3, 0)), 0.55, 0.24, body="crystal", tip="goldglow")
        # the main canopy over the outer half of the antler
        cc = pts[3].lerp(pts[4], 0.5) + Vector((0, 0.95, 0))
        (rx, rz), under = deck_canopy(k, "Canopy" + sd, cc, (3.4, 0.8, 3.0), ry=sx * 8)
        for i in range(6):  # gem fruit hung round the rim on stems of different lengths
            a = 2 * math.pi * (i + 0.3) / 6
            p = Vector((cc.x + math.sin(a) * rx * (0.8 - 0.25 * (i % 2)), under, cc.z - math.cos(a) * rz * 0.8))
            stem = (0.25, 0.75, 0.4, 0.95, 0.3, 0.6)[i]
            sz = (0.58, 0.7, 0.55, 0.66, 0.6, 0.52)[i]
            gem_fruit(k, "Fruit%s%d" % (sd, i + 1), p - Vector((0, stem + sz * 0.6 + 0.05, 0)), sz, stem=stem)
        for i, (ox, oz) in enumerate(((0.9, 0.5), (-0.6, -0.7), (0.2, 0.9), (-1.0, 0.4))):
            A.blossom(k, "CanopyBlossom%s%d" % (sd, i + 1), cc + Vector((sx * ox, 0.38 + 0.5 * (i % 2), oz)),
                      (0, 1, 0), 0.42, petal="flower", centre="pollen")
        for i, (ox, oz, ln) in enumerate(((1.3, -0.4, 1.3), (-1.2, 0.6, 1.0), (0.4, 1.2, 1.15))):  # hanging vines
            top = Vector((cc.x + sx * ox, under, cc.z + oz))
            k.seg("Vine%s%d" % (sd, i + 1), top, top - Vector((0, ln, 0)), 0.09, 0.09, "leaf4", studs=False)
            A.leaf(k, "VineLeaf%s%d" % (sd, i + 1), top - Vector((0, ln * 0.6, 0)), (sx, -0.3, 0), 0.4, 0.24, "leaf3",
                   thick=0.08, normal=(0, 0, -1), tip=False)
        # a smaller leaf cluster on the upright tine
        uc = tu[2] + Vector((0, 0.3, 0))
        (urx, urz), uunder = deck_canopy(k, "Cluster" + sd, uc, (1.8, 0.55, 1.6), ry=-sx * 15)
        gem_fruit(k, "ClusterFruit" + sd, Vector((uc.x - sx * urx * 0.5, uunder - 0.8, uc.z + 0.3)), 0.52, stem=0.35)

    # ---- tail: a long gnarled root-branch sweeping back and down, forking into gold-crystal tips --------------------
    J("Tail")
    k.hinge("Tail", (0, 4.9, 4.1))
    tp = gnarl(k, "Tail", (0, 4.9, 4.05), (((0, -0.15, 1), 1.0), ((0.1, -0.75, 0.85), 1.15), ((0.15, -0.95, 0.5), 1.1),
                                          ((0.1, -0.6, 0.8), 0.6)), 0.95, taper=0.82)
    for t, (d, ln) in enumerate((((0.6, -0.6, 0.5), 0.8), ((-0.45, -0.5, 0.7), 0.85), ((0.1, -0.3, 1), 0.7))):
        f2 = gnarl(k, "TailFork%d" % (t + 1), tp[4], ((d, ln),), 0.3)
        k.crystal("TailCrystal%d" % (t + 1), f2[1], Vector(d), 0.55, 0.24, body="crystal", tip="goldglow")
    for i, (p, d) in enumerate(((tp[1], (0.8, 0.3, 0.3)), (tp[1], (-0.8, 0.3, 0.3)), (tp[2], (0.7, 0.2, 0.4)),
                                (tp[2], (-0.7, 0.2, 0.2)), (tp[3], (0.6, 0.3, 0.3)), (tp[3], (-0.6, 0.3, 0.4)))):
        A.leaf(k, "TailLeaf%d" % (i + 1), p + Vector((0, 0.2, 0)), d, 0.8, 0.45, ("leaf2", "leaf", "leaf3")[i % 3],
               thick=0.12, normal=(0, 1, 0))
    for i, p in enumerate((tp[1], tp[3])):
        A.blossom(k, "TailBlossom%d" % (i + 1), p + Vector((0, 0.45, 0)), (0, 1, 0.2), 0.42, petal="flower",
                  centre="pollen")

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
