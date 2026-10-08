# crystal.py - Icy crystal quarry (World 1 remaster, Claude 2026-10-05). Pale ice + slate with a few saturated crystal colours.
import math, random
from w1lib import *

SLATE = "5D6F8C"; SLATE2 = "4A5A74"; SLATE3 = "7487A6"; PALE = "CFEFFF"
CYAN = "54E3F0"; MAG = "E35BD6"; VIO = "9A6BFF"; PALEC = "BFF3FF"; TIMB = "8A5530"; TIMB2 = "6B4024"; RAIL = "5B5F6A"


def gem(m, base, tip, r, col, part="Crystal", glow=False):
    crystal(m, P(col, "NE" if glow else "GL", 0 if glow else 0.08), base, tip, r, seg=6, part=part)


def cluster(m, cx, cy, cz, s, rnd, cols=(CYAN, MAG, VIO, PALEC), part="Crystal", n=6):
    for k in range(n):
        a = 2 * math.pi * k / n + rnd.uniform(-0.4, 0.4)
        lean = rnd.uniform(0.15, 0.5)
        h = s * rnd.uniform(0.55, 1.0) * (1.4 if k == 0 else 1)
        bx_, by_ = cx + math.cos(a) * s * 0.18, cy + math.sin(a) * s * 0.18
        tip = (bx_ + math.cos(a) * h * lean, by_ + math.sin(a) * h * lean, cz + h)
        if k == 0: tip = (cx, cy, cz + h)
        col = cols[k % len(cols)]
        gem(m, (bx_, by_, cz - 0.3), tip, s * rnd.uniform(0.12, 0.2), col, part=part + col)


def X_WallSeg(m):
    rnd = random.Random(4)
    strata_segment(m, 28, 14, 30, [SLATE, SLATE2, SLATE3], rnd, part_prefix="Rock", jag=0.12)
    for k in range(3):
        x = rnd.uniform(-11, 11)
        cluster(m, x, -6.8, rnd.uniform(3, 18), rnd.uniform(3, 5), rnd, n=4)


def X_WallSegB(m):
    """Variant with a timbered mine tunnel mouth, rails running into the dark and a lantern."""
    rnd = random.Random(9)
    strata_segment(m, 28, 14, 30, [SLATE2, SLATE, SLATE3], rnd, part_prefix="Rock", jag=0.12)
    flat(m, P("161B26"), arch_poly(9, 10, n=8), 0.6, (0, -6.4, 0), axis=(0, -1, 0), part="Tunnel")
    for sx in (-5, 5):
        bx(m, "Timber", TIMB, sx - 0.7, sx + 0.7, -8.2, -6.8, 0, 9, r=0.15)
    bx(m, "Timber", TIMB, -5.8, 5.8, -8.2, -6.8, 8.6, 10, r=0.15)
    for sx in (-1.1, 1.1):
        beam(m, P(RAIL), (sx, -12, 0.15), (sx, -6.6, 0.15), w=0.25, h=0.25, r=0.03, part="Rail")
    for k in range(5):
        bx(m, "Sleeper", TIMB2, -1.8, 1.8, -11.6 + k * 1.2, -11.1 + k * 1.2, 0, 0.18, r=0.03)
    lantern(m, 6.2, -8.6, 7, col="FFD27A", s=1.2)
    cluster(m, -9, -6.6, 12, 4, rnd, n=4)


def X_Heart(m):
    """Landmark: the Crystal Heart - a huge multi-crystal formation on a rock base with a mining crane beside it (~32 x 28, 48 tall)."""
    rnd = random.Random(12)
    for k in range(7):
        a = 2 * math.pi * k / 7
        rock(m, P(SLATE if k % 2 else SLATE2), (math.cos(a) * 7, math.sin(a) * 6, 2.5), size=(6, 5, 3.4), seed=k, sub=1, jag=0.15, part="Base")
    rock(m, P(SLATE3), (0, 0, 4), size=(8, 7, 4.5), seed=99, sub=1, jag=0.12, part="Base")
    gem(m, (0, 0, 5), (0.8, -0.4, 46), 5.2, CYAN, part="Heart")
    gem(m, (0, 0, 15), (0.4, -0.2, 44), 3.0, PALEC, part="HeartCore", glow=True)
    for (a, h, r, col) in ((0.3, 30, 3.4, MAG), (1.4, 26, 3.0, VIO), (2.5, 33, 3.2, PALEC), (3.6, 22, 2.6, CYAN), (4.6, 28, 3.0, MAG), (5.5, 20, 2.4, VIO)):
        b = (math.cos(a) * 4.5, math.sin(a) * 4, 4)
        t = (math.cos(a) * 12, math.sin(a) * 10, 4 + h)
        gem(m, b, t, r, col, part="Crystal" + col)
    cluster(m, 9, -7, 1, 7, rnd, n=5)
    cluster(m, -10, 6, 1, 6, rnd, n=5)
    # mining crane (timber mast + jib + hook holding a crystal)
    rod(m, P(TIMB), (-15, -6, 0), (-15, -6, 30), r=0.6, seg=6, part="Timber")
    for zz in range(4, 28, 6):
        beam(m, P(TIMB2), (-16.2, -6, zz), (-13.8, -6, zz + 5), w=0.3, h=0.3, r=0.05, part="Timber")
        beam(m, P(TIMB2), (-13.8, -6, zz), (-16.2, -6, zz + 5), w=0.3, h=0.3, r=0.05, part="Timber")
    beam(m, P(TIMB), (-15, -6, 30), (-3, -10, 36), w=0.7, h=0.7, r=0.1, part="Timber")
    beam(m, P(TIMB), (-15, -6, 30), (-20, -4, 31), w=0.6, h=0.6, r=0.1, part="Timber")
    bx(m, "Weight", "4A4F5C", -22, -19, -5.5, -2.5, 28, 31, r=0.3)
    rod(m, P("C9C2A8"), (-3.4, -10, 35.6), (-3.4, -10, 26), r=0.1, seg=5, part="Rope")
    gem(m, (-3.4, -10, 22.5), (-3.4, -10, 26), 1.3, MAG, part="CrystalHook")
    snowcap(m, -16, -14, -7, -5, 30, t=0.4)
    for k in range(6):
        drift(m, rnd.uniform(-14, 14), rnd.uniform(-12, 12), 0.1, rnd.uniform(1.6, 2.6), rnd)


def X_Headframe(m):
    """Mine headframe with a big pulley wheel (Spin) on top (~12 x 10, 22 tall). Wheel is its own part 'Wheel'."""
    for sx in (-4, 4):
        for sy in (-3, 3):
            rod(m, P(TIMB), (sx, sy, 0), (sx * 0.6, sy * 0.6, 18), r=0.45, seg=6, part="Timber")
    for zz in (5, 11, 17):
        k = 1 - zz / 30
        for (a, b) in (((-4 * k, -3 * k), (4 * k, -3 * k)), ((-4 * k, 3 * k), (4 * k, 3 * k)), ((-4 * k, -3 * k), (-4 * k, 3 * k)), ((4 * k, -3 * k), (4 * k, 3 * k))):
            beam(m, P(TIMB2), (a[0], a[1], zz), (b[0], b[1], zz), w=0.3, h=0.3, r=0.05, part="Timber")
    bx(m, "Deck", TIMB2, -3.4, 3.4, -2.6, 2.6, 18, 18.5, r=0.1)
    torus(m, P(RAIL), (0, 0, 21.5), R=2.8, r=0.3, seg=20, rseg=6, rot=(90, 0, 0), part="Wheel")
    for k in range(6):
        a = math.pi * k / 6
        beam(m, P(RAIL), (math.cos(a) * 2.7, 0, 21.5 + math.sin(a) * 2.7), (-math.cos(a) * 2.7, 0, 21.5 - math.sin(a) * 2.7), w=0.18, h=0.18, r=0.02, part="Wheel")
    rod(m, P("C9C2A8"), (2.8, 0, 21.5), (2.8, 0, 3), r=0.08, seg=4, part="Rope")
    bx(m, "Cage", "6E7480", 1.6, 4.0, -1.2, 1.2, 1, 3.6, r=0.1)
    snowcap(m, -3.4, 3.4, -2.6, 2.6, 18.5, t=0.35)


def X_Trestle(m):
    """Supported timber walkway segment (24 long, ~9 tall) with railings and a lantern - decorative, along the walls."""
    for k in range(4):
        x = -10.5 + k * 7
        for sy in (-1.6, 1.6):
            rod(m, P(TIMB), (x, sy, 0), (x, sy, 8), r=0.35, seg=6, part="Timber")
        beam(m, P(TIMB2), (x, -1.6, 0.5), (x, 1.6, 7.5), w=0.22, h=0.22, r=0.04, part="Timber")
    bx(m, "Deck", TIMB2, -12, 12, -2.2, 2.2, 8, 8.5, r=0.1)
    for sy in (-2.0, 2.0):
        beam(m, P(TIMB), (-12, sy, 9.8), (12, sy, 9.8), w=0.2, h=0.25, r=0.04, part="Timber")
        for k in range(7):
            rod(m, P(TIMB), (-12 + k * 4, sy, 8.5), (-12 + k * 4, sy, 9.8), r=0.12, seg=4, part="Timber")
    snowcap(m, -12, 12, -2.2, 2.2, 8.5, t=0.3)
    lantern(m, 0, -2.4, 10, col="FFD27A")


def X_Cart(m):
    """Ore cart on a short rail piece, heaped with crystals (8 x 4)."""
    rnd = random.Random(17)
    for sy in (-0.9, 0.9):
        beam(m, P(RAIL), (-4, sy, 0.12), (4, sy, 0.12), w=0.2, h=0.24, r=0.02, part="Rail")
    for k in range(6):
        bx(m, "Sleeper", TIMB2, -3.6 + k * 1.4 - 0.3, -3.6 + k * 1.4 + 0.3, -1.5, 1.5, 0, 0.16, r=0.03)
    lathe(m, P("6E7480"), [(0.01, 0.9), (1.4, 0.9), (1.8, 2.6)], seg=4, rot=(0, 0, 45), sx=1.4, sy=1.0, part="Cart")
    for sx in (-1.2, 1.2):
        for sy in (-0.95, 0.95):
            cyl(m, P(DARK), (sx, sy, 0.55), r=0.5, h=0.25, seg=10, rot=(90, 0, 0), part="Wheels")
    for k in range(5):
        gem(m, (rnd.uniform(-1, 1), rnd.uniform(-0.6, 0.6), 2.2), (rnd.uniform(-1.4, 1.4), rnd.uniform(-0.8, 0.8), 3.6 + rnd.uniform(0, 1)), 0.45, [CYAN, MAG, VIO][k % 3])


def X_Cluster(m):
    rnd = random.Random(23)
    rock(m, P(SLATE2), (0, 0, 0.8), size=(3.4, 3, 1.6), seed=3, sub=1, jag=0.2, part="Base")
    cluster(m, 0, 0, 1, 8, rnd, n=6)
    drift(m, 2.5, 1.5, 0.1, 1.4, rnd)


def X_BigCrystal(m):
    """Large formation for corners (~16 tall)."""
    rnd = random.Random(29)
    rock(m, P(SLATE), (0, 0, 1.4), size=(5, 4, 2.4), seed=5, sub=1, jag=0.16, part="Base")
    gem(m, (0, 0, 2), (1.0, 0.4, 17), 2.6, PALEC, part="CrystalA")
    gem(m, (1.5, 1, 1.5), (5, 2.5, 11), 1.8, VIO, part="CrystalB")
    gem(m, (-1.5, -0.5, 1.5), (-5, -2, 10), 1.6, CYAN, part="CrystalC")
    gem(m, (0.5, -1.5, 1.5), (1.6, -5, 8), 1.2, MAG, part="CrystalD")


def X_Cave(m):
    """Background quarry cliff with a glowing crystal cave mouth (outside the boundary, 60 x 30, ~40 tall)."""
    rnd = random.Random(37)
    strata_segment(m, 60, 26, 40, [SLATE2, SLATE, "3E4C64"], rnd, part_prefix="Rock", jag=0.12, layers=4)
    flat(m, P("10141E"), arch_poly(14, 16, n=8), 0.8, (4, -11.6, 0), axis=(0, -1, 0), part="Cave")
    for k in range(6):
        x = 4 + rnd.uniform(-6, 6)
        gem(m, (x, -12.4, rnd.uniform(0, 8)), (x + rnd.uniform(-2, 2), -14.5, rnd.uniform(4, 13)), rnd.uniform(0.8, 1.6), [CYAN, MAG, VIO][k % 3], part="CaveGlow", glow=True)
    for k in range(3):
        cluster(m, rnd.uniform(-26, 26), -12.5, rnd.uniform(6, 30), rnd.uniform(4, 7), rnd, n=4)


def X_Lamp(m):
    rod(m, P(TIMB), (0, 0, 0), (0, 0, 6), r=0.22, seg=6, part="Timber")
    beam(m, P(TIMB), (0, 0, 5.8), (1.6, 0, 5.8), w=0.18, h=0.18, r=0.03, part="Timber")
    lantern(m, 1.6, 0, 4.6, col="FFD27A", s=1.1)
    gem(m, (0.2, 0.2, 0), (0.6, 0.8, 1.6), 0.4, CYAN)


def X_Crates(m):
    rnd = random.Random(43)
    for (x, y, s, r) in ((-2, 0, 2.2, 10), (0.6, -1.2, 1.8, -12), (-0.8, 1.8, 1.6, 30)):
        crate(m, x, y, 0, s, rot=r, col=TIMB)
    barrel(m, 3, 1, 0, h=2.2, col="5B6E84")
    for k in range(3):
        gem(m, (-2 + rnd.uniform(-0.6, 0.6), rnd.uniform(-0.5, 0.5), 2.2), (-2 + rnd.uniform(-1, 1), rnd.uniform(-1, 1), 3.4), 0.4, [CYAN, MAG, VIO][k])


BUILDERS = {"X_WallSeg": X_WallSeg, "X_WallSegB": X_WallSegB, "X_Heart": X_Heart, "X_Headframe": X_Headframe, "X_Trestle": X_Trestle, "X_Cart": X_Cart,
            "X_Cluster": X_Cluster, "X_BigCrystal": X_BigCrystal, "X_Cave": X_Cave, "X_Lamp": X_Lamp, "X_Crates": X_Crates}
