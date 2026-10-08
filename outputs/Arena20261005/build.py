# build.py - Snowplow Bumper Arena models: packs, budgets (per-object triangle counts), FBX export, preview tiles + assembled scene.
# usage: blender -b --factory-startup -P build.py -- [--export] [--tiles] [--scene] [--save] [--only A,B]
import bpy, sys, os, json, math, importlib, importlib.util
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
import models as MD
importlib.reload(MD)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k, d=None): return argv[argv.index(k) + 1] if k in argv else d

# ring models share the arena-centre origin (at = 0); props are spaced along X inside their pack
PACKS = {
    "AR_Arena": [("ArenaFloor", (0, 0, 0)), ("WallRing", (0, 0, 0)), ("ExitGates", (0, 0, 0)), ("Stands", (0, 0, 0)), ("Jumbotron", (0, 0, 0)), ("LightTowers", (0, 0, 0))],
    "AR_Island": [("Island", (0, 0, 0)), ("PracticeRing", (0, 0, 0))],
    "AR_Props": [(n, (24 * (i + 1), 0, 0)) for i, n in enumerate(["Target", "Bumper", "Portal", "Trophy", "Lamp", "Banner", "SnowBank"])],
}
OBJ_TRIS = 9000  # per MeshPart safety budget


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    res = {}
    only = opt("--only")
    for pack, items in PACKS.items():
        ms = []
        for name, at in items:
            if only and name not in only.split(","): continue
            m = L.Model(name, at=at); MD.BUILDERS[name](m)
            ms.append((m, at))
        if not ms: continue
        objs = L.realize([m for m, _ in ms], pack)
        for m, at in ms:
            mo = [o for o in objs if o["w2model"] == m.name]
            for o in mo: o["pack"] = pack
            res[m.name] = {"pack": pack, "at": at, "objs": mo}
    return res


def ref_marker(pack):
    m = L.Model("Ref", at=(0, 0, 0))
    L.rbox(m, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
    objs = L.realize([m], pack + "_Ref")
    objs[0].name = "Ref__Origin__FF00FFNE"; objs[0].data.name = "Ref__Origin__FF00FFNE"
    return objs[0]


def export(res):
    for pack in PACKS:
        objs = [o for n, r in res.items() if r["pack"] == pack for o in r["objs"]]
        if not objs: continue
        ref = ref_marker(pack)
        path = os.path.join(HERE, "fbx", pack + ".fbx")
        L.export_fbx(objs + [ref], path)
        me = ref.data; bpy.data.objects.remove(ref, do_unlink=True); bpy.data.meshes.remove(me)
        print("EXPORTED", path, os.path.getsize(path))


_spec = importlib.util.spec_from_file_location("sg_scene", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\scene.py")
SG = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(SG)


def tiles(res, stats):
    SG.setup(res=(SG.TW, SG.TH), samples=24)
    paths = []
    for n in res:
        for k, r in res.items():
            for o in r["objs"]: o.hide_render = (k != n)
        st = stats[n]; at = Vector(res[n]["at"])
        mn, mx = Vector(st["min"]), Vector(st["max"]); c = at + (mn + mx) / 2
        size = max(mx.x - mn.x, mx.y - mn.y, (mx.z - mn.z) * 1.2, 1.5)
        SG.ground(at.z + mn.z - 0.03)
        d = Vector((0.78, -1.0, 0.75)).normalized()
        ortho = size * 1.25
        cam = SG.camera(c + d * (size * 3 + 20), c, ortho=ortho)
        SG.label(n, cam, ortho)
        p = os.path.join(HERE, "renders", "tiles", n + ".png"); SG.render(p); paths.append(p)
    for o in list(bpy.data.objects):
        if o.name.startswith("Lbl_"): bpy.data.objects.remove(o, do_unlink=True)
    SG.compose(paths, 5, os.path.join(HERE, "renders", "Models.png"))
    for r in res.values():
        for o in r["objs"]: o.hide_render = False


def scene(res):
    """Assembled island preview: arena models at the origin, practice ring + plaza props at their offsets."""
    for r in res.values():
        for o in r["objs"]: o.hide_render = True
    g = bpy.data.objects.get("RGround")
    if g: g.hide_render = True
    SG.setup(res=(1800, 1100), samples=32, world=(0.62, 0.77, 0.95), strength=0.8)
    col = L.collection("Scene")
    def place(name, x, y, z=0.0, rot=0.0):
        for o in res[name]["objs"]:
            n = o.copy(); n.data = o.data; col.objects.link(n)
            n.location = Vector((x, y, z)) + (o.location - Vector(res[name]["at"]))
            n.rotation_euler = (0, 0, math.radians(rot)); n.hide_render = False
    for n in ("ArenaFloor", "WallRing", "ExitGates", "Stands", "Jumbotron", "LightTowers", "Island"):
        if n in res: place(n, 0, 0)
    if "PracticeRing" in res: place("PracticeRing", *MD.PRACTICE_OFF)
    if "Portal" in res: place("Portal", MD.PLAZA_OFF[0], MD.PLAZA_OFF[1] - 10, 0, 180)
    if "Trophy" in res: place("Trophy", MD.PLAZA_OFF[0] + 22, MD.PLAZA_OFF[1] + 4)
    if "Target" in res:
        for k in range(3):
            a = math.radians(90 + k * 120); place("Target", -math.cos(a) * 16, math.sin(a) * 16)
    if "Bumper" in res:
        place("Bumper", 0, 38); place("Bumper", 26, -20, 0, 50)
    SG.camera((0, -330, 230), (0, -40, 0), lens=35); SG.render(os.path.join(HERE, "renders", "scene_overview.png"))
    SG.camera((60, -95, 26), (0, 0, 4), lens=28); SG.render(os.path.join(HERE, "renders", "scene_arena.png"))
    SG.camera((0, 0, 260), (0, -0.01, 0), ortho=380); SG.render(os.path.join(HERE, "renders", "scene_top.png"))


if __name__ == "__main__":
    res = build()
    stats = {}
    over = []
    for name, r in res.items():
        st = L.stats(r["objs"])[name]
        per = {o.name.split("__")[1]: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in r["objs"]}
        big = {k: v for k, v in per.items() if v > OBJ_TRIS}
        st.update({"pack": r["pack"], "at": list(r["at"]), "objects": len(r["objs"]), "perObject": per,
                   "neon": [o.name.split("__")[1] for o in r["objs"] if o.name.split("__")[2][6:8] == "NE"]})
        stats[name] = st
        if big: over.append((name, big))
        print("STAT %-12s tris=%6d objs=%2d size=%s%s" % (name, st["tris"], st["objects"], st["size"], (" OVER " + str(big)) if big else ""))
    if not opt("--only"):
        json.dump(stats, open(os.path.join(HERE, "stats.json"), "w"), indent=1)
    if "--export" in argv: export(res)
    if "--tiles" in argv: tiles(res, stats)
    if "--scene" in argv: scene(res)
    if "--save" in argv:
        L.save_blend(os.path.join(HERE, "Arena.blend")); print("SAVED")
    print("DONE over-budget objects:", over)
