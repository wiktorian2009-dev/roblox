
from prop_lib import *
from props_desert import bez
from props_crystal import crystal

def aim(d): return tuple(Vector((0, 0, 1)).rotation_difference(Vector(d).normalized()).to_euler("XYZ"))

def ice_spikes():
    p = P("IceSpikes"); p.sph((0,0,0.7), (5.2,4.8,1.2), "frostWhite")
    for i, (x, y, h, r, t) in enumerate(((0,0,12,1.5,(0,0)),(2.7,0.8,8.5,1.2,(0,0.3)),(-2.6,0.6,9.0,1.25,(0.05,-0.3)),(0.8,-2.7,6.5,1.0,(0.3,0.05)),(-1.0,2.5,7.0,1.1,(-0.3,0)),(3.7,-1.6,4.5,0.85,(0.2,0.45)),(-3.9,-1.3,5,0.9,(0.25,-0.5)))):
        crystal(p, (x,y,0.7), h, r, ["iceBlue","frost","iceDeep","glow"][i % 4], t, tip=0.42)
    return p.finish()
def frozen_pine():
    p = P("FrozenPine"); p.cyl((0,0,0), 0.75, 0.6, 2.6, "deadWood", seg=10)
    for i, (r, h, z0) in enumerate(((4.6,4.6,1.8),(3.7,4.2,4.6),(2.9,3.8,7.3),(2.1,3.3,9.7))):
        p.cone((0,0,z0), r, h, "iceDeep" if i % 2 == 0 else "iceBlue", seg=10, smooth=False); fh = h*0.55; rc = r*fh/h*1.08
        p.cone((0,0,z0+h-fh), rc, fh*1.04, "frostWhite", seg=10, smooth=False)
        for k in range(10):
            a = 2*math.pi*k/10 + 0.2*i; p.cone((r*0.97*math.cos(a), r*0.97*math.sin(a), z0+0.25), 0.2, 0.9+0.5*((k+i) % 3)/2, "glow", seg=5, rot=(math.pi, 0, 0), smooth=False)
    p.cone((0,0,13.0), 0.55, 1.6, "glow", seg=5, smooth=False); p.sph((0,0,0.1), (3.0,3.0,0.6), "frostWhite")
    return p.finish()
def ice_boulder():
    p = P("IceBoulder"); p.ico((0,0,2.6), (4.4,3.9,3.1), "iceBlue", sub=1, noise=0.28, seed=31); p.ico((3.9,1.1,1.3), (2.0,1.8,1.5), "iceDeep", sub=1, noise=0.3, seed=32); p.ico((-3.3,-1.6,1.1), (1.6,1.5,1.2), "iceBlue", sub=1, noise=0.3, seed=33)
    p.ico((0,0,4.6), (3.2,2.8,1.1), "frostWhite", sub=1, noise=0.25, seed=31); p.ico((3.9,1.1,2.4), (1.6,1.4,0.6), "frostWhite", sub=1, noise=0.25, seed=32)
    return p.finish()
def obelisk():
    p = P("RuneObelisk"); q = math.pi/4
    p.cyl((0,0,0), 5.2, 4.3, 1.0, "stoneDark", seg=4, rot=(0,0,q), smooth=False); p.cyl((0,0,1.0), 3.5, 2.7, 1.0, "stone", seg=4, rot=(0,0,q), smooth=False)
    p.cyl((0,0,2.0), 2.4, 1.6, 11.0, "stoneDark", seg=4, rot=(0,0,q), smooth=False); p.cone((0,0,13.0), 1.6, 2.3, "stone", seg=4, rot=(0,0,q), smooth=False)
    ff = lambda z: -(2.4-0.8*(z-2)/11.0)*0.7071
    for z in (4.3, 7.0, 9.7):
        y = ff(z)-0.03; p.box((0,y,z), (0.34,0.14,1.5), "glow", flat=True); p.box((0,y,z+0.35), (1.1,0.14,0.3), "glow", flat=True); p.box((-0.55,y,z-0.35), (0.3,0.14,0.8), "glow", flat=True); p.box((0.55,y,z-0.35), (0.3,0.14,0.8), "glow", flat=True)
    p.cone((0,0,17.0), 1.1, 2.2, "glow", seg=4, smooth=False); p.cone((0,0,17.0), 1.1, 1.8, "iceBlue", seg=4, smooth=False, rot=(math.pi,0,0))
    p.sweep([(2.3*math.cos(a), 2.3*math.sin(a), 17.0) for a in np.linspace(0, 2*math.pi, 20, endpoint=False)], [0.12]*20, "glow", seg=5, closed=True)
    return p.finish()
def ice_arch():
    p = P("IceArch"); n = 16; pts = [(6.0*math.cos(math.pi*k/(n-1)), 0, 0.5+7.0*math.sin(math.pi*k/(n-1))) for k in range(n)]
    p.sweep(pts, [(1.7+0.25*math.sin(k*1.3), 1.5) for k in range(n)], "iceBlue", seg=8); p.sweep([(x, y, z+1.15) for (x, y, z) in pts[2:-2]], [(1.35, 0.85)]*(n-4), "frostWhite", seg=8)
    for k in (4, 6, 8, 10, 11): x, y, z = pts[k]; p.cone((x*0.93, 0.0, z-1.0), 0.28, 1.6+0.4*(k % 3), "glow", seg=5, rot=(math.pi,0,0), smooth=False)
    for s in (-1, 1): p.ico((s*6.0,0,0.7), (2.6,2.3,1.2), "frostWhite", sub=1, noise=0.2, seed=int(s+40)); p.ico((s*7.6,1.4,0.5), (1.3,1.1,0.7), "iceBlue", sub=1, noise=0.2, seed=int(s+44))
    return p.finish()
def frost_bush():
    p = P("FrostBush"); p.sph((0,0,1.5), (2.3,2.3,1.5), "ice"); rs = random.Random(7)
    for k in range(26):
        d = Vector((rs.gauss(0,1), rs.gauss(0,1), abs(rs.gauss(0,1))*0.9+0.25)).normalized(); b = Vector((0,0,1.4)) + d*1.5
        p.cone(tuple(b), 0.34, 2.6+rs.uniform(0, 1.5), "frost" if k % 2 else "glow", seg=5, rot=aim(d), smooth=False)
    return p.finish()
def shards():
    p = P("FloatingShards")
    for i, (x, y, z, s, col) in enumerate(((0,0,6.5,1.6,"glow"),(3.8,-1.0,9.5,1.0,"iceDeep"),(-3.6,1.2,4.2,1.15,"iceBlue"),(1.6,3.4,11.5,0.75,"frost"),(-1.4,-3.0,8.6,0.9,"glow"),(4.4,2.2,5.2,0.7,"iceBlue"))):
        p.cone((x,y,z), s, s*3.0, col, seg=5, smooth=False, rot=(0, 0.15*(i-2), 0)); p.cone((x,y,z), s, s*2.0, col, seg=5, smooth=False, rot=(math.pi, 0, 0))
    p.ico((0,0,0.9), (3.4,3.0,1.2), "frostWhite", sub=1, noise=0.25, seed=51)
    return p.finish()
def ice_cube():
    p = P("IceCube"); p.box((0,0,2.8), (5.6,5.6,5.6), "iceBlue", bevel=0.35, smooth=True); p.box((0,0,2.8), (4.4,4.4,4.4), "frost", bevel=0.3, smooth=True)
    for s in (-1, 1): p.sph((s*1.1,-2.85,3.3), (0.42,0.14,0.56), "coal", seg=10, ring=8, flat=True); p.sph((s*1.05,-2.97,3.55), 0.13, "white", seg=6, ring=4, flat=True); p.sph((s*1.85,-2.8,2.4), (0.45,0.12,0.28), "pink", seg=8, ring=6, flat=True)
    for a in np.linspace(0.2*math.pi, 0.8*math.pi, 6): p.sph((0.8*math.cos(a), -2.88, 2.2-0.55*math.sin(a)+0.25), 0.13, "coal", seg=5, ring=4, flat=True)
    for (x, y, z, s) in ((2.4,2.0,6.4,0.6),(-2.6,-1.0,6.8,0.5)): p.cone((x,y,z), s, s*1.3, "glow", seg=4, smooth=False); p.cone((x,y,z), s, s*1.1, "glow", seg=4, smooth=False, rot=(math.pi,0,0))
    return p.finish()
BUILDERS = [ice_spikes, frozen_pine, ice_boulder, obelisk, ice_arch, frost_bush, shards, ice_cube]
