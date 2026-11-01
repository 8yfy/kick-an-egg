# Signature VFX sprites for the top tier (2026-11-01, the user's picks: Judgement Light, Overcharged Engine, Aurora
# Veil). White on alpha, tinted in Roblox. Beam textures run along the image's X axis (Beam U = length, V = width).
#   python -I bmcp.py code v3/sprites_signature.py   (writes assets/pet-vfx/vfx_v3_{shaft,arc,clock_dial,veil}.png)
import math

import numpy as np

from kit import sprites as X


def shaft(path, n=256, seed=3):
    """Light shaft (Heaven Lion): soft across the width, faint lengthwise streaks, fading at both ends."""
    rng = np.random.default_rng(seed)
    x, y = X._grid(n, 1)
    across = np.exp(-(y / 0.42) ** 2)
    streak = np.ones_like(y)
    for _ in range(7):
        c, w = rng.uniform(-0.6, 0.6), rng.uniform(0.03, 0.09)
        streak += np.exp(-((y - c) / w) ** 2) * rng.uniform(0.3, 0.7)
    along = np.clip((1 - np.abs(x)) / 0.25, 0, 1) ** 1.5
    a = across * streak / streak.max() * along
    X._save(path, np.clip(a / a.max(), 0, 1) * 0.9)


def arc(path, n=128):
    """Lightning segment (Clockwork Titan): a thick white-hot core with a wide soft glow across the width."""
    x, y = X._grid(n, 1)
    core = np.clip(np.exp(-(y / 0.22) ** 2) * 1.4, 0, 1)
    glow = np.exp(-(y / 0.6) ** 2) * 0.55
    X._save(path, np.clip(core + glow, 0, 1))


def clock_dial(path, n=512):
    """Overclock dial (Clockwork Titan): a double rim, twelve hour bars (long at 12/3/6/9), sixty minute dots, two
    hands and a hub, all with a soft glow."""
    x, y = X._grid(n)
    r = np.hypot(x, y)
    d = np.minimum(np.abs(r - 0.94), np.abs(r - 0.86))
    for i in range(12):
        a = math.pi / 2 - 2 * math.pi * i / 12
        r0 = 0.6 if i % 3 == 0 else 0.68
        d = np.minimum(d, X._seg(x, y, X._polar(r0, a), X._polar(0.8, a)))
    m = np.zeros_like(x)
    for i in range(60):
        if i % 5:
            cx, cy = X._polar(0.8, math.pi / 2 - 2 * math.pi * i / 60)
            m = np.maximum(m, (np.hypot(x - cx, y - cy) < 0.014).astype(float))
    d = np.minimum(d, X._seg(x, y, (0, 0), X._polar(0.42, math.radians(30))))
    d = np.minimum(d, X._seg(x, y, (0, 0), X._polar(0.62, math.radians(160))))
    m = np.maximum(m, (r < 0.07).astype(float))
    X._glow_save(path, n, m, d, w=0.022, glow=0.5)


def veil(path, n=256, seed=5):
    """Aurora veil (Prism Seraph): dense vertical light streaks along X over a solid glow, strongest low across the
    width and fading toward the top edge, so a ribbon or curtain reads as a lit sheet even in daylight."""
    rng = np.random.default_rng(seed)
    x, y = X._grid(n, 1)
    s = np.zeros_like(x)
    for _ in range(18):
        c, w = rng.uniform(-1, 1), rng.uniform(0.02, 0.08)
        dx = np.minimum(np.abs(x - c), 2 - np.abs(x - c))  # wraps, so the texture tiles along the beam
        s += np.exp(-(dx / w) ** 2) * rng.uniform(0.4, 1.0)
    s = 0.6 + 0.4 * s / s.max()
    v = (y + 1) / 2  # 0 at the bottom row, 1 at the top
    up = np.clip(v / 0.08, 0, 1) * np.clip((1 - v) / 0.55, 0, 1) ** 0.7
    X._save(path, np.clip(s * up, 0, 1))


F = REPO + "/assets/pet-vfx/"
shaft(F + "vfx_v3_shaft.png")
arc(F + "vfx_v3_arc.png")
clock_dial(F + "vfx_v3_clock_dial.png")
veil(F + "vfx_v3_veil.png")
print("signature sprites written")
