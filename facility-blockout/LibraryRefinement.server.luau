local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
local quality=art:WaitForChild("QualityProps")
while not quality:GetAttribute("Ready") do task.wait() end
if art:FindFirstChild("LibraryRefinement") then return end
local out=Instance.new("Model");out.Name="LibraryRefinement";out.Parent=art
local backup=Instance.new("Folder");backup.Name="Library_PreSurfaceRefinement";backup.Parent=game.ServerStorage
for _,m in quality:GetChildren() do if m.Name=="Chair" then m.Parent=backup end end
local source=game.ServerStorage:WaitForChild("InstitutionChair")
for _,r in {{145,-120},{177,-120},{196,-109},{219,-109}} do
 local m=source:Clone();m.Name="InstitutionChair";m.Parent=out
 local cf=CFrame.new(r[1],1,r[2])*CFrame.Angles(0,math.pi,0)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CFrame=cf*p.CFrame;p.Anchored=true;p.CanCollide=false;p.CanTouch=false end end
 local c=Instance.new("Part");c.Name="ChairCollision";c.Size=Vector3.new(2,2.1,2);c.Position=Vector3.new(r[1],2.05,r[2]);c.Anchored=true;c.Transparency=1;c.Parent=m
end
-- One continuous substrate avoids independently shaded 16-stud patchwork.
for _,p in root:GetDescendants() do if p:IsA("BasePart") and p.Name=="Floor_Library" then p.Parent=backup end end
local floor=Instance.new("Part");floor.Name="ContinuousLibraryCarpet";floor.Size=Vector3.new(144,1,144);floor.Position=Vector3.new(160,.5,-160);floor.Anchored=true;floor.Material=Enum.Material.Fabric;floor.Color=Color3.fromRGB(42,57,43);floor.TopSurface=Enum.SurfaceType.Smooth;floor.Parent=out
local t=Instance.new("Texture");t.Name="FineCarpetWeave";t.Texture="rbxassetid://1587302687";t.Face=Enum.NormalId.Top;t.StudsPerTileU=6;t.StudsPerTileV=6;t.Color3=Color3.fromRGB(64,83,61);t.Transparency=.42;t.Parent=floor
local function finishWall(p,faces)
 for _,v in p:GetChildren() do if v:IsA("Texture") and v.Name=="WornWallpaper" then v.Parent=backup end end
 p.Color=Color3.fromRGB(131,129,115);p.Material=Enum.Material.Concrete
 for _,face in faces do
  local tx=Instance.new("Texture");tx.Name="SubtleWallGrain";tx.Texture="rbxassetid://762795527";tx.Face=face;tx.StudsPerTileU=8;tx.StudsPerTileV=8;tx.Color3=Color3.fromRGB(161,158,141);tx.Transparency=.3;tx.Parent=p
 end
end
for _,p in art.CornerPolish:GetChildren() do if p:IsA("BasePart") and p.Name=="AgedPlaster" then
 finishWall(p,p.Size.X>p.Size.Z and {Enum.NormalId.Front,Enum.NormalId.Back} or {Enum.NormalId.Left,Enum.NormalId.Right})
end end
-- Exposed base walls at cladding breaks are structure, not new barriers.
for _,p in root.CleanArchitecture:GetChildren() do if p:IsA("BasePart") then
 local x,z=p.Position.X,p.Position.Z
 if math.abs(x-88)<.05 and z>=-233 and z<=-87 then finishWall(p,{Enum.NormalId.Right})
 elseif math.abs(x-232)<.05 and z>=-233 and z<=-87 then finishWall(p,{Enum.NormalId.Left})
 elseif math.abs(z+232)<.05 and x>=88 and x<=232 then finishWall(p,{Enum.NormalId.Back})
 elseif math.abs(z+88)<.05 and x>=88 and x<=232 then finishWall(p,{Enum.NormalId.Front}) end
end end
out:SetAttribute("Ready",true)
