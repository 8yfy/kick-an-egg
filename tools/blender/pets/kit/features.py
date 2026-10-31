# Signature features added on top of a body plan, named in each pet's data entry:
#   features=[("ears", {...}), ("antlers", {...}), ...]. Head features use the head frame (local coords: x right,
#   y up, front -z); body features attach to the spine segments (s = arc fraction, 0 = rump/tail end).
import math

from mathutils import Vector

from . import anatomy as A
from .rbx import CF, J, cf, frame, look


def ears(k, ctx, kind="leaf", at=(0.9, 0.6, 0.0), dir=(0.8, 0.5, 0.2), len=1.2, w=0.7, thick=0.16, col="dark",
         inner=None, droop=None, normals=None, tip=True):
    """Pair of ears on the head. kind: leaf (pointed leaf blade), floppy (hangs; `droop` = per-side directions,
    e.g. one flipped up and one hanging, `normals` = per-side blade facings), pointed (wedge), round (block)."""
    J("Head")
    H = ctx["head"]
    for sx, sd in A.SIDES:
        base = H.pt((sx * at[0], at[1], at[2]))
        dd = droop[0 if sx < 0 else 1] if droop else dir
        d = H.vec((sx * dd[0], dd[1], dd[2])).normalized()
        nv = normals[0 if sx < 0 else 1] if normals else (0, 0, -1)
        nrm = H.vec((sx * nv[0], nv[1], nv[2]))
        if kind in ("leaf", "floppy"):
            A.leaf(k, "Ear" + sd, base, d, len, w, col, thick=thick, normal=nrm, tip=tip)
            if inner:
                c = look(base + d * len * 0.42, d, nrm) * CF((0, 0, -thick * 0.5 - 0.02))
                k.p("EarIn" + sd, (w * 0.5, len * 0.6, 0.05), c, inner, studs=False)
        elif kind == "pointed":
            c = look(base + d * len / 2, d, nrm)
            k.p("Ear" + sd, (w, len, thick), c, col, shape="Wedge")
            if inner:
                k.p("EarIn" + sd, (w * 0.55, len * 0.6, 0.05), c * CF((0, -len * 0.12, -thick / 2 - 0.02)), inner,
                    shape="Wedge")
        else:
            c = look(base + d * len / 2, d, nrm)
            k.p("Ear" + sd, (w, len, thick), c, col)
            if inner:
                k.p("EarIn" + sd, (w * 0.6, len * 0.6, 0.05), c * CF((0, 0, -thick / 2 - 0.02)), inner, studs=False)


def sprout(k, ctx, at=(0, 1.0, 0), stem=0.55, leaf=0.75, w=0.4, col="light", stem_col="dark", lean=8, tips=False):
    """Seedling on the head: a stem and two leaves opening sideways (the Sprout Pup's crown)."""
    J("Head")
    H = ctx["head"]
    p0 = H.pt(at)
    up = H.vec((math.sin(math.radians(lean)), 1, 0)).normalized()
    p1 = p0 + up * stem
    k.seg("Stem", p0 - up * 0.1, p1, 0.16, 0.16, stem_col)
    for sx, sd in A.SIDES:
        d = (up * 0.55 + H.vec((sx, 0, 0)) * 0.85).normalized()
        A.leaf(k, "Sprout" + sd, p1 - up * 0.05, d, leaf, w, col, thick=0.12, normal=up.cross(H.vec((0, 0, 1))),
               tip=tips)


def collar(k, ctx, s=0.9, col="dark", gem="glow", drop=0.0, size=None):
    """Collar band round the chest end of the body with a Neon gem pendant (diamond)."""
    J("Body")
    g = A.seg_at(ctx["body"], s)
    w, t = g["w"], g["t"]
    c = g["f"] * CF((0, 0, -g["len"] * 0.45))
    k.p("Collar", size or (w * 1.04, t * 1.04, 0.26), c, col, studs=False)
    if gem:
        f = g["f"] * CF((0, -t * 0.18 - drop, -g["len"] * 0.45 - 0.17))
        k.p("Pendant", (0.34, 0.34, 0.1), f * cf(rz=45), gem, material="Neon")


def mantle(k, ctx, s0=0.45, s1=1.0, col="moss", blossoms=(), over=0.06, wf=1.06, bloom=0.42, th=0.2):
    """Moss / fur mantle draped over the back segments, optional blossoms [(s, side)] on it."""
    J("Body")
    for g in ctx["body"]:
        if s0 <= g["s"] <= s1:
            k.p("Mantle%d" % (g["i"] + 1), (g["w"] * wf, th, g["len"] * 1.05),
                g["f"] * CF((0, g["t"] / 2 + over - (th - 0.2) / 2, 0)), col)
    for i, (s, side) in enumerate(blossoms):
        g = A.seg_at(ctx["body"], s)
        at = g["mid"] + g["B"] * (g["t"] / 2 + over + 0.12) + g["X"] * side * g["w"] * 0.3
        A.blossom(k, "MantleBloom%d" % (i + 1), at, g["B"], bloom)


def antlers(k, ctx, base=(0.35, 0.5, 0.1), beams=(), tines=(), col="bark", w0=0.24, taper=0.78, blooms=(),
            bloom_size=0.42, leaves=()):
    """Branching antlers on the head: per side a beam of segments (`beams` = [(dir, len)] in head coords, x
    mirrored), tines branching off beam joints (`tines` = [(joint index, dir, len)]), blossoms at tips
    (`blooms` = indices: 'b' beam end, or tine number) and leaves [(joint index, dir, len, w)]."""
    J("Head")
    H = ctx["head"]
    for sx, sd in A.SIDES:
        m = lambda v: H.vec((sx * v[0], v[1], v[2]))
        pts = A.branch(k, "Antler" + sd, H.pt((sx * base[0], base[1], base[2])), [(m(d), ln) for d, ln in beams], col,
                       w0=w0, taper=taper)
        ends = {"b": (pts[-1], (pts[-1] - pts[-2]).normalized())}
        for i, (j, d, ln) in enumerate(tines):
            a = pts[j]
            dd = m(d).normalized()
            ww = w0 * taper ** (j + 1)
            k.seg("Tine%s%d" % (sd, i + 1), a, a + dd * ln, ww, ww, col)
            ends[i + 1] = (a + dd * ln, dd)
        for i, key in enumerate(blooms):
            p, dd = ends[key]
            A.blossom(k, "Bloom%s%d" % (sd, i + 1), p + dd * 0.05, dd, bloom_size)
        for i, (j, d, ln, w) in enumerate(leaves):
            A.leaf(k, "AntlerLeaf%s%d" % (sd, i + 1), pts[j], m(d), ln, w, "leaf", thick=0.1, normal=H.vec((0, 1, 0)),
                   tip=False)


def fuzz(k, ctx, at=(0, 2, 0), size=(2.2, 0.5, 2.2), col="light", joint="Body", turn=45, axis="y"):
    """Fuzzy collar: two square slabs crossed 45 degrees about `axis` (an octagon ring of fluff)."""
    J(joint)
    k.p("Fuzz", size, CF(Vector(at)), col)
    twist = cf(rz=turn) if axis == "z" else cf(ry=turn)
    k.p("Fuzz2", tuple(v * f for v, f in zip(size, (0.94, 0.94, 0.9) if axis == "z" else (0.94, 0.9, 0.94))),
        CF(Vector(at)) * twist, col)


def dipper(k, ctx, s=0.0, len=0.9, r=0.34, col="dark", rings=3, ring_col="light", drip="glow"):
    """Honey-dipper stinger at the abdomen tip: a handle and a ribbed head of stacked discs, with a Neon drip."""
    J("Body")
    g = ctx["body"][0]
    d = -g["T"]
    a = g["a"] - d * 0.1
    k.seg("Stinger", a, a + d * len, 0.16, 0.16, col)
    for i in range(rings):
        c = look(a + d * (len - 0.08 - i * 0.16), d, (0, 1, 0))
        k.p("Ridge%d" % (i + 1), (r * (1 - 0.18 * (i % 2)), 0.12, r * (1 - 0.18 * (i % 2))), c * cf(ry=45 * (i % 2)),
            ring_col if i % 2 == 0 else col, studs=False)
    if drip:
        k.p("Drip", (0.16, 0.26, 0.16), CF(a + d * (len - 0.2) + Vector((0, -r * 0.55, 0))), drip, material="Neon")


def crystals(k, ctx, at=(), joint="Body"):
    """Glass crystals with a Neon tip: at = [(name, base, up, length, width, n)] in world coords."""
    J(joint)
    for name, base, up, ln, w, n in at:
        k.crystal(name, base, up, ln, w, n=n)


def brows(k, ctx, y=0.7, x=0.45, w=0.5, h=0.14, rz=12, col="dark", z=None):
    J("Head")
    H = ctx["head"]
    dp = ctx["head_size"][2]
    for sx, sd in A.SIDES:
        H.p("Brow" + sd, (w, h, 0.12), (sx * x, y, (z if z is not None else -dp / 2) - 0.06), col, rz=-sx * rz,
            studs=False)


FEATURES = dict(ears=ears, sprout=sprout, collar=collar, mantle=mantle, antlers=antlers, fuzz=fuzz, dipper=dipper,
                crystals=crystals, brows=brows)
