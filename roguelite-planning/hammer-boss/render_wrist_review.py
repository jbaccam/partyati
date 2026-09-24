import bpy,os
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent/'finished'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['HammerBoss_Rig'];cam=scene.camera
scene.render.resolution_x=1000;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.cycles.samples=24
cam.location=(17,-17,12);cam.rotation_euler=(Vector((0,-1,6))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=20
for clip,f in [('Slam',23),('Swing',25),('Spin',29),('Swing',47)]:
 rig.animation_data.action=bpy.data.actions['Boss_'+clip];scene.frame_set(f+1)
 scene.render.filepath=str(OUT/('WristReview_'+clip+'_'+str(f)+'.png'));bpy.ops.render.render(write_still=True)
