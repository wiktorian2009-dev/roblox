import json, pathlib, shutil
from PIL import Image
root=pathlib.Path(r"C:\Users\wikto\Desktop\Roblox Gra\outputs\UniversalVFX20261003")
data=json.loads((root/"prompts.json").read_text(encoding="utf-8-sig"))
textures=root/"textures"; originals=root/"originals"
textures.mkdir(exist_ok=True); originals.mkdir(exist_ok=True)
report=[]
for item in data["assets"]:
    source=pathlib.Path(item["source"])
    shutil.copy2(source,originals/(item["name"]+".png"))
    image=Image.open(source)
    assert image.mode=="RGBA", (item["name"],image.mode)
    alpha=image.getchannel("A")
    assert alpha.getextrema()[0]==0
    # The user requested small game textures. Preserve the originals and alpha;
    # only change raster resolution for upload, not the generated artwork.
    target=textures/(item["name"]+".png")
    small=image.resize((item["size"],item["size"]),Image.Resampling.LANCZOS)
    small.save(target,optimize=True)
    check=Image.open(target)
    assert check.size==(item["size"],item["size"]) and check.mode=="RGBA"
    assert check.getchannel("A").getextrema()[0]==0
    report.append({"name":item["name"],"source":str(source),"texture":str(target),
      "dimensions":list(check.size),"bytes":target.stat().st_size,
      "alphaRange":list(check.getchannel("A").getextrema()),"bbox":check.getchannel("A").getbbox()})
(root/"assets.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print(json.dumps({"count":len(report),"totalPNGBytes":sum(x["bytes"] for x in report),
  "textures":[{"name":x["name"],"dimensions":x["dimensions"],"bytes":x["bytes"]} for x in report]}))

