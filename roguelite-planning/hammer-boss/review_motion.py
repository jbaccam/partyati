import bpy,json,math,sys
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['HammerBoss_Rig'];rig.animation_data_clear()
D=json.loads((OUT/'BossData.json').read_text())
C=Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
def matrix(a):return Matrix(((a[3],a[4],a[5],a[0]),(a[6],a[7],a[8],a[1]),(a[9],a[10],a[11],a[2]),(0,0,0,1)))
def pose(clip,f):
    frames=D['clips'][clip]['frames'];f=min(f,len(frames)-1)
    for n,a in frames[f].items():
        d=Matrix.Translation((0,0,D['rootHeight']))@C.inverted()@matrix(a)@C@Matrix.Translation((0,0,-D['rootHeight']))
        rig.pose.bones[n].matrix=d@rig.data.bones[n].matrix_local;bpy.context.view_layer.update()
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=440;scene.render.resolution_y=440;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.camera.data.ortho_scale=19
views={'Front':(0,-27,9),'Side':(27,0,9),'Back':(0,27,9),'Top':(0,-.1,30)}
samples={'Idle':[0,24,48,72,96],'Walk':[0,10,20,30,40,60,81],'Slam':[0,9,17,21,23,27,36,46,50],'Swing':[0,14,18,21,23,25,33,43,54],'Spin':[0,14,20,24,27,30,33,37,40,48,58,66],'Hit':[0,4,9,14,18],'Death':[0,12,24,36,48,60,72,84]}
dest=OUT/'review';dest.mkdir(exist_ok=True)
for view,loc in views.items():
    scene.camera.location=loc;scene.camera.rotation_euler=(Vector((0,0,5))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
    for clip,frames in samples.items():
        for frame in frames:
            pose(clip,frame);scene.render.filepath=str(dest/f'{clip}_{view}_{frame:03}.png');bpy.ops.render.render(write_still=True)
print('MOTION_REVIEW_DONE')
