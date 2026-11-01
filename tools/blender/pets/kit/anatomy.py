# Shared creature parts, built from Roblox primitives: palettes, local frames, spine-curve bodies, eyes, ears,
# horns/antlers, blossoms, wings, tails and limbs. Body plans (plans.py) assemble them. Roblox axes: +Y up, front -Z.
import math

from mathutils import Vector

from .rbx import CF, J, catmull, cf, crystal, frame, keys, look, part, resample, seg, tri

SIDES = ((-1, "L"), (1, "R"))


# ---- colour ----------------------------------------------------------------------------------------------
def _rgb(hx):
    hx = hx.lstrip("#")
    return [int(hx[i : i + 2], 16) for i in (0, 2, 4)]


def _hex(c):
    return "%02X%02X%02X" % tuple(max(0, min(255, round(v))) for v in c)


def shade(hx, f):
    """Darker (f < 1) or lighter towards white (f > 1)."""
    c = _rgb(hx)
    if f <= 1:
        return _hex([v * f for v in c])
    t = f - 1
    return _hex([v + (255 - v) * t for v in c])


def mix(a, b, t):
    ca, cb = _rgb(a), _rgb(b)
    return _hex([x + (y - x) * t for x, y in zip(ca, cb)])


class Pal:
    """3 main colours + 1 Neon glow accent (main, dark, light, glow) and the shades derived from them.
    Any other key (blossom, horn...) may be added per pet; feature colours name a key or give a hex."""

    def __init__(self, d):
        self.d = {k: v.lstrip("#").upper() for k, v in d.items()}
        g = self.d
        g.setdefault("main2", shade(g["main"], 0.9))  # every other body segment (banding)
        g.setdefault("ink", mix(g["dark"], "000000", 0.72))  # sockets, pupils, mouths
        g.setdefault("glint", "FFFFFF")
        g.setdefault("eye", g["glow"])
        g.setdefault("glass", mix(g["glow"], "FFFFFF", 0.45))  # crystals, membranes
        g.setdefault("tip", mix(g["glow"], "FFFFFF", 0.7))

    def __call__(self, k):
        return self.d.get(k, k.lstrip("#").upper() if isinstance(k, str) else k)


# ---- builder ---------------------------------------------------------------------------------------------
class Kit:
    """Palette-aware part maker. Small details (thinner than `thin` studs) and non-blocks get no studs; big
    masses keep the default studded top (BlockBuilder: top faces only)."""

    def __init__(self, pal, thin=0.32):
        self.pal = pal
        self.thin = thin

    def p(self, name, size, c, col, shape="Block", studs=None, material="SmoothPlastic", **kw):
        if studs is None and (min(size) < self.thin or shape != "Block"):
            studs = False
        return part(name, size, c, self.pal(col), mat=material, shape=shape, studs=studs, **kw)

    def seg(self, name, a, b, w, t, col, up_hint=(0, 0, 1), **kw):
        a, b = Vector(a), Vector(b)
        c = look((a + b) / 2, b - a, up_hint)
        return self.p(name, (w, (b - a).length, t), c, col, **kw)

    def hinge(self, joint, pos):
        """Invisible pivot: the first part of a joint group is where BlockBuilder puts its Motor6D."""
        J(joint)
        return self.p("Hinge" + joint, (0.2, 0.2, 0.2), CF(Vector(pos)), "main", transp=1, studs=False)

    def crystal(self, name, base, up, length, width, hint=(0, 0, 1), n=2, body="glass", tip="tip", **kw):
        return crystal(name, Vector(base), Vector(up), length, width, self.pal(body), self.pal(tip), hint=hint, n=n,
                       **kw)

    def tri(self, name, a, b, c, thick, col, **kw):
        if "material" in kw:
            kw["mat"] = kw.pop("material")
        return tri(name, a, b, c, thick, self.pal(col), **kw)


class Frame:
    """A local frame with uniform scale `s`: place parts and points in local coordinates (heads, eggs)."""

    def __init__(self, k, c, s=1.0):
        self.k, self.c, self.s = k, c, s

    def pt(self, v):
        return self.c.point(tuple(x * self.s for x in v))

    def vec(self, v):
        return self.c.vec(v)

    def at(self, pos, rx=0, ry=0, rz=0):
        return self.c * cf(tuple(x * self.s for x in pos), rx, ry, rz)

    def p(self, name, size, pos, col, rx=0, ry=0, rz=0, **kw):
        return self.k.p(name, tuple(x * self.s for x in size), self.at(pos, rx, ry, rz), col, **kw)


# ---- spine-curve bodies ----------------------------------------------------------------------------------
def spine(k, name, pts, n, w, t, col=("main", "main2"), up=(0, 1, 0), stretch=1.18, sub=10, joint=None,
          studs=None, roll=None):
    """Segmented body along a Catmull-Rom curve through `pts` (first -> last). `w`/`t` are widths/thicknesses:
    numbers or [(s, value)] keys over the arc fraction s. `joint(i, s)` names each segment's joint group.
    Returns the segments (frames, sizes) for attaching plates, fins and limbs."""
    poly = catmull([Vector(p) for p in pts], sub)
    P, fr, _ = resample(poly, n)
    segs = []
    for i in range(n):
        a, b = P[i], P[i + 1]
        s = (fr[i] + fr[i + 1]) / 2
        wi = keys(s, w) if isinstance(w, list) else w
        ti = keys(s, t) if isinstance(t, list) else t
        T = (b - a).normalized()
        B0 = Vector(up)
        B = (B0 - T * B0.dot(T)).normalized()
        X = B.cross(T)
        f = frame((a + b) / 2, X, B, T)
        if roll:
            f = f * cf(rz=roll(i, s))
        if joint:
            J(joint(i, s))
        c = col[i % len(col)] if isinstance(col, tuple) else col
        k.p("%s%d" % (name, i + 1), (wi, ti, (b - a).length * stretch), f, c, studs=studs)
        segs.append(dict(i=i, a=a, b=b, mid=(a + b) / 2, s=s, w=wi, t=ti, T=T, B=B, X=X, f=f, len=(b - a).length))
    return segs


def seg_at(segs, s):
    return min(segs, key=lambda g: abs(g["s"] - s))


# ---- eyes --------------------------------------------------------------------------------------------------
def eyes(F, style, x, y, z, w, h, iris="eye", rz=0, look_in=0.0, pupil="ink", socket=True, rx=0):
    """A pair of eyes on a head frame F (Kit convention: EyeL/R Neon, PupilL/R, GlintL/R so Anim/Pet blinks them).
    front styles sit on the face plane z (negative): "cute" big iris + big pupil + glint; "almond" a socket,
    an angled almond iris, a slit pupil and a glint ("cool"); "dot" a dark Neon eye + glint (cheapest).
    "side" sits on the head's side planes x = +-x (deer, dragons): socket, iris, pupil towards the front, glint."""
    for sx, sd in SIDES:
        if style == "side":
            X = sx * x
            if socket:
                F.p("Socket" + sd, (0.06, h * 1.3, w * 1.18), (X, y, z), "ink", rx=rx, studs=False)
            F.p("Eye" + sd, (0.05, h, w), (X + sx * 0.03, y, z), iris, rx=rx, material="Neon")
            F.p("Pupil" + sd, (0.04, h * 0.92, w * 0.18), (X + sx * 0.05, y, z - w * 0.12), pupil, rx=rx, studs=False)
            F.p("Glint" + sd, (0.03, h * 0.3, h * 0.3), (X + sx * 0.065, y + h * 0.28, z - w * 0.3), "glint", rx=rx,
                material="Neon")
            continue
        t = -sx * rz  # outer corners up for positive rz
        if style == "dot":
            F.p("Eye" + sd, (w, h, 0.08), (sx * x, y, z - 0.04), "ink", rz=t, material="Neon")
            F.p("Glint" + sd, (w * 0.36, w * 0.36, 0.04), (sx * (x + w * 0.16), y + h * 0.2, z - 0.1), "glint",
                rz=t, material="Neon")
            continue
        if style == "almond":
            if socket:
                F.p("Socket" + sd, (w * 1.2, h * 1.3, 0.05), (sx * x, y, z - 0.02), "ink", rz=t, studs=False)
            F.p("Eye" + sd, (w, h, 0.06), (sx * x, y, z - 0.05), iris, rz=t, material="Neon")
            F.p("Pupil" + sd, (w * 0.26, h * 0.92, 0.05), (sx * (x - look_in), y, z - 0.09), pupil, rz=t,
                studs=False)
            F.p("Glint" + sd, (w * 0.22, w * 0.22, 0.04), (sx * (x + w * 0.24), y + h * 0.22, z - 0.12), "glint",
                rz=t, material="Neon")
            continue
        # cute
        F.p("Eye" + sd, (w, h, 0.08), (sx * x, y, z - 0.04), iris, rz=t, material="Neon")
        F.p("Pupil" + sd, (w * 0.62, h * 0.74, 0.06), (sx * (x - look_in), y - h * 0.06, z - 0.09), pupil, rz=t,
            studs=False)
        F.p("Glint" + sd, (w * 0.3, w * 0.3, 0.04), (sx * (x + w * 0.17), y + h * 0.2, z - 0.13), "glint", rz=t,
            material="Neon")


# ---- ears, horns, antlers, blossoms ------------------------------------------------------------------------
def leaf(k, name, base, d, length, width, col, thick=0.14, normal=(0, 0, -1), vein=None, tip=True):
    """Leaf blade from `base` along `d` (pointed diamond tip). Used for ears, sprouts, tails, wings of plants."""
    d = Vector(d).normalized()
    base = Vector(base)
    c = look(base + d * (length * 0.42), d, normal)
    out = [k.p(name, (width, length * 0.84, thick), c, col)]
    if tip:
        tc = look(base + d * (length * 0.84), d, normal) * cf(rz=45)
        e = width * 0.7071
        out.append(k.p(name + "Tip", (e, e, thick * 0.96), tc, col))
    if vein:
        vc = look(base + d * (length * 0.45), d, normal) * CF((0, 0, -thick * 0.5))
        out.append(k.p(name + "Vein", (width * 0.16, length * 0.8, 0.05), vc, vein, studs=False))
    return out


def branch(k, name, base, dirs, col, w0=0.24, taper=0.8):
    """Antler / branch beam: one segment per (direction, length); width tapers. Returns the joint points."""
    pts = [Vector(base)]
    w = w0
    for i, (d, ln) in enumerate(dirs):
        a = pts[-1]
        b = a + Vector(d).normalized() * ln
        k.seg("%s%d" % (name, i + 1), a - (b - a).normalized() * 0.04, b + (b - a).normalized() * 0.04, w, w, col)
        pts.append(b)
        w *= taper
    return pts


def blossom(k, name, at, normal, size, petal="blossom", centre="glow", glow=True):
    """Bricky five-petal flower read as a diamond of petals + a Neon centre (2 parts)."""
    n = Vector(normal).normalized()
    c = look(Vector(at), n, (0, 1, 0) if abs(n.y) < 0.9 else (0, 0, 1))
    k.p(name, (size, 0.12, size), c * cf(ry=45), petal, studs=False)
    k.p(name + "Core", (size * 0.42, 0.14, size * 0.42), c * CF((0, 0.04, 0)), centre,
        material="Neon" if glow else "SmoothPlastic", studs=False)


def horn(k, name, base, d, length, w, col, bend=(0, 0, 0), n=3, tip=None):
    """Stepped curved horn: n tapering segments bending by `bend` per step; optional crystal/neon tip."""
    pts = [Vector(base)]
    d = Vector(d).normalized()
    for i in range(n):
        a = pts[-1]
        b = a + d * (length / n)
        ww = w * (1 - 0.55 * i / n)
        k.seg("%s%d" % (name, i + 1), a, b + d * 0.05, ww, ww, col)
        pts.append(b)
        d = (d + Vector(bend)).normalized()
    if tip:
        k.crystal(name + "Tip", pts[-1] - d * 0.05, d, length * 0.3, w * 0.5, n=1) if tip == "crystal" else k.p(
            name + "Tip", (w * 0.4, length * 0.18, w * 0.4), look(pts[-1] + d * length * 0.08, d), tip,
            material="Neon")
    return pts


# ---- wings -------------------------------------------------------------------------------------------------
def wings_insect(k, root, span, chord, col="glass", vein="ink", rise=28, sweep=30, hind=0.62, transp=0.35,
                 caps=(True, False)):
    """Two glass wings per side (fore + hind) with a dark leading-edge vein; each side is its own Wing group
    whose first part is the root (pivot for the flap)."""
    for sx, sd in SIDES:
        J("Wing" + sd)
        r = Vector((sx * abs(root[0]), root[1], root[2]))
        k.p("WingRoot" + sd, (0.24, 0.24, 0.24), CF(r), vein, shape="Ball")
        out = Vector((sx * math.cos(math.radians(sweep)), math.sin(math.radians(rise)), math.sin(math.radians(sweep))))
        out.normalize()
        nrm = (Vector((0, 1, 0)) - out * out.y).normalized()
        Z = out.cross(nrm)
        lead = 1 if Z.z < 0 else -1  # local z towards the front (leading edge)
        for w_i, (name, ln, ch, back) in enumerate(
            (("Forewing", span, chord, 0.0), ("Hindwing", span * hind, chord * 0.8, chord * 0.55))
        ):
            base = r + Vector((0, -0.05, back))
            c = frame(base + out * (ln / 2), out, nrm, Z)  # local X along the wing, Z across the chord
            k.p(name + sd, (ln, 0.08, ch), c, col, material="Glass", transp=transp)
            if caps[w_i]:  # a wider outer pane rounds the wing (stepped teardrop)
                k.p(name + "Cap" + sd, (ln * 0.42, 0.07, ch * 1.18), c * CF((ln * 0.26, 0, 0)), col, material="Glass",
                    transp=transp)
            if name == "Forewing":
                k.p("Vein" + sd, (ln * 0.96, 0.1, 0.09), c * CF((0, 0.01, lead * ch * 0.42)), vein, studs=False)


def wings_feather(k, root, span, col=("main", "light"), tipcol="dark", feathers=4, rise=18, sweep=25, fold=0.0):
    """Bird wing per side: an arm bone (first part = shoulder pivot) and `feathers` long blocks fanning back,
    longest at the tip; alternating colours, the outer primaries in `tipcol`."""
    for sx, sd in SIDES:
        J("Wing" + sd)
        r = Vector((sx * abs(root[0]), root[1], root[2]))
        out = Vector((sx * math.cos(math.radians(sweep)), math.sin(math.radians(rise)), math.sin(math.radians(sweep))))
        out.normalize()
        k.p("Shoulder" + sd, (0.36, 0.36, 0.36), CF(r), col[0], shape="Ball")
        tip = r + out * span * 0.55
        k.seg("Arm" + sd, r, tip, 0.34, 0.24, col[0])
        nrm = (Vector((0, 1, 0)) - out * out.y).normalized()
        for i in range(feathers):
            f = i / max(1, feathers - 1)
            a = r.lerp(tip, 0.35 + 0.65 * f)
            ln = span * (0.45 + 0.55 * f)
            back = (Vector((0, 0, 1)) * (1 - f) + out * f * 0.9 + Vector((0, -0.25, 0)) * (1 - f)).normalized()
            c = look(a + back * ln / 2, back, nrm)
            k.p("Feather%s%d" % (sd, i + 1), (0.36 - 0.04 * f, ln, 0.1), c,
                tipcol if i >= feathers - 2 else col[i % 2])


def wings_membrane(k, root, scale=1.0, bone="dark", mem=("glass", "light"), claw="tip", fingers=3, crystals=True):
    """Dragon / bat wing per side, FS style: shoulder ball (pivot), upper arm to the elbow, forearm to the wrist,
    a thumb crystal, fingers fanning back and two-tone glass membranes that stop short of the finger tips."""
    for sx, sd in SIDES:
        J("Wing" + sd)
        S = Vector((sx * abs(root[0]), root[1], root[2]))
        k.p("Shoulder" + sd, (0.4 * scale, 0.4 * scale, 0.4 * scale), CF(S), bone, shape="Ball")
        E = S + Vector((sx * 0.55, 0.85, 0.45)).normalized() * 1.05 * scale
        Wr = E + Vector((sx * 1.0, 0.35, -0.15)).normalized() * 1.35 * scale
        k.seg("UpperWing" + sd, S, E + (E - S).normalized() * 0.1, 0.26 * scale, 0.26 * scale, bone)
        k.seg("Forewing" + sd, E, Wr, 0.22 * scale, 0.22 * scale, bone)
        k.p("Wrist" + sd, (0.32 * scale,) * 3, CF(Wr), bone, shape="Ball")
        k.crystal("Thumb" + sd, Wr, Vector((sx * 0.3, 0.5, -0.8)), 0.42 * scale, 0.14 * scale, n=1)
        fan = ((0.55, 0.85, 0.25, 1.5), (0.95, 0.2, 0.35, 2.1), (0.7, -0.55, 0.45, 1.95), (0.25, -0.9, 0.4, 1.6))
        fan = fan[:fingers] if fingers < 4 else fan
        edge = []
        for i, (fx, fy, fz, ln) in enumerate(fan):
            d = Vector((sx * fx, fy, fz)).normalized()
            tipp = Wr + d * ln * scale
            k.seg("Finger%s%d" % (sd, i + 1), Wr, tipp, (0.15 - 0.01 * i) * scale, (0.15 - 0.01 * i) * scale, bone)
            if crystals and i in (1, 2):
                k.crystal("WingTip%s%d" % (sd, i + 1), tipp - d * 0.05, d, 0.5 * scale, 0.17 * scale, n=1)
            edge.append(Wr + d * ln * 0.84 * scale)
        anchor = S + Vector((sx * 0.05, -1.45, 0.3)) * scale
        panels = [(S, E, Wr)] + [(Wr, edge[i], edge[i + 1]) for i in range(len(edge) - 1)]
        panels += [(Wr, edge[-1], anchor), (S, Wr, anchor)]
        for i, (p0, p1, p2) in enumerate(panels):
            k.tri("Membrane%s%d" % (sd, i + 1), p0, p1, p2, 0.1, mem[i % 2], material="Glass",
                  transp=0.1 if i % 2 else 0.05)


# ---- limbs and tails ---------------------------------------------------------------------------------------
def limb(k, joint, pts, widths, col, foot=None, hinge=True):
    """Hinge at pts[0], then one segment per point pair (thigh, shin...), optional foot block
    foot = dict(size=, col=, fwd=, pad=)."""
    if hinge:
        k.hinge(joint, pts[0])
    else:
        J(joint)
    n = len(pts) - 1
    names = {1: ("Leg",), 2: ("Upper", "Lower"), 3: ("Upper", "Mid", "Lower")}[n]
    for i in range(n):
        a, b = Vector(pts[i]), Vector(pts[i + 1])
        d = (b - a).normalized()
        w = widths[i] if isinstance(widths, (list, tuple)) else widths
        c = col[i] if isinstance(col, (list, tuple)) else col
        k.seg(names[i] + joint, a - d * 0.06, b + d * 0.06, w, w, c)
    if foot:
        e = Vector(pts[-1])
        sz = foot["size"]
        pos = Vector((e.x, sz[1] / 2 + foot.get("y", 0), e.z - foot.get("fwd", 0)))
        k.p(foot.get("name", "Foot") + joint, sz, CF(pos) * cf(ry=foot.get("ry", 0)), foot["col"])
        if foot.get("pad"):
            k.p("Pad" + joint, (sz[0] * 0.6, 0.06, sz[2] * 0.35), CF(pos + Vector((0, sz[1] / 2 + 0.02, -sz[2] * 0.3))),
                foot["pad"], studs=False)


def tail_curve(k, name, pts, n, w, t, col=("main", "main2"), tip=None, hinge=True, up=(0, 1, 0)):
    """Tapered segmented tail along a curve, hinge at its base (Tail group), optional tip: leaf/crystal/tuft."""
    if hinge:
        k.hinge("Tail", pts[0])
    else:
        J("Tail")
    segs = spine(k, name, pts, n, w, t, col=col, up=up, stretch=1.15)
    if tip:
        g = segs[-1]
        kind = tip["kind"]
        if kind == "leaf":
            leaf(k, name + "Leaf", g["b"] - g["T"] * 0.05, g["T"] + Vector(tip.get("bend", (0, 0.3, 0))),
                 tip.get("len", 0.9), tip.get("w", 0.5), tip.get("col", "light"), normal=g["X"],
                 vein=tip.get("vein"))
        elif kind == "crystal":
            k.crystal(name + "Tip", g["b"] - g["T"] * 0.05, g["T"], tip.get("len", 0.6), tip.get("w", 0.24))
        elif kind == "tuft":
            c = look(g["b"] + g["T"] * 0.18, g["T"], g["B"])
            k.p(name + "Tuft", (g["w"] * 1.5, 0.5, g["w"] * 1.5), c * cf(ry=45), tip.get("col", "light"))
    return segs
