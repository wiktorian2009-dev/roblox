# paidgear.py - Aurora Wheels, the Premium Wheels game-pass gear (task 8, Claude 2026-10-05).
# Same contract as every gear (outputs/PlowExpansion20261005/parts/gears.py): origin = chassis ground centre, ground contact z = 0,
# wheel centres under the fenders (front y -2.3, rear y +2.5), assemblies between |x| 2.63 and 3.6, tyre tops <= 1.97,
# so the set fits every body (the bodies keep |x| > 2.6 below z 1.9 clear).
import math, sys
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\PlowExpansion20261005\parts")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
from partlib import *
from w2lib import P, torus, cyl

FY, RY = -2.3, 2.5
WHEELS = [(sx, y) for sx in (-1, 1) for y in (FY, RY)]
RUB = "23262E"; ICE = "D6ECFF"; ICE2 = "9FD3F5"; AUR1 = "6FFFD0"; AUR2 = "B48CFF"; DARKS = "2A2D34"


def GearAuroraWheels(m):
    """Aurora Wheels: chunky snow tyres, icy alloy six-spoke hubs, a soft aurora ring on each sidewall (teal front, violet rear)."""
    R, w, xc = 0.88, 0.94, 3.08
    for sx, y in WHEELS:
        c = (sx * xc, y, R + 0.02)
        tire(m, P(RUB), c, R, w, seg=18, bulge=0.2)
        knobs(m, P("1B1D24"), c, R - 0.02, w, n=16, rows=2, size=(None, 0.22, 0.12), part="Knobs", r=0.0)
        rim_x = xc + w / 2 - 0.03
        disc(m, P("5E7FA8", "ME"), (sx * rim_x, y, R + 0.02), 0.58, 0.08, axis=(sx, 0, 0), seg=18, bev=0.02, part="Recess")
        torus(m, P(ICE, "ME"), (sx * (rim_x + 0.09), y, R + 0.02), R=0.56, r=0.07, seg=22, rseg=5, rot=(0, 90, 0), part="Rim")
        for k in range(6):  # six raised icy spokes
            a = 2 * math.pi * k / 6 + math.pi / 6
            beam(m, P(ICE, "ME"), (sx * (rim_x + 0.12), y, R + 0.02), (sx * (rim_x + 0.12), y + 0.52 * math.cos(a), R + 0.02 + 0.52 * math.sin(a)), w=0.14, h=0.09, r=0.03, part="Spokes")
        torus(m, P(AUR1 if y < 0 else AUR2, "NE"), (sx * (rim_x + 0.07), y, R + 0.02), R=0.68, r=0.055, seg=26, rseg=4, rot=(0, 90, 0), part="Aurora")
        disc(m, P(ICE2, "ME"), (sx * (rim_x + 0.14), y, R + 0.02), 0.19, 0.08, axis=(sx, 0, 0), seg=10, bev=0.02, part="Cap")
        rod(m, P(DARKS), (sx * 2.15, y, R), (sx * xc, y, R), r=0.12, seg=8, part="Axle")


BUILDERS = {"GearAuroraWheels": GearAuroraWheels}
