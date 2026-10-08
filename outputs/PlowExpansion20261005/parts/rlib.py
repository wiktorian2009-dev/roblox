# rlib.py - render / scene helpers for the plow parts (headless Blender)
import bpy, math, os, sys
from mathutils import Vector
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L

KIT = r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SnowplowKit2026\SnowplowKit.blend"
HERE = os.path.dirname(os.path.abspath(__file__))


def load_chassis(coll="Chassis", at=(0, 0, 0), markers=False):
    """Append the PlowChassis objects from the kit .blend (unchanged geometry)."""
    with bpy.data.libraries.load(KIT, link=False) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("PlowChassis__")]
    col = L.collection(coll); out = []
    for o in dst.objects:
        if o is None: continue
        code = o.name.split("__")[2].split(".")[0]
        if code.startswith("FF00FF") and not markers:
            bpy.data.objects.remove(o, do_unlink=True); continue
        o.data.materials.clear(); o.data.materials.append(L.pmat(code))
        col.objects.link(o); o.location = Vector(at); out.append(o)
    return out


def dup_objs(objs, offset, coll):
    col = L.collection(coll); out = []
    for o in objs:
        n = o.copy(); n.data = o.data  # share mesh
        col.objects.link(n); n.location = o.location + Vector(offset); out.append(n)
    return out


def setup(res=(1600, 1000), world=(0.80, 0.85, 0.92), samples=32):
    sc = bpy.context.scene
    try: sc.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        try: sc.render.engine = "BLENDER_EEVEE"
        except TypeError: pass
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    try: sc.eevee.taa_render_samples = samples
    except Exception: pass
    sc.render.film_transparent = False
    try: sc.view_settings.view_transform = "Standard"
    except Exception: pass
    w = sc.world or bpy.data.worlds.new("W"); sc.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (*[L.srgb2lin(c) for c in world], 1); bg.inputs[1].default_value = 0.62
    sun = bpy.data.objects.get("RSun")
    if sun is None:
        ld = bpy.data.lights.new("RSun", "SUN"); ld.energy = 4.2; ld.angle = math.radians(12)
        sun = bpy.data.objects.new("RSun", ld); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(-12), math.radians(-35))
    try:
        sc.eevee.use_shadows = True
    except Exception: pass
    return sc


def camera(loc, target, ortho=None, lens=50):
    sc = bpy.context.scene
    cam = bpy.data.objects.get("RCam")
    if cam is None:
        cam = bpy.data.objects.new("RCam", bpy.data.cameras.new("RCam")); sc.collection.objects.link(cam)
    cam.location = Vector(loc)
    d = Vector(target) - Vector(loc)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    if ortho:
        cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    else:
        cam.data.type = "PERSP"; cam.data.lens = lens
    cam.data.clip_end = 2000
    sc.camera = cam
    return cam


def label(text, loc, size=0.9, coll="Labels", rot=None, color="1E2235"):
    cu = bpy.data.curves.new("Lbl_" + text, "FONT"); cu.body = text; cu.size = size
    cu.align_x = "CENTER"; cu.extrude = 0.0
    ob = bpy.data.objects.new("Lbl_" + text, cu); L.collection(coll).objects.link(ob)
    ob.location = Vector(loc)
    if rot is not None: ob.rotation_euler = rot
    m = bpy.data.materials.get("LblMat")
    if m is None:
        m = bpy.data.materials.new("LblMat"); m.use_nodes = True
        b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        rgb = [L.srgb2lin(int(color[i:i + 2], 16) / 255) for i in (0, 2, 4)]
        b.inputs["Base Color"].default_value = (*rgb, 1)
        b.inputs["Emission Color"].default_value = (*rgb, 1); b.inputs["Emission Strength"].default_value = 0.0
    cu.materials.append(m)
    return ob


def ground(size=400, z=-0.01, color="DDE4EE"):
    ob = bpy.data.objects.get("RGround")
    if ob: return ob
    me = bpy.data.meshes.new("RGround")
    s = size / 2
    me.from_pydata([(-s, -s, z), (s, -s, z), (s, s, z), (-s, s, z)], [], [(0, 1, 2, 3)])
    ob = bpy.data.objects.new("RGround", me); bpy.context.scene.collection.objects.link(ob)
    me.materials.append(L.pmat(color + "SP"))
    return ob


def render(path, res=None):
    sc = bpy.context.scene
    if res: sc.render.resolution_x, sc.render.resolution_y = res
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sc.render.filepath = path
    sc.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    print("RENDERED", path)


def resize_png(src, dst, width):
    img = bpy.data.images.load(src)
    w, h = img.size
    img.scale(width, int(h * width / w))
    img.filepath_raw = dst; img.file_format = "PNG"; img.save()
    bpy.data.images.remove(img)

