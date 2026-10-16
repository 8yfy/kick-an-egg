"""Pairs the mesh ids Studio returned (ids only, in the order of the sorted "Asset__Role" part names of an inserted
kit) with the names from the kit's Blender manifest, and writes tools/world/ids/<Kit>.meshes.txt.
  python tools/world/pair_ids.py <Kit> <file with "count|id;id;...">
Refuses when the counts differ (an asset failed to import)."""
import json
import os
import sys

kit, src = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
man = json.load(open(os.path.join(here, "out", f"{kit}.manifest.json"), encoding="utf-8"))
names = sorted(f"{a}__{r}" for a, spec in man.items() for r in spec["parts"])
text = open(src, encoding="utf-8").read().strip()
count, ids = text.split("|", 1)
ids = [i for i in ids.split(";") if i]
if int(count) != len(names) or len(ids) != len(names):
    sys.exit(f"count mismatch: studio {count}/{len(ids)} vs manifest {len(names)}")
out = os.path.join(here, "ids", f"{kit}.meshes.txt")
open(out, "w", encoding="utf-8").write(";".join(f"{n}={i}" for n, i in zip(names, ids)) + "\n")
print(f"{kit}: {len(names)} mesh ids -> {out}")
