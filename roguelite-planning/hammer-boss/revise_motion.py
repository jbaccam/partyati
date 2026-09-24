import bpy,math,json,os
from pathlib import Path
from mathutils import Matrix,Vector
HERE=Path(__file__).resolve().parent;OUT=HERE/'finished'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
if os.environ.get('BOSS_MOTION_OUTPUT'):
 OUT=Path(os.environ['BOSS_MOTION_OUTPUT']);OUT.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene;rig=bpy.data.objects['HammerBoss_Rig'];rig.animation_data_clear()
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
T=Matrix.Translation
def R(x=0,y=0,z=0):return Matrix.Rotation(math.radians(z),4,'Z')@Matrix.Rotation(math.radians(y),4,'Y')@Matrix.Rotation(math.radians(x),4,'X')
def around(p,r):return T(p)@r@T(-Vector(p))
HT=T((-4.4,-2.65,2.65))@R(y=-13);mid=HT@Vector((5.385,0,0));ROOT=4.45
joints={n:{'parent':b.parent.name,'head':b.head_local.copy(),'tail':b.tail_local.copy()} for n,b in rig.data.bones.items() if n!='HumanoidRootPart'}
objects={n:bpy.data.objects[n] for n in joints}
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
source=(HERE/'finish_reference.py').read_text();exec(source[source.index('# hip yaw'):])
