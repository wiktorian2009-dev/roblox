# scene.py - render helpers: per-model 3/4 tiles + Models.png sheet, assembled lobby preview renders.
import bpy, os, math
import numpy as np
from mathutils import Vector, Matrix
import w2lib as L
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "renders")
TW, TH = 520, 400


def setup(res=(1600, 1000), world=(0.72, 0.82, 0.95), samples=32, strength=0.7):
    sc = bpy.context.scene
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try: sc.render.engine = eng; break
        except TypeError: pass
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    try: sc.eevee.taa_render_samples = samples
    except Exception: pass
    try: sc.view_settings.view_transform = "Standard"
    except Exception: pass
    w = sc.world or bpy.data.worlds.new("W"); sc.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (*[L.srgb2lin(c) for c in world], 1); bg.inputs[1].default_value = strength
    sun = bpy.data.objects.get("RSun")
    if sun is None:
        ld = bpy.data.lights.new("RSun", "SUN"); ld.energy = 3.6; ld.angle = math.radians(10)
        sun = bpy.data.objects.new("RSun", ld); sc.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(48), math.radians(-10), math.radians(-30))
    return sc


def camera(loc, target, ortho=None, lens=50):
    sc = bpy.context.scene
    cam = bpy.data.objects.get("RCam")
    if cam is None:
        cam = bpy.data.objects.new("RCam", bpy.data.cameras.new("RCam")); sc.collection.objects.link(cam)
    cam.location = Vector(loc)
    cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    if ortho: cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    else: cam.data.type = "PERSP"; cam.data.lens = lens
    cam.data.clip_start = 0.1; cam.data.clip_end = 3000
    sc.camera = cam
    return cam


def ground(z, size=600, color="DCE6F0"):
    ob = bpy.data.objects.get("RGround")
    if ob is None:
        me = bpy.data.meshes.new("RGround"); s = size / 2
        me.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
        ob = bpy.data.objects.new("RGround", me); bpy.context.scene.collection.objects.link(ob)
        me.materials.append(L.pmat(color + "SP"))
    ob.location.z = z
    return ob


def label(text, cam, ortho):
    for o in list(bpy.data.objects):
        if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
    cu = bpy.data.curves.new("Lbl_" + text, "FONT"); cu.body = text; cu.size = ortho * 0.055; cu.align_x = "CENTER"
    ob = bpy.data.objects.new("Lbl_" + text, cu); bpy.context.scene.collection.objects.link(ob)
    mat = bpy.data.materials.get("LblMat") or bpy.data.materials.new("LblMat")
    mat.use_nodes = True
    b = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"); b.inputs["Base Color"].default_value = (0.02, 0.03, 0.06, 1)
    cu.materials.append(mat)
    hgt = ortho * TH / TW
    bpy.context.view_layer.update()
    ob.matrix_world = cam.matrix_world @ Matrix.Translation((0, -hgt / 2 + ortho * 0.03, -5))


def render(path, res=None):
    sc = bpy.context.scene
    if res: sc.render.resolution_x, sc.render.resolution_y = res
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sc.render.filepath = path; sc.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    print("RENDERED", path)


def compose(tiles, cols, out, w=TW, h=TH):
    rows = (len(tiles) + cols - 1) // cols
    W, H = cols * w, rows * h
    big = np.ones((H, W, 4), dtype=np.float32)
    for i, path in enumerate(tiles):
        img = bpy.data.images.load(path)
        px = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(px)
        r, c = i // cols, i % cols; y0 = H - (r + 1) * h
        big[y0:y0 + h, c * w:(c + 1) * w] = px.reshape(h, w, 4)
        bpy.data.images.remove(img)
    im = bpy.data.images.new("sheet", W, H, alpha=True)
    im.pixels.foreach_set(big.ravel()); im.filepath_raw = out; im.file_format = "PNG"; im.save()
    bpy.data.images.remove(im); print("SHEET", out)


ORDER = ["GarageBay", "GarageStreet", "GarageIsland", "GarageAnnexSlab", "PlazaLandmark", "ReturnPortal", "GaragePineTree", "GarageCrateStack",
         "GarageOilDrums", "GarageToolCart", "GarageLampPost", "GarageSnowPile", "GarageBench", "GarageHoistCrane"]


def tiles(res, stats):
    setup(res=(TW, TH), samples=24)
    paths = []
    for n in ORDER:
        if n not in res: continue
        for k, r in res.items():
            for o in r["objs"]: o.hide_render = (k != n)
        st = stats[n]; at = Vector(res[n]["at"])
        mn, mx = Vector(st["min"]), Vector(st["max"]); c = at + (mn + mx) / 2
        size = max(mx.x - mn.x, mx.y - mn.y, (mx.z - mn.z) * 1.2)
        ground(at.z + mn.z - 0.03)
        d = Vector((0.78, -1.0, 0.3 if n in ("GarageIsland", "GarageAnnexSlab") else 0.75)).normalized()
        ortho = size * 1.32
        cam = camera(c + d * (size * 3 + 20), c, ortho=ortho)
        label(n, cam, ortho)
        p = os.path.join(OUT, "tiles", n + ".png"); render(p); paths.append(p)
        if n in ("GarageBay", "PlazaLandmark", "ReturnPortal"):   # extra close views for review
            cam = camera(c + Vector((-0.55, -1.0, 0.45)).normalized() * (size * 3 + 20), c, ortho=ortho * 0.9)
            label(n + " (front-left)", cam, ortho * 0.9)
            render(os.path.join(OUT, "tiles", n + "_b.png"))
    for o in list(bpy.data.objects):
        if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
    compose(paths, 4, os.path.join(OUT, "Models.png"))
    for r in res.values():
        for o in r["objs"]: o.hide_render = False


def place(res, name, loc, rot_deg=0.0, coll="Lobby"):
    col = L.collection(coll); out = []
    for o in res[name]["objs"]:
        n = o.copy(); n.data = o.data; col.objects.link(n)
        n.location = Vector(loc); n.rotation_euler = (0, 0, math.radians(rot_deg)); n.hide_render = False; out.append(n)
    return out


LOBBY = ([("GarageIsland", (0, 0, 0), 0)] +
         [("GarageBay", (x, 30, 0), 0) for x in (-48, -16, 16, 48)] +
         [("GarageBay", (x, -30, 0), 180) for x in (-48, -16, 16, 48)] +
         [("GarageStreet", (x, 0, 0), 0) for x in (-48, -16, 16, 48)] +
         [("PlazaLandmark", (0, 0, 0), 0), ("ReturnPortal", (-66, 0, 0), 90),
          ("GaragePineTree", (70, 34, 0), 0), ("GaragePineTree", (-70, 36, 0), 20), ("GaragePineTree", (70, -36, 0), 50), ("GaragePineTree", (-71, -34, 0), 0),
          ("GarageHoistCrane", (69, 0, 0), 90), ("GarageCrateStack", (69, -15, 0), 30), ("GarageOilDrums", (69, 14, 0), 0),
          ("GarageSnowPile", (-70, 18, 0), 0), ("GarageSnowPile", (-70, -18, 0), 70), ("GarageLampPost", (-64.5, 8, 0), 0), ("GarageLampPost", (-64.5, -8, 0), 0),
          ("GarageBench", (-30, 9.5, 0), 180), ("GarageBench", (30, -9.5, 0), 0), ("GarageToolCart", (-42, 40.5, 0), 0), ("GarageToolCart", (-56, -40, 0), 180)])


def lobby(res):
    for r in res.values():
        for o in r["objs"]: o.hide_render = True
    for name, loc, rot in LOBBY:
        if name in res: place(res, name, loc, rot)
    g = bpy.data.objects.get("RGround")
    if g: g.hide_render = True
    setup(res=(1920, 1080), samples=48, world=(0.66, 0.79, 0.95), strength=0.75)
    camera((105, -125, 95), (0, -2, -6), lens=30); render(os.path.join(OUT, "Lobby_high.png"))
    camera((44, -9, 5), (-10, 3, 5.5), lens=22); render(os.path.join(OUT, "Lobby_eye.png"))
    camera((-40, 4, 5), (10, -2, 6.0), lens=24); render(os.path.join(OUT, "Lobby_eye2.png"))
    camera((16, -8, 5), (16, 34, 4), lens=24); render(os.path.join(OUT, "Lobby_baylook.png"))
