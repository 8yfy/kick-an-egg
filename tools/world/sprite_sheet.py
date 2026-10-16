"""Preview: all wfx_*.png sprites on a dark and a light background in one sheet (tools/world/out/sprites.png)."""
import os, sys, struct, zlib
import numpy as np
src, out = sys.argv[1], sys.argv[2]

def load(path):
    data = open(path, 'rb').read()
    pos, idat, w, h = 8, b'', 0, 0
    while pos < len(data):
        n = struct.unpack('>I', data[pos:pos+4])[0]; t = data[pos+4:pos+8]; d = data[pos+8:pos+8+n]
        if t == b'IHDR': w, h = struct.unpack('>II', d[:8])
        if t == b'IDAT': idat += d
        pos += 12 + n
    raw = zlib.decompress(idat); stride = w * 4 + 1
    rows = [np.frombuffer(raw[y*stride+1:(y+1)*stride], np.uint8) for y in range(h)]
    return np.array(rows).reshape(h, w, 4).astype(np.float32) / 255

files = sorted(f for f in os.listdir(src) if f.startswith('wfx_'))
tiles = []
for f in files:
    img = load(os.path.join(src, f))
    a = img[..., 3:4]
    dark = img[..., :3] * a + np.array([0.12, 0.13, 0.18]) * (1 - a)
    light = img[..., :3] * a * np.array([1.0, 0.55, 0.3]) + np.array([0.55, 0.75, 0.95]) * (1 - a)
    tiles.append(np.concatenate([dark, light], axis=0))
cols = 10
rows_ = []
for i in range(0, len(tiles), cols):
    row = tiles[i:i+cols]
    while len(row) < cols: row.append(np.zeros_like(tiles[0]))
    rows_.append(np.concatenate(row, axis=1))
sheet = np.concatenate(rows_, axis=0)
img = (np.clip(sheet, 0, 1) * 255).astype(np.uint8)
h, w = img.shape[:2]
raw = b''.join(b'\x00' + img[y].tobytes() for y in range(h))
def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xFFFFFFFF)
open(out, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))
print(files)
