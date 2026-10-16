# Kick the Egg! world kit: low-poly modelling helpers for headless Blender (blender -b --python <script>).
# 1 Blender unit = 1 stud. +Y up in Roblox = +Z up here; exports convert. Every asset is a root Empty with one child
# mesh per colour role (Trunk, Leaf, LeafDark, Stone, Trim, Glow...); Roblox recolours roles from palettes at runtime,
# so one mesh serves many zones. Faces are flat shaded (faceted low-poly), with optional small bevels on hard edges.
import bmesh
import bpy
import math
import random
from mathutils import Matrix, Vector

ROLE_COLORS = {  # preview colours only (Blender renders, importer default); the game recolours by role
    "Trunk": (0.36, 0.22, 0.12),
    "Leaf": (0.30, 0.70, 0.20),
    "LeafDark": (0.18, 0.50, 0.14),
    "LeafLight": (0.55, 0.85, 0.30),
    "Stone": (0.62, 0.62, 0.66),
    "StoneDark": (0.42, 0.42, 0.48),
    "Wood": (0.60, 0.40, 0.22),
    "WoodDark": (0.40, 0.25, 0.14),
    "Roof": (0.85, 0.25, 0.25),
    "RoofDark": (0.62, 0.15, 0.15),
    "Trim": (0.95, 0.90, 0.80),
    "Wall": (0.95, 0.92, 0.85),
    "Metal": (0.55, 0.58, 0.64),
    "Gold": (1.0, 0.78, 0.2),
    "Glow": (1.0, 0.9, 0.5),
    "Accent": (0.2, 0.6, 1.0),
    "Accent2": (1.0, 0.45, 0.7),
    "Ground": (0.45, 0.75, 0.30),
    "Dirt": (0.62, 0.42, 0.26),
    "Sand": (0.93, 0.83, 0.58),
    "Snow": (0.95, 0.97, 1.0),
    "Ice": (0.70, 0.88, 1.0),
    "Crystal": (0.55, 0.85, 1.0),
    "Glass": (0.8, 0.95, 1.0),
    "Cap": (0.90, 0.20, 0.20),
    "Spot": (1.0, 1.0, 1.0),
    "Stem": (0.95, 0.90, 0.80),
    "Water": (0.25, 0.65, 0.95),
    "Cloth": (0.9, 0.3, 0.3),
    "Cloth2": (1.0, 1.0, 1.0),
    "Dark": (0.12, 0.12, 0.16),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)


_mats = {}


def material(role):
    if role in _mats and _mats[role].name in bpy.data.materials:
        return _mats[role]
    m = bpy.data.materials.new(role)
    col = ROLE_COLORS.get(role.rstrip("0123456789"), (0.8, 0.8, 0.8))
    m.diffuse_color = (*col, 1.0)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*col, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.6
    _mats[role] = m
    return m


class Asset:
    """An asset under construction: one bmesh per colour role, all in asset-local space (origin = base centre)."""

    def __init__(self, name, seed=1):
        self.name = name
        self.parts = {}
        self.rng = random.Random(seed)

    def bm(self, role):
        if role not in self.parts:
            self.parts[role] = bmesh.new()
        return self.parts[role]

    def build(self, collection=None, location=(0, 0, 0)):
        coll = collection or bpy.context.scene.collection
        root = bpy.data.objects.new(self.name, None)
        root.empty_display_size = 2
        coll.objects.link(root)
        objs = []
        for role, bm in self.parts.items():
            bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            me = bpy.data.meshes.new(f"{self.name}_{role}")
            bm.to_mesh(me)
            bm.free()
            for p in me.polygons:
                p.use_smooth = False
            me.materials.append(material(role))
            ob = bpy.data.objects.new(f"{self.name}__{role}", me)
            coll.objects.link(ob)
            ob.parent = root
            objs.append(ob)
        root.location = location
        self.parts = {}
        return root, objs


# ---------------------------------------------------------------- primitives (all write into a role's bmesh)


def _xf(bm, verts, m):
    bmesh.ops.transform(bm, matrix=m, verts=verts)


def box(a, role, center, size, rot=(0, 0, 0), bevel=0.0, taper=1.0):
    """Axis box (size x,y,z) at center, rotated (radians xyz). bevel = chamfer width on all edges; taper scales the
    top face (1 = straight)."""
    bm = a.bm(role)
    res = bmesh.ops.create_cube(bm, size=1.0)
    verts = res["verts"]
    if taper != 1.0:
        for v in verts:
            if v.co.z > 0:
                v.co.x *= taper
                v.co.y *= taper
    _xf(bm, verts, Matrix.Diagonal((size[0], size[1], size[2], 1)))
    _xf(bm, verts, Matrix.Translation(center) @ _rot(rot))
    if bevel > 0:
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(bm, geom=edges, offset=bevel, segments=1, affect="EDGES", profile=0.5, clamp_overlap=True)
    return verts


def block(a, role, base, size, rot=(0, 0, 0), bevel=0.0, taper=1.0):
    """Box standing on `base` (bottom-centre point); rotation pivots around the base, so a tilted block leans."""
    r = _rot(rot)
    center = Vector(base) + (r @ Vector((0, 0, size[2] / 2)))
    return box(a, role, center, size, rot=rot, bevel=bevel, taper=taper)


def _rot(rot):
    return Matrix.Rotation(rot[2], 4, "Z") @ Matrix.Rotation(rot[1], 4, "Y") @ Matrix.Rotation(rot[0], 4, "X")


def prism(a, role, center, sides, r0, r1, h, rot=(0, 0, 0), twist=0.0, cap=True, jitter=0.0):
    """Faceted cylinder/cone from z=0 to z=h (radius r0 at bottom, r1 at top) placed at center."""
    bm = a.bm(role)
    bot, top = [], []
    for i in range(sides):
        ang = 2 * math.pi * i / sides
        j0 = 1 + a.rng.uniform(-jitter, jitter)
        j1 = 1 + a.rng.uniform(-jitter, jitter)
        bot.append(bm.verts.new((math.cos(ang) * r0 * j0, math.sin(ang) * r0 * j0, 0)))
        if r1 > 0.0001:
            ang2 = ang + twist
            top.append(bm.verts.new((math.cos(ang2) * r1 * j1, math.sin(ang2) * r1 * j1, h)))
    verts = bot + top
    if top:
        for i in range(sides):
            k = (i + 1) % sides
            bm.faces.new((bot[i], bot[k], top[k], top[i]))
        if cap:
            bm.faces.new(list(reversed(bot)))
            bm.faces.new(top)
    else:
        tip = bm.verts.new((0, 0, h))
        verts.append(tip)
        for i in range(sides):
            k = (i + 1) % sides
            bm.faces.new((bot[i], bot[k], tip))
        if cap:
            bm.faces.new(list(reversed(bot)))
    _xf(bm, verts, Matrix.Translation(center) @ _rot(rot))
    return verts


def blob(a, role, center, radius, scale=(1, 1, 1), subdiv=1, jitter=0.12, rot=(0, 0, 0), flat_bottom=None):
    """Faceted low-poly blob (jittered icosphere). flat_bottom = cut z below this fraction of radius."""
    bm = a.bm(role)
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    verts = res["verts"]
    for v in verts:
        n = v.co.normalized()
        v.co += n * radius * a.rng.uniform(-jitter, jitter)
        if flat_bottom is not None and v.co.z < -radius * flat_bottom:
            v.co.z = -radius * flat_bottom
    _xf(bm, verts, Matrix.Translation(center) @ _rot(rot) @ Matrix.Diagonal((*scale, 1)))
    return verts


def wedge(a, role, center, size, rot=(0, 0, 0)):
    """Roblox-style wedge: slope rises toward +y. size x (width), y (depth), z (height); base centred at center."""
    bm = a.bm(role)
    sx, sy, sz = size[0] / 2, size[1] / 2, size[2]
    v = [
        bm.verts.new((-sx, -sy, 0)),
        bm.verts.new((sx, -sy, 0)),
        bm.verts.new((sx, sy, 0)),
        bm.verts.new((-sx, sy, 0)),
        bm.verts.new((-sx, sy, sz)),
        bm.verts.new((sx, sy, sz)),
    ]
    bm.faces.new((v[0], v[3], v[2], v[1]))
    bm.faces.new((v[3], v[4], v[5], v[2]))
    bm.faces.new((v[0], v[1], v[5], v[4]))
    bm.faces.new((v[0], v[4], v[3]))
    bm.faces.new((v[1], v[2], v[5]))
    _xf(bm, v, Matrix.Translation(center) @ _rot(rot))
    return v


def tri_prism(a, role, center, w, h, t, rot=(0, 0, 0)):
    """Triangular prism (a gable end): base along local Y (width w) at z = 0, apex at z = h, thickness t along X."""
    bm = a.bm(role)
    v = []
    for x in (-t / 2, t / 2):
        v += [bm.verts.new((x, -w / 2, 0)), bm.verts.new((x, w / 2, 0)), bm.verts.new((x, 0, h))]
    bm.faces.new((v[0], v[2], v[1]))
    bm.faces.new((v[3], v[4], v[5]))
    for i in range(3):
        j = (i + 1) % 3
        bm.faces.new((v[i], v[j], v[j + 3], v[i + 3]))
    _xf(bm, v, Matrix.Translation(center) @ _rot(rot))
    return v


def poly_extrude(a, role, pts, z0, z1, center=(0, 0, 0), rot=(0, 0, 0)):
    """Extrude a convex-or-not 2D polygon (list of (x, y), CCW) from z0 to z1."""
    bm = a.bm(role)
    bot = [bm.verts.new((x, y, z0)) for x, y in pts]
    top = [bm.verts.new((x, y, z1)) for x, y in pts]
    n = len(pts)
    for i in range(n):
        k = (i + 1) % n
        bm.faces.new((bot[i], bot[k], top[k], top[i]))
    bm.faces.new(list(reversed(bot)))
    bm.faces.new(top)
    verts = bot + top
    _xf(bm, verts, Matrix.Translation(center) @ _rot(rot))
    return verts


def frustum_rect(a, role, center, w0, d0, w1, d1, h, rot=(0, 0, 0), shift=(0, 0)):
    """Rectangular frustum: bottom w0 x d0 at z=0, top w1 x d1 at z=h, top shifted by `shift`."""
    bm = a.bm(role)
    b = [bm.verts.new((sx * w0 / 2, sy * d0 / 2, 0)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    t = [
        bm.verts.new((sx * w1 / 2 + shift[0], sy * d1 / 2 + shift[1], h))
        for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))
    ]
    for i in range(4):
        k = (i + 1) % 4
        bm.faces.new((b[i], b[k], t[k], t[i]))
    bm.faces.new(list(reversed(b)))
    if w1 > 0.0001 and d1 > 0.0001:
        bm.faces.new(t)
    verts = b + t
    _xf(bm, verts, Matrix.Translation(center) @ _rot(rot))
    return verts


# ---------------------------------------------------------------- export


def export_fbx(path, roots):
    bpy.ops.object.select_all(action="DESELECT")
    for r in roots:
        r.select_set(True)
        for c in r.children_recursive:
            c.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        object_types={"EMPTY", "MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_NONE",
        global_scale=0.01,  # Roblox imports FBX units as cm*100: 0.01 makes 1 Blender unit = 1 stud
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        use_mesh_modifiers=True,
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="AUTO",
    )


def export_glb(path, roots):
    bpy.ops.object.select_all(action="DESELECT")
    for r in roots:
        r.select_set(True)
        for c in r.children_recursive:
            c.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_normals=True,
        export_materials="EXPORT",
    )


def save_blend(path):
    bpy.ops.wm.save_as_mainfile(filepath=path)


def bounds_obj(o):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for v in o.data.vertices:
        w = o.matrix_world @ v.co
        lo = Vector(map(min, lo, w))
        hi = Vector(map(max, hi, w))
    return lo, hi


def bounds(root):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for c in root.children_recursive:
        if c.type != "MESH":
            continue
        for v in c.data.vertices:
            w = c.matrix_world @ v.co
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


# ---------------------------------------------------------------- previews (front, side, rear, 3/4 contact sheet)


def preview(roots, path, size=360):
    """Renders each root from 4 angles (front -Y, right +X, rear +Y, 3/4) with Workbench and writes one PNG sheet:
    one row per asset. Needs numpy (bundled with Blender)."""
    import numpy as np

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_cavity = True
    scene.display.shading.cavity_type = "WORLD"
    scene.display.shading.show_object_outline = True
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.film_transparent = False
    scene.world = scene.world or bpy.data.worlds.new("W")
    scene.world.color = (0.62, 0.78, 0.95)
    cam_data = bpy.data.cameras.new("PreviewCam")
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    rows = []
    hidden = {}
    for r in roots:
        for c in [r] + list(r.children_recursive):
            hidden[c] = c.hide_render
    everything = [o for o in scene.objects if o.type in ("MESH", "EMPTY")]
    for o in everything:
        hidden.setdefault(o, o.hide_render)
    for root in roots:
        family = set([root] + list(root.children_recursive))
        for o in everything:
            o.hide_render = o not in family
        lo, hi = bounds(root)
        center = (lo + hi) / 2
        ext = max((hi - lo).length, 1.0)
        tiles = []
        for ang, elev in ((-90, 12), (0, 12), (90, 12), (-45, 32)):
            a = math.radians(ang)
            e = math.radians(elev)
            d = ext * 1.25
            cam.location = center + Vector((math.cos(a) * math.cos(e) * d, math.sin(a) * math.cos(e) * d, math.sin(e) * d))
            direction = center - cam.location
            cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
            cam_data.lens = 50
            tmp = path + f".tmp.png"
            scene.render.filepath = tmp
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(tmp)
            px = np.array(img.pixels[:], dtype=np.float32).reshape(size, size, 4)[::-1]
            bpy.data.images.remove(img)
            tiles.append(px)
        rows.append(np.concatenate(tiles, axis=1))
    for c, h in hidden.items():
        c.hide_render = h
    sheet = np.concatenate(rows, axis=0)
    h, w = sheet.shape[:2]
    out = bpy.data.images.new("sheet", w, h, alpha=True)
    out.pixels = sheet[::-1].ravel()
    out.filepath_raw = path
    out.file_format = "PNG"
    out.save()
    import os

    try:
        os.remove(path + ".tmp.png")
    except OSError:
        pass
