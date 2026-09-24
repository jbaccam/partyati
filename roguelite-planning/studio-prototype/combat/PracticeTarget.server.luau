-- The existing display zombie becomes a harmless, resettable Studio-only target.
if not game:GetService('RunService'):IsStudio() then return end
local target=workspace:WaitForChild('Zombie_R15_ProvidedTextures_Studio',10)
if not target or not target:IsA('Model') then return end
local h=target:FindFirstChildOfClass('Humanoid');local root=target:FindFirstChild('HumanoidRootPart')
if not h or not root then return end
target:SetAttribute('PracticeTarget',true);target:SetAttribute('PracticeHits',0);target:SetAttribute('PracticeDamage',0)
h.MaxHealth=1000;h.Health=1000;h.BreakJointsOnDeath=false;h.WalkSpeed=0
for _,part in target:GetDescendants() do if part:IsA('BasePart') then part.Anchored=true;part.CanQuery=true end end
game:GetService('CollectionService'):AddTag(target,'RogueliteZombie')
