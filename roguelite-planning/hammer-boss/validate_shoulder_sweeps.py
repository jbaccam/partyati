"""Check the shoulder-load sequence, delayed grip slide and horizontal sweeps."""
import json, math, os
from pathlib import Path
from mathutils import Matrix, Vector
OUT=Path(os.environ.get('BOSS_MOTION_OUTPUT',str(Path(__file__).resolve().parent/'finished')))
d=json.loads((OUT/'BossData.json').read_text())
def mat(a):return Matrix(((a[3],a[4],a[5],a[0]),(a[6],a[7],a[8],a[1]),(a[9],a[10],a[11],a[2]),(0,0,0,1)))
H0=mat(d['hammerHeadRest']);report={}
for clip,start,end in [('Swing',19,25),('Spin',21,37)]:
 rows=d['clips'][clip]['frames'];lift=start-7;gripError=0;angles=[];flex=[]
 for f,row in enumerate(rows):
  H=mat(row['Hammer'])@H0
  if f<=lift:
   for side,g in [('Right',2.72),('Left',8.05)]:
    contact=H.inverted()@mat(row[side+'Hand'])@H0@Vector((-g,0,0))
    gripError=max(gripError,abs(contact.x+g),abs(contact.y),abs(contact.z))
  if start<=f<=end:
   shaft=H.to_3x3()@Vector((1,0,0));assert abs(shaft.y)<.0001,(clip,f,'shaft not level')
   angles.append(math.atan2(shaft.z,shaft.x))
 row=rows[lift];H=mat(row['Hammer'])@H0
 for side in ['Right','Left']:
  def point(name):return Vector(d['joints'][side+name]['head'])-Vector((0,d['rootHeight'],0))
  shoulder=mat(row['UpperTorso'])@point('UpperArm');elbow=mat(row[side+'LowerArm'])@point('LowerArm');wrist=mat(row[side+'Hand'])@point('Hand')
  flex.append(math.degrees((elbow-shoulder).angle(wrist-elbow)))
 sweep=abs(sum((b-a+math.pi)%math.tau-math.pi for a,b in zip(angles,angles[1:])))*180/math.pi
 report[clip]={'carryGripErrorThroughShoulderLift':gripError,'loadedElbowFlexionDegrees':flex,'headHeightAtShoulder':H.translation.y+d['rootHeight'],'sweepDegrees':sweep}
 assert gripError<.001,(clip,'hands slid before the shoulder lift finished')
 assert H.translation.y+d['rootHeight']>11.5,(clip,'missing shoulder lift')
 assert min(flex)>35 and max(flex)<130,(clip,'load pose elbows not bent',flex)
 assert abs(sweep-(180 if clip=='Swing' else 360))<.01,(clip,'wrong sweep',sweep)
(OUT/'shoulder-sweep-checks.json').write_text(json.dumps(report,indent=2));print('SHOULDER_SWEEPS',json.dumps(report))
