-- Local-only, deterministic FK for four different skinned skeletons.
-- Only Bone.Transform changes: no movement, damage, cooldowns or flight authority.
local Profiles = require(script.Parent.FighterRigProfiles)
local Definitions = require(script.Parent.FighterDefinitions)
local FighterPose = {}
FighterPose.__index = FighterPose
local TAU = math.pi * 2
local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis
local function smooth(a, b, rate, dt)
	return a + (b - a) * (1 - math.exp(-rate * dt))
end
local function pulse(t, hit, width)
	return math.max(0, 1 - math.abs(t - hit) / width) ^ 2
end

local function ease01(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
local function envelope(t, duration, enter, leave)
	return math.min(ease01(t / enter), ease01((duration - t) / leave))
end
-- Return neutral at either end without reversing a full body turn during fadeout.
-- At the impact time the rear-facing tail crosses the forward hit hemisphere.
local function tailTurn(t, hit, duration)
	if t <= hit then
		return math.pi * ease01(t / hit)
	end
	return math.pi + math.pi * ease01((t - hit) / (duration - hit))
end

function FighterPose.ActionTiming(id, action, combo)
	local fighter = Definitions.ById[id]
	if not fighter then
		return nil
	end
	if action == "M1" then
		local basic = fighter.Basic
		return basic.Recovery, (basic.HitTimes and basic.HitTimes[combo]) or basic.HitTime or basic.Recovery * 0.4
	elseif action == "F" then
		return fighter.Ultimate.Duration, 0
	end
	local ability = fighter.Abilities[action]
	return ability and ability.Duration, ability and ability.HitTime
end

-- Bounded, substepped springs keep follow-through stable through a slow frame.
-- Only angles are sprung: skin bind translations and gameplay physics never move.
function FighterPose.SpringStep(position, velocity, target, dt, frequency, damping, limit)
	dt = math.clamp(dt, 0, 0.1)
	local steps = math.max(1, math.ceil(dt * 120))
	local h = dt / steps
	for _ = 1, steps do
		velocity += ((target - position) * frequency * frequency - 2 * damping * frequency * velocity) * h
		position += velocity * h
		if math.abs(position) > limit then
			position = math.clamp(position, -limit, limit)
			if position * velocity > 0 then
				velocity = 0
			end
		end
	end
	return position, velocity
end

-- Shared by Tung and the four asset-specific rigs. Hits come only from the
-- replicated server hit marker, never from client-side collision guesses.
function FighterPose.UpdateSecondary(pose, dt, velocity, air, now, disabled)
	local s = pose.secondary
	if not s then
		s = {
			pitch = 0,
			pitchV = 0,
			sway = 0,
			swayV = 0,
			hitX = 0,
			hitXV = 0,
			hitZ = 0,
			hitZV = 0,
			previousVelocity = velocity,
			previousLook = pose.root.CFrame.LookVector,
			wasAir = air,
		}
		pose.secondary = s
	end
	local localDelta = pose.root.CFrame:VectorToObjectSpace(velocity - s.previousVelocity)
	local localLook = pose.root.CFrame:VectorToObjectSpace(s.previousLook)
	local airborne = air and not disabled
	local vertical = math.clamp(velocity.Y / 65, -1, 1)
	local pitchTarget = math.clamp(-localDelta.Z * 0.0025 - localDelta.Y * 0.003, -0.12, 0.12)
		+ (airborne and (-vertical * 0.09 + math.sin(pose.time * 5) * 0.025) or 0)
	local swayTarget = math.clamp(localDelta.X * -0.003 + localLook.X * 0.7, -0.16, 0.16)
		+ (airborne and math.sin(pose.time * 4.2) * 0.045 or 0)
	if s.wasAir and not air and not disabled then
		s.pitchV += math.clamp(-s.previousVelocity.Y / 45, 0.1, 0.9)
	end
	local character = pose.visual.Parent
	local at = character and character:GetAttribute("CombatHitAt")
	if at and at ~= s.hitAt and now >= at and now - at <= 0.25 and not disabled then
		s.hitAt = at
		local direction = character:GetAttribute("CombatHitDirection")
		if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.001 then
			direction = -pose.root.CFrame.LookVector
		end
		local d = pose.root.CFrame:VectorToObjectSpace(direction.Unit)
		s.hitXV = math.clamp(s.hitXV + d.X * 3.6, -5, 5)
		s.hitZV = math.clamp(s.hitZV + d.Z * 3.6, -5, 5)
	end
	if disabled then
		pitchTarget, swayTarget = 0, 0
	end
	s.pitch, s.pitchV = FighterPose.SpringStep(s.pitch, s.pitchV, pitchTarget, dt, 12, 0.55, 0.18)
	s.sway, s.swayV = FighterPose.SpringStep(s.sway, s.swayV, swayTarget, dt, 10, 0.5, 0.20)
	s.hitX, s.hitXV = FighterPose.SpringStep(s.hitX, s.hitXV, 0, dt, 19, 0.48, 0.22)
	s.hitZ, s.hitZV = FighterPose.SpringStep(s.hitZ, s.hitZV, 0, dt, 19, 0.48, 0.22)
	s.previousVelocity, s.previousLook, s.wasAir = velocity, pose.root.CFrame.LookVector, air
	return s
end

function FighterPose:secondaryMotion(s, active)
	local p = self.profile
	local pitch, sway = s.pitch, s.sway
	local hx, hz = s.hitX, s.hitZ
	self:rotate(p.Root, X, hz * 0.55)
	self:rotate(p.Root, Z, -hx * 0.55)
	self:rotate(p.Head, X, -hz * 0.45)
	self:rotate(p.Head, Z, hx * 0.35)
	if self.id == "chimpanzini" then
		-- The banana base/tip are the only independently supported lower chain.
		-- Face-area 005--008 are deliberately not guessed to be peel bones.
		self:rotate(p.Tail, Z, pitch * 1.25 + sway + hx * 0.8)
		self:rotate(p.TailTip, Z, -pitch * 1.65 - sway * 0.7 - hx * 1.1)
		self:rotate(p.Tail, X, pitch * 0.5 + hz * 0.5)
		self:rotate(p.Spine, X, -pitch * 0.3 - hz * 0.45)
	elseif self.id == "tralalero" then
		self:rotate(p.Tail, Y, sway * 1.5 + math.sin(self.time * 5.5) * 0.11 * self.air + hx * 0.9)
		self:rotate(p.Tail, X, pitch * 0.6 + hz * 0.35)
		for i, fin in p.TailFins do
			self:rotate(fin, X, (i == 1 and 1 or -1) * (pitch * 0.8 + hz * 0.3))
		end
		self:rotate(p.Jaw, X, -math.abs(hz) * 0.25)
	elseif self.id == "bombardiro" then
		self:rotate(p.Tail, Y, sway * 1.3 + hx * 0.6)
		self:rotate(p.Tail, X, pitch * 0.55 + hz * 0.4)
		self:rotate(p.Jaw, X, -(0.03 + 0.065 * self.air + math.abs(pitch) * 0.7 + math.abs(hz) * 0.6))
		for i, wing in p.Wings do
			self:rotate(wing, Z, (i == 1 and -1 or 1) * (pitch * 0.7 + hz * 0.45) - hx * 0.4)
		end
	elseif self.id == "ballerina" then
		-- This source has no independent skirt bones. Hip/arm follow-through is
		-- honest articulation, not a claim of cloth simulation on a rigid hem.
		for i, arm in p.Arms do
			local sign = i == 1 and -1 or 1
			self:rotate(arm[1], X, pitch * 0.45 - hz * 0.7)
			self:rotate(arm[1], Z, sign * math.abs(pitch) * 0.35 + hx * 0.45)
			self:rotate(arm[2], X, pitch * 0.45 + hz * 0.45)
			self:rotate(arm[3], X, -pitch * 0.65 - hz * 0.5)
		end
	end
	if p.Legs and not active then
		for _, leg in p.Legs do
			self:rotate(leg[1], X, -pitch * 0.3 - hz * 0.3)
			self:rotate(leg[2], X, pitch * 0.3 + hz * 0.25)
		end
	end
end

function FighterPose.new(visual)
	local id = visual:GetAttribute("FighterId") or visual:GetAttribute("RigProfile")
	local profile = Profiles[id]
	local character = visual.Parent
	local mesh = visual:FindFirstChild("Mesh")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not profile or not mesh or not root or not humanoid then
		return nil
	end
	local self = setmetatable({
		visual = visual,
		mesh = mesh,
		root = root,
		humanoid = humanoid,
		id = id,
		profile = profile,
		bones = {},
		rest = {},
		propellerPivots = {},
		phase = 0,
		time = 0,
		speed = 0,
		moving = 0,
		air = 0,
		landing = 0,
		wasAir = false,
		sprint = 0,
		dead = 0,
		state = "Idle",
	}, FighterPose)
	for _, b in mesh:GetDescendants() do
		if b:IsA("Bone") then
			self.bones[b.Name] = b
			self.rest[b.Name] = mesh.CFrame:ToObjectSpace(b.WorldCFrame)
		end
	end
	for _, name in profile.Required do
		if not self.bones[name] then
			return nil
		end
	end
	for _, name in profile.Propellers or {} do
		local rest = self.rest[name]
		local scale = profile.PropellerHubScale or 1
		local hub = Vector3.new(rest.X * scale, rest.Y * scale, rest.Z)
		self.propellerPivots[name] = rest:PointToObjectSpace(hub)
	end
	return self
end

-- Rigid rotation about the blade hub, not the imported bone's offset origin.
-- The compensating translation keeps the hub fixed; it does not stretch blades.
function FighterPose:spinPropeller(name, angle)
	local bone = self.bones[name]
	local pivot = self.propellerPivots[name]
	if not bone or not pivot then return end
	local axis = self.rest[name]:VectorToObjectSpace(Z).Unit
	bone.Transform *= CFrame.new(pivot) * CFrame.fromAxisAngle(axis, angle) * CFrame.new(-pivot)
end

-- Axis is expressed in the unposed mesh, converted to the actual bind basis.
-- Compose small anatomical rotations; no hand-target IK or arbitrary Euler winding.
function FighterPose:rotate(name, axis, angle)
	local b = self.bones[name]
	if b then
		b.Transform *= CFrame.fromAxisAngle(self.rest[name]:VectorToObjectSpace(axis).Unit, angle)
	end
end
function FighterPose:offset(name, v)
	local b = self.bones[name]
	if b then
		b.Transform = CFrame.new(self.rest[name]:VectorToObjectSpace(v)) * b.Transform
	end
end

function FighterPose:locomotion(angle, move, forward, side, velocity)
	local p = self.profile
	local air = self.air
	local wave = math.sin(angle)
	local breathe = math.sin(self.time * 2.5)
	local run = self.sprint
	local scale = math.clamp(self.mesh.Size.Y / 6, 0.3, 1.4)
	if self.id == "tralalero" or self.id == "ballerina" then
		self:offset(
			p.Root,
			Vector3.new(
				0,
				(0.035 * breathe * (1 - move) + 0.09 * math.abs(wave) * move - 0.10 * self.landing) * scale,
				0
			)
		)
		self:rotate(p.Root, X, -(0.07 + run * 0.10) * move * forward + 0.05 * air)
		self:rotate(p.Root, Z, -0.07 * move * side)
		local stride = self.id == "ballerina" and 0.43 or 0.36
		for i, leg in p.Legs do
			local cycle = angle + (i - 1) * math.pi
			if i == 3 then
				cycle = angle + math.pi / 2
			end
			local swing = math.sin(cycle) * (stride + 0.10 * run) * move * forward
			local bend = math.max(0, math.cos(cycle)) * (0.48 + 0.1 * run) * move
			self:rotate(leg[1], X, swing - 0.28 * air)
			self:rotate(leg[1], Z, math.sin(cycle) * 0.16 * move * side)
			self:rotate(leg[2], X, -bend - 0.38 * air - 0.12 * self.landing)
			self:rotate(leg[3], X, -swing + bend * 0.65 + 0.15 * air)
		end
		self:rotate(p.Head, X, 0.025 * breathe + 0.04 * move)
		if p.Arms then
			for i, arm in p.Arms do
				local swing = wave * (i == 1 and 1 or -1) * (0.40 + 0.13 * run) * move
				self:rotate(arm[1], X, -swing + 0.22 * air)
				self:rotate(arm[1], Z, (i == 1 and -1 or 1) * (0.10 + 0.15 * air))
				self:rotate(arm[2], X, 0.12 + 0.24 * run * move + 0.2 * air)
			end
		else
			self:rotate(p.Tail, Y, 0.09 * breathe + wave * 0.20 * move)
			self:rotate("Bone.008", X, 0.06 * wave * move)
			self:rotate("Bone.009", X, -0.06 * wave * move)
			self:rotate(p.Jaw, X, -0.035 - 0.03 * breathe)
		end
	elseif self.id == "chimpanzini" then
		-- This asset is a banana, not an ape with hidden humanoid limbs.
		local hop = math.abs(wave)
		self:offset(p.Root, Vector3.new(0, (0.22 * hop * move + 0.025 * breathe - 0.10 * self.landing) * scale, 0))
		self:rotate(p.Root, X, -0.10 * move * forward - 0.08 * air)
		self:rotate(p.Root, Z, 0.09 * wave * move - 0.08 * move * side)
		self:rotate(p.Spine, X, -0.07 * move * forward + 0.04 * breathe)
		self:rotate(p.Head, X, 0.07 * move * forward - 0.03 * breathe)
		self:rotate(p.Tail, Z, 0.15 * wave * move + 0.10 * air)
		self:rotate(p.TailTip, Z, -0.22 * wave * move - 0.12 * air)
	elseif self.id == "bombardiro" then
		self:offset(p.Root, Vector3.new(0, (0.07 * breathe + 0.055 * wave * move - 0.08 * self.landing) * scale, 0))
		self:rotate(p.Root, X, -(0.08 + 0.05 * run) * move * forward + math.clamp(velocity.Y / 180, -0.12, 0.18) * air)
		self:rotate(p.Root, Z, -0.12 * move * side + 0.035 * breathe)
		self:rotate(p.Tail, Y, 0.07 * breathe + 0.10 * wave * move)
		self:rotate(p.Head, X, 0.025 * breathe)
		for i, wing in p.Wings do
			self:rotate(wing, Z, (i == 1 and -1 or 1) * (0.025 * breathe + 0.04 * wave * move + 0.035 * air))
		end
		-- Four engine pivots have differing bind orientations. Rotate in mesh Z,
		-- never local Y guessed from another skeleton.
		for i, prop in p.Propellers do
			self:spinPropeller(prop, ((self.enginePhase or self.time * 18) * (i % 2 == 0 and -1 or 1)) % TAU)
		end
	end
end

-- Flight is a timed gameplay state, not an attack pose. Keep its silhouette
-- underneath a bomb throw or bite so using an allowed attack never folds wings.
function FighterPose:movementPosture(mode, blend)
	local p = self.profile
	if mode == "Flight" and self.id == "bombardiro" then
		self:rotate(p.Root, X, 0.18 * blend)
		self:rotate(p.Jaw, X, -0.32 * blend)
		for i, wing in p.Wings do
			self:rotate(wing, Z, (i == 1 and -1 or 1) * 0.23 * blend)
		end
		self:rotate(p.Tail, Y, math.sin(self.time * 12) * 0.14 * blend)
	elseif mode == "Glide" and self.id == "chimpanzini" then
		self:rotate(p.Root, X, -0.26 * blend)
		self:rotate(p.Spine, X, 0.18 * blend)
		self:rotate(p.Tail, Z, 0.65 * blend)
		self:rotate(p.TailTip, Z, -0.92 * blend)
		self:rotate(p.Tail, X, 0.16 * math.sin(self.time * 10) * blend)
		self:rotate(p.TailTip, X, -0.24 * math.sin(self.time * 10 - 0.7) * blend)
	end
end

-- Full-body ultimate choreography. Windups remain readable between impacts;
-- jaw/peel/kick/recoil events use the same impact times as FighterCombatKits.
-- Rotate existing anatomical joints only: no invented limbs or stretching.
function FighterPose:ultimate(t, duration)
	local p = self.profile
	local hold = envelope(t, duration, 0.16, 0.30)
	if self.id == "tralalero" then
		local opening, snap = 0, 0
		for _, at in { 0.45, 1.1, 1.75 } do
			opening += pulse(t, at - 0.16, 0.22)
			snap += pulse(t, at + 0.035, 0.20)
		end
		self:rotate(p.Jaw, X, -0.20 * hold - 0.85 * opening + 0.17 * snap)
		self:rotate(p.Head, X, 0.20 * opening - 0.13 * snap)
		self:rotate(p.Root, X, 0.12 * opening - 0.32 * snap)
		self:rotate(p.Tail, Y, (0.40 * math.sin(t * 14) + 0.25 * opening) * hold)
		for i, leg in p.Legs do
			self:rotate(leg[1], X, -0.45 * hold + (i == 2 and -1 or 1) * 0.35 * snap)
			self:rotate(leg[2], X, -0.60 * hold)
			self:rotate(leg[3], X, 0.35 * hold)
		end
	elseif self.id == "chimpanzini" then
		local wind, flick, direction = 0, 0, 1
		for i, at in { 0.6, 1.3, 2.0 } do
			local w, f = pulse(t, at - 0.20, 0.28), pulse(t, at, 0.24)
			wind += w
			flick += f
			if w + f > 0.01 then
				direction = i == 2 and -1 or 1
			end
		end
		self:rotate(p.Root, X, 0.12 * wind - 0.22 * flick)
		self:rotate(p.Root, Z, direction * (0.20 * wind - 0.28 * flick))
		self:rotate(p.Spine, X, 0.26 * wind - 0.40 * flick)
		self:rotate(p.Head, X, -0.15 * wind + 0.22 * flick)
		self:rotate(p.Tail, Z, direction * (0.32 * hold + 0.70 * wind - 0.92 * flick))
		self:rotate(p.TailTip, Z, direction * (-0.42 * hold - 0.68 * wind + 1.10 * flick))
		self:rotate(p.Tail, X, -0.36 * flick)
		self:rotate(p.TailTip, X, 0.48 * flick)
	elseif self.id == "ballerina" then
		local kick = pulse(t, 0.55, 0.22) + pulse(t, 1.05, 0.22) + pulse(t, 1.55, 0.22)
		local finish = pulse(t, 2.2, 0.30)
		-- Three complete turns end facing forward; the last beat is a high kick.
		self:rotate(p.Root, Y, ease01(t / 1.85) * TAU * 3)
		self:rotate(p.Root, X, 0.18 * finish)
		for i, arm in p.Arms do
			self:rotate(arm[1], Z, (i == 1 and -1 or 1) * (0.95 * hold + 0.20 * kick))
			self:rotate(arm[2], X, 0.35 * finish)
		end
		self:rotate(p.Legs[2][1], Z, 0.62 * hold + 0.30 * kick)
		self:rotate(p.Legs[2][1], X, 1.25 * finish)
		self:rotate(p.Legs[2][2], X, -0.22 * hold + 0.16 * finish)
		self:rotate(p.Legs[2][3], X, -0.30 * finish)
		self:rotate(p.Legs[1][2], X, -0.16 * finish)
	elseif self.id == "bombardiro" then
		local load, recoil = 0, 0
		for _, at in { 1.05, 1.85, 2.65 } do
			load += pulse(t, at - 0.22, 0.32)
			recoil += pulse(t, at, 0.28)
		end
		self:rotate(p.Root, X, 0.12 * hold - 0.16 * load + 0.25 * recoil)
		self:rotate(p.Head, X, -0.15 * load + 0.24 * recoil)
		self:rotate(p.Jaw, X, -0.40 * hold - 0.46 * load + 0.22 * recoil)
		self:rotate(p.UpperJaw, X, 0.12 * load)
		for i, wing in p.Wings do
			self:rotate(wing, Z, (i == 1 and -1 or 1) * (0.26 * hold + 0.22 * recoil))
		end
		self:rotate(p.Tail, Y, 0.24 * math.sin(t * 9) * hold)
	end
end

function FighterPose:attack(action, t, combo)
	local p = self.profile
	local duration, hit = FighterPose.ActionTiming(self.id, action, combo)
	if not duration or t < 0 or t > duration then
		return false
	end
	if action == "F" then
		self:ultimate(t, duration)
		return true
	end
	hit = hit or duration * 0.4
	local jab = pulse(t, hit, math.max(0.075, duration * 0.4))
	local blend = envelope(t, duration, 0.09, 0.16)
	if self.id == "tralalero" then
		if action == "M1" then
			if combo == 3 then
				self:rotate(p.Root, Y, tailTurn(t, hit, duration))
				self:rotate(p.Tail, Y, -0.85 * jab)
				self:rotate(p.Tail, X, 0.18 * jab)
				for _, leg in p.Legs do
					self:rotate(leg[2], X, -0.22 * blend)
				end
			else
				local windup = pulse(t, hit * 0.52, hit * 0.6)
				self:rotate(p.Jaw, X, -0.70 * windup - 0.04 * jab)
				self:rotate(p.Head, Y, (combo == 2 and -1 or 1) * 0.17 * jab)
				self:rotate(p.Root, X, -0.10 * jab)
				local leg = p.Legs[combo]
				self:rotate(leg[1], X, 0.50 * jab)
				self:rotate(leg[2], X, -0.25 * jab)
			end
		elseif action == "Q" then
			-- Hold a recognizable torpedo silhouette through the entire driven dash.
			local torpedo = envelope(t, duration, 0.075, 0.16)
			self:rotate(p.Root, X, -0.34 * torpedo)
			self:rotate(p.Jaw, X, -0.62 * torpedo)
			self:rotate(p.Head, X, 0.10 * torpedo)
			for _, leg in p.Legs do
				self:rotate(leg[1], X, -0.90 * torpedo)
				self:rotate(leg[2], X, -0.48 * torpedo)
				self:rotate(leg[3], X, 0.50 * torpedo)
			end
			self:rotate(p.Tail, Y, math.sin(t * 32) * 0.30 * torpedo)
		elseif action == "E" then
			self:rotate(p.Root, Y, tailTurn(t, hit, duration))
			self:rotate(p.Tail, Y, -1.0 * pulse(t, hit, 0.26))
			self:rotate(p.Tail, X, 0.35 * pulse(t, hit, 0.21))
			for i, fin in p.TailFins do
				self:rotate(fin, X, (i == 1 and 1 or -1) * 0.28 * blend)
			end
			for _, leg in p.Legs do
				self:rotate(leg[2], X, -0.30 * blend)
			end
		elseif action == "R" then
			-- Nose up on breach, level out, then nose down into the landing arc.
			local progress = math.clamp(t / duration, 0, 1)
			self:rotate(p.Root, X, (0.50 - 0.88 * progress) * blend)
			self:rotate(p.Tail, Y, math.sin(t * 16) * 0.28 * blend)
			self:rotate(p.Jaw, X, -0.22 * blend)
			for _, leg in p.Legs do
				self:rotate(leg[1], X, -0.45 * blend)
				self:rotate(leg[2], X, -0.55 * blend)
			end
		end
	elseif self.id == "ballerina" then
		if action == "M1" then
			-- Left kick, right kick, committed forward extension. Arms balance;
			-- they never substitute the generic alternating fist animation.
			local index = combo == 2 and 2 or 1
			local leg, support = p.Legs[index], p.Legs[index == 1 and 2 or 1]
			local kick = combo == 3 and 1.48 or 1.12
			self:rotate(leg[1], X, kick * jab)
			self:rotate(leg[2], X, -0.12 * jab)
			self:rotate(leg[3], X, -0.28 * jab)
			self:rotate(support[2], X, -0.20 * jab)
			self:rotate(p.Root, X, 0.16 * jab)
			self:rotate(p.Root, Y, (index == 1 and 1 or -1) * 0.20 * jab)
			for i, arm in p.Arms do
				self:rotate(arm[1], Z, (i == 1 and -1 or 1) * 0.48 * jab)
				self:rotate(arm[1], X, -0.12 * jab)
			end
		elseif action == "Q" then
			self:rotate(p.Root, Y, ease01(t / duration) * TAU)
			for i, arm in p.Arms do
				self:rotate(arm[1], Z, (i == 1 and -1 or 1) * 0.95 * blend)
			end
			self:rotate(p.Legs[2][1], Z, 0.68 * blend)
			self:rotate(p.Legs[2][2], X, -0.20 * blend)
		elseif action == "E" then
			for i, arm in p.Arms do
				self:rotate(arm[1], X, 0.70 * blend)
				self:rotate(arm[1], Z, (i == 1 and 1 or -1) * 0.22 * blend)
				self:rotate(arm[2], X, 0.65 * blend)
			end
			self:rotate(p.Legs[2][2], X, -0.48 * blend)
		elseif action == "R" then
			local first = pulse(t, 0.13, 0.19)
			local second = pulse(t, 0.53, 0.21)
			self:rotate(p.Legs[1][1], X, 1.10 * first - 0.65 * second)
			self:rotate(p.Legs[2][1], X, -0.65 * first + 1.10 * second)
			self:rotate(p.Legs[1][2], X, -0.28 * second)
			self:rotate(p.Legs[2][2], X, -0.28 * first)
			for i, arm in p.Arms do
				self:rotate(arm[1], Z, (i == 1 and -1 or 1) * 0.82 * blend)
			end
			self:rotate(p.Root, Z, 0.12 * (first - second))
		end
	elseif self.id == "chimpanzini" then
		if action == "R" then
			-- Only the verified banana base/tip chain is used, never face bones.
			if not self.motionLayer then
				self:movementPosture("Glide", blend)
			end
		else
			local strike = jab
			if action == "Q" then
				strike = pulse(t, hit, 0.18)
			end
			if action == "E" then
				strike = pulse(t, hit, 0.20)
			end
			local sign = combo == 2 and -1 or 1
			self:rotate(p.Spine, X, -0.26 * strike)
			self:rotate(p.Head, X, 0.16 * strike)
			self:rotate(p.Root, Z, -sign * 0.15 * strike)
			self:rotate(p.Tail, Z, sign * (combo == 3 and 0.90 or 0.70) * strike)
			self:rotate(p.TailTip, Z, -sign * (combo == 3 and 0.74 or 0.48) * strike)
			if action == "M1" and combo == 3 then
				self:rotate(p.Tail, X, -0.45 * strike)
				self:rotate(p.TailTip, X, 0.60 * strike)
			end
		end
	elseif self.id == "bombardiro" then
		if action == "M1" then
			-- Telegraph a wide-open mouth, then SNAP it shut at the damage frame.
			local opening = pulse(t, hit * 0.60, hit * 0.62)
			self:rotate(p.Jaw, X, -0.92 * opening)
			self:rotate(p.UpperJaw, X, 0.14 * opening)
			self:rotate(p.Head, X, -0.10 * opening + 0.16 * jab)
			self:rotate(p.Root, X, -0.12 * jab)
			self:rotate(p.Tail, Y, -0.22 * opening)
		elseif action == "R" or action == "E" then
			if not self.motionLayer then
				self:movementPosture("Flight", blend)
			end
		else
			local strike = pulse(t, hit, 0.25)
			self:rotate(p.Root, X, 0.12 * strike)
			self:rotate(p.Jaw, X, -0.52 * strike)
			for i, wing in p.Wings do
				self:rotate(wing, Z, (i == 1 and -1 or 1) * 0.10 * strike)
			end
		end
	end
	return true
end

function FighterPose:step(dt, sample)
	if not self.visual.Parent or not self.root.Parent then
		return false
	end
	dt = math.clamp(dt, 0, 0.1)
	self.time += dt
	local character = self.visual.Parent
	local velocity = sample and sample.velocity or self.root.AssemblyLinearVelocity
	local hs = sample and sample.state or self.humanoid:GetState()
	local grounded = sample and sample.grounded
	if grounded == nil then
		grounded = self.humanoid.FloorMaterial ~= Enum.Material.Air
	end
	local disabled = hs == Enum.HumanoidStateType.Seated
		or hs == Enum.HumanoidStateType.Swimming
		or hs == Enum.HumanoidStateType.Climbing
	local dead = self.humanoid.Health <= 0 or hs == Enum.HumanoidStateType.Dead
	local air = not grounded and not disabled and not dead
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = (disabled or dead) and 0 or math.min(48, horizontal.Magnitude)
	self.speed = smooth(self.speed, speed, 12, dt)
	self.moving = smooth(self.moving, math.clamp(self.speed / 3, 0, 1), 12, dt)
	self.air = smooth(self.air, air and 1 or 0, 14, dt)
	self.dead = smooth(self.dead, dead and 1 or 0, 8, dt)
	self.sprint = smooth(self.sprint, character:GetAttribute("Sprinting") and 1 or 0, 10, dt)
	if self.wasAir and not air then
		self.landing = 1
	end
	self.wasAir = air
	self.landing *= math.exp(-10 * dt)
	local localV = self.root.CFrame:VectorToObjectSpace(horizontal)
	local forward = speed > 0.25 and math.clamp(-localV.Z / speed, -1, 1) or 1
	local side = speed > 0.25 and math.clamp(localV.X / speed, -1, 1) or 0
	self.phase = (self.phase + math.min(4.5, self.speed / 7) * dt * (1 - self.air)) % 1
	local now = sample and sample.now or workspace:GetServerTimeNow()
	local motionMode = character:GetAttribute("AbilityMotionMode")
	local motionUntil = character:GetAttribute("AbilityMotionUntil") or 0
	local motionActive = not dead and not disabled and now < motionUntil
	self.motionBlend = smooth(self.motionBlend or 0, motionActive and 1 or 0, 20, dt)
	if motionActive then
		self.lastMotionMode = motionMode
	end
	self.motionLayer = self.motionBlend > 0.01 and (self.lastMotionMode == "Flight" or self.lastMotionMode == "Glide")
	self.enginePhase = (
		(self.enginePhase or 0)
		+ dt
			* (18 + 20 * self.moving + 8 * self.air + 65 * self.motionBlend + (character:GetAttribute("CombatAction") == "F" and 75 or 0))
	) % TAU
	self:reset()
	self:locomotion(self.phase * TAU, self.moving * (1 - self.air) * (1 - self.dead), forward, side, velocity)
	if self.motionLayer then
		self:movementPosture(self.lastMotionMode, self.motionBlend)
	end
	self.state = dead and "Dead"
		or (
			disabled and "Rest"
			or (
				air and (velocity.Y > 1 and "Jump" or "Fall")
				or (self.landing > 0.2 and "Land" or (speed > 0.6 and "Walk" or "Idle"))
			)
		)
	local secondary = FighterPose.UpdateSecondary(self, dt, velocity, air, now, disabled or dead)
	local action = character:GetAttribute("CombatAction")
	if
		not dead
		and not disabled
		and action
		and action ~= ""
		and self:attack(
			action,
			now - (character:GetAttribute("CombatActionAt") or 0),
			character:GetAttribute("CombatCombo") or 1
		)
	then
		self.state = action
	end
	if not dead and not disabled then
		self:secondaryMotion(secondary, self.state == action)
	end
	if dead then
		self:rotate(self.profile.Root, Z, 0.48 * self.dead)
		self:rotate(self.profile.Root, X, 0.20 * self.dead)
	end
	return true
end

function FighterPose:reset()
	for _, bone in self.bones do
		if bone.Parent then
			bone.Transform = CFrame.identity
		end
	end
end
return FighterPose
