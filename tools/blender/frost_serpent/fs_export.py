# Bake the FS_Egg / FS_Pet collections into a BlockBuilder block table (Luau). Needs fs_lib.py first.
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


def export_luau(path, header, palette_names, pal):
    names = {v.upper(): k for k, v in palette_names.items()}
    out = [header.rstrip("\n"), ""]
    out.append("local P, rgb = S.part, Color3.fromRGB")
    for k, v in palette_names.items():
        out.append("local %s = rgb(%d, %d, %d) -- #%s" % (k, *(int(v[i : i + 2], 16) for i in (0, 2, 4)), v.upper()))
    out.append("")
    counts = {}
    for kind, coll in (("egg", "FS_Egg"), ("pet", "FS_Pet")):
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
