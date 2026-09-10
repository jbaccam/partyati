local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
local finish=art:WaitForChild("LibraryFinish")
while not finish:GetAttribute("Ready") do task.wait() end
if art:FindFirstChild("CornerPolish") then return end
local out=Instance.new("Model");out.Name="CornerPolish";out.Parent=art
local backup=Instance.new("Folder");backup.Name="LibraryLining_PreCorner_"..os.time();backup.Parent=game.ServerStorage
local wood=Color3.fromRGB(55,36,24)
local function p(n,s,pos,c,mat)
 local v=Instance.new("Part");v.Name=n;v.Size=s;v.Position=pos;v.Color=c or wood;v.Material=mat or Enum.Material.Wood;v.Anchored=true
 v.TopSurface=Enum.SurfaceType.Smooth;v.BottomSurface=Enum.SurfaceType.Smooth;v.Parent=out;return v
end
-- Rebuild lining with butt-jointed corners and inward-facing skirting on all sides.
for _,v in art:GetChildren()do if v.Name=="AgedPlaster" or v.Name=="Skirting" or v.Name=="DampStreak"then v.Parent=backup end end
local function wall(axis,fixed,a,b,inward)
 local mid=(a+b)/2;local length=b-a
 p("AgedPlaster",axis=="X" and Vector3.new(.3,16,length) or Vector3.new(length,16,.3),axis=="X" and Vector3.new(fixed,9,mid) or Vector3.new(mid,9,fixed),Color3.fromRGB(104,105,92),Enum.Material.Concrete)
 p("ContinuousSkirting",axis=="X" and Vector3.new(.28,.7,length) or Vector3.new(length,.7,.28),axis=="X" and Vector3.new(fixed+inward*.24,1.35,mid) or Vector3.new(mid,1.35,fixed+inward*.24))
end
wall("Z",-231.35,88.8,231.2,1);wall("X",231.35,-231.5,-88.5,-1)
for _,r in {{-231.5,-190},{-178,-126},{-114,-88.5}}do wall("X",88.65,r[1],r[2],1)end
for _,r in {{88.8,162},{174,231.2}}do wall("Z",-88.65,r[1],r[2],-1)end
for _,x in {88.9,231.1}do for _,z in {-231.1,-88.9}do p("CornerTrim",Vector3.new(.35,16,.35),Vector3.new(x,9,z))end end
-- Extend the existing full upright-book case along the return wall.
local transform=CFrame.new(230,0,-107.3)*CFrame.Angles(0,math.pi/2,0)*CFrame.new(-208,0,90.4)
local books={}
for _,v in finish:GetChildren()do
 local isBook=v:IsA("MeshPart") and math.abs(v.Position.Z+90.5)<.3
 if v.Name=="WallBookcaseShelf" or v.Name=="WallBookcaseUpright" or isBook then
  local c=v:Clone();c.Name=isBook and "UprightCornerBooks" or "ReturnBookcaseFrame";c.CFrame=transform*v.CFrame;c.Parent=out
  if isBook then table.insert(books,v) end
 end
end
-- Fill the short stretch between the existing south case and its return.
for _,y in {1.25,3.25,5.25,7.25,9.25,11.25}do p("CornerShelfExtension",Vector3.new(5.1,.3,1.8),Vector3.new(226.55,y,-90.4))end
for _,v in books do if v.Position.X>221 then
 for _,dx in {2.42,4.84}do local c=v:Clone();c.Name="UprightCornerBooks";c.Position+=Vector3.new(dx,0,0);c.Parent=out end
end end
-- READING LAMPS: the formerly empty corner needs its own visible light sources.
for _,x in {196,219}do
 p("ReadingLampBase",Vector3.new(.9,.12,.9),Vector3.new(x+3,4.68,-104),Color3.fromRGB(51,56,43),Enum.Material.Metal)
 p("ReadingLampStem",Vector3.new(.12,1.4,.12),Vector3.new(x+3,5.4,-104),Color3.fromRGB(51,56,43),Enum.Material.Metal)
 local shade=p("ReadingLampShade",Vector3.new(1.7,.45,1.1),Vector3.new(x+3,6.2,-104),Color3.fromRGB(62,73,46),Enum.Material.Metal)
 local light=Instance.new("PointLight");light.Brightness=.85;light.Range=20;light.Shadows=false;light.Color=Color3.fromRGB(218,203,159);light.Parent=shade
end
-- Scattered sheets: anchored, noncolliding, slight lift prevents floor flickering.
local rng=Random.new(939)
for i,r in {{185,-98},{213,-115},{227,-118},{137,-103},{120,-191},{179,-158},{198,-193},{99,-140},{202,-98},{190,-119},{131,-126},{214,-161}}do
 local cf=CFrame.new(r[1],1.035,r[2])*CFrame.Angles(0,rng:NextNumber(-2,2),0)
 local sheet=p("ScatteredPaper",Vector3.new(1.5,.025,2),cf.Position,Color3.fromRGB(164,157,135),Enum.Material.SmoothPlastic);sheet.CFrame=cf;sheet.CanCollide=false;sheet.CanTouch=false;sheet.CastShadow=false
 for line=1,4 do
  local mark=p("FadedPrint",Vector3.new(rng:NextNumber(.5,1.1),.007,.025),Vector3.zero,Color3.fromRGB(93,93,80),Enum.Material.SmoothPlastic)
  mark.CFrame=cf*CFrame.new(0,.017,-.55+line*.23);mark.CanCollide=false;mark.CanTouch=false;mark.CastShadow=false
 end
end
-- Gentle local fill, retaining contrast without entirely black aisle segments.
for _,x in {116,148,180,212}do for _,z in {-211,-177,-143,-105}do
 local anchor=p("LibraryReadabilityFill",Vector3.one,Vector3.new(x,10,z));anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
 local light=Instance.new("PointLight");light.Name="SoftBounce";light.Brightness=.42;light.Range=29;light.Color=Color3.fromRGB(173,181,160);light.Shadows=false;light.Parent=anchor
end end
-- Join the L case through the actual corner rather than stopping short.
for _,v in out:GetChildren() do
 if v.Name=="CornerShelfExtension" then
  v.Size=Vector3.new(6.9,.3,1.8);v.Position=Vector3.new(227.45,v.Position.Y,-90.4)
 elseif v.Name=="ReturnBookcaseFrame" and math.abs(v.Position.Z+91.5)<.05 then
  v.Size=Vector3.new(.35,10,.35);v.CFrame=CFrame.new(230.725,6.25,-89.675)
 elseif v.Name=="UprightCornerBooks" and v:IsA("MeshPart") then
  if math.abs(v.Position.Z+90.5)<.05 and math.abs(v.Position.X-227.18)<.05 then
   local c=v:Clone();c.Name="CornerEndBooks";c.Position=Vector3.new(229.5,v.Position.Y,-90.5);c.Parent=out
  elseif math.abs(v.Position.X-229.9)<.05 and math.abs(v.Position.Z+92.6)<.05 then
   v.Position=Vector3.new(v.Position.X,v.Position.Y,-92.16)
  end
 end
end
out:SetAttribute("CornerJoinFixed",true)
out:SetAttribute("Ready",true)
