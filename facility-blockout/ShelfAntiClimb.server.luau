local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
while art:GetAttribute("VariedShelvesVersion")~=1 do task.wait()end
if art:FindFirstChild("ShelfAntiClimb")then return end
local out=Instance.new("Model");out.Name="ShelfAntiClimb";out.Parent=art
-- Full-height vertical collision within each leaning shelf's footprint.
-- A vertical face cannot serve as a walkable ramp; ceiling-height closure
-- also prevents jumping from the debris onto the sloped mesh.
for _,shelf in art:GetChildren()do
 if shelf:IsA("Model")and shelf:GetAttribute("Fallen")then
  local proxy=shelf:FindFirstChild("CollisionProxy",true)
  assert(proxy,"Missing shelf collision proxy")
  local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=proxy.CFrame*Vector3.new(x*proxy.Size.X/2,y*proxy.Size.Y/2,z*proxy.Size.Z/2)
   lo=lo:Min(v);hi=hi:Max(v)
  end end end
  local p=Instance.new("Part");p.Name="VerticalShelfBarrier"
  p.Size=Vector3.new(hi.X-lo.X,16,hi.Z-lo.Z)
  p.CFrame=CFrame.new((lo.X+hi.X)/2,9,(lo.Z+hi.Z)/2)
  p.Anchored=true;p.Transparency=1;p.CanCollide=true;p.CanQuery=true;p.CanTouch=false
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
  p:SetAttribute("ShelfZ",shelf:GetPivot().Position.Z);p.Parent=out
 end
end
out:SetAttribute("Ready",true)
