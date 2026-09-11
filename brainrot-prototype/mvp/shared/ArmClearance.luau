-- Reusable arm constraint, applied after clip and locomotion blending.
-- Each fighter supplies bone names and side clearances in its chest's local space.
local Clearance={}
local function fromTo(a,b)
 a=a.Unit; b=b.Unit
 local dot=math.clamp(a:Dot(b),-1,1)
 if dot>0.99999 then return CFrame.identity end
 local axis=a:Cross(b)
 if axis.Magnitude<1e-5 then axis=a:Cross(Vector3.xAxis); if axis.Magnitude<1e-5 then axis=a:Cross(Vector3.zAxis) end end
 return CFrame.fromAxisAngle(axis.Unit,math.acos(dot))
end
local function basis(axis,normal)
 return CFrame.fromMatrix(Vector3.zero,axis:Cross(normal).Unit,axis.Unit,normal.Unit)
end
local function constrain(pose,names,side,profile)
 local upper,fore,hand=pose.bones[names[1]],pose.bones[names[2]],pose.bones[names[3]]
 if not upper or not fore or not hand or upper.Parent~=pose.bones[profile.BodyBone] then return end
 local pre=upper.CFrame
 local rawUpper=pre*upper.Transform
 local rawFore=rawUpper*fore.CFrame*fore.Transform
 local rawHand=rawFore*hand.CFrame*hand.Transform
 local shoulder=pre.Position
 local oldElbow=rawFore.Position
 local target=rawHand.Position
 -- Both forearm endpoints stay on the same outside plane, so the whole
 -- forearm segment stays clear, including when the torso turns or bends.
 if side*target.X>=profile.WristSide and side*oldElbow.X>=profile.ElbowSide then return end
 local a=fore.CFrame.Position.Magnitude; local b=hand.CFrame.Position.Magnitude
 local reach=(a+b)*profile.MaxReachRatio
 local x=math.max(profile.WristSide,side*target.X)
 x=math.min(x,side*shoulder.X+reach*.85)
 target=Vector3.new(side*x,target.Y,target.Z)
 local delta=target-shoulder
 local yz=Vector3.new(0,delta.Y,delta.Z)
 local yzLimit=math.sqrt(math.max(.001,reach*reach-delta.X*delta.X))
 if yz.Magnitude>yzLimit then target=Vector3.new(target.X,shoulder.Y,shoulder.Z)+yz.Unit*yzLimit end
 local outward=Vector3.new(side,0,0)
 local center,normal,u,v,radius,required
 for _=1,6 do
  delta=target-shoulder
  local distance=math.max(.01,delta.Magnitude); normal=delta/distance
  local along=(a*a+distance*distance-b*b)/(2*distance)
  center=shoulder+normal*along
  radius=math.sqrt(math.max(.0001,a*a-along*along))
  u=(outward-normal*outward:Dot(normal)).Unit
  v=normal:Cross(u).Unit
  required=(profile.ElbowSide-side*center.X)/math.max(.0001,radius*side*u.X)
  if required<=1 then break end
  -- A slightly softer extension gives the elbow room to stay outside.
  target=Vector3.new(target.X,shoulder.Y+(target.Y-shoulder.Y)*.94,shoulder.Z+(target.Z-shoulder.Z)*.94)
 end
 local desired=oldElbow-center
 local angle=math.atan2(desired:Dot(v),desired:Dot(u))
 local limit=math.acos(math.clamp(required,-1,1))
 angle=math.clamp(angle,-limit,limit)
 local elbow=center+radius*(u*math.cos(angle)+v*math.sin(angle))
 -- Preserve the anatomical elbow hinge; do not add a second wrist bend.
 local restAxis=fore.CFrame.Position.Unit
 -- The slight sideways cant in the bind pose is not the elbow hinge.
 local hinge=Vector3.new(table.unpack(profile.HingeAxis))
 local restNormal=(hinge-restAxis*hinge:Dot(restAxis)).Unit
 local desiredAxis=pre:VectorToObjectSpace(elbow-shoulder).Unit
 local desiredNormal=pre:VectorToObjectSpace((elbow-shoulder):Cross(target-elbow))
 if desiredNormal.Magnitude<1e-5 then return end
 upper.Transform=basis(desiredAxis,desiredNormal.Unit)*basis(restAxis,restNormal.Unit):Inverse()
 local forePre=pre*upper.Transform*fore.CFrame
 fore.Transform=fromTo(hand.CFrame.Position,forePre:VectorToObjectSpace(target-elbow))
 hand.Transform=CFrame.identity
end
function Clearance.apply(pose,profile)
 if not profile or pose.humanoid.Health<=0 then return end
 -- Preserve the authored idle/run arms; constrain combat and its fade-out only.
 local character=pose.visual.Parent
 if not character then return end
 local action=character:GetAttribute("CombatAction")
 if (not action or action=="") and not pose._combatOutput then return end
 constrain(pose,profile.Left,-1,profile)
 constrain(pose,profile.Right,1,profile)
end
return Clearance
