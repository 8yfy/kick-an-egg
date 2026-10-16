# Batch 1 zone kits: Meadow (windmill, hay, beehives, sunflowers, scarecrow, cart), Sandy Beach (palms, lighthouse,
# dock, umbrella, shells, starfish, driftwood, beach hut, tropical plants), Autumn Forest (maple, leaf piles,
# pumpkins, cabin, the Hollow Oak), Mushroom Grove (giant mushrooms, mushroom houses, root arches, glow shrooms, the
# Mushroom Tower), and far-scenery silhouettes (forest blobs, clouds). Origin = base centre, front = -Y.
import math

from mathutils import Vector

import kit
import lib_hub as H
import lib_nature as N
from lib_nature import R


# ---------------------------------------------------------------- Meadow


def windmill(name, seed, h=30.0):
    """Meadow windmill: studless stone base, tapered wooden tower with plank bands, a cap roof, a door, two windows,
    a balcony; the sails are a separate asset (WindmillSails) spun in game around the hub at (0, -2.2, h*0.86)."""
    a = kit.Asset(name, seed)
    kit.prism(a, "Stone", (0, 0, -0.5), 8, 7.2, 6.6, 4.5, rot=(0, 0, math.pi / 8))
    kit.prism(a, "StoneDark", (0, 0, 3.9), 8, 6.9, 6.9, 0.6, rot=(0, 0, math.pi / 8))
    kit.prism(a, "Wall", (0, 0, 4.4), 8, 6.2, 4.4, h * 0.62, rot=(0, 0, math.pi / 8))
    for k in range(3):
        z = 4.4 + h * 0.62 * (0.25 + 0.3 * k)
        r = 6.2 - (6.2 - 4.4) * (0.25 + 0.3 * k)
        kit.prism(a, "Wood", (0, 0, z), 8, r + 0.25, r + 0.2, 0.6, rot=(0, 0, math.pi / 8))
    top = 4.4 + h * 0.62
    kit.prism(a, "WoodDark", (0, 0, top - 0.2), 8, 5.4, 5.4, 0.8, rot=(0, 0, math.pi / 8))
    # balcony ring with posts
    for i in range(16):
        ang = 2 * math.pi * i / 16
        kit.block(a, "WoodDark", (math.cos(ang) * 5.2, math.sin(ang) * 5.2, top + 0.6), (0.3, 0.3, 1.6))
    kit.prism(a, "Wood", (0, 0, top + 2.0), 16, 5.35, 5.35, 0.3)
    # cap roof (onion-ish faceted cone)
    kit.prism(a, "Roof", (0, 0, top + 0.6), 8, 4.9, 3.6, 2.4, rot=(0, 0, math.pi / 8))
    kit.prism(a, "Roof", (0, 0, top + 3.0), 8, 3.6, 0.01, 4.2, rot=(0, 0, math.pi / 8))
    kit.block(a, "Gold", (0, 0, top + 7.0), (0.6, 0.6, 1.4), bevel=0.15, taper=0.3)
    # door, windows
    kit.block(a, "WoodDark", (0, -6.1, 3.9), (3.0, 1.0, 5.0), bevel=0.1)
    kit.block(a, "Trim", (0, -6.3, 8.9), (3.8, 0.6, 0.6))
    for z in (h * 0.3, h * 0.48):
        kit.block(a, "Glass", (0, -5.5 + (z - 4.4) / (h * 0.62) * 1.6, z), (1.8, 0.6, 2.2))
        kit.block(a, "Trim", (0, -5.6 + (z - 4.4) / (h * 0.62) * 1.6, z - 0.3), (2.4, 0.5, 0.4))
    # axle housing at the front of the cap
    kit.box(a, "WoodDark", (0, -4.6, h * 0.86), (1.6, 3.0, 1.6), rot=(math.pi / 2, 0, 0), bevel=0.2)
    return a


def windmill_sails(name, seed, r=14.0):
    """Four lattice sails around the hub (local origin = hub centre; sails in the XZ plane, facing -Y)."""
    a = kit.Asset(name, seed)
    kit.prism(a, "Gold", (0, 0.4, 0), 8, 1.1, 0.9, 1.2, rot=(math.pi / 2, 0, 0))
    for i in range(4):
        ang = i * math.pi / 2 + math.pi / 4
        c, s = math.cos(ang), math.sin(ang)
        kit.box(a, "WoodDark", (c * r / 2, 0, s * r / 2), (r, 0.5, 0.6), rot=(0, -ang, 0))
        # sail cloth panel on one side of the spar, with lattice slats
        px, pz = c * r * 0.58 - s * 1.6, s * r * 0.58 + c * 1.6
        kit.box(a, "Cloth2", (px, 0.15, pz), (r * 0.72, 0.2, 3.0), rot=(0, -ang, 0))
        for k in range(4):
            t = 0.28 + k * 0.2
            kit.box(a, "Wood", (c * r * t - s * 1.6, -0.05, s * r * t + c * 1.6), (0.3, 0.3, 3.2), rot=(0, -ang, 0))
    return a


def hay_bale(name, seed, round_=True):
    a = kit.Asset(name, seed)
    if round_:
        kit.prism(a, "Sand", (0, -1.6, 1.7), 12, 1.8, 1.8, 3.2, rot=(-math.pi / 2, 0, 0))
        for y in (-1.0, 0.0, 1.0):
            kit.prism(a, "Dirt", (0, y - 0.15, 1.7), 12, 1.84, 1.84, 0.3, rot=(-math.pi / 2, 0, 0))
        kit.prism(a, "Trim", (0, -1.65, 1.7), 12, 1.3, 1.3, 0.05, rot=(-math.pi / 2, 0, 0))
    else:
        kit.block(a, "Sand", (0, 0, -0.2), (4.2, 2.6, 2.4), bevel=0.25)
        for x in (-1.0, 1.0):
            kit.block(a, "Dirt", (x, 0, -0.25), (0.25, 2.7, 2.5))
    return a


def hay_stack(name, seed):
    a = kit.Asset(name, seed)
    kit.block(a, "Sand", (0, 0, -0.2), (4.2, 2.6, 2.4), bevel=0.25)
    kit.block(a, "Sand", (2.3, 0.4, -0.2), (4.2, 2.6, 2.4), rot=(0, 0, 0.2), bevel=0.25)
    kit.block(a, "Sand", (1.1, 0.2, 2.1), (4.2, 2.6, 2.4), rot=(0, 0, -0.1), bevel=0.25)
    for x in (-1.0, 1.0):
        kit.block(a, "Dirt", (x, 0, -0.25), (0.25, 2.7, 2.5))
    return a


def beehive(name, seed):
    a = kit.Asset(name, seed)
    kit.block(a, "WoodDark", (0, 0, -0.3), (2.4, 2.4, 1.6), bevel=0.1)
    for i, s in enumerate((2.0, 2.3, 2.0, 1.6)):
        kit.prism(a, "Gold", (0, 0, 1.3 + i * 0.9), 10, s / 1.5, s / 1.5, 0.95)
    kit.prism(a, "Gold", (0, 0, 4.9), 10, 0.9, 0.2, 0.6)
    kit.block(a, "Dark", (0, -1.1, 1.8), (0.6, 0.4, 0.5))
    return a


def sunflower(name, seed, h=7.0):
    a = kit.Asset(name, seed)
    kit.block(a, "Leaf", (0, 0, -0.3), (0.35, 0.35, h + 0.3))
    for z in (h * 0.35, h * 0.6):
        kit.box(a, "LeafDark", (0.9, 0, z), (1.8, 0.2, 0.8), rot=(0, -0.4, 0.3))
        kit.box(a, "LeafDark", (-0.9, 0, z + 0.6), (1.8, 0.2, 0.8), rot=(0, 0.4, -0.3))
    kit.prism(a, "Gold", (0, -0.25, h + 0.6), 12, 1.9, 1.9, 0.3, rot=(math.pi / 2 - 0.25, 0, 0))
    kit.prism(a, "Trunk", (0, -0.45, h + 0.6 + 0.07), 10, 0.95, 0.95, 0.35, rot=(math.pi / 2 - 0.25, 0, 0))
    return a


def scarecrow(name, seed):
    a = kit.Asset(name, seed)
    kit.block(a, "WoodDark", (0, 0, -0.4), (0.5, 0.5, 7.4))
    kit.box(a, "WoodDark", (0, 0, 5.0), (5.2, 0.4, 0.4))
    kit.block(a, "Cloth", (0, 0, 3.0), (2.0, 1.2, 2.6), bevel=0.2, taper=0.8)
    for sx in (-1, 1):
        kit.box(a, "Cloth", (sx * 1.6, 0, 5.0), (1.4, 0.8, 0.8), bevel=0.1)
        kit.box(a, "Sand", (sx * 2.5, 0, 5.0), (0.6, 0.6, 0.6), rot=(0.4, 0.3, 0))
    kit.block(a, "Sand", (0, 0, 5.6), (1.5, 1.5, 1.5), bevel=0.25)
    kit.prism(a, "Wood", (0, 0, 7.0), 10, 1.6, 1.6, 0.25)
    kit.prism(a, "Wood", (0, 0, 7.2), 10, 0.85, 0.65, 1.0)
    kit.box(a, "Dark", (-0.35, -0.75, 6.4), (0.2, 0.1, 0.2))
    kit.box(a, "Dark", (0.35, -0.75, 6.4), (0.2, 0.1, 0.2))
    return a


def cart(name, seed):
    a = kit.Asset(name, seed)
    kit.block(a, "Wood", (0, 0, 1.6), (4.0, 6.0, 0.4), bevel=0.06)
    for sx in (-1, 1):
        kit.block(a, "Wood", (sx * 1.9, 0, 2.0), (0.3, 6.0, 1.4), bevel=0.05)
    for sy in (-1, 1):
        kit.block(a, "Wood", (0, sy * 2.9, 2.0), (4.0, 0.3, 1.4), bevel=0.05)
    for sx in (-1, 1):
        kit.prism(a, "WoodDark", (sx * 2.3, -1.4, 1.2), 10, 1.3, 1.3, 0.35, rot=(0, math.pi / 2, 0))
    kit.box(a, "WoodDark", (0.6, -4.6, 1.6), (0.3, 3.4, 0.3), rot=(0.25, 0, 0))
    kit.box(a, "WoodDark", (-0.6, -4.6, 1.6), (0.3, 3.4, 0.3), rot=(0.25, 0, 0))
    N.boulder(a, "Accent", (0, 0.6, 1.9), (1.4, 1.2, 0.8), n=10)
    N.boulder(a, "Accent2", (0.6, -1.4, 1.9), (1.1, 1.0, 0.7), n=10)
    return a


# ---------------------------------------------------------------- Sandy Beach


def palm(name, seed, h=18.0, lean=0.35, fronds=8):
    """Segmented, smoothly curving palm trunk (overlapping beveled rings shrinking upward), a crown of long arching
    fronds (4 tapered segments: rising, then arching down; widest in the middle), a young frond pointing up, and
    coconuts."""
    a = kit.Asset(name, seed)
    seg = 11
    pos = Vector((0, 0, -0.4))
    for i in range(seg):
        t = i / seg
        w = 1.6 * (1 - 0.32 * t)
        ang = lean * (t ** 1.6) * 1.5
        dirv = Vector((math.sin(ang), 0, math.cos(ang)))
        sl = h / seg
        kit.block(a, "Trunk" if i % 2 == 0 else "Wood", tuple(pos), (w, w, sl + 0.5), rot=(0, ang, 0.12 * i), bevel=0.14, taper=0.88)
        pos = pos + dirv * sl
    top = pos
    for i in range(3):
        a2 = i * 2 * math.pi / 3 + 0.4
        kit.box(a, "WoodDark", tuple(top + Vector((math.cos(a2) * 0.7, math.sin(a2) * 0.7, -0.7))), (0.95, 0.95, 0.95), bevel=0.28)
    for i in range(fronds):
        fa = 2 * math.pi * i / fronds + R(a, -0.25, 0.25)
        dirh = Vector((math.cos(fa), math.sin(fa), 0))
        L = R(a, 7.0, 9.0)
        p = top.copy() + Vector((0, 0, 0.2))
        droops = (-0.35, 0.05, 0.45, 0.85)
        widths = (1.1, 2.0, 1.8, 0.9)
        for k in range(4):
            droop = droops[k] + R(a, -0.08, 0.08)
            d = dirh * math.cos(droop) + Vector((0, 0, -math.sin(droop)))
            seglen = L / 4
            c = p + d * seglen / 2
            kit.box(a, "Leaf" if (i + k) % 2 == 0 else "LeafDark", tuple(c), (seglen + 0.35, widths[k], 0.2), rot=(0, droop, fa), bevel=0.03)
            p = p + d * seglen
    kit.block(a, "LeafLight", tuple(top + Vector((0, 0, -0.4))), (1.1, 1.1, 1.8), rot=(0.15, 0.1, 0.6), bevel=0.15, taper=0.35)
    return a

def lighthouse(name, seed, h=46.0):
    """Beach lighthouse on a rocky foot: red / white banded tapered tower, a gallery with railing, a glass lantern
    room (Glow core, a beam is added in game), a red cap; a little keeper door."""
    a = kit.Asset(name, seed)
    for k in range(4):
        N.boulder(a, "Stone" if k % 2 else "StoneDark", (math.cos(k * 1.7) * 6, math.sin(k * 1.7) * 6, -1.0), (R(a, 3, 5), R(a, 3, 4.5), R(a, 2.5, 4)), n=12)
    kit.prism(a, "Stone", (0, 0, -0.8), 10, 9.0, 8.4, 4.2)
    tower_h = h * 0.7
    bands = 6
    for k in range(bands):
        t0, t1 = k / bands, (k + 1) / bands
        r0, r1 = 6.2 - 2.2 * t0, 6.2 - 2.2 * t1
        kit.prism(a, "Cloth" if k % 2 == 0 else "Cloth2", (0, 0, 3.4 + tower_h * t0), 12, r0, r1, tower_h / bands)
    top = 3.4 + tower_h
    kit.prism(a, "Trim", (0, 0, top), 12, 5.6, 5.6, 0.9)
    for i in range(18):
        ang = 2 * math.pi * i / 18
        kit.block(a, "Metal", (math.cos(ang) * 5.2, math.sin(ang) * 5.2, top + 0.9), (0.3, 0.3, 2.0))
    kit.prism(a, "Metal", (0, 0, top + 2.8), 18, 5.35, 5.35, 0.3)
    kit.prism(a, "Glass", (0, 0, top + 0.9), 10, 3.0, 3.0, 4.6)
    kit.prism(a, "Glow", (0, 0, top + 1.6), 8, 1.6, 1.6, 3.0)
    for i in range(10):
        ang = 2 * math.pi * i / 10
        kit.block(a, "Metal", (math.cos(ang) * 3.0, math.sin(ang) * 3.0, top + 0.9), (0.25, 0.25, 4.6))
    kit.prism(a, "Cloth", (0, 0, top + 5.5), 10, 3.6, 0.6, 3.4)
    kit.block(a, "Gold", (0, 0, top + 8.8), (0.6, 0.6, 1.6), bevel=0.15, taper=0.3)
    kit.block(a, "WoodDark", (0, -6.2, 3.3), (2.6, 1.2, 4.2), bevel=0.1)
    for z in (tower_h * 0.35, tower_h * 0.65):
        rr = 6.2 - 2.2 * (z / tower_h)
        kit.block(a, "Glass", (0, -rr + 0.1, 3.4 + z), (1.4, 0.6, 2.0))
    return a


def dock(name, seed, length=24.0, width=6.0):
    """Wooden pier running along local -Y from the shore (y = 0), planks on posts, bollards and a lantern."""
    a = kit.Asset(name, seed)
    n = int(length / 1.2)
    for i in range(n):
        y = -i * 1.2 - 0.6
        kit.box(a, "Wood" if i % 3 else "WoodDark", (R(a, -0.08, 0.08), y, 1.2), (width * R(a, 0.97, 1.03), 1.1, 0.35), rot=(0, 0, R(a, -0.02, 0.02)), bevel=0.05)
    for k in range(int(length / 6) + 1):
        y = -k * 6
        for sx in (-1, 1):
            kit.block(a, "WoodDark", (sx * width * 0.46, y, -4.0), (0.9, 0.9, 5.2 + (0.7 if k % 2 else 0)), bevel=0.1)
    for sx in (-1, 1):
        kit.box(a, "WoodDark", (sx * width * 0.5, -length / 2, 1.6), (0.4, length, 0.4))
    kit.block(a, "Metal", (width * 0.35, -length + 1.2, 1.35), (0.8, 0.8, 0.9), bevel=0.2)
    kit.block(a, "Metal", (-width * 0.35, -length + 1.2, 1.35), (0.8, 0.8, 0.9), bevel=0.2)
    return a


def beach_umbrella(name, seed):
    a = kit.Asset(name, seed)
    kit.block(a, "Trim", (0, 0, -0.5), (0.3, 0.3, 7.5), rot=(0.12, 0, 0))
    for i in range(8):
        ang = 2 * math.pi * i / 8
        kit.frustum_rect(a, "Cloth" if i % 2 else "Cloth2", (math.cos(ang) * 1.6, math.sin(ang) * 1.6 + 0.8, 6.0), 3.3, 0.3, 0.2, 0.2, 1.2, rot=(0, 0, ang + math.pi / 2), shift=(0, 0))
    kit.prism(a, "Cloth", (0, 0.8, 6.6), 8, 3.6, 0.3, 1.0)
    kit.block(a, "Cloth2", (2.4, -1.2, -0.2), (2.4, 4.6, 0.3), rot=(0, 0, 0.3))
    return a


def shell(name, seed, s=1.0):
    a = kit.Asset(name, seed)
    for i in range(7):
        ang = (i - 3) * 0.32
        kit.box(a, "Accent2" if i % 2 else "Trim", (math.sin(ang) * 0.9 * s, -math.cos(ang) * 0.3 * s, 0.3 * s), (0.42 * s, 1.8 * s, 0.4 * s), rot=(0.2, 0, ang), bevel=0.08 * s)
    kit.block(a, "Trim", (0, 0.7 * s, -0.1), (0.9 * s, 0.6 * s, 0.6 * s), bevel=0.1 * s)
    return a


def starfish(name, seed):
    a = kit.Asset(name, seed)
    for i in range(5):
        ang = 2 * math.pi * i / 5
        kit.box(a, "Accent", (math.cos(ang) * 0.9, math.sin(ang) * 0.9, 0.2), (1.9, 0.75, 0.45), rot=(0, 0, ang), bevel=0.12)
    kit.prism(a, "Accent", (0, 0, 0.0), 5, 0.7, 0.6, 0.55)
    return a


def driftwood(name, seed):
    a = kit.Asset(name, seed)
    kit.box(a, "Wood", (0, 0, 0.6), (9.0, 1.3, 1.1), rot=(0, 0.06, 0.1), bevel=0.3, taper=0.8)
    kit.box(a, "Wood", (2.5, 1.2, 0.8), (3.2, 0.7, 0.6), rot=(0.2, 0.3, 0.8), bevel=0.15)
    kit.box(a, "WoodDark", (-3.0, -0.8, 0.9), (2.6, 0.6, 0.5), rot=(0.1, -0.4, -0.6), bevel=0.12)
    return a


def beach_hut(name, seed):
    """Little thatched beach hut on stilts with a ladder, palm-leaf roof and a striped awning."""
    a = kit.Asset(name, seed)
    for sx in (-1, 1):
        for sy in (-1, 1):
            kit.block(a, "WoodDark", (sx * 4.2, sy * 3.6, -0.4), (0.8, 0.8, 4.4))
    kit.block(a, "Wood", (0, 0, 3.8), (10.0, 8.6, 0.6), bevel=0.1)
    kit.block(a, "Wall", (0, 0.6, 4.4), (8.6, 6.6, 5.4), bevel=0.15)
    kit.block(a, "WoodDark", (0, -2.8, 4.4), (2.6, 0.6, 4.0))
    for sx in (-1, 1):
        kit.block(a, "Glass", (sx * 4.35, 0.6, 6.2), (0.3, 2.2, 1.8))
    # thatch roof: two slopes of overlapping tiers
    for side in (-1, 1):
        for k in range(3):
            kit.box(a, "Sand" if k % 2 == 0 else "Dirt", (0, side * (1.2 + k * 1.4), 11.6 - k * 1.1), (11.4, 3.2, 0.5), rot=(-side * 0.62, 0, 0), bevel=0.1)
    kit.box(a, "Dirt", (0, 0, 12.6), (11.4, 1.0, 0.8))
    for i in range(6):
        kit.box(a, "Wood", (2.2, -5.0 - i * 0.05, 0.4 + i * 0.6), (1.8, 0.3, 0.2))
    return a


def tropical_plant(name, seed, n=6, h=3.6):
    a = kit.Asset(name, seed)
    kit.block(a, "LeafDark", (0, 0, -0.3), (0.8, 0.8, 1.2), bevel=0.1, taper=0.6)
    for i in range(n):
        ang = 2 * math.pi * i / n + R(a, -0.2, 0.2)
        L = h * R(a, 0.8, 1.1)
        kit.box(a, "Leaf" if i % 2 else "LeafLight", (math.cos(ang) * L * 0.4, math.sin(ang) * L * 0.4, L * 0.5), (L, 1.4, 0.18), rot=(0, -0.9, ang), bevel=0.04)
    return a


# ---------------------------------------------------------------- Autumn Forest


def maple(name, seed, height=17.0, width=14.0, tw=2.0):
    """Autumn maple: thick trunk, wide flat stacked canopy discs (faceted, 3 tiers) in Leaf / LeafDark / LeafLight."""
    a = kit.Asset(name, seed)
    N.trunk(a, height * 0.42, tw)
    base = height * 0.38
    for k, (wf, role) in enumerate(((1.0, "LeafDark"), (0.82, "Leaf"), (0.55, "LeafLight"))):
        z = base + k * height * 0.17
        w = width * wf
        kit.prism(a, role, (R(a, -0.4, 0.4), R(a, -0.4, 0.4), z), 9, w / 2, w / 2 * 0.86, height * 0.2, rot=(0, 0, R(a, 0, 1)), jitter=0.08)
    kit.prism(a, "LeafLight", (0, 0, base + 3 * height * 0.17), 7, width * 0.2, 0.3, height * 0.12, rot=(0, 0, 0.4))
    return a


def leaf_pile(name, seed, r=3.0):
    a = kit.Asset(name, seed)
    N.boulder(a, "Leaf", (0, 0, -0.4), (r, r * 0.8, r * 0.38), n=14, flat=0.2)
    for i in range(7):
        ang = R(a, 0, 2 * math.pi)
        rr = R(a, 0.05, 0.55)
        x, y = math.cos(ang) * rr * r, math.sin(ang) * rr * r * 0.8
        z = -0.4 + r * 0.38 * 1.2 * math.sqrt(max(0.0, 1 - rr * rr)) * 0.72
        kit.box(a, "LeafDark" if i % 2 else "LeafLight", (x, y, z), (0.9, 0.7, 0.15), rot=(R(a, -0.3, 0.3), R(a, -0.3, 0.3), ang))
    return a

def pumpkin(name, seed, r=1.6):
    a = kit.Asset(name, seed)
    for i in range(7):
        ang = 2 * math.pi * i / 7
        kit.blob(a, "Accent", (math.cos(ang) * r * 0.42, math.sin(ang) * r * 0.42, r * 0.62), r * 0.6, scale=(0.72, 0.72, 1.0), subdiv=2, jitter=0.0, rot=(0, 0, ang))
    kit.block(a, "Trunk", (0, 0, r * 1.05), (0.4, 0.4, 0.9), rot=(0.25, 0, 0), bevel=0.06)
    kit.box(a, "Leaf", (0.6, 0.2, r * 1.3), (1.0, 0.7, 0.12), rot=(0.3, 0.2, 0.6))
    return a


def cabin(name, seed):
    """Log cabin: stacked log walls (alternating tones) on a stone foot, a steep shingled roof with a chimney, a door
    with a lantern, two framed windows and a little porch."""
    a = kit.Asset(name, seed)
    kit.block(a, "Stone", (0, 0, -0.5), (15.0, 12.0, 1.4), bevel=0.25)
    W, D, hh = 13.0, 10.0, 7.0
    n = 7
    for k in range(n):
        z = 0.9 + k * hh / n
        role = "Trunk" if k % 2 == 0 else "Wood"
        for sy in (-1, 1):
            kit.box(a, role, (0, sy * D / 2, z + 0.5), (W + 1.2, 1.0, 1.0), rot=(0, 0, 0), bevel=0.25)
        for sx in (-1, 1):
            kit.box(a, role, (sx * W / 2, 0, z + 0.5 + 0.5), (1.0, D + 1.2, 1.0), bevel=0.25)
    kit.block(a, "WoodDark", (0, 0, 0.9), (W - 0.6, D - 0.6, hh))
    top = 0.9 + hh
    # gable roof
    for side in (-1, 1):
        for k in range(4):
            kit.box(a, "Roof" if k % 2 == 0 else "RoofDark", (0, side * (1.4 + k * 1.55), top + 4.6 - k * 1.25), (W + 2.4, 2.3, 0.45), rot=(-side * 0.68, 0, 0), bevel=0.06)
    for sx in (-1, 1):
        kit.tri_prism(a, "Wood", (sx * W / 2, 0, top), D + 0.6, 5.4, 0.8)
    kit.block(a, "Stone", (W * 0.3, 2.0, top), (2.0, 2.0, 7.0), bevel=0.15)
    kit.block(a, "StoneDark", (W * 0.3, 2.0, top + 6.8), (2.4, 2.4, 0.6), bevel=0.1)
    kit.block(a, "WoodDark", (0, -D / 2 - 0.6, 0.9), (2.8, 0.6, 4.6), bevel=0.08)
    for sx in (-1, 1):
        kit.block(a, "Glass", (sx * 3.8, -D / 2 - 0.55, 3.0), (2.2, 0.4, 2.2))
        kit.block(a, "Trim", (sx * 3.8, -D / 2 - 0.65, 2.7), (2.8, 0.4, 0.4))
    kit.block(a, "Wood", (0, -D / 2 - 2.6, 0.2), (6.0, 3.6, 0.4), bevel=0.05)
    kit.block(a, "Glow", (1.9, -D / 2 - 0.9, 4.2), (0.6, 0.6, 0.8))
    return a


def hollow_oak(name, seed, h=48.0):
    """The Hollow Oak (Autumn landmark): a huge gnarled trunk with buttress roots and a glowing hollow door, branches
    holding a treehouse (plank floor, walls, a little roof, a rope ladder) and a vast layered autumn canopy."""
    a = kit.Asset(name, seed)
    tw = 7.5
    N.trunk(a, h * 0.48, tw, flares=6)
    for i in range(6):
        ang = i * math.pi / 3 + R(a, -0.2, 0.2)
        kit.block(a, "Trunk", (math.cos(ang) * tw * 0.55, math.sin(ang) * tw * 0.55, -0.6), (tw * 0.9, 2.2, 4.5), rot=(0, 0, ang), bevel=0.3, taper=0.3)
    kit.block(a, "Dark", (0, -tw * 0.42, -0.2), (3.4, 1.2, 5.2), bevel=0.4)
    kit.block(a, "Glow", (0, -tw * 0.38, 0.3), (2.6, 0.6, 4.2), bevel=0.3)
    # branches
    for i, ang in enumerate((0.5, 2.4, 4.1)):
        kit.block(a, "Trunk", (math.cos(ang) * 1.5, math.sin(ang) * 1.5, h * 0.36), (2.4, 2.4, h * 0.32), rot=(-math.sin(ang) * 0.9, math.cos(ang) * 0.9, 0), bevel=0.2, taper=0.6)
    # treehouse on the front branch
    tz = h * 0.4
    ty = -12.0
    kit.box(a, "Trunk", (0, -6.0, tz - 1.2), (2.6, 9.0, 2.2), rot=(0.15, 0, 0), bevel=0.25)
    kit.block(a, "Wood", (0, ty, tz), (11.0, 9.0, 0.6), bevel=0.08)
    for sx in (-1, 1):
        for sy in (-1, 1):
            kit.block(a, "WoodDark", (sx * 5.0, ty + sy * 4.0, tz + 0.6), (0.4, 0.4, 1.8))
    kit.box(a, "WoodDark", (0, ty - 4.3, tz + 2.3), (10.4, 0.3, 0.3))
    kit.block(a, "Wall", (0, ty + 0.8, tz + 0.6), (7.6, 6.0, 4.6), bevel=0.12)
    kit.block(a, "WoodDark", (-1.6, ty - 2.3, tz + 0.6), (2.0, 0.4, 3.3))
    kit.block(a, "Glow", (2.2, ty - 2.25, tz + 2.2), (1.8, 0.3, 1.5))
    for side in (-1, 1):
        kit.box(a, "Roof", (0, ty + 0.8 + side * 2.3, tz + 6.6), (9.0, 5.2, 0.45), rot=(-side * 0.6, 0, 0), bevel=0.06)
    kit.tri_prism(a, "Wall", (3.8, ty + 0.8, tz + 5.2), 6.0, 3.0, 0.4)
    kit.tri_prism(a, "Wall", (-3.8, ty + 0.8, tz + 5.2), 6.0, 3.0, 0.4)
    for k in range(7):
        kit.box(a, "Wood", (-3.6, ty - 4.6, tz - 1.0 - k * 1.6), (1.8, 0.25, 0.25))
    for sx in (-4.5, -2.7):
        kit.box(a, "WoodDark", (sx, ty - 4.6, tz - 5.5), (0.12, 0.12, 11.0))
    # canopy: three wide layered tiers of faceted discs plus side clumps
    base = h * 0.55
    for k, (wf, role) in enumerate(((1.0, "LeafDark"), (0.85, "Leaf"), (0.6, "LeafLight"))):
        z = base + k * h * 0.13
        w = 42 * wf
        kit.prism(a, role, (R(a, -1, 1), R(a, -1, 1), z), 10, w / 2, w / 2 * 0.85, h * 0.15, rot=(0, 0, R(a, 0, 1)), jitter=0.07)
    for i in range(5):
        ang = 2 * math.pi * i / 5 + R(a, -0.3, 0.3)
        kit.blob(a, "Leaf" if i % 2 else "LeafDark", (math.cos(ang) * 17, math.sin(ang) * 17 + 3, base + R(a, 3, 7)), R(a, 6, 8), scale=(1, 1, 0.65), subdiv=1, jitter=0.1)
    return a


# ---------------------------------------------------------------- Mushroom Grove


def giant_mushroom(name, seed, h=20.0, cap=12.0, style="dome", bend=0.25, spots=8, gills=True):
    """Giant mushroom: a bent, segmented stem (Stem) with a ring skirt, a cap (Cap) shaped by `style` (dome, flat,
    cone, bell), Spot dots on top and a glowing gill underside (Glow)."""
    a = kit.Asset(name, seed)
    seg = 6
    pos = Vector((0, 0, -0.5))
    w0 = cap * 0.22
    for i in range(seg):
        t = i / seg
        ang = bend * math.sin(t * math.pi * 0.8)
        d = Vector((math.sin(ang), 0, math.cos(ang)))
        sl = h / seg
        kit.prism(a, "Stem", tuple(pos), 8, w0 * (1.2 - 0.35 * t), w0 * (1.2 - 0.35 * (t + 1 / seg)), sl + 0.3, rot=(0, ang, 0))
        pos = pos + d * sl
    top = pos
    kit.prism(a, "Stem", tuple(top + Vector((0, 0, -h * 0.35))), 10, w0 * 1.9, w0 * 1.0, 1.2)
    r = cap / 2
    if gills:
        kit.prism(a, "Glow", tuple(top + Vector((0, 0, -0.2))), 12, r * 0.92, r * 0.3, 0.5)
    if style == "dome":
        kit.prism(a, "Cap", tuple(top), 12, r, r * 0.86, r * 0.35)
        kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.35))), 12, r * 0.86, r * 0.5, r * 0.32)
        kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.67))), 12, r * 0.5, 0.01, r * 0.2)
        crown = r * 0.7
    elif style == "flat":
        kit.prism(a, "Cap", tuple(top), 12, r, r * 0.92, r * 0.22)
        kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.22))), 12, r * 0.92, r * 0.3, r * 0.14)
        crown = r * 0.3
    elif style == "cone":
        kit.prism(a, "Cap", tuple(top), 10, r, r * 0.55, r * 0.5)
        kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.5))), 10, r * 0.55, 0.01, r * 0.7)
        crown = r * 0.8
    else:  # bell
        kit.prism(a, "Cap", tuple(top + Vector((0, 0, -r * 0.25))), 12, r * 0.95, r, r * 0.35)
        kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.1))), 12, r, r * 0.6, r * 0.5)
        kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.6))), 12, r * 0.6, 0.01, r * 0.3)
        crown = r * 0.7
    for i in range(spots):
        ang = 2 * math.pi * i / spots + R(a, -0.3, 0.3)
        rr = r * R(a, 0.35, 0.72)
        z = top.z + crown * (1 - (rr / r) ** 2) * 0.9 + 0.05
        kit.box(a, "Spot", (top.x + math.cos(ang) * rr, top.y + math.sin(ang) * rr, z + 0.15), (r * 0.24, r * 0.24, 0.5), rot=(math.sin(ang) * 0.55, -math.cos(ang) * 0.55, ang), bevel=0.08)
    return a


def mushroom_house(name, seed):
    """Mushroom house: a fat stem as the walls (Stem), a round door, porthole windows (Glow), a spotted dome cap roof,
    a crooked chimney and a little stoop."""
    a = kit.Asset(name, seed)
    kit.prism(a, "Stem", (0, 0, -0.5), 12, 6.2, 5.4, 10.5)
    kit.prism(a, "StoneDark", (0, 0, -0.6), 12, 6.6, 6.6, 0.9)
    kit.prism(a, "WoodDark", (0, -5.9, 2.4), 10, 1.7, 1.7, 0.6, rot=(math.pi / 2, 0, 0))
    kit.block(a, "WoodDark", (0, -5.6, 0.2), (3.4, 1.0, 2.6), bevel=0.15)
    kit.block(a, "Gold", (0.9, -6.25, 1.6), (0.3, 0.3, 0.3), bevel=0.08)
    for ang, z in ((0.9, 5.8), (-0.95, 6.6), (2.6, 5.4)):
        x, y = math.sin(ang) * 5.75, -math.cos(ang) * 5.75
        kit.prism(a, "Trim", (x, y, z), 10, 1.15, 1.15, 0.5, rot=(math.pi / 2, 0, -ang))
        kit.prism(a, "Glow", (x * 1.02, y * 1.02, z), 10, 0.8, 0.8, 0.52, rot=(math.pi / 2, 0, -ang))
    kit.prism(a, "Cap", (0, 0, 9.4), 14, 10.0, 8.6, 3.4)
    kit.prism(a, "Cap", (0, 0, 12.8), 14, 8.6, 4.6, 3.0)
    kit.prism(a, "Cap", (0, 0, 15.8), 14, 4.6, 0.01, 1.6)
    kit.prism(a, "Glow", (0, 0, 9.2), 14, 9.4, 4.0, 0.4)
    for i in range(10):
        ang = 2 * math.pi * i / 10 + R(a, -0.25, 0.25)
        rr = R(a, 4.0, 8.0)
        z = 9.4 + 3.4 * (1 - (rr - 4) / 6) + (3.0 if rr < 6 else 0.6) * 0.6
        kit.box(a, "Spot", (math.cos(ang) * rr, math.sin(ang) * rr, z + 1.2), (1.4, 1.4, 0.3), rot=(math.sin(ang) * 0.45, -math.cos(ang) * 0.45, ang), bevel=0.08)
    kit.block(a, "Stone", (3.5, 2.0, 12.0), (1.6, 1.6, 5.2), rot=(0.1, 0.15, 0.2), bevel=0.15)
    kit.block(a, "StoneDark", (3.9, 2.2, 16.9), (2.0, 2.0, 0.6), rot=(0.1, 0.15, 0.2), bevel=0.1)
    return a


def root_arch(name, seed, span=14.0, h=8.0):
    """Twisted root arch (decor beside the track, never over it): two gnarled legs meeting over a gap, knobs."""
    a = kit.Asset(name, seed)
    n = 9
    for i in range(n):
        t = i / (n - 1)
        x = -span / 2 + t * span
        z = h * math.sin(math.pi * t)
        ang = math.atan2(h * math.pi * math.cos(math.pi * t) / span, 1)
        w = 2.4 * (1.15 - 0.4 * math.sin(math.pi * t))
        kit.box(a, "Trunk" if i % 2 else "WoodDark", (x, R(a, -0.3, 0.3), z + 0.4), (span / (n - 1) + 1.0, w, w), rot=(R(a, -0.2, 0.2), -ang, R(a, -0.15, 0.15)), bevel=0.3)
    for sx in (-1, 1):
        for k in range(3):
            ang = R(a, 0, 2 * math.pi)
            kit.block(a, "Trunk", (sx * span / 2 + math.cos(ang) * 1.4, math.sin(ang) * 1.4, -0.5), (1.0, 3.0, 1.0), rot=(0.6 * math.sin(ang), 0.6 * math.cos(ang), ang), bevel=0.15, taper=0.4)
    kit.blob(a, "Leaf", (R(a, -2, 2), 0, h + 1.0), 1.6, scale=(1.4, 1, 0.6), subdiv=1, jitter=0.1)
    return a


def glow_shrooms(name, seed, n=6):
    a = kit.Asset(name, seed)
    for i in range(n):
        ang = 2 * math.pi * i / n + R(a, -0.4, 0.4)
        rr = R(a, 0.2, 1.8)
        h = R(a, 0.8, 2.6)
        x, y = math.cos(ang) * rr, math.sin(ang) * rr
        kit.prism(a, "Stem", (x, y, -0.2), 6, 0.22, 0.18, h + 0.2)
        r = R(a, 0.5, 0.9)
        kit.prism(a, "Glow", (x, y, h - 0.05), 8, r, r * 0.3, r * 0.6)
    return a


def mushroom_tower(name, seed, h=58.0):
    """The Mushroom Tower (Mushroom Grove landmark): a towering bent stem with a spiral stair winding round it, round
    glowing windows and doors, two shelf mushrooms as balconies, and a huge spotted dome cap with a glowing rim."""
    a = kit.Asset(name, seed)
    # roots
    for i in range(7):
        ang = 2 * math.pi * i / 7 + R(a, -0.2, 0.2)
        kit.block(a, "Trunk", (math.cos(ang) * 5.5, math.sin(ang) * 5.5, -0.8), (6.0, 2.4, 3.2), rot=(0, 0, ang), bevel=0.4, taper=0.35)
    seg = 8
    pos = Vector((0, 0, -0.6))
    for i in range(seg):
        t = i / seg
        ang = 0.18 * math.sin(t * math.pi)
        d = Vector((math.sin(ang), 0, math.cos(ang)))
        sl = h * 0.8 / seg
        kit.prism(a, "Stem", tuple(pos), 10, 7.0 - 2.6 * t, 7.0 - 2.6 * (t + 1 / seg), sl + 0.3, rot=(0, ang, 0))
        pos = pos + d * sl
    top = pos
    # spiral stair
    steps = 34
    for k in range(steps):
        t = k / steps
        ang = t * math.pi * 4.2
        rr = 7.4 - 2.4 * t
        z = 1.0 + t * h * 0.72
        cx = math.sin(0.18 * math.sin(t * math.pi)) * z
        kit.box(a, "Wood" if k % 2 else "WoodDark", (cx + math.cos(ang) * rr, math.sin(ang) * rr, z), (3.0, 1.4, 0.4), rot=(0, 0, ang), bevel=0.05)
    # windows and door
    for z, ang in ((h * 0.2, -1.6), (h * 0.42, 0.4), (h * 0.6, 2.4), (h * 0.33, 3.6)):
        t = z / (h * 0.8)
        rr = 7.0 - 2.6 * t
        cx = math.sin(0.18 * math.sin(t * math.pi)) * z
        x, y = cx + math.cos(ang) * rr, math.sin(ang) * rr
        kit.prism(a, "Trim", (x, y, z), 10, 1.3, 1.3, 0.5, rot=(math.pi / 2, 0, ang + math.pi / 2))
        kit.prism(a, "Glow", (x * 1.01, y * 1.01, z), 10, 0.9, 0.9, 0.52, rot=(math.pi / 2, 0, ang + math.pi / 2))
    kit.block(a, "WoodDark", (0, -7.0, -0.4), (3.6, 1.6, 5.4), bevel=0.3)
    kit.block(a, "Glow", (0, -7.6, 0.2), (2.6, 0.4, 4.0), bevel=0.2)
    # shelf mushrooms (balconies)
    for z, ang in ((h * 0.35, 0.9), (h * 0.55, -2.2)):
        t = z / (h * 0.8)
        rr = 7.0 - 2.6 * t
        kit.prism(a, "Cap", (math.cos(ang) * (rr + 2.4), math.sin(ang) * (rr + 2.4), z), 10, 4.2, 3.6, 1.2)
        kit.prism(a, "Glow", (math.cos(ang) * (rr + 2.4), math.sin(ang) * (rr + 2.4), z - 0.3), 10, 3.8, 1.2, 0.35)
    # cap
    r = 19.0
    kit.prism(a, "Glow", tuple(top + Vector((0, 0, -0.6))), 16, r * 0.95, r * 0.3, 0.8)
    kit.prism(a, "Cap", tuple(top), 16, r, r * 0.88, r * 0.3)
    kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.3))), 16, r * 0.88, r * 0.55, r * 0.3)
    kit.prism(a, "Cap", tuple(top + Vector((0, 0, r * 0.6))), 16, r * 0.55, 0.01, r * 0.22)
    for i in range(16):
        ang = 2 * math.pi * i / 16 + R(a, -0.15, 0.15)
        rr = r * R(a, 0.3, 0.8)
        z = top.z + r * 0.6 * (1 - (rr / r) ** 1.6) + 0.4
        kit.box(a, "Spot", (top.x + math.cos(ang) * rr, top.y + math.sin(ang) * rr, z + 0.3), (r * 0.2, r * 0.2, 0.8), rot=(math.sin(ang) * 0.5, -math.cos(ang) * 0.5, ang), bevel=0.15)
    return a


# ---------------------------------------------------------------- far scenery


def forest_far(name, seed, w=120.0, d=40.0, n=26, pines=False):
    """A distant forest band as one mesh: many simple trees (balls or cones on short trunks) in two tones."""
    a = kit.Asset(name, seed)
    for i in range(n):
        x = R(a, -w / 2, w / 2)
        y = R(a, -d / 2, d / 2)
        s = R(a, 0.7, 1.4)
        role = "Leaf" if i % 2 else "LeafDark"
        if pines:
            kit.prism(a, role, (x, y, -1), 6, 5 * s, 0.01, 18 * s, rot=(0, 0, R(a, 0, 1)))
        else:
            kit.blob(a, role, (x, y, 8 * s), 6 * s, scale=(1, 1, 0.9), subdiv=1, jitter=0.12)
            kit.block(a, "Trunk", (x, y, -1), (1.5 * s, 1.5 * s, 6 * s))
    return a


def cloud(name, seed, w=30.0, n=6):
    """Blocky stylised cloud: a flat-bottomed cluster of beveled boxes, light on top, shaded underneath."""
    a = kit.Asset(name, seed)
    kit.box(a, "Snow", (0, 0, 2.0), (w, w * 0.45, 4.0), bevel=1.2)
    for i in range(n):
        x = R(a, -w * 0.38, w * 0.38)
        y = R(a, -w * 0.12, w * 0.12)
        s = R(a, w * 0.18, w * 0.3)
        kit.box(a, "Snow" if i % 2 else "Trim", (x, y, 3.0 + s * 0.35), (s, s * 0.8, s * 0.7), rot=(0, 0, R(a, -0.2, 0.2)), bevel=s * 0.15)
    kit.box(a, "Stone", (0, 0, 0.3), (w * 0.9, w * 0.4, 0.8), bevel=0.3)
    return a
