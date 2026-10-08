# scene.py - render helpers for the Help Yard contracts: per-model tiles + Models.png, and the 8 assembled scene previews
# (pad + gate + props from prefabs.json + translucent snow over the zones from ContractConfig, read from the Lua file).
import bpy, os, math, json, re, sys, importlib.util
from mathutils import Vector
import w2lib as L
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "renders")
_spec = importlib.util.spec_from_file_location("sg_scene", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\scene.py")
SG = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SG)
setup, camera, ground, label, render, compose = SG.setup, SG.camera, SG.ground, SG.label, SG.render, SG.compose
TW, TH = SG.TW, SG.TH
CFG = r"C:\Users\wikto\Desktop\Roblox Gra\game\src\ReplicatedStorage\ContractConfig.luau"


def zones_from_lua():
    """Parse Id + Zones rects from ContractConfig.luau (simple regex; the file is ours)."""
    src = open(CFG, encoding="utf-8").read()
    out = {}
    for blk in re.split(r"\n\t\{\n\t\tId = ", src)[1:]:
        tid = re.match(r'"(\w+)"', blk).group(1)
        zs = []
        for g, r, rest in re.findall(r'\{Group = "(\w+)", Rect = \{([-\d, ]+)\}([^}]*)\}', blk):
            zs.append((g, [float(v) for v in r.split(",")], "Tough" in rest))
        out[tid] = zs
    return out


def tiles(res, stats):
    setup(res=(TW, TH), samples=24)
    paths = []
    for n in res:
        for k, r in res.items():
            for o in r["objs"]: o.hide_render = (k != n)
        st = stats[n]; at = Vector(res[n]["at"])
        mn, mx = Vector(st["min"]), Vector(st["max"]); c = at + (mn + mx) / 2
        size = max(mx.x - mn.x, mx.y - mn.y, (mx.z - mn.z) * 1.2, 1.5)
        ground(at.z + mn.z - 0.03)
        d = Vector((0.78, -1.0, 0.75)).normalized()
        ortho = size * 1.32
        cam = camera(c + d * (size * 3 + 20), c, ortho=ortho)
        label(n, cam, ortho)
        p = os.path.join(OUT, "tiles", n + ".png"); render(p); paths.append(p)
    for o in list(bpy.data.objects):
        if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
    compose(paths, 6, os.path.join(OUT, "Models.png"))
    for r in res.values():
        for o in r["objs"]: o.hide_render = False


def place(res, name, x, z, rot=0.0, y=0.0, tint=None, coll="Scene"):
    col = L.collection(coll); out = []
    for o in res[name]["objs"]:
        n = o.copy(); n.data = o.data; col.objects.link(n)
        n.location = Vector((-x, z, y)); n.rotation_euler = (0, 0, math.radians(rot)); n.hide_render = False
        part = o.name.split("__")[1]
        if tint and part == "TintBody":
            n.data = o.data.copy(); n.data.materials.clear(); n.data.materials.append(L.pmat(tint.upper() + "SP"))
        out.append(n)
    return out


def flatbox(coll, x0, z0, x1, z1, y0, y1, code):
    m = L.Model("Box", at=(0, 0, 0))
    L.rbox(m, code, (-(x0 + x1) / 2, (z0 + z1) / 2, (y0 + y1) / 2), (abs(x1 - x0), abs(z1 - z0), y1 - y0), r=0.0)
    for o in L.realize([m], coll + "_tmp"):
        bpy.data.collections[coll + "_tmp"].objects.unlink(o); L.collection(coll).objects.link(o)


def garage_models():
    sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005")
    spec = importlib.util.spec_from_file_location("sg_models", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\models.py")
    GM = importlib.util.module_from_spec(spec); spec.loader.exec_module(GM)
    res = {}
    for i, n in enumerate(["GarageLampPost", "GaragePineTree", "GarageBench", "GarageSnowPile", "GarageCrateStack", "GarageOilDrums", "GarageToolCart"]):
        m = L.Model(n, at=(0, -400 - 30 * i, 0)); GM.BUILDERS[n](m)
        objs = L.realize([m], "GarageProps_" + n)
        for o in objs: o.location = Vector((0, 0, 0)); o.hide_render = True
        res[n] = {"objs": objs}
    return res


def scenes(res):
    pre = json.load(open(os.path.join(HERE, "prefabs.json")))
    zones = zones_from_lua()
    res = dict(res); res.update(garage_models())
    for r in res.values():
        for o in r["objs"]: o.hide_render = True
    g = bpy.data.objects.get("RGround")
    if g: g.hide_render = True
    setup(res=(1600, 1000), samples=32, world=(0.66, 0.79, 0.95), strength=0.75)
    for tid, sc in pre.items():
        if tid.startswith("_"): continue
        L.clear_collection("Scene")
        place(res, "YardPad", 0, 0); place(res, "YardGate", 0, -30)
        for s in sc.get("surfaces", []):
            x0, z0, x1, z1 = s["rect"]; flatbox("Scene", x0, z0, x1, z1, 0.0, 0.06, s["color"].upper() + "SP")
        for d in sc.get("dashes", []) + sc.get("lines", []):
            (ax, az), (bx_, bz) = d["from"], d["to"]
            w = 0.5
            flatbox("Scene", min(ax, bx_) - (w if ax == bx_ else 0), min(az, bz) - (w if az == bz else 0), max(ax, bx_) + (w if ax == bx_ else 0), max(az, bz) + (w if az == bz else 0), 0.06, 0.1, (d.get("color") or "FFD23A").upper() + "NE")
        for p in sc["props"]:
            if p.get("parent"): continue
            place(res, p["model"], p["x"], p["z"], p.get("rot", 0), p.get("y", 0), p.get("tint"))
        for (gk, r, hard) in zones.get(tid, []):
            flatbox("Scene", r[0] + 0.05, r[1] + 0.05, r[2] - 0.05, r[3] - 0.05, 0.1, 1.6, "9FD8FFSPT45" if hard else "FFFFFFSPT35")
        camera((-40, -86, 70), (0, 2, 0), lens=30); render(os.path.join(OUT, "scene_%s.png" % tid))
        camera((0, 0, 140), (0, 0.01, 0), ortho=82); render(os.path.join(OUT, "scene_%s_top.png" % tid))
