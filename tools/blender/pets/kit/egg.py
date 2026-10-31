# Eggs: the classic stepped shell (identical to Sculpt.eggShell: `Shell<n>` layers, joint Body so the chase legs
# sprout under it) plus decorations named in the pair's data: egg=dict(h, w, paint, deco=[(kind, {...}), ...]).
# Keep the shell <= 4.2 wide and <= 6 tall; decorations may float beyond it (they never widen the collider).
import math

from mathutils import Vector

from . import anatomy as A
from .rbx import CF, J, cf, frame, look, rot_r

EGG_STEP = 0.55
RARITY = dict(Common="BEBEBE", Uncommon="55DC5F", Rare="3C96FF", Epic="AA55FF", Legendary="FFC328",
              Mythic="FF3C50", Divine="FFFAC8", Secret="FFFFFF")


def egg_layers(h):
    return max(7, int(math.floor(h / EGG_STEP + 0.5)))


def egg_profile(h, w, y):
    t = min(1, max(-1, (y / h) * 2 - 1))
    r = math.sqrt(max(0, 1 - t * t)) * (1 - 0.14 * t)
    return w / 2 * r / 1.03


def egg_radius(h, w, y):
    n = egg_layers(h)
    dh = h / n
    i = min(n, max(1, int(math.floor(y / dh)) + 1))
    return max(egg_profile(h, w, (i - 0.5) * dh), 0.3)


def squircle(r, th, n=6):
    c, s = abs(math.cos(th)), abs(math.sin(th))
    return r / (c ** n + s ** n) ** (1 / n)


class Egg:
    def __init__(self, k, h, w):
        self.k, self.h, self.w = k, h, w
        self.n = egg_layers(h)
        self.dh = h / self.n

    def r(self, y):
        return egg_radius(self.h, self.w, y)

    def layer_y(self, i):
        return (i - 0.5) * self.dh

    def on(self, a, y, lift=0.0):
        """Sculpt.onEgg: frame on the square face the angle points at (0 = front -Z, 90 = right +X), facing out."""
        r = self.r(y)
        face = math.floor((a + 45) / 90) * 90
        th = math.radians(face)
        along = max(-r + 0.2, min(r - 0.2, math.tan(math.radians(a - face)) * r))
        normal = Vector((math.sin(th), 0, -math.cos(th)))
        tangent = Vector((math.cos(th), 0, math.sin(th)))
        pos = normal * (r + lift) + tangent * along + Vector((0, y, 0))
        return CF(pos, rot_r(0, -face, 0))

    def shell(self, paint):
        for i in range(1, self.n + 1):
            y = self.layer_y(i)
            r = self.r(y)
            self.k.p("Shell%d" % i, (r * 2, self.dh, r * 2), CF((0, y, 0)), paint(i, self.n))


def _paint(spec, n):
    """[(from, to, colour)] with negative indices counting from the top (-1 = top layer)."""

    def f(i, n_):
        col = spec[0][2]
        for a, b, c in spec:
            a = a if a > 0 else n_ + 1 + a
            b = b if b > 0 else n_ + 1 + b
            if a <= i <= b:
                col = c
        return col

    return f


# ---- decorations ---------------------------------------------------------------------------------------------
def band(E, name="Band", y=1.0, th=0.3, out=0.07, col="dark", material="SmoothPlastic", **kw):
    r = E.r(y + 0.01) + out
    E.k.p(name, (r * 2, th, r * 2), CF((0, y, 0)), col, material=material, **kw)


def rarity(E, rarity="Rare", y=1.2, th=0.2, out=0.08):
    band(E, "RarityBand", y, th, out, RARITY[rarity], material="Neon")


def plates(E, name="Spot", at=(), size=(0.4, 0.36, 0.14), col="light", rz=0):
    """Flat plates flush on the faces: at = [(angle, y)] or [(angle, y, (w, h))]."""
    for i, a in enumerate(at):
        sz = (a[2][0], a[2][1], size[2]) if len(a) > 2 else size
        E.k.p("%s%d" % (name, i + 1), sz, E.on(a[0], a[1], sz[2] / 2 - 0.08) * cf(rz=rz), col, studs=False)


def drips(E, name="Drip", y=3.0, lengths=(0.5, 0.9, 0.45), col="light", w=0.42, per_face=3, spread=0.95,
          material="SmoothPlastic", point=False, drop=None):
    """A cap edge running down the shell in chunky drips (FS frost cap). point=True ends each in a diamond tip
    (pinked leaf edge); drop = ball size ends each in a round drop (honey)."""
    r_out = max(E.r(y - 0.1), E.r(y - E.dh - 0.1)) + 0.05
    k_ = 0
    for f in range(4):
        th = math.radians(f * 90)
        nrm = Vector((math.sin(th), 0, -math.cos(th)))
        tan = Vector((math.cos(th), 0, math.sin(th)))
        for j in range(per_face):
            along = (j - (per_face - 1) / 2) * spread
            ln = lengths[k_ % len(lengths)]
            k_ += 1
            if point:  # leaf point: a diamond hanging off the edge
                pos = nrm * r_out + tan * along + Vector((0, y - ln * 0.3, 0))
                c = frame(pos, tan, Vector((0, 1, 0)), -nrm) * cf(rz=45)
                E.k.p("%s%d" % (name, k_), (ln, ln, 0.14), c, col, studs=False, material=material)
            else:
                pos = nrm * r_out + tan * along + Vector((0, y + 0.12 - ln / 2, 0))
                E.k.p("%s%d" % (name, k_), (w, ln + 0.24, 0.14), frame(pos, tan, Vector((0, 1, 0)), -nrm), col,
                      studs=False, material=material)
                if drop:
                    bp = nrm * (r_out + 0.03) + tan * along + Vector((0, y - ln, 0))
                    E.k.p("%sDrop%d" % (name, k_), (drop, drop, drop), CF(bp), col, shape="Ball", material=material)


def ring(E, name="Trim", y=2.0, per_side=2, size=(0.4, 0.4, 0.16), col="dark", turn=(0, 0, 45), material=None):
    """Sculpt.eggRing: per_side parts on each face at height y (pinked trims, hex plates, fur tufts)."""
    r = E.r(y)
    i = 0
    for f in range(4):
        th = math.radians(f * 90)
        nrm = Vector((math.sin(th), 0, -math.cos(th)))
        tan = Vector((math.cos(th), 0, math.sin(th)))
        for j in range(per_side):
            along = (j + 1 - (per_side + 1) / 2) * (2 * r / per_side)
            c = CF(nrm * (r + size[2] / 2 - 0.06) + tan * along + Vector((0, y, 0)), rot_r(0, -f * 90, 0))
            c = c * cf((0, 0, 0), *turn)
            i += 1
            kw = {"material": material} if material else {}
            E.k.p("%s%d" % (name, i), size, c, col, studs=False, **kw)


def sprout(E, stem=0.5, leaf=0.62, w=0.34, col="light", stem_col="dark"):
    top = E.h
    E.k.seg("Stem", (0, top - 0.15, 0), (0, top + stem, 0), 0.16, 0.16, stem_col)
    for sx, sd in A.SIDES:
        d = Vector((sx * 0.85, 0.55, 0)).normalized()
        A.leaf(E.k, "Sprout" + sd, Vector((0, top + stem - 0.05, 0)), d, leaf, w, col, thick=0.12, normal=(0, 0, -1),
               tip=False)


def nubs(E, beams=(((0.4, 0.85, 0.2), 0.6),), base=(0.5, -0.3, 0.0), col="dark", w0=0.2, taper=0.75,
         tines=(), blooms=(), bloom_size=0.34, name="Nub"):
    """Small antlers / horns on the egg's top, mirrored (`beams` per side, x mirrored)."""
    for sx, sd in A.SIDES:
        b0 = Vector((sx * base[0], E.h + base[1], base[2]))
        pts = A.branch(E.k, name + sd, b0, [(Vector((sx * d[0], d[1], d[2])), ln) for d, ln in beams], col, w0=w0,
                       taper=taper)
        ends = {"b": (pts[-1], (pts[-1] - pts[-2]).normalized())}
        for i, (j, d, ln) in enumerate(tines):
            dd = Vector((sx * d[0], d[1], d[2])).normalized()
            E.k.seg("%sTine%s%d" % (name, sd, i + 1), pts[j], pts[j] + dd * ln, w0 * 0.7, w0 * 0.7, col)
            ends[i + 1] = (pts[j] + dd * ln, dd)
        for i, key in enumerate(blooms):
            p, dd = ends[key]
            A.blossom(E.k, "%sBloom%s%d" % (name, sd, i + 1), p + dd * 0.04, dd, bloom_size)


def antennae(E, x=0.3, len=0.7, lean=22, tip=0.3, col="ink", tip_col="ink"):
    for sx, sd in A.SIDES:
        p0 = Vector((sx * x, E.h - 0.15, 0))
        d = Vector((sx * math.sin(math.radians(lean)), math.cos(math.radians(lean)), 0))
        p1 = p0 + d * len
        E.k.seg("Antenna" + sd, p0, p1, 0.1, 0.1, col)
        E.k.p("AntTip" + sd, (tip, tip, tip), CF(p1), tip_col, shape="Ball")


def wingnubs(E, y=2.4, size=(0.1, 1.0, 1.3), col="glass", tilt=15, back=0.35, transp=0.35, vein=None, out=0.12):
    """Glass wing panes standing off the egg's sides."""
    for sx, sd in A.SIDES:
        r = E.r(y)
        c = CF((sx * (r + out), y, back)) * cf(rz=-sx * tilt)
        E.k.p("Wing" + sd, size, c, col, material="Glass", transp=transp)
        if vein:
            E.k.p("WingVein" + sd, (0.12, size[1] * 0.9, 0.08), c * CF((sx * 0.02, 0, -size[2] * 0.42)), vein,
                  studs=False)


def hexband(E, y=2.0, per_side=3, size=0.42, col="wax", rim=None, material=None):
    """Honeycomb band: hexagon-ish cells (a block crossed by a 60-degree twin) round every face."""
    ring(E, "Comb", y, per_side, (size, size * 0.58, 0.14), col, turn=(0, 0, 0), material=material)
    ring(E, "CombX", y, per_side, (size, size * 0.58, 0.13), col, turn=(0, 0, 60), material=material)
    if rim:
        band(E, "CombRim", y - size * 0.62, 0.12, 0.05, rim)


def paw(E, name="Paw", a=-30, y=0.8, col="dark", s=1.0):
    plates(E, name + "Pad", [(a, y, (0.62 * s, 0.5 * s))], col=col)
    plates(E, name + "Toe", [(a - 13, y + 0.45 * s, (0.2 * s, 0.22 * s)), (a, y + 0.52 * s, (0.2 * s, 0.22 * s)),
                             (a + 13, y + 0.45 * s, (0.2 * s, 0.22 * s))], col=col)


def crown(E, length=0.9, width=0.3, n=3, tilt=(0, 1, -0.1)):
    E.k.crystal("Crown", Vector((0, E.h - 0.08, 0)), Vector(tilt), length, width, n=n)


def blooms(E, y=3.0, angles=(), size=0.36, lift=0.1):
    for i, a in enumerate(angles):
        c = E.on(a, y, lift)
        A.blossom(E.k, "Bloom%d" % (i + 1), c.p, c.vec((0, 0, -1)), size)


DECO = dict(band=band, rarity=rarity, plates=plates, drips=drips, ring=ring, sprout=sprout, nubs=nubs,
            antennae=antennae, wingnubs=wingnubs, hexband=hexband, paw=paw, crown=crown, blooms=blooms)


def build_egg(k, d, rarity_name):
    J("Body")
    E = Egg(k, d["h"], d["w"])
    E.shell(_paint(d["paint"], E.n))
    for kind, params in d.get("deco", ()):
        J("Body")
        if kind == "rarity":
            params = dict(params, rarity=rarity_name)
        DECO[kind](E, **params)
    J("Root")
    return E
