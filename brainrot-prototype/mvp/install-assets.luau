-- Run in Studio Edit Command Bar. Rebuilds only the four owned MVP templates.
local package=game.ReplicatedStorage:WaitForChild("TungPrototype")
local normal=workspace:WaitForChild("BrainrotPack"):WaitForChild("Normal")
local definitions={
 {"Tralalero","Tralalero Tralala","tralalero",4.6,"Y"},
 {"Chimpanzini","Chimpanzini Bananini","chimpanzini",4.8,"Y"},
 {"Ballerina","Ballerina Cappuccina","ballerina",5.5,"Y"},
 {"Bombardiro","Bombardiro Crocodilo","bombardiro",7.5,"Max"},
}
local pending={}
for _,d in definitions do
 local source=normal:FindFirstChild(d[2]); assert(source,"Missing source: "..d[2])
 local original=source:FindFirstChildWhichIsA("MeshPart",true); assert(original,"Missing mesh: "..d[2])
 local model=Instance.new("Model"); model.Name=d[1]
 local mesh=original:Clone();mesh.Name="Mesh";mesh.PivotOffset=CFrame.identity;mesh.CFrame=CFrame.identity;mesh.Parent=model
 for _,v in mesh:GetDescendants() do
  if not (v:IsA("Bone") or v:IsA("SurfaceAppearance") or v:IsA("Attachment") or v:IsA("WrapTarget")) then v:Destroy()
  elseif v:IsA("Bone") then v.Transform=CFrame.identity end
 end
 for _,v in model:GetDescendants() do for _,tag in v:GetTags() do v:RemoveTag(tag) end end
 mesh.Anchored=true;mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=false;mesh.Massless=true
 model.PrimaryPart=mesh;model:PivotTo(CFrame.identity)
 local dimension=d[5]=="Y" and mesh.Size.Y or math.max(mesh.Size.X,mesh.Size.Y,mesh.Size.Z)
 model:ScaleTo(d[4]/dimension)
 model:SetAttribute("FighterId",d[3]);model:SetAttribute("RigProfile",d[3]);model:SetAttribute("MVPReviewed",true)
 assert(mesh:FindFirstChildWhichIsA("Bone",true),"Missing skeleton")
 table.insert(pending,model)
end
for _,model in pending do
 local old=package.Assets:FindFirstChild(model.Name)
 if old then assert(old:GetAttribute("MVPReviewed"),"Refusing to replace unrelated asset "..old.Name);old:Destroy() end
 model.Parent=package.Assets
end
return "Four sanitized, scaled skeletal templates installed; pack originals untouched."
