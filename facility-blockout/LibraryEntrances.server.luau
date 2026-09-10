local root=workspace:WaitForChild("FacilityLayoutReview")
local art=root:WaitForChild("LibraryArt")
local refined=art:WaitForChild("LibraryRefinement")
while not refined:GetAttribute("Ready") do task.wait() end
if art:FindFirstChild("AlignedEntrances") then return end
local out=Instance.new("Model");out.Name="AlignedEntrances";out.Parent=art
local backup=Instance.new("Folder");backup.Name="Library_PreEntranceAlignment";backup.Parent=game.ServerStorage
local sample=art.CornerPolish:FindFirstChild("AgedPlaster"):Clone()
-- Replace only the west library wall span; keep neighboring rooms intact.
for _,p in root.CleanArchitecture:GetChildren() do
 if p:IsA("BasePart") and math.abs(p.Position.X-88)<.05 then
  local a,b=p.Position.Z-p.Size.Z/2,p.Position.Z+p.Size.Z/2
  if b> -232 and a< -88 then
   for _,range in {{a,math.min(b,-232)},{math.max(a,-88),b}} do
    if range[2]>range[1] then local c=p:Clone();c.Size=Vector3.new(p.Size.X,p.Size.Y,range[2]-range[1]);c.Position=Vector3.new(p.Position.X,p.Position.Y,(range[1]+range[2])/2);c.Parent=root.CleanArchitecture end
   end
   p.Parent=backup
  end
 end
end
for _,p in art.CornerPolish:GetChildren() do
 if p:IsA("BasePart") and p.Name=="AgedPlaster" and math.abs(p.Position.X-88.65)<.05 then p.Parent=backup end
end
local function wall(z,length,y,height)
 local p=sample:Clone();p.Name="AlignedLibraryWall";p.Size=Vector3.new(1.3,height,length);p.CFrame=CFrame.new(88.15,y,z);p.Parent=out
 -- Only retain the current subtle finish; make both sides consistent.
 for _,v in p:GetChildren() do v:Destroy() end
 for _,face in {Enum.NormalId.Left,Enum.NormalId.Right}do local t=Instance.new("Texture");t.Name="SubtleWallGrain";t.Texture="rbxassetid://762795527";t.Face=face;t.StudsPerTileU=8;t.StudsPerTileV=8;t.Color3=Color3.fromRGB(161,158,141);t.Transparency=.3;t.Parent=p end
end
for _,r in {{-232,-190},{-178,-126},{-114,-88}}do wall((r[1]+r[2])/2,r[2]-r[1],9,16)end
for _,z in {-184,-120}do
 wall(z,12,14.5,5)
 for _,dz in {-6.18,6.18}do local p=Instance.new("Part");p.Name="DoorJamb";p.Anchored=true;p.Size=Vector3.new(1.5,11,.3);p.Position=Vector3.new(88.15,6.5,z+dz);p.Color=Color3.fromRGB(55,39,29);p.Material=Enum.Material.Wood;p.Parent=out end
 local p=Instance.new("Part");p.Name="DoorLintel";p.Anchored=true;p.Size=Vector3.new(1.5,.35,12.65);p.Position=Vector3.new(88.15,12.18,z);p.Color=Color3.fromRGB(55,39,29);p.Material=Enum.Material.Wood;p.Parent=out
end
sample:Destroy()
out:SetAttribute("Ready",true)
