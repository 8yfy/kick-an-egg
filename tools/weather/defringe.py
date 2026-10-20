"""Alpha-only defringe for the weather icons (extracted from a dark artwork sheet, so their soft edges carry a grey
fringe that shows on bright backgrounds). RGB is never changed: only the alpha of DARK, semi-transparent pixels is
lowered; opaque pixels and bright glow keep their alpha. Originals stay untouched.
  "<Blender>/5.2/python/bin/python.exe" -I tools/weather/defringe.py <out_dir> <png> [<png> ...]"""

import os
import struct
import sys
import zlib

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet import load  # noqa: E402  (PNG reader with all row filters)

OPAQUE = 0.96  # pixels at or above this alpha are the icon body: never touched
DARK, LIGHT = 0.16, 0.42  # luminance ramp: fringe at or below DARK fades fully, glow at or above LIGHT stays


def save(path, rgba):
    img = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w = img.shape[:2]
    raw = b"".join(b"\x00" + img[y].tobytes() for y in range(h))

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def defringe(img):
    rgb, a = img[..., :3], img[..., 3]
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722], np.float32)
    t = np.clip((lum - DARK) / (LIGHT - DARK), 0, 1)
    keep = t * t * (3 - 2 * t)
    soft = a < OPAQUE
    # the fainter a dark pixel already is, the more it is fringe: scale by keep, eased by its own alpha
    new_a = np.where(soft, a * (keep + (1 - keep) * (a / OPAQUE) ** 3), a)
    out = img.copy()
    out[..., 3] = new_a
    return out, float(np.mean(np.abs(new_a - a)[a > 0.01]))


if __name__ == "__main__":
    out_dir, files = sys.argv[1], sys.argv[2:]
    os.makedirs(out_dir, exist_ok=True)
    for f in files:
        img, change = defringe(load(f))
        save(os.path.join(out_dir, os.path.basename(f)), img)
        print(f"{os.path.basename(f)}: mean alpha change on visible pixels {change:.3f}")
