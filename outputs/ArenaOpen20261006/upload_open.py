import sys, os, json
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
HERE = r"C:\Users\wikto\Desktop\Roblox Gra\outputs\ArenaOpen20261006"
op = L.upload_model(os.path.join(HERE, "fbx", "AR_ArenaOpen.fbx"), "BumperArena AR_ArenaOpen", "Open-rim arena floor (r45) + island with a full void ring (2026-10-06). Ref__Origin = arena centre.")
if "error" in op: print("UPLOAD-ERR", op.get("error"), str(op.get("body"))[:300])
else:
    res = L.poll(op, tries=40, wait=3.0)
    aid = (res.get("response") or {}).get("assetId")
    json.dump({"AR_ArenaOpen": str(aid)}, open(os.path.join(HERE, "uploads.json"), "w"))
    print("RESULT", aid)
    if aid: L.registry_add({"pack": "BumperArena AR_ArenaOpen 2026-10-06", "file": "outputs\\ArenaOpen20261006\\fbx\\AR_ArenaOpen.fbx", "assetId": str(aid), "date": "2026-10-06"})
