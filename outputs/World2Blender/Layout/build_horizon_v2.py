import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# World 2 horizon v2 (Claude 2026-10-03): natural mountain massifs (rounded summits, ridges, conforming snow) + cloud curtains between islands.
from w2lib import *
from w2lib import _merge
def massif(m, rock, snow, loc, r, h, seed, snowline=.64, ridges=5, jag=.06, seg=20, rings=12, sx=1.0, sy=.85, prock="Rock", psnow="Snow"):
    rnd = random.Random(seed); ph = [rnd.uniform(0, 6.28) for _ in range(3)]
    def R(t):
        t0 = .82
        if t <= t0: return (1 - t) ** .78
        k = (t - t0) / (1 - t0); return (1 - t0) ** .78 * math.sqrt(max(0.0, 1 - k * k))
    grid = []
    for k in range(rings + 1):
        t = k / rings; row = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            ridge = 1 + .13 * math.sin(ridges * a + ph[0] + t * 1.5) + .06 * math.sin((ridges + 3) * a + ph[1])
            rr = r * R(t) * ridge * (1 + rnd.uniform(-jag, jag) * (.4 + t))
            z = h * t + (rnd.uniform(-1, 1) * h * .012 if 0 < k < rings else 0)
            row.append((math.cos(a) * rr * sx, math.sin(a) * rr * sy, z))
        grid.append(row)
    def shell(pc, part, k0, push, drop):
        tb = bmesh.new(); vs = []
        for k in range(k0, rings + 1):
            row = []
            for i, (x, y, z) in enumerate(grid[k]):
                d = math.hypot(x, y) or 1.0
                zz = z + (-rnd.uniform(0, drop) if k == k0 else .4 * push)
                row.append(tb.verts.new((loc[0] + x + x / d * push, loc[1] + y + y / d * push, loc[2] + zz)))
            vs.append(row)
        top = tb.verts.new((loc[0], loc[1], loc[2] + h + push * .6))
        for A, B in zip(vs, vs[1:]):
            for i in range(seg):
                j = (i + 1) % seg; tb.faces.new((A[i], A[j], B[j], B[i]))
        for i in range(seg): tb.faces.new((vs[-1][i], vs[-1][(i + 1) % seg], top))
        if k0 == 0: tb.faces.new(list(reversed(vs[0])))
        bmesh.ops.recalc_face_normals(tb, faces=tb.faces); _merge(m.bm(part, pc), tb)
    shell(rock, prock, 0, 0, 0)
    if snow: shell(snow, psnow, int(rings * snowline), 1.1, h * .07)
def mrange(name, rock, snow, seed, deco=None, length=600, n=7, hmin=200, hmax=330, ridges=5, jag=.06):
    mm = Model(name, at=(len(models) * 800, 0, 0)); models.append(mm); rr = random.Random(seed)
    for i in range(n):
        x = -length / 2 + length * (i + .5) / n + rr.uniform(-25, 25); y = rr.uniform(10, 60)
        h = rr.uniform(hmin, hmax); r = rr.uniform(.42, .55) * h
        massif(mm, rock, snow, (x, y, 0), r, h, seed * 100 + i, ridges=ridges, jag=jag)
        if deco: deco(mm, rr, x, y, r, h)
    for i in range(n - 1):   # rounded foothills in front (toward the islands = Blender -Y = Roblox -Z side)
        x = -length / 2 + length * (i + 1) / n + rr.uniform(-20, 20); h = rr.uniform(70, 120)
        massif(mm, rock, None, (x, rr.uniform(-70, -40), 0), h * .75, h, seed * 100 + 50 + i, ridges=3, jag=.05, rings=8, seg=16)
    mm.sharp["Rock__" + rock] = 34
    return mm
def blossom(mm, rr, x, y, r, h):
    for k in range(4):
        a = rr.uniform(3.4, 6.0); t = rr.uniform(.08, .3)
        blob(mm, P("FF92C2") if k % 2 else P("FFB7D5"), (x + math.cos(a) * r * (1 - t * 1.2) * .95, y + math.sin(a) * r * (1 - t * 1.2) * .8, h * t), rad=r * .11, n=3, seed=k, flat=.7, seg=8, rings=5, part="Blossom")
def drips(mm, rr, x, y, r, h):
    for k in range(7):
        a = 2 * math.pi * k / 7 + rr.uniform(-.2, .2); rad = r * .37
        sphere(mm, P("FFC2DA") if k % 2 else P("FFF3DC"), (x + math.cos(a) * rad, y + math.sin(a) * rad * .85, h * .6), r * .06, scl=(1, 1, 2.4), seg=8, rings=5, part="Drips")
def corals(mm, rr, x, y, r, h):
    for k in range(3):
        a = rr.uniform(3.4, 6.0); t = rr.uniform(.15, .5)
        blob(mm, [P("FF7A5C"), P("FF9EC2"), P("B48CFF")][k], (x + math.cos(a) * r * (1 - t) * .95, y + math.sin(a) * r * (1 - t) * .8, h * t), rad=r * .09, n=3, seed=k, flat=.9, seg=8, rings=5, part="Coral" + str(k))
models = []
mrange("SakuraRangeV2", P("B7AECF"), P("FFFFFF"), 3, blossom)
mrange("CandyRangeV2", P("7A4A2E"), P("FFF3DC"), 5, drips, hmin=180, hmax=300)
mrange("ReefRangeV2", P("8FB8B8"), None, 7, corals, hmin=180, hmax=310, ridges=7, jag=.09)
# Cloud curtain: opaque puffy cloud bank, wide along Roblox Z (= Blender Y), thin along travel (Roblox X = Blender -X)
cc = Model("CloudCurtain", at=(len(models) * 800, 0, 0)); models.append(cc)
rq = random.Random(11)
for i in range(46):
    y = rq.uniform(-175, 175); z = rq.uniform(-95, 135); r = rq.uniform(26, 44)
    sphere(cc, P("F7F9FF") if z > 10 else P("E7EBFA"), (rq.uniform(-12, 12), y, z), r, scl=(.7, 1.15, .85), seg=12, rings=8, part="Puff" if z > 10 else "PuffLow")
for i in range(18):   # lumpy top silhouette
    y = -170 + 340 * i / 17 + rq.uniform(-8, 8)
    sphere(cc, P("FFFFFF"), (rq.uniform(-8, 8), y, 135 + rq.uniform(0, 25)), rq.uniform(22, 34), scl=(.7, 1, .9), seg=12, rings=8, part="Puff")

objs = realize(models, 'W2_Horizon2')
