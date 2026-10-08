# upload.py - uploads the 3 arena packs (Open Cloud via w2lib), registers them and writes manifest.json.
# usage: blender -b --factory-startup -P upload.py -- [--manifest-only]
import sys, os, json, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender"); sys.path.insert(0, HERE)
import w2lib as L

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PACKS = ["AR_Arena", "AR_Island", "AR_Props"]
DESC = {"AR_Arena": "Snowplow Bumper Arena: floor, bumper walls, exit gates, stands, scoreboard crown, light towers",
        "AR_Island": "Snowplow Bumper Arena: sky island + practice ring",
        "AR_Props": "Snowplow Bumper Arena props: target, vehicle bumper, portal, trophy, lamp, banner, snowbank"}
stats = json.load(open(os.path.join(HERE, "stats.json")))
upl_path = os.path.join(HERE, "uploads.json")
uploads = json.load(open(upl_path)) if os.path.exists(upl_path) else {}


def upload(pack):
    path = os.path.join(HERE, "fbx", pack + ".fbx"); last = None
    for attempt in range(3):
        try: op = L.upload_model(path, "BumperArena " + pack, DESC[pack] + " (2026-10-05). Ref__Origin marker at pack origin; see manifest.")
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


if "--manifest-only" not in argv:
    for pack in PACKS:
        if uploads.get(pack, {}).get("assetId"): print("SKIP", pack, uploads[pack]["assetId"]); continue
        r = upload(pack); uploads[pack] = r
        json.dump(uploads, open(upl_path, "w"), indent=1)
        print("RESULT", pack, r.get("assetId") or "FAILED")
        if r.get("assetId"):
            L.registry_add({"pack": "BumperArena " + pack + " 2026-10-05", "file": "outputs\\Arena20261005\\fbx\\%s.fbx" % pack,
                            "assetId": r["assetId"], "date": "2026-10-05"})

models = {}
for name, s in stats.items():
    models[name] = {"pack": s["pack"], "assetId": uploads.get(s["pack"], {}).get("assetId"), "at": s["at"], "tris": s["tris"],
                    "objects": s["objects"], "parts": [p.split("__")[0] + ":" + p.split("__")[1] for p in s["parts"]],
                    "bboxMin": s["min"], "bboxMax": s["max"], "size": s["size"]}
man = {"date": "2026-10-05", "units": "1 Blender unit = 1 stud; up = +Z; Studio maps Blender (x,y,z) -> Roblox local (-x, z, y)",
       "origin": "ring models + Island: arena centre (ArenaConfig.Center) at floor top; PracticeRing: practice centre; props: floor-level centre",
       "packs": [{"pack": p, "file": "fbx/%s.fbx" % p, "assetId": uploads.get(p, {}).get("assetId")} for p in PACKS], "models": models}
json.dump(man, open(os.path.join(HERE, "manifest.json"), "w"), indent=1)
print("MANIFEST", len(models))
