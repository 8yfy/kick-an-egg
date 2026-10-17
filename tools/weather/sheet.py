"""Review sheet: every PNG in the given folders on a dark and a light background, each scaled to a 128 px tile.
  "<Blender>/5.2/python/bin/python.exe" -I tools/weather/sheet.py <out.png> <folder> [<folder> ...]"""

import os
import struct
import sys
import zlib

import numpy as np


def load(path):
    """RGBA float image from an 8-bit RGB / RGBA PNG (all five row filters)."""
    data = open(path, "rb").read()
    pos, idat, w, h, ctype = 8, b"", 0, 0, 6
    while pos < len(data):
        n = struct.unpack(">I", data[pos : pos + 4])[0]
        t, d = data[pos + 4 : pos + 8], data[pos + 8 : pos + 8 + n]
        if t == b"IHDR":
            w, h = struct.unpack(">II", d[:8])
            ctype = d[9]
        if t == b"IDAT":
            idat += d
        pos += 12 + n
    bpp = 4 if ctype == 6 else 3
    raw = zlib.decompress(idat)
    stride = w * bpp
    out = np.zeros((h, stride), np.uint8)
    prev = np.zeros(stride, np.int32)
    for y in range(h):
        f = raw[y * (stride + 1)]
        line = np.frombuffer(raw[y * (stride + 1) + 1 : (y + 1) * (stride + 1)], np.uint8).astype(np.int32)
        if f == 0:
            cur = line
        elif f == 2:
            cur = (line + prev) & 255
        else:
            cur = line.copy()
            for x in range(stride):
                a = cur[x - bpp] if x >= bpp else 0
                b = prev[x]
                if f == 1:
                    cur[x] = (cur[x] + a) & 255
                elif f == 3:
                    cur[x] = (cur[x] + ((a + b) >> 1)) & 255
                else:
                    c = prev[x - bpp] if x >= bpp else 0
                    pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                    pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                    cur[x] = (cur[x] + pr) & 255
        out[y] = cur
        prev = cur
    img = out.reshape(h, w, bpp).astype(np.float32) / 255
    if bpp == 3:
        img = np.concatenate([img, np.ones((h, w, 1), np.float32)], axis=2)
    return img


def tile(img, t=128):
    h, w = img.shape[:2]
    ys = (np.arange(t) * h / t).astype(int)
    xs = (np.arange(t) * w / t).astype(int)
    return img[ys][:, xs]


def save(path, rgb):
    img = (np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w = img.shape[:2]
    raw = b"".join(b"\x00" + img[y].tobytes() for y in range(h))

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b"")
    open(path, "wb").write(png)


if __name__ == "__main__":
    out, folders = sys.argv[1], sys.argv[2:]
    files = [os.path.join(f, n) for f in folders for n in sorted(os.listdir(f)) if n.endswith(".png")]
    dark, light = np.array([0.12, 0.13, 0.18]), np.array([0.55, 0.75, 0.95])
    cols = 9
    rows = []
    for i in range(0, len(files), cols):
        chunk = [tile(load(p)) for p in files[i : i + cols]]
        chunk += [np.zeros((128, 128, 4), np.float32)] * (cols - len(chunk))
        for bg in (dark, light):
            rows.append(np.concatenate([t[..., :3] * t[..., 3:] + bg * (1 - t[..., 3:]) for t in chunk], axis=1))
    save(out, np.concatenate(rows, axis=0))
    print("\n".join(os.path.basename(p) for p in files))
