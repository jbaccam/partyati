local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
while not art:WaitForChild("UnifiedFurniture"):GetAttribute("Ready")do task.wait()end
if art:FindFirstChild("FinalLibraryCorrections")then return end
local out=Instance.new("Model");out.Name="FinalLibraryCorrections";out.Parent=art
local backup=Instance.new("Folder");backup.Name="Library_PreFinalCorrections";backup.Parent=game.ServerStorage
-- Remove the unwanted west door, its frame and adjoining wall strips.
local door=root.Basement:FindFirstChild("Library West Door");if door then door.Parent=backup end
local sample
for _,p in art.AlignedEntrances:GetChildren()do
 if p.Name=="AlignedLibraryWall"then sample=sample or p:Clone()end
 if p:IsA("BasePart")and p.Position.Z> -178 then p.Parent=backup end
end
sample.Name="ContinuousWestWall";sample.Size=Vector3.new(1.3,16,90);sample.CFrame=CFrame.new(88.15,9,-133);sample.Parent=out
local function wood(n,s,pos)
 local p=Instance.new("Part");p.Name=n;p.Size=s;p.Position=pos;p.Anchored=true;p.Color=Color3.fromRGB(55,39,29);p.Material=Enum.Material.Wood;p.Parent=out;return p
end
wood("WestSkirtingRepair",Vector3.new(.28,.7,12),Vector3.new(88.89,1.35,-120))
-- South opening receives the same dark frame as the remaining west opening.
for _,x in {162.18,173.82}do wood("SouthDoorJamb",Vector3.new(.3,11,1.5),Vector3.new(x,6.5,-88))end
wood("SouthDoorLintel",Vector3.new(12.3,.35,1.5),Vector3.new(168,12.18,-88))
-- Fallen book mesh used elsewhere in this library, already lying flat.
local source
for _,p in art.LibraryFinish:GetDescendants()do
 if p:IsA("MeshPart")and p.Position.Y<2 and p.Name=="Old book"then source=p;break end
end
assert(source,"Missing reviewed horizontal floor-book mesh")
local function bounds(p)
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do local v=p.CFrame*Vector3.new(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2);lo=lo:Min(v);hi=hi:Max(v)end end end
 return lo,hi
end
local rng=Random.new(1774)
for _,shelf in art:GetChildren()do if shelf:IsA("Model")and shelf:GetAttribute("Fallen")then
 local cf=shelf:GetPivot();local direction=cf.RightVector.Y<0 and 1 or -1
 for _,group in shelf:GetDescendants()do if group:IsA("Model")and group.Name=="BookCluster"then
  local sum=Vector3.zero;local count=0
  for _,p in group:GetDescendants()do if p:IsA("BasePart")then sum+=p.Position;count+=1 end end
  if count>0 and cf:PointToObjectSpace(sum/count).X*direction>0 then group.Parent=backup end
 end end
 local pile=Instance.new("Model");pile.Name="FallenBookPiles";pile.Parent=out
 -- One irregular band nearer the standing case, with clearance below the lean.
 for row=0,8 do
  local offset=8+rng:NextNumber(-.22,.22)
  local x=cf.Position.X+direction*offset;local z=cf.Position.Z-10.3+row*2.55
  local height=0;local layers=rng:NextInteger(9,16)
  for layer=1,layers do
   local p=source:Clone();p.Name="FallenBook"
   local h=rng:NextNumber(.15,.24)
   local yaw=rng:NextNumber(-.32,.32)+(layer%4==0 and math.pi or 0)
   local sx=rng:NextNumber(1.55,2.05);local sz=rng:NextNumber(2.1,2.48)
   local desired=Vector3.new(sx,h,sz);local rot=p.CFrame.Rotation
   p.Size=Vector3.new((rot.RightVector*desired).Magnitude,(rot.UpVector*desired).Magnitude,(rot.LookVector*desired).Magnitude)
   p.CFrame=CFrame.new(x+rng:NextNumber(-.12,.12),1+height+h/2,z+rng:NextNumber(-.09,.09))*CFrame.Angles(0,yaw,0)*rot
   -- All eight corners must stay on the open side of the tilted shelf slab.
   local clear=true
   for bx=-1,1,2 do for by=-1,1,2 do for bz=-1,1,2 do
    local corner=p.CFrame*Vector3.new(bx*p.Size.X/2,by*p.Size.Y/2,bz*p.Size.Z/2)
    if cf:PointToObjectSpace(corner).X*direction<1.85 then clear=false end
   end end end
   if not clear then p:Destroy();break end
   height+=h
   p.Color=Color3.fromRGB(rng:NextInteger(130,190),rng:NextInteger(123,171),rng:NextInteger(110,153))
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.Parent=pile
  end
  local c=Instance.new("Part");c.Name="BookPileCollision";c.Size=Vector3.new(1.8,height,2.4);c.Position=Vector3.new(x,1+height/2,z);c.Transparency=1;c.Anchored=true;c.Parent=pile
 end
end end
out:SetAttribute("Ready",true)
