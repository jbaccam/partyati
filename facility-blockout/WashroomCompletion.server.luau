-- Full-room finish; preserves the basement's staggered circulation geometry.
local root=workspace:WaitForChild("FacilityLayoutReview")
local first=root:WaitForChild("WashroomArt")
while not first:GetAttribute("FirstBayReady") do task.wait() end
local detail=root:WaitForChild("WashroomDetails")
while not detail:GetAttribute("Ready") do task.wait() end
if root:FindFirstChild("WashroomCompletion") then return end
local out=Instance.new("Model");out.Name="WashroomCompletion";out.Parent=root
local backup=Instance.new("Folder");backup.Name="WashroomCompletion_Backup";backup.Parent=game.ServerStorage
local V=Vector3.new
local tile=Color3.fromRGB(125,139,129)
local green=Color3.fromRGB(58,76,66)
local metal=Color3.fromRGB(97,105,100)
local dark=Color3.fromRGB(43,51,47)
local function p(n,s,cf,c,m)
 local a=Instance.new("Part");a.Name=n;a.Size=s;a.CFrame=typeof(cf)=="CFrame" and cf or CFrame.new(cf)
 a.Anchored=true;a.CanTouch=false;a.Color=c or metal;a.Material=m or Enum.Material.SmoothPlastic
 a.TopSurface=Enum.SurfaceType.Smooth;a.BottomSurface=Enum.SurfaceType.Smooth;a.Parent=out;return a
end
local function trim(n,s,cf,c)
 local a=p(n,s,cf,c,Enum.Material.Metal);a.CanCollide=false
 if string.find(n,"Grout") or n=="CeilingTBar" then a.CastShadow=false end
 return a
end
local function pipe(n,a,b,r)
 local v=p(n,V((b-a).Magnitude,r,r),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),metal,Enum.Material.Metal)
 v.Shape=Enum.PartType.Cylinder;v.CanCollide=false;return v
end
local function asset(n,pos,yaw)
 local m=game.ServerStorage:WaitForChild("WashroomTemplates")[n]:Clone();m.Parent=out
 local cf=CFrame.new(pos)*CFrame.Angles(0,yaw,0)
 for _,v in m:GetDescendants() do if v:IsA("BasePart") then v.CFrame=cf*v.CFrame;v.Anchored=true;v.CanTouch=false end end
end
-- Replace only the earlier partial ceiling, retaining its three working fixtures.
for _,v in first:GetChildren() do
 if v.Name=="WashroomCeiling" or v.Name=="CeilingTBar" then v.Parent=backup end
end
for _,v in root.Basement:GetChildren() do
 if v.Name=="BasinPlaceholder" then v.Parent=backup end
 if v.Name=="WashroomScreen" then
  v.Material=Enum.Material.SmoothPlastic;v.Color=tile
  trim("PartitionCap",V(3.14,.16,44.1),v.Position+V(0,6.06,0),metal)
  for _,side in {-1,1} do
   for y=-38,-28,2 do trim("ScreenGrout",V(.025,.022,44),V(v.Position.X+side*1.505,y,v.Position.Z),Color3.fromRGB(100,113,104)) end
   for z=v.Position.Z-20,v.Position.Z+20,2 do trim("ScreenGrout",V(.025,12,.022),V(v.Position.X+side*1.505,-33,z),Color3.fromRGB(100,113,104)) end
   trim("ScreenKickplate",V(.05,.65,44),V(v.Position.X+side*1.53,-38.58,v.Position.Z),dark)
  end
 end
end
-- Lower wall tile: north/south are split around the actual two openings.
local function panel(cx,cz,width,yaw)
 local cf=CFrame.new(cx,-36.4,cz)*CFrame.Angles(0,yaw,0)
 p("WallTileWainscot",V(width,5,.08),cf,tile)
 trim("WallTileCap",V(width,.12,.16),cf*CFrame.new(0,2.55,0),metal)
 trim("WallSkirting",V(width,.3,.12),cf*CFrame.new(0,-2.35,0),dark)
 for x=-width/2+2,width/2-1,2 do trim("WallGrout",V(.018,5,.012),cf*CFrame.new(x,0,.045),Color3.fromRGB(104,116,107)) end
 for y=-1.5,1.5,1 do trim("WallGrout",V(width,.018,.012),cf*CFrame.new(0,y,.045),Color3.fromRGB(104,116,107)) end
end
panel(-227,144.58,24,0) -- rest of west north run already has sink splashback
panel(-178,144.58,25,0)
panel(-117,144.58,74,0)
panel(-202.5,231.42,74,math.pi);panel(-117,231.42,74,math.pi)
panel(-239.42,188,86,math.pi/2);panel(-80.58,188,86,-math.pi/2)
local ceiling=p("DropCeiling",V(159,.3,87),V(-160,-23.2,188),Color3.fromRGB(57,62,57));ceiling.CanCollide=false
for x=-239,-81,4 do trim("CeilingTBar",V(.045,.04,87),V(x,-23.37,188),metal) end
for z=144.5,231.5,4 do trim("CeilingTBar",V(159,.04,.045),V(-160,-23.37,z),metal) end
for i,r in {{-182,153},{-144,153},{-100,153},{-204,180},{-170,190},{-136,177},{-98,179},{-224,216},{-201,222},{-164,218},{-132,220},{-96,219}} do
 trim("LightHousing",V(2.4,.3,5),V(r[1],-23.6,r[2]),metal)
 local lit=i~=5 and i~=11
 local bulb=p(lit and "Diffuser" or "DeadDiffuser",V(2.1,.1,4.7),V(r[1],-23.8,r[2]),lit and Color3.fromRGB(189,201,178) or Color3.fromRGB(89,96,85),lit and Enum.Material.Neon or Enum.Material.SmoothPlastic)
 bulb.CanCollide=false
 if lit then local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Angle=110;l.Range=29;l.Brightness=2.2;l.Color=Color3.fromRGB(199,212,188);l.Shadows=true;l.Parent=bulb end
end
-- Second toilet bank uses the same ceramics and powder-coated partitions.
for _,z in {184,196,208,220} do
 p("StallPartition",V(10,7.6,.2),V(-179.4,-34.2,z),green,Enum.Material.Metal)
 for _,x in {-183.8,-174.8} do trim("PartitionFoot",V(.22,.9,.22),V(x,-38.45,z),metal) end
end
for i,z in {190,202,214} do
 asset("Toilet",V(-181.5,-38.95,z),math.pi/2)
 local hinge=CFrame.new(-174.4,-34.2,z-5.8)*CFrame.Angles(0,math.rad(({72,48,85})[i]),0)
 local cf=hinge*CFrame.new(0,0,2.75)
 p("StallDoorAjar",V(.18,7.4,5.5),cf,green,Enum.Material.Metal)
 trim("StallLatch",V(.14,.22,.5),cf*CFrame.new(.15,0,2.2),metal)
 for _,dy in {-2.5,2.5} do trim("StallHinge",V(.28,.4,.3),V(-174.4,-34.2+dy,z-5.8),metal) end
 trim("PaperHolder",V(1,.2,.9),V(-179,-36.3,z-5.3),metal)
 local roll=p("PaperRoll",V(.6,.8,.8),V(-179,-36,z-5.3),Color3.fromRGB(161,157,139));roll.Shape=Enum.PartType.Cylinder;roll.CanCollide=false
end
for _,x in {-144,-136,-128} do
 -- Rear rim meets this bank's tile face at Z=144.62.
 asset("CeramicSink",V(x,-38.95,145.48),math.pi)
 trim("MirrorFrame",V(3.4,3.9,.16),V(x,-33.4,145.2),metal)
 local g=p("AgedMirror",V(3.1,3.6,.04),V(x,-33.4,145.31),Color3.fromRGB(90,110,110),Enum.Material.Glass);g.Reflectance=.15;g.CanCollide=false
 trim("SoapDispenser",V(.6,.9,.45),V(x+2.5,-35.1,145.15),dark)
 trim("SoapLever",V(.4,.1,.35),V(x+2.5,-35.5,145.45),metal)
end
local function drain(x,z)
 trim("FloorDrain",V(1.3,.025,1.3),V(x,-38.915,z),dark)
 for i=-3,3 do trim("DrainGrille",V(.06,.035,1.2),V(x+i*.17,-38.9,z),metal) end
end
-- Four open shower cubicles on the eastern wall, with real exposed plumbing.
for _,z in {156,167,178,189,200} do
 p("ShowerDivider",V(9,8,.18),V(-85.2,-34.9,z),tile)
 trim("ShowerDividerCap",V(9,.12,.25),V(-85.2,-30.84,z),metal)
end
for _,z in {161.5,172.5,183.5,194.5} do
 pipe("ShowerRiser",V(-81.1,-36,z),V(-81.1,-31,z),.15)
 pipe("ShowerArm",V(-81.1,-31,z),V(-82.4,-31,z),.15)
 local head=trim("ShowerHead",V(.25,.65,.65),CFrame.new(-82.4,-31.1,z)*CFrame.Angles(0,0,math.rad(40)),metal);head.Shape=Enum.PartType.Cylinder
 local dial=trim("ShowerControl",V(.22,.45,.45),V(-81.15,-35.6,z),metal);dial.Shape=Enum.PartType.Cylinder
 trim("ControlLever",V(.25,.12,.6),V(-81.35,-35.6,z),dark)
 trim("SoapShelf",V(.7,.1,1.3),V(-81.1,-35,z+2),metal)
 drain(-85,z)
 trim("TowelHookPlate",V(.12,.5,.35),V(-88.8,-32.2,z-5.3),metal)
end
local function bench(x,z,length)
 for i=0,3 do p("BenchSlat",V(.43,.18,length),V(x+i*.5,-36.8,z),Color3.fromRGB(79,64,45),Enum.Material.Wood) end
 for _,dz in {-length/2+1,length/2-1} do
  trim("BenchCrossbar",V(2,.15,.22),V(x+.75,-37,z+dz),dark)
  for _,dx in {0,1.5} do pipe("BenchLeg",V(x+dx,-38.9,z+dz),V(x+dx,-37,z+dz),.17) end
 end
end
bench(-99,215,11);bench(-145,211,10)
drain(-178,169);drain(-132,203);drain(-104,204)
-- Utility service and towel dispensers stay out of the circulation lanes.
for _,x in {-211,-136} do
 trim("TowelDispenser",V(2.1,2.4,.8),V(x+4,-33.8,145.1),dark)
 trim("TowelSlot",V(1.7,.15,.2),V(x+4,-34.7,145.55),metal)
 local paper=p("HangingPaper",V(1.5,.65,.025),V(x+4,-35,145.57),Color3.fromRGB(178,174,152));paper.CanCollide=false
end
for _,z in {208,225} do
 trim("VentFrame",V(.2,2.1,4),V(-80.8,-26.5,z),metal)
 trim("VentInset",V(.22,1.8,3.7),V(-80.94,-26.5,z),dark)
 for i=-4,4 do trim("VentLouver",V(.3,.08,3.5),V(-81.1,-26.5+i*.18,z),metal) end
end
pipe("OverheadServicePipe",V(-83,-24.3,148),V(-83,-24.3,228),.28)
pipe("ServiceDrop",V(-83,-24.3,226),V(-83,-35.5,226),.28)
for _,z in {144.7,231.3} do
 for _,x in {-165.3,-154.2} do trim("EntranceTrim",V(.2,11,.23),V(x,-33.5,z),metal) end
 trim("EntranceTrim",V(11.3,.2,.23),V(-159.75,-28,z),metal)
 local sign=p("ExitSign",V(3.2,.9,.15),V(-159.75,-26.5,z),green)
 local gui=Instance.new("SurfaceGui");gui.Face=z<188 and Enum.NormalId.Back or Enum.NormalId.Front;gui.CanvasSize=Vector2.new(320,90);gui.Parent=sign
 local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text="EXIT";text.TextColor3=Color3.fromRGB(189,207,183);text.TextScaled=true;text.Font=Enum.Font.GothamMedium;text.Parent=gui
end
-- Grout reads as a continuous seam, without thin geometry casting stippled shadows.
for _,group in {first,detail,out} do
 for _,a in group:GetDescendants() do
  if a:IsA("BasePart") and string.find(a.Name,"Grout") then
   a.CastShadow=false;a.Material=Enum.Material.SmoothPlastic
   local s=a.Size
   a.Size=V(s.X<.04 and .04 or s.X,s.Y<.02 and .02 or s.Y,s.Z<.04 and .04 or s.Z)
  end
 end
end
out:SetAttribute("Ready",true)
