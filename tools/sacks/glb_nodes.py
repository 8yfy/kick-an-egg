# Lists every mesh node of the 20 original Kick Sack GLBs with its world-space bounding-box centre and size
# (metres, glTF frame), as JSON for tools/sacks/fix-import-names.luau, which uses it to restore the original
# node names on parts that Studio's 3D importer renamed (it de-duplicates names across one import).
#
#   <blender>/4.5/python/bin/python.exe -I tools/sacks/glb_nodes.py assets/sacks/glb out.json
import glob, json, math, os, re, struct, sys


def read_glb(path):
    data = open(path, "rb").read()
    off, js = 12, None
    while off < len(data):
        clen, ctype = struct.unpack_from("<I4s", data, off)
        off += 8
        if ctype == b"JSON":
            js = json.loads(data[off : off + clen])
        off += clen
    return js


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def trs(node):
    if "matrix" in node:
        m = node["matrix"]  # column-major
        return [[m[c * 4 + r] for c in range(4)] for r in range(4)]
    tx, ty, tz = node.get("translation", [0, 0, 0])
    qx, qy, qz, qw = node.get("rotation", [0, 0, 0, 1])
    sx, sy, sz = node.get("scale", [1, 1, 1])
    r = [
        [1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy - qz * qw), 2 * (qx * qz + qy * qw)],
        [2 * (qx * qy + qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz - qx * qw)],
        [2 * (qx * qz - qy * qw), 2 * (qy * qz + qx * qw), 1 - 2 * (qx * qx + qy * qy)],
    ]
    return [
        [r[0][0] * sx, r[0][1] * sy, r[0][2] * sz, tx],
        [r[1][0] * sx, r[1][1] * sy, r[1][2] * sz, ty],
        [r[2][0] * sx, r[2][1] * sy, r[2][2] * sz, tz],
        [0, 0, 0, 1],
    ]


def apply(m, p):
    return [m[i][0] * p[0] + m[i][1] * p[1] + m[i][2] * p[2] + m[i][3] for i in range(3)]


out = {}
for path in sorted(glob.glob(os.path.join(sys.argv[1], "kick-sack-*.glb"))):
    tier = int(re.search(r"kick-sack-(\d\d)-", os.path.basename(path)).group(1))
    js = read_glb(path)
    rows = []

    def visit(i, parent):
        node = js["nodes"][i]
        world = matmul(parent, trs(node))
        if "mesh" in node:
            lo, hi = [math.inf] * 3, [-math.inf] * 3
            for prim in js["meshes"][node["mesh"]]["primitives"]:
                acc = js["accessors"][prim["attributes"]["POSITION"]]
                for x in (acc["min"][0], acc["max"][0]):
                    for y in (acc["min"][1], acc["max"][1]):
                        for z in (acc["min"][2], acc["max"][2]):
                            w = apply(world, [x, y, z])
                            lo = [min(a, b) for a, b in zip(lo, w)]
                            hi = [max(a, b) for a, b in zip(hi, w)]
            rows.append({
                "name": node.get("name", ""),
                "center": [(a + b) / 2 for a, b in zip(lo, hi)],
                "size": [b - a for a, b in zip(lo, hi)],
            })
        for c in node.get("children", []):
            visit(c, world)

    identity = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    for r in js["scenes"][js.get("scene", 0)]["nodes"]:
        visit(r, identity)
    out[str(tier)] = rows
    print(f"GLBNODES tier {tier}: {len(rows)} mesh nodes")
with open(sys.argv[2], "w", newline="\n") as fh:
    json.dump(out, fh)
