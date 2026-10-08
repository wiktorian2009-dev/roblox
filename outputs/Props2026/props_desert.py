
from prop_lib import *

def bez(p0, p1, p2, p3, n=10):
    a, b, c, d = map(Vector, (p0, p1, p2, p3)); return [tuple((1-t)**3*a + 3*(1-t)**2*t*b + 3*(1-t)*t**2*c + t**3*d) for t in [i/(n-1) for i in range(n)]]
def cute_face(p, y, z, s=1.0, col="coal"):
    for k in (-1, 1):
        p.sph((k*0.5*s, y, z), (0.16*s, 0.1*s, 0.22*s), col, seg=8, ring=6, flat=True); p.sph((k*0.5*s-0.04*s, y-0.07*s, z+0.07*s), 0.05*s, "white", seg=5, ring=4, flat=True)
        p.sph((k*0.95*s, y+0.02, z-0.28*s), (0.22*s, 0.08*s, 0.13*s), "pink", seg=8, ring=6, flat=True)
    for a in np.linspace(0.25*math.pi, 0.75*math.pi, 5): p.sph((0.3*s*math.cos(a), y-0.02, z-0.5*s-0.16*s*math.sin(a)+0.1*s), 0.055*s, col, seg=5, ring=4, flat=True)

def saguaro():
    p = P("Saguaro"); p.sph((0,0,0.12), (2.7,2.7,0.45), "sand")
    p.sweep([(0,0,0),(0,0,3),(0,0,6.5),(0,0,9.6),(0,0,11.2)], [1.45,1.42,1.32,1.12,0.6], "cactus", seg=10)
    for s, (z0, zt) in ((-1, (4.2, 8.6)), (1, (5.6, 9.8))):
        p.sweep([(s*1.0,0,z0),(s*2.4,0,z0+0.15),(s*3.35,0,z0+1.4),(s*3.45,0,z0+3.2),(s*3.45,0,zt)], [0.95,0.92,0.88,0.82,0.5], "cactus", seg=8)
    for (x, z) in ((0,11.35),(-3.45,8.75),(3.45,9.95)): p.sph((x,0,z), (0.62,0.62,0.34), "pink", seg=8, ring=5); p.sph((x,0,z+0.14), 0.24, "yellow", seg=6, ring=4)
    cute_face(p, -1.36, 6.4, 1.0)
    for z in (2.2, 4.2, 7.8, 9.0): 
        for k in range(4): a = k*math.pi/2+0.4; p.cone((1.4*math.cos(a), 1.4*math.sin(a), z), 0.07, 0.35, "white", seg=4, rot=(0, 0, 0) if False else (math.pi/2*math.sin(a), -math.pi/2*math.cos(a), 0), smooth=False)
    return p.finish()

def barrel():
    p = P("BarrelCactus")
    p.lathe([(1.7,0),(2.3,0.05),(2.65,2.4),(3.0,2.5),(3.0,3.2),(2.55,3.2),(2.55,2.95),(0,2.95)], seg=18, colors=["terra","terra","terra","terraLight","terraLight","terraLight","brown"])
    zz = [2.95 + 2.9*(1-math.cos(a))*0.5 for a in np.linspace(0, math.pi, 12)]
    p.lathe([(2.75*math.sin(a), 2.9 + 2.75*(1-math.cos(a))) for a in np.linspace(0.05, math.pi, 12)], "cactus", seg=18, rmod=lambda th, i: 1+0.075*math.cos(9*th))
    cute_face(p, -2.55, 5.3, 1.05)
    for (x, y, z, r) in ((0,0,8.35,0.6),(-0.9,0.3,8.0,0.42),(0.95,-0.2,8.05,0.44)): p.sph((x,y,z), (r,r,r*0.5), "pink", seg=8, ring=5); p.sph((x,y,z+0.1), r*0.4, "yellow", seg=6, ring=4)
    return p.finish()

def palm():
    p = P("PalmTree"); n = 12; trunk = [(2.8*(i/n)**2, 0, 14.5*i/n) for i in range(n+1)]
    p.sph((0,0,0.1), (2.6,2.6,0.4), "sand"); p.sweep(trunk, [1.2-0.5*(i/n) for i in range(n+1)], "wood", seg=10)
    for i in range(1, n, 1): x, _, z = trunk[i]; p.sph((x,0,z), (1.2-0.5*(i/n)+0.12, 1.2-0.5*(i/n)+0.12, 0.16), "brown", seg=10, ring=4)
    tx, _, tz = trunk[-1]
    for k in range(9):
        az = 2*math.pi*k/9 + 0.2; d = (math.cos(az), math.sin(az)); pts = []; ws = []
        for j in range(9):
            t = j/8; out = 7.0*t; z = 1.2*math.sin(math.pi*t*0.75) - 4.6*t*t
            pts.append((tx+d[0]*out, d[1]*out, tz+z+0.3)); ws.append((0.15+0.95*math.sin(math.pi*min(1, 0.12+0.88*t))**0.8*(1-0.5*t), 0.07))
        p.sweep(pts, ws, "leaf" if k % 2 else "leafDark", seg=6, uhint=(-d[1], d[0], 0))
    for (x, y) in ((0.5,0.3),(-0.4,0.5),(0.1,-0.6)): p.sph((tx+x, y, tz-0.4), 0.55, "brown", seg=8, ring=6)
    return p.finish()

def rock_stack():
    p = P("RockStack")
    for (z, rx, rz, col, sd) in ((1.6, 3.4, 1.8, "sandstone", 1), (3.9, 2.6, 1.5, "sand", 2), (5.8, 1.95, 1.3, "sandstone", 3), (7.4, 1.3, 1.0, "sand", 4)):
        p.ico((0,0,z), (rx, rx*0.9, rz), col, sub=2, noise=0.18, seed=sd)
    p.sweep([(0.1,0,8.2),(0.15,0,9.1)], [0.08,0.07], "leaf", seg=5); p.sph((0.15,0,9.3), (0.35,0.35,0.2), "pink", seg=8, ring=5)
    p.ico((4.4,1.5,0.9), (1.5,1.3,0.9), "sandDark", sub=1, noise=0.2, seed=6); p.ico((-4.0,-1.2,0.7), (1.2,1.1,0.7), "sandDark", sub=1, noise=0.2, seed=7)
    return p.finish()

def arch():
    p = P("SandstoneArch"); R = 4.4
    for s in (-1, 1): p.box((s*R,0,4.2), (3.0,3.4,8.4), "sandstone", bevel=0.25, smooth=True)
    n = 9
    for k in range(n):
        a = math.pi*(k+0.5)/n; p.box((R*math.cos(a), 0, 8.4+R*math.sin(a)*0.8), (2.2 if k != 4 else 2.5, 3.3, 3.0), "sand" if k % 2 else "sandstone", rot=(0, math.pi/2-a, 0), bevel=0.2, smooth=True)
    for (x, y, r, sd) in ((-6.5,1.5,1.6,1),(6.4,-1.0,1.4,2),(5.6,2.2,0.9,3)): p.ico((x,y,r*0.6), (r, r*0.9, r*0.65), "sandDark", sub=1, noise=0.2, seed=sd)
    p.box((0,0,0.35), (13.5,4.2,0.7), "sandDark", bevel=0.2, smooth=True)
    return p.finish()

def pyramid():
    p = P("StepPyramid")
    for i in range(6): w = 14.0 - i*2.1; p.box((0,0,0.85+i*1.7), (w, w, 1.7), "sandstone" if i % 2 == 0 else "sand", bevel=0.12, smooth=True)
    p.box((0,-5.6,1.0), (2.4,1.2,2.0), "coal", bevel=0.05); p.box((0,-4.6,1.1), (3.6,3.2,1.0), "sandDark", rot=(0.35,0,0), bevel=0.05)
    p.cone((0,0,10.2), 1.3, 2.2, "gold", seg=4, rot=(0,0,math.pi/4), smooth=False)
    return p.finish()

def vase():
    p = P("ClayVase")
    prof = [(1.5,0),(2.1,0.25),(2.9,1.7),(3.15,3.3),(2.7,5.1),(1.7,6.3),(1.35,7.0),(1.35,7.6),(1.85,8.0),(1.85,8.4),(1.2,8.4)]
    p.lathe(prof, seg=20, colors=["sandDark","terra","terra","cream","teal2","cream","terra","terra","terraLight","terraLight"])
    for s in (-1, 1): p.sweep(bez((s*1.4,0,7.2),(s*3.4,0,7.6),(s*4.0,0,4.6),(s*2.6,0,4.3),10), [0.32,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.3], "terra", seg=6)
    p.sph((0,0,0.12), (2.4,2.4,0.3), "sandDark")
    return p.finish()

def tumbleweed():
    p = P("Tumbleweed"); rs = random.Random(4); R = 2.6
    for i in range(30):
        a = Vector((rs.gauss(0,1), rs.gauss(0,1), rs.gauss(0,1))).normalized(); b = a.cross(Vector((rs.gauss(0,1), rs.gauss(0,1), rs.gauss(0,1)))).normalized()
        t0 = rs.uniform(0, 6.28); span = rs.uniform(2.6, 5.0); r = R*rs.uniform(0.6, 1.0)
        pts = [tuple(r*(math.cos(t0+span*j/11)*a + math.sin(t0+span*j/11)*b) + Vector((0, 0, R))) for j in range(12)]
        p.sweep(pts, [0.12]*12, "sandDark" if i % 3 else "sand", seg=4)
    return p.finish()

def agave():
    p = P("Agave"); n = 13
    for k in range(n):
        az = 2*math.pi*k/n + (0.25 if k % 2 else 0); d = (math.cos(az), math.sin(az)); tilt = 0.55 if k % 2 == 0 else 0.3; L = 5.2 if k % 2 == 0 else 4.2; pts = []; ws = []
        for j in range(8):
            t = j/7; out = L*math.sin(tilt*math.pi/2*1.0)*t*1.6 + 0.3; z = 0.5 + L*t*(0.9 - tilt*0.35) - 1.6*t*t*(tilt+0.4)
            pts.append((d[0]*out, d[1]*out, z)); ws.append((0.15 + 0.85*math.sin(math.pi*(0.08+0.92*t**0.75))*(1-0.4*t), 0.14))
        p.sweep(pts, ws, "cactus" if k % 2 else "cactusDark", seg=6, uhint=(-d[1], d[0], 0))
    p.sph((0,0,0.5), (1.0,1.0,0.6), "cactusDark")
    return p.finish()
BUILDERS = [saguaro, barrel, palm, rock_stack, arch, pyramid, vase, tumbleweed, agave]
