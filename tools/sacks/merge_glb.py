# Merges the 20 original Kick Sack GLBs into ONE importable GLB, losslessly, without re-exporting anything:
# the glTF JSON and binary chunks are concatenated with their indices offset, so every mesh, accessor byte,
# material value (incl. KHR_materials_* extensions) and node name/transform stays exactly as in the originals.
# Each sack's original scene roots go under a new group node Sack_01 .. Sack_20 with an IDENTITY transform: every
# sack keeps its own origin/pivot (no offsets; all 20 sit at the origin, as in their source files).
# Then it validates the result against the originals (names, transforms, materials, accessor bytes).
#
#   <blender>/4.5/python/bin/python.exe -I tools/sacks/merge_glb.py assets/sacks/glb assets/sacks/KickSacks_ALL_20.glb
import glob, json, os, re, struct, sys

LISTS = ["nodes", "meshes", "materials", "accessors", "bufferViews"]


def read_glb(path):
    data = open(path, "rb").read()
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    assert magic == b"glTF" and version == 2, f"{path}: not a glTF 2 binary"
    off, js, binary = 12, None, b""
    while off < length:
        clen, ctype = struct.unpack_from("<I4s", data, off)
        off += 8
        chunk = data[off : off + clen]
        off += clen
        if ctype == b"JSON":
            js = json.loads(chunk.decode("utf-8"))
        elif ctype == b"BIN\x00":
            binary = chunk
    for unsupported in ("skins", "animations", "cameras", "textures", "images", "samplers"):
        assert not js.get(unsupported), f"{path}: {unsupported} not handled by this merger"
    assert len(js.get("buffers", [])) == 1, f"{path}: expected one buffer"
    return js, binary


def write_glb(path, js, binary):
    text = json.dumps(js, separators=(",", ":")).encode("utf-8")
    text += b" " * (-len(text) % 4)
    binary = bytes(binary) + b"\x00" * (-len(binary) % 4)
    total = 12 + 8 + len(text) + 8 + len(binary)
    with open(path, "wb") as fh:
        fh.write(struct.pack("<4sII", b"glTF", 2, total))
        fh.write(struct.pack("<I4s", len(text), b"JSON") + text)
        fh.write(struct.pack("<I4s", len(binary), b"BIN\x00") + binary)


def tier_of(path):
    return int(re.match(r"kick-sack-(\d\d)-", os.path.basename(path)).group(1))


def merge(paths, out_path):
    out = {
        "asset": {"version": "2.0", "generator": "Kick The Egg tools/sacks/merge_glb.py (lossless merge of 20 GLBs)"},
        "scene": 0,
        "scenes": [{"name": "KickSacks_ALL_20", "nodes": []}],
        "nodes": [], "meshes": [], "materials": [], "accessors": [], "bufferViews": [],
        "buffers": [{"byteLength": 0}],
    }
    ext_used = set()
    binary = bytearray()
    for path in paths:
        js, b = read_glb(path)
        binary += b"\x00" * (-len(binary) % 4)  # keep every source buffer 4-byte aligned
        base = len(binary)
        binary += b
        o = {k: len(out[k]) for k in LISTS}
        for bv in js.get("bufferViews", []):
            bv = dict(bv)
            bv["buffer"] = 0
            bv["byteOffset"] = bv.get("byteOffset", 0) + base
            out["bufferViews"].append(bv)
        for acc in js.get("accessors", []):
            acc = json.loads(json.dumps(acc))
            if "bufferView" in acc:
                acc["bufferView"] += o["bufferViews"]
            sparse = acc.get("sparse")
            if sparse:
                sparse["indices"]["bufferView"] += o["bufferViews"]
                sparse["values"]["bufferView"] += o["bufferViews"]
            out["accessors"].append(acc)
        out["materials"] += [json.loads(json.dumps(m)) for m in js.get("materials", [])]
        for mesh in js.get("meshes", []):
            mesh = json.loads(json.dumps(mesh))
            for prim in mesh["primitives"]:
                prim["attributes"] = {k: v + o["accessors"] for k, v in prim["attributes"].items()}
                if "indices" in prim:
                    prim["indices"] += o["accessors"]
                if "material" in prim:
                    prim["material"] += o["materials"]
                for target in prim.get("targets", []):
                    for k in target:
                        target[k] += o["accessors"]
            out["meshes"].append(mesh)
        for node in js.get("nodes", []):
            node = json.loads(json.dumps(node))
            if "mesh" in node:
                node["mesh"] += o["meshes"]
            if "children" in node:
                node["children"] = [c + o["nodes"] for c in node["children"]]
            out["nodes"].append(node)
        roots = [r + o["nodes"] for r in js["scenes"][js.get("scene", 0)]["nodes"]]
        out["nodes"].append({"name": f"Sack_{tier_of(path):02d}", "children": roots})  # identity transform
        out["scenes"][0]["nodes"].append(len(out["nodes"]) - 1)
        ext_used |= set(js.get("extensionsUsed", []))
    if ext_used:
        out["extensionsUsed"] = sorted(ext_used)
    out["buffers"][0]["byteLength"] = len(binary)
    write_glb(out_path, out, binary)


def accessor_bytes(js, binary, index):
    acc = js["accessors"][index]
    bv = js["bufferViews"][acc["bufferView"]]
    comps = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[acc["type"]]
    size = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}[acc["componentType"]] * comps
    stride = bv.get("byteStride", size)
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return b"".join(binary[start + i * stride : start + i * stride + size] for i in range(acc["count"]))


def flatten(js, binary, roots):
    """(name, transform, mesh fingerprint) for every node under `roots`, depth first."""
    rows = []

    def visit(i):
        n = js["nodes"][i]
        prims = []
        if "mesh" in n:
            for p in js["meshes"][n["mesh"]]["primitives"]:
                mat = js["materials"][p["material"]] if "material" in p else None
                data = [accessor_bytes(js, binary, p["attributes"][k]) for k in sorted(p["attributes"])]
                if "indices" in p:
                    data.append(accessor_bytes(js, binary, p["indices"]))
                prims.append((json.dumps(mat, sort_keys=True), hash(b"".join(data))))
        rows.append((n.get("name"), n.get("matrix"), n.get("translation"), n.get("rotation"), n.get("scale"), tuple(prims)))
        for c in n.get("children", []):
            visit(c)

    for r in roots:
        visit(r)
    return rows


def validate(paths, out_path):
    mjs, mbin = read_glb(out_path)
    groups = {mjs["nodes"][i]["name"]: i for i in mjs["scenes"][0]["nodes"]}
    ok = True
    for path in paths:
        js, b = read_glb(path)
        name = f"Sack_{tier_of(path):02d}"
        group = mjs["nodes"][groups[name]]
        identity = not any(k in group for k in ("matrix", "translation", "rotation", "scale"))
        src = flatten(js, b, js["scenes"][js.get("scene", 0)]["nodes"])
        dst = flatten(mjs, mbin, group["children"])
        same = src == dst
        meshes = sum(1 for row in src if row[5])
        ok = ok and same and identity
        print(f"MERGE {name}: {len(src)} nodes ({meshes} with meshes), names/transforms/materials/bytes "
              f"{'identical' if same else 'DIFFERENT'}, pivot {'unchanged' if identity else 'MOVED'}")
    print(f"MERGE {'VALID' if ok else 'INVALID'}: {out_path} ({os.path.getsize(out_path) // 1024} KB, {len(groups)} sacks)")
    return ok


if __name__ == "__main__":
    src_dir, out_file = sys.argv[1], sys.argv[2]
    files = sorted(glob.glob(os.path.join(src_dir, "kick-sack-*.glb")), key=tier_of)
    assert len(files) == 20, f"expected 20 GLBs in {src_dir}, found {len(files)}"
    merge(files, out_file)
    sys.exit(0 if validate(files, out_file) else 1)
