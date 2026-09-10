return function()
 local Service=require(game.ServerScriptService.TungCombatService)
 local folder=Instance.new("Folder"); folder.Name="TungExtendedFixtures"; folder.Parent=workspace
 local function rig(name,pos,hp)
  local m=Instance.new("Model"); m.Name=name
  local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Size=Vector3.new(2,2,1); r.Anchored=true; r.CanCollide=false; r.Position=pos; r.Parent=m
  local h=Instance.new("Humanoid"); h.RequiresNeck=false; h.MaxHealth=hp or 115; h.Health=h.MaxHealth; h.Parent=m
  m:SetAttribute("TungSahurActive",true); m.Parent=folder; return m,h,r
 end
 local service=Service.new(workspace)
 local ok,err=xpcall(function()
  local a,ah,ar=rig("Attacker",Vector3.new(0,15000,0))
  local b,bh,br=rig("Target",Vector3.new(0,15000,-3))
  local s=service:Register(a,true); service:Register(b,false)
  for i,t in {10,10.4,10.8} do
   assert(service:Request(a,"M1",Vector3.new(0,0,-1),t)); service:Step(t+0.16,0.16)
  end
  assert(math.abs(bh.Health-102.55)<0.001,"three-hit combo or Beat damage incorrect")
  assert(s.stacks==3)
  service:Step(14,1); assert(s.stacks==2,"Beat did not decay one stack")
  service:Step(20,1); assert(s.stacks==0)
  bh.Health=115
  local floor=Instance.new("Part"); floor.Size=Vector3.new(50,1,50); floor.Anchored=true
  floor.Position=Vector3.new(0,14996.5,0); floor.Parent=folder
  assert(service:Request(a,"E",Vector3.new(0,0,-1),21))
  service:Step(21.3,0.3); assert(math.abs(bh.Health-103)<0.001,"Slam landing damage")
  service:Step(22,0.7); assert(math.abs(bh.Health-103)<0.001,"Slam repeated damage")
  floor:Destroy()
  service:Step(30,1); bh.Health=115
  assert(service:GrantCore(a)); assert(service:Request(a,"F",Vector3.new(0,0,-1),31))
  service:Step(31.66,0.66); service:Step(32.26,0.6); service:Step(33.06,0.8); service:Step(34.16,1.1)
  assert(math.abs(bh.Health-57.76)<0.001,"two drum booms + resonant strike + final slam including Beat")
  service:Step(37,1); assert(math.abs(bh.Health-57.76)<0.001,"ultimate repeated")
  bh.Health=115
  local ff=Instance.new("ForceField"); ff.Parent=b
  assert(service:Request(a,"Q",Vector3.new(0,0,-1),40)); service:Step(40.3,0.3)
  assert(bh.Health==115,"ForceField protection ignored"); ff:Destroy()
  a:SetAttribute("CombatDisabled",true)
  assert(not service:Request(a,"Q",Vector3.new(0,0,-1),46),"disabled combat accepted")
  a:SetAttribute("CombatDisabled",nil)
  assert(service:Request(a,"R",Vector3.new(0,0,-1),47))
  service:Step(47.2,0.2)
  assert(bh.Health<115,"recovery contact must damage")
  local after=bh.Health; service:Step(47.3,0.1); assert(bh.Health==after,"recovery hit a target twice")
  service:Step(48,0.7)
  local c,ch,cr=rig("Restore",Vector3.new(30,15000,0),100); ch.Health=50
  service:Register(c,true); assert(ch.MaxHealth==115 and ch.Health==57.5)
  service:SetActive(c,false); assert(ch.MaxHealth==100 and ch.Health==50,"morph healed player")
  local target=service.records[b]; br.Anchored=false
  service:Velocity(target,Vector3.new(12,34,0),60,0.2)
  assert((br.AssemblyLinearVelocity-Vector3.new(12,34,0)).Magnitude<0.001,"launch velocity missing")
  br.Anchored=true
 end,debug.traceback)
 service:Destroy(); folder:Destroy(); assert(ok,err)
 print("PASS: combo, passive, landing Slam, four ultimate pulses, ForceField, recovery contact, health restoration, velocity")
end
