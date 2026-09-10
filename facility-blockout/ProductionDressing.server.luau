-- Shared Blender meshes + native collision, architecture and searchable set dressing.
local root=workspace:WaitForChild("FacilityLayoutReview")
local layout=root:WaitForChild("ProductionLayout");while not layout:GetAttribute("Ready") do task.wait() end
if root:GetAttribute("ProductionDressed") then return end
local rooms=root.RoomInteriors
local K=require(game.ServerScriptService:WaitForChild("FacilityRoomKit"))
local kit=game.ServerStorage:WaitForChild("FacilityProductionTemplates")
local V=Vector3.new;local C=Color3.fromRGB;local P=K.colors;local M=Enum.Material
local function cf(x,y,z,a) return CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(a or 0),0) end
local backup=Instance.new("Folder");backup.Name="Facility_PreProductionDressing";backup.Parent=game.ServerStorage
local function mesh(parent,name,frame,scale)
 local p=kit:WaitForChild(name):Clone();p.Size*=scale or 1;p.PivotOffset=CFrame.new(0,-p.Size.Y/2,0);p:PivotTo(frame);p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.Parent=parent;return p
end
local function collision(parent,size,frame)
 local p=K.part(parent,"SimpleCollision",size,frame,P.dark,nil,true);p.Transparency=1;p.CastShadow=false;return p
end
local function paper(parent,frame,index)
 local p=K.part(parent,"ScatteredPaper",V(.85,.018,1.15),frame,P.paper);local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Top;g.CanvasSize=Vector2.new(170,230);g.Parent=p
 for i=1,7 do local t=Instance.new("Frame");t.BorderSizePixel=0;t.BackgroundColor3=C(94,99,90);t.BackgroundTransparency=.4;t.Size=UDim2.fromScale(i==1 and .65 or .5+(i%3)*.09,.01);t.Position=UDim2.fromScale(.12,.1+i*.08);t.Parent=g end
 return p
end
local function rack(parent,frame,id,item)
 local m=K.model(parent,"PartLoadedStorageBay");m:SetAttribute("BayId",id)
 for _,x in {-5.1,5.1} do for _,z in {-1.65,1.65} do K.part(m,"SteelAnglePost",V(.18,9,.18),frame*CFrame.new(x,4.5,z),P.trim,M.Metal,true) end end
 for j=0,3 do local y=.5+j*2.4
  K.part(m,"FoldedSteelShelf",V(10.5,.17,3.5),frame*CFrame.new(0,y,0),P.metal,M.Metal,true)
  for s=1,3 do
   local x=(s-2)*3.15;local seed=id*13+j*7+s
   if seed%5<3 then
    local h=.85+(seed%3)*.28
    K.part(m,"ArchiveCarton",V(2.35,h,2.65),frame*CFrame.new(x,y+h/2+.1,0),C(119+seed%17,105+seed%9,81),M.Fabric)
    K.part(m,"CartonLid",V(2.43,.12,2.72),frame*CFrame.new(x,y+h+.1,0),C(144,128,95),M.Fabric)
    K.part(m,"ContentsLabel",V(.8,.3,.025),frame*CFrame.new(x,y+h/2+.1,1.34),P.paper)
   else
    local spawn=K.node(m,frame*CFrame.new(x,y+.3,0),"Search","Storage_Bay_"..id.."_"..j.."_"..s,item);item=nil;spawn:SetAttribute("SpawnSurface",true)
   end
  end
 end
 K.rod(m,"RearDiagonalBrace",frame:PointToWorldSpace(V(-5,.7,-1.68)),frame:PointToWorldSpace(V(5,8.6,-1.68)),.06,P.metal)
 return m
end
local function framedPicture(parent,frame,index)
 -- Original graphic institutional archive print, not a photorealistic portrait.
 local m=K.model(parent,"FramedArchivePicture")
 K.part(m,"RecessedPrint",V(4.5,3.3,.12),frame,C(111,106,85),M.SmoothPlastic)
 for _,x in {-2.38,2.38} do K.part(m,"OakFrame",V(.25,3.8,.32),frame*CFrame.new(x,0,-.04),P.wood,M.Wood) end
 for _,y in {-1.78,1.78} do K.part(m,"OakFrame",V(5,.25,.32),frame*CFrame.new(0,y,-.04),P.wood,M.Wood) end
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(450,330);gui.Parent=m.RecessedPrint
 local function rect(x,y,w,h,col) local f=Instance.new("Frame");f.BorderSizePixel=0;f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h);f.BackgroundColor3=col;f.Parent=gui;return f end
 rect(25,25,400,255,C(128,124,107));rect(25,200,400,80,C(82,86,72))
 if index%2==0 then
  rect(105,90,245,140,C(76,78,65));rect(90,83,275,12,C(60,65,56))
  for x=125,320,44 do for y=110,175,45 do rect(x,y,18,28,C(37,47,40)) end end
  rect(203,179,34,51,C(34,40,33))
 else
  for i=0,6 do local x=64+i*49;local f=rect(x,125+(i%2)*5,24,30,C(69,66,55));local u=Instance.new("UICorner");u.CornerRadius=UDim.new(.5,0);u.Parent=f;rect(x-8,153,40,72,C(48+i%3*4,53,46)) end
 end
 local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(0,283);t.Size=UDim2.fromOffset(450,35);t.Text=index%2==0 and "NORTH WING  /  1968" or "STAFF ARCHIVE  /  1971";t.Font=Enum.Font.Garamond;t.TextSize=17;t.TextColor3=C(46,49,40);t.Parent=gui
 return m
end
-- Repair the kitchen partition to exact intervals on every build.
for _,p in layout:GetChildren() do if p:IsA("BasePart") and p.Name:find("Kitchen") then p.Parent=backup end end
local kitchen=K.model(rooms.CafeteriaKitchen,"EnclosedKitchen")
local function wallSegment(a,b,lo,hi)
 K.part(kitchen,"ContinuousPartition",V(.8,hi-lo,b-a),V(203,(lo+hi)/2,(a+b)/2),lo<5.5 and P.lower or P.wall,M.Concrete,true)
end
for _,s in {{8,16},{44,61},{89,99},{109,120}} do wallSegment(s[1],s[2],1,5.3);wallSegment(s[1],s[2],5.3,17) end
for _,z in {30,75} do
 wallSegment(z-14,z+14,1,5.5);wallSegment(z-14,z+14,12,17)
 local g=K.part(kitchen,"WiredServingWindow",V(.16,6.5,27.6),V(203,8.75,z),C(136,159,143),M.Glass,true);g.Transparency=.68
 for _,h in {5.5,12} do K.part(kitchen,"WindowFrame",V(1.15,.18,28.3),V(203,h,z),P.trim,M.Metal) end
 K.part(kitchen,"ServingCounter",V(3,.25,28.5),V(202.5,5.5,z),P.metal,M.Metal,true)
 for _,a in {-14,0,14} do K.part(kitchen,"WindowMullion",V(.9,6.6,.13),V(203,8.75,z+a),P.trim,M.Metal) end
end
wallSegment(99,109,12,17)
local door=K.model(kitchen,"KitchenSwingDoor");door:SetAttribute("ProductionSwingDoor",true)
local hinge=cf(203,1,99,90);door:SetAttribute("ClosedHinge",hinge)
local leaf=K.part(door,"Leaf",V(9.6,10.7,.3),hinge*CFrame.new(-4.8,5.35,0),P.lower,M.Metal,true)
door.PrimaryPart=leaf;door.WorldPivot=hinge
local anchor=K.node(kitchen,cf(201,5,104),"Door","KitchenDoor");anchor:SetAttribute("DoorTarget","KitchenSwingDoor")
K.sign(kitchen,cf(201.8,13,104,90),"KITCHEN / STAFF",9,1)
-- Restore the former stair floor cut with the room's own continuous finish.
for _,r in {{rooms.Residential,-224,M.WoodPlanks,C(93,79,58)},{rooms.CafeteriaKitchen,208,M.Concrete,C(96,104,95)}} do
 K.part(r[1],"MatchedFormerStairFloor",V(16,.06,24),V(r[2],1.045,36),r[4],r[3])
end
-- Graybox is replaced one placement at a time; meshes are shared, not uniquely uploaded.
local index=0
for _,p in layout.GameplayGraybox:GetChildren() do
 index+=1;local asset=p:GetAttribute("Asset");local f=p:GetAttribute("Placement");local m
 if asset=="Bed" then
  local parent=p.Name=="WardBed" and rooms.Residential or rooms.Medical
  m=K.bed(parent,f,"ProductionBed_"..index)
  K.cabinet(parent,f*CFrame.new(4,0,-3.4),2.6,2.9,"wood","Bedside_Production_"..index)
  if index%3==0 then paper(parent,f*CFrame.new(4,3.05,-3.4)*CFrame.Angles(0,.2,0),index) end
 elseif asset=="LinenIsland" then
  m=K.model(rooms.Residential,"LinenPrivacyIsland")
  for _,x in {-3.25,3.25} do K.cabinet(m,f*CFrame.new(x,0,0),6.3,7,"medical","Linen_"..index.."_"..x) end
  K.part(m,"PrivacyBack",V(13,7,.15),f*CFrame.new(0,3.5,-1.35),P.lower,M.Metal,true)
 elseif asset=="StorageRow" then
  m=K.model(rooms.Storage,"StorageRow_"..index)
  for b=0,3 do rack(m,f*CFrame.new(-16.2+b*10.8,0,0),index*4+b,b==1 and "Wire" or nil) end
 elseif asset=="DiningSet" then
  m=K.model(rooms.CafeteriaKitchen,"InstitutionDiningSet");mesh(m,"DiningBenchSet",f)
  collision(m,V(24,.3,5.7),f*CFrame.new(0,3.3,0))
  for _,z in {-4.5,4.5} do collision(m,V(24,.25,1.65),f*CFrame.new(0,1.82,z)) end
  for _,x in {-8.4,8.4} do collision(m,V(.65,3,9),f*CFrame.new(x,1.5,0)) end
  for j=1,3 do local x=-8+j*4;K.part(m,"MealTray",V(2.1,.1,1.5),f*CFrame.new(x,3.52,1.4)*CFrame.Angles(0,j*.13,0),P.metal,M.Metal);K.disc(m,"Plate",f*CFrame.new(x,3.6,1.4),1,.08,P.paper) end
  paper(m,f*CFrame.new(-7,3.53,-1)*CFrame.Angles(0,.3,0),index)
  local h=K.node(m,f*CFrame.new(0,.8,0),"Hide","DiningCover_"..index);h:SetAttribute("HidePosition",(f*CFrame.new(0,.65,0)).Position);h:SetAttribute("ExitPosition",(f*CFrame.new(13,2,0)).Position)
 elseif asset=="KitchenStation" then
  m=K.model(kitchen,"KitchenWorkstation")
  local z=p.Position.Z;local frame=cf(243,1,z,-90)
  if z==103 then
   K.cabinet(m,frame,15,10,"medical","Cold_Storage");K.sign(m,frame*CFrame.new(0,8,1.5),"COLD STORE",6,1)
  else
   K.cabinet(m,frame,16,3.3,"medical","Kitchen_Drawers_"..z,z==75 and "Fuse" or nil)
   K.part(m,"StainlessWorktop",V(16,.2,5),frame*CFrame.new(0,3.5,0),C(144,150,140),M.Metal,true)
   K.part(m,"WashableBacksplash",V(16,2,.1),frame*CFrame.new(0,4.5,-2.48),P.metal,M.Metal)
   if z==27 then
    for _,x in {-4,4} do
     K.part(m,"BasinInterior",V(4,.15,3),frame*CFrame.new(x,3.63,0),P.dark,M.Metal)
     for _,a in {-2,2} do K.part(m,"BasinRim",V(.12,.18,3.2),frame*CFrame.new(x+a,3.67,0),P.metal,M.Metal) end
     for _,a in {-1.55,1.55} do K.part(m,"BasinRim",V(4.1,.18,.12),frame*CFrame.new(x,3.67,a),P.metal,M.Metal) end
     K.rod(m,"TapRiser",frame:PointToWorldSpace(V(x,3.6,-1.9)),frame:PointToWorldSpace(V(x,5,-1.9)),.14,P.metal)
     K.rod(m,"TapSpout",frame:PointToWorldSpace(V(x,5,-1.9)),frame:PointToWorldSpace(V(x,5,-.6)),.14,P.metal)
    end
   elseif z==51 then
    for _,x in {-5,0,5} do for _,a in {-1.2,1.2} do K.disc(m,"CastIronBurner",frame*CFrame.new(x,3.66,a),1.25,.1,P.dark) end end
    K.part(m,"ExtractorCanopy",V(17,1.3,6),frame*CFrame.new(0,9,0),P.metal,M.Metal,true)
    for x=-7,7,1 do K.part(m,"ExtractorLouver",V(.08,.08,4.8),frame*CFrame.new(x,8.3,0),P.dark,M.Metal) end
    for _,x in {-5,0,5} do K.disc(m,"OvenControl",frame*CFrame.new(x,3,2.6)*CFrame.Angles(math.pi/2,0,0),.28,.15,P.dark) end
   else
    K.part(m,"CuttingBoard",V(4,.12,2.8),frame*CFrame.new(-4,3.67,0),P.wood,M.Wood)
    for _,x in {1,3.5,6} do K.disc(m,"StockPot",frame*CFrame.new(x,4.2,0),1.8,1.1,P.metal);K.disc(m,"Lid",frame*CFrame.new(x,4.79,0),1.9,.12,P.metal) end
   end
  end
 elseif asset=="PrepIsland" then
  m=K.model(kitchen,"CentralPrepIsland");K.table(m,f,7,32,true)
  K.part(m,"LowerShelf",V(6.5,.15,30),f*CFrame.new(0,.65,0),P.metal,M.Metal)
  for _,z in {-10,0,10} do K.part(m,"PreparationTray",V(4,.12,3),f*CFrame.new(0,3.52,z),P.metal,M.Metal) end
  K.node(m,f*CFrame.new(0,3.9,0),"Search","Prep_Tray")
 elseif asset=="WaitingGroup" then
  m=K.model(rooms.Reception,"VisitorSeatingGroup")
  for _,x in {-5,0,5} do K.chair(m,f*CFrame.new(x,0,0)*CFrame.Angles(0,p.Position.Z>230 and 0 or math.pi,0)) end
  local tf=f*CFrame.new(0,0,p.Position.Z>230 and -5.5 or 5.5);local t=K.table(m,tf,11,3.8);t:ScaleTo(.7)
  for j=1,3 do K.book(m,tf*CFrame.new(j-2,2.53,0)*CFrame.Angles(0,j*.2,0),1.3,1.8,.1,P.cloth) end
 elseif asset=="ReceptionDesk" then
  m=K.model(rooms.Reception,"ReceptionWorkstation")
  for _,x in {-14,-3,8} do K.cabinet(m,f*CFrame.new(x,0,0),10.8,3.6,"wood","ReceptionDrawer_"..x) end
  K.table(m,f,40,6);K.chair(m,f*CFrame.new(-7,0,-5));K.chair(m,f*CFrame.new(8,0,-5))
  for j=1,7 do paper(m,f*CFrame.new(-12+j*.4,3.49+j*.02,.1)*CFrame.Angles(0,.05*j,0),j) end
 elseif asset=="Tree" then
  m=K.model(rooms.Courtyard,"CourtyardTree");mesh(m,"CourtyardTree",f*CFrame.Angles(0,index,0),1.1)
  collision(m,V(1.6,10,1.6),f*CFrame.new(0,5,0))
 elseif asset=="ShrubGroup" then
  m=K.model(rooms.Courtyard,"LeafyPlantingBed")
  for j=1,3 do mesh(m,"LeafyShrub",f*CFrame.new((j-2)*4.6,0,(j%2)*1.1)*CFrame.Angles(0,j*2+index,0),.8+j*.08) end
 elseif asset=="HallObstacle" then
  m=K.model(rooms,"HallwayMedicalCluster_"..index);m:SetAttribute("PowerSector",p.Position.X<0 and 1 or 3)
  mesh(m,"MedicalGurney",f*CFrame.Angles(0,.12,0));collision(m,V(4.6,2.8,9),f*CFrame.new(0,1.6,0))
  K.tray(m,f*CFrame.new(1.5,0,7)*CFrame.Angles(0,.25,0),"HallTray_"..index,index%3==0 and "Battery" or nil)
  for j=1,5 do paper(m,f*CFrame.new(-2+j*.8,.1,5+j*.45)*CFrame.Angles(0,j*1.3,0),j) end
  local h=K.node(m,f*CFrame.new(0,.8,0),"Hide","TrolleyCover_"..index);h:SetAttribute("HidePosition",(f*CFrame.new(0,.65,0)).Position);h:SetAttribute("ExitPosition",(f*CFrame.new(4,2,0)).Position)
 end
 if m then m:SetAttribute("ProductionPlacement",true) end
 p.Parent=backup
end
-- Restore the actual phone and its progression node from the previous desk, not a fake placeholder.
for _,m in game.ServerStorage.Facility_PreProductionLayout:GetChildren() do if m.Name=="ReceptionTelephone" then m.Parent=rooms.Reception end end
K.cabinet(rooms.Reception,cf(-50,1,194,90),6,7,"wood","Reception_Supplies","RadioPart")
K.cabinet(rooms.Storage,cf(-12,1,145,180),7,8,"medical","Locked_Tool_Cabinet","Screwdriver")
K.node(rooms.Storage,cf(-91,4,99),"Search","Maintenance_Cutters","Cutters")
for _,d in rooms.Storage:GetChildren() do if d.Name=="LockedStorageDoor" then
 for _,s in {-1,1} do K.node(rooms.Storage,d.CFrame*CFrame.new(0,0,s),"Route","StorageLock") end
end end
-- Wall-mounted narrative details, with no intrusion into the travel lane.
for i,r in {{-135,-100,90},{-135,-36,90},{87,-52,-90},{87,76,-90},{-52,-151,180},{8,-167,0},{110,183,180},{-48,247,0}} do framedPicture(rooms,cf(r[1],9,r[2],r[3]),i) end
for _,r in {{-43,-33,0},{-5,-15,180},{-33,-45,-90},{-15,-3,90}} do
 K.bench(rooms.Courtyard,cf(r[1],1.45,r[2],r[3]));K.part(rooms.Courtyard,"BenchConcretePad",V(11,.4,5),cf(r[1],1.3,r[2],r[3]),C(127,128,115),M.Concrete,true)
end
for _,r in {{-65,-5},{15,-42}} do
 K.bench(rooms.Courtyard,cf(r[1],1,r[2]));K.part(rooms.Courtyard,"BenchConcretePad",V(12,.4,6),V(r[1],1,r[2]),C(127,128,115),M.Concrete,true)
end
-- Replace thin segmented chain strokes with individually addressable forged links.
local front=rooms.EscapeRoutes.FrontExit
for _,p in front:GetChildren() do if p.Name=="SecurityChain" then p.Parent=backup end end
for i=0,13 do
 local x=-5.2+i*.8;local z=-.85;local y=5.9-.45*math.sin(i/13*math.pi)
 local p=mesh(front,"ChainLink",cf(-8+x,1+y,248+z)*CFrame.Angles(math.pi/2+(i%2)*math.pi/2,0,0),1)
 p.Name="SecurityChain";p:SetAttribute("LinkIndex",i);p:SetAttribute("Breakable",true)
end
local lock=K.part(front,"SecurityChain",V(.8,1,.4),V(-8,6,246.7),C(115,94,54),M.Metal);lock:SetAttribute("Breakable",true)
K.rod(front,"SecurityChain",V(-8.27,6.5,246.7),V(-8.27,6.85,246.7),.15,P.metal);K.rod(front,"SecurityChain",V(-7.73,6.5,246.7),V(-7.73,6.85,246.7),.15,P.metal);K.rod(front,"SecurityChain",V(-8.27,6.85,246.7),V(-7.73,6.85,246.7),.15,P.metal)
-- Actual vent mouth: louvres, screws, a steel throat and an inner bend.
local admin=rooms.Administration
for _,p in admin:GetDescendants() do if p:IsA("BasePart") and p.Name=="StaffVentPanel" then p.Parent=backup end end
local v=mesh(admin,"VentGrille",cf(20.3,1.05,-230,90));v.Name="StaffVentPanel"
for _,z in {-233.55,-226.45} do K.part(admin,"VentDuctSide",V(6,3.5,.15),V(24,2.75,z),P.metal,M.Metal,true) end
for _,y in {1.05,4.5} do K.part(admin,"VentDuctTopBottom",V(6,.15,7.2),V(24,y,-230),P.metal,M.Metal,true) end
K.part(admin,"DuctRecess",V(.15,3.4,7),V(26.8,2.75,-230),P.dark,M.Metal,true)
-- Shadow-casting lights in the relocated stairs, on the same sabotage circuit.
for _,shaft in layout:GetChildren() do if shaft:IsA("Model") and shaft.Name:find("ServiceStair") then
 shaft:SetAttribute("PowerSector",6);local x=shaft:GetAttribute("Landing").X
 for i,z in {16,43,70,97,114} do local y=z<24 and 14.5 or math.max(-25,14.5-(z-24)*.5)
  K.lamp(shaft,V(x,y,z),6,i)
 end
 K.sign(shaft,cf(x,10,9),"BASEMENT / SERVICE STAIR",10,1)
end end
local preview=root:FindFirstChild("ProductionAssetPreview");if preview then preview.Parent=backup end
for _,p in rooms:GetDescendants() do if p:IsA("BasePart") and p.Name=="Diffuser" and not p:FindFirstChild("CeilingBounce") then
 local l=Instance.new("PointLight");l.Name="CeilingBounce";l.Range=23;l.Brightness=.7;l.Color=C(196,204,182);l.Shadows=true;l.Parent=p
end end
root:SetAttribute("ProductionDressed",true)
