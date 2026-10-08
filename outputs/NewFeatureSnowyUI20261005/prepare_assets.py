import json, pathlib, shutil, html
from PIL import Image, ImageDraw
root=pathlib.Path(__file__).resolve().parent
manifest=json.loads((root/'generation-results.json').read_text(encoding='utf-8'))
(root/'originals').mkdir(exist_ok=True); (root/'icons').mkdir(exist_ok=True); (root/'gallery').mkdir(exist_ok=True)
items=[]
for item in manifest:
    src=pathlib.Path(item['source']); key=item['key']
    shutil.copyfile(src,root/'originals'/f'{key}.png')
    original=Image.open(src).convert('RGBA')
    alpha=original.getchannel('A')
    assert alpha.getextrema()[0]==0 and alpha.getextrema()[1]>0,key
    bbox=alpha.getbbox(); cropped=original.crop(bbox)
    if key=='hud-frame':
        width=1024
        height=round(cropped.height*width/cropped.width)
        result=cropped.resize((width,height),Image.Resampling.LANCZOS)
        dest=root/'icons'/f'{key}.png'; result.save(dest)
        slice_center=[min(150,width//4),min(100,height//3),width-min(150,width//4),height-min(100,height//3)]
        extra={'sliceCenter':slice_center,'centerAlpha':result.getpixel((width//2,height//2))[3]}
        assert extra['centerAlpha']==0,'frame interior must be transparent'
    else:
        cropped.thumbnail((448,448),Image.Resampling.LANCZOS)
        result=Image.new('RGBA',(512,512))
        result.alpha_composite(cropped,((512-cropped.width)//2,(512-cropped.height)//2))
        dest=root/'icons'/f'{key}.png'; result.save(dest)
        edge=[result.getchannel('A').crop((0,0,512,1)),result.getchannel('A').crop((0,511,512,512)),result.getchannel('A').crop((0,0,1,512)),result.getchannel('A').crop((511,0,512,512))]
        extra={'edgeAlphaMax':max(e.getextrema()[1] for e in edge)}
        assert extra['edgeAlphaMax']==0,key
    items.append({**item,'file':str(dest),'relativeFile':f'icons/{key}.png','sourceSize':list(original.size),'size':list(result.size),'mode':result.mode,'alphaExtrema':list(result.getchannel('A').getextrema()),**extra})
(root/'assets.json').write_text(json.dumps({'count':len(items),'assets':items},indent=2),encoding='utf-8')
cards=[]
for item in items:
    cards.append('<article><div class="preview"><img src="../'+item['relativeFile']+'"></div><h2>'+html.escape(item['key'])+'</h2><p>'+str(item['size'])+' RGBA</p><details><summary>Generation prompt</summary><pre>'+html.escape(item['prompt'])+'</pre></details></article>')
page='<!doctype html><html><head><meta charset="utf-8"><title>Snowy feature GUI artwork</title><style>body{margin:30px;background:#102950;color:#e7f7ff;font:16px system-ui}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px}article{padding:16px;border:1px solid #4488c6;border-radius:18px;background:#163760}.preview{height:230px;display:grid;place-items:center;background:repeating-conic-gradient(#245380 0% 25%,#1f466d 0% 50%) 0/28px 28px;border-radius:12px}img{max-width:100%;max-height:210px}pre{white-space:pre-wrap;font-size:13px}</style></head><body><h1>Snowy feature GUI artwork</h1><p>Generated transparent PNGs for Travel, driving controls, SPIN, contracts and paid offers. No baked prices or status text.</p><main>'+''.join(cards)+'</main></body></html>'
(root/'gallery'/'index.html').write_text(page,encoding='utf-8')
cols=4; w=256; h=280
sheet=Image.new('RGB',(cols*w,((len(items)+cols-1)//cols)*h),(19,48,82))
draw=ImageDraw.Draw(sheet)
for i,item in enumerate(items):
    image=Image.open(item['file']).convert('RGBA'); image.thumbnail((220,220))
    x=(i%cols)*w+(w-image.width)//2; y=(i//cols)*h+10+(220-image.height)//2
    sheet.paste(image,(x,y),image)
    draw.text(((i%cols)*w+14,(i//cols)*h+244),item['key'],fill=(232,246,255))
sheet.save(root/'preview-grid.png')
print(json.dumps({'count':len(items),'frame':next((i for i in items if i['key']=='hud-frame'),None)},indent=2))

