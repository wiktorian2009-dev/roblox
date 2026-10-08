import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Giant Toybox v2 pieces (Claude 2026-10-03): the stage becomes the inside of an open toy box.
from w2lib import *
RED, BLUE, YEL, GRN, ORA, PUR = P("FF4B4B"), P("3E8BFF"), P("FFD23F"), P("44C767"), P("FF9A3C"), P("9C6BFF")
WOOD, WOOD_D, WOOD_L, WHITE = P("E2B57E"), P("A8733E"), P("F0CC98"), P("FFFFFF")
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 10; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def star(r1, r2): return [(math.cos(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2), math.sin(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2)) for i in range(10)]
# wall segment: 44 long (X), 16 tall, 3 thick; painted inner face toward -Y (Roblox -Z)
w = add("ToyBoxWall", 46)
rbox(w, WOOD, (0, 0, 0), (44, 3, 15.2), r=.5, base=True, part="Board")
for k in range(4): rbox(w, WOOD_D, (-16.5 + k * 11, -1.52, 7.6), (.25, .1, 14.6), r=.05, part="Seams")
rbox(w, WOOD_D, (0, 0, 15.2), (44.4, 3.6, 1.2), r=.5, base=True, part="TopRail")
rbox(w, RED, (0, -1.56, 11.6), (44, .18, 1.6), r=.08, part="StripeA")
rbox(w, BLUE, (0, -1.56, 9.6), (44, .18, 1.0), r=.08, part="StripeB")
shapes = [("star", YEL), ("heart", RED), ("circle", GRN), ("star", PUR), ("heart", ORA)]
for k, (sh, col) in enumerate(shapes):
    x = -17.6 + k * 8.8; z = 4.6 + (k % 2) * 1.2
    if sh == "star": prism(w, col, star(2.0, .85), .15, loc=(x, -1.58, z), rot=(90, 0, 0), part="Decals")
    elif sh == "heart": prism(w, col, heart_poly(1.3), .15, loc=(x, -1.58, z - .6), rot=(90, 0, 0), part="Decals")
    else: cyl(w, col, (x, -1.5, z), r=1.6, h=.15, seg=20, rot=(90, 0, 0), part="Decals")
c = add("ToyBoxCorner", 8)
rbox(c, WOOD_D, (0, 0, 0), (5, 5, 17.5), r=.6, base=True, part="Post")
for z, col in ((5, RED), (10, BLUE)): rbox(c, col, (0, 0, z), (5.15, 5.15, 1.0), r=.3, part="Bands")
sphere(c, RED, (0, 0, 20.2), 2.9, part="Knob"); torus(c, YEL, (0, 0, 20.2), R=2.9, r=.3, seg=24, rseg=6, part="KnobRing")
cr = add("GiantCrayon", 30)
cyl(cr, P("FF5A7A"), (0, 0, 0), r=1.6, h=22, seg=8, part="Wax"); lathe(cr, P("FF5A7A"), [(1.6, 22), (.45, 26), (0, 26.3)], seg=8, part="Wax")
for z in (2.0, 18.5): cyl(cr, WHITE, (0, 0, z), r=1.66, h=1.6, seg=8, part="Wrap")
cyl(cr, P("2A2433"), (0, 0, 9.0), r=1.66, h=4.5, seg=8, part="Label")
bl = add("GiantBall", 14)
for i in range(6):
    a0 = 360 / 6 * i
    lathe(bl, [RED, YEL, BLUE, GRN, ORA, WHITE][i], [(.01, -6), (3.0, -5.2), (5.2, -3), (6, 0), (5.2, 3), (3.0, 5.2), (.01, 6)], loc=(0, 0, 6), seg=4, part="Seg" + str(i), rot=(0, 0, a0)) if False else None
# beach ball: 6 coloured wedges built as partial lathes
def wedge(m, pc, a0, a1, part):
    tb = bmesh.new(); prof = [(.01, -6), (3.0, -5.2), (5.2, -3), (6, 0), (5.2, 3), (3.0, 5.2), (.01, 6)]; seg = 6; rows = []
    for k in range(seg + 1):
        a = math.radians(a0 + (a1 - a0) * k / seg)
        rows.append([tb.verts.new((math.cos(a) * r, math.sin(a) * r, z + 6)) for r, z in prof])
    for A, B in zip(rows, rows[1:]):
        for i in range(len(prof) - 1): tb.faces.new((A[i], A[i + 1], B[i + 1], B[i]))
    for R in (rows[0], rows[-1]):
        ctr = tb.verts.new((0, 0, 6))
        for i in range(len(prof) - 1): tb.faces.new((R[i], R[i + 1], ctr))
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces); from w2lib import _merge; _merge(m.bm(part, pc), tb)
for i, col in enumerate([RED, YEL, BLUE, GRN, ORA, WHITE]): wedge(bl, col, i * 60, (i + 1) * 60, "Seg" + str(i))
cyl(bl, WHITE, (0, 0, 11.9), r=1.2, h=.3, seg=16, part="Cap")

objs = realize(models, 'W2_ToyboxV2')
