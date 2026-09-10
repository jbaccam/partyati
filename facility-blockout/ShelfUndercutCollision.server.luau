local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
while not art:WaitForChild("FinalLibraryCorrections"):GetAttribute("Ready")do task.wait()end
if art:FindFirstChild("SealedShelfUndercuts")then return end
local out=Instance.new("Model");out.Name="SealedShelfUndercuts";out.Parent=art
-- Collision fills the triangular void up to the leaning shelf's underside.
-- The visible piles remain irregular; their tops are no longer a bypass.
for _,shelf in art:GetChildren()do if shelf:IsA("Model")and shelf:GetAttribute("Fallen")then
 local cf=shelf:GetPivot();local direction=cf.RightVector.Y<0 and 1 or -1
 local group=Instance.new("Model");group.Name="BlockedUndercut";group.Parent=out
 for i=0,18 do
  local offset=1.05+i*.5
  local top=cf.Position.Y+offset-1.6*math.sqrt(2)+.4
  local height=math.max(.2,top-1)
  local p=Instance.new("Part");p.Name="UnderShelfCollision";p.Size=Vector3.new(.52,height,24)
  p.Position=Vector3.new(cf.Position.X+direction*offset,1+height/2,cf.Position.Z)
  p.Anchored=true;p.Transparency=1;p.CanCollide=true;p.CanTouch=false;p.CanQuery=true;p.Parent=group
 end
end end
out:SetAttribute("Ready",true)
