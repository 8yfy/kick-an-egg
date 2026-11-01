# Turntable check renders of the Frost Serpent pet and egg (Blender EEVEE, sunny stage, grass ground) into
# tools/blender/frost_serpent/out/ (gitignored). Studs only show in Studio; final approval shots come from Studio.
#   python -I bmcp.py code fs_lib.py fs_scene.py fs_serpent.py fs_egg.py preview.py
import os

OUT = REPO + "/tools/blender/frost_serpent/out/"
os.makedirs(OUT, exist_ok=True)
for c in [c for c in bpy.data.collections if c.name.startswith("FS_")]:
    for ob in list(c.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    bpy.data.collections.remove(c)
setup_stage()
build_serpent("FS_Pet", (0, 0, 0))
build_egg("FS_Egg", (10, 0, 0))
shots = []
views = {"front34": (-10, 6.8, -12.5), "side": (16, 5, -0.5), "back34": (10.5, 7.5, 11), "front": (0, 5, -16)}
for v, eye in views.items():
    only(["FS_Pet"])
    p = OUT + "pet_%s.png" % v
    shoot(p, eye, (0, 4.2, 0), res=(760, 820), lens=45)
    shots.append(p)
for v, eye in views.items():
    only(["FS_Egg"])
    p = OUT + "egg_%s.png" % v
    shoot(p, (eye[0] * 0.62 + 10, eye[1] * 0.6, eye[2] * 0.62), (10, 2.6, 0), res=(760, 820), lens=45)
    shots.append(p)
sheet(shots, 4, OUT + "frost_serpent_sheet.png")
print("renders in", OUT)
