-- Default combat shoulder lock using Roblox's normal zoom/collision camera.
-- Scroll fully inward for first person. B/Esc/chat release the pointer.
-- No private PlayerModule API, Scriptable camera, or server movement authority.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local package = game.ReplicatedStorage:WaitForChild("TungPrototype")
local focused = true
local saved, humanoidSaved
local cursorOwned = false
local originalMouseBehavior, originalMouseIcon
local reticleGui = Instance.new("ScreenGui")
reticleGui.Name = "BrainrotCombatReticle"
reticleGui.IgnoreGuiInset = true
reticleGui.ResetOnSpawn = false
reticleGui.DisplayOrder = 8
reticleGui.Enabled = false
local dot = Instance.new("Frame")
dot.Name = "AimPoint"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(5, 5)
dot.BackgroundColor3 = Color3.fromRGB(255, 250, 229)
dot.BorderSizePixel = 0
dot.Parent = reticleGui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = dot
local outline = Instance.new("UIStroke")
outline.Thickness = 1.5
outline.Color = Color3.fromRGB(36, 39, 42)
outline.Parent = dot
reticleGui.Parent = player:WaitForChild("PlayerGui")

local function driving(character)
	return character and (character:GetAttribute("AbilityMotionUntil") or 0) > workspace:GetServerTimeNow()
end
local function releaseHumanoid()
	if humanoidSaved then
		local h = humanoidSaved.humanoid
		if h.Parent then
			h.CameraOffset = humanoidSaved.offset
			if not driving(h.Parent) then
				h.AutoRotate = humanoidSaved.autoRotate
			end
		end
		humanoidSaved = nil
	end
end
local function releaseCursor()
	if cursorOwned then
		Input.MouseBehavior = originalMouseBehavior
		Input.MouseIconEnabled = originalMouseIcon
		cursorOwned = false
	end
end
local function activeCharacter()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if
		package:GetAttribute("CombatAvailable") ~= true
		or not c
		or c:GetAttribute("TungSahurActive") ~= true
		or not h
		or h.Health <= 0
		or not root
	then
		return nil
	end
	return c, h, root
end
local function freePointer()
	return not focused
		or player:GetAttribute("FighterSelectorOpen") == true
		or GuiService.MenuIsOpen
		or Input:GetFocusedTextBox() ~= nil
end

Input.WindowFocused:Connect(function()
	focused = true
end)
Input.WindowFocusReleased:Connect(function()
	focused = false
	releaseCursor()
end)

-- Prepare CameraOffset before the default camera, and feed locked mouse delta
-- to its normal camera controls. Do not steal a cutscene's Scriptable camera.
RunService:BindToRenderStep("BrainrotShoulderPrepare", Enum.RenderPriority.Camera.Value - 1, function(dt)
	local c, h = activeCharacter()
	local camera = workspace.CurrentCamera
	if not c or not camera or camera.CameraType ~= Enum.CameraType.Custom then
		player:SetAttribute("CombatShiftLocked", false)
		reticleGui.Enabled = false
		releaseCursor()
		releaseHumanoid()
		if saved then
			player.CameraMode = saved.mode
			player.CameraMinZoomDistance = saved.minimum
			player.CameraMaxZoomDistance = saved.maximum
			saved = nil
		end
		return
	end
	if not saved then
		saved =
			{ mode = player.CameraMode, minimum = player.CameraMinZoomDistance, maximum = player.CameraMaxZoomDistance }
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = math.max(20, saved.maximum)
	end
	if freePointer() then
		player:SetAttribute("CombatShiftLocked", false)
		reticleGui.Enabled = false
		releaseCursor()
		releaseHumanoid()
		return
	end
	if humanoidSaved and humanoidSaved.humanoid ~= h then
		releaseHumanoid()
	end
	if not humanoidSaved then
		local autoRotate = h.AutoRotate
		if driving(c) then
			autoRotate = true
		end
		humanoidSaved = { humanoid = h, offset = h.CameraOffset, autoRotate = autoRotate }
	end
	player:SetAttribute("CombatShiftLocked", true)
	reticleGui.Enabled = true
	local distance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	local shoulder = math.clamp((distance - 1) / 2, 0, 1)
	local target = humanoidSaved.offset + Vector3.new(1.75 * shoulder, 0.25 * shoulder, 0)
	h.CameraOffset = h.CameraOffset:Lerp(target, 1 - math.exp(-18 * math.min(dt, 0.1)))
	if Input.MouseEnabled then
		if not cursorOwned then
			originalMouseBehavior, originalMouseIcon = Input.MouseBehavior, Input.MouseIconEnabled
			cursorOwned = true
		end
		Input.MouseBehavior = Enum.MouseBehavior.LockCenter
		Input.MouseIconEnabled = false
	end
end)

-- The stock camera may set MouseBehavior during its own update. Reapply only
-- while combat has the pointer, after the existing additive shake (+1).
RunService:BindToRenderStep("BrainrotShoulderFacing", Enum.RenderPriority.Camera.Value + 2, function()
	local c, h, root = activeCharacter()
	local camera = workspace.CurrentCamera
	if not c or not camera or camera.CameraType ~= Enum.CameraType.Custom then
		return
	end
	if freePointer() then
		if Input.MouseEnabled then
			Input.MouseBehavior = Enum.MouseBehavior.Default
		end
		return
	end
	if cursorOwned then
		Input.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
	if
		driving(c)
		or root.Anchored
		or h.Sit
		or h.PlatformStand
		or (c:GetAttribute("StunnedUntil") or 0) > workspace:GetServerTimeNow()
		or (c:GetAttribute("CombatHitAt") or -math.huge) + 0.35 > workspace:GetServerTimeNow()
	then
		return
	end
	local look = camera.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude > 0.01 then
		h.AutoRotate = false
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
	end
end)

script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep("BrainrotShoulderPrepare")
	RunService:UnbindFromRenderStep("BrainrotShoulderFacing")
	releaseCursor()
	releaseHumanoid()
	if saved then
		player.CameraMode = saved.mode
		player.CameraMinZoomDistance = saved.minimum
		player.CameraMaxZoomDistance = saved.maximum
	end
	player:SetAttribute("CombatShiftLocked", false)
	reticleGui:Destroy()
end)
