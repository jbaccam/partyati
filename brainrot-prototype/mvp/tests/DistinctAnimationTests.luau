-- Inspect the actual reviewed asset Bone.Transforms at server damage frames.
-- This supplements (does not replace) client visual QA of motion and skin weights.
return function(package)
	local Pose = require(package.FighterPose)
	local Definitions = require(package.FighterDefinitions)
	local results = { passed = true, fighters = {} }
	for _, id in { "tralalero", "chimpanzini", "ballerina", "bombardiro" } do
		local character = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name, root.Anchored, root.Parent = "HumanoidRootPart", true, character
		Instance.new("Humanoid", character)
		local def = Definitions.ById[id]
		local visual = assert(package.Assets:FindFirstChild(def.AssetName)):Clone()
		visual:SetAttribute("FighterId", id)
		visual.Parent = character
		local pose = assert(Pose.new(visual), "Missing skeleton " .. id)
		local p = pose.profile
		local function angle(name)
			local b = pose.bones[name]
			local rotation = pose.rest[name].Rotation * b.Transform.Rotation * pose.rest[name].Rotation:Inverse()
			local axis, radians = rotation:ToAxisAngle()
			return axis * radians
		end
		local function sample(action, time, combo)
			pose:reset()
			pose.motionLayer = false
			assert(pose:attack(action, time, combo or 1), id .. " missing active " .. action)
			for name, bone in pose.bones do
				assert(name == p.Root or bone.Transform.Position.Magnitude < 0.00001, "Joint stretched " .. name)
			end
		end
		local duration, hit = Pose.ActionTiming(id, "M1", 1)
		assert(duration == def.Basic.Recovery and hit == def.Basic.HitTimes[1], "Timing not shared with server")
		if id == "tralalero" then
			sample("M1", hit * 0.52)
			local open = angle(p.Jaw).Magnitude
			sample("M1", hit)
			assert(open > 0.6 and angle(p.Jaw).Magnitude < open * 0.4, "Bite must close at damage, not open after it")
			sample("M1", def.Basic.HitTimes[3], 3)
			assert(angle(p.Tail).Magnitude > 0.8, "Third snap missing tail strike")
			sample("Q", 0.25)
			assert(angle(p.Root).X < -0.30 and angle(p.Jaw).X < -0.5, "Torpedo not visibly pitched/open")
			for _, leg in p.Legs do
				assert(angle(leg[1]).X < -0.8, "Torpedo sneaker not swept back")
			end
			local tailHit = def.Abilities.E.HitTime
			sample("E", tailHit)
			assert(angle(p.Tail).Magnitude > 0.95, "Launcher has no tail bend at impact")
			local rotation = pose.rest[p.Root].Rotation
				* pose.bones[p.Root].Transform.Rotation
				* pose.rest[p.Root].Rotation:Inverse()
			assert(rotation.LookVector.Z > 0.99, "Tail is not facing the hit area at impact")
			sample("E", def.Abilities.E.Duration)
			assert(angle(p.Root).Magnitude < 0.0001, "Tail spin does not return cleanly to neutral")
		elseif id == "ballerina" then
			sample("M1", hit, 1)
			assert(angle(p.Legs[1][1]).X > 1 and angle(p.Legs[2][1]).Magnitude < 0.01, "Left kick not isolated")
			assert(math.abs(angle(p.Arms[1][1]).X) < 0.2, "M1 still animates as a punch")
			sample("M1", def.Basic.HitTimes[2], 2)
			assert(angle(p.Legs[2][1]).X > 1 and angle(p.Legs[1][1]).Magnitude < 0.01, "Right kick not isolated")
			sample("M1", def.Basic.HitTimes[3], 3)
			assert(angle(p.Legs[1][1]).X > 1.4, "Heavy kick missing extension")
			sample("R", 0.13)
			assert(angle(p.Legs[1][1]).X > 1 and angle(p.Legs[2][1]).X < -0.6, "First air step absent")
			sample("R", 0.53)
			assert(angle(p.Legs[2][1]).X > 1 and angle(p.Legs[1][1]).X < -0.6, "Second air step not alternating")
		elseif id == "chimpanzini" then
			sample("M1", hit, 1)
			assert(angle(p.Tail).Z > 0.65 and angle(p.TailTip).Z < -0.4, "First peel lash absent")
			sample("M1", def.Basic.HitTimes[2], 2)
			assert(angle(p.Tail).Z < -0.65 and angle(p.TailTip).Z > 0.4, "Second peel lash not mirrored")
			sample("M1", def.Basic.HitTimes[3], 3)
			assert(angle(p.TailTip).Magnitude > 0.8, "Projectile flick missing at release")
			for _, name in { "Bone.005", "Bone.006", "Bone.007", "Bone.008" } do
				assert(pose.bones[name].Transform == CFrame.identity, "Fake peel control distorts face")
			end
		elseif id == "bombardiro" then
			sample("M1", hit * 0.60)
			local open = angle(p.Jaw).Magnitude
			assert(open > 0.85, "Heavy chomp lacks readable windup")
			sample("M1", hit)
			assert(angle(p.Jaw).Magnitude < open * 0.2, "Jaw does not snap shut at .27 damage frame")
			for _, wing in p.Wings do
				assert(angle(wing).Magnitude < 0.01, "Heavy chomp still uses wing punches")
			end
		end
		-- The whole sustained movement animation must outlast the old .65s boost.
		local rDuration = def.Abilities.R.Duration
		sample("R", rDuration - 0.10)
		assert(not pose:attack("R", rDuration + 0.01, 1), "Recovery animation does not expire")
		if id == "bombardiro" or id == "chimpanzini" then
			character:SetAttribute("AbilityMotionMode", id == "bombardiro" and "Flight" or "Glide")
			character:SetAttribute("AbilityMotionAt", 10)
			character:SetAttribute("AbilityMotionUntil", 12)
			character:SetAttribute("CombatAction", "M1")
			character:SetAttribute("CombatActionAt", 10)
			for frame = 1, 20 do
				pose:step(
					1 / 60,
					{
						now = 10 + frame / 60,
						velocity = Vector3.new(0, 0, -28),
						grounded = false,
						state = Enum.HumanoidStateType.Freefall,
					}
				)
			end
			assert(pose.motionLayer and pose.motionBlend > 0.95, "Attacking removed flight/glide posture")
			if id == "bombardiro" then
				assert(angle(p.Wings[1]).Magnitude > 0.2, "Wings folded during airborne M1")
			else
				assert(angle(p.TailTip).Magnitude > 0.65, "Banana glide collapsed during M1")
			end
		end
		results.fighters[id] = { hitTime = hit, basicDuration = duration, recoveryDuration = rDuration }
		character:Destroy()
	end
	return results
end
