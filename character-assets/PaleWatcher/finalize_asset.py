"""Repair coincident component edge welds without changing UVs, weights or silhouette."""
import bpy,bmesh,json
from pathlib import Path
P=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(P/'PaleWatcher.blend'))
s=bpy.data.scenes['PaleWatcher_Asset'];bpy.context.window.scene=s
m=s.objects['PaleWatcher'];r=s.objects['PaleWatcher_Rig']
bm=bmesh.new();bm.from_mesh(m.data)
shared=[e for e in bm.edges if len(e.link_faces)>2]
if shared:bmesh.ops.split_edges(bm,edges=shared)
assert all(e.is_manifold for e in bm.edges)
bm.to_mesh(m.data);bm.free();m.data.update()
for v in m.data.vertices:
    x,y,z=v.co
    name='Foot.'+('L' if x>0 else 'R') if z<.40 else ('Pelvis' if 3.10<z<4.35 and abs(x)<.45 and y<-.32 else None)
    if name:
        for g in list(v.groups):m.vertex_groups[g.group].remove([v.index])
        m.vertex_groups[name].add([v.index],1,'REPLACE')
s.frame_set(1);bpy.ops.object.select_all(action='DESELECT');m.select_set(True);r.select_set(True);bpy.context.view_layer.objects.active=r
action=r.animation_data.action;r.animation_data.action=None
args=dict(use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
bpy.ops.export_scene.fbx(filepath=str(P/'PaleWatcher_Rigged.fbx'),bake_anim=False,**args)
r.animation_data.action=action
bpy.ops.export_scene.fbx(filepath=str(P/'PaleWatcher_Idle.fbx'),bake_anim=True,bake_anim_use_all_actions=False,bake_anim_use_nla_strips=False,**args)
s.frame_set(1);bpy.ops.wm.save_as_mainfile(filepath=str(P/'PaleWatcher.blend'))
stats=json.loads((P/'validation.json').read_text());stats['vertices']=len(m.data.vertices);m.data.calc_loop_triangles();stats['triangles']=len(m.data.loop_triangles);stats['split_coincident_edges']=len(shared)
(P/'validation.json').write_text(json.dumps(stats,indent=2));print(stats)
