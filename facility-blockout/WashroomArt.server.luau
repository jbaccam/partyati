local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("GeometryCleaned")do task.wait()end
if root:FindFirstChild("WashroomArt")then return end
local out=Instance.new("Model");out.Name="WashroomArt";out.Parent=root
local backups=Instance.new("Folder");backups.Name="Washroom_PreArt";backups.Parent=game.ServerStorage
local function p(n,s,pos,c,mat)
 local v=Instance.new("Part");v.Name=n;v.Anchored=true;v.Size=s;v.Position=pos;v.Color=c;v.Material=mat or Enum.Material.SmoothPlastic;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v.Parent=out;return v
end
local green=Color3.fromRGB(58,76,66);local metal=Color3.fromRGB(102,107,101)
local floor=p("WashroomTileFloor",Vector3.new(159,.04,87),Vector3.new(-160,-38.98,188),Color3.fromRGB(92,112,111))
floor.CanCollide=false
-- Fine grout, not separate independently shaded floor blocks.
for x=-238,-82,2 do local g=p("Grout",Vector3.new(.025,.012,87),Vector3.new(x,-38.94,188),Color3.fromRGB(61,72,69));g.CanCollide=false;g.CastShadow=false end
for z=146,230,2 do local g=p("Grout",Vector3.new(159,.012,.025),Vector3.new(-160,-38.94,z),Color3.fromRGB(61,72,69));g.CanCollide=false;g.CastShadow=false end
for _,v in root.Basement:GetChildren()do
 if v.Name=="WashroomScreen"then v.Color=green;v.Material=Enum.Material.Metal end
 if v.Name=="BasinPlaceholder"and math.abs(v.Position.X+211)<1 then v.Parent=backups end
end
local function asset(n,pos,yaw)
 local m=game.ServerStorage:WaitForChild("WashroomTemplates")[n]:Clone();m.Parent=out
 local cf=CFrame.new(pos)*CFrame.Angles(0,yaw,0)
 for _,v in m:GetDescendants()do if v:IsA("BasePart")then v.CFrame=cf*v.CFrame;v.Anchored=true;v.CanCollide=true;v.CanTouch=false end end
end
-- First western fixture bay: three offset stall leaves, clear side aisle.
for _,z in {158,170,182,194}do
 p("StallPartition",Vector3.new(10,7.6,.2),Vector3.new(-234,-34.2,z),green,Enum.Material.Metal)
 for _,x in {-238.5,-229.5}do p("PartitionFoot",Vector3.new(.22,.9,.22),Vector3.new(x,-38.45,z),metal,Enum.Material.Metal)end
end
for i,z in {164,176,188}do
 asset("Toilet",Vector3.new(-236,-38.95,z),math.pi/2)
 local angle=math.rad(({65,80,55})[i])
 local hinge=CFrame.new(-229,-34.2,z-5.8)*CFrame.Angles(0,angle,0)
 local door=p("StallDoorAjar",Vector3.new(.18,7.4,5.5),Vector3.zero,green,Enum.Material.Metal);door.CFrame=hinge*CFrame.new(0,0,2.75)
 for _,dy in {-2.5,2.5}do p("StallHinge",Vector3.new(.28,.4,.3),Vector3.new(-229,-34.2+dy,z-5.8),metal,Enum.Material.Metal)end
 local latch=p("StallLatch",Vector3.new(.14,.22,.5),Vector3.zero,metal,Enum.Material.Metal);latch.CFrame=door.CFrame*CFrame.new(.15,0,2.2)
 local roll=p("PaperRoll",Vector3.new(.6,.8,.8),Vector3.new(-233,-36,z-5.4),Color3.fromRGB(161,157,139));roll.Shape=Enum.PartType.Cylinder
end
for _,x in {-211,-203,-195}do
 -- Rear rim slightly overlaps the splashback face at Z=144.73.
 asset("CeramicSink",Vector3.new(x,-38.95,145.59),math.pi)
 p("MirrorFrame",Vector3.new(3.4,3.9,.16),Vector3.new(x,-33.4,145.2),metal,Enum.Material.Metal)
 local glass=p("AgedMirror",Vector3.new(3.1,3.6,.04),Vector3.new(x,-33.4,145.31),Color3.fromRGB(90,110,110),Enum.Material.Glass);glass.Reflectance=.15
end
-- Ceiling and warm/cool lighting belong to this bay only.
local ceiling=p("WashroomCeiling",Vector3.new(49,.3,55),Vector3.new(-215,-23.2,172),Color3.fromRGB(34,37,35));ceiling.CanCollide=false
for x=-239,-191,4 do p("CeilingTBar",Vector3.new(.045,.04,55),Vector3.new(x,-23.37,172),Color3.fromRGB(61,65,60),Enum.Material.Metal)end
for z=146,198,4 do p("CeilingTBar",Vector3.new(49,.04,.045),Vector3.new(-215,-23.37,z),Color3.fromRGB(61,65,60),Enum.Material.Metal)end
for _,r in {{-206,153},{-224,174},{-224,194}}do
 p("LightHousing",Vector3.new(2.4,.3,5),Vector3.new(r[1],-23.6,r[2]),metal,Enum.Material.Metal)
 local bulb=p("Diffuser",Vector3.new(2.1,.1,4.7),Vector3.new(r[1],-23.8,r[2]),Color3.fromRGB(189,201,178),Enum.Material.Neon)
 local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Angle=110;light.Range=28;light.Brightness=2.5;light.Color=Color3.fromRGB(199,212,188);light.Shadows=true;light.Parent=bulb
end
out:SetAttribute("FirstBayReady",true)
