import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Cosmic Sanctuary pack (World 2, final stage 16) - Claude 2026-10-03. Massive, detailed buildings. Front = -Y (Roblox -Z). R2B for Roblox-frame pieces.
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
NAVY, INDIGO, VIOLET, LAV = P("2E2A5C"), P("3B3480"), P("7E5BEF"), P("B9A6FF")
GOLD, GOLD_D = P("FFD25A", "ME"), P("E0A830", "ME")
CYN, PNK, VIO_N, STARW = P("7FE9FF", "NE"), P("FF8AD8", "NE"), P("A98BFF", "NE"), P("FFF6C8", "NE")
MAR, MAR_D, ROCK, ROCK_D = P("EDE8FF"), P("CFC6F2"), P("4A4078"), P("332B5C")
CRY = [P("9D7BFF"), P("6FD8FF"), P("FF9AD8")]
INK, WH, BLUSH = P("2A2433"), P("FFFFFF"), P("FF9BB5")
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 12; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def star(r1, r2): return [(math.cos(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2), math.sin(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2)) for i in range(10)]
def crystal(m, pc, loc, r, h, part, rot=(0, 0, 0)):
    lathe(m, pc, [(r * .7, 0), (r, h * .12), (r * .95, h * .78), (0, h)], loc=loc, rot=rot, seg=6, part=part)
def face(m, y, z, sep=.36, er=.17):
    for s in (-1, 1):
        sphere(m, INK, (s * sep, y, z), er, scl=(.8, .45, 1.15), part="Eyes"); sphere(m, WH, (s * sep - .05, y - .08, z + .07), er * .38, part="Shine")
        sphere(m, BLUSH, (s * (sep + .27), y + .07, z - .23), .14, scl=(1, .35, .6), part="Blush")
# 1) island: asteroid base (top 0.15 under the floor), gold rim, glowing crystal veins, hanging crystals
isl = add("CosmicIsland", 260); rq = random.Random(61)
rbox(isl, ROCK, (0, 0, -2.65), (234, 110, 5), r=2.0, part="Top")
rbox(isl, GOLD, (0, 0, -1.0), (234.8, 110.8, 1.0), r=.4, part="Rim")
for i in range(14):
    x = -95 + i * 14.6 + rq.uniform(-6, 6); y = rq.uniform(-35, 35); r = rq.uniform(22, 36); dep = rq.uniform(30, 60)
    lathe(isl, ROCK if i % 2 else ROCK_D, [(r, 0), (r * .8, -dep * .3), (r * .45, -dep * .7), (0, -dep)], loc=(x, y, -5), seg=10, wob=.12, seed=i, part="Under" + str(i % 2))
for i in range(22):
    x = rq.uniform(-105, 105); y = rq.choice((-1, 1)) * rq.uniform(30, 54); z = rq.uniform(-8, -30)
    crystal(isl, CRY[i % 3], (x, y, z), rq.uniform(1.6, 3.2), -rq.uniform(8, 16), "Hang" + str(i % 3))
for i in range(16):
    a = 2 * math.pi * i / 16; x, y = math.cos(a) * 112, math.sin(a) * 52
    tube(isl, CYN if i % 2 else VIO_N, [(max(-115, min(115, x)), max(-54, min(54, y)), -6), (x * .93, y * .9, -16), (x * .85, y * .8, -26)], r=.45, seg=6, smooth=3, part="Veins" + str(i % 2))
# 2) floor pieces: star tile, constellation floor, orb lamp, crystal wall, crystal cluster, floating rock, banner, bench, small telescope
tl = add("StarTile", 8)
rbox(tl, NAVY, (0, 0, 0), (5.94, 5.94, .3), r=.12, base=True, part="Tile")
prism(tl, GOLD, star(1.6, .7), .06, loc=(0, 0, .3), rot=(0, 0, 0), part="Star")
for x, y in ((-2.4, -2.4), (2.4, -2.4), (-2.4, 2.4), (2.4, 2.4)): cyl(tl, CYN, (x, y, .3), r=.18, h=.05, seg=8, part="Dots")
cf = add("ConstellationFloor", 36)
cyl(cf, NAVY, (0, 0, 0), r=16, h=.12, seg=40, part="Disc"); torus(cf, GOLD, (0, 0, .12), R=15.6, r=.25, seg=48, rseg=4, part="Ring")
pts = [(-9, -4), (-5, 2), (-1, -1), (3, 5), (8, 2), (6, -6), (1, -9), (-4, -10), (10, 9), (-11, 7)]
for (a, b) in ((0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0), (4, 8), (1, 9)):
    (x1, y1), (x2, y2) = pts[a], pts[b]; mx, my = (x1 + x2) / 2, (y1 + y2) / 2; ln = math.hypot(x2 - x1, y2 - y1)
    rbox(cf, GOLD_D, (mx, my, .14), (ln, .3, .04), r=0, rot=(0, 0, math.degrees(math.atan2(y2 - y1, x2 - x1))), part="Lines")
for (x, y) in pts: cyl(cf, STARW, (x, y, .12), r=.55, h=.08, seg=10, part="Stars")
ol = add("OrbLamp", 4)
cyl(ol, GOLD_D, (0, 0, 0), r=.7, h=.5, seg=10, part="Base"); cyl(ol, GOLD, (0, 0, .5), r=.22, h=8, seg=10, part="Post")
torus(ol, GOLD, (0, 0, 9.2), R=1.05, r=.12, arc=250, rot=(90, 0, -35), seg=20, rseg=4, part="Holder")
sphere(ol, CYN, (0, 0, 9.2), .75, part="Orb")
cw = add("CrystalWall", 40); rq = random.Random(7)
rbox(cw, ROCK_D, (0, 0, 0), (36, 2.6, 2.0), r=.5, base=True, part="Base")
for i in range(10):
    x = -16 + i * 3.55 + rq.uniform(-.6, .6); h = rq.uniform(8, 15)
    crystal(cw, CRY[i % 3], (x, rq.uniform(-.4, .4), 1.6), rq.uniform(1.1, 1.7), h, "Crys" + str(i % 3), rot=(rq.uniform(-8, 8), rq.uniform(-8, 8), 0))
for x in (-18, -9, 0, 9, 18): sphere(cw, GOLD, (x, -1.35, 1.6), .45, part="Studs")
cc = add("CrystalCluster", 8); rq = random.Random(9)
blob(cc, ROCK, (0, 0, .4), rad=1.6, n=3, seed=3, flat=.6, seg=10, rings=6, part="Rock")
for i, (x, y, r, h, tx) in enumerate([(0, 0, 1.0, 6, 0), (1.2, .4, .7, 4, 18), (-1.1, .3, .75, 4.5, -16), (.3, -1.0, .6, 3.2, 12), (-.5, 1.0, .55, 3, -10)]):
    crystal(cc, CRY[i % 3], (x, y, .6), r, h, "Crys" + str(i % 3), rot=(tx * .6, tx, 0))
fr = add("FloatingRock", 8)
blob(fr, ROCK, (0, 0, 0), rad=2.6, n=4, seed=11, flat=.7, seg=10, rings=6, part="Rock"); crystal(fr, CRY[1], (.6, .2, 1.2), .5, 2.4, "Crys")
for k in range(3): sphere(fr, VIO_N, (math.cos(k * 2.1) * 1.8, math.sin(k * 2.1) * 1.4, -1.4), .25, part="Glow")
bn = add("CosmicBanner", 6)
cyl(bn, GOLD_D, (0, 0, 0), r=.8, h=.6, seg=10, part="Base"); cyl(bn, GOLD, (0, 0, .6), r=.18, h=12.5, seg=8, part="Pole")
rbox(bn, GOLD, (1.6, 0, 12.6), (3.6, .25, .25), r=.08, part="Arm"); sphere(bn, STARW, (0, 0, 13.4), .45, part="Finial")
rbox(bn, VIOLET, (1.8, 0, 9.0), (3.0, .12, 6.8), r=.15, part="Cloth"); prism(bn, GOLD, star(.9, .4), .06, loc=(1.8, -.1, 9.6), rot=(90, 0, 0), part="Emblem")
prism(bn, VIOLET, [(-1.5, 0), (1.5, 0), (0, -1.2)], .12, loc=(1.8, .06, 5.6), rot=(90, 0, 0), part="Cloth")
sb = add("StarBench", 6)
for x in (-1.7, 1.7): rbox(sb, MAR_D, (x, 0, 0), (.6, 1.4, 1.0), r=.1, base=True, part="Legs")
rbox(sb, MAR, (0, 0, 1.0), (4.4, 1.4, .3), r=.1, base=True, part="Seat"); rbox(sb, MAR, (0, .6, 1.3), (4.4, .25, 1.4), r=.1, base=True, part="Back")
prism(sb, GOLD, star(.45, .2), .05, loc=(0, .45, 2.0), rot=(90, 0, 0), part="Star")
st_ = add("SmallTelescope", 5)
for k in range(3):
    a = math.radians(90 + 120 * k); tube(st_, GOLD_D, [(math.cos(a) * 1.0, math.sin(a) * 1.0, 0), (0, 0, 2.6)], r=.07, seg=6, smooth=1, part="Tripod")
tube(st_, GOLD, [(0, .9, 2.0), (0, -1.6, 4.0)], r=.32, r2=.42, seg=10, smooth=1, part="Tube"); cyl(st_, CYN, (0, -1.62, 4.0), r=.36, h=.05, seg=10, rot=(52, 0, 0), part="Lens")
# 3) massive buildings
# 3a) crystal spire (~75 tall)
sp = add("CrystalSpire", 22); rq = random.Random(13)
cyl(sp, MAR, (0, 0, 0), r=9, h=2.4, seg=6, part="Plinth"); torus(sp, GOLD, (0, 0, 2.4), R=8.6, r=.35, seg=6, rseg=4, part="Trim")
cyl(sp, ROCK_D, (0, 0, 2.4), r=6.4, h=3.0, seg=6, part="Plinth2")
crystal(sp, CRY[0], (0, 0, 5.4), 4.6, 62, "Main")
for z in (14, 26, 38, 50): torus(sp, GOLD, (0, 0, z), R=4.7 * (1 - (z - 5) / 62 * .05) + .1, r=.32, seg=6, rseg=4, part="Rings")
for k in range(5):
    a = 2 * math.pi * k / 5 + .3; crystal(sp, CRY[(k + 1) % 3], (math.cos(a) * 5.4, math.sin(a) * 5.4, 4.0), rq.uniform(1.6, 2.4), rq.uniform(16, 30), "Side" + str(k % 3), rot=(math.degrees(math.sin(a)) * .2, -math.degrees(math.cos(a)) * .2, 0))
prism(sp, STARW, star(3.0, 1.3), .6, loc=(0, .3, 70.5), rot=(90, 0, 0), part="TipStar")
for k in range(6): sphere(sp, CYN if k % 2 else PNK, (math.cos(k) * 4.9, math.sin(k) * 4.9, 20 + k * 6), .4, part="Sparkles")
# 3b) moon arch (~45 tall)
ma = add("MoonArch", 40)
for sx in (-1, 1):
    rbox(ma, MAR, (sx * 15, 0, 0), (6, 6, 28), r=.6, base=True, part="Pillars")
    for z in (3, 14, 25): rbox(ma, GOLD, (sx * 15, 0, z), (6.4, 6.4, .8), r=.2, part="Bands")
    prism(ma, VIO_N, star(1.6, .7), .2, loc=(sx * 15, -3.05, 19.5), rot=(90, 0, 0), part="Stars")
    rbox(ma, MAR_D, (sx * 15, 0, 28), (7.6, 7.6, 1.6), r=.3, base=True, part="Caps")
torus(ma, GOLD, (0, 0, 29.6), R=15, r=1.6, arc=180, rot=(90, 0, 0), seg=40, rseg=8, part="Arch")
torus(ma, INDIGO, (0, 0, 29.6), R=12.4, r=.9, arc=180, rot=(90, 0, 0), seg=40, rseg=6, part="InnerArch")
cres = []
for i in range(25):
    a = math.radians(-120 + 240 * i / 24); cres.append((math.cos(a) * 9, math.sin(a) * 9))
for i in range(25):
    a = math.radians(120 - 240 * i / 24); cres.append((math.cos(a) * 7.2 + 3.2, math.sin(a) * 7.2))
prism(ma, GOLD, cres, 1.8, loc=(0, .9, 52), rot=(90, 0, 90), part="Crescent")
for k in range(5): sphere(ma, STARW, (-12 + k * 6, -.6, 47 + (k % 2) * 3), .6, part="ArchStars")
# 3c) observatory: platform + drum (static) and a rotating dome + telescope
ob = add("Observatory", 60)
rbox(ob, MAR, (0, 0, 0), (44, 44, 12), r=1.0, base=True, part="Platform")
rbox(ob, GOLD, (0, 0, 12), (44.6, 44.6, .8), r=.3, base=True, part="Trim")
for side in range(4):
    for k in range(7):
        t = -18 + k * 6
        loc = [(t, -22.1, 1), (t, 22.1, 1), (-22.1, t, 1), (22.1, t, 1)][side]
        if side == 3 and abs(t) < 13: continue
        size = (1.4, .5, 10.4) if side < 2 else (.5, 1.4, 10.4)
        rbox(ob, MAR_D, loc, size, r=.15, base=True, part="Pilasters")
    for t in (-9, 9):
        if side == 3: continue
        loc = [(t, -22.3, 6.5), (t, 22.3, 6.5), (-22.3, t, 6.5)][side]; rot = [(90, 0, 0), (90, 0, 0), (90, 0, 90)][side]
        prism(ob, VIO_N, star(2.0, .9), .2, loc=loc, rot=rot, part="Stars")
cyl(ob, LAV, (0, 0, 12.8), r=16, h=13.4, seg=36, part="Drum")
for z in (13.0, 25.8): torus(ob, GOLD, (0, 0, z), R=16.1, r=.45, seg=40, rseg=6, part="Bands")
for k in range(12):
    a = 2 * math.pi * k / 12
    rbox(ob, VIO_N, (math.cos(a) * 16.05, math.sin(a) * 16.05, 19.4), (2.2, .2, 6.0), r=.9, rot=(0, 0, math.degrees(a) + 90), part="Windows")
for k in range(48):
    a = 2 * math.pi * k / 48; R = 21.4
    for sx, sy in ((math.cos(a), math.sin(a)),):
        x, y = max(-21.4, min(21.4, sx * 30)), max(-21.4, min(21.4, sy * 30))
        if x > 21 and abs(y) < 13: continue
        cyl(ob, GOLD_D, (x, y, 12.8), r=.16, h=1.6, seg=6, part="Balustrade")
dm = add("ObservatoryDome", 40)
lathe(dm, INDIGO, [(16.2, 0), (15.6, 4), (13.9, 8), (11.2, 11.6), (7.4, 14.4), (3.6, 15.8), (0, 16.3)], seg=36, part="Dome")
for k in range(8):
    a = 2 * math.pi * k / 8 + .2
    if abs(math.sin(a) + 1) < .35: continue
    tube(dm, GOLD, [(math.cos(a) * 16.3 * math.cos(math.radians(t)), math.sin(a) * 16.3 * math.cos(math.radians(t)), 16.3 * math.sin(math.radians(t))) for t in range(0, 91, 15)], r=.32, seg=6, smooth=1, part="Ribs")
tube(dm, NAVY, [(0, -16.35 * math.cos(math.radians(t)), 16.35 * math.sin(math.radians(t))) for t in range(0, 91, 10)], r=1.5, seg=8, smooth=1, part="Slit")
rq = random.Random(21)
for k in range(40):
    a = rq.uniform(0, 6.28); t = math.radians(rq.uniform(8, 80))
    sphere(dm, STARW if k % 3 else CYN, (math.cos(a) * 16.3 * math.cos(t), math.sin(a) * 16.3 * math.cos(t), 16.3 * math.sin(t)), .3, part="StarDots")
tube(dm, GOLD, [(0, -2, 6), (0, -21, 26)], r=2.6, r2=2.0, seg=16, smooth=1, part="Telescope")
for k in range(4): torus(dm, GOLD_D, (0, -5 - k * 4.6, 9.2 + k * 4.85), R=2.8 - k * .13, r=.28, rot=(-45, 0, 0), seg=18, rseg=4, part="TeleRings")
cyl(dm, CYN, (0, -21.4, 26.4), r=2.1, h=.2, seg=18, rot=(-45, 0, 0), part="Lens")
# 3d) grand staircase (rises toward Roblox +X; 24 wide, run 20, rise 12)
gs = add("GrandStairs", 30)
for k in range(12):
    run = 20.0 / 12; x = run * (k + .5); h = 12.0 * (k + 1) / 12
    rbox(gs, MAR if k % 2 else MAR_D, R2B((x, h / 2, 0)), (run + .04, 24, h), r=.08, part="Steps")
for s in (-12.4, 12.4):
    rbox(gs, MAR_D, R2B((10, 6.6, s)), (21, 1.2, 1.2), r=.2, rot=(0, math.degrees(math.atan2(12, 20)) * (1 if s < 0 else 1), 0), part="Cheeks") if False else None
    tube(gs, GOLD, [R2B((0, 2.6, s)), R2B((20, 14.6, s))], r=.3, seg=8, smooth=1, part="Rails")
    for x in (1, 5, 9, 13, 17):
        tube(gs, GOLD_D, [R2B((x, 12.0 * x / 20, s)), R2B((x, 12.0 * x / 20 + 2.6, s))], r=.16, seg=6, smooth=1, part="Posts")
    rbox(gs, MAR, R2B((-1.2, 3.0, s)), (2.4, 2.4, 6), r=.3, part="Newels"); sphere(gs, CYN, R2B((-1.2, 6.9, s)), .9, part="NewelOrbs")
# 3e) asteroid step + star altar + altar star
ast = add("AsteroidStep", 9)
blob(ast, ROCK, (0, 0, -1.8), rad=3.6, n=4, seed=17, flat=.55, seg=10, rings=6, part="Rock")
cyl(ast, LAV, (0, 0, -.6), r=3.5, h=.6, seg=16, part="Top")
crystal(ast, CRY[1], (2.2, 1.4, -.2), .5, 2.6, "Crys"); crystal(ast, CRY[2], (-2.4, -1.0, -.2), .45, 2.0, "Crys")
for k in range(4): sphere(ast, VIO_N, (math.cos(k * 1.6) * 2.4, math.sin(k * 1.6) * 2.4, -3.2), .3, part="Glow")
alt = add("StarAltar", 16)
blob(alt, ROCK_D, (0, 0, -2.4), rad=5.8, n=5, seed=23, flat=.5, seg=12, rings=7, part="Rock")
cyl(alt, MAR, (0, 0, -1.0), r=6.2, h=1.0, seg=28, part="Platform"); torus(alt, GOLD, (0, 0, 0), R=6.1, r=.3, seg=32, rseg=4, part="Rim")
lathe(alt, MAR_D, [(1.6, 0), (1.1, .8), (.9, 3.2), (1.5, 3.8), (0, 3.9)], seg=16, part="Pedestal")
for k in range(6):
    a = 2 * math.pi * k / 6; crystal(alt, CRY[k % 3], (math.cos(a) * 5.0, math.sin(a) * 5.0, 0), .5, 2.4, "Crys" + str(k % 3))
ast2 = add("AltarStar", 6)
prism(ast2, STARW, star(1.8, .8), .5, loc=(0, .25, 0), rot=(90, 0, 0), part="Star")
for k in range(5): sphere(ast2, CYN if k % 2 else PNK, (math.cos(k * 1.26) * 2.6, 0, math.sin(k * 1.26) * 2.6), .25, part="Sparkles")
# 3f) temple of stars (~41 tall) and the coming-soon gateway
tp = add("TempleOfStars", 50)
for k, (w, d) in enumerate(((40, 30), (37, 27), (34, 24))): rbox(tp, MAR_D if k % 2 else MAR, (0, 0, k * 1.2), (w, d, 1.2), r=.2, base=True, part="Base")
for k in range(6):
    x = -15 + k * 6
    cyl(tp, MAR, (x, -9, 3.6), r=1.8, h=26, seg=16, part="Columns")
    rbox(tp, GOLD, (x, -9, 3.6), (4.2, 4.2, .8), r=.2, base=True, part="ColBases"); rbox(tp, GOLD, (x, -9, 28.8), (4.4, 4.4, 1.0), r=.2, base=True, part="Capitals")
for x in (-15, 15): cyl(tp, MAR, (x, 5, 3.6), r=1.8, h=26, seg=16, part="Columns")
rbox(tp, MAR_D, (0, -1, 29.8), (40, 22, 3.2), r=.4, base=True, part="Entablature")
rbox(tp, GOLD, (0, -12.1, 31.4), (40.2, .3, .8), r=.1, part="Frieze")
prism(tp, MAR, [(-20, 0), (20, 0), (0, 8)], 22, loc=(0, 10, 33.0), rot=(90, 0, 0), part="Pediment")
prism(tp, VIO_N, star(2.6, 1.1), .4, loc=(0, -12.3, 36.0), rot=(90, 0, 0), part="Emblem")
rbox(tp, INDIGO, (0, 9.5, 3.6), (32, 1.6, 26), r=.3, base=True, part="RearWall")
cyl(tp, VIO_N, (0, 8.6, 17), r=6.0, h=.3, seg=32, rot=(90, 0, 0), part="RoseWindow"); torus(tp, GOLD, (0, 8.45, 17), R=6.1, r=.45, rot=(90, 0, 0), seg=32, rseg=6, part="WindowFrame")
for k in range(8):
    a = 2 * math.pi * k / 8; rbox(tp, GOLD_D, (math.cos(a) * 3.0, 8.4, 17 + math.sin(a) * 3.0), (6.0, .1, .3), r=0, rot=(0, -math.degrees(a), 0), part="WindowFrame")
cs = add("ComingSoonGate", 36)
rbox(cs, ROCK_D, (0, 0, 0), (34, 8, 2.4), r=.6, base=True, part="Base")
torus(cs, GOLD, (0, 0, 16), R=13, r=2.0, rot=(90, 0, 0), seg=48, rseg=10, part="Ring")
torus(cs, VIOLET, (0, 0, 16), R=10.8, r=.7, rot=(90, 0, 0), seg=48, rseg=6, part="InnerRing")
for k in range(8):
    a = 2 * math.pi * k / 8; sphere(cs, [CYN, PNK][k % 2], (math.cos(a) * 13, -1.6, 16 + math.sin(a) * 13), .9, part="Gems")
for x in (-14, -9, 9, 14): crystal(cs, CRY[(int(x) // 5) % 3], (x, 0, 2.4), 1.2, rq.uniform(5, 8), "BaseCrys")
sw = add("PortalSwirl", 26)
cyl(sw, P("5A3FC8", "NE"), (0, .25, 0), r=10.6, h=.15, seg=40, rot=(90, 0, 0), part="Disc")
for k in range(5):
    pts = [(math.cos(k * 1.2566 + t * .35) * (1 + t * 1.9), -.2, math.sin(k * 1.2566 + t * .35) * (1 + t * 1.9)) for t in range(6)]
    tube(sw, CYN if k % 2 else PNK, pts, r=.35, seg=6, smooth=3, part="Arms" + str(k % 2))
sphere(sw, STARW, (0, -.3, 0), 1.2, scl=(1, .3, 1), part="Core")
# 3g) armillary sphere + rings (each ring spins on its own axis)
am = add("ArmillarySphere", 34)
lathe(am, MAR, [(4, 0), (3.6, 1.2), (1.6, 2.4), (1.2, 8), (2.4, 9), (0, 9.2)], seg=20, part="Base"); torus(am, GOLD, (0, 0, 1.2), R=3.6, r=.3, seg=24, rseg=4, part="Trim")
sphere(am, VIO_N, (0, 0, 20), 2.6, part="Orb"); cyl(am, GOLD_D, (0, 0, 9.2), r=.35, h=8.6, seg=8, part="Axle")
for name, R, col in (("ArmRing1", 14, GOLD), ("ArmRing2", 11.6, P("C8B4FF", "ME")), ("ArmRing3", 9.2, P("8FE6FF", "ME"))):
    rr = add(name, 2 * R + 4)
    torus(rr, col, (0, 0, 0), R=R, r=.55, rot=(90, 0, 0), seg=48, rseg=6, part="Ring")
    for k in range(6):
        a = 2 * math.pi * k / 6; sphere(rr, STARW, (math.cos(a) * R, 0, math.sin(a) * R), .7, part="Beads")
# 4) sky: planets, giant planet, comet head, asteroid range
pl = add("PlanetRinged", 16)
sphere(pl, VIOLET, (0, 0, 0), 4, seg=20, rings=12, part="Body"); torus(pl, P("C8B4FF"), (0, 0, 0), R=4.02, r=.35, seg=28, rseg=4, part="Band")
torus(pl, GOLD, (0, 0, 0), R=7, r=.45, rot=(20, 10, 0), seg=40, rseg=4, part="Ring")
pm = add("PlanetMoon", 8)
sphere(pm, P("CFC6F2"), (0, 0, 0), 2.6, seg=16, rings=10, part="Body")
for k, (x, y, z, r) in enumerate([(1.4, -1.8, .8, .6), (-1.6, -1.5, -.6, .5), (.2, -2.2, -1.2, .4)]): sphere(pm, P("A99FD6"), (x, y, z), r, scl=(1, .4, 1), part="Craters")
pt2 = add("PlanetTeal", 10)
sphere(pt2, P("4FD1C5"), (0, 0, 0), 3.2, seg=18, rings=10, part="Body"); torus(pt2, P("2C9C93"), (0, 0, .6), R=3.12, r=.4, seg=24, rseg=4, part="Band"); torus(pt2, P("A7F3EC"), (0, 0, -1.0), R=2.95, r=.3, seg=24, rseg=4, part="Band2")
gp = add("GiantPlanet", 240)
sphere(gp, P("8C6BE0"), (0, 0, 0), 60, seg=28, rings=16, part="Body")
for z, col, R in ((18, P("B49BFF"), 57.2), (-12, P("6A4CC6"), 58.8), (35, P("D2C3FF"), 48.6)): torus(gp, col, (0, 0, z), R=R, r=3.4, seg=40, rseg=6, part="Bands")
torus(gp, P("F2D8A8"), (0, 0, 0), R=105, r=8, rot=(18, 6, 0), seg=64, rseg=4, part="Ring")
cm = add("CometHead", 6)
sphere(cm, STARW, (0, 0, 0), 1.6, part="Head"); sphere(cm, CYN, (0, 1.4, 0), 1.0, scl=(1, 1.6, 1), part="Glow")
ar = add("AsteroidRange", 820); rq = random.Random(99)
for i in range(11):
    x = -380 + i * 76 + rq.uniform(-15, 15); y = rq.uniform(0, 60); z = rq.uniform(20, 170); r = rq.uniform(26, 56)
    blob(ar, ROCK if i % 2 else ROCK_D, (x, y, z), rad=r, n=4, seed=200 + i, flat=.7, seg=12, rings=7, part="Rocks" + str(i % 2))
    for k in range(3): crystal(ar, CRY[(i + k) % 3], (x + rq.uniform(-r * .5, r * .5), y + rq.uniform(-r * .3, r * .3), z + r * .5), rq.uniform(3, 6), rq.uniform(16, 34), "Crys" + str((i + k) % 3))
# 5) egg + pets
egg = add("StarEgg", 9)
cc_ = [(0, 0, 1.0, 2.4), (1.6, .8, .6, 1.2), (-1.5, .6, .6, 1.1), (.4, -1.5, .5, .9)]
for k, (x, y, r, h) in enumerate(cc_): crystal(egg, CRY[k % 3], (x, y, 0), r * 1.1, h * 1.2 if k else 2.6, "Pedestal")
blob(egg, ROCK, (0, 0, .6), rad=2.4, n=3, seed=5, flat=.5, seg=10, rings=6, part="Pedestal")
PROF = [(0, 0), (1.0, .12), (1.6, .6), (1.95, 1.4), (2.05, 2.2), (1.95, 3.0), (1.65, 3.8), (1.1, 4.5), (.5, 4.88), (0, 5.0)]
Z0 = 2.6
lathe(egg, P("3B2C8C"), PROF, loc=(0, 0, Z0), seg=28, part="Shell")
torus(egg, GOLD, (0, 0, Z0 + 2.4), R=2.9, r=.16, rot=(18, 0, 0), seg=40, rseg=6, part="PlanetRing")
for k, (dz, col) in enumerate(((1.6, CYN), (3.1, PNK))): torus(egg, col, (0, 0, Z0 + dz), R=2.0 if dz < 2.2 else 1.85, r=.09, seg=36, rseg=4, part="Swirl")
for i, (h, ang) in enumerate([(1.0, 30), (1.2, 150), (1.0, 270), (3.9, 90), (4.1, 210), (3.8, 330), (2.6, 0), (2.7, 180)]):
    a = math.radians(ang); rr = 1.98 if h < 3.0 else 1.6
    prism(egg, STARW, star(.3, .13), .06, loc=(math.cos(a) * rr, math.sin(a) * rr, Z0 + h), rot=(0, 90, math.degrees(a)), part="Stars")
p1 = add("Pet_CometPup", 4)
sphere(p1, P("A9D8FF"), (0, .25, .8), .85, scl=(.95, 1.15, .85), part="Body"); sphere(p1, P("A9D8FF"), (0, -.6, 1.45), .68, part="Head")
sphere(p1, WH, (0, -1.15, 1.32), .32, scl=(1.1, .8, .8), part="Snout"); sphere(p1, INK, (0, -1.42, 1.42), .1, part="Nose")
for s in (-1, 1): sphere(p1, P("7FB8F0"), (s * .62, -.45, 1.75), .3, scl=(.6, .5, 1.3), rot=(0, s * 25, 0), part="Ears"); sphere(p1, WH, (s * .42, -.45, .15), .25, scl=(1, 1.2, .7), part="Feet")
for k, (y, z, r, col) in enumerate([(1.0, 1.1, .45, STARW), (1.6, 1.35, .38, P("FFE38A", "NE")), (2.15, 1.55, .3, PNK), (2.6, 1.7, .22, VIO_N)]): sphere(p1, col, (0, y, z), r, part="Comet" + str(k % 2))
face(p1, -1.08, 1.62, sep=.27, er=.12)
p2 = add("Pet_MoonBunny", 4)
sphere(p2, P("F1ECFF"), (0, .1, .8), .82, scl=(1, 1.1, .95), part="Body"); sphere(p2, P("F1ECFF"), (0, -.45, 1.55), .65, part="Head")
for s in (-1, 1): sphere(p2, P("F1ECFF"), (s * .3, -.3, 2.55), .24, scl=(.8, .5, 2.2), rot=(0, s * 10, 0), part="Ears"); sphere(p2, P("FFC7E8"), (s * .3, -.42, 2.55), .14, scl=(.7, .3, 1.9), part="EarIn")
moon = [(math.cos(math.radians(-120 + 240 * i / 12)) * .3, math.sin(math.radians(-120 + 240 * i / 12)) * .3) for i in range(13)] + [(math.cos(math.radians(120 - 240 * i / 12)) * .24 + .1, math.sin(math.radians(120 - 240 * i / 12)) * .24) for i in range(13)]
prism(p2, GOLD, moon, .06, loc=(0, -1.08, 1.85), rot=(90, 0, 90), part="Moon")
sphere(p2, WH, (0, .95, .7), .3, part="Tail"); face(p2, -1.0, 1.5, sep=.27, er=.12)
p3 = add("Pet_AstroCat", 4)
sphere(p3, P("FFAE5C"), (0, .2, .85), .85, scl=(.95, 1.15, .9), part="Body"); sphere(p3, P("FFAE5C"), (0, -.5, 1.6), .66, part="Head")
for s in (-1, 1): lathe(p3, P("FFAE5C"), [(.24, 0), (.1, .4), (0, .48)], loc=(s * .36, -.45, 2.08), seg=8, part="Ears"); sphere(p3, WH, (s * .35, -.5, .12), .22, scl=(1, 1.3, .6), part="Paws")
sphere(p3, P("CFF6FF", "GL", .55), (0, -.5, 1.65), 1.0, part="Helmet"); torus(p3, P("C8CDE0", "ME"), (0, -.5, 1.0), R=.75, r=.12, seg=20, rseg=6, part="Collar")
cyl(p3, P("C8CDE0", "ME"), (0, -.4, 2.6), r=.04, h=.5, seg=6, part="Antenna"); sphere(p3, PNK, (0, -.4, 3.15), .12, part="AntennaTip")
tube(p3, P("FFAE5C"), [(0, 1.0, .7), (.3, 1.5, 1.2), (.1, 1.7, 1.8)], r=.15, seg=8, smooth=3, part="Tail"); face(p3, -1.05, 1.68, sep=.28, er=.13)
p4 = add("Pet_NebulaFox", 4)
sphere(p4, P("C77DFF"), (0, .2, .85), .85, scl=(.9, 1.15, .9), part="Body"); sphere(p4, P("F3E6FF"), (0, -.45, .78), .48, scl=(1, .5, 1), part="Belly")
sphere(p4, P("C77DFF"), (0, -.55, 1.6), .65, part="Head"); sphere(p4, P("F3E6FF"), (0, -1.05, 1.45), .3, scl=(1, .9, .7), part="Belly"); sphere(p4, INK, (0, -1.32, 1.5), .09, part="Nose")
for s in (-1, 1): lathe(p4, P("C77DFF"), [(.25, 0), (.12, .4), (0, .55)], loc=(s * .38, -.5, 2.05), seg=8, part="Ears"); sphere(p4, INK, (s * .3, -.6, .1), .2, scl=(1, 1.2, .6), part="Feet")
tube(p4, P("C77DFF"), [(0, 1.0, .7), (.3, 1.6, 1.1), (.2, 1.9, 1.7)], r=.38, r2=.2, seg=10, smooth=3, part="Tail")
for k, (x, y, z) in enumerate([(.2, 1.95, 1.95), (.35, 1.75, 1.55), (.05, 1.6, 1.25)]): sphere(p4, [STARW, CYN, PNK][k], (x, y, z), .14, part="TailStars")
face(p4, -1.0, 1.72, sep=.28, er=.12)
p5 = add("Pet_GalaxyDragon", 4)
sphere(p5, P("3C2E8F"), (0, .15, 1.0), 1.0, scl=(1, 1.1, .95), part="Body"); sphere(p5, P("B9A6FF"), (0, -.55, .88), .58, scl=(1, .5, 1), part="Belly")
sphere(p5, P("3C2E8F"), (0, -.65, 1.85), .72, part="Head")
for s in (-1, 1):
    lathe(p5, GOLD, [(.15, 0), (.06, .45), (0, .5)], loc=(s * .35, -.55, 2.45), rot=(-20, s * 15, 0), seg=8, part="Horns")
    prism(p5, P("8B6BFF", "SP", .25), [(0, 0), (1.5, .5), (1.3, -.3), (.7, -.7)], .08, loc=(s * .75, .45, 1.45), rot=(90, 0, 90 + s * 90), part="Wings")
    sphere(p5, P("2C2270"), (s * .45, -.3, .2), .28, scl=(1, 1.3, .6), part="Feet")
tube(p5, P("3C2E8F"), [(0, 1.0, .7), (.3, 1.7, .6), (.5, 2.2, .45)], r=.32, r2=.1, seg=8, smooth=3, part="Tail")
rq = random.Random(5)
for k in range(10): sphere(p5, [STARW, CYN, PNK][k % 3], (rq.uniform(-.7, .7), rq.uniform(-.3, .9), rq.uniform(.8, 1.7)), .08, part="Spots")
face(p5, -1.28, 1.95, sep=.3, er=.14); sphere(p5, P("FFE2A0", "NE"), (0, -1.0, .6), .1, part="Glow")

objs = realize(models, 'W2_Cosmic')
