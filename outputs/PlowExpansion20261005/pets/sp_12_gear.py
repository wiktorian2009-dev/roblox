# Gear (Clockwork) Egg: brass, copper, teal, rivets, little gears.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet
from w2lib import tube

def pair(f):
    for s in (-1, 1): f(s)

BRASS = P("E0B04A", "ME")
COPPER = P("C9773E", "ME")
TEALM = P("3FBFB4", "ME")
CREAM = P("F6E7C8")

def gearwheel(m, pc, hub_pc, c, R, normal=(0, -1, 0), teeth=8, part="Accent", hub_part="Mark", thick=0.05, spin=0.0):
    disc(m, pc, gear_poly(R, teeth, 0.24), thick, c, normal=normal, part=part, spin=spin)
    n = Vector(normal).normalized()
    ell(m, hub_pc, Vector(c) + n * thick * 0.6, (R * 0.32, R * 0.32, R * 0.32), part=hub_part, seg=8, rings=4, q=n.to_track_quat('Z', 'Y'))

def windkey(m, pc, base, direction=(0, 1, 0), size=1.0, part="Accent"):
    d = Vector(direction).normalized(); b = Vector(base)
    vtube(m, pc, [b, b + d * 0.22 * size], [0.04 * size, 0.04 * size], seg=6, part=part, smooth=1)
    c = b + d * 0.24 * size
    side = d.cross(Vector((0, 0, 1))).normalized() if abs(d.z) < 0.9 else Vector((1, 0, 0))
    for s in (-1, 1):
        ell(m, pc, c + side * s * 0.13 * size, (0.12 * size, 0.04 * size, 0.1 * size), part=part, seg=8, rings=5, q=d.to_track_quat('Y', 'Z'))

@pet("Brass Beetle")
def brass_beetle(m):
    sh = Head((0, 0.12, 0.62), (0.64, 0.7, 0.52)); ell(m, BRASS, sh.c, sh.r, part="Body", seg=14, rings=8)
    ell(m, CREAM, (0, 0.1, 0.38), (0.58, 0.62, 0.2), part="Belly")
    vtube(m, COPPER, [sh.pt(180, a, 0.0)[0] for a in (2, 30, 60, 88)] + [sh.pt(0, 70, 0)[0]], [0.035] * 5, seg=6, part="Mark", smooth=2)
    for (a, pp) in [(140, 20), (220, 20), (110, 45), (250, 45), (155, 70), (205, 70)]:
        p, n = sh.pt(a, pp); ell(m, COPPER, p, 0.04, part="Mark", seg=5, rings=4)
    p, n = sh.pt(180, 48)
    gearwheel(m, TEALM, COPPER, p + n * 0.02, 0.26, normal=n, teeth=9, part="Accent", hub_part="Mark")
    h = Head((0, -0.56, 0.62), (0.4, 0.32, 0.34)); ell(m, COPPER, h.c, h.r, part="AccentHead", seg=12, rings=8)
    for s in (-1, 1):
        b = h.pt(s * 30, 60, -0.03)[0]
        vtube(m, COPPER, [b, b + Vector((s * 0.1, -0.12, 0.25)), b + Vector((s * 0.2, -0.15, 0.36))], [0.022, 0.02, 0.02], seg=5, part="AccentHead", smooth=2)
        gearwheel(m, TEALM, COPPER, b + Vector((s * 0.22, -0.16, 0.4)), 0.08, normal=(0, -1, 0), teeth=6, part="Accent", hub_part="Mark", thick=0.035)
        for y in (-0.3, 0.1, 0.5):
            vtube(m, COPPER, [(s * 0.5, y, 0.38), (s * 0.78, y - 0.05, 0.3), (s * 0.82, y - 0.08, 0.04)], [0.05, 0.045, 0.04], seg=6, part="AccentHead", smooth=2)
    eyes(m, h, 30, 6, rx=0.11, rz=0.14)
    mouth(m, h, -22, w=12, kind="smile", sag=6)
    blush(m, h, 54, -10, 0.07)
    return {"L": 3.0}

@pet("Clockwork Bird")
def clockwork_bird(m):
    B, BE = TEALM, CREAM
    body = Head((0, 0.08, 0.95), (0.62, 0.58, 0.64)); ell(m, B, body.c, body.r, part="Body", seg=12, rings=8)
    ell(m, BE, (0, -0.2, 0.8), (0.44, 0.38, 0.46), part="Belly")
    wings(m, BRASS, "feather", (0.5, 0.15, 1.0), span=0.75, hgt=0.55, thick=0.07, spread=(-5, 30, 0), part="Accent", lobes=3)
    for s in (-1, 1):
        for k in range(3):
            p = Vector((s * (0.62 + k * 0.17), 0.2 + k * 0.08, 1.08 + k * 0.02))
            ell(m, COPPER, p + Vector((0, -0.05, 0)), 0.035, part="Mark", seg=5, rings=4)
        vtube(m, BRASS, [(s * 0.2, 0.05, 0.38), (s * 0.22, 0.0, 0.08)], [0.04, 0.04], seg=5, part="Accent", smooth=1)
        for d in (-30, 0, 30):
            a = math.radians(d)
            vtube(m, BRASS, [(s * 0.22, 0.0, 0.04), (s * 0.22 + math.sin(a) * 0.12, -math.cos(a) * 0.14, 0.03)], [0.03, 0.025], seg=5, part="Accent", smooth=1)
    for k, dx in enumerate((-0.16, 0.0, 0.16)):
        cone(m, BRASS, (dx * 0.6, 0.55, 0.9), (dx * 2.2, 0.95, 1.15 - abs(dx)), 0.1, seg=6, part="Accent", sq=0.5)
    windkey(m, BRASS, (0, 0.55, 1.2), (0, 1, 0.3), size=0.9, part="Accent")
    p, n = body.pt(0, 8)
    cone(m, COPPER, p - n * 0.04, p + n * 0.24 + Vector((0, 0, -0.04)), 0.1, seg=6, part="AccentBeak")
    b = body.pt(0, 72, -0.04)[0]
    gearwheel(m, BRASS, COPPER, b + Vector((0, 0.05, 0.12)), 0.17, normal=(0, -1, 0.15), teeth=8, part="Accent", hub_part="Mark")
    eyes(m, body, 30, 22, rx=0.13, rz=0.16)
    blush(m, body, 50, 8, 0.08)
    return {"H": 2.4}

@pet("Steam Pup")
def steam_pup(m):
    B, BE, MK, LENS, PUFF = P("D07A48"), CREAM, P("8E4A2A"), P("6FE0D8"), P("F4F4F4")
    ell(m, B, (0, 0.12, 0.58), (0.46, 0.5, 0.52))
    ell(m, BE, (0, -0.2, 0.6), (0.3, 0.24, 0.36), part="Belly")
    h = Head((0, -0.08, 1.38), (0.62, 0.55, 0.52)); ell(m, B, h.c, h.r, seg=12, rings=8)
    mz = Head((0, -0.52, 1.24), (0.28, 0.2, 0.2)); ell(m, BE, mz.c, mz.r, part="Belly", seg=10, rings=7)
    for s in (-1, 1):
        b = h.pt(s * 58, 42, -0.06)[0]
        vtube(m, MK, [b, b + Vector((s * 0.2, 0.02, 0.02)), b + Vector((s * 0.3, -0.02, -0.3)), b + Vector((s * 0.28, -0.06, -0.6))], [0.12, 0.17, 0.17, 0.08], seg=8, part="Mark", sq=0.45, up=(s, 0, 0))
    p, n = mz.pt(0, 34); ell(m, P("2A2026"), p + n * 0.01, (0.09, 0.055, 0.06), part="Nose", seg=8)
    for s in (-1, 1):
        q, nn = h.pt(s * 22, 44)
        tube(m, BRASS, [q + nn * 0.04 + (Vector((math.cos(a), 0, math.sin(a))) * 0.13) for a in [2 * math.pi * i / 10 for i in range(10)]], r=0.035, seg=5, part="Accent", closed=True, smooth=1)
        ell(m, LENS, q + nn * 0.04, (0.12, 0.03, 0.12), part="AccentLens", seg=8, rings=5, q=nn.to_track_quat('Y', 'Z'))
        leg(m, B, (s * 0.2, -0.22, 0.55), (s * 0.22, -0.32, 0.1), r=0.1)
        ell(m, B, (s * 0.34, 0.16, 0.26), (0.2, 0.32, 0.26))
    band = [h.pt(a, 44 + (90 - 44) * 0.0, 0.03)[0] for a in (-60, -40)] + [h.pt(a, 44, 0.03)[0] for a in (40, 60)]
    vtube(m, COPPER, [h.pt(-80, 40, 0.03)[0], h.pt(-34, 44, 0.03)[0]], [0.03, 0.03], seg=5, part="AccentStrap", smooth=1)
    vtube(m, COPPER, [h.pt(34, 44, 0.03)[0], h.pt(80, 40, 0.03)[0]], [0.03, 0.03], seg=5, part="AccentStrap", smooth=1)
    vtube(m, COPPER, [h.pt(-10, 44, 0.04)[0], h.pt(10, 44, 0.04)[0]], [0.03, 0.03], seg=5, part="AccentStrap", smooth=1)
    cyl(m, BRASS, (0.0, 0.42, 0.8), r=0.1, h=0.45, seg=10, rot=(-15, 0, 0), part="Accent")
    cyl(m, BRASS, (0.0, 0.53, 1.22), r=0.14, h=0.06, seg=10, rot=(-15, 0, 0), part="Accent")
    for (x, y, z, r) in ((0.0, 0.58, 1.4, 0.13), (0.12, 0.66, 1.52, 0.1), (-0.06, 0.7, 1.62, 0.08)):
        ell(m, PUFF, (x, y, z), r, part="Belly", seg=8)
    vtube(m, B, [(0, 0.55, 0.45), (0.15, 0.78, 0.65), (0.2, 0.75, 0.9)], [0.08, 0.07, 0.04], seg=7)
    eyes(m, h, 26, 4, rx=0.12, rz=0.145)
    mouth(m, mz, -20, w=18, kind="w", sag=10)
    blush(m, h, 48, -10, 0.09)

@pet("Gear Fox")
def gear_fox(m):
    B, BE, MK = P("FF8A3D"), CREAM, P("7A3E1E")
    bh = Head((0, 0.28, 0.82), (0.42, 0.68, 0.4)); ell(m, B, bh.c, bh.r)
    ell(m, BE, (0, -0.15, 0.85), (0.3, 0.26, 0.32), part="Belly")
    h = Head((0, -0.52, 1.4), (0.56, 0.5, 0.47)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -0.98, 1.27), (0.2, 0.28, 0.16)); ell(m, BE, sn.c, sn.r, part="Belly", seg=10, rings=7)
    pair(lambda s: cone(m, BE, (s * 0.38, -0.66, 1.24), (s * 0.7, -0.6, 1.14), 0.15, seg=7, part="Belly"))
    pointy_ear(m, B, MK, h, 34, 48, height=0.6, width=0.25, out=14, back=-8, ipart="Mark")
    for sx in (-1, 1):
        for y in (-0.15, 0.68):
            leg(m, B, (sx * 0.24, y, 0.7), (sx * 0.25, y, 0.1), r=0.11, paw=1.15)
            ell(m, MK, (sx * 0.25, y - 0.03, 0.08), (0.13, 0.15, 0.08), part="Mark", seg=8)
    tp = [(0, 0.9, 0.95), (0.1, 1.28, 1.1), (0.2, 1.38, 1.5), (0.1, 1.2, 1.82)]
    vtube(m, B, tp, [0.13, 0.27, 0.26, 0.0], seg=12)
    for (c, r) in (((0.08, 1.22, 1.07), 0.24), ((0.18, 1.37, 1.42), 0.27)):
        tube(m, BRASS, [Vector(c) + Vector((math.cos(a) * r, math.sin(a) * r * 0.5, math.sin(a) * r * 0.6)) for a in [2 * math.pi * i / 10 for i in range(10)]], r=0.035, seg=5, part="Accent", closed=True, smooth=1)
    vtube(m, BE, [(0.17, 1.33, 1.65), (0.1, 1.2, 1.82), (0.04, 1.1, 1.92)], [0.2, 0.15, 0.0], seg=12, part="Belly", smooth=2)
    tube(m, BRASS, [(math.cos(a) * 0.32, -0.42 + math.sin(a) * 0.26, 1.02) for a in [2 * math.pi * i / 10 for i in range(10)]], r=0.035, seg=5, part="Accent", closed=True, smooth=1)
    gearwheel(m, TEALM, BRASS, (0, -0.7, 0.92), 0.12, normal=(0, -1, 0.1), teeth=8, part="AccentTeal", hub_part="Accent")
    p, n = h.pt(-38, 58)
    gearwheel(m, BRASS, TEALM, p + n * 0.05, 0.11, normal=n, teeth=7, part="Accent", hub_part="AccentTeal")
    eyes(m, h, 28, 10, rx=0.12, rz=0.145, tilt=10)
    p, n = sn.pt(0, 22); ell(m, P("2D2433"), p + n * 0.01, (0.07, 0.05, 0.05), part="Nose", seg=8)
    mouth(m, sn, -26, w=16, kind="w", sag=8)
    blush(m, h, 50, -10, 0.08)

@pet("Clockwork Dragon")
def clockwork_dragon(m):
    B, BE, GL = TEALM, CREAM, P("FFE6A0", "NE")
    bh = Head((0, 0.32, 0.92), (0.52, 0.8, 0.5)); ell(m, B, bh.c, bh.r, seg=12, rings=8)
    for k in range(3):
        y = 0.0 + k * 0.32
        tube(m, BRASS, [(math.cos(a) * 0.5, y + math.sin(a) * 0.07, 0.92 + 0.48 * math.sin(a) ** 2 * 0 + math.sin(a) * 0.0) for a in [0]] * 0 + [bh.c + Vector((math.cos(a) * 0.53, y - bh.c.y, math.sin(a) * 0.51)) for a in [math.pi * i / 6 for i in range(-1, 8)]],
             r=0.05, seg=5, part="Accent", closed=False, smooth=1, sq=0.6)
    for k in range(4):
        ell(m, BE, (0, -0.15 + k * 0.27, 0.5), (0.3, 0.13, 0.1), part="Belly", seg=8, rings=4)
    vtube(m, B, [(0, -0.3, 1.1), (0, -0.55, 1.45), (0, -0.62, 1.75)], [0.26, 0.22, 0.22], seg=10)
    for z in (1.4,):
        tube(m, BRASS, [(math.cos(a) * 0.235, -0.55 + math.sin(a) * 0.235, z) for a in [2 * math.pi * i / 10 for i in range(10)]], r=0.035, seg=5, part="Accent", closed=True, smooth=1)
    h = Head((0, -0.72, 1.95), (0.5, 0.46, 0.42)); ell(m, B, h.c, h.r, seg=12, rings=8)
    sn = Head((0, -1.12, 1.84), (0.3, 0.26, 0.2)); ell(m, B, sn.c, sn.r, seg=10, rings=7)
    p, n = h.pt(0, 70); box(m, BRASS, p + Vector((0, 0.05, 0.0)), (0.5, 0.42, 0.1), r=0.04, part="Accent", rot=(-15, 0, 0))
    for s in (-1, 1):
        b = h.pt(s * 32, 50, -0.04)[0]
        horn(m, COPPER, b, b + Vector((s * 0.08, 0.25, 0.25)), b + Vector((s * 0.1, 0.5, 0.3)), 0.07, part="AccentCopper")
        for y in (-0.1, 0.8):
            leg(m, B, (s * 0.3, y, 0.75), (s * 0.32, y, 0.1), r=0.13, paw=1.15)
            for k in (-1, 0, 1):
                cone(m, COPPER, (s * 0.32 + k * 0.07, y - 0.15, 0.06), (s * 0.32 + k * 0.08, y - 0.24, 0.04), 0.03, seg=4, part="AccentCopper")
        for k, (dx, dz, r) in enumerate(((0.55, 0.45, 0.42), (1.05, 0.7, 0.32), (0.85, 0.1, 0.26))):
            c = Vector((s * dx, 0.35 + k * 0.08, 1.35 + dz))
            gearwheel(m, BRASS if k != 1 else COPPER, TEALM, c, r, normal=(0, 1, 0), teeth=7, part="Accent" if k != 1 else "AccentCopper", hub_part="Body", thick=0.06)
        vtube(m, COPPER, [(s * 0.35, 0.35, 1.35), (s * 0.55, 0.35, 1.78)], [0.04, 0.04], seg=5, part="AccentCopper", smooth=1)
        sn.put(m, P("1E5A55"), s * 25, 30, (0.035, 0.02, 0.025), "Nose", off=0.01)
    vtube(m, B, [(0, 1.05, 0.95), (0.2, 1.45, 0.85), (0.5, 1.6, 0.6), (0.7, 1.45, 0.45)], [0.18, 0.13, 0.09, 0.05], seg=8)
    disc(m, BRASS, [(-0.12, 0), (0, 0.16), (0.12, 0), (0, -0.16)], 0.05, (0.72, 1.45, 0.45), normal=(1, 0, 0.3), part="Accent")
    disc(m, BRASS, [(math.cos(a) * 0.2, math.sin(a) * 0.2) for a in [2 * math.pi * i / 16 for i in range(16)]], 0.04, (0, -0.48, 1.08), normal=(0, -1, 0.35), part="Accent")
    disc(m, GL, [(math.cos(a) * 0.16, math.sin(a) * 0.16) for a in [2 * math.pi * i / 16 for i in range(16)]], 0.04, (0, -0.5, 1.09), normal=(0, -1, 0.35), part="Glow")
    vtube(m, P("3A2A20"), [(0, -0.54, 1.11), (0.0, -0.57, 1.22)], [0.018, 0.012], seg=4, part="MarkHands", smooth=1)
    vtube(m, P("3A2A20"), [(0, -0.54, 1.11), (0.08, -0.56, 1.1)], [0.018, 0.012], seg=4, part="MarkHands", smooth=1)
    eyes(m, h, 30, 10, rx=0.12, rz=0.15)
    mouth(m, sn, -22, w=22, kind="smile", sag=8)
    blush(m, h, 54, -8, 0.08)
    return {}



