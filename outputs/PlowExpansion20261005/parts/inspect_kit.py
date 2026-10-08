import bpy, json
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\wikto\Desktop\Roblox Gra\outputs\SnowplowKit2026\SnowplowKit.blend")
out = []
for c in bpy.data.collections:
    out.append("COL %s: %d objs" % (c.name, len(c.objects)))
for o in bpy.data.objects:
    s = "%s type=%s loc=%s par=%s" % (o.name, o.type, tuple(round(x, 3) for x in o.matrix_world.translation), o.parent.name if o.parent else None)
    if o.type == "MESH":
        ws = [o.matrix_world @ Vector(b) for b in o.bound_box]
        mn = [round(min(v[i] for v in ws), 2) for i in range(3)]; mx = [round(max(v[i] for v in ws), 2) for i in range(3)]
        s += " bb=%s..%s tris=%d" % (mn, mx, sum(len(p.vertices) - 2 for p in o.data.polygons))
    out.append(s)
print("\n".join(out))
