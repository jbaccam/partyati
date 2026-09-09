-- Run with the Pose module and reviewed template, in Studio.
-- No persistent data, live players, or source assets are modified.
return function(Pose, template)
	local character = Instance.new("Model")
	character.Name = "TungPoseTestFixture"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Parent = character
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	local visual = template:Clone()
	visual.Parent = character
	local pose = assert(Pose.new(visual), "Expected all 15 rig bones")
	local observations = {}
	local checks = 0
	local greatestHip = 0
	local leastHip = math.huge
	local function sample(velocity, grounded, state)
		assert(pose:step(1/60, {velocity=velocity, grounded=grounded, state=state}))
		observations[pose.state] = true
		for _, bone in pose.bones do
			for _, value in {bone.Transform:GetComponents()} do
				assert(value == value and math.abs(value) < 1e6, "Non-finite transform")
				checks += 1
			end
		end
		local _, angle = pose.bones["Bone.009"].Transform:ToAxisAngle()
		greatestHip = math.max(greatestHip, angle)
		leastHip = math.min(leastHip, angle)
	end
	for _, speed in {0, 4, 8, 16, 24, 32} do
		for _ = 1, 120 do sample(Vector3.new(0,0,-speed), true, Enum.HumanoidStateType.Running) end
	end
	for _ = 1, 30 do sample(Vector3.new(0,30,-16), false, Enum.HumanoidStateType.Jumping) end
	for _ = 1, 30 do sample(Vector3.new(0,-25,-16), false, Enum.HumanoidStateType.Freefall) end
	for _ = 1, 60 do sample(Vector3.zero, true, Enum.HumanoidStateType.Running) end
	for _ = 1, 60 do sample(Vector3.new(16,0,0), true, Enum.HumanoidStateType.Running) end
	for _ = 1, 60 do sample(Vector3.new(0,0,16), true, Enum.HumanoidStateType.Running) end
	for _, name in {"Idle","Walk","Jump","Fall","Land"} do assert(observations[name], "Missing "..name) end
	assert(greatestHip-leastHip > 0.3, "Leg skeleton must actually articulate")
	sample(Vector3.zero, true, Enum.HumanoidStateType.Seated)
	assert(pose.state == "Rest", "Seated fallback")
	sample(Vector3.zero, false, Enum.HumanoidStateType.Dead)
	assert(pose.state == "Dead", "Death fallback")
	pose:reset()
	for _, bone in pose.bones do assert(bone.Transform == CFrame.identity) end
	character:Destroy()
	return {passed=true, finiteComponentChecks=checks, states=observations, hipRange=greatestHip-leastHip}
end

