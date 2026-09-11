-- Server-only four-fighter kits. No client-reported hits, targets, cooldowns or flight.
local Rules=require(game.ReplicatedStorage.TungPrototype.CombatRules)
local Roster=require(game.ReplicatedStorage.TungPrototype.FighterDefinitions)
local Kits={}
local UP=Vector3.yAxis
function Kits.Duration(id,key)
 local fighter=Roster.ById[id]
 local ability=fighter and fighter.Abilities[key]
 return ability and ability.Duration or .5
end
local function alive(s) return s.active and s.character.Parent and s.root.Parent and s.humanoid.Health>0 end
local function visual(service,kind,s,p,data)
 data=data or {}; data.source=s.character; data.fighterId=s.fighter.Id
 service.effect(kind,p,data)
end
local function sweep(service,s,a,now,damage,kb,radius)
 local p=s.root.Position; local delta=p-a.lastPosition
 local n=math.clamp(math.ceil(delta.Magnitude/1.5),1,20)
 for i=1,n do
  local point=a.lastPosition:Lerp(p,i/n)
  service:Area(s,point,radius,damage,kb,now,{seen=a.seen,aim=a.aim,cone=-.3,up=.45,context=a.key=="F" and "Ultimate" or "Ability"})
 end
 a.lastPosition=p
end
local function projectile(service,s,origin,velocity,now,duration,damage,kb,kind,options)
 options=options or {}
 service.projectileSerial+=1
 local p={id=service.projectileSerial,owner=s,origin=origin,position=origin,velocity=velocity,at=now,
  duration=duration,damage=damage,kb=kb,kind=kind,seen=options.seen or {},radius=options.radius or .7,
  explosion=options.explosion,returning=options.returning,returnDamage=options.returnDamage,context=options.context or (s.action and s.action.key=="F" and "Ultimate" or "Ability"),stopOnHit=options.stopOnHit}
 table.insert(service.projectiles,p)
 visual(service,options.dropTarget and "BombDrop" or "Projectile",s,origin,{id=p.id,velocity=velocity,at=now,duration=duration,kind=kind,radius=p.radius,target=options.dropTarget})
 return p
end
local function endProjectile(service,p)
 visual(service,"ProjectileEnd",p.owner,p.position,{id=p.id})
end
local function explode(service,p,now)
 service:Area(p.owner,p.position,p.explosion or 4,p.damage,p.kb,now,{seen=p.seen,height=7,sight=p.position,up=.6,context=p.context})
 visual(service,"Slam",p.owner,p.position,{radius=(p.explosion or 4)+2})
end
function Kits.Clear(service,s)
 for i=#service.projectiles,1,-1 do
  if service.projectiles[i].owner==s then endProjectile(service,service.projectiles[i]); table.remove(service.projectiles,i) end
 end
 for i=#service.traps,1,-1 do
  if service.traps[i].owner==s then visual(service,"TrapEnd",s,service.traps[i].position); table.remove(service.traps,i) end
 end
end
function Kits.Start(service,s,a,now)
 local id=s.fighter.Id
 if a.key=="R" then
  s.recoveryUsed=true; s.needsLanding=true; s.wasAirborne=not service:Ground(s); s.resetAfter=now+.3
  if id=="tralalero" then
   service:Drive(s,a.aim,42,.8,now,{lift=54,mode="Porpoise"})
  elseif id=="chimpanzini" then
   service:Drive(s,a.aim,28,1.25,now,{lift=24,vertical=12,mode="Glide"})
  elseif id=="ballerina" then
   service:Drive(s,a.aim,58,.22,now,{lift=28,mode="AirStep"})
  elseif id=="bombardiro" then
   service:Drive(s,a.aim,32,1.6,now,{lift=24,vertical=8,mode="Flight"})
  end
 elseif id=="tralalero" and a.key=="Q" then
  service:Drive(s,a.aim,62,.42,now,{lift=2,mode="Torpedo"})
 elseif id=="ballerina" and a.key=="Q" then
  service:Drive(s,a.aim,26,.55,now,{mode="Pirouette"})
 elseif id=="ballerina" and a.key=="E" then
  s.counterUntil=0 -- window opens only after startup; expires in server clock time
 elseif id=="bombardiro" and a.key=="E" then
  service:Drive(s,a.aim,32,.9,now,{lift=8,vertical=0,mode="CarpetRun"})
 elseif a.key=="F" then
  a.origin=s.root.Position
 end
end
function Kits.Advance(service,s,a,now,dt)
 local elapsed=now-a.at; local id=s.fighter.Id; local key=a.key; local p=s.root.Position
 local fighter=s.fighter
 if key=="M1" then
  local combo=fighter.Basic.SingleHit and 1 or s.combo
  local hitAt=(fighter.Basic.HitTimes or {})[combo] or fighter.Basic.Recovery*.4
  if a.stage==0 and elapsed>=hitAt then
   a.stage=1
   local damage=fighter.Basic.Hits[combo]
   if id=="tralalero" and not service:Ground(s) then damage+=1 end
   if id=="chimpanzini" and combo==3 then
    -- A short visible peel, not an invisible melee sphere or a full ranged basic.
    projectile(service,s,p,a.aim*54,now,13/54,damage,fighter.Basic.FinalKnockback,"Banana",{context="BasicProjectile",radius=.7,stopOnHit=true})
   else
    local radius=fighter.Basic.Reach-2
    local cone=.1; local up=combo==3 and .9 or .15
    local kb=combo==3 and fighter.Basic.FinalKnockback or 8
    if id=="tralalero" then
     cone=combo==3 and -.45 or .5 -- jaw snaps need aim; broad tail catches flankers
     radius=combo==3 and 4.5 or 3.5
    elseif id=="chimpanzini" then cone=.35
    elseif id=="ballerina" then
     cone=.5; up=combo==3 and .55 or .12
     if combo==3 then service:Drive(s,a.aim,38,.12,now,{mode="FinishingKick"}) end
    elseif id=="bombardiro" then
     cone=.05; kb=fighter.Basic.FinalKnockback; up=.35
    end
    service:Area(s,p,radius,damage,kb,now,{aim=a.aim,cone=cone,seen=a.seen,up=up,context="M1"})
   end
   visual(service,"FighterStrike",s,p,{aim=a.aim,combo=combo,kind=fighter.Basic.Name,radius=fighter.Basic.Reach-2})
  end
 elseif key=="R" then
  if id=="ballerina" and elapsed>=.4 and not a.secondStep then
   a.secondStep=true
   service:Drive(s,a.aim,52,.22,now,{lift=32,mode="AirStep"})
  end
  -- Glide/flight are positioning tools, not persistent contact-damage auras.
  if id=="tralalero" and elapsed<=.8 then
   sweep(service,s,a,now,fighter.Abilities.R.Damage,fighter.Abilities.R.Knockback,2.2)
  elseif id=="ballerina" and (elapsed<=.22 or elapsed>=.4 and elapsed<=.62) then
   sweep(service,s,a,now,fighter.Abilities.R.Damage,fighter.Abilities.R.Knockback,2)
  end
 elseif id=="tralalero" then
  if key=="Q" and elapsed>=.08 and elapsed<=.42 then
   sweep(service,s,a,now,11,39,2.4)
  elseif key=="E" and a.stage==0 and elapsed>=.32 then
   a.stage=1
   service:Area(s,p,5,8,52,now,{aim=a.aim,cone=-1,up=3,seen=a.seen})
   visual(service,"TailSweep",s,p,{radius=7,aim=a.aim,kind="TailLauncher"})
  elseif key=="F" then
   local times={.45,1.1,1.75}
   if a.stage<3 and elapsed>=times[a.stage+1]-.25 and a.warned~=a.stage+1 then
    a.warned=a.stage+1; visual(service,"AlarmWarn",s,p+a.aim*5,{radius=6,duration=.25})
   end
   if a.stage<3 and elapsed>=times[a.stage+1] then
    a.stage+=1; a.seen={}; a.lastPosition=p; a.hitUntil=now+.2
    service:Drive(s,a.aim,55,.2,now,{mode="FrenzyBite"})
    visual(service,"Wave",s,p,{radius=6,aim=a.aim})
   end
   if a.hitUntil and now<=a.hitUntil then sweep(service,s,a,now,13,a.stage==3 and 70 or 15,3.5) end
  end
 elseif id=="chimpanzini" then
  if key=="Q" and a.stage==0 and elapsed>=.18 then
   a.stage=1
   projectile(service,s,p,a.aim*64,now,32/64,7,22,"Banana",{returning=true,returnDamage=5})
  elseif key=="E" and a.stage==0 and elapsed>=.2 then
   a.stage=1
   for i=#service.traps,1,-1 do
    if service.traps[i].owner==s then visual(service,"TrapEnd",s,service.traps[i].position); table.remove(service.traps,i) end
   end
   local floor=service.world:Raycast(p,-UP*12,service:RayParams())
   if floor and floor.Normal.Y>.45 then
    local position=floor.Position+UP*.15
    table.insert(service.traps,{owner=s,position=position,at=now,expires=now+8})
    visual(service,"Trap",s,position,{duration=8,radius=3.5})
   end
  elseif key=="F" then
   local times={.6,1.3,2}
   if a.stage<3 and elapsed>=times[a.stage+1]-.3 and a.warned~=a.stage+1 then
    a.warned=a.stage+1; visual(service,"AlarmWarn",s,p+a.aim*12,{radius=7,duration=.3})
   end
   if a.stage<3 and elapsed>=times[a.stage+1] then
    a.stage+=1
    local seen={}
    for _,angle in {-.18,0,.18} do
     local aim=CFrame.fromAxisAngle(UP,angle):VectorToWorldSpace(a.aim)
     projectile(service,s,p,aim*42,now,.85,12,a.stage==3 and 65 or 18,"Banana",{seen=seen,radius=1,context="Ultimate"})
    end
   end
  end
 elseif id=="ballerina" then
  if key=="Q" then
   while a.stage<4 and elapsed>=(a.stage+1)*.15 do
    a.stage+=1
    service:Area(s,p,4.5,3,a.stage==4 and 35 or 4,now,{up=a.stage==4 and .55 or .1})
    visual(service,"Swing",s,p,{aim=a.aim})
   end
  elseif key=="E" and a.stage==0 and elapsed>=.08 then
   a.stage=1; s.counterUntil=a.at+.48; s.character:SetAttribute("CounterUntil",s.counterUntil)
   visual(service,"Counter",s,p,{duration=.4})
  elseif key=="F" then
   local times={.55,1.05,1.55,2.2}
   if a.stage<4 and elapsed>=times[a.stage+1]-.3 and a.warned~=a.stage+1 then
    a.warned=a.stage+1; visual(service,"AlarmWarn",s,p,{radius=8,duration=.3})
   end
   while a.stage<4 and elapsed>=times[a.stage+1] do
    a.stage+=1
    service:Area(s,p,6,a.stage==4 and 15 or 7,a.stage==4 and 72 or 9,now,{up=a.stage==4 and 1 or .2})
    visual(service,a.stage==4 and "AlarmFinal" or "Wave",s,p,{radius=8,aim=a.aim})
   end
  end
 elseif id=="bombardiro" then
  if key=="Q" and a.stage==0 and elapsed>=.35 then
   a.stage=1
   projectile(service,s,p,a.aim*38,now,1,13,40,"Bomb",{explosion=4.5,radius=.8})
  elseif key=="E" then
   while a.stage<3 and elapsed>=.2+a.stage*.3 do
    a.stage+=1
    local floor=service.world:Raycast(p,-UP*24,service:RayParams())
    if floor then
     local position=floor.Position+UP*.5
     visual(service,"AlarmWarn",s,position,{radius=5,duration=.35})
     -- Real server-traveled bombs, not just a scheduled ring on the floor.
     -- They persist after the release animation ends and stop on solid cover.
     projectile(service,s,p,(position-p)/.35,now,.35,4,32,"Bomb",{explosion=3.5,radius=.6,dropTarget=position})
    end
   end
  elseif key=="F" then
   a.blasts=a.blasts or {}
   local times={1.05,1.85,2.65}
   if a.stage<3 and elapsed>=times[a.stage+1]-.6 and a.warned~=a.stage+1 then
    local stage=a.stage+1; a.warned=stage
    local desired=a.origin+a.aim*(8+stage*6)
    local block=service.world:Raycast(a.origin,desired-a.origin,service:RayParams())
    if block then desired=block.Position-a.aim*1.5 end
    local floor=service.world:Raycast(desired+UP*4,-UP*30,service:RayParams())
    a.blasts[stage]=floor and floor.Position+UP*.5 or desired
    visual(service,"AlarmWarn",s,a.blasts[stage],{radius=8,duration=.6})
   end
   if a.stage<3 and elapsed>=times[a.stage+1] then
    a.stage+=1; local center=a.blasts[a.stage]
    if center and service:Visible(a.origin,center+UP*2) then
     service:Area(s,center,6,14,a.stage==3 and 75 or 30,now,{height=8,up=.7})
     visual(service,"Slam",s,center,{radius=8})
    end
   end
  end
 end
end
function Kits.Step(service,now,dt)
 for i=#service.projectiles,1,-1 do
  local p=service.projectiles[i]
  if not alive(p.owner) then endProjectile(service,p); table.remove(service.projectiles,i); continue end
  local nextPosition=p.origin+p.velocity*math.clamp(now-p.at,0,p.duration)
  local delta=nextPosition-p.position
  local block=delta.Magnitude>.001 and service.world:Raycast(p.position,delta,service:RayParams()) or nil
  if block then nextPosition=block.Position+block.Normal*.15 end
  local travel=nextPosition-p.position; local stopped=false
  local steps=math.clamp(math.ceil(travel.Magnitude/.8),1,150)
  for j=1,steps do
   local point=p.position:Lerp(nextPosition,j/steps)
   for _,target in service.records do
    if target==p.owner or p.seen[target] or not target.character.Parent or target.humanoid.Health<=0 then continue end
    local stats=target.fighter and target.fighter.Stats
    if Rules.capsuleInSphere(point,p.radius,target.root.Position,stats and stats.HitRadius or 2,stats and stats.HitHalfHeight or 3)
     and service:Visible(point,target.root.Position) then
     if p.explosion then nextPosition=point; stopped=true; break end
     p.seen[target]=true -- A blocked/parried pass cannot re-hit on the next substep.
     service:Hit(p.owner,target,p.damage,p.kb,p.velocity.Unit+UP*.25,now,p.context or "Ability")
     if p.stopOnHit then nextPosition=point;stopped=true;break end
    end
   end
   if stopped then break end
  end
  p.position=nextPosition
  local expired=now>=p.at+p.duration
  if block or stopped or expired then
   if p.explosion then explode(service,p,now) end
   endProjectile(service,p); table.remove(service.projectiles,i)
   if expired and not block and p.returning then
     projectile(service,p.owner,p.position,-p.velocity,now,p.duration,p.returnDamage or 5,p.kb,"Banana",{context=p.context})
   end
  end
 end
 for i=#service.traps,1,-1 do
  local t=service.traps[i]; local remove=not alive(t.owner) or now>=t.expires
  if not remove and now>=t.at+.5 then
   local nearest=nil; local distance=math.huge
   for _,target in service.records do
    local delta=(target.root.Position-t.position).Magnitude
    if target~=t.owner and target.character.Parent and target.humanoid.Health>0 and delta<distance and delta<=5
     and service:Visible(t.position+UP,target.root.Position) then nearest=target; distance=delta end
   end
   if nearest then
    local countered=(nearest.counterUntil or 0)>now
    remove=service:Hit(t.owner,nearest,8,28,UP,now,"Ability") or countered
   end
  end
  if remove then visual(service,"TrapEnd",t.owner,t.position); table.remove(service.traps,i) end
 end
end
return Kits
