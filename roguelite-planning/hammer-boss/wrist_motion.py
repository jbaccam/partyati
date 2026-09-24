"""Two-hand grip roll and elbow solve; the contact axis stays on the shaft."""
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
  # Bend the elbow toward the wrist cuff, rather than leaving the hand
  # fixed to the head's roll and solving the arm on an unrelated plane.
  elbow,err=ik(shoulder,wrist,l1,l2,wrist+direction*l2)
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

def wrist_forearm(a,b,c,d,hand):
 def frame(tangent,side):
  tangent=tangent.normalized();side-=tangent*side.dot(tangent);side.normalize()
  return Matrix((side,tangent,tangent.cross(side))).transposed()
 side=HT.to_3x3()@Vector((1,0,0))
 rotation=frame(d-c,hand.to_3x3()@side)@frame(b-a,side).transposed()
 return T(c)@rotation.to_4x4()@T(-a)

def solve_grips(weapon,offsets,chest,history,grounded=False):
 """Solve weapon placement and both wrist rolls together, with continuity."""
 inv=chest.inverted();cuff=HT.to_3x3()@Vector((0,0,1))
 def evaluate(values):
  W=weapon.copy();shift=chest.to_3x3()@Vector(values[:3])
  if grounded:shift.z=0
  W.translation+=shift;H=W@HT
  axis=(H.to_3x3()@Vector((1,0,0))).normalized();solutions={};score=sum(x*x for x in values[:3])*.03
  for i,(side,g) in enumerate([('Right',2.72),('Left',8.05)]):
   a=joints[side+'UpperArm']['head'];b=joints[side+'LowerArm']['head'];w=joints[side+'Hand']['head']
   center=W@offsets[side]@HT@Vector((g,0,0))
   hand=around(center,Matrix.Rotation(values[3+i],4,axis))@W@offsets[side]
   wrist=hand@w;direction=(hand.to_3x3()@cuff).normalized()
   elbow,err=ik(chest@a,wrist,(b-a).length,(w-b).length,wrist+direction*4)
   bend=(elbow-wrist).normalized().angle(direction)
   score+=max(0,bend-math.radians(18))**2*20+bend*bend*.04+err*err*20000
   for k in range(9):
    p=inv@elbow.lerp(wrist,k/8);q=(p.x/2.25)**2+((p.y+.15)/1.7)**2+((p.z-6.5)/2.15)**2
    score+=max(0,1.3-q)**2*80
   if side in history:
    score+=(inv@elbow-history[side]['elbow']).length_squared*.08
    diff=(values[3+i]-history[side]['roll']+math.pi)%math.tau-math.pi
    score+=diff*diff*.025
   solutions[side]=(hand,elbow,err,bend,values[3+i])
  return score,W,solutions
 initial=[0.,0.,0.]+[history.get(side,{}).get('roll',0.) for side in ('Right','Left')]
 # Independent coarse rolls are a second seed, avoiding a bad local branch.
 seeds=[initial,[0.,0.,0.]+[math.radians(grip_arm(side,weapon,offsets[side],chest)[4]) for side in ('Right','Left')]]
 best=None
 for values in seeds:
  current=evaluate(values)
  for positionStep,angleStep in [(.4,20),(.2,10),(.1,5),(.04,2)]:
   for repeat in range(8):
    changed=False
    for index in range(5):
     if grounded and index==2:continue
     for sign in (-1,1):
      trial=values.copy();trial[index]+=sign*(positionStep if index<3 else math.radians(angleStep))
      if index<3 and abs(trial[index])>2.4:continue
      result=evaluate(trial)
      if result[0]<current[0]:values,current=trial,result;changed=True
    if not changed:break
  if best is None or current[0]<best[0]:best=current
 for side,(hand,elbow,err,bend,roll) in best[2].items():history[side]={'roll':roll,'elbow':inv@elbow}
 return best[1],best[2]
