assert(not game:GetService('RunService'):IsRunning(),'Stop Play before installing cards')
local combat=game.ReplicatedStorage:WaitForChild('RogueliteCombat')
combat.CardPresentation.Sandboxed=combat.WeaponMotion.Sandboxed
combat.CardPresentation.Capabilities=combat.WeaponMotion.Capabilities
local Cards=require(combat:WaitForChild('CardPresentation'))
local count=0
for _,name in {'RogueliteWeaponShowcase','RogueliteWeaponShowcase_PlaySize'} do
 local folder=workspace:FindFirstChild(name)
 local model=folder and folder:FindFirstChild('18_Deck_of_Cards')
 if model then Cards.prepare(model);count+=1 end
end
Cards.prepare(assert(combat.WeaponTemplates:FindFirstChild('18')))
return ('Prepared %d showcases and the equipped deck template'):format(count)
