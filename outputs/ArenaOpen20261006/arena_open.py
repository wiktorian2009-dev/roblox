# arena_open.py - "no walls, absolute madness" arena (Claude, 2026-10-06). Rebuilds two arena models from
# outputs/Arena20261005/models.py with the open-rim layout:
#   ArenaOpenFloor: a smaller floating floor (radius FLOOR_R), full painted red/white edge band, spawn pads at PAD_R
#   Island: the sky island with a full void ring cut around the floor (FLOOR_R+0.4 .. VOID_R1, just inside the stands)
# Blender: arena centre at the origin, up = +Z, Studio local = (-x, z, y). usage: blender -b --factory-startup -P arena_open.py -- [--export] [--render]
import bpy, bmesh, sys, os, math
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\Arena20261005")
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
import models as MD
from w2lib import P, cyl, prism, rbox
from partlib import beam, star_poly

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
FLOOR_R, PAD_R, VOID_R1 = 45.0, 26.0, 64.6
RED, WHITE, YEL = MD.RED, MD.WHITE, MD.YEL


def ArenaOpenFloor(m):
    cyl(m, P(MD.ICE, "IC"), (0, 0, -1.2), r=FLOOR_R, h=1.2, seg=72, part="Ice")
    cyl(m, P(MD.ICE2), (0, 0, -2.6), r=FLOOR_R - 0.6, r2=FLOOR_R + 0.3, h=1.4, seg=72, part="Rim")
    prism(m, P(WHITE), star_poly(6, 9.5, 3.6), 0.06, loc=(0, 0, 0.0), part="Inlay")
    cyl(m, P(MD.BLUE), (0, 0, 0.0), r=3.0, h=0.08, seg=24, part="InlayBlue")
    MD.ring_strip(m, P(WHITE), 14.0, 0.8, 0.0, 0.05, n=64, part="Inlay")
    MD.ring_strip(m, P(MD.BLUE), 34.0, 0.7, 0.0, 0.05, n=96, part="InlayBlue")
    # the edge: a bold red / white striped band all the way round, and a thin yellow warning line inside it
    n = 48
    for i in range(n):
        d = 360.0 * (i + 0.5) / n
        MD.seg_box(m, P(RED if i % 2 == 0 else WHITE), d, FLOOR_R - 2.6, FLOOR_R - 0.05, 0.0, 0.06, 360.0 / n, "EdgeRed" if i % 2 == 0 else "EdgeWhite", r=0.0)
    MD.ring_strip(m, P(YEL), FLOOR_R - 3.6, 0.5, 0.0, 0.05, n=96, part="Hazard")
    for d in MD.PADS:
        x, y = MD.pol(PAD_R, d)
        cyl(m, P(MD.NAVY), (x, y, 0.0), r=4.4, h=0.05, seg=28, part="Pad")
        cyl(m, P(MD.TEAL), (x, y, 0.0), r=4.6, r2=4.6, h=0.03, seg=28, part="PadGlow")   # matte (was neon)
        ang = 180 - d + 180
        prism(m, P(WHITE), [(-1.6, -1.2), (1.6, -1.2), (0, 2.0)], 0.07, loc=(x, y, 0.0), rot=(0, 0, ang - 90), part="Inlay")
    m.flat("Ice", P(MD.ICE, "IC"), 20)


def ring_cutter(r0, r1, z0=-95.0, z1=14.0, seg=96):
    bm = bmesh.new()
    outer_b = [bm.verts.new((r1 * math.cos(2 * math.pi * i / seg), r1 * math.sin(2 * math.pi * i / seg), z0)) for i in range(seg)]
    outer_t = [bm.verts.new((v.co.x, v.co.y, z1)) for v in outer_b]
    inner_b = [bm.verts.new((r0 * math.cos(2 * math.pi * i / seg), r0 * math.sin(2 * math.pi * i / seg), z0)) for i in range(seg)]
    inner_t = [bm.verts.new((v.co.x, v.co.y, z1)) for v in inner_b]
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((outer_b[i], outer_b[j], outer_t[j], outer_t[i]))
        bm.faces.new((inner_b[j], inner_b[i], inner_t[i], inner_t[j]))
        bm.faces.new((outer_t[i], outer_t[j], inner_t[j], inner_t[i]))
        bm.faces.new((outer_b[j], outer_b[i], inner_b[i], inner_b[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("VoidRing"); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new("VoidRing", me); bpy.context.scene.collection.objects.link(o)
    return o


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mf = L.Model("ArenaOpenFloor", at=(0, 0, 0)); ArenaOpenFloor(mf)
    floor = L.realize([mf], "AR_ArenaOpen")
    mi = L.Model("Island", at=(0, 0, 0)); MD.Island(mi)
    isl = L.realize([mi], "AR_IslandOpen")
    cut = ring_cutter(FLOOR_R + 0.4, VOID_R1)
    keep = []
    for o in isl:
        part = o.name.split("__")[1]
        if part not in ("Rock", "Snow"):
            me = o.data; bpy.data.objects.remove(o, do_unlink=True); bpy.data.meshes.remove(me); continue
        mod = o.modifiers.new("cut", "BOOLEAN"); mod.operation = "DIFFERENCE"; mod.object = cut; mod.solver = "EXACT"
        mod.use_hole_tolerant = True; mod.use_self = True
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
        o.modifiers.clear(); old = o.data; o.data = me; bpy.data.meshes.remove(old)
        print("CUT", o.name, "tris", sum(len(p.vertices) - 2 for p in o.data.polygons))
        keep.append(o)
    me = cut.data; bpy.data.objects.remove(cut, do_unlink=True); bpy.data.meshes.remove(me)
    return floor, keep


def check(isl):
    from mathutils.bvhtree import BVHTree
    dg = bpy.context.evaluated_depsgraph_get()
    for o in isl:
        t = BVHTree.FromObject(o, dg)
        res = []
        for r in (30, 50, 56, 62, 70, 80):
            hits = sum(1 for a in range(0, 360, 30) if t.ray_cast(Vector((r * math.cos(math.radians(a)), r * math.sin(math.radians(a)), 50)), Vector((0, 0, -1)), 500)[0] is not None)
            res.append("r%d:%d/12" % (r, hits))
        print("RAY", o.name.split("__")[1], " ".join(res))


if __name__ == "__main__":
    floor, isl = build()
    check(isl)
    if "--export" in argv:
        os.makedirs(os.path.join(HERE, "fbx"), exist_ok=True)
        mm = L.Model("Ref", at=(0, 0, 0)); L.rbox(mm, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
        ref = L.realize([mm], "Ref")[0]; ref.name = "Ref__Origin__FF00FFNE"; ref.data.name = "Ref__Origin__FF00FFNE"
        path = os.path.join(HERE, "fbx", "AR_ArenaOpen.fbx")
        L.export_fbx(floor + isl + [ref], path); print("EXPORTED", path, os.path.getsize(path))
    if "--render" in argv:
        import importlib.util
        spec = importlib.util.spec_from_file_location("sg_scene", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\scene.py")
        S = importlib.util.module_from_spec(spec); spec.loader.exec_module(S)
        ms = []
        for n in ("Stands", "Jumbotron", "LightTowers"):
            mm = L.Model(n, at=(0, 0, 0)); MD.BUILDERS[n](mm); ms.append(mm)
        L.realize(ms, "Ctx")
        S.setup(res=(1600, 1000), samples=24, world=(0.62, 0.77, 0.95), strength=0.8)
        g = bpy.data.objects.get("RGround")
        if g: g.hide_render = True
        os.makedirs(os.path.join(HERE, "renders"), exist_ok=True)
        S.camera((60, -95, 40), (0, 0, -5), lens=26); S.render(os.path.join(HERE, "renders", "open_arena.png"))
        S.camera((0, 0, 260), (0, -0.01, 0), ortho=200); S.render(os.path.join(HERE, "renders", "open_top.png"))
    print("DONE")
