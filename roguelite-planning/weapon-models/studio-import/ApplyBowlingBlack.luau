-- Edit-time migration for existing displays and the combat template.
local roots={workspace:FindFirstChild('RogueliteWeaponShowcase'),workspace:FindFirstChild('RogueliteWeaponShowcase_PlaySize')}
local combat=game.ReplicatedStorage:FindFirstChild('RogueliteCombat')
if combat then table.insert(roots,combat:FindFirstChild('WeaponTemplates')) end
local changed={}
for _,root in pairs(roots) do
 for _,part in root:GetDescendants() do
  if part:IsA('MeshPart') and part.Name=='W22_Bowling_Ball' then
   part.TextureID=''
   part.Color=Color3.fromRGB(17,17,17)
   part.Material=Enum.Material.SmoothPlastic
   table.insert(changed,part:GetFullName())
  end
 end
end
game:GetService('ChangeHistoryService'):SetWaypoint('Black bowling ball with naturally shaded sockets')
return changed
