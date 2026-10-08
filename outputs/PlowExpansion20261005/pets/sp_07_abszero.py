# Absolute Zero Egg: frosted silhouettes, elegant icy details.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet

def pair(f):
    for s in (-1, 1): f(s)

ICE = P("8FDFFF", "IC")

def snowflake(m, pc, c, r, normal=(0, -1, 0), part="Accent"):
    pts = []
    for i in range(6):
        a = math.pi / 3 * i
        for (rr, da) in ((r * 0.22, -0.5), (r, -0.12), (r, 0.12)):
            pts.append((math.cos(a + da) * rr, math.sin(a + da) * rr))
    disc(m, pc, pts, r * 0.22, c, normal=normal, part=part)

@pet("Frost Sprite")
def frost_sprite(m):
    B, WG, BE = P("C4EEFF"), P("9FE4FF", "SP", 0.25), P("F4FCFF")
    h = Head((0, 0, 1.4), (0.56, 0.5, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    vtube(m, B, [(0, 0.02, 1.0), (0, 0.04, 0.72), (0.12, 0.12, 0.42), (0.3, 0.1, 0.22), (0.4, -0.05, 0.12), (0.3, -0.12, 0.02)], [0.36, 0.3, 0.2, 0.12, 0.06, 0.0], seg=10)
    ell(m, BE, (0, -0.22, 0.9), (0.22, 0.14, 0.2), part="Belly")
    pair(lambda s: vtube(m, B, [(s * 0.26, -0.05, 0.98), (s * 0.45, -0.15, 0.85)], [0.07, 0.06], seg=6, smooth=1))
    vtube(m, B, [h.pt(0, 70, -0.05)[0], (0.05, 0.0, 2.02), (0.2, 0.05, 2.08), (0.24, 0.08, 1.96)], [0.12, 0.08, 0.05, 0.0], seg=8)
    for k, a in enumerate((-28, 0, 28)):
        b, n = h.pt(a, 58, -0.04)
        crystal(m, ICE, b, n + Vector((0, 0, 1.2)), 0.36 if a == 0 else 0.26, 0.07, seg=6, part="Accent")
    wings(m, WG, "leaf", (0.2, 0.32, 1.25), span=0.85, hgt=0.75, thick=0.04, spread=(-35, 30, -10), part="AccentWing")
    wings(m, WG, "leaf", (0.2, 0.32, 1.02), span=0.6, hgt=0.5, thick=0.04, spread=(25, 30, -10), part="AccentWing")
    eyes(m, h, 26, 0, rx=0.14, rz=0.17)
    mouth(m, h, -20, w=8, kind="smile", sag=5)
    blush(m, h, 44, -12, 0.09)
    return {"H": 2.4}

@pet("Ice Seal")
def ice_seal(m):
    B, BE, MK = P("EEF4FB"), P("FFFFFF"), P("A9C6E2")
    vtube(m, B, [(0, -0.3, 0.55), (0, 0.15, 0.46), (0, 0.6, 0.34), (0, 0.95, 0.22), (0, 1.12, 0.18)], [0.5, 0.48, 0.34, 0.18, 0.1], seg=12)
    h = Head((0, -0.42, 0.98), (0.56, 0.5, 0.48)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, B, (0, -0.2, 0.42), (0.48, 0.5, 0.4))
    for s in (-1, 1):
        ell(m, B, (s * 0.2, 1.26, 0.18), (0.2, 0.26, 0.06), rot=(0, 0, s * 30), seg=8, rings=5)
        ell(m, B, (s * 0.52, -0.36, 0.18), (0.26, 0.14, 0.08), rot=(0, -s * 15, s * -30), seg=8, rings=5)
    cheeks = []
    for s in (-1, 1):
        p, n = h.pt(s * 14, -22)
        ell(m, BE, p + n * 0.02, (0.14, 0.1, 0.11), part="Belly", seg=8, rings=6)
        cheeks.append(Head(p + n * 0.02, (0.14, 0.1, 0.11)))
        for d in (-1, 0, 1):
            cheeks[-1].put(m, MK, s * 25 + d * 18, 10 - d * 12, (0.016, 0.01, 0.016), "Mark", off=0.0, seg=5, rings=3)
    p, n = h.pt(0, -10); ell(m, P("2D2433"), p + n * 0.05, (0.08, 0.05, 0.055), part="Nose", seg=8)
    eyes(m, h, 30, 10, rx=0.14, rz=0.17)
    blush(m, h, 50, -10, 0.09)
    p, n = h.pt(-38, 50); snowflake(m, ICE, p + n * 0.05, 0.16, normal=n)
    return {"L": 2.9, "H": 2.2}

@pet("Snow Owl")
def snow_owl(m):
    B, BE, MK, GD = P("F7FAFF"), P("E1EAF7"), P("8DA6C8"), P("F2B84A")
    body = Head((0, 0.05, 0.98), (0.66, 0.6, 0.86)); ell(m, B, body.c, body.r, seg=12, rings=9)
    disc_c = Head((0, -0.14, 1.32), (0.52, 0.42, 0.4)); ell(m, BE, disc_c.c, disc_c.r, part="Belly", seg=12, rings=8)
    for s in (-1, 1):
        b, n = body.pt(s * 40, 62, -0.06)
        cone(m, B, b, b + Vector((s * 0.12, 0.02, 0.36)), 0.14, seg=6, part="Body")
        ell(m, B, (s * 0.6, 0.1, 0.92), (0.14, 0.4, 0.56), rot=(10, -s * 8, 0), seg=10)
        ell(m, MK, (s * 0.66, 0.22, 0.6), (0.1, 0.24, 0.24), rot=(10, -s * 8, 0), part="Mark", seg=8, rings=5)
        p, n = disc_c.pt(s * 30, 12)
        ell(m, GD, p + n * 0.01, (0.17, 0.035, 0.17), part="Accent", seg=10, rings=6, q=n.to_track_quat('Y', 'Z'))
        for k in range(3):
            ell(m, GD, (s * 0.2 + (k - 1) * 0.06, -0.48, 0.05), (0.03, 0.09, 0.03), part="Accent", seg=5, rings=3)
        ell(m, B, (s * 0.2, -0.36, 0.12), (0.16, 0.16, 0.12), seg=8)
    for (a, pp) in [(-30, -35), (0, -45), (30, -35), (-15, -20), (15, -20), (-40, -55), (40, -55)]:
        p, n = body.pt(a, pp)
        vtube(m, MK, [p + Vector((-0.04, 0, 0.03)), p, p + Vector((0.04, 0, 0.03))], [0.018] * 3, seg=4, part="Mark", smooth=1)
    p, n = disc_c.pt(0, -8)
    cone(m, GD, p - n * 0.03, p + n * 0.12 + Vector((0, 0, -0.08)), 0.07, seg=6, part="Accent")
    eyes(m, disc_c, 30, 12, rx=0.12, rz=0.14, gap=0.04)
    blush(m, disc_c, 52, -12, 0.07)

@pet("Glacier Mammoth")
def mammoth(m):
    B, BE, TUSK = P("8DB3DE"), P("D8E9FA"), P("F7FBFF")
    ell(m, B, (0, 0.3, 0.95), (0.62, 0.78, 0.58))
    for k in range(9):
        a = math.radians(-120 + 240 * k / 8)
        b = Vector((math.sin(a) * 0.58, 0.3 - math.cos(a) * 0.72, 0.6))
        cone(m, BE, b, b + Vector((math.sin(a) * 0.12, -math.cos(a) * 0.1, -0.28)), 0.15, seg=6, part="Belly")
    h = Head((0, -0.48, 1.42), (0.58, 0.5, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    ell(m, B, (0, -0.42, 1.86), (0.3, 0.3, 0.22), seg=8)
    vtube(m, B, [h.pt(0, -10, -0.1)[0], (0, -1.08, 1.12), (0, -1.12, 0.72), (0, -1.0, 0.5), (0, -0.88, 0.58)], [0.18, 0.15, 0.12, 0.09, 0.07], seg=10)
    for s in (-1, 1):
        p, n = h.pt(s * 72, 4)
        ell(m, B, p + Vector((s * 0.02, 0.2, -0.08)), (0.07, 0.28, 0.3), rot=(0, 0, -s * 45), seg=10)
        b = h.pt(s * 22, -30, -0.08)[0]
        vtube(m, TUSK, [b, b + Vector((s * 0.12, -0.3, -0.25)), b + Vector((s * 0.1, -0.62, -0.1)), b + Vector((s * 0.0, -0.66, 0.15))], [0.08, 0.07, 0.05, 0.0], seg=8, part="Accent")
        for y in (-0.15, 0.78):
            leg(m, B, (s * 0.34, y, 0.7), (s * 0.35, y, 0.12), r=0.2, paw=1.1)
            for d in (-1, 0, 1):
                ell(m, BE, (s * 0.35 + d * 0.09, y - 0.25, 0.06), 0.05, part="Belly", seg=5, rings=4)
    for d in ((0.2, 0.6, 1), (-0.25, 0.5, 1), (0.0, 0.2, 1), (0.1, 1.0, 0.8)):
        crystal(m, ICE, (d[0] * 0.6, d[1], 1.45), (d[0], 0.2, d[2]), 0.42, 0.1, part="AccentIce")
    vtube(m, B, [(0, 1.05, 0.95), (0, 1.2, 0.75)], [0.05, 0.04], seg=6, smooth=1)
    eyes(m, h, 32, 14, rx=0.12, rz=0.145)
    blush(m, h, 50, -8, 0.09)
    return {}

@pet("Absolute Phoenix")
def phoenix(m):
    B, BE, WG, MK, GD, GL = P("8FDFFF"), P("F4FBFF"), P("C9B8FF"), P("5CC4F2"), P("FFD36E", "ME"), P("CFF6FF", "NE")
    body = Head((0, 0.1, 0.95), (0.48, 0.46, 0.55)); ell(m, B, body.c, body.r)
    ell(m, BE, (0, -0.12, 0.88), (0.34, 0.3, 0.42), part="Belly")
    h = Head((0, -0.12, 1.7), (0.5, 0.45, 0.45)); ell(m, B, h.c, h.r, seg=12, rings=8)
    
    for k, (dx, ln, dz) in enumerate(((-0.14, 0.5, 0.0), (0.0, 0.68, 0.1), (0.14, 0.5, 0.0))):
        b = h.pt(dx * 120, 60, -0.05)[0]
        vtube(m, WG, [b, b + Vector((dx, 0.25, 0.25 + dz)), b + Vector((dx * 1.6, 0.55, 0.38 + dz)), b + Vector((dx * 2, 0.75, 0.3 + dz))][:4], [0.07, 0.06, 0.04, 0.0], seg=6, part="Accent", sq=0.5)
    wings(m, WG, "feather", (0.3, 0.25, 1.15), span=1.6, hgt=1.1, thick=0.07, spread=(38, 25, 0), part="Accent", lobes=4)
    wings(m, MK, "feather", (0.32, 0.27, 1.05), span=1.0, hgt=0.6, thick=0.08, spread=(30, 25, 0), part="Mark", lobes=3)
    for k, dx in enumerate((-0.18, 0.0, 0.18)):
        b = Vector((dx * 0.4, 0.4, 0.62))
        pts = [b, b + Vector((dx, 0.45, -0.2)), b + Vector((dx * 2, 0.8, -0.42)), b + Vector((dx * 2.6, 1.05, -0.3)), b + Vector((dx * 2.8, 1.1, -0.1))]
        vtube(m, WG, pts, [0.06, 0.11, 0.12, 0.08, 0.0], seg=6, part="Accent", sq=0.4)
        ell(m, MK, pts[2] + Vector((0, 0, 0)), (0.07, 0.07, 0.12), part="Mark", seg=6, rings=4)
    pair(lambda s: (vtube(m, GD, [(s * 0.16, 0.05, 0.5), (s * 0.18, 0.0, 0.08)], [0.05, 0.045], seg=5, part="AccentGold", smooth=1),
                    ell(m, GD, (s * 0.18, -0.08, 0.04), (0.08, 0.12, 0.04), part="AccentGold", seg=6)))
    p, n = h.pt(0, -6)
    cone(m, GD, p - n * 0.03, p + n * 0.18 + Vector((0, 0, -0.06)), 0.08, seg=6, part="AccentGold")
    from w2lib import tube
    tube(m, GL, [(math.cos(a) * 0.32, 0.05 + math.sin(a) * 0.32, 2.34) for a in [2 * math.pi * i / 18 for i in range(18)]], r=0.035, seg=5, part="Glow", closed=True, smooth=1)
    eyes(m, h, 28, 10, rx=0.12, rz=0.15, tilt=6)
    lashes(m, h, 28, 10, 0.12, 0.15)
    blush(m, h, 48, -10, 0.08)
    return {"H": 3.1}

