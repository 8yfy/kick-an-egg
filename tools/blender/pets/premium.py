# Premium mesh pipeline (the user's "master Blender modelling handoff", 2026-10-31): turns a V3 pet build (Roblox
# primitives in Blender, studs in Roblox axes) into a game-ready mesh pet for KickAnEgg_PremiumPets/<Name>/:
#   - every part bevelled (a chamfer that catches light; thin plates get a smaller one, balls none), studs dropped;
#   - merged into one mesh per joint and kind, each kind with its own palette texture so colours never split a mesh:
#     Solid (colour, metalness, roughness maps -> SurfaceAppearance), Glow (colour map -> a Neon MeshPart) and Crystal
#     (colour map with alpha 0.75 -> SurfaceAppearance, AlphaMode Transparency), so draw calls stay low;
#   - an armature built from the BlockBuilder hinges (same joint names as the game's Motor6Ds), rigid skinning;
#   - Idle, Walk/Float and Special actions (loops), pushed to NLA so FBX and glTF both carry them;
#   - previews (front, side, rear, hero 3/4, gameplay distance, animation strips), .blend, .fbx, .glb, textures,
#     a re-import check of both exports and a Studio JSON (per-mesh triangles and colours) for an EditableMesh preview.
#   python -I bmcp.py code premium.py -- what=HeavenLion steps=build,anim,export,validate,preview
import importlib
import json
import math
import os
import re

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

from kit import stage
from kit.rbx import C3

C3T = C3.transposed()
KEY = ARGS.get("what", "HeavenLion")
STEPS = ARGS.get("steps", "build,anim,export,validate,preview").split(",")
BEVEL = float(ARGS.get("bevel", "0.06"))
CFG = {
    "HeavenLion": dict(name="HeavenlyLion", mod="v3.heaven_lion", rig="quad",
                       metal={"E2B04A": (0.75, 0.3), "C9932E": (0.75, 0.36)}, spin=[]),
    "PrismSeraph": dict(name="PrismSeraph", mod="v3.prism_seraph", rig="float",
                        metal={"E0B24E": (0.75, 0.3), "C4932F": (0.75, 0.36), "DCD8E6": (0.5, 0.3)}, spin=[]),
    "ClockworkTitan": dict(name="ClockworkTitan", mod="v3.clockwork_titan", rig="mech",
                           metal={"C9A24E": (0.75, 0.4), "A8823A": (0.75, 0.45), "F3D98C": (0.75, 0.35),
                                  "34302D": (0.6, 0.6), "4A4440": (0.6, 0.55)},
                           spin=[(r"^(Heart)Hand\d+$", "HeartFace"), (r"^(Gear\d+)(T\d+)?$", None)],
                           numerals=[("ShoulderClockLFace", 0.62, 0.15), ("ShoulderClockRFace", 0.62, 0.15)]),
}
cfg = CFG[KEY]
NAME = cfg["name"]
ROOT = REPO + "/KickAnEgg_PremiumPets/" + NAME + "/"
for d in ("Textures", "Animations", "Previews"):
    os.makedirs(ROOT + d, exist_ok=True)
COLL = "PREMIUM_" + NAME
FPS = 30


def srgb(hx):
    return [int(hx[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def rbx(v):  # Blender -> Roblox coordinates
    return C3T @ Vector(v)


def tris_of(me):
    return sum(len(p.vertices) - 2 for p in me.polygons)


ROMAN = ("XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI")


def roman_numerals(src, face_name, rad, h, ink="1A1614"):
    """Mesh-only tertiary detail: flat Roman numerals round a clock face (the Titan's shoulder clocks). The numerals
    become extra source objects in the face's joint, so they merge into that joint's Solid mesh."""
    face = next((o for o in src.objects if o["rbx_name"] == face_name), None)
    if face is None:
        return
    M = face.matrix_world
    cols = [M.col[i].to_3d() for i in range(3)]
    k = min(range(3), key=lambda i: cols[i].length)  # the thin axis is the normal
    n = cols[k].normalized()
    c = M.translation.copy()
    if n.dot(Vector((c.x, c.y, 0))) < 0:  # face away from the body
        n = -n
    r = max(cols[i].length for i in range(3) if i != k) / 2
    up = Vector((0, 0, 1))
    up = (up - n * up.dot(n)).normalized()
    x = up.cross(n)
    for i, txt in enumerate(ROMAN):
        cu = bpy.data.curves.new("_num", "FONT")
        cu.body = txt
        cu.size = h
        cu.align_x, cu.align_y = "CENTER", "CENTER"
        tob = bpy.data.objects.new("_num", cu)
        src.objects.link(tob)
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(tob.evaluated_get(dg))
        bpy.data.objects.remove(tob, do_unlink=True)
        bpy.data.curves.remove(cu)
        a = 2 * math.pi * i / 12
        pos = c + (x * math.sin(a) + up * math.cos(a)) * r * rad + n * 0.075
        R = Matrix((x, up, n)).transposed().to_4x4()
        me.transform(Matrix.Translation(pos) @ R)
        if not me.materials:
            me.materials.append(None)
        ob = bpy.data.objects.new(face_name.replace("Face", "Numeral%d" % (i + 1)), me)
        src.objects.link(ob)
        ob["rbx_name"] = ob.name
        ob["rbx_shape"] = "Text"
        ob["rbx_joint"] = face["rbx_joint"]
        ob["rbx_material"] = "SmoothPlastic"
        ob["rbx_color"] = ink
        ob["rbx_transparency"] = 0.0
        ob["rbx_studs"] = 0
        ob["rbx_order"] = 100000 + i


# ---- build: bevel, merge, palette, rig ---------------------------------------------------------------------------
def build():
    mod = importlib.import_module(cfg["mod"])
    src = mod.build("PK3_%s_Pet" % KEY, (0, 0, 0))
    old = bpy.data.collections.get(COLL)
    if old:
        for ob in list(old.objects):
            bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.collections.remove(old)
    pc = bpy.data.collections.new(COLL)
    bpy.context.scene.collection.children.link(pc)

    # joints: hinge pivots (or the first part of a group), plus spinning sub-groups (clock hands, gears)
    for face, rad, h in cfg.get("numerals", []):
        roman_numerals(src, face, rad, h)
    objs = sorted(src.objects, key=lambda o: o["rbx_order"])
    pivots, joint_of, parent_joint = {"Root": Vector((0, 0, 0))}, {}, {}
    for ob in objs:
        j = ob["rbx_joint"]
        if ob["rbx_name"] == "Hinge" + j:
            pivots[j] = ob.matrix_world.translation.copy()
    by_name = {ob["rbx_name"]: ob for ob in objs}
    for ob in objs:
        j = ob["rbx_joint"]
        if j not in pivots:
            pivots[j] = ob.matrix_world.translation.copy()
        joint_of[ob.name] = j
        for rx, piv in cfg["spin"]:
            m = re.match(rx, ob["rbx_name"])
            if m and ob["rbx_joint"] != m.group(1) + ("Hands" if "Hand" in rx else ""):  # not already a joint
                sub = m.group(1) + ("Hands" if "Hand" in rx else "")
                joint_of[ob.name] = sub
                parent_joint[sub] = j
                if sub not in pivots:
                    pv = by_name.get(piv) if piv else by_name.get(m.group(1))
                    pivots[sub] = (pv or ob).matrix_world.translation.copy()
                break

    # one mesh per joint and kind; each kind has its own palette texture so colours never split a mesh
    groups, pal = {}, {"Solid": [], "Glow": [], "Crystal": []}
    for ob in objs:
        if ob["rbx_name"].startswith("Hinge") or ob["rbx_transparency"] >= 0.99:
            continue
        mat, hx, tr = ob["rbx_material"], ob["rbx_color"], ob["rbx_transparency"]
        kind = "Glow" if mat == "Neon" else ("Crystal" if mat == "Glass" or tr > 0.05 else "Solid")
        if hx not in pal[kind]:
            pal[kind].append(hx)
        groups.setdefault((joint_of[ob.name], kind), []).append(ob)
    cells = {k: {hx: i for i, hx in enumerate(v)} for k, v in pal.items()}
    assert all(len(v) <= 64 for v in cells.values()), "palette overflow"

    # palette textures: 8x8 cells of 32 px. Solid: colour, metalness, roughness; Glow: colour; Crystal: colour + alpha
    N, C = 256, 32
    layers = {"Color": np.ones((N, N, 4), np.float32), "Metalness": np.zeros((N, N, 4), np.float32),
              "Roughness": np.full((N, N, 4), 0.55, np.float32), "GlowColor": np.ones((N, N, 4), np.float32),
              "CrystalColor": np.ones((N, N, 4), np.float32)}
    layers["Metalness"][..., 3] = 1
    layers["Roughness"][..., 3] = 1
    for kind, tags in (("Solid", ("Color",)), ("Glow", ("GlowColor",)), ("Crystal", ("CrystalColor",))):
        for hx, i in cells[kind].items():
            cx, cy = i % 8, i // 8
            ys, xs = slice(cy * C, cy * C + C), slice(cx * C, cx * C + C)
            layers[tags[0]][ys, xs, :3] = srgb(hx)
            if kind == "Crystal":
                layers[tags[0]][ys, xs, 3] = 0.75
            if kind == "Solid":
                m, r = cfg["metal"].get(hx, (0.0, 0.55))
                layers["Metalness"][ys, xs, :3] = m
                layers["Roughness"][ys, xs, :3] = r
    imgs = {}
    for tag, arr in layers.items():
        kind = {"GlowColor": "Glow", "CrystalColor": "Crystal"}.get(tag, "Solid")
        if not cells[kind]:
            continue
        nm = "%s_%s" % (NAME, tag)
        if bpy.data.images.get(nm):
            bpy.data.images.remove(bpy.data.images[nm])
        im = bpy.data.images.new(nm, N, N, alpha=tag == "CrystalColor")
        im.colorspace_settings.name = "Non-Color" if tag in ("Metalness", "Roughness") else "sRGB"
        im.pixels.foreach_set(arr.ravel())
        im.filepath_raw = ROOT + "Textures/%s.png" % nm
        im.file_format = "PNG"
        im.save()
        imgs[tag] = im

    def material(kind):
        nm = "M_%s_%s" % (NAME, kind)
        m = bpy.data.materials.get(nm)
        if m:
            bpy.data.materials.remove(m)
        m = bpy.data.materials.new(nm)
        m.use_nodes = True
        nt = m.node_tree
        b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")

        def tex(tag):
            t = nt.nodes.new("ShaderNodeTexImage")
            t.image = imgs[tag]
            t.interpolation = "Closest"
            return t
        if kind == "Solid":
            for tag, sock in (("Color", "Base Color"), ("Metalness", "Metallic"), ("Roughness", "Roughness")):
                nt.links.new(tex(tag).outputs["Color"], b.inputs[sock])
        elif kind == "Glow":
            t = tex("GlowColor")
            nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
            nt.links.new(t.outputs["Color"], b.inputs["Emission Color"])
            b.inputs["Emission Strength"].default_value = 2.5
        else:
            t = tex("CrystalColor")
            nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
            nt.links.new(t.outputs["Alpha"], b.inputs["Alpha"])
            b.inputs["Roughness"].default_value = 0.05
            try:
                m.surface_render_method = "BLENDED"
            except Exception:
                pass
        return m

    mats = {k: material(k) for k in pal if cells[k]}
    meshes, report = [], {}
    for (j, kind), obs in sorted(groups.items()):
        out = bmesh.new()
        tmp = bpy.data.meshes.new("_tmp")
        for ob in obs:
            bm = bmesh.new()
            bm.from_mesh(ob.data)
            M = ob.matrix_world
            bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
            if M.to_3x3().determinant() < 0:
                bmesh.ops.reverse_faces(bm, faces=bm.faces)
            bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(1.5), verts=bm.verts[:], edges=bm.edges[:])
            mind = min(abs(x) for x in M.to_scale())
            w = min(BEVEL, 0.2 * mind)
            if ob["rbx_shape"] not in ("Ball", "Text") and w >= 0.012:
                sharp = [e for e in bm.edges if e.is_manifold and e.calc_face_angle(0) > math.radians(30)]
                if sharp:
                    bmesh.ops.bevel(bm, geom=sharp, offset=w, offset_type="OFFSET", segments=1, profile=0.5,
                                    affect="EDGES", clamp_overlap=True)
            smooth = ob["rbx_shape"] == "Ball"
            uvl = bm.loops.layers.uv.verify()
            cl = bm.loops.layers.float_color.new("Col") if "Col" not in bm.loops.layers.float_color \
                else bm.loops.layers.float_color["Col"]
            rgb = [*[x ** 2.2 for x in srgb(ob["rbx_color"])], 1.0]
            i = cells[kind][ob["rbx_color"]]
            uv = ((i % 8 + 0.5) / 8, (i // 8 + 0.5) / 8)
            for f in bm.faces:
                f.smooth = smooth and f.smooth
                for lp in f.loops:
                    lp[uvl].uv = uv
                    lp[cl] = rgb
            bm.to_mesh(tmp)
            bm.free()
            out.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
        nm = "%s_%s_%s" % (NAME, j, kind)
        me = bpy.data.meshes.new(nm)
        out.to_mesh(me)
        out.free()
        me.materials.append(mats[kind])
        o = bpy.data.objects.new(nm, me)
        pc.objects.link(o)
        vg = o.vertex_groups.new(name=j)
        vg.add(range(len(me.vertices)), 1.0, "REPLACE")
        meshes.append(o)
        report[nm] = dict(joint=j, kind=kind, colors=sorted({ob["rbx_color"] for ob in obs}), parts=len(obs),
                          tris=tris_of(me))

    # armature from the pivots: legs hang off Root for walkers; everything else rides Body
    arm_d = bpy.data.armatures.new(NAME + "_Rig")
    arm = bpy.data.objects.new(NAME + "_Rig", arm_d)
    pc.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    root_kids = {"quad": ("Body", "ArmL", "ArmR", "LegL", "LegR"), "mech": ("Body", "LegL", "LegR"),
                 "float": ("Body",)}[cfg["rig"]]
    bones = {}
    used = sorted({j for (j, _) in groups} | {"Root", "Body"} | set(parent_joint))
    for j in used:
        if j not in pivots:
            continue
        eb = arm_d.edit_bones.new(j)
        eb.head = pivots[j]
        eb.tail = pivots[j] + Vector((0, 0, 0.6 if j != "Root" else 1.0))
        bones[j] = eb
    for j, eb in bones.items():
        if j == "Root":
            continue
        par = parent_joint.get(j) or ("Root" if j in root_kids else "Body")
        eb.parent = bones.get(par) or bones["Root"]
    bpy.ops.object.mode_set(mode="OBJECT")
    for o in meshes:
        o.parent = arm
        md = o.modifiers.new("Rig", "ARMATURE")
        md.object = arm
    info = dict(key=KEY, name=NAME, bones={j: list(rbx(p)) for j, p in pivots.items() if j in bones},
                meshes=report, tris=sum(r["tris"] for r in report.values()), parts_source=len(objs))
    json.dump(info, open(ROOT + "build.json", "w"), indent=1)
    print("built %s: %d meshes, %d tris, %d bones" % (NAME, len(meshes), info["tris"], len(bones)))


# ---- animation ---------------------------------------------------------------------------------------------------
def env(f, a, b, c, d):
    """0 before a, eased up to 1 at b, hold to c, eased down to 0 at d."""
    def ease(t):
        t = max(0.0, min(1.0, t))
        return t * t * (3 - 2 * t)
    return ease((f - a) / (b - a)) if f < c else 1 - ease((f - c) / (d - c))


def motions(rig):
    """{action: (frames, fn(f) -> {bone: (rot_xyz_deg, loc_xyz)})}. Bone axes: X = side (pitch, legs swing), Y = up
    (yaw), Z = -forward (roll). Positive X lifts the front / swings a foot forward."""
    S = math.sin
    if rig == "quad":
        def idle(f):
            t = f / 72 * math.tau
            return {"Body": ((S(t) * 1.0, 0, 0), (0, 0.04 * S(t), 0)),
                    "Head": ((3 * S(t + 0.6), 6 * S(t), 0), (0, 0, 0)),
                    "Tail": ((4 * S(2 * t), 12 * S(t), 0), (0, 0, 0))}

        def walk(f):
            p = f / 32 * math.tau
            a = 18 * S(p)
            return {"ArmL": ((a, 0, 0), (0, 0, 0)), "LegR": ((a, 0, 0), (0, 0, 0)),
                    "ArmR": ((-a, 0, 0), (0, 0, 0)), "LegL": ((-a, 0, 0), (0, 0, 0)),
                    "Body": ((0, 0, 1.5 * S(p)), (0, 0.05 * math.cos(2 * p), 0)),
                    "Head": ((-2 * math.cos(2 * p), 3 * S(p), 0), (0, 0, 0)),
                    "Tail": ((0, 10 * S(p), 0), (0, 0, 0))}

        def special(f):
            e = env(f, 4, 18, 40, 58)
            return {"Head": ((22 * e, 0, 0), (0, 0, 0)), "Body": ((4 * e, 0, 0), (0, 0.12 * e, 0)),
                    "Tail": ((20 * e, 8 * S(f / 60 * 2 * math.tau) * e, 0), (0, 0, 0))}
        return {"Idle": (72, idle), "Walk": (32, walk), "Special": (60, special)}
    if rig == "mech":
        def idle(f):
            t = f / 72 * math.tau
            return {"Body": ((0, 0, 0), (0, 0.03 * S(t), 0)), "ArmL": ((3 * S(t), 0, 0), (0, 0, 0)),
                    "ArmR": ((-3 * S(t), 0, 0), (0, 0, 0)), "Head": ((0, 8 * S(t), 0), (0, 0, 0)),
                    "HeartHands": ((0, 0, -360 * f / 72), (0, 0, 0)),
                    **{"Gear%d" % i: ((0, 0, (90 if i % 2 else -90) * f / 72), (0, 0, 0)) for i in range(1, 9)}}

        def walk(f):
            p = f / 40 * math.tau
            return {"LegL": ((14 * S(p), 0, 0), (0, 0, 0)), "LegR": ((-14 * S(p), 0, 0), (0, 0, 0)),
                    "ArmL": ((-10 * S(p), 0, 0), (0, 0, 0)), "ArmR": ((10 * S(p), 0, 0), (0, 0, 0)),
                    "Body": ((0, 0, 2 * S(p)), (0, 0.06 * math.cos(2 * p) - 0.06, 0)),
                    "HeartHands": ((0, 0, -360 * f / 40), (0, 0, 0))}

        def special(f):
            e = env(f, 4, 20, 38, 58)
            return {"ArmL": ((55 * e, 0, -8 * e), (0, 0, 0)), "ArmR": ((55 * e, 0, 8 * e), (0, 0, 0)),
                    "Body": ((4 * e, 0, 0), (0, 0.08 * e, 0)), "Head": ((10 * e, 0, 0), (0, 0, 0)),
                    "HeartHands": ((0, 0, -1440 * f / 60), (0, 0, 0)),
                    **{"Gear%d" % i: ((0, 0, (360 if i % 2 else -360) * f / 60), (0, 0, 0)) for i in range(1, 9)}}
        return {"Idle": (72, idle), "Walk": (40, walk), "Special": (60, special)}

    def idle(f):
        t = f / 72 * math.tau
        w = 10 * S(t)
        return {"Body": ((0, 0, 0), (0, 0.25 * S(t), 0)), "WingL": ((0, 0, -w), (0, 0, 0)),
                "WingR": ((0, 0, w), (0, 0, 0)), "Orbit": ((0, 360 * f / 72, 0), (0, 0, 0)),
                "Halo": ((0, -360 * f / 72, 0), (0, 0, 0)), "ArmL": ((4 * S(t + 1), 0, 0), (0, 0, 0)),
                "ArmR": ((4 * S(t + 1), 0, 0), (0, 0, 0)), "Head": ((0, 5 * S(t), 0), (0, 0, 0))}

    def floatf(f):
        p = f / 48 * math.tau
        w = 18 * S(2 * p)
        return {"Body": ((-8, 0, 3 * S(p)), (0, 0.15 * S(2 * p), 0)), "WingL": ((0, 0, -w), (0, 0, 0)),
                "WingR": ((0, 0, w), (0, 0, 0)), "Orbit": ((0, 360 * f / 48, 0), (0, 0, 0)),
                "Halo": ((0, -360 * f / 48, 0), (0, 0, 0))}

    def special(f):
        e = env(f, 4, 20, 40, 58)
        return {"WingL": ((0, 0, -26 * e), (0, 0, 0)), "WingR": ((0, 0, 26 * e), (0, 0, 0)),
                "ArmL": ((35 * e, 0, -20 * e), (0, 0, 0)), "ArmR": ((35 * e, 0, 20 * e), (0, 0, 0)),
                "Head": ((12 * e, 0, 0), (0, 0, 0)), "Body": ((0, 0, 0), (0, 0.4 * e, 0)),
                "Orbit": ((0, 720 * f / 60, 0), (0, 0, 0)), "Halo": ((0, -720 * f / 60, 0), (0, 0, 0))}
    return {"Idle": (72, idle), "Float": (48, floatf), "Special": (60, special)}


def animate():
    arm = bpy.data.objects[NAME + "_Rig"]
    ad = arm.animation_data_create()
    for t in list(ad.nla_tracks):
        ad.nla_tracks.remove(t)
    for a in [a for a in bpy.data.actions if a.name.startswith(NAME + "_")]:
        bpy.data.actions.remove(a)
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
    out = {}
    for act_name, (frames, fn) in motions(cfg["rig"]).items():
        act = bpy.data.actions.new("%s_%s" % (NAME, act_name))
        ad.action = act
        step = 4
        keyed = set()
        for f in list(range(0, frames, step)) + [frames]:
            pose = fn(f)
            for bn, (rot, loc) in pose.items():
                pb = arm.pose.bones.get(bn)
                if pb is None:
                    continue
                pb.rotation_euler = [math.radians(x) for x in rot]
                pb.location = loc
                pb.keyframe_insert("rotation_euler", frame=f)
                pb.keyframe_insert("location", frame=f)
                keyed.add(bn)
        spin = act_name != "Special"  # loops: linear spins so the cycle is seamless
        for fc in getattr(act, "fcurves", []) or []:
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR" if spin and "rotation" in fc.data_path else "BEZIER"
        ad.action = None
        tr = ad.nla_tracks.new()
        tr.name = act.name
        tr.strips.new(act.name, 0, act)
        tr.mute = True
        act.use_fake_user = True
        out[act.name] = dict(frames=frames, fps=FPS, seconds=round(frames / FPS, 2), bones=sorted(keyed),
                             loop=act_name != "Special")
    for pb in arm.pose.bones:
        pb.rotation_euler = (0, 0, 0)
        pb.location = (0, 0, 0)
    bpy.context.scene.render.fps = FPS
    json.dump(out, open(ROOT + "Animations/%s_animations.json" % NAME, "w"), indent=1)
    print("actions:", ", ".join("%s %df" % (k, v["frames"]) for k, v in out.items()))


# ---- export --------------------------------------------------------------------------------------------------------
def premium_objects():
    return list(bpy.data.collections[COLL].objects)


def select_premium():
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    obs = premium_objects()
    for o in obs:
        o.hide_set(False)
        o.select_set(True)
    bpy.context.view_layer.objects.active = bpy.data.objects[NAME + "_Rig"]
    return obs


def export():
    pc = bpy.data.collections[COLL]
    # writing a Scene with libraries.write crashes Blender 5.2 (view layer copy), so write the collection and let a
    # background Blender append it into a clean scene and save the deliverable .blend (blend_scene.py). The texture
    # paths are absolute here; RELATIVE_ALL turns them into //Textures/... next to the .blend.
    lib = ROOT + "_%s_lib.blend" % NAME
    acts = {a for a in bpy.data.actions if a.name.startswith(NAME + "_")}
    bpy.data.libraries.write(lib, {pc} | acts, path_remap="RELATIVE_ALL", fake_user=True)
    select_premium()
    bpy.ops.export_scene.fbx(filepath=ROOT + NAME + ".fbx", use_selection=True, object_types={"ARMATURE", "MESH"},
                             axis_forward="Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
                             add_leaf_bones=False, use_armature_deform_only=True, mesh_smooth_type="FACE",
                             bake_anim=True, bake_anim_use_all_actions=True, bake_anim_use_nla_strips=False,
                             bake_anim_force_startend_keying=True, path_mode="COPY", embed_textures=True)
    for act in [a for a in bpy.data.actions if not a.name.startswith(NAME + "_")]:
        bpy.data.actions.remove(act)
    # one clip per FBX, armature only, for Roblox's Animation Editor (Import > From FBX Animation: one take)
    arm = bpy.data.objects[NAME + "_Rig"]
    for act in [a for a in bpy.data.actions if a.name.startswith(NAME + "_")]:
        arm.animation_data.action = act
        select_premium()
        bpy.ops.export_scene.fbx(filepath=ROOT + "Animations/%s.fbx" % act.name, use_selection=True,
                                 object_types={"ARMATURE"}, axis_forward="Z", axis_up="Y",
                                 apply_scale_options="FBX_SCALE_ALL", add_leaf_bones=False,
                                 use_armature_deform_only=True, bake_anim=True, bake_anim_use_all_actions=False,
                                 bake_anim_use_nla_strips=False, bake_anim_force_startend_keying=True,
                                 path_mode="STRIP")
    arm.animation_data.action = None
    select_premium()
    bpy.ops.export_scene.gltf(filepath=ROOT + NAME + ".glb", export_format="GLB", use_selection=True,
                              export_animations=True, export_animation_mode="ACTIONS", export_skins=True,
                              export_yup=True, export_apply=False)
    # Studio preview data: per mesh, Roblox-space vertices, triangles and per-triangle colour
    data = []
    for o in premium_objects():
        if o.type != "MESH":
            continue
        me = o.data
        me.calc_loop_triangles()
        cl = me.color_attributes.get("Col")
        V = [list(map(lambda x: round(x, 4), rbx(v.co))) for v in me.vertices]
        T, F = [], []
        for t in me.loop_triangles:
            T.append(list(t.vertices))
            c = cl.data[t.loops[0]].color if cl else (1, 1, 1, 1)
            F.append("%02X%02X%02X" % tuple(int(round(max(0, c[i]) ** (1 / 2.2) * 255)) for i in range(3)))
        kind = o.name.rsplit("_", 1)[1]
        data.append(dict(name=o.name, joint=o.vertex_groups[0].name, kind=kind, v=V, t=T, c=F))
    json.dump(dict(name=NAME, meshes=data), open(ROOT + "RobloxPreview_%s.json" % NAME, "w"))
    print("exported", NAME, ".blend .fbx .glb, Studio JSON with", len(data), "meshes")


# ---- validate: re-import both exports and compare -------------------------------------------------------------
def bounds(obs):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in obs:
        if o.type != "MESH":
            continue
        dg = bpy.context.evaluated_depsgraph_get()
        oe = o.evaluated_get(dg)
        for v in oe.to_mesh().vertices:
            w = oe.matrix_world @ v.co
            lo, hi = Vector(map(min, lo, w)), Vector(map(max, hi, w))
        oe.to_mesh_clear()
    return lo, hi


def validate():
    src = [o for o in premium_objects()]
    lo, hi = bounds(src)
    ref = dict(meshes=sum(o.type == "MESH" for o in src), tris=sum(tris_of(o.data) for o in src if o.type == "MESH"),
               size=[round(x, 2) for x in (hi - lo)])
    res = {"source": ref}
    kinds = ("objects", "meshes", "materials", "actions", "armatures", "images")
    for fmt in ("fbx", "glb"):
        before = {k: set(getattr(bpy.data, k)) for k in kinds}
        tmpc = bpy.data.collections.new("_validate")
        bpy.context.scene.collection.children.link(tmpc)
        lc = bpy.context.view_layer.layer_collection.children[tmpc.name]
        bpy.context.view_layer.active_layer_collection = lc
        if fmt == "fbx":
            bpy.ops.import_scene.fbx(filepath=ROOT + NAME + ".fbx", axis_forward="Z", axis_up="Y")
        else:
            bpy.ops.import_scene.gltf(filepath=ROOT + NAME + ".glb")
        new = {k: set(getattr(bpy.data, k)) - before[k] for k in kinds}
        # count the skinned meshes only: the glTF importer adds an icosphere for bone display
        obs = [o for o in new["objects"] if o.type != "MESH" or any(m.type == "ARMATURE" for m in o.modifiers)]
        l2, h2 = bounds(obs)
        arms = [o for o in obs if o.type == "ARMATURE"]
        r = dict(meshes=sum(o.type == "MESH" for o in obs),
                 tris=sum(tris_of(o.data) for o in obs if o.type == "MESH"),
                 size=[round(x, 2) for x in (h2 - l2)],
                 bones=len(arms[0].data.bones) if arms else 0,
                 actions=sorted(a.name for a in new["actions"]),
                 materials=len(new["materials"]), images=len(new["images"]),
                 skinned=sum(1 for o in obs if o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)))
        r["size_match"] = all(abs(a - b) < 0.05 * max(1, b) for a, b in zip(r["size"], ref["size"]))
        res[fmt] = r
        for k in kinds:
            coll = getattr(bpy.data, k)
            for idb in new[k]:
                try:
                    coll.remove(idb)
                except Exception:
                    pass
        bpy.data.collections.remove(tmpc)
    json.dump(res, open(ROOT + "validation.json", "w"), indent=1)
    print(json.dumps(res))


# ---- previews ---------------------------------------------------------------------------------------------------------
def preview():
    stage.setup_stage("5DAE4A")
    for c in bpy.context.scene.collection.children:
        c.hide_render = c.name not in (COLL, "Stage")
    obs = premium_objects()
    lo, hi = bounds(obs)
    ctr = (lo + hi) / 2
    R = max(hi - lo)
    tgt = rbx(ctr)
    views = {"hero34": (-0.62, 0.32, -0.72), "front": (0, 0.12, -1), "side": (1, 0.1, 0), "rear": (0.15, 0.25, 1),
             "gameplay": (-0.42, 0.62, -0.85)}
    arm = bpy.data.objects[NAME + "_Rig"]
    arm.animation_data.action = None
    shots = []
    for v, d in views.items():
        dd = Vector(d).normalized()
        eye = tgt + dd * R * (3.4 if v == "gameplay" else 1.7)
        p = ROOT + "Previews/%s_%s.png" % (NAME, v)
        stage.shoot(p, tuple(eye), tuple(tgt), res=(900, 900) if v != "gameplay" else (1280, 720), lens=50)
        shots.append(p)
    stage.sheet(shots[:4], 4, ROOT + "Previews/%s_turnaround.png" % NAME)
    # animation strips: four frames per action, hero angle
    sc = bpy.context.scene
    for act in [a for a in bpy.data.actions if a.name.startswith(NAME + "_")]:
        arm.animation_data.action = act
        fr = int(act.frame_range[1])
        frames = [0, fr // 4, fr // 2, 3 * fr // 4] if not act.name.endswith("Special") else [0, 12, 26, 44]
        ps = []
        for f in frames:
            sc.frame_set(f)
            p = ROOT + "Previews/_%s_f%02d.png" % (act.name, f)
            dd = Vector(views["hero34"]).normalized()
            stage.shoot(p, tuple(tgt + dd * R * 1.9), tuple(tgt), res=(480, 480), lens=50)
            ps.append(p)
        stage.sheet(ps, 4, ROOT + "Animations/%s_strip.png" % act.name)
        for p in ps:
            os.remove(p)
    arm.animation_data.action = None
    sc.frame_set(0)
    for c in bpy.context.scene.collection.children:
        c.hide_render = False
    print("previews", ROOT + "Previews/")


for step in STEPS:
    {"build": build, "anim": animate, "export": export, "validate": validate, "preview": preview}[step]()
