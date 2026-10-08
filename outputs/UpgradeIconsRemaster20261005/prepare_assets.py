"""Export imagegen artwork: preserve original PNG; normalize alpha padding/size.
Usage: python prepare_assets.py [generation-results.json]
Input: array of {key, source, prompt, nodeIds} records.
"""
from __future__ import annotations
import argparse
import datetime as dt
import html
import json
import math
import re
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
SIZE, CONTENT = 512, 448

def bounds(image, threshold=0):
    mask = image.getchannel('A').point(lambda value: 255 if value > threshold else 0)
    box = mask.getbbox()
    return {'threshold': threshold, 'bounds': box, 'padding': None if box is None else {
        'left': box[0], 'top': box[1], 'right': image.width-box[2], 'bottom': image.height-box[3]}}

def export(record):
    key = record.get('key')
    if not isinstance(key, str) or not re.fullmatch(r'[A-Za-z0-9_-]+', key):
        raise ValueError(f'Unsafe or missing key: {key!r}')
    source = Path(record['source']).expanduser().resolve()
    with Image.open(source) as opened:
        if opened.format != 'PNG':
            raise ValueError(f'{key}: source must be PNG')
        original = opened.convert('RGBA')
    extrema = original.getchannel('A').getextrema()
    if extrema[0] != 0 or extrema[1] == 0:
        raise ValueError(f'{key}: source needs real transparent pixels and visible artwork; alpha={extrema}')
    box = original.getchannel('A').getbbox()  # All nonzero alpha, including faint glow.
    original_path, file = ROOT/'originals'/f'{key}.png', ROOT/'icons'/f'{key}.png'
    original_path.parent.mkdir(parents=True, exist_ok=True)
    file.parent.mkdir(parents=True, exist_ok=True)
    if source != original_path.resolve():
        shutil.copy2(source, original_path)
    cropped = original.crop(box)  # Remove only completely transparent border pixels.
    factor = CONTENT/max(cropped.size)
    dimensions = tuple(max(1, round(value*factor)) for value in cropped.size)
    resized = cropped.resize(dimensions, Image.Resampling.LANCZOS)
    result = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    offset = ((SIZE-dimensions[0])//2, (SIZE-dimensions[1])//2)
    result.paste(resized, offset)  # No alpha mask: alpha copied once, not squared.
    result.save(file, optimize=True)
    alpha = result.getchannel('A')
    edge_alpha = max(alpha.crop(rect).getextrema()[1] for rect in (
        (0,0,SIZE,1), (0,SIZE-1,SIZE,SIZE), (0,0,1,SIZE), (SIZE-1,0,SIZE,SIZE)))
    if edge_alpha != 0:
        raise ValueError(f'{key}: exported artwork unexpectedly touches an edge')
    return {'key': key, 'prompt': record.get('prompt',''), 'nodeIds': record.get('nodeIds',[]),
        'sourceImage': str(source), 'original': str(original_path), 'file': str(file),
        'relativeFile': file.relative_to(ROOT).as_posix(), 'sourceSize': list(original.size),
        'size': list(result.size), 'mode': result.mode, 'sourceAlphaExtrema': list(extrema),
        'alphaExtrema': list(alpha.getextrema()), 'edgeAlphaMax': edge_alpha,
        'sourceContent': bounds(original), 'sourceVisibleContent': bounds(original,16),
        'content': bounds(result), 'visibleContent': bounds(result,16),
        'transform': {'operation': 'crop only transparent border; uniform resize; center on transparent canvas',
            'sourceCrop': list(box), 'scale': factor, 'resizedSize': list(dimensions), 'offset': list(offset),
            'resampling': 'Lanczos', 'recolored': False, 'backgroundRemoved': False}, 'status': 'prepared'}

def gallery(assets):
    path = ROOT/'gallery'/'index.html'
    path.parent.mkdir(parents=True, exist_ok=True)
    cards=[]
    for a in assets:
        label=html.escape(a['key'].replace('_',' ').replace('-',' '))
        img=html.escape('../'+a['relativeFile'],quote=True)
        ids=html.escape(', '.join(a['nodeIds']) or 'Menu / standalone asset')
        p=a['visibleContent']['padding']
        padding='/'.join(str(p[k]) for k in ('left','top','right','bottom'))
        cards.append(f'<article><a class="art" href="{img}"><img src="{img}" alt="{label}" loading="lazy"></a>'
            f'<h2>{label}</h2><p class="meta">512×512 RGBA · visible padding L/T/R/B {padding}px</p>'
            f'<details><summary>Assigned nodes ({len(a["nodeIds"])})</summary><p>{ids}</p></details>'
            f'<details><summary>Generation prompt</summary><p>{html.escape(a["prompt"])}</p></details></article>')
    doc='''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Snowplow upgrade icons</title>
<style>*{box-sizing:border-box}body{margin:0;background:#101c31;color:#edf7ff;font:16px/1.5 system-ui,sans-serif}
header{max-width:1400px;margin:auto;padding:34px 24px 20px}h1{margin:0;font-size:30px}header p{color:#b4d7ef}
main{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:20px;max-width:1400px;margin:auto;padding:0 24px 40px}
article{background:#1b2d47;border:1px solid #396384;border-radius:18px;padding:14px;overflow:hidden}
.art{display:block;aspect-ratio:1;border-radius:12px;background-color:#829aad;background-image:linear-gradient(45deg,#acc4d5 25%,transparent 25%),linear-gradient(-45deg,#acc4d5 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#acc4d5 75%),linear-gradient(-45deg,transparent 75%,#acc4d5 75%);background-size:24px 24px;background-position:0 0,0 12px,12px -12px,-12px 0}
img{display:block;width:100%;height:100%;object-fit:contain}h2{font-size:18px;margin:12px 0 3px}.meta{font-size:12px;color:#afd4ef;margin:0 0 12px}
details{font-size:13px;margin:8px 0}summary{cursor:pointer;color:#cee8fc}details p{overflow-wrap:anywhere;color:#aecbdf}
</style></head><body><header><h1>Snowplow upgrade icons</h1><p>Actual transparent game exports. Click an icon to inspect its PNG.
Originals are preserved; exports only normalize resolution and transparent padding.</p></header><main>'''
    path.write_text(doc+'\n'.join(cards)+'</main></body></html>',encoding='utf-8')
    return path

def preview(assets):
    columns, width, height=5,260,294
    sheet=Image.new('RGB',(columns*width,math.ceil(len(assets)/columns)*height),'#162740')
    draw=ImageDraw.Draw(sheet)
    font=ImageFont.load_default(size=17)
    for i,a in enumerate(assets):
        x,y=(i%columns)*width,(i//columns)*height
        for cy in range(y+12,y+244,16):
            for cx in range(x+14,x+246,16):
                color='#9bb2c4' if ((cx-x)//16+(cy-y)//16)%2 else '#7893aa'
                draw.rectangle((cx,cy,min(cx+15,x+245),min(cy+15,y+243)),fill=color)
        with Image.open(a['file']) as image:
            icon=image.convert('RGBA').resize((232,232),Image.Resampling.LANCZOS)
        sheet.paste(icon,(x+14,y+12),icon)
        label=a['key'].replace('_',' ').replace('-',' ')
        box=draw.textbbox((0,0),label,font=font)
        draw.text((x+(width-(box[2]-box[0]))/2,y+254),label,font=font,fill='#eaf7ff')
    path=ROOT/'preview-grid.png'
    sheet.save(path,optimize=True)
    return path

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input',nargs='?',type=Path,default=ROOT/'generation-results.json')
    args=parser.parse_args()
    records=json.loads(args.input.read_text(encoding='utf-8-sig'))
    if not isinstance(records,list) or not records:
        raise ValueError('Input must be a nonempty array of artwork records')
    keys=[r.get('key') for r in records]
    if len(set(keys)) != len(keys):
        raise ValueError('Artwork keys must be unique')
    assets=[export(record) for record in records]
    gallery_path,preview_path=gallery(assets),preview(assets)
    manifest={'createdUtc':dt.datetime.now(dt.timezone.utc).isoformat(),'generatedWith':'built-in imagegen',
        'input':str(args.input.resolve()),'targetSize':[SIZE,SIZE],'count':len(assets),
        'gallery':str(gallery_path),'preview':str(preview_path),'assets':assets}
    path=ROOT/'assets.json'
    path.write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(json.dumps({'count':len(assets),'manifest':str(path),'gallery':str(gallery_path),'preview':str(preview_path)},indent=2))

if __name__ == '__main__':
    main()
