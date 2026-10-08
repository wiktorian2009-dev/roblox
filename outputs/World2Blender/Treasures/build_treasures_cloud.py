import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

from w2lib import *
GOLD, GOLD_D, WH, INK = P("FFD25A", "ME"), P("E0A830", "ME"), P("F7F9FF"), P("2A2433")
RB = [P("FF6B6B"), P("FFA94D"), P("FFE066"), P("69DB7C"), P("4DABF7"), P("748FFC"), P("B197FC")]
def star(r1, r2): return [(math.cos(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2), math.sin(math.radians(90 + 36 * i)) * (r1 if i % 2 == 0 else r2)) for i in range(10)]
def B_CloudPuff():
    m = Model("CloudPuff")
    for k, (x, z, r) in enumerate([(0, 0, 1.2), (1.1, -.2, .9), (-1.1, -.15, .95), (.5, .6, .8), (-.5, .55, .75)]): sphere(m, [WH, P("E2DBFF")][k % 2], (x, 0, z), r, seg=16, rings=10, part="Puff" + str(k % 2))
    for s in (-1, 1): sphere(m, INK, (s * .35, -1.1, .1), .13, scl=(.8, .4, 1.1), part="Eyes")
    sphere(m, P("FF9BB5"), (0, -1.15, -.25), .12, scl=(1.6, .4, .6), part="Smile")
    return m
def B_SilverFeather():
    m = Model("SilverFeather")
    tube(m, P("C9D3E6", "ME"), [(0, 0, -1.8), (.1, 0, 0), (-.05, 0, 1.8)], r=.06, seg=6, smooth=3, part="Quill")
    for k in range(9):
        t = -1.3 + k * .32; w = .9 * math.sin((k + 1) / 10 * math.pi)
        for s in (-1, 1): rbox(m, P("E8EEF8", "ME"), (s * w * .5, 0, t), (w, .05, .3), r=.1, rot=(0, s * 25, 0), part="Vanes")
    return m
def B_RainbowPrism():
    m = Model("RainbowPrism")
    prism(m, P("E9F7FF", "GL", .25), [(-1.3, -1.0), (1.3, -1.0), (0, 1.25)], 1.4, loc=(0, -.7, 0), rot=(90, 0, 0), part="Glass")
    for i, c in enumerate(RB): rbox(m, c, (1.9 + i * .0, 0, .6 - i * .22), (1.6, .1, .18), r=.05, rot=(0, -12, 0), part="Beam" + str(i))
    rbox(m, P("FFFFFF", "NE"), (-2.0, 0, .2), (1.4, .1, .14), r=.05, rot=(0, 15, 0), part="Light")
    return m
def B_GoldenHarp():
    m = Model("GoldenHarp")
    tube(m, GOLD, [(-1.2, 0, -1.6), (-1.0, 0, .5), (-.2, 0, 1.7), (1.0, 0, 1.4)], r=.16, seg=10, smooth=3, part="Frame")
    tube(m, GOLD_D, [(-1.2, 0, -1.6), (.2, 0, -1.4), (1.0, 0, -.6), (1.0, 0, 1.4)], r=.13, seg=10, smooth=3, part="Frame2")
    for k in range(6):
        x = -.9 + k * .35; tube(m, P("FFF3C4"), [(x, 0, -1.45 + k * .12), (x, 0, 1.1 + k * .05)], r=.025, seg=4, smooth=1, part="Strings")
    for s in (-1, 1): prism(m, WH, [(0, 0), (.8, .3), (.9, .9), (.4, .7)], .06, loc=(-1.25, s * .05, .6), rot=(90, 0, 180), part="Wing")
    return m
def B_SunCrown():
    m = Model("SunCrown")
    torus(m, GOLD, (0, 0, 0), R=1.4, r=.22, seg=32, rseg=8, part="Band")
    for k in range(10):
        a = 2 * math.pi * k / 10; h = 1.1 if k % 2 == 0 else .7
        prism(m, GOLD_D if k % 2 else GOLD, [(-.25, 0), (.25, 0), (0, h)], .12, loc=(math.cos(a) * 1.45, math.sin(a) * 1.45, .1), rot=(90, 0, math.degrees(a) + 90), part="Rays")
    for k in range(5):
        a = 2 * math.pi * k / 5; sphere(m, RB[k * 1 % 7], (math.cos(a) * 1.55, math.sin(a) * 1.55, 0), .2, part="Gems")
    cyl(m, P("FFE680", "NE"), (0, -1.4, .05), r=.45, h=.1, seg=16, rot=(90, 0, 0), part="SunGem")
    return m
BUILDERS = [B_CloudPuff, B_SilverFeather, B_RainbowPrism, B_GoldenHarp, B_SunCrown]
