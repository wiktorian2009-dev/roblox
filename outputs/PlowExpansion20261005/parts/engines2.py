# engines2.py - the 15 rebalance engines (2026-10-05). Same contract as engines.py: origin = bottom-centre on the rear deck,
# front = -Y (driver side); envelope x +-1.75, y -0.5..+1.4, z 0.05..3.4; detail on the rear (+Y) face and top.
import math
from mathutils import Vector
from partlib import *
from engines import YC, base, ring_band, fan, fins, capsule


def EngineCauldron(m, c):
    p = c["palette"]
    base(m, P(p[0]), 2.8, 1.7)
    lathe(m, P("2A2236"), [(0.95, 0.27), (1.25, 0.6), (1.35, 1.2), (1.2, 1.8), (1.05, 1.95)], loc=(0, YC, 0), seg=16, part="Pot")
    torus(m, P("3B2A55"), (0, YC, 1.95), R=1.08, r=0.12, seg=18, rseg=6, part="Rim")
    disc(m, P(p[3], "NE"), (0, YC, 1.86), 0.98, 0.08, axis=(0, 0, 1), seg=16, part="Brew")
    for (x, y, r) in ((0.3, 0.2, 0.22), (-0.35, -0.1, 0.18), (0.05, -0.35, 0.14)):
        sphere(m, P(p[3], "NE"), (x, YC + y, 2.02), r, seg=8, rings=5, part="Bubbles")
    for sx in (-1, 1):   # twin bone pipes
        tube(m, P(p[2]), [(sx * 0.9, YC + 0.6, 1.3), (sx * 1.2, YC + 1.0, 1.7), (sx * 1.25, YC + 1.05, 2.6)], r=0.14, seg=8, part="Bones", smooth=3)
        sphere(m, P(p[2]), (sx * 1.25, YC + 1.05, 2.7), 0.2, seg=8, rings=5, part="Bones")
    for k in range(3): rod(m, P("1C1428"), (-0.9 + k * 0.9, YC + 0.9, 0.3), (-0.95 + k * 0.95, YC + 1.1, 0.05), r=0.09, seg=6, part="Legs")


def EngineShardSpinner(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.6, 1.6)
    rbox(m, P("4A5470"), (0, YC, 0.27), (2.2, 1.3, 0.9), r=0.16, bseg=2, part="Block", base=True)
    ring_band(m, P(p[3]), (0, YC + 0.75, 1.65), 0.95, 1.15, 0.35, axis=(0, 1, 0), part="Shroud")
    fan(m, P(p[0], "GL"), (0, YC + 0.9, 1.65), 0.9, n=8, axis=(0, 1, 0), pitch=30, part="Shards")
    disc(m, P(p[1], "NE"), (0, YC + 1.05, 1.65), 0.22, 0.12, axis=(0, 1, 0), seg=10, part="Hub")
    for sx in (-1, 1): crystal(m, P(p[0]), (sx * 0.85, YC - 0.2, 1.1), (sx * 0.95, YC - 0.25, 2.4), 0.2, seg=6, part="Spires")


def EngineQuartzPiston(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.8, 1.6)
    rbox(m, P("5B6378"), (0, YC, 0.27), (2.5, 1.3, 0.7), r=0.12, bseg=2, part="Block", base=True)
    for k, x in enumerate((-0.8, 0.0, 0.8)):   # three clear quartz piston columns
        h = 1.3 + 0.25 * (k % 2)
        cyl(m, P("E8F7FF", "GL"), (x, YC + 0.05, 0.95), r=0.33, h=h, seg=8, part="Quartz")
        cyl(m, P(p[0], "NE"), (x, YC + 0.05, 1.05), r=0.18, h=h - 0.25, seg=6, part="Glow")
        disc(m, P(STEEL, "ME"), (x, YC + 0.05, 0.95 + h), 0.38, 0.14, axis=(0, 0, 1), seg=10, part="Caps")
    tube(m, P(STEEL, "ME"), [(-1.1, YC + 0.65, 0.8), (-1.2, YC + 1.0, 1.4), (-1.15, YC + 1.05, 2.2)], r=0.1, seg=8, part="Caps", smooth=2)


def EngineCartridge(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.0, 1.7)
    for k in range(3):   # stacked game cartridges
        z = 0.27 + k * 0.62
        box(m, P([p[1], p[0], "9B6BFF"][k]), (0, YC + 0.05 * k, z + 0.28), (2.4 - k * 0.3, 1.2, 0.52), r=0.06, part="Cart%d" % k)
        box(m, P("1E1E2E"), (0, YC + 0.65, z + 0.28), (1.6 - k * 0.3, 0.06, 0.32), r=0.02, part="Labels")
        for i in range(4): box(m, P(p[2], "NE"), (-0.6 + i * 0.4, YC + 0.68, z + 0.28), (0.18, 0.04, 0.18), r=0.0, part="Pixels")
    for sx in (-1, 1):
        for i in range(3): box(m, P(p[2]), (sx * (1.1 + 0.18 * i), YC + 0.9, 1.6 + 0.3 * i), (0.25, 0.25, 0.25), r=0.0, part="Vents")


def EngineTotem(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.6, 1.6)
    for k in range(3):   # totem pole of carved faces
        z = 0.27 + k * 0.72
        rbox(m, P(["8A5A33", "A86E3E", "7A4C2A"][k]), (0, YC, z + 0.34), (1.6 - k * 0.15, 1.2, 0.68), r=0.12, part="Totem", base=False)
        for sx in (-1, 1): box(m, P("1C1C1C"), (sx * 0.3, YC + 0.62, z + 0.52), (0.26, 0.05, 0.18), r=0.02, part="Eyes")
        box(m, P(p[2]), (0, YC + 0.63, z + 0.22), (0.7, 0.05, 0.12), r=0.02, part="Mouths")
    for k in range(6):   # leafy crown exhaust
        a = 2 * math.pi * k / 6
        flat(m, P(p[0]), leaf_poly(0.8, 0.4), 0.04, (0.25 * math.cos(a), YC + 0.25 * math.sin(a), 2.45), axis=(math.cos(a), math.sin(a), 0.0), spin=0, part="Leaves")
    for sx in (-1, 1): tube(m, P("C8A15A"), [(sx * 1.0, YC + 0.4, 0.4), (sx * 1.05, YC + 0.5, 2.0)], r=0.13, seg=8, part="Bamboo", smooth=1)


def EngineFrostPiston(m, c):
    p = c["palette"]
    base(m, P(p[1]), 2.6, 1.6)
    rbox(m, P("DCEFFF", "IC"), (0, YC, 0.27), (2.2, 1.3, 1.1), r=0.2, bseg=2, part="Block", base=True)
    fins(m, P(p[1], "ME"), (0, YC, 0.55), 1.0, 0.8, n=5, gap=0.17, axis=(0, 0, 1), part="Fins", seg=14)
    for sx in (-1, 1):
        cyl(m, P("BFE6FF", "IC"), (sx * 0.55, YC + 0.1, 1.37), r=0.32, h=0.8, seg=10, part="Pistons")
        disc(m, P(STEEL, "ME"), (sx * 0.55, YC + 0.1, 2.17), 0.36, 0.12, axis=(0, 0, 1), seg=10, part="Caps")
    for k in range(5): crystal(m, P("F4FBFF", "IC"), (-0.9 + k * 0.45, YC + 0.7, 1.35), (-0.9 + k * 0.45, YC + 0.72, 0.95), 0.08, seg=5, part="Icicles")


def EngineGlacierV6(m, c):
    p = c["palette"]
    base(m, P(p[1]), 3.1, 1.75)
    rbox(m, P("CFE9FF", "IC"), (0, YC, 0.27), (2.7, 1.4, 0.75), r=0.15, bseg=2, part="Case", base=True)
    for sx in (-1, 1):   # V6: two banks of three, leaning out
        for k in range(3):
            y = YC - 0.45 + k * 0.45
            rod(m, P("E8F7FF", "IC"), (sx * 0.4, y, 1.0), (sx * 0.9, y, 1.75), r=0.22, seg=8, part="Bank")
            rod(m, P(p[2], "ME"), (sx * 0.95, y, 1.8), (sx * 1.05, y + 0.1, 2.6 + 0.1 * k), r=0.09, seg=6, part="Stacks")
            sphere(m, P("FFFFFF"), (sx * 1.05, y + 0.1, 2.7 + 0.1 * k), 0.13, seg=6, rings=4, part="Frost")
    capsule(m, P(p[3]), (0, YC + 0.1, 1.3), 0.28, 1.2, axis=(0, 1, 0), part="Tank")


def EngineBonsai(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.6, 1.6)
    rbox(m, P("3A1F18"), (0, YC, 0.27), (2.2, 1.3, 0.85), r=0.18, bseg=2, part="Lacquer", base=True)
    box(m, P("D4AF37", "ME"), (0, YC + 0.66, 0.7), (1.8, 0.05, 0.12), r=0.02, part="Gold")
    disc(m, P("2A2A2A"), (0, YC, 1.12), 0.75, 0.25, axis=(0, 0, 1), seg=14, part="Pot")
    tube(m, P("6B4A2E"), [(0, YC, 1.3), (0.25, YC, 1.8), (-0.15, YC + 0.1, 2.3), (0.1, YC, 2.7)], r=0.13, r2=0.06, seg=7, part="Trunk", smooth=3)
    for (x, y, z, r) in ((0.45, 0.0, 2.2, 0.42), (-0.4, 0.15, 2.5, 0.38), (0.15, -0.1, 2.85, 0.34)):
        sphere(m, P(p[0]), (x, YC + y, z), r, scl=(1.3, 1.0, 0.6), seg=10, rings=6, part="Canopy")
    tube(m, P(STEEL, "ME"), [(0.9, YC + 0.6, 0.8), (1.1, YC + 0.9, 1.2), (1.1, YC + 0.95, 1.8)], r=0.1, seg=8, part="Pipe", smooth=2)


def EngineTaffyTwister(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.6, 1.6)
    rbox(m, P("FFF2F8"), (0, YC, 0.27), (2.0, 1.2, 0.8), r=0.2, bseg=2, part="Cowl", base=True)
    for k in range(6): box(m, P(p[0]), (-0.85 + k * 0.34, YC, 0.67), (0.12, 1.22, 0.82), r=0.02, part="Stripes")
    ring_band(m, P(p[1]), (0, YC + 0.65, 1.8), 0.85, 1.05, 0.3, axis=(0, 1, 0), part="Shroud")
    for k in range(3):   # twisting taffy-pull rotor arms
        a = 2 * math.pi * k / 3
        tube(m, P([p[0], "FFB3D1", p[2]][k]), [(0, YC + 0.8, 1.8), (0.4 * math.cos(a), YC + 0.85, 1.8 + 0.4 * math.sin(a)), (0.8 * math.cos(a + 0.6), YC + 0.9, 1.8 + 0.8 * math.sin(a + 0.6))], r=0.12, seg=7, part="Rotor", smooth=3)
    sphere(m, P(p[2]), (0, YC + 0.9, 1.8), 0.2, seg=8, rings=5, part="Hub")


def EngineCocoa(m, c):
    p = c["palette"]
    base(m, P("6B3E2E"), 3.0, 1.7)
    for i in range(3):   # chocolate-bar block
        for j in range(2):
            rbox(m, P("5A3220"), (-0.85 + i * 0.85, YC - 0.3 + j * 0.6, 0.27), (0.78, 0.55, 0.9), r=0.08, part="Bar", base=True)
    lathe(m, P("F2E3C2"), [(0.42, 0), (0.45, 0.6), (0.42, 0.7)], loc=(0.75, YC + 0.4, 1.17), seg=12, part="Mug")
    torus(m, P("F2E3C2"), (1.2, YC + 0.4, 1.5), R=0.22, r=0.06, seg=10, rseg=4, rot=(90, 0, 0), part="Mug")
    disc(m, P("7A4A2A"), (0.75, YC + 0.4, 1.8), 0.4, 0.05, axis=(0, 0, 1), seg=12, part="Cocoa")
    for k in range(3): sphere(m, P("FFFFFF"), (0.75 + 0.1 * k, YC + 0.4, 2.0 + 0.3 * k), 0.15 + 0.05 * k, seg=7, rings=4, part="Steam")
    tube(m, P(STEEL, "ME"), [(-1.0, YC + 0.6, 1.0), (-1.2, YC + 0.9, 1.5), (-1.2, YC + 0.95, 2.4)], r=0.13, seg=8, part="Stack", smooth=2)


def EnginePearlDiver(m, c):
    p = c["palette"]
    base(m, P(p[1]), 2.9, 1.7)
    rbox(m, P(p[0]), (0, YC, 0.27), (2.6, 1.4, 0.75), r=0.16, bseg=2, part="Case", base=True)
    for sx in (-1, 1):   # clam-shell cylinder heads holding pearls
        x = sx * 0.66
        cyl(m, P(p[1]), (x, YC + 0.1, 1.02), r=0.42, h=0.75, seg=12, part="Cyl")
        lathe(m, P("FF7A5C"), [(0.55, 0), (0.6, 0.15), (0.4, 0.45), (0.0, 0.5)], loc=(x, YC + 0.1, 1.77), seg=12, rib=(9, 0.08), part="Shells")
        sphere(m, P("FFF4E6", "NE"), (x, YC + 0.3, 1.95), 0.2, seg=10, rings=6, part="Pearls")
    tube(m, P("D4AF37", "ME"), [(0, YC + 0.7, 0.8), (0, YC + 1.05, 1.2), (0, YC + 1.1, 2.2)], r=0.12, seg=8, part="Snorkel", smooth=2)
    disc(m, P("D4AF37", "ME"), (0, YC + 1.1, 2.25), 0.2, 0.15, axis=(0, 0, 1), seg=10, part="Snorkel")


def EngineToyRocket(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.6, 1.6)
    lathe(m, P(p[0]), [(0.0, 0.0), (0.7, 0.05), (0.75, 1.2), (0.6, 1.9), (0.0, 2.5)], loc=(0, YC + 0.1, 0.27), seg=14, part="Rocket")
    for k in range(5): sphere(m, P(p[2]), (0.73 * math.cos(k * 1.3), YC + 0.1 + 0.73 * math.sin(k * 1.3), 0.6 + k * 0.25), 0.11, seg=6, rings=4, part="Dots")
    for k in range(3):
        a = 2 * math.pi * k / 3 + 0.5
        flat(m, P(p[1]), tri_poly(0.7, 0.9), 0.08, (0.7 * math.cos(a), YC + 0.1 + 0.7 * math.sin(a), 0.4), axis=(math.cos(a + math.pi / 2), math.sin(a + math.pi / 2), 0), part="Fins")
    lathe(m, P(STEEL, "ME"), [(0.35, 0), (0.5, 0.3), (0.55, 0.35)], loc=(0, YC + 1.05, 1.0), rot=(-90, 0, 0), seg=12, part="Nozzle")
    disc(m, P("FF8A3D", "NE"), (0, YC + 1.38, 1.0), 0.4, 0.06, axis=(0, 1, 0), seg=12, part="Flame")


def EngineEscapement(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.8, 1.7)
    for sx in (-1, 1): box(m, P(p[0], "ME"), (sx * 1.0, YC, 1.3), (0.15, 1.2, 2.1), r=0.04, part="Frame")
    flat(m, P(p[1], "ME"), gear_poly(16, 0.85, 0.7, 0.4), 0.12, (0, YC + 0.65, 1.5), axis=(0, 1, 0), part="Escapement")
    disc(m, P(p[2]), (0, YC + 0.7, 1.5), 0.25, 0.1, axis=(0, 1, 0), seg=10, part="Hub")
    helix(m, P(STEEL, "ME"), (0, YC - 0.1, 2.45), 0.38, 0.04, 0.25, 4, part="Spring", axis="y")
    for k in range(3): flat(m, P(p[0], "ME"), gear_poly(10, 0.4, 0.3, 0.45), 0.08, (-0.5 + k * 0.5, YC - 0.15, 0.85 + 0.3 * (k % 2)), axis=(0, 1, 0), part="Gears")
    rod(m, P(p[0], "ME"), (0, YC + 0.75, 1.5), (0.25, YC + 0.8, 2.6), r=0.05, seg=6, part="Anchor")


def EngineSteamRegulator(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.0, 1.7)
    capsule(m, P(p[0], "ME"), (0, YC, 0.9), 0.6, 2.4, axis=(1, 0, 0), part="Boiler")
    for k in range(3): torus(m, P(p[1], "ME"), (-0.8 + k * 0.8, YC, 0.9), R=0.62, r=0.05, seg=16, rseg=4, rot=(0, 90, 0), part="Bands")
    rod(m, P(STEEL, "ME"), (0, YC + 0.1, 1.5), (0, YC + 0.1, 2.6), r=0.06, seg=6, part="Governor")
    for sx in (-1, 1):   # fly-ball governor
        rod(m, P(STEEL, "ME"), (0, YC + 0.1, 2.5), (sx * 0.45, YC + 0.1, 2.1), r=0.04, seg=5, part="Governor")
        sphere(m, P(p[0], "ME"), (sx * 0.5, YC + 0.1, 2.05), 0.16, seg=8, rings=5, part="Balls")
        disc(m, P("F2E3C2"), (sx * 0.8, YC + 0.62, 1.35), 0.22, 0.06, axis=(0, 1, 0), seg=12, part="Gauges")
    tube(m, P(p[1], "ME"), [(1.0, YC + 0.3, 1.4), (1.15, YC + 0.5, 2.0), (1.15, YC + 0.55, 2.8)], r=0.12, seg=8, part="Stack", smooth=2)


def EngineGaleRotor(m, c):
    p = c["palette"]
    base(m, P(p[1]), 2.6, 1.6)
    puff(m, P("F7F9FF"), [(-0.5, YC, 0.75, 0.55), (0.5, YC, 0.75, 0.55), (0, YC - 0.15, 1.1, 0.5), (0, YC + 0.3, 1.05, 0.45)], part="Cloud")
    rod(m, P("D4AF37", "ME"), (0, YC + 0.4, 1.0), (0, YC + 0.95, 1.6), r=0.12, seg=8, part="Mast")
    for k in range(3):   # three swept white blades
        a = 2 * math.pi * k / 3
        flat(m, P("8FD0FF"), [(-0.12, 0), (0.22, 0.05), (0.3, 1.25), (-0.05, 1.35)], 0.12, (0, YC + 1.0, 1.65), axis=(0, 1, 0), spin=a, part="Blades")
    disc(m, P("D4AF37", "ME"), (0, YC + 1.02, 1.65), 0.22, 0.14, axis=(0, 1, 0), seg=10, part="Hub")
