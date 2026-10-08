import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Detailed Cosmic observatory (Claude 2026-10-03). Same footprint/heights as v1: platform 44x44, walkable top 12.8, dome base 26.2, r 16.
# Entrance on Blender +X (= Roblox -X, where the grand stairs arrive). Small pieces use sharp boxes (r=0) to keep triangles down.
from w2lib import *
from w2lib import _merge
NAVY, INDIGO, VIOLET, LAV = P("2E2A5C"), P("3B3480"), P("7E5BEF"), P("B9A6FF")
GOLD, GOLD_D = P("FFD25A", "ME"), P("E0A830", "ME")
CYN, PNK, VIO_N, STARW = P("7FE9FF", "NE"), P("FF8AD8", "NE"), P("A98BFF", "NE"), P("FFF6C8", "NE")
MAR, MAR_D = P("EDE8FF"), P("CFC6F2")
models = []
def star(r1, r2): return [(math.cos(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2), math.sin(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2)) for i in range(10)]
def crescent(r):
    return [(math.cos(math.radians(-120 + 240 * i / 12)) * r, math.sin(math.radians(-120 + 240 * i / 12)) * r) for i in range(13)] + [(math.cos(math.radians(120 - 240 * i / 12)) * r * .8 + r * .35, math.sin(math.radians(120 - 240 * i / 12)) * r * .8) for i in range(13)]
ob = Model("ObservatoryV2", at=(0, 0, 0)); models.append(ob)
# --- platform: core (Box collision), moldings, cornice (walkable trim, top 12.8), pilasters + capitals, medallions, glow band
rbox(ob, MAR, (0, 0, 0), (44, 44, 12), r=.6, base=True, part="Platform")
rbox(ob, MAR_D, (0, 0, 0), (45.2, 45.2, 1.0), r=0, base=True, part="Molding")
rbox(ob, VIO_N, (0, 0, 1.15), (44.25, 44.25, .3), r=0, base=True, part="GlowBand")
rbox(ob, GOLD_D, (0, 0, 9.8), (44.35, 44.35, .45), r=0, base=True, part="Bands")
rbox(ob, GOLD, (0, 0, 12), (44.8, 44.8, .8), r=.2, base=True, part="Trim")
def side_pt(side, t, off):   # side 0:-Y, 1:+X (entrance side), 2:+Y, 3:-X ; t along the side, off outward distance from the face
    return [(t, -22 - off), (22 + off, t), (-t, 22 + off), (-22 - off, -t)][side]
for side in range(4):
    for k in range(9):
        t = -20 + k * 5
        if side == 1 and abs(t) < 13: continue
        x, y = side_pt(side, t, .25)
        alongx = side % 2 == 0
        rbox(ob, MAR_D, (x, y, 1.45), (1.6, .5, 8.3) if alongx else (.5, 1.6, 8.3), r=0, base=True, part="Pilasters")
        rbox(ob, GOLD, (x, y, 9.4), (2.1, .8, .5) if alongx else (.8, 2.1, .5), r=0, base=True, part="Capitals")
    for k, (t, emb) in enumerate(((-12.5, "star"), (-2.5, "moon"), (7.5, "sun"), (17.5, "star"))):
        if side == 1 and abs(t) < 15: continue
        x, y = side_pt(side, t, .1); rot = (90, 0, 0) if side % 2 == 0 else (90, 0, 90)
        cyl(ob, INDIGO, (x, y, 5.4) if False else ((x, y - .1 if side == 0 else y + .1, 5.4) if side % 2 == 0 else (x + (.1 if side == 1 else -.1), y, 5.4)), r=1.9, h=.25, seg=20, rot=rot, part="Medallions")
        ox, oy = (0, -.3) if side == 0 else (.3, 0) if side == 1 else (0, .3) if side == 2 else (-.3, 0)
        torus(ob, GOLD, (x + ox * .5, y + oy * .5, 5.4), R=1.9, r=.18, rot=rot, seg=20, rseg=4, part="Medallions2")
        poly = star(1.1, .48) if emb == "star" else crescent(1.0) if emb == "moon" else [(math.cos(2 * math.pi * i / 16) * (1.1 if i % 2 == 0 else .7), math.sin(2 * math.pi * i / 16) * (1.1 if i % 2 == 0 else .7)) for i in range(16)]
        prism(ob, STARW if emb != "moon" else CYN, poly, .12, loc=(x + ox, y + oy, 5.4), rot=rot, part="Emblems")
# --- terrace: star-mosaic ring floor (0.1 above the trim), balustrade with an opening for the stairs, braziers, globes
cyl(ob, NAVY, (0, 0, 12.8), r=21.2, h=.1, seg=48, part="TerraceFloor")
for R_ in (19.6, 16.9): torus(ob, GOLD, (0, 0, 12.92), R=R_, r=.16, seg=48, rseg=4, part="FloorRings")
for k in range(24):
    a = 2 * math.pi * k / 24; rbox(ob, GOLD_D, (math.cos(a) * 18.25, math.sin(a) * 18.25, 12.93), (2.6, .2, .05), r=0, rot=(0, 0, math.degrees(a)), part="FloorRays")
    if k % 2 == 0: prism(ob, STARW, star(.45, .2), .05, loc=(math.cos(a + .13) * 20.4, math.sin(a + .13) * 20.4, 12.9), part="FloorStars")
posts = []
for side in range(4):
    for k in range(23):
        t = -21.6 + k * (43.2 / 22)
        x, y = side_pt(side, t, -.4)
        if side == 1 and abs(t) < 12.5: continue
        posts.append((x, y, k % 4 == 0))
for (x, y, big) in posts:
    cyl(ob, MAR_D, (x, y, 12.8), r=.28 if not big else .45, h=1.9, seg=8, part="Balustrade")
    if big: sphere(ob, CYN, (x, y, 15.1), .38, seg=8, rings=6, part="BalOrbs")
for side in range(4):
    if side == 1:
        for seg_ in ((-21.6, -12.5), (12.5, 21.6)):
            a0, a1 = side_pt(1, seg_[0], -.4), side_pt(1, seg_[1], -.4)
            tube(ob, GOLD, [(a0[0], a0[1], 14.75), (a1[0], a1[1], 14.75)], r=.17, seg=6, smooth=1, part="BalRail")
    else:
        a0, a1 = side_pt(side, -21.6, -.4), side_pt(side, 21.6, -.4)
        tube(ob, GOLD, [(a0[0], a0[1], 14.75), (a1[0], a1[1], 14.75)], r=.17, seg=6, smooth=1, part="BalRail")
for sx in (-1, 1):
    for sy in (-1, 1):
        bx, by = sx * 19.4, sy * 19.4
        rbox(ob, MAR, (bx, by, 12.8), (2.2, 2.2, 1.4), r=0, base=True, part="Braziers")
        lathe(ob, GOLD, [(0, 14.2), (1.4, 14.3), (1.6, 15.0), (1.2, 15.2), (0, 15.2)], loc=(bx, by, 0), seg=12, part="BrazierBowls")
        lathe(ob, [VIO_N, CYN, PNK, VIO_N][(sx + 1) + (sy + 1) // 2], [(.55, 0), (.75, .4), (.7, 1.6), (0, 2.5)], loc=(bx, by, 15.0), seg=6, part="BrazierCrystals")
for sy in (-8.5, 8.5):
    lathe(ob, MAR_D, [(1.2, 12.8), (.9, 13.4), (.45, 13.6), (.4, 15.4), (.9, 15.7), (0, 15.75)], loc=(19.2, sy, 0), seg=12, part="GlobeStands")
    sphere(ob, NAVY, (19.2, sy, 17.2), 1.5, seg=14, rings=10, part="Globes")
    torus(ob, GOLD, (19.2, sy, 17.2), R=1.75, r=.1, rot=(70, 0, 20), seg=20, rseg=4, part="GlobeRings"); torus(ob, GOLD_D, (19.2, sy, 17.2), R=1.75, r=.08, rot=(0, 90, 0), seg=20, rseg=4, part="GlobeRings")
    for k in range(5): sphere(ob, STARW, (19.2 + math.cos(k * 1.3) * 1.45, sy + math.sin(k * 1.3) * .6, 17.2 + math.sin(k * 2.1) * 1.0), .1, seg=4, rings=3, part="GlobeStars")
# --- lower drum with arched windows and engaged columns; cornice; catwalk; upper drum with portholes
cyl(ob, LAV, (0, 0, 12.8), r=16, h=8.0, seg=40, part="Drum")
for k in range(12):
    a = 2 * math.pi * (k + .5) / 12
    if abs(math.cos(a) - 1) < .05: continue
    x, y = math.cos(a) * 16.05, math.sin(a) * 16.05; deg = math.degrees(a) + 90
    rbox(ob, VIO_N, (x, y, 16.2), (2.4, .2, 4.0), r=0, rot=(0, 0, deg), part="Windows")
    cyl(ob, VIO_N, (x, y, 18.2), r=1.2, h=.2, seg=12, rot=(90, 0, deg), part="Windows")
    rbox(ob, GOLD_D, (math.cos(a) * 16.12, math.sin(a) * 16.12, 14.0), (3.0, .25, .35), r=0, rot=(0, 0, deg), part="WinSills")
    torus(ob, GOLD, (math.cos(a) * 16.15, math.sin(a) * 16.15, 18.2), R=1.3, r=.16, arc=180, rot=(90, 0, deg), seg=14, rseg=4, part="WinArches")
for k in range(12):
    a = 2 * math.pi * k / 12
    if abs(math.cos(a) - 1) < .05: continue
    x, y = math.cos(a) * 16.25, math.sin(a) * 16.25
    cyl(ob, MAR, (x, y, 12.8), r=.6, h=8.0, seg=10, part="DrumColumns"); rbox(ob, GOLD, (x, y, 20.3), (1.5, 1.5, .5), r=0, rot=(0, 0, math.degrees(a)), part="DrumCapitals")
cyl(ob, GOLD, (0, 0, 20.8), r=16.9, h=.8, seg=40, part="Cornice")
cyl(ob, NAVY, (0, 0, 21.6), r=18.2, h=.3, seg=40, part="Catwalk")
for k in range(24):
    a = 2 * math.pi * k / 24; cyl(ob, GOLD_D, (math.cos(a) * 17.9, math.sin(a) * 17.9, 21.9), r=.1, h=1.4, seg=4, part="CatwalkRail")
torus(ob, GOLD, (0, 0, 23.3), R=17.9, r=.12, seg=48, rseg=4, part="CatwalkRail")
cyl(ob, INDIGO, (0, 0, 21.6), r=15, h=4.6, seg=40, part="UpperDrum")
for k in range(16):
    a = 2 * math.pi * (k + .5) / 16; x, y = math.cos(a) * 15.08, math.sin(a) * 15.08; deg = math.degrees(a) + 90
    cyl(ob, CYN, (x, y, 23.9), r=.75, h=.15, seg=12, rot=(90, 0, deg), part="Portholes")
    torus(ob, GOLD, (math.cos(a) * 15.15, math.sin(a) * 15.15, 23.9), R=.85, r=.13, rot=(90, 0, deg), seg=12, rseg=4, part="PortholeRims")
torus(ob, GOLD_D, (0, 0, 26.15), R=15.05, r=.25, seg=48, rseg=4, part="Cornice")
# --- grand entrance portal on the stairs side (+X)
for sy in (-3.4, 3.4):
    cyl(ob, MAR, (16.9, sy, 12.8), r=.8, h=7.4, seg=12, part="PortalColumns"); rbox(ob, GOLD, (16.9, sy, 20.2), (2.0, 2.0, .6), r=0, part="PortalCapitals")
rbox(ob, INDIGO, (16.15, 0, 12.8), (.3, 5.6, 6.2), r=0, base=True, part="Doors")
rbox(ob, GOLD_D, (16.3, 0, 12.8), (.12, .18, 6.2), r=0, base=True, part="DoorSeam")
for k, (dy, dz) in enumerate(((-1.4, 15.0), (1.4, 15.0), (-1.4, 17.4), (1.4, 17.4))): prism(ob, STARW, star(.5, .22), .06, loc=(16.33, dy, dz), rot=(90, 0, 90), part="DoorStars")
torus(ob, GOLD, (16.9, 0, 20.8), R=3.4, r=.5, arc=180, rot=(90, 0, 90), seg=24, rseg=6, part="PortalArch")
prism(ob, STARW, star(1.1, .48), .3, loc=(17.0, 0, 24.4), rot=(90, 0, 90), part="Keystone")
rbox(ob, GOLD_D, (17.3, 0, 20.6), (1.6, 8.2, .5), r=0, part="Lintel")
# ===== rotating dome (separate model, Spin Y): shell, ribs, rings, slit, constellations, cupola, detailed telescope
dm = Model("ObservatoryDomeV2", at=(80, 0, 0)); models.append(dm)
prof = [(16.2, 0), (15.8, 3), (14.8, 6.2), (13.0, 9.2), (10.4, 12.0), (7.2, 14.4), (3.8, 15.9), (0, 16.4)]
lathe(dm, INDIGO, prof, seg=40, part="Dome")
def dpt(a, t, r_add=.15):   # point on the dome at azimuth a, elevation t (deg)
    R_ = 16.2 + r_add; return (math.cos(a) * R_ * math.cos(math.radians(t)), math.sin(a) * R_ * math.cos(math.radians(t)), 16.4 * math.sin(math.radians(t)) * (1 + r_add / 16.2))
for k in range(16):
    a = 2 * math.pi * k / 16 + .1
    if abs(math.sin(a) + 1) < .12: continue
    tube(dm, GOLD, [dpt(a, t) for t in range(0, 86, 12)], r=.24, seg=5, smooth=1, part="Ribs")
for t, rr in ((22, .2), (48, .18), (70, .16)):
    z = 16.4 * math.sin(math.radians(t)); R_ = 16.35 * math.cos(math.radians(t)); torus(dm, GOLD_D, (0, 0, z), R=R_, r=rr, seg=40, rseg=4, part="DomeRings")
tube(dm, NAVY, [(0, -16.45 * math.cos(math.radians(t)), 16.6 * math.sin(math.radians(t))) for t in range(0, 91, 9)], r=1.7, seg=8, smooth=1, part="Slit")
for s in (-1, 1): tube(dm, GOLD, [(s * 1.9, -16.35 * math.cos(math.radians(t)), 16.5 * math.sin(math.radians(t))) for t in range(0, 88, 9)], r=.18, seg=5, smooth=1, part="SlitEdges")
rq = random.Random(42)
for c in range(4):
    a0 = math.pi / 2 + c * 1.1 + rq.uniform(-.2, .2); t0 = rq.uniform(25, 55)
    pts = [(a0 + rq.uniform(-.25, .25), t0 + rq.uniform(-12, 12)) for _ in range(5)]
    for (a_, t_) in pts: sphere(dm, STARW if c % 2 else CYN, dpt(a_, t_, .25), .35, seg=6, rings=4, part="ConstStars")
    for (a1, t1), (a2, t2) in zip(pts, pts[1:]): tube(dm, GOLD_D, [dpt(a1, t1, .2), dpt(a2, t2, .2)], r=.06, seg=4, smooth=1, part="ConstLines")
for k in range(40):
    a_ = rq.uniform(0, 6.28); t_ = rq.uniform(8, 80)
    if abs(math.sin(a_) + 1) < .15: continue
    sphere(dm, STARW, dpt(a_, t_, .2), .18, seg=4, rings=3, part="StarDots")
cyl(dm, MAR, (0, 0, 16.0), r=2.7, h=2.6, seg=16, part="Cupola")
for k in range(6):
    a_ = 2 * math.pi * k / 6; cyl(dm, GOLD_D, (math.cos(a_) * 2.75, math.sin(a_) * 2.75, 16.0), r=.2, h=2.6, seg=6, part="CupolaCols")
    rbox(dm, CYN, (math.cos(a_ + .52) * 2.72, math.sin(a_ + .52) * 2.72, 17.3), (1.4, .15, 1.6), r=0, rot=(0, 0, math.degrees(a_ + .52) + 90), part="CupolaGlass")
lathe(dm, GOLD, [(3.1, 18.6), (2.6, 19.5), (1.4, 20.4), (0, 20.9)], seg=16, part="CupolaRoof")
cyl(dm, GOLD_D, (0, 0, 20.9), r=.12, h=1.6, seg=6, part="Finial"); prism(dm, STARW, star(.9, .4), .2, loc=(0, 0, 23.2), rot=(90, 0, 0), part="FinialStar")
tube(dm, GOLD, [(0, -1.5, 6.5), (0, -21.5, 27.0)], r=3.0, r2=2.4, seg=18, smooth=1, part="Telescope")
for k in range(5):
    f = .18 + k * .17; x, y, z = 0, -1.5 - 20 * f, 6.5 + 20.5 * f
    torus(dm, GOLD_D, (x, y, z), R=3.0 - .6 * f + .15, r=.3, rot=(-45, 0, 0), seg=20, rseg=4, part="TeleBands")
torus(dm, GOLD_D, (0, -21.8, 27.3), R=2.7, r=.45, rot=(-45, 0, 0), seg=20, rseg=6, part="LensHood")
cyl(dm, CYN, (0, -21.85, 27.35), r=2.25, h=.2, seg=20, rot=(-45, 0, 0), part="Lens")
tube(dm, GOLD_D, [(2.6, -6.5, 12.0), (2.6, -14.5, 20.2)], r=.5, seg=8, smooth=1, part="Finder"); cyl(dm, CYN, (2.6, -14.6, 20.3), r=.42, h=.1, seg=10, rot=(-45, 0, 0), part="Lens")
for s in (-1, 1): rbox(dm, GOLD_D, (s * 3.4, -2.0, 4.6), (.6, 3.0, 5.0), r=0, rot=(-40, 0, 0), part="Mount")
sphere(dm, GOLD_D, (0, 2.0, 3.6), 2.0, seg=10, rings=6, part="Counterweight")

objs = realize(models, 'W2_ObservatoryV2')
