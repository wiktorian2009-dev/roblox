"""Real Blender mesh decorations. Original Claude sources are read only.
Run with Blender --factory-startup --background --python this_file.
"""
import bpy, bmesh, math, json, os, sys, traceback, importlib.util
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(r'C:\Users\wikto\Desktop\Roblox Gra')
OUT = ROOT / 'outputs' / 'StageBlender20261001'
OUT.mkdir(parents=True, exist_ok=True)
spec = importlib.util.spec_from_file_location('stage_mesh_helpers', ROOT / 'outputs/DesertLife2026/life_lib.py')
lib = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lib)
lib.OUT = str(OUT)
lib.NCOL, lib.CW = 128, 8
lib.HEX.update({
 'snow':'EDF6FF','ice':'87D3ED','iceDark':'438CAB','blue':'389CCD','navy':'233651',
 'red':'EF5B65','gold':'FFCB50','wood':'A66F43','woodLight':'D49A62','woodDark':'634A3D',
 'stone':'63838F','stoneDark':'38515F','stoneLight':'A9C2CF','cursed':'56435F','purple':'9860BC',
 'violet':'BB93E3','pink':'F399CB','mint':'88E8BC','cyan':'5CCEDC','moss':'4EAD6B',
 'mossDark':'327957','mossLight':'8DD167','water':'45B6D5','waterLight':'AFE5EB',
 'coral':'FF8166','retroPurple':'8B69DD','retroBlue':'54B6E4','retroPink':'E969AE',
 'steel':'86A7BE','steelDark':'3D638A','plum':'7956A8','orange':'FDB246',
 'leaf':'48B965','leafLight':'97D976','leafDark':'288457','banana':'FFE36A',
 'macawBlue':'319DDD','macawRed':'EF5458','cheek':'FFBDC0','cream':'FFF0D0',
})
lib.PAL = {n:i for i,n in enumerate(lib.HEX)}
assert len(lib.PAL) <= lib.NCOL
P, pi = lib.P, math.pi
ASSETS, STAGES = [], {}
STAGE_IDS = ['Starter','Desert','Cursed','Crystal','Retro','Jungle','AbsoluteZero','Portal']

def progress(status, **kw):
    (OUT/'build-status.json').write_text(json.dumps({'status':status,'pid':os.getpid(),**kw},indent=2),encoding='utf-8')
    print('STAGE_BLENDER_PROGRESS',status,kw,flush=True)

def add(stage, p, motion=None):
    o = p.finish() if isinstance(p,P) else p
    o['Stage'] = stage
    if motion: o['StageDecorMotion'] = motion
    zmin = min(v.co.z for v in o.data.vertices)
    for v in o.data.vertices: v.co.z -= zmin
    o.location=(0,0,0)
    for c in list(o.users_collection): c.objects.unlink(o)
    STAGES[stage].objects.link(o)
    ASSETS.append(o)
    return o

def ring(p, c, r, thickness, color, vertical=False, n=28):
    pts=[(c[0]+r*math.cos(2*pi*i/n),c[1]+(0 if vertical else r*math.sin(2*pi*i/n)),c[2]+(r*math.sin(2*pi*i/n) if vertical else 0))for i in range(n)]
    return p.sweep(pts,[thickness]*n,color,seg=8,closed=True)

def eyes(p, y, z, spread=.6, size=.25):
    for x in (-spread,spread):
        p.sph((x,y,z),(size,size*.46,size*1.15),'eye',seg=10,ring=7,flat=True)
        p.sph((x+.06,y-size*.42,z+.08),size*.28,'white',seg=6,ring=4,flat=True)

def smile(p,y,z,w=.6):
    p.sweep([(w*math.cos(a),y,z-.24*math.sin(a))for a in [pi*i/9 for i in range(10)]],[.055]*10,'eye',seg=5)

def gem(p,c,h,r,color,rot=(0,0,0)):
    return p.lathe([(0,0),(r,.13*h),(r,.64*h),(.50*r,.83*h),(0,h)],color,seg=6,smooth=False,c=c,rot=rot)

def crate(p,c,size=2):
    x,y,z=c
    p.box((x,y,z+size/2),(size,size,size),'wood',bevel=.09)
    for a in (-.35,.35): p.box((x+a*size,y,z+size/2),(.12*size,size+.05,size+.05),'woodDark',bevel=.03)

def igloo():
    p=P('Starter_ScoutIgloo')
    p.cyl((0,0,0),5.7,5.7,.3,'ice',seg=32)
    # Curved individual bricks form a genuinely open doorway, rather than a dark surface patch.
    rows, segments = 8,32
    for j in range(rows):
        a0=j/rows*(pi/2-.04)+.005;a1=(j+1)/rows*(pi/2-.04)-.005
        for i in range(segments):
            t0=2*pi*i/segments+.006;t1=2*pi*(i+1)/segments-.006
            mid=(t0+t1)/2;dist=abs((mid+pi/2+pi)%(2*pi)-pi)
            if j<3 and dist<.43: continue
            coords=[]
            for r in (4.68,5.0):
                for a,t in ((a0,t0),(a0,t1),(a1,t1),(a1,t0)):
                    coords.append((r*math.cos(a)*math.cos(t),r*math.cos(a)*math.sin(t),.3+4.35*math.sin(a)))
            vs=[p.bm.verts.new(c)for c in coords]
            fs=[p.bm.faces.new([vs[k]for k in f])for f in ((0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0))]
            p._paint(fs,'snow',smooth=False,grad=(.40,.85))
    p.sph((0,0,4.63),(.32,.32,.15),'snow',seg=12,ring=6)
    for y in (-4.65,-5.65,-6.65):
        p.sweep([(2.15*math.cos(a),y,.38+2.55*math.sin(a))for a in [pi*i/16 for i in range(17)]],[.34]*17,'ice',seg=8)
    p.box((0,-5.6,.20),(4.6,3.8,.25),'snow',bevel=.12)
    return add('Starter',p)

def snowman():
    p=P('Starter_ScarfSnowman')
    p.sph((0,0,1.35),(1.4,1.2,1.35),'snow',seg=18,ring=12)
    p.sph((0,0,3.35),(1.0,.94,1.0),'snow',seg=18,ring=12)
    p.lathe([(0,0),(1.3,0),(1.3,.18),(.85,.18),(.85,1.1),(0,1.1)],'navy',seg=20,c=(0,0,4.2))
    p.cyl((0,0,4.39),.87,.87,.2,'red',seg=20)
    ring(p,(0,0,2.7),1.02,.21,'blue')
    p.sweep([(.62,-.90,2.65),(.75,-1.1,2.1),(.60,-1.15,1.7)],[(.22,.12)]*3,'blue',seg=8)
    eyes(p,-.91,3.56,.37,.15)
    p.cone((0,-.92,3.27),.19,.85,'flowerOrange',seg=9,rot=(pi/2,0,0))
    smile(p,-.90,3.10,.40)
    for z in (.9,1.5,2.05):p.sph((0,-1.16,z),.13,'eye',seg=8,ring=5)
    for s in (-1,1):
        p.sweep([(s*1.12,0,1.8),(s*1.8,0,2.3),(s*2.4,.1,2.6)],[.14,.10,.06],'woodDark',seg=7)
        p.sweep([(s*1.8,0,2.3),(s*1.8,0,2.8)],[.075,.04],'woodDark',seg=6)
    return add('Starter',p)

def sled():
    p=P('Starter_ExpeditionSled')
    for x in (-1.5,1.5):p.sweep([(x,2.7,.9),(x,2.5,.35),(x,1.5,.2),(x,-2.5,.2),(x,-2.9,.9)],[.12]*5,'steelDark',seg=8)
    for y in (-2,-1.2,-.4,.4,1.2,2):p.box((0,y,.75),(3.5,.65,.2),'woodLight',bevel=.06)
    crate(p,(-.6,.7,.85),1.6)
    p.sph((.75,-.7,1.15),(.7,1.6,.65),'blue',seg=12,ring=8)
    for y in (-1.65,.25):ring(p,(.75,y,1.15),.60,.07,'cream',vertical=True,n=16)
    p.sweep([(-1.5,-2.7,.9),(-.9,-3.7,.2),(.9,-3.7,.2),(1.5,-2.7,.9)],[.075]*4,'woodDark',seg=6)
    return add('Starter',p)

def oasis():
    p=P('Desert_OasisGarden')
    p.lathe([(0,0),(8.6,0),(9.2,.25),(8.9,.6),(8.0,.75),(0,.75)],'sandstoneLight',seg=36)
    p.cyl((0,0,.78),7.4,7.4,.08,'water',seg=36,flat=True)
    ring(p,(0,0,.88),7.5,.14,'waterLight',n=36)
    for i in range(9):
        a=2*pi*i/9;p.ico((8.1*math.cos(a),8.1*math.sin(a),.58),(1.5,1.0,.7),'sandstone',sub=2,noise=.10,seed=i,smooth=True)
    for x,y,h in ((-5,3,10),(5,4,12)):
        p.sweep([(x,y,.6),(x+.3,y,h*.5),(x+1,y,h)],[.50,.42,.30],'palmTrunk',seg=10)
        for i in range(7):
            a=2*pi*i/7;start=(x+1,y,h)
            pts=[start,(start[0]+2*math.cos(a),start[1]+2*math.sin(a),h+.4),(start[0]+4.5*math.cos(a),start[1]+4.5*math.sin(a),h-1.1)]
            p.sweep(pts,[(.15,.06),(.85,.10),(.04,.04)],'frond'if i%2 else 'frondLight',seg=8,uhint=(-math.sin(a),math.cos(a),0))
        p.sph((x+.7,y-.4,h-.65),.40,'coconut',seg=10,ring=7)
    for x,y in ((-3,-1),(4,1)):
        p.sph((x,y,.94),(1.0,.85,.08),'frond',seg=12,ring=5)
        lib.flower(p,(x,y,1.07),'flowerPink',r=.40)
    return add('Desert',p)

def caravan():
    p=P('Desert_ShadeCaravan')
    for x in (-4.4,4.4):
        for y in (-2.6,2.6):p.cyl((x,y,0),.18,.18,6.2,'wood',seg=10)
    for i in range(7):
        x=(i-3)*1.3
        p.sweep([(x,-3.3,5.6),(x,0,6.5),(x,3.3,5.6)],[(.67,.07)]*3,'blanketRed'if i%2 else 'cream',seg=4,uhint=(1,0,0))
    p.box((0,-1.9,2),(8.5,1.7,.35),'woodLight',bevel=.12)
    for x in (-3.2,3.2):p.box((x,-1.9,1),(0.25,1.1,2),'wood',bevel=.05)
    for x,col in ((-2,'sandstone'),(0,'sandstoneLight'),(2,'sandstoneDark')):
        p.lathe([(0,0),(.5,0),(.8,.5),(.68,1.15),(.37,1.6),(.45,1.8),(.30,1.8),(.27,1.5),(0,1.4)],col,seg=16,c=(x,-1.9,2.18))
    crate(p,(3.3,1.3,0),1.8)
    return add('Desert',p)

def sunarch():
    p=P('Desert_SunArch')
    for x in (-6.2,6.2):
        p.lathe([(0,0),(1.5,0),(1.5,.5),(1.15,.8),(.95,8.7),(1.3,9),(1.3,9.6),(0,9.6)],'sandstoneLight',seg=12,c=(x,0,0))
        for z in (1,4,7):ring(p,(x,0,z),1.03,.09,'sandstoneDark',n=12)
    p.box((0,0,10.2),(15.5,3.0,1.4),'sandstone',bevel=.20)
    p.cyl((0,-1.60,10.2),1.15,1.15,.25,'gold',seg=24,rot=(pi/2,0,0))
    for i in range(8):
        a=2*pi*i/8;p.sph((1.5*math.cos(a),-1.85,10.2+1.5*math.sin(a)),(.14,.12,.23),'gold',seg=8,ring=6,rot=(0,a,0))
    return add('Desert',p)

def moon_shrine():
    p=P('Cursed_MoonShrine')
    p.lathe([(0,0),(6.2,0),(6.2,.6),(5.7,.9),(5.7,1.2),(0,1.2)],'cursed',seg=28)
    ring(p,(0,0,1.25),5.3,.14,'violet')
    for x in (-4.5,4.5):
        p.box((x,0,4.2),(1.35,1.45,6),'cursed',bevel=.15)
        p.box((x,-.75,4.5),(.32,.10,3.7),'violet',bevel=.03)
        p.sph((x,0,7.4),(.95,.95,.38),'stoneDark',seg=12,ring=6)
    angles=[-.30*pi+i*1.58*pi/30 for i in range(31)]
    pts=[(3.65*math.cos(a),1.0,8+3.65*math.sin(a))for a in angles]
    widths=[.07+.40*math.sin(pi*i/30)**.7 for i in range(31)]
    p.sweep(pts,widths,'gold',seg=8)
    gem(p,(0,0,2),5.5,1.1,'violet')
    for x in (-3,3):p.cyl((x,-3.5,1.2),.35,.35,1.2,'stoneDark',seg=12);p.sph((x,-3.5,2.5),.40,'pink',seg=12,ring=7)
    return add('Cursed',p)

def ghost():
    p=P('Cursed_FriendlyGhost')
    p.lathe([(1.8,0),(1.85,1.5),(1.78,2.7),(1.45,3.7),(.85,4.25),(0,4.5)],'snow',seg=24,zmod=lambda a,i:.30*(1+math.cos(5*a))if i==0 else 0)
    for s in (-1,1):p.sph((s*2.0,0,2),(0.40,.50,.75),'snow',seg=12,ring=8,rot=(0,s*.7,0))
    eyes(p,-1.7,2.8,.58,.30);smile(p,-1.68,2.2,.5)
    for s in (-1,1):p.sph((s*1.07,-1.48,2.25),(.32,.08,.16),'cheek',seg=8,ring=5)
    return add('Cursed',p,'Float')

def cauldron():
    p=P('Cursed_PotionCauldron')
    p.lathe([(0,.4),(1.5,.4),(2.8,1.3),(3.2,2.7),(2.95,4.1),(2.65,4.35),(2.3,4.05),(0,3.8)],'navy',seg=24)
    ring(p,(0,0,4.35),2.65,.25,'plum')
    p.cyl((0,0,3.96),2.35,2.35,.1,'mint',seg=24)
    for x,y,r in ((-.8,-.5,.50),(.7,.8,.38),(1.3,-.7,.30),(-.1,.2,.65)):p.sph((x,y,4.25),r,'mint',seg=10,ring=7)
    for s in (-1,1):p.sweep([(s*2.9,0,3.7),(s*3.8,0,3.8),(s*3.8,0,2.5),(s*3.0,0,2.4)],[.22]*4,'steelDark',seg=8)
    for a in (0,2*pi/3,4*pi/3):p.sph((1.7*math.cos(a),1.7*math.sin(a),.35),(.70,.70,.35),'plum',seg=12,ring=8)
    eyes(p,-2.95,2.5,.65,.28);smile(p,-3.0,1.8,.6)
    return add('Cursed',p)

def crystal_garden():
    p=P('Crystal_PrismaticGeode')
    p.lathe([(0,0),(7.2,0),(7.4,.6),(7,.9),(0,.9)],'iceDark',seg=28)
    for i in range(11):
        a=.04*pi+i*.92*pi/10
        p.ico((6.6*math.cos(a),3.8*math.sin(a),2.2+3.0*math.sin(a)),(1.75,1.4,2.1),'stoneLight',sub=1,noise=.15,seed=i)
    for x,y,h,r,col in ((0,0,8,1.3,'cyan'),(-2.7,0,5.2,.9,'violet'),(2.8,.4,6.2,.9,'pink'),(-4,-1.3,3.7,.65,'cyan'),(4.3,-1.8,3.3,.70,'violet')):
        gem(p,(x,y,.9),h,r,col,rot=(0,x*.035,0))
    return add('Crystal',p)

def mushrooms():
    p=P('Crystal_LuminousMushrooms')
    for x,y,h,r,col in ((-1.8,0,2.9,1.65,'cyan'),(1.4,.6,4.2,2.15,'pink'),(.5,-1.7,1.8,1.05,'violet')):
        p.sweep([(x,y,0),(x+.2,y,h*.55),(x,y,h)],[.35,.30,.25],'ice',seg=12)
        p.lathe([(0,0),(r,0),(r,.18),(r*.85,.65),(r*.38,1),(0,1.1)],col,seg=20,c=(x,y,h))
        for i in range(5):
            a=2*pi*i/5;p.sph((x+r*.60*math.cos(a),y+r*.60*math.sin(a),h+.60),(.18,.18,.06),'snow',seg=8,ring=5)
    return add('Crystal',p)

def gemcart():
    p=P('Crystal_GemCart')
    p.box((0,0,1.8),(4.0,5.0,.35),'woodDark',bevel=.12)
    for x in (-2,2):
        p.box((x,0,2.8),(.20,5.0,2),'wood',bevel=.06)
        for y in (-1.65,1.65):
            p.cyl((x-.25,y,1),.9,.9,.45,'steelDark',seg=16,rot=(0,pi/2,0))
            p.cyl((x-.30,y,1),.22,.22,.55,'steel',seg=12,rot=(0,pi/2,0))
    p.box((0,2.4,2.8),(4,.2,2),'wood',bevel=.06)
    for x,y,h,col in ((-1,-.9,3.1,'cyan'),(1,.6,2.6,'violet'),(.1,1.5,2.1,'pink')):gem(p,(x,y,1.9),h,.55,col)
    for x in (-1.6,1.6):p.sweep([(x,-2.5,1.9),(x,-4.4,2.1)],[.18,.14],'wood',seg=8)
    return add('Crystal',p)

STAR=['00100','01110','11111','01110','10101']
def pixels(p,rows,c=(0,0,0),cell=.4,color='gold',depth=1):
    cells={}
    for z,row in enumerate(reversed(rows)):
        for x,t in enumerate(row):
            if t!='0':
                for y in range(depth):cells[(x,y,z)]=color if t=='1'else 'eye'
    return p.vox(cells,cell=cell,origin=(c[0]-len(rows[0])*cell/2,c[1],c[2]))

def arcade():
    p=P('Retro_ArcadeCabinet')
    p.box((0,0,.25),(4.4,3.8,.5),'navy',bevel=.12)
    p.box((0,0,3.2),(3.7,3.4,5.6),'retroBlue',bevel=.16)
    p.box((0,.2,6.0),(4.1,3.5,1.4),'retroPurple',bevel=.14)
    p.box((0,-1.65,4.25),(3.0,.30,2.6),'navy',bevel=.10)
    p.box((0,-1.83,4.25),(2.5,.08,2.2),'steelDark',bevel=.04)
    pixels(p,STAR,(0,-1.9,3.38),cell=.32,color='gold')
    p.box((0,-1.3,2.6),(4.0,2.0,.32),'retroPurple',bevel=.12)
    p.cyl((-.8,-1.75,2.75),.09,.09,.70,'steel',seg=10);p.sph((-.8,-1.75,3.4),.25,'retroPink',seg=12,ring=8)
    for x in (.2,.7,1.2):p.sph((x,-1.78,2.85),(.18,.18,.09),'gold'if x<1 else 'red',seg=10,ring=6)
    p.box((0,-1.6,6.2),(3.3,.12,.45),'gold',bevel=.07)
    p.box((0,-1.73,1.15),(.9,.06,.16),'navy',bevel=.02)
    return add('Retro',p)

def joystick():
    p=P('Retro_GiantJoystick')
    p.box((0,0,.65),(10,7,1.3),'retroPurple',bevel=.30)
    p.box((0,0,1.30),(9.3,6.3,.20),'navy',bevel=.18)
    p.cyl((-2,-.1,1.4),1.05,1.05,.25,'steelDark',seg=24)
    p.cyl((-2,-.1,1.6),.22,.22,3.1,'steel',seg=16)
    p.sph((-2,-.1,5),(1.2,1.2,1.2),'retroPink',seg=20,ring=12)
    for x,y,col in ((1.6,-1.0,'gold'),(3,0,'red'),(1.6,1.0,'retroBlue')):p.cyl((x,y,1.5),.56,.56,.35,col,seg=20)
    for x in (-3,-2,-1,0,1):p.box((x,3.2,.8),(.30,.08,.35),'cyan')
    return add('Retro',p)

def alien():
    p=P('Retro_PixelBuddy')
    p.box((0,0,.3),(5,3.2,.6),'retroPurple',bevel=.10)
    mask=['0100000010','0011111100','0111111110','1121111211','1111111111','0011111100','0010000100','0110000110']
    pixels(p,mask,(0,-.35,1.0),cell=.46,color='mint',depth=2)
    for x in (-1.1,1.1):p.box((x,0,.9),(.4,.5,.7),'navy')
    return add('Retro',p,'Float')

def waterfall():
    p=P('Jungle_TempleWaterfall')
    # Overlapping sculpted boulders cover the hidden wall, without a skyline of square towers.
    p.box((0,1.15,9.5),(40,2.8,19),'stoneDark',bevel=.7)
    for i,(x,h) in enumerate(((-17,23),(-10.5,28),(-5.7,21),(5.7,21),(10.5,26),(17,22))):
        for j in range(3):
            z=h*(j+.5)/3
            p.ico((x+.32*math.sin(i+j),.65,z),(4.3,2.1,h/6+.8),'stone' if j%2 else 'stoneLight',sub=2,noise=.13,seed=i*3+j,smooth=False)
        p.sph((x,.65,h),(3.4,1.9,.48),'moss',seg=14,ring=7)
        for dx in (-1.2,1.2):p.sph((x+dx,-1.10,h-.30),(.9,.16,.55),'mossLight',seg=10,ring=6)
    p.box((0,1,11),(5.7,3.8,22),'stoneDark',bevel=.45)
    p.box((0,-1.18,11.7),(5.5,.20,20.2),'water',bevel=.07)
    for x in (-2.0,-.7,.7,2.0):p.box((x,-1.31,11.7),(.16,.035,19.0),'waterLight',bevel=.035)
    p.box((0,1,22.1),(6.1,4.0,.75),'moss',bevel=.25)
    p.sph((0,-1.30,1.4),(4.7,1.1,.65),'waterLight',seg=24,ring=8)
    for x in (-12,12):
        p.sweep([(x,-1.0,17),(x+.8,-1.25,13),(x-.3,-1.25,9),(x+.6,-1.3,5)],[.16]*4,'mossDark',seg=7)
        for z in (5,8,11,14):p.sph((x+.4,-1.35,z),(.6,.12,.9),'mossLight',seg=10,ring=6,rot=(0,.3,0))
    return add('Jungle',p)

def totem():
    p=P('Jungle_FriendlyTotem')
    p.box((0,0,.4),(4.2,4.2,.8),'stoneDark',bevel=.16)
    p.box((0,0,4.5),(3.2,2.6,7.4),'wood',bevel=.25)
    p.box((0,0,8.4),(4.0,3.2,.75),'moss',bevel=.16)
    for z in (1.4,7.4):p.box((0,-1.40,z),(3.4,.18,.55),'gold',bevel=.05)
    for x in (-.68,.68):
        p.sph((x,-1.34,5.9),(.59,.12,.66),'cream',seg=12,ring=8)
        p.sph((x,-1.47,5.8),(.22,.07,.25),'eye',seg=10,ring=7)
    p.sph((0,-1.47,4.85),(.30,.40,.45),'woodDark',seg=12,ring=8)
    p.box((0,-1.34,3.7),(1.8,.17,.7),'cream',bevel=.15)
    p.box((0,-1.45,3.75),(1.35,.10,.17),'woodDark',bevel=.05)
    for x in (-1.2,1.2):p.sph((x,-1.40,4.5),(.38,.08,.2),'coral',seg=8,ring=5)
    return add('Jungle',p)

def fern():
    p=P('Jungle_LeafyFern')
    for i in range(7):
        a=2*pi*i/7;L=3.8+(.4 if i%2 else 0)
        pts=[(0,0,0),(.7*math.cos(a),.7*math.sin(a),2.6),(L*math.cos(a),L*math.sin(a),1.0)]
        p.sweep(pts,[(.08,.04),(.65,.12),(.01,.02)],'leaf'if i%2 else 'leafLight',seg=8,uhint=(-math.sin(a),math.cos(a),0))
        for j in (1,2,3):
            t=j/4;base=(L*t*math.cos(a),L*t*math.sin(a),2.6-(1.6*t))
            for s in (-1,1):
                tip=(base[0]+s*.65*math.sin(a),base[1]-s*.65*math.cos(a),base[2]+.1)
                p.sweep([base,tip],[(.18,.05),(.02,.02)],'leafDark',seg=6)
    return add('Jungle',p,'Sway')

def macaw():
    p=P('Jungle_TropicalMacaw')
    p.sweep([(-2.5,0,.7),(0,0,.55),(2.5,0,.85)],[.34,.40,.28],'woodDark',seg=10)
    p.sph((0,0,2.5),(.87,.70,1.35),'macawRed',seg=18,ring=12)
    p.sph((0,-.10,4.1),(.85,.75,.85),'macawRed',seg=18,ring=12)
    for s in (-1,1):p.sph((s*.72,.12,2.5),(.28,.63,1.0),'macawBlue',seg=14,ring=10,rot=(0,s*.20,0))
    p.sph((0,-.70,4.08),(.68,.28,.52),'cream',seg=16,ring=10)
    eyes(p,-.89,4.22,.35,.16)
    p.lathe([(0,0),(.35,0),(.29,.6),(0,.90)],'eye',seg=12,c=(0,-.94,4.04),rot=(pi/2,0,0))
    for x in (-.30,0,.30):p.sweep([(x,.4,1.6),(x,.80,.9),(x,1.5,.25)],[(.20,.10),(.23,.08),(.04,.03)],'macawBlue'if x else 'macawRed',seg=8)
    for x in (-.3,.3):p.sweep([(x,-.1,1.45),(x,-.25,.88),(x,-.65,.8)],[.11]*3,'eye',seg=8)
    return add('Jungle',p,'Sway')

def frozenheart():
    p=P('AbsoluteZero_FrozenHeart')
    p.lathe([(0,0),(7.4,0),(7.4,.7),(6.7,1.1),(6.7,1.5),(0,1.5)],'steelDark',seg=28)
    ring(p,(0,0,1.55),6.1,.13,'cyan')
    for a in (0,pi/2,pi,3*pi/2):
        x,y=5*math.cos(a),5*math.sin(a)
        p.box((x,y,5),(1.4,1.4,7),'ice',bevel=.15)
        p.box((x,y-.72,5),(.30,.08,4.9),'cyan',bevel=.04)
    gem(p,(0,0,2),8.0,1.25,'cyan')
    ring(p,(0,0,11.3),5.8,.15,'ice',n=36)
    ring(p,(0,0,13.6),3.9,.15,'violet',n=32)
    for x,y in ((-3,-2),(3,-2),(0,3)):gem(p,(x,y,1.5),2.3,.45,'snow')
    return add('AbsoluteZero',p)

def penguin(name='AbsoluteZero_PolarPenguin',stage='AbsoluteZero',crown=False):
    p=P(name)
    p.sph((0,0,2.15),(1.25,.98,1.65),'steelDark',seg=20,ring=14)
    p.sph((0,-.82,2.0),(.94,.32,1.28),'snow',seg=18,ring=12)
    p.sph((0,-.03,3.94),(1.0,.90,.98),'steelDark',seg=20,ring=14)
    for x in (-.39,.39):
        p.sph((x,-.82,4.16),(.31,.12,.37),'snow',seg=12,ring=9)
        p.sph((x,-.94,4.13),(.12,.055,.17),'eye',seg=10,ring=7)
        p.sph((x+.035,-.99,4.18),.035,'white',seg=6,ring=4)
    p.sph((0,-1.0,3.87),(.32,.42,.16),'gold',seg=12,ring=8)
    for s in (-1,1):
        p.sph((s*.62,-.37,.3),(.54,.77,.30),'gold',seg=14,ring=8)
        p.sph((s*1.25,.05,2.35),(.26,.55,1.0),'steelDark',seg=14,ring=10,rot=(0,-s*.38,0))
    ring(p,(0,0,3.12),.98,.15,'blue')
    p.sweep([(.62,-.70,3.1),(.78,-.91,2.7),(.61,-1.0,2.38)],[(.20,.09)]*3,'blue',seg=8)
    if crown:
        p.cyl((0,0,4.68),.92,.92,.20,'gold',seg=20)
        for x,h in ((-.60,.7),(0,1.1),(.60,.7)):gem(p,(x,0,4.81),h,.19,'cyan')
        p.lathe([(0,0),(2.1,0),(2.1,.30),(1.85,.50),(0,.50)],'ice',seg=24)
    return add(stage,p)

def pine():
    p=P('AbsoluteZero_FrozenPine')
    p.cyl((0,0,0),.43,.32,9.5,'woodDark',seg=12)
    for z,r,h in ((1.1,3.0,4.2),(3.9,2.5,3.9),(6.5,1.9,3.6)):
        p.lathe([(r,0),(r*.91,.45),(r*.56,h*.55),(0,h)],'iceDark',seg=16,c=(0,0,z))
        # Snow caps follow the outer cone, lifted above it, so the white layer remains visible.
        p.lathe([(r*.83,1.0),(r*.60,h*.49),(r*.30,h*.78),(0,h+.32)],'snow',seg=16,c=(0,0,z),smooth=False)
    for x,y in ((-2.7,-.8),(2.5,.5)):gem(p,(x,y,0),1.9,.42,'ice')
    return add('AbsoluteZero',p)

def obelisk():
    p=P('Portal_AuroraObelisk')
    p.lathe([(0,0),(1.8,0),(1.8,.40),(1.5,.70),(0,.70)],'steelDark',seg=20)
    p.box((0,0,4.8),(1.5,1.5,8.4),'steelDark',bevel=.17)
    p.box((0,-.79,4.6),(.25,.08,5.0),'cyan',bevel=.03)
    for z in (2.4,4.7,7.0):p.box((0,-.85,z),(1.1,.10,.18),'violet',rot=(0,.30,0),bevel=.02)
    gem(p,(0,0,9.0),2.0,.64,'cyan')
    for x in (-.8,.8):gem(p,(x,0,.7),1.6,.28,'ice')
    return add('Portal',p)

def halo():
    p=P('Portal_CrystalHalo')
    p.box((0,0,.4),(11.6,3.0,.80),'steelDark',bevel=.15)
    ring(p,(0,0,6.0),5.2,.45,'steelDark',vertical=True,n=40)
    ring(p,(0,-.45,6.0),4.76,.17,'cyan',vertical=True,n=40)
    for a in (pi/4,3*pi/4,5*pi/4,7*pi/4):
        p.box((5.2*math.cos(a),-.55,6.0+5.2*math.sin(a)),(.5,.12,.5),'violet',rot=(0,pi/4,0),bevel=.04)
    for x in (-5.0,5.0):gem(p,(x,0,.8),2.5,.40,'ice')
    return add('Portal',p)

def append_desert_life():
    source=ROOT/'outputs/DesertLife2026/DesertLife.blend'
    with bpy.data.libraries.load(str(source),link=False)as(data_from,data_to):
        data_to.objects=list(data_from.objects)
    count=0
    for o in data_to.objects:
        if o is None or o.type!='MESH':continue
        o.name='Desert_'+o.name
        o.data=o.data.copy()
        for uv in o.data.uv_layers:
            for loop in uv.data:loop.uv.x *= .5 # preserve the original 64-column palette in 128 columns.
        o.data.materials.clear();o.data.materials.append(lib._MAT)
        add('Desert',o);count+=1
    assert count==19

def asset_metrics(o):
    vs=[v.co for v in o.data.vertices]
    lo=[min(v[i]for v in vs)for i in range(3)];hi=[max(v[i]for v in vs)for i in range(3)]
    tri=sum(len(p.vertices)-2 for p in o.data.polygons)
    assert 0<tri<=10000,(o.name,tri)
    assert o.data.uv_layers and abs(lo[2])<.0001
    assert all(math.isfinite(v[i])for v in vs for i in range(3))
    return {'stage':o['Stage'],'triangles':tri,'blender_size':[round(hi[i]-lo[i],4)for i in range(3)],'local_min':lo,'local_max':hi,'motion':o.get('StageDecorMotion'),'front':'Blender -Y; Roblox -Z','base_pivot':True}

def layout_library():
    for row,stage in enumerate(STAGE_IDS):
        objs=[o for o in ASSETS if o['Stage']==stage]
        for i,o in enumerate(objs):o.location=((i%11)*24,(row*2+i//11)*28,0)

def export_assets():
    lib.export_fbx(ASSETS,'AllStages.fbx')
    for stage in STAGE_IDS:lib.export_fbx([o for o in ASSETS if o['Stage']==stage],stage+'.fbx')
    bpy.ops.object.select_all(action='DESELECT')
    for o in ASSETS:o.select_set(True)
    bpy.context.view_layer.objects.active=ASSETS[0]
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'AllStages.blend'))

def render_previews():
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
    scene.cycles.use_denoising=True;scene.render.threads_mode='FIXED';scene.render.threads=8
    scene.render.resolution_x=1000;scene.render.resolution_y=820;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
    scene.view_settings.view_transform='AgX'
    scene.world.color=(.38,.38,.38);scene.world.use_nodes=True
    scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.50,.63,.80,1)
    scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.65
    camera_data=bpy.data.cameras.new('PreviewCamera');camera=bpy.data.objects.new('PreviewCamera',camera_data);scene.collection.objects.link(camera);scene.camera=camera
    camera.data.type='ORTHO'
    light_data=bpy.data.lights.new('Softbox','AREA');light=bpy.data.objects.new('Softbox',light_data);scene.collection.objects.link(light);light.location=(-14,-19,33);light_data.energy=5200;light_data.shape='DISK';light_data.size=16
    light.rotation_euler=(Vector((0,0,4))-light.location).to_track_quat('-Z','Y').to_euler()
    fill_data=bpy.data.lights.new('Fill','AREA');fill=bpy.data.objects.new('Fill',fill_data);scene.collection.objects.link(fill);fill.location=(15,8,18);fill_data.energy=2600;fill_data.size=12
    fill.rotation_euler=(Vector((0,0,4))-fill.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;floor.name='PreviewGround'
    mat=bpy.data.materials.new('PreviewGroundMaterial');mat.diffuse_color=(.7,.8,.85,1);mat.use_nodes=True;floor.data.materials.append(mat)
    plans={
      'Starter':{'Starter_ScoutIgloo':(-4,2,0),'Starter_ScarfSnowman':(4,-3,0),'Starter_ExpeditionSled':(3,4,0)},
      'Desert':{'Desert_OasisGarden':(-4,3,0),'Desert_SaguaroSmall':(-11,-3,0),'Desert_CamelResting':(5,0,0),'Desert_FennecFox':(6,-7,0),'Desert_BarrelCactus':(-6,-7,0),'Desert_FlowerPatch':(-1,-7,0)},
      'Cursed':{'Cursed_MoonShrine':(-4,2,0),'Cursed_FriendlyGhost':(4,-2,2),'Cursed_PotionCauldron':(5,4,0)},
      'Crystal':{'Crystal_PrismaticGeode':(-4,3,0),'Crystal_LuminousMushrooms':(5,-2,0),'Crystal_GemCart':(6,6,0)},
      'Retro':{'Retro_ArcadeCabinet':(-5,2,0),'Retro_GiantJoystick':(3,5,0),'Retro_PixelBuddy':(2,-4,0)},
      'Jungle':{'Jungle_TempleWaterfall':(-2,5,0),'Jungle_FriendlyTotem':(7,-2,0),'Jungle_LeafyFern':(-5,-5,0),'Jungle_TropicalMacaw':(1,-6,0)},
      'AbsoluteZero':{'AbsoluteZero_FrozenHeart':(-3,3,0),'AbsoluteZero_PolarPenguin':(5,-4,0),'AbsoluteZero_FrozenPine':(8,6,0)},
      'Portal':{'Portal_CrystalHalo':(0,5,0),'Portal_CrystalGuardian':(-5,-2,0),'Portal_AuroraObelisk':(6,2,0)}
    }
    floors={'Starter':(.65,.78,.86,1),'Desert':(.67,.39,.17,1),'Cursed':(.18,.15,.23,1),'Crystal':(.26,.41,.48,1),'Retro':(.20,.35,.30,1),'Jungle':(.22,.36,.26,1),'AbsoluteZero':(.58,.73,.84,1),'Portal':(.30,.43,.59,1)}
    original={o:o.location.copy()for o in ASSETS}
    for index,stage in enumerate(STAGE_IDS):
        for o in ASSETS:o.hide_render=o.name not in plans[stage]
        for name,loc in plans[stage].items():bpy.data.objects[name].location=loc
        mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=floors[stage]
        target=Vector((0,0,12 if stage=='Jungle'else 5))
        camera.location=target+Vector((22,-34,24));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
        camera.data.ortho_scale=65 if stage=='Jungle'else 39 if stage=='Desert'else 32
        scene.render.filepath=str(OUT/(stage+'-preview.png'))
        progress('rendering',stage=stage,index=index+1,total=8)
        bpy.ops.render.render(write_still=True)
    for o in ASSETS:o.hide_render=False;o.location=original[o]
    for o in (camera,light,fill,floor):bpy.data.objects.remove(o,do_unlink=True)
    # Save the editable asset library, not the temporary photographic arrangement.
    scene.camera=None
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'AllStages.blend'))

def main():
    progress('building')
    lib.clear_scene();lib.make_atlas()
    for stage in STAGE_IDS:
        c=bpy.data.collections.new(stage);bpy.context.scene.collection.children.link(c);STAGES[stage]=c
    igloo();snowman();sled()
    oasis();caravan();sunarch();append_desert_life()
    moon_shrine();ghost();cauldron()
    crystal_garden();mushrooms();gemcart()
    arcade();joystick();alien()
    waterfall();totem();fern();macaw()
    frozenheart();penguin();pine()
    penguin('Portal_CrystalGuardian','Portal',True);obelisk();halo()
    metrics={o.name:asset_metrics(o)for o in ASSETS}
    (OUT/'manifest.json').write_text(json.dumps({'source':'Blender 5.2','models':metrics,'count':len(ASSETS),'triangles':sum(m['triangles']for m in metrics.values()),'fbx_global_scale':.01,'installed_in_studio':False},indent=2),encoding='utf-8')
    # Pack the atlas so the saved .blend and FBX stay self-contained.
    for image in bpy.data.images:
        if image.name=='LifeAtlas':image.pack()
    layout_library();progress('exporting',models=len(ASSETS))
    export_assets();render_previews()
    progress('complete',models=len(ASSETS),triangles=sum(m['triangles']for m in metrics.values()),previews=8)

if __name__=='__main__':
    try:main()
    except Exception:
        progress('failed',traceback=traceback.format_exc())
        raise
