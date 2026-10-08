import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# World 2 layout pack (Claude 2026-10-03): S-curve bridges between offset islands + big themed mountain ranges.
# Bridge geometry is authored in ROBLOX local coordinates and converted with R2B (Roblox X,Y,Z -> Blender -X, Z, Y).
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
def bez(p0, p1, p2, p3, t):
    u = 1 - t
    return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t
def curve(end, n=26):
    P0 = Vector((0, 0, 0)); P3 = Vector(end); P1 = Vector((end[0] * .48, 0, 0)); P2 = P3 - Vector((end[0] * .48, 0, 0))
    pts = [bez(P0, P1, P2, P3, i / n) for i in range(n + 1)]
    frames = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, n)] - pts[max(i - 1, 0)]); t.y = 0; t.normalize()
        frames.append((p, Vector((-t.z, 0, t.x))))
    return frames
def deck(m, pc, frames, w, thick, part="Deck"):
    tb = bmesh.new(); rows = []
    for p, r in frames:
        a = [p - r * w / 2, p + r * w / 2, p + r * w / 2 - Vector((0, thick, 0)), p - r * w / 2 - Vector((0, thick, 0))]
        rows.append([tb.verts.new(R2B(v)) for v in a])
    for A, B in zip(rows, rows[1:]):
        for k in range(4):
            j = (k + 1) % 4; tb.faces.new((A[k], A[j], B[j], B[k]))
    tb.faces.new(list(reversed(rows[0]))); tb.faces.new(rows[-1])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces); _merge(m.bm(part, pc), tb)
def edge_pts(frames, off, dy):
    return [R2B(p + r * off + Vector((0, dy, 0))) for p, r in frames]
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 20; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
b1 = add("BridgeSakuraCandy", 120); F1 = curve((59, 4, 55))
deck(b1, P("E9B872"), F1, 10, 1.0, part="Deck")
for s in (-1, 1):
    tube(b1, P("FFC2DA"), edge_pts(F1, s * 5.1, .05), r=.45, seg=8, smooth=1, part="Frosting")
    tube(b1, P("FF7FB0"), edge_pts(F1, s * 5.0, 2.6), r=.28, seg=8, smooth=1, part="Rails")
for i in range(0, len(F1), 3):
    p, r = F1[i]
    for s in (-1, 1):
        base = p + r * s * 5.0
        stripes(b1, [P("FF4D6D"), P("FFFFFF")], [R2B(base), R2B(base + Vector((0, 2.7, 0)))], r=.32, seglen=.7, seg=8, part="Posts", smooth=1)
        sphere(b1, P("8FE8C8", "SA"), R2B(base + Vector((0, 3.0, 0))), .5, scl=(1, 1, .8), part="Gumdrops")
for i in range(1, len(F1) - 1, 2):
    p, r = F1[i]
    rbox(b1, P("C99550"), R2B(p + Vector((0, .02, 0))), (9.6, .25, .12), r=.04, rot=(0, 0, -math.degrees(math.atan2(r.x, r.z))), part="Grooves")
b2 = add("BridgeCandyAtlantis", 120); F2 = curve((59, -14, -70))
deck(b2, P("E6DFCF"), F2, 10, 1.4, part="Deck")
for s in (-1, 1):
    tube(b2, P("3FD0D4"), edge_pts(F2, s * 4.3, .05), r=.22, seg=6, smooth=1, part="Mosaic")
    tube(b2, P("C9C0AB"), edge_pts(F2, s * 5.0, 2.2), r=.35, seg=8, smooth=1, part="Rails")
for i in range(0, len(F2), 3):
    p, r = F2[i]
    for s in (-1, 1):
        base = p + r * s * 5.0
        cyl(b2, P("E6DFCF"), R2B(base), r=.42, h=2.4, seg=10, bev=.1, part="Posts")
        if i % 6 == 0: sphere(b2, P("E9FFFF", "NE"), R2B(base + Vector((0, 2.75, 0))), .42, part="Pearls")
        else: sphere(b2, P("FF7A5C"), R2B(base + Vector((0, 2.6, 0))), .38, scl=(1, 1, .7), part="CoralKnobs")
def mrange(name, rock, cap, seed, deco=None, peaks=9, length=540, depth=180, hmin=170, hmax=320):
    m = add(name, length); rr = random.Random(seed)
    for i in range(peaks):
        x = -length / 2 + length * (i + .5) / peaks + rr.uniform(-22, 22); z = rr.uniform(-depth * .3, depth * .3)
        h = rr.uniform(hmin, hmax) * (1.0 if i % 3 else 1.12); r = rr.uniform(78, 120)
        prof = [(r, 0), (r * .86, h * .15), (r * .62, h * .38), (r * .42, h * .6), (r * .25, h * .8), (r * .1, h * .94), (0, h)]
        lathe(m, rock, prof, loc=R2B((x, 0, z)), seg=14, wob=.1, seed=seed * 10 + i, part="Rock")
        if cap: lathe(m, cap, [(r * .3, h * .78), (r * .2, h * .86), (r * .1, h * .94), (0, h + 1.5)], loc=R2B((x, 0, z)), seg=14, wob=.08, seed=seed * 10 + i, part="Cap")
        if deco: deco(m, rr, x, z, r, h)
    m.flat("Rock", rock, 30)
    return m
def blossoms(m, rr, x, z, r, h):
    for k in range(5):
        a = rr.uniform(0, 6.283); t = rr.uniform(.08, .35); rad = r * (1 - t * 1.4)
        blob(m, P("FF92C2") if k % 2 else P("FFB7D5"), R2B((x + math.cos(a) * rad, h * t, z + math.sin(a) * rad)), rad=r * .12, n=3, seed=k, flat=.7, seg=8, rings=5, part="Blossom")
def frosting(m, rr, x, z, r, h):
    for k in range(10):
        a = 2 * math.pi * k / 10; zz = h * .76; rad = r * .3
        sphere(m, P("FFC2DA") if k % 2 else P("FFF3DC"), R2B((x + math.cos(a) * rad, zz - 8, z + math.sin(a) * rad)), 6, scl=(1, 1, 2.2), seg=8, rings=5, part="Drips")
def corals(m, rr, x, z, r, h):
    for k in range(4):
        a = rr.uniform(0, 6.283); t = rr.uniform(.15, .55); rad = r * (1 - t * 1.25)
        blob(m, [P("FF7A5C"), P("FF9EC2"), P("B48CFF")][k % 3], R2B((x + math.cos(a) * rad, h * t, z + math.sin(a) * rad)), rad=r * .1, n=3, seed=k, flat=.9, seg=8, rings=5, part="Coral" + str(k % 3))
mrange("SakuraRange", P("B7AECF"), P("FFFFFF"), 3, blossoms)
mrange("CandyRange", P("7A4A2E"), P("FFF3DC"), 5, frosting, hmin=150, hmax=290)
mrange("ReefRange", P("8FB8B8"), None, 7, corals, hmin=160, hmax=300)

objs = realize(models, 'W2_Layout')
