-- Server-only Tung combat. Input intent enters Request; all outcomes are computed here.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local package=ReplicatedStorage:WaitForChild("TungPrototype")
local Rules=require(package.CombatRules)
local Fighter=require(package.FighterDefinitions).ById.tung_sahur
local Service={}; Service.__index=Service
local UP=Vector3.yAxis
local function living(s)
 return s.character.Parent and s.root.Parent and s.humanoid.Health>0
end
local function clockAttributes(s)
 s.character:SetAttribute("BeatStacks",s.stacks)
 s.character:SetAttribute("UltimateReady",s.core)
 s.character:SetAttribute("RecoveryUsed",s.recoveryUsed)
end
function Service.new(world,effect,motion)
 return setmetatable({world=world,records={},effect=effect or function() end,motion=motion},Service)
end
function Service:Register(character,active)
 if self.records[character] then self:SetActive(character,active); return self.records[character] end
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 local root=character:FindFirstChild("HumanoidRootPart")
 if not humanoid or not root then return nil end
 local s={character=character,humanoid=humanoid,root=root,active=false,
  cooldowns={},combo=0,lastM1=-math.huge,stacks=0,lastBeat=0,core=false,
  recoveryUsed=false,airJumps=0,busyUntil=0,lastInput=-math.huge,action=nil,
  saved={MaxHealth=humanoid.MaxHealth,WalkSpeed=humanoid.WalkSpeed,UseJumpPower=humanoid.UseJumpPower,JumpPower=humanoid.JumpPower,AutoRotate=humanoid.AutoRotate}}
 self.records[character]=s
 self:SetActive(character,active)
 return s
end
function Service:SetActive(character,active)
 local s=self.records[character]; if not s or s.active==active then return end
 s.active=active; s.sprinting=false; character:SetAttribute("Sprinting",false); s.action=nil; s.buffer=nil; s.busyUntil=0; s.stacks=0; s.humanoid.AutoRotate=s.saved.AutoRotate
 self:Release(s)
 if active then
  local fraction=s.humanoid.Health/math.max(s.humanoid.MaxHealth,1)
  s.humanoid.MaxHealth=Fighter.Stats.MaxHealth
  s.humanoid.Health=fraction*Fighter.Stats.MaxHealth
  s.humanoid.UseJumpPower=true; s.humanoid.JumpPower=Fighter.Stats.JumpVelocity
  s.humanoid.WalkSpeed=Fighter.Stats.WalkSpeed
  character:SetAttribute("CombatWeight",Fighter.Stats.Weight)
 else
  local fraction=s.humanoid.Health/math.max(s.humanoid.MaxHealth,1)
  for property,value in s.saved do s.humanoid[property]=value end
  s.humanoid.Health=fraction*s.saved.MaxHealth
  character:SetAttribute("CombatWeight",nil)
 end
 character:SetAttribute("CombatAction","")
 clockAttributes(s)
end
function Service:Speed(s)
 return (s.sprinting and 28 or Fighter.Stats.WalkSpeed)*(1+s.stacks*0.04)
end
function Service:SetSprint(character,enabled,now)
 local s=self.records[character]
 if typeof(enabled)~="boolean" or not s or not s.active or not living(s) then return false end
 if character:GetAttribute("TungSahurActive")~=true then return false end
 s.sprinting=enabled
 character:SetAttribute("Sprinting",enabled)
 s.humanoid.WalkSpeed=self:Speed(s)
 return true
end
function Service:Release(s)
 if s.owned then
  s.owned=nil
  if s.root.Parent and not s.root.Anchored then pcall(function() s.root:SetNetworkOwnershipAuto() end) end
 end
end
function Service:Velocity(s,velocity,now,duration)
 if s.root.Anchored then return end
 local ok=pcall(function() s.root:SetNetworkOwner(nil) end)
 if ok then s.owned=now+(duration or 0.4) end
 s.root.AssemblyLinearVelocity=velocity
end
-- Self-abilities change only vertical speed, once, without taking network ownership.
-- Player motion is delivered to the existing owner; NPCs are applied locally.
function Service:Lift(s,y,now)
 if s.root.Anchored then return end
 if self.motion and self.motion(s.character,y,now) then return end
 local v=s.root.AssemblyLinearVelocity
 s.root.AssemblyLinearVelocity=Vector3.new(v.X,y,v.Z)
end
function Service:Remove(character)
 local s=self.records[character]; if not s then return end
 self:SetActive(character,false); self:Release(s)
 for _,attr in {"BeatStacks","UltimateReady","RecoveryUsed","CombatAction","CombatActionAt","CombatCombo","CombatBusyUntil","TungInvulnerableUntil","TungAirJumpSerial","Sprinting"} do
  character:SetAttribute(attr,nil)
 end
 self.records[character]=nil
end
function Service:Destroy()
 local list={}; for character in self.records do table.insert(list,character) end
 for _,character in list do self:Remove(character) end
end
function Service:RayParams()
 local p=RaycastParams.new()
 local ignore={}
 for character in self.records do table.insert(ignore,character) end
 local fx=self.world:FindFirstChild("TungCombatEffects"); if fx then table.insert(ignore,fx) end
 p.FilterType=Enum.RaycastFilterType.Exclude
 p.FilterDescendantsInstances=ignore
 p.RespectCanCollide=true
 return p
end
function Service:Ground(s)
 local distance=s.humanoid.HipHeight+s.root.Size.Y/2
 if s.humanoid.RigType==Enum.HumanoidRigType.R6 then
  local leg=s.character:FindFirstChild("Left Leg")
  distance+=leg and leg.Size.Y or 2
 end
 local hit=self.world:Raycast(s.root.Position,-UP*(distance+0.45),self:RayParams())
 return hit and hit.Normal.Y>0.45 and s.root.AssemblyLinearVelocity.Y<=4 and hit or nil
end
function Service:Visible(from,to)
 local direction=to-from
 if direction.Magnitude<0.01 then return true end
 return self.world:Raycast(from,direction,self:RayParams())==nil
end
function Service:Beat(s,now)
 s.stacks,s.lastBeat=Rules.decay(s.stacks,s.lastBeat,now)
 s.stacks=math.min(3,s.stacks+1); s.lastBeat=now
 s.humanoid.WalkSpeed=self:Speed(s)
 clockAttributes(s)
end
function Service:Hit(s,target,baseDamage,knockback,direction,now)
 if target==s or not living(target) or target.character:GetAttribute("CombatInvulnerable")==true then return false end
 if (target.character:GetAttribute("TungInvulnerableUntil") or 0)>now
  or target.character:FindFirstChildOfClass("ForceField") then return false end
 local attackerPlayer=game.Players:GetPlayerFromCharacter(s.character)
 local targetPlayer=game.Players:GetPlayerFromCharacter(target.character)
 if attackerPlayer and targetPlayer and not attackerPlayer.Neutral and not targetPlayer.Neutral
  and attackerPlayer.Team==targetPlayer.Team then return false end
 local damage=Rules.damage(baseDamage,s.stacks)
 local before=target.humanoid.Health
 target.humanoid:TakeDamage(damage)
 if target.humanoid.Health>=before then return false end
 local weight=target.character:GetAttribute("CombatWeight") or 1
 local launch=Rules.knockback(knockback,target.humanoid.Health,target.humanoid.MaxHealth,weight)
 if direction.Magnitude>0.001 then self:Velocity(target,direction.Unit*launch,now,0.35) end
 target.character:SetAttribute("LastCombatAt",now); s.character:SetAttribute("LastCombatAt",now)
 target.character:SetAttribute("CombatHitAt",now)
 target.character:SetAttribute("CombatHitDirection",direction)
 self.effect("Hit",target.root.Position,{damage=before-target.humanoid.Health,source=s.character,target=target.character})
 return true
end
function Service:Area(s,center,radius,damage,kb,now,options)
 options=options or {}
 local hitAny=false
 for _,target in self.records do
  if target==s or not living(target) or (options.seen and options.seen[target]) then continue end
  local delta=target.root.Position-center
  if not Rules.capsuleInSphere(center,radius,target.root.Position,2,3) then continue end
  if options.height and math.abs(delta.Y)>options.height then continue end
  local flat=Vector3.new(delta.X,0,delta.Z)
  if options.aim and flat.Magnitude>0.01 and flat.Unit:Dot(options.aim)<(options.cone or 0) then continue end
  if not self:Visible(options.sight or center,target.root.Position) then continue end
  local base,force=damage,kb
  if options.sweet and flat.Magnitude>=options.sweet then base,force=13,46 end
  local dir=flat.Magnitude>0.01 and flat.Unit or (options.aim or s.root.CFrame.LookVector)
  if options.pull then dir=-dir+UP*0.12 else dir=dir+UP*(options.up or 0.35) end
  if self:Hit(s,target,base,force,dir,now) then
   hitAny=true; if options.seen then options.seen[target]=true end
  end
 end
 if hitAny and (not options.beatOnce or not options.beatOnce.gained) then
  self:Beat(s,now)
  if options.beatOnce then options.beatOnce.gained=true end
 end
end
function Service:GrantCore(character)
 local s=self.records[character]
 if not s or not s.active or not living(s) or s.core then return false end
 s.core=true; clockAttributes(s)
 self.effect("Core",s.root.Position,{source=character})
 return true
end
function Service:Request(character,key,aim,now)
 local s=self.records[character]
 if not s or not s.active or not living(s) or character:GetAttribute("TungSahurActive")~=true then return false end
 if typeof(key)~="string" or not ({M1=true,Q=true,E=true,R=true,F=true,Jump=true})[key] then return false end
 aim=Rules.aim(aim); if not aim then return false end
 if character:GetAttribute("CombatDisabled")==true or self.world:GetAttribute("CombatEnabled")==false then return false end
 local phase=self.world:GetAttribute("CombatPhase")
 if phase and phase~="Active" and phase~="Practice" then return false end
 local hstate=s.humanoid:GetState()
 if s.humanoid.Sit or s.humanoid.PlatformStand or hstate==Enum.HumanoidStateType.Swimming
  or hstate==Enum.HumanoidStateType.Climbing then return false end
 if now-s.lastInput<0.07 then return false end
 s.lastInput=now
 if now<(character:GetAttribute("StunnedUntil") or 0) then return false end
 if key~="Jump" and now<s.busyUntil then
  local cancel=s.action and ((s.action.key=="M1" and (key=="Q" or key=="E" or key=="R"))
   or (s.action.key=="R" and key=="E")) and now-s.action.at>=0.18
   and now>=(s.cooldowns[key] or 0) and (key~="R" or not s.recoveryUsed)
  if cancel then
   s.action=nil; s.busyUntil=now
  elseif key~="Jump" and s.busyUntil-now<=0.16 and (s.cooldowns[key] or 0)<=s.busyUntil then
   s.buffer={key=key,aim=aim,expires=now+0.23}
   return true
  else return false end
 end
 if now<(s.cooldowns[key] or 0) then return false end
 s.stacks,s.lastBeat=Rules.decay(s.stacks,s.lastBeat,now)
 if key=="Jump" then
  if self:Ground(s) or s.airJumps>=Fighter.Stats.AirJumps then return false end
  s.airJumps+=1
  self:Lift(s,Fighter.Stats.JumpVelocity,now)
  character:SetAttribute("TungAirJumpSerial",(character:GetAttribute("TungAirJumpSerial") or 0)+1)
  self.effect("Jump",s.root.Position,{source=character})
  return true
 end
 if key=="R" and s.recoveryUsed then return false end
 if key=="F" and not s.core then return false end
 -- Starting an attack breaks only this fighter's respawn protection.
 character:SetAttribute("TungInvulnerableUntil",0)
 local shield=character:FindFirstChildOfClass("ForceField")
 if shield then shield:Destroy() end
 local duration=0.5
 if key=="M1" then
  s.combo=Rules.combo(s.combo,s.lastM1,now); s.lastM1=now
  duration=s.combo==3 and 0.4 or 0.28
  s.cooldowns.M1=now+duration
 elseif key=="F" then duration=Fighter.Ultimate.Duration; s.core=false
 else
  duration=key=="E" and 2.5 or (key=="R" and 0.65 or 0.52)
  s.cooldowns[key]=now+Fighter.Abilities[key].Cooldown
 end
 s.busyUntil=now+duration
 -- Movement and facing remain owned by the normal character controller.
 s.action={key=key,at=now,aim=aim,seen={},stage=0,lastPosition=s.root.Position,peakY=s.root.Position.Y}
 character:SetAttribute("CombatAction",key)
 character:SetAttribute("CombatActionAt",now)
 character:SetAttribute("CombatCombo",s.combo)
 character:SetAttribute("CombatBusyUntil",s.busyUntil)
 character:SetAttribute("Cooldown"..key,s.cooldowns[key] or now+duration)
 clockAttributes(s)
 if key=="R" then
  s.recoveryUsed=true; s.resetAfter=now+0.3
  self:Lift(s,74,now)
 elseif key=="E" then
  if self:Ground(s) then s.action.lifted=true; self:Lift(s,58,now) end
  s.resetAfter=now+0.3
 end
 self.effect("Cast",s.root.Position,{source=character,key=key,aim=aim,combo=s.combo,duration=duration})
 clockAttributes(s)
 return true
end
function Service:Advance(s,now,dt)
 local a=s.action; if not a then return end
 local elapsed=now-a.at; local key=a.key; local p=s.root.Position
 if key=="M1" and a.stage==0 and elapsed>=(s.combo==3 and 0.135 or 0.105) then
  a.stage=1
  self:Area(s,p,Fighter.Basic.Reach-2,Fighter.Basic.Hits[s.combo],s.combo==3 and Fighter.Basic.FinalKnockback or 9,now,
   {aim=a.aim,cone=0.15,up=s.combo==3 and 1.1 or 0.2,seen=a.seen})
 elseif key=="Q" and a.stage==0 and elapsed>=0.225 then
  a.stage=1
  self:Area(s,p,Fighter.Abilities.Q.Range-2,10,38,now,{aim=a.aim,cone=-0.2,sweet=7*2/3,seen=a.seen})
  self.effect("Swing",p,{source=s.character,aim=a.aim})
 elseif key=="R" and elapsed<=0.7 then
  local travel=p-a.lastPosition
  local count=math.clamp(math.ceil(travel.Magnitude/2),1,8)
  for i=1,count do
   local point=a.lastPosition:Lerp(p,i/count)
   self:Area(s,point,2.2,7,28,now,{seen=a.seen,beatOnce=a,up=0.65})
  end
  a.lastPosition=p
 elseif key=="E" then
  a.peakY=math.max(a.peakY,p.Y)
  -- Drive down before the hop reaches its apex.
  if elapsed>=(a.lifted and 0.16 or 0.08) and a.stage==0 then
   a.stage=1
   self:Lift(s,-48,now)
  end
  if elapsed>=0.25 and a.stage==1 then
   local ground=self:Ground(s)
   -- Sweep between samples so a fast descent cannot skip a thin platform.
   if not ground and a.lastPosition.Y>p.Y then
    local hit=self.world:Raycast(a.lastPosition,p-a.lastPosition-UP*3,self:RayParams())
    if hit and hit.Normal.Y>0.45 then ground=hit end
   end
   if ground then
    a.stage=2
    local impact=ground.Position
    local clearance=s.humanoid.HipHeight+s.root.Size.Y/2
    if s.humanoid.RigType==Enum.HumanoidRigType.R6 then local leg=s.character:FindFirstChild("Left Leg"); clearance+=leg and leg.Size.Y or 2 end
    local drop=math.max(0,a.peakY-impact.Y-clearance)
    local damage=Rules.slamDamage(drop)
    s.character:SetAttribute("LastSlamHeight",drop); s.character:SetAttribute("LastSlamDamage",damage)
    self:Area(s,impact+UP*2,7,damage,42,now,{height=6,sight=impact+UP*2,seen=a.seen,up=0.65})
    self.effect("Slam",impact,{source=s.character,radius=9,damage=damage,drop=drop})
    s.busyUntil=now+0.28
    s.character:SetAttribute("CombatBusyUntil",s.busyUntil)
    s.character:SetAttribute("CombatAction","SlamLand")
    s.character:SetAttribute("CombatActionAt",now)
    self:Release(s)
   end
  end
  a.lastPosition=p
 elseif key=="F" then
  local hits=Fighter.Ultimate.Hits
  local pending=hits[a.stage+1]
  if pending and elapsed>=pending.At-0.35 and a.warned~=a.stage+1 then
   a.warned=a.stage+1
   self.effect("AlarmWarn",p,{source=s.character,radius=pending.Radius,duration=0.35})
  end
  while a.stage<#hits and elapsed>=hits[a.stage+1].At do
   a.stage+=1
   local hit=hits[a.stage]
   -- Independent server hit per impact; no damage is requested by clients.
   self:Area(s,p,hit.Radius-2,hit.Damage,hit.Knockback,now,
    {up=a.stage==#hits and 0.85 or 0.2,height=8})
   self.effect(hit.Effect,p,{source=s.character,radius=hit.Radius,aim=a.aim,stage=a.stage})
  end
 end
 if now>=s.busyUntil then
  s.action=nil; s.character:SetAttribute("CombatAction","")
 end
end
function Service:Step(now,dt)
 for _,s in self.records do
  if not living(s) then
   s.action=nil; s.buffer=nil; s.core=false; s.stacks=0; s.humanoid.AutoRotate=s.saved.AutoRotate; self:Release(s)
   if s.character.Parent then clockAttributes(s); s.character:SetAttribute("CombatAction","") end
   continue
  end
  if s.owned and now>=s.owned then self:Release(s) end
  if not s.active then continue end
  local old=s.stacks
  s.stacks,s.lastBeat=Rules.decay(s.stacks,s.lastBeat,now)
  if old~=s.stacks then clockAttributes(s) end
  s.humanoid.WalkSpeed=self:Speed(s)
  if now>=(s.resetAfter or 0) and self:Ground(s) then
   if s.recoveryUsed then s.recoveryUsed=false; clockAttributes(s) end
   s.airJumps=0
  end
  self:Advance(s,now,dt)
  if not s.action and s.buffer then
   local buffered=s.buffer; s.buffer=nil
   if now<=buffered.expires then
    s.lastInput=-math.huge
    self:Request(s.character,buffered.key,buffered.aim,now)
   end
  end
 end
end
return Service
