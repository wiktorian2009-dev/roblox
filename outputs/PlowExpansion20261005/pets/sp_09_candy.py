# Candy Egg: candy pinks, mint, sprinkles, frosting.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import tube

def pair(f):
    for s in (-1, 1): f(s)

MINT = P("8FE8C8")
CPINK = P("FF9CCB")
RED = P("E8383D")
CREAM = P("FFF5EC")

@pet("Gummy Bear")
def gummy_bear(m):
    B, BE = P("FF4D6D"), P("FF96AA")
    ell(m, B, (0, 0.05, 0.62), (0.5, 0.42, 0.55))
    ell(m, BE, (0, -0.22, 0.6), (0.32, 0.22, 0.36), part="Belly")
    h = Head((0, -0.03, 1.42), (0.58, 0.5, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.44, 1.3), (0.24, 0.14, 0.15)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=6)
    round_ear(m, B, None, h, 44, 46, r=0.19, thick=0.6)
    for s in (-1, 1):
        ell(m, B, (s * 0.52, -0.1, 0.82), (0.17, 0.17, 0.26), rot=(0, s * 40, 0), seg=10)
        ell(m, B, (s * 0.3, -0.25, 0.18), (0.2, 0.26, 0.18), seg=10)
    for d in (-1, 1):
        ell(m, MINT, (d * 0.13, -0.38, 1.0), (0.12, 0.06, 0.09), rot=(0, d * 20, 0), part="Accent", seg=8)
    ell(m, MINT, (0, -0.42, 1.0), 0.05, part="Accent", seg=6)
    for (a, pp) in [(-40, 60), (35, 70), (60, 30), (-65, 20), (10, 85)]:
        p, n = h.pt(a, pp); ell(m, P("FFFFFF"), p + n * 0.01, (0.03, 0.03, 0.015), part="MarkSugar", seg=5, rings=3, q=n.to_track_quat('Z', 'Y'))
    eyes(m, h, 26, 8, rx=0.12, rz=0.15)
    p, n = mz.pt(0, 30); ell(m, P("A3142E"), p + n * 0.01, (0.06, 0.04, 0.04), part="Nose", seg=8)
    mouth(m, mz, -18, w=18, kind="w", sag=10)
    blush(m, h, 46, -10, 0.09, pc=P("FFB3C3"))

@pet("Marshmallow Bunny")
def marsh_bunny(m):
    B, MK, INN = P("FFF8F4"), P("E9B17C"), P("FFB8CC")
    cyl(m, B, (0, 0, 0.04), r=0.6, h=1.3, seg=16, bev=0.18, bseg=3, part="Body")
    prof = [(0.6, 0.0), (0.6, 1.4)]
    for s in (-1, 1):
        cyl(m, B, (s * 0.26, 0.02, 1.28), r=0.16, h=0.62, seg=10, bev=0.07, bseg=2, rot=(0, s * 12, 0), part="Body")
        cyl(m, INN, (s * 0.25, -0.09, 1.4), r=0.08, h=0.42, seg=8, bev=0.03, bseg=1, rot=(-8, s * 12, 0), scl=(1, 0.5, 1), part="Blush")
        ell(m, B, (s * 0.3, -0.5, 0.1), (0.16, 0.18, 0.1), seg=8)
    for (x, y, r) in ((0.25, -0.2, 0.18), (-0.2, 0.15, 0.2), (0.15, 0.3, 0.14), (-0.3, -0.25, 0.12)):
        ell(m, MK, (x, y, 1.34), (r, r * 0.9, 0.03), part="Mark", seg=8, rings=4)
    tube(m, MK, [(math.cos(a) * 0.52, math.sin(a) * 0.52, 1.32) for a in [2 * math.pi * i / 16 for i in range(16)]], r=0.04, seg=5, part="Mark", closed=True, smooth=1)
    ell(m, B, (0, 0.62, 0.35), 0.17, seg=8)
    f = LatheFace(prof, (0, 0.02), 0.82, 0.5)
    eyes(m, f, 24, 4, rx=0.14, rz=0.17)
    nose(m, f, -18, (0.06, 0.04, 0.045), pc=P("FF8FAE"))
    mouth(m, f, -30, w=7, kind="w", sag=6)
    blush(m, f, 44, -16, 0.1)
    return {"H": 2.5}

@pet("Cupcake Cat")
def cupcake_cat(m):
    B, FROST, CUP, SPY, SPB = P("FFF0E2"), P("FFB3D1"), MINT, P("FFE066"), P("6FC8FF")
    lathe(m, CUP, [(0.0, 0.0), (0.46, 0.0), (0.6, 0.55), (0.0, 0.55)], seg=20, part="Accent", rib=(10, 0.05))
    for k, (r, z) in enumerate(((0.62, 0.62), (0.5, 0.8))):
        tube(m, FROST, [(math.cos(a) * r, math.sin(a) * r, z + 0.04 * math.sin(3 * a)) for a in [2 * math.pi * i / 18 for i in range(18)]], r=0.16 - k * 0.02, seg=8, part="Belly", closed=True, smooth=1)
    ell(m, FROST, (0, 0, 0.72), (0.56, 0.56, 0.22), part="Belly", seg=12, rings=6)
    h = Head((0, -0.05, 1.38), (0.6, 0.52, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    pointy_ear(m, B, P("FFB8CC"), h, 38, 48, height=0.48, width=0.25, out=20, back=-6, ipart="Blush")
    pair(lambda s: ell(m, B, (s * 0.26, -0.5, 0.84), (0.13, 0.15, 0.1), seg=8))
    ell(m, RED, (0.22, 0.05, 1.98), 0.13, part="AccentCherry", seg=10)
    vtube(m, CUP, [(0.22, 0.05, 2.08), (0.26, 0.1, 2.25), (0.34, 0.12, 2.3)], [0.025, 0.022, 0.02], seg=5, part="Accent", smooth=2)
    import random
    rnd = random.Random(7)
    fr = Head((0, 0, 0.78), (0.66, 0.66, 0.24))
    for i in range(14):
        a = rnd.uniform(-180, 180); pp = rnd.uniform(10, 60)
        p, n = fr.pt(a, pp)
        ell(m, SPY if i % 2 else SPB, p + n * 0.02, (0.06, 0.02, 0.02), part="MarkY" if i % 2 else "MarkB", seg=5, rings=3, rot=(0, 0, rnd.uniform(0, 180)))
    vtube(m, B, [(0.4, 0.4, 0.45), (0.7, 0.55, 0.65), (0.75, 0.4, 1.0), (0.62, 0.3, 1.1)], [0.07, 0.07, 0.065, 0.05], seg=7)
    eyes(m, h, 26, 6, rx=0.13, rz=0.155)
    nose(m, h, -8, (0.05, 0.035, 0.04), pc=P("FF7FA8"))
    mouth(m, h, -16, w=8, kind="w", sag=5)
    blush(m, h, 46, -8, 0.09, pc=P("FFB8CC"))

@pet("Candy Fox")
def candy_fox(m):
    B, BE, MK = P("FFA94D"), P("FFFFFF"), RED
    ell(m, B, (0, 0.12, 0.55), (0.46, 0.5, 0.55))
    h = Head((0, -0.06, 1.33), (0.62, 0.55, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.5, 1.2), (0.22, 0.28, 0.18)); ell(m, BE, sn.c, sn.r, part="Belly", seg=10, rings=7)
    ell(m, BE, (0, -0.26, 0.72), (0.32, 0.22, 0.34), part="Belly")
    pair(lambda s: cone(m, BE, (s * 0.42, -0.2, 1.12), (s * 0.78, -0.12, 1.02), 0.16, seg=7, part="Belly"))
    pointy_ear(m, B, CPINK, h, 34, 50, height=0.6, width=0.26, out=16, back=-6, ipart="Blush")
    pair(lambda s: leg(m, B, (s * 0.2, -0.24, 0.6), (s * 0.22, -0.36, 0.1), r=0.1))
    pair(lambda s: ell(m, BE, (s * 0.22, -0.42, 0.07), (0.12, 0.14, 0.07), part="Belly", seg=8))
    pair(lambda s: ell(m, B, (s * 0.36, 0.18, 0.3), (0.2, 0.34, 0.28)))
    segtube(m, [BE, MK], ["Belly", "Mark"], [(0.1, 0.55, 0.3), (0.3, 0.75, 0.6), (0.36, 0.72, 1.2), (0.3, 0.5, 1.58), (0.25, 0.2, 1.6), (0.24, 0.05, 1.4)],
            [0.13, 0.16, 0.17, 0.16, 0.15, 0.13], 0.16, seg=10, smooth=3)
    for s in (-1, 1):
        cone(m, MINT, (s * 0.04, -0.44, 0.88), (s * 0.22, -0.46, 0.92), 0.1, seg=6, part="Accent")
    ell(m, MINT, (0, -0.45, 0.88), 0.07, part="Accent", seg=8)
    eyes(m, h, 26, 4, rx=0.13, rz=0.155, tilt=8)
    p, n = sn.pt(0, 12); ell(m, P("3A2433"), p + n * 0.015, (0.07, 0.05, 0.05), part="Nose", seg=8)
    mouth(m, sn, -28, w=12, kind="w", sag=8)
    blush(m, h, 46, -12, 0.09)

@pet("Sugar Dragon")
def sugar_dragon(m):
    B, FR, GUM, WG, GL = MINT, CREAM, CPINK, P("FFB3D9"), P("FF7FC4", "NE")
    ell(m, B, (0, 0.12, 0.78), (0.66, 0.6, 0.72), seg=12, rings=8)
    h = Head((0, -0.18, 1.78), (0.6, 0.53, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, FR, (0, -0.34, 0.72), (0.44, 0.3, 0.46), part="Belly")
    cap = Head((0, -0.06, 2.02), (0.6, 0.53, 0.32)); ell(m, FR, cap.c, cap.r, part="Belly", seg=12, rings=7)
    for (a, ln) in [(-62, 0.14), (0, 0.1), (62, 0.14), (100, 0.18), (-100, 0.15), (150, 0.16), (-150, 0.14)]:
        p, n = cap.pt(a, -8)
        vtube(m, FR, [p + Vector((0, 0, 0.04)), p + Vector((0, 0, -ln)), p + Vector((0, 0, -ln - 0.06))], [0.07, 0.065, 0.0], seg=6, part="Belly", smooth=1)
    import random
    rnd = random.Random(3)
    for i in range(10):
        p, n = cap.pt(rnd.uniform(-150, 150), rnd.uniform(25, 80))
        ell(m, P("FF6FA8"), p + n * 0.01, (0.05, 0.018, 0.018), part="Mark", seg=5, rings=3, rot=(0, 0, rnd.uniform(0, 180)))
    for s in (-1, 1):
        b = cap.pt(s * 40, 40, -0.05)[0]
        segtube(m, [FR, RED], ["Belly", "AccentRed"], [b, b + Vector((s * 0.08, 0.05, 0.3)), b + Vector((s * 0.22, 0.08, 0.48)), b + Vector((s * 0.35, 0.02, 0.42))], [0.07, 0.07, 0.065, 0.06], 0.1, seg=8, smooth=3)
        wings(m, WG, "round", (0.4, 0.42, 1.2), span=0.85, hgt=0.75, thick=0.08, spread=(25, 30, 0), part="AccentWing", sides=(s,))
        ell(m, B, (s * 0.38, -0.22, 0.15), (0.24, 0.32, 0.16), seg=10)
        vtube(m, B, [(s * 0.5, -0.2, 1.02), (s * 0.66, -0.36, 0.84)], [0.12, 0.1], seg=7, smooth=1)
    for k, (y, z) in enumerate(((0.45, 1.25), (0.68, 0.95), (0.74, 0.62))):
        ell(m, GUM, (0, y, z), (0.14, 0.14, 0.17), part="AccentGum", seg=8)
    vtube(m, B, [(0, 0.6, 0.3), (0.35, 0.95, 0.25), (0.65, 0.9, 0.42), (0.72, 0.7, 0.6)], [0.2, 0.14, 0.09, 0.06], seg=8)
    vtube(m, FR, [(0.72, 0.7, 0.6), (0.74, 0.64, 0.78)], [0.025, 0.025], seg=5, part="Belly", smooth=1)
    spiral = []
    for i in range(16):
        t = i / 15 * 2.2 * math.pi; r = 0.04 + 0.12 * i / 15
        spiral.append((math.cos(t) * r, math.sin(t) * r))
    disc(m, GL, [(math.cos(a) * 0.17, math.sin(a) * 0.17) for a in [2 * math.pi * i / 14 for i in range(14)]], 0.06, (0.75, 0.62, 0.95), normal=(0.6, -1, 0), part="Glow")
    eyes(m, h, 27, 4, rx=0.13, rz=0.155)
    mouth(m, h, -20, w=14, kind="smile", sag=8)
    blush(m, h, 48, -10, 0.09)




