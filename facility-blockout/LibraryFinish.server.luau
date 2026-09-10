-- Scoped library dressing. No player-control or objective changes.
local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
while art:GetAttribute("VariedShelvesVersion")~=1 do task.wait() end
if art:FindFirstChild("LibraryFinish") then return end
local finish=Instance.new("Model");finish.Name="LibraryFinish";finish.Parent=art
local backup=Instance.new("Folder");backup.Name="Library_PreFinish_"..os.time();backup.Parent=game.ServerStorage
local wood=Color3.fromRGB(55,36,24);local metal=Color3.fromRGB(49,51,47)
local function p(name,size,cf,color,mat,collide)
 local v=Instance.new("Part");v.Name=name;v.Size=size;v.CFrame=cf;v.Color=color or wood;v.Material=mat or Enum.Material.Wood
 v.Anchored=true;v.CanCollide=collide~=false;v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v.Parent=finish;return v
end
local bay=game.ServerStorage:WaitForChild("BookshelfBay")
local upright,flat
for _,v in bay:GetDescendants()do if v:IsA("MeshPart")then
 if v.Name=="Books 2" and v.Position.Y>10 and v.Position.Z> -9 then upright=v end
 if v.Name=="Old book" then flat=v end
end end
assert(upright and flat,"Reviewed book assets missing")
local function bounds(v)
 local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
 for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do local q=v.CFrame:PointToWorldSpace(v.Size*Vector3.new(x,y,z)/2);low=low:Min(q);high=high:Max(q) end end end
 return (low+high)/2,high-low
end
local function book(template,cf,scale)
 local v=template:Clone();local center=bounds(v);v.CFrame=cf*CFrame.new((v.Position-center)*scale)*v.CFrame.Rotation;v.Size*=scale
 v.CanCollide=false;v.CanTouch=false;v.CastShadow=false;v.Parent=finish;return v
end
-- Replace the broken case with the same cabinet/book asset family, stripped of backing.
local old=art:FindFirstChild("BrokenAisleBookshelf");if old then old.Parent=backup end
local broken=Instance.new("Model");broken.Name="BrokenAisleBookshelf";broken.Parent=finish
for i=0,1 do
 local transform=CFrame.new(161+i*6,1,-166.5)*CFrame.Angles(0,-math.pi/2,0)*CFrame.new(.8,0,9)
 for _,v in bay:GetDescendants()do if v:IsA("BasePart")then
  local back=v.Material==Enum.Material.Wood and v.Size.Z<.1 and v.Size.Y>10
  local missing=(i==1 and v.Position.Y>8 and v.Position.Y<9.6) or v.Position.Y>11.25
  if not back and not missing then
   local c=v:Clone();c.CFrame=transform*v.CFrame;c.Anchored=true;c.CanCollide=v.Material==Enum.Material.Wood;c.CastShadow=c.CanCollide;c.Parent=broken
  end
 end end
end
p("SnappedFrameBrace",Vector3.new(.45,6,.4),CFrame.new(165,4.2,-167.8)*CFrame.Angles(0,0,.45))
-- Replace slide-wall greybox with a checkout counter and open service hatch.
for _,v in root:GetChildren()do
 if v:IsA("BasePart") and v.Position.X>88 and v.Position.Z< -88 and
  (v.Name=="SlideWallLeft" or v.Name=="SlideWallRight" or v.Name=="SlideOpening_10x3" or v.Name=="LibraryHurdle")then v.Parent=backup end
end
for _,x in {147,173}do
 p("CheckoutCabinet",Vector3.new(16,3.8,4.6),CFrame.new(x,2.9,-112))
 for i=-1,1 do
  p("DrawerFront",Vector3.new(4.7,2.8,.16),CFrame.new(x+i*5,3,-114.4),Color3.fromRGB(66,45,30))
  p("DrawerHandle",Vector3.new(1.2,.14,.18),CFrame.new(x+i*5,3.8,-114.57),metal,Enum.Material.Metal,false)
 end
end
local beam=p("CheckoutSlideHeader",Vector3.new(10,.8,4.6),CFrame.new(160,4.4,-112))
beam:SetAttribute("TraversalType","Slide");beam:SetAttribute("ClearanceStuds",3)
p("WornCountertop",Vector3.new(42.4,.35,5.1),CFrame.new(160,4.975,-112),Color3.fromRGB(85,67,44))
p("CheckoutCRT",Vector3.new(3.2,2.7,2.7),CFrame.new(146,6.5,-111.7),Color3.fromRGB(97,93,74),Enum.Material.SmoothPlastic)
p("DarkMonitorGlass",Vector3.new(2.6,1.8,.08),CFrame.new(146,6.6,-113.09),Color3.fromRGB(21,29,27),Enum.Material.Glass,false)
p("Keyboard",Vector3.new(3,.18,1),CFrame.new(146,5.25,-114),Color3.fromRGB(71,69,57),Enum.Material.SmoothPlastic,false)
for i=1,3 do p("CheckoutPaper",Vector3.new(1.6,.02,2),CFrame.new(174+i*.08,5.17+i*.023,-112)*CFrame.Angles(0,i*.07,0),Color3.fromRGB(159,150,123),Enum.Material.SmoothPlastic,false) end
-- Dress the other existing low underpass without reducing its clearance.
for _,v in root:GetChildren()do if v.Name=="FallenShelfTop" or v.Name=="ShelfSupport" then v.Material=Enum.Material.Wood;v.Color=wood end end
for _,x in {196,204,208}do book(flat,CFrame.new(x,6.2,-125)*CFrame.Angles(0,.4,0),1) end
local function chair(x,z,angle)
 local cf=CFrame.new(x,1,z)*CFrame.Angles(0,angle,0)
 p("ChairSeat",Vector3.new(3,.35,2.8),cf*CFrame.new(0,1.8,0),Color3.fromRGB(55,66,52),Enum.Material.Fabric)
 p("ChairBack",Vector3.new(3,2.8,.35),cf*CFrame.new(0,3.2,1.25),Color3.fromRGB(55,66,52),Enum.Material.Fabric)
 for _,a in {-1.15,1.15}do for _,b in {-1.05,1.05}do p("ChairLeg",Vector3.new(.18,1.65,.18),cf*CFrame.new(a,.825,b),metal,Enum.Material.Metal)end end
end
chair(145,-120,math.pi);chair(177,-120,math.pi)
for _,x in {196,219}do
 p("StudyDeskTop",Vector3.new(10,.4,5.5),CFrame.new(x,4.4,-104),Color3.fromRGB(73,51,32))
 for _,dx in {-4,4}do for _,dz in {-2,2}do p("DeskLeg",Vector3.new(.35,3.2,.35),CFrame.new(x+dx,2.6,-104+dz),metal,Enum.Material.Metal)end end
 chair(x,-109,math.pi)
 book(flat,CFrame.new(x-2,4.85,-104)*CFrame.Angles(0,.25,0),1)
end
-- A single wall corner, not all walls: dense upright-only book clusters.
for _,y in {1.25,3.25,5.25,7.25,9.25,11.25}do p("WallBookcaseShelf",Vector3.new(32,.3,1.8),CFrame.new(208,y,-90.4))end
for _,x in {192.2,208,223.8}do p("WallBookcaseUpright",Vector3.new(.35,10,1.8),CFrame.new(x,6.25,-90.4))end
local _,size=bounds(upright);local scale=math.min(2.18/size.Z,1.6/size.Y,1.45/size.X)
for row=0,4 do for col=0,12 do
 book(upright,CFrame.new(193.3+col*2.42,1.43+row*2+size.Y*scale/2,-90.5)*CFrame.Angles(0,-math.pi/2,0),scale)
end end
-- Sparse fallen books, kept out of entrances and the slide approach.
for _,r in {{188,-97,.2},{210,-116,-.7},{224,-121,1.2},{135,-103,.5},{198,-95,-.3}}do
 local _,s=bounds(flat);book(flat,CFrame.new(r[1],1.03+s.Y/2,r[2])*CFrame.Angles(0,r[3],0),1)
end
-- One warm checkout task lamp provides a readable landmark.
p("DeskLampBase",Vector3.new(1.2,.18,1.2),CFrame.new(178,5.24,-112),metal,Enum.Material.Metal)
p("DeskLampStem",Vector3.new(.13,1.6,.13),CFrame.new(178,6.1,-112),metal,Enum.Material.Metal)
local shade=p("DeskLampShade",Vector3.new(2,.6,1.5),CFrame.new(178,7,-112),Color3.fromRGB(72,79,53),Enum.Material.Metal)
local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Range=15;light.Brightness=1.6;light.Color=Color3.fromRGB(232,194,124);light.Shadows=true;light.Parent=shade
finish:SetAttribute("Ready",true)
