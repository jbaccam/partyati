-- Server fixtures: prove the visible basic peel and falling bombs actually hit.
return function(package)
 local Service=require(game.ServerScriptService.TungCombatService)
 local Kits=require(game.ServerScriptService.FighterCombatKits)
 local Roster=require(package.FighterDefinitions)
 local folder=Instance.new("Folder");folder.Name="ProjectileGameplayFixtures";folder.Parent=workspace
 local effects={};local svc=Service.new(workspace,function(kind,position,data) table.insert(effects,{kind=kind,position=position,data=data}) end)
 local function rig(id,pos)
  local c=Instance.new("Model");c.Name=id
  local r=Instance.new("Part");r.Name="HumanoidRootPart";r.Size=Vector3.new(2,2,2);r.Anchored=true;r.CanCollide=false;r.Position=pos;r.Parent=c
  local h=Instance.new("Humanoid");h.RequiresNeck=false;h.MaxHealth=500;h.Health=500;h.Parent=c
  c.PrimaryPart=r;c:SetAttribute("FighterId",id);c:SetAttribute("TungSahurActive",true);c.Parent=folder
  local state=svc:Register(c,true);h.MaxHealth=500;h.Health=500;return state
 end
 local function action(key,at,root) return {key=key,at=at,stage=0,seen={},aim=-Vector3.zAxis,lastPosition=root.Position} end
 local result={}
 local ok,err=xpcall(function()
  local origin=Vector3.new(24000,18000,0)
  local s=rig("chimpanzini",origin);local t=rig("tung_sahur",origin-Vector3.zAxis*8)
  svc.Velocity=function() end -- Separate MotionPhysicsTests covers actual knockback/motion.
  s.combo=3
  Kits.Advance(svc,s,action("M1",10,s.root),10.17,.17)
  assert(#svc.projectiles==1 and svc.projectiles[1].stopOnHit,"basic banana missing contact termination")
  Kits.Step(svc,10.31,.14)
  assert(t.humanoid.Health==495,"third M1 banana failed to deal its 5 damage")
  assert(#svc.projectiles==0,"basic banana passed through its first victim")
  result.basicBananaDamage=5
  Kits.Advance(svc,s,action("Q",20,s.root),20.19,.19)
  assert(svc.projectiles[1].velocity.Magnitude==64 and svc.projectiles[1].duration==.5,"boomerang speed/range mismatch")
  Kits.Clear(svc,s)
  local floor=Instance.new("Part");floor.Size=Vector3.new(30,2,30);floor.Anchored=true;floor.Position=origin-Vector3.yAxis*12;floor.Parent=folder
  local b=rig("bombardiro",origin+Vector3.xAxis*6)
  t.root.Position=Vector3.new(b.root.Position.X,floor.Position.Y+4,b.root.Position.Z);t.humanoid.Health=500
  local a=action("E",30,b.root)
  for _,elapsed in {.21,.51,.81} do Kits.Advance(svc,b,a,30+elapsed,.3) end
  assert(#svc.projectiles==3,"Carpet Run did not release three server-traveled bombs")
  local drops=0
  for _,e in effects do if e.kind=="BombDrop" then
   drops+=1;assert(e.data.target.Y<e.position.Y and e.data.at and e.data.id,"drop lacks synchronized falling route")
  end end
  assert(drops==3,"falling bomb visuals not emitted")
  b.action=nil -- Already released bombs must survive the end of the animation.
  Kits.Step(svc,31.3,.49)
  assert(#svc.projectiles==0 and t.humanoid.Health==488,"released carpet bombs failed to explode for 3 x 4 damage")
  result.carpetDamage=12;result.fallingBombs=drops
  local rs=rig("chimpanzini",origin+Vector3.xAxis*20)
  local requested
  svc.Drive=function(_,_,_,speed,duration,_,options) requested={speed=speed,duration=duration,vertical=options.vertical} end
  Kits.Start(svc,rs,action("R",40,rs.root),40)
  assert(requested.vertical==12 and requested.duration==1.25,"Peel Glide is not a finite upward recovery")
 end,debug.traceback)
 svc:Destroy();folder:Destroy();assert(ok,err)
 return result
end
