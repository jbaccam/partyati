-- Deterministic secondary motion and directional hit tests on cloned fixtures.
return function(package)
	local Pose = require(package.Pose)
	local Motion = require(package.FighterPose)
	local assets = {
		tung_sahur = "TungSahur",
		tralalero = "Tralalero",
		chimpanzini = "Chimpanzini",
		ballerina = "Ballerina",
		bombardiro = "Bombardiro",
	}
	local results = { passed = true, fighters = {}, springChecks = 0 }
	for _, dt in { 1 / 240, 1 / 60, 1 / 20, 0.1 } do
		local x, v = 0, 50
		for _ = 1, math.ceil(3 / dt) do
			x, v = Motion.SpringStep(x, v, 0, dt, 19, 0.48, 0.22)
			assert(x == x and v == v and math.abs(x) <= 0.220001, "Unstable spring")
			results.springChecks += 1
		end
		assert(math.abs(x) < 0.0001 and math.abs(v) < 0.001, "Recoil did not settle")
	end
	for id, asset in assets do
		local character = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name, root.Anchored, root.Parent = "HumanoidRootPart", true, character
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = character
		local visual = assert(package.Assets:FindFirstChild(asset), "Missing asset " .. asset):Clone()
		visual:SetAttribute("FighterId", id)
		visual:SetAttribute("RigProfile", id)
		visual.Parent = character
		local pose = assert(Pose.new(visual), "Pose failed " .. id)
		local now = 500
		local function step(v, ground, dt)
			dt = dt or 1 / 60
			now += dt
			pose:step(
				dt,
				{
					now = now,
					velocity = v,
					grounded = ground,
					state = ground and Enum.HumanoidStateType.Running or Enum.HumanoidStateType.Freefall,
				}
			)
			for name, bone in pose.bones do
				for _, value in { bone.Transform:GetComponents() } do
					assert(value == value and math.abs(value) < 1e6, "Nonfinite secondary pose " .. id .. name)
				end
				local hub = pose.propellerPivots and pose.propellerPivots[name]
				if hub then
					assert((bone.Transform:PointToWorldSpace(hub) - hub).Magnitude < 0.00001, "Propeller hub moved " .. name)
				elseif name ~= "Bone" then
					assert(bone.Transform.Position.Magnitude < 0.0001, "Stretched joint " .. name)
				end
			end
		end
		step(Vector3.zero, true)
		for _ = 1, 20 do
			step(Vector3.new(7, 35, -20), false)
		end
		assert(math.abs(pose.secondary.pitch) > 0.005, id .. " has no jumping lag")
		for _ = 1, 20 do
			step(Vector3.new(7, -40, -20), false)
		end
		step(Vector3.zero, true)
		assert(math.abs(pose.secondary.pitchV) > 0.01, id .. " has no landing follow-through")
		for _ = 1, 100 do
			step(Vector3.zero, true)
		end
		character:SetAttribute("CombatHitAt", now)
		character:SetAttribute("CombatHitDirection", root.CFrame.RightVector)
		step(Vector3.zero, true)
		assert(pose.secondary.hitX > 0 and math.abs(pose.secondary.hitZ) < 0.0001, "Hit direction ignored " .. id)
		local velocityBefore = pose.secondary.hitXV
		Motion.UpdateSecondary(pose, 0, Vector3.zero, false, now, false)
		assert(pose.secondary.hitXV == velocityBefore, "Same hit retriggered " .. id)
		for _ = 1, 150 do
			step(Vector3.zero, true)
		end
		assert(math.abs(pose.secondary.hitX) < 0.0001, "Hit wiggle persists " .. id)
		character:SetAttribute("CombatHitAt", now)
		character:SetAttribute("CombatHitDirection", -root.CFrame.RightVector)
		step(Vector3.zero, true)
		assert(pose.secondary.hitX < 0, "Opposite hit not mirrored " .. id)
		-- Facial controls are not mislabeled as cloth/peel bones.
		if id == "ballerina" or id == "chimpanzini" then
			local names = id == "ballerina" and { "Bone.014", "Bone.015", "Bone.016" }
				or { "Bone.005", "Bone.006", "Bone.007", "Bone.008" }
			for _, name in names do
				assert(pose.bones[name].Transform == CFrame.identity, "Facial distortion " .. name)
			end
		end
		pose:reset()
		for _, bone in pose.bones do
			assert(bone.Transform == CFrame.identity, "Reset failed " .. id)
		end
		results.fighters[id] =
			"Jump lag, landing spring, directional single-trigger hit, decay, unchanged joint lengths"
		character:Destroy()
	end
	return results
end
