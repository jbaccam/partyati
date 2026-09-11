-- Run in a fresh Studio server. Uses isolated fixtures; never awards progress.
return function()
 local Rules=require(game.ReplicatedStorage.TungPrototype.SprintStrikeRules)
 local Service=require(game.ServerScriptService.TungCombatService)
 local r=Rules.new()
 assert(not Rules.intent(r,"true",1),"malformed intent accepted")
 assert(not Rules.intent(r,true,0/0),"NaN clock accepted")
 assert(Rules.intent(r,true,1))
 local spam=Rules.new(); local accepted=0
 for i=1,30 do if Rules.intent(spam,i%2==0,1+i*.0001) then accepted+=1 end end
 assert(accepted==Rules.InputBurst,"movement spam bypassed token bucket")
 local edges=Rules.new(); Rules.intent(edges,true,1)
 assert(Rules.intent(edges,false,1.01) and Rules.intent(edges,true,1.14),"heartbeat swallowed valid movement edge")
 assert(not Rules.sample(r,1,true)); assert(Rules.sample(r,1.19,true),"sustained sprint did not arm")
 assert(Rules.consume(r,1.2) and not Rules.consume(r,1.2),"token not consumed once")
 assert(Rules.intent(r,true,1.4)); assert(not Rules.sample(r,1.59,true),"held movement rearmed")
 assert(Rules.intent(r,false,1.6)); assert(Rules.intent(r,true,1.67))
 assert(not Rules.sample(r,1.9,true),"too-short release rearmed")
 assert(Rules.intent(r,false,2)); assert(Rules.intent(r,true,2.13))
 assert(not Rules.sample(r,2.13,true)); assert(Rules.sample(r,2.32,true),"deliberate reset did not rearm")
 assert(not Rules.sample(r,2.34,false),"stationary/reverse movement retained readiness")
 assert(not Rules.sample(r,3,true),"stale movement armed sprint strike")
 local cool=Rules.new(); Rules.intent(cool,true,10); Rules.sample(cool,10,true)
 assert(Rules.sample(cool,10.19,true)); Rules.consume(cool,10.2)
 Rules.intent(cool,false,10.25); Rules.intent(cool,true,10.38); Rules.sample(cool,10.38,true)
 assert(not Rules.sample(cool,10.6,true),"recharge bypass")
 Rules.intent(cool,true,10.85); assert(Rules.sample(cool,10.91,true))
 assert(not Rules.canAmplify(20,20.99) and Rules.canAmplify(20,21),"victim immunity duration")
 local velocity=Rules.amplify(Vector3.new(10,7,-10))
 assert(velocity==Vector3.new(12,7,-12),"vertical knockback changed")

 local folder=Instance.new("Folder"); folder.Name="CombatTimingFixtures"; folder.Parent=workspace
 local svc=Service.new(workspace)
 local function rig(name,position)
  local c=Instance.new("Model"); c.Name=name
  local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Size=Vector3.new(2,2,1)
  root.Anchored=true; root.CanCollide=false; root.Position=position; root.Parent=c
  local h=Instance.new("Humanoid"); h.RequiresNeck=false; h.MaxHealth=500; h.Health=500; h.Parent=c
  c:SetAttribute("FighterId","tung_sahur"); c:SetAttribute("TungSahurActive",true); c.Parent=folder
  return c,root,h
 end
 local ok,err=xpcall(function()
  local c,root=rig("Attacker",Vector3.new(28000,18000,0))
  local target,tr,th=rig("Target",root.Position-Vector3.zAxis*3)
  local second,_,sh=rig("SecondTarget",root.Position-Vector3.zAxis*4)
  local s=svc:Register(c,true); local t=svc:Register(target,false); local t2=svc:Register(second,false)
  svc.Velocity=function(_,victim,v) victim.testVelocity=v end
  assert(not svc:SetMoveIntent(c,Vector3.zero,30),"service accepted nonboolean movement")
  assert(svc:SetMoveIntent(c,true,30))
  local allowed=0; for i=1,12 do if svc:SetMoveIntent(c,true,30+i*.0001) then allowed+=1 end end
  assert(allowed==Rules.InputBurst-1,"service input throttle")
  svc:SetSprint(c,true,30); root.AssemblyLinearVelocity=Vector3.zero
  svc:SampleSprintStrike(s,30); svc:SampleSprintStrike(s,30.2)
  assert(not c:GetAttribute("SprintStrikeReady"),"intent alone enabled sprint strike")
  root.AssemblyLinearVelocity=Vector3.zAxis*28; svc:SampleSprintStrike(s,30.21)
  assert(not c:GetAttribute("SprintStrikeReady"),"backpedaling enabled sprint strike")
  root.AssemblyLinearVelocity=-Vector3.zAxis*200; svc:SampleSprintStrike(s,30.22)
  assert(not c:GetAttribute("SprintStrikeReady"),"extreme/knockback velocity enabled sprint strike")
  -- Supply server-observed forward motion; the fixture itself is anchored for isolation.
  root.AssemblyLinearVelocity=-Vector3.zAxis*28
  svc:SampleSprintStrike(s,30.25); svc:SampleSprintStrike(s,30.44)
  assert(c:GetAttribute("SprintStrikeReady"),"physical sprint did not arm")
  assert(svc:Request(c,"M1",-Vector3.zAxis,30.45)); assert(s.action.sprintStrike)
  assert(not c:GetAttribute("SprintStrikeReady"),"M1 cast did not consume token")
  local direction=Vector3.new(0,.2,-1)
  th.Health=500
  assert(svc:Hit(s,t,3,9,direction,30.55,"M1"))
  local boosted=t.testVelocity
  assert(th.Health==497,"sprint strike changed base damage")
  assert(c:GetAttribute("SprintStrikeAt")==30.55,"confirmation not published")
  assert(not s.action.sprintStrike,"successful impact failed to consume swing bonus")
  sh.Health=500; assert(svc:Hit(s,t2,3,9,direction,30.55,"M1"))
  local baseline=t2.testVelocity
  assert(math.abs(boosted.Z-baseline.Z*1.2)<.0001 and math.abs(boosted.Y-baseline.Y)<.0001,"bonus leaked to second target/vertical")
  s.action.sprintStrike=true; th.Health=500
  assert(svc:Hit(s,t,3,9,direction,30.8,"M1"))
  assert(math.abs(t.testVelocity.Z-baseline.Z)<.0001,"victim repeat-amplification cap bypassed")
  s.action.sprintStrike=true; th.Health=500
  assert(svc:Hit(s,t,3,9,direction,32,"Ability"))
  local actualWeight=target:GetAttribute("CombatWeight") or 1
  local expectedAbility=require(game.ReplicatedStorage.TungPrototype.KnockbackRules).Resolve(9,497,500,actualWeight,direction,"Ability")
  assert((t.testVelocity-expectedAbility).Magnitude<.0001 and s.action.sprintStrike,"ability consumed/received melee bonus")
  -- A whiff consumes at cast and cannot passively refill from holding sprint/M1.
  s.action=nil; s.busyUntil=0; s.cooldowns={}; s.lastInput=-math.huge
  s.sprintStrike=Rules.new(); svc:SetMoveIntent(c,true,33); svc:SampleSprintStrike(s,33); svc:SampleSprintStrike(s,33.19)
  tr.Position+=Vector3.xAxis*100; svc.records[second]=nil
  assert(svc:Request(c,"M1",-Vector3.zAxis,33.2)); svc:Step(33.4,.2)
  svc:SetMoveIntent(c,true,34); svc:SampleSprintStrike(s,34); svc:SampleSprintStrike(s,34.2)
  assert(not c:GetAttribute("SprintStrikeReady"),"whiff auto-rearmed while holding movement")
  -- A delayed banana finisher cannot borrow bonuses from a subsequent melee swing.
  s.fighter=require(game.ReplicatedStorage.TungPrototype.FighterDefinitions).ById.chimpanzini
  s.action={key="M1",sprintStrike=true}; s.passiveReadyUntil=40; th.Health=500
  assert(svc:Hit(s,t,3,9,direction,35,"BasicProjectile"))
  assert(th.Health==497 and s.passiveReadyUntil==40 and s.action.sprintStrike,"basic projectile stole later melee bonuses")
  s.action=nil; s.passiveReadyUntil=0; th.Health=500
  assert(svc:Hit(s,t,3,9,direction,36,"BasicProjectile"))
  assert(s.passiveReadyUntil==0,"expired basic attack self-primed passive")
  assert(svc:Hit(s,t,3,9,direction,37,"Ability"))
  assert(s.passiveReadyUntil==41,"ability failed to prime passive")
  svc:SetActive(c,false)
  assert(not svc:SetMoveIntent(c,true,35),"inactive avatar accepted movement intent")
 end,debug.traceback)
 svc:Destroy(); folder:Destroy(); assert(ok,err)
 print("PASS: sprint strike intent validation/throttle, physical momentum, deliberate rearm/recharge, whiff consumption, single-target horizontal-only bonus, unchanged damage, ability isolation and victim anti-juggle cap")
end
