-- Fixed toy-like props. Appearance is part of identity, never an extra control.
local C = {}
local Config = require(script.Parent.Config)
local AssetData = require(script.Parent.AssetData)
local V, rgb = Vector3.new, Color3.fromRGB
local paint = {
	Pink = rgb(193, 131, 124),
	Cream = rgb(218, 204, 176),
	Blue = rgb(67, 109, 137),
	Mint = rgb(117, 161, 145),
	Purple = rgb(78, 97, 122),
	Yellow = rgb(219, 171, 76),
	Red = rgb(184, 85, 69),
	Brown = rgb(142, 104, 69),
	Dark = rgb(33, 45, 54),
	White = rgb(235, 233, 221),
	Green = rgb(93, 133, 101),
}
C.Definitions = {
	Tent = { Name = "Tent", W = 2, D = 2, H = 2, Color = paint.Cream },
	Skateboard = { Name = "Skateboard", W = 1, D = 2, H = 1, Color = paint.Blue },
	Ramp = { Name = "Ramp", W = 2, D = 2, H = 1, Color = paint.Brown },
	Cone = { Name = "Cone", W = 1, D = 1, H = 1, Color = paint.Yellow },
	Lantern = { Name = "Lantern", W = 1, D = 1, H = 1, Color = paint.Yellow },
	Lollipop = { Name = "Lollipop", W = 1, D = 1, H = 2, Color = paint.Pink },
	Donut = { Name = "Donut", W = 1, D = 1, H = 1, Color = paint.Pink, Stackable = true },
	Gummy = { Name = "Gummy bear", W = 1, D = 1, H = 1, Color = paint.Mint },
	Gift = { Name = "Present", W = 1, D = 1, H = 1, Color = paint.Purple, Stackable = true },
	Cake = { Name = "Party cake", W = 2, D = 2, H = 1, Color = paint.Pink, Stackable = true },
	Crate = { Name = "Crate", W = 1, D = 1, H = 1, Color = paint.Brown, Stackable = true },
	Chest = { Name = "Treasure", W = 2, D = 1, H = 1, Color = paint.Yellow, Stackable = true },
	Palm = { Name = "Palm tree", W = 2, D = 2, H = 2, Color = paint.Green },
	Parrot = { Name = "Parrot", W = 1, D = 1, H = 1, Color = paint.Red },
	Skull = { Name = "Pirate skull", W = 1, D = 1, H = 1, Color = paint.White },
	Rocket = { Name = "Rocket", W = 2, D = 2, H = 2, Color = paint.Red },
	UFO = { Name = "UFO", W = 2, D = 2, H = 1, Color = paint.Purple },
	Alien = { Name = "Alien", W = 1, D = 1, H = 1, Color = paint.Mint },
	MoonRock = { Name = "Moon rock", W = 1, D = 1, H = 1, Color = paint.Blue, Stackable = true },
	Dino = { Name = "Dino", W = 2, D = 2, H = 2, Color = paint.Green },
	Egg = { Name = "Dino egg", W = 1, D = 1, H = 1, Color = paint.Cream },
	Mushroom = { Name = "Mushroom", W = 1, D = 1, H = 1, Color = paint.Red },
	Campfire = { Name = "Campfire", W = 2, D = 2, H = 1, Color = paint.Yellow },
	Pizza = { Name = "Pizza box", W = 2, D = 2, H = 1, Color = paint.Red, Stackable = true },
	Soda = { Name = "Soda", W = 1, D = 1, H = 1, Color = paint.Blue },
	Arcade = { Name = "Arcade", W = 2, D = 2, H = 2, Color = paint.Purple },
	Gamepad = { Name = "Controller", W = 2, D = 1, H = 1, Color = paint.Blue },
	Cat = { Name = "Cat", W = 1, D = 1, H = 1, Color = paint.Cream },
	Ball = { Name = "Beach ball", W = 1, D = 1, H = 1, Color = paint.Yellow },
	Table = { Name = "Picnic table", W = 2, D = 2, H = 1, Color = paint.Blue, Stackable = true },
}
function C.Create(kind)
	local d = assert(C.Definitions[kind], "Unknown prop " .. tostring(kind))
	local model = Instance.new("Model")
	model.Name = kind
	local color = d.Color
	local function part(name, size, pos, c, shape, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf or CFrame.new(pos)
		p.Color = c or color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = true
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end
	local function box(name, size, pos, c)
		return part(name, size, pos, c)
	end
	local function ball(name, size, pos, c)
		local p = part(name, size, pos, c)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		return p
	end
	local function disc(name, w, h, depth, pos, c)
		return part(
			name,
			V(h, w, depth),
			pos,
			c,
			Enum.PartType.Cylinder,
			CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
		)
	end
	local function face(pos, spacing)
		for _, x in ipairs({ -spacing, spacing }) do
			ball("Eye", V(0.26, 0.36, 0.18), pos + V(x, 0, 0), paint.Dark)
			ball("EyeShine", V(0.08, 0.1, 0.05), pos + V(x - 0.035, 0.08, -0.09), paint.White)
		end
		box("Smile", V(0.28, 0.08, 0.08), pos + V(0, -0.3, -0.02), paint.Dark)
	end
	if AssetData[kind] then
		for _, entry in ipairs(AssetData[kind]) do
			local p = part(
				entry.Name,
				V(table.unpack(entry.Size)),
				V(0, 0, 0),
				Color3.new(table.unpack(entry.Color)),
				Enum.PartType[entry.Shape],
				CFrame.new(table.unpack(entry.CFrame))
			)
			p.Material = Enum.Material[entry.Material]
			p.Transparency = entry.Transparency
			if entry.Mesh then
				local m = Instance.new("SpecialMesh")
				m.MeshType = Enum.MeshType[entry.Mesh.Type]
				m.MeshId, m.TextureId = entry.Mesh.Id, entry.Mesh.Texture
				m.Scale, m.Offset = V(table.unpack(entry.Mesh.Scale)), V(table.unpack(entry.Mesh.Offset))
				m.Parent = p
			end
		end
	elseif kind == "Ramp" then
		local p = Instance.new("WedgePart")
		p.Name, p.Size, p.CFrame = "Ramp", V(5.8, 2.8, 5.8), CFrame.new(0, 1.4, 0)
		p.Color, p.Material, p.Anchored = paint.Brown, Enum.Material.Wood, true
		p.TopSurface, p.BottomSurface, p.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, model
	elseif kind == "Cone" then
		box("Base", V(2.5, 0.2, 2.5), V(0, 0.1, 0), paint.Dark)
		-- A tapered traffic cone built from a few wide segments.
		for i = 1, 6 do
			local w = 1.9 - i * 0.23
			disc("Cone", w, 0.4, w, V(0, 0.2 + i * 0.4, 0), i == 3 and paint.White or paint.Yellow)
		end
	elseif kind == "Lantern" then
		disc("Base", 1.8, 0.3, 1.8, V(0, 0.15, 0), paint.Dark)
		box("Glass", V(1.15, 1.5, 1.15), V(0, 1.05, 0), paint.Yellow)
		for _, x in ipairs({ -0.68, 0.68 }) do
			for _, z in ipairs({ -0.68, 0.68 }) do
				box("Frame", V(0.12, 1.65, 0.12), V(x, 1.12, z), paint.Dark)
			end
		end
		disc("Cap", 1.8, 0.25, 1.8, V(0, 2.03, 0), paint.Dark)
		box("Handle", V(0.2, 0.6, 0.2), V(0, 2.4, 0), paint.Dark)
	elseif kind == "Lollipop" then
		box("Stick", V(0.22, 3.6, 0.22), V(0, 1.8, 0), paint.White)
		ball("Candy", V(2.65, 2.65, 0.8), V(0, 4.4, 0), paint.Pink)
		for i = 1, 12 do
			local a = i * math.pi / 6
			ball("Swirl", V(0.35, 0.35, 0.15), V(math.sin(a) * 0.7, 4.4 + math.cos(a) * 0.7, -0.4), paint.Cream)
		end
		ball("Center", V(0.6, 0.6, 0.15), V(0, 4.4, -0.45), paint.Yellow)
	elseif kind == "Donut" then
		disc("Cake", 2.8, 2.65, 2.8, V(0, 1.33, 0), paint.Cream)
		disc("Frosting", 2.8, 0.35, 2.8, V(0, 2.8, 0), paint.Pink)
		disc("Hole", 0.75, 0.02, 0.75, V(0, 2.99, 0), paint.Brown)
		for i = 1, 9 do
			local a = i * math.pi * 2 / 9
			local p = box(
				"Sprinkle",
				V(0.3, 0.04, 0.12),
				V(math.sin(a) * 0.9, 2.99, math.cos(a) * 0.9),
				i % 2 == 0 and paint.Yellow or paint.Blue
			)
			p.CFrame *= CFrame.Angles(0, a, 0)
		end
	elseif kind == "Gummy" or kind == "Cat" or kind == "Alien" or kind == "Parrot" then
		ball("Body", V(1.8, 1.7, 1.35), V(0, 0.9, 0), color)
		ball("Head", V(1.95, 1.55, 1.45), V(0, 2.1, -0.08), color)
		for _, x in ipairs({ -0.55, 0.55 }) do
			ball("Foot", V(0.65, 0.4, 0.9), V(x, 0.22, -0.2), color)
		end
		face(V(0, 2.15, -0.78), kind == "Alien" and 0.48 or 0.35)
		if kind == "Gummy" or kind == "Cat" then
			for _, x in ipairs({ -0.6, 0.6 }) do
				ball("Ear", V(0.65, 0.6, 0.45), V(x, 2.65, 0), color)
			end
		elseif kind == "Alien" then
			for _, x in ipairs({ -0.55, 0.55 }) do
				box("Antenna", V(0.1, 0.5, 0.1), V(x, 2.6, 0), color)
				ball("Tip", V(0.23, 0.23, 0.23), V(x, 2.88, 0), paint.Yellow)
			end
		else
			ball("Beak", V(0.6, 0.55, 0.65), V(0, 1.9, -0.85), paint.Yellow)
			for _, x in ipairs({ -1, 1 }) do
				ball("Wing", V(0.6, 1.4, 0.9), V(x, 1.1, 0), paint.Blue)
			end
		end
	elseif kind == "Gift" then
		box("Box", V(2.8, 2.65, 2.8), V(0, 1.33, 0), color)
		box("Lid", V(2.95, 0.35, 2.95), V(0, 2.82, 0), paint.Pink)
		box("RibbonX", V(0.38, 3, 2.96), V(0, 1.5, 0), paint.Yellow)
		box("RibbonZ", V(2.96, 3, 0.38), V(0, 1.5, 0), paint.Yellow)
	elseif kind == "Crate" then
		box("Wood", V(2.8, 3, 2.8), V(0, 1.5, 0), paint.Brown)
		for _, y in ipairs({ 0.2, 2.8 }) do
			box("Band", V(2.96, 0.25, 2.96), V(0, y, 0), paint.Cream)
		end
		local p = box("Brace", V(0.25, 2.6, 0.12), V(0, 1.5, -1.43), paint.Cream)
		p.CFrame *= CFrame.Angles(0, 0, 0.7)
	elseif kind == "Cake" then
		disc("Plate", 5.9, 0.15, 5.9, V(0, 0.08, 0), paint.White)
		disc("Cake", 5.3, 2.6, 5.3, V(0, 1.45, 0), paint.Pink)
		disc("Icing", 5.4, 0.3, 5.4, V(0, 2.85, 0), paint.White)
		for i = 1, 8 do
			local a = i * math.pi / 4
			ball("Cherry", V(0.4, 0.3, 0.4), V(math.sin(a) * 2, 2.86, math.cos(a) * 2), paint.Red)
		end
	elseif kind == "Chest" then
		box("Chest", V(5.6, 2.6, 2.7), V(0, 1.3, 0), paint.Brown)
		box("Lid", V(5.8, 0.4, 2.9), V(0, 2.8, 0), paint.Yellow)
		for _, x in ipairs({ -2, 2 }) do
			box("GoldBand", V(0.35, 2.8, 2.85), V(x, 1.4, 0), paint.Yellow)
		end
		box("Lock", V(0.6, 0.7, 0.15), V(0, 1.6, -1.43), paint.Yellow)
		box("Keyhole", V(0.14, 0.22, 0.06), V(0, 1.6, -1.53), paint.Dark)
	elseif kind == "Palm" then
		box("Trunk", V(0.7, 4.5, 0.7), V(0, 2.25, 0), paint.Brown)
		for i = 1, 6 do
			local a = i * math.pi / 3
			local p = ball("Leaf", V(1.25, 0.65, 3.5), V(math.sin(a) * 0.9, 4.85, math.cos(a) * 0.9), paint.Green)
			p.CFrame *= CFrame.Angles(0, a, 0)
		end
		ball("Coconut", V(0.65, 0.65, 0.65), V(0.3, 4.2, -0.35), paint.Brown)
	elseif kind == "Skull" then
		ball("Skull", V(2.6, 2.35, 2), V(0, 1.7, 0), paint.White)
		for _, x in ipairs({ -0.62, 0.62 }) do
			ball("Socket", V(0.7, 0.85, 0.12), V(x, 1.9, -0.94), paint.Dark)
		end
		for _, x in ipairs({ -0.6, 0, 0.6 }) do
			box("Tooth", V(0.4, 0.6, 0.7), V(x, 0.5, -0.5), paint.White)
		end
	elseif kind == "Rocket" then
		disc("Hull", 2.6, 3.6, 2.6, V(0, 2.7, 0), paint.White)
		ball("Nose", V(2.65, 2.2, 2.65), V(0, 4.65, 0), paint.Red)
		for i = 1, 4 do
			local a = i * math.pi / 2
			local p = box("Fin", V(0.5, 2, 1.5), V(math.sin(a) * 1.6, 1, math.cos(a) * 1.6), paint.Red)
			p.CFrame *= CFrame.Angles(0, a, 0)
		end
		ball("WindowRim", V(1.25, 1.25, 0.25), V(0, 3, -1.29), paint.Yellow)
		ball("Window", V(0.95, 0.95, 0.3), V(0, 3, -1.43), paint.Blue)
	elseif kind == "UFO" then
		disc("Saucer", 5.7, 0.75, 5.7, V(0, 1.2, 0), paint.Purple)
		ball("Dome", V(3.1, 2.4, 3.1), V(0, 1.8, 0), paint.Mint)
		for i = 1, 8 do
			local a = i * math.pi / 4
			ball("Light", V(0.5, 0.35, 0.5), V(math.sin(a) * 2.45, 1.65, math.cos(a) * 2.45), paint.Yellow)
		end
	elseif kind == "MoonRock" then
		box("Crystal", V(2.8, 3, 2.8), V(0, 1.5, 0), paint.Blue)
		box("Vein", V(0.24, 3, 2.82), V(0.5, 1.5, 0), paint.Mint)
	elseif kind == "Dino" then
		ball("Body", V(3.5, 3.4, 3.8), V(0, 2.3, 0.2), paint.Green)
		ball("Head", V(2.8, 2.6, 2.9), V(0, 4.1, -1), paint.Green)
		ball("Snout", V(2.5, 1.3, 1.6), V(0, 3.6, -2), paint.Mint)
		face(V(0, 4.3, -2.37), 0.65)
		for _, x in ipairs({ -1, 1 }) do
			ball("Foot", V(1.1, 0.7, 1.8), V(x, 0.4, -0.4), paint.Green)
		end
		for i = 1, 3 do
			ball("Spike", V(0.6, 0.65, 0.65), V(0, 3.4 - i * 0.3, 0.5 + i * 0.55), paint.Yellow)
		end
	elseif kind == "Egg" then
		ball("Egg", V(2.2, 2.9, 2.2), V(0, 1.45, 0), paint.Cream)
		for _, v in ipairs({ V(0.5, 1.6, -0.95), V(-0.5, 1, -0.9), V(0, 2.2, -0.9) }) do
			ball("Spot", V(0.6, 0.5, 0.12), v, paint.Purple)
		end
	elseif kind == "Mushroom" then
		disc("Stem", 0.7, 1.8, 0.7, V(0, 0.9, 0), paint.Cream)
		ball("Cap", V(2.8, 1.4, 2.8), V(0, 2.1, 0), paint.Red)
		for _, v in ipairs({ V(0.65, 2.6, 0), V(-0.6, 2.55, 0.5), V(0, 2.77, -0.5) }) do
			ball("Spot", V(0.45, 0.16, 0.45), v, paint.White)
		end
	elseif kind == "Campfire" then
		for i = 1, 8 do
			local a = i * math.pi / 4
			ball("Stone", V(1, 0.6, 1), V(math.sin(a) * 2, 0.3, math.cos(a) * 2), paint.Dark)
		end
		for _, x in ipairs({ -0.65, 0.65 }) do
			box("Log", V(0.65, 0.65, 3.2), V(x, 0.6, 0), paint.Brown)
		end
		local source = box("Embers", V(0.2, 0.2, 0.2), V(0, 0.8, 0), paint.Dark)
		source.Transparency, source.CanCollide = 1, false
		local fire = Instance.new("Fire")
		fire.Size, fire.Heat = 3.5, 2
		fire.Color, fire.SecondaryColor = paint.Yellow, paint.Red
		fire.Parent = source
	elseif kind == "Pizza" then
		box("PizzaBox", V(5.8, 2.7, 5.8), V(0, 1.35, 0), paint.Cream)
		disc("Pizza", 5, 0.2, 5, V(0, 2.83, 0), paint.Yellow)
		for i = 1, 7 do
			local a = i * math.pi * 2 / 7
			disc("Pepperoni", 0.6, 0.06, 0.6, V(math.sin(a) * 1.65, 2.97, math.cos(a) * 1.65), paint.Red)
		end
	elseif kind == "Soda" then
		disc("Cup", 1.7, 2.55, 1.7, V(0, 1.28, 0), paint.Blue)
		disc("Lid", 1.85, 0.2, 1.85, V(0, 2.65, 0), paint.White)
		box("Straw", V(0.14, 0.35, 0.14), V(0.25, 2.82, 0), paint.Red)
	elseif kind == "Arcade" then
		box("Cabinet", V(3.5, 5.6, 3.3), V(0, 2.8, 0), paint.Purple)
		box("ScreenRim", V(3, 2.2, 0.25), V(0, 3.8, -1.73), paint.Dark)
		box("Screen", V(2.65, 1.8, 0.12), V(0, 3.8, -1.89), paint.Blue)
		box("ControlDeck", V(3.5, 0.35, 1.3), V(0, 2.45, -2), paint.Pink)
		box("Joystick", V(0.14, 0.4, 0.14), V(-0.7, 2.8, -2), paint.Dark)
		ball("JoystickTop", V(0.35, 0.35, 0.35), V(-0.7, 3, -2), paint.Red)
		for _, x in ipairs({ 0.45, 1 }) do
			ball("Button", V(0.3, 0.12, 0.3), V(x, 2.7, -2), paint.Yellow)
		end
		box("Marquee", V(3.5, 0.55, 0.18), V(0, 5.4, -1.75), paint.Yellow)
		for i = 1, 3 do
			box("ScreenLine", V(1.7 - i * 0.25, 0.12, 0.06), V(0, 4.25 - i * 0.28, -1.99), paint.White)
		end
	elseif kind == "Gamepad" then
		ball("Controller", V(5.6, 1.4, 2.7), V(0, 1.25, 0), paint.Blue)
		box("DPadX", V(1, 0.12, 0.3), V(-1.5, 1.95, 0), paint.Dark)
		box("DPadZ", V(0.3, 0.12, 1), V(-1.5, 1.95, 0), paint.Dark)
		for i = 1, 4 do
			local a = i * math.pi / 2
			ball(
				"Button",
				V(0.3, 0.13, 0.3),
				V(1.5 + math.sin(a) * 0.4, 1.96, math.cos(a) * 0.4),
				i % 2 == 0 and paint.Red or paint.Yellow
			)
		end
	elseif kind == "Ball" then
		ball("Ball", V(2.8, 2.8, 2.8), V(0, 1.4, 0), paint.Yellow)
		ball("BluePanel", V(1.7, 2.65, 2.65), V(0, 1.4, 0), paint.Blue)
	elseif kind == "Table" then
		box("Top", V(5.8, 0.35, 5.8), V(0, 2.83, 0), paint.Blue)
		for _, x in ipairs({ -2.2, 2.2 }) do
			for _, z in ipairs({ -2.2, 2.2 }) do
				box("Leg", V(0.5, 2.65, 0.5), V(x, 1.33, z), paint.Cream)
			end
		end
	end
	-- Face the island entrance so the first view shows faces and identifying details.
	local facing = CFrame.Angles(0, math.pi, 0)
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			p.CFrame = facing * p.CFrame
		end
	end
	model.WorldPivot = CFrame.identity
	local bounds, size = model:GetBoundingBox()
	local bottom = bounds.Position.Y - size.Y / 2
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			p.CFrame -= V(0, bottom, 0)
		end
	end
	model:ScaleTo(Config.Cell / 3)
	return model
end
return C
