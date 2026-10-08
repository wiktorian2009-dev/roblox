import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

from w2lib import *
GOLD, GOLD_D = P("FFD25A", "ME"), P("E0A830", "ME")
CYN, PNK, VIO_N, STARW = P("7FE9FF", "NE"), P("FF8AD8", "NE"), P("A98BFF", "NE"), P("FFF6C8", "NE")
def star(r1, r2): return [(math.cos(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2), math.sin(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2)) for i in range(10)]
def B_StardustJar():
    m = Model("StardustJar")
    lathe(m, P("D8F4FF", "GL", .45), [(0, 0), (1.2, 0), (1.4, .4), (1.4, 2.4), (.9, 2.9), (.8, 3.3), (0, 3.3)], seg=24, part="Glass")
    lathe(m, VIO_N, [(0, .1), (1.25, .1), (1.3, 1.6), (0, 1.6)], seg=20, part="Dust")
    for k in range(6): sphere(m, [STARW, CYN, PNK][k % 3], (math.cos(k) * .7, math.sin(k) * .7, 1.9 + (k % 3) * .3), .14, part="Sparkles")
    cyl(m, GOLD, (0, 0, 3.2), r=.95, h=.5, seg=20, part="Lid"); torus(m, P("FF8AD8"), (0, 0, 2.95), R=.9, r=.08, seg=20, rseg=4, part="Ribbon")
    return m
def B_Meteorite():
    m = Model("Meteorite")
    blob(m, P("5A4E8C"), (0, 0, 0), rad=1.6, n=4, seed=8, flat=.85, seg=14, rings=9, part="Rock")
    for k in range(5): sphere(m, P("3E3466"), (math.cos(k * 1.3) * 1.2, -1.0, math.sin(k * 1.3) * 1.0), .3, scl=(1, .35, 1), part="Craters")
    for k in range(4): sphere(m, [CYN, PNK][k % 2], (math.cos(k * 1.7) * 1.4, math.sin(k * 1.7) * 1.2, .9), .18, part="Glints")
    for k in range(3): sphere(m, P("FFB060", "NE"), (0, 1.4 + k * .6, .2 + k * .2), .5 - k * .12, part="Trail")
    return m
def B_MoonCrystal():
    m = Model("MoonCrystal")
    lathe(m, P("CBB8FF"), [(.8, 0), (1.1, .5), (1.0, 3.0), (0, 4.2)], seg=6, part="Crystal")
    lathe(m, P("8FE6FF"), [(.5, 0), (.65, .3), (.6, 1.8), (0, 2.6)], loc=(1.1, .2, 0), rot=(0, 18, 0), seg=6, part="Side")
    moon = [(math.cos(math.radians(-120 + 240 * i / 12)) * .9, math.sin(math.radians(-120 + 240 * i / 12)) * .9) for i in range(13)] + [(math.cos(math.radians(120 - 240 * i / 12)) * .72 + .32, math.sin(math.radians(120 - 240 * i / 12)) * .72) for i in range(13)]
    prism(m, GOLD, moon, .12, loc=(0, -1.05, 2.0), rot=(90, 0, 90), part="Moon")
    return m
def B_GoldenAstrolabe():
    m = Model("GoldenAstrolabe")
    for k, (R, rot) in enumerate(((1.6, (90, 0, 0)), (1.35, (90, 0, 55)), (1.1, (90, 0, -55)))): torus(m, GOLD if k % 2 == 0 else GOLD_D, (0, 0, 0), R=R, r=.1, rot=rot, seg=32, rseg=6, part="Rings" + str(k % 2))
    sphere(m, VIO_N, (0, 0, 0), .45, part="Core")
    prism(m, STARW, star(.6, .26), .08, loc=(0, -.1, 2.1), rot=(90, 0, 0), part="Star")
    cyl(m, GOLD_D, (0, 0, -2.4), r=.7, h=.3, seg=16, part="Stand"); cyl(m, GOLD, (0, 0, -2.1), r=.08, h=.6, seg=6, part="Stand")
    return m
def B_GalaxyHeart():
    m = Model("GalaxyHeart")
    prism(m, P("6A3FD8"), heart_poly(1.5), .9, loc=(0, .45, 0), rot=(90, 0, 0), part="Heart")
    for k in range(4):
        pts = [(math.cos(k * 1.57 + t * .5) * (.2 + t * .35), -.5, math.sin(k * 1.57 + t * .5) * (.2 + t * .35)) for t in range(5)]
        tube(m, [CYN, PNK][k % 2], pts, r=.07, seg=5, smooth=3, part="Swirl" + str(k % 2))
    for k in range(7): sphere(m, STARW, (math.cos(k * .9) * 1.0, -.52, math.sin(k * .9) * .9), .08, part="Stars")
    torus(m, GOLD, (0, 0, 0), R=2.0, r=.08, rot=(70, 0, 20), seg=32, rseg=4, part="Ring")
    return m
BUILDERS = [B_StardustJar, B_Meteorite, B_MoonCrystal, B_GoldenAstrolabe, B_GalaxyHeart]
