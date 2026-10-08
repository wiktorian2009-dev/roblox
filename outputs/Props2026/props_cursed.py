
from prop_lib import *
from props_desert import bez, cute_face

def dead_tree():
    p = P("DeadTree"); n = 14; trunk = bez((0,0,0),(0.9,0.3,4.5),(-1.3,-0.4,8.5),(0.6,0.2,13.0), n)
    p.sweep(trunk, [1.75-1.2*(i/(n-1)) for i in range(n)], "deadWood", seg=8)
    for k in range(5):
        a = 2*math.pi*k/5 + 0.3; c, s = math.cos(a), math.sin(a); p.sweep([(1.0*c,1.0*s,1.4),(2.0*c,2.0*s,0.55),(3.2*c,3.2*s,0.12)], [0.8,0.52,0.2], "deadWood", seg=6)
    for (idx, sx, sy, L) in ((4,1,0.3,4.2),(6,-1,-0.4,4.6),(8,1,0.5,3.8),(10,-1,0.2,3.2),(12,1,-0.3,2.4)):
        b = trunk[idx]; r = 0.62-0.03*idx/2; mid = (b[0]+sx*L*0.55, b[1]+sy*L*0.5, b[2]+L*0.35); end = (b[0]+sx*L, b[1]+sy*L, b[2]+L*0.85)
        p.sweep([b, mid, end], [r, r*0.7, r*0.22], "deadWood", seg=6); p.sweep([mid, (mid[0]+sx*1.4, mid[1]-sy*1.2, mid[2]+1.5)], [r*0.45, r*0.12], "deadWood", seg=5)
    p.sph((1.0,-1.1,0.6), (1.3,1.0,0.5), "moss")
    return p.finish()

def tomb_round():
    p = P("TombstoneRound")
    p.box((0,0,0.5), (4.6,2.8,1.0), "stoneDark", bevel=0.15, smooth=True); p.box((0,0,2.9), (3.5,1.5,3.8), "tomb", bevel=0.12, smooth=True)
    p.cyl((0,-0.75,4.8), 1.75, 1.75, 1.5, "tomb", seg=16, rot=(-math.pi/2,0,0))
    p.box((0,-0.78,4.5), (0.34,0.16,1.7), "stoneDark"); p.box((0,-0.78,4.85), (1.1,0.16,0.32), "stoneDark")
    p.sph((-1.4,-0.4,1.1), (1.3,1.0,0.6), "moss"); p.sph((1.7,0.1,0.9), (1.0,0.8,0.5), "moss"); p.sph((-1.25,-0.5,5.8), (0.75,0.45,0.5), "moss")
    for k in range(6): p.cone((-2.0+k*0.8, -1.6, 0.9), 0.14, 0.9, "leafDark", seg=4, rot=(0.15*(k%3-1), 0.2*(k%2-0.5), 0))
    return p.finish()

def tomb_cross():
    p = P("TombstoneCross")
    p.box((0,0,0.5), (4.4,3.0,1.0), "stoneDark", bevel=0.15, smooth=True); p.box((0,0,3.5), (1.3,1.3,5.0), "tomb", bevel=0.14, smooth=True); p.box((0,0,4.6), (3.6,1.3,1.3), "tomb", bevel=0.14, smooth=True)
    p.sph((1.2,-0.5,1.1), (1.2,1.0,0.6), "moss"); p.sph((-0.5,-0.6,6.0), (0.6,0.4,0.35), "moss"); p.sph((-1.6,0.2,4.6), (0.7,0.7,0.4), "moss")
    p.sph((-1.5,-1.6,1.15), 0.3, "pink", seg=8, ring=6); p.sph((1.6,-1.5,1.15), 0.3, "yellow", seg=8, ring=6)
    return p.finish()

def pumpkin():
    p = P("Pumpkin")
    p.lathe([(3.5*math.sin(a), 2.9-2.5*math.cos(a)) for a in np.linspace(0.0, math.pi, 14)], "pumpkin", seg=24, rmod=lambda th, i: 1+0.09*math.cos(8*th))
    p.sweep([(0,0,5.2),(0.25,0.05,5.9),(0.75,0.1,6.45)], [0.5,0.4,0.3], "leafDark", seg=6)
    for s in (-1, 1): p.cone((s*1.25,-3.35,3.55), 1.0, 0.8, "yellow", seg=3, rot=(math.pi/2,0,s*0.3), smooth=False, flat=True)
    p.cone((0,-3.45,2.75), 0.6, 0.6, "yellow", seg=3, rot=(math.pi/2,0,math.pi), smooth=False, flat=True)
    for i, x in enumerate(np.linspace(-2.0, 2.0, 7)): p.box((x,-3.3,1.85+(0.45 if i % 2 else 0)), (0.68,0.5,0.75), "yellow", flat=True)
    return p.finish()

def cauldron():
    p = P("Cauldron")
    p.lathe([(0.001,1.0),(1.8,1.0),(3.2,2.2),(3.85,4.0),(3.7,5.4),(3.3,6.0),(3.0,5.75),(0.001,5.4)], seg=22, colors=["coal","coal","navy","navy","coal","coal","lime"])
    p.sweep([(3.35*math.cos(a), 3.35*math.sin(a), 6.0) for a in np.linspace(0, 2*math.pi, 22, endpoint=False)], [0.5]*22, "stoneDark", seg=8, closed=True)
    for (x, y, z, r) in ((0.6,0.3,5.9,0.65),(-1.0,-0.4,5.85,0.5),(1.5,-0.8,5.8,0.38),(-0.2,1.0,6.4,0.32),(-1.7,1.1,5.7,0.3)): p.sph((x,y,z), r, "leafLight", seg=8, ring=6)
    for k in range(3): a = 2*math.pi*k/3+0.5; p.sph((2.1*math.cos(a), 2.1*math.sin(a), 0.7), (0.9,0.9,0.7), "coal")
    for s in (-1, 1): p.sweep(bez((s*3.8,0,5.0),(s*5.1,0,5.3),(s*5.1,0,3.3),(s*3.9,0,3.3),10), [0.3]*10, "stoneDark", seg=6)
    for s in (-1, 1): p.sph((s*1.1,-3.55,3.6), (0.4,0.15,0.55), "lime", seg=8, ring=6, flat=True)
    for a in np.linspace(0.2*math.pi, 0.8*math.pi, 5): p.sph((1.0*math.cos(a), -3.6, 2.6-0.5*math.sin(a)+0.3), 0.14, "lime", seg=5, ring=4, flat=True)
    return p.finish()

def ghost():
    p = P("Ghost")
    p.lathe([(2.7,0),(2.75,1.8),(2.8,3.2),(2.68,4.3),(2.2,5.3),(1.4,6.0),(0.001,6.35)], "ghost", seg=22, zmod=lambda th, i: (0.7+0.7*math.cos(5*th)) if i == 0 else 0.0)
    for s in (-1, 1):
        p.sph((s*3.15,0,3.3), (0.55,0.75,1.0), "ghost", rot=(0, s*0.6, 0)); p.sph((s*1.0,-2.6,4.15), (0.45,0.2,0.62), "coal", seg=10, ring=8, flat=True)
        p.sph((s*0.95,-2.72,4.35), 0.12, "white", seg=6, ring=4, flat=True); p.sph((s*1.75,-2.35,3.3), (0.45,0.15,0.28), "pink", seg=8, ring=6, flat=True)
    p.sph((0,-2.7,3.0), (0.4,0.2,0.5), "coal", seg=10, ring=8, flat=True)
    return p.finish()

def fence():
    p = P("IronFence")
    for z in (1.9, 4.5): p.box((0,0,z), (12.6,0.36,0.32), "coal")
    for i in range(7): x = -5.4+i*1.8; p.cyl((x,0,0), 0.17, 0.17, 6.0, "coal", seg=6); p.cone((x,0,6.0), 0.32, 1.0, "purpleDark", seg=6)
    for s in (-1, 1): p.cyl((s*6.2,0,0), 0.45, 0.45, 6.9, "coal", seg=8); p.sph((s*6.2,0,7.15), 0.62, "purple", seg=10, ring=8)
    return p.finish()

def candles():
    p = P("Candles"); p.cyl((0,0,0), 3.3, 3.3, 0.35, "stoneDark", seg=18)
    for (x, y, h, r) in ((0,0,4.2,0.85),(1.7,0.8,2.7,0.68),(-1.5,1.0,3.3,0.72)):
        p.cyl((x,y,0.35), r, r, h, "candle", seg=10); p.sph((x,y,0.35+h), (r,r,0.2), "candle", seg=10, ring=5); p.sph((x+r*0.75,y,0.35+h-0.55), (0.22,0.22,0.55), "candle", seg=6, ring=5)
        p.cone((x,y,0.35+h+0.05), 0.3, 1.0, "orange", seg=6); p.cone((x,y,0.35+h+0.15), 0.17, 0.62, "yellow", seg=6)
    return p.finish()
BUILDERS = [dead_tree, tomb_round, tomb_cross, pumpkin, cauldron, ghost, fence, candles]
