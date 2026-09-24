"""Regression for extended attack silhouettes, raised hands, and safe reset."""
import json,os,math
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(os.environ.get('BOSS_MOTION_OUTPUT',str(Path(__file__).resolve().parent/'finished')))
d=json.loads((OUT/'BossData.json').read_text())
def mat(v):return Matrix(((v[3],v[4],v[5],v[0]),(v[6],v[7],v[8],v[1]),(v[9],v[10],v[11],v[2]),(0,0,0,1)))
def joint(side,n):return Vector(d['joints'][side+n]['head'])-Vector((0,d['rootHeight'],0))
headRest=mat(d['hammerHeadRest']);idle=d['clips']['Idle']['frames'][0];report={};fail=[]
for clip,active in [('Slam',range(23,30)),('Swing',range(19,26)),('Spin',range(21,38))]:
 extension=[];shaftClear=100;resetError=0;overhead=[]
 for f,row in enumerate(d['clips'][clip]['frames']):
  pose={n:mat(v) for n,v in row.items()};chest=pose['UpperTorso'];inv=chest.inverted();H=pose['Hammer']@headRest
  for side in ['Right','Left']:
   a,b,w=[joint(side,n) for n in ['UpperArm','LowerArm','Hand']]
   wrist=pose[side+'Hand']@w
   if f in active:extension.append((wrist-chest@a).length/((b-a).length+(w-b).length))
   if clip=='Slam' and f==18:overhead.append(wrist.y+d['rootHeight'])
  # Probe the full wooden shaft against a conservative torso core.
  for k in range(41):
   p=inv@(H@Vector((-1.45-k/40*7.6,0,0)));p.y+=d['rootHeight']
   q=(p.x/2.25)**2+((p.y-6.5)/2.15)**2+((p.z+.15)/1.7)**2
   shaftClear=min(shaftClear,q)
  if f in (0,d['clips'][clip]['lastFrame']):
   for n in row:resetError=max(resetError,max(abs(x-y) for x,y in zip(row[n],idle[n])))
 report[clip]={'minActiveExtension':min(extension),'maxActiveExtension':max(extension),'minimumShaftTorsoDistanceSquared':shaftClear,'carryPoseMismatch':resetError,'overheadWristHeights':overhead}
 if min(extension)<.94 or max(extension)>1.001 or shaftClear<1 or resetError>.0001 or (overhead and min(overhead)<12.7):fail.append(clip)
(OUT/'extended-motion-checks.json').write_text(json.dumps(report,indent=2));print('EXTENDED',json.dumps(report));assert not fail,fail
