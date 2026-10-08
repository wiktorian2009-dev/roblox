import base64, hashlib, json
from pathlib import Path
root = Path(r"C:\Users\wikto\Desktop\Roblox Gra").resolve()
out = root / "outputs" / "CleanButtons20261006"
data = json.loads((out / "final-sources.json").read_text(encoding="utf-8"))
records = []
for item in data["scripts"]:
    path = (root / item["file"]).resolve()
    assert path.is_relative_to(root / "game")
    if path.exists():
        backup = out / "before-mirrors" / item["file"]
        backup.parent.mkdir(parents=True, exist_ok=True)
        if not backup.exists():
            backup.write_bytes(path.read_bytes())
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = item["source"].encode("utf-8")
    path.write_bytes(payload)
    records.append({k: v for k, v in item.items() if k != "source"} | {"sha256": hashlib.sha256(payload).hexdigest()})
(out / "source-hashes.json").write_text(json.dumps(records, indent=2), encoding="utf-8")
shotpath = (out / "screenshot-data.json").resolve()
assert shotpath.parent == out.resolve()
shot = json.loads(shotpath.read_text(encoding="utf-8"))
payload = base64.b64decode(shot["data"])
suffix = ".png" if payload.startswith(b"\x89PNG\r\n\x1a\n") else ".jpg"
assert suffix == ".png" or payload.startswith(b"\xff\xd8\xff")
(out / ("preview" + suffix)).write_bytes(payload)
shotpath.unlink()
print(json.dumps({"mirrors": len(records), "screenshot": "preview" + suffix}))

