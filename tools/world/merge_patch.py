"""Merges a kit patch (build_kit.py --only ...) into the kit: out/<Kit>_patch.manifest.json -> out/<Kit>.manifest.json
and ids/<Kit>_patch.meshes.txt -> ids/<Kit>.meshes.txt (entries of the patched assets are replaced).
  python tools/world/merge_patch.py <Kit>"""
import json
import os
import sys

kit = sys.argv[1]
here = os.path.dirname(os.path.abspath(__file__))
man_p = os.path.join(here, "out", f"{kit}.manifest.json")
patch_p = os.path.join(here, "out", f"{kit}_patch.manifest.json")
man = json.load(open(man_p, encoding="utf-8"))
patch = json.load(open(patch_p, encoding="utf-8"))
man.update(patch)
json.dump(man, open(man_p, "w", encoding="utf-8"), indent=1)


def read_ids(path):
    out = {}
    for pair in open(path, encoding="utf-8").read().replace("\n", ";").split(";"):
        if "=" in pair:
            k, v = pair.strip().split("=", 1)
            out[k] = v
    return out


ids_p = os.path.join(here, "ids", f"{kit}.meshes.txt")
ids = read_ids(ids_p)
new = read_ids(os.path.join(here, "ids", f"{kit}_patch.meshes.txt"))
for asset in patch:
    for k in [k for k in ids if k.startswith(asset + "__")]:
        del ids[k]
ids.update(new)
open(ids_p, "w", encoding="utf-8").write(";".join(f"{k}={v}" for k, v in sorted(ids.items())) + "\n")
print(f"merged {len(patch)} assets, {len(new)} mesh ids into {kit}")
