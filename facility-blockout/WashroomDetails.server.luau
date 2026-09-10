local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:WaitForChild("WashroomArt"):GetAttribute("FirstBayReady")do task.wait()end
if root:FindFirstChild("WashroomDetails")then return end
local out=Instance.new("Model");out.Name="WashroomDetails";out.Parent=root
local metal=Color3.fromRGB(72,79,75)
local function p(n,s,pos,c,mat,shape)
 local v=Instance.new("Part");v.Name=n;v.Size=s;v.Position=pos;v.Color=c;v.Material=mat or Enum.Material.SmoothPlastic;v.Anchored=true;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;if shape then v.Shape=shape end;v.Parent=out;return v
end
-- Local tile splashback ends before the washroom entrance; no route is closed.
local tile=Color3.fromRGB(127,139,128);local grout=Color3.fromRGB(87,98,91)
p("SinkSplashback",Vector3.new(48,.1,5),Vector3.zero,tile).CFrame=CFrame.new(-215,-36.4,144.68)*CFrame.Angles(math.pi/2,0,0)
for x=-239,-191,2 do p("SplashbackGrout",Vector3.new(.025,5,.018),Vector3.new(x,-36.4,144.75),grout)end
for y=-38.9,-33.9,1 do p("SplashbackGrout",Vector3.new(48,.025,.018),Vector3.new(-215,y,144.75),grout)end
p("TileCap",Vector3.new(48,.12,.18),Vector3.new(-215,-33.84,144.72),metal,Enum.Material.Metal)
-- Wall-mounted dispensers beside the mirrors; subdued rounded housings.
for _,x in {-207,-199}do
 local body=p("SoapDispenser",Vector3.new(.65,1,.5),Vector3.new(x,-35,145.1),Color3.fromRGB(91,101,95))
 local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=body
 p("SoapLever",Vector3.new(.45,.1,.45),Vector3.new(x,-35.38,145.38),metal,Enum.Material.Metal)
end
-- Short slatted bench placed beyond the stalls, away from the side aisle.
local wood=Color3.fromRGB(79,64,45)
for i=0,3 do p("BenchSlat",Vector3.new(.43,.18,9.5),Vector3.new(-238+i*.5,-36.8,216),wood,Enum.Material.Wood)end
for _,z in {212.4,219.6}do
 p("BenchCrossbar",Vector3.new(2,.15,.22),Vector3.new(-237.25,-37,z),metal,Enum.Material.Metal)
 for _,x in {-238,-236.5}do local leg=p("BenchTubularLeg",Vector3.new(1.8,.17,.17),Vector3.new(x,-38,z),metal,Enum.Material.Metal,Enum.PartType.Cylinder);leg.CFrame*=CFrame.Angles(0,0,math.pi/2)end
end
-- Drain inset on top of the existing floor; thin bars don't obstruct walking.
local drain=p("DrainRecess",Vector3.new(1.3,.025,1.3),Vector3.new(-206,-38.915,159),Color3.fromRGB(30,36,32),Enum.Material.Metal);drain.CanCollide=false
for i=-3,3 do local bar=p("DrainGrille",Vector3.new(.06,.035,1.2),Vector3.new(-206+i*.17,-38.9,159),metal,Enum.Material.Metal);bar.CanCollide=false end
-- Extraction grille above the sinks.
p("VentFrame",Vector3.new(3,1.6,.18),Vector3.new(-215,-26,145),metal,Enum.Material.Metal)
p("VentDarkInset",Vector3.new(2.7,1.3,.2),Vector3.new(-215,-26,145.1),Color3.fromRGB(25,30,27))
for i=-3,3 do local slat=p("VentLouver",Vector3.new(2.6,.075,.25),Vector3.new(-215,-26+i*.16,145.25),Color3.fromRGB(93,101,94),Enum.Material.Metal);slat.CFrame*=CFrame.Angles(.3,0,0)end
out:SetAttribute("Ready",true)
