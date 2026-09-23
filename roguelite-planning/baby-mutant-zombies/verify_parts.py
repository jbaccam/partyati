import bpy,json
from pathlib import Path
out=Path('C:/Users/Jeremiah/Documents/ChatGPT/Roblox/roguelite-planning/baby-mutant-zombies')
results={}
for kind in ['Baby','Mutant']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=str(out/kind/'Parts.fbx'))
 results[kind]={'meshes':len([o for o in bpy.data.objects if o.type=='MESH']),'armatures':len([o for o in bpy.data.objects if o.type=='ARMATURE'])}
 assert results[kind]=={'meshes':15,'armatures':0},results
(out/'parts-verification.json').write_text(json.dumps(results,indent=2))
print(results)
