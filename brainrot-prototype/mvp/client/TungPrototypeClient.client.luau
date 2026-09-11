local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local package = ReplicatedStorage:WaitForChild("TungPrototype")
local Config = require(package:WaitForChild("Config"))
local Pose = require(package:WaitForChild("Pose"))
local Roster = require(package:WaitForChild("FighterDefinitions"))
local request = package:WaitForChild("RequestMorph")
local requestFighter = package:WaitForChild("RequestFighter")
local player = Players.LocalPlayer
local poses = {}
local pending = {}
local function add(visual)
	if poses[visual] or pending[visual] then return end
	pending[visual] = true
	task.spawn(function()
		for _ = 1, 50 do
			if not visual.Parent or not CollectionService:HasTag(visual, Config.VisualTag) then break end
			local pose = Pose.new(visual)
			if pose then poses[visual] = pose; break end
			task.wait(0.1)
		end
		pending[visual] = nil
	end)
end
CollectionService:GetInstanceAddedSignal(Config.VisualTag):Connect(add)
CollectionService:GetInstanceRemovedSignal(Config.VisualTag):Connect(function(visual)
	local pose = poses[visual]
	if pose then pose:reset(); poses[visual] = nil end
end)
for _, visual in CollectionService:GetTagged(Config.VisualTag) do add(visual) end
local debugElapsed = 0
RunService.PreSimulation:Connect(function(dt)
	debugElapsed += dt
	local report = debugElapsed >= 0.1
	if report then debugElapsed = 0 end
	for visual, pose in poses do
		local sample
		-- FloorMaterial is local simulation state, not reliable for remote/NPC rigs.
		-- Sample their actual supporting surface instead of showing permanent freefall.
		if visual.Parent ~= player.Character and pose.root.Parent then
			if report or pose.remoteGrounded == nil then
				local h=pose.humanoid
				local distance=h.HipHeight+pose.root.Size.Y*.5
				if h.RigType==Enum.HumanoidRigType.R6 then
					local leg=visual.Parent:FindFirstChild("Left Leg");distance+=leg and leg.Size.Y or 2
				end
				local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances={visual.Parent};params.RespectCanCollide=true
				local hit=workspace:Raycast(pose.root.Position,-Vector3.yAxis*(distance+.6),params)
				pose.remoteGrounded=hit~=nil and hit.Normal.Y>.45 and pose.root.AssemblyLinearVelocity.Y<=4
			end
			sample={grounded=pose.remoteGrounded}
		end
		if not pose:step(dt,sample) then poses[visual] = nil else
			-- Match Roblox's first-person body fade for the local visual only.
			if visual.Parent == player.Character then
				local head = player.Character:FindFirstChild("Head")
				local camera = workspace.CurrentCamera
				local nearHead = head and camera and (camera.CFrame.Position-head.Position).Magnitude < 1.25
				pose.mesh.LocalTransparencyModifier = nearHead and 1 or 0
			end
			if report and RunService:IsStudio() then
				visual:SetAttribute("MotionState", pose.state)
				visual:SetAttribute("MotionPhase", pose.phase)
				visual:SetAttribute("MotionSpeed", pose.speed)
			end
		end
	end
end)
local gui = Instance.new("ScreenGui")
gui.Name = "TungPrototypeControls"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.Name = "MorphToggle"
button.Size = UDim2.fromOffset(210, 38)
button.AnchorPoint = Vector2.new(0.5, 0)
button.Position = UDim2.new(0.5, 0, 0, 60)
button.BackgroundColor3 = Color3.fromRGB(255, 247, 225)
button.BackgroundTransparency = 0
button.TextColor3 = Color3.fromRGB(56, 48, 41)
button.TextSize = 15
button.Font = Enum.Font.FredokaOne
button.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(56, 48, 41)
stroke.Transparency = 0
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = button
local lastToggle = -math.huge
local function toggle()
	if UserInputService:GetFocusedTextBox() or player:GetAttribute("FighterSelectorOpen") then return end
	if package:GetAttribute("Available") ~= true then return end
	if os.clock()-lastToggle < Config.RequestCooldown then return end
	lastToggle = os.clock()
	local character = player.Character
	if character then request:FireServer(character:GetAttribute("TungSahurActive") ~= true) end
end
button.Activated:Connect(toggle)
ContextActionService:BindAction("TungPrototypeToggle", function(_, state)
	if state == Enum.UserInputState.Begin then toggle() end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.T)
-- Local selector only requests an id. Availability, combat locks and morphing stay on the server.
local INK = Color3.fromRGB(56,48,41)
local CREAM = Color3.fromRGB(255,247,225)
local TEAL = Color3.fromRGB(71,168,148)
local function rounded(object, radius)
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,radius); c.Parent=object
	local s=Instance.new("UIStroke"); s.Color=INK; s.Thickness=2; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=object
end
local function label(parent,name,value,x,y,w,h,size)
	local l=Instance.new("TextLabel"); l.Name=name; l.BackgroundTransparency=1
	l.Position=UDim2.fromOffset(x,y); l.Size=UDim2.fromOffset(w,h); l.Text=value
	l.Font=Enum.Font.FredokaOne; l.TextSize=size; l.TextColor3=INK
	l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true; l.Parent=parent; return l
end
local openButton=Instance.new("TextButton"); openButton.Name="FightersButton"
openButton.AnchorPoint=Vector2.new(.5,0); openButton.Position=UDim2.new(.5,0,0,10)
openButton.Size=UDim2.fromOffset(210,42); openButton.Text="FIGHTERS  ·  B"
openButton.Font=Enum.Font.FredokaOne; openButton.TextSize=22; openButton.TextColor3=INK
openButton.BackgroundColor3=TEAL; openButton.Parent=gui; rounded(openButton,12)
local selector=Instance.new("Frame"); selector.Name="FighterSelector"; selector.Visible=false
selector.AnchorPoint=Vector2.new(.5,.5); selector.Position=UDim2.fromScale(.5,.5)
selector.Size=UDim2.fromOffset(720,524); selector.BackgroundColor3=CREAM; selector.Parent=gui; rounded(selector,18)
local selectorScale=Instance.new("UIScale"); selectorScale.Parent=selector
label(selector,"Title","PICK YOUR FIGHTER",22,12,570,36,29)
label(selector,"Subtitle","Five styles. All unlocked. Switch safely between fights.",22,50,640,28,15)
local close=Instance.new("TextButton"); close.Name="Close"; close.Text="X"
close.Modal=true -- Release first-person mouse lock while the selector is visible.
close.Position=UDim2.fromOffset(658,14); close.Size=UDim2.fromOffset(42,36)
close.Font=Enum.Font.FredokaOne; close.TextSize=24; close.TextColor3=CREAM
close.BackgroundColor3=INK; close.Parent=selector; rounded(close,10)
local list=Instance.new("ScrollingFrame"); list.Name="FighterCards"
list.Position=UDim2.fromOffset(18,88); list.Size=UDim2.fromOffset(684,376)
list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=6
list.ScrollBarImageColor3=INK; list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.new(); list.ScrollingDirection=Enum.ScrollingDirection.Y; list.Parent=selector
local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,10); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=list
local padding=Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,3); padding.PaddingLeft=UDim.new(0,3); padding.PaddingBottom=UDim.new(0,3); padding.Parent=list
local feedback=label(selector,"SelectionFeedback","Select a fighter to join practice.",22,478,676,32,15)
local cards={}
local selectedFocus
local lastSelect=-math.huge
for order,id in {"tung_sahur","tralalero","chimpanzini","ballerina","bombardiro"} do
	local f=Roster.ById[id]
	if not f or not f.MVP then continue end
	local card=Instance.new("TextButton"); card.Name=id; card.Size=UDim2.new(1,-16,0,136)
	card.BackgroundColor3=Color3.fromRGB(239,231,206); card.Text=""; card.LayoutOrder=order; card.Parent=list; rounded(card,12)
	label(card,"FighterName",f.DisplayName,14,7,490,29,24)
	local selected=label(card,"Selected","SELECT",532,10,116,23,15); selected.TextXAlignment=Enum.TextXAlignment.Right
	label(card,"Stats",string.format("%s  /  %d HP  /  %g speed  /  %g sprint",f.Role,f.Stats.MaxHealth,f.Stats.WalkSpeed,f.Stats.SprintSpeed or f.Stats.WalkSpeed),14,38,630,23,14)
	local moves=string.format("M1  %s     Q  %s     E  %s\nR  %s     F  %s",f.Basic.Name,f.Abilities.Q.Name,f.Abilities.E.Name,f.Abilities.R.Name,f.Ultimate.Name)
	local moveLabel=label(card,"Moves",moves,14,64,630,42,13); moveLabel.Font=Enum.Font.GothamBold
	local passive=label(card,"Passive",f.Passive.Name.."  ·  "..(f.Passive.Description or ""),14,109,630,20,11); passive.Font=Enum.Font.Gotham; passive.TextTruncate=Enum.TextTruncate.AtEnd
	cards[id]={button=card,selected=selected}
	card.Activated:Connect(function()
		if os.clock()-lastSelect<.4 then return end
		lastSelect=os.clock(); feedback.Text="Requesting "..f.DisplayName.."…"
		requestFighter:FireServer(id)
	end)
end
local function showSelector(show)
	selector.Visible=show; player:SetAttribute("FighterSelectorOpen",show)
	button.Visible=not show; openButton.Visible=not show
	if show then
		selectedFocus=GuiService.SelectedObject
		local entry=cards[player:GetAttribute("SelectedFighterId") or "tung_sahur"]
		if UserInputService.GamepadEnabled then GuiService.SelectedObject=entry and entry.button or close end
	elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(selector) then
		GuiService.SelectedObject=selectedFocus and selectedFocus.Parent and selectedFocus or nil
	end
end
openButton.Activated:Connect(function() showSelector(true) end)
close.Activated:Connect(function() showSelector(false) end)
ContextActionService:BindActionAtPriority("BrainrotFighterMenu",function(_,state,input)
	if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if input.KeyCode==Enum.KeyCode.ButtonB and not selector.Visible then return Enum.ContextActionResult.Pass end
	if state==Enum.UserInputState.Begin then showSelector(not selector.Visible) end
	return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value+10,Enum.KeyCode.B,Enum.KeyCode.ButtonSelect,Enum.KeyCode.ButtonB)
RunService.PreRender:Connect(function()
	local camera=workspace.CurrentCamera
	if camera then
		local s=math.min(1,(camera.ViewportSize.Y-24)/524)
		local width=math.min(720,(camera.ViewportSize.X-24)/s)
		selectorScale.Scale=s;selector.Size=UDim2.fromOffset(width,524)
		list.Size=UDim2.fromOffset(width-36,376)
		close.Position=UDim2.fromOffset(width-62,14)
		selector.Title.Size=UDim2.fromOffset(width-92,36)
		selector.Title.TextSize=width<530 and 22 or 29
		selector.Subtitle.Size=UDim2.fromOffset(width-44,30)
		selector.Subtitle.TextSize=width<530 and 12 or 15
		feedback.Size=UDim2.fromOffset(width-44,32)
		for _,entry in cards do
			local c=entry.button;local compact=width<530;local content=width-82
			c.Size=UDim2.new(1,-16,0,compact and 188 or 136)
			c.FighterName.Size=UDim2.fromOffset(compact and content or content-140,29)
			c.FighterName.TextSize=compact and 20 or 24
			entry.selected.Position=UDim2.fromOffset(content-102,compact and 39 or 10)
			c.Stats.Position=UDim2.fromOffset(14,compact and 65 or 38)
			c.Stats.Size=UDim2.fromOffset(content,compact and 34 or 23)
			c.Stats.TextSize=compact and 12 or 14
			c.Moves.Position=UDim2.fromOffset(14,compact and 103 or 64)
			c.Moves.Size=UDim2.fromOffset(content,compact and 58 or 42)
			c.Moves.TextSize=compact and 12 or 13
			c.Passive.Position=UDim2.fromOffset(14,compact and 165 or 109)
			c.Passive.Size=UDim2.fromOffset(content,20)
		end
	end
end)
player:GetAttributeChangedSignal("FighterSelectionAt"):Connect(function()
	feedback.Text=player:GetAttribute("FighterSelectionStatus") or ""
end)
local characterConnections={}
local function refresh()
	gui.Enabled = package:GetAttribute("Available") == true
	local active = player.Character and player.Character:GetAttribute("TungSahurActive")
	local chosen=player:GetAttribute("SelectedFighterId") or "tung_sahur"
	button.Text = active and "T  ·  Return to avatar" or "T  ·  Become fighter"
	for id,entry in cards do
		entry.selected.Text=id==chosen and "SELECTED" or "SELECT"
		entry.button.BackgroundColor3=id==chosen and Color3.fromRGB(169,218,190) or Color3.fromRGB(239,231,206)
	end
	openButton.Text=UserInputService.GamepadEnabled and "FIGHTERS · SELECT" or "FIGHTERS  ·  B"
end
local function watch(character)
	for _,connection in characterConnections do connection:Disconnect() end
	table.clear(characterConnections)
	table.insert(characterConnections,character:GetAttributeChangedSignal("TungSahurActive"):Connect(refresh))
	table.insert(characterConnections,character:GetAttributeChangedSignal("FighterId"):Connect(refresh))
	refresh()
end
player:GetAttributeChangedSignal("SelectedFighterId"):Connect(refresh)
UserInputService.LastInputTypeChanged:Connect(refresh)
player.CharacterAdded:Connect(watch)
package:GetAttributeChangedSignal("Available"):Connect(refresh)
if player.Character then watch(player.Character) end
refresh()
