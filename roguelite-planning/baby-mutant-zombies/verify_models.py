"""Reopen both masters and both interchange formats, checking actual export contents."""
import bpy, bmesh, json, math
from pathlib import Path
OUT=Path(__file__).resolve().parent
results={}
for kind in ('Baby','Mutant'):
    expected=set(json.loads((OUT/kind/'manifest.json').read_text())['sections'])
    for fmt in ('blend','fbx','glb'):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        path=str(OUT/kind/('Model.'+fmt))
        if fmt=='blend': bpy.ops.wm.open_mainfile(filepath=path)
        elif fmt=='fbx': bpy.ops.import_scene.fbx(filepath=path)
        else: bpy.ops.import_scene.gltf(filepath=path)
        meshes={o.name:o for o in bpy.context.scene.objects if o.type=='MESH' and o.name in expected}
        assert set(meshes)==expected,(kind,fmt,list(meshes))
        rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
        assert len(rigs)==1
        rig=rigs[0]
        assert len(rig.data.bones)==16
        assert set(rig.data.bones.keys())==expected|{'HumanoidRootPart'}
        for bone in rig.pose.bones:
            bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0)
        bpy.context.view_layer.update()
        nonmanifold=0
        for name,o in meshes.items():
            assert len(o.data.materials)==1,(name,'materials')
            assert o.data.uv_layers
            assert all(math.isfinite(v) and 0<=v<=1 for uv in o.data.uv_layers.active.data for v in uv.uv)
            if name in ('Head','LeftFoot','RightFoot','LeftHand','RightHand','LeftLowerArm','RightLowerArm'):
                assert all(uv.uv.y>.5 for uv in o.data.uv_layers.active.data),(name,'clothing pixels on skin')
            assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in o.data.vertices),(name,'weights')
            bm=bmesh.new();bm.from_mesh(o.data)
            bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
            nonmanifold += sum(not e.is_manifold for e in bm.edges)
            assert all(f.calc_area()>1e-12 for f in bm.faces),(name,'degenerate face')
            bm.free()
            images=[n.image for n in o.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
            for image in images:
                _=image.pixels[0]
            assert images and all(i.has_data for i in images),(name,'texture')
        assert nonmanifold==0,(kind,fmt,'open edges',nonmanifold)
        world_verts=[o.matrix_world@v.co for o in meshes.values() for v in o.data.vertices]
        assert abs(min(v.z for v in world_verts))<.001,(kind,fmt,'ground alignment')
        def points(name):
            o=meshes[name].evaluated_get(bpy.context.evaluated_depsgraph_get())
            return [o.matrix_world@v.co for v in o.data.vertices]
        before=points('LeftLowerArm');foot=points('RightFoot')
        rig.pose.bones['LeftLowerArm'].rotation_euler.x=.6;bpy.context.view_layer.update()
        moved=max((a-b).length for a,b in zip(before,points('LeftLowerArm')))
        stable=max((a-b).length for a,b in zip(foot,points('RightFoot')))
        assert moved>.05 and stable<.001,(kind,fmt,moved,stable)
        results[kind+'_'+fmt]={'body_sections':15,'bones':16,'uv_bounds':'pass','normalized_weights':'pass',
            'closed_geometry':'pass','textures_loaded':True,'elbow_displacement':moved,'unrelated_foot_displacement':stable}
(OUT/'verification.json').write_text(json.dumps(results,indent=2))
print('VERIFIED',json.dumps(results))
