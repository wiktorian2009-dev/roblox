"""Generate a self-contained Luau installer from the verified Blender layout."""
import json
from pathlib import Path
ROOT=Path(r'C:\Users\wikto\Desktop\Roblox Gra')
OUT=ROOT/'outputs/StageBlender20261001'
manifest=json.loads((OUT/'manifest.json').read_text())
plan=json.loads((OUT/'placement-plan.json').read_text())
assert json.loads((OUT/'export-verification.json').read_text())['passed']
assert json.loads((OUT/'layout-verification.json').read_text())['passed']
models={name:{'stage':v['stage'],'size':[v['blender_size'][0],v['blender_size'][2],v['blender_size'][1]]}for name,v in manifest['models'].items()}
data={'models':models,'count':len(models),'placements':plan['placements'],'groundY':{'Starter':.239,'Desert':3.528625,'Cursed':3.137625,'Crystal':3.69764,'Retro':3.761625,'Jungle':5.145625,'AbsoluteZero':1.090625,'Portal':1.090625}}
template=(ROOT/'work/stage-blender-installer-template-20261001.luau').read_text()
(OUT/'install-after-import.luau').write_text(template.replace('__STAGE_BLENDER_DATA__',json.dumps(data,separators=(',',':'))),encoding='utf-8')
print('Prepared installer:',len(models),'models,',len(plan['placements']),'placements, DRY_RUN=true')
