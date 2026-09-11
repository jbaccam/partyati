-- Real asset bone checks. These establish articulated, continuous choreography,
-- not subjective visual approval or skin-weight quality.
return function(package)
	local Pose = require(package.FighterPose)
	local Definitions = require(package.FighterDefinitions)
	local results = { passed = true, fighters = {} }
	for _, id in { "tralalero", "chimpanzini", "ballerina", "bombardiro" } do
		local character = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name, root.Anchored, root.Parent = "HumanoidRootPart", true, character
		Instance.new("Humanoid", character)
		local definition = Definitions.ById[id]
		local visual = package.Assets[definition.AssetName]:Clone()
		visual:SetAttribute("FighterId", id)
		visual.Parent = character
		local pose = assert(Pose.new(visual), "Missing ultimate rig " .. id)
		local p, duration = pose.profile, definition.Ultimate.Duration
		local function angle(name)
			local rotation = pose.rest[name].Rotation
				* pose.bones[name].Transform.Rotation
				* pose.rest[name].Rotation:Inverse()
			local axis, radians = rotation:ToAxisAngle()
			return axis * radians
		end
		local function sample(time)
			pose:reset()
			assert(pose:attack("F", time, 1))
		end
		local animatedFrames, frames = 0, 0
		for frame = 1, math.floor(duration * 60) - 1 do
			sample(frame / 60)
			local articulated = 0
			for name, bone in pose.bones do
				assert(bone.Transform.Position.Magnitude < 0.00001, id .. " ultimate stretches joints")
				local axis, radians = bone.Transform:ToAxisAngle()
				assert(axis.X == axis.X and radians == radians, "Nonfinite ultimate")
				if name ~= p.Root and math.abs(radians) > 0.12 then
					articulated += 1
				end
			end
			frames += 1
			if articulated >= 2 then
				animatedFrames += 1
			end
		end
		assert(animatedFrames / frames > 0.80, id .. " has long unanimated ultimate gaps")
		if id == "tralalero" then
			for _, at in { 0.45, 1.1, 1.75 } do
				sample(at - 0.16)
				local opening = angle(p.Jaw).Magnitude
				sample(at + 0.035)
				assert(opening > 0.9 and angle(p.Jaw).Magnitude < opening * 0.45, "Frenzy jaw missing open/snap")
				assert(angle(p.Legs[1][2]).X < -0.5, "Frenzy has no leg silhouette")
			end
		elseif id == "chimpanzini" then
			for _, at in { 0.6, 1.3, 2 } do
				sample(at)
				assert(angle(p.TailTip).Magnitude > 0.65, "Barrage release has no peel whip")
				assert(angle(p.Spine).X < -0.35, "Barrage release has no body followthrough")
				for _, name in { "Bone.005", "Bone.006", "Bone.007", "Bone.008" } do
					assert(pose.bones[name].Transform == CFrame.identity, "Ultimate distorts banana face")
				end
			end
		elseif id == "ballerina" then
			sample(2.2)
			assert(angle(p.Legs[2][1]).Magnitude > 1.2, "Finale has no final kick")
			assert(angle(p.Arms[1][1]).Magnitude > 0.9, "Finale arms not extended")
		elseif id == "bombardiro" then
			for _, at in { 1.05, 1.85, 2.65 } do
				sample(at)
				assert(angle(p.Wings[1]).Magnitude > 0.45, "Bombardment has no wing recoil")
				assert(angle(p.Head).X > 0.20, "Bombardment has no head recoil")
			end
		end
		sample(duration)
		for _, bone in pose.bones do
			local _, radians = bone.Transform:ToAxisAngle()
			assert(math.abs(radians) < 0.0001, id .. " ultimate fails to return to rest")
		end
		assert(not pose:attack("F", duration + 0.01, 1), "Ultimate never expires")
		results.fighters[id] = { articulatedCoverage = animatedFrames / frames, duration = duration }
		character:Destroy()
	end
	return results
end
