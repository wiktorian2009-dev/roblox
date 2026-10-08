import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Cloud Kingdom pack (World 2, stage 14) - Claude 2026-10-03. Units = studs, front = -Y (Roblox -Z). R2B for Roblox-frame geometry.
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
WH, WH2, LAV, PINKC, BLUEC = P("F7F9FF"), P("EEF2FF"), P("E2DBFF"), P("FFE3F1"), P("DDEEFF")
GOLD, GOLD_D, SKY, NAVY, INK, BLUSH = P("FFD25A", "ME"), P("E0A830", "ME"), P("8FD0FF"), P("3E5BA8"), P("2A2433"), P("FF9BB5")
RB = [P("FF6B6B"), P("FFA94D"), P("FFE066"), P("69DB7C"), P("4DABF7"), P("748FFC"), P("B197FC")]
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 12; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def face(m, y, z, sep=.36, er=.17):
    for s in (-1, 1):
        sphere(m, INK, (s * sep, y, z), er, scl=(.8, .45, 1.15), part="Eyes"); sphere(m, P("FFFFFF"), (s * sep - .05, y - .08, z + .07), er * .38, part="Shine")
        sphere(m, BLUSH, (s * (sep + .27), y + .07, z - .23), .14, scl=(1, .35, .6), part="Blush")
def star(r1, r2): return [(math.cos(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2), math.sin(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2)) for i in range(10)]
# 1) island: flat cloud top (0.15 under the floor), gold rim band, fluffy sides and underside
isl = add("CloudIsland", 260); rq = random.Random(31)
rbox(isl, WH, (0, 0, -3.15), (234, 110, 6), r=2.5, part="Top")
rbox(isl, GOLD, (0, 0, -1.1), (234.8, 110.8, 1.0), r=.4, part="Rim")
for i in range(34):
    a = 2 * math.pi * i / 34; x = math.cos(a) * 121; y = math.sin(a) * 58
    sphere(isl, [WH, WH2, LAV][i % 3], (max(-121, min(121, x)), max(-58, min(58, y)), -8 - rq.uniform(0, 4)), rq.uniform(8, 12), seg=12, rings=8, part="Side" + str(i % 3))
for i in range(40):
    x = rq.uniform(-105, 105); y = rq.uniform(-45, 45); d = (x / 110) ** 2 + (y / 50) ** 2
    if d > 1.1: continue
    sphere(isl, [WH, LAV, PINKC, BLUEC][i % 4], (x, y, -14 - rq.uniform(0, 26) * (1.1 - d)), rq.uniform(14, 26) * (1.15 - d * .5), seg=12, rings=8, part="Under" + str(i % 4))
# 2) cloud wall segment (~36 long, ~15 tall), path pad, star lamp, cloud tree, sunflowers
cw = add("CloudWall", 40); rq = random.Random(5)
for i in range(7):
    x = -16 + i * 5.3 + rq.uniform(-1, 1); sphere(cw, WH, (x, rq.uniform(-.6, .6), 4.6), rq.uniform(5.0, 6.2), scl=(1, .8, 1), seg=10, rings=7, part="Puff1")
for i in range(6):
    x = -13.5 + i * 5.4 + rq.uniform(-1, 1); sphere(cw, PINKC if i % 2 else BLUEC, (x, rq.uniform(-.5, .5), 9.6), rq.uniform(4.2, 5.0), scl=(1, .8, 1), seg=10, rings=7, part="Puff2")
for i in range(4):
    x = -10 + i * 6.8 + rq.uniform(-1.5, 1.5); sphere(cw, WH2, (x, 0, 13.0), rq.uniform(3.0, 3.8), scl=(1, .8, 1), seg=10, rings=7, part="Puff3")
pd = add("CloudPad", 8)
cyl(pd, WH, (0, 0, 0), r=3.2, h=.35, seg=20, part="Pad"); torus(pd, P("BFE3FF"), (0, 0, .36), R=2.85, r=.14, seg=20, rseg=4, part="Ring")
lp = add("StarLamp", 4)
cyl(lp, WH, (0, 0, 0), r=.28, h=7.4, seg=10, part="Post"); cyl(lp, GOLD, (0, 0, 0), r=.6, h=.5, seg=10, part="Base")
for z in (2.5, 5.5): torus(lp, GOLD, (0, 0, z), R=.3, r=.08, seg=10, rseg=4, part="Rings")
prism(lp, P("FFE680", "NE"), star(1.0, .45), .35, loc=(0, .17, 8.4), rot=(90, 0, 0), part="Star")
sphere(lp, WH2, (.4, 0, .5), .55, part="Fluff"); sphere(lp, WH2, (-.35, .2, .4), .45, part="Fluff")
ct = add("CloudTree", 10)
tube(ct, P("C8A27A"), [(0, 0, 0), (.3, 0, 2.5), (-.2, 0, 5.0)], r=.45, r2=.3, seg=8, smooth=3, part="Trunk")
for k, (x, y, z, r) in enumerate([(0, 0, 6.6, 2.6), (1.8, .6, 5.6, 1.8), (-1.7, -.4, 5.8, 1.9), (.3, -1.3, 7.9, 1.6)]): sphere(ct, PINKC, (x, y, z), r, seg=12, rings=8, part="Puffs")
sf = add("SunFlowers", 6)
for k, (x, y, h) in enumerate([(0, 0, 3.2), (1.3, .7, 2.5), (-1.2, .5, 2.1)]):
    cyl(sf, P("6CCB6A"), (x, y, 0), r=.1, h=h, seg=6, part="Stems")
    for i in range(10):
        a = 2 * math.pi * i / 10; sphere(sf, P("FFD43B"), (x + math.cos(a) * .55, y - .12, h + math.sin(a) * .55), .3, scl=(1, .3, .6), rot=(0, math.degrees(a), 0), part="Petals")
    sphere(sf, P("B5651D"), (x, y - .18, h), .32, scl=(1, .5, 1), part="Centers"); sphere(sf, P("6CCB6A"), (x + .4, y, h * .45), .32, scl=(1.3, .3, .6), part="Leaves")
# 3) balloons, windmill + blades, sheep, fountain, waterfall
hb = add("HotAirBalloon", 14)
lathe(hb, P("FF8FB1"), [(0.01, 0), (1.6, 1.0), (4.6, 4.0), (6.0, 7.5), (5.6, 10.5), (3.8, 12.8), (0.01, 14)], loc=(0, 0, 6), seg=12, part="StripeA")
lathe(hb, P("FFE066"), [(0.01, 0), (1.62, 1.0), (4.62, 4.0), (6.02, 7.5), (5.62, 10.5), (3.82, 12.8), (0.01, 14)], loc=(0, 0, 6), seg=12, rot=(0, 0, 15), sx=.999, sy=.999, part="StripeB") if False else None
for i in range(6):
    a0 = 60 * i
    lathe(hb, [P("FF8FB1"), P("FFE066")][i % 2], [(0.01, 0), (1.6, 1.0), (4.6, 4.0), (6.0, 7.5), (5.6, 10.5), (3.8, 12.8), (0.01, 14)], loc=(0, 0, 6), seg=2, rot=(0, 0, a0), part="Stripe" + str(i % 2)) if False else None
lathe(hb, P("FF8FB1"), [(0.01, 0), (1.6, 1.0), (4.6, 4.0), (6.0, 7.5), (5.6, 10.5), (3.8, 12.8), (0.01, 14)], loc=(0, 0, 6), seg=14, part="Envelope")
for z, col in ((10.5, P("FFE066")), (14.0, P("8FD0FF")), (17.0, P("FFE066"))):
    rr = {10.5: 5.95, 14.0: 5.75, 17.0: 4.1}[z]; torus(hb, col, (0, 0, z), R=rr, r=.45, seg=24, rseg=6, part="Bands")
rbox(hb, P("B07A4A"), (0, 0, 0), (2.6, 2.6, 1.8), r=.3, base=True, part="Basket")
for sx in (-1, 1):
    for sy in (-1, 1): tube(hb, P("8A6A4A"), [(sx * 1.1, sy * 1.1, 1.8), (sx * 1.7, sy * 1.7, 6.6)], r=.06, seg=4, smooth=1, part="Ropes")
wm = add("Windmill", 10)
lathe(wm, WH, [(3.0, 0), (2.6, 6), (2.0, 13), (1.8, 14)], seg=14, part="Tower"); lathe(wm, NAVY, [(2.4, 14), (1.4, 16.2), (0, 17.6)], seg=14, part="Cap")
rbox(wm, P("8FD0FF"), (0, -2.75, 0), (1.5, .3, 2.6), r=.5, base=True, part="Door")
for z in (6, 10): cyl(wm, P("BFE3FF", "GL", .15), (0, -2.35, z), r=.5, h=.1, seg=12, rot=(90, 0, 0), part="Windows")
wb = add("WindmillBlades", 14)
for k in range(4):
    a = 90 * k; rbox(wb, WH2, (0, 0, 0), (1.2, .15, 6.2), r=.1, rot=(0, a, 0), part="Spokes")
for k in range(4):
    a = math.radians(90 * k); x, z = math.sin(a) * 3.8, math.cos(a) * 3.8
    rbox(wb, [PINKC, BLUEC, P("FFF3BF"), P("D3F9D8")][k], (x, -.05, z), (1.8, .1, 4.4), r=.15, rot=(0, 90 * k, 0), part="Sails" + str(k % 2))
sphere(wb, GOLD, (0, -.2, 0), .5, part="Hub")
sh = add("CloudSheep", 5)
for k, (x, y, z, r) in enumerate([(0, 0, 1.6, 1.1), (.8, .2, 1.5, .8), (-.8, .2, 1.5, .8), (0, .9, 1.7, .8), (.4, -.4, 2.3, .7), (-.4, .4, 2.3, .7)]): sphere(sh, WH, (x, y, z), r, seg=10, rings=7, part="Wool")
sphere(sh, P("6E6A80"), (0, -1.15, 1.9), .55, scl=(.9, 1.0, 1.0), part="Head")
for s in (-1, 1):
    sphere(sh, P("6E6A80"), (s * .55, -1.0, 2.2), .22, scl=(1.3, .5, .6), part="Ears")
    for y in (-.5, .6): cyl(sh, P("6E6A80"), (s * .5, y, 0), r=.16, h=.9, seg=6, part="Legs")
for s in (-1, 1): sphere(sh, P("FFFFFF"), (s * .2, -1.6, 2.0), .1, part="Eyes")
cf = add("CloudFountain", 12)
lathe(cf, WH, [(0, 0), (4.4, 0), (4.6, .8), (4.0, 1.4), (0, 1.4)], seg=24, part="Basin"); torus(cf, GOLD, (0, 0, 1.4), R=4.2, r=.22, seg=28, rseg=6, part="Rim")
cyl(cf, P("8FD0FF", "GL", .25), (0, 0, 1.0), r=3.9, h=.3, seg=24, part="Water")
cyl(cf, WH2, (0, 0, 1.0), r=.6, h=3.6, seg=12, part="Column"); lathe(cf, WH, [(0, 3.6), (1.8, 3.8), (1.4, 4.4), (0, 4.4)], seg=18, part="Bowl")
torus(cf, GOLD, (0, 0, 4.4), R=1.6, r=.12, seg=20, rseg=4, part="Rim")
for k, (x, z, r) in enumerate([(0, 5.4, .9), (.6, 5.9, .6), (-.5, 6.0, .55)]): sphere(cf, P("FFFFFF", "SP", .1), (x, 0, z), r, part="Cloud")
fl = add("SkyFall", 12)
tbm = bmesh.new(); rows = []
for i in range(9):
    t = i / 8; z = -t * 46; y = -1.5 * math.sin(t * math.pi * .5) * 3
    rows.append([tbm.verts.new((x, y, z)) for x in (-4.5, 4.5)])
for A, B in zip(rows, rows[1:]): tbm.faces.new((A[0], A[1], B[1], B[0]))
bmesh.ops.recalc_face_normals(tbm, faces=tbm.faces)
for f in tbm.faces: f.normal_flip() if f.normal.y > 0 else None
_merge(fl.bm("Water", P("A8DCFF", "GL", .35)), tbm)
for k in range(5): sphere(fl, P("FFFFFF", "SP", .4), (-4 + k * 2, -4.5, -46), 2.4, seg=10, rings=6, part="Mist")
rbox(fl, P("A8DCFF", "GL", .3), (0, 0, -.2), (9.4, 1.6, .4), r=.15, part="Lip")
# 4) landmark castle + rainbow
cs = add("SkyCastle", 40)
rbox(cs, WH, (0, 0, 0), (30, 20, 10), r=1.0, base=True, part="Walls")
rbox(cs, GOLD, (0, 0, 10), (30.6, 20.6, .8), r=.3, base=True, part="Trim")
for k in range(9): rbox(cs, WH2, (-13 + k * 3.25, -10.0, 10.8), (1.6, 1.0, 1.4), r=.2, base=True, part="Crenels")
rbox(cs, P("8FD0FF"), (0, -10.05, 0), (5.0, .3, 7.0), r=2.2, base=True, part="Door")
for sx in (-1, 1):
    for sy in (-1, 1):
        cyl(cs, WH, (sx * 14, sy * 9, 0), r=3.4, h=19, seg=18, part="Towers"); torus(cs, GOLD, (sx * 14, sy * 9, 19), R=3.4, r=.3, seg=18, rseg=4, part="Trim")
        lathe(cs, NAVY, [(4.0, 19), (2.2, 23), (0, 27)], loc=(sx * 14, sy * 9, 0), seg=18, part="Roofs")
        cyl(cs, GOLD, (sx * 14, sy * 9, 27), r=.12, h=2.4, seg=6, part="Poles"); prism(cs, P("FF8FB1"), [(0, 0), (1.8, -.5), (0, -1.0)], .1, loc=(sx * 14 + .1, sy * 9, 29.2), rot=(90, 0, 0), part="Flags")
rbox(cs, WH2, (0, 2, 10), (13, 11, 14), r=.8, base=True, part="Keep")
cyl(cs, WH, (0, 2, 24), r=3.2, h=12, seg=18, part="Spire"); lathe(cs, GOLD, [(3.6, 36), (2.8, 38.5), (1.2, 40.5), (0, 42)], loc=(0, 2, 0), seg=18, part="Dome")
cyl(cs, GOLD, (0, 2, 42), r=.15, h=3.0, seg=6, part="Poles"); prism(cs, GOLD, star(1.0, .45), .25, loc=(0, 2.1, 45.6), rot=(90, 0, 0), part="TopStar")
for x in (-8, 8):
    for z in (4.5,): rbox(cs, P("BFE3FF", "GL", .15), (x, -10.05, z), (2.0, .2, 2.6), r=.8, part="Windows")
for x in (-3.5, 3.5): rbox(cs, P("BFE3FF", "GL", .15), (x, -3.55, 18.5), (1.6, .2, 2.4), r=.7, part="Windows")
rw = add("Rainbow", 160)
for i, c in enumerate(RB): torus(rw, c, (0, 0, 0), R=70 - i * 1.15, r=.62, arc=180, rot=(90, 0, 0), seg=64, rseg=6, part="Band" + str(i))
for s in (-1, 1):
    for k, (dx, dz, r) in enumerate([(0, 1.5, 7), (4, 3, 5), (-4, 2.5, 5.5), (0, 6, 4.5)]): sphere(rw, [WH, WH2, PINKC, BLUEC][k], (s * 66 + dx, rq.uniform(-2, 2), dz), r, seg=12, rings=8, part="Feet" + str(k % 2))
# 5) terrace stairs (rise toward Roblox +X), bell tower, cloud platform
cst = add("CloudStairs", 22)
for k in range(8):
    run = 18.0 / 8; x = run * (k + .5); h = 8.0 * (k + 1) / 8
    rbox(cst, WH if k % 2 else WH2, R2B((x, h / 2, 0)), (run + .05, 8.2, h), r=.3, part="Steps")
for s in (-1, 1):
    for k in range(5): sphere(cst, [PINKC, BLUEC][k % 2], R2B((2 + k * 4, 1.6 * (k + 1), s * 4.6)), 1.6, seg=10, rings=6, part="Puffs")
bt = add("SkyBellTower", 14)
cyl(bt, WH, (0, 0, 0), r=2.6, h=30, seg=18, part="Pillar")
for z in (6, 12, 18, 24): torus(bt, GOLD, (0, 0, z), R=2.65, r=.22, seg=20, rseg=4, part="Rings")
cyl(bt, WH2, (0, 0, 30), r=5.2, h=1.0, seg=24, part="Top"); torus(bt, GOLD, (0, 0, 31), R=5.1, r=.25, seg=28, rseg=4, part="TopRim")
for k in range(4):
    a = math.radians(45 + 90 * k); cyl(bt, GOLD_D, (math.cos(a) * 3.4, math.sin(a) * 3.4, 31), r=.18, h=5.0, seg=8, part="Arch")
lathe(bt, GOLD, [(3.9, 36), (2.8, 37.5), (0, 38.6)], seg=18, part="Dome")
lathe(bt, GOLD, [(0, 35.6), (.35, 35.5), (1.2, 34.6), (1.5, 33.6), (1.6, 33.2), (0, 33.2)], seg=18, part="Bell"); sphere(bt, GOLD_D, (0, 0, 33.0), .3, part="Bell")
prism(bt, P("FFE680", "NE"), star(1.1, .5), .3, loc=(0, 0, 40.0), rot=(90, 0, 0), part="Star")
cp = add("CloudPlatform", 9)
cyl(cp, WH, (0, 0, -.5), r=3.6, h=1.0, seg=18, part="Pad")
for k in range(6):
    a = 2 * math.pi * k / 6; sphere(cp, [WH2, PINKC, BLUEC][k % 3], (math.cos(a) * 3.0, math.sin(a) * 3.0, -1.1), 1.3, seg=10, rings=6, part="Puffs")
sphere(cp, WH2, (0, 0, -1.6), 2.4, scl=(1, 1, .6), seg=12, rings=7, part="Puffs")
# 6) gate + rainbow bridge (Roblox local end (85, 16, 60))
gt = add("CloudGate", 24)
for sx in (-1, 1):
    for k, (z, r) in enumerate([(1.8, 2.2), (5.0, 1.9), (8.0, 1.7), (11.0, 1.5)]): sphere(gt, [WH, WH2][k % 2], (sx * 8.8, 0, z), r, seg=12, rings=8, part="Pillars")
torus(gt, GOLD, (0, 0, 12), R=8.8, r=.6, arc=180, rot=(90, 0, 0), seg=28, rseg=6, part="Arch")
cyl(gt, GOLD, (0, -.2, 21.6), r=2.2, h=.4, seg=24, rot=(90, 0, 0), part="Sun")
for k in range(12):
    a = 2 * math.pi * k / 12; prism(gt, GOLD_D, [(-.35, 0), (.35, 0), (0, 1.5)], .2, loc=(math.cos(a) * 2.4, -.1, 21.6 + math.sin(a) * 2.4), rot=(90, 0, math.degrees(a) - 90), part="Rays")
for k, (x, z, r) in enumerate([(-4, 20.5, 1.8), (4, 20.2, 1.9), (0, 24.6, 1.4)]): sphere(gt, WH, (x, .6, z), r, seg=10, rings=6, part="Cloud")
def bez(p0, p1, p2, p3, t):
    u = 1 - t; return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t
def curve(end, n=32):
    P0 = Vector((0, 0, 0)); P3 = Vector(end); P1 = Vector((end[0] * .48, 0, 0)); P2 = P3 - Vector((end[0] * .48, 0, 0))
    pts = [bez(P0, P1, P2, P3, i / n) for i in range(n + 1)]; fr = []
    for i, p in enumerate(pts):
        t = pts[min(i + 1, n)] - pts[max(i - 1, 0)]; t.y = 0; t.normalize(); fr.append((p, Vector((-t.z, 0, t.x))))
    return fr
br = add("BridgeClockworkCloud", 130); F = curve((85, 16, 60))
for k in range(7):
    o0, o1 = -5 + k * 10 / 7, -5 + (k + 1) * 10 / 7
    tb = bmesh.new(); rows = []
    for p, r in F:
        rows.append([tb.verts.new(R2B(v)) for v in (p + r * o0, p + r * o1, p + r * o1 - Vector((0, .8, 0)), p + r * o0 - Vector((0, .8, 0)))])
    for A, B in zip(rows, rows[1:]):
        for q in range(4): tb.faces.new((A[q], A[(q + 1) % 4], B[(q + 1) % 4], B[q]))
    tb.faces.new(list(reversed(rows[0]))); tb.faces.new(rows[-1]); bmesh.ops.recalc_face_normals(tb, faces=tb.faces); _merge(br.bm("Stripe" + str(k), RB[k]), tb)
for s in (-1, 1):
    tube(br, WH, [R2B(p + r * s * 5.1 + Vector((0, 2.4, 0))) for p, r in F], r=.35, seg=8, smooth=1, part="Rails")
    for i in range(0, len(F), 2):
        p, r = F[i]; sphere(br, [WH, WH2][i % 2], R2B(p + r * s * 5.1 + Vector((0, .9, 0))), .95, seg=10, rings=6, part="Puffs")
# 7) background: giant cumulus towers
cr = add("CloudRange", 820); rq = random.Random(77)
for i in range(8):
    x = -360 + i * 103 + rq.uniform(-20, 20); y = rq.uniform(10, 60); z = 0
    for k in range(rq.randint(4, 6)):
        r = rq.uniform(42, 70) * (1 - k * .12); z += r * .9
        sphere(cr, [WH, LAV, PINKC, WH2][(i + k) % 4], (x + rq.uniform(-18, 18), y + rq.uniform(-12, 12), z), r, seg=12, rings=8, part="Tower" + str((i + k) % 4))
for i in range(7): sphere(cr, WH2, (-330 + i * 105 + rq.uniform(-20, 20), rq.uniform(-75, -45), 10), rq.uniform(40, 55), scl=(1.5, 1, .55), seg=12, rings=7, part="Base")
# 8) egg on a cloud pedestal
egg = add("CloudEgg", 8)
for k, (x, y, r) in enumerate([(0, 0, 2.4), (1.7, .6, 1.5), (-1.6, .5, 1.6), (.4, -1.6, 1.4), (-.5, 1.6, 1.4)]): sphere(egg, [WH, WH2][k % 2], (x, y, 1.4), r, scl=(1, 1, .7), seg=12, rings=8, part="Pedestal")
cyl(egg, GOLD, (0, 0, 2.7), r=2.4, h=.35, seg=24, part="Plinth")
PROF = [(0, 0), (1.0, .12), (1.6, .6), (1.95, 1.4), (2.05, 2.2), (1.95, 3.0), (1.65, 3.8), (1.1, 4.5), (.5, 4.88), (0, 5.0)]
Z0 = 3.05
lathe(egg, P("FDFBFF"), PROF, loc=(0, 0, Z0), seg=28, part="Shell")
for i, (c, dz) in enumerate(zip(RB[:5], (1.7, 2.0, 2.3, 2.6, 2.9))):
    rr = 2.05 if dz < 2.6 else 1.98; torus(egg, c, (0, 0, Z0 + dz), R=rr, r=.11, seg=36, rseg=5, part="RainbowBand")
for s in (-1, 1): prism(egg, GOLD, [(0, 0), (1.4, .6), (1.6, 1.4), (.9, 1.2), (.2, .5)], .12, loc=(s * 2.0, 0, Z0 + 3.0), rot=(90, 0, 90 + s * 90), part="Wings")
for i, (h, ang) in enumerate([(1.0, 30), (1.1, 150), (1.0, 270), (4.0, 90), (4.1, 210), (4.0, 330)]):
    a = math.radians(ang); rr = 1.98 if h < 2.2 else 1.6
    prism(egg, GOLD, star(.32, .14), .08, loc=(math.cos(a) * rr, math.sin(a) * rr, Z0 + h), rot=(0, 90, math.degrees(a)), part="Stars")
# 9) pets (face -Y, feet at z=0)
p1 = add("Pet_CloudLamb", 4)
for k, (x, y, z, r) in enumerate([(0, .1, .95, .85), (.55, .3, .9, .55), (-.55, .3, .9, .55), (0, .7, 1.1, .55), (.3, -.2, 1.5, .5), (-.3, -.2, 1.5, .5), (0, .3, 1.6, .5)]): sphere(p1, WH, (x, y, z), r, seg=12, rings=8, part="Wool")
sphere(p1, P("8A86A0"), (0, -.75, 1.25), .5, part="Head")
for s in (-1, 1): sphere(p1, P("8A86A0"), (s * .5, -.6, 1.45), .2, scl=(1.4, .5, .6), part="Ears"); cyl(p1, P("8A86A0"), (s * .35, -.2, 0), r=.13, h=.45, seg=6, part="Legs")
face(p1, -1.18, 1.3, sep=.2, er=.1)
p2 = add("Pet_CloudKitten", 4)
sphere(p2, P("CFE4FF"), (0, .2, .85), .85, scl=(.95, 1.15, .9), part="Body"); sphere(p2, P("CFE4FF"), (0, -.5, 1.6), .68, part="Head")
for s in (-1, 1): lathe(p2, P("CFE4FF"), [(.26, 0), (.1, .42), (0, .5)], loc=(s * .38, -.45, 2.1), seg=8, part="Ears"); sphere(p2, WH, (s * .35, -.5, .12), .22, scl=(1, 1.3, .6), part="Paws")
for k, (x, y, z, r) in enumerate([(0, -.5, 2.25, .3), (.25, -.35, 2.2, .22), (-.25, -.35, 2.2, .22)]): sphere(p2, WH, (x, y, z), r, part="Fluff")
tube(p2, P("CFE4FF"), [(0, 1.0, .7), (.3, 1.5, 1.2), (.1, 1.7, 1.8)], r=.18, seg=8, smooth=3, part="Tail"); sphere(p2, WH, (.1, 1.72, 1.95), .35, part="Fluff")
face(p2, -1.08, 1.68, sep=.28, er=.13); sphere(p2, P("FF9BB5"), (0, -1.15, 1.48), .07, part="Nose")
p3 = add("Pet_ThunderOwl", 4)
sphere(p3, P("6F7FD0"), (0, 0, 1.1), 1.0, scl=(1, .9, 1.05), part="Body"); sphere(p3, P("D9DEFF"), (0, -.62, 1.0), .6, scl=(1, .45, 1.1), part="Belly")
for s in (-1, 1):
    sphere(p3, WH, (s * .34, -.78, 1.55), .32, scl=(1, .4, 1), part="EyeRings"); sphere(p3, INK, (s * .34, -.9, 1.55), .17, scl=(1, .4, 1), part="Eyes")
    lathe(p3, P("6F7FD0"), [(.2, 0), (.06, .4), (0, .45)], loc=(s * .45, -.2, 2.0), rot=(0, s * 20, 0), seg=6, part="Tufts")
    sphere(p3, P("5A68B8"), (s * .95, .1, 1.05), .45, scl=(.35, .9, .8), part="Wings"); sphere(p3, P("FFC94A"), (s * .25, -.4, .1), .18, scl=(1, 1.3, .5), part="Feet")
lathe(p3, P("FFC94A"), [(.14, 0), (0, .25)], loc=(0, -.95, 1.3), rot=(90, 0, 0), seg=6, part="Beak")
prism(p3, P("FFE066", "NE"), [(0, .45), (.25, .05), (.05, .05), (.2, -.45), (-.25, -.02), (-.05, -.02)], .06, loc=(0, -.92, .95), rot=(90, 0, 0), part="Bolt")
p4 = add("Pet_RainbowPegasus", 4)
sphere(p4, WH, (0, .2, 1.0), .8, scl=(.9, 1.35, .85), part="Body"); sphere(p4, WH, (0, -.75, 1.75), .55, scl=(.9, 1.1, 1), part="Head")
sphere(p4, PINKC, (0, -1.15, 1.6), .3, scl=(1, 1, .8), part="Muzzle")
for s in (-1, 1):
    for y in (-.3, .7): cyl(p4, WH, (s * .35, y, 0), r=.14, h=.55, seg=8, part="Legs"); sphere(p4, GOLD, (s * .35, y, .02), .16, scl=(1, 1, .5), part="Hooves")
    prism(p4, WH2, [(0, 0), (1.2, .5), (1.0, -.2), (.5, -.4)], .08, loc=(s * .7, .1, 1.4), rot=(90, 0, 90 + s * 90), part="Wings")
    lathe(p4, WH, [(.14, 0), (0, .3)], loc=(s * .25, -.65, 2.25), seg=6, part="Ears")
for k, c in enumerate(RB[:6]): sphere(p4, c, (0, -.5 + k * .22, 2.2 - k * .12), .2, part="Mane" + str(k % 3))
tube(p4, RB[4], [(0, 1.3, 1.1), (.2, 1.8, .8), (.1, 2.0, .4)], r=.16, seg=6, smooth=3, part="Tail")
face(p4, -1.08, 1.95, sep=.24, er=.11)
p5 = add("Pet_SkyWhale", 4)
sphere(p5, SKY, (0, .2, 1.2), 1.1, scl=(.95, 1.5, .85), part="Body"); sphere(p5, WH, (0, -.3, .9), .75, scl=(.9, 1.4, .5), part="Belly")
for s in (-1, 1): sphere(p5, SKY, (s * 1.0, -.1, .8), .45, scl=(1.2, .6, .25), rot=(0, s * 20, 0), part="Fins")
tube(p5, SKY, [(0, 1.5, 1.2), (0, 2.1, 1.5)], r=.35, r2=.2, seg=8, smooth=1, part="Tail")
for s in (-1, 1): sphere(p5, SKY, (s * .45, 2.25, 1.6), .4, scl=(1.2, .5, .25), part="Fluke")
for k, (x, z, r) in enumerate([(0, 2.35, .3), (.25, 2.6, .22), (-.25, 2.65, .22)]): sphere(p5, WH, (x, -.2, z), r, part="Spout")
face(p5, -1.38, 1.35, sep=.42, er=.14); sphere(p5, P("FFF2A8", "NE"), (0, -1.0, .45), .1, part="Glow")

objs = realize(models, 'W2_Cloud')
