return function(package)
 local Pose=require(package.FighterPose)
 local character=Instance.new("Model")
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true;root.Parent=character
 Instance.new("Humanoid",character)
 local visual=package.Assets.Bombardiro:Clone();visual:SetAttribute("FighterId","bombardiro");visual.Parent=character
 local pose=assert(Pose.new(visual));local maximum=0
 local ok,err=pcall(function()
  for _,name in pose.profile.Propellers do
   local hub=pose.propellerPivots[name];assert(hub and hub.Magnitude>.1,"Missing offset-pivot correction")
   local rest=pose.rest[name]
   -- Reject the old orbiting implementation using its actual hub displacement.
   local old=CFrame.fromAxisAngle(rest:VectorToObjectSpace(Vector3.zAxis),math.pi)
   assert((old:PointToWorldSpace(hub)-hub).Magnitude>.2,"Fixture must detect old off-center spin")
   for i=0,72 do
    pose:reset();pose:spinPropeller(name,i*math.pi/36)
    local transform=pose.bones[name].Transform
    local drift=(transform:PointToWorldSpace(hub)-hub).Magnitude
    maximum=math.max(maximum,drift);assert(drift<.00001,"Hub orbits the engine")
    local tip=hub+rest:VectorToObjectSpace(Vector3.xAxis*.4)
    assert(math.abs((transform:PointToWorldSpace(tip)-hub).Magnitude-.4)<.00001,"Blade radius changes")
   end
  end
 end)
 character:Destroy();assert(ok,err)
 return {propellers=4,phaseSamples=292,maximumHubDrift=maximum}
end
