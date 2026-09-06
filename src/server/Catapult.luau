local RunService = game:GetService("RunService")
local Theme = require(game.ReplicatedStorage.CopyTheScene.Theme)
local Catapult = {}
local V = Vector3.new
local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Color, p.Material = color, material or Enum.Material.Wood
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function animate(seconds, step)
	local start = os.clock()
	repeat
		local alpha = math.clamp((os.clock() - start) / seconds, 0, 1)
		step(alpha)
		if alpha == 1 then
			break
		end
		RunService.Heartbeat:Wait()
	until false
end
function Catapult.Create(parent, origin)
	local model = Instance.new("Model")
	model.Name, model.Parent = "Catapult", parent
	for _, x in ipairs({ -3.4, 3.4 }) do
		part(model, "Chassis", V(1.1, 1.2, 12), CFrame.new(x, 1.7, 0), Theme.Wood)
		for _, z in ipairs({ -4, 4 }) do
			local wheel =
				part(model, "Wheel", V(1, 3.8, 3.8), CFrame.new(x * 1.3, 1.9, z), Theme.Ink, Enum.Material.Metal)
			wheel.Shape = Enum.PartType.Cylinder
			part(model, "Hub", V(1.2, 0.6, 0.6), wheel.CFrame, Theme.WoodLight)
		end
		for _, sign in ipairs({ -1, 1 }) do
			local bottom, top = V(x, 2.2, sign * 3.8), V(x, 7.5, 0)
			part(
				model,
				"AFrame",
				V(0.85, 0.85, (top - bottom).Magnitude),
				CFrame.lookAt((top + bottom) / 2, top),
				Theme.WoodLight
			)
		end
	end
	for _, z in ipairs({ -4, 0, 4 }) do
		part(model, "CrossBrace", V(8, 0.8, 0.8), CFrame.new(0, 2.1, z), Theme.Wood)
	end
	part(model, "Axle", V(8.6, 0.9, 0.9), CFrame.new(0, 7, 0), Theme.Ink, Enum.Material.Metal)
	local arm = Instance.new("Model")
	arm.Name, arm.Parent = "ThrowingArm", model
	part(arm, "Beam", V(0.9, 0.9, 14), CFrame.new(0, 7, 2), Theme.WoodLight)
	part(arm, "Counterweight", V(3, 2.6, 2.6), CFrame.new(0, 6.8, -4), Theme.Ink, Enum.Material.Metal)
	part(arm, "Bucket", V(4, 0.5, 3.5), CFrame.new(0, 7.4, 7.5), Theme.Wood)
	for _, x in ipairs({ -1.8, 1.8 }) do
		part(arm, "BucketSide", V(0.4, 1.2, 3.5), CFrame.new(x, 8, 7.5), Theme.Wood)
	end
	part(arm, "BucketBack", V(4, 1.2, 0.4), CFrame.new(0, 8, 9), Theme.Wood)
	local rock = part(
		arm,
		"LoadedRock",
		V(4, 3.6, 4),
		CFrame.new(0, 9.4, 7.5),
		Color3.fromRGB(94, 105, 109),
		Enum.Material.Slate
	)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Sphere, rock
	arm.WorldPivot = CFrame.new(0, 7, 0)
	model.WorldPivot = CFrame.identity
	model:PivotTo(CFrame.new(origin))
	return { Model = model, Arm = arm, Rock = rock, Origin = origin }
end
function Catapult.Fire(catapult, target, impact)
	local cf = CFrame.lookAt(catapult.Origin, V(target.X, catapult.Origin.Y, target.Z)) * CFrame.Angles(0, math.pi, 0)
	catapult.Model:PivotTo(cf)
	local pivot = cf * CFrame.new(0, 7, 0)
	task.wait(1.2) -- Let everyone see which island is being targeted.
	animate(0.6, function(t)
		catapult.Arm:PivotTo(pivot * CFrame.Angles(math.rad(-68) * t * t, 0, 0))
	end)
	local rock = catapult.Rock:Clone()
	rock.Name, rock.Parent = "FlyingRock", catapult.Model.Parent
	catapult.Rock.Transparency = 1
	local start = rock.Position
	animate(1.65, function(t)
		rock.CFrame = CFrame.new(start:Lerp(target, t) + V(0, 4 * 28 * t * (1 - t), 0)) * CFrame.Angles(t * 7, t * 4, 0)
	end)
	rock:Destroy()
	impact()
end
return Catapult
