# Frost Serpent egg (needs fs_lib.py + fs_serpent.py PALETTES). Shell layers match Sculpt.eggShell exactly.
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
    global JOINT
    C = PALETTES[palette]
    use(name, offset)
    JOINT = "Body"
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
    JOINT = "Root"
    return COLL
