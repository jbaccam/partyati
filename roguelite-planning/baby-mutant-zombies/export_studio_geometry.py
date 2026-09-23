import bpy,json
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(__file__).resolve().parent
C=Matrix(((-1,0,0),(0,0,1),(0,1,0)))
for kind in ['Baby','Mutant']:
    bpy.ops.wm.open_mainfile(filepath=str(OUT/kind/'Model.blend'))
    manifest=json.loads((OUT/kind/'manifest.json').read_text())
    data={'kind':kind,'parts':{},'joints':manifest['joints'],'height':manifest['height']}
    for name in manifest['sections']:
        ob=bpy.data.objects[name];me=ob.data;me.calc_loop_triangles()
        world=[C@(ob.matrix_world@v.co) for v in me.vertices]
        lo=Vector(tuple(min(v[i] for v in world) for i in range(3)))
        hi=Vector(tuple(max(v[i] for v in world) for i in range(3)))
        center=(lo+hi)/2
        rounded=lambda v:[round(float(x),6) for x in v]
        triangles=[]
        for tri in me.loop_triangles:
            uv=[rounded((me.uv_layers.active.data[li].uv.x,1-me.uv_layers.active.data[li].uv.y)) for li in tri.loops]
            normal=C@ob.matrix_world.to_3x3()@tri.normal
            triangles.append([list(tri.vertices),uv,rounded(normal.normalized())])
        data['parts'][name]={'center':rounded(center),'size':rounded(hi-lo),'vertices':[rounded(v-center) for v in world],'triangles':triangles}
    for j in data['joints'].values():
        j['head']=rounded(C@Vector(j['head']));j['tail']=rounded(C@Vector(j['tail']))
    (OUT/kind/'StudioGeometry.json').write_text(json.dumps(data,separators=(',',':')))
compact={}
for kind in ['Baby','Mutant']:
    data=json.loads((OUT/kind/'StudioGeometry.json').read_text())
    compact[kind]={'height':data['height'],'joints':data['joints'],
                   'parts':{name:{key:part[key] for key in ['center','size']} for name,part in data['parts'].items()}}
(OUT/'ZombieImportData.luau').write_text("return game:GetService('HttpService'):JSONDecode([====["+json.dumps(compact,separators=(',',':'))+"]====])\n")
print('STUDIO_GEOMETRY_EXPORTED')
