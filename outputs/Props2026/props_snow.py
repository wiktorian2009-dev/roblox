
from prop_lib import *

def snow_pine():
    p = P("SnowPine")
    p.cyl((0,0,0), 0.75, 0.6, 2.6, "wood", seg=10)
    tiers = [(4.6, 4.6, 1.8), (3.7, 4.2, 4.6), (2.9, 3.8, 7.3), (2.1, 3.3, 9.7)]
    for i, (r, h, z0) in enumerate(tiers):
        p.cone((0,0,z0), r, h, "teal" if i % 2 == 0 else "tealDark", seg=10, smooth=False)
        fh = h*0.52; rc = r*fh/h*1.07
        p.cone((0,0,z0+h-fh), rc, fh*1.04, "white", seg=10, smooth=False)
        for k in range(9):
            a = 2*math.pi*k/9 + (0.3 if i % 2 else 0)
            p.sph((rc*math.cos(a)*0.93, rc*math.sin(a)*0.93, z0+h-fh+0.15), (r*0.11, r*0.11, r*0.085), "white", seg=6, ring=4)
    p.sph((0,0,13.3), 0.7, "yellow", seg=6, ring=4, smooth=False)
    for (i, a, f, c) in ((0,.4,.22,"pink"),(0,2.2,.3,"yellow"),(0,4.2,.18,"iceBlue"),(1,1.2,.25,"yellow"),(1,3.4,.2,"pink"),(1,5.3,.3,"iceBlue"),(2,.2,.22,"pink"),(2,2.6,.28,"yellow"),(3,1.0,.2,"iceBlue"),(3,4.0,.25,"pink")):
        r, h, z0 = tiers[i]; rr = r*(1-f)+0.12; p.sph((rr*math.cos(a), rr*math.sin(a), z0+h*f), 0.36, c, seg=8, ring=6)
    p.sph((0,0,0.1), (3.0, 3.0, 0.6), "white")
    return p.finish()

def _front(cz, rxy, rz, z): return -rxy*math.sqrt(max(0.0, 1-((z-cz)/rz)**2))
def snowman():
    p = P("Snowman"); W = "white"
    p.sph((0,0,2.3), (2.5,2.5,2.35), W); p.sph((0,0,5.3), (1.9,1.9,1.8), W); p.sph((0,0,7.75), (1.4,1.4,1.35), W)
    p.cyl((0,0,8.9), 1.0, 1.0, 1.35, "navy", seg=16); p.cyl((0,0,8.85), 1.6, 1.6, 0.2, "navy", seg=20); p.cyl((0,0,8.98), 1.03, 1.03, 0.4, "pink", seg=16)
    p.cone((0,-1.15,7.6), 0.24, 1.3, "orange", seg=8, rot=(math.pi/2,0,0))
    for s in (-1, 1): p.sph((s*0.5,-1.22,8.05), 0.17, "coal", seg=8, ring=6); p.sph((s*0.85,-1.05,7.6), (0.26,0.1,0.16), "pink", seg=8, ring=6, flat=True)
    for k in range(5):
        a = math.radians(40 + k*25); p.sph((-0.62*math.cos(a)*(-1) + 0, -1.3, 7.05 - 0.22*math.sin(a) + 0.25), 0.1, "coal", seg=6, ring=4)
    for z in (5.75, 5.2, 4.65): p.sph((0, _front(5.3,1.9,1.8,z)-0.02, z), 0.2, "coal", seg=8, ring=6)
    p.sweep([(1.4*math.cos(2*math.pi*k/20), 1.4*math.sin(2*math.pi*k/20), 6.55) for k in range(20)], [0.34]*20, "pink", seg=8, closed=True)
    p.box((0.75,-1.45,5.8), (0.62,0.28,1.7), "pink", rot=(0,0,0.15), bevel=0.06, smooth=True)
    for s in (-1, 1):
        pts = [(s*1.7, 0, 5.4), (s*2.5, 0, 5.9), (s*3.3, 0, 6.8), (s*3.9, 0, 7.6)]
        p.sweep(pts, [0.17, 0.15, 0.12, 0.08], "brown", seg=6)
        p.sweep([(s*3.3,0,6.8),(s*3.9,0,6.7),(s*4.3,0,6.9)], [0.09,0.07,0.04], "brown", seg=5); p.sweep([(s*3.6,0,7.2),(s*3.75,0,7.9),(s*3.7,0,8.3)], [0.09,0.07,0.04], "brown", seg=5)
    return p.finish()

def snow_mound():
    p = P("SnowMound")
    p.sweep([(1.3,0.6,1.5),(1.75,0.9,4.2),(2.2,1.2,7.0)], [0.26]*3, "wood", seg=8)
    p.sweep([(2.25+0.72*math.cos(2*math.pi*k/18), 1.2, 7.6+0.72*math.sin(2*math.pi*k/18)) for k in range(18)], [0.2]*18, "stone", seg=6, closed=True)
    for (x, y, z, rx, ry, rz) in ((0,0,1.0,5.0,4.3,2.9),(-3.5,1.0,0.6,3.0,2.7,1.8),(3.4,0.6,0.55,3.1,2.6,1.9),(0.6,-2.9,0.6,2.8,2.3,1.7),(-1.4,2.3,0.8,2.8,2.4,2.1),(-0.2,0.6,2.0,2.4,2.0,1.6),(1.8,-0.6,1.7,2.0,1.8,1.4)): p.sph((x,y,z), (rx,ry,rz), "white", seg=14, ring=9)
    for (x, y, r) in ((-4.8,-2.4,0.8),(-3.6,-3.3,0.55),(4.6,-2.2,0.7),(3.4,-3.1,0.5)): p.sph((x,y,r*0.85), r, "white", seg=10, ring=7)
    return p.finish()

def ice_rock():
    p = P("IceRock")
    p.ico((0,0,1.9), (3.2,2.8,2.4), "stone", sub=2, noise=0.22, seed=3, flat=False); p.ico((3.6,1.2,1.1), (1.9,1.7,1.4), "stoneDark", sub=2, noise=0.25, seed=5); p.ico((-2.9,-1.5,0.9), (1.5,1.4,1.1), "stone", sub=2, noise=0.25, seed=8)
    p.ico((0,0,3.3), (2.6,2.3,1.1), "white", sub=2, noise=0.2, seed=3); p.ico((3.5,1.2,2.0), (1.6,1.4,0.6), "white", sub=2, noise=0.2, seed=5)
    for (x, y, h, r) in ((-0.8,-1.2,2.2,0.5),(0.6,-1.8,1.6,0.42),(2.2,-1.5,1.4,0.38)): p.cone((x,y,1.4), r, h, "iceBlue", seg=6, smooth=False)
    return p.finish()

def present():
    p = P("Present")
    p.box((0,0,1.4), (4.2,4.2,2.8), "pink", bevel=0.18, smooth=True); p.box((0,0,3.05), (4.6,4.6,0.9), "red", bevel=0.16, smooth=True)
    p.box((0,0,1.5), (0.95,4.3,3.0), "yellow", bevel=0.05); p.box((0,0,1.5), (4.3,0.95,3.0), "yellow", bevel=0.05)
    p.box((0,0,3.12), (0.95,4.7,0.95), "yellow", bevel=0.05); p.box((0,0,3.12), (4.7,0.95,0.95), "yellow", bevel=0.05)
    for s in (-1, 1):
        p.sweep([(s*1.15+s*0.95*math.cos(a), 0, 4.45+0.85*math.sin(a)) for a in np.linspace(0, 2*math.pi, 16, endpoint=False)], [0.23]*16, "yellow", seg=6, closed=True)
        p.box((s*0.45,-0.25,2.9), (0.5,0.12,1.3), "yellow", rot=(0,0,s*0.25), bevel=0.03)
    p.sph((0,0,4.45), 0.5, "gold", seg=10, ring=8); p.sph((1.6,1.3,3.6), (1.0,0.9,0.32), "white")
    return p.finish()

def penguin():
    p = P("Penguin")
    p.sph((0,0,2.6), (1.9,1.6,2.5), "navy"); p.sph((0,-0.5,2.4), (1.35,1.15,2.0), "white"); p.sph((0,-0.45,4.35), (1.25,1.0,0.95), "white")
    for s in (-1, 1):
        p.sph((s*0.55,-1.35,4.55), (0.3,0.15,0.38), "coal", seg=10, ring=8); p.sph((s*0.6,-1.47,4.75), 0.09, "white", seg=6, ring=4, flat=True); p.sph((s*1.0,-1.25,4.05), (0.3,0.1,0.2), "pink", seg=8, ring=6, flat=True)
        p.sph((s*2.0,0,3.0), (0.45,0.85,1.55), "navy", rot=(0, -s*0.4, 0)); p.sph((s*0.85,-1.0,0.2), (0.85,1.25,0.3), "orange")
    p.cone((0,-1.2,4.1), 0.4, 0.8, "orange", seg=8, rot=(math.pi/2,0,0))
    p.sph((0,0,5.0), (1.5,1.4,0.9), "pink"); p.sph((0,0,6.0), 0.42, "white", seg=10, ring=8); p.cyl((0,0,4.45), 1.42, 1.42, 0.3, "white", seg=18)
    p.sweep([(1.5*math.cos(2*math.pi*k/20), 1.35*math.sin(2*math.pi*k/20), 3.55) for k in range(20)], [0.28]*20, "pink", seg=8, closed=True)
    return p.finish()
BUILDERS = [snow_pine, snowman, snow_mound, ice_rock, present, penguin]
