# Original V3 effect sprites (white on alpha, tinted in Roblox), drawn with numpy; vault "Mesh VFX Packs Built in
# Blender" / "Particle Emitters In Depth": own textures, a ring with a bright lip and a soft noisy inner smear, a
# sparkle with a white-hot core, pixel shapes that match the brick world, and a soft dark blob for the dark contrast
# layer under bright stacks. Run: python -I bmcp.py code v3/sprites_v3.py  (writes assets/pet-vfx/vfx_v3_*.png)
import math

import numpy as np

from kit import sprites as X

CLOVER = [
    "...##..##...",
    "..####.####.",
    "..########..",
    "...######...",
    ".##..##..##.",
    "####.##.####",
    "####.##.####",
    ".##..##..##.",
    "...######...",
    "..########..",
    "..####.####.",
    "...##..##...",
]
PETAL = [
    "...##...",
    "..####..",
    ".######.",
    ".######.",
    "########",
    "########",
    ".######.",
    "..####..",
    "...##...",
]
DROPLET = [
    "....#....",
    "...###...",
    "...###...",
    "..#####..",
    ".#######.",
    ".#o#####.",
    "#o#######",
    "#o#######",
    "##o######",
    ".#######.",
    "..#####..",
]
BUBBLE = [
    "...####...",
    ".##....##.",
    ".#.oo...#.",
    "#.o......#",
    "#.o......#",
    "#........#",
    "#........#",
    ".#......#.",
    ".##....##.",
    "...####...",
]


def sparkle(path, n=128):
    """Four-point sparkle: thin rays, a white-hot core, a faint halo (twinkle / hot-frame flash)."""
    x, y = X._grid(n)
    r = np.hypot(x, y)
    ray = lambda u, v, ln, w: np.exp(-np.abs(v) / w) * np.clip(1 - np.abs(u) / ln, 0, 1) ** 1.6
    a = ray(x, y, 1.0, 0.035) + ray(y, x, 1.0, 0.035)
    a += np.exp(-(r ** 2) / 0.012) + 0.35 * np.exp(-(r ** 2) / 0.08)
    X._save(path, X._down(np.clip(a, 0, 1)))


def ripple(path, n=256, seed=7):
    """Ground ring: a bright lip at the rim, a soft noisy smear fading inward (tiles round the ring)."""
    rng = np.random.default_rng(seed)
    x, y = X._grid(n)
    r = np.hypot(x, y)
    th = np.arctan2(y, x)
    noise = np.zeros_like(x)
    for f in (3, 5, 8, 13):  # integer angular frequencies: seamless round the ring
        noise += np.sin(f * th + rng.uniform(0, math.tau)) * np.cos(f * 0.7 * r * 6 + rng.uniform(0, math.tau)) / f
    noise = (noise - noise.min()) / (noise.max() - noise.min())
    lip = np.exp(-((r - 0.88) / 0.035) ** 2)
    smear = np.clip((r - 0.45) / 0.43, 0, 1) ** 2 * (0.25 + 0.4 * noise) * (r < 0.9)
    X._save(path, X._down(np.clip(np.maximum(lip, smear), 0, 1) * (r < 0.99)))


def shadow(path, n=128):
    """Soft contact blob (tinted dark in the recipe): the dark contrast layer that grounds a bright stack."""
    x, y = X._grid(n, 1)
    r = np.hypot(x, y)
    X._save(path, np.clip(1 - r, 0, 1) ** 1.6 * 0.9)


def make_all(folder):
    X.pixel(folder + "vfx_v3_clover.png", CLOVER)
    X.pixel(folder + "vfx_v3_petal.png", PETAL)
    X.pixel(folder + "vfx_v3_droplet.png", DROPLET, values={"#": 0.8, "o": 1.0})
    X.pixel(folder + "vfx_v3_bubble.png", BUBBLE, values={"#": 1.0, "o": 1.0, ".": 0.0}, halo=0.5)
    sparkle(folder + "vfx_v3_sparkle.png")
    ripple(folder + "vfx_v3_ripple.png")
    shadow(folder + "vfx_v3_shadow.png")


# ---- top tier (Divine, Secret): one sigil per creature (vault rarity ladder: glyphs from Legendary up), rays, motifs ----
FEATHER = [
    "......##",
    ".....###",
    "....####",
    "...####.",
    "..#####.",
    "..####..",
    ".####...",
    ".###....",
    "###.....",
    "##......",
    "#.......",
]
COG = [
    "...##...",
    ".######.",
    ".##..##.",
    "##....##",
    "##....##",
    ".##..##.",
    ".######.",
    "...##...",
]


def sun_sigil(path, n=512):
    """Heaven Lion: a double ring, twelve rays alternating long and short, a sun disc with a four-point star."""
    x, y = X._grid(n)
    r = np.hypot(x, y)
    d = np.minimum(np.abs(r - 0.6), np.abs(r - 0.52))
    for i in range(12):
        a = 2 * math.pi * i / 12
        r1 = 0.95 if i % 2 == 0 else 0.8
        d = np.minimum(d, X._seg(x, y, X._polar(0.64, a), X._polar(r1, a)))
    m = (r < 0.3).astype(float) * 0.55
    for a in (0, math.pi / 2):
        u = x * math.cos(a) + y * math.sin(a)
        v = -x * math.sin(a) + y * math.cos(a)
        m = np.maximum(m, ((np.abs(u) / 0.42 + np.abs(v) / 0.07) < 1).astype(float))
    X._glow_save(path, n, m, d, w=0.018)


def gear_sigil(path, n=512):
    """Clockwork Titan: a toothed gear ring, an inner ring, six spokes and a hexagon hub."""
    x, y = X._grid(n)
    r = np.hypot(x, y)
    th = np.arctan2(y, x)
    tooth = (np.cos(th * 16) > 0.35).astype(float)
    m = ((r > 0.78) & (r < 0.86 + 0.09 * tooth)).astype(float)
    d = np.abs(r - 0.5)
    for i in range(6):
        a = 2 * math.pi * i / 6
        d = np.minimum(d, X._seg(x, y, X._polar(0.16, a), X._polar(0.76, a)))
    hexv = [X._polar(0.16, 2 * math.pi * i / 6 + math.pi / 6) for i in range(6)]
    for i in range(6):
        d = np.minimum(d, X._seg(x, y, hexv[i], hexv[(i + 1) % 6]))
    X._glow_save(path, n, m, d, w=0.02)


def prism_sigil(path, n=512):
    """Prism Seraph: a triangle prism splitting a beam into seven rays, seven diamonds on a ring, a double ring."""
    x, y = X._grid(n)
    r = np.hypot(x, y)
    d = np.minimum(np.abs(r - 0.93), np.abs(r - 0.87))
    tri = [X._polar(0.36, math.pi / 2 + 2 * math.pi * i / 3) for i in range(3)]
    for i in range(3):
        d = np.minimum(d, X._seg(x, y, tri[i], tri[(i + 1) % 3]))
    d = np.minimum(d, X._seg(x, y, (-0.8, 0.12), (-0.18, 0.0)))
    for i in range(7):
        a = -0.45 + 0.15 * i
        d = np.minimum(d, X._seg(x, y, (0.18, 0.0), (0.18 + 0.6 * math.cos(a), 0.6 * math.sin(a))))
    m = np.zeros_like(x)
    for i in range(7):
        cx, cy = X._polar(0.72, math.pi / 2 + 2 * math.pi * i / 7)
        m = np.maximum(m, ((np.abs(x - cx) + np.abs(y - cy)) < 0.06).astype(float))
    X._glow_save(path, n, m, d, w=0.016)


def rays(path, n=256):
    """Light rays fanning up from a point near the bottom (a camera-facing board behind Divine pets)."""
    x, y = X._grid(n)
    yy = y + 0.9
    ang = np.arctan2(x, yy)
    rr = np.hypot(x, yy)
    a = np.zeros_like(x)
    for i, (c, w) in enumerate(((-0.55, 0.05), (-0.3, 0.07), (-0.08, 0.05), (0.12, 0.08), (0.34, 0.05), (0.56, 0.06))):
        a = np.maximum(a, np.exp(-((ang - c) / w) ** 2))
    a *= np.clip(1 - rr / 1.8, 0, 1) ** 1.2 * (yy > 0)
    X._save(path, X._down(np.clip(a, 0, 1)))


def steam(path, n=128, seed=11):
    """Soft steam puff: overlapping blobs with a little noise breakup."""
    rng = np.random.default_rng(seed)
    x, y = X._grid(n, 1)
    a = np.zeros_like(x)
    for _ in range(6):
        cx, cy = rng.uniform(-0.3, 0.3, 2)
        sg = rng.uniform(0.2, 0.32)
        a += np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * sg * sg)) * rng.uniform(0.5, 0.9)
    a = a * np.clip(1.05 - np.hypot(x, y), 0, 1)
    X._save(path, np.clip(a / a.max(), 0, 1) * 0.85)


def make_top(folder):
    sun_sigil(folder + "vfx_v3_sun_sigil.png")
    gear_sigil(folder + "vfx_v3_gear_sigil.png")
    prism_sigil(folder + "vfx_v3_prism_sigil.png")
    rays(folder + "vfx_v3_rays.png")
    steam(folder + "vfx_v3_steam.png")
    X.pixel(folder + "vfx_v3_feather.png", FEATHER)
    X.pixel(folder + "vfx_v3_cog.png", COG)


make_all(REPO + "/assets/pet-vfx/")
make_top(REPO + "/assets/pet-vfx/")
print("v3 sprites written")
