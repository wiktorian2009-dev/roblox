
exec(open(os.path.join(OUT, "egg_lib.py"), encoding="utf-8").read()) if "Paint" not in globals() else None

def wavy_cap(name, z_edge, off, swatch, segs=64, rows=14):
    bm = bmesh.new(); grid = []
    for j in range(rows):
        t = j / (rows - 1); ring = []
        for i in range(segs):
            a = 2*math.pi*i/segs
            ze = z_edge(a); z = ze + (H - ze) * (1 - (1 - t)**1.6) if j < rows - 1 else H
            r = shell_r(min(z, H - 1e-4)) + off
            if j == rows - 1: r = 0.0
            ring.append(bm.verts.new((r*math.cos(a), r*math.sin(a), z + (off if j == rows-1 else 0))))
        grid.append(ring)
    for j in range(rows - 1):
        for i in range(segs):
            a, b = grid[j][i], grid[j][(i+1) % segs]; c, d = grid[j+1][(i+1) % segs], grid[j+1][i]
            if j == rows - 2: bm.faces.new((a, b, c)) if c != d else None
            else: bm.faces.new((a, b, c, d))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    return from_bm(name, bm, swatch)

def egg_snowy(x):
    P = Paint([(0, "6FB9F0"), (0.55, "A9DBFF"), (1, "E6F6FF")])
    P.scatter(26, 0.07, 0.13, "FFFFFF", vmin=0.12, vmax=0.68, seed=3, minsep=0.08)
    P.swatches(["FAFDFF", "FF9FCB"])
    img = P.save("SnowyEgg_Tex")
    parts = [shell("SnowyEgg_Shell")]
    ze = lambda a: 0.70*H + 0.09*math.sin(5*a)
    cap = wavy_cap("SnowyEgg_Cap", ze, 0.05, 0); solidify(cap, 0.07); parts.append(cap)
    for k in range(5):
        a = (1.5*math.pi + 2*math.pi*k) / 5; z = 0.70*H - 0.09 - 0.06
        r = shell_r(z) + 0.05
        parts.append(blob("SnowyEgg_Drip", (r*math.cos(a), r*math.sin(a), z), (0.085, 0.085, 0.15), 0))
    parts.append(blob("SnowyEgg_Pom", (0, 0, H + 0.2), (0.24, 0.24, 0.22), 1, seg=20, ring=12))
    return finish("SnowyEgg", parts, img, x)


def crystal(name, base, direction, L, r, swatch):
    bm = bmesh.new(); ring0, ring1 = [], []
    for k in range(6):
        a = math.pi/3*k
        ring0.append(bm.verts.new((r*math.cos(a), r*math.sin(a), 0)))
        ring1.append(bm.verts.new((r*1.06*math.cos(a), r*1.06*math.sin(a), L*0.7)))
    tip = bm.verts.new((0, 0, L))
    for k in range(6):
        n = (k+1) % 6
        bm.faces.new((ring0[k], ring0[n], ring1[n], ring1[k])); bm.faces.new((ring1[k], ring1[n], tip))
    bm.faces.new(list(reversed(ring0)))
    rot = Vector((0, 0, 1)).rotation_difference(Vector(direction).normalized()).to_matrix()
    for v in bm.verts: v.co = rot @ v.co + Vector(base)
    ob = from_bm(name, bm, swatch)
    for p in ob.data.polygons: p.use_smooth = False
    return ob

def egg_snowy(x):
    P = Paint([(0, "4FA6EC"), (0.5, "8CCBFA"), (1, "DDF2FF")])
    P.scatter(26, 0.07, 0.13, "FFFFFF", vmin=0.12, vmax=0.66, seed=3, minsep=0.08)
    P.swatches(["FAFDFF", "FF9FCB"])
    img = P.save("SnowyEgg_Tex")
    parts = [shell("SnowyEgg_Shell")]
    ze = lambda a: 0.70*H + 0.09*math.sin(5*a)
    cap = wavy_cap("SnowyEgg_Cap", ze, 0.05, 0); solidify(cap, 0.07); parts.append(cap)
    for k in range(5):
        a = (1.5*math.pi + 2*math.pi*k) / 5; z = 0.70*H - 0.09 - 0.05
        r = shell_r(z) + 0.055
        parts.append(blob("SnowyEgg_Drip", (r*math.cos(a), r*math.sin(a), z), (0.09, 0.09, 0.17), 0))
    parts.append(blob("SnowyEgg_Pom", (0, 0, H + 0.2), (0.24, 0.24, 0.22), 1, seg=20, ring=12))
    return finish("SnowyEgg", parts, img, x)

def egg_desert(x):
    P = Paint([(0, "EE9A4E"), (0.5, "FFC98A"), (1, "FFEACB")])
    P.zigzag(0.46, 0.05, 10, 0.036, "FFFFFF"); P.zigzag(0.46, 0.05, 10, 0.022, "35C2B8")
    P.scatter(14, 0.035, 0.055, "E5774A", vmin=0.6, vmax=0.9, seed=5, minsep=0.1)
    P.scatter(12, 0.035, 0.055, "E5774A", vmin=0.12, vmax=0.34, seed=6, minsep=0.1)
    P.swatches(["4CB860", "FF7EB6", "FFD84D"])
    img = P.save("DesertEgg_Tex")
    parts = [shell("DesertEgg_Shell")]
    parts.append(tube("DesertEgg_Cactus", [(0,0,H-0.25),(0,0,H),(0,0,H+0.3),(0,0,H+0.5),(0,0,H+0.62),(0,0,H+0.7),(0,0,H+0.74)],
                      [0.2,0.21,0.21,0.2,0.17,0.11,0.02], 0))
    parts.append(tube("DesertEgg_ArmL", [(-0.12,0,H+0.26),(-0.3,0,H+0.28),(-0.4,0,H+0.35),(-0.42,0,H+0.5),(-0.41,0,H+0.58),(-0.41,0,H+0.62)],
                      [0.1,0.1,0.1,0.095,0.07,0.02], 0))
    parts.append(tube("DesertEgg_ArmR", [(0.12,0,H+0.4),(0.28,0,H+0.42),(0.35,0,H+0.48),(0.36,0,H+0.58),(0.36,0,H+0.64)],
                      [0.09,0.09,0.085,0.065,0.02], 0))
    for k in range(5):
        a = 2*math.pi*k/5
        parts.append(blob("DesertEgg_Petal", (0.09*math.cos(a), 0.09*math.sin(a), H+0.75), (0.08, 0.08, 0.05), 1, seg=12, ring=8))
    parts.append(blob("DesertEgg_FlowerMid", (0, 0, H+0.78), (0.055, 0.055, 0.045), 2, seg=12, ring=8))
    return finish("DesertEgg", parts, img, x)

def egg_cursed(x):
    P = Paint([(0, "45287D"), (0.5, "7B4FC4"), (1, "B894F2")])
    P.scatter(18, 0.07, 0.12, "FFD1FF", vmin=0.1, vmax=0.9, shape="sparkle", seed=7, minsep=0.1)
    P.scatter(22, 0.022, 0.038, "E3B5FF", vmin=0.08, vmax=0.95, seed=8, minsep=0.05)
    P.swatches(["FFE6C7", "FF8FD0"])
    img = P.save("CursedEgg_Tex")
    parts = [shell("CursedEgg_Shell")]
    zb = 0.80*H; xb = shell_r(zb)*0.8
    loc = [(0,0),(0.16,0.1),(0.3,0.26),(0.36,0.46),(0.31,0.62),(0.2,0.7)]
    rad = [0.17,0.155,0.13,0.1,0.065,0.02]
    for s in (-1, 1):
        pts = [(s*(xb + px), 0, zb + pz) for px, pz in loc]
        parts.append(tube("CursedEgg_Horn", pts[:4], rad[:4], 0))
        parts.append(tube("CursedEgg_HornTip", pts[2:], [rad[2]*1.04, rad[3]*1.05, rad[4]*1.05, rad[5]], 1))
    return finish("CursedEgg", parts, img, x)

def egg_crystal(x):
    P = Paint([(0, "A48BFF"), (0.45, "8FD8FF"), (1, "EAF9FF")])
    P.scatter(22, 0.06, 0.12, "FFFFFF", vmin=0.1, vmax=0.85, shape="sparkle", seed=9, minsep=0.1)
    P.swatches(["6FDDFF", "C6A8FF", "F0FFFF"])
    img = P.save("CrystalEgg_Tex")
    parts = [shell("CrystalEgg_Shell")]
    parts.append(crystal("CrystalEgg_Main", (0, 0, H-0.3), (0, 0, 1), 1.1, 0.21, 0))
    for k in range(4):
        a = math.radians(45 + 90*k)
        d = (math.sin(math.radians(32))*math.cos(a), math.sin(math.radians(32))*math.sin(a), math.cos(math.radians(32)))
        parts.append(crystal("CrystalEgg_Side", (0.2*math.cos(a), 0.2*math.sin(a), H-0.32), d, 0.72 if k % 2 == 0 else 0.6, 0.15, 1 if k % 2 == 0 else 2))
    for a in (0, math.pi):
        d = (0.75*math.cos(a), 0.75*math.sin(a), 0.66)
        parts.append(crystal("CrystalEgg_Small", (0.28*math.cos(a), 0.28*math.sin(a), H-0.4), d, 0.42, 0.1, 0))
    return finish("CrystalEgg", parts, img, x)

STAR = ["....#....", "...###...", "...###...", "#########", ".##e#e##.", "..#####..", "..##.##..", ".##...##.", ".#.....#."]
def pixel_cubes(name, cells, c, depth, swatch):
    bm = bmesh.new()
    for (cx, cz) in cells:
        vs = [bm.verts.new((cx + dx*c/2, dy*depth/2, cz + dz*c/2)) for dx in (-1,1) for dy in (-1,1) for dz in (-1,1)]
        for f in ((0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)):
            bm.faces.new([vs[i] for i in f])
    ob = from_bm(name, bm, swatch)
    for p in ob.data.polygons: p.use_smooth = False
    return ob

def egg_retro(x):
    P = Paint([(0, "5FD9FF"), (0.5, "B99CFF"), (1, "FF9ED6")])
    P.band(0.383, 0.402, "FFE14D"); P.band(0.518, 0.537, "FFE14D")
    P.checker(0.402, 0.518, 24, 2, "2B1E57", "FFFFFF")
    P.scatter(14, 0.04, 0.06, "FFFFFF", vmin=0.62, vmax=0.92, seed=11, minsep=0.1)
    P.scatter(10, 0.04, 0.06, "FFFFFF", vmin=0.1, vmax=0.32, seed=12, minsep=0.1)
    P.swatches(["FFD93D", "FF6FB5", "2B1E57"])
    img = P.save("RetroEgg_Tex")
    parts = [shell("RetroEgg_Shell")]
    c = 0.1; zc = H + 0.58; yel, eye = [], []
    for j, row in enumerate(STAR):
        for i, ch in enumerate(row):
            if ch == ".": continue
            (eye if ch == "e" else yel).append(((i-4)*c, zc + (4-j)*c))
    parts.append(pixel_cubes("RetroEgg_Star", yel, c, 0.16, 0))
    parts.append(pixel_cubes("RetroEgg_Eyes", eye, c, 0.17, 2))
    parts.append(tube("RetroEgg_Stick", [(0,0,H-0.1),(0,0,H+0.2),(0,0,H+0.45)], [0.06,0.06,0.06], 1, segs=10))
    return finish("RetroEgg", parts, img, x)

def leaf(name, a, z0, L, wmax, swatch, N=16, M=7):
    bm = bmesh.new(); grid = []
    out = Vector((math.cos(a), math.sin(a), 0)); tan = Vector((-math.sin(a), math.cos(a), 0))
    for i in range(N):
        t = i/(N-1); z = z0 + t*L; r = shell_r(min(z, H-0.01)) + 0.035 + 0.45*t**2.2
        w = wmax * math.sin(math.pi*min(t, 0.999))**0.75 * (1 - 0.25*t)
        row = []
        for j in range(M):
            s = -1 + 2*j/(M-1)
            p = out*(r + 0.07*s*s*math.sin(math.pi*t)) + tan*(s*w) + Vector((0, 0, z))
            row.append(bm.verts.new(p))
        grid.append(row)
    for i in range(N-1):
        for j in range(M-1):
            bm.faces.new((grid[i][j], grid[i][j+1], grid[i+1][j+1], grid[i+1][j]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    ob = from_bm(name, bm, swatch); solidify(ob, 0.035); return ob

def egg_jungle(x):
    P = Paint([(0, "3FAE55"), (0.5, "7ED957"), (1, "D4F77E")])
    P.scatter(14, 0.12, 0.17, "34A04C", vmin=0.35, vmax=0.9, seed=13, aspect=0.5, minsep=0.08)
    P.scatter(16, 0.03, 0.05, "F4F77A", vmin=0.5, vmax=0.93, seed=14, minsep=0.08)
    P.swatches(["2DA84E", "5CCB5F", "FF6B4A", "FFD84D"])
    img = P.save("JungleEgg_Tex")
    parts = [shell("JungleEgg_Shell")]
    for k in range(6):
        a = math.radians(15 + 60*k)
        parts.append(leaf("JungleEgg_Leaf", a, 0.08, 1.3 if k % 2 == 0 else 1.05, 0.42 if k % 2 == 0 else 0.34, k % 2))
    a = math.radians(45); z = 0.62
    n = Vector((math.cos(a), math.sin(a), 0)); t1 = Vector((-math.sin(a), math.cos(a), 0)); t2 = Vector((0, 0, 1))
    P0 = n*(shell_r(z) + 0.02) + Vector((0, 0, z))
    for k in range(5):
        b = 2*math.pi*k/5
        parts.append(blob("JungleEgg_Petal", P0 + n*0.03 + (t1*math.cos(b) + t2*math.sin(b))*0.1, (0.075, 0.075, 0.075), 2, seg=12, ring=8))
    parts.append(blob("JungleEgg_FlowerMid", P0 + n*0.08, (0.06, 0.06, 0.06), 3, seg=12, ring=8))
    return finish("JungleEgg", parts, img, x)

def torus(name, center, major, minor, tilt, swatch, s1=48, s2=12):
    bm = bmesh.new(); rings = []
    M = Matrix.Rotation(tilt, 3, "X")
    for i in range(s1):
        a = 2*math.pi*i/s1; ring = []
        for j in range(s2):
            b = 2*math.pi*j/s2
            p = Vector(((major + minor*math.cos(b))*math.cos(a), (major + minor*math.cos(b))*math.sin(a), minor*math.sin(b)))
            ring.append(bm.verts.new(M @ p + Vector(center)))
        rings.append(ring)
    for i in range(s1):
        for j in range(s2):
            n1, n2 = (i+1) % s1, (j+1) % s2
            bm.faces.new((rings[i][j], rings[n1][j], rings[n1][n2], rings[i][n2]))
    return from_bm(name, bm, swatch), M

def egg_absolutezero(x):
    P = Paint([(0, "1F4FC9"), (0.45, "4A8DF0"), (0.8, "BFE6FF"), (1, "FFFFFF")])
    P.scatter(20, 0.06, 0.11, "FFFFFF", vmin=0.08, vmax=0.8, shape="sparkle", seed=15, minsep=0.1)
    P.scatter(22, 0.02, 0.04, "D8F2FF", vmin=0.08, vmax=0.8, seed=16, minsep=0.05)
    P.swatches(["C9F4FF", "EAFBFF", "8FE3FF"])
    img = P.save("AbsoluteZeroEgg_Tex")
    parts = [shell("AbsoluteZeroEgg_Shell")]
    center = Vector((0, 0, 0.52*H)); tilt = math.radians(12)
    ring, M = torus("AbsoluteZeroEgg_Ring", center, 1.42, 0.1, tilt, 0); parts.append(ring)
    for k in range(12):
        a = 2*math.pi*k/12 + 0.13
        top = M @ Vector((1.42*math.cos(a), 1.42*math.sin(a), 0)) + center
        L = 0.3 if k % 2 == 0 else 0.19
        parts.append(tube("AbsoluteZeroEgg_Icicle", [top + Vector((0,0,0.02)), top - Vector((0,0,L*0.35)), top - Vector((0,0,L*0.75)), top - Vector((0,0,L))],
                          [0.065, 0.05, 0.025, 0.004], 1, segs=10))
    for k in range(4):
        a = 2*math.pi*k/4 + math.pi/4
        base = M @ Vector((1.42*math.cos(a), 1.42*math.sin(a), 0.05)) + center
        parts.append(crystal("AbsoluteZeroEgg_Shard", base, (0.15*math.cos(a), 0.15*math.sin(a), 1), 0.32, 0.08, 2))
    return finish("AbsoluteZeroEgg", parts, img, x)

BUILDERS = [egg_snowy, egg_desert, egg_cursed, egg_crystal, egg_retro, egg_jungle, egg_absolutezero]
def build_all(spacing=3.6):
    for ob in list(bpy.data.objects):
        if ob.type == "MESH": bpy.data.objects.remove(ob, do_unlink=True)
    res = []
    for i, f in enumerate(BUILDERS): res.append(f(i*spacing))
    return res


# ---- v2 tweaks (override earlier definitions) ----
def egg_cursed(x):
    P = Paint([(0, "45287D"), (0.5, "7B4FC4"), (1, "B894F2")])
    P.scatter(18, 0.08, 0.13, "FFD1FF", vmin=0.1, vmax=0.88, shape="sparkle", seed=7, minsep=0.1)
    P.scatter(22, 0.022, 0.038, "E3B5FF", vmin=0.08, vmax=0.95, seed=8, minsep=0.05)
    P.swatches(["FFE6C7", "FF8FD0"])
    img = P.save("CursedEgg_Tex")
    parts = [shell("CursedEgg_Shell")]
    zb = 0.84*H; xb = shell_r(zb)*0.55; S = 1.55
    loc = [(0,0),(0.16,0.1),(0.3,0.26),(0.36,0.46),(0.31,0.62),(0.2,0.7)]
    rad = [0.17,0.155,0.13,0.1,0.065,0.02]
    for s in (-1, 1):
        pts = [(s*(xb + px*S), 0, zb - 0.08 + pz*S) for px, pz in loc]
        r = [q*S for q in rad]
        parts.append(tube("CursedEgg_Horn", pts[:4], r[:4], 0))
        parts.append(tube("CursedEgg_HornTip", pts[2:], [r[2]*1.04, r[3]*1.05, r[4]*1.05, r[5]], 1))
    return finish("CursedEgg", parts, img, x)

def egg_crystal(x):
    P = Paint([(0, "9C7CFF"), (0.45, "7FCBFF"), (1, "DDF4FF")])
    P.scatter(20, 0.09, 0.15, "FFFFFF", vmin=0.1, vmax=0.8, shape="sparkle", seed=9, minsep=0.1)
    P.scatter(16, 0.025, 0.04, "FFFFFF", vmin=0.08, vmax=0.9, seed=10, minsep=0.06)
    P.swatches(["5FD6FF", "B996FF", "EFFFFF"])
    img = P.save("CrystalEgg_Tex")
    parts = [shell("CrystalEgg_Shell")]
    parts.append(crystal("CrystalEgg_Main", (0, 0, H-0.4), (0, 0, 1), 1.4, 0.28, 0))
    for k in range(4):
        a = math.radians(45 + 90*k); tl = math.radians(34)
        d = (math.sin(tl)*math.cos(a), math.sin(tl)*math.sin(a), math.cos(tl))
        parts.append(crystal("CrystalEgg_Side", (0.26*math.cos(a), 0.26*math.sin(a), H-0.42), d, 0.95 if k % 2 == 0 else 0.8, 0.2, 1 if k % 2 == 0 else 2))
    for a in (0, math.pi, math.pi/2, -math.pi/2):
        d = (0.8*math.cos(a), 0.8*math.sin(a), 0.6)
        parts.append(crystal("CrystalEgg_Small", (0.34*math.cos(a), 0.34*math.sin(a), H-0.5), d, 0.5, 0.12, 0 if a in (0, math.pi) else 1))
    return finish("CrystalEgg", parts, img, x)

def egg_jungle(x):
    P = Paint([(0, "3FAE55"), (0.5, "7ED957"), (1, "D4F77E")])
    P.scatter(14, 0.12, 0.17, "34A04C", vmin=0.35, vmax=0.9, seed=13, aspect=0.5, minsep=0.08)
    P.scatter(16, 0.03, 0.05, "F4F77A", vmin=0.5, vmax=0.93, seed=14, minsep=0.08)
    P.swatches(["2DA84E", "5CCB5F", "FF6B4A", "FFD84D"])
    img = P.save("JungleEgg_Tex")
    parts = [shell("JungleEgg_Shell")]
    for k in range(6):
        a = math.radians(15 + 60*k)
        parts.append(leaf("JungleEgg_Leaf", a, 0.08, 1.3 if k % 2 == 0 else 1.05, 0.42 if k % 2 == 0 else 0.34, k % 2))
    for a, z in ((math.radians(285), 1.05), (math.radians(105), 1.0)):
        n = Vector((math.cos(a), math.sin(a), 0)); t1 = Vector((-math.sin(a), math.cos(a), 0)); t2 = Vector((0, 0, 1))
        P0 = n*(shell_r(z) + 0.02) + Vector((0, 0, z))
        for k in range(5):
            b = 2*math.pi*k/5 + math.pi/2
            parts.append(blob("JungleEgg_Petal", P0 + n*0.03 + (t1*math.cos(b) + t2*math.sin(b))*0.12, (0.09, 0.09, 0.09), 2, seg=12, ring=8))
        parts.append(blob("JungleEgg_FlowerMid", P0 + n*0.1, (0.07, 0.07, 0.07), 3, seg=12, ring=8))
    return finish("JungleEgg", parts, img, x)

BUILDERS = [egg_snowy, egg_desert, egg_cursed, egg_crystal, egg_retro, egg_jungle, egg_absolutezero]
