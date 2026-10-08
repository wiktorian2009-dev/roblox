from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math, zipfile
root = Path(__file__).resolve().parent
manifest = json.loads((root / "generation-manifest.json").read_text(encoding="utf-8-sig"))
jobs = manifest["icons"]
report = []
cols, cell, row_h, header = 7, 160, 192, 180
sheet = Image.new("RGB", (cols * cell, header + 5 * row_h), (20, 27, 44))
draw = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 12)
    small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 11)
    title = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 25)
except OSError:
    font = small = title = ImageFont.load_default()
biomes = ["Starter", "Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero"]
rarities = ["Common", "Rare", "Epic", "Legendary", "Mythic"]
colors = {"Common": (170,205,240), "Rare": (70,160,255), "Epic": (185,95,255), "Legendary": (255,200,45), "Mythic": (255,95,200)}
draw.text((170,20), "BURIED TREASURES", font=title, fill=(240,246,255))
draw.text((170,62), "35 collectible icons + menu chest | transparent PNG originals", font=font, fill=(170,191,215))
for j in jobs:
    file = root / j["file"]
    if not file.exists():
        report.append({"id": j["id"], "missing": True})
        continue
    im = Image.open(file)
    alpha = im.getchannel("A") if "A" in im.getbands() else None
    bbox = alpha.point(lambda v: 255 if v > 16 else 0).getbbox() if alpha else None
    extrema = alpha.getextrema() if alpha else None
    clear = bool(bbox and bbox[0] > 0 and bbox[1] > 0 and bbox[2] < im.width and bbox[3] < im.height)
    report.append({"id": j["id"], "file": j["file"], "size": list(im.size), "mode": im.mode, "alphaExtrema": list(extrema) if extrema else None, "visibleBounds": list(bbox) if bbox else None, "clearEdges": clear, "bytes": file.stat().st_size})
    if j["id"] == "MenuIcon":
        x, y = 10, 8
        box = 136
    else:
        col, row = biomes.index(j["biome"]), rarities.index(j["rarity"])
        x, y, box = col * cell + 10, header + row * row_h + 8, 140
        draw.rounded_rectangle((col*cell+3,header+row*row_h+3,(col+1)*cell-3,header+(row+1)*row_h-3),radius=10,fill=(29,38,58))
        draw.line((col*cell+14,header+row*row_h+153,(col+1)*cell-14,header+row*row_h+153), fill=colors[j["rarity"]], width=2)
        draw.text((col*cell+10,header+row*row_h+158),j["name"],font=small,fill=(240,246,255))
        draw.text((col*cell+10,header+row*row_h+174),j["rarity"],font=small,fill=colors[j["rarity"]])
    thumb = im.copy()
    thumb.thumbnail((box,box), Image.Resampling.LANCZOS)
    sheet.paste(thumb,(x+(box-thumb.width)//2,y+(box-thumb.height)//2),thumb if thumb.mode=="RGBA" else None)
for i, biome in enumerate(biomes):
    label = "ABS. ZERO" if biome == "AbsoluteZero" else biome.upper()
    draw.text((i*cell+10,header-23),label,font=font,fill=(210,229,252))
sheet.save(root / "preview-grid.png")
(root / "qa.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
bad = [r for r in report if r.get("missing") or not r.get("clearEdges") or r.get("alphaExtrema") != [0,255]]
print(json.dumps({"expected": len(jobs), "present": sum(not r.get("missing") for r in report), "transparent": sum(r.get("alphaExtrema")==[0,255] for r in report), "clearEdges": sum(bool(r.get("clearEdges")) for r in report), "bad": bad}))

