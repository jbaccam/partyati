-- Server-authoritative swing doors; existing hide, search and escape logic stays server-owned.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("ProductionDressed") do task.wait() end
local Run=game:GetService("RunService");if not Run:IsRunning() then return end
local Players=game:GetService("Players");local Tween=game:GetService("TweenService")
for _,anchor in root:GetDescendants() do
 if anchor:IsA("BasePart") and anchor:GetAttribute("DoorTarget") then
  local model=anchor.Parent:FindFirstChild(anchor:GetAttribute("DoorTarget"));local prompt=anchor:FindFirstChildOfClass("ProximityPrompt")
  if model and prompt then
   local leaf=model.Leaf;local closed=leaf.CFrame;local hinge=model:GetAttribute("ClosedHinge");local offset=hinge:ToObjectSpace(closed);local busy=false
   prompt.ActionText="Open / close";prompt.ObjectText="Kitchen door";prompt.HoldDuration=.25
   prompt.Triggered:Connect(function(player)
    local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local p=c and c:FindFirstChild("HumanoidRootPart")
    if busy or not h or h.Health<=0 or not p or (p.Position-anchor.Position).Magnitude>9 then return end
    local open=model:GetAttribute("Open")==true
    if open then for _,other in Players:GetPlayers() do local b=other.Character and other.Character:FindFirstChild("HumanoidRootPart");if b then local v=closed:PointToObjectSpace(b.Position);if math.abs(v.X)<5.8 and math.abs(v.Z)<3 and math.abs(v.Y)<6 then return end end end end
    busy=true;model:SetAttribute("Open",not open)
    local target=open and closed or hinge*CFrame.Angles(0,-math.pi/2,0)*offset
    local t=Tween:Create(leaf,TweenInfo.new(.55,Enum.EasingStyle.Sine),{CFrame=target});t:Play();t.Completed:Wait();busy=false
   end)
  end
 end
end
