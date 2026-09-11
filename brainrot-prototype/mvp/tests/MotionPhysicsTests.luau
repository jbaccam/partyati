-- Real unanchored physics fixtures, not just a mocked motion callback.
return function()
 local Service=require(game.ServerScriptService.TungCombatService)
 local folder=Instance.new("Folder");folder.Name="MVPDrivePhysicsTests";folder.Parent=workspace
 local floor=Instance.new("Part");floor.Size=Vector3.new(200,2,200);floor.Position=Vector3.new(22000,1000,22000);floor.Anchored=true;floor.Parent=folder
 local model=Instance.new("Model");model.Name="MotionFixture"
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,2);root.Position=floor.Position+Vector3.new(0,5,0);root.Parent=model
 local h=Instance.new("Humanoid");h.RequiresNeck=false;h.HipHeight=2;h.Parent=model
 model.PrimaryPart=root;model:SetAttribute("FighterId","tralalero");model:SetAttribute("TungSahurActive",true);model.Parent=folder
 local svc=Service.new(workspace);local s=svc:Register(model,true)
 local connection=game.RunService.Heartbeat:Connect(function(dt) svc:Step(workspace:GetServerTimeNow(),dt) end)
 local result={}
 local ok,err=xpcall(function()
  task.wait(.5)
  local start=root.Position
  assert(svc:Drive(s,-Vector3.zAxis,62,.42,workspace:GetServerTimeNow(),{lift=2,mode="Torpedo"}))
  task.wait(.48)
  result.torpedoTravel=(Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(start.X,0,start.Z)).Magnitude
  assert(result.torpedoTravel>20 and result.torpedoTravel<36,"Torpedo must actually cover 20+ studs, not jolt")
  assert(not root:FindFirstChild("AbilityDriveVelocity") and not s.drive,"Dash constraint leaked")
  root.CFrame=CFrame.new(floor.Position+Vector3.new(0,6,20));root.AssemblyLinearVelocity=Vector3.zero
  local wall=Instance.new("Part");wall.Anchored=true;wall.Size=Vector3.new(20,16,2);wall.Position=floor.Position+Vector3.new(0,8,10);wall.Parent=folder
  svc:Drive(s,-Vector3.zAxis,62,.42,workspace:GetServerTimeNow(),{mode="Torpedo"})
  task.wait(.5);assert(root.Position.Z>wall.Position.Z+1,"Dash tunneled through wall");assert(not s.drive,"Wall did not cancel")
  wall:Destroy()
  root.CFrame=CFrame.new(floor.Position+Vector3.new(0,20,20));root.AssemblyLinearVelocity=Vector3.zero
  local y=root.Position.Y
  svc:Drive(s,-Vector3.zAxis,32,1.6,workspace:GetServerTimeNow(),{vertical=8,lift=24,mode="Flight"})
  task.wait(1.3);result.flightRise=root.Position.Y-y;assert(s.drive and result.flightRise>8,"Powered flight did not sustain lift")
  task.wait(.5);assert(not s.drive and not root:FindFirstChild("AbilityDriveVelocity"),"Flight never expired")
  task.wait(.25);assert(root.AssemblyLinearVelocity.Y<0,"Gravity did not resume after flight")
  root.CFrame=CFrame.new(floor.Position+Vector3.new(0,20,20));root.AssemblyLinearVelocity=Vector3.zero
  local glideStart=root.Position.Y
  svc:Drive(s,-Vector3.zAxis,28,1.25,workspace:GetServerTimeNow(),{vertical=12,lift=24,mode="Glide"})
  task.wait(.8);result.glideRise=root.Position.Y-glideStart
  assert(result.glideRise>7,"Peel Glide failed to fly upward")
  svc:Velocity(s,Vector3.new(20,20,0),workspace:GetServerTimeNow(),.3)
  assert(not s.drive and not root:FindFirstChild("AbilityDriveVelocity"),"Hit did not interrupt glide")
  svc:Drive(s,-Vector3.zAxis,32,1.6,workspace:GetServerTimeNow(),{vertical=8,mode="Flight"})
  svc:SetActive(model,false);assert(not root:FindFirstChild("AbilityDriveVelocity"),"Unmorph retained flight")
 end,debug.traceback)
 connection:Disconnect();svc:Destroy();folder:Destroy();assert(ok,err)
 return result
end
