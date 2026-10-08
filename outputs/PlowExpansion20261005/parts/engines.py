# engines.py - 30 snowplow engines. Origin = bottom-centre (sits on the rear deck); front = -Y (towards the driver).
# Safe envelope: x +-1.75, y -0.5..+1.4, z 0.05..3.4 (Legendary up to 4.6). Keep tall parts at y >= -0.3 (roll bar).
# Detail goes on the rear (+Y) face and top because the gameplay camera sits behind the vehicle.
import math
from mathutils import Vector, Matrix
from partlib import *
from w2lib import rock

YC = 0.45          # footprint centre along Y
YR = 1.38          # rear face limit


def base(m, pc, w=3.0, d=1.75, h=0.22, part="Base", r=0.08):
    rbox(m, pc, (0, YC, 0.05), (w, d, h), r=r, bseg=1, part=part, base=True)


def ring_band(m, pc, c, r_in, r_out, depth, axis=(0, 1, 0), seg=20, part="Shroud"):
    verts = []; faces = []
    for i in range(seg):
        a = 2 * math.pi * i / seg; ca, sa = math.cos(a), math.sin(a)
        for z in (0, depth):
            verts += [(r_in * ca, r_in * sa, z), (r_out * ca, r_out * sa, z)]
    for i in range(seg):
        j = (i + 1) % seg; a, b = i * 4, j * 4   # a+0 in z0, a+1 out z0, a+2 in z1, a+3 out z1
        faces += [(a + 1, b + 1, b + 3, a + 3), (a + 0, a + 2, b + 2, b + 0), (a + 0, b + 0, b + 1, a + 1), (a + 2, a + 3, b + 3, b + 2)]
    mesh(m, pc, verts, faces, part=part, mat=Matrix.Translation(Vector(c)) @ frame(axis))


def fan(m, pc_blade, c, R, n=6, axis=(0, 1, 0), pitch=28, width=0.36, part="SpinFan", poly=None, thick=0.06):
    a = Vector(axis).normalized(); F = Matrix.Translation(Vector(c)) @ frame(a)
    for i in range(n):
        ang = 2 * math.pi * i / n
        M = F @ Matrix.Rotation(ang, 4, 'Z') @ Matrix.Translation((R * 0.52, 0, 0)) @ Matrix.Rotation(math.radians(pitch), 4, 'X')
        if poly is None:
            box_m(m, pc_blade, M, (R * 0.86, width, thick), r=0.02, part=part)
        else:
            tb = bmesh.new(); vs = [tb.verts.new((x, y, 0)) for x, y in poly]; f = tb.faces.new(vs)
            ext = bmesh.ops.extrude_face_region(tb, geom=[f]); nv = [e for e in ext['geom'] if isinstance(e, bmesh.types.BMVert)]
            bmesh.ops.translate(tb, vec=(0, 0, thick), verts=nv); bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
            bmesh.ops.triangulate(tb, faces=[f for f in tb.faces if len(f.verts) > 4])
            put(m, part, pc_blade, tb, F @ Matrix.Rotation(ang, 4, 'Z') @ Matrix.Rotation(-math.pi / 2, 4, 'Z') @ Matrix.Rotation(math.radians(pitch * 0.5), 4, 'Y'))


def fins(m, pc, c, r, h, n=4, gap=0.18, t=0.07, axis=(0, 0, 1), part="Fins", seg=12):
    a = Vector(axis).normalized()
    for k in range(n):
        disc(m, pc, Vector(c) + a * (k * gap), r, t, axis=a, seg=seg, part=part)


def capsule(m, pc, c, r, length, axis=(1, 0, 0), part="Tank", seg=12):
    a = Vector(axis).normalized(); c = Vector(c)
    rod(m, pc, c - a * (length / 2 - r), c + a * (length / 2 - r), r=r, seg=seg, part=part, cap=False)
    for s in (-1, 1): sphere(m, pc, c + a * s * (length / 2 - r), r, seg=seg, rings=max(5, seg // 2), part=part)


import bmesh


# =====================================================================================
def EngineStarter(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.6, 1.6)
    rbox(m, P(p[2]), (0, YC, 0.27), (2.0, 1.3, 1.05), r=0.18, bseg=2, part="Block", base=True)
    rbox(m, P(STEEL, "ME"), (0.15, YC, 1.3), (1.4, 1.0, 0.3), r=0.08, part="Head", base=True)
    for k in range(4):
        box(m, P(p[3]), (0.15, YC - 0.36 + k * 0.24, 1.66), (1.3, 0.08, 0.14), r=0.02, part="Fins")
    # rear grille
    box(m, P(p[3]), (0, YC + 0.66, 0.78), (1.4, 0.06, 0.62), r=0.04, part="Fins")
    for k in range(3): box(m, P(STEEL, "ME"), (0, YC + 0.7, 0.6 + k * 0.18), (1.25, 0.04, 0.07), r=0.01, part="Head")
    # exhaust pipe
    tube(m, P(STEEL, "ME"), [(-0.8, YC + 0.3, 1.0), (-1.15, YC + 0.45, 1.15), (-1.2, YC + 0.55, 1.8), (-1.15, YC + 0.6, 2.35)], r=0.12, seg=8, part="Head", smooth=3)
    disc(m, P(p[3]), (-1.15, YC + 0.6, 2.3), 0.15, 0.18, axis=(0, 0.1, 1), seg=8, part="Tip")
    # air filter + pull handle
    disc(m, P(p[1]), (0.9, YC - 0.1, 1.3), 0.32, 0.3, axis=(0, 0, 1), seg=12, bev=0.06, part="Filter")
    torus(m, P(p[3]), (1.05, YC + 0.68, 0.95), R=0.14, r=0.04, seg=8, rseg=4, rot=(90, 0, 0), part="Fins")
    for sx in (-1, 1): box(m, P(p[0]), (sx * 0.65, YC + 0.66, 0.35), (0.4, 0.04, 0.08), r=0.01, part="Trim")


def EngineSnowball(m, c):
    p = c["palette"]
    disc(m, P(p[3]), (0, YC + 0.05, 0.05), 0.95, 0.2, axis=(0, 0, 1), seg=16, bev=0.05, part="Base")
    sphere(m, P(p[0]), (0, YC + 0.05, 1.2), 1.08, scl=(1.05, 0.84, 0.95), seg=16, rings=10, part="Ball")
    for (x, y, z, r) in ((0.75, YC + 0.45, 0.75, 0.38), (-0.8, YC + 0.3, 0.9, 0.34), (0.3, YC + 0.65, 1.7, 0.3)):
        sphere(m, P(p[0]), (x, y, z), r, seg=10, rings=6, part="Ball")
    torus(m, P(p[2]), (0, YC, 0.85), R=0.98, r=0.1, seg=20, rseg=6, part="Band")
    lathe(m, P(p[1]), [(1.0, 0), (1.02, 0.08), (0.62, 0.14), (0.6, 0.45), (0.45, 0.62), (0, 0.66)], loc=(0, YC, 2.02), seg=16, part="Cap")
    sphere(m, P(WHITE), (0, YC, 2.72), 0.16, seg=8, rings=5, part="Ball")
    tube(m, P(p[3]), [(0.55, YC + 0.75, 1.5), (0.7, YC + 0.95, 1.75), (0.72, YC + 0.95, 2.05)], r=0.15, seg=8, part="Pipe", smooth=2)
    disc(m, P(p[3]), (0.72, YC + 0.95, 2.0), 0.2, 0.12, axis=(0, 0, 1), seg=8, part="Pipe")
    for (x, z) in ((-0.3, 1.35), (0.3, 1.35), (0, 1.0)):
        sphere(m, P("23252B"), (x, YC + 0.95, z), 0.08, seg=6, rings=4, part="Coal")


def EngineBalanced(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.9, 1.7)
    rbox(m, P(p[3]), (0, YC, 0.27), (2.6, 1.4, 0.8), r=0.15, bseg=2, part="Case", base=True)
    for sx in (-1, 1):
        x = sx * 0.66
        cyl(m, P(p[0]), (x, YC + 0.1, 1.05), r=0.46, h=0.95, seg=14, part="Cyl")
        fins(m, P(p[3]), (x, YC + 0.1, 1.15), 0.58, 0.8, n=4, gap=0.2, axis=(0, 0, 1), part="Fins", seg=14)
        rbox(m, P(p[2]), (x, YC + 0.1, 1.98), (1.0, 1.0, 0.32), r=0.1, part="Heads", base=True)
        tube(m, P(STEEL, "ME"), [(x, YC + 0.55, 1.6), (x + sx * 0.25, YC + 0.95, 1.55), (x + sx * 0.4, YC + 1.15, 1.95), (x + sx * 0.45, YC + 1.2, 2.75)], r=0.11, seg=8, part="Chrome", smooth=3)
        disc(m, P(STEEL, "ME"), (x + sx * 0.45, YC + 1.2, 2.65), 0.15, 0.22, axis=(0, 0, 1), seg=10, part="Chrome")
    capsule(m, P(p[1]), (0, YC - 0.15, 2.5), 0.32, 1.25, axis=(0, 1, 0), part="Tank")
    disc(m, P(STEEL, "ME"), (0, YC - 0.15, 2.78), 0.1, 0.1, axis=(0, 0, 1), seg=8, part="Chrome")
    for sx in (-1, 1): box(m, P(p[3]), (sx * 0.3, YC - 0.15, 2.25), (0.12, 0.6, 0.2), r=0.02, part="Case")
    box(m, P(p[2]), (0, YC + 0.71, 0.66), (1.6, 0.04, 0.12), r=0.01, part="Heads")


def EngineSandRunner(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.0, 1.6)
    rbox(m, P(p[0]), (0, YC, 0.27), (1.4, 1.4, 1.15), r=0.2, bseg=2, part="Body", base=True)
    for sx in (-1, 1):
        rod(m, P(p[0]), (sx * 0.6, YC, 0.85), (sx * 1.55, YC, 0.85), r=0.38, seg=12, part="Body")
        fins(m, P(p[3]), (sx * 0.8, YC, 0.85), 0.5, 0.6, n=4, gap=0.2 * sx, axis=(1, 0, 0), part="Fins", seg=12)
        rbox(m, P(p[2]), (sx * 1.55, YC, 0.85), (0.22, 0.85, 0.85), r=0.08, part="Caps")
    # turquoise intake fan (rear facing) on a pylon
    cz = 2.05; cy = YC + 0.3
    box(m, P(p[3]), (0, cy - 0.1, 1.5), (0.5, 0.5, 0.4), r=0.06, part="Fins")
    ring_band(m, P(p[1]), (0, cy - 0.35, cz), 0.62, 0.78, 0.7, axis=(0, 1, 0), seg=18, part="Shroud")
    fan(m, P(p[1]), (0, cy, cz), 0.62, n=6, axis=(0, 1, 0), part="SpinFan")
    disc(m, P(p[2]), (0, cy - 0.05, cz), 0.2, 0.3, axis=(0, 1, 0), seg=10, r2=0.06, part="Caps")
    tube(m, P(p[3]), [(0.9, YC + 0.6, 1.0), (1.0, YC + 0.95, 1.1), (1.05, YC + 1.1, 1.55)], r=0.1, seg=8, part="Fins", smooth=2)


def EnginePower(m, c):
    p = c["palette"]
    base(m, P("3A3F4C"), 3.2, 1.8)
    rbox(m, P("3A3F4C", "ME"), (0, YC, 0.27), (2.8, 1.6, 1.6), r=0.14, bseg=2, part="Block", base=True)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(m, P(p[0]), (sx * 1.38, YC + sy * 0.78, 1.07), (0.26, 0.26, 1.62), r=0.06, part="Armor")
        # hazard plate on the side
        box(m, P(p[2]), (sx * 1.42, YC, 1.05), (0.06, 1.1, 0.8), r=0.02, part="Hazard")
        for k in range(4):
            flat(m, P("23252B"), [(-0.08, -0.36), (0.08, -0.36), (0.26, 0.36), (0.1, 0.36)], 0.03, (sx * 1.46, YC - 0.45 + k * 0.3, 1.05), axis=(sx, 0, 0), part="Stripes")
    rbox(m, P(p[0]), (0, YC, 1.85), (2.5, 1.4, 0.22), r=0.06, part="Armor", base=True)
    # scoop
    rbox(m, P(p[1]), (-0.3, YC - 0.05, 2.05), (1.0, 1.0, 0.5), r=0.12, part="Scoop", base=True)
    box(m, P("23252B"), (-0.3, YC - 0.56, 2.32), (0.75, 0.05, 0.28), r=0.02, part="Stripes")
    # twin tall stacks with rain caps
    for x in (0.65, 1.15):
        cyl(m, P(STEEL, "ME"), (x, YC + 0.45, 2.05), r=0.19, h=1.2, seg=10, part="Stacks")
        box(m, P(p[3]), (x, YC + 0.42, 3.3), (0.36, 0.4, 0.06), r=0.02, rot=(-25, 0, 0), part="Caps")
        torus(m, P(p[3]), (x, YC + 0.45, 2.6), R=0.2, r=0.05, seg=10, rseg=4, part="Caps")
    # rear grille
    box(m, P("23252B"), (0, YC + 0.81, 0.95), (2.0, 0.05, 0.9), r=0.03, part="Stripes")
    for k in range(5): box(m, P(STEEL, "ME"), (0, YC + 0.85, 0.6 + k * 0.17), (1.85, 0.04, 0.07), r=0.01, part="Stacks")


def EngineLantern(m, c):
    p = c["palette"]
    base(m, P(p[0]), 2.6, 1.6)
    prof = [(0, 0.3), (0.75, 0.33), (1.15, 0.65), (1.28, 1.2), (1.12, 1.75), (0.6, 2.05), (0, 2.1)]
    lathe(m, P(p[1]), prof, loc=(0, YC + 0.1, 0), seg=20, sx=1.08, sy=0.72, rib=(8, 0.07), part="Pumpkin")
    # glowing face on the rear
    yf = YC + 0.1 + 0.9
    for sx in (-1, 1):
        flat(m, P(p[3], "NE"), [(-0.24, 0), (0.24, 0), (0.02 * sx, 0.36)], 0.12, (sx * 0.45, yf - 0.06, 1.3), axis=(0, 1, 0), part="Glow")
    mouth = [(-0.62, 0.0), (-0.4, -0.18), (-0.2, -0.05), (0.0, -0.22), (0.2, -0.05), (0.4, -0.18), (0.62, 0.0), (0.45, 0.14), (0.2, 0.06), (0, 0.14), (-0.2, 0.06), (-0.45, 0.14)]
    flat(m, P(p[3], "NE"), mouth, 0.12, (0, yf - 0.08, 0.85), axis=(0, 1, 0), part="Glow")
    # stem + crooked chimney
    tube(m, P("4F8A3A"), [(0, YC + 0.1, 2.0), (0.05, YC + 0.1, 2.3), (0.25, YC + 0.15, 2.45)], r=0.13, seg=6, part="Stem", smooth=2)
    tube(m, P("2A1F3D"), [(-0.75, YC + 0.3, 1.6), (-0.85, YC + 0.35, 2.3), (-0.6, YC + 0.4, 2.75), (-0.8, YC + 0.45, 3.15)], r=0.16, seg=8, part="Chimney", smooth=3)
    disc(m, P(p[2]), (-0.8, YC + 0.45, 3.1), 0.24, 0.12, axis=(-0.2, 0, 1), seg=8, part="Bone")
    for sx in (-1, 1):
        sphere(m, P(p[2]), (sx * 1.15, YC + 0.75, 0.32), 0.17, seg=8, rings=5, part="Bone")
        flat(m, P("4F8A3A"), leaf_poly(0.7, 0.4), 0.05, (sx * 0.15, YC + 0.1, 2.05), axis=(0, 0, 1), up=(sx, 0.3, 0), part="Stem")


def EnginePhantom(m, c):
    p = c["palette"]
    base(m, P(p[0]), 3.0, 1.7)
    lathe(m, P(p[0]), [(0.0, 0.25), (0.75, 0.27), (0.95, 0.6), (0.85, 1.05), (0.4, 1.2), (0, 1.22)], loc=(0, YC, 0), seg=16, sx=1.3, sy=0.9, part="Case")
    for sx in (-1, 1):
        a = Vector((sx * math.sin(math.radians(34)), 0, math.cos(math.radians(34))))
        b0 = Vector((sx * 0.25, YC, 0.95)); b1 = b0 + a * 1.25
        rod(m, P(p[1]), b0, b1, r=0.4, seg=12, part="Cyl")
        for k in range(3):
            disc(m, P("2A1F3D"), b0 + a * (0.35 + k * 0.25), 0.52, 0.08, axis=a, seg=12, part="Fins")
        disc(m, P(p[0]), b1, 0.46, 0.25, axis=a, seg=12, bev=0.06, part="Case")
        # bone exhaust horns sweeping back and up
        h0 = b1 + Vector((0, 0.35, -0.2))
        tube(m, P(p[2]), [h0, h0 + Vector((sx * 0.25, 0.45, -0.05)), h0 + Vector((sx * 0.35, 0.75, 0.4)), h0 + Vector((sx * 0.2, 0.85, 0.95))], r=0.15, r2=0.04, seg=8, part="Horns", smooth=3)
    sphere(m, P(p[3], "NE"), (0, YC + 0.1, 1.6), 0.3, seg=12, rings=8, part="Glow")
    torus(m, P(p[2]), (0, YC + 0.1, 1.6), R=0.36, r=0.06, seg=14, rseg=5, rot=(90, 0, 0), part="Horns")
    for sx in (-1, 1): sphere(m, P(p[2]), (sx * 0.5, YC + 0.82, 0.55), 0.13, seg=8, rings=5, part="Horns")


def EngineGeode(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.8, 1.6)
    rock(m, P("5A6585"), (-0.72, YC, 0.95), (0.85, 0.82, 0.85), seed=3, sub=1, jag=0.12, part="Rock", flatz=-0.7)
    rock(m, P("5A6585"), (0.78, YC + 0.05, 0.9), (0.8, 0.8, 0.8), seed=7, sub=1, jag=0.12, part="Rock", flatz=-0.65)
    m.flat("Rock", P("5A6585"), 1)
    rock(m, P(p[1]), (0.0, YC, 0.9), (0.55, 0.7, 0.55), seed=5, sub=1, jag=0.1, part="Lining")
    m.flat("Lining", P(p[1]), 1)
    for (bx, bz, tx, tz, r) in ((0, 1.1, 0.0, 2.75, 0.32), (-0.25, 1.0, -0.75, 2.3, 0.22), (0.25, 1.0, 0.7, 2.35, 0.24), (0.0, 1.0, 0.25, 2.1, 0.18), (-0.1, 1.0, -0.4, 1.95, 0.16)):
        crystal(m, P(p[0], "GL"), (bx, YC + 0.1, bz), (tx, YC + 0.25, tz), r, seg=6, part="Crystals")
    for (x, y, z) in ((0.35, YC + 0.75, 0.6), (-0.4, YC + 0.75, 0.55)):
        crystal(m, P(p[2], "GL"), (x, y - 0.2, z), (x * 1.3, y + 0.25, z + 0.25), 0.1, seg=5, part="Shards")
    for (x, y) in ((-0.6, YC + 0.75), (0.6, YC + 0.75)):
        pass


def EngineReactor(m, c):
    p = c["palette"]
    disc(m, P(p[3]), (0, YC + 0.05, 0.05), 0.95, 0.22, axis=(0, 0, 1), seg=18, bev=0.06, part="Base")
    disc(m, P(p[3]), (0, YC + 0.05, 0.27), 0.9, 0.5, axis=(0, 0, 1), seg=18, bev=0.06, part="Base")
    torus(m, P(p[2], "ME"), (0, YC + 0.05, 0.8), R=0.86, r=0.08, seg=20, rseg=6, part="Cage")
    torus(m, P(p[2], "ME"), (0, YC + 0.05, 2.5), R=0.86, r=0.08, seg=20, rseg=6, part="Cage")
    for k in range(6):
        a = 2 * math.pi * k / 6 + 0.26
        rod(m, P("2C3350"), (0.86 * math.cos(a), YC + 0.05 + 0.86 * math.sin(a), 0.8), (0.86 * math.cos(a), YC + 0.05 + 0.86 * math.sin(a), 2.5), r=0.08, seg=6, part="Bars")
    crystal(m, P(p[1], "GL"), (0, YC, 0.75), (0, YC, 2.45), 0.32, seg=6, part="Rods", mid=0.8)
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.78
        crystal(m, P(p[1], "GL"), (0.5 * math.cos(a), YC + 0.45 * math.sin(a), 0.75), (0.55 * math.cos(a), YC + 0.5 * math.sin(a), 1.95), 0.16, seg=6, part="Rods", mid=0.8)
    lathe(m, P(p[3]), [(0.98, 0), (1.0, 0.1), (0.8, 0.32), (0.35, 0.45), (0.3, 0.6), (0, 0.62)], loc=(0, YC + 0.05, 2.5), seg=18, sy=0.95, part="Base")
    disc(m, P(p[0]), (0, YC, 3.1), 0.16, 0.25, axis=(0, 0, 1), seg=8, part="Tip")
    box(m, P(p[2], "ME"), (0, YC + 1.02, 0.55), (0.9, 0.08, 0.3), r=0.03, part="Cage")


def Engine8Bit(m, c):
    p = c["palette"]
    s = 0.5
    rbox(m, P(p[3]), (0, YC, 0.05), (3.0, 1.6, 0.25), r=0.03, part="Base", base=True)
    box(m, P(p[3]), (0, YC, 1.05), (2.5, 1.5, 1.5), r=0.04, part="Block")
    # pixel decals on the rear and sides
    pat = ["10101", "01110", "10101"]
    for r_, row in enumerate(pat):
        for i, ch in enumerate(row):
            col = P(p[0]) if ch == "1" else P(p[1])
            box(m, col, (-1.0 + i * 0.5, YC + 0.76, 1.55 - r_ * 0.45), (0.44, 0.06, 0.4), r=0.02, part="Px" + ("A" if ch == "1" else "B"))
    for sx in (-1, 1):
        for k in range(2):
            box(m, P(p[1]), (sx * 1.26, YC - 0.3 + k * 0.6, 1.1), (0.06, 0.42, 0.42), r=0.02, part="PxB")
    # yellow heat-sink voxels on top
    for i in range(4):
        box(m, P(p[2]), (-0.75 + i * 0.5, YC - 0.2, 1.98), (s * 0.9, s * 0.9, 0.36), r=0.03, part="Sink")
    # stepped pixel pipes
    for sx, col in ((1, P(p[0])), (-1, P(p[1]))):
        steps = [(0.85, 0.5, 2.0), (0.85, 0.5, 2.4), (0.85, 0.95, 2.4), (0.85, 0.95, 2.8)]
        for (x, y, z) in steps:
            box(m, col, (sx * x, YC + y - 0.3, z), (0.42, 0.42, 0.42), r=0.03, part="Pipes" + ("A" if sx > 0 else "B"))
        box(m, P(p[3]), (sx * 0.85, YC + 0.65, 3.04), (0.5, 0.5, 0.06), r=0.02, part="Block")


def EngineArcade(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.2, 1.7)
    rbox(m, P(p[3]), (0, YC - 0.1, 0.27), (2.4, 1.4, 1.0), r=0.14, part="Body", base=True)
    for sx in (-1, 1):
        flat(m, P(p[0]), [(-0.7, 0), (0.7, 0), (0.7, 1.6), (0.2, 2.3), (-0.7, 2.3)], 0.16, (sx * 1.3 - (0.16 if sx > 0 else 0), YC, 0.27), axis=(1, 0, 0), part="Sides") if False else None
        rbox(m, P(p[0]), (sx * 1.25, YC + 0.1, 0.27), (0.3, 1.5, 2.4), r=0.1, part="Sides", base=True)
    cz = 1.85; cy = YC + 0.25
    ring_band(m, P(p[3]), (0, cy - 0.45, cz), 1.05, 1.28, 0.95, axis=(0, 1, 0), seg=22, part="Shroud")
    torus(m, P(p[0], "NE"), (0, cy + 0.5, cz), R=1.17, r=0.06, seg=24, rseg=5, rot=(90, 0, 0), part="Neon")
    fan(m, P(p[1]), (0, cy + 0.15, cz), 1.02, n=8, axis=(0, 1, 0), pitch=30, width=0.38, part="SpinFan")
    disc(m, P(p[2]), (0, cy - 0.2, cz), 0.3, 0.5, axis=(0, 1, 0), seg=12, r2=0.12, part="Hub")
    for sx in (-1, 1):
        disc(m, P(p[2]), (sx * 0.6, YC - 0.85, 1.05), 0.12, 0.08, axis=(0, -1, 0), seg=8, part="Hub")
    box(m, P(p[2]), (0, YC + 0.65, 0.55), (0.5, 0.05, 0.2), r=0.02, part="Hub")


def EngineTiki(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.0, 1.6)
    rbox(m, P(p[1], "WO"), (0, YC, 0.27), (1.9, 1.45, 2.3), r=0.16, bseg=2, part="Totem", base=True)
    yf = YC + 0.73
    for sx in (-1, 1):
        box(m, P(p[2]), (sx * 0.45, yf + 0.02, 1.95), (0.65, 0.14, 0.18), r=0.04, rot=(0, -sx * 12, 0), part="Paint")
        disc(m, P(p[2]), (sx * 0.45, yf - 0.02, 1.58), 0.27, 0.1, axis=(0, 1, 0), seg=12, part="Paint")
        disc(m, P("2E1E12"), (sx * 0.45, yf + 0.05, 1.58), 0.15, 0.06, axis=(0, 1, 0), seg=10, part="Dark")
    box(m, P("6E4426", "WO"), (0, yf + 0.06, 1.25), (0.3, 0.2, 0.55), r=0.06, part="Nose")
    rbox(m, P("2E1E12"), (0, yf + 0.0, 0.72), (1.25, 0.14, 0.45), r=0.08, part="Dark")
    for k in range(4): box(m, P("FFF4E0"), (-0.45 + k * 0.3, yf + 0.06, 0.86), (0.2, 0.06, 0.15), r=0.02, part="Teeth")
    for k in range(3): box(m, P("6E4426", "WO"), (0, YC, 0.55 + k * 0.7), (1.95, 1.5, 0.06), r=0.02, part="Nose")
    # leaf crown
    for k in range(6):
        a = k * 60 + 15
        flat(m, P(p[0] if k % 2 else p[3]), leaf_poly(1.0, 0.45), 0.05, (0, YC, 2.5), axis=(math.cos(math.radians(a)) * 0.3, math.sin(math.radians(a)) * 0.3, 1), up=(math.cos(math.radians(a)), math.sin(math.radians(a)), 0), part="Leaves")
    # bamboo exhausts
    for sx in (-1, 1):
        x = sx * 1.25
        cyl(m, P("8FC24A"), (x, YC + 0.45, 0.4), r=0.17, h=2.65, seg=8, part="Bamboo")
        for k in range(4): torus(m, P("5E8F2C"), (x, YC + 0.45, 0.9 + k * 0.6), R=0.18, r=0.05, seg=8, rseg=4, part="Joints")
        disc(m, P("5E8F2C"), (x, YC + 0.45, 3.0), 0.19, 0.06, axis=(0, 0, 1), seg=8, part="Joints")
        box(m, P(p[1], "WO"), (sx * 1.07, YC + 0.45, 1.2), (0.25, 0.25, 0.25), r=0.04, part="Totem")


def EngineJungleTurbine(m, c):
    p = c["palette"]
    base(m, P(p[1], "WO"), 2.8, 1.7)
    box(m, P(p[1], "WO"), (0, YC, 0.65), (0.6, 0.9, 0.8), r=0.08, part="Pylon")
    cz = 1.6
    lathe(m, P(p[0]), [(0.35, 0), (0.7, 0.15), (0.85, 0.6), (0.85, 1.3), (0.78, 1.75)], loc=(0, -0.3, cz), rot=(-90, 0, 0), seg=16, part="Nacelle")
    ring_band(m, P(p[2]), (0, 1.42 - 0.3, cz), 0.62, 0.86, 0.3, axis=(0, 1, 0), seg=16, part="Intake")
    disc(m, P(p[2], "NE"), (0, 1.2, cz), 0.62, 0.04, axis=(0, 1, 0), seg=14, part="Glow")
    fan(m, P(p[3]), (0, 1.3, cz), 0.6, n=7, axis=(0, 1, 0), part="SpinFan", width=0.3)
    disc(m, P(p[1], "WO"), (0, 1.25, cz), 0.18, 0.18, axis=(0, 1, 0), seg=8, r2=0.05, part="Pylon")
    # vine spiral around the casing
    pts = []
    for i in range(30):
        t = i / 29; a = t * 2 * math.pi * 2.2
        pts.append((0.88 * math.cos(a), -0.15 + t * 1.2, cz + 0.88 * math.sin(a)))
    tube(m, P(p[3]), pts, r=0.07, seg=5, part="Vine", smooth=1)
    for i in range(3, 29, 5):
        x, y, z = pts[i]
        flat(m, P(p[3]), leaf_poly(0.5, 0.28), 0.04, (x * 1.05, y, z * 1.0 + 0.0), axis=(x, 0, z - cz), up=(0, 1, 0), part="Vine")
    # big leaf fins on top and sides
    flat(m, P(p[0]), leaf_poly(1.15, 0.75), 0.06, (0, 0.2, cz + 0.65), axis=(1, 0, 0), up=(0, 0.45, 1), part="Leaves")
    for sx in (-1, 1):
        flat(m, P(p[3]), leaf_poly(1.0, 0.55), 0.05, (sx * 0.7, 0.4, cz - 0.1), axis=(0, 0, 1), up=(sx, 0.4, 0), part="Leaves2")


def EngineCryo(m, c):
    p = c["palette"]
    base(m, P(p[1]), 3.1, 1.7)
    rbox(m, P(p[0]), (-0.45, YC, 0.27), (1.9, 1.5, 1.35), r=0.16, bseg=2, part="Box", base=True)
    for k in range(4): box(m, P(p[2], "ME"), (-0.45, YC + 0.77, 0.55 + k * 0.26), (1.5, 0.05, 0.1), r=0.02, part="Vents")
    # coil column
    cyl(m, P(p[2], "ME"), (1.0, YC, 0.27), r=0.3, h=2.1, seg=12, part="Silver")
    helix(m, P(p[1]), (1.0, YC, 0.45), 0.42, 0.08, 1.75, 5, seg=6, part="Coil", n=50)
    lathe(m, P(p[2], "ME"), [(0.45, 0), (0.45, 0.12), (0.2, 0.25), (0, 0.27)], loc=(1.0, YC, 2.37), seg=12, part="Silver")
    # twin silver tanks on top
    for x in (-0.85, -0.1):
        capsule(m, P(p[2], "ME"), (x, YC, 1.95), 0.3, 1.45, axis=(0, 1, 0), part="Tanks")
        torus(m, P(p[1]), (x, YC + 0.3, 1.95), R=0.31, r=0.05, seg=12, rseg=4, rot=(90, 0, 0), part="Coil")
    for (x, y, z, tz) in ((-1.3, YC + 0.5, 1.6, 2.0), (0.3, YC - 0.4, 1.6, 1.95)):
        crystal(m, P(WHITE, "IC"), (x, y, z), (x - 0.1, y + 0.05, tz + 0.3), 0.12, seg=5, part="Frost")
    tube(m, P(p[1]), [(-0.1, YC + 0.75, 1.95), (0.4, YC + 0.95, 1.7), (0.8, YC + 0.4, 1.4)], r=0.07, seg=6, part="Coil", smooth=3)


def EnginePolar(m, c):
    p = c["palette"]
    base(m, P(p[2], "ME"), 3.2, 1.7)
    box(m, P(p[1]), (0, YC, 0.85), (1.0, 1.4, 1.0), r=0.15, part="Pylon")
    for sx in (-1, 1):
        x = sx * 0.88; cz = 1.35
        lathe(m, P(p[0]), [(0.4, 0), (0.62, 0.12), (0.72, 0.5), (0.7, 1.25), (0.55, 1.75)], loc=(x, -0.35, cz), rot=(-90, 0, 0), seg=16, part="Jets")
        ring_band(m, P(p[1]), (x, 0.65, cz), 0.7, 0.76, 0.32, axis=(0, 1, 0), seg=16, part="Bands")
        disc(m, P(p[3], "NE"), (x, 1.3, cz), 0.42, 0.04, axis=(0, 1, 0), seg=14, part="Glow")
        ring_band(m, P(p[2], "ME"), (x, 1.2, cz), 0.42, 0.56, 0.2, axis=(0, 1, 0), seg=14, part="Nozzle")
        disc(m, P(p[1]), (x, -0.36, cz), 0.4, 0.06, axis=(0, -1, 0), seg=14, part="Bands")
        sphere(m, P(p[2], "ME"), (x, -0.3, cz), 0.22, seg=8, rings=5, part="Nozzle")
        for k in range(3): box(m, P(p[1]), (x, 0.0 + k * 0.32, cz + 0.68), (0.36, 0.12, 0.08), r=0.02, part="Bands")
    flat(m, P(p[0]), [(-0.5, 0), (0.6, 0), (0.6, 0.15), (0.0, 1.0), (-0.4, 1.0)], 0.12, (-0.06, 0.3, 1.35), axis=(1, 0, 0), part="Jets")


def EngineZeroCore(m, c):
    p = c["palette"]
    lathe(m, P(p[2], "ME"), [(1.3, 0.05), (1.3, 0.25), (1.0, 0.35), (0.55, 0.5), (0.45, 0.85), (0.6, 0.95), (0, 0.97)], loc=(0, YC, 0), seg=18, sy=0.7, part="Silver")
    cz = 2.45
    for rotz in (0, 90):
        torus(m, P(p[2], "ME"), (0, YC, cz), R=1.15, r=0.09, seg=24, rseg=6, rot=(90, 0, rotz), arc=230, part="Arcs") if False else None
    # two cradle arcs (U shapes) crossing under and around the core
    for rz in (35, -35):
        pts = []
        for i in range(17):
            a = math.radians(-200 + 220 * i / 16)
            v = Vector((1.18 * math.cos(a), 0, 1.18 * math.sin(a)))
            v.rotate(Matrix.Rotation(math.radians(rz), 3, 'Z'))
            pts.append((v.x, YC + v.y, cz + v.z))
        tube(m, P(p[2], "ME"), pts, r=0.09, seg=6, part="Arcs", smooth=1)
        for e in (pts[0], pts[-1]): sphere(m, P(p[2], "ME"), e, 0.14, seg=8, rings=5, part="Arcs")
    rod(m, P(p[2], "ME"), (0, YC, 0.95), (0, YC, cz - 1.15), r=0.12, seg=8, part="Arcs")
    sphere(m, P(p[3], "IC"), (0, YC, cz), 0.78, seg=16, rings=10, part="Core")
    torus(m, P(p[0], "NE"), (0, YC, cz), R=0.8, r=0.07, seg=24, rseg=5, rot=(0, 0, 0), part="Glow")
    for k in range(6):
        a = 2 * math.pi * k / 6
        crystal(m, P(p[0], "IC"), (0.6 * math.cos(a), YC + 0.6 * math.sin(a) * 0.9, cz + 0.35), (1.0 * math.cos(a), YC + 0.95 * math.sin(a) * 0.9, cz + 0.95), 0.12, seg=5, part="Spikes")
    crystal(m, P(p[0], "IC"), (0, YC, cz + 0.65), (0, YC, cz + 1.5), 0.18, seg=6, part="Spikes")


def EngineLanternTwin(m, c):
    p = c["palette"]
    base(m, P(p[3], "WO"), 3.1, 1.7, h=0.3)
    prof = [(0.2, 0), (0.45, 0.05), (0.66, 0.4), (0.7, 0.85), (0.62, 1.3), (0.4, 1.6), (0.2, 1.65)]
    for sx in (-1, 1):
        x = sx * 0.78
        lathe(m, P(p[2]), prof, loc=(x, YC + 0.1, 0.62), seg=16, rib=(10, 0.05), part="Paper")
        disc(m, P(p[3], "WO"), (x, YC + 0.1, 0.35), 0.48, 0.3, axis=(0, 0, 1), seg=12, bev=0.05, part="Caps")
        disc(m, P(p[3], "WO"), (x, YC + 0.1, 2.22), 0.42, 0.22, axis=(0, 0, 1), seg=12, bev=0.05, part="Caps")
        torus(m, P(p[0]), (x, YC + 0.1, 1.47), R=0.71, r=0.05, seg=16, rseg=4, part="Bands")
        flat(m, P(GOLD, "ME"), L.flower_poly(0.3, 5, 4), 0.04, (x, YC + 0.1 + 0.71, 1.15), axis=(0, 1, 0), part="Gold")
        rod(m, P(GOLD, "ME"), (x, YC + 0.75, 0.6), (x, YC + 0.85, 0.2), r=0.04, seg=6, part="Gold") if False else None
        tube(m, P(GOLD, "ME"), [(x, YC + 0.1, 2.44), (x, YC + 0.1, 2.7)], r=0.07, seg=6, part="Gold", smooth=1)
    # wooden yoke + exhaust in the middle
    box(m, P(p[3], "WO"), (0, YC + 0.1, 2.78), (2.3, 0.3, 0.2), r=0.06, part="Caps")
    for sx in (-1, 1): box(m, P(p[3], "WO"), (sx * 1.15, YC + 0.1, 2.88), (0.3, 0.36, 0.16), r=0.04, rot=(0, -sx * 18, 0), part="Caps")
    cyl(m, P(p[0]), (0, YC + 0.35, 0.35), r=0.22, h=1.5, seg=10, part="Bands")
    disc(m, P(p[2]), (0, YC + 0.35, 1.85), 0.28, 0.12, axis=(0, 0, 1), seg=10, part="Paper")


def EngineBlossom(m, c):
    p = c["palette"]
    base(m, P(p[3], "WO"), 3.0, 1.7)
    box(m, P(p[3], "WO"), (0, YC - 0.1, 0.85), (0.9, 0.9, 1.1), r=0.1, part="Stand")
    cz = 1.95; cy = YC + 0.3
    ring_band(m, P(p[1]), (0, cy - 0.45, cz), 1.18, 1.42, 0.8, axis=(0, 1, 0), seg=22, part="Shroud")
    torus(m, P(p[2]), (0, cy + 0.35, cz), R=1.3, r=0.07, seg=22, rseg=5, rot=(90, 0, 0), part="Trim")
    fan(m, P(p[0]), (0, cy, cz), 1.15, n=5, axis=(0, 1, 0), part="SpinFan", poly=petal_poly(1.1, 0.8), thick=0.06, pitch=20)
    sphere(m, P(GOLD, "ME"), (0, cy + 0.1, cz), 0.28, seg=12, rings=7, part="Hub")
    for k in range(5):
        a = 2 * math.pi * k / 5 + 0.6
        sphere(m, P(p[2], "NE"), (0.22 * math.cos(a), cy + 0.32, cz + 0.22 * math.sin(a)), 0.06, seg=6, rings=4, part="Glow")
    for sx in (-1, 1):
        flat(m, P(p[0]), petal_poly(0.5, 0.42), 0.04, (sx * 1.2, YC + 0.8, 0.35), axis=(0, 1, 0), part="SpinFanB") if False else None
        box(m, P(p[2]), (sx * 1.0, YC + 0.1, 0.6), (0.5, 1.2, 0.5), r=0.08, part="Trim")


def EngineGumdrop(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.0, 1.7)
    rbox(m, P("F2C98A"), (0, YC, 0.27), (2.7, 1.5, 0.95), r=0.1, part="Wafer", base=True)
    for k in range(5): box(m, P("C9935A"), (-1.08 + k * 0.54, YC, 0.75), (0.07, 1.54, 0.99), r=0.02, part="Grid")
    for k in range(2): box(m, P("C9935A"), (0, YC, 0.5 + k * 0.45), (2.74, 1.54, 0.07), r=0.02, part="Grid")
    dome = [(0.55, 0), (0.56, 0.1), (0.5, 0.42), (0.3, 0.68), (0, 0.75)]
    for (x, y, col, s) in ((-0.8, YC + 0.1, p[0], 1.0), (0.15, YC - 0.15, p[1], 1.15), (0.95, YC + 0.25, p[2], 0.9)):
        lathe(m, P(col), [(r * s, z * s) for r, z in dome], loc=(x, y, 1.22), seg=14, part="Gum" + str(int(s * 10)))
    for (x, y, col) in ((-0.8, YC + 0.1, p[0]), (0.15, YC - 0.15, p[1]), (0.95, YC + 0.25, p[2])):
        for k in range(4):
            a = k * 1.7
            sphere(m, P(WHITE), (x + 0.3 * math.cos(a), y + 0.3 * math.sin(a), 1.65), 0.05, seg=6, rings=4, part="Sugar")
    path = [(1.15, YC + 0.75, 0.75), (1.35, YC + 0.95, 0.9), (1.4, YC + 1.0, 1.6), (1.35, YC + 0.95, 2.45)]
    L.stripes(m, [P(WHITE), P(p[0])], path, 0.15, seglen=0.3, seg=8, part="Pipe", smooth=3)
    disc(m, P(p[1]), (1.35, YC + 0.95, 2.4), 0.2, 0.14, axis=(0, 0, 1), seg=10, part="Gum11")


def EngineSugarV8(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.2, 1.75)
    rbox(m, P(p[3]), (0, YC, 0.27), (1.6, 1.6, 0.9), r=0.12, part="Block", base=True)
    for sx in (-1, 1):
        box(m, P(p[1]), (sx * 0.72, YC, 1.25), (0.8, 1.55, 0.5), r=0.12, rot=(0, sx * 32, 0), part="Banks")
        for k in range(4):
            y = YC - 0.55 + k * 0.37
            b0 = Vector((sx * 0.92, y, 1.45)); d = Vector((sx * 0.38, 0, 1)).normalized()
            rod(m, P(WHITE), b0, b0 + d * 1.15, r=0.05, seg=6, part="Sticks")
            col = P(p[0]) if k % 2 == 0 else P(p[2])
            disc(m, col, b0 + d * 1.25 - Vector((0, 0.07, 0)), 0.26, 0.14, axis=(0, 1, 0), seg=14, bev=0.04, part="Pops" + ("A" if k % 2 == 0 else "B"))
    # pink blower on top
    rbox(m, P(p[0]), (0, YC - 0.05, 1.45), (0.9, 1.3, 0.75), r=0.18, bseg=2, part="Blower", base=True)
    rbox(m, P(p[1]), (0, YC - 0.05, 2.15), (0.65, 0.7, 0.42), r=0.12, part="Scoop", base=True)
    box(m, P(p[2], "NE"), (0, YC + 0.32, 2.36), (0.42, 0.04, 0.2), r=0.02, part="Glow")
    for k in range(3): box(m, P(WHITE), (0, YC - 0.5 + k * 0.4, 2.18), (0.95, 0.08, 0.06), r=0.02, part="Sticks")
    rbox(m, P(p[2]), (0, YC + 0.82, 0.55), (1.0, 0.08, 0.4), r=0.04, part="Banks")


def EngineBubble(m, c):
    p = c["palette"]
    BR = "C9963A"
    base(m, P(p[1]), 2.8, 1.7)
    lathe(m, P(BR, "ME"), [(1.0, 0.27), (1.05, 0.45), (1.12, 0.6), (1.1, 1.4), (0.95, 1.95), (0.6, 2.35), (0, 2.45)], loc=(0, YC + 0.05, 0), seg=18, sy=0.84, part="Helmet")
    lathe(m, P(BR, "ME"), [(1.1, 0.45), (1.2, 0.55), (1.1, 0.65)], loc=(0, YC + 0.05, 0), seg=18, sy=0.84, part="Helmet")
    # rear porthole
    cy = YC + 0.98; cz = 1.35
    disc(m, P(p[0], "GL"), (0, cy - 0.06, cz), 0.5, 0.06, axis=(0, 1, 0), seg=16, part="Glass")
    torus(m, P(p[3]), (0, cy - 0.02, cz), R=0.55, r=0.1, seg=16, rseg=5, rot=(90, 0, 0), part="Ring")
    for k in range(6):
        a = 2 * math.pi * k / 6
        sphere(m, P(p[1]), (0.7 * math.cos(a), cy - 0.08, cz + 0.7 * math.sin(a)), 0.07, seg=6, rings=4, part="Bolts")
    for sx in (-1, 1):
        disc(m, P(p[0], "GL"), (sx * 1.02, YC, 1.4), 0.25, 0.08, axis=(sx, 0, 0), seg=10, part="Glass")
        torus(m, P(p[3]), (sx * 1.08, YC, 1.4), R=0.28, r=0.06, seg=10, rseg=4, rot=(0, 90, 0), part="Ring")
    # bubble pipe
    tube(m, P(p[2]), [(0.4, YC + 0.4, 2.2), (0.6, YC + 0.6, 2.45), (0.9, YC + 0.75, 2.55), (1.05, YC + 0.8, 2.75)], r=0.1, seg=8, part="Pipe", smooth=3)
    for (dx, dz, r) in ((0.0, 0.18, 0.13), (0.14, 0.42, 0.1), (-0.04, 0.6, 0.07)):
        sphere(m, P(p[3]), (1.05 + dx, YC + 0.8, 2.75 + dz), r, seg=8, rings=5, part="Bubbles")
    disc(m, P(p[2]), (0, YC, 2.4), 0.2, 0.18, axis=(0, 0, 1), seg=10, part="Pipe")


def EngineLeviathan(m, c):
    p = c["palette"]
    base(m, P(p[1]), 3.0, 1.75)
    box(m, P(p[1]), (0, YC + 0.1, 0.65), (0.8, 1.0, 0.85), r=0.1, part="Pylon")
    cz = 1.75
    lathe(m, P(p[0]), [(0.05, -0.0), (0.4, 0.1), (0.75, 0.55), (0.95, 1.1), (0.95, 1.55), (0.86, 1.85)], loc=(0, -0.45, cz), rot=(-90, 0, 0), seg=16, sx=1.0, sy=0.88, part="Body")
    ring_band(m, P(p[2]), (0, 1.4 - 0.32, cz), 0.66, 0.92, 0.3, axis=(0, 1, 0), seg=18, part="Intake")
    disc(m, P(p[3], "NE"), (0, 1.12, cz), 0.66, 0.04, axis=(0, 1, 0), seg=14, part="Glow")
    fan(m, P(p[2]), (0, 1.22, cz), 0.62, n=6, axis=(0, 1, 0), part="SpinFan", poly=[(0, -0.12), (0.6, -0.06), (0.62, 0.18), (0.1, 0.12)], thick=0.05)
    # fins: dorsal, pectoral, tail flukes at the front
    flat(m, P(p[1]), [(-0.6, 0), (0.7, 0), (0.25, 0.25), (-0.35, 0.95)], 0.12, (-0.06, 0.45, cz + 0.8), axis=(1, 0, 0), part="Fins")
    for sx in (-1, 1):
        flat(m, P(p[1]), [(0, 0), (0.75, -0.05), (0.95, -0.45), (0.25, -0.2)], 0.08, (sx * 0.8, 0.5, cz - 0.3), axis=(0, 0, 1), up=(sx, 0, 0), part="Fins") if False else None
        flat(m, P(p[1]), [(-0.4, 0), (0.4, 0), (0.1, -0.5), (-0.5, -0.8)], 0.08, (sx * 0.85, 0.65, cz - 0.25), axis=(sx, 0, 0), part="Fins")
        flat(m, P(p[1]), [(0, 0), (0.25, 0.1), (0.85, 0.6), (0.3, 0.35)], 0.08, (sx * 0.02, -0.4, cz), axis=(0, -1, 0), part="Fins") if False else None
    for sx in (-1, 1):
        disc(m, P(p[3]), (sx * 0.62, 1.05, cz + 0.45), 0.1, 0.05, axis=(sx, 0.4, 0.3), seg=8, part="Eyes") if False else None
    sphere(m, P(p[3]), (0, -0.15, cz), 0.3, seg=10, rings=6, part="Stripes")
    for k in range(4): torus(m, P(p[3]), (0, 0.1 + k * 0.25, cz), R=0.97, r=0.035, seg=16, rseg=4, rot=(90, 0, 0), part="Stripes") if k in (1, 2) else None


def EngineWindup(m, c):
    p = c["palette"]
    base(m, P(p[1]), 2.9, 1.7)
    rbox(m, P(p[0]), (0, YC, 0.27), (2.4, 1.5, 1.45), r=0.25, bseg=2, part="Body", base=True)
    rbox(m, P(p[1]), (0, YC, 1.6), (2.2, 1.35, 0.25), r=0.1, part="Lid", base=True)
    for z in (0.5, 1.3): box(m, P(p[2]), (0, YC, z), (2.46, 1.56, 0.12), r=0.05, part="Trim")
    for sx in (-1, 1):
        disc(m, P(p[3]), (sx * 1.2, YC, 0.85), 0.35, 0.12, axis=(sx, 0, 0), seg=14, part="Dots")
    disc(m, P(p[2]), (0, YC + 0.75, 0.9), 0.32, 0.06, axis=(0, 1, 0), seg=14, part="Trim")
    disc(m, P(p[1]), (0, YC + 0.8, 0.9), 0.14, 0.04, axis=(0, 1, 0), seg=10, part="Lid")
    # giant wind-up key
    cyl(m, P(p[2], "ME"), (0, YC + 0.2, 1.85), r=0.15, h=0.6, seg=10, part="SpinKey")
    cyl(m, P(p[2], "ME"), (0, YC + 0.2, 1.85), r=0.28, h=0.12, seg=12, part="SpinKey")
    for sx in (-1, 1):
        lobe = [(0.12 * sx, -0.2), (0.12 * sx, 0.2)]
        flat(m, P(p[2], "ME"), [(x * 0.6 + sx * 0.6, y * 0.7 + 0.55) for x, y in circle_poly(0.75, 14)], 0.16, (0, YC + 0.2 - 0.08, 2.3), axis=(0, 1, 0), part="SpinKey")
    disc(m, P(p[2], "ME"), (0, YC + 0.12, 2.35 + 0.55), 0.3, 0.16, axis=(0, 1, 0), seg=10, part="SpinKey") if False else None
    for sx in (-1, 1):
        disc(m, P(p[0]), (sx * 0.72, YC + 0.3, 2.9), 0.18, 0.04, axis=(0, 1, 0), seg=10, part="Dots") if False else None


def EngineJackbox(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.9, 1.7)
    rbox(m, P(p[1]), (0, YC, 0.27), (2.2, 1.55, 1.75), r=0.12, bseg=2, part="Box", base=True)
    for sx in (-1, 1):
        flat(m, P(p[2]), star_poly(5, 0.48, 0.2), 0.05, (sx * 1.1, YC, 1.15), axis=(sx, 0, 0), part="Stars")
    flat(m, P(p[2]), star_poly(5, 0.5, 0.21), 0.05, (0, YC + 0.78, 1.15), axis=(0, 1, 0), part="Stars")
    for z in (0.4, 1.9): box(m, P(p[0]), (0, YC, z), (2.26, 1.6, 0.14), r=0.05, part="Bands")
    # open lid tilted back on its hinge
    box(m, P(p[0]), (0, YC + 0.95, 2.45), (2.2, 0.14, 1.1), r=0.06, rot=(-12, 0, 0), part="Bands")
    # spring piston + head
    helix(m, P(STEEL, "ME"), (0, YC, 2.0), 0.36, 0.07, 1.1, 5, seg=6, part="Spring", n=60)
    cyl(m, P(STEEL, "ME"), (0, YC, 2.0), r=0.12, h=1.25, seg=8, part="Spring")
    disc(m, P(p[2]), (0, YC, 3.15), 0.55, 0.2, axis=(0, 0, 1), seg=16, bev=0.06, part="Cap")
    sphere(m, P(p[0]), (0, YC, 3.65), 0.42, seg=14, rings=9, part="Ball")
    flat(m, P(p[2], "NE"), star_poly(5, 0.42, 0.18), 0.1, (0, YC, 4.1), axis=(0, 1, 0), part="Glow")
    torus(m, P(p[3]), (0, YC, 3.38), R=0.38, r=0.07, seg=14, rseg=5, part="Cap")
    box(m, P(GOLD, "ME"), (1.0, YC + 0.3, 2.0), (0.18, 0.5, 0.12), r=0.03, part="Cap")


def EnginePocketwatch(m, c):
    p = c["palette"]
    base(m, P(p[3]), 2.8, 1.6)
    box(m, P(p[3]), (0, YC, 0.45), (1.4, 0.7, 0.4), r=0.08, part="Stand")
    cz = 1.45; cy = YC - 0.05
    disc(m, P(p[0], "ME"), (0, cy - 0.32, cz), 1.2, 0.7, axis=(0, 1, 0), seg=24, bev=0.12, part="Case")
    disc(m, P("FFF4E6"), (0, cy + 0.36, cz), 1.0, 0.04, axis=(0, 1, 0), seg=24, part="Face")
    for k in range(12):
        a = 2 * math.pi * k / 12
        box(m, P(p[3]), (0.86 * math.cos(a), cy + 0.42, cz + 0.86 * math.sin(a)), (0.08, 0.04, 0.18 if k % 3 == 0 else 0.1), r=0.0, rot=(0, -math.degrees(a) + 90, 0), part="Marks")
    # visible gears (skeleton) on the lower half of the face
    for (x, z, r, n, col) in ((-0.42, -0.38, 0.42, 10, p[2]), (0.38, -0.45, 0.34, 9, p[1]), (0.0, 0.1, 0.25, 8, p[0])):
        flat(m, P(col, "ME" if col == p[0] else "SP"), gear_poly(n, r, r - 0.12, 0.45), 0.05, (x, cy + 0.42, cz + z), axis=(0, 1, 0), part="Gears" + col[:2])
    box(m, P(p[3]), (0.0, cy + 0.5, cz + 0.32), (0.07, 0.03, 0.65), r=0.0, part="Hands")
    box(m, P(p[3]), (0.2, cy + 0.5, cz + 0.08), (0.45, 0.03, 0.06), r=0.0, rot=(0, -20, 0), part="Hands")
    disc(m, P(p[1], "ME"), (0, cy + 0.42, cz), 0.08, 0.1, axis=(0, 1, 0), seg=8, part="Hands")
    # crown + bow
    cyl(m, P(p[0], "ME"), (0, cy, cz + 1.15), r=0.17, h=0.28, seg=10, part="Case")
    cyl(m, P(p[1], "ME"), (0, cy, cz + 1.4), r=0.24, h=0.13, seg=12, part="Crown")
    torus(m, P(p[0], "ME"), (0, cy, cz + 1.7), R=0.22, r=0.06, seg=14, rseg=5, rot=(90, 0, 0), part="Case")
    for sx in (-1, 1): box(m, P(p[1], "ME"), (sx * 0.95, YC, 0.5), (0.35, 0.6, 0.35), r=0.06, part="Crown")


def EngineGrandClock(m, c):
    p = c["palette"]
    base(m, P(p[3]), 3.1, 1.75)
    rbox(m, P(p[3]), (0, YC + 0.05, 0.27), (2.2, 1.5, 0.9), r=0.1, part="Plinth", base=True)
    rbox(m, P(p[1], "ME"), (0, YC + 0.1, 1.15), (1.55, 1.3, 2.05), r=0.08, part="Tower", base=True)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(m, P(p[0], "ME"), (sx * 0.78, YC + 0.1 + sy * 0.64, 2.17), (0.18, 0.18, 2.1), r=0.04, part="Brass")
    box(m, P(p[0], "ME"), (0, YC + 0.1, 3.27), (1.8, 1.5, 0.18), r=0.05, part="Brass")
    cyl(m, P(p[2]), (0, YC + 0.1, 3.35), r=1.12, r2=0.02, h=1.0, seg=4, rot=(0, 0, 45), part="Roof")
    m.flat("Roof", P(p[2]), 1)
    rod(m, P(p[0], "ME"), (0, YC + 0.1, 4.2), (0, YC + 0.1, 4.6), r=0.05, seg=6, part="Brass")
    # clock face (rear)
    cy = YC + 0.78; cz = 2.45
    disc(m, P(p[0], "ME"), (0, cy - 0.04, cz), 0.62, 0.08, axis=(0, 1, 0), seg=18, part="Brass")
    disc(m, P("FFF4E6"), (0, cy + 0.02, cz), 0.5, 0.04, axis=(0, 1, 0), seg=18, part="Face")
    box(m, P(p[3]), (0, cy + 0.08, cz + 0.17), (0.06, 0.03, 0.36), r=0.0, part="Hands")
    box(m, P(p[3]), (0.12, cy + 0.08, cz + 0.05), (0.26, 0.03, 0.05), r=0.0, rot=(0, -25, 0), part="Hands")
    disc(m, P(p[2], "NE"), (0, cy + 0.06, cz), 0.07, 0.06, axis=(0, 1, 0), seg=8, part="Glow")
    # layered gears on both sides
    for sx in (-1, 1):
        for (y, z, r, n, col, d) in ((YC + 0.25, 1.75, 0.62, 12, p[2], 0.0), (YC - 0.3, 2.4, 0.42, 9, p[0], 0.1), (YC + 0.55, 2.75, 0.32, 8, p[2], 0.16)):
            flat(m, P(col, "ME" if col == p[0] else "SP"), gear_poly(n, r, r - 0.14, 0.45, a0=0.2 * sx), 0.1, (sx * (0.78 + d), y, z), axis=(sx, 0, 0), part="Gears" + ("B" if col == p[0] else "T"))
            disc(m, P(p[3]), (sx * (0.86 + d), y, z), r * 0.3, 0.06, axis=(sx, 0, 0), seg=8, part="Hands")
    box(m, P(p[2]), (0, YC + 0.82, 0.7), (1.3, 0.05, 0.3), r=0.02, part="Roof")


def EngineBreeze(m, c):
    p = c["palette"]
    base(m, P(p[1]), 3.0, 1.7)
    cz = 1.75; cy = YC + 0.25
    ring_band(m, P(p[0]), (0, cy - 0.5, cz), 0.98, 1.15, 0.9, axis=(0, 1, 0), seg=20, part="Shroud")
    puffs = []
    for k in range(9):
        a = 2 * math.pi * k / 9 + 0.2
        r = 0.42 + 0.12 * math.sin(k * 2.1)
        puffs.append((1.18 * math.cos(a), cy - 0.05, cz + 1.18 * math.sin(a), r))
    puffs += [(-0.95, cy - 0.1, 0.55, 0.5), (0.95, cy - 0.1, 0.55, 0.5), (0, cy - 0.15, 0.48, 0.45)]
    puff(m, P(p[0]), [(x, y, max(z, r * 0.85 + 0.25), r) for x, y, z, r in puffs], part="Puffs", seg=10)
    fan(m, P(p[1]), (0, cy + 0.1, cz), 0.95, n=6, axis=(0, 1, 0), part="SpinFan", width=0.4)
    sphere(m, P(p[3], "NE"), (0, cy + 0.15, cz), 0.25, seg=10, rings=6, part="Hub")
    torus(m, P(p[2], "ME"), (0, cy + 0.42, cz), R=1.0, r=0.06, seg=20, rseg=5, rot=(90, 0, 0), part="Gold")


def EngineStorm(m, c):
    p = c["palette"]
    DK = "5D6A86"; DK2 = "47526B"
    base(m, P("3E4760"), 3.1, 1.75)
    cl = [(0, YC, 1.6, 0.85), (-0.85, YC + 0.1, 1.35, 0.68), (0.85, YC + 0.05, 1.4, 0.7), (-0.4, YC - 0.1, 2.25, 0.62), (0.45, YC + 0.0, 2.3, 0.66),
          (0.0, YC + 0.2, 2.75, 0.55), (-1.15, YC + 0.0, 0.85, 0.5), (1.15, YC + 0.1, 0.85, 0.5), (0, YC + 0.1, 0.8, 0.6)]
    puff(m, P(DK), cl, part="Cloud", seg=12)
    puff(m, P(DK2), [(-0.6, YC + 0.55, 1.0, 0.42), (0.6, YC + 0.6, 1.05, 0.4)], part="Shade", seg=10)
    # glowing lightning core bursting out the rear
    flat(m, P(p[3], "NE"), bolt_poly(0.85, 1.6), 0.16, (0.0, YC + 0.78, 1.75), axis=(0, 1, 0), part="Bolt")
    flat(m, P(p[3], "NE"), bolt_poly(0.5, 0.9), 0.12, (0.9, YC - 0.1, 3.05), axis=(0, 1, 0), part="Bolt", spin=-25)
    for sx in (-1, 1):
        rod(m, P(p[2], "ME"), (sx * 0.9, YC + 0.3, 0.25), (sx * 1.15, YC + 0.4, 3.05), r=0.07, seg=6, part="Rods")
        sphere(m, P(p[2], "ME"), (sx * 1.15, YC + 0.4, 3.1), 0.12, seg=8, rings=5, part="Rods")


def EngineStarDrive(m, c):
    p = c["palette"]
    base(m, P(p[0]), 3.0, 1.7)
    box(m, P(p[1]), (0, YC, 0.6), (0.8, 0.8, 0.7), r=0.1, part="Pylon")
    cz = 1.86; cy = YC - 0.15
    flat(m, P(p[0]), star_poly(5, 1.55, 0.7), 0.6, (0, cy - 0.3, cz), axis=(0, 1, 0), part="Star", bev=0.1)
    flat(m, P(p[1]), star_poly(5, 1.15, 0.52), 0.1, (0, cy + 0.32, cz), axis=(0, 1, 0), part="Inlay")
    # nozzle pointing back
    lathe(m, P(p[2], "ME"), [(0.45, 0), (0.5, 0.2), (0.4, 0.55), (0.48, 0.85)], loc=(0, cy + 0.3, cz), rot=(-90, 0, 0), seg=14, part="Nozzle")
    disc(m, P(p[3], "NE"), (0, cy + 1.05, cz), 0.38, 0.04, axis=(0, 1, 0), seg=14, part="Glow")
    for k in range(5):
        a = math.pi / 2 + 2 * math.pi * k / 5
        sphere(m, P(p[2]), (1.4 * math.cos(a), cy + 0.05, cz + 1.4 * math.sin(a)), 0.13, seg=8, rings=5, part="Tips")


def EngineNebula(m, c):
    p = c["palette"]
    lathe(m, P(p[0]), [(1.35, 0.05), (1.35, 0.25), (1.05, 0.38), (0.6, 0.55), (0.5, 0.95), (0.7, 1.15), (0, 1.17)], loc=(0, YC + 0.05, 0), seg=18, sy=0.68, part="Base")
    cz = 2.15
    sphere(m, P(p[1]), (0, YC, cz), 0.95, seg=18, rings=11, part="Sphere")
    # swirl bands on the sphere
    for k in range(2):
        pts = []
        for i in range(19):
            a = 2 * math.pi * i / 18; tilt = 0.35 if k == 0 else -0.5
            v = Vector((0.97 * math.cos(a), 0.97 * math.sin(a) * math.cos(tilt), 0.97 * math.sin(a) * math.sin(tilt) + (0.3 if k else -0.25)))
            v = v.normalized() * 0.98
            pts.append((v.x, YC + v.y, cz + v.z))
        tube(m, P(p[0]), pts, r=0.07, seg=5, part="Swirl", smooth=1, closed=True)
    torus(m, P(p[2]), (0, YC, cz), R=1.42, r=0.08, seg=28, rseg=6, rot=(68, 18, 0), part="Rings")
    torus(m, P(p[3]), (0, YC, cz), R=1.25, r=0.06, seg=26, rseg=5, rot=(-60, -25, 0), part="Rings2")
    sphere(m, P(p[2]), Vector((0, YC, cz)) + (Matrix.Rotation(math.radians(68), 3, 'X') @ Vector((1.42, 0, 0))), 0.16, seg=8, rings=5, part="Rings")
    flat(m, P(p[2], "NE"), star_poly(4, 0.5, 0.16), 0.08, (0, YC + 0.95, cz), axis=(0, 1, 0), part="Star")
    sphere(m, P(p[3], "NE"), (0, YC + 0.9, cz), 0.16, seg=8, rings=5, part="Core")
