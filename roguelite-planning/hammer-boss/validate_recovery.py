import json,os,math
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(os.environ['BOSS_MOTION_OUTPUT']);d=json.loads((OUT/'BossData.json').read_text())
def mat(a):return Matrix(((a[3],a[4],a[5],a[0]),(a[6],a[7],a[8],a[1]),(a[9],a[10],a[11],a[2]),(0,0,0,1)))
report={}
for clip,end in [('Swing',25),('Spin',37)]:
 rows=d['clips'][clip]['frames'];high=0;maxTurn=0;prev=None
 for f,row in enumerate(rows):
  rel=mat(row['Hammer']).inverted()@mat(row['LeftHand'])
  if prev is not None:maxTurn=max(maxTurn,math.degrees(prev.to_quaternion().rotation_difference(rel.to_quaternion()).angle))
  prev=rel
  if f>end+3:
   for side in ['Right','Left']:
    w=Vector(d['joints'][side+'Hand']['head'])-Vector((0,d['rootHeight'],0));high=max(high,(mat(row[side+'Hand'])@w).y+d['rootHeight'])
 assert maxTurn<15,(clip,'Left wrist snapped around shaft',maxTurn)
 assert high<6.5,(clip,'Handle raised toward face',high)
 report[clip]={'maxRecoveryWristHeight':high,'maxLeftGripRotationStepDegrees':maxTurn}
print(report)
(OUT/'direct-recovery-checks.json').write_text(json.dumps(report,indent=2))
