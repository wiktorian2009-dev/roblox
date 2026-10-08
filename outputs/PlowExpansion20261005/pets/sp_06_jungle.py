# Jungle Egg: lively animal shapes, natural saturated colours.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet

def pair(f):
    for s in (-1, 1): f(s)

LEAF = P("3FBF5A")

def leaf_poly(L=1.0, W=0.35, n=7):
    up = [(L * i / n, W * math.sin(math.pi * i / n) ** 0.8) for i in range(n + 1)]
    dn = [(L * i / n, -W * math.sin(math.pi * i / n) ** 0.8) for i in range(n - 1, 0, -1)]
    return up + dn

@pet("Tree Frog")
def tree_frog(m):
    B, BE, MK, TOE, IRIS = P("5FD45A"), P("FFD75A"), P("3F7BE0"), P("FF8A3D"), P("F0473F")
    ell(m, B, (0, 0.12, 0.48), (0.56, 0.56, 0.44))
    ell(m, BE, (0, -0.2, 0.42), (0.42, 0.34, 0.34), part="Belly")
    h = Head((0, -0.22, 0.88), (0.64, 0.5, 0.4)); ell(m, B, h.c, h.r, seg=12, rings=8)
    for s in (-1, 1):
        bump = Head((s * 0.34, -0.3, 1.2), (0.27, 0.25, 0.25)); ell(m, B, bump.c, bump.r, seg=10, rings=7)
        p, n = bump.pt(s * 14, 8)
        ell(m, IRIS, p + n * 0.005, (0.2, 0.05, 0.2), part="AccentIris", seg=10, rings=6, q=n.to_track_quat('Y', 'Z'))
        eyes(m, bump, 14, 8, rx=0.13, rz=0.15, gap=0.04, single=False) if False else None
        sub = Head(p + n * 0.04, (0.01, 0.01, 0.01))
        e = Head(bump.c, bump.r * 1.0)
        eyes_one(m, bump, s * 14, 8)
        ell(m, B, (s * 0.58, 0.25, 0.25), (0.24, 0.36, 0.22))
        vtube(m, B, [(s * 0.6, 0.0, 0.18), (s * 0.68, -0.3, 0.06)], [0.08, 0.07], seg=6, smooth=1)
        for d in (-25, 0, 25):
            a = math.radians(d)
            ell(m, TOE, (s * 0.68 + math.sin(a) * 0.12, -0.32 - math.cos(a) * 0.1, 0.05), 0.06, part="Accent", seg=6, rings=4)
        vtube(m, B, [(s * 0.3, -0.35, 0.5), (s * 0.36, -0.5, 0.12)], [0.08, 0.07], seg=6, smooth=1)
        for d in (-25, 0, 25):
            a = math.radians(d)
            ell(m, TOE, (s * 0.36 + math.sin(a) * 0.1, -0.56 - math.cos(a) * 0.08, 0.05), 0.055, part="Accent", seg=6, rings=4)
        bh = Head((0, 0.12, 0.48), (0.56, 0.56, 0.44))
        p, n = bh.pt(s * 95, 15)
        vtube(m, MK, [bh.pt(s * 70, 30, 0.01)[0], bh.pt(s * 100, 20, 0.01)[0], bh.pt(s * 130, 8, 0.01)[0]], [0.05, 0.06, 0.04], seg=6, part="Mark", smooth=2)
    mouth(m, h, -14, w=34, kind="smile", sag=10, r=0.026)
    blush(m, h, 46, 4, 0.09)
    return {"H": 2.0}

def eyes_one(m, bump, yaw, pitch):
    p, n = bump.pt(yaw, pitch)
    q = n.to_track_quat('Y', 'Z')
    c = p + n * 0.05
    ell(m, INK, c, (0.12, 0.05, 0.14), part="Eye", seg=10, rings=6, q=q)
    tx = q @ Vector((1, 0, 0)); tz = q @ Vector((0, 0, 1))
    if tx.x < 0: tx = -tx
    for (u, v, k) in [(-0.34, 0.36, 0.34), (0.3, -0.32, 0.15)]:
        w = math.sqrt(1 - u * u - v * v)
        sp = c + tx * (u * 0.12) + tz * (v * 0.14) + n * (0.05 * w + 0.008)
        ell(m, WHITE, sp, (0.12 * k, 0.018, 0.12 * k), part="Shine", seg=6, rings=4, q=n.to_track_quat('Y', 'Z'))

@pet("Monkey")
def monkey(m):
    B, BE, BAN, BTIP = P("8B5734"), P("EBC69C"), P("FFD93D"), P("6B4426")
    ell(m, B, (0, 0.1, 0.55), (0.42, 0.38, 0.48))
    ell(m, BE, (0, -0.16, 0.5), (0.28, 0.2, 0.32), part="Belly")
    h = Head((0, -0.05, 1.36), (0.6, 0.52, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    for s in (-1, 1):
        ell(m, BE, (s * 0.17, -0.3, 1.46), (0.24, 0.27, 0.24), part="Belly", seg=10, rings=7)
    mz = Head((0, -0.38, 1.22), (0.34, 0.24, 0.2)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    fh = Head((0, -0.05, 1.42), (0.52, 0.54, 0.45))
    round_ear(m, B, BE, h, 86, 4, r=0.22, thick=0.4, out=80, ipart="Belly")
    for k, (dx, dz) in enumerate(((-0.08, 0.0), (0.06, 0.04))):
        cone(m, B, (dx, -0.05, 1.82), (dx * 2.5, -0.12, 2.02 + dz), 0.08, seg=6, part="Body")
    vtube(m, B, [(0, 0.45, 0.32), (0.25, 0.85, 0.5), (0.3, 0.82, 1.0), (0.1, 0.7, 1.25), (-0.05, 0.75, 1.1), (0.02, 0.85, 0.98)], [0.07, 0.065, 0.06, 0.055, 0.05, 0.04], seg=7)
    vtube(m, B, [(-0.36, -0.02, 0.8), (-0.55, -0.2, 0.6), (-0.42, -0.4, 0.5)], [0.08, 0.075, 0.07], seg=7)
    vtube(m, B, [(0.36, -0.02, 0.8), (0.58, -0.22, 0.85), (0.54, -0.42, 1.0)], [0.08, 0.075, 0.07], seg=7)
    ell(m, BE, (-0.42, -0.42, 0.5), 0.09, part="Belly", seg=8); ell(m, BE, (0.54, -0.44, 1.02), 0.09, part="Belly", seg=8)
    ban = [(0.62, -0.4, 0.8), (0.64, -0.5, 1.02), (0.58, -0.48, 1.28)]
    vtube(m, BAN, ban, [0.04, 0.08, 0.035], seg=6, part="Accent", smooth=3, sq=1.0)
    ell(m, BTIP, (0.58, -0.48, 1.3), 0.035, part="AccentTip", seg=6, rings=4)
    pair(lambda s: ell(m, BE, (s * 0.22, -0.3, 0.1), (0.15, 0.2, 0.1), part="Belly", seg=8))
    eyes(m, fh, 18, 4, rx=0.12, rz=0.15)
    nose(m, mz, 30, (0.05, 0.03, 0.03), pc=P("4A2E1E"))
    mouth(m, mz, -12, w=26, kind="smile", sag=12, r=0.024)
    blush(m, fh, 40, -16, 0.08)

@pet("Toucan")
def toucan(m):
    B, BE, BK, TIP, MK = P("26262E"), P("FFF1C2"), P("FF8A1E"), P("E8343A"), P("4FB8F0")
    ell(m, B, (0, 0.12, 0.78), (0.5, 0.46, 0.62))
    h = Head((0, -0.04, 1.52), (0.5, 0.46, 0.46)); ell(m, B, h.c, h.r, seg=12, rings=8)
    bib = Head((0, -0.17, 1.38), (0.44, 0.4, 0.4)); ell(m, BE, bib.c, bib.r, part="Belly", seg=12, rings=8)
    ell(m, BE, (0, -0.16, 0.95), (0.36, 0.34, 0.32), part="Belly")
    p, n = bib.pt(0, 0)
    vtube(m, BK, [p + Vector((0, 0.1, 0.02)), p + Vector((0, -0.25, -0.02)), p + Vector((0, -0.55, -0.12)), p + Vector((0, -0.72, -0.28))], [0.17, 0.15, 0.1, 0.0], seg=10, part="Accent", sq=1.35)
    vtube(m, TIP, [p + Vector((0, -0.52, -0.1)), p + Vector((0, -0.64, -0.2)), p + Vector((0, -0.73, -0.29))], [0.112, 0.07, 0.0], seg=10, part="AccentTip", sq=1.35, smooth=2)
    for s in (-1, 1):
        q, nn = bib.pt(s * 36, 16)
        ell(m, MK, q + nn * 0.005, (0.15, 0.03, 0.15), part="Mark", seg=10, rings=6, q=nn.to_track_quat('Y', 'Z'))
        ell(m, B, (s * 0.46, 0.18, 0.86), (0.13, 0.36, 0.42), rot=(18, 0, 0), seg=10)
        vtube(m, MK, [(s * 0.18, 0.0, 0.25), (s * 0.2, -0.05, 0.06)], [0.05, 0.05], seg=5, part="Mark", smooth=1)
        ell(m, MK, (s * 0.2, -0.12, 0.04), (0.1, 0.14, 0.05), part="Mark", seg=6)
    vtube(m, B, [(0, 0.5, 0.55), (0, 0.78, 0.3), (0, 0.85, 0.08)], [0.16, 0.14, 0.1], seg=8, sq=0.45)
    eyes(m, bib, 36, 16, rx=0.1, rz=0.12, gap=0.05)
    blush(m, bib, 52, -6, 0.07)

def rosette(m, pc, surf, yaw, pitch, r=0.075, part="Mark"):
    p, n = surf.pt(yaw, pitch)
    poly = [(math.cos(a) * r, math.sin(a) * r) for a in [math.radians(30 + 300 * i / 5) for i in range(6)]]
    poly += [(math.cos(a) * r * 0.5, math.sin(a) * r * 0.5) for a in [math.radians(330 - 300 * i / 3) for i in range(4)]]
    disc(m, pc, poly, 0.03, p + n * 0.004, normal=n, part=part, spin=yaw * 3)

@pet("Jaguar")
def jaguar(m):
    B, BE, MK, VINE = P("F2AE38"), P("FFF0CF"), P("4A2E1C"), P("3FBF5A")
    bh = Head((0, 0.3, 0.8), (0.46, 0.74, 0.42)); ell(m, B, bh.c, bh.r)
    ell(m, BE, (0, 0.3, 0.6), (0.36, 0.6, 0.24), part="Belly")
    h = Head((0, -0.55, 1.38), (0.6, 0.52, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.98, 1.22), (0.26, 0.16, 0.16)); ell(m, BE, sn.c, sn.r, part="Belly", seg=10, rings=7)
    round_ear(m, B, MK, h, 40, 50, r=0.17, ipart="Mark")
    for sx in (-1, 1):
        for y in (-0.2, 0.76):
            leg(m, B, (sx * 0.27, y, 0.7), (sx * 0.28, y, 0.1), r=0.13, paw=1.15)
    vtube(m, B, [(0, 0.95, 0.95), (0.05, 1.3, 1.1), (0.12, 1.36, 1.5), (0.0, 1.18, 1.72)], [0.09, 0.08, 0.08, 0.07], seg=8)
    for t in (0.25, 0.55, 0.8):
        pass
    ell(m, MK, (0.0, 1.17, 1.73), (0.09, 0.09, 0.09), part="Mark", seg=8)
    ell(m, MK, (0.12, 1.36, 1.5), (0.095, 0.095, 0.06), part="Mark", seg=8)
    for (a, pp) in [(150, 40), (180, 58), (210, 40), (120, 18), (240, 18), (180, 18), (95, 40), (265, 40)]:
        rosette(m, MK, bh, a, pp, r=0.085)
    for (a, pp) in [(-28, 60), (28, 60), (0, 74)]:
        h.put(m, MK, a, pp, (0.05, 0.02, 0.05), "Mark", off=0.003, seg=6, rings=4)
    from w2lib import tube
    pts = [(math.cos(a) * 0.36, -0.42 + math.sin(a) * 0.3, 0.98 + 0.06 * math.sin(a)) for a in [2 * math.pi * i / 14 for i in range(14)]]
    tube(m, VINE, pts, r=0.035, seg=5, part="Accent", closed=True, smooth=1)
    disc(m, VINE, leaf_poly(0.3, 0.12), 0.03, (0.06, -0.74, 0.86), normal=(0.3, -1, 0.2), part="Accent", spin=-60)
    eyes(m, h, 28, 8, rx=0.125, rz=0.15, tilt=8)
    p, n = sn.pt(0, 40); ell(m, P("C2575A"), p + n * 0.006, (0.07, 0.04, 0.045), part="Nose", seg=8)
    mouth(m, sn, -16, w=22, kind="w", sag=10)
    blush(m, h, 50, -8, 0.08)

@pet("Tiki Guardian")
def tiki(m):
    B, FACE, MK, GD, GL = P("9A6235", "WO"), P("D49A5E", "WO"), P("5E3519", "WO"), P("F5C443", "ME"), P("6CFF9E", "NE")
    prof = [(0.5, 0.0), (0.56, 0.12), (0.58, 0.6), (0.62, 1.0), (0.66, 1.5), (0.66, 2.05), (0.6, 2.3), (0.4, 2.45), (0.0, 2.5)]
    lathe(m, B, prof, seg=14, part="Body", sy=0.9)
    for z in (0.62, 0.92):
        from w2lib import tube
        rr = 0.6 if z < 0.8 else 0.63
        tube(m, MK, [(math.cos(a) * rr, math.sin(a) * rr * 0.9, z) for a in [2 * math.pi * i / 14 for i in range(14)]], r=0.04, seg=5, part="Mark", closed=True, smooth=1)
    face = Head((0, -0.28, 1.68), (0.56, 0.42, 0.5)); ell(m, FACE, face.c, face.r, part="Belly", seg=12, rings=8)
    pair(lambda s: vtube(m, MK, [face.pt(s * 12, 42, 0.02)[0], face.pt(s * 27, 47, 0.02)[0], face.pt(s * 42, 42, 0.02)[0]], [0.03, 0.04, 0.03], seg=6, part="Mark", smooth=2))
    eyes(m, face, 26, 12, rx=0.14, rz=0.16)
    mouth(m, face, -24, w=28, kind="smile", sag=12, r=0.04, pc=P("3A1F12"))
    for s in (-1, 1):
        p, n = face.pt(s * 22, -32, 0.0)
        cone(m, P("FFF6E0"), p + n * 0.02, p + n * 0.05 + Vector((0, 0, 0.13)), 0.045, seg=5, part="MouthTeeth")
    nose(m, face, -4, (0.08, 0.05, 0.06), pc=MK, part="Nose")
    for i, ang in enumerate((-70, -42, -14, 14, 42, 70)):
        a = math.radians(ang)
        d = Vector((math.sin(a), 0.15, math.cos(a)))
        base = Vector((math.sin(a) * 0.3, 0.05, 2.35))
        q = d.to_track_quat('Z', 'Y')
        M = Matrix.Translation(base) @ q.to_matrix().to_4x4() @ Matrix.Rotation(math.radians(-90), 4, 'Y')
        slab(m, LEAF, leaf_poly(0.95 if abs(ang) < 50 else 0.75, 0.2), 0.05, M, part="Accent")
    p, n = face.pt(0, 62); gem(m, GL, p + n * 0.05 + Vector((0, 0, 0.04)), 0.11, h=0.18, part="Glow", rot=(80, 0, 0))
    for s in (-1, 1):
        cyl(m, GD, (s * 0.7, -0.05, 1.45), r=0.1, h=0.03, seg=10, rot=(0, 90, 0), part="AccentGold")
        torus(m, GD, (s * 0.72, -0.05, 1.28), R=0.09, r=0.025, seg=10, rseg=4, rot=(0, 90, 0), part="AccentGold")
        vtube(m, B, [(s * 0.58, -0.05, 1.05), (s * 0.8, -0.2, 0.85), (s * 0.78, -0.35, 0.72)], [0.12, 0.11, 0.1], seg=7)
        ell(m, FACE, (s * 0.78, -0.38, 0.7), 0.13, part="Belly", seg=8)
        ell(m, B, (s * 0.28, -0.25, 0.1), (0.22, 0.28, 0.12), seg=8)
    from w2lib import tube
    tube(m, GD, [(math.cos(a) * 0.62, math.sin(a) * 0.56, 1.12) for a in [2 * math.pi * i / 14 for i in range(14)]], r=0.04, seg=5, part="AccentGold", closed=True, smooth=1)
    return {}




