# Crystal Egg: clean faceted crystals, readable bright cores.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import rock

def pair(f):
    for s in (-1, 1): f(s)

CY = P("6FDCFF")
PK = P("FF84CF")

@pet("Gem Slime")
def gem_slime(m):
    B, CORE = P("6ED8FF", "SP", 0.25), P("FF8FE0", "NE")
    prof = [(0.0, 0.0), (0.66, 0.02), (0.78, 0.2), (0.76, 0.44), (0.64, 0.74), (0.46, 0.98), (0.26, 1.18), (0.1, 1.34), (0.0, 1.4)]
    lathe(m, B, prof, seg=18, part="Body")
    vtube(m, B, [(0.0, 0.0, 1.28), (0.08, 0.04, 1.5), (-0.04, 0.1, 1.62)], [0.12, 0.08, 0.0], seg=8)
    pair(lambda s: ell(m, B, (s * 0.72, -0.2, 0.08), (0.18, 0.18, 0.1), seg=8))
    gem(m, CORE, (0, 0.3, 0.38), 0.15, h=0.28, seg=6, part="Glow")
    gem(m, PK, (0.3, 0.06, 1.12), 0.18, h=0.3, seg=6, part="Accent", rot=(0, 25, 0))
    f = LatheFace(prof, (0, 0), 0.55, 0.3)
    eyes(m, f, 26, 4, rx=0.14, rz=0.17)
    mouth(m, f, -36, w=14, kind="smile", sag=8)
    blush(m, f, 46, -22, 0.1)
    return {"H": 2.2}

@pet("Crystal Bunny")
def crystal_bunny(m):
    B, BE = P("EEF2FF"), P("D3DEFF")
    ell(m, B, (0, 0.12, 0.5), (0.52, 0.48, 0.5))
    h = Head((0, -0.05, 1.3), (0.64, 0.56, 0.55)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, BE, (0, -0.26, 0.45), (0.32, 0.2, 0.3), part="Belly")
    for s in (-1, 1):
        b, n = h.pt(s * 22, 62, -0.08)
        crystal(m, CY, b, (s * 0.25, 0.08, 1), 0.95, 0.15, seg=6, part="Accent")
        b2, n2 = h.pt(s * 40, 52, -0.06)
        crystal(m, CY, b2, (s * 0.8, 0.1, 0.7), 0.4, 0.09, seg=6, part="Accent")
    b, n = h.pt(0, 34, 0.0); gem(m, PK, b + n * 0.05, 0.1, h=0.16, part="AccentGem", rot=(70, 0, 0))
    for d in ((0, 1, 0.4), (0.5, 1, 0.8), (-0.5, 1, 0.6)):
        crystal(m, CY, (0, 0.55, 0.45), d, 0.36, 0.08, seg=6, part="Accent")
    pair(lambda s: foot(m, B, s * 0.24, -0.38, 0.16))
    pair(lambda s: ell(m, B, (s * 0.4, 0.08, 0.13), (0.19, 0.3, 0.13)))
    eyes(m, h, 27, 2, rx=0.135, rz=0.165)
    nose(m, h, -12, (0.06, 0.04, 0.045), pc=P("FF8FC8"))
    mouth(m, h, -20, w=7, kind="w", sag=4)
    blush(m, h, 44, -10, 0.1)

@pet("Prism Bird")
def prism_bird(m):
    B, BE, WG, TL, CR, BK = P("F4F8FF"), P("D7E3FF"), P("FF97D4"), P("6FDCFF"), P("FFE266"), P("F2B84A")
    body = Head((0, 0.05, 0.92), (0.66, 0.6, 0.66)); ell(m, B, body.c, body.r, seg=9, rings=6); m.flat("Body", B, 15)
    ell(m, BE, (0, -0.2, 0.74), (0.5, 0.42, 0.48), part="Belly", seg=8, rings=6); m.flat("Belly", BE, 15)
    wings(m, WG, "shard", (0.5, 0.12, 0.98), span=0.85, hgt=0.6, thick=0.07, spread=(-10, 32, 0), part="Accent")
    for k, (dx, dz) in enumerate(((-0.18, 0.1), (0.0, 0.18), (0.18, 0.1))):
        crystal(m, TL, (dx * 0.5, 0.55, 0.85), (dx * 2, 1, 0.35 + dz), 0.55, 0.09, seg=4, part="AccentTail")
    for k, (dx, ln) in enumerate(((-0.12, 0.32), (0.0, 0.45), (0.12, 0.32))):
        crystal(m, CR, (dx, -0.05, 1.5), (dx * 3, 0.5, 1), ln, 0.07, seg=4, part="AccentCrest")
    p, n = body.pt(0, 4)
    cone(m, BK, p - n * 0.04, p + n * 0.24 + Vector((0, 0, -0.04)), 0.12, seg=4, part="AccentBeak")
    pair(lambda s: (vtube(m, BK, [(s * 0.2, 0.0, 0.32), (s * 0.22, -0.05, 0.08)], [0.04, 0.04], seg=5, part="AccentBeak", smooth=1),
                    ell(m, BK, (s * 0.22, -0.12, 0.05), (0.1, 0.14, 0.05), part="AccentBeak", seg=6)))
    eyes(m, body, 30, 18, rx=0.13, rz=0.16)
    blush(m, body, 50, 4, 0.09)
    return {"H": 2.5}

@pet("Crystal Golem")
def crystal_golem(m):
    B, PLATE, GL = P("5E6F9C"), P("B3C3EA"), P("7FF0FF", "NE")
    rock(m, B, (0, 0.05, 1.0), (0.66, 0.5, 0.55), seed=3, sub=2, jag=0.08, part="Body")
    rock(m, B, (0, -0.08, 1.78), (0.56, 0.48, 0.44), seed=5, sub=2, jag=0.06, part="Body")
    m.flat("Body", B, 1)
    face = Head((0, -0.3, 1.74), (0.42, 0.36, 0.32)); ell(m, PLATE, face.c, face.r, part="Belly", seg=10, rings=6); m.flat("Belly", PLATE, 25)
    for s in (-1, 1):
        rock(m, B, (s * 0.72, 0.0, 1.32), (0.3, 0.3, 0.28), seed=7 + s, sub=1, jag=0.1, part="Body")
        rock(m, B, (s * 0.82, -0.06, 0.88), (0.2, 0.2, 0.3), seed=9 + s, sub=1, jag=0.1, part="Body")
        rock(m, B, (s * 0.84, -0.14, 0.5), (0.3, 0.3, 0.26), seed=11 + s, sub=1, jag=0.1, part="Body")
        rock(m, B, (s * 0.32, -0.04, 0.22), (0.24, 0.3, 0.22), seed=13 + s, sub=1, jag=0.1, part="Body")
        crystal(m, CY, (s * 0.75, 0.05, 1.5), (s * 0.4, 0.2, 1), 0.48, 0.11, part="Accent")
        crystal(m, CY, (s * 0.6, 0.15, 1.5), (s * 0.1, 0.4, 1), 0.32, 0.08, part="Accent")
    crystal(m, CY, (0.15, 0.1, 2.1), (0.3, 0.2, 1), 0.42, 0.1, part="Accent")
    crystal(m, CY, (-0.18, 0.15, 2.08), (-0.4, 0.3, 1), 0.3, 0.08, part="Accent")
    crystal(m, CY, (0, 0.5, 1.2), (0, 1, 0.6), 0.4, 0.1, part="Accent")
    gem(m, GL, (0, -0.5, 1.02), 0.15, h=0.26, part="Glow", rot=(90, 0, 0))
    eyes(m, face, 30, 8, rx=0.11, rz=0.13)
    mouth(m, face, -30, w=14, kind="smile", sag=6)
    blush(m, face, 52, -10, 0.07)

@pet("Diamond Dragon")
def diamond_dragon(m):
    B, BE, GL = P("BFEBFF"), P("F6FBFF"), P("CFF8FF", "NE")
    ell(m, B, (0, 0.18, 0.72), (0.55, 0.56, 0.62), seg=10, rings=6)
    h = Head((0, -0.22, 1.68), (0.56, 0.5, 0.48)); ell(m, B, h.c, h.r, seg=10, rings=7)
    sn = Head((0, -0.66, 1.56), (0.32, 0.24, 0.2)); ell(m, B, sn.c, sn.r, seg=8, rings=5)
    m.flat("Body", B, 18)
    for k, z in enumerate((0.38, 0.62, 0.86, 1.1)):
        w = 0.36 - abs(k - 1.2) * 0.04
        box(m, BE, (0, -0.32 + k * 0.025, z), (w * 1.6, 0.14, 0.2), r=0.03, part="Belly", rot=(-8, 0, 0))
    for s in (-1, 1):
        b, n = h.pt(s * 30, 55, -0.05)
        crystal(m, CY, b, (s * 0.25, 0.7, 0.75), 0.55, 0.09, part="Accent")
        crystal(m, CY, h.pt(s * 62, 30, -0.04)[0], (s * 0.8, 0.5, 0.2), 0.3, 0.06, part="Accent")
    for k, (y, z) in enumerate(((0.05, 2.06), (0.32, 1.88), (0.6, 1.36), (0.74, 1.02), (0.78, 0.66))):
        crystal(m, CY, (0, y, z - 0.08), (0, 0.5, 1), 0.3 - k * 0.02, 0.08, seg=4, part="Accent")
    wings(m, CY, "shard", (0.36, 0.4, 1.12), span=1.25, hgt=0.95, thick=0.07, spread=(28, 30, 0), part="Accent")
    vtube(m, B, [(0.1, 0.65, 0.25), (0.5, 0.95, 0.18), (0.85, 0.7, 0.18), (0.95, 0.35, 0.28)], [0.2, 0.15, 0.1, 0.06], seg=8)
    gem(m, CY, (0.98, 0.25, 0.3), 0.16, h=0.3, part="Accent", rot=(0, 90, 30))
    pair(lambda s: vtube(m, B, [(s * 0.42, -0.2, 0.95), (s * 0.5, -0.38, 0.72), (s * 0.44, -0.46, 0.55)], [0.11, 0.1, 0.1], seg=7, smooth=2))
    pair(lambda s: ell(m, B, (s * 0.36, -0.12, 0.13), (0.22, 0.32, 0.14), seg=8, rings=5))
    gem(m, GL, (0, -0.47, 1.28), 0.12, h=0.2, part="Glow", rot=(95, 0, 0))
    eyes(m, h, 28, 10, rx=0.13, rz=0.155)
    for s in (-1, 1): sn.put(m, P("6A8DB8"), s * 25, 25, (0.035, 0.02, 0.025), "Nose", off=0.01)
    mouth(m, sn, -20, w=24, kind="smile", sag=8)
    blush(m, h, 52, -6, 0.09)

