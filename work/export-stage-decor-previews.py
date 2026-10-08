"""Save Studio review captures and a contact sheet; consumes newline-delimited JSON on stdin."""
import base64
import io
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

out = Path(r'C:\Users\wikto\Desktop\Roblox Gra\outputs\StageDecor20260930')
out.mkdir(parents=True, exist_ok=True)
captures = {}
stream = open(sys.argv[1], encoding='utf-8') if len(sys.argv) > 1 else sys.stdin
for line in stream:
    item = json.loads(line)
    if item.get('done'):
        break
    if 'metadata' in item:
        for key, value in item['metadata'].items():
            assert key in {'validation', 'runtime-check', 'cleanup', 'scene-snapshot'}
            (out / (key + '.json')).write_text(json.dumps(value, indent=2), encoding='utf-8')
        print('Saved validation, runtime, cleanup and scene inventory.', flush=True)
        continue
    name = item['name']
    assert name in {'Starter', 'Desert', 'Cursed', 'Crystal', 'Retro', 'Jungle', 'AbsoluteZero', 'Portal', 'DesertRuins'}
    path = out / (name + '.png')
    with Image.open(io.BytesIO(base64.b64decode(item['data']))) as im:
        assert im.format in {'PNG', 'JPEG'}
        captures[name] = im.convert('RGB').copy()
        captures[name].save(path, format='PNG')
    print('Saved ' + name + '.png', flush=True)

order = ['Starter', 'Desert', 'Cursed', 'Crystal', 'Retro', 'Jungle', 'AbsoluteZero', 'Portal']
assert all(name in captures for name in order)
font = ImageFont.truetype(r'C:\Windows\Fonts\segoeuib.ttf', 25)
heading = ImageFont.truetype(r'C:\Windows\Fonts\segoeuib.ttf', 34)
margin, gutter, width, height = 24, 16, 570, 449
sheet = Image.new('RGB', (margin * 2 + width * 4 + gutter * 3, 78 + 2 * (height + 45) + gutter + margin), '#12283b')
draw = ImageDraw.Draw(sheet)
draw.text((margin, 20), 'FROSTFALL — STAGE DECORATION', font=heading, fill='white')
for i, name in enumerate(order):
    x = margin + (i % 4) * (width + gutter)
    y = 78 + (i // 4) * (height + 45 + gutter)
    im = captures[name]
    im.thumbnail((width, height), Image.Resampling.LANCZOS)
    sheet.paste(im, (x, y))
    label = 'Absolute Zero' if name == 'AbsoluteZero' else name
    draw.text((x, y + height + 6), label, font=font, fill='#e9f7ff')
sheet.save(out / 'stage-decor-preview-grid.png')
print(str(out / 'stage-decor-preview-grid.png'), flush=True)
