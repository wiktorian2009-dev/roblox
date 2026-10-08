"""Independent FBX round-trip checks, plus a close-up of the new Desert landmarks."""
import bpy, json, math, traceback
from pathlib import Path
from mathutils import Vector
OUT=Path(r'C:\Users\wikto\Desktop\Roblox Gra\outputs\StageBlender20261001')
manifest=json.loads((OUT/'manifest.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=str(OUT/'AllStages.fbx'),use_image_search=True)
meshes={o.name:o for o in bpy.context.scene.objects if o.type=='MESH'}
assert set(meshes)==set(manifest['models']), {'missing':list(set(manifest['models'])-set(meshes)), 'extra':list(set(meshes)-set(manifest['models']))}
report={'mesh_count':len(meshes),'triangles':0,'size_errors':{},'missing_uv':[],'untextured':[],'missing_images':[],'zero_scale':[]}
for name,o in meshes.items():
    report['triangles']+=sum(len(p.vertices)-2 for p in o.data.polygons)
    size=manifest['models'][name]['blender_size']
    # The baked FBX local axes are Y-up (width, height, depth).
    expected=[size[0],size[2],size[1]]
    actual=list(o.dimensions)
    error=max(abs(a/.01-e)for a,e in zip(actual,expected))
    if error>.004:report['size_errors'][name]={'actual':actual,'expected':expected,'error':error}
    if not o.data.uv_layers:report['missing_uv'].append(name)
    if any(abs(s)<1e-8 for s in o.scale):report['zero_scale'].append(name)
    nodes=[n for m in o.data.materials if m and m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE']
    if not nodes:report['untextured'].append(name)
    for node in nodes:
        if node.image is None or not node.image.has_data:report['missing_images'].append(name)
report['coordinate_basis']='FBX Y-up; 0.01 exported units per authored stud; Studio import still requires verification'
report['passed']=all(not report[k]for k in ('size_errors','missing_uv','untextured','missing_images','zero_scale')) and report['triangles']==manifest['triangles']
(OUT/'export-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
assert report['passed'],report
print('FBX_ROUNDTRIP_PASS',json.dumps(report),flush=True)

bpy.ops.wm.open_mainfile(filepath=str(OUT/'AllStages.blend'))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=1000;scene.render.resolution_y=820;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
plans={'Desert_ShadeCaravan':(-5,1,0),'Desert_SunArch':(6,8,0),'Desert_Camel':(5,-3,0),'Desert_Meerkat':(-1,-6,0)}
for o in scene.objects:
    o.hide_render=o.name not in plans
    if o.name in plans:o.location=plans[o.name]
scene.world.use_nodes=True;bg=scene.world.node_tree.nodes.get('Background');bg.inputs['Color'].default_value=(.5,.63,.80,1);bg.inputs['Strength'].default_value=.65
bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object
mat=bpy.data.materials.new('WarmPreviewFloor');mat.use_nodes=True;mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.67,.39,.17,1);floor.data.materials.append(mat)
for loc,energy,size in [((-14,-19,33),5200,16),((15,8,18),2600,12)]:
    d=bpy.data.lights.new('PreviewLight','AREA');o=bpy.data.objects.new('PreviewLight',d);scene.collection.objects.link(o);o.location=loc;d.energy=energy;d.size=size;o.rotation_euler=(Vector((0,0,4))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('DetailCamera');o=bpy.data.objects.new('DetailCamera',d);scene.collection.objects.link(o);scene.camera=o
target=Vector((0,0,5));o.location=target+Vector((22,-34,24));o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler();d.type='ORTHO';d.ortho_scale=34
scene.render.filepath=str(OUT/'Desert-landmarks-preview.png');bpy.ops.render.render(write_still=True)
print('DETAIL_RENDER_COMPLETE',flush=True)
