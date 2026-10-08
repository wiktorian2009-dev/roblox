# build.py - builds the Shared Garage lobby models into 4 packs, checks budgets/contracts, exports FBX, renders.
# usage: blender -b --factory-startup -P build.py -- [--export] [--save] [--tiles] [--lobby] [--only A,B]
import bpy, sys, os, json, math, importlib
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import models as MD
import w2lib as L
importlib.reload(MD)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k, d=None): return argv[argv.index(k) + 1] if k in argv else d

PROPS = ["GaragePineTree", "GarageCrateStack", "GarageOilDrums", "GarageToolCart", "GarageLampPost", "GarageSnowPile", "GarageBench", "GarageHoistCrane"]
PACKS = {
    "Pack_Bay": [("GarageBay", (30, 0, 0)), ("GarageStreet", (76, 0, 0))],
    "Pack_Island": [("GarageIsland", (90, 0, 0)), ("GarageAnnexSlab", (200, 0, 0))],
    "Pack_Landmarks": [("PlazaLandmark", (20, 0, 0)), ("ReturnPortal", (45, 0, 0))],
    "Pack_Props": [(n, (16 + 16 * i, 0, 0)) for i, n in enumerate(PROPS)],
}
BUDGET = {"GarageBay": 9000, "GarageStreet": 3000, "GarageIsland": 12000, "GarageAnnexSlab": 12000, "PlazaLandmark": 9000, "ReturnPortal": 5000}
CLAMP0 = set(PROPS) | {"PlazaLandmark", "ReturnPortal"}


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    res = {}
    only = opt("--only")
    for pack, items in PACKS.items():
        ms = []
        for name, at in items:
            if only and name not in only.split(","): continue
            m = L.Model(name, at=at); MD.BUILDERS[name](m)
            if name in CLAMP0:
                for b in m.parts.values():
                    for v in b.verts:
                        if v.co.z < 0: v.co.z = 0.0
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


def verts_of(o):
    return [v.co.copy() for v in o.data.vertices]


def checks(res, stats):
    """Contract checks: floors flat, clear zones in the bay, island covers the lobby layout."""
    out = []
    if "GarageBay" in res:
        zones_rect = [(-11.5, -8, 3.6, 3.6), (-11.5, 0, 3.6, 3.6), (-11.5, 8, 3.6, 3.6), (11.5, -5, 4.1, 4.1), (11.5, 7, 3.35, 1.45)]
        bad = 0; maxfloor = -9
        for o in res["GarageBay"]["objs"]:
            for v in o.data.vertices:
                p = v.co
                if abs(p.x) < 14 and abs(p.y) < 13 and p.z > -0.5 and p.z < 0.3: maxfloor = max(maxfloor, p.z)
                if 0.05 < p.z < 7.5:
                    inz = (math.hypot(p.x, p.y - 4) < 7.5) or any(abs(p.x - cx) <= hx and abs(p.y - cy) <= hy for cx, cy, hx, hy in zones_rect)
                    if inz:
                        bad += 1
                        if bad <= 5: print("INTRUDE", o.name, tuple(round(c, 2) for c in p))
        out.append("GarageBay: clear-zone intrusions(verts)=%d  max floor-area z (|x|<14,|y|<13, z<0.3)=%.3f" % (bad, maxfloor))
    if "GarageStreet" in res:
        mz = max(v.co.z for o in res["GarageStreet"]["objs"] if "Lamp" not in o.name and o.name.split("__")[1] not in ("Steel", "Red", "Orange", "LampBulb")
                 for v in o.data.vertices if abs(v.co.x) < 13.5 or abs(v.co.y) < 12)
        out.append("GarageStreet: max z of paving/snow = %.3f" % mz)
    if "GarageIsland" in res:
        def inside(x, y, a=76, b=50, n=6): return abs(x / a) ** n + abs(y / b) ** n < 1
        pts = [(64, 45), (-64, 45), (64, -45), (-68, 2), (-68, -2)]
        out.append("GarageIsland: layout corners inside top = %s" % [inside(*p) for p in pts])
        top = [v.co.z for o in res["GarageIsland"]["objs"] if o.name.split("__")[1] == "Snow" for v in o.data.vertices if abs(v.co.x) < 66 and abs(v.co.y) < 46]
        out.append("GarageIsland: snow top z range inside layout = %.3f..%.3f" % (min(top), max(top)))
    return out


def export(res):
    for pack in PACKS:
        objs = [o for n, r in res.items() if r["pack"] == pack for o in r["objs"]]
        if not objs: continue
        ref = ref_marker(pack)
        path = os.path.join(HERE, "fbx", pack + ".fbx")
        L.export_fbx(objs + [ref], path)
        me = ref.data; bpy.data.objects.remove(ref, do_unlink=True); bpy.data.meshes.remove(me)
        print("EXPORTED", path, os.path.getsize(path))


if __name__ == "__main__":
    res = build()
    stats = {}
    for name, r in res.items():
        st = L.stats(r["objs"])[name]
        st.update({"pack": r["pack"], "at": list(r["at"]), "objects": len(r["objs"]),
                   "neon": [o.name.split("__")[1] for o in r["objs"] if o.name.split("__")[2][6:8] == "NE"]})
        stats[name] = st
        lim = BUDGET.get(name, 2500)
        flag = (" OVER-TRIS(%d)" % lim if st["tris"] > lim else "") + (" OVER-OBJ" if st["objects"] > 16 else "")
        print("STAT %-17s tris=%5d objs=%2d min=%s max=%s neon=%s%s" % (name, st["tris"], st["objects"], st["min"], st["max"], st["neon"], flag))
    for line in checks(res, stats): print("CHECK", line)
    if not opt("--only"):
        json.dump(stats, open(os.path.join(HERE, "stats.json"), "w"), indent=1)
    if "--export" in argv: export(res)
    if "--tiles" in argv or "--lobby" in argv:
        import scene as S; importlib.reload(S)
        if "--tiles" in argv: S.tiles(res, stats)
        if "--lobby" in argv: S.lobby(res)
    if "--save" in argv:
        L.save_blend(os.path.join(HERE, "SharedGarage.blend")); print("SAVED")
