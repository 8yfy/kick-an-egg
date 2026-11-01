# Block helpers for the top tiers (Divine, Secret): rings and gears in any plane, spinning hubs, block-feather wings,
# ray manes and block clouds. Roblox primitives only, Roblox axes (+Y up, front -Z). A spinning group's hub is an
# invisible first part whose local Y is the spin axis (Anim/Spin poses the motor about the hub's Y).
import math

from mathutils import Vector

from kit.rbx import CF, J, frame, look


def basis(axis):
    A = Vector(axis).normalized()
    ref = Vector((0, 1, 0)) if abs(A.y) < 0.9 else Vector((0, 0, -1))
    U = (ref - A * ref.dot(A)).normalized()  # 0 degrees points up (or forward for a horizontal ring)
    V = A.cross(U).normalized()
    return A, U, V


def hub(k, joint, centre, axis):
    """Invisible pivot for a spinning group: local Y along `axis`."""
    J(joint)
    A, U, V = basis(axis)
    k.p("Hub" + joint, (0.2, 0.2, 0.2), frame(Vector(centre), V, A, U), "main", transp=1, studs=False)


def ring(k, name, centre, axis, r, n, thick, depth, cols, mat="SmoothPlastic", transp=0.0, phase=0.0, studs=None):
    """n blocks round a circle (plane normal `axis`), each tangent, `thick` along the axis, `depth` radially;
    cols cycles (one hex or palette key per block)."""
    A, U, V = basis(axis)
    c = Vector(centre)
    seg = 2 * r * math.sin(math.pi / n) * 1.08
    out = []
    for i in range(n):
        a = phase + 2 * math.pi * i / n
        radial = U * math.cos(a) + V * math.sin(a)
        p = c + radial * r
        col = cols[i % len(cols)] if isinstance(cols, (list, tuple)) else cols
        f = look(p, A, radial)  # local Y = axis, local Z = radial, local X = tangent
        out.append(k.p("%s%d" % (name, i + 1), (seg, thick, depth), f, col, material=mat, transp=transp, studs=studs))
    return out


def teeth(k, name, centre, axis, r, n, size, col, phase=0.0, mat="SmoothPlastic"):
    """Gear teeth: n blocks standing out radially from a ring of radius r."""
    A, U, V = basis(axis)
    c = Vector(centre)
    for i in range(n):
        a = phase + 2 * math.pi * i / n
        radial = U * math.cos(a) + V * math.sin(a)
        k.p("%s%d" % (name, i + 1), size, look(c + radial * (r + size[2] / 2), A, radial), col, material=mat,
            studs=False)


def gear(k, name, centre, axis, r, n_ring, n_teeth, thick, depth, ring_col, tooth_col, spokes=0, spoke_col=None,
         hub_col=None):
    ring(k, name + "Rim", centre, axis, r, n_ring, thick, depth, ring_col, studs=False)
    teeth(k, name + "Tooth", centre, axis, r + depth / 2, n_teeth, (depth * 0.9, thick * 0.95, depth * 0.8),
          tooth_col)
    A, U, V = basis(axis)
    c = Vector(centre)
    for i in range(spokes):
        a = math.pi * i / spokes
        d = U * math.cos(a) + V * math.sin(a)
        k.p("%sSpoke%d" % (name, i + 1), (depth * 0.6, thick * 0.8, 2 * r), look(c, A, d), spoke_col or ring_col,
            studs=False)
    if hub_col:
        k.p(name + "Hub", (depth * 1.6, thick * 1.3, depth * 1.6), look(c, A, U), hub_col, studs=False)


def feather_wing(k, sx, sd, root, arm=(1.1, 1.0), spread=(0.95, 0.75, 0.3), lift=(0.7, 1.0, 0.1), n=8, length=2.4,
                 width=0.42, cols=("light",), tip=None, tip_n=4, coverts=None, bone="light", fan=(-0.15, -0.95),
                 mat="SmoothPlastic", transp=0.0, tag="", p_dir=None, s_dir=None, tip_mat=None):
    """Raised block-feather wing for one side (WingL/WingR group): shoulder ball (the pivot), upper arm to the elbow,
    forearm to the wrist, `n` feathers fanning from the wrist (primaries, longest) towards the elbow (secondaries),
    optional coloured tips on the outer primaries and a row of shorter coverts over the arm."""
    J("Wing" + sd)
    S = Vector(root)
    E = S + Vector((sx * spread[0], spread[1], spread[2])).normalized() * arm[0]
    W = E + Vector((sx * lift[0], lift[1], lift[2])).normalized() * arm[1]
    if not tag or tag == "A":
        k.p("Shoulder" + sd, (0.36, 0.36, 0.36), CF(S), bone, shape="Ball")
    k.seg("UpperWing%s%s" % (sd, tag), S, E + (E - S).normalized() * 0.08, 0.3, 0.3, bone)
    k.seg("Forewing%s%s" % (sd, tag), E, W + (W - E).normalized() * 0.08, 0.26, 0.26, bone)
    N = (E - S).cross(W - E).normalized()
    if N.z < 0:
        N = -N  # feather planes face backwards-ish so the fan reads from the front three-quarter
    # primaries (at the wrist) point along p_dir, secondaries (towards the elbow) along s_dir; x mirrored per side
    pd = p_dir or (0.55, 1.0, 0.15)
    sd_ = s_dir or (0.6 + fan[0], fan[1], 0.55)
    up_out = Vector((sx * pd[0], pd[1], pd[2])).normalized()
    down_out = Vector((sx * sd_[0], sd_[1], sd_[2])).normalized()
    for i in range(n):
        t = i / max(1, n - 1)
        base = W.lerp(E, t * 0.95)
        d = up_out.lerp(down_out, t).normalized()
        ln = length * (1 - 0.42 * t)
        c = look(base + d * (ln / 2 - 0.05), d, N)
        col = cols[i % len(cols)]
        k.p("Feather%s%s%d" % (sd, tag, i + 1), (width, ln, 0.12), c, col, material=mat, transp=transp)
        if tip and i < tip_n:
            k.p("FeatherTip%s%s%d" % (sd, tag, i + 1), (width * 1.02, ln * 0.24, 0.13),
                look(base + d * (ln * 0.88), d, N), tip, material=tip_mat or mat, transp=0 if tip_mat else transp,
                studs=False)
    if coverts:
        for i in range(coverts[0]):
            t = (i + 0.5) / coverts[0]
            base = W.lerp(S, t * 0.9) + N * -0.08
            d = up_out.lerp(down_out, 0.35 + 0.5 * t).normalized()
            ln = coverts[1] * (1 - 0.3 * t)
            k.p("Covert%s%s%d" % (sd, tag, i + 1), (width * 1.15, ln, 0.14), look(base + d * ln / 2, d, N),
                coverts[2], studs=False)
    return S, E, W


def ray_mane(k, name, centre, fwd, r0, r1, n, back, cols, width=0.55, thick=0.16, phase=0.0, tilt=0.0):
    """Sun-ray mane: n flat triangles (two wedges each) radiating round `centre` in the plane facing `fwd`, their
    tips swept `back` so the mane is a shallow cone (reads from the side as well)."""
    F = Vector(fwd).normalized()
    A, U, V = basis(F)
    c = Vector(centre)
    for i in range(n):
        a = phase + 2 * math.pi * i / n
        da = width / max(r0, 0.1) / 2
        p0 = c + (U * math.cos(a - da) + V * math.sin(a - da)) * r0
        p1 = c + (U * math.cos(a + da) + V * math.sin(a + da)) * r0
        rad = U * math.cos(a + tilt) + V * math.sin(a + tilt)
        tipp = c + rad * r1 - F * back
        k.tri("%s%d" % (name, i + 1), p0, p1, tipp, thick, cols[i % len(cols)])


def cloud(k, name, centre, puffs, cols=("light",)):
    """Block cloud: puffs = [(dx, dy, dz, w, h, d, turn)] chunky blocks round a centre, turned 0/45 degrees."""
    c = Vector(centre)
    for i, (dx, dy, dz, w, h, d, turn) in enumerate(puffs):
        f = CF(c + Vector((dx, dy, dz)))
        if turn:
            from kit.rbx import cf
            f = f * cf(ry=turn)
        k.p("%s%d" % (name, i + 1), (w, h, d), f, cols[i % len(cols)])


# ---- emblems and dense brick detail (top-tier references, 2026-10-31) -------------------------------------------
def plane_frame(centre, normal, up=(0, 1, 0)):
    """Frame at `centre` whose local Z points along `normal` (out of the emblem), local Y as close to `up` as
    possible: emblems are drawn in its local XY plane."""
    N = Vector(normal).normalized()
    U = Vector(up)
    U = (U - N * U.dot(N))
    if U.length < 1e-4:
        U = Vector((0, 0, 1)) - N * N.z
    U.normalize()
    X = U.cross(N).normalized()
    return frame(Vector(centre), X, U, N)


def star4(k, name, centre, normal, size, col, up=(0, 1, 0), core=None, mat="Neon", thick=0.12, rot=0.0):
    """Four-point star facing `normal`: a diamond core and four pointed rays (two wedges each)."""
    from kit.rbx import cf
    f = plane_frame(centre, normal, up) * cf(rz=rot)
    w = size * 0.2
    for i in range(4):
        a = math.pi / 2 * i
        dx, dy = math.cos(a), math.sin(a)
        px, py = -dy, dx
        b1 = f.point((px * w, py * w, 0))
        b2 = f.point((-px * w, -py * w, 0))
        tip = f.point((dx * size, dy * size, 0))
        k.tri("%s%d" % (name, i + 1), b1, b2, tip, thick, col, material=mat)
    k.p(name + "Core", (w * 2.2, w * 2.2, thick * 1.3), f * cf(rz=45), core or col, material=mat)


def diamond_frame(k, name, centre, normal, r, col, up=(0, 1, 0), bar=0.14, thick=0.16):
    """Square frame turned 45 degrees (a diamond outline) round an emblem: four bars."""
    from kit.rbx import cf
    f = plane_frame(centre, normal, up)
    side = r * math.sqrt(2)
    for i in range(4):
        a = math.pi / 4 + math.pi / 2 * i
        m = (math.cos(a) * r / math.sqrt(2) * 1.0, math.sin(a) * r / math.sqrt(2) * 1.0, 0)
        k.p("%s%d" % (name, i + 1), (side + bar, bar, thick), f * CF(m) * cf(rz=math.degrees(a) + 90), col,
            studs=False)


def shingles(k, name, centre, radii, rows, cols, size=0.8, thick=0.15, face=(0, 0, -1), window=55, tilt=0.45,
             skip=None, mat_fn=None, flow_back=0.0):
    """Scale/feather field on an ellipsoid (the lion mane): rows = [(elevation_deg, count)], diamonds tangent to
    the surface with one corner hanging down the dome, the lower corner lifted outward by `tilt`; directions within
    `window` degrees of `face` are left open (the face). cols(row, j) picks each plate's colour."""
    from kit.rbx import cf
    c = Vector(centre)
    rx, ry, rz = radii
    F = Vector(face).normalized()
    n_out = 0
    for ri, (el, cnt) in enumerate(rows):
        e = math.radians(el)
        for j in range(cnt):
            az = 2 * math.pi * j / cnt + (math.pi / cnt if ri % 2 else 0.0)
            d = Vector((math.sin(az) * math.cos(e), math.sin(e), math.cos(az) * math.cos(e)))
            if math.degrees(d.angle(F)) < window or (skip and skip(d)):
                continue
            p = c + Vector((d.x * rx, d.y * ry, d.z * rz))
            n = Vector((d.x / rx, d.y / ry, d.z / rz)).normalized()
            want = Vector((0, -1, 0)) * (1 - flow_back) - F * flow_back  # down, or away from the face
            down = want - n * want.dot(n)
            if down.length < 1e-3:
                down = Vector((d.x, 0, d.z))
            down.normalize()
            up = (n - down * tilt).normalized()
            fr = look(p + down * size * 0.32 + n * thick, up, down) * cf(ry=45)
            col = cols(ri, j)
            k.p("%s%d_%d" % (name, ri + 1, j + 1), (size, thick, size), fr, col,
                material=mat_fn(ri, j) if mat_fn else "SmoothPlastic", studs=False)
            n_out += 1
    return n_out


def clock(k, name, centre, normal, r, face_col, rim_col, tick_col, hand_col, ticks=12, glow=False, up=(0, 1, 0),
          hands=(-60, 40), rim_n=16, hands_joint=None, back_to=None):
    """Clock face: a disc (Neon if glow), a rim ring, hour ticks and two hands. `hands_joint` puts the hands on their
    own joint (a hinge at the clock centre) so Anim can turn them; `back_to` is the joint to resume afterwards."""
    from kit.rbx import cf
    f = plane_frame(centre, normal, up)
    k.p(name + "Face", (r * 2, r * 2, 0.08), f, face_col, material="Neon" if glow else "SmoothPlastic", studs=False)
    ring(k, name + "Rim", f.point((0, 0, 0.02)), f.vec((0, 0, 1)), r, rim_n, 0.16, 0.16, rim_col, studs=False)
    for i in range(ticks):
        a = 2 * math.pi * i / ticks
        ln = 0.22 if i % 3 == 0 else 0.12
        k.p("%sTick%d" % (name, i + 1), (0.05 + 0.03 * (i % 3 == 0), ln * r, 0.06),
            f * CF((math.sin(a) * r * 0.78, math.cos(a) * r * 0.78, 0.06)) * cf(rz=-math.degrees(a)), tick_col,
            studs=False)
    if hands_joint:
        k.hinge(hands_joint, f.p)
    for i, (deg, ln) in enumerate(((hands[0], 0.5), (hands[1], 0.72))):
        a = math.radians(deg)
        k.p("%sHand%d" % (name, i + 1), (0.07, ln * r, 0.05),
            f * CF((math.sin(a) * ln * r / 2, math.cos(a) * ln * r / 2, 0.1)) * cf(rz=-deg), hand_col, studs=False)
    if hands_joint and back_to:
        J(back_to)


def small_gear(k, name, centre, axis, r, col, tooth_col=None, depth=0.14):
    """Cheap gear that reads at a distance: a disc and two crossed tooth bars (four parts)."""
    A, U, V = basis(axis)
    c = Vector(centre)
    k.p(name, (depth, r * 2, r * 2), frame(c, A, U, V), col, shape="Cylinder", studs=False)
    for i, ang in enumerate((0, 45, 90, 135)):
        a = math.radians(ang)
        d = U * math.cos(a) + V * math.sin(a)
        k.p("%sT%d" % (name, i + 1), (r * 0.42, depth * 0.9, r * 2.5), look(c, A, d), tooth_col or col, studs=False)


def spire(k, name, base, h, w, col, tip_col=None, up=(0, 1, 0)):
    """Stepped spire: a square shaft turned 45 degrees and a thinner pointed tip."""
    from kit.rbx import cf
    U = Vector(up).normalized()
    b = Vector(base)
    k.p(name, (w, h * 0.6, w), look(b + U * h * 0.3, U, (0, 0, -1)) * cf(ry=45), col)
    k.p(name + "Tip", (w * 0.55, h * 0.45, w * 0.55), look(b + U * h * 0.8, U, (0, 0, -1)) * cf(ry=45),
        tip_col or col, studs=False)


def banner(k, name, top, normal, w, h, col, trim, emblem=None, emblem_col=None, up=(0, 1, 0)):
    """Hanging cloth banner: a panel, gold side trims, a V-cut bottom (two triangles) and an optional gear emblem."""
    f = plane_frame(top, normal, up)
    k.p(name, (w, h, 0.07), f * CF((0, -h / 2, 0)), col, studs=False)
    for sx in (-1, 1):
        k.p("%sTrim%s" % (name, "L" if sx < 0 else "R"), (0.08, h, 0.09), f * CF((sx * (w / 2 - 0.02), -h / 2, 0.01)),
            trim, studs=False)
    k.tri(name + "Tip", f.point((-w / 2, -h, 0)), f.point((w / 2, -h, 0)), f.point((0, -h - w * 0.5, 0)), 0.07, col)
    if emblem:
        small_gear(k, name + "Emblem", f.point((0, -h * 0.45, 0.05)), f.vec((0, 0, 1)), w * 0.28, emblem_col or trim)
