-- Procedural skeletal animation: every client poses all replicated Tung visuals.
-- Bone.Transform is local-only; no client-supplied poses or per-frame remotes.
local CombatPose = require(script.Parent:WaitForChild("CombatPose"))
local ArmClearance = require(script.Parent.ArmClearance)
local RigProfiles = require(script.Parent.RigProfiles)
local FighterPose = require(script.Parent.FighterPose)
local Pose = {}
local PI = math.pi
local TAU = 2 * PI
local IDENTITY = CFrame.identity
local X = Vector3.xAxis
local FORWARD = Vector3.new(0, 0, -1)

local function smooth(current, target, rate, dt)
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

local function fromTo(a, b)
	if a.Magnitude < 1e-6 or b.Magnitude < 1e-6 then
		return IDENTITY
	end
	a, b = a.Unit, b.Unit
	local dot = math.clamp(a:Dot(b), -1, 1)
	if dot > 0.999999 then
		return IDENTITY
	end
	local axis = a:Cross(b)
	if axis.Magnitude < 1e-6 then
		axis = a:Cross(Vector3.xAxis)
		if axis.Magnitude < 1e-6 then
			axis = a:Cross(Vector3.zAxis)
		end
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
end

function Pose.new(visual)
	local fighterId = visual:GetAttribute("FighterId") or visual:GetAttribute("RigProfile")
	if fighterId and fighterId ~= "tung_sahur" then
		return FighterPose.new(visual)
	end
	local character = visual.Parent
	local mesh = visual:FindFirstChild("Mesh")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not mesh or not root or not humanoid then
		return nil
	end
	local self = {
		visual = visual,
		mesh = mesh,
		root = root,
		humanoid = humanoid,
		rigProfile = RigProfiles[visual:GetAttribute("RigProfile") or "tung_sahur"],
		bones = {},
		rest = {},
		phase = 0,
		time = 0,
		speed = 0,
		moving = 0,
		air = 0,
		landing = 0,
		wasAir = false,
		lean = 0,
		side = 0,
		dead = 0,
		state = "Idle",
	}
	for _, b in mesh:GetDescendants() do
		if b:IsA("Bone") then
			self.bones[b.Name] = b
			self.rest[b.Name] = mesh.CFrame:ToObjectSpace(b.WorldCFrame)
		end
	end
	for _, name in
		{
			"Bone",
			"Bone.001",
			"Bone.002",
			"Bone.003",
			"Bone.004",
			"Bone.005",
			"Bone.006",
			"Bone.007",
			"Bone.008",
			"Bone.009",
			"Bone.010",
			"Bone.011",
			"Bone.012",
			"Bone.013",
			"Bone.014",
		}
	do
		if not self.bones[name] then
			return nil
		end
	end
	return setmetatable(self, { __index = Pose })
end

function Pose:rotate(name, axis, angle)
	local bone = self.bones[name]
	local localAxis = self.rest[name]:VectorToObjectSpace(axis)
	bone.Transform = CFrame.fromAxisAngle(localAxis, angle)
end

function Pose:leg(hipName, kneeName, footName, target, pelvis, footPitch)
	local hip, knee, foot = self.bones[hipName], self.bones[kneeName], self.bones[footName]
	local preHip = pelvis * hip.CFrame
	local hipPosition = preHip.Position
	local a, b = knee.CFrame.Position.Magnitude, foot.CFrame.Position.Magnitude
	local difference = target - hipPosition
	local distance = math.clamp(difference.Magnitude, math.abs(a - b) + 0.001, (a + b) * 0.997)
	local direction = difference.Magnitude > 0.001 and difference.Unit or -Vector3.yAxis
	target = hipPosition + direction * distance
	local bend = FORWARD - direction * FORWARD:Dot(direction)
	if bend.Magnitude < 0.001 then
		bend = Vector3.yAxis
	end
	bend = bend.Unit
	local along = (a * a + distance * distance - b * b) / (2 * distance)
	local away = math.sqrt(math.max(0, a * a - along * along))
	local kneePosition = hipPosition + direction * along + bend * away
	hip.Transform = fromTo(knee.CFrame.Position, preHip:VectorToObjectSpace(kneePosition - hipPosition))
	local posedHip = preHip * hip.Transform
	local preKnee = posedHip * knee.CFrame
	knee.Transform = fromTo(foot.CFrame.Position, preKnee:VectorToObjectSpace(target - preKnee.Position))
	local preFoot = preKnee * knee.Transform * foot.CFrame
	-- Feet stay level through the stance; swing toes lift with the step.
	foot.Transform = preFoot.Rotation:Inverse() * CFrame.fromAxisAngle(X, footPitch) * self.rest[footName].Rotation
end

function Pose:step(dt, sample)
	dt = math.clamp(dt, 0, 0.1)
	if not self.visual.Parent or not self.root.Parent then
		return false
	end
	self.time += dt
	local humanoid, root = self.humanoid, self.root
	local velocity = sample and sample.velocity or root.AssemblyLinearVelocity
	local state = sample and sample.state or humanoid:GetState()
	local grounded
	if sample then
		grounded = sample.grounded
	else
		grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	end
	local disabled = state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Climbing
	local isDead = humanoid.Health <= 0 or state == Enum.HumanoidStateType.Dead
	local air = not grounded and not disabled and not isDead
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = disabled and 0 or math.min(horizontal.Magnitude, 36)
	self.speed = smooth(self.speed, speed, 12, dt)
	self.moving = smooth(self.moving, math.clamp(self.speed / 3, 0, 1), 12, dt)
	self.air = smooth(self.air, air and 1 or 0, 14, dt)
	self.dead = smooth(self.dead, isDead and 1 or 0, 6, dt)
	if self.wasAir and not air then
		self.landing = 1
	end
	self.wasAir = air
	self.landing *= math.exp(-10 * dt)
	local localVelocity = root.CFrame:VectorToObjectSpace(horizontal)
	local forward = speed > 0.25 and math.clamp(-localVelocity.Z / speed, -1, 1) or 1
	local sideways = speed > 0.25 and math.clamp(localVelocity.X / speed, -1, 1) or 0
	self.lean = smooth(self.lean, forward * math.min(speed / 24, 1), 8, dt)
	self.side = smooth(self.side, sideways, 8, dt)
	-- Grounded sprint adds a forward hunch and stronger arm drive, easing out on release.
	local sprinting = self.visual.Parent:GetAttribute("Sprinting") == true
	self.sprint = smooth(self.sprint or 0, sprinting and 1 or 0, 10, dt)
	local run = self.sprint
	local stride = 0.68 + 0.12 * math.clamp((self.speed - 10) / 14, 0, 1)
	-- One full gait travels four half-strides; step frequency follows ground speed.
	local cycles = math.min(self.speed / (4 * stride), 5.5)
	self.phase = (self.phase + cycles * dt * (1 - self.air)) % 1
	local move = self.moving * (1 - self.air) * (1 - self.dead)
	local angle = self.phase * TAU
	local breath = math.sin(self.time * 2.3)
	local crouch = -(0.12 + 0.05 * run) * move - 0.20 * self.landing - 0.08 * self.air
	local bob = 0.045 * (1 - move) * breath + 0.035 * math.cos(angle * 2) * move
	local pelvis = self.bones.Bone
	pelvis.Transform = CFrame.new(0, crouch + bob, 0)
		* CFrame.Angles(0, math.sin(angle) * 0.04 * move, -0.035 * math.cos(angle) * move)
	local posedPelvis = pelvis.CFrame * pelvis.Transform
	self:rotate(
		"Bone.001",
		X,
		-(0.07 + 0.20 * run) * self.lean * move + 0.035 * breath * (1 - move) + 0.12 * self.air + 0.65 * self.dead
	)
	self:rotate("Bone.002", X, (0.035 + 0.06 * run) * self.lean * move - 0.025 * breath * (1 - move) - 0.06 * self.air)
	for index, names in ipairs({ { "Bone.009", "Bone.010", "Bone.011" }, { "Bone.012", "Bone.013", "Bone.014" } }) do
		local phase = (self.phase + (index - 1) * 0.5) % 1
		local travel, lift, pitch
		if phase < 0.5 then
			local t = phase * 2
			travel = -stride + 2 * stride * t
			lift, pitch = 0, 0
		else
			local t = (phase - 0.5) * 2
			local eased = t * t * (3 - 2 * t)
			travel = stride - 2 * stride * eased
			lift = math.sin(PI * t) * (0.42 + 0.08 * run)
			pitch = math.sin(PI * t) * -0.18
		end
		local restFoot = self.rest[names[3]].Position
		local target = restFoot + Vector3.new(travel * self.side * move, lift * move, travel * forward * move)
		local rise = math.clamp(velocity.Y / 35, -1, 1)
		local tuck = Vector3.new(0, 0.30 + math.max(rise, 0) * 0.18 + (index - 1) * 0.06, 0.24)
		target += tuck * self.air
		target += Vector3.new(0, -0.1, 0.12) * self.dead
		self:leg(names[1], names[2], names[3], target, posedPelvis, pitch * move + 0.15 * self.air)
	end
	local swing = math.sin(angle) * (0.48 + 0.22 * run) * move
	local idleArm = 0.025 * math.sin(self.time * 2.3)
	self:rotate("Bone.003", X, swing + idleArm + 0.65 * self.air - 0.15 * self.dead)
	self:rotate("Bone.006", X, -swing - idleArm + 0.65 * self.air - 0.15 * self.dead)
	self:rotate("Bone.004", X, 0.16 + 0.22 * run * move + math.max(-swing, 0) * 0.45 + 0.30 * self.air)
	self:rotate("Bone.007", X, 0.16 + 0.22 * run * move + math.max(swing, 0) * 0.45 + 0.30 * self.air)
	self:rotate("Bone.005", X, -0.06)
	self:rotate("Bone.008", X, -0.06)
	self.state = isDead and "Dead"
		or (
			disabled and "Rest"
			or (
				air and (velocity.Y > 1 and "Jump" or "Fall")
				or (self.landing > 0.2 and "Land" or (speed > 0.6 and "Walk" or "Idle"))
			)
		)
	local now = sample and sample.now or workspace:GetServerTimeNow()
	CombatPose.apply(self, now, dt)
	CombatPose.react(self, now)
	local secondary = FighterPose.UpdateSecondary(self, dt, velocity, air, now, disabled or isDead)
	if not disabled and not isDead then
		local function add(name, axis, angle)
			self.bones[name].Transform *= CFrame.fromAxisAngle(self.rest[name]:VectorToObjectSpace(axis), angle)
		end
		-- Keep authored combat shoulder/elbow/wrist poses intact, especially the
		-- corrected Midnight Alarm finale. Recoil articulates torso/head instead.
		add("Bone.001", X, secondary.hitZ * 0.35)
		add("Bone.001", Vector3.zAxis, -secondary.hitX * 0.3)
		add("Bone.002", X, -secondary.hitZ * 0.5)
		add("Bone.002", Vector3.zAxis, secondary.hitX * 0.4)
		local action = self.visual.Parent:GetAttribute("CombatAction")
		local active = action and action ~= "" and now - (self.visual.Parent:GetAttribute("CombatActionAt") or 0) < 4
		if not active then
			for _, names in { { "Bone.003", "Bone.004", "Bone.005" }, { "Bone.006", "Bone.007", "Bone.008" } } do
				add(names[1], X, secondary.pitch * 0.35 - secondary.hitZ * 0.55)
				add(names[1], Vector3.zAxis, secondary.sway * 0.2 + secondary.hitX * 0.4)
				add(names[2], X, secondary.pitch * 0.4 + secondary.hitZ * 0.35)
				add(names[3], X, -secondary.pitch * 0.4 - secondary.hitZ * 0.3)
			end
		end
	end
	ArmClearance.apply(self, self.rigProfile)
	return true
end

function Pose:reset()
	for _, bone in self.bones do
		if bone.Parent then
			bone.Transform = IDENTITY
		end
	end
end
return Pose
