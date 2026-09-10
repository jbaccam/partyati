-- Assemble one reusable master from the reviewed static bay. No remote model loading.
local storage=game:GetService("ServerStorage")
if storage:FindFirstChild("BookshelfMaster") then return end
local bay=storage:WaitForChild("BookshelfBay")
local master=Instance.new("Model");master.Name="BookshelfMaster"
-- Serialized bay is already 6 studs wide, facing -X, centered at X=-.8/Z=-9.
for side=0,1 do for index=0,3 do
 local c=bay:Clone();c.Name="CabinetBay"
 local transform=side==0 and CFrame.new(0,0,index*6) or CFrame.new(0,0,-18+index*6)*CFrame.Angles(0,math.pi,0)
 for _,p in c:GetDescendants() do if p:IsA("BasePart") then p.CFrame=transform*p.CFrame end end
 c.Parent=master
end end
local p=Instance.new("Part");p.Name="CollisionProxy";p.Size=Vector3.new(3.2,11.7,24);p.Position=Vector3.new(0,5.85,0)
p.Anchored=true;p.Transparency=1;p.Parent=master
master.WorldPivot=CFrame.new();master:SetAttribute("SourceAssetId","9914694425");master:SetAttribute("SourceCreator","bradyocon")
master.Parent=storage
