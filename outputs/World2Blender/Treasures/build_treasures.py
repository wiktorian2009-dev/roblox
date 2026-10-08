import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

# World 2 treasure models for PNG icons (Claude 2026-10-02). Each builder makes one Model at the origin.
from w2lib import *
GOLD, GOLD_D, WHITE, INK = P("FFC94A", "ME"), P("E0A325", "ME"), P("FFFFFF"), P("2A2433")
def petal_poly(L_, W_, notch=.18, n=22):
    pts = []
    for i in range(n + 1):
        t = i / n; a = math.pi * t
        x = math.sin(a) * W_ * (1 - .25 * t); y = -L_ * .1 + L_ * (1 - math.cos(a)) * .55
        pts.append((x, y))
    pts = pts + [(-x, y) for (x, y) in reversed(pts[1:-1])]
    top = max(p[1] for p in pts)
    return [(x, y - (notch * L_ if abs(x) < W_ * .18 and y > top - .2 * L_ else 0)) for (x, y) in pts]
def B_BlossomPetal():
    m = Model("BlossomPetal")
    prism(m, P("FF9CC6"), petal_poly(2.6, 1.25), .35, loc=(0, .18, 0), rot=(90, 0, 0), bev=.12, part="Petal")
    prism(m, P("FFE3EF"), petal_poly(.9, .28, .0), .06, loc=(-.35, -.2, .55), rot=(90, 0, -12), part="Shine")
    torus(m, GOLD, (0, 0, -.6), R=.36, r=.11, rot=(90, 0, 0), seg=18, rseg=8, part="Ring")
    return m
def B_PaperFan():
    m = Model("PaperFan"); n = 9
    for i in range(n):
        a0 = math.radians(20 + 140 * i / n); a1 = math.radians(20 + 140 * (i + 1) / n)
        poly = [(math.cos(a0) * .35, math.sin(a0) * .35)] + [(math.cos(a0 + (a1 - a0) * k / 4) * 2.4, math.sin(a0 + (a1 - a0) * k / 4) * 2.4) for k in range(5)] + [(math.cos(a1) * .35, math.sin(a1) * .35)]
        prism(m, P("FF7FB0") if i % 2 else P("FFF0F6"), poly, .08, loc=(0, .04 + .03 * (i % 2), -1.0), rot=(90, 0, 0), part="Leaf" + str(i % 2))
    for i in range(n + 1):
        a = math.radians(20 + 140 * i / n)
        tube(m, P("8A5A3C"), [(0, .06, -1.0), (math.cos(a) * 2.45, .06, -1.0 + math.sin(a) * 2.45)], r=.05, seg=6, smooth=1, part="Ribs")
    flower(m, P("F06AA6"), GOLD, (-.9, -.12, .45), .32, rot=(90, 0, 0), part="Flowers")
    flower(m, P("FFFFFF"), GOLD, (.7, -.12, .85), .26, rot=(90, 0, 0), part="Flowers")
    sphere(m, GOLD, (0, 0, -1.0), .2, part="Pin")
    tube(m, P("E2453B"), [(0, 0, -1.05), (.1, 0, -1.6), (.05, 0, -2.0)], r=.08, seg=6, smooth=3, part="Tassel")
    lathe(m, P("E2453B"), [(.0, -2.6), (.22, -2.5), (.14, -2.0), (0, -1.95)], seg=10, part="Tassel")
    return m
def B_JadeTeacup():
    m = Model("JadeTeacup")
    cyl(m, P("E9F3EE"), (0, 0, 0), r=1.7, r2=1.85, h=.22, seg=28, bev=.08, part="Saucer")
    lathe(m, P("4FB58A"), [(.65, .22), (.8, .45), (1.15, 1.2), (1.25, 1.75), (1.12, 1.8), (1.0, 1.25), (0.6, .55), (0.01, .55)], seg=28, part="Cup")
    torus(m, GOLD, (0, 0, 1.78), R=1.19, r=.07, seg=32, rseg=6, part="Rim")
    cyl(m, P("C9A26B"), (0, 0, 1.5), r=1.02, h=.05, seg=24, part="Tea")
    torus(m, P("4FB58A"), (1.35, 0, 1.05), R=.38, r=.1, rot=(90, 0, 0), seg=16, rseg=6, part="Cup")
    for i, x in enumerate((-.35, .3)):
        tube(m, P("FFFFFF", "SP", .3), [(x, 0, 1.9), (x + .25, 0, 2.3), (x - .1, 0, 2.7), (x + .2, 0, 3.1)], r=.09, r2=.03, seg=6, smooth=4, part="Steam")
    flower(m, P("FF9CC6"), GOLD, (0, -1.13, 1.2), .3, rot=(90, 0, 0), part="Flower")
    return m
def B_GoldenKoiStatue():
    m = Model("GoldenKoiStatue")
    cyl(m, P("6FD3E6"), (0, 0, 0), r=1.5, r2=1.3, h=.5, seg=24, bev=.12, part="Wave")
    for i in range(6):
        a = 2 * math.pi * i / 6
        sphere(m, P("E8FAFF"), (math.cos(a) * 1.1, math.sin(a) * 1.1, .55), .32, scl=(1, 1, .6), part="Foam")
    T = Mx((0, .25, .45), (-24, 0, 0))
    lathe(m, GOLD, [(0, 0), (.3, .2), (.55, .7), (.62, 1.25), (.55, 1.75), (.33, 2.15), (0, 2.3)], loc=(0, .25, .45), rot=(-24, 0, 0), seg=18, sy=.82, part="Body")
    for s in (-1, 1):
        sphere(m, GOLD_D, T @ Vector((s * .62, 0, 1.45)), .34, scl=(.25, .7, 1.0), part="Fins")
        sphere(m, INK, T @ Vector((s * .33, -.42, 1.95)), .1, part="Eyes")
        sphere(m, P("FFFFFF"), T @ Vector((s * .31, -.5, 2.0)), .04, part="Shine")
        sphere(m, GOLD_D, T @ Vector((s * .25, .1, .05)), .45, scl=(.2, 1.0, .65), rot=(s * 25, 0, 0), part="Tail")
    sphere(m, GOLD_D, T @ Vector((0, .5, 1.3)), .5, scl=(.15, .8, .9), part="Fins")
    sphere(m, P("FFE38A"), T @ Vector((-.22, -.48, 1.2)), .18, scl=(1, .4, 1.6), part="Shine")
    return m
def B_EternalSakura():
    m = Model("EternalSakura")
    for k in range(5):
        a = 2 * math.pi * k / 5 + math.pi / 2
        prism(m, P("FFB8DA"), petal_poly(1.35, .72), .22, loc=(0, .1, 1.4), rot=(90, math.degrees(2 * math.pi * k / 5), 0), bev=.06, part="Crystal")
    sphere(m, P("FFF2A8", "NE"), (0, -.25, 1.4), .38, part="Core")
    for i, (x, z, s) in enumerate([(-1.5, 2.6, .25), (1.6, 2.4, .2), (1.3, .2, .22), (-1.4, .4, .18)]):
        prism(m, P("FFFFFF", "NE"), [(0, s * 2), (s * .45, s * .45), (s * 2, 0), (s * .45, -s * .45), (0, -s * 2), (-s * .45, -s * .45), (-s * 2, 0), (-s * .45, s * .45)], .1, loc=(x, -.2, z), rot=(-90, 0, 0), part="Sparkles")
    cyl(m, P("8FD3C0"), (0, 0, -.35), r=.12, h=1.0, seg=8, part="Stem")
    return m
def B_GummyDrop():
    m = Model("GummyDrop")
    lathe(m, P("FF4D6D"), [(1.4, 0), (1.37, .4), (1.2, 1.0), (.8, 1.55), (.3, 1.82), (0, 1.86)], seg=28, part="Drop")
    rq = random.Random(3)
    for i in range(26):
        a = rq.uniform(0, 6.283); h = rq.uniform(.15, 1.7); r = (1.4 - h * .62) + .02
        sphere(m, P("FFFFFF"), (math.cos(a) * r, math.sin(a) * r, h), .07, part="Sugar")
    sphere(m, P("FF9AAE"), (-.45, -.95, 1.1), .25, scl=(1, .4, 1.4), part="Shine")
    return m
def B_SwirlLollipop():
    m = Model("SwirlLollipop")
    cyl(m, P("FFF3DC"), (0, 0, -2.6), r=.13, h=2.6, seg=10, part="Stick")
    cyl(m, P("FFFFFF"), (0, .15, .9), r=1.5, h=.3, seg=32, rot=(90, 0, 0), bev=.08, part="Disc")
    pts = []
    for k in range(80):
        t = k / 79; a = t * 3 * 2 * math.pi; rr = .12 + 1.25 * t
        pts.append((rr * math.cos(a), -.17, .9 + rr * math.sin(a)))
    tube(m, P("FF7FB0"), pts, r=.13, seg=6, smooth=1, sq=.35, part="Swirl")
    torus(m, P("8FE8C8"), (0, 0, -.65), R=.24, r=.08, seg=14, rseg=6, part="Bow")
    for s in (-1, 1): sphere(m, P("8FE8C8"), (s * .35, -.05, -.6), .25, scl=(1, .5, .7), part="Bow")
    return m
def B_GoldenBonbon():
    m = Model("GoldenBonbon")
    sphere(m, GOLD, (0, 0, 0), 1.1, scl=(1.35, 1, 1), part="Foil")
    for s in (-1, 1):
        lathe(m, GOLD_D, [(.01, 0), (.5, .6), (.85, 1.1), (.3, 1.2), (0.01, 1.21)], loc=(s * 1.25, 0, 0), rot=(0, s * 90, 0), seg=12, wob=.12, seed=s + 2, part="Twist")
    torus(m, P("FF4D6D"), (0, 0, 0), R=1.08, r=.12, rot=(0, 90, 0), seg=28, rseg=6, part="Ribbon")
    sphere(m, P("FFF6C8"), (-.35, -.85, .45), .22, scl=(1.2, .4, .8), part="Shine")
    return m
def B_ChocolateCrown():
    m = Model("ChocolateCrown")
    lathe(m, P("7A4A2E"), [(1.5, 0), (1.55, .55), (1.6, .62), (1.36, .62), (1.32, .1), (0.01, .1)], seg=32, part="Band")
    for k in range(6):
        a = 2 * math.pi * k / 6
        lathe(m, P("7A4A2E"), [(.42, 0), (.3, .7), (0, 1.25)], loc=(math.cos(a) * 1.42, math.sin(a) * 1.42, .55), seg=10, part="Points")
        sphere(m, [P("FF4D6D"), P("8FD3FF"), P("FFE36E"), P("8FE8C8"), P("C9A7FF"), P("FFA94D")][k], (math.cos(a) * 1.42, math.sin(a) * 1.42, 1.85), .22, part="Gems" + str(k))
    torus(m, P("FFF3DC"), (0, 0, .62), R=1.48, r=.12, seg=32, rseg=6, part="Frosting")
    for k in range(12):
        a = 2 * math.pi * k / 12
        sphere(m, P("FFF3DC"), (math.cos(a) * 1.55, math.sin(a) * 1.55, .45), .13, scl=(1, 1, 2.0), part="Frosting")
    sphere(m, P("FF4D6D"), (0, -1.58, .32), .2, part="FrontGem")
    return m
def B_RainbowCrystal():
    m = Model("RainbowCrystal")
    cols = ["FF4D6D", "FFA94D", "FFE36E", "8FE8C8", "8FD3FF", "C9A7FF"]
    spec = [(0, 0, 0, 2.6, .55), (-.75, .2, -12, 1.8, .42), (.8, -.1, 14, 2.0, .45), (-.3, -.6, -6, 1.4, .35), (.45, .65, 8, 1.6, .38), (.05, .7, 3, 1.2, .3)]
    for i, (x, y, tilt, h, r) in enumerate(spec):
        lathe(m, P(cols[i], "SP", .1), [(r, 0), (r, h * .72), (0, h)], loc=(x, y, -.2), rot=(tilt, tilt * .6, 0), seg=6, part="Crystal" + str(i))
    sphere(m, P("FFFFFF", "NE"), (0, -.4, 1.2), .28, part="Glow")
    rock(m, P("E9DDF5"), (0, 0, -.35), (1.4, 1.1, .45), seed=4, part="Base")
    return m
BUILDERS = [B_BlossomPetal, B_PaperFan, B_JadeTeacup, B_GoldenKoiStatue, B_EternalSakura, B_GummyDrop, B_SwirlLollipop, B_GoldenBonbon, B_ChocolateCrown, B_RainbowCrystal]
