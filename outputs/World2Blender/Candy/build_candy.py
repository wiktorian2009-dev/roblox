import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random
from mathutils import Vector

# Candy Kingdom pack (World 2, stage 10) - Claude 2026-10-02. Units = studs, front = -Y (Roblox -Z).
from w2lib import *
STRAW, STRAW_D, PINK_L = P("FF7FB0"), P("F2558F"), P("FFC2DA")
MINT, MINT_D, CREAM, VAN = P("8FE8C8"), P("4FCFA2"), P("FFF3DC"), P("FFE9B8")
CHOC, CHOC_D, CHOC_L = P("7A4A2E"), P("5A3420"), P("A0663F")
LEMON, ORANGE, GRAPE, SKY, RED, WHITE = P("FFE36E"), P("FFA94D"), P("C9A7FF"), P("8FD3FF"), P("FF4D6D"), P("FFFFFF")
WAFER, WAFER_D, INK, BLUSH = P("E9B872"), P("C99550"), P("2A2433"), P("FF9BB5")
SUG = lambda h: P(h, "SA")            # sugar-coated (Sand material)
GLOWP, GLOWY = P("FF9CCB", "NE"), P("FFE38A", "NE")
RAINBOW = [P("FF4D6D"), P("FFE36E"), P("8FD3FF"), P("8FE8C8"), P("C9A7FF"), P("FFA94D")]
models = []
X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 10; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def gumdrop(m, pc, loc, r, h, part="Gumdrops", seg=14):
    lathe(m, pc, [(r, 0), (r * .98, h * .22), (r * .86, h * .55), (r * .58, h * .85), (r * .2, h * .99), (0, h)], loc=loc, seg=seg, part=part)
def swirl_top(m, pc, loc, r, n=3, part="Frosting"):
    z = loc[2]
    for i in range(n):
        rr = r * (1 - i * .27); torus(m, pc, (loc[0], loc[1], z + rr * .38), R=rr * .72, r=rr * .38, seg=20, rseg=8, part=part); z += rr * .55
    lathe(m, pc, [(r * .3, 0), (r * .12, r * .35), (0, r * .5)], loc=(loc[0], loc[1], z + r * .1), seg=10, part=part)
    return z + r * .55
def lollipop_disc(m, base, swirl, loc, R, thick=.7, part="Disc", spart="Swirl"):
    cyl(m, base, (loc[0], loc[1] + thick / 2, loc[2]), r=R, h=thick, seg=28, rot=(90, 0, 0), bev=.2, part=part)
    for side in (-1, 1):
        pts = []
        for k in range(70):
            t = k / 69; a = t * 3 * 2 * math.pi; rr = .25 + (R - .45) * t
            pts.append((loc[0] + rr * math.cos(a), loc[1] + side * (thick / 2 + .02), loc[2] + rr * math.sin(a)))
        tube(m, swirl, pts, r=.26, seg=6, smooth=1, sq=.35, part=spart)

# 1) Cake island: frosting top layer, sponge band, chocolate cone with drips
isl = add("CandyIsland", 320)
turf_se(isl, PINK_L, a=152, b=64, n=4, thick=1.4, seg=56, part="Frosting", top=-0.3)
turf_se(isl, VAN, a=149, b=61.5, n=4, thick=5.0, seg=56, part="Sponge", top=-1.7)
island_se(isl, CHOC, a=147, b=60, depth=74, n=4, seed=31, seg=56, rings=7, jag=0.08, part="Choc", top=-6.6, tip=(-8, 5))
rr = random.Random(4)
for i in range(46):
    ang = 2 * math.pi * i / 46 + rr.uniform(-.04, .04); x, y = se_point(152.5, 64.5, ang, 4.0)
    sphere(isl, PINK_L, (x, y, -1.8 - rr.uniform(0, 1.2)), rr.uniform(1.0, 1.8), scl=(1, 1, rr.uniform(1.6, 2.6)), seg=8, rings=6, part="Drips")
for i in range(7):
    a = rr.uniform(0, 6.283); k = rr.uniform(.3, .7)
    sphere(isl, CHOC_L, (math.cos(a) * 110 * k, math.sin(a) * 42 * k, -30 - rr.uniform(0, 25)), rr.uniform(5, 8), scl=(1, 1, 1.5), part="Bonbons")
isl.flat("Choc", CHOC, 32)

# 2) Rim decorations: frosting dollops with gumdrops
rim = add("CandyRim", 16)
for i, (x, y, r) in enumerate([(0, 0, 2.6), (-4.2, .8, 1.9), (4.0, -.6, 2.0)]):
    torus(rim, CREAM if i != 1 else PINK_L, (x, y, r * .35), R=r * .75, r=r * .42, seg=18, rseg=8, part="Dollops")
    swirl_top(rim, CREAM if i != 1 else PINK_L, (x, y, r * .5), r * .8, n=2, part="Dollops")
for i, (x, y) in enumerate([(-2.0, -1.9), (2.2, 1.9), (6.0, 1.0), (-6.3, -1.0)]):
    gumdrop(rim, SUG(["FF4D6D", "FFE36E", "8FD3FF", "C9A7FF"][i][0:6]), (x, y, 0), 1.0, 1.4, part="Gumdrops")

# 3) Lollipop tree (swirl recoloured per instance in Studio)
lol = add("LollipopTree", 8)
cyl(lol, CREAM, (0, 0, 0), r=.32, h=10.5, seg=10, part="Stick")
lollipop_disc(lol, WHITE, STRAW, (0, 0, 13.2), 3.3)
torus(lol, MINT, (0, 0, 10.0), R=.55, r=.2, seg=14, rseg=6, part="Bow")
sphere(lol, MINT, (.75, -.1, 10.1), .45, scl=(1, .5, .7), part="Bow"); sphere(lol, MINT, (-.75, -.1, 10.1), .45, scl=(1, .5, .7), part="Bow")

# 4) Gumdrop bush (sugar-coated cluster; recolourable parts)
gb = add("GumdropBush", 8)
for i, (x, y, r) in enumerate([(0, 0, 1.7), (1.9, .9, 1.2), (-1.8, .6, 1.3), (.6, -1.6, 1.1), (-.9, 1.9, 1.0)]):
    gumdrop(gb, SUG(["FF7FB0", "8FE8C8", "FFE36E", "C9A7FF", "FFA94D"][i]), (x, y, 0), r, r * 1.35, part="Drop" + str(i))
gb.flat("Drop0", SUG("FF7FB0"), 50)

# 5) Chocolate river ribbon + wafer bridge
riv = add("ChocoRiver", 110)
pts = [(math.sin(t * .09) * 3.2, -52 + t, .06) for t in range(0, 105, 3)]
for side, col in ((-1, CREAM), (1, CREAM)):
    tube(riv, col, [(p[0] + side * 4.6, p[1], .25) for p in pts], r=.7, seg=8, smooth=2, sq=.5, part="Banks")
poly = [(p[0] - 4.2, p[1]) for p in pts] + [(p[0] + 4.2, p[1]) for p in reversed(pts)]
prism(riv, CHOC, poly, .12, loc=(0, 0, .02), part="Choc")
br = add("WaferBridge", 16)
rbox(br, WAFER, (0, 0, 0), (14, 8.4, .9), r=.2, base=True, part="Deck")
for k in range(-6, 7, 2): rbox(br, WAFER_D, (k, 0, .9), (.25, 8.2, .12), r=.05, base=True, part="Grooves")
for sy in (-1, 1):
    rbox(br, WAFER, (0, sy * 4.0, 1.9), (14, .5, .6), r=.2, part="Rails")
    for k in (-6.5, -3.25, 0, 3.25, 6.5):
        cyl(br, STRAW, (k, sy * 4.0, .9), r=.28, h=1.4, seg=8, part="Posts")
        gumdrop(br, SUG("FFE36E"), (k, sy * 4.0, 2.2), .45, .6, part="PostTops")

# 6) Cupcake stall
cs = add("CupcakeStall", 12)
lathe(cs, MINT, [(3.2, 0), (3.5, 3.6), (3.7, 3.8), (0.01, 3.8)], seg=24, rib=(12, .05), part="Wrapper")
rbox(cs, WAFER, (0, -3.6, 0), (6.2, 1.6, 3.0), r=.25, base=True, part="Counter")
rbox(cs, PINK_L, (0, -3.6, 3.0), (6.6, 2.0, .35), r=.15, base=True, part="CounterTop")
for sx in (-1, 1): cyl(cs, CREAM, (sx * 2.9, -3.9, 3.35), r=.22, h=3.6, seg=8, part="Poles")
lathe(cs, STRAW, [(4.6, 6.6), (4.2, 7.3), (3.0, 8.4), (1.6, 9.4), (0, 9.9)], seg=24, wob=.02, part="Roof")
torus(cs, CREAM, (0, 0, 6.65), R=4.4, r=.42, seg=28, rseg=8, part="RoofTrim")
sphere(cs, RED, (0, 0, 10.4), .75, part="Cherry"); tube(cs, P("4F9E47"), [(0, 0, 11.0), (.3, .2, 11.8), (.8, .3, 12.3)], r=.08, seg=6, smooth=3, part="CherryStem")
for i, x in enumerate((-1.8, 0, 1.8)):
    lathe(cs, CREAM, [(.42, 3.35), (.5, 3.85), (0.01, 3.85)], loc=(x, -3.7, 0), seg=10, part="MiniCupcakes")
    sphere(cs, [STRAW, GRAPE, MINT][i], (x, -3.7, 4.05), .45, scl=(1, 1, .7), part="MiniFrost" + str(i))
for sx in (-1, 1): sphere(cs, GLOWP, (sx * 2.9, -3.9, 6.6), .35, part="Lights")

# 7) Candy cane lamp with glowing gumdrop
cl = add("CandyCaneLamp", 6)
pts = [(0, 0, 0), (0, 0, 7.5)] + [(math.cos(a) * 1.2 - 1.2 + 1.2, 0, 7.5 + math.sin(a) * 1.2) for a in [x * math.pi / 8 for x in range(0, 9)]]
pts = [(0, 0, 0), (0, 0, 7.6)] + [(1.2 - math.cos(a) * 1.2, 0, 7.6 + math.sin(a) * 1.2) for a in [x * math.pi / 8 for x in range(1, 9)]]
stripes(cl, [RED, WHITE], pts, r=.3, seglen=.9, seg=10, part="Cane", smooth=1)
lathe(cl, GLOWP, [(.55, 0), (.5, .4), (.32, .8), (0, 1.0)], loc=(2.4, 0, 6.2), rot=(180, 0, 0), seg=12, part="Light")
cyl(cl, CREAM, (0, 0, 0), r=.8, h=.4, seg=14, bev=.12, part="Base")

# 8) Gummy bear statue (translucent jelly; recoloured per instance)
gy = add("GummyBear", 6)
J = P("FF4D6D", "SP", 0.12)
sphere(gy, J, (0, 0, 1.9), 1.55, scl=(1, .9, 1.1), part="Jelly")
sphere(gy, J, (0, -.1, 4.15), 1.25, scl=(1.05, .95, .95), part="Jelly")
for s in (-1, 1):
    sphere(gy, J, (s * .95, 0, 5.15), .5, scl=(1, .6, 1), part="Jelly")
    sphere(gy, J, (s * 1.3, -.5, 2.6), .52, scl=(.8, .8, 1.2), part="Jelly")
    sphere(gy, J, (s * .75, -.6, .4), .62, scl=(1, 1.2, .7), part="Jelly")
    sphere(gy, INK, (s * .45, -1.1, 4.35), .17, scl=(.8, .45, 1.1), part="Eyes")
    sphere(gy, WHITE, (s * .45 - .05, -1.18, 4.43), .06, part="Shine")
sphere(gy, P("FF8FA8", "SP", .12), (0, -1.05, 3.85), .42, scl=(1.1, .5, .7), part="Muzzle")
sphere(gy, INK, (0, -1.25, 3.95), .12, part="Nose")

# 9) Checkered path tile (8 x 8)
pt = add("CandyPathTile", 9)
for i, (x, y) in enumerate([(-2, -2), (2, 2), (2, -2), (-2, 2)]):
    rbox(pt, PINK_L if i < 2 else CREAM, (x, y, 0), (3.92, 3.92, .3), r=.12, base=True, part="TileA" if i < 2 else "TileB")

# 10) Clouds + mountains
for name, col, seed in (("CottonCloudPink", P("FFC2DA"), 3), ("CottonCloudBlue", P("BFE6FF"), 5)):
    c = add(name, 34)
    blob(c, col, (0, 0, 2.2), rad=8, n=7, seed=seed, spread=(1.9, .9, .35), flat=.62, part="Puff")
    clamp_z(c, "Puff", col, 0.0)
cm = add("ChocoMountain", 150)
lathe(cm, CHOC, [(66, 0), (58, 20), (45, 48), (30, 76), (16, 98), (6, 110), (0, 113)], seg=16, wob=.07, seed=4, part="Choc")
lathe(cm, CREAM, [(28.6, 81.0), (19.6, 95.0), (8.4, 107.5), (0, 114.6)], seg=16, wob=.05, seed=4, part="Frosting")
for i in range(16):
    a = 2 * math.pi * i / 16; z = 80 + (i % 3) * 2; r = 29.0 - (z - 80) * .6
    sphere(cm, CREAM, (math.cos(a) * r, math.sin(a) * r, z - 2.5), 2.4, scl=(1, 1, 2.0), seg=8, rings=6, part="Frosting")
rq = random.Random(9)
for i in range(30):
    a = rq.uniform(0, 6.283); z = rq.uniform(86, 106); r = (113 - z) * 0.9 + 1
    tube(cm, RAINBOW[i % 6], [(math.cos(a) * r, math.sin(a) * r, z), (math.cos(a) * r, math.sin(a) * r, z + 2.2)], r=.6, seg=6, smooth=1, part="Sprinkle" + str(i % 6))
cm.flat("Choc", CHOC, 30)
ih = add("IceCreamHill", 120)
lathe(ih, MINT, [(52, 0), (48, 16), (38, 36), (22, 52), (0, 58)], seg=18, wob=.05, seed=7, part="Hill")
for i, (x, y, z, r, c) in enumerate([(0, 0, 56, 14, STRAW), (-11, 4, 50, 10, CREAM), (10, -3, 50, 10, P("C9A7FF"))]):
    sphere(ih, c, (x, y, z), r, scl=(1, 1, .8), part="Scoop" + str(i))
sphere(ih, RED, (0, 0, 69), 3.2, part="Cherry")

# 11) Giant gumdrop (jump route) + giant cupcake platform + sugar chest (activity)
gg = add("GiantGumdrop", 8)
gumdrop(gg, SUG("FF7FB0"), (0, 0, 0), 2.9, 3.0, part="Drop", seg=18)
gc = add("GiantCupcake", 20)
lathe(gc, P("FF9CCB"), [(7.0, 0), (7.8, 12.0), (8.1, 12.4), (0.01, 12.4)], seg=28, rib=(16, .04), part="Wrapper")
for i, rr2 in enumerate((8.6, 7.4, 5.8)):
    torus(gc, CREAM, (0, 0, 13.4 + i * 1.9), R=rr2 * .78, r=rr2 * .3, seg=28, rseg=10, part="FrostRing" + str(i))
lathe(gc, CREAM, [(8.0, 12.4), (7.2, 15.8), (0.01, 16.0)], seg=28, part="FrostTop")
sphere(gc, RED, (3.6, 3.6, 17.2), 1.2, part="Cherry")
rq = random.Random(12)
for i in range(26):
    a = rq.uniform(0, 6.283); d = rq.uniform(5.8, 8.6); z = 13.2 + rq.uniform(0, 2.2)
    tube(gc, RAINBOW[i % 6], [(math.cos(a) * d, math.sin(a) * d, z), (math.cos(a + .08) * d, math.sin(a + .08) * d, z + .5)], r=.2, seg=6, smooth=1, part="Sprinkle" + str(i % 6))
ch = add("SugarChest", 6)
rbox(ch, STRAW, (0, 0, 0), (3.4, 2.4, 1.8), r=.25, base=True, part="Box")
lathe(ch, STRAW_D, [(1.75, 0), (1.75, .6), (1.2, 1.1), (0.01, 1.25)], loc=(0, 0, 1.8), seg=4, rot=(0, 0, 45), sx=1.0, sy=.7, part="Lid")
rbox(ch, LEMON, (0, -1.25, 1.4), (.9, .25, 1.0), r=.1, part="Lock")
for x in (-1.2, 1.2): rbox(ch, LEMON, (x, 0, .9), (.3, 2.5, 1.9), r=.08, part="Bands")
sphere(ch, GLOWY, (0, 0, 3.3), .5, part="Sparkle")

# 12) Candy-cane gate arch (Sakura -> Candy); posts split L/R for collision, sign on top
gt = add("CandyGate", 22)
for side, nm in ((-1, "PostL"), (1, "PostR")):
    pts = [(side * 8.6, 0, 0), (side * 8.6, 0, 12.0)] + [(side * (8.6 - 3.0 + math.cos(a) * 3.0), 0, 12.0 + math.sin(a) * 3.0) for a in [k * math.pi / 10 for k in range(1, 11)]]
    stripes(gt, [RED, WHITE], pts, r=.75, seglen=1.6, seg=12, part=nm, smooth=1)
    cyl(gt, CREAM, (side * 8.6, 0, 0), r=1.4, h=.8, seg=16, bev=.2, part="Bases")
    gumdrop(gt, SUG("8FE8C8"), (side * 8.6, 0, .8), 1.0, 1.0, part="BaseDrops")
sphere(gt, P("FF7FB0"), (0, 0, 16.2), 3.0, scl=(1.5, .9, 1.0), part="Candy")
for s2 in (-1, 1):
    lathe(gt, P("FFE36E"), [(.01, 0), (1.2, 1.6), (1.6, 2.4), (.6, 2.6), (0.01, 2.62)], loc=(s2 * 4.4, 0, 16.2), rot=(0, s2 * 90, 0), seg=10, part="Wrap")
    torus(gt, P("FFE36E"), (s2 * 4.3, 0, 16.2), R=.6, r=.25, rot=(0, 90, 0), seg=12, rseg=6, part="Wrap")
heartp = heart_poly(1.6)
prism(gt, RED, heartp, .4, loc=(0, -2.8, 15.6), rot=(90, 0, 0), part="Heart")

# 13) Candy castle (landmark). Door opening 11 x 13 at x=0; every block that frames it is its own part.
cc = add("CandyCastle", 50)
rbox(cc, PINK_L, (-13.25, 0, 0), (15.5, 12, 17), r=.8, base=True, part="WingL")
rbox(cc, PINK_L, (13.25, 0, 0), (15.5, 12, 17), r=.8, base=True, part="WingR")
rbox(cc, PINK_L, (0, 0, 13.0), (11.6, 12, 4.0), r=.5, base=True, part="Lintel")
for sx in (-1, 1):
    arc = [(sx * (5.5 * math.cos(math.radians(a))), 7.5 + 5.5 * math.sin(math.radians(a))) for a in range(0, 91, 10)]
    poly = arc + [(0, 13.05), (sx * 5.55, 13.05)]
    if sx < 0: poly = list(reversed(poly))
    prism(cc, PINK_L, poly, 12, loc=(0, 6, 0), rot=(90, 0, 0), part="Spandrel" + ("L" if sx < 0 else "R"))
torus(cc, CREAM, (0, -6.3, 7.5), R=5.6, r=.75, arc=180, seg=24, rseg=8, rot=(90, 0, 0), part="ArchTrim")
for sx in (-1, 1): rbox(cc, CREAM, (sx * 5.85, -6.3, 0), (1.3, .9, 7.5), r=.3, base=True, part="DoorTrim")
rbox(cc, WAFER, (0, -9.2, 0), (10.6, 6.4, .45), r=.15, base=True, part="Drawbridge")
for k in range(-4, 5, 2): rbox(cc, WAFER_D, (k, -9.2, .45), (.2, 6.2, .08), r=.04, base=True, part="Grooves")
for sx in (-1, 1):
    for sy, h in ((-1, 0), (1, 0)):
        pass
# corner towers
TW = [(-19.5, -5.5, 4.2, 23, "TowerFL", MINT), (19.5, -5.5, 4.2, 23, "TowerFR", MINT), (-17.0, 5.5, 3.8, 28, "TowerBL", STRAW), (17.0, 5.5, 3.8, 28, "TowerBR", STRAW)]
for (x, y, r, h, nm, col) in TW:
    cyl(cc, col, (x, y, 0), r=r, h=h, seg=24, bev=.4, part=nm)
    torus(cc, CREAM, (x, y, h - .2), R=r * .98, r=.55, seg=24, rseg=8, part="TowerFrost")
    for i in range(10):
        a = 2 * math.pi * i / 10
        sphere(cc, CREAM, (x + math.cos(a) * r * .99, y + math.sin(a) * r * .99, h - 1.4), .55, scl=(1, 1, 2.1), seg=8, rings=6, part="TowerFrost")
    if nm.startswith("TowerF"):
        top = swirl_top(cc, CREAM, (x, y, h), r * .9, n=3, part="SwirlRoof")
        sphere(cc, RED, (x, y, top + .2), .9, part="Cherries")
    else:
        lathe(cc, WAFER, [(r * 1.18, h), (r * .7, h + 4.5), (0, h + 9.5)], loc=(x, y, 0), seg=16, part="ConeRoof")
        sphere(cc, P("FF9CCB"), (x, y, h + 9.6), 1.5, part="Scoops")
        cyl(cc, CREAM, (x, y, h + 10.7), r=.15, h=4.0, seg=6, part="FlagPoles")
        prism(cc, MINT, [(0, 0), (2.6, -.7), (0, -1.4)], .15, loc=(x + .1, y, h + 14.6), rot=(90, 0, 0), part="Flags")
    for wz in (h * .45, h * .72):
        rbox(cc, CHOC_D, (x, y - r * .93, wz), (1.4, .6, 2.2), r=.5, part="Windows")
# central keep behind the gate + giant lollipop crown
cyl(cc, GRAPE, (0, 3.5, 16.5), r=5.6, h=16, seg=28, bev=.5, part="Keep")
torus(cc, CREAM, (0, 3.5, 32.3), R=5.5, r=.7, seg=28, rseg=8, part="KeepFrost")
top = swirl_top(cc, CREAM, (0, 3.5, 32.3), 5.0, n=3, part="KeepRoof")
cyl(cc, CREAM, (0, 3.5, top), r=.4, h=5.5, seg=8, part="CrownStick")
lollipop_disc(cc, WHITE, STRAW, (0, 3.5, top + 8.2), 3.4, part="CrownDisc", spart="CrownSwirl")
for i in range(3): rbox(cc, CHOC_D, (0, 3.5 - 5.45, 20 + i * 4), (1.6, .6, 2.4), r=.6, part="Windows")
# battlements: rainbow gumdrops along the front wall tops
for sx in (-1, 1):
    for k in range(5):
        x = sx * (7.2 + k * 2.9)
        gumdrop(cc, SUG(["FF4D6D", "FFE36E", "8FD3FF", "8FE8C8", "C9A7FF"][k]), (x, -4.8, 17), .95, 1.4, part="Battlement" + str(k))
for k in range(3): gumdrop(cc, SUG(["FFE36E", "FF4D6D", "8FD3FF"][k]), ((k - 1) * 3.2, -4.8, 17), .9, 1.3, part="Battlement" + str(k))
prism(cc, RED, heart_poly(1.9), .5, loc=(0, -6.05, 15.0), rot=(90, 0, 0), part="Heart")
for sx in (-1, 1):
    for wz in (5.0, 11.0):
        for wx in (9.5, 16.5):
            rbox(cc, CHOC_D, (sx * wx, -6.05, wz), (2.2, .5, 2.8), r=.7, part="Windows")
            rbox(cc, CREAM, (sx * wx, -6.0, wz), (2.9, .3, 3.5), r=.9, part="WindowFrames")
    pts = [(sx * 7.0, -7.2, 0), (sx * 7.0, -7.2, 9.0)] + [(sx * (7.0 - 1.1 + math.cos(a) * 1.1), -7.2, 9.0 + math.sin(a) * 1.1) for a in [k * math.pi / 8 for k in range(1, 9)]]
    stripes(cc, [RED, WHITE], pts, r=.45, seglen=1.1, seg=10, part="DoorCanes" + ("L" if sx < 0 else "R"), smooth=1)
cc.flat("Keep", GRAPE, 40)

# 14) Candy egg on a cupcake pedestal (Shell + EggArt decor)
egg = add("CandyEgg", 6)
lathe(egg, MINT, [(2.4, 0), (2.7, 2.4), (2.85, 2.6), (0.01, 2.6)], seg=24, rib=(12, .05), part="Pedestal")
torus(egg, CREAM, (0, 0, 2.75), R=2.2, r=.55, seg=24, rseg=8, part="Cushion")
PROF = [(0, 0), (1.0, .12), (1.6, .6), (1.95, 1.4), (2.05, 2.2), (1.95, 3.0), (1.65, 3.8), (1.1, 4.5), (.5, 4.88), (0, 5.0)]
Z0 = 2.75
lathe(egg, P("FFD1E3"), PROF, loc=(0, 0, Z0), seg=28, part="Shell")
def rad_at(h):
    for (r1, z1), (r2, z2) in zip(PROF, PROF[1:]):
        if z1 <= h <= z2: return r1 + (r2 - r1) * (h - z1) / max(1e-6, z2 - z1)
    return 0
lathe(egg, CREAM, [(1.72, 3.65), (1.2, 4.45), (.55, 4.86), (0, 5.06)], loc=(0, 0, Z0), seg=28, part="Frosting")
for i in range(12):
    a = 2 * math.pi * i / 12; h = 3.55 - (i % 3) * .35; r = rad_at(h) + .05
    sphere(egg, CREAM, (math.cos(a) * r, math.sin(a) * r, Z0 + h - .15), .32, scl=(1, 1, 1.9), seg=8, rings=6, part="Frosting")
sphere(egg, RED, (0, 0, Z0 + 5.45), .5, part="Cherry")
rq = random.Random(21)
for i in range(46):
    h = rq.uniform(.6, 3.2); a = rq.uniform(0, 6.283); r = rad_at(h) + .04
    p0 = Vector((math.cos(a) * r, math.sin(a) * r, Z0 + h)); tdir = Vector((-math.sin(a), math.cos(a), 0)).lerp(Vector((0, 0, 1)), rq.uniform(0, 1)).normalized() * .22
    tube(egg, RAINBOW[i % 6], [p0 - tdir, p0 + tdir], r=.075, seg=6, smooth=1, part="Sprinkles")

# 15) Pets (face -Y, feet at z=0)
def face(m, y, z, sep=.36, er=.17, blush=True):
    for s in (-1, 1):
        sphere(m, INK, (s * sep, y, z), er, scl=(.8, .45, 1.15), part="Eyes")
        sphere(m, WHITE, (s * sep - .05, y - .08, z + .07), er * .38, part="Shine")
        if blush: sphere(m, BLUSH, (s * (sep + .27), y + .07, z - .23), .14, scl=(1, .35, .6), part="Blush")
gbp = add("Pet_GummyBear", 4)
GJ = P("FF4D6D", "SP", .1)
sphere(gbp, GJ, (0, 0, .9), .95, scl=(1, .9, 1), part="Jelly")
sphere(gbp, GJ, (0, -.1, 2.0), .78, part="Jelly")
for s in (-1, 1):
    sphere(gbp, GJ, (s * .6, -.05, 2.6), .3, scl=(1, .6, 1), part="Jelly")
    sphere(gbp, GJ, (s * .85, -.35, 1.15), .32, scl=(.8, .8, 1.1), part="Jelly")
    sphere(gbp, GJ, (s * .5, -.45, .22), .36, scl=(1, 1.2, .6), part="Jelly")
face(gbp, -.82, 2.1, sep=.28, er=.13)
sphere(gbp, P("FF8FA8", "SP", .1), (0, -.8, 1.82), .3, scl=(1.1, .5, .7), part="Muzzle")
sphere(gbp, INK, (0, -.95, 1.9), .08, part="Nose")
mb = add("Pet_MarshmallowBunny", 4)
MW = P("FFF8F4")
cyl(mb, MW, (0, 0, .1), r=.95, h=1.75, seg=20, bev=.42, part="Body")
for s in (-1, 1):
    cyl(mb, MW, (s * .42, .05, 1.6), r=.27, h=1.25, seg=12, bev=.13, rot=(0, s * 10, 0), part="Ears")
    cyl(mb, P("FFC2DA"), (s * .42, -.15, 1.85), r=.13, h=.85, seg=10, bev=.06, rot=(0, s * 10, 0), part="InnerEars")
    sphere(mb, P("F2B48C"), (s * .62, -.8, .82), .2, scl=(1, .4, .7), part="Toasted")
    sphere(mb, MW, (s * .45, -.55, .15), .28, scl=(1, 1.3, .6), part="Feet")
face(mb, -.93, 1.12, blush=False)
sphere(mb, P("FFC2DA"), (0, -.96, .9), .07, part="Nose")
sphere(mb, MW, (0, .95, .7), .32, part="Tail")
cc2 = add("Pet_CupcakeCat", 4)
lathe(cc2, MINT, [(.7, 0), (.92, 1.0), (.98, 1.08), (0.01, 1.08)], seg=16, rib=(10, .06), part="Wrapper")
sphere(cc2, P("FFB3D1"), (0, 0, 1.75), .95, scl=(1, .95, .9), part="Head")
for s in (-1, 1):
    lathe(cc2, P("FFB3D1"), [(.32, 0), (.12, .45), (0, .55)], loc=(s * .55, 0, 2.45), rot=(0, s * 15, 0), seg=10, part="Ears")
    sphere(cc2, P("FF7FB0"), (s * .55, -.12, 2.62), .12, scl=(1, .4, 1.4), part="InnerEars")
face(cc2, -.85, 1.85, sep=.33, er=.15)
sphere(cc2, P("FF7FB0"), (0, -.92, 1.6), .07, part="Nose")
sphere(cc2, RED, (0, .1, 2.72), .24, part="Cherry")
tube(cc2, P("FFB3D1"), [(0, .7, .6), (.4, 1.1, .9), (.5, 1.2, 1.5)], r=.13, seg=8, smooth=3, part="Tail")
for i in range(10):
    a = 2 * math.pi * i / 10
    tube(cc2, RAINBOW[i % 6], [(math.cos(a) * .55, math.sin(a) * .55, 2.48), (math.cos(a + .2) * .55, math.sin(a + .2) * .55, 2.52)], r=.05, seg=5, smooth=1, part="Sprinkles")
cf = add("Pet_CandyFox", 4)
FO, FC = P("FFA94D"), P("FFF3DC")
sphere(cf, FO, (0, 0, 1.0), .98, scl=(1, .95, .95), part="Body")
sphere(cf, FC, (0, -.6, .8), .55, scl=(1.1, .55, 1), part="Belly")
for s in (-1, 1):
    lathe(cf, FO, [(.36, 0), (.14, .55), (0, .7)], loc=(s * .52, 0, 1.75), rot=(0, s * 16, 0), seg=10, part="Ears")
    sphere(cf, FC, (s * .52, -.15, 1.95), .12, scl=(1, .4, 1.6), part="InnerEars")
    sphere(cf, FO, (s * .45, -.45, .2), .27, scl=(1, 1.3, .6), part="Feet")
face(cf, -.9, 1.15, sep=.34, er=.15)
sphere(cf, INK, (0, -1.0, .95), .08, part="Nose")
pts = [(0, .8, .7), (.2, 1.4, .8)] + [(.2 + math.cos(a) * (.6 - a * .06), 1.75 + math.sin(a) * (.6 - a * .06) * .3, 1.4 + math.sin(a) * (.6 - a * .06)) for a in [k * .5 for k in range(0, 9)]]
stripes(cf, [STRAW, WHITE], pts, r=.2, seglen=.35, seg=8, part="Tail", smooth=1)
sd = add("Pet_SugarDragon", 4)
DM, DB = P("8FE8C8"), P("FFF3DC")
sphere(sd, DM, (0, 0, 1.05), 1.0, scl=(1, .95, .98), part="Body")
sphere(sd, DB, (0, -.52, .85), .6, scl=(1, .55, 1), part="Belly")
for s in (-1, 1):
    pts = [(s * .4, .05, 1.85), (s * .45, .05, 2.25)] + [(s * (.45 + .18 - math.cos(a) * .18), .05, 2.25 + math.sin(a) * .18) for a in [k * math.pi / 6 for k in range(1, 7)]]
    stripes(sd, [RED, WHITE], pts, r=.09, seglen=.18, seg=6, part="Horns", smooth=1)
    sphere(sd, DM, (s * .48, -.35, .2), .27, scl=(1, 1.3, .6), part="Feet")
    sphere(sd, P("C9A7FF"), (s * .98, .45, 1.6), .58, scl=(.16, 1.0, .75), rot=(25, 0, -s * 22), part="Wings")
for i, z in enumerate((1.95, 1.7, 1.35)):
    gumdrop(sd, SUG(["FF7FB0", "FFE36E", "C9A7FF"][i]), (0, .45 + i * .3, z), .2, .3, part="Spikes" + str(i))
tube(sd, DM, [(0, .8, .55), (.3, 1.4, .5), (.55, 1.8, .8), (.5, 2.0, 1.2)], r=.22, r2=.08, seg=8, smooth=3, part="Tail")
lollipop_disc(sd, WHITE, STRAW, (.5, 2.05, 1.55), .42, thick=.12, part="TailPop", spart="TailSwirl")
face(sd, -.9, 1.18, sep=.34, er=.17)
sphere(sd, GLOWP, (0, -.98, .55), .12, part="Glow")

objs = realize(models, 'W2_Candy')
