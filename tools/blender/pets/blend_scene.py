# Background step of premium.py: append the PREMIUM_<Name> collection (and its actions) from the library file the
# pipeline wrote into a clean scene, set up a preview camera, light and frame range, and save <Name>.blend.
#   blender -b --factory-startup --python blend_scene.py -- <root dir> <Name>
import math
import os
import sys

import bpy

root, name = sys.argv[sys.argv.index("--") + 1:][:2]
lib = os.path.join(root, "_%s_lib.blend" % name)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0  # no .blend1 backups next to the deliverable
sc = bpy.context.scene
sc.name = name
with bpy.data.libraries.load(lib, link=False) as (src, dst):
    dst.collections = [c for c in src.collections if c == "PREMIUM_" + name]
    dst.actions = [a for a in src.actions if a.startswith(name + "_")]
for c in dst.collections:
    sc.collection.children.link(c)
for a in dst.actions:
    a.use_fake_user = True
sc.render.fps = 30
sc.frame_start, sc.frame_end = 0, 72
sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
sun.data.energy = 4
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
sc.collection.objects.link(sun)
cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
sc.collection.objects.link(cam)
sc.camera = cam
cam.location = (-14, 16, 8)  # front three-quarter (the pet faces Blender +Y)
cam.rotation_euler = (math.radians(72), 0, math.radians(-138))
world = bpy.data.worlds.new("World")
sc.world = world
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.42, 0.66, 0.95, 1)
bpy.ops.file.make_paths_relative()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(root, name + ".blend"))
os.remove(lib)
print("saved", os.path.join(root, name + ".blend"), "collections", len(dst.collections), "actions", len(dst.actions))
