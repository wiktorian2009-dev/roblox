
import bpy, bmesh, math, random, os
import numpy as np
from mathutils import Vector, Matrix, Euler

OUT = r"C:\Users\wikto\Desktop\Roblox Gra\outputs\Eggs2026"
TEX = 1024
SV0 = 80 / TEX          # shell UVs start here; rows below hold solid colour swatches
H, R = 2.7, 1.0          # egg height / radius (Blender units)

def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))

def shell_r(z):
    zn = (z - H/2) / (H/2)
    return R * math.sqrt(max(0.0, 1 - zn*zn)) * (1 - 0.12*zn)

def link(ob):
    bpy.context.collection.objects.link(ob); return ob

def set_uv(ob, swatch):
    me = ob.data
    if not me.uv_layers: me.uv_layers.new(name="UVMap")
    u, v = (swatch + 0.5) / 16, 32 / TEX
    for d in me.uv_layers.active.data: d.uv = (u, v)
    for p in me.polygons: p.use_smooth = True

def from_bm(name, bm, swatch):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = link(bpy.data.objects.new(name, me)); set_uv(ob, swatch); return ob

def shell(name):
    bm = bmesh.new(); bm.loops.layers.uv.new("UVMap")
    bmesh.ops.create_uvsphere(bm, u_segments=64, v_segments=32, radius=1.0, calc_uvs=True)
    for v in bm.verts:
        zn = v.co.z; k = 1 - 0.12*zn
        v.co.x *= R*k; v.co.y *= R*k; v.co.z = zn*H/2 + H/2
    uvl = bm.loops.layers.uv.active
    for f in bm.faces:
        for l in f.loops:
            l[uvl].uv.y = SV0 + l[uvl].uv.y * (1 - SV0)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = link(bpy.data.objects.new(name, me))
    for p in ob.data.polygons: p.use_smooth = True
    return ob

def blob(name, loc, scale, swatch, seg=16, ring=10):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=ring, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x*scale[0], v.co.y*scale[1], v.co.z*scale[2])) + Vector(loc)
    return from_bm(name, bm, swatch)

def tube(name, pts, radii, swatch, segs=14):
    bm = bmesh.new(); rings = []; n = len(pts)
    prev_u = None
    for i, (p, r) in enumerate(zip(pts, radii)):
        p = Vector(p)
        t = (Vector(pts[min(i+1, n-1)]) - Vector(pts[max(i-1, 0)])).normalized()
        if prev_u is None:
            a = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
            u = t.cross(a).normalized()
        else:
            u = (prev_u - t * prev_u.dot(t)).normalized()
        prev_u = u; w = t.cross(u).normalized()
        rings.append([bm.verts.new(p + (u*math.cos(2*math.pi*k/segs) + w*math.sin(2*math.pi*k/segs)) * max(r, 0.004)) for k in range(segs)])
    for i in range(n - 1):
        for k in range(segs):
            bm.faces.new((rings[i][k], rings[i][(k+1) % segs], rings[i+1][(k+1) % segs], rings[i+1][k]))
    bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
    return from_bm(name, bm, swatch)

def solidify(ob, t):
    m = ob.modifiers.new("S", "SOLIDIFY"); m.thickness = t; m.offset = 0
    with bpy.context.temp_override(object=ob, active_object=ob):
        bpy.ops.object.modifier_apply(modifier=m.name)

# ---------------- texture painting ----------------
class Paint:
    def __init__(s, stops):
        s.img = np.ones((TEX, TEX, 4), dtype=np.float32)
        rows = np.arange(TEX); s.v = np.clip((rows - SV0*TEX) / (TEX - SV0*TEX), 0, 1)
        ps = [p for p, _ in stops]; cs = [hx(c) for _, c in stops]
        for ch in range(3):
            col = np.interp(s.v, ps, [c[ch] for c in cs])
            s.img[:, :, ch] = col[:, None]
        s.u = (np.arange(TEX) + 0.5) / TEX
    def swatches(s, cols):
        for i, c in enumerate(cols):
            s.img[0:64, i*64:(i+1)*64, :3] = hx(c)
    def _local(s, uc, vc, rad):
        # rows in the shell region around vc, returns row slice, dx, dy (surface units)
        LY = math.pi * 1.35
        dv = rad / LY + 0.01
        v0, v1 = max(0.0, vc - dv), min(1.0, vc + dv)
        r0 = int(SV0*TEX + v0*(TEX - SV0*TEX)); r1 = int(SV0*TEX + v1*(TEX - SV0*TEX)) + 1
        rs = slice(r0, min(r1, TEX))
        vv = s.v[rs][:, None]
        du = (s.u[None, :] - uc + 0.5) % 1.0 - 0.5
        cf = np.cos((vv - 0.5) * math.pi)
        dx = du * 2*math.pi * np.maximum(cf, 0.02) * R
        dy = (vv - vc) * LY
        return rs, dx, dy
    def blend(s, rs, a, col):
        a = np.clip(a, 0, 1)[:, :, None]; c = np.array(hx(col), dtype=np.float32)
        s.img[rs, :, :3] = s.img[rs, :, :3] * (1 - a) + c * a
    def spot(s, uc, vc, rad, col, shape="dot", rot=0.0, aspect=1.0):
        rs, dx, dy = s._local(uc, vc, rad * max(aspect, 1) * 1.2)
        if shape == "sparkle":
            d = (np.sqrt(np.abs(dx)) + np.sqrt(np.abs(dy)))**2
        else:
            cr, sr = math.cos(rot), math.sin(rot)
            x = dx*cr + dy*sr; y = -dx*sr + dy*cr
            d = np.sqrt((x/aspect)**2 + y**2)
        s.blend(rs, (rad - d) / 0.008, col)
    def scatter(s, n, rmin, rmax, col, vmin=0.08, vmax=0.95, shape="dot", seed=1, aspect=1.0, minsep=0.0):
        rng = random.Random(seed); pts = []
        tries = 0
        while len(pts) < n and tries < n*60:
            tries += 1
            z = rng.uniform(-1, 1); v = (math.asin(z) / math.pi) + 0.5
            if not (vmin <= v <= vmax): continue
            u = rng.random(); rad = rng.uniform(rmin, rmax)
            ok = True
            for (pu, pv, pr) in pts:
                du = ((u - pu + 0.5) % 1 - 0.5) * 2*math.pi * math.cos((v-0.5)*math.pi)
                if math.hypot(du, (v - pv)*math.pi*1.35) < (rad + pr + minsep): ok = False; break
            if not ok: continue
            pts.append((u, v, rad))
            s.spot(u, v, rad, col, shape, rot=rng.uniform(0, math.pi), aspect=aspect)
        return pts
    def zigzag(s, vc, amp, k, half, col):
        tri = np.abs((s.u * k) % 1.0 - 0.5) * 2 - 0.5
        line = vc + amp * tri
        d = np.abs(s.v[:, None] - line[None, :])
        a = np.clip((half - d) / 0.003, 0, 1); a[: int(SV0*TEX)] = 0
        c = np.array(hx(col), dtype=np.float32)
        s.img[:, :, :3] = s.img[:, :, :3] * (1 - a[:, :, None]) + c * a[:, :, None]
    def band(s, v0, v1, col):
        a = ((s.v >= v0) & (s.v <= v1)).astype(np.float32); a[: int(SV0*TEX)] = 0
        s.img[:, :, :3] = s.img[:, :, :3] * (1 - a[:, None, None]) + np.array(hx(col)) * a[:, None, None]
    def checker(s, v0, v1, n, rows, c1, c2):
        cell = (np.floor(s.u[None, :] * n) + np.floor((s.v[:, None] - v0) / (v1 - v0) * rows)) % 2
        inb = ((s.v >= v0) & (s.v < v1))[:, None]
        inb = np.broadcast_to(inb, cell.shape).copy(); inb[: int(SV0*TEX)] = False
        for val, col in ((0, c1), (1, c2)):
            m = (inb & (cell == val))
            s.img[m, :3] = hx(col)
    def save(s, name):
        img = bpy.data.images.get(name) or bpy.data.images.new(name, TEX, TEX, alpha=False)
        img.pixels.foreach_set(s.img.ravel())
        img.filepath_raw = os.path.join(OUT, name + ".png"); img.file_format = "PNG"; img.save()
        return img

def material(name, img, rough=0.45):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img
    bsdf.inputs["Roughness"].default_value = rough
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m

def finish(egg_id, parts, img, x):
    mat = material(egg_id + "_Mat", img)
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    ob = bpy.context.active_object; ob.name = egg_id; ob.data.name = egg_id
    ob.data.materials.clear(); ob.data.materials.append(mat)
    ob.location.x = x
    return ob
