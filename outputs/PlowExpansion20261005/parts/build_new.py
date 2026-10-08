# build_new.py - builds the 45 rebalance parts (blades2 / engines2 / gears2) into packs Blades_C / Engines_C / Gears_C,
# checks budgets, exports FBX and renders contact sheets. Rebalance 2026-10-05.
# usage: blender -b --factory-startup -P build_new.py -- [--slots Blade,Engine,Gear] [--export] [--render] [--save]
import bpy, sys, os, json, importlib, importlib.util, traceback, math
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
import partlib, blades2, engines2, gears2
MODS = {"Blade": blades2, "Engine": engines2, "Gear": gears2}

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k, d=None): return argv[argv.index(k) + 1] if k in argv else d
SLOTS = opt("--slots", "Blade,Engine,Gear").split(",")
CAT = [e for e in json.load(open(r"C:\Users\wikto\Desktop\Roblox Gra\outputs\Rebalance20261005\data\catalog_visual2.json", encoding="utf-8")) if e.get("new")]
PACKS = [("Blades_C", "Blade", 6), ("Engines_C", "Engine", 7), ("Gears_C", "Gear", 8)]
GRID = {"Blade": (4, 20.0, 12.0), "Engine": (5, 10.0, 10.0), "Gear": (4, 14.0, 16.0)}
ZMIN = {"Blade": -1.1, "Engine": 0.05, "Gear": 0.0}

def layout():
    out = []
    for pack, slot, k in PACKS:
        ents = sorted([e for e in CAT if e["slot"] == slot], key=lambda e: (e["band"], e["id"]))
        cols, dx, dy = GRID[slot]
        base = 100.0 * k + 10.0
        for i, e in enumerate(ents):
            out.append((pack, slot, e, (round(base + (i % cols) * dx, 3), round(-(i // cols) * dy, 3), 0.0)))
    return out

def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    res, errors = {}, []
    for pack, slot, e, at in layout():
        if slot not in SLOTS: continue
        fn = getattr(MODS[slot], e["model"], None)
        if fn is None: errors.append(e["model"] + ": no builder"); continue
        m = L.Model(e["model"], at=at)
        try:
            fn(m, e)
            for bm_ in m.parts.values():
                for v in bm_.verts:
                    if v.co.z < ZMIN[slot]: v.co.z = ZMIN[slot]
        except Exception:
            errors.append(e["model"] + ": " + traceback.format_exc()); continue
        res[e["model"]] = [pack, slot, e, at, m]
    for pack in {r[0] for r in res.values()}:
        ms = [r[4] for r in res.values() if r[0] == pack]
        objs = L.realize(ms, pack)
        for r in res.values():
            if r[0] == pack: r[4] = [o for o in objs if o["w2model"] == r[4].name]
    return res, errors

def ref_marker(pack):
    m = L.Model("Ref", at=(0, 0, 0))
    L.rbox(m, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
    objs = L.realize([m], pack + "_Ref")
    objs[0].name = "Ref__Origin__FF00FFNE"; objs[0].data.name = "Ref__Origin__FF00FFNE"
    return objs[0]

_spec = importlib.util.spec_from_file_location("sg_scene", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\scene.py")
SG = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SG)

def render(res, stats):
    SG.setup(res=(SG.TW, SG.TH), samples=20)
    for slot in ("Blade", "Engine", "Gear"):
        names = [n for n, r in res.items() if r[1] == slot]
        if not names: continue
        paths = []
        for n in names:
            for k, r in res.items():
                for o in r[4]: o.hide_render = (k != n)
            st = stats[n]; at = Vector(res[n][3])
            mn, mx = Vector(st["min"]), Vector(st["max"]); c = at + (mn + mx) / 2
            size = max(mx.x - mn.x, mx.y - mn.y, (mx.z - mn.z) * 1.2, 1.5)
            SG.ground(at.z + mn.z - 0.03)
            d = Vector((0.75, 1.0, 0.7) if slot == "Engine" else (0.78, -1.0, 0.75)).normalized()   # engines: 3/4 rear like the game camera
            cam = SG.camera(c + d * (size * 3 + 20), c, ortho=size * 1.25)
            SG.label(res[n][2]["name"], cam, size * 1.25)
            p = os.path.join(HERE, "renders", "new", n + ".png"); SG.render(p); paths.append(p)
            for o in list(bpy.data.objects):
                if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
        SG.compose(paths, 5, os.path.join(HERE, "renders", "new_%s_sheet.png" % slot.lower()))

if __name__ == "__main__":
    res, errors = build()
    stats = {}
    for name, (pack, slot, e, at, objs) in res.items():
        st = L.stats(objs)[name]
        st.update({"pack": pack, "slot": slot, "band": e["band"], "id": e["id"], "at": list(at), "objects": len(objs), "rarity": e["rarity"],
                   "neon": sum(1 for o in objs if o.name.split("__")[2][6:8] == "NE")})
        stats[name] = st
        lim = 4500 if slot == "Gear" else 2500
        flag = (" OVER-TRIS" if st["tris"] > lim else "") + (" OVER-OBJ" if st["objects"] > 14 else "") + (" NEON>2" if st["neon"] > 2 else "")
        print("STAT %-22s tris=%5d objs=%2d neon=%d min=%s max=%s%s" % (name, st["tris"], st["objects"], st["neon"], st["min"], st["max"], flag))
    for er in errors: print("ERROR", er)
    json.dump(stats, open(os.path.join(HERE, "stats_new.json"), "w"), indent=1)
    if "--render" in argv: render(res, stats)
    if "--export" in argv:
        os.makedirs(os.path.join(HERE, "fbx"), exist_ok=True)
        for pack, slot, k in PACKS:
            objs = [o for n, r in res.items() if r[0] == pack for o in r[4]]
            if not objs: continue
            ref = ref_marker(pack)
            path = os.path.join(HERE, "fbx", pack + ".fbx")
            L.export_fbx(objs + [ref], path)
            me = ref.data; bpy.data.objects.remove(ref, do_unlink=True); bpy.data.meshes.remove(me)
            print("EXPORTED", path, os.path.getsize(path))
    if "--save" in argv:
        L.save_blend(os.path.join(HERE, "PlowParts45new.blend")); print("SAVED")
