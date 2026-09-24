import bpy,json
from pathlib import Path
p=Path(__file__).resolve().parent
for entry in json.loads((p/'manifest.json').read_text()):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(p/(entry['name']+'.fbx')))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert len(meshes)==1
    o=meshes[0]; o.data.calc_loop_triangles()
    assert len(o.data.loop_triangles)==entry['triangles']
    assert o.data.uv_layers and len(o.data.materials)==1
    assert o.location.length<.0001
    assert abs(min((o.matrix_world@v.co).z for v in o.data.vertices))<.0001
    print('PASS',entry['name'],entry['triangles'])
