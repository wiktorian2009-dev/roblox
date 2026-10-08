# blades.py - 30 snowplow blades. Origin = back-centre of the mount bracket; front = -Y; bottom edge z = -1.05.
import math
from mathutils import Vector
from partlib import *

ZB = -1.05


def yz(pts, z):
    """Front-surface y of a bottom->top profile at height z (clamped)."""
    if z <= pts[0][1]: return pts[0][0]
    for a, b in zip(pts, pts[1:]):
        if a[1] <= z <= b[1] or b[1] <= z <= a[1]:
            t = (z - a[1]) / ((b[1] - a[1]) or 1); return a[0] + (b[0] - a[0]) * t
    return pts[-1][0]


def sub(pts, zlo, zhi, off=0.03, n=4):
    return [(yz(pts, zlo + (zhi - zlo) * i / (n - 1)) - off, zlo + (zhi - zlo) * i / (n - 1)) for i in range(n)]


def skin(m, pc, pts, zlo, zhi, W, off=0.03, thick=0.06, plan=None, ns=13, part="Trim", x0=None):
    xs = stations(W, ns) if x0 is None else [x0 + W * i / (ns - 1) for i in range(ns)]
    return shell(m, pc, xs, profile_fn(sub(pts, zlo, zhi, off + thick * 0, 4)), thick, plan=plan, part=part)


def mount_arms(m, dark, steel, pts, plan=None, xa=1.25, za=-0.3, w=0.26, h=0.32, mount_w=1.9, piston=True, brace=True, part="Arms", sleeve=None):
    pl = plan or (lambda x: 0.0)
    box(m, dark, (0, -0.15, 0), (mount_w, 0.3, 0.8), r=0.08, part="Mount")
    for sx in (-1, 1):
        ye = yz(pts, za) + pl(sx * xa) + 0.12
        beam(m, dark, (sx * 0.62, -0.24, -0.08), (sx * xa, ye, za), w=w, h=h, r=0.06, part=part)
        cyl(m, P(steel, "ME"), (sx * 0.62 - 0.0, -0.18, -0.08), r=0.11, h=0.12, rot=(0, 90, 0), seg=8, part="Pins") if False else None
    if brace:
        yb = max(yz(pts, za) + pl(xa) + 0.45, yz(pts, za) + pl(0) + 0.45)
        beam(m, dark, (-xa * 0.92, yb, za), (xa * 0.92, yb, za), w=0.2, h=0.22, r=0.05, part=part)
    if piston:
        yt = yz(pts, 0.95) + pl(0) + 0.12
        rod(m, sleeve or dark, (0, -0.28, 0.3), (0, -1.15, 0.62), r=0.14, seg=10, part=part)
        rod(m, P(steel, "ME"), (0, -1.1, 0.6), (0, yt, 0.95), r=0.075, seg=8, part="Piston")


def endplates(m, pc, pts, W, thick=0.16, back=0.5, plan=None, part="Ends", inset=0.0, zcut=None):
    pl = plan or (lambda x: 0.0)
    for sx in (-1, 1):
        x = sx * (W / 2 - inset)
        q = [(y + pl(x), z) for y, z in pts if zcut is None or z <= zcut]
        poly = [(y - 0.04, z) for y, z in q] + [(y + back, z) for y, z in reversed(q)]
        flat(m, pc, poly, thick, (x - thick / 2, 0, 0), axis=(1, 0, 0), part=part)


def bolts(m, pc, pts, xs, z, plan=None, r=0.09, part="Bolts", seg=6, h=0.09):
    pl = plan or (lambda x: 0.0)
    for x in xs:
        disc(m, pc, (x, yz(pts, z) + pl(x) + 0.02, z), r, h, axis=(0, -1, 0), seg=seg, part=part)


def back_ribs(m, pc, pts, xs, thick, plan=None, r=0.08, part="Ribs"):
    pl = plan or (lambda x: 0.0)
    q = pts[1:-1] if len(pts) > 4 else [(yz(pts, z), z) for z in (pts[0][1] + 0.12, (pts[0][1] + pts[-1][1]) / 2, pts[-1][1] - 0.12)]
    for x in xs:
        tube(m, pc, [(x, y + pl(x) + thick + r * 0.4, z) for (y, z) in q], r=r, seg=6, part=part, smooth=1)


def skids(m, pc, xs, y0=-3.1, y1=-1.9, part="Skids"):
    for x in xs:
        box(m, pc, (x, (y0 + y1) / 2, ZB + 0.06), (0.24, y1 - y0, 0.12), r=0.04, part=part)
        rod(m, pc, (x, y0 + 0.02, ZB + 0.06), (x, y0 - 0.22, ZB + 0.3), r=0.07, seg=6, part=part)
        beam(m, pc, (x, (y0 + y1) / 2 + 0.2, ZB + 0.1), (x, (y0 + y1) / 2 + 0.2, ZB + 0.55), w=0.12, h=0.12, r=0.03, part=part)


# =====================================================================================
def BladeBasic(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = bez((-2.92, ZB), (-2.3, 0.1), (-2.85, 1.3), 7)
    shell(m, P("E2483D"), stations(W, 13), profile_fn(pts), 0.26, part="Plate")
    box(m, P(STEEL, "ME"), (0, yz(pts, -0.93) - 0.06, -0.93), (W - 0.1, 0.18, 0.26), r=0.05, part="Edge")
    rod(m, P(p[3]), (-W / 2, yz(pts, 1.3) + 0.08, 1.31), (W / 2, yz(pts, 1.3) + 0.08, 1.31), r=0.12, seg=8, part="Lip")
    back_ribs(m, P(STEEL, "ME"), pts, [-2.6, -1.3, 0, 1.3, 2.6], 0.26)
    bolts(m, P(STEEL, "ME"), pts, [-3.0, -1.8, -0.6, 0.6, 1.8, 3.0], 1.02)
    bolts(m, P(STEEL, "ME"), pts, [-3.0, -1.8, -0.6, 0.6, 1.8, 3.0], -0.62)
    endplates(m, P(p[3]), pts, W, thick=0.18, back=0.42)
    mount_arms(m, P(p[3]), STEEL, pts, xa=1.3)


def BladeWide(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.32 * (2 * x / W) ** 2
    pts = bez((-3.0, ZB), (-2.45, -0.15), (-2.85, 0.85), 6)
    shell(m, P("E2483D"), stations(W, 17), profile_fn(pts), 0.24, plan=plan, part="Plate")
    skin(m, P(HAZ), pts, 0.3, 0.72, W - 0.5, off=0.02, thick=0.05, plan=plan, ns=17, part="Hazard")
    for i in range(-5, 6):
        x = i * 1.0
        z = 0.51; y = yz(pts, z) + plan(x) - 0.08
        flat(m, P("23252B"), [(-0.14, -0.2), (0.12, -0.2), (0.34, 0.2), (0.08, 0.2)], 0.04, (x, y, z), axis=(0, -1, 0), part="Stripes")
    box(m, P(STEEL, "ME"), (0, yz(pts, -0.95) - 0.05, -0.95), (W - 0.2, 0.16, 0.22), r=0.05, part="Edge") if False else None
    skin(m, P(STEEL, "ME"), pts, ZB, -0.75, W - 0.1, off=0.02, thick=0.1, plan=plan, ns=17, part="Edge")
    rod(m, P(p[3]), (-W / 2 + 0.1, yz(pts, 0.85) + plan(W / 2) + 0.06, 0.86), (-W / 2 + 0.1, yz(pts, 0.85) + 0.06, 0.86), r=0.01, seg=3, part="Lip") if False else None
    tube(m, P(p[3]), [(x, yz(pts, 0.85) + plan(x) + 0.08, 0.87) for x in stations(W, 9)], r=0.11, seg=8, part="Lip", smooth=3)
    endplates(m, P(p[3]), pts, W, thick=0.2, back=0.5, plan=plan)
    skids(m, P(p[3]), [-W / 2 + 0.35, W / 2 - 0.35], y0=yz(pts, ZB) + plan(W / 2) - 0.05, y1=yz(pts, ZB) + plan(W / 2) + 1.0)
    back_ribs(m, P(STEEL, "ME"), pts, [-4.5, -2.2, 2.2, 4.5], 0.24, plan=plan)
    mount_arms(m, P(p[3]), STEEL, pts, plan=plan, xa=1.9)
    for sx in (-1, 1):
        beam(m, P(p[3]), (sx * 0.8, -0.3, -0.2), (sx * 3.6, yz(pts, -0.4) + plan(sx * 3.6) + 0.12, -0.4), w=0.2, h=0.22, part="Arms")


def BladeFrostScoop(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.55 * (2 * x / W) ** 2
    pts = bez((-3.35, ZB), (-2.2, 0.0), (-3.25, 1.5), 8)
    F, B = shell(m, P("7EC8F5"), stations(W, 15), profile_fn(pts), 0.24, plan=plan, part="Plate")
    # snow-cap rim: lumpy spheres along the top edge
    for i in range(11):
        x = -W / 2 + 0.35 + (W - 0.7) * i / 10
        r = 0.27 + 0.07 * math.sin(i * 2.3)
        sphere(m, P(WHITE), (x, yz(pts, 1.5) + plan(x) + 0.1, 1.52 + 0.04 * math.cos(i * 1.7)), r, seg=8, rings=5, scl=(1.25, 1.0, 0.8), part="Snow")
    skin(m, P("DDF3FF", "IC"), pts, ZB, -0.78, W - 0.3, off=0.02, thick=0.1, plan=plan, ns=15, part="Edge")
    # side wings angled out-forward
    for sx in (-1, 1):
        x = sx * W / 2
        q = [(yz(pts, z) + plan(x), z) for z in (ZB, -0.3, 0.5, 1.3)]
        poly = [(q[0][0] - 0.75, ZB), (q[1][0] - 0.95, -0.3), (q[2][0] - 0.8, 0.5), (q[3][0] - 0.25, 1.3), (q[3][0] + 0.3, 1.3), (q[0][0] + 0.35, ZB)]
        flat(m, P(p[3]), poly, 0.16, (x - (0.16 if sx > 0 else 0), 0, 0), axis=(1, 0, 0), part="Wings")
        sphere(m, P(WHITE), (x, q[3][0] - 0.05, 1.38), 0.3, seg=10, rings=6, part="Snow")
    back_ribs(m, P(p[3]), pts, [-2.8, -1.0, 1.0, 2.8], 0.24, plan=plan, r=0.09)
    # A-frame arms
    box(m, P(p[3]), (0, -0.15, 0), (1.9, 0.3, 0.8), r=0.08, part="Mount")
    for sx in (-1, 1):
        beam(m, P(p[3]), (sx * 0.6, -0.25, -0.1), (sx * 1.7, yz(pts, -0.35) + plan(sx * 1.7) + 0.12, -0.35), w=0.26, h=0.3, part="Arms")
        beam(m, P(p[3]), (sx * 0.4, -0.25, 0.25), (sx * 0.9, yz(pts, 0.7) + plan(sx * 0.9) + 0.15, 0.7), w=0.2, h=0.22, part="Arms")
    rod(m, P(STEEL, "ME"), (0, -0.3, 0.05), (0, yz(pts, 0.1) + 0.15, 0.1), r=0.1, seg=8, part="Piston")


def BladeIce(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = [(-2.85, ZB), (-2.7, -0.3), (-2.62, 0.5), (-2.65, 1.25)]
    shell(m, P(p[0]), stations(W, 9), profile_fn(pts), 0.5, part="Plate")
    # riveted horizontal rails
    for z in (-0.25, 0.75):
        box(m, P(p[1]), (0, yz(pts, z) - 0.1, z), (W + 0.2, 0.26, 0.34), r=0.08, bseg=2, part="Rails")
        for x in [i * 1.1 for i in range(-4, 5)]:
            disc(m, P(p[3]), (x, yz(pts, z) - 0.22, z), 0.08, 0.07, seg=6, part="Rivets")
    # hardened chisel edge: thick bar with angled teeth
    box(m, P("5C5F6B", "ME"), (0, yz(pts, -0.9) - 0.14, -0.88), (W + 0.1, 0.38, 0.34), r=0.06, part="Edge")
    for i in range(9):
        x = -W / 2 + 0.55 + (W - 1.1) * i / 8
        flat(m, P("5C5F6B", "ME"), [(-0.32, 0.3), (0.32, 0.3), (0.0, -0.05)], 0.3, (x, -3.0, -1.0), axis=(0, 1, 0), up=(0, 0, 1), part="Edge") if False else None
        rod(m, P("5C5F6B", "ME"), (x, yz(pts, -0.9) - 0.2, -0.86), (x, yz(pts, -0.9) - 0.62, -0.98), r=0.13, r2=0.03, seg=4, part="Edge")
    # thick side armour + top cap
    for sx in (-1, 1):
        box(m, P(p[3]), (sx * (W / 2 + 0.05), -2.45, 0.1), (0.36, 0.95, 2.35), r=0.1, bseg=2, part="Armor")
        for z in (-0.6, 0.2, 1.0): disc(m, P(p[2], "ME"), (sx * (W / 2 + 0.23), -2.45, z), 0.09, 0.06, axis=(sx, 0, 0), seg=6, part="Rivets2")
    box(m, P(p[3]), (0, -2.45, 1.32), (W - 0.2, 0.75, 0.2), r=0.06, part="Armor")
    back_ribs(m, P(p[3]), pts, [-3.3, -1.65, 0, 1.65, 3.3], 0.5, r=0.1)
    mount_arms(m, P(p[3]), STEEL, pts, xa=1.4, w=0.32, h=0.38)


def BladeDune(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.25 * (2 * x / W) ** 2
    pts = bez((-3.05, ZB), (-2.4, -0.1), (-2.75, 0.95), 6)
    shell(m, P(p[0]), stations(W, 15), profile_fn(pts), 0.24, plan=plan, part="Plate")
    tube(m, P(p[1]), [(x, yz(pts, 0.95) + plan(x) - 0.02, 1.0) for x in stations(W - 0.1, 9)], r=0.17, seg=10, part="Lip", smooth=3)
    skin(m, P(p[1]), pts, ZB, -0.8, W - 0.1, off=0.02, thick=0.09, plan=plan, ns=15, part="Lip")
    # sun emblem
    zc = 0.15; y = yz(pts, zc) + plan(0) - 0.05
    flat(m, P(p[2]), star_poly(12, 0.62, 0.42), 0.08, (0, y, zc), axis=(0, -1, 0), part="Sun")
    disc(m, P(p[2]), (0, y - 0.06, zc), 0.34, 0.08, seg=14, part="Sun")
    disc(m, P(p[3]), (0, y - 0.13, zc), 0.18, 0.04, seg=12, part="SunCore")
    for sx in (-1, 1):
        for k in range(3):
            x = sx * (1.6 + k * 1.3)
            flat(m, P(p[3]), [(-0.32, -0.06), (0.32, -0.06), (0.32, 0.06), (-0.32, 0.06)], 0.03, (x, yz(pts, 0.15) + plan(x) - 0.02, 0.15), axis=(0, -1, 0), part="SunCore") if False else None
        disc(m, P(p[1]), (sx * 3.4, yz(pts, 0.2) + plan(sx * 3.4) - 0.03, 0.2), 0.2, 0.06, seg=10, part="Lip")
    endplates(m, P(p[3]), pts, W, thick=0.2, back=0.45, plan=plan)
    back_ribs(m, P(p[3]), pts, [-4.2, -2.1, 2.1, 4.2], 0.24, plan=plan)
    mount_arms(m, P(p[3]), STEEL, pts, plan=plan, xa=1.7)


def BladeGrave(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = [(-2.75, ZB), (-2.6, 0.0), (-2.55, 0.9)]
    shell(m, P(p[0]), stations(W, 9), profile_fn(pts), 0.22, part="Plate")
    # violet frame: bottom bar and top rail
    box(m, P(p[1]), (0, -2.55, 1.0), (W + 0.25, 0.55, 0.26), r=0.1, bseg=2, part="Frame")
    box(m, P(p[1]), (0, -2.65, -0.92), (W + 0.25, 0.5, 0.26), r=0.1, bseg=2, part="Frame")
    for sx in (-1, 1):
        box(m, P(p[1]), (sx * (W / 2 + 0.02), -2.55, 0.05), (0.3, 0.55, 2.1), r=0.1, part="Frame")
        sphere(m, P(p[1]), (sx * (W / 2 + 0.02), -2.55, 1.22), 0.2, seg=8, rings=5, part="Frame")
    # tombstone teeth, leaning forward, varied heights
    n = 7
    for i in range(n):
        x = -W / 2 + 0.75 + (W - 1.5) * i / (n - 1)
        h = 1.55 + 0.25 * math.sin(i * 1.9)
        flat(m, P(p[2]), arch_poly(1.02, h), 0.24, (x, -2.82, -1.05), axis=(0, -1, 0), up=(0, 0.18, 1), part="Teeth", spin=4 * math.sin(i * 2.7))
        # little carved cross
        flat(m, P("B9AE95"), [(-0.05, 0), (0.05, 0), (0.05, 0.38), (-0.05, 0.38)], 0.04, (x, -3.06 + 0.02 * 0, h - 1.05 - 0.75), axis=(0, -1, 0), up=(0, 0.18, 1), part="Marks")
        flat(m, P("B9AE95"), [(-0.16, 0.24), (0.16, 0.24), (0.16, 0.32), (-0.16, 0.32)], 0.04, (x, -3.06, h - 1.05 - 0.75), axis=(0, -1, 0), up=(0, 0.18, 1), part="Marks")
    back_ribs(m, P(p[3] if False else "2A1F3D"), pts, [-3.0, -1.0, 1.0, 3.0], 0.22)
    mount_arms(m, P("2A1F3D"), STEEL, pts, xa=1.3)


def BladeHex(m, c):
    p = c["palette"]; W = c["visualWidth"]
    D = 1.0
    plan = lambda x: -D * (1 - abs(2 * x / W))
    pts = [(-2.45, ZB), (-2.35, -0.2), (-2.3, 0.7), (-2.45, 1.45)]
    F, B = shell(m, P(p[0]), stations(W, 11), profile_fn(pts), 0.26, plan=plan, part="Plate")
    # rune lines (glow) - chevrons on each wing
    for sx in (-1, 1):
        for k, z in enumerate((-0.35, 0.35)):
            x0, x1 = sx * 0.6, sx * (W / 2 - 0.7)
            pa = (x0, yz(pts, z) + plan(x0) - 0.05, z); pb = (x1, yz(pts, z + 0.3) + plan(x1) - 0.05, z + 0.3)
            beam(m, P(p[3], "NE"), pa, pb, w=0.09, h=0.04, r=0.0, part="Runes", up=(0, 0, 1))
        disc(m, P(p[3], "NE"), (sx * 2.4, yz(pts, 1.0) + plan(sx * 2.4) - 0.02, 1.0), 0.14, 0.05, seg=6, part="Runes")
    # central keel and spiky tips
    beam(m, P(p[1]), (0, yz(pts, ZB) - D - 0.15, ZB + 0.05), (0, yz(pts, 1.45) - D - 0.1, 1.5), w=0.3, h=0.3, part="Keel")
    for sx in (-1, 1):
        x = sx * W / 2
        spike(m, P(p[2]), (x - sx * 0.05, -2.4, 1.2), (x + sx * 0.55, -2.75, 1.95), 0.2, part="Spikes")
        spike(m, P(p[2]), (x - sx * 0.05, -2.4, 0.3), (x + sx * 0.7, -2.7, 0.35), 0.18, part="Spikes")
        spike(m, P(p[2]), (x - sx * 0.05, -2.4, -0.6), (x + sx * 0.55, -2.7, -0.8), 0.16, part="Spikes")
    spike(m, P(p[2]), (0, -3.3, 1.4), (0, -3.75, 2.05), 0.2, part="Spikes")
    endplates(m, P(p[1]), pts, W, thick=0.2, back=0.4, plan=plan)
    mount_arms(m, P("2A1F3D"), STEEL, pts, plan=plan, xa=1.3)


def BladeQuartz(m, c):
    p = c["palette"]; W = c["visualWidth"]
    # frame
    n = 5; seg_w = (W - 0.4) / n
    ang = [(-14, 0), (-7, 0), (0, 0), (7, 0), (14, 0)]
    pts = [(-2.7, ZB), (-2.6, 1.35)]
    for i in range(n):
        x = -W / 2 + 0.2 + seg_w * (i + 0.5)
        yo = -0.12 * abs(i - 2) ** 1.6
        poly = [(-seg_w / 2 + 0.06, 0.0), (seg_w / 2 - 0.06, 0.0), (seg_w / 2 - 0.06, 1.7), (seg_w * 0.18, 2.15), (-seg_w * 0.18, 2.15), (-seg_w / 2 + 0.06, 1.7)]
        if i % 2: poly = [(-seg_w / 2 + 0.06, 0.0), (seg_w / 2 - 0.06, 0.0), (seg_w / 2 - 0.06, 1.95), (-seg_w / 2 + 0.06, 1.95)]
        flat(m, P(p[0], "GL"), poly, 0.3, (x, -2.6 + yo, -0.95), axis=(0, -1, 0), part="Crystal", bev=0.08, spin=0)
        flat(m, P(p[2]), [(-0.08, 0.3), (0.08, 0.3), (0.2, 1.4), (-0.02, 1.4)], 0.04, (x - 0.2, -2.92 + yo, -0.95), axis=(0, -1, 0), part="Shine")
    m.flat("Crystal", P(p[0], "GL"), 1)
    box(m, P(p[3]), (0, -2.45, -0.92), (W + 0.2, 0.55, 0.28), r=0.08, part="Frame")
    box(m, P(p[3]), (0, -2.35, 0.3), (W, 0.25, 1.5), r=0.08, part="Frame")
    for i in range(n + 1):
        x = -W / 2 + 0.2 + seg_w * i
        box(m, P(p[3]), (x, -2.6, 0.05), (0.2, 0.5, 2.15), r=0.06, part="Frame")
        sphere(m, P(p[1]), (x, -2.62, 1.22), 0.13, seg=8, rings=5, part="Studs")
    mount_arms(m, P(p[3]), STEEL, [(-2.35, ZB), (-2.35, 1.4)], xa=1.4)


def BladePrism(m, c):
    p = c["palette"]; W = c["visualWidth"]
    D = 1.1
    plan = lambda x: -D * (1 - abs(2 * x / W)) ** 0.9
    pts = [(-2.4, ZB), (-2.35, 0.2), (-2.5, 1.3)]
    shell(m, P(p[0], "GL"), stations(W, 11), profile_fn(pts), 0.32, plan=plan, part="Crystal")
    m.flat("Crystal", P(p[0], "GL"), 1)
    skin(m, P(p[2], "GL"), pts, ZB, -0.75, W, off=0.03, thick=0.1, plan=plan, ns=11, part="EdgeIce")
    # magenta core gems down the prow
    for z, r in ((-0.35, 0.26), (0.45, 0.22)):
        crystal(m, P(p[1], "NE"), (0, -3.25, z), (0, -3.8, z), r, seg=6, part="Gems", mid=0.4)
    # prism fins on top
    for x in (-3.3, -2.0, -0.7, 0.7, 2.0, 3.3):
        h = 0.95 - 0.12 * abs(x)
        flat(m, P(p[2], "GL"), [(-0.4, 0), (0.4, 0), (0.05, h)], 0.12, (x, yz(pts, 1.3) + plan(x) + 0.1, 1.25), axis=(0, -1, 0), part="Fins")
    m.flat("Fins", P(p[2], "GL"), 1)
    endplates(m, P(p[3]), pts, W, thick=0.2, back=0.45, plan=plan)
    mount_arms(m, P(p[3]), STEEL, pts, plan=plan, xa=1.3)


def BladePixel(m, c):
    p = c["palette"]; W = c["visualWidth"]
    s = 0.92
    rows = [(12, -2.95), (12, -2.75), (10, -2.55), (8, -2.35)]
    cols = [P(p[0]), P(p[1])]
    for r, (n, y) in enumerate(rows):
        z = ZB + s * 0.5 + r * s * 0.86
        for i in range(n):
            x = (i - (n - 1) / 2) * s
            pc = cols[(i + r) % 2] if r < 3 else P(p[2])
            box(m, pc, (x, y, z), (s * 0.98, s * 0.98, s * 0.88), r=0.06, part="Voxels")
    for sx in (-1, 1):
        box(m, P(p[3]), (sx * (5.5 * s + 0.6), -2.45, ZB + 1.1), (0.4, 1.0, 2.2), r=0.04, part="Ends")
    box(m, P(p[3]), (0, -2.0, ZB + 1.2), (W - 1.6, 0.25, 2.2), r=0.04, part="Ends")
    mount_arms(m, P(p[3]), STEEL, [(-2.1, ZB), (-2.1, 1.4)], xa=1.3)


def BladeArcade(m, c):
    p = c["palette"]; W = c["visualWidth"]
    n = 4; sw = (W - 0.3) / n
    # cabinet side profile (y,z): screen top overhang
    prof = [(-2.95, ZB), (-2.25, ZB), (-2.25, 1.55), (-2.55, 1.55), (-2.95, 1.25), (-2.85, 0.75), (-3.1, 0.35), (-3.1, ZB + 0.05)]
    for i in range(n):
        x0 = -W / 2 + 0.15 + sw * i
        flat(m, P(p[3]), [(y, z) for y, z in prof], sw - 0.14, (x0 + 0.07, 0, 0), axis=(1, 0, 0), part="Cabinet")
        xc = x0 + sw / 2
        # side trims
        for xx in (x0 + 0.04, x0 + sw - 0.12):
            flat(m, P(p[0] if i % 2 == 0 else p[1]), prof, 0.08, (xx, 0, 0), axis=(1, 0, 0), part="SideA" if i % 2 == 0 else "SideB")
        # screen
        box(m, P("4A3E8C"), (xc, -2.92, 0.98), (sw - 0.45, 0.06, 0.42), r=0.03, rot=(-37, 0, 0), part="Screen")
        # joystick + buttons on the control deck
        rod(m, P(DARK), (xc - 0.25, -3.05, 0.55), (xc - 0.25, -3.05, 0.85), r=0.04, seg=6, part="Sticks")
        sphere(m, P(p[2]), (xc - 0.25, -3.05, 0.9), 0.14, seg=8, rings=5, part="Knobs")
        for k in range(2): disc(m, P(p[2]), (xc + 0.12 + k * 0.24, -3.0, 0.4), 0.07, 0.06, axis=(0, 0, 1), seg=8, part="Knobs")
    # neon strip along the marquee
    box(m, P(p[1], "NE"), (0, -2.58, 1.6), (W - 0.4, 0.12, 0.08), r=0.02, part="Neon")
    box(m, P(p[0], "NE"), (0, -3.12, ZB + 0.25), (W - 0.4, 0.06, 0.08), r=0.02, part="Neon2")
    mount_arms(m, P(p[3]), STEEL, [(-2.35, ZB), (-2.35, 1.4)], xa=1.3)


def BladeVine(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.3 * (2 * x / W) ** 2
    pts = bez((-3.0, ZB), (-2.4, -0.1), (-2.8, 0.9), 6)
    shell(m, P(p[1], "WO"), stations(W, 11), profile_fn(pts), 0.26, plan=plan, part="Plate")
    # plank seams
    for z in (-0.4, 0.3):
        skin(m, P("6E4426", "WO"), pts, z - 0.04, z + 0.04, W - 0.1, off=0.01, thick=0.03, plan=plan, ns=9, part="Seams")
    # vines: sinusoid tube across the face
    for k, ph in enumerate((0.0, 2.2)):
        vp = []
        for i in range(19):
            x = -W / 2 + 0.2 + (W - 0.4) * i / 18
            z = 0.0 + 0.55 * math.sin(i * 0.86 + ph)
            vp.append((x, yz(pts, z) + plan(x) - 0.07, z))
        tube(m, P(p[3] if k else p[0]), vp, r=0.07, seg=5, part="Vines", smooth=1)
        for i in range(1, 18, 3):
            x, y, z = vp[i]
            flat(m, P(p[0] if k else p[3]), leaf_poly(0.55, 0.32), 0.04, (x, y - 0.05, z), axis=(0, -1, 0), part="Leaves", spin=(i * 47) % 360)
    for x in (-3.6, 0.4, 4.2):
        sphere(m, P(p[2]), (x, yz(pts, 0.45) + plan(x) - 0.12, 0.45), 0.16, seg=8, rings=5, part="Flowers")
    tube(m, P(p[3]), [(x, yz(pts, 0.9) + plan(x) + 0.05, 0.93) for x in stations(W, 9)], r=0.12, seg=8, part="Vines", smooth=3)
    endplates(m, P(p[3]), pts, W, thick=0.2, back=0.45, plan=plan)
    mount_arms(m, P("5A3A22", "WO"), STEEL, pts, plan=plan, xa=1.8)


def BladeTusk(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = [(-2.75, ZB), (-2.6, 0.0), (-2.65, 1.2)]
    shell(m, P(p[1], "WO"), stations(W, 9), profile_fn(pts), 0.34, part="Plate")
    # tiki face carving: brows, eyes, mouth band
    for sx in (-1, 1):
        box(m, P(p[2]), (sx * 1.0, -2.75, 0.75), (1.2, 0.14, 0.24), r=0.05, rot=(0, sx * 10, 0), part="Paint")
        disc(m, P("2E1E12"), (sx * 1.0, -2.7, 0.3), 0.32, 0.08, seg=10, part="Eyes")
        disc(m, P(p[2], "NE"), (sx * 1.0, -2.77, 0.3), 0.14, 0.05, seg=8, part="Glow")
    box(m, P(p[2]), (0, -2.76, -0.42), (2.6, 0.12, 0.42), r=0.08, part="Paint")
    for k in range(5): box(m, P("FFF4E0"), (-1.0 + k * 0.5, -2.82, -0.42), (0.3, 0.08, 0.3), r=0.04, part="Ivory")
    for sx in (-1, 1):
        for k in range(3):
            box(m, P("6E4426", "WO"), (sx * (2.1 + k * 0.8), -2.7, 0.2), (0.12, 0.08, 1.8), r=0.03, part="Grooves")
    # big ivory tusks curving up from the bottom corners
    for sx in (-1, 1):
        x = sx * (W / 2 - 0.45)
        tp = [(x, -2.7, -0.72), (x + sx * 0.15, -3.35, -0.72), (x + sx * 0.3, -3.85, -0.35), (x + sx * 0.35, -3.9, 0.35)]
        tube(m, P("FFF4E0"), tp, r=0.3, r2=0.04, seg=10, part="Ivory", smooth=4)
        torus(m, P(p[2]), (x, -2.85, -0.72), R=0.3, r=0.08, seg=12, rseg=6, rot=(90, 0, 0), part="Paint")
    # small teeth along the bottom
    for i in range(6):
        x = -2.1 + i * 0.84
        spike(m, P("FFF4E0"), (x, -2.72, -0.9), (x, -3.2, -1.0), 0.14, seg=6, part="Ivory")
    box(m, P(p[3]), (0, -2.6, 1.3), (W + 0.2, 0.6, 0.22), r=0.08, part="Cap")
    for sx in (-1, 1):
        for k in range(3):
            flat(m, P(p[0]), leaf_poly(0.9, 0.36), 0.05, (sx * (W / 2 - 0.3 - k * 0.4), -2.6, 1.38), axis=(0, 0, 1), up=(0, -1, 0), part="Leaves", spin=sx * (30 + 30 * k))
    mount_arms(m, P("5A3A22", "WO"), STEEL, pts, xa=1.3)


def BladeGlacier(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.5 * (2 * x / W) ** 2
    pts = bez((-3.35, ZB), (-2.25, 0.05), (-3.15, 1.5), 8)
    shell(m, P(p[0], "IC"), stations(W, 15), profile_fn(pts), 0.26, plan=plan, part="Plate")
    # frosted ridges
    for x in (-4.0, -2.7, -1.35, 0, 1.35, 2.7, 4.0):
        tube(m, P(WHITE), [(x, yz(pts, z) + plan(x) - 0.03, z) for z in (-0.75, -0.2, 0.4, 1.0, 1.3)], r=0.11, r2=0.05, seg=5, part="Ridges", smooth=2)
    # silver rim (top + ends)
    tube(m, P(p[2], "ME"), [(x, yz(pts, 1.5) + plan(x) + 0.08, 1.52) for x in stations(W, 9)], r=0.13, seg=7, part="Rim", smooth=2)
    for sx in (-1, 1):
        x = sx * W / 2
        tube(m, P(p[2], "ME"), [(x, y + plan(x) + 0.1, z) for (y, z) in pts], r=0.13, seg=8, part="Rim", smooth=1)
    skin(m, P(p[1]), pts, ZB, -0.8, W - 0.2, off=0.02, thick=0.1, plan=plan, ns=15, part="Edge")
    back_ribs(m, P(p[1]), pts, [-3.0, -1.0, 1.0, 3.0], 0.26, plan=plan)
    mount_arms(m, P(p[1]), STEEL, pts, plan=plan, xa=1.5)


def BladeZero(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = [(-2.95, ZB), (-2.72, -0.3), (-2.62, 0.6), (-2.75, 1.4)]
    shell(m, P(p[1]), stations(W, 9), profile_fn(pts), 0.52, part="Plate")
    for x in (-3.2, -1.6, 0, 1.6, 3.2):
        tube(m, P(p[2], "ME"), [(x, y - 0.06, z) for (y, z) in pts[1:]] , r=0.15, seg=8, part="Ribs", smooth=2, sq=0.6)
    # frost-white chisel cutting edge
    box(m, P(WHITE, "IC"), (0, yz(pts, -0.9) - 0.12, -0.9), (W + 0.3, 0.4, 0.32), r=0.06, part="Edge")
    flat(m, P(WHITE, "IC"), [(-W / 2 - 0.15, 0), (W / 2 + 0.15, 0), (W / 2 + 0.15, 0.25), (-W / 2 - 0.15, 0.25)], 0.01, (0, 0, 0), axis=(0, -1, 0), part="Edge") if False else None
    for i in range(8):
        x = -W / 2 + 0.6 + (W - 1.2) * i / 7
        crystal(m, P(WHITE, "IC"), (x, yz(pts, -0.9) - 0.25, -0.92), (x, yz(pts, -0.9) - 0.75, -1.02), 0.14, seg=4, part="Edge")
    # armoured top + lilac glow seam
    box(m, P(p[2], "ME"), (0, -2.55, 1.42), (W + 0.2, 0.85, 0.24), r=0.08, part="Cap")
    box(m, P(p[3], "NE"), (0, yz(pts, 1.15) - 0.06, 1.15), (W - 0.9, 0.06, 0.07), r=0.02, part="Glow")
    for sx in (-1, 1):
        box(m, P(p[2], "ME"), (sx * (W / 2 + 0.1), -2.6, 0.15), (0.32, 1.0, 2.4), r=0.1, bseg=2, part="Cap")
        crystal(m, P(p[0], "IC"), (sx * (W / 2 + 0.1), -2.6, 1.3), (sx * (W / 2 + 0.35), -2.7, 2.1), 0.2, seg=5, part="Frost")
    mount_arms(m, P("1F3F86"), STEEL, pts, xa=1.4, w=0.32, h=0.38)


def BladeSingularity(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -1.15 * (1 - abs(2 * x / W)) ** 1.25
    zt = lambda x: 1.15 + 0.75 * abs(2 * x / W) ** 1.5   # wings sweep up at the tips
    def prof(x):
        top = zt(x)
        return [(-2.35 - 0.05, ZB), (-2.3, -0.1), (-2.38, 0.6), (-2.55 - 0.1 * abs(2 * x / W), top)]
    shell(m, P(p[3], "IC"), stations(W, 15), prof, 0.26, plan=plan, part="Plate")
    pts0 = prof(0)
    # silver spine along the prow and silver rim
    beam(m, P(p[2], "ME"), (0, -2.4 + plan(0) - 0.1, ZB + 0.05), (0, -2.6 + plan(0) - 0.05, 1.25), w=0.28, h=0.28, part="Silver")
    tube(m, P(p[2], "ME"), [(x, prof(x)[-1][0] + plan(x) + 0.1, zt(x) + 0.02) for x in stations(W, 13)], r=0.1, seg=8, part="Silver", smooth=2)
    skin(m, P(p[0], "IC"), pts0, ZB, -0.78, W, off=0.02, thick=0.1, plan=plan, ns=15, part="Edge")
    # cold core ring at the prow
    cy = -2.4 + plan(0) - 0.35
    torus(m, P(p[2], "ME"), (0, cy, 0.4), R=0.62, r=0.12, seg=20, rseg=8, rot=(90, 0, 0), part="Silver")
    sphere(m, P(p[0], "NE"), (0, cy - 0.02, 0.4), 0.36, seg=12, rings=8, part="Core")
    for sx in (-1, 1):
        crystal(m, P(p[0], "IC"), (sx * (W / 2 - 0.15), -2.45, zt(W / 2) - 0.3), (sx * (W / 2 + 0.4), -2.9, zt(W / 2) + 0.45), 0.2, seg=5, part="Edge")
    endplates(m, P(p[2], "ME"), pts0, W, thick=0.01, back=0.1, plan=plan) if False else None
    mount_arms(m, P(p[1]), STEEL, pts0, plan=plan, xa=1.4)


def BladePetal(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.35 * (2 * x / W) ** 2
    pts = bez((-2.6, ZB), (-2.2, 0.0), (-2.45, 0.9), 5)
    shell(m, P(p[3], "WO"), stations(W - 0.6, 13), profile_fn(pts), 0.22, plan=plan, part="Frame")
    n = 7
    for i in range(n):
        x = -W / 2 + 0.95 + (W - 1.9) * i / (n - 1)
        tilt = (i - 3) * 6
        y = yz(pts, -0.2) + plan(x) - 0.12 - 0.05 * (i % 2)
        flat(m, P(p[0]), petal_poly(2.3, 2.15), 0.14, (x, y, ZB + 0.02), axis=(0, -1, 0), up=(math.sin(math.radians(tilt)), 0.22, 1), part="Petals")
        flat(m, P(p[1]), petal_poly(0.9, 0.95), 0.05, (x, y - 0.12, ZB + 1.25), axis=(0, -1, 0), up=(math.sin(math.radians(tilt)), 0.22, 1), part="Tips")
    # blossom emblem
    L.flower(m, P(p[1]), P(p[2]), (0, yz(pts, 0.3) + plan(0) - 0.45, 0.25), 0.55, rot=(90, 0, 0), part="Bloom")
    skin(m, P(p[2]), pts, ZB, -0.82, W - 0.3, off=0.2, thick=0.08, plan=plan, ns=13, part="Edge")
    mount_arms(m, P(p[3], "WO"), "E8B84A", pts, plan=plan, xa=1.7)


def BladeKatana(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = [(-2.6, -0.55), (-2.48, 0.3), (-2.55, 1.35)]
    shell(m, P(p[2]), stations(W, 9), profile_fn(pts), 0.24, part="Plate")
    # curved katana edge along the bottom (steel), slightly sweeping forward
    poly = []
    for i in range(13):
        t = i / 12; x = -W / 2 + W * t
        poly.append((x, -1.05 + 0.18 * (1 - (2 * t - 1) ** 2)))
    for i in range(12, -1, -1):
        t = i / 12; x = -W / 2 + W * t
        poly.append((x, -0.42 + 0.06 * (1 - (2 * t - 1) ** 2)))
    flat(m, P("E9EEF5", "ME"), poly, 0.16, (0, -2.5, 0), axis=(0, -1, 0), part="Steel")
    flat(m, P("FFE6F0", "NE"), [(x, z + 0.17) for x, z in poly[:13]] + [(x, z + 0.24) for x, z in reversed(poly[:13])], 0.03, (0, -2.66, 0), axis=(0, -1, 0), part="Hamon")
    # gold habaki band and guards (tsuba) at both ends
    box(m, P(GOLD, "ME"), (0, -2.55, -0.45), (W + 0.05, 0.36, 0.14), r=0.04, part="Gold")
    for sx in (-1, 1):
        disc(m, P(GOLD, "ME"), (sx * (W / 2 + 0.02) - (0.18 if sx > 0 else 0), -2.5, 0.35), 0.75, 0.18, axis=(1, 0, 0), seg=16, part="Gold") if False else None
        disc(m, P(GOLD, "ME"), (sx * (W / 2) , -2.5, 0.3), 0.72, 0.16, axis=(sx, 0, 0), seg=14, bev=0.04, part="Gold")
        # wrapped handle stub
        rod(m, P(p[3]), (sx * (W / 2 + 0.15), -2.5, 0.3), (sx * (W / 2 + 0.55), -2.5, 0.3), r=0.2, seg=8, part="Wrap")
        for k in range(3):
            torus(m, P(p[1]), (sx * (W / 2 + 0.24 + 0.12 * k), -2.5, 0.3), R=0.2, r=0.04, seg=8, rseg=4, rot=(0, 90, 0), part="Wrap2")
    # black lacquer top spine with gold mon
    box(m, P("2B1E1E"), (0, -2.5, 1.43), (W - 0.1, 0.5, 0.18), r=0.06, part="Spine")
    flat(m, P(GOLD, "ME"), L.flower_poly(0.35, 5, 5), 0.05, (0, yz(pts, 0.6) - 0.02, 0.6), axis=(0, -1, 0), part="Gold")
    mount_arms(m, P("2B1E1E"), STEEL, pts, xa=1.3, za=-0.2)


def BladeLollipop(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.45 * (2 * x / W) ** 2
    pts = bez((-3.3, ZB), (-2.25, 0.0), (-3.1, 1.4), 8)
    shell(m, P(p[0]), stations(W - 1.6, 13), profile_fn(pts), 0.26, plan=plan, part="Plate")
    tube(m, P(p[1]), [(x, yz(pts, 1.4) + plan(x) + 0.08, 1.42) for x in stations(W - 1.6, 9)], r=0.18, seg=10, part="Rim", smooth=3)
    skin(m, P(p[1]), pts, ZB, -0.78, W - 1.6, off=0.02, thick=0.1, plan=plan, ns=13, part="Rim")
    for x in (-2.8, -1.4, 0, 1.4, 2.8):
        sphere(m, P(p[2]), (x, yz(pts, 0.2) + plan(x) - 0.06, 0.2 + 0.25 * math.sin(x)), 0.12, seg=8, rings=5, part="Drops")
    # lollipop discs at each end (facing outwards) with swirl
    for sx in (-1, 1):
        cx = sx * (W / 2 - 0.55); cyy = -2.75; cz = 0.35
        disc(m, P(WHITE), (cx - sx * 0.2, cyy, cz), 1.05, 0.38, axis=(sx, 0, 0), seg=16, bev=0.12, part="Candy")
        sw = []
        for i in range(26):
            a = i * 0.62; r = 0.08 + 0.9 * i / 26
            sw.append((cx + sx * 0.2, cyy + r * math.cos(a), cz + r * math.sin(a)))
        tube(m, P(p[0]), sw, r=0.11, seg=5, part="Swirl", smooth=1)
        rod(m, P(WHITE), (cx, cyy + 0.8, cz - 0.6), (cx, cyy + 0.2, cz - 1.25), r=0.08, seg=6, part="Candy") if False else None
    mount_arms(m, P(p[3]), STEEL, pts, plan=plan, xa=1.4)


def BladeCaneCrusher(m, c):
    p = c["palette"]; W = c["visualWidth"]
    # chocolate bar frame with segment grid
    box(m, P(p[3]), (0, -2.45, 0.55), (W, 0.45, 1.5), r=0.1, part="Choc")
    for i in range(6):
        for j in range(2):
            x = -W / 2 + W / 6 * (i + 0.5); z = 0.2 + j * 0.72
            box(m, P("834F3B"), (x, -2.72, z), (W / 6 - 0.16, 0.12, 0.6), r=0.06, part="ChocTop")
    # candy-cane hooks as teeth (hanging down and curling forward)
    n = 8
    for i in range(n):
        x = -W / 2 + 0.6 + (W - 1.2) * i / (n - 1)
        path = [(x, -2.55, 0.05), (x, -2.65, -0.7), (x, -2.95, -1.0), (x, -3.35, -0.85), (x, -3.45, -0.5)]
        L.stripes(m, [P(WHITE), P(p[0])], path, 0.17, seglen=0.36, seg=6, part="Cane", smooth=2)
    # mint top trim + sprinkles
    tube(m, P(p[1]), [(x, -2.55, 1.32) for x in stations(W, 7)], r=0.16, seg=10, part="Mint", smooth=1)
    for x in (-3.5, -1.2, 1.2, 3.5):
        sphere(m, P(p[2], "NE"), (x, -2.7, 1.5), 0.11, seg=8, rings=5, part="Gumdrops") if False else None
    for sx in (-1, 1):
        lathe(m, P(p[1]), [(0.35, 0), (0.36, 0.1), (0.25, 0.42), (0, 0.48)], loc=(sx * (W / 2 - 0.3), -2.45, 1.32), seg=10, part="Mint")
    mount_arms(m, P(p[3]), STEEL, [(-2.2, ZB), (-2.2, 1.4)], xa=1.3)


def BladeCoral(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.5 * (2 * x / W) ** 2
    pts = bez((-3.3, ZB), (-2.2, 0.0), (-3.0, 1.35), 8)
    zt = lambda x: 1.35 + 0.18 * math.cos(x * 2.2)  # scalloped top
    shell(m, P(p[0]), stations(W, 13), lambda x: [(y, z if z < 1.0 else z + (zt(x) - 1.35) * (z - 1.0) / 0.35) for y, z in pts], 0.26, plan=plan, part="Shell")
    # radial shell ribs fanning out from the bottom centre
    for k in range(-4, 5):
        xb = k * 0.3; xt = k * (W / 9.5)
        rp = []
        for i in range(6):
            t = i / 5; z = ZB + 0.15 + t * 2.2; x = xb + (xt - xb) * t
            rp.append((x, yz(pts, z) + plan(x) - 0.05, z))
        tube(m, P(p[1]), rp, r=0.09, r2=0.14, seg=5, part="Ribs", smooth=1)
    for x in stations(W - 0.6, 9):
        sphere(m, P(p[3]), (x, yz(pts, 1.33) + plan(x) - 0.08, 1.4 + 0.15 * math.cos(x * 2.2)), 0.14, seg=6, rings=4, part="Pearls")
    # coral branches at both ends
    for sx in (-1, 1):
        x0 = sx * (W / 2 - 0.1)
        b0 = (x0, -2.6, -0.6)
        tube(m, P(p[2]), [b0, (x0 + sx * 0.3, -2.6, 0.3), (x0 + sx * 0.25, -2.7, 1.3), (x0 + sx * 0.45, -2.75, 1.95)], r=0.16, r2=0.08, seg=6, part="Coral")
        tube(m, P(p[2]), [(x0 + sx * 0.28, -2.6, 0.4), (x0 + sx * 0.75, -2.65, 0.9), (x0 + sx * 0.9, -2.7, 1.45)], r=0.11, r2=0.06, seg=6, part="Coral")
        tube(m, P(p[2]), [(x0 + sx * 0.27, -2.7, 1.1), (x0 - sx * 0.15, -2.75, 1.65), (x0 - sx * 0.1, -2.8, 2.0)], r=0.09, r2=0.05, seg=6, part="Coral")
    skin(m, P(p[1]), pts, ZB, -0.8, W - 0.2, off=0.02, thick=0.1, plan=plan, ns=15, part="Ribs")
    mount_arms(m, P(p[1]), STEEL, pts, plan=plan, xa=1.6)


def BladeTrident(m, c):
    p = c["palette"]; W = c["visualWidth"]
    D = 1.0
    plan = lambda x: -D * (1 - abs(2 * x / W))
    pts = [(-2.45, ZB), (-2.35, -0.1), (-2.4, 1.0)]
    shell(m, P(p[0], "GL"), stations(W, 11), profile_fn(pts), 0.24, plan=plan, part="Glass")
    # gold frame: prow spine, top rail, bottom edge
    G = P(GOLD, "ME")
    beam(m, G, (0, -2.45 - D - 0.12, ZB + 0.05), (0, -2.4 - D - 0.12, 1.05), w=0.3, h=0.3, part="Gold")
    for sx in (-1, 1):
        a = (0, -2.4 - D, 1.05); b = (sx * W / 2, -2.4, 1.05)
        beam(m, G, a, b, w=0.22, h=0.22, part="Gold")
        a = (0, -2.45 - D - 0.05, ZB + 0.08); b = (sx * W / 2, -2.45 - 0.05, ZB + 0.08)
        beam(m, G, a, b, w=0.24, h=0.2, part="Gold")
        # side prongs (trident tines)
        x = sx * (W / 2 - 0.1)
        tube(m, G, [(x, -2.4, 0.9), (x + sx * 0.05, -2.45, 1.6), (x + sx * 0.05, -2.5, 2.05)], r=0.11, seg=6, part="Gold", smooth=1)
        flat(m, G, [(-0.2, 0), (0.2, 0), (0, 0.45)], 0.12, (x + sx * 0.05, -2.44, 2.0), axis=(0, -1, 0), part="Gold")
        flat(m, G, [(-0.06, 0), (0.18, 0.1), (0.25, 0.4), (0.06, 0.2)], 0.1, (x + sx * 0.12, -2.44, 1.55), axis=(0, -1, 0) if sx > 0 else (0, 1, 0), part="Gold")
    # centre trident (three prongs) above the prow
    cy = -2.4 - D - 0.1
    tube(m, G, [(0, cy, 1.0), (0, cy, 2.2)], r=0.13, seg=8, part="Gold", smooth=1)
    for sx in (-1, 1):
        tube(m, G, [(0, cy, 1.45), (sx * 0.45, cy, 1.55), (sx * 0.5, cy, 1.95)], r=0.1, seg=6, part="Gold", smooth=2)
        flat(m, G, [(-0.16, 0), (0.16, 0), (0, 0.38)], 0.12, (sx * 0.5, cy + 0.06, 1.92), axis=(0, -1, 0), part="Gold")
    flat(m, G, [(-0.2, 0), (0.2, 0), (0, 0.5)], 0.14, (0, cy + 0.07, 2.15), axis=(0, -1, 0), part="Gold")
    sphere(m, P(p[2], "NE"), (0, cy - 0.12, 0.3), 0.22, seg=10, rings=6, part="Pearl")
    for sx in (-1, 1):
        sphere(m, P(p[3]), (sx * 2.2, yz(pts, 0.4) + plan(sx * 2.2) - 0.08, 0.4), 0.15, seg=8, rings=5, part="Pearls")
    mount_arms(m, P(p[1]), GOLD, pts, plan=plan, xa=1.3)


def BladeBrick(m, c):
    p = c["palette"]; W = c["visualWidth"]
    cols = [p[0], p[1], p[2], p[3]]
    u = 1.5
    rows = [(ZB + 0.38, 0.0, 8), (ZB + 1.14, 0.75, 7), (ZB + 1.9, 0.0, 6)]
    ci = 0
    for r, (z, off, n) in enumerate(rows):
        for i in range(n):
            x = -W / 2 + u / 2 + off + i * u + (0.75 * r if r == 2 else 0)
            if abs(x) > W / 2: continue
            col = cols[(i * 3 + r * 2) % 4]
            box(m, P(col), (x, -2.65 + r * 0.05, z), (u - 0.06, 0.8, 0.74), r=0.06, part="Bricks")
            if r == len(rows) - 1 or (r == 1 and (x < -2.6 or x > 2.6)):
                for k in (-0.37, 0.37):
                    cyl(m, P(col), (x + k, -2.65 + r * 0.05, z + 0.37), r=0.2, h=0.18, seg=10, part="Studs")
    for x in (-2.25, 2.25):
        for k in (-0.37, 0.37):
            pass
    box(m, P("3B3F4A"), (0, -2.1, 0.2), (W - 1.2, 0.3, 2.2), r=0.06, part="Back")
    mount_arms(m, P("3B3F4A"), STEEL, [(-2.25, ZB), (-2.25, 1.4)], xa=1.4)


def BladeBulldozer(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = bez((-3.15, ZB), (-2.3, 0.15), (-3.0, 1.55), 8)
    shell(m, P(p[2]), stations(W, 11), profile_fn(pts), 0.4, part="Plate")
    # red trim (top roll + side caps)
    tube(m, P(p[0]), [(x, yz(pts, 1.55) + 0.12, 1.58) for x in stations(W, 7)], r=0.2, seg=10, part="Trim", smooth=1)
    endplates(m, P(p[0]), pts, W, thick=0.28, back=0.7)
    skin(m, P("3B3F4A", "ME"), pts, ZB, -0.72, W, off=0.02, thick=0.14, ns=11, part="Edge")
    # big hex bolts
    for x in (-4.2, -2.1, 0, 2.1, 4.2):
        for z in (-0.45, 0.85):
            disc(m, P("3B3F4A"), (x, yz(pts, z) + 0.03, z), 0.2, 0.14, seg=6, part="Bolts")
    # heavy C-frame push arms + beacon
    box(m, P("3B3F4A"), (0, -0.15, 0), (2.1, 0.3, 0.9), r=0.1, part="Mount")
    for sx in (-1, 1):
        beam(m, P(p[2]), (sx * 0.75, -0.25, -0.1), (sx * 2.6, yz(pts, -0.4) + 0.2, -0.4), w=0.42, h=0.48, r=0.12, part="Arms", bseg=2)
        rod(m, P(STEEL, "ME"), (sx * 0.5, -0.3, 0.35), (sx * 1.2, yz(pts, 0.9) + 0.25, 0.9), r=0.09, seg=8, part="Piston")
        rod(m, P("3B3F4A"), (sx * 0.5, -0.3, 0.35), (sx * 0.85, -1.4, 0.62), r=0.15, seg=8, part="Mount")
    disc(m, P("3B3F4A"), (W / 2 - 0.6, -2.6, 1.7), 0.25, 0.15, axis=(0, 0, 1), seg=10, part="Mount")
    lathe(m, P("FF9A2E", "NE"), [(0.2, 0), (0.2, 0.2), (0.12, 0.33), (0, 0.36)], loc=(W / 2 - 0.6, -2.6, 1.85), seg=10, part="Beacon")


def BladeCog(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.25 * (2 * x / W) ** 2
    pts = bez((-3.0, ZB), (-2.4, -0.1), (-2.75, 0.9), 6)
    shell(m, P(p[0], "ME"), stations(W - 1.2, 15), profile_fn(pts), 0.24, plan=plan, part="Plate")
    for z in (-0.55, 0.45):
        skin(m, P(p[1], "ME"), pts, z - 0.11, z + 0.11, W - 1.3, off=0.02, thick=0.06, plan=plan, ns=13, part="Bands")
        for x in stations(W - 1.8, 11):
            disc(m, P(p[3]), (x, yz(pts, z) + plan(x) - 0.08, z), 0.06, 0.05, seg=6, part="Rivets")
    # half-cog end plates
    for sx in (-1, 1):
        x = sx * (W / 2 - 0.55)
        half = [pt for pt in gear_poly(14, 1.45, 1.15, 0.45) if pt[0] * sx * -1 <= 0.0001 or True]
        flat(m, P(p[1], "ME"), gear_poly(12, 1.2, 0.98, 0.45), 0.24, (x - 0.12, -2.55, 0.12), axis=(1, 0, 0), part="Cogs")
        disc(m, P(p[2]), (x + sx * 0.12, -2.55, 0.12), 0.45, 0.1, axis=(sx, 0, 0), seg=12, part="Hubs")
        disc(m, P(p[3]), (x + sx * 0.2, -2.55, 0.12), 0.2, 0.08, axis=(sx, 0, 0), seg=8, part="Rivets")
    tube(m, P(p[1], "ME"), [(x, yz(pts, 0.9) + plan(x) + 0.06, 0.92) for x in stations(W - 1.2, 9)], r=0.11, seg=8, part="Bands", smooth=3)
    mount_arms(m, P(p[3]), STEEL, pts, plan=plan, xa=1.7)


def BladeGearbreaker(m, c):
    p = c["palette"]; W = c["visualWidth"]
    box(m, P(p[3], "ME"), (0, -2.35, 0.45), (W, 0.35, 1.9), r=0.1, part="Frame")
    box(m, P(p[0], "ME"), (0, -2.45, 1.45), (W + 0.2, 0.6, 0.24), r=0.08, part="Brass")
    # row of interlocking gears (faces -Y), alternating size/colour and phase
    gears = [(-4.15, -0.05, 0.85, 0), (-2.55, -0.25, 1.0, 1), (-0.85, -0.05, 0.85, 0), (0.85, -0.25, 1.0, 1), (2.55, -0.05, 0.85, 0), (4.15, -0.25, 0.95, 1)]
    for x, z, r, k in gears:
        z = ZB + r + 0.0 if k else ZB + r + 0.2
        col = P(p[2]) if k else P(p[0], "ME")
        n = 10 if k else 9
        flat(m, col, gear_poly(n, r, r - 0.24, 0.42, a0=(0.3 if k else 0)), 0.3, (x, -2.55 - k * 0.1, z), axis=(0, -1, 0), part="Gears")
        disc(m, P(p[1], "ME"), (x, -2.85 - k * 0.1, z), r * 0.42, 0.12, seg=10, part="Hubs")
        disc(m, P(p[3]), (x, -2.97 - k * 0.1, z), r * 0.16, 0.06, seg=6, part="Axles")
    flat(m, P(p[2], "NE"), circle_poly(0.16, 8), 0.04, (0, -2.65, 1.2), axis=(0, -1, 0), part="Glow") if False else None
    box(m, P(p[2], "NE"), (0, -2.78, 1.45), (W - 1.0, 0.06, 0.08), r=0.02, part="Glow")
    mount_arms(m, P(p[3]), STEEL, [(-2.2, ZB), (-2.2, 1.4)], xa=1.4)


def BladeCumulus(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.3 * (2 * x / W) ** 2
    pts = bez((-3.0, ZB), (-2.45, -0.15), (-2.75, 0.75), 6)
    shell(m, P(p[0]), stations(W - 0.6, 11), profile_fn(pts), 0.26, plan=plan, part="Cloud")
    rnd = [0.6, 0.8, 0.7, 0.9, 0.75, 0.9, 0.7, 0.8, 0.6]
    for i, r in enumerate(rnd):
        x = -W / 2 + 0.7 + (W - 1.4) * i / (len(rnd) - 1)
        sphere(m, P(p[0]), (x, yz(pts, 0.7) + plan(x) + 0.12, 0.72 + r * 0.35), r, seg=9, rings=6, part="Cloud")
    for sx in (-1, 1):
        sphere(m, P(p[0]), (sx * (W / 2 - 0.3), -2.7, -0.1), 0.75, seg=10, rings=6, part="Cloud")
        sphere(m, P(p[1]), (sx * (W / 2 - 0.3), -2.85, -0.65), 0.45, seg=10, rings=6, part="Shade")
    skin(m, P(p[2], "ME"), pts, ZB, -0.8, W - 0.6, off=0.02, thick=0.1, plan=plan, ns=15, part="Gold")
    tube(m, P(p[2], "ME"), [(x, yz(pts, 0.3) + plan(x) - 0.06, 0.3) for x in stations(W - 2.2, 9)], r=0.07, seg=6, part="Gold", smooth=3)
    for x in (-3.0, 0, 3.0):
        flat(m, P(p[2], "ME"), star_poly(4, 0.3, 0.1), 0.05, (x, yz(pts, -0.25) + plan(x) - 0.05, -0.25), axis=(0, -1, 0), part="Gold")
    mount_arms(m, P(p[1]), STEEL, pts, plan=plan, xa=1.7)


def BladeThunder(m, c):
    p = c["palette"]; W = c["visualWidth"]
    D = 1.05
    plan = lambda x: -D * (1 - abs(2 * x / W))
    pts = [(-2.45, ZB), (-2.35, -0.1), (-2.35, 0.7), (-2.5, 1.35)]
    shell(m, P(p[1]), stations(W, 11), profile_fn(pts), 0.26, plan=plan, part="Plate")
    skin(m, P(p[0]), pts, 0.55, 1.35, W, off=0.02, thick=0.06, plan=plan, ns=11, part="Top")
    # glowing yellow seam down the prow + along the top
    beam(m, P(p[3], "NE"), (0, -2.45 - D - 0.02, ZB + 0.1), (0, -2.5 - D - 0.02, 1.3), w=0.12, h=0.08, r=0.02, part="Seam")
    # lightning-bolt fins on the wings
    for sx in (-1, 1):
        for x, h in ((sx * 1.6, 1.0), (sx * 3.4, 1.25)):
            flat(m, P(p[2], "ME"), bolt_poly(0.7 * sx if False else 0.75, h), 0.14, (x, yz(pts, 1.35) + plan(x) + 0.12, 1.3 + h * 0.5), axis=(0, -1, 0), part="Bolts")
        x = sx * W / 2
        flat(m, P(p[2], "ME"), [(-0.0, -0.9), (0.55 * sx, 0.0), (0.0, 0.9)], 0.16, (x, -2.4, 0.3), axis=(0, 1, 0), part="Bolts") if False else None
    skin(m, P(p[2], "ME"), pts, ZB, -0.8, W, off=0.02, thick=0.1, plan=plan, ns=11, part="Bolts")
    endplates(m, P(p[0]), pts, W, thick=0.2, back=0.4, plan=plan)
    mount_arms(m, P("5E7FA3"), STEEL, pts, plan=plan, xa=1.3)


def BladeComet(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.5 * (2 * x / W) ** 2
    pts = bez((-3.35, ZB), (-2.25, 0.0), (-3.15, 1.45), 8)
    shell(m, P(p[0]), stations(W, 15), profile_fn(pts), 0.26, plan=plan, part="Plate")
    # comet tail sweeping from the right end over the top to the left
    tail = []
    for i in range(16):
        t = i / 15; x = W / 2 - 0.6 - (W - 0.4) * t
        z = 1.55 + 0.55 * math.sin(math.pi * t * 0.9) - 0.25 * t
        tail.append((x, yz(pts, 1.4) + plan(x) - 0.1 + 0.2 * t, z))
    tube(m, P(p[2]), tail, r=0.5, r2=0.05, seg=8, part="Tail", smooth=1)
    tube(m, P(p[1]), [(x, y - 0.2, z - 0.32) for x, y, z in tail[:12]], r=0.24, r2=0.03, seg=8, part="Tail2", smooth=2)
    sphere(m, P(p[3], "NE"), tail[0], 0.62, seg=12, rings=8, part="Head")
    # star studs
    for x, z in ((-3.8, 0.1), (-2.0, 0.7), (-0.4, -0.2), (1.4, 0.55), (3.2, -0.1), (-1.0, -0.75), (2.2, -0.7)):
        flat(m, P(p[2]), star_poly(5, 0.24, 0.1), 0.06, (x, yz(pts, z) + plan(x) - 0.04, z), axis=(0, -1, 0), part="Stars")
    skin(m, P(p[1]), pts, ZB, -0.8, W - 0.2, off=0.02, thick=0.1, plan=plan, ns=15, part="Edge")
    endplates(m, P(p[1]), pts, W, thick=0.18, back=0.45, plan=plan)
    mount_arms(m, P("2A2160"), STEEL, pts, plan=plan, xa=1.5)


def BladeGalaxy(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.35 * (2 * x / W) ** 2
    pts = [(-2.6, ZB), (-2.45, 0.0), (-2.55, 1.2)]
    shell(m, P(p[0]), stations(W, 13), profile_fn(pts), 0.26, plan=plan, part="Plate")
    # galaxy disc in the centre with spiral arms
    cz = 0.45; cy = -2.65 + plan(0) - 0.25
    disc(m, P("2A2160"), (0, cy + 0.2, cz), 1.35, 0.25, seg=24, bev=0.08, part="Disc")
    for k in range(3):
        arm = []
        for i in range(14):
            t = i / 13; a = k * 2.094 + t * 3.4; r = 0.15 + 1.05 * t
            arm.append((r * math.cos(a), cy - 0.02, cz + r * math.sin(a)))
        tube(m, P(p[1]), arm, r=0.13, r2=0.03, seg=6, part="Swirl", smooth=1, sq=0.5)
    sphere(m, P(p[2], "NE"), (0, cy - 0.05, cz), 0.3, seg=12, rings=8, part="Core")
    torus(m, P(p[3], "ME"), (0, cy - 0.1, cz), R=1.75, r=0.09, seg=28, rseg=6, rot=(75, 20, 0), part="Orbit")
    sphere(m, P(p[3], "NE"), (1.75 * math.cos(0.6), cy - 0.1 - 0.4, cz + 1.0), 0.15, seg=8, rings=5, part="Moon") if False else None
    # violet crystal teeth along the bottom
    for i in range(9):
        x = -W / 2 + 0.6 + (W - 1.2) * i / 8
        if abs(x) < 0.9: continue
        crystal(m, P(p[1], "GL"), (x, yz(pts, -0.8) + plan(x) + 0.05, -0.8), (x + 0.1 * x / abs(x), yz(pts, -0.8) + plan(x) - 0.6, -1.0), 0.22, seg=5, part="Teeth")
        if i % 2 == 0:
            crystal(m, P(p[1], "GL"), (x, yz(pts, 1.1) + plan(x) + 0.1, 1.1), (x + 0.15 * x / abs(x), yz(pts, 1.1) + plan(x) - 0.1, 1.85), 0.18, seg=5, part="Teeth")
    for x, z in ((-3.2, 0.5), (3.0, 0.2), (-2.0, -0.2), (2.0, 0.9), (4.2, 0.8), (-4.3, 0.95)):
        flat(m, P(p[2]), star_poly(4, 0.18, 0.06), 0.05, (x, yz(pts, z) + plan(x) - 0.03, z), axis=(0, -1, 0), part="Stars")
    endplates(m, P(p[3], "ME"), pts, W, thick=0.18, back=0.4, plan=plan)
    mount_arms(m, P("2A2160"), STEEL, pts, plan=plan, xa=1.4)

