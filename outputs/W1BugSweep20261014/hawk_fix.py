# hawk_fix.py - rebuilds the Desert hawk (D_Hawk) with two-sided wings and tail (2026-10-14, Claude, World 1 bug sweep).
# Cause of "eagle with one wing": the 2026-10-05 builder made each wing and the tail from one quad plus the same quad reversed.
# bmesh refuses a second face on the same four vertices (partlib.mesh swallows the ValueError), so every wing/tail was a
# single-sided face. The left wing is mirrored, so its face pointed the other way: from below you saw one wing, from above the other.
# Fix: each wing and the tail is a thin closed slab (top + bottom + sides), same outline, colours and size as before.
# usage: blender -b --factory-startup -P hawk_fix.py -- [--upload]
import bpy, sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = r"C:\Users\wikto\Desktop\Roblox Gra\outputs"
for p in (os.path.join(ROOT, "World2Blender"), os.path.join(ROOT, "PlowExpansion20261005", "parts"), os.path.join(ROOT, "W1Remaster20261005")):
    sys.path.insert(0, p)
import w2lib as L
from w1lib import *  # P, sphere, prism, mesh, GOLD (same helpers as desert.py)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PACK = "W1_HawkFix"


def slab(m, pc, top, t, part):
    """Thin closed solid under a 4-point outline: the outline, the same outline t lower, and the four sides."""
    bot = [(x, y, z - t) for (x, y, z) in top]
    faces = [[0, 1, 2, 3], [7, 6, 5, 4], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]]
    mesh(m, pc, list(top) + bot, faces, part=part, recalc=True)


def D_Hawk(m):
    """Same hawk as desert.py (body along -Y = forward), wings and tail now visible from both sides."""
    sphere(m, P("8A5A36"), (0, 0, 0), 0.7, scl=(0.9, 1.8, 0.8), seg=10, part="Body")
    sphere(m, P("F0E2C8"), (0, -1.15, 0.2), 0.48, seg=8, part="Head")
    prism(m, P(GOLD), [(-0.18, 0), (0.18, 0), (0, 0.5)], 0.2, loc=(0, -1.6, 0.15), rot=(90, 0, 180), part="Beak")
    for sx in (-1, 1):
        slab(m, P("6E452A"), [(0, 0.3, 0.1), (sx * 3.2, 0.9, 0.5), (sx * 2.6, -0.3, 0.3), (0, -0.4, 0.1)], 0.08, "Wing")
    slab(m, P("6E452A"), [(-0.6, 1.0, 0.03), (0.6, 1.0, 0.03), (0.9, 2.4, 0.03), (-0.9, 2.4, 0.03)], 0.06, "Tail")


bpy.ops.wm.read_factory_settings(use_empty=True)
m = L.Model("D_Hawk", at=(0, 0, 0))
D_Hawk(m)
objs = L.realize([m], PACK)
info = {}
for o in objs:
    part = o.name.split("__")[1] if "__" in o.name else o.name
    vs = [o.matrix_world @ v.co for v in o.data.vertices]
    mn = [min(v[i] for v in vs) for i in range(3)]
    mx = [max(v[i] for v in vs) for i in range(3)]
    info[part] = {"name": o.name, "faces": len(o.data.polygons), "min": [round(x, 4) for x in mn], "max": [round(x, 4) for x in mx]}
    print("OBJ", o.name, "faces", len(o.data.polygons), "min", info[part]["min"], "max", info[part]["max"])
path = os.path.join(HERE, PACK + ".fbx")
L.export_fbx(objs, path)
print("EXPORTED", path, os.path.getsize(path))
out = {"pack": PACK, "objects": info}
if "--upload" in argv:
    op = L.upload_model(path, "W1 HawkFix 2026-10-14", "Desert hawk with two-sided wings and tail (World 1 bug sweep, 2026-10-14).")
    if "error" in op:
        print("UPLOAD-ERR", op.get("error"), str(op.get("body"))[:300])
    else:
        res = L.poll(op, tries=40, wait=3.0)
        aid = (res.get("response") or {}).get("assetId")
        print("ASSET", aid)
        out["assetId"] = aid
json.dump(out, open(os.path.join(HERE, "hawk_fix.json"), "w"), indent=1)
print("DONE")
