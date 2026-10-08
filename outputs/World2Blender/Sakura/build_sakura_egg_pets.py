import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

# Sakura egg + pets (World 2) - Claude 2026-10-02. Pets face -Y, ~2-3 studs, feet at z=0.
from w2lib import *
INK, WHITE, BLUSH, GOLD = P("2A2433"), P("FFFFFF"), P("FF9BB5"), P("FFC94A")
PINK_M, PINK_D, PETAL, CREAM = P("FF92C2"), P("F06AA6"), P("FFF0F6"), P("F0E4CF")
models = []
X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 40, 0); X[0] += w / 2 + 4; return p
def face(m, y, z, sep=.36, er=.17, blush=True):
    for s in (-1, 1):
        sphere(m, INK, (s * sep, y, z), er, scl=(.8, .45, 1.15), part="Eyes")
        sphere(m, WHITE, (s * sep - .05, y - .08, z + .07), er * .38, part="Shine")
        if blush: sphere(m, BLUSH, (s * (sep + .27), y + .07, z - .23), .14, scl=(1, .35, .6), part="Blush")
def curve(pts, n):
    out = []
    for i in range(n):
        t = i / (n - 1) * (len(pts) - 1); k = min(int(t), len(pts) - 2); f = t - k
        out.append(tuple(pts[k][j] * (1 - f) + pts[k + 1][j] * f for j in range(3)))
    return out

# --- Blossom Egg on a stone pedestal (Shell + EggArt decor + pedestal) ---
egg = Model("BlossomEgg", at=at(6)); models.append(egg)
lathe(egg, CREAM, [(2.6, 0), (2.6, .4), (2.2, .62), (1.6, .9), (1.5, 2.0), (2.0, 2.3), (2.35, 2.6), (2.35, 2.9), (0.01, 2.9)], seg=8, part="Pedestal")
rbox(egg, P("E0457B"), (0, 0, 2.9), (3.3, 3.3, .5), r=.22, base=True, part="Cushion")
PROF = [(0, 0), (1.0, .12), (1.6, .6), (1.95, 1.4), (2.05, 2.2), (1.95, 3.0), (1.65, 3.8), (1.1, 4.5), (.5, 4.88), (0, 5.0)]
Z0 = 3.35
lathe(egg, P("FFB8D6"), PROF, loc=(0, 0, Z0), seg=28, part="Shell")
def rad_at(h):
    for (r1, z1), (r2, z2) in zip(PROF, PROF[1:]):
        if z1 <= h <= z2: return r1 + (r2 - r1) * (h - z1) / max(1e-6, z2 - z1)
    return 0
torus(egg, GOLD, (0, 0, Z0 + 2.2), R=2.08, r=.12, seg=40, rseg=8, part="Band")
rr = random.Random(4)
for i, (h, ang) in enumerate([(1.3, 0), (1.5, 100), (1.2, 210), (1.4, 300), (3.2, 45), (3.4, 160), (3.0, 255), (4.1, 330)]):
    a = math.radians(ang + rr.uniform(-12, 12)); rad = rad_at(h) + .02
    el = 15 if h > 2.2 else -5
    flower(egg, PETAL if i % 2 else PINK_M, GOLD, (math.cos(a) * rad, math.sin(a) * rad, Z0 + h), .55, rot=(0, 90 - el, math.degrees(a)), part="Petals")

# --- Pets ---
k = Model("Pet_Koi", at=at(4)); models.append(k)
W, OR, RD = P("FFF6EE"), P("FF7A2E"), P("E8383D")
lathe(k, W, [(0, 0), (.35, .25), (.75, .8), (.92, 1.4), (.85, 1.95), (.55, 2.4), (0, 2.6)], loc=(0, 1.3, 1.2), rot=(90, 0, 0), seg=16, sy=.85, part="Body")
sphere(k, OR, (0, 1.75, 1.55), .5, scl=(.22, 1, .62), rot=(-38, 0, 0), part="Tail")
sphere(k, OR, (0, 1.75, .85), .5, scl=(.22, 1, .62), rot=(38, 0, 0), part="Tail")
sphere(k, OR, (0, .35, 1.95), .55, scl=(.2, 1, .45), part="Fins")
for s in (-1, 1): sphere(k, OR, (s * .82, -.15, .95), .38, scl=(.6, 1, .25), rot=(0, s * 30, 0), part="Fins")
sphere(k, OR, (.25, -.35, 1.82), .5, scl=(1, 1.1, .3), part="Spots")
sphere(k, RD, (-.3, .55, 1.72), .42, scl=(1, 1.1, .3), part="Spots2")
face(k, -1.0, 1.35, sep=.42, er=.17)
sphere(k, P("F28AA0"), (0, -1.24, 1.02), .12, scl=(1.3, .5, .7), part="Mouth")

bn = Model("Pet_BlossomBunny", at=at(4)); models.append(bn)
BW, BIN = P("FFF7FA"), P("FFB0C8")
sphere(bn, BW, (0, 0, 1.0), 1.0, scl=(1.0, .95, .95), part="Body")
for s in (-1, 1):
    sphere(bn, BW, (s * .42, -.05, 2.25), .3, scl=(.95, .75, 2.3), rot=(0, s * 12, 0), part="Ears")
    sphere(bn, BIN, (s * .44, -.25, 2.25), .17, scl=(.8, .4, 1.9), rot=(0, s * 12, 0), part="InnerEars")
    sphere(bn, BW, (s * .45, -.55, .2), .3, scl=(1, 1.3, .6), part="Feet")
sphere(bn, BW, (0, .95, .8), .35, part="Tail")
face(bn, -.86, 1.15)
sphere(bn, BIN, (0, -.95, .92), .07, part="Nose")
flower(bn, PINK_M, GOLD, (.5, -.3, 1.88), .42, rot=(30, 25, 0), part="Flower")

rp = Model("Pet_RedPanda", at=at(4)); models.append(rp)
O, CR, DK = P("D9572B"), P("FFF1E0"), P("4A2A20")
sphere(rp, O, (0, 0, 1.0), 1.0, scl=(1.05, .95, .92), part="Body")
for s in (-1, 1):
    sphere(rp, CR, (s * .45, -.76, .82), .32, scl=(1, .5, .8), part="Mask")
    sphere(rp, CR, (s * .36, -.82, 1.5), .12, scl=(1.4, .4, .8), part="Mask")
    sphere(rp, O, (s * .62, 0, 1.78), .33, scl=(1, .6, 1), part="Ears")
    sphere(rp, CR, (s * .62, -.14, 1.8), .2, scl=(1, .4, 1), part="EarIn")
    sphere(rp, DK, (s * .45, -.45, .18), .28, scl=(1, 1.2, .65), part="Paws")
sphere(rp, CR, (0, -.88, .78), .28, scl=(1.2, .5, .7), part="Mask")
sphere(rp, INK, (0, -1.0, .88), .08, part="Nose")
face(rp, -.88, 1.14, sep=.33, er=.15)
for i, p in enumerate(curve([(0, .85, .7), (.3, 1.45, .9), (.48, 1.8, 1.4), (.42, 1.85, 2.0)], 6)):
    sphere(rp, O if i % 2 == 0 else CR, p, .36 - .025 * i, part="Tail" if i % 2 == 0 else "TailRings")

cr = Model("Pet_Crane", at=at(4)); models.append(cr)
CW, BK, RC, BEAK, LEG = P("FFFFFF"), P("2B2B33"), P("E8383D"), P("E8C46A"), P("6B6B75")
sphere(cr, CW, (0, .15, 1.25), .95, scl=(.95, 1.15, .8), part="Body")
tube(cr, CW, [(0, -.5, 1.55), (0, -.75, 2.05), (0, -.72, 2.5)], r=.22, seg=10, smooth=3, part="Neck")
sphere(cr, CW, (0, -.72, 2.72), .43, part="Head")
sphere(cr, RC, (0, -.66, 3.07), .21, scl=(1, 1, .5), part="Crown")
lathe(cr, BEAK, [(.12, 0), (.0, .6)], loc=(0, -1.05, 2.68), rot=(90, 0, 0), seg=8, part="Beak")
face(cr, -1.04, 2.8, sep=.2, er=.09)
for s in (-1, 1):
    sphere(cr, CW, (s * .8, .25, 1.35), .5, scl=(.4, 1.3, .75), part="Wings")
    sphere(cr, BK, (s * .82, .95, 1.3), .3, scl=(.35, .9, .6), part="WingTips")
    cyl(cr, LEG, (s * .3, .1, 0), r=.07, h=.65, seg=6, part="Legs")
    sphere(cr, LEG, (s * .3, -.05, .04), .14, scl=(1, 1.6, .4), part="Legs")
sphere(cr, BK, (0, 1.3, 1.35), .38, scl=(.8, 1, .6), part="Tail")

dg = Model("Pet_BlossomDragon", at=at(4)); models.append(dg)
PK, BELLY, HORN, WING = P("FF9FC9"), P("FFE9D6"), P("FFF3D9"), P("FFC7DE")
sphere(dg, PK, (0, 0, 1.05), 1.0, scl=(1, .95, .98), part="Body")
sphere(dg, BELLY, (0, -.52, .85), .62, scl=(1, .55, 1), part="Belly")
for s in (-1, 1):
    lathe(dg, HORN, [(.14, 0), (.08, .35), (0, .52)], loc=(s * .42, .05, 1.85), rot=(0, s * 20, 0), seg=8, part="Horns")
    sphere(dg, PK, (s * .48, -.35, .2), .27, scl=(1, 1.3, .6), part="Feet")
    sphere(dg, WING, (s * .98, .45, 1.6), .58, scl=(.16, 1.0, .75), rot=(25, 0, -s * 22), part="Wings")
tube(dg, PK, [(0, .8, .55), (.3, 1.4, .5), (.55, 1.8, .8), (.5, 2.0, 1.2)], r=.22, r2=.08, seg=8, smooth=3, part="Tail")
flower(dg, PINK_D, GOLD, (.5, 2.0, 1.28), .36, rot=(-20, 0, 0), part="TailFlower")
for i, x in enumerate((-.32, 0, .32)):
    flower(dg, PETAL if i == 1 else PINK_M, GOLD, (x, .12, 2.0), .24, rot=(10, x * 40, 0), part="Crown")
face(dg, -.9, 1.18, sep=.34, er=.17)
sphere(dg, P("FFD9F0", "NE"), (0, -.98, .55), .12, part="Glow")

objs = realize(models, 'W2_Sakura_EggPets')
