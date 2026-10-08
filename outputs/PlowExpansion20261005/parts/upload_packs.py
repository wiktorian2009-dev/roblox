# upload_packs.py - uploads the 6 FBX packs (Open Cloud via w2lib), registers them and writes manifest.json.
# usage: blender -b --factory-startup -P upload_packs.py -- [--manifest-only]
import sys, os, json, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PACKS = ["Blades_A", "Blades_B", "Engines_A", "Engines_B", "Gears_A", "Gears_B"]
DESC = {"Blades_A": "Snowplow blades, bands 1-7", "Blades_B": "Snowplow blades, bands 8-14", "Engines_A": "Snowplow engines, bands 1-7",
        "Engines_B": "Snowplow engines, bands 8-14", "Gears_A": "Snowplow gear sets, bands 1-7", "Gears_B": "Snowplow gear sets, bands 8-14"}
stats = json.load(open(os.path.join(HERE, "stats_all.json")))
upl_path = os.path.join(HERE, "uploads.json")
uploads = json.load(open(upl_path)) if os.path.exists(upl_path) else {}


def upload(pack):
    path = os.path.join(HERE, "fbx", pack + ".fbx")
    last = None
    for attempt in range(3):
        try:
            op = L.upload_model(path, "PlowParts " + pack, DESC[pack] + " (Plow Expansion 2026-10-05). Ref__Origin marker at pack origin; see manifest for mount offsets.")
        except Exception as e:
            op = {"error": "exception", "body": repr(e)[:300]}
        if "error" in op:
            last = op; print("UPLOAD-ERR", pack, attempt, op.get("error"), str(op.get("body"))[:300])
            if str(op.get("error")) in ("400", "401", "403"): break
            time.sleep(5 * (attempt + 1) ** 2); continue
        res = L.poll(op, tries=40, wait=3.0)
        aid = (res.get("response") or {}).get("assetId")
        if aid:
            return {"assetId": str(aid), "operationId": res.get("operationId") or op.get("operationId")}
        last = res; print("POLL-ERR", pack, attempt, json.dumps(res)[:400])
        time.sleep(5 * (attempt + 1) ** 2)
    return {"error": last}


if "--manifest-only" not in argv:
    for pack in PACKS:
        if uploads.get(pack, {}).get("assetId"): print("SKIP", pack, uploads[pack]["assetId"]); continue
        r = upload(pack); uploads[pack] = r
        json.dump(uploads, open(upl_path, "w"), indent=1)
        print("RESULT", pack, r.get("assetId") or "FAILED")
        if r.get("assetId"):
            L.registry_add({"pack": "PlowParts_" + pack, "file": "outputs/PlowExpansion20261005/parts/fbx/%s.fbx" % pack, "assetId": r["assetId"], "date": "2026-10-05"})

cat = json.load(open(os.path.join(HERE, "..", "data", "catalog_visual.json"), encoding="utf-8"))
models = []
for e in cat:
    s = stats.get(e["model"])
    if not s: continue
    models.append({"id": e["id"], "model": e["model"], "slot": e["slot"], "band": e["band"], "rarity": e["rarity"], "archetype": e["archetype"],
                   "pack": s["pack"], "packFile": "fbx/%s.fbx" % s["pack"], "assetId": uploads.get(s["pack"], {}).get("assetId"),
                   "at": s["at"], "tris": s["tris"], "objectCount": s["objects"], "neonObjects": s["neon"],
                   "objects": [{"part": p.split("__")[0], "code": p.split("__")[1]} for p in s["parts"]],
                   "bboxMin": s["min"], "bboxMax": s["max"], "size": s["size"], "notes": ""})
man = {"date": "2026-10-05", "units": "1 Blender unit = 1 stud; front = -Y (Roblox -Z); up = +Z (Roblox +Y)",
       "origin": "every object origin = its model's mount point (Blade: bracket back-centre; Engine: bottom-centre; Gear: chassis ground centre)",
       "refMarker": "Ref__Origin__FF00FFNE (0.2 cube) at pack world origin; model mount point = Ref position + at (at is in Blender coords; Roblox offset = (at.x, at.z, at.y) since Roblox X = Blender X, Roblox Y = Blender Z, Roblox Z = Blender Y)",
       "packs": [{"pack": p, "file": "fbx/%s.fbx" % p, "assetId": uploads.get(p, {}).get("assetId"), "models": sum(1 for m in models if m["pack"] == p),
                  "tris": sum(m["tris"] for m in models if m["pack"] == p)} for p in PACKS],
       "models": models}
json.dump(man, open(os.path.join(HERE, "manifest.json"), "w"), indent=1)
print("MANIFEST", len(models))
