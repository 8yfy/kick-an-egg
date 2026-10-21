# DEV ONLY. Makes evidence small enough for the repo, in headless Blender (its FFmpeg / OpenImageIO):
#   blender -b --factory-startup --python tools/anim/shrink.py -- <in> <out> [--width 960]
# .mp4 in -> .mp4 out at that width (same frame rate, lower bitrate); .png in -> .jpg out (quality 82).
import argparse
import os
import sys

import bpy

ap = argparse.ArgumentParser()
ap.add_argument("src")
ap.add_argument("out")
ap.add_argument("--width", type=int, default=960)
args = ap.parse_args(sys.argv[sys.argv.index("--") + 1 :])

if args.src.lower().endswith(".png"):
    import OpenImageIO as oiio

    buf = oiio.ImageBuf(args.src)
    spec = buf.spec()
    w = min(args.width, spec.width)
    h = round(spec.height * w / spec.width)
    small = oiio.ImageBufAlgo.resize(buf, roi=oiio.ROI(0, w, 0, h, 0, 1, 0, 3))
    small.specmod().attribute("Compression", "jpeg:82")
    small.set_write_format(oiio.UINT8)
    small.write(args.out)
    print("jpg", args.out, os.path.getsize(args.out))
else:
    scene = bpy.context.scene
    se = scene.sequence_editor_create()
    strips = se.strips if hasattr(se, "strips") else se.sequences
    clip = strips.new_movie(name="m", filepath=args.src, channel=1, frame_start=1)
    sw, sh = bpy.data.movieclips.load(args.src).size  # (strip elements report 0 x 0 in background mode)
    scene.render.fps = int(round(clip.fps)) if clip.fps else 30
    w = min(args.width, sw)
    h = round(sh * w / sw)
    scene.render.resolution_x, scene.render.resolution_y = w - w % 2, h - h % 2
    scene.render.resolution_percentage = 100
    clip.transform.scale_x = clip.transform.scale_y = w / sw
    scene.frame_start, scene.frame_end = 1, clip.frame_final_duration
    if hasattr(scene.render.image_settings, "media_type"):
        scene.render.image_settings.media_type = "VIDEO"
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "MEDIUM"
    scene.render.filepath = args.out
    bpy.ops.render.render(animation=True)
    print("mp4", args.out, os.path.getsize(args.out))
