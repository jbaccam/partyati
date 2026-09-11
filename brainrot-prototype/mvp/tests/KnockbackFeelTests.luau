return function(package)
 local K=require(package.KnockbackRules)
 local Rules=require(package.CombatRules)
 local Service=require(game.ServerScriptService.TungCombatService)
 local old=Vector3.new(0,.45,-1).Unit*Rules.knockback(70,60,100,1)
 local ult,duration=K.Resolve(70,60,100,1,Vector3.new(0,.45,-1),"Ultimate")
 assert((ult-old).Magnitude<.001 and duration==0,"Ultimate knockback changed")
 assert(K.Kind("M1",1,false)=="Carry" and K.Kind("M1",3,false)=="Finisher" and K.Kind("M1",1,true)=="Finisher")
 local normal=K.Resolve(38,90,100,1,Vector3.new(0,.35,-1),"Ability")
 local weak=K.Resolve(38,20,100,1,Vector3.new(0,.35,-1),"Ability")
 local heavy=K.Resolve(38,90,100,1.3,Vector3.new(0,.35,-1),"Ability")
 assert(weak.Magnitude>normal.Magnitude and heavy.Magnitude<normal.Magnitude,"health/weight balance lost")
 local folder=Instance.new("Folder");folder.Name="KnockbackFeelFixtures";folder.Parent=workspace
 local floor=Instance.new("Part");floor.Size=Vector3.new(180,2,180);floor.Position=Vector3.new(26000,1000,26000);floor.Anchored=true;floor.Parent=folder
 local function model(name,position,anchored)
  local c=Instance.new("Model");c.Name=name
  local r=Instance.new("Part");r.Name="HumanoidRootPart";r.Size=Vector3.new(2,2,2);r.Position=position;r.Anchored=anchored;r.Parent=c
  local h=Instance.new("Humanoid");h.RequiresNeck=false;h.HipHeight=2;h.Parent=c;c.PrimaryPart=r
  c:SetAttribute("FighterId","tung_sahur");c:SetAttribute("TungSahurActive",true);c.Parent=folder
  return c,r,h
 end
 local ac,ar,ah=model("Attacker",floor.Position+Vector3.new(0,5,6),true)
 local tc,tr,th=model("Victim",floor.Position+Vector3.new(0,5,0),false)
 local svc=Service.new(workspace);local a=svc:Register(ac,true);local t=svc:Register(tc,false)
 tc:SetAttribute("CombatWeight",1);tr:SetNetworkOwner(nil)
 local connection=game.RunService.Heartbeat:Connect(function(dt) svc:Step(workspace:GetServerTimeNow(),dt) end)
 local results={}
 local ok,err=xpcall(function()
  local function sample(label,base,context,combo,up,seconds)
   require(game.ServerScriptService.HitReaction).Stop(t)
   tr.CFrame=CFrame.new(floor.Position+Vector3.new(0,5,0));tr.AssemblyLinearVelocity=Vector3.zero
   th.Health=th.MaxHealth;task.wait(.35)
   local start=tr.Position;a.combo=combo;a.action=nil
   assert(svc:Hit(a,t,3,base,Vector3.new(0,up,-1),workspace:GetServerTimeNow(),context))
   task.wait(seconds)
   local travel=math.abs(tr.Position.Z-start.Z);results[label]=travel
   assert(not tr:FindFirstChild("HitCarryVelocity"),"hit carry never released")
   return travel
  end
  local carry=sample("openingHitStuds",9,"M1",1,.2,.5)
  local finish=sample("finisherStuds",34,"M1",3,1.1,.9)
  local ability=sample("abilityStuds",38,"Ability",1,.35,.9)
  assert(carry>1.5 and carry<6,"Opening hit must carry, not barely twitch or throw out of combo range")
  assert(finish>7 and ability>7,"Regular finishers/abilities still lack ring-out pressure")
  -- Third rapid stagger must be short; existing sprint bonus stays independent.
  t.staggerChain=2;t.lastStaggerHit=workspace:GetServerTimeNow()
  a.combo=1;local now=workspace:GetServerTimeNow()
  svc:Hit(a,t,3,9,Vector3.new(0,.2,-1),now,"M1")
  assert(tc:GetAttribute("HitStaggerUntil")<=now+.041,"Repeated hits enabled indefinite stagger")
  require(game.ServerScriptService.HitReaction).Stop(t)
  ar.Anchored=false;ar.CFrame=CFrame.lookAt(floor.Position+Vector3.new(0,5,5),floor.Position+Vector3.new(0,5,0));ar.AssemblyLinearVelocity=Vector3.zero;ar:SetNetworkOwner(nil)
  tr.CFrame=CFrame.new(floor.Position+Vector3.new(0,5,0));tr.AssemblyLinearVelocity=Vector3.zero
  th.Health=100;a.action=nil;a.busyUntil=0;a.cooldowns={};a.lastM1=-math.huge;a.combo=0
  -- The single-part test rig has no torso to recover from FallingDown on its own.
  ah:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false);ah:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
  ah:ChangeState(Enum.HumanoidStateType.Running);ar.AssemblyAngularVelocity=Vector3.zero
  task.wait(.35)
  local chase=game.RunService.Heartbeat:Connect(function() ah:Move(-Vector3.zAxis,false) end)
  for i=1,3 do assert(svc:Request(ac,"M1",-Vector3.zAxis,workspace:GetServerTimeNow()));task.wait(i==3 and .44 or .30) end
  chase:Disconnect();ah:Move(Vector3.zero,false)
  results.chasedComboDamage=100-th.Health
  assert(results.chasedComboDamage>=12,"Running in failed to connect all three basic attacks: "..game.HttpService:JSONEncode(results).." separation="..tostring((ar.Position-tr.Position).Magnitude))
  svc:Remove(tc);assert(not tr:FindFirstChild("HitCarryVelocity"),"Unregister leaked hit constraint")
 end,debug.traceback)
 connection:Disconnect();svc:Destroy();folder:Destroy();assert(ok,err)
 return results
end
