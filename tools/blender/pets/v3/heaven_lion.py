# 78 Heaven Lion V3 (Rainbow Heaven, Divine), Roblox primitives only (Frost Serpent method, studs on top faces).
# Built to the user's reference (2026-10-31, second pass: "fierce, not like a dog, a lot more built"): a heroic
# statue lion. Massive pillar legs and broad shoulders and haunches, a deep chest held high. The head is a lion's,
# not a dog's: a broad flat face, a wide short muzzle with whisker pads, a T-shaped nose, a heavy brow angled down over
# narrow glowing gold eyes, fangs under a stern frown, a gold diamond crown with a star. The mane is a sunburst of
# layered rhombus scales radiating from the face (white, gold and glowing gold), flaring into swept spikes and a tall
# crest, a collar over the shoulders and a bib down the chest. Star medallions in gold frames on the shoulders, sun
# medallions on the haunches, gold bracers with glowing diamonds, white toes with gold claws, an S-curled banded tail
# ending in a sun of feather blades, a halo arc with a star. Palette: white, gold, glowing gold, a dark nose.
# Joints: Body (body, mane, halo), Head, ArmL/R (front legs and shoulders), LegL/R (haunches and hind legs), Tail.
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, look, use
from v3 import top_parts as T

PAL = dict(main="F6F2E8", main2="E8E1CF", dark="C9932E", light="FFFFFF", glow="FFD966", gold="E2B04A",
           gold2="C9932E", ink="3E2A1E", nose="5B3A2C", eye="FFE27A", glass="FFE9A6", tip="FFF7D6")
CONCEPT = "Heaven Lion: heroic white-and-gold statue lion, sunburst rhombus mane with crest, fierce glowing glare"
HEADER = '''--!strict
-- 78 Heaven Lion V3 (Rainbow Heaven, Divine). Preview candidate (KICK_AN_EGG_PET_REMODEL_V3), not wired.
-- Pet: a heroic white-and-gold statue lion (the user's reference): pillar legs, broad shoulders and haunches, a fierce
--      lion face (wide short muzzle, heavy brow, glowing gold eyes, fangs, a diamond star crown), a sunburst mane of
--      layered rhombus scales with a crest, collar and chest bib, star and sun medallions, gold bracers, gold claws,
--      an S-curled banded tail ending in a feathered sun, a halo arc.
-- Egg: white and gold terraces, a band of rhombus scales, star medallions on four faces, a crown of sun rays, the
--      Divine band and a halo arc.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/heaven_lion.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.05

HEAD = Vector((0, 5.0, -2.75))  # head centre
MANE = Vector((0, 5.25, -1.2))  # mane ellipsoid centre, behind the face


def medallion(k, name, centre, normal, size):
    """Glowing four-point star in a gold diamond frame (shoulders)."""
    T.diamond_frame(k, name + "Frame", Vector(centre) - Vector(normal).normalized() * 0.02, normal, size * 1.05,
                    "gold", bar=0.16)
    T.star4(k, name + "Star", centre, normal, size, "glow", core="light")


def sun(k, name, centre, normal, r):
    """Round sun medallion facing +-X (a cylinder's axis is its X): a glowing disc, a gold rim, a white star."""
    n = Vector(normal).normalized()
    k.p(name + "Disc", (0.12, r * 1.6, r * 1.6), CF(Vector(centre)), "glow", shape="Cylinder", material="Neon")
    T.ring(k, name + "Rim", Vector(centre), n, r * 1.02, 8, 0.12, 0.16, "gold", studs=False)
    T.star4(k, name + "Star", Vector(centre) + n * 0.08, n, r * 0.95, "light", core="glow")


def diamond(k, name, p, n, radial, s, col, thick=0.16):
    """Rhombus scale: a square plate facing n, one diagonal along `radial`."""
    k.p(name, (s, thick, s), look(p, n, radial) * cf(ry=45), col,
        material="Neon" if col == "glow" else "SmoothPlastic", studs=False)


def spike(k, name, base, d, n, length, width, col, thick=0.16):
    """Pointed feather blade (two wedges) from `base` along `d`, flat face towards n."""
    d = Vector(d).normalized()
    side = Vector(n).cross(d).normalized()
    base = Vector(base)
    k.tri(name, base + side * width / 2, base - side * width / 2, base + d * length, thick, col,
          material="Neon" if col == "glow" else "SmoothPlastic")


def build(name="PK3_HeavenLion_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a deep chest held high, barrel, hips; gold trims -------------------------------------------------
    J("Body")
    k.hinge("Body", (0, 3.4, 0.3))
    k.p("Chest", (2.3, 2.5, 2.0), CF(Vector((0, 3.5, -1.1))), "main")
    k.p("Neck", (1.6, 1.5, 1.4), CF(Vector((0, 4.75, -1.75))), "main2")
    k.p("Barrel", (2.0, 1.85, 1.7), CF(Vector((0, 3.55, 0.5))), "main2")  # a tucked waist
    k.p("Hips", (2.2, 2.2, 1.6), CF(Vector((0, 3.45, 1.85))), "main")
    k.p("Back", (1.7, 0.32, 3.0), CF(Vector((0, 4.6, 0.8))), "main")
    k.p("Belly", (1.6, 0.3, 1.6), CF(Vector((0, 2.66, 0.5))), "main2", studs=False)
    for sx, sd in A.SIDES:  # a gold frame round the flank with a glowing diamond
        k.p("Trim" + sd, (0.1, 0.2, 1.7), CF(Vector((sx * 1.06, 4.3, 0.5))), "gold", studs=False)
        k.p("TrimLow" + sd, (0.1, 0.16, 1.7), CF(Vector((sx * 1.06, 2.75, 0.5))), "gold2", studs=False)
        k.p("TrimBack" + sd, (0.1, 1.55, 0.16), CF(Vector((sx * 1.06, 3.52, 1.3))), "gold", studs=False)
        k.p("FlankGem" + sd, (0.1, 0.62, 0.62), CF(Vector((sx * 1.06, 3.52, 0.5))) * cf(rx=45), "gold",
            studs=False)
        k.p("FlankCore" + sd, (0.08, 0.34, 0.34), CF(Vector((sx * 1.12, 3.52, 0.5))) * cf(rx=45), "glow",
            material="Neon", studs=False)

    # ---- the mane: rows of big rhombus scales wrapped round an ellipsoid (an artichoke opening at the face) -----
    a, b, c = 2.3, 2.45, 2.3  # ellipsoid radii round MANE

    def on_mane(phi, th):
        u = Vector((math.sin(phi) * math.sin(th), math.sin(phi) * math.cos(th), -math.cos(phi)))
        p = MANE + Vector((a * u.x, b * u.y, c * u.z))
        nrm = Vector((u.x / a, u.y / b, u.z / c)).normalized()
        slope = Vector((a * math.cos(phi) * math.sin(th), b * math.cos(phi) * math.cos(th),
                        c * math.sin(phi))).normalized()  # towards the back
        return p, nrm, slope

    rows = [  # angle from the face axis, count, scale size, colour pattern
        (36, 14, 1.0, ("main",)),
        (54, 18, 1.12, ("gold", "main")),
        (72, 20, 1.2, ("main", "main", "glow", "main")),
        (90, 20, 1.22, ("gold", "dark")),
        (108, 16, 1.15, ("main2", "main2", "gold")),
        (126, 12, 1.1, ("main",)),
    ]
    for ri, (deg, n, size, pat) in enumerate(rows):
        for j in range(n):
            th = 2 * math.pi * (j + 0.5 * (ri % 2)) / n
            if deg >= 90 and math.cos(th) < -0.55:  # inside the chest
                continue
            pos, nrm, slope = on_mane(math.radians(deg), th)
            diamond(k, "Mane%d_%d" % (ri + 1, j + 1), pos, (nrm - slope * 0.4).normalized(), slope, size,
                    pat[j % len(pat)], thick=0.18)
    # flaring blades round the rim, longest at the top; none over the chest
    for j in range(18):
        th = 2 * math.pi * (j + 0.5) / 18
        if math.cos(th) < -0.45:
            continue
        pos, nrm, slope = on_mane(math.radians(78), th)
        ln = 1.05 + 0.65 * max(0.0, math.cos(th))
        d = Vector((math.sin(th), math.cos(th), 0.45))
        spike(k, "ManeSpike%d" % (j + 1), pos, d, (0, 0, -1), ln, 0.72, ("gold", "glow", "main")[j % 3], thick=0.18)
    # a tall crest of swept blades over the head
    for i, (x, ln, col) in enumerate(((0, 2.2, "gold"), (-0.55, 1.85, "glow"), (0.55, 1.85, "glow"),
                                       (-1.05, 1.5, "main"), (1.05, 1.5, "main"))):
        base = MANE + Vector((x, b * 0.82 - 0.1 * abs(x), 0.15 + 0.25 * abs(x)))
        spike(k, "Crest%d" % (i + 1), base, (x * 0.45, 1, 0.7), (x * 0.4, 0, -1), ln, 0.72, col, thick=0.18)
    # a bib under the chin, down the chest, carrying the radiant chest star
    for i, (x, y, sz) in enumerate(((-0.55, 3.15, 0.85), (0.55, 3.15, 0.85))):
        diamond(k, "Bib%d" % (i + 1), Vector((x, y, -2.32)), Vector((0, -0.25, -1)).normalized(),
                Vector((0, -1, 0)), sz, "main", thick=0.18)
    chest = Vector((0, 2.85, -2.46))
    medallion(k, "ChestStar", chest, (0, -0.2, -1), 0.62)
    for i in range(8):  # short gold rays round the chest star
        ang = 2 * math.pi * i / 8 + math.pi / 8
        d = Vector((math.cos(ang), math.sin(ang), 0))
        spike(k, "ChestRay%d" % (i + 1), chest + d * 0.62 + Vector((0, 0, 0.03)), d, (0, 0, -1), 0.32, 0.18, "gold",
              thick=0.1)
    # wing-like flares sweeping back off the shoulders (the reference's shoulder feathers)
    for sx, sd in A.SIDES:
        for i, (ln, up, col) in enumerate(((1.75, 0.75, "gold"), (1.45, 0.45, "main"), (1.15, 0.2, "glow"))):
            base = Vector((sx * 1.35, 4.35 - 0.25 * i, -0.6 + 0.35 * i))
            d = Vector((sx * 0.55, up, 1.0))
            spike(k, "ShoulderWing%s%d" % (sd, i + 1), base, d, Vector((sx, 0.35, 0)).normalized(), ln, 0.62, col,
                  thick=0.16)

    # ---- halo arc behind the mane with a star on top ---------------------------------------------------------------
    hc = Vector((0, 6.5, -0.2))
    for i in range(14):
        ang = math.radians(-12 + i * (204 / 13))
        pos = hc + Vector((math.cos(ang), math.sin(ang), 0)) * 2.8
        k.p("Halo%d" % (i + 1), (0.56, 0.18, 0.18), look(pos, Vector((0, 0, 1)),
            Vector((math.cos(ang), math.sin(ang), 0))) * cf(ry=90), "glow" if i % 2 else "gold",
            material="Neon" if i % 2 else "SmoothPlastic", studs=False)
    T.star4(k, "HaloStar", hc + Vector((0, 3.05, -0.05)), (0, 0, -1), 0.62, "glow", core="light")

    # ---- head: a broad lion face, wide short muzzle, heavy brow, glowing glare, a snarl with fangs, star crown -----
    J("Head")
    k.hinge("Head", (0, 4.7, -2.0))
    H = A.Frame(k, CF(HEAD), s=1.45)
    H.p("Skull", (1.5, 1.2, 1.3), (0, 0.12, 0.05), "main")
    H.p("Forehead", (1.0, 0.46, 0.22), (0, 0.48, -0.66), "main2", studs=False)
    for sx, sd in A.SIDES:
        H.p("Cheek" + sd, (0.5, 0.75, 0.7), (sx * 0.76, -0.36, -0.36), "main")
        H.p("Brow" + sd, (0.74, 0.26, 0.32), (sx * 0.37, 0.27, -0.76), "main2", rz=-sx * 24, studs=False)
        H.p("Pad" + sd, (0.66, 0.52, 0.5), (sx * 0.31, -0.42, -0.98), "main")
        fx = sx * 0.21  # upper fangs over the snarl, lower canines up from the jaw
        k.tri("Fang" + sd, H.pt((fx - 0.08, -0.62, -1.24)), H.pt((fx + 0.08, -0.62, -1.24)),
              H.pt((fx, -0.88, -1.24)), 0.1, "light")
        lx = sx * 0.34
        k.tri("Canine" + sd, H.pt((lx - 0.06, -0.86, -1.22)), H.pt((lx + 0.06, -0.86, -1.22)),
              H.pt((lx, -0.68, -1.22)), 0.1, "light")
    A.eyes(H, "almond", 0.37, 0.05, -0.84, 0.48, 0.2, iris="eye", rz=16, look_in=0.02)
    H.p("Bridge", (0.62, 0.34, 0.72), (0, 0.06, -0.92), "main", rx=-10)
    H.p("Nose", (0.5, 0.2, 0.18), (0, -0.12, -1.26), "nose", studs=False)
    k.tri("NoseTip", H.pt((-0.25, -0.22, -1.28)), H.pt((0.25, -0.22, -1.28)), H.pt((0, -0.38, -1.28)), 0.12, "nose")
    H.p("Philtrum", (0.06, 0.16, 0.04), (0, -0.48, -1.24), "ink", studs=False)
    H.p("Mouth", (0.86, 0.22, 0.3), (0, -0.74, -1.06), "ink", studs=False)
    H.p("Jaw", (1.0, 0.32, 0.62), (0, -0.96, -0.92), "main2")
    T.diamond_frame(k, "CrownFrame", H.pt((0, 0.66, -0.84)), H.vec((0, 0.3, -1)), 0.36 * 1.45, "gold", bar=0.14)
    T.star4(k, "Crown", H.pt((0, 0.66, -0.88)), H.vec((0, 0.3, -1)), 0.4 * 1.45, "glow", core="light")
    spike(k, "CrownSpike", H.pt((0, 0.95, -0.74)), H.vec((0, 1, -0.15)), H.vec((0, 0, -1)), 1.0, 0.42, "gold")

    # ---- legs: broad shoulders and haunches, pillar legs, gold bracers, white toes with gold claws ------------------
    for joint, sx, z, front in (("ArmL", -1, -1.25, True), ("ArmR", 1, -1.25, True), ("LegL", -1, 1.85, False),
                                ("LegR", 1, 1.85, False)):
        x = sx * 0.98
        k.hinge(joint, (x, 3.4, z))
        if front:
            k.p("Shoulder" + joint, (1.2, 1.9, 1.5), CF(Vector((x, 3.35, z))), "main")
            k.p("ShoulderTop" + joint, (0.12, 0.16, 1.5), CF(Vector((sx * 1.6, 4.25, z))), "gold", studs=False)
            k.p("ShoulderEdge" + joint, (0.12, 1.75, 0.16), CF(Vector((sx * 1.6, 3.4, z - 0.72))), "gold",
                studs=False)
            medallion(k, "Shoulder" + joint, (sx * 1.66, 3.35, z + 0.05), (sx, 0, 0), 0.55)
            col_z = z - 0.05
            k.p("Forearm" + joint, (1.38, 0.95, 1.42), CF(Vector((x, 2.2, col_z))), "main")  # muscle over the bracer
        else:
            k.p("Haunch" + joint, (1.3, 2.2, 2.0), CF(Vector((x, 3.3, z))), "main")
            k.p("Thigh" + joint, (1.2, 1.1, 1.6), CF(Vector((x, 2.2, z + 0.1))), "main2")
            sun(k, "Hip" + joint, (sx * 1.66, 3.35, z), (sx, 0, 0), 0.5)
            col_z = z + 0.2
        k.p("Pillar" + joint, (1.2, 2.3, 1.25), CF(Vector((x, 1.35, col_z))), "main2" if front else "main")
        k.p("Bracer" + joint, (1.32, 0.44, 1.37), CF(Vector((x, 1.25, col_z))), "gold")
        k.p("BracerTrim" + joint, (1.37, 0.1, 1.42), CF(Vector((x, 1.51, col_z))), "gold2", studs=False)
        k.p("BracerGem" + joint, (0.5, 0.5, 0.12), CF(Vector((x, 1.25, col_z - 0.72))) * cf(rz=45), "gold",
            studs=False)
        k.p("BracerCore" + joint, (0.24, 0.24, 0.08), CF(Vector((x, 1.25, col_z - 0.8))) * cf(rz=45), "glow",
            material="Neon", studs=False)
        spike(k, "BracerFlare" + joint, (sx * 1.3, 1.45, col_z + 0.3), (sx * 0.35, 1, 0.5), (sx, 0, 0), 0.6, 0.34,
              "gold")
        k.p("Paw" + joint, (1.45, 0.44, 1.6), CF(Vector((x, 0.22, col_z - 0.15))), "main")
        for t, dx in enumerate((-0.51, -0.17, 0.17, 0.51)):
            k.p("Toe%s%d" % (joint, t + 1), (0.31, 0.44, 0.44), CF(Vector((x + dx, 0.25, col_z - 1.06))), "main2")
            k.p("Claw%s%d" % (joint, t + 1), (0.31, 0.13, 0.22), CF(Vector((x + dx, 0.065, col_z - 1.2))), "gold",
                studs=False)

    # ---- tail: an S curl with gold bands, ending in a sun of feather blades (faces the side, as in the reference) ---
    J("Tail")
    k.hinge("Tail", (0, 4.05, 2.6))
    tsegs = A.spine(k, "Tail", [(0, 4.0, 2.55), (0, 3.35, 3.3), (0, 3.7, 4.1), (0, 4.75, 4.35), (0, 5.7, 4.0)], 6,
                    [(0, 0.46), (1, 0.34)], [(0, 0.46), (1, 0.34)], col=("main", "main2"), stretch=1.12)
    for g in tsegs[1::2]:
        k.p("TailBand%d" % (g["i"] + 1), (g["w"] * 1.12, g["t"] * 1.12, 0.14), g["f"], "gold", studs=False)
    sc = tsegs[-1]["b"] + Vector((0, 0.55, -0.2))
    k.p("SunDisc", (0.14, 0.82, 0.82), CF(sc), "glow", shape="Cylinder", material="Neon")
    T.ring(k, "SunRim", sc, (1, 0, 0), 0.48, 8, 0.12, 0.18, "gold", studs=False)
    T.star4(k, "SunStar", sc + Vector((0.1, 0, 0)), (1, 0, 0), 0.46, "light", core="glow")
    for j in range(12):  # feather blades fanning round the sun
        a = 2 * math.pi * j / 12 + math.pi / 12
        d = Vector((0, math.sin(a), math.cos(a)))
        spike(k, "SunBlade%d" % (j + 1), sc + d * 0.5, d, (1, 0, 0), 0.75 if j % 2 else 0.95, 0.42,
              ("gold", "main")[j % 2])
    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))  # Divine reads bigger: scale about the feet
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
