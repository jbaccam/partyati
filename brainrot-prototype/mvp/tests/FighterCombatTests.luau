-- Studio server integration tests. Isolated anchored fixtures, no persistent rewards.
return function()
 local Service=require(game.ServerScriptService.TungCombatService)
 local Roster=require(game.ReplicatedStorage.TungPrototype.FighterDefinitions)
 local folder=Instance.new("Folder"); folder.Name="FighterCombatTestFixtures"; folder.Parent=workspace
 local services={}; local base=Vector3.new(24000,20000,0); local serial=0
 local function rig(id,pos,health)
  serial+=1
  local model=Instance.new("Model"); model.Name="FighterFixture"..serial
  local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Size=Vector3.new(2,2,1); root.Position=pos
  root.Anchored=true; root.CanCollide=false; root.Parent=model
  local h=Instance.new("Humanoid"); h.RequiresNeck=false; h.MaxHealth=health or 500; h.Health=h.MaxHealth; h.Parent=model
  model:SetAttribute("FighterId",id); model:SetAttribute("TungSahurActive",true); model.Parent=folder
  return model,h,root
 end
 local function service()
  local svc=Service.new(workspace)
  table.insert(services,svc)
  return svc
 end
 local function fresh(s,now)
  s.action=nil; s.busyUntil=0; s.cooldowns={}; s.lastInput=-math.huge; s.core=true; s.recoveryUsed=false
 end
 local ok,err=xpcall(function()
  local count=0
  for _,f in Roster.List do
   if not f.MVP then continue end
   count+=1
   local svc=service(); local origin=base+Vector3.new(count*120,0,0)
   local floor=Instance.new("Part"); floor.Anchored=true; floor.Size=Vector3.new(70,1,70)
   floor.Position=origin-Vector3.yAxis*3.5; floor.Parent=folder
   local c,h=rig(f.Id,origin); local target,th=rig("tung_sahur",origin+Vector3.new(0,0,-3))
   local s=svc:Register(c,true); svc:Register(target,false)
   assert(h.MaxHealth==f.Stats.MaxHealth,f.Id.." health mismatch")
   assert(h.WalkSpeed==f.Stats.WalkSpeed,f.Id.." speed mismatch")
   assert(svc:SetSprint(c,true,1)); assert(h.WalkSpeed==f.Stats.SprintSpeed,f.Id.." sprint mismatch")
   assert(svc:Request(c,"M1",-Vector3.zAxis,10)); svc:Step(10.3,.3)
   assert(th.Health<500,f.Id.." basic missed")
   assert(f.Id=="tung_sahur" or s.stacks==0,"non-Tung received Beat buffs")
   c:SetAttribute("CombatDisabled",true)
   assert(not svc:Request(c,"Q",-Vector3.zAxis,11),"disabled input accepted")
   c:SetAttribute("CombatDisabled",false)
   fresh(s,12)
   assert(not svc:Request(c,"INVALID",-Vector3.zAxis,12),"invalid key accepted")
   assert(not svc:Request(c,"Q",Vector3.new(0/0,0,0),12),"NaN accepted")
   s.core=false; assert(not svc:Request(c,"F",-Vector3.zAxis,13),"unearned ultimate accepted")
   fresh(s,14); th.Health=500
   assert(svc:Request(c,"Q",-Vector3.zAxis,14))
   for frame=1,40 do svc:Step(14+frame*.05,.05) end
   assert(th.Health<500,f.Id.." Q did not damage nearby target")
   fresh(s,17); th.Health=500
   assert(svc:Request(c,"E",-Vector3.zAxis,17))
   svc:Step(17.15,.15)
   if f.Id=="ballerina" then
    assert(s.counterUntil>17.15,"counter window failed to open")
    assert(not svc:Hit(svc.records[target],s,10,0,Vector3.zAxis,17.2),"counter failed to block close strike")
   end
   for frame=1,30 do svc:Step(17.15+frame*.05,.05) end
   assert(th.Health<500,f.Id.." E did not damage/counter nearby target")
   fresh(s,20)
   svc.Ground=function() return nil end
   assert(svc:Request(c,"R",-Vector3.zAxis,20)); svc:Step(21,1)
   s.cooldowns.R=0
   assert(not svc:Request(c,"R",-Vector3.zAxis,30),"infinite recovery: "..f.Id)
   fresh(s,40); s.airJumps=0
   for i=1,f.Stats.AirJumps do assert(svc:Request(c,"Jump",-Vector3.zAxis,40+i)) end
   assert(not svc:Request(c,"Jump",-Vector3.zAxis,45),"infinite air jumps: "..f.Id)
   svc.Ground=function() return {Position=origin-Vector3.yAxis*3} end
   svc:Step(46,1)
   assert(not s.recoveryUsed and s.airJumps==0,"landing reset failed: "..f.Id)
   fresh(s,50); th.Health=500
   assert(svc:Request(c,"F",-Vector3.zAxis,50))
   for frame=1,90 do svc:Step(50+frame*.05,.05) end
   assert(s.action==nil and not s.core,"ultimate did not expire/consume Core: "..f.Id)
   svc:Destroy()
  end
  assert(count==5,"MVP roster must have five fighters")
  -- A projectile takes time to travel, hits at most once per pass, and is blocked by cover.
  local svc=service(); local origin=base+Vector3.new(1000,0,0)
  local c=rig("chimpanzini",origin); local target,th,tr=rig("tung_sahur",origin-Vector3.zAxis*12)
  local s=svc:Register(c,true); svc:Register(target,false)
  assert(svc:Request(c,"Q",-Vector3.zAxis,100)); svc:Step(100.2,.2)
  assert(th.Health==500 and #svc.projectiles==1,"projectile became hitscan")
  for frame=1,35 do svc:Step(100.2+frame*.04,.04) end
  assert(th.Health==488,"boomerang must deal 7 outbound + 5 return, once per pass")
  assert(#svc.projectiles==0,"projectile exceeded finite range/lifetime")
  local wall=Instance.new("Part"); wall.Anchored=true; wall.Size=Vector3.new(20,20,1)
  wall.Position=origin-Vector3.zAxis*6; wall.Parent=folder
  fresh(s,110); th.Health=500
  assert(svc:Request(c,"Q",-Vector3.zAxis,110))
  for frame=1,50 do svc:Step(110+frame*.04,.04) end
  assert(th.Health==500,"projectile damaged through cover"); wall:Destroy()
  -- Counter blocks exactly one impact and can only retaliate at melee distance.
  local dancer=rig("ballerina",origin+Vector3.xAxis*40)
  local ds=svc:Register(dancer,true); ds.counterUntil=121
  local before=ds.humanoid.Health
  assert(not svc:Hit(s,ds,20,0,Vector3.xAxis,120),"counter failed to block")
  assert(ds.humanoid.Health==before and ds.counterUntil==0,"counter did not consume once")
  assert(svc:Hit(s,ds,20,0,Vector3.xAxis,120.1),"counter remained invincible")
  -- Tank firing penalty and no health restoration by switching active state.
  local bomber,bh=rig("bombardiro",origin+Vector3.xAxis*80)
  local bs=svc:Register(bomber,true); svc:SetSprint(bomber,true,130)
  assert(svc:Request(bomber,"Q",-Vector3.zAxis,130)); svc:Step(130.1,.1)
  assert(bh.WalkSpeed==12,"ranged fighter can sprint while firing")
  bh.Health=65; svc:SetActive(bomber,false); bomber:SetAttribute("FighterId","ballerina"); svc:SetActive(bomber,true)
  assert(bh.MaxHealth==90 and math.abs(bh.Health-45)<.001,"switching healed fighter")
 end,debug.traceback)
 for _,svc in services do svc:Destroy() end
 folder:Destroy(); assert(ok,err)
 print("PASS: five kits/stats, finite recovery/jumps, Core requirement, disabled/invalid inputs, projectile travel/cover/pass caps, counter, firing penalty and health-preserving switch")
end
