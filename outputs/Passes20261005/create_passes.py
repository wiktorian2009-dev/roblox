# create_passes.py - creates the three game passes for universe 10768102325 through Open Cloud, NOT for sale (task 8).
# Idempotent: an existing pass with the same name is reused. Writes passes.json with the real ids.
# Sales stay OFF on purpose: the published game does not contain the grant code yet, so a purchase now would give nothing.
# wiktor turns sales on (and sets the price) in the Creator Dashboard after saving + publishing.
import json, os, urllib.request, uuid
HERE = os.path.dirname(os.path.abspath(__file__))
UNIVERSE = 10768102325
KEY = os.environ["ROBLOX_API_KEY"]
BASE = "https://apis.roblox.com/game-passes/v1/universes/%d/game-passes" % UNIVERSE
PASSES = [
    ("SnowBoost", "1.5x Snow", "Earn 1.5x Snow forever from clearing snow and finished jobs (and treasures, chests and quest Snow). Stacks once with upgrades, pets and boosts.", "icon_snow15.png", 10),
    ("StarterPack", "Starter Pack", "Start strong with the full Haunted set! Get all 10 Haunted plow parts: 3 blades, 3 engines, 3 sets of wheels and the Grave Hauler body. The parts stay yours forever. One-time purchase.", "icon_starterpack.png", 15),
    ("PremiumWheels", "Aurora Wheels", "Premium snow wheels with icy alloy hubs and aurora rims: great grip and turning and strong early-to-mid pushing power. Yours forever.", "icon_aurorawheels.png", 50),
]

def req(method, url, body=None, headers=None):
    r = urllib.request.Request(url, data=body, method=method, headers=dict({"x-api-key": KEY}, **(headers or {})))
    try:
        with urllib.request.urlopen(r) as resp: return resp.status, json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:500]

def multipart(fields, files):
    b = uuid.uuid4().hex; out = b""
    for k, v in fields.items():
        out += ("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n" % (b, k, v)).encode()
    for k, (fn, data, ct) in files.items():
        out += ("--%s\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\nContent-Type: %s\r\n\r\n" % (b, k, fn, ct)).encode() + data + b"\r\n"
    out += ("--%s--\r\n" % b).encode()
    return out, "multipart/form-data; boundary=" + b

path = os.path.join(HERE, "passes.json")
known = json.load(open(path)) if os.path.exists(path) else {}
st, existing = req("GET", BASE + "?pageSize=50")
print("list", st, existing if st != 200 else len(existing.get("gamePasses", [])))
byname = {g.get("name"): g for g in (existing.get("gamePasses", []) if st == 200 else [])}
for key, name, desc, icon, price in PASSES:
    if key in known and known[key].get("id"): print("SKIP", key, known[key]["id"]); continue
    if name in byname:
        g = byname[name]; known[key] = {"id": g.get("gamePassId") or g.get("id"), "name": name, "defaultPrice": price, "reused": True}; print("REUSE", key, known[key]["id"]); continue
    body, ct = multipart({"name": name, "description": desc, "isForSale": "false"}, {"imageFile": (icon, open(os.path.join(HERE, "renders", icon), "rb").read(), "image/png")})
    st, res = req("POST", BASE, body, {"Content-Type": ct})
    print("CREATE", key, st, res)
    if st in (200, 201) and isinstance(res, dict):
        known[key] = {"id": res.get("gamePassId") or res.get("id"), "name": name, "defaultPrice": price, "response": res}
    json.dump(known, open(path, "w"), indent=1)
json.dump(known, open(path, "w"), indent=1)
print("DONE", {k: v.get("id") for k, v in known.items()})
