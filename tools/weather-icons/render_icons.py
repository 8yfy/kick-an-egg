"""Kick an Egg weather icons (one per Config/Mutations.Weather entry), rendered in Blender to match the approved
HUD art: chunky glossy toy shapes, a light-to-dark vertical gradient per piece, darker painted edges, soft
specular highlights, transparent background, 512 px.

usage:
  blender -b --factory-startup -P tools/weather-icons/render_icons.py -- <out_dir> [Sunny,Rainy,...]
writes <out_dir>/weather_<name lowercase>.png
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0] if ARGS else "weather-icons")
ONLY = ARGS[1].split(",") if len(ARGS) > 1 else None
RES = 512


def lin(h):
    h = h.lstrip("#")
    c = [int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple((x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4) for x in c) + (1.0,)


# Scene ------------------------------------------------------------------------------------------------------


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("World")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = lin("C8D2EC")
    bg.inputs[1].default_value = 0.4
    cam = bpy.data.cameras.new("Cam")
    cam.type = "ORTHO"
    cam.ortho_scale = 4.5
    co = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(co)
    co.location = (0, -10, 1.6)
    co.rotation_euler = (math.radians(81), 0, 0)
    sc.camera = co
    for name, loc, power, size, color in (
        ("Key", (-4, -6, 7), 850, 3.5, "FFFFFF"),
        ("Rim", (5, 5, 5), 750, 3, "D8E8FF"),
        ("Fill", (4, -7, -2), 180, 6, "FFF4E8"),
    ):
        light = bpy.data.lights.new(name, "AREA")
        light.energy, light.size, light.color = power, size, lin(color)[:3]
        lo = bpy.data.objects.new(name, light)
        sc.collection.objects.link(lo)
        lo.location = loc
        lo.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return sc


def link(o):
    bpy.context.scene.collection.objects.link(o)
    return o


def mat(name, top, bottom, edge, rough=0.32, coat=0.6, emit=None, strength=0.0, axis="Z"):
    """Vertical gradient (object bounds; `axis` = the object's local up: Y for flat outlines) darkened toward the
    silhouette, glossy clear coat."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    n, ln = nt.nodes, nt.links
    p = n["Principled BSDF"]
    p.inputs["Roughness"].default_value = rough
    p.inputs["Coat Weight"].default_value = coat
    p.inputs["Coat Roughness"].default_value = 0.06
    tc = n.new("ShaderNodeTexCoord")
    sep = n.new("ShaderNodeSeparateXYZ")
    ln.new(tc.outputs["Generated"], sep.inputs[0])
    vert = n.new("ShaderNodeValToRGB")
    vert.color_ramp.elements[0].position = 0.0
    vert.color_ramp.elements[0].color = lin(bottom)
    vert.color_ramp.elements[1].position = 0.75
    vert.color_ramp.elements[1].color = lin(top)
    ln.new(sep.outputs[axis], vert.inputs["Fac"])
    lw = n.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.5
    rim = n.new("ShaderNodeMapRange")
    rim.inputs["From Min"].default_value = 0.22
    rim.inputs["From Max"].default_value = 0.9
    ln.new(lw.outputs["Facing"], rim.inputs["Value"])
    mix = n.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    a = next(s for s in mix.inputs if s.name == "A" and s.type == "RGBA")
    b = next(s for s in mix.inputs if s.name == "B" and s.type == "RGBA")
    out = next(s for s in mix.outputs if s.type == "RGBA")
    ln.new(rim.outputs["Result"], mix.inputs[0])
    ln.new(vert.outputs["Color"], a)
    b.default_value = lin(edge)
    ln.new(out, p.inputs["Base Color"])
    if emit:
        p.inputs["Emission Color"].default_value = lin(emit)
        p.inputs["Emission Strength"].default_value = strength
    return m


# Shapes (built in the XZ plane, facing the camera at -Y) -----------------------------------------------------


def cloud(name, at, s, m, puffs=None):
    mb = bpy.data.metaballs.new(name)
    mb.resolution = 0.04
    mb.render_resolution = 0.015
    o = link(bpy.data.objects.new(name, mb))
    o.location = at
    o.scale = (s, s * 0.8, s)
    for x, z, r in puffs or (
        (0.0, 0.18, 0.95),
        (-0.82, -0.12, 0.72),
        (0.86, -0.08, 0.76),
        (-0.36, 0.52, 0.74),
        (0.42, 0.5, 0.7),
        (0.0, -0.22, 0.8),
    ):
        e = mb.elements.new()
        e.co = (x, 0, z)
        e.radius = r
    flat = mb.elements.new()
    flat.type = "CAPSULE"
    flat.co = (0, 0, -0.3)
    flat.size_x = 0.75
    flat.radius = 0.7
    o.data.materials.append(m)
    return o


def mesh_obj(name, bm, m, at, scale=(1, 1, 1), rot=(0, 0, 0)):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for poly in me.polygons:
        poly.use_smooth = True
    o = link(bpy.data.objects.new(name, me))
    o.location, o.scale, o.rotation_euler = at, scale, rot
    o.data.materials.append(m)
    return o


def sphere(name, at, r, m, scale=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=48, v_segments=32, radius=r)
    return mesh_obj(name, bm, m, at, scale)


def drop(name, at, s, m, tilt=-14):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=48, v_segments=40, radius=1)
    for v in bm.verts:
        z = v.co.z
        if z > 0:
            k = math.sqrt(max(0.0, (1 - z) / (1 + z)))
            v.co.x *= k
            v.co.y *= k
            v.co.z = z * 1.55
    return mesh_obj(name, bm, m, at, (s, s * 0.8, s), (0, math.radians(tilt), 0))


def shape(name, pts, extrude, bevel, m, at=(0, 0, 0), spin=0.0, depth_y=0.0):
    """A filled 2D outline (x right, y up) extruded toward the camera with a rounded bevel."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "2D"
    cu.fill_mode = "BOTH"
    sp = cu.splines.new("POLY")
    sp.points.add(len(pts) - 1)
    for i, (x, y) in enumerate(pts):
        sp.points[i].co = (x, y, 0, 1)
    sp.use_cyclic_u = True
    sp.use_smooth = True
    cu.extrude = extrude
    cu.bevel_depth = bevel
    cu.bevel_resolution = 5
    o = link(bpy.data.objects.new(name, cu))
    o.rotation_euler = (math.radians(90), math.radians(spin), 0)
    o.location = (at[0], at[1] + depth_y, at[2])
    o.data.materials.append(m)
    return o


def smooth(path, radii, steps=6):
    """Catmull-Rom resample of a polyline (and its per-point radii) so tapered tubes bend smoothly."""
    pts = [path[0]] + list(path) + [path[-1]]
    rs = [radii[0]] + list(radii) + [radii[-1]]
    out, outr = [], []
    for i in range(1, len(pts) - 2):
        for t in [k / steps for k in range(steps)]:
            p = [
                0.5 * ((2 * pts[i][c]) + (-pts[i - 1][c] + pts[i + 1][c]) * t
                + (2 * pts[i - 1][c] - 5 * pts[i][c] + 4 * pts[i + 1][c] - pts[i + 2][c]) * t * t
                + (-pts[i - 1][c] + 3 * pts[i][c] - 3 * pts[i + 1][c] + pts[i + 2][c]) * t ** 3)
                for c in (0, 1)
            ]
            out.append(tuple(p))
            outr.append(rs[i] + (rs[i + 1] - rs[i]) * t)
    out.append(path[-1])
    outr.append(radii[-1])
    return out, outr


def tube(name, paths, radius, m, at=(0, 0, 0), radii=None):
    """Round tubes along polylines in the XZ plane (closed caps)."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = 6
    cu.use_fill_caps = True
    for path in paths:
        if radii and len(path) > 2:
            path, radii = smooth(path, radii)
        sp = cu.splines.new("POLY")
        sp.points.add(len(path) - 1)
        for i, (x, z) in enumerate(path):
            sp.points[i].co = (x, 0, z, 1)
            if radii:
                sp.points[i].radius = radii[i]
        sp.use_smooth = True
    o = link(bpy.data.objects.new(name, cu))
    o.location = at
    o.data.materials.append(m)
    return o


def star_pts(outer, inner, n=5, phase=90):
    pts = []
    for i in range(2 * n):
        r = outer if i % 2 == 0 else inner
        a = math.radians(phase + i * 180 / n)
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


def snowflake(name, at, s, m, ball_m):
    paths = []
    tips = []
    for k in range(6):
        a = math.radians(90 + 60 * k)
        d = (math.cos(a), math.sin(a))
        paths.append([(0, 0), (d[0] * s, d[1] * s)])
        tips.append((d[0] * s, d[1] * s))
        for along, length in ((0.55, 0.32), (0.3, 0.22)):
            base = (d[0] * s * along, d[1] * s * along)
            for side in (-1, 1):
                b = a + side * math.radians(55)
                end = (base[0] + math.cos(b) * s * length, base[1] + math.sin(b) * s * length)
                paths.append([base, end])
    o = tube(name, paths, 0.075 * s / 0.9, m, at)
    for i, (x, z) in enumerate(tips):
        sphere(f"{name}Tip{i}", (at[0] + x, at[1], at[2] + z), 0.12 * s / 0.9, ball_m)
    hexagon = [(math.cos(math.radians(30 + 60 * k)) * 0.24 * s, math.sin(math.radians(30 + 60 * k)) * 0.24 * s) for k in range(6)]
    shape(f"{name}Core", hexagon, 0.08, 0.06, ball_m, at, depth_y=-0.05)
    return o


# Icons ------------------------------------------------------------------------------------------------------

WHITE_CLOUD = ("FFFFFF", "C9DAF2", "7F95C4")
BOLT = ("FFF35A", "FFA000", "B85A00")


def sunny():
    sun = mat("Sun", "FFEE55", "FF9A00", "D05A00", rough=0.3)
    ray = mat("Ray", "FFD43A", "FF7A00", "C04800", rough=0.3, axis="Y")
    for k in range(12):
        long = k % 2 == 0
        a = math.radians(90 + k * 30)
        r0, r1, w = 1.0, (1.85 if long else 1.55), (0.36 if long else 0.28)
        tip = (math.cos(a) * r1, math.sin(a) * r1)
        side = (-math.sin(a), math.cos(a))
        b0 = (math.cos(a) * r0 + side[0] * w, math.sin(a) * r0 + side[1] * w)
        b1 = (math.cos(a) * r0 - side[0] * w, math.sin(a) * r0 - side[1] * w)
        shape(f"Ray{k}", [b0, tip, b1], 0.1, 0.07, ray, (0, 0, 0.05), depth_y=0.25)
    sphere("SunBall", (0, 0, 0.05), 1.12, sun, (1, 0.85, 1))


def rainy():
    cloud("Cloud", (0, 0, 0.62), 1.0, mat("Cloud", *WHITE_CLOUD, rough=0.4, coat=0.3))
    water = mat("Drop", "8FE4FF", "1A78E0", "0B4AA8", rough=0.18, coat=0.9)
    for i, (x, z, s) in enumerate(((-0.85, -0.95, 0.38), (0.05, -1.3, 0.42), (0.92, -0.92, 0.38))):
        drop(f"Drop{i}", (x, -0.5, z), s, water)


def snowy():
    cloud("Cloud", (-0.15, 0.2, 0.75), 0.92, mat("Cloud", "FFFFFF", "D2E6F8", "86A6CC", rough=0.4, coat=0.3))
    ice = mat("Ice", "E8FAFF", "6CC4FF", "1F6FC0", rough=0.2, coat=0.8, emit="BFEFFF", strength=0.08)
    snowflake("Flake", (0.55, -0.6, -0.75), 0.95, ice, ice)
    snowflake("Small", (-1.05, -0.5, -1.0), 0.45, ice, ice)


def stormy():
    cloud("Cloud", (0, 0, 0.6), 1.05, mat("Cloud", "7F8FC4", "2C3568", "141A3A", rough=0.42, coat=0.3))
    bolt = mat("Bolt", *BOLT, rough=0.22, coat=0.8, emit="FFC21A", strength=0.15, axis="Y")
    pts = [(-0.05, 0.75), (0.55, 0.75), (0.2, 0.12), (0.6, 0.12), (-0.32, -1.2), (-0.02, -0.28), (-0.42, -0.28)]
    shape("Bolt", [(x * 1.05, y * 1.05) for x, y in pts], 0.14, 0.07, bolt, (0.12, 0, -0.3), spin=-6, depth_y=-0.75)


def starfall():
    trail = mat("Trail", "FF8AE6", "8A3CF0", "3E128C", rough=0.3, emit="B45CFF", strength=0.12)
    path = [(0.3, -0.3), (-0.25, 0.2), (-0.75, 0.55), (-1.2, 1.0), (-1.5, 1.45)]
    tube("Trail", [path], 0.42, trail, (0, 0.5, 0), radii=[1.0, 0.8, 0.55, 0.3, 0.05])
    glow = mat("Glow", "FFD0F6", "E86AD8", "8A2A90", rough=0.3, emit="FFB0F0", strength=0.2)
    tube("Trail2", [[(0.2, -0.75), (-0.45, -0.45), (-1.15, -0.2)]], 0.16, glow, (0, 0.55, 0), radii=[1.0, 0.5, 0.05])
    tube("Trail3", [[(0.75, 0.15), (0.35, 0.7), (-0.05, 1.25)]], 0.14, glow, (0, 0.55, 0), radii=[1.0, 0.5, 0.05])
    gold = mat("Star", "FFF04A", "FF8A00", "B84A00", rough=0.22, coat=0.9, axis="Y")
    shape("Star", star_pts(1.05, 0.5), 0.18, 0.16, gold, (0.4, 0, -0.5), spin=-14, depth_y=-0.4)
    small = mat("Small", "FFFFFF", "FFD95A", "C28A1A", rough=0.25, emit="FFF2C0", strength=0.15, axis="Y")
    shape("S1", star_pts(0.3, 0.14), 0.06, 0.06, small, (1.4, 0, 0.95), spin=10, depth_y=-0.3)
    shape("S2", star_pts(0.22, 0.1), 0.05, 0.05, small, (-1.3, 0, -1.05), spin=-20, depth_y=-0.3)


def rainbow():
    bands = (
        ("FF6A6A", "E01E2A", "9E0E1A"),
        ("FFB45A", "F07000", "A84800"),
        ("FFF27A", "FFC000", "C28000"),
        ("9CF56A", "36C40F", "1E7A08"),
        ("6FD0FF", "1D7FE0", "0E4FA8"),
        ("C99BFF", "7A3CE0", "4A1A9C"),
    )
    for i, colors in enumerate(bands):
        r = 1.62 - i * 0.215
        arc = [(math.cos(math.radians(a)) * r, math.sin(math.radians(a)) * r) for a in range(0, 181, 4)]
        tube(f"Band{i}", [arc], 0.112, mat(f"Band{i}", *colors, rough=0.28, coat=0.7), (0, 0.1 * i, -0.75))
    cloudy = mat("Cloud", *WHITE_CLOUD, rough=0.4, coat=0.3)
    small = (
        (0.0, 0.1, 0.8),
        (-0.62, -0.1, 0.62),
        (0.62, -0.1, 0.64),
        (0.0, -0.25, 0.7),
    )
    cloud("CloudL", (-1.3, -0.7, -0.95), 0.62, cloudy, small)
    cloud("CloudR", (1.3, -0.7, -0.95), 0.62, cloudy, small)


ICONS = {
    "Sunny": sunny,
    "Rainy": rainy,
    "Snowy": snowy,
    "Stormy": stormy,
    "Starfall": starfall,
    "Rainbow": rainbow,
}

def outline(path, px=9, color=(0.05, 0.06, 0.1)):
    """A dark outline around the icon's silhouette (like the approved HUD art), drawn behind it."""
    import numpy as np

    img = bpy.data.images.load(path)
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    alpha = a[..., 3]
    grown = alpha.copy()
    for dy in range(-px, px + 1):
        for dx in range(-px, px + 1):
            if dx * dx + dy * dy <= px * px:
                grown = np.maximum(grown, np.roll(np.roll(alpha, dy, 0), dx, 1))
    total = alpha + grown * (1 - alpha)
    rgb = a[..., :3] * alpha[..., None] + np.array(color, dtype=np.float32) * (grown * (1 - alpha))[..., None]
    rgb = np.where(total[..., None] > 0, rgb / np.maximum(total[..., None], 1e-6), 0)
    img.pixels[:] = np.dstack([rgb, total]).ravel()
    img.save()


os.makedirs(OUT, exist_ok=True)
for name, build in ICONS.items():
    if ONLY and name not in ONLY:
        continue
    sc = reset()
    build()
    sc.render.filepath = os.path.join(OUT, f"weather_{name.lower()}.png")
    bpy.ops.render.render(write_still=True)
    outline(sc.render.filepath)
    print("ICON", name, sc.render.filepath)
