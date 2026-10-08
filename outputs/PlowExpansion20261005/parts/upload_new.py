# upload_new.py - uploads the rebalance packs Blades_C / Engines_C / Gears_C (45 parts) via Open Cloud; records them in uploads.json.
# usage: blender -b --factory-startup -P upload_new.py
import sys, os, json, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
PACKS = {"Blades_C": "Snowplow blades, rebalance mid-band parts", "Engines_C": "Snowplow engines, rebalance mid-band parts", "Gears_C": "Snowplow gear sets, rebalance mid-band parts"}
upl_path = os.path.join(HERE, "uploads.json")
uploads = json.load(open(upl_path)) if os.path.exists(upl_path) else {}
for pack, desc in PACKS.items():
    if uploads.get(pack, {}).get("assetId"): print("SKIP", pack, uploads[pack]["assetId"]); continue
    res = {"error": "none"}
    for attempt in range(3):
        op = L.upload_model(os.path.join(HERE, "fbx", pack + ".fbx"), "PlowParts " + pack, desc + " (Rebalance 2026-10-05). Ref__Origin marker at pack origin.")
        if "error" in op: print("UPLOAD-ERR", pack, op); time.sleep(5 * (attempt + 1)); continue
        r = L.poll(op, tries=40, wait=3.0)
        aid = (r.get("response") or {}).get("assetId")
        if aid: res = {"assetId": str(aid), "operationId": r.get("operationId") or op.get("operationId")}; break
        time.sleep(5 * (attempt + 1))
    uploads[pack] = res
    json.dump(uploads, open(upl_path, "w"), indent=1)
    print("RESULT", pack, res.get("assetId") or "FAILED")
    if res.get("assetId"): L.registry_add({"pack": "PlowParts_" + pack, "file": "outputs/PlowExpansion20261005/parts/fbx/%s.fbx" % pack, "assetId": res["assetId"], "date": "2026-10-05"})
