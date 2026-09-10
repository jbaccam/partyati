-- V3 additive greybox; no finished art or key progression yet.
local root=workspace:WaitForChild("FacilityLayoutReview")
if root:FindFirstChild("Basement") then return end
root:SetAttribute("LayoutVersion",5)
local basement=Instance.new("Model"); basement.Name="Basement"; basement.Parent=root
local gray=Color3.fromRGB(104,112,108)
local function p(name,size,position,color,parent)
 local v=Instance.new("Part"); v.Name=name; v.Anchored=true; v.Size=size; v.Position=position
 v.Color=color or gray; v.Material=Enum.Material.SmoothPlastic; v.TopSurface=Enum.SurfaceType.Smooth
 v.Parent=parent or basement; return v
end
local function label(text,x,y,z)
 local a=p("ReviewLabel",Vector3.one,Vector3.new(x,y,z)); a.Transparency=1; a.CanCollide=false; a.CanQuery=false
 local b=Instance.new("BillboardGui"); b.Size=UDim2.fromOffset(220,38); b.MaxDistance=180; b.Parent=a
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=.25; t.BackgroundColor3=Color3.fromRGB(25,28,30)
 t.TextColor3=Color3.fromRGB(235,231,215); t.TextSize=14; t.Text=text; t.Parent=b
end
-- Preserve template, but make it nonblocking so stairs can pass through it.
local base=workspace:FindFirstChild("Baseplate")
if base and base:IsA("BasePart") then
 if base:GetAttribute("FacilityPreviousTransparency")==nil then
  base:SetAttribute("FacilityPreviousTransparency",base.Transparency); base:SetAttribute("FacilityPreviousCanCollide",base.CanCollide)
 end
 base.Transparency=1; base.CanCollide=false
end
-- Generator silhouettes move downstairs; the old room becomes a service hall.
for _,v in root:GetChildren() do
 if v:IsA("BasePart") and v.Name=="MachineBlock" then v.Position+=Vector3.new(0,-40,124); v.Parent=basement end
 if v:IsA("BasePart") and v.Name=="Floor_Generator" then v.Name="Floor_ServiceHall" end
 for _,t in v:GetDescendants() do if t:IsA("TextLabel") and t.Text=="Generator" then t.Text="Service Hall / East Stairs" end end
end
p("BasementFloor",Vector3.new(512,1,164),Vector3.new(0,-39.5,170),Color3.fromRGB(91,95,89))
for _,r in {{0,88,512,1},{0,252,512,1},{-256,170,1,164},{256,170,1,164}} do
 -- North boundary has two stair entrances, added separately below.
 if r[2]~=88 then p("Boundary",Vector3.new(r[3],20,r[4]),Vector3.new(r[1],-29,r[2])) end
end
for _,r in {{-244,24},{-8,416},{236,40}} do p("NorthBoundary",Vector3.new(r[2],20,1),Vector3.new(r[1],-29,88)) end
-- Two broad straight service stairs; half-stud risers remain cheap to revise.
for _,x in {-224,208} do
 for _,v in root:GetChildren() do
  if v:IsA("BasePart") then
   if string.sub(v.Name,1,6)=="Floor_" and math.abs(v.Position.X-x)<1 and v.Position.Z>=32 and v.Position.Z<=112 then v:Destroy() end
   if v.Name=="Wall" and math.abs(v.Position.X-x)<1 and v.Position.Z>24 and v.Position.Z<104 and v.Size.X>1 then v:Destroy() end
  end
 end
 for i=1,80 do
  local top=1-i*.5
  p("StairTread",Vector3.new(15,1,1),Vector3.new(x,top-.5,24+i-.5))
 end
 for _,dx in {-8,8} do
  local rail=p("StairGuard",Vector3.new(1,4,math.sqrt(80^2+40^2)),Vector3.new(x+dx,-17,64))
  rail.CFrame=CFrame.new(rail.Position)*CFrame.Angles(math.atan(.5),0,0)
 end
 label(x<0 and "WEST STAIRS" or "EAST STAIRS",x,10,16)
end
-- Frames also mark future gating. Width is generous for chase movement.
local function frame(name,x,z,width,angle,floor,locked,withDoor)
 local cf=CFrame.new(x,floor,z)*CFrame.Angles(0,angle,0)
 local function piece(n,w,h,d,dx,y)
  local v=p(n,Vector3.new(w,h,d),Vector3.zero,nil); v.CFrame=cf*CFrame.new(dx,y,0); return v
 end
 local gap=12; local side=(width-gap)/2
 if floor<0 then
  if side>0 then piece("FrameWall",side,20,1,-gap/2-side/2,10); piece("FrameWall",side,20,1,gap/2+side/2,10) end
  piece("Header",gap,9,1,0,15.5)
 end
 if withDoor then
  local model=Instance.new("Model"); model.Name=name; model:SetAttribute("FacilityDoor",true); model:SetAttribute("Locked",locked); model:SetAttribute("Open",false); model.Parent=basement
  local leaf=piece("Leaf",11.8,10.8,.8,0,5.5); leaf.Color=locked and Color3.fromRGB(132,92,72) or Color3.fromRGB(81,103,115); leaf.Parent=model
  local anchor=piece("PromptAnchor",1,1,1,0,5); anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false; anchor.Parent=model
  local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=locked and "Locked (key system pending)" or "Open"; prompt.ObjectText=name; prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false; prompt.Parent=anchor
 end
end
local function room(name,x,z,w,d,locked)
 p("RoomSide",Vector3.new(1,20,d),Vector3.new(x-w/2,-29,z))
 p("RoomSide",Vector3.new(1,20,d),Vector3.new(x+w/2,-29,z))
 frame(name.." North",x,z-d/2,w,0,-39,locked,locked)
 frame(name.." South",x,z+d/2,w,0,-39,locked,locked)
 label(name,x,-24,z)
end
room("Generator Hall",176,188,128,88,false)
room("Pump Room",16,188,152,88,false)
room("Washroom Labyrinth",-160,188,160,88,false)
-- Enclosed service voids reduce the former broad north apron to a 20-stud hall.
-- Keep 16-stud connectors from both stair landings.
for _,r in {{-256,-232},{-216,-56},{-8,24},{72,200},{216,256}} do
 p("EnclosedServiceVoid",Vector3.new(r[2]-r[1],20,36),Vector3.new((r[1]+r[2])/2,-29,106))
end
frame("West Stair Threshold",-224,124,16,0,-39,false,false)
frame("East Stair Threshold",208,124,16,0,-39,false,false)
-- Repeated offset screens create a navigable loop, not a solid maze choke.
for i=0,3 do
 local x=-220+i*34
 p("WashroomScreen",Vector3.new(3,12,44),Vector3.new(x,-33,i%2==0 and 180 or 202))
 p("BasinPlaceholder",Vector3.new(12,3,5),Vector3.new(x+9,-37,160))
end
for _,r in {{-14,178},{45,203}} do p("PumpBlock",Vector3.new(20,10,24),Vector3.new(r[1],-34,r[2])) end
-- Optional locked alcoves don't gate either stair or the outer escape loop.
for _,r in {{"Electrical Switchgear",-32},{"Records Cage",48}} do
 local x=r[2]
 p("AlcoveBack",Vector3.new(48,16,1),Vector3.new(x,-31,88))
 for _,dx in {-24,24} do p("AlcoveSide",Vector3.new(1,16,36),Vector3.new(x+dx,-31,106)) end
 frame(r[1],x,124,48,0,-39,true,true)
end
-- Selected upstairs thresholds: working prototypes, not a completed door pass.
frame("Security Door",104,184,32,0,1,false,true)
frame("Library West Door",88,-120,32,math.pi/2,1,false,true)
frame("Medical East Door",-136,-176,48,math.pi/2,1,false,true)
label("POWER / SABOTAGE — proposed",176,-27,188)
label("PUMPS / UTILITY OBJECTIVE — proposed",16,-27,188)
label("WASHROOMS / BREAK SIGHTLINES",-160,-27,188)
label("RECORDS / RISKY SEARCH — proposed",48,-25,105)
root:SetAttribute("BasementReady",true)
