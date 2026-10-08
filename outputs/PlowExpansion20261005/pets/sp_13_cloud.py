# Cloud Egg: white, sky blue, gold, rainbow touches.
import math, random
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import tube

def pair(f):
    for s in (-1, 1): f(s)

SKY = P("8FCBFF")
GOLD = P("FFC94A", "ME")
RAIN = [P("FF7A9C"), P("FFD84A"), P("7BE3A0"), P("6FB8FF")]

def puffs(m, pc, centre, radii, n, spread, seed, part="Body", rmin=0.55, seg=7):
    rnd = random.Random(seed); c = Vector(centre)
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi); b = rnd.uniform(-0.6, 1.0)
        d = Vector((math.cos(a) * math.cos(b) * spread[0], math.sin(a) * math.cos(b) * spread[1], math.sin(b) * spread[2]))
        r = radii * rnd.uniform(rmin, 1.0)
        ell(m, pc, c + d, r, part=part, seg=seg, rings=5)

@pet("Cloud Lamb")
def cloud_lamb(m):
    B, FACE = P("F7F9FF"), P("BACAE8")
    ell(m, B, (0, 0.12, 0.72), (0.58, 0.6, 0.48), seg=12, rings=8)
    puffs(m, B, (0, 0.12, 0.75), 0.32, 10, (0.55, 0.58, 0.42), 4)
    h = Head((0, -0.45, 1.12), (0.4, 0.34, 0.38)); ell(m, FACE, h.c, h.r, part="Belly", seg=12, rings=8)
    puffs(m, B, (0, -0.38, 1.46), 0.17, 6, (0.26, 0.18, 0.08), 9, rmin=0.75)
    for s in (-1, 1):
        p, n = h.pt(s * 78, 18)
        ell(m, FACE, p + Vector((s * 0.12, 0.02, -0.04)), (0.18, 0.07, 0.09), rot=(0, s * 30, s * -25), part="Belly", seg=8)
        for y in (-0.25, 0.45):
            vtube(m, FACE, [(s * 0.28, y, 0.4), (s * 0.28, y, 0.08)], [0.08, 0.08], seg=6, part="Belly", smooth=1)
            ell(m, P("7D8FB8"), (s * 0.28, y - 0.02, 0.05), (0.1, 0.11, 0.06), part="Mark", seg=8)
    tube(m, SKY, [(math.cos(a) * 0.3, -0.36 + math.sin(a) * 0.24, 0.88) for a in [2 * math.pi * i / 12 for i in range(12)]], r=0.035, seg=5, part="Accent", closed=True, smooth=1)
    ell(m, GOLD, (0, -0.62, 0.82), 0.08, part="AccentGold", seg=8)
    eyes(m, h, 28, 6, rx=0.11, rz=0.135)
    nose(m, h, -14, (0.05, 0.03, 0.035), pc=P("7D6A8E"))
    mouth(m, h, -24, w=10, kind="w", sag=6)
    blush(m, h, 50, -12, 0.08)
    return {"H": 2.3}

@pet("Cloud Kitten")
def cloud_kitten(m):
    B, PUFF = P("CFE4FF"), P("FFFFFF")
    ell(m, B, (0, 0.12, 0.55), (0.45, 0.48, 0.55))
    h = Head((0, -0.05, 1.33), (0.62, 0.54, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.48, 1.2), (0.24, 0.14, 0.13)); ell(m, PUFF, mz.c, mz.r, part="Belly", seg=10, rings=6)
    pointy_ear(m, B, P("FFC2D4"), h, 38, 48, height=0.5, width=0.26, out=20, back=-6, ipart="Blush")
    pair(lambda s: leg(m, B, (s * 0.2, -0.22, 0.55), (s * 0.21, -0.34, 0.1), r=0.1))
    pair(lambda s: ell(m, B, (s * 0.34, 0.16, 0.26), (0.2, 0.32, 0.26)))
    for a in range(0, 360, 40):
        r = math.radians(a)
        ell(m, PUFF, (math.cos(r) * 0.4, -0.02 + math.sin(r) * 0.36, 0.86 + 0.03 * math.sin(3 * r)), 0.13, part="Belly", seg=7, rings=4)
    vtube(m, B, [(0.1, 0.55, 0.3), (0.45, 0.75, 0.45), (0.5, 0.6, 0.85)], [0.08, 0.08, 0.07], seg=7)
    puffs(m, PUFF, (0.5, 0.58, 0.98), 0.17, 5, (0.14, 0.12, 0.12), 2, part="Belly", rmin=0.7)
    ell(m, GOLD, (0, -0.42, 0.78), 0.08, part="AccentGold", seg=8)
    eyes(m, h, 26, 6, rx=0.13, rz=0.155)
    nose(m, h, -8, (0.05, 0.035, 0.04), pc=P("FF8FB0"))
    mouth(m, mz, -10, w=14, kind="w", sag=8)
    blush(m, h, 46, -10, 0.09)

@pet("Thunder Owl")
def thunder_owl(m):
    B, BE, BOLT, IR = P("6F7FD0"), P("DCE1FF"), P("FFD84A"), P("6FE8FF")
    body = Head((0, 0.05, 0.98), (0.62, 0.58, 0.84)); ell(m, B, body.c, body.r, seg=12, rings=9)
    dc = Head((0, -0.14, 1.3), (0.5, 0.42, 0.4)); ell(m, BE, dc.c, dc.r, part="Belly", seg=12, rings=8)
    ell(m, BE, (0, -0.22, 0.72), (0.38, 0.3, 0.4), part="Belly")
    for s in (-1, 1):
        b = body.pt(s * 40, 64, -0.08)[0]
        M = Matrix.Translation(b) @ Euler((0, math.radians(-s * 15), 0), 'XYZ').to_matrix().to_4x4()
        slab(m, BOLT, [(0.0, 0.0), (0.16, 0.0), (0.1, 0.18), (0.22, 0.18), (0.02, 0.5), (0.06, 0.26), (-0.06, 0.26)], 0.07, M, part="Accent", mirror=s)
        wings(m, B, "feather", (0.5, 0.15, 1.1), span=0.65, hgt=0.6, thick=0.08, spread=(-35, 25, 0), part="Body", lobes=3, sides=(s,))
        p, n = dc.pt(s * 30, 12)
        ell(m, IR, p + n * 0.01, (0.16, 0.035, 0.16), part="AccentIris", seg=10, rings=6, q=n.to_track_quat('Y', 'Z'))
        for k in range(3):
            ell(m, BOLT, (s * 0.2 + (k - 1) * 0.06, -0.46, 0.05), (0.03, 0.09, 0.03), part="Accent", seg=5, rings=3)
        ell(m, B, (s * 0.2, -0.34, 0.12), (0.15, 0.15, 0.12), seg=8)
    disc(m, BOLT, [(0.0, 0.25), (0.12, 0.25), (0.04, 0.05), (0.14, 0.05), (-0.06, -0.28), (-0.01, -0.04), (-0.12, -0.04)], 0.04, (0, -0.52, 0.72), normal=(0, -1, -0.1), part="Mark")
    p, n = dc.pt(0, -8)
    cone(m, BOLT, p - n * 0.03, p + n * 0.12 + Vector((0, 0, -0.08)), 0.07, seg=6, part="Accent")
    eyes(m, dc, 30, 12, rx=0.12, rz=0.14, gap=0.04)
    blush(m, dc, 52, -12, 0.07)

@pet("Rainbow Pegasus")
def pegasus(m):
    B, BE, WG = P("FAFBFF"), P("FFE3EE"), P("FFE08A")
    bh = Head((0, 0.3, 0.8), (0.45, 0.66, 0.42)); ell(m, B, bh.c, bh.r)
    vtube(m, B, [(0, -0.2, 1.05), (0, -0.4, 1.4), (0, -0.42, 1.6)], [0.22, 0.18, 0.18], seg=10, smooth=1)
    h = Head((0, -0.5, 1.82), (0.46, 0.44, 0.42)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.86, 1.66), (0.27, 0.22, 0.2)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    pointy_ear(m, B, BE, h, 30, 56, height=0.34, width=0.14, out=14, back=-10, ipart="Belly")
    for sx in (-1, 1):
        for y in (-0.05, 0.68):
            vtube(m, B, [(sx * 0.23, y, 0.6), (sx * 0.24, y, 0.15)], [0.13, 0.12], seg=8, smooth=1)
            cyl(m, WG, (sx * 0.24, y, 0.0), r=0.14, h=0.15, seg=8, part="AccentWing")
        wings(m, WG, "feather", (0.34, 0.25, 1.1), span=1.15, hgt=0.75, thick=0.07, spread=(30, 30, 0), part="AccentWing", lobes=3, sides=(sx,))
        mz.put(m, MOUTH, sx * 28, 26, (0.03, 0.015, 0.02), "Mouth", off=0.01)
    for k in range(4):
        b = h.pt(0, 70 - k * 25, -0.05)[0] if k < 2 else Vector((0, -0.22 + (k - 2) * 0.14, 1.6 - (k - 2) * 0.24))
        ell(m, RAIN[k], b + Vector((0, 0.1, 0.08)), (0.17, 0.22, 0.2), part="Accent" + "RYGB"[k], seg=7, rings=5)
        ell(m, RAIN[(k + 2) % 4], b + Vector((0.1, 0.2, 0.0)), (0.13, 0.18, 0.16), part="Accent" + "RYGB"[(k + 2) % 4], seg=7, rings=5)
        ell(m, RAIN[(k + 1) % 4], b + Vector((-0.1, 0.2, 0.0)), (0.12, 0.16, 0.15), part="Accent" + "RYGB"[(k + 1) % 4], seg=7, rings=5)
    for k in range(4):
        dx = (k - 1.5) * 0.06
        pts = [(dx, 0.95, 1.05), (dx * 2, 1.2, 1.0 - k * 0.04), (dx * 3, 1.32, 0.7 - k * 0.06), (dx * 3, 1.25, 0.42 - k * 0.04)]
        vtube(m, RAIN[k], pts, [0.07, 0.08, 0.07, 0.0], seg=6, part="Accent" + "RYGB"[k], sq=0.6)
    eyes(m, h, 30, 6, rx=0.12, rz=0.15)
    lashes(m, h, 30, 6, 0.12, 0.15)
    mouth(m, mz, -20, w=18, kind="smile", sag=6)
    blush(m, h, 52, -10, 0.08)

@pet("Sky Whale")
def sky_whale(m):
    B, BE, MK, CLD, GL = SKY, P("F7F9FF"), P("B8DEF7"), P("FFFFFF"), P("FFF2A8", "NE")
    vtube(m, B, [(0, -1.2, 0.95), (0, -0.95, 1.0), (0, -0.35, 1.06), (0, 0.35, 1.08), (0, 0.9, 1.22), (0, 1.25, 1.42)], [0.0, 0.52, 0.7, 0.58, 0.28, 0.1], seg=14)
    bel = Head((0, -0.5, 0.82), (0.56, 0.72, 0.42)); ell(m, BE, bel.c, bel.r, part="Belly", seg=12, rings=7)
    for k in range(4):
        x = (k - 1.5) * 0.15
        vtube(m, MK, [bel.pt(math.degrees(math.atan2(x, 0.7)) * 1.4, -20, 0.005)[0], bel.pt(math.degrees(math.atan2(x, 0.7)) * 1.4, -55, 0.005)[0]], [0.025, 0.025], seg=4, part="Mark", smooth=1)
    for s in (-1, 1):
        M = Matrix.Translation(Vector((0.05, 1.28, 1.44))) @ Euler((math.radians(90), math.radians(-12), math.radians(-12)), 'XYZ').to_matrix().to_4x4()
        slab(m, B, [(0, 0.12), (0.4, 0.18), (0.62, 0.0), (0.45, -0.2), (0.1, -0.12)], 0.08, M, part="Body", mirror=s)
        ell(m, B, (s * 0.66, -0.35, 0.72), (0.3, 0.14, 0.07), rot=(0, s * 25, s * 30), seg=8, rings=5)
    puffs(m, CLD, (0.0, 0.25, 1.75), 0.2, 6, (0.35, 0.22, 0.06), 5, part="AccentCloud", rmin=0.7)
    p = Vector((0, -0.4, 1.74))
    from w2lib import lathe
    lathe(m, GOLD, [(0.2, 0.0), (0.2, 0.1)], loc=p, seg=10, part="AccentGold")
    for k in range(5):
        a = 2 * math.pi * k / 5
        cone(m, GOLD, p + Vector((math.cos(a) * 0.2, math.sin(a) * 0.2, 0.08)), p + Vector((math.cos(a) * 0.21, math.sin(a) * 0.21, 0.24)), 0.05, seg=4, part="AccentGold")
    gem(m, GL, p + Vector((0, -0.2, 0.08)), 0.06, h=0.1, part="Glow", rot=(90, 0, 0))
    f = Head((0, -0.55, 1.03), (0.66, 0.68, 0.64)); ell(m, B, f.c, f.r, seg=12, rings=8)
    eyes(m, f, 40, 6, rx=0.12, rz=0.15)
    mouth(m, f, -14, w=24, kind="smile", sag=6)
    blush(m, f, 56, -8, 0.09)
    return {"L": 3.6}



