
import bpy, bmesh, math, os, random, traceback
import numpy as np
from mathutils import Vector, Matrix, Euler

OUT = r"C:\Users\wikto\Desktop\Roblox Gra\outputs\Props2026"
NCOL, CW, ROWS = 64, 16, 128          # colour atlas: 64 colour columns x 128 shade rows (dark at the bottom, light at the top)
HEX = {}
for _n, _h in [
 ("white","F4FBFF"),("frost","DFF7FF"),("ice","BFEAFF"),("iceBlue","7FDFFF"),("deepBlue","2F8FFF"),("teal","2FB5A7"),("tealDark","1E8C86"),
 ("pink","FF7FAE"),("red","FF4D5E"),("yellow","FFD34D"),("orange","FF9A3C"),("brown","8A5A3B"),("wood","B07A45"),("coal","2B2340"),("navy","26395F"),
 ("stone","9DA3C0"),("stoneDark","6B7399"),("gold","FFC93A"),("cream","FFF3D6"),
 ("sand","F0C070"),("sandDark","D9A050"),("terra","D9683B"),("terraLight","E57A4A"),("cactus","4FBF6A"),("cactusDark","2F9A50"),("sandstone","E5B07A"),("teal2","2FC4B8"),
 ("purple","8E4DD6"),("purpleDark","4B2A7A"),("violet","B58CFF"),("ghost","F4F1FF"),("lime","8BE04A"),("pumpkin","FF8A1F"),("bone","F3EFE0"),("deadWood","5A4060"),("tomb","A09BC4"),("candle","F6E7C8"),
 ("cyan","5EE6FF"),("cyanDark","25AEE0"),("magenta","FF8AD8"),("mint","59F0C0"),("amethyst","C9A4FF"),("rockBlue","6F78AD"),
 ("leaf","35B350"),("leafDark","1E8A4A"),("leafLight","9BE14A"),("hib","FF4D6D"),("moss","5FA84A"),("bamboo","B5D86A"),("mossRock","7C8F6A"),
 ("glow","A8F0FF"),("iceDeep","4FB8FF"),("frostWhite","EAFBFF"),
 ("pxRed","FF3B5C"),("pxYellow","FFD23F"),("pxBlue","4DB8FF"),("pxGreen","5BE05C"),("pxPink","FF5EDF"),("pxPurple","8B8FD6"),("pxWhite","FFFFFF"),("pxDark","1B1240"),("pxGray","9EA3C8"),
]: HEX[_n] = _h
PAL = {n: i for i, n in enumerate(HEX)}
assert len(PAL) <= NCOL

def hx(h): return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))

_MAT = None
def make_atlas():
    global _MAT
    os.makedirs(OUT, exist_ok=True)
    arr = np.ones((ROWS, NCOL*CW, 4), np.float32); t = (np.arange(ROWS) / (ROWS-1))[:, None]
    for name, col in PAL.items():
        base = np.array(hx(HEX[name]), np.float32)
        dark = np.clip(base*np.array([0.50, 0.53, 0.72]) + np.array([0.02, 0.03, 0.10]), 0, 1); light = base + (1-base)*0.38
        c = np.where(t < 0.62, dark + (base-dark)*(t/0.62), base + (light-base)*((t-0.62)/0.38))
        arr[:, col*CW:(col+1)*CW, :3] = c[:, None, :]
    old = bpy.data.images.get("PropAtlas")
    if old: bpy.data.images.remove(old)
    img = bpy.data.images.new("PropAtlas", NCOL*CW, ROWS, alpha=False)
    img.pixels.foreach_set(arr.ravel()); img.filepath_raw = os.path.join(OUT, "PropAtlas.png"); img.file_format = "PNG"; img.save()
    m = bpy.data.materials.get("PropMat") or bpy.data.materials.new("PropMat")
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    o = nt.nodes.new("ShaderNodeOutputMaterial"); b = nt.nodes.new("ShaderNodeBsdfPrincipled"); tx = nt.nodes.new("ShaderNodeTexImage")
    tx.image = img; b.inputs["Roughness"].default_value = 0.55
    nt.links.new(tx.outputs["Color"], b.inputs["Base Color"]); nt.links.new(b.outputs["BSDF"], o.inputs["Surface"])
    _MAT = m; return img

def _M(loc, rot, sc):
    if not isinstance(sc, (tuple, list)): sc = (sc, sc, sc)
    return Matrix.Translation(loc) @ Euler(rot, "XYZ").to_matrix().to_4x4() @ Matrix.Diagonal((sc[0], sc[1], sc[2], 1.0))

class P:
    """One prop: many primitives merged into a single mesh that samples the shared colour atlas."""
    def __init__(self, name):
        self.name = name; self.bm = bmesh.new(); self.uv = self.bm.loops.layers.uv.new("UVMap"); self.recalc = True
    def _faces(self, verts):
        fs = set()
        for v in verts: fs.update(v.link_faces)
        return fs
    def _paint(self, faces, color, smooth=True, grad=(0.10, 0.95), flat=False):
        u = (PAL[color] + 0.5) / NCOL; faces = list(faces)
        zs = [l.vert.co.z for f in faces for l in f.loops]; z0, z1 = min(zs), max(zs); rng = max(z1-z0, 1e-6)
        for f in faces:
            f.smooth = smooth
            for l in f.loops:
                t = 0.55 if flat else grad[0] + (grad[1]-grad[0])*((l.vert.co.z-z0)/rng)
                l[self.uv].uv = (u, 0.03 + 0.94*t)
    def _xf(self, vs, c, rot, sc):
        M = _M(c, rot, sc)
        for v in vs: v.co = M @ v.co
    def sph(self, c=(0,0,0), r=1.0, color="white", seg=12, ring=8, smooth=True, rot=(0,0,0), **kw):
        vs = bmesh.ops.create_uvsphere(self.bm, u_segments=seg, v_segments=ring, radius=1.0)["verts"]
        self._xf(vs, c, rot, r); self._paint(self._faces(vs), color, smooth, **kw); return self
    def cyl(self, base=(0,0,0), r0=1.0, r1=None, h=1.0, color="white", seg=12, cap=True, smooth=True, rot=(0,0,0), **kw):
        r1 = r0 if r1 is None else r1
        vs = bmesh.ops.create_cone(self.bm, cap_ends=cap, cap_tris=False, segments=seg, radius1=r0, radius2=r1, depth=h)["verts"]
        if r0 < 1e-4 or r1 < 1e-4: bmesh.ops.remove_doubles(self.bm, verts=vs, dist=1e-4); vs = [v for v in vs if v.is_valid]
        M = _M(base, rot, 1.0) @ Matrix.Translation((0, 0, h/2))
        for v in vs: v.co = M @ v.co
        self._paint(self._faces(vs), color, smooth, **kw); return self
    def cone(self, base, r, h, color="white", **kw): return self.cyl(base, r, 0.0, h, color, **kw)
    def box(self, c=(0,0,0), s=(1,1,1), color="white", rot=(0,0,0), bevel=0.0, smooth=False, **kw):
        vs = bmesh.ops.create_cube(self.bm, size=1.0)["verts"]; self._xf(vs, c, rot, s); fs = self._faces(vs)
        if bevel > 0:
            es = list({e for v in vs for e in v.link_edges})
            res = bmesh.ops.bevel(self.bm, geom=es, offset=bevel, segments=2, affect="EDGES")
            fs = self._faces({v for f in res["faces"] for v in f.verts} | {v for v in vs if v.is_valid})
        self._paint(fs, color, smooth, **kw); return self
    def ico(self, c=(0,0,0), r=1.0, color="stone", sub=2, noise=0.0, seed=0, smooth=False, rot=(0,0,0), **kw):
        vs = bmesh.ops.create_icosphere(self.bm, subdivisions=sub, radius=1.0)["verts"]; rs = random.Random(seed); ph = [rs.uniform(0, 6.28) for _ in range(6)]
        for v in vs:
            p = v.co; n = math.sin(p.x*2.3+ph[0])*math.sin(p.y*2.1+ph[1])*math.sin(p.z*2.6+ph[2]) + 0.5*math.sin(p.x*4.7+ph[3])*math.cos(p.y*4.1+ph[4])
            v.co = p*(1 + noise*n)
        self._xf(vs, c, rot, r); self._paint(self._faces(vs), color, smooth, **kw); return self
    def sweep(self, pts, widths, color="wood", seg=8, uhint=None, smooth=True, cap=True, closed=False, **kw):
        """Tube / leaf blade along a path. widths: radius or (wide, thin) per point. uhint: direction the wide axis should follow."""
        n = len(pts); Pt = [Vector(p) for p in pts]; rings = []; prev = None
        for i in range(n):
            t = (Pt[(i+1) % n] - Pt[(i-1) % n]) if closed else (Pt[min(i+1, n-1)] - Pt[max(i-1, 0)])
            t = t.normalized() if t.length > 1e-9 else Vector((0, 0, 1))
            if uhint is not None:
                hv = Vector(uhint); u = hv - t*hv.dot(t)
                if u.length < 1e-4: u = Vector((1, 0, 0)) - t*t.x
            elif prev is None:
                a = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0)); u = t.cross(a)
            else: u = prev - t*prev.dot(t)
            u = u.normalized(); prev = u; w = t.cross(u).normalized()
            wd = widths[i]; wu, ww = (wd if isinstance(wd, (tuple, list)) else (wd, wd))
            rings.append([self.bm.verts.new(Pt[i] + u*(math.cos(2*math.pi*k/seg)*max(wu, 0.004)) + w*(math.sin(2*math.pi*k/seg)*max(ww, 0.004))) for k in range(seg)])
        fs = []
        for i in range((n if closed else n-1)):
            a, b = rings[i], rings[(i+1) % n]
            for k in range(seg): fs.append(self.bm.faces.new((a[k], a[(k+1) % seg], b[(k+1) % seg], b[k])))
        if cap and not closed: fs.append(self.bm.faces.new(list(reversed(rings[0])))); fs.append(self.bm.faces.new(rings[-1]))
        self._paint(fs, color, smooth, **kw); return self
    def lathe(self, prof, color="white", seg=16, smooth=True, c=(0,0,0), rot=(0,0,0), sc=1.0, rmod=None, zmod=None, colors=None, **kw):
        """Revolve a (radius, height) profile, bottom to top. colors: optional colour per profile segment."""
        rings = []
        for i, (r, z) in enumerate(prof):
            if r < 1e-4: rings.append([self.bm.verts.new((0, 0, z))])
            else:
                ring = []
                for k in range(seg):
                    th = 2*math.pi*k/seg; rr = r*(rmod(th, i) if rmod else 1.0); zz = z + (zmod(th, i) if zmod else 0.0)
                    ring.append(self.bm.verts.new((rr*math.cos(th), rr*math.sin(th), zz)))
                rings.append(ring)
        segfaces = []
        for i in range(len(prof)-1):
            a, b = rings[i], rings[i+1]; fl = []
            for k in range(seg):
                k2 = (k+1) % seg
                if len(a) > 1 and len(b) > 1: fl.append(self.bm.faces.new((a[k], a[k2], b[k2], b[k])))
                elif len(a) == 1 and len(b) > 1: fl.append(self.bm.faces.new((a[0], b[k2], b[k])))
                elif len(a) > 1 and len(b) == 1: fl.append(self.bm.faces.new((a[k], a[k2], b[0])))
            segfaces.append(fl)
        caps = []
        if len(rings[0]) > 1: caps.append(self.bm.faces.new(list(reversed(rings[0]))))
        if len(rings[-1]) > 1: caps.append(self.bm.faces.new(rings[-1]))
        allv = [v for r_ in rings for v in r_]; self._xf(allv, c, rot, sc)
        if colors:
            for fl, col in zip(segfaces, colors): self._paint(fl, col, smooth, **kw)
            if caps: self._paint(caps, colors[-1], smooth, **kw)
        else: self._paint([f for fl in segfaces for f in fl] + caps, color, smooth, **kw)
        return self
    def vox(self, cells, cell=0.5, origin=(0,0,0), tone=True):
        """cells {(x,y,z): colour}; only exposed faces are built. Top faces are lit, sides mid, bottoms dark."""
        self.recalc = False
        D = [((1,0,0), [(1,0,0),(1,1,0),(1,1,1),(1,0,1)], 0.52), ((-1,0,0), [(0,1,0),(0,0,0),(0,0,1),(0,1,1)], 0.42), ((0,1,0), [(1,1,0),(0,1,0),(0,1,1),(1,1,1)], 0.48),
             ((0,-1,0), [(0,0,0),(1,0,0),(1,0,1),(0,0,1)], 0.60), ((0,0,1), [(0,0,1),(1,0,1),(1,1,1),(0,1,1)], 0.90), ((0,0,-1), [(0,1,0),(1,1,0),(1,0,0),(0,0,0)], 0.15)]
        for (x, y, z), col in cells.items():
            u = (PAL[col] + 0.5) / NCOL
            for d, q, tv in D:
                if (x+d[0], y+d[1], z+d[2]) in cells: continue
                vs = [self.bm.verts.new((origin[0] + (x+a)*cell, origin[1] + (y+b)*cell, origin[2] + (z+c_)*cell)) for a, b, c_ in q]
                f = self.bm.faces.new(vs); f.smooth = False
                for l in f.loops: l[self.uv].uv = (u, 0.03 + 0.94*(tv if tone else 0.55))
        return self
    def finish(self, loc=(0,0,0)):
        if self.recalc: bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        me = bpy.data.meshes.new(self.name); self.bm.to_mesh(me); self.bm.free()
        ob = bpy.data.objects.new(self.name, me); bpy.context.collection.objects.link(ob)
        ob.data.materials.append(_MAT); ob.location = loc; ob["tris"] = sum(len(p.vertices)-2 for p in me.polygons); return ob

def clear_scene():
    for ob in list(bpy.data.objects): bpy.data.objects.remove(ob, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0: bpy.data.meshes.remove(me)

def row(objs, spacing, y=0.0, cols=None):
    cols = cols or len(objs)
    for i, o in enumerate(objs): o.location = ((i % cols)*spacing, y - (i//cols)*spacing, 0)

def show(center=(0,0,3), dist=60, yaw=-28, pitch=26):
    for win in bpy.context.window_manager.windows:
        for area in win.screen.areas:
            if area.type == "VIEW_3D":
                sp = area.spaces.active; sh = sp.shading; sh.type = "SOLID"; sh.light = "STUDIO"; sh.color_type = "TEXTURE"
                try: sp.overlay.show_overlays = False; sp.show_gizmo = False
                except Exception: pass
                r3 = sp.region_3d; r3.view_perspective = "PERSP"; r3.view_location = center; r3.view_distance = dist
                r3.view_rotation = Euler((math.radians(90 - pitch), 0, math.radians(yaw)), "XYZ").to_quaternion(); return True
    return False

def export_fbx(objs, name):
    # global_scale=0.01: Blender's FBX export writes centimetres (x100) and Roblox reads 1 FBX unit as 1 stud -> without it props import 100x too big (seen 2026-09-30)
    path = os.path.join(OUT, name)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"}, global_scale=0.01, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE",
        axis_forward="-Z", axis_up="Y", bake_space_transform=True, path_mode="COPY", embed_textures=True, mesh_smooth_type="OFF", use_mesh_modifiers=True, add_leaf_bones=False, bake_anim=False)
    return path

def build(builders):
    res = []
    for f in builders:
        try: res.append(f())
        except Exception: tb = traceback.format_exc().splitlines(); print("FAILED", f.__name__, "->", tb[-1], "|", [l.strip() for l in tb if "props_" in l][-1:])
    return res
