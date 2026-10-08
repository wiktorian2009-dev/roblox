# desert.py - Frozen Desert Outpost (World 1 remaster, Claude 2026-10-05). Builders take a w2lib.Model; origin = floor-level centre.
import math, random
from w1lib import *

SAND = "E6C08A"; SAND2 = "D9A066"; SAND3 = "C98B52"; SAND4 = "B8764A"; SANDL = "F0D3A2"; CANVAS = "F4E6CB"; CANVAS2 = "D9573F"
GLYPH = "7A4A2A"; PALM = "5FB39A"; PALM2 = "3E8F7B"; TRUNK = "A8743F"


def D_CliffSeg(m):
    rnd = random.Random(11)
    strata_segment(m, 28, 16, 36, [SAND3, SAND2, SAND4, SANDL], rnd, part_prefix="Strata", jag=0.1)
    # a few icicles under the front ledges
    for k in range(6):
        x = rnd.uniform(-12, 12)
        rod(m, P(ICE, "IC"), (x, -6.6, rnd.uniform(9, 22)), (x, -6.9, rnd.uniform(5, 8)), r=0.45, r2=0.02, seg=6, part="Icicle")


def D_CliffSegB(m):
    rnd = random.Random(23)
    strata_segment(m, 28, 16, 30, [SAND2, SAND4, SANDL, SAND3], rnd, part_prefix="Strata", jag=0.14, layers=3)
    # a carved niche with a small statue on the front face
    bx(m, "Glyph", GLYPH, -3, 3, -8.4, -7.6, 6, 13, r=0.2)
    sphere(m, P(SANDL), (0, -8.6, 9.3), 1.2, scl=(1, 0.8, 1.2), seg=10, part="Statue")


def D_SunGate(m):
    """Landmark: a huge ruined sandstone gate with a hanging sun disc and an excavation scaffold (46 x 18, ~46 tall)."""
    rnd = random.Random(5)
    for sx, h in ((-1, 34), (1, 30)):
        x = sx * 17
        z = 0
        for i, (w, hh) in enumerate(((11, 7), (9, 9), (8, 9), (7, 9))):
            if z + hh > h: hh = h - z
            if hh <= 0: break
            bx(m, "Stone" + str(i % 2), SAND2 if i % 2 == 0 else SAND3, x - w / 2, x + w / 2, -w / 2, w / 2, z, z + hh, r=0.6, bseg=2)
            bx(m, "Glyph", GLYPH, x - w / 2 + 1, x + w / 2 - 1, -w / 2 - 0.12, -w / 2 + 0.05, z + 1.5, z + 2.3, r=0.05)
            z += hh
        snowcap(m, x - 3.6, x + 3.6, -3.6, 3.6, z, t=0.7)
    # intact half of the lintel on the left pillar, fallen half leaning on the right one
    bx(m, "Stone0", SAND2, -22, 2, -5, 5, 34, 39, r=0.7, bseg=2, rot=(0, -4, 0))
    snowcap(m, -22, 2, -5, 5, 39.2, t=0.6)
    rbox(m, P(SAND3), (12.5, -7.5, 9), (18, 9, 5), r=0.7, bseg=2, rot=(0, 52, -10), part="Stone1")
    snowcap(m, 6, 18, -10, -5, 15.5, t=0.4)
    # carved sun disc hanging from the lintel
    cyl(m, P(GOLD, "ME"), (-4, 0.4, 22), r=7.5, h=1.6, seg=28, rot=(90, 0, 0), part="Sun")
    prism(m, P("FFD25E", "NE"), star_poly(12, 10.5, 7.2), 0.6, loc=(-4, -0.9, 22), rot=(90, 0, 0), part="SunRays")
    cyl(m, P(GLYPH), (-4, -1.3, 22), r=3.2, h=0.4, seg=20, rot=(90, 0, 0), part="Glyph")
    for sx in (-2.6, 2.6):
        rod(m, P(STEEL), (-4 + sx, 0, 34), (-4 + sx, 0, 29.4), r=0.18, seg=6, part="Chain")
    # excavation scaffold on the left pillar: poles, planks, ladder, a pulley arm with a bucket
    for px in (-27, -21.5):
        for py in (-7, 3):
            rod(m, P(WOOD2), (px, py, 0), (px, py, 26), r=0.32, seg=6, part="Scaffold")
    for zz in (8, 16, 24):
        bx(m, "Plank", WOOD, -28, -20.5, -8, 4, zz, zz + 0.45, r=0.08)
        for py in (-7, 3):
            beam(m, P(WOOD2), (-27, py, zz - 3.5), (-21.5, py, zz), w=0.22, h=0.22, r=0.04, part="Scaffold")
    for zz in range(1, 24, 2):
        bx(m, "Plank", WOOD, -29.2, -28.6, -2.6, -0.6, zz, zz + 0.3, r=0.04)
    rod(m, P(WOOD2), (-29, -2.7, 0), (-29, -2.7, 24.5), r=0.18, seg=5, part="Scaffold")
    rod(m, P(WOOD2), (-29, -0.5, 0), (-29, -0.5, 24.5), r=0.18, seg=5, part="Scaffold")
    beam(m, P(WOOD2), (-24, -2, 26), (-34, -2, 31), w=0.5, h=0.5, r=0.08, part="Scaffold")
    rod(m, P("D9C8A0"), (-33.6, -2, 30.8), (-33.6, -2, 15), r=0.1, seg=5, part="Rope")
    lathe(m, P(WOOD), [(0.9, 0), (1.15, 1.6), (0, 1.6)], loc=(-33.6, -2, 13.5), seg=10, part="Bucket")
    # dig site: sand piles and a cart at the base
    for (x, y, r) in ((9, -11, 4.2), (-10, -12, 3.2), (22, 6, 3.6)):
        sphere(m, P(SANDL), (x, y, 0.2), r, scl=(1.4, 1.1, 0.45), seg=10, rings=6, part="SandPile")
        sphere(m, P(SNOW), (x + 0.6, y + 0.2, r * 0.42), r * 0.6, scl=(1.3, 1.0, 0.35), seg=8, rings=4, part="Snow")
    bx(m, "Cart", WOOD, -16, -11, -14, -10.6, 1.0, 2.8, r=0.2)
    for wx in (-15, -12):
        cyl(m, P(DARK), (wx, -14.3, 1.0), r=0.9, h=0.4, seg=10, rot=(90, 0, 0), part="Wheel")
        cyl(m, P(DARK), (wx, -10.3, 1.0), r=0.9, h=0.4, seg=10, rot=(90, 0, 0), part="Wheel")


def D_Ziggurat(m):
    """Half-buried stepped ruin (replaces the old pyramid): 34 x 34, 22 tall, sand drifts on two sides."""
    rnd = random.Random(8)
    z = 0
    for i, (w, h) in enumerate(((34, 6), (26, 6), (18, 5.5), (11, 4.5))):
        bx(m, "Step" + str(i % 2), SAND2 if i % 2 == 0 else SAND3, -w / 2, w / 2, -w / 2, w / 2, z, z + h, r=0.8, bseg=2)
        snowcap(m, -w / 2 + 0.2, w / 2 - 0.2, -w / 2 + 0.2, w / 2 - 0.2, z + h, t=0.45)
        for k in range(4):
            gx = -w / 2 + 3 + k * (w - 6) / 3
            bx(m, "Glyph", GLYPH, gx - 0.8, gx + 0.8, -w / 2 - 0.12, -w / 2 + 0.05, z + 1.5, z + h - 1.5, r=0.05)
        z += h
    # shrine on top with a dark doorway and a gold idol
    bx(m, "Step1", SAND3, -4.5, 4.5, -4.5, 4.5, z, z + 6, r=0.6)
    bx(m, "Door", "3A2416", -1.6, 1.6, -4.62, -4.3, z, z + 4, r=0.2)
    sphere(m, P(GOLD, "ME"), (0, 0, z + 7.1), 1.4, seg=12, part="Idol")
    snowcap(m, -4.6, 4.6, -4.6, 4.6, z + 6, t=0.5)
    # central stair
    for k in range(10):
        bx(m, "Stair", SANDL, -3, 3, -17.6 + k * 1.3, -16.4 + k * 1.3, 0, 1.2 + k * 2.1, r=0.2)
    # half-burying sand drifts on two sides
    for k in range(5):
        sphere(m, P(SANDL), (16 - k * 8, 17.5, 1), 7.5, scl=(1.2, 0.8, 0.75), seg=12, rings=7, part="Drift")
        sphere(m, P(SANDL), (17.5, 14 - k * 7, 1), 6.5, scl=(0.8, 1.2, 0.7), seg=12, rings=7, part="Drift")
    for k in range(3):
        sphere(m, P(SNOW), (14 - k * 9, 18, 5.2), 4, scl=(1.2, 0.8, 0.3), seg=9, rings=5, part="Snow")


def D_Camp(m):
    """Abandoned explorers' camp (30 x 22): striped tents, crates, barrels, a campfire ring, bedrolls and a signpost."""
    rnd = random.Random(31)
    def tent(x, y, rot, s):
        a = math.radians(rot)
        poly = [(-3.2 * s, 0), (3.2 * s, 0), (0, 4.2 * s)]
        flat(m, P(CANVAS), poly, 6.5 * s, (x - math.sin(a) * 3.25 * s, y + math.cos(a) * 3.25 * s, 0), axis=(math.sin(a), -math.cos(a), 0), part="Canvas")
        for k in (-1, 1):
            q = (x + math.cos(a) * 0 , y)
        flat(m, P(CANVAS2), [(-0.5 * s, 0), (0.5 * s, 0), (0.5 * s, 3.6 * s), (-0.5 * s, 3.6 * s)], 6.6 * s, (x - math.sin(a) * 3.3 * s, y + math.cos(a) * 3.3 * s, 0.01), axis=(math.sin(a), -math.cos(a), 0), part="Stripe")
        rod(m, P(WOOD2), (x, y, 0), (x, y, 4.6 * s), r=0.12, seg=5, part="Pole")
        sphere(m, P(SNOW), (x, y, 4.1 * s), 1.1 * s, scl=(1.0, 2.4, 0.3), seg=8, rings=4, part="Snow")
    tent(-8, 3, 15, 1.0)
    tent(2, 6, -20, 1.15)
    # campfire ring + logs + glow
    for k in range(8):
        a = 2 * math.pi * k / 8
        rock(m, P("8D8A86"), (6 + math.cos(a) * 1.9, -4 + math.sin(a) * 1.9, 0.35), size=(0.55, 0.45, 0.4), seed=k, sub=1, jag=0.2, part="Stones")
    for k in range(3):
        a = k * 2.1
        beam(m, P(WOOD2), (6 + math.cos(a) * 1.2, -4 + math.sin(a) * 1.2, 0.3), (6 - math.cos(a) * 1.2, -4 - math.sin(a) * 1.2, 0.6), w=0.4, h=0.4, r=0.1, part="Logs")
    cyl(m, P("FF8A2A", "NE"), (6, -4, 0.4), r=0.8, r2=0.1, h=1.6, seg=8, part="FireGlow")
    # crates, barrels, sacks
    for (x, y, s, r) in ((-12, -5, 2.2, 10), (-9.6, -6.2, 1.8, -15), (-11, -3.4, 1.5, 30), (12, 2, 2.0, 5)):
        crate(m, x, y, 0, s, rot=r)
    crate(m, -11.8, -5.2, 2.2, 1.4, rot=40)
    for (x, y) in ((13.5, -2), (11.3, -1.4)):
        barrel(m, x, y, 0)
    for (x, y) in ((-2, -7), (0, -8.2)):
        sphere(m, P("C9A877"), (x, y, 0.7), 0.9, scl=(1.2, 1, 0.8), seg=8, part="Sack")
    for (x, y, r) in ((4, -9, 70), (9.5, -7.5, -30)):
        rbox(m, P(CANVAS2), (x, y, 0.25), (3.2, 1.2, 0.5), r=0.25, rot=(0, 0, r), part="Bedroll")
    # signpost
    rod(m, P(WOOD2), (14, -8, 0), (14, -8, 6), r=0.22, seg=6, part="Pole")
    rbox(m, P(WOOD), (15.6, -8, 5), (3.8, 0.3, 1.2), r=0.15, rot=(0, 0, 8), part="Sign")
    rbox(m, P(WOOD), (12.6, -8, 4), (3.4, 0.3, 1.0), r=0.15, rot=(0, 0, -12), part="Sign")
    # a few snow drifts
    for (x, y, r) in ((-14, 7, 2.6), (8, 9, 2.2), (15, -11, 2.4)):
        drift(m, x, y, 0.1, r, rnd)


def D_Oasis(m):
    """Frozen oasis pond (24 x 16): ice sheet raised above the floor, sandy/snowy rim, frozen reeds and rocks."""
    rnd = random.Random(44)
    cyl(m, P("A9DDF5", "IC"), (0, 0, 0.0), r=10, h=0.35, seg=28, scl=(1.25, 0.8, 1), part="Ice")
    cyl(m, P("D6F1FF", "IC"), (2, 1, 0.36), r=3.2, h=0.04, seg=16, scl=(1.6, 0.6, 1), part="IceShine")
    for k in range(22):
        a = 2 * math.pi * k / 22
        x, y = math.cos(a) * 12.6, math.sin(a) * 8.2
        sphere(m, P(SANDL if k % 3 else SNOW), (x, y, 0.15), rnd.uniform(1.3, 2.1), scl=(1.4, 1.2, 0.42), seg=8, rings=4, part="Rim")
    for k in range(14):
        a = rnd.uniform(0, 6.28); r = rnd.uniform(9.5, 11.5)
        x, y = math.cos(a) * r * 1.2, math.sin(a) * r * 0.8
        h = rnd.uniform(1.8, 3.4)
        rod(m, P("9CC9B0"), (x, y, 0), (x + rnd.uniform(-0.3, 0.3), y + rnd.uniform(-0.3, 0.3), h), r=0.12, r2=0.03, seg=5, part="Reeds")
        sphere(m, P(WHITE), (x, y, h * 0.85), 0.22, scl=(1, 1, 2), seg=6, rings=4, part="ReedFrost")
    for (x, y, s) in ((-13, -4, 1.6), (12, 5, 1.3), (-6, 9, 1.1)):
        rock(m, P(SAND4), (x, y, s * 0.6), size=(s * 1.3, s, s * 0.9), seed=int(x * 10), sub=1, jag=0.2, part="Rock")


def D_FrozenPalm(m):
    """Frost-touched palm (~20 tall): curved ringed trunk, drooping blue-green fronds with white tips, snow on the crown."""
    rnd = random.Random(52)
    pts = [(0, 0, 0), (0.6, 0.2, 5), (1.8, 0.5, 10), (3.4, 0.8, 15), (5.0, 1.0, 18.5)]
    tube(m, P(TRUNK), pts, r=0.85, r2=0.55, seg=10, part="Trunk", smooth=4)
    from mathutils import Vector as V3
    for i in range(1, 14):
        t = i / 14
        q = L._catmull([V3(p) for p in pts], 6, False)
        p = q[int(t * (len(q) - 1))]
        torus(m, P("8C5F33"), (p.x, p.y, p.z), R=0.8 - t * 0.25, r=0.16, seg=12, rseg=4, part="Rings")
    top = V3((5.0, 1.0, 18.5))
    for k in range(8):
        a = 2 * math.pi * k / 8 + rnd.uniform(-0.15, 0.15)
        d = V3((math.cos(a), math.sin(a), 0))
        p1 = top + d * 4.5 + V3((0, 0, 1.2)); p2 = top + d * 8.5 + V3((0, 0, -1.6)); p3 = top + d * 10.5 + V3((0, 0, -4.2))
        tube(m, P(PALM if k % 2 else PALM2), [top, p1, p2, p3], r=0.95, r2=0.2, seg=6, part="Frond", sq=0.25, smooth=3)
        sphere(m, P(WHITE), (p3.x, p3.y, p3.z + 0.2), 0.45, scl=(1.6, 1.6, 0.6), seg=6, rings=4, part="FrostTip")
    for k in range(3):
        a = k * 2.1
        sphere(m, P("7A4E2A"), (5 + math.cos(a) * 0.9, 1 + math.sin(a) * 0.9, 17.6), 0.6, seg=8, part="Coconut")
    sphere(m, P(SNOW), (5, 1, 19.6), 1.8, scl=(1.4, 1.4, 0.45), seg=9, rings=5, part="Snow")
    sphere(m, P(SANDL), (0, 0, 0), 2.2, scl=(1.4, 1.4, 0.35), seg=9, rings=5, part="Mound")


def D_Dune(m):
    """Wind-shaped dune ridge (36 x 16, ~7 tall) with a sharp-ish crest and snow on the lee side - for outside the boundary."""
    rnd = random.Random(61)
    for k in range(7):
        x = -15 + k * 5 + rnd.uniform(-1, 1)
        h = 6.5 - abs(k - 3) * 1.4 + rnd.uniform(-0.4, 0.4)
        sphere(m, P(SAND if k % 2 else SANDL), (x, 0, 0), 1.0, scl=(6.5, 7.5, h), seg=12, rings=7, part="Sand")
    for k in range(4):
        sphere(m, P(SNOW), (-9 + k * 6, 3.5, 3.0 - abs(k - 1.5) * 0.6), 1.0, scl=(3.4, 2.4, 1.0), seg=9, rings=5, part="Snow")


def D_Mesa(m):
    rnd = random.Random(73)
    mesa(m, 0, 0, 44, 30, 46, [SAND3, SAND2, SAND4], rnd, part_prefix="Mesa")


def D_Ruins(m):
    """Half-buried ruin cluster (22 x 16): broken columns, a fallen drum column, a giant jackal-head statue sunk in sand."""
    rnd = random.Random(84)
    for (x, y, h) in ((-8, -4, 11), (-3.5, -5, 7), (1.5, -4.5, 13.5)):
        cyl(m, P(SAND2), (x, y, 0), r=1.6, h=h, seg=12, part="Column")
        for zz in range(2, int(h), 3):
            torus(m, P(SAND3), (x, y, zz), R=1.62, r=0.18, seg=14, rseg=4, part="Flute")
        cyl(m, P(SANDL), (x, y, h), r=2.0, h=0.9, seg=12, part="Capital")
        sphere(m, P(SNOW), (x, y, h + 1.0), 1.4, scl=(1.2, 1.2, 0.4), seg=8, rings=4, part="Snow")
    for k in range(3):
        cyl(m, P(SAND2), (-10 + k * 2.6, 4.5, 1.6), r=1.6, h=2.4, seg=12, rot=(0, 90, 8 * k), part="Column")
    # jackal statue head, sunk to the jaw
    sphere(m, P(SANDL), (7, 2, 2.5), 4.2, scl=(1.0, 1.25, 1.0), seg=14, rings=9, part="Statue")
    sphere(m, P(SANDL), (7, -2.6, 2.6), 2.2, scl=(0.9, 1.3, 0.8), seg=10, part="Statue")
    for sx in (-1, 1):
        prism(m, P(SAND2), [(-1.4, 0), (1.4, 0), (0, 4.4)], 0.9, loc=(7 + sx * 2.2, 1.4, 5.6), rot=(90, 0, sx * 12), part="Ear")
        sphere(m, P("2B6E8F", "NE"), (7 + sx * 1.6, -1.4, 4.4), 0.5, seg=8, part="Eye")
    bx(m, "Glyph", GOLD, 5.6, 8.4, -0.6, 0.6, 6.4, 6.9, r=0.15, mat="ME")
    for k in range(6):
        sphere(m, P(SAND), (rnd.uniform(-11, 11), rnd.uniform(-7, 7), 0), rnd.uniform(1.6, 3.2), scl=(1.5, 1.2, 0.45), seg=9, rings=5, part="SandPile")
    for k in range(5):
        rbox(m, P(SAND3), (rnd.uniform(-11, 11), rnd.uniform(-7, 7), 0.5), (rnd.uniform(1.4, 2.6), rnd.uniform(1.2, 2.2), rnd.uniform(0.8, 1.4)), r=0.25, rot=(0, 0, rnd.uniform(0, 90)), part="Block")
    sphere(m, P(SNOW), (7, 2, 6.6), 2.3, scl=(1.2, 1.4, 0.35), seg=9, rings=5, part="Snow")


def D_Obelisk(m):
    bx(m, "Base", SAND3, -3, 3, -3, 3, 0, 1.6, r=0.3)
    lathe(m, P(SAND2), [(2.0, 1.6), (1.4, 14), (0.01, 16.4)], loc=(0, 0, 0), seg=4, rot=(0, 0, 45), part="Shaft")
    lathe(m, P(GOLD, "ME"), [(0.62, 14.6), (0.01, 16.6)], loc=(0, 0, 0), seg=4, rot=(0, 0, 45), part="Tip")
    for k in range(4):
        a = math.radians(90 * k)
        prism(m, P(GLYPH), star_poly(6, 0.9, 0.4), 0.1, loc=(math.cos(a) * 1.85, math.sin(a) * 1.85, 8.5), rot=(90, 0, 90 * k + 90), part="Glyph")
    snowcap(m, -3, 3, -3, 3, 1.6, t=0.35)


def D_Hawk(m):
    """Small desert hawk for an Orbit motion (body along -Y = forward)."""
    sphere(m, P("8A5A36"), (0, 0, 0), 0.7, scl=(0.9, 1.8, 0.8), seg=10, part="Body")
    sphere(m, P("F0E2C8"), (0, -1.15, 0.2), 0.48, seg=8, part="Head")
    prism(m, P(GOLD), [(-0.18, 0), (0.18, 0), (0, 0.5)], 0.2, loc=(0, -1.6, 0.15), rot=(90, 0, 180), part="Beak")
    for sx in (-1, 1):
        mesh(m, P("6E452A"), [(0, 0.3, 0.1), (sx * 3.2, 0.9, 0.5), (sx * 2.6, -0.3, 0.3), (0, -0.4, 0.1)], [[0, 1, 2, 3], [3, 2, 1, 0]], part="Wing", recalc=False)
    mesh(m, P("6E452A"), [(-0.6, 1.0, 0), (0.6, 1.0, 0), (0.9, 2.4, 0), (-0.9, 2.4, 0)], [[0, 1, 2, 3], [3, 2, 1, 0]], part="Tail", recalc=False)


BUILDERS = {"D_CliffSeg": D_CliffSeg, "D_CliffSegB": D_CliffSegB, "D_SunGate": D_SunGate, "D_Ziggurat": D_Ziggurat, "D_Camp": D_Camp,
            "D_Oasis": D_Oasis, "D_FrozenPalm": D_FrozenPalm, "D_Dune": D_Dune, "D_Mesa": D_Mesa, "D_Ruins": D_Ruins, "D_Obelisk": D_Obelisk, "D_Hawk": D_Hawk}
