local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local package = ReplicatedStorage:WaitForChild("TungPrototype")
local Config = require(package:WaitForChild("Config"))
local Pose = require(package:WaitForChild("Pose"))
local request = package:WaitForChild("RequestMorph")
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
		if not pose:step(dt) then poses[visual] = nil else
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
button.Size = UDim2.fromOffset(240, 42)
button.AnchorPoint = Vector2.new(0.5, 0)
button.Position = UDim2.new(0.5, 0, 0, 12)
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
local characterConnection
local function refresh()
	gui.Enabled = package:GetAttribute("Available") == true
	local active = player.Character and player.Character:GetAttribute("TungSahurActive")
	button.Text = active and "Tung Sahur  ·  T: return to avatar" or "Become Tung Sahur  ·  T"
end
local function watch(character)
	if characterConnection then characterConnection:Disconnect() end
	characterConnection = character:GetAttributeChangedSignal("TungSahurActive"):Connect(refresh)
	refresh()
end
player.CharacterAdded:Connect(watch)
package:GetAttributeChangedSignal("Available"):Connect(refresh)
if player.Character then watch(player.Character) end
refresh()
