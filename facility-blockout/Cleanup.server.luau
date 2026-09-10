-- Exact axis-aligned architectural union using compressed coordinates.
-- Produces ordinary Parts with non-overlapping volumes, not fragile overlapping wall patches.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("BasementReady") do task.wait() end
if root:GetAttribute("GeometryCleaned") then return end
local names={Wall=true,RoomBoundary=true,DoorwayHeader=true,StructuralInfill=true,Boundary=true,NorthBoundary=true,RoomSide=true,FrameWall=true,Header=true,AlcoveBack=true,AlcoveSide=true,EnclosedServiceVoid=true}
local boxes={}; local xs,zs,ys={},{},{}
local function add(set,n) set[math.round(n*1000)/1000]=true end
for _,v in root:GetDescendants() do
 if v:IsA("Part") and names[v.Name] then
  local s=v.Size
  if math.abs(v.CFrame.RightVector.Z)>.5 then s=Vector3.new(s.Z,s.Y,s.X) end
  -- Square off wall junctions by half a thickness before unioning.
  if s.X<=1.01 then s+=Vector3.new(0,0,1) elseif s.Z<=1.01 then s+=Vector3.new(1,0,0) end
  local a,b=v.Position-s/2,v.Position+s/2
  local box={a.X,b.X,a.Y,b.Y,a.Z,b.Z,v}; table.insert(boxes,box)
  add(xs,a.X); add(xs,b.X); add(ys,a.Y); add(ys,b.Y); add(zs,a.Z); add(zs,b.Z)
 end
end
local function sorted(set) local t={} for n in set do table.insert(t,n) end; table.sort(t); return t end
local x,z,y=sorted(xs),sorted(zs),sorted(ys)
local xi,zi={},{}; for i,n in x do xi[n]=i end; for i,n in z do zi[n]=i end
local output=Instance.new("Model"); output.Name="CleanArchitecture"
for k=1,#y-1 do
 local grid={}; local mid=(y[k]+y[k+1])/2
 for _,b in boxes do
  if mid>b[3] and mid<b[4] then
   for i=xi[math.round(b[1]*1000)/1000],xi[math.round(b[2]*1000)/1000]-1 do
    grid[i]=grid[i] or {}
    for j=zi[math.round(b[5]*1000)/1000],zi[math.round(b[6]*1000)/1000]-1 do grid[i][j]=true end
   end
  end
 end
 for i=1,#x-1 do for j=1,#z-1 do
  if grid[i] and grid[i][j] then
   local ie,je=i,j
   while grid[i][je+1] do je+=1 end
   while ie+1<#x do
    local ok=true; for t=j,je do if not grid[ie+1] or not grid[ie+1][t] then ok=false; break end end
    if not ok then break end; ie+=1
   end
   for a=i,ie do for b=j,je do grid[a][b]=nil end end
   local p=Instance.new("Part"); p.Name="WallSolid"; p.Anchored=true
   p.Size=Vector3.new(x[ie+1]-x[i],y[k+1]-y[k],z[je+1]-z[j])
   p.Position=Vector3.new((x[ie+1]+x[i])/2,mid,(z[je+1]+z[j])/2)
   p.Material=Enum.Material.SmoothPlastic; p.Color=Color3.fromRGB(140,145,148)
   p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=output
  end
 end end
end
-- Commit only after the replacement has been constructed successfully.
for _,b in boxes do b[7]:Destroy() end
output.Parent=root
-- Review labels shouldn't resemble texture patches on prop surfaces.
for _,v in root:GetDescendants() do if v:IsA("BillboardGui") then v.Enabled=false end end
root:SetAttribute("GeometryCleaned",true)
