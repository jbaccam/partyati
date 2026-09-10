return function()
 local p=game.ReplicatedStorage.TungPrototype
 local mesh=p.Assets.TungSahur.Mesh;local bones={}
 for _,v in mesh:GetDescendants() do if v:IsA("Bone") then bones[v.Name]=v end end
 local keys=p.CombatAnimations.F:GetKeyframes()
 table.sort(keys,function(a,b)return a.Time<b.Time end)
 local function poses(key)
  local out={} for _,v in key:GetDescendants() do if v:IsA("Pose") then out[v.Name]=v.CFrame end end return out
 end
 local previousTipY=math.huge
 for i=0,120 do
  local time=2.93+.22*i/120
  local a,b=keys[1],keys[#keys]
  for n=1,#keys-1 do if time>=keys[n].Time and time<=keys[n+1].Time then a=keys[n];b=keys[n+1];break end end
  local aa,bb=poses(a),poses(b);local frames={}
  local function frame(name)
   if frames[name] then return frames[name] end
   local bone=bones[name]
   local parent=bone.Parent:IsA("Bone") and frame(bone.Parent.Name) or CFrame.identity
   frames[name]=parent*bone.CFrame*aa[name]:Lerp(bb[name],math.clamp((time-a.Time)/(b.Time-a.Time),0,1))
   return frames[name]
  end
  local elbow=frame("Bone.007");local hand=frame("Bone.008")
  local bat=hand*bones["Bone.008"].WeaponGrip.CFrame*p.Assets.WoodenBat.BatGrip.CFrame:Inverse()
  local tip=bat:PointToWorldSpace(p.Assets.WoodenBat:GetAttribute("TrailTip"))
  assert(elbow.Position.Z<0 and hand.Position.Z<0 and tip.Z<0,"final swing crossed behind torso")
  assert(tip.Y<=previousTipY+.025,"club reversed upward during downswing")
  assert(hand.Position.X>1.2,"hand cut inward through torso")
  previousTipY=tip.Y
 end
 assert(previousTipY< -2.5,"club did not finish at ground level")
 -- Validate the skinned arm itself, not just the endpoint path.
 local fixture=Instance.new("Model");fixture:SetAttribute("CombatAction","F")
 local visual=p.Assets.TungSahur:Clone();visual.Parent=fixture
 local previewBones={} for _,v in visual.Mesh:GetDescendants() do if v:IsA("Bone") then previewBones[v.Name]=v end end
 local ok,err=pcall(function()
  for _,key in keys do if key.Time>=2.55 then
   local transforms=poses(key)
   local axis,angle=transforms["Bone.007"]:ToAxisAngle()
   assert(axis:Dot(Vector3.new(-1,0,0))>.999 and angle<=.36,"elbow twist or excessive fold")
   assert(transforms["Bone.008"]==CFrame.fromAxisAngle(Vector3.new(-1,0,0),-.3),"wrist corkscrew")
   for name,bone in previewBones do bone.Transform=transforms[name] end
   require(p.ArmClearance).apply({bones=previewBones,visual=visual,humanoid={Health=115}},require(p.RigProfiles).tung_sahur)
   for _,name in {"Bone.006","Bone.007","Bone.008"} do
    assert(previewBones[name].Transform==transforms[name],"runtime clearance rewrote final arm")
   end
  end end
 end)
 fixture:Destroy();assert(ok,err)
 return "PASS: forward/downward path, shallow single-axis elbow, fixed wrist, no runtime arm correction"
end
