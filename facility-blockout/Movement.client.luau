local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local player=game:GetService("Players").LocalPlayer
local remote=game:GetService("ReplicatedStorage"):WaitForChild("FacilityMovementReview"):WaitForChild("Sprint")
local active=false
local function set(value) active=value; remote:FireServer(value) end
CAS:BindAction("FacilityReviewSprint",function(_,state,input)
 if input.UserInputType==Enum.UserInputType.Touch then
  if state==Enum.UserInputState.Begin then set(not active) end
 elseif state==Enum.UserInputState.Begin then set(true)
 elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then set(false) end
 return Enum.ContextActionResult.Sink
end,true,Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3)
CAS:SetTitle("FacilityReviewSprint","Sprint")
CAS:SetPosition("FacilityReviewSprint",UDim2.fromScale(.75,.7))
UIS.WindowFocusReleased:Connect(function() set(false) end)
player.CharacterAdded:Connect(function() active=false end)
