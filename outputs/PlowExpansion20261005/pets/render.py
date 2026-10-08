# render.py - EEVEE preview renders + numpy sheet compositing for the pet set (Claude, 2026-10-05).
import bpy, math, os, colorsys
import numpy as np
from mathutils import Vector
from w2lib import srgb2lin
from petkit import role_of

BG = (0.80, 0.84, 0.90)          # sheet background (sRGB) = light grey-blue
TILE_W, TILE_H, ORTHO = 320, 400, 4.9
GOLD = {"Body": "FFC837", "Belly": "FFECA0", "Mark": "C98A1E", "Accent": "FFAE2E"}

def _mat(name, kind):
    m = bpy.data.materials.get(name)
    if m: return m
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    oi = nt.nodes.new("ShaderNodeObjectInfo")
    nt.links.new(oi.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.5
    if kind == "NE":
        nt.links.new(oi.outputs["Color"], b.inputs["Emission Color"]); b.inputs["Emission Strength"].default_value = 1.6
    if kind == "ME":
        b.inputs["Metallic"].default_value = 0.45; b.inputs["Roughness"].default_value = 0.32
    if kind == "T":
        nt.links.new(oi.outputs["Alpha"], b.inputs["Alpha"])
        try: m.surface_render_method = "BLENDED"
        except Exception: pass
    return m

def code_parts(code):
    hexc, mat = code[:6], code[6:8]
    t = int(code[code.index("T", 8) + 1:]) / 100 if "T" in code[8:] else 0.0
    return hexc, mat, t

def setup():
    sc = bpy.context.scene
    try: sc.render.engine = "BLENDER_EEVEE"
    except TypeError: sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.render.film_transparent = True
    sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = TILE_W, TILE_H, 100
    sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
    try: sc.view_settings.view_transform = "Standard"
    except Exception: pass
    try: sc.eevee.taa_render_samples = 24
    except Exception: pass
    w = bpy.data.worlds.new("PetWorld"); sc.world = w; w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.55, 0.62, 0.74, 1); bg.inputs["Strength"].default_value = 0.6
    ld = bpy.data.lights.new("PetSun", "SUN"); ld.energy = 2.9; ld.angle = math.radians(28)
    sun = bpy.data.objects.new("PetSun", ld); sc.collection.objects.link(sun); sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
    cd = bpy.data.cameras.new("PetCam"); cd.type = "ORTHO"; cd.ortho_scale = ORTHO
    cam = bpy.data.objects.new("PetCam", cd); sc.collection.objects.link(cam); sc.camera = cam
    # label rig, far away from the pets
    td = bpy.data.curves.new("PetLabel", "FONT"); td.align_x = "CENTER"; td.align_y = "CENTER"; td.size = 0.3
    txt = bpy.data.objects.new("PetLabel", td); sc.collection.objects.link(txt); txt.location = (0, 0, -200); txt.rotation_euler = (math.radians(90), 0, 0)
    tm = bpy.data.materials.new("LabelMat"); tm.use_nodes = True
    tb = next(n for n in tm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    tb.inputs["Base Color"].default_value = (0, 0, 0, 1); tb.inputs["Emission Color"].default_value = (0.012, 0.016, 0.03, 1)
    tb.inputs["Emission Strength"].default_value = 1.0
    td.materials.append(tm); txt.hide_render = True
    return cam, txt

def assign_render_colors(objs, golden=False):
    for o in objs:
        code = o["pc"]; hexc, mat, t = code_parts(code)
        if golden:
            role = role_of(o["part"])
            if role in GOLD:
                if role == "Accent":
                    r, g, b = [int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4)]
                    hh, ss, vv = colorsys.rgb_to_hsv(r, g, b)
                    if not (0.09 <= hh <= 0.16 and ss > 0.45 and vv > 0.6): hexc = GOLD["Accent"]
                else: hexc = GOLD[role]
        rgb = [srgb2lin(int(hexc[i:i + 2], 16) / 255) for i in (0, 2, 4)]
        o.color = (*rgb, 1 - t)
        kind = "NE" if mat == "NE" else ("T" if t > 0 else ("ME" if mat in ("ME", "FO") else "SP"))
        slot = o.material_slots[0]; slot.link = "OBJECT"; slot.material = _mat("R_" + kind, kind)

def restore_materials(objs):
    for o in objs:
        slot = o.material_slots[0]; slot.material = None; slot.link = "DATA"

def aim(cam, target, az=30, el=16, dist=30):
    a, e = math.radians(az), math.radians(el)
    t = Vector(target)
    cam.location = t + Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))) * dist
    cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()

def render_tile(cam, target, path, az=30, el=16):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = TILE_W, TILE_H; cam.data.ortho_scale = ORTHO
    aim(cam, target, az, el); sc.render.filepath = path
    bpy.ops.render.render(write_still=True)

def render_label(cam, txt, name, path):
    sc = bpy.context.scene
    txt.data.body = name; txt.hide_render = False
    sc.render.resolution_x, sc.render.resolution_y = TILE_W, 44
    cam.data.ortho_scale = 3.2
    cam.location = Vector((0, -10, -200)); cam.rotation_euler = (math.radians(90), 0, 0)
    sc.render.filepath = path; bpy.ops.render.render(write_still=True)
    txt.hide_render = True

# ---------------------------------------------------------------- compositing
def load(path):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size; a = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(a)
    bpy.data.images.remove(img)
    return a.reshape(h, w, 4)[::-1].copy()   # top-down rows

def over(dst, src, x, y, bg=None):
    h, w = src.shape[:2]; al = src[..., 3:4]
    region = dst[y:y + h, x:x + w, :3]
    dst[y:y + h, x:x + w, :3] = src[..., :3] * al + region * (1 - al)

def canvas(w, h, col=BG):
    c = np.zeros((h, w, 4), dtype=np.float32); c[..., :3] = col; c[..., 3] = 1; return c

def save(arr, path):
    h, w = arr.shape[:2]
    img = bpy.data.images.new(os.path.basename(path), w, h, alpha=False)
    img.pixels.foreach_set(np.ascontiguousarray(arr[::-1]).ravel())
    img.filepath_raw = path; img.file_format = "PNG"; img.save(); bpy.data.images.remove(img)

def resize(arr, W, H):
    """Area-average resize via integral image (premultiplied alpha)."""
    h, w = arr.shape[:2]; a = arr.copy(); a[..., :3] *= a[..., 3:4]
    I = np.zeros((h + 1, w + 1, 4), dtype=np.float64); I[1:, 1:] = a.cumsum(0).cumsum(1)
    ys = np.linspace(0, h, H + 1); xs = np.linspace(0, w, W + 1)
    y0 = np.floor(ys[:-1]).astype(int); y1 = np.maximum(y0 + 1, np.floor(ys[1:]).astype(int))
    x0 = np.floor(xs[:-1]).astype(int); x1 = np.maximum(x0 + 1, np.floor(xs[1:]).astype(int))
    S = I[y1][:, x1] - I[y0][:, x1] - I[y1][:, x0] + I[y0][:, x0]
    area = ((y1 - y0)[:, None] * (x1 - x0)[None, :])[..., None]
    out = (S / area).astype(np.float32)
    al = np.maximum(out[..., 3:4], 1e-6); out[..., :3] /= al; out[..., :3] = np.clip(out[..., :3], 0, 1)
    return out

def crop_alpha(arr, pad=0.06):
    al = arr[..., 3]; ys, xs = np.where(al > 0.02)
    if len(xs) == 0: return arr
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    s = int(max(x1 - x0, y1 - y0) * (1 + 2 * pad)) + 2
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    out = np.zeros((s, s, 4), dtype=np.float32)
    sx0, sy0 = cx - s // 2, cy - s // 2
    for yy in range(s):
        pass
    h, w = arr.shape[:2]
    ax0, ay0 = max(0, sx0), max(0, sy0); ax1, ay1 = min(w, sx0 + s), min(h, sy0 + s)
    out[ay0 - sy0:ay1 - sy0, ax0 - sx0:ax1 - sx0] = arr[ay0:ay1, ax0:ax1]
    return out

