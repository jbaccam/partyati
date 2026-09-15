"""Run headlessly after build_character.py; verify FBX round trip and rig motion."""
import bpy, json, bmesh, math
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent
scene=bpy.data.scenes.new('ExportVerification');bpy.context.window.scene=scene
bpy.ops.import_scene.fbx(filepath=str(P/'PaleWatcher_Rigged.fbx'))
meshes=[o for o in scene.objects if o.type=='MESH'];rigs=[o for o in scene.objects if o.type=='ARMATURE']
assert len(meshes)==1 and len(rigs)==1,(len(meshes),len(rigs))
m=meshes[0];r=rigs[0];m.data.calc_loop_triangles()
assert len(m.data.loop_triangles)<=20000
assert all(1<=len(v.groups)<=4 for v in m.data.vertices)
assert all(abs(sum(g.weight for g in v.groups)-1)<.0001 for v in m.data.vertices)
assert len(m.data.uv_layers)>0
assert any(mod.type=='ARMATURE' and mod.object==r for mod in m.modifiers)
root=m.vertex_groups.get('Root')
assert root is None or not any(g.group==root.index and g.weight>0 for v in m.data.vertices for g in v.groups)
bm=bmesh.new();bm.from_mesh(m.data);bad=sum(not e.is_manifold for e in bm.edges);bm.free()
assert bad==0,bad
def coords():
    bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();o=m.evaluated_get(deps);me=o.to_mesh();v=[o.matrix_world@p.co for p in me.vertices];o.to_mesh_clear();return v
before=coords();pb=r.pose.bones['Finger2.L'];pb.rotation_mode='XYZ';pb.rotation_euler.x=.45;after=coords();moves=[(a-b).length for a,b in zip(after,before)]
assert max(moves)>.001
assert all(math.isfinite(c) for q in after for c in q)
pb.rotation_euler.x=0
data={'fbx_roundtrip':'PASS','meshes':len(meshes),'bones':len(r.data.bones),'triangles':len(m.data.loop_triangles),'normalized_weights':'PASS','root_unweighted':'PASS','nonmanifold_edges':bad,'finger_deformation':'PASS','finger_test_moved_vertices':sum(d>.0001 for d in moves),'max_finger_displacement_import_units':max(moves),'roblox_studio_import':'NOT TESTED','roblox_animation_playback':'NOT TESTED'}
assert r.data.bones['Head'].parent.name=='Neck'
for side in ['L','R']:
    assert r.data.bones['Hand.'+side].parent.name=='Forearm.'+side
    for j in range(1,6):assert r.data.bones['Finger%d.%s.tip'%(j,side)].parent.name=='Finger%d.%s'%(j,side)
data['bone_hierarchy']='PASS'
idle_scene=bpy.data.scenes.new('IdleVerification');bpy.context.window.scene=idle_scene
bpy.ops.import_scene.fbx(filepath=str(P/'PaleWatcher_Idle.fbx'))
idle_rig=next(o for o in idle_scene.objects if o.type=='ARMATURE')
assert idle_rig.animation_data and idle_rig.animation_data.action
idle_scene.frame_set(1);bpy.context.view_layer.update();rest=idle_rig.pose.bones['Head'].matrix.copy()
idle_scene.frame_set(23);bpy.context.view_layer.update();pose=idle_rig.pose.bones['Head'].matrix.copy()
assert sum(abs(rest[i][j]-pose[i][j]) for i in range(4) for j in range(4))>.0001
data['idle_animation_roundtrip']='PASS'
(P/'export_validation.json').write_text(json.dumps(data,indent=2));print(json.dumps(data),flush=True)
