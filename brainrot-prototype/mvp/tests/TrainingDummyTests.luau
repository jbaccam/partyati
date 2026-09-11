return function()
 local Dummy=require(game.ServerScriptService.TrainingDummy)
 local folder=Instance.new("Folder");folder.Name="MVPTrainingDummyTests";folder.Parent=workspace
 local floor=Instance.new("Part");floor.Size=Vector3.new(100,2,100);floor.Position=Vector3.new(24000,1000,24000);floor.Anchored=true;floor.Parent=folder
 local model=Instance.new("Model");model.Name="DummyFixture"
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,2);root.Anchored=true
 root.CFrame=CFrame.new(floor.Position+Vector3.new(0,4,0));root.Parent=model;model.PrimaryPart=root
 local mesh=Instance.new("Part");mesh.Name="VisualFixture";mesh.Size=Vector3.one;mesh.CFrame=root.CFrame*CFrame.new(0,1,0);mesh.Anchored=true;mesh.Parent=model
 local h=Instance.new("Humanoid");h.RequiresNeck=false;h.MaxHealth=100;h.Health=100;h.Parent=model;model.Parent=folder
 local control=Dummy.new(model,{autoStep=false})
 local result={}
 local ok,err=xpcall(function()
  assert(not root.Anchored and not mesh.Anchored and root.CanCollide,"Target still anchored or falls through ground")
  assert(mesh:FindFirstChild("TrainingDummyWeld"),"Visual does not follow physical root")
  assert(root:GetNetworkOwner()==nil and not root:GetNetworkOwnershipAuto(),"Target must remain server owned")
  task.wait(.25)
  local start=root.Position;root.AssemblyLinearVelocity=Vector3.new(42,22,0)
  task.wait(.15);result.knockbackTravel=(root.Position-start).Magnitude
  assert(result.knockbackTravel>2,"Real impulse did not move target")
  local now=workspace:GetServerTimeNow()
  h:TakeDamage(10);model:SetAttribute("LastCombatAt",now);control:Step(now)
  control:Step(now+3.9)
  assert(h.Health==90,"Target healed during combat")
  assert((root.Position-control.home.Position).Magnitude>2,"Target returned too early")
  model:SetAttribute("LastCombatAt",now+3.9);control:Step(now+3.9)
  control:Step(now+4.1);assert(h.Health==90,"New hit failed to postpone reset")
  control:Step(now+8)
  assert((root.Position-control.home.Position).Magnitude<.01,"Target did not return home")
  assert(root.AssemblyLinearVelocity.Magnitude<.01 and root.AssemblyAngularVelocity.Magnitude<.01,"Reset retained momentum")
  assert(h.Health==h.MaxHealth and not root.Anchored,"Reset must heal and stay hittable")
  local old=model;h.Health=0;control:Step(now+9);control:Step(now+10.1)
  assert(control.target~=old and not old.Parent,"Dead Humanoid was not rebuilt")
  assert(control.humanoid.Health>0 and not control.root.Anchored,"Dead reset remained dead or anchored")
  assert(game.CollectionService:HasTag(control.target,"BrainrotCombatTarget"),"Respawn lost combat registration")
  local replacement=control.target
  control.root.CFrame=CFrame.new(control.home.Position-Vector3.new(0,40,0))
  control:Step(now+11);control:Step(now+12.1)
  assert(control.target~=replacement and control.root.Position.Y>control.ringOutY,"Void reset failed")
 end,debug.traceback)
 control:Destroy();folder:Destroy();assert(ok,err)
 result.idleReturnSeconds=4;result.deathAndVoidRespawn=true
 return result
end
