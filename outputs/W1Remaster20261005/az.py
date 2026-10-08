# az.py - Absolute Zero (World 1 remaster, Claude 2026-10-05): glacier cliffs, giant frozen pines, crystal towers, frozen heart engine,
# polar research camp, portal guardians + aurora banners, penguins. Icy palette, glowing cyan cores.
import math, random
from w1lib import *
from mathutils import Vector as V3

GL1 = "CFEBFF"; GL2 = "9FD3F7"; GL3 = "6FAEE8"; DEEP = "3E6FA8"; ROCKD = "2C4566"; GLOW = "7FE9FF"; GLOW2 = "B9A6FF"
PINE1 = "4FA3E8"; PINE2 = "2F7FD0"; PINE3 = "8CC8F5"; ORANGE = "FF8A3D"; TENT = "E9503F"; METAL = "8A96A8"


def spike(m, x, y, z, h, r, col=GL2, part="Spike", lean=(0, 0)):
    lathe(m, P(col), [(r, 0), (r * 0.55, h * 0.6), (0.01, h)], loc=(x, y, z), seg=5, rot=(lean[0], lean[1], 0), part=part)


def icicles(m, x0, x1, y, z, rnd, n=4, part="Icicle"):
    for k in range(n):
        x = rnd.uniform(x0, x1); h = rnd.uniform(1.2, 2.8)
        lathe(m, P(GL1, "IC"), [(0.35, 0), (0.01, -h)], loc=(x, y, z), seg=5, part=part)


def Z_CliffSeg(m, big=False):
    """Glacier cliff (14 x 12, ~30 tall): dark rock foot, stacked glacier slabs, icicle ledges, snow, ice spikes on top."""
    rnd = random.Random(5 if not big else 6)
    Lh, D, H = 14.0, 12.0, 28.0
    bx(m, "Foot", ROCKD, -Lh / 2 + 0.2, Lh / 2 - 0.2, -D / 2 + 0.6, D / 2, 0, 6, r=0.8)
    top = strata_segment(m, Lh, D, H - 5, [GL2, GL3, GL1, GL2], rnd, part_prefix="Glacier", snow=True, jag=0.12, layers=4)
    # dark rock band along the foot, in front of the glacier strata
    for k in range(3):
        rbox(m, P(ROCKD), (-Lh / 2 + Lh * (k + 0.5) / 3 + rnd.uniform(-0.5, 0.5), -D / 2 + 0.6, 2.2), (Lh / 3 * 1.1, 2.0, 4.4), r=0.7, bseg=2, rot=(0, 0, rnd.uniform(-4, 4)), part="Foot")
    icicles(m, -6, 6, -D / 2 + 0.4, 9.5, rnd, n=4)
    icicles(m, -6, 6, -D / 2 + 1.4, 15.0, rnd, n=3)
    n = 3 if not big else 2
    for k in range(n):
        x = -Lh / 2 + Lh * (k + 0.5) / n + rnd.uniform(-1, 1)
        spike(m, x, rnd.uniform(-2, 2), top - 0.4, rnd.uniform(5, 9), rnd.uniform(1.0, 1.6), col=GL1 if k % 2 else GL2, lean=(rnd.uniform(-8, 8), rnd.uniform(-8, 8)))
    if big:
        lathe(m, P(GLOW, "GL", 0.2), [(1.8, 0), (1.2, 8), (0.01, 13)], loc=(0, 0.5, top - 0.6), seg=6, part="Spire")


def Z_CliffSegB(m):
    Z_CliffSeg(m, big=True)


def Z_FrozenPine(m):
    """Giant stylised frozen pine (~42 tall): five tiered ice-blue cones with icicle fringes and snow rims."""
    rnd = random.Random(9)
    cyl(m, P("5A6F8A"), (0, 0, 0), r=1.6, h=8, r2=1.2, seg=10, part="Trunk")
    tiers = [(13, 5, 9), (11, 13, 9), (9, 20.5, 8), (6.8, 27.5, 7.5), (4.6, 34, 8)]
    for i, (r, z, h) in enumerate(tiers):
        col = [PINE2, PINE1, PINE2, PINE1, PINE3][i]
        lathe(m, P(col), [(r, z), (r * 0.92, z + 0.6), (0.01, z + h)], seg=12, part="Tier" + col)
        torus(m, P(SNOW), (0, 0, z + 0.45), R=r * 0.95, r=0.45, seg=24, rseg=5, part="SnowRim")
        for k in range(int(r * 1.1)):
            a = 2 * math.pi * k / int(r * 1.1) + rnd.uniform(-0.1, 0.1)
            lathe(m, P(GL1, "IC"), [(0.4, 0), (0.01, -rnd.uniform(1.5, 3.2))], loc=(math.cos(a) * r * 0.97, math.sin(a) * r * 0.97, z + 0.1), seg=5, part="Icicle")
    lathe(m, P(GLOW, "NE"), [(0.9, 41.5), (0.01, 44.5)], seg=6, part="Star")
    drift(m, 0, 0, 0.1, 5.0, rnd)


def Z_CrystalTower(m):
    """Crystal tower (~40 tall): rock plinth, tall glowing main crystal with satellite crystals, frost rings."""
    rnd = random.Random(13)
    rock(m, P(ROCKD), (0, 0, 3), (5.5, 5, 3.2), seed=13, part="Plinth")
    lathe(m, P(GLOW, "GL", 0.15), [(3.0, 3), (2.6, 24), (1.6, 32), (0.01, 40)], seg=6, part="MainCrystal")
    lathe(m, P(GLOW, "NE"), [(1.2, 6), (1.0, 28), (0.01, 34)], seg=6, part="Core")
    for k in range(7):
        a = 2 * math.pi * k / 7 + rnd.uniform(-0.2, 0.2); d = rnd.uniform(3, 5.5); h = rnd.uniform(8, 18)
        lathe(m, P([GL1, GL2, GLOW2][k % 3], "GL" if k % 3 else "IC", 0.1), [(1.3, 0), (1.0, h * 0.7), (0.01, h)], loc=(math.cos(a) * d, math.sin(a) * d, 2), rot=(math.cos(a) * 14, -math.sin(a) * 14, 0), seg=5, part="Satellite")
    for z in (12, 20):
        torus(m, P(GL1, "NE"), (0, 0, z), R=4.6, r=0.18, seg=24, rseg=4, part="FrostRing")
    drift(m, 0, 0, 0.1, 4.0, rnd)


def Z_HeartEngine(m):
    """Frozen Heart Engine (20 x 20, ~22 tall): machine base with pipes, ice-encased glowing heart in a rotating ring frame."""
    rnd = random.Random(17)
    cyl(m, P(METAL), (0, 0, 0), r=9, h=2.2, r2=8.4, seg=20, part="Base")
    cyl(m, P(ROCKD), (0, 0, 2.2), r=6.5, h=2.0, seg=16, part="Deck")
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        x, y = math.cos(a) * 6.8, math.sin(a) * 6.8
        rbox(m, P(METAL), (x, y, 8.5), (1.6, 1.6, 13), r=0.3, part="Pylon")
        sphere(m, P(GLOW, "NE"), (x, y, 15.4), 0.8, seg=10, part="PylonLight")
        tube(m, P("5E6B7D"), [(x * 1.05, y * 1.05, 1.5), (x * 1.25, y * 1.25, 1.0), (x * 1.3, y * 1.3, 0.2)], r=0.5, seg=8, part="Pipe", smooth=2)
    # ring frame (Spin in Studio) + heart
    torus(m, P("C9D6E6", "ME"), (0, 0, 11), R=5.4, r=0.55, seg=32, rseg=8, rot=(90, 0, 0), part="Ring")
    torus(m, P("C9D6E6", "ME"), (0, 0, 11), R=5.4, r=0.4, seg=32, rseg=8, rot=(90, 0, 90), part="Ring")
    sphere(m, P(GL1, "GL", 0.25), (0, 0, 11), 3.6, seg=14, rings=8, part="IceShell")
    lathe(m, P(GLOW, "NE"), [(0.01, 8.6), (1.9, 10.4), (1.6, 12), (0.01, 13.6)], seg=6, part="HeartCore")
    snowcap(m, -2, 2, -2, 2, 4.2, t=0.2)
    for k in range(5):
        a = rnd.uniform(0, 6.28)
        sphere(m, P(SNOW), (math.cos(a) * 8.5, math.sin(a) * 8.5, 2.2), rnd.uniform(1.2, 1.8), scl=(1.5, 1.2, 0.4), seg=8, rings=5, part="Snow")


def Z_Beacon(m):
    """Frost beacon (~11 tall): stone base, metal post, glowing crystal lantern."""
    bx(m, "Base", ROCKD, -1.4, 1.4, -1.4, 1.4, 0, 1.2, r=0.3)
    cyl(m, P(METAL), (0, 0, 1.2), r=0.35, h=7.6, seg=8, part="Post")
    cyl(m, P(METAL), (0, 0, 8.6), r=1.1, h=0.4, seg=10, part="Cage")
    lathe(m, P(GLOW, "NE"), [(0.01, 8.9), (0.8, 9.8), (0.01, 11.2)], seg=6, part="Lamp")
    cyl(m, P(METAL), (0, 0, 11.1), r=0.9, h=0.3, seg=10, part="Cap")
    snowcap(m, -1.4, 1.4, -1.4, 1.4, 1.2, t=0.25)


def Z_Camp(m):
    """Polar research camp (18 x 14): orange dome tent, radio mast, supply crates, a snowmobile, flag."""
    rnd = random.Random(19)
    sphere(m, P(TENT, "FA"), (-3, 1, 0), 4.2, scl=(1.2, 1.0, 0.75), seg=14, rings=7, part="Dome")
    bx(m, "Door", "3A3F4A", -4.2, -1.8, -3.3, -3.0, 0, 2.6, r=0.3)
    sphere(m, P(SNOW), (-3, 1, 3.0), 2.6, scl=(1.2, 1.0, 0.3), seg=10, rings=5, part="Snow")
    # radio mast
    for k in range(4):
        z0 = k * 3.5
        cyl(m, P(METAL), (5, 4, z0), r=0.25, h=3.5, seg=6, part="Mast")
    rbox(m, P(TENT), (5, 4, 14.4), (0.12, 1.6, 1.0), r=0.02, part="Flag")
    sphere(m, P(TENT, "NE"), (5, 4, 14.2), 0.25, seg=6, part="MastLight")
    for (x, y) in ((5 + 2.5, 4), (5 - 2.5, 4), (5, 4 + 2.5)):
        tube(m, P("C9D6E6"), [(5, 4, 12), (x, y, 0)], r=0.06, seg=4, part="Guy", smooth=1)
    crate(m, 4, -3, 0, 2.2, rot=10); crate(m, 6.6, -2.4, 0, 1.8, rot=-15); crate(m, 5.2, -2.8, 2.2, 1.6, rot=30)
    # snowmobile
    bx(m, "Sled", ORANGE, -6, -1, -6.5, -4.6, 0.6, 1.8, r=0.5)
    bx(m, "Seat", "2B2F38", -4.6, -2.4, -6.3, -4.8, 1.8, 2.4, r=0.3)
    rbox(m, P("2B2F38"), (-6.4, -5.55, 2.4), (0.4, 1.6, 0.8), r=0.1, part="Bar")
    for y in (-6.6, -4.5):
        bx(m, "Ski", METAL, -7.2, -0.6, y - 0.15, y + 0.15, 0, 0.4, r=0.1)
    for k in range(3):
        drift(m, rnd.uniform(-8, 8), rnd.uniform(-6, 6), 0.1, 1.8, rnd)


def Z_Guardian(m):
    """Portal guardian (~14 tall): ice golem statue on a plinth, glowing eyes, crystal spear."""
    bx(m, "Plinth", ROCKD, -2.6, 2.6, -2.6, 2.6, 0, 1.6, r=0.4)
    rbox(m, P(GL2), (0, 0, 4.0), (3.4, 2.4, 3.6), r=0.8, part="Legs")
    rbox(m, P(GL3), (0, 0, 7.6), (4.6, 3.0, 4.0), r=1.0, part="Torso")
    rbox(m, P(GL2), (0, -0.2, 10.6), (2.8, 2.6, 2.4), r=0.8, part="Head")
    for x in (-0.65, 0.65):
        bx(m, "Eye", GLOW, x - 0.35, x + 0.35, -1.55, -1.4, 10.6, 11.1, r=0.05, mat="NE")
    for sx in (-1, 1):
        rbox(m, P(GL2), (sx * 3.0, 0, 7.4), (1.4, 1.6, 4.0), r=0.5, rot=(0, sx * 8, 0), part="Arm")
    rod(m, P(METAL), (3.1, -0.6, 2.4), (3.1, -0.6, 14), r=0.18, seg=6, part="Spear")
    lathe(m, P(GLOW, "NE"), [(0.5, 14), (0.01, 16.2)], loc=(3.1, -0.6, 0), seg=5, part="SpearTip")
    for k in range(3):
        spike(m, -1 + k, 0.4, 11.6, 1.6, 0.4, col=GL1, part="Crown")
    snowcap(m, -2.6, 2.6, -2.6, 2.6, 1.6, t=0.3)


def Z_Banner(m):
    """Aurora banner (~17 tall): ice pole, crossbar, two-tone cloth (Sway in Studio)."""
    cyl(m, P(METAL), (0, 0, 0), r=0.3, h=16, seg=8, part="Pole")
    lathe(m, P(GLOW, "NE"), [(0.5, 16), (0.01, 17.4)], seg=6, part="Finial")
    cyl(m, P(METAL), (-0.1, 0, 15), r=0.15, h=5, seg=6, rot=(0, 90, 0), part="Bar")
    rbox(m, P("4CD3C2", "FA"), (2.6, 0, 11.8), (4.4, 0.12, 6.0), r=0.05, part="Cloth")
    rbox(m, P("8E7CFF", "FA"), (2.6, -0.05, 8.2), (4.4, 0.12, 1.6), r=0.05, part="Cloth2")
    prism(m, P(GLOW, "NE"), star_poly(6, 1.1, 0.45), 0.1, loc=(2.6, -0.14, 12.2), rot=(90, 0, 0), part="Emblem")
    drift(m, 0, 0, 0.1, 1.0, random.Random(3))


def Z_Ruins(m):
    """Frozen temple ruins (16 x 8, ~14 tall): broken columns, a fallen lintel, rubble, ice crust."""
    rnd = random.Random(23)
    for k, (x, h) in enumerate(((-6, 12), (0, 7), (6, 10))):
        bx(m, "ColBase", ROCKD, x - 1.6, x + 1.6, -1.6, 1.6, 0, 1.0, r=0.2)
        cyl(m, P("A9B8C8"), (x, 0, 1.0), r=1.2, h=h, seg=10, part="Column")
        lathe(m, P(GL1, "IC"), [(1.3, 1 + h), (0.9, 1.6 + h), (0.01, 2.2 + h)], loc=(x, 0, 0), seg=7, part="IceCrust")
    bx(m, "Lintel", "A9B8C8", -8, 1, -1.2, 1.2, 0, 1.6, r=0.2, rot=(0, 0, 12))
    for k in range(6):
        rock(m, P("8E9BAA"), (rnd.uniform(-7, 7), rnd.uniform(-3, 3), 0.5), (rnd.uniform(0.6, 1.2), rnd.uniform(0.6, 1.0), 0.6), seed=k + 30, part="Rubble")
    spike(m, -6, 0.6, 13, 3.0, 0.8, col=GL2)
    snowcap(m, -7.6, -4.4, -1.6, 1.6, 1.0, t=0.25)


def Z_Penguin(m):
    """Penguin (~3 tall) for Bob motion near the camp and the portal."""
    sphere(m, P("1F2433"), (0, 0, 1.3), 0.95, scl=(1.0, 0.9, 1.35), seg=12, rings=8, part="Body")
    sphere(m, P("F4F7FB"), (0, -0.45, 1.2), 0.75, scl=(0.9, 0.6, 1.25), seg=10, rings=6, part="Belly")
    sphere(m, P("1F2433"), (0, -0.1, 2.75), 0.6, seg=10, rings=6, part="Head")
    for x in (-0.22, 0.22):
        sphere(m, P("FFFFFF"), (x, -0.55, 2.85), 0.13, seg=6, part="Eye")
    lathe(m, P(ORANGE), [(0.17, 0), (0.01, 0.4)], loc=(0, -0.62, 2.7), rot=(90, 0, 0), seg=6, part="Beak")
    for x in (-0.35, 0.35):
        rbox(m, P(ORANGE), (x, -0.25, 0.08), (0.45, 0.6, 0.16), r=0.06, part="Foot")
    for sx in (-1, 1):
        rbox(m, P("1F2433"), (sx * 0.95, 0, 1.4), (0.2, 0.55, 1.2), r=0.08, rot=(0, sx * 15, 0), part="Flipper")


BUILDERS = {"Z_CliffSeg": Z_CliffSeg, "Z_CliffSegB": Z_CliffSegB, "Z_FrozenPine": Z_FrozenPine, "Z_CrystalTower": Z_CrystalTower,
            "Z_HeartEngine": Z_HeartEngine, "Z_Beacon": Z_Beacon, "Z_Camp": Z_Camp, "Z_Guardian": Z_Guardian, "Z_Banner": Z_Banner,
            "Z_Ruins": Z_Ruins, "Z_Penguin": Z_Penguin}
