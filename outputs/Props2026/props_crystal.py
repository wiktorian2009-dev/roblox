
from prop_lib import *
from props_desert import bez

def crystal(p, base, h, r, color, tilt=(0, 0), tip=0.3):
    rot = (tilt[0], tilt[1], 0.0); R = Euler(rot, "XYZ").to_matrix(); hh = h*(1-tip)
    p.cyl(base, r, r, hh, color, seg=6, smooth=False, rot=rot); top = Vector(base) + R @ Vector((0, 0, hh)); p.cone(tuple(top), r, h*tip, color, seg=6, smooth=False, rot=rot)

def cluster(name, fam, seed):
    p = P(name); p.ico((0,0,0.9), (4.6,4.2,1.5), "rockBlue", sub=1, noise=0.22, seed=seed)
    for i, (x, y, h, r, t) in enumerate(((0,0,11,1.25,(0,0)),(2.0,0.4,7.5,1.0,(0,0.35)),(-2.1,0.3,8.2,1.05,(0,-0.3)),(0.6,-2.2,6.0,0.9,(0.3,0.05)),(-0.8,2.0,6.8,0.95,(-0.3,-0.05)),(2.9,-1.4,4.2,0.75,(0.25,0.45)),(-3.1,-1.2,4.8,0.8,(0.2,-0.5)))):
        crystal(p, (x,y,0.9), h, r, fam[i % len(fam)], t)
    return p.finish()
def cluster_cyan(): return cluster("CrystalClusterCyan", ["cyan","cyanDark","iceBlue","mint"], 1)
def cluster_purple(): return cluster("CrystalClusterPurple", ["amethyst","violet","purple","magenta"], 2)
def cluster_pink(): return cluster("CrystalClusterPink", ["magenta","pink","violet","amethyst"], 3)

def spire():
    p = P("CrystalSpire"); p.ico((0,0,0.8), (4.2,4.0,1.4), "rockBlue", sub=1, noise=0.2, seed=4)
    crystal(p, (0,0,0.8), 17, 1.7, "cyan", (0,0), 0.26); crystal(p, (2.6,0.8,0.8), 8, 1.0, "amethyst", (0,0.4)); crystal(p, (-2.5,-0.6,0.8), 9, 1.1, "cyanDark", (0.1,-0.35)); crystal(p, (0.4,-2.6,0.8), 5.5, 0.85, "mint", (0.35,0))
    return p.finish()

def mushrooms():
    p = P("GlowMushrooms")
    def shroom(x, y, s, cap, spot):
        p.lathe([(0.8*s,0),(1.0*s,1.3*s),(0.85*s,2.7*s),(0.9*s,3.3*s)], "cream", seg=14, c=(x,y,0))
        p.lathe([(2.7*s,0),(3.0*s,0.3*s),(2.85*s,1.0*s),(2.2*s,1.75*s),(1.2*s,2.25*s),(0.001,2.4*s)], cap, seg=18, c=(x,y,3.1*s))
        for (dx, dy, dz, r) in ((1.3,0.8,1.9,0.42),(-1.1,1.2,1.8,0.36),(0.3,-1.6,1.85,0.4),(-0.4,0.2,2.3,0.3),(1.7,-0.7,1.4,0.3)): p.sph((x+dx*s, y+dy*s, 3.1*s+dz*s), (r*s,r*s,r*s*0.6), spot, seg=8, ring=5)
    shroom(0, 0, 1.0, "deepBlue", "cyan"); shroom(4.2, 1.6, 0.6, "amethyst", "mint"); shroom(-3.8, 1.2, 0.72, "magenta", "glow")
    return p.finish()

def stalagmites():
    p = P("Stalagmites"); p.ico((0,0,0.5), (5.0,4.6,0.9), "stoneDark", sub=1, noise=0.15, seed=9)
    for (x, y, h, r, col) in ((0,0,11,2.0,"rockBlue"),(3.3,1.0,7,1.5,"stone"),(-3.2,0.6,8,1.6,"rockBlue"),(1.0,-2.8,4.5,1.15,"stone"),(-1.6,2.6,5.5,1.25,"stoneDark")):
        p.cyl((x,y,0.4), r, r*0.72, h*0.5, col, seg=9, smooth=False); p.cyl((x,y,0.4+h*0.5), r*0.72, r*0.38, h*0.3, col, seg=9, smooth=False); p.cone((x,y,0.4+h*0.8), r*0.38, h*0.22, "amethyst" if col == "rockBlue" else "iceBlue", seg=9, smooth=False)
    return p.finish()

def gem_boulder():
    p = P("GemBoulder"); p.ico((0,0,2.3), (4.0,3.5,2.8), "stone", sub=2, noise=0.2, seed=11); p.ico((3.9,1.0,1.1), (1.8,1.6,1.3), "stoneDark", sub=1, noise=0.2, seed=12)
    for (x, y, z, h, r, col, t) in ((-1.3,-0.4,4.3,4.5,0.7,"cyan",(0.2,-0.3)),(1.2,-1.0,3.6,3.6,0.6,"magenta",(0.5,0.2)),(0.2,1.4,4.0,3.8,0.65,"mint",(-0.3,0.15)),(-2.6,1.1,3.0,2.7,0.5,"amethyst",(0.1,-0.7)),(3.0,0.2,3.1,2.4,0.5,"cyan",(0.2,0.6))): crystal(p, (x,y,z), h, r, col, t)
    for (x, y, z, r) in ((2.1,-2.3,1.5,0.6),(-2.7,-1.8,1.6,0.5),(3.9,-0.4,2.0,0.42)): p.ico((x,y,z), r, "gold", sub=1, noise=0.25, seed=int(x*7))
    return p.finish()

def crystal_arch():
    p = P("CrystalArch"); p.ico((-5,0,0.9), (3.4,3.0,1.4), "rockBlue", sub=1, noise=0.2, seed=13); p.ico((5,0,0.9), (3.4,3.0,1.4), "rockBlue", sub=1, noise=0.2, seed=14)
    crystal(p, (-5.2,0,0.9), 13, 1.7, "cyan", (0,0.42), 0.18); crystal(p, (5.2,0,0.9), 13, 1.7, "amethyst", (0,-0.42), 0.18)
    crystal(p, (-6.6,0.8,0.9), 6, 0.9, "mint", (0.1,0.25)); crystal(p, (6.6,-0.8,0.9), 6.5, 0.95, "magenta", (-0.1,-0.25))
    return p.finish()

def floating():
    p = P("FloatingCrystal"); p.cone((0,0,7.2), 2.3, 5.4, "cyan", seg=6, smooth=False); p.cone((0,0,7.2), 2.3, 4.2, "cyanDark", seg=6, smooth=False, rot=(math.pi,0,0))
    p.sweep([(4.2*math.cos(a), 4.2*math.sin(a)*0.35+0.0, 7.0+4.2*math.sin(a)*0.55) for a in np.linspace(0, 2*math.pi, 28, endpoint=False)], [0.2]*28, "amethyst", seg=6, closed=True)
    for (x, y, z, s, col) in ((3.6,-1.0,8.6,0.7,"mint"),(-3.4,1.2,5.4,0.55,"magenta"),(0.6,3.4,9.5,0.5,"iceBlue")):
        p.cone((x,y,z), s, s*1.4, col, seg=4, smooth=False); p.cone((x,y,z), s, s*1.1, col, seg=4, smooth=False, rot=(math.pi,0,0))
    p.ico((0,0,0.9), (3.0,2.8,1.0), "stoneDark", sub=1, noise=0.2, seed=15)
    return p.finish()
BUILDERS = [cluster_cyan, cluster_purple, cluster_pink, spire, mushrooms, stalagmites, gem_boulder, crystal_arch, floating]
