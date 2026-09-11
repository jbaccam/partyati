-- Deterministic kit-contract tests; physical displacement needs the separate live drive tests.
return function()
 local Kits=require(game.ServerScriptService.FighterCombatKits)
 local Roster=require(game.ReplicatedStorage.TungPrototype.FighterDefinitions)
 local function fixture(id,combo,key)
  local attrs={}
  local s={active=true,fighter=Roster.ById[id],combo=combo or 1,root={Position=Vector3.zero,Parent=true},
   character={Parent=true,SetAttribute=function(_,k,v) attrs[k]=v end},humanoid={Health=100}}
  local service={drives={},areas={},effects={},projectiles={},projectileSerial=0,traps={},records={},
   world={Raycast=function() return nil end}}
  function service:Drive(_,aim,speed,duration,now,options)
   table.insert(self.drives,{aim=aim,speed=speed,duration=duration,at=now,options=options})
  end
  function service:Ground() return true end
  function service:Area(_,position,radius,damage,kb,now,options)
   table.insert(self.areas,{position=position,radius=radius,damage=damage,kb=kb,at=now,options=options})
  end
  function service:RayParams() return nil end
  service.effect=function(kind,position,data) table.insert(service.effects,{kind=kind,data=data}) end
  local a={key=key or "M1",at=100,stage=0,seen={},lastPosition=Vector3.zero,aim=-Vector3.zAxis}
  return service,s,a
 end
 -- Different basic geometries, rhythm and number of stages, not a renamed shared punch.
 local svc,s,a=fixture("tralalero",1)
 Kits.Advance(svc,s,a,100.10,.10); assert(#svc.areas==0,"bite hit before jaw closes")
 Kits.Advance(svc,s,a,100.12,.02); assert(#svc.areas==1 and svc.areas[1].options.cone==.5)
 local tail,ts,ta=fixture("tralalero",3)
 Kits.Advance(tail,ts,ta,100.16,.16)
 assert(tail.areas[1].radius>svc.areas[1].radius and tail.areas[1].options.cone<0,"tail is still a narrow bite")
 for combo=1,3 do
  local heavy,hs,ha=fixture("bombardiro",combo)
  Kits.Advance(heavy,hs,ha,100.2,.2); assert(#heavy.areas==0,"heavy windup removed")
  Kits.Advance(heavy,hs,ha,100.28,.08)
  assert(#heavy.areas==1 and heavy.areas[1].damage==7 and heavy.areas[1].kb==42,"chomp became a three-hit combo")
 end
 local dancer,ds,da=fixture("ballerina",3)
 Kits.Advance(dancer,ds,da,100.12,.12)
 assert(dancer.areas[1].options.cone==.5 and dancer.drives[1].speed==38,"finishing kick must advance")
 assert(Roster.ById.ballerina.Basic.Recovery<Roster.ById.tralalero.Basic.Recovery)
 assert(Roster.ById.bombardiro.Basic.SingleHit and #Roster.ById.bombardiro.Basic.Hits==1)
 local chimp,cs,ca=fixture("chimpanzini",3)
 Kits.Advance(chimp,cs,ca,100.17,.17)
 assert(#chimp.areas==0 and #chimp.projectiles==1,"third peel lash must release a projectile")
 local peel=chimp.projectiles[1]
 assert(math.abs(peel.velocity.Magnitude*peel.duration-13)<.001 and peel.context=="BasicProjectile" and not peel.returning)
 Kits.Step(chimp,101,1); assert(#chimp.projectiles==0,"basic peel lasts beyond its range")
 local modes={tralalero="Porpoise",chimpanzini="Glide",ballerina="AirStep",bombardiro="Flight"}
 local durations={tralalero=.8,chimpanzini=1.25,ballerina=.22,bombardiro=1.6}
 for id,mode in modes do
  local recovery,rs,ra=fixture(id,1,"R")
  Kits.Start(recovery,rs,ra,100)
  assert(rs.recoveryUsed and rs.needsLanding,"recovery did not consume airtime resource")
  local drive=recovery.drives[1]
  assert(drive and drive.options.mode==mode and drive.duration==durations[id],id.." uses generic one-shot lift")
  assert(Kits.Duration(id,"R")==Roster.ById[id].Abilities.R.Duration,"animation and server duration disagree")
  if id=="chimpanzini" then assert(drive.options.vertical==12 and drive.speed==28)
  elseif id=="bombardiro" then assert(drive.options.vertical==8 and drive.speed==32)
  elseif id=="tralalero" then assert(drive.options.vertical==nil and drive.options.lift==54)
  elseif id=="ballerina" then
   Kits.Advance(recovery,rs,ra,100.39,.39); assert(#recovery.drives==1)
   Kits.Advance(recovery,rs,ra,100.41,.02); assert(#recovery.drives==2 and recovery.drives[2].speed==52)
   Kits.Advance(recovery,rs,ra,100.5,.09); assert(#recovery.drives==2,"second air-step retriggered")
  end
 end
 local torpedo,qs,qa=fixture("tralalero",1,"Q")
 Kits.Start(torpedo,qs,qa,100)
 assert(torpedo.drives[1].speed*torpedo.drives[1].duration>25,"torpedo is a tiny jolt")
 local launcher,es,ea=fixture("tralalero",1,"E")
 Kits.Advance(launcher,es,ea,100.30,.30); assert(#launcher.areas==0)
 Kits.Advance(launcher,es,ea,100.33,.03)
 assert(launcher.areas[1].options.cone==-1 and launcher.areas[1].options.up==3 and launcher.areas[1].kb==52)
 assert(launcher.effects[1].kind=="TailSweep","tail launcher missing distinct impact cue")
 local speeds={}; local jumps={}
 for _,id in {"tung_sahur","tralalero","chimpanzini","ballerina","bombardiro"} do
  local stats=Roster.ById[id].Stats
  assert(not speeds[stats.WalkSpeed],"walk speeds should differ"); speeds[stats.WalkSpeed]=true
  assert(not jumps[stats.JumpVelocity],"jump impulses should differ"); jumps[stats.JumpVelocity]=true
 end
 print("PASS: distinct basic hit windows/shapes/projectile/chomp, sustained kit-drive contracts, two-step recovery, finite peel, tail pop and movement stats")
end
