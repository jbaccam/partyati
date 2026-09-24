"""Separate the existing launcher's coplanar rear disks; retain atlas and silhouette.

Run in Blender background mode. No rebake, render, upload or rocket edits.
The matching generator change lives in build_guns.py's rocket().
"""
import bpy, json, math, shutil
from pathlib import Path

root = Path(__file__).resolve().parents[2]
folder = root / 'assets' / '11-rocket-launcher'
backup = folder / 'backups' / '20260922-rear-cap'
backup.mkdir(parents=True, exist_ok=True)
for filename in ('Model.blend', 'Model.glb', 'Model.fbx', 'validation.json'):
    target = backup / filename
    if not target.exists(): shutil.copy2(folder / filename, target)

bpy.ops.wm.open_mainfile(filepath=str(folder / 'Model.blend'))
collection = next(c for c in bpy.data.collections if c.name.endswith('| EXPORT') and c.objects)
ob = next(o for o in collection.objects if o.type == 'MESH')
ob.name='Rocket_Launcher'
changed = []
for v in ob.data.vertices:
    # The model pivot is original (1.64, 0, 2.10); Blender is Z-up.
    if abs(v.co.x + 4.19) < 1e-5 and abs(math.hypot(v.co.y, v.co.z) - .51) < 1e-5:
        changed.append(v.index)
        v.co.x += .03
assert len(changed) in (0,10), f'Unexpected rear ring vertices: {len(changed)}'
assert sum(abs(v.co.x+4.16)<1e-5 and abs(math.hypot(v.co.y,v.co.z)-.51)<1e-5 for v in ob.data.vertices)==10
ob.data.update()
bpy.ops.object.select_all(action='DESELECT')
ob.select_set(True); bpy.context.view_layer.objects.active=ob
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'Model.blend'))
bpy.ops.export_scene.fbx(filepath=str(folder/'Model.fbx'),use_selection=True,object_types={'MESH'},bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
bpy.ops.export_scene.gltf(filepath=str(folder/'Model.glb'),use_selection=True,export_format='GLB',export_animations=False)
stats=json.loads((folder/'validation.json').read_text())
stats['rear_bore_repair']={
    'old_olive_and_dark_cap_original_x': -2.55,
    'olive_cap_original_x': -2.55, 'dark_cap_original_x': -2.52,
    'depth_separation': .03, 'moved_vertices':10,
    'texture_unchanged':True, 'imported_roblox_mesh_replaced':False,
    'studio_compatibility_repair':'WeaponPresentation.stabilizeLauncher v2',
}
for ext in ('glb','fbx'):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    if ext=='glb':bpy.ops.import_scene.gltf(filepath=str(folder/'Model.glb'))
    else:bpy.ops.import_scene.fbx(filepath=str(folder/'Model.fbx'))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert len(meshes)==1
    mesh=meshes[0].data;mesh.calc_loop_triangles()
    degenerate=sum((mesh.vertices[t.vertices[1]].co-mesh.vertices[t.vertices[0]].co).cross(mesh.vertices[t.vertices[2]].co-mesh.vertices[t.vertices[0]].co).length<1e-10 for t in mesh.loop_triangles)
    assert len(mesh.loop_triangles)==2588 and degenerate==0
    stats['rear_bore_repair'][ext+'_reimport']={'triangles':2588,'zero_area_triangles':0,'passed':True}
(folder/'validation.json').write_text(json.dumps(stats,indent=2)+'\n')
print('REAR_CAP_REPAIRED',json.dumps(stats['rear_bore_repair']))
