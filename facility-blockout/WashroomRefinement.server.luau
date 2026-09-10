-- Geometry is authored once in Edit or at build startup; interactions bind in Play.
local root=workspace:WaitForChild("FacilityLayoutReview")
local complete=root:WaitForChild("WashroomCompletion")
while not complete:GetAttribute("Ready") do task.wait() end
local V=Vector3.new
local out=root:FindFirstChild("WashroomRefinement")
if not out then
 out=Instance.new("Model");out.Name="WashroomRefinement";out.Parent=root
 local backup=Instance.new("Folder");backup.Name="Washroom_PreRefinement";backup.Parent=game.ServerStorage
 local green=Color3.fromRGB(58,76,66);local metal=Color3.fromRGB(97,105,100);local dark=Color3.fromRGB(43,51,47)
 local function part(n,s,cf,c,collide,parent)
  local p=Instance.new("Part");p.Name=n;p.Size=s;p.CFrame=typeof(cf)=="CFrame" and cf or CFrame.new(cf)
  p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.Material=Enum.Material.SmoothPlastic;p.Color=c or metal
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent or out;return p
 end
 local function pipe(n,a,b,r)
  local p=part(n,V((b-a).Magnitude,r,r),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),metal)
  p.Shape=Enum.PartType.Cylinder;p.Material=Enum.Material.Metal;return p
 end
 local function label(pos,yaw,text,width)
  local p=part("Wayfinding",V(width or 5,1.2,.12),CFrame.new(pos)*CFrame.Angles(0,yaw,0),dark)
  local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Back;g.CanvasSize=Vector2.new(600,120);g.Parent=p
  local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=Color3.fromRGB(188,195,177);t.TextScaled=true;t.Font=Enum.Font.GothamMedium;t.Parent=g
 end
 local old={Toilet=true,StallPartition=true,PartitionFoot=true,StallDoorAjar=true,StallHinge=true,StallLatch=true,PaperRoll=true,PaperHolder=true,ShowerDivider=true,ShowerDividerCap=true,ShowerRiser=true,ShowerArm=true,ShowerHead=true,ShowerControl=true,ControlLever=true,SoapShelf=true,TowelHookPlate=true}
 for _,g in {root.WashroomArt,root.WashroomDetails,complete} do for _,p in g:GetChildren() do
  if old[p.Name] or string.find(p.Name,"Bench") then p.Parent=backup end
 end end
 -- Solid separation: north entrance belongs only to Men, south only to Women.
 part("FullHeightSeparation",V(160,16,.8),V(-160,-31,188),Color3.fromRGB(139,146,133),true)
 for _,side in {-1,1} do
  part("DividerTile",V(159,5,.08),V(-160,-36.4,188+side*.44),Color3.fromRGB(125,139,129))
  part("DividerTileCap",V(159,.12,.16),V(-160,-33.84,188+side*.48),metal)
  part("DividerSkirting",V(159,.3,.12),V(-160,-38.75,188+side*.48),dark)
 end
 -- Move the second sink bank and all its accessories onto the south wall.
 local accessories={MirrorFrame=true,AgedMirror=true,SoapDispenser=true,SoapLever=true,TowelDispenser=true,TowelSlot=true,HangingPaper=true}
 for _,p in complete:GetChildren() do
  if p.Name=="CeramicSink" then
   local cf=p:GetPivot();local delta=CFrame.new(cf.Position.X,cf.Position.Y,230.52)*CFrame.Angles(0,math.pi,0)*CFrame.new(-cf.Position)
   p:PivotTo(delta*cf)
  elseif p:IsA("BasePart") and accessories[p.Name] and p.Position.X>-160 and p.Position.Z<150 then
   local cf=p.CFrame;p.CFrame=CFrame.new(cf.Position.X,cf.Position.Y,376-cf.Position.Z)*CFrame.Angles(0,math.pi,0)*cf.Rotation
  end
 end
 local function toilet(back,z)
  local m=game.ServerStorage.WashroomTemplates.Toilet:Clone();m.Parent=out
  local cf=CFrame.new(back+1.83,-38.95,z)*CFrame.Angles(0,math.pi/2,0)
  for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CFrame=cf*p.CFrame;p.Anchored=true;p.CanTouch=false end end
  m:SetAttribute("WallFaceX",back)
 end
 -- Seven-stud cubicles instead of twelve; rear cistern overlaps the wall by .02.
 for bank,b in {{-239.38,150,"Men"},{-239.38,192,"Women"}} do
  local back,start,wing=b[1],b[2],b[3];local front=back+7.4
  for i=0,5 do
   local z=start+i*7
   part("StallPartition",V(7.4,7.6,.18),V(back+3.7,-34.2,z),green,true)
   part("PartitionEdge",V(7.44,.09,.24),V(back+3.7,-30.36,z),metal)
   for _,x in {back+.3,front-.25} do pipe("PartitionFoot",V(x,-38.95,z),V(x,-38,z),.18) end
  end
  for i=0,4 do
   local z=start+i*7;toilet(back,z+3.5)
   part("FrontPilaster",V(.2,7.6,1.35),V(front,-34.2,z+.675),green,true)
   local hinge=CFrame.new(front,-34.2,z+1.45)
   local m=Instance.new("Model");m.Name=wing.."StallDoor"..(i+1);m.Parent=out
   m:SetAttribute("Hinge",hinge);m:SetAttribute("Open",i%2==0);m:SetAttribute("Width",5.35)
   local leaf=part("Leaf",V(.18,7.4,5.35),hinge*CFrame.new(0,0,2.675),green,true,m)
   part("EdgeRail",V(.22,7.4,.1),hinge*CFrame.new(0,0,5.3),metal,false,m)
   part("Latch",V(.4,.25,.55),hinge*CFrame.new(.15,0,4.85),metal,false,m)
   part("InsideHandle",V(.25,.16,.7),hinge*CFrame.new(-.22,0,4.8),metal,false,m)
   m.WorldPivot=hinge
   if m:GetAttribute("Open") then m:PivotTo(hinge*CFrame.Angles(0,math.rad(-88),0)) end
   for _,dy in {-2.5,2.5} do pipe("DoorHinge",V(front,-34.4+dy,z+1.45),V(front,-34+dy,z+1.45),.24) end
   local prompt=Instance.new("ProximityPrompt");prompt.Name="StallDoorPrompt";prompt.ActionText=m:GetAttribute("Open") and "Close" or "Open";prompt.ObjectText="Stall door";prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=true;prompt.HoldDuration=.15;prompt.Parent=leaf
   local roll=part("PaperRoll",V(.7,.8,.8),V(back+3,-36,z+.55),Color3.fromRGB(168,163,145));roll.Shape=Enum.PartType.Cylinder
   part("PaperHolder",V(1,.1,1),V(back+3,-36.48,z+.55),metal)
  end
 end
 -- Four showers in EACH room, entirely on its own side of the solid wall.
 for _,start in {150,194} do
  for i=0,4 do
   local z=start+i*7.5
   part("ShowerDivider",V(9,8,.18),V(-85.2,-34.9,z),Color3.fromRGB(125,139,129),true)
   part("ShowerCap",V(9.05,.12,.25),V(-85.2,-30.84,z),metal)
  end
  for i=0,3 do
   local z=start+3.75+i*7.5
   pipe("ShowerRiser",V(-81.1,-36,z),V(-81.1,-31,z),.15)
   pipe("ShowerArm",V(-81.1,-31,z),V(-82.4,-31,z),.15)
   local h=part("ShowerHead",V(.25,.65,.65),CFrame.new(-82.4,-31.1,z)*CFrame.Angles(0,0,math.rad(40)),metal);h.Shape=Enum.PartType.Cylinder
   local d=part("ShowerControl",V(.22,.45,.45),V(-81.15,-35.6,z),metal);d.Shape=Enum.PartType.Cylinder
   part("ControlLever",V(.25,.12,.6),V(-81.35,-35.6,z),dark)
   part("SoapShelf",V(.7,.1,1.3),V(-81.1,-35,z+2),metal)
   part("FloorDrain",V(1.3,.025,1.3),V(-85,-38.91,z),dark)
   for j=-3,3 do part("DrainGrille",V(.06,.025,1.2),V(-85+j*.17,-38.89,z),metal) end
  end
 end
 -- Curtain rails and drawn-back pleats: privacy detail without closing the routes.
 for _,b in {{-89.75,150,7.5},{-89.75,194,7.5}} do
  for i=0,3 do
   local x,z,w=b[1],b[2]+i*b[3],b[3]
   pipe("CurtainRail",V(x,-30.25,z+.15),V(x,-30.25,z+w-.15),.12)
   for j=0,8 do
    local zz=z+.4+j*.13
    local c=part("DrawnCurtainPleat",V(.12,6.65,.21),V(x+(j%2)*.13,-34,zz),Color3.fromRGB(113+(j%2)*8,126+(j%2)*8,117+(j%2)*8))
    c.Material=Enum.Material.Fabric
   end
  end
 end
 label(V(-174,-28.1,145),0,"MEN",6)
 label(V(-174,-28.1,231),math.pi,"WOMEN",7)
 label(V(-160,-26.5,143.3),math.pi,"MEN",6)
 label(V(-160,-26.5,232.7),0,"WOMEN",7)
 label(V(-81,-28.4,165),math.pi/2,"SHOWERS",6)
 label(V(-81,-28.4,208),math.pi/2,"SHOWERS",6)
 -- Benches and wall-mounted hooks form changing spaces, rather than random clutter.
 for _,b in {{-190,153},{-101,181},{-190,228},{-101,227}} do
  local x,z=b[1],b[2]
  for i=0,3 do local p=part("ChangingBenchSlat",V(10,.18,.43),V(x,-36.8,z+i*.5),Color3.fromRGB(79,64,45),true);p.Material=Enum.Material.Wood end
  for _,dx in {-4,4} do
   for _,dz in {0,1.5} do pipe("BenchLeg",V(x+dx,-38.95,z+dz),V(x+dx,-36.9,z+dz),.18) end
   pipe("BenchBrace",V(x+dx,-37,z),V(x+dx,-37,z+1.5),.16)
  end
 end
 for _,row in {{-190,145},{-190,231}} do
  local x,z=row[1],row[2];local dz=z<188 and 1 or -1
  part("CoatHookRail",V(10,.5,.16),V(x,-33,z),dark)
  for j=-4,4,2 do
   pipe("CoatHook",V(x+j,-33,z),V(x+j,-33,z+dz*.5),.1)
   pipe("HookTip",V(x+j,-33,z+dz*.5),V(x+j,-32.75,z+dz*.5),.1)
  end
 end
 -- Server-controlled circuits; future switches/outages set Powered on either zone.
 local power=Instance.new("Folder");power.Name="PowerZones";power.Parent=out
 for _,n in {"Men","Women"} do local z=Instance.new("Folder");z.Name=n;z:SetAttribute("Powered",true);z:SetAttribute("FlickerEnabled",true);z.Parent=power end
 for _,group in {root.WashroomArt,complete} do
  for _,p in group:GetChildren() do
   if p:IsA("BasePart") and (p.Name=="Diffuser" or p.Name=="DeadDiffuser") then
    if math.abs(p.Position.Z-188)<3 then
     local dz=192-p.Position.Z
     for _,housing in group:GetChildren() do if housing.Name=="LightHousing" and (Vector3.new(housing.Position.X,0,housing.Position.Z)-Vector3.new(p.Position.X,0,p.Position.Z)).Magnitude<.1 then housing.Position+=V(0,0,dz) end end
     p.Position+=V(0,0,dz)
    end
    p:SetAttribute("PowerZone",p.Position.Z < 188 and "Men" or "Women")
    p:SetAttribute("RatedBrightness",2.8)
    p:SetAttribute("Flickers",(math.abs(p.Position.X+182)<.1 and math.abs(p.Position.Z-153)<.1) or (math.abs(p.Position.X+132)<.1 and math.abs(p.Position.Z-220)<.1))
    local l=p:FindFirstChildWhichIsA("SurfaceLight") or Instance.new("SurfaceLight")
    l.Face=Enum.NormalId.Bottom;l.Angle=120;l.Range=34;l.Brightness=2.8;l.Shadows=true;l.Color=Color3.fromRGB(202,213,190);l.Parent=p
    p.Material=Enum.Material.Neon;p.Color=Color3.fromRGB(189,201,178)
   end
  end
 end
 out:SetAttribute("Ready",true)
end
if not game:GetService("RunService"):IsRunning() then return end
while not out:GetAttribute("Ready") do task.wait() end
local players=game:GetService("Players")
-- Server validates every prompt and checks the leaf's swept volume for characters.
for _,m in out:GetChildren() do
 if m:IsA("Model") and m:GetAttribute("Hinge") then
  local prompt=m.Leaf.StallDoorPrompt;local busy=false;local last=0
  local hinge=m:GetAttribute("Hinge");local width=m:GetAttribute("Width")
  local function obstructed(angle)
   local chars={};for _,p in players:GetPlayers() do if p.Character then table.insert(chars,p.Character) end end
   local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=chars
   return #workspace:GetPartBoundsInBox(hinge*CFrame.Angles(0,angle,0)*CFrame.new(0,0,width/2),V(.35,7.4,width),params)>0
  end
  local function activate(player)
   local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local hrp=c and c:FindFirstChild("HumanoidRootPart")
   if busy or os.clock()-last<.7 or not h or h.Health<=0 or not hrp or (hrp.Position-m.Leaf.Position).Magnitude>9 then return end
   local wasOpen=m:GetAttribute("Open");local a=wasOpen and math.rad(-88) or 0;local b=wasOpen and 0 or math.rad(-88)
   for i=1,12 do if obstructed(a+(b-a)*i/12) then return end end
   busy=true;last=os.clock();prompt.Enabled=false
   local success=true
   for i=1,24 do
    local alpha=i/24;alpha=alpha*alpha*(3-2*alpha);local angle=a+(b-a)*alpha
    if obstructed(angle) then success=false;break end
    m:PivotTo(hinge*CFrame.Angles(0,angle,0));task.wait(.025)
   end
   if success then m:SetAttribute("Open",not wasOpen) else m:PivotTo(hinge*CFrame.Angles(0,a,0)) end
   prompt.ActionText=m:GetAttribute("Open") and "Close" or "Open";prompt.Enabled=true;busy=false
  end
  prompt.Triggered:Connect(activate)
  -- Server-only test seam; never exposed as a RemoteEvent.
  local test=Instance.new("BindableFunction");test.Name="ValidateAndToggle";test.OnInvoke=activate;test.Parent=m
 end
end
local rng=Random.new();local lamps={}
for _,group in {root.WashroomArt,complete} do for _,p in group:GetChildren() do if p:IsA("BasePart") and p:GetAttribute("PowerZone") then table.insert(lamps,{part=p,nextDip=os.clock()+rng:NextNumber(8,20),dipEnd=0}) end end end
task.spawn(function()
 while out.Parent do
  local now=os.clock()
  for _,entry in lamps do
   local p=entry.part;local zone=out.PowerZones[p:GetAttribute("PowerZone")];local powered=zone:GetAttribute("Powered")~=false
   if powered and p:GetAttribute("Flickers") and zone:GetAttribute("FlickerEnabled")~=false and now>=entry.nextDip then
    entry.dipEnd=now+.35;entry.nextDip=now+rng:NextNumber(12,25)
   end
   local dip=zone:GetAttribute("FlickerEnabled")~=false and now<entry.dipEnd
   local l=p:FindFirstChildWhichIsA("SurfaceLight");l.Enabled=powered;l.Brightness=p:GetAttribute("RatedBrightness")*(dip and .15 or 1)
   p.Material=powered and not dip and Enum.Material.Neon or Enum.Material.SmoothPlastic
   p.Color=powered and not dip and Color3.fromRGB(189,201,178) or Color3.fromRGB(66,72,66)
  end
  task.wait(.1)
 end
end)
