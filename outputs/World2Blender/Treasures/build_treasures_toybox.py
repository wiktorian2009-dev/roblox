import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

from w2lib import *
GOLD, GOLD_D = P("FFC94A", "ME"), P("E0A325", "ME")
def B_WoodenBlock():
    m = Model("WoodenBlock")
    rbox(m, P("E3A866"), (0, 0, 0), (2.6, 2.6, 2.6), r=.35, part="Block")
    star = [(math.cos(math.radians(90 + 36 * i)) * (.85 if i % 2 == 0 else .38), math.sin(math.radians(90 + 36 * i)) * (.85 if i % 2 == 0 else .38)) for i in range(10)]
    prism(m, P("FF4B4B"), star, .12, loc=(0, -1.32, 0), rot=(90, 0, 0), part="Star")
    prism(m, P("3E8BFF"), heart_poly(.55), .12, loc=(-1.32, 0, -.1), rot=(90, 0, -90), part="Heart")
    rbox(m, P("44C767"), (0, 0, 1.32), (1.2, 1.2, .12), r=.3, part="Square")
    return m
def B_SpinningTopT():
    m = Model("SpinningTopT")
    lathe(m, P("FF4B4B"), [(.0, 0), (.35, .5), (1.5, 1.6), (1.7, 1.9), (1.2, 2.3), (.4, 2.5), (0.01, 2.5)], seg=28, part="Body")
    torus(m, P("FFD23F"), (0, 0, 1.85), R=1.62, r=.16, seg=28, rseg=6, part="Stripe")
    torus(m, P("3E8BFF"), (0, 0, 1.3), R=1.25, r=.12, seg=28, rseg=6, part="Stripe2")
    cyl(m, P("D9A066"), (0, 0, 2.5), r=.18, h=1.2, seg=8, part="Handle"); sphere(m, P("3E8BFF"), (0, 0, 3.8), .3, part="Knob")
    return m
def B_WindupKey():
    m = Model("WindupKey")
    cyl(m, GOLD, (0, 0, -1.8), r=.22, h=2.6, seg=10, part="Shaft")
    for s in (-1, 1): torus(m, GOLD, (s * .75, 0, 1.15), R=.65, r=.2, rot=(90, 0, 0), seg=20, rseg=8, part="Loops")
    sphere(m, GOLD_D, (0, 0, .9), .35, part="Hub")
    rbox(m, GOLD_D, (0, 0, -1.9), (.7, .25, .5), r=.08, part="Bit")
    return m
def B_RockingHorse():
    m = Model("RockingHorse")
    torus(m, GOLD_D, (0, 0, 1.2), R=2.4, r=.18, arc=110, rot=(90, 0, 215), seg=20, rseg=6, part="Rocker")
    torus(m, GOLD_D, (0, .55, 1.2), R=2.4, r=.18, arc=110, rot=(90, 0, 215), seg=20, rseg=6, part="Rocker")
    sphere(m, GOLD, (0, .27, 1.55), .9, scl=(1.6, .7, .75), part="Body")
    tube(m, GOLD, [(-1.1, .27, 1.8), (-1.5, .27, 2.6)], r=.33, seg=10, smooth=1, part="Body")
    sphere(m, GOLD, (-1.75, .27, 2.85), .45, scl=(1.4, .8, .9), part="Body")
    for x in (-.9, .9):
        for y in (0, .55): tube(m, GOLD, [(x, y, 1.2), (x * 1.05, y, .45)], r=.12, seg=6, smooth=1, part="Legs")
    for k in range(4): sphere(m, P("FF4B4B"), (-1.45 + k * .1, .27, 2.6 + k * .15), .14, scl=(1, 1, 1.4), part="Mane")
    tube(m, P("FF4B4B"), [(1.4, .27, 1.7), (1.9, .27, 2.0), (2.1, .27, 1.6)], r=.12, seg=6, smooth=3, part="Tail")
    sphere(m, P("2A2433"), (-2.15, .0, 2.95), .07, part="Eye")
    return m
def B_MusicBox():
    m = Model("MusicBox")
    rbox(m, P("9C6BFF"), (0, 0, 0), (3.0, 2.2, 1.4), r=.2, base=True, part="Box")
    rbox(m, P("FF9AD5"), (0, 0, 1.4), (3.1, 2.3, .2), r=.08, base=True, part="Trim")
    for k, c in enumerate(["FF4B4B", "FF9A3C", "FFD23F", "44C767", "3E8BFF"]):
        rbox(m, P(c), (-1.1 + k * .55, -1.12, .7), (.42, .1, .9), r=.05, part="Bars" + str(k))
    cyl(m, GOLD, (0, 0, 1.6), r=.08, h=1.0, seg=6, part="Pole")
    lathe(m, P("FFFFFF"), [(.05, 0), (.5, .1), (.15, .45), (0, .9)], loc=(0, 0, 2.6), seg=14, part="Dancer")
    sphere(m, P("FFE38A"), (0, 0, 3.6), .2, part="Dancer")
    for k in range(3):
        prism(m, P("FFD23F", "NE"), [(0, .3), (.08, .08), (.3, 0), (.08, -.08), (0, -.3), (-.08, -.08), (-.3, 0), (-.08, .08)], .06, loc=(-1.2 + k * 1.2, -.2, 2.6 + (k % 2) * .5), rot=(90, 0, 0), part="Sparkles")
    return m
BUILDERS = [B_WoodenBlock, B_SpinningTopT, B_WindupKey, B_RockingHorse, B_MusicBox]
