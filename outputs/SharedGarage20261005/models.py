# models.py - Shared Garage lobby models (Claude, 2026-10-05). One builder per model; each takes a w2lib.Model.
# 1 unit = 1 stud, front = -Y, up = +Z, model origin = placement point (floor-level centre).
import sys, math, random
from mathutils import Vector, Matrix
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\PlowExpansion20261005\parts")
import w2lib as L
from w2lib import P, Mx, sphere, rbox, cyl, lathe, tube, torus, prism, rock, island_se, turf_se, se_point
import partlib as PL
from partlib import beam, rod, flat, disc, mesh, gear_poly, arch_poly, crystal, box_m, frame

SNOW = "F6FAFF"; ICE = "9FD8FF"; ICE2 = "57D8FF"; RED = "E2483D"; ORA = "F2A23D"; YEL = "FFD23A"; STEEL = "3B3F4A"
WOOD = "E09A5A"; WOOD2 = "A9622F"; CREAM = "FFF3D6"; SILVER = "C9D2DE"; BULB = "FFE3A0"; WHITE = "F2F4F7"
ROCK = "7F92AC"; ICEBAND = "A9CBE8"; GREEN = "2F9E62"; BARK = "8A5530"; GLOW = "FF9A3D"


def bx(m, part, col, x0, x1, y0, y1, z0, z1, r=0.15, bseg=1, mat="SP", rot=(0, 0, 0)):
    rbox(m, P(col, mat), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), r=r, bseg=bseg, part=part, rot=rot)


def snowcap(m, x0, x1, y0, y1, z, t=0.4, ov=0.12, part="Snow"):
    bx(m, part, SNOW, x0 - ov, x1 + ov, y0 - ov, y1 + ov, z - 0.05, z + t, r=min(0.2, t * 0.45), bseg=2)


def sector(m, pc, c, R0, R1, a0, a1, z0, z1, seg=8, part="Main"):
    verts, faces = [], []
    for i in range(seg + 1):
        a = math.radians(a0 + (a1 - a0) * i / seg); ca, sa = math.cos(a), math.sin(a)
        for R in (R0, R1):
            for z in (z0, z1): verts.append((c[0] + R * ca, c[1] + R * sa, z))
    for i in range(seg):
        a, b = i * 4, (i + 1) * 4
        faces += [(a + 1, b + 1, b + 3, a + 3), (a + 0, a + 2, b + 2, b + 0), (a + 2, a + 3, b + 3, b + 2), (a + 0, b + 0, b + 1, a + 1)]
    faces += [(0, 1, 3, 2), (seg * 4 + 0, seg * 4 + 2, seg * 4 + 3, seg * 4 + 1)]
    mesh(m, pc, verts, faces, part=part)


def ring(m, pc, c, R0, R1, z0, z1, seg=32, part="Main"):
    verts, faces = [], []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        for R in (R0, R1):
            for z in (z0, z1): verts.append((c[0] + R * math.cos(a), c[1] + R * math.sin(a), z))
    for i in range(seg):
        a, b = i * 4, ((i + 1) % seg) * 4
        faces += [(a + 1, b + 1, b + 3, a + 3), (a + 0, a + 2, b + 2, b + 0), (a + 2, a + 3, b + 3, b + 2), (a + 0, b + 0, b + 1, a + 1)]
    mesh(m, pc, verts, faces, part=part)


def lamp_post(m, x, y):
    """Warm street lamp, height ~7 (shared by GarageStreet and GarageLampPost)."""
    bx(m, "Steel", STEEL, x - 0.5, x + 0.5, y - 0.5, y + 0.5, 0, 0.5, r=0.12)
    cyl(m, P(STEEL), (x, y, 0.5), r=0.22, h=5.4, seg=10, part="Steel")
    for z in (1.3, 4.9):
        cyl(m, P(RED), (x, y, z), r=0.3, h=0.3, seg=10, bev=0.06, bseg=1, part="Red")
    cyl(m, P(ORA), (x, y, 5.8), r=0.32, r2=0.58, h=0.32, seg=10, part="Orange")
    sphere(m, P(BULB, "NE"), (x, y, 6.36), 0.4, seg=10, rings=6, part="LampBulb")
    cyl(m, P(ORA), (x, y, 6.6), r=0.78, r2=0.16, h=0.36, seg=10, part="Orange")
    cyl(m, P(SNOW), (x, y, 6.68), r=0.66, r2=0.06, h=0.38, seg=10, part="Snow")
    for a in (0, 120, 240):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        rod(m, P(STEEL), (x + ca * 0.5, y + sa * 0.5, 6.1), (x + ca * 0.62, y + sa * 0.62, 6.66), r=0.05, seg=4, part="Steel")


# ------------------------------------------------------------------ 1. GarageBay
def GarageBay(m):
    bx(m, "Floor", "CCD5E0", -16, 16, -15, 15, -1.2, 0, r=0.08)
    z0, z1 = -0.03, 0.02   # flush floor paint (top 0.02 above the floor, not a step)
    for sx in (-1, 1):
        bx(m, "Ice", ICE, *sorted((sx * 14.2, sx * 14.8)), -14.2, 13.6, z0, z1, r=0)
    bx(m, "Ice", ICE, -14.8, 14.8, 13.0, 13.6, z0, z1, r=0)
    bx(m, "Yellow", YEL, -14.6, 14.6, -14.9, -14.3, z0, z1, r=0)          # front hazard line
    ring(m, P(ICE2), (0, 4), 7.8, 8.3, z0, z1, seg=40, part="Ice2")       # turntable parking ring
    # corner posts (front and back) with steel footings
    for sx in (-1, 1):
        for y in (-14.6, 14.4):
            bx(m, "Red", RED, *sorted((sx * 14.8, sx * 16.0)), y - 0.6, y + 0.6, 0, 11.0, r=0.25)
            bx(m, "Steel", STEEL, *sorted((sx * 14.6, sx * 16.0)), y - 0.7, y + 0.7, 0, 0.55, r=0.12)
    # header beam, sign, back beam
    bx(m, "Orange", ORA, -16, 16, -15.1, -13.9, 10.0, 11.6, r=0.3, bseg=2)
    bx(m, "Ice2", ICE2, -14.8, 14.8, -15.15, -13.85, 9.72, 10.08, r=0.1)
    bx(m, "Snow", SNOW, -16, 16, -15.2, -13.8, 11.5, 12.0, r=0.2, bseg=2)
    bx(m, "Red", RED, -3.3, 3.3, -15.22, -15.06, 9.45, 12.15, r=0.1)
    bx(m, "Sign", CREAM, -3.0, 3.0, -15.3, -15.18, 9.7, 11.9, r=0.05)
    bx(m, "Orange", ORA, -16, 16, 13.8, 15.0, 10.0, 11.2, r=0.25)
    # back wall (low) with window strip
    bx(m, "Wood", WOOD, -14.8, 14.8, 14.2, 15.0, 0, 3.0, r=0.12)
    bx(m, "Wood", WOOD, -14.8, 14.8, 14.2, 15.0, 5.45, 6.0, r=0.12)
    bx(m, "Trim", WHITE, -14.9, 14.9, 14.05, 15.0, 2.9, 3.2, r=0.08)
    bx(m, "Trim", WHITE, -14.9, 14.9, 14.15, 15.0, 5.2, 5.5, r=0.08)
    for x in (-10, -5, 0, 5, 10):
        bx(m, "Trim", WHITE, x - 0.16, x + 0.16, 14.3, 14.9, 3.2, 5.2, r=0.05)
    bx(m, "Glass", "BFE8FF", -14.8, 14.8, 14.52, 14.68, 3.2, 5.2, r=0, mat="GL")
    bx(m, "Snow", SNOW, -14.85, 14.85, 14.1, 15.0, 5.95, 6.35, r=0.18, bseg=2)
    # side dividers (low, open)
    for sx in (-1, 1):
        x = sx * 15.8   # just outside the reserve pedestal edge (x=15.6)
        for y in ((-7.5, 0, 7.5) if sx < 0 else (-11.0, 1.5, 8.0)):
            bx(m, "Yellow", YEL, x - 0.19, x + 0.19, y - 0.3, y + 0.3, 0, 3.15, r=0.1)
        bx(m, "Yellow", YEL, x - 0.18, x + 0.18, -14.0, 13.8, 2.7, 3.1, r=0.1)
        bx(m, "Red", RED, x - 0.13, x + 0.13, -14.0, 13.8, 1.5, 1.8, r=0.07)
        bx(m, "Ice", ICE, x - 0.1, x + 0.1, -14.0, 13.8, 0, 0.7, r=0.05)
        bx(m, "Snow", SNOW, x - 0.2, x + 0.2, -14.0, 13.8, 3.08, 3.3, r=0.1, bseg=2)
    # roof frame: rafters along Y, purlins along X, one snowy back roof panel, rest open
    for x in (-15.4, -7.7, 0, 7.7, 15.4):
        bx(m, "Steel", STEEL, x - 0.4, x + 0.4, -13.9, 13.8, 10.15, 11.0, r=0.12)
        bx(m, "Snow", SNOW, x - 0.45, x + 0.45, -13.8, 6.9, 10.98, 11.22, r=0.1, bseg=2)
    for y in (-6.0, 0.8):
        bx(m, "Yellow", YEL, -15.4, 15.4, y - 0.3, y + 0.3, 11.0, 11.5, r=0.1)
        bx(m, "Snow", SNOW, -15.4, 15.4, y - 0.34, y + 0.34, 11.48, 11.7, r=0.1, bseg=2)
    bx(m, "Ice", ICE, -16, 16, 6.8, 15.0, 11.05, 11.4, r=0.12)
    bx(m, "Snow", SNOW, -15.9, 15.9, 7.0, 14.9, 11.35, 11.8, r=0.2, bseg=2)
    for i in range(13):
        x = -15 + i * 2.5
        sphere(m, P(SNOW), (x, 7.05, 11.55), 0.42, scl=(1.3, 1, 0.7), seg=6, rings=4, part="Snow")
    # 2 warm hanging lamps under the rafters at x=+-7.7
    for x in (-7.7, 7.7):
        rod(m, P(STEEL), (x, -2, 10.15), (x, -2, 9.3), r=0.07, seg=6, part="Steel")
        cyl(m, P(STEEL), (x, -2, 9.2), r=0.28, h=0.2, seg=8, part="Steel")
        cyl(m, P(ORA), (x, -2, 8.6), r=1.0, r2=0.36, h=0.62, seg=12, part="Orange")
        sphere(m, P(BULB, "NE"), (x, -2, 8.6), 0.36, seg=10, rings=6, part="LampBulb")
    # tool wall rack (pegboard on the back wall) with wrenches and hammers
    bx(m, "Steel", STEEL, -10.0, -3.0, 13.95, 14.2, 0.9, 2.85, r=0.06)
    for x in (-9.3, -8.5, -7.7):
        bx(m, "Silver", SILVER, x - 0.11, x + 0.11, 13.82, 13.95, 1.15, 2.15, r=0.04)
        torus(m, P(SILVER), (x, 13.88, 2.35), R=0.24, r=0.08, seg=8, rseg=4, rot=(90, 0, 0), part="Silver")
    for x in (-6.4, -5.5):
        bx(m, "Red", RED, x - 0.1, x + 0.1, 13.82, 13.95, 1.1, 2.25, r=0.04)
        bx(m, "Silver", SILVER, x - 0.38, x + 0.38, 13.78, 13.95, 2.2, 2.5, r=0.05)
    bx(m, "Yellow", YEL, -4.6, -3.4, 13.82, 13.95, 1.2, 2.5, r=0.08)        # big yellow spanner
    torus(m, P(YEL), (-4.0, 13.86, 2.62), R=0.4, r=0.12, seg=8, rseg=4, rot=(90, 0, 0), part="Yellow")
    # red tool chest + parts crate against the back wall (y > 12)
    bx(m, "Red", RED, 3.0, 5.2, 12.8, 14.0, 0, 2.6, r=0.15)
    for z in (0.6, 1.2, 1.8, 2.3):
        bx(m, "Silver", SILVER, 3.6, 4.6, 12.68, 12.82, z - 0.07, z + 0.07, r=0.03)
    bx(m, "Wood2", WOOD2, 7.9, 10.1, 12.3, 13.9, 0, 1.4, r=0.12)
    for z in (0.35, 1.05):
        bx(m, "Wood", WOOD, 7.85, 10.15, 12.25, 13.95, z - 0.12, z + 0.12, r=0.05)
    prism(m, P(YEL), gear_poly(8, 0.55, 0.42), 0.18, loc=(8.6, 13.1, 1.4), part="Yellow")
    prism(m, P(SILVER), gear_poly(8, 0.45, 0.34), 0.18, loc=(9.5, 12.9, 1.4), part="Silver")


# ------------------------------------------------------------------ 2. GarageStreet
def GarageStreet(m):
    bx(m, "Slab", "A9C2DA", -16, 16, -15, 15, -1.2, 0, r=0.08)
    for i in range(8):
        for j in range(6):
            x = -14 + 4 * i; y = -10 + 4 * j
            col = ICE if (i + j) % 2 == 0 else "D3ECFB"
            bx(m, "PaverA" if (i + j) % 2 == 0 else "PaverB", col, x - 1.85, x + 1.85, y - 1.85, y + 1.85, -0.03, 0.02, r=0)
    # snowy edges (flush) with a wavy inner boundary
    wav = [(x * 0.5 - 16, 12.6 + 0.4 * math.sin((x * 0.5 - 16) * 0.8)) for x in range(65)]
    prism(m, P(SNOW), wav + [(16, 15), (-16, 15)], 0.05, loc=(0, 0, -0.03), part="Snow")
    wav2 = [(x, -y) for x, y in reversed(wav)]
    prism(m, P(SNOW), wav2 + [(-16, -15), (16, -15)], 0.05, loc=(0, 0, -0.03), part="Snow")
    lamp_post(m, 15.0, -13.6)


# ------------------------------------------------------------------ 3. GarageIsland + GarageAnnexSlab
def _icicle(m, x, y, z, h, r, part="Icicles"):
    cyl(m, P("CFEFFF"), (x, y, z + 0.05), r=r, r2=0.02, h=h, seg=6, rot=(180, 0, 0), part=part)


def GarageIsland(m):
    A, Bb, N, TOP = 76.0, 50.0, 6.0, -0.05
    turf_se(m, P(SNOW), a=A, b=Bb, n=N, thick=1.6, seg=72, part="Snow", top=TOP)
    island_se(m, P(ICEBAND), a=A - 0.4, b=Bb - 0.4, depth=8.0, n=N, seed=3, seg=64, rings=2, jag=0.06, part="IceBand", top=-1.6)
    island_se(m, P(ROCK), a=A - 1.4, b=Bb - 1.4, depth=43.4, n=N, seed=7, seg=56, rings=7, jag=0.13, part="Rock", top=-1.6)
    m.flat("Rock", P(ROCK), 1)
    rnd = random.Random(11)
    # rock ledges on the cliff sides
    for i in range(34):
        ang = 2 * math.pi * (i + rnd.uniform(-0.3, 0.3)) / 34
        t = rnd.uniform(0.08, 0.35)
        z = -1.6 - 43.4 * t ** 1.2
        f = (1 - t) ** 0.75 * 0.97
        x, y = se_point(A - 1.4, Bb - 1.4, ang, max(2.0, N - t * 7 * 0.6))
        s = rnd.uniform(3.0, 6.0)
        rock(m, P(ROCK), (x * f, y * f, z), (s, s * 0.9, s * 0.7), seed=i, sub=1, jag=0.2, part="Rock")
    # icicles under the snow lip
    for i in range(72):
        ang = 2 * math.pi * (i + 0.5) / 72
        x, y = se_point(A - 0.6, Bb - 0.6, ang, N)
        _icicle(m, x, y, -1.6, rnd.uniform(1.6, 3.6), rnd.uniform(0.35, 0.6))
    # icy crystals hanging from the underside
    for i in range(12):
        ang = 2 * math.pi * (i + rnd.uniform(0, 0.6)) / 12
        t = rnd.uniform(0.25, 0.6); z = -1.6 - 43.4 * t ** 1.2; f = (1 - t) ** 0.75
        x, y = se_point(A - 1.4, Bb - 1.4, ang, max(2.0, N - t * 7 * 0.6))
        base = Vector((x * f * 0.85, y * f * 0.85, z))
        out = Vector((x, y, 0)).normalized()
        crystal(m, P(ICE2), base, base + out * rnd.uniform(4, 7) + Vector((0, 0, -rnd.uniform(3, 6))), rnd.uniform(1.0, 1.6), part="Crystal")
    # snow drifts along the rim (only near the outer edge, well outside the building area)
    for i in range(40):
        ang = 2 * math.pi * (i + rnd.uniform(-0.25, 0.25)) / 40
        x, y = se_point(A - 0.3, Bb - 0.3, ang, N)
        r = rnd.uniform(2.0, 2.8)
        if abs(x) - r < 65.5 and abs(y) - r < 46.5:   # corner drift would touch the bay rows: skip it
            continue
        sphere(m, P(SNOW), (x, y, -0.75), r, scl=(1, 1, 0.42), seg=10, rings=5, part="Snow")


def GarageAnnexSlab(m):
    bx(m, "Snow", SNOW, -16, 16, -30, 30, -1.65, -0.05, r=0.3, bseg=2)
    island_se(m, P(ICEBAND), a=15.7, b=29.7, depth=4.0, n=5, seed=5, seg=40, rings=1, jag=0.04, part="IceBand", top=-1.6)
    island_se(m, P(ROCK), a=15.2, b=29.2, depth=16.4, n=4, seed=9, seg=40, rings=5, jag=0.12, part="Rock", top=-1.6)
    m.flat("Rock", P(ROCK), 1)
    rnd = random.Random(21)
    for i in range(12):
        ang = 2 * math.pi * (i + rnd.uniform(-0.3, 0.3)) / 12
        t = rnd.uniform(0.1, 0.35); z = -1.6 - 16.4 * t ** 1.2; f = (1 - t) ** 0.75 * 0.95
        x, y = se_point(15.2, 29.2, ang, max(2.0, 4 - t * 5 * 0.6))
        s = rnd.uniform(2.0, 3.4)
        rock(m, P(ROCK), (x * f, y * f, z), (s, s * 0.9, s * 0.7), seed=40 + i, sub=1, jag=0.2, part="Rock")
    for i in range(28):
        ang = 2 * math.pi * (i + 0.5) / 28
        x, y = se_point(15.6, 29.6, ang, 6)
        _icicle(m, x, y, -1.6, rnd.uniform(1.2, 2.6), rnd.uniform(0.3, 0.5))


# ------------------------------------------------------------------ 4. PlazaLandmark (warm stove + gear clock + bench ring)
def PlazaLandmark(m):
    lathe(m, P(ICE), [(4.4, 0), (4.45, 0.35), (0, 0.35)], seg=28, part="Plinth")
    lathe(m, P(SNOW), [(4.25, 0.3), (4.2, 0.52), (3.9, 0.62), (0, 0.62)], seg=28, part="Snow")
    for k in range(4):
        a = math.radians(45 + 90 * k)
        cyl(m, P(STEEL), (1.7 * math.cos(a), 1.7 * math.sin(a), 0.55), r=0.38, r2=0.28, h=0.55, seg=8, part="Steel")
    lathe(m, P(STEEL), [(0, 1.0), (2.0, 1.0), (2.5, 1.3), (2.65, 2.4), (2.55, 3.4), (2.1, 4.0), (1.0, 4.4), (0.65, 4.5)], seg=22, part="Stove")
    torus(m, P(ORA), (0, 0, 2.3), R=2.68, r=0.14, seg=22, rseg=6, part="Orange")
    torus(m, P(ORA), (0, 0, 3.55), R=2.45, r=0.13, seg=22, rseg=6, part="Orange")
    torus(m, P(ORA), (0, 0, 1.22), R=2.35, r=0.12, seg=22, rseg=6, part="Orange")
    for sy in (-1, 1):
        bx(m, "Orange", ORA, -0.95, 0.95, *sorted((sy * 2.45, sy * 2.75)), 1.5, 2.95, r=0.12)
        bx(m, "Glow", GLOW, -0.68, 0.68, *sorted((sy * 2.6, sy * 2.82)), 1.72, 2.72, r=0.08, mat="NE")
    cyl(m, P(STEEL), (0, 0, 4.4), r=0.6, h=9.5, seg=12, part="Stove")
    for z in (6.2, 13.2):
        cyl(m, P(ORA), (0, 0, z), r=0.72, h=0.3, seg=12, bev=0.06, bseg=1, part="Orange")
    for sx in (-1, 1):
        beam(m, P(ORA), (sx * 1.9, 0, 3.85), (sx * 1.05, 0, 8.45), w=0.34, h=0.34, r=0.08, part="Orange")
    # gear clock (faces -Y and +Y)
    flat(m, P(YEL), gear_poly(14, 2.95, 2.5, frac=0.5), 0.8, (0, 0.4, 11.0), axis=(0, -1, 0), part="Gear")
    for sy in (-1, 1):
        disc(m, P(CREAM), (0, sy * 0.4, 11.0), 2.1, 0.12, axis=(0, sy, 0), seg=24, part="Face")
        for k in range(12):
            a = 2 * math.pi * k / 12; L_ = 0.34 if k % 3 == 0 else 0.18
            p = Vector((math.sin(a) * 1.75, sy * 0.53, 11.0 + math.cos(a) * 1.75))
            d = Vector((math.sin(a), 0, math.cos(a)))
            beam(m, P(STEEL), p - d * L_ / 2, p + d * L_ / 2, w=0.14, h=0.06, r=0.0, part="Steel", up=(0, 1, 0))
        yy = sy * 0.58
        beam(m, P(STEEL), (0, yy, 11.0), (0, yy, 12.55), w=0.2, h=0.08, r=0.0, part="Steel", up=(0, 1, 0))
        beam(m, P(STEEL), (0, yy, 11.0), (sy * 0.9, yy, 11.55), w=0.26, h=0.08, r=0.0, part="Steel", up=(0, 1, 0))
        disc(m, P(RED), (0, sy * 0.52, 11.0), 0.3, 0.16, axis=(0, sy, 0), seg=10, part="Red")
    # chimney cap, snow, lantern finial
    cyl(m, P(ORA), (0, 0, 13.9), r=0.95, h=0.45, seg=12, bev=0.1, bseg=1, part="Orange")
    cyl(m, P(SNOW), (0, 0, 14.3), r=0.9, h=0.28, seg=12, bev=0.1, bseg=1, part="Snow")
    rod(m, P(STEEL), (0, 0, 14.5), (0, 0, 15.0), r=0.12, seg=6, part="Steel")
    sphere(m, P(BULB, "NE"), (0, 0, 15.25), 0.42, seg=10, rings=6, part="LampBulb")
    cyl(m, P(ORA), (0, 0, 15.55), r=0.6, r2=0.1, h=0.35, seg=10, part="Orange")
    # ring of 4 curved benches (outer radius 7.5; entrances on the 4 axes)
    for k in range(4):
        c = 45 + 90 * k; a0, a1 = c - 28, c + 28
        for (r0, r1) in ((6.0, 6.55), (6.62, 7.15)):
            sector(m, P(WOOD), (0, 0), r0, r1, a0, a1, 1.15, 1.42, seg=6, part="Wood")
        for z in (1.6, 2.15):
            sector(m, P(WOOD2), (0, 0), 7.18, 7.45, a0, a1, z, z + 0.38, seg=6, part="Wood2")
        sector(m, P(SNOW), (0, 0), 7.12, 7.5, a0 + 4, a1 - 6, 2.53, 2.72, seg=5, part="Snow")
        for a in (a0 + 4, c, a1 - 4):
            ar = math.radians(a); ca, sa = math.cos(ar), math.sin(ar)
            rbox(m, P(STEEL), (6.6 * ca, 6.6 * sa, 0.57), (1.25, 0.26, 1.14), r=0.06, bseg=1, rot=(0, 0, a), part="Steel")
            rbox(m, P(STEEL), (7.3 * ca, 7.3 * sa, 1.9), (0.18, 0.26, 1.3), r=0.04, bseg=1, rot=(0, 0, a), part="Steel")


# ------------------------------------------------------------------ 5. ReturnPortal
def ReturnPortal(m):
    bx(m, "Base", "BFE6FF", -5, 5, -2, 2, 0, 0.4, r=0.15)
    for sx in (-1, 1):
        bx(m, "Ice", ICE, *sorted((sx * 3.2, sx * 4.8)), -1.2, 1.2, 0.3, 6.45, r=0.2)
        bx(m, "Ice2", ICE2, *sorted((sx * 3.05, sx * 4.95)), -1.35, 1.35, 0.35, 1.1, r=0.15)
        bx(m, "Ice2", ICE2, *sorted((sx * 3.1, sx * 4.9)), -1.3, 1.3, 5.6, 6.0, r=0.1)
        b = Vector((sx * 4.7, -1.55, 0.4))
        crystal(m, P(ICE2), b, b + Vector((sx * 0.5, -0.2, 1.8)), 0.38, part="Ice2")
        crystal(m, P(ICE2), b + Vector((0, 0.6, 0)), b + Vector((sx * 0.7, 0.5, 1.1)), 0.28, part="Ice2")
        for sy in (-1, 1):
            sphere(m, P(SNOW), (sx * 4.55, sy * 1.6, 0.38), 0.55, scl=(1.1, 0.9, 0.5), seg=8, rings=5, part="Snow")
    torus(m, P(ICE), (0, 0, 6.4), R=4.0, r=1.2, sq=0.667, seg=18, rseg=8, rot=(90, 0, 0), arc=180, part="Ice")
    for sy in (-1, 1):
        torus(m, P(ICE2), (0, sy * 1.22, 6.4), R=4.0, r=0.17, seg=18, rseg=5, rot=(90, 0, 0), arc=180, part="Ice2")
    torus(m, P(SNOW), (0, 0, 6.4), R=4.55, r=0.62, sq=0.8, seg=14, rseg=7, rot=(90, -28, 0), arc=124, part="Snow")
    for a in (28, 152):
        ar = math.radians(a)
        sphere(m, P(SNOW), (4.55 * math.cos(ar), 0, 6.4 + 4.55 * math.sin(ar)), 0.62, seg=8, rings=5, part="Snow")
    # glowing disc + swirl line
    flat(m, P(ICE2, "NE", 0.15), arch_poly(6.3, 9.15, n=10), 0.16, (0, 0.08, 0.4), axis=(0, -1, 0), part="Swirl")
    for sy in (-1, 1):
        pts = []
        for i in range(44):
            t = i / 43; a = t * 2.3 * 2 * math.pi * (-sy)
            r = 0.25 + 2.55 * t
            pts.append((math.cos(a) * r, sy * 0.13, 5.0 + math.sin(a) * r))
        tube(m, P("EAFBFF", "NE"), pts, r=0.11, seg=5, smooth=1, part="SwirlLine")


# ------------------------------------------------------------------ 6. Props
def GaragePineTree(m):
    cyl(m, P(BARK), (0, 0, 0), r=0.5, r2=0.42, h=1.6, seg=8, part="Bark")
    sphere(m, P(SNOW), (0, 0, 0), 1.9, scl=(1, 1, 0.28), seg=12, rings=6, part="Snow")
    for (r, zb, h) in ((3.0, 1.1, 3.2), (2.4, 3.0, 2.9), (1.8, 4.9, 2.6), (1.15, 6.7, 2.3)):
        cyl(m, P(GREEN), (0, 0, zb), r=r, r2=0.12, h=h, seg=10, part="Needles")
        zs = zb + h * 0.45; ra = r * 0.55 + 0.12 * 0.45
        cyl(m, P(SNOW), (0, 0, zs - 0.02), r=ra * 1.08, r2=0.05, h=h * 0.55 + 0.1, seg=10, part="Snow")
        for k in range(6):
            a = 2 * math.pi * (k + 0.5 * (zb > 3)) / 6
            sphere(m, P(SNOW), (math.cos(a) * ra * 1.0, math.sin(a) * ra * 1.0, zs + 0.02), 0.26 + 0.05 * r, scl=(1, 1, 0.8), seg=6, rings=4, part="Snow")


def _crate(m, x, y, z, s, rot, part="Wood", band="Wood2"):
    rbox(m, P(WOOD), (x, y, z + s / 2), (s, s, s), r=0.12, bseg=1, rot=(0, 0, rot), part=part)
    for zz in (z + 0.22, z + s - 0.22):
        rbox(m, P(WOOD2), (x, y, zz), (s + 0.08, s + 0.08, 0.24), r=0.05, bseg=1, rot=(0, 0, rot), part=band)
    rbox(m, P(WOOD2), (x, y, z + s / 2), (s + 0.08, 0.3, s - 0.3), r=0.05, bseg=1, rot=(0, 0, rot), part=band)


def GarageCrateStack(m):
    _crate(m, -1.3, 0.1, 0, 2.4, 4)
    _crate(m, 1.3, 0.3, 0, 2.4, -8)
    _crate(m, -0.1, 0.15, 2.4, 2.2, -14)
    rbox(m, P(ICE2), (0.4, -2.0, 0.75), (1.5, 1.5, 1.5), r=0.12, bseg=1, rot=(0, 0, 18), part="Blue")
    rbox(m, P(WHITE), (0.4, -2.0, 0.75), (1.58, 1.58, 0.22), r=0.05, bseg=1, rot=(0, 0, 18), part="BlueBand")
    rbox(m, P(SNOW), (-0.1, 0.15, 4.72), (2.25, 2.25, 0.32), r=0.14, bseg=2, rot=(0, 0, -14), part="Snow")
    rbox(m, P(SNOW), (1.75, 0.3, 2.47), (1.4, 2.3, 0.22), r=0.1, bseg=2, rot=(0, 0, -8), part="Snow")
    rbox(m, P(SNOW), (-2.05, 0.1, 2.47), (0.9, 2.3, 0.22), r=0.1, bseg=2, rot=(0, 0, 4), part="Snow")
    rbox(m, P(SNOW), (0.4, -2.0, 1.56), (1.45, 1.45, 0.2), r=0.08, bseg=2, rot=(0, 0, 18), part="Snow")
    sphere(m, P(SNOW), (-0.5, 0.3, 4.85), 0.6, scl=(1.2, 1, 0.55), seg=8, rings=5, part="Snow")


def GarageOilDrums(m):
    for (x, y, col, h) in ((-1.0, -0.3, RED, 2.5), (0.95, -0.55, YEL, 2.5), (0.05, 1.15, ICE2, 2.5)):
        cyl(m, P(col), (x, y, 0), r=0.85, h=h, seg=14, bev=0.08, bseg=1, part="Drum" + col)
        for z in (0.75, 1.75):
            torus(m, P(STEEL), (x, y, z), R=0.87, r=0.07, seg=14, rseg=4, part="Steel")
        torus(m, P(STEEL), (x, y, h - 0.05), R=0.8, r=0.08, seg=14, rseg=4, part="Steel")
        cyl(m, P(SNOW), (x, y, h - 0.02), r=0.74, h=0.2, seg=14, bev=0.08, bseg=1, part="Snow")
        sphere(m, P(SNOW), (x + 0.15, y - 0.1, h + 0.18), 0.4, scl=(1.2, 1, 0.5), seg=8, rings=5, part="Snow")
    cyl(m, P(STEEL), (1.6, 1.25, 0), r=0.42, r2=0.48, h=0.7, seg=10, part="Steel")
    sphere(m, P(SNOW), (1.6, 1.25, 0.7), 0.38, scl=(1, 1, 0.45), seg=8, rings=5, part="Snow")


def GarageToolCart(m):
    bx(m, "Red", RED, -1.3, 1.3, -0.7, 0.7, 0.5, 2.4, r=0.15)
    for z in (1.15, 1.75):
        bx(m, "Steel", STEEL, -1.2, 1.2, -0.74, -0.68, z - 0.03, z + 0.03, r=0)
    for z in (0.85, 1.45, 2.05):
        bx(m, "Silver", SILVER, -0.45, 0.45, -0.82, -0.7, z - 0.07, z + 0.07, r=0.03)
    bx(m, "Steel", STEEL, -1.42, 1.42, -0.82, 0.82, 2.4, 2.56, r=0.05)
    for sx in (-1, 1):
        bx(m, "Steel", STEEL, *sorted((sx * 1.42, sx * 1.34)), -0.82, 0.82, 2.56, 2.75, r=0.02)
    for sy in (-1, 1):
        bx(m, "Steel", STEEL, -1.42, 1.42, *sorted((sy * 0.82, sy * 0.74)), 2.56, 2.75, r=0.02)
    tube(m, P(SILVER), [(1.3, -0.55, 2.1), (1.85, -0.55, 2.1), (1.85, 0.55, 2.1), (1.3, 0.55, 2.1)], r=0.07, seg=6, smooth=1, part="Silver")
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 1.0, sy * 0.48
            bx(m, "Steel", STEEL, x - 0.12, x + 0.12, y - 0.12, y + 0.12, 0.38, 0.52, r=0.02)
            disc(m, P(STEEL), (x - 0.09, y, 0.25), 0.25, 0.18, axis=(1, 0, 0), seg=10, part="Steel")
    # items on top: spanner, oil can
    bx(m, "Silver", SILVER, -1.0, 0.2, -0.3, -0.12, 2.56, 2.66, r=0.03)
    torus(m, P(SILVER), (0.35, -0.21, 2.61), R=0.2, r=0.07, seg=8, rseg=4, part="Silver")
    cyl(m, P(YEL), (0.8, 0.25, 2.56), r=0.3, h=0.5, seg=10, bev=0.05, bseg=1, part="Yellow")
    rod(m, P(YEL), (0.8, 0.25, 3.0), (0.45, 0.1, 3.35), r=0.05, seg=5, part="Yellow")
    sphere(m, P(SNOW), (-0.9, 0.45, 2.62), 0.32, scl=(1.3, 1, 0.5), seg=8, rings=5, part="Snow")


def GarageLampPost(m):
    lamp_post(m, 0, 0)
    sphere(m, P(SNOW), (0, 0, 0), 1.0, scl=(1, 1, 0.3), seg=10, rings=5, part="Snow")


def GarageSnowPile(m):
    L.blob(m, P(SNOW), (0, 0, 0), rad=2.3, n=5, seed=2, spread=(1, 0.8, 0.35), flat=0.62, part="Snow")
    d = Vector((1.0, -0.55, 2.4)).normalized()
    p0 = Vector((0.75, -0.55, 1.0)); p1 = p0 + d * 2.6
    rod(m, P(WOOD), p0, p1, r=0.09, seg=6, part="Wood")
    rod(m, P(STEEL), p1 + Vector((-0.28, -0.12, 0.0)), p1 + Vector((0.28, 0.12, 0.0)), r=0.07, seg=6, part="Steel")
    box_m(m, P(RED), Matrix.Translation(p0 - d * 0.35) @ frame(d), (0.9, 0.1, 0.95), r=0.04, part="Red")
    for i, (x, y) in enumerate(((-2.0, -0.8), (-1.6, 1.0), (1.9, 0.9))):
        b = Vector((x, y, 0.1))
        crystal(m, P(ICE), b, b + Vector((x * 0.15, y * 0.15, 0.9 + 0.2 * i)), 0.3, part="Ice")


def GarageBench(m):
    c = (0, -6.0)
    for (r0, r1) in ((5.35, 5.75), (5.8, 6.2), (6.25, 6.62)):
        sector(m, P(WOOD), c, r0, r1, 65, 115, 1.05, 1.27, seg=6, part="Wood")
    for z in (1.55, 2.05):
        sector(m, P(WOOD), c, 6.55, 6.75, 65, 115, z, z + 0.32, seg=6, part="Wood")
    for a in (68, 90, 112):
        ar = math.radians(a); ca, sa = math.cos(ar), math.sin(ar)
        rbox(m, P(STEEL), (c[0] + 6.0 * ca, c[1] + 6.0 * sa, 0.52), (0.22, 1.3, 1.05), r=0.05, bseg=1, rot=(0, 0, a - 90), part="Steel")
        rbox(m, P(STEEL), (c[0] + 6.82 * ca, c[1] + 6.82 * sa, 1.65), (0.22, 0.16, 1.2), r=0.04, bseg=1, rot=(0, 0, a - 90), part="Steel")
    for a in (65.5, 114.5):
        ar = math.radians(a); ca, sa = math.cos(ar), math.sin(ar)
        rbox(m, P(STEEL), (c[0] + 6.05 * ca, c[1] + 6.05 * sa, 1.6), (0.2, 1.2, 0.14), r=0.04, bseg=1, rot=(0, 0, a - 90), part="Steel")
    sector(m, P(SNOW), c, 6.5, 6.8, 72, 104, 2.35, 2.5, seg=4, part="Snow")
    sphere(m, P(SNOW), (c[0] + 5.9 * math.cos(math.radians(108)), c[1] + 5.9 * math.sin(math.radians(108)), 1.3), 0.5, scl=(1.2, 1, 0.45), seg=8, rings=5, part="Snow")


def GarageHoistCrane(m):
    for sx in (-1, 1):
        x = sx * 2.6
        bx(m, "Steel", STEEL, x - 0.28, x + 0.28, -1.5, 1.5, 0.35, 0.75, r=0.08)
        for sy in (-1, 1):
            disc(m, P(STEEL), (x - 0.11, sy * 1.18, 0.3), 0.3, 0.22, axis=(1, 0, 0), seg=10, part="Steel")
            beam(m, P(YEL), (x, sy * 1.2, 0.7), (x, sy * 0.12, 7.25), w=0.36, h=0.36, r=0.08, part="Yellow")
        beam(m, P(STEEL), (x, -0.9, 2.4), (x, 0.9, 2.4), w=0.16, h=0.16, r=0.03, part="Steel")
        beam(m, P(STEEL), (x, -0.55, 4.6), (x, 0.55, 4.6), w=0.16, h=0.16, r=0.03, part="Steel")
        bx(m, "Red", RED, *sorted((sx * 2.95, sx * 3.0 - sx * 0.25)), -0.32, 0.32, 7.15, 7.9, r=0.06)
    bx(m, "Yellow", YEL, -2.8, 2.8, -0.3, 0.3, 7.2, 7.85, r=0.1)
    bx(m, "Steel", STEEL, -2.8, 2.8, -0.38, 0.38, 7.12, 7.24, r=0.03)
    bx(m, "Snow", SNOW, -2.9, 2.9, -0.36, 0.36, 7.82, 8.05, r=0.1, bseg=2)
    bx(m, "Steel", STEEL, 0.0, 1.2, -0.45, 0.45, 6.6, 7.1, r=0.08)
    rod(m, P(STEEL), (0.6, 0, 6.6), (0.6, 0, 3.4), r=0.06, seg=5, part="Steel")
    bx(m, "Red", RED, 0.3, 0.9, -0.25, 0.25, 2.75, 3.4, r=0.08)
    torus(m, P(STEEL), (0.6, 0, 2.38), R=0.3, r=0.08, seg=10, rseg=5, rot=(90, 0, 0), arc=280, part="Steel")
    bx(m, "Yellow", YEL, -0.5, -0.1, -0.31, 0.31, 7.25, 7.8, r=0.04)


BUILDERS = {f.__name__: f for f in (GarageBay, GarageStreet, GarageIsland, GarageAnnexSlab, PlazaLandmark, ReturnPortal,
                                     GaragePineTree, GarageCrateStack, GarageOilDrums, GarageToolCart, GarageLampPost,
                                     GarageSnowPile, GarageBench, GarageHoistCrane)}
