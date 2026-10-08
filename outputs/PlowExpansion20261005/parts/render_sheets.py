# render_sheets.py - contact sheets, thumbnails-scale sheets, complete vehicles and fit checks.
# usage: blender -b --factory-startup -P render_sheets.py -- --slots Blade [--sheets] [--vehicles] [--fit] [--only A,B] [--tile 300x260]
import bpy, sys, os, json, math
import numpy as np
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import build_all as B
import rlib as R
import w2lib as L

argv = B.argv
OUT = os.path.join(HERE, "renders")
tw, th = [int(v) for v in B.opt("--tile", "300x260").split("x")]

CAMS = {  # offset from model origin, target offset, ortho scale, ground z
    "Blade": ((9.0, -15.0, 7.5), (0, -2.4, 0.35), 13.2, -1.15),
    "Engine": ((7.0, 10.5, 6.5), (0, 0.45, 1.75), 6.0, 0.0),
    "Gear": ((10.0, -13.0, 9.5), (0, 0, 0.7), 13.5, 0.0),
}


def hide_all(objs_by_model, keep):
    for n, r in objs_by_model.items():
        for o in r[4]: o.hide_render = (n not in keep)


def compose(tiles, cols, out, w=tw, h=th):
    rows = (len(tiles) + cols - 1) // cols
    W, H = cols * w, rows * h
    big = np.ones((H, W, 4), dtype=np.float32)
    for i, path in enumerate(tiles):
        img = bpy.data.images.load(path)
        px = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(px)
        px = px.reshape(h, w, 4)
        r, c = i // cols, i % cols
        y0 = H - (r + 1) * h
        big[y0:y0 + h, c * w:(c + 1) * w] = px
        bpy.data.images.remove(img)
    im = bpy.data.images.new("sheet", W, H, alpha=True)
    im.pixels.foreach_set(big.ravel()); im.filepath_raw = out; im.file_format = "PNG"; im.save()
    bpy.data.images.remove(im)
    print("SHEET", out)


def tile_label(cam, text, ortho):
    for o in list(bpy.data.objects):
        if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
    bpy.context.view_layer.update()
    hgt = ortho * th / tw
    ob = R.label(text, (0, 0, 0), size=ortho * 0.062)
    ob.matrix_world = cam.matrix_world @ __import__("mathutils").Matrix.Translation((0, -hgt / 2 + ortho * 0.035, -5))


def sheets(res):
    for slot in B.SLOTS:
        names = [e["model"] for e in B.CAT if e["slot"] == slot and e["model"] in res]
        if not names: continue
        off, tgt, ortho, gz = CAMS[slot]
        g = R.ground(z=gz); g.location.z = 0
        g.data.vertices.foreach_set("co", [c for v in g.data.vertices for c in (v.co.x, v.co.y, gz)])
        tiles = []
        R.setup(res=(tw, th), samples=24)
        for n in names:
            at = Vector(res[n][3])
            hide_all(res, {n})
            cam = R.camera(at + Vector(tgt) + Vector(off), at + Vector(tgt), ortho=ortho)
            e = res[n][2]
            tile_label(cam, "%s  %s" % (n, e["rarity"][0] if e["rarity"] != "Starter" else "S"), ortho)
            p = os.path.join(OUT, "tiles", slot, n + ".png"); R.render(p); tiles.append(p)
        big = os.path.join(OUT, slot + "s.png")
        compose(tiles, 6, big)
        R.resize_png(big, os.path.join(OUT, slot + "s_600.png"), 600)
        hide_all(res, set(res))


VEH = [(1, "BladeBasic", "EngineStarter", "GearWheels"), (3, "BladeHex", "EnginePhantom", "GearHaunted"),
       (5, "BladeArcade", "EngineArcade", "GearHoverPods"), (7, "BladeSingularity", "EngineZeroCore", "GearZeroG"),
       (9, "BladeCaneCrusher", "EngineSugarV8", "GearDonut"), (11, "BladeBulldozer", "EngineJackbox", "GearToyTank"),
       (13, "BladeThunder", "EngineStorm", "GearStormPods"), (14, "BladeGalaxy", "EngineNebula", "GearMeteor")]
ATT = {"Blade": Vector((0, -4.30, 1.15)), "Engine": Vector((0, 3.0, 2.6)), "Gear": Vector((0, 0, 0))}


def place(res, name, base):
    pack, slot, e, at, objs = res[name]
    out = []
    for o in objs:
        n = o.copy(); n.data = o.data; L.collection("Veh").objects.link(n)
        n.location = base + ATT[slot]; n.hide_render = False; out.append(n)
    return out


def vehicles(res, combos=VEH, out_name="Vehicles.png", views=("front", "rear")):
    hide_all(res, set())
    chassis = R.load_chassis("ChassisV", at=(0, 0, 0))
    R.setup(res=(600, 450), samples=32); g = R.ground(z=0)
    tiles = []
    for view in views:
        for band, b, en, ge in combos:
            vobjs = []
            base = Vector((0, 0, 0))
            for nm in (b, en, ge):
                if nm in res: vobjs += place(res, nm, base)
            if view == "front": cam = R.camera((15.5, -21, 12), (0, -1.6, 1.3), lens=50)
            else: cam = R.camera((-13, 18.5, 11.5), (0, -0.5, 1.6), lens=50)
            for o in list(bpy.data.objects):
                if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
            p = os.path.join(OUT, "tiles", "veh", "%s_band%02d.png" % (view, band)); R.render(p); tiles.append(p)
            for o in vobjs: bpy.data.objects.remove(o, do_unlink=True)
    compose(tiles, 4, os.path.join(OUT, out_name), w=600, h=450)
    for o in chassis: bpy.data.objects.remove(o, do_unlink=True)


def fit(res, stats):
    hide_all(res, set())
    blades = [n for n in res if res[n][1] == "Blade"]; engines = [n for n in res if res[n][1] == "Engine"]; gears = [n for n in res if res[n][1] == "Gear"]
    def size(n, i): return stats[n]["max"][i] - stats[n]["min"][i]
    picks = []
    if blades: picks.append(max(blades, key=lambda n: size(n, 0)))
    if engines: picks.append(max(engines, key=lambda n: stats[n]["max"][2]))
    if gears: picks.append(max(gears, key=lambda n: max(abs(stats[n]["min"][0]), stats[n]["max"][0])))
    chassis = R.load_chassis("ChassisF", at=(0, 0, 0), markers=True)
    R.setup(res=(1000, 800), samples=24); R.ground(z=0)
    base = Vector((0, 0, 0)); vobjs = []
    for n in picks: vobjs += place(res, n, base)
    print("FIT picks", picks)
    R.camera((30, 0, 2.2), (0, 0, 2.2), ortho=15); R.render(os.path.join(OUT, "Fit_side.png"))
    R.camera((0, 0, 30), (0, 0.0001, 0), ortho=15); R.render(os.path.join(OUT, "Fit_top.png"))
    R.camera((0, -30, 2.0), (0, 0, 2.0), ortho=15); R.render(os.path.join(OUT, "Fit_front.png"))
    R.camera((0, 30, 2.4), (0, 0, 2.4), ortho=9); R.render(os.path.join(OUT, "Fit_rear.png"))
    for o in vobjs: bpy.data.objects.remove(o, do_unlink=True)
    return picks


def per_vehicle_fit(res, names, tag):
    """Side ortho of chassis + each part (quick check of every part on the chassis)."""
    hide_all(res, set())
    R.load_chassis("ChassisP", at=(0, 0, 0))
    R.setup(res=(360, 300), samples=16); R.ground(z=0)
    tiles = []
    for n in names:
        vobjs = place(res, n, Vector((0, 0, 0)))
        slot = res[n][1]
        if slot == "Engine": cam = R.camera((14, 9, 7), (0, 2.0, 2.8), ortho=9.5)
        elif slot == "Blade": cam = R.camera((10, -15, 8), (0, -2.5, 1.5), ortho=17)
        else: cam = R.camera((12, -11, 6), (0, 0, 1.3), ortho=10.5)
        tile_label(cam, n, cam.data.ortho_scale) if False else None
        p = os.path.join(OUT, "tiles", "onchassis", n + ".png"); R.render(p); tiles.append(p)
        for o in vobjs: bpy.data.objects.remove(o, do_unlink=True)
    compose(tiles, 6, os.path.join(OUT, "OnChassis_%s.png" % tag), w=360, h=300)


if __name__ == "__main__":
    res, errors = B.build()
    for er in errors: print("ERROR", er)
    stats = {n: L.stats(r[4])[n] for n, r in res.items()}
    if "--sheets" in argv: sheets(res)
    if "--vehicles" in argv: vehicles(res)
    if "--fit" in argv: fit(res, stats)
    if "--onchassis" in argv:
        for slot in B.SLOTS:
            names = [e["model"] for e in B.CAT if e["slot"] == slot and e["model"] in res]
            if names: per_vehicle_fit(res, names, slot)

