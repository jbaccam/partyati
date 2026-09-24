import bpy,json,math,os
from pathlib import Path
from mathutils import Matrix,Vector
HERE=Path(__file__).resolve().parent
OUT=Path(os.environ.get('BOSS_MOTION_OUTPUT',str(HERE/'finished')))
d=json.loads((OUT/'BossData.json').read_text())
C=Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)));T=Matrix.Translation
HT=T((-4.4,-2.65,2.65))@Matrix.Rotation(math.radians(-13),4,'Y')
def mat(a):return Matrix(((a[3],a[4],a[5],a[0]),(a[6],a[7],a[8],a[1]),(a[9],a[10],a[11],a[2]),(0,0,0,1)))
def delta(a):return T((0,0,4.45))@C.inverted()@mat(a)@C@T((0,0,-4.45))
report={}
for clip,active in {'Slam':(23,24),'Swing':(19,25),'Spin':(21,37)}.items():
 frames=d['clips'][clip]['frames'];drift=0;grips=[];normals=[];faceMargins=[];reaches=[];ground=[]
 for f,row in enumerate(frames):
  H=delta(row['Hammer'])@HT;pair=[]
  for side,g in [('Right',2.72),('Left',8.05)]:
   q=H.inverted()@delta(row[side+'Hand'])@HT@Vector((g,0,0));drift=max(drift,math.hypot(q.y,q.z));pair.append(q.x)
  if active[0]<=f<=active[1]:
   grips.append(pair);reaches.append(math.hypot(H.translation.x,H.translation.y))
   if clip=='Slam':ground.append(min((H@Vector((x,y,z))).z for x in [-1.55,1.55] for y in [-1.155,1.155] for z in [-2.21,2.21]))
   else:
    prev=delta(frames[max(0,f-1)]['Hammer'])@HT;following=delta(frames[min(f+1,len(frames)-1)]['Hammer'])@HT
    velocity=(following.translation-prev.translation).normalized();normal=H.to_3x3()@Vector((0,0,1));normals.append(velocity.dot(normal));faceMargins.append(velocity.dot(normal)-max(abs(velocity.dot(H.to_3x3()@Vector(axis))) for axis in [(1,0,0),(0,1,0)]))
 report[clip]={'maxRadialGripDrift':drift,'activeGripPositions':grips,'minHeadReach':min(reaches),'maxHeadReach':max(reaches),'minLeadingFaceDot':min(normals) if normals else None,'minHeadGround':min(ground) if ground else None,'maxHeadGround':max(ground) if ground else None}
 assert drift<.001,(clip,'Grip left shaft')
 assert all(abs(a-6.55)<.001 and abs(b-8.05)<.001 for a,b in grips),(clip,'Hands not at handle end')
 # The intended striking face must lead more than either broad/side face.
 if normals:assert min(faceMargins)>0,(clip,'Wrong striking face',min(faceMargins))
 if ground:assert max(abs(z-.005) for z in ground)<.001,(clip,'Ground contact')
(OUT/'lever-motion-checks.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
