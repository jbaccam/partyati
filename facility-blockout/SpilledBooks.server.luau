local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
while not art:WaitForChild("SealedShelfUndercuts"):GetAttribute("Ready")do task.wait()end
if art:FindFirstChild("SpilledLibraryBooks")then return end
local out=Instance.new("Model");out.Name="SpilledLibraryBooks";out.Parent=art
local source
for _,p in art.LibraryFinish:GetDescendants()do if p:IsA("MeshPart")and p.Name=="Old book"and p.Position.Y<2 then source=p;break end end
assert(source,"Missing reviewed book mesh")
local rng=Random.new(60612)
local rot=source.CFrame.Rotation
for _,shelf in art:GetChildren()do if shelf:IsA("Model")and shelf:GetAttribute("Fallen")then
 local cf=shelf:GetPivot();local direction=cf.RightVector.Y<0 and 1 or -1
 -- Small offset heaps overlap loosely along the toe of the taller piles.
 for cluster=1,15 do
  local x=cf.Position.X+direction*rng:NextNumber(5.6,6.7)
  local z=cf.Position.Z+rng:NextNumber(-11,11)
  local count=rng:NextInteger(1,5);local base=1
  for layer=1,count do
   local h=rng:NextNumber(.12,.22);local desired=Vector3.new(rng:NextNumber(1.1,1.8),h,rng:NextNumber(1.5,2.2))
   local p=source:Clone();p.Name="SpilledBook"
   p.Size=Vector3.new((rot.RightVector*desired).Magnitude,(rot.UpVector*desired).Magnitude,(rot.LookVector*desired).Magnitude)
   local tilt=layer==1 and 0 or rng:NextNumber(-.06,.06)
   p.CFrame=CFrame.new(x+rng:NextNumber(-.35,.35),base+h/2+(layer==1 and .01 or .04),z+rng:NextNumber(-.45,.45))*CFrame.Angles(tilt,rng:NextNumber(-math.pi,math.pi),0)*rot
   local safe=true
   for bx=-1,1,2 do for by=-1,1,2 do for bz=-1,1,2 do
    local corner=p.CFrame*Vector3.new(bx*p.Size.X/2,by*p.Size.Y/2,bz*p.Size.Z/2)
    if cf:PointToObjectSpace(corner).X*direction<1.85 then safe=false end
   end end end
   if safe then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.Color=Color3.fromRGB(rng:NextInteger(125,190),rng:NextInteger(120,165),rng:NextInteger(108,150));p.Parent=out else p:Destroy()end
   base+=h*.82
  end
 end
end end
-- Break up the taller stacks' regular edges without moving them into the shelf.
for _,pile in art.FinalLibraryCorrections:GetChildren()do if pile.Name=="FallenBookPiles"then
 for _,p in pile:GetChildren()do if p:IsA("MeshPart")then
  p.CFrame=CFrame.new(p.Position+Vector3.new(0,0,rng:NextNumber(-.22,.22)))*CFrame.Angles(0,rng:NextNumber(-.15,.15),0)*p.CFrame.Rotation
 end end
end end
out:SetAttribute("Ready",true)
