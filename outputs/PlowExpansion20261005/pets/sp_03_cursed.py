# Cursed Egg: playful spooky silhouettes, controlled violet accents.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet

def pair(f):
    for s in (-1, 1): f(s)

@pet("Shadow Bat")
def shadow_bat(m):
    B, FACE, VI = P("3D2E5C"), P("C3B0F2"), P("7A4FD0")
    ell(m, B, (0, 0.05, 1.12), (0.62, 0.56, 0.6), seg=12, rings=8)
    face = Head((0, -0.16, 1.06), (0.47, 0.42, 0.4)); ell(m, FACE, face.c, face.r, part="Belly", seg=12, rings=8)
    h = Head((0, 0.05, 1.12), (0.62, 0.56, 0.6))
    pointy_ear(m, B, VI, h, 34, 46, height=0.66, width=0.3, out=26, back=-4, ipart="Mark")
    cone(m, B, h.pt(0, 80, -0.05)[0], (0.06, 0.02, 1.86), 0.12, seg=7, part="Body")
    wings(m, VI, "bat", (0.48, 0.15, 1.15), span=1.15, hgt=0.72, thick=0.06, spread=(18, 22, 8), part="Accent")
    pair(lambda s: ell(m, B, (s * 0.2, -0.05, 0.52), (0.1, 0.12, 0.12), seg=8))
    eyes(m, face, 26, 8, rx=0.13, rz=0.16)
    mouth(m, face, -22, w=12, kind="smile", sag=6)
    fang(m, face, -7, -25, 0.07)
    fang(m, face, 7, -25, 0.07)
    blush(m, face, 46, -10, 0.08)
    return {"H": 2.4}

@pet("Ghost")
def ghost(m):
    B, BOW, TONG = P("F2ECFF", "SP", 0.15), P("8D5BE0"), P("FF7FA8")
    prof = [(0.62, 0.1), (0.66, 0.36), (0.66, 0.75), (0.6, 1.15), (0.48, 1.5), (0.28, 1.74), (0.0, 1.82)]
    lathe_wave(m, B, prof, seg=24, part="Body", wave=(6, 0.09), wave_rings=2)
    ell(m, B, (0, 0.05, 0.12), (0.5, 0.5, 0.08), seg=12, rings=5)
    vtube(m, B, [(0.15, 0.45, 0.22), (0.25, 0.85, 0.2), (0.42, 1.0, 0.42), (0.36, 0.92, 0.6)], [0.22, 0.14, 0.08, 0.0], seg=10)
    ell(m, B, (-0.66, -0.08, 0.98), (0.2, 0.15, 0.13), rot=(0, 30, 0), seg=10)
    ell(m, B, (0.64, -0.12, 1.12), (0.2, 0.15, 0.13), rot=(0, 50, 0), seg=10)
    h = Head((0, 0, 1.18), (0.62, 0.62, 0.6))
    eyes(m, h, 24, 6, rx=0.13, rz=0.18)
    mouth(m, h, -12, w=10, kind="smile", sag=5)
    p, n = h.pt(4, -16, 0.0)
    ell(m, TONG, p + n * 0.02 + Vector((0, 0, -0.04)), (0.07, 0.04, 0.08), part="Mouth", seg=8)
    blush(m, h, 42, -6, 0.09)
    p, n = h.pt(-40, 52, 0.0)
    for s in (-1, 1):
        ell(m, BOW, p + n * 0.05 + Vector((s * 0.14, 0, s * 0.03)), (0.14, 0.06, 0.1), part="Accent", rot=(0, s * 20, 30), seg=10)
    ell(m, BOW, p + n * 0.07, 0.06, part="Accent", seg=8)
    return {"H": 2.4}

@pet("Imp")
def imp(m):
    B, BE, HN = P("B44690"), P("F3A8CF"), P("3A2342")
    ell(m, B, (0, 0.08, 0.5), (0.4, 0.36, 0.45))
    ell(m, BE, (0, -0.18, 0.46), (0.28, 0.16, 0.3), part="Belly")
    h = Head((0, -0.04, 1.28), (0.6, 0.52, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    for s in (-1, 1):
        p, n = h.pt(s * 34, 52, -0.06)
        horn(m, HN, p, p + Vector((s * 0.16, 0.0, 0.25)), p + Vector((s * 0.06, 0.06, 0.48)), 0.11, part="Accent")
    pointy_ear(m, B, BE, h, 82, 8, height=0.42, width=0.18, out=78, back=-10, thick=0.4, ipart="Belly")
    wings(m, HN, "bat", (0.2, 0.32, 0.9), span=0.62, hgt=0.42, thick=0.05, spread=(25, 35, 0), part="Accent")
    vtube(m, B, [(0, 0.38, 0.3), (0.2, 0.75, 0.25), (0.45, 0.82, 0.5), (0.5, 0.65, 0.76)], [0.06, 0.05, 0.04, 0.035], seg=6)
    disc(m, HN, heart_poly(0.012, 20), 0.05, (0.5, 0.62, 0.86), normal=(0.3, -1, 0), part="Accent")
    pair(lambda s: foot(m, B, s * 0.2, -0.12, 0.13))
    pair(lambda s: vtube(m, B, [(s * 0.34, -0.05, 0.7), (s * 0.5, -0.15, 0.5)], [0.08, 0.07], seg=6, smooth=1))
    eyes(m, h, 26, 4, rx=0.13, rz=0.155, tilt=-8)
    mouth(m, h, -16, w=16, kind="smile", sag=7)
    fang(m, h, 6, -19, 0.06)
    blush(m, h, 46, -8, 0.09, pc=P("FF7FB6"))

@pet("Shadow Wolf")
def shadow_wolf(m):
    B, BE, MK, GL = P("3C3557"), P("A79BD0"), P("292340"), P("B27CFF", "NE")
    ell(m, B, (0, 0.28, 0.8), (0.46, 0.72, 0.42))
    h = Head((0, -0.55, 1.42), (0.56, 0.5, 0.48)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mask = Head((0, -0.68, 1.36), (0.44, 0.4, 0.36)); ell(m, BE, mask.c, mask.r, part="Belly", seg=12, rings=8)
    sn = Head((0, -1.0, 1.26), (0.2, 0.26, 0.16)); ell(m, BE, sn.c, sn.r, part="Belly", seg=12)
    for a in range(-80, 81, 32):
        b = Vector((math.sin(math.radians(a)) * 0.42, -0.42 - math.cos(math.radians(a)) * 0.15, 1.05))
        cone(m, BE, b, b + Vector((math.sin(math.radians(a)) * 0.3, -0.12, -0.3)), 0.16, seg=7, part="Belly")
    pointy_ear(m, B, MK, h, 32, 48, height=0.6, width=0.24, out=12, back=-8, ipart="Mark")
    for sx in (-1, 1):
        for y in (-0.2, 0.72):
            leg(m, B, (sx * 0.27, y, 0.7), (sx * 0.28, y, 0.1), r=0.13, paw=1.15)
        p, n = Head((0, 0.28, 0.8), (0.46, 0.72, 0.42)).pt(sx * 90 + 180 * 0, 30)
    for y, z in ((0.1, 1.2), (0.38, 1.21), (0.66, 1.16)):
        ell(m, MK, (0, y, z), (0.2, 0.08, 0.06), part="Mark", seg=8, rings=5)
    vtube(m, B, [(0, 0.9, 0.95), (0.1, 1.2, 1.25), (0.15, 1.2, 1.65), (0.05, 1.0, 1.85)], [0.12, 0.24, 0.22, 0.0], seg=12)
    p, n = h.pt(0, 46, 0.0)
    poly = [(math.cos(a) * 0.14, math.sin(a) * 0.14) for a in [math.radians(40 + 280 * i / 14) for i in range(15)]]
    poly += [(math.cos(a) * 0.1 + 0.05, math.sin(a) * 0.1) for a in [math.radians(300 - 240 * i / 10) for i in range(11)]]
    disc(m, GL, poly, 0.04, p + n * 0.02, normal=n, part="Glow", spin=0)
    eyes(m, mask, 28, 10, rx=0.12, rz=0.145, tilt=10)
    p, n = sn.pt(0, 22); ell(m, P("1E1A2E"), p + n * 0.01, (0.08, 0.05, 0.055), part="Nose", seg=8)
    mouth(m, sn, -26, w=16, kind="w", sag=8)
    blush(m, mask, 50, -8, 0.08)
    return {}

@pet("Void Demon")
def void_demon(m):
    B, BE, HN, WG, GL = P("2B2148"), P("8656DD"), P("EFE6FF"), P("4B2F8C"), P("CB86FF", "NE")
    ell(m, B, (0, 0.06, 0.92), (0.66, 0.56, 0.75), seg=12, rings=8)
    ell(m, BE, (0, -0.28, 0.85), (0.44, 0.3, 0.5), part="Belly")
    h = Head((0, -0.08, 1.85), (0.6, 0.53, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    face = Head((0, -0.2, 1.8), (0.47, 0.42, 0.38)); ell(m, BE, face.c, face.r, part="Belly", seg=12, rings=8)
    for s in (-1, 1):
        p, n = h.pt(s * 52, 40, -0.06)
        vtube(m, HN, [p, p + Vector((s * 0.34, 0.08, 0.18)), p + Vector((s * 0.46, 0.1, 0.5)), p + Vector((s * 0.3, -0.02, 0.68)), p + Vector((s * 0.16, -0.1, 0.62))],
              [0.15, 0.12, 0.09, 0.05, 0.0], seg=8, part="Accent")
    wings(m, WG, "dragon", (0.4, 0.32, 1.3), span=1.35, hgt=0.95, thick=0.07, spread=(20, 28, 6), part="AccentWing")
    from w2lib import tube
    pts = [(math.cos(a) * 0.4, 0.12 + math.sin(a) * 0.4, 2.62) for a in [2 * math.pi * i / 20 for i in range(20)]]
    tube(m, GL, pts, r=0.045, seg=5, part="Glow", closed=True, smooth=1)
    vtube(m, B, [(0, 0.5, 0.4), (0.35, 0.95, 0.35), (0.6, 1.0, 0.7)], [0.12, 0.08, 0.05], seg=8)
    cone(m, HN, (0.6, 1.0, 0.7), (0.7, 1.02, 0.95), 0.12, seg=4, part="Accent")
    pair(lambda s: vtube(m, B, [(s * 0.6, -0.02, 1.25), (s * 0.85, -0.12, 0.9), (s * 0.8, -0.24, 0.62)], [0.16, 0.16, 0.17], seg=8, smooth=2))
    for s in (-1, 1):
        for k in (-1, 0, 1):
            cone(m, HN, (s * 0.8 + k * 0.06, -0.36, 0.6), (s * 0.82 + k * 0.08, -0.48, 0.48), 0.04, seg=5, part="Accent")
        ell(m, B, (s * 0.8, -0.28, 0.6), (0.18, 0.17, 0.16), seg=8, rings=6)
        ell(m, B, (s * 0.34, -0.15, 0.14), (0.26, 0.34, 0.15), seg=12)
    eyes(m, face, 26, 10, rx=0.13, rz=0.155, tilt=-6)
    mouth(m, face, -24, w=16, kind="smile", sag=8, r=0.028)
    fang(m, face, -8, -29, 0.08); fang(m, face, 8, -29, 0.08)
    blush(m, face, 48, -8, 0.09, pc=P("FF86C8"))


