local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.CopyTheScene
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Placement = require(Shared.Placement)
local Scenes = require(script.Parent.Scenes)
local Scoring = require(script.Parent.Scoring)
local Rules = require(script.Parent.RoundRules)
local World = require(script.Parent.World)
local Persistence = require(script.Parent.Persistence)
local Service = {}
local active

function Service.Start()
	assert(not active, "Game service already running")
	World.Build()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = Shared
	local action = Instance.new("RemoteEvent")
	action.Name = "Action"
	action.Parent = remotes
	local stateEvent = Instance.new("RemoteEvent")
	stateEvent.Name = "State"
	stateEvent.Parent = remotes
	local feedback = Instance.new("RemoteEvent")
	feedback.Name = "Feedback"
	feedback.Parent = remotes
	local state = {
		Phase = "Lobby",
		Deadline = 0,
		Round = 0,
		Records = {},
		Members = {},
		Results = {},
		Practice = false,
		Used = {},
	}
	active = state
	local random = Random.new()
	local function now()
		return workspace:GetServerTimeNow()
	end
	local function alive()
		local list = {}
		for _, player in ipairs(state.Members) do
			if player.Parent and state.Records[player] and state.Records[player].Alive then
				table.insert(list, player)
			end
		end
		return list
	end
	local function send(player)
		local r = state.Records[player]
		if not r then
			return
		end
		local roster = {}
		for _, p in ipairs(state.Members) do
			local pr = state.Records[p]
			if p.Parent and pr then
				table.insert(roster, {
					UserId = p.UserId,
					Name = p.DisplayName,
					Plot = pr.Plot,
					Alive = pr.Alive,
					Submitted = pr.Submitted,
				})
			end
		end
		stateEvent:FireClient(player, {
			Phase = state.Phase,
			Deadline = state.Deadline,
			Round = state.Round,
			SceneName = state.Scene and state.Scene.Name or "",
			Difficulty = state.Scene and state.Scene.Difficulty or 0,
			Plot = r.Plot,
			Alive = r.Alive,
			Submitted = r.Submitted,
			Placed = r.Placed,
			Inventory = (r.Alive and (state.Phase == "Build" or state.Phase == "Results")) and state.Inventory or {},
			Roster = roster,
			Results = state.Results,
			Winner = state.Winner,
			Players = #Players:GetPlayers(),
			Minimum = Config.MinPlayers,
			Practice = state.Practice,
			PracticeAvailable = RunService:IsStudio() and Config.StudioPractice and state.Phase == "Lobby",
		})
	end
	local function broadcast()
		for player in pairs(state.Records) do
			if player.Parent then
				send(player)
			end
		end
	end
	local function phase(name, seconds)
		state.Phase = name
		state.Deadline = seconds and now() + seconds or 0
		broadcast()
	end
	local function move(player)
		local r = state.Records[player]
		local character = player.Character
		if not r or not character then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local building = r.Alive and state.Phase ~= "Lobby" and state.Phase ~= "Countdown"
		root.Anchored = false
		character:PivotTo(
			CFrame.new(
				building and (World.Plots[r.Plot].Origin + Vector3.new(0, 4, Config.Grid * Config.Cell / 2 + 2))
					or Vector3.new(0, 22, 9)
			)
		)
	end
	local function waitPhase()
		while now() < state.Deadline do
			if state.Phase == "Build" then
				local all = true
				for _, p in ipairs(alive()) do
					if not state.Records[p].Submitted then
						all = false
					end
				end
				if all then
					break
				end
			end
			if (state.Phase == "Preview" or state.Phase == "Build") and #alive() <= (state.Practice and 0 or 1) then
				break
			end
			task.wait(0.1)
		end
	end
	local function makeProp(o, parent, origin)
		local model = Catalog.Create(o.ObjectType)
		model:PivotTo(Placement.CFrame(o, origin))
		if o.ID then
			model.Name = "Placed_" .. o.ID
			model:SetAttribute("PlacementId", o.ID)
		end
		model.Parent = parent
		return model
	end
	local function clearToLobby()
		state.Members = {}
		state.Results = {}
		state.Scene = nil
		state.Winner = nil
		state.Practice = false
		state.Round = 0
		World.Clear()
		for player, r in pairs(state.Records) do
			r.Alive = false
			r.Plot = nil
			r.Placed = {}
			r.Submitted = false
			move(player)
		end
		phase("Lobby")
	end
	local function playMatch(members, practice)
		state.Members = members
		state.Practice = practice
		state.Used = {}
		state.Results = {}
		state.Winner = nil
		World.Clear()
		for i = #members, 2, -1 do
			local j = random:NextInteger(1, i)
			members[i], members[j] = members[j], members[i]
		end
		for i, p in ipairs(members) do
			local r = state.Records[p]
			r.Alive = true
			r.Plot = i
			r.Total = 0
			r.TieOrder = i
			r.Placed = {}
			r.Submitted = false
			World.Plots[i].Label.Text = p.DisplayName
		end
		local rounds = practice and 3 or #members - 1
		for round = 1, rounds do
			if #alive() <= (practice and 0 or 1) then
				break
			end
			state.Round = round
			state.Results = {}
			local difficulty = practice and round or math.floor(1 + (round - 1) * 6 / math.max(1, rounds - 1))
			local choices = {}
			for _, s in ipairs(Scenes) do
				if s.Difficulty == difficulty and not state.Used[s.ID] then
					table.insert(choices, s)
				end
			end
			state.Scene = choices[random:NextInteger(1, #choices)]
			state.Used[state.Scene.ID] = true
			state.Inventory = Rules.Inventory(state.Scene)
			for _, plot in ipairs(World.Plots) do
				plot.Props:ClearAllChildren()
				plot.Reference:ClearAllChildren()
			end
			for _, player in ipairs(alive()) do
				local r = state.Records[player]
				r.Placed = {}
				r.Submitted = false
				r.NextID = 0
				local plot = World.Plots[r.Plot]
				plot.Label.Text = player.DisplayName
				for _, o in ipairs(state.Scene.RequiredObjects) do
					makeProp(o, plot.Reference, plot.Origin)
				end
			end
			phase("Preview", state.Scene.PreviewSeconds)
			for _, player in ipairs(alive()) do
				move(player)
			end
			waitPhase()
			for _, plot in ipairs(World.Plots) do
				plot.Reference:ClearAllChildren()
			end
			phase("Build", state.Scene.BuildSeconds)
			waitPhase()
			state.Phase = "Scoring" -- Close action acceptance before calculating any scores.
			local results = {}
			for _, player in ipairs(alive()) do
				local r = state.Records[player]
				local score, breakdown = Scoring.Score(state.Scene.RequiredObjects, r.Placed)
				table.insert(results, {
					UserId = player.UserId,
					Name = player.DisplayName,
					Score = score,
					Breakdown = breakdown,
					Plot = r.Plot,
					PreviousTotal = r.Total,
					TieOrder = r.TieOrder,
				})
				r.Total += score
				if not practice then
					Persistence.Award(player, Config.RoundCoins + (score == 100 and Config.PerfectCoins or 0), 0)
				end
				if score == 100 then
					World.Perfect(r.Plot)
				end
			end
			results = Rules.Rank(results)
			if not practice and #results > 1 then
				local last = results[#results]
				last.Eliminated = true
				for _, p in ipairs(state.Members) do
					if p.UserId == last.UserId then
						state.Records[p].Alive = false
						move(p)
					end
				end
				World.Eliminate(last.Plot)
			end
			state.Results = results
			phase("Results", Config.ResultsSeconds)
			waitPhase()
		end
		local survivors = alive()
		local winner = survivors[1]
		state.Winner = winner and { Name = winner.DisplayName, UserId = winner.UserId, Practice = practice } or nil
		if winner and not practice then
			Persistence.Award(winner, Config.WinCoins, 1)
			task.spawn(Persistence.Save, winner)
		end
		phase("Winner", Config.WinnerSeconds)
		waitPhase()
		clearToLobby()
	end
	local function reject(player, message)
		feedback:FireClient(player, message, false)
	end
	local function handle(player, verb, payload)
		local r = state.Records[player]
		if not r or type(verb) ~= "string" then
			return
		end
		local time = os.clock()
		-- Token bucket, applied to every message including sync requests and invalid payloads.
		r.Tokens = math.min(15, r.Tokens + (time - r.LastRequest) * 8)
		r.LastRequest = time
		if r.Tokens < 1 then
			return
		end
		r.Tokens -= 1
		if verb == "Sync" then
			send(player)
			return
		end
		if verb == "Practice" then
			if RunService:IsStudio() and Config.StudioPractice and state.Phase == "Lobby" then
				state.PracticeRequest = player
			end
			return
		end
		if state.Phase ~= "Build" or not r.Alive or r.Submitted or now() >= state.Deadline then
			reject(player, "Building is closed")
			return
		end
		if verb == "Submit" then
			r.Submitted = true
			broadcast()
			return
		end
		if type(payload) ~= "table" then
			reject(player, "Invalid action")
			return
		end
		if verb == "Place" then
			if type(payload.ObjectType) ~= "string" then
				return
			end
			local capacity = state.Inventory[payload.ObjectType] or 0
			local used = 0
			for _, o in ipairs(r.Placed) do
				if o.ObjectType == payload.ObjectType then
					used += 1
				end
			end
			if used >= capacity or #r.Placed >= 10 then
				reject(player, "No copies left")
				return
			end
			local o = {
				ObjectType = payload.ObjectType,
				X = payload.X,
				Z = payload.Z,
				Level = payload.Level,
			}
			local valid, reason = Placement.Valid(o, r.Placed)
			if not valid then
				reject(player, reason)
				return
			end
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local position = Placement.CFrame(o, World.Plots[r.Plot].Origin).Position
			if not root or (root.Position - position).Magnitude > 65 then
				reject(player, "Come back to your island!")
				return
			end
			r.NextID += 1
			o.ID = r.NextID
			table.insert(r.Placed, o)
			makeProp(o, World.Plots[r.Plot].Props, World.Plots[r.Plot].Origin)
			send(player)
		elseif verb == "Delete" then
			if type(payload.ID) ~= "number" then
				return
			end
			local remaining = {}
			local found
			for _, o in ipairs(r.Placed) do
				if o.ID == payload.ID then
					found = o
				else
					table.insert(remaining, o)
				end
			end
			if not found then
				reject(player, "Select one of your props")
				return
			end
			for _, o in ipairs(remaining) do
				local others = {}
				for _, p in ipairs(remaining) do
					if p ~= o then
						table.insert(others, p)
					end
				end
				if not Placement.Valid(o, others) then
					reject(player, "Remove the prop on top first")
					return
				end
			end
			r.Placed = remaining
			local model = World.Plots[r.Plot].Props:FindFirstChild("Placed_" .. found.ID)
			if model then
				model:Destroy()
			end
			send(player)
		end
	end
	action.OnServerEvent:Connect(handle)
	local function join(player)
		if state.Records[player] then
			return
		end
		state.Records[player] = {
			Alive = false,
			Submitted = false,
			Placed = {},
			Total = 0,
			Tokens = 15,
			LastRequest = os.clock(),
			Joined = os.clock(),
		}
		player.RespawnLocation = World.Spawn
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 45
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			move(player)
		end)
		if player.Character then
			move(player)
		end
		task.spawn(Persistence.Load, player)
		broadcast()
	end
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		state.Records[player] = nil
		task.spawn(Persistence.Remove, player)
		task.defer(broadcast)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		join(player)
	end
	Persistence.Start()
	-- Rescue falls and keep active builders on their own island without restricting normal movement.
	task.spawn(function()
		while task.wait(0.5) do
			for player, r in pairs(state.Records) do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and r.Alive and r.Plot then
					local delta = root.Position - World.Plots[r.Plot].Origin
					local edge = Config.Grid * Config.Cell / 2 + 4
					if math.abs(delta.X) > edge or math.abs(delta.Z) > edge or delta.Y < -5 then
						move(player)
					end
				elseif root and root.Position.Y < 4 then
					move(player)
				end
			end
		end
	end)
	-- Only server-side Studio tooling can shorten a phase for integration checks.
	if RunService:IsStudio() then
		state.Advance = function()
			state.Deadline = now()
		end
		state.Handle = handle
		local debug = Instance.new("BindableFunction")
		debug.Name = "StudioTest"
		debug.Parent = script.Parent
		debug.OnInvoke = function(verb, player, payload)
			if verb == "Advance" then
				state.Deadline = now()
				return true
			end
			if verb == "Hold" then
				state.Deadline = now() + 600
				broadcast()
				return true
			end
			if verb == "Action" then
				handle(player, payload.Verb, payload.Data)
				return true
			end
			local records = {}
			for p, r in pairs(state.Records) do
				records[tostring(p.UserId)] =
					{ Alive = r.Alive, Plot = r.Plot, Placed = r.Placed, Submitted = r.Submitted }
			end
			return {
				Phase = state.Phase,
				Round = state.Round,
				Scene = state.Scene,
				Records = records,
				Results = state.Results,
				Practice = state.Practice,
				Winner = state.Winner,
			}
		end
	end
	task.spawn(function()
		while true do
			if state.PracticeRequest then
				local p = state.PracticeRequest
				state.PracticeRequest = nil
				if p.Parent and state.Phase == "Lobby" then
					playMatch({ p }, true)
				end
			elseif #Players:GetPlayers() >= Config.MinPlayers then
				phase("Countdown", Config.LobbySeconds)
				while now() < state.Deadline and #Players:GetPlayers() >= Config.MinPlayers do
					task.wait(0.2)
				end
				if #Players:GetPlayers() >= Config.MinPlayers then
					local members = Players:GetPlayers()
					table.sort(members, function(a, b)
						return state.Records[a].Joined < state.Records[b].Joined
					end)
					while #members > Config.MaxPlayers do
						table.remove(members)
					end
					playMatch(members, false)
				else
					phase("Lobby")
				end
			end
			task.wait(0.2)
		end
	end)
	print("[CopyTheScene] Ready. Live matches require 4 players; Studio practice is available.")
	return state
end
function Service.Get()
	return active
end
return Service
