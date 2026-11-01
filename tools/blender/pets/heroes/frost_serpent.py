# 23 Frost Serpent (Legendary hero): pet + egg, built from Roblox primitives. Roblox axes, faces -Z, feet at y = 0.
# Bespoke (not a kit body plan); its bake must stay byte-identical (Premium/FrostSerpent.luau).
import math

from mathutils import Matrix, Vector

from kit.rbx import (C3, CF, J, catmull, cf, crystal, frame, keys, look, part, resample, rot_r, seg, smooth, tri,
                     use)

# Approved palette (Glacier): hide, darker hide band, armour, belly/antlers, crystal, crystal tip, two membrane tones,
# eye glow, eye socket, pupil, teeth.
PALETTES = {
    "glacier": dict(HIDE="2F7FE0", HIDE2="2A70CC", ARMOR="163E9A", WHITE="E6F6FF", ICE="9EEBFF", TIP="D6FAFF",
                    MEM_D="6CC2F7", MEM_L="CBEFFF", EYE="4FE8FF", SOCKET="0A1430", PUPIL="06102A", FANG="F2FAFF"),
}


def spine():
    centre = Vector((0, 0, 0.55))
    th_end = -0.35
    th_start = th_end - 1.15 * math.tau
    coil = []
    for k in range(61):
        f = k / 60
        th = th_start + (th_end - th_start) * f
        r = 1.05 + 0.95 * f
        coil.append(centre + Vector((r * math.sin(th), (0.42 + 0.64 * f) * 0.9 / 2, -r * math.cos(th))))
    rise = [(0.1, 1.2, -1.75), (0.1, 2.1, -1.85), (0, 2.95, -1.3), (0, 3.7, -0.6), (0, 4.5, -0.5),
            (0, 5.15, -0.95), (0, 5.5, -1.5)]
    sub = 12
    tail = catmull([coil[-7], coil[-1]] + rise, sub)[sub:]
    poly = coil + tail[1:]
    coil_len = sum((coil[i] - coil[i - 1]).length for i in range(1, len(coil)))
    return poly, coil_len


def build_serpent(name, offset, palette="glacier", scale=1.15):
    C = PALETTES[palette]
    coll = use(name, offset)
    poly, coil_len = spine()
    N = 24
    pts, fr, L = resample(poly, N)
    s_c = coil_len / L
    segs = []
    for i in range(N):
        a, b = pts[i], pts[i + 1]
        s = (fr[i] + fr[i + 1]) / 2
        w = keys(s, [(0, 0.4), (s_c, 1.06), (s_c + (1 - s_c) * 0.55, 1.24), (1, 0.96)])
        t = w * 0.9
        T = (b - a).normalized()
        st = smooth(s_c - 0.03, s_c + 0.1, s)
        B0 = Vector((0, 1, 0)).lerp(Vector((0, 0, 1)), st).normalized()
        B = (B0 - T * B0.dot(T)).normalized()
        X = B.cross(T)
        joint = "Coil" if s < s_c else ("Head" if i >= N - 3 else "Body")
        segs.append(dict(i=i, a=a, b=b, mid=(a + b) / 2, s=s, w=w, t=t, T=T, B=B, X=X, len=(b - a).length, joint=joint))

    # hidden hinges first: each joint group's first part is its Motor6D pivot (Anim/Pet rotates about it)
    def hinge(joint, pos):
        J(joint)
        part("Hinge" + joint, (0.2, 0.2, 0.2), CF(pos), C["WHITE"], studs=False, transp=1)

    hinge("Coil", Vector((0, 0.3, 0.55)))
    hinge("Body", next(g for g in segs if g["joint"] == "Body")["a"])
    hinge("Head", next(g for g in segs if g["joint"] == "Head")["a"])

    # body segments, belly plates, dorsal scales / mane
    mane = 0
    for g in segs:
        J(g["joint"])
        f = frame(g["mid"], g["X"], g["B"], g["T"])
        part("Seg%d" % g["i"], (g["w"], g["t"], g["len"] * 1.22), f, C["HIDE"] if g["i"] % 2 == 0 else C["HIDE2"])
        if g["s"] > s_c - 0.02:
            part("Belly%d" % g["i"], (g["w"] * 0.66, 0.16, g["len"] * 0.98), f * CF((0, -g["t"] / 2 - 0.05, 0)), C["WHITE"], studs=False)
        if g["joint"] == "Head":
            up = (g["B"] * math.cos(math.radians(42)) - g["T"] * math.sin(math.radians(42))).normalized()
            mane += 1
            crystal("Mane%d" % mane, g["mid"] + g["B"] * (g["t"] / 2 - 0.08), up, 0.55 + 0.12 * (mane % 2), 0.22, C["ICE"], C["TIP"], hint=g["X"])
        else:
            h = 0.2 + 0.2 * g["w"]
            wf = frame(g["mid"] + g["B"] * (g["t"] / 2 + h / 2 - 0.03), -g["X"], g["B"], -g["T"])
            part("Dorsal%d" % g["i"], (g["w"] * 0.3, h, g["len"] * 0.8), wf, C["ARMOR"], shape="Wedge", studs=False)

    # tail tip crystal
    J("Coil")
    g0 = segs[0]
    crystal("TailTip", g0["a"] + g0["T"] * 0.1, (-g0["T"] + Vector((0, 0.7, 0))).normalized(), 0.85, 0.3, C["ICE"], C["TIP"], hint=g0["X"])

    def seg_at(s):
        return min(segs, key=lambda g: abs(g["s"] - s))

    # chest frost core
    J("Body")
    gc = seg_at(s_c + (1 - s_c) * 0.62)
    fc = frame(gc["mid"], gc["X"], gc["B"], gc["T"])
    part("CoreFrame", (0.62, 0.1, 0.62), fc * CF((0, -gc["t"] / 2 - 0.15, 0)) * cf(ry=45), C["WHITE"], studs=False)
    part("Core", (0.42, 0.12, 0.42), fc * CF((0, -gc["t"] / 2 - 0.19, 0)) * cf(ry=45), C["EYE"], mat="Neon")

    # arms
    ga = seg_at(s_c + (1 - s_c) * 0.5)
    for sx, side in ((-1, "L"), (1, "R")):
        J("Arm" + side)
        Sd = Vector((sx, 0, 0))
        S = ga["mid"] + Sd * (ga["w"] / 2 - 0.05) - ga["B"] * (ga["t"] * 0.15)
        part("HingeArm" + side, (0.2, 0.2, 0.2), CF(S), C["WHITE"], studs=False, transp=1)
        d1 = (Sd * 0.35 + Vector((0, -0.6, 0)) - ga["B"] * 0.65).normalized()
        E = S + d1 * 0.62
        d2 = (Sd * 0.1 + Vector((0, -0.15, 0)) - ga["B"] * 1.0).normalized()
        Hd = E + d2 * 0.56
        seg("UpperArm" + side, S, E, 0.3, 0.3, C["HIDE"])
        seg("Forearm" + side, E, Hd, 0.26, 0.26, C["HIDE"])
        part("Hand" + side, (0.34, 0.24, 0.36), look(Hd + d2 * 0.08, Vector((0, 1, 0)), -d2), C["ARMOR"], studs=False)
        part("Claws" + side, (0.32, 0.14, 0.22), look(Hd + d2 * 0.3 + Vector((0, -0.04, 0)), Vector((0, 1, 0)), d2), C["FANG"], shape="Wedge", studs=False)

    # head
    J("Head")
    HS = 1.15
    H0 = CF(Vector((0, 5.42, -1.5)), rot_r(-8, 0, 0))

    class _H:
        def point(self, v):
            return H0.point(tuple(c * HS for c in v))

        def vec(self, v):
            return H0.vec(v)

    H = _H()

    def hp(nm, size, pos, hx, rx=0, ry=0, rz=0, **kw):
        return part(nm, tuple(c * HS for c in size), H0 * cf(tuple(c * HS for c in pos), rx, ry, rz), hx, **kw)

    hp("Skull", (1.3, 1.05, 1.4), (0, 0.45, -0.6), C["HIDE"])
    hp("Snout", (1.02, 0.62, 1.2), (0, 0.27, -1.85), C["HIDE"])
    hp("SnoutRidge", (0.46, 0.28, 1.15), (0, 0.72, -1.8), C["ARMOR"], shape="Wedge", studs=False)
    hp("Nose", (0.86, 0.34, 0.22), (0, 0.36, -2.5), C["ARMOR"], studs=False)
    hp("Jaw", (0.9, 0.28, 1.35), (0, -0.12, -1.65), C["WHITE"], rx=-9, studs=False)
    hp("Mouth", (0.84, 0.16, 1.05), (0, -0.01, -1.72), C["SOCKET"], rx=-4, studs=False)
    for sx, side in ((-1, "L"), (1, "R")):
        hp("Nostril" + side, (0.16, 0.1, 0.06), (sx * 0.22, 0.47, -2.62), C["SOCKET"], studs=False)
        hp("Brow" + side, (0.42, 0.3, 0.95), (sx * 0.42, 1.1, -1.0), C["ARMOR"], rz=-sx * 14, shape="Wedge", studs=False)
        hp("Socket" + side, (0.06, 0.34, 0.66), (sx * 0.665, 0.62, -1.0), C["SOCKET"], rx=-16, studs=False)
        hp("Eye" + side, (0.05, 0.26, 0.56), (sx * 0.69, 0.6, -1.02), C["EYE"], rx=-16, mat="Neon")
        hp("Pupil" + side, (0.04, 0.24, 0.09), (sx * 0.715, 0.6, -1.08), C["PUPIL"], rx=-16, studs=False)
        hp("Glint" + side, (0.03, 0.08, 0.08), (sx * 0.725, 0.69, -1.2), "FFFFFF", mat="Neon")
        hp("Fang" + side, (0.15, 0.34, 0.15), (sx * 0.33, -0.02, -2.3), C["FANG"], studs=False)
        hp("Tooth" + side, (0.12, 0.2, 0.12), (sx * 0.38, 0.03, -1.85), C["FANG"], studs=False)
        hp("LowTooth" + side, (0.12, 0.18, 0.12), (sx * 0.26, 0.05, -2.08), C["FANG"], studs=False)
        # antlers: two white beams, a crystal tine and a crystal tip
        b0 = H.point((sx * 0.42, 0.95, -0.25))
        d1 = H.vec((sx * 0.35, 0.85, 0.45)).normalized()
        b1 = b0 + d1 * 1.0
        d2 = H.vec((sx * 0.25, 0.6, 0.85)).normalized()
        b2 = b1 + d2 * 0.85
        seg("Antler" + side, b0, b1 + d1 * 0.08, 0.22, 0.22, C["WHITE"], studs=False)
        seg("AntlerTop" + side, b1, b2, 0.18, 0.18, C["WHITE"], studs=False)
        crystal("Tine" + side, b0 + d1 * 0.55, H.vec((sx * 0.2, 0.9, -0.35)), 0.6, 0.16, C["ICE"], C["TIP"], n=1)
        crystal("AntlerTip" + side, b2 - d2 * 0.05, d2, 0.55, 0.2, C["ICE"], C["TIP"])
        crystal("Tine2" + side, b1 + d2 * 0.4, H.vec((sx * 0.3, 0.85, -0.2)), 0.45, 0.14, C["ICE"], C["TIP"], n=1)
        # cheek frills
        for k in range(2):
            crystal("Frill%s%d" % (side, k + 1), H.point((sx * 0.62, 0.25 + 0.35 * k, -0.4 + 0.12 * k)),
                    H.vec((sx * 0.6, 0.1 + 0.25 * k, 0.8)), 0.8 - 0.12 * k, 0.14, C["ICE"], C["TIP"], n=1)
        # whiskers with a crystal bead
        w0 = H.point((sx * 0.45, 0.32, -2.35))
        wd = H.vec((sx * 0.75, -0.35, 0.55)).normalized()
        w1 = w0 + wd * 0.95
        seg("Whisker" + side, w0, w1, 0.1, 0.1, C["WHITE"], studs=False)
        part("Bead" + side, (0.24, 0.24, 0.24), CF(w1), C["ICE"], mat="Neon", shape="Ball")
    crystal("Crest", H.point((0, 0.98, -0.8)), H.vec((0, 0.85, 0.5)), 0.6, 0.24, C["ICE"], C["TIP"])

    # wings: shoulder -> elbow -> wrist with a bent leading edge, a thumb claw, four fingers fanning back and
    # two-tone glass membranes that stop short of the finger tips (the bones poke past: a scalloped trailing edge)
    gw = seg_at(s_c + (1 - s_c) * 0.72)
    for sx, side in ((-1, "L"), (1, "R")):
        J("Wing" + side)
        Sd = Vector((sx, 0, 0))
        S = gw["mid"] + Sd * (gw["w"] / 2 - 0.05) + gw["B"] * (gw["t"] * 0.3)
        part("Shoulder" + side, (0.4, 0.4, 0.4), CF(S), C["WHITE"], shape="Ball")
        E = S + Vector((sx * 0.55, 0.85, 0.45)).normalized() * 1.05
        Wr = E + Vector((sx * 1.0, 0.35, -0.15)).normalized() * 1.35
        seg("UpperWing" + side, S, E + (E - S).normalized() * 0.1, 0.26, 0.26, C["ARMOR"], studs=False)
        seg("Forewing" + side, E, Wr, 0.22, 0.22, C["ARMOR"], studs=False)
        part("Wrist" + side, (0.32, 0.32, 0.32), CF(Wr), C["WHITE"], shape="Ball")
        crystal("Thumb" + side, Wr, Vector((sx * 0.3, 0.5, -0.8)), 0.42, 0.14, C["ICE"], C["TIP"], n=1)
        fingers = ((0.55, 0.85, 0.25, 1.5), (0.95, 0.2, 0.35, 2.1), (0.7, -0.55, 0.45, 1.95), (0.25, -0.9, 0.4, 1.6))
        edge = []
        for k, (fx, fy, fz, ln) in enumerate(fingers):
            d = Vector((sx * fx, fy, fz)).normalized()
            tip = Wr + d * ln
            seg("Finger%s%d" % (side, k + 1), Wr, tip, 0.15 - 0.01 * k, 0.15 - 0.01 * k, C["ARMOR"], studs=False)
            if k in (1, 2):
                crystal("WingTip%s%d" % (side, k + 1), tip - d * 0.05, d, 0.5, 0.17, C["ICE"], C["TIP"], n=1)
            edge.append(Wr + d * ln * 0.84)
        anchor = S + Vector((sx * 0.05, -1.45, 0.3))
        panels = [(S, E, Wr)] + [(Wr, edge[i], edge[i + 1]) for i in range(3)]
        panels += [(Wr, edge[3], anchor), (S, Wr, anchor)]
        for k, (p0, p1, p2) in enumerate(panels):
            hx_, tr_ = (C["MEM_D"], 0.1) if k % 2 == 1 else (C["MEM_L"], 0.05)
            tri("Membrane%s%d" % (side, k + 1), p0, p1, p2, 0.1, hx_, mat="Glass", transp=tr_)
    J("Root")
    if scale != 1:  # uniform scale about the model's own origin (feet stay on the ground)
        off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
        for ob in coll.objects:
            ob.matrix_world = off @ Matrix.Scale(scale, 4) @ off.inverted() @ ob.matrix_world
    return coll
# Egg: shell layers match Sculpt.eggShell exactly.
EGG_H, EGG_W, EGG_STEP = 4.8, 3.6, 0.55
EGG_SHELL = "4FB0F5"


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


def build_egg(name, offset, palette="glacier"):
    C = PALETTES[palette]
    coll = use(name, offset)
    J("Body")
    H, W = EGG_H, EGG_W
    n = egg_layers(H)
    dh = H / n
    cap_from = 6  # layers 6..n are the frost cap
    for i in range(1, n + 1):
        y = (i - 0.5) * dh
        r = egg_radius(H, W, y)
        part("Shell%d" % i, (r * 2, dh, r * 2), CF((0, y, 0)), C["WHITE"] if i >= cap_from else EGG_SHELL)

    # drip line: the cap's lower edge runs down the blue shell in chunky drips
    y_edge = (cap_from - 1) * dh
    r_out = max(egg_radius(H, W, y_edge - 0.1), egg_radius(H, W, y_edge - dh - 0.1)) + 0.05
    lengths = (0.55, 0.95, 0.45, 0.8, 0.5, 1.05, 0.6, 0.9, 0.4, 0.75, 0.55, 1.0)
    k = 0
    for f in range(4):
        th = math.radians(f * 90)
        nrm = Vector((math.sin(th), 0, -math.cos(th)))
        tan = Vector((math.cos(th), 0, math.sin(th)))
        for j, along in enumerate((-0.95, 0.0, 0.95)):
            ln = lengths[k]
            k += 1
            pos = nrm * r_out + tan * along + Vector((0, y_edge + 0.12 - ln / 2, 0))
            part("Drip%d" % k, (0.5 if j == 1 else 0.42, ln + 0.24, 0.14), frame(pos, tan, Vector((0, 1, 0)), -nrm),
                 C["WHITE"], studs=False)

    # serpent coil wrapping 1.25 turns up the shell, thin to thick, with crystal fins on its back
    pts = []
    M = 60
    for j in range(M + 1):
        u = j / M
        th = math.radians(160) + u * 1.4 * math.tau
        y = 0.5 + u * 3.0
        t = 0.28 + 0.27 * u
        rr = squircle(egg_radius(H, W, y), th) + t / 2 - 0.02
        pts.append(Vector((math.sin(th) * rr, y, -math.cos(th) * rr)))
    sp, fr, _ = resample(pts, 16)
    fin = 0
    for i in range(16):
        a, b = sp[i], sp[i + 1]
        u = (fr[i] + fr[i + 1]) / 2
        t = 0.28 + 0.27 * u
        T = (b - a).normalized()
        B = Vector((0, 1, 0))
        B = (B - T * B.dot(T)).normalized()
        X = B.cross(T)
        f = frame((a + b) / 2, X, B, T)
        part("Coil%d" % (i + 1), (t * 1.15, t, (b - a).length * 1.25), f, C["HIDE"] if i % 2 == 0 else C["HIDE2"])
        if i % 3 == 1:
            fin += 1
            outward = Vector((a.x + b.x, 0, a.z + b.z)).normalized()
            crystal("Fin%d" % fin, (a + b) / 2 + B * (t / 2 - 0.04), (B * 0.8 + outward * 0.5 - T * 0.35).normalized(),
                    0.35 + 0.08 * fin, 0.14, C["ICE"], C["TIP"], n=1)
    T0 = (sp[1] - sp[0]).normalized()
    crystal("CoilTip", sp[0], (-T0 + Vector((0, 0.4, 0))).normalized(), 0.55, 0.22, C["ICE"], C["TIP"])

    # snow line round the base (one studded band, flush: the chase legs sprout under the shell)
    yb = dh * 1.0
    rb = egg_radius(H, W, yb + 0.01) + 0.07
    part("SnowBand", (rb * 2, 0.34, rb * 2), CF((0, yb, 0)), C["WHITE"])

    # crown: two small antlers either side of one central crystal, like the serpent's
    top = H - 0.12
    for sx, side in ((-1, "L"), (1, "R")):
        b0 = Vector((sx * 0.48, top, 0.12))
        d1 = Vector((sx * 0.45, 0.85, 0.25)).normalized()
        b1 = b0 + d1 * 0.7
        seg("EggAntler" + side, b0, b1, 0.16, 0.16, C["WHITE"], studs=False)
        crystal("EggTine" + side, b0 + d1 * 0.38, Vector((sx * 0.2, 0.9, -0.4)), 0.38, 0.12, C["ICE"], C["TIP"], n=1)
        crystal("EggAntlerTip" + side, b1 - d1 * 0.04, d1, 0.4, 0.16, C["ICE"], C["TIP"])
    crystal("Crown", Vector((0, top - 0.05, -0.05)), Vector((0, 1, -0.12)), 1.0, 0.3, C["ICE"], C["TIP"], n=3)
    J("Root")
    return coll
