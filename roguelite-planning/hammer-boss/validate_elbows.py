"""Validate signed elbow flexion and the same hinge axis on BOTH meshes."""
import bpy,math,json,os
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(os.environ.get('BOSS_MOTION_OUTPUT',str(Path(__file__).resolve().parent/'finished')))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'HammerBoss.blend'))
data=json.loads((OUT/'BossData.json').read_text());bones=bpy.data.objects['HammerBoss_Rig'].data.bones
C=Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)));T=Matrix.Translation
def delta(v):
 m=Matrix(((v[3],v[4],v[5],v[0]),(v[6],v[7],v[8],v[1]),(v[9],v[10],v[11],v[2]),(0,0,0,1)))
 return T((0,0,4.45))@C.inverted()@m@C@T((0,0,-4.45))
report={};failures=[]
for clip,anim in data['clips'].items():
 minimum=180;maximum=-180;axisError=0;gap=0;minPole=1;steps=0;previous={};previousSwivel={};swivelStep=0
 for f,row in enumerate(anim['frames']):
  D={n:delta(v) for n,v in row.items()}
  for side,s in [('Right',-1),('Left',1)]:
   a=bones[side+'UpperArm'].head_local;b=bones[side+'LowerArm'].head_local;w=bones[side+'Hand'].head_local
   U=D[side+'UpperArm'];L=D[side+'LowerArm'];H=D[side+'Hand'];chest=D['UpperTorso']
   restUpper=(b-a).normalized();restLower=(w-b).normalized();hinge=restUpper.cross(restLower).normalized()
   lowerInUpper=U.to_3x3().transposed()@L.to_3x3()@restLower
   signed=math.degrees(math.atan2(hinge.dot(restUpper.cross(lowerInUpper)),restUpper.dot(lowerInUpper)))
   minimum=min(minimum,signed);maximum=max(maximum,signed)
   axisError=max(axisError,(U.to_3x3()@hinge-L.to_3x3()@hinge).length)
   gap=max(gap,(U@b-L@b).length,(L@w-H@w).length,(U@a-chest@a).length)
   shoulder=U@a;elbow=L@b;wrist=H@w;u=(wrist-shoulder).normalized()
   pole=chest.to_3x3()@Vector((s*2.2,.35,-3.5));pole-=u*pole.dot(u)
   bend=elbow-shoulder;bend-=u*bend.dot(u)
   minPole=min(minPole,bend.normalized().dot(pole.normalized()))
   swivel=math.degrees(math.atan2(u.dot(pole.cross(bend)),pole.dot(bend)))
   if side in previousSwivel:swivelStep=max(swivelStep,abs(swivel-previousSwivel[side]))
   previousSwivel[side]=swivel
   if side in previous:steps=max(steps,(chest.inverted()@elbow-previous[side]).length)
   previous[side]=chest.inverted()@elbow
 report[clip]={'minSignedFlexion':minimum,'maxSignedFlexion':maximum,'maxHingeAxisMismatch':axisError,'maxJointGap':gap,'minimumBendSideDot':minPole,'maxElbowStep':steps,'maxSwivelStepDegrees':swivelStep}
 if clip in ['Slam','Swing','Spin'] and swivelStep>20.1:failures.append(clip+' shoulder snap')
 if minimum<11.9 or maximum>130.1 or axisError>.001 or gap>.001 or minPole<math.cos(math.radians(75))-.001:failures.append(clip)
(OUT/'elbow-checks.json').write_text(json.dumps(report,indent=2));print('ELBOWS',json.dumps(report))
assert not failures,failures
