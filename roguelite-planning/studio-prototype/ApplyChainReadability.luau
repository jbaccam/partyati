-- Edit-time visual correction; property assignment requires Studio/plugin context.
assert(game.PlaceId==107877054949326,'Roguelite only')
assert(not game:GetService('RunService'):IsRunning(),'Apply in Edit mode')
local templates=game.ReplicatedStorage.RogueliteCombat.WeaponTemplates
local definitions={
 ['02']={name='W02_Nunchucks',texture='rbxassetid://139611611040047'},
 ['04']={name='W04_Kusarigama',texture='rbxassetid://84554283265256'},
 ['25']={name='W25_Wrecking_Ball',texture='rbxassetid://97648290326179'},
}
local targets={}
for id,d in definitions do
 local p=templates[id]:FindFirstChild(d.name,true)
 assert(p and p:IsA('MeshPart') and p.TextureID==d.texture,'Unexpected chain skin '..id)
 local existing=p:FindFirstChildOfClass('SurfaceAppearance')
 assert(not existing or existing.Name=='ChainReadability','Preserve unrelated material')
 targets[id]=p
end
local backup=game.ServerStorage:FindFirstChild('BeforeChainReadability')
if not backup then
 backup=Instance.new('Folder');backup.Name='BeforeChainReadability';backup.Parent=game.ServerStorage
 for id in definitions do templates[id]:Clone().Parent=backup end
end
for id,p in targets do
 local a=p:FindFirstChild('ChainReadability') or Instance.new('SurfaceAppearance')
 a.Name='ChainReadability'
 a.ColorMap=definitions[id].texture
 -- Low texture-masked fill retains the painted detail on the shadow-facing
 -- idle side. Constant through the attack: no brightness switches or new lights.
 a.EmissiveMaskContent=Content.fromUri(definitions[id].texture)
 a.EmissiveTint=Color3.new(1,1,1)
 a.EmissiveStrength=1.5
 a.Parent=p
 p:SetAttribute('ChainReadabilityVersion',1)
end
return 'Applied constant material fill to 02, 04 and 25 combat templates'
