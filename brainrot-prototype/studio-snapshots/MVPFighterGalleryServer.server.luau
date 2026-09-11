-- Training targets only: no player unlocks, rewards, wins, or persistent data.
local RunService=game:GetService("RunService")
local gallery=workspace:FindFirstChild("MVPFighterGallery")
if not gallery or gallery:GetAttribute("Owner")~="MVPPracticeGallery" then return end
if not RunService:IsStudio() then gallery:Destroy();return end
local records={}
for _,target in gallery:GetChildren() do
 local h=target:FindFirstChildOfClass("Humanoid")
 if target:IsA("Model") and h then
  local record={target=target,humanoid=h,lastHit=0,previous=h.Health};table.insert(records,record)
  local function label()
   local root=target:FindFirstChild("HumanoidRootPart")
   local info=root and root:FindFirstChild("TargetLabel")
   if info then info.Info.Text=target.Name.."\nTARGET / "..target:GetAttribute("RigBoneCount").." BONES\n"..math.ceil(h.Health).." / "..h.MaxHealth end
  end
  h.HealthChanged:Connect(function(health)
   if health<record.previous then record.lastHit=os.clock() end
   record.previous=health;label()
   if health<100 then task.defer(function() if h.Parent then h.Health=h.MaxHealth end end) end
  end)
  label()
 end
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.25 then return end;elapsed=0
 for _,record in records do
  local h=record.humanoid
  if h.Parent and h.Health>0 and h.Health<h.MaxHealth and os.clock()-record.lastHit>=4 then h.Health=h.MaxHealth end
 end
end)
