# Retro Egg: deliberate blocky arcade / voxel styling.
import math
from mathutils import Vector
from petkit import *
from species_reg import pet

def pair(f):
    for s in (-1, 1): f(s)

def pixmouth(m, y, z, u=0.06, pc=MOUTH, part="Mouth", wide=2):
    """Pixel 'w' mouth made of small cubes on the plane y (front)."""
    cells = [(-wide, 1), (-wide + 1, 0), (0, 1), (wide - 1, 0), (wide, 1)] if wide >= 2 else [(-1, 0), (0, 0), (1, 0)]
    for i, k in cells:
        cube(m, pc, (i * u, y - 0.012, z + k * u), (u, 0.05, u), part=part)

@pet("Pixel Cat")
def pixel_cat(m):
    B, BE, MK, INN = P("FF7DC4"), P("FFE1F0"), P("D9439A"), P("FFB6DD")
    cube(m, B, (0, -0.1, 1.38), (1.24, 1.0, 0.96))
    cube(m, B, (0, 0.14, 0.52), (0.82, 0.76, 0.72))
    cube(m, BE, (0, -0.25, 0.48), (0.5, 0.5, 0.5), part="Belly")
    for s in (-1, 1):
        cube(m, B, (s * 0.44, -0.08, 1.98), (0.34, 0.3, 0.26)); cube(m, B, (s * 0.5, -0.08, 2.17), (0.18, 0.2, 0.14))
        cube(m, INN, (s * 0.44, -0.24, 1.97), (0.18, 0.04, 0.16), part="Belly")
        for y in (-0.12, 0.38):
            cube(m, B, (s * 0.24, y, 0.11), (0.24, 0.26, 0.22))
        for k in range(3):
            cube(m, MK, (s * 0.63, -0.1, 1.5 - k * 0.15), (0.04, 0.6, 0.06), part="Mark")
    for k, c in enumerate([(0.0, 0.62, 0.5), (0.12, 0.74, 0.68), (0.2, 0.8, 0.88), (0.22, 0.78, 1.08), (0.16, 0.7, 1.24)]):
        cube(m, MK if k == 4 else B, c, (0.18, 0.18, 0.2), part="Mark" if k == 4 else "Body")
    for x in (-0.18, 0.0, 0.18):
        cube(m, MK, (x, -0.1, 1.87), (0.08, 0.6, 0.04), part="Mark")
    f = FlatFace((0, -0.1, 1.38), (0.62, 0.5, 0.48))
    sqeyes(m, f, 22, 8, w=0.2, hgt=0.26)
    cube(m, P("FF4FA0"), (0, -0.62, 1.26), (0.1, 0.05, 0.07), part="Nose")
    pixmouth(m, -0.6, 1.13, u=0.05)
    for s in (-1, 1): cube(m, BLUSH, (s * 0.4, -0.615, 1.2), (0.14, 0.03, 0.07), part="Blush")
    m.flat("Body", B, 30)

@pet("Arcade Bot")
def arcade_bot(m):
    B, MK, SCR, PIX, RED, YEL, GL = P("6A5BE2"), P("FF5FB4"), P("18213A"), P("6CFF9E"), P("FF4D5E"), P("FFD84A"), P("FFE27A", "NE")
    cube(m, B, (0, 0.05, 0.98), (1.06, 0.86, 1.02))
    box(m, B, (0, -0.02, 1.62), (1.1, 0.8, 0.3), r=0.05)
    cube(m, GL, (0, -0.42, 1.62), (0.8, 0.04, 0.16), part="Glow")
    cube(m, SCR, (0, -0.4, 1.12), (0.8, 0.06, 0.52), part="EyeScreen")
    for s in (-1, 1):
        cube(m, PIX, (s * 0.18, -0.445, 1.2), (0.1, 0.03, 0.16), part="Shine")
        cube(m, PIX, (s * 0.15, -0.445, 1.0), (0.06, 0.03, 0.05), part="Shine")
    cube(m, PIX, (0, -0.445, 0.97), (0.24, 0.03, 0.05), part="Shine")
    box(m, B, (0, -0.48, 0.66), (0.96, 0.36, 0.14), r=0.04, rot=(-14, 0, 0))
    vtube(m, P("2A2340"), [(-0.2, -0.52, 0.72), (-0.2, -0.54, 0.86)], [0.025, 0.025], seg=6, part="Accent", smooth=1)
    ell(m, RED, (-0.2, -0.54, 0.9), 0.06, part="Accent", seg=8)
    pair(lambda s: cyl(m, YEL, (0.12 + s * 0.1, -0.52, 0.71), r=0.04, h=0.04, seg=8, part="AccentButton", rot=(-14, 0, 0)))
    for s in (-1, 1):
        for k in range(3):
            cube(m, MK, (s * 0.535, 0.05 + (k - 1) * 0.22, 1.0 - k * 0.12), (0.03, 0.14, 0.32), part="Mark")
        cube(m, B, (s * 0.25, 0.05, 0.22), (0.26, 0.34, 0.44))
        cube(m, P("2A2340"), (s * 0.25, -0.02, 0.06), (0.32, 0.46, 0.12), part="Accent")
        vtube(m, P("2A2340"), [(s * 0.55, 0.0, 1.05), (s * 0.78, -0.08, 0.86)], [0.05, 0.05], seg=6, part="Accent", smooth=1)
        ell(m, B, (s * 0.82, -0.12, 0.8), 0.12, seg=8)
    vtube(m, P("2A2340"), [(0.3, 0.1, 1.76), (0.36, 0.12, 2.06)], [0.025, 0.025], seg=6, part="Accent", smooth=1)
    ell(m, RED, (0.36, 0.12, 2.1), 0.07, part="Accent", seg=8)
    m.flat("Body", B, 30)

@pet("Neon Frog")
def neon_frog(m):
    B, BE, MK, GL = P("5DEB6A"), P("DDFFA0"), P("2E9E54"), P("FF4FD8", "NE")
    cube(m, B, (0, -0.02, 0.5), (1.2, 1.0, 0.62))
    cube(m, BE, (0, -0.42, 0.4), (0.9, 0.3, 0.32), part="Belly")
    for s in (-1, 1):
        cube(m, B, (s * 0.36, -0.22, 0.98), (0.4, 0.42, 0.36))
        cube(m, B, (s * 0.62, 0.18, 0.28), (0.3, 0.6, 0.36))
        cube(m, B, (s * 0.72, -0.24, 0.07), (0.34, 0.3, 0.14))
        cube(m, B, (s * 0.38, -0.5, 0.16), (0.18, 0.18, 0.3))
        cube(m, B, (s * 0.38, -0.6, 0.05), (0.28, 0.24, 0.1))
    for c in ((-0.3, 0.1, 0.82), (0.25, 0.3, 0.82), (0.0, 0.0, 0.82), (-0.1, 0.36, 0.82)):
        cube(m, MK, c, (0.16, 0.16, 0.04), part="Mark")
    cube(m, GL, (0, 0.2, 0.83), (0.12, 0.6, 0.05), part="Glow")
    f = FlatFace((0, -0.22, 0.98), (0.36, 0.21, 0.18))
    sqeyes(m, f, 90, -4, w=0.24, hgt=0.26)
    cube(m, P("2A1F33"), (0, -0.525, 0.6), (0.8, 0.04, 0.05), part="Mouth")
    pair(lambda s: cube(m, P("2A1F33"), (s * 0.42, -0.525, 0.64), (0.06, 0.04, 0.1), part="Mouth"))
    pair(lambda s: cube(m, BLUSH, (s * 0.5, -0.52, 0.74), (0.14, 0.03, 0.07), part="Blush"))
    m.flat("Body", B, 30)
    return {"H": 2.0}

@pet("Synth Fox")
def synth_fox(m):
    B, BE, MK, HP, GL = P("3FD0F5"), P("FF5CC8"), P("7A3CF0"), P("2A2350"), P("FFB13D", "NE")
    box(m, B, (0, 0.2, 0.55), (0.75, 0.9, 0.62), r=0.06)
    box(m, BE, (0, -0.2, 0.62), (0.5, 0.2, 0.5), r=0.05, part="Belly")
    box(m, B, (0, -0.22, 1.32), (1.0, 0.8, 0.76), r=0.07)
    box(m, BE, (0, -0.72, 1.18), (0.44, 0.34, 0.3), r=0.05, part="Belly")
    for s in (-1, 1):
        b = Vector((s * 0.32, -0.2, 1.62))
        cone(m, B, b, b + Vector((s * 0.06, 0.0, 0.62)), 0.24, seg=4, part="Body")
        cone(m, MK, b + Vector((s * 0.04, -0.1, 0.48)), b + Vector((s * 0.06, -0.06, 0.66)), 0.08, seg=4, part="Mark")
        for y in (-0.06, 0.48):
            box(m, B, (s * 0.24, y, 0.14), (0.22, 0.24, 0.28), r=0.03)
        box(m, HP, (s * 0.52, -0.22, 1.36), (0.08, 0.34, 0.34), r=0.03, part="Accent")
    vtube(m, HP, [(-0.52, -0.22, 1.5), (-0.36, -0.2, 1.76), (0, -0.2, 1.79), (0.36, -0.2, 1.76), (0.52, -0.22, 1.5)], [0.04] * 5, seg=4, part="Accent", smooth=1)
    tail = [((0.1, 0.72, 0.55), (0.24, 0.3, 0.24)), ((0.22, 0.95, 0.75), (0.32, 0.34, 0.34)), ((0.3, 1.05, 1.08), (0.36, 0.36, 0.36)), ((0.32, 0.96, 1.42), (0.3, 0.3, 0.3))]
    for k, (c, sz) in enumerate(tail):
        box(m, B, c, sz, r=0.04)
        box(m, MK, (c[0], c[1], c[2] + sz[2] * 0.36), (sz[0] * 1.06, sz[1] * 1.06, sz[2] * 0.18), r=0.02, part="Mark")
    box(m, GL, (0.32, 0.92, 1.65), (0.2, 0.2, 0.2), r=0.03, part="Glow")
    f = FlatFace((0, -0.22, 1.32), (0.5, 0.4, 0.38))
    sqeyes(m, f, 26, 18, w=0.2, hgt=0.24)
    cube(m, P("2A1F33"), (0, -0.9, 1.26), (0.12, 0.05, 0.08), part="Nose")
    pixmouth(m, -0.89, 1.08, u=0.04)
    for s in (-1, 1): cube(m, P("FFFFFF"), (s * 0.34, -0.625, 1.12), (0.14, 0.03, 0.07), part="Blush")
    m.flat("Body", B, 30)

@pet("Glitch Dragon")
def glitch_dragon(m):
    B, BE, WG, CYN, GL = P("8E4CF0"), P("45F0DD"), P("FF4FB8"), P("45F0DD"), P("FFFFFF", "NE")
    cube(m, B, (0, 0.2, 0.72), (0.9, 0.86, 0.96))
    cube(m, BE, (0, -0.24, 0.66), (0.6, 0.06, 0.72), part="Belly")
    for k in range(3): cube(m, B, (0, -0.255, 0.42 + k * 0.24), (0.62, 0.04, 0.04))
    cube(m, B, (0, -0.25, 1.62), (1.0, 0.9, 0.84))
    cube(m, B, (0, -0.86, 1.48), (0.62, 0.42, 0.4))
    cube(m, CYN, (-0.53, -0.25, 1.75), (0.08, 0.7, 0.18), part="Mark")
    cube(m, WG, (0.53, -0.3, 1.45), (0.08, 0.6, 0.14), part="AccentWing")
    cube(m, B, (0.06, -0.25, 1.36), (1.06, 0.92, 0.1))
    for s in (-1, 1):
        cube(m, BE, (s * 0.3, -0.18, 2.12), (0.14, 0.14, 0.2), part="Belly"); cube(m, BE, (s * 0.34, -0.1, 2.28), (0.12, 0.12, 0.14), part="Belly")
        cube(m, BE, (s * 0.36, 0.0, 2.38), (0.1, 0.1, 0.1), part="Belly")
        for y in (-0.08, 0.5):
            cube(m, B, (s * 0.28, y, 0.13), (0.28, 0.32, 0.26))
        cube(m, B, (s * 0.38, -0.32, 0.9), (0.18, 0.3, 0.18))
        for i, (x, z, w, hh) in enumerate([(0.6, 1.25, 0.3, 0.5), (0.9, 1.45, 0.3, 0.5), (1.18, 1.62, 0.26, 0.5), (1.38, 1.85, 0.2, 0.3)]):
            cube(m, WG, (s * x, 0.42, z), (w, 0.08, hh), part="AccentWing")
        cube(m, WG, (s * 0.85, 0.42, 1.02), (0.24, 0.08, 0.2), part="AccentWing")
    for k, (y, z, sz) in enumerate([(0.75, 0.42, 0.34), (1.05, 0.34, 0.28), (1.3, 0.38, 0.22), (1.48, 0.5, 0.18), (1.6, 0.66, 0.14)]):
        cube(m, B, (0.06 * k, y, z), (sz, sz, sz))
    cube(m, WG, (0.34, 1.68, 0.84), (0.16, 0.16, 0.16), part="AccentWing")
    for c in ((-0.82, -0.6, 2.05), (0.75, 0.9, 1.0), (-0.66, 0.6, 0.35)):
        cube(m, CYN, c, (0.1, 0.1, 0.1), part="Mark")
    cube(m, GL, (0.7, -0.75, 2.12), (0.1, 0.1, 0.1), part="Glow")
    f = FlatFace((0, -0.25, 1.62), (0.5, 0.45, 0.42))
    sqeyes(m, f, 28, 20, w=0.2, hgt=0.26)
    for s in (-1, 1): cube(m, P("2A1F33"), (s * 0.14, -1.075, 1.58), (0.06, 0.03, 0.05), part="Nose")
    pixmouth(m, -1.075, 1.36, u=0.05)
    for s in (-1, 1): cube(m, BLUSH, (s * 0.38, -0.715, 1.36), (0.14, 0.03, 0.07), part="Blush")
    m.flat("Body", B, 30)
