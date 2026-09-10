return function()
 local Service=require(game.ServerScriptService.TungCombatService)
 local folder=Instance.new("Folder");folder.Name="MidnightAlarmFixtures";folder.Parent=workspace
 local function rig(name,pos)
  local c=Instance.new("Model");c.Name=name;c.Parent=folder
  local r=Instance.new("Part");r.Name="HumanoidRootPart";r.Size=Vector3.new(2,2,1);r.Anchored=true;r.CanCollide=false;r.Position=pos;r.Parent=c
  local h=Instance.new("Humanoid");h.RequiresNeck=false;h.MaxHealth=500;h.Health=500;h.Parent=c
  c:SetAttribute("TungSahurActive",true);return c,r,h
 end
 local a,ar,ah=rig("Caster",Vector3.new(0,22000,0))
 local b,br,bh=rig("Target",Vector3.new(0,22000,-4))
 local events={} local service=Service.new(workspace,function(kind) table.insert(events,kind) end)
 local s=service:Register(a,true);service:Register(b,false)
 local ok,err=pcall(function()
  assert(not service:Request(a,"F",Vector3.xAxis,1),"ultimate without Core")
  assert(service:GrantCore(a)); assert(service:Request(a,"F",Vector3.xAxis,10))
  service:Step(10.29,.29);assert(bh.Health==500,"damage before warning")
  for _,t in {.31,.66,.91,1.26,1.71,2.06,2.81,3.16,3.8,4.2} do service:Step(10+t,.1) end
  assert(math.abs(bh.Health-(500-57.24))<.001,"four-impact damage")
  local counts={} for _,kind in events do counts[kind]=(counts[kind] or 0)+1 end
  assert(counts.AlarmWarn==4 and counts.AlarmBeat==2 and counts.AlarmStrike==1 and counts.AlarmFinal==1,"wrong pulse count")
  assert(not s.core and s.action==nil,"Core/recovery lifecycle")
  local wall=Instance.new("Part");wall.Anchored=true;wall.Size=Vector3.new(30,30,1);wall.Position=Vector3.new(0,22000,-2);wall.Parent=folder
  bh.Health=500;assert(service:GrantCore(a));assert(service:Request(a,"F",Vector3.xAxis,30))
  for _,t in {.66,1.26,2.06,3.16,3.8} do service:Step(30+t,.2) end
  assert(bh.Health==500,"ultimate pierced wall");wall:Destroy()
  br.Position=Vector3.new(0,22000,-24);bh.Health=500
  assert(service:GrantCore(a));assert(service:Request(a,"F",Vector3.xAxis,50))
  for _,t in {.66,1.26,2.06,3.16,3.8} do service:Step(50+t,.2) end
  assert(bh.Health==500,"ultimate exceeded range")
  br.Position=Vector3.new(0,22000,-4)
  assert(service:GrantCore(a));assert(service:Request(a,"F",Vector3.xAxis,70))
  service:Step(70.66,.66);local health=bh.Health
  ah.Health=0;service:Step(73.5,2.84)
  assert(bh.Health==health and s.action==nil,"dead caster finished ultimate")
 end)
 service:Destroy();folder:Destroy();assert(ok,err)
 return "PASS: Core, warnings, four impacts, no repeat, walls, range, death cancellation"
end

