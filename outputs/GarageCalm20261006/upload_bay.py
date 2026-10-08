# upload_bay.py - uploads Pack_BayOpen.fbx (Open Cloud via w2lib); records the asset id in uploads.json.
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
path = os.path.join(HERE, "fbx", "Pack_BayOpen.fbx")
upl = os.path.join(HERE, "uploads.json")
uploads = json.load(open(upl)) if os.path.exists(upl) else {}
if uploads.get("Pack_BayOpen", {}).get("assetId"):
    print("SKIP", uploads["Pack_BayOpen"]["assetId"])
else:
    op = L.upload_model(path, "SharedGarage Pack_BayOpen", "Open-air garage bay shell 48x45, matte snowy style (2026-10-06). Ref__Origin = bay floor centre.")
    if "error" in op:
        print("UPLOAD-ERR", op.get("error"), str(op.get("body"))[:300])
    else:
        res = L.poll(op, tries=40, wait=3.0)
        aid = (res.get("response") or {}).get("assetId")
        uploads["Pack_BayOpen"] = {"assetId": str(aid) if aid else None}
        json.dump(uploads, open(upl, "w"), indent=1)
        print("RESULT", aid)
        if aid:
            L.registry_add({"pack": "SharedGarage Pack_BayOpen 2026-10-06", "file": "outputs\\GarageCalm20261006\\fbx\\Pack_BayOpen.fbx", "assetId": str(aid), "date": "2026-10-06"})
