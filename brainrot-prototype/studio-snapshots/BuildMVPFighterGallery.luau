-- Studio-only five-fighter inspection/punching range; source models stay untouched.
return function()
 assert(not game:GetService("RunService"):IsRunning(),"Build the gallery in Edit mode")
 assert(not workspace:FindFirstChild("MVPFighterGallery"),"Gallery already exists; do not overwrite it")
 local collection=game:GetService("CollectionService")
 local sources=workspace.BrainrotPack.Normal
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
 local origin=(spawn and spawn.Position or Vector3.zero)+Vector3.new(0,0,-54)
 local gallery=Instance.new("Folder");gallery.Name="MVPFighterGallery";gallery:SetAttribute("Owner","MVPPracticeGallery");gallery.Parent=workspace
 local names={"Tung Sahur","Tralalero Tralala","Chimpanzini Bananini","Ballerina Cappuccina","Bombardiro Crocodilo"}
 local entries={}
 for i,name in names do
  local original=sources:FindFirstChild(name);assert(original,"Missing source "..name)
  local source=original:FindFirstChildWhichIsA("MeshPart",true);assert(source,"Missing mesh "..name)
  local target=Instance.new("Model");target.Name=name;target:SetAttribute("TrainingOnly",true);target:SetAttribute("FighterId",({"tung_sahur","tralalero","chimpanzini","ballerina","bombardiro"})[i])
  local position=origin+Vector3.new((i-3)*14,0,0)
  local pad=Instance.new("Part");pad.Name=name.." Pad";pad.Anchored=true;pad.Size=Vector3.new(12,1,12);pad.Material=Enum.Material.Slate;pad.Color=Color3.fromRGB(46,67,78);pad.Position=position;pad.Parent=gallery
  local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1);root.Anchored=true;root.Transparency=1;root.CanCollide=false;root.CanTouch=false;root.CanQuery=false
  root.CFrame=CFrame.new(position+Vector3.new(0,3.5,0))*CFrame.Angles(0,math.pi,0);root.Parent=target;target.PrimaryPart=root
  local humanoid=Instance.new("Humanoid");humanoid.RequiresNeck=false;humanoid.MaxHealth=1000;humanoid.Health=1000;humanoid.WalkSpeed=0;humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;humanoid.BreakJointsOnDeath=false;humanoid.Parent=target
  local visual=Instance.new("Model");visual.Name="GalleryVisual";visual.Parent=target
  local mesh=source:Clone();mesh.Name="Mesh"
  for _,v in mesh:GetDescendants() do
   if not (v:IsA("Bone") or v:IsA("Attachment") or v:IsA("SurfaceAppearance")) then v:Destroy() end
  end
  for _,v in {mesh,table.unpack(mesh:GetDescendants())} do
   for _,tag in collection:GetTags(v) do collection:RemoveTag(v,tag) end
   if v:IsA("Bone") then v.Transform=CFrame.identity end
  end
  mesh.Anchored=true;mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=false
  -- Keep the original proportions; a training presentation, not final fighter hitboxes.
  local size=mesh.Size
  local factor=math.min(6/size.Y,10/math.max(size.X,size.Z),1.5)
  mesh.Size=size*factor
  -- Scaling MeshPart.Size scales its skinned render; ScaleTo also handles bone offsets.
  mesh.Size=size;mesh.Parent=visual;visual:ScaleTo(factor)
  mesh.CFrame=CFrame.new(position+Vector3.new(0,.5+mesh.Size.Y/2,0))*CFrame.Angles(0,math.pi,0)
  local bones=0 for _,v in mesh:GetDescendants() do if v:IsA("Bone") then bones+=1 end end
  target:SetAttribute("RigBoneCount",bones);target:SetAttribute("SourceModel",original:GetFullName());target:SetAttribute("CombatWeight",1)
  local board=Instance.new("BillboardGui");board.Name="TargetLabel";board.Size=UDim2.fromScale(11,3.5);board.StudsOffsetWorldSpace=Vector3.new(0,mesh.Size.Y-1,0);board.MaxDistance=110;board.AlwaysOnTop=false;board.Adornee=root;board.Parent=root
  local label=Instance.new("TextLabel");label.Name="Info";label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(255,247,225);label.TextColor3=Color3.fromRGB(56,48,41);label.Font=Enum.Font.FredokaOne;label.TextSize=17;label.TextWrapped=true;label.TextScaled=true
  label.Text=name.."\nTARGET / "..bones.." BONES\n1000 / 1000";label.Parent=board
  local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=label
  local stroke=Instance.new("UIStroke");stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;stroke.Color=Color3.fromRGB(56,48,41);stroke.Thickness=2;stroke.Parent=label
  target.Parent=gallery;collection:AddTag(target,"BrainrotCombatTarget")
  table.insert(entries,{name=name,bones=bones,mesh=source.MeshId,texture=source.TextureID,source=original:GetFullName()})
 end
 gallery:SetAttribute("StudioOnly",true)
 return entries
end
