# upload_w1.py - uploads World 1 remaster packs (Open Cloud via w2lib) and records uploads.json + manifest.json.
# usage: blender -b --factory-startup -P upload_w1.py -- --packs W1_Desert[,W1_Cursed...] [--force]
import sys, os, json, time, glob
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender"); sys.path.insert(0, HERE)
import w2lib as L
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def opt(k, d=None): return argv[argv.index(k) + 1] if k in argv else d
packs = (opt("--packs") or "").split(",")
upl_path = os.path.join(HERE, "uploads.json")
uploads = json.load(open(upl_path)) if os.path.exists(upl_path) else {}


def upload(pack):
    path = os.path.join(HERE, "fbx", pack + ".fbx"); last = None
    for attempt in range(3):
        try: op = L.upload_model(path, "PlowParts " + pack, "Snowplow BODY shells %s (task 7, 2026-10-05). Ref__Origin marker at pack origin; see manifest." % pack)
        except Exception as e: op = {"error": "exception", "body": repr(e)[:300]}
        if "error" in op:
            last = op; print("UPLOAD-ERR", pack, attempt, op.get("error"), str(op.get("body"))[:300])
            if str(op.get("error")) in ("400", "401", "403"): break
            time.sleep(5 * (attempt + 1) ** 2); continue
        res = L.poll(op, tries=40, wait=3.0)
        aid = (res.get("response") or {}).get("assetId")
        if aid: return {"assetId": str(aid), "operationId": res.get("operationId") or op.get("operationId")}
        last = res; print("POLL-ERR", pack, attempt, json.dumps(res)[:400]); time.sleep(5 * (attempt + 1) ** 2)
    return {"error": last}


for pack in packs:
    if not pack: continue
    if uploads.get(pack, {}).get("assetId") and "--force" not in argv: print("SKIP", pack, uploads[pack]["assetId"]); continue
    r = upload(pack); uploads[pack] = r
    json.dump(uploads, open(upl_path, "w"), indent=1)
    print("RESULT", pack, r.get("assetId") or "FAILED")
    if r.get("assetId"):
        L.registry_add({"pack": "PlowParts " + pack + " 2026-10-05", "file": "outputs\\Body20261005\\fbx\\%s.fbx" % pack, "assetId": r["assetId"], "date": "2026-10-05"})

models = {}
for f in glob.glob(os.path.join(HERE, "stats_*.json")):
    for name, s in json.load(open(f)).items():
        models[name] = {"pack": s["pack"], "assetId": uploads.get(s["pack"], {}).get("assetId"), "at": s["at"], "tris": s["tris"], "objects": s["objects"],
                        "bboxMin": s["min"], "bboxMax": s["max"], "size": s["size"]}
man = {"date": "2026-10-05", "units": "1 Blender unit = 1 stud; up = +Z; Studio maps Blender (x,y,z) -> Roblox local (-x, z, y); front = Blender -Y = Roblox -Z (LookVector)",
       "origin": "floor-level centre of each model; packs place models at (120*(i+1), 0, 0)",
       "packs": {p: uploads[p] for p in uploads}, "models": models}
json.dump(man, open(os.path.join(HERE, "manifest.json"), "w"), indent=1)
print("MANIFEST", len(models))
