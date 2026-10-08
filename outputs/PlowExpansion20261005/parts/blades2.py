# blades2.py - the 15 rebalance blades (2026-10-05). Same contract as blades.py: origin = back-centre of the mount bracket,
# front = -Y, bottom edge z = -1.05, widths within the existing 9..13.5 stud range (the vehicle width cap is unchanged).
import math
from mathutils import Vector
from partlib import *
from blades import ZB, yz, sub, skin, mount_arms, endplates, bolts, back_ribs, skids


def BladeBonechill(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.45 * (2 * x / W) ** 2
    pts = bez((-3.2, ZB), (-2.25, 0.05), (-3.05, 1.35), 8)
    shell(m, P(p[0]), stations(W, 15), profile_fn(pts), 0.22, plan=plan, part="Plate")
    for i in range(7):   # ribcage ribs over the face
        x = -W / 2 + 0.9 + (W - 1.8) * i / 6
        tube(m, P(p[2]), [(x, yz(pts, z) + plan(x) - 0.08, z) for z in (-0.8, -0.2, 0.4, 1.0)], r=0.11, seg=6, part="Ribs", smooth=2)
    tube(m, P(p[3], "NE"), [(x, yz(pts, 1.35) + plan(x) - 0.02, 1.4) for x in stations(W - 0.4, 9)], r=0.07, seg=6, part="Wisp", smooth=3)
    skin(m, P(STEEL, "ME"), pts, ZB, -0.78, W - 0.3, off=0.02, thick=0.09, plan=plan, ns=15, part="Edge")
    endplates(m, P(p[2]), pts, W, thick=0.2, back=0.45, plan=plan)
    mount_arms(m, P("2B2140"), STEEL, pts, plan=plan, xa=1.6)


def BladeGeodeShovel(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = bez((-3.0, ZB), (-2.45, 0.2), (-2.9, 1.25), 7)
    shell(m, P(p[3]), stations(W, 13), profile_fn(pts), 0.26, part="Plate")
    for i, x in enumerate((-3.2, -1.1, 1.1, 3.2)):   # split geodes with crystal interiors
        y = yz(pts, 0.25) - 0.18
        disc(m, P("5B6378"), (x, y, 0.25), 0.78, 0.14, axis=(0, -1, 0), seg=10, part="Geode")
        disc(m, P(p[0], "GL" if i % 2 else "NE"), (x, y - 0.08, 0.25), 0.52, 0.1, axis=(0, -1, 0), seg=8, part="Core")
        for k in range(5):
            a = 2 * math.pi * k / 5 + i
            crystal(m, P(p[1]), (x + 0.3 * math.cos(a), y - 0.1, 0.25 + 0.3 * math.sin(a)), (x + 0.38 * math.cos(a), y - 0.42, 0.25 + 0.38 * math.sin(a)), 0.08, seg=5, part="Shards")
    skin(m, P(STEEL, "ME"), pts, ZB, -0.75, W - 0.1, off=0.02, thick=0.1, ns=13, part="Edge")
    endplates(m, P(p[3]), pts, W, thick=0.2, back=0.45)
    mount_arms(m, P(p[3]), STEEL, pts, xa=1.5)


def BladeAmethyst(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: 0.9 * abs(2 * x / W) - 0.9   # V-wedge: centre forward
    pts = bez((-2.95, ZB), (-2.4, 0.15), (-2.75, 1.2), 7)
    shell(m, P("6B4FA8"), stations(W, 15), profile_fn(pts), 0.28, plan=plan, part="Plate")
    for k in range(4):   # stacked amethyst slabs
        z = -0.65 + k * 0.5
        skin(m, P("B48CFF" if k % 2 else "8E5BE8", "GL"), pts, z, z + 0.4, W - 0.6 - k * 0.5, off=0.02, thick=0.06, plan=plan, ns=15, part="Slabs")
    rod(m, P(STEEL, "ME"), (0, yz(pts, ZB) + plan(0) - 0.15, ZB + 0.1), (0, yz(pts, 1.2) + plan(0) - 0.1, 1.3), r=0.14, seg=8, part="Spine")
    for sx in (-1, 1): crystal(m, P(p[1], "NE"), (sx * W / 2, yz(pts, 1.1) + plan(sx * W / 2), 1.1), (sx * (W / 2 + 0.2), yz(pts, 1.1) + plan(sx * W / 2) - 0.2, 1.9), 0.18, seg=6, part="Tips")
    mount_arms(m, P(p[3]), STEEL, pts, plan=plan, xa=1.4)


def BladeJoystick(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = [(-3.0, ZB), (-2.85, -0.4), (-2.7, 0.2), (-2.7, 0.8), (-2.85, 1.2)]
    shell(m, P(p[3]), stations(W, 12), profile_fn(pts), 0.3, part="Plate")
    for i in range(11):   # pixel steps along the top
        x = -W / 2 + 0.5 + i * (W - 1) / 10
        box(m, P(p[0] if i % 2 else p[1]), (x, -2.95, 1.25 + (i % 3) * 0.12), (0.9, 0.5, 0.35), r=0.02, part="Pixels")
    for i in range(6):   # arcade buttons
        x = -W / 2 + 1.5 + i * (W - 3) / 5
        disc(m, P([p[0], p[1], p[2]][i % 3], "NE" if i % 3 == 0 else "SP"), (x, yz(pts, 0.35) - 0.04, 0.35), 0.3, 0.14, axis=(0, -1, 0), seg=12, part="Buttons")
    for sx in (-1, 1):
        rod(m, P("1E1E2E"), (sx * W / 2, -2.6, 0.2), (sx * W / 2, -2.6, 1.9), r=0.12, seg=8, part="Sticks")
        sphere(m, P(p[0]), (sx * W / 2, -2.6, 2.0), 0.3, seg=10, rings=6, part="Ball")
    skin(m, P(STEEL, "ME"), pts, ZB, -0.78, W - 0.1, off=0.02, thick=0.1, ns=12, part="Edge")
    mount_arms(m, P(p[3]), STEEL, pts, xa=1.8)


def BladeCanopy(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.5 * (2 * x / W) ** 2
    pts = bez((-3.25, ZB), (-2.3, 0.0), (-3.15, 1.4), 8)
    shell(m, P(p[3]), stations(W, 15), profile_fn(pts), 0.2, plan=plan, part="Plate")
    for i in range(9):   # overlapping fronds
        x = -W / 2 + 0.7 + (W - 1.4) * i / 8
        z = 0.1 + 0.25 * math.sin(i * 1.7)
        flat(m, P(p[0] if i % 2 else "57D468"), leaf_poly(1.9, 0.9), 0.05, (x, yz(pts, z) + plan(x) - 0.08, z - 0.8), axis=(0, -1, 0), spin=math.radians(-8 + i * 2), part="Fronds")
    for z in (-0.6, 0.6): tube(m, P("C8A15A"), [(x, yz(pts, z) + plan(x) + 0.25, z) for x in stations(W, 9)], r=0.09, seg=6, part="Bamboo", smooth=3)
    skin(m, P("8A5A33"), pts, ZB, -0.8, W - 0.3, off=0.02, thick=0.09, plan=plan, ns=15, part="Edge")
    mount_arms(m, P("2E5E2A"), STEEL, pts, plan=plan, xa=1.7)


def BladeFrostbite(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = bez((-2.85, ZB + 0.2), (-2.35, 0.25), (-2.75, 1.25), 7)
    shell(m, P("C9E6FF", "IC"), stations(W, 13), profile_fn(pts), 0.32, part="Plate")
    for i in range(10):   # icicle teeth hanging below the edge
        x = -W / 2 + 0.45 + (W - 0.9) * i / 9
        crystal(m, P("EAF7FF", "IC"), (x, yz(pts, ZB + 0.25) - 0.05, ZB + 0.3), (x, yz(pts, ZB + 0.25) - 0.15, ZB - 0.0), 0.16, seg=5, part="Icicles")
    for k in range(3): rod(m, P(p[1], "ME"), (-W / 2 + 0.3, yz(pts, 0.2 + k * 0.35) - 0.02, 0.2 + k * 0.35), (W / 2 - 0.3, yz(pts, 0.2 + k * 0.35) - 0.02, 0.2 + k * 0.35), r=0.05, seg=6, part="Frost")
    endplates(m, P(p[1]), pts, W, thick=0.22, back=0.5)
    mount_arms(m, P(p[1]), STEEL, pts, xa=1.35)


def BladePolar(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.38 * (2 * x / W) ** 2
    pts = bez((-3.05, ZB), (-2.45, -0.1), (-2.9, 0.95), 6)
    shell(m, P("F7FBFF"), stations(W, 17), profile_fn(pts), 0.22, plan=plan, part="Plate")
    for z in (-0.35, 0.45): skin(m, P(p[1]), pts, z, z + 0.2, W - 0.4, off=0.02, thick=0.04, plan=plan, ns=17, part="Stripes")
    for i in range(7):
        x = -W / 2 + 1.0 + (W - 2) * i / 6
        flat(m, P(p[3], "NE" if i == 3 else "SP"), star_poly(6, 0.25, 0.1), 0.05, (x, yz(pts, 0.05) + plan(x) - 0.06, 0.05), axis=(0, -1, 0), part="Flakes")
    skin(m, P(STEEL, "ME"), pts, ZB, -0.75, W - 0.1, off=0.02, thick=0.1, plan=plan, ns=17, part="Edge")
    skids(m, P(p[1]), [-W / 2 + 0.35, W / 2 - 0.35], y0=yz(pts, ZB) + plan(W / 2) - 0.05, y1=yz(pts, ZB) + plan(W / 2) + 1.0)
    mount_arms(m, P(p[1]), STEEL, pts, plan=plan, xa=1.9)


def BladeLotus(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: 0.8 * abs(2 * x / W) - 0.8
    pts = bez((-2.95, ZB), (-2.35, 0.2), (-2.7, 1.25), 7)
    shell(m, P("3A2A30"), stations(W, 15), profile_fn(pts), 0.26, plan=plan, part="Plate")
    for i in range(7):   # opening lotus petals
        x = -W / 2 + 0.8 + (W - 1.6) * i / 6
        z = 0.3 + 0.35 * (1 - abs(i - 3) / 3)
        flat(m, P(p[0] if i % 2 else "FF8FB8"), petal_poly(1.6, 0.85), 0.05, (x, yz(pts, z) + plan(x) - 0.1, z - 0.6), axis=(0, -1, 0), spin=math.radians((i - 3) * 9), part="Petals")
    sphere(m, P(p[2], "NE"), (0, yz(pts, 0.2) + plan(0) - 0.3, 0.2), 0.3, seg=10, rings=6, part="Heart")
    skin(m, P("D4AF37", "ME"), pts, ZB, -0.78, W - 0.3, off=0.02, thick=0.09, plan=plan, ns=15, part="Edge")
    mount_arms(m, P("3A2A30"), STEEL, pts, plan=plan, xa=1.5)


def BladeGumdrop(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.3 * (2 * x / W) ** 2
    pts = bez((-3.0, ZB), (-2.5, -0.15), (-2.85, 0.9), 6)
    shell(m, P("D9A066"), stations(W, 17), profile_fn(pts), 0.24, plan=plan, part="Wafer")
    for k in range(4): skin(m, P("B97E45"), pts, -0.7 + k * 0.42, -0.62 + k * 0.42, W - 0.2, off=0.02, thick=0.03, plan=plan, ns=17, part="Grid")
    cols = [p[0], p[1], p[2], "FF9A3D", "9B6BFF"]
    for i in range(10):   # gumdrops along the top
        x = -W / 2 + 0.6 + (W - 1.2) * i / 9
        lathe(m, P(cols[i % 5], "GL"), [(0.36, 0), (0.33, 0.25), (0.18, 0.45), (0, 0.5)], loc=(x, yz(pts, 0.9) + plan(x) + 0.05, 0.92), seg=7, part="Gumdrops")
    skin(m, P("FFF2F8"), pts, ZB, -0.78, W - 0.1, off=0.02, thick=0.1, plan=plan, ns=17, part="Edge")
    mount_arms(m, P("6B3E2E"), STEEL, pts, plan=plan, xa=1.9)


def BladeTaffy(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = bez((-2.9, ZB + 0.15), (-2.4, 0.2), (-2.75, 1.2), 7)
    shell(m, P("FFF2F8"), stations(W, 13), profile_fn(pts), 0.26, part="Plate")
    for k in range(4):   # twisted taffy ropes
        z = -0.55 + k * 0.48
        tube(m, P(p[0] if k % 2 else "FFB3D1"), [(x, yz(pts, z) - 0.1 + 0.06 * math.sin(x * 3), z + 0.06 * math.cos(x * 3)) for x in stations(W - 0.3, 11)], r=0.13, seg=6, part="Ropes", smooth=2)
    for i in range(9):   # teeth
        x = -W / 2 + 0.55 + (W - 1.1) * i / 8
        spike(m, P(p[0]), (x, yz(pts, ZB + 0.2) - 0.05, ZB + 0.25), (x, yz(pts, ZB + 0.2) - 0.55, ZB + 0.05), 0.17, seg=6, part="Teeth")
    endplates(m, P(p[3]), pts, W, thick=0.2, back=0.45)
    mount_arms(m, P(p[3]), STEEL, pts, xa=1.4)


def BladeReef(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: 0.85 * abs(2 * x / W) - 0.85
    pts = bez((-2.95, ZB), (-2.4, 0.15), (-2.75, 1.2), 7)
    shell(m, P(p[0]), stations(W, 15), profile_fn(pts), 0.27, plan=plan, part="Plate")
    rod(m, P(p[3]), (0, yz(pts, ZB) + plan(0) - 0.2, ZB + 0.1), (0, yz(pts, 1.2) + plan(0) - 0.12, 1.3), r=0.16, seg=8, part="Keel")
    for z in (-0.5, 0.0, 0.5): sphere(m, P("FFF4E6"), (0, yz(pts, z) + plan(0) - 0.32, z), 0.13, seg=8, rings=5, part="Pearls")
    for sx in (-1, 1):
        for k in range(3):   # coral fins
            x = sx * (1.2 + k * 1.3); z = 0.6 + 0.15 * k
            b = Vector((x, yz(pts, z) + plan(x) - 0.05, z))
            tube(m, P(p[2]), [b, b + Vector((sx * 0.15, -0.25, 0.4)), b + Vector((sx * 0.35, -0.3, 0.8))], r=0.09, seg=6, part="Coral", smooth=2)
    skin(m, P(p[1]), pts, ZB, -0.75, W - 0.3, off=0.02, thick=0.09, plan=plan, ns=15, part="Edge")
    mount_arms(m, P(p[1]), STEEL, pts, plan=plan, xa=1.5)


def BladeCrayon(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = [(-2.9, ZB + 0.1), (-2.8, -0.3), (-2.75, 0.4), (-2.85, 1.15)]
    shell(m, P("F2EFE6"), stations(W, 12), profile_fn(pts), 0.22, part="Plate")
    cols = [p[0], p[1], p[2]]
    n = 9
    for i in range(n):   # giant crayons side by side, tips forward
        x = -W / 2 + 0.6 + (W - 1.2) * i / (n - 1)
        rod(m, P(cols[i % 3]), (x, -2.55, -0.55), (x, -2.55, 0.95), r=0.42, seg=8, part="Crayons")
        lathe(m, P(cols[i % 3]), [(0.42, 0), (0.15, 0.45), (0.0, 0.55)], loc=(x, -2.55, 0.95), seg=8, part="Tips")
        disc(m, P("2B2B2B"), (x, -2.55, 0.1), 0.43, 0.25, axis=(0, 0, 1), seg=8, part="Labels")
    skin(m, P(STEEL, "ME"), pts, ZB, -0.75, W - 0.1, off=0.02, thick=0.1, ns=12, part="Edge")
    mount_arms(m, P(p[3]), STEEL, pts, xa=1.7)


def BladePiston(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.42 * (2 * x / W) ** 2
    pts = bez((-3.15, ZB), (-2.3, 0.05), (-3.0, 1.35), 8)
    shell(m, P(p[0], "ME"), stations(W, 15), profile_fn(pts), 0.24, plan=plan, part="Plate")
    for z in (-0.4, 0.35, 1.05): tube(m, P(p[1], "ME"), [(x, yz(pts, z) + plan(x) - 0.04, z) for x in stations(W - 0.3, 11)], r=0.07, seg=6, part="Bands", smooth=3)
    bolts(m, P(p[1], "ME"), pts, [-4.5, -3, -1.5, 0, 1.5, 3, 4.5], 0.0, plan=plan, r=0.08)
    for sx in (-1, 1):   # two visible pushing pistons
        rod(m, P(p[3]), (sx * 1.6, -0.4, 0.5), (sx * 2.1, yz(pts, 0.5) + plan(sx * 2.1) + 0.3, 0.5), r=0.22, seg=10, part="Cylinders")
        rod(m, P(STEEL, "ME"), (sx * 2.0, -1.6, 0.5), (sx * 2.2, yz(pts, 0.5) + plan(sx * 2.2) + 0.1, 0.5), r=0.11, seg=8, part="Rods")
    skin(m, P(STEEL, "ME"), pts, ZB, -0.78, W - 0.3, off=0.02, thick=0.09, plan=plan, ns=15, part="Edge")
    mount_arms(m, P(p[3]), STEEL, pts, plan=plan, xa=1.3, piston=False)


def BladeSprocket(m, c):
    p = c["palette"]; W = c["visualWidth"]
    pts = bez((-2.9, ZB + 0.1), (-2.4, 0.15), (-2.8, 1.2), 7)
    shell(m, P(p[3]), stations(W, 13), profile_fn(pts), 0.28, part="Plate")
    for i, x in enumerate((-3.0, 0.0, 3.0)):   # sprocket wheels in the cutting edge (centre one Spins)
        flat(m, P(p[0] if i != 1 else p[2], "ME"), gear_poly(12, 0.9, 0.7, 0.45), 0.16, (x, yz(pts, -0.35) - 0.12, -0.35), axis=(0, -1, 0), part="Sprocket" if i == 1 else "Gears")
        disc(m, P(p[1], "ME"), (x, yz(pts, -0.35) - 0.3, -0.35), 0.28, 0.1, axis=(0, -1, 0), seg=10, part="Hubs")
    for k in range(4): box(m, P(p[1], "ME"), (-W / 2 + 0.9 + k * (W - 1.8) / 3, yz(pts, 0.75) - 0.05, 0.75), (0.5, 0.12, 0.5), r=0.05, part="Rivets")
    skin(m, P(STEEL, "ME"), pts, ZB, -0.75, W - 0.1, off=0.02, thick=0.1, ns=13, part="Edge")
    endplates(m, P(p[0], "ME"), pts, W, thick=0.2, back=0.45)
    mount_arms(m, P(p[3]), STEEL, pts, xa=1.45)


def BladeRainbow(m, c):
    p = c["palette"]; W = c["visualWidth"]
    plan = lambda x: -0.35 * (2 * x / W) ** 2
    pts = bez((-3.05, ZB), (-2.5, -0.1), (-2.9, 1.0), 6)
    shell(m, P("FFFFFF"), stations(W, 17), profile_fn(pts), 0.22, plan=plan, part="Plate")
    cols = ["FF5A5A", "FF9A3D", "FFE14F", "5ED67A", "4FB8FF", "9B6BFF"]
    for k, col in enumerate(cols):   # rainbow bands across the face
        z = -0.75 + k * 0.28
        skin(m, P(col), pts, z, z + 0.22, W - 0.6, off=0.02, thick=0.04, plan=plan, ns=9, part="Band%d" % k)
    for sx in (-1, 1):   # fluffy cloud end caps
        x = sx * (W / 2 - 0.2)
        puff(m, P("F7F9FF"), [(x, yz(pts, 0.4) + plan(x) + 0.2, 0.4, 0.5), (x + sx * 0.2, yz(pts, 0.9) + plan(x) + 0.3, 0.9, 0.42), (x, yz(pts, -0.2) + plan(x) + 0.3, -0.2, 0.4)], part="Clouds")
    skin(m, P("FFE08A", "ME"), pts, ZB, -0.78, W - 0.1, off=0.02, thick=0.1, plan=plan, ns=17, part="Edge")
    mount_arms(m, P("8FD0FF"), STEEL, pts, plan=plan, xa=1.9)
