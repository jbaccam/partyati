"""Check anatomical wrist bend, shaft contact, and rigid joint continuity."""
import bpy,math,json,os
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(os.environ.get('BOSS_MOTION_OUTPUT',str(Path(__file__).resolve().parent/'finished')))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
data=json.loads((OUT/'BossData.json').read_text());bones=bpy.data.objects['HammerBoss_Rig'].data.bones
C=Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)));T=Matrix.Translation
HT=T((-4.4,-2.65,2.65))@Matrix.Rotation(math.radians(-13),4,'Y')
def delta(v):
 m=Matrix(((v[3],v[4],v[5],v[0]),(v[6],v[7],v[8],v[1]),(v[9],v[10],v[11],v[2]),(0,0,0,1)))
 return T((0,0,4.45))@C.inverted()@m@C@T((0,0,-4.45))
report={}
for clip in ['Slam','Swing','Spin']:
 worst=(0,None);gap=0;grip=0;clearance=100;jump=0;prev={}
 for f,row in enumerate(data['clips'][clip]['frames']):
  D={n:delta(v) for n,v in row.items()};H=D['Hammer']@HT;inv=D['UpperTorso'].inverted()
  for side,g in [('Right',2.72),('Left',8.05)]:
   b=bones[side+'LowerArm'].head_local;w=bones[side+'Hand'].head_local
   elbow=D[side+'LowerArm']@b;wrist=D[side+'Hand']@w
   direction=D[side+'Hand'].to_3x3()@HT.to_3x3()@Vector((0,0,1))
   bend=math.degrees((elbow-wrist).angle(direction))
   if bend>worst[0]:worst=(bend,[f,side])
   gap=max(gap,(D[side+'LowerArm']@w-wrist).length)
   p=H.inverted()@D[side+'Hand']@HT@Vector((g,0,0));grip=max(grip,math.hypot(p.y,p.z))
   for k in range(11):
    p=inv@elbow.lerp(wrist,k/10)
    clearance=min(clearance,(p.x/2.25)**2+((p.y+.15)/1.7)**2+((p.z-6.5)/2.15)**2)
   if side in prev:jump=max(jump,(inv@elbow-prev[side]).length)
   prev[side]=inv@elbow
 report[clip]={'maxWristBendDegrees':worst,'maxWristGap':gap,'maxGripRadialDrift':grip,'torsoClearanceSquared':clearance,'maxElbowStep':jump}
 assert worst[0]<35,(clip,'Folded wrist',worst)
 assert gap<.001,(clip,'Disconnected wrist',gap)
 assert grip<.001,(clip,'Grip left shaft',grip)
 assert clearance>1.25,(clip,'Forearm entered torso',clearance)
(OUT/'wrist-checks.json').write_text(json.dumps(report,indent=2));print('WRISTS',json.dumps(report))
