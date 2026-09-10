-- Movement blockout v2. Sliding/vaulting controller and enemy AI are deferred.
if workspace:FindFirstChild("FacilityLayoutReview") then return end
local root=Instance.new("Model"); root.Name="FacilityLayoutReview"; root:SetAttribute("LayoutVersion",2)
local cells,zones={},{}
local function pos(x,z) return (x-18)*16,(z-17)*16 end
local function part(name,w,h,d,x,y,z,color)
 local p=Instance.new("Part"); p.Name=name; p.Anchored=true
 p.Size=Vector3.new(w,h,d); p.Position=Vector3.new(x,y,z)
 p.Material=Enum.Material.SmoothPlastic; p.Color=color or Color3.fromRGB(140,145,148)
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=root; return p
end
local function fill(x1,z1,x2,z2,zone)
 for x=x1,x2 do for z=z1,z2 do
  local key=x..":"..z
  if zone or not cells[key] then cells[key]={x=x,z=z,zone=zone or "Hall"} end
 end end
end
local function label(text,x,y,z)
 local p=part("ReviewLabel",1,1,1,x,y,z); p.Transparency=1; p.CanCollide=false; p.CanQuery=false
 local b=Instance.new("BillboardGui"); b.Size=UDim2.fromOffset(210,36); b.MaxDistance=150; b.Parent=p
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=0.3
 t.BackgroundColor3=Color3.fromRGB(25,28,30); t.TextColor3=Color3.fromRGB(230,228,218)
 t.TextSize=14; t.Font=Enum.Font.GothamMedium; t.Text=text; t.Parent=b
end
local function zone(name,x1,z1,x2,z2,color)
 fill(x1,z1,x2,z2,name); local x,z=pos((x1+x2)/2,(z1+z2)/2)
 zones[name]={x=x,z=z,color=color}; label(name,x,12,z)
end
-- Several connected loops, with 32-stud main corridors and distinct room footprints.
for _,r in {{10,5,11,27},{22,7,23,30},{7,9,28,10},{7,21,27,22},{10,26,26,27},
 {17,26,18,30},{7,6,10,7},{6,9,7,14},{7,18,11,19},{11,4,14,5},
 {19,5,24,6},{28,10,29,18},{22,14,29,15},{24,24,25,29}} do fill(table.unpack(r)) end
zone("Medical",3,3,9,7,Color3.fromRGB(141,142,130))
zone("Admin",14,2,20,6,Color3.fromRGB(131,121,111))
zone("Library",24,3,32,11,Color3.fromRGB(99,120,109))
zone("Residential",2,13,8,20,Color3.fromRGB(104,119,136))
zone("Courtyard",13,12,20,19,Color3.fromRGB(112,129,113))
zone("Generator",25,18,33,24,Color3.fromRGB(131,127,100))
zone("Storage",12,23,17,26,Color3.fromRGB(126,119,102))
zone("Entry",15,29,20,32,Color3.fromRGB(133,136,137))
zone("Security",24,29,29,32,Color3.fromRGB(131,109,106))
fill(11,14,13,15); fill(20,16,22,17); fill(16,19,17,21)
-- Seal enclosed non-playable pockets; exterior remains exterior, not fake rooms.
local outside={}; local queue={{0,0}}; outside['0:0']=true; local head=1
while head<=#queue do
 local q=queue[head]; head+=1
 for _,d in {{1,0},{-1,0},{0,1},{0,-1}} do
  local x,z=q[1]+d[1],q[2]+d[2]; local key=x..":"..z
  if x>=0 and x<=35 and z>=0 and z<=34 and not cells[key] and not outside[key] then outside[key]=true; table.insert(queue,{x,z}) end
 end
end
for x=1,34 do for z=1,33 do
 if not cells[x..":"..z] and not outside[x..":"..z] then
  local px,pz=pos(x,z); part("StructuralInfill",16,16,16,px,9,pz)
 end
end end
for _,c in cells do
 local x,z=pos(c.x,c.z)
 part("Floor_"..c.zone,16,1,16,x,0.5,z,zones[c.zone] and zones[c.zone].color or Color3.fromRGB(119,123,126))
 for _,d in {{-1,0},{1,0},{0,-1},{0,1}} do
  if not cells[(c.x+d[1])..":"..(c.z+d[2])] then
   part("Wall",d[1]==0 and 16 or 1,16,d[2]==0 and 16 or 1,x+d[1]*8,9,z+d[2]*8)
  end
 end
end
-- Partition every room/hall interface, preserving one framed opening per contiguous run.
local runs={}
for _,c in cells do
 for _,d in {{1,0},{0,1}} do
  local n=cells[(c.x+d[1])..":"..(c.z+d[2])]
  if n and n.zone~=c.zone then
   local axis=d[1]==1 and "X" or "Z"
   local fixed=d[1]==1 and c.x or c.z
   local names={c.zone,n.zone}; table.sort(names)
   local key=axis..fixed..names[1]..names[2]
   runs[key]=runs[key] or {axis=axis,fixed=fixed,values={}}
   table.insert(runs[key].values,d[1]==1 and c.z or c.x)
  end
 end
end
local function threshold(r,first,last)
 local length=(last-first+1)*16; local middle=(first+last)/2
 local x,z
 if r.axis=="X" then x,z=pos(r.fixed+.5,middle) else x,z=pos(middle,r.fixed+.5) end
 local side=(length-12)/2
 for _,sign in {-1,1} do
  local shift=sign*(6+side/2)
  part("RoomBoundary",r.axis=="X" and 1 or side,16,r.axis=="X" and side or 1,x+(r.axis=="Z" and shift or 0),9,z+(r.axis=="X" and shift or 0))
 end
 part("DoorwayHeader",r.axis=="X" and 1 or 12,5,r.axis=="X" and 12 or 1,x,14.5,z)
end
for _,r in runs do
 table.sort(r.values); local first=r.values[1]; local last=first
 for i=2,#r.values do local v=r.values[i]; if v>last+1 then threshold(r,first,last); first=v end; last=v end
 threshold(r,first,last)
end
local dark=Color3.fromRGB(82,89,92)
local amber=Color3.fromRGB(169,132,73)
local function obstacle(zoneName,name,dx,dz,w,h,d)
 local a=zones[zoneName]; return part(name,w,h,d,a.x+dx,1+h/2,a.z+dz,dark)
end
-- Dense stacks: eight columns, three full rows and a short fourth row.
-- 8-stud longitudinal aisles / 10-stud cross aisles; southern traversal bays reserved.
for row=0,3 do for col=0,7 do
 if row<3 or col<2 then obstacle("Library","ShelfBlock",-52+col*16,-52+row*34,8,12,24) end
end end
local hurdle=obstacle("Library","LibraryHurdle",0,64,18,3,6)
hurdle:SetAttribute("TraversalType","Vault"); hurdle:SetAttribute("Prototype",true)
for i=-1,1 do obstacle("Admin","DeskIsland",i*28,0,16,4,12); obstacle("Medical","BedScreen",i*28,0,4,10,30) end
for _,o in {{-38,-25,28,36},{10,20,34,26},{45,-30,16,28}} do obstacle("Generator","MachineBlock",o[1],o[2],o[3],12,o[4]) end
obstacle("Storage","CrateBank",-16,0,24,8,20)
obstacle("Residential","Partition",0,0,4,14,64)
obstacle("Residential","PartitionReturn",14,-30,32,14,4)
for _,r in {{"Library",0,48},{"Storage",0,22}} do
 local a=zones[r[1]]; local x,z=a.x+r[2],a.z+r[3]
 part("SlideWallLeft",16,12,3,x-13,7,z); part("SlideWallRight",16,12,3,x+13,7,z)
 local beam=part("SlideOpening_10x3",10,9,3,x,8.5,z,amber)
 beam:SetAttribute("TraversalType","Slide"); beam:SetAttribute("ClearanceStuds",3)
 label("SLIDE GAP — controller pending",x,14,z)
end
local a=zones.Library
part("FallenShelfTop",20,2,8,a.x+42,5,a.z+35,dark)
for _,dx in {-9,9} do part("ShelfSupport",2,3,8,a.x+42+dx,2.5,a.z+35) end
label("LOW UNDERPASS",a.x+42,10,a.z+35)
local a=zones.Residential
part("WindowLeft",12,14,2,a.x-23,8,a.z+42); part("WindowRight",12,14,2,a.x+1,8,a.z+42)
local sill=part("VaultWindowSill",12,3,2,a.x-11,2.5,a.z+42,amber); sill:SetAttribute("TraversalType","Vault")
part("WindowHeader",12,4,2,a.x-11,13,a.z+42); label("VAULT WINDOW — controller pending",a.x-11,17,a.z+42)
obstacle("Courtyard","PlanterBlock",-24,-20,28,4,12); obstacle("Courtyard","PlanterBlock",26,25,12,4,28)
local spawn=Instance.new("SpawnLocation"); spawn.Name="ReviewSpawn"; spawn.Size=Vector3.new(6,1,6)
spawn.Position=Vector3.new(zones.Entry.x,1.5,zones.Entry.z); spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0; spawn.Parent=root
root.Parent=workspace
local old=workspace:FindFirstChild("SpawnLocation"); if old and old:IsA("SpawnLocation") then old.Enabled=false end
