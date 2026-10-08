# Desert Egg: warm sand, turquoise, gold.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet

def pair(f):
    for s in (-1, 1): f(s)

TQ = P("1FBFB0")
GD = P("F5C443", "ME")

@pet("Fennec Fox")
def fennec(m):
    B, BE, INN, MK = P("EDBE84"), P("FFF1DC"), P("FFC7AE"), P("8E5A33")
    ell(m, B, (0, 0.12, 0.5), (0.42, 0.46, 0.5))
    h = Head((0, -0.06, 1.26), (0.58, 0.5, 0.48)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, BE, (0, -0.24, 1.1), (0.4, 0.3, 0.24), part="Belly")
    sn = Head((0, -0.46, 1.14), (0.19, 0.22, 0.15)); ell(m, BE, sn.c, sn.r, part="Belly", seg=12)
    ell(m, BE, (0, -0.26, 0.5), (0.3, 0.2, 0.32), part="Belly")
    pointy_ear(m, B, INN, h, 42, 40, height=1.0, width=0.36, out=36, back=-4, thick=0.4, ipart="Blush")
    pair(lambda s: leg(m, B, (s * 0.18, -0.22, 0.5), (s * 0.2, -0.32, 0.1), r=0.09))
    pair(lambda s: ell(m, B, (s * 0.33, 0.14, 0.26), (0.18, 0.3, 0.24)))
    tp = [(0.16, 0.48, 0.2), (0.55, 0.62, 0.26), (0.78, 0.38, 0.5), (0.7, 0.05, 0.6)]
    vtube(m, B, tp, [0.1, 0.22, 0.24, 0.16], seg=12)
    vtube(m, MK, [(0.76, 0.2, 0.57), (0.7, 0.05, 0.6), (0.6, -0.08, 0.6)], [0.19, 0.16, 0.0], seg=12, part="Mark", smooth=3)
    scarf(m, TQ, (0, -0.02, 0.86), R=0.4, Ry=0.38, r=0.06, tail=False, part="Accent")
    disc(m, TQ, [(-0.26, 0.0), (0.26, 0.0), (0.0, -0.3)], 0.04, (0, -0.4, 0.86), normal=(0, -1, 0.25), part="Accent")
    ell(m, GD, (0, -0.44, 0.79), 0.06, part="AccentGold", seg=8)
    eyes(m, h, 26, 4, rx=0.13, rz=0.16, tilt=6)
    p, n = sn.pt(0, 14); ell(m, P("2D2433"), p + n * 0.015, (0.07, 0.05, 0.05), part="Nose", seg=8)
    mouth(m, sn, -30, w=14, kind="w", sag=8)
    blush(m, h, 46, -12, 0.09)

@pet("Camel")
def camel(m):
    B, BE, HOOF = P("D9A464"), P("F4DCAE"), P("8C6239")
    ell(m, B, (0, 0.25, 1.0), (0.46, 0.7, 0.4))
    ell(m, B, (0, -0.02, 1.46), (0.3, 0.29, 0.46))
    ell(m, B, (0, 0.6, 1.44), (0.29, 0.28, 0.44))
    ell(m, TQ, (0, 0.26, 1.08), (0.48, 0.17, 0.3), part="Accent")
    pair(lambda s: ell(m, GD, (s * 0.47, 0.26, 0.8), 0.06, part="AccentGold", seg=8))
    vtube(m, B, [(0, -0.3, 1.0), (0, -0.62, 1.18), (0, -0.74, 1.45)], [0.2, 0.17, 0.17], seg=10)
    h = Head((0, -0.84, 1.62), (0.42, 0.4, 0.37)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -1.2, 1.52), (0.27, 0.22, 0.2)); ell(m, BE, sn.c, sn.r, part="Belly", seg=12)
    for s in (-1, 1):
        sn.put(m, P("6E4A30"), s * 22, 18, (0.035, 0.02, 0.05), "Nose", off=0.01)
        p, n = h.pt(s * 78, 36); ell(m, B, p + n * 0.05, (0.13, 0.06, 0.08), rot=(0, 0, s * 20), seg=8)
    mouth(m, sn, -24, w=16, kind="smile", sag=6)
    for sx in (-1, 1):
        for y in (-0.15, 0.62):
            vtube(m, B, [(sx * 0.24, y, 0.8), (sx * 0.25, y, 0.4), (sx * 0.25, y, 0.12)], [0.12, 0.1, 0.1], seg=8, smooth=1)
            ell(m, HOOF, (sx * 0.25, y - 0.02, 0.07), (0.13, 0.15, 0.08), part="Mark", seg=8)
    vtube(m, B, [(0, 0.92, 1.1), (0, 1.04, 0.9), (0, 1.06, 0.72)], [0.06, 0.05, 0.04], seg=6)
    ell(m, HOOF, (0, 1.07, 0.66), (0.07, 0.07, 0.1), part="Mark", seg=8)
    ell(m, BE, (0, -0.7, 1.96), (0.16, 0.14, 0.09), part="Belly", seg=8)
    eyes(m, h, 32, 12, rx=0.12, rz=0.15)
    lashes(m, h, 32, 12, 0.12, 0.15)
    blush(m, h, 54, -6, 0.08)

@pet("Sand Lizard")
def sand_lizard(m):
    B, BE, MK = P("E8B651"), P("F8E4A8"), P("B9762E")
    ell(m, B, (0, 0.18, 0.5), (0.4, 0.62, 0.32), rot=(-18, 0, 0))
    bodyh = Head((0, 0.18, 0.5), (0.4, 0.62, 0.32))
    ell(m, BE, (0, -0.18, 0.46), (0.3, 0.3, 0.24), part="Belly")
    h = Head((0, -0.55, 0.98), (0.52, 0.46, 0.38)); ell(m, B, h.c, h.r, seg=12, rings=8)
    vtube(m, B, [(0, 0.7, 0.3), (0.15, 1.15, 0.2), (0.55, 1.32, 0.16), (0.8, 1.05, 0.15), (0.62, 0.82, 0.17), (0.48, 0.95, 0.2)],
          [0.2, 0.15, 0.11, 0.08, 0.05, 0.02], seg=10)
    for s in (-1, 1):
        vtube(m, B, [(s * 0.28, -0.3, 0.55), (s * 0.4, -0.38, 0.3), (s * 0.44, -0.45, 0.08)], [0.1, 0.09, 0.08], seg=8, smooth=1)
        ell(m, BE, (s * 0.46, -0.52, 0.05), (0.13, 0.13, 0.05), part="Belly", seg=8)
        vtube(m, B, [(s * 0.3, 0.45, 0.4), (s * 0.55, 0.42, 0.22), (s * 0.6, 0.3, 0.08)], [0.12, 0.1, 0.08], seg=8, smooth=1)
        ell(m, BE, (s * 0.62, 0.24, 0.05), (0.13, 0.13, 0.05), part="Belly", seg=8)
    for i, (y, z) in enumerate([(-0.55, 1.36), (-0.3, 1.24), (-0.05, 0.98), (0.2, 0.86), (0.45, 0.74), (0.7, 0.6)]):
        cone(m, TQ, (0, y, z - 0.08), (0, y + 0.08, z + 0.14 - i * 0.012), 0.08 - i * 0.004, seg=6, part="Accent")
    for (a, pp, r) in [(-35, 30, 0.08), (30, 40, 0.07), (0, 60, 0.07), (55, 10, 0.06), (-60, 5, 0.06)]:
        p, n = Head((0, 0.25, 0.5), (0.4, 0.62, 0.32)).pt(a + 180, pp)
        ell(m, MK, p + n * 0.0, (r, r, r * 0.5), part="Mark", seg=8, rings=5, q=n.to_track_quat('Z', 'Y'))
    pair(lambda s: h.put(m, MK, s * 50, 40, (0.07, 0.06, 0.04), "Mark", off=0.0))
    eyes(m, h, 36, 18, rx=0.14, rz=0.16)
    mouth(m, h, -16, w=26, kind="smile", sag=8, r=0.026)
    blush(m, h, 58, -4, 0.08)
    return {"L": 3.0}

@pet("Scarab")
def scarab(m):
    SH, UND, HD, DK = P("1FB89E", "ME"), P("17575F"), P("F2C14E", "ME"), P("17575F")
    ell(m, UND, (0, 0.1, 0.4), (0.6, 0.76, 0.26), part="Belly")
    sh = Head((0, 0.18, 0.5), (0.66, 0.78, 0.5)); ell(m, SH, sh.c, sh.r, seg=16, rings=9)
    vtube(m, HD, [sh.pt(180, a, 0.0)[0] for a in (5, 30, 60, 90)] + [sh.pt(0, 80, 0)[0], sh.pt(0, 55, 0)[0]], [0.035] * 6, seg=6, part="Mark", smooth=2)
    p, n = sh.pt(180, 52, 0.0)
    disc(m, HD, [(math.cos(a) * 0.2, math.sin(a) * 0.2) for a in [2 * math.pi * i / 14 for i in range(14)]], 0.04, p + n * 0.01, normal=n, part="Mark")
    pair(lambda s: vtube(m, HD, [sh.pt(s * 60, 8, 0.0)[0], sh.pt(s * 95, 10, 0.0)[0], sh.pt(s * 150, 8, 0.0)[0]], [0.03] * 3, seg=6, part="Mark", smooth=3))
    h = Head((0, -0.62, 0.62), (0.44, 0.34, 0.36)); ell(m, HD, h.c, h.r, part="Accent", seg=12, rings=8)
    horn(m, HD, h.pt(0, 50, -0.05)[0], (0, -0.88, 1.12), (0, -0.74, 1.4), 0.1, part="Accent")
    for s in (-1, 1):
        p, n = h.pt(s * 40, 55, -0.02)
        vtube(m, DK, [p, p + Vector((s * 0.12, -0.1, 0.22)), p + Vector((s * 0.22, -0.12, 0.3))], [0.025, 0.02, 0.02], seg=5, part="Belly", smooth=2)
        ell(m, HD, p + Vector((s * 0.24, -0.12, 0.32)), 0.06, part="Accent", seg=8)
        for k, y in enumerate((-0.35, 0.1, 0.55)):
            vtube(m, DK, [(s * 0.5, y, 0.35), (s * 0.78, y - 0.05, 0.28), (s * 0.84, y - 0.1, 0.04)], [0.06, 0.05, 0.045], seg=6, part="Belly", smooth=2)
    eyes(m, h, 32, 6, rx=0.12, rz=0.15)
    mouth(m, h, -22, w=12, kind="smile", sag=6)
    blush(m, h, 54, -10, 0.07)
    return {"L": 3.1}

@pet("Sphinx Cat")
def sphinx(m):
    B, BE, NEM = P("EAC184"), P("FFF0D4"), P("F5C443", "ME")
    ell(m, B, (0, 0.18, 0.6), (0.5, 0.56, 0.6))
    ell(m, BE, (0, -0.2, 0.74), (0.34, 0.24, 0.4), part="Belly")
    h = Head((0, -0.04, 1.58), (0.6, 0.52, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.47, 1.43), (0.24, 0.14, 0.13)); ell(m, BE, sn.c, sn.r, part="Belly", seg=12)
    pointy_ear(m, B, P("FFC7AE"), h, 38, 50, height=0.55, width=0.26, out=22, back=-6, ipart="Blush")
    cap = Head((0, 0.06, 1.7), (0.64, 0.57, 0.48)); ell(m, NEM, cap.c, cap.r, part="Accent", seg=14, rings=8)
    for z in (1.92,):
        dz = (z - cap.c.z) / cap.r.z; k = math.sqrt(1 - dz * dz)
        pts = [(cap.c.x + math.cos(a) * cap.r.x * k * 1.01, cap.c.y + math.sin(a) * cap.r.y * k * 1.01, z) for a in [2 * math.pi * i / 14 for i in range(14)]]
        from w2lib import tube
        tube(m, TQ, pts, r=0.035, seg=5, part="Mark", closed=True, smooth=1)
    for s in (-1, 1):
        segtube(m, [NEM, TQ], ["Accent", "Mark"], [(s * 0.55, -0.12, 1.5), (s * 0.5, -0.24, 1.15), (s * 0.4, -0.3, 0.88)], [0.17, 0.17, 0.19], 0.13, seg=8, smooth=2, sq=0.45)
    from w2lib import tube
    pts = [(math.cos(a) * 0.42, -0.02 + math.sin(a) * 0.36, 1.06 - 0.1 * max(0, -math.sin(a))) for a in [2 * math.pi * i / 16 for i in range(16)]]
    tube(m, NEM, pts, r=0.08, seg=5, part="Accent", closed=True, smooth=1, sq=0.4)
    for i, a in enumerate([-math.pi / 2 + d for d in (-0.6, -0.3, 0.0, 0.3, 0.6)]):
        ell(m, TQ, (math.cos(a) * 0.43, -0.02 + math.sin(a) * 0.38, 0.98), 0.055, part="Mark", seg=8)
    p, n = cap.pt(0, 42); gem(m, P("4FF2E0", "NE"), p + n * 0.06, 0.09, part="Glow", rot=(70, 0, 0))
    pair(lambda s: leg(m, B, (s * 0.2, -0.26, 0.55), (s * 0.21, -0.36, 0.1), r=0.1))
    pair(lambda s: ell(m, B, (s * 0.36, 0.2, 0.28), (0.2, 0.34, 0.26)))
    vtube(m, B, [(0.3, 0.6, 0.12), (0.62, 0.3, 0.1), (0.55, -0.25, 0.1), (0.3, -0.5, 0.15)], [0.08, 0.08, 0.07, 0.05], seg=8)
    eyes(m, h, 26, 6, rx=0.13, rz=0.15, tilt=12)
    for s in (-1, 1):
        p, n = h.pt(s * 41, 8, 0.03)
        vtube(m, INK, [p, p + Vector((s * 0.12, 0.04, -0.02))], [0.022, 0.008], seg=5, part="Eye", smooth=1)
    p, n = sn.pt(0, 30); ell(m, P("C26A6A"), p + n * 0.01, (0.06, 0.04, 0.04), part="Nose", seg=8)
    mouth(m, sn, -20, w=16, kind="w", sag=10)
    blush(m, h, 48, -10, 0.09)





