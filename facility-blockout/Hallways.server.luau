-- Complete corridor kit, derived from the authoritative hall floors and wall faces.
-- Does not decorate room interiors or cut through bathroom separation walls.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("GeometryCleaned") do task.wait() end
local wash=root:WaitForChild("WashroomRefinement")
while not wash:GetAttribute("Ready") do task.wait() end
local out=root:FindFirstChild("Hallways")
local V=Vector3.new
if not out then
 out=Instance.new("Model");out.Name="Hallways";out.Parent=root
 local architecture=Instance.new("Model");architecture.Name="Finishes";architecture.Parent=out
 local furnishing=Instance.new("Model");furnishing.Name="WallFurniture";furnishing.Parent=out
 local lighting=Instance.new("Model");lighting.Name="Fixtures";lighting.Parent=out
 local circuits=Instance.new("Folder");circuits.Name="PowerZones";circuits.Parent=out
 local palette={wall=Color3.fromRGB(140,139,125),lower=Color3.fromRGB(84,99,89),trim=Color3.fromRGB(47,57,51),metal=Color3.fromRGB(89,95,89),wood=Color3.fromRGB(73,56,39),floor=Color3.fromRGB(94,100,94)}
 local function part(n,s,cf,c,mat,parent,collide)
  local p=Instance.new("Part");p.Name=n;p.Size=s;p.CFrame=typeof(cf)=="CFrame" and cf or CFrame.new(cf)
  p.Anchored=true;p.CanTouch=false;p.CanCollide=collide==true;p.Color=c or palette.metal;p.Material=mat or Enum.Material.SmoothPlastic
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.CastShadow=collide==true or n=="AcousticCeiling" or n=="StairwellTop";p.Parent=parent or architecture;return p
 end
 local function tube(n,a,b,diameter,parent,c)
  local p=part(n,V((b-a).Magnitude,diameter,diameter),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),c or palette.metal,Enum.Material.Metal,parent)
  p.Shape=Enum.PartType.Cylinder;return p
 end
 local function textSign(cf,title,subtitle,width,parent)
  local board=part("EnamelSign",V(width or 6,1.65,.15),cf,palette.trim,nil,parent)
  local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(600,165);gui.Parent=board
  local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(.94,.9);label.Position=UDim2.fromScale(.03,.05);label.BackgroundTransparency=1;label.Text=title..(subtitle and "\n"..subtitle or "");label.TextColor3=Color3.fromRGB(210,210,187);label.TextScaled=true;label.Font=Enum.Font.GothamMedium;label.Parent=gui
 end
 local function grain(p,face)
  local t=Instance.new("Texture");t.Name="FinePlaster";t.Texture="rbxassetid://762795527";t.Face=face;t.StudsPerTileU=8;t.StudsPerTileV=8;t.Transparency=.72;t.Color3=Color3.fromRGB(170,168,151);t.Parent=p
 end
 local cells={};local ordered={}
 for _,p in root:GetChildren() do if p:IsA("BasePart") and p.Name=="Floor_Hall" then
  local ix,iz=math.round(p.Position.X/16),math.round(p.Position.Z/16);local key=ix..":"..iz
  cells[key]={x=ix,z=iz,service=p.Name=="Floor_ServiceHall"};table.insert(ordered,cells[key])
  p.Color=palette.floor;p.Material=Enum.Material.Concrete
 end end
 table.sort(ordered,function(a,b) return a.x==b.x and a.z<b.z or a.x<b.x end)
 local basementRects={{-256,124,256,144},{-256,232,256,252},{-256,144,-240,232},{-80,144,-60,232},{92,144,112,232},{240,144,256,232},{-232,104,-216,124},{200,104,216,124}}
 local function isHall(x,z,floor)
  if floor==1 then return cells[math.floor((x+8)/16)..":"..math.floor((z+8)/16)]~=nil end
  for _,r in basementRects do if x>r[1] and x<r[3] and z>r[2] and z<r[4] then return true end end
  return false
 end
 local function circuit(x,z,floor)
  if floor<0 then return z<144 and "BasementNorth" or z>232 and "BasementSouth" or x<0 and "BasementWest" or "BasementEast" end
  return (z<0 and "MainNorth" or "MainSouth")..(x<0 and "West" or "East")
 end
 local function getCircuit(name)
  if not circuits:FindFirstChild(name) then local f=Instance.new("Folder");f.Name=name;f:SetAttribute("Powered",true);f:SetAttribute("FlickerEnabled",true);f.Parent=circuits end
 end
 -- Greedy rectangles share continuous surfaces; no 16-stud shaded floor patchwork.
 local used={};local rectangles={}
 for _,c in ordered do if not used[c.x..":"..c.z] then
  local xe,ze=c.x,c.z
  while cells[(xe+1)..":"..c.z] and not used[(xe+1)..":"..c.z] do xe+=1 end
  while true do local good=true;for x=c.x,xe do if not cells[x..":"..(ze+1)] or used[x..":"..(ze+1)] then good=false;break end end;if not good then break end;ze+=1 end
  for x=c.x,xe do for z=c.z,ze do used[x..":"..z]=true end end
  table.insert(rectangles,{c.x*16-8,c.z*16-8,xe*16+8,ze*16+8,1})
 end end
 for _,r in basementRects do table.insert(rectangles,{r[1],r[2],r[3],r[4],-39}) end
 for _,r in rectangles do
  local x,z=(r[1]+r[3])/2,(r[2]+r[4])/2;local w,d=r[3]-r[1],r[4]-r[2];local f=r[5]
  local surface=part("ContinuousCorridorFloor",V(w,.04,d),V(x,f+.025,z),f<0 and Color3.fromRGB(88,94,87) or palette.floor,Enum.Material.Concrete)
  surface.CastShadow=false
  part("AcousticCeiling",V(w,.5,d),V(x,f+15.55,z),Color3.fromRGB(79,83,74),Enum.Material.Concrete)
  for xx=r[1]+4,r[3]-.1,4 do local p=part("CeilingGrid",V(.055,.06,d),V(xx,f+15.27,z),palette.trim,Enum.Material.Metal);p.CastShadow=false end
  for zz=r[2]+8,r[4]-.1,8 do local p=part("CeilingGrid",V(w,.06,.055),V(x,f+15.27,zz),palette.trim,Enum.Material.Metal);p.CastShadow=false end
 end
 -- Surface only the hall-facing side of actual solid architecture, preserving openings.
 local spans={}
 local wallParts=root.CleanArchitecture:GetChildren()
 local library=root:FindFirstChild("LibraryArt")
 if library then
  for _,g in {library:FindFirstChild("AlignedEntrances"),library:FindFirstChild("FinalLibraryCorrections")} do
   if g then for _,p in g:GetChildren() do if p.Name=="AlignedLibraryWall" or p.Name=="ContinuousWestWall" then table.insert(wallParts,p) end end end
  end
 end
 for _,wall in wallParts do if wall:IsA("BasePart") then
  local lo,hi=wall.Position-wall.Size/2,wall.Position+wall.Size/2
  for _,floor in {1,-39} do if lo.Y<=floor+2 and hi.Y>=floor+3 then
   for _,face in {{"X",lo.X,-1,lo.Z,hi.Z},{"X",hi.X,1,lo.Z,hi.Z},{"Z",lo.Z,-1,lo.X,hi.X},{"Z",hi.Z,1,lo.X,hi.X}} do
    local axis,fixed,sign,a,b=table.unpack(face);local start=nil;local step=math.min(2,b-a)
    if step>=.2 then
     local count=math.ceil((b-a)/step)
     for i=0,count do
      local at=a+(b-a)*i/count;local mid=a+(b-a)*(i+.5)/count
      local inside=i<count and isHall(axis=="X" and fixed+sign*.6 or mid,axis=="Z" and fixed+sign*.6 or mid,floor)
      if inside and not start then start=at end
      if not inside and start then
       local length=at-start
       if length>1 then
        local center=(at+start)/2
        local yaw=axis=="X" and sign*math.pi/2 or sign==-1 and math.pi or 0
        local cf=CFrame.new(axis=="X" and fixed+sign*.025 or center,floor,axis=="Z" and fixed+sign*.025 or center)*CFrame.Angles(0,yaw,0)
        part("PaintedWainscot",V(length,4.3,.045),cf*CFrame.new(0,2.15,0),palette.lower)
        local upper=part("PlasterFinish",V(length,11.05,.045),cf*CFrame.new(0,9.825,0),palette.wall,Enum.Material.Concrete);grain(upper,Enum.NormalId.Back)
        part("Skirting",V(length,.4,.14),cf*CFrame.new(0,.23,.045),palette.trim)
        part("ChairRail",V(length,.14,.18),cf*CFrame.new(0,4.34,.07),palette.trim,Enum.Material.Wood)
        part("CeilingCove",V(length,.25,.18),cf*CFrame.new(0,15.18,.07),palette.trim)
        table.insert(spans,{cf=cf,length=length,floor=floor})
       end
       start=nil
      end
     end
    end
   end
  end end
 end end
 -- Compressed architecture merges headers into long strips. Pair adjacent wall
 -- runs to recover each real doorway instead of assuming a 12-stud header Part.
 local framed={}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=wallParts
 for _,a in spans do for _,b in spans do
  if a~=b and a.floor==b.floor and a.cf.LookVector:Dot(b.cf.LookVector)>.999 then
   local relative=a.cf:PointToObjectSpace(b.cf.Position)
   local gap=relative.X-(a.length+b.length)/2
   if math.abs(relative.Z)<.06 and gap>=10 and gap<=13 then
    local cf=a.cf*CFrame.new(a.length/2+gap/2,0,0)
    local key=math.round(cf.X*10)..":"..math.round(cf.Z*10)..":"..a.floor
    local mid=(cf*CFrame.new(0,4,0)).Position
    if not framed[key] and #workspace:GetPartBoundsInBox(CFrame.new(mid),V(.4,.4,.4),params)==0 then
     framed[key]=true
     for _,dx in {-gap/2,gap/2} do part("FinishedDoorJamb",V(.2,11,.2),cf*CFrame.new(dx,5.5,.1),palette.trim,Enum.Material.Metal) end
     part("FinishedDoorLintel",V(gap+.2,.2,.2),cf*CFrame.new(0,11,.1),palette.trim,Enum.Material.Metal)
     local header=part("DoorHeaderFinish",V(gap,4.25,.05),cf*CFrame.new(0,13.15,0),palette.wall,Enum.Material.Concrete);grain(header,Enum.NormalId.Back)
     part("DoorThreshold",V(gap,.025,1.2),cf*CFrame.new(0,.06,.25),palette.metal,Enum.Material.Metal)
    end
   end
  end
 end end
 -- Explicit functional thresholds receive matching trim on the corridor side.
 for _,w in root.CleanArchitecture:GetChildren() do if w:IsA("BasePart") then
  local low=w.Position.Y-w.Size.Y/2;local floor=math.abs(low-12)<.1 and 1 or math.abs(low+28)<.1 and -39 or nil
  if floor and math.min(w.Size.X,w.Size.Z)<1.1 and math.max(w.Size.X,w.Size.Z)<=13 then
   local alongX=w.Size.X>w.Size.Z;local width=math.max(w.Size.X,w.Size.Z)
   for _,sign in {-1,1} do
    local x,z=w.Position.X+(alongX and 0 or sign*.65),w.Position.Z+(alongX and sign*.65 or 0)
    if isHall(x,z,floor) then
     local cf=CFrame.new(x,floor,z)*CFrame.Angles(0,alongX and (sign==1 and 0 or math.pi) or sign*math.pi/2,0)
     for _,dx in {-width/2,width/2} do part("DoorJamb",V(.22,11,.18),cf*CFrame.new(dx,5.5,0),palette.trim,Enum.Material.Metal) end
     part("DoorLintel",V(width+.22,.22,.18),cf*CFrame.new(0,11,0),palette.trim,Enum.Material.Metal)
    end
   end
  end
 end end
 local function furnitureFrame(cf,name)
  local m=Instance.new("Model");m.Name=name;m.Parent=furnishing
  local function p(n,s,pos,c,mat,collide) return part(n,s,cf*CFrame.new(pos),c,mat,m,collide) end
  local function rod(n,a,b,d,c) return tube(n,cf:PointToWorldSpace(a),cf:PointToWorldSpace(b),d,m,c) end
  return m,p,rod
 end
 local function bench(cf)
  local m,p,rod=furnitureFrame(cf,"InstitutionalBench")
  for i=0,3 do p("SeatSlat",V(7,.16,.43),V(0,2,.8+i*.48),palette.wood,Enum.Material.Wood,true) end
  for i=0,2 do p("BackSlat",V(7,.45,.16),V(0,2.55+i*.5,.55),palette.wood,Enum.Material.Wood) end
  for _,x in {-2.8,2.8} do
   rod("RearFrame",V(x,.1,.5),V(x,3.9,.5),.17);rod("FrontLeg",V(x,.1,2.4),V(x,2,2.4),.17)
   rod("SeatFrame",V(x,1.85,.5),V(x,1.85,2.4),.17)
   rod("ArmUpright",V(x,2,2.2),V(x,2.9,2.2),.14);rod("ArmRest",V(x,2.9,.6),V(x,2.9,2.2),.18)
   for _,z in {.5,2.4} do p("RubberFoot",V(.3,.13,.3),V(x,.09,z),palette.trim) end
  end
 end
 local function radiator(cf)
  local m,p,rod=furnitureFrame(cf,"CastRadiator")
  for i=-5,5 do
   local a=p("RoundedFin",V(.3,2.45,.8),V(i*.43,1.6,.65),Color3.fromRGB(129,130,116),Enum.Material.Metal)
   local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=a
   rod("FinCore",V(i*.43,.5,.65),V(i*.43,2.7,.65),.27,Color3.fromRGB(129,130,116))
  end
  for _,y in {.7,2.5} do rod("Manifold",V(-2.4,y,.65),V(2.4,y,.65),.22) end
  rod("SupplyPipe",V(-2.65,.15,.3),V(-2.65,1,.3),.15);rod("SupplyElbow",V(-2.65,1,.3),V(-2.2,1,.65),.15)
  local valve=p("ValveWheel",V(.12,.45,.45),V(-2.65,1.25,.3),palette.trim,Enum.Material.Metal);valve.Shape=Enum.PartType.Cylinder
  for _,x in {-1.8,1.8} do p("Foot",V(.3,.4,.8),V(x,.2,.65),palette.metal,Enum.Material.Metal) end
 end
 local function notice(cf)
  local m,p=furnitureFrame(cf,"Noticeboard")
  p("Frame",V(6,3.6,.18),V(0,6,.1),palette.wood,Enum.Material.Wood)
  p("Cork",V(5.7,3.3,.06),V(0,6,.23),Color3.fromRGB(103,100,78),Enum.Material.Fabric)
  for i,pos in {{-1.7,6.5},{0,5.7},{1.7,6.3}} do
   local sheet=p("Notice",V(1.25,1.65,.015),V(pos[1],pos[2],.275),Color3.fromRGB(177-i*4,175-i*4,150-i*3))
   local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(160,220);gui.Parent=sheet
   local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(.9,.9);t.Position=UDim2.fromScale(.05,.05);t.BackgroundTransparency=1;t.Text=({"VISITING HOURS\n\n09:00 — 17:00\n\nReport to reception","MAINTENANCE\n\nKeep access clear\n\nFacilities Office","WARD NOTICE\n\nDaily schedule\n\nSee duty staff"})[i];t.TextColor3=Color3.fromRGB(60,66,59);t.TextScaled=true;t.Font=Enum.Font.SourceSans; t.Parent=gui
   p("Pin",V(.06,.06,.04),V(pos[1],pos[2]+.65,.31),palette.trim)
  end
 end
 local function trolley(cf)
  local m,p,rod=furnitureFrame(cf,"ParkedLinenTrolley")
  for _,x in {-1.7,1.7} do for _,z in {.6,2.4} do
   rod("FrameTube",V(x,.4,z),V(x,3.5,z),.13)
   local wheel=p("Caster",V(.18,.55,.55),V(x,.3,z),palette.trim);wheel.Shape=Enum.PartType.Cylinder
  end end
  for _,y in {1,2.8} do
   p("Tray",V(3.6,.1,2),V(0,y,1.5),palette.metal,Enum.Material.Metal,true)
   for _,z in {.5,2.5} do p("TrayLip",V(3.6,.2,.06),V(0,y+.12,z),palette.metal,Enum.Material.Metal) end
  end
  rod("PushBar",V(-1.7,3.5,2.4),V(1.7,3.5,2.4),.15)
  for i=0,3 do p("FoldedLinen",V(2.5,.17,1.4),V(.1*(i%2),2.95+i*.18,1.5),Color3.fromRGB(154-i*3,157-i*3,141-i*2),Enum.Material.Fabric) end
 end
 local function cabinet(cf)
  local m,p=furnitureFrame(cf,"ServiceCabinet")
  p("CabinetBody",V(3,4.6,.65),V(0,2.6,.4),palette.lower,Enum.Material.Metal,true)
  p("InsetDoor",V(2.76,4.3,.08),V(0,2.6,.77),palette.metal,Enum.Material.Metal)
  p("Pull",V(.12,.5,.18),V(1,2.6,.9),palette.trim,Enum.Material.Metal)
  for i=0,5 do p("Louver",V(1.8,.04,.04),V(0,3.7-i*.14,.83),palette.trim) end
  textSign(cf*CFrame.new(0,5.5,.1),"SERVICE",nil,3,m)
 end
 -- A sparse rhythm of functional wall furniture; nothing is placed at junction centers.
 local placements={};local count=0
 for _,s in spans do if s.length>=18 then
  local n=math.max(1,math.floor(s.length/58))
  for i=1,n do
   local cf=s.cf*CFrame.new((i-(n+1)/2)*(s.length/n),0,.12);local pos=cf.Position;local clear=true
   for _,other in placements do if math.abs(pos.Y-other.Y)<2 and (pos-other).Magnitude<30 then clear=false;break end end
   -- Entire 8x3 furnishing footprint must remain inside corridor floors.
   for _,dx in {-4.2,4.2} do for _,dz in {.4,3.3} do local a=cf:PointToWorldSpace(V(dx,0,dz));if not isHall(a.X,a.Z,s.floor) then clear=false end end end
   if clear then
    count+=1;table.insert(placements,pos)
    local choice=count%7
    if choice==0 or choice==4 then bench(cf)
    elseif choice==1 or choice==5 then radiator(cf)
    elseif choice==2 then notice(cf)
    elseif choice==3 then cabinet(cf)
    else trolley(cf) end
   end
  end
 end end
 -- Downward fixtures with real shadow occlusion; room circuits remain independent.
 local lampPositions={};local lampCount=0
 local function lamp(x,z,floor,overrideY,zoneOverride)
  local zone=zoneOverride or circuit(x,z,floor);getCircuit(zone);lampCount+=1
  local y=overrideY or floor+14.95
  part("FluorescentHousing",V(2.8,.25,6),V(x,y,z),palette.metal,Enum.Material.Metal,lighting)
  local bulb=part("HallDiffuser",V(2.45,.12,5.6),V(x,y-.19,z),Color3.fromRGB(198,205,180),Enum.Material.Neon,lighting)
  bulb:SetAttribute("PowerZone",zone);bulb:SetAttribute("RatedBrightness",3.8);bulb:SetAttribute("Flickers",lampCount%13==0)
  local l=Instance.new("SurfaceLight");l.Face=Enum.NormalId.Bottom;l.Angle=105;l.Range=34;l.Brightness=3.8;l.Color=Color3.fromRGB(204,211,187);l.Shadows=true;l.Parent=bulb
  for _,dx in {-1.25,1.25} do part("DiffuserFrame",V(.06,.15,5.7),V(x+dx,y-.2,z),palette.trim,Enum.Material.Metal,lighting) end
 end
 for _,c in ordered do
  local xa,xb,za,zb=c.x,c.x,c.z,c.z
  while cells[(xa-1)..":"..c.z] do xa-=1 end
  while cells[(xb+1)..":"..c.z] do xb+=1 end
  while cells[c.x..":"..(za-1)] do za-=1 end
  while cells[c.x..":"..(zb+1)] do zb+=1 end
  local pos=xb-xa<zb-za and V((xa+xb)*8,1,c.z*16) or V(c.x*16,1,(za+zb)*8);local near=false
  for _,p in lampPositions do if (p-pos).Magnitude<29 then near=true;break end end
  if not near then table.insert(lampPositions,pos);lamp(pos.X,pos.Z,1) end
 end
 for _,r in basementRects do
  local w,d=r[3]-r[1],r[4]-r[2];local n=math.max(1,math.ceil(math.max(w,d)/30))
  for i=1,n do lamp(w>d and r[1]+w*(i-.5)/n or (r[1]+r[3])/2,w>d and (r[2]+r[4])/2 or r[2]+d*(i-.5)/n,-39) end
 end
 -- Both service stairways receive sloped ceilings and continuous tubular handrails.
 for _,x in {-224,208} do
  local zone=x<0 and "WestStairs" or "EastStairs";getCircuit(zone)
  -- Enclose the removed-floor strip as a stairwell, not a slot open to the sky.
  part("StairwellTop",V(17,.5,97),V(x,16.55,72),Color3.fromRGB(79,83,74),Enum.Material.Concrete)
  for _,side in {-1,1} do
   part("StairwellSide",V(.8,40,96),V(x+side*8,-19,72),palette.wall,Enum.Material.Concrete,architecture,true)
   part("StairEntranceSide",V(.8,15.3,24),V(x+side*8,8.65,36),palette.wall,Enum.Material.Concrete,architecture,true)
   part("UpperStairSkirting",V(.12,.4,24),V(x+side*7.5,1.23,36),palette.trim)
  end
  part("StairEntranceBack",V(16.8,15.3,.8),V(x,8.65,48),palette.wall,Enum.Material.Concrete,architecture,true)
  part("RestoredFloorBehindStairs",V(16,1,72),V(x,.5,84),palette.floor,Enum.Material.Concrete,architecture,true)
  part("BasementLanding",V(16,1,20),V(x,-39.5,114),palette.floor,Enum.Material.Concrete,architecture,true)
  part("StairwellEndAboveLanding",V(17,24,.8),V(x,-11,120),palette.wall,Enum.Material.Concrete,architecture,true)
  for _,side in {-1,1} do
   tube("StairHandrail",V(x+side*6.8,4,24),V(x+side*6.8,-36,104),.22,architecture)
   for z=28,100,12 do
    local floor=1-(z-24)*.5
    tube("RailStanchion",V(x+side*6.8,floor+.1,z),V(x+side*6.8,floor+3,z),.14,architecture)
   end
  end
  for _,z in {36,64,92} do lamp(x,z,1,z==36 and 14.8 or -.8,zone) end
  part("StairEntranceHeader",V(16.8,3,.8),V(x,15,24),palette.wall,Enum.Material.Concrete,architecture,true)
  textSign(CFrame.new(x,14.8,23.5)*CFrame.Angles(0,math.pi,0),"BASEMENT",x<0 and "WEST STAIR" or "EAST STAIR",8,architecture)
  for _,p in root.Basement:GetChildren() do if p.Name=="StairTread" and math.abs(p.Position.X-x)<1 then
   p.Color=Color3.fromRGB(86,92,86);p.Material=Enum.Material.Concrete
   part("AntiSlipNosing",V(14.5,.025,.12),V(x,p.Position.Y+.512,p.Position.Z-.36),palette.trim,Enum.Material.Metal)
  elseif p.Name=="StairGuard" and math.abs(p.Position.X-x)<10 then p.Transparency=1;p.CanCollide=false end end
 end
 -- Suspended location markers at corridor junctions, above head clearance.
 local markers={{-120,-160,"WEST WING","MEDICAL / RESIDENTIAL"},{72,-160,"EAST WING","LIBRARY / ADMINISTRATION"},{-120,80,"WEST CORRIDOR","RESIDENTIAL / STORAGE"},{72,80,"EAST CORRIDOR","SECURITY / SERVICE HALL"},{0,152,"SOUTH CORRIDOR","RECEPTION"},{176,64,"SERVICE HALL","EAST STAIR"}}
 for _,r in markers do if isHall(r[1],r[2],1) then
  textSign(CFrame.new(r[1],12.5,r[2]),r[3],r[4],10,architecture)
  for _,dx in {-4,4} do tube("SignSuspension",V(r[1]+dx,13.35,r[2]),V(r[1]+dx,16.25,r[2]),.05,architecture) end
 end end
 out:SetAttribute("HallFloorCells",#ordered);out:SetAttribute("BasementHallRuns",#basementRects);out:SetAttribute("WallFinishRuns",#spans);out:SetAttribute("FurnitureGroups",count);out:SetAttribute("LightFixtures",lampCount)
 out:SetAttribute("Ready",true)
end
if not game:GetService("RunService"):IsRunning() then return end
while not out:GetAttribute("Ready") do task.wait() end
local rng=Random.new();local lights={}
for _,p in out.Fixtures:GetChildren() do if p:GetAttribute("PowerZone") then table.insert(lights,{p=p,nextDip=os.clock()+rng:NextNumber(10,35),dipEnd=0}) end end
task.spawn(function()
 while out.Parent do
  local now=os.clock()
  for _,e in lights do
   local p=e.p;local zone=out.PowerZones[p:GetAttribute("PowerZone")];local powered=zone:GetAttribute("Powered")~=false
   if powered and p:GetAttribute("Flickers") and zone:GetAttribute("FlickerEnabled")~=false and now>=e.nextDip then e.dipEnd=now+.3;e.nextDip=now+rng:NextNumber(18,35) end
   local dim=zone:GetAttribute("FlickerEnabled")~=false and now<e.dipEnd
   local l=p:FindFirstChildWhichIsA("SurfaceLight");l.Enabled=powered;l.Brightness=p:GetAttribute("RatedBrightness")*(dim and .18 or 1)
   p.Material=powered and not dim and Enum.Material.Neon or Enum.Material.SmoothPlastic;p.Color=powered and not dim and Color3.fromRGB(198,205,180) or Color3.fromRGB(63,70,63)
  end
  task.wait(.12)
 end
end)
