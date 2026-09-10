return function()
 local Service=require(game.ServerScriptService.TungCombatService)
 local c=Instance.new("Model"); c.Name="TungSprintValidation"
 local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Anchored=true; r.Position=Vector3.new(0,19000,0); r.Parent=c
 local h=Instance.new("Humanoid"); h.RequiresNeck=false; h.Parent=c
 c:SetAttribute("TungSahurActive",true); c.Parent=workspace
 local service=Service.new(workspace); local s=service:Register(c,true)
 local ok,err=pcall(function()
  assert(not service:SetSprint(c,"true",9),"malformed sprint")
  assert(service:SetSprint(c,true,10) and h.WalkSpeed==28,"sprint start")
  service:Beat(s,10.1); assert(math.abs(h.WalkSpeed-29.12)<.001,"Beat sprint speed")
  assert(service:Request(c,"M1",Vector3.xAxis,10.2)); service:Step(10.35,.15)
  assert(s.sprinting and h.WalkSpeed>28 and h.AutoRotate,"attack cancels sprint")
  s.cooldowns.Q=20
  local action=s.action
  assert(not service:Request(c,"Q",Vector3.xAxis,10.4),"cooldown ability accepted")
  assert(s.action==action,"failed cancel discarded current punch")
  service:SetSprint(c,false,10.45); assert(math.abs(h.WalkSpeed-20.8)<.001,"sprint release")
  service:Step(14,1); assert(h.WalkSpeed==20,"Beat decay walk")
  service:SetSprint(c,true,15); service:SetActive(c,false)
  assert(not s.sprinting and h.WalkSpeed==16,"morph fails to reset sprint")
  assert(not service:SetSprint(c,true,16),"normal avatar sprint hijacked")
 end)
 service:Destroy(); c:Destroy(); assert(ok,err)
 print("PASS: sprint start/release, Beat scaling, combat sprint, invalid cancels, morph cleanup")
end
