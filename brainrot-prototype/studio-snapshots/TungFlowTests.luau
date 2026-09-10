return function()
 local Service=require(game.ServerScriptService.TungCombatService)
 local c=Instance.new("Model"); c.Name="TungFlowTest"
 local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Anchored=true; r.Position=Vector3.new(0,18000,0); r.Parent=c
 local h=Instance.new("Humanoid"); h.RequiresNeck=false; h.Parent=c
 c:SetAttribute("TungSahurActive",true); c.Parent=workspace
 local s=Service.new(workspace); local state=s:Register(c,true)
 local ok,err=pcall(function()
  assert(s:Request(c,"M1",Vector3.xAxis,10))
  assert(h.AutoRotate,"M1 disabled steering")
  assert(r.CFrame.LookVector:Dot(Vector3.new(0,0,-1))>.99,"M1 snapped character facing")
  assert(state.owned==nil,"M1 seized character physics")
  s:Step(10.12,.12)
  assert(s:Request(c,"M1",Vector3.xAxis,10.2),"early combo input was dropped")
  s:Step(10.29,.17)
  assert(state.combo==2,"buffered second hit did not execute")
  s:Step(10.43,.14)
  assert(s:Request(c,"Q",Vector3.xAxis,10.48),"ability cancel window rejected")
  assert(state.action.key=="Q","ability cancel did not transition")
  assert(h.AutoRotate and state.owned==nil,"Q locked movement")
  r.Anchored=false; r.AssemblyLinearVelocity=Vector3.new(12,0,7)
  assert(s:Request(c,"Jump",Vector3.xAxis,10.6),"attack recovery blocked air jump")
  local v=r.AssemblyLinearVelocity
  assert(math.abs(v.X-12)<.001 and math.abs(v.Z-7)<.001 and v.Y==52,"air jump erased horizontal movement")
  assert(state.action.key=="Q" and state.owned==nil,"air jump interrupted attack or seized physics")
  s:Step(11.1,.5)
  for i,key in {"M1","Q","R","E","F"} do
   state.action=nil; state.busyUntil=0; state.cooldowns={}; state.core=true; state.recoveryUsed=false
   local now=20+i*10
   local before=CFrame.new(0,18000,0)*CFrame.Angles(0,.73,0)
   r.CFrame=before; r.AssemblyLinearVelocity=Vector3.new(12,2,7)
   assert(s:Request(c,key,Vector3.xAxis,now),key.." rejected")
   assert(h.AutoRotate and state.owned==nil,key.." locked steering/ownership")
   assert(r.CFrame==before,key.." snapped facing")
   local v=r.AssemblyLinearVelocity
   assert(math.abs(v.X-12)<.001 and math.abs(v.Z-7)<.001,key.." replaced horizontal speed")
   if key=="M1" or key=="Q" or key=="F" then assert(math.abs(v.Y-2)<.001,key.." changed velocity") end
   if key=="E" then s:Step(now+.2,.2); assert(r.AssemblyLinearVelocity.Y==-48 and r.AssemblyLinearVelocity.X==12,"Slam dive removed steering") end
  end
  r.Anchored=true
 end)
 s:Destroy(); c:Destroy(); assert(ok,err); print("PASS: free movement for all attacks, combo buffer, ability cancel, air jump during recovery, horizontal steering")
end
