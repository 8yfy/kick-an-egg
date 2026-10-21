"""Original particle / beam textures for the world weather VFX (VFX/WeatherFx), drawn procedurally.
Greyscale + alpha (tinted per emitter in game) unless the name says otherwise (wx_prism is pre-coloured).
Run with Blender's bundled Python (it has numpy):
  "<Blender>/5.2/python/bin/python.exe" -I tools/weather/sprites.py <out_textures_dir> <out_flipbooks_dir>
Particles are 128 px, beams 256 px (U = along the beam, tileable), the flipbook is a 2x2 grid of 128 px frames."""

import math
import os
import struct
import sys
import zlib

import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 else "Custom_VFX_Textures"
OUT_FLIP = sys.argv[2] if len(sys.argv) > 2 else OUT
os.makedirs(OUT, exist_ok=True)
os.makedirs(OUT_FLIP, exist_ok=True)


def save(folder, name, rgba):
    rgba = np.clip(rgba, 0, 1)
    img = (rgba * 255 + 0.5).astype(np.uint8)
    h, w = img.shape[:2]
    raw = b"".join(b"\x00" + img[y].tobytes() for y in range(h))

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )
    with open(os.path.join(folder, f"{name}.png"), "wb") as f:
        f.write(png)


def grid(s):
    yy, xx = np.mgrid[0:s, 0:s].astype(np.float32)
    c = (s - 1) / 2
    x = (xx - c) / (s / 2)  # -1..1, right
    y = -(yy - c) / (s / 2)  # -1..1, up
    return x, y


def smooth(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def seg(x, y, ax, ay, bx, by):
    """Distance from every pixel to the segment a-b."""
    dx, dy = bx - ax, by - ay
    t = np.clip(((x - ax) * dx + (y - ay) * dy) / max(dx * dx + dy * dy, 1e-9), 0, 1)
    return np.hypot(x - (ax + t * dx), y - (ay + t * dy))


def polyline(x, y, pts):
    d = np.full(x.shape, 9.0, np.float32)
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        d = np.minimum(d, seg(x, y, ax, ay, bx, by))
    return d


def inside(x, y, pts):
    """Even-odd polygon fill."""
    res = np.zeros(x.shape, bool)
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        cond = (y1 > y) != (y2 > y)
        xi = x1 + (y - y1) * (x2 - x1) / ((y2 - y1) if y2 != y1 else 1e-9)
        res ^= cond & (x < xi)
    return res


def soft_poly(x, y, pts, feather):
    """Polygon alpha with an anti-aliased / soft edge of width `feather`."""
    edge = polyline(x, y, list(pts) + [pts[0]])
    inn = inside(x, y, pts)
    return np.where(inn, smooth(0, feather, edge) * 0.5 + 0.5, 0.5 - smooth(0, feather, edge) * 0.5)


def rgba(value, alpha, tint=(1.0, 1.0, 1.0)):
    out = np.zeros(alpha.shape + (4,), np.float32)
    v = np.clip(value, 0, 1)
    for i in range(3):
        out[..., i] = v * tint[i]
    out[..., 3] = np.clip(alpha, 0, 1)
    return out


# Particles ------------------------------------------------------------------------------------------------------
S = 128
X, Y = grid(S)
R = np.hypot(X, Y)
A = np.arctan2(Y, X)


def raindrop():
    # a thin streak (faint top -> bright bottom) ending in a round bead: reads as a fast drop at small sizes
    d = seg(X, Y, 0, 0.92, 0, -0.55)
    ramp = smooth(0.95, -0.55, Y)  # 0 at the top, 1 at the bottom
    streak = (1 - smooth(0.035, 0.085, d)) * (0.15 + 0.85 * ramp)
    bead = 1 - smooth(0.13, 0.2, np.hypot(X, (Y + 0.66) * 0.85))
    alpha = np.maximum(streak, bead)
    shine = 1 - smooth(0.0, 0.07, np.hypot(X + 0.05, Y + 0.6))
    value = 0.82 + 0.18 * np.maximum(shine, ramp * 0.6)
    return rgba(value, alpha)


def glitter():
    # faceted diamond + 8-ray flare; top-left facets lighter so a gold tint shows depth
    diamond = np.abs(X) + np.abs(Y)
    body = 1 - smooth(0.36, 0.42, diamond)
    facet = np.where((X < 0) ^ (Y < 0), 0.78, 1.0)
    facet = np.where((X < 0) & (Y > 0), 1.0, np.where((X > 0) & (Y < 0), 0.62, facet))
    long_rays = np.maximum(np.exp(-(X / 0.035) ** 2) * (1 - smooth(0.2, 0.98, np.abs(Y))),
                           np.exp(-(Y / 0.035) ** 2) * (1 - smooth(0.2, 0.98, np.abs(X))))
    u, v = (X + Y) / math.sqrt(2), (X - Y) / math.sqrt(2)
    diag = np.maximum(np.exp(-(u / 0.03) ** 2) * (1 - smooth(0.1, 0.6, np.abs(v))),
                      np.exp(-(v / 0.03) ** 2) * (1 - smooth(0.1, 0.6, np.abs(u))))
    glow = np.exp(-(R / 0.35) ** 2) * 0.45
    alpha = np.maximum.reduce([body, long_rays, diag * 0.7, glow])
    value = np.where(body > 0.5, facet, 1.0)
    return rgba(value, alpha)


def prism():
    # pre-coloured hexagonal crystal: spectrum facets around a white core (emitter Color stays white)
    pts = [(0.62 * math.cos(math.pi / 6 + i * math.pi / 3), 0.62 * math.sin(math.pi / 6 + i * math.pi / 3)) for i in range(6)]
    body = soft_poly(X, Y, pts, 0.03)
    hue = (A / (2 * math.pi) + 0.5 + 0.08) % 1.0
    rgb = np.zeros(X.shape + (3,), np.float32)
    h6 = hue * 6
    for i, off in enumerate((0, 4, 2)):  # cheap HSV -> RGB at full saturation
        rgb[..., i] = np.clip(np.abs((h6 + off) % 6 - 3) - 1, 0, 1)
    sector = np.floor(((A + math.pi) / (math.pi / 3)) % 6)
    shade = 0.75 + 0.25 * np.cos(sector * 1.7)
    core = 1 - smooth(0.1, 0.42, R)
    col = rgb * 0.75 + 0.25
    col = col * shade[..., None]
    col = col * (1 - core[..., None]) + core[..., None]
    rim = np.exp(-((polyline(X, Y, pts + [pts[0]])) / 0.025) ** 2)
    col = col * (1 - rim[..., None] * 0.6) + rim[..., None] * 0.6
    glow = np.exp(-(R / 0.6) ** 2) * 0.35
    alpha = np.maximum(body, glow)
    out = np.zeros(X.shape + (4,), np.float32)
    out[..., :3] = np.clip(col, 0, 1)
    out[..., 3] = np.clip(alpha, 0, 1)
    return out


def voxelflake():
    # chunky pixel-art snowflake on a 13x13 grid, each voxel bevelled (lighter top-left, darker bottom-right)
    n = 11
    c = n // 2
    cells = set()
    for k in range(-4, 5):
        cells |= {(c + k, c), (c, c + k)}  # main arms
    for k in (-1, 1):
        cells |= {(c + k, c + k), (c + k, c - k)}  # a small x at the centre
    for s in (-1, 1):  # a V on each main arm: from 2 voxels out, slanting outward to the arm's tip row
        cells |= {(c - 1, c + 3 * s), (c + 1, c + 3 * s), (c + 3 * s, c - 1), (c + 3 * s, c + 1)}
        cells |= {(c - 2, c + 4 * s), (c + 2, c + 4 * s), (c + 4 * s, c - 2), (c + 4 * s, c + 2)}
    cell = 2 / n
    gx = np.floor((X + 1) / cell).astype(int)
    gy = np.floor((1 - Y) / cell).astype(int)
    fx = ((X + 1) / cell) % 1
    fy = ((1 - Y) / cell) % 1
    on = np.zeros(X.shape, bool)
    for (i, j) in cells:
        on |= (gx == i) & (gy == j)
    bevel = np.where((fx < 0.18) | (fy < 0.18), 1.0, np.where((fx > 0.82) | (fy > 0.82), 0.68, 0.88))
    value = np.where(on, bevel, 1.0)
    alpha = np.where(on, 1.0, 0.0).astype(np.float32)
    glow = np.exp(-(R / 0.75) ** 2) * 0.25
    return rgba(value, np.maximum(alpha, glow))


def mote():
    core = 1 - smooth(0.08, 0.22, R)
    halo = np.exp(-(R / 0.5) ** 2) * 0.55
    return rgba(np.ones_like(R), np.maximum(core, halo))


def comet():
    # bright head at the bottom, a tapering tail above it
    head = 1 - smooth(0.12, 0.24, np.hypot(X, Y + 0.62))
    width = 0.03 + 0.17 * smooth(0.95, -0.6, Y)
    tail = (1 - smooth(0.0, 1.0, np.abs(X) / np.maximum(width, 1e-3))) * smooth(0.98, -0.3, Y) * (Y > -0.62)
    glow = np.exp(-(np.hypot(X, Y + 0.62) / 0.4) ** 2) * 0.5
    alpha = np.maximum.reduce([head, tail * 0.9, glow])
    return rgba(np.ones_like(R), alpha)


def twinkle():
    rays = np.maximum(np.exp(-(X / 0.022) ** 2) * (1 - smooth(0.0, 1.0, np.abs(Y))) ** 1.5,
                      np.exp(-(Y / 0.022) ** 2) * (1 - smooth(0.0, 1.0, np.abs(X))) ** 1.5)
    u, v = (X + Y) / math.sqrt(2), (X - Y) / math.sqrt(2)
    small = np.maximum(np.exp(-(u / 0.02) ** 2) * (1 - smooth(0, 0.45, np.abs(v))),
                       np.exp(-(v / 0.02) ** 2) * (1 - smooth(0, 0.45, np.abs(u))))
    core = 1 - smooth(0.04, 0.12, R)
    glow = np.exp(-(R / 0.22) ** 2) * 0.6
    return rgba(np.ones_like(R), np.maximum.reduce([rays, small * 0.6, core, glow]))


def swirl():
    # three soft log-spiral arms around a dark eye (rotated by RotSpeed in game)
    theta = A - 2.6 * np.log(np.maximum(R, 1e-3))
    arms = (0.5 + 0.5 * np.cos(3 * theta)) ** 3
    ring = smooth(0.08, 0.3, R) * (1 - smooth(0.6, 0.98, R))
    alpha = arms * ring
    value = 0.65 + 0.35 * (1 - smooth(0.2, 0.9, R))
    return rgba(value, alpha)


def shard():
    pts = [(-0.18, 0.86), (0.36, 0.3), (0.22, -0.82), (-0.3, -0.42), (-0.42, 0.22)]
    body = soft_poly(X, Y, pts, 0.025)
    # two facets split along the long axis
    side = (X - (-0.18)) * (-0.82 - 0.86) - (Y - 0.86) * (0.22 - (-0.18))
    value = np.where(side > 0, 1.0, 0.7)
    edge = np.exp(-((polyline(X, Y, pts + [pts[0]])) / 0.03) ** 2)
    value = np.maximum(value, edge)
    glow = np.exp(-(R / 0.7) ** 2) * 0.3
    return rgba(value, np.maximum(body, glow))


def feather():
    # curved spine with soft vanes; barbs as faint diagonal stripes
    spine_x = 0.18 * np.sin((Y + 1) * 1.4) - 0.05
    dx = X - spine_x
    t = (Y + 0.85) / 1.7  # 0 at the quill, 1 at the tip
    half = 0.32 * np.maximum(np.sin(np.clip(t, 0, 1) * math.pi), 0) ** 0.8
    vane = (1 - smooth(half - 0.04, half + 0.02, np.abs(dx))) * ((t > 0.12) & (t < 1.0))
    barbs = 0.82 + 0.18 * np.cos((np.abs(dx) * 1.6 + Y) * 40)
    spine = (1 - smooth(0.015, 0.04, np.abs(dx))) * ((t > -0.05) & (t < 1.0))
    alpha = np.maximum(vane * 0.85, spine)
    value = np.where(spine > 0.5, 1.0, barbs * (0.75 + 0.25 * (1 - np.abs(dx) / 0.35)))
    glow = np.exp(-(np.hypot(X * 1.6, Y * 0.9) / 0.9) ** 2) * 0.25
    return rgba(value, np.maximum(alpha, glow))


def goldrop():
    # chunky cartoon teardrop with a highlight; lighter left edge so a gold tint keeps depth
    body = 1 - smooth(0.5, 0.55, np.hypot(X, (Y + 0.25)))
    top_w = 0.5 * smooth(0.85, -0.25, Y)
    cone = (np.abs(X) < top_w) & (Y > -0.25) & (Y < 0.85)
    shape = np.maximum(body, np.where(cone, 1.0, 0.0))
    alpha = shape
    shade = 0.7 + 0.3 * smooth(0.5, -0.5, X)
    hi = 1 - smooth(0.05, 0.12, np.hypot(X + 0.2, Y + 0.05))
    value = np.maximum(shade, hi)
    return rgba(value, alpha)


def toxicspore():
    ring = np.exp(-((R - 0.42) / 0.07) ** 2)
    fill = (1 - smooth(0.38, 0.46, R)) * 0.45
    dots = np.zeros_like(R)
    for (cx, cy, r) in ((0.1, 0.12, 0.09), (-0.16, -0.05, 0.07), (0.06, -0.2, 0.06)):
        dots = np.maximum(dots, 1 - smooth(r * 0.7, r, np.hypot(X - cx, Y - cy)))
    glow = np.exp(-(R / 0.7) ** 2) * 0.35
    alpha = np.maximum.reduce([ring, fill, dots, glow])
    return rgba(np.ones_like(R), alpha)


def billow():
    # cartoon cumulus: union of soft lobes, lighter on top and darker underneath (greyscale shading)
    lobes = [(-0.45, -0.1, 0.36), (-0.1, 0.12, 0.45), (0.32, 0.02, 0.4), (0.0, -0.22, 0.42), (0.55, -0.2, 0.28)]
    a = np.zeros_like(R)
    for cx, cy, r in lobes:
        a = np.maximum(a, 1 - smooth(r * 0.75, r, np.hypot(X - cx, Y - cy)))
    flat = smooth(-0.5, -0.38, Y)  # flat-ish bottom
    alpha = a * flat
    value = 0.6 + 0.4 * smooth(-0.45, 0.4, Y)
    return rgba(value, alpha)


# Beams (U along the beam = image x, tileable; V across = image y) -------------------------------------------------
B = 256
yy, xx = np.mgrid[0:B, 0:B].astype(np.float32)
U = xx / B  # 0..1 along (wraps)
V = yy / (B - 1) * 2 - 1  # -1..1 across


def tile_noise(u, freqs, seed):
    rng = np.random.default_rng(seed)
    out = np.zeros_like(u)
    for f in freqs:
        out += rng.uniform(0.4, 1.0) * np.cos(2 * math.pi * (f * u + rng.uniform(0, 1)))
    return out / len(freqs)


def ray():
    across = np.exp(-(V / 0.55) ** 2 * 2.2) * (1 - smooth(0.85, 1.0, np.abs(V)))
    streak = 0.85 + 0.15 * tile_noise(U, (1, 2, 3), 3)
    return rgba(np.ones_like(U), across * streak)


def aurora():
    # a curtain: bright fringe near the bottom edge (V = +1), rays fading upward, folds varying along U
    fold = tile_noise(U, (1, 2, 3), 11)
    edge = 0.55 + 0.12 * fold
    fringe = np.exp(-((V - edge) / 0.12) ** 2)
    body = smooth(-0.95, edge, V) * (1 - smooth(edge, edge + 0.25, V))
    rays = 0.55 + 0.45 * np.clip(tile_noise(U, (7, 11, 13, 17, 23), 5) * 1.6, -1, 1)
    alpha = np.clip(body * (0.35 + 0.65 * rays) * 0.75 + fringe * 0.9, 0, 1)
    value = 0.75 + 0.25 * fringe
    return rgba(value, alpha)


def arc():
    # jagged electric arc, endpoints at the same height so it tiles along U
    rng = np.random.default_rng(21)
    n = 12
    pts_main = [(i / n, 0.0 if i in (0, n) else rng.uniform(-0.45, 0.45)) for i in range(n + 1)]
    pts_alt = [(i / n, 0.0 if i in (0, n) else rng.uniform(-0.65, 0.65)) for i in range(n + 1)]
    d1 = polyline(U, V, pts_main)
    d2 = polyline(U, V, pts_alt)
    core = np.exp(-(d1 / 0.035) ** 2)
    glow = np.exp(-(d1 / 0.16) ** 2) * 0.55
    alt = np.exp(-(d2 / 0.025) ** 2) * 0.45
    alpha = np.maximum.reduce([core, glow, alt])
    value = 0.8 + 0.2 * core
    return rgba(value, alpha)


def splash_flipbook():
    # 2x2 frames: a crown of drops rises from a widening rim, then fades
    F = 128
    fx, fy = grid(F)
    sheet = np.zeros((2 * F, 2 * F, 4), np.float32)
    for k in range(4):
        p = (k + 0.6) / 4
        rim_w = 0.42 + 0.5 * p
        rim = np.exp(-((np.hypot(fx / rim_w, (fy + 0.55) / (rim_w * 0.28)) - 1) / 0.12) ** 2)
        a = rim * (1 - 0.55 * p)
        for i in range(5):
            ang = math.pi * (0.15 + 0.7 * i / 4)
            r = rim_w * (0.9 + 0.2 * p)
            h = 1.2 * math.sin(math.pi * min(1.0, p * 1.25)) * (0.75 + 0.25 * math.sin(i * 2.1))
            cx, cy = math.cos(ang) * r, -0.55 + h * math.sin(ang) * 0.9
            a = np.maximum(a, (1 - smooth(0.07, 0.13, np.hypot(fx - cx, fy - cy))) * (1 - 0.6 * p))
        img = rgba(np.ones_like(fx), a)
        r0, c0 = (k // 2) * F, (k % 2) * F
        sheet[r0 : r0 + F, c0 : c0 + F] = img
    return sheet


PARTICLES = {
    "wx_raindrop": raindrop,
    "wx_glitter": glitter,
    "wx_prism": prism,
    "wx_voxelflake": voxelflake,
    "wx_mote": mote,
    "wx_comet": comet,
    "wx_twinkle": twinkle,
    "wx_swirl": swirl,
    "wx_shard": shard,
    "wx_feather": feather,
    "wx_goldrop": goldrop,
    "wx_toxicspore": toxicspore,
    "wx_billow": billow,
}
BEAMS = {"wx_ray": ray, "wx_aurora": aurora, "wx_arc": arc}

for name, fn in PARTICLES.items():
    save(OUT, name, fn())
for name, fn in BEAMS.items():
    save(OUT, name, fn())
save(OUT_FLIP, "wx_splash_2x2", splash_flipbook())
print(f"{len(PARTICLES) + len(BEAMS)} textures -> {OUT}, 1 flipbook -> {OUT_FLIP}")
