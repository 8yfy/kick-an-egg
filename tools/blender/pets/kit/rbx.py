# Roblox-primitive modelling helpers for Blender (imported inside Blender; see README.md).
# Every object is one BlockBuilder part: a unit Block/Wedge/Ball/Cylinder mesh in Roblox local axes,
# placed by a Roblox CFrame. Roblox space: +Y up, front = -Z, left = -X. Blender: x = x, y = -z, z = y.
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

C3 = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox -> Blender
C3T = C3.transposed()


def rot_r(rx=0.0, ry=0.0, rz=0.0):
    """CFrame.Angles(rx, ry, rz) in degrees = Rx @ Ry @ Rz."""
    return (
        Matrix.Rotation(math.radians(rx), 3, "X")
        @ Matrix.Rotation(math.radians(ry), 3, "Y")
        @ Matrix.Rotation(math.radians(rz), 3, "Z")
    )


class CF:
    def __init__(self, p=(0, 0, 0), R=None):
        self.p = Vector(p)
        self.R = R.copy() if R is not None else Matrix.Identity(3)

    def __mul__(self, o):
        return CF(self.p + self.R @ o.p, self.R @ o.R)

    def vec(self, v):
        return self.R @ Vector(v)

    def point(self, v):
        return self.p + self.R @ Vector(v)


def cf(p=(0, 0, 0), rx=0.0, ry=0.0, rz=0.0):
    return CF(p, rot_r(rx, ry, rz))


def frame(p, X, Y, Z):
    R = Matrix((tuple(X), tuple(Y), tuple(Z))).transposed()  # columns = local axes
    return CF(p, R)


def look(p, up, hint=(0, 0, 1)):
    """CF at p whose local +Y is `up`; local Z as close to `hint` as possible."""
    Y = Vector(up).normalized()
    Z = Vector(hint)
    Z = (Z - Y * Z.dot(Y))
    if Z.length < 1e-4:
        Z = Vector((1, 0, 0)) - Y * Y.x
    Z.normalize()
    X = Y.cross(Z)
    return frame(p, X, Y, Z)


# ---- unit meshes (shared) -----------------------------------------------------------------------------
def _unit_mesh(shape):
    name = "RBX_unit_" + shape
    me = bpy.data.meshes.get(name)
    if me:
        return me
    pts = []
    if shape == "Block":
        pts = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    elif shape == "Wedge":
        pts = [(x, -0.5, z) for x in (-0.5, 0.5) for z in (-0.5, 0.5)] + [(x, 0.5, 0.5) for x in (-0.5, 0.5)]
    elif shape == "Cylinder":  # Roblox cylinders run along local X
        for x in (-0.5, 0.5):
            for k in range(24):
                a = k / 24 * math.tau
                pts.append((x, 0.5 * math.cos(a), 0.5 * math.sin(a)))
    elif shape == "Ball":
        for i in range(1, 12):
            t = i / 12 * math.pi
            for k in range(20):
                a = k / 20 * math.tau
                pts.append((0.5 * math.sin(t) * math.cos(a), 0.5 * math.cos(t), 0.5 * math.sin(t) * math.sin(a)))
        pts += [(0, 0.5, 0), (0, -0.5, 0)]
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    for p in pts:
        bm.verts.new(C3 @ Vector(p))
    bmesh.ops.convex_hull(bm, input=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if shape in ("Ball", "Cylinder"):
        for f in bm.faces:
            f.smooth = shape == "Ball" or abs(f.normal.x) < 0.9
    bm.to_mesh(me)
    bm.free()
    me.materials.append(None)  # one slot; each object links its own material (shared mesh)
    return me


# ---- materials -------------------------------------------------------------------------------------------
def hexc(h):
    h = h.lstrip("#")
    srgb = [int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    return (*lin, 1.0)


def get_mat(hx, mat, transp):
    key = "RBX_%s_%s_%02d" % (hx.lstrip("#").upper(), mat, round(transp * 100))
    m = bpy.data.materials.get(key)
    if m:
        return m
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    col = hexc(hx)
    b.inputs["Base Color"].default_value = col
    b.inputs["Roughness"].default_value = 0.45
    if mat == "Neon":
        b.inputs["Emission Color"].default_value = col
        b.inputs["Emission Strength"].default_value = 1.6
    elif mat == "Glass":
        b.inputs["Roughness"].default_value = 0.08
        b.inputs["Coat Weight"].default_value = 0.6
    elif mat == "Metal":
        b.inputs["Metallic"].default_value = 0.8
        b.inputs["Roughness"].default_value = 0.3
    elif mat == "Ice":
        b.inputs["Roughness"].default_value = 0.15
    alpha = 1.0 - transp if mat != "Glass" else 1.0 - min(0.9, transp * 1.6 + 0.12)
    if alpha < 0.999:
        b.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
    m.diffuse_color = col
    return m


# ---- parts -----------------------------------------------------------------------------------------------
COLL = None
JOINT = "Root"
COUNT = {"n": 0}


def J(name):
    """Joint group for the parts built next (BlockBuilder `joint`)."""
    global JOINT
    JOINT = name


def coll():
    return COLL


def use(collection_name, offset=(0, 0, 0)):
    """Build into a fresh collection; `offset` (Roblox studs) shifts the whole model for side-by-side views."""
    global COLL
    old = bpy.data.collections.get(collection_name)
    if old:
        for ob in list(old.objects):
            bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.collections.remove(old)
    COLL = bpy.data.collections.new(collection_name)
    bpy.context.scene.collection.children.link(COLL)
    COLL["rbx_offset"] = list(offset)
    COUNT["n"] = 0
    J("Root")
    return COLL


def part(name, size, c, hx, mat="SmoothPlastic", shape="Block", joint=None, studs=None, transp=0.0):
    size = list(size)
    if shape == "Ball":
        size = [size[0]] * 3
    elif shape == "Cylinder":
        d = min(size[1], size[2])
        size = [size[0], d, d]
    off = Vector(COLL["rbx_offset"]) if COLL is not None and "rbx_offset" in COLL else Vector((0, 0, 0))
    ob = bpy.data.objects.new(name, _unit_mesh(shape))
    COLL.objects.link(ob)
    Rb = C3 @ c.R @ C3T
    S = Matrix.Diagonal((size[0], size[2], size[1], 1.0))
    ob.matrix_world = Matrix.Translation(C3 @ (c.p + off)) @ Rb.to_4x4() @ S
    ob.material_slots[0].link = "OBJECT"
    ob.material_slots[0].material = get_mat(hx, mat, transp)
    ob["rbx_name"] = name
    ob["rbx_shape"] = shape
    ob["rbx_joint"] = joint or JOINT
    ob["rbx_material"] = mat
    ob["rbx_color"] = hx.lstrip("#").upper()
    ob["rbx_transparency"] = float(transp)
    ob["rbx_studs"] = -1 if studs is None else int(bool(studs))
    ob["rbx_order"] = COUNT["n"]
    COUNT["n"] += 1
    return ob


def seg(name, a, b, w, t, hx, up_hint=(0, 0, 1), **kw):
    """A block from point a to point b (local Y along a->b), width w (X) and depth t (Z)."""
    a, b = Vector(a), Vector(b)
    d = b - a
    c = look((a + b) / 2, d, up_hint)
    return part(name, (w, d.length, t), c, hx, **kw)


def crystal(name, base, up, length, width, body_hx, tip_hx, hint=(0, 0, 1), tip_mat="Neon", n=2, **kw):
    """Stepped bricky crystal: a diamond-turned body plus a smaller tip (n=1 body only, n=3 adds a cap)."""
    c = look(Vector(base), up, hint) * cf(rz=0, ry=45)
    kw.setdefault("studs", False)
    out = []
    if n == 1:
        out.append(part(name, (width, length, width), c * CF((0, length / 2, 0)), body_hx, mat="Glass", transp=0.2, **kw))
        return out
    out.append(part(name + "A", (width, length * 0.62, width), c * CF((0, length * 0.31, 0)), body_hx, mat="Glass", transp=0.2, **kw))
    if n == 2:
        out.append(part(name + "B", (width * 0.55, length * 0.42, width * 0.55), c * CF((0, length * 0.79, 0)), tip_hx, mat=tip_mat, **kw))
    else:
        out.append(part(name + "B", (width * 0.66, length * 0.3, width * 0.66), c * CF((0, length * 0.74, 0)), body_hx, mat="Glass", transp=0.2, **kw))
        out.append(part(name + "C", (width * 0.34, length * 0.2, width * 0.34), c * CF((0, length * 0.94, 0)), tip_hx, mat=tip_mat, **kw))
    return out


def _wedge_rt(name, F, P, Q, thick, hx, **kw):
    """Right-triangle wedge with its right angle at F, legs F->P and F->Q."""
    F, P, Q = Vector(F), Vector(P), Vector(Q)
    d, h = (P - F).length, (Q - F).length
    if d < 0.03 or h < 0.03:
        return None
    Y = (Q - F).normalized()
    Z = -(P - F).normalized()
    X = Y.cross(Z)
    centre = F + Y * (h / 2) - Z * (d / 2)
    return part(name, (thick, h, d), frame(centre, X, Y, Z), hx, shape="Wedge", **kw)


def tri(name, a, b, c, thick, hx, **kw):
    """Any triangle from two wedges, split by the altitude onto its longest edge."""
    pts = [Vector(a), Vector(b), Vector(c)]
    edges = [(0, 1, 2), (1, 2, 0), (2, 0, 1)]
    u, v, w = max(edges, key=lambda e: (pts[e[0]] - pts[e[1]]).length)
    U, V, W = pts[u], pts[v], pts[w]
    e = (V - U).normalized()
    F = U + e * (W - U).dot(e)
    kw.setdefault("studs", False)
    out = [_wedge_rt(name + "a", F, U, W, thick, hx, **kw), _wedge_rt(name + "b", F, V, W, thick, hx, **kw)]
    return [o for o in out if o]


# ---- curves ----------------------------------------------------------------------------------------------
def catmull(points, sub=10):
    pts = [Vector(p) for p in points]
    pts = [pts[0] * 2 - pts[1]] + pts + [pts[-1] * 2 - pts[-2]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for k in range(sub):
            t = k / sub
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(pts[-2])
    return out


def resample(poly, n):
    """n+1 points evenly spaced by arc length, plus each point's arc fraction."""
    acc = [0.0]
    for i in range(1, len(poly)):
        acc.append(acc[-1] + (poly[i] - poly[i - 1]).length)
    L = acc[-1]
    out, fr = [], []
    j = 0
    for k in range(n + 1):
        s = L * k / n
        while j < len(acc) - 2 and acc[j + 1] < s:
            j += 1
        seg_len = acc[j + 1] - acc[j]
        t = 0 if seg_len == 0 else (s - acc[j]) / seg_len
        out.append(poly[j].lerp(poly[j + 1], min(1, max(0, t))))
        fr.append(k / n)
    return out, fr, L


def keys(x, pairs):
    if x <= pairs[0][0]:
        return pairs[0][1]
    for (x0, y0), (x1, y1) in zip(pairs, pairs[1:]):
        if x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return pairs[-1][1]


def smooth(e0, e1, x):
    t = min(1, max(0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)
