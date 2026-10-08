# travel.py - lobby TRAVEL teleporter pad (Claude, 2026-10-05). Low-poly icy pad: octagonal stone base with two steps, frosted ice top,
# glowing rune circle, a soft floating icy ring, four crystal pillars with snow caps and a small sign board (the readable "TRAVEL"
# label is a SurfaceGui added in Studio). Origin = floor-level centre; front (steps, sign) = Blender -Y = Roblox -Z.
import math, random, sys
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\W1Remaster20261005")
from w1lib import *

STONE = "8EA2B8"; STONE2 = "72859C"; ICETOP = "DDF3FF"; RUNE = "6FE3FF"; RING = "BDF4FF"; CRYS = "9AD8FF"; CRYS2 = "6EB8F0"; POST = "4A5A72"; BOARD = "2C4A78"


def octa(r, rot=22.5):
    return [(r * math.cos(math.radians(rot + 45 * i)), r * math.sin(math.radians(rot + 45 * i))) for i in range(8)]


def T_TravelPad(m):
    """Lobby teleporter (~15 wide, ring at 3.2): walk-on pad, prompt at the centre."""
    rnd = random.Random(7)
    prism(m, P(STONE2), octa(7.6), 0.55, loc=(0, 0, 0), part="Base", bev=0.12)
    prism(m, P(STONE), octa(7.0), 0.45, loc=(0, 0, 0.55), part="Base2", bev=0.1)
    cyl(m, P(ICETOP), (0, 0, 0.98), r=6.0, h=0.14, seg=24, part="IceTop", bev=0.04)
    torus(m, P(RUNE, "NE"), (0, 0, 1.14), R=4.7, r=0.13, seg=32, rseg=4, part="Rune", sq=0.5)
    torus(m, P(RUNE, "NE"), (0, 0, 1.14), R=2.2, r=0.1, seg=20, rseg=4, part="Rune", sq=0.5)
    for i in range(6):  # rune ticks between the circles
        a = math.radians(60 * i + 15)
        bx(m, "Rune", RUNE, math.cos(a) * 3.1 - 0.12, math.cos(a) * 3.1 + 0.12, math.sin(a) * 3.1 - 0.5, math.sin(a) * 3.1 + 0.5, 1.1, 1.18, r=0.03, mat="NE", rot=(0, 0, 60 * i + 15))
    torus(m, P(RING, "NE", t=0.35), (0, 0, 3.3), R=5.4, r=0.32, seg=36, rseg=8, part="Ring")
    for k in range(4):  # crystal pillars on the diagonals
        a = math.radians(45 + 90 * k)
        x, y = math.cos(a) * 6.3, math.sin(a) * 6.3
        prism(m, P(STONE2), octa(0.95), 0.5, loc=(x, y, 1.0), part="PillarFoot", bev=0.08)
        lathe(m, P(CRYS if k % 2 == 0 else CRYS2), [(0.62, 1.45), (0.66, 3.6), (0.01, 5.3)], seg=6, loc=(x, y, 0), part="Crystal")
        lathe(m, P(SNOW), [(0.5, 4.3), (0.25, 4.9), (0.01, 5.35)], seg=6, loc=(x, y, 0.02), part="Snow")
        lathe(m, P(CRYS2), [(0.32, 1.45), (0.3, 2.4), (0.01, 3.1)], seg=5, loc=(x + 0.75 * math.cos(a + 0.9), y + 0.75 * math.sin(a + 0.9), 0), part="Crystal")
    # two front steps (Blender -Y = front)
    bx(m, "Step", STONE, -2.4, 2.4, -8.5, -7.3, 0, 0.35, r=0.08)
    bx(m, "Step", STONE2, -2.0, 2.0, -9.3, -8.4, 0, 0.18, r=0.06)
    # sign board on two posts, front-left, facing front
    for sx in (-6.9, -4.3):
        cyl(m, P(POST), (sx, -8.4, 0), r=0.16, h=3.6, seg=8, part="Post")
    bx(m, "Board", BOARD, -7.3, -3.9, -8.62, -8.3, 2.2, 3.5, r=0.12)
    bx(m, "Snow", SNOW, -7.4, -3.8, -8.7, -8.2, 3.5, 3.72, r=0.1)
    for k in range(5):  # snow drifts around the base
        a = rnd.uniform(0, 6.28)
        if math.sin(a) < -0.55: continue  # keep the front clear
        drift(m, math.cos(a) * 7.8, math.sin(a) * 7.8, 0.05, 1.5, rnd)


BUILDERS = {"T_TravelPad": T_TravelPad}
