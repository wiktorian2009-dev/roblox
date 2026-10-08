# partlib.py - extra modelling helpers for the 90 snowplow parts (built on w2lib)
import bmesh, math, random
from mathutils import Vector, Matrix
import w2lib as L
from w2lib import P, Mx, sphere, rbox, cyl, lathe, tube, torus, prism

# shared neutrals
STEEL = "C3CAD6"; DARK = "2A2D34"; NAVY = "26324F"; RUBBER = "30333C"; HAZ = "FFC81E"; GOLD = "E8B84A"; WHITE = "F6F8FC"


def frame(d, up=None):
    z = Vector(d).normalized()
    if up is None: up = Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((0, 1, 0))
    x = Vector(up).cross(z).normalized(); y = z.cross(x)
    return Matrix((x, y, z)).transposed().to_4x4()


def put(m, part, pc, tb, mat=None):
    L._put(m, part, pc, tb, mat if mat is not None else Matrix.Identity(4))


def mesh(m, pc, verts, faces, part="Main", mat=None, recalc=True):
    tb = bmesh.new(); vs = [tb.verts.new(v) for v in verts]
    for f in faces:
        try: tb.faces.new([vs[i] for i in f])
        except ValueError: pass
    if recalc: bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    put(m, part, pc, tb, mat)


def box(m, pc, loc, size, r=0.05, part="Main", rot=(0, 0, 0), bseg=1):
    rbox(m, pc, loc, size, r=r, bseg=bseg, rot=rot, part=part)


def beam(m, pc, p0, p1, w=0.3, h=0.3, r=0.06, part="Arms", bseg=1, up=None):
    p0, p1 = Vector(p0), Vector(p1); d = p1 - p0
    tb = bmesh.new(); bmesh.ops.create_cube(tb, size=1.0)
    bmesh.ops.scale(tb, vec=Vector((w, h, d.length)), verts=tb.verts)
    rr = min(r, min(w, h, d.length) * 0.45)
    if rr > 0.001: bmesh.ops.bevel(tb, geom=list(tb.edges), offset=rr, segments=bseg, affect='EDGES', profile=0.5, clamp_overlap=True)
    put(m, part, pc, tb, Matrix.Translation((p0 + p1) / 2) @ frame(d, up))


def rod(m, pc, p0, p1, r=0.1, seg=10, r2=None, part="Main", cap=True):
    p0, p1 = Vector(p0), Vector(p1); d = p1 - p0
    tb = bmesh.new()
    bmesh.ops.create_cone(tb, cap_ends=cap, cap_tris=False, segments=seg, radius1=r, radius2=(r if r2 is None else max(r2, 0.001)), depth=d.length)
    put(m, part, pc, tb, Matrix.Translation((p0 + p1) / 2) @ frame(d))


def disc(m, pc, center, r, h, axis=(0, -1, 0), seg=16, r2=None, bev=0.0, part="Main"):
    """Cylinder whose base centre is `center`, extruded h along `axis`."""
    c = Vector(center); a = Vector(axis).normalized()
    tb = bmesh.new()
    bmesh.ops.create_cone(tb, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=(r if r2 is None else max(r2, 0.001)), depth=h)
    bmesh.ops.translate(tb, vec=(0, 0, h / 2), verts=tb.verts)
    if bev > 0:
        es = [e for e in tb.edges if any(len(f.verts) > 4 for f in e.link_faces)]
        bmesh.ops.bevel(tb, geom=es, offset=min(bev, r * 0.45, h * 0.45), segments=1, affect='EDGES', profile=0.5, clamp_overlap=True)
    put(m, part, pc, tb, Matrix.Translation(c) @ frame(a))


def flat(m, pc, poly, depth, center, axis=(0, -1, 0), up=(0, 0, 1), part="Main", bev=0.0, spin=0.0):
    """Extrude a 2-D outline (x right, y up in the plate's plane) by depth along `axis` from `center`.
    For axis (0,-1,0) the outline's x = world X, y = world Z."""
    a = Vector(axis).normalized(); u = Vector(up)
    if abs(a.dot(u.normalized())) > 0.95: u = Vector((0, 1, 0)) if abs(a.y) < 0.9 else Vector((1, 0, 0))
    y = (u - a * u.dot(a)).normalized(); x = y.cross(a)
    M = Matrix((x, y, a)).transposed().to_4x4()
    if spin: M = M @ Matrix.Rotation(math.radians(spin), 4, 'Z')
    tb = bmesh.new(); vs = [tb.verts.new((px, py, 0)) for px, py in poly]
    f = tb.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(tb, geom=[f])
    nv = [e for e in ext['geom'] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(tb, vec=(0, 0, depth), verts=nv)
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    if bev > 0:
        es = [e for e in tb.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(40)]
        bmesh.ops.bevel(tb, geom=es, offset=bev, segments=1, affect='EDGES', profile=0.5, clamp_overlap=True)
    bmesh.ops.triangulate(tb, faces=[f for f in tb.faces if len(f.verts) > 4], quad_method='BEAUTY', ngon_method='BEAUTY')
    put(m, part, pc, tb, Matrix.Translation(Vector(center)) @ M)


# ---------- 2-D outlines ----------
def circle_poly(r, n=16, a0=0.0):
    return [(r * math.cos(a0 + 2 * math.pi * i / n), r * math.sin(a0 + 2 * math.pi * i / n)) for i in range(n)]

def gear_poly(n, ro, ri, frac=0.45, a0=0.0):
    pts = []; step = 2 * math.pi / n
    for i in range(n):
        a = a0 + i * step; h = step * frac / 2; e = step * (1 - frac) / 2
        pts += [(ri * math.cos(a - h - e * 0.6), ri * math.sin(a - h - e * 0.6)), (ro * math.cos(a - h), ro * math.sin(a - h)),
                (ro * math.cos(a + h), ro * math.sin(a + h)), (ri * math.cos(a + h + e * 0.6), ri * math.sin(a + h + e * 0.6))]
    return pts

def star_poly(n, ro, ri, a0=math.pi / 2):
    return [((ro if i % 2 == 0 else ri) * math.cos(a0 + math.pi * i / n), (ro if i % 2 == 0 else ri) * math.sin(a0 + math.pi * i / n)) for i in range(2 * n)]

def arch_poly(w, h, n=6):
    """Tombstone: rectangle with half-round top; base at y=0."""
    r = w / 2; pts = [(-r, 0), (r, 0), (r, h - r)]
    for i in range(1, n):
        a = math.pi * i / n; pts.append((r * math.cos(a), h - r + r * math.sin(a)))
    pts.append((-r, h - r)); return pts

def petal_poly(length, width, n=7):
    """Petal pointing +y, base at origin, with a small notch at the tip."""
    pts = []
    for i in range(n + 1):
        t = i / n; y = t * length; x = width / 2 * math.sin(math.pi * min(1, t * 1.08)) ** 0.8
        pts.append((x, y))
    pts.append((0, length * 0.9))
    for i in range(n, -1, -1):
        t = i / n; y = t * length; x = width / 2 * math.sin(math.pi * min(1, t * 1.08)) ** 0.8
        pts.append((-x, y))
    # remove duplicates
    out = []
    for p in pts:
        if not out or (abs(out[-1][0] - p[0]) + abs(out[-1][1] - p[1])) > 1e-4: out.append(p)
    if abs(out[0][0] - out[-1][0]) + abs(out[0][1] - out[-1][1]) < 1e-4: out.pop()
    return out

def bolt_poly(w, h):
    """Lightning bolt zigzag, centred, height h."""
    pts = [(-0.10, 0.5), (0.32, 0.5), (0.06, 0.10), (0.30, 0.10), (-0.22, -0.5), (-0.02, -0.06), (-0.28, -0.06)]
    return [(x * w / 0.6, y * h) for x, y in pts]

def leaf_poly(length, width, n=5):
    pts = []
    for i in range(n + 1):
        t = i / n; pts.append((width / 2 * math.sin(math.pi * t), t * length))
    for i in range(n - 1, 0, -1):
        t = i / n; pts.append((-width / 2 * math.sin(math.pi * t), t * length))
    return pts

def tri_poly(w, h):
    return [(-w / 2, 0), (w / 2, 0), (0, h)]


# ---------- blade shell ----------
def shell(m, pc, xs, prof, thick, plan=None, part="Plate", zfun=None):
    """Thick curved panel. xs: x stations (ascending). prof(x) -> [(y,z) front surface bottom->top].
    plan(x) -> y offset. Thickness goes toward the back (+Y side) along the 2-D profile normal."""
    F, B = [], []
    for x in xs:
        pts = prof(x); off = plan(x) if plan else 0.0; n = len(pts)
        fr, bk = [], []
        for j in range(n):
            a = pts[max(j - 1, 0)]; b = pts[min(j + 1, n - 1)]
            ty, tz = b[0] - a[0], b[1] - a[1]; ln = math.hypot(ty, tz) or 1
            ny, nz = tz / ln, -ty / ln
            y, z = pts[j]
            fr.append((x, y + off, z)); bk.append((x, y + off + ny * thick, z + nz * thick))
        F.append(fr); B.append(bk)
    verts = []; idx = {}
    def vid(k, i, j):
        key = (k, i, j)
        if key not in idx:
            idx[key] = len(verts); verts.append((F if k == 0 else B)[i][j])
        return idx[key]
    faces = []; ns = len(xs); n = len(F[0])
    for i in range(ns - 1):
        for j in range(n - 1):
            faces.append((vid(0, i, j), vid(0, i + 1, j), vid(0, i + 1, j + 1), vid(0, i, j + 1)))
            faces.append((vid(1, i, j), vid(1, i, j + 1), vid(1, i + 1, j + 1), vid(1, i + 1, j)))
        faces.append((vid(0, i, n - 1), vid(0, i + 1, n - 1), vid(1, i + 1, n - 1), vid(1, i, n - 1)))
        faces.append((vid(0, i, 0), vid(1, i, 0), vid(1, i + 1, 0), vid(0, i + 1, 0)))
    for i in (0, ns - 1):
        for j in range(n - 1):
            faces.append((vid(0, i, j), vid(0, i, j + 1), vid(1, i, j + 1), vid(1, i, j)))
    mesh(m, pc, verts, faces, part=part)
    return F, B


def profile_fn(pts):
    """Return a prof(x) that ignores x (constant cross-section)."""
    return lambda x: pts


def bez(p0, p1, p2, n=6):
    out = []
    for i in range(n + 1):
        t = i / n; a = (1 - t) ** 2; b = 2 * (1 - t) * t; c = t * t
        out.append((a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1]))
    return out


def stations(w, n):
    return [-w / 2 + w * i / (n - 1) for i in range(n)]


def along(F, i_frac, j_frac):
    """Sample a point on the shell front surface (fractions)."""
    ns = len(F); n = len(F[0])
    fi = i_frac * (ns - 1); fj = j_frac * (n - 1)
    i0 = min(int(fi), ns - 2); j0 = min(int(fj), n - 2)
    ti = fi - i0; tj = fj - j0
    def P_(i, j): return Vector(F[i][j])
    a = P_(i0, j0).lerp(P_(i0 + 1, j0), ti); b = P_(i0, j0 + 1).lerp(P_(i0 + 1, j0 + 1), ti)
    return a.lerp(b, tj)


# ---------- wheels and tracks ----------
def tire(m, pc, c, R, w, part="Tire", seg=18, bulge=0.12, inner=0.55, axis_x=True):
    """Rounded tyre centred at c with its axle along X."""
    hw = w / 2
    prof = [(R * inner, -hw), (R * (1 - bulge * 0.9), -hw), (R * (1 - bulge * 0.15), -hw * 0.72), (R, -hw * 0.3),
            (R, hw * 0.3), (R * (1 - bulge * 0.15), hw * 0.72), (R * (1 - bulge * 0.9), hw), (R * inner, hw)]
    lathe(m, pc, prof, loc=c, seg=seg, rot=(0, 90, 0), part=part)


def knobs(m, pc, c, R, w, n=12, size=(None, 0.26, 0.16), rows=1, stagger=True, part="Knobs", r=0.03, chevron=0.0):
    cx, cy, cz = c
    kw = size[0] if size[0] else (w * 0.82 / rows)
    for row in range(rows):
        xo = (row - (rows - 1) / 2) * (w / rows) * 0.98
        for k in range(n):
            a = 2 * math.pi * (k + (0.5 * row if stagger else 0)) / n
            rr = R + size[2] * 0.25
            loc = (cx + xo, cy + rr * math.cos(a), cz + rr * math.sin(a))
            M = (Matrix.Translation(loc) @ Matrix.Rotation(a - math.pi / 2, 4, 'X')
                 @ Matrix.Rotation(math.radians(chevron if row % 2 == 0 else -chevron), 4, 'Z'))
            box_m(m, pc, M, (kw, size[1], size[2]), r=r, part=part)


def box_m(m, pc, M, size, r=0.03, part="Main", bseg=1):
    tb = bmesh.new(); bmesh.ops.create_cube(tb, size=1.0)
    bmesh.ops.scale(tb, vec=Vector(size), verts=tb.verts)
    rr = min(r, min(size) * 0.45)
    if rr > 0.001: bmesh.ops.bevel(tb, geom=list(tb.edges), offset=rr, segments=bseg, affect='EDGES', profile=0.5, clamp_overlap=True)
    put(m, part, pc, tb, M)


def hull2d(points):
    pts = sorted(set((round(p[0], 5), round(p[1], 5)) for p in points))
    if len(pts) <= 2: return pts
    def cross(o, a, b): return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0: lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0: up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]   # CCW


def track_path(wheels, n=14):
    """wheels: [(y, z, r)] -> CCW hull polygon (y,z) of the belt's inner surface."""
    pts = []
    for (y, z, r) in wheels:
        for i in range(n):
            a = 2 * math.pi * i / n; pts.append((y + r * math.cos(a), z + r * math.sin(a)))
    return hull2d(pts)


def _normals2d(poly):
    n = len(poly); out = []
    for i in range(n):
        a = poly[i - 1]; b = poly[(i + 1) % n]
        ty, tz = b[0] - a[0], b[1] - a[1]; ln = math.hypot(ty, tz) or 1
        out.append((tz / ln, -ty / ln))   # outward for CCW
    return out


def belt(m, pc, poly, xc, width, thick, part="Track"):
    n = len(poly); N = _normals2d(poly); hw = width / 2
    verts = []
    for (y, z), (ny, nz) in zip(poly, N):
        for x in (xc - hw, xc + hw):
            verts.append((x, y, z)); verts.append((x, y + ny * thick, z + nz * thick))
    # index: i*4 + [0 inL,1 outL,2 inR,3 outR]
    faces = []
    for i in range(n):
        j = (i + 1) % n; a, b = i * 4, j * 4
        faces.append((a + 1, b + 1, b + 3, a + 3))  # outer
        faces.append((a + 0, a + 2, b + 2, b + 0))  # inner
        faces.append((a + 0, b + 0, b + 1, a + 1))  # left side
        faces.append((a + 2, a + 3, b + 3, b + 2))  # right side
    mesh(m, pc, verts, faces, part=part)


def cleats(m, pc, poly, xc, width, thick, spacing=0.42, h=0.12, depth=0.16, part="Cleats", r=0.0):
    n = len(poly); N = _normals2d(poly)
    segs = []; total = 0
    for i in range(n):
        a = Vector(poly[i]); b = Vector(poly[(i + 1) % n]); segs.append((a, b, total)); total += (b - a).length
    k = int(total / spacing); out = 0
    for s in range(k):
        d = s * total / k
        for a, b, t0 in segs:
            ln = (b - a).length
            if t0 <= d <= t0 + ln + 1e-9:
                p = a.lerp(b, (d - t0) / ln if ln else 0); t = (b - a).normalized()
                nrm = Vector((t.y, -t.x))
                c = p + nrm * (thick + h / 2)
                ang = math.degrees(math.atan2(nrm.y, nrm.x)) - 90
                box(m, pc, (xc, c.x, c.y), (width * 1.02, depth, h), r=r, rot=(ang, 0, 0), part=part, bseg=1)
                out += 1
                break
    return out


def wheel_disc(m, pc, c, r, w, seg=14, part="Hub", bev=0.04):
    """Cylinder along X centred at c (width w)."""
    disc(m, pc, (c[0] - w / 2, c[1], c[2]), r, w, axis=(1, 0, 0), seg=seg, bev=bev, part=part)


def mirror_x(fn, *a, **k):
    for sx in (-1, 1): fn(sx, *a, **k)


def helix(m, pc, c, R, r, h, turns, seg=8, part="Coil", axis="z", n=None):
    n = n or int(turns * 12)
    pts = []
    for i in range(n + 1):
        t = i / n; a = 2 * math.pi * turns * t
        if axis == "z": pts.append((c[0] + R * math.cos(a), c[1] + R * math.sin(a), c[2] + h * t))
        elif axis == "y": pts.append((c[0] + R * math.cos(a), c[1] + h * t, c[2] + R * math.sin(a)))
        else: pts.append((c[0] + h * t, c[1] + R * math.cos(a), c[2] + R * math.sin(a)))
    tube(m, pc, pts, r=r, seg=seg, part=part, smooth=1)


def crystal(m, pc, base, tip, r, seg=6, part="Crystal", mid=0.72):
    """Faceted crystal: hexagonal prism with pointed tip; base centre -> tip."""
    b = Vector(base); t = Vector(tip); d = t - b; Ln = d.length
    tb = bmesh.new()
    prof = [(r * 0.7, 0), (r, Ln * 0.08), (r, Ln * mid), (0, Ln)]
    rings = []
    for (rr, z) in prof:
        if rr == 0: rings.append([tb.verts.new((0, 0, z))]); continue
        rings.append([tb.verts.new((rr * math.cos(2 * math.pi * i / seg), rr * math.sin(2 * math.pi * i / seg), z)) for i in range(seg)])
    for A, B in zip(rings, rings[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            if len(B) == 1: tb.faces.new((A[i], A[j], B[0]))
            else: tb.faces.new((A[i], A[j], B[j], B[i]))
    tb.faces.new(list(reversed(rings[0])))
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    put(m, part, pc, tb, Matrix.Translation(b) @ frame(d))
    m.flat(part, pc, 1)


def spike(m, pc, base, tip, r, seg=8, part="Spikes"):
    rod(m, pc, base, tip, r=r, seg=seg, r2=0.001, part=part)


def puff(m, pc, centers, part="Puff", seg=10):
    for (x, y, z, r) in centers:
        sphere(m, pc, (x, y, z), r, seg=seg, rings=max(5, int(seg * 0.6)), part=part)
