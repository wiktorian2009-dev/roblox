# bodies.py - 14 snowplow BODY shells (task 7, Claude 2026-10-05). The free starter body is the original chassis shell (BodyStarter,
# split out of PlowParts.Chassis in Studio), so it is not rebuilt here.
# Frame convention (shared with PlowParts.Chassis): origin = chassis root at floor centre; Blender (x, y, z) -> Roblox local (-x, z, y);
# front = Blender -Y (Roblox -Z, where the blade mounts). Every body keeps these zones clear so it fits every blade / engine / gear:
#   wheels + tracks : below z 2.0 outside |x| 2.5            blade mount : nothing in front of y -4.2
#   driver well     : |x| < 1.6, -0.9 < y < 2.3, above z 2.6  engine bay  : |x| < 1.75, 2.1 < y < 4.9, above z 2.6
#   height          : top <= 7.6 (roofs only above the driver's head, from z 6.9)
import math, random, sys
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\W1Remaster20261005")
from w1lib import *

GLASS = "BFE9FF"; DARK = "262A33"; LIGHT = "FFF3B0"; TAIL = "FF5A5A"; CHROME = "D9DEE6"; RUB = "2A2D34"


def tub(m, main, trim, dark=DARK, hood=2.9, nose=-4.15, rear=4.05, fender=None, side=3.15, bumper=None):
    """Shared lower shell: hull, fenders over the wheels, hood, cockpit sides, rear engine deck, bumpers and lights."""
    fender = fender or trim
    bx(m, "Hull", main, -2.5, 2.5, nose + 0.35, rear - 0.15, 0.7, 2.2, r=0.35, bseg=2)
    bx(m, "Fender", fender, -side, side, nose + 0.55, rear - 0.1, 2.0, 2.32, r=0.12)
    bx(m, "Hood", main, -2.2, 2.2, nose + 0.1, -0.95, 2.2, hood, r=0.3, bseg=2)
    for sx in (-1, 1):  # cockpit side walls (driver well stays open)
        bx(m, "Side", main, sx * 1.7, sx * 2.45, -0.95, 2.1, 2.2, 3.15, r=0.15)
    bx(m, "Deck", dark, -2.2, 2.2, 2.1, rear, 2.2, 2.55, r=0.12)
    bx(m, "Bumper", bumper or dark, -2.4, 2.4, nose, nose + 0.5, 0.85, 1.6, r=0.2)
    bx(m, "Bumper", bumper or dark, -2.3, 2.3, rear - 0.25, rear + 0.1, 0.85, 1.5, r=0.18)
    for sx in (-1.45, 1.45):
        bx(m, "Lights", LIGHT, sx - 0.42, sx + 0.42, nose + 0.05, nose + 0.2, hood - 0.75, hood - 0.25, r=0.12, mat="NE")
        bx(m, "TailLights", TAIL, sx - 0.4, sx + 0.4, rear - 0.05, rear + 0.12, 1.65, 2.0, r=0.06, mat="NE")


def cage(m, col, top=6.9, posts=((-2.15, -0.75), (2.15, -0.75), (-2.15, 2.05), (2.15, 2.05)), r=0.17, cross=True):
    """Tubular roll cage around the driver (posts outside the driver well)."""
    for (x, y) in posts:
        cyl(m, P(col), (x, y, 2.6), r=r, h=top - 2.6, seg=8, part="Cage")
    if cross:
        for y in (posts[0][1], posts[2][1]):
            tube(m, P(col), [(-2.15, y, top), (2.15, y, top)], r=r, seg=8, part="Cage", smooth=1)
        for x in (-2.15, 2.15):
            tube(m, P(col), [(x, posts[0][1], top), (x, posts[2][1], top)], r=r, seg=8, part="Cage", smooth=1)


def roof(m, col, top=7.0, y0=-1.0, y1=2.2, w=2.45, t=0.28, part="Roof"):
    bx(m, part, col, -w, w, y0, y1, top, top + t, r=0.12)


def windshield(m, frame, z0=3.1, z1=4.6, y=-0.85):
    for sx in (-1, 1):
        bx(m, "Frame", frame, sx * 1.75, sx * 1.95, y - 0.1, y + 0.1, z0, z1, r=0.05)
    bx(m, "Frame", frame, -1.95, 1.95, y - 0.1, y + 0.1, z1 - 0.15, z1 + 0.05, r=0.05)
    rbox(m, P(GLASS, "SP", t=0.45), (0, y, (z0 + z1 - 0.15) / 2), (3.5, 0.1, z1 - 0.15 - z0), r=0.02, part="Glass")


# ---------------------------------------------------------------- 14 bodies
def BodyFrostHauler(m):
    """Frost Hauler (Starter, practical): boxy snow-white pickup tub, blue stripes, tall roll cage with a light bar."""
    W, B = "F4F8FF", "3E7FE0"
    tub(m, W, B, hood=2.95)
    bx(m, "Stripe", B, -0.55, -0.25, -4.0, -0.95, 2.93, 2.97, r=0.02); bx(m, "Stripe", B, 0.25, 0.55, -4.0, -0.95, 2.93, 2.97, r=0.02)
    for sx in (-1, 1): bx(m, "Stripe", B, sx * 2.5 - 0.02, sx * 2.5 + 0.02, -3.6, 3.7, 1.35, 1.6, r=0.01)
    cage(m, "DCE6F2", top=6.7)
    bx(m, "LightBar", DARK, -1.6, 1.6, -0.85, -0.6, 6.85, 7.15, r=0.08)
    for x in (-1.0, -0.35, 0.35, 1.0): bx(m, "Lights", LIGHT, x - 0.22, x + 0.22, -0.92, -0.86, 6.9, 7.1, r=0.03, mat="NE")
    windshield(m, "DCE6F2")
    drift(m, 1.3, -3.0, 2.85, 0.6, random.Random(1), flat_=0.35)


def BodyDuneRunner(m):
    """Dune Runner (Desert): sand buggy, tubular frame, roof rack with a spare tire."""
    S, T, R = "E8C27A", "2EC4B6", "8A4B2A"
    tub(m, S, R, hood=2.7, fender=R)
    cage(m, T, top=6.95, r=0.15)
    for x in (-1.2, 0, 1.2): tube(m, P(T), [(x, -0.75, 6.95), (x, 2.05, 6.95)], r=0.1, seg=6, part="Rack", smooth=1)
    torus(m, P(RUB), (0, 0.65, 7.3), R=0.75, r=0.25, seg=16, rseg=6, part="Spare")
    cyl(m, P(CHROME), (0, 0.65, 7.15), r=0.45, h=0.3, seg=10, part="Spare")
    bx(m, "Scoop", T, -0.6, 0.6, -2.6, -1.3, 2.7, 3.2, r=0.15)
    for sx in (-1, 1): tube(m, P(T), [(sx * 2.2, -3.95, 1.2), (sx * 2.2, -4.0, 2.4), (sx * 1.9, -3.4, 2.9)], r=0.12, seg=6, part="Bar", smooth=3)


def BodyGraveHauler(m):
    """Grave Hauler (Cursed): dark purple hearse cab, arched windows, lantern, bone trim."""
    Pu, Li, Bo, Gr = "3B2A55", "8E4DE0", "EDE3C8", "7CFFB2"
    tub(m, Pu, Li, hood=2.85, fender=Pu, bumper=Bo)
    for sx in (-1, 1):  # tall side panels with arched windows (outside the driver well)
        bx(m, "Cab", Pu, sx * 1.75, sx * 2.45, -0.9, 2.1, 3.15, 6.8, r=0.2)
        bx(m, "Window", Gr, sx * 2.46, sx * 2.5, -0.4, 1.6, 4.2, 5.9, r=0.25, mat="NE")
    roof(m, Pu, top=6.8, w=2.5)
    lathe(m, P(Li), [(1.4, 7.08), (1.2, 7.35), (0.01, 7.55)], seg=6, loc=(0, 0.55, 0), part="RoofPeak")
    cyl(m, P(DARK), (0, -1.6, 2.9), r=0.12, h=0.9, seg=6, part="Post")
    sphere(m, P(Gr, "NE"), (0, -1.6, 4.0), r=0.32, seg=8, rings=6, part="Lantern")
    for k in range(5): bx(m, "Bone", Bo, -2.2 + k * 1.1 - 0.12, -2.2 + k * 1.1 + 0.12, -4.08, -3.98, 1.0, 1.45, r=0.08)
    sphere(m, P(Bo), (0, -3.6, 3.0), r=0.38, seg=8, rings=6, part="Skull")


def BodyGeodeCrawler(m):
    """Geode Crawler (Crystal Caves): slate rock-armoured hull with cyan crystal spikes on the fenders."""
    Sl, Cy, Pi = "3D4766", "57D8FF", "E07BFF"
    tub(m, Sl, "56627F", hood=3.0)
    rnd = random.Random(4)
    for k in range(6):
        sx = -1 if k % 2 == 0 else 1; y = -3.0 + (k // 2) * 2.6
        rock(m, P("5A6788"), (sx * 2.8, y, 2.75), size=(0.8, 1.3, 0.5), seed=k, part="Armor")
        lathe(m, P(Cy if k % 3 else Pi), [(0.32, 2.4), (0.3, 3.1), (0.01, 3.9)], seg=5, loc=(sx * 2.75, y + 0.3, 0), part="Crystal")
    windshield(m, "56627F", z1=4.4)
    lathe(m, P(Cy), [(0.4, 2.9), (0.36, 3.3), (0.01, 4.2)], seg=6, loc=(0, -3.2, 0), part="Crystal")


def BodyArcadeKart(m):
    """Arcade Kart (Retro World): blocky pixel kart, neon pink / cyan trims, scoreboard spoiler."""
    Pk, Cy, Ye, Dk = "FF4FB6", "3FF0FF", "FFE14F", "1E1E2E"
    tub(m, Dk, Pk, hood=2.7, fender=Pk)
    for y in (-3.2, -2.2, -1.2): bx(m, "Pixel", Cy, -2.2, 2.2, y, y + 0.5, 2.7, 3.0, r=0.0, mat="NE")
    for sx in (-1, 1): bx(m, "Trim", Cy, sx * 2.5, sx * 2.56, -3.6, 3.7, 1.9, 2.05, r=0.0, mat="NE")
    # scoreboard spoiler sits behind the engine bay on two struts from the rear bumper
    for sx in (-1, 1): bx(m, "Strut", Dk, sx * 1.95, sx * 2.15, 4.9, 5.15, 1.3, 4.9, r=0.05)
    bx(m, "Strut", Dk, -2.15, 2.15, 3.9, 5.15, 1.3, 1.55, r=0.05)
    bx(m, "Spoiler", Pk, -2.5, 2.5, 4.95, 5.6, 4.9, 5.45, r=0.1)
    for k in range(4): bx(m, "Score", Ye, -1.6 + k * 0.85, -1.15 + k * 0.85, 4.92, 4.96, 5.0, 5.35, r=0.0, mat="NE")
    for sx in (-1, 1): bx(m, "Block", Ye, sx * 2.2 - 0.3, sx * 2.2 + 0.3, -1.0, -0.4, 3.15, 3.75, r=0.0)


def BodySafari(m):
    """Safari Cruiser (Jungle): green jeep, bamboo bars, canvas roof and a roof crate."""
    Gn, Bw, Or, Dg = "3FBF4F", "8A5A33", "FF9A2E", "2E5E2A"
    tub(m, Gn, Dg, hood=2.9, bumper=Bw)
    cage(m, "D8C27A", top=6.8, r=0.16)
    bx(m, "Canvas", "E6D2A0", -2.3, 2.3, -0.9, 2.1, 6.95, 7.15, r=0.1)
    bx(m, "Crate", Bw, -0.9, 0.9, 0.0, 1.4, 7.15, 7.55, r=0.06)
    for sx in (-1, 1): tube(m, P("D8C27A"), [(sx * 2.0, -4.15, 1.3), (sx * 2.0, -4.15, 2.6), (sx * 1.0, -4.0, 3.0)], r=0.12, seg=6, part="Bamboo", smooth=3)
    cyl(m, P(Or), (-2.6, 3.2, 2.3), r=0.22, h=1.8, seg=8, part="Jerrycan")
    windshield(m, Dg, z1=4.3)


def BodyPolarTitan(m):
    """Polar Titan (Absolute Zero, premium): heavy armoured ice truck, ram bumper, frost plates, glowing cyan seams."""
    Wh, Bl, Gy, Cy = "D8F3FF", "2E6BD8", "C9D6E6", "7FE8FF"
    tub(m, Gy, Bl, hood=3.2, fender=Bl, bumper=Bl, side=3.3)
    bx(m, "Ram", "9FB3CC", -2.6, 2.6, -4.2, -3.85, 0.7, 2.0, r=0.3)
    for k in range(3): bx(m, "Plate", Wh, -2.0, 2.0, -3.7 + k * 0.85, -3.25 + k * 0.85, 3.15, 3.32, r=0.08)
    for sx in (-1, 1):
        bx(m, "Seam", Cy, sx * 2.5 - 0.03, sx * 2.5 + 0.03, -3.6, 3.7, 1.05, 1.15, r=0.0, mat="NE")
        bx(m, "Cab", Gy, sx * 1.75, sx * 2.5, -0.9, 2.1, 3.15, 6.7, r=0.25)
        bx(m, "Seam", Cy, sx * 2.52, sx * 2.55, -0.6, 1.8, 4.0, 4.1, r=0.0, mat="NE")
    roof(m, Wh, top=6.75, w=2.55, t=0.35)
    for x in (-1.2, 0, 1.2): lathe(m, P(Cy), [(0.25, 7.05), (0.22, 7.25), (0.01, 7.6)], seg=5, loc=(x, 0.6, 0), part="Icicle")
    windshield(m, Bl, z1=4.6)


def BodyPagoda(m):
    """Pagoda Wagon (Sakura): red lacquer wagon, curved pagoda roof over the seat, paper lanterns."""
    Rd, Pk, Bk, Gd = "D6363C", "FFA7C8", "5A3A2E", "F2C14E"
    tub(m, Rd, Bk, hood=2.85, bumper=Bk)
    for (x, y) in ((-2.15, -0.75), (2.15, -0.75), (-2.15, 2.05), (2.15, 2.05)): cyl(m, P(Rd), (x, y, 2.6), r=0.16, h=4.3, seg=8, part="Pillar")
    prism(m, P(Bk), [(-2.9, -1.6), (2.9, -1.6), (2.9, 2.9), (-2.9, 2.9)], 0.25, loc=(0, 0, 6.9), part="Eave", bev=0.06)
    lathe(m, P(Bk), [(2.6, 7.15), (1.4, 7.45), (0.01, 7.6)], seg=4, rot=(0, 0, 45), loc=(0, 0.65, 0), part="Roof")
    for (x, y) in ((-2.8, -1.5), (2.8, -1.5), (-2.8, 2.8), (2.8, 2.8)): sphere(m, P(Gd), (x, y, 7.05), r=0.16, seg=6, rings=4, part="Tip")
    for sx in (-1, 1):
        cyl(m, P(Bk), (sx * 2.15, -0.75, 5.9), r=0.03, h=0.4, seg=4, part="Cord")
        sphere(m, P("FFE7C2", "NE"), (sx * 2.15, -0.75, 5.6), r=0.32, scl=(1, 1, 1.3), seg=8, rings=6, part="Lantern")
    bx(m, "Petals", Pk, -1.6, 1.6, -3.4, -1.4, 2.86, 2.9, r=0.02)


def BodySweetTruck(m):
    """Sweet Truck (Candy Kingdom): candy-striped truck, cupcake fender caps, lollipop antenna."""
    Pk, Mt, Ye, Ch = "FF6FA8", "7FE8C3", "FFE36E", "6B3E2E"
    tub(m, "FFF2F6", Pk, hood=2.9, fender=Mt, bumper=Ch)
    for k in range(7): bx(m, "Stripe", Pk, -2.52, 2.52, -3.4 + k * 1.0, -3.0 + k * 1.0, 0.9, 2.0, r=0.1)
    for (x, y) in ((-2.6, -3.0), (2.6, -3.0), (-2.6, 3.1), (2.6, 3.1)):
        cyl(m, P(Ch), (x, y, 2.3), r=0.5, h=0.35, r2=0.42, seg=10, part="Cupcake")
        sphere(m, P("FFF2F6"), (x, y, 2.75), r=0.48, scl=(1, 1, 0.7), seg=10, rings=6, part="Frosting")
        sphere(m, P(TAIL), (x, y, 3.08), r=0.12, seg=6, rings=4, part="Cherry")
    cyl(m, P("FFFFFF"), (-2.2, 2.0, 2.6), r=0.05, h=3.6, seg=5, part="Stick")
    cyl(m, P(Ye), (-2.2, 2.0, 6.4), r=0.55, h=0.16, seg=14, rot=(90, 0, 0), part="Lollipop")
    windshield(m, Pk, z1=4.3)


def BodyReefDiver(m):
    """Reef Diver (Sunken Atlantis): rounded teal submarine hull, brass portholes, fins and a periscope."""
    Te, Nv, Co, Br = "1FB7A6", "155E8C", "FF7A5C", "D9A441"
    tub(m, Te, Nv, hood=3.0, fender=Nv)
    for sx in (-1, 1):
        sphere(m, P(Te), (sx * 2.1, 0.55, 4.2), r=1.0, scl=(0.45, 1.7, 1.2), seg=10, rings=7, part="Pod")
        for y in (-0.3, 1.4): torus(m, P(Br), (sx * 2.55, y, 4.3), R=0.32, r=0.08, seg=12, rseg=4, rot=(0, 90, 0), part="Porthole")
    prism(m, P(Co), [(0, 0), (1.6, 0), (1.3, 0.9), (0.2, 0.9)], 0.14, loc=(-0.07, -3.6, 3.0), rot=(90, 0, 90), part="Fin")   # nose fin on the hood
    for sx in (-1, 1): prism(m, P(Co), [(0, 0), (1.0, 0.4), (1.0, 1.0), (0, 1.2)], 0.12, loc=(sx * 2.5, 2.6, 2.45), rot=(90, 0, 90 if sx > 0 else -90), part="Fin")
    cyl(m, P(Br), (1.9, -0.6, 3.15), r=0.12, h=3.2, seg=8, part="Periscope")
    bx(m, "Periscope", Br, 1.75, 2.05, -0.95, -0.45, 6.2, 6.55, r=0.06)
    windshield(m, Br, z1=4.2)


def BodyToyTruck(m):
    """Toy Truck (Giant Toybox): chunky primary-colour toy truck, building-block studs, a wind-up key."""
    Rd, Bl, Ye, Gn = "E8443A", "3A7BE8", "FFD23A", "4CC35A"
    tub(m, Rd, Bl, hood=3.0, fender=Bl, bumper=Ye)
    for x in (-1.3, -0.45, 0.45, 1.3):
        for y in (-3.5, -2.6, -1.7): cyl(m, P(Rd), (x, y, 3.0), r=0.26, h=0.22, seg=10, part="Stud")
    for sx in (-1, 1):
        bx(m, "Block", Gn, sx * 1.75, sx * 2.45, -0.9, 0.6, 3.15, 4.4, r=0.05)
        bx(m, "Block", Ye, sx * 1.75, sx * 2.45, 0.6, 2.1, 3.15, 4.0, r=0.05)
    cyl(m, P(Ye), (0, 4.2, 1.2), r=0.12, h=0.9, rot=(90, 0, 0), seg=8, part="Key")
    torus(m, P(Ye), (0, 4.95, 1.6), R=0.42, r=0.12, seg=12, rseg=5, rot=(0, 90, 0), part="Key")
    windshield(m, Bl, z1=4.4)


def BodyBrassCarriage(m):
    """Brass Carriage (Clockwork City): steampunk brass and wood carriage with pipes, gauges and a little chimney."""
    Br, Cu, Tl, Wd = "D9A441", "C46A3A", "3FBFB4", "8A5530"
    tub(m, Wd, Br, hood=2.9, fender=Br, bumper=Cu)
    for sx in (-1, 1):
        tube(m, P(Cu), [(sx * 2.55, -3.4, 2.5), (sx * 2.6, -1.0, 2.55), (sx * 2.6, 1.5, 2.55), (sx * 2.4, 3.6, 2.6)], r=0.14, seg=8, part="Pipe", smooth=3)
        cyl(m, P(Br), (sx * 1.95, -0.75, 2.6), r=0.14, h=4.2, seg=8, part="Pillar")
        cyl(m, P(Br), (sx * 1.95, 2.05, 2.6), r=0.14, h=4.2, seg=8, part="Pillar")
    roof(m, Wd, top=6.8, w=2.3)
    for x in (-0.9, 0.9):
        cyl(m, P(Br), (x, -2.1, 2.95), r=0.38, h=0.15, seg=14, rot=(90, 0, 0), part="Gauge")
        cyl(m, P("FFF6E0"), (x, -2.12, 2.95), r=0.3, h=0.05, seg=14, rot=(90, 0, 0), part="Gauge")
    cyl(m, P(DARK), (-2.0, -2.8, 2.9), r=0.2, h=1.6, r2=0.28, seg=8, part="Chimney")
    torus(m, P(Tl), (0, -3.0, 3.0), R=0.5, r=0.08, seg=12, rseg=4, part="Cog")


def BodySkyCruiser(m):
    """Sky Cruiser (Cloud Kingdom): streamlined white and sky-blue cruiser with cloud puffs and small wings."""
    Wh, Sk, Gd = "FFFFFF", "8FD3FF", "F2C14E"
    tub(m, Wh, Sk, hood=2.8, fender=Sk)
    sphere(m, P(Wh), (0, -2.6, 2.85), r=1.6, scl=(1.3, 0.9, 0.35), seg=12, rings=6, part="Nose")
    for sx in (-1, 1):
        prism(m, P(Sk), [(0, -0.6), (1.6, 0.4), (1.6, 0.9), (0, 0.9)], 0.18, loc=(sx * 2.45, 0.6, 2.1), rot=(0, 0, 0 if sx > 0 else 180), part="Wing")
        bx(m, "WingTip", Gd, sx * 3.95 - 0.08, sx * 3.95 + 0.08, 0.9, 1.5, 2.08, 2.32, r=0.04)
    rnd = random.Random(13)
    for (x, y, z) in ((-2.4, 3.3, 2.6), (2.4, 3.3, 2.6), (-2.5, -3.4, 2.6), (2.5, -3.4, 2.6)):
        for k in range(3): sphere(m, P("F6FAFF"), (x + rnd.uniform(-0.3, 0.3), y + rnd.uniform(-0.3, 0.3), z + 0.1 * k), r=0.45 - 0.08 * k, seg=8, rings=5, part="Puff")
    windshield(m, Sk, z1=4.0)


def BodyStarCruiser(m):
    """Star Cruiser (Cosmic Sanctuary, legendary): sleek navy cruiser, star-shaped neon trims, tail fins and a glowing halo ring."""
    Nv, Vi, Gd, Cy = "1B2350", "7A5CFF", "FFD86B", "7FE8FF"
    tub(m, Nv, Vi, hood=2.8, fender=Vi, bumper=Nv)
    for sx in (-1, 1):
        bx(m, "Trim", Cy, sx * 2.5 - 0.03, sx * 2.5 + 0.03, -3.6, 3.7, 1.95, 2.02, r=0.0, mat="NE")
        prism(m, P(Vi), [(0, 0), (1.3, 0.2), (1.6, 1.8), (0.4, 1.8)], 0.14, loc=(sx * 2.2, 3.0, 2.55), rot=(90, 0, 90 if sx > 0 else -90), part="TailFin")
    torus(m, P(Gd, "NE"), (0, 0.4, 7.35), R=1.55, r=0.11, seg=28, rseg=5, part="Halo")
    for (x, y) in ((0, -3.0), (-1.4, -2.2), (1.4, -2.2)):
        prism(m, P(Gd, "NE"), star_poly(5, 0.42, 0.18), 0.06, loc=(x, y, 2.82), part="Star")
    lathe(m, P(Nv), [(0.4, 2.8), (0.25, 3.4), (0.01, 4.0)], seg=6, loc=(0, -3.75, 0), part="NoseSpike")
    windshield(m, Vi, z1=4.1)


BUILDERS = {f.__name__: f for f in (BodyFrostHauler, BodyDuneRunner, BodyGraveHauler, BodyGeodeCrawler, BodyArcadeKart, BodySafari, BodyPolarTitan,
                                    BodyPagoda, BodySweetTruck, BodyReefDiver, BodyToyTruck, BodyBrassCarriage, BodySkyCruiser, BodyStarCruiser)}
