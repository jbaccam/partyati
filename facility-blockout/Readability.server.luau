-- Final map readability pass: real doorway approaches and visible, fixed supplies.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("MapFinishReady") do task.wait() end
if root:GetAttribute("ReadabilityReady") then return end
local K=require(game.ServerScriptService.FacilityRoomKit)
local V,C=Vector3.new,Color3.fromRGB;local P=K.colors
local rooms=root.RoomInteriors;local yard=rooms.Courtyard
local backup=Instance.new("Folder");backup.Name="Facility_ReadabilityBackup";backup.Parent=game.ServerStorage
local function cf(x,y,z,a) return CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(a or 0),0) end
local paths=K.model(yard,"DoorAlignedCourtyardPaths")
-- Door apertures measured from CleanArchitecture: west Z=-40, east Z=-8,
-- south X=-24, each ten studs wide. There is no northern doorway.
local rectangles={{-38,-10,-50,2},{-88,-38,-45,-35},{-10,40,-13,-3},{-29,-19,2,40}}
local benches={{-41,-24,90},{-7,-27,-90},{-62,-48,0},{15,0,180},{-24,-53,0},{-32,23,90}}
for _,r in benches do
 local dx,dz=6,3.5;if math.abs(r[3])==90 then dx,dz=dz,dx end
 table.insert(rectangles,{r[1]-dx,r[1]+dx,r[2]-dz,r[2]+dz})
end
local function paved(x,z)
 for _,r in rectangles do if x>=r[1] and x<=r[2] and z>=r[3] and z<=r[4] then return true end end
 return false
end
-- Preserve the superseded cross, furniture and curbs for recovery.
for _,p in root.ProductionLayout:GetChildren() do if p.Name=="CourtyardConcretePath" then p.Parent=backup end end
for _,p in yard:GetChildren() do
 if p.Name=="PathEdging" or p.Name=="BenchConcretePad" or p.Name=="CourtyardSlattedBench" or p.Name=="CourtyardPathLight" then p.Parent=backup end
end
-- Partition the union into adjoining slabs: no overlapping coplanar paving.
local xs,zs={},{};local seenX,seenZ={},{}
for _,r in rectangles do
 for _,x in {r[1],r[2]} do if not seenX[x] then seenX[x]=true;table.insert(xs,x) end end
 for _,z in {r[3],r[4]} do if not seenZ[z] then seenZ[z]=true;table.insert(zs,z) end end
end
table.sort(xs);table.sort(zs)
local previous={}
for j=1,#zs-1 do
 local nextRow={};local i=1
 while i<#xs do
  if paved((xs[i]+xs[i+1])/2,(zs[j]+zs[j+1])/2) then
   local start=i;i+=1
   while i<#xs and paved((xs[i]+xs[i+1])/2,(zs[j]+zs[j+1])/2) do i+=1 end
   local x0,x1,z0,z1=xs[start],xs[i],zs[j],zs[j+1]
   local key=tostring(x0)..":"..tostring(x1);local slab=previous[key]
   if slab then
    local oldMin=slab.Position.Z-slab.Size.Z/2
    slab.Size=V(x1-x0,.45,z1-oldMin);slab.Position=V((x0+x1)/2,1.225,(oldMin+z1)/2)
   else slab=K.part(paths,"ConcreteApproach",V(x1-x0,.45,z1-z0),V((x0+x1)/2,1.225,(z0+z1)/2),C(127,128,115),Enum.Material.Concrete,true) end
   nextRow[key]=slab
  else i+=1 end
 end
 previous=nextRow
end
-- Edging only on exposed planting boundaries, never across an entry or junction.
for i=1,#xs-1 do for j=1,#zs-1 do
 local x0,x1,z0,z1=xs[i],xs[i+1],zs[j],zs[j+1];local x,z=(x0+x1)/2,(z0+z1)/2
 if paved(x,z) then
  for _,edge in {{x0,z,x0-.01,z,.14,z1-z0},{x1,z,x1+.01,z,.14,z1-z0},{x,z0,x,z0-.01,x1-x0,.14},{x,z1,x,z1+.01,x1-x0,.14}} do
   if edge[1]>-87.9 and edge[1]<39.9 and edge[2]>-87.9 and edge[2]<39.9 and not paved(edge[3],edge[4]) then
    K.part(paths,"FlushStoneEdging",V(edge[5],.16,edge[6]),V(edge[1],1.4,edge[2]),C(102,107,95),Enum.Material.Concrete)
   end
  end
 end
end end
for _,r in benches do K.bench(paths,cf(r[1],1.45,r[2],r[3])) end
-- Terrain surface remains Y=1; Ground suppresses blades beneath the new union.
local terrain=workspace.Terrain
local saved=terrain:CopyRegion(Region3int16.new(Vector3int16.new(-22,-2,-22),Vector3int16.new(10,1,10)))
saved.Name="CourtyardTerrainBeforeDoorAlignment";saved.Parent=backup
local materials,occupancy={},{}
for x=1,32 do materials[x]={};occupancy[x]={};for y=1,4 do materials[x][y]={};occupancy[x][y]={};for z=1,32 do
 local ground=false;local px,pz=-90+x*4,-90+z*4
 -- Cover the entire intersecting terrain cell so grass cannot overhang a path.
 for _,r in rectangles do if px+2>r[1] and px-2<r[2] and pz+2>r[3] and pz-2<r[4] then ground=true;break end end
 materials[x][y][z]=y<3 and (ground and Enum.Material.Ground or Enum.Material.Grass) or Enum.Material.Air
 occupancy[x][y][z]=y==1 and 1 or y==2 and .75 or 0
end end end
terrain:WriteVoxels(Region3.new(V(-88,-8,-88),V(40,8,40)),4,materials,occupancy)
for _,r in {{-78,-47},{-50,-47},{-39,-9},{-9,-43},{6,-15},{30,-15},{-31,9},{-31,33}} do
 local m=K.model(paths,"CourtyardPathLight");local pos=V(r[1],1.3,r[2])
 K.disc(m,"BaseFlange",CFrame.new(pos),1.25,.18,P.trim)
 K.rod(m,"LampPost",pos,pos+V(0,8.4,0),.18,P.trim)
 local globe=K.part(m,"WarmBulb",V(.85,.55,.85),CFrame.new(pos+V(0,8.2,0)),C(206,195,147),Enum.Material.Neon)
 K.part(m,"Downshade",V(1.5,.15,1.5),CFrame.new(pos+V(0,8.6,0)),P.trim,Enum.Material.Metal)
 local l=Instance.new("PointLight");l.Range=38;l.Brightness=1.4;l.Color=C(214,210,169);l.Shadows=true;l.Parent=globe
end
-- One fixed, visible point for each supply type. Decorative empty storage slots
-- remain useful future authoring markers, but never ask players to search them.
local chosen={Office_Files_1="Storage key",Maintenance_Cutters="Bolt cutters",Locked_Tool_Cabinet="Screwdriver",Staff_Badge_Cabinet="Staff badge",Pump_Tools="Pump valve",Reception_Supplies="Radio relay",Visible_Medical_Supplies_1="Fuse",Visible_Medical_Supplies_2="Battery",Storage_Bay_133_1_2="Insulated wire"}
local active={};local retired=0
for _,n in root:GetDescendants() do if n:IsA("BasePart") and n:GetAttribute("InteractionKind")=="Search" then
 local id=n:GetAttribute("ObjectiveId");local q=n:FindFirstChildOfClass("ProximityPrompt")
 if q and chosen[id] and not active[id] then active[id]=n else
  if q then q:SetAttribute("OriginalNode",n:GetFullName());q.Parent=backup;retired+=1 end
  n:SetAttribute("InteractionKind",nil);n:SetAttribute("ItemId",nil);n:SetAttribute("SpawnSurface",true)
 end
end end
local function display(parent,frame,item)
 local m=K.model(parent,"Visible_"..item)
 local function part(name,size,pos,color) return K.part(m,name,size,frame*CFrame.new(pos),color or P.metal,Enum.Material.Metal) end
 local function rod(name,a,b,d,color) return K.rod(m,name,frame:PointToWorldSpace(a),frame:PointToWorldSpace(b),d,color or P.metal) end
 local function ring(name,radius,y,z,color)
  for i=0,19 do local a,b=i*math.pi/10,(i+1)*math.pi/10;rod(name,V(math.cos(a)*radius,y+math.sin(a)*radius,z),V(math.cos(b)*radius,y+math.sin(b)*radius,z),.1,color) end
 end
 if item=="Cutters" then
  for _,s in {-1,1} do
   rod("ForgedHandle",V(s*.14,.15,0),V(s*.65,-1.2,0),.15)
   rod("RubberGrip",V(s*.48,-.8,0),V(s*.65,-1.2,0),.24,C(117,66,44))
   part("CuttingJaw",V(.25,.7,.22),V(s*.17,.62,0),P.trim)
  end
  part("HingeBolt",V(.4,.28,.35),V(0,.1,0))
 elseif item=="Screwdriver" then
  rod("SteelShaft",V(0,-.9,0),V(0,.3,0),.1)
  rod("MouldedGrip",V(0,.3,0),V(0,.95,0),.32,C(161,129,67))
  part("FlatBlade",V(.19,.22,.06),V(0,-1,0))
 elseif item=="StorageKey" then
  ring("KeyBow",.25,.5,0,C(169,145,83));rod("KeyShaft",V(0,.25,0),V(0,-.55,0),.13,C(169,145,83))
  for _,y in {-.35,-.53} do part("KeyTooth",V(.28,.12,.13),V(.13,y,0),C(169,145,83)) end
  part("StoresTag",V(.8,.38,.07),V(.65,.45,0),P.paper)
 elseif item=="Valve" then
  ring("ValveWheel",.85,0,0,C(126,69,47))
  for i=0,3 do local a=i*math.pi/2;rod("WheelSpoke",Vector3.zero,V(math.cos(a)*.8,math.sin(a)*.8,0),.12,C(126,69,47)) end
  part("SquareSpindleSocket",V(.3,.3,.25),Vector3.zero)
 elseif item=="Badge" then
  rod("BadgeClip",V(0,.8,0),V(0,.4,0),.1)
  part("LaminatedBadge",V(1,1.3,.08),V(0,-.2,0),P.paper)
  part("Portrait",V(.38,.44,.015),V(-.2,-.1,.055),P.lower)
  for i=1,3 do part("PrintedCredentials",V(.4,.035,.015),V(.2,-.18-i*.14,.055),P.trim) end
 elseif item=="Wire" then
  for z=0,.24,.08 do ring("CoiledInsulatedWire",.65,0,z,C(129,107,70)) end
  rod("LooseCableEnd",V(.6,0,.24),V(.85,-.9,.24),.1,C(129,107,70))
 elseif item=="Fuse" then
  rod("CeramicFuseBody",V(0,-.65,0),V(0,.65,0),.36,P.paper)
  for _,y in {-.6,.6} do rod("MetalFuseCap",V(0,y-.13,0),V(0,y+.13,0),.4) end
 elseif item=="Battery" then
  part("BatteryHousing",V(1.1,1.35,.65),Vector3.zero,P.trim)
  part("BatteryLabel",V(.86,.75,.04),V(0,0,.35),C(156,139,85))
  for _,x in {-.32,.32} do part("Terminal",V(.16,.16,.2),V(x,.75,0)) end
 elseif item=="RadioPart" then
  part("RelayChassis",V(1.7,1.05,.6),Vector3.zero,P.metal)
  for i=1,5 do part("CoolingSlot",V(.07,.65,.025),V(-.65+i*.2,0,.32),P.trim) end
  for _,x in {-.55,.55} do part("Connector",V(.22,.2,.28),V(x,-.6,0),C(156,139,85)) end
 end
 return m
end
for id,n in active do
 local item=n:GetAttribute("ItemId");local f=n.CFrame
 if id=="Maintenance_Cutters" then f=cf(-90.02,5.4,100.65,90)
 elseif item=="Wire" then f=f*CFrame.new(0,.9,1.95) end
 local m=K.model(n.Parent,"MarkedSupply_"..item);m:SetAttribute("SupplyItem",item);m:SetAttribute("FixedSpawn",true)
 if id:find("Visible_Medical_Supplies") then
  -- Replace opaque cases with the component itself on the existing trolley.
  for _,p in n.Parent:GetChildren() do if p.Name=="VisibleSupplyCase" or p.Name=="CaseHandle" or p.Name=="EnamelSign" or p.Name=="FoldedCloth" then p.Parent=backup end end
  f=cf(n.Position.X,5.25,n.Position.Z)
  K.part(m,"DisplayTray",V(2.8,.1,1.8),f*CFrame.new(0,-.76,0),P.metal,Enum.Material.Metal)
  K.part(m,"LabelStand",V(.12,1,.12),f*CFrame.new(0,.55,-.65),P.metal,Enum.Material.Metal)
  K.sign(m,f*CFrame.new(0,1.35,-.65),string.upper(chosen[id]),3,.7)
 else
  -- Shallow hook board attaches to a cabinet/rack, not a floating world marker.
  K.part(m,"SupplyMount",V(3.1,3.7,.32),f*CFrame.new(0,.25,-.15),P.lower,Enum.Material.Metal)
  K.part(m,"BottomLip",V(3.1,.14,.7),f*CFrame.new(0,-1.53,.15),P.trim,Enum.Material.Metal)
  K.sign(m,f*CFrame.new(0,1.57,.06),string.upper(chosen[id]),2.85,.62)
  for _,x in {-1.35,1.35} do for _,y in {-1.3,1.1} do K.part(m,"MountScrew",V(.1,.1,.08),f*CFrame.new(x,y,.06),P.metal,Enum.Material.Metal) end end
  K.rod(m,"DisplayHook",f:PointToWorldSpace(V(0,.7,0)),f:PointToWorldSpace(V(0,.7,.48)),.09,P.metal)
  f=f*CFrame.new(0,0,.35)
 end
 display(m,f,item)
 n.CFrame=f*CFrame.new(0,0,.7);n:SetAttribute("VisibleSupply",true);n:SetAttribute("FixedSpawn",true)
 local q=n:FindFirstChildOfClass("ProximityPrompt");q.ActionText="Take";q.ObjectText=chosen[id];q.HoldDuration=.35;q.RequiresLineOfSight=true;q.MaxActivationDistance=7
end
-- In-world directories make destinations learnable without searching random props.
local reception=K.model(rooms.Reception,"SupplyLocationDirectory")
K.sign(reception,cf(-36,9,247.1),"SUPPLY DIRECTORY",15,1.3)
K.sign(reception,cf(-36,6.6,247.1),"ADMINISTRATION  /  labelled storage-key hook\nSTORES  /  bolt cutters, screwdriver, cable\nPUMP ROOM  /  red spare valve wheel\nRECEPTION  /  labelled radio relay",15,3.1)
K.sign(rooms.Storage,cf(-84,10,89),"TOOLS ON MARKED HOOK BOARDS\nBOLT CUTTERS  /  FIRST RACK\nSCREWDRIVER  /  REAR CABINET",16,2.6)
root:SetAttribute("RetiredSearchPrompts",retired)
root:SetAttribute("ReadabilityReady",true)
