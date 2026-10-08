from pathlib import Path
import json, zipfile
root=Path(__file__).resolve().parent
manifest=json.loads((root/"generation-manifest.json").read_text(encoding="utf-8-sig"))
files=[j["file"] for j in manifest["icons"]]+["preview-grid.png","README.md","generation-manifest.json","asset-map.json","qa.json","verification.json","TreasureImageIds.lua","TreasureConfig.before.luau","TreasureConfig.after.luau"]
with zipfile.ZipFile(root/"TreasureIcons.zip","w",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for name in files:
        z.write(root/name,arcname=name)
with zipfile.ZipFile(root/"TreasureIcons.zip") as z:
    assert z.testzip() is None
    assert sum(name.startswith("treasure_") and name.endswith(".png") for name in z.namelist())==36
print(json.dumps({"files":len(files),"individualPNGs":36,"zipBytes":(root/"TreasureIcons.zip").stat().st_size}))

