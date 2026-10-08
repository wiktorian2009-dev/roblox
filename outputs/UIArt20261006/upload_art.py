# upload_art.py - uploads the GUI PNGs as Decal assets via Open Cloud (w2lib key handling); writes uploads.json {name: decalId}.
# The image id used in GUIs is resolved in Studio (decal -> image) afterwards.
import sys, os, json, uuid, urllib.request, time
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
HERE = os.path.dirname(os.path.abspath(__file__))
UP = os.path.join(HERE, "uploads.json")
ups = json.load(open(UP)) if os.path.exists(UP) else {}
only = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def upload(path, name):
    bnd = "----UI" + uuid.uuid4().hex; CR = b"\r\n"
    req = json.dumps({"assetType": "Decal", "displayName": ("SnowUI " + name)[:50], "description": "Snowy cartoon GUI art (2026-10-06)",
                      "creationContext": {"creator": {"userId": L.CREATOR_USER_ID}}}).encode()
    data = open(path, "rb").read()
    body = (b"--" + bnd.encode() + CR + b'Content-Disposition: form-data; name="request"' + CR + b"Content-Type: application/json" + CR + CR + req + CR +
            b"--" + bnd.encode() + CR + ('Content-Disposition: form-data; name="fileContent"; filename="%s"' % os.path.basename(path)).encode() + CR +
            b"Content-Type: image/png" + CR + CR + data + CR + b"--" + bnd.encode() + b"--" + CR)
    r = urllib.request.Request("https://apis.roblox.com/assets/v1/assets", data=body, method="POST",
                               headers={"x-api-key": L._key(), "Content-Type": "multipart/form-data; boundary=" + bnd})
    try: return json.loads(urllib.request.urlopen(r, timeout=120).read())
    except urllib.error.HTTPError as e: return {"error": e.code, "body": e.read().decode("utf-8", "replace")[:300]}
for f in sorted(os.listdir(os.path.join(HERE, "png"))):
    name = f[:-4]
    if only and name not in only: continue
    if ups.get(name): continue
    op = upload(os.path.join(HERE, "png", f), name)
    if "error" in op: print("ERR", name, op["error"], op.get("body")); break
    res = L.poll(op, tries=30, wait=2.0)
    aid = (res.get("response") or {}).get("assetId")
    print("OK", name, aid); ups[name] = aid
    json.dump(ups, open(UP, "w"), indent=1)
print("DONE", len(ups))
