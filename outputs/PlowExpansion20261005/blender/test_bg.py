import bpy, sys, os
sys.path.insert(0, r"C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender")
import w2lib as L
bpy.ops.wm.read_factory_settings(use_empty=True)
m = L.Model("Test")
L.sphere(m, L.P("FF8040"), (0, 0, 1), 1.0)
objs = L.realize([m], "T")
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); bpy.context.scene.collection.objects.link(cam)
cam.location = (0, -6, 2); cam.rotation_euler = (1.35, 0, 0); bpy.context.scene.camera = cam
sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); bpy.context.scene.collection.objects.link(sun)
sc = bpy.context.scene
print("engines", [e.identifier for e in sc.render.bl_rna.properties["engine"].enum_items])
sc.render.resolution_x = sc.render.resolution_y = 128
sc.render.filepath = r"C:\Users\wikto\Desktop\Roblox Gra\outputs\PlowExpansion20261005\blender\test_bg.png"
bpy.ops.render.render(write_still=True)
print("OK", os.path.exists(sc.render.filepath))
