-- Isolated animation-state regression; no live players, damage, or physics changes.
return function()
 local package=game.ReplicatedStorage.TungPrototype
 local fresh=package.CombatPose:Clone(); fresh.Name="CombatPoseContactTest"; fresh.Parent=package
 local character=Instance.new("Model")
 local pose={visual={Parent=character},humanoid={Health=115,FloorMaterial=Enum.Material.Slate,MoveDirection=Vector3.zero,WalkSpeed=18},bones={},speed=0,air=1}
 for _,p in package.CombatAnimations.E:GetDescendants() do
  if p:IsA("Pose") and p.Name~="Mesh" then pose.bones[p.Name]={Transform=CFrame.identity} end
 end
 local ok,err=pcall(function()
  local playback=require(fresh)
  local function step(t) playback.apply(pose,t,1/60) end
  character:SetAttribute("CombatAction","E"); character:SetAttribute("CombatActionAt",10)
  step(10); assert(pose._slamLandingAt==nil,"landed during grounded startup")
  pose.humanoid.FloorMaterial=Enum.Material.Air; step(10.05); step(10.2)
  assert(pose.state=="E" and pose._slamLandingAt==nil,"landed while airborne")
  pose.humanoid.FloorMaterial=Enum.Material.Slate; step(10.27)
  assert(pose.state=="SlamLand" and pose._slamLandingAt==10.27,"contact did not start landing")
  local landingKey=pose._combatKey
  step(10.3); assert(pose._combatKey==landingKey,"repeated contact restarted landing")
  character:SetAttribute("CombatAction","SlamLand"); character:SetAttribute("CombatActionAt",10.55)
  step(10.55); assert(pose._combatKey==landingKey and pose._slamLandingAt==10.27,"confirmation replayed slam")
  character:SetAttribute("CombatAction",""); step(10.9)
  assert(pose._slamLandingAt==nil and pose._slamCastAt==nil,"landing state leaked")
  character:SetAttribute("CombatAction","E"); character:SetAttribute("CombatActionAt",11)
  pose.humanoid.FloorMaterial=Enum.Material.Air; step(11.05); step(12)
  assert(pose.state=="E" and pose._slamLandingAt==nil,"high fall used timed landing")
  pose.humanoid.FloorMaterial=Enum.Material.Slate; step(12.1)
  assert(pose._slamLandingAt==12.1,"aerial cast failed to land")
  character:SetAttribute("CombatAction","Q"); character:SetAttribute("CombatActionAt",12.15); step(12.15)
  assert(pose.state=="Q" and pose._slamLandingAt==nil,"other action inherited slam")
 end)
 fresh:Destroy(); character:Destroy(); assert(ok,err)
 return "PASS: contact landing, no startup/airborne false land, no confirmation replay, high falls, action cleanup"
end

