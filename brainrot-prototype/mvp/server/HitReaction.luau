-- A short horizontal constraint prevents Humanoid braking from swallowing hits.
-- Gravity stays enabled; steering/defensive abilities return promptly, not a ragdoll lock.
local Reaction={}
function Reaction.Stop(s)
 local r=s.hitReaction;if not r then return end
 r.velocity:Destroy();r.attachment:Destroy();s.hitReaction=nil
end
function Reaction.Start(s,velocity,now,duration,stagger)
 Reaction.Stop(s)
 if s.root.Anchored or s.humanoid.Health<=0 or duration<=0 then return end
 local a=Instance.new("Attachment");a.Name="HitCarryAttachment";a.Parent=s.root
 local v=Instance.new("LinearVelocity");v.Name="HitCarryVelocity";v.Attachment0=a
 v.RelativeTo=Enum.ActuatorRelativeTo.World;v.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
 v.PrimaryTangentAxis=Vector3.xAxis;v.SecondaryTangentAxis=Vector3.zAxis
 v.ForceLimitsEnabled=true;v.ForceLimitMode=Enum.ForceLimitMode.PerAxis
 local force=math.clamp(s.root.AssemblyMass*2500,20000,2000000);v.MaxPlanarAxesForce=Vector2.new(force,force)
 v.PlaneVelocity=Vector2.new(velocity.X,velocity.Z);v.Parent=s.root
 s.hitReaction={velocity=v,attachment=a,untilAt=now+duration,from=s.root.Position,horizontal=Vector3.new(velocity.X,0,velocity.Z)}
 -- Repeated attacks cannot keep extending a long stagger indefinitely.
 s.staggerChain=now-(s.lastStaggerHit or -math.huge)<.7 and (s.staggerChain or 0)+1 or 1
 s.lastStaggerHit=now
 local seconds=s.staggerChain<=2 and stagger or .04
 s.character:SetAttribute("HitStaggerUntil",now+seconds)
 if s.action and s.action.key=="M1" and s.action.stage==0 then
  s.action=nil;s.buffer=nil;s.busyUntil=now+seconds
  s.character:SetAttribute("CombatAction","");s.character:SetAttribute("CombatBusyUntil",s.busyUntil)
 end
 s.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
 s.root.AssemblyLinearVelocity=velocity
end
function Reaction.Step(service,s,now,dt)
 local r=s.hitReaction;if not r then return end
 if now>=r.untilAt or not s.character.Parent or not s.root.Parent or s.root.Anchored or s.humanoid.Health<=0 then Reaction.Stop(s);return end
 local travel=s.root.Position-r.from
 local ahead=r.horizontal*math.clamp(dt,.016,.06)
 if ahead.Magnitude>.001 then ahead+=ahead.Unit*1.1 end
 local params=service:RayParams()
 local crossed=travel.Magnitude>.001 and service.world:Raycast(r.from,travel,params)
 local hit=service.world:Raycast(s.root.Position,ahead,params)
 if (hit and hit.Normal.Y<.6) or (crossed and crossed.Normal.Y<.6) then
  Reaction.Stop(s);s.root.AssemblyLinearVelocity=Vector3.yAxis*s.root.AssemblyLinearVelocity.Y;return
 end
 r.from=s.root.Position
end
return Reaction
