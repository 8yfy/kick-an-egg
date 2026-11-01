# V3 matching eggs, Roblox primitives only (the Frost Serpent egg method): the classic stepped shell (Shell<n> layers
# identical to Sculpt.eggShell, joint Body, so the chase hitbox and the sprouted legs work unchanged) plus motifs
# taken from the pet without turning the egg into a mini pet. Shells stay within 4.2 wide and 6 tall.
#   SproutPup  (Common): cream base, clover-green cap, a clover heart on every face, a four-leaf clover on top.
#   MeadowStag (Rare):   fawn with cream dapples, a moss band in bloom, a bark branch climbing the shell, velvet
#                        antler nubs, the Rare band.
#   TideSpirit (Epic):   deep blue to turquoise, a scallop shell on the front, coral up both sides, little claw nubs,
#                        a glass wave fin on the back, a pearl in a shell cup on top, foam at the base, the Epic band.
#   HeavenLion (Divine): white and gold, rhombus scale bands, star medallions in diamond frames on every face, a crown
#                        of white and gold rays, the Divine band, a halo arc with a star (to the user's reference).
#   ClockworkTitan (Divine): iron and brass, a glowing amber clock ringed by teeth and small gears, a red banner with a
#                        gear emblem, amber vents, a crown of spires, a clock on the back, the Divine band.
#   PrismSeraph (Secret): pearl and gold, a band of prism crystals between gold bands, a glowing star, a crown of
#                        prisms, the Secret band, a halo arc with stars and orbiting prism shards (Orbit).
import math

from mathutils import Vector

from kit import anatomy as A
from kit import egg as EG
from kit.rbx import CF, J, cf, look, use
from v3 import top_parts as T

RAINBOW_LIST = ("FF6B6B", "FFA35C", "FFE45C", "7BEA7B", "5CD8FF", "6F86FF", "B77BFF")
PALS = {
    "SproutPup": dict(main="4CBF4A", dark="2E8B3A", light="FFF0D0", glow="72F25A", crown="6FD66A"),
    "MeadowStag": dict(main="C08A55", dark="4E3424", light="F6E6C8", moss="5FA544", glow="9CFF7A", velvet="E9D3B0",
                       blossom="FFF6EC", cap="E8664F"),
    "HeavenLion": dict(main="F6F2E8", main2="E8E1CF", light="FFFFFF", dark="C9932E", glow="FFD966", gold="E2B04A",
                       glass="FFE9A6", tip="FFF7D6"),
    "ClockworkTitan": dict(main="C9A24E", main2="A8823A", dark="34302D", light="F3D98C", glow="FFB84A", face="F1E2B6",
                           red="8E2B2B", ink="1A1614", glass="FFD99A", tip="FFF1C8"),
    "PrismSeraph": dict(main="F5F3FA", main2="DCD8E6", dark="E0B24E", light="FFFFFF", glow="FFE38A", glass="E2D6FF",
                        tip="FFFFFF"),
    "TideSpirit": dict(main="1F78D6", dark="0F4C9C", light="F3E2B8", turq="25C6C4", coral="FF7F6B", glow="5CF2FF",
                       pearl="F2FBFF", glass="9FF0FF", tip="E6FDFF", star="FFB347"),
}


def _heart(k, E, name, a, y, size, col, lift=0.05):
    """A clover heart flush on the face at angle a: two diamond lobes side by side."""
    base = E.on(a, y, lift)
    for j, s in enumerate((-1, 1)):
        k.p("%s%d" % (name, j + 1), (size, size, 0.12), base * CF((s * size * 0.36, 0, 0)) * cf(rz=45),
            col if j == 0 else "dark", studs=False)


def build(key, name, offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PALS[key]))
    coll = use(name, offset)
    J("Body")
    if key == "SproutPup":
        E = EG.Egg(k, 3.9, 3.0)
        E.shell(lambda i, n: "light" if i <= 3 else ("crown" if i == n else "main"))
        for f in range(1, 4):  # a clover heart on three faces, the paw print on the front
            _heart(k, E, "Heart%d" % f, f * 90, 2.05, 0.58, "main")
        for i in range(8):  # pinked leaf rim where the green cap meets the cream
            c = E.on(i * 45 + 22.5, 3 * E.dh - 0.05, 0.05)
            k.p("Rim%d" % (i + 1), (0.34, 0.34, 0.12), c * cf(rz=45), "dark" if i % 2 else "main", studs=False)
        EG.paw(E, "Paw", a=0, y=0.72, col="dark", s=0.95)
        top = Vector((0, E.h, 0))
        stem1 = top + Vector((0, 0.45, 0.08))
        k.seg("CloverStem", top - Vector((0, 0.15, 0)), stem1, 0.14, 0.14, "dark")
        for i, (a, b) in enumerate(((1, 0), (0, 1), (-1, 0), (0, -1))):
            out = Vector((a, 0, b))
            c = look(stem1 + Vector((0, 0.06, 0)) + out * 0.34, (Vector((0, 0.97, 0)) - out * 0.22).normalized(), out)
            k.p("Clover%d" % (i + 1), (0.4, 0.1, 0.4), c * cf(ry=45), "dark")
        k.p("LuckyGem", (0.16, 0.16, 0.16), CF(stem1 + Vector((0, 0.12, 0))) * cf(rx=45, ry=45), "glow",
            material="Neon")
    elif key == "MeadowStag":
        E = EG.Egg(k, 4.2, 3.2)
        E.shell(lambda i, n: "dark" if i == 1 else "main")
        EG.rarity(E, "Rare", y=1.2, th=0.2, out=0.08)
        EG.band(E, "MossBand", y=3.05, th=0.34, out=0.08, col="moss")
        EG.blooms(E, y=3.05, angles=(-25, 155), size=0.46, lift=0.14)
        EG.plates(E, "Dapple", ((-30, 2.15), (40, 2.5), (105, 1.95), (190, 2.35), (250, 2.0), (318, 2.45)),
                  size=(0.4, 0.34, 0.14), col="light")
        for bi, path in enumerate((((22, 0.8), (14, 1.5), (30, 2.2), (18, 2.95)),
                                   ((200, 0.9), (212, 1.65), (196, 2.35), (205, 2.95)))):
            pts = [E.on(a, y, 0.06).p for a, y in path]
            for i in range(3):  # bark branches climbing the shell into the moss
                k.seg("Branch%d%d" % (bi + 1, i + 1), pts[i], pts[i + 1], 0.17 - 0.03 * i, 0.17 - 0.03 * i, "dark")
        EG.blooms(E, y=3.05, angles=(70,), size=0.36, lift=0.14)
        for i, a in enumerate((120, 300)):  # little mushrooms at the base
            c = E.on(a, 0.55, 0.18)
            k.p("Stem%d" % (i + 1), (0.1, 0.3, 0.1), c * CF((0, 0.0, 0)), "light", studs=False)
            k.p("Cap%d" % (i + 1), (0.32, 0.13, 0.32), c * CF((0, 0.18, 0)) * cf(ry=45), "cap", studs=False)
        for sx, sd in A.SIDES:  # velvet-tipped antler nubs
            b0 = Vector((sx * 0.5, E.h - 0.32, 0))
            b1 = b0 + Vector((sx * 0.32, 0.5, 0.06))
            b2 = b1 + Vector((sx * 0.22, 0.32, -0.08))
            k.seg("Nub%s1" % sd, b0, b1, 0.2, 0.2, "dark")
            k.seg("Nub%s2" % sd, b1, b2, 0.15, 0.15, "velvet")
            k.seg("Nub%sTine" % sd, b1, b1 + Vector((-sx * 0.05, 0.3, 0.2)), 0.12, 0.12, "velvet")
        k.p("MossTuft", (0.7, 0.22, 0.7), CF(Vector((0, E.h + 0.05, 0))) * cf(ry=45), "moss")
    elif key == "HeavenLion":
        E = EG.Egg(k, 4.6, 3.4)
        E.shell(lambda i, n: "gold" if i in (1, n) else ("main2" if i == n - 1 else "main"))
        EG.rarity(E, "Divine", y=0.85, th=0.2, out=0.08)
        EG.ring(E, "Scale", y=3.05, per_side=3, size=(0.46, 0.46, 0.14), col="gold", turn=(0, 0, 45))  # rhombus band
        for f in range(4):  # star medallions in diamond frames on every face
            c = E.on(f * 90, 1.95, 0.08)
            T.diamond_frame(k, "Frame%d" % (f + 1), c.p, c.vec((0, 0, -1)), 0.62, "gold", bar=0.14)
            T.star4(k, "Star%d" % (f + 1), c.point((0, 0, -0.04)), c.vec((0, 0, -1)), 0.55, "glow", core="light")
        top_y = E.h - 0.3
        r = E.r(top_y)
        for i in range(8):  # a crown of white and gold rays
            a = 2 * math.pi * i / 8 + math.pi / 8
            radial = Vector((math.cos(a), 0, math.sin(a)))
            d = (radial * 0.75 + Vector((0, 0.66, 0))).normalized()
            ln = 1.15 if i % 2 == 0 else 0.85
            base = Vector((0, top_y, 0)) + radial * r * 0.95
            k.p("Ray%d" % (i + 1), (0.36, ln, 0.16), look(base + d * ln / 2, d, radial), "gold" if i % 2 == 0 else
                "main", studs=False)
        hc = Vector((0, E.h + 0.35, 0.4))
        for i in range(13):  # a halo arc behind the top with a star
            a = math.radians(-20 + i * (220 / 12))
            p = hc + Vector((math.cos(a), math.sin(a), 0)) * 1.35
            k.p("Arc%d" % (i + 1), (0.36, 0.12, 0.14), look(p, Vector((0, 0, 1)), Vector((math.cos(a), math.sin(a), 0)))
                * cf(ry=90), "glow" if i % 2 else "gold", material="Neon" if i % 2 else "SmoothPlastic", studs=False)
        T.star4(k, "ArcStar", hc + Vector((0, 1.5, -0.05)), (0, 0, -1), 0.42, "glow", core="light")
    elif key == "ClockworkTitan":
        from v3.clockwork_titan import cyl

        E = EG.Egg(k, 4.8, 3.5)
        E.shell(lambda i, n: "dark" if i in (1, n - 1) else ("main2" if i in (2, n) else "main"))
        EG.rarity(E, "Divine", y=0.95, th=0.2, out=0.08)
        EG.ring(E, "Rivet", y=1.45, per_side=3, size=(0.14, 0.14, 0.12), col="light", turn=(0, 0, 0))
        cc = E.on(0, 2.55, 0.1)
        n = cc.vec((0, 0, -1))
        T.clock(k, "Clock", cc.p, n, 0.68, "glow", "main", "ink", "ink", glow=True, rim_n=14, hands=(-40, 70))
        T.teeth(k, "ClockTooth", cc.p, n, 0.76, 12, (0.16, 0.14, 0.16), "main2")
        for i, (dx, dy, r) in enumerate(((-0.95, 0.85, 0.24), (0.95, 0.85, 0.24), (-0.95, -0.75, 0.2),
                                          (0.95, -0.75, 0.2))):
            T.small_gear(k, "Gear%d" % (i + 1), cc.point((dx, dy, -0.04)), n, r, "main", "main2")
        bc = E.on(90, 3.1, max(E.r(y / 10) for y in range(16, 32)) - E.r(3.1) + 0.1)  # hang clear of the bulge
        T.banner(k, "Banner", bc.p, bc.vec((0, 0, -1)), 0.62, 1.5, "red", "main", emblem=True)
        vc = E.on(270, 2.2, 0.06)
        for i in range(3):  # amber vents on the left face
            k.p("Vent%d" % (i + 1), (0.1, 0.62, 0.06), vc * CF(((i - 1) * 0.22, 0, -0.03)), "glow", material="Neon",
                studs=False)
        for i, (x, z, h) in enumerate(((0, 0, 0.95), (-0.45, 0.2, 0.62), (0.45, 0.2, 0.62), (-0.3, -0.35, 0.5),
                                       (0.3, -0.35, 0.5))):
            T.spire(k, "Spire%d" % (i + 1), (x, E.h - 0.12, z), h, 0.24 if i else 0.3, "main", "light")
        gc = E.on(180, 2.4, 0.08)
        T.clock(k, "BackClock", gc.p, gc.vec((0, 0, -1)), 0.45, "face", "main", "ink", "ink", rim_n=10)
    elif key == "PrismSeraph":
        prisms = ("FF8FCB", "8FC8FF", "FFE57A", "B59BFF", "7FF0CF", "FFB88A")
        E = EG.Egg(k, 4.8, 3.4)
        E.shell(lambda i, n: "main" if i % 2 else "main2")
        EG.rarity(E, "Secret", y=0.9, th=0.2, out=0.08)
        EG.band(E, "GoldBandHigh", y=2.95, th=0.16, out=0.09, col="dark")
        EG.band(E, "GoldBandLow", y=1.6, th=0.16, out=0.09, col="dark")
        for i in range(12):  # a band of prism crystals standing out of the shell
            a = i * 30 + 15
            c = E.on(a, 2.28, 0.05)
            out = c.vec((0, 0, -1))
            k.crystal("BandPrism%d" % (i + 1), c.p, (out * 0.55 + Vector((0, 0.85, 0))).normalized(), 0.85, 0.3, n=2,
                      body=prisms[i % 6], tip=prisms[i % 6])
        sc = E.on(0, 3.6, 0.1)
        T.star4(k, "Star", sc.p, sc.vec((0, 0, -1)), 0.62, "glow", core="light")
        for i, (x, z, ln) in enumerate(((0, 0, 1.5), (0.4, 0.12, 0.95), (-0.4, 0.12, 0.95), (0.22, -0.34, 0.85),
                                        (-0.22, -0.34, 0.85))):
            k.crystal("CrownPrism%d" % (i + 1), (x, E.h - 0.1, z), (x * 0.5, 1, z * 0.3), ln, 0.34, n=2,
                      body=prisms[(i * 2) % 6], tip=prisms[(i * 2) % 6])
        hc = Vector((0, E.h + 0.45, 0.45))
        for i in range(13):  # a halo arc with three stars
            a = math.radians(-20 + i * (220 / 12))
            p = hc + Vector((math.cos(a), math.sin(a), 0)) * 1.4
            k.p("Arc%d" % (i + 1), (0.38, 0.12, 0.14), look(p, Vector((0, 0, 1)), Vector((math.cos(a), math.sin(a), 0)))
                * cf(ry=90), "dark" if i % 2 else "glow", material="SmoothPlastic" if i % 2 else "Neon", studs=False)
        for i, a in enumerate((90, 160, 20)):
            r_ = math.radians(a)
            T.star4(k, "ArcStar%d" % (i + 1), hc + Vector((math.cos(r_), math.sin(r_), 0)) * 1.4 + Vector((0, 0, -0.05)),
                    (0, 0, -1), 0.42 if a == 90 else 0.3, "dark", core="light", mat="SmoothPlastic")
        oc = Vector((0, 2.6, 0))
        T.hub(k, "Orbit", oc, (0, 1, 0))
        for i in range(4):
            a = 2 * math.pi * i / 4 + 0.4
            p = oc + Vector((math.cos(a) * 2.7, 0.4 * math.sin(2 * a), math.sin(a) * 2.7))
            k.crystal("Shard%d" % (i + 1), p, (0, -1, 0), 0.8, 0.3, n=2, body=prisms[(i * 2 + 1) % 6],
                      tip=prisms[(i * 2 + 1) % 6])
    else:  # TideSpirit / Reef Crab Knight
        E = EG.Egg(k, 4.5, 3.4)
        E.shell(lambda i, n: "dark" if i <= 2 else ("turq" if i >= n - 1 else "main"))
        EG.rarity(E, "Epic", y=1.1, th=0.2, out=0.08)
        EG.ring(E, "Foam", y=0.36, per_side=3, size=(0.46, 0.3, 0.22), col="pearl", turn=(0, 0, 0))
        for i, (a, y, sz) in enumerate(((-40, 1.5, 0.3), (-55, 1.75, 0.22), (150, 1.3, 0.28), (230, 2.6, 0.24))):
            k.p("Barnacle%d" % (i + 1), (0.2, sz, sz), E.on(a, y, 0.08) * cf(ry=90), "pearl", shape="Cylinder",
                studs=False)
        from v3.reef_crab import starfish
        c = E.on(130, 3.1, 0.06)
        starfish(k, "Star", c.p, c.vec((0, 0, -1)), 0.55, "star")
        base = E.on(0, 2.35, 0.08)  # scallop shell on the front: five ribs fanning up
        for i, a in enumerate((-44, -22, 0, 22, 44)):
            k.p("Scallop%d" % (i + 1), (0.24, 0.72, 0.14), base * cf(rz=a) * CF((0, 0.3, 0)),
                "coral" if i % 2 else "pearl", studs=False)
        for sx, sd in A.SIDES:  # coral growing up both sides, little claw nubs
            p0, p1, p2 = (E.on(sx * 90 + sx * 25, y, 0.08).p for y in (1.4, 2.25, 3.0))
            k.seg("Coral%s1" % sd, p0, p1, 0.2, 0.2, "coral")
            k.seg("Coral%s2" % sd, p1, p2, 0.15, 0.15, "coral")
            k.seg("Coral%s3" % sd, p1, p1 + Vector((sx * 0.45, 0.35, 0.1)), 0.12, 0.12, "coral")
            c = E.on(sx * 90 - sx * 20, 2.0, 0.22)
            k.p("ClawNub%s1" % sd, (0.34, 0.26, 0.42), c * cf(rx=-15), "main", shape="Wedge", studs=False)
            k.p("ClawNub%s2" % sd, (0.3, 0.22, 0.36), c * CF((0, -0.24, 0)) * cf(rz=180, rx=15), "coral",
                shape="Wedge", studs=False)
        for i, (dx, h) in enumerate(((-0.35, 0.8), (0.0, 1.05), (0.35, 0.7))):  # glass wave fin on the back
            c = E.on(180, 2.6, 0.05)
            k.crystal("Fin%d" % (i + 1), c.point((dx, 0, 0)), c.vec((dx * 0.4, 0.8, 0.6)), h, 0.3, n=2)
        top = E.h
        for i in range(6):  # shell cup and pearl on top
            a = 2 * math.pi * i / 6
            k.p("Cup%d" % (i + 1), (0.26, 0.22, 0.14), CF(Vector((math.cos(a) * 0.3, top + 0.02, math.sin(a) * 0.3)))
                * cf(ry=-math.degrees(a) + 90, rx=-30), "pearl", studs=False)
        k.p("Pearl", (0.46, 0.46, 0.46), CF(Vector((0, top + 0.22, 0))), "pearl", shape="Ball", material="Neon")
    J("Root")
    return coll
