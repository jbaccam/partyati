-- Bounded server-owned ability motion. Plane constraints leave gravity untouched;
-- vector constraints are reserved for timed flight/glide. Never anchors a fighter.
local Rules=require(game.ReplicatedStorage.TungPrototype.CombatRules)
local Motion={}
local function finite(n) return typeof(n)=="number" and n==n and math.abs(n)<math.huge end
function Motion.Stop(service,s)
 local d=s.drive;if not d then return end
 s.drive=nil
 d.velocity:Destroy();d.attachment:Destroy()
 if s.humanoid.Parent then s.humanoid.AutoRotate=d.autoRotate end
 if s.character.Parent then
  s.character:SetAttribute("AbilityMotionMode",nil);s.character:SetAttribute("AbilityMotionUntil",0)
 end
 -- Retain current momentum, then return ordinary movement control.
 service:Release(s)
end
function Motion.Start(service,s,aim,speed,duration,now,options)
 options=options or {};aim=Rules.aim(aim)
 if not aim or not finite(speed) or speed<0 or speed>90 or not finite(duration) or duration<=0 or duration>2 then return false end
 if not finite(now) or s.root.Anchored or not s.active or s.humanoid.Health<=0 then return false end
 if options.vertical~=nil and (not finite(options.vertical) or math.abs(options.vertical)>50) then return false end
 if options.lift~=nil and (not finite(options.lift) or math.abs(options.lift)>100) then return false end
 Motion.Stop(service,s)
 local attachment=Instance.new("Attachment");attachment.Name="AbilityDriveAttachment";attachment.Parent=s.root
 local velocity=Instance.new("LinearVelocity");velocity.Name="AbilityDriveVelocity";velocity.Attachment0=attachment
 velocity.RelativeTo=Enum.ActuatorRelativeTo.World;velocity.ForceLimitsEnabled=true
 velocity.ForceLimitMode=Enum.ForceLimitMode.PerAxis
 local force=math.clamp(s.root.AssemblyMass*2500,20000,2000000)
 if options.vertical~=nil then
  velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
  velocity.MaxAxesForce=Vector3.new(force,force,force)
  velocity.VectorVelocity=aim*speed+Vector3.yAxis*(options.lift or options.vertical)
 else
  velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
  velocity.PrimaryTangentAxis=Vector3.xAxis;velocity.SecondaryTangentAxis=Vector3.zAxis
  velocity.MaxPlanarAxesForce=Vector2.new(force,force)
  velocity.PlaneVelocity=Vector2.new(aim.X*speed,aim.Z*speed)
 end
 local mode=options.mode or "Dash"
 local d={velocity=velocity,attachment=attachment,at=now,untilAt=now+duration,aim=aim,wanted=aim,
  speed=speed,vertical=options.vertical,lift=options.lift,mode=mode,autoRotate=s.humanoid.AutoRotate,
  lastSteer=-math.huge,lastPosition=s.root.Position}
 s.drive=d;s.humanoid.AutoRotate=false
 pcall(function() s.root:SetNetworkOwner(nil) end);s.owned=now+duration+.1
 s.root.CFrame=CFrame.lookAt(s.root.Position,s.root.Position+aim)
 if options.lift~=nil then s.humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end
 s.root.AssemblyLinearVelocity=aim*speed+Vector3.yAxis*(options.lift or s.root.AssemblyLinearVelocity.Y)
 velocity.Parent=s.root
 s.character:SetAttribute("AbilityMotionMode",mode)
 s.character:SetAttribute("AbilityMotionAt",now);s.character:SetAttribute("AbilityMotionUntil",now+duration)
 service.effect("MoveBurst",s.root.Position,{source=s.character,fighterId=s.fighter.Id,mode=mode,duration=duration,aim=aim,at=now})
 return true
end
function Motion.Steer(service,s,aim,now)
 local d=s and s.drive
 if not d or (d.mode~="Flight" and d.mode~="Glide") or now-d.lastSteer<.08 then return false end
 aim=Rules.aim(aim);if not aim then return false end
 d.lastSteer=now;d.wanted=aim;return true
end
function Motion.Step(service,s,now,dt)
 local d=s.drive;if not d then return end
 if now>=d.untilAt or not s.active or not s.character.Parent or s.humanoid.Health<=0 or s.root.Anchored
  or s.character:GetAttribute("CombatDisabled")==true or (s.character:GetAttribute("StunnedUntil") or 0)>now
  or s.humanoid.Sit or s.humanoid.PlatformStand then Motion.Stop(service,s);return end
 dt=math.clamp(dt,0,.1)
 if d.mode=="Flight" or d.mode=="Glide" then
  local dot=math.clamp(d.aim:Dot(d.wanted),-1,1);local cross=d.aim:Cross(d.wanted).Y
  local angle=math.atan2(cross,dot)
  d.aim=CFrame.fromAxisAngle(Vector3.yAxis,math.clamp(angle,-1.75*dt,1.75*dt)):VectorToWorldSpace(d.aim)
 end
 local speed=d.speed
 if d.mode=="Flight" and s.action and s.action.key=="Q" then speed*=.65 end
 local vertical=d.vertical
 if vertical~=nil and d.lift and now-d.at<.12 then vertical=d.lift end
 local desired=d.aim*speed+Vector3.yAxis*(vertical or s.root.AssemblyLinearVelocity.Y)
 -- Three forward feelers plus swept previous travel stop at solid cover.
 local params=service:RayParams();local advance=d.aim*(speed*math.max(dt,1/30)+1.6)
 local right=d.aim:Cross(Vector3.yAxis);local blocked=false
 for _,side in {-1,0,1} do
  local hit=service.world:Raycast(s.root.Position+right*side,advance,params)
  if hit and hit.Normal.Y<.65 then blocked=true;break end
 end
 local travel=s.root.Position-d.lastPosition
 if not blocked and travel.Magnitude>.05 then
  local hit=service.world:Raycast(d.lastPosition,travel,params)
  blocked=hit~=nil and hit.Normal.Y<.65
 end
 if not blocked and vertical and vertical>0 then
  blocked=service.world:Raycast(s.root.Position,Vector3.yAxis*(vertical*dt+2),params)~=nil
 end
 if blocked then
  Motion.Stop(service,s);s.root.AssemblyLinearVelocity=Vector3.yAxis*math.min(0,s.root.AssemblyLinearVelocity.Y)
  s.action=nil;s.busyUntil=now;s.character:SetAttribute("CombatAction","");s.character:SetAttribute("CombatBusyUntil",now)
  s.character:SetAttribute("AbilityMotionBlockedAt",now);return
 end
 d.lastPosition=s.root.Position
 if vertical~=nil then d.velocity.VectorVelocity=desired else d.velocity.PlaneVelocity=Vector2.new(desired.X,desired.Z) end
 s.root.CFrame=CFrame.lookAt(s.root.Position,s.root.Position+d.aim)
end
return Motion
