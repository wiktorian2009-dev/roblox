import base64, hashlib, json, re, shutil
from pathlib import Path

ROOT = Path(r"C:\Users\wikto\Desktop\Roblox Gra").resolve()
OUT = ROOT / "outputs" / "NewFeatureSnowyUI20261005"
UPGRADES = ROOT / "outputs" / "UpgradeIconsRemaster20261005"
data = json.loads((OUT / "final-sources.json").read_text(encoding="utf-8"))
assert len(data["scripts"]) == 9 and data["balanceFlagRemoved"] and data["ownerRemoved"]
manifest = []
for item in data["scripts"]:
    target = (ROOT / item["file"]).resolve()
    assert target.is_relative_to(ROOT / "game")
    source = item["source"]
    assert isinstance(source, str) and len(source) > 100 and item["compiled"]
    previous = None
    if target.exists():
        old = target.read_bytes()
        backup = OUT / "before-mirrors" / item["file"]
        backup.parent.mkdir(parents=True, exist_ok=True)
        if not backup.exists():
            backup.write_bytes(old)
        previous = hashlib.sha256(backup.read_bytes()).hexdigest()
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(source)
    payload = source.encode("utf-8")
    assert target.read_bytes() == payload
    record = {k: v for k, v in item.items() if k != "source"}
    record.update(sha256=hashlib.sha256(payload).hexdigest(), utf8Bytes=len(payload), previousMirrorSha256=previous)
    manifest.append(record)
(OUT / "source-hashes.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
(OUT / "final-gui-properties.json").write_text(json.dumps(data["properties"], indent=2), encoding="utf-8")
upgrade_data = dict(data)
upgrade_data["scripts"] = [s for s in data["scripts"] if s["key"] in ("UpgradeIconArt", "UpgradeTreeClient")]
(UPGRADES / "final-sources.json").write_text(json.dumps(upgrade_data, indent=2), encoding="utf-8")
(UPGRADES / "source-hashes.json").write_text(json.dumps([s for s in manifest if s["key"] in ("UpgradeIconArt", "UpgradeTreeClient")], indent=2), encoding="utf-8")
(UPGRADES / "final-gui-properties.json").write_text(json.dumps(data["properties"], indent=2), encoding="utf-8")

# Store native tool captures unchanged, not re-rendered or image edited.
shot_path = (OUT / "screenshot-data.json").resolve()
assert shot_path.parent == OUT.resolve()
shots = json.loads(shot_path.read_text(encoding="utf-8"))
(OUT / "screenshots").mkdir(exist_ok=True)
for name, shot in shots.items():
    payload = base64.b64decode(shot["data"])
    if payload.startswith(b"\x89PNG\r\n\x1a\n"):
        suffix = ".png"
    elif payload.startswith(b"\xff\xd8\xff"):
        suffix = ".jpg"
    else:
        raise AssertionError("Unexpected native screenshot format: " + shot["mimeType"])
    (OUT / "screenshots" / (name + suffix)).write_bytes(payload)
shot_path.unlink()

# Keep the guarded one-time installer consistent with the tested helper.
installer = OUT / "install-edit.luau"
text = installer.read_text(encoding="utf-8")
source = next(s["source"] for s in data["scripts"] if s["key"] == "FeatureUIArt")
lines = text.splitlines()
ix = [i for i, line in enumerate(lines) if line.startswith("local moduleSource=")]
assert len(ix) == 1
lines[ix[0]] = "local moduleSource=" + json.dumps(source, ensure_ascii=False)
installer.write_text("\n".join(lines) + "\n", encoding="utf-8")
patches = json.loads((OUT / "patches.json").read_text(encoding="utf-8"))
assert not any(s.get("sourceKey") == "PassConfig" for s in patches["scripts"])
patches["scripts"].append({
    "sourceKey": "PassConfig", "target": "ReplicatedStorage.PassConfig",
    "replacements": [
        {"old": "rbxassetid://14828805856", "new": "rbxassetid://118980978543857", "label": "SnowBoost icon"},
        {"old": "rbxassetid://17023282679", "new": "rbxassetid://109621099381649", "label": "StarterPack icon"},
        {"old": "rbxassetid://14829149871", "new": "rbxassetid://106686963600706", "label": "PremiumWheels icon"}
    ]
})
# Use actual before/after icon literals rather than guessing historical art.
before = json.loads((OUT / "before-sources.json").read_text(encoding="utf-8"))
before_cfg = before.get("PassConfig")
if isinstance(before_cfg, dict):
    before_cfg = before_cfg["source"]
elif before_cfg is None:
    raise AssertionError("Inspect before-source format")
after_cfg = next(s["source"] for s in data["scripts"] if s["key"] == "PassConfig")
old_icons = re.findall(r'Icon\s*=\s*"(rbxassetid://\d+)"', before_cfg)
new_icons = re.findall(r'Icon\s*=\s*"(rbxassetid://\d+)"', after_cfg)
assert len(old_icons) == len(new_icons) == 3
for replacement, old, new in zip(patches["scripts"][-1]["replacements"], old_icons, new_icons):
    replacement["old"], replacement["new"] = old, new
patches["description"] = "Six scripts: guarded presentation-only replacement pairs used by the completed Edit installation. Final FeatureUIArt source is in FeatureUIArt.luau; already-installed guards prevent accidental replay."
(OUT / "patches.json").write_text(json.dumps(patches, indent=2), encoding="utf-8")
print(json.dumps({"mirrorsWritten": len(manifest), "screenshotsSaved": len(shots), "installerUpdated": True, "upgradeIds": 138}))

