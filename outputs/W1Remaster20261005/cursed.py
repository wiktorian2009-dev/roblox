# cursed.py - Haunted winter settlement (World 1 remaster, Claude 2026-10-05). Playful spooky, readable: mid-tone stone, snow keeps it bright,
# restrained violet / green accents. Origin = floor-level centre; segments along X with the playable side at -Y.
import math, random
from w1lib import *

STONE = "6E6A80"; STONE2 = "5A5670"; STONE3 = "817C94"; MOSS = "5E7A5A"; ROOF = "4B3F66"; ROOF2 = "3E3457"; WOODD = "5A4636"
GLOWG = "7CFF9E"; GLOWV = "B98CFF"; PUMP = "F28A2E"; IRON = "2E2C38"; GHOST = "EEF4FF"; BARK = "4A3E3A"


def crack(m, x, y, z0, z1, rnd, part="Crack"):
    pts = [(x, y, z0)]
    for k in range(4):
        pts.append((x + rnd.uniform(-0.8, 0.8), y, z0 + (z1 - z0) * (k + 1) / 4))
    tube(m, P(GLOWV, "NE"), pts, r=0.12, seg=4, part=part, smooth=1)


def C_WallSeg(m):
    """Broken gothic wall: stacked dark blocks, broken crenellations, an arrow slit, a faint violet crack, snow on top (28 x 12 x ~26)."""
    rnd = random.Random(3)
    L_, D, H = 28.0, 12.0, 22.0
    bx(m, "Stone0", STONE2, -L_ / 2 + 0.4, L_ / 2 - 0.4, -D / 2 + 1.0, D / 2 - 0.6, 0, H - 1, r=0.6)
    for row in range(5):
        z = row * (H / 5)
        n = 5 + (row % 2)
        for k in range(n):
            x0 = -L_ / 2 + L_ * k / n + (0.6 if row % 2 else 0); w = L_ / n - 0.25
            if x0 + w > L_ / 2: w = L_ / 2 - x0
            col = [STONE, STONE3, STONE2][(row + k) % 3]
            rbox(m, P(col), (x0 + w / 2, -D / 2 + 1.0 + rnd.uniform(-0.25, 0.1), z + H / 10), (w, 1.4, H / 5 - 0.25), r=0.3, part="Block" + str((row + k) % 3))
    # broken crenellations
    for k in range(6):
        if k in (2, 5): continue
        x = -L_ / 2 + 2.4 + k * 4.6
        h = rnd.uniform(2.6, 4.2)
        bx(m, "Block0", STONE, x - 1.6, x + 1.6, -D / 2 + 0.6, D / 2 - 0.8, H - 1, H - 1 + h, r=0.35)
        snowcap(m, x - 1.6, x + 1.6, -D / 2 + 0.6, D / 2 - 0.8, H - 1 + h, t=0.45)
    snowcap(m, -L_ / 2 + 0.4, L_ / 2 - 0.4, -D / 2 + 1.0, D / 2 - 0.6, H - 1, t=0.5)
    bx(m, "Slit", "1C1A26", -0.6, 0.6, -D / 2 + 0.2, -D / 2 + 0.6, 9, 15, r=0.2)
    crack(m, -8, -D / 2 + 0.25, 1.5, 9, rnd)
    # dead vines and fallen rubble at the foot
    for k in range(3):
        x = rnd.uniform(-12, 12)
        tube(m, P(MOSS), [(x, -D / 2 + 0.2, H - 2), (x + 1, -D / 2 - 0.1, H - 7), (x - 0.5, -D / 2 + 0.1, H - 12)], r=0.22, seg=5, part="Vine", smooth=3)
    for k in range(5):
        rock(m, P(STONE3), (rnd.uniform(-12, 12), -D / 2 - 1.0, 0.5), size=(1.0, 0.8, 0.6), seed=k, sub=1, jag=0.2, part="Rubble")
    for k in range(4):
        drift(m, rnd.uniform(-12, 12), -D / 2 - 0.6, 0.1, rnd.uniform(1.4, 2.0), rnd)


def C_WallSegB(m):
    """Variant: a ruined arched window with a glowing candle niche."""
    C_WallSeg(m)
    flat(m, P("1C1A26"), arch_poly(5.5, 8.5, n=8), 0.5, (3, -5.0, 8), axis=(0, -1, 0), part="Window")
    lantern(m, -7, -6.6, 6, col=GLOWG)


def C_Chapel(m):
    """Landmark: crooked haunted chapel with a leaning spire, a glowing moon clock and green windows (34 x 26, ~52 tall)."""
    rnd = random.Random(7)
    # nave
    bx(m, "Wall0", STONE3, -12, 12, -9, 9, 0, 16, r=0.6)
    for x in (-8, 0, 8):
        flat(m, P("1C1A26"), arch_poly(3.2, 6.5, n=6), 0.4, (x, -8.85, 5), axis=(0, -1, 0), part="Window")
        flat(m, P(GLOWG, "NE", 0.2), arch_poly(2.6, 5.9, n=6), 0.1, (x, -9.3, 5.3), axis=(0, -1, 0), part="Glow")
    yc, half, ang, L2 = gable_roof(m, -13, 13, -10, 10, 16, 9, ROOF)
    # leaning bell tower + spire on the left
    tw = 7
    for k in range(4):
        z0 = 0 + k * 9
        sx = -16 + k * 0.6  # leans
        bx(m, "Tower", STONE if k % 2 else STONE2, sx - tw / 2, sx + tw / 2, -tw / 2, tw / 2, z0, z0 + 9.1, r=0.4)
    sx = -16 + 2.4
    lathe(m, P(ROOF2), [(5.5, 36), (0.01, 52)], loc=(sx + 0.8, 0, 0), seg=4, rot=(0, 6, 45), part="Spire")
    sphere(m, P(GLOWV, "NE"), (sx + 2.6, 0, 52.4), 0.7, seg=8, part="SpireOrb")
    # moon clock on the tower front
    cyl(m, P("F4F0D2", "NE"), (sx, -tw / 2 - 0.15, 27), r=2.6, h=0.3, seg=20, rot=(90, 0, 0), part="Clock")
    beam(m, P(IRON), (sx, -tw / 2 - 0.5, 27), (sx + 1.6, -tw / 2 - 0.5, 28.2), w=0.25, h=0.15, r=0.02, part="Hands")
    beam(m, P(IRON), (sx, -tw / 2 - 0.5, 27), (sx - 0.4, -tw / 2 - 0.5, 29.2), w=0.25, h=0.15, r=0.02, part="Hands")
    # front door + steps + snow
    flat(m, P(WOODD), arch_poly(4.5, 7.5, n=6), 0.5, (0, -9.0, 0), axis=(0, -1, 0), part="Door")
    for k in range(3):
        bx(m, "Steps", STONE, -4 - k, 4 + k, -10.5 - k * 1.2, -9, 0, 1.2 - k * 0.4, r=0.2)
    snowcap(m, sx - tw / 2, sx + tw / 2, -tw / 2, tw / 2, 36, t=0.6)
    # crooked fence + two graves at the side
    for k in range(5):
        rod(m, P(IRON), (14 + k * 1.6, -10, 0), (14 + k * 1.6, -10, 3.4 + (k % 2) * 0.5), r=0.12, seg=5, part="Iron")
    beam(m, P(IRON), (14, -10, 2.6), (20.4, -10, 2.8), w=0.15, h=0.2, r=0.02, part="Iron")
    for x in (16, 19):
        flat(m, P(STONE3), arch_poly(1.8, 2.8, n=5), 0.5, (x, -5, 0), axis=(0, -1, 0), part="Grave")
    lantern(m, 5.5, -9.6, 11, col=GLOWG, s=1.4)
    lantern(m, -5.5, -9.6, 11, col=GLOWG, s=1.4)


def gable_roof(m, x0, x1, y0, y1, z0, h, col, over=0.8, thick=0.8):
    yc = (y0 + y1) / 2; half = (y1 - y0) / 2 + over
    ang = math.degrees(math.atan2(h, half)); L_ = math.hypot(h, half)
    for s in (-1, 1):
        rbox(m, P(col), ((x0 + x1) / 2, yc + s * half / 2, z0 + h / 2), (x1 - x0 + over * 2, L_, thick), r=0.15, part="Roof", rot=(s * -ang, 0, 0))
        rbox(m, P(SNOW), ((x0 + x1) / 2, yc + s * half / 2 * 0.97, z0 + h / 2 + 0.55), (x1 - x0 + over * 2 + 0.2, L_ * 0.9, 0.45), r=0.2, part="Snow", rot=(s * -ang, 0, 0))
    return yc, half, ang, L_


def C_Cottage(m):
    """Crooked little house (14 x 12, ~17 tall): leaning walls, steep wonky roof, green-lit windows, a chimney."""
    rnd = random.Random(15)
    rbox(m, P(STONE3), (0, 0, 4), (12, 10, 8), r=0.5, rot=(0, 3, 2), part="Wall")
    rbox(m, P(WOODD), (0, 0, 9.4), (12.6, 10.6, 3), r=0.3, rot=(0, -2, 3), part="Timber")
    for s in (-1, 1):
        rbox(m, P(ROOF), (0.3, s * 3.2, 14.2), (14.5, 7.6, 0.8), r=0.2, rot=(s * -52, 0, 4), part="Roof")
        rbox(m, P(SNOW), (0.3, s * 3.05, 14.75), (14.7, 6.8, 0.45), r=0.2, rot=(s * -52, 0, 4), part="Snow")
    rbox(m, P(STONE2), (-4.2, 2, 16), (2, 2, 6), r=0.25, rot=(0, 0, -6), part="Chimney")
    for x in (-3, 3):
        bx(m, "Glow", GLOWG, x - 1, x + 1, -5.25, -5.0, 3, 5.2, r=0.1, mat="NE")
        bx(m, "Trim", WOODD, x - 1.2, x + 1.2, -5.35, -5.2, 2.8, 5.4, r=0.05)
    bx(m, "Door", WOODD, -1.1, 1.1, -5.3, -5.0, 0, 4, r=0.2)
    drift(m, 6, -5, 0.1, 1.8, rnd); drift(m, -6.5, 4, 0.1, 1.6, rnd)


def C_DeadTree(m):
    """Twisted dead tree (~20 tall) with a hanging green lantern and snow on the branches."""
    rnd = random.Random(21)
    tube(m, P(BARK), [(0, 0, 0), (0.6, 0.3, 5), (-0.6, 0.2, 10), (0.8, -0.2, 14)], r=1.2, r2=0.5, seg=8, part="Bark", smooth=3)
    for k in range(6):
        a = 2 * math.pi * k / 6 + rnd.uniform(-0.3, 0.3)
        z = rnd.uniform(9, 14)
        p1 = (math.cos(a) * 3, math.sin(a) * 3, z + 2); p2 = (math.cos(a + 0.4) * 6, math.sin(a + 0.4) * 6, z + rnd.uniform(1, 5))
        tube(m, P(BARK), [(0.3, 0, z), p1, p2], r=0.45, r2=0.08, seg=5, part="Bark", smooth=3)
        sphere(m, P(SNOW), p1, 0.6, scl=(1.6, 1.0, 0.4), seg=6, rings=4, part="Snow")
    rod(m, P(IRON), (4.2, 1.5, 13.6), (4.2, 1.5, 10.8), r=0.06, seg=4, part="Iron")
    lantern(m, 4.2, 1.5, 9.6, col=GLOWG, s=1.2)
    for k in range(4):
        a = k * 1.7
        tube(m, P(BARK), [(0, 0, 0.6), (math.cos(a) * 2.2, math.sin(a) * 2.2, 0.1)], r=0.5, r2=0.2, seg=5, part="Bark", smooth=1)
    drift(m, 0.5, 0.5, 0, 2.2, rnd)


def C_Graves(m):
    """Snowy graveyard plot (20 x 14): leaning tombstones, a little crypt, a candle cluster."""
    rnd = random.Random(33)
    for r_ in range(2):
        for k in range(4):
            x = -7 + k * 4.2 + rnd.uniform(-0.4, 0.4); y = -3 + r_ * 5
            h = rnd.uniform(2.6, 3.8)
            flat(m, P(STONE3 if (k + r_) % 2 else STONE), arch_poly(2.2, h, n=5), 0.6, (x, y, 0), axis=(0, -1, 0), part="Grave", spin=rnd.uniform(-8, 8))
            sphere(m, P(SNOW), (x, y - 0.3, h - 0.3), 0.8, scl=(1.4, 0.6, 0.35), seg=6, rings=4, part="Snow")
            sphere(m, P(SNOW2), (x, y - 1.6, 0.1), 1.1, scl=(1.2, 1.4, 0.3), seg=6, rings=4, part="Snow")
    # small crypt
    bx(m, "Crypt", STONE2, 6.5, 11.5, -3, 3, 0, 5, r=0.3)
    for s in (-1, 1):
        rbox(m, P(ROOF2), (9, s * 1.6, 6.0), (6, 3.8, 0.5), r=0.15, rot=(s * -30, 0, 0), part="Roof")
    bx(m, "Door", "1C1A26", 8, 10, -3.15, -2.9, 0, 3.4, r=0.15)
    sphere(m, P(GLOWV, "NE"), (9, -3.25, 4.2), 0.35, seg=8, part="Orb")
    for k in range(5):
        h = rnd.uniform(0.6, 1.2)
        cyl(m, P("F3EBD8"), (-9 + rnd.uniform(-1, 1), -5.5 + rnd.uniform(-0.8, 0.8), 0), r=0.18, h=h, seg=6, part="Candle")
        sphere(m, P("FFD27A", "NE"), (-9 + 0, -5.5, h + 0.15), 0.12, seg=6, part="Flame")


def C_Arch(m):
    """Ruined stone arch (20 wide, ~20 tall) with hanging chains; one pillar broken."""
    rnd = random.Random(41)
    for sx, h in ((-1, 18), (1, 12)):
        x = sx * 8
        for k in range(int(h / 3)):
            bx(m, "Stone" + str(k % 2), STONE if k % 2 else STONE3, x - 2.2, x + 2.2, -2.2, 2.2, k * 3, k * 3 + 2.9, r=0.35)
        snowcap(m, x - 2.2, x + 2.2, -2.2, 2.2, int(h / 3) * 3, t=0.5)
    pts = [(-8, 0, 18), (-4, 0, 21), (0, 0, 21.6), (3.5, 0, 19.5)]
    tube(m, P(STONE3), pts, r=1.6, seg=6, part="ArchTop", smooth=3, sq=1.2)
    for x in (-3, 1):
        for k in range(5):
            torus(m, P(IRON), (x, 0, 19.5 - k * 0.9), R=0.35, r=0.09, seg=8, rseg=4, rot=(0, 90 * (k % 2), 0), part="Chain")
    for k in range(4):
        rock(m, P(STONE2), (8 + rnd.uniform(-3, 3), rnd.uniform(-3, 3), 0.6), size=(1.4, 1.1, 0.9), seed=k, sub=1, jag=0.2, part="Rubble")


def C_Fence(m):
    """Wrought-iron fence run (14 long, ~4 tall) with spiked bars and pumpkin-capped posts (matches the old IronFence footprint)."""
    for k in range(15):
        x = -7 + k
        rod(m, P(IRON), (x, 0, 0), (x, 0, 3.4), r=0.1, seg=5, part="Iron")
        prism(m, P(IRON), [(-0.22, 0), (0.22, 0), (0, 0.6)], 0.12, loc=(x, 0.06, 3.4), rot=(90, 0, 0), part="Iron")
    for zz in (0.6, 2.8):
        beam(m, P(IRON), (-7, 0, zz), (7, 0, zz), w=0.16, h=0.18, r=0.02, part="Iron")
    for x in (-7.3, 7.3):
        bx(m, "Post", STONE2, x - 0.6, x + 0.6, -0.6, 0.6, 0, 4.2, r=0.2)
        sphere(m, P(PUMP), (x, 0, 4.8), 0.6, scl=(1.1, 1.1, 0.85), seg=10, part="Pumpkin")
        sphere(m, P("FFE07A", "NE"), (x, -0.5, 4.8), 0.2, seg=6, part="PumpkinGlow")


def C_Pumpkins(m):
    """Pumpkin patch with jack-o'-lanterns, straw and a little scarecrow (12 x 9)."""
    rnd = random.Random(55)
    for k in range(9):
        x = rnd.uniform(-5, 5); y = rnd.uniform(-3.5, 3.5); s = rnd.uniform(0.7, 1.3)
        sphere(m, P(PUMP), (x, y, 0.7 * s), 0.9 * s, scl=(1.15, 1.15, 0.85), seg=10, rings=7, part="Pumpkin")
        rod(m, P("4C6B2E"), (x, y, 1.4 * s), (x + 0.15, y, 1.85 * s), r=0.12, seg=5, part="Stem")
        if k % 3 == 0:
            sphere(m, P("FFE07A", "NE"), (x, y - 0.8 * s, 0.75 * s), 0.25 * s, scl=(1.4, 0.4, 0.9), seg=6, part="PumpkinGlow")
    for k in range(4):
        rbox(m, P("E8C46A"), (rnd.uniform(-5, 5), rnd.uniform(-3.5, 3.5), 0.4), (1.6, 1.0, 0.8), r=0.2, rot=(0, 0, rnd.uniform(0, 90)), part="Straw")
    rod(m, P(WOODD), (5.5, 2.5, 0), (5.5, 2.5, 6.2), r=0.16, seg=5, part="Pole")
    beam(m, P(WOODD), (4.0, 2.5, 4.6), (7.0, 2.5, 4.6), w=0.16, h=0.16, r=0.03, part="Pole")
    rbox(m, P("7B5CA8"), (5.5, 2.5, 4.4), (2.4, 0.9, 2.2), r=0.3, part="Coat")
    sphere(m, P(PUMP), (5.5, 2.5, 6.3), 0.8, seg=10, part="Pumpkin")
    cyl(m, P(IRON), (5.5, 2.5, 6.9), r=0.9, h=0.12, seg=10, part="Hat")
    cyl(m, P(IRON), (5.5, 2.5, 7.0), r=0.55, h=0.9, r2=0.35, seg=10, part="Hat")


def C_Ghost(m):
    """Cute little ghost (for a Bob motion), ~3 tall."""
    lathe(m, P(GHOST, "SP", 0.15), [(0.01, 2.9), (1.0, 2.5), (1.2, 1.6), (1.25, 0.4), (0.9, 0.2)], seg=14, part="Ghost")
    for k in range(5):
        a = 2 * math.pi * k / 5
        sphere(m, P(GHOST, "SP", 0.15), (math.cos(a) * 0.95, math.sin(a) * 0.95, 0.25), 0.36, seg=6, rings=4, part="Ghost")
    for sx in (-0.4, 0.4):
        sphere(m, P("2A2340"), (sx, -1.05, 1.9), 0.17, scl=(1, 0.5, 1.3), seg=6, part="Eyes")
    sphere(m, P("FF9AC8"), (0, -1.12, 1.45), 0.13, scl=(1.5, 0.5, 0.8), seg=6, part="Mouth")


def C_Crag(m):
    """Background crag with a broken spire tower on top (outside the boundary, 50 x 36, ~62 tall)."""
    rnd = random.Random(61)
    mesa(m, 0, 0, 26, 20, 34, [STONE2, STONE, "4D4A60"], rnd, part_prefix="Crag")
    for k in range(3):
        bx(m, "Tower", STONE3 if k % 2 else STONE, -3 + k * 0.4, 3 + k * 0.4, -3, 3, 33 + k * 7, 33 + (k + 1) * 7, r=0.3)
    lathe(m, P(ROOF2), [(4.2, 54), (0.01, 64)], loc=(1.2, 0, 0), seg=4, rot=(0, 8, 45), part="Spire")
    bx(m, "Glow", GLOWV, -0.6, 0.6, -3.15, -2.9, 44, 47, r=0.1, mat="NE")


def C_Lamp(m):
    rod(m, P(IRON), (0, 0, 0), (0.6, 0, 7), r=0.16, seg=6, part="Iron")
    beam(m, P(IRON), (0.6, 0, 7), (2.0, 0, 7.6), w=0.12, h=0.12, r=0.02, part="Iron")
    lantern(m, 2.0, 0, 6.3, col=GLOWG, s=1.1)
    bx(m, "Base", STONE2, -0.8, 0.8, -0.8, 0.8, 0, 0.6, r=0.2)


BUILDERS = {"C_WallSeg": C_WallSeg, "C_WallSegB": C_WallSegB, "C_Chapel": C_Chapel, "C_Cottage": C_Cottage, "C_DeadTree": C_DeadTree,
            "C_Graves": C_Graves, "C_Arch": C_Arch, "C_Fence": C_Fence, "C_Pumpkins": C_Pumpkins, "C_Ghost": C_Ghost, "C_Crag": C_Crag, "C_Lamp": C_Lamp}
