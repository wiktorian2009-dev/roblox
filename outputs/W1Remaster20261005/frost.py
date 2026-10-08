# frost.py - Frostfall Village props (World 1 remaster, Claude 2026-10-05). The approved village layout, machines, eggs, travel points,
# meshes and the mini snowplow display stay; these replace the part-built pines/lanterns/benches/scout props and add background landmarks.
import math, random
from w1lib import *

NAVY = "1D3753"; PINE_A = "2F707A"; PINE_B = "3E8B8B"; TRUNK = "7F5239"; SEAT = "C08A55"; GLASS = "FFC84F"
IGLOO = "EAF4FF"; IGLOO2 = "CFE3F7"; ROCK = "56657A"; ROCK2 = "6F7F94"; SCARF = "E2483D"; COAL = "22262E"; CARROT = "FF8A3D"


def F_Pine(m):
    """Village pine (~13 tall): three snowy tiers in the village teal, trunk, snow drift."""
    rnd = random.Random(3)
    cyl(m, P(TRUNK), (0, 0, 0), r=0.55, h=5, r2=0.4, seg=8, part="Trunk")
    for i, (r, z, h) in enumerate(((3.9, 3.2, 4.6), (3.0, 6.2, 4.2), (2.1, 9.0, 3.9))):
        col = PINE_A if i % 2 == 0 else PINE_B
        lathe(m, P(col), [(r, z), (r * 0.9, z + 0.5), (0.01, z + h)], seg=10, part="Tier" + col, wob=0.06, seed=i)
        if i == 2:
            lathe(m, P(SNOW), [(r * 0.55, z + h * 0.45), (r * 0.3, z + h * 0.75), (0.01, z + h + 0.08)], seg=10, part="Snow")
        torus(m, P(SNOW), (0, 0, z + 0.55), R=r * 0.88, r=0.42, seg=18, rseg=5, part="Snow")
    drift(m, 0.6, 0.3, 0.1, 2.2, rnd)


def F_Lantern(m):
    """Village lantern (~7.4 tall): navy post on a foot, warm glass box, roof with snow hat."""
    bx(m, "Foot", NAVY, -0.9, 0.9, -0.9, 0.9, 0, 0.9, r=0.2)
    cyl(m, P(NAVY), (0, 0, 0.9), r=0.18, h=5.0, seg=8, part="Post")
    torus(m, P(NAVY), (0, 0, 2.2), R=0.3, r=0.08, seg=10, rseg=4, part="Post")
    bx(m, "Base", NAVY, -0.7, 0.7, -0.7, 0.7, 5.9, 6.1, r=0.05)
    bx(m, "WarmGlass", GLASS, -0.55, 0.55, -0.55, 0.55, 6.1, 7.2, r=0.05, mat="NE")
    for sx in (-1, 1):
        for sy in (-1, 1):
            bx(m, "Frame", NAVY, sx * 0.6 - 0.06, sx * 0.6 + 0.06, sy * 0.6 - 0.06, sy * 0.6 + 0.06, 6.1, 7.2, r=0.02)
    lathe(m, P(NAVY), [(1.0, 7.2), (0.01, 7.9)], seg=4, rot=(0, 0, 45), part="Roof")
    lathe(m, P(SNOW), [(0.95, 7.32), (0.5, 7.75), (0.01, 8.0)], seg=8, part="Snow")


def F_Bench(m):
    """Snowy park bench (8 x 2.4): slatted seat + back, navy cast legs, snow pillow."""
    for sx in (-3.4, 3.4):
        bx(m, "Leg", NAVY, sx - 0.25, sx + 0.25, -1.0, 1.0, 0, 1.7, r=0.12)
        bx(m, "Arm", NAVY, sx - 0.2, sx + 0.2, -1.0, 0.6, 1.7, 2.4, r=0.1)
    for k in range(4):
        y = -0.95 + k * 0.55
        bx(m, "Seat", SEAT, -4, 4, y, y + 0.45, 1.7, 2.1, r=0.08)
    for k in range(3):
        z = 2.4 + k * 0.55
        bx(m, "Back", TRUNK, -4, 4, 0.75, 1.15, z, z + 0.42, r=0.08)
    sphere(m, P(SNOW), (0.8, -0.2, 2.2), 1.3, scl=(1.6, 0.8, 0.28), seg=8, rings=4, part="Snow")
    sphere(m, P(SNOW), (0, 0.95, 4.1), 1.6, scl=(2.4, 0.4, 0.22), seg=8, rings=4, part="Snow")


def snowman(m, x, y, s=1.0, part="Snowman"):
    sphere(m, P(SNOW), (x, y, 1.2 * s), 1.3 * s, seg=12, rings=8, part=part)
    sphere(m, P(SNOW), (x, y, 2.9 * s), 0.95 * s, seg=12, rings=8, part=part)
    sphere(m, P(SNOW), (x, y, 4.2 * s), 0.7 * s, seg=12, rings=8, part=part)
    for z in (2.6, 3.1):
        sphere(m, P(COAL), (x, y - 0.9 * s, z * s), 0.12 * s, seg=6, part="Coal")
    for dx in (-0.25, 0.25):
        sphere(m, P(COAL), (x + dx * s, y - 0.62 * s, 4.35 * s), 0.09 * s, seg=6, part="Coal")
    lathe(m, P(CARROT), [(0.13 * s, 0), (0.01, 0.7 * s)], loc=(x, y - 0.65 * s, 4.2 * s), rot=(90, 0, 0), seg=6, part="Carrot")
    torus(m, P(SCARF), (x, y, 3.65 * s), R=0.62 * s, r=0.16 * s, seg=14, rseg=5, part="Scarf")
    rbox(m, P(SCARF), (x + 0.4 * s, y - 0.55 * s, 3.2 * s), (0.3 * s, 0.12 * s, 0.9 * s), r=0.04, rot=(0, -15, 0), part="Scarf")
    cyl(m, P(COAL), (x, y, 4.75 * s), r=0.65 * s, h=0.08 * s, seg=12, part="Hat")
    cyl(m, P(COAL), (x, y, 4.8 * s), r=0.42 * s, h=0.75 * s, seg=12, part="Hat")
    for sx in (-1, 1):
        tube(m, P(TRUNK), [(x + sx * 0.8 * s, y, 3.0 * s), (x + sx * 1.6 * s, y, 3.6 * s), (x + sx * 2.0 * s, y, 3.7 * s)], r=0.07 * s, seg=4, part="Arm", smooth=2)


def lamp(m, x, y, h=4.5):
    cyl(m, P(NAVY), (x, y, 0), r=0.4, h=0.3, seg=8, part="LampFoot")
    cyl(m, P(NAVY), (x, y, 0.3), r=0.12, h=h, seg=6, part="LampPost")
    sphere(m, P(GLASS, "NE"), (x, y, h + 0.6), 0.45, seg=8, part="LampGlow")
    lathe(m, P(NAVY), [(0.6, h + 1.0), (0.01, h + 1.5)], loc=(x, y, 0), seg=8, part="LampCap")


def F_ScoutCamp(m):
    """Snow scout camp (24 x 17): faceted igloo with entry tunnel, campfire with logs + embers, snowman, lamp, rocks, drifts."""
    rnd = random.Random(7)
    sphere(m, P(IGLOO), (-4, 2, 0), 5.0, scl=(1, 1, 0.82), seg=12, rings=7, part="Igloo")
    for k in range(4):
        z = 0.9 + k * 1.05
        torus(m, P(IGLOO2), (-4, 2, z), R=math.sqrt(max(0.1, 25 - (z / 0.82) ** 2)) * 1.0, r=0.1, seg=20, rseg=3, part="IglooLine")
    rbox(m, P(IGLOO), (-4, -3.6, 1.3), (3.2, 3.4, 2.6), r=1.1, bseg=2, part="Igloo")
    bx(m, "Door", "35445C", -5.0, -3.0, -5.35, -5.1, 0, 2.0, r=0.4)
    # campfire
    for k in range(5):
        a = 2 * math.pi * k / 5
        rock(m, P(ROCK), (5 + math.cos(a) * 1.6, -2 + math.sin(a) * 1.6, 0.3), (0.5, 0.45, 0.35), seed=k, part="FireRing")
    for a in (0, 60, 120):
        cyl(m, P(TRUNK), (5, -2, 0.4), r=0.18, h=2.4, seg=6, rot=(0, 75, a), part="Log")
    lathe(m, P("FF7A2E", "NE"), [(0.6, 0.3), (0.35, 0.9), (0.01, 1.6)], loc=(5, -2, 0), seg=6, part="Ember")
    snowman(m, 9, 3, 1.0)
    lamp(m, 1.5, -5.5)
    for k in range(6):
        rock(m, P(ROCK if k % 2 else ROCK2), (rnd.uniform(-11, 11), rnd.choice((-7.5, 7.5)) + rnd.uniform(-1, 1), 0.5), (rnd.uniform(0.9, 1.6), rnd.uniform(0.8, 1.3), 0.9), seed=k + 20, part="Rock")
    for k in range(4):
        drift(m, rnd.uniform(-10, 10), rnd.uniform(-6, 6), 0.1, rnd.uniform(1.4, 2.2), rnd)


def F_TrailSign(m):
    """Trail marker (9 x 3): snowman beside a lamp and a wooden arrow sign."""
    snowman(m, -2, 0, 0.9)
    lamp(m, 2.4, 0, 4.0)
    cyl(m, P(TRUNK), (0.6, 0.6, 0), r=0.15, h=4.4, seg=6, part="SignPost")
    prism(m, P(SEAT), [(-1.6, -0.45), (1.0, -0.45), (1.6, 0), (1.0, 0.45), (-1.6, 0.45)], 0.2, loc=(0.6, 0.6, 3.8), rot=(90, 0, 0), part="SignBoard")
    snowcap(m, -1.0, 2.2, 0.45, 0.75, 4.3, t=0.15)


def F_Sled(m):
    """Expedition sled (9 x 4): curled runners, slatted deck, strapped crate, rolled blanket."""
    for y in (-1.5, 1.5):
        tube(m, P(NAVY), [(-4.2, y, 0.25), (3.4, y, 0.25), (4.3, y, 0.8), (4.0, y, 1.6)], r=0.13, seg=6, part="Runner", smooth=3)
        for x in (-3, 0, 3):
            cyl(m, P(NAVY), (x, y, 0.25), r=0.08, h=0.75, seg=5, part="Strut")
    for k in range(7):
        x = -3.9 + k * 1.1
        bx(m, "Deck", SEAT, x, x + 0.95, -1.8, 1.8, 1.0, 1.25, r=0.06)
    crate(m, -1.6, 0, 1.25, 2.0, rot=4)
    bx(m, "Strap", SCARF, -1.7, -1.5, -1.1, 1.1, 1.25, 3.3, r=0.03)
    cyl(m, P("5D7FB5", "FA"), (1.8, 0, 1.9), r=0.65, h=3.0, seg=12, rot=(90, 0, 0), part="Blanket")
    cyl(m, P(SCARF), (1.8, 0, 1.9), r=0.68, h=0.25, seg=12, rot=(90, 0, 0), part="BlanketBand")
    snowcap(m, -2.6, -0.6, -1.0, 1.0, 3.3, t=0.25)


def F_Watchtower(m):
    """Background landmark (~34 tall): rock knoll, timber lookout with snowy roof, warm lantern, pennant (Sway)."""
    rnd = random.Random(11)
    for k in range(5):
        a = 2 * math.pi * k / 5
        rock(m, P(ROCK if k % 2 else ROCK2), (math.cos(a) * 4, math.sin(a) * 4, 2.5), (5, 4.5, 3.4), seed=40 + k, part="Knoll")
    sphere(m, P(SNOW), (0, 0, 5.4), 6.5, scl=(1.2, 1.2, 0.25), seg=12, rings=6, part="Snow")
    for sx in (-1, 1):
        for sy in (-1, 1):
            rod(m, P(TRUNK), (sx * 3.2, sy * 3.2, 5), (sx * 2.2, sy * 2.2, 24), r=0.45, seg=8, part="Leg")
    for z in (11, 17):
        for (a, b) in (((-3, -3), (3, -3)), ((3, -3), (3, 3)), ((3, 3), (-3, 3)), ((-3, 3), (-3, -3))):
            k = (z - 5) / 19
            s = 3.2 - k
            rod(m, P(TRUNK), (a[0] / 3 * s, a[1] / 3 * s, z), (b[0] / 3 * s, b[1] / 3 * s, z), r=0.25, seg=6, part="Brace")
    bx(m, "Deck", SEAT, -3.4, 3.4, -3.4, 3.4, 24, 24.6, r=0.1)
    for (x0, x1, y0, y1) in ((-3.4, 3.4, -3.4, -3.1), (-3.4, 3.4, 3.1, 3.4), (-3.4, -3.1, -3.4, 3.4), (3.1, 3.4, -3.4, 3.4)):
        bx(m, "Rail", TRUNK, x0, x1, y0, y1, 24.6, 26, r=0.06)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl(m, P(TRUNK), (sx * 3.1, sy * 3.1, 24.6), r=0.2, h=4.4, seg=6, part="RoofPost")
    lathe(m, P(SCARF), [(4.6, 29), (0.01, 32.6)], seg=4, rot=(0, 0, 45), part="Roof")
    lathe(m, P(SNOW), [(4.4, 29.25), (2.4, 30.9), (0.01, 32.8)], seg=4, rot=(0, 0, 45), part="Snow")
    sphere(m, P(GLASS, "NE"), (0, 0, 27.4), 0.8, seg=10, part="Lantern")
    cyl(m, P(NAVY), (0, 0, 32.6), r=0.1, h=3.5, seg=6, part="FlagPole")
    rbox(m, P(SCARF), (1.1, 0, 35.4), (2.2, 0.08, 1.1), r=0.03, part="Pennant")


def F_PineGrove(m):
    """Background grove (24 x 18) of six pines at varied heights for the slopes behind the mountain ring."""
    rnd = random.Random(13)
    for k in range(6):
        x, y = rnd.uniform(-10, 10), rnd.uniform(-7, 7)
        pine(m, x, y, 0, rnd.uniform(9, 16), rnd, col=PINE_A, col2=PINE_B, snow=True, part="Pine")
    for k in range(4):
        drift(m, rnd.uniform(-10, 10), rnd.uniform(-7, 7), 0.1, rnd.uniform(2, 3), rnd)


BUILDERS = {"F_Pine": F_Pine, "F_Lantern": F_Lantern, "F_Bench": F_Bench, "F_ScoutCamp": F_ScoutCamp, "F_TrailSign": F_TrailSign,
            "F_Sled": F_Sled, "F_Watchtower": F_Watchtower, "F_PineGrove": F_PineGrove}
