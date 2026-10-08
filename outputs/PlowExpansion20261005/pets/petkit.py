# petkit.py - shared helpers for the 70-pet rebuild (Claude, 2026-10-05).
# Built on outputs/World2Blender/w2lib.py. 1 unit = 1 stud, face looks toward -Y, up = +Z.
# Every part name must start with a role prefix (ROLES) - the runtime Golden recolour depends on it.
import sys, math, random
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import bpy, bmesh
from mathutils import Vector, Matrix, Quaternion, Euler
import w2lib
from w2lib import P, Mx, Model, rbox, cyl, lathe, torus, _put, _merge, _catmull, heart_poly

SC = [1.0]   # global segment scale (auto-reduced by the builder when a pet exceeds its triangle budget)
def _sc(n, lo=4): return max(lo, int(round(n * SC[0])))
ROLES = ("Belly", "Body", "Mark", "Accent", "Eye", "Shine", "Mouth", "Nose", "Blush", "Glow")
INK = P("241C33")      # default eye colour
WHITE = P("FFFFFF")    # eye highlights
MOUTH = P("4A2433")
BLUSH = P("FF8DA6")

def role_of(part):
    for r in ROLES:
        if part.startswith(r): return r
    return None

def _segs(rmax):
    return max(6, min(12, int(round(5 + rmax * 6.0))))

def _rotm(rot):
    return Euler([math.radians(a) for a in rot], 'XYZ').to_matrix().to_4x4()

# ---------------------------------------------------------------- primitives
def ell(m, pc, c, r, part="Body", seg=None, rings=None, rot=(0, 0, 0), q=None):
    """Ellipsoid with radii r=(rx,ry,rz) at c. Rotation by Euler degrees or quaternion q."""
    if isinstance(r, (int, float)): r = (r, r, r)
    if seg is None: seg = _segs(max(r))
    if rings is None: rings = max(4, int(seg * 0.6 + 0.5))
    seg, rings = _sc(seg, 5), _sc(rings, 4)
    tb = bmesh.new(); bmesh.ops.create_uvsphere(tb, u_segments=seg, v_segments=rings, radius=1.0)
    R = q.to_matrix().to_4x4() if q is not None else _rotm(rot)
    _put(m, part, pc, tb, Matrix.Translation(Vector(c)) @ R @ Matrix.Diagonal((r[0], r[1], r[2], 1.0)))

def box(m, pc, c, size, r=0.06, part="Body", rot=(0, 0, 0), bseg=1):
    rbox(m, pc, c, size, r=r, bseg=bseg, rot=rot, part=part)

def vtube(m, pc, pts, radii, seg=8, part="Body", smooth=3, sq=1.0, phase=0.0, up=None):
    """Tube along pts with per-point radii (0 = pointed end). sq flattens the tube along the frame normal."""
    Pp = [Vector(p) for p in pts]; R = list(radii); seg = _sc(seg, 4)
    if SC[0] < 0.8 and smooth > 2: smooth -= 1
    if smooth > 1 and len(Pp) > 2:
        Pp = _catmull(Pp, smooth, False); RR = []
        for i in range(len(R) - 1):
            for k in range(smooth): RR.append(R[i] + (R[i + 1] - R[i]) * k / smooth)
        RR.append(R[-1]); R = RR
    n = len(Pp); tb = bmesh.new(); rings = []
    T = []
    for i in range(n):
        t = Pp[min(i + 1, n - 1)] - Pp[max(i - 1, 0)]
        T.append(t.normalized() if t.length > 1e-9 else Vector((0, 0, 1)))
    upv = Vector(up) if up else (Vector((0, 0, 1)) if abs(T[0].z) < 0.95 else Vector((0, -1, 0)))
    N = (upv - T[0] * upv.dot(T[0])).normalized()
    for i in range(n):
        if i > 0:
            N = N - T[i] * N.dot(T[i])
            N = N.normalized() if N.length > 1e-9 else N
        B = T[i].cross(N); rr = R[i]
        if rr <= 0.002: rings.append([tb.verts.new(Pp[i])]); continue
        rings.append([tb.verts.new(Pp[i] + (N * math.cos(2 * math.pi * k / seg + phase) * sq + B * math.sin(2 * math.pi * k / seg + phase)) * rr) for k in range(seg)])
    for a, b in zip(rings, rings[1:]):
        if len(a) == 1 and len(b) == 1: continue
        for k in range(seg):
            j = (k + 1) % seg
            if len(a) == 1: tb.faces.new((a[0], b[k], b[j]))
            elif len(b) == 1: tb.faces.new((a[k], a[j], b[0]))
            else: tb.faces.new((a[k], a[j], b[j], b[k]))
    if len(rings[0]) > 1: tb.faces.new(list(reversed(rings[0])))
    if len(rings[-1]) > 1: tb.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _merge(m.bm(part, pc), tb)

def slab(m, pc, poly, thick, M, part="Body", mirror=1):
    """Flat shape: 2-D outline poly [(x,z)...] in the XZ plane, thickness along Y, placed by matrix M.
    mirror=-1 mirrors in X (applied in world after M)."""
    tb = bmesh.new()
    vs = [tb.verts.new((x, -thick / 2, z)) for x, z in poly]
    f = tb.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(tb, geom=[f])
    nv = [e for e in ext['geom'] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(tb, vec=(0, thick, 0), verts=nv)
    bmesh.ops.triangulate(tb, faces=tb.faces[:], quad_method='BEAUTY', ngon_method='BEAUTY')
    W = Matrix.Diagonal((mirror, 1, 1, 1)) @ M
    bmesh.ops.transform(tb, matrix=W, verts=tb.verts)
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _merge(m.bm(part, pc), tb)
    m.flat(part, pc, 30)

def cone(m, pc, base, tip, r, seg=8, part="Accent", r_tip=0.0, sq=1.0):
    vtube(m, pc, [base, tip], [r, r_tip], seg=seg, part=part, smooth=1, sq=sq)

def horn(m, pc, base, ctrl, tip, r, seg=8, part="Accent"):
    vtube(m, pc, [base, ctrl, tip], [r, r * 0.6, 0.0], seg=seg, part=part, smooth=3)

def crystal(m, pc, base, direction, length, r, seg=6, part="Accent", rot_phase=0.0):
    d = Vector(direction).normalized(); b = Vector(base)
    vtube(m, pc, [b, b + d * length * 0.18, b + d * length * 0.72, b + d * length], [r * 0.7, r, r, 0.0], seg=seg, part=part, smooth=1, phase=rot_phase)
    m.flat(part, pc, 20)

def gem(m, pc, c, r, h=None, seg=6, part="Accent", rot=(0, 0, 0)):
    h = h or r * 1.3
    lathe(m, pc, [(0, -h * 0.55), (r, 0), (r * 0.6, h * 0.35), (0, h * 0.4)], loc=c, seg=seg, rot=rot, part=part)
    m.flat(part, pc, 20)

def star_poly(R, r, n=5, rot=90):
    out = []
    for i in range(n * 2):
        a = math.radians(rot) + math.pi * i / n
        rr = R if i % 2 == 0 else r
        out.append((math.cos(a) * rr, math.sin(a) * rr))
    return out

def gear_poly(R, teeth=8, depth=0.22, per=4):
    teeth = min(teeth, 8)
    out = []; n = teeth * per
    for i in range(n):
        a = 2 * math.pi * i / n; k = i % per
        rr = R if k in (0, 1) else R * (1 - depth)
        out.append((math.cos(a) * rr, math.sin(a) * rr))
    return out

def disc(m, pc, poly, thick, c, normal=(0, -1, 0), spin=0.0, part="Accent"):
    """Flat 2-D outline [(x,y)] laid out facing `normal` (outline local X,Y -> plane axes)."""
    n = Vector(normal).normalized()
    q = n.to_track_quat('Y', 'Z') @ Quaternion((0, 1, 0), math.radians(spin))
    M = Matrix.Translation(Vector(c)) @ q.to_matrix().to_4x4()
    slab(m, pc, [(x, y) for x, y in poly], thick, M, part=part)

def flower(m, petal_pc, center_pc, c, r, normal=(0, -1, 0), petals=5, part="Accent", cpart="Belly", spin=0.0):
    n = Vector(normal).normalized(); per = 3; poly = []
    for i in range(petals * per):
        a = 2 * math.pi * i / (petals * per); k = abs(math.cos(petals * a / 2))
        poly.append((math.cos(a) * r * (0.45 + 0.55 * k), math.sin(a) * r * (0.45 + 0.55 * k)))
    disc(m, petal_pc, poly, r * 0.2, c, normal, spin, part=part)
    ell(m, center_pc, Vector(c) + n * r * 0.12, (r * 0.3, r * 0.3, r * 0.3), part=cpart, seg=6, rings=4)

# ---------------------------------------------------------------- surfaces / faces
class Head:
    """Axis-aligned ellipsoid surface used to place facial features. yaw: + toward +X, pitch: + up."""
    def __init__(self, c, r):
        self.c = Vector(c); self.r = Vector(r if not isinstance(r, (int, float)) else (r, r, r))
    def u(self, yaw, pitch):
        y, p = math.radians(yaw), math.radians(pitch)
        return Vector((math.sin(y) * math.cos(p), -math.cos(y) * math.cos(p), math.sin(p)))
    def pt(self, yaw, pitch, off=0.0):
        u = self.u(yaw, pitch); r = self.r
        p = self.c + Vector((u.x * r.x, u.y * r.y, u.z * r.z))
        n = Vector((u.x / r.x, u.y / r.y, u.z / r.z)).normalized()
        return p + n * off, n
    def put(self, m, pc, yaw, pitch, r, part, off=0.0, seg=8, rings=5, spin=0.0):
        p, n = self.pt(yaw, pitch)
        q = n.to_track_quat('Y', 'Z') @ Quaternion((0, 1, 0), math.radians(spin))
        if isinstance(r, (int, float)): r = (r, r, r)
        ell(m, pc, p + n * off, r, part=part, seg=seg, rings=rings, q=q)

class FlatFace(Head):
    """Flat front plane (box heads): yaw/pitch map to x/z on the plane y = c.y - r.y."""
    def pt(self, yaw, pitch, off=0.0):
        x = self.c.x + self.r.x * math.sin(math.radians(yaw)); z = self.c.z + self.r.z * math.sin(math.radians(pitch))
        n = Vector((0, -1, 0))
        return Vector((x, self.c.y - self.r.y, z)) + n * off, n

class LatheFace(Head):
    """Face surface of a lathe profile [(r,z)...] centred at c (x,y): pitch maps to z = zc + zr*sin(pitch)."""
    def __init__(self, prof, c, zc, zr, sx=1.0, sy=1.0):
        self.prof = prof; self.c = Vector((c[0], c[1], zc)); self.zr = zr; self.sx, self.sy = sx, sy
        self.r = Vector((self.rad(zc) * sx, self.rad(zc) * sy, zr))
    def rad(self, z):
        pr = self.prof
        for (r1, z1), (r2, z2) in zip(pr, pr[1:]):
            if z1 <= z <= z2: return r1 + (r2 - r1) * (z - z1) / max(1e-6, z2 - z1)
        return pr[-1][0] if z > pr[-1][1] else pr[0][0]
    def pt(self, yaw, pitch, off=0.0):
        z = self.c.z + self.zr * math.sin(math.radians(pitch)); r = self.rad(z)
        dr = (self.rad(z + 0.02) - self.rad(z - 0.02)) / 0.04
        y = math.radians(yaw)
        p = Vector((self.c.x + r * math.sin(y) * self.sx, self.c.y - r * math.cos(y) * self.sy, z))
        n = Vector((math.sin(y) / self.sx, -math.cos(y) / self.sy, -dr)).normalized()
        return p + n * off, n

def _frame(n):
    tz = Vector((0, 0, 1)) - n * n.z
    tz = tz.normalized() if tz.length > 1e-6 else Vector((0, 1, 0))
    tx = tz.cross(n).normalized()
    return tx, tz

def eyes(m, h, yaw=24, pitch=6, rx=0.15, rz=None, depth=0.055, pc=INK, shine=WHITE, part="Eye", gap=0.014,
         tilt=0.0, shine2=True, seg=10, square=False, single=False):
    """Big cute eyes sitting proud of surface h, with highlights. Returns list of (centre, normal)."""
    rz = rz or rx * 1.22; out = []
    for s in ((0,) if single else (-1, 1)):
        p, n = h.pt(s * yaw, pitch)
        q = n.to_track_quat('Y', 'Z') @ Quaternion((0, 1, 0), math.radians(-s * tilt))
        c = p + n * gap
        ell(m, pc, c, (rx, depth, rz), part=part, seg=seg, rings=max(6, seg // 2 + 1), q=q)
        tx = (q @ Vector((1, 0, 0))); tz = (q @ Vector((0, 0, 1)))
        if tx.x < 0: tx = -tx
        for (u, v, k) in ([(-0.34, 0.36, 0.34), (0.3, -0.32, 0.15)] if shine2 else [(-0.34, 0.36, 0.34)]):
            w = math.sqrt(max(0.0, 1 - u * u - v * v))
            sp = c + tx * (u * rx) + tz * (v * rz) + n * (depth * w + 0.008)
            nn = (tx * (u / rx) + n * (w / depth) + tz * (v / rz)).normalized()
            ell(m, shine, sp, (rx * k, 0.018, rx * k), part="Shine", seg=6, rings=4, q=nn.to_track_quat('Y', 'Z'))
        out.append((c, n))
    return out

def sqeyes(m, h, yaw=24, pitch=6, w=0.24, hgt=0.26, depth=0.05, pc=INK, part="Eye"):
    """Square/pixel eyes on a flat or curved face, with square highlights."""
    for s in (-1, 1):
        p, n = h.pt(s * yaw, pitch)
        q = n.to_track_quat('Y', 'Z'); R = q.to_matrix().to_4x4()
        c = p + n * (depth + 0.012)
        tb = bmesh.new(); bmesh.ops.create_cube(tb, size=1.0)
        bmesh.ops.scale(tb, vec=Vector((w, depth * 2, hgt)), verts=tb.verts)
        _put(m, part, pc, tb, Matrix.Translation(c) @ R)
        tx = q @ Vector((1, 0, 0)); tz = q @ Vector((0, 0, 1))
        tb = bmesh.new(); bmesh.ops.create_cube(tb, size=1.0)
        bmesh.ops.scale(tb, vec=Vector((w * 0.34, 0.03, hgt * 0.34)), verts=tb.verts)
        if tx.x < 0: tx = -tx
        _put(m, "Shine", WHITE, tb, Matrix.Translation(c + n * (depth + 0.01) - tx * w * 0.2 + tz * hgt * 0.2) @ R)

def happy_eyes(m, h, yaw=24, pitch=8, w=10, r=0.035, pc=INK, part="Eye", lift=6):
    """Closed ^ ^ happy eyes (arcs) on the surface."""
    for s in (-1, 1):
        pts = [h.pt(s * yaw + d, pitch + lift * (1 - abs(d) / w) ** 0.7, r * 0.7)[0] for d in (-w, -w / 2, 0, w / 2, w)]
        vtube(m, pc, pts, [r * 0.8, r, r, r, r * 0.8], seg=6, part=part, smooth=2)

def mouth(m, h, pitch=-14, w=8, kind="w", pc=MOUTH, r=0.024, sag=4, yaw0=0.0, part="Mouth"):
    if kind == "w":
        keys = [(-w, 0), (-w / 2, -sag), (0, 0), (w / 2, -sag), (w, 0)]
    elif kind == "smile":
        keys = [(-w, 0), (-w / 2, -sag * 0.8), (0, -sag), (w / 2, -sag * 0.8), (w, 0)]
    elif kind == "flat":
        keys = [(-w, 0), (0, -sag * 0.2), (w, 0)]
    elif kind == "o":
        h.put(m, pc, yaw0, pitch, (r * 3, r * 1.2, r * 3.3), part, off=0.004, seg=8, rings=5); return
    elif kind == "open":
        h.put(m, pc, yaw0, pitch, (w * 0.012, 0.03, w * 0.009), part, off=0.0, seg=10, rings=6); return
    pts = [h.pt(yaw0 + a, pitch + b, r * 0.55)[0] for a, b in keys]
    vtube(m, pc, pts, [r] * len(pts), seg=6, part=part, smooth=2)

def fang(m, h, yaw, pitch, size=0.06, pc=WHITE, part="Mouth"):
    p, n = h.pt(yaw, pitch, 0.0)
    cone(m, pc, p + n * 0.01 + Vector((0, 0, size * 0.2)), p + n * 0.03 + Vector((0, 0, -size)), size * 0.45, seg=5, part=part)

def blush(m, h, yaw=40, pitch=-6, r=0.1, pc=BLUSH, part="Blush"):
    for s in (-1, 1):
        h.put(m, pc, s * yaw, pitch, (r, 0.018, r * 0.62), part, off=0.006, seg=8, rings=5)

def nose(m, h, pitch=-4, r=(0.07, 0.05, 0.05), pc=P("3A2A33"), part="Nose", yaw=0.0, off=0.01):
    h.put(m, pc, yaw, pitch, r, part, off=off, seg=8, rings=5)

# ---------------------------------------------------------------- ears / limbs / tails / wings
def pointy_ear(m, pc, ipc, h, yaw, pitch, height=0.55, width=0.3, out=18, back=-8, thick=0.45, inner=True,
               part="Body", ipart="Belly", sink=0.08, seg=8, bend=0.0):
    for s in (-1, 1):
        p, n = h.pt(s * yaw, pitch)
        b = p - n * sink
        rot = (back, s * out, 0)
        prof = [(width, 0), (width * 0.85, height * 0.35), (width * 0.45, height * 0.75), (0, height)]
        lathe(m, pc, prof, loc=b, rot=rot, seg=seg, sy=thick, part=part)
        if inner and ipc:
            M = Mx(b, rot)
            ip = M @ Vector((0, -width * thick * 0.55, height * 0.12))
            lathe(m, ipc, [(width * 0.62, 0), (width * 0.5, height * 0.3), (width * 0.22, height * 0.6), (0, height * 0.78)],
                  loc=ip, rot=rot, seg=seg, sy=thick * 0.5, part=ipart)

def round_ear(m, pc, ipc, h, yaw, pitch, r=0.26, thick=0.45, out=10, part="Body", ipart="Belly", sink=0.06, back=0):
    for s in (-1, 1):
        p, n = h.pt(s * yaw, pitch)
        c = p - n * sink + n * r * 0.55
        ell(m, pc, c, (r, r * thick, r), part=part, rot=(back, s * out, 0), seg=10, rings=7)
        if ipc:
            M = Mx(c, (back, s * out, 0))
            ell(m, ipc, M @ Vector((0, -r * thick * 0.62, -r * 0.05)), (r * 0.62, r * thick * 0.4, r * 0.62), part=ipart, rot=(back, s * out, 0), seg=8, rings=5)

def long_ear(m, pc, ipc, h, yaw, pitch, length=0.75, width=0.2, out=10, back=-8, droop=0.0, part="Body", ipart="Belly", thick=0.5, sink=0.06, sides=(-1, 1)):
    for s in sides:
        p, n = h.pt(s * yaw, pitch)
        b = p - n * sink
        d = Vector((s * math.sin(math.radians(out)), math.sin(math.radians(-back)) * 0.0 + math.sin(math.radians(-back)), 1)).normalized()
        d = (Mx((0, 0, 0), (back, s * out, 0)) @ Vector((0, 0, 1))).normalized()
        mid = b + d * length * 0.55
        tip = b + d * length + Vector((s * droop, 0, -abs(droop) * 0.6))
        vtube(m, pc, [b, mid, tip], [width * 0.75, width, 0.03], seg=10, part=part, smooth=3, sq=thick)
        if ipc:
            fo = Vector((0, -width * thick * 0.55, 0))
            vtube(m, ipc, [b + d * length * 0.12 + fo, mid + fo, tip + fo * 0.8 - d * length * 0.08], [width * 0.4, width * 0.58, 0.02], seg=8, part=ipart, smooth=3, sq=thick * 0.45)

def foot(m, pc, x, y, r=0.18, part="Body", ry=1.2, rz=0.72, z=None, seg=10):
    ell(m, pc, (x, y, (r * rz) if z is None else z), (r, r * ry, r * rz), part=part, seg=seg, rings=6)

def leg(m, pc, top, bottom, r=0.13, part="Body", seg=8, paw=1.25):
    vtube(m, pc, [top, bottom], [r, r], seg=seg, part=part, smooth=1)
    b = Vector(bottom)
    ell(m, pc, (b.x, b.y - r * 0.15, max(r * paw * 0.7, b.z)), (r * paw, r * paw * 1.15, r * paw * 0.7), part=part, seg=seg, rings=5)

def wing_poly(kind, span=1.0, hgt=0.6, lobes=3):
    """Right-side wing outline in (x,z): root near x=0, tip toward +x."""
    if kind == "feather":
        top = [(0.0, 0.1), (0.2, 0.42), (0.5, 0.62), (0.8, 0.66), (1.0, 0.55)]
        bot = []
        for i in range(lobes):
            x0 = 1.0 - i * (0.85 / lobes); x1 = 1.0 - (i + 1) * (0.85 / lobes)
            bot += [(x0 - 0.02, 0.38 - i * 0.12), (x0 - 0.1, 0.12 - i * 0.14), ((x0 + x1) / 2 - 0.06, 0.0 - i * 0.13)]
        bot += [(0.1, -0.1), (0.0, -0.05)]
        pts = top + bot
    elif kind == "bat":
        pts = [(0, 0.1), (0.35, 0.45), (0.75, 0.72), (1.0, 0.82), (0.92, 0.4), (0.84, 0.18), (0.7, 0.3), (0.58, 0.02),
               (0.45, 0.14), (0.3, -0.12), (0.18, 0.02), (0.0, -0.12)]
    elif kind == "leaf":
        pts = [(math.cos(a) * 0.5 + 0.5, math.sin(a) * 0.5) for a in [math.pi * (1 - i / 11) for i in range(12)]] + \
              [(math.cos(a) * 0.5 + 0.5, math.sin(a) * 0.32) for a in [-math.pi * (i / 11) for i in range(1, 11)]]
    elif kind == "shard":
        pts = [(0, 0.05), (0.3, 0.5), (0.62, 0.78), (1.0, 0.95), (0.86, 0.5), (0.98, 0.3), (0.66, 0.16), (0.72, -0.12), (0.36, -0.02), (0.18, -0.2), (0.0, -0.1)]
    elif kind == "fin":
        pts = [(0, 0.2), (0.4, 0.3), (0.85, 0.15), (1.0, -0.05), (0.7, -0.15), (0.3, -0.18), (0.0, -0.1)]
    elif kind == "dragon":
        pts = [(0, 0.08), (0.25, 0.5), (0.55, 0.8), (0.82, 0.98), (1.0, 1.0), (0.92, 0.7), (0.86, 0.38), (0.72, 0.5), (0.62, 0.15),
               (0.46, 0.28), (0.34, -0.02), (0.18, 0.06), (0.0, -0.1)]
    elif kind == "round":
        pts = [(0.5 + math.cos(a) * 0.5, math.sin(a) * 0.45) for a in [2 * math.pi * i / 16 for i in range(16)]]
    else:
        raise ValueError(kind)
    return [(x * span, z * hgt) for x, z in pts]

def wings(m, pc, kind, root, span=1.0, hgt=0.6, thick=0.07, spread=(10, 20, 25), part="Accent", lobes=3, sides=(-1, 1)):
    """Pair of flat wings. root = right-wing root (x>0). spread=(raise about Y (deg, tip up), sweep back about Z, tilt about X)."""
    poly = wing_poly(kind, span, hgt, lobes)
    for s in sides:
        M = Matrix.Translation(Vector(root)) @ _rotm((spread[2], -spread[0], spread[1]))
        slab(m, pc, poly, thick, M, part=part, mirror=s)

def scarf(m, pc, c, R=0.45, r=0.09, tail=True, Ry=None, part="Accent", side=1, tail_len=0.42):
    Ry = Ry or R
    pts = [(c[0] + math.cos(a) * R, c[1] + math.sin(a) * Ry, c[2]) for a in [2 * math.pi * i / 18 for i in range(18)]]
    from w2lib import tube
    tube(m, pc, pts, r=r, seg=8, part=part, closed=True, smooth=1, sq=1.6)
    if tail:
        a = math.radians(-60 if side > 0 else -120)
        b = Vector((c[0] + math.cos(a) * R * 0.95, c[1] + math.sin(a) * Ry * 0.95 - 0.04, c[2] - 0.02))
        vtube(m, pc, [b, b + Vector((side * 0.06, -0.06, -tail_len * 0.5)), b + Vector((side * 0.1, -0.05, -tail_len))], [r * 1.2, r * 1.3, r * 1.4], seg=6, part=part, smooth=2, sq=0.45)

# ---------------------------------------------------------------- finishing
TARGET = {"Common": (3.0, 2.6), "Uncommon": (3.1, 2.7), "Rare": (3.3, 2.85), "Legendary": (3.8, 3.1)}

def bbox(m):
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for b in m.parts.values():
        for v in b.verts:
            mn = Vector(map(min, mn, v.co)); mx = Vector(map(max, mx, v.co))
    return mn, mx

def finish(m, rarity, L=None, H=None, scale=None):
    """Recentre (feet at z=0, footprint centred) and scale into the rarity size box. Validates parts."""
    for k in m.order:
        part = k.split("__")[0]
        if role_of(part) is None: raise ValueError("%s: part %s has no role prefix" % (m.name, part))
    if len(m.order) > 12: raise ValueError("%s: %d objects > 12: %s" % (m.name, len(m.order), m.order))
    for k in m.order:
        if k not in m.sharp: m.sharp[k] = 80
    mn, mx = bbox(m)
    size = mx - mn
    tl, th = TARGET[rarity]
    if L: tl = L
    if H: th = H
    s = scale or min(tl / max(size.x, size.y, size.z), th / size.z)
    off = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
    M = Matrix.Diagonal((s, s, s, 1)) @ Matrix.Translation(-off)
    for b in m.parts.values():
        bmesh.ops.transform(b, matrix=M, verts=b.verts)
    m.meta["scale"] = round(s, 3)
    tris = 0
    for b in m.parts.values():
        tris += sum(len(f.verts) - 2 for f in b.faces)
    m.meta["tris"] = tris
    if tris > 2300:
        top = sorted(((sum(len(f.verts) - 2 for f in b.faces), k) for k, b in m.parts.items()), reverse=True)[:5]
        print("HEAVY", m.name, tris, top)
    return s


def vox(m, pc, cells, unit, origin=(0, 0, 0), part="Body", gap=0.0):
    """Voxel blocks: cells = [(i,j,k), ...] -> cubes of edge `unit` centred at origin + cell*unit."""
    o = Vector(origin)
    for (i, j, k) in cells:
        tb = bmesh.new(); bmesh.ops.create_cube(tb, size=unit - gap)
        _put(m, part, pc, tb, Matrix.Translation(o + Vector((i, j, k)) * unit))

def cube(m, pc, c, size, part="Body", rot=(0, 0, 0)):
    tb = bmesh.new(); bmesh.ops.create_cube(tb, size=1.0)
    bmesh.ops.scale(tb, vec=Vector(size), verts=tb.verts)
    _put(m, part, pc, tb, Matrix.Translation(Vector(c)) @ _rotm(rot))

def segtube(m, pcs, parts, pts, radii, seglen, seg=10, smooth=4, sq=1.0):
    """Tube split into alternating colour bands (stripes on tails, lappets...)."""
    Pp = [Vector(p) for p in pts]; R = list(radii)
    if smooth > 1 and len(Pp) > 2:
        Pp = _catmull(Pp, smooth, False); RR = []
        for i in range(len(R) - 1):
            for k in range(smooth): RR.append(R[i] + (R[i + 1] - R[i]) * k / smooth)
        RR.append(R[-1]); R = RR
    chunk, rch, acc, idx = [Pp[0]], [R[0]], 0.0, 0
    for i in range(1, len(Pp)):
        chunk.append(Pp[i]); rch.append(R[i]); acc += (Pp[i] - Pp[i - 1]).length
        if acc >= seglen or i == len(Pp) - 1:
            vtube(m, pcs[idx % len(pcs)], chunk, rch, seg=seg, part=parts[idx % len(parts)], smooth=1, sq=sq)
            chunk, rch, acc, idx = [Pp[i]], [R[i]], 0.0, idx + 1

def lathe_wave(m, pc, prof, seg=20, loc=(0, 0, 0), part="Body", wave=(6, 0.0), wave_rings=1, sx=1.0, sy=1.0):
    """Lathe (prof [(r,z)...] bottom->top) whose first `wave_rings` rings wave up/down (ghost hems)."""
    tb = bmesh.new(); rings = []; o = Vector(loc)
    for ri, (r, z) in enumerate(prof):
        if r <= 1e-6: rings.append([tb.verts.new(o + Vector((0, 0, z)))]); continue
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            dz = wave[1] * math.cos(wave[0] * a) * (1 - ri / max(1, wave_rings)) if ri < wave_rings else 0.0
            ring.append(tb.verts.new(o + Vector((r * math.cos(a) * sx, r * math.sin(a) * sy, z + dz))))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            if len(a) == 1: tb.faces.new((a[0], b[i], b[j]))
            elif len(b) == 1: tb.faces.new((a[i], a[j], b[0]))
            else: tb.faces.new((a[i], a[j], b[j], b[i]))
    if len(rings[0]) > 1: tb.faces.new(list(reversed(rings[0])))
    if len(rings[-1]) > 1: tb.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _merge(m.bm(part, pc), tb)

def lashes(m, h, yaw, pitch, rx, rz, pc=INK, part="Eye", n=2, ln=0.09):
    """Small eyelash flicks at the outer-top corner of each eye."""
    for s in (-1, 1):
        for k in range(n):
            a = math.radians(35 + k * 30)
            p0, nn = h.pt(s * (yaw + math.degrees(rx * math.cos(a) / max(0.2, h.r.x))), pitch + math.degrees(rz * math.sin(a) / max(0.2, h.r.z)), 0.03)
            d = Vector((s * math.cos(a), 0, math.sin(a))) * ln
            vtube(m, pc, [p0, p0 + d + nn * 0.03], [0.02, 0.006], seg=5, part=part, smooth=1)



