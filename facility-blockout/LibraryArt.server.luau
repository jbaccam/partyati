-- First art sample only: procedural original assets and Roblox built-in materials.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("GeometryCleaned") do task.wait() end
if root:FindFirstChild("LibraryArt") then return end
local art=Instance.new("Model");art.Name="LibraryArt";art.Parent=root
local rng=Random.new(613)
local wood=Color3.fromRGB(58,39,27)
local function part(name,size,cf,color,material,parent,collide)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.Color=color
 p.Material=material or Enum.Material.Wood;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.CanCollide=collide~=false;p.Parent=parent or art;return p
end
local shelves={}
for _,v in root:GetChildren() do
 if v.Name=="ShelfBlock" then table.insert(shelves,v)
 elseif v:IsA("BasePart") and v.Name=="Floor_Library" then v.Material=Enum.Material.Fabric;v.Color=Color3.fromRGB(34,53,37) end
end
local colors={Color3.fromRGB(56,47,34),Color3.fromRGB(69,60,44),Color3.fromRGB(44,51,43),Color3.fromRGB(68,41,34),Color3.fromRGB(40,45,49),Color3.fromRGB(93,81,60)}
for _,old in shelves do
 local model=Instance.new("Model");model.Name="AgedBookshelf";model.Parent=art
 local reverse=old.Position.X==172 and old.Position.Z==-212
 local fallen=reverse or (old.Position.X==140 and old.Position.Z==-178) or (old.Position.X==188 and old.Position.Z==-144)
 local cf=CFrame.new(old.Position.X,7,old.Position.Z)
 if fallen then
  -- Heel on floor, upper corner braced against the next upright case's side.
  local direction=reverse and -1 or 1
  cf=CFrame.new(old.Position.X+direction*(14-8/math.sqrt(2)),1+8/math.sqrt(2),old.Position.Z)*CFrame.Angles(0,0,-direction*math.pi/4)
  model:SetAttribute("LeanDirection",direction)
  model.Name="LeaningBookshelf";model:SetAttribute("LeanDegrees",45)
 end
 model:SetAttribute("Fallen",fallen)
 local function s(name,size,x,y,z,color,mat,collide)
  return part(name,size,cf*CFrame.new(x,y,z),color or wood,mat,model,collide)
 end
 -- Four-stud depth replaces the former eight-stud blocks.
 s("Backboard",Vector3.new(.3,12,24),0,0,0)
 for _,z in {-11.8,0,11.8} do s("EndPanel",Vector3.new(4,12,.4),0,0,z) end
 for _,y in {-5.8,-3.5,-1.2,1.1,3.4,5.8} do s("Shelf",Vector3.new(4,.4,24),0,y,0) end
 for _,side in {-1,1} do for level=0,4 do for bay=0,7 do
  if rng:NextNumber()>.13 then
   local h=rng:NextNumber(1.3,1.8);local len=rng:NextNumber(1.6,2.4);local z=-10.2+bay*2.9
   local book=s("WornVolumes",Vector3.new(1.5,h,len),side*.95,-5.6+level*2.3+h/2,z,colors[rng:NextInteger(1,#colors)],Enum.Material.Fabric,false)
   book.CastShadow=false
   s("SpineBand",Vector3.new(.03,.07,len*.85),side*1.72,-5.25+level*2.3,z,Color3.fromRGB(108,92,61),Enum.Material.Wood,false).CastShadow=false
  end
 end end end
 old:Destroy()
end
-- BROKEN AISLE CASE: open-backed furniture, not a wall panel.
local wreck=Instance.new("Model");wreck.Name="BrokenAisleBookshelf";wreck.Parent=art
local function broken(name,size,x,y,z,angle,color)
 return part(name,size,CFrame.new(x,y,z)*CFrame.Angles(0,0,angle or 0),color or wood,Enum.Material.Wood,wreck)
end
for _,x in {158.3,169.7} do broken("BatteredSide",Vector3.new(.4,10,3),x,6,-166.5) end
for _,y in {1.25,3.65,6.05} do broken("ShelfBoard",Vector3.new(11,.35,3),164,y,-166.5) end
broken("SplitUpperShelf",Vector3.new(6,.35,3),161.5,8.5,-166.5)
broken("SaggingShelfFragment",Vector3.new(4.2,.35,2.8),167,7.9,-166.5,-.25)
broken("BrokenTopLeft",Vector3.new(7,.45,3),161.9,10.7,-166.5)
broken("BrokenTopRight",Vector3.new(3.7,.45,3),168,10.2,-166.5,-.28)
broken("SnappedDivider",Vector3.new(.3,4.6,2.8),163,3.7,-166.5)
-- Irregular book clusters make the obstruction recognizable from either approach.
for row=0,2 do for col=0,6 do
 if not (row==2 and col>3) and not (row==1 and col==2) then
  local h=1.2+(col%3)*.2
  local book=broken("DislodgedBooks",Vector3.new(.75,h,1.7),159.3+col*1.45,1.45+row*2.4+h/2,-166.6,(col%2==0) and .1 or -.12,colors[(col+row)%#colors+1])
  book.CanCollide=false;book.CastShadow=false
 end
end end
broken("WedgedBrokenPlank",Vector3.new(.65,6.3,.35),166.1,4.2,-168.05,.5)
-- END BROKEN AISLE CASE
part("BlackCeiling",Vector3.new(144,2,144),CFrame.new(160,18,-160),Color3.fromRGB(15,17,16),Enum.Material.Concrete)
-- Interior plaster lining split at existing entrances, with dark wood skirting.
local function wall(x,z,length,rotate)
 local cf=CFrame.new(x,9,z)*CFrame.Angles(0,rotate,0)
 part("AgedPlaster",Vector3.new(length,16,.18),cf,Color3.fromRGB(104,105,92),Enum.Material.Concrete)
 part("Skirting",Vector3.new(length,.65,.24),cf*CFrame.new(0,-7.6,-.13),wood)
 for i=1,math.floor(length/9) do
  local px=rng:NextNumber(-length/2+.5,length/2-.5)
  part("DampStreak",Vector3.new(rng:NextNumber(.1,.5),rng:NextNumber(.5,2),.015),cf*CFrame.new(px,-5.5,-.105),Color3.fromRGB(77,81,69),Enum.Material.Concrete,nil,false)
 end
end
wall(160,-231.3,142,0);wall(231.3,-160,142,math.pi/2)
for _,r in {{-231,-190},{-178,-126},{-114,-89}} do wall(88.7,(r[1]+r[2])/2,r[2]-r[1],-math.pi/2) end
for _,r in {{89,162},{174,231}} do wall((r[1]+r[2])/2,-88.7,r[2]-r[1],math.pi) end
for _,r in {{116,-212,true},{164,-195,true},{212,-178,false},{132,-161,false},{180,-127,true},{100,-184,true},{216,-102,false}} do
 local x,z,working=r[1],r[2],r[3]
 part("OldFixtureHousing",Vector3.new(2,.5,6),CFrame.new(x,16.6,z),Color3.fromRGB(62,64,58),Enum.Material.Metal)
 local p=part(working and "Fluorescent" or "DeadFluorescent",Vector3.new(1.2,.12,5),CFrame.new(x,16.28,z),working and Color3.fromRGB(204,207,166) or Color3.fromRGB(62,66,61),working and Enum.Material.Neon or Enum.Material.Glass)
 if working then local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Angle=110;l.Range=40;l.Brightness=3.3;l.Color=Color3.fromRGB(220,217,174);l.Shadows=true;l.Parent=p end
end
-- Global exposure establishes night; detailed lighting is restricted to the library.
local lighting=game:GetService("Lighting")
for _,key in {"ClockTime","Brightness","Ambient","OutdoorAmbient","ExposureCompensation","EnvironmentDiffuseScale","EnvironmentSpecularScale","GlobalShadows"} do
 if lighting:GetAttribute("FacilityBefore_"..key)==nil then lighting:SetAttribute("FacilityBefore_"..key,lighting[key]) end
end
-- Gameplay lighting is applied separately, even when edit-time geometry already exists.
root:SetAttribute("LibraryArtReady",true)
