# Builds one kit: blender -b --python build_kit.py -- <KitName> [--preview] [--only Asset1,Asset2]
# Writes tools/world/blend/<Kit>.blend, tools/world/out/<Kit>.fbx, tools/world/out/<Kit>.manifest.json and
# (with --preview) tools/world/out/preview/<Kit>_<n>.png contact sheets (front / right / rear / 3-4).
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import kit  # noqa: E402
import kits  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
name = argv[0]
preview = "--preview" in argv
only = None
if "--only" in argv:
    only = set(argv[argv.index("--only") + 1].split(","))
root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
os.makedirs(os.path.join(root_dir, "blend"), exist_ok=True)
os.makedirs(os.path.join(root_dir, "out", "preview"), exist_ok=True)

kit.reset()
specs = kits.KITS[name]
roots = []
manifest = {}
for fn, asset_name, seed, params in specs:
    if only and asset_name not in only:
        continue
    a = fn(asset_name, seed, **params)
    root, objs = a.build()
    lo, hi = kit.bounds(root)
    parts = {}
    for o in objs:
        plo, phi = kit.bounds_obj(o)
        parts[o.name.split("__", 1)[1]] = {"min": [round(v, 4) for v in plo], "max": [round(v, 4) for v in phi]}
    manifest[asset_name] = {
        "roles": sorted(parts.keys()),
        "parts": parts,
        "min": [round(v, 3) for v in lo],
        "max": [round(v, 3) for v in hi],
        "tris": sum(len(o.data.polygons) for o in objs),
    }
    roots.append(root)
kit.save_blend(os.path.join(root_dir, "blend", f"{name}.blend" if not only else f"{name}_partial.blend"))
stem = name if not only else f"{name}_patch"  # a patch re-uploads only the listed assets (merge_patch.py)
kit.export_fbx(os.path.join(root_dir, "out", f"{stem}.fbx"), roots)
with open(os.path.join(root_dir, "out", f"{stem}.manifest.json"), "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=1)
if preview:
    per = 5
    for i in range(0, len(roots), per):
        kit.preview(roots[i : i + per], os.path.join(root_dir, "out", "preview", f"{name}_{i // per + 1}.png"), size=260)
tot = sum(m["tris"] for m in manifest.values())
print(f"KIT {name}: {len(manifest)} assets, {tot} faces")
for k, m in manifest.items():
    print(f"  {k}: {m['tris']} faces, size {[round(m['max'][j] - m['min'][j], 1) for j in range(3)]}")
