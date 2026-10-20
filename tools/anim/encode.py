# DEV ONLY. Turns a tools/anim/capture.ps1 frame folder into evidence, using Blender's own FFmpeg (no ffmpeg on PATH):
#   blender -b --factory-startup --python tools/anim/encode.py -- <frames dir> <out.mp4>
#       [--sheet sheet.png] [--cols 6] [--every 2] [--from 0] [--to 99999] [--at ms,ms,...] [--no-mp4]
#       [--crop x,y,w,h | --crop auto]
# The game viewport is cut out of the Studio window (--crop auto finds the colourful area). The mp4 is 30 fps real
# time: each output frame shows the newest capture taken at or before its time (times.txt), so a slow capture never
# speeds the motion up. The contact sheet tiles every <every>-th capture between --from and --to ms, with the time
# of each tile in <sheet>.txt (Blender's OpenImageIO has no FreeType for drawing text).
import argparse
import os
import sys
import tempfile

import bpy
import numpy as np
import OpenImageIO as oiio

ap = argparse.ArgumentParser()
ap.add_argument("src")
ap.add_argument("out")
ap.add_argument("--sheet")
ap.add_argument("--cols", type=int, default=6)
ap.add_argument("--every", type=int, default=2)
ap.add_argument("--from", dest="t0", type=int, default=0)
ap.add_argument("--to", dest="t1", type=int, default=10**9)
ap.add_argument("--crop", default="auto")
ap.add_argument("--at", default="")  # sheet tiles = the captures nearest these times (ms), e.g. one per camera cut
ap.add_argument("--no-mp4", dest="mp4", action="store_false")
# sheet tiles = the middle capture of each of N still shots (a review tour: cuts found by the biggest image changes)
ap.add_argument("--segments", type=int, default=0)
# review tours open with a magenta flash: --tour HOLD_MS,COUNT picks the middle capture of each of COUNT
# HOLD_MS-long shots that follow the flash
ap.add_argument("--tour", default="")
args = ap.parse_args(sys.argv[sys.argv.index("--") + 1 :])
FPS = 30

files = sorted(f for f in os.listdir(args.src) if f.startswith("f_") and f.endswith(".png"))
times = [int(x) for x in open(os.path.join(args.src, "times.txt")).read().split()][: len(files)]


def pixels(path):
    buf = oiio.ImageBuf(path)
    spec = buf.spec()
    return np.array(buf.get_pixels(oiio.FLOAT)).reshape(spec.height, spec.width, -1)[:, :, :3]


def save(px, path):
    h, w = px.shape[:2]
    buf = oiio.ImageBuf(oiio.ImageSpec(w, h, 3, oiio.FLOAT))
    buf.set_pixels(oiio.ROI(0, w, 0, h, 0, 1, 0, 3), np.ascontiguousarray(px))
    buf.write(path)


# the viewport: the colourful rectangle inside the dark Studio chrome
if args.crop == "auto":
    px = pixels(os.path.join(args.src, files[len(files) // 2]))
    sat = px.max(axis=2) - px.min(axis=2)
    xs = np.where(sat.mean(axis=0) > 0.12)[0]
    ys = np.where(sat.mean(axis=1) > 0.12)[0]
    x, y, w, h = int(xs[0]), int(ys[0]), int(xs[-1] - xs[0] + 1), int(ys[-1] - ys[0] + 1)
else:
    x, y, w, h = (int(v) for v in args.crop.split(","))
w, h = w - w % 2, h - h % 2
print("crop", x, y, w, h)

tmp = tempfile.mkdtemp(prefix="kte_enc_")
for name in files:
    save(pixels(os.path.join(args.src, name))[y : y + h, x : x + w], os.path.join(tmp, name))

# one output frame every 1/30 s, holding the newest capture
seq = []
j = 0
t = times[0]
while t <= times[-1]:
    while j + 1 < len(times) and times[j + 1] <= t:
        j += 1
    seq.append(files[j])
    t += 1000 / FPS

scene = bpy.context.scene
if not args.mp4:
    seq = []
scene.render.fps = FPS
scene.render.resolution_x, scene.render.resolution_y = w, h
scene.render.resolution_percentage = 100
se = scene.sequence_editor_create()
strips = se.strips if hasattr(se, "strips") else se.sequences
for i, name in enumerate(seq):
    s = strips.new_image(name=f"f{i}", filepath=os.path.join(tmp, name), channel=1, frame_start=i + 1)
    s.frame_final_duration = 1
scene.frame_start, scene.frame_end = 1, max(len(seq), 1)
if hasattr(scene.render.image_settings, "media_type"):
    scene.render.image_settings.media_type = "VIDEO"  # Blender 5: video is a media type
scene.render.image_settings.file_format = "FFMPEG"
scene.render.ffmpeg.format = "MPEG4"
scene.render.ffmpeg.codec = "H264"
scene.render.ffmpeg.constant_rate_factor = "HIGH"
scene.render.filepath = args.out
if seq:
    bpy.ops.render.render(animation=True)
    print("mp4", args.out, len(seq), "frames")

if args.sheet:
    if args.tour:
        hold, count = (int(v) for v in args.tour.split(","))
        last = None
        for i, n in enumerate(files):
            px = pixels(os.path.join(tmp, n))[::8, ::8].reshape(-1, 3).mean(axis=0)
            if px[0] > 0.6 and px[1] < 0.35 and px[2] > 0.6:
                last = i
        start = times[last + 1] if last is not None and last + 1 < len(times) else times[0]
        want = [start + hold * (k + 0.5) for k in range(count)]
        picks = [files[min(range(len(times)), key=lambda i: abs(times[i] - w))] for w in want]
        print("tour start", start)
    elif args.segments > 1:
        small = [pixels(os.path.join(tmp, n))[::8, ::8] for n in files]
        diffs = [float(np.abs(small[i + 1] - small[i]).mean()) for i in range(len(small) - 1)]
        cuts = sorted(sorted(range(len(diffs)), key=lambda i: -diffs[i])[: args.segments - 1])
        bounds = [0] + [c + 1 for c in cuts] + [len(files)]
        picks = [files[(bounds[k] + bounds[k + 1] - 1) // 2] for k in range(len(bounds) - 1)]
    elif args.at:
        want = [int(x) for x in args.at.split(",")]
        picks = [files[min(range(len(times)), key=lambda i: abs(times[i] - w))] for w in want]
    else:
        picks = [n for n, tm in zip(files, times) if args.t0 <= tm <= args.t1][:: args.every]
    cols = args.cols
    rows = (len(picks) + cols - 1) // cols
    tw, th = w // 2, h // 2
    canvas = np.zeros((rows * th, cols * tw, 3), dtype=np.float32)
    for k, name in enumerate(picks):
        buf = oiio.ImageBuf(os.path.join(tmp, name))
        small = oiio.ImageBufAlgo.resize(buf, roi=oiio.ROI(0, tw, 0, th, 0, 1, 0, buf.spec().nchannels))
        r, c = divmod(k, cols)
        canvas[r * th : (r + 1) * th, c * tw : (c + 1) * tw] = np.array(small.get_pixels(oiio.FLOAT)).reshape(
            th, tw, -1
        )[:, :, :3]
    save(canvas, args.sheet)
    with open(os.path.splitext(args.sheet)[0] + ".txt", "w") as legend:
        for k, name in enumerate(picks):
            legend.write(f"tile {k + 1} (row {k // cols + 1}, col {k % cols + 1}): {times[files.index(name)]} ms\n")
    print("sheet", args.sheet, len(picks), "tiles")
