local T = {}
function T.Run()
	local Shared = game.ReplicatedStorage.CopyTheScene
	local Placement = require(Shared.Placement)
	local Catalog = require(Shared.Catalog)
	local Config = require(Shared.Config)
	local Scoring = require(script.Parent.Scoring)
	local Scenes = require(script.Parent.Scenes)
	local Rules = require(script.Parent.RoundRules)
	local Persistence = require(script.Parent.Persistence)
	local Queue = require(script.Parent.Queue)
	local checks = 0
	local function check(ok, message)
		checks += 1
		assert(ok, message)
	end
	local function o(kind, x, z, level)
		return { ObjectType = kind, X = x, Z = z, Level = level or 0 }
	end
	check(#Scenes == 20, "Expected 20 scenes")
	local ids = {}
	local a, b, c, d = { Parent = true }, { Parent = true }, { Parent = true }, { Parent = true }
	local records = {
		[a] = { Queued = false, QueueOrder = 1 },
		[b] = { Queued = true, QueueOrder = 3 },
		[c] = { Queued = true, QueueOrder = 2 },
		[d] = { Queued = true, QueueOrder = 0, InMatch = true },
	}
	local queue = Queue.List(records)
	check(
		#queue == 2 and queue[1] == c and queue[2] == b,
		"Queue requires opt-in, excludes participants, preserves arrival order"
	)
	records[c].Queued = false
	check(#Queue.List(records) == 1, "Leaving queue removes entry")
	b.Parent = nil
	check(#Queue.List(records) == 0, "Disconnected players cannot enter match")
	for _, scene in ipairs(Scenes) do
		check(not ids[scene.ID], "Duplicate scene")
		ids[scene.ID] = true
		check(scene.PreviewSeconds == 8 and scene.BuildSeconds >= 45 and scene.BuildSeconds <= 75, "Bad timing")
		local placed = {}
		for i, obj in ipairs(scene.RequiredObjects) do
			local valid, reason = Placement.Valid(obj, placed)
			check(valid, scene.ID .. " object " .. i .. ": " .. reason)
			check(obj.Color == nil and obj.Rotation == nil, "Scene must not require color or rotation")
			table.insert(placed, obj)
		end
		check(Scoring.Score(placed, placed) == 100, "Exact scene must score perfect")
		local reversed = {}
		for i = #placed, 1, -1 do
			table.insert(reversed, placed[i])
		end
		check(Scoring.Score(placed, reversed) == 100, "Creation order must not affect score")
		local n = 0
		for _, count in pairs(Rules.Inventory(scene)) do
			n += count
		end
		check(n <= 10, "Too much inventory")
	end
	local targets = { o("Gummy", 2, 3), o("Gummy", 8, 6) }
	check(Scoring.Score(targets, {}) == 0, "Empty score")
	check(Scoring.Score(targets, { targets[2], targets[1] }) == 100, "Closest duplicate matching")
	check(Scoring.Score({ targets[1] }, { o("Gummy", 3, 3) }) == 90, "One cell: 90 percent")
	check(Scoring.Score({ targets[1] }, { o("Alien", 2, 3) }) == 0, "Wrong prop")
	check(Scoring.Score({ targets[1] }, { targets[1], o("Alien", 8, 6) }) == 95, "Extra penalty")
	check(Scoring.Score(targets, { targets[1] }) == 50, "Missing prop")
	check(
		Scoring.Score({ o("Gummy", 0, 0), o("Gummy", 4, 0) }, { o("Gummy", 3, 0), o("Gummy", 7, 0) }) == 70,
		"Minimum distance assignment"
	)
	check(not Placement.Valid(o("Cake", 11, 0), {}), "Out of bounds")
	check(not Placement.Valid(o("Gift", 0 / 0, 0), {}), "NaN")
	check(not Placement.Valid(o("Gift", math.huge, 0), {}), "Infinity")
	check(not Placement.Valid(o("Gift", 0.5, 0), {}), "Off grid")
	check(not Placement.Valid(o("Gift", 0, 0, 1), {}), "Floating")
	check(not Placement.Valid(o("Gift", 4, 4), { o("Gift", 4, 4) }), "Collision")
	check(Placement.Valid(o("Gift", 4, 4, 1), { o("Gift", 4, 4) }), "Stack gifts")
	check(Placement.Valid(o("Cat", 4, 4, 1), { o("Pizza", 4, 4) }), "Cat on pizza")
	check(not Placement.Valid(o("Cat", 4, 4, 2), { o("Rocket", 4, 4) }), "Non-stackable")
	check(not Placement.Valid(o("Cake", 4, 4, 1), { o("Crate", 4, 4) }), "No oversized stack")
	local aim = Placement.FromPoint(Vector3.new(8, 4, 8), Vector3.zero, "Gift", o("Cake", 4, 4))
	check(aim.Level == 1 and aim.X == 5 and aim.Z == 5, "Automatic top-surface stacking")
	local cf = Placement.CFrame(o("Gift", 0, 0), Vector3.zero)
	check(cf.Position == Vector3.new(-10, 0, -10), "Cell centers match physical tiles")
	check(Placement.Valid(o("Skateboard", 5, 4), {}), "Last grid column accepts a narrow prop")
	check(not Placement.Valid(o("Skateboard", 5, 5), {}), "Footprint cannot cross the last row")
	check(not Placement.Valid(o("Crate", 6, 0), {}), "Reject the removed outer cells")
	check(Placement.FromPoint(Vector3.new(-10, 0, -10), Vector3.zero, "Crate").X == 0, "First tile ray hit")
	local ranked = Rules.Rank({
		{ Score = 50, PreviousTotal = 80, TieOrder = 2 },
		{ Score = 50, PreviousTotal = 90, TieOrder = 3 },
		{ Score = 50, PreviousTotal = 90, TieOrder = 1 },
	})
	check(ranked[1].TieOrder == 1 and ranked[3].TieOrder == 2, "Tie rules")
	local data = Persistence.Merge(nil, "a", 10, 1, 100)
	data = Persistence.Merge(data, "a", 10, 1, 101)
	check(data.Coins == 10 and data.Wins == 1, "No duplicate rewards")
	data = Persistence.Merge(data, "b", 20, 2, 102)
	data = Persistence.Merge(data, "a", 15, 1, 103)
	check(data.Coins == 35 and data.Wins == 3, "Concurrent sessions")
	data = Persistence.Merge(data, "a", 10, 1, 104)
	check(data.Coins == 35 and data.Wins == 3, "Stale save")
	for kind, d in pairs(Catalog.Definitions) do
		local model = Catalog.Create(kind)
		check(#model:GetChildren() > 0, "Empty prop " .. kind)
		local cf, size = model:GetBoundingBox()
		check(math.abs(cf.Position.Y - size.Y / 2) < 0.02, kind .. " must rest on its base")
		check(
			size.X <= d.W * Config.Cell + 0.25 and size.Z <= d.D * Config.Cell + 0.25,
			kind .. " exceeds its grid footprint"
		)
		for _, descendant in ipairs(model:GetDescendants()) do
			check(not descendant:IsA("LuaSourceContainer"), "Prop contains executable code")
		end
		model:Destroy()
	end
	return string.format(
		"PASS: %d checks; 20 playful scenes, stacking, scoring, placement, save retry invariants",
		checks
	)
end
function T.World(world)
	assert(not game:GetService("RunService"):IsRunning(), "World restoration checks require Edit mode")
	assert(#world.Plots == 8, "Eight match islands required")
	assert(not world.Root:FindFirstChild("Boardwalk", true), "Match islands must be disconnected")
	assert((world.Spawn.Position - world.Center).Magnitude > 400, "Lobby must be separate from arena")
	for _, plot in ipairs(world.Plots) do
		local floor = plot.Model.Floor
		assert(
			floor.Transparency == 1 and floor.CanQuery and floor.CanCollide,
			"Invisible placement and collision plane"
		)
		local tiles = 0
		for _, tile in ipairs(plot.Model:GetChildren()) do
			if tile.Name == "Tile" then
				tiles += 1
				assert(
					math.abs(tile.Position.Y + tile.Size.Y / 2 - plot.Origin.Y) < 0.001,
					"Tile top and placement plane agree"
				)
				local backing = plot.Model.GridBacking
				assert(
					tile.Position.Y + tile.Size.Y / 2 - backing.Position.Y - backing.Size.Y / 2 > 0.2,
					"Visible backing cannot fight with tile top"
				)
			end
		end
		assert(tiles == 36, "Six by six visible tiles")
	end
	world.Eliminate(8)
	for _, obj in ipairs(world.Plots[8].Model:GetDescendants()) do
		if obj:IsA("BasePart") then
			assert(obj.Transparency == 1 and not obj.CanCollide, "Impact removes entire island")
		end
	end
	assert(
		world.Plots[1].Base.Transparency == 0 and world.Plots[1].Model.Floor.CanCollide,
		"Impact must not affect other islands"
	)
	world.Clear()
	assert(
		world.Plots[8].Base.Transparency == 0
			and world.Plots[8].Model.Floor.Transparency == 1
			and world.Plots[8].Model.Floor.CanCollide,
		"Match reset restores island without exposing hidden floor"
	)
	assert(world.Plots[8].Label.Parent.Enabled, "Reset restores stage label")
	return "PASS: world layout, tile depth separation, isolated destruction, and match restoration"
end
return T
