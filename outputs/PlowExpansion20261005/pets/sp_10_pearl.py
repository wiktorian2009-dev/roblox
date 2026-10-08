# Pearl (Atlantis) Egg: teal, coral, pearl, gold.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import tube

def pair(f):
    for s in (-1, 1): f(s)

TEAL = P("2FC4B2")
CORAL = P("FF7A5C")
PEARL = P("FFF4E6")
GOLD = P("F5C443", "ME")

@pet("Crab")
def crab(m):
    B, BE, MK = P("FF6F4C"), P("FFE3C8"), P("E04A3A")
    sh = Head((0, 0.05, 0.6), (0.78, 0.56, 0.4)); ell(m, B, sh.c, sh.r, seg=14, rings=8)
    ell(m, BE, (0, -0.05, 0.42), (0.66, 0.48, 0.22), part="Belly")
    for (a, pp) in [(150, 60), (210, 60), (180, 75), (120, 35), (240, 35)]:
        p, n = sh.pt(a, pp); ell(m, MK, p, (0.08, 0.08, 0.04), part="Mark", seg=6, rings=4, q=n.to_track_quat('Z', 'Y'))
    for s in (-1, 1):
        st = [(s * 0.24, -0.25, 0.85), (s * 0.27, -0.3, 1.1), (s * 0.3, -0.3, 1.25)]
        vtube(m, B, st, [0.07, 0.06, 0.06], seg=6, smooth=1)
        eb = Head((s * 0.3, -0.32, 1.38), (0.2, 0.18, 0.2)); ell(m, PEARL, eb.c, eb.r, part="Belly", seg=10, rings=7)
        eyes(m, eb, s * 0.0 + 0, 4, rx=0.12, rz=0.14, single=True, gap=0.01)
        arm = [(s * 0.65, -0.2, 0.62), (s * 0.95, -0.38, 0.75), (s * 0.95, -0.6, 1.0)]
        vtube(m, B, arm, [0.1, 0.09, 0.09], seg=8, smooth=2)
        c = Vector((s * 0.95, -0.68, 1.1))
        ell(m, B, c, (0.2, 0.17, 0.24), seg=10, rings=7)
        ell(m, B, c + Vector((s * -0.02, -0.12, 0.2)), (0.1, 0.08, 0.2), rot=(-25, s * 15, 0), seg=8, rings=6)
        ell(m, B, c + Vector((s * 0.08, -0.13, 0.13)), (0.08, 0.07, 0.17), rot=(-30, -s * 25, 0), seg=8, rings=6)
        for k, y in enumerate((-0.05, 0.2, 0.45)):
            vtube(m, B, [(s * 0.62, y, 0.45), (s * 0.95, y + 0.05, 0.45), (s * 1.08, y + 0.08, 0.06)], [0.06, 0.055, 0.03], seg=6, smooth=2)
    ell(m, PEARL, (-0.95, -0.82, 1.12), 0.08, part="Belly", seg=8)
    face = Head((0, 0.05, 0.6), (0.78, 0.56, 0.4))
    mouth(m, face, -2, w=10, kind="smile", sag=5)
    blush(m, face, 30, 6, 0.09)
    return {"L": 3.0}

@pet("Seahorse")
def seahorse(m):
    B, BE, FIN = P("FFC24A"), P("FFEFC2"), TEAL
    path = [(0, -0.02, 0.18), (0, 0.18, 0.1), (0, 0.3, 0.28), (0, 0.18, 0.5), (0, 0.04, 0.72), (0, -0.08, 1.0), (0, -0.04, 1.32), (0, 0.04, 1.6)]
    vtube(m, B, path[::-1], [0.26, 0.34, 0.36, 0.3, 0.2, 0.14, 0.1, 0.06], seg=10)
    for z, r in ((0.82, 0.27), (0.98, 0.3), (1.14, 0.3), (1.3, 0.25)):
        ell(m, BE, (0, -0.14 - (0.04 if 0.9 < z < 1.2 else 0), z), (r * 0.85, 0.2, 0.07), part="Belly", seg=8, rings=4)
    h = Head((0, -0.04, 1.86), (0.4, 0.4, 0.38)); ell(m, B, h.c, h.r, seg=12, rings=8)
    p, n = h.pt(0, -12)
    vtube(m, B, [p - n * 0.1, p + n * 0.25 + Vector((0, 0, -0.02)), p + n * 0.42 + Vector((0, 0, -0.03))], [0.13, 0.09, 0.11], seg=8, smooth=1)
    ell(m, MOUTH, p + n * 0.44 + Vector((0, 0, -0.03)), (0.07, 0.03, 0.06), part="Mouth", seg=8, rings=4, q=n.to_track_quat('Y', 'Z'))
    for k, (a, ln) in enumerate(((0, 0.24), (-24, 0.18), (24, 0.18), (0, 0.16))):
        b, nn = h.pt(a, 70 - (40 if k == 3 else 0), -0.04) if k < 3 else h.pt(180, 50, -0.04)
        cone(m, CORAL, b, b + nn * ln, 0.07, seg=6, part="Accent")
    M = Matrix.Translation(Vector((0, 0.22, 1.1))) @ Euler((0, 0, math.radians(90)), 'XYZ').to_matrix().to_4x4()
    slab(m, FIN, [(0, -0.25), (0.2, -0.3), (0.3, -0.1), (0.32, 0.15), (0.2, 0.3), (0, 0.25)], 0.05, M, part="AccentFin")
    for s in (-1, 1):
        p, n = h.pt(s * 80, 0)
        ell(m, FIN, p + n * 0.06, (0.05, 0.12, 0.1), rot=(0, 0, s * 20), part="AccentFin", seg=6)
    ell(m, PEARL, (0, -0.28, 1.04), 0.07, part="AccentPearl", seg=8)
    eyes(m, h, 36, 10, rx=0.12, rz=0.15)
    blush(m, h, 54, -10, 0.08, pc=P("FF8A80"))
    return {"H": 2.6}

@pet("Turtle")
def turtle(m):
    SH, SK, MK = P("2FB59E"), P("A8EBC5"), P("1C7F70")
    sh = Head((0, 0.15, 0.6), (0.68, 0.78, 0.48)); ell(m, SH, sh.c, sh.r, seg=14, rings=8)
    ell(m, P("FFE7C2"), (0, 0.12, 0.42), (0.66, 0.74, 0.18), part="Belly")
    tube(m, GOLD, [(math.cos(a) * 0.68, 0.15 + math.sin(a) * 0.78, 0.47) for a in [2 * math.pi * i / 20 for i in range(20)]], r=0.04, seg=5, part="AccentGold", closed=True, smooth=1)
    hexp = [(math.cos(a) * 0.17, math.sin(a) * 0.17) for a in [math.pi / 3 * i for i in range(6)]]
    for (a, pp) in [(180, 88), (180, 45), (130, 40), (230, 40), (90, 35), (270, 35), (40, 45), (-40, 45)]:
        p, n = sh.pt(a, pp); disc(m, MK, hexp, 0.03, p, normal=n, part="Mark")
    h = Head((0, -0.72, 0.82), (0.42, 0.4, 0.38)); ell(m, SK, h.c, h.r, part="Belly", seg=12, rings=8)
    vtube(m, SK, [(0, -0.42, 0.6), (0, -0.62, 0.74)], [0.2, 0.2], seg=8, part="Belly", smooth=1)
    for s in (-1, 1):
        ell(m, SK, (s * 0.7, -0.35, 0.3), (0.36, 0.16, 0.08), rot=(0, -s * 15, s * 30), part="Belly", seg=8, rings=5)
        ell(m, SK, (s * 0.55, 0.65, 0.22), (0.22, 0.12, 0.07), rot=(0, 0, -s * 30), part="Belly", seg=8, rings=5)
        h.put(m, MK, s * 60, 40, (0.05, 0.02, 0.05), "Mark", off=0.0, seg=6, rings=4)
    cone(m, SK, (0, 0.85, 0.4), (0, 1.05, 0.32), 0.08, seg=6, part="Belly")
    p, n = sh.pt(160, 60); ell(m, CORAL, p + n * 0.05, 0.06, part="Accent", seg=6)
    cone(m, CORAL, p, p + n * 0.22 + Vector((0.05, 0, 0.0)), 0.04, seg=5, part="Accent")
    cone(m, CORAL, p, p + n * 0.18 + Vector((-0.1, 0.05, 0.05)), 0.035, seg=5, part="Accent")
    eyes(m, h, 30, 10, rx=0.12, rz=0.145)
    mouth(m, h, -18, w=16, kind="smile", sag=6)
    blush(m, h, 50, -6, 0.08)
    return {"L": 3.0}

@pet("Manta Ray")
def manta(m):
    B, BE, MK = P("17607A"), P("F4FBFA"), P("BDEBE5")
    body = Head((0, 0.0, 0.62), (0.48, 0.58, 0.26)); ell(m, B, body.c, body.r, seg=12, rings=7)
    ell(m, BE, (0, -0.02, 0.5), (0.44, 0.52, 0.17), part="Belly")
    wing = [(0.0, 0.4), (0.45, 0.25), (0.9, 0.02), (1.1, -0.12), (0.7, -0.24), (0.3, -0.42), (0.0, -0.45)]
    for s in (-1, 1):
        M = Matrix.Translation(Vector((0.25, 0.05, 0.62))) @ Euler((math.radians(90), math.radians(-22), 0), 'XYZ').to_matrix().to_4x4()
        slab(m, B, wing, 0.09, M, part="Body", mirror=s)
        Mb = Matrix.Translation(Vector((0.25, 0.05, 0.565))) @ Euler((math.radians(90), math.radians(-22), 0), 'XYZ').to_matrix().to_4x4()
        slab(m, BE, [(x * 0.92, z * 0.92) for x, z in wing], 0.05, Mb, part="Belly", mirror=s)
        vtube(m, B, [(s * 0.3, -0.48, 0.62), (s * 0.34, -0.72, 0.6), (s * 0.24, -0.8, 0.72)], [0.08, 0.06, 0.0], seg=6, smooth=2)
        p, n = body.pt(180 + s * 30, 60); ell(m, MK, p, (0.1, 0.13, 0.03), part="Mark", seg=8, rings=4, q=n.to_track_quat('Z', 'Y'))
    vtube(m, B, [(0, 0.55, 0.6), (0, 0.95, 0.55), (0.05, 1.35, 0.45)], [0.06, 0.035, 0.0], seg=6)
    eyes(m, body, 30, 22, rx=0.11, rz=0.12)
    mouth(m, body, -12, w=18, kind="smile", sag=8)
    blush(m, body, 48, 2, 0.07)
    return {"H": 2.0}

@pet("Ancient Sea Serpent")
def serpent(m):
    B, BE, FIN, GL = TEAL, P("FFF0C8"), CORAL, P("E9FFFF", "NE")
    path = []
    for i in range(14):
        t = i / 13
        a = math.radians(200 - 470 * t)
        r = 0.75 - 0.3 * t
        path.append((math.cos(a) * r, 0.25 + math.sin(a) * r, 0.22 + 0.55 * t))
    path += [(0.0, -0.05, 1.1), (0.0, -0.25, 1.55), (0.0, -0.3, 1.95)]
    rad = [0.06 + 0.2 * min(1, i / 4) for i in range(14)] + [0.24, 0.22, 0.2]
    vtube(m, B, path, rad, seg=10, smooth=2)
    for z in (1.2, 1.42, 1.64, 1.84):
        tt = (z - 1.1) / 0.85
        y = -0.05 - 0.25 * min(1, tt * 1.4)
        ell(m, BE, (0, y - 0.15, z), (0.17, 0.08, 0.1), part="Belly", seg=8, rings=4)
    for k, (y, z) in enumerate(((0.12, 1.2), (0.04, 1.5), (-0.02, 1.8))):
        M = Matrix.Translation(Vector((0, y + 0.1, z))) @ Euler((0, 0, math.radians(90)), 'XYZ').to_matrix().to_4x4()
        slab(m, FIN, [(0, -0.12), (0.22, 0.0), (0.28, 0.22), (0.0, 0.12)], 0.04, M, part="Accent")
    h = Head((0, -0.42, 2.22), (0.5, 0.48, 0.42)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.82, 2.1), (0.3, 0.26, 0.2)); ell(m, B, sn.c, sn.r, seg=10, rings=7)
    for s in (-1, 1):
        p, n = h.pt(s * 80, 10)
        M = Matrix.Translation(p) @ Euler((0, math.radians(-s * 20), math.radians(s * 20)), 'XYZ').to_matrix().to_4x4()
        slab(m, FIN, [(0, -0.12), (0.35, 0.05), (0.4, 0.28), (0.18, 0.2), (0.0, 0.12)], 0.04, M, part="Accent", mirror=1 if s > 0 else -1) if False else None
        vtube(m, FIN, [p - n * 0.02, p + n * 0.22 + Vector((0, 0.1, 0.18)), p + n * 0.34 + Vector((0, 0.2, 0.32))], [0.1, 0.07, 0.0], seg=6, part="Accent", sq=0.35)
        sn.put(m, P("1E7C70"), s * 25, 30, (0.035, 0.02, 0.025), "Nose", off=0.01)
    for k, a in enumerate((-36, -18, 0, 18, 36)):
        b, n = h.pt(a, 58, -0.03)
        cone(m, GOLD, b, b + n * (0.3 if a == 0 else 0.22) + Vector((0, 0, 0.08)), 0.07, seg=5, part="AccentGold")
    tube(m, GOLD, [h.c + Vector((math.cos(a) * 0.4, math.sin(a) * 0.36, 0.3 - 0.06 * math.sin(a))) for a in [2 * math.pi * i / 16 for i in range(16)]], r=0.045, seg=5, part="AccentGold", closed=True, smooth=1)
    p, n = h.pt(0, 52, 0.0); ell(m, GL, p + n * 0.1, 0.1, part="Glow", seg=10)
    eyes(m, h, 30, 12, rx=0.12, rz=0.15)
    mouth(m, sn, -22, w=24, kind="smile", sag=8)
    blush(m, h, 54, -6, 0.08, pc=P("FF9C8A"))
    return {"H": 3.1}

