# Merges the 20 original Kick Sack GLBs into ONE GLB (assets/sacks/kick-sacks-all.glb) so Studio needs a single
# File > Import 3D instead of 20. Each sack's nodes are grouped under an empty named Sack_01 .. Sack_20, all at
# the origin, geometry and materials untouched. Blender suffixes repeated node names (body.001 ...); the rename
# helper and Builders/SackGeometry strip those suffixes again.
#
#   blender -b --factory-startup --python tools/sacks/combine.py -- assets/sacks/glb assets/sacks/kick-sacks-all.glb
import glob, os, sys

import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
src, out = args[0], args[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
expected = {}
for path in sorted(glob.glob(os.path.join(src, "kick-sack-*.glb"))):
    tier = int(os.path.basename(path).split("-")[2])
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    group = bpy.data.objects.new(f"Sack_{tier:02d}", None)
    bpy.context.scene.collection.objects.link(group)
    for o in new:
        if o.parent is None:
            o.parent = group
    expected[group.name] = sum(1 for o in new if o.type == "MESH")

bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")

# verify: re-import the merged file and count the mesh nodes under every Sack_NN
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=out)
ok = True
for name, want in sorted(expected.items()):
    group = bpy.data.objects.get(name)
    got = sum(1 for o in group.children_recursive if o.type == "MESH") if group else 0
    ok = ok and got == want
    print(f"COMBINE {name}: {got}/{want} mesh nodes")
print(f"COMBINE {'OK' if ok else 'MISMATCH'} -> {out} ({os.path.getsize(out) // 1024} KB)")
