"""Make a measured placement plan and an actual-render contact sheet. Does not change Studio."""
import json, math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
OUT=Path(r'C:\Users\wikto\Desktop\Roblox Gra\outputs\StageBlender20261001')
m=json.loads((OUT/'manifest.json').read_text())
geo=json.loads((OUT/'live-geometry-20261001.json').read_text())
placements=[]
heights={'Starter':.239,'Desert':3.528625,'Cursed':3.137625,'Crystal':3.69764,'Retro':3.761625,'Jungle':5.145625,'AbsoluteZero':1.090625,'Portal':1.090625}
def put(asset,x,z,yaw=0,scale=1,lift=0,**kw):
    info=m['models'][asset];stage=info['stage']
    placements.append(dict(asset=asset,stage=stage,position=[x,heights[stage]+lift,z],yaw=yaw,scale=scale,**kw))
put('Starter_ScoutIgloo',-16,-309,180)
put('Starter_ScarfSnowman',-4,-311,30)
put('Starter_ExpeditionSled',-17,-257,12)
put('Desert_OasisGarden',121,-253)
put('Desert_ShadeCaravan',120,-308)
put('Desert_SunArch',185,-331.4,180)
put('Desert_CamelResting',137,-247,-30)
put('Desert_Camel',132,-297,-20)
put('Desert_FennecFox',125,-320,15)
put('Desert_BoulderA',137,-235,20,scale=.55)
put('Desert_Meerkat',137,-235,10,lift=2.27,support='Desert_BoulderA')
put('Desert_SunRock',143,-315,-8)
put('Desert_Lizard',143,-315,-8,lift=1.89,support='Desert_SunRock')
put('Desert_VultureFlying',120,-257,0,lift=22,motion='Orbit',amount=.3,speed=.25,radius=9)
put('Desert_Tumbleweed',137,-321,0,motion='Roll',amount=.10,speed=.25,radius=3)
put('Desert_SaguaroTall',108,-238,5,motion='Sway',amount=.018,speed=.55)
put('Desert_SaguaroSmall',136,-267,-20,motion='Sway',amount=.02,speed=.6)
put('Desert_BarrelCactus',128,-239)
put('Desert_PricklyPear',142,-243,30)
put('Desert_GrassTuft',132,-265,0,motion='Sway',amount=.07,speed=1)
put('Desert_FlowerPatch',110,-317)
put('Desert_DesertShrub',135,-333,30,motion='Sway',amount=.04,speed=.8)
put('Desert_PalmTree',104,-254,20,motion='Sway',amount=.015,speed=.5)
put('Desert_Reeds',120,-244,20,motion='Sway',amount=.045,speed=.8)
put('Desert_RockPillar',110,-308,10)
for x,z in [(105,-241),(111,-318),(140,-240),(137,-332)]:put('Desert_GrassTuft',x,z,20,motion='Sway',amount=.07,speed=.8)
put('Cursed_MoonShrine',267,-91,90)
put('Cursed_FriendlyGhost',267,-36,0,lift=2,motion='Float',amount=.45,speed=.9)
put('Cursed_PotionCauldron',267,29,90)
put('Crystal_PrismaticGeode',217,150,-90)
put('Crystal_LuminousMushrooms',210,184)
put('Crystal_GemCart',280,92,180)
put('Retro_GiantJoystick',44,279)
put('Retro_ArcadeCabinet',70,272)
put('Retro_ArcadeCabinet',80,272)
put('Retro_PixelBuddy',155,235,-90,motion='Float',amount=.3,speed=1.1)
put('Jungle_TempleWaterfall',-88,193,180)
put('Jungle_FriendlyTotem',-62,195.8,180)
put('Jungle_LeafyFern',-55,258,0,motion='Sway',amount=.04,speed=.75)
put('Jungle_TropicalMacaw',-43,258,0,motion='Sway',amount=.02,speed=.75)
for x in [-135,-102,-78,-30]:put('Jungle_LeafyFern',x,258,0,scale=.9,motion='Sway',amount=.035,speed=.8)
put('AbsoluteZero_FrozenHeart',-327,183,-90)
put('AbsoluteZero_PolarPenguin',-197,342,90)
put('AbsoluteZero_FrozenPine',-197,163)
put('AbsoluteZero_FrozenPine',-331,310,10)
put('AbsoluteZero_FrozenPine',-329,247,-10)
put('Portal_CrystalGuardian',-320,215,-90)
put('Portal_CrystalGuardian',-320,295,-90)
put('Portal_AuroraObelisk',-320,222,-90)
put('Portal_AuroraObelisk',-320,287,-90)

def corners_record(r,pad=0):
    cf=r['cf'];x,z=cf[0],cf[2];a,b,c,d=cf[3],cf[5],cf[9],cf[11]
    w,h=r['size'][0]/2+pad,r['size'][2]/2+pad
    return [(x+a*u+b*v,z+c*u+d*v)for u,v in [(-w,-h),(w,-h),(w,h),(-w,h)]]
def corners_prop(p):
    size=m['models'][p['asset']]['blender_size'];w,d=size[0]*p['scale']/2,size[1]*p['scale']/2
    # Conservative allowance for the prescribed local movement.
    r=p.get('radius',0)if p.get('motion')in ('Orbit','Roll')else 0
    sway=(size[2]*p['scale']*p.get('amount',0))if p.get('motion')=='Sway'else 0
    w+=r+sway;d+=r+sway
    a=math.radians(p['yaw']);c,s=math.cos(a),math.sin(a);x,y,z=p['position']
    return [(x+c*u+s*v,z-s*u+c*v)for u,v in [(-w,-d),(w,-d),(w,d),(-w,d)]]
def overlap(a,b):
    for poly in (a,b):
        for p,q in zip(poly,poly[1:]+poly[:1]):
            ax,az=-(q[1]-p[1]),q[0]-p[0]
            pa=[x*ax+z*az for x,z in a];pb=[x*ax+z*az for x,z in b]
            if max(pa)<min(pb)or max(pb)<min(pa):return False
    return True
def inside(p,poly):
    cross=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):cross.append((b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]))
    return all(x>=-.001 for x in cross)or all(x<=.001 for x in cross)
issues=[]
for p in placements:
    foot=corners_prop(p)
    for f in geo['fields']:
        if overlap(foot,corners_record(f,2)):issues.append({'asset':p['asset'],'position':p['position'],'type':'field','target':f['name']})
    for g in geo['gates']:
        if overlap(foot,corners_record(g,6)):issues.append({'asset':p['asset'],'position':p['position'],'type':'gate','target':g['cf'][:3]})
    grounds=[g for g in geo['ground']if abs(g['cf'][1]+g['size'][1]/2-heights[p['stage']])<.1]
    if not all(any(inside(v,corners_record(g))for g in grounds)for v in foot):issues.append({'asset':p['asset'],'position':p['position'],'type':'ground'})
plan={'place_id':94130990350526,'status':'prepared; not installed','placements':placements,'reserved_models':['Portal_CrystalHalo'],'field_margin':2,'gate_margin':6,'placement_count':len(placements),'instanced_triangles':sum(m['models'][p['asset']]['triangles']for p in placements)}
(OUT/'placement-plan.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
report={'passed':not issues,'placements':len(placements),'field_padding':2,'gate_padding':6,'issues':issues,'limits':'Bounds checked against a live geometry snapshot; actual imported axes, mesh texture, old scenery overlaps, wall fit and runtime still require Studio verification.'}
(OUT/'layout-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report),flush=True)
assert not issues
try:font=ImageFont.truetype(r'C:\Windows\Fonts\segoeuib.ttf',28)
except OSError:font=ImageFont.load_default()
stages=['Starter','Desert','Cursed','Crystal','Retro','Jungle','AbsoluteZero','Portal']
labels=['Snow camp','Living desert','Moon shrine','Crystal grotto','Retro arcade','Jungle waterfall','Absolute Zero','Portal guardians']
grid=Image.new('RGB',(1600,760),(22,29,40));draw=ImageDraw.Draw(grid)
for i,(stage,label)in enumerate(zip(stages,labels)):
    tile=Image.open(OUT/(stage+'-preview.png')).convert('RGB');tile=tile.resize((400,328),Image.Resampling.LANCZOS)
    col,row=i%4,i//4;grid.paste(tile,(col*400,row*380))
    draw.text((col*400+16,row*380+342),label,font=font,fill=(245,248,252))
grid.save(OUT/'preview-grid.png')
