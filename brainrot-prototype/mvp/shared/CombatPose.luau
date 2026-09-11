-- Full-body Blender-authored clips, stored as editable Studio KeyframeSequences.
local library=script.Parent:WaitForChild("CombatAnimations")
local Playback={}
local cache={}
local function getClip(name)
 if cache[name] then return cache[name] end
 local sequence=library:FindFirstChild(name); if not sequence then return nil end
 local keys=sequence:GetKeyframes(); table.sort(keys,function(a,b) return a.Time<b.Time end)
 local frames={}
 for _,key in keys do
  local transforms={}
  for _,p in key:GetDescendants() do if p:IsA("Pose") and p.Name~="Mesh" then transforms[p.Name]=p.CFrame end end
  table.insert(frames,{time=key.Time,transforms=transforms})
 end
 if #frames<2 then return nil end
 cache[name]={frames=frames,duration=frames[#frames].time}
 return cache[name]
end
local function sample(clip,t)
 local frames=clip.frames
 local low,high=1,#frames
 while low+1<high do
  local mid=math.floor((low+high)/2)
  if frames[mid].time<=t then low=mid else high=mid end
 end
 local a,b=frames[low],frames[high]
 local alpha=math.clamp((t-a.time)/math.max(0.001,b.time-a.time),0,1)
 local result={}
 for name,cf in a.transforms do result[name]=cf:Lerp(b.transforms[name] or cf,alpha) end
 return result
end
function Playback.apply(pose,now,dt)
 dt=dt or 1/60
 local character=pose.visual.Parent
 if not character or pose.humanoid.Health<=0 then pose._combatOutput=nil; return end
 local action=character:GetAttribute("CombatAction")
 local key=action=="M1" and ("M1"..tostring(character:GetAttribute("CombatCombo") or 1)) or action
 local at=character:GetAttribute("CombatActionAt") or 0
 -- Presentation follows observed contact, not the later server damage confirmation.
 -- Never change replicated action attributes, physics, cooldowns, or damage here.
 if action=="E" then
  if pose._slamCastAt~=at then
   pose._slamCastAt=at; pose._slamSeenAir=false; pose._slamLandingAt=nil
  end
  local grounded=pose.humanoid.FloorMaterial~=Enum.Material.Air
  if not grounded then pose._slamSeenAir=true end
  if grounded and pose._slamSeenAir and not pose._slamLandingAt and now-at>=0.1 then
   pose._slamLandingAt=now
  end
 elseif action~="SlamLand" then
  pose._slamCastAt=nil; pose._slamSeenAir=nil; pose._slamLandingAt=nil
 end
 if (action=="E" or action=="SlamLand") and pose._slamLandingAt then
  -- Keep the original local landing time when confirmation arrives: no second slam.
  key="SlamLand"; at=pose._slamLandingAt
 end
 local clip=key and getClip(key)
 if not clip or now-at>clip.duration+0.15 then
  if pose._combatOutput then
   pose._combatFade=(pose._combatFade or 1)*math.exp(-35*dt)
   for name,cf in pose._combatOutput do
    local bone=pose.bones[name]
    if bone then bone.Transform=bone.Transform:Lerp(cf,pose._combatFade) end
   end
   if pose._combatFade<0.01 then pose._combatOutput=nil; pose._combatKey=nil end
  end
  return
 end
 local id=key..tostring(at)
 if pose._combatKey~=id then
  pose._combatKey=id; pose._combatTransition=0
  pose._combatFrom=pose._combatOutput or {}
  if not pose._combatOutput then
   for name,bone in pose.bones do pose._combatFrom[name]=bone.Transform end
  end
 end
 pose._combatTransition=math.min(1,(pose._combatTransition or 0)+dt/0.045)
 local output=sample(clip,math.clamp(now-at,0,clip.duration))
 local moveSpeed=math.max(pose.speed,pose.humanoid.MoveDirection.Magnitude*pose.humanoid.WalkSpeed)
 local moving=math.clamp((moveSpeed-0.5)/5,0,1)*(1-(pose.air or 0))
 pose._combatMove=(pose._combatMove or moving)+(moving-(pose._combatMove or moving))*(1-math.exp(-22*dt))
 for name,cf in output do
  local bone=pose.bones[name]
  if bone then
   cf=(pose._combatFrom[name] or cf):Lerp(cf,pose._combatTransition)
   -- Locomotion owns the pelvis and legs while running, through every ability.
   local leg=name=="Bone.009" or name=="Bone.010" or name=="Bone.011" or name=="Bone.012" or name=="Bone.013" or name=="Bone.014"
   if leg or name=="Bone" then cf=cf:Lerp(bone.Transform,pose._combatMove) end
   bone.Transform=cf; output[name]=cf
  end
 end
 pose._combatOutput=output; pose._combatFade=1; pose.state=key
end
function Playback.react(pose,now)
 local character=pose.visual.Parent
 local at=character and character:GetAttribute("CombatHitAt")
 if not at then return end
 local t=now-at
 if t<0 or t>0.18 or pose.humanoid.Health<=0 then return end
 local direction=character:GetAttribute("CombatHitDirection")
 if typeof(direction)~="Vector3" then return end
 local localDirection=pose.root.CFrame:VectorToObjectSpace(direction)
 local amount=math.sin(t/0.18*math.pi)*(1-t/0.18)
 pose.bones.Bone.Transform*=CFrame.new(localDirection.X*0.12*amount,0,localDirection.Z*0.1*amount)
  *CFrame.Angles(localDirection.Z*0.22*amount,0,-localDirection.X*0.22*amount)
end
return Playback
