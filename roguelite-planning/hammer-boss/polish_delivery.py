import bpy,json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent/'finished'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
s=bpy.context.scene;rig=bpy.data.objects['HammerBoss_Rig'];cam=s.camera
stages={'Slam':{'START':0,'ANTICIPATION':5,'MAX WINDUP':18,'ATTACK START':20,'IMPACT':23,'FOLLOW THROUGH':26,'RECOVERY':32,'IDLE':50},'Swing':{'START':0,'ANTICIPATION':6,'MAX WINDUP':18,'ATTACK START':19,'IMPACT':23,'FOLLOW THROUGH':30,'RECOVERY':44,'IDLE':54},'Spin':{'START':0,'ANTICIPATION':6,'MAX WINDUP':20,'ATTACK START':21,'IMPACT':29,'FOLLOW THROUGH':42,'RECOVERY':51,'IDLE':66}}
s.timeline_markers.clear()
for clip,markers in stages.items():
 bpy.data.actions['Boss_'+clip]['StageFrames']=json.dumps(markers)
 for label,f in markers.items():s.timeline_markers.new(clip+' | '+label,frame=f+1)
rig.animation_data.action=bpy.data.actions['Boss_Idle'];s.frame_set(1)
def camera(loc,target,scale):
 cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
camera((.4,-30,11),(-.7,0,6.05),16.2)
s.render.resolution_x=1086;s.render.resolution_y=1448;s.render.resolution_percentage=75;s.cycles.samples=32
s.render.filepath=str(OUT/'HammerBoss_Front.png')
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'HammerBoss.blend'))
camera((13,-27,11),(-.8,0,6),17.5);s.render.filepath=str(OUT/'HammerBoss_ThreeQuarter.png');bpy.ops.render.render(write_still=True)
camera((25,0,10),(0,0,6),16.5);s.render.filepath=str(OUT/'HammerBoss_Side.png');bpy.ops.render.render(write_still=True)
camera((0,28,10),(0,0,6),16.5);s.render.filepath=str(OUT/'HammerBoss_Back.png');bpy.ops.render.render(write_still=True)
camera((0,-.001,30),(-.3,0,5),16.5);s.render.filepath=str(OUT/'HammerBoss_Top.png');bpy.ops.render.render(write_still=True)
print('DELIVERY_VIEWS_COMPLETE')
