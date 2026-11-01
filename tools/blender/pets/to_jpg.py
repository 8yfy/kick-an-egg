# Converts the premium pets' PNG previews and animation strips to JPEG (quality 88) so the repo stays small.
#   blender -b --factory-startup --python to_jpg.py -- <KickAnEgg_PremiumPets dir>
import glob, os, sys
import bpy
root = sys.argv[sys.argv.index("--") + 1]
sc = bpy.context.scene
sc.render.image_settings.file_format = "JPEG"
sc.render.image_settings.quality = 88
n = 0
for pat in ("*/Previews/*.png", "*/Animations/*_strip.png"):
    for p in glob.glob(os.path.join(root, pat)):
        im = bpy.data.images.load(p)
        im.save_render(p[:-4] + ".jpg", scene=sc)
        bpy.data.images.remove(im)
        os.remove(p)
        n += 1
print("converted", n)
