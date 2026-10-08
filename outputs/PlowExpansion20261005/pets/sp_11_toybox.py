# Toy Capsule (Toybox) Egg: plush/toy materials, primary colours, stitches, wind-up keys.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import tube

def pair(f):
    for s in (-1, 1): f(s)

RED, BLUE, YEL = P("E8433F"), P("3E7BE0"), P("FFD84A")
GOLDM = P("F5C443", "ME")

def stitch_line(m, surf, pts, pc, part="Mark", r=0.02):
    """Cross-stitch dashes along a list of (yaw,pitch) points on surface."""
    for (a, p_) in pts:
        p, n = surf.pt(a, p_, 0.008)
        tx = n.cross(Vector((0, 0, 1))).normalized() if abs(n.z) < 0.95 else Vector((1, 0, 0))
        tz = tx.cross(n).normalized()
        for d in (tx + tz, tx - tz):
            vtube(m, pc, [p - d * 0.035, p + d * 0.035], [r, r], seg=4, part=part, smooth=1)

def windkey(m, pc, base, direction=(0, 1, 0), size=1.0, part="Accent"):
    d = Vector(direction).normalized(); b = Vector(base)
    vtube(m, pc, [b, b + d * 0.22 * size], [0.04 * size, 0.04 * size], seg=6, part=part, smooth=1)
    c = b + d * 0.24 * size
    side = d.cross(Vector((0, 0, 1))).normalized() if abs(d.z) < 0.9 else Vector((1, 0, 0))
    for s in (-1, 1):
        ell(m, pc, c + side * s * 0.13 * size, (0.12 * size, 0.04 * size, 0.1 * size), part=part, seg=8, rings=5, q=d.to_track_quat('Y', 'Z'))

@pet("Teddy Bear")
def teddy(m):
    B, BE, MK, BOW = P("B5763F", "FA"), P("E8C39A", "FA"), P("5A3A22"), RED
    ell(m, B, (0, 0.1, 0.6), (0.5, 0.44, 0.55))
    bel = Head((0, -0.18, 0.56), (0.32, 0.2, 0.34)); ell(m, BE, bel.c, bel.r, part="Belly")
    h = Head((0, -0.03, 1.42), (0.62, 0.54, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.48, 1.28), (0.27, 0.18, 0.18)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    round_ear(m, B, BE, h, 46, 44, r=0.2, ipart="Belly")
    for s in (-1, 1):
        ell(m, B, (s * 0.52, -0.12, 0.72), (0.17, 0.17, 0.28), rot=(0, s * 35, 0), seg=10)
        ell(m, B, (s * 0.3, -0.3, 0.2), (0.2, 0.26, 0.19), seg=10)
        ell(m, BE, (s * 0.3, -0.53, 0.2), (0.12, 0.04, 0.12), part="Belly", seg=8, rings=5)
    stitch_line(m, bel, [(0, 40), (0, 10), (0, -20)], MK)
    p, n = h.pt(-38, 30); disc(m, BLUE, [(math.cos(a) * 0.12, math.sin(a) * 0.1) for a in [2 * math.pi * i / 8 for i in range(8)]], 0.03, p + n * 0.005, normal=n, part="AccentPatch")
    stitch_line(m, Head(h.c, h.r + Vector((0.02, 0.02, 0.02))), [(-38, 30)], MK)
    for s in (-1, 1):
        ell(m, BOW, (s * 0.15, -0.45, 0.98), (0.15, 0.07, 0.1), rot=(0, s * 15, 0), part="Accent", seg=8)
    ell(m, BOW, (0, -0.48, 0.98), 0.06, part="Accent", seg=6)
    eyes(m, h, 26, 8, rx=0.12, rz=0.145)
    p, n = mz.pt(0, 34); ell(m, P("3A2418"), p + n * 0.01, (0.085, 0.05, 0.06), part="Nose", seg=8)
    mouth(m, mz, -20, w=18, kind="w", sag=10)
    blush(m, h, 48, -10, 0.09)

@pet("Toy Duck")
def toy_duck(m):
    B, BK, HAT, WH = P("FFD23F"), P("FF8A1E"), BLUE, P("FFFFFF")
    ell(m, B, (0, 0.12, 0.62), (0.58, 0.68, 0.42))
    cone(m, B, (0, 0.6, 0.72), (0, 0.92, 1.05), 0.22, seg=8)
    h = Head((0, -0.25, 1.28), (0.48, 0.44, 0.44)); ell(m, B, h.c, h.r, seg=12, rings=8)
    for s in (-1, 1):
        ell(m, B, (s * 0.52, 0.18, 0.7), (0.12, 0.36, 0.22), rot=(15, 0, 0), seg=8)
    p, n = h.pt(0, -14)
    ell(m, BK, p + n * 0.1, (0.24, 0.2, 0.07), part="AccentBeak", seg=10, rings=6, rot=(-8, 0, 0))
    ell(m, BK, p + n * 0.08 + Vector((0, 0, -0.06)), (0.2, 0.16, 0.05), part="AccentBeak", seg=8, rings=5, rot=(-14, 0, 0))
    cyl(m, HAT, (0, -0.22, 1.62), r=0.32, h=0.16, seg=14, bev=0.04, part="AccentHat", rot=(-10, 0, 0))
    tube(m, WH, [(math.cos(a) * 0.34, -0.23 + math.sin(a) * 0.34, 1.64) for a in [2 * math.pi * i / 16 for i in range(16)]], r=0.035, seg=5, part="Belly", closed=True, smooth=1)
    ell(m, RED, (0, -0.2, 1.82), 0.07, part="AccentWheel", seg=8)
    ell(m, P("3E5A9A"), (0, 0.12, 0.25), (0.48, 0.6, 0.1), part="AccentBase", seg=10, rings=5)
    for sx in (-1, 1):
        for y in (-0.32, 0.5):
            cyl(m, RED, (sx * 0.42, y, 0.17), r=0.17, h=0.1, seg=12, bev=0.03, rot=(0, 90, 0), part="AccentWheel")
            cyl(m, WH, (sx * 0.53, y, 0.17), r=0.06, h=0.03, seg=8, rot=(0, 90, 0), part="Belly")
    eyes(m, h, 30, 8, rx=0.11, rz=0.135)
    blush(m, h, 50, -8, 0.08)
    return {}

@pet("Wind-up Mouse")
def windup_mouse(m):
    B, INN, MK, CU = P("C7CBD6", "ME"), P("FFB3C4"), P("8F95A6", "ME"), P("C9773E", "ME")
    ell(m, B, (0, 0.2, 0.55), (0.48, 0.66, 0.48))
    h = Head((0, -0.36, 0.95), (0.48, 0.42, 0.42)); ell(m, B, h.c, h.r, seg=12, rings=8)
    p, n = h.pt(0, -12)
    vtube(m, B, [p - n * 0.15, p + n * 0.12, p + n * 0.24], [0.2, 0.1, 0.0], seg=8, smooth=1)
    ell(m, INN, p + n * 0.24, 0.06, part="Nose", seg=8)
    round_ear(m, B, INN, h, 50, 36, r=0.27, thick=0.25, ipart="Blush")
    vtube(m, MK, [(0, -0.4, 0.95), (0, -0.05, 1.03), (0, 0.4, 0.98), (0, 0.8, 0.6)], [0.025] * 4, seg=5, part="Mark")
    for (y, z) in ((-0.1, 1.0), (0.2, 1.02), (0.5, 0.9)):
        pair(lambda s: ell(m, MK, (s * 0.25, y, z - 0.06), 0.03, part="Mark", seg=5, rings=3))
    windkey(m, GOLDM, (0, 0.3, 1.0), (0, 0.15, 1), size=1.1, part="Accent")
    vtube(m, CU, [(0, 0.82, 0.4), (0.15, 1.1, 0.32), (0.3, 1.2, 0.5), (0.18, 1.08, 0.62), (0.05, 1.18, 0.7), (0.15, 1.35, 0.78)], [0.03] * 6, seg=5, part="AccentCopper")
    for sx in (-1, 1):
        for y in (-0.1, 0.5):
            cyl(m, P("3A3F4E"), (sx * 0.32, y, 0.12), r=0.12, h=0.08, seg=10, rot=(0, 90, 0), part="AccentWheel")
    eyes(m, h, 30, 12, rx=0.12, rz=0.145)
    mouth(m, h, -26, w=12, kind="w", sag=6)
    blush(m, h, 50, -10, 0.09)

@pet("Toy Robot")
def toy_robot(m):
    B, FACE, GL = RED, P("E8ECF2"), P("8FF0FF", "NE")
    box(m, B, (0, 0.05, 0.86), (0.84, 0.64, 0.72), r=0.12, bseg=2)
    box(m, YEL, (0, -0.28, 0.88), (0.46, 0.04, 0.36), r=0.04, part="Mark")
    for k, x in enumerate((-0.12, 0.0, 0.12)):
        cyl(m, (BLUE, RED, BLUE)[k], (x, -0.3, 0.8), r=0.04, h=0.04, seg=8, rot=(90, 0, 0), part=("Accent", "Body", "Accent")[k])
    box(m, B, (0, -0.02, 1.65), (1.0, 0.78, 0.72), r=0.14, bseg=2)
    face = Head((0, -0.16, 1.63), (0.42, 0.34, 0.28)); ell(m, FACE, face.c, face.r, part="Belly", seg=12, rings=7)
    for s in (-1, 1):
        cyl(m, BLUE, (s * 0.5, -0.02, 1.65), r=0.13, h=0.08, seg=10, rot=(0, 90, 0), part="Accent")
        vtube(m, BLUE, [(s * 0.46, 0.0, 1.05), (s * 0.68, -0.08, 0.85), (s * 0.7, -0.18, 0.62)], [0.08, 0.07, 0.07], seg=7, part="Accent")
        for k in (-1, 1):
            cone(m, BLUE, (s * 0.7, -0.2, 0.6), (s * 0.7 + k * 0.08, -0.26, 0.45), 0.05, seg=5, part="Accent")
        box(m, BLUE, (s * 0.22, 0.05, 0.28), (0.24, 0.26, 0.36), r=0.05, part="Accent")
        box(m, P("3A3F4E"), (s * 0.22, -0.02, 0.06), (0.32, 0.44, 0.12), r=0.04, part="AccentFeet")
    vtube(m, P("3A3F4E"), [(0, -0.02, 2.0), (0, -0.02, 2.25)], [0.03, 0.03], seg=6, part="AccentFeet", smooth=1)
    ell(m, GL, (0, -0.02, 2.3), 0.09, part="Glow", seg=10)
    windkey(m, GOLDM, (0, 0.38, 0.9), (0, 1, 0.1), size=1.0, part="AccentGold")
    eyes(m, face, 30, 6, rx=0.11, rz=0.13)
    mouth(m, face, -30, w=16, kind="smile", sag=6)
    blush(m, face, 54, -8, 0.07)
    m.flat("Body", B, 40)

@pet("Plush Dinosaur")
def plush_dino(m):
    B, BE, SP, MK, CR, GL = P("6FD27A", "FA"), P("D3F5C4", "FA"), P("FFB33D", "FA"), P("2E7A3A"), P("FFD23F", "FA"), P("FFF2A8", "NE")
    ell(m, B, (0, 0.18, 0.8), (0.6, 0.62, 0.68))
    bel = Head((0, -0.15, 0.75), (0.44, 0.34, 0.5)); ell(m, BE, bel.c, bel.r, part="Belly")
    h = Head((0, -0.32, 1.75), (0.62, 0.56, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.72, 1.6), (0.42, 0.3, 0.26)); ell(m, B, sn.c, sn.r, seg=10, rings=7)
    vtube(m, B, [(0, 0.65, 0.55), (0.1, 1.1, 0.4), (0.4, 1.4, 0.28), (0.6, 1.5, 0.3)], [0.38, 0.28, 0.16, 0.06], seg=10)
    spine = [(0, -0.3, 2.22), (0, 0.05, 2.12), (0, 0.42, 1.5), (0, 0.72, 1.2), (0.05, 0.95, 0.85), (0.15, 1.2, 0.62), (0.35, 1.38, 0.45)]
    for k, c in enumerate(spine[1:]):
        sz = 0.2 - k * 0.02
        cone(m, SP, Vector(c) + Vector((0, -0.04, -0.06)), Vector(c) + Vector((0, 0.06, sz * 1.5)), sz, seg=6, part="Accent", sq=0.45)
    for s in (-1, 1):
        vtube(m, B, [(s * 0.5, -0.25, 1.1), (s * 0.66, -0.42, 0.95)], [0.1, 0.09], seg=7, smooth=1)
        ell(m, B, (s * 0.67, -0.46, 0.93), 0.1, seg=8)
        ell(m, B, (s * 0.38, -0.08, 0.3), (0.26, 0.32, 0.3), seg=10)
        ell(m, BE, (s * 0.38, -0.28, 0.08), (0.2, 0.2, 0.08), part="Belly", seg=8)
        sn.put(m, MK, s * 26, 30, (0.035, 0.02, 0.025), "Mark", off=0.01)
    stitch_line(m, bel, [(0, 50), (0, 20), (0, -10), (0, -40)], MK)
    poly = [(-0.34, 0.0), (0.34, 0.0), (0.34, 0.18), (0.22, 0.08), (0.11, 0.3), (0.0, 0.1), (-0.11, 0.3), (-0.22, 0.08), (-0.34, 0.18)]
    p, n = h.pt(0, 62, -0.04)
    from w2lib import lathe
    lathe(m, CR, [(0.3, 0.0), (0.3, 0.14)], loc=p + Vector((0, 0.04, 0.0)), seg=12, rot=(-14, 0, 0), part="AccentCrown")
    for k in range(5):
        a = math.radians(-90 + (k - 2) * 38)
        b = p + Vector((0, 0.04, 0)) + Vector((math.cos(a) * 0.3, math.sin(a) * 0.3 * 0.95, 0.12))
        cone(m, CR, b, b + Vector((0, 0, 0.18)), 0.07, seg=5, part="AccentCrown")
    disc(m, GL, star_poly(0.1, 0.045), 0.04, p + Vector((0, -0.28, 0.08)), normal=(0, -1, 0.2), part="Glow")
    eyes(m, h, 30, 10, rx=0.13, rz=0.155)
    mouth(m, sn, -16, w=30, kind="smile", sag=8)
    blush(m, h, 56, -6, 0.09)


