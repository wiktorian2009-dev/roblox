# jungle.py - Frozen jungle temple ruins (World 1 remaster, Claude 2026-10-05): mossy carved stone, vines, snowy palms, bamboo, hibiscus.
import math, random
from w1lib import *
from mathutils import Vector as V3
from w2lib import flower

STONE = "5E6B63"; STONE2 = "4B5750"; STONE3 = "76827A"  # darkened after the Studio check (uploaded pack was recoloured in Studio to match); MOSS = "4E9A52"; MOSS2 = "3C7F45"; LEAF = "2FA35B"; LEAF2 = "1F8048"
VINE = "3E8E3E"; HIB = "FF5C7A"; HIB2 = "FFB347"; GLOW = "7CFFB2"; TRUNK = "8A6440"; BAMBOO = "9CCB5A"; BAMBOO2 = "7DAF43"


def vines(m, x0, x1, y, ztop, rnd, n=3, part="Vine"):
    for k in range(n):
        x = rnd.uniform(x0, x1); L_ = rnd.uniform(ztop * 0.35, ztop * 0.8)
        pts = [(x, y, ztop), (x + rnd.uniform(-0.6, 0.6), y - 0.3, ztop - L_ * 0.4), (x + rnd.uniform(-1, 1), y - 0.2, ztop - L_)]
        tube(m, P(VINE), pts, r=0.22, r2=0.14, seg=5, part=part, smooth=3)
        for j in range(3):
            t = (j + 1) / 4; z = ztop - L_ * t
            sphere(m, P(LEAF if j % 2 else LEAF2), (x + rnd.uniform(-0.5, 0.5), y - 0.4, z), 0.55, scl=(1.2, 0.5, 0.8), seg=6, rings=4, part="VineLeaf")


def J_WallSeg(m):
    """Temple-block boundary (14 x 12, ~30 tall): staggered mossy carved blocks, a carved glyph band, vines and snow."""
    rnd = random.Random(3)
    Lh, D, H = 14.0, 12.0, 30.0
    bx(m, "Core", STONE2, -Lh / 2 + 0.3, Lh / 2 - 0.3, -D / 2 + 1.2, D / 2, 0, H - 1, r=0.6)
    z = 0; row = 0
    while z < H - 1:
        h = rnd.uniform(4.2, 5.6) if row else 3.5
        nb = 2 if row % 2 == 0 else 3
        for k in range(nb):
            x0 = -Lh / 2 + Lh * k / nb; x1 = -Lh / 2 + Lh * (k + 1) / nb
            col = [STONE, STONE3, STONE2][(row + k) % 3]
            rbox(m, P(col), ((x0 + x1) / 2, -D / 2 + 0.9 + rnd.uniform(-0.25, 0.25), z + h / 2), (x1 - x0 - 0.25, 2.0, h - 0.25), r=0.45, bseg=2, rot=(0, 0, rnd.uniform(-1.5, 1.5)), part="Block" + col)
        if row == 3:
            for k in range(4):
                x = -Lh / 2 + Lh * (k + 0.5) / 4
                prism(m, P(MOSS2), star_poly(4, 1.1, 0.45), 0.25, loc=(x, -D / 2 - 0.15, z + h / 2), rot=(90, 0, 0), part="Glyph")
        z += h; row += 1
    for k in range(3):
        sphere(m, P(MOSS if k % 2 else MOSS2), (rnd.uniform(-5, 5), -D / 2 - 0.2, rnd.uniform(4, 22)), rnd.uniform(1.2, 2.0), scl=(1.6, 0.4, 1.0), seg=8, rings=5, part="Moss")
    vines(m, -6, 6, -D / 2 - 0.2, H - 1, rnd, n=3)
    for k in range(3):
        sphere(m, P(SNOW), (rnd.uniform(-5, 5), rnd.uniform(-3, 3), H - 0.6), rnd.uniform(2.2, 3.0), scl=(1.5, 1.4, 0.4), seg=9, rings=5, part="Snow")
    drift(m, rnd.uniform(-4, 4), -D / 2 - 0.6, 0.1, 1.6, rnd)
    m.flat("Block" + STONE, P(STONE), 28)


def J_Temple(m):
    """Landmark: stepped jungle temple (22 x 20, ~26 tall) with a carved-face doorway, glowing eyes, stairs, corner braziers, vines and snow."""
    rnd = random.Random(7)
    tiers = [(22, 20, 6), (17, 15.5, 5.5), (12.5, 11, 5), (8.5, 7.5, 4.5)]
    z = 0
    for i, (w, d, h) in enumerate(tiers):
        col = [STONE, STONE3, STONE, STONE3][i]
        bx(m, "Tier" + col, col, -w / 2, w / 2, -d / 2, d / 2, z, z + h, r=0.6, bseg=2)
        bx(m, "Band", MOSS2, -w / 2 - 0.1, w / 2 + 0.1, -d / 2 - 0.1, d / 2 + 0.1, z + h - 0.9, z + h - 0.4, r=0.15)
        snowcap(m, -w / 2, w / 2, -d / 2, d / 2, z + h, t=0.45)
        vines(m, -w / 2 + 1, w / 2 - 1, -d / 2 - 0.15, z + h - 0.4, rnd, n=2)
        z += h
    # shrine on top
    bx(m, "Shrine", STONE2, -3, 3, -2.5, 2.5, z, z + 4, r=0.4)
    lathe(m, P(MOSS2), [(4.4, z + 4), (0.01, z + 7.5)], seg=4, rot=(0, 0, 45), part="ShrineRoof")
    sphere(m, P(GLOW, "NE"), (0, -2.6, z + 2), 0.9, seg=10, part="ShrineGlow")
    # stairs up the front (playable side -Y)
    for k in range(8):
        y0 = -10 - 2.2 + k * 1.0
        bx(m, "Stair", STONE3, -2.6, 2.6, y0, y0 + 2.4, 0, 1.0 + k * 2.6, r=0.2)
    # carved stone face on the front of tier 1 (eyes glow)
    bx(m, "Face", STONE2, -5.5, 5.5, -10.6, -9.9, 0.5, 5.6, r=0.3)
    for x in (-3.4, 3.4):
        bx(m, "Brow", STONE, x - 1.6, x + 1.6, -10.9, -10.5, 4.1, 4.8, r=0.15)
        bx(m, "Eye", GLOW, x - 1.0, x + 1.0, -10.8, -10.55, 2.9, 3.8, r=0.1, mat="NE")
    for x in (-4.5, 4.5):
        bx(m, "Fang", STONE3, x - 0.4, x + 0.4, -10.85, -10.55, 0.6, 2.0, r=0.1)
    # braziers on the corners of the base
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 10, sy * 9
            cyl(m, P(STONE2), (x, y, 6.6), r=0.9, h=1.2, r2=1.3, seg=10, part="Brazier")
            sphere(m, P(HIB2, "NE"), (x, y, 7.5), 0.7, seg=8, part="Flame")
    # moss mounds + ferns at the base
    for k in range(6):
        a = rnd.uniform(0, 6.28)
        sphere(m, P(MOSS), (math.cos(a) * 11.5, math.sin(a) * 10.5, 0.4), rnd.uniform(1.4, 2.2), scl=(1.4, 1.2, 0.55), seg=8, rings=5, part="Moss")


def J_Idol(m):
    """Giant mossy stone head (12 x 10, ~16 tall) half sunk into the snow, glowing eyes, vines on the crown."""
    rnd = random.Random(11)
    bx(m, "Head", STONE, -5, 5, -4.5, 4.5, 0, 13, r=1.4, bseg=2)
    bx(m, "Crown", STONE3, -5.6, 5.6, -5, 5, 12, 15, r=0.8)
    for k in range(5):
        x = -4.4 + k * 2.2
        lathe(m, P(MOSS2), [(0.9, 15), (0.01, 17.2)], loc=(x, 0, 0), seg=4, part="Spike")
    bx(m, "Brow", STONE2, -4.6, 4.6, -5.0, -4.3, 8.4, 9.6, r=0.3)
    for x in (-2.3, 2.3):
        bx(m, "Socket", DARK, x - 1.3, x + 1.3, -4.75, -4.35, 6.0, 8.2, r=0.3)
        bx(m, "Eye", GLOW, x - 0.7, x + 0.7, -4.85, -4.6, 6.6, 7.6, r=0.1, mat="NE")
    bx(m, "Nose", STONE2, -1, 1, -5.6, -4.3, 3.6, 6.4, r=0.35)
    bx(m, "Mouth", DARK, -2.8, 2.8, -4.8, -4.35, 1.4, 2.6, r=0.3)
    for k in range(3):
        sphere(m, P(MOSS if k % 2 else MOSS2), (rnd.uniform(-4, 4), rnd.uniform(-3, 3), 15.2), rnd.uniform(1.2, 1.8), scl=(1.4, 1.4, 0.5), seg=8, rings=5, part="Moss")
    vines(m, -4, 4, -5.1, 14, rnd, n=3)
    sphere(m, P(SNOW), (0, 0, 15.3), 3.0, scl=(1.6, 1.4, 0.35), seg=9, rings=5, part="Snow")
    for k in range(4):
        drift(m, rnd.uniform(-6, 6), rnd.choice((-5.2, 5.2)), 0.1, 2.0, rnd)


def J_Palm(m):
    """Snowy jungle palm (~18 tall), leaning, bright fronds with snow on top."""
    rnd = random.Random(23)
    pts = [(0, 0, 0), (0.4, 0.2, 5), (1.4, 0.4, 10), (2.8, 0.6, 14.5), (4.0, 0.8, 17)]
    tube(m, P(TRUNK), pts, r=0.8, r2=0.5, seg=10, part="Trunk", smooth=4)
    top = V3((4.0, 0.8, 17))
    for k in range(9):
        a = 2 * math.pi * k / 9 + rnd.uniform(-0.15, 0.15)
        d = V3((math.cos(a), math.sin(a), 0))
        p1 = top + d * 4 + V3((0, 0, 1.3)); p2 = top + d * 7.5 + V3((0, 0, -0.6)); p3 = top + d * 9.5 + V3((0, 0, -3.4))
        tube(m, P(LEAF if k % 2 else LEAF2), [top, p1, p2, p3], r=1.0, r2=0.25, seg=6, part="Frond", sq=0.25, smooth=3)
        sphere(m, P(SNOW), (p1.x, p1.y, p1.z + 0.35), 0.8, scl=(1.8, 1.2, 0.35), seg=6, rings=4, part="Snow")
    for k in range(3):
        a = k * 2.1
        sphere(m, P("7A4E2A"), (4 + math.cos(a) * 0.9, 0.8 + math.sin(a) * 0.9, 16.2), 0.6, seg=8, part="Coconut")
    sphere(m, P(SNOW), (0, 0, 0), 2.0, scl=(1.4, 1.4, 0.35), seg=9, rings=5, part="Mound")


def J_Bamboo(m):
    """Bamboo clump (~16 tall): segmented canes with leaf tufts, snow puffs."""
    rnd = random.Random(29)
    for k in range(7):
        a = rnd.uniform(0, 6.28); r = rnd.uniform(0, 2.0)
        x, y = math.cos(a) * r, math.sin(a) * r; h = rnd.uniform(10, 16)
        lean = (rnd.uniform(-1.2, 1.2), rnd.uniform(-1.2, 1.2))
        tube(m, P(BAMBOO if k % 2 else BAMBOO2), [(x, y, 0), (x + lean[0] * 0.5, y + lean[1] * 0.5, h * 0.5), (x + lean[0], y + lean[1], h)], r=0.38, seg=8, part="Cane", smooth=2)
        for j in range(1, int(h / 2.6)):
            t = j * 2.6 / h
            torus(m, P(BAMBOO2), (x + lean[0] * t, y + lean[1] * t, j * 2.6), R=0.42, r=0.09, seg=10, rseg=4, part="Node")
        for j in range(2):
            sphere(m, P(LEAF), (x + lean[0] + rnd.uniform(-1, 1), y + lean[1] + rnd.uniform(-1, 1), h - j * 2), 1.0, scl=(1.8, 0.6, 0.4), seg=6, rings=4, rot=(0, 0, rnd.uniform(0, 180)), part="Leaf")
        sphere(m, P(SNOW), (x + lean[0], y + lean[1], h + 0.3), 0.55, scl=(1.4, 1.4, 0.6), seg=6, rings=4, part="Snow")
    drift(m, 0, 0, 0.1, 2.4, rnd)


def J_Hibiscus(m):
    """Flowering bush (8 x 6, ~5 tall) with big pink/orange flowers and snow."""
    rnd = random.Random(31)
    blob(m, P(LEAF2), (0, 0, 1.8), rad=2.6, n=6, seed=31, spread=(1.4, 1.0, 0.5), part="Bush")
    for k in range(9):
        a = 2 * math.pi * k / 9; r = 3.4
        flower(m, P(HIB if k % 2 else HIB2), P("FFE680"), (math.cos(a) * r, math.sin(a) * r * 0.75, rnd.uniform(2.0, 3.6)), 0.9, rot=(rnd.uniform(-30, 30), rnd.uniform(-30, 30), 0), part="Flowers")
    sphere(m, P(SNOW), (0.4, 0, 4.3), 1.0, scl=(1.5, 1.2, 0.4), seg=8, rings=5, part="Snow")


def J_Boulder(m):
    """Mossy boulder pair with snow (~6 tall)."""
    rock(m, P(STONE), (0, 0, 2.6), (3, 2.5, 2.7), seed=41, part="Rock")
    rock(m, P(STONE2), (3.4, 1.2, 1.3), (1.7, 1.5, 1.4), seed=42, part="Rock2")
    sphere(m, P(MOSS), (-0.8, -1.6, 4.0), 1.6, scl=(1.4, 1.0, 0.5), seg=8, rings=5, part="Moss")
    sphere(m, P(SNOW), (0.3, 0.3, 5.0), 1.8, scl=(1.4, 1.2, 0.35), seg=8, rings=5, part="Snow")


def J_Pillar(m):
    """Broken ancient pillar (~12 tall) with carved rings, moss and a vine."""
    rnd = random.Random(43)
    bx(m, "Base", STONE2, -2, 2, -2, 2, 0, 1.4, r=0.3)
    cyl(m, P(STONE), (0, 0, 1.4), r=1.4, h=9, seg=12, part="Shaft")
    for k in range(3):
        torus(m, P(STONE3), (0, 0, 3 + k * 3), R=1.45, r=0.22, seg=14, rseg=4, part="Ring")
    lathe(m, P(STONE3), [(1.5, 10.4), (1.1, 11.2), (1.35, 11.8), (0.6, 12.2), (0.01, 12.3)], seg=12, part="Break")
    sphere(m, P(MOSS), (0.3, -0.8, 7), 1.0, scl=(1.2, 0.5, 1.5), seg=7, rings=4, part="Moss")
    vines(m, -0.8, 0.8, -1.5, 11, rnd, n=1)
    sphere(m, P(SNOW), (0, 0, 12.0), 1.3, scl=(1.2, 1.2, 0.4), seg=8, rings=5, part="Snow")


def J_Parrot(m):
    """Bright parrot (~2.5 long) for orbit motion above the fields."""
    sphere(m, P("E63946"), (0, 0, 0), 0.8, scl=(1.0, 1.6, 0.9), seg=10, rings=6, part="Body")
    sphere(m, P("E63946"), (0, -1.2, 0.5), 0.55, seg=8, part="Head")
    lathe(m, P("FFD166"), [(0.25, 0), (0.01, 0.5)], loc=(0, -1.75, 0.45), rot=(90, 0, 0), seg=6, part="Beak")
    for sx in (-1, 1):
        rbox(m, P("118AB2" if sx < 0 else "06D6A0"), (sx * 1.2, 0, 0.2), (1.6, 1.2, 0.15), r=0.06, rot=(0, sx * 18, 0), part="Wing")
    rbox(m, P("118AB2"), (0, 1.6, -0.1), (0.5, 1.6, 0.12), r=0.05, part="Tail")


def J_BigTree(m):
    """Background giant snowy rainforest tree (~42 tall): buttress roots, tall trunk, three umbrella canopies with snow."""
    rnd = random.Random(47)
    lathe(m, P(TRUNK), [(4.5, 0), (2.4, 3), (2.0, 10), (1.7, 28), (1.4, 36)], seg=12, part="Trunk")
    for k in range(5):
        a = 2 * math.pi * k / 5
        tube(m, P(TRUNK), [(math.cos(a) * 1.8, math.sin(a) * 1.8, 6), (math.cos(a) * 4, math.sin(a) * 4, 2), (math.cos(a) * 6, math.sin(a) * 6, 0)], r=0.8, r2=0.4, seg=6, part="Root", smooth=2)
    for (z, r, ox) in ((36, 9, 0), (28, 6.5, 4.5), (24, 5.5, -4)):
        sphere(m, P(LEAF2), (ox, 0, z), r, scl=(1.0, 1.0, 0.38), seg=12, rings=6, part="Canopy")
        sphere(m, P(SNOW), (ox, 0, z + r * 0.3), r * 0.85, scl=(1.0, 1.0, 0.18), seg=12, rings=5, part="Snow")
        if ox: tube(m, P(TRUNK), [(0, 0, z - 6), (ox * 0.6, 0, z - 2), (ox, 0, z - 0.5)], r=0.5, seg=6, part="Branch", smooth=2)
    vines(m, -6, 6, -3, 32, rnd, n=4)


BUILDERS = {"J_WallSeg": J_WallSeg, "J_Temple": J_Temple, "J_Idol": J_Idol, "J_Palm": J_Palm, "J_Bamboo": J_Bamboo, "J_Hibiscus": J_Hibiscus,
            "J_Boulder": J_Boulder, "J_Pillar": J_Pillar, "J_Parrot": J_Parrot, "J_BigTree": J_BigTree}
