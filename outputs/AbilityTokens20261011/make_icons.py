# Draws the eight ability-token icons (256x256 PNG, transparent) with signed-distance shapes. Original artwork, no external assets.
# Run: python make_icons.py  -> icons/<Kind>.png and icons/contact_sheet.png
import numpy as np, zlib, struct, os, math
S = 256; SS = 3; N = S * SS
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, "icons")
os.makedirs(OUT, exist_ok=True)
y, x = np.mgrid[0:N, 0:N].astype(np.float32) / SS  # pixel coords in 0..256
NAVY = (28, 44, 78)
WHITE = (250, 253, 255)

# --- SDFs (negative inside) ---
def circle(cx, cy, r): return np.hypot(x - cx, y - cy) - r
def ring(cx, cy, r, w): return np.abs(np.hypot(x - cx, y - cy) - r) - w / 2
def capsule(ax, ay, bx, by, r):
    pax, pay, bax, bay = x - ax, y - ay, bx - ax, by - ay
    h = np.clip((pax * bax + pay * bay) / (bax * bax + bay * bay), 0, 1)
    return np.hypot(pax - bax * h, pay - bay * h) - r
def rbox(cx, cy, hw, hh, r, ang=0.0):
    c, s = math.cos(ang), math.sin(ang)
    px, py = (x - cx) * c + (y - cy) * s, -(x - cx) * s + (y - cy) * c
    qx, qy = np.abs(px) - hw + r, np.abs(py) - hh + r
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r
def poly(pts):
    d = np.full(x.shape, 1e9, np.float32); sgn = np.ones(x.shape, np.float32)
    n = len(pts)
    for i in range(n):
        ax, ay = pts[i]; bx, by = pts[(i + 1) % n]
        ex, ey = bx - ax, by - ay; wx, wy = x - ax, y - ay
        h = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        d = np.minimum(d, np.hypot(wx - ex * h, wy - ey * h))
        c1 = y >= ay; c2 = y < by; c3 = ex * wy > ey * wx
        flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        sgn = np.where(flip, -sgn, sgn)
    return sgn * d
def union(*ds):
    d = ds[0]
    for e in ds[1:]: d = np.minimum(d, e)
    return d
def sub(a, b): return np.maximum(a, -b)
def inter(a, b): return np.maximum(a, b)

def write_png(path, img):
    h, w, _ = img.shape
    raw = b"".join(b"\x00" + img[r].tobytes() for r in range(h))
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

class Canvas:
    def __init__(self): self.rgb = np.zeros((N, N, 3), np.float32); self.a = np.zeros((N, N), np.float32)
    def paint(self, d, col, alpha=1.0):
        cov = (np.clip(0.5 - d * SS, 0, 1) * alpha).astype(np.float32)
        c = col if isinstance(col, np.ndarray) else np.array(col, np.float32)
        self.rgb = self.rgb * (1 - cov[..., None]) + c * cov[..., None]
        self.a = self.a + cov * (1 - self.a)
    def shape(self, d, col, outline=7.0):  # chunky navy outline, then the fill
        self.paint(d - outline, NAVY); self.paint(d, col)
    def grad(self, top, bot):
        t = np.clip(y / S, 0, 1)[..., None]
        return np.array(top, np.float32) * (1 - t) + np.array(bot, np.float32) * t
    def save(self, path):
        rgb = self.rgb.reshape(S, SS, S, SS, 3).mean(axis=(1, 3)); a = self.a.reshape(S, SS, S, SS).mean(axis=(1, 3))
        out = np.where(a[..., None] > 1e-4, rgb / np.maximum(a[..., None], 1e-4), 0)  # un-premultiply (composited over black)
        img = np.concatenate([np.clip(out, 0, 255), (a * 255)[..., None]], axis=2).astype(np.uint8)
        write_png(path, img)
        return img

def badge(c, top, bot):
    d = circle(128, 128, 112)
    c.paint(d - 9, NAVY); c.paint(d, c.grad(top, bot))
    c.paint(inter(circle(128, 128, 104), circle(128, 40, 96)), (255, 255, 255), 0.18)  # soft top highlight

def snowflake(cx, cy, r, w):
    arms = []
    for k in range(6):
        a = k * math.pi / 3 - math.pi / 2
        arms.append(capsule(cx, cy, cx + math.cos(a) * r, cy + math.sin(a) * r, w))
        for side in (-1, 1):
            bx, by = cx + math.cos(a) * r * 0.6, cy + math.sin(a) * r * 0.6
            ba = a + side * 0.75
            arms.append(capsule(bx, by, bx + math.cos(ba) * r * 0.32, by + math.sin(ba) * r * 0.32, w * 0.8))
    return union(*arms, circle(cx, cy, w * 1.6))

def arrow_up(cx, cy, h, w):
    shaft = rbox(cx, cy + h * 0.18, w * 0.42, h * 0.34, w * 0.2)
    head = poly([(cx, cy - h * 0.5), (cx + w, cy - h * 0.02), (cx - w, cy - h * 0.02)])
    return union(shaft, head)

def snowburst():
    c = Canvas(); badge(c, (150, 215, 255), (60, 140, 230))
    for k in range(8):
        a = k * math.pi / 4 + math.pi / 8
        tip = (128 + math.cos(a) * 100, 128 + math.sin(a) * 100)
        l = (128 + math.cos(a - 0.22) * 62, 128 + math.sin(a - 0.22) * 62); r = (128 + math.cos(a + 0.22) * 62, 128 + math.sin(a + 0.22) * 62)
        c.shape(poly([tip, r, l]), (255, 236, 140), 5)
    c.shape(snowflake(128, 128, 62, 10), WHITE, 7)
    return c
def turbo():
    c = Canvas(); badge(c, (120, 230, 255), (30, 130, 220))
    for i, (yy, l) in enumerate(((92, 70), (128, 92), (164, 70))):
        c.shape(capsule(40, yy, 40 + l, yy, 10), (90, 225, 255) if i != 1 else (200, 245, 255), 6)
    c.shape(circle(160, 128, 58), (60, 70, 95), 7)
    for k in range(10):
        a = k * math.pi / 5
        c.paint(rbox(160 + math.cos(a) * 56, 128 + math.sin(a) * 56, 8, 5, 2, a), NAVY)
    c.shape(circle(160, 128, 30), (225, 235, 245), 6)
    c.paint(circle(160, 128, 11), (90, 225, 255))
    return c
def heated():
    c = Canvas(); badge(c, (255, 200, 120), (235, 110, 40))
    for xx in (92, 128, 164):
        pts = [capsule(xx + (6 if j % 2 else -6), 48 + j * 14, xx + (-6 if j % 2 else 6), 62 + j * 14, 5) for j in range(4)]
        c.shape(union(*pts), (255, 240, 220), 5)
    c.shape(rbox(128, 150, 80, 30, 12), (205, 215, 230), 7)
    c.paint(rbox(128, 140, 66, 6, 3), (240, 245, 250))
    c.shape(rbox(128, 178, 82, 9, 6), (255, 140, 40), 6)
    c.paint(rbox(128, 176, 70, 3, 2), (255, 225, 140))
    return c
def surge():
    c = Canvas(); badge(c, (190, 235, 255), (80, 160, 235))
    c.shape(snowflake(100, 144, 54, 9), WHITE, 7)
    c.shape(arrow_up(180, 118, 120, 34), (110, 235, 140), 7)
    return c
def magnet():
    c = Canvas(); badge(c, (150, 245, 235), (30, 150, 170))
    outer = circle(128, 120, 70); inner = circle(128, 120, 32)
    arc = sub(inter(outer, rbox(128, 82, 80, 50, 0)), inner)
    legs = union(sub(rbox(77, 152, 19, 34, 4), circle(128, 120, 32)), sub(rbox(179, 152, 19, 34, 4), circle(128, 120, 32)))
    c.shape(union(arc, legs), (95, 175, 255), 7)
    c.shape(rbox(77, 184, 20, 15, 4), WHITE, 6)
    c.shape(rbox(179, 184, 20, 15, 4), WHITE, 6)
    c.paint(inter(sub(circle(128, 120, 60), circle(128, 120, 48)), rbox(128, 78, 80, 40, 0)), (200, 235, 255))
    return c
def combo():
    c = Canvas(); badge(c, (175, 190, 255), (85, 105, 225))
    gold = (255, 220, 120)
    c.shape(ring(110, 128, 26, 14), gold, 6)
    c.shape(ring(148, 128, 26, 14), gold, 6)
    c.paint(sub(ring(110, 128, 26, 14), rbox(92, 128, 22, 40, 0)), NAVY)  # interlock: left ring over the right one on the top half
    c.paint(sub(ring(110, 128, 26, 14), union(rbox(92, 128, 22, 40, 0), rbox(128, 150, 60, 22, 0))) + 3.5, gold)
    c.shape(snowflake(62, 86, 38, 7), WHITE, 6)
    c.shape(snowflake(194, 170, 38, 7), WHITE, 6)
    return c
def lane():
    c = Canvas(); badge(c, (140, 210, 255), (40, 110, 210))
    for i, (xx, yy) in enumerate(((64, 176), (106, 150), (148, 124))):
        c.shape(rbox(xx, yy, 24, 24, 7), WHITE, 6)
        c.paint(rbox(xx, yy - 10, 18, 6, 3), (190, 225, 255))
    head = poly([(218, 64), (204, 118), (180, 86)])
    c.shape(union(capsule(158, 112, 200, 84, 9), head), (110, 235, 140), 7)
    return c
def aurora():
    c = Canvas(); badge(c, (60, 70, 140), (25, 35, 80))
    cols = [(110, 255, 180), (90, 210, 255), (200, 140, 255)]
    for i, col in enumerate(cols):
        yy = 72 + i * 22
        band = union(*[capsule(40 + k * 18, yy + 14 * math.sin(k * 0.9 + i), 58 + k * 18, yy + 14 * math.sin((k + 1) * 0.9 + i), 9) for k in range(9)])
        c.paint(inter(band, circle(128, 128, 103)), col, 0.92)
    for sx, sy in ((70, 60), (190, 56), (150, 44)):
        c.paint(circle(sx, sy, 3.5), WHITE)
    c.shape(snowflake(128, 170, 38, 8), WHITE, 6)
    return c

icons = {}
for name, fn in [("Snowburst", snowburst), ("TurboTracks", turbo), ("HeatedBlade", heated), ("SnowSurge", surge),
                 ("TokenMagnet", magnet), ("ComboKeeper", combo), ("SnowLane", lane), ("AuroraPatch", aurora)]:
    icons[name] = fn().save(os.path.join(OUT, name + ".png"))
sheet = np.zeros((S, S * 8, 4), np.uint8); sheet[..., :3] = (236, 244, 252); sheet[..., 3] = 255
for i, im in enumerate(icons.values()):
    a = im[..., 3:4] / 255.0
    sheet[:, i * S:(i + 1) * S, :3] = (im[..., :3] * a + sheet[:, i * S:(i + 1) * S, :3] * (1 - a)).astype(np.uint8)
write_png(os.path.join(OUT, "contact_sheet.png"), sheet)
print("done", list(icons))
