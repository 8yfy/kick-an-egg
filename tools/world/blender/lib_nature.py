# Shared nature kit: chunky, beveled, faceted Roblox-style vegetation, rocks and terrain modules.
# Every generator takes (name, seed, **params) and returns a kit.Asset (the caller builds it). Origin = base centre on
# the ground; parts dip ~0.4 below 0 so placements on uneven banks never float. Colour roles are recoloured per zone.
# Front = -Y (Roblox -Z).
import math

import bmesh
from mathutils import Matrix, Vector

import kit


def R(a, lo, hi):
    return a.rng.uniform(lo, hi)


def canopy_layer(a, role, center, w, h, n, spread, bevel, tilt=0.12):
    """One canopy layer: n overlapping beveled boxes around `center` (w footprint, h thick)."""
    for i in range(n):
        ang = 2 * math.pi * i / max(n, 1) + R(a, -0.4, 0.4)
        off = Vector((0, 0, 0)) if i == 0 else Vector((math.cos(ang) * spread * R(a, 0.7, 1.0), math.sin(ang) * spread * R(a, 0.7, 1.0), R(a, -h * 0.2, h * 0.15)))
        s = 1.0 if i == 0 else R(a, 0.62, 0.82)
        kit.box(
            a,
            role,
            Vector(center) + off,
            (w * s, w * s * R(a, 0.85, 1.1), h * R(a, 0.85, 1.1)),
            rot=(R(a, -tilt, tilt), R(a, -tilt, tilt), R(a, 0, math.pi / 2)),
            bevel=bevel,
        )


def trunk(a, height, width, lean=(0, 0), flares=4, role="Trunk"):
    kit.block(a, role, (0, 0, -0.4), (width, width, height + 0.4), rot=(lean[0], lean[1], R(a, 0, 1.5)), bevel=min(0.18, width * 0.1), taper=0.72)
    for i in range(flares):
        ang = i * 2 * math.pi / flares + R(a, -0.3, 0.3)
        kit.block(a, role, (math.cos(ang) * width * 0.45, math.sin(ang) * width * 0.45, -0.4), (width * 0.95, width * 0.42, 1.4), rot=(0, 0, ang), bevel=0.08, taper=0.35)


def tree_round(name, seed, height=16.0, width=12.0, tw=1.9, layers=3, branch=True):
    """Broadleaf tree: thick tapered trunk with root flares and a side branch, then a layered chunky canopy:
    a wide dark skirt of soft beveled blocks, a mid layer and a small light crown (rounded overall silhouette)."""
    a = kit.Asset(name, seed)
    th = height * 0.4
    trunk(a, th, tw)
    if branch:
        ang = R(a, 0, 2 * math.pi)
        kit.block(a, "Trunk", (math.cos(ang) * tw * 0.15, math.sin(ang) * tw * 0.15, th * 0.5), (tw * 0.5, tw * 0.5, th * 0.7), rot=(-math.sin(ang) * 0.85, math.cos(ang) * 0.85, 0), bevel=0.08, taper=0.6)
    base = th * 0.88
    ch = height - base
    roles = ["LeafDark", "Leaf", "LeafLight"]
    plan = [(1.0, 0.42, 6), (0.74, 0.36, 4), (0.42, 0.28, 2)][:layers]
    z = base
    for li, (wf, hf, n) in enumerate(plan):
        w = width * wf
        lh = ch * hf
        zc = z + lh * 0.5
        # centre block
        kit.box(a, roles[li], (R(a, -0.3, 0.3), R(a, -0.3, 0.3), zc), (w * 0.62, w * 0.62, lh), rot=(0, 0, R(a, 0, 1.5)), bevel=min(lh, w * 0.62) * 0.2, taper=0.86)
        for i in range(n - 1):
            ang = 2 * math.pi * i / (n - 1) + R(a, -0.3, 0.3)
            rr = w * R(a, 0.26, 0.32)
            s = w * R(a, 0.36, 0.46)
            hh = lh * R(a, 0.7, 0.9)
            kit.box(a, roles[li], (math.cos(ang) * rr, math.sin(ang) * rr, zc - lh * R(a, 0.05, 0.22)), (s, s * R(a, 0.85, 1.1), hh), rot=(R(a, -0.1, 0.1), R(a, -0.1, 0.1), R(a, 0, 1.5)), bevel=min(hh, s) * 0.2, taper=0.84)
        z += lh * 0.78
    return a


def tree_ball(name, seed, height=15.0, width=11.0, tw=1.7, balls=3):
    """Low-poly broadleaf with faceted ball canopies (2-3 stacked/offset), dark below and light on top."""
    a = kit.Asset(name, seed)
    th = height * 0.42
    trunk(a, th, tw)
    r0 = width / 2
    centers = [(0, 0, th + r0 * 0.55, r0, "LeafDark"), (R(a, -1, 1) * r0 * 0.35, R(a, -1, 1) * r0 * 0.35, th + r0 * 1.15, r0 * 0.78, "Leaf"), (R(a, -1, 1) * r0 * 0.25, R(a, -1, 1) * r0 * 0.25, th + r0 * 1.6, r0 * 0.5, "LeafLight")]
    for x, y, z, r, role in centers[:balls]:
        kit.blob(a, role, (x, y, z), r, scale=(1, 1, 0.82), subdiv=1, jitter=0.1, rot=(0, 0, R(a, 0, 3)))
    return a


def tree_tall(name, seed, height=20.0, width=7.0, tw=1.1):
    """Columnar poplar: short trunk, stacked narrowing canopy blocks."""
    a = kit.Asset(name, seed)
    trunk(a, height * 0.3, tw, flares=3)
    z = height * 0.2
    n = 4
    seg = (height - z) / (n + 0.3)
    for i in range(n):
        w = width * (1 - 0.17 * i) * R(a, 0.92, 1.05)
        kit.block(a, "LeafDark" if i % 2 == 0 else "Leaf", (R(a, -0.25, 0.25), R(a, -0.25, 0.25), z + i * seg * 0.95), (w, w * R(a, 0.85, 1.0), seg * 1.2), rot=(0, 0, R(a, 0, 1.5)), bevel=0.3, taper=0.82)
    kit.block(a, "LeafLight", (0, 0, z + n * seg * 0.95 - seg * 0.1), (width * 0.4, width * 0.4, seg * 0.7), rot=(0, 0, 0.6), bevel=0.2, taper=0.55)
    return a


def pine(name, seed, height=18.0, width=10.0, tiers=5, snow=False):
    """Blocky pine: stacked square frustum tiers, alternately rotated 45 deg, dark/mid tones, pointed top.
    snow=True adds a Snow cap and lip on every tier."""
    a = kit.Asset(name, seed)
    trunk(a, height * 0.24, 1.3, flares=3)
    z = height * 0.15
    seg = (height - z) / (tiers + 0.7)
    for i in range(tiers):
        t = i / max(tiers - 1, 1)
        w = width * (1 - 0.7 * t)
        rot = (i % 2) * math.pi / 4 + R(a, -0.08, 0.08)
        h = seg * 1.5
        kit.frustum_rect(a, "LeafDark" if i % 2 == 0 else "Leaf", (0, 0, z + i * seg), w, w, w * 0.4, w * 0.4, h, rot=(0, 0, rot))
        if snow:
            sw = w * 0.4 * 1.08
            kit.frustum_rect(a, "Snow", (0, 0, z + i * seg + h - 0.05), sw, sw, sw * 0.7, sw * 0.7, 0.6, rot=(0, 0, rot))
            kit.frustum_rect(a, "Snow", (0, 0, z + i * seg + h * 0.38), w * 0.82, w * 0.82, w * 0.6, w * 0.6, h * 0.2, rot=(0, 0, rot))
    top = z + tiers * seg
    kit.frustum_rect(a, "Snow" if snow else "LeafLight", (0, 0, top - seg * 0.2), width * 0.22, width * 0.22, 0.0001, 0.0001, seg * 1.5, rot=(0, 0, 0.3))
    return a


def bush(name, seed, width=6.0, height=3.6, n=5, flowers=0):
    a = kit.Asset(name, seed)
    for i in range(n):
        ang = 2 * math.pi * i / n + R(a, -0.5, 0.5)
        r = 0 if i == 0 else width * 0.3 * R(a, 0.6, 1.0)
        s = width * (0.56 if i == 0 else R(a, 0.34, 0.46))
        hh = height * (1.0 if i == 0 else R(a, 0.55, 0.85))
        kit.block(a, "Leaf" if i % 2 == 0 else "LeafDark", (math.cos(ang) * r, math.sin(ang) * r, -0.4), (s, s * R(a, 0.8, 1.1), hh + 0.4), rot=(0, 0, R(a, 0, 1.5)), bevel=min(0.35, s * 0.12), taper=0.82)
    kit.block(a, "LeafLight", (R(a, -0.4, 0.4), R(a, -0.4, 0.4), height * 0.7), (width * 0.3, width * 0.3, height * 0.42), rot=(0, 0, 0.7), bevel=0.15, taper=0.65)
    for i in range(flowers):
        ang = R(a, 0, 2 * math.pi)
        r = width * R(a, 0.22, 0.4)
        z = height * R(a, 0.5, 0.92)
        kit.box(a, "Accent" if i % 2 == 0 else "Accent2", (math.cos(ang) * r, math.sin(ang) * r, z), (0.6, 0.6, 0.6), rot=(0.3, 0.2, ang), bevel=0.07)
    return a


def boulder(a, role, base, half, n=12, flat=0.35, rot_z=0.0, squash=1.0):
    """Faceted convex boulder (hull of random points in an ellipsoid) standing on `base`; `half` = half extents."""
    bm = a.bm(role)
    pts = []
    for _ in range(n):
        u = R(a, -1, 1)
        th = R(a, 0, 2 * math.pi)
        s = math.sqrt(max(0.0, 1 - u * u))
        r = R(a, 0.8, 1.0)
        p = Vector((s * math.cos(th) * r, s * math.sin(th) * r, u * r * squash))
        p.z = max(p.z, -flat)
        pts.append(p)
    for k in range(5):
        th = 2 * math.pi * k / 5 + R(a, -0.3, 0.3)
        pts.append(Vector((math.cos(th) * 0.92, math.sin(th) * 0.92, -flat)))
    verts = [bm.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(bm, input=verts)
    for v in res.get("geom_unused", []) + res.get("geom_interior", []):
        if isinstance(v, bmesh.types.BMVert) and v.is_valid:
            bm.verts.remove(v)
    allv = [v for v in verts if v.is_valid]
    m = Matrix.Translation(Vector(base) + Vector((0, 0, flat * half[2]))) @ Matrix.Rotation(rot_z, 4, "Z") @ Matrix.Diagonal((half[0], half[1], half[2], 1))
    kit._xf(bm, allv, m)
    return allv


def rock(name, seed, size=(6, 5, 4), extra=2):
    a = kit.Asset(name, seed)
    boulder(a, "Stone", (0, 0, -0.5), (size[0] / 2, size[1] / 2, size[2] / 2), n=16, rot_z=R(a, 0, 3))
    for i in range(extra):
        ang = R(a, 0, 2 * math.pi)
        s = R(a, 0.32, 0.5)
        boulder(a, "StoneDark", (math.cos(ang) * size[0] * 0.48, math.sin(ang) * size[1] * 0.48, -0.4), (size[0] * s / 2, size[1] * s / 2, size[2] * s / 2.2), n=9, rot_z=R(a, 0, 3))
    return a


def slab_stack(name, seed, w=10, d=8, h=6, layers=3):
    """Stacked, offset, beveled stone slabs (strata): sandstone ledges, stepped outcrops."""
    a = kit.Asset(name, seed)
    z = -0.5
    lh = (h + 0.5) / layers
    for i in range(layers):
        s = 1 - 0.17 * i
        kit.block(a, "Stone" if i % 2 == 0 else "StoneDark", (R(a, -0.6, 0.6), R(a, -0.6, 0.6), z), (w * s * R(a, 0.9, 1.05), d * s * R(a, 0.9, 1.05), lh), rot=(0, 0, R(a, -0.15, 0.15)), bevel=0.35, taper=0.94)
        z += lh * 0.97
    return a


def bank(name, seed, length=28.0, depth=18.0, height=8.0, tiers=2, drips=True):
    """Terrain bank module for the valley sides. Runs along local X (length); the face toward the track is local
    -Y (front); it climbs in `tiers` steps toward +Y. Stone body in two strata bands, a Ground cap slab with an
    irregular lip of drips over each front face."""
    a = kit.Asset(name, seed)
    y0 = -depth / 2
    td = depth / tiers
    for t in range(tiers):
        h = height * (t + 1) / tiers
        dd = depth - td * t
        yc = y0 + td * t + dd / 2
        band = h * 0.5
        kit.block(a, "Stone", (R(a, -0.4, 0.4), yc + 0.2, -0.8), (length * R(a, 0.95, 0.99), dd - 0.4, band + 0.8), bevel=0.45)
        kit.block(a, "StoneDark", (R(a, -0.4, 0.4), yc + 0.35, band - 0.05), (length * R(a, 0.92, 0.97), dd - 0.7, h - band - 1.0), bevel=0.45)
        cap = 1.3
        kit.block(a, "Ground", (0, yc - 0.25, h - cap + 0.1), (length + 0.4, dd + 0.6, cap), bevel=0.4)
        if drips:
            x = -length / 2 + R(a, 0.8, 2.0)
            while x < length / 2 - 1.2:
                dw = R(a, 1.4, 3.0)
                dh = R(a, 0.7, 2.2)
                kit.block(a, "Ground", (x + dw / 2, yc - dd / 2 - 0.15, h - cap - dh + 0.35), (dw, 0.8, dh), bevel=0.22)
                x += dw + R(a, 0.6, 2.8)
    return a


def mound(name, seed, w=60, d=50, h=18, n=26, rocks=3):
    """Big low-poly hill (faceted hull), Ground role, with a few Stone outcrops."""
    a = kit.Asset(name, seed)
    boulder(a, "Ground", (0, 0, -1.5), (w / 2, d / 2, h / 1.55), n=n, flat=0.1)
    for i in range(rocks):
        ang = R(a, 0, 2 * math.pi)
        r = R(a, 0.35, 0.62)
        boulder(a, "Stone", (math.cos(ang) * w * r * 0.5, math.sin(ang) * d * r * 0.5, h * (1 - r) * 0.5 - 1.5), (R(a, 3, 6), R(a, 3, 5), R(a, 2.5, 4)), n=9)
    return a


def _peak(a, role, base, w, d, h, snow, snow_role="Snow"):
    rings = ((0.0, 1.0, 9), (0.34, 0.72, 8), (0.66, 0.38, 6))
    apex = Vector((R(a, -0.1, 0.1), R(a, -0.1, 0.1), 1.0))
    ring_pts = []
    for ri, (rz, rr, n) in enumerate(rings):
        rp = []
        for k in range(n):
            th = 2 * math.pi * k / n + R(a, -0.25, 0.25) + ri * 0.7
            r = rr * R(a, 0.82, 1.06)
            rp.append(Vector((math.cos(th) * r, math.sin(th) * r, rz + (R(a, -0.04, 0.04) if ri else 0))))
        ring_pts.append(rp)
    m = Matrix.Translation(Vector(base) + Vector((0, 0, -2))) @ Matrix.Diagonal((w / 2, d / 2, h + 2, 1))
    bm = a.bm(role)
    vs = [bm.verts.new(p) for p in [apex] + ring_pts[0] + ring_pts[1] + ring_pts[2]]
    res = bmesh.ops.convex_hull(bm, input=vs)
    kit._xf(bm, [v for v in vs if v.is_valid], m)
    if snow > 0:
        cut = 1 - snow
        t = max(0.0, min(1.0, (cut - 0.34) / (0.66 - 0.34)))
        cap = [apex]
        for p in ring_pts[2]:
            if p.z >= cut:
                cap.append(Vector((p.x * 1.05, p.y * 1.05, p.z)))
        shrink = 1 + (0.38 / 0.72 - 1) * t
        for p in ring_pts[1]:
            cap.append(Vector((p.x * shrink * 1.06, p.y * shrink * 1.06, cut - R(a, 0.0, 0.05))))
        sb = a.bm(snow_role)
        cv = [sb.verts.new(p) for p in cap]
        bmesh.ops.convex_hull(sb, input=cv)
        kit._xf(sb, [v for v in cv if v.is_valid], Matrix.Translation(Vector(base) + Vector((0, 0, -2))) @ Matrix.Diagonal((w / 2, d / 2, (h + 2) * 1.008, 1)))


def mountain(name, seed, w=140, d=110, h=90, snow=0.4, peaks=3):
    """A faceted massif: one main peak and 1-2 lower shoulder peaks, each with a Snow cap (snow=0 for none)."""
    a = kit.Asset(name, seed)
    _peak(a, "Stone", (0, 0, 0), w * 0.62, d * 0.75, h, snow)
    for i in range(peaks - 1):
        side = -1 if i == 0 else 1
        _peak(a, "StoneDark" if i == 0 else "Stone", (side * w * R(a, 0.22, 0.3), R(a, -d * 0.12, d * 0.12), 0), w * R(a, 0.4, 0.5), d * R(a, 0.5, 0.65), h * R(a, 0.5, 0.7), snow * 0.8 if snow > 0 else 0)
    return a


def flowers(name, seed, n=7, radius=1.6, height=1.6):
    a = kit.Asset(name, seed)
    for i in range(3):
        ang = R(a, 0, 2 * math.pi)
        kit.block(a, "LeafDark", (math.cos(ang) * 0.5, math.sin(ang) * 0.5, -0.3), (1.3, 0.65, 1.0), rot=(0.25, 0, ang), bevel=0.08, taper=0.45)
    for i in range(n):
        ang = 2 * math.pi * i / n + R(a, -0.4, 0.4)
        r = radius * R(a, 0.2, 1.0)
        h = height * R(a, 0.6, 1.0)
        x, y = math.cos(ang) * r, math.sin(ang) * r
        kit.block(a, "Leaf", (x, y, -0.3), (0.2, 0.2, h + 0.3))
        role = "Accent" if i % 3 else "Accent2"
        rz = R(a, 0, 1.5)
        kit.box(a, role, (x, y, h), (1.0, 0.42, 0.3), rot=(0, 0, rz))
        kit.box(a, role, (x, y, h), (0.42, 1.0, 0.3), rot=(0, 0, rz))
        kit.box(a, "Glow", (x, y, h + 0.12), (0.34, 0.34, 0.3), rot=(0, 0, rz))
    return a


def grass(name, seed, n=7, height=1.8, radius=0.9):
    a = kit.Asset(name, seed)
    for i in range(n):
        ang = 2 * math.pi * i / n + R(a, -0.3, 0.3)
        r = radius * R(a, 0.1, 1.0)
        h = height * R(a, 0.6, 1.0)
        kit.frustum_rect(a, "Leaf" if i % 2 else "LeafDark", (math.cos(ang) * r, math.sin(ang) * r, -0.3), 0.55, 0.34, 0.1, 0.07, h + 0.3, rot=(math.sin(ang) * 0.35, -math.cos(ang) * 0.35, ang))
    return a
