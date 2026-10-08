# spot_art.py (2026-10-06, Claude): the tutorial spotlight's soft cut-out, written as a PNG with plain Python (no Pillow on this PC).
# 256 x 256, opaque black outside, a transparent rounded hole with a feathered edge. 9-slice centre Rect(96, 96, 160, 160) is fully clear,
# so the hole stretches to any target size; the tutorial tints it with ImageColor3 / ImageTransparency to match its dim frames.
import os, struct, zlib, math
HERE = os.path.dirname(os.path.abspath(__file__))
S, M, R, F = 256, 96, 40, 30  # size, slice margin, hole corner radius, feather width
def alpha(x, y):
    # signed distance to the rounded rect [M-?]: the hole spans the whole slice centre and reaches into the margins by (M - F - 8)
    inset = 8 + F  # dark band at the very edge, then the feather, then clear
    x0, y0, x1, y1 = inset + R, inset + R, S - inset - R, S - inset - R
    dx = max(x0 - x, 0, x - x1); dy = max(y0 - y, 0, y - y1)
    d = math.hypot(dx, dy) - R  # <0 inside the hole
    t = min(1.0, max(0.0, (d + F) / F))  # 0 inside (clear) .. 1 at the outer edge (dark)
    return int(255 * (t * t * (3 - 2 * t)))
rows = b"".join(b"\x00" + b"".join(bytes((0, 0, 0, alpha(x + 0.5, y + 0.5))) for x in range(S)) for y in range(S))
def chunk(tag, data): return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", S, S, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b"")
open(os.path.join(HERE, "png", "tut_spot.png"), "wb").write(png)
print("DONE tut_spot", len(png))
