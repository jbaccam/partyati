local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
while not art:WaitForChild("AlignedEntrances"):GetAttribute("Ready")do task.wait()end
if art:FindFirstChild("UnifiedFurniture")then return end
local out=Instance.new("Model");out.Name="UnifiedFurniture";out.Parent=art
local backup=Instance.new("Folder");backup.Name="Library_PreUnifiedFurniture";backup.Parent=game.ServerStorage
for _,folder in {art.QualityProps,art.LibraryRefinement}do for _,m in folder:GetChildren()do
 if m.Name=="BankersLamp"or m.Name=="VintageComputer"or m.Name=="InstitutionChair"then m.Parent=backup end
end end
local templates=game.ServerStorage:WaitForChild("CoherentKitTemplates")
local function place(name,pos,yaw)
 local m=templates[name]:Clone();m.Parent=out;local cf=CFrame.new(pos)*CFrame.Angles(0,yaw,0)
 for _,p in m:GetDescendants()do if p:IsA("BasePart")then p.CFrame=cf*p.CFrame;p.Anchored=true;p.CanCollide=false;p.CanTouch=false end end;return m
end
for _,r in {{145,-117},{177,-117},{196,-108.5},{219,-108.5}}do
 local m=place("OfficeChair",Vector3.new(r[1],1,r[2]),math.pi)
 local c=Instance.new("Part");c.Name="ChairCollision";c.Size=Vector3.new(2.5,2,2.2);c.Position=Vector3.new(r[1],2,r[2]);c.Transparency=1;c.Anchored=true;c.Parent=m
end
place("Terminal",Vector3.new(146,5.15,-111),math.pi)
place("Keyboard",Vector3.new(146,5.15,-113.65),0)
-- Matching matte articulated task lights. Generated geometry avoids importing
-- asset interaction scripts or relying on runtime InsertService permissions.
local function part(parent,n,size,cf,color,shape)
 local p=Instance.new("Part");p.Name=n;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;if shape then p.Shape=shape end;p.Parent=parent;return p
end
local metal=Color3.fromRGB(51,53,49)
local function rod(m,a,b,r)
 local mid=(a+b)/2;local p=part(m,"ArticulatedArm",Vector3.new(r,(b-a).Magnitude,r),CFrame.lookAt(mid,b)*CFrame.Angles(math.pi/2,0,0),metal)
 return p
end
for _,r in {{178,5.15,-112},{199,4.6,-104},{222,4.6,-104}}do
 local m=Instance.new("Model");m.Name="MatteTaskLamp";m.Parent=out
 local o=Vector3.new(table.unpack(r))
 part(m,"WeightedBase",Vector3.new(.16,1.05,1.05),CFrame.new(o+Vector3.new(0,.08,0))*CFrame.Angles(0,0,math.pi/2),metal,Enum.PartType.Cylinder)
 local a=o+Vector3.new(0,.18,0);local b=o+Vector3.new(.2,1.05,.18);local c=o+Vector3.new(0,1.95,-.35)
 rod(m,a,b,.09);rod(m,b,c,.09)
 for _,v in {a,b,c}do part(m,"Pivot",Vector3.one*.18,CFrame.new(v),metal,Enum.PartType.Ball)end
 local center=c+Vector3.new(0,-.06,-.27)
 local sphere=part(m,"EnamelShade",Vector3.new(1.05,.72,1.05),CFrame.new(center),metal,Enum.PartType.Ball)
 local inside=part(m,"TemporaryShadeInner",Vector3.new(.91,.64,.91),CFrame.new(center-Vector3.new(0,.06,0)),metal,Enum.PartType.Ball)
 local cut=part(m,"TemporaryShadeOpening",Vector3.new(2,1,2),CFrame.new(center-Vector3.new(0,.5,0)),metal)
 local ok,shade=pcall(function()return sphere:SubtractAsync({inside,cut},Enum.CollisionFidelity.Box,Enum.RenderFidelity.Automatic)end)
 if ok then shade.Name="EnamelShade";shade.Anchored=true;shade.CanCollide=false;shade.Color=metal;shade.UsePartColor=true;shade.Parent=m;sphere:Destroy()end
 inside:Destroy();cut:Destroy()
 local bulb=part(m,"WarmBulb",Vector3.new(.2,.1,.2),CFrame.new(center-Vector3.new(0,.04,0)),Color3.fromRGB(221,210,171),Enum.PartType.Ball);bulb.Material=Enum.Material.Neon
 local light=Instance.new("PointLight");light.Color=Color3.fromRGB(223,205,162);light.Brightness=.85;light.Range=20;light.Shadows=false;light.Parent=bulb
end
out:SetAttribute("Ready",true)
