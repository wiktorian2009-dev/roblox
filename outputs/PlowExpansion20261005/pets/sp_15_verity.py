# Verity Egg (paid shop egg, 2026-10-06, Claude): five cartoony lion-cub themed pets - truth (Verity), a sly masked fox (Falsity),
# a grumpy-cute spiky dragon pup (Cruelty), a crowned royal lion (Lord Verity) and a rainbow winged lion (Rainbow Verity).
# Same kit and rules as the 70 rebuilt pets (role-prefixed parts, <= 12 objects, eyes with highlights). Bigger size box: these are OP pets.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import tube

def pair(f):
    for s in (-1, 1): f(s)

GOLD = P("FFD84A", "ME")
GEM = P("7FE3FF", "NE")

def mane(m, pc, h, n=10, R=0.62, r=0.21, dy=0.14, part="Mark", scale_z=0.94):
    """puffy mane ring behind the face (balls on a circle in the XZ plane)"""
    for i in range(n):
        a = 2 * math.pi * i / n
        ell(m, pc, (math.cos(a) * R, h.c.y + dy, h.c.z + math.sin(a) * R * scale_z), r, part=part, seg=8, rings=6)

def halo(m, pc, c, R=0.3, r=0.05, part="Accent"):
    pts = [(c[0] + math.cos(a) * R, c[1] + math.sin(a) * R * 0.85, c[2]) for a in [2 * math.pi * i / 16 for i in range(16)]]
    tube(m, pc, pts, r=r, seg=6, part=part, closed=True, smooth=1)

def lion_body(m, B, BE, z0=0.0, big=1.0):
    ell(m, B, (0, 0.14, 0.56 + z0), (0.48 * big, 0.54 * big, 0.54 * big))
    ell(m, BE, (0, -0.22, 0.58 + z0), (0.3 * big, 0.2 * big, 0.34 * big), part="Belly")
    pair(lambda s: leg(m, B, (s * 0.21, -0.22, 0.55 + z0), (s * 0.23, -0.34, 0.1), r=0.11))
    pair(lambda s: ell(m, B, (s * 0.36, 0.2, 0.28), (0.21, 0.34, 0.27)))

def lion_tail(m, B, TUFT, part="Mark"):
    vtube(m, B, [(0, 0.6, 0.45), (0.25, 0.9, 0.55), (0.42, 1.0, 0.85)], [0.07, 0.065, 0.06], seg=7)
    ell(m, TUFT, (0.45, 1.02, 0.95), (0.15, 0.15, 0.18), part=part, seg=8, rings=6)

@pet("Verity")
def verity(m):
    B, BE, MANE = P("FFF2D6"), P("FFFFFF"), P("FFC96B")
    lion_body(m, B, BE)
    h = Head((0, -0.06, 1.38), (0.6, 0.53, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mane(m, MANE, h, n=10, R=0.6, r=0.2)
    mz = Head((0, -0.5, 1.24), (0.26, 0.18, 0.17)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    round_ear(m, B, BE, h, 42, 46, r=0.17, thick=0.5, out=12)
    lion_tail(m, B, MANE)
    halo(m, GOLD, (0, -0.02, 2.06), R=0.3, r=0.045)
    h.put(m, GEM, 0, 40, (0.075, 0.035, 0.1), "Glow", off=0.012)
    eyes(m, h, 26, 6, rx=0.13, rz=0.16)
    nose(m, mz, 34, (0.06, 0.04, 0.04), pc=P("FF8FAE"))
    mouth(m, mz, -16, w=16, kind="w", sag=9)
    blush(m, h, 46, -10, 0.09)
    return {"L": 3.4, "H": 2.9}

@pet("Falsity")
def falsity(m):
    B, BE, MASK, TRIM, TIP = P("9B6BFF"), P("F1E6FF"), P("FFFFFF"), P("FFD84A"), P("FF8AD8")
    ell(m, B, (0, 0.14, 0.55), (0.46, 0.52, 0.55))
    ell(m, BE, (0, -0.24, 0.72), (0.3, 0.2, 0.32), part="Belly")
    h = Head((0, -0.06, 1.34), (0.62, 0.55, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.5, 1.2), (0.22, 0.28, 0.18)); ell(m, BE, sn.c, sn.r, part="Belly", seg=10, rings=7)
    pair(lambda s: cone(m, BE, (s * 0.42, -0.2, 1.14), (s * 0.76, -0.12, 1.04), 0.15, seg=7, part="Belly"))
    pointy_ear(m, B, TIP, h, 34, 50, height=0.62, width=0.26, out=16, back=-6, ipart="AccentTip")
    pair(lambda s: leg(m, B, (s * 0.2, -0.24, 0.6), (s * 0.22, -0.36, 0.1), r=0.1))
    pair(lambda s: ell(m, B, (s * 0.36, 0.18, 0.3), (0.2, 0.34, 0.28)))
    # big curly tail with a pink tip
    vtube(m, B, [(0.2, 0.55, 0.3), (0.62, 0.62, 0.55), (0.72, 0.4, 1.0), (0.48, 0.3, 1.3)], [0.13, 0.24, 0.24, 0.16], seg=12, part="Body")
    vtube(m, TIP, [(0.52, 0.31, 1.25), (0.42, 0.3, 1.38), (0.3, 0.32, 1.42)], [0.17, 0.12, 0.0], seg=10, part="AccentTip", smooth=2)
    # a party mask pushed up on the forehead (the "two faces" of Falsity): white face with gold trim and a cheeky smile
    p, n = h.pt(-24, 40)
    disc(m, MASK, [(math.cos(a) * 0.29, math.sin(a) * 0.24) for a in [2 * math.pi * i / 14 for i in range(14)]], 0.06, p + n * 0.04, normal=n, part="Accent", spin=-14)
    for s in (-1, 1):
        q = p + n * 0.085 + Vector((s * 0.11, -0.0, 0.05))
        disc(m, TRIM, star_poly(0.07, 0.03, n=4), 0.025, q, normal=n, part="Mark")
    vtube(m, TRIM, [p + n * 0.08 + Vector((-0.11, 0, -0.08)), p + n * 0.09 + Vector((0, 0, -0.14)), p + n * 0.08 + Vector((0.11, 0, -0.08))], [0.026, 0.026, 0.026], seg=5, part="Mark", smooth=2)
    eyes(m, h, 26, 2, rx=0.13, rz=0.15, tilt=10)
    p2, n2 = sn.pt(0, 12); ell(m, P("3A2457"), p2 + n2 * 0.015, (0.07, 0.05, 0.05), part="Nose", seg=8)
    mouth(m, sn, -26, w=14, kind="smile", sag=9, yaw0=6)
    blush(m, h, 46, -12, 0.09)
    return {"L": 3.4, "H": 2.9}

@pet("Cruelty")
def cruelty(m):
    B, BE, HORN, WG, EMB = P("D9405A"), P("FFD9C2"), P("4A2033"), P("8C2140"), P("FF9A3C", "NE")
    ell(m, B, (0, 0.12, 0.62), (0.5, 0.52, 0.56))
    bel = Head((0, -0.16, 0.6), (0.34, 0.28, 0.4)); ell(m, BE, bel.c, bel.r, part="Belly", seg=10, rings=7)
    h = Head((0, -0.1, 1.44), (0.6, 0.54, 0.5)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.56, 1.28), (0.26, 0.22, 0.16)); ell(m, BE, sn.c, sn.r, part="Belly", seg=10, rings=7)
    for s in (-1, 1):
        b = h.pt(s * 32, 50, -0.05)[0]
        horn(m, HORN, b, b + Vector((s * 0.12, 0.12, 0.28)), b + Vector((s * 0.05, 0.3, 0.42)), 0.09)
    for k, z in enumerate((1.02, 0.78, 0.55)):
        cone(m, HORN, (0, 0.5 + k * 0.08, z + 0.1), (0, 0.72 + k * 0.08, z + 0.32), 0.09, seg=6)
    wings(m, WG, "bat", (0.36, 0.34, 1.02), span=0.8, hgt=0.6, thick=0.06, spread=(20, 30, 0), part="AccentWing")
    pair(lambda s: leg(m, B, (s * 0.22, -0.2, 0.55), (s * 0.24, -0.32, 0.1), r=0.12))
    pair(lambda s: ell(m, B, (s * 0.38, 0.2, 0.28), (0.22, 0.34, 0.27)))
    vtube(m, B, [(0, 0.55, 0.42), (0.35, 0.95, 0.35), (0.62, 1.05, 0.55), (0.7, 0.95, 0.82)], [0.17, 0.12, 0.08, 0.05], seg=8)
    ell(m, EMB, (0.72, 0.93, 0.9), (0.13, 0.13, 0.17), part="Glow", seg=8, rings=6)
    # grumpy-cute: slanted eyes, little fang, tiny brows
    eyes(m, h, 25, 4, rx=0.13, rz=0.14, tilt=-12)
    for s in (-1, 1):
        a, _ = h.pt(s * 34, 22, 0.03); b2, _ = h.pt(s * 16, 18, 0.03)
        vtube(m, P("241C33"), [a, b2], [0.022, 0.026], seg=5, part="Eye", smooth=1)
    mouth(m, sn, -22, w=16, kind="smile", sag=7)
    fang(m, sn, 10, -22, size=0.06)
    sn.put(m, P("5A1F2E"), 0, 30, (0.06, 0.035, 0.035), "Nose", off=0.01)
    blush(m, h, 48, -10, 0.09)
    return {"L": 3.6, "H": 3.0}

@pet("Lord Verity")
def lord_verity(m):
    B, BE, MANE, CAPE = P("FFC85A"), P("FFF0D0"), P("FFFFFF"), P("D93A4E")
    lion_body(m, B, BE, big=1.06)
    h = Head((0, -0.08, 1.42), (0.62, 0.55, 0.53)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mane(m, MANE, h, n=12, R=0.66, r=0.25, dy=0.16)
    mz = Head((0, -0.52, 1.27), (0.27, 0.19, 0.17)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    round_ear(m, B, BE, h, 42, 46, r=0.17, thick=0.5, out=12)
    # royal cape behind the body
    cape = [(-0.55, 1.05), (0.55, 1.05), (0.7, 0.2), (0.35, 0.05), (0.0, 0.12), (-0.35, 0.05), (-0.7, 0.2)]
    slab(m, CAPE, cape, 0.06, Matrix.Translation(Vector((0, 0.62, 0.02))) @ Euler((math.radians(-8), 0, 0), 'XYZ').to_matrix().to_4x4(), part="AccentCape")
    # crown: a gold band with points and a gem in front
    band = [(math.cos(a) * 0.3, -0.04 + math.sin(a) * 0.27, 2.0) for a in [2 * math.pi * i / 14 for i in range(14)]]
    tube(m, GOLD, band, r=0.06, seg=6, part="Accent", closed=True, smooth=1)
    for k in range(5):
        a = math.radians(-90 + (k - 2) * 38)
        b = Vector((math.cos(a) * 0.3, -0.04 + math.sin(a) * 0.27, 2.02))
        cone(m, GOLD, b, b + Vector((0, 0, 0.24)), 0.07, seg=5)
    h.put(m, GEM, 0, 58, (0.07, 0.035, 0.09), "Glow", off=0.06)
    lion_tail(m, B, MANE)
    eyes(m, h, 26, 6, rx=0.13, rz=0.16)
    nose(m, mz, 34, (0.065, 0.045, 0.045), pc=P("8A4B2E"))
    mouth(m, mz, -16, w=16, kind="w", sag=9)
    blush(m, h, 46, -10, 0.09)
    return {"L": 3.9, "H": 3.3}

@pet("Rainbow Verity")
def rainbow_verity(m):
    B, BE, WG, HALO = P("FFFFFF"), P("FFF3FB"), P("BFD8FF"), P("FFE88A", "NE")
    RAIN = [P("FF6B8A"), P("FFD84A"), P("6FE3A0"), P("9B7BFF")]
    lion_body(m, B, BE, big=1.06)
    h = Head((0, -0.08, 1.42), (0.62, 0.55, 0.53)); ell(m, B, h.c, h.r, seg=12, rings=8)
    names = ("MarkRose", "MarkSun", "MarkMint", "MarkViolet")
    for i in range(12):  # rainbow mane: alternating colours around the face
        a = 2 * math.pi * i / 12
        ell(m, RAIN[i % 4], (math.cos(a) * 0.66, h.c.y + 0.16, h.c.z + math.sin(a) * 0.62), 0.24, part=names[i % 4], seg=8, rings=6)
    mz = Head((0, -0.52, 1.27), (0.27, 0.19, 0.17)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    round_ear(m, B, BE, h, 42, 46, r=0.17, thick=0.5, out=12)
    wings(m, WG, "feather", (0.36, 0.36, 1.0), span=1.25, hgt=0.85, thick=0.07, spread=(24, 26, 0), part="AccentWing", lobes=3)
    halo(m, HALO, (0, -0.04, 2.1), R=0.32, r=0.05, part="Glow")
    vtube(m, B, [(0, 0.6, 0.45), (0.25, 0.9, 0.55), (0.42, 1.0, 0.85)], [0.07, 0.065, 0.06], seg=7)
    ell(m, RAIN[3], (0.45, 1.02, 0.95), (0.15, 0.15, 0.18), part="MarkViolet", seg=8, rings=6)
    eyes(m, h, 26, 6, rx=0.135, rz=0.165)
    nose(m, mz, 34, (0.065, 0.045, 0.045), pc=P("FF8FAE"))
    mouth(m, mz, -16, w=16, kind="w", sag=9)
    return {"L": 4.1, "H": 3.4}
