local RunService=game:GetService('RunService')
local Cards=require(game.ReplicatedStorage:WaitForChild('RogueliteCombat'):WaitForChild('CardPresentation'))
local rigs={}
for _,name in {'RogueliteWeaponShowcase','RogueliteWeaponShowcase_PlaySize'} do
 local folder=workspace:FindFirstChild(name)
 local model=folder and folder:FindFirstChild('18_Deck_of_Cards')
 if model then table.insert(rigs,Cards.bind(model,'18')) end
end
RunService.RenderStepped:Connect(function()
 local now=workspace:GetServerTimeNow()
 for _,rig in rigs do if rig.model.Parent then Cards.step(rig,now) end end
end)
