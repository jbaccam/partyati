-- Pure pose regression, including intermediate frames and locomotion blends.
local M=require(game.ReplicatedStorage.RogueliteCombat.BossMotion)
local D=M.Data
local minimum,maximum,axisError,gap,poleDot=180,-180,0,0,1
local samples=0
local function check(poses)
 M.constrainArms(poses)
 for _,side in {'Right','Left'} do
  local function point(name) return Vector3.new(table.unpack(D.joints[side..name].head))-Vector3.yAxis*D.rootHeight end
  local a,b,w=point('UpperArm'),point('LowerArm'),point('Hand')
  local u,v=(b-a).Unit,(w-b).Unit;local axis=u:Cross(v).Unit
  local U,L,H=poses[side..'UpperArm'],poses[side..'LowerArm'],poses[side..'Hand']
  local lower=U:VectorToObjectSpace(L:VectorToWorldSpace(v))
  local signed=math.deg(math.atan2(axis:Dot(u:Cross(lower)),u:Dot(lower)))
  minimum=math.min(minimum,signed);maximum=math.max(maximum,signed)
  axisError=math.max(axisError,(U:VectorToWorldSpace(axis)-L:VectorToWorldSpace(axis)).Magnitude)
  gap=math.max(gap,(U*b-L*b).Magnitude,(L*w-H*w).Magnitude,(U*a-poses.UpperTorso*a).Magnitude)
  local shoulder,elbow,wrist=U*a,L*b,H*w;local reach=(wrist-shoulder).Unit
  local pole=poses.UpperTorso:VectorToWorldSpace(Vector3.new(side=='Right' and 2.2 or -2.2,-3.5,.35));pole-=reach*pole:Dot(reach)
  local bend=elbow-shoulder;bend-=reach*bend:Dot(reach)
  poleDot=math.min(poleDot,pole.Unit:Dot(bend.Unit))
 end
 samples+=1
end
for clip in D.clips do
 for f=0,math.ceil(M.duration(clip)*120) do check(M.sample(clip,math.min(f/120,M.duration(clip)))) end
end
for _,clip in {'Swing','Spin'} do
 local a=M.Attacks[clip]
 for f=0,math.ceil((a.finish-a.active)*120) do
  local head=M.head(CFrame.identity,clip,math.min(a.finish,a.active+f/120))
  assert(math.abs(head.Y+D.rootHeight-4.6)<.001,'Sweep lifted above avatar height: '..clip)
 end
end
for phase=0,7 do
 local walk=M.sample('Walk',M.duration('Walk')*phase/8)
 for _,clip in {'Slam','Swing','Spin','Hit','Death'} do
  for f=0,16 do
   local alpha=f/16;local target=M.sample(clip,alpha*.12);local blend=M.blend(walk,target,alpha)
   check(blend)
  end
 end
end
local idle=M.sample('Idle',0)
for _,clip in {'Slam','Swing','Spin'} do
 local a=M.Attacks[clip]
 for step=0,math.ceil((a.finish-a.active)*120) do
  local poses=M.sample(clip,math.min(a.finish,a.active+step/120))
  for _,side in {'Right','Left'} do
   local function point(n) return Vector3.new(table.unpack(D.joints[side..n].head))-Vector3.yAxis*D.rootHeight end
   local shoulder,elbow,wrist=point('UpperArm'),point('LowerArm'),point('Hand')
   local ratio=(poses[side..'Hand']*wrist-poses.UpperTorso*shoulder).Magnitude/((elbow-shoulder).Magnitude+(wrist-elbow).Magnitude)
   assert(ratio>.94,'Cramped active arm '..clip..' '..side)
  end
 end
 for _,time in {0,M.duration(clip)} do
  local poses=M.sample(clip,time)
  for _,name in {'Hammer','RightHand','LeftHand','RightUpperArm','LeftUpperArm','RightLowerArm','LeftLowerArm','Head'} do
   local diff=idle[name]:ToObjectSpace(poses[name]);local _,angle=diff:ToAxisAngle()
   assert(diff.Position.Magnitude<.0001 and math.abs(angle)<.002,'Carry reset mismatch '..clip..' '..name)
  end
 end
end
local result={samples=samples,minSignedFlexion=minimum,maxSignedFlexion=maximum,maxHingeAxisMismatch=axisError,maxJointGap=gap,minimumBendSideDot=poleDot}
-- A small positive bend and the shared hinge protect near-straight reach.
result.ok=minimum>=11.9 and maximum<=130.1 and axisError<.001 and gap<.001 and poleDot>=math.cos(math.rad(75))-.001
assert(result.ok,game:GetService('HttpService'):JSONEncode(result))
return result
