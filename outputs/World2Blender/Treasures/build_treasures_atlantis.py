import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

from w2lib import *
GOLD, GOLD_D, INK = P("FFC94A", "ME"), P("E0A325", "ME"), P("2A2433")
def B_SpiralSeashell():
    m = Model("SpiralSeashell")
    for i in range(14):
        t = i / 13; a = t * 4.2 * math.pi; r = 1.25 * (1 - t) + .15
        sphere(m, P("FFD6B0") if i % 2 else P("FFE9D2"), (math.cos(a) * .55 * (1 - t), math.sin(a) * .55 * (1 - t), t * 2.6), r, scl=(1, 1, .8), part="Whorls" + str(i % 2))
    lathe(m, P("FF9E8A"), [(.0, -.3), (.9, -.1), (1.15, .5), (.8, 1.0), (.0, 1.1)], loc=(.75, -.55, .2), rot=(0, 25, 0), seg=14, sy=.55, part="Lip")
    return m
def B_StarfishCharm():
    m = Model("StarfishCharm")
    star = [(math.cos(math.radians(90 + 36 * i)) * (1.9 if i % 2 == 0 else .75), math.sin(math.radians(90 + 36 * i)) * (1.9 if i % 2 == 0 else .75)) for i in range(10)]
    prism(m, P("FF8A5C"), star, .55, loc=(0, .28, 0), rot=(90, 0, 0), bev=.2, part="Star")
    for i in range(5):
        a = math.radians(90 + 72 * i)
        for k in (1, 2): sphere(m, P("FFD0A0"), (math.cos(a) * .55 * k, -.32, math.sin(a) * .55 * k), .13, part="Dots")
    torus(m, GOLD, (0, 0, 2.15), R=.35, r=.1, rot=(90, 0, 0), seg=16, rseg=6, part="Ring")
    return m
def B_PearlNecklace():
    m = Model("PearlNecklace")
    for i in range(22):
        a = math.radians(200 + 140 * i / 21 * 1.0) if False else 2 * math.pi * i / 22
        sphere(m, P("FFF8EE"), (math.cos(a) * 1.8, 0, math.sin(a) * 1.3 + .2), .26, part="Pearls")
    lathe(m, P("FFB8D6"), [(0, 0), (.55, .25), (.7, .75), (.5, 1.25), (0, 1.45)], loc=(0, -.1, -2.25), seg=18, part="Pendant")
    torus(m, GOLD, (0, -.05, -.75), R=.25, r=.08, rot=(90, 0, 0), seg=14, rseg=6, part="Clasp")
    return m
def B_GoldenTrident():
    m = Model("GoldenTrident")
    cyl(m, GOLD, (0, 0, -2.6), r=.16, h=4.4, seg=10, part="Shaft")
    tube(m, GOLD, [(-1.0, 0, 2.3), (-1.0, 0, 1.6), (0, 0, 1.4), (1.0, 0, 1.6), (1.0, 0, 2.3)], r=.15, seg=8, smooth=3, part="Fork")
    for x in (-1.0, 0, 1.0): lathe(m, GOLD_D, [(.22, 0), (0, .75)], loc=(x, 0, 2.25 + (.2 if x == 0 else 0)), seg=8, part="Prongs")
    sphere(m, P("3FD0D4", "NE"), (0, -.12, 1.55), .32, part="Gem")
    torus(m, P("3FD0D4"), (0, 0, -.2), R=.25, r=.08, seg=14, rseg=6, part="Band")
    return m
def B_AtlanteanCrystal():
    m = Model("AtlanteanCrystal")
    lathe(m, P("7FF4F0", "SP", .1), [(.0, -1.6), (.85, -.8), (.85, .9), (.0, 2.0)], seg=6, part="Crystal")
    sphere(m, P("E9FFFF", "NE"), (0, -.5, .2), .4, part="Core")
    torus(m, GOLD, (0, 0, -.9), R=1.05, r=.16, seg=24, rseg=6, part="Setting")
    for i in range(6):
        a = 2 * math.pi * i / 6
        sphere(m, P("FFF8EE"), (math.cos(a) * 1.05, math.sin(a) * 1.05, -.9), .18, part="Pearls")
    return m
BUILDERS = [B_SpiralSeashell, B_StarfishCharm, B_PearlNecklace, B_GoldenTrident, B_AtlanteanCrystal]
