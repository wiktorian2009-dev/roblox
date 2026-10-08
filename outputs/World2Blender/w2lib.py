# w2lib.py - World 2 Blender model kit (Claude, 2026-10-02)
# 1 Blender unit = 1 stud (FBX export global_scale=0.01 undoes FBX centimetres; verified pipeline from Props2026).
# Model front = Blender -Y (Roblox -Z). Up = +Z (Roblox +Y). Every object origin = its model's bottom-centre origin.
# Object name: <Model>__<Part>__<RRGGBB><MAT>[T<nn>]  e.g. Lantern__Glow__FFD27ANE  -> Studio post-process applies colour/material,
# renames the part to <Part> and regroups parts by <Model>. MAT codes in MATS.
import bpy, bmesh, math, random, json, os, time, uuid, urllib.request, urllib.error
from mathutils import Vector, Matrix, Euler

ROOT = r"C:\Users\wikto\Desktop\Roblox Gra"
OUT = os.path.join(ROOT, "outputs", "World2Blender")
MATS = {"SP":"SmoothPlastic","NE":"Neon","GL":"Glass","ME":"Metal","FO":"Foil","WO":"Wood","IC":"Ice","SA":"Sand",
        "GR":"Grass","CO":"Concrete","PL":"Plastic","MA":"Marble","SL":"Slate","FA":"Fabric","PE":"Pebble","BR":"Brick",
        "CB":"Cobblestone","GN":"Granite","WP":"WoodPlanks","SN":"Snow","LI":"Limestone","SS":"Sandstone","RO":"Rock"}
CREATOR_USER_ID = "200458631"

def P(hexrgb, mat="SP", t=0.0):
    c = hexrgb.upper().lstrip("#") + mat
    if t: c += "T%02d" % int(round(t * 100))
    return c

def Mx(loc=(0,0,0), rot=(0,0,0), scl=1):
    if isinstance(scl, (int, float)): scl = (scl, scl, scl)
    return (Matrix.Translation(Vector(loc)) @ Euler([math.radians(a) for a in rot], 'XYZ').to_matrix().to_4x4()
            @ Matrix.Diagonal((scl[0], scl[1], scl[2], 1.0)))

class Model:
    def __init__(self, name, at=(0,0,0), **meta):
        self.name, self.at, self.parts, self.order, self.sharp, self.meta = name, Vector(at), {}, [], {}, meta
    def bm(self, part, pc):
        k = part + "__" + pc
        b = self.parts.get(k)
        if b is None:
            b = bmesh.new(); self.parts[k] = b; self.order.append(k)
        return b
    def flat(self, part, pc, angle=1):   # faceted look for this part (rocks)
        self.sharp[part + "__" + pc] = angle

def _merge(dst, src):
    vm = {v: dst.verts.new(v.co) for v in src.verts}
    for f in src.faces:
        try: dst.faces.new([vm[v] for v in f.verts])
        except ValueError: pass
    src.free()

def _put(m, part, pc, tb, mat):
    bmesh.ops.transform(tb, matrix=mat, verts=tb.verts)
    _merge(m.bm(part, pc), tb)

def sphere(m, pc, loc=(0,0,0), r=1.0, scl=1, rot=(0,0,0), seg=None, rings=None, part="Main"):
    if seg is None:
        k = r * (max(scl) if isinstance(scl, (tuple, list)) else scl)
        seg = max(6, min(18, int(5 + k * 3.2)))
    if rings is None: rings = max(4, int(seg * 0.6))
    tb = bmesh.new(); bmesh.ops.create_uvsphere(tb, u_segments=seg, v_segments=rings, radius=r)
    _put(m, part, pc, tb, Mx(loc, rot, scl))

def rbox(m, pc, loc=(0,0,0), size=(1,1,1), r=0.15, bseg=2, rot=(0,0,0), part="Main", base=False):
    tb = bmesh.new(); bmesh.ops.create_cube(tb, size=1.0)
    bmesh.ops.scale(tb, vec=Vector(size), verts=tb.verts)
    if base: bmesh.ops.translate(tb, vec=(0, 0, size[2] / 2), verts=tb.verts)
    r = min(r, min(size) * 0.49)
    if r > 0.001: bmesh.ops.bevel(tb, geom=list(tb.edges), offset=r, segments=bseg, affect='EDGES', profile=0.5, clamp_overlap=True)
    _put(m, part, pc, tb, Mx(loc, rot))

def cyl(m, pc, loc=(0,0,0), r=1.0, h=1.0, r2=None, seg=16, rot=(0,0,0), scl=1, bev=0.0, bseg=2, part="Main", cap=True):
    tb = bmesh.new()
    bmesh.ops.create_cone(tb, cap_ends=cap, cap_tris=False, segments=seg, radius1=r, radius2=(r if r2 is None else max(r2, 0.001)), depth=h)
    bmesh.ops.translate(tb, vec=(0, 0, h / 2), verts=tb.verts)
    if bev > 0 and cap:
        es = [e for e in tb.edges if any(len(f.verts) > 4 for f in e.link_faces)]
        bmesh.ops.bevel(tb, geom=es, offset=min(bev, r * 0.45, h * 0.45), segments=bseg, affect='EDGES', profile=0.5, clamp_overlap=True)
    _put(m, part, pc, tb, Mx(loc, rot, scl))

def lathe(m, pc, prof, loc=(0,0,0), seg=20, rot=(0,0,0), scl=1, part="Main", sx=1.0, sy=1.0, wob=0.0, seed=0, rib=None):
    """prof = [(radius, z), ...] bottom->top; radius 0 = pole. Caps added for non-zero end rings."""
    tb = bmesh.new(); rings = []; rnd = random.Random(seed)
    for (r, z) in prof:
        if r <= 1e-6: rings.append([tb.verts.new((0, 0, z))])
        else:
            ring = []
            for i in range(seg):
                a = 2 * math.pi * i / seg; k = 1 + (rnd.uniform(-wob, wob) if wob else 0) + (rib[1] * math.cos(rib[0] * a) if rib else 0)
                ring.append(tb.verts.new((r * k * math.cos(a) * sx, r * k * math.sin(a) * sy, z)))
            rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        if len(a) == 1 and len(b) == 1: continue
        for i in range(seg):
            j = (i + 1) % seg
            if len(a) == 1: tb.faces.new((a[0], b[i], b[j]))
            elif len(b) == 1: tb.faces.new((a[i], a[j], b[0]))
            else: tb.faces.new((a[i], a[j], b[j], b[i]))
    if len(rings[0]) > 1: tb.faces.new(list(reversed(rings[0])))
    if len(rings[-1]) > 1: tb.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _put(m, part, pc, tb, Mx(loc, rot, scl))

def _catmull(P, n, closed):
    out = []; L = len(P)
    rng = range(L) if closed else range(L - 1)
    for i in rng:
        p0 = P[(i - 1) % L] if closed else P[max(i - 1, 0)]
        p1 = P[i]; p2 = P[(i + 1) % L]
        p3 = P[(i + 2) % L] if closed else P[min(i + 2, L - 1)]
        for k in range(n):
            t = k / n; t2 = t * t; t3 = t2 * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    if not closed: out.append(P[-1])
    return out

def tube(m, pc, pts, r=0.3, seg=10, part="Main", r2=None, closed=False, smooth=4, cap=True, phase=0.0, sq=1.0):
    P = [Vector(p) for p in pts]
    if smooth > 1 and len(P) > 2: P = _catmull(P, smooth, closed)
    n = len(P); tb = bmesh.new(); rings = []
    T = []
    for i in range(n):
        if closed: t = P[(i + 1) % n] - P[(i - 1) % n]
        else: t = P[min(i + 1, n - 1)] - P[max(i - 1, 0)]
        T.append(t.normalized() if t.length > 1e-9 else Vector((0, 0, 1)))
    up = Vector((0, 0, 1)) if abs(T[0].z) < 0.95 else Vector((1, 0, 0))
    N = (up - T[0] * up.dot(T[0])).normalized()
    for i in range(n):
        if i > 0:
            N = N - T[i] * N.dot(T[i])
            N = N.normalized() if N.length > 1e-9 else N
        B = T[i].cross(N)
        rr = r if r2 is None else r + (r2 - r) * (i / max(1, n - 1))
        ring = []
        for k in range(seg):
            a = 2 * math.pi * k / seg + phase
            ring.append(tb.verts.new(P[i] + (N * math.cos(a) * sq + B * math.sin(a)) * rr))
        rings.append(ring)
    pairs = list(zip(rings, rings[1:]))
    if closed: pairs.append((rings[-1], rings[0]))
    for a, b in pairs:
        for k in range(seg):
            j = (k + 1) % seg
            tb.faces.new((a[k], a[j], b[j], b[k]))
    if cap and not closed:
        tb.faces.new(list(reversed(rings[0]))); tb.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _merge(m.bm(part, pc), tb)

def torus(m, pc, loc=(0,0,0), R=2.0, r=0.4, seg=24, rseg=10, rot=(0,0,0), arc=360, part="Main", sq=1.0, phase=0.0):
    full = arc >= 359.9
    cnt = seg if full else seg + 1
    pts = []
    for i in range(cnt):
        a = math.radians(arc) * i / seg
        p = Mx(loc, rot) @ Vector((R * math.cos(a), R * math.sin(a), 0))
        pts.append(p)
    tube(m, pc, pts, r=r, seg=rseg, part=part, closed=full, smooth=1, phase=phase, sq=sq)

def prism(m, pc, poly, depth, loc=(0,0,0), rot=(0,0,0), scl=1, part="Main", bev=0.0, bseg=2):
    """poly: 2-D outline in the XY plane (CCW). Extruded along +Z by depth."""
    tb = bmesh.new(); vs = [tb.verts.new((x, y, 0)) for x, y in poly]; f = tb.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(tb, geom=[f])
    nv = [e for e in ext['geom'] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(tb, vec=(0, 0, depth), verts=nv)
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    if bev > 0:
        es = [e for e in tb.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(40)]
        bmesh.ops.bevel(tb, geom=es, offset=bev, segments=bseg, affect='EDGES', profile=0.5, clamp_overlap=True)
    bmesh.ops.triangulate(tb, faces=tb.faces[:], quad_method='BEAUTY', ngon_method='BEAUTY')
    _put(m, part, pc, tb, Mx(loc, rot, scl))

def rock(m, pc, loc=(0,0,0), size=(2,2,1.5), seed=0, sub=2, jag=0.16, rot=(0,0,0), part="Main", flatz=None):
    tb = bmesh.new(); bmesh.ops.create_icosphere(tb, subdivisions=sub, radius=1.0); rnd = random.Random(seed)
    for v in tb.verts:
        k = 1 + rnd.uniform(-jag, jag)
        v.co = Vector((v.co.x * k * size[0], v.co.y * k * size[1], v.co.z * k * size[2]))
        if flatz is not None and v.co.z < flatz: v.co.z = flatz
    _put(m, part, pc, tb, Mx(loc, rot))

def island(m, pc, loc=(0,0,0), rx=60.0, ry=25.0, depth=40.0, seed=0, seg=32, rings=7, jag=0.13, part="Under", lip=1.5, tip=(0.0, 0.0)):
    """Downward rocky cone under a floating stage. Top ring at z=0 (radius rx/ry), tip at z=-depth."""
    rnd = random.Random(seed); prof = []
    tb = bmesh.new(); rr = []
    for k in range(rings + 1):
        t = k / rings
        z = -depth * (t ** 1.15) + (lip if k == 0 else 0)
        f = (1 - t) ** 0.8 if k < rings else 0
        if k == rings:
            rr.append([tb.verts.new((loc[0] + tip[0], loc[1] + tip[1], loc[2] - depth))]); continue
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            n = 1 + rnd.uniform(-jag, jag) * (0.4 if k == 0 else 1)
            ring.append(tb.verts.new((loc[0] + math.cos(a) * rx * f * n + tip[0] * t, loc[1] + math.sin(a) * ry * f * n + tip[1] * t, loc[2] + z + rnd.uniform(-1, 1) * depth * 0.03 * (k > 0))))
        rr.append(ring)
    for a, b in zip(rr, rr[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            if len(b) == 1: tb.faces.new((a[i], a[j], b[0]))
            else: tb.faces.new((a[i], a[j], b[j], b[i]))
    tb.faces.new(rr[0])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _merge(m.bm(part, pc), tb)

def blob(m, pc, loc=(0,0,0), rad=3.0, n=5, seed=0, spread=(1.0, 1.0, 0.45), flat=0.8, seg=None, rings=None, part="Main", shrink=(0.45, 0.8)):
    rnd = random.Random(seed); cx, cy, cz = loc
    sphere(m, pc, loc, rad, scl=(1, 1, flat), seg=seg, rings=rings, part=part)
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi); d = rnd.uniform(0.45, 0.85) * rad
        rr = rad * rnd.uniform(*shrink)
        sphere(m, pc, (cx + math.cos(a) * d * spread[0], cy + math.sin(a) * d * spread[1], cz + rnd.uniform(-0.2, 1.0) * rad * spread[2]), rr,
               scl=(1, 1, flat), seg=(None if seg is None else max(6, seg - 2)), rings=(None if rings is None else max(4, rings - 2)), part=part)

def srgb2lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def pmat(code):
    mat = bpy.data.materials.get("P_" + code)
    if mat: return mat
    mat = bpy.data.materials.new("P_" + code); mat.use_nodes = True
    rgb = [srgb2lin(int(code[i:i + 2], 16) / 255) for i in (0, 2, 4)]
    b = mat.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1); b.inputs["Roughness"].default_value = 0.55
    if code[6:8] == "NE":
        b.inputs["Emission Color"].default_value = (*rgb, 1); b.inputs["Emission Strength"].default_value = 2.5
    if code[6:8] in ("ME", "FO"): b.inputs["Metallic"].default_value = 0.6; b.inputs["Roughness"].default_value = 0.3
    if "T" in code[8:]:
        a = 1 - int(code[code.index("T", 8) + 1:]) / 100
        b.inputs["Alpha"].default_value = a
    mat.diffuse_color = (*rgb, 1)
    return mat

def collection(name):
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(col)
    return col

def clear_collection(name):
    col = bpy.data.collections.get(name)
    if not col: return
    for o in list(col.objects):
        me = o.data; bpy.data.objects.remove(o, do_unlink=True)
        if me and me.users == 0: bpy.data.meshes.remove(me)

def realize(models, coll):
    clear_collection(coll); col = collection(coll); objs = []
    for m in models:
        for key in m.order:
            b = m.parts[key]
            bmesh.ops.remove_doubles(b, verts=b.verts, dist=1e-4)
            me = bpy.data.meshes.new(m.name + "__" + key); b.to_mesh(me); b.free()
            me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
            try: me.set_sharp_from_angle(angle=math.radians(m.sharp.get(key, 38)))
            except Exception: pass
            me.materials.append(pmat(key.split("__")[1]))
            ob = bpy.data.objects.new(me.name, me); col.objects.link(ob); ob.location = m.at
            ob["w2model"] = m.name; objs.append(ob)
        m.parts = {}
    return objs

def export_fbx(objs, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"}, global_scale=0.01, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_NONE", axis_forward="-Z", axis_up="Y", bake_space_transform=True, path_mode="AUTO",
        embed_textures=False, mesh_smooth_type="OFF", use_mesh_modifiers=True, add_leaf_bones=False, bake_anim=False)
    return path

def stats(objs):
    """Per-model bounding box (relative to the model origin), triangle count and parts."""
    res = {}
    for o in objs:
        me = o.data; mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
        for v in me.vertices:
            mn = Vector(map(min, mn, v.co)); mx = Vector(map(max, mx, v.co))
        tris = sum(len(p.vertices) - 2 for p in me.polygons)
        r = res.setdefault(o["w2model"], {"min": [1e9] * 3, "max": [-1e9] * 3, "tris": 0, "parts": [], "origin": list(o.location)})
        r["min"] = [min(a, b) for a, b in zip(r["min"], mn)]; r["max"] = [max(a, b) for a, b in zip(r["max"], mx)]
        r["tris"] += tris; r["parts"].append(o.name.split("__", 1)[1])
    for k, r in res.items():
        r["size"] = [round(b - a, 2) for a, b in zip(r["min"], r["max"])]
        r["min"] = [round(x, 2) for x in r["min"]]; r["max"] = [round(x, 2) for x in r["max"]]
    return res

def save_blend(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path, copy=True)

def _key():
    k = os.environ.get("ROBLOX_API_KEY")
    if not k: raise RuntimeError("ROBLOX_API_KEY is not set in Blender's environment")
    return k

def upload_model(path, display, desc):
    """Open Cloud Assets API: upload an FBX as a Model asset owned by the place owner. Never prints the key."""
    bnd = "----W2" + uuid.uuid4().hex; CR = b"\r\n"
    req = json.dumps({"assetType": "Model", "displayName": display[:50], "description": desc[:1000],
                      "creationContext": {"creator": {"userId": CREATOR_USER_ID}}}).encode()
    data = open(path, "rb").read()
    body = (b"--" + bnd.encode() + CR + b'Content-Disposition: form-data; name="request"' + CR + b"Content-Type: application/json" + CR + CR + req + CR +
            b"--" + bnd.encode() + CR + ('Content-Disposition: form-data; name="fileContent"; filename="%s"' % os.path.basename(path)).encode() + CR +
            b"Content-Type: model/fbx" + CR + CR + data + CR + b"--" + bnd.encode() + b"--" + CR)
    r = urllib.request.Request("https://apis.roblox.com/assets/v1/assets", data=body, method="POST",
                               headers={"x-api-key": _key(), "Content-Type": "multipart/form-data; boundary=" + bnd})
    try: return json.loads(urllib.request.urlopen(r, timeout=180).read())
    except urllib.error.HTTPError as e: return {"error": e.code, "body": e.read().decode("utf-8", "replace")[:600]}

def poll(op, tries=25, wait=2.0):
    oid = op.get("operationId") or op.get("path", "").split("/")[-1]
    for i in range(tries):
        if op.get("done"): return op
        time.sleep(wait)
        r = urllib.request.Request("https://apis.roblox.com/assets/v1/operations/" + oid, headers={"x-api-key": _key()})
        try: op = json.loads(urllib.request.urlopen(r, timeout=60).read())
        except urllib.error.HTTPError as e: return {"error": e.code, "body": e.read().decode("utf-8", "replace")[:600], "operationId": oid}
    op["operationId"] = oid
    return op

def registry_add(entry):
    p = os.path.join(OUT, "asset-registry.json")
    reg = json.load(open(p, encoding="utf-8")) if os.path.exists(p) else []
    reg.append(entry); json.dump(reg, open(p, "w", encoding="utf-8"), indent=1)


def se_point(a, b, ang, n=2.0):
    """Point on a superellipse |x/a|^n + |y/b|^n = 1 (n=2 ellipse, n=4 rounded rectangle)."""
    c, si = math.cos(ang), math.sin(ang)
    return (a * math.copysign(abs(c) ** (2 / n), c), b * math.copysign(abs(si) ** (2 / n), si))

def island_se(m, pc, loc=(0,0,0), a=150.0, b=62.0, depth=70.0, n=4.0, seed=0, seg=48, rings=7, jag=0.12, part="Under", top=-0.6, tip=(0.0, 0.0)):
    rnd = random.Random(seed); tb = bmesh.new(); rr = []
    for k in range(rings + 1):
        t = k / rings
        if k == rings:
            rr.append([tb.verts.new((loc[0] + tip[0], loc[1] + tip[1], loc[2] + top - depth))]); break
        f = (1 - t) ** 0.75; ring = []
        for i in range(seg):
            x, y = se_point(a, b, 2 * math.pi * i / seg, n if k == 0 else max(2.0, n - k * 0.6))
            q = 1 + rnd.uniform(-jag, jag) * (0.25 if k == 0 else 1.0)
            ring.append(tb.verts.new((loc[0] + x * f * q + tip[0] * t, loc[1] + y * f * q + tip[1] * t,
                                      loc[2] + top - depth * (t ** 1.2) + (rnd.uniform(-1, 1) * depth * 0.035 if k else 0))))
        rr.append(ring)
    for A, B in zip(rr, rr[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            if len(B) == 1: tb.faces.new((A[i], A[j], B[0]))
            else: tb.faces.new((A[i], A[j], B[j], B[i]))
    tb.faces.new(rr[0]); bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _merge(m.bm(part, pc), tb)

def turf_se(m, pc, loc=(0,0,0), a=150.0, b=62.0, n=4.0, thick=0.6, seg=48, part="Turf", top=-0.3):
    poly = [se_point(a, b, 2 * math.pi * i / seg, n) for i in range(seg)]
    prism(m, pc, poly, thick, loc=(loc[0], loc[1], loc[2] + top - thick), part=part)

def clamp_z(m, part, pc, zmin=0.0):
    for v in m.bm(part, pc).verts:
        if v.co.z < zmin: v.co.z = zmin


def flower_poly(r, petals=5, per=6):
    n = petals * per; out = []
    for i in range(n):
        a = 2 * math.pi * i / n; k = abs(math.cos(petals * a / 2))
        out.append((math.cos(a) * r * (0.42 + 0.58 * k), math.sin(a) * r * (0.42 + 0.58 * k)))
    return out

def flower(m, pc, center_pc, loc, r, rot=(0,0,0), part="Flowers", petals=5):
    """Flat cartoon blossom facing +Z (rotate with rot), with a round centre."""
    prism(m, pc, flower_poly(r, petals), r * 0.22, loc=loc, rot=rot, part=part)
    sphere(m, center_pc, Mx(loc, rot) @ Vector((0, 0, r * 0.24)), r * 0.25, part="Centers")


def stripes(m, pcs, pts, r, seglen=1.2, seg=10, part="Stripes", smooth=4):
    """Striped tube (candy canes): alternates paints pcs along the path every seglen studs."""
    P = [Vector(p) for p in pts]
    if smooth > 1 and len(P) > 2: P = _catmull(P, smooth, False)
    dense = [P[0]]
    for a, b in zip(P, P[1:]):
        n = max(1, int((b - a).length / 0.25))
        for k in range(1, n + 1): dense.append(a.lerp(b, k / n))
    chunk, acc, idx = [dense[0]], 0.0, 0
    for a, b in zip(dense, dense[1:]):
        chunk.append(b); acc += (b - a).length
        if acc >= seglen:
            tube(m, pcs[idx % len(pcs)], chunk, r=r, seg=seg, part=part + str(idx % len(pcs)), smooth=1)
            chunk, acc, idx = [b], 0.0, idx + 1
    if len(chunk) > 1: tube(m, pcs[idx % len(pcs)], chunk, r=r, seg=seg, part=part + str(idx % len(pcs)), smooth=1)

def heart_poly(s, n=28):
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        out.append((s * 16 * math.sin(t) ** 3 / 16, s * (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 16))
    return out
