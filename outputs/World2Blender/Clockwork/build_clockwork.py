import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Clockwork City pack (World 2, stage 13) - Claude 2026-10-03. Units = studs, front = -Y (Roblox -Z). R2B for Roblox-frame geometry.
from w2lib import *
from w2lib import _merge
def R2B(p): return Vector((-p[0], p[2], p[1]))
BRASS, BRASS_D, COPPER, COPPER_D = P("E0B04A", "ME"), P("B8862E", "ME"), P("D07A48"), P("9A5530")
IRON, CREAM, TEAL, TEAL_D, STONE = P("4A4F5C"), P("F6E7C8"), P("3FBFB4"), P("2C8F88"), P("CDB898")
WHITE, INK, BLUSH, GLASS, WARM = P("FFFFFF"), P("2A2433"), P("FF9BB5"), P("BFEFFF", "GL", .15), P("FFE2A0", "NE")
models = []; X = [0]
def at(w):
    X[0] += w / 2; p = (X[0], 0, 0); X[0] += w / 2 + 10; return p
def add(name, w):
    m = Model(name, at=at(w)); models.append(m); return m
def gear(m, pc, loc, R, thick, teeth, axis="y", part="Gear", hub=None):
    cx, cy, cz = loc
    if axis == "y":
        cyl(m, pc, (cx, cy + thick / 2, cz), r=R * .84, h=thick, seg=max(16, teeth * 2), rot=(90, 0, 0), part=part)
        for i in range(teeth):
            a = 2 * math.pi * i / teeth
            rbox(m, pc, (cx + math.cos(a) * R * .93, cy, cz + math.sin(a) * R * .93), (R * .2, thick, 2 * math.pi * R / teeth * .5), r=0, rot=(0, -math.degrees(a), 0), part=part)
        cyl(m, hub or pc, (cx, cy + thick * .8, cz), r=R * .22, h=thick * 1.6, seg=14, rot=(90, 0, 0), part=part + "Hub")
        for i in range(4):
            a = 2 * math.pi * (i + .5) / 4
            cyl(m, P("2A2433") if hub is None else hub, (cx + math.cos(a) * R * .52, cy - thick / 2 - .01, cz + math.sin(a) * R * .52), r=R * .14, h=.02, seg=12, rot=(90, 0, 0), part=part + "Holes")
    else:
        cyl(m, pc, (cx, cy, cz - thick / 2), r=R * .84, h=thick, seg=max(16, teeth * 2), part=part)
        for i in range(teeth):
            a = 2 * math.pi * i / teeth
            rbox(m, pc, (cx + math.cos(a) * R * .93, cy + math.sin(a) * R * .93, cz), (R * .2, 2 * math.pi * R / teeth * .5, thick), r=0, rot=(0, 0, math.degrees(a)), part=part)
        cyl(m, hub or pc, (cx, cy, cz + thick / 2 - .01), r=R * .22, h=thick * .3, seg=14, part=part + "Hub")
def face(m, y, z, sep=.36, er=.17):
    for s in (-1, 1):
        sphere(m, INK, (s * sep, y, z), er, scl=(.8, .45, 1.15), part="Eyes")
        sphere(m, WHITE, (s * sep - .05, y - .08, z + .07), er * .38, part="Shine")
        sphere(m, BLUSH, (s * (sep + .27), y + .07, z - .23), .14, scl=(1, .35, .6), part="Blush")
def clockface(m, loc, normal, r=3.6, part="Face"):
    # normal: one of "+x","-x","+y","-y" in Blender axes; disc + rim + 12 marks
    rot = {"+x": (0, 90, 0), "-x": (0, -90, 0), "+y": (-90, 0, 0), "-y": (90, 0, 0)}[normal]
    cyl(m, WHITE, loc, r=r, h=.25, seg=28, rot=rot, part=part)
    tr = {"+x": (0, 90, 0), "-x": (0, 90, 0), "+y": (90, 0, 0), "-y": (90, 0, 0)}[normal]
    off = {"+x": (.26, 0, 0), "-x": (-.26, 0, 0), "+y": (0, .26, 0), "-y": (0, -.26, 0)}[normal]
    torus(m, BRASS, (loc[0] + off[0] * .5, loc[1] + off[1] * .5, loc[2]), R=r, r=.32, rot=tr, seg=28, rseg=8, part=part + "Rim")
    for i in range(12):
        a = 2 * math.pi * i / 12; u, v = math.cos(a) * r * .8, math.sin(a) * r * .8
        p = (loc[0] + off[0], loc[1] + u, loc[2] + v) if normal[1] == "x" else (loc[0] + u, loc[1] + off[1], loc[2] + v)
        sphere(m, INK, p, .22 if i % 3 == 0 else .14, part=part + "Marks")
# 1) island: machine base exactly 261 x 124 (no overhang), riveted copper plates, brass bands, tapering underside, hanging pipes
isl = add("ClockIsland", 280)
rbox(isl, COPPER, (0, 0, -16), (261, 124, 32), r=2.5, part="Body")
rbox(isl, BRASS_D, (0, 0, -1.3), (261.6, 124.6, 2.6), r=.8, part="Rim")
rbox(isl, BRASS, (0, 0, -12), (261.8, 124.8, 2.2), r=.6, part="Band")
rbox(isl, COPPER_D, (0, 0, -40), (220, 100, 18), r=4, part="Under")
lathe(isl, COPPER_D, [(46, 0), (34, -14), (18, -26), (6, -34), (0, -36)], loc=(0, 0, -49), seg=12, sx=2.0, sy=1.0, part="Under")
for x in range(-120, 121, 16):
    for y in (-62.4, 62.4):
        sphere(isl, BRASS, (x, y, -6), .7, scl=(1, .5, 1), part="Rivets"); sphere(isl, BRASS, (x, y, -18), .7, scl=(1, .5, 1), part="Rivets")
for k, (x, y) in enumerate([(-70, 30), (-20, -25), (35, 20), (80, -30), (-100, -10), (110, 15)]):
    tube(isl, IRON, [(x, y, -48), (x + 2, y, -60), (x - 1, y, -70)], r=1.4, seg=8, smooth=3, part="Pipes")
    sphere(isl, BRASS, (x - 1, y, -71), 2.0, part="PipeEnds")
# 2) side gear (spins on the island sides; axle = Roblox Z)
sg = add("SideGear", 30); gear(sg, BRASS, (0, 0, 0), 12, 2.4, 14, axis="y", hub=COPPER_D)
gg = add("GiantGear", 22); gear(gg, BRASS, (0, 0, 0), 8, 1.8, 12, axis="y", hub=TEAL)
# 3) path tile, lamp, wall, corner
pt = add("GearPathTile", 9)
rbox(pt, P("E6C98A"), (0, 0, 0), (7.94, 7.94, .35), r=.15, base=True, part="Plate")
gear(pt, P("C99A45"), (0, 0, .38), 2.2, .06, 10, axis="z", part="Inlay")
lp = add("ClockLamp", 4)
cyl(lp, IRON, (0, 0, 0), r=.32, h=7.6, seg=10, part="Post"); cyl(lp, IRON, (0, 0, 0), r=.7, h=.6, seg=10, part="Post")
rbox(lp, BRASS, (0, 0, 7.6), (1.5, 1.5, .3), r=.1, part="Cage"); rbox(lp, WARM, (0, 0, 8.6), (1.1, 1.1, 1.6), r=.15, part="Light")
lathe(lp, BRASS, [(1.0, 9.4), (.5, 10.2), (0, 10.6)], seg=4, part="Cage"); gear(lp, BRASS, (0, 0, 3.0), .9, .2, 8, axis="y", part="Deco")
cw = add("ClockWall", 46)
rbox(cw, COPPER, (0, 0, 0), (44, 3, 15), r=.4, base=True, part="Panel")
for k in range(5): rbox(cw, COPPER_D, (-17.6 + k * 8.8, -1.52, 7.5), (.3, .1, 14.4), r=.05, part="Seams")
for x in range(-20, 21, 4):
    for z in (2.0, 13.0): sphere(cw, BRASS, (x, -1.55, z), .3, scl=(1, .5, 1), part="Rivets")
tube(cw, BRASS, [(-22, -1.9, 9.2), (22, -1.9, 9.2)], r=.55, seg=10, smooth=1, part="Pipe")
for x in (-12, 14): gear(cw, TEAL, (x, -1.75, 5.2), 2.6, .3, 10, axis="y", part="Gears", hub=BRASS)
rbox(cw, BRASS_D, (0, 0, 15), (44.4, 3.6, 1.0), r=.4, base=True, part="TopRail")
cc = add("ClockCorner", 8)
rbox(cc, COPPER_D, (0, 0, 0), (5.4, 5.4, 17), r=.5, base=True, part="Post")
for nrm, loc in (("-y", (0, -2.75, 12.5)), ("+x", (2.75, 0, 12.5))): clockface(cc, loc, nrm, r=1.8, part="Face")
lathe(cc, BRASS, [(3.2, 17), (2.6, 18.6), (1.2, 20), (0, 20.6)], seg=16, part="Dome"); sphere(cc, TEAL, (0, 0, 21.2), .7, part="Knob")
# 4) houses
ha = add("ClockHouseA", 12)
rbox(ha, CREAM, (0, 0, 0), (8, 7, 8), r=.4, base=True, part="Walls")
prism(ha, TEAL, [(-4.8, 0), (4.8, 0), (0, 4.2)], 8.2, loc=(0, 4.1, 8), rot=(90, 0, 0), part="Roof")
cyl(ha, COPPER, (2.2, 1.5, 9.5), r=.7, h=4.0, seg=10, part="Chimney"); sphere(ha, P("FFFFFF", "SP", .3), (2.2, 1.5, 14.1), .9, part="Steam")
torus(ha, BRASS, (-1.6, -3.55, 4.8), R=1.2, r=.22, rot=(90, 0, 0), seg=20, rseg=6, part="Porthole"); cyl(ha, GLASS, (-1.6, -3.4, 4.8), r=1.05, h=.1, seg=20, rot=(90, 0, 0), part="Glass")
rbox(ha, COPPER_D, (2.0, -3.55, 0), (1.8, .2, 3.4), r=.4, base=True, part="Door")
gear(ha, BRASS, (3.6, -3.6, 6.4), .9, .15, 8, axis="y", part="Deco")
hb = add("ClockHouseB", 9)
cyl(hb, P("FFD9C2"), (0, 0, 0), r=3.2, h=12, seg=18, part="Walls")
lathe(hb, BRASS, [(3.8, 12), (3.0, 13.6), (1.4, 15.2), (0, 16)], seg=18, part="Dome"); sphere(hb, TEAL, (0, 0, 16.4), .55, part="Knob")
for z in (4, 8.5):
    torus(hb, BRASS, (0, -3.25, z), R=1.0, r=.18, rot=(90, 0, 0), seg=16, rseg=6, part="Porthole"); cyl(hb, GLASS, (0, -3.12, z), r=.85, h=.1, seg=16, rot=(90, 0, 0), part="Glass")
tube(hb, COPPER, [(3.1, 0, 1), (3.6, -.5, 6), (3.2, 0, 11)], r=.3, seg=8, smooth=3, part="Pipes")
# 5) landmark: clock tower (faces on 4 sides; hands are a separate spinning model)
ct = add("ClockTower", 20)
rbox(ct, STONE, (0, 0, 0), (14, 14, 6), r=.8, base=True, part="Base")
rbox(ct, CREAM, (0, 0, 6), (10, 10, 30), r=.5, base=True, part="Body")
for sx in (-1, 1):
    for sy in (-1, 1): rbox(ct, BRASS_D, (sx * 5, sy * 5, 6), (1.2, 1.2, 30), r=.3, base=True, part="Trim")
for z in (14, 22, 34): rbox(ct, BRASS, (0, 0, z), (10.6, 10.6, .8), r=.25, part="Bands")
for nrm, loc in (("+x", (5.1, 0, 27)), ("-x", (-5.1, 0, 27)), ("+y", (0, 5.1, 27)), ("-y", (0, -5.1, 27))): clockface(ct, loc, nrm, r=3.7)
lathe(ct, TEAL, [(7.6, 36), (5.6, 39), (2.4, 43.5), (0, 46)], seg=4, rot=(0, 0, 45), part="Roof")
cyl(ct, BRASS, (0, 0, 46), r=.25, h=4, seg=8, part="Spire"); sphere(ct, BRASS, (0, 0, 50.4), .7, part="Spire")
rbox(ct, COPPER_D, (0, -7.05, 0), (4, .3, 5.2), r=1.4, base=True, part="Door")
hd = add("ClockHands", 9)
rbox(hd, INK, (0, -.15, 1.05), (.45, .12, 2.3), r=.1, part="Hands"); rbox(hd, INK, (.85, -.2, .45), (.35, .1, 3.2), r=.08, rot=(0, -65, 0), part="Hands")
sphere(hd, BRASS, (0, -.25, 0), .45, scl=(1, .5, 1), part="Cap")
# 6) activity: gear stepping platforms on pipe pillars + clock crank machine on a high platform
gs = add("GearStep", 9)
cyl(gs, IRON, (0, 0, 0), r=.9, h=10, seg=10, part="Pillar"); gear(gs, BRASS, (0, 0, 10.5), 3.6, 1.0, 12, axis="z", part="Platform")
cp = add("CrankPlatform", 16)
cyl(cp, IRON, (0, 0, 0), r=1.4, h=15, seg=12, part="Pillar")
for x, y in ((-3, -3), (3, 3), (-3, 3), (3, -3)): cyl(cp, IRON, (x, y, 0), r=.6, h=15, seg=8, part="Pillar")
gear(cp, BRASS, (0, 0, 15.5), 6.5, 1.0, 16, axis="z", part="Platform")
ck = add("ClockCrank", 8)
rbox(ck, COPPER, (0, 0, 0), (3.6, 2.6, 2.8), r=.3, base=True, part="Box")
cyl(ck, WHITE, (0, -1.32, 1.7), r=.65, h=.1, seg=16, rot=(90, 0, 0), part="Gauge"); rbox(ck, RED := P("FF4B4B"), (.2, -1.4, 1.85), (.08, .05, .5), r=.02, rot=(0, -40, 0), part="Needle")
torus(ck, BRASS, (2.1, 0, 1.6), R=1.1, r=.16, rot=(0, 90, 0), seg=20, rseg=6, part="Wheel")
tube(ck, BRASS, [(2.2, 0, 1.6), (2.4, 0, 2.8), (3.1, 0, 2.8)], r=.12, seg=6, smooth=1, part="Handle"); sphere(ck, RED, (3.25, 0, 2.8), .3, part="Knob")
cyl(ck, BRASS, (-1, .5, 2.8), r=.3, h=1.4, seg=8, part="Whistle"); sphere(ck, WARM, (0, 0, 3.4), .45, part="Glow")
# 7) gate (Toybox -> Clockwork) and brass girder bridge (S-curve end (59, 8, -80) in Roblox local)
gt = add("ClockGate", 22)
for sx in (-1, 1):
    rbox(gt, COPPER_D, (sx * 8.8, 0, 0), (2.6, 2.6, 13), r=.4, base=True, part="Pillars")
    gear(gt, BRASS, (sx * 8.8, -1.4, 9.0), 1.8, .3, 10, axis="y", part="PillarGears")
torus(gt, BRASS, (0, 0, 13), R=8.8, r=.9, arc=180, rot=(90, 0, 0), seg=28, rseg=8, part="Arch")
clockface(gt, (0, -.4, 21.0), "-y", r=2.6, part="Face"); clockface(gt, (0, .4, 21.0), "+y", r=2.6, part="FaceBack")
def bez(p0, p1, p2, p3, t):
    u = 1 - t; return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t
def curve(end, n=26):
    P0 = Vector((0, 0, 0)); P3 = Vector(end); P1 = Vector((end[0] * .48, 0, 0)); P2 = P3 - Vector((end[0] * .48, 0, 0))
    pts = [bez(P0, P1, P2, P3, i / n) for i in range(n + 1)]; fr = []
    for i, p in enumerate(pts):
        t = pts[min(i + 1, n)] - pts[max(i - 1, 0)]; t.y = 0; t.normalize(); fr.append((p, Vector((-t.z, 0, t.x))))
    return fr
br = add("BridgeToyboxClockwork", 130); F = curve((59, 8, -80))
tb = bmesh.new(); rows = []
for p, r in F:
    rows.append([tb.verts.new(R2B(v)) for v in (p - r * 5, p + r * 5, p + r * 5 - Vector((0, 1.2, 0)), p - r * 5 - Vector((0, 1.2, 0)))])
for A, B in zip(rows, rows[1:]):
    for k in range(4): tb.faces.new((A[k], A[(k + 1) % 4], B[(k + 1) % 4], B[k]))
tb.faces.new(list(reversed(rows[0]))); tb.faces.new(rows[-1]); bmesh.ops.recalc_face_normals(tb, faces=tb.faces); _merge(br.bm("Deck", P("8C7B6B")), tb)
for s in (-1, 1):
    tube(br, BRASS, [R2B(p + r * s * 5.0 + Vector((0, 2.8, 0))) for p, r in F], r=.3, seg=8, smooth=1, part="Rails")
    tube(br, COPPER_D, [R2B(p + r * s * 5.1 + Vector((0, .1, 0))) for p, r in F], r=.35, seg=8, smooth=1, part="Kerb")
    for i in range(0, len(F) - 2, 2):
        p, r = F[i]; q, rq = F[i + 2]
        tube(br, COPPER_D, [R2B(p + r * s * 5.0), R2B(p + r * s * 5.0 + Vector((0, 2.8, 0)))], r=.18, seg=6, smooth=1, part="Posts")
        tube(br, COPPER_D, [R2B(p + r * s * 5.0 + Vector((0, .2, 0))), R2B(q + rq * s * 5.0 + Vector((0, 2.6, 0)))], r=.12, seg=6, smooth=1, part="Braces")
for i in range(0, len(F), 6):
    p, r = F[i]
    for s in (-1, 1): sphere(br, BRASS, R2B(p + r * s * 5.0 + Vector((0, 3.1, 0))), .38, part="Knobs")
# 8) background: warm stone massifs with giant half-buried gears
def massif(m, rock, loc, r, h, seed, seg=18, rings=10, ridges=5, jag=.06, part="Rock"):
    rnd = random.Random(seed); ph = rnd.uniform(0, 6.28)
    def R(t):
        t0 = .82
        if t <= t0: return (1 - t) ** .78
        k = (t - t0) / (1 - t0); return (1 - t0) ** .78 * math.sqrt(max(0.0, 1 - k * k))
    tbm = bmesh.new(); vs = []
    for k in range(rings + 1):
        t = k / rings; row = []
        for i in range(seg):
            a = 2 * math.pi * i / seg; rr = r * R(t) * (1 + .13 * math.sin(ridges * a + ph + t * 1.5)) * (1 + rnd.uniform(-jag, jag))
            row.append(tbm.verts.new((loc[0] + math.cos(a) * rr, loc[1] + math.sin(a) * rr * .85, loc[2] + h * t)))
        vs.append(row)
    top = tbm.verts.new((loc[0], loc[1], loc[2] + h))
    for A, B in zip(vs, vs[1:]):
        for i in range(seg): j = (i + 1) % seg; tbm.faces.new((A[i], A[j], B[j], B[i]))
    for i in range(seg): tbm.faces.new((vs[-1][i], vs[-1][(i + 1) % seg], top))
    tbm.faces.new(list(reversed(vs[0]))); bmesh.ops.recalc_face_normals(tbm, faces=tbm.faces); _merge(m.bm(part, rock), tbm)
gr = add("GearRange", 700); rq = random.Random(13)
for i in range(7):
    x = -300 + i * 100 + rq.uniform(-20, 20); h = rq.uniform(170, 300)
    massif(gr, P("C4A07E"), (x, rq.uniform(10, 50), 0), h * rq.uniform(.42, .52), h, 900 + i)
for i in range(6):
    x = -280 + i * 110 + rq.uniform(-15, 15); h = rq.uniform(70, 110)
    massif(gr, P("B48F6E"), (x, rq.uniform(-70, -45), 0), h * .75, h, 950 + i, seg=14, rings=7, ridges=3, part="Hills")
for x, z, R in ((-170, 120, 62), (60, 150, 70), (230, 100, 55)):
    gear(gr, P("D9AE55", "ME"), (x, -20, z), R, 12, 16, axis="y", part="BigGears", hub=P("B8862E", "ME"))
gr.sharp["Rock__" + P("C4A07E")] = 34
# 9) Gear Egg on a machine pedestal
egg = add("GearEgg", 8)
rbox(egg, COPPER, (0, 0, 0), (4.4, 4.4, 2.8), r=.4, base=True, part="Pedestal")
gear(egg, BRASS, (0, 0, 2.95), 2.6, .3, 14, axis="z", part="PedestalGear")
PROF = [(0, 0), (1.0, .12), (1.6, .6), (1.95, 1.4), (2.05, 2.2), (1.95, 3.0), (1.65, 3.8), (1.1, 4.5), (.5, 4.88), (0, 5.0)]
Z0 = 3.2
lathe(egg, P("E8C26A"), PROF, loc=(0, 0, Z0), seg=28, part="Shell")
torus(egg, TEAL, (0, 0, Z0 + 2.2), R=2.08, r=.2, seg=40, rseg=8, part="Band")
for i in range(16):
    a = 2 * math.pi * i / 16
    rbox(egg, TEAL, (math.cos(a) * 2.2, math.sin(a) * 2.2, Z0 + 2.2), (.35, .45, .5), r=.05, rot=(0, 0, math.degrees(a)), part="BandTeeth")
cyl(egg, WHITE, (0, -2.0, Z0 + 3.3), r=.75, h=.12, seg=20, rot=(90, 0, 0), part="ClockFace"); torus(egg, BRASS, (0, -2.06, Z0 + 3.3), R=.75, r=.1, rot=(90, 0, 0), seg=20, rseg=6, part="ClockRim")
rbox(egg, INK, (0, -2.15, Z0 + 3.55), (.1, .05, .5), r=.02, part="ClockHands"); rbox(egg, INK, (.18, -2.15, Z0 + 3.3), (.4, .05, .08), r=.02, part="ClockHands")
for i, (h, ang) in enumerate([(1.0, 40), (1.1, 160), (1.0, 280), (4.0, 0), (4.1, 120), (4.0, 240)]):
    a = math.radians(ang); rr = 1.98 if h < 2.2 else 1.6
    sphere(egg, BRASS, (math.cos(a) * rr, math.sin(a) * rr, Z0 + h), .17, part="Rivets")
# 10) pets (face -Y, feet at z = 0)
p1 = add("Pet_BrassBeetle", 4)
sphere(p1, BRASS, (0, .2, .8), .95, scl=(1, 1.2, .78), part="Shell"); rbox(p1, BRASS_D, (0, .25, 1.5), (.08, 2.0, .1), r=.03, part="Seam")
sphere(p1, P("6B4E2E"), (0, -.95, .75), .55, part="Head"); face(p1, -1.38, .82, sep=.22, er=.11)
for s in (-1, 1):
    for y in (-.3, .3, .9): tube(p1, P("6B4E2E"), [(s * .75, y, .5), (s * 1.15, y, .2), (s * 1.2, y, 0)], r=.07, seg=6, smooth=2, part="Legs")
    tube(p1, P("6B4E2E"), [(s * .2, -1.3, 1.1), (s * .45, -1.6, 1.6)], r=.05, seg=6, smooth=1, part="Antennae"); sphere(p1, TEAL, (s * .47, -1.62, 1.66), .1, part="AntennaTips")
gear(p1, TEAL, (0, .5, 1.62), .38, .08, 8, axis="z", part="BackGear")
p2 = add("Pet_ClockworkBird", 4)
sphere(p2, TEAL, (0, 0, 1.0), .95, scl=(1, 1.05, 1), part="Body"); sphere(p2, CREAM, (0, -.62, .85), .55, scl=(1, .45, 1.05), part="Belly")
lathe(p2, P("FF9A3C"), [(.25, 0), (.12, .32), (0, .38)], loc=(0, -.92, 1.15), rot=(90, 0, 0), seg=10, part="Beak")
for s in (-1, 1): sphere(p2, BRASS, (s * .95, .15, 1.05), .48, scl=(.3, 1.0, .7), rot=(0, s * 15, 0), part="Wings"); tube(p2, P("FF9A3C"), [(s * .3, 0, .1), (s * .3, -.2, 0)], r=.06, seg=6, smooth=1, part="Feet")
for k in (-1, 0, 1): rbox(p2, BRASS, (k * .25, 1.05, 1.15), (.18, .7, .08), r=.04, rot=(-25, k * 18, 0), part="Tail")
face(p2, -.88, 1.3, sep=.3, er=.13)
cyl(p2, BRASS, (0, .9, 1.4), r=.06, h=.4, seg=6, rot=(90, 0, 0), part="Key"); torus(p2, BRASS, (0, 1.42, 1.4), R=.2, r=.05, rot=(0, 0, 0), seg=12, rseg=6, part="Key")
p3 = add("Pet_SteamPup", 4)
sphere(p3, COPPER, (0, .25, .8), .85, scl=(.95, 1.15, .85), part="Body"); sphere(p3, COPPER, (0, -.6, 1.45), .68, part="Head")
sphere(p3, CREAM, (0, -1.15, 1.32), .32, scl=(1.1, .8, .8), part="Snout"); sphere(p3, INK, (0, -1.42, 1.42), .1, part="Nose")
for s in (-1, 1): sphere(p3, BRASS, (s * .62, -.45, 1.75), .3, scl=(.6, .5, 1.3), rot=(0, s * 25, 0), part="Ears"); sphere(p3, COPPER, (s * .42, -.45, .15), .25, scl=(1, 1.2, .7), part="Feet")
torus(p3, TEAL, (0, -.45, 1.0), R=.5, r=.09, seg=16, rseg=6, part="Collar"); gear(p3, BRASS, (0, -.95, .95), .17, .05, 8, axis="y", part="Tag")
cyl(p3, IRON, (0, .55, 1.45), r=.14, h=.5, seg=8, part="Chimney"); sphere(p3, P("FFFFFF", "SP", .25), (0, .55, 2.15), .22, part="Steam")
face(p3, -1.08, 1.62, sep=.27, er=.12)
p4 = add("Pet_GearFox", 4); FOX = P("FF8A3D")
sphere(p4, FOX, (0, .2, .85), .85, scl=(.9, 1.15, .9), part="Body"); sphere(p4, CREAM, (0, -.45, .78), .48, scl=(1, .5, 1), part="Belly")
sphere(p4, FOX, (0, -.55, 1.6), .65, part="Head"); sphere(p4, CREAM, (0, -1.05, 1.45), .3, scl=(1, .9, .7), part="Belly")
sphere(p4, INK, (0, -1.32, 1.5), .09, part="Nose")
for s in (-1, 1): lathe(p4, FOX, [(.25, 0), (.12, .4), (0, .55)], loc=(s * .38, -.5, 2.05), seg=8, part="Ears"); sphere(p4, INK, (s * .3, -.6, .1), .2, scl=(1, 1.2, .6), part="Feet")
tube(p4, FOX, [(0, 1.0, .7), (.3, 1.6, 1.1), (.2, 1.9, 1.7)], r=.38, r2=.2, seg=10, smooth=3, part="Tail"); gear(p4, BRASS, (.2, 1.95, 1.95), .3, .1, 8, axis="y", part="TailGear")
gear(p4, BRASS, (0, -.82, .9), .22, .06, 8, axis="y", part="Amulet"); face(p4, -1.0, 1.72, sep=.28, er=.12)
p5 = add("Pet_ClockworkDragon", 4)
sphere(p5, TEAL, (0, .15, 1.0), 1.0, scl=(1, 1.1, .95), part="Body"); sphere(p5, CREAM, (0, -.55, .88), .58, scl=(1, .5, 1), part="Belly")
sphere(p5, TEAL, (0, -.65, 1.85), .72, part="Head")
for s in (-1, 1):
    lathe(p5, BRASS, [(.15, 0), (.06, .45), (0, .5)], loc=(s * .35, -.55, 2.45), rot=(-20, s * 15, 0), seg=8, part="Horns")
    prism(p5, BRASS, [(0, 0), (1.4, .5), (1.2, -.3), (.6, -.6)], .08, loc=(s * .75, .45, 1.45), rot=(90, 0, 90 + s * 90), part="Wings")
    sphere(p5, TEAL_D, (s * .45, -.3, .2), .28, scl=(1, 1.3, .6), part="Feet")
tube(p5, TEAL, [(0, 1.0, .7), (.3, 1.7, .6), (.5, 2.2, .45)], r=.32, r2=.1, seg=8, smooth=3, part="Tail"); gear(p5, BRASS, (.55, 2.3, .45), .25, .08, 8, axis="y", part="TailGear")
for k, (y, z) in enumerate([(-.1, 2.0), (.4, 1.9), (.85, 1.6)]): lathe(p5, BRASS, [(.16, 0), (0, .3)], loc=(0, y, z), seg=6, part="Spikes")
face(p5, -1.28, 1.95, sep=.3, er=.14); sphere(p5, P("FFE2A0", "NE"), (0, -1.0, .6), .1, part="Glow")

objs = realize(models, 'W2_Clockwork')
