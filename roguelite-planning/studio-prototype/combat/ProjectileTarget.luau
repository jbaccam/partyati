-- Server targeting policy shared by all in-flight projectile families.
local Tags=game:GetService('CollectionService')
local T={}
function T.alive(root)
 local npc=root and root.Parent
 local h=npc and npc:FindFirstChildOfClass('Humanoid')
 return npc and npc:IsDescendantOf(workspace) and Tags:HasTag(npc,'RogueliteZombie') and h and h.Health>0
end
function T.replacement(position,d,hit,remaining,launchOrigin,rayParams)
 local best,range=nil,math.min(d.range,remaining)
 for _,npc in Tags:GetTagged('RogueliteZombie') do
  local root=npc:FindFirstChild('HumanoidRootPart')
  if T.alive(root) and not (hit and hit[npc]) and (not d.practiceTarget or npc:GetAttribute('PracticeTarget')) then
   local distance=(root.Position-position).Magnitude
   if distance>.05 and distance<range and (root.Position-launchOrigin).Magnitude<=d.range
    and not workspace:Raycast(position,root.Position-position,rayParams(d.character,true)) then best=root;range=distance end
  end
 end
 return best
end
return T
