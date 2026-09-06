local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)
local player = Players.LocalPlayer
local shared = game.ReplicatedStorage:WaitForChild("CopyTheScene")
local Catalog = require(shared.Catalog)
local Placement = require(shared.Placement)
local Config = require(shared.Config)
local remotes = shared:WaitForChild("Remotes")
local action = remotes:WaitForChild("Action")
local stateRemote = remotes:WaitForChild("State")
local feedback = remotes:WaitForChild("Feedback")
local camera = workspace.CurrentCamera
local state = { Phase = "Loading", Placed = {}, Inventory = {}, Roster = {}, Results = {} }
local Theme = require(shared.Theme)
local palette = {
	Ink = Theme.Ink,
	Blue = Theme.Blue,
	Accent = Theme.Accent,
	Danger = Theme.Danger,
	Gold = Theme.Gold,
	Paper = Theme.Paper,
	White = Theme.White,
	Line = Theme.Line,
}
local selected, ghost, ghostKind, footprint = nil, nil, nil, nil
local candidate, aimedProp = nil, nil
local deleteMode = false
local types, cards = {}, {}
local lastPhase, lastRound, inventoryKey = "", 0, ""
local confirmUntil, toastUntil = 0, 0
local spectateIndex, spectating = 1, false
local touchPoint
local inputMode = UIS.TouchEnabled and not UIS.MouseEnabled and "Touch" or "Mouse"
local render, updateAim, refreshGhost, place, remove, submit, cycleType, layout

local gui = Instance.new("ScreenGui")
gui.Name = "CopyTheSceneUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui
local function round(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = obj
end
local function stroke(obj, color, width)
	local s = Instance.new("UIStroke")
	s.Name = "Outline"
	s.Color = color or palette.Ink
	s.Thickness = width or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end
local function panel(parent, name, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color or palette.Paper
	f.BorderSizePixel = 0
	f.Parent = parent
	round(f)
	stroke(f)
	return f
end
local function label(parent, name, value, size, color, outlined)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Text = value
	t.TextColor3 = color or palette.Ink
	t.Font = Enum.Font.GothamBold
	t.TextSize = size or 20
	t.BackgroundTransparency = 1
	t.TextWrapped = true
	t.Parent = parent
	if outlined then
		t.TextStrokeColor3 = palette.Ink
		t.TextStrokeTransparency = 0.55
	end
	return t
end
local function button(parent, name, value, color, callback)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = value
	b.BackgroundColor3 = color
	b.TextColor3 = (color == palette.Paper or color == palette.Gold) and palette.Ink or palette.White
	b.TextStrokeColor3 = palette.Ink
	b.TextStrokeTransparency = 1
	b.Font = Enum.Font.GothamBold
	b.TextSize = 21
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Parent = parent
	round(b, 10)
	stroke(b)
	b.Activated:Connect(callback)
	return b
end
local function rect(obj, x, y, w, h)
	obj.Position = UDim2.fromOffset(x, y)
	obj.Size = UDim2.fromOffset(w, h)
end
local function insideOurButton(point)
	for _, obj in ipairs(player.PlayerGui:GetGuiObjectsAtPosition(point.X, point.Y)) do
		if obj:IsDescendantOf(gui) and (obj:IsA("TextButton") or obj:IsA("ScrollingFrame")) then
			return true
		end
	end
	return false
end

local header = panel(root, "Header", palette.Ink)
header.AnchorPoint = Vector2.new(0.5, 0)
local phaseLabel = label(header, "Phase", "Welcome!", 25, palette.White, true)
local sceneLabel = label(header, "Scene", "Copy the Scene", 15, palette.White)
local timer = label(header, "Timer", "", 28, palette.Gold, true)
local progress = Instance.new("Frame")
progress.Name = "Progress"
progress.BackgroundColor3 = palette.Gold
progress.BorderSizePixel = 0
progress.Size = UDim2.new(1, -18, 0, 5)
progress.Position = UDim2.new(0, 9, 1, -9)
progress.Parent = header
round(progress, 3)
local currency = panel(root, "Currency", palette.Paper)
currency.AnchorPoint = Vector2.new(1, 0)
local coins = label(currency, "Coins", "0 coins", 19)
local wins = label(root, "Wins", "0 wins", 16, palette.White, true)
wins.AnchorPoint = Vector2.new(1, 0)
local welcome = panel(root, "Welcome", palette.Paper)
welcome.AnchorPoint = Vector2.new(0.5, 1)
local welcomeTitle = label(welcome, "Title", "Think fast. Build it back.", 28, palette.Blue)
local welcomeCopy = label(welcome, "Copy", "Remember the setup. Rebuild it. Stay in the game.", 17)
local waiting = label(welcome, "Waiting", "Waiting for players: 1 / 4", 18)
local practice = button(welcome, "Practice", "PLAY PRACTICE", palette.Gold, function()
	action:FireServer("Practice")
end)
local practiceNote = label(welcome, "PracticeNote", "Try 3 rounds on your own", 13)

local build = Instance.new("Frame")
build.Name = "Build"
build.BackgroundTransparency = 1
build.Size = UDim2.fromScale(1, 1)
build.Parent = root
local hotbar = Instance.new("ScrollingFrame")
hotbar.Name = "Hotbar"
hotbar.BackgroundTransparency = 1
hotbar.BorderSizePixel = 0
hotbar.ScrollBarThickness = 4
hotbar.ScrollingDirection = Enum.ScrollingDirection.X
hotbar.Parent = build
local row = Instance.new("UIListLayout")
row.FillDirection = Enum.FillDirection.Horizontal
row.Padding = UDim.new(0, 8)
row.SortOrder = Enum.SortOrder.LayoutOrder
row.Parent = hotbar
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingTop = UDim.new(0, 4)
padding.Parent = hotbar
local placeButton = button(build, "Place", "PLACE", palette.Gold, function()
	if deleteMode then
		remove()
	else
		place()
	end
end)
local deleteButton = button(build, "Delete", "REMOVE", palette.Paper, function()
	deleteMode = not deleteMode
	refreshGhost()
end)
local submitButton = button(build, "Submit", "DONE", palette.Blue, function()
	submit()
end)
local hint = label(build, "Hint", "Pick a prop!", 16, palette.White, true)
local crosshair = label(root, "Crosshair", "+", 28, palette.White, true)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(32, 32)
local previewHint =
	label(root, "PreviewHint", "Walk around and remember where everything goes!", 20, palette.White, true)
previewHint.AnchorPoint = Vector2.new(0.5, 1)
local toast = panel(root, "Toast", palette.Paper)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Visible = false
local toastText = label(toast, "Message", "", 17)
toastText.Size = UDim2.new(1, -20, 1, 0)
toastText.Position = UDim2.fromOffset(10, 0)
local function message(value, good)
	toastText.Text = value
	toastText.TextColor3 = good and palette.Ink or Color3.fromRGB(182, 48, 86)
	toast.Visible = true
	toastUntil = os.clock() + 2.8
end

local results = panel(root, "Results", palette.Paper)
results.AnchorPoint = Vector2.new(0.5, 0.5)
local resultTitle = label(results, "Title", "Nice building!", 30, palette.Blue)
local resultSub = label(results, "Subtitle", "", 16)
local resultRows = Instance.new("ScrollingFrame")
resultRows.Name = "Rows"
resultRows.BackgroundTransparency = 1
resultRows.BorderSizePixel = 0
resultRows.ScrollBarThickness = 4
resultRows.Parent = results
local resultFoot = label(results, "Foot", "", 14)
local spectator = panel(root, "Spectator", palette.Blue)
spectator.AnchorPoint = Vector2.new(0.5, 1)
local watched = label(spectator, "Watched", "Watching", 18, palette.White, true)
local previous = button(spectator, "Previous", "<", palette.Blue, function()
	spectating = true
	spectateIndex -= 1
end)
local nextButton = button(spectator, "Next", ">", palette.Blue, function()
	spectating = true
	spectateIndex += 1
end)

layout = function()
	local size = gui.AbsoluteSize
	local w, h = size.X, size.Y
	local phone = h < 520 or w < 700
	local hw = math.min(phone and 320 or 420, w - 150)
	if w < 540 then
		hw = w - 30
	end
	header.Size = UDim2.fromOffset(hw, phone and 65 or 78)
	header.Position = UDim2.new(0.5, 0, 0, 10)
	rect(phaseLabel, 8, 3, hw - 72, 32)
	phaseLabel.TextSize = phone and 21 or 26
	rect(sceneLabel, 8, 34, hw - 72, 20)
	sceneLabel.TextSize = phone and 13 or 16
	rect(timer, hw - 64, 3, 58, 50)
	currency.Size = UDim2.fromOffset(phone and 113 or 140, 36)
	currency.Position = UDim2.new(1, -12, 0, w < 540 and 85 or 12)
	coins.Size = UDim2.fromScale(1, 1)
	coins.TextSize = phone and 17 or 20
	wins.Position = UDim2.new(1, -14, 0, w < 540 and 123 or 51)
	wins.Size = UDim2.fromOffset(130, 25)
	local ww = math.min(phone and 355 or 425, w - 30)
	local wh = phone and 180 or 225
	welcome.Size = UDim2.fromOffset(ww, wh)
	welcome.Position = UDim2.new(0.5, 0, 1, -16)
	rect(welcomeTitle, 10, 8, ww - 20, 34)
	welcomeTitle.TextSize = phone and 25 or 30
	rect(welcomeCopy, 18, 46, ww - 36, phone and 36 or 44)
	welcomeCopy.TextSize = phone and 15 or 18
	rect(waiting, 10, phone and 85 or 99, ww - 20, 26)
	rect(practice, 25, phone and 113 or 135, ww - 50, 46)
	rect(practiceNote, 10, phone and 160 or 189, ww - 20, 22)
	local cardW, cardH = phone and 74 or 92, phone and 78 or 96
	local barW = math.min(#types * (cardW + 8) + 8, phone and math.max(140, w - 265) or math.max(200, w - 425))
	hotbar.Size = UDim2.fromOffset(barW, cardH + 12)
	hotbar.AnchorPoint = Vector2.new(phone and 0.5 or 0, 1)
	hotbar.Position = phone and UDim2.new(0.5, 0, 1, -8) or UDim2.new(0, 14, 1, -14)
	hotbar.CanvasSize = UDim2.fromOffset(#types * (cardW + 8) + 8, 0)
	for kind, b in pairs(cards) do
		b.Size = UDim2.fromOffset(cardW, cardH)
		b.Preview.Size = UDim2.new(1, -8, 1, -27)
		b.Preview.Position = UDim2.fromOffset(4, 0)
		b.Count.Position = UDim2.new(0, 2, 1, -27)
		b.Count.Size = UDim2.new(1, -4, 0, 25)
		b.Count.TextSize = phone and 12 or 15
		b.Stock.Position = UDim2.new(1, -24, 0, 3)
		b.Stock.Size = UDim2.fromOffset(22, 22)
	end
	if phone then
		local ay = math.max(12, h - 245)
		rect(placeButton, w - 114, ay, 102, 44)
		rect(deleteButton, w - 114, ay + 48, 102, 44)
		rect(submitButton, w - 114, ay + 96, 102, 44)
	else
		rect(placeButton, w - 380, h - 86, 112, 54)
		rect(deleteButton, w - 259, h - 86, 112, 54)
		rect(submitButton, w - 138, h - 86, 122, 54)
	end
	placeButton.TextSize = phone and 20 or 23
	deleteButton.TextSize = phone and 18 or 20
	submitButton.TextSize = phone and 21 or 23
	hint.Size = UDim2.fromOffset(math.min(w - 250, 700), 25)
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, phone and 0 or -80, 1, -cardH - 22)
	hint.TextSize = phone and 14 or 17
	toast.Size = UDim2.fromOffset(math.min(460, w - 30), 48)
	toast.Position = UDim2.new(0.5, 0, 0, phone and 88 or 102)
	previewHint.Size = UDim2.new(1, -40, 0, 35)
	previewHint.Position = UDim2.new(0.5, 0, 1, -22)
	previewHint.TextSize = phone and 16 or 21
	local rw = math.min(480, w - 30)
	local rh = math.min(420, h - 105)
	results.Size = UDim2.fromOffset(rw, rh)
	results.Position = UDim2.new(0.5, 0, 0.5, 36)
	rect(resultTitle, 12, 8, rw - 24, 42)
	resultTitle.TextSize = phone and 25 or 30
	rect(resultSub, 16, 49, rw - 32, 36)
	rect(resultRows, 18, 91, rw - 36, rh - 141)
	rect(resultFoot, 16, rh - 43, rw - 32, 36)
	spectator.Size = UDim2.fromOffset(math.min(380, w - 30), 55)
	spectator.Position = UDim2.new(0.5, 0, 1, -18)
	watched.Size = UDim2.new(1, -112, 1, 0)
	watched.Position = UDim2.fromOffset(56, 0)
	rect(previous, 8, 6, 43, 43)
	nextButton.Size = UDim2.fromOffset(43, 43)
	nextButton.Position = UDim2.new(1, -51, 0, 6)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
local function building()
	return state.Phase == "Build" and state.Alive and not state.Submitted
end
local function plotInfo(index)
	local world = workspace:FindFirstChild("CopyTheSceneWorld")
	local plot = world and world:FindFirstChild("Plot" .. tostring(index))
	local floor = plot and plot:FindFirstChild("Floor")
	return floor and floor.Position + Vector3.new(0, 0.1, 0), plot
end
local function remaining(kind)
	local n = state.Inventory[kind] or 0
	for _, o in ipairs(state.Placed) do
		if o.ObjectType == kind then
			n -= 1
		end
	end
	return n
end
local function destroyGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if footprint then
		footprint:Destroy()
		footprint = nil
	end
	ghostKind = nil
end
refreshGhost = function()
	deleteButton.Text = deleteMode and "CANCEL" or "REMOVE"
	placeButton.Text = deleteMode and "REMOVE" or (inputMode == "Gamepad" and "PLACE [RT]" or "PLACE")
	if not building() or not selected or not candidate or deleteMode then
		destroyGhost()
		if deleteMode then
			hint.Text = aimedProp and "Remove this prop?" or "Aim at a prop to remove it"
		else
			hint.Text = "Pick a prop, then aim at a square!"
		end
		return
	end
	local origin = plotInfo(state.Plot)
	if not origin then
		return
	end
	if ghostKind ~= selected then
		destroyGhost()
		ghost = Catalog.Create(selected)
		ghost.Name = "PlacementPreview"
		ghost.Parent = workspace
		ghostKind = selected
		for _, p in ipairs(ghost:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = false
				p.CanQuery = false
				p.Transparency = math.max(p.Transparency, 0.35)
			elseif p:IsA("Fire") then
				p.Enabled = false
			end
		end
		local hi = Instance.new("Highlight")
		hi.Name = "Validity"
		hi.FillTransparency = 0.7
		hi.OutlineTransparency = 0
		hi.Parent = ghost
		footprint = Instance.new("Part")
		footprint.Name = "PlacementFootprint"
		footprint.Anchored = true
		footprint.CanCollide = false
		footprint.CanQuery = false
		footprint.Material = Enum.Material.Neon
		footprint.Transparency = 0.6
		footprint.Parent = workspace
	end
	local valid, reason = Placement.Valid(candidate, state.Placed)
	if remaining(selected) <= 0 then
		valid = false
		reason = "All used! Pick another prop."
	end
	local cf = Placement.CFrame(candidate, origin)
	ghost:PivotTo(cf)
	local d = Catalog.Definitions[selected]
	footprint.Size = Vector3.new(d.W * Config.Cell - 0.12, 0.08, d.D * Config.Cell - 0.12)
	footprint.CFrame = cf * CFrame.new(0, 0.05, 0)
	local color = valid and Color3.fromRGB(91, 255, 129) or Color3.fromRGB(255, 64, 92)
	ghost.Validity.FillColor = color
	ghost.Validity.OutlineColor = color
	footprint.Color = color
	hint.Text = Catalog.Definitions[selected].Name .. "  -  " .. reason
	gui:SetAttribute("AimX", candidate.X)
	gui:SetAttribute("AimZ", candidate.Z)
	gui:SetAttribute("AimLevel", candidate.Level)
end
updateAim = function(point)
	if not building() or not selected then
		candidate = nil
		aimedProp = nil
		refreshGhost()
		return
	end
	local origin, plot = plotInfo(state.Plot)
	if not plot then
		return
	end
	local ray = camera:ViewportPointToRay(point.X, point.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { plot.Floor, plot.Props }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 250, params)
	candidate = nil
	aimedProp = nil
	if hit then
		local obj = hit.Instance
		while obj and obj ~= plot do
			local id = obj:GetAttribute("PlacementId")
			if id then
				for _, o in ipairs(state.Placed) do
					if o.ID == id then
						aimedProp = o
						break
					end
				end
				break
			end
			obj = obj.Parent
		end
		local support = hit.Normal.Y > 0.4 and aimedProp or nil
		candidate = Placement.FromPoint(hit.Position, origin, selected, support)
	end
	refreshGhost()
end
place = function()
	if not building() or not candidate or not selected then
		message("Aim at your island first!", false)
		return
	end
	local valid, reason = Placement.Valid(candidate, state.Placed)
	if not valid then
		message(reason, false)
		return
	end
	if remaining(selected) <= 0 then
		message("No copies left!", false)
		return
	end
	action:FireServer("Place", candidate)
end
remove = function()
	if building() and aimedProp then
		action:FireServer("Delete", { ID = aimedProp.ID })
	else
		message("Aim at the prop you want to remove", false)
	end
end
submit = function()
	if not building() then
		return
	end
	if os.clock() < confirmUntil then
		action:FireServer("Submit")
		confirmUntil = 0
	else
		confirmUntil = os.clock() + 3
		message("Finished? Press DONE again to lock it in!", true)
	end
end
cycleType = function(delta)
	if #types == 0 then
		return
	end
	local i = table.find(types, selected) or 1
	selected = types[(i - 1 + delta) % #types + 1]
	deleteMode = false
	render()
end
local function rebuild()
	for _, b in pairs(cards) do
		b:Destroy()
	end
	cards = {}
	types = {}
	for kind in pairs(state.Inventory) do
		table.insert(types, kind)
	end
	table.sort(types)
	if not table.find(types, selected) then
		selected = types[1]
	end
	for i, kind in ipairs(types) do
		local d = Catalog.Definitions[kind]
		local b = button(hotbar, kind, "", palette.Paper, function()
			selected = kind
			deleteMode = false
			render()
		end)
		b.LayoutOrder = i
		cards[kind] = b
		local view = Instance.new("ViewportFrame")
		view.Name = "Preview"
		view.BackgroundTransparency = 1
		view.Ambient = Color3.new(0.8, 0.8, 0.8)
		view.LightColor = Color3.new(1, 1, 1)
		view.Parent = b
		local cam = Instance.new("Camera")
		cam.Parent = view
		view.CurrentCamera = cam
		local world = Instance.new("WorldModel")
		world.Parent = view
		local model = Catalog.Create(kind)
		model.Parent = world
		local cf, size = model:GetBoundingBox()
		local distance = math.max(size.X, size.Y, size.Z) * 1.2
		cam.FieldOfView = 40
		cam.CFrame =
			CFrame.lookAt(cf.Position + Vector3.new(distance * 0.7, distance * 0.65, distance * 1.3), cf.Position)
		local count = label(b, "Count", d.Name, 15, palette.Ink, false)
		local stock = label(b, "Stock", "1", 17, palette.Ink, false)
	end
	layout()
end
render = function()
	local lobby = state.Phase == "Lobby" or state.Phase == "Countdown" or state.Phase == "Loading"
	currency.Visible = lobby or state.Phase == "Results" or state.Phase == "Winner"
	wins.Visible = currency.Visible
	welcome.Visible = lobby
	build.Visible = building()
	previewHint.Visible = state.Phase == "Preview"
	results.Visible = state.Phase == "Results" or state.Phase == "Winner"
	spectator.Visible = not lobby and not results.Visible and (not state.Alive or state.Submitted)
	crosshair.Visible = building() and (inputMode == "Gamepad" or (UIS.MouseBehavior == Enum.MouseBehavior.LockCenter))
	practice.Visible = state.PracticeAvailable == true
	practiceNote.Visible = practice.Visible
	waiting.Text = state.Phase == "Countdown" and "A match is starting!"
		or string.format("Waiting for players: %d / %d", state.Players or 1, state.Minimum or 4)
	local titles = {
		Lobby = "COPY THE SCENE",
		Countdown = "Get ready",
		Preview = "Remember the scene",
		Build = "Build it back",
		Results = "Round results",
		Winner = "Last builder standing",
		Loading = "Loading...",
	}
	phaseLabel.Text = titles[state.Phase] or state.Phase
	if state.Practice and state.Phase == "Winner" then
		phaseLabel.Text = "Practice complete!"
	end
	sceneLabel.Text = lobby and "Copy the Scene!" or state.SceneName
	if state.Submitted and state.Phase == "Build" then
		phaseLabel.Text = "Build locked in!"
	end
	local sorted = {}
	for kind, n in pairs(state.Inventory) do
		table.insert(sorted, kind .. n)
	end
	table.sort(sorted)
	local key = table.concat(sorted, "|")
	if key ~= inventoryKey then
		inventoryKey = key
		rebuild()
	end
	if not selected then
		selected = types[1]
	end
	for kind, b in pairs(cards) do
		b.Outline.Color = kind == selected and palette.Gold or palette.Line
		b.Outline.Thickness = kind == selected and 3 or 1.5
		b.Stock.Text = "x" .. remaining(kind)
		b.BackgroundTransparency = remaining(kind) > 0 and 0 or 0.35
	end
	if selected and cards[selected] then
		local b = cards[selected]
		local x = b.AbsolutePosition.X - hotbar.AbsolutePosition.X + hotbar.CanvasPosition.X
		if x < hotbar.CanvasPosition.X then
			hotbar.CanvasPosition = Vector2.new(math.max(0, x - 4), 0)
		elseif x + b.AbsoluteSize.X > hotbar.CanvasPosition.X + hotbar.AbsoluteSize.X then
			hotbar.CanvasPosition = Vector2.new(x + b.AbsoluteSize.X - hotbar.AbsoluteSize.X + 5, 0)
		end
	end
	if state.Phase == "Results" then
		resultTitle.Text = "Round " .. state.Round .. " results!"
		resultSub.Text = state.Practice and "Check your score. Next scene coming up." or "Lowest score is out!"
		resultRows:ClearAllChildren()
		for i, r in ipairs(state.Results) do
			local line = panel(
				resultRows,
				"Row" .. i,
				r.Eliminated and Color3.fromRGB(224, 199, 190) or Color3.fromRGB(217, 226, 226)
			)
			rect(line, 4, (i - 1) * 43, resultRows.AbsoluteSize.X - 12, 36)
			local name = label(line, "Name", i .. ". " .. r.Name .. (r.Eliminated and " - OUT!" or ""), 17)
			name.TextXAlignment = Enum.TextXAlignment.Left
			rect(name, 8, 0, line.Size.X.Offset - 112, 36)
			local score = label(
				line,
				"Score",
				r.Score == 100 and "PERFECT!" or r.Score .. "%",
				20,
				r.Score == 100 and Color3.fromRGB(47, 141, 69) or palette.Blue
			)
			score.AnchorPoint = Vector2.new(1, 0)
			score.Position = UDim2.new(1, -7, 0, 0)
			score.Size = UDim2.fromOffset(99, 36)
			if r.UserId == player.UserId then
				resultFoot.Text =
					string.format("Right props: %d%%   Right spots: %d%%", r.Breakdown.Object, r.Breakdown.Position)
			end
		end
		resultRows.CanvasSize = UDim2.fromOffset(0, #state.Results * 43)
	elseif state.Phase == "Winner" then
		resultTitle.Text = state.Practice and "Practice complete" or "Champion!"
		resultSub.Text = state.Practice and "Three rounds complete. Ready for a match?" or "Last builder standing!"
		resultRows:ClearAllChildren()
		local name =
			label(resultRows, "Winner", state.Winner and state.Winner.Name or "Everyone went home!", 32, palette.Blue)
		name.Size = UDim2.new(1, 0, 1, 0)
		resultRows.CanvasSize = UDim2.new()
		resultFoot.Text = state.Practice and "Practice doesn't use saved coins or wins." or "+75 coins and a win!"
	end
	refreshGhost()
end
stateRemote.OnClientEvent:Connect(function(value)
	state = value
	if state.Phase ~= lastPhase or state.Round ~= lastRound then
		confirmUntil = 0
		deleteMode = false
		touchPoint = nil
		if state.Phase == "Preview" then
			spectating = false
			candidate = nil
			task.delay(0.25, function()
				local origin = plotInfo(state.Plot)
				if origin and state.Phase == "Preview" then
					camera.CFrame = CFrame.lookAt(origin + Vector3.new(0, 19, 30), origin + Vector3.new(0, 2, 0))
				end
			end)
		end
		if state.Phase == "Build" then
			selected = nil
		end
		if state.Phase == "Lobby" then
			spectating = false
		end
		if not state.Alive and state.Phase ~= "Lobby" and state.Phase ~= "Countdown" then
			spectating = true
		end
		lastPhase = state.Phase
		lastRound = state.Round
	end
	render()
end)
feedback.OnClientEvent:Connect(message)

UIS.InputBegan:Connect(function(input, processed)
	if processed or UIS:GetFocusedTextBox() then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and building() then
		inputMode = "Mouse"
		updateAim(UIS:GetMouseLocation())
		if deleteMode then
			remove()
		else
			place()
		end
	elseif input.UserInputType == Enum.UserInputType.Touch and building() then
		inputMode = "Touch"
		touchPoint = Vector2.new(input.Position.X, input.Position.Y)
		updateAim(touchPoint)
	elseif input.UserInputType == Enum.UserInputType.Keyboard and building() then
		inputMode = "Mouse"
		local key = input.KeyCode
		if key == Enum.KeyCode.E then
			if deleteMode then
				remove()
			else
				place()
			end
		elseif key == Enum.KeyCode.Q then
			deleteMode = not deleteMode
			refreshGhost()
		elseif key == Enum.KeyCode.Return then
			submit()
		else
			local n = key.Value - Enum.KeyCode.One.Value + 1
			if n >= 1 and n <= #types then
				selected = types[n]
				deleteMode = false
				render()
			end
		end
	end
end)
-- Keep Roblox's A/jump, sticks/movement, and right-stick camera bindings intact.
CAS:BindActionAtPriority(
	"CopySceneBuildButtons",
	function(_, inputState, input)
		if not building() or GuiService.MenuIsOpen then
			return Enum.ContextActionResult.Pass
		end
		inputMode = "Gamepad"
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.ButtonR2 then
			place()
		elseif key == Enum.KeyCode.ButtonB then
			remove()
		elseif key == Enum.KeyCode.ButtonX then
			submit()
		elseif key == Enum.KeyCode.ButtonL1 then
			cycleType(-1)
		elseif key == Enum.KeyCode.ButtonR1 then
			cycleType(1)
		end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.ContextActionPriority.High.Value + 1,
	Enum.KeyCode.ButtonR2,
	Enum.KeyCode.ButtonB,
	Enum.KeyCode.ButtonX,
	Enum.KeyCode.ButtonL1,
	Enum.KeyCode.ButtonR1
)
UIS.LastInputTypeChanged:Connect(function(t)
	if t == Enum.UserInputType.Gamepad1 then
		inputMode = "Gamepad"
	elseif t == Enum.UserInputType.Touch then
		inputMode = "Touch"
	elseif t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Keyboard then
		inputMode = "Mouse"
	end
	render()
end)
local phaseDuration = 1
local aimElapsed = 0
RunService.RenderStepped:Connect(function(dt)
	camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	local subject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if spectating and spectator.Visible then
		local targets = {}
		for _, r in ipairs(state.Roster) do
			if r.Alive then
				table.insert(targets, r)
			end
		end
		if #targets > 0 then
			local target = targets[(spectateIndex - 1) % #targets + 1]
			local other = Players:GetPlayerByUserId(target.UserId)
			subject = other and other.Character and other.Character:FindFirstChildOfClass("Humanoid") or subject
			watched.Text = "Watching " .. target.Name
		end
	elseif spectator.Visible then
		watched.Text = "Build locked! Watch friends >"
	end
	if subject then
		camera.CameraSubject = subject
	end
	local left = state.Deadline and math.max(0, state.Deadline - workspace:GetServerTimeNow()) or 0
	timer.Text = left > 0 and tostring(math.ceil(left)) or ""
	timer.TextColor3 = left <= 10 and state.Phase == "Build" and palette.Danger or palette.Gold
	phaseDuration = state.Phase == "Preview" and 8
		or state.Phase == "Build" and (45 + math.min((state.Difficulty or 1) - 1, 5) * 3)
		or 20
	progress.Visible = left > 0
	progress.Size =
		UDim2.fromOffset(math.max(0, (header.AbsoluteSize.X - 18) * math.clamp(left / phaseDuration, 0, 1)), 5)
	submitButton.Text = os.clock() < confirmUntil and "SURE?" or "DONE"
	crosshair.Visible = building() and (inputMode == "Gamepad" or UIS.MouseBehavior == Enum.MouseBehavior.LockCenter)
	local inset = GuiService:GetGuiInset()
	crosshair.Position = UDim2.fromOffset(camera.ViewportSize.X / 2 - inset.X, camera.ViewportSize.Y / 2 - inset.Y)
	if toast.Visible and os.clock() > toastUntil then
		toast.Visible = false
	end
	aimElapsed += dt
	if building() and aimElapsed > 0.035 then
		aimElapsed = 0
		local point
		if inputMode == "Gamepad" or UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
			point = camera.ViewportSize / 2
		elseif inputMode == "Touch" then
			point = touchPoint
		else
			point = UIS:GetMouseLocation()
			if insideOurButton(point) then
				point = nil
			end
		end
		if point then
			updateAim(point)
		end
	end
	local leader = player:FindFirstChild("leaderstats")
	if leader and leader:FindFirstChild("Coins") then
		coins.Text = leader.Coins.Value .. " coins"
		wins.Text = leader.Wins.Value .. " wins"
	end
end)
layout()
render()
action:FireServer("Sync")
