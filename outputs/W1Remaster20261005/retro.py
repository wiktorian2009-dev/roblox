# retro.py - Snowy arcade / toy district (World 1 remaster, Claude 2026-10-05). Chunky geometric, bold colours, voxel sculptures.
import math, random
from w1lib import *

R1 = "FF5A6E"; R2 = "FFC93C"; R3 = "4CC9F0"; R4 = "7B61FF"; R5 = "3DDC97"; R6 = "FF8C42"; INK = "2B2D42"; PANEL = "1B1E33"
SCREEN = "3CF2FF"; BRICKS = [R1, R2, R3, R4, R5, R6]


def brick(m, x0, x1, y0, y1, z0, z1, col, part, studs=True):
    bx(m, part, col, x0, x1, y0, y1, z0, z1, r=0.35, bseg=1)
    if studs:
        nx = max(1, int((x1 - x0) / 2.6)); ny = max(1, int((y1 - y0) / 2.6))
        for i in range(nx):
            for j in range(ny):
                cx = x0 + (i + 0.5) * (x1 - x0) / nx; cy = y0 + (j + 0.5) * (y1 - y0) / ny
                cyl(m, P(col), (cx, cy, z1 - 0.02), r=0.7, h=0.5, seg=8, part=part)


def R_WallSeg(m):
    """Toy-brick wall (24 x 10, ~20 tall): staggered oversized bricks in bold colours, studs on top, snow drifts."""
    rnd = random.Random(2)
    L_, D, H = 24.0, 10.0, 20.0
    rows = 5
    for r in range(rows):
        z0 = r * H / rows; z1 = z0 + H / rows - 0.15
        off = 3.0 if r % 2 else 0
        x = -L_ / 2 - off
        k = 0
        while x < L_ / 2:
            w = 6.0
            x0 = max(-L_ / 2, x); x1 = min(L_ / 2, x + w - 0.15)
            if x1 - x0 > 0.5:
                col = BRICKS[(r * 3 + k) % len(BRICKS)]
                brick(m, x0, x1, -D / 2, D / 2, z0, z1, col, "Brick" + col, studs=(r == rows - 1))
            x += w; k += 1
    for k in range(4):
        sphere(m, P(SNOW), (rnd.uniform(-10, 10), rnd.uniform(-3, 3), H + 0.4), rnd.uniform(1.8, 2.6), scl=(1.6, 1.3, 0.4), seg=9, rings=5, part="Snow")
    for k in range(3):
        drift(m, rnd.uniform(-10, 10), -D / 2 - 0.8, 0.1, rnd.uniform(1.4, 2.0), rnd)


def R_ArcadeTower(m):
    """Landmark: a giant arcade cabinet tower (16 x 14, ~36 tall): pixel screen, joystick + buttons, neon marquee, coin slot door."""
    bx(m, "Cabinet", R4, -8, 8, -6, 7, 0, 30, r=1.0, bseg=2)
    bx(m, "Trim", R1, -8.4, 8.4, -6.4, 7.4, 29.4, 31.2, r=0.5)
    # screen (pixel art blocks) on the front
    bx(m, "Bezel", PANEL, -6, 6, -6.3, -5.8, 14, 25, r=0.4)
    rnd = random.Random(5)
    for i in range(8):
        for j in range(6):
            if rnd.random() < 0.45:
                col = [SCREEN, R2, R1, R5][(i + j) % 4]
                bx(m, "Pixel" + col, col, -5.2 + i * 1.3, -4.2 + i * 1.3, -6.45, -6.25, 15 + j * 1.5, 16.1 + j * 1.5, r=0.05, mat="NE")
    # control deck + joystick + buttons
    rbox(m, P(INK), (0, -8.5, 12), (14, 6, 1.4), r=0.4, rot=(-18, 0, 0), part="Deck")
    rod(m, P(INK), (-3, -9, 12.6), (-3, -9.4, 15), r=0.3, seg=8, part="Stick")
    sphere(m, P(R1), (-3, -9.4, 15.4), 0.9, seg=10, part="StickBall")
    for k, col in enumerate((R2, R3, R5)):
        cyl(m, P(col, "NE"), (1.5 + k * 1.8, -9.2, 12.5), r=0.6, h=0.4, seg=10, rot=(-18, 0, 0), part="Button" + col)
    # marquee sign above the screen (SurfaceGui text "ARCADE" goes on MarqueeFace in Studio)
    bx(m, "Marquee", R2, -7, 7, -7.2, -5.6, 26, 29, r=0.4)
    bx(m, "MarqueeFace", PANEL, -6.4, 6.4, -7.35, -7.15, 26.4, 28.6, r=0.05)
    # door with coin slot
    bx(m, "Door", INK, -2.4, 2.4, -6.25, -5.9, 0, 6.5, r=0.3)
    bx(m, "Coin", R2, -0.5, 0.5, -6.4, -6.2, 7.5, 9, r=0.15, mat="NE")
    # side art stripes + snow on top
    for k, col in enumerate((R1, R2, R3)):
        bx(m, "Stripe" + col, col, -8.15, -7.9, -4 + k * 3.5, -2 + k * 3.5, 2, 28, r=0.1)
        bx(m, "Stripe" + col, col, 7.9, 8.15, -4 + k * 3.5, -2 + k * 3.5, 2, 28, r=0.1)
    snowcap(m, -8.4, 8.4, -6.4, 7.4, 31.2, t=0.7)
    # giant coin balanced on top (Spin)
    cyl(m, P(R2, "ME"), (0, 0, 33), r=3.0, h=0.8, seg=20, rot=(90, 0, 0), part="BigCoin")


def block_building(m, w, d, levels, cols, rnd, roofcol=None):
    z = 0
    for i, h in enumerate(levels):
        ww = w - i * 2; dd = d - i * 2
        col = cols[i % len(cols)]
        bx(m, "Block" + col, col, -ww / 2, ww / 2, -dd / 2, dd / 2, z, z + h, r=0.8, bseg=2)
        # windows in a grid on the front + sides
        nwx = max(1, int(ww / 4))
        for k in range(nwx):
            for f in range(max(1, int(h / 4))):
                x = -ww / 2 + (k + 0.5) * ww / nwx
                zz = z + 1.2 + f * 4
                if zz + 2 < z + h:
                    bx(m, "Window", "FFE9A8" if rnd.random() < 0.6 else SCREEN, x - 0.9, x + 0.9, -dd / 2 - 0.12, -dd / 2 + 0.05, zz, zz + 2, r=0.1, mat="NE")
        snowcap(m, -ww / 2, ww / 2, -dd / 2, dd / 2, z + h, t=0.5)
        z += h
    return z


def R_BlockA(m):
    rnd = random.Random(11)
    top = block_building(m, 14, 12, [8, 7, 6], [R3, R4, R1], rnd)
    sphere(m, P(R2), (0, 0, top + 1.6), 1.8, seg=12, part="Ball")
    bx(m, "Door", INK, -1.5, 1.5, -6.2, -5.9, 0, 4, r=0.3)


def R_BlockB(m):
    rnd = random.Random(13)
    top = block_building(m, 12, 12, [10, 9], [R5, R6], rnd)
    lathe(m, P(R1), [(4.2, top), (0.01, top + 5)], seg=4, rot=(0, 0, 45), part="Pyramid")
    bx(m, "Door", INK, -1.5, 1.5, -6.2, -5.9, 0, 4, r=0.3)
    # bold sign board on the front (SurfaceGui in Studio on SignFace)
    bx(m, "Sign", R2, -5, 5, -7.2, -6.4, 10.5, 13.5, r=0.3)
    bx(m, "SignFace", PANEL, -4.5, 4.5, -7.35, -7.15, 10.9, 13.1, r=0.05)


def R_BlockC(m):
    """Tall thin tower with a ring ledge and a satellite dish."""
    rnd = random.Random(17)
    top = block_building(m, 9, 9, [9, 9, 8], [R1, R2, R3], rnd)
    torus(m, P(R4), (0, 0, 12), R=6.0, r=0.6, seg=24, rseg=6, part="Ring")
    lathe(m, P("E8EEF6"), [(0.01, top + 0.6), (2.4, top + 1.6), (2.6, top + 1.8)], loc=(1, 0, 0), seg=14, rot=(25, 0, 0), part="Dish")


def R_VoxelTree(m):
    """Blocky tree: cube trunk + stacked cube canopy with snow cubes (~12 tall)."""
    rnd = random.Random(19)
    bx(m, "Trunk", "8A5530", -0.9, 0.9, -0.9, 0.9, 0, 5, r=0.15)
    for (x, y, z, s) in ((0, 0, 6.5, 5.2), (1.8, 0.6, 8.5, 3.4), (-1.6, -0.8, 8.8, 3.2), (0, 0, 10.4, 3.0)):
        bx(m, "Leaves", "2FBF71" if s > 4 else "25A35F", x - s / 2, x + s / 2, y - s / 2, y + s / 2, z - s / 2, z + s / 2, r=0.25)
        bx(m, "Snow", SNOW, x - s / 2 - 0.1, x + s / 2 + 0.1, y - s / 2 - 0.1, y + s / 2 + 0.1, z + s / 2 - 0.05, z + s / 2 + 0.6, r=0.2)


def R_PixelHeart(m):
    """Voxel sculpture: a big pixel heart on a stand (~11 tall)."""
    pat = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
    s = 1.2
    for j, row in enumerate(pat):
        for i, c in enumerate(row):
            if c == "1":
                x = (i - 3) * s; z = 4 + (len(pat) - j) * s
                bx(m, "Voxel", R1 if (i + j) % 3 else "FF8FA0", x - s / 2, x + s / 2, -s / 2, s / 2, z, z + s, r=0.1)
    bx(m, "Stand", INK, -1, 1, -1, 1, 0, 4.2, r=0.2)
    bx(m, "Base", R4, -3, 3, -2.5, 2.5, 0, 0.8, r=0.3)
    snowcap(m, -2.4, -1.2, -0.6, 0.6, 4 + 6 * s, t=0.3)


def R_PixelGhost(m):
    """Voxel sculpture: a retro game ghost (~9 tall)."""
    pat = ["0011100", "0111110", "1111111", "1101011", "1111111", "1111111", "1010101"]
    s = 1.1
    for j, row in enumerate(pat):
        for i, c in enumerate(row):
            if c == "1":
                x = (i - 3) * s; z = 1 + (len(pat) - j) * s
                bx(m, "Voxel", R3, x - s / 2, x + s / 2, -s / 2, s / 2, z, z + s, r=0.1)
    for x in (-1.1, 1.1):
        bx(m, "Eye", "FFFFFF", x - 0.5, x + 0.5, -0.75, -0.45, 1 + 4 * s, 1 + 5 * s, r=0.05)
    snowcap(m, -2, 2, -0.6, 0.6, 1 + 8 * s, t=0.3)


def R_Arcades(m):
    """Row of three small arcade cabinets (12 x 4)."""
    for k, col in enumerate((R1, R3, R5)):
        x = -4.2 + k * 4.2
        bx(m, "Cab" + col, col, x - 1.6, x + 1.6, -1.4, 1.4, 0, 6.4, r=0.3)
        bx(m, "Scr", SCREEN, x - 1.2, x + 1.2, -1.5, -1.35, 3.6, 5.6, r=0.05, mat="NE")
        rbox(m, P(INK), (x, -1.9, 3.1), (3.0, 1.4, 0.4), r=0.1, rot=(-20, 0, 0), part="Deck")
        sphere(m, P(R2), (x - 0.6, -2.1, 3.6), 0.3, seg=8, part="Stick")
        snowcap(m, x - 1.6, x + 1.6, -1.4, 1.4, 6.4, t=0.35)


def R_Sign(m):
    """Bold arrow sign on a post (SurfaceGui text on SignFace)."""
    bx(m, "Post", INK, -0.4, 0.4, -0.4, 0.4, 0, 9, r=0.15)
    prism(m, P(R2), [(-4.5, -1.6), (3, -1.6), (5, 0), (3, 1.6), (-4.5, 1.6)], 0.8, loc=(0, 0.4, 8), rot=(90, 0, 0), part="Arrow")
    bx(m, "SignFace", PANEL, -4, 2.8, -0.46, -0.4, 6.6, 9.4, r=0.05)
    snowcap(m, -4.5, 3, -0.4, 0.4, 9.6, t=0.3)


def R_GiantBlocks(m):
    """Background stack of giant alphabet toy blocks (~30 tall)."""
    rnd = random.Random(29)
    z = 0
    for k, (s, col) in enumerate(((14, R3), (12, R1), (10, R2), (8, R5))):
        ox, oy = rnd.uniform(-2, 2), rnd.uniform(-2, 2)
        rbox(m, P(col), (ox, oy, z + s / 2), (s, s, s), r=1.0, bseg=2, rot=(0, 0, rnd.uniform(-20, 20)), part="Block" + col)
        prism(m, P("FFFFFF"), star_poly(5, s * 0.3, s * 0.14), 0.2, loc=(ox, oy - s / 2 - 0.1, z + s / 2), rot=(90, 0, 0), part="Letter")
        snowcap(m, ox - s / 2 + 0.6, ox + s / 2 - 0.6, oy - s / 2 + 0.6, oy + s / 2 - 0.6, z + s, t=0.5)
        z += s - 0.2


def R_SpinTop(m):
    """Big spinning top (Spin about Y in Studio), ~14 tall."""
    lathe(m, P(R4), [(0.01, 0), (2, 1.5), (6, 5), (6.4, 6), (4, 8.5), (1.2, 10)], seg=16, part="Top")
    for k in range(4):
        torus(m, P([R1, R2, R3, R5][k]), (0, 0, 5.2 + k * 0.5), R=6.0 - k * 0.4, r=0.25, seg=20, rseg=5, part="Band")
    cyl(m, P(INK), (0, 0, 10), r=0.6, h=3.5, seg=8, part="Handle")


BUILDERS = {"R_WallSeg": R_WallSeg, "R_ArcadeTower": R_ArcadeTower, "R_BlockA": R_BlockA, "R_BlockB": R_BlockB, "R_BlockC": R_BlockC,
            "R_VoxelTree": R_VoxelTree, "R_PixelHeart": R_PixelHeart, "R_PixelGhost": R_PixelGhost, "R_Arcades": R_Arcades, "R_Sign": R_Sign,
            "R_GiantBlocks": R_GiantBlocks, "R_SpinTop": R_SpinTop}
