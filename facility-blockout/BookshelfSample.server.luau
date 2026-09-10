-- Six deterministic detailed variants throughout the library.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("LibraryArtReady") do task.wait() end
local art=root.LibraryArt
if art:GetAttribute("VariedShelvesVersion")==1 then return end
local storage=game:GetService("ServerStorage")
local bay=storage:WaitForChild("BookshelfBay")
local heights={.964,3.053,4.919,6.578,8.254,9.790,11.22}
local groups,pool,frame={},{},{}
for _,p in bay:GetDescendants() do if p:IsA("BasePart") then
 if p.Material==Enum.Material.Wood then table.insert(frame,p)
 else
  local y=p.Position.Y;local row=y<2.7 and 1 or y<4.6 and 2 or y<6.3 and 3 or y<8 and 4 or y<9.6 and 5 or 6
  local key=row..":"..(p.Position.Z< -9 and 1 or 2)
  if not groups[key] then local m=Instance.new("Model");m.Name="BookCluster";groups[key]=m;table.insert(pool,m) end
  p:Clone().Parent=groups[key]
 end
end end
local variants=Instance.new("Folder");variants.Name="BookshelfVariants";variants.Parent=storage
for variant=1,6 do
 local rng=Random.new(7230+variant*101);local master=Instance.new("Model");master.Name="BookshelfVariant"..variant
 for side=0,1 do for index=0,3 do
  local unit=Instance.new("Model");unit.Name="CabinetBay"
  for _,p in frame do p:Clone().Parent=unit end
  local slots={};for row=1,6 do for col=1,2 do table.insert(slots,{row,col}) end end
  for i=#slots,2,-1 do local j=rng:NextInteger(1,i);slots[i],slots[j]=slots[j],slots[i] end
  for i=1,rng:NextInteger(8,11) do
   local cluster=pool[rng:NextInteger(1,#pool)]:Clone()
   -- Mesh axes differ from shelf axes; fit against world-aligned bounds.
   local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
   for _,p in cluster:GetDescendants()do if p:IsA("BasePart")then
    for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
     local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2);low=low:Min(v);high=high:Max(v)
    end end end
   end end
   local cf=CFrame.new((low+high)/2);local size=high-low
   local row,col=slots[i][1],slots[i][2]
   local scale=math.min(1,(heights[row+1]-heights[row]-.16)/size.Y,2.48/size.Z,1.4/size.X)
   local destination=Vector3.new(-.82,heights[row]+.035+size.Y*scale/2,col==1 and -10.35 or -7.62)
   local tint=rng:NextNumber(.82,1)
   for _,p in cluster:GetDescendants() do if p:IsA("BasePart") then
    p.CFrame=CFrame.new(destination+(p.Position-cf.Position)*scale)*p.CFrame.Rotation;p.Size*=scale
    p.Color=Color3.new(p.Color.R*tint,p.Color.G*tint,p.Color.B*tint);p.CanCollide=false;p.CanTouch=false;p.CastShadow=false
    for _,c in p:GetChildren()do if c:IsA("SpecialMesh")then c.Scale*=scale end end
   end end
   cluster.Parent=unit
  end
  local transform=side==0 and CFrame.new(0,0,index*6) or CFrame.new(0,0,-18+index*6)*CFrame.Angles(0,math.pi,0)
  for _,p in unit:GetDescendants()do if p:IsA("BasePart")then p.CFrame=transform*p.CFrame end end
  unit.Parent=master
 end end
 local p=Instance.new("Part");p.Name="CollisionProxy";p.Size=Vector3.new(3.2,11.7,24);p.Position=Vector3.new(0,5.85,0);p.Anchored=true;p.Transparency=1;p.Parent=master
 master.WorldPivot=CFrame.new();master:SetAttribute("Variant",variant);master.Parent=variants
end
for _,m in pool do m:Destroy() end
local backup=Instance.new("Folder");backup.Name="LibraryShelves_PreVariety_"..os.time();backup.Parent=storage
local replaced=0
for _,old in art:GetChildren()do
 local back=old:FindFirstChild("Backboard")
 if back or old.Name=="BookshelfMasterSample" then
  local cf=back and back.CFrame*CFrame.new(0,-6,0) or old:GetPivot()
  local v=(replaced*5+math.floor(cf.Position.Z/34))%6+1
  local m=variants["BookshelfVariant"..v]:Clone();m.Name="DetailedBookshelf"
  m:SetAttribute("Fallen",old:GetAttribute("Fallen")==true)
  for _,a in {"LeanDegrees","LeanDirection"}do m:SetAttribute(a,old:GetAttribute(a))end
  m:PivotTo(cf);m.Parent=art;old.Parent=backup;replaced+=1
 end
end
art:SetAttribute("VariedShelvesVersion",1);art:SetAttribute("DetailedShelfCount",replaced)
