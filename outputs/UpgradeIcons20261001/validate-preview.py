from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math
root=Path(r"C:\Users\wikto\Desktop\Roblox Gra\outputs\UpgradeIcons20261001")
m=json.loads((root/"manifest.json").read_text(encoding="utf-8-sig"))
items=[j for j in m["jobs"] if (root/j["filename"]).exists()]
report=[]
w=1020
cols=6
cell=170
rows=math.ceil(len(items)/cols)
sheet=Image.new("RGB",(w,rows*195),(23,29,46))
draw=ImageDraw.Draw(sheet)
for i,j in enumerate(items):
 im=Image.open(root/j["filename"])
 alpha=im.getchannel("A") if "A" in im.getbands() else None
 bbox=alpha.point(lambda v: 255 if v > 16 else 0).getbbox() if alpha else None
 report.append({"id":j["upgradeId"],"filename":j["filename"],"size":im.size,"mode":im.mode,"alphaExtrema":alpha.getextrema() if alpha else None,"bbox":bbox,"clearEdges":bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<im.width and bbox[3]<im.height})
 thumb=im.copy()
 thumb.thumbnail((150,150))
 x=(i%cols)*cell+(cell-thumb.width)//2
 y=(i//cols)*195+8
 sheet.paste(thumb,(x,y),thumb if thumb.mode=="RGBA" else None)
 draw.text(((i%cols)*cell+8,(i//cols)*195+162),j["upgradeId"],fill="white")
 draw.text(((i%cols)*cell+8,(i//cols)*195+176),j["filename"][:23],fill=(162,183,208))
sheet.save(root/"preview-grid.png")
(root/"qa.json").write_text(json.dumps(report,indent=2))
print(json.dumps({"generated":len(report),"transparent":sum(r["alphaExtrema"]==[0,255] or r["alphaExtrema"]==(0,255) for r in report),"clearEdges":sum(bool(r["clearEdges"]) for r in report),"bad":[r for r in report if not r["clearEdges"] or r["alphaExtrema"]!=(0,255)]}))


