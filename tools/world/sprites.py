"""Original particle sprites for the world VFX (white / greyscale + alpha, tinted per emitter in game), 128 px.
Run with Blender's bundled Python (it has numpy):
  "<Blender>/5.2/python/bin/python.exe" -I tools/world/sprites.py assets/world-vfx
Flipbooks are 2x2 grids (ParticleEmitter.FlipbookLayout = Grid2x2)."""

import math
import os
import struct
import sys
import zlib

import numpy as np

S = 128
OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/world-vfx"
os.makedirs(OUT, exist_ok=True)

yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
cx = cy = (S - 1) / 2
U = (xx - cx) / (S / 2)  # -1..1
V = (yy - cy) / (S / 2)
R = np.sqrt(U * U + V * V)
A = np.arctan2(V, U)
rng = np.random.default_rng(7)


def save(name, rgba):
    rgba = np.clip(rgba, 0, 1)
    img = (rgba * 255 + 0.5).astype(np.uint8)
    h, w = img.shape[:2]
    raw = b"".join(b"\x00" + img[y].tobytes() for y in range(h))

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(os.path.join(OUT, f"wfx_{name}.png"), "wb") as f:
        f.write(png)


def white(alpha, tint=None):
    out = np.ones((S, S, 4), np.float32)
    if tint is not None:
        out[..., :3] = tint
    out[..., 3] = np.clip(alpha, 0, 1)
    return out


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def noise(scale, octaves=3, seed=0):
    g = np.random.default_rng(seed)
    acc = np.zeros((S, S), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        n = int(scale * 2**o) + 1
        grid = g.random((n + 1, n + 1)).astype(np.float32)
        gx = xx / (S - 1) * n
        gy = yy / (S - 1) * n
        x0, y0 = np.floor(gx).astype(int), np.floor(gy).astype(int)
        fx, fy = gx - x0, gy - y0
        fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
        x1, y1 = np.minimum(x0 + 1, n), np.minimum(y0 + 1, n)
        v = (grid[y0, x0] * (1 - fx) + grid[y0, x1] * fx) * (1 - fy) + (grid[y1, x0] * (1 - fx) + grid[y1, x1] * fx) * fy
        acc += v * amp
        tot += amp
        amp *= 0.5
    return acc / tot


# 1 soft dot: glow core with smooth falloff
save("softdot", white(np.exp(-(R * 2.4) ** 2) + 0.35 * np.exp(-(R * 1.2) ** 2) * smooth(1.0, 0.55, R)))
# 2 sparkle: 4-point star with a hot core
arms = np.maximum(np.exp(-np.abs(U) * 26) * np.exp(-np.abs(V) * 2.6), np.exp(-np.abs(V) * 26) * np.exp(-np.abs(U) * 2.6))
diag = np.maximum(np.exp(-np.abs(U - V) * 30) * np.exp(-np.abs(U + V) * 4), np.exp(-np.abs(U + V) * 30) * np.exp(-np.abs(U - V) * 4)) * 0.45
save("sparkle", white(arms + diag + np.exp(-(R * 5) ** 2)))
# 3 star: chunky 5-point star with soft edge
k = 5
star_r = 0.5 + 0.38 * (np.cos(k * (A + math.pi / 2)) * 0.5 + 0.5) ** 2.2
save("star", white(smooth(star_r + 0.04, star_r - 0.04, R * 1.25) + 0.25 * np.exp(-(R * 1.6) ** 2)))
# 4 petal: rounded teardrop with a soft centre line
pu, pv = U * 1.6, V * 1.15 + 0.15
petal = smooth(1.02, 0.94, np.sqrt(pu * pu / (1 - 0.45 * np.clip(pv, -1, 1)) + pv * pv))
save("petal", white(petal * (0.85 + 0.15 * (1 - np.exp(-(U * 10) ** 2)))))
# 5 leaf: pointed oval with a stem and a darker vein (greyscale shading for tint)
lu, lv = U * 1.7, V * 1.05
leaf = smooth(1.0, 0.92, np.abs(lu) / np.maximum(0.001, np.maximum(0.0, 1 - lv * lv) ** 0.75 * 0.95) + 0.0)
leaf *= (np.abs(lv) < 0.98)
stem = (np.abs(U) < 0.035) * (V > 0.75) * (V < 1.0)
shade = 0.8 + 0.2 * smooth(0.0, 0.5, np.abs(U))
vein = 1 - 0.35 * np.exp(-(U * 40) ** 2) * (np.abs(V) < 0.85)
leaf_rgb = np.ones((S, S, 4), np.float32)
leaf_rgb[..., :3] = (shade * vein)[..., None]
leaf_rgb[..., 3] = np.clip(leaf + stem, 0, 1)
save("leaf", leaf_rgb)
# 6 maple-ish leaf: lobed silhouette
lob = 0.62 + 0.3 * np.abs(np.cos(2.5 * (A + math.pi / 2))) ** 0.6
maple = smooth(lob + 0.03, lob - 0.03, R * 1.1) * (V < 0.92)
maple = np.maximum(maple, (np.abs(U) < 0.04) * (V > 0.4) * (V < 1.0))
m_rgb = np.ones((S, S, 4), np.float32)
m_rgb[..., :3] = (0.82 + 0.18 * (1 - R))[..., None]
m_rgb[..., 3] = maple
save("maple", m_rgb)
# 7 snowflake: 6 arms with side branches
flake = np.zeros((S, S), np.float32)
for i in range(6):
    a = i * math.pi / 3
    ca, sa = math.cos(a), math.sin(a)
    pu_ = U * ca + V * sa
    pv_ = -U * sa + V * ca
    arm = np.exp(-np.abs(pv_) * 40) * (pu_ > 0) * (pu_ < 0.92)
    for t in (0.42, 0.66):
        bu = pu_ - t
        for sgn in (-1, 1):
            br = np.exp(-np.abs(pv_ - sgn * bu * 0.9) * 36) * (bu > 0) * (bu < 0.2)
            arm = np.maximum(arm, br)
    flake = np.maximum(flake, arm)
save("snowflake", white(np.maximum(flake, np.exp(-(R * 7) ** 2))))
# 8 bubble: ring with a highlight
ring = np.exp(-((R - 0.78) * 14) ** 2) * 0.9 + 0.12 * (R < 0.78)
hl = np.exp(-(((U + 0.32) * 6) ** 2 + ((V + 0.32) * 6) ** 2))
save("bubble", white(ring + hl))
# 9 mist puff: soft noisy cloud
n = noise(3, 4, seed=3)
save("mist", white(smooth(1.0, 0.2, R) * (0.55 + 0.45 * n) * 0.85))
# 10 smoke / dust puff: billowy lobes
lobes = np.zeros((S, S), np.float32)
for i in range(7):
    a = i / 7 * math.tau + rng.random()
    r = 0.32
    cu, cv = math.cos(a) * r, math.sin(a) * r
    lobes = np.maximum(lobes, smooth(0.55, 0.0, np.sqrt((U - cu) ** 2 + (V - cv) ** 2)))
lobes = np.maximum(lobes, smooth(0.6, 0.0, R))
save("puff", white(lobes * (0.7 + 0.3 * noise(4, 3, seed=5))))
# 11 ember: hot core with a short upward tail
tail = np.exp(-(U * 9) ** 2) * np.exp(-np.maximum(V, 0) * 3.5) * (V > -0.1)
save("ember", white(np.maximum(np.exp(-(R * 4) ** 2), tail * 0.8)))
# 12 streak (wind / sand gust): long soft horizontal line
save("streak", white(np.exp(-(V * 14) ** 2) * smooth(1.0, 0.3, np.abs(U))))
# 13 glint (crystal): sharp diamond + thin cross
dia = smooth(0.42, 0.3, np.abs(U) + np.abs(V))
cross = np.maximum(np.exp(-np.abs(U) * 60) * smooth(1, 0, np.abs(V)), np.exp(-np.abs(V) * 60) * smooth(1, 0, np.abs(U)))
save("glint", white(np.maximum(dia, cross)))
# 14 ring (expanding shock / pulse)
save("ring", white(np.exp(-((R - 0.8) * 18) ** 2)))
# 15 spore: dot with a fuzzy halo
save("spore", white(smooth(0.3, 0.18, R) + 0.4 * np.exp(-(R * 2.2) ** 2)))
# 16 sprinkle (candy): rounded capsule
cap = np.sqrt(np.maximum(np.abs(U) - 0.45, 0) ** 2 + V * V)
save("sprinkle", white(smooth(0.26, 0.2, cap)))
# 17 butterfly flipbook 2x2: wings open -> closed (greyscale wings, dark body), tinted in game
def butterfly(open_):
    img = np.zeros((S, S), np.float32)
    body = (np.abs(U) < 0.06) * (np.abs(V) < 0.55)
    for sgn in (-1, 1):
        wu = (U * sgn - 0.05) / max(0.08, open_)
        up = smooth(1.0, 0.9, np.sqrt(((wu - 0.5) / 0.55) ** 2 + ((V + 0.25) / 0.45) ** 2))
        lo = smooth(1.0, 0.9, np.sqrt(((wu - 0.38) / 0.4) ** 2 + ((V - 0.35) / 0.32) ** 2))
        img = np.maximum(img, np.maximum(up, lo) * (U * sgn > 0.02))
    return img, body


frames = []
for open_ in (1.0, 0.7, 0.35, 0.7):
    w, b = butterfly(open_)
    f = np.ones((S, S, 4), np.float32)
    f[..., :3] = np.where(b[..., None] > 0, 0.15, (0.85 + 0.15 * (1 - R))[..., None])
    f[..., 3] = np.clip(w + b, 0, 1)
    # downscale 2x into a quadrant
    frames.append(f.reshape(S // 2, 2, S // 2, 2, 4).mean(axis=(1, 3)))
sheet = np.zeros((S, S, 4), np.float32)
sheet[: S // 2, : S // 2] = frames[0]
sheet[: S // 2, S // 2 :] = frames[1]
sheet[S // 2 :, : S // 2] = frames[2]
sheet[S // 2 :, S // 2 :] = frames[3]
save("butterfly", sheet)
# 18 aurora ribbon: soft vertical curtain (for beams)
curtain = smooth(1.0, 0.0, np.abs(U)) * (0.35 + 0.65 * smooth(1.0, -0.6, V)) * (0.7 + 0.3 * noise(6, 2, seed=9))
save("curtain", white(curtain))
# 19 waterfall sheet (beam texture): vertical streaks
streaks = 0.6 + 0.4 * np.sin(U * 40 + noise(8, 2, seed=11) * 6)
save("falls", white(streaks * smooth(1.0, 0.75, np.abs(U)) * 0.9))
# 20 square confetti / pixel
save("pixel", white(smooth(0.62, 0.55, np.maximum(np.abs(U), np.abs(V)))))
print("sprites written to", OUT)
