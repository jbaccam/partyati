"""Plan elbow swivel over the whole clip while preserving weapon/hand paths."""
def polish_hinges(frames):
 for side,sign in [('Right',-1),('Left',1)]:
  a=joints[side+'UpperArm']['head'];b=joints[side+'LowerArm']['head'];w=joints[side+'Hand']['head']
  l1=(b-a).length;l2=(w-b).length;cuff=HT.to_3x3()@Vector((0,0,1))
  layers=[];costs={};parents=[]
  for f,D in enumerate(frames):
   chest=D['UpperTorso'];inv=chest.inverted();shoulder=chest@a;wrist=D[side+'Hand']@w
   u=(wrist-shoulder).normalized();old=D[side+'LowerArm']@b-shoulder;old-=u*old.dot(u)
   pole=chest.to_3x3()@Vector((sign*2.2,.35,-3.5));pole-=u*pole.dot(u)
   original=math.degrees(math.atan2(u.dot(pole.cross(old)),pole.dot(old)))
   candidates=[original] if f in (0,len(frames)-1) else list(range(-75,76))
   direction=D[side+'Hand'].to_3x3()@cuff;valid={};back={};nextCosts={}
   for angle in candidates:
    elbow,err=elbow_hinge(side,shoulder,wrist,l1,l2,chest,math.radians(angle))
    if math.degrees((elbow-wrist).angle(direction))>=35:continue
    clear=True
    for k in range(11):
     p=inv@elbow.lerp(wrist,k/10)
     if (p.x/2.25)**2+((p.y+.15)/1.7)**2+((p.z-6.5)/2.15)**2<=1.0:clear=False;break
    if not clear:continue
    valid[angle]=elbow
    if not f:nextCosts[angle]=0;continue
    choices=[(cost+(angle-prev)**2+(angle-original)**2*.04,prev) for prev,cost in costs.items() if abs(angle-prev)<=20.0001]
    if choices:nextCosts[angle],back[angle]=min(choices)
   assert nextCosts,('No continuous elbow path',side,f)
   layers.append(valid);parents.append(back);costs=nextCosts
  angle=min(costs,key=costs.get);path=[angle]
  for f in range(len(frames)-1,0,-1):angle=parents[f][angle];path.append(angle)
  path.reverse()
  for D,layer,angle in zip(frames,layers,path):
   shoulder=D['UpperTorso']@a;wrist=D[side+'Hand']@w
   D[side+'UpperArm'],D[side+'LowerArm']=hinge_frames(a,b,w,shoulder,layer[angle],wrist)
 return frames
