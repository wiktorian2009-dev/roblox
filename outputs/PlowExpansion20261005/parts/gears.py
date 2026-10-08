# gears.py - 30 snowplow gear sets (wheels / tracks / runners / hover). Origin = chassis ground centre.
# Contract used: ground contact at z = 0; left/right assemblies between |x| 2.63 (outside the skirt/body) and 3.6;
# y within -3.8..3.9; wheel centres under the fenders (front y -2.3, rear y +2.5) and tyre tops <= 1.97 because
# the chassis fenders (|x| 2.22..3.0, z 2.0..2.3) sit directly above the wheels.
import math
from mathutils import Vector, Matrix
from partlib import *
from w2lib import rock

FY, RY = -2.3, 2.5
WHEELS = [(sx, y) for sx in (-1, 1) for y in (FY, RY)]


def axle(m, pc, sx, y, z, x_to, r=0.11, part="Axle"):
    rod(m, pc, (sx * 2.15, y, z), (sx * x_to, y, z), r=r, seg=8, part=part)


def hubcap(m, pc, sx, y, z, xo, r, h=0.1, seg=12, part="Hub", bev=0.03):
    disc(m, pc, (sx * xo, y, z), r, h, axis=(sx, 0, 0), seg=seg, bev=bev, part=part)


def strut(m, pc, sx, y, z0, z1, x0=2.2, x1=2.9, part="Struts", w=0.16):
    beam(m, pc, (sx * x0, y, z0), (sx * x1, y, z1), w=w, h=w, r=0.04, part=part)


def track_side(m, sx, wheels, xc, width, thick, pc_belt, pc_cleat=None, pc_wheel=None, wheel_w=None, spacing=0.42, ch=0.1, part="Track", wheel_seg=14, cleat_part="Cleats", hub_pc=None):
    poly = track_path(wheels, n=14)
    belt(m, pc_belt, poly, sx * xc, width, thick, part=part)
    if pc_cleat: cleats(m, pc_cleat, poly, sx * xc, width, thick, spacing=spacing, h=ch, depth=0.15, part=cleat_part)
    if pc_wheel:
        ww = wheel_w or width * 0.78
        for (y, z, r) in wheels:
            wheel_disc(m, pc_wheel, (sx * xc, y, z), r * 0.96, ww, seg=wheel_seg, part="Wheels")
            if hub_pc: hubcap(m, hub_pc, sx, y, z, xc + ww / 2, r * 0.45, h=0.06, seg=10, part="Hubs")
    return poly


# =====================================================================================
def GearWheels(m, c):
    p = c["palette"]
    R, w, xc = 0.82, 0.62, 2.96
    for sx, y in WHEELS:
        tire(m, P(RUBBER), (sx * xc, y, R), R, w, seg=16)
        knobs(m, P("24262D"), (sx * xc, y, R), R - 0.04, w, n=12, size=(w * 0.8, 0.2, 0.1), part="Tread", r=0.0)
        hubcap(m, P(p[2]), sx, y, R, xc + w / 2 - 0.02, 0.44, h=0.08, seg=12)
        hubcap(m, P(STEEL, "ME"), sx, y, R, xc + w / 2 + 0.05, 0.16, h=0.07, seg=8, part="Cap")
        axle(m, P(DARK), sx, y, R, xc)


def GearChunky(m, c):
    p = c["palette"]
    R, w, xc = 0.84, 0.9, 3.05
    for sx, y in WHEELS:
        tire(m, P(RUBBER), (sx * xc, y, R + 0.03), R, w, seg=16, bulge=0.18)
        knobs(m, P("24262D"), (sx * xc, y, R + 0.03), R - 0.02, w, n=13, rows=2, size=(None, 0.32, 0.2), part="Knobs", r=0.0)
        hubcap(m, P(p[0]), sx, y, R + 0.03, xc + w / 2 - 0.04, 0.5, h=0.1, seg=14)
        for k in range(5):
            a = 2 * math.pi * k / 5
            hubcap(m, P(p[3]), sx, y + 0.3 * math.cos(a), R + 0.03 + 0.3 * math.sin(a), xc + w / 2 + 0.05, 0.06, h=0.05, seg=6, part="Nuts")
        hubcap(m, P(p[2]), sx, y, R + 0.03, xc + w / 2 + 0.05, 0.16, h=0.08, seg=10, part="Cap")
        axle(m, P(DARK), sx, y, R, xc)


def GearTracks(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.78, 0.62), (3.05, 0.78, 0.62), (-1.45, 0.47, 0.32), (0.05, 0.47, 0.32), (1.55, 0.47, 0.32)]
        track_side(m, sx, wh, 3.1, 0.88, 0.15, P("4A5060", "ME"), P(DARK), P(STEEL, "ME"), hub_pc=P(p[2]))
        box(m, P(p[3]), (sx * 3.1, 0.05, 1.62), (0.95, 5.6, 0.12), r=0.04, part="Guard") if False else None
        for y in (-1.4, 1.6): axle(m, P(DARK), sx, y, 0.75, 2.75, r=0.13)
        beam(m, P(p[3]), (sx * 2.72, -2.9, 0.78), (sx * 2.72, 3.0, 0.78), w=0.18, h=0.3, r=0.05, part="Axle")


def GearBalloon(m, c):
    p = c["palette"]
    R, w, xc = 0.95, 0.9, 3.05
    for sx, y in WHEELS:
        lathe(m, P(p[0]), [(R * 0.5, -w / 2), (R * 0.72, -w / 2), (R * 0.92, -w * 0.38), (R, -w * 0.12), (R, w * 0.12), (R * 0.92, w * 0.38), (R * 0.72, w / 2), (R * 0.5, w / 2)],
              loc=(sx * xc, y, R), seg=18, rot=(0, 90, 0), part="Tire")
        for k in range(3): torus(m, P("C9A35E"), (sx * (xc + (k - 1) * 0.28), y, R), R=R - 0.01, r=0.035, seg=18, rseg=4, rot=(0, 90, 0), part="Grooves")
        hubcap(m, P(p[1]), sx, y, R, xc + w / 2 - 0.06, 0.5, h=0.12, seg=14, part="Rim")
        hubcap(m, P(p[3]), sx, y, R, xc + w / 2 + 0.05, 0.2, h=0.08, seg=10, part="Cap")
        axle(m, P(p[3]), sx, y, R, xc)


def GearSandcrawler(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.95, 0.6), (3.05, 0.72, 0.56), (-1.5, 0.47, 0.32), (0.0, 0.47, 0.32), (1.5, 0.47, 0.32)]
        track_side(m, sx, wh, 3.07, 0.94, 0.16, P(p[3]), P("5E3320"), P(p[0]), wheel_w=0.6)
        for (y, z, r) in wh[:2]:
            flat(m, P(p[2], "ME"), gear_poly(10, r + 0.08, r - 0.06, 0.45), 0.06, (sx * 3.5, y, z), axis=(sx, 0, 0), part="Sprockets")
            hubcap(m, P(p[1]), sx, y, z, 3.54, r * 0.4, h=0.06, seg=10, part="Hubs")
        beam(m, P(p[1]), (sx * 3.1, -2.6, 1.72), (sx * 3.1, 2.7, 1.55), w=1.0, h=0.1, r=0.04, part="Guard")
        for y in (-1.5, 1.5): axle(m, P(p[3]), sx, y, 0.8, 2.7, r=0.13)


def GearBoneWheels(m, c):
    p = c["palette"]
    R, w, xc = 0.72, 0.7, 3.0
    for sx, y in WHEELS:
        tire(m, P(p[1]), (sx * xc, y, R + 0.22), R, w, seg=14)
        for k in range(10):
            a = 2 * math.pi * k / 10
            d = Vector((0, math.cos(a), math.sin(a)))
            b = Vector((sx * xc, y, R + 0.22)) + d * (R - 0.05)
            spike(m, P(p[2]), b, b + d * 0.27, 0.1, seg=6, part="Spikes")
        hubcap(m, P(p[2]), sx, y, R + 0.22, xc + w / 2 - 0.04, 0.36, h=0.1, seg=12, part="Bone")
        hubcap(m, P(p[0]), sx, y, R + 0.22, xc + w / 2 + 0.05, 0.16, h=0.06, seg=8, part="Cap")
        axle(m, P(p[0]), sx, y, R + 0.22, xc)


def GearHaunted(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.82, 0.66), (3.05, 0.82, 0.66), (-1.25, 0.48, 0.33), (0.6, 0.48, 0.33), (-0.3, 0.48, 0.33) if False else (1.75, 0.48, 0.33)]
        poly = track_side(m, sx, wh, 3.1, 0.86, 0.15, P(p[0]), P("221A30"))
        for (y, z, r) in wh:
            wheel_disc(m, P("2A1F3D"), (sx * 3.1, y, z), r * 0.96, 0.68, seg=12, part="Wheels")
            hubcap(m, P(p[3], "NE"), sx, y, z, 3.1 + 0.34, r * 0.55, h=0.05, seg=10, part="Glow")
        beam(m, P(p[1]), (sx * 3.12, -2.9, 1.78), (sx * 3.12, 3.0, 1.78), w=0.94, h=0.1, r=0.04, part="Guard")
        for y in (-2.9, 3.0): flat(m, P(p[2]), arch_poly(0.5, 0.55), 0.08, (sx * 3.12, y, 1.82), axis=(0, -1, 0), part="Bones") if False else None
        for y in (-1.2, 1.6): axle(m, P("221A30"), sx, y, 0.8, 2.7, r=0.13)


def GearCrystalStud(m, c):
    p = c["palette"]
    R, w, xc = 0.76, 0.72, 3.02
    for sx, y in WHEELS:
        tire(m, P(p[3]), (sx * xc, y, R + 0.2), R, w, seg=14)
        for k in range(9):
            a = 2 * math.pi * k / 9 + 0.2
            d = Vector((0, math.cos(a), math.sin(a)))
            for xo in (-0.18, 0.18):
                b = Vector((sx * (xc + xo * (1 if k % 2 else -1)), y, R + 0.2)) + d * (R - 0.08)
                crystal(m, P(p[0], "GL"), b, b + d * 0.27 + Vector((0, 0.04, 0)), 0.09, seg=4, part="Crystals")
        hubcap(m, P(p[1]), sx, y, R + 0.2, xc + w / 2 - 0.02, 0.32, h=0.08, seg=6, part="Gem")
        hubcap(m, P(p[2]), sx, y, R + 0.2, xc + w / 2 + 0.04, 0.12, h=0.06, seg=6, part="Cap")
        axle(m, P(p[3]), sx, y, R + 0.2, xc)


def GearGeodeTracks(m, c):
    p = c["palette"]
    for sx, y0 in WHEELS:
        wh = [(y0 - 0.75, 0.45, 0.32), (y0 + 0.75, 0.45, 0.32), (y0, 1.1, 0.32)]
        track_side(m, sx, wh, 3.1, 0.82, 0.13, P(p[3]), P("252A3D"), P(STEEL, "ME"), wheel_seg=10)
        crystal(m, P(p[1], "GL"), (sx * 3.1, y0 - 0.15, 1.35), (sx * 3.15, y0 - 0.35, 1.95), 0.3, seg=6, part="Guards")
        crystal(m, P(p[1], "GL"), (sx * 3.1, y0 + 0.35, 1.3), (sx * 3.15, y0 + 0.65, 1.8), 0.22, seg=6, part="Guards")
        crystal(m, P(p[0], "GL"), (sx * 3.35, y0, 1.2), (sx * 3.55, y0 + 0.1, 1.6), 0.13, seg=5, part="Tips")
        axle(m, P(p[3]), sx, y0, 0.8, 2.7, r=0.14)


def GearPixelWheels(m, c):
    p = c["palette"]
    R, w, xc = 0.86, 0.7, 3.0
    for i, (sx, y) in enumerate(WHEELS):
        disc(m, P(p[3]), (sx * (xc - w / 2), y, R), R, w, axis=(1, 0, 0) if sx > 0 else (-1, 0, 0), seg=8, part="Tire") if False else None
        wheel_disc(m, P(p[3]), (sx * xc, y, R), R / math.cos(math.pi / 8) * 0.98, w, seg=8, part="Tire", bev=0.0)
        col = P(p[0]) if i % 2 == 0 else P(p[1])
        box(m, col, (sx * (xc + w / 2 + 0.02), y, R), (0.1, 0.9, 0.9), r=0.02, part="Px" + ("A" if i % 2 == 0 else "B"))
        box(m, P(p[2]), (sx * (xc + w / 2 + 0.08), y, R), (0.08, 0.36, 0.36), r=0.02, part="Center")
        for k in range(8):
            a = 2 * math.pi * k / 8 + math.pi / 8
            ry = R * 0.95
            box(m, col if k % 2 else P(p[2]), (sx * xc, y + ry * math.cos(a), R + ry * math.sin(a)), (w * 0.9, 0.26, 0.26), r=0.02, part="Px" + ("A" if i % 2 == 0 else "B") if k % 2 else "Center")
        axle(m, P(p[3]), sx, y, R, xc)


def GearHoverPods(m, c):
    p = c["palette"]
    for i, (sx, y) in enumerate(WHEELS):
        x = sx * 3.05; z0 = 0.32
        lathe(m, P(p[3]), [(0.42, 0), (0.5, 0.04), (0.5, 0.18), (0.38, 0.38), (0, 0.42)], loc=(x, y, z0), seg=16, sy=1.9, part="Pods")
        lathe(m, P(p[0] if i % 2 == 0 else p[1]), [(0.52, 0), (0.54, 0.06), (0.5, 0.14), (0, 0.15)], loc=(x, y, z0 + 0.12), seg=16, sy=1.9, part="Shell" + str(i % 2))
        torus(m, P(p[1], "NE"), (x, y, z0 - 0.04), R=0.45, r=0.05, seg=18, rseg=4, rot=(0, 0, 0), part="Glow") if False else None
        tube(m, P(p[1], "NE"), [(x + 0.42 * math.cos(a), y + 0.82 * math.sin(a), z0 - 0.04) for a in [2 * math.pi * k / 18 for k in range(18)]], r=0.05, seg=4, closed=True, smooth=1, part="Glow")
        strut(m, P(p[2]), sx, y, 0.62, 0.6, x0=2.3, x1=2.95, w=0.14)
        sphere(m, P(p[2]), (x, y, z0 + 0.45), 0.1, seg=8, rings=5, part="Struts")


def GearMudder(m, c):
    p = c["palette"]
    R, w, xc = 0.8, 0.9, 3.04
    for sx, y in WHEELS:
        tire(m, P("2B2620"), (sx * xc, y, R + 0.12), R, w, seg=16, bulge=0.2)
        knobs(m, P("221E19"), (sx * xc, y, R + 0.12), R - 0.03, w, n=11, rows=2, size=(0.5, 0.3, 0.26), chevron=28, part="Chevrons", r=0.0)
        hubcap(m, P(p[1], "WO"), sx, y, R + 0.12, xc + w / 2 - 0.05, 0.5, h=0.14, seg=10, part="WoodHub")
        for k in range(4):
            a = 2 * math.pi * k / 4 + 0.4
            box(m, P("6E4426", "WO"), (sx * (xc + w / 2 + 0.1), y + 0.22 * math.cos(a), R + 0.12 + 0.22 * math.sin(a)), (0.06, 0.1, 0.32), r=0.02, rot=(math.degrees(a), 0, 0), part="Pegs")
        hubcap(m, P(p[2]), sx, y, R + 0.12, xc + w / 2 + 0.1, 0.12, h=0.06, seg=8, part="Cap")
        rock(m, P("6B4A2E"), (sx * (xc + 0.2), y - 0.2, 0.12), (0.28, 0.25, 0.12), seed=sx + int(y), sub=1, part="Mud")
        axle(m, P(p[3]), sx, y, R + 0.12, xc)


def GearVineCrawler(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.9, 0.62), (3.05, 0.82, 0.6), (-1.55, 0.47, 0.32), (0.0, 0.47, 0.32), (1.55, 0.47, 0.32)]
        poly = track_side(m, sx, wh, 3.07, 0.94, 0.16, P(p[3]), P("1F421C"), P(p[1], "WO"), wheel_w=0.62)
        vp = []
        for i in range(25):
            t = i / 24; y = -3.0 + 6.1 * t
            vp.append((sx * (3.11 + 0.5 * math.cos(t * 18)), y, 1.0 + 0.55 * math.sin(t * 18)))
        tube(m, P(p[0]), [(sx * (3.54), -3.0 + 6.1 * i / 12, 0.55 + 0.35 * math.sin(i * 1.3)) for i in range(13)], r=0.06, seg=5, part="Vine", smooth=2)
        for k in range(5):
            y = -2.5 + k * 1.25
            flat(m, P(p[0] if k % 2 else "4CC35A"), leaf_poly(1.15, 0.85), 0.06, (sx * 3.1, y - 0.55, 1.68 + 0.04 * (k % 2)), axis=(0, 0, 1), up=(0, 1, 0), part="Leaves")
        for y in (-1.5, 1.5): axle(m, P(p[1], "WO"), sx, y, 0.8, 2.7, r=0.13)
        flat(m, P(p[2]), L.flower_poly(0.22, 5, 4), 0.05, (sx * 3.54, 0.0, 1.0), axis=(sx, 0, 0), part="Flower")


def GearSkis(m, c):
    p = c["palette"]
    for sx, y0 in WHEELS:
        x = sx * 3.05
        prof = [(y0 + 1.25, 0.0), (y0 + 0.4, 0.0), (y0 - 0.5, 0.0), (y0 - 1.05, 0.08), (y0 - 1.3, 0.3), (y0 - 1.35, 0.5)]
        shell(m, P(p[1]), [x - 0.32, x + 0.32], lambda xx: prof, -0.16, part="Skis") if False else None
        pts = [(y, z) for y, z in reversed(prof)]
        shell(m, P(p[1]), [x - 0.32, x - 0.11, x + 0.11, x + 0.32], profile_fn(pts[::-1][::-1] if False else list(reversed(pts))), 0.16, part="Skis")
        box(m, P(p[0], "IC"), (x, y0 + 0.1, 0.2), (0.4, 1.6, 0.08), r=0.03, part="Ice")
        box(m, P(p[2], "ME"), (x, y0, 0.28), (0.32, 0.55, 0.14), r=0.04, part="Silver")
        for yo in (-0.18, 0.18):
            beam(m, P(p[2], "ME"), (x, y0 + yo, 0.3), (sx * 2.75, y0 + yo * 0.6, 0.95), w=0.1, h=0.1, r=0.02, part="Silver")
        rod(m, P(p[2], "ME"), (sx * 2.2, y0, 0.95), (sx * 2.85, y0, 0.95), r=0.1, seg=8, part="Silver")
        sphere(m, P(p[3]), (x, y0 - 1.33, 0.52), 0.09, seg=8, rings=5, part="Tip")


def GearGlacierTracks(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.82, 0.6), (3.05, 0.82, 0.6), (-1.55, 0.47, 0.32), (0.0, 0.47, 0.32), (1.55, 0.47, 0.32)]
        track_side(m, sx, wh, 3.07, 0.94, 0.16, P(p[1]), P("1D4BA0"), P(p[2], "ME"), wheel_w=0.62)
        rbox(m, P(p[0], "IC"), (sx * 3.07, 0.02, 1.62), (1.0, 6.6, 0.24), r=0.1, part="Guard")
        for k in range(7):
            y = -2.7 + k * 0.9
            crystal(m, P(WHITE, "IC"), (sx * 3.5, y, 1.6), (sx * 3.52, y + 0.05, 1.3), 0.07, seg=4, part="Icicles")
        rbox(m, P(WHITE), (sx * 3.07, -1.5 + 0.0, 1.78), (0.8, 1.2, 0.12), r=0.05, part="Frost")
        rbox(m, P(WHITE), (sx * 3.07, 1.6, 1.78), (0.8, 1.0, 0.12), r=0.05, part="Frost")
        for y in (-1.5, 1.5): axle(m, P(p[1]), sx, y, 0.8, 2.7, r=0.13)


def GearZeroG(m, c):
    p = c["palette"]
    for sx, y in WHEELS:
        x = sx * 3.02; z = 0.45
        disc(m, P(p[2], "ME"), (x, y, z - 0.08), 0.5, 0.16, axis=(0, 0, 1), seg=16, bev=0.04, part="Frame")
        torus(m, P(p[3], "IC"), (x, y, z), R=0.5, r=0.09, seg=20, rseg=6, part="Ring")
        torus(m, P(p[0], "NE"), (x, y, z - 0.28), R=0.4, r=0.05, seg=18, rseg=4, part="Glow")
        torus(m, P(p[2], "ME"), (x, y, z + 0.3), R=0.44, r=0.06, seg=16, rseg=4, rot=(0, 0, 0), part="Frame")
        for k in range(4):
            a = 2 * math.pi * k / 4 + math.pi / 4
            rod(m, P(p[2], "ME"), (x + 0.58 * math.cos(a), y + 0.58 * math.sin(a), z), (x + 0.44 * math.cos(a), y + 0.44 * math.sin(a), z + 0.3), r=0.04, seg=5, part="Frame")
        crystal(m, P(p[0], "IC"), (x, y, z + 0.08), (x, y, z + 0.55), 0.14, seg=6, part="Core")
        strut(m, P(p[2], "ME"), sx, y, 0.85, 0.85, x0=2.25, x1=2.75, w=0.14)
        beam(m, P(p[2], "ME"), (sx * 2.7, y, 0.85), (x - sx * 0.3, y, z + 0.3), w=0.12, h=0.12, r=0.03, part="Frame")


def GearBamboo(m, c):
    p = c["palette"]
    R, w, xc = 0.85, 0.55, 2.95
    for sx, y in WHEELS:
        torus(m, P(p[0]), (sx * xc, y, R), R=R - 0.13, r=0.13, seg=20, rseg=7, rot=(0, 90, 0), part="Rim")
        torus(m, P(p[3]), (sx * xc, y, R), R=R - 0.05, r=0.06, seg=20, rseg=4, rot=(0, 90, 0), part="Tire") if False else None
        torus(m, P(p[3]), (sx * xc, y, R), R=R - 0.07, r=0.09, seg=20, rseg=6, rot=(0, 90, 0), part="Tire")
        for k in range(6):
            a = 2 * math.pi * k / 6
            d = Vector((0, math.cos(a), math.sin(a)))
            ctr = Vector((sx * xc, y, R))
            rod(m, P("8FC24A"), ctr + d * 0.12, ctr + d * (R - 0.2), r=0.05, seg=6, part="Bamboo")
            sphere(m, P("5E8F2C"), ctr + d * 0.42, 0.065, seg=6, rings=4, part="Joints")
        hubcap(m, P(p[2]), sx, y, R, xc - 0.12, 0.2, h=0.24, seg=10, part="Hub")
        flat(m, P(p[1]), L.flower_poly(0.2, 5, 4), 0.04, (sx * (xc + 0.12), y, R), axis=(sx, 0, 0), part="Flower")
        axle(m, P(p[3]), sx, y, R, xc)


def GearPetalGlide(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        x = sx * 3.1
        # long petal-shaped runner, curving up at the front with a gold tip
        prof = [(3.7, 0.08), (3.2, 0.0), (1.0, 0.0), (-1.5, 0.0), (-3.0, 0.08), (-3.5, 0.32), (-3.65, 0.6)]
        wd = lambda yy: 0.32 + 0.22 * math.cos(max(-1.0, min(1.0, yy / 3.8)) * math.pi / 2)
        xs = [x - 0.5, x - 0.25, x, x + 0.25, x + 0.5]
        F, B = shell(m, P(p[0]), xs, lambda xx: [(y, z + 0.18 * (abs(xx - x) / 0.5) ** 2) for y, z in prof], 0.14, part="Runner")
        shell(m, P(p[1]), [x - 0.12, x + 0.12], profile_fn([(y, z + 0.14) for y, z in prof[1:-1]]), 0.06, part="Stripe")
        sphere(m, P(GOLD, "ME"), (x, -3.66, 0.68), 0.15, seg=10, rings=6, part="Gold")
        rbox(m, P(GOLD, "ME"), (x, 3.62, 0.2), (0.5, 0.2, 0.16), r=0.05, part="Gold")
        for y in (FY, RY):
            for yo in (-0.25, 0.25):
                beam(m, P(p[3], "WO"), (x, y + yo, 0.15), (sx * 2.7, y + yo * 0.5, 0.95), w=0.12, h=0.12, r=0.03, part="Struts")
            rod(m, P(p[3], "WO"), (sx * 2.2, y, 0.95), (sx * 2.8, y, 0.95), r=0.1, seg=8, part="Struts")
            L.flower(m, P(p[1]), P(p[2]), (sx * 3.54, y, 0.3), 0.22, rot=(0, 90 * sx, 0), part="Bloom")


def GearDonut(m, c):
    p = c["palette"]
    R, xc = 0.92, 3.1
    for i, (sx, y) in enumerate(WHEELS):
        z = R
        torus(m, P("D9A066"), (sx * xc, y, z), R=0.58, r=0.34, seg=18, rseg=10, rot=(0, 90, 0), part="Dough")
        torus(m, P(p[0] if i % 2 == 0 else p[1]), (sx * (xc + 0.09), y, z), R=0.58, r=0.31, seg=18, rseg=10, rot=(0, 90, 0), sq=0.75, part="Icing" + str(i % 2))
        for k in range(12):
            a = 2 * math.pi * k / 12 + 0.13
            col = [p[2], WHITE, "6FC3FF"][k % 3]
            rr = 0.58 + 0.12 * (1 if k % 2 else -1)
            box(m, P(col), (sx * (xc + 0.38), y + rr * math.cos(a), z + rr * math.sin(a)), (0.05, 0.16, 0.05), r=0.0, rot=(math.degrees(a) + k * 30, 0, 0), part="Sprinkles")
        rod(m, P(p[3]), (sx * 2.15, y, z), (sx * (xc + 0.05), y, z), r=0.18, seg=10, part="Axle")
        disc(m, P(WHITE), (sx * (xc + 0.05), y, z), 0.22, 0.12, axis=(sx, 0, 0), seg=10, part="Axle")


def GearGummyTreads(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.8, 0.64), (3.05, 0.8, 0.64), (-1.4, 0.47, 0.32), (0.05, 0.47, 0.32), (1.5, 0.47, 0.32)]
        poly = track_side(m, sx, wh, 3.1, 0.88, 0.15, P(p[0], "GL"), None, P(p[3]), wheel_w=0.66)
        n = len(poly)
        # alternating gummy cleats
        segs = []; total = 0
        for i in range(n):
            a = Vector(poly[i]); b = Vector(poly[(i + 1) % n]); segs.append((a, b, total)); total += (b - a).length
        k = int(total / 0.48)
        for s in range(k):
            d = s * total / k
            for a, b, t0 in segs:
                ln = (b - a).length
                if t0 <= d <= t0 + ln:
                    q = a.lerp(b, (d - t0) / ln if ln else 0); t = (b - a).normalized(); nrm = Vector((t.y, -t.x)); cc = q + nrm * 0.22
                    ang = math.degrees(math.atan2(nrm.y, nrm.x)) - 90
                    col = [p[1], p[2]][s % 2]
                    box(m, P(col, "GL"), (sx * 3.1, cc.x, cc.y), (0.9, 0.24, 0.14), r=0.0, rot=(ang, 0, 0), part="Gummy" + str(s % 2), bseg=1)
                    break
        for (y, z, r) in wh[:2]:
            sphere(m, P(p[2]), (sx * 3.34, y, z), 0.26, seg=10, rings=6, part="Gummy1")
            for e in (-1, 1): sphere(m, P(p[2]), (sx * 3.38, y + e * 0.17, z + 0.25), 0.1, seg=6, rings=4, part="Gummy1")
        for y in (-1.4, 1.5): axle(m, P(p[3]), sx, y, 0.75, 2.75, r=0.13)


def GearShell(m, c):
    p = c["palette"]
    R, w, xc = 0.86, 0.66, 3.0
    for sx, y in WHEELS:
        tire(m, P(p[3]), (sx * xc, y, R), R, w, seg=18, bulge=0.15)
        lathe(m, P(p[2]), [(R * 0.82, 0), (R * 0.6, 0.12), (R * 0.3, 0.22), (0, 0.26)], loc=(sx * (xc + w / 2 - 0.04), y, R), rot=(0, 90 * sx, 0), seg=16, part="Shell")
        sp = []
        for i in range(30):
            t = i / 29; a = t * 4.5 * math.pi; r = 0.68 * (1 - t) + 0.04
            sp.append((sx * (xc + w / 2 + 0.06 + 0.2 * t), y + r * math.cos(a), R + r * math.sin(a)))
        tube(m, P("E5584A"), sp, r=0.045, seg=4, part="Spiral", smooth=1)
        for k in range(10):
            a = 2 * math.pi * k / 10
            sphere(m, P(WHITE), (sx * (xc + 0.0), y + (R + 0.02) * math.cos(a), R + (R + 0.02) * math.sin(a)), 0.08, seg=6, rings=4, part="Pearls") if R + (R + 0.02) * math.sin(a) < 1.95 else None
        axle(m, P(p[1]), sx, y, R, xc)


def GearPaddle(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.82, 0.6), (3.05, 0.82, 0.6), (-1.5, 0.47, 0.32), (0.0, 0.47, 0.32), (1.5, 0.47, 0.32)]
        poly = track_side(m, sx, wh, 3.07, 0.94, 0.16, P(p[0]), None, P(p[1]), wheel_w=0.62)
        cleats(m, P(p[3]), poly, sx * 3.07, 0.94, 0.16, spacing=0.8, h=0.17, depth=0.1, part="Paddles")
        for (y, z, r) in wh[:2]:
            # paddle-wheel hubs on the outside
            for k in range(6):
                a = 2 * math.pi * k / 6
                box(m, P(p[2]), (sx * 3.54, y + r * 0.6 * math.cos(a), z + r * 0.6 * math.sin(a)), (0.06, 0.12, r * 1.0), r=0.02, rot=(math.degrees(a) + 90, 0, 0), part="Spokes")
            hubcap(m, P(GOLD, "ME"), sx, y, z, 3.52, 0.18, h=0.06, seg=10, part="Gold")
        rbox(m, P(p[1]), (sx * 3.07, 0.05, 1.68), (1.0, 4.4, 0.12), r=0.05, part="Guard")
        for k in range(3): sphere(m, P(p[3]), (sx * 3.54, -1.2 + k * 1.2, 1.62), 0.1, seg=6, rings=4, part="Paddles")
        sphere(m, P(p[2], "NE"), (sx * 3.54, 0.0, 1.0), 0.11, seg=8, rings=5, part="Glow")
        for y in (-1.5, 1.5): axle(m, P(p[1]), sx, y, 0.8, 2.7, r=0.13)


def GearToyBrick(m, c):
    p = c["palette"]
    R, w, xc = 0.86, 0.72, 3.02
    cols = [p[0], p[1], p[2], p[3]]
    for i, (sx, y) in enumerate(WHEELS):
        tire(m, P("2B2D33"), (sx * xc, y, R), R, w, seg=16, bulge=0.25, inner=0.6)
        col = cols[i]
        box(m, P(col), (sx * (xc + 0.1), y, R), (w * 0.85, 0.8, 0.8), r=0.05, part="Bricks")
        for a in (-0.2, 0.2):
            for b in (-0.2, 0.2):
                cyl(m, P(col), (sx * (xc + 0.1 + w * 0.42), y + a, R + b), r=0.12, h=0.12, seg=8, rot=(0, 90 * sx, 0), part="Bricks")
        axle(m, P("3B3F4A"), sx, y, R, xc)


def GearToyTank(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.6, 0.72, 0.56), (-0.05, 0.72, 0.56), (2.5, 0.72, 0.56), (-3.35, 1.0, 0.3) if False else (-3.25, 1.05, 0.3), (3.25, 1.05, 0.3)]
        track_side(m, sx, wh, 3.1, 0.9, 0.16, P(p[0]), P("A8302A"), None)
        for (y, z, r) in wh[:3]:
            wheel_disc(m, P(p[2]), (sx * 3.1, y, z), r * 0.98, 0.72, seg=16, part="Wheels")
            hubcap(m, P(p[1]), sx, y, z, 3.46, 0.26, h=0.08, seg=12, part="Hubs")
            hubcap(m, P(WHITE), sx, y, z, 3.54, 0.09, h=0.05, seg=8, part="Caps")
        for (y, z, r) in wh[3:]:
            wheel_disc(m, P(p[1]), (sx * 3.1, y, z), r * 0.98, 0.72, seg=10, part="Hubs")
        rbox(m, P(p[3]), (sx * 3.12, 0.0, 1.66), (0.98, 6.4, 0.14), r=0.06, part="Guard")
        for k in range(3): cyl(m, P(p[3]), (sx * 3.12 + sx * 0.0 - 0.0, -2.0 + k * 2.0, 1.72), r=0.14, h=0.1, seg=8, part="Guard")
        for y in (-1.3, 1.25): axle(m, P("3B3F4A"), sx, y, 0.75, 2.75, r=0.13)


def GearCogWheels(m, c):
    p = c["palette"]
    R, w, xc = 0.9, 0.62, 2.98
    for sx, y in WHEELS:
        flat(m, P(p[0], "ME"), gear_poly(12, R, R - 0.2, 0.42), w, (sx * (xc - w / 2) if sx > 0 else -(xc - w / 2), y, R + 0.02), axis=(sx, 0, 0), part="Cog")
        hubcap(m, P(p[1], "ME"), sx, y, R + 0.02, xc + w / 2 - 0.02, 0.45, h=0.1, seg=12, part="Copper")
        for k in range(5):
            a = 2 * math.pi * k / 5
            hubcap(m, P(p[3]), sx, y + 0.3 * math.cos(a), R + 0.02 + 0.3 * math.sin(a), xc + w / 2 + 0.06, 0.06, h=0.04, seg=6, part="Rivets")
        hubcap(m, P(p[2]), sx, y, R + 0.02, xc + w / 2 + 0.06, 0.14, h=0.07, seg=8, part="Cap")
        torus(m, P(p[3]), (sx * xc, y, R + 0.02), R=R - 0.22, r=0.06, seg=18, rseg=4, rot=(0, 90, 0), part="Rivets")
        axle(m, P(p[3]), sx, y, R, xc)


def GearBrassTracks(m, c):
    p = c["palette"]
    for sx, y0 in WHEELS:
        wh = [(y0 - 0.8, 0.5, 0.36), (y0 + 0.8, 0.5, 0.36), (y0 - 0.25, 1.12, 0.3), (y0 + 0.4, 1.12, 0.3)]
        track_side(m, sx, wh, 3.1, 0.84, 0.14, P(p[0], "ME"), P(p[1], "ME"), P(p[3]), wheel_seg=12)
        flat(m, P(p[2]), gear_poly(10, 0.62, 0.48, 0.45), 0.08, (sx * 3.47, y0, 0.85), axis=(sx, 0, 0), part="Guards")
        hubcap(m, P(p[0], "ME"), sx, y0, 0.85, 3.53, 0.22, h=0.06, seg=10, part="BrassHub")
        axle(m, P(p[3]), sx, y0, 0.85, 2.7, r=0.14)


def GearCloudPuff(m, c):
    p = c["palette"]
    R, xc = 0.72, 3.08
    for sx, y in WHEELS:
        z = R + 0.22
        for k in range(9):
            a = 2 * math.pi * k / 9
            sphere(m, P(p[0]), (sx * xc, y + R * math.cos(a), z + R * math.sin(a)), 0.32 + 0.04 * (k % 2), seg=8, rings=5, part="Puffs")
        sphere(m, P(p[1]), (sx * (xc - 0.05), y, z), 0.6, seg=12, rings=7, scl=(0.7, 1, 1), part="Inner")
        hubcap(m, P(p[2], "ME"), sx, y, z, xc + 0.3, 0.32, h=0.12, seg=12, part="Gold")
        hubcap(m, P(p[3], "NE"), sx, y, z, xc + 0.42, 0.14, h=0.05, seg=10, part="Glow")
        axle(m, P(p[2], "ME"), sx, y, z, xc)


def GearStormPods(m, c):
    p = c["palette"]
    for i, (sx, y) in enumerate(WHEELS):
        x = sx * 3.05; z = 0.62
        puff(m, P("5D6A86"), [(x, y, z, 0.44), (x, y - 0.55, z - 0.05, 0.36), (x, y + 0.55, z - 0.03, 0.36), (x + sx * 0.04, y - 0.2, z + 0.3, 0.32), (x, y + 0.95, z - 0.1, 0.24), (x, y - 0.95, z - 0.1, 0.24)], part="Cloud", seg=10)
        tube(m, P(p[3], "NE"), [(x + 0.42 * math.cos(a), y + 0.9 * math.sin(a), 0.2 + 0.07 * math.sin(6 * a)) for a in [2 * math.pi * k / 24 for k in range(24)]], r=0.05, seg=4, closed=True, smooth=1, part="Glow")
        flat(m, P(p[2], "ME"), bolt_poly(0.3, 0.5), 0.05, (x + sx * 0.38, y, z), axis=(sx, 0, 0), part="Bolts")
        strut(m, P(p[2], "ME"), sx, y, 0.85, 0.75, x0=2.25, x1=2.85, w=0.14)


def GearOrbit(m, c):
    p = c["palette"]
    R, xc = 0.84, 3.05
    for sx, y in WHEELS:
        z = R + 0.1
        torus(m, P(p[1]), (sx * xc, y, z), R=R - 0.06, r=0.14, seg=22, rseg=8, rot=(0, 90, 0), part="Ring")
        torus(m, P(p[3]), (sx * (xc + 0.2), y, z), R=R - 0.3, r=0.05, seg=18, rseg=4, rot=(0, 90, 18), part="Orbit")
        flat(m, P(p[2], "NE"), star_poly(5, R - 0.12, 0.2), 0.1, (sx * (xc - 0.05), y, z), axis=(sx, 0, 0), part="Star")
        sphere(m, P(p[0]), (sx * (xc + 0.06), y, z), 0.18, seg=10, rings=6, part="Hub")
        sphere(m, P(p[3]), (sx * (xc + 0.22), y + (R - 0.3), z), 0.09, seg=8, rings=5, part="Orbit")
        axle(m, P(p[0]), sx, y, z, xc)


def GearMeteor(m, c):
    p = c["palette"]
    for sx in (-1, 1):
        wh = [(-2.95, 0.82, 0.62), (3.05, 0.82, 0.62), (-1.5, 0.47, 0.32), (0.0, 0.47, 0.32), (1.5, 0.47, 0.32)]
        poly = track_side(m, sx, wh, 3.07, 0.94, 0.16, P(p[0]), P("221A5C"))
        for k, (y, z, r) in enumerate(wh):
            rock(m, P("4A3F7A"), (sx * 3.07, y, z), (0.36, r * 0.92, r * 0.92), seed=k + (5 if sx > 0 else 0), sub=1, jag=0.14, part="Rocks")
            hubcap(m, P(p[3], "NE"), sx, y, z, 3.42, r * 0.45, h=0.05, seg=6, part="Glow")
        m.flat("Rocks", P("4A3F7A"), 1)
        rbox(m, P(p[1]), (sx * 3.07, 0.05, 1.68), (1.0, 5.0, 0.12), r=0.05, part="Guard")
        for k in range(4): flat(m, P(p[2]), star_poly(4, 0.16, 0.05), 0.04, (sx * 3.54, -1.6 + k * 1.1, 1.66), axis=(sx, 0, 0), part="Stars")
        for y in (-1.5, 1.5): axle(m, P("221A5C"), sx, y, 0.8, 2.7, r=0.13)