# render_icons.py - 512x512 transparent icons for the three game passes (task 8): 1.5x Snow, Starter Pack, Aurora Wheels.
# usage: blender -b --factory-startup -P render_icons.py
import bpy, math, os, sys
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\W1Remaster20261005"); sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
from w1lib import *
import paidgear

def scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try: sc.render.engine = eng; break
        except TypeError: pass
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = 512
    sc.render.image_settings.file_format = "PNG"; sc.render.image_settings.color_mode = "RGBA"
    sc.world = bpy.data.worlds.new("W")
    sc.world.use_nodes = True
    bg = next(n for n in sc.world.node_tree.nodes if n.type == "BACKGROUND"); bg.inputs[0].default_value = (0.9, 0.95, 1.0, 1); bg.inputs[1].default_value = 0.4
    for i, (rot, e) in enumerate((((math.radians(50), 0, math.radians(30)), 2.4), ((math.radians(70), 0, math.radians(-120)), 0.7))):
        ld = bpy.data.lights.new("L%d" % i, "SUN"); ld.energy = e
        lo = bpy.data.objects.new("L%d" % i, ld); lo.rotation_euler = rot; sc.collection.objects.link(lo)
    return sc

def shoot(sc, objs, path, d=(0.55, -1.0, 0.55), pad=1.15):
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    c = (lo + hi) / 2
    cd = bpy.data.cameras.new("C"); cd.type = "ORTHO"; cd.ortho_scale = max((hi - lo).length * 0.82, 1) * pad
    cam = bpy.data.objects.new("C", cd); sc.collection.objects.link(cam); sc.camera = cam
    dv = Vector(d).normalized(); cam.location = c + dv * 80
    cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("ICON", path)

def text(body, size, loc, col_hex, extrude=0.25):
    cu = bpy.data.curves.new("T", "FONT"); cu.body = body; cu.size = size; cu.extrude = extrude; cu.align_x = "CENTER"; cu.align_y = "CENTER"
    cu.bevel_depth = 0.04
    ob = bpy.data.objects.new("T", cu); ob.location = loc; ob.rotation_euler = (math.radians(90), 0, 0)
    ob.data.materials.append(L.pmat(col_hex + "SP")); bpy.context.scene.collection.objects.link(ob)
    return ob

# 1) 1.5x Snow: a chunky snowflake emblem with "x1.5"
sc = scene()
m = L.Model("Snow", at=(0, 0, 0))
for k in range(6):
    a = math.radians(60 * k)
    tube(m, P("6FBFFF"), [(0, 0, 0), (math.cos(a) * 3.2, 0, math.sin(a) * 3.2)], r=0.32, seg=8, part="Arm", smooth=1)
    for s in (-1, 1):
        b = a + s * math.radians(40)
        p0 = (math.cos(a) * 2.0, 0, math.sin(a) * 2.0)
        tube(m, P("9FD8FF"), [p0, (p0[0] + math.cos(b) * 1.0, 0, p0[2] + math.sin(b) * 1.0)], r=0.22, seg=8, part="Twig", smooth=1)
sphere(m, P("E8F6FF", "NE"), (0, 0, 0), r=1.1, seg=16, rings=10, part="Core")
objs = L.realize([m], "Snow")
t = text("x1.5", 2.2, (1.6, -1.6, -2.1), "FFB000")
shoot(sc, objs + [t], os.path.join(HERE, "renders", "icon_snow15.png"), d=(0.15, -1.0, 0.25))

# 2) Starter Pack: a gift crate with a ribbon, a snowflake tag and a little plow blade peeking out
sc = scene()
m = L.Model("Pack", at=(0, 0, 0))
bx(m, "Crate", "3E7FE0", -2.4, 2.4, -2.4, 2.4, 0, 3.4, r=0.3)
bx(m, "Lid", "5A98F0", -2.6, 2.6, -2.6, 2.6, 3.3, 3.9, r=0.25)
bx(m, "Ribbon", "E2483D", -0.45, 0.45, -2.65, 2.65, 0, 3.95, r=0.08)
bx(m, "Ribbon", "E2483D", -2.65, 2.65, -0.45, 0.45, 0, 3.95, r=0.08)
torus(m, P("E2483D"), (-0.7, 0, 4.4), R=0.7, r=0.22, seg=16, rseg=6, rot=(90, 0, 30), part="Bow")
torus(m, P("E2483D"), (0.7, 0, 4.4), R=0.7, r=0.22, seg=16, rseg=6, rot=(90, 0, -30), part="Bow")
bx(m, "Blade", "C9D6E6", -2.0, 2.0, -3.1, -2.7, 0.3, 1.6, r=0.15)
for x in (-1.4, 1.4): bx(m, "Blade", "8E9CB0", x - 0.15, x + 0.15, -2.75, -2.4, 0.5, 1.4, r=0.04)
objs = L.realize([m], "Pack")
shoot(sc, objs, os.path.join(HERE, "renders", "icon_starterpack.png"))

# 3) Aurora Wheels: one wheel of the set, seen from the outside
sc = scene()
m = L.Model("Wheel", at=(0, 0, 0))
paidgear.WHEELS = [(1, paidgear.FY)]   # one wheel only for the icon
paidgear.GearAuroraWheels(m)
objs = L.realize([m], "Wheel")
keep = []
for o in objs:  # keep only geometry near the front-right wheel (x > 2, y < 0)
    pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
    keep.append(o)
# move the camera to the right-front wheel
cx = Vector((3.2, -2.3, 0.9))
cd = bpy.data.cameras.new("C"); cd.type = "ORTHO"; cd.ortho_scale = 2.6
cam = bpy.data.objects.new("C", cd); sc.collection.objects.link(cam); sc.camera = cam
dv = Vector((1.0, -0.35, 0.25)).normalized(); cam.location = cx + dv * 40
cam.rotation_euler = (cx - cam.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = os.path.join(HERE, "renders", "icon_aurorawheels.png")
bpy.ops.render.render(write_still=True)
print("ICON", sc.render.filepath)
