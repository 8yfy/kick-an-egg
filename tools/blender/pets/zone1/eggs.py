# Zone 1 Meadow matching eggs, Roblox primitives only (the Frost Serpent egg method): the classic stepped shell
# (Shell<n> layers in the Body joint, so the chase hitbox, the sprouted legs, incubation growth and hold-E hatching
# keep working unchanged) plus motifs taken from the pet. Shells stay within 4.2 wide and 6 tall. Each egg is its own
# design, never a recolour. Pieces that should open on hatching are named Petal*/Plate*/Arch*/Shard* (the hatch FX
# reads them).
import math

from mathutils import Vector

from kit import anatomy as A
from kit import egg as EG
from kit.rbx import CF, J, cf, look, use
from v3 import top_parts as T

PALS = {
    "Piproot": dict(main="7CCF2E", dark="3E9A2A", light="B5E85A", glow="FFC93C", cream="F3E6C6", cream2="E6D6B0",
                    leaf="7CCF2E", leaf2="5DB52A", leaf3="B5E85A", flower="FFFFFF", flower2="F2F2EA", pollen="FFC93C"),
    "HoneybackBeetle": dict(main="F7C531", dark="B8730C", light="FFE48A", glow="FFB02E", gold="F7C531",
                            honey="FFD95A", amber="FF9A1C", amber2="F28A10", leaf="5FB544", leaf2="3E8E34",
                            flower="FFFFFF", flower2="F2F2EA", pollen="FFC93C"),
    "Crownstag": dict(main="7A3F1E", dark="5A2E14", light="F4E3C4", glow="FFE066", cream="F4E3C4", cream2="E9D3AC",
                      gold="F0B93A", gold2="C48E22", gem="FF4FA0", leaf="5FB544", leaf2="3E8E34", blossom="FF7EB6",
                      blossom2="FFA6CF", bloomcore="FFC93C"),
    "ThistlebackHedgehog": dict(main="F0D29A", main2="E2BE7E", dark="7A4A26", light="F6E6C4", glow="FFE066",
                                leaf="4FA83A", leaf2="6CC23A", leaf4="2E7A2A", vine="7A4A26", thorn="F4D99C",
                                thorn2="E8C27A", berry="D8283A", berry2="F04A55", flower="FFFFFF", flower2="F2F2EA",
                                pollen="FFC93C"),
    "BloomcrestCrane": dict(main="FFF6EA", main2="F5E9D6", dark="D99A22", light="FFFFFF", glow="FFD45A",
                            pink="FF86B4", pink2="F2639E", blush="FFB3CF", gold="F5B935", gold2="D99A22",
                            leaf="6CC23A", leaf2="4FA83A", lotus="FF7EB6", lotus2="FFB0D0", core="FFE58A",
                            blossom="FF7EB6", blossom2="FFA6CF", bloomcore="FFC93C"),
    "BurrowMonarch": dict(main="6E4126", main2="5C3620", dark="3A2214", light="F2E4C8", glow="FFAE2E",
                          stone="8C8578", stone2="726C61", amber="FF9A1F", gold="E3A933", root="5A3A22",
                          moss="5FA83A", leaf="7FC24A", claw="F4ECD8", ear="F0A868", armour="3F7E35",
                          light2="7E4C2C"),
    "WalkingOrchard": dict(main="F7E2B5", main2="EBD09A", dark="6B3F22", light="FFF3DC", glow="FFD45A",
                           cream="F7E2B5", cream2="EBD09A", bark="7A4A2A", bark2="6B3F22", leaf="3E9B35",
                           leaf2="6CC23A", leaf3="9BE04F", flower="FFFFFF", pollen="FFD34E", fruit="D8203A",
                           fruit2="FF5468", fruitglow="FF3355", gold="F2B632", gold2="C98F1E", goldglow="FFE27A"),
    "FirstSeed": dict(main="6E4426", main2="5A361E", dark="472A17", light="F5D9A8", glow="8CFF4A", bark="6E4426",
                      bark2="5A361E", ivory="F5D9A8", ivory2="E8C690", gold="E8BE4A", gold2="B8902E", core="8CFF4A",
                      core2="E6FFB8", vein="7DFF5A", leafglow="9CFF5A", moss="5FB33A"),
}


def _leaf_cap(k, E, name, y, n, ln, w, cols, lift=0.04, tilt=0.55, phase=0.0):
    """A ring of leaves hanging down over the shell from height y (overlapping plates)."""
    for i in range(n):
        a = i * 360 / n + phase
        c = E.on(a, y, lift)
        out = c.vec((0, 0, -1))
        d = (Vector((0, -1, 0)) + out * tilt).normalized()
        A.leaf(k, "%s%d" % (name, i + 1), c.p + Vector((0, 0.12, 0)), d, ln, w, cols[i % len(cols)], thick=0.12,
               normal=out)


def piproot(k):
    from zone1.crownstag import flower

    E = EG.Egg(k, 4.0, 3.1)
    E.shell(lambda i, n: ("cream" if i % 2 else "cream2") if i <= 3 else "main")
    # a bud of big pointed leaves closing over the top half in three overlapping rings (they open on hatching)
    _leaf_cap(k, E, "PetalLeafA", 2.45, 8, 1.35, 0.95, ("leaf", "leaf2"), lift=0.1, tilt=0.45, phase=0.0)
    _leaf_cap(k, E, "PetalLeafB", 3.15, 8, 1.15, 0.85, ("leaf2", "leaf3"), lift=0.1, tilt=0.4, phase=22.5)
    _leaf_cap(k, E, "PetalLeafC", 3.75, 6, 0.9, 0.7, ("leaf3", "leaf"), lift=0.08, tilt=0.3, phase=0.0)
    # white flowers round the waist where the leaves end
    for i, a in enumerate((-30, 45, 120, 190, 260)):
        c = E.on(a, 1.75, 0.08)
        flower(k, "Bloom%d" % (i + 1), c.p + c.vec((0, 0, -1)) * 0.45, c.vec((0, 0.35, -1)), 0.66, petal="flower",
               petal2="flower2", centre="pollen")
    # the two-leaf sprout on top
    top = Vector((0, E.h - 0.05, 0))
    k.seg("SproutStem", top, top + Vector((0, 0.65, 0.05)), 0.2, 0.2, "dark")
    bud = top + Vector((0, 0.65, 0.05))
    for sx, sd in A.SIDES:
        A.leaf(k, "Sprout" + sd, bud, (sx * 0.9, 0.5, 0.05), 1.15, 0.7, "light", thick=0.12, normal=(0, 0, -1),
               vein="main")
    return E


def _hex(k, name, c, size, frame="gold", core=None):
    """Honeycomb cell flush on a shell face frame c (local -Z out): three bars at 60 degrees make a regular hexagon
    `size` across the flats; `core` adds a glowing amber chamber."""
    f = c * CF((0, 0, -0.03))
    for i in range(3):
        k.p("%s%d" % (name, i + 1), (size, size * 0.577, 0.13), f * cf(rz=60 * i + 30), frame, studs=False)
    if core:
        k.p(name + "Core", (size * 0.5, size * 0.5 * 0.577, 0.15), f * CF((0, 0, -0.02)), core, material="Neon",
            studs=False)


def honeyback_beetle(k):
    from zone1.crownstag import flower

    E = EG.Egg(k, 4.2, 3.3)
    E.shell(lambda i, n: "amber2" if i % 2 else "amber")
    # chunky gold honeycomb cells over the whole shell, rows offset like a comb; the amber shell glows between them
    n = 0
    for r, y in enumerate((1.25, 2.05, 2.85, 3.6)):
        for face in (0, 90, 180, 270):
            for t in ((-20, 20) if r % 2 == 0 else (0, 40)):
                if r == 3 and t:
                    continue
                n += 1
                _hex(k, "PlateHex%d" % n, E.on(face + t, y, 0.05), 1.12 - 0.1 * (r == 3),
                     frame="gold" if (n + r) % 2 else "honey", core="amber" if n % 4 == 0 else None)
    top = Vector((0, E.h, 0))
    k.p("CapHex", (0.7, 0.18, 0.4), CF(top) * cf(ry=0), "gold", studs=False)
    k.p("CapHex2", (0.7, 0.18, 0.4), CF(top) * cf(ry=60), "gold", studs=False)
    k.p("CapHex3", (0.7, 0.18, 0.4), CF(top) * cf(ry=120), "gold", studs=False)
    # white flowers and leaves round the base
    for i in range(6):
        a = i * 60 + 15
        c = E.on(a, 0.75, 0.04)
        out = c.vec((0, 0, -1))
        A.leaf(k, "BaseLeaf%d" % (i + 1), c.p + out * 0.2, out * 0.8 + Vector((0, 0.25, 0)), 0.9, 0.5,
               "leaf" if i % 2 else "leaf2", thick=0.12, normal=out)
        if i % 2 == 0:
            flower(k, "BaseFlower%d" % (i // 2 + 1), c.p + out * 0.6 + Vector((0, 0.3, 0)), out + Vector((0, 0.7, 0)),
                   0.75, petal="flower", petal2="flower2", centre="pollen")
    c = E.on(200, 2.0, 0.1)
    flower(k, "SideFlower", c.p + c.vec((0, 0, -1)) * 0.12, c.vec((0, 0.3, -1)), 0.62, petal="flower",
           petal2="flower2", centre="pollen")
    return E


def _vine(k, E, name, path, col, w=0.2):
    """A branch climbing the shell through (angle, y) points, a little proud of the surface. Returns the points."""
    pts = []
    for a, y in path:
        c = E.on(a, y, 0.08)
        pts.append(c.p)
    for i in range(len(pts) - 1):
        d = (pts[i + 1] - pts[i]).normalized()
        k.seg("%s%d" % (name, i + 1), pts[i] - d * 0.06, pts[i + 1] + d * 0.06, w, w, col)
    return pts


def crownstag(k):
    from zone1.crownstag import flower

    E = EG.Egg(k, 4.3, 3.2)
    E.shell(lambda i, n: "main" if i <= 1 else ("cream" if i % 2 else "cream2"))
    EG.rarity(E, "Rare", y=0.85, th=0.18, out=0.08)
    # a thick forking branch on every face: a trunk up from the base forking into two arms, a pink flower at each tip
    for f in range(4):
        a0 = f * 90
        _vine(k, E, "ArchTrunk%d" % (f + 1), ((a0, 0.95), (a0, 1.95)), "main", w=0.3)
        for side, sg in ((-1, "A"), (1, "B")):
            arm = _vine(k, E, "ArchArm%d%s" % (f + 1, sg), ((a0, 1.95), (a0 + side * 22, 2.6), (a0 + side * 30, 3.25)),
                        "main", w=0.24)
            tip = arm[-1]
            out = Vector((tip.x, 0, tip.z)).normalized()
            flower(k, "Bloom%d%s" % (f + 1, sg), tip + out * 0.12, out + Vector((0, 0.35, 0)), 0.55)
    # a ring of leaves and pink flowers round the base
    for i in range(8):
        a = i * 45 + 22.5
        c = E.on(a, 1.2, 0.04)
        out = c.vec((0, 0, -1))
        A.leaf(k, "BaseLeaf%d" % (i + 1), c.p, out * 0.7 + Vector((0, -0.3, 0)), 0.8, 0.46,
               "leaf" if i % 2 else "leaf2", thick=0.12, normal=out)
        if i % 2 == 0:
            flower(k, "BaseFlower%d" % (i // 2 + 1), c.p + out * 0.25 + Vector((0, 0.15, 0)), out + Vector((0, 0.4, 0)),
                   0.66)
    # a gold crown on top: a band, eight points, a pink gem at the front, flowers round it
    y = E.h - 0.55
    EG.band(E, "Circlet", y=y, th=0.2, out=0.09, col="gold")
    EG.band(E, "CircletTrim", y=y - 0.13, th=0.06, out=0.11, col="gold2")
    r = E.r(y) + 0.08
    for i in range(8):
        ang = i * math.pi / 4
        p = Vector((math.sin(ang) * r, y + 0.3, -math.cos(ang) * r))
        k.p("CrownPoint%d" % (i + 1), (0.24, 0.44 if i % 2 == 0 else 0.3, 0.24), CF(p) * cf(ry=-math.degrees(ang),
                                                                                            rz=45), "gold",
            studs=False)
    c = E.on(0, y, 0.18)
    k.p("CircletGem", (0.36, 0.36, 0.14), c * cf(rz=45), "gem", material="Neon", studs=False)
    top = Vector((0, E.h, 0))
    for i, (o, n) in enumerate((((-0.42, 0.12, 0.2), (-0.4, 1, 0.2)), ((0.45, 0.12, -0.1), (0.4, 1, -0.2)),
                                ((0.0, 0.22, 0.45), (0, 1, 0.5)))):
        flower(k, "CrownFlower%d" % (i + 1), top + Vector(o), n, 0.55)
    A.leaf(k, "CrownLeaf1", top + Vector((-0.1, 0.1, -0.3)), (-0.5, 0.6, -0.6), 0.6, 0.34, "leaf", thick=0.1,
           normal=(0, 1, 0))
    A.leaf(k, "CrownLeaf2", top + Vector((0.15, 0.1, 0.25)), (0.6, 0.6, 0.5), 0.6, 0.34, "leaf2", thick=0.1,
           normal=(0, 1, 0))
    return E


def thistleback_hedgehog(k):
    from zone1.crownstag import flower
    from zone1.thistleback_hedgehog import berries, thorn

    E = EG.Egg(k, 4.2, 3.3)
    E.shell(lambda i, n: "main" if i % 2 else "main2")
    EG.rarity(E, "Epic", y=0.85, th=0.18, out=0.08)
    # green leaf plates: big triangles pointing down from the crown and up from the base, tiling the shell
    n = 0
    for y, angles, up in ((3.25, (0, 90, 180, 270), False), (2.35, (45, 135, 225, 315), True),
                          (1.55, (0, 90, 180, 270), True)):
        for a in angles:
            n += 1
            c = E.on(a, y, 0.04)
            h = 1.3 if up else -1.3
            k.tri("PlateLeaf%d" % n, c.point((-0.75, -h / 2, -0.04)), c.point((0.75, -h / 2, -0.04)),
                  c.point((0, h / 2, -0.04)), 0.14, ("leaf", "leaf2", "leaf4")[n % 3])
            k.p("PlateVein%d" % n, (0.07, abs(h) * 0.7, 0.06), c * CF((0, 0, -0.12)), "leaf4", studs=False)
    # a brown vine net climbing over the shell
    for v, path in enumerate((((-30, 0.8), (-10, 1.7), (-30, 2.6), (-5, 3.4), (20, 3.9)),
                              ((60, 0.9), (35, 1.9), (60, 2.9), (40, 3.6)),
                              ((150, 0.8), (175, 1.8), (150, 2.7), (180, 3.5)),
                              ((240, 0.9), (215, 2.0), (245, 3.0), (220, 3.8)))):
        _vine(k, E, "Vine%d_" % (v + 1), path, "vine", w=0.22)
    # cream thorns standing out between the plates, white flowers and red berries
    for i, (a, y, ln) in enumerate(((-45, 2.0, 0.8), (45, 2.8, 0.85), (100, 1.7, 0.8), (160, 2.9, 0.85),
                                    (210, 1.9, 0.8), (280, 2.7, 0.85), (0, 3.9, 0.9), (120, 3.6, 0.75),
                                    (300, 3.7, 0.75))):
        c = E.on(a, y, 0.0)
        out = c.vec((0, 0, -1))
        thorn(k, "Thorn%d" % (i + 1), c.p, out + Vector((0, 0.35, 0)), ln * 1.25, 0.44)
    for i, (a, y) in enumerate(((-55, 2.75), (195, 2.35))):
        c = E.on(a, y, 0.1)
        flower(k, "Flower%d" % (i + 1), c.p + c.vec((0, 0, -1)) * 0.1, c.vec((0, 0.3, -1)), 0.66, petal="flower",
               petal2="flower2", centre="pollen")
    for i, (a, y) in enumerate(((55, 1.55), (255, 2.25))):
        c = E.on(a, y, 0.2)
        berries(k, "Berry%d_" % (i + 1), c.p)
    return E


def bloomcrest_crane(k):
    from zone1.bloomcrest_crane import lotus
    from zone1.crownstag import flower

    E = EG.Egg(k, 4.6, 3.1)
    E.shell(lambda i, n: "main" if i % 2 else "main2")
    EG.rarity(E, "Legendary", y=0.85, th=0.18, out=0.08)
    # gold straps: a band round the waist and straps up the front, back and sides to the crest
    EG.band(E, "GoldBand", y=2.0, th=0.24, out=0.09, col="gold")
    EG.band(E, "GoldBase", y=0.55, th=0.2, out=0.1, col="gold")
    for i in range(4):
        _vine(k, E, "GoldStrap%d" % (i + 1), [(i * 90, y) for y in (0.6, 1.3, 2.0, 2.8, 3.5, E.h - 0.45)], "gold",
              w=0.26)
    # the clasp: a gold diamond on the front with a pink flower, gold leaves either side
    c = E.on(0, 2.0, 0.12)
    k.p("Clasp", (0.95, 0.95, 0.16), c * cf(rz=45), "gold", studs=False)
    k.p("ClaspRim", (0.75, 0.75, 0.18), c * CF((0, 0, -0.02)) * cf(rz=45), "gold2", studs=False)
    flower(k, "ClaspFlower", c.p + c.vec((0, 0, -1)) * 0.16, c.vec((0, 0, -1)), 0.75)
    for sx in (-1, 1):
        k.p("ClaspLeaf%d" % (sx + 2), (0.55, 0.22, 0.12), c * CF((sx * 0.62, 0.12, -0.04)) * cf(rz=sx * 25), "gold",
            studs=False)
    # big green leaves cradling the base on each side
    for i, a in enumerate((70, 110, 250, 290, 160, 200)):
        c = E.on(a, 0.95, 0.04)
        out = c.vec((0, 0, -1))
        A.leaf(k, "BaseLeaf%d" % (i + 1), c.p, out * 0.45 + Vector((0, 1, 0)), 1.5 if i < 4 else 1.1, 0.62,
               "leaf" if i % 2 else "leaf2", thick=0.12, normal=out)
    # the pink lotus crest on a gold base
    top = Vector((0, E.h, 0))
    k.p("CrestBase", (1.0, 0.24, 1.0), CF(top + Vector((0, 0.05, 0))) * cf(ry=45), "gold", studs=False)
    lotus(k, "CrestLotus", (0, E.h + 0.1, 0), (0, 1, 0), 1.05)
    return E


def burrow_monarch(k):
    E = EG.Egg(k, 4.4, 3.4)
    E.shell(lambda i, n: "dark" if i <= 1 else ("main" if i % 2 else "main2"))
    EG.rarity(E, "Mythic", y=0.85, th=0.2, out=0.08)
    # brick blocks of two browns patching the shell (the panels shift apart on hatching)
    n = 0
    for y, angles in ((1.45, (-30, 30, 120, 160, 200, 240)), (2.3, (-55, 55, 100, 150, 210, 260)),
                      (3.15, (-30, 30, 110, 180, 250))):
        for a in angles:
            n += 1
            c = E.on(a, y, 0.02)
            k.p("PlateBrick%d" % n, (0.62 + 0.1 * (n % 3), 0.5 + 0.08 * (n % 2), 0.14), c, "main2" if n % 2 else "light2",
                studs=False)
    # the glowing amber crack network: a trunk up the front branching left and right, more cracks round the back
    def crack(name, path, w=0.16):
        pts = [E.on(a, y, 0.1).p for a, y in path]
        for i in range(len(pts) - 1):
            d = (pts[i + 1] - pts[i]).normalized()
            k.seg("%s%d" % (name, i + 1), pts[i] - d * 0.06, pts[i + 1] + d * 0.06, w, 0.08, "amber",
                  material="Neon", studs=False)

    crack("Crack", ((0, 0.95), (6, 1.6), (-4, 2.2), (5, 2.8), (0, 3.4), (-3, 3.85)))
    crack("CrackL", ((-4, 2.2), (-22, 2.55), (-38, 2.35), (-52, 2.75)), w=0.13)
    crack("CrackR", ((6, 1.6), (24, 1.9), (40, 1.65), (55, 1.95)), w=0.13)
    crack("CrackT", ((5, 2.8), (22, 3.2), (34, 3.5)), w=0.11)
    crack("CrackB", ((180, 1.0), (172, 1.7), (190, 2.4), (178, 3.1), (186, 3.7)))
    crack("CrackBL", ((172, 1.7), (150, 2.0), (132, 1.8)), w=0.12)
    crack("CrackBR", ((190, 2.4), (212, 2.75), (228, 2.55)), w=0.12)
    # green moss bands on the sides, studded
    for sx in (-1, 1):
        for i, y in enumerate((1.5, 2.6)):
            c = E.on(90 * sx, y, 0.06)
            k.p("MossBand%d_%d" % (sx + 2, i + 1), (1.7, 0.42, 0.2), c, "moss", studs=False)
            k.p("MossTuft%d_%d" % (sx + 2, i + 1), (0.9, 0.2, 0.26), c * CF((0.2, 0.24, -0.04)), "leaf", studs=False)
    # the root crown: a gold band, a gold-framed amber diamond at the front, twisting roots with leaf sprouts
    y = E.h - 0.55
    EG.band(E, "CrownBand", y=y, th=0.24, out=0.09, col="gold")
    c = E.on(0, y + 0.05, 0.18)
    k.p("CrownGemSet", (0.7, 0.7, 0.14), c * cf(rz=45), "gold", studs=False)
    k.p("CrownGem", (0.48, 0.48, 0.18), c * CF((0, 0, -0.03)) * cf(rz=45), "amber", material="Neon", studs=False)
    for i, deg in enumerate((35, 90, 145, 215, 270, 325)):
        ang = math.radians(deg)
        out = Vector((math.sin(ang), 0, -math.cos(ang)))
        b = Vector((0, y + 0.1, 0)) + out * (E.r(y) - 0.05)
        pts = A.branch(k, "CrownRoot%d" % (i + 1), b, ((out * 0.3 + Vector((0, 1, 0)), 0.55),
                                                       (out * 0.8 + Vector((0, 0.6, 0)), 0.4)), "root", w0=0.22,
                       taper=0.75)
        k.p("CrownLeaf%d" % (i + 1), (0.4, 0.1, 0.26), CF(pts[-1] + out * 0.12) * cf(ry=-deg, rx=-35), "leaf",
            studs=False)
    top = Vector((0, E.h, 0))
    pts = A.branch(k, "CrownStem", top, (((0.2, 1, 0), 0.5), ((0.5, 0.8, 0.1), 0.35)), "root", w0=0.24)
    k.p("CrownStemLeaf", (0.46, 0.1, 0.3), CF(pts[-1]) * cf(rz=-30), "leaf", studs=False)
    return E


def _tree_emblem(k, name, c, z=-0.16, s=1.0):
    """The glowing sacred tree on a shell frame c (local -Z out)."""
    def g(nm, size, pos, rz=0):
        k.p(name + nm, (size[0] * s, size[1] * s, 0.06), c * CF((pos[0] * s, pos[1] * s, z)) * cf(rz=rz), "goldglow",
            material="Neon", studs=False)
    g("Trunk", (0.13, 0.6), (0, -0.12))
    g("Crown", (0.17, 0.17), (0, 0.36), 45)
    for sx in (-1, 1):
        g("Branch%d" % (sx + 2), (0.08, 0.38), (sx * 0.13, 0.22), -sx * 35)
        g("Bough%d" % (sx + 2), (0.07, 0.28), (sx * 0.28, 0.1), -sx * 62)
        g("Leaf%d" % (sx + 2), (0.15, 0.15), (sx * 0.3, 0.3), 45)
        g("Root%d" % (sx + 2), (0.07, 0.24), (sx * 0.12, -0.45), sx * 40)


def walking_orchard(k):
    from zone1.walking_orchard import gem_fruit

    E = EG.Egg(k, 4.6, 3.4)
    E.shell(lambda i, n: "cream" if i % 2 else "cream2")
    EG.rarity(E, "Divine", y=0.85, th=0.2, out=0.08)
    EG.band(E, "GoldBase", y=0.5, th=0.18, out=0.1, col="gold")
    # thick branches wrapping the shell (they part on hatching), framing the crest at the front
    paths = (((-75, 0.6), (-48, 1.3), (-58, 2.2), (-36, 3.05), (-14, 3.8)),
             ((75, 0.6), (48, 1.3), (58, 2.2), (36, 3.05), (14, 3.8)),
             ((110, 0.7), (148, 1.6), (196, 2.5), (236, 3.4), (205, 4.05)),
             ((250, 0.7), (214, 1.7), (172, 2.85), (134, 3.75)))
    for i, path in enumerate(paths):
        pts = _vine(k, E, "ArchBranch%d_" % (i + 1), path, "bark" if i % 2 else "bark2", w=0.44)
        for j, p in enumerate(pts[1:-1]):
            out = Vector((p.x, 0, p.z)).normalized()
            for side in (-1, 1):
                A.leaf(k, "BranchLeaf%d_%d%s" % (i + 1, j + 1, "AB"[side > 0]), p + out * 0.15,
                       out * 0.45 + Vector((0.55 * side * out.z, 0.55, -0.55 * side * out.x)), 0.8, 0.46,
                       ("leaf", "leaf2", "leaf3")[(i + j + side) % 3], thick=0.12, normal=out)
    for i, (a, y) in enumerate(((-50, 1.55), (54, 2.6), (160, 2.0), (225, 3.0), (100, 3.4), (300, 1.4))):
        c = E.on(a, y, 0.1)
        out = c.vec((0, 0, -1))
        A.blossom(k, "Blossom%d" % (i + 1), c.p + out * 0.08, out + Vector((0, 0.4, 0)), 0.42, petal="flower",
                  centre="pollen")
    for i, (a, y, sz) in enumerate(((-62, 2.1, 0.52), (62, 1.45, 0.5), (185, 1.6, 0.5), (130, 3.0, 0.46),
                                    (290, 2.8, 0.48))):
        c = E.on(a, y, 0.0)
        gem_fruit(k, "Fruit%d" % (i + 1), c.p + c.vec((0, 0, -1)) * (sz * 0.55 + 0.1), sz, stem=0.12)
    # the gold hexagon crest with the glowing tree on the front
    c = E.on(0, 2.2, 0.06)
    _hex(k, "Crest", c, 1.45, frame="gold")
    _hex(k, "CrestField", c * CF((0, 0, -0.04)), 1.15, frame="gold2")
    _tree_emblem(k, "CrestTree", c, z=-0.2)
    # a crown of branches on top with leaves and a gem fruit
    top = Vector((0, E.h - 0.1, 0))
    for sx, sd in A.SIDES:
        pts = A.branch(k, "Crown" + sd, top + Vector((sx * 0.2, 0, 0)), (((sx * 0.55, 1, 0.1), 0.65),
                                                                         ((sx * 1, 0.45, -0.1), 0.6),
                                                                         ((sx * 0.3, 1, 0), 0.35)), "bark", w0=0.26)
        for j, (p, d) in enumerate(((pts[2], (sx, 0.6, -0.3)), (pts[3], (sx * 0.2, 1, 0.2)), (pts[1], (-sx * 0.2, 1, 0.5)))):
            A.leaf(k, "CrownLeaf%s%d" % (sd, j + 1), p, d, 0.6, 0.36, ("leaf2", "leaf3")[j % 2], thick=0.1,
                   normal=(0, 1, 0))
    gem_fruit(k, "CrownFruit", top + Vector((0, 0.75, 0)), 0.6, stem=0.15)
    return E


def first_seed(k):
    from zone1.first_seed import glowleaf, leaf_glyph

    def diamond(name, c, w, h, z, col, thick=0.14, mat="SmoothPlastic"):
        """An upright leaf-diamond on a shell frame c (local -Z out)."""
        a, b = c.point((-w / 2, 0, z)), c.point((w / 2, 0, z))
        k.tri(name + "Top", a, b, c.point((0, h / 2, z)), thick, col, material=mat)
        k.tri(name + "Bottom", a, b, c.point((0, -h / 2, z)), thick, col, material=mat)

    E = EG.Egg(k, 4.6, 3.4)
    E.shell(lambda i, n: "bark" if i % 2 else "bark2")
    EG.rarity(E, "Secret", y=0.85, th=0.2, out=0.08)
    EG.band(E, "GoldBase", y=0.5, th=0.18, out=0.1, col="gold")
    # gold-rimmed ivory leaf plates in two rings (the outer layer that opens first), each with a gold leaf glyph
    n = 0
    for y, angles, (w, h) in ((1.75, (-48, 48, 100, 150, 210, 260), (0.8, 1.25)),
                              (3.2, (-28, 28, 90, 180, 270), (0.62, 1.0))):
        for a in angles:
            n += 1
            c = E.on(a, y, 0.02)
            diamond("PlateGold%d" % n, c, w + 0.16, h + 0.22, -0.04, "gold")
            diamond("PlateIvory%d" % n, c, w, h, -0.1, "ivory")
            leaf_glyph(k, "PlateGlyph%d" % n, c * cf(ry=180) * CF((0, -0.05, 0.12)), h * 0.42)
    # the green seed core at the front: a gold rim, a glowing leaf-diamond, a bright facet and a vein
    c = E.on(0, 2.3, 0.04)
    diamond("CoreRim", c, 1.45, 2.15, -0.04, "gold")
    diamond("CoreGlow", c, 1.15, 1.8, -0.1, "core", mat="Neon")
    diamond("CoreFacet", c, 0.55, 0.95, -0.16, "core2", mat="Neon")
    k.p("CoreVein", (0.06, 1.35, 0.06), c * CF((0, 0, -0.22)), "core2", material="Neon", studs=False)
    # glowing sprouts on top and an orbiting green ring
    top = Vector((0, E.h - 0.1, 0))
    for i, (d, ln) in enumerate((((-0.7, 1, 0.1), 0.8), ((0.75, 1, -0.15), 0.85), ((0.1, 1, 0.6), 0.7))):
        pts = A.branch(k, "Sprout%d" % (i + 1), top, ((d, ln), ((d[0] * 1.3, 0.6, d[2]), 0.45)), "bark", w0=0.22)
        glowleaf(k, "SproutLeaf%dA" % (i + 1), pts[2], (d[0], 1, d[2]), 0.62, 0.36, normal=(0, 0, -1))
        glowleaf(k, "SproutLeaf%dB" % (i + 1), pts[1], (-d[0] * 0.6, 0.8, 0.5), 0.5, 0.3, normal=(0, 0, -1))
    T.ring(k, "Orbit", (0, 2.1, 0), (0.12, 1, 0.08), 2.55, 28, 0.06, 0.1, "vein", mat="Neon", studs=False)
    return E


BUILD = {"Piproot": piproot, "HoneybackBeetle": honeyback_beetle, "Crownstag": crownstag,
         "ThistlebackHedgehog": thistleback_hedgehog, "BloomcrestCrane": bloomcrest_crane,
         "BurrowMonarch": burrow_monarch, "WalkingOrchard": walking_orchard, "FirstSeed": first_seed}


def build(key, name, offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PALS[key]))
    coll = use(name, offset)
    J("Body")
    BUILD[key](k)
    J("Root")
    return coll
