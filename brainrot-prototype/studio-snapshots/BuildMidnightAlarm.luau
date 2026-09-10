-- Rebuild the editable Midnight Alarm clip without changing the user's weapon grip.
return function()
 local p=game.ReplicatedStorage.TungPrototype
 local mesh=p.Assets.TungSahur:FindFirstChild("Mesh",true)
 local bones={} for _,b in mesh:GetDescendants() do if b:IsA("Bone") then bones[b.Name]=b end end
 local weapon=bones["Bone.008"]:FindFirstChild("WeaponGrip").CFrame
 local function fromTo(a,b)
  a=a.Unit; b=b.Unit
  local dot=math.clamp(a:Dot(b),-1,1)
  if dot>.99999 then return CFrame.identity end
  local axis=a:Cross(b)
  if axis.Magnitude<.0001 then axis=a:Cross(Vector3.xAxis); if axis.Magnitude<.0001 then axis=a:Cross(Vector3.zAxis) end end
  return CFrame.fromAxisAngle(axis.Unit,math.acos(dot))
 end
 local function arm(out,position,direction,forwardSwing)
  local up=direction.Unit
  -- Keep the same lateral axis through the overhead arc. The old cross product
  -- flipped this axis when the club pointed down, twisting the entire arm inward.
  local right=forwardSwing and (Vector3.xAxis-up*up.X) or up:Cross(Vector3.zAxis)
  if right.Magnitude<.01 then right=Vector3.xAxis end
  right=right.Unit
  local grip=CFrame.fromMatrix(position,right,up,right:Cross(up))
  local handGoal=grip*weapon:Inverse()
  local pre=bones.Bone.CFrame*out.Bone*bones["Bone.001"].CFrame*out["Bone.001"]*bones["Bone.006"].CFrame
  local upper=bones["Bone.007"].CFrame.Position.Magnitude
  local lower=bones["Bone.008"].CFrame.Position.Magnitude
  local delta=handGoal.Position-pre.Position
  local dist=math.clamp(delta.Magnitude,math.abs(upper-lower)+.001,(upper+lower)*.997)
  local dir=delta.Unit
  local pole=forwardSwing and Vector3.new(1,0,-0.7).Unit or Vector3.xAxis
  local bend=pole-dir*dir:Dot(pole)
  if bend.Magnitude<.01 then bend=Vector3.new(0,0,-1) end
  local along=(upper*upper+dist*dist-lower*lower)/(2*dist)
  local elbow=pre.Position+dir*along+bend.Unit*math.sqrt(math.max(0,upper*upper-along*along))
  out["Bone.006"]=fromTo(bones["Bone.007"].CFrame.Position,pre:VectorToObjectSpace(elbow-pre.Position))
  local preElbow=pre*out["Bone.006"]*bones["Bone.007"].CFrame
  local target=pre.Position+dir*dist
  out["Bone.007"]=fromTo(bones["Bone.008"].CFrame.Position,preElbow:VectorToObjectSpace(target-preElbow.Position))
  local preHand=preElbow*out["Bone.007"]*bones["Bone.008"].CFrame
  out["Bone.008"]=preHand.Rotation:Inverse()*handGoal.Rotation
 end
 local function pose(pos,dir,lean,crouch,forwardSwing)
  local out={} for name in bones do out[name]=CFrame.identity end
  out.Bone=CFrame.new(0,crouch or 0,0)
  out["Bone.001"]=CFrame.Angles(lean or 0,0,0)
  out["Bone.002"]=CFrame.Angles(-(lean or 0)*.4,0,0)
  local rest=mesh.CFrame:ToObjectSpace(bones["Bone.003"].WorldCFrame)
  out["Bone.003"]=CFrame.fromAxisAngle(rest:VectorToObjectSpace(Vector3.xAxis),.55)
  rest=mesh.CFrame:ToObjectSpace(bones["Bone.004"].WorldCFrame)
  out["Bone.004"]=CFrame.fromAxisAngle(rest:VectorToObjectSpace(Vector3.xAxis),.7)
  arm(out,pos,dir,forwardSwing)
  return out
 end
 local function sample(sequence,t)
  local keys=sequence:GetKeyframes(); table.sort(keys,function(a,b)return a.Time<b.Time end)
  local low,high=keys[1],keys[#keys]
  for i=1,#keys-1 do if t>=keys[i].Time and t<=keys[i+1].Time then low=keys[i];high=keys[i+1];break end end
  local a,b={},{} for _,x in low:GetDescendants() do if x:IsA("Pose") then a[x.Name]=x.CFrame end end
  for _,x in high:GetDescendants() do if x:IsA("Pose") then b[x.Name]=x.CFrame end end
  local out={} for name in bones do out[name]=(a[name] or CFrame.identity):Lerp(b[name] or CFrame.identity,math.clamp((t-low.Time)/math.max(.001,high.Time-low.Time),0,1)) end return out
 end
 -- Final swing uses ordinary joint rotations, not hand-target IK.
 -- Keep a fixed elbow hinge and modest wrist bend so skinning never corkscrews.
 local function hingePose(pitch,elbow,lean,crouch)
  local out={} for name in bones do out[name]=CFrame.identity end
  out.Bone=CFrame.new(0,crouch or 0,0)
  out["Bone.001"]=CFrame.Angles(lean or 0,0,0)
  out["Bone.002"]=CFrame.Angles(-(lean or 0)*.4,0,0)
  local r=bones["Bone.006"].CFrame.Rotation
  out["Bone.006"]=r:Inverse()*CFrame.Angles(pitch,0,.25)*r
  out["Bone.007"]=CFrame.fromAxisAngle(Vector3.new(-1,0,0),elbow)
  out["Bone.008"]=CFrame.fromAxisAngle(Vector3.new(-1,0,0),-.3)
  -- Left arm stays in a light guard; no mirrored contortion.
  for _,entry in {{"Bone.003",.35},{"Bone.004",.3}} do
   local rest=mesh.CFrame:ToObjectSpace(bones[entry[1]].WorldCFrame)
   out[entry[1]]=CFrame.fromAxisAngle(rest:VectorToObjectSpace(Vector3.xAxis),entry[2])
  end
  return out
 end
 local ready=pose(Vector3.new(1.5,.8,-1.2),Vector3.new(-.1,1,-.2),0,0)
 local wind=pose(Vector3.new(1.5,.9,-1.1),Vector3.new(.15,.85,-.5),.04,-.03)
 local drum=pose(Vector3.new(1.8,.15,-1.5),Vector3.new(-2.5,-.4,.7),-.06,-.06)
 local raised=hingePose(2,.35,0,0)
 local forward=hingePose(1.5,.3,-.04,-.02)
 local down=hingePose(.9,.25,-.08,-.04)
 local smash=hingePose(.15,.2,-.18,-.08)
 local recover=hingePose(.5,.25,-.06,-.02)
 local finish=hingePose(.15,.2,0,0)
 local keys={{0,ready},{.42,wind},{.65,drum},{.77,ready},{1.08,wind},{1.25,drum},{1.4,ready},
  {1.65,sample(p.CombatAnimations.Q,0)},{1.9,sample(p.CombatAnimations.Q,.14)},
  {2.05,sample(p.CombatAnimations.Q,.225)},{2.3,sample(p.CombatAnimations.Q,.4)},
  {2.55,raised},{2.93,raised},{3.00,forward},{3.08,down},{3.15,smash},{3.3,smash},{3.5,recover},{3.7,finish}}
 local sequence=Instance.new("KeyframeSequence"); sequence.Name="F"; sequence.Loop=false
 for _,entry in keys do
  local key=Instance.new("Keyframe"); key.Time=entry[1];key.Parent=sequence
  local root=Instance.new("Pose");root.Name="Mesh";root.Parent=key
  local poses={}
  local function add(name)
   if poses[name] then return poses[name] end
   local b=bones[name]; local x=Instance.new("Pose");x.Name=name;x.CFrame=entry[2][name] or CFrame.identity
   x.EasingStyle=Enum.PoseEasingStyle.Linear; x.Parent=b.Parent:IsA("Bone") and add(b.Parent.Name) or root
   poses[name]=x;return x
  end
  for name in bones do add(name) end
 end
 local old=p.CombatAnimations:FindFirstChild("F")
 if old then
  -- Preserve any hand-edited drum/sweep keyframes outside the final swing.
  for _,k in sequence:GetKeyframes() do if k.Time<2.55 then k:Destroy() end end
  for _,k in old:GetKeyframes() do if k.Time<2.55 then k:Clone().Parent=sequence end end
  local backup=old:Clone(); backup.Name="MidnightAlarmBackup_"..game.HttpService:GenerateGUID(false):sub(1,8); backup.Parent=game.ServerStorage
  old:Destroy()
 end
 sequence.Parent=p.CombatAnimations
 return "Corrected final-swing arm path; earlier strikes preserved; prior F backed up in ServerStorage"
end
