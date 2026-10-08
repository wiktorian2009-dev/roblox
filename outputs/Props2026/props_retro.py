
from prop_lib import *

def pmask(pts, n):
    ys, xs = np.mgrid[0:n, 0:n]; px = xs + 0.5; py = ys + 0.5; inside = np.zeros((n, n), bool); m = len(pts)
    for k in range(m):
        x1, y1 = pts[k]; x2, y2 = pts[(k+1) % m]; dy = (y2-y1) if y2 != y1 else 1e-9
        inside ^= ((y1 > py) != (y2 > py)) & (px < (x2-x1)*(py-y1)/dy + x1)
    return inside
def circ(n, cx, cy, r): ys, xs = np.mgrid[0:n, 0:n]; return (xs+0.5-cx)**2 + (ys+0.5-cy)**2 <= r*r
def rect(n, i0, j0, i1, j1): ys, xs = np.mgrid[0:n, 0:n]; return (xs >= i0) & (xs <= i1) & (ys >= j0) & (ys <= j1)
def sprite(name, mask, colfn, depth=4, cell=0.5, outline=True):
    n = mask.shape[0]; out = np.zeros_like(mask)
    if outline:
        d = np.zeros_like(mask); d[1:, :] |= mask[:-1, :]; d[:-1, :] |= mask[1:, :]; d[:, 1:] |= mask[:, :-1]; d[:, :-1] |= mask[:, 1:]; out = d & ~mask
    cells = {}
    for j in range(n):
        for i in range(n):
            z = n-1-j
            if mask[j, i]:
                for k in range(depth): cells[(i, k, z)] = colfn(i, j, k)
            elif out[j, i]:
                for k in range(depth): cells[(i, k, z)] = "pxDark"
    p = P(name); p.vox(cells, cell=cell, origin=(-n*cell/2, -depth*cell/2, 0)); return p.finish()

def heart():
    n = 24; ys, xs = np.mgrid[0:n, 0:n]; x = (xs+0.5-12)/9.6; y = (12-(ys+0.5))/9.6 + 0.12; m = ((x*x+y*y-1)**3 - x*x*y**3) <= 0
    return sprite("PixelHeart", m, lambda i, j, k: "pxWhite" if (k == 0 and i in (6, 7) and j in (6, 7, 8)) else "pxRed")
def star():
    n = 24; pts = [(12+math.cos(math.radians(-90+36*k))*(11 if k % 2 == 0 else 4.7), 12.8+math.sin(math.radians(-90+36*k))*(11 if k % 2 == 0 else 4.7)) for k in range(10)]
    return sprite("PixelStar", pmask(pts, n), lambda i, j, k: "pxWhite" if (k == 0 and i in (11, 12) and j in (5, 6, 7)) else ("gold" if j > 14 else "pxYellow"))
def coin():
    n = 24; m = circ(n, 12, 12, 10.6)
    return sprite("PixelCoin", m, lambda i, j, k: "gold" if ((abs(i-12) <= 1 and 6 <= j <= 17) or ((i+.5-12)**2+(j+.5-12)**2 > 8.3**2)) else "pxYellow", depth=3)
def cloud():
    n = 24; m = circ(n, 7, 14, 4.6) | circ(n, 12, 10.5, 6.0) | circ(n, 17.5, 12, 6.6) | circ(n, 20.5, 15.5, 3.6) | rect(n, 7, 14, 20, 19)
    return sprite("PixelCloud", m, lambda i, j, k: "frost" if j >= 16 else "pxWhite")
def tree():
    n = 24; m = circ(n, 12, 9, 8.2) | circ(n, 6.5, 12, 5) | circ(n, 17.5, 12, 5) | rect(n, 10, 14, 13, 22)
    def col(i, j, k):
        if j >= 14 and 10 <= i <= 13 and not (circ(n, 12, 9, 8.2)[j, i]): return "brown"
        if k == 0 and (i, j) in ((8, 8), (15, 10), (11, 12), (17, 13), (6, 12)): return "pxRed"
        return "leafLight" if j < 5 else ("pxGreen" if j < 11 else "leaf")
    return sprite("PixelTree", m, col)
def alien():
    n = 24; body = circ(n, 12, 14, 8.6) & (np.mgrid[0:n, 0:n][0] <= 21)
    ant = circ(n, 6, 3, 1.8) | circ(n, 18, 3, 1.8) | rect(n, 7, 4, 7, 8) | rect(n, 17, 4, 17, 8) | rect(n, 8, 6, 8, 9) | rect(n, 16, 6, 16, 9) | rect(n, 7, 21, 10, 22) | rect(n, 14, 21, 17, 22)
    m = body | ant
    def col(i, j, k):
        if k == 0:
            if circ(n, 12, 12, 3.4)[j, i]: return "pxDark" if circ(n, 12.6, 12.6, 1.6)[j, i] else "pxWhite"
            if j == 17 and 10 <= i <= 13: return "pxDark"
            if j in (15, 16) and i in (7, 8, 16, 17): return "pxPink"
        if circ(n, 6, 3, 1.8)[j, i] or circ(n, 18, 3, 1.8)[j, i]: return "pxYellow"
        return "leaf" if j > 20 else "pxGreen"
    return sprite("PixelAlien", m, col)
def gem():
    n = 24; m = pmask([(12, 1.5), (22, 10), (12, 22.5), (2, 10)], n)
    return sprite("PixelGem", m, lambda i, j, k: ("magenta" if i < 12 else "pxPink") if j < 10 else ("pxPink" if i < 12 else "violet"))
def sun():
    n = 24; m = circ(n, 12, 12, 11) & ~(rect(n, 0, 15, 23, 15) | rect(n, 0, 18, 23, 18) | rect(n, 0, 21, 23, 22))
    return sprite("PixelSun", m, lambda i, j, k: "yellow" if j < 7 else ("orange" if j < 12 else ("pxPink" if j < 17 else "pxRed")), depth=3)
def arcade():
    p = P("ArcadeCabinet")
    p.box((0,0,4.0), (6.2,5.0,8.0), "pxPurple", bevel=0.12, smooth=True); p.box((0,0.3,9.7), (6.2,4.3,3.6), "pxPurple", bevel=0.12, smooth=True)
    p.box((0,-1.9,9.6), (4.8,0.4,3.0), "pxDark"); p.box((0,-2.15,9.6), (4.2,0.1,2.4), "pxBlue", flat=True); p.box((0,-1.3,12.0), (5.6,0.6,1.1), "pxPink", bevel=0.05)
    p.box((0,-2.7,6.4), (5.6,2.4,0.5), "pxGray", rot=(0.3,0,0), bevel=0.05)
    p.cyl((-1.4,-2.9,6.6), 0.13, 0.13, 0.9, "pxGray", seg=8); p.sph((-1.4,-2.95,7.65), 0.38, "pxRed", seg=10, ring=8)
    for (x, c) in ((0.4,"pxYellow"),(1.3,"pxGreen"),(2.2,"pxBlue")): p.sph((x,-2.95,6.72), (0.34,0.34,0.2), c, seg=8, ring=6, flat=True)
    for s in (-1, 1): p.box((s*3.12,0,5.0), (0.12,4.6,9.0), "pxYellow"); p.box((s*3.12,0.3,9.8), (0.12,3.9,2.8), "pxPink")
    p.box((0,-2.55,2.4), (4.6,0.12,2.4), "pxDark")
    return p.finish()
BUILDERS = [heart, star, coin, cloud, tree, alien, gem, sun, arcade]
