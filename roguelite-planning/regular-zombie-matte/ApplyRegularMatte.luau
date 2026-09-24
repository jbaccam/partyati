assert(game.PlaceId==107877054949326,'Roguelite only')
assert(not game:GetService('RunService'):IsRunning(),'Apply in Edit mode')
local mapping=game:GetService('HttpService'):JSONDecode([==[{"rbxassetid://117306049770322":"rbxassetid://97543481166969","rbxassetid://140609339752453":"rbxassetid://96501124394348","rbxassetid://104527573352654":"rbxassetid://103105933639828","rbxassetid://74400295976437":"rbxassetid://113708131041008","rbxassetid://139143564029844":"rbxassetid://102010131243863","rbxassetid://97498265662380":"rbxassetid://109554557437132"}]==])
local count=0
for _,model in {workspace.Zombie_R15_ProvidedTextures_Studio,game.ServerStorage.RogueliteNPCs.Zombie_NPC} do
 for _,part in model:GetDescendants() do
  if part:IsA('MeshPart') then
   local replacement=mapping[part.TextureID]
   if replacement then
    part:SetAttribute('OriginalTextureBeforeMatte',part.TextureID)
    part.TextureID=replacement
   end
   part.Material=Enum.Material.Plastic
   part.Color=Color3.new(1,1,1)
   part.Reflectance=0
   count+=1
  end
 end
end
return count
