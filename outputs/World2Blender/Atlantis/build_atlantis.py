import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random
from mathutils import Vector

# Sunken Atlantis pack (World 2, stage 11) - Claude 2026-10-03. Units = studs, front = -Y (Roblox -Z).
from w2lib import *
TURQ, TEAL, DEEP = P("3FD0D4"), P("1E8C96"), P("17607A")
STONE, STONE_D, SANDC = P("E6DFCF"), P("C9C0AB"), P("F1E3C0")
CORAL, CORAL2, CORAL3 = P("FF7A5C"), P("FF9EC2"), P("B48CFF")
PEARL, PEARLP, GOLD = P("FFF8EE"), P("FFE6EE"), P("FFC94A")
WEED, WEED_D, INK, WHITE, BLUSH = P("3FAF7A"), P("2E8C60"), P("2A2433"), P("FFFFFF"), P("FF9BB5")
GLOWP = P("E9FFFF", "NE")
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 10; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def column(m, pc, loc, r, h, part, cap=True):
    x, y, z = loc
    rbox(m, pc, (x, y, z), (r * 2.6, r * 2.6, r * .55), r=.12, base=True, part=part)
    lathe(m, pc, [(r, z + r * .55), (r * .92, z + h * .5), (r * .86, z + h - r * .5), (r * .86, z + h - r * .45)], loc=(x, y, 0), seg=20, rib=(12, .06), part=part)
    if cap: cyl(m, pc, (x, y, z + h - r * .5), r=r * 1.35, h=r * .5, seg=16, bev=.06, part=part)
def scallop(m, pc, pcb, loc, R, rot=(0, 0, 0), n=11, part="Shell", partb="ShellBack", depth=.25):
    M_ = Mx(loc, rot)
    poly = [(0, 0)] + [(math.cos(math.radians(a)) * R, math.sin(math.radians(a)) * R) for a in range(10, 171, 8)]
    pts = [M_ @ Vector(p) for p in [(0, 0, 0)]]
    prism(m, pcb, poly, depth, loc=loc, rot=(rot[0] + 90, rot[1], rot[2]), part=partb)
    for i in range(n):
        a = math.radians(12 + 156 * i / (n - 1))
        p0 = M_ @ Vector((0, -depth - .05, R * .08)); p1 = M_ @ Vector((math.cos(a) * R * .55, -depth - .2 - R * .05, math.sin(a) * R * .55)); p2 = M_ @ Vector((math.cos(a) * R, -depth - .1, math.sin(a) * R))
        tube(m, pc, [p0, p1, p2], r=R * .055, r2=R * .085, seg=8, smooth=3, part=part)
def coral(m, pc, base, h, seed, part="Coral", r0=.45, depth=2):
    rr = random.Random(seed)
    def br(p, d, length, rad, depth):
        q = Vector(p) + d.normalized() * length
        tube(m, pc, [p, Vector(p).lerp(q, .5) + Vector((rr.uniform(-.2, .2), rr.uniform(-.2, .2), 0)), q], r=rad, r2=rad * .75, seg=7, smooth=3, part=part)
        if depth == 0: sphere(m, pc, q, rad * .95, part=part); return
        for k in range(2 if depth > 1 else 3):
            nd = (d.normalized() + Vector((rr.uniform(-.9, .9), rr.uniform(-.9, .9), rr.uniform(.2, .7)))).normalized()
            br(q, nd, length * rr.uniform(.6, .8), rad * .72, depth - 1)
    br(Vector(base), Vector((0, 0, 1)), h * .45, r0, depth)
def kelp(m, base, h, seed, part="Kelp"):
    rr = random.Random(seed); bx, by, bz = base
    for s in range(3):
        ox, oy = rr.uniform(-.8, .8), rr.uniform(-.8, .8); pts = []
        for k in range(8):
            z = h * k / 7; pts.append((bx + ox + math.sin(k * .9 + s) * .45, by + oy + math.cos(k * .7 + s) * .3, bz + z))
        tube(m, WEED, pts, r=.2, r2=.1, seg=6, smooth=3, part=part)
        for k in range(1, 7):
            p = pts[k]; sphere(m, WEED_D if k % 2 else WEED, (p[0] + .35, p[1], p[2]), .38, scl=(1.4, .25, .7), rot=(0, rr.uniform(-30, 30), rr.uniform(0, 360)), part=part + "Leaves")
def fish(m, pc, fin, loc, s=1.0, part="Fish"):
    x, y, z = loc
    lathe(m, pc, [(0, 0), (.25 * s, .2 * s), (.42 * s, .7 * s), (.36 * s, 1.15 * s), (0, 1.4 * s)], loc=(x, y + .7 * s, z), rot=(90, 0, 0), seg=10, sy=.8, part=part)
    sphere(m, fin, (x, y + .85 * s, z), .38 * s, scl=(.15, 1, .9), part=part + "Fin")
    for sd in (-1, 1): sphere(m, INK, (x + sd * .24 * s, y - .45 * s, z + .1 * s), .07 * s, part=part + "Eye")

# 1) island: sand turf, pale reef rock, coral growths
isl = add("AtlantisIsland", 320)
turf_se(isl, P("F1E3C0", "SA"), a=151, b=63, n=4, thick=.8, seg=56, part="Sand", top=-0.3)
island_se(isl, STONE_D, a=148, b=61, depth=76, n=4, seed=41, seg=56, rings=7, jag=.12, part="Reef", top=-1.0, tip=(6, 8))
rq = random.Random(5)
for i in range(14):
    ang = 2 * math.pi * i / 14 + rq.uniform(-.05, .05); x, y = se_point(146, 60, ang, 4.0)
    coral(isl, [CORAL, CORAL2, CORAL3][i % 3], (x * .97, y * .97, -4 - rq.uniform(0, 3)), rq.uniform(5, 8), seed=i, part="Coral" + str(i % 3), r0=.6, depth=1)
for i in range(8):
    a = rq.uniform(0, 6.283); k = rq.uniform(.3, .75)
    rock(isl, TEAL, (math.cos(a) * 115 * k, math.sin(a) * 45 * k, -28 - rq.uniform(0, 26)), (rq.uniform(6, 10), rq.uniform(6, 10), rq.uniform(9, 15)), seed=i + 50, part="Hang")
isl.flat("Reef", STONE_D, 30); isl.flat("Hang", TEAL, 30)
# 2) rim
rim = add("AtlantisRim", 16)
rock(rim, STONE_D, (0, 0, 1.0), (4.2, 3.3, 2.6), seed=2, part="Rocks"); rock(rim, STONE, (-4.3, .8, .7), (2.8, 2.4, 2.0), seed=3, part="Rocks2")
coral(rim, CORAL, (2.8, .5, 1.2), 4.5, 11, part="CoralA"); coral(rim, CORAL3, (-4.6, 1.0, 2.0), 3.5, 12, part="CoralB")
kelp(rim, (1.0, 1.6, 1.8), 6, 13)
scallop(rim, PEARLP, PEARL, (4.6, -1.6, .3), .9, rot=(-20, 0, 0), n=7, part="Shells", partb="ShellsB")
rim.flat("Rocks", STONE_D, 25); rim.flat("Rocks2", STONE, 25)
# 3) props
cb = add("CoralBranch", 7); coral(cb, CORAL, (0, 0, 0), 6, 21, part="Coral", r0=.5)
for i, (x, y) in enumerate([(1.2, .6), (-1.0, -.7), (.2, 1.2)]): sphere(cb, STONE_D, (x, y, 0), .7, scl=(1, 1, .45), part="Base")
cf = add("CoralFan", 7)
fanp = [(math.cos(math.radians(a)) * 2.6 * (1 + .1 * math.sin(a * .3)), math.sin(math.radians(a)) * 3.0 + 1.2) for a in range(15, 166, 10)] + [(.3, 0), (-.3, 0)]
prism(cf, CORAL3, fanp, .25, loc=(0, .12, 0), rot=(90, 0, 0), part="Fan")
cyl(cf, CORAL3, (0, 0, 0), r=.35, h=1.4, seg=8, part="Stem")
kp = add("KelpTall", 5); kelp(kp, (0, 0, 0), 11, 31)
bc = add("BrokenColumn", 6)
column(bc, STONE, (0, 0, 0), 1.1, 9, part="Column", cap=False)
rock(bc, STONE, (0, 0, 9.2), (1.0, 1.0, .5), seed=7, jag=.3, part="Column")
coral(bc, CORAL2, (.6, -.8, 4.0), 2.2, 41, part="CoralGrow", r0=.22)
rw = add("RuinWall", 24)
arcpoly = []
for i in range(21):
    a = math.radians(-50 + 100 * i / 20); arcpoly.append((math.sin(a) * 11, -math.cos(a) * 11 + 11))
inner = [(x * .87, (y - 11) * .87 + 11) for x, y in reversed(arcpoly)]
prism(rw, STONE, arcpoly + inner, 7.5, part="Wall")
for i, a in enumerate((-35, 0, 35)):
    t = math.radians(a); cx, cy = math.sin(t) * 10.3, -math.cos(t) * 10.3 + 11
    rbox(rw, DEEP, (cx, cy, 2.0), (2.0, 1.8, 3.2), r=.8, base=True, rot=(0, 0, -a), part="Windows")
rock(rw, STONE_D, (9.5, 3, .4), (1.4, 1.2, .9), seed=9, part="Rubble"); rock(rw, STONE_D, (-8, 4.5, .3), (1.1, 1, .7), seed=10, part="Rubble")
pl = add("PearlLamp", 5)
column(pl, STONE, (0, 0, 0), .45, 6.4, part="Post")
scallop(pl, PEARLP, PEARL, (0, -.15, 6.5), 1.3, rot=(-35, 0, 0), n=7, part="Shell", partb="ShellBack")
sphere(pl, GLOWP, (0, -.45, 6.95), .6, part="Pearl")
tc = add("TreasureChestAtl", 6)
rbox(tc, P("8A5A3C"), (0, 0, 0), (3.2, 2.2, 1.7), r=.2, base=True, part="Box")
lathe(tc, P("8A5A3C"), [(1.65, 0), (1.65, .5), (1.1, 1.0), (0.01, 1.1)], loc=(0, 1.2, 1.7), seg=4, rot=(-62, 0, 45), sx=1.0, sy=.68, part="Lid")
for x in (-1.15, 1.15): rbox(tc, GOLD, (x, 0, .85), (.28, 2.3, 1.75), r=.06, part="Bands")
for i in range(9): sphere(tc, GOLD if i % 3 else PEARL, (random.Random(i).uniform(-1.2, 1.2), random.Random(i + 9).uniform(-.8, .6), 1.75 + random.Random(i + 3).uniform(0, .35)), .3, scl=(1, 1, .45 if i % 3 else 1), part="Loot")
ss = add("SeahorseStatue", 6)
cyl(ss, STONE, (0, 0, 0), r=1.4, r2=1.2, h=1.2, seg=14, bev=.15, part="Pedestal")
SH = P("F2B544")
sphere(ss, SH, (0, 0, 4.0), .95, scl=(.8, .9, 1.5), part="Body")
sphere(ss, SH, (0, -.45, 5.9), .8, part="Body")
lathe(ss, SH, [(.32, 0), (.2, .9), (.24, 1.15), (0, 1.2)], loc=(0, -.95, 5.75), rot=(100, 0, 0), seg=10, part="Snout")
tube(ss, SH, [(0, .3, 2.7), (0, .7, 1.9), (0, .3, 1.35), (0, -.25, 1.5), (0, -.2, 1.95)], r=.38, r2=.18, seg=8, smooth=3, part="Tail")
for k in range(5): sphere(ss, CORAL, (0, .55, 6.4 - k * .55), .22, scl=(.3, 1.3, .8), part="Fin")
for sd in (-1, 1): sphere(ss, INK, (sd * .38, -.75, 6.05), .14, part="Eyes")
mr = add("MantaDecor", 14)
mpoly = [(0, 3.4), (5.6, -.6), (2.2, -1.2), (0, -2.2), (-2.2, -1.2), (-5.6, -.6)]
prism(mr, DEEP, mpoly, .55, loc=(0, 0, .35), bev=.18, part="Top")
prism(mr, PEARL, [(x * .9, y * .9) for x, y in mpoly], .35, loc=(0, 0, 0), part="Belly")
tube(mr, DEEP, [(0, -2.0, .5), (0, -4.5, .6), (0, -7.0, .9)], r=.18, r2=.05, seg=6, smooth=3, part="Tail")
for sd in (-1, 1): sphere(mr, P("FFFFFF"), (sd * .9, 2.5, .65), .2, part="Eyes")
fs_ = add("FishSchool", 10)
rq = random.Random(4)
for i in range(7): fish(fs_, [P("FFB43C"), P("FF7A5C"), P("FFE36E")][i % 3], CORAL, (rq.uniform(-3, 3), rq.uniform(-2, 2), rq.uniform(-1.2, 1.2)), s=rq.uniform(.8, 1.1), part="Fish" + str(i % 3))
jf = add("Jellyfish", 8)
lathe(jf, P("FF9EC8", "SP", .3), [(2.4, 0), (2.3, .7), (1.8, 1.7), (1.0, 2.35), (0, 2.6)], seg=20, part="Dome")
torus(jf, P("FFC4DD", "SP", .2), (0, 0, .1), R=2.2, r=.3, seg=20, rseg=6, part="Frill")
for k in range(7):
    a = 2 * math.pi * k / 7
    tube(jf, P("FFC4DD", "SP", .25), [(math.cos(a) * 1.2, math.sin(a) * 1.2, 0), (math.cos(a) * 1.5, math.sin(a) * 1.4, -2.2), (math.cos(a) * 1.1, math.sin(a) * 1.0, -4.5)], r=.15, r2=.05, seg=5, smooth=3, part="Tentacles")
sphere(jf, GLOWP, (0, 0, 1.1), .55, part="Glow")
bb = add("BubbleColumn", 6)
for k in range(9): sphere(bb, P("E9FFFF", "GL", .45), (math.sin(k) * .5, math.cos(k * 1.3) * .5, k * 1.6), .35 + .08 * (k % 3), part="Bubbles")
rs = add("ReefSpire", 80)
lathe(rs, STONE_D, [(30, 0), (24, 25), (17, 55), (12, 85), (8, 105), (4, 118), (0, 124)], seg=14, wob=.12, seed=6, part="Rock")
rq = random.Random(8)
for i in range(7):
    z = rq.uniform(6, 100); r = 30 - z * .22; a = rq.uniform(0, 6.283)
    coral(rs, [CORAL, CORAL2, CORAL3][i % 3], (math.cos(a) * r * .9, math.sin(a) * r * .9, z), rq.uniform(5, 9), seed=60 + i, part="Coral" + str(i % 3), r0=.7, depth=1)
rs.flat("Rock", STONE_D, 30)
tile = add("AtlantisPathTile", 9)
rbox(tile, STONE, (0, 0, 0), (7.8, 7.8, .3), r=.12, base=True, part="Slab")
for sx in (-1, 1): rbox(tile, TURQ, (0, sx * 3.5, .3), (7.6, .5, .06), r=.03, base=True, part="Mosaic")
sphere(tile, PEARL, (0, 0, .3), .5, scl=(1, 1, .15), part="Pearl")
# 4) gate (Candy -> Atlantis): coral columns + shell arch
gt = add("AtlantisGate", 22)
for sx, nm in ((-1, "PostL"), (1, "PostR")):
    column(gt, STONE, (sx * 8.8, 0, 0), 1.1, 13.0, part=nm)
    coral(gt, CORAL if sx < 0 else CORAL3, (sx * 9.6, -.6, 1.0), 4.5, 70 + sx, part="Coral", r0=.35)
torus(gt, TURQ, (0, 0, 13.0), R=8.8, r=.95, arc=180, seg=26, rseg=8, rot=(90, 0, 0), part="Arch")
for k in range(9):
    a = math.radians(10 + 160 * k / 8)
    scallop(gt, PEARLP if k % 2 else PEARL, PEARL, (math.cos(a) * 8.8, -.9, 13.0 + math.sin(a) * 8.8), 1.1, rot=(0, -math.degrees(a) + 90, 0), n=5, part="ArchShells", partb="ArchShellsB")
tube(gt, GOLD, [(0, -1.1, 19.2), (0, -1.1, 24.0)], r=.22, seg=8, smooth=1, part="Trident")
for sx in (-1, 0, 1):
    lathe(gt, GOLD, [(.32, 0), (.1, 1.0), (0, 1.3)], loc=(sx * .9, -1.1, 23.6 + (0.4 if sx == 0 else 0)), seg=8, part="Trident")
tube(gt, GOLD, [(-.9, -1.1, 23.6), (-.9, -1.1, 23.0), (.9, -1.1, 23.0), (.9, -1.1, 23.6)], r=.15, seg=6, smooth=1, part="Trident")
# 5) ancient arch (frames the palace) - path passes under it
aa = add("AncientArch", 26)
for sx, nm in ((-1, "ColumnL"), (1, "ColumnR")): column(aa, STONE, (sx * 10, 0, 0), 1.5, 17, part=nm)
torus(aa, STONE, (0, 0, 17), R=10, r=1.6, arc=180, seg=28, rseg=4, rot=(90, 0, 0), phase=math.pi / 4, part="Lintel")
for k in range(7):
    a = math.radians(15 + 150 * k / 6)
    sphere(aa, TURQ, (math.cos(a) * 10, -1.7, 17 + math.sin(a) * 10), .45, part="Gems")
prism(aa, GOLD, [(0, 2.4), (1.8, 0), (0, -2.4), (-1.8, 0)], .5, loc=(0, -1.3, 27.6), rot=(90, 0, 0), part="Emblem")
coral(aa, CORAL2, (11.3, -1.2, 0), 4, 81, part="Coral", r0=.4); kelp(aa, (-11.6, -1.0, 0), 9, 82)
rock(aa, STONE_D, (12.5, 2.0, .5), (1.6, 1.4, 1.1), seed=83, part="Rubble")
# 6) shell palace (landmark)
sp_ = add("ShellPalace", 46)
rbox(sp_, STONE, (0, 0, 0), (34, 24, 2.0), r=.4, base=True, part="Platform")
for k in range(3): rbox(sp_, STONE, (0, -12.8 - k * 1.2, 0), (12 - k * 0.0, 1.2 + k * 1.2, 1.5 - k * .5), r=.15, base=True, part="Stairs")
cyl(sp_, PEARL, (0, 0, 2), r=8, h=12, seg=32, bev=.3, part="Hall")
for k in range(10):
    a = 2 * math.pi * k / 10 + math.pi / 2
    column(sp_, STONE, (math.cos(a) * 9.2, math.sin(a) * 9.2, 2), .55, 11.5, part="Columns")
torus(sp_, GOLD, (0, 0, 14.0), R=8.3, r=.45, seg=40, rseg=8, part="Ring")
lathe(sp_, TURQ, [(8.6, 14.2), (8.2, 16.5), (6.5, 19.5), (3.8, 21.8), (0, 22.8)], seg=32, part="Dome")
lathe(sp_, GOLD, [(.9, 22.5), (.5, 25.5), (0, 28.0)], seg=12, part="Spire")
sphere(sp_, GLOWP, (0, 0, 28.6), 1.1, part="Pearl")
rbox(sp_, DEEP, (0, -7.95, 2), (4.4, 1.0, 6.5), r=1.6, base=True, part="Door")
torus(sp_, GOLD, (0, -8.3, 6.3), R=2.3, r=.25, arc=180, seg=18, rseg=6, rot=(90, 0, 0), part="DoorTrim")
scallop(sp_, PEARLP, P("FFF0F3"), (0, 10.5, 1.5), 21, rot=(0, 0, 0), n=13, part="BigShell", partb="BigShellBack", depth=.8)
for sx in (-1, 1):
    cyl(sp_, PEARL, (sx * 13, 3, 2), r=3.2, h=8, seg=20, bev=.2, part="TowerHall")
    lathe(sp_, P("7FE3D8"), [(3.5, 10), (3.0, 11.6), (1.6, 13.3), (0, 14)], loc=(sx * 13, 3, 0), seg=20, part="TowerDome")
    sphere(sp_, GLOWP, (sx * 13, 3, 14.5), .55, part="Pearl")
    scallop(sp_, PEARLP, PEARL, (sx * 6, -12.0, 2), 1.6, rot=(0, 0, 0), n=7, part="StairShells", partb="StairShellsB")
# 7) activity: ruin platform + giant clam
rp = add("RuinPlatform", 14)
rbox(rp, STONE, (0, 0, 0), (11, 11, 13.0), r=.6, base=True, part="Block")
for sx in (-1, 1):
    for sy in (-1, 1): column(rp, STONE, (sx * 4.6, sy * 4.6, 13.0), .5, 3.5, part="Pillars")
coral(rp, CORAL, (5.0, -5.6, 3), 4, 91, part="Coral", r0=.4); kelp(rp, (-5.6, -5.2, 0), 10, 92)
gc = add("GiantClam", 7)
for half, rx in ((0, 0), (1, -62)):
    scallop(gc, P("BFA5FF") if half else P("A88BF0"), P("D8C8FF"), (0, .8 if half else -.4, .4 + (0.2 if half else 0)), 2.6, rot=(rx - (90 if half == 0 else 0), 0, 0), n=9, part="Shell" + str(half), partb="Inner" + str(half))
sphere(gc, GLOWP, (0, -.6, .95), .75, part="Pearl")
rock(gc, STONE_D, (0, 0, .2), (2.4, 2.0, .5), seed=4, part="Base")
# 8) pearl egg on a scallop pedestal
egg = add("PearlEgg", 7)
cyl(egg, STONE, (0, 0, 0), r=2.4, r2=2.1, h=1.0, seg=20, bev=.15, part="Pedestal")
scallop(egg, PEARLP, PEARL, (0, 1.3, 1.0), 3.2, rot=(0, 0, 0), n=11, part="BackShell", partb="BackShellB")
PROF = [(0, 0), (1.0, .12), (1.6, .6), (1.95, 1.4), (2.05, 2.2), (1.95, 3.0), (1.65, 3.8), (1.1, 4.5), (.5, 4.88), (0, 5.0)]
Z0 = 1.05
lathe(egg, P("FFF6EE"), PROF, loc=(0, 0, Z0), seg=28, part="Shell")
def rad_at(h):
    for (r1, z1), (r2, z2) in zip(PROF, PROF[1:]):
        if z1 <= h <= z2: return r1 + (r2 - r1) * (h - z1) / max(1e-6, z2 - z1)
    return 0
pts = []
for i in range(41):
    a = 2 * math.pi * i / 40; h = 2.0 + .35 * math.sin(a * 4); r = rad_at(h) + .03
    pts.append((math.cos(a) * r, math.sin(a) * r, Z0 + h))
tube(egg, TURQ, pts, r=.16, seg=6, smooth=1, closed=True, part="Wave")
starp = [(math.cos(math.radians(90 + 36 * i)) * (.45 if i % 2 == 0 else .2), math.sin(math.radians(90 + 36 * i)) * (.45 if i % 2 == 0 else .2)) for i in range(10)]
for i, (h, ang) in enumerate([(1.0, 20), (1.2, 140), (3.3, 260), (3.6, 80), (2.9, 330)]):
    a = math.radians(ang); r = rad_at(h) + .02
    prism(egg, CORAL, starp, .12, loc=(math.cos(a) * r, math.sin(a) * r, Z0 + h), rot=(0, 90 - (10 if h > 2.2 else -10), math.degrees(a)), part="Stars")
for i in range(9):
    a = 2 * math.pi * i / 9 + .3; h = 4.15; r = rad_at(h) + .05
    sphere(egg, PEARL, (math.cos(a) * r, math.sin(a) * r, Z0 + h), .17, part="Pearls")
# 9) pets
def face(m, y, z, sep=.36, er=.17, blush=True):
    for s in (-1, 1):
        sphere(m, INK, (s * sep, y, z), er, scl=(.8, .45, 1.15), part="Eyes")
        sphere(m, WHITE, (s * sep - .05, y - .08, z + .07), er * .38, part="Shine")
        if blush: sphere(m, BLUSH, (s * (sep + .27), y + .07, z - .23), .14, scl=(1, .35, .6), part="Blush")
cr = add("Pet_Crab", 4); RC = P("FF6F4C")
sphere(cr, RC, (0, 0, .95), 1.05, scl=(1.15, .9, .7), part="Body")
for s in (-1, 1):
    tube(cr, RC, [(s * .4, -.3, 1.4), (s * .45, -.45, 1.95)], r=.08, seg=6, smooth=1, part="Stalks")
    sphere(cr, WHITE, (s * .45, -.5, 2.05), .22, part="EyeBalls"); sphere(cr, INK, (s * .45, -.68, 2.08), .11, part="Eyes")
    tube(cr, RC, [(s * 1.0, -.2, .8), (s * 1.55, -.6, 1.1), (s * 1.6, -1.0, 1.45)], r=.15, seg=6, smooth=3, part="Arms")
    sphere(cr, RC, (s * 1.62, -1.15, 1.6), .42, scl=(1, .8, .75), part="Claws")
    for k in range(3): tube(cr, RC, [(s * .8, .2 - k * .3, .55), (s * 1.3, .3 - k * .35, .3), (s * 1.45, .25 - k * .35, 0)], r=.08, seg=5, smooth=3, part="Legs")
    sphere(cr, BLUSH, (s * .65, -.82, .9), .14, scl=(1, .35, .6), part="Blush")
sphere(cr, INK, (0, -.95, .75), .1, scl=(1.8, .5, .6), part="Smile")
sh = add("Pet_Seahorse", 4); SY = P("FFC94A")
sphere(sh, SY, (0, 0, 1.3), .7, scl=(.85, .85, 1.3), part="Body")
sphere(sh, SY, (0, -.3, 2.45), .65, part="Head")
lathe(sh, SY, [(.26, 0), (.16, .6), (.2, .78), (0, .82)], loc=(0, -.7, 2.35), rot=(100, 0, 0), seg=10, part="Snout")
tube(sh, SY, [(0, .25, .55), (0, .5, .1), (0, .1, -.15), (0, -.25, .05), (0, -.2, .35)], r=.3, r2=.12, seg=8, smooth=3, part="Tail")
for k in range(5): sphere(sh, CORAL, (0, .55, 2.6 - k * .42), .18, scl=(.3, 1.3, .8), part="Fin")
face(sh, -.88, 2.55, sep=.26, er=.14)
sphere(sh, P("FFE6A0"), (0, -.5, 1.25), .42, scl=(.9, .5, 1.2), part="Belly")
tu = add("Pet_Turtle", 4); TG, TS = P("7ED36A"), P("3FAF7A")
sphere(tu, TS, (0, .15, .95), 1.15, scl=(1, 1.05, .62), part="Shell")
for k, (x, y) in enumerate([(0, .15), (.55, -.2), (-.55, -.2), (.55, .55), (-.55, .55), (0, .9), (0, -.6)]):
    sphere(tu, P("2E8C60"), (x, y, 1.62 - (abs(x) + abs(y - .15)) * .25), .3, scl=(1, 1, .25), part="Plates")
sphere(tu, P("FFF0C8"), (0, .1, .6), 1.0, scl=(1, 1, .35), part="Belly")
sphere(tu, TG, (0, -1.05, 1.15), .62, part="Head")
for s in (-1, 1):
    sphere(tu, TG, (s * 1.0, -.55, .55), .38, scl=(1.3, .7, .35), rot=(0, 0, s * 25), part="Flippers")
    sphere(tu, TG, (s * .8, .9, .5), .3, scl=(1.2, .7, .35), part="Flippers")
face(tu, -1.58, 1.25, sep=.26, er=.13)
mt = add("Pet_MantaRay", 4)
prism(mt, DEEP, [(0, 1.9), (2.1, -.2), (.9, -.7), (0, -1.1), (-.9, -.7), (-2.1, -.2)], .5, loc=(0, 0, 1.0), bev=.18, part="Top")
prism(mt, PEARL, [(0, 1.7), (1.9, -.2), (.8, -.6), (0, -1.0), (-.8, -.6), (-1.9, -.2)], .3, loc=(0, -.05, .8), part="Belly")
tube(mt, DEEP, [(0, .9, 1.2), (0, 1.9, 1.3), (0, 2.8, 1.6)], r=.1, r2=.03, seg=6, smooth=3, part="Tail")
for s in (-1, 1): sphere(mt, DEEP, (s * .45, -1.15, 1.25), .22, scl=(.6, 1.2, .6), part="Horns")
face(mt, -1.05, 1.32, sep=.3, er=.13)
se = add("Pet_SeaSerpent", 5); SG = P("2FC4B2")
pts = [(0, 1.4, .5), (.9, .7, .45), (.6, -.3, .5), (-.6, -.4, .9), (-.5, .5, 1.4), (.2, .3, 1.9), (.1, -.5, 2.3)]
tube(se, SG, pts, r=.42, r2=.3, seg=10, smooth=4, part="Body")
for k, p in enumerate(pts[:-1]): sphere(se, P("FFF0C8"), (p[0], p[1] - .2, p[2] - .2), .26, scl=(1, .6, .5), part="Belly")
sphere(se, SG, (.1, -.8, 2.5), .62, scl=(1, 1.15, .9), part="Head")
for k, x in enumerate((-.35, 0, .35)):
    lathe(se, GOLD, [(.12, 0), (.04, .45), (0, .55)], loc=(.1 + x, -.75, 2.95), rot=(-15, x * 30, 0), seg=8, part="Crown")
for s in (-1, 1): sphere(se, P("7FE3D8"), (.1 + s * .65, -.6, 2.6), .3, scl=(.2, 1, .7), part="FinEars")
face(se, -1.35, 2.62, sep=.27, er=.14)
sphere(se, GLOWP, (.1, -1.3, 2.25), .1, part="Glow")

objs = realize(models, 'W2_Atlantis')
