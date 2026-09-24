import bpy,json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent/'finished'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
before=set(bpy.data.objects)
for o in before:
 if o.type=='MESH' and o.name!='RENDER_STAGE_ONLY':o.hide_render=True
bpy.ops.import_scene.fbx(filepath=str(OUT/'HammerBoss_Import.fbx'))
imported=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
report={o.name:{'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'uvs':[uv.name for uv in o.data.uv_layers]} for o in imported}
(OUT/'fbx-roundtrip-checks.json').write_text(json.dumps(report,indent=2))
s=bpy.context.scene;cam=s.camera;cam.location=(6,-12,7);cam.rotation_euler=(Vector((3.45,-2.65,5.35))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=4.4
s.cycles.samples=16;s.render.resolution_percentage=60;s.render.filepath=str(OUT/'FBX_Grip_Roundtrip.png');bpy.ops.render.render(write_still=True)
print('FBX_ROUNDTRIP_COMPLETE',json.dumps(report))
