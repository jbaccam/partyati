-- Execute on the CLIENT after selecting an active fighter. This exercises
-- default lock, menu release, and real stock-camera zoom into first person.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
assert(RunService:IsClient(), "Run camera.spec on the client")
local player = Players.LocalPlayer
local character = assert(player.Character)
assert(character:GetAttribute("TungSahurActive"), "Select a fighter first")
local humanoid = character:FindFirstChildOfClass("Humanoid")
local camera = workspace.CurrentCamera
assert(camera.CameraType == Enum.CameraType.Custom, "Restore normal camera first")
local prior = {
	selector = player:GetAttribute("FighterSelectorOpen"),
	minimum = player.CameraMinZoomDistance,
	maximum = player.CameraMaxZoomDistance,
}
local function settle(frames)
	for _ = 1, frames do
		RunService.RenderStepped:Wait()
	end
end
local ok, message = pcall(function()
	player:SetAttribute("FighterSelectorOpen", false)
	settle(20)
	assert(player:GetAttribute("CombatShiftLocked") == true, "Combat shoulder lock absent")
	assert(
		player.CameraMode == Enum.CameraMode.Classic and player.CameraMinZoomDistance <= 0.5,
		"First person is blocked"
	)
	if Input.MouseEnabled then
		assert(Input.MouseBehavior == Enum.MouseBehavior.LockCenter, "Cursor not centered")
	end
	player:SetAttribute("FighterSelectorOpen", true)
	settle(3)
	assert(player:GetAttribute("CombatShiftLocked") == false, "Selector did not release lock")
	if Input.MouseEnabled then
		assert(Input.MouseBehavior == Enum.MouseBehavior.Default, "Selector cursor remains trapped")
	end
	player:SetAttribute("FighterSelectorOpen", false)
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5
	settle(90)
	assert((camera.CFrame.Position - camera.Focus.Position).Magnitude < 1, "Normal first-person zoom did not work")
	assert(humanoid.CameraOffset.Magnitude < 0.08, "Shoulder offset intrudes in first person")
end)
player.CameraMaxZoomDistance = prior.maximum
player.CameraMinZoomDistance = prior.minimum
player:SetAttribute("FighterSelectorOpen", prior.selector)
assert(ok, message)
return { passed = true, lock = true, selectorRelease = true, firstPerson = true }
