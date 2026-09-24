import bpy,json
from pathlib import Path
p=Path(__file__).resolve().parent
results=[]
for entry in json.loads((p/'manifest.json').read_text()):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(p/(entry['name']+'.fbx')))
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert len(obs)==1
    ob=obs[0]; ob.data.calc_loop_triangles()
    print('COUNTS',entry['name'],len(ob.data.loop_triangles),entry['triangles'])
    assert abs(len(ob.data.loop_triangles)-entry['triangles'])<=entry['triangles']*.01
    assert len(ob.data.loop_triangles)<10000
    assert ob.data.uv_layers and len(ob.data.materials)==1
    assert ob.location.length<.0001
    assert min((ob.matrix_world@v.co).z for v in ob.data.vertices)>=-.001
    results.append({'name':entry['name'],'passed':True,'sourceTriangles':entry['triangles'],'importedTriangles':len(ob.data.loop_triangles)})
(p/'validation.json').write_text(json.dumps(results,indent=2))
print(json.dumps(results))
