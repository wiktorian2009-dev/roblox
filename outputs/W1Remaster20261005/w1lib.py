# w1lib.py - shared World 1 remaster modelling helpers (Claude, 2026-10-05), built on w2lib + partlib.
# 1 unit = 1 stud, up = +Z, model origin = floor-level centre. Studio maps Blender (x,y,z) -> Roblox local (-x, z, y).
# Wall / cliff SEGMENTS are built along X (length), playable side = -Y ("front"), so Studio can tile them along an old wall line.
import sys, math, random
from mathutils import Vector
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\PlowExpansion20261005\parts")
import w2lib as L
from w2lib import P, Mx, sphere, rbox, cyl, lathe, tube, torus, prism, rock, island_se, turf_se, se_point, blob
from partlib import beam, rod, flat, disc, mesh, arch_poly, box_m, circle_poly, star_poly, crystal

SNOW = "F6FAFF"; SNOW2 = "E4EEFA"; ICE = "BFE6FF"; ICE2 = "8FC8F5"; WARM = "FFE3A0"; STEEL = "3B3F4A"; DARK = "262A33"
WOOD = "B9763F"; WOOD2 = "8A5530"; RED = "E2483D"; YEL = "FFC81E"; WHITE = "F2F6FB"; GOLD = "F2C14E"


def bx(m, part, col, x0, x1, y0, y1, z0, z1, r=0.15, bseg=1, mat="SP", rot=(0, 0, 0)):
    rbox(m, P(col, mat), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), r=r, bseg=bseg, part=part, rot=rot)


def snowcap(m, x0, x1, y0, y1, z, t=0.4, ov=0.15, part="Snow", col=SNOW):
    bx(m, part, col, x0 - ov, x1 + ov, y0 - ov, y1 + ov, z - 0.05, z + t, r=min(0.2, t * 0.45), bseg=2)


def drift(m, x, y, z, r, rnd, part="Snow", col=SNOW, flat_=0.42):
    """Soft snow pile: a few squashed spheres."""
    for k in range(3):
        a = rnd.uniform(0, 6.28); d = rnd.uniform(0, r * 0.5)
        sphere(m, P(col), (x + math.cos(a) * d, y + math.sin(a) * d, z), r * rnd.uniform(0.6, 1.0), scl=(1.3, 1.0, flat_), seg=9, rings=5, part=part)


def strata_segment(m, length, depth, height, cols, rnd, part_prefix="Rock", snow=True, jag=0.12, lean=0.0, layers=4, front_bias=0.0):
    """Layered cliff wall segment along X (length), centred at the origin, base z=0, playable side = -Y.
    Each layer is a chunky jagged slab slightly set back from the one below; snow on the ledges."""
    z = 0.0
    hs = [height * w for w in ([0.34, 0.28, 0.22, 0.16][:layers])]
    tot = sum(hs); hs = [h * height / tot for h in hs]
    # solid core so the wall never shows gaps; strata bands are chunky rounded slabs on its faces
    bx(m, part_prefix + "0", cols[0], -length / 2 + 0.6, length / 2 - 0.6, -depth / 2 + depth * 0.18 + front_bias, depth / 2 - 0.6 + front_bias, 0, height * 0.94, r=0.8)
    for i, h in enumerate(hs):
        inset = i * depth * 0.07
        col = cols[i % len(cols)]
        n = max(2, int(length / 7))
        for k in range(n):
            x0 = -length / 2 + length * k / n; x1 = -length / 2 + length * (k + 1) / n
            cx = (x0 + x1) / 2 + rnd.uniform(-0.3, 0.3)
            w = (x1 - x0) * rnd.uniform(1.05, 1.18)
            dd = depth - inset * 2 + rnd.uniform(-0.8, 0.5)
            hh = h * rnd.uniform(0.9, 1.08)
            cy = inset * 0.4 + rnd.uniform(-0.4, 0.4) + front_bias
            rbox(m, P(col), (cx, cy, z + hh / 2), (w, dd, hh), r=min(1.1, hh * 0.3), bseg=2,
                 rot=(rnd.uniform(-2, 2), rnd.uniform(-3, 3), rnd.uniform(-4, 4)), part=part_prefix + str(i % len(cols)))
        z += h * 0.96
        if snow and i < len(hs) - 1:
            for k in range(max(2, int(length / 7))):
                if rnd.random() < 0.55:
                    x = rnd.uniform(-length / 2 + 2, length / 2 - 2)
                    sphere(m, P(SNOW), (x, -depth / 2 + inset + 1.6 + front_bias, z + 0.2), rnd.uniform(1.4, 2.4), scl=(1.6, 0.9, 0.35), seg=8, rings=4, part="Snow")
    if snow:
        for k in range(max(3, int(length / 5))):
            x = -length / 2 + length * (k + 0.5) / max(3, int(length / 5)) + rnd.uniform(-0.8, 0.8)
            sphere(m, P(SNOW), (x, rnd.uniform(-1.0, 1.0) + front_bias, z + 0.3), rnd.uniform(2.2, 3.2), scl=(1.5, 1.3, 0.38), seg=9, rings=5, part="Snow")
    for k in range(len(cols)):
        m.flat(part_prefix + str(k), P(cols[k]), 28)
    return z


def pine(m, x, y, z, h, rnd, col="2F8F5A", col2="23704A", snow=True, part="Pine", trunk=WOOD2, tiers=4):
    cyl(m, P(trunk), (x, y, z), r=0.18 * h / 6, h=h * 0.25, seg=7, part="Trunk")
    for t in range(tiers):
        f = t / tiers
        r = (0.42 - f * 0.3) * h * 0.55 + 0.4
        zz = z + h * (0.18 + f * 0.62)
        cyl(m, P(col if t % 2 == 0 else col2), (x, y, zz), r=r, r2=r * 0.25, h=h * 0.3, seg=8, part=part)
        if snow:
            cyl(m, P(SNOW), (x, y, zz + h * 0.14), r=r * 0.62, r2=r * 0.12, h=h * 0.12, seg=8, part="Snow")


def lantern(m, x, y, z, part="Lamp", col=WARM, s=1.0):
    cyl(m, P(STEEL), (x, y, z), r=0.32 * s, h=0.16 * s, seg=8, part="Steel")
    cyl(m, P(col, "NE"), (x, y, z + 0.16 * s), r=0.26 * s, h=0.6 * s, seg=8, part=part)
    cyl(m, P(STEEL), (x, y, z + 0.76 * s), r=0.36 * s, r2=0.08 * s, h=0.3 * s, seg=8, part="Steel")


def crate(m, x, y, z, s, col=WOOD, rot=0, part="Crate"):
    rbox(m, P(col), (x, y, z + s / 2), (s, s, s), r=0.12 * s, rot=(0, 0, rot), part=part)
    a = math.radians(rot)
    for sgn in (-1, 1):
        rbox(m, P(WOOD2), (x + math.cos(a) * 0 , y, z + s / 2), (s * 1.02, s * 0.16, s * 1.02), r=0.04, rot=(0, 0, rot + 45 * sgn), part="CrateBand")


def barrel(m, x, y, z, h=2.2, col="9C5A2E", part="Barrel"):
    lathe(m, P(col), [(0.75 * h / 2.2, 0), (0.92 * h / 2.2, h * 0.5), (0.75 * h / 2.2, h)], loc=(x, y, z), seg=12, part=part)
    for zz in (0.18, 0.82):
        torus(m, P(STEEL), (x, y, z + h * zz), R=0.86 * h / 2.2, r=0.07, seg=14, rseg=5, part="Steel")


def fence_run(m, p0, p1, h=2.4, col=WOOD, post=WOOD2, part="Fence"):
    p0, p1 = Vector(p0), Vector(p1); d = p1 - p0; n = max(1, int(d.length / 3.2))
    for k in range(n + 1):
        q = p0 + d * (k / n)
        rbox(m, P(post), (q.x, q.y, h / 2), (0.45, 0.45, h), r=0.08, part=part + "Post")
    for zz in (h * 0.45, h * 0.85):
        beam(m, P(col), (p0.x, p0.y, zz), (p1.x, p1.y, zz), w=0.28, h=0.32, r=0.06, part=part)


def mesa(m, cx, cy, rx, ry, h, cols, rnd, part_prefix="Mesa", snow=True):
    """Broad flat-topped butte: 3 stacked tapered rocky layers + snowy top."""
    z = 0.0
    for i, k in enumerate((1.0, 0.86, 0.72)):
        hh = h * (0.42, 0.33, 0.25)[i]
        for s in range(6):
            a = 2 * math.pi * s / 6 + rnd.uniform(-0.3, 0.3)
            ox, oy = math.cos(a) * rx * k * 0.42, math.sin(a) * ry * k * 0.42
            rock(m, P(cols[i % len(cols)]), (cx + ox, cy + oy, z + hh / 2), size=(rx * k * 0.62, ry * k * 0.62, hh / 2 * 1.05), seed=int(rnd.random() * 1e6), sub=1, jag=0.12, part=part_prefix + str(i % len(cols)))
        z += hh * 0.95
    if snow:
        sphere(m, P(SNOW), (cx, cy, z + 0.4), 1.0, scl=(rx * 0.55, ry * 0.55, 1.6), seg=12, rings=6, part="Snow")
    for k in range(len(cols)): m.flat(part_prefix + str(k), P(cols[k]), 28)
