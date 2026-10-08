import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

# Sakura Garden scenery pack (World 2, stage 9) - Claude 2026-10-02. Units = studs, front = -Y.
from w2lib import *
PINK_L, PINK_M, PINK_D, PETAL = P("FFB7D5"), P("FF92C2"), P("F06AA6"), P("FFF0F6")
LEAF, LEAF_D, BARK = P("6CBF5B"), P("4F9E47"), P("7A4A33")
RED, DARKW, WOOD = P("E2453B"), P("3B2B2E"), P("C68A5A")
CREAM, STONE, MOSS = P("F0E4CF"), P("BDB4A8"), P("86BF5E")
ROCK_A, ROCK_B = P("CDBDAE"), P("AE9C8F")
GLOW, GOLD, INK = P("FFD27A", "NE"), P("FFC94A"), P("2A2433")
WATER = P("7FD6EA", "GL", 0.25)
ROOF = P("4E5873")
MOUNT, SNOWC = P("B7AECF"), P("FFFFFF")
CLOUD, CLOUD_P = P("FFFFFF"), P("FFF1F7")
TURF = P("7AB45C", "GR")
models = []
def add(m): models.append(m); return m
X = [0]
def at(w):  # lay models out along X in the .blend so they don't overlap
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 10; return p

# 1) Island underside for the 260 x 100 strip (origin = strip centre at ground level)
isl = add(Model("SakuraIsland", at=at(320)))
island_se(isl, ROCK_A, a=150, b=62, depth=78, n=4, seed=11, seg=56, rings=8, part="Rock", top=-0.6, tip=(10, -6))
turf_se(isl, TURF, a=151, b=63, n=4, thick=0.6, seg=56, part="Turf", top=-0.3)
rnd = random.Random(5)
for i in range(9):   # hanging rocks under the island
    ang = rnd.uniform(0, 6.283); r = rnd.uniform(0.35, 0.8)
    rock(isl, ROCK_B, (math.cos(ang) * 120 * r, math.sin(ang) * 48 * r, -20 - rnd.uniform(0, 30)), (rnd.uniform(6, 12), rnd.uniform(6, 11), rnd.uniform(9, 16)), seed=i, part="Hang")
isl.flat("Rock", ROCK_A, 30); isl.flat("Hang", ROCK_B, 30)

# 2) Rim rocks with moss and a blossom tuft (placed along the island edge, outside the hedges)
rim = add(Model("SakuraRimRocks", at=at(16)))
rock(rim, ROCK_A, (0, 0, 1.2), (4.5, 3.6, 3.0), seed=2, part="Rocks")
rock(rim, ROCK_B, (-4.6, 1.0, 0.8), (3.0, 2.6, 2.2), seed=3, part="Rocks2")
rock(rim, ROCK_A, (4.4, -0.6, 0.6), (2.6, 2.2, 1.7), seed=4, part="Rocks")
sphere(rim, MOSS, (0.2, 0.2, 3.6), 3.4, scl=(1, 0.8, 0.28), part="Moss")
sphere(rim, MOSS, (-4.6, 1.0, 2.6), 2.2, scl=(1, 0.85, 0.3), part="Moss")
blob(rim, PINK_M, (2.8, 1.4, 3.9), rad=1.7, n=4, seed=8, flat=0.8, part="Blossom")
rim.flat("Rocks", ROCK_A, 25); rim.flat("Rocks2", ROCK_B, 25)

# 3) Background mountains (base sits in the cloud sea far below the island)
def mountain(name, h, r0, seed, patches):
    m = add(Model(name, at=at(r0 * 2.2)))
    lathe(m, MOUNT, [(r0, 0), (r0 * .88, h * .14), (r0 * .66, h * .36), (r0 * .46, h * .58), (r0 * .28, h * .78), (r0 * .13, h * .92), (0, h)], seg=14, wob=0.09, seed=seed, part="Rock")
    lathe(m, SNOWC, [(r0 * .305, h * .765), (r0 * .2, h * .85), (r0 * .1, h * .935), (0, h + .6)], seg=14, wob=0.09, seed=seed, part="Snow")
    rr = random.Random(seed)
    for i in range(patches):
        a = rr.uniform(0, 6.283); t = rr.uniform(0.06, 0.4)
        rad = r0 * (1 - t * 1.35) * 0.98
        blob(m, PINK_M if i % 3 else PINK_L, (math.cos(a) * rad, math.sin(a) * rad, h * t), rad=r0 * 0.11, n=3, seed=i + seed, flat=0.7, seg=8, rings=5, part="Blossom")
    m.flat("Rock", MOUNT, 28)
    return m
mountain("SakuraMountainA", 150, 70, 21, 14)
mountain("SakuraMountainB", 105, 58, 34, 10)

# 4) Clouds (flat bottoms)
for name, rad, n, seed, col in (("SakuraCloudA", 8.5, 7, 41, CLOUD), ("SakuraCloudB", 5.5, 5, 43, CLOUD_P)):
    c = add(Model(name, at=at(rad * 4)))
    blob(c, col, (0, 0, rad * 0.25), rad=rad, n=n, seed=seed, spread=(1.9, 0.9, 0.35), flat=0.62, part="Puff")
    clamp_z(c, "Puff", col, 0.0)

# 5) Flowering bushes
for name, base, fl, seed, rad in (("BlossomBushA", LEAF, PINK_M, 3, 2.6), ("BlossomBushB", PINK_L, PINK_D, 9, 2.0)):
    b = add(Model(name, at=at(rad * 3)))
    blob(b, base, (0, 0, rad * .62), rad=rad, n=5, seed=seed, flat=.78, part="Leaves")
    rr = random.Random(seed)
    for i in range(16):
        a = rr.uniform(0, 6.283); el = rr.uniform(0.25, 1.25)
        p = (math.cos(a) * math.cos(el) * rad * 1.05, math.sin(a) * math.cos(el) * rad * 1.05, rad * .62 + math.sin(el) * rad * .82)
        flower(b, fl if i % 4 else PETAL, GOLD, p, rr.uniform(.55, .8), rot=(0, 90 - math.degrees(el), math.degrees(a)))

# 6) Stepping stone
st = add(Model("SteppingStone", at=at(5)))
rock(st, CREAM, (0, 0, 0.18), (1.7, 1.4, 0.5), seed=6, sub=2, jag=0.1, part="Stone", flatz=-0.3)
st.flat("Stone", CREAM, 40)

# 7) Pond koi (decor) - body along -Y, seen from above
def koi(name, body, spot, spot2):
    m = add(Model(name, at=at(5)))
    lathe(m, body, [(0, 0), (.28, .25), (.5, .9), (.62, 1.6), (.6, 2.1), (.45, 2.6), (.22, 2.95), (0, 3.05)], loc=(0, 1.5, .55), rot=(90, 0, 0), seg=14, sy=.72, part="Body")
    prism(m, body, [(-0.05, 0), (.9, .75), (.55, .2), (.95, -.2), (-.05, -.15)], .12, loc=(0, 1.45, .5), rot=(0, 0, 90), part="Tail")
    prism(m, body, [(0.05, 0), (-.9, .75), (-.55, .2), (-.95, -.2), (0.05, -.15)], .12, loc=(0, 1.45, .5), rot=(0, 0, 90), part="Tail")
    for s in (-1, 1):
        sphere(m, body, (s * .62, -.2, .45), .38, scl=(1, .6, .15), part="Fins")
        sphere(m, INK, (s * .33, -1.15, .72), .11, part="Eyes")
    sphere(m, spot, (.12, -.6, .86), .42, scl=(1, 1.3, .35), part="Spots")
    sphere(m, spot2, (-.18, .45, .84), .36, scl=(1.1, 1.2, .35), part="Spots2")
    return m
koi("PondKoiA", P("FFF6EE"), P("FF7A2E"), P("FF7A2E"))
koi("PondKoiB", P("FF7A2E"), P("FFF6EE"), P("2A2433"))
koi("GoldenKoi", P("FFC94A", "FO"), P("FFE38A"), P("FFE38A"))

# 8) Tea pavilion (front -Y)
tp = add(Model("TeaPavilion", at=at(26)))
rbox(tp, STONE, (0, 0, 0), (12, 12, 1.2), r=.3, base=True, part="Base")
rbox(tp, STONE, (0, -6.8, 0), (5, 1.8, .6), r=.15, base=True, part="Base")
rbox(tp, WOOD, (0, 0, 1.2), (11, 11, .3), r=.08, base=True, part="Deck")
for sx in (-1, 1):
    for sy in (-1, 1):
        cyl(tp, RED, (sx * 4.7, sy * 4.7, 1.5), r=.36, h=6.2, seg=10, part="Posts")
for sy in (-1, 1):
    rbox(tp, RED, (0, sy * 4.7, 7.5), (10.4, .6, .6), r=.1, part="Beams")
    rbox(tp, RED, (sy * 4.7, 0, 7.5), (.6, 10.4, .6), r=.1, part="Beams")
for sx in (-1, 1):   # side + back railings
    rbox(tp, RED, (sx * 4.7, 0, 2.6), (.25, 9, .25), r=.06, part="Rail")
rbox(tp, RED, (0, 4.7, 2.6), (9, .25, .25), r=.06, part="Rail")
lathe(tp, ROOF, [(11.4, 7.75), (10.6, 8.0), (7.5, 9.1), (4.4, 10.6), (1.4, 12.1), (0, 12.5)], seg=4, rot=(0, 0, 45), part="Roof")
lathe(tp, RED, [(11.35, 7.55), (11.5, 7.8), (0.01, 7.8)], seg=4, rot=(0, 0, 45), part="Trim")
sphere(tp, GOLD, (0, 0, 12.6), .55, part="Finial"); cyl(tp, GOLD, (0, 0, 12.4), r=.18, h=1.2, seg=8, part="Finial")
rbox(tp, WOOD, (0, 0, 1.5), (3.2, 3.2, .3), r=.1, base=True, part="Table")
rbox(tp, P("8A5A3C"), (0, 0, 1.8), (3.4, 3.4, .22), r=.08, base=True, part="TableTop")
sphere(tp, P("6FB7A8"), (0, 0, 2.45), .5, scl=(1, 1, .8), part="Teapot")
tube(tp, P("6FB7A8"), [(0, -.4, 2.4), (0, -.75, 2.55), (0, -.95, 2.8)], r=.1, seg=8, smooth=3, part="Teapot")
for a in (0, 2.1, 4.2):
    cyl(tp, PETAL, (math.cos(a) * 1.1, math.sin(a) * 1.1 + .2, 2.02), r=.22, r2=.27, h=.3, seg=10, part="Cups")
for p in ((0, -2.6), (0, 2.6), (-2.6, 0), (2.6, 0)):
    rbox(tp, PINK_M, (p[0], p[1], 1.5), (1.8, 1.8, .45), r=.2, base=True, part="Cushions")
for sx in (-1, 1):
    sphere(tp, GLOW, (sx * 4.7, -4.7, 6.3), .55, scl=(1, 1, 1.25), part="Lanterns")
    cyl(tp, DARKW, (sx * 4.7, -4.7, 6.95), r=.06, h=.6, seg=6, part="Strings")

# 9) Koi shrine (activity): stone base, small roof, golden koi on a wave
ks = add(Model("KoiShrine", at=at(8)))
lathe(ks, STONE, [(2.4, 0), (2.4, .5), (2.0, .7), (1.5, .9), (1.4, 2.6), (1.8, 2.9), (1.8, 3.2), (0.01, 3.2)], seg=8, part="Pedestal")
cyl(ks, P("6FD3E6"), (0, 0, 3.2), r=1.3, r2=.9, h=.5, seg=12, part="Wave")
lathe(ks, PETAL, [(0.9, 3.65), (0.6, 4.0), (0.01, 4.05)], seg=12, part="Foam")
for sx in (-1, 1):
    cyl(ks, RED, (sx * 2.0, 0, 0.5), r=.22, h=6.8, seg=8, part="Posts")
rbox(ks, RED, (0, 0, 7.0), (5.6, .5, .4), r=.08, part="Lintel")
rbox(ks, DARKW, (0, 0, 7.45), (6.6, .7, .4), r=.12, part="Kasagi")
for sx in (-1, 1):
    sphere(ks, GLOW, (sx * 2.0, -.45, 5.7), .35, part="Bells")


objs = realize(models, 'W2_Sakura_Scenery')
