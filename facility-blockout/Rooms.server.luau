-- Complete map dressing and objective geography. Leaves the approved library and washrooms intact.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:WaitForChild("Hallways"):GetAttribute("Ready") do task.wait() end
if root:FindFirstChild("RoomInteriors") then return end
local K=require(game.ServerScriptService:WaitForChild("FacilityRoomKit"));local V=Vector3.new;local C=Color3.fromRGB;local P=K.colors
local out=K.model(root,"RoomInteriors")
local backup=Instance.new("Folder");backup.Name="Facility_PreCompletedRooms";backup.Parent=game.ServerStorage
local obsolete={DeskIsland=true,BedScreen=true,CrateBank=true,Partition=true,PartitionReturn=true,WindowLeft=true,WindowRight=true,VaultWindowSill=true,WindowHeader=true,MachineBlock=true,PumpBlock=true,PlanterBlock=true}
for _,p in root:GetChildren() do if obsolete[p.Name] or p:IsA("BasePart") and p.Name:find("Slide") and p.Position.X<0 then p.Parent=backup end end
for _,p in root.Basement:GetChildren() do if obsolete[p.Name] then p.Parent=backup end end
-- The finished room ceiling supersedes the temporary stair lid (no coplanar faces).
for _,p in root.Hallways.Finishes:GetChildren() do if p.Name=="StairwellTop" then p.Parent=backup end end
local function cf(x,y,z,a) return CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(a or 0),0) end
local function box(m,n,x,y,z,w,h,d,c,mat,col) return K.part(m,n,V(w,h,d),V(x,y,z),c,mat,col) end
local rooms={
 {"Medical",-248,-232,-136,-152,1,1},{"Administration",-72,-248,40,-168,1,2},
 {"Residential",-264,-72,-152,56,1,1},{"CafeteriaKitchen",104,8,248,120,1,3},
 {"Storage",-104,88,-8,152,1,4},{"Reception",-56,184,40,248,1,2},
 {"Security",88,184,184,248,1,2},{"PumpRoom",-60,144,92,232,-39,5},
 {"GeneratorHall",112,144,240,232,-39,6},{"Electrical",-56,88,-8,124,-39,6},
 {"Records",24,88,72,124,-39,4}}
local models={};local count=0
local function stairCut(x,z) return (math.abs(x+224)<8.01 or math.abs(x-208)<8.01) and z>=24 and z<=48 end
for _,r in rooms do
 local name,x1,z1,x2,z2,f,sector=table.unpack(r);local m=K.model(out,name);models[name]=m;m:SetAttribute("PowerSector",sector)
 -- Clip room surfaces to stair aperture, with continuous adjoining slabs.
 local stair=name=="Residential" and -224 or name=="CafeteriaKitchen" and 208 or nil
 local slices=stair and {{x1,z1,stair-8,z2},{stair+8,z1,x2,z2},{stair-8,z1,stair+8,24},{stair-8,48,stair+8,z2}} or {{x1,z1,x2,z2}}
 for _,a in slices do if a[3]>a[1] and a[4]>a[2] then box(m,"ContinuousRoomFloor",(a[1]+a[3])/2,f+.045,(a[2]+a[4])/2,a[3]-a[1],.06,a[4]-a[2],name=="Residential" and C(93,79,58) or C(96,104,95),name=="Residential" and Enum.Material.WoodPlanks or Enum.Material.Concrete,false) end end
 box(m,"SolidCeiling",(x1+x2)/2,f+15.55,(z1+z2)/2,x2-x1,.5,z2-z1,C(81,86,77),Enum.Material.Concrete,true)
 -- Only skin existing wall faces; every actual doorway remains an opening.
 for _,wall in root.CleanArchitecture:GetChildren() do if wall:IsA("BasePart") then
  local lo,hi=wall.Position-wall.Size/2,wall.Position+wall.Size/2
  if lo.Y<f+3 and hi.Y>f+2 then
   for _,a in {{"X",hi.X,1,lo.Z,hi.Z},{"X",lo.X,-1,lo.Z,hi.Z},{"Z",hi.Z,1,lo.X,hi.X},{"Z",lo.Z,-1,lo.X,hi.X}} do
    local axis,fix,sign,low,high=table.unpack(a);local inside=axis=="X" and fix+sign*.1>x1 and fix+sign*.1<x2 or axis=="Z" and fix+sign*.1>z1 and fix+sign*.1<z2
    local start=math.max(low,axis=="X" and z1 or x1);local finish=math.min(high,axis=="X" and z2 or x2)
    if inside and finish-start>.5 then
     local pos=V(axis=="X" and fix+sign*.04 or (start+finish)/2,f,axis=="Z" and fix+sign*.04 or (start+finish)/2)
     local frame=CFrame.new(pos)*CFrame.Angles(0,axis=="X" and math.pi/2 or 0,0)
     K.part(m,"LowerWallPaint",V(finish-start,4.3,.055),frame*CFrame.new(0,2.15,0),P.lower)
     K.part(m,"UpperPlaster",V(finish-start,11,.055),frame*CFrame.new(0,9.8,0),P.wall,Enum.Material.Concrete)
     for _,y in {.25,4.35,15.1} do K.part(m,"WallMolding",V(finish-start,y==.25 and .4 or .13,.18),frame*CFrame.new(0,y,0),P.trim) end
    end
   end
  end
 end end
 local nx,nz=math.max(1,math.ceil((x2-x1)/29)),math.max(1,math.ceil((z2-z1)/29))
 for i=1,nx do for j=1,nz do local x,z=x1+(x2-x1)*(i-.5)/nx,z1+(z2-z1)*(j-.5)/nz
  if not stairCut(x,z) then count+=1;K.lamp(m,V(x,f+14.8,z),sector,count) end
 end end
 K.sign(m,cf((x1+x2)/2,f+10.5,z1+.7),name:gsub("(%l)(%u)","%1 %2"):upper(),8,1.3)
end
box(out,"RestoredSouthStairWall",-224,8.65,56,16.8,15.3,1,P.wall,Enum.Material.Concrete,true)
-- Medical: two bed bays, examination lane, medicine storage and clean trays.
do local m=models.Medical
 for i=0,3 do local x=-234+i*24
  K.bed(m,cf(x,1,-217),"Medical_Bed_"..i);K.cabinet(m,cf(x+6,1,-221),3,3.1,"medical","Bedside_"..i)
  if i<3 then box(m,"PrivacyScreen",x+12,5.4,-213,.25,8.4,15,P.cloth,Enum.Material.Fabric,true);K.rod(m,"ScreenRail",V(x+12,9.7,-220),V(x+12,9.7,-206),.15,P.metal) end
 end
 K.cabinet(m,cf(-241,1,-177,90),7,8,"medical","Medicine_Cabinet","Fuse")
 K.cabinet(m,cf(-231,1,-155,180),6,7,"medical","Bandage_Cabinet")
 K.tray(m,cf(-208,1,-174,12),"Examination_Tray","Battery")
 K.table(m,cf(-184,1,-172),12,5,true);K.tray(m,cf(-163,1,-160,180),"Sterile_Tray")
 K.sign(m,cf(-208,9,-231),"WARD A / EXAMINATION",9,1.3)
end
-- Residential: furniture in small offset bays, with broad central chase circulation.
do local m=models.Residential
 for i=0,3 do local z=-58+i*25
  K.bed(m,cf(-249,1,z,90),"Dorm_Bed_W"..i);K.cabinet(m,cf(-260,1,z+8,90),3.6,3.2,"wood","Bedside_W"..i)
  K.bed(m,cf(-166,1,z,-90),"Dorm_Bed_E"..i);K.cabinet(m,cf(-156,1,z+8,-90),3.6,3.2,"wood","Bedside_E"..i)
 end
 for _,z in {-46,-6} do box(m,"DormitoryScreen",-204,5.4,z,17,8.8,.4,P.lower,nil,true);K.sign(m,cf(-204,8.6,z+.3),z==-46 and "RESIDENTS 01–04" or "RESIDENTS 05–08",6,.8) end
 K.cabinet(m,cf(-195,1,53,180),7,8,"wood","Ward_Linen")
 K.table(m,cf(-193,1,34),10,5);K.chair(m,cf(-193,1,39,180));K.book(m,cf(-191,4.52,34,23),1.7,2.1,.23,P.cloth)
end
-- Administration and staff records: coherent desk groups, not scattered props.
do local m=models.Administration
 for i=0,2 do local x=-55+i*35
  K.table(m,cf(x,1,-215),13,6);K.chair(m,cf(x,1,-209,180));K.cabinet(m,cf(x+5,1,-240),5,7,"wood","Office_Files_"..i,i==1 and "StorageKey" or nil)
  K.place(m,game.ServerStorage.CoherentKitTemplates.Terminal,cf(x-3,4.46,-216,180));K.place(m,game.ServerStorage.CoherentKitTemplates.Keyboard,cf(x-3,4.46,-213.8))
  for j=0,2 do K.book(m,cf(x+3,4.57+j*.24,-215,j*9),1.7,2.3,.2,P.cloth) end
 end
 for _,x in {-55,-30,5} do K.shelf(m,cf(x,1,-172,180),10,8,"Personnel_Records_"..x) end
 box(m,"StaffOfficePartition",21,8.5,-241,.4,15,14,P.lower,nil,true)
 box(m,"StaffOfficePartition",21,8.5,-222,.4,15,8,P.lower,nil,true)
 box(m,"StaffVentHeader",21,10,-230,.4,12,8,P.lower,nil,true)
 box(m,"StaffOfficeReturn",30.5,8.5,-218,19,15,.4,P.lower,nil,true)
 K.cabinet(m,cf(35,1,-240,-90),5,8,"medical","Staff_Badge_Cabinet","Badge")
 local vent=box(m,"StaffVentPanel",21,2.55,-230,.2,3,7,P.trim,nil,true);K.node(m,cf(20,2.4,-230),"Route","StaffVent")
 -- The maintenance vent bypasses the partition through a short, explicitly bounded crawl duct.
 local duct=K.model(m,"StaffVentDuct");for _,y in {1.1,4.2} do box(duct,"DuctSkin",25,y,-230,8,.15,7,P.metal,Enum.Material.Metal,true) end
 box(duct,"DuctRear",25,2.65,-233.5,8,3.1,.15,P.metal,Enum.Material.Metal,true)
 K.node(m,cf(30,2.5,-230),"Route","StaffVentReturn")
end
-- Cafeteria occupies the service hall; a real kitchen counter separates the prep lane.
do local m=models.CafeteriaKitchen
 for _,z in {28,65,98} do for _,x in {127,171} do
  K.table(m,cf(x,1,z),15,6)
  for _,dx in {-4,4} do K.chair(m,cf(x+dx,1,z+5,180));K.chair(m,cf(x+dx,1,z-5,0)) end
  K.disc(m,"EnamelPlate",cf(x-3,4.48,z),1.15,.07,P.paper);K.disc(m,"EnamelCup",cf(x+4,4.7,z),.55,.5,P.paper)
 end end
 -- East stair head stays clear; the kitchen begins behind its enclosure.
 for _,z in {62,78,94,110} do K.cabinet(m,cf(244,1,z,-90),12,3.2,"medical","Kitchen_Drawers_"..z,z==94 and "Fuse" or nil);K.table(m,cf(231,1,z),6,11,true) end
 for _,z in {67,82,97} do K.place(m,game.ServerStorage.FacilityRoomTemplates.Stove,cf(238,1,z,-90),"EnamelKitchenRange") end
 box(m,"ExtractionCanopy",238,9.5,83,7,1.4,38,P.metal,Enum.Material.Metal,true)
 for i=0,8 do box(m,"ExtractorBaffle",238,8.75,67+i*4,6,.06,.12,P.trim) end
 K.cabinet(m,cf(217,1,117,180),7,9,"medical","Cold_Storage")
 K.shelf(m,cf(196,1,117,180),8,8,"Dry_Pantry","Wire")
 K.table(m,cf(217,1,86),5,20,true);K.node(m,cf(217,4.7,80),"Search","Prep_Tray")
 K.sign(m,cf(231,11,54),"KITCHEN / STAFF ONLY",9,1.4)
end
-- Storage has clear cross aisles and genuinely searchable racks.
do local m=models.Storage
 for row=0,1 do for i=0,3 do K.shelf(m,cf(-94+i*22,1,100+row*34,row==0 and 0 or 180),12,9,"Storage_Rack_"..row.."_"..i,row==1 and i==1 and "Cutters" or nil) end end
 K.cabinet(m,cf(-12,1,116,-90),8,8,"medical","Locked_Tool_Cabinet","Screwdriver")
 -- Recover real 12-stud apertures from the authoritative lower wall intervals.
 for _,edge in {{"Z",88,-104,-8},{"Z",152,-104,-8},{"X",-104,88,152},{"X",-8,88,152}} do
  local axis,fixed,start,finish=table.unpack(edge);local segments={}
  for _,wall in root.CleanArchitecture:GetChildren() do local a,b=wall.Position-wall.Size/2,wall.Position+wall.Size/2
   local hit=axis=="Z" and a.Z<fixed+.6 and b.Z>fixed-.6 or axis=="X" and a.X<fixed+.6 and b.X>fixed-.6
   if hit and a.Y<4 and b.Y>3 then table.insert(segments,{math.max(start,axis=="Z" and a.X or a.Z),math.min(finish,axis=="Z" and b.X or b.Z)}) end
  end
  table.sort(segments,function(a,b)return a[1]<b[1]end);local cursor=start
  for _,seg in segments do if seg[2]>seg[1] then
   if seg[1]-cursor>9 and seg[1]-cursor<14 then
    local mid=(cursor+seg[1])/2;local frame=axis=="Z" and cf(mid,1,fixed) or cf(fixed,1,mid,90)
    local leaf=K.part(m,"LockedStorageDoor",V(seg[1]-cursor-.2,10.8,.35),frame*CFrame.new(0,5.5,0),P.lower,Enum.Material.Metal,true)
    K.node(m,frame*CFrame.new(0,5,-.7),"Route","StorageLock");K.node(m,frame*CFrame.new(0,5,.7),"Route","StorageLock")
   end
   cursor=math.max(cursor,seg[2])
  end end
 end
 K.sign(m,cf(-60,9,145),"STORES / AUTHORIZED STAFF",10,1.5)
end
-- Reception desk, a restrained waiting area and a physical communications objective.
do local m=models.Reception
 for _,x in {-24,-12,0,12} do K.cabinet(m,cf(x,1,199,180),11.8,3.6,"wood","Reception_Drawer_"..x) end
 K.table(m,cf(-6,1,198),43,5);K.chair(m,cf(-10,1,193))
 for _,x in {-44,29} do for _,z in {213,225} do K.chair(m,cf(x,1,z,x<0 and 90 or -90)) end end
 K.table(m,cf(-39,1,238),10,4);K.book(m,cf(-40,4.5,238,14),2,2.5,.15)
 local phone=K.model(m,"ReceptionTelephone");local b=K.part(phone,"SlopedPhoneBase",V(2.4,.5,1.7),cf(5,4.7,198)*CFrame.Angles(math.rad(8),0,0),P.dark)
 for _,x in {4.1,5.9} do K.disc(phone,"ReceiverEarpiece",cf(x,5.2,197.6),.65,.4,P.dark) end
 K.rod(phone,"Receiver",V(4.1,5.37,197.6),V(5.9,5.37,197.6),.24,P.dark)
 for i=0,2 do for j=0,2 do box(phone,"DialKey",4.65+i*.33,5.01,198+j*.24,.21,.06,.16,P.paper) end end
 for i=0,15 do K.disc(phone,"CoiledCord",cf(6.5,4.63,197.3+i*.13),.2,.05,P.dark) end
 K.node(phone,cf(5,5.5,198),"Route","EmergencyPhone");K.sign(m,cf(3,8,185),"RECEPTION / VISITOR CONTROL",14,1.5)
 K.cabinet(m,cf(-50,1,192,90),6,7,"wood","Reception_Supplies","RadioPart")
end
do local m=models.Security
 K.table(m,cf(134,1,202),32,6);for _,x in {124,136,148} do K.place(m,game.ServerStorage.CoherentKitTemplates.Terminal,cf(x,4.47,201,180));K.chair(m,cf(x,1,208,180)) end
 K.cabinet(m,cf(179,1,225,-90),8,8,"medical","Security_Equipment","Fuse")
 K.shelf(m,cf(113,1,244,180),15,8,"Incident_Archive")
 K.node(m,cf(134,5,199),"Route","CommunicationsPanel")
 K.sign(m,cf(137,9,185),"SECURITY / COMMUNICATIONS",13,1.5)
 -- Four staff lockers only, grouped where staff belongings belong.
 for i=0,3 do K.cabinet(m,cf(94,1,211+i*8,90),3.6,8,"medical","Staff_Locker_"..i) end
end
-- Six visually distinct numbered diesel sets, with repair panels and generous loop lanes.
local sectorNames={"MEDICAL / RESIDENTIAL","ADMIN / RECEPTION / SECURITY","CAFETERIA / LIBRARY","STORAGE / RECORDS","WASHROOMS / PUMPS","BASEMENT / SERVICE"}
do local m=models.GeneratorHall
 for i=1,6 do local x=({133,176,219})[(i-1)%3+1];local z=i<=3 and 165 or 210;local f=-39
  local g=K.model(m,"Generator_"..i);g:SetAttribute("GeneratorId",i);g:SetAttribute("Powered",true)
  box(g,"ConcreteEquipmentPad",x,f+.2,z,17,.4,11,C(98,98,88),Enum.Material.Concrete,true)
  box(g,"SteelSkid",x,f+.6,z,14,.35,8,P.dark,Enum.Material.Metal,true)
  box(g,"DieselEnclosure",x,f+3.2,z,12,4.8,6,C(69,83,68),Enum.Material.Metal,true)
  box(g,"RaisedAccessPanel",x-2,f+3.1,z+3.08,5,3.7,.1,C(80,93,78),Enum.Material.Metal)
  for n=0,10 do box(g,"VentLouver",x+3.5,f+1.8+n*.25,z+3.13,3,.075,.15,P.dark) end
  for _,dx in {-5.2,.6} do for _,y in {f+1.7,f+4.6} do K.disc(g,"PanelBolt",cf(x+dx,y,z+3.17,90)*CFrame.Angles(math.pi/2,0,0),.12,.07,P.metal) end end
  K.rod(g,"ExhaustRiser",V(x-4,f+5.6,z-1),V(x-4,f+11.4,z-1),.6,P.dark)
  K.rod(g,"ExhaustElbow",V(x-4,f+11.4,z-1),V(x-4,f+11.4,z-5),.6,P.dark)
  K.rod(g,"Silencer",V(x-4,f+7,z-1),V(x-4,f+9,z-1),1.3,P.metal)
  box(g,"ControlPanel",x-2,f+4,z+3.25,2.9,2.2,.25,P.trim,Enum.Material.Metal)
  for _,dx in {-2.7,-1.4} do local gauge=K.part(g,"AnalogGauge",V(.55,.55,.08),cf(x+dx,f+4.3,z+3.42),P.paper);local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=gauge;box(g,"GaugeNeedle",x+dx,f+4.3,z+3.48,.025,.25,.02,P.dark) end
  local status=box(g,"StatusLamp",x-2,f+3.4,z+3.48,.3,.3,.08,C(111,164,97),Enum.Material.Neon);status:SetAttribute("GeneratorStatus",i)
  K.sign(g,cf(x,f+6.6,z+3.1),"G0"..i.."  /  "..sectorNames[i],14,1)
  local node=K.node(g,cf(x-2,f+3.8,z+4.2),"Generator","Generator_"..i);node:SetAttribute("GeneratorId",i)
  if i==1 or i==3 or i==5 then
   for _,dx in {-10,10} do K.fence(m,cf(x+dx,f,z,90),19,10,false) end
   K.fence(m,cf(x,f,z-9.5),20,10,false)
   -- Front leaves a full-height 9-stud entry, plus a distinct low rear-service passage.
   K.fence(m,cf(x-7.2,f,z+9.5),5.5,10,false);K.fence(m,cf(x+7.2,f,z+9.5),5.5,10,true)
  end
 end
 K.table(m,cf(119,-39,188,90),12,5,true);K.node(m,cf(121,-35,188),"Search","Generator_Toolbench","Fuse")
 K.cabinet(m,cf(237,-39,187,-90),9,8,"medical","Generator_Spares")
end
-- Pump room: rounded vessels, manifolds and low bypass fence openings.
do local m=models.PumpRoom
 for i,r in {{-29,170},{50,205},{46,166}} do local x,z=r[1],r[2]
  local tank=K.disc(m,"PressureVessel",cf(x,-34,z),12,9,C(74,92,88));tank.CanCollide=true;tank.CastShadow=true
  for _,y in {-37,-31} do K.disc(m,"TankBand",cf(x,y,z),12.2,.22,P.metal) end
  K.rod(m,"PumpOutlet",V(x,-34,z),V(x+11,-34,z),1.2,P.metal)
  box(m,"MotorBlock",x+13,-36,z,5,4,4,P.lower,Enum.Material.Metal,true)
  for n=0,5 do box(m,"MotorCoolingFin",x+13,-36,z-1.8+n*.7,5.2,4.2,.08,P.trim) end
  K.disc(m,"ValveWheel",cf(x+8,-32.4,z),2,.12,P.wood)
 end
 K.fence(m,cf(0,-39,191,90),25,9,true)
 K.cabinet(m,cf(87,-39,218,-90),7,8,"medical","Pump_Tools","Valve")
 K.table(m,cf(-48,-39,216,90),12,5,true);K.node(m,cf(-46,-35,216),"Route","DrainPump")
 K.sign(m,cf(4,-28,145),"PUMP CONTROL / DRAINAGE",12,1.5)
end
do local m=models.Electrical
 for _,x in {-48,-37,-26,-15} do K.cabinet(m,cf(x,-39,92),8,10,"medical","Switchgear_"..x) end
 K.table(m,cf(-44,-39,111,90),10,5,true);K.node(m,cf(-41,-35,111),"Search","Electrical_Bench","Fuse")
end
do local m=models.Records for _,x in {32,48,64} do K.shelf(m,cf(x,-39,92),10,9,"Basement_Records_"..x,x==48 and "RadioPart" or nil) end end
-- A courtyard with a well, planting beds and spaced benches, not a maze of lockers.
do local m=K.model(out,"Courtyard");m:SetAttribute("PowerSector",3)
 box(m,"CourtyardPaving",-24,1.06,-24,127,.08,127,C(97,103,91),Enum.Material.Concrete)
 for _,r in {{-62,-57,24,10},{15,14,12,25},{-57,17,20,12}} do
  box(m,"RaisedPlanter",r[1],2,r[2],r[3],2,r[4],C(91,89,73),Enum.Material.Brick,true)
  box(m,"PlantingSoil",r[1],3.03,r[2],r[3]-1,.08,r[4]-1,C(51,55,41),Enum.Material.Ground)
  for i=-2,2 do local p=K.part(m,"LowShrub",V(4,2.3,4),cf(r[1]+i*2.6,3.8,r[2]),C(54+i*2,72,48),Enum.Material.Grass);p.Shape=Enum.PartType.Ball end
 end
 local well=K.model(m,"DrainageWell");for i=0,15 do local a=i*math.pi/8;K.part(well,"StoneCoping",V(2,2.5,1.2),cf(-23+5*math.sin(a),2.25,-25+5*math.cos(a),i*22.5),C(115,112,93),Enum.Material.Slate,true) end
 local grate=K.disc(well,"WellGrate",cf(-23,3.55,-25),9,.16,P.trim);grate.CanCollide=true
 K.node(well,cf(-23,4,-21),"Route","WellGrate")
 for _,r in {{-72,-21,90},{15,-55,0},{-10,28,180}} do K.bench(m,cf(r[1],1,r[2],r[3])) end
 for i,r in {{-76,-76},{28,-76},{28,28},{-76,28}} do
  K.rod(m,"CourtyardLightPost",V(r[1],1,r[2]),V(r[1],12.8,r[2]),.25,P.trim)
  K.lamp(m,V(r[1],13,r[2]),3,i)
 end
end
-- Bathroom dead space gains purposeful linen storage without joining the two rooms.
do local m=K.model(out,"BathroomUtilityDetails")
 K.cabinet(m,cf(-184,-39,185,180),8,7,"medical","Mens_Linen")
 K.cabinet(m,cf(-174,-39,191),7,7,"medical","Womens_Linen")
 K.tray(m,cf(-137,-39,169),"Washroom_Supply_Tray")
 local cover=K.disc(m,"MaintenanceManhole",cf(-161,-38.83,214),6,.2,P.dark);cover.CanCollide=true
 for _,x in {-162.2,-159.8} do box(m,"ManholeGrip",x,-38.67,214,.7,.08,.12,P.metal) end
 K.node(m,cf(-161,-38,214),"Route","BathroomManhole")
end
-- Cut exterior door apertures in owned architecture only, preserving upper headers.
local function cutDoor(x,z,width,axis)
 local affected={};for _,p in root.CleanArchitecture:GetChildren() do if p:IsA("BasePart") then
  local a,b=p.Position-p.Size/2,p.Position+p.Size/2
  local hit=axis=="Z" and a.Z<z+.8 and b.Z>z-.8 and a.X<x+width/2 and b.X>x-width/2 or axis=="X" and a.X<x+.8 and b.X>x-.8 and a.Z<z+width/2 and b.Z>z-width/2
  if hit and a.Y<12 and b.Y>1 then table.insert(affected,p) end
 end end
 for _,p in affected do local a,b=p.Position-p.Size/2,p.Position+p.Size/2;local low=axis=="Z" and a.X or a.Z;local high=axis=="Z" and b.X or b.Z;local c=axis=="Z" and x or z
  for _,range in {{low,math.max(low,c-width/2)},{math.min(high,c+width/2),high}} do if range[2]-range[1]>.01 then local q=p:Clone();q.Size=axis=="Z" and V(range[2]-range[1],p.Size.Y,p.Size.Z) or V(p.Size.X,p.Size.Y,range[2]-range[1]);q.Position=axis=="Z" and V((range[1]+range[2])/2,p.Position.Y,p.Position.Z) or V(p.Position.X,p.Position.Y,(range[1]+range[2])/2);q.Parent=p.Parent end end
  p.Parent=backup
 end
 -- Room finish strips crossing the new aperture must be split as well.
 for _,p in out:GetDescendants() do if p:IsA("BasePart") and (p.Name=="LowerWallPaint" or p.Name=="UpperPlaster" or p.Name=="WallMolding") then
  local pos=p.Position;local near=axis=="Z" and math.abs(pos.Z-z)<1 or axis=="X" and math.abs(pos.X-x)<1
  if near then local a=p.CFrame:PointToObjectSpace(V(x,pos.Y,z));if math.abs(a.X)<p.Size.X/2+width/2 then
   local old=p.Size.X;for _,seg in {{-old/2,math.max(-old/2,a.X-width/2)},{math.min(old/2,a.X+width/2),old/2}} do if seg[2]>seg[1] then local q=p:Clone();q.Size=V(seg[2]-seg[1],p.Size.Y,p.Size.Z);q.CFrame=p.CFrame*CFrame.new((seg[1]+seg[2])/2,0,0);q.Parent=p.Parent end end;p.Parent=backup
  end end
 end end
end
local exits=K.model(out,"EscapeRoutes")
cutDoor(-8,248,12,"Z");cutDoor(184,229,10,"X")
local function exitGate(id,x,z,yaw,w)
 local m=K.model(exits,id);local frame=cf(x,1,z,yaw)
 for _,dx in {-w/2,w/2} do K.part(m,"DoorJamb",V(.3,11,.45),frame*CFrame.new(dx,5.5,0),P.trim,Enum.Material.Metal,true) end
 K.part(m,"DoorHeader",V(w+.3,.4,.45),frame*CFrame.new(0,11,0),P.trim,Enum.Material.Metal,true)
 local leaf=K.part(m,"ExitLeaf",V(w-.35,10.6,.35),frame*CFrame.new(0,5.4,0),P.lower,Enum.Material.Metal,true);leaf:SetAttribute("ExitId",id)
 K.part(m,"PushBar",V(w-2,.15,.25),frame*CFrame.new(0,4.7,-.3),P.metal,Enum.Material.Metal)
 K.node(m,frame*CFrame.new(0,5,-1),"Route",id);K.sign(m,frame*CFrame.new(0,12,0),id=="FrontExit" and "FRONT ENTRANCE" or "STAFF EMERGENCY EXIT",w,1.1)
 return m,frame
end
local front,f=exitGate("FrontExit",-8,248,0,12)
for i=0,22 do local x=-5+i*.45;local link=f*CFrame.new(x,5.5+math.sin(i*.3)*.18,-.4)*CFrame.Angles(i%2==0 and 0 or math.pi/2,0,0)
 for j=0,11 do local a,b=j*math.pi/6,(j+1)*math.pi/6;K.rod(front,"SecurityChain",link:PointToWorldSpace(V(math.cos(a)*.34,math.sin(a)*.2,0)),link:PointToWorldSpace(V(math.cos(b)*.34,math.sin(b)*.2,0)),.075,P.metal) end
end
exitGate("StaffExit",184,229,90,10)
box(exits,"FrontApproach",-8,.5,270,36,1,44,C(74,81,75),Enum.Material.Concrete,true)
box(exits,"StaffExitLanding",198,.5,229,28,1,22,C(74,81,75),Enum.Material.Concrete,true)
-- Clearly marked underground escape destinations keep hatch transitions within a physical route.
for i,r in {{"MaintenanceTunnel",-164},{"WellDrain",-24}} do
 local m=K.model(exits,r[1]);local x=r[2];box(m,"TunnelFloor",x,-51.5,276,18,1,52,P.dark,Enum.Material.Concrete,true)
 for _,dx in {-9,9} do box(m,"TunnelWall",x+dx,-46,276,1,11,52,P.lower,Enum.Material.Concrete,true) end
 box(m,"TunnelRoof",x,-40.5,276,19,1,52,P.dark,Enum.Material.Concrete,true)
 K.lamp(m,V(x,-41.5,270),5,1);K.lamp(m,V(x,-41.5,292),5,1)
 local hatch=K.node(m,cf(x,-48,298),"Route",r[1].."Exit");K.sign(m,cf(x,-44,298),"DRAINAGE OUTFALL",10,1.4)
end
out:SetAttribute("RoomCount",#rooms+2);out:SetAttribute("Ready",true)
for _,name in {"Electrical Switchgear","Records Cage"} do local d=root.Basement:FindFirstChild(name);if d then d:SetAttribute("Locked",false);for _,p in d:GetDescendants() do if p:IsA("ProximityPrompt") then p.ActionText="Open" end end end end
