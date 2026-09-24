import bpy, math
from pathlib import Path
from mathutils import Vector, Quaternion
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'Mutant/Model.blend'))
scene=bpy.context.scene
rig=bpy.data.objects['MutantZombie_Rig']
# Move both arms out from the body to expose the continuous sleeve undersides.
for side,s in [('Left',1),('Right',-1)]:
    bone=rig.pose.bones[side+'UpperArm'];bone.rotation_mode='QUATERNION'
    local_axis=bone.bone.matrix_local.to_3x3().inverted()@Vector((0,1,0))
    bone.rotation_quaternion=Quaternion(local_axis,math.radians(-s*60))
cam=scene.camera;cam.location=(10,-25,9)
cam.rotation_euler=(Vector((0,0,4.2))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.ortho_scale=15
scene.render.resolution_x=1200;scene.render.resolution_y=1000
scene.render.filepath=str(OUT/'Mutant/UnderarmCheck.png')
bpy.ops.render.render(write_still=True)
