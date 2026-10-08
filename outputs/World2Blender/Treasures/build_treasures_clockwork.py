import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random

from w2lib import *
GOLD, GOLD_D, BR, TEAL, WHITE, INK = P("FFC94A", "ME"), P("E0A325", "ME"), P("D9A54A", "ME"), P("3FBFB4"), P("FFFFFF"), P("2A2433")
def gearz(m, pc, R, thick, teeth, z=0, part="Gear"):
    cyl(m, pc, (0, 0, z - thick / 2), r=R * .84, h=thick, seg=teeth * 2, part=part)
    for i in range(teeth):
        a = 2 * math.pi * i / teeth
        rbox(m, pc, (math.cos(a) * R * .93, math.sin(a) * R * .93, z), (R * .2, 2 * math.pi * R / teeth * .5, thick), r=0, rot=(0, 0, math.degrees(a)), part=part)
def B_BrassCog():
    m = Model("BrassCog"); gearz(m, BR, 1.6, .5, 12)
    cyl(m, TEAL, (0, 0, -.35), r=.4, h=.7, seg=16, part="Hub")
    for i in range(4):
        a = 2 * math.pi * (i + .5) / 4; cyl(m, INK, (math.cos(a) * .85, math.sin(a) * .85, .24), r=.25, h=.03, seg=12, part="Holes")
    return m
def B_PocketWatch():
    m = Model("PocketWatch")
    cyl(m, GOLD, (0, .2, 0), r=1.5, h=.4, seg=32, rot=(90, 0, 0), part="Case"); cyl(m, WHITE, (0, -.22, 0), r=1.3, h=.06, seg=32, rot=(90, 0, 0), part="Dial")
    for i in range(12):
        a = 2 * math.pi * i / 12; sphere(m, INK, (math.cos(a) * 1.05, -.27, math.sin(a) * 1.05), .07, part="Marks")
    rbox(m, INK, (0, -.3, .35), (.08, .04, .75), r=.02, part="Hands"); rbox(m, INK, (.25, -.3, 0), (.55, .04, .07), r=.02, part="Hands")
    cyl(m, GOLD_D, (0, 0, 1.5), r=.2, h=.35, seg=12, part="Crown"); torus(m, GOLD, (0, 0, 2.05), R=.3, r=.08, rot=(90, 0, 0), seg=16, rseg=6, part="Ring")
    return m
def B_SteamWhistle():
    m = Model("SteamWhistle")
    cyl(m, BR, (0, 0, 0), r=.55, h=2.6, seg=20, part="Pipe"); lathe(m, GOLD, [(.55, 2.6), (.8, 2.9), (.8, 3.2), (.3, 3.5), (0, 3.6)], seg=20, part="Top")
    for z in (.6, 1.6): torus(m, TEAL, (0, 0, z), R=.58, r=.08, seg=20, rseg=6, part="Bands")
    tube(m, GOLD_D, [(.55, 0, 1.2), (1.2, 0, 1.2), (1.4, 0, 1.6)], r=.1, seg=8, smooth=2, part="Lever")
    for k, (x, z, r) in enumerate([(.1, 4.0, .35), (-.25, 4.5, .45), (.2, 5.1, .55)]): sphere(m, P("FFFFFF", "SP", .2), (x, 0, z), r, part="Steam")
    return m
def B_Gyroscope():
    m = Model("Gyroscope")
    torus(m, GOLD, (0, 0, 1.8), R=1.6, r=.12, rot=(90, 0, 0), seg=32, rseg=8, part="Rings"); torus(m, GOLD_D, (0, 0, 1.8), R=1.35, r=.12, rot=(0, 90, 0), seg=32, rseg=8, part="Rings")
    torus(m, GOLD, (0, 0, 1.8), R=1.1, r=.12, rot=(0, 0, 0), seg=32, rseg=8, part="Rings2")
    sphere(m, TEAL, (0, 0, 1.8), .45, part="Core"); cyl(m, GOLD_D, (0, 0, 0), r=.9, h=.25, seg=24, part="Stand"); cyl(m, GOLD_D, (0, 0, .25), r=.1, h=.5, seg=8, part="Stand")
    return m
def B_Hourglass():
    m = Model("Hourglass")
    for z in (0, 3.6): cyl(m, GOLD, (0, 0, z), r=1.3, h=.3, seg=6, part="Caps")
    for k in range(3):
        a = 2 * math.pi * k / 3 + .5; cyl(m, GOLD_D, (math.cos(a) * 1.05, math.sin(a) * 1.05, .3), r=.1, h=3.3, seg=8, part="Posts")
    lathe(m, P("CFF6FF", "GL", .35), [(.95, .3), (.8, 1.2), (.15, 1.95), (.8, 2.7), (.95, 3.6)], seg=24, part="Glass")
    lathe(m, P("B48CFF", "NE"), [(.0, .32), (.8, .35), (.55, 1.0), (.15, 1.5), (0, 1.6)], seg=20, part="Sand")
    lathe(m, P("B48CFF", "NE"), [(.0, 2.55), (.42, 2.6), (.75, 3.2), (0, 3.35)], seg=20, part="SandTop")
    return m
BUILDERS = [B_BrassCog, B_PocketWatch, B_SteamWhistle, B_Gyroscope, B_Hourglass]
