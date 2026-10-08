# upload_packs.py - upload the 14 egg FBX packs (Open Cloud) + registry + manifest (Claude, 2026-10-05).
#   blender -b --factory-startup -P upload_packs.py [-- --manifest-only]
# Resumable: finished uploads are kept in uploads.json and skipped. Never prints the API key.
import sys, os, json, time, glob
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib
ROOT = r"C:\Users\wikto\Desktop\Roblox Gra"
EGGS = ["SnowyEgg", "DesertEgg", "CursedEgg", "CrystalEgg", "RetroEgg", "JungleEgg", "AbsoluteZeroEgg", "BlossomEgg",
        "CandyEgg", "PearlEgg", "ToyCapsuleEgg", "GearEgg", "CloudEgg", "StarEgg", "VerityEgg"]  # VerityEgg: paid shop egg, 2026-10-06
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
UP = os.path.join(HERE, "uploads.json")
DATE = {"VerityEgg": "2026-10-06"}
ups = json.load(open(UP)) if os.path.exists(UP) else {}

def transient(r):
    return isinstance(r, dict) and r.get("error") in (408, 425, 429, 500, 502, 503, 504)

def upload(egg):
    path = os.path.join(HERE, "packs", egg + "_Pets.fbx")
    data = json.load(open(os.path.join(HERE, "data", egg + ".json")))
    display = "Pets %s %s" % (egg, DATE.get(egg, "2026-10-05"))
    desc = "Pet models (rebuild 2026-10-05) for %s: %s. Import as ReplicatedStorage.PetModelOverrides.<pet name>." % (egg, ", ".join(d["name"] for d in data))
    last = None
    for attempt in range(3):
        try:
            op = w2lib.upload_model(path, display, desc)
            if "error" in op:
                last = op; print("UPLOAD", egg, "attempt", attempt + 1, "error", op.get("error"), str(op.get("body"))[:200])
                if transient(op): time.sleep(5 * (attempt + 1)); continue
                return None, op
            res = w2lib.poll(op, tries=40, wait=2.5)
            aid = (res.get("response") or {}).get("assetId")
            if aid: return str(aid), res
            last = res; print("UPLOAD", egg, "attempt", attempt + 1, "no assetId yet:", {k: res.get(k) for k in ("done", "error", "operationId")})
            if res.get("operationId") and not res.get("error"):
                res2 = w2lib.poll({"operationId": res["operationId"], "done": False}, tries=40, wait=4)
                aid = (res2.get("response") or {}).get("assetId")
                if aid: return str(aid), res2
                return None, {"operationId": res.get("operationId"), "note": "upload accepted but no assetId after polling"}
            time.sleep(5 * (attempt + 1))
        except Exception as e:
            last = {"exception": repr(e)[:300]}; print("UPLOAD", egg, "attempt", attempt + 1, "exception", repr(e)[:200]); time.sleep(5 * (attempt + 1))
    return None, last

if "--manifest-only" not in argv:
    for egg in EGGS:
        if egg in ups and ups[egg].get("assetId"): print("SKIP", egg, ups[egg]["assetId"]); continue
        aid, res = upload(egg)
        if aid:
            rel = os.path.relpath(os.path.join(HERE, "packs", egg + "_Pets.fbx"), ROOT)
            ups[egg] = {"assetId": aid, "file": rel, "pack": "Pets %s %s" % (egg, DATE.get(egg, "2026-10-05"))}
            w2lib.registry_add({"pack": "Pets %s %s" % (egg, DATE.get(egg, "2026-10-05")), "file": rel, "assetId": aid, "date": DATE.get(egg, "2026-10-05")})
            print("UPLOADED", egg, aid)
        else:
            ups[egg] = {"assetId": None, "error": res}
            print("FAILED", egg, str(res)[:300])
        json.dump(ups, open(UP, "w"), indent=1)

# manifest
pets, packs = [], []
for egg in EGGS:
    data = json.load(open(os.path.join(HERE, "data", egg + ".json")))
    u = ups.get(egg, {})
    packs.append({"egg": egg, "pack": "Pets %s 2026-10-05" % egg, "file": data[0].get("pack"), "assetId": u.get("assetId"),
                  "marker": "Ref__Origin__FF00FFNE at (0,0,0)", "pets": [d["name"] for d in data]})
    for d in data:
        d = dict(d); d["assetId"] = u.get("assetId"); pets.append(d)
man = {"date": "2026-10-05", "units": "1 Blender unit = 1 stud; front = Blender -Y; up = +Z; FBX exported via w2lib.export_fbx",
       "naming": "<Key>__<Part>__<RRGGBB><MAT>[Tnn]; Model = Key (pet name without spaces/hyphens); load as ReplicatedStorage.PetModelOverrides.<name>",
       "roles": "part prefixes Body/Belly/Mark/Accent/Eye/Shine/Mouth/Nose/Blush/Glow (golden: Body FFC837, Belly FFECA0, Mark C98A1E, Accent FFAE2E unless already gold)",
       "packs": packs, "pets": pets}
json.dump(man, open(os.path.join(HERE, "manifest.json"), "w"), indent=1)
print("MANIFEST", len(pets), "pets", sum(1 for p in packs if p["assetId"]), "packs with assetId")
