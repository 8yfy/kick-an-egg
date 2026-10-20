# Pipeline probe: one small low-poly tree (Trunk + Leaf + LeafDark roles) exported as FBX and GLB.
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import kit  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "out")
kit.reset()
a = kit.Asset("ProbeTree", seed=3)
kit.prism(a, "Trunk", (0, 0, 0), 6, 0.9, 0.6, 7, jitter=0.05)
kit.blob(a, "Leaf", (0, 0, 8), 3.6, scale=(1, 1, 0.8), subdiv=1, jitter=0.15)
kit.blob(a, "LeafDark", (1.6, 0.6, 6.4), 2.4, scale=(1, 1, 0.75), subdiv=1, jitter=0.15)
root, objs = a.build()
lo, hi = kit.bounds(root)
print("BOUNDS", tuple(round(x, 3) for x in lo), tuple(round(x, 3) for x in hi))
kit.export_fbx(os.path.join(OUT, "ProbeTree.fbx"), [root])
kit.export_glb(os.path.join(OUT, "ProbeTree.glb"), [root])
kit.save_blend(os.path.join(OUT, "ProbeTree.blend"))
print("DONE")
