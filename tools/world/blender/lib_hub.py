# Hub hero models: Boxing Sack Shop (vault roof, glove sign, awning, pillars, windows, gym props), Pet Selling Stand
# (canopy, paw topper, posts, pet props), the Golden Egg Fountain, egg monuments, launch-platform trims, hub cliff
# modules and a waterfall. Origins: base centre; front = -Y (Roblox -Z). Roles are recoloured in game.
import math

import bmesh
from mathutils import Matrix, Vector

import kit
import lib_nature as N
from lib_nature import R


# ---------------------------------------------------------------- shared shape helpers


def arch_profile(span, rise, n):
    """Points (x, z) of a flattened semicircle from -span/2 to span/2."""
    pts = []
    for i in range(n + 1):
        t = math.pi * i / n
        pts.append((-math.cos(t) * span / 2, math.sin(t) * rise))
    return pts


def egg_mesh(a, role, base, height, width, rings=8, sides=10, rot=(0, 0, 0)):
    """Faceted egg standing on `base` (wider bottom, pointier top)."""
    bm = a.bm(role)
    verts_rings = []
    for i in range(1, rings):
        t = i / rings
        z = t * height
        # egg radius profile: sin with a bias toward the bottom
        r = (width / 2) * math.sin(math.pi * t) ** 0.62 * (1.0 - 0.12 * t)
        ring = []
        for k in range(sides):
            ang = 2 * math.pi * k / sides + (i % 2) * math.pi / sides
            ring.append(bm.verts.new((math.cos(ang) * r, math.sin(ang) * r, z)))
        verts_rings.append(ring)
    bot = bm.verts.new((0, 0, 0))
    top = bm.verts.new((0, 0, height))
    allv = [bot, top] + [v for r_ in verts_rings for v in r_]
    for k in range(sides):
        bm.faces.new((bot, verts_rings[0][(k + 1) % sides], verts_rings[0][k]))
        bm.faces.new((top, verts_rings[-1][k], verts_rings[-1][(k + 1) % sides]))
    for i in range(len(verts_rings) - 1):
        r0, r1 = verts_rings[i], verts_rings[i + 1]
        for k in range(sides):
            k1 = (k + 1) % sides
            bm.faces.new((r0[k], r0[k1], r1[k1]))
            bm.faces.new((r0[k], r1[k1], r1[k]))
    kit._xf(bm, allv, Matrix.Translation(Vector(base)) @ kit._rot(rot))
    return allv


def vault_strip(a, role, x0, x1, span, rise, n, y0, y1, thick=0.5):
    """One longitudinal strip of a barrel vault between arc steps x0..x1 (indices), from y0 to y1 (length)."""
    pts = arch_profile(span, rise, n)
    bm = a.bm(role)
    out = []
    for i in range(x0, x1):
        (xa, za), (xb, zb) = pts[i], pts[i + 1]
        # outward normals for thickness
        def off(x, z):
            nx, nz = x / (span / 2), z / max(rise, 0.01)
            l = math.hypot(nx, nz) or 1
            return x + nx / l * thick, z + nz / l * thick
        xa2, za2 = off(xa, za)
        xb2, zb2 = off(xb, zb)
        q = [
            bm.verts.new((xa, y0, za)), bm.verts.new((xb, y0, zb)), bm.verts.new((xb, y1, zb)), bm.verts.new((xa, y1, za)),
            bm.verts.new((xa2, y0, za2)), bm.verts.new((xb2, y0, zb2)), bm.verts.new((xb2, y1, zb2)), bm.verts.new((xa2, y1, za2)),
        ]
        bm.faces.new((q[0], q[3], q[2], q[1]))
        bm.faces.new((q[4], q[5], q[6], q[7]))
        bm.faces.new((q[0], q[1], q[5], q[4]))
        bm.faces.new((q[3], q[7], q[6], q[2]))
        bm.faces.new((q[0], q[4], q[7], q[3]))
        bm.faces.new((q[1], q[2], q[6], q[5]))
        out += q
    return out


# ---------------------------------------------------------------- Boxing Sack Shop


def shop_roof(name, seed, span=33.0, length=27.0, rise=8.0, n=10):
    """Barrel-vault gym roof: alternating red/white stripes along its length, chunky gold end ribs and eave
    beams, a filled front gable (WallTop) with a round glowing window and a small clerestory crest on top.
    Local z = 0 is the top of the walls; the vault spans local X, runs along Y (front at -Y)."""
    a = kit.Asset(name, seed)
    half = length / 2
    # stripes run front-to-back: split the arc into n facets, alternate colours per facet
    for i in range(n):
        vault_strip(a, "Roof" if i % 2 == 0 else "Roof2", i, i + 1, span, rise, n, -half - 0.8, half + 0.8, thick=0.55)
    # end ribs (front and back) and two middle ribs
    for y in (-half - 0.9, -half / 3, half / 3, half + 0.9):
        pts = arch_profile(span + 1.4, rise + 0.9, n)
        for i in range(n):
            (xa, za), (xb, zb) = pts[i], pts[i + 1]
            mx, mz = (xa + xb) / 2, (za + zb) / 2
            ang = math.atan2(zb - za, xb - xa)
            ln = math.hypot(xb - xa, zb - za)
            kit.box(a, "Trim", (mx, y, mz - 0.2), (ln + 0.35, 1.1, 1.0), rot=(0, -ang, 0), bevel=0.12)
    # eave beams along both sides
    for sx in (-1, 1):
        kit.box(a, "Trim", (sx * (span / 2 + 0.3), 0, 0.2), (1.4, length + 2.6, 1.3), bevel=0.15)
    # front gable infill (slightly recessed), round window with frame
    gable = arch_profile(span - 0.6, rise - 0.3, n)
    bm = a.bm("WallTop")
    vs = [bm.verts.new((x, -half + 0.2, z)) for x, z in gable]
    vs2 = [bm.verts.new((x, -half + 0.9, z)) for x, z in gable]
    bm.faces.new(vs)
    bm.faces.new(list(reversed(vs2)))
    for i in range(len(vs) - 1):
        bm.faces.new((vs[i], vs2[i], vs2[i + 1], vs[i + 1]))
    bm.faces.new((vs[-1], vs2[-1], vs2[0], vs[0]))
    kit.prism(a, "Trim", (0, -half - 0.1, rise * 0.48), 12, 3.0, 3.0, 0.7, rot=(math.pi / 2, 0, 0))
    kit.prism(a, "Glow", (0, -half - 0.25, rise * 0.48), 12, 2.3, 2.3, 0.4, rot=(math.pi / 2, 0, 0))
    for ang in (0, math.pi / 2):
        kit.box(a, "Trim", (0, -half - 0.55, rise * 0.48), (4.6, 0.3, 0.35), rot=(0, ang, 0))
    # roof crest: a short raised lantern strip on the ridge
    kit.block(a, "Trim", (0, 0, rise + 0.2), (3.2, length * 0.55, 1.0), bevel=0.2)
    kit.block(a, "Glow", (0, 0, rise + 1.15), (2.2, length * 0.5, 0.6), bevel=0.1)
    return a


def boxing_glove(name, seed, size=8.0):
    """Giant boxing glove standing on its cuff, knuckles up and slightly forward (-Y): a big rounded fist (faceted
    ball), a knuckle roll, a thumb hugging the front-left, a white band and a laced cuff. Roles: Cloth (glove),
    Cloth2 (band / cuff stripe), Dark (laces), Trim (cuff rim)."""
    a = kit.Asset(name, seed)
    s = size / 8.0
    # cuff: tapered, with a rim and a white stripe
    kit.prism(a, "Cloth", (0, 0.3 * s, 0), 12, 1.75 * s, 1.95 * s, 2.6 * s)
    kit.prism(a, "Trim", (0, 0.3 * s, -0.15 * s), 12, 1.9 * s, 1.9 * s, 0.5 * s)
    kit.prism(a, "Cloth2", (0, 0.3 * s, 1.5 * s), 12, 1.98 * s, 1.98 * s, 0.6 * s)
    # laces on the back of the cuff
    for i in range(3):
        kit.box(a, "Dark", (0, 2.2 * s, 0.6 * s + i * 0.6 * s), (1.2 * s, 0.25 * s, 0.18 * s), rot=(0, 0, 0.4 if i % 2 else -0.4))
    # the fist: a big faceted ball, squashed front-to-back, leaning forward
    kit.blob(a, "Cloth", (0, -0.2 * s, 4.9 * s), 3.0 * s, scale=(1.0, 0.92, 1.05), subdiv=2, jitter=0.02, rot=(0.25, 0, 0))
    # knuckle roll across the front-top
    kit.blob(a, "Cloth", (0, -1.7 * s, 6.1 * s), 1.6 * s, scale=(1.55, 0.75, 0.8), subdiv=2, jitter=0.02, rot=(0.5, 0, 0))
    # thumb: a fat capsule from the side wrapping to the front
    kit.blob(a, "Cloth", (2.15 * s, -1.3 * s, 4.1 * s), 1.05 * s, scale=(0.85, 1.55, 0.85), subdiv=2, jitter=0.02, rot=(0.35, 0, -0.55))
    # white band where the fist meets the cuff
    kit.prism(a, "Cloth2", (0, 0.15 * s, 2.55 * s), 12, 2.2 * s, 2.35 * s, 0.7 * s)
    # highlight stripe on the knuckles
    kit.box(a, "Cloth2", (0, -2.55 * s, 6.25 * s), (2.4 * s, 0.3 * s, 0.45 * s), rot=(0.5, 0, 0), bevel=0.08 * s)
    return a


def awning(name, seed, width=26.0, depth=5.5, drop=2.0, stripes=8, tabs=10):
    """Sloped striped awning (attach edge at local y=0, z=0; slopes down toward -Y) with a scalloped valance."""
    a = kit.Asset(name, seed)
    slope = math.atan2(drop, depth)
    sw = width / stripes
    for i in range(stripes):
        x = -width / 2 + (i + 0.5) * sw
        kit.box(a, "Cloth" if i % 2 == 0 else "Cloth2", (x, -depth / 2, -drop / 2), (sw + 0.01, depth / math.cos(slope), 0.3), rot=(slope, 0, 0))
    tw = width / tabs
    for i in range(tabs):
        x = -width / 2 + (i + 0.5) * tw
        kit.prism(a, "Cloth" if i % 2 == 0 else "Cloth2", (x, -depth - 0.05, -drop - 0.15), 8, tw * 0.5, tw * 0.5, 0.25, rot=(math.pi / 2, 0, 0))
    kit.box(a, "Trim", (0, -depth - 0.05, -drop + 0.1), (width + 0.4, 0.4, 0.5), bevel=0.1)
    # two slim support rods
    for sx in (-1, 1):
        kit.box(a, "Metal", (sx * (width / 2 - 1.0), -depth / 2, -drop / 2 - 0.6), (0.25, depth, 0.25), rot=(slope - 0.3, 0, 0))
    return a


def pillar(name, seed, h=12.0, w=2.4):
    a = kit.Asset(name, seed)
    kit.block(a, "StoneDark", (0, 0, -0.3), (w * 1.45, w * 1.45, 1.3), bevel=0.2)
    kit.block(a, "Stone", (0, 0, 1.0), (w * 1.2, w * 1.2, 0.6), bevel=0.15, taper=0.9)
    kit.block(a, "Wall", (0, 0, 1.5), (w, w, h - 3.2), bevel=0.2)
    for z in (h * 0.42,):
        kit.block(a, "Trim", (0, 0, z), (w * 1.12, w * 1.12, 0.6), bevel=0.1)
    kit.block(a, "Stone", (0, 0, h - 1.8), (w * 1.25, w * 1.25, 0.7), bevel=0.15)
    kit.block(a, "Trim", (0, 0, h - 1.1), (w * 1.45, w * 1.45, 1.1), bevel=0.2)
    return a


def window(name, seed, w=6.0, h=7.0, arch=True):
    """Arched window: Trim frame, Glass pane, cross mullions, a sill. Faces -Y; local z = sill bottom."""
    a = kit.Asset(name, seed)
    kit.block(a, "Trim", (0, -0.2, -0.2), (w + 1.4, 1.2, 0.6), bevel=0.12)
    kit.block(a, "Glass", (0, 0.1, 0.4), (w - 0.4, 0.3, h - w / 2 if arch else h - 0.4))
    if arch:
        kit.prism(a, "Glass", (0, 0.25, 0.4 + h - w / 2), 12, (w - 0.4) / 2, (w - 0.4) / 2, 0.3, rot=(math.pi / 2, 0, 0))
    # frame
    for sx in (-1, 1):
        kit.block(a, "Trim", (sx * (w / 2), -0.05, 0.4), (0.7, 0.8, h - w / 2 if arch else h))
    if arch:
        pts = arch_profile(w, w / 2, 8)
        for i in range(8):
            (xa, za), (xb, zb) = pts[i], pts[i + 1]
            ang = math.atan2(zb - za, xb - xa)
            kit.box(a, "Trim", ((xa + xb) / 2, -0.05, 0.4 + h - w / 2 + (za + zb) / 2), (math.hypot(xb - xa, zb - za) + 0.3, 0.8, 0.7), rot=(0, -ang, 0))
    else:
        kit.box(a, "Trim", (0, -0.05, 0.4 + h), (w + 0.7, 0.8, 0.7))
    kit.block(a, "Trim", (0, -0.15, 0.4), (0.3, 0.5, h - w / 2 + (w / 2 if arch else 0) - 0.2))
    kit.box(a, "Trim", (0, -0.15, 0.4 + (h - w / 2) * 0.55), (w - 0.4, 0.5, 0.3))
    return a


def dumbbell_rack(name, seed, length=7.0):
    a = kit.Asset(name, seed)
    for sx in (-1, 1):
        kit.block(a, "Metal", (sx * length / 2, 0, -0.3), (0.5, 2.2, 3.3), bevel=0.08)
    for k, z in enumerate((1.2, 2.5)):
        kit.box(a, "Metal", (0, 0, z), (length + 0.5, 1.8, 0.25), rot=(0.25 if k == 0 else 0.25, 0, 0))
        for i in range(4):
            x = -length / 2 + 1.0 + i * (length - 2) / 3
            s = 1.0 - 0.1 * i
            for ex in (-0.65, 0.65):
                kit.prism(a, "Dark", (x + ex - 0.2, 0, z + 0.65), 8, 0.55 * s, 0.55 * s, 0.4, rot=(0, math.pi / 2, 0))
            kit.box(a, "Metal", (x, 0, z + 0.65), (1.4, 0.25, 0.25))
    return a


def tire_stack(name, seed, n=3, r=1.9):
    a = kit.Asset(name, seed)
    z = -0.2
    for i in range(n):
        off = (R(a, -0.25, 0.25), R(a, -0.25, 0.25))
        kit.prism(a, "Dark", (off[0], off[1], z), 12, r, r, 0.95)
        kit.prism(a, "StoneDark", (off[0], off[1], z + 0.94), 12, r * 0.55, r * 0.55, 0.03)
        z += 0.95
    return a


def speed_bag(name, seed):
    """Wall-mounted speed bag platform (back at local +Y): bracket, round board, a teardrop bag."""
    a = kit.Asset(name, seed)
    kit.block(a, "WoodDark", (0, 0.6, 0), (3.0, 0.4, 3.0), bevel=0.08)
    kit.box(a, "Metal", (0, -0.6, 2.6), (0.35, 2.4, 0.35))
    kit.prism(a, "Wood", (0, -1.5, 2.85), 12, 2.0, 2.0, 0.4)
    kit.box(a, "Metal", (0, -1.5, 2.55), (0.2, 0.2, 0.5))
    egg_mesh(a, "Cloth", (0, -1.5, 0.6), 2.0, 1.3, rot=(math.pi, 0, 0))
    return a


# ---------------------------------------------------------------- Pet Selling Stand


def stand_canopy(name, seed, width=22.0, depth=16.0, rise=4.5, stripes=10):
    """Market-stall canopy: a two-slope striped roof (ridge along X), scalloped valance on all four sides, a ridge
    beam and finials. Local z = 0 is the top of the posts."""
    a = kit.Asset(name, seed)
    slope = math.atan2(rise, depth / 2)
    ln = math.hypot(rise, depth / 2)
    sw = width / stripes
    for side in (-1, 1):
        for i in range(stripes):
            x = -width / 2 + (i + 0.5) * sw
            kit.box(a, "Cloth" if (i + (side > 0)) % 2 == 0 else "Cloth2", (x, side * depth / 4, rise / 2 + 0.1), (sw + 0.01, ln + 0.6, 0.3), rot=(-side * slope, 0, 0))
    # valance tabs
    tabs = 11
    tw = (width + 0.6) / tabs
    for side in (-1, 1):
        for i in range(tabs):
            x = -width / 2 - 0.3 + (i + 0.5) * tw
            kit.prism(a, "Cloth" if i % 2 == 0 else "Cloth2", (x, side * (depth / 2 + 0.35), -0.35), 8, tw * 0.5, tw * 0.5, 0.25, rot=(math.pi / 2, 0, 0))
        kit.box(a, "Trim", (0, side * (depth / 2 + 0.3), 0.05), (width + 0.8, 0.35, 0.55), bevel=0.08)
    for sx in (-1, 1):
        # gable ends (triangles) in Trim
        bm = a.bm("WallTop")
        x = sx * (width / 2 + 0.05)
        v = [bm.verts.new((x, -depth / 2, 0.05)), bm.verts.new((x, depth / 2, 0.05)), bm.verts.new((x, 0, rise))]
        v2 = [bm.verts.new((x - sx * 0.4, -depth / 2, 0.05)), bm.verts.new((x - sx * 0.4, depth / 2, 0.05)), bm.verts.new((x - sx * 0.4, 0, rise))]
        bm.faces.new(v)
        bm.faces.new(list(reversed(v2)))
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((v[i], v2[i], v2[j], v[j]))
    kit.box(a, "Trim", (0, 0, rise + 0.3), (width + 1.4, 0.8, 0.8), bevel=0.15)
    for sx in (-1, 1):
        kit.block(a, "Gold", (sx * (width / 2 + 0.6), 0, rise + 0.6), (0.9, 0.9, 1.2), bevel=0.25, taper=0.4)
    return a


def paw_sign(name, seed, size=7.0):
    """Round board with a big paw print, on a short stem (sits on the canopy ridge). Faces -Y."""
    a = kit.Asset(name, seed)
    s = size / 7.0
    kit.block(a, "WoodDark", (0, 0, -0.4), (0.8 * s, 0.8 * s, 1.6 * s), bevel=0.1)
    kit.prism(a, "Wood", (0, 0.2, 1.2 * s + 3.0 * s), 14, 3.4 * s, 3.4 * s, 0.7 * s, rot=(math.pi / 2, 0, 0))
    kit.prism(a, "Trim", (0, 0.45, 1.2 * s + 3.0 * s), 14, 3.8 * s, 3.8 * s, 0.35 * s, rot=(math.pi / 2, 0, 0))
    cz = 1.2 * s + 2.5 * s
    kit.prism(a, "Accent2", (0, -0.3, cz), 10, 1.25 * s, 1.0 * s, 0.4 * s, rot=(math.pi / 2, 0, 0))
    for i, (x, z) in enumerate(((-1.35, 1.25), (-0.5, 1.95), (0.5, 1.95), (1.35, 1.25))):
        kit.prism(a, "Accent2", (x * s, -0.3, cz + z * s), 8, 0.52 * s, 0.52 * s, 0.4 * s, rot=(math.pi / 2, 0, 0))
    return a


def stand_post(name, seed, h=11.0, w=1.5):
    a = kit.Asset(name, seed)
    kit.block(a, "StoneDark", (0, 0, -0.3), (w * 1.6, w * 1.6, 1.2), bevel=0.15)
    kit.block(a, "Wood", (0, 0, 0.9), (w, w, h - 0.9), bevel=0.12)
    for z in (h * 0.35, h * 0.7):
        kit.block(a, "WoodDark", (0, 0, z), (w * 1.18, w * 1.18, 0.4), bevel=0.06)
    kit.block(a, "Trim", (0, 0, h - 0.5), (w * 1.35, w * 1.35, 0.6), bevel=0.1)
    return a


def egg_crate(name, seed, w=4.0, d=3.0, eggs=6):
    a = kit.Asset(name, seed)
    kit.block(a, "Wood", (0, 0, -0.2), (w, d, 1.4), bevel=0.1)
    kit.block(a, "WoodDark", (0, 0, 1.1), (w + 0.15, d + 0.15, 0.25), bevel=0.05)
    kit.block(a, "Cloth2", (0, 0, 1.0), (w - 0.4, d - 0.4, 0.3))
    roles = ["Accent", "Accent2", "Gold", "Accent3"]
    cols = 3
    for i in range(eggs):
        x = -w / 2 + (i % cols + 0.5) * w / cols
        y = -d / 4 if i < cols else d / 4
        egg_mesh(a, roles[i % 4], (x, y, 1.2), 1.4, 1.0, rings=6, sides=8, rot=(R(a, -0.2, 0.2), R(a, -0.2, 0.2), 0))
    return a


def pet_bed(name, seed, r=2.2):
    a = kit.Asset(name, seed)
    kit.prism(a, "Cloth", (0, 0, -0.2), 12, r, r * 0.95, 1.0)
    kit.prism(a, "Cloth2", (0, 0, 0.6), 12, r * 0.75, r * 0.75, 0.25)
    kit.prism(a, "Cloth", (0, 0, 0.0), 12, r * 1.05, r, 0.7)
    return a


def pet_carrier(name, seed):
    a = kit.Asset(name, seed)
    kit.block(a, "Accent", (0, 0, -0.2), (3.2, 2.4, 2.4), bevel=0.3)
    kit.block(a, "Dark", (0, -1.22, 0.3), (2.0, 0.1, 1.6))
    for i in range(4):
        kit.block(a, "Metal", (-0.75 + i * 0.5, -1.3, 0.3), (0.15, 0.15, 1.6))
    kit.box(a, "Metal", (0, 0, 2.6), (2.0, 0.4, 0.3), bevel=0.05)
    for sx in (-1, 1):
        kit.box(a, "Metal", (sx * 1.0, 0, 2.35), (0.3, 0.4, 0.6))
    return a


def chalkboard(name, seed):
    a = kit.Asset(name, seed)
    for sx in (-1, 1):
        kit.box(a, "Wood", (sx * 1.3, -0.4, 1.9), (0.3, 0.3, 4.0), rot=(0.18, 0, 0))
        kit.box(a, "Wood", (sx * 1.3, 0.4, 1.9), (0.3, 0.3, 4.0), rot=(-0.18, 0, 0))
    kit.box(a, "Dark", (0, -0.55, 2.4), (2.6, 0.15, 2.6), rot=(0.18, 0, 0))
    kit.box(a, "Wood", (0, -0.58, 2.4), (2.95, 0.12, 2.95), rot=(0.18, 0, 0))
    return a


def bunting(name, seed, length=20.0, sag=1.2, flags=12):
    """A string of triangle flags along local X (attach points at x = +-length/2, z = 0)."""
    a = kit.Asset(name, seed)
    roles = ["Accent", "Accent2", "Gold", "Accent3"]
    for i in range(flags):
        t = (i + 0.5) / flags
        x = -length / 2 + t * length
        z = -sag * math.sin(math.pi * t)
        kit.frustum_rect(a, roles[i % 4], (x, 0, z), 0.0001, 0.1, 1.2, 0.1, 1.4, rot=(math.pi, 0, 0))
    segs = 8
    for k in range(segs):
        t0, t1 = k / segs, (k + 1) / segs
        x0, x1 = -length / 2 + t0 * length, -length / 2 + t1 * length
        z0, z1 = -sag * math.sin(math.pi * t0), -sag * math.sin(math.pi * t1)
        kit.box(a, "Dark", ((x0 + x1) / 2, 0, (z0 + z1) / 2 + 0.05), (math.hypot(x1 - x0, z1 - z0) + 0.05, 0.08, 0.08), rot=(0, -math.atan2(z1 - z0, x1 - x0), 0))
    return a


# ---------------------------------------------------------------- plaza


def egg_fountain(name, seed, r=11.0):
    """Golden Egg Fountain: octagonal studless stone basin with a chunky rim, a water disc (Water role), a fluted
    centre column, a second basin, and a giant golden egg cradled in a cracked white shell on top."""
    a = kit.Asset(name, seed)
    kit.prism(a, "StoneDark", (0, 0, -0.4), 8, r + 0.6, r + 0.4, 1.0, rot=(0, 0, math.pi / 8))
    kit.prism(a, "Stone", (0, 0, 0.5), 8, r, r, 1.4, rot=(0, 0, math.pi / 8))
    kit.prism(a, "Trim", (0, 0, 1.85), 8, r + 0.35, r + 0.35, 0.45, rot=(0, 0, math.pi / 8))
    kit.prism(a, "Water", (0, 0, 0.6), 8, r - 1.0, r - 1.0, 1.0, rot=(0, 0, math.pi / 8))
    # column
    kit.prism(a, "Stone", (0, 0, 0.6), 8, 2.4, 1.9, 5.2, rot=(0, 0, math.pi / 8))
    for i in range(8):
        ang = i * math.pi / 4
        kit.block(a, "Trim", (math.cos(ang) * 2.0, math.sin(ang) * 2.0, 1.2), (0.5, 0.5, 4.0), rot=(0, 0, ang), bevel=0.08)
    kit.prism(a, "StoneDark", (0, 0, 5.8), 8, 5.2, 5.4, 0.8, rot=(0, 0, math.pi / 8))
    kit.prism(a, "Trim", (0, 0, 6.55), 8, 5.6, 5.6, 0.35, rot=(0, 0, math.pi / 8))
    kit.prism(a, "Water", (0, 0, 6.2), 8, 4.6, 4.6, 0.55, rot=(0, 0, math.pi / 8))
    # spouts: four egg-shaped heads on the column pointing out
    for i in range(4):
        ang = i * math.pi / 2 + math.pi / 4
        egg_mesh(a, "Gold", (math.cos(ang) * 2.6, math.sin(ang) * 2.6, 3.4), 1.6, 1.2, rings=5, sides=8, rot=(math.sin(ang) * 1.2, -math.cos(ang) * 1.2, 0))
    # shell cradle (jagged white shards) and the golden egg
    kit.prism(a, "Stone", (0, 0, 6.6), 8, 2.0, 2.4, 1.2, rot=(0, 0, math.pi / 8))
    for i in range(9):
        ang = 2 * math.pi * i / 9
        h = R(a, 2.0, 3.4)
        kit.block(a, "Spot", (math.cos(ang) * 2.6, math.sin(ang) * 2.6, 7.4), (1.5, 0.5, h), rot=(-math.sin(ang) * 0.35, math.cos(ang) * 0.35, ang + math.pi / 2), bevel=0.06, taper=0.35)
    egg_mesh(a, "Gold", (0, 0, 7.4), 8.4, 7.0, rings=10, sides=14)
    kit.box(a, "Glow", (0, 0, 7.6 + 8.6 * 0.55), (0.2, 0.2, 0.2))  # tiny anchor for the sparkle emitter
    return a


def egg_monument(name, seed, h=9.0):
    a = kit.Asset(name, seed)
    kit.block(a, "StoneDark", (0, 0, -0.4), (5.0, 5.0, 1.4), bevel=0.25)
    kit.block(a, "Stone", (0, 0, 1.0), (4.0, 4.0, 2.2), bevel=0.2, taper=0.9)
    kit.block(a, "Trim", (0, 0, 3.1), (4.5, 4.5, 0.5), bevel=0.12)
    egg_mesh(a, "Accent", (0, 0, 3.55), h * 0.75, h * 0.5, rings=9, sides=12)
    for k, zf in enumerate((0.36, 0.5)):
        zz = 3.55 + h * 0.75 * zf
        rr = (h * 0.5 / 2) * math.sin(math.pi * zf) ** 0.62 * (1.0 - 0.12 * zf)
        kit.prism(a, "Accent2" if k == 0 else "Gold", (0, 0, zz - 0.3), 12, rr * 1.06, rr * 1.06, 0.6)
    return a


def launch_ring(name, seed, r=13.0):
    """Low decorative ring for the launch platform edge (never walked on: trims only)."""
    a = kit.Asset(name, seed)
    n = 24
    for i in range(n):
        ang = 2 * math.pi * i / n
        x, y = math.cos(ang) * r, math.sin(ang) * r
        kit.block(a, "Stone" if i % 2 == 0 else "StoneDark", (x, y, -0.2), (3.6, 1.2, 0.75), rot=(0, 0, ang + math.pi / 2), bevel=0.12)
        if i % 3 == 0:
            kit.block(a, "Gold", (x * 1.04, y * 1.04, 0.4), (0.9, 0.9, 1.2), rot=(0, 0, ang), bevel=0.15, taper=0.5)
    return a


# ---------------------------------------------------------------- hub boundary: cliffs and a waterfall


def cliff(name, seed, length=40.0, depth=14.0, height=44.0, ledges=4, vines=True, notch=False):
    """Hub cliff module: irregular strata. Each tier is a run of blocks of random width, height and protrusion
    (never a grid), stepping back as it rises; grass (Ground) tufts on the steps, boulders at the foot, hanging
    vines (Leaf), and an uneven grass cap. Front faces -Y. notch=True keeps a slot in the middle (waterfall)."""
    a = kit.Asset(name, seed)
    lh = height / ledges
    z = -0.8
    for i in range(ledges):
        th = lh * R(a, 0.85, 1.15) if i < ledges - 1 else height - z
        back = i * depth * 0.1
        x = -length / 2
        while x < length / 2 - 0.5:
            bw = min(R(a, 5.0, 12.0), length / 2 - x)
            cx = x + bw / 2
            if notch and abs(cx) < 5.5:
                x += bw
                continue
            protrude = R(a, -1.2, 1.6)
            fy = -depth / 2 + back - protrude
            bh = th * R(a, 0.82, 1.08)
            kit.block(a, "Stone" if R(a, 0, 1) < 0.55 else "StoneDark", (cx, fy + (depth - back + protrude) / 2, z), (bw + 0.6, depth - back + protrude, bh + 0.4), rot=(R(a, -0.02, 0.02), 0, R(a, -0.04, 0.04)), bevel=0.55, taper=R(a, 0.9, 0.98))
            if R(a, 0, 1) < 0.75:
                kit.block(a, "Ground", (cx + R(a, -1, 1), fy + 1.6, z + bh + 0.1), (bw * R(a, 0.6, 1.0), R(a, 2.4, 3.6), 0.9), rot=(0, 0, R(a, -0.05, 0.05)), bevel=0.3)
            if vines and R(a, 0, 1) < 0.45:
                vx = cx + R(a, -bw / 3, bw / 3)
                vl = R(a, bh * 0.4, bh * 0.95)
                kit.block(a, "Leaf", (vx, fy - 0.15, z + bh - vl + 0.5), (R(a, 0.7, 1.3), 0.5, vl), bevel=0.15)
                for k in range(int(vl / 3)):
                    kit.box(a, "LeafDark", (vx + R(a, -0.5, 0.5), fy - 0.3, z + bh - k * 3 - 1), (1.2, 0.6, 1.0), rot=(0, 0, R(a, 0, 1.5)), bevel=0.2)
            x += bw
        z += th * 0.97
    # uneven grass cap in a few slabs
    x = -length / 2 - 0.5
    while x < length / 2:
        w = R(a, 7, 13)
        kit.block(a, "Ground", (x + w / 2, depth * 0.12 + R(a, -0.6, 0.6), height - R(a, 0.6, 1.3)), (w + 0.8, depth * 0.85, R(a, 1.6, 2.6)), rot=(0, 0, R(a, -0.03, 0.03)), bevel=0.5)
        x += w
    for k in range(int(length / 9)):
        N.boulder(a, "StoneDark", (R(a, -length / 2 + 2, length / 2 - 2), -depth / 2 - R(a, 0.5, 2.5), -0.8), (R(a, 1.8, 3.2), R(a, 1.5, 2.6), R(a, 1.4, 2.4)), n=10)
    return a


def waterfall(name, seed, height=40.0, width=8.0, steps=4):
    """Stepped water ribbon (Water role) falling toward -Y, with foam (Foam) lips at each step and a splash pool
    rim (Stone) at the bottom. Local z = 0 is the pool water level."""
    a = kit.Asset(name, seed)
    sh = height / steps
    for i in range(steps):
        z = height - (i + 1) * sh
        y = -i * 1.2
        kit.block(a, "Water", (0, y, z), (width * (1 - 0.06 * i), 0.8, sh + 0.2))
        kit.block(a, "Foam", (0, y - 0.5, z + sh - 0.2), (width * (1 - 0.06 * i) + 0.4, 1.6, 0.6), bevel=0.2)
    kit.prism(a, "Water", (0, -steps * 1.2 - 3.5, -0.5), 10, 7.5, 7.5, 0.6)
    kit.prism(a, "Foam", (0, -steps * 1.2 - 1.2, -0.3), 8, 3.2, 3.2, 0.5)
    for i in range(10):
        ang = 2 * math.pi * i / 10
        kit.block(a, "Stone" if i % 2 else "StoneDark", (math.cos(ang) * 8.2, -steps * 1.2 - 3.5 + math.sin(ang) * 8.2, -0.8), (3.2, 2.2, 1.6 + R(a, 0, 0.6)), rot=(0, 0, ang + math.pi / 2), bevel=0.4)
    return a
