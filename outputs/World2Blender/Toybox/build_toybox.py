import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Giant Toybox pack (World 2, stage 12) - Claude 2026-10-03. Units = studs, front = -Y (Roblox -Z). R2B for Roblox-frame geometry.
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
RED, BLUE, YEL, GRN, ORA, PUR = P("FF4B4B"), P("3E8BFF"), P("FFD23F"), P("44C767"), P("FF9A3C"), P("9C6BFF")
WOOD, WOOD_D, CREAM, WHITE, INK, BLUSH = P("D9A066"), P("A8733E"), P("FFF3DC"), P("FFFFFF"), P("2A2433"), P("FF9BB5")
METAL = P("B8C2D6", "ME")
PRIM = [RED, BLUE, YEL, GRN, ORA, PUR]
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 10; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def block(m, pc, loc, s, rot=(0, 0, 0), part="Block", emblem=None, epc=None):
    rbox(m, pc, loc, (s, s, s), r=s * .14, bseg=2, rot=rot, part=part)
    if emblem:
        star = [(math.cos(math.radians(90 + 36 * i)) * (s * .32 if i % 2 == 0 else s * .14), math.sin(math.radians(90 + 36 * i)) * (s * .32 if i % 2 == 0 else s * .14)) for i in range(10)]
        prism(m, epc, star if emblem == "star" else heart_poly(s * .2), s * .06, loc=(loc[0], loc[1] - s / 2 - s * .02, loc[2]), rot=(90, 0, rot[2]), part=part + "Emblem")
def face(m, y, z, sep=.36, er=.17, blush=True):
    for s in (-1, 1):
        sphere(m, INK, (s * sep, y, z), er, scl=(.8, .45, 1.15), part="Eyes")
        sphere(m, WHITE, (s * sep - .05, y - .08, z + .07), er * .38, part="Shine")
        if blush: sphere(m, BLUSH, (s * (sep + .27), y + .07, z - .23), .14, scl=(1, .35, .6), part="Blush")
# 1) island underside: a giant wooden toy box with painted bands and spilled blocks
isl = add("ToyIsland", 300)
rbox(isl, WOOD, (0, 0, -24), (286, 126, 46), r=3.5, part="Box")
rbox(isl, WOOD_D, (0, 0, -1.4), (290, 130, 2.6), r=1.0, part="Rim")
for k, (z, col) in enumerate([(-12, RED), (-26, BLUE), (-38, YEL)]):
    rbox(isl, col, (0, 0, z), (287.2, 127.2, 3.0), r=1.0, part="Band" + str(k))
for sx in (-1, 1):
    for sy in (-1, 1): sphere(isl, WOOD_D, (sx * 143, sy * 63, -47), 4.5, part="Feet")
rq = random.Random(4)
for i in range(9):
    s = rq.uniform(9, 16)
    block(isl, PRIM[i % 6], (rq.uniform(-110, 110), rq.uniform(-40, 40), -55 - rq.uniform(0, 30)), s, rot=(rq.uniform(0, 40), rq.uniform(0, 40), rq.uniform(0, 90)), part="Spill" + str(i % 6))
# 2) rim: block stack + ball
rim = add("ToyRim", 12)
block(rim, RED, (0, 0, 1.6), 3.2, rot=(0, 0, 12), part="B0"); block(rim, BLUE, (.4, .2, 4.8), 3.0, rot=(0, 0, -20), part="B1"); block(rim, YEL, (3.4, -.5, 1.4), 2.8, rot=(0, 0, 35), part="B2")
sphere(rim, GRN, (-3.6, .6, 1.6), 1.6, part="Ball"); torus(rim, WHITE, (-3.6, .6, 1.6), R=1.6, r=.18, rot=(90, 0, 30), seg=20, rseg=6, part="BallStripe")
# 3) props
tb = add("ToyBlockA", 5); block(tb, RED, (0, 0, 2), 4, part="Block", emblem="star", epc=YEL)
bb = add("BuildingBricks", 8)
for k, (x, y, z, col) in enumerate([(0, 0, 0, BLUE), (1.2, .2, 1.6, YEL), (-1.0, -.1, 3.2, RED)]):
    rbox(bb, col, (x, y, z), (4.8, 2.4, 1.6), r=.18, base=True, part="Brick" + str(k))
    for i in range(4): cyl(bb, col, (x - 1.8 + i * 1.2, y, z + 1.6), r=.38, h=.35, seg=10, part="Brick" + str(k))
st_ = add("SpinningTop", 5)
lathe(st_, RED, [(.0, 0), (.35, .5), (1.5, 1.6), (1.7, 1.9), (1.2, 2.3), (.4, 2.5), (0.01, 2.5)], seg=24, part="Body")
torus(st_, YEL, (0, 0, 1.85), R=1.62, r=.16, seg=24, rseg=6, part="Stripe")
cyl(st_, WOOD, (0, 0, 2.5), r=.18, h=1.4, seg=8, part="Handle"); sphere(st_, BLUE, (0, 0, 3.95), .32, part="Knob")
td = add("TeddyBearStatue", 7); BR_, BRL = P("B5763F"), P("E8C39A")
sphere(td, BR_, (0, 0, 2.2), 2.0, scl=(1, .9, 1.05), part="Fur"); sphere(td, BRL, (0, -1.5, 2.0), 1.2, scl=(1, .5, 1.1), part="Belly")
sphere(td, BR_, (0, -.2, 5.0), 1.55, part="Fur")
for s in (-1, 1):
    sphere(td, BR_, (s * 1.2, 0, 6.3), .6, scl=(1, .6, 1), part="Fur"); sphere(td, BRL, (s * 1.2, -.2, 6.3), .32, scl=(1, .4, 1), part="Belly")
    sphere(td, BR_, (s * 2.0, -.6, 3.0), .75, scl=(.8, .8, 1.3), part="Fur"); sphere(td, BR_, (s * 1.2, -1.6, .6), .85, scl=(1, 1.3, .7), part="Fur")
    sphere(td, BRL, (s * 1.2, -2.5, .65), .5, scl=(1, .3, .8), part="Belly")
sphere(td, BRL, (0, -1.4, 4.7), .6, scl=(1.1, .6, .75), part="Belly"); sphere(td, INK, (0, -1.95, 4.85), .2, part="Nose")
for s in (-1, 1): sphere(td, INK, (s * .55, -1.35, 5.4), .2, scl=(.8, .5, 1.1), part="Eyes")
torus(td, RED, (0, -.2, 3.75), R=1.15, r=.22, seg=20, rseg=6, part="Bow")
rb = add("ToyRobotStatue", 6)
rbox(rb, METAL, (0, 0, 1.6), (3.2, 2.2, 3.2), r=.35, base=True, part="Body")
rbox(rb, P("D6DEEC", "ME"), (0, 0, 4.9), (2.6, 2.2, 2.2), r=.4, base=True, part="Head")
for s in (-1, 1):
    rbox(rb, METAL, (s * .8, 0, 0), (1.0, 1.4, 1.6), r=.2, base=True, part="Legs")
    tube(rb, METAL, [(s * 1.6, 0, 4.2), (s * 2.3, -.2, 3.4), (s * 2.4, -.6, 2.6)], r=.28, seg=8, smooth=3, part="Arms")
    sphere(rb, P("7FE9FF", "NE"), (s * .6, -1.12, 6.0), .3, part="Eyes")
sphere(rb, RED, (0, -1.12, 2.9), .45, scl=(1, .4, 1), part="Heart")
cyl(rb, METAL, (0, 0, 7.1), r=.08, h=1.0, seg=6, part="Antenna"); sphere(rb, YEL, (0, 0, 8.2), .28, part="Bulb")
bf = add("ButtonFlowerPatch", 7)
for k, (x, y, h, col) in enumerate([(0, 0, 3.4, RED), (1.6, .8, 2.6, BLUE), (-1.4, .6, 2.2, YEL)]):
    cyl(bf, GRN, (x, y, 0), r=.12, h=h, seg=6, part="Stems")
    sphere(bf, GRN, (x + .5, y, h * .45), .45, scl=(1.2, .35, .6), part="Leaves")
    for i in range(6):
        a = 2 * math.pi * i / 6
        cyl(bf, col, (x + math.cos(a) * .55, y - .05, h + math.sin(a) * .55), r=.32, h=.14, seg=12, rot=(90, 0, 0), part="Petals" + str(k))
    cyl(bf, WHITE, (x, y - .1, h), r=.36, h=.16, seg=12, rot=(90, 0, 0), part="Centers")
    for i in range(4): cyl(bf, INK, (x + (i % 2 - .5) * .24, y - .2, h + (i // 2 - .5) * .24), r=.06, h=.06, seg=6, rot=(90, 0, 0), part="Holes")
cl = add("CrayonLamp", 4)
cyl(cl, P("6FA8FF"), (0, 0, 0), r=.5, h=6.5, seg=6, part="Crayon"); lathe(cl, P("6FA8FF"), [(.5, 6.5), (.18, 7.6), (0, 7.7)], seg=6, part="Crayon")
for z in (1.0, 5.8): cyl(cl, WHITE, (0, 0, z), r=.52, h=.5, seg=6, part="Wrap")
sphere(cl, P("FFE38A", "NE"), (0, 0, 8.6), .7, part="Light")
pt = add("ToyPathTile", 9)
for i, (x, y) in enumerate([(-2, -2), (2, -2), (-2, 2), (2, 2)]):
    rbox(pt, [P("FF8A8A"), P("8FD3FF"), P("FFE38A"), P("9EE6A8")][i], (x, y, 0), (3.94, 3.94, .35), r=.12, base=True, part="Mat" + str(i))
for x, y in ((0, -2), (0, 2), (-2, 0), (2, 0)): cyl(pt, P("FFFFFF"), (x, y, .35), r=.45, h=.02, seg=10, part="Knobs")
# 4) landmark: track loop + train + block arch
TR = 16.0
tl = add("TrackLoop", 36)
for rr_, nm in ((TR - 1.0, "RailIn"), (TR + 1.0, "RailOut")): torus(tl, METAL, (0, 0, .55), R=rr_, r=.16, seg=64, rseg=6, part="Rails")
for i in range(40):
    a = 2 * math.pi * i / 40
    rbox(tl, WOOD, (math.cos(a) * TR, math.sin(a) * TR, .25), (3.0, .7, .3), r=.08, rot=(0, 0, math.degrees(a)), part="Sleepers")
def wheels(m, xs, y, pc=RED):
    for x in xs:
        for s in (-1, 1): cyl(m, pc, (x, s * 1.05, .8), r=.8, h=.35, seg=14, rot=(90, 0, 0), part="Wheels"); cyl(m, YEL, (x, s * 1.25, .8), r=.25, h=.12, seg=8, rot=(90, 0, 0), part="Hubs")
eng = add("ToyTrainEngine", 10)
# engine built along Blender Y (front = -Y) - so wheel axes along X
for x in (-1.6, 0.4, 2.2):
    for s in (-1, 1):
        cyl(eng, RED, (s * 1.25, x, .8), r=.8, h=.35, seg=14, rot=(0, 90, 0), part="Wheels"); cyl(eng, YEL, (s * 1.45, x, .8), r=.26, h=.12, seg=8, rot=(0, 90, 0), part="Hubs")
rbox(eng, BLUE, (0, .2, .9), (2.4, 6.6, .9), r=.2, base=True, part="Chassis")
cyl(eng, GRN, (0, -1.2, 2.6), r=1.25, h=4.4, seg=18, rot=(90, 0, 0), part="Boiler")
rbox(eng, RED, (0, 1.9, 1.8), (2.6, 2.4, 3.2), r=.3, base=True, part="Cab"); rbox(eng, YEL, (0, 1.9, 5.0), (3.0, 2.8, .4), r=.15, base=True, part="Roof")
cyl(eng, INK, (0, -2.4, 3.8), r=.45, r2=.7, h=1.6, seg=10, part="Chimney"); sphere(eng, YEL, (0, -3.55, 2.6), .45, part="Lamp")
lathe(eng, YEL, [(.0, 0), (1.1, .1), (0.01, 1.0)], loc=(0, -3.4, .4), rot=(0, 0, 0), seg=4, part="Cow")
for s in (-1, 1): rbox(eng, P("BFE6FF", "GL", .2), (s * 1.32, 1.9, 3.2), (.12, 1.2, 1.0), r=.1, part="Windows")
car = add("ToyTrainCar", 9)
for x in (-1.5, 1.5):
    for s in (-1, 1):
        cyl(car, BLUE, (s * 1.25, x, .8), r=.8, h=.35, seg=14, rot=(0, 90, 0), part="Wheels"); cyl(car, YEL, (s * 1.45, x, .8), r=.26, h=.12, seg=8, rot=(0, 90, 0), part="Hubs")
rbox(car, YEL, (0, 0, .9), (2.6, 5.4, 2.4), r=.3, base=True, part="Wagon")
block(car, RED, (0, -1.1, 3.9), 1.6, rot=(0, 0, 20), part="Cargo0"); block(car, PUR, (.2, 1.0, 3.8), 1.5, rot=(0, 0, -30), part="Cargo1"); sphere(car, GRN, (-.3, .0, 4.4), .8, part="Cargo2")
arch = add("BlockArch", 26)
for sx, nm in ((-1, "PillarL"), (1, "PillarR")):
    for k in range(4): block(arch, PRIM[(k + (sx > 0) * 2) % 6], (sx * 7.5, 0, 2.25 + k * 4.5), 4.5, rot=(0, 0, (k % 2) * 8 - 4), part=nm)
for k in range(5):
    a = math.radians(180 * (k + .5) / 5)
    block(arch, PRIM[(k + 3) % 6], (math.cos(a) * 7.5, 0, 18 + math.sin(a) * 6.0), 4.6, rot=(0, -math.degrees(a) + 90, 0), part="Top", emblem="star" if k == 2 else None, epc=WHITE)
sphere(arch, YEL, (0, 0, 27.5), 2.2, part="TopBall"); torus(arch, RED, (0, 0, 27.5), R=2.2, r=.25, rot=(90, 0, 0), seg=20, rseg=6, part="TopBall")
# 5) block castle with a flat walkable keep (activity reward on top)
cs = add("BlockCastle", 30)
rbox(cs, BLUE, (0, 0, 0), (13, 12, 14), r=1.2, base=True, part="Keep")
for sx in (-1, 1):
    cyl(cs, RED, (sx * 9, 2, 0), r=3.2, h=19, seg=20, bev=.4, part="Tower" + ("L" if sx < 0 else "R"))
    lathe(cs, YEL, [(3.8, 19), (2.0, 22.5), (0, 25.5)], loc=(sx * 9, 2, 0), seg=20, part="Roofs")
    cyl(cs, WHITE, (sx * 9, 2, 25.4), r=.12, h=3.0, seg=6, part="FlagPoles"); prism(cs, GRN, [(0, 0), (2.0, -.6), (0, -1.2)], .12, loc=(sx * 9 + .1, 2, 28.3), rot=(90, 0, 0), part="Flags")
for k in range(5): block(cs, PRIM[k % 6], (-5 + k * 2.5, -5.0, 15.1), 2.2, rot=(0, 0, 0), part="Crenels")
rbox(cs, WOOD_D, (0, -6.05, 0), (4.0, .4, 6.0), r=1.5, base=True, part="Door")
for k, (x, z) in enumerate([(-4, 9.0), (4, 9.0)]): rbox(cs, P("BFE6FF"), (x, -6.05, z), (2.0, .3, 2.4), r=.6, part="Windows")
pb = add("PrizeBox", 5)
rbox(pb, PUR, (0, 0, 0), (3.2, 3.2, 2.6), r=.3, base=True, part="Box")
rbox(pb, YEL, (0, .4, 2.9), (3.4, 3.4, .45), r=.15, rot=(-25, 0, 0), part="Lid")
star = [(math.cos(math.radians(90 + 36 * i)) * (.9 if i % 2 == 0 else .4), math.sin(math.radians(90 + 36 * i)) * (.9 if i % 2 == 0 else .4)) for i in range(10)]
prism(pb, YEL, star, .12, loc=(0, -1.66, 1.3), rot=(90, 0, 0), part="Star"); sphere(pb, P("FFF2A8", "NE"), (0, -.2, 2.8), .6, part="Glow")
# 6) gate (Atlantis -> Toybox) and train-track bridge
gt = add("ToyGate", 22)
for sx, nm in ((-1, "PostL"), (1, "PostR")):
    for k in range(4): block(gt, PRIM[(k * 2 + (sx > 0)) % 6], (sx * 8.8, 0, 1.6 + k * 3.2), 3.2, rot=(0, 0, (k % 2) * 10 - 5), part=nm)
rbox(gt, WOOD, (0, 0, 13.6), (21, 2.6, 1.6), r=.5, part="Beam")
for k in range(7):
    x = -7.8 + k * 2.6
    prism(gt, PRIM[k % 6], [(-.9, 0), (.9, 0), (0, -1.6)], .12, loc=(x, -1.4, 13.0), rot=(90, 0, 0), part="Pennants")
sphere(gt, RED, (0, 0, 16.4), 1.8, part="Ball"); torus(gt, WHITE, (0, 0, 16.4), R=1.8, r=.2, rot=(90, 0, 0), seg=20, rseg=6, part="Ball")
def bez(p0, p1, p2, p3, t):
    u = 1 - t; return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t
def curve(end, n=26):
    P0 = Vector((0, 0, 0)); P3 = Vector(end); P1 = Vector((end[0] * .48, 0, 0)); P2 = P3 - Vector((end[0] * .48, 0, 0))
    pts = [bez(P0, P1, P2, P3, i / n) for i in range(n + 1)]; fr = []
    for i, p in enumerate(pts):
        t = pts[min(i + 1, n)] - pts[max(i - 1, 0)]; t.y = 0; t.normalize(); fr.append((p, Vector((-t.z, 0, t.x))))
    return fr
br = add("BridgeAtlantisToybox", 120); F = curve((59, 8, 60))
tbm = bmesh.new(); rows = []
for p, r in F:
    rows.append([tbm.verts.new(R2B(v)) for v in (p - r * 5, p + r * 5, p + r * 5 - Vector((0, 1, 0)), p - r * 5 - Vector((0, 1, 0)))])
for A, B in zip(rows, rows[1:]):
    for k in range(4): tbm.faces.new((A[k], A[(k + 1) % 4], B[(k + 1) % 4], B[k]))
tbm.faces.new(list(reversed(rows[0]))); tbm.faces.new(rows[-1]); bmesh.ops.recalc_face_normals(tbm, faces=tbm.faces); _merge(br.bm("Deck", WOOD), tbm)
for s in (-1, 1):
    tube(br, METAL, [R2B(p + r * s * 1.6 + Vector((0, .25, 0))) for p, r in F], r=.18, seg=6, smooth=1, part="Rails")
for i in range(0, len(F), 1):
    p, r = F[i]
    rbox(br, WOOD_D, R2B(p + Vector((0, .05, 0))), (6.0, .9, .25), r=.06, rot=(0, 0, -math.degrees(math.atan2(r.x, r.z)) + 90), part="Sleepers")
for i in range(0, len(F), 3):
    p, r = F[i]
    for s in (-1, 1): block(br, PRIM[(i // 3 + (s > 0)) % 6], R2B(p + r * s * 5.0 + Vector((0, 1.2, 0))), 1.6, part="PostBlocks")
# 7) block mountain range (background): stacked giant rounded blocks + cushion hills
rng_ = add("BlockRange", 800); rq = random.Random(9)
MUTED = [P("E88A8A"), P("8FB4E8"), P("E8D08A"), P("94D3A2"), P("E8B48A"), P("B9A2E8")]
for i in range(8):
    x = -360 + i * 103 + rq.uniform(-20, 20); y = rq.uniform(10, 60); z = 0
    for k in range(rq.randint(3, 6)):
        s = rq.uniform(38, 66) * (1 - k * .1)
        rbox(rng_, MUTED[(i + k) % 6], (x + rq.uniform(-12, 12), y + rq.uniform(-10, 10), z + s / 2), (s, s, s), r=s * .12, bseg=2, rot=(0, 0, rq.uniform(-25, 25)), part="Stack" + str((i + k) % 6))
        z += s * .92
for i in range(7):
    x = -330 + i * 105 + rq.uniform(-20, 20)
    sphere(rng_, MUTED[(i + 2) % 6], (x, rq.uniform(-75, -45), 0), rq.uniform(38, 55), scl=(1.4, 1, .55), seg=14, rings=8, part="Cushion" + str((i + 2) % 6))
# 8) toy capsule egg on a block pedestal
egg = add("ToyCapsuleEgg", 7)
block(egg, BLUE, (0, 0, 1.6), 3.2, part="Pedestal", emblem="star", epc=YEL)
rbox(egg, RED, (0, 0, 3.2), (3.6, 3.6, .5), r=.2, base=True, part="Cushion")
PROF = [(0, 0), (1.0, .12), (1.6, .6), (1.95, 1.4), (2.05, 2.2), (1.95, 3.0), (1.65, 3.8), (1.1, 4.5), (.5, 4.88), (0, 5.0)]
Z0 = 3.7
lathe(egg, YEL, PROF, loc=(0, 0, Z0), seg=28, part="Shell")
lathe(egg, P("FF5A5A"), [(2.09, 2.2), (1.99, 3.0), (1.69, 3.8), (1.13, 4.5), (.52, 4.9), (0, 5.04)], loc=(0, 0, Z0), seg=28, part="Cap")
torus(egg, WHITE, (0, 0, Z0 + 2.2), R=2.1, r=.16, seg=40, rseg=8, part="Band")
for i, (h, ang) in enumerate([(1.2, 30), (1.4, 150), (1.0, 270), (3.4, 90), (3.6, 210), (3.2, 330)]):
    a = math.radians(ang); rr2 = 2.06 if h < 2.2 else 1.9
    st5 = [(math.cos(math.radians(90 + 36 * j)) * (.42 if j % 2 == 0 else .18), math.sin(math.radians(90 + 36 * j)) * (.42 if j % 2 == 0 else .18)) for j in range(10)]
    prism(egg, [BLUE, GRN, PUR][i % 3], st5, .1, loc=(math.cos(a) * rr2, math.sin(a) * rr2, Z0 + h), rot=(0, 90, math.degrees(a)), part="Stickers")
# 9) pets (face -Y, feet at z=0)
pt1 = add("Pet_TeddyBear", 4)
sphere(pt1, BR_, (0, 0, 1.0), 1.0, scl=(1, .9, .95), part="Fur"); sphere(pt1, BRL, (0, -.62, .85), .55, scl=(1, .5, 1), part="Belly")
for s in (-1, 1):
    sphere(pt1, BR_, (s * .62, 0, 1.78), .32, scl=(1, .6, 1), part="Fur"); sphere(pt1, BRL, (s * .62, -.14, 1.8), .18, scl=(1, .4, 1), part="Belly")
    sphere(pt1, BR_, (s * .48, -.42, .2), .3, scl=(1, 1.3, .65), part="Fur")
sphere(pt1, BRL, (0, -.85, .88), .3, scl=(1.2, .5, .7), part="Belly"); sphere(pt1, INK, (0, -1.0, .98), .09, part="Nose")
face(pt1, -.86, 1.18, sep=.33, er=.15); torus(pt1, RED, (0, -.1, .45), R=.62, r=.09, seg=16, rseg=6, part="Bow")
pt2 = add("Pet_ToyDuck", 4); DY = P("FFD23F")
sphere(pt2, DY, (0, .2, .85), .95, scl=(1, 1.15, .8), part="Body"); sphere(pt2, DY, (0, -.45, 1.75), .62, part="Body")
lathe(pt2, ORA, [(.32, 0), (.2, .38), (0, .45)], loc=(0, -1.0, 1.62), rot=(90, 0, 0), seg=10, sx=1.2, sy=.55, part="Beak")
sphere(pt2, DY, (0, 1.25, 1.25), .4, scl=(.8, 1, .6), rot=(-30, 0, 0), part="Body")
for s in (-1, 1): sphere(pt2, DY, (s * .8, .3, 1.0), .35, scl=(.5, 1.2, .5), part="Body")
face(pt2, -.98, 1.88, sep=.26, er=.12)
pt3 = add("Pet_WindupMouse", 4); MG = P("C7CBD6")
sphere(pt3, MG, (0, .1, .8), .9, scl=(.95, 1.2, .85), part="Body")
for s in (-1, 1):
    sphere(pt3, MG, (s * .55, -.3, 1.55), .42, scl=(1, .4, 1), part="Ears"); sphere(pt3, P("FFB0C8"), (s * .55, -.42, 1.55), .25, scl=(1, .3, 1), part="EarIn")
    sphere(pt3, P("FFB0C8"), (s * .38, -.55, .15), .2, scl=(1, 1.3, .6), part="Feet")
sphere(pt3, P("FFB0C8"), (0, -1.12, .75), .1, part="Nose"); face(pt3, -.95, .95, sep=.3, er=.13)
tube(pt3, P("FFB0C8"), [(0, 1.1, .5), (.4, 1.6, .7), (.2, 2.0, 1.1)], r=.06, seg=6, smooth=3, part="Tail")
cyl(pt3, P("D4A537", "ME"), (0, .45, 1.55), r=.08, h=.5, seg=6, part="Key")
for s in (-1, 1): torus(pt3, P("D4A537", "ME"), (s * .28, .45, 2.1), R=.22, r=.06, rot=(0, 90, 0), seg=12, rseg=6, part="Key")
pt4 = add("Pet_ToyRobot", 4)
rbox(pt4, METAL, (0, 0, .6), (1.7, 1.5, 1.4), r=.3, base=True, part="Body"); rbox(pt4, P("D6DEEC", "ME"), (0, 0, 2.05), (1.7, 1.5, 1.2), r=.35, base=True, part="Head")
for s in (-1, 1):
    sphere(pt4, P("7FE9FF", "NE"), (s * .38, -.78, 2.65), .17, part="Eyes"); rbox(pt4, METAL, (s * .45, 0, 0), (.5, .7, .7), r=.15, base=True, part="Legs")
    sphere(pt4, METAL, (s * 1.05, 0, 1.3), .28, part="Arms")
sphere(pt4, RED, (0, -.78, 1.25), .2, scl=(1, .4, 1), part="Heart")
cyl(pt4, METAL, (0, 0, 3.25), r=.05, h=.5, seg=6, part="Antenna"); sphere(pt4, YEL, (0, 0, 3.85), .15, part="Bulb")
pt5 = add("Pet_PlushDino", 4); DG = P("6FD27A")
sphere(pt5, DG, (0, .1, 1.0), 1.0, scl=(1, 1.1, .95), part="Body"); sphere(pt5, P("CFF5C0"), (0, -.55, .85), .58, scl=(1, .55, 1), part="Belly")
for s in (-1, 1): sphere(pt5, DG, (s * .5, -.3, .2), .28, scl=(1, 1.3, .6), part="Feet")
tube(pt5, DG, [(0, .9, .6), (.2, 1.6, .5), (.3, 2.1, .35)], r=.35, r2=.1, seg=8, smooth=3, part="Tail")
for k, (y, z) in enumerate([(-.1, 1.95), (.35, 1.85), (.75, 1.6), (1.15, 1.25), (1.6, .85)]):
    lathe(pt5, [YEL, ORA, PUR][k % 3], [(.2, 0), (0, .35)], loc=(0, y, z), seg=6, part="Spikes" + str(k % 3))
face(pt5, -.95, 1.2, sep=.34, er=.16)
sphere(pt5, P("FFF2A8", "NE"), (0, -1.0, .55), .1, part="Glow")

objs = realize(models, 'W2_Toybox')
