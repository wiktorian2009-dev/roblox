# check_zones.py - vertex-level clearance check of every body against the frame's keep-clear zones (Blender coords: x, y = front/back,
# z = up; Roblox local = (-x, z, y)). usage: blender -b blend/Bodies_A.blend -P check_zones.py
import bpy, json, os
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
AT = {k: v["at"] for k, v in json.load(open(os.path.join(HERE, "stats_bodies.json"))).items()}
# (name, (xmin, ymin, zmin), (xmax, ymax, zmax)) - y negative = front
ZONES = [("driver", (-1.55, -0.85, 2.75), (1.55, 2.25, 6.8)),
         ("engine", (-1.7, 2.15, 2.7), (1.7, 4.85, 7.2)),
         ("blade", (-7.0, -9.0, 0.0), (7.0, -4.3, 4.0)),
         ("wheels", (2.6, -3.9, -0.1), (3.7, 3.9, 1.9)),   # |x| test below
         ]
res = {}
for o in bpy.data.objects:
    if o.type != "MESH" or "__" not in o.name: continue
    body = o.name.split("__")[0]
    if body not in AT: continue
    at = Vector(AT[body]); mw = o.matrix_world
    for v in o.data.vertices:
        p = mw @ v.co - at
        for name, lo, hi in ZONES:
            x = abs(p.x) if name == "wheels" else p.x
            if lo[0] < x < hi[0] and lo[1] < p.y < hi[1] and lo[2] < p.z < hi[2]:
                key = (body, name, o.name.split("__")[1])
                res[key] = res.get(key, 0) + 1
out = {}
for (b, z, part), n in sorted(res.items()): out.setdefault(b, []).append("%s:%s(%d)" % (z, part, n))
for b in AT: print("ZONE", b, "clear" if b not in out else ", ".join(out[b]))
