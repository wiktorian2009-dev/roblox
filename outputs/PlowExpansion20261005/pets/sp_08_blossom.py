# Blossom (Sakura) Egg: pink blossoms, white, red lacquer, gold.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet

def pair(f):
    for s in (-1, 1): f(s)

PINK = P("FF8FBF")
GOLD = P("F5C443", "ME")
RED = P("D9343C")

@pet("Koi")
def koi(m):
    B, MK, FIN = P("FFF6EE"), P("FF6A2A"), P("FF8A4A")
    vtube(m, B, [(0, -0.45, 0.95), (0, 0.0, 0.92), (0, 0.45, 1.02), (0, 0.78, 1.22)], [0.5, 0.48, 0.32, 0.14], seg=12, sq=1.12)
    h = Head((0, -0.5, 0.95), (0.5, 0.52, 0.55)); ell(m, B, h.c, h.r, seg=12, rings=8)
    bh = Head((0, -0.05, 0.94), (0.48, 0.5, 0.55))
    for (a, pp, r) in [(180, 60, 0.22), (140, 30, 0.18), (215, 10, 0.16), (60, 55, 0.2)]:
        p, n = bh.pt(a, pp)
        ell(m, MK, p - n * 0.04, (r, r, r * 0.45), part="Mark", seg=10, rings=6, q=n.to_track_quat('Z', 'Y'))
    p, n = h.pt(0, 70); ell(m, MK, p - n * 0.02, (0.24, 0.22, 0.1), part="Mark", seg=10, rings=6, q=n.to_track_quat('Z', 'Y'))
    M = Matrix.Translation(Vector((0, 0.8, 1.22))) @ Euler((0, 0, math.radians(90)), 'XYZ').to_matrix().to_4x4()
    slab(m, FIN, [(0, 0.1), (0.3, 0.45), (0.62, 0.56), (0.45, 0.08), (0.64, -0.42), (0.32, -0.34), (0, -0.1)], 0.05, M, part="Accent")
    for s in (-1, 1):
        ell(m, FIN, (s * 0.46, -0.3, 0.6), (0.06, 0.26, 0.14), rot=(30, 0, s * -20), part="Accent", seg=8, rings=5)
        b = h.pt(s * 22, -34, -0.02)[0]
        vtube(m, GOLD, [b, b + Vector((s * 0.12, -0.08, -0.12)), b + Vector((s * 0.22, -0.02, -0.22))], [0.03, 0.022, 0.012], seg=5, part="AccentGold", smooth=2)
    M = Matrix.Translation(Vector((0, 0.05, 1.38))) @ Euler((0, 0, math.radians(90)), 'XYZ').to_matrix().to_4x4()
    slab(m, FIN, [(-0.35, 0.0), (-0.1, 0.32), (0.3, 0.22), (0.4, 0.0)], 0.05, M, part="Accent")
    p, n = h.pt(-30, 58); flower(m, PINK, GOLD, p + n * 0.04, 0.17, normal=n, part="AccentFlower", cpart="AccentGold")
    eyes(m, h, 36, 12, rx=0.12, rz=0.15)
    mouth(m, h, -14, w=0, kind="o", r=0.035)
    blush(m, h, 50, -6, 0.08)
    return {"H": 2.2}

@pet("Blossom Bunny")
def blossom_bunny(m):
    B, BE, INN = P("FFF7FA"), P("FFE3EE"), P("FFB0C8")
    ell(m, B, (0, 0.12, 0.5), (0.58, 0.54, 0.5))
    h = Head((0, -0.06, 1.28), (0.66, 0.58, 0.55)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, BE, (0, -0.32, 0.45), (0.34, 0.2, 0.3), part="Belly")
    for s in (-1, 1):
        b, n = h.pt(s * 52, 46, -0.06)
        pts = [b, b + Vector((s * 0.3, 0.02, 0.06)), b + Vector((s * 0.48, -0.02, -0.25)), b + Vector((s * 0.5, -0.06, -0.7))]
        vtube(m, B, pts, [0.14, 0.2, 0.2, 0.1], seg=10, sq=0.5, up=(s, 0, 0))
        ip = [p + Vector((0, -0.06, 0)) for p in pts[1:]]
        vtube(m, INN, ip, [0.12, 0.12, 0.05], seg=8, part="Blush", sq=0.4, up=(s, 0, 0))
    for k, a in enumerate((-24, 0, 24)):
        p, n = h.pt(a, 64)
        flower(m, PINK if k != 1 else P("FFFFFF"), GOLD, p + n * 0.04, 0.16, normal=n, part="AccentFlower" if k != 1 else "AccentFlowerW", cpart="AccentGold")
    pair(lambda s: foot(m, B, s * 0.26, -0.42, 0.16))
    pair(lambda s: ell(m, B, (s * 0.44, 0.06, 0.13), (0.2, 0.3, 0.13)))
    ell(m, PINK, (0, 0.68, 0.42), 0.19, part="AccentFlower", seg=10)
    eyes(m, h, 26, 4, rx=0.135, rz=0.165)
    nose(m, h, -10, (0.06, 0.04, 0.045), pc=P("FF8FAE"))
    mouth(m, h, -18, w=7, kind="w", sag=4)
    blush(m, h, 44, -8, 0.1)

@pet("Red Panda")
def red_panda(m):
    B, BE, MK = P("D9572B"), P("FFF1E0"), P("4A2A20")
    ell(m, B, (0, 0.12, 0.6), (0.48, 0.46, 0.55))
    ell(m, MK, (0, -0.12, 0.52), (0.36, 0.28, 0.4), part="Mark")
    h = Head((0, -0.06, 1.4), (0.66, 0.56, 0.54)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.5, 1.26), (0.3, 0.2, 0.18)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    for s in (-1, 1):
        h.put(m, BE, s * 36, -12, (0.2, 0.08, 0.17), "Belly", off=0.0, seg=10, rings=6)
        h.put(m, BE, s * 26, 30, (0.1, 0.05, 0.06), "Belly", off=0.0, seg=8, rings=5)
        p, n = h.pt(s * 30, -8)
        vtube(m, B, [p + n * 0.02, p + n * 0.02 + Vector((0, 0, -0.14))], [0.035, 0.03], seg=5, smooth=1)
        leg(m, MK, (s * 0.24, -0.25, 0.5), (s * 0.26, -0.34, 0.1), r=0.11, part="Mark")
        ell(m, MK, (s * 0.38, 0.12, 0.2), (0.2, 0.32, 0.2), part="Mark")
    round_ear(m, B, BE, h, 46, 42, r=0.21, ipart="Belly")
    segtube(m, [B, BE], ["Body", "Belly"], [(0.2, 0.5, 0.25), (0.62, 0.68, 0.35), (0.86, 0.45, 0.75), (0.8, 0.1, 1.05)], [0.16, 0.26, 0.26, 0.17], 0.2, seg=10, smooth=3)
    from w2lib import tube
    tube(m, RED, [(math.cos(a) * 0.42, -0.02 + math.sin(a) * 0.4, 0.95) for a in [2 * math.pi * i / 14 for i in range(14)]], r=0.035, seg=5, part="Accent", closed=True, smooth=1)
    ell(m, GOLD, (0, -0.44, 0.88), 0.09, part="AccentGold", seg=8)
    eyes(m, h, 24, 6, rx=0.125, rz=0.15, gap=0.03)
    p, n = mz.pt(0, 34); ell(m, P("2B2026"), p + n * 0.01, (0.07, 0.045, 0.05), part="Nose", seg=8)
    mouth(m, mz, -16, w=20, kind="w", sag=10)
    blush(m, h, 48, -18, 0.07)

@pet("Crane")
def crane(m):
    B, BLK, CRN, BK, LEG = P("FFFFFF"), P("2B2B36"), P("E8383D"), P("E8C46A"), P("6B6B78")
    ell(m, B, (0, 0.18, 1.0), (0.52, 0.66, 0.45), rot=(-10, 0, 0))
    vtube(m, B, [(0, -0.3, 1.15), (0, -0.5, 1.5), (0, -0.38, 1.95), (0, -0.42, 2.3)], [0.17, 0.14, 0.13, 0.15], seg=10)
    vtube(m, BLK, [(0, -0.45, 1.55), (0, -0.42, 1.75), (0, -0.38, 2.0)], [0.145, 0.135, 0.14], seg=10, part="AccentBlack")
    h = Head((0, -0.42, 2.42), (0.42, 0.38, 0.38)); ell(m, B, h.c, h.r, seg=12, rings=8)
    p, n = h.pt(0, 75); ell(m, CRN, p - n * 0.02, (0.16, 0.14, 0.06), part="Mark", seg=8, q=n.to_track_quat('Z', 'Y'))
    p, n = h.pt(0, -10)
    vtube(m, BK, [p - n * 0.05, p + n * 0.22 + Vector((0, 0, -0.04)), p + n * 0.42 + Vector((0, 0, -0.1))], [0.08, 0.05, 0.0], seg=7, part="AccentBeak")
    for s in (-1, 1):
        wings(m, B, "feather", (0.42, 0.1, 1.15), span=0.85, hgt=0.55, thick=0.07, spread=(28, 38, 0), part="Body", lobes=3, sides=(s,))
        M = Matrix.Translation(Vector((s * 0.42, 0.1, 1.15)))
        cone(m, BLK, (s * 0.85, 0.55, 1.42), (s * 1.0, 0.75, 1.45), 0.1, seg=6, part="AccentBlack")
        vtube(m, LEG, [(s * 0.18, 0.15, 0.7), (s * 0.2, 0.1, 0.35), (s * 0.2, 0.05, 0.06)], [0.045, 0.04, 0.04], seg=6, part="AccentLeg", smooth=1)
        for d in (-30, 0, 30):
            a = math.radians(d)
            vtube(m, LEG, [(s * 0.2, 0.05, 0.03), (s * 0.2 + math.sin(a) * 0.16, 0.05 - math.cos(a) * 0.18, 0.03)], [0.03, 0.025], seg=5, part="AccentLeg", smooth=1)
    for k, dx in enumerate((-0.12, 0.0, 0.12)):
        cone(m, BLK, (dx, 0.7, 1.0), (dx * 2.5, 1.05, 1.18 - abs(dx)), 0.12, seg=6, part="AccentBlack")
    flower(m, PINK, GOLD, h.pt(-48, 40, 0.04)[0], 0.13, normal=h.pt(-48, 40)[1], part="AccentFlower", cpart="AccentBeak")
    eyes(m, h, 32, 12, rx=0.1, rz=0.125)
    blush(m, h, 52, -4, 0.07)
    return {"H": 2.95}

@pet("Blossom Dragon")
def blossom_dragon(m):
    B, BE, HN, PET, GL = P("FF9FC9"), P("FFE9D6"), P("F5C443", "ME"), P("FFFFFF"), P("FFE6F4", "NE")
    path = [(0.6, 0.95, 0.4), (0.9, 0.45, 0.28), (0.6, -0.12, 0.32), (-0.15, -0.05, 0.55), (-0.5, 0.45, 0.9), (-0.2, 0.92, 1.18), (0.3, 0.72, 1.45), (0.25, 0.12, 1.7), (0.05, -0.2, 1.88)]
    rad = [0.05, 0.17, 0.24, 0.27, 0.28, 0.27, 0.26, 0.24, 0.23]
    vtube(m, B, path, rad, seg=9, smooth=3)
    from petkit import _catmull
    dense = _catmull([Vector(p) for p in path], 3, False)
    for i in range(3, len(dense) - 2):
        t = (dense[i + 1] - dense[i - 1]).normalized()
        side = t.cross(Vector((0, 0, 1)))
        if side.length < 1e-3: continue
        side.normalize(); up = side.cross(t).normalized()
        if up.z < 0: up = -up
        rr = rad[min(len(rad) - 1, int(i / 3))]
        if i % 3 == 0:
            ell(m, BE, dense[i] - up * rr * 0.55, (rr * 0.85, rr * 0.9, rr * 0.55), part="Belly", seg=7, rings=4, q=t.to_track_quat('Y', 'Z'))
        if i % 2 == 1 and i < len(dense) - 2:
            back = -t
            cone(m, PET, dense[i] + up * rr * 0.6, dense[i] + up * (rr + 0.2) + back * 0.18, 0.09, seg=5, part="AccentPetalW")
        if i in (7, 16):
            flower(m, PINK, HN, dense[i] + side * rr * 0.9 + up * rr * 0.3, 0.24, normal=side + up * 0.4, part="AccentPetal", cpart="Accent")
    h = Head((0, -0.38, 2.1), (0.54, 0.5, 0.46)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.84, 1.95), (0.3, 0.27, 0.19)); ell(m, B, sn.c, sn.r, seg=10, rings=7)
    for k, (a, pp) in enumerate(((-110, 10), (-140, 35), (180, 50), (140, 35), (110, 10), (-160, 5), (160, 5))):
        p, n = h.pt(a, pp, -0.04)
        cone(m, PET, p, p + n * 0.36 + Vector((0, 0.12, 0.04)), 0.11, seg=5, part="AccentPetalW")
    for a in (-24, 24):
        p, n = h.pt(a, 72)
        flower(m, PINK, HN, p + n * 0.05, 0.22, normal=n, part="AccentPetal", cpart="Accent")
    for s in (-1, 1):
        b = h.pt(s * 34, 55, -0.05)[0]
        vtube(m, HN, [b, b + Vector((s * 0.08, 0.25, 0.3)), b + Vector((s * 0.12, 0.5, 0.42))], [0.06, 0.05, 0.0], seg=6, part="Accent")
        vtube(m, HN, [b + Vector((s * 0.06, 0.2, 0.25)), b + Vector((s * 0.22, 0.2, 0.4))], [0.035, 0.0], seg=5, part="Accent", smooth=1)
        w0 = sn.pt(s * 40, -5, -0.02)[0]
        vtube(m, HN, [w0, w0 + Vector((s * 0.25, 0.0, -0.05)), w0 + Vector((s * 0.42, 0.15, -0.28))], [0.03, 0.025, 0.0], seg=5, part="Accent")
        sn.put(m, P("D9688F"), s * 24, 30, (0.035, 0.02, 0.03), "Nose", off=0.01)
    for (pp, side) in ((3, 1), (5, -1)):
        c = Vector(path[pp])
        vtube(m, B, [c, c + Vector((side * 0.25, -0.15, -0.2)), c + Vector((side * 0.3, -0.25, -0.35))], [0.08, 0.07, 0.06], seg=6, smooth=2)
        for k in (-1, 0, 1):
            cone(m, HN, c + Vector((side * 0.3 + k * 0.04, -0.27, -0.36)), c + Vector((side * 0.32 + k * 0.06, -0.36, -0.42)), 0.025, seg=4, part="Accent")
    ell(m, GL, Vector(path[3]) + Vector((0.3, -0.33, -0.4)), 0.12, part="Glow", seg=10)
    for k, a in enumerate((-40, 0, 40)):
        d = Vector((math.sin(math.radians(a)) * 0.5, 0.6, math.cos(math.radians(a)) * 0.6)).normalized()
        flower(m, PET if k == 1 else PINK, HN, Vector((0.6, 0.95, 0.4)) + d * 0.18, 0.27, normal=d, part="AccentPetalW" if k == 1 else "AccentPetal", cpart="Accent")
    eyes(m, h, 30, 12, rx=0.13, rz=0.16)
    mouth(m, sn, -22, w=22, kind="smile", sag=8)
    blush(m, h, 54, -8, 0.08)
    return {"H": 3.1}



