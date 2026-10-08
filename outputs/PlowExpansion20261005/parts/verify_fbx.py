import bpy, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
for pack in ("Blades_A", "Blades_B", "Engines_A", "Engines_B", "Gears_A", "Gears_B"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(HERE, "fbx", pack + ".fbx"))
    obs = [o for o in bpy.data.objects if o.type == "MESH"]
    models = sorted({o.name.split("__")[0] for o in obs})
    ref = [o for o in obs if o.name.startswith("Ref__")]
    tris = sum(len(p.vertices) - 2 for o in obs for p in o.data.polygons)
    print("VERIFY", pack, "objs", len(obs), "models", len(models), "ref", [(r.name, tuple(round(v, 3) for v in r.matrix_world.translation)) for r in ref], "tris", tris)
