"""Two-hand grip roll and elbow solve; the contact axis stays on the shaft."""
# A small positive bend avoids hyperextension; the stable body-owned hinge
# determines the bend direction even during near-straight reach.
ELBOW_MIN=math.radians(12)
ELBOW_MAX=math.radians(130)

def elbow_hinge(side,shoulder,wrist,l1,l2,chest,swivel=0):
 # The elbow plane belongs to the upper arm/body, NEVER to the hand roll.
 # A down/out pole keeps the elbow below and outside the shoulder when the
 # grip is carried in front, and preserves the same anatomical bend branch.
 s=-1 if side=='Right' else 1
 pole=shoulder+chest.to_3x3()@Vector((s*2.2,.35,-3.5))
 v=wrist-shoulder;distance=v.length;u=v.normalized()
 low=math.sqrt(l1*l1+l2*l2+2*l1*l2*math.cos(ELBOW_MAX))
 high=math.sqrt(l1*l1+l2*l2+2*l1*l2*math.cos(ELBOW_MIN))
 d=max(low,min(high,distance));along=(l1*l1-l2*l2+d*d)/(2*d)
 bend=pole-shoulder;bend-=u*bend.dot(u);bend.normalize()
 bend=Matrix.Rotation(max(-math.radians(75),min(math.radians(75),swivel)),3,u)@bend
 elbow=shoulder+u*along+bend*math.sqrt(max(0,l1*l1-along*along))
 return elbow,abs(distance-d)

def hinge_frames(a,b,w,shoulder,elbow,wrist):
 # Transport ONE elbow hinge frame through both bones. Independently
 # shortest-arc rotating the two meshes had twisted the visible elbow.
 def frame(direction,normal):
  y=direction.normalized();z=normal.normalized();x=y.cross(z).normalized()
  return Matrix((x,y,z)).transposed()
 upper=b-a;lower=w-b;restAxis=upper.cross(lower).normalized()
 liveUpper=elbow-shoulder;liveLower=wrist-elbow
 liveAxis=liveUpper.cross(liveLower).normalized()
 U=frame(liveUpper,liveAxis)@frame(upper,restAxis).transposed()
 restFlex=upper.angle(lower);flex=liveUpper.angle(liveLower)
 L=U@Matrix.Rotation(flex-restFlex,3,restAxis)
 return T(shoulder)@U.to_4x4()@T(-a),T(elbow)@L.to_4x4()@T(-b)

def grip_arm(side,weapon,offset,chest,previous=None):
 s=-1 if side=='Right' else 1
 a=joints[side+'UpperArm']['head'];b=joints[side+'LowerArm']['head'];w=joints[side+'Hand']['head']
 shoulder=chest@a;l1=(b-a).length;l2=(w-b).length
 base=weapon@offset;H=weapon@HT
 localGrip=HT.inverted()@offset@HT@Vector((2.72 if s<0 else 8.05,0,0))
 center=H@localGrip;axis=(H.to_3x3()@Vector((1,0,0))).normalized()
 cuff=(HT.to_3x3()@Vector((0,0,1))).normalized()
 inv=chest.inverted();best=None
 for degrees in range(-180,181,2):
  angle=math.radians(degrees)
  hand=around(center,Matrix.Rotation(angle,4,axis))@base
  wrist=hand@w;direction=(hand.to_3x3()@cuff).normalized()
  elbow,err=elbow_hinge(side,shoulder,wrist,l1,l2,chest)
  bend=(elbow-wrist).normalized().angle(direction)
  clearance=0
  for k in range(9):
   p=inv@elbow.lerp(wrist,k/8)
   q=(p.x/2.25)**2+((p.y+.15)/1.7)**2+((p.z-6.5)/2.15)**2
   clearance+=max(0,1.3-q)**2
  score=bend*bend+err*err*40+clearance*12+angle*angle*.002
  if previous is not None:score+=math.radians(degrees-previous)**2*.002
  if best is None or score<best[0]:best=(score,hand,elbow,err,math.degrees(bend),degrees)
 return best[1:]

def solve_grips(weapon,offsets,chest,history,grounded=False,sweepWeight=0,extensionWeight=0,carryWeight=1,overheadWeight=0,isSweep=False,heightTarget=4.6,tiltAllowed=True,flightHeight=None,motionContinuity=0,extensionTarget=.975):
 """Solve weapon placement and both wrist rolls together, with continuity."""
 inv=chest.inverted();cuff=HT.to_3x3()@Vector((0,0,1))
 baseline=globals().get("carryBase",[0.]*8)
 def evaluate(values):
  actual=[baseline[i]*(1-carryWeight)+values[i]*carryWeight for i in range(8)]
  for i in (3,4):actual[i]=baseline[i]+((values[i]-baseline[i]+math.pi)%math.tau-math.pi)*carryWeight
  actual[7]*=float(tiltAllowed)
  W=weapon.copy();baseH=W@HT
  tiltAxis=baseH.to_3x3()@Vector((0,1-carryWeight,carryWeight)).normalized() if isSweep else baseH.to_3x3()@Vector((0,1,0))
  W=around(baseH@Vector((7.3,0,0)),Matrix.Rotation(actual[7],4,tiltAxis))@W
  shift=chest.to_3x3()@Vector(actual[:3])
  if grounded:shift.z=0
  W.translation+=shift;H=W@HT
  if grounded:
   if flightHeight is not None:W.translation.z+=flightHeight-H.translation.z
   elif isSweep:W.translation.z+=heightTarget-H.translation.z
   else:W.translation.z+=.005-min((H@Vector((x,y,z))).z for x in [-1.55,1.55] for y in [-1.155,1.155] for z in [-2.21,2.21])
   H=W@HT
  axis=(H.to_3x3()@Vector((1,0,0))).normalized();solutions={};score=sum(x*x for x in values[:3])*3.0
  score+=actual[7]**2*2
  if motionContinuity and '_weapon' in history:score+=(W.translation-history['_weapon']).length_squared*10*motionContinuity
  score+=(H.translation.z-4.6)**2*5000*sweepWeight*sweepWeight
  for i,(side,g) in enumerate([('Right',2.72),('Left',8.05)]):
   a=joints[side+'UpperArm']['head'];b=joints[side+'LowerArm']['head'];w=joints[side+'Hand']['head']
   center=W@offsets[side]@HT@Vector((g,0,0))
   hand=around(center,Matrix.Rotation(actual[3+i],4,axis))@W@offsets[side]
   wrist=hand@w;direction=(hand.to_3x3()@cuff).normalized()
   elbow,err=elbow_hinge(side,chest@a,wrist,(b-a).length,(w-b).length,chest,actual[5+i])
   bend=(elbow-wrist).normalized().angle(direction)
   length=(b-a).length+(w-b).length
   extension=(wrist-chest@a).length/length
   score+=(extension-extensionTarget)**2*100000*extensionWeight
   # Below the shoulders, both cuffs and the held shaft stay ahead of the belly.
   score+=max(0,7.0+6.1*overheadWeight-wrist.z)**2*5000*overheadWeight
   localWrist=inv@wrist
   frontWeight=1-ease(9.5,11.5,localWrist.z)
   score+=max(0,localWrist.y+3.35)**2*1200*frontWeight
   score+=max(0,bend-math.radians(18))**2*4000+bend*bend*.04+err*err*20000
   for k in range(9):
    p=inv@elbow.lerp(wrist,k/8);q=(p.x/2.25)**2+((p.y+.15)/1.7)**2+((p.z-6.5)/2.15)**2
    score+=max(0,1.3-q)**2*1000
   if side in history:
    score+=(inv@elbow-history[side]['elbow']).length_squared*15.0
    diff=(values[3+i]-history[side]['roll']+math.pi)%math.tau-math.pi
    score+=diff*diff*(.25+25*motionContinuity)
    score+=(actual[5+i]-history[side]['swivel'])**2*15
   score+=values[5+i]**2*.02
   solutions[side]=(hand,elbow,err,bend,actual[3+i],actual[5+i])
  return score,W,solutions
 initial=list(history.get('_shift',[0.,0.,0.]))+[history.get(side,{}).get('roll',0.) for side in ('Right','Left')]+[history.get(side,{}).get('swivel',0.) for side in ('Right','Left')]+[history.get('_tilt',0.)]
 # Independent coarse rolls are a second seed, avoiding a bad local branch.
 seeds=[initial]
 seeds.append([0.,0.,0.]+[math.radians(grip_arm(side,weapon,offsets[side],chest)[4]) for side in ('Right','Left')]+[0.,0.,0.])
 best=None
 for values in seeds:
  current=evaluate(values)
  for positionStep,angleStep in [(.4,20),(.2,10),(.1,5),(.04,2),(.01,.5)]:
   for repeat in range(12):
    changed=False
    for index in range(8):
     if grounded and index==2:continue
     for sign in (-1,1):
      trial=values.copy();trial[index]+=sign*(positionStep if index<3 else math.radians(angleStep))
      if index<3 and abs(trial[index])>8.0:continue
      if 5<=index<=6 and abs(trial[index])>math.radians(75):continue
      if index==7 and abs(trial[index])>math.radians(35):continue
      result=evaluate(trial)
      if result[0]<current[0]:values,current=trial,result;changed=True
    if not changed:break
  if best is None or current[0]<best[0]:best=current;bestValues=values.copy()
 # Projection is mandatory, not a score penalty: preserve exact bone
 # lengths and joint limits even when the wrist objective is infeasible.
 W=best[1].copy()
 for iteration in range(160):
  worst=0
  for side,g in [('Right',2.72),('Left',8.05)]:
   a=joints[side+'UpperArm']['head'];b=joints[side+'LowerArm']['head'];w=joints[side+'Hand']['head']
   axis=(W.to_3x3()@HT.to_3x3()@Vector((1,0,0))).normalized();center=W@offsets[side]@HT@Vector((g,0,0))
   hand=around(center,Matrix.Rotation(best[2][side][4],4,axis))@W@offsets[side]
   v=hand@w-chest@a;d=v.length;l1=(b-a).length;l2=(w-b).length
   low=math.sqrt(l1*l1+l2*l2+2*l1*l2*math.cos(ELBOW_MAX-.001))
   high=math.sqrt(l1*l1+l2*l2+2*l1*l2*math.cos(ELBOW_MIN+.001))
   correction=max(low,min(high,d))-d;worst=max(worst,abs(correction))
   direction=v.normalized()
   if grounded:direction.z=0
   W.translation+=direction*(correction/max(direction.length_squared,.001))
  if worst<.000001:break
 shift=Vector(bestValues[:3])+chest.to_3x3().transposed()@(W.translation-best[1].translation)/max(carryWeight,1e-6)
 bestValues[:3]=list(shift);best=evaluate(bestValues)
 history['_weapon']=best[1].translation.copy()
 history['_shift']=bestValues[:3]
 history['_values']=bestValues.copy()
 history['_tilt']=bestValues[7]
 for side,(hand,elbow,err,bend,roll,swivel) in best[2].items():history[side]={'roll':roll,'elbow':inv@elbow,'swivel':swivel}
 return best[1],best[2]
