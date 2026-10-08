# render_icon.py - transparent 512x512 icon of the TRAVEL pad for the HUD button / menu banner.
# usage: blender -b blend/W1_Travel.blend -P render_icon.py
import bpy, os, math
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sc = bpy.context.scene
for o in list(bpy.data.objects):
    if o.type in ("CAMERA", "LIGHT") or o.name.startswith("Lbl_") or o.name.startswith("Ground") or "Ref__" in o.name:
        bpy.data.objects.remove(o, do_unlink=True)
for o in list(bpy.data.objects):
    if o.type == "MESH" and not o.name.startswith("T_TravelPad"): bpy.data.objects.remove(o, do_unlink=True)
objs = [o for o in bpy.data.objects if o.type == "MESH"]
mn = Vector((min(v[0] for o in objs for v in o.bound_box), 0, 0))
pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
c = (lo + hi) / 2
try: sc.render.engine = "BLENDER_EEVEE_NEXT"
except TypeError:
    try: sc.render.engine = "BLENDER_EEVEE"
    except TypeError: pass
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = 512
sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
cam_d = bpy.data.cameras.new("Cam"); cam_d.type = "ORTHO"; cam_d.ortho_scale = max(hi.x - lo.x, hi.y - lo.y) * 1.08
cam = bpy.data.objects.new("Cam", cam_d); sc.collection.objects.link(cam); sc.camera = cam
d = Vector((0.0, -1.0, 0.72)).normalized()
cam.location = c + d * 60
cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
for i, (loc, e) in enumerate((((20, -30, 40), 3.5), ((-30, 10, 25), 1.5))):
    ld = bpy.data.lights.new("L%d" % i, "SUN"); ld.energy = e
    lo_ = bpy.data.objects.new("L%d" % i, ld); lo_.location = loc; lo_.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(lo_)
if sc.world is None: sc.world = bpy.data.worlds.new("W")
sc.world.use_nodes = True
bg = next(n for n in sc.world.node_tree.nodes if n.type == "BACKGROUND"); bg.inputs[0].default_value = (0.85, 0.92, 1.0, 1); bg.inputs[1].default_value = 0.8
sc.render.filepath = os.path.join(HERE, "renders", "travel_icon.png")
bpy.ops.render.render(write_still=True)
print("ICON", sc.render.filepath)
