import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Clockwork City v2 detail pack (Claude 2026-10-03): city-layout pieces + street detail. Roblox-frame pieces use R2B.
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
BRASS, BRASS_D, COPPER, COPPER_D = P("E0B04A", "ME"), P("B8862E", "ME"), P("D07A48"), P("9A5530")
IRON, CREAM, TEAL, TEAL_D, STONE, STONE_D = P("4A4F5C"), P("F6E7C8"), P("3FBFB4"), P("2C8F88"), P("CDB898"), P("A89272")
WHITE, INK, GLASS, WARM, WOOD, RED, YEL, PINK, GRN, BLUE = P("FFFFFF"), P("2A2433"), P("BFEFFF", "GL", .15), P("FFE2A0", "NE"), P("B07A4A"), P("FF5A5A"), P("FFD23F"), P("FF9AC8"), P("6CCB6A"), P("6FA8FF")
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 10; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def gear(m, pc, loc, R, thick, teeth, axis="z", part="Gear", hub=None):
    cx, cy, cz = loc
    if axis == "y":
        cyl(m, pc, (cx, cy + thick / 2, cz), r=R * .84, h=thick, seg=max(16, teeth * 2), rot=(90, 0, 0), part=part)
        for i in range(teeth):
            a = 2 * math.pi * i / teeth
            rbox(m, pc, (cx + math.cos(a) * R * .93, cy, cz + math.sin(a) * R * .93), (R * .2, thick, 2 * math.pi * R / teeth * .5), r=0, rot=(0, -math.degrees(a), 0), part=part)
        cyl(m, hub or pc, (cx, cy + thick * .8, cz), r=R * .22, h=thick * 1.6, seg=12, rot=(90, 0, 0), part=part + "Hub")
    else:
        cyl(m, pc, (cx, cy, cz - thick / 2), r=R * .84, h=thick, seg=max(16, teeth * 2), part=part)
        for i in range(teeth):
            a = 2 * math.pi * i / teeth
            rbox(m, pc, (cx + math.cos(a) * R * .93, cy + math.sin(a) * R * .93, cz), (R * .2, 2 * math.pi * R / teeth * .5, thick), r=0, rot=(0, 0, math.degrees(a)), part=part)
def window(m, loc, w=1.4, h=1.8, face="-y"):
    off = -.05 if face == "-y" else .05
    rbox(m, BRASS_D, (loc[0], loc[1] + off, loc[2]), (w + .4, .2, h + .4), r=.15, part="WinFrames")
    rbox(m, GLASS, (loc[0], loc[1] + off * 2, loc[2]), (w, .2, h), r=.1, part="Windows")
    rbox(m, BRASS_D, (loc[0], loc[1] + off * 3, loc[2]), (.12, .1, h), r=0, part="WinFrames")
# 1) plaza floor mosaic (r 27, thin) and tram loop (r 21)
pz = add("GearPlaza", 60)
cyl(pz, P("EADBB8"), (0, 0, 0), r=27, h=.12, seg=48, part="Floor")
gear(pz, P("E0B04A"), (0, 0, .16), 19.5, .06, 28, part="Inlay")
cyl(pz, P("EADBB8"), (0, 0, .17), r=15.2, h=.06, seg=40, part="Floor2")
for i in range(16):
    a = 2 * math.pi * i / 16
    rbox(pz, TEAL, (math.cos(a) * 9.5, math.sin(a) * 9.5, .2), (9, .5, .05), r=0, rot=(0, 0, math.degrees(a)), part="Spokes")
torus(pz, TEAL_D, (0, 0, .15), R=25.5, r=.35, seg=48, rseg=4, part="Ring")
tl = add("TramLoop", 46)
for rr in (20.0, 22.0): torus(tl, BRASS_D, (0, 0, .5), R=rr, r=.16, seg=72, rseg=6, part="Rails")
for i in range(48):
    a = 2 * math.pi * i / 48
    rbox(tl, IRON, (math.cos(a) * 21, math.sin(a) * 21, .2), (3.2, .6, .3), r=.05, rot=(0, 0, math.degrees(a)), part="Sleepers")
tr = add("SteamTram", 10)
for y in (-1.6, 1.6):
    for s in (-1, 1): cyl(tr, IRON, (s * 1.25, y, .8), r=.75, h=.3, seg=12, rot=(0, 90, 0), part="Wheels")
rbox(tr, TEAL, (0, 0, 1.0), (2.6, 6.2, 3.6), r=.4, base=True, part="Body")
rbox(tr, CREAM, (0, 0, 2.4), (2.66, 6.0, 1.3), r=.2, part="Band")
for y in (-1.9, 0, 1.9):
    for s in (-1, 1): rbox(tr, GLASS, (s * 1.34, y, 2.5), (.1, 1.3, 1.0), r=.15, part="Windows")
rbox(tr, BRASS, (0, 0, 4.6), (3.0, 6.6, .4), r=.2, base=True, part="Roof")
cyl(tr, IRON, (0, -2.2, 5.0), r=.35, r2=.55, h=1.4, seg=10, part="Chimney"); sphere(tr, WARM, (0, -3.15, 2.0), .4, part="Lamp")
gear(tr, BRASS, (1.36, 0, 1.5), .7, .12, 8, axis="y", part="Deco")
tw = add("TramWagon", 9)
for y in (-1.3, 1.3):
    for s in (-1, 1): cyl(tw, IRON, (s * 1.25, y, .8), r=.75, h=.3, seg=12, rot=(0, 90, 0), part="Wheels")
rbox(tw, COPPER, (0, 0, 1.0), (2.6, 5.0, 2.0), r=.3, base=True, part="Body")
for k, c in enumerate([RED, YEL, BLUE]): sphere(tw, c, (0, -1.6 + k * 1.6, 3.4), .8, part="Cargo" + str(k))
# 2) airship
air = add("Airship", 40)
lathe(air, CREAM, [(0, -14), (2.6, -12.5), (4.6, -9), (5.4, -4), (5.5, 0), (5.2, 5), (4.0, 10), (2.0, 13.2), (0, 14)], loc=(0, 0, 0), rot=(90, 0, 0), seg=22, part="Envelope")
for k, y in enumerate((-8, 0, 8)): torus(air, TEAL, (0, y, 0), R=5.45 if y == 0 else 5.0, r=.32, rot=(90, 0, 0), seg=28, rseg=6, part="Stripes")
for s in (-1, 1):
    prism(air, TEAL, [(0, 0), (3.6, 0), (2.2, 3.4), (0, 3.4)], .3, loc=(s * .15, 10.5, 0), rot=(90, 0, 90 if s > 0 else -90), part="Fins")
prism(air, TEAL, [(0, 0), (3.6, 0), (2.2, 3.4), (0, 3.4)], .3, loc=(0, 10.5, .15), rot=(0, 0, 90), part="Fins")
rbox(air, COPPER, (0, 0, -7.4), (2.8, 7.5, 2.2), r=.5, part="Gondola")
for y in (-2.4, -.8, .8, 2.4): rbox(air, GLASS, (1.42, y, -7.2), (.1, 1.0, .9), r=.2, part="Windows")
for k, (x, y) in enumerate(((-1.2, -2.5), (1.2, -2.5), (-1.2, 2.5), (1.2, 2.5))): tube(air, IRON, [(x, y, -6.3), (x * 2.2, y, -2.5)], r=.08, seg=6, smooth=1, part="Ropes")
cyl(air, BRASS, (0, 3.8, -7.4), r=.25, h=1.2, seg=8, rot=(90, 0, 0), part="Prop")
for k in range(3):
    a = 120 * k; rbox(air, BRASS_D, (0, 5.0, -7.4), (.3, .12, 3.2), r=.08, rot=(0, a, 0), part="Prop")
# 3) terrace wall, stairs (rise toward Roblox +X), canal edge + bridge, fountain
twl = add("TerraceWall", 22)
rbox(twl, STONE, (0, 0, 0), (20, 2, 6), r=.3, base=True, part="Stones")
for k in range(5):
    for j in range(2): rbox(twl, STONE_D, (-8 + k * 4 + (j % 2) * 2, -1.02, 1.5 + j * 3), (.15, .1, 2.8), r=0, part="Joints")
rbox(twl, STONE_D, (0, -1.02, 3.0), (20, .1, .15), r=0, part="Joints")
rbox(twl, BRASS_D, (0, 0, 6), (20.4, 2.6, .6), r=.2, base=True, part="Cap")
for x in (-6, 6):
    rbox(twl, BRASS, (x, -1.25, 4.4), (.3, .5, .3), r=.05, part="Brackets"); sphere(twl, WARM, (x, -1.6, 4.1), .45, part="Lights")
stw = add("StoneStairs", 14)
tbs = 12
for k in range(tbs):
    run = 10.0 / tbs; x = -5 + run * (k + .5); h = 6.0 * (k + 1) / tbs
    rbox(stw, STONE if k % 2 else P("D8C4A4"), R2B((x, h / 2, 0)), (run + .02, 8, h), r=.05, part="Steps")
for s in (-4.3, 4.3):
    tube(stw, BRASS, [R2B((-5, 3.0, s)), R2B((5, 9.0, s))], r=.14, seg=8, smooth=1, part="Rails")
    for x in (-4.5, 0, 4.5): tube(stw, BRASS_D, [R2B((x, 6.0 * (x + 5) / 10, s)), R2B((x, 6.0 * (x + 5) / 10 + 3.0, s))], r=.1, seg=6, smooth=1, part="Posts")
ce = add("CanalEdge", 22)
rbox(ce, STONE, (0, 0, 0), (20, 1.4, .9), r=.2, base=True, part="Curb")
for x in (-8, -2, 4, 9.5): cyl(ce, BRASS_D, (x, 0, .9), r=.1, h=1.6, seg=6, part="Posts")
tube(ce, BRASS, [(-9.6, 0, 2.3), (9.6, 0, 2.3)], r=.08, seg=6, smooth=1, part="Rail")
cb = add("CanalBridge", 12)
torus(cb, BRASS, (0, 0, -1.2), R=5.6, r=.2, arc=100, rot=(90, 0, 40), seg=20, rseg=6, part="Arch")
tbm = bmesh.new(); rows = []
for i in range(13):
    t = i / 12; x = -5.5 + 11 * t; z = 1.2 * math.sin(math.pi * t)
    rows.append([tbm.verts.new(v) for v in ((x, -1.6, z), (x, 1.6, z), (x, 1.6, z - .35), (x, -1.6, z - .35))])
for A, B in zip(rows, rows[1:]):
    for k in range(4): tbm.faces.new((A[k], A[(k + 1) % 4], B[(k + 1) % 4], B[k]))
tbm.faces.new(list(reversed(rows[0]))); tbm.faces.new(rows[-1]); bmesh.ops.recalc_face_normals(tbm, faces=tbm.faces); _merge(cb.bm("Deck", WOOD), tbm)
for s in (-1.6, 1.6): tube(cb, BRASS, [(-5.5, s, 1.0 + 0), (0, s, 2.4), (5.5, s, 1.0)], r=.09, seg=6, smooth=3, part="Rails")
gf = add("GearFountain", 14)
gear(gf, STONE, (0, 0, .6), 5.2, 1.2, 18, part="Basin")
cyl(gf, P("6FC8FF", "GL", .25), (0, 0, .8), r=4.1, h=.4, seg=28, part="Water")
cyl(gf, BRASS_D, (0, 0, 1.0), r=.7, h=4.0, seg=12, part="Column")
for z, r in ((2.6, 2.0), (4.4, 1.3)): gear(gf, BRASS, (0, 0, z), r, .35, 12, part="Tiers")
for z, r in ((2.85, 1.65), (4.65, 1.0)): cyl(gf, P("6FC8FF", "GL", .25), (0, 0, z - .05), r=r, h=.12, seg=20, part="Water")
sphere(gf, P("A8E6FF", "NE", .2), (0, 0, 5.4), .45, part="Jet")
# 4) street detail
bn = add("Bench", 6)
for x in (-1.6, 1.6): rbox(bn, IRON, (x, 0, 0), (.25, 1.2, 1.0), r=.05, base=True, part="Legs")
rbox(bn, WOOD, (0, 0, 1.0), (4.0, 1.2, .2), r=.05, base=True, part="Seat")
rbox(bn, WOOD, (0, .55, 1.6), (4.0, .15, .9), r=.05, base=True, part="Back")
gear(bn, BRASS, (0, .65, 2.1), .35, .08, 8, axis="y", part="Deco")
br_ = add("Barrel", 3)
lathe(br_, WOOD, [(.0, 0), (.65, 0), (.78, .7), (.65, 1.4), (0, 1.4)], seg=14, part="Wood")
for z in (.25, 1.15): torus(br_, IRON, (0, 0, z), R=.72, r=.06, seg=16, rseg=4, part="Hoops")
cs = add("CrateStack", 6)
rbox(cs, WOOD, (0, 0, 0), (4, 4, 4), r=.15, base=True, part="Crate")
for z in (.2, 3.8): rbox(cs, P("8A5A30"), (0, 0, z), (4.08, 4.08, .25), r=.05, part="Slats")
rbox(cs, WOOD, (1.0, .6, 4), (1.8, 1.8, 1.8), r=.1, base=True, rot=(0, 0, 20), part="Small")
fb = add("FlowerBox", 5)
rbox(fb, COPPER_D, (0, 0, 0), (3.2, 1.0, .8), r=.1, base=True, part="Box")
for k in range(5):
    sphere(fb, GRN, (-1.2 + k * .6, 0, 1.0), .35, part="Leaves"); sphere(fb, [RED, YEL, PINK, WHITE, BLUE][k], (-1.2 + k * .6, -.1, 1.3), .2, part="Flowers" + str(k % 3))
tp = add("Topiary", 4)
lathe(tp, COPPER, [(0, 0), (.9, 0), (1.1, 1.2), (0, 1.2)], seg=12, part="Pot")
cyl(tp, WOOD, (0, 0, 1.2), r=.12, h=1.4, seg=6, part="Trunk"); sphere(tp, GRN, (0, 0, 3.2), 1.25, part="Ball"); sphere(tp, P("8BDB82"), (.3, -.5, 3.6), .5, part="Ball")
sc = add("StreetClock", 4)
cyl(sc, IRON, (0, 0, 0), r=.2, h=6, seg=8, part="Post"); cyl(sc, IRON, (0, 0, 0), r=.45, h=.5, seg=8, part="Post")
cyl(sc, BRASS, (0, .3, 6.8), r=1.0, h=.6, seg=20, rot=(90, 0, 0), part="Case")
for s, yy in ((-1, -.32), (1, .32)):
    cyl(sc, WHITE, (0, yy + s * .02, 6.8), r=.85, h=.04, seg=20, rot=(90, 0, 0), part="Dial")
    rbox(sc, INK, (0, yy + s * .06, 7.05), (.08, .04, .5), r=0, part="Hands"); rbox(sc, INK, (.17, yy + s * .06, 6.8), (.35, .04, .07), r=0, part="Hands")
sphere(sc, BRASS, (0, 0, 7.9), .25, part="Case")
sp = add("SignPost", 4)
cyl(sp, WOOD, (0, 0, 0), r=.18, h=5.5, seg=8, part="Post")
for k, (z, a, c) in enumerate(((4.6, 20, TEAL), (3.8, 160, RED), (3.0, 80, YEL))):
    ang = math.radians(a)
    prism(sp, c, [(0, -.35), (2.2, -.35), (2.7, 0), (2.2, .35), (0, .35)], .15, loc=(0, 0, z), rot=(90, 0, a), part="Arrows" + str(k))
bu = add("Bunting", 32)
pts = [(-15 + 30 * t / 20, 0, -1.6 * math.sin(math.pi * t / 20)) for t in range(21)]
tube(bu, P("F6E7C8"), pts, r=.05, seg=4, smooth=1, part="String")
cols = [RED, YEL, TEAL, PINK, BLUE, GRN]
for i in range(1, 20, 1):
    x, y, z = pts[i]; prism(bu, cols[i % 6], [(-.45, 0), (.45, 0), (0, -1.0)], .05, loc=(x, 0, z - .02), rot=(90, 0, 0), part="Flags" + str(i % 3))
# 5) route buildings + detailed house
aw = add("Awning", 10)
for x in (-3.6, 3.6):
    for y in (-2.6, 2.6): cyl(aw, IRON, (x, y, 0), r=.18, h=7.6, seg=8, part="Posts")
rbox(aw, BRASS_D, (0, 0, 7.6), (8.2, 6.2, .4), r=.1, base=True, part="Deck")
for k in range(6): rbox(aw, [RED, CREAM][k % 2], (-3.4 + k * 1.36, -3.25, 7.2), (1.36, .2, .8), r=.05, part="Valance" + str(k % 2))
fr = add("FlatRoofHouse", 12)
rbox(fr, P("FFD9C2"), (0, 0, 0), (10, 10, 12), r=.4, base=True, part="Walls")
rbox(fr, COPPER_D, (0, 0, 12), (10.6, 10.6, .7), r=.2, base=True, part="RoofEdge")
for x in (-2.5, 2.5):
    for z in (3.5, 8.0): window(fr, (x, -5.0, z))
rbox(fr, COPPER_D, (0, -5.06, 0), (2.0, .2, 3.4), r=.5, base=True, part="Door")
rbox(fr, P("FFFFFF", "SP", .0), (0, 0, 12.7), (.1, .1, .1), r=0, part="Marker")
cyl(fr, COPPER, (3.5, 3.5, 12.7), r=.6, h=2.4, seg=10, part="Chimney")
tw2 = add("TallWorkshop", 14)
rbox(tw2, CREAM, (0, 0, 0), (12, 12, 16), r=.5, base=True, part="Walls")
rbox(tw2, BRASS_D, (0, 0, 16), (12.6, 12.6, .8), r=.25, base=True, part="RoofEdge")
for z in (4, 9): window(tw2, (-3.2, -6.0, z)); window(tw2, (3.2, -6.0, z))
gear(tw2, BRASS, (0, -6.3, 12.6), 2.6, .4, 12, axis="y", part="FacadeGear", hub=TEAL)
rbox(tw2, COPPER_D, (0, -6.06, 0), (2.4, .2, 3.8), r=.6, base=True, part="Door")
for z in (2, 6, 10, 14): tube(tw2, COPPER, [(6.1, -3, z), (6.1, 3, z)], r=.15, seg=6, smooth=1, part="Pipes")
hc = add("ClockHouseC", 14)
rbox(hc, P("FFF2DD"), (0, 0, 0), (10, 8, 12), r=.4, base=True, part="Walls")
prism(hc, P("E8785A"), [(-5.8, 0), (5.8, 0), (0, 4.6)], 8.4, loc=(0, 4.2, 12), rot=(90, 0, 0), part="Roof")
rbox(hc, BRASS_D, (0, 0, 6), (10.3, 8.3, .5), r=.15, part="Floorline")
for x in (-2.8, 2.8): window(hc, (x, -4.0, 8.8)); window(hc, (x, -4.0, 3.2), w=1.2, h=1.6)
rbox(hc, COPPER_D, (0, -4.06, 0), (2.0, .2, 3.6), r=.5, base=True, part="Door")
rbox(hc, BRASS, (0, -4.9, 6.1), (6.5, 1.8, .25), r=.08, part="Balcony")
for x in (-3.0, -1.5, 0, 1.5, 3.0): cyl(hc, BRASS_D, (x, -5.6, 6.2), r=.06, h=1.0, seg=6, part="BalconyRail")
tube(hc, BRASS_D, [(-3.2, -5.6, 7.2), (3.2, -5.6, 7.2)], r=.06, seg=6, smooth=1, part="BalconyRail")
for x in (-2.8, 2.8):
    rbox(hc, COPPER_D, (x, -4.35, 7.3), (2.0, .6, .45), r=.08, part="FlowerBoxes")
    for k in range(4): sphere(hc, [RED, PINK, YEL, WHITE][k], (x - .7 + k * .45, -4.5, 7.7), .2, part="Flowers")
rbox(hc, TEAL, (0, -4.9, 4.4), (3.0, 1.6, .2), r=.1, rot=(-25, 0, 0), part="Canopy")
cyl(hc, COPPER, (3.2, 2.0, 13.5), r=.6, h=3.4, seg=10, part="Chimney")
gear(hc, BRASS, (-4.2, -4.15, 10.6), .8, .15, 8, axis="y", part="Sign", hub=TEAL)

objs = realize(models, 'W2_ClockworkV2')
