# build_all.py - builds all 90 plow parts, lays them out per pack, exports FBX packs, saves the .blend and stats.
# usage: blender -b --factory-startup -P build_all.py -- [--slots Blade,Engine,Gear] [--export] [--save] [--render]
import bpy, sys, os, json, importlib, traceback
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
import partlib, blades
for mod in (partlib, blades): importlib.reload(mod)
MODS = {"Blade": blades}
for name, slot in (("engines", "Engine"), ("gears", "Gear")):
    try:
        MODS[slot] = importlib.import_module(name)
    except ModuleNotFoundError:
        pass

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k, d=None):
    return argv[argv.index(k) + 1] if k in argv else d
SLOTS = opt("--slots", "Blade,Engine,Gear").split(",")
ONLY = opt("--only")

CAT = json.load(open(os.path.join(HERE, "..", "data", "catalog_visual.json"), encoding="utf-8"))
PACKS = [("Blades_A", "Blade", 1, 7), ("Blades_B", "Blade", 8, 14), ("Engines_A", "Engine", 1, 7), ("Engines_B", "Engine", 8, 14),
         ("Gears_A", "Gear", 1, 7), ("Gears_B", "Gear", 8, 14)]
GRID = {"Blade": (4, 20.0, 12.0), "Engine": (5, 10.0, 10.0), "Gear": (4, 14.0, 16.0)}


def layout():
    out = []
    for k, (pack, slot, b0, b1) in enumerate(PACKS):
        ents = [e for e in CAT if e["slot"] == slot and b0 <= e["band"] <= b1]
        cols, dx, dy = GRID[slot]
        base = 100.0 * k + 10.0   # packs occupy separate regions; each pack's Ref marker stays at world 0
        for i, e in enumerate(ents):
            at = (round(base + (i % cols) * dx, 3), round(-(i // cols) * dy, 3), 0.0)
            out.append((pack, slot, e, at))
    return out


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    res = {}; errors = []
    for pack, slot, e, at in layout():
        if slot not in SLOTS or slot not in MODS: continue
        if ONLY and e["model"] not in ONLY.split(","): continue
        fn = getattr(MODS[slot], e["model"], None)
        if fn is None:
            errors.append(e["model"] + ": no builder"); continue
        m = L.Model(e["model"], at=at)
        try:
            fn(m, e)
            zmin = {"Blade": -1.1, "Engine": 0.05, "Gear": 0.0}[slot]
            for bm_ in m.parts.values():
                for v in bm_.verts:
                    if v.co.z < zmin: v.co.z = zmin
        except Exception:
            errors.append(e["model"] + ": " + traceback.format_exc()); continue
        res[e["model"]] = [pack, slot, e, at, m]
    for pack in {r[0] for r in res.values()}:
        ms = [r[4] for r in res.values() if r[0] == pack]
        objs = L.realize(ms, pack)
        for o in objs:
            o["pack"] = pack; o["slot"] = res[o["w2model"]][1]
        for r in res.values():
            if r[0] == pack: r[4] = [o for o in objs if o["w2model"] == r[4].name]
    return {k: tuple(v) for k, v in res.items()}, errors


def ref_marker(pack):
    m = L.Model("Ref", at=(0, 0, 0))
    L.rbox(m, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
    objs = L.realize([m], pack + "_Ref")
    objs[0].name = "Ref__Origin__FF00FFNE"; objs[0].data.name = "Ref__Origin__FF00FFNE"
    return objs[0]


if __name__ == "__main__":
    res, errors = build()
    stats = {}
    for name, (pack, slot, e, at, objs) in res.items():
        st = L.stats(objs)[name]
        st.update({"pack": pack, "slot": slot, "band": e["band"], "id": e["id"], "at": list(at), "objects": len(objs), "rarity": e["rarity"],
                   "neon": sum(1 for o in objs if o.name.split("__")[2][6:8] == "NE")})
        stats[name] = st
    tag = opt("--tag", "_".join(SLOTS))
    json.dump(stats, open(os.path.join(HERE, "stats_%s.json" % tag), "w"), indent=1)
    for k, v in stats.items():
        flag = ""
        lim = 4500 if v["slot"] == "Gear" else 2500
        if v["tris"] > lim: flag += " OVER-TRIS"
        if v["objects"] > 14: flag += " OVER-OBJ"
        if v["neon"] > 2: flag += " NEON>2"
        print("STAT %-20s tris=%5d objs=%2d neon=%d min=%s max=%s%s" % (k, v["tris"], v["objects"], v["neon"], v["min"], v["max"], flag))
    for er in errors: print("ERROR", er)
    if "--export" in argv:
        for pack, slot, b0, b1 in PACKS:
            objs = [o for n, r in res.items() if r[0] == pack for o in r[4]]
            if not objs: continue
            ref = ref_marker(pack)
            path = os.path.join(HERE, "fbx", pack + ".fbx")
            L.export_fbx(objs + [ref], path)
            me = ref.data; bpy.data.objects.remove(ref, do_unlink=True); bpy.data.meshes.remove(me)
            print("EXPORTED", path, os.path.getsize(path), "tris", sum(stats[n]["tris"] for n, r in res.items() if r[0] == pack))
    if "--save" in argv:
        sys.path.insert(0, HERE); import rlib
        rlib.load_chassis("Chassis", at=(0, 40, 0), markers=True)
        L.save_blend(os.path.join(HERE, opt("--blend", "PlowParts90.blend")))
        print("SAVED")

