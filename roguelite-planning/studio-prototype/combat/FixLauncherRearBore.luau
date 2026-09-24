-- Edit-only repair; leaves imported meshes and their dimensions unchanged.
assert(not game:GetService('RunService'):IsRunning(),'Apply in Edit mode')
local combat=game.ReplicatedStorage.RogueliteCombat
local source=combat.WeaponPresentation
-- Fresh require prevents an older Studio require cache from retaining v1.
local fresh=source:Clone();fresh.Parent=combat
local P=require(fresh);fresh:Destroy()
local roots={combat.WeaponTemplates['11']}
for _,name in {'RogueliteWeaponShowcase','RogueliteWeaponShowcase_PlaySize'} do
 local showcase=workspace:FindFirstChild(name)
 if showcase then for _,model in showcase:GetChildren() do
  if model.Name:match('^11_') then table.insert(roots,model) end
 end end
end
local backup=game.ServerStorage:FindFirstChild('BeforeLauncherRearBore_20260922')
if not backup then
 backup=Instance.new('Folder');backup.Name='BeforeLauncherRearBore_20260922';backup.Parent=game.ServerStorage
 for index,model in roots do local copy=model:Clone();copy.Name=tostring(index)..'_'..model.Name;copy.Parent=backup end
end
for _,model in roots do
 P.stabilizeLauncher(model)
 local mesh=model:FindFirstChild('W11_Rocket_Launcher',true)
 mesh.RenderFidelity=Enum.RenderFidelity.Precise
 assert(not model:FindFirstChild('StableBoreBackstop'))
 assert(model:GetAttribute('StableLauncherBoreVersion')==2)
end
return {updated=#roots,version=2,backup=backup:GetFullName()}
