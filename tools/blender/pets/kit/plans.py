# Body plans: quadruped, biped, serpent, flyer (bird), floater, fish and insect. Each builds one pet from its data
# entry (zones/*.py) into the current collection with the standard rig (anatomy.py, Models/Kit.luau conventions):
#   joint groups Body, Head, ArmL/R (front legs on quadrupeds), LegL/R, WingL/R, Tail, Coil (serpents),
#   Orbit/Orbit2/Halo (spun by Anim/Spin; each starts with an invisible hub). The first part of every group is its
#   pivot: an invisible Hinge*, or a small joint part (shoulder ball, wing root) centred on the joint.
# Feet at y = 0 (floaters/fish/hovering insects have no part at y = 0), facing -Z. Shared features
# (features.py) add the signature details on top.
import math

from mathutils import Matrix, Vector

from . import anatomy as A
from .rbx import CF, J, cf, frame, look, rot_r


def _v(p):
    return Vector(p)


def _rotx(d, deg):
    """Rotate a direction about X: positive tips a downward vector towards the front (-Z)."""
    return Matrix.Rotation(math.radians(-deg), 3, "X") @ Vector(d)


def _chain(top, lengths, angles):
    pts = [Vector(top)]
    for ln, a in zip(lengths, angles):
        pts.append(pts[-1] + _rotx((0, -1, 0), a) * ln)
    return pts


def _fit(top, lengths, angles, foot_h):
    """Scale segment lengths so a standing leg's foot block lands on the ground."""
    drop = sum(ln * math.cos(math.radians(a)) for ln, a in zip(lengths, angles))
    need = top[1] - foot_h
    f = need / drop if drop > 1e-6 else 1
    return [ln * f for ln in lengths]


def legs(k, d, pairs):
    """Legs from hips: `pairs` = [(joint prefix, dict(x, y, z, len, ang, w, col, foot))]; per-side pose overrides
    in d["pose"] = {"ArmR": [angles...]} (a lifted leg keeps its lengths and leaves the ground)."""
    pose = d.get("pose", {})
    for pre, L in pairs:
        for sx, sd in A.SIDES:
            joint = pre + sd
            top = (sx * L["x"], L["y"], L["z"])
            ang = L["ang"]
            foot = L.get("foot")
            fh = foot["size"][1] if foot else 0.0
            lens = _fit(top, L["len"], ang, fh) if not L.get("free") else L["len"]
            ang = pose.get(joint, ang)
            pts = _chain(top, lens, ang)
            A.limb(k, joint, pts, L["w"], L["col"], hinge=L.get("hinge", True))
            if foot:
                dvec = (pts[-1] - pts[-2]).normalized()
                sz = foot["size"]
                c = look(pts[-1] + dvec * (sz[1] / 2 - foot.get("sink", 0.04)), -dvec, (0, 0, -1))
                c = c * CF((0, 0, foot.get("fwd", 0)))
                k.p(foot.get("name", "Foot") + joint, sz, c, foot["col"])
                if foot.get("toe"):
                    k.p("Toe" + joint, (sz[0] * 0.7, 0.06, 0.12), c * CF((0, sz[1] / 2 + 0.02, sz[2] / 2 - 0.08)),
                        foot["toe"], studs=False)


# ---- heads ---------------------------------------------------------------------------------------------------
def head(k, d, ctx):
    """Head group: hinge at the neck, then the skull and face by kind. Returns the head Frame (features use it)."""
    at = _v(d["at"])
    w, h, dp = d["size"]
    neck = _v(d.get("neck", (0, at.y - h * 0.42, at.z + dp * 0.22)))
    if d.get("hinge", True):
        k.hinge("Head", neck)
    else:
        J("Head")
    H = A.Frame(k, CF(at, rot_r(d.get("pitch", 0), d.get("yaw", 0), d.get("roll", 0))))
    ctx["head"] = H
    ctx["head_size"] = (w, h, dp)
    col = d.get("col", "main")
    kind = d.get("kind", "block")
    fz = -dp / 2
    if kind in ("block", "long", "round", "bug"):
        H.p("Skull", (w, h, dp), (0, 0, 0), col)
    if kind == "round":  # stepped silhouette: a crossed slab rounds the corners
        H.p("SkullRound", (w * 1.08, h * 0.7, dp * 0.84), (0, -h * 0.02, 0), col)
    if kind == "long":
        sl = d.get("snout", 1.0)
        H.p("Snout", (w * 0.64, h * 0.56, sl), (0, -h * 0.16, fz - sl / 2 + 0.12), col)
        if d.get("chin"):
            H.p("Chin", (w * 0.56, h * 0.16, sl * 0.86), (0, -h * 0.38, fz - sl / 2 + 0.1), d["chin"], studs=False)
        nw, nh = d.get("nose_size", (0.5, 0.26))
        H.p("Nose", (w * nw, h * nh, 0.14), (0, -h * 0.06 + h * (0.26 - nh) / 2, fz - sl + 0.1), d.get("nose", "ink"),
            studs=False)
        fz_eye = d.get("eye_z", -dp * 0.12)
    if kind in ("block", "round"):
        if d.get("face"):
            H.p("Face", (w * 0.8, h * 0.6, 0.1), (0, -h * 0.13, fz - 0.04), d["face"], studs=False)
        mz = d.get("muzzle")
        if mz:
            H.p("Muzzle", mz[:3], (0, mz[3], fz - mz[2] / 2 + 0.06), d.get("muzzle_col", "light"))
            H.p("Nose", (0.38, 0.22, 0.12), (0, mz[3] + mz[1] / 2 - 0.06, fz - mz[2] - 0.0), d.get("nose", "ink"),
                studs=False)
    e = d.get("eyes")
    if e:
        if e["style"] == "side":
            A.eyes(H, "side", w / 2 + 0.02, e.get("y", h * 0.12), e.get("z", fz_eye if kind == "long" else -dp * 0.15),
                   e["w"], e["h"], iris=e.get("iris", "eye"), rx=e.get("rx", 0), socket=e.get("socket", True))
        else:
            A.eyes(H, e["style"], e["x"], e["y"], fz - e.get("lift", 0.0), e["w"], e["h"], iris=e.get("iris", "eye"),
                   rz=e.get("rz", 0), look_in=e.get("look_in", 0.0), socket=e.get("socket", True))
    if d.get("cheeks"):
        c = d["cheeks"]
        for sx, sd in A.SIDES:
            H.p("Cheek" + sd, (c["w"], c["h"], 0.06), (sx * c["x"], c["y"], fz - c.get("lift", 0.0) - 0.04),
                c.get("col", "blush"), studs=False)
    if d.get("mouth"):
        m = d["mouth"]
        H.p("Mouth", (m["w"], m.get("h", 0.08), 0.06), (0, m["y"], fz - m.get("lift", 0.0) - 0.04), "ink", studs=False)
    return H


# ---- plans -----------------------------------------------------------------------------------------------------
def quadruped(k, d, ctx):
    """Four legs (front = ArmL/R, back = LegL/R) under a spine-curve body (rump -> withers), an optional neck
    curve (Head group) and a head. d: body, neck, head, front, back, tail, pose."""
    b = d["body"]
    J("Body")
    if b.get("hinge", True):
        k.hinge("Body", b.get("pivot", b["pts"][len(b["pts"]) // 2]))
    segs = A.spine(k, b.get("name", "Body"), b["pts"], b["n"], b["w"], b["t"], col=tuple(b.get("col", ("main",))),
                   stretch=b.get("stretch", 1.18))
    ctx["body"] = segs
    if b.get("belly"):
        bl = b["belly"]
        for g in segs:
            if bl.get("from", 0) <= g["s"] <= bl.get("to", 1):
                k.p("Belly%d" % (g["i"] + 1), (g["w"] * bl.get("wf", 0.7), 0.14, g["len"] * 0.98),
                    g["f"] * CF((0, -g["t"] / 2 - 0.05, 0)), bl["col"], studs=False)
    legs(k, d, [("Arm", d["front"]), ("Leg", d["back"])])
    if d.get("neck"):
        n = d["neck"]
        J("Head")
        k.hinge("Head", n["pts"][0])
        ctx["neck"] = A.spine(k, "Neck", n["pts"], n["n"], n["w"], n["t"], col=tuple(n.get("col", ("main",))),
                              stretch=n.get("stretch", 1.2))
        hd = dict(d["head"], hinge=False)
    else:
        hd = d["head"]
    head(k, hd, ctx)
    if d.get("tail"):
        tail(k, d["tail"], ctx)


def biped(k, d, ctx):
    """Upright: spine-curve torso (hips -> chest), head on top, arms (ArmL/R: shoulder hinge, upper, lower, hand)
    and legs (LegL/R: hip hinge, thigh, shin, foot)."""
    b = d["body"]
    J("Body")
    if b.get("hinge", True):
        k.hinge("Body", b["pts"][0])
    segs = A.spine(k, "Body", b["pts"], b["n"], b["w"], b["t"], col=tuple(b.get("col", ("main",))),
                   up=(0, 0, -1), stretch=b.get("stretch", 1.12))
    ctx["body"] = segs
    if b.get("belly"):
        bl = b["belly"]
        for g in segs:
            k.p("Belly%d" % (g["i"] + 1), (g["w"] * 0.7, 0.12, g["len"] * 0.96), g["f"] * CF((0, g["t"] / 2 + 0.04, 0)),
                bl["col"], studs=False)
    legs(k, d, [("Leg", d["legs"])])
    a = d["arms"]
    for sx, sd in A.SIDES:
        S = (sx * a["x"], a["y"], a["z"])
        pts = _chain(S, a["len"], a["ang"])
        pts = [Vector((p.x + sx * a.get("out", 0.15) * i, p.y, p.z)) for i, p in enumerate(pts)]
        A.limb(k, "Arm" + sd, pts, a["w"], a["col"])
        if a.get("hand"):
            hs = a["hand"]["size"]
            dv = (pts[-1] - pts[-2]).normalized()
            k.p("Hand" + sd, hs, look(pts[-1] + dv * hs[1] * 0.4, dv, (0, 0, -1)), a["hand"]["col"])
    head(k, d["head"], ctx)
    if d.get("tail"):
        tail(k, d["tail"], ctx)


def flyer(k, d, ctx):
    """Bird: tilted spine-curve body (tail -> chest), head with a beak, feathered wings, a fanned tail and thin
    legs with toes."""
    b = d["body"]
    J("Body")
    k.hinge("Body", b["pts"][len(b["pts"]) // 2])
    segs = A.spine(k, "Body", b["pts"], b["n"], b["w"], b["t"], col=tuple(b.get("col", ("main",))),
                   stretch=b.get("stretch", 1.2))
    ctx["body"] = segs
    if b.get("belly"):
        for g in segs:
            k.p("Belly%d" % (g["i"] + 1), (g["w"] * 0.72, 0.14, g["len"] * 0.98), g["f"] * CF((0, -g["t"] / 2 - 0.05, 0)),
                b["belly"]["col"], studs=False)
    if d.get("legs"):
        legs(k, d, [("Leg", d["legs"])])
    H = head(k, d["head"], ctx)
    bk = d["head"].get("beak")
    if bk:
        w, h, dp = d["head"]["size"]
        H.p("Beak", (bk["w"], bk["h"], bk["len"]), (0, bk.get("y", -h * 0.1), -dp / 2 - bk["len"] / 2 + 0.05),
            bk.get("col", "dark"), rx=bk.get("rx", 0), shape="Wedge", ry=180)
        H.p("BeakLow", (bk["w"] * 0.85, bk["h"] * 0.45, bk["len"] * 0.7),
            (0, bk.get("y", -h * 0.1) - bk["h"] * 0.6, -dp / 2 - bk["len"] * 0.35 + 0.05), bk.get("col", "dark"),
            studs=False)
    wg = d["wings"]
    A.wings_feather(k, wg["root"], wg["span"], col=tuple(wg.get("col", ("main", "light"))),
                    tipcol=wg.get("tip", "dark"), feathers=wg.get("feathers", 4), rise=wg.get("rise", 18),
                    sweep=wg.get("sweep", 25))
    if d.get("tail"):
        tail(k, d["tail"], ctx)


def floater(k, d, ctx):
    """Hovers (no part at y = 0): a stepped orb body (square layers like the egg shell), a face on its front,
    optional tendrils (Tail), an orbiting ring (Orbit) and a halo (Halo)."""
    b = d["body"]
    lift, R, H_ = b["lift"], b["r"], b["h"]
    J("Body")
    k.hinge("Body", (0, lift + H_ / 2, 0))
    n = b.get("layers", 6)
    for i in range(n):
        y = lift + (i + 0.5) * H_ / n
        t = (y - lift) / H_ * 2 - 1
        r = max(0.25, R * math.sqrt(max(0, 1 - t * t)) * (1 - 0.1 * t))
        col = b["col"][i % len(b["col"])] if isinstance(b["col"], (list, tuple)) else b["col"]
        k.p("Orb%d" % (i + 1), (r * 2, H_ / n, r * 2), CF((0, y, 0)), col,
            material=b.get("material", "SmoothPlastic"), transp=b.get("transp", 0.0))
    head(k, d["head"], ctx)
    if d.get("tail"):
        tail(k, d["tail"], ctx)
    if d.get("orbit"):
        o = d["orbit"]
        J("Orbit")
        k.p("OrbitHub", (0.2, 0.2, 0.2), CF((0, o["y"], 0)), "main", transp=1, studs=False)
        for i in range(o["count"]):
            a = math.tau * i / o["count"]
            p = Vector((math.sin(a) * o["r"], o["y"], -math.cos(a) * o["r"]))
            if o.get("kind", "cube") == "crystal":
                k.crystal("Orbit%d" % (i + 1), p, (0, 1, 0), o["size"] * 2, o["size"] * 0.7, n=2)
            else:
                k.p("Orbit%d" % (i + 1), (o["size"],) * 3, CF(p) * cf(rx=45, ry=45), o.get("col", "glow"),
                    material=o.get("material", "Neon"))


def fish(k, d, ctx):
    """Hovering fish: a laterally flat spine-curve body (tail -> head), dorsal fin, pectoral fins (WingL/R so they
    flap) and a forked tail fin (Tail)."""
    b = d["body"]
    J("Body")
    k.hinge("Body", b["pts"][len(b["pts"]) // 2])
    segs = A.spine(k, "Body", b["pts"], b["n"], b["w"], b["t"], col=tuple(b.get("col", ("main", "main2"))),
                   stretch=1.16)
    ctx["body"] = segs
    if b.get("belly"):
        for g in segs:
            k.p("Belly%d" % (g["i"] + 1), (g["w"] * 0.8, 0.12, g["len"] * 0.98), g["f"] * CF((0, -g["t"] / 2 - 0.04, 0)),
                b["belly"]["col"], studs=False)
    fin = d.get("dorsal")
    if fin:
        g = A.seg_at(segs, fin.get("s", 0.5))
        c = frame(g["mid"] + g["B"] * (g["t"] / 2 + fin["h"] / 2 - 0.05), -g["X"], g["B"], -g["T"])
        k.p("Dorsal", (0.12, fin["h"], fin["len"]), c, fin.get("col", "dark"), shape="Wedge")
    H = head(k, d["head"], ctx)
    pf = d.get("pecs")
    if pf:
        g = A.seg_at(segs, pf.get("s", 0.75))
        for sx, sd in A.SIDES:
            J("Wing" + sd)
            r = g["mid"] + Vector((sx * g["w"] / 2, -g["t"] * 0.2, 0))
            k.p("FinRoot" + sd, (0.18, 0.18, 0.18), CF(r), pf.get("col", "dark"), shape="Ball")
            k.p("Fin" + sd, (pf["len"], 0.08, pf["w"]), CF(r + Vector((sx * pf["len"] / 2, -0.1, 0.15))) * cf(rz=-sx * 25),
                pf.get("col", "dark"), material=pf.get("material", "SmoothPlastic"), transp=pf.get("transp", 0))
    tf = d["tailfin"]
    g = segs[0]
    J("Tail")
    k.p("TailHinge", (0.2, 0.2, 0.2), CF(g["a"]), "main", transp=1, studs=False)
    for sgn, nm in ((1, "Upper"), (-1, "Lower")):
        dvec = (-g["T"] + Vector((0, sgn * 0.75, 0))).normalized()
        c = look(g["a"] + dvec * tf["len"] / 2, dvec, (1, 0, 0))
        k.p("TailFin" + nm, (0.1, tf["len"], tf["w"]), c, tf.get("col", "dark"), shape="Wedge")


def insect(k, d, ctx):
    """Bug: thorax (Body pivot), a segmented abdomen curving back (stripes = alternating colours), head with big
    eyes and antennae, glass wings (WingL/R) and six thin legs (front pair = ArmL/R, middle + hind = LegL/R).
    `hover` lifts the whole bug (the pet floats over the pedestal)."""
    b = d["body"]
    J("Body")
    th = b["thorax"]
    k.p("Thorax", th["size"], CF(_v(th["at"])), th.get("col", "main"))
    ab = b["abdomen"]
    ctx["body"] = A.spine(k, "Abdomen", ab["pts"], ab["n"], ab["w"], ab["t"], col=tuple(ab["col"]),
                          stretch=ab.get("stretch", 1.12))
    if d.get("wings"):
        wg = d["wings"]
        A.wings_insect(k, wg["root"], wg["span"], wg["chord"], col=wg.get("col", "glass"),
                       vein=wg.get("vein", "ink"), rise=wg.get("rise", 28), sweep=wg.get("sweep", 30),
                       hind=wg.get("hind", 0.62), transp=wg.get("transp", 0.35), caps=wg.get("caps", (True, False)))
    lg = d["legs"]
    for pre, rows in (("Arm", lg["front"]), ("Leg", lg["rear"])):
        for sx, sd in A.SIDES:
            joint = pre + sd
            hip0 = rows[0]["hip"]
            k.hinge(joint, (sx * hip0[0], hip0[1], hip0[2]))
            for r_i, row in enumerate(rows):
                hip = Vector((sx * row["hip"][0], row["hip"][1], row["hip"][2]))
                knee = hip + Vector((sx * row["out"], row["drop"][0], row.get("fwd", 0)))
                foot = knee + Vector((sx * row.get("out2", 0.05), row["drop"][1], row.get("fwd2", 0)))
                nm = "%s%d" % (sd, r_i + 1) if len(rows) > 1 else sd
                k.seg(pre + "Femur" + nm, hip, knee, lg["w"], lg["w"], lg.get("col", "ink"))
                k.seg(pre + "Tibia" + nm, knee, foot, lg["w"] * 0.85, lg["w"] * 0.85, lg.get("col", "ink"))
    H = head(k, d["head"], ctx)
    an = d.get("antennae")
    if an:
        for sx, sd in A.SIDES:
            p0 = H.pt((sx * an["x"], an["y"], an["z"]))
            p1 = p0 + H.vec((sx * an["out"], an["up"], an.get("fwd", -0.1))).normalized() * an["len"]
            k.seg("Antenna" + sd, p0, p1, 0.1, 0.1, an.get("col", "ink"))
            k.p("AntTip" + sd, (an["tip"],) * 3, CF(p1), an.get("tip_col", "ink"), shape="Ball")
    if d.get("tail"):
        tail(k, d["tail"], ctx)


def serpent(k, d, ctx):
    """Coiled serpent (the Frost Serpent's plan, parametrised): a ground coil rising in an S to the head, with
    belly plates, dorsal wedges and a head; optional arms. Joints: Coil, Body, Head."""
    from .rbx import catmull

    s = d["spine"]
    centre = Vector(s.get("centre", (0, 0, 0.55)))
    th_end = s.get("end", -0.35)
    th_start = th_end - s.get("turns", 1.15) * math.tau
    coil = []
    for i in range(61):
        f = i / 60
        th = th_start + (th_end - th_start) * f
        r = s.get("r0", 1.05) + s.get("r1", 0.95) * f
        coil.append(centre + Vector((r * math.sin(th), (0.42 + 0.64 * f) * 0.45, -r * math.cos(th))))
    sub = 12
    tl = catmull([coil[-7], coil[-1]] + [Vector(p) for p in s["rise"]], sub)[sub:]
    poly = coil + tl[1:]
    coil_len = sum((coil[i] - coil[i - 1]).length for i in range(1, len(coil)))
    from .rbx import resample, keys, smooth

    N = s.get("n", 18)
    P, fr, L = resample(poly, N)
    s_c = coil_len / L
    J("Coil")
    k.hinge("Coil", (centre.x, 0.3, centre.z))
    segs = []
    for i in range(N):
        a, b = P[i], P[i + 1]
        sm = (fr[i] + fr[i + 1]) / 2
        w = keys(sm, s.get("w", [(0, 0.4), (s_c, 1.0), (1, 0.9)]))
        T = (b - a).normalized()
        st = smooth(s_c - 0.03, s_c + 0.1, sm)
        B0 = Vector((0, 1, 0)).lerp(Vector((0, 0, 1)), st).normalized()
        B = (B0 - T * B0.dot(T)).normalized()
        X = B.cross(T)
        joint = "Coil" if sm < s_c else "Body"
        if joint == "Body" and not any(g["joint"] == "Body" for g in segs):
            k.hinge("Body", a)
        J(joint)
        f = frame((a + b) / 2, X, B, T)
        k.p("Seg%d" % (i + 1), (w, w * 0.9, (b - a).length * 1.22), f, "main" if i % 2 == 0 else "main2")
        if sm > s_c - 0.02:
            k.p("Belly%d" % (i + 1), (w * 0.66, 0.16, (b - a).length * 0.98), f * CF((0, -w * 0.45 - 0.05, 0)),
                "light", studs=False)
        hgt = 0.2 + 0.2 * w
        if i % s.get("dorsal_every", 1) == 0:
            wf = frame((a + b) / 2 + B * (w * 0.45 + hgt / 2 - 0.03), -X, B, -T)
            k.p("Dorsal%d" % (i + 1), (w * 0.3, hgt, (b - a).length * 0.8), wf, "dark", shape="Wedge")
        segs.append(dict(i=i, a=a, b=b, mid=(a + b) / 2, s=sm, w=w, t=w * 0.9, T=T, B=B, X=X, f=f,
                         len=(b - a).length, joint=joint))
    ctx["body"] = segs
    hd = dict(d["head"])
    hd.setdefault("at", tuple(P[-1] + Vector((0, 0.1, -0.3))))
    hd.setdefault("neck", tuple(P[-2]))
    head(k, hd, ctx)


def tail(k, t, ctx):
    kind = t.get("kind", "curve")
    if kind == "curve":
        A.tail_curve(k, "Tail", t["pts"], t["n"], t["w"], t["t"], col=tuple(t.get("col", ("main", "main2"))),
                     tip=t.get("tip"), hinge=t.get("hinge", True))
    elif kind == "leaf":  # a stem (the pivot) and a leaf blade
        J("Tail")
        p0, p1 = Vector(t["pts"][0]), Vector(t["pts"][1])
        k.seg("TailStem", p0, p1, t.get("stem_w", 0.24), t.get("stem_w", 0.24), t.get("stem_col", "dark"))
        A.leaf(k, "TailLeaf", p1 - (p1 - p0).normalized() * 0.05, Vector(t["dir"]), t["len"], t["w"],
               t.get("col", "light"), normal=t.get("normal", (1, 0, 0)), vein=t.get("vein"))
    elif kind == "tuft":  # short stem (pivot) + a fluffy block, turned 45 degrees
        J("Tail")
        p0, p1 = Vector(t["pts"][0]), Vector(t["pts"][1])
        k.seg("TailStem", p0, p1, t.get("stem_w", 0.3), t.get("stem_w", 0.3), t.get("stem_col", "main"))
        d = (p1 - p0).normalized()
        k.p("TailTuft", t["size"], look(p1 + d * t["size"][1] * 0.35, d, (0, 0, 1)) * cf(ry=45), t.get("col", "light"))
    elif kind == "fan":  # bird tail: hinge + feathers fanning back
        J("Tail")
        p0 = Vector(t["at"])
        k.hinge("Tail", p0)
        n = t.get("count", 3)
        for i in range(n):
            a = (i - (n - 1) / 2) * t.get("spread", 22)
            d = Vector((math.sin(math.radians(a)), t.get("up", 0.25), math.cos(math.radians(a)))).normalized()
            c = look(p0 + d * t["len"] / 2, d, (0, 1, 0))
            k.p("TailFeather%d" % (i + 1), (t.get("w", 0.36), t["len"], 0.1), c,
                t.get("col", ("main", "dark"))[i % 2] if isinstance(t.get("col"), (list, tuple)) else t.get("col", "dark"))


PLANS = dict(quadruped=quadruped, biped=biped, flyer=flyer, floater=floater, fish=fish, insect=insect,
             serpent=serpent)
