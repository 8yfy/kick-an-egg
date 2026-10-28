# Original Frost Serpent VFX sprites: white-on-alpha PNGs (tinted in Roblox by Color / ImageColor3).
# Drawn procedurally with numpy distance fields, 4x supersampled. Run inside Blender (uses bpy image saving).
import math

import bpy
import numpy as np


def _grid(n, ss=4):
    m = n * ss
    c = (np.arange(m) + 0.5) / m * 2 - 1
    x, y = np.meshgrid(c, -c)
    return x, y


def _down(a, ss=4):
    m = a.shape[0] // ss
    return a.reshape(m, ss, m, ss).mean(axis=(1, 3))


def _seg(x, y, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = np.clip(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy + 1e-12), 0, 1)
    return np.hypot(x - (ax + t * dx), y - (ay + t * dy))


def _line(d, w):
    return np.clip((w - d) / (w * 0.35) + 0.5, 0, 1)


def _polar(r, a):
    return (r * math.cos(a), r * math.sin(a))


def _save(path, alpha, rgb=(1, 1, 1)):
    n = alpha.shape[0]
    img = np.zeros((n, n, 4), dtype=np.float32)
    img[..., 0], img[..., 1], img[..., 2] = rgb
    img[..., 3] = np.clip(alpha, 0, 1)
    img = img[::-1]  # Blender pixel rows start at the bottom
    im = bpy.data.images.new("tex", n, n, alpha=True)
    im.colorspace_settings.name = "sRGB"
    im.pixels.foreach_set(img.ravel())
    im.filepath_raw = path
    im.file_format = "PNG"
    im.save()
    bpy.data.images.remove(im)


def tex_sigil(path, n=512):
    """Snowflake sigil: double ring with ticks, a hexagon and six branched arms."""
    x, y = _grid(n)
    r = np.hypot(x, y)
    d = np.full_like(x, 9.0)
    d = np.minimum(d, np.abs(r - 0.93))
    d = np.minimum(d, np.abs(r - 0.76))
    d = np.minimum(d, np.abs(r - 0.15))
    segs = []
    for k in range(36):
        a = math.radians(k * 10 + 5)
        segs.append((_polar(0.80 if k % 3 == 0 else 0.84, a), _polar(0.89, a)))
    hexv = [_polar(0.62, math.radians(30 + 60 * k)) for k in range(6)]
    segs += [(hexv[k], hexv[(k + 1) % 6]) for k in range(6)]
    for k in range(6):
        a = math.radians(60 * k)
        segs.append((_polar(0.15, a), _polar(0.72, a)))
        for t, ln in ((0.36, 0.17), (0.55, 0.12)):
            p0 = _polar(t, a)
            for sgn in (-1, 1):
                b = a + sgn * math.radians(42)
                segs.append((p0, (p0[0] + ln * math.cos(b), p0[1] + ln * math.sin(b))))
    for a0, b0 in segs:
        d = np.minimum(d, _seg(x, y, a0, b0))
    # diamond tips on the arms
    for k in range(6):
        a = math.radians(60 * k)
        cx, cy = _polar(0.72, a)
        u = (x - cx) * math.cos(a) + (y - cy) * math.sin(a)
        v = -(x - cx) * math.sin(a) + (y - cy) * math.cos(a)
        d = np.minimum(d, np.maximum(np.abs(u) / 0.06 + np.abs(v) / 0.035 - 1, 0) * 0.03)
    core = _line(d, 0.012)
    glow = np.exp(-d / 0.035) * 0.45
    _save(path, _down(np.maximum(core, glow) * (r < 0.99)))


def tex_rune_ring(path, n=256):
    """Egg glyph: a hexagon with a ring inside and a diamond on every corner."""
    x, y = _grid(n)
    r = np.hypot(x, y)
    d = np.abs(r - 0.58)
    hexv = [_polar(0.84, math.radians(60 * k)) for k in range(6)]
    for k in range(6):
        d = np.minimum(d, _seg(x, y, hexv[k], hexv[(k + 1) % 6]))
    for k in range(6):
        a = math.radians(60 * k + 30)
        cx, cy = _polar(0.42, a)
        d = np.minimum(d, np.maximum(np.abs(x - cx) + np.abs(y - cy) - 0.06, 0))
    core = _line(d, 0.022)
    glow = np.exp(-d / 0.05) * 0.4
    _save(path, _down(np.maximum(core, glow) * (r < 0.99)))


def tex_spark(path, n=128):
    """Four-point frost glint with shorter diagonal rays and a soft core."""
    x, y = _grid(n)
    r = np.hypot(x, y)
    ray = lambda u, v, ln, w: np.exp(-np.abs(v) / w) * np.clip(1 - np.abs(u) / ln, 0, 1) ** 2
    du, dv = (x + y) / math.sqrt(2), (x - y) / math.sqrt(2)
    a = ray(x, y, 1.0, 0.03) + ray(y, x, 1.0, 0.03) + 0.5 * (ray(du, dv, 0.5, 0.02) + ray(dv, du, 0.5, 0.02))
    a += np.exp(-(r**2) / 0.02)
    _save(path, _down(np.clip(a, 0, 1)))


FLAKE = [
    "....#...#...#....",
    ".....#..#..#.....",
    "..#...#.#.#...#..",
    "...#...###...#...",
    "....#...#...#....",
    "#....#..#..#....#",
    ".#....#.#.#....#.",
    "..##...###...##..",
    "#####.#####.#####",
    "..##...###...##..",
    ".#....#.#.#....#.",
    "#....#..#..#....#",
    "....#...#...#....",
    "...#...###...#...",
    "..#...#.#.#...#..",
    ".....#..#..#.....",
    "....#...#...#....",
]


def tex_flake(path, n=128):
    """Blocky pixel snowflake (classic brick look), with a soft halo."""
    g = np.array([[1.0 if ch == "#" else 0.0 for ch in row] for row in FLAKE])
    cell = n // (len(FLAKE) + 3)
    px = np.kron(g, np.ones((cell, cell)))
    pad = (n - px.shape[0]) // 2
    a = np.zeros((n, n))
    a[pad : pad + px.shape[0], pad : pad + px.shape[1]] = px
    # halo: cheap blur by repeated box averaging
    h = a.copy()
    for _ in range(6):
        h = (h + np.roll(h, 2, 0) + np.roll(h, -2, 0) + np.roll(h, 2, 1) + np.roll(h, -2, 1)) / 5
    _save(path, np.clip(a + h * 0.9, 0, 1))


def tex_mist(path, n=128):
    """Soft cold-breath puff: a few overlapping blobs with value-noise breakup."""
    rng = np.random.default_rng(23)
    x, y = _grid(n, 1)
    a = np.zeros_like(x)
    for _ in range(7):
        cx, cy = rng.uniform(-0.35, 0.35, 2)
        s = rng.uniform(0.18, 0.32)
        a += np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * s * s)) * rng.uniform(0.5, 0.9)
    noise = np.zeros_like(x)
    for _ in range(6):
        f = rng.uniform(2.5, 6.0)
        th = rng.uniform(0, math.tau)
        noise += np.sin(f * (x * math.cos(th) + y * math.sin(th)) + rng.uniform(0, math.tau))
    noise = (noise - noise.min()) / (noise.max() - noise.min())
    a = a * (0.65 + 0.5 * noise) * np.clip(1.05 - np.hypot(x, y), 0, 1) ** 0.8
    _save(path, np.clip(a / a.max(), 0, 1))


def tex_cube(path, n=64):
    """Ice cube: bevelled square, a bright rim and a top-left highlight."""
    x, y = _grid(n)
    m = np.maximum(np.abs(x), np.abs(y))
    body = _line(m - 0.78, 0.0) * 0.55
    rim = _line(np.abs(m - 0.74), 0.07)
    hl = _line(np.maximum(np.abs(x + 0.32) - 0.18, np.abs(y - 0.32) - 0.18), 0.02) * 0.9
    edge = (m < 0.86).astype(float)
    _save(path, _down(np.clip(np.maximum(np.maximum(body, rim), hl) * edge, 0, 1)))


def make_all(folder):
    tex_sigil(folder + "vfx_frost_sigil.png")
    tex_rune_ring(folder + "vfx_frost_rune_ring.png")
    tex_spark(folder + "vfx_frost_spark.png")
    tex_flake(folder + "vfx_frost_flake.png")
    tex_mist(folder + "vfx_frost_mist.png")
    tex_cube(folder + "vfx_frost_cube.png")
