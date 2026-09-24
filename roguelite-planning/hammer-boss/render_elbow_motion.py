"""Frame-by-frame geometry review; no image generation or pose substitution."""
import bpy,os
from pathlib import Path
from mathutils import Vector
OUT=Path(os.environ.get('BOSS_MOTION_OUTPUT',str(Path(__file__).resolve().parent/'finished')))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['HammerBoss_Rig'];cam=scene.camera
scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.color_type='TEXTURE'
scene.display.shading.light='STUDIO';scene.display.shading.show_shadows=True
scene.render.resolution_x=720;scene.render.resolution_y=600;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
folder=OUT/'elbow-review-frames';folder.mkdir(exist_ok=True)
cam.location=(22,-16,15);cam.rotation_euler=(Vector((0,-1,9))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=31
for clip,last in [('Slam',50),('Swing',54),('Spin',66)]:
 rig.animation_data.action=bpy.data.actions['Boss_'+clip]
 for f in range(0,last+1,2):
  scene.frame_set(f+1);scene.render.filepath=str(folder/(clip+'_'+str(f).zfill(3)+'.png'));bpy.ops.render.render(write_still=True)
