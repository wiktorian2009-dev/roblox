# deltoid.py - "Deltoid" supercar (Claude, 2026-11-11). Standalone Blender model in the w2lib conventions:
#   1 unit = 1 stud, up = +Z, front = Blender -Y (Roblox -Z), origin = floor centre; Blender (x, y, z) -> Roblox local (-x, z, y).
#   Object names <Model>__<Part>__<RRGGBB><MAT>[Tnn] -> the Studio post-process applies colour/material and groups by model.
# Top view is a deltoid (kite): long pointed nose, widest just ahead of the rear wheels, short tapered tail.
# Small front wheels on a narrow front track, big rear wheels under raised hips, bubble canopy, kite wing, neon trim.
# Every wheel is its own Tire/Rim/Hub set (TireFL ... HubRR) so Studio can spin it; calipers are one static part.
# usage (bpy module):  python deltoid.py [--export] [--save] [--render]
#        (Blender):    blender -b --factory-startup -P deltoid.py -- [--export] [--save] [--render]
import bpy, bmesh, sys, os, math, json
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "World2Blender"))
import w2lib as L
from w2lib import P, Mx, sphere, rbox, cyl, tube

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
NAME = "Deltoid"
OBJ_TRIS = 9000

# ------------------------------------------------------------------ palette
PAINT = "6A2BFF"      # electric violet body
STRIPE = "F4F8FF"     # racing stripes
CARBON = "23262E"     # floor, liners, trim
GLASS = "7FD0FF"      # canopy
NEON = "38F2FF"       # cyan LEDs / skirt glow
HEAD = "EAFBFF"       # headlights
TAIL = "FF2D55"       # tail lights
CHROME = "D9DEE6"
ACCENT = "FFC81E"     # calipers, hub caps, seat trim
TIRE = "2A2D34"
FIRE = "FF8A1E"       # exhaust glow

# ------------------------------------------------------------------ dimensions (studs)
Y_NOSE, Y_WIDE, Y_TAIL = -9.0, 2.6, 8.6          # kite: nose tip, widest point, tail face
HW_NOSE, HW_WIDE, HW_TAIL = 0.4, 4.1, 3.1        # half widths at those points
RN, RT = 1.2, 0.4                                 # nose / tail rounding lengths
FRONT = dict(y=-5.0, x=1.6, r=1.05, w=1.0)        # small front wheels, narrow track
REAR = dict(y=5.0, x=3.2, r=1.55, w=1.7)          # big rear wheels
ARCH = 0.25                                       # arch clearance around each tyre
ZT = [(-9.0, 1.45), (-6.0, 2.05), (-2.6, 2.75), (1.0, 3.0), (5.5, 3.0), (8.6, 2.8)]   # body top (side wedge)
ZB = [(-9.0, 1.05), (-7.0, 0.88), (-5.0, 0.85), (6.4, 0.85), (8.6, 1.2)]              # body bottom (tail diffuser ramp)
EXP = 3.5                                         # body section superellipse exponent
NSEC = 48                                         # points per body section
CANOPY = dict(y=0.8, front=3.5, rear=4.1, w=1.75, h=2.2)
COCKPIT = [(0.0, -2.5), (1.3, 0.3), (1.15, 2.5), (-1.15, 2.5), (-1.3, 0.3)]           # cockpit cut-out (x, y)
COCKPIT_Z = 1.2


def gauss(v, c, s): return math.exp(-((v - c) / s) ** 2)


def hermite(pts, y):
    ys = [p[0] for p in pts]; vs = [p[1] for p in pts]; n = len(pts)
    if y <= ys[0]: return vs[0]
    if y >= ys[-1]: return vs[-1]

    def slope(i):
        if i == 0: return (vs[1] - vs[0]) / (ys[1] - ys[0])
        if i == n - 1: return (vs[-1] - vs[-2]) / (ys[-1] - ys[-2])
        return (vs[i + 1] - vs[i - 1]) / (ys[i + 1] - ys[i - 1])
    for i in range(n - 1):
        if ys[i] <= y <= ys[i + 1]:
            h = ys[i + 1] - ys[i]; t = (y - ys[i]) / h
            return ((2 * t ** 3 - 3 * t ** 2 + 1) * vs[i] + (t ** 3 - 2 * t ** 2 + t) * h * slope(i)
                    + (-2 * t ** 3 + 3 * t ** 2) * vs[i + 1] + (t ** 3 - t ** 2) * h * slope(i + 1))


def kite(y):
    if y <= Y_WIDE: return HW_NOSE + (HW_WIDE - HW_NOSE) * (y - Y_NOSE) / (Y_WIDE - Y_NOSE)
    return HW_WIDE + (HW_TAIL - HW_WIDE) * (y - Y_WIDE) / (Y_TAIL - Y_WIDE)


def dims(y):
    """Body section at y: half width, centre z, half height (kite planform + fender flares + rounded nose/tail)."""
    w = kite(y) + 0.40 * gauss(y, FRONT["y"], 1.3) + 0.35 * gauss(y, REAR["y"], 1.7)
    b, t = hermite(ZB, y), hermite(ZT, y)
    zc, hh = (b + t) / 2, (t - b) / 2
    if y < Y_NOSE + RN:                       # ellipsoidal nose that closes to a point
        s = math.sqrt(max(0.0, 1 - ((Y_NOSE + RN - y) / RN) ** 2))
        w *= s; hh *= s
    if y > Y_TAIL - RT:                       # rounded tail edge, flat tail face
        k = 1 - math.sqrt(max(0.0, 1 - ((y - (Y_TAIL - RT)) / RT) ** 2))
        w -= 0.35 * k; hh -= 0.25 * k
    return w, zc, hh


def hips(ax, y):
    """Raised fenders over the wheels (added to the upper half of each section)."""
    return (0.6 * gauss(y, FRONT["y"], 1.25) * gauss(ax, FRONT["x"], 0.7)
            + 0.85 * gauss(y, REAR["y"], 1.75) * gauss(ax, REAR["x"], 0.95))


def se(a, n):
    c, s = math.cos(a), math.sin(a)
    return math.copysign(abs(c) ** (2 / n), c), math.copysign(abs(s) ** (2 / n), s)


def body_section(y):
    w, zc, hh = dims(y)
    pts = []
    for i in range(NSEC):
        cx, u = se(-math.pi / 2 + 2 * math.pi * i / NSEC, EXP)
        x = w * cx * ((1 - 0.10 * u) if u > 0 else (1 - 0.06 * -u))     # tumblehome / tuck-under
        z = zc + hh * u
        if u > 0: z += hips(abs(x), y) * u ** 0.7
        pts.append(Vector((x, y, z)))
    return pts


def floor_section(y):
    w, zc, hh = dims(y)
    b = hermite(ZB, y)
    zc2, hh2 = b + 0.09, 0.21 * min(1.0, w / 0.6)
    pts = []
    for i in range(NSEC):
        cx, u = se(-math.pi / 2 + 2 * math.pi * i / NSEC, 6)
        pts.append(Vector(((w + 0.02) * cx, y, zc2 + hh2 * u)))
    return pts


def body_ys(step=0.2):
    ys = [Y_NOSE + RN * (1 - math.cos(math.radians(a))) for a in range(0, 90, 10)]
    y = Y_NOSE + RN
    while y < Y_TAIL - RT - 1e-6:
        ys.append(y); y += step
    ys += [Y_TAIL - RT + RT * math.sin(math.radians(a)) for a in range(0, 91, 15)]
    out = []
    for v in ys:
        if not out or v - out[-1] > 1e-4: out.append(v)
    return out


# ------------------------------------------------------------------ mesh helpers
def loft(sections):
    """sections: list of rings (lists of Vector, same length) or single Vectors (poles). End rings are capped."""
    tb = bmesh.new(); rings = []
    for s in sections:
        rings.append([tb.verts.new(s)] if isinstance(s, Vector) else [tb.verts.new(p) for p in s])
    for a, b in zip(rings, rings[1:]):
        n = max(len(a), len(b))
        for i in range(n):
            j = (i + 1) % n
            if len(a) == 1: tb.faces.new((a[0], b[j], b[i]))
            elif len(b) == 1: tb.faces.new((a[i], a[j], b[0]))
            else: tb.faces.new((a[i], a[j], b[j], b[i]))
    if len(rings[0]) > 1: tb.faces.new(list(reversed(rings[0])))
    if len(rings[-1]) > 1: tb.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    return tb


def add(m, part, pc, tb, M=None):
    if M is not None: bmesh.ops.transform(tb, matrix=M, verts=tb.verts)
    L._merge(m.bm(part, pc), tb)


def revolve(prof, seg=28):
    """Closed (r, z) profile revolved around local Z (no caps) - a donut."""
    tb = bmesh.new(); rings = []
    for r, z in prof:
        rings.append([tb.verts.new((r * math.cos(2 * math.pi * k / seg), r * math.sin(2 * math.pi * k / seg), z)) for k in range(seg)])
    for a, b in zip(rings, rings[1:] + rings[:1]):
        for k in range(seg):
            j = (k + 1) % seg
            tb.faces.new((a[k], a[j], b[j], b[k]))
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    return tb


def ccyl(r, z0, z1, seg=24, r2=None):
    tb = bmesh.new()
    bmesh.ops.create_cone(tb, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=z1 - z0)
    bmesh.ops.translate(tb, vec=(0, 0, (z0 + z1) / 2), verts=tb.verts)
    return tb


def slab(poly, z0, z1, bev=0.0):
    """2-D polygon (x, y) extruded from z0 to z1."""
    tb = bmesh.new(); vs = [tb.verts.new((x, y, z0)) for x, y in poly]; f = tb.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(tb, geom=[f])
    bmesh.ops.translate(tb, vec=(0, 0, z1 - z0), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    if bev > 0:
        es = [e for e in tb.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(40)]
        bmesh.ops.bevel(tb, geom=es, offset=bev, segments=2, affect="EDGES", profile=0.5, clamp_overlap=True)
    bmesh.ops.triangulate(tb, faces=tb.faces[:])
    return tb


def plane_slab(pts3, ext):
    """Planar 3-D polygon pts3 extruded by vector ext."""
    tb = bmesh.new(); a = [tb.verts.new(p) for p in pts3]; b = [tb.verts.new(Vector(p) + Vector(ext)) for p in pts3]
    tb.faces.new(a); tb.faces.new(list(reversed(b)))
    n = len(a)
    for i in range(n):
        j = (i + 1) % n; tb.faces.new((a[i], b[i], b[j], a[j]))
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    return tb


AXIS = {"z": (Vector((0, 0, -1)), lambda u, v, s: Vector((u, v, 30))),
        "x": (None, lambda u, v, s: Vector((s * 30, u, v)))}


def skin(bvh, poly, axis="z", side=1, off=0.025, depth=0.09, lmax=0.3):
    """Decal that hugs the body: 2-D outline projected onto the surface along an axis, given a small thickness.
    axis 'z': outline in (x, y), projected from above. axis 'x': outline in (y, z), projected from the side (side = +1 / -1)."""
    tb = bmesh.new(); f = tb.faces.new([tb.verts.new((u, v, 0)) for u, v in poly])
    bmesh.ops.triangulate(tb, faces=[f])
    for _ in range(10):
        long_ = [e for e in tb.edges if e.calc_length() > lmax]
        if not long_: break
        bmesh.ops.subdivide_edges(tb, edges=long_, cuts=1)
        bmesh.ops.triangulate(tb, faces=tb.faces[:])
    d = Vector((0, 0, -1)) if axis == "z" else Vector((-side, 0, 0))
    for v in tb.verts:
        o = Vector((v.co.x, v.co.y, 30)) if axis == "z" else Vector((side * 30, v.co.x, v.co.y))
        hit, _n, _i, _d = bvh.ray_cast(o, d)
        k = 0
        while hit is None and k < 40:          # outline poked past the silhouette: slide the vertex inward until it lands
            k += 1
            if axis == "z": o = Vector((o.x * 0.97, o.y, o.z))
            else: o = Vector((o.x, o.y, o.z + (2.0 - o.z) * 0.05))
            hit, _n, _i, _d = bvh.ray_cast(o, d)
        v.co = (hit if hit is not None else o + d * 30) - d * off
    ext = bmesh.ops.extrude_face_region(tb, geom=tb.faces[:])
    for e in ext["geom"]:
        if isinstance(e, bmesh.types.BMVert): e.co += d * depth
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    return tb


def side_x(bvh, y, z, side):
    hit, _n, _i, _d = bvh.ray_cast(Vector((side * 30, y, z)), Vector((-side, 0, 0)))
    return hit.x if hit is not None else side * dims(y)[0]


def top_z(bvh, x, y):
    hit, _n, _i, _d = bvh.ray_cast(Vector((x, y, 30)), Vector((0, 0, -1)))
    return hit.z if hit is not None else hermite(ZT, y)


def mirror_poly(poly): return [(-x, y) for x, y in reversed(poly)]


# ------------------------------------------------------------------ model
def canopy_dims(y):
    c = CANOPY; t = (y - c["y"]) / (c["front"] if y < c["y"] else c["rear"])
    t = max(-1.0, min(1.0, t))
    w = c["w"] * max(0.0, 1 - abs(t) ** 1.6) ** (1 / 1.6)
    h = c["h"] * max(0.0, 1 - t * t) ** 0.5
    return w, hermite(ZT, y) - 0.08, h


def build_body(m):
    ys = body_ys()
    bt = loft([Vector((0, ys[0], dims(ys[0])[1]))] + [body_section(y) for y in ys[1:]])     # nose = pole
    bvh = BVHTree.FromBMesh(bt)
    add(m, "Body", P(PAINT), bt)
    ys = body_ys(0.25)
    add(m, "Floor", P(CARBON), loft([Vector((0, ys[0], hermite(ZB, ys[0]) + 0.09))] + [floor_section(y) for y in ys[1:]]))
    return bvh


def build_canopy(m):
    c = CANOPY; y0, y1 = c["y"] - c["front"], c["y"] + c["rear"]
    ys = [y0 + (y1 - y0) * (1 - math.cos(math.pi * k / 36)) / 2 for k in range(37)]
    secs = []
    for k, y in enumerate(ys):
        w, zc, h = canopy_dims(y)
        if k in (0, len(ys) - 1):
            secs.append(Vector((0, y, zc))); continue
        ring = []
        for i in range(32):
            cx, u = se(-math.pi / 2 + 2 * math.pi * i / 32, 2.3)
            ring.append(Vector((w * cx, y, zc + (h * u if u > 0 else 0.35 * u))))
        secs.append(ring)
    add(m, "Canopy", P(GLASS, "GL", t=0.35), loft(secs))
    rail = [Vector((canopy_dims(y)[0], y, canopy_dims(y)[1] + 0.02)) for y in ys[1:-1]]
    loop = rail + [Vector((-p.x, p.y, p.z)) for p in reversed(rail)]
    tube(m, P(CARBON), loop, r=0.07, seg=8, part="Frame", closed=True, smooth=1)


def build_aero(m, bvh):
    pa = P(PAINT)
    # kite wing on swan-neck struts, with a brake-light edge
    wing = [(0.0, 6.85), (4.3, 7.85), (0.0, 8.6), (-4.3, 7.85)]
    add(m, "Aero", pa, slab(wing, 4.45, 4.75, bev=0.08))
    tube(m, P(TAIL, "NE"), [(4.05, 7.92, 4.6), (0.0, 8.66, 4.6), (-4.05, 7.92, 4.6)], r=0.06, seg=6, part="Tail", smooth=1)
    for sx in (-1.5, 1.5):
        z0 = top_z(bvh, sx, 6.7) - 0.25
        tube(m, P(CARBON), [(sx, 6.7, z0), (sx, 6.95, 3.6), (sx, 7.4, 4.3), (sx, 7.6, 4.55)], r=0.13, seg=8, part="Frame", smooth=4)
    # dorsal fin from the canopy to the wing
    fin = [Vector((-0.11, 3.9, 2.75)), Vector((-0.11, 7.7, 2.7)), Vector((-0.11, 8.0, 4.55)), Vector((-0.11, 7.05, 4.55))]
    add(m, "Aero", pa, plane_slab(fin, (0.22, 0, 0)))
    # front splitter (chevron) and rear diffuser fins
    split = [(0.0, -9.3), (1.4, -6.55), (1.4, -6.15), (0.0, -7.05), (-1.4, -6.15), (-1.4, -6.55)]
    add(m, "Trim", P(CARBON), slab(split, 0.7, 0.9, bev=0.05))
    tube(m, P(NEON, "NE"), [(1.42, -6.45, 0.8), (0.0, -9.33, 0.8), (-1.42, -6.45, 0.8)], r=0.05, seg=6, part="Neon", smooth=1)
    for x in (-2.0, -1.0, 1.0, 2.0):
        add(m, "Trim", P(CARBON), plane_slab([Vector((x - 0.06, 6.6, 0.95)), Vector((x - 0.06, 8.75, 0.72)),
                                               Vector((x - 0.06, 8.75, 1.35)), Vector((x - 0.06, 6.6, 1.05))], (0.12, 0, 0)))
    # mirrors: kite pods on stalks
    for s in (-1, 1):
        x0 = side_x(bvh, -1.5, 2.55, s) - s * 0.15
        tube(m, P(CARBON), [(x0, -1.45, 2.55), (s * 2.3, -1.55, 2.95)], r=0.08, seg=6, part="Frame", smooth=1)
        add(m, "Aero", pa, plane_slab([Vector((s * 2.0, -1.75, 3.0)), Vector((s * 2.55, -1.75, 3.22)),
                                       Vector((s * 2.95, -1.75, 2.98)), Vector((s * 2.45, -1.75, 2.8))], (0, 0.32, 0)))
        add(m, "Chrome", P(CHROME), plane_slab([Vector((s * 2.12, -1.42, 2.99)), Vector((s * 2.55, -1.42, 3.16)),
                                                 Vector((s * 2.85, -1.42, 2.98)), Vector((s * 2.45, -1.42, 2.85))], (0, 0.03, 0)))


def build_trim(m, bvh):
    st = P(STRIPE)
    # twin racing stripes: nose -> canopy, canopy -> tail (either side of the fin)
    for s in (-1, 1):
        a, b = sorted((s * 0.1, s * 0.3))
        add(m, "Stripe", st, skin(bvh, [(a, -8.55), (b, -8.4), (b, -3.2), (a, -3.2)]))
        add(m, "Stripe", st, skin(bvh, [(a, 4.4), (b, 4.4), (b, 8.45), (a, 8.45)]))
    # kite headlights on the nose + LED eyebrows along the kite edges
    hl = [(0.5, -8.0), (0.98, -7.05), (0.9, -6.45), (0.52, -7.0)]
    rim = [(0.4, -8.25), (1.0, -7.05), (0.94, -6.3), (0.42, -6.9)]
    for poly in (hl, mirror_poly(hl)):
        add(m, "Lights", P(HEAD, "NE"), skin(bvh, poly, off=0.045))
    for poly in (rim, mirror_poly(rim)):
        add(m, "Trim", P(CARBON), skin(bvh, poly, off=0.025))
    for s in (-1, 1):
        pts = []
        for k in range(12):
            y = -8.45 + 2.0 * k / 11
            w, zc, hh = dims(y); z = zc + 0.35 * hh
            pts.append(Vector((side_x(bvh, y, z, s) + s * 0.03, y, z)))
        tube(m, P(NEON, "NE"), pts, r=0.065, seg=6, part="Neon", smooth=2)
    # dark kite air intakes on the hips + engine louvres
    intake = [(0.75, 2.0), (2.55, 2.5), (2.95, 1.85), (2.35, 1.38)]
    for s in (-1, 1):
        add(m, "Trim", P(CARBON), skin(bvh, intake, axis="x", side=s, off=0.03, depth=0.12))
        for y in (5.55, 6.05, 6.55):
            xs = sorted((s * 0.75, s * 1.95))
            add(m, "Trim", P(CARBON), skin(bvh, [(xs[0], y), (xs[1], y + 0.15), (xs[1], y + 0.38), (xs[0], y + 0.23)], off=0.03))
    # neon side skirts between the wheels
    for s in (-1, 1):
        pts = []
        for k in range(10):
            y = -3.55 + 6.55 * k / 9
            w, zc, hh = dims(y); b = hermite(ZB, y)
            pts.append(Vector((s * (w + 0.06), y, b + 0.09)))
        tube(m, P(NEON, "NE"), pts, r=0.07, seg=6, part="Neon", smooth=2)
    # tail: light bar, kite lamps, quad exhausts
    w, zc, hh = dims(Y_TAIL)
    rbox(m, P(TAIL, "NE"), (0, Y_TAIL + 0.02, zc + 0.12), (3.2, 0.08, 0.22), r=0.03, part="Tail")
    for s in (-1, 1):
        kx = s * 2.0
        add(m, "Tail", P(TAIL, "NE"), plane_slab([Vector((kx - 0.28, Y_TAIL - 0.02, zc + 0.08)), Vector((kx, Y_TAIL - 0.02, zc + 0.36)),
                                                  Vector((kx + 0.28, Y_TAIL - 0.02, zc + 0.08)), Vector((kx, Y_TAIL - 0.02, zc - 0.2))], (0, 0.08, 0)))
        for ex in (0.42, 1.05):
            cyl(m, P(CHROME), (s * ex, Y_TAIL - 0.3, zc - 0.32), r=0.22, h=0.62, seg=14, rot=(-90, 0, 0), part="Chrome")
            cyl(m, P(FIRE, "NE"), (s * ex, Y_TAIL + 0.29, zc - 0.32), r=0.15, h=0.05, seg=12, rot=(-90, 0, 0), part="Exhaust")


def build_interior(m):
    c, a = P(CARBON), P(ACCENT)
    rbox(m, c, (0, 1.15, COCKPIT_Z + 0.22), (1.5, 1.45, 0.45), r=0.15, part="Interior")              # seat cushion
    rbox(m, c, (0, 1.95, COCKPIT_Z + 1.25), (1.5, 0.35, 1.9), r=0.15, rot=(-14, 0, 0), part="Interior")   # seat back
    for sx in (-0.62, 0.62):
        rbox(m, a, (sx, 1.97, COCKPIT_Z + 1.3), (0.2, 0.38, 1.7), r=0.07, rot=(-14, 0, 0), part="SeatTrim")
    rbox(m, c, (0, -1.15, 2.45), (0.9, 0.6, 0.5), r=0.12, part="Interior")                           # dash pod
    rbox(m, P(NEON, "NE"), (0, -0.84, 2.55), (0.6, 0.03, 0.22), r=0.02, part="Neon")                 # screen
    tube(m, c, [(0, -1.0, 2.35), (0, -0.4, 2.62)], r=0.07, seg=6, part="Interior", smooth=1)          # column
    L.torus(m, c, (0, -0.35, 2.68), R=0.42, r=0.07, seg=20, rseg=6, rot=(68, 0, 0), part="Interior")  # wheel
    tube(m, c, [(-0.4, -0.37, 2.66), (0.4, -0.37, 2.66)], r=0.05, seg=6, part="Interior", smooth=1)


def build_wheel(m, tag, wd, side):
    r, w = wd["r"], wd["w"]; c = Vector((side * wd["x"], wd["y"], r))
    M = Matrix.Translation(c) @ Matrix.Rotation(math.radians(90 * side), 4, "Y")    # local +Z = outward
    ri, h = r * 0.64, w / 2
    prof = [(ri - 0.02, h - 0.12), (ri - 0.02, -h + 0.12), (r - 0.28, -h), (r - 0.07, -h + 0.08), (r, -h + 0.3),
            (r, h - 0.3), (r - 0.07, h - 0.08), (r - 0.28, h)]
    add(m, "Tire" + tag, P(TIRE), revolve(prof, 30), M)
    add(m, "Tire" + tag, P(TIRE), ccyl(ri, -h + 0.18, h - 0.62, 20), M)                  # rim barrel (dark)
    z0, z1 = h - 0.38, h - 0.14                                                         # spoke depth
    for k in range(5):
        f = 2 * math.pi * k / 5 + math.pi / 2; e = Vector((math.cos(f), math.sin(f))); p = Vector((-e.y, e.x))
        r0, r1 = 0.2, ri - 0.04; rk = r0 + 0.32 * (r1 - r0); wk = 0.2 * r
        kite_ = [e * r0, e * rk + p * wk, e * r1, e * rk - p * wk]
        add(m, "Rim" + tag, P(CHROME), slab([(q.x, q.y) for q in kite_], z0, z1), M)
    lip = [M @ Vector(((ri - 0.05) * math.cos(2 * math.pi * k / 26), (ri - 0.05) * math.sin(2 * math.pi * k / 26), h - 0.15)) for k in range(26)]
    tube(m, P(CHROME), lip, r=0.07, seg=6, part="Rim" + tag, closed=True, smooth=1)
    add(m, "Hub" + tag, P(ACCENT), ccyl(0.26, h - 0.4, h - 0.07, 12, r2=0.2), M)
    th = math.radians(50)                                                               # caliper: upper rear, static
    cc = c + Vector((side * (h - 0.5), math.sin(th) * ri * 0.66, math.cos(th) * ri * 0.66))
    rbox(m, P(ACCENT), tuple(cc), (0.22, 0.62 * r, 0.3 * r), r=0.06, rot=(-50, 0, 0), part="Caliper")


WHEELS = [("FR", FRONT, -1), ("FL", FRONT, 1), ("RR", REAR, -1), ("RL", REAR, 1)]   # Blender -X = the car's right (Roblox +X)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m = L.Model(NAME, at=(0, 0, 0))
    bvh = build_body(m)
    build_canopy(m)
    build_aero(m, bvh)
    build_trim(m, bvh)
    build_interior(m)
    for tag, wd, side in WHEELS: build_wheel(m, tag, wd, side)
    objs = L.realize([m], NAME)
    cut_body(objs)
    return objs


# ------------------------------------------------------------------ booleans (wheel arches + cockpit, with dark liners)
def _cutter(bms):
    me = bpy.data.meshes.new("cutter"); tb = bmesh.new()
    for b in bms: L._merge(tb, b)
    tb.to_mesh(me); tb.free()
    ob = bpy.data.objects.new("cutter", me); bpy.context.scene.collection.objects.link(ob); ob.hide_render = True
    return ob


def _bool(ob, bms, op):
    cut = _cutter(bms)
    mod = ob.modifiers.new("b", "BOOLEAN"); mod.operation = op; mod.object = cut; mod.solver = "EXACT"
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    ob.modifiers.remove(mod)
    old = ob.data; ob.data = me
    if not me.materials: me.materials.append(old.materials[0])
    me.name = old.name; bpy.data.meshes.remove(old)
    cm = cut.data; bpy.data.objects.remove(cut); bpy.data.meshes.remove(cm)
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    try: me.set_sharp_from_angle(angle=math.radians(38))
    except Exception: pass


def _xcyl(r, xa, xb, y, z, seg=40):
    tb = ccyl(r, 0, abs(xb - xa), seg)
    bmesh.ops.transform(tb, matrix=Matrix.Translation((min(xa, xb), y, z)) @ Matrix.Rotation(math.radians(90), 4, "Y"), verts=tb.verts)
    return tb


def arches(grow=0.0, inset=0.0):
    out = []
    for tag, wd, side in WHEELS:
        ra = wd["r"] + ARCH - grow
        xin = wd["x"] - wd["w"] / 2 - 0.15 + inset
        a, b = (side * xin, side * 7.0)
        out.append(_xcyl(ra, a, b + side * inset * 10, wd["y"], wd["r"]))
    return out


def cockpit(shrink=0.0, z0=COCKPIT_Z, z1=7.0):
    poly = []
    cx = sum(p[0] for p in COCKPIT) / len(COCKPIT); cy = sum(p[1] for p in COCKPIT) / len(COCKPIT)
    for x, y in COCKPIT:
        d = Vector((x - cx, y - cy)); poly.append((x - d.normalized().x * shrink, y - d.normalized().y * shrink))
    return [slab(poly, z0, z1, bev=0.18)]


def _new_like(src, part, col):
    me = src.data.copy(); me.materials.clear(); me.materials.append(L.pmat(col))
    nm = NAME + "__" + part + "__" + col; me.name = nm
    ob = bpy.data.objects.new(nm, me); src.users_collection[0].objects.link(ob); ob.location = src.location; ob["w2model"] = NAME
    return ob


def cut_body(objs):
    body = next(o for o in objs if o.name.split("__")[1] == "Body")
    floor = next(o for o in objs if o.name.split("__")[1] == "Floor")
    well = _new_like(body, "WheelWell", P(CARBON))                       # dark liner inside each arch
    _bool(well, arches(), "INTERSECT")
    _bool(well, arches(grow=0.07, inset=0.07), "DIFFERENCE")
    tub = _new_like(body, "Cockpit", P(CARBON))                          # dark tub inside the cockpit
    _bool(tub, cockpit(), "INTERSECT")
    _bool(tub, cockpit(shrink=0.07, z0=COCKPIT_Z + 0.07, z1=8.0), "DIFFERENCE")
    _bool(body, arches() + cockpit(), "DIFFERENCE")
    _bool(floor, arches() + cockpit(), "DIFFERENCE")
    objs += [well, tub]


# ------------------------------------------------------------------ render
def render_setup(res=(1200, 760), samples=48):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = samples
    try: sc.cycles.use_denoising = True
    except Exception: pass
    sc.render.resolution_x, sc.render.resolution_y = res; sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "Standard"
    w = sc.world or bpy.data.worlds.new("W"); sc.world = w; w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (*[L.srgb2lin(c) for c in (0.74, 0.84, 0.96)], 1); bg.inputs[1].default_value = 0.8
    if not bpy.data.objects.get("RSun"):
        ld = bpy.data.lights.new("RSun", "SUN"); ld.energy = 3.4; ld.angle = math.radians(12)
        sun = bpy.data.objects.new("RSun", ld); sc.collection.objects.link(sun)
        sun.rotation_euler = (math.radians(46), math.radians(-12), math.radians(-35))
    if not bpy.data.objects.get("RGround"):
        me = bpy.data.meshes.new("RGround"); s = 300
        me.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
        g = bpy.data.objects.new("RGround", me); sc.collection.objects.link(g); me.materials.append(L.pmat("DCE6F0SP"))
    return sc


def shot(path, loc, target, lens=50, ortho=None, res=None, roll=None):
    sc = bpy.context.scene
    cam = bpy.data.objects.get("RCam") or bpy.data.objects.new("RCam", bpy.data.cameras.new("RCam"))
    if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
    cam.location = Vector(loc); cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    if roll: cam.rotation_euler = (0, 0, math.radians(roll))
    if ortho: cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    else: cam.data.type = "PERSP"; cam.data.lens = lens
    cam.data.clip_end = 1000; sc.camera = cam
    if res: sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = path; sc.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True); print("RENDERED", path)
    return path


def sheet(paths, cols, out):
    import numpy as np
    imgs = [bpy.data.images.load(p) for p in paths]
    w, h = imgs[0].size; rows = (len(imgs) + cols - 1) // cols
    big = np.ones((rows * h, cols * w, 4), dtype=np.float32)
    for i, im in enumerate(imgs):
        px = np.empty(w * h * 4, dtype=np.float32); im.pixels.foreach_get(px)
        r, c = i // cols, i % cols; y0 = (rows - 1 - r) * h
        big[y0:y0 + h, c * w:(c + 1) * w] = px.reshape(h, w, 4)
    o = bpy.data.images.new("sheet", cols * w, rows * h, alpha=True)
    o.pixels.foreach_set(big.ravel()); o.filepath_raw = out; o.file_format = "PNG"; o.save(); print("SHEET", out)


def renders(views=("hero", "top", "side", "rear"), samples=48):
    render_setup(samples=samples)
    R = os.path.join(HERE, "renders"); os.makedirs(R, exist_ok=True)
    V = {"hero": dict(loc=(15.5, -21.0, 9.0), target=(0.2, -0.6, 1.9), lens=45),
         "top": dict(loc=(0, -0.3, 60), target=(0, -0.3, 0), ortho=21.0, roll=-90),
         "side": dict(loc=(60, -0.2, 2.6), target=(0, -0.2, 2.6), ortho=21.5),
         "rear": dict(loc=(-14.5, 19.5, 8.0), target=(0, 1.0, 2.0), lens=45),
         "front": dict(loc=(-9.0, -21.0, 4.2), target=(0, -1.5, 1.9), lens=45)}
    paths = [shot(os.path.join(R, "Deltoid_%s.png" % v), **V[v]) for v in views]
    if len(paths) == 4: sheet(paths, 2, os.path.join(R, "Deltoid_sheet.png"))
    return paths


def ref_marker():
    """Origin marker that W1RemasterKit.postProcess uses to place the model's Root (same as the body / W1 packs)."""
    m = L.Model("Ref", at=(0, 0, 0))
    rbox(m, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
    ob = L.realize([m], NAME + "_Ref")[0]
    ob.name = ob.data.name = "Ref__Origin__FF00FFNE"; ob.hide_render = True
    return ob


# ------------------------------------------------------------------ main
if __name__ == "__main__":
    objs = build()
    st = L.stats(objs)[NAME]
    per = {o.name.split("__")[1]: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs}
    over = {k: v for k, v in per.items() if v > OBJ_TRIS}
    st.update({"objects": len(objs), "perObject": per})
    print("STAT %s tris=%d objs=%d size=%s%s" % (NAME, st["tris"], len(objs), st["size"], (" OVER " + str(over)) if over else ""))
    json.dump(st, open(os.path.join(HERE, "stats_deltoid.json"), "w"), indent=1)
    if "--export" in argv: print("FBX", L.export_fbx(objs + [ref_marker()], os.path.join(HERE, "fbx", NAME + ".fbx")))
    if "--save" in argv: L.save_blend(os.path.join(HERE, "blend", NAME + ".blend")); print("BLEND saved")
    if "--render" in argv:
        vs = [a for a in argv if a.startswith("--views=")]
        renders(tuple(vs[0][8:].split(",")) if vs else ("hero", "top", "side", "rear"),
                samples=int(next((a[10:] for a in argv if a.startswith("--samples=")), 48)))
