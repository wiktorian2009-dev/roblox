# build_bodies.py (copy of W1Remaster build_w1.py) - snowplow BODY pack (task 7): build one biome module, per-object triangle budget, FBX export, preview tiles.
# usage: blender -b --factory-startup -P build_w1.py -- --biome desert [--export] [--tiles] [--save]
import bpy, sys, os, json, math, importlib, importlib.util
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\W1Remaster20261005")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k, d=None): return argv[argv.index(k) + 1] if k in argv else d
BIOME = opt("--biome", "bodies")
MD = importlib.import_module(BIOME); importlib.reload(MD)
PACK = "Bodies_A"
OBJ_TRIS = 9000
SPACING = 30


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ms = []
    for i, name in enumerate(MD.BUILDERS):
        at = (SPACING * (i + 1), 0, 0)
        m = L.Model(name, at=at); MD.BUILDERS[name](m)
        ms.append((m, at))
    objs = L.realize([m for m, _ in ms], PACK)
    res = {}
    for m, at in ms:
        mo = [o for o in objs if o["w2model"] == m.name]
        res[m.name] = {"at": at, "objs": mo}
    return res


def ref_marker():
    m = L.Model("Ref", at=(0, 0, 0))
    L.rbox(m, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
    objs = L.realize([m], PACK + "_Ref")
    objs[0].name = "Ref__Origin__FF00FFNE"; objs[0].data.name = "Ref__Origin__FF00FFNE"
    return objs[0]


_spec = importlib.util.spec_from_file_location("sg_scene", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\scene.py")
SG = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SG)


def tiles(res, stats):
    SG.setup(res=(SG.TW, SG.TH), samples=20)
    paths = []
    for n in res:
        for k, r in res.items():
            for o in r["objs"]: o.hide_render = (k != n)
        st = stats[n]; at = Vector(res[n]["at"])
        mn, mx = Vector(st["min"]), Vector(st["max"]); c = at + (mn + mx) / 2
        size = max(mx.x - mn.x, mx.y - mn.y, (mx.z - mn.z) * 1.2, 1.5)
        SG.ground(at.z + mn.z - 0.03)
        d = Vector((0.78, -1.0, 0.75)).normalized()
        cam = SG.camera(c + d * (size * 3 + 20), c, ortho=size * 1.25)
        SG.label(n, cam, size * 1.25)
        p = os.path.join(HERE, "renders", BIOME, n + ".png"); SG.render(p); paths.append(p)
    for o in list(bpy.data.objects):
        if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
    SG.compose(paths, 4, os.path.join(HERE, "renders", BIOME + "_models.png"))


if __name__ == "__main__":
    res = build()
    stats = {}; over = []
    for name, r in res.items():
        st = L.stats(r["objs"])[name]
        per = {o.name.split("__")[1]: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in r["objs"]}
        big = {k: v for k, v in per.items() if v > OBJ_TRIS}
        st.update({"pack": PACK, "at": list(r["at"]), "objects": len(r["objs"]), "perObject": per})
        stats[name] = st
        if big: over.append((name, big))
        print("STAT %-14s tris=%6d objs=%2d size=%s%s" % (name, st["tris"], st["objects"], st["size"], (" OVER " + str(big)) if big else ""))
    json.dump(stats, open(os.path.join(HERE, "stats_" + BIOME + ".json"), "w"), indent=1)
    if "--export" in argv:
        ref = ref_marker()
        objs = [o for r in res.values() for o in r["objs"]]
        path = os.path.join(HERE, "fbx", PACK + ".fbx")
        L.export_fbx(objs + [ref], path)
        print("EXPORTED", path, os.path.getsize(path))
    if "--tiles" in argv: tiles(res, stats)
    if "--save" in argv: L.save_blend(os.path.join(HERE, "blend", PACK + ".blend")); print("SAVED")
    print("DONE over:", over)
