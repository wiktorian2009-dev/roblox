# pits.py - Snowplow Bumper Arena island with a void pit behind each exit (Claude, 2026-10-06).
# Rebuilds the Island model from outputs/Arena20261005/models.py and cuts an annular-sector shaft straight through the
# Rock + Snow meshes behind every exit gap, so a vehicle pushed out falls visibly below the island instead of sinking into snow.
# usage: blender -b --factory-startup -P pits.py -- [--export] [--render]
import bpy, bmesh, sys, os, math
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
ARENA = r"C:\Users\wikto\Desktop\Roblox Gra\outputs\Arena20261005"
sys.path.insert(0, ARENA)
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
import models as MD

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PIT_R0, PIT_R1, PIT_HALF = MD.FLOOR_R + 0.4, 93.0, 17.0   # floor edge -> past the stands; +-17 deg keeps rock under the stands


def sector(name, g):
    """Closed prism: annular sector around Roblox exit angle g, z from -90 to +12."""
    bm = bmesh.new()
    n = 14
    pts = []
    for i in range(n + 1):
        d = g - PIT_HALF + 2 * PIT_HALF * i / n
        pts.append(MD.pol(PIT_R1, d))
    for i in range(n, -1, -1):
        d = g - PIT_HALF + 2 * PIT_HALF * i / n
        pts.append(MD.pol(PIT_R0, d))
    bot = [bm.verts.new((x, y, -90.0)) for x, y in pts]
    top = [bm.verts.new((x, y, 12.0)) for x, y in pts]
    bm.faces.new(bot[::-1]); bm.faces.new(top)
    k = len(pts)
    for i in range(k):
        j = (i + 1) % k
        bm.faces.new((bot[i], bot[j], top[j], top[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    return o


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m = L.Model("Island", at=(0, 0, 0)); MD.Island(m)
    objs = L.realize([m], "AR_Island")
    cutters = [sector("Pit%d" % g, g) for g in MD.EXITS]
    dg = bpy.context.evaluated_depsgraph_get()
    kept = []
    for o in objs:
        part = o.name.split("__")[1]
        if part not in ("Rock", "Snow"): continue
        before = len(o.data.polygons)
        for c in cutters:
            mod = o.modifiers.new("cut_" + c.name, "BOOLEAN"); mod.operation = "DIFFERENCE"; mod.object = c; mod.solver = "EXACT"; mod.use_hole_tolerant = True; mod.use_self = True
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
        o.modifiers.clear(); old = o.data; o.data = me; bpy.data.meshes.remove(old)
        print("CUT", o.name, before, "->", len(o.data.polygons), "tris", sum(len(p.vertices) - 2 for p in o.data.polygons))
        kept.append(o)
    for c in cutters:
        me = c.data; bpy.data.objects.remove(c, do_unlink=True); bpy.data.meshes.remove(me)
    for o in objs:
        if o not in kept:
            me = o.data; bpy.data.objects.remove(o, do_unlink=True); bpy.data.meshes.remove(me)
    return kept


def bbox(objs):
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for o in objs:
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
    return mn, mx


if __name__ == "__main__":
    objs = build()
    for o in objs:
        mn, mx = bbox([o]); print("BBOX", o.name, tuple(round(x, 2) for x in mn), tuple(round(x, 2) for x in mx))
    # check: a ray straight down through each pit centre must miss Rock and Snow; one at 0 deg (under the stands) must hit
    from mathutils.bvhtree import BVHTree
    dg = bpy.context.evaluated_depsgraph_get()
    trees = {o.name.split("__")[1]: (BVHTree.FromObject(o, dg), o.matrix_world.inverted()) for o in objs}
    for g in MD.EXITS + [0, 90]:
        for r in (66, 78, 90):
            x, y = MD.pol(r, g)
            hits = {}
            for k, (t, inv) in trees.items():
                org = inv @ Vector((x, y, 50)); dirv = (inv.to_3x3() @ Vector((0, 0, -1))).normalized()
                hits[k] = t.ray_cast(org, dirv, 500)[0] is not None
            print("RAY", g, r, hits)
    print("MW", [tuple(round(v, 2) for v in o.matrix_world.translation) for o in objs], [tuple(o.scale) for o in objs])
    if "--export" in argv:
        m = L.Model("Ref", at=(0, 0, 0)); L.rbox(m, "FF00FFNE", (0, 0, 0), (0.2, 0.2, 0.2), r=0.0, part="Origin")
        ref = L.realize([m], "AR_IslandPits_Ref")[0]; ref.name = "Ref__Origin__FF00FFNE"; ref.data.name = "Ref__Origin__FF00FFNE"
        os.makedirs(os.path.join(HERE, "fbx"), exist_ok=True)
        path = os.path.join(HERE, "fbx", "AR_IslandPits.fbx")
        L.export_fbx(objs + [ref], path); print("EXPORTED", path, os.path.getsize(path))
    if "--render" in argv:
        import importlib.util
        spec = importlib.util.spec_from_file_location("sg_scene", r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SharedGarage20261005\scene.py")
        SG = importlib.util.module_from_spec(spec); spec.loader.exec_module(SG)
        # arena ring models for context
        ms = []
        for n in ("ArenaFloor", "WallRing", "ExitGates", "Stands"):
            mm = L.Model(n, at=(0, 0, 0)); MD.BUILDERS[n](mm); ms.append(mm)
        L.realize(ms, "Ctx")
        SG.setup(res=(1600, 1000), samples=24, world=(0.62, 0.77, 0.95), strength=0.8)
        g = bpy.data.objects.get("RGround")
        if g: g.hide_render = True
        ex = MD.pol(80, 45)
        SG.camera((ex[0] * 0.2 - 60, ex[1] * 0.2 - 60, 70), (ex[0], ex[1], -10), lens=30)
        SG.render(os.path.join(HERE, "renders", "pit_exit45.png"))
        SG.camera((0, 0, 330), (0, -0.01, 0), ortho=260); SG.render(os.path.join(HERE, "renders", "pits_top.png"))
        SG.camera((ex[0] * 1.9, ex[1] * 1.9, -95), (ex[0], ex[1], -10), lens=30); SG.render(os.path.join(HERE, "renders", "pit_below.png"))
    print("DONE")
