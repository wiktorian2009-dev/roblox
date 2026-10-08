import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Cloud -> Cosmic starry bridge (Neon dropped, Cosmic moved into its slot) - Claude 2026-10-03. End (85, 12, -15) in Roblox local.
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
NAVY, GOLD, GOLD_D, CYN, VIO_N, STARW = P("2E2A5C"), P("FFD25A", "ME"), P("E0A830", "ME"), P("7FE9FF", "NE"), P("A98BFF", "NE"), P("FFF6C8", "NE")
def star(r1, r2): return [(math.cos(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2), math.sin(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2)) for i in range(10)]
def bez(p0, p1, p2, p3, t):
    u = 1 - t; return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t
def curve(end, n=32):
    P0 = Vector((0, 0, 0)); P3 = Vector(end); P1 = Vector((end[0] * .48, 0, 0)); P2 = P3 - Vector((end[0] * .48, 0, 0))
    pts = [bez(P0, P1, P2, P3, i / n) for i in range(n + 1)]; fr = []
    for i, p in enumerate(pts):
        t = pts[min(i + 1, n)] - pts[max(i - 1, 0)]; t.y = 0; t.normalize(); fr.append((p, Vector((-t.z, 0, t.x))))
    return fr
models = []
b = Model("BridgeCloudCosmic", at=(0, 0, 0)); models.append(b); F = curve((85, 12, -15))
tb = bmesh.new(); rows = []
for p, r in F: rows.append([tb.verts.new(R2B(v)) for v in (p - r * 5, p + r * 5, p + r * 5 - Vector((0, 1.0, 0)), p - r * 5 - Vector((0, 1.0, 0)))])
for A, B in zip(rows, rows[1:]):
    for k in range(4): tb.faces.new((A[k], A[(k + 1) % 4], B[(k + 1) % 4], B[k]))
tb.faces.new(list(reversed(rows[0]))); tb.faces.new(rows[-1]); bmesh.ops.recalc_face_normals(tb, faces=tb.faces); _merge(b.bm("Deck", NAVY), tb)
for s in (-1, 1):
    tube(b, GOLD_D, [R2B(p + r * s * 5.05 + Vector((0, .05, 0))) for p, r in F], r=.3, seg=8, smooth=1, part="Kerb")
    tube(b, CYN, [R2B(p + r * s * 5.0 + Vector((0, 2.5, 0))) for p, r in F], r=.18, seg=6, smooth=1, part="Rails")
for i in range(0, len(F), 3):
    p, r = F[i]
    for s in (-1, 1):
        base = p + r * s * 5.0
        tube(b, GOLD, [R2B(base), R2B(base + Vector((0, 2.6, 0)))], r=.16, seg=6, smooth=1, part="Posts")
        prism(b, STARW if (i // 3) % 2 else VIO_N, star(.55, .24), .12, loc=R2B(base + Vector((0, 3.1, 0))), rot=(90, 0, -math.degrees(math.atan2(r.x, r.z))), part="Stars" + str((i // 3) % 2))
for i in range(1, len(F) - 1, 2):
    p, r = F[i]; prism(b, GOLD, star(.7, .3), .05, loc=R2B(p + Vector((0, .02, 0))), rot=(0, 0, -math.degrees(math.atan2(r.x, r.z))), part="DeckStars")

objs = realize(models, 'W2_CosmicBridge')
