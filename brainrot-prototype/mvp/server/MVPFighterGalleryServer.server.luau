-- Training targets only: no player unlocks, rewards, wins, or persistent data.
local RunService=game:GetService("RunService")
local gallery=workspace:FindFirstChild("MVPFighterGallery")
if not gallery or gallery:GetAttribute("Owner")~="MVPPracticeGallery" then return end
if not RunService:IsStudio() then gallery:Destroy();return end
local CollectionService=game:GetService("CollectionService")
local package=game.ReplicatedStorage:WaitForChild("TungPrototype")
local Config=require(package.Config)
local Dummy=require(script.Parent.TrainingDummy)
local function presentation(target)
 local h=target:FindFirstChildOfClass("Humanoid")
  local visual=target:FindFirstChild("GalleryVisual")
  if visual then
   visual:SetAttribute("FighterId",target:GetAttribute("FighterId"))
   visual:SetAttribute("RigProfile",target:GetAttribute("FighterId"))
   CollectionService:AddTag(visual,Config.VisualTag)
  end
  local function label()
   local root=target:FindFirstChild("HumanoidRootPart")
   local info=root and root:FindFirstChild("TargetLabel")
   if info then info.Info.Text=target.Name.."\nKNOCKBACK TARGET / RETURNS AFTER 4s\n"..math.ceil(h.Health).." / "..h.MaxHealth end
  end
  h.HealthChanged:Connect(label)
  label()
end
for _,target in gallery:GetChildren() do
 if target:IsA("Model") and target:FindFirstChildOfClass("Humanoid") then
  Dummy.new(target,{visualTag=Config.VisualTag,onSpawn=presentation})
 end
end
