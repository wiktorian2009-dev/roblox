import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random, bmesh
from mathutils import Vector

# Detailed Sakura pagoda (Claude 2026-10-03): 3 storeys, curved upturned roofs, brackets, rafters, balconies, bells, sorin spire. Front = -Y.
from w2lib import *
from w2lib import _merge
VER, VER_D, PLA, WOOD, ROOF, ROOF_L, RIDGE = P("E84A3A"), P("C23A2C"), P("F7F2E8"), P("5A3A2E"), P("2F63B7"), P("4C82D6"), P("23498C")
GOLD, GOLD_D, STONE, STONE_D, PAPER, WARM, INK = P("F2C14E", "ME"), P("D9A23A", "ME"), P("D8D2C8"), P("BEB7AC"), P("F3E6C8"), P("FFD98A", "NE"), P("2A2433")
m = Model("SakuraPagodaV2", at=(0, 0, 0)); models = [m]
def roof(a_in, z_in, R, z_out, lift, seg=16, rings=6, thick=.7, ribs=9):
    N = 4 * seg; tb = bmesh.new()
    def perim(s, i):
        side, t = i // seg, (i % seg) / seg
        return [(-s + 2 * s * t, -s), (s, -s + 2 * s * t), (s - 2 * s * t, s), (-s, s - 2 * s * t)][side]
    def zat(x, y, s, u):
        c = min(abs(x), abs(y)) / s; ze = z_out + lift * c ** 4
        return z_in + (ze - z_in) * (u ** .75)
    top, bot = [], []
    for k in range(rings + 1):
        u = k / rings; s = a_in + (R - a_in) * u; row = []
        for i in range(N):
            x, y = perim(s, i); row.append(tb.verts.new((x, y, zat(x, y, s, u))))
        top.append(row)
    for k, row in enumerate(top): bot.append([tb.verts.new((v.co.x, v.co.y, v.co.z - thick * (.6 + .4 * k / rings))) for v in row])
    for k in range(rings):
        A, B, C, D = top[k], top[k + 1], bot[k], bot[k + 1]
        for i in range(N):
            j = (i + 1) % N; tb.faces.new((A[i], A[j], B[j], B[i])); tb.faces.new((C[i], D[i], D[j], C[j]))
    for (A, C, flip) in ((top[-1], bot[-1], False), (top[0], bot[0], True)):
        for i in range(N):
            j = (i + 1) % N; tb.faces.new((A[j], C[j], C[i], A[i]) if flip else (A[i], C[i], C[j], A[j]))
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces); _merge(m.bm("Roof", ROOF), tb)
    def surf(x_frac, u, side):   # point on the roof top surface; x_frac in [-1,1] along a side
        s = a_in + (R - a_in) * u; x, y = x_frac * s, -s
        z = zat(x, y, s, u) + .08
        for _ in range(side): x, y = -y, x
        return (x, y, z)
    for side in range(4):
        for r_ in range(ribs):
            f = -1 + 2 * (r_ + 1) / (ribs + 1)
            tube(m, ROOF_L, [surf(f, u / 4, side) for u in range(5)], r=.13, seg=4, smooth=1, part="TileRibs")
        tube(m, GOLD, [surf(-1 + 2 * t / 12, 1.0, side) for t in range(13)], r=.17, seg=6, smooth=1, part="EaveTrim")
        for k in range(int((2 * (R - 1.2)) / .85)):
            x = -(R - 1.2) + k * .85; ez = z_out + lift * (abs(x) / R) ** 4 - thick - .1
            p = [(x, -R + .5, ez)]
            for _ in range(side): p = [(-p[0][1], p[0][0], p[0][2])]
            rbox(m, P("FFF6E6"), p[0], (.24, .9, .26) if side % 2 == 0 else (.9, .24, .26), r=0, part="Rafters")
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        pts = []
        for u in range(7):
            uu = u / 6; s = a_in + (R - a_in) * uu; pts.append((sx * s, sy * s, z_in + (z_out + lift - z_in) * uu ** .75 + .12))
        tube(m, RIDGE, pts, r=.33, seg=6, smooth=1, part="HipRidges")
        tip = (sx * R, sy * R, z_out + lift + .15)
        sphere(m, GOLD, tip, .45, part="Ornaments"); torus(m, GOLD_D, (tip[0], tip[1], tip[2] + .45), R=.35, r=.1, rot=(90, 0, 45 * sx * sy), seg=12, rseg=4, part="Ornaments")
        tube(m, GOLD_D, [tip, (tip[0], tip[1], tip[2] - 1.4)], r=.05, seg=4, smooth=1, part="BellChains")
        lathe(m, GOLD, [(0, 0), (.38, .1), (.34, .45), (.15, .7), (0, .75)], loc=(tip[0], tip[1], tip[2] - 2.1), seg=10, part="Bells")
    return lambda sx, sy: (sx * R, sy * R, z_out + lift + .15)
def storey(a, z0, h, door, deck):
    rbox(m, PLA, (0, 0, z0), (2 * a - .3, 2 * a - .3, h), r=.15, base=True, part="Walls")
    for zz in (z0 + h * .28, z0 + h * .72): 
        for side in range(4):
            loc = [(0, -a + .12, zz), (a - .12, 0, zz), (0, a - .12, zz), (-a + .12, 0, zz)][side]
            rbox(m, WOOD, loc, (2 * a, .32, .35) if side % 2 == 0 else (.32, 2 * a, .35), r=0, part="Beams")
    rbox(m, VER_D, (0, 0, z0 + h - .5), (2 * a + .4, 2 * a + .4, .6), r=0, part="TopBeam")
    cols = set()
    for t in (-a, -a / 3, a / 3, a):
        for c in ((t, -a), (t, a), (-a, t), (a, t)): cols.add((round(c[0], 3), round(c[1], 3)))
    for (x, y) in cols:
        cyl(m, VER, (x, y, z0), r=.5, h=h, seg=12, part="Columns"); cyl(m, STONE_D, (x, y, z0), r=.7, h=.35, seg=8, part="ColBases")
        out_x, out_y = (1 if x > a * .9 else -1 if x < -a * .9 else 0), (1 if y > a * .9 else -1 if y < -a * .9 else 0)
        for k, (w, o) in enumerate(((1.0, 0), (1.3, .5), (1.0, .95))):
            rbox(m, VER, (x + out_x * o, y + out_y * o, z0 + h + .2 + k * .42), (w, w, .38), r=0, part="Brackets")
        sphere(m, GOLD, (x + out_x * 1.25, y + out_y * 1.25, z0 + h + .95), .22, seg=6, rings=4, part="BracketCaps")
    for side in range(4):
        for bay in (-1, 0, 1):
            t = bay * 2 * a / 3
            loc = [(t, -a - .02, z0 + h * .48), (a + .02, t, z0 + h * .48), (-t, a + .02, z0 + h * .48), (-a - .02, -t, z0 + h * .48)][side]
            alongx = side % 2 == 0
            if door and side == 0 and bay == 0:
                for lr in (-1, 1):
                    dl = (loc[0] + lr * .55, loc[1] - .05, z0 + .1)
                    rbox(m, VER_D, dl, (1.05, .2, h * .62), r=0, base=True, part="Doors")
                    for i in range(3):
                        for j in range(4): sphere(m, GOLD, (dl[0] - .3 + i * .3, dl[1] - .12, z0 + .9 + j * h * .13), .07, seg=6, rings=4, part="Studs")
                torus(m, GOLD, (loc[0], loc[1] - .2, z0 + h * .33), R=.22, r=.05, rot=(90, 0, 0), seg=10, rseg=4, part="Studs")
            else:
                fw, fh = 2 * a / 3 - 1.1, h * .42
                rbox(m, PAPER, loc, (fw, .1, fh) if alongx else (.1, fw, fh), r=0, part="Paper")
                rbox(m, WOOD, loc, (fw + .3, .2, .25) if alongx else (.2, fw + .3, .25), r=0, part="Lattice")
                for zz in (-fh / 2, fh / 2): rbox(m, WOOD, (loc[0], loc[1], loc[2] + zz), (fw + .3, .22, .22) if alongx else (.22, fw + .3, .22), r=0, part="Lattice")
                for i in range(6):
                    off = -fw / 2 + fw * (i + .5) / 6
                    p = (loc[0] + off, loc[1], loc[2]) if alongx else (loc[0], loc[1] + off, loc[2])
                    rbox(m, WOOD, p, (.1, .24, fh) if alongx else (.24, .1, fh), r=0, part="Lattice")
    if deck:
        d = deck
        rbox(m, WOOD, (0, 0, z0 - .35), (2 * d, 2 * d, .4), r=0, base=True, part="Decks")
        posts = []
        n = 9
        for side in range(4):
            for i in range(n):
                t = -d + 2 * d * i / n; posts.append([(t, -d), (d, t), (-t, d), (-d, -t)][side])
        for (x, y) in posts:
            if door and abs(x) < 2.2 and y < -d * .9: continue
            cyl(m, VER, (x, y, z0), r=.14, h=1.6, seg=6, part="Railing")
        for zz in (z0 + .8, z0 + 1.55):
            ring = [(-d, -d, zz), (d, -d, zz), (d, d, zz), (-d, d, zz), (-d, -d, zz)]
            if door:
                tube(m, VER, [(2.2, -d, zz), (d, -d, zz), (d, d, zz), (-d, d, zz), (-d, -d, zz), (-2.2, -d, zz)], r=.09, seg=6, smooth=1, part="Railing")
            else: tube(m, VER, ring, r=.09, seg=6, smooth=1, part="Railing")
# podium + stairs + stone lanterns
rbox(m, STONE_D, (0, 0, 0), (24, 24, 1.2), r=.3, base=True, part="Podium")
rbox(m, STONE, (0, 0, 1.2), (21, 21, 1.2), r=.25, base=True, part="Podium")
for k in range(3): rbox(m, STONE, (0, -10.5 - (2 - k) * .9, 0), (6, 1.0, 0.8 * (k + 1)), r=.1, base=True, part="Stairs")
for sx in (-1, 1):
    bx, by = sx * 5.2, -11.6
    cyl(m, STONE, (bx, by, 0), r=.8, h=.4, seg=8, part="Toro"); cyl(m, STONE, (bx, by, .4), r=.3, h=2.2, seg=8, part="Toro")
    rbox(m, STONE_D, (bx, by, 2.6), (1.3, 1.3, .3), r=.1, part="Toro"); rbox(m, WARM, (bx, by, 3.3), (.8, .8, 1.0), r=.1, part="ToroLight")
    for c in ((-.5, -.5), (.5, -.5), (-.5, .5), (.5, .5)): rbox(m, STONE, (bx + c[0], by + c[1], 3.3), (.25, .25, 1.0), r=.05, part="Toro")
    lathe(m, STONE_D, [(1.2, 3.85), (.9, 4.3), (.2, 4.7), (0, 4.8)], loc=(bx, by, 0), seg=6, part="Toro"); sphere(m, STONE, (bx, by, 5.0), .25, part="Toro")
# storeys + roofs
storey(6.5, 2.4, 9.0, True, 8.6)
tips1 = roof(5.6, 14.0, 13.2, 11.2, 1.9)
storey(5.3, 14.0, 7.0, False, 6.6)
roof(4.6, 23.4, 11.6, 20.8, 1.8)
storey(4.4, 23.4, 6.2, False, 5.6)
tips3 = roof(1.3, 33.8, 10.2, 29.4, 1.7, rings=7)
# hanging paper lanterns under the first eave (front corners)
for sx in (-1, 1):
    x, y = sx * 10.5, -10.5
    tube(m, INK, [(x, y, 12.2), (x, y, 10.6)], r=.04, seg=4, smooth=1, part="LanternCords")
    lathe(m, P("E8443A"), [(.0, 0), (.5, .1), (.75, .6), (.75, 1.3), (.5, 1.8), (0, 1.9)], loc=(x, y, 8.6), seg=14, part="Chochin")
    for zz in (8.55, 10.45): cyl(m, INK, (x, y, zz), r=.42, h=.12, seg=12, part="LanternCords")
    sphere(m, WARM, (x, y, 9.55), .3, part="ToroLight")
# sorin spire
rbox(m, RIDGE, (0, 0, 33.6), (2.8, 2.8, 1.2), r=.2, base=True, part="Roban")
lathe(m, GOLD, [(0, 34.8), (1.25, 34.8), (1.15, 35.4), (.6, 35.9), (0, 36.0)], seg=16, part="Sorin")
for k in range(8):
    a_ = 2 * math.pi * k / 8; sphere(m, GOLD_D, (math.cos(a_) * .8, math.sin(a_) * .8, 36.2), .32, scl=(1, 1, .6), part="Sorin")
cyl(m, GOLD_D, (0, 0, 36.0), r=.22, h=12.6, seg=10, part="Sorin")
for k in range(9): torus(m, GOLD, (0, 0, 37.3 + k * 1.2), R=.95 - k * .03, r=.13, seg=16, rseg=6, part="Kurin")
flame = [(0, 0), (.5, .5), (.35, 1.1), (.8, 1.6), (.4, 2.2), (.6, 2.8), (0, 2.6), (-.6, 2.8), (-.4, 2.2), (-.8, 1.6), (-.35, 1.1), (-.5, .5)]
for rz in (0, 90): prism(m, GOLD, flame, .12, loc=(0, 0, 47.4), rot=(90, 0, rz), part="Suien")
sphere(m, GOLD_D, (0, 0, 50.5), .35, part="Sorin")
lathe(m, GOLD, [(0, 50.8), (.45, 51.2), (.42, 51.7), (.12, 52.3), (0, 52.6)], seg=14, part="Hoju")
for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
    tip = tips3(sx, sy); top_ = (sx * .3, sy * .3, 47.0)
    mid = ((tip[0] + top_[0]) / 2, (tip[1] + top_[1]) / 2, (tip[2] + top_[2]) / 2 - 1.2)
    tube(m, GOLD_D, [top_, mid, (tip[0], tip[1], tip[2] + .3)], r=.06, seg=4, smooth=3, part="Chains")

objs = realize(models, 'W2_PagodaV2')
