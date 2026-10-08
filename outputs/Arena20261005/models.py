# models.py - Snowplow Bumper Arena models (Claude, 2026-10-05). One builder per model; each takes a w2lib.Model.
# 1 unit = 1 stud, up = +Z, Studio maps Blender (x,y,z) -> Roblox local (-x, z, y).
# Ring models are built around the ARENA CENTRE (Roblox ArenaConfig.Center). Angle mapping: Blender angle = 180 - Roblox angle,
# and both the exit set {45,135,225,315} and the pad set are symmetric under it, so the same numbers are used here.
# Parts named Tint* are recoloured in Studio (bumper paint, banner colours).
import sys, math, random
from mathutils import Vector
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\PlowExpansion20261005\parts")
import w2lib as L
from w2lib import P, Mx, sphere, rbox, cyl, lathe, tube, torus, prism, rock, island_se, turf_se, se_point, blob
from partlib import beam, rod, flat, disc, mesh, arch_poly, box_m, circle_poly, star_poly, crystal

# ---- layout (must match ReplicatedStorage.ArenaConfig) ----
OUT_R = 61.5; WALL_IN = 58.0; EXIT_W = 20.0; EXITS = [45, 135, 225, 315]
PAD_R = 38.0; PADS = [344, 16, 74, 106, 164, 196, 254, 286]
FLOOR_R = OUT_R + 2.0
STAND_IN, STAND_OUT, STAND_TOP = OUT_R + 4.0, OUT_R + 26.0, 5.0
GAP_HALF = math.degrees(math.asin((EXIT_W / 2) / (WALL_IN + 1.5)))
PRACTICE_R, PRACTICE_OUT, PRACTICE_EXIT = 24.0, 27.5, 180  # Roblox angle; Blender = 180-180 = 0 (+X)
# island centre relative to the arena centre (Roblox (-45,80) vs (-40,150)) -> Roblox offset (-5,-70) -> Blender (5,-70)
ISLAND = (5.0, -70.0); ISLAND_A, ISLAND_B = 112.0, 172.0
PRACTICE_OFF = (72.0, -142.0)      # Roblox practice centre (-112, 8) - arena (-40,150) = (-72,-142) -> Blender (72,-142)
PLAZA_OFF = (0.0, -208.0)          # Roblox plaza (-40,-58) -> Blender (0,-208)

ICE = "CDEBFF"; ICE2 = "A9D8FF"; SNOW = "F6FAFF"; WHITE = "F2F6FB"; RED = "E8483D"; YEL = "FFC81E"; BLUE = "3D7BE2"; NAVY = "1F3F7A"
PINK = "FF7FAE"; TEAL = "2FC6C0"; ORANGE = "FF9640"; GOLD = "F2C14E"; STEEL = "3B3F4A"; DARK = "262A33"; WARM = "FFE3A0"; WOOD = "C98A4E"
WALLC = "8FC8F5"; GLASS = "BFE8FF"; ROCKC = "7F92AC"; ROCK2 = "6A7E9A"


def pol(r, deg):
    """Blender point at Roblox angle deg (mapping: Blender angle = 180 - deg)."""
    a = math.radians(180 - deg)
    return (r * math.cos(a), r * math.sin(a))


def in_gap(deg, gaps, half):
    for g in gaps:
        if abs(((deg - g) + 180) % 360 - 180) < half: return True
    return False


def arc_blocks(step, gaps, half, r0, r1):
    """Same segment rule as build_colliders.luau: yields Roblox-angle centres of kept segments."""
    out = []
    a = step / 2
    while a < 360:
        lo, hi = a - step / 2, a + step / 2
        if not (in_gap(lo + 0.01, gaps, half) or in_gap(hi - 0.01, gaps, half) or in_gap(a, gaps, half)): out.append(a)
        a += step
    return out


def seg_box(m, pc, deg, r0, r1, z0, z1, step, part, r=0.25, shrink=0.0):
    rm = (r0 + r1) / 2
    x, y = pol(rm, deg)
    ln = 2 * r1 * math.tan(math.radians(step / 2)) + 0.2 - shrink
    ang = 180 - deg  # Blender angle of the radial direction
    rbox(m, pc, (x, y, (z0 + z1) / 2), (r1 - r0, ln, z1 - z0), r=r, bseg=1, rot=(0, 0, ang), part=part)


def ring_strip(m, pc, r, w, z0, z1, n=72, part="Line", a0=0, a1=360, skip=None):
    for i in range(n):
        d = a0 + (a1 - a0) * (i + 0.5) / n
        if skip and skip(d): continue
        seg_box(m, pc, d, r - w / 2, r + w / 2, z0, z1, (a1 - a0) / n, part, r=0.0)


# ------------------------------------------------------------------ main arena
def ArenaFloor(m):
    cyl(m, P(ICE, "IC"), (0, 0, -1.2), r=FLOOR_R, h=1.2, seg=72, part="Ice")
    cyl(m, P(ICE2), (0, 0, -2.6), r=FLOOR_R - 0.6, r2=FLOOR_R + 0.3, h=1.4, seg=72, part="Rim")
    # centre emblem: big snowflake + rings
    prism(m, P(WHITE), star_poly(6, 9.5, 3.6), 0.06, loc=(0, 0, 0.0), part="Inlay")
    cyl(m, P(BLUE), (0, 0, 0.0), r=3.0, h=0.08, seg=24, part="InlayBlue")
    ring_strip(m, P(WHITE), 14.0, 0.8, 0.0, 0.05, n=64, part="Inlay")
    ring_strip(m, P(BLUE), 30.0, 0.7, 0.0, 0.05, n=96, part="InlayBlue")
    # outer warning band, open only at the exits
    ring_strip(m, P(YEL), WALL_IN - 1.4, 1.2, 0.0, 0.05, n=180, part="Hazard", skip=lambda d: in_gap(d, EXITS, GAP_HALF + 2))
    # exit danger lanes: red/yellow chevrons pointing out through every gap
    for g in EXITS:
        for k in range(7):
            r = 46.5 + k * 2.4
            col = RED if k % 2 == 0 else YEL
            for s in (-1, 1):
                x0, y0 = pol(r, g); x1, y1 = pol(r + 2.4, g + s * 7.5)
                beam(m, P(col), (x0, y0, 0.03), (x1, y1, 0.03), w=1.1, h=0.07, r=0.0, part="Hazard" if col == YEL else "HazardRed")
        x, y = pol(OUT_R + 0.6, g)
        rbox(m, P(RED), (x, y, 0.03), (2.2, EXIT_W - 2, 0.06), r=0.0, rot=(0, 0, 180 - g), part="HazardRed")
    # spawn pads: blue discs with a white arrow pointing at the centre
    for d in PADS:
        x, y = pol(PAD_R, d)
        cyl(m, P(NAVY), (x, y, 0.0), r=4.4, h=0.05, seg=28, part="Pad")
        cyl(m, P(TEAL, "NE"), (x, y, 0.0), r=4.6, r2=4.6, h=0.03, seg=28, part="PadGlow")
        ang = 180 - d + 180  # arrow points toward the centre
        prism(m, P(WHITE), [(-1.6, -1.2), (1.6, -1.2), (0, 2.0)], 0.07, loc=(x, y, 0.0), rot=(0, 0, ang - 90), part="Inlay")
    m.flat("Ice", P(ICE, "IC"), 20)


def WallRing(m):
    blocks = arc_blocks(6, EXITS, GAP_HALF, WALL_IN, WALL_IN + 3)
    for i, d in enumerate(blocks):
        seg_box(m, P(WALLC, "IC"), d, WALL_IN, WALL_IN + 3, 0, 4.0, 6, "Ice", r=0.35, shrink=0.25)
        seg_box(m, P(SNOW), d, WALL_IN - 0.15, WALL_IN + 3.15, 4.0, 4.6, 6, "Snow", r=0.25, shrink=0.05)
        # padded inner cushion (alternating red / white)
        seg_box(m, P(RED if i % 2 == 0 else WHITE), d, WALL_IN - 0.55, WALL_IN, 0.9, 3.1, 6, "Cushion" if i % 2 == 0 else "CushionW", r=0.25, shrink=0.6)
    # big striped posts at every exit edge
    for g in EXITS:
        for s in (-1, 1):
            x, y = pol(WALL_IN + 1.5, g + s * GAP_HALF)
            for k in range(5):
                cyl(m, P(RED if k % 2 == 0 else YEL), (x, y, k * 1.3), r=1.65, h=1.3, seg=16, part="Post" if k % 2 == 0 else "PostY")
            cyl(m, P(RED, "NE"), (x, y, 6.5), r=1.1, h=0.9, seg=12, part="WarnLamp")
            cyl(m, P(SNOW), (x, y, 6.4), r=1.8, r2=1.2, h=0.4, seg=16, part="Snow")
    m.flat("Ice", P(WALLC, "IC"), 25)


def ExitGates(m):
    for g in EXITS:
        ang = 180 - g
        a = math.radians(ang)
        ux, uy = math.cos(a), math.sin(a)          # outward
        tx, ty = -uy, ux                           # tangent
        c = Vector(pol(WALL_IN + 1.5, g))
        w = 2 * (WALL_IN + 1.5) * math.sin(math.radians(GAP_HALF))
        # overhead arch beam + sign boards (inner + outer faces get "EXIT" SurfaceGuis in Studio)
        p0 = c + Vector((tx, ty)) * (w / 2); p1 = c - Vector((tx, ty)) * (w / 2)
        for p in (p0, p1):
            rbox(m, P(STEEL), (p.x, p.y, 7.0 + 2.2), (1.2, 1.2, 4.4), r=0.2, part="Steel")
        beam(m, P(RED), (p0.x, p0.y, 11.2), (p1.x, p1.y, 11.2), w=1.6, h=1.6, r=0.3, part="Arch")
        rbox(m, P(YEL), (c.x, c.y, 13.6), (2.0, 11.0, 3.4), r=0.35, rot=(0, 0, ang), part="Sign")
        rbox(m, P(DARK), (c.x - ux * 1.02, c.y - uy * 1.02, 13.6), (0.06, 10.0, 2.6), r=0.0, rot=(0, 0, ang), part="SignFaceIn")
        rbox(m, P(DARK), (c.x + ux * 1.02, c.y + uy * 1.02, 13.6), (0.06, 10.0, 2.6), r=0.0, rot=(0, 0, ang), part="SignFaceOut")
        for k in (-1, 1):
            q = c + Vector((tx, ty)) * (k * 4.2)
            sphere(m, P(RED, "NE"), (q.x, q.y, 15.7), 0.6, seg=10, part="WarnLamp")
        # outer apron: a short snowy chute that drops off the island edge (visual - the ring-out happens at the wall line)
        for k in range(4):
            r = OUT_R + 1.0 + k * 2.2
            q = c + Vector((ux, uy)) * (r - (WALL_IN + 1.5))
            rbox(m, P(SNOW), (q.x, q.y, -0.4 - k * 0.9), (2.3, w + 1.5 - k * 1.2, 0.8), r=0.3, rot=(0, 0, ang), part="Snow")
        # floor arrows just outside the gap
        for k in range(2):
            q = c + Vector((ux, uy)) * (1.2 + k * 2.2)
            prism(m, P(RED), [(-1.4, -0.9), (1.4, -0.9), (0, 1.3)], 0.06, loc=(q.x, q.y, 0.04), rot=(0, 0, ang - 90), part="HazardRed")


def Stands(m):
    rnd = random.Random(5)
    half = GAP_HALF + 6
    segs = arc_blocks(6, EXITS, half, STAND_IN, STAND_OUT)
    for d in segs:
        seg_box(m, P("EAF2FC"), d, STAND_IN, STAND_OUT, STAND_TOP - 0.6, STAND_TOP, 6, "Deck", r=0.15)
        seg_box(m, P("5B8ED9"), d, STAND_IN + 0.3, STAND_OUT - 0.3, -3.5, STAND_TOP - 0.6, 6, "Base", r=0.3)
        # front glass barrier + snowy rail
        seg_box(m, P(GLASS, "GL", 0.55), d, STAND_IN + 0.2, STAND_IN + 0.6, STAND_TOP, STAND_TOP + 3.4, 6, "Glass", r=0.05, shrink=0.1)
        seg_box(m, P(SNOW), d, STAND_IN + 0.0, STAND_IN + 0.8, STAND_TOP + 3.4, STAND_TOP + 3.9, 6, "Snow", r=0.2)
        # back wall except at the south entrance (Roblox 270 deg)
        if abs(((d - 270) + 180) % 360 - 180) > 7:
            seg_box(m, P("4A78C8"), d, STAND_OUT - 1.2, STAND_OUT, STAND_TOP, STAND_TOP + 3.0, 6, "BackWall", r=0.25)
            seg_box(m, P(SNOW), d, STAND_OUT - 1.4, STAND_OUT + 0.2, STAND_TOP + 3.0, STAND_TOP + 3.5, 6, "Snow", r=0.2)
    # benches: three rows, colourful, with gaps for walking
    cols = [PINK, BLUE, YEL, TEAL, ORANGE]
    for row, r in enumerate((STAND_IN + 5.5, STAND_IN + 11.0, STAND_IN + 16.5)):
        d = 0.0
        while d < 360:
            if not in_gap(d, EXITS, half + 2) and abs(((d - 270) + 180) % 360 - 180) > 8 and rnd.random() > 0.12:
                x, y = pol(r, d)
                ang = 180 - d
                col = cols[rnd.randrange(len(cols))]
                rbox(m, P(col), (x, y, STAND_TOP + 0.75), (1.5, 5.0, 0.5), r=0.2, rot=(0, 0, ang), part="Bench" + col)
                bx, by = pol(r + 0.75, d)
                rbox(m, P(col), (bx, by, STAND_TOP + 1.5), (0.4, 5.0, 1.2), r=0.15, rot=(0, 0, ang), part="Bench" + col)
                rbox(m, P(STEEL), (x, y, STAND_TOP + 0.25), (1.0, 4.2, 0.5), r=0.0, rot=(0, 0, ang), part="Steel")
            d += 360 / (2 * math.pi * r / 6.5)
    # banner poles along the back wall (pennants in Studio-tinted colours)
    for i, d in enumerate([d for d in range(0, 360, 12) if not in_gap(d, EXITS, half + 3) and abs(((d - 270) + 180) % 360 - 180) > 10]):
        x, y = pol(STAND_OUT - 0.6, d)
        rod(m, P(STEEL), (x, y, STAND_TOP + 3.0), (x, y, STAND_TOP + 14.0), r=0.22, seg=8, part="Steel")
        sphere(m, P(GOLD, "ME"), (x, y, STAND_TOP + 14.2), 0.45, seg=10, part="Gold")
        col = [RED, BLUE, YEL, TEAL, PINK][i % 5]
        ang = 180 - d
        nx, ny = math.cos(math.radians(ang)), math.sin(math.radians(ang))
        tx, ty = -ny, nx
        pts = [(0, 0), (0, -5.2), (1.4, -4.2), (2.8, -5.2), (2.8, 0)]
        verts = []
        for (u, v) in pts:
            verts.append((x + tx * (u - 1.4) - nx * 0.25, y + ty * (u - 1.4) - ny * 0.25, STAND_TOP + 13.6 + v))
        mesh(m, P(col, "FA"), verts, [list(range(len(verts))), list(reversed(range(len(verts))))], part="Flag" + col, recalc=False)


def Jumbotron(m):
    z0 = 30.0
    # cube scoreboard with four screens (SurfaceGuis in Studio show the timer + leader)
    rbox(m, P(NAVY), (0, 0, z0 + 5), (15, 15, 10), r=0.8, bseg=2, part="Body")
    for k in range(4):
        a = math.radians(90 * k)
        nx, ny = math.cos(a), math.sin(a)
        rbox(m, P("0E1B33"), (nx * 7.55, ny * 7.55, z0 + 5), (0.1, 12, 7), r=0.0, rot=(0, 0, 90 * k), part="Screen%d" % k)
        rbox(m, P(GOLD, "ME"), (nx * 7.6, ny * 7.6, z0 + 9.2), (0.3, 13, 0.6), r=0.1, rot=(0, 0, 90 * k), part="Gold")
        rbox(m, P(GOLD, "ME"), (nx * 7.6, ny * 7.6, z0 + 0.8), (0.3, 13, 0.6), r=0.1, rot=(0, 0, 90 * k), part="Gold")
    # ice crown on top
    cyl(m, P(GOLD, "ME"), (0, 0, z0 + 10), r=7.0, r2=6.4, h=1.4, seg=24, part="Gold")
    for k in range(8):
        a = 2 * math.pi * k / 8
        crystal(m, P(ICE2, "GL", 0.15), (math.cos(a) * 5.4, math.sin(a) * 5.4, z0 + 11.2), (math.cos(a) * 6.2, math.sin(a) * 6.2, z0 + 16 + (k % 2) * 2.5), 1.2, part="Crown")
    crystal(m, P("E7F6FF", "GL", 0.1), (0, 0, z0 + 11), (0, 0, z0 + 21), 2.2, part="Crown")
    prism(m, P(SNOW, "NE"), star_poly(6, 2.0, 0.8), 0.4, loc=(0, -0.2, z0 + 21.5), rot=(90, 0, 0), part="Star")
    # glow ring under it
    torus(m, P(TEAL, "NE"), (0, 0, z0 - 0.4), R=6.5, r=0.35, seg=32, rseg=8, part="Glow")
    cyl(m, P(NAVY), (0, 0, z0 - 1.2), r=4.0, r2=7.0, h=1.2, seg=24, part="Body")


def LightTowers(m):
    for d in (0, 90, 180, 270):
        x, y = pol(STAND_OUT + 7, d)
        ang = 180 - d
        nx, ny = -math.cos(math.radians(ang)), -math.sin(math.radians(ang))  # toward the centre
        for sx in (-1, 1):
            for sy in (-1, 1):
                rod(m, P(STEEL), (x + sx * 1.6, y + sy * 1.6, -4), (x + sx * 0.7, y + sy * 0.7, 30), r=0.3, seg=6, part="Steel")
        for z in range(0, 30, 6):
            for (ax, ay, bx, by) in ((-1, -1, 1, 1), (1, -1, -1, 1)):
                k0 = 1.6 - 0.9 * (z / 34); k1 = 1.6 - 0.9 * ((z + 6) / 34)
                rod(m, P(STEEL), (x + ax * k0, y + ay * k0, z), (x + bx * k1, y + by * k1, z + 6), r=0.12, seg=5, part="Steel")
        rbox(m, P(DARK), (x + nx * 0.6, y + ny * 0.6, 32), (5.2, 5.2, 3.6), r=0.4, rot=(0, 0, ang), part="Head")
        for i in range(3):
            for j in range(2):
                ox = -ny * (i - 1) * 1.5; oy = nx * (i - 1) * 1.5
                q = (x + nx * 3.0 + ox, y + ny * 3.0 + oy, 31.2 + j * 1.6)
                disc(m, P(WARM, "NE"), q, 0.6, 0.2, axis=(nx, ny, -0.35), seg=10, part="Lamp")
        cyl(m, P(SNOW), (x + nx * 0.6, y + ny * 0.6, 33.8), r=3.4, r2=2.6, h=0.6, seg=12, part="Snow")


# ------------------------------------------------------------------ island + practice ring
def Island(m):
    cx, cy = ISLAND
    island_se(m, P(ROCKC), (cx, cy, 0), a=ISLAND_A + 0.6, b=ISLAND_B + 0.6, depth=70, n=5, seed=11, seg=72, rings=7, jag=0.12, part="Rock", top=-1.4)
    turf_se(m, P(SNOW), (cx, cy, 0), a=ISLAND_A, b=ISLAND_B, n=5, thick=1.0, seg=96, part="Snow", top=-0.5)
    m.flat("Rock", P(ROCKC), 30)
    rnd = random.Random(21)
    # snowy lip + scattered snowbanks / ice rocks on free ground (kept clear of the arena, stands, practice ring, paths)
    def free(x, y):
        if math.hypot(x, y) < STAND_OUT + 12: return False
        if math.hypot(x - PRACTICE_OFF[0], y - PRACTICE_OFF[1]) < PRACTICE_OUT + 8: return False
        if abs(x) < 12 and -220 < y < -60: return False          # walkway corridor
        if abs(x - PLAZA_OFF[0]) < 42 and abs(y - PLAZA_OFF[1]) < 26: return False
        return True
    for i in range(70):
        ang = 2 * math.pi * i / 70
        x, y = se_point(ISLAND_A - 2.5, ISLAND_B - 2.5, ang, 5)
        x += cx; y += cy
        if free(x, y):
            sphere(m, P(SNOW), (x, y, -0.7), 2.2 + rnd.random() * 1.4, scl=(1.5, 1.5, 0.5), seg=8, rings=5, part="Snow")
    n = 0
    while n < 26:
        x = cx + rnd.uniform(-ISLAND_A + 12, ISLAND_A - 12); y = cy + rnd.uniform(-ISLAND_B + 12, ISLAND_B - 12)
        if abs(x - cx) / ISLAND_A + abs(y - cy) / ISLAND_B > 0.92 or not free(x, y): continue
        if rnd.random() < 0.55:
            blob(m, P(SNOW), (x, y, -0.6), rad=2.0 + rnd.random() * 2.0, n=4, seed=n, spread=(1.2, 1.2, 0.35), flat=0.55, seg=8, rings=5, part="Snow")
        else:
            rock(m, P(ICE2, "IC"), (x, y, 0.4), size=(1.6 + rnd.random(), 1.4 + rnd.random(), 1.6 + rnd.random() * 1.5), seed=n, sub=1, jag=0.2, part="IceRock")
        n += 1
    m.flat("IceRock", P(ICE2, "IC"), 1)


def PracticeRing(m):
    # built around the practice centre (its own origin)
    cyl(m, P(ICE, "IC"), (0, 0, -1.2), r=PRACTICE_OUT + 2, h=1.2, seg=48, part="Ice")
    cyl(m, P(ICE2), (0, 0, -2.4), r=PRACTICE_OUT + 1.4, r2=PRACTICE_OUT + 2.2, h=1.2, seg=48, part="Rim")
    for k, (r, col) in enumerate(((11, RED), (7.5, WHITE), (4, RED))):
        cyl(m, P(col), (0, 0, 0.0), r=r, h=0.04 + k * 0.01, seg=36, part="Target" + col)
    half = math.degrees(math.asin((16 / 2) / (PRACTICE_R + 1)))
    blocks = arc_blocks(10, [PRACTICE_EXIT], half, PRACTICE_R, PRACTICE_R + 2)
    for i, d in enumerate(blocks):
        seg_box(m, P(WALLC, "IC"), d, PRACTICE_R, PRACTICE_R + 2, 0, 3.4, 10, "Ice", r=0.3, shrink=0.3)
        seg_box(m, P(SNOW), d, PRACTICE_R - 0.1, PRACTICE_R + 2.1, 3.4, 3.9, 10, "Snow", r=0.2)
        seg_box(m, P(YEL if i % 2 == 0 else WHITE), d, PRACTICE_R - 0.45, PRACTICE_R, 0.8, 2.6, 10, "Cushion" if i % 2 == 0 else "CushionW", r=0.2, shrink=0.8)
    for s in (-1, 1):
        x, y = pol(PRACTICE_R + 1, PRACTICE_EXIT + s * half)
        for k in range(4):
            cyl(m, P(RED if k % 2 == 0 else YEL), (x, y, k * 1.2), r=1.2, h=1.2, seg=14, part="Post" if k % 2 == 0 else "PostY")
    # "PRACTICE" sign arch on the far side (opposite the exit)
    x, y = pol(PRACTICE_R + 4.5, 0)
    for s in (-1, 1):
        rod(m, P(STEEL), (x, y + s * 5, 0), (x, y + s * 5, 9), r=0.35, seg=8, part="Steel")
    rbox(m, P(TEAL), (x, y, 9.4), (1.2, 12, 2.6), r=0.3, part="Sign")
    rbox(m, P(DARK), (x + 0.62, y, 9.4), (0.06, 11, 1.9), r=0.0, part="SignFaceIn")


# ------------------------------------------------------------------ props
def Target(m):
    """Training dummy puck: fits the 7x7 server footprint, base at z=0."""
    cyl(m, P(RED), (0, 0, 0.4), r=3.4, h=1.0, seg=28, bev=0.3, part="Cushion")
    torus(m, P(WHITE), (0, 0, 1.2), R=3.1, r=0.45, seg=28, rseg=8, part="Ring")
    cyl(m, P(YEL), (0, 0, 1.3), r=3.0, h=0.9, seg=28, bev=0.3, part="CushionY")
    torus(m, P(RED), (0, 0, 2.2), R=2.7, r=0.4, seg=28, rseg=8, part="Cushion")
    # snowman on top
    sphere(m, P(SNOW), (0, 0, 3.6), 1.6, seg=14, part="Snow")
    sphere(m, P(SNOW), (0, 0, 5.6), 1.15, seg=14, part="Snow")
    rod(m, P(ORANGE), (0, -1.05, 5.65), (0, -2.0, 5.6), r=0.18, r2=0.02, seg=8, part="Nose")
    for sx in (-0.4, 0.4): sphere(m, P(DARK), (sx, -1.0, 5.95), 0.13, seg=8, part="Eyes")
    cyl(m, P(DARK), (0, 0, 6.5), r=0.95, h=0.18, seg=16, part="Hat")
    cyl(m, P(DARK), (0, 0, 6.6), r=0.62, h=1.1, seg=16, part="Hat")
    cyl(m, P(RED), (0, 0, 6.75), r=0.64, h=0.25, seg=16, part="Band")
    # bullseye on the top cushion face
    cyl(m, P(WHITE), (0, 0, 2.21), r=2.2, h=0.03, seg=24, part="Ring")


def Bumper(m):
    """Arena vehicle bumper ring around the normalized 8.6 x 13.2 footprint (origin = footprint centre at floor level)."""
    W, Lg, R, z = 8.6, 13.2, 0.6, 1.75
    hw, hl, c = W / 2 - R, Lg / 2 - R, 1.6
    pts = []
    for (cx, cy, a0) in ((hw - c, -hl + c, 270), (hw - c, hl - c, 0), (-hw + c, hl - c, 90), (-hw + c, -hl + c, 180)):
        for k in range(5):
            a = math.radians(a0 + 90 * k / 4)
            pts.append((cx + math.cos(a) * c, cy + math.sin(a) * c, z))
    tube(m, P(RED), pts, r=R, seg=10, part="TintBumper", closed=True, smooth=2)
    tube(m, P(DARK), [(x, y, z - 0.55) for (x, y, _) in pts], r=0.28, seg=8, part="Rubber", closed=True, smooth=2)
    # front ram pad (front = -Y) with white chevrons
    rbox(m, P(RED), (0, -Lg / 2 + 0.3, z + 0.1), (W - 1.4, 1.2, 1.7), r=0.5, bseg=2, part="TintBumper")
    rbox(m, P(DARK), (0, -Lg / 2 + 0.25, z - 0.65), (W - 1.2, 1.3, 0.4), r=0.15, part="Rubber")
    for sx in (-1.6, 1.6):
        prism(m, P(WHITE), [(-0.9, -0.5), (0, 0.1), (0.9, -0.5), (0.9, -0.05), (0, 0.55), (-0.9, -0.05)], 0.08, loc=(sx, -Lg / 2 - 0.31, z + 0.1), rot=(90, 0, 0), part="Chevron")
    # rear lights
    for sx in (-2.6, 2.6):
        rbox(m, P(RED, "NE"), (sx, Lg / 2 - 0.05, z + 0.2), (1.0, 0.25, 0.45), r=0.08, part="Light")


def Portal(m):
    """Arena portal arch (lobby / garage / island return); prompt goes on the PortalPad part."""
    rbox(m, P("5B8ED9"), (0, 0, 0.35), (16, 7, 0.7), r=0.3, part="Base")
    rbox(m, P(SNOW), (0, 0, 0.75), (15.4, 6.4, 0.2), r=0.1, part="Snow")
    pts = arch_poly(13.0, 15.0, n=10)
    flat(m, P(WALLC, "IC"), [(x * 1.18, y * 1.05) for x, y in pts], 2.2, (0, 1.1, 0.7), axis=(0, -1, 0), part="Ice", bev=0.25)
    # inner opening (neon swirl)
    inner = arch_poly(9.6, 12.4, n=10)
    flat(m, P(TEAL, "NE", 0.15), inner, 0.3, (0, -1.1, 1.1), axis=(0, -1, 0), part="Swirl")
    for k, r in enumerate((4.2, 3.0, 1.8)):
        torus(m, P(WHITE if k % 2 else "8FF5EE", "NE"), (0, -1.65, 6.8), R=r, r=0.16, seg=28, rseg=6, rot=(90, 0, k * 25), part="Rings")
    # sign board above
    rbox(m, P(GOLD), (0, -0.2, 17.6), (12.5, 1.0, 2.8), r=0.4, part="Sign")
    rbox(m, P(DARK), (0, -0.74, 17.6), (11.6, 0.06, 2.1), r=0.0, part="SignFaceIn")
    for sx in (-7.4, 7.4):
        cyl(m, P(SNOW), (sx, 0, 0.7), r=1.4, r2=1.1, h=0.6, seg=12, part="Snow")
        sphere(m, P(WARM, "NE"), (sx, -0.8, 13.5), 0.55, seg=10, part="Lamp")
    rbox(m, P(WHITE, "SP", 1.0), (0, -2.0, 1.2), (8, 3, 0.8), r=0.0, part="PortalPad")


def Trophy(m):
    rbox(m, P("5B8ED9"), (0, 0, 1.6), (6.5, 6.5, 3.2), r=0.5, bseg=2, part="Plinth")
    rbox(m, P(SNOW), (0, 0, 3.3), (6.9, 6.9, 0.4), r=0.25, part="Snow")
    rbox(m, P(DARK), (0, -3.27, 1.7), (5.2, 0.06, 1.6), r=0.0, part="SignFaceIn")
    lathe(m, P(GOLD, "ME"), [(2.0, 3.5), (2.2, 3.9), (0.8, 4.5), (0.6, 6.5), (1.6, 7.2), (3.0, 8.8), (3.4, 10.8), (3.1, 11.0), (2.8, 9.2), (0, 8.4)], seg=24, part="Gold")
    for s in (-1, 1):
        torus(m, P(GOLD, "ME"), (s * 3.4, 0, 9.4), R=1.1, r=0.25, seg=16, rseg=6, rot=(90, 0, 0), part="Gold")
    # mini snowplow on top of the cup
    rbox(m, P(RED), (0, 0.2, 11.6), (2.4, 3.6, 1.0), r=0.3, part="Plow")
    rbox(m, P(BLUE), (0, 0.6, 12.5), (1.8, 1.6, 1.0), r=0.3, part="Cab")
    rbox(m, P("C9D2DE", "ME"), (0, -2.1, 11.5), (3.4, 0.4, 1.2), r=0.15, rot=(10, 0, 0), part="Blade")
    for sx in (-1.2, 1.2):
        for sy in (-0.8, 1.2):
            cyl(m, P(DARK), (sx - 0.25, sy, 11.2), r=0.45, h=0.5, seg=10, rot=(0, 90, 0), part="Wheels")


def Lamp(m):
    rbox(m, P(STEEL), (0, 0, 0.3), (1.2, 1.2, 0.6), r=0.2, part="Steel")
    rod(m, P(STEEL), (0, 0, 0.5), (0, 0, 7.5), r=0.18, seg=8, part="Steel")
    cyl(m, P(STEEL), (0, 0, 7.4), r=0.5, h=0.2, seg=10, part="Steel")
    cyl(m, P(WARM, "NE"), (0, 0, 7.6), r=0.42, h=1.0, seg=10, part="Glow")
    cyl(m, P(STEEL), (0, 0, 8.6), r=0.62, r2=0.12, h=0.45, seg=10, part="Steel")
    cyl(m, P(SNOW), (0, 0, 8.7), r=0.5, r2=0.15, h=0.3, seg=10, part="Snow")


def Banner(m):
    rod(m, P(STEEL), (0, 0, 0), (0, 0, 10.5), r=0.2, seg=8, part="Steel")
    sphere(m, P(GOLD, "ME"), (0, 0, 10.7), 0.4, seg=10, part="Gold")
    rod(m, P(STEEL), (0, 0, 10.0), (2.8, 0, 10.0), r=0.1, seg=6, part="Steel")
    verts = [(0.15, 0, 10.0), (2.75, 0, 10.0), (2.75, 0, 5.4), (1.45, 0, 6.4), (0.15, 0, 5.4)]
    mesh(m, P(RED, "FA"), verts, [list(range(5)), list(reversed(range(5)))], part="TintBanner", recalc=False)
    rbox(m, P(SNOW), (0, 0, 0.15), (1.4, 1.4, 0.3), r=0.15, part="Snow")


def SnowBank(m):
    blob(m, P(SNOW), (0, 0, 0.0), rad=3.0, n=5, seed=3, spread=(1.4, 1.0, 0.35), flat=0.55, seg=10, rings=6, part="Snow")
    blob(m, P(ICE2, "IC"), (1.8, 0.6, 0.2), rad=1.0, n=2, seed=5, spread=(1, 1, 0.4), flat=0.9, seg=7, rings=5, part="Ice")


BUILDERS = {"ArenaFloor": ArenaFloor, "WallRing": WallRing, "ExitGates": ExitGates, "Stands": Stands, "Jumbotron": Jumbotron, "LightTowers": LightTowers,
            "Island": Island, "PracticeRing": PracticeRing,
            "Target": Target, "Bumper": Bumper, "Portal": Portal, "Trophy": Trophy, "Lamp": Lamp, "Banner": Banner, "SnowBank": SnowBank}
