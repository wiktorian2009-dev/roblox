# Star (Cosmic) Egg: indigo, violet, star yellow, cyan.
import math, random
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import tube

def pair(f):
    for s in (-1, 1): f(s)

STAR = P("FFE066")
CYAN = P("6FE8FF")
INDIGO = P("3C2E8F")

def stars_on(m, pc, surf, spots, r=0.06, part="Mark", off=0.004):
    for (a, pp) in spots:
        p, n = surf.pt(a, pp)
        disc(m, pc, star_poly(r, r * 0.45), 0.025, p + n * off, normal=n, part=part, spin=a)

@pet("Comet Pup")
def comet_pup(m):
    B, BE, MK, GL = P("A9D8FF"), P("EEF7FF"), P("5C6FD6"), P("FFF2A8", "NE")
    ell(m, B, (0, 0.12, 0.56), (0.46, 0.5, 0.54))
    ell(m, BE, (0, -0.2, 0.58), (0.3, 0.24, 0.36), part="Belly")
    h = Head((0, -0.07, 1.36), (0.62, 0.55, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.5, 1.22), (0.27, 0.2, 0.19)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    for s in (-1, 1):
        b = h.pt(s * 58, 42, -0.06)[0]
        vtube(m, MK, [b, b + Vector((s * 0.2, 0.02, 0.02)), b + Vector((s * 0.3, -0.02, -0.28)), b + Vector((s * 0.28, -0.06, -0.55))], [0.12, 0.17, 0.17, 0.08], seg=8, part="Mark", sq=0.45, up=(s, 0, 0))
    p, n = h.pt(0, 42); disc(m, STAR, star_poly(0.15, 0.07), 0.04, p + n * 0.01, normal=n, part="Accent")
    p, n = mz.pt(0, 34); ell(m, P("2A2440"), p + n * 0.01, (0.08, 0.05, 0.055), part="Nose", seg=8)
    pair(lambda s: leg(m, B, (s * 0.2, -0.22, 0.55), (s * 0.22, -0.32, 0.1), r=0.1))
    pair(lambda s: ell(m, B, (s * 0.34, 0.16, 0.26), (0.2, 0.32, 0.26)))
    tail = [(0, 0.55, 0.5), (0.1, 0.85, 0.75), (0.3, 1.0, 1.15), (0.5, 0.95, 1.55)]
    vtube(m, CYAN, tail, [0.06, 0.12, 0.16, 0.18], seg=10, part="AccentTail")
    vtube(m, P("B48CFF"), [(0.12, 0.88, 0.82), (0.32, 1.02, 1.2), (0.52, 0.96, 1.58)], [0.07, 0.1, 0.13], seg=8, part="AccentTail2")
    ell(m, GL, (0.52, 0.94, 1.62), 0.2, part="Glow", seg=10)
    eyes(m, h, 26, 4, rx=0.125, rz=0.15)
    mouth(m, mz, -20, w=18, kind="w", sag=10)
    blush(m, h, 48, -10, 0.09)

@pet("Moon Bunny")
def moon_bunny(m):
    B, BE, MOON = P("F1ECFF"), P("FFFFFF"), P("FFD36E", "ME")
    arc = []
    for i in range(9):
        a = math.radians(200 + 140 * i / 8)
        arc.append((math.cos(a) * 0.85, 0.05, 0.95 + math.sin(a) * 0.82))
    vtube(m, MOON, arc, [0.02, 0.12, 0.2, 0.26, 0.28, 0.26, 0.2, 0.12, 0.02], seg=10, part="Accent", smooth=2, sq=1.0)
    ell(m, B, (0, 0.08, 0.58), (0.46, 0.42, 0.42))
    h = Head((0, -0.05, 1.3), (0.6, 0.52, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, BE, (0, -0.24, 0.55), (0.28, 0.16, 0.26), part="Belly")
    long_ear(m, B, P("D8C6FF"), h, 20, 62, length=0.85, width=0.19, out=6, back=-6, ipart="Blush", sides=(-1,))
    long_ear(m, B, P("D8C6FF"), h, 20, 62, length=0.8, width=0.19, out=28, back=-8, droop=0.3, ipart="Blush", sides=(1,))
    p, n = h.pt(-30, 50); disc(m, STAR, star_poly(0.11, 0.05), 0.04, p + n * 0.02, normal=n, part="Mark")
    for s in (-1, 1):
        ell(m, B, (s * 0.22, -0.36, 0.3), (0.13, 0.16, 0.13), seg=8)
    ell(m, B, (0, 0.5, 0.55), 0.16, seg=8)
    eyes(m, h, 26, 2, rx=0.13, rz=0.16)
    nose(m, h, -12, (0.055, 0.04, 0.045), pc=P("FF9FC8"))
    mouth(m, h, -20, w=7, kind="w", sag=4)
    blush(m, h, 44, -10, 0.1)
    return {"H": 2.6}

@pet("Astro Cat")
def astro_cat(m):
    B, SUIT, PACK, GL = P("FFAE5C"), P("F4F7FF"), P("7A6CF0"), P("FFF2A8", "NE")
    ell(m, SUIT, (0, 0.12, 0.56), (0.46, 0.46, 0.54), part="Belly")
    box(m, PACK, (0, 0.55, 0.7), (0.56, 0.24, 0.6), r=0.08, part="Accent")
    h = Head((0, -0.05, 1.38), (0.6, 0.52, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.48, 1.25), (0.22, 0.13, 0.12)); ell(m, P("FFF1E0"), mz.c, mz.r, part="BellyFace", seg=10, rings=6)
    pointy_ear(m, B, BLUSH, h, 36, 50, height=0.5, width=0.25, out=18, back=-6, ipart="Blush")
    pts = [h.c + Vector((math.cos(a) * 0.62, -0.32, math.sin(a) * 0.58)) for a in [2 * math.pi * i / 20 for i in range(20)]]
    tube(m, SUIT, pts, r=0.07, seg=6, part="Belly", closed=True, smooth=1)
    for k, a in enumerate((-60, -30, 0, 30, 60)):
        p, n = h.pt(a + 180, 30)
    vtube(m, PACK, [h.pt(64, 46, -0.02)[0], h.pt(64, 46, 0.32)[0]], [0.025, 0.025], seg=5, part="Accent", smooth=1)
    p = h.pt(64, 46, 0.34)[0]; disc(m, GL, star_poly(0.1, 0.045), 0.04, p, normal=(0, -1, 0), part="Glow")
    for s in (-1, 1):
        ell(m, SUIT, (s * 0.24, -0.3, 0.14), (0.15, 0.2, 0.14), part="Belly", seg=8)
        vtube(m, SUIT, [(s * 0.4, -0.05, 0.8), (s * 0.55, -0.22, 0.6)], [0.1, 0.09], seg=7, part="Belly", smooth=1)
        ell(m, B, (s * 0.57, -0.26, 0.56), 0.09, seg=8)
        ell(m, PACK, (s * 0.22, -0.3, 0.06), (0.16, 0.22, 0.06), part="Accent", seg=8)
    disc(m, CYAN, [(math.cos(a) * 0.12, math.sin(a) * 0.12) for a in [2 * math.pi * i / 10 for i in range(10)]], 0.03, (0, -0.44, 0.75), normal=(0, -1, 0.1), part="AccentBadge")
    disc(m, STAR, star_poly(0.08, 0.035), 0.035, (0, -0.47, 0.76), normal=(0, -1, 0.1), part="Mark")
    vtube(m, B, [(0.3, 0.45, 0.3), (0.6, 0.6, 0.4), (0.7, 0.5, 0.75), (0.6, 0.45, 0.9)], [0.07, 0.07, 0.065, 0.05], seg=7)
    eyes(m, h, 26, 6, rx=0.13, rz=0.155)
    nose(m, mz, 30, (0.05, 0.03, 0.03), pc=P("FF7F9A"))
    mouth(m, mz, -14, w=18, kind="w", sag=10)
    blush(m, h, 46, -10, 0.09)

@pet("Nebula Fox")
def nebula_fox(m):
    B, BE, TL, TIP = P("C77DFF"), P("F3E6FF"), INDIGO, CYAN
    ell(m, B, (0, 0.14, 0.55), (0.46, 0.52, 0.55))
    h = Head((0, -0.06, 1.33), (0.62, 0.55, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.5, 1.2), (0.22, 0.28, 0.18)); ell(m, BE, sn.c, sn.r, part="Belly", seg=10, rings=7)
    ell(m, BE, (0, -0.26, 0.74), (0.32, 0.22, 0.34), part="Belly")
    pair(lambda s: cone(m, BE, (s * 0.42, -0.2, 1.12), (s * 0.78, -0.12, 1.02), 0.16, seg=7, part="Belly"))
    pointy_ear(m, B, TIP, h, 34, 50, height=0.66, width=0.27, out=16, back=-6, ipart="AccentCyan")
    pair(lambda s: leg(m, B, (s * 0.2, -0.24, 0.6), (s * 0.22, -0.36, 0.1), r=0.1))
    pair(lambda s: ell(m, B, (s * 0.36, 0.18, 0.3), (0.2, 0.34, 0.28)))
    tp = [(0.25, 0.55, 0.2), (0.7, 0.4, 0.22), (0.75, -0.1, 0.24), (0.4, -0.5, 0.22), (-0.1, -0.6, 0.2)]
    vtube(m, TL, tp, [0.14, 0.26, 0.28, 0.24, 0.12], seg=12, part="Accent")
    vtube(m, TIP, [(0.12, -0.56, 0.21), (-0.1, -0.6, 0.2), (-0.32, -0.55, 0.2)], [0.2, 0.15, 0.0], seg=12, part="AccentCyan", smooth=2)
    tsurf = Head((0.72, 0.15, 0.24), (0.28, 0.5, 0.26))
    for (a, pp) in [(60, 50), (100, 60), (80, 20), (130, 40), (40, 30)]:
        p, n = tsurf.pt(a, pp); disc(m, STAR, star_poly(0.055, 0.025), 0.02, p + n * 0.06, normal=n, part="Mark")
    for (a, pp) in [(150, 40), (210, 50), (180, 70), (120, 20)]:
        p, n = Head((0, 0.14, 0.55), (0.46, 0.52, 0.55)).pt(a, pp); disc(m, STAR, star_poly(0.05, 0.022), 0.02, p + n * 0.005, normal=n, part="Mark")
    p, n = h.pt(0, 40); disc(m, STAR, star_poly(0.08, 0.035), 0.03, p + n * 0.01, normal=n, part="Mark")
    eyes(m, h, 26, 4, rx=0.13, rz=0.155, tilt=8)
    p, n = sn.pt(0, 12); ell(m, P("3A2457"), p + n * 0.015, (0.07, 0.05, 0.05), part="Nose", seg=8)
    mouth(m, sn, -28, w=12, kind="w", sag=8)
    blush(m, h, 46, -12, 0.09)

@pet("Galaxy Dragon")
def galaxy_dragon(m):
    B, BE, WG, GL = INDIGO, P("C9A8FF"), P("5B3FD0"), P("FFF2A8", "NE")
    ell(m, B, (0, 0.12, 0.92), (0.6, 0.52, 0.76), seg=12, rings=8)
    bel = Head((0, -0.14, 0.85), (0.42, 0.36, 0.56)); ell(m, BE, bel.c, bel.r, part="Belly", seg=12, rings=8)
    h = Head((0, -0.18, 1.92), (0.58, 0.52, 0.48)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.62, 1.7), (0.28, 0.24, 0.17)); ell(m, B, sn.c, sn.r, seg=10, rings=7)
    face = Head((0, -0.36, 1.86), (0.46, 0.44, 0.36)); ell(m, BE, face.c, face.r, part="Belly", seg=12, rings=8)
    for s in (-1, 1):
        b = h.pt(s * 34, 52, -0.05)[0]
        horn(m, CYAN, b, b + Vector((s * 0.15, 0.2, 0.3)), b + Vector((s * 0.1, 0.45, 0.42)), 0.09, part="AccentCyan")
        wings(m, WG, "dragon", (0.42, 0.35, 1.35), span=1.45, hgt=1.0, thick=0.07, spread=(26, 26, 0), part="AccentWing", sides=(s,))
        ell(m, B, (s * 0.36, -0.12, 0.15), (0.26, 0.34, 0.16), seg=10)
        vtube(m, B, [(s * 0.52, -0.1, 1.2), (s * 0.68, -0.3, 1.0)], [0.12, 0.1], seg=7, smooth=1)
        ell(m, B, (s * 0.7, -0.34, 0.98), 0.1, seg=8)
        sn.put(m, P("1E1650"), s * 25, 30, (0.035, 0.02, 0.025), "Nose", off=0.01)
    wsurf = Head((0.9, 0.5, 1.7), (0.5, 0.05, 0.4))
    rnd = random.Random(11)
    for s in (-1, 1):
        for k in range(4):
            while True:
                u, v = rnd.uniform(0.45, 1.2), rnd.uniform(0.35, 0.8)
                if v < u * 0.85: break
            M = Matrix.Translation(Vector((0.42, 0.35, 1.35))) @ Euler((0, math.radians(-26), math.radians(26)), 'XYZ').to_matrix().to_4x4()
            pt = M @ Vector((u, -0.06, v))
            pt.x *= s
            disc(m, STAR, star_poly(0.05, 0.022), 0.02, pt, normal=(s * 0.4, -1, 0.3), part="Mark", spin=k * 20)
    stars_on(m, STAR, bel, [(-20, -30), (25, -10), (-10, 30)], r=0.06)
    vtube(m, B, [(0, 0.55, 0.45), (0.4, 0.95, 0.35), (0.75, 0.9, 0.55), (0.82, 0.62, 0.8)], [0.2, 0.14, 0.09, 0.05], seg=8)
    disc(m, GL, star_poly(0.17, 0.08), 0.06, (0.84, 0.58, 0.86), normal=(0.5, -1, 0.2), part="Glow")
    eyes(m, face, 27, 10, rx=0.13, rz=0.155)
    mouth(m, sn, -22, w=22, kind="smile", sag=8)
    blush(m, face, 50, -10, 0.09)




