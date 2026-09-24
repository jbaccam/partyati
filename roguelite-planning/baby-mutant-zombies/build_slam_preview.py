"""Bake Luau motor poses onto Blender bones for review."""
import bpy,json,math
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'Mutant/Model.blend'))
scene=bpy.context.scene
rig=bpy.data.objects['MutantZombie_Rig']
manifest=json.loads((OUT/'Mutant/manifest.json').read_text())
data=json.loads((OUT/'slam-poses.json').read_text())
frames=list(data['frames'].values()) if isinstance(data['frames'],dict) else data['frames']
def array(v):return [v[str(i)] for i in range(1,len(v)+1)] if isinstance(v,dict) else v
C=Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
def matrix(v):
    v=array(v)
    return C.inverted()@Matrix(((v[3],v[4],v[5],v[0]),(v[6],v[7],v[8],v[1]),(v[9],v[10],v[11],v[2]),(0,0,0,1)))@C
def motor(name):
    if name=='LowerTorso':return 'Root'
    if name=='UpperTorso':return 'Waist'
    if name=='Head':return 'Neck'
    for p,n in [('UpperArm','Shoulder'),('LowerArm','Elbow'),('Hand','Wrist'),('UpperLeg','Hip'),('LowerLeg','Knee'),('Foot','Ankle')]:
        if name.endswith(p):return name.replace(p,n)
def pose(poses,keyframe=None):
    transforms={'HumanoidRootPart':Matrix.Identity(4)}
    for name,joint in manifest['joints'].items():
        pivot=Matrix.Translation(Vector(joint['head']))
        D=transforms[joint['parent']]@pivot@matrix(poses[motor(name)])@pivot.inverted()
        transforms[name]=D
        bone=rig.pose.bones[name];bone.rotation_mode='QUATERNION'
        bone.matrix=D@rig.data.bones[name].matrix_local
        bpy.context.view_layer.update()
        if keyframe is not None:
            bone.keyframe_insert(data_path='location',frame=keyframe,group=name)
            bone.keyframe_insert(data_path='rotation_quaternion',frame=keyframe,group=name)
    bpy.context.view_layer.update()
scene.render.fps=30;scene.frame_start=1;scene.frame_end=31
for sample in frames:pose(sample['poses'],1+round(sample['time']*30))
rig.animation_data.action.name='Mutant_Overhead_Slam_OneSecond'
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Mutant/SlamAnimation.blend'))
obs=[bpy.data.objects[n] for n in manifest['sections']]
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in obs:o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.fbx(filepath=str(OUT/'Mutant/SlamAnimation.fbx'),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,bake_anim=True,bake_anim_use_all_actions=False,bake_anim_use_nla_strips=False,bake_anim_simplify_factor=0,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
scene.render.resolution_x=850;scene.render.resolution_y=1000;scene.cycles.samples=24
cam=scene.camera;cam.location=(10,-23,10);cam.rotation_euler=(Vector((0,0,5.2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=14
measure={}
for name,frame in [('Hunched',1),('ArmsRaised',11),('Impact',15)]:
    scene.frame_set(frame);bpy.context.view_layer.update()
    scene.render.filepath=str(OUT/'Mutant'/('Slam_'+name+'.png'));bpy.ops.render.render(write_still=True)
    points=[]
    for hand in ['LeftHand','RightHand']:
        ob=bpy.data.objects[hand].evaluated_get(bpy.context.evaluated_depsgraph_get())
        pts=[ob.matrix_world@v.co for v in ob.data.vertices]
        points.append({'name':hand,'bottom':min(v.z for v in pts),'forward':-sum(v.y for v in pts)/len(pts)})
    measure[name]=points
(OUT/'Mutant/slam-check.json').write_text(json.dumps(measure,indent=2))
print('SLAM_POSE_CHECK',json.dumps(measure))
