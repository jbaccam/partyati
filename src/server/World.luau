local Catapult = require(script.Parent.Catapult)
local TweenService = game:GetService("TweenService")
local Scenery = require(script.Parent.Scenery)
local Shared = game.ReplicatedStorage.CopyTheScene
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Theme = require(Shared.Theme)
local W = { Plots = {}, Center = Vector3.new(0, 18, 0), LobbyPosition = Vector3.new(0, 22, 529) }
local V, rgb = Vector3.new, Color3.fromRGB
local function part(parent, name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if name == "DeckPlank" or name == "Boardwalk" or name == "Rim" then
		p.Material = Enum.Material.Wood
	end
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end
local function label(parent, value, offset, width)
	local g = Instance.new("BillboardGui")
	g.Name = "Label"
	g.Size = UDim2.fromOffset(width or 240, 45)
	g.StudsOffset = offset or V(0, 3, 0)
	g.MaxDistance = 100
	g.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 23
	t.TextColor3 = Theme.White
	t.TextStrokeColor3 = Theme.Ink
	t.TextStrokeTransparency = 0.35
	t.Text = value
	t.Parent = g
	return t
end
function W.Build()
	local old = workspace:FindFirstChild("CopyTheSceneWorld")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "CopyTheSceneWorld"
	-- This compact arena stays available to the shared camera, away from the avatar.
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	root.Parent = workspace
	W.Root, W.Plots = root, {}
	-- A single architectural setting. The open central pavilion can evolve later.
	local water = part(root, "Lagoon", V(1800, 4, 1800), CFrame.new(0, 2, 0), rgb(64, 111, 133))
	water.Material = Enum.Material.Glass
	water.Reflectance = 0.15
	-- Layered rock coves and a distant treeline hide the empty template horizon.
	local random = Random.new(49)
	for i = 1, 26 do
		local angle = i * math.pi * 2 / 26
		local radius = 155 + random:NextNumber(-7, 9)
		local position = V(math.sin(angle) * radius, -12, math.cos(angle) * radius)
		Scenery.Create("Cliff", root, position, random:NextNumber(1.05, 1.7), angle + math.pi / 2)
		for j = 1, 3 do
			local a = angle + (j - 2) * 0.065
			local r = radius + random:NextNumber(-3, 11)
			Scenery.Create(
				"Pine",
				root,
				V(math.sin(a) * r, 22, math.cos(a) * r),
				random:NextNumber(0.75, 1.3),
				random:NextNumber(0, math.pi * 2)
			)
		end
	end
	for i = 1, 14 do
		local angle = i * math.pi * 2 / 14
		local radius = 270 + random:NextNumber(-20, 20)
		Scenery.Create(
			"Cliff",
			root,
			V(math.sin(angle) * radius, -14, math.cos(angle) * radius),
			random:NextNumber(2.5, 4),
			angle
		)
	end
	local lobby = Instance.new("Model")
	lobby.Name, lobby.Parent = "Lobby", root
	part(lobby, "LobbyFoundation", V(50, 6, 50), CFrame.new(0, 14.6, 0), Theme.Ink)
	part(lobby, "LobbyDeck", V(50, 0.5, 50), CFrame.new(0, 17.75, 0), Theme.Wood)
	for x = -24, 24, 3 do
		part(lobby, "DeckPlank", V(2.94, 0.08, 49.5), CFrame.new(x, 18.025, 0), Theme.WoodLight)
	end
	part(lobby, "WelcomeMat", V(18, 0.08, 11), CFrame.new(0, 18.1, 9), Theme.Blue)
	local sign = part(lobby, "Title", V(34, 8, 0.8), CFrame.new(0, 27, -21), Theme.Ink)
	part(lobby, "TitleTrim", V(35, 0.22, 1), CFrame.new(0, 31.2, -21), Theme.Gold)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local g = Instance.new("SurfaceGui")
		g.Face, g.CanvasSize, g.Parent = face, Vector2.new(1200, 280), sign
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack
		t.TextSize = 76
		t.TextColor3 = Theme.White
		t.Text = "COPY THE SCENE"
		t.Parent = g
	end
	for _, x in ipairs({ -19, 19 }) do
		part(lobby, "PavilionColumn", V(1.2, 17, 1.2), CFrame.new(x, 25.5, -21), Theme.Paper)
	end
	part(lobby, "Canopy", V(42, 0.5, 11), CFrame.new(0, 34, -19), Theme.Blue)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.Position = "LobbySpawn", V(5, 0.2, 5), V(0, 18.3, 9)
	spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
	spawn.Transparency, spawn.CanCollide, spawn.Parent = 1, false, lobby
	W.Spawn = spawn
	local pad = part(lobby, "QueuePad", V(10, 0.3, 8), CFrame.new(0, 18.3, -8), Theme.Blue)
	label(pad, "MATCH QUEUE", V(0, 3.5, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = "Queue", "Join / leave queue", "Copy the Scene"
	prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0, 12, false
	prompt.Parent = pad
	W.QueuePrompt = prompt
	for i = 1, 12 do
		local angle = (i - 1) * math.pi / 9
		local position = V(40 + math.sin(angle) * 18, 18 + (i % 4) * 1.8, math.cos(angle) * 18)
		part(lobby, "JumpStep", V(7, 2, 7), CFrame.new(position), i % 3 == 0 and Theme.Blue or Theme.WoodLight)
	end
	part(lobby, "JumpLanding", V(12, 2, 10), CFrame.new(29, 17, 17), Theme.Wood)
	for _, side in ipairs({ -1, 1 }) do
		part(lobby, "Bench", V(10, 1, 3), CFrame.new(side * 16, 20, 13), Theme.Wood)
		part(lobby, "BenchBack", V(10, 3, 0.6), CFrame.new(side * 16, 21, 14.4), Theme.Blue)
	end
	lobby.WorldPivot = CFrame.identity
	lobby:PivotTo(CFrame.new(0, 0, 520))
	for i = 1, 14 do
		local angle = i * math.pi * 2 / 14
		Scenery.Create("Cliff", root, V(math.sin(angle) * 110, -12, 520 + math.cos(angle) * 100), 1.6, angle)
		Scenery.Create("Pine", root, V(math.sin(angle) * 108, 24, 520 + math.cos(angle) * 98), 1.1, angle)
	end
	local center = Instance.new("Model")
	center.Name, center.Parent = "CenterStage", root
	part(center, "Foundation", V(32, 4, 32), CFrame.new(0, 15.7, 0), Theme.Ink)
	part(center, "Deck", V(32, 0.25, 32), CFrame.new(0, 17.725, 0), Theme.Wood)
	local display = Instance.new("Folder")
	display.Name, display.Parent = "Display", center
	part(display, "Backing", V(24, 0.1, 24), CFrame.new(0, 17.6, 0), Theme.Blue)
	for x = 0, 5 do
		for z = 0, 5 do
			part(
				display,
				"Tile",
				V(3.86, 0.2, 3.86),
				CFrame.new((x - 2.5) * 4, 17.9, (z - 2.5) * 4),
				(x + z) % 2 == 0 and Theme.TileA or Theme.TileB
			)
		end
	end
	part(display, "Front", V(24, 0.15, 0.35), CFrame.new(0, 18.12, -12.3), Theme.Gold)
	local reference = Instance.new("Folder")
	reference.Name, reference.Parent = "Reference", center
	W.Display, W.Reference, W.CenterStage = display, reference, center
	local span = Config.Grid * Config.Cell
	local width = span + 8
	for i = 1, 8 do
		local angle = (i - 1) * math.pi / 4
		local origin = V(math.sin(angle) * 66, 18, math.cos(angle) * 66)
		local plot = Instance.new("Model")
		plot.Name, plot.Parent = "Plot" .. i, root
		local base = part(plot, "Base", V(width, 3.5, width), CFrame.new(origin - V(0, 2.3, 0)), Theme.Ink)
		for _, sign in ipairs({ -1, 1 }) do
			part(
				plot,
				"Rim",
				V(width, 0.45, 4),
				CFrame.new(origin + V(0, -0.225, sign * (span / 2 + 2))),
				Theme.WoodLight
			)
			part(
				plot,
				"Rim",
				V(4, 0.45, span),
				CFrame.new(origin + V(sign * (span / 2 + 2), -0.225, 0)),
				Theme.WoodLight
			)
		end
		local floor = part(plot, "Floor", V(span, 0.2, span), CFrame.new(origin - V(0, 0.1, 0)), Theme.Blue)
		floor.Transparency = 1 -- Invisible raycast/physics plane; only the tiles render.
		part(plot, "GridBacking", V(span, 0.1, span), CFrame.new(origin - V(0, 0.3, 0)), Theme.Blue)
		for x = 0, Config.Grid - 1 do
			for z = 0, Config.Grid - 1 do
				local tile = part(
					plot,
					"Tile",
					V(Config.Cell - 0.14, 0.2, Config.Cell - 0.14),
					CFrame.new(
						origin
							+ V(
								(x + 0.5 - Config.Grid / 2) * Config.Cell,
								-0.1,
								(z + 0.5 - Config.Grid / 2) * Config.Cell
							)
					),
					(x + z) % 2 == 0 and Theme.TileA or Theme.TileB
				)
				tile.CanCollide, tile.CanQuery = false, false
			end
		end
		-- A single amber edge and two entrance markers anchor the layout in memory.
		local front =
			part(plot, "Front", V(span, 0.15, 0.35), CFrame.new(origin + V(0, 0.12, -span / 2 - 0.3)), Theme.Gold)
		local name = label(front, "STAGE " .. i, V(0, 3, 0))
		for _, x in ipairs({ -width / 2 + 1, width / 2 - 1 }) do
			for _, z in ipairs({ -width / 2 + 1, width / 2 - 1 }) do
				part(plot, "Corner", V(0.6, 1.8, 0.6), CFrame.new(origin + V(x, 0.85, z)), Theme.Ink)
				part(plot, "CornerCap", V(0.75, 0.15, 0.75), CFrame.new(origin + V(x, 1.8, z)), Theme.Paper)
			end
		end
		local props, reference = Instance.new("Folder"), Instance.new("Folder")
		props.Name, props.Parent = "Props", plot
		reference.Name, reference.Parent = "Reference", plot
		W.Plots[i] = {
			Model = plot,
			Origin = origin,
			Props = props,
			Reference = reference,
			Label = name,
			Stripe = front,
			Base = base,
			Accent = Theme.Gold,
		}
		local saved = {}
		for _, obj in ipairs(plot:GetDescendants()) do
			if obj:IsA("BasePart") then
				saved[obj] = { Transparency = obj.Transparency, CanCollide = obj.CanCollide, CanQuery = obj.CanQuery }
			end
		end
		W.Plots[i].Saved = saved
	end
	-- Curved perimeter seating gives the islands a clear game-show arena silhouette.
	for i = 1, 32 do
		local angle = i * math.pi / 16
		for tier = 1, 3 do
			local radius = 95 + tier * 3
			local cf = CFrame.new(math.sin(angle) * radius, 8 + tier * 2, math.cos(angle) * radius)
				* CFrame.Angles(0, angle, 0)
			part(root, "Grandstand", V(19.5, 2.8, 3), cf, tier == 3 and Theme.Blue or Theme.Paper)
		end
		if i % 4 == 0 then
			local x, z = math.sin(angle) * 94, math.cos(angle) * 94
			part(root, "LightMast", V(0.65, 22, 0.65), CFrame.new(x, 19, z), Theme.Ink)
			local lamp = part(
				root,
				"StageLight",
				V(4, 0.65, 1.5),
				CFrame.new(x, 30, z) * CFrame.Angles(0, angle, 0),
				Theme.Paper
			)
			local l = Instance.new("PointLight")
			l.Color, l.Brightness, l.Range, l.Parent = Theme.Gold, 0.6, 22, lamp
		end
	end
	-- A compact arcade corner previews an actual scene rather than a toy parade.
	for _, item in ipairs({ { "Arcade", -9, -9 }, { "Table", 7, -9 }, { "Soda", 7, -9, 1 } }) do
		local model = Catalog.Create(item[1])
		model:PivotTo(CFrame.new(item[2], 18 + (item[4] or 0) * Config.Cell, item[3] + 520))
		model.Parent = lobby
	end
	local light = game.Lighting
	light.ClockTime, light.Brightness = 14, 1.8
	light.Ambient, light.OutdoorAmbient = rgb(100, 111, 120), rgb(141, 151, 159)
	light.ExposureCompensation = 0
	local atmosphere = light:FindFirstChild("CopySceneAtmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "CopySceneAtmosphere"
	atmosphere.Density, atmosphere.Offset, atmosphere.Haze = 0.25, 0.15, 1.2
	atmosphere.Color, atmosphere.Decay = rgb(200, 218, 225), rgb(99, 121, 139)
	atmosphere.Parent = light
	return root
end
function W.ShowReference()
	if W.Catapult then
		W.Catapult.Model:Destroy()
		W.Catapult = nil
	end
	W.Reference:ClearAllChildren()
	for _, obj in ipairs(W.Display:GetChildren()) do
		obj.Transparency = 0
	end
end
function W.ShowCatapult()
	W.Reference:ClearAllChildren()
	for _, obj in ipairs(W.Display:GetChildren()) do
		obj.Transparency = 1
	end
	if W.Catapult then
		W.Catapult.Model:Destroy()
	end
	W.Catapult = Catapult.Create(W.CenterStage, W.Center)
end
function W.Restore(i)
	local p = W.Plots[i]
	p.Destroyed = false
	for obj, saved in pairs(p.Saved) do
		for property, value in pairs(saved) do
			obj[property] = value
		end
	end
	p.Label.Parent.Enabled = true
	p.Label.Text = "STAGE " .. i
	p.Stripe.Color = p.Accent
end
function W.Clear()
	W.ShowReference()
	for i, p in ipairs(W.Plots) do
		p.Props:ClearAllChildren()
		p.Reference:ClearAllChildren()
		W.Restore(i)
	end
	local effects = W.Root:FindFirstChild("ImpactDebris")
	if effects then
		effects:Destroy()
	end
end
function W.Eliminate(i)
	local p = W.Plots[i]
	p.Destroyed = true
	p.Label.Parent.Enabled = false
	for _, obj in ipairs(p.Model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency, obj.CanCollide, obj.CanQuery = 1, false, false
		elseif obj:IsA("Fire") or obj:IsA("ParticleEmitter") then
			obj.Enabled = false
		end
	end
	local effects = Instance.new("Folder")
	effects.Name, effects.Parent = "ImpactDebris", W.Root
	local random = Random.new(i)
	for x = -1.5, 1.5 do
		for z = -1.5, 1.5 do
			local chunk = part(
				effects,
				"BrokenDeck",
				V(7.6, 1.1, 7.6),
				CFrame.new(p.Origin + V(x * 8, -0.3, z * 8)),
				(x + z) % 2 == 0 and Theme.Wood or Theme.TileA
			)
			chunk.CanCollide, chunk.CanQuery, chunk.CanTouch = false, false, false
			local goal = chunk.CFrame
				* CFrame.new(x * 8, random:NextNumber(9, 18), z * 8)
				* CFrame.Angles(random:NextNumber(-2, 2), 0, random:NextNumber(-2, 2))
			task.spawn(function()
				local up = TweenService:Create(
					chunk,
					TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = goal }
				)
				up:Play()
				up.Completed:Wait()
				if chunk.Parent then
					TweenService:Create(
						chunk,
						TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ CFrame = goal + V(x * 5, -35, z * 5), Transparency = 1 }
					):Play()
				end
			end)
		end
	end
	local emitterPart = part(effects, "Dust", V(1, 1, 1), CFrame.new(p.Origin), Theme.Paper)
	emitterPart.Transparency, emitterPart.CanCollide = 1, false
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Theme.WoodLight)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 12) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	dust.Rate, dust.Lifetime, dust.Speed = 0, NumberRange.new(1, 2), NumberRange.new(10, 22)
	dust.SpreadAngle, dust.Parent = Vector2.new(180, 180), emitterPart
	dust:Emit(45)
	local sound = Instance.new("Sound")
	sound.SoundId, sound.Volume, sound.RollOffMaxDistance = "rbxasset://sounds/impact_water.mp3", 1, 220
	sound.Parent = emitterPart
	sound:Play()
	game:GetService("Debris"):AddItem(effects, 4)
end
function W.FireAt(i, impact)
	Catapult.Fire(W.Catapult, W.Plots[i].Origin + V(0, 2, 0), function()
		W.Eliminate(i)
		if impact then
			impact()
		end
	end)
end
function W.Perfect(i)
	local p = W.Plots[i]
	p.Label.Text, p.Stripe.Color = "PERFECT!", Theme.Gold
	local a = Instance.new("Attachment")
	a.Parent = p.Stripe
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Theme.Gold, Theme.Paper)
	e.Rate, e.Speed, e.Lifetime = 0, NumberRange.new(12, 20), NumberRange.new(1, 2)
	e.SpreadAngle, e.Parent = Vector2.new(65, 65), a
	e:Emit(40)
	local sound = Instance.new("Sound")
	sound.SoundId, sound.Volume, sound.Parent = "rbxasset://sounds/electronicpingshort.wav", 0.5, p.Stripe
	sound:Play()
	game:GetService("Debris"):AddItem(a, 3)
	game:GetService("Debris"):AddItem(sound, 3)
end
return W
