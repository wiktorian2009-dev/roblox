# upload_pits.py - uploads AR_IslandPits.fbx (Open Cloud via w2lib) and records the asset id in uploads.json.
# usage: blender -b --factory-startup -P upload_pits.py
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L

path = os.path.join(HERE, "fbx", "AR_IslandPits.fbx")
upl = os.path.join(HERE, "uploads.json")
uploads = json.load(open(upl)) if os.path.exists(upl) else {}
if uploads.get("AR_IslandPits", {}).get("assetId"):
    print("SKIP", uploads["AR_IslandPits"]["assetId"])
else:
    op = L.upload_model(path, "BumperArena AR_IslandPits", "Snowplow Bumper Arena island Rock + Snow with a void pit behind each exit (2026-10-06). Ref__Origin = arena centre.")
    if "error" in op:
        print("UPLOAD-ERR", op.get("error"), str(op.get("body"))[:300])
    else:
        res = L.poll(op, tries=40, wait=3.0)
        aid = (res.get("response") or {}).get("assetId")
        uploads["AR_IslandPits"] = {"assetId": str(aid) if aid else None, "operationId": res.get("operationId") or op.get("operationId")}
        json.dump(uploads, open(upl, "w"), indent=1)
        print("RESULT", aid)
        if aid:
            L.registry_add({"pack": "BumperArena AR_IslandPits 2026-10-06", "file": "outputs\\ArenaVoid20261006\\fbx\\AR_IslandPits.fbx", "assetId": str(aid), "date": "2026-10-06"})
