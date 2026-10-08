import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Longer bridges (86-stud span) after the stages became 10% shorter / wider (Claude 2026-10-03). Roblox-frame geometry via R2B.
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
def bez(p0, p1, p2, p3, t):
    u = 1 - t; return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t
def curve(end, n=32):
    P0 = Vector((0, 0, 0)); P3 = Vector(end); P1 = Vector((end[0] * .48, 0, 0)); P2 = P3 - Vector((end[0] * .48, 0, 0))
    pts = [bez(P0, P1, P2, P3, i / n) for i in range(n + 1)]; fr = []
    for i, p in enumerate(pts):
        t = pts[min(i + 1, n)] - pts[max(i - 1, 0)]; t.y = 0; t.normalize(); fr.append((p, Vector((-t.z, 0, t.x))))
    return fr
def deck(m, pc, F, w, thick, part="Deck"):
    tb = bmesh.new(); rows = []
    for p, r in F:
        rows.append([tb.verts.new(R2B(v)) for v in (p - r * w / 2, p + r * w / 2, p + r * w / 2 - Vector((0, thick, 0)), p - r * w / 2 - Vector((0, thick, 0)))])
    for A, B in zip(rows, rows[1:]):
        for k in range(4): tb.faces.new((A[k], A[(k + 1) % 4], B[(k + 1) % 4], B[k]))
    tb.faces.new(list(reversed(rows[0]))); tb.faces.new(rows[-1]); bmesh.ops.recalc_face_normals(tb, faces=tb.faces); _merge(m.bm(part, pc), tb)
def edge(F, off, dy): return [R2B(p + r * off + Vector((0, dy, 0))) for p, r in F]
models = []; X = [0]
def add(name):
    X[0] += 140; m = Model(name, at=(X[0], 0, 0)); models.append(m); return m
# Sakura -> Candy: wafer deck, frosting edges, candy-cane posts with gumdrops
b = add("BridgeSakuraCandy2"); F = curve((85, 4, 55))
deck(b, P("E9B872"), F, 10, 1.0)
for s in (-1, 1):
    tube(b, P("FFC2DA"), edge(F, s * 5.1, .05), r=.45, seg=8, smooth=1, part="Frosting"); tube(b, P("FF7FB0"), edge(F, s * 5.0, 2.6), r=.28, seg=8, smooth=1, part="Rails")
for i in range(0, len(F), 3):
    p, r = F[i]
    for s in (-1, 1):
        base = p + r * s * 5.0
        stripes(b, [P("FF4D6D"), P("FFFFFF")], [R2B(base), R2B(base + Vector((0, 2.7, 0)))], r=.32, seglen=.7, seg=8, part="Posts", smooth=1)
        sphere(b, P("8FE8C8", "SA"), R2B(base + Vector((0, 3.0, 0))), .5, scl=(1, 1, .8), part="Gumdrops")
for i in range(1, len(F) - 1, 2):
    p, r = F[i]; rbox(b, P("C99550"), R2B(p + Vector((0, .02, 0))), (9.6, .25, .12), r=.04, rot=(0, 0, -math.degrees(math.atan2(r.x, r.z))), part="Grooves")
# Candy -> Atlantis: pale stone causeway, turquoise mosaic, pearl / coral posts
b = add("BridgeCandyAtlantis2"); F = curve((85, -14, -70))
deck(b, P("E6DFCF"), F, 10, 1.4)
for s in (-1, 1):
    tube(b, P("3FD0D4"), edge(F, s * 4.3, .05), r=.22, seg=6, smooth=1, part="Mosaic"); tube(b, P("C9C0AB"), edge(F, s * 5.0, 2.2), r=.35, seg=8, smooth=1, part="Rails")
for i in range(0, len(F), 3):
    p, r = F[i]
    for s in (-1, 1):
        base = p + r * s * 5.0
        cyl(b, P("E6DFCF"), R2B(base), r=.42, h=2.4, seg=10, bev=.1, part="Posts")
        if i % 6 == 0: sphere(b, P("E9FFFF", "NE"), R2B(base + Vector((0, 2.75, 0))), .42, part="Pearls")
        else: sphere(b, P("FF7A5C"), R2B(base + Vector((0, 2.6, 0))), .38, scl=(1, 1, .7), part="CoralKnobs")
# Atlantis -> Toybox: wooden train-track bridge with block posts
PRIM = [P("FF4B4B"), P("3E8BFF"), P("FFD23F"), P("44C767"), P("FF9A3C"), P("9C6BFF")]
METAL = P("B8C2D6", "ME")
b = add("BridgeAtlantisToybox2"); F = curve((85, 8, 60))
deck(b, P("D9A066"), F, 10, 1.0)
for s in (-1, 1): tube(b, METAL, [R2B(p + r * s * 1.6 + Vector((0, .25, 0))) for p, r in F], r=.18, seg=6, smooth=1, part="Rails")
for i in range(len(F)):
    p, r = F[i]; rbox(b, P("A8733E"), R2B(p + Vector((0, .05, 0))), (6.0, .9, .25), r=.06, rot=(0, 0, -math.degrees(math.atan2(r.x, r.z)) + 90), part="Sleepers")
for i in range(0, len(F), 3):
    p, r = F[i]
    for s in (-1, 1): rbox(b, PRIM[(i // 3 + (s > 0)) % 6], R2B(p + r * s * 5.0 + Vector((0, 1.2, 0))), (1.6, 1.6, 1.6), r=.22, part="PostBlocks")
# Toybox -> Clockwork: brass girder bridge
BRASS, COPPER_D = P("E0B04A", "ME"), P("9A5530")
b = add("BridgeToyboxClockwork2"); F = curve((85, 8, -80))
deck(b, P("8C7B6B"), F, 10, 1.2)
for s in (-1, 1):
    tube(b, BRASS, [R2B(p + r * s * 5.0 + Vector((0, 2.8, 0))) for p, r in F], r=.3, seg=8, smooth=1, part="Rails")
    tube(b, COPPER_D, [R2B(p + r * s * 5.1 + Vector((0, .1, 0))) for p, r in F], r=.35, seg=8, smooth=1, part="Kerb")
    for i in range(0, len(F) - 2, 2):
        p, r = F[i]; q, rq = F[i + 2]
        tube(b, COPPER_D, [R2B(p + r * s * 5.0), R2B(p + r * s * 5.0 + Vector((0, 2.8, 0)))], r=.18, seg=6, smooth=1, part="Posts")
        tube(b, COPPER_D, [R2B(p + r * s * 5.0 + Vector((0, .2, 0))), R2B(q + rq * s * 5.0 + Vector((0, 2.6, 0)))], r=.12, seg=6, smooth=1, part="Braces")
for i in range(0, len(F), 6):
    p, r = F[i]
    for s in (-1, 1): sphere(b, BRASS, R2B(p + r * s * 5.0 + Vector((0, 3.1, 0))), .38, part="Knobs")

objs = realize(models, 'W2_Bridges2')
