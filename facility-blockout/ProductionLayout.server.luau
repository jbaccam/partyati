-- Revised gameplay layout, built and tested before the production mesh kit.
local root=workspace:WaitForChild("FacilityLayoutReview")
local rooms=root:WaitForChild("RoomInteriors");while not rooms:GetAttribute("Ready") do task.wait() end
if root:FindFirstChild("ProductionLayout") then return end
local V=Vector3.new;local C=Color3.fromRGB
local out=Instance.new("Model");out.Name="ProductionLayout";out.Parent=root
local backup=Instance.new("Folder");backup.Name="Facility_PreProductionLayout";backup.Parent=game.ServerStorage
local function part(n,size,pos,col,parent)
 local p=Instance.new("Part");p.Name=n;p.Size=size;p.Position=pos;p.Anchored=true;p.Material=Enum.Material.Concrete;p.Color=col or C(112,117,105);p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent or out;return p
end
local function worldSize(p) local s=p.Size;return V(math.abs(p.CFrame.RightVector.X)*s.X+math.abs(p.CFrame.LookVector.X)*s.Z,s.Y,math.abs(p.CFrame.RightVector.Z)*s.X+math.abs(p.CFrame.LookVector.Z)*s.Z) end
local finish={PaintedWainscot=true,PlasterFinish=true,Skirting=true,ChairRail=true,CeilingCove=true,LowerWallPaint=true,UpperPlaster=true,WallMolding=true,FinishedDoorJamb=true,FinishedDoorLintel=true,DoorHeaderFinish=true,DoorJamb=true,DoorLintel=true,DoorThreshold=true}
local function cut(lo,hi,parents,onlyFinish)
 local list={};for _,parent in parents do for _,p in parent:GetDescendants() do if p:IsA("BasePart") and (not onlyFinish or finish[p.Name]) and math.abs(p.CFrame.UpVector.Y)>.999 then table.insert(list,p) end end end
 for _,p in list do local s=worldSize(p);local a,b=p.Position-s/2,p.Position+s/2
  local c,d=V(math.max(a.X,lo.X),math.max(a.Y,lo.Y),math.max(a.Z,lo.Z)),V(math.min(b.X,hi.X),math.min(b.Y,hi.Y),math.min(b.Z,hi.Z))
  if c.X<d.X-.001 and c.Y<d.Y-.001 and c.Z<d.Z-.001 then
   local boxes={{a,V(c.X,b.Y,b.Z)},{V(d.X,a.Y,a.Z),b},{V(c.X,a.Y,a.Z),V(d.X,c.Y,b.Z)},{V(c.X,d.Y,a.Z),V(d.X,b.Y,b.Z)},{V(c.X,c.Y,a.Z),V(d.X,d.Y,c.Z)},{V(c.X,c.Y,d.Z),V(d.X,d.Y,b.Z)}}
   for _,r in boxes do local size=r[2]-r[1];if size.X>.005 and size.Y>.005 and size.Z>.005 then local q=p:Clone();q.Size=size;q.CFrame=CFrame.new((r[1]+r[2])/2);q.Parent=p.Parent end end
   p.Parent=backup
  end
 end
end
-- Retire the visible stair boxes and restore their original room floors.
local stairNames={StairwellTop=true,StairwellSide=true,StairEntranceSide=true,UpperStairSkirting=true,StairEntranceBack=true,RestoredFloorBehindStairs=true,BasementLanding=true,StairwellEndAboveLanding=true,StairHandrail=true,RailStanchion=true,AntiSlipNosing=true,StairEntranceHeader=true}
for _,p in root.Hallways:GetDescendants() do if p:IsA("BasePart") and (stairNames[p.Name] or p:GetAttribute("PowerZone")=="WestStairs" or p:GetAttribute("PowerZone")=="EastStairs" or p.Name=="EnamelSign" and (math.abs(p.Position.X+224)<1 or math.abs(p.Position.X-208)<1) and p.Position.Z<25) then p.Parent=backup end end
for _,p in root.Basement:GetChildren() do if p.Name=="StairTread" or p.Name=="StairGuard" then p.Parent=backup end end
for _,x in {-224,208} do
 part("RestoredRoomSlab",V(16,1,96),V(x,.5,72),C(96,104,95))
 part("ClosedFormerStairPortal",V(16,16,1),V(x,-31,124),C(140,139,125))
end
-- New shafts fit the structural strips between room and hall, not inside rooms.
for _,r in {{-144,-136,1},{96,88,-1}} do local x,face,sign=table.unpack(r)
 -- Remove the old hallway floor tiles over the upper flight (both directions need headroom).
 for _,p in root:GetChildren() do if p:IsA("BasePart") and p.Name=="Floor_Hall" and math.abs(p.Position.X-x)<.1 and p.Position.Z>=24 and p.Position.Z<=48 then p.Parent=backup end end
 cut(V(x-8.5,-39,7.5),V(x+8.5,17,124.5),{root.CleanArchitecture})
 cut(V(x-8.6,1,7.5),V(x+8.6,17,124.5),{root.Hallways,rooms},true)
 local shaft=Instance.new("Model");shaft.Name=x<0 and "WestServiceStair" or "EastServiceStair";shaft.Parent=out
 part("UpperLanding",V(15,1,16),V(x,.5,16),nil,shaft)
 part("LowerLanding",V(15,1,21),V(x,-39.5,114.5),nil,shaft)
 for i=1,80 do part("StairTread",V(15,1,1),V(x,.5-i*.5,24+i-.5),C(94,99,90),shaft) end
 for _,side in {-1,1} do
  local wallx=x+side*8
  part("ShaftWall",V(.8,40,116),V(wallx,-19,66),C(140,139,125),shaft)
  if side==sign then
   part("CorridorWall",V(.8,16,2),V(wallx,9,9),C(140,139,125),shaft)
   part("CorridorWall",V(.8,16,102),V(wallx,9,73),C(140,139,125),shaft)
   part("StairDoorHeader",V(.8,5,12),V(wallx,14.5,16),C(140,139,125),shaft)
  else part("BackOfServiceWall",V(.8,16,116),V(wallx,9,66),C(140,139,125),shaft) end
 end
 part("HeadWall",V(16.8,56,.8),V(x,-11,8),C(140,139,125),shaft)
 part("ShaftRoof",V(17,.5,117),V(x,16.55,66),C(79,83,74),shaft)
 part("UpperFloorAboveStair",V(16,1,76),V(x,.5,86),C(96,104,95),shaft)
 part("EndAboveBasementDoor",V(16.8,40,.8),V(x,-3,124),C(140,139,125),shaft)
 shaft:SetAttribute("UpperEntry",V(face+sign*5,4,16));shaft:SetAttribute("Landing",V(x,4,16));shaft:SetAttribute("LowerEntry",V(x,-36,131))
end
-- This old prototype door was placed in front of solid medical wall, not its real aperture.
local dead=root.Basement:FindFirstChild("Medical East Door");if dead then dead.Parent=backup end
-- Skin only after geometry is correct: native wall sides, corners and jambs share material bands.
local solids={};for _,p in root.CleanArchitecture:GetChildren() do if p:IsA("BasePart") then table.insert(solids,p) end end
for _,p in out:GetDescendants() do if p:IsA("BasePart") and (p.Name:find("Wall") or p.Name:find("Header") or p.Name=="ClosedFormerStairPortal") then table.insert(solids,p) end end
for _,p in solids do
 local a,b=p.Position-p.Size/2,p.Position+p.Size/2;local levels={a.Y,b.Y}
 for _,y in {-39,-34.7,-23,1,5.3,17} do if y>a.Y+.01 and y<b.Y-.01 then table.insert(levels,y) end end;table.sort(levels)
 for i=1,#levels-1 do local q=p:Clone();q.Size=V(p.Size.X,levels[i+1]-levels[i],p.Size.Z);q.Position=V(p.Position.X,(levels[i]+levels[i+1])/2,p.Position.Z)
  local y=q.Position.Y;local lower=y>=-39 and y<-34.7 or y>=1 and y<5.3
  q.Color=lower and C(84,99,89) or C(140,139,125);q.Material=Enum.Material.Concrete
  if not lower then for _,face in Enum.NormalId:GetEnumItems() do local t=Instance.new("Texture");t.Name="WrappedPlaster";t.Texture="rbxassetid://762795527";t.Face=face;t.StudsPerTileU=8;t.StudsPerTileV=8;t.Transparency=.72;t.Color3=C(170,168,151);t.Parent=q end end
  q.Parent=p.Parent
 end;p.Parent=backup
end
-- Preserve architectural shells, temporarily replace rejected dressing by collision graybox.
local keep={ContinuousRoomFloor=true,SolidCeiling=true,LowerWallPaint=true,UpperPlaster=true,WallMolding=true,CeilingLuminaire=true,EnamelSign=true,LockedStorageDoor=true}
for _,name in {"Medical","Residential","CafeteriaKitchen","Storage","Reception"} do
 for _,p in rooms[name]:GetChildren() do if not keep[p.Name] then p.Parent=backup end end
end
local gray=Instance.new("Model");gray.Name="GameplayGraybox";gray.Parent=out
local function proxy(name,pos,size,asset,yaw)
 local p=part(name,size,pos,C(110,119,106),gray);p:SetAttribute("Asset",asset);p:SetAttribute("Placement",CFrame.new(pos-V(0,size.Y/2,0))*CFrame.Angles(0,math.rad(yaw or 0),0));return p
end
-- Sixteen ward beds and twelve medical beds, with clear cross aisles.
for i=0,7 do for _,r in {{-248,90},{-167,-90}} do proxy("WardBed",V(r[1],2.1,-61+i*14.5),V(10,2.2,5),"Bed",r[2]) end end
for i=0,5 do for _,z in {-218,-164} do proxy("MedicalBed",V(-237+i*17.8,2.1,z),V(5,2.2,10),"Bed",z==-218 and 0 or 180) end end
for _,z in {-44,-5,34} do proxy("WardIsland",V(-208,4.5,z),V(13,7,5),"LinenIsland") end
for _,x in {-92,-68,-44,-20} do proxy("StorageRow",V(x,5.5,120),V(4,9,44),"StorageRow",90) end
for _,z in {29,65,101} do for _,x in {128,171} do proxy("DiningSet",V(x,2.65,z),V(24,3.3,11),"DiningSet") end end
-- Kitchen boundary: serving windows and a proper full-height 10-stud door.
for _,z in {30,75} do
 part("KitchenWallBase",V(.8,4.5,28),V(203,3.25,z),C(84,99,89))
 part("KitchenWindowHeader",V(.8,5,28),V(203,14.5,z),C(140,139,125))
end
for _,span in {{8,16},{44,61},{89,99},{109,120}} do
 part("KitchenWindowPier",V(.8,16,span[2]-span[1]),V(203,9,(span[1]+span[2])/2),C(140,139,125))
end
part("KitchenEntryHeader",V(.8,5,10),V(203,14.5,104),C(140,139,125))
for _,z in {27,51,75,103} do proxy("KitchenStation",V(242,3,z),V(8,4,18),"KitchenStation",-90) end
proxy("KitchenIsland",V(222,2.8,69),V(7,3.6,32),"PrepIsland")
for _,r in {{-35,220},{20,220},{-35,239},{20,239}} do proxy("WaitingGroup",V(r[1],2.5,r[2]),V(15,3,6),"WaitingGroup") end
proxy("ReceptionDesk",V(-7,3,199),V(40,4,6),"ReceptionDesk")
-- Courtyard is grass and paths, not a paved warehouse with sphere bushes.
for _,p in rooms.Courtyard:GetChildren() do if p.Name~="DrainageWell" then p.Parent=backup end end
for _,p in root:GetChildren() do if p.Name=="Floor_Courtyard" then p.Parent=backup end end
local terrain=workspace.Terrain
local region=Region3int16.new(Vector3int16.new(-22,-2,-22),Vector3int16.new(10,1,10));local saved=terrain:CopyRegion(region);saved.Name="CourtyardTerrainBeforeProduction";saved.Parent=backup
terrain:FillBlock(CFrame.new(-24,-1,-24),V(126,4,126),Enum.Material.Grass)
for _,r in {{-24,-24,12,128},{-24,-24,128,12}} do part("CourtyardConcretePath",V(r[3],.6,r[4]),V(r[1],1.15,r[2]),C(127,128,115)) end
for _,r in {{-64,-59},{13,13}} do proxy("TreeRoot",V(r[1],6,r[2]),V(3,10,3),"Tree") end
for _,r in {{-63,14},{16,-58},{-61,-55},{13,19}} do proxy("ShrubBed",V(r[1],2.4,r[2]),V(15,2.8,7),"ShrubGroup") end
-- A few composed corridor obstacles give cover while retaining wide routes.
for _,r in {{-127,-112,0},{-111,-16,0},{-129,116,0},{78,-96,0},{64,48,0},{5,164,90},{-64,-112,90},{48,88,90}} do proxy("HallObstacle",V(r[1],3,r[2]),V(5,4,12),"HallObstacle",r[3]) end
out:SetAttribute("Ready",true)
