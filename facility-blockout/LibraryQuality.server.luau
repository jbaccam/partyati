-- Reviewed static prop templates; no imported code or runtime asset insertion.
local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
local finish=art:WaitForChild("LibraryFinish")
local corner=art:WaitForChild("CornerPolish")
while not corner:GetAttribute("Ready") do task.wait() end
if art:FindFirstChild("QualityProps") then return end
local templates=game.ServerStorage:WaitForChild("LibraryPropTemplates")
local out=Instance.new("Model");out.Name="QualityProps";out.Parent=art
local backup=Instance.new("Folder");backup.Name="LibraryBlockProps_PreQuality";backup.Parent=game.ServerStorage
local replace={CheckoutCRT=true,DarkMonitorGlass=true,Keyboard=true,DeskLampBase=true,DeskLampStem=true,DeskLampShade=true,ReadingLampBase=true,ReadingLampStem=true,ReadingLampShade=true,ChairSeat=true,ChairBack=true,ChairLeg=true}
for _,container in {finish,corner} do
 for _,v in container:GetChildren() do if replace[v.Name] then v.Parent=backup end end
end
local function bounds(m)
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=p.CFrame*Vector3.new(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2);lo=lo:Min(v);hi=hi:Max(v)
  end end end
 end end
 return lo,hi
end
local function place(name,height,pos,yaw)
 local m=templates[name]:Clone();m.Name=name;m.Parent=out
 local lo,hi=bounds(m);local scale=height/(hi.Y-lo.Y)
 local center=Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2)
 local cf=CFrame.new(pos)*CFrame.Angles(0,yaw or 0,0)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then
  p.Size*=scale;p.CFrame=cf*CFrame.new((p.Position-center)*scale)*p.CFrame.Rotation
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false
 end end
 return m
end
for _,r in {{178,5.15,-112},{199,4.6,-104},{222,4.6,-104}} do
 local lamp=place("BankersLamp",2.05,Vector3.new(table.unpack(r)),math.pi/2)
 local anchor=Instance.new("Part");anchor.Name="TaskLight";anchor.Size=Vector3.one*.1;anchor.Position=Vector3.new(r[1],r[2]+1.65,r[3]);anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.Parent=lamp
 local light=Instance.new("PointLight");light.Brightness=.85;light.Range=20;light.Color=Color3.fromRGB(228,204,153);light.Shadows=false;light.Parent=anchor
end
place("VintageComputer",2.9,Vector3.new(146,5.15,-112),0)
for _,r in {{145,-120},{177,-120},{196,-109},{219,-109}} do
 local chair=place("Chair",4.4,Vector3.new(r[1],1,r[2]),math.pi)
 for _,v in chair:GetDescendants() do if v:IsA("BasePart") then v.Color=Color3.fromRGB(148,128,98) end end
 -- Simple invisible collision, not dozens of snagging mesh surfaces.
 local collider=Instance.new("Part");collider.Name="ChairCollision";collider.Size=Vector3.new(2,2.2,2);collider.Position=Vector3.new(r[1],2.1,r[2]);collider.Anchored=true;collider.Transparency=1;collider.Parent=chair
end
for _,floor in root:GetDescendants() do if floor:IsA("BasePart") and floor.Name=="Floor_Library" then
 local t=Instance.new("Texture");t.Name="WornCarpet";t.Texture="rbxassetid://7851491033";t.Face=Enum.NormalId.Top;t.StudsPerTileU=16;t.StudsPerTileV=16;t.Color3=Color3.fromRGB(85,109,76);t.Parent=floor
 floor.Color=Color3.fromRGB(45,58,39)
end end
for _,wall in corner:GetChildren() do if wall:IsA("BasePart") and wall.Name=="AgedPlaster" then
 -- Tile at human scale; wall panels remain flush and door openings unchanged.
 for _,face in (wall.Size.X>wall.Size.Z and {Enum.NormalId.Front,Enum.NormalId.Back} or {Enum.NormalId.Left,Enum.NormalId.Right}) do
  local t=Instance.new("Texture");t.Name="WornWallpaper";t.Texture="rbxassetid://71812035749325";t.Face=face;t.StudsPerTileU=10;t.StudsPerTileV=16;t.Color3=Color3.fromRGB(172,170,146);t.Parent=wall
 end
end end
out:SetAttribute("Ready",true)
