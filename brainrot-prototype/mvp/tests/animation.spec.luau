-- Pass the shared package. Clones fixtures only; no live players/assets mutated.
return function(package)
	local Pose = require(package.Pose)
	local Profiles = require(package.FighterRigProfiles)
	local Definitions = require(package.FighterDefinitions)
	local assets =
		{ tralalero = "Tralalero", chimpanzini = "Chimpanzini", ballerina = "Ballerina", bombardiro = "Bombardiro" }
	local results = { passed = true, finiteChecks = 0, fighters = {} }
	for id, asset in assets do
		local character = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Parent = character
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = character
		local visual = assert(package.Assets:FindFirstChild(asset), "Missing asset " .. asset):Clone()
		visual:SetAttribute("FighterId", id)
		visual:SetAttribute("RigProfile", id)
		visual.Parent = character
		local pose = assert(Pose.new(visual), "Failed distinct skeleton dispatch " .. id)
		local checks = 0
		local seen = {}
		local changed = {}
		local function sample(v, grounded, state, now)
			assert(pose:step(1 / 60, { velocity = v, grounded = grounded, state = state, now = now or 100 }))
			seen[pose.state] = true
			for name, bone in pose.bones do
				for _, number in { bone.Transform:GetComponents() } do
					assert(number == number and math.abs(number) < 1e6, "Nonfinite " .. id .. " " .. name)
					checks += 1
				end
				if bone.Transform ~= CFrame.identity then
					changed[name] = true
				end
				-- Rotation only in joints; never stretch an arm or leg toward a target.
				local hub = pose.propellerPivots and pose.propellerPivots[name]
				if hub then
					assert((bone.Transform:PointToWorldSpace(hub) - hub).Magnitude < 0.00001, "Propeller hub moved " .. name)
				elseif name ~= Profiles[id].Root then
					assert(bone.Transform.Position.Magnitude < 0.00001, "Joint translation stretches " .. name)
				end
			end
		end
		for _, speed in { 0, 8, 20, 30 } do
			character:SetAttribute("Sprinting", speed >= 28)
			for _ = 1, 60 do
				sample(Vector3.new(0, 0, -speed), true, Enum.HumanoidStateType.Running)
			end
		end
		for _ = 1, 30 do
			sample(Vector3.new(4, 35, -15), false, Enum.HumanoidStateType.Jumping)
		end
		for _ = 1, 30 do
			sample(Vector3.new(4, -25, -15), false, Enum.HumanoidStateType.Freefall)
		end
		for _ = 1, 40 do
			sample(Vector3.zero, true, Enum.HumanoidStateType.Running)
		end
		for _, action in { "M1", "Q", "E", "R", "F" } do
			character:SetAttribute("CombatAction", action)
			character:SetAttribute("CombatActionAt", 100)
			for combo = 1, (action == "M1" and 3 or 1) do
				character:SetAttribute("CombatCombo", combo)
				local duration = action == "F" and Definitions.ById[id].Ultimate.Duration or 1.2
				for frame = 0, math.ceil(duration * 60) do
					sample(Vector3.zero, true, Enum.HumanoidStateType.Running, 100 + frame / 60)
				end
			end
		end
		character:SetAttribute("CombatAction", "")
		sample(Vector3.zero, true, Enum.HumanoidStateType.Seated)
		sample(Vector3.zero, false, Enum.HumanoidStateType.Dead)
		for _, state in { "Idle", "Walk", "Jump", "Fall", "Land", "Rest", "Dead", "M1", "Q", "E", "R", "F" } do
			assert(seen[state], id .. " missing " .. state)
		end
		local n = 0
		for _ in changed do
			n += 1
		end
		assert(n >= 5, id .. " must articulate at least five bones, not slide rigidly")
		if Profiles[id].Legs then
			for _, leg in Profiles[id].Legs do
				for _, name in leg do
					assert(changed[name], "Inactive leg " .. id .. " " .. name)
				end
			end
		end
		pose:reset()
		for _, bone in pose.bones do
			assert(bone.Transform == CFrame.identity, "Reset failed")
		end
		results.finiteChecks += checks
		results.fighters[id] = { animatedBones = n, requiredBones = #Profiles[id].Required, states = seen }
		character:Destroy()
	end
	return results
end
