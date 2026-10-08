# build.py - builds the Help Yard contract models into packs, prints budgets, exports FBX, renders tiles + 8 scene previews.
# usage: blender -b --factory-startup -P build.py -- [--export] [--tiles] [--scenes] [--save] [--only A,B]
import bpy, sys, os, json, math, importlib
from mathutils import Vector, Matrix
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
import models as MD
importlib.reload(MD)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k, d=None): return argv[argv.index(k) + 1] if k in argv else d

PACKS = {
    "CT_Yard": ["YardPad", "YardGate", "YardBridge"],
    "CT_Homes": ["Cottage", "Mailbox", "PicketFence", "RoadSign", "RoadClosed", "Snowman"],
    "CT_Market": ["MarketStall", "StallShutter", "StallGoods", "MarketArch", "ShopFront"],
    "CT_Vehicles": ["Car", "BarrierArm", "BarrierBoom", "BusShelter", "BusStopSign", "Bus", "DeliveryVan"],
    "CT_Work": ["SupplyTent", "SupplyCrate", "Campfire", "PumpHouse", "PumpMachine", "PumpWheel", "Warehouse", "WarehouseDoor", "PalletStack", "WinterHat", "Scarf"],
}
SPACING = 90
BUDGET = {"YardPad": 14000, "Warehouse": 6000, "ShopFront": 5000, "Bus": 5000, "Cottage": 5000, "MarketStall": 4500, "YardGate": 5000}
NOCLAMP = {"YardPad", "YardBridge", "PumpWheel", "BarrierBoom", "WinterHat", "Scarf"}


def at_of(pack, i): return (SPACING * (i + 1), 0, 0)


def build(names=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    res = {}
    only = opt("--only")
    for pack, items in PACKS.items():
        ms = []
        for i, name in enumerate(items):
            if only and name not in only.split(","): continue
            at = at_of(pack, i)
            m = L.Model(name, at=at); MD.BUILDERS[name](m)
            if name not in NOCLAMP:
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
        lim = BUDGET.get(name, 3500)
        flag = (" OVER-TRIS(%d)" % lim if st["tris"] > lim else "") + (" OVER-OBJ" if st["objects"] > 20 else "")
        print("STAT %-14s tris=%5d objs=%2d min=%s max=%s%s" % (name, st["tris"], st["objects"], st["min"], st["max"], flag))
    if not opt("--only"):
        json.dump(stats, open(os.path.join(HERE, "stats.json"), "w"), indent=1)
    if "--export" in argv: export(res)
    if "--tiles" in argv or "--scenes" in argv:
        import scene as S; importlib.reload(S)
        if "--tiles" in argv: S.tiles(res, stats)
        if "--scenes" in argv: S.scenes(res)
    if "--save" in argv:
        L.save_blend(os.path.join(HERE, "Contracts.blend")); print("SAVED")
