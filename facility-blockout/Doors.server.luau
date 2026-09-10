-- Server-owned prototype doors. Locked branches remain locked until progression is designed.
local root=workspace:WaitForChild("FacilityLayoutReview")
local Players=game:GetService("Players")
local hooked={}
local function hook(model)
 if not model:IsA("Model") or not model:GetAttribute("FacilityDoor") or hooked[model] then return end
 local leaf=model:FindFirstChild("Leaf"); local anchor=model:FindFirstChild("PromptAnchor")
 local prompt=anchor and anchor:FindFirstChildOfClass("ProximityPrompt")
 if not leaf or not prompt then return end
 hooked[model]=true
 local closed=leaf.CFrame; local busy=false
 prompt.Triggered:Connect(function(player)
  local char=player.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
  if busy or not hrp or not hum or hum.Health<=0 or (hrp.Position-anchor.Position).Magnitude>14 or model:GetAttribute("Locked") then return end
  local open=model:GetAttribute("Open")
  if open then
   for _,other in Players:GetPlayers() do
    local body=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
    if body then local at=closed:PointToObjectSpace(body.Position); if math.abs(at.X)<8 and math.abs(at.Y)<8 and math.abs(at.Z)<4 then return end end
   end
  end
  busy=true; model:SetAttribute("Open",not open)
  leaf.CanCollide=open; leaf.CFrame=open and closed or closed*CFrame.new(0,11,0)
  prompt.ActionText=open and "Open" or "Close"
  task.delay(.35,function() busy=false end)
 end)
end
root.DescendantAdded:Connect(function(v) local model=v:FindFirstAncestorOfClass("Model"); if model then task.defer(hook,model) end end)
for _,v in root:GetDescendants() do hook(v) end
