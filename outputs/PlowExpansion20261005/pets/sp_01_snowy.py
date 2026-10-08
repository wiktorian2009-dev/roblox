# species_a.py - per-species builders, eggs 1-7 (Snowy, Desert, Cursed, Crystal, Retro, Jungle, Absolute Zero).
# Design space ~ final studs; petkit.finish() recentres and fits the rarity size box.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet

def pair(f):
    for s in (-1, 1): f(s)

# ============================================================== SNOWY EGG
@pet("Snow Bunny")
def snow_bunny(m):
    B, BE, SC, INN = P("F7FAFF"), P("DCE9F7"), P("6EC3F0", "FA"), P("FFB3C7")
    ell(m, B, (0, 0.14, 0.52), (0.55, 0.5, 0.52))
    h = Head((0, -0.05, 1.34), (0.68, 0.6, 0.6)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, BE, (0, -0.27, 0.46), (0.34, 0.2, 0.32), part="Belly")
    long_ear(m, B, INN, h, 20, 62, length=0.9, width=0.2, out=8, back=-6, ipart="Blush", sides=(-1,))
    long_ear(m, B, INN, h, 20, 62, length=0.82, width=0.2, out=30, back=-10, droop=0.28, ipart="Blush", sides=(1,))
    pair(lambda s: foot(m, B, s * 0.24, -0.4, 0.16))
    pair(lambda s: ell(m, B, (s * 0.42, 0.08, 0.13), (0.2, 0.3, 0.13)))
    ell(m, B, (0, 0.66, 0.42), 0.2, seg=10)
    scarf(m, SC, (0, -0.02, 0.83), R=0.5, Ry=0.46, r=0.085, part="Accent", side=-1, tail_len=0.38)
    eyes(m, h, 27, 2, rx=0.135, rz=0.165)
    nose(m, h, -12, (0.06, 0.04, 0.045), pc=P("FF8FAE"))
    mouth(m, h, -20, w=7, kind="w", sag=4)
    blush(m, h, 44, -10, 0.1)

@pet("Penguin")
def penguin(m):
    NV, WH, OR, HAT, POM = P("2B3552"), P("F6F9FF"), P("FFA53A"), P("5BB8EC", "FA"), P("F6F9FF", "FA")
    ell(m, NV, (0, 0.05, 0.62), (0.62, 0.55, 0.62))
    ell(m, NV, (0, 0.0, 1.42), (0.6, 0.55, 0.55), seg=12, rings=8)
    mask = Head((0, -0.14, 1.36), (0.5, 0.45, 0.43)); ell(m, WH, mask.c, mask.r, part="Belly", seg=12, rings=8)
    ell(m, WH, (0, -0.14, 0.58), (0.46, 0.44, 0.5), part="Belly", seg=14)
    p, n = mask.pt(0, -10)
    ell(m, OR, p + Vector((0, -0.04, 0)), (0.14, 0.12, 0.08), part="AccentBeak", seg=10)
    cone(m, OR, p + Vector((0, -0.08, 0.0)), p + Vector((0, -0.24, -0.03)), 0.09, seg=8, part="AccentBeak")
    pair(lambda s: ell(m, NV, (s * 0.64, 0.02, 0.72), (0.1, 0.22, 0.38), rot=(0, -s * 32, 0)))
    pair(lambda s: ell(m, OR, (s * 0.24, -0.36, 0.06), (0.17, 0.23, 0.07), part="AccentBeak", rot=(0, 0, s * 12)))
    ell(m, HAT, (0, 0.0, 1.63), (0.63, 0.58, 0.48), part="AccentHat", seg=12, rings=8)
    from w2lib import tube
    pts = [(math.cos(a) * 0.6, math.sin(a) * 0.555, 1.53) for a in [2 * math.pi * i / 20 for i in range(20)]]
    tube(m, HAT, pts, r=0.08, seg=8, part="AccentHat", closed=True, smooth=1)
    ell(m, POM, (0, 0.03, 2.17), 0.15, part="Belly", seg=10)
    eyes(m, mask, 24, 3, rx=0.12, rz=0.15)
    blush(m, mask, 42, -6, 0.09)
    return {}

@pet("Arctic Fox")
def arctic_fox(m):
    B, BE, MK, INN = P("F2F6FC"), P("FFFFFF"), P("A9DAF7"), P("A9DAF7")
    ell(m, B, (0, 0.14, 0.55), (0.46, 0.52, 0.55))
    h = Head((0, -0.06, 1.33), (0.62, 0.55, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.5, 1.2), (0.22, 0.3, 0.19)); ell(m, BE, sn.c, sn.r, part="Belly", seg=12)
    ell(m, BE, (0, -0.27, 0.78), (0.34, 0.22, 0.3), part="Belly")
    pair(lambda s: cone(m, BE, (s * 0.42, -0.22, 1.14), (s * 0.8, -0.16, 1.02), 0.17, seg=8, part="Belly"))
    pointy_ear(m, B, INN, h, 34, 50, height=0.62, width=0.26, out=16, back=-6, ipart="Mark")
    pair(lambda s: leg(m, B, (s * 0.2, -0.24, 0.6), (s * 0.22, -0.36, 0.1), r=0.1))
    pair(lambda s: ell(m, MK, (s * 0.22, -0.42, 0.07), (0.12, 0.14, 0.07), part="Mark"))
    pair(lambda s: ell(m, B, (s * 0.36, 0.18, 0.3), (0.2, 0.34, 0.28)))
    tp = [(0.18, 0.55, 0.22), (0.62, 0.78, 0.4), (0.88, 0.55, 0.85), (0.78, 0.22, 1.22)]
    vtube(m, B, tp, [0.12, 0.3, 0.34, 0.2], seg=12)
    vtube(m, MK, [(0.86, 0.48, 0.98), (0.78, 0.22, 1.22), (0.66, 0.08, 1.38)], [0.3, 0.24, 0.0], seg=12, part="Mark", smooth=3)
    eyes(m, h, 26, 4, rx=0.13, rz=0.15, tilt=10)
    p, n = sn.pt(0, 10); ell(m, P("2D2433"), p + n * 0.02, (0.075, 0.05, 0.055), part="Nose", seg=8)
    mouth(m, sn, -28, w=12, kind="w", sag=8)
    blush(m, h, 46, -12, 0.09)

@pet("Polar Bear")
def polar_bear(m):
    B, BE, MUFF, BAND = P("F6F7F4"), P("E9E1D2"), P("8FD6F5", "FA"), P("3E82C8")
    ell(m, B, (0, 0.2, 0.78), (0.62, 0.82, 0.58))
    h = Head((0, -0.58, 1.28), (0.62, 0.55, 0.55)); ell(m, B, h.c, h.r, seg=12, rings=8)
    for sx in (-1, 1):
        for y in (-0.3, 0.62):
            leg(m, B, (sx * 0.36, y, 0.6), (sx * 0.38, y, 0.12), r=0.19, paw=1.15)
    ell(m, B, (0, 1.0, 0.92), 0.14, seg=8)
    sn = Head((0, -1.0, 1.12), (0.27, 0.2, 0.19)); ell(m, BE, sn.c, sn.r, part="Belly", seg=12)
    p, n = sn.pt(0, 32); ell(m, P("2B2430"), p + n * 0.005, (0.1, 0.06, 0.065), part="Nose", seg=10)
    mouth(m, sn, -22, w=14, kind="w", sag=10)
    round_ear(m, B, BE, h, 40, 50, r=0.17, ipart="Belly")
    for s in (-1, 1):
        h.put(m, MUFF, s * 72, 30, (0.22, 0.22, 0.22), "AccentMuff", off=0.06, seg=10, rings=7)
    band = [h.pt(s * a, 30 + (90 - 30) * (1 - abs(a) / 72) ** 1.0, 0.06)[0] for s, a in [(-1, 72), (-1, 48), (1, 0), (1, 48), (1, 72)]]
    band = [h.pt(a, 30 + 60 * (1 - abs(a) / 72), 0.05)[0] for a in (-72, -40, 0, 40, 72)]
    vtube(m, BAND, band, [0.055] * 5, seg=6, part="AccentBand", smooth=3)
    eyes(m, h, 30, 6, rx=0.12, rz=0.145)
    blush(m, h, 50, -8, 0.1)
    return {}

@pet("Yeti")
def yeti(m):
    B, FACE, ICE, GL = P("EEF6FF"), P("86BDEB"), P("A6E0FF", "IC"), P("BFF2FF", "NE")
    ell(m, B, (0, 0.05, 0.92), (0.74, 0.6, 0.82), seg=12, rings=8)
    h = Head((0, -0.1, 1.9), (0.62, 0.55, 0.55)); ell(m, B, h.c, h.r, seg=12, rings=8)
    face = Head((0, -0.24, 1.84), (0.46, 0.42, 0.38)); ell(m, FACE, face.c, face.r, part="Belly", seg=12, rings=8)
    ell(m, FACE, (0, -0.32, 0.86), (0.48, 0.3, 0.5), part="Belly", seg=12)
    for (a, p_, ln) in [(-50, 70, 0.32), (-18, 84, 0.36), (18, 84, 0.36), (50, 70, 0.32), (-80, 40, 0.28), (80, 40, 0.28)]:
        b, n = h.pt(a, p_, -0.08); cone(m, B, b, b + n * ln + Vector((0, 0.05, 0.05)), 0.17, seg=7, part="Body")
    pair(lambda s: cone(m, B, (s * 0.62, 0.0, 1.4), (s * 1.0, 0.05, 1.55), 0.22, seg=7, part="Body"))
    pair(lambda s: vtube(m, B, [(s * 0.62, -0.02, 1.32), (s * 0.95, -0.1, 0.92), (s * 0.92, -0.22, 0.55)], [0.2, 0.22, 0.24], seg=10))
    pair(lambda s: ell(m, FACE, (s * 0.92, -0.28, 0.45), (0.24, 0.24, 0.22), part="Belly", seg=10))
    pair(lambda s: ell(m, B, (s * 0.36, -0.2, 0.15), (0.3, 0.4, 0.16), seg=12))
    pair(lambda s: horn(m, ICE, (s * 0.5, -0.02, 2.12), (s * 0.82, -0.05, 2.3), (s * 0.76, -0.12, 2.62), 0.11, part="Accent"))
    for i, a in enumerate((-30, -15, 0, 15, 30)):
        b, n = h.pt(a, 66, -0.05)
        crystal(m, ICE, b, n + Vector((0, 0, 0.6)), 0.34 if a else 0.48, 0.08 if a else 0.1, part="Accent")
    b, n = h.pt(0, 52, 0.02); gem(m, GL, b + n * 0.06, 0.1, part="Glow", rot=(80, 0, 0))
    eyes(m, face, 26, 10, rx=0.12, rz=0.145)
    nose(m, face, -6, (0.08, 0.05, 0.05), pc=P("3C5C8C"))
    mouth(m, face, -28, w=16, kind="smile", sag=9, r=0.03)
    fang(m, face, -9, -32, 0.08, pc=P("FFFFFF"), part="MouthFang"); fang(m, face, 9, -32, 0.08, pc=P("FFFFFF"), part="MouthFang")
    blush(m, face, 48, -10, 0.09)



