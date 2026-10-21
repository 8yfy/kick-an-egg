# Generic props kit (recoloured per zone through roles): fences, lamps, benches, crates, barrels, signs, lanterns,
# planters, bridges, docks, logs, stumps. Chunky proportions for the Roblox avatar (~5 studs tall, a door ~8 tall).
# Origin = base centre on the ground, front = -Y.
import math

from mathutils import Vector

import kit
from lib_nature import R


def fence_post(name, seed, h=4.2, w=1.2, cap=True):
    """Chunky square post with a beveled cap and a collar; scaled per pen level (the rail is a separate asset)."""
    a = kit.Asset(name, seed)
    kit.block(a, "Wood", (0, 0, -0.4), (w, w, h + 0.4), bevel=0.12)
    kit.block(a, "WoodDark", (0, 0, h * 0.18), (w * 1.12, w * 1.12, 0.35), bevel=0.06)
    if cap:
        kit.block(a, "Trim", (0, 0, h - 0.05), (w * 1.35, w * 1.35, 0.42), bevel=0.1)
        kit.block(a, "Trim", (0, 0, h + 0.35), (w * 0.9, w * 0.9, 0.5), bevel=0.12, taper=0.55)
    return a


def fence_rail(name, seed, length=8.0, h=4.2, boards=2):
    """Rail section between posts (local X = length). Two chunky rails with slightly uneven boards."""
    a = kit.Asset(name, seed)
    for i in range(boards):
        z = h * (0.32 + 0.38 * i)
        kit.box(a, "Wood", (0, 0, z), (length, 0.42, 0.62), rot=(0, R(a, -0.012, 0.012), 0), bevel=0.08)
    return a


def picket_rail(name, seed, length=8.0, h=3.4):
    a = kit.Asset(name, seed)
    kit.box(a, "Wood", (0, 0.05, h * 0.35), (length, 0.3, 0.45), bevel=0.06)
    kit.box(a, "Wood", (0, 0.05, h * 0.75), (length, 0.3, 0.45), bevel=0.06)
    n = max(2, int(length / 1.15))
    for i in range(n):
        x = -length / 2 + (i + 0.5) * length / n
        ph = h * R(a, 0.95, 1.05)
        kit.block(a, "Wall", (x, -0.15, -0.3), (0.62, 0.22, ph + 0.3), bevel=0.05)
        kit.block(a, "Wall", (x, -0.15, ph), (0.62, 0.22, 0.45), bevel=0.04, taper=0.25)
    return a


def lamp_post(name, seed, h=10.0):
    """Park lamp: stepped stone foot, slim post with collars, a lantern box with glowing panes and a little roof."""
    a = kit.Asset(name, seed)
    kit.block(a, "StoneDark", (0, 0, -0.4), (2.0, 2.0, 1.0), bevel=0.15)
    kit.block(a, "Stone", (0, 0, 0.55), (1.4, 1.4, 0.5), bevel=0.1, taper=0.85)
    kit.block(a, "Metal", (0, 0, 1.0), (0.55, 0.55, h - 3.4), bevel=0.05)
    for z in (2.0, h - 3.0):
        kit.block(a, "Metal", (0, 0, z), (0.85, 0.85, 0.35), bevel=0.06)
    kit.block(a, "Metal", (0, 0, h - 2.6), (1.5, 1.5, 0.3), bevel=0.05)
    kit.block(a, "Glow", (0, 0, h - 2.3), (1.1, 1.1, 1.6), bevel=0.06)
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        kit.block(a, "Metal", (sx * 0.62, sy * 0.62, h - 2.3), (0.22, 0.22, 1.6))
    kit.block(a, "Roof", (0, 0, h - 0.7), (2.0, 2.0, 0.9), bevel=0.06, taper=0.35)
    kit.block(a, "Metal", (0, 0, h + 0.15), (0.3, 0.3, 0.5), bevel=0.05)
    return a


def bench(name, seed, length=6.0):
    a = kit.Asset(name, seed)
    for sx in (-1, 1):
        kit.block(a, "Metal", (sx * (length / 2 - 0.7), 0, -0.3), (0.5, 1.9, 1.9), bevel=0.06)
        kit.block(a, "Metal", (sx * (length / 2 - 0.7), 0.7, 1.4), (0.4, 0.4, 1.9), rot=(-0.15, 0, 0), bevel=0.05)
    for i in range(3):
        kit.block(a, "Wood", (0, -0.6 + i * 0.6, 1.55), (length, 0.5, 0.28), bevel=0.06)
    for i in range(2):
        kit.box(a, "Wood", (0, 0.95, 2.4 + i * 0.7), (length, 0.25, 0.5), rot=(-0.15, 0, 0), bevel=0.06)
    return a


def crate(name, seed, s=3.0):
    a = kit.Asset(name, seed)
    kit.block(a, "Wood", (0, 0, -0.2), (s, s, s), bevel=0.12)
    for z in (0.12, s - 0.42):
        kit.block(a, "WoodDark", (0, 0, z - 0.2), (s + 0.12, s + 0.12, 0.42), bevel=0.06)
    for sx in (-1, 1):
        kit.box(a, "WoodDark", (sx * (s / 2 + 0.03), 0, s / 2 - 0.2), (0.1, s * 1.15, 0.42), rot=(math.atan2(s, s) * sx, 0, 0), bevel=0)
    return a


def barrel(name, seed, h=3.6, r=1.4):
    a = kit.Asset(name, seed)
    kit.prism(a, "Wood", (0, 0, -0.2), 10, r * 0.88, r, h * 0.5 + 0.2)
    kit.prism(a, "Wood", (0, 0, h * 0.5), 10, r, r * 0.88, h * 0.5)
    for z in (h * 0.16, h * 0.84):
        kit.prism(a, "Metal", (0, 0, z - 0.17), 10, r * 0.97 + 0.08, r * 0.97 + 0.08, 0.34)
    kit.prism(a, "WoodDark", (0, 0, h - 0.05), 10, r * 0.8, r * 0.8, 0.12)
    return a


def lantern(name, seed, h=2.2):
    a = kit.Asset(name, seed)
    kit.block(a, "Metal", (0, 0, 0), (1.1, 1.1, 0.25), bevel=0.05)
    kit.block(a, "Glow", (0, 0, 0.25), (0.8, 0.8, h * 0.55), bevel=0.05)
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        kit.block(a, "Metal", (sx * 0.45, sy * 0.45, 0.25), (0.16, 0.16, h * 0.55))
    kit.block(a, "Metal", (0, 0, 0.25 + h * 0.55), (1.2, 1.2, 0.45), bevel=0.05, taper=0.4)
    kit.block(a, "Metal", (0, 0, 0.7 + h * 0.55), (0.18, 0.5, 0.5))
    return a


def signpost(name, seed, h=6.5, arrows=2):
    a = kit.Asset(name, seed)
    kit.block(a, "Wood", (0, 0, -0.5), (0.7, 0.7, h + 0.5), bevel=0.08)
    kit.block(a, "WoodDark", (0, 0, h), (0.95, 0.95, 0.35), bevel=0.06, taper=0.5)
    for i in range(arrows):
        z = h - 1.0 - i * 1.5
        side = 1 if i % 2 == 0 else -1
        rz = R(a, -0.25, 0.25)
        kit.box(a, "Trim", (side * 1.7, 0, z), (3.4, 0.25, 1.05), rot=(0, 0, rz), bevel=0.06)
        kit.box(a, "Trim", (side * 3.55, 0, z), (0.9, 0.25, 0.9), rot=(0, math.pi / 4, rz), bevel=0.04)
    return a


def planter(name, seed, w=6.0, d=3.0, h=1.8):
    a = kit.Asset(name, seed)
    kit.block(a, "Wood", (0, 0, -0.3), (w, d, h + 0.3), bevel=0.15)
    kit.block(a, "WoodDark", (0, 0, h - 0.1), (w + 0.3, d + 0.3, 0.35), bevel=0.08)
    kit.block(a, "Dirt", (0, 0, h - 0.3), (w - 0.6, d - 0.6, 0.5))
    return a


def plank_bridge(name, seed, length=16.0, width=7.0, arch=1.6, rails=True):
    """Arched plank bridge along local Y (length), walkable look; decor only (no collision in game)."""
    a = kit.Asset(name, seed)
    n = int(length / 1.1)
    for i in range(n):
        t = (i + 0.5) / n
        y = -length / 2 + t * length
        z = arch * math.sin(math.pi * t)
        slope = math.atan(arch * math.pi / length * math.cos(math.pi * t))
        kit.box(a, "Wood" if i % 3 else "WoodDark", (R(a, -0.1, 0.1), y, z + 0.3), (width * R(a, 0.96, 1.02), 1.0, 0.4), rot=(slope, 0, R(a, -0.02, 0.02)), bevel=0.06)
    for sx in (-1, 1):
        for i in range(n + 1):
            pass
        # stringers
        segs = 6
        for k in range(segs):
            t0, t1 = k / segs, (k + 1) / segs
            y0, y1 = -length / 2 + t0 * length, -length / 2 + t1 * length
            z0, z1 = arch * math.sin(math.pi * t0), arch * math.sin(math.pi * t1)
            ang = math.atan2(z1 - z0, y1 - y0)
            ln = math.hypot(y1 - y0, z1 - z0)
            kit.box(a, "WoodDark", (sx * width * 0.42, (y0 + y1) / 2, (z0 + z1) / 2), (0.6, ln + 0.1, 0.6), rot=(ang, 0, 0), bevel=0.05)
            if rails:
                kit.box(a, "Wood", (sx * width * 0.47, (y0 + y1) / 2, (z0 + z1) / 2 + 2.4), (0.4, ln + 0.1, 0.4), rot=(ang, 0, 0), bevel=0.05)
        if rails:
            for k in range(segs + 1):
                t = k / segs
                y = -length / 2 + t * length
                z = arch * math.sin(math.pi * t)
                kit.block(a, "WoodDark", (sx * width * 0.47, y, z - 0.6), (0.55, 0.55, 3.3), bevel=0.06)
    return a


def log(name, seed, length=8.0, r=1.1):
    a = kit.Asset(name, seed)
    kit.prism(a, "Trunk", (-length / 2, 0, r * 0.85), 8, r, r, length, rot=(0, math.pi / 2, 0))
    kit.prism(a, "Wood", (-length / 2 - 0.05, 0, r * 0.85), 8, r * 0.82, r * 0.82, 0.1, rot=(0, math.pi / 2, 0))
    kit.prism(a, "Wood", (length / 2 - 0.05, 0, r * 0.85), 8, r * 0.82, r * 0.82, 0.1, rot=(0, math.pi / 2, 0))
    kit.block(a, "Trunk", (length * 0.15, 0, r * 1.5), (0.5, 0.5, 1.6), rot=(0.4, 0.2, 0), bevel=0.05, taper=0.6)
    return a


def stump(name, seed, r=1.7, h=1.8):
    a = kit.Asset(name, seed)
    kit.prism(a, "Trunk", (0, 0, -0.4), 8, r * 1.05, r, h + 0.4, jitter=0.05)
    kit.prism(a, "Wood", (0, 0, h - 0.02), 8, r * 0.85, r * 0.85, 0.12)
    for i in range(4):
        ang = i * math.pi / 2 + R(a, -0.3, 0.3)
        kit.block(a, "Trunk", (math.cos(ang) * r * 0.9, math.sin(ang) * r * 0.9, -0.4), (r * 0.9, r * 0.5, 1.1), rot=(0, 0, ang), bevel=0.06, taper=0.4)
    return a


def mushroom_small(name, seed, h=1.8, r=1.1, spots=True):
    a = kit.Asset(name, seed)
    kit.prism(a, "Stem", (0, 0, -0.3), 7, r * 0.35, r * 0.28, h + 0.3)
    kit.prism(a, "Cap", (0, 0, h - 0.1), 8, r, r * 0.35, r * 0.75)
    if spots:
        for i in range(4):
            ang = i * math.pi / 2 + R(a, -0.4, 0.4)
            kit.box(a, "Spot", (math.cos(ang) * r * 0.62, math.sin(ang) * r * 0.62, h + r * 0.28), (0.28, 0.28, 0.12), rot=(math.sin(ang) * 0.5, -math.cos(ang) * 0.5, ang), bevel=0.03)
    return a


def flag_pole(name, seed, h=12.0, fw=4.0, fh=2.6):
    a = kit.Asset(name, seed)
    kit.block(a, "StoneDark", (0, 0, -0.4), (1.8, 1.8, 1.0), bevel=0.12)
    kit.block(a, "Metal", (0, 0, 0.5), (0.4, 0.4, h), bevel=0.04)
    kit.block(a, "Gold", (0, 0, h + 0.4), (0.8, 0.8, 0.8), bevel=0.2)
    # wavy banner in 3 strips (bannerets): local X out from the pole
    for i in range(4):
        x = 0.3 + (i + 0.5) * fw / 4
        kit.box(a, "Cloth" if i % 2 == 0 else "Cloth2", (x, 0.15 * math.sin(i * 1.4), h - fh / 2 - 0.2), (fw / 4 + 0.02, 0.18, fh), rot=(0, 0, 0.2 * math.cos(i * 1.4)))
    return a
