import json,pathlib,shutil
from PIL import Image
pack=pathlib.Path(r"C:\Users\wikto\Desktop\Roblox Gra\outputs\NewShovelIcons20261004")
data=json.loads((pack/"generation-results.json").read_text(encoding="utf-8-sig"))
for d in ["originals","icons","references"]: (pack/d).mkdir(exist_ok=True)
out=[]
for item in data:
    source=pathlib.Path(item["source"])
    image=Image.open(source)
    assert image.mode=="RGBA", (item["name"],image.mode)
    assert image.getchannel("A").getextrema()[0]==0
    shutil.copy2(source,pack/"originals"/(item["slug"]+".png"))
    shutil.copy2(item["reference"],pack/"references"/(item["slug"]+".png"))
    target=pack/"icons"/(item["slug"]+".png")
    # Match the existing 512px inventory icon footprint; retain alpha and originals.
    small=image.resize((512,512),Image.Resampling.LANCZOS)
    small.save(target,optimize=True)
    check=Image.open(target); alpha=check.getchannel("A")
    assert check.size==(512,512) and check.mode=="RGBA" and alpha.getextrema()[0]==0
    out.append({"name":item["name"],"slug":item["slug"],"path":str(target),"source":str(source),"size":list(check.size),
        "alphaRange":list(alpha.getextrema()),"alphaBounds":alpha.getbbox(),"bytes":target.stat().st_size})
(pack/"assets.json").write_text(json.dumps(out,indent=2),encoding="utf-8")
print(json.dumps({"count":len(out),"totalBytes":sum(x["bytes"] for x in out),"icons":[{"name":x["name"],"bounds":x["alphaBounds"]} for x in out]}))

