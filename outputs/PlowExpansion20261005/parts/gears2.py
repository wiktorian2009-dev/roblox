# gears2.py - the 15 rebalance running-gear sets (2026-10-05). Same contract as gears.py: origin = chassis ground centre,
# ground contact z = 0, left/right assemblies between |x| 2.63 and 3.6, y -3.8..3.9, wheel centres y -2.3 / +2.5, tops <= 1.97.
import math
from mathutils import Vector
from partlib import *
from gears import FY, RY, WHEELS, axle, hubcap, strut, track_side


def GearGraveRollers(m, c):
    p = c["palette"]
    R, w, xc = 0.86, 0.9, 3.05
    for sx, y in WHEELS:
        tire(m, P("2A2236"), (sx * xc, y, R), R, w, seg=16, bulge=0.16)
        for k in range(10):   # tombstone tread blocks
            a = 2 * math.pi * k / 10
            ctr = Vector((sx * xc, y + (R - 0.02) * math.cos(a), R + (R - 0.02) * math.sin(a)))
            flat(m, P("8E8AA0"), arch_poly(0.34, 0.42), w * 0.75, ctr - Vector((sx * w * 0.375, 0, 0)), axis=(sx, 0, 0), up=(0, -math.sin(a), math.cos(a)), part="Stones")
        hubcap(m, P(p[1]), sx, y, R, xc + w / 2 - 0.04, 0.48, h=0.1, seg=12, part="Rim")
        hubcap(m, P(p[3], "NE"), sx, y, R, xc + w / 2 + 0.05, 0.15, h=0.06, seg=8, part="Glow")
        axle(m, P(DARK), sx, y, R, xc)


def GearShardTreads(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.8, 0.64), (3.05, 0.8, 0.64), (-1.4, 0.46, 0.32), (0.1, 0.46, 0.32), (1.6, 0.46, 0.32)]
        poly = track_side(m, sx, wh, 3.1, 0.86, 0.15, P("4A5470"), None, P(p[3]))
        for k in range(14):   # crystal-shard cleats along the top run
            yy = -2.7 + k * 0.42
            crystal(m, P(p[0], "GL"), (sx * 3.1, yy, 1.42), (sx * 3.1, yy + 0.08, 1.72), 0.1, seg=5, part="Shards")
        for y in (-1.4, 1.6): axle(m, P(DARK), sx, y, 0.75, 2.75, r=0.13)


def GearPrismSkids(m, c):
    p = c["palette"]
    for sx, y in WHEELS:
        x = sx * 3.0
        flat(m, P(p[0], "GL"), [(-1.1, 0.0), (0.9, 0.0), (1.25, 0.35), (0.9, 0.22), (-1.1, 0.22)], 0.42, (x - 0.21, y, 0.02), axis=(1, 0, 0), up=(0, 0, 1), part="Prism")
        crystal(m, P(p[1], "NE"), (x, y - 0.2, 0.25), (x, y - 0.2, 0.95), 0.12, seg=6, part="Shards")
        strut(m, P("3D4766"), sx, y, 0.3, 1.25, x0=2.2, x1=2.95, part="Struts")
        axle(m, P(DARK), sx, y, 1.2, 2.95)


def GearJoypad(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.0, 0.7, 0.6), (2.2, 0.7, 0.6), (0.1, 0.45, 0.38)]
        track_side(m, sx, wh, 3.05, 0.92, 0.16, P("2B2B3A"), P(p[1]), P(p[3]))
        x = sx * 3.55
        flat(m, P(p[0]), [(-0.42, -0.14), (-0.14, -0.14), (-0.14, -0.42), (0.14, -0.42), (0.14, -0.14), (0.42, -0.14), (0.42, 0.14), (0.14, 0.14), (0.14, 0.42), (-0.14, 0.42), (-0.14, 0.14), (-0.42, 0.14)], 0.08, (x, -2.0, 0.7), axis=(sx, 0, 0), part="DPad")
        for k, col in enumerate((p[1], p[2])): disc(m, P(col, "NE"), (x, 2.2 + (k - 0.5) * 0.4, 0.7 + (0.5 - k) * 0.3), 0.15, 0.08, axis=(sx, 0, 0), seg=10, part="Buttons")
        for y in (-1.0, 1.2): axle(m, P(DARK), sx, y, 0.7, 2.7, r=0.13)


def GearRootCrawler(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.82, 0.66), (2.9, 0.82, 0.66), (-1.3, 0.47, 0.33), (0.4, 0.47, 0.33), (1.8, 0.47, 0.33)]
        poly = track_side(m, sx, wh, 3.1, 0.88, 0.15, P("6B4A2E"), P("4A3220"), P(p[1]))
        for k in range(7):   # woven roots over the guard
            yy = -2.6 + k * 0.85
            tube(m, P("8A5A33"), [(sx * 2.7, yy, 1.45), (sx * 3.1, yy + 0.3, 1.62), (sx * 3.5, yy + 0.55, 1.45)], r=0.08, seg=5, part="Roots", smooth=2)
        for y in (-2.0, 0.0, 2.0): flat(m, P(p[0]), leaf_poly(0.9, 0.45), 0.04, (sx * 3.58, y, 0.95), axis=(sx, 0, 0), part="Leaves")
        for y in (-1.3, 1.8): axle(m, P(DARK), sx, y, 0.78, 2.75, r=0.13)


def GearFrostbite(m, c):
    p = c["palette"]
    R, w, xc = 0.8, 0.78, 3.0
    for sx, y in WHEELS:
        tire(m, P("BFE6FF", "IC"), (sx * xc, y, R), R, w, seg=16)
        for k in range(12):   # frost-crystal studs
            a = 2 * math.pi * k / 12
            d = Vector((0, math.cos(a), math.sin(a)))
            b = Vector((sx * xc, y, R)) + d * (R - 0.04)
            crystal(m, P("F4FBFF", "IC"), b, b + d * 0.2, 0.07, seg=5, part="Studs")
        hubcap(m, P(p[1], "ME"), sx, y, R, xc + w / 2 - 0.03, 0.42, h=0.1, seg=12, part="Rim")
        flat(m, P(p[0]), star_poly(6, 0.3, 0.12), 0.05, (sx * (xc + w / 2 + 0.06), y, R), axis=(sx, 0, 0), part="Flake")
        axle(m, P(DARK), sx, y, R, xc)


def GearAurora(m, c):
    p = c["palette"]
    for sx, y in WHEELS:
        c0 = (sx * 3.05, y, 0.75)
        disc(m, P("C9D6E6", "ME"), c0, 0.6, 0.24, axis=(0, 0, 1), seg=18, bev=0.06, part="Disc")
        torus(m, P(p[1], "NE"), (c0[0], c0[1], 0.6), R=0.52, r=0.07, seg=18, rseg=5, part="Ring")
        for k, col in enumerate(("7CFFB2", "B79CFF", "6FE7FF")):   # trailing aurora ribbons
            tube(m, P(col, "NE" if k == 0 else "SP"), [(c0[0] + sx * 0.1 * (k - 1), y + 0.5, 0.85 + 0.1 * k), (c0[0] + sx * 0.1 * (k - 1), y + 0.9, 0.95 + 0.12 * k), (c0[0] + sx * 0.1 * (k - 1), y + 1.2, 0.8 + 0.1 * k)], r=0.05, seg=5, part="Ribbons", smooth=2)
        strut(m, P(p[1]), sx, y, 1.35, 0.9, x0=2.2, x1=2.9)


def GearKoiFin(m, c):
    p = c["palette"]
    R, w, xc = 0.92, 0.88, 3.05
    for sx, y in WHEELS:
        lathe(m, P("FFF6FA"), [(R * 0.5, -w / 2), (R * 0.75, -w / 2), (R * 0.95, -w * 0.3), (R, 0), (R * 0.95, w * 0.3), (R * 0.75, w / 2), (R * 0.5, w / 2)],
              loc=(sx * xc, y, R), seg=18, rot=(0, 90, 0), part="Roller")
        for k in range(4):   # koi patches
            a = 2 * math.pi * k / 4 + 0.4
            sphere(m, P(p[2] if k % 2 else "FF8A3D"), (sx * (xc + 0.2), y + R * 0.9 * math.cos(a), R + R * 0.9 * math.sin(a)), 0.22, scl=(0.5, 1.0, 1.0), seg=8, rings=5, part="Spots")
        flat(m, P(p[0]), petal_poly(0.6, 0.5), 0.05, (sx * (xc + w / 2 + 0.05), y + 0.3, R + 0.1), axis=(sx, 0, 0), spin=0.6, part="Fins")
        axle(m, P("5A3A2E"), sx, y, R, xc)


def GearLollipop(m, c):
    p = c["palette"]
    R, w, xc = 0.8, 0.5, 2.95
    for sx, y in WHEELS:
        disc(m, P("FFF2F8"), (sx * xc, y, R), R, w, axis=(sx, 0, 0), seg=18, bev=0.08, part="Candy")
        for k in range(3):   # swirl rings
            torus(m, P([p[0], p[1], p[2]][k]), (sx * (xc + w / 2 + 0.01), y, R), R=R * (0.3 + 0.22 * k), r=0.06, seg=18, rseg=4, rot=(0, 90, 0), part="Swirl")
        rod(m, P("FFFFFF"), (sx * 2.2, y, R), (sx * (xc + w / 2 + 0.25), y, R), r=0.09, seg=8, part="Stick")
    for y in (FY, RY): rod(m, P(DARK), (-2.2, y, 0.8), (2.2, y, 0.8), r=0.1, seg=8, part="Axle")


def GearLicorice(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.0, 0.72, 0.62), (2.2, 0.72, 0.62), (0.1, 0.46, 0.36)]
        poly = track_side(m, sx, wh, 3.05, 0.9, 0.17, P("1E1418"), None, P(p[0]))
        for k in range(3):   # braided licorice ropes
            off = (k - 1) * 0.26
            tube(m, P("2A1A20" if k != 1 else "E8443A"), [(sx * (3.05 + off), y, z + 0.06 * math.sin(i * 1.5 + k)) for i, (y, z) in enumerate(poly[::2])], r=0.07, seg=5, part="Braid", smooth=1, closed=True)
        for y in (-1.0, 1.2): axle(m, P(DARK), sx, y, 0.7, 2.7, r=0.13)


def GearBubbleHover(m, c):
    p = c["palette"]
    for sx, y in WHEELS:
        c0 = Vector((sx * 3.05, y, 0.8))
        sphere(m, P("BFF5FF", "GL", 0.35), c0, 0.6, seg=14, rings=8, part="Bubble")
        disc(m, P(p[0]), (c0.x, c0.y, 0.32), 0.62, 0.14, axis=(0, 0, 1), seg=14, part="Shell")
        lathe(m, P("FF7A5C"), [(0.5, 0), (0.62, 0.1), (0.3, 0.3), (0, 0.32)], loc=(c0.x, c0.y, 0.06), seg=12, rib=(10, 0.06), part="Shell")
        sphere(m, P("FFF4E6", "NE"), (c0.x, c0.y, 0.85), 0.14, seg=8, rings=5, part="Pearl")
        strut(m, P(p[1]), sx, y, 1.35, 1.0, x0=2.2, x1=2.85)


def GearYoyo(m, c):
    p = c["palette"]
    R, xc = 0.86, 3.05
    for sx, y in WHEELS:
        for k, off in enumerate((-0.28, 0.28)):   # two yo-yo halves
            lathe(m, P(p[0] if k else p[1]), [(0.2, 0), (R, 0.08), (R, 0.24), (0.3, 0.3)], loc=(sx * (xc + off * (1 if k else -1)), y, R), rot=(0, 90 * (1 if k else -1) * sx, 0), seg=18, part="Halves")
        torus(m, P("FFFFFF"), (sx * xc, y, R), R=0.22, r=0.06, seg=12, rseg=4, rot=(0, 90, 0), part="String")
        for k in range(5):
            a = 2 * math.pi * k / 5
            sphere(m, P(p[2], "NE"), (sx * (xc + 0.33), y + 0.55 * math.cos(a), R + 0.55 * math.sin(a)), 0.07, seg=6, rings=4, part="Stars")
        axle(m, P(DARK), sx, y, R, xc)


def GearRatchet(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.8, 0.64), (2.9, 0.8, 0.64), (-1.45, 0.46, 0.32), (0.05, 0.46, 0.32), (1.55, 0.46, 0.32)]
        poly = track_side(m, sx, wh, 3.1, 0.86, 0.15, P(p[0], "ME"), P(p[1], "ME"), P("3B3F4A"), spacing=0.36, ch=0.14)
        for (yy, z, r) in wh[:2]:
            flat(m, P(p[1], "ME"), gear_poly(12, r + 0.1, r - 0.05, 0.5), 0.07, (sx * 3.52, yy, z), axis=(sx, 0, 0), part="Ratchets")
        beam(m, P(p[2], "ME"), (sx * 3.1, -2.6, 1.68), (sx * 3.1, 2.7, 1.68), w=0.9, h=0.08, r=0.03, part="Guard")
        for y in (-1.45, 1.55): axle(m, P(DARK), sx, y, 0.75, 2.75, r=0.13)


def GearPendulum(m, c):
    p = c["palette"]
    for sx, y in WHEELS:
        x = sx * 3.05
        flat(m, P(p[0], "ME"), [(-1.2, 0.0), (1.0, 0.0), (1.3, 0.3), (1.05, 0.18), (-1.2, 0.18)], 0.36, (x - 0.18, y, 0.02), axis=(1, 0, 0), up=(0, 0, 1), part="Skis")
        rod(m, P(p[1], "ME"), (x, y, 0.2), (x, y, 1.45), r=0.07, seg=6, part="Pendulum")
        disc(m, P(p[2], "ME"), (x + sx * 0.05, y, 0.75), 0.3, 0.07, axis=(sx, 0, 0), seg=14, part="Bob")
        strut(m, P("3B3F4A"), sx, y, 1.45, 1.45, x0=2.2, x1=3.0, part="Struts")


def GearNimbus(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.92, 0.58), (3.05, 0.72, 0.56), (-1.5, 0.47, 0.32), (0.0, 0.47, 0.32), (1.5, 0.47, 0.32)]
        poly = track_side(m, sx, wh, 3.07, 0.94, 0.16, P("F7F9FF"), None, P(p[2], "ME"), wheel_w=0.6)
        puff(m, P("FFFFFF"), [(sx * 3.07, -2.2, 1.48, 0.38), (sx * 3.07, -0.8, 1.52, 0.42), (sx * 3.07, 0.7, 1.52, 0.42), (sx * 3.07, 2.2, 1.46, 0.38)], part="Clouds")
        for y in (-1.5, 1.5): axle(m, P(p[2], "ME"), sx, y, 0.8, 2.7, r=0.13)
