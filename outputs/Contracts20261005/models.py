# models.py - NPC clearing-contract ("Help Yard") models (Claude, 2026-10-05). One builder per model; each takes a w2lib.Model.
# 1 unit = 1 stud, front = -Y (Roblox -Z), up = +Z, model origin = floor-level centre. Studio maps Blender (x,y,z) -> Roblox (-x, z, y).
# Parts whose name starts with Tint* are recoloured per biome / per instance in Studio (Ground, Rock, Accent, Trim, Body).
import sys, math, random
from mathutils import Vector
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\PlowExpansion20261005\parts")
import w2lib as L
from w2lib import P, Mx, sphere, rbox, cyl, lathe, tube, torus, prism, rock, island_se, turf_se, se_point
from partlib import beam, rod, flat, disc, mesh, arch_poly, box_m, tire, wheel_disc, circle_poly, star_poly

SNOW = "F6FAFF"; ICE = "9FD8FF"; RED = "E2483D"; ORA = "F2A23D"; YEL = "FFD23A"; STEEL = "3B3F4A"; WOOD = "E09A5A"
WOOD2 = "A9622F"; CREAM = "FFF3D6"; SILVER = "C9D2DE"; BULB = "FFE3A0"; WHITE = "F2F4F7"; ROCK = "7F92AC"; GREEN = "2F9E62"
GLASS = "BFE8FF"; DARK = "2A2E38"; BLUE = "3D7BE2"; PINK = "FF7FAE"; TEAL = "2FC6C0"; BROWN = "8A5530"; WARM = "FFC86B"
# neutral placeholder colours for tinted parts (Studio overrides them)
T_GROUND = "F2F7FF"; T_ROCK = "7F92AC"; T_ACCENT = "E2483D"; T_TRIM = "FFD23A"; T_BODY = "E2483D"


def bx(m, part, col, x0, x1, y0, y1, z0, z1, r=0.15, bseg=1, mat="SP", rot=(0, 0, 0)):
    rbox(m, P(col, mat), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), r=r, bseg=bseg, part=part, rot=rot)


def snowcap(m, x0, x1, y0, y1, z, t=0.35, ov=0.12, part="Snow"):
    bx(m, part, SNOW, x0 - ov, x1 + ov, y0 - ov, y1 + ov, z - 0.05, z + t, r=min(0.18, t * 0.45), bseg=2)


def gable(m, part, col, x0, x1, y0, y1, z0, h, over=0.6, thick=0.45):
    """Gable roof along X: two slabs meeting at the ridge (y centre)."""
    yc = (y0 + y1) / 2; half = (y1 - y0) / 2 + over
    ang = math.degrees(math.atan2(h, half)); L_ = math.hypot(h, half)
    for s in (-1, 1):
        rbox(m, P(col), ((x0 + x1) / 2, yc + s * half / 2, z0 + h / 2), (x1 - x0 + over * 2, L_, thick), r=0.12, part=part, rot=(s * -ang, 0, 0))
    return yc, half, ang, L_


def gable_snow(m, x0, x1, y0, y1, z0, h, over=0.6):
    yc = (y0 + y1) / 2; half = (y1 - y0) / 2 + over
    ang = math.degrees(math.atan2(h, half)); L_ = math.hypot(h, half)
    for s in (-1, 1):
        rbox(m, P(SNOW), ((x0 + x1) / 2, yc + s * half / 2 * 0.98, z0 + h / 2 + 0.38), (x1 - x0 + over * 2 + 0.2, L_ * 0.96, 0.4), r=0.18, bseg=2, part="Snow", rot=(s * -ang, 0, 0))


def lantern(m, x, y, z, part="Lamp", col=WARM):
    cyl(m, P(STEEL), (x, y, z), r=0.32, h=0.16, seg=8, part="Steel")
    cyl(m, P(col, "NE"), (x, y, z + 0.16), r=0.26, h=0.6, seg=8, part=part)
    cyl(m, P(STEEL), (x, y, z + 0.76), r=0.36, r2=0.08, h=0.3, seg=8, part="Steel")


def window(m, x, y, z, w=1.8, h=1.8, part="Window", frame=WHITE, face=-1):
    """Glowing window on a wall facing -Y (face=-1) or +Y (face=1); y = wall surface."""
    d = 0.12 * face
    bx(m, "Trim", frame, x - w / 2 - 0.18, x + w / 2 + 0.18, *sorted((y, y + d * 1.6)), z - 0.18, z + h + 0.18, r=0.05)
    bx(m, part, BULB, x - w / 2, x + w / 2, *sorted((y + d * 1.6, y + d * 2.2)), z, z + h, r=0.03, mat="NE")
    bx(m, "Trim", frame, x - 0.07, x + 0.07, *sorted((y + d * 2.0, y + d * 2.6)), z, z + h, r=0.02)
    bx(m, "Trim", frame, x - w / 2, x + w / 2, *sorted((y + d * 2.0, y + d * 2.6)), z + h / 2 - 0.07, z + h / 2 + 0.07, r=0.02)


# ------------------------------------------------------------------ yard pieces
def YardPad(m):
    a, b = 36.0, 30.0
    turf_se(m, P(T_GROUND), (0, 0, 0), a=a, b=b, n=8, thick=1.0, seg=64, part="TintGround", top=0.0)
    island_se(m, P(T_ROCK), (0, 0, 0), a=a + 0.6, b=b + 0.6, depth=24, n=6, seed=7, seg=56, rings=6, jag=0.1, part="TintRock", top=-0.9)
    m.flat("TintRock", P(T_ROCK), 30)
    # snowy lip under the turf edge
    for i in range(48):
        ang = 2 * math.pi * i / 48
        x, y = se_point(a - 0.3, b - 0.3, ang, 8)
        if y < -b + 2 and abs(x) < 16.5: continue
        sphere(m, P(SNOW), (x, y, -0.65), 1.0, scl=(1.6, 1.6, 0.55), seg=8, rings=5, part="Snow")
    # low stone curb around the pad except the gate gap (|x| < 16.5 at the front)
    rnd = random.Random(3)
    def curb_run(p0, p1, n):
        for k in range(n):
            t = (k + 0.5) / n
            x, y = p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t
            rock(m, P(T_ROCK), (x, y, 0.45), size=(1.15 + rnd.uniform(0, 0.25), 1.0, 0.8), seed=k + int(x * 7 + y * 3), sub=1, jag=0.12, part="TintCurb")
            sphere(m, P(SNOW), (x, y, 1.1), 0.75, scl=(1.35, 1.1, 0.42), seg=7, rings=4, part="Snow")
    curb_run((-35, -29), (-35, 29), 26); curb_run((35, -29), (35, 29), 26); curb_run((-34, 29), (34, 29), 30)
    curb_run((-34, -29), (-17, -29), 8); curb_run((17, -29), (34, -29), 8)
    m.flat("TintCurb", P(T_ROCK), 30)


def YardGate(m):
    """Help Yard gate: posts at x=+-16.5, clear opening |x|<15.2, height 10."""
    for sx in (-1, 1):
        x = sx * 16.5
        bx(m, "TintRock", T_ROCK, x - 1.5, x + 1.5, -1.5, 1.5, 0, 1.2, r=0.3, bseg=2)
        bx(m, "TintAccent", T_ACCENT, x - 1.15, x + 1.15, -1.15, 1.15, 1.2, 10.4, r=0.35, bseg=2)
        for z in (3.0, 6.0, 9.0):
            bx(m, "TintTrim", T_TRIM, x - 1.25, x + 1.25, -1.25, 1.25, z, z + 0.45, r=0.15)
        bx(m, "TintTrim", T_TRIM, x - 1.4, x + 1.4, -1.4, 1.4, 10.4, 11.0, r=0.2)
        sphere(m, P(SNOW), (x, 0, 11.2), 1.5, scl=(1, 1, 0.55), seg=10, rings=6, part="Snow")
        lantern(m, x - sx * 1.6, -1.2, 7.2, part="Lamp")
        rod(m, P(STEEL), (x - sx * 1.15, -1.2, 8.3), (x - sx * 1.6, -1.2, 8.3), r=0.08, seg=6, part="Steel")
    # arched beam
    pts = []
    for i in range(13):
        t = i / 12; x = -16.5 + 33 * t
        pts.append((x, 0, 11.0 + 1.6 * math.sin(math.pi * t)))
    tube(m, P(T_ACCENT), pts, r=0.75, seg=10, part="TintAccent", smooth=2)
    tube(m, P(SNOW), [(p[0], p[1], p[2] + 0.55) for p in pts[1:-1]], r=0.55, seg=8, part="Snow", smooth=2, sq=0.6)
    # sign board (Studio adds the text): Sign part faces -Y
    bx(m, "TintTrim", T_TRIM, -7.4, 7.4, -0.9, -0.4, 12.0, 15.2, r=0.4, bseg=2)
    bx(m, "Sign", CREAM, -6.9, 6.9, -1.0, -0.85, 12.4, 14.8, r=0.2)
    snowcap(m, -7.4, 7.4, -0.9, -0.4, 15.2, t=0.45)
    for x in (-7.8, 7.8):
        rod(m, P(STEEL), (x * 0.92, -0.65, 11.3), (x * 0.92, -0.65, 12.2), r=0.1, seg=6, part="Steel")
    # string of bulbs under the arch
    for i in range(1, 12):
        t = i / 12; x = -15 + 30 * t
        sphere(m, P([YEL, PINK, TEAL, ORA][i % 4], "NE"), (x, -0.2, 10.3 + 1.1 * math.sin(math.pi * t) - 0.4), 0.28, seg=6, rings=4, part="Bulbs")


def YardBridge(m):
    """Path tile 30 wide, 12 deep (stretched along Y in Studio), top at z=0."""
    bx(m, "TintGround", T_GROUND, -15, 15, -6, 6, -1.2, 0.0, r=0.1)
    for sx in (-1, 1):
        bx(m, "TintRock", T_ROCK, sx * 15 - 0.9, sx * 15 + 0.9, -6, 6, -1.6, 0.9, r=0.3, bseg=2)
        bx(m, "Snow", SNOW, sx * 15 - 1.0, sx * 15 + 1.0, -6, 6, 0.85, 1.25, r=0.18, bseg=2)
    bx(m, "TintRock", T_ROCK, -15.5, 15.5, -6, 6, -3.2, -1.2, r=0.4, bseg=2)


# ------------------------------------------------------------------ homes / road
def Cottage(m):
    W, D, H = 7.0, 5.0, 6.0  # half width (x), half depth (y), wall height
    bx(m, "TintRock", T_ROCK, -W - 0.2, W + 0.2, -D - 0.2, D + 0.2, 0, 0.8, r=0.2)
    bx(m, "TintBody", T_BODY, -W, W, -D, D, 0.8, H, r=0.18)
    bx(m, "Trim", WHITE, -W - 0.15, W + 0.15, -D - 0.15, D + 0.15, H - 0.35, H, r=0.1)
    for sx in (-1, 1):
        bx(m, "Trim", WHITE, sx * W - 0.3, sx * W + 0.3, -D - 0.3, -D + 0.3, 0.8, H, r=0.08)
        bx(m, "Trim", WHITE, sx * W - 0.3, sx * W + 0.3, D - 0.3, D + 0.3, 0.8, H, r=0.08)
    # gable ends (triangles) + roof
    tri = [(-D - 0.1, 0), (D + 0.1, 0), (0, 3.4)]
    for sx in (-1, 1):
        prism(m, P(T_BODY), [(p[0], p[1]) for p in tri], 0.4, loc=(sx * W - 0.2, 0, H), rot=(90, 0, 90), part="TintBody")
    gable(m, "Roof", "9E3B33", -W, W, -D, D, H, 3.4, over=0.9, thick=0.5)
    gable_snow(m, -W, W, -D, D, H, 3.4, over=0.9)
    # chimney
    bx(m, "Brick", "B5523C", 3.2, 4.6, 0.8, 2.2, H + 1.2, H + 5.0, r=0.1, mat="BR")
    snowcap(m, 3.2, 4.6, 0.8, 2.2, H + 5.0, t=0.4)
    # door + porch (front = -Y)
    bx(m, "Door", "7A4A2A", -1.0, 1.0, -D - 0.12, -D + 0.05, 0.8, 4.2, r=0.08, mat="WO")
    sphere(m, P(YEL, "ME"), (0.65, -D - 0.2, 2.4), 0.13, seg=6, rings=4, part="Knob")
    bx(m, "Wood", WOOD, -2.6, 2.6, -D - 2.4, -D, 0.0, 0.8, r=0.12, mat="WO")
    bx(m, "Wood", WOOD, -2.0, 2.0, -D - 3.1, -D - 2.4, 0.0, 0.4, r=0.1, mat="WO")
    for sx in (-1, 1):
        bx(m, "Trim", WHITE, sx * 2.3 - 0.18, sx * 2.3 + 0.18, -D - 2.3, -D - 1.9, 0.8, 4.6, r=0.06)
    rbox(m, P("9E3B33"), (0, -D - 1.3, 4.85), (5.6, 2.9, 0.3), r=0.1, part="Roof", rot=(-12, 0, 0))
    rbox(m, P(SNOW), (0, -D - 1.3, 5.12), (5.7, 2.9, 0.3), r=0.12, bseg=2, part="Snow", rot=(-12, 0, 0))
    sphere(m, P(WARM, "NE"), (1.6, -D - 0.25, 3.9), 0.28, seg=8, rings=5, part="PorchLamp")
    cyl(m, P(STEEL), (1.6, -D - 0.25, 4.1), r=0.2, h=0.25, seg=6, part="Steel")
    # windows
    for x in (-4.4, 4.4):
        window(m, x, -D, 2.2, w=2.2, h=2.0)
        bx(m, "Wood", WOOD, x - 1.4, x + 1.4, -D - 0.7, -D, 1.75, 2.15, r=0.08, mat="WO")
        sphere(m, P(SNOW), (x, -D - 0.4, 2.3), 0.35, scl=(3.6, 1, 0.7), seg=8, rings=4, part="Snow")
    for sx in (-1, 1):
        for y in (-2.2, 2.2):
            pass
    # snow drifts against the walls
    for x, y in ((-W - 0.6, -2), (W + 0.6, 1.5), (-3, D + 0.6), (3.5, D + 0.6)):
        sphere(m, P(SNOW), (x, y, 0.4), 1.2, scl=(1.2, 1.2, 0.6), seg=8, rings=5, part="Snow")


def Mailbox(m):
    bx(m, "Wood", WOOD2, -0.18, 0.18, -0.18, 0.18, 0, 3.2, r=0.06, mat="WO")
    bx(m, "TintBody", T_BODY, -0.55, 0.55, -0.9, 0.9, 3.2, 4.0, r=0.3, bseg=2)
    cyl(m, P(T_BODY), (0, -0.9, 4.0), r=0.55, h=1.8, seg=12, rot=(-90, 0, 0), part="TintBody")
    bx(m, "Flag", RED, 0.55, 0.65, 0.2, 0.3, 3.6, 4.9, r=0.02)
    bx(m, "Flag", RED, 0.55, 0.65, 0.3, 0.9, 4.4, 4.9, r=0.02)
    snowcap(m, -0.6, 0.6, -0.95, 0.95, 4.5, t=0.3)


def PicketFence(m):
    for i in range(7):
        x = -3 + i
        bx(m, "Fence", WHITE, x - 0.2, x + 0.2, -0.1, 0.1, 0, 2.0, r=0.06)
        sphere(m, P(WHITE), (x, 0, 2.05), 0.22, scl=(1, 0.5, 1), seg=6, rings=4, part="Fence")
        sphere(m, P(SNOW), (x, 0, 2.25), 0.2, scl=(1.2, 1, 0.6), seg=6, rings=3, part="Snow")
    for z in (0.6, 1.5):
        bx(m, "Fence", WHITE, -3.2, 3.2, 0.1, 0.25, z, z + 0.25, r=0.04)
        snowcap(m, -3.2, 3.2, 0.1, 0.25, z + 0.25, t=0.12, ov=0.05)


def RoadSign(m):
    cyl(m, P(SILVER, "ME"), (0, 0, 0), r=0.14, h=4.4, seg=8, part="Pole")
    rbox(m, P(YEL), (0, -0.16, 4.6), (2.1, 0.1, 2.1), r=0.12, part="Sign", rot=(0, 45, 0))
    rbox(m, P(DARK), (0, -0.06, 4.6), (2.3, 0.1, 2.3), r=0.12, part="Edge", rot=(0, 45, 0))
    # bend arrow
    pts = [(-0.4, -0.28, 4.1), (-0.4, -0.28, 4.6), (-0.1, -0.28, 4.95), (0.35, -0.28, 4.95)]
    tube(m, P(DARK), pts, r=0.1, seg=6, part="Arrow", smooth=3)
    prism(m, P(DARK), [(0, -0.3), (0.45, 0), (0, 0.3)], 0.1, loc=(0.35, -0.24, 4.95), rot=(90, 0, 0), part="Arrow")
    sphere(m, P(SNOW), (0, -0.1, 5.95), 0.35, scl=(1.6, 0.8, 0.5), seg=8, rings=4, part="Snow")


def RoadClosed(m):
    for sx in (-1, 1):
        for sy in (-1, 1):
            rod(m, P(WOOD2), (sx * 2.2, sy * 0.7, 0), (sx * 2.2, sy * 0.15, 2.6), r=0.12, seg=6, part="Legs")
    for z, col in ((2.2, RED), (1.4, WHITE)):
        bx(m, "Stripes", col, -2.6, 2.6, -0.12, 0.12, z, z + 0.65, r=0.08)
    for i in range(5):
        x = -2.1 + i * 1.05
        bx(m, "StripesB", WHITE if i % 2 else RED, x - 0.25, x + 0.25, -0.16, 0.16, 2.2, 2.85, r=0.03)
    sphere(m, P(ORA, "NE"), (-2.2, 0, 3.1), 0.25, seg=8, rings=4, part="Blink")
    sphere(m, P(ORA, "NE"), (2.2, 0, 3.1), 0.25, seg=8, rings=4, part="Blink")
    snowcap(m, -2.6, 2.6, -0.12, 0.12, 2.85, t=0.2)


def Snowman(m):
    sphere(m, P(SNOW), (0, 0, 1.3), 1.5, seg=14, rings=9, part="Snow")
    sphere(m, P(SNOW), (0, 0, 3.4), 1.05, seg=12, rings=8, part="Snow")
    sphere(m, P(SNOW), (0, 0, 4.9), 0.75, seg=12, rings=8, part="Snow")
    lathe(m, P(ORA), [(0.13, 0), (0.0, 0.7)], loc=(0, -0.7, 4.9), rot=(90, 0, 0), seg=8, part="Nose")
    for sx in (-1, 1):
        sphere(m, P(DARK), (sx * 0.25, -0.65, 5.1), 0.09, seg=6, rings=4, part="Coal")
        rod(m, P(BROWN), (sx * 0.9, 0, 3.6), (sx * 2.1, 0, 4.3), r=0.08, seg=5, part="Arms")
    for z in (3.1, 3.5, 3.9):
        sphere(m, P(DARK), (0, -1.0, z), 0.1, seg=6, rings=4, part="Coal")
    torus(m, P(RED), (0, 0, 4.3), R=0.7, r=0.2, seg=14, rseg=6, part="Scarf")
    cyl(m, P(DARK), (0, 0, 5.45), r=0.75, h=0.12, seg=12, part="Hat")
    cyl(m, P(DARK), (0, 0, 5.55), r=0.5, h=0.9, seg=12, part="Hat")


# ------------------------------------------------------------------ market
def MarketStall(m):
    """Front (-Y) = the counter side. 12 wide, 8 deep."""
    bx(m, "Wood", WOOD, -6, 6, -4, 4, 0, 0.4, r=0.1, mat="WO")
    bx(m, "Counter", WOOD2, -5.6, 5.6, -4.0, -2.6, 0.4, 3.2, r=0.15, mat="WO")
    bx(m, "TintTrim", T_TRIM, -5.7, 5.7, -4.1, -2.5, 3.2, 3.55, r=0.12)
    bx(m, "Wood", WOOD2, -5.6, 5.6, 3.0, 3.8, 0.4, 7.4, r=0.12, mat="WO")
    for x in (-5.6, 5.6):
        for y in (-3.6, 3.4):
            bx(m, "Posts", WOOD2, x - 0.3, x + 0.3, y - 0.3, y + 0.3, 0.4, 7.6, r=0.1, mat="WO")
    # striped awning sloping to the front
    for i in range(8):
        x0 = -6.4 + i * 1.6
        col = "TintAccent" if i % 2 == 0 else "Awning"
        rbox(m, P(T_ACCENT if i % 2 == 0 else WHITE, "FA"), (x0 + 0.8, -0.6, 7.9), (1.6, 9.6, 0.25), r=0.06, part=col, rot=(-14, 0, 0))
        sphere(m, P(T_ACCENT if i % 2 == 0 else WHITE, "FA"), (x0 + 0.8, -5.3, 6.65), 0.8, scl=(1, 0.6, 0.6), seg=8, rings=4, part=col)
    rbox(m, P(SNOW), (0, -0.4, 8.25), (12.6, 8.6, 0.35), r=0.15, bseg=2, part="Snow", rot=(-14, 0, 0))
    # sign plate above the awning (Studio adds text)
    bx(m, "Wood", WOOD2, -4.0, 4.0, 3.0, 3.8, 7.4, 8.9, r=0.12, mat="WO")
    bx(m, "TintTrim", T_TRIM, -3.9, 3.9, 2.85, 3.0, 8.9, 10.5, r=0.15)
    bx(m, "Sign", CREAM, -3.6, 3.6, 2.7, 2.85, 9.05, 10.35, r=0.12)
    for x in (-4.5, 4.5):
        sphere(m, P(WARM, "NE"), (x, -3.8, 6.2), 0.3, seg=8, rings=5, part="StallLamp")


def StallShutter(m):
    """Roll-down shutter in front of a counter; slides up (+Z) when the stall opens. Bottom at z=0."""
    bx(m, "Shutter", "8FA3B8", -5.6, 5.6, -0.15, 0.15, 0, 3.5, r=0.06, mat="ME")
    for z in range(1, 7):
        bx(m, "Ribs", "6F8399", -5.6, 5.6, -0.22, -0.15, z * 0.5 - 0.06, z * 0.5 + 0.06, r=0.02, mat="ME")
    bx(m, "Handle", DARK, -0.6, 0.6, -0.32, -0.15, 0.2, 0.42, r=0.05)
    snowcap(m, -5.6, 5.6, -0.2, 0.2, 3.5, t=0.25)


def StallGoods(m):
    rnd = random.Random(11)
    for i, x in enumerate((-4, -1.3, 1.3, 4)):
        bx(m, "Crates", WOOD, x - 1.1, x + 1.1, -0.8, 0.8, 0, 0.9, r=0.1, mat="WO")
        col = [RED, ORA, GREEN, PINK][i]
        for k in range(6):
            sphere(m, P(col), (x - 0.6 + (k % 3) * 0.6, -0.3 + (k // 3) * 0.6, 1.1), 0.32, seg=8, rings=5, part="Goods" + str(i))
    for x in (-3, 0, 3):
        cyl(m, P([TEAL, YEL, BLUE][int(x / 3) + 1]), (x, 0.4, 1.0), r=0.32, h=0.7, seg=10, part="Mugs")


def MarketArch(m):
    for sx in (-1, 1):
        x = sx * 10.5
        bx(m, "TintRock", T_ROCK, x - 1, x + 1, -1, 1, 0, 0.9, r=0.25)
        cyl(m, P(T_ACCENT), (x, 0, 0.9), r=0.65, h=8.6, seg=12, part="TintAccent")
        for z in (2.5, 5.0, 7.5):
            torus(m, P(WHITE), (x, 0, z), R=0.66, r=0.14, seg=12, rseg=5, part="Stripes")
        sphere(m, P(T_TRIM), (x, 0, 9.7), 0.8, seg=10, rings=6, part="TintTrim")
        sphere(m, P(SNOW), (x, 0, 10.3), 0.6, scl=(1, 1, 0.6), seg=8, rings=4, part="Snow")
    bx(m, "TintTrim", T_TRIM, -10.5, 10.5, -0.5, 0.5, 8.4, 9.2, r=0.2)
    bx(m, "TintTrim", T_TRIM, -5.5, 5.5, -0.7, -0.4, 9.2, 11.4, r=0.3)
    bx(m, "Sign", CREAM, -5.1, 5.1, -0.8, -0.7, 9.45, 11.15, r=0.15)
    snowcap(m, -5.5, 5.5, -0.7, -0.4, 11.4, t=0.35)
    pts = [(-10.2 + 20.4 * i / 14, -0.6, 8.2 - 0.9 * math.sin(math.pi * i / 14)) for i in range(15)]
    tube(m, P(GREEN), pts, r=0.22, seg=6, part="Garland", smooth=2)
    for i in range(1, 14):
        p = pts[i]
        sphere(m, P([RED, YEL, TEAL, PINK][i % 4], "NE"), (p[0], p[1] - 0.1, p[2] - 0.3), 0.2, seg=6, rings=4, part="Bulbs")


# ------------------------------------------------------------------ town
def ShopFront(m):
    W, D, H = 13.5, 6.0, 9.0
    bx(m, "TintRock", T_ROCK, -W - 0.3, W + 0.3, -D - 0.3, D + 0.3, 0, 0.6, r=0.2)
    bx(m, "Walls", "F3E2C8", -W, W, -D, D, 0.6, H, r=0.2)
    bx(m, "TintAccent", T_ACCENT, -W - 0.3, W + 0.3, -D - 0.3, D + 0.3, H, H + 1.2, r=0.25)
    snowcap(m, -W - 0.3, W + 0.3, -D - 0.3, D + 0.3, H + 1.2, t=0.6)
    bx(m, "Glass", GLASS, -11.5, -2.0, -D - 0.1, -D + 0.1, 1.4, 6.0, r=0.05, mat="GL")
    bx(m, "Glass", GLASS, 4.5, 11.5, -D - 0.1, -D + 0.1, 1.4, 6.0, r=0.05, mat="GL")
    for x0, x1 in ((-11.5, -2.0), (4.5, 11.5)):
        bx(m, "Trim", WHITE, x0 - 0.3, x1 + 0.3, -D - 0.25, -D, 1.1, 1.4, r=0.05)
        bx(m, "Trim", WHITE, x0 - 0.3, x1 + 0.3, -D - 0.25, -D, 6.0, 6.3, r=0.05)
        bx(m, "Shelves", WARM, x0 + 0.3, x1 - 0.3, -D + 0.3, -D + 0.9, 1.4, 5.6, r=0.05, mat="NE")
    bx(m, "Door", "3E6FB8", -1.2, 3.7, -D - 0.12, -D + 0.05, 0.6, 6.3, r=0.1)
    bx(m, "Glass", GLASS, -0.6, 3.1, -D - 0.2, -D - 0.1, 2.6, 5.8, r=0.05, mat="GL")
    # striped awning
    for i in range(14):
        x0 = -12.6 + i * 1.8
        rbox(m, P(T_ACCENT if i % 2 == 0 else WHITE, "FA"), (x0 + 0.9, -D - 1.3, 6.9), (1.8, 2.8, 0.22), r=0.05,
             part="TintAccent" if i % 2 == 0 else "Awning", rot=(-20, 0, 0))
    rbox(m, P(SNOW), (0, -D - 1.25, 7.15), (25.4, 2.8, 0.3), r=0.12, bseg=2, part="Snow", rot=(-20, 0, 0))
    # big sign + OPEN sign (neon, toggled in Studio)
    bx(m, "Sign", CREAM, -7.0, 7.0, -D - 0.35, -D - 0.15, 7.8, 9.9, r=0.2)
    bx(m, "OpenSign", "FF4F6E", -10.8, -7.9, -D - 0.3, -D - 0.12, 3.3, 4.4, r=0.15, mat="NE")


def Car(m):
    """Cute parked car: 4.4 wide, 8 long, front = -Y."""
    bx(m, "TintBody", T_BODY, -2.2, 2.2, -4.0, 4.0, 0.55, 2.1, r=0.6, bseg=3)
    bx(m, "TintBody", T_BODY, -1.85, 1.85, -1.8, 2.6, 2.0, 3.5, r=0.55, bseg=3)
    bx(m, "Glass", GLASS, -1.9, 1.9, -1.95, -1.6, 2.15, 3.25, r=0.15, mat="GL")
    bx(m, "Glass", GLASS, -1.9, 1.9, 2.4, 2.75, 2.15, 3.25, r=0.15, mat="GL")
    for sx in (-1, 1):
        bx(m, "Glass", GLASS, sx * 1.9 - 0.1, sx * 1.9 + 0.1, -1.4, 2.2, 2.2, 3.25, r=0.05, mat="GL")
        for y in (-2.6, 2.6):
            tire(m, P(DARK), (sx * 1.95, y, 0.8), 0.8, 0.7, part="Tires")
            wheel_disc(m, P(SILVER, "ME"), (sx * 2.32, y, 0.8), 0.42, 0.06, part="Hubs")
        sphere(m, P(BULB, "NE"), (sx * 1.4, -4.0, 1.5), 0.32, scl=(1, 0.5, 1), seg=8, rings=5, part="Headlights")
        sphere(m, P("FF3A3A", "NE"), (sx * 1.5, 4.0, 1.5), 0.26, scl=(1, 0.5, 1), seg=8, rings=5, part="Taillights")
    bx(m, "Bumper", SILVER, -2.0, 2.0, -4.25, -3.9, 0.6, 1.0, r=0.15, mat="ME")
    bx(m, "Bumper", SILVER, -2.0, 2.0, 3.9, 4.25, 0.6, 1.0, r=0.15, mat="ME")
    rbox(m, P(SNOW), (0, 0.4, 3.62), (3.6, 4.2, 0.45), r=0.2, bseg=2, part="Snow")
    sphere(m, P(SNOW), (0, -3.0, 2.15), 0.7, scl=(2.4, 1.2, 0.35), seg=8, rings=4, part="Snow")


def BarrierArm(m):
    bx(m, "Box", YEL, -0.7, 0.7, -0.7, 0.7, 0, 3.0, r=0.2)
    snowcap(m, -0.7, 0.7, -0.7, 0.7, 3.0, t=0.3)
    sphere(m, P("FF3A3A", "NE"), (0, -0.75, 2.4), 0.22, seg=6, rings=4, part="Light")


def BarrierBoom(m):
    """The arm alone (pivot at its root, x=0), points along +X; Studio rotates it up when the exit is clear."""
    for i in range(8):
        x0 = i * 1.1
        bx(m, "BoomA" if i % 2 == 0 else "BoomB", RED if i % 2 == 0 else WHITE, x0, x0 + 1.1, -0.2, 0.2, -0.2, 0.2, r=0.08)
    sphere(m, P(SNOW), (4.4, 0, 0.25), 0.25, scl=(16, 1.4, 0.6), seg=8, rings=3, part="Snow")


def BusShelter(m):
    W = 9.0
    bx(m, "Base", "C9D2DE", -W, W, -3.0, 3.0, 0, 0.4, r=0.1)
    for x in (-W + 0.4, W - 0.4):
        for y in (-2.4, 2.4):
            bx(m, "TintAccent", T_ACCENT, x - 0.25, x + 0.25, y - 0.25, y + 0.25, 0.4, 7.2, r=0.08)
    bx(m, "Glass", GLASS, -W + 0.6, W - 0.6, 2.25, 2.55, 0.9, 6.6, r=0.05, mat="GL", )
    bx(m, "Glass", GLASS, -W + 0.25, -W + 0.55, -2.1, 2.2, 0.9, 6.6, r=0.05, mat="GL")
    bx(m, "TintAccent", T_ACCENT, -W - 0.4, W + 0.4, -3.4, 3.2, 7.2, 7.8, r=0.2)
    rbox(m, P(SNOW), (0, -0.1, 8.0), (2 * W + 1.0, 6.8, 0.55), r=0.25, bseg=2, part="Snow")
    bx(m, "Bench", WOOD, -5.5, 5.5, 0.8, 2.0, 1.6, 1.9, r=0.08, mat="WO")
    bx(m, "Bench", WOOD, -5.5, 5.5, 1.8, 2.1, 1.9, 3.0, r=0.08, mat="WO")
    for x in (-4.8, 4.8):
        bx(m, "Steel", STEEL, x - 0.15, x + 0.15, 1.0, 1.8, 0.4, 1.6, r=0.04)
    bx(m, "Poster", "4FA3FF", 2.2, 7.6, 2.05, 2.2, 2.2, 5.6, r=0.05, mat="NE")
    sphere(m, P(WARM, "NE"), (0, 0, 7.0), 0.35, scl=(4, 1, 0.5), seg=8, rings=4, part="Lamp")


def BusStopSign(m):
    cyl(m, P(SILVER, "ME"), (0, 0, 0), r=0.16, h=6.0, seg=8, part="Pole")
    disc(m, P(WHITE), (0, -0.1, 6.4), 1.15, 0.16, axis=(0, -1, 0), seg=20, part="Sign")
    disc(m, P(BLUE), (0, -0.2, 6.4), 0.95, 0.08, axis=(0, -1, 0), seg=20, part="SignFace")
    sphere(m, P(SNOW), (0, 0, 7.6), 0.35, scl=(2.2, 1, 0.5), seg=8, rings=4, part="Snow")


def Bus(m):
    """Friendly bus 6 wide, 19 long, front = -Y."""
    bx(m, "TintBody", T_BODY, -3.0, 3.0, -9.5, 9.5, 0.9, 6.9, r=0.9, bseg=3)
    bx(m, "Stripe", WHITE, -3.05, 3.05, -9.3, 9.3, 2.0, 2.6, r=0.2)
    bx(m, "Roof", WHITE, -2.7, 2.7, -8.8, 8.8, 6.6, 7.2, r=0.4)
    rbox(m, P(SNOW), (0, 0.5, 7.4), (5.0, 15.0, 0.5), r=0.22, bseg=2, part="Snow")
    bx(m, "Glass", GLASS, -2.6, 2.6, -9.6, -9.3, 3.4, 6.1, r=0.25, mat="GL")
    for sx in (-1, 1):
        for i in range(5):
            y = -6.6 + i * 3.2
            bx(m, "Glass", GLASS, sx * 3.0 - 0.1, sx * 3.0 + 0.1, y - 1.25, y + 1.25, 3.3, 5.8, r=0.15, mat="GL")
        for y in (-6.0, 6.0):
            tire(m, P(DARK), (sx * 2.7, y, 1.05), 1.05, 0.9, part="Tires")
            wheel_disc(m, P(SILVER, "ME"), (sx * 3.17, y, 1.05), 0.55, 0.06, part="Hubs")
        sphere(m, P(BULB, "NE"), (sx * 2.0, -9.55, 1.9), 0.42, scl=(1, 0.4, 1), seg=10, rings=6, part="Headlights")
        sphere(m, P("FF3A3A", "NE"), (sx * 2.1, 9.55, 1.9), 0.32, scl=(1, 0.4, 1), seg=8, rings=5, part="Taillights")
    bx(m, "DestSign", "FFB000", -1.9, 1.9, -9.65, -9.5, 6.2, 6.8, r=0.08, mat="NE")
    bx(m, "Bumper", DARK, -2.9, 2.9, -9.8, -9.3, 0.8, 1.4, r=0.2)
    bx(m, "Door", "1F2937", sx * 0 + 3.0, 3.12, -8.4, -6.6, 1.2, 5.9, r=0.05)


# ------------------------------------------------------------------ camp / pump / workshop
def SupplyTent(m):
    W, D = 8.0, 5.0
    for sx in (-1, 1):
        rbox(m, P(T_ACCENT, "FA"), (sx * W * 0.48, 0, 3.3), (W * 1.12, 2 * D, 0.3), r=0.08, part="TintAccent", rot=(0, sx * 52, 0))
    tri = [(-W * 0.98, 0), (W * 0.98, 0), (0, 6.6)]
    prism(m, P(CREAM, "FA"), tri, 0.2, loc=(0, D, 0), rot=(90, 0, 0), part="Canvas")
    rod(m, P(WOOD2), (0, -D - 0.4, 6.7), (0, D + 0.4, 6.7), r=0.18, seg=8, part="Pole")
    for y in (-D - 0.4, D + 0.4):
        rod(m, P(WOOD2), (0, y, 0), (0, y, 6.8), r=0.16, seg=8, part="Pole")
    prism(m, P("6E4630"), [(-1.8, 0), (1.8, 0), (0, 3.8)], 0.15, loc=(0, -D + 0.05, 0), rot=(90, 0, 0), part="Opening")
    for sx in (-1, 1):
        rbox(m, P(SNOW), (sx * W * 0.5, 0, 3.6), (W * 0.9, 2 * D + 0.2, 0.3), r=0.12, bseg=2, part="Snow", rot=(0, sx * 52, 0))
    for sx in (-1, 1):
        rod(m, P("D9D2C0"), (sx * W, -D, 0.1), (sx * W * 0.62, -D, 2.5), r=0.05, seg=4, part="Ropes")
    lantern(m, 2.4, -D - 0.6, 0, part="Lamp")


def SupplyCrate(m):
    """Rounded supply crate 4 x 4 x 3.4 (sits buried until dug out)."""
    bx(m, "Crate", WOOD, -2, 2, -2, 2, 0, 3.4, r=0.45, bseg=3, mat="WO")
    for z in (0.5, 2.9):
        bx(m, "Bands", STEEL, -2.06, 2.06, -2.06, 2.06, z - 0.18, z + 0.18, r=0.3, mat="ME")
    for x in (-1.1, 1.1):
        bx(m, "Bands", STEEL, x - 0.18, x + 0.18, -2.08, 2.08, 0.2, 3.3, r=0.12, mat="ME")
    bx(m, "TintAccent", T_ACCENT, -1.2, 1.2, -2.12, -2.04, 1.2, 2.2, r=0.1)
    star = star_poly(5, 0.42, 0.18)
    prism(m, P(WHITE), star, 0.05, loc=(0, -2.14, 1.7), rot=(90, 0, 0), part="Star")
    rbox(m, P(SNOW), (0, 0, 3.55), (3.6, 3.6, 0.35), r=0.15, bseg=2, part="Snow")


def Campfire(m):
    for i in range(9):
        a = 2 * math.pi * i / 9
        rock(m, P(ROCK), (math.cos(a) * 1.4, math.sin(a) * 1.4, 0.3), size=(0.5, 0.45, 0.35), seed=i, sub=1, part="Stones")
    for a in (0, 60, 120):
        rod(m, P(BROWN), (math.cos(math.radians(a)) * 1.0, math.sin(math.radians(a)) * 1.0, 0.2),
            (-math.cos(math.radians(a)) * 1.0, -math.sin(math.radians(a)) * 1.0, 0.5), r=0.18, seg=6, part="Logs")
    lathe(m, P(ORA, "NE"), [(0.7, 0.3), (0.55, 0.9), (0.0, 2.1)], seg=10, part="Flame")
    lathe(m, P(YEL, "NE"), [(0.38, 0.35), (0.3, 0.8), (0.0, 1.5)], loc=(0.1, -0.1, 0), seg=8, part="Flame")
    m.flat("Stones", P(ROCK), 30)


def PumpHouse(m):
    W, D, H = 11.0, 6.0, 7.0
    bx(m, "TintRock", T_ROCK, -W - 0.3, W + 0.3, -D - 0.3, D + 0.3, 0, 0.7, r=0.2)
    bx(m, "Walls", "D9A07A", -W, W, -D, D, 0.7, H, r=0.2, mat="BR")
    gable(m, "Roof", "3D6E9E", -W, W, -D, D, H, 3.2, over=0.9, thick=0.5)
    gable_snow(m, -W, W, -D, D, H, 3.2, over=0.9)
    tri = [(-D - 0.1, 0), (D + 0.1, 0), (0, 3.2)]
    for sx in (-1, 1):
        prism(m, P("D9A07A", "BR"), tri, 0.4, loc=(sx * W - 0.2, 0, H), rot=(90, 0, 90), part="Walls")
    bx(m, "Door", "3D6E9E", -1.4, 1.4, -D - 0.12, -D + 0.05, 0.7, 4.8, r=0.1)
    for x in (-6.5, 6.5):
        window(m, x, -D, 2.4, w=2.4, h=2.0)
    bx(m, "Sign", CREAM, -3.2, 3.2, -D - 0.25, -D - 0.12, 5.3, 6.6, r=0.1)
    # pipe from the house to the pump (runs along -Y)
    rod(m, P("5D6F82", "ME"), (6.0, -D, 1.2), (6.0, -D - 3.0, 1.2), r=0.45, seg=10, part="Pipe")
    sphere(m, P(WARM, "NE"), (-1.9, -D - 0.25, 5.2), 0.28, seg=8, rings=5, part="Lamp")


def PumpMachine(m):
    """Pump body + spout + trough; the wheel is separate (PumpWheel) on its axle at (2.4, 0, 3.2) pointing +X."""
    bx(m, "TintRock", T_ROCK, -2.6, 2.6, -1.6, 1.6, 0, 0.7, r=0.25)
    cyl(m, P("3D7BE2"), (0, 0, 0.7), r=1.25, r2=1.0, h=3.4, seg=16, bev=0.2, part="Body")
    cyl(m, P(SILVER, "ME"), (0, 0, 4.1), r=1.1, r2=0.5, h=0.9, seg=16, part="Cap")
    sphere(m, P(YEL), (0, 0, 5.1), 0.35, seg=10, rings=6, part="Knob")
    for z in (1.4, 3.4):
        torus(m, P(SILVER, "ME"), (0, 0, z), R=1.2, r=0.12, seg=18, rseg=5, part="Bands")
    rod(m, P(SILVER, "ME"), (0, 0, 3.2), (2.4, 0, 3.2), r=0.2, seg=8, part="Axle")
    tube(m, P(SILVER, "ME"), [(0, -1.0, 2.8), (0, -2.0, 2.9), (0, -2.6, 2.3)], r=0.32, seg=10, part="Spout", smooth=3)
    bx(m, "Trough", WOOD, -1.6, 1.6, -4.6, -2.4, 0, 1.2, r=0.15, mat="WO")
    bx(m, "Water", "4FC3FF", -1.35, 1.35, -4.35, -2.65, 0.6, 1.12, r=0.05, mat="GL")
    bx(m, "Gauge", WHITE, -0.9, -0.2, -1.32, -1.2, 2.2, 2.9, r=0.1)
    sphere(m, P("6CFF9A", "NE"), (-0.55, -1.36, 3.25), 0.18, seg=8, rings=4, part="StatusLight")


def PumpWheel(m):
    """Spoked hand wheel; axis along X, centre at the origin."""
    torus(m, P(RED), (0, 0, 0), R=2.0, r=0.2, seg=28, rseg=6, rot=(0, 90, 0), part="Rim")
    for i in range(6):
        a = 2 * math.pi * i / 6
        rod(m, P(RED), (0, 0, 0), (0, math.cos(a) * 1.95, math.sin(a) * 1.95), r=0.12, seg=6, part="Spokes")
    cyl(m, P(SILVER, "ME"), (-0.25, 0, 0), r=0.42, h=0.5, seg=12, rot=(0, 90, 0), part="Hub")
    rod(m, P(YEL), (0.0, 0, 1.95), (0.9, 0, 1.95), r=0.16, seg=6, part="Handle")


def Warehouse(m):
    """66 wide, 12 deep, two loading openings (10 wide) centred at x = +-15. Front = -Y."""
    W, D, H = 33.0, 6.0, 11.0
    bx(m, "TintRock", T_ROCK, -W - 0.3, W + 0.3, -D - 0.3, D + 0.3, 0, 0.6, r=0.2)
    xs = [-W, -20.0, -10.0, 10.0, 20.0, W]
    for x0, x1 in ((-W, -20.0), (-10.0, 10.0), (20.0, W)):
        bx(m, "Walls", "B7C4D4", x0, x1, -D, D, 0.6, H, r=0.15)
    for x0, x1 in ((-20.0, -10.0), (10.0, 20.0)):
        bx(m, "Walls", "B7C4D4", x0, x1, -D, D, 9.2, H, r=0.1)
        bx(m, "Floor", "8E9AAB", x0, x1, -D + 0.6, D, 0.6, 0.8, r=0.05)
        bx(m, "TintAccent", T_ACCENT, x0 - 0.5, x0, -D - 0.25, -D + 0.2, 0.6, 9.4, r=0.08)
        bx(m, "TintAccent", T_ACCENT, x1, x1 + 0.5, -D - 0.25, -D + 0.2, 0.6, 9.4, r=0.08)
        bx(m, "TintAccent", T_ACCENT, x0 - 0.5, x1 + 0.5, -D - 0.25, -D + 0.2, 9.2, 9.7, r=0.08)
        sphere(m, P(WARM, "NE"), ((x0 + x1) / 2, -D - 0.6, 10.3), 0.42, scl=(1.6, 1, 0.7), seg=10, rings=5, part="BayLamp")
        bx(m, "Inside", "3A4150", x0 + 0.2, x1 - 0.2, D - 0.4, D - 0.2, 0.8, 9.0, r=0.02)
        for k in range(3):
            bx(m, "Boxes", WOOD, x0 + 1.2 + k * 2.6, x0 + 3.2 + k * 2.6, D - 2.6, D - 0.6, 0.8, 2.6 + (k % 2) * 1.6, r=0.12, mat="WO")
    for x in xs[1:-1]:
        bx(m, "Trim", "8E9AAB", x - 0.25, x + 0.25, -D - 0.15, -D + 0.1, 0.6, H, r=0.06)
    rbox(m, P("6D7F95"), (0, 0, H + 0.6), (2 * W + 1.2, 2 * D + 1.2, 1.2), r=0.3, part="Roof")
    rbox(m, P(SNOW), (0, 0, H + 1.35), (2 * W + 1.0, 2 * D + 1.0, 0.6), r=0.25, bseg=2, part="Snow")
    bx(m, "Sign", CREAM, -7.5, 7.5, -D - 0.3, -D - 0.12, 5.8, 8.4, r=0.2)
    for x in (-27.0, 27.0):
        window(m, x, -D, 4.0, w=3.0, h=2.4)


def WarehouseDoor(m):
    """Roll-up door 10 wide x 8.6 high, bottom at z=0; slides up when the delivery arrives."""
    bx(m, "Door", "D59A3A", -5.0, 5.0, -0.12, 0.12, 0, 8.6, r=0.05, mat="ME")
    for z in range(1, 12):
        bx(m, "Ribs", "B57E2A", -5.0, 5.0, -0.2, -0.12, z * 0.72 - 0.06, z * 0.72 + 0.06, r=0.02, mat="ME")
    bx(m, "Handle", DARK, -0.6, 0.6, -0.3, -0.12, 0.4, 0.6, r=0.04)


def DeliveryVan(m):
    """5.4 wide, 11 long, front = -Y."""
    bx(m, "TintBody", T_BODY, -2.7, 2.7, -2.4, 5.5, 0.9, 6.2, r=0.55, bseg=3)
    bx(m, "TintBody", T_BODY, -2.6, 2.6, -5.5, -2.2, 0.9, 4.4, r=0.7, bseg=3)
    bx(m, "Glass", GLASS, -2.3, 2.3, -5.25, -3.6, 2.6, 4.1, r=0.3, mat="GL", rot=(0, 0, 0))
    for sx in (-1, 1):
        bx(m, "Glass", GLASS, sx * 2.6 - 0.1, sx * 2.6 + 0.1, -4.6, -2.6, 2.6, 4.0, r=0.1, mat="GL")
        for y in (-3.6, 3.8):
            tire(m, P(DARK), (sx * 2.45, y, 0.95), 0.95, 0.8, part="Tires")
            wheel_disc(m, P(SILVER, "ME"), (sx * 2.87, y, 0.95), 0.5, 0.06, part="Hubs")
        sphere(m, P(BULB, "NE"), (sx * 1.8, -5.55, 1.9), 0.36, scl=(1, 0.4, 1), seg=8, rings=5, part="Headlights")
        bx(m, "Logo", WHITE, sx * 2.72 - 0.05, sx * 2.72 + 0.05, 0.0, 4.0, 3.0, 5.0, r=0.3)
    bx(m, "Bumper", DARK, -2.6, 2.6, -5.8, -5.3, 0.8, 1.4, r=0.2)
    rbox(m, P(SNOW), (0, 1.6, 6.4), (4.8, 7.0, 0.45), r=0.2, bseg=2, part="Snow")


def PalletStack(m):
    bx(m, "Pallet", WOOD2, -1.8, 1.8, -1.8, 1.8, 0, 0.5, r=0.06, mat="WO")
    for i, (x, y, h) in enumerate(((-0.9, -0.9, 1.6), (0.9, -0.9, 1.3), (-0.9, 0.9, 1.4), (0.9, 0.9, 1.7))):
        bx(m, "Boxes", ["C9A26B", "B98D55", "D8B47A", "C29A60"][i], x - 0.82, x + 0.82, y - 0.82, y + 0.82, 0.5, 0.5 + h, r=0.1)
    bx(m, "Wrap", "E8F4FF", -1.75, 1.75, -1.75, 1.75, 0.5, 2.0, r=0.2, mat="GL")
    rbox(m, P(SNOW), (0, 0, 2.3), (3.2, 3.2, 0.3), r=0.12, bseg=2, part="Snow")


# ------------------------------------------------------------------ fallback NPC accessories (sized for a 1.2 stud head)
def WinterHat(m):
    lathe(m, P(RED, "FA"), [(0.66, 0.0), (0.66, 0.35), (0.6, 0.62), (0.42, 0.88), (0.0, 1.0)], seg=16, part="Hat")
    torus(m, P(WHITE, "FA"), (0, 0, 0.12), R=0.64, r=0.16, seg=18, rseg=6, part="Brim")
    sphere(m, P(WHITE, "FA"), (0, 0, 1.08), 0.24, seg=10, rings=6, part="Pom")


def Scarf(m):
    torus(m, P(YEL, "FA"), (0, 0, 0), R=0.62, r=0.2, seg=18, rseg=6, part="Scarf")
    rbox(m, P(YEL, "FA"), (0.3, -0.6, -0.5), (0.38, 0.14, 0.9), r=0.06, part="Scarf", rot=(0, 10, 0))
    for z in (-0.25, -0.65):
        bx(m, "Stripes", RED, 0.1, 0.5, -0.69, -0.66, z - 0.06, z + 0.06, r=0.02)


BUILDERS = {k: globals()[k] for k in (
    "YardPad", "YardGate", "YardBridge", "Cottage", "Mailbox", "PicketFence", "RoadSign", "RoadClosed", "Snowman",
    "MarketStall", "StallShutter", "StallGoods", "MarketArch", "ShopFront", "Car", "BarrierArm", "BarrierBoom", "BusShelter",
    "BusStopSign", "Bus", "SupplyTent", "SupplyCrate", "Campfire", "PumpHouse", "PumpMachine", "PumpWheel", "Warehouse",
    "WarehouseDoor", "DeliveryVan", "PalletStack", "WinterHat", "Scarf")}
