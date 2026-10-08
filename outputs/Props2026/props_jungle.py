
from prop_lib import *
from props_desert import bez

def leafblade(p, base, az, L, wmax, droop, col, rise=0.6, stem=0.3):
    d = (math.cos(az), math.sin(az)); pts = []; ws = []
    for j in range(10):
        t = j/9; pts.append((base[0]+d[0]*L*t, base[1]+d[1]*L*t, base[2] + L*rise*math.sin(math.pi*t*0.85)*(1-t*0.3) - droop*t*t*L*0.5))
        if t < stem: ws.append((0.1, 0.06))
        else: u = (t-stem)/(1-stem); ws.append((0.1 + wmax*max(0.0, math.sin(math.pi*u**0.7))**0.9, 0.07))
    p.sweep(pts, ws, col, seg=6, uhint=(-d[1], d[0], 0))

def banana():
    p = P("BananaPlant"); p.sph((0,0,0.1), (2.4,2.4,0.4), "moss"); p.lathe([(1.3,0),(1.15,3),(0.95,6.5),(0.7,8.2)], "leafLight", seg=10)
    for k in range(8): leafblade(p, (0,0,8.0), 2*math.pi*k/8+0.3, 9.0, 1.9, 1.6, "leaf" if k % 2 else "leafDark", rise=0.7)
    p.sph((0,0,7.1), (0.6,0.6,1.0), "purple", seg=8, ring=6)
    for k in range(5): a = k*0.45-0.9; p.sweep(bez((0.9*math.cos(a)+0.3,0.9*math.sin(a),7.4),(2.0*math.cos(a)+0.3,2.0*math.sin(a),7.3),(2.5*math.cos(a)+0.3,2.5*math.sin(a),6.0),(2.1*math.cos(a)+0.3,2.1*math.sin(a),5.0),8), [0.36,0.36,0.36,0.34,0.3,0.27,0.22,0.12], "yellow", seg=6)
    return p.finish()
def monstera():
    p = P("GiantLeafPlant")
    for k, (az, L, w, col) in enumerate(((0.2,6.8,2.7,"leaf"),(1.4,7.6,3.0,"leafDark"),(2.6,6.4,2.6,"leaf"),(3.8,7.2,2.9,"leafDark"),(5.0,6.6,2.7,"leaf"),(0.8,4.4,1.8,"leafLight"),(3.2,4.6,1.9,"leafLight"))): leafblade(p, (0.3*math.cos(az),0.3*math.sin(az),0.2), az, L, w, 0.5, col, rise=0.4, stem=0.42)
    return p.finish()
def fern():
    p = P("Fern")
    for k in range(17): leafblade(p, (0,0,0.2), 2*math.pi*k/17+(0.2 if k % 2 else 0), 5.5+0.8*(k % 3), 0.6, 1.2, "leaf" if k % 2 else "leafLight", rise=0.85, stem=0.06)
    p.sph((0,0,0.3), (0.8,0.8,0.5), "moss"); return p.finish()
def toadstools():
    p = P("Toadstools")
    def shroom(x, y, s, cap):
        p.lathe([(0.8*s,0),(1.0*s,1.3*s),(0.85*s,2.7*s),(0.9*s,3.3*s)], "cream", seg=14, c=(x,y,0))
        p.lathe([(2.7*s,0),(3.0*s,0.3*s),(2.85*s,1.0*s),(2.2*s,1.75*s),(1.2*s,2.25*s),(0.001,2.4*s)], cap, seg=18, c=(x,y,3.1*s))
        for (dx, dy, dz, r) in ((1.3,0.8,1.9,0.45),(-1.1,1.2,1.8,0.4),(0.3,-1.6,1.85,0.42),(-0.4,0.2,2.3,0.32),(1.7,-0.7,1.4,0.34)): p.sph((x+dx*s, y+dy*s, 3.1*s+dz*s), (r*s,r*s,r*s*0.55), "cream", seg=8, ring=5)
    shroom(0,0,1.0,"red"); shroom(4.3,1.5,0.62,"red"); shroom(-3.9,1.1,0.7,"orange")
    for k in range(9): a = 2*math.pi*k/9; p.cone((6*math.cos(a)*0.0+ (k-4)*1.2, 3.2+0.4*(k % 2), 0), 0.22, 1.2, "leaf", seg=4)
    return p.finish()
def hibiscus():
    p = P("HibiscusBush")
    for (x, y, z, r, col) in ((0,0,2.4,3.2,"leafDark"),(-2.3,0.8,1.8,2.3,"leaf"),(2.4,-0.4,1.9,2.4,"leafDark"),(0.3,-2.0,1.6,2.0,"leaf"),(-0.8,1.9,2.0,2.2,"leaf")): p.sph((x,y,z), (r,r,r*0.85), col, seg=12, ring=8)
    for (x, y, z) in ((0.2,0.1,5.4),(-2.2,0.9,3.9),(2.4,-0.3,4.0),(0.4,-2.0,3.4),(-0.9,1.8,4.2),(1.3,1.2,4.9)):
        for k in range(5): a = 2*math.pi*k/5; p.sph((x+0.62*math.cos(a), y+0.62*math.sin(a), z), (0.78,0.56,0.13), "hib", seg=8, ring=5, rot=(0,0,a))
        p.sph((x,y,z+0.12), 0.26, "yellow", seg=6, ring=4); p.sweep([(x,y,z+0.1),(x+0.15,y,z+0.7)], [0.06,0.05], "gold", seg=4)
    return p.finish()
def tiki():
    p = P("TikiTotem")
    p.box((0,0,1.2), (4.4,4.4,2.4), "brown", bevel=0.2, smooth=True); p.box((0,0,4.9), (3.8,3.8,5.0), "wood", bevel=0.2, smooth=True)
    for z, c in ((3.3,"teal2"),(4.1,"yellow"),(6.0,"teal2")): p.box((0,-1.95,z), (3.6,0.12,0.4), c)
    p.box((0,0,9.6), (4.4,4.4,4.4), "terraLight", bevel=0.2, smooth=True)
    for s in (-1, 1):
        p.sph((s*1.0,-2.2,10.2), (0.55,0.2,0.55), "white", seg=8, ring=6, flat=True); p.sph((s*1.0,-2.35,10.2), (0.26,0.1,0.26), "coal", seg=6, ring=4, flat=True)
        p.box((s*1.0,-2.25,10.95), (1.2,0.25,0.25), "coal", rot=(0,s*0.3,0)); p.cone((s*2.0,0,11.2), 0.5, 1.6, "cream", seg=6, rot=(0,-s*0.7,0))
    p.box((0,-2.4,9.3), (0.6,0.6,1.3), "terra", rot=(0.2,0,0)); p.box((0,-2.25,8.2), (2.4,0.3,0.6), "coal")
    for x in (-0.7,-0.25,0.25,0.7): p.box((x,-2.42,8.25), (0.3,0.12,0.3), "cream")
    for k in range(7): leafblade(p, (0,0,11.7), 2*math.pi*k/7, 3.0, 0.5, 1.3, "leaf" if k % 2 else "leafDark", rise=0.5, stem=0.1)
    return p.finish()
def mossy_boulder():
    p = P("MossyBoulder"); p.ico((0,0,2.6), (4.2,3.6,3.0), "mossRock", sub=2, noise=0.2, seed=21); p.ico((4.2,1.2,1.2), (2.0,1.8,1.4), "stoneDark", sub=1, noise=0.25, seed=22)
    p.ico((0,0.1,4.3), (3.4,3.0,1.3), "moss", sub=2, noise=0.22, seed=21); p.ico((4.1,1.2,2.1), (1.6,1.4,0.7), "moss", sub=1, noise=0.2, seed=22)
    for k in range(5): leafblade(p, (-2.6,-1.8,0.3), 0.6*k-0.6, 2.4, 0.3, 1.0, "leafLight", rise=0.9, stem=0.05)
    return p.finish()
def bamboo():
    p = P("Bamboo")
    for (x, y, h, r) in ((0,0,14,0.62),(1.5,0.6,11.6,0.5),(-1.4,0.5,12.6,0.54),(0.6,-1.4,9.6,0.46),(-0.8,-1.1,10.6,0.48)):
        segs = int(h/2.4)
        for s_ in range(segs): z = s_*2.4; p.cyl((x,y,z), r, r, 2.3, "bamboo", seg=8); p.sph((x,y,z+2.3), (r*1.18,r*1.18,0.14), "leafLight", seg=8, ring=4)
        for k in range(5): leafblade(p, (x,y,segs*2.4-0.2), 2*math.pi*k/5+x, 3.2, 0.4, 1.2, "leaf" if k % 2 else "leafDark", rise=0.4, stem=0.05)
    return p.finish()
def lily_pad():
    p = P("LilyPad"); p.lathe([(0.001,0.0),(4.6,0.0),(4.6,0.3),(0.001,0.3)], "leaf", seg=26); p.cyl((0,0,0.05), 0.1, 0.1, 0.1, "leafDark", seg=4)
    for k in range(9): a = 2*math.pi*k/9; p.sph((-0.6+1.0*math.cos(a), 0.2+1.0*math.sin(a), 0.9), (0.9,0.42,0.16), "magenta", seg=8, ring=5, rot=(0, -0.7, a))
    for k in range(6): a = 2*math.pi*k/6+0.3; p.sph((-0.6+0.55*math.cos(a), 0.2+0.55*math.sin(a), 1.25), (0.6,0.32,0.14), "pink", seg=8, ring=5, rot=(0, -0.9, a))
    p.sph((-0.6,0.2,1.3), 0.3, "yellow", seg=6, ring=4)
    p.sph((2.4,-0.6,0.95), (0.95,0.85,0.65), "leafLight"); p.sph((2.4,-1.25,1.25), (0.6,0.5,0.45), "leafLight")
    for s in (-1, 1): p.sph((2.4+s*0.32,-1.45,1.75), 0.26, "leafLight", seg=8, ring=6); p.sph((2.4+s*0.32,-1.62,1.78), 0.13, "coal", seg=6, ring=4, flat=True)
    return p.finish()
BUILDERS = [banana, monstera, fern, toadstools, hibiscus, tiki, mossy_boulder, bamboo, lily_pad]
