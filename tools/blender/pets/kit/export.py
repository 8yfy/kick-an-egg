# Bake built collections into BlockBuilder block tables (Luau): one pair file (Premium/<Key>.luau) or one zone file.
import math

import bpy
from mathutils import Vector

from .rbx import C3, C3T

def _num(v):
    v = round(v, 3)
    if abs(v) < 0.0005:
        v = 0.0
    s = ("%.3f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def _vec(vals):
    return "{ " + ", ".join(_num(v) for v in vals) + " }"


def rbx_of(ob, offset):
    loc, q, sc = ob.matrix_world.decompose()
    Rr = C3T @ q.to_matrix() @ C3
    pos = C3T @ loc - Vector(offset)
    size = (sc.x, sc.z, sc.y)
    e = Rr.to_euler("ZYX")  # Euler 'ZYX' == Rx @ Ry @ Rz == CFrame.Angles(x, y, z)
    rot = tuple(math.degrees(a) for a in (e.x, e.y, e.z))
    return pos, rot, size


def part_line(ob, offset, names):
    pos, rot, size = rbx_of(ob, offset)
    hx = ob["rbx_color"]
    col = names.get(hx, "rgb(%d, %d, %d)" % tuple(int(hx[i : i + 2], 16) for i in (0, 2, 4)))
    opts = ['joint = "%s"' % ob["rbx_joint"]]
    if any(abs(a) > 0.05 for a in rot):
        opts.append("rot = " + _vec(rot))
    if ob["rbx_shape"] != "Block":
        opts.append('shape = "%s"' % ob["rbx_shape"])
    if ob["rbx_material"] != "SmoothPlastic":
        opts.append('material = "%s"' % ob["rbx_material"])
    if ob["rbx_transparency"] > 0:
        opts.append("transparency = " + _num(ob["rbx_transparency"]))
    if ob["rbx_studs"] == 0:
        opts.append("studs = false")
    return 'P("%s", %s, %s, %s, { %s }),' % (ob["rbx_name"], _vec(size), _vec(pos), col, ", ".join(opts))


def export_luau(path, header, palette_names, pal=None, egg_coll="FS_Egg", pet_coll="FS_Pet"):
    names = {v.upper(): k for k, v in palette_names.items()}
    out = [header.rstrip("\n"), ""]
    out.append("local P, rgb = S.part, Color3.fromRGB")
    for k, v in palette_names.items():
        out.append("local %s = rgb(%d, %d, %d) -- #%s" % (k, *(int(v[i : i + 2], 16) for i in (0, 2, 4)), v.upper()))
    out.append("")
    counts = {}
    for kind, coll in (("egg", egg_coll), ("pet", pet_coll)):
        c = bpy.data.collections[coll]
        offset = tuple(c["rbx_offset"])
        obs = sorted(c.objects, key=lambda o: o["rbx_order"])
        counts[kind] = len(obs)
        out.append("local %s: Builder.Spec = {" % kind)
        out.append("\tparts = {")
        for ob in obs:
            out.append("\t\t" + part_line(ob, offset, names))
        out.append("\t},")
        out.append("}")
        out.append("")
    out.append("return { egg = egg, pet = pet }")
    with open(path, "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(out) + "\n")
    return counts


def export_zone(path, header, pairs):
    """One Luau module for a zone: `Baked.<Key> = { egg = Spec, pet = Spec }` per pair, each in its own `do`
    block with its palette constants. pairs = [dict(key, title, palette (name -> hex), egg, pet)]."""
    out = [header.rstrip("\n"), ""]
    out.append("local P, rgb = S.part, Color3.fromRGB")
    out.append("")
    out.append("export type Pair = { egg: Builder.Spec, pet: Builder.Spec }")
    out.append("local Baked: { [string]: Pair } = {}")
    out.append("")
    counts = {}
    for pr in pairs:
        names = {}
        for k, v in pr["palette"].items():
            names.setdefault(v.upper(), k)
        used = set()
        lines = {}
        for kind in ("egg", "pet"):
            c = bpy.data.collections[pr[kind]]
            offset = tuple(c["rbx_offset"])
            obs = sorted(c.objects, key=lambda o: o["rbx_order"])
            counts[pr["key"] + "." + kind] = len(obs)
            lines[kind] = [part_line(ob, offset, names) for ob in obs]
            used |= {ob["rbx_color"] for ob in obs}
        for t in pr["title"]:
            out.append("-- " + t)
        out.append("do")
        for hx, k in names.items():
            if hx in used:
                out.append("\tlocal %s = rgb(%d, %d, %d) -- #%s" % (k, *(int(hx[i : i + 2], 16) for i in (0, 2, 4)), hx))
        out.append("\tBaked.%s = {" % pr["key"])
        for kind in ("egg", "pet"):
            out.append("\t\t%s = {" % kind)
            out.append("\t\t\tparts = {")
            out += ["\t\t\t\t" + ln for ln in lines[kind]]
            out.append("\t\t\t},")
            out.append("\t\t},")
        out.append("\t}")
        out.append("end")
        out.append("")
    out.append("return Baked")
    with open(path, "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(out) + "\n")
    return counts
