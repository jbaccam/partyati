-- Final architectural and player-height visibility adjustments.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("ProductionDressed") do task.wait() end
if root:GetAttribute("ProductionPolished") then return end
local K=require(game.ServerScriptService.FacilityRoomKit);local P=K.colors;local V=Vector3.new;local C=Color3.fromRGB
local function cf(x,y,z,a) return CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(a or 0),0) end
local yard=root.RoomInteriors.Courtyard;yard:SetAttribute("PowerSector",2)
-- Explicit occupancy prevents Terrain's coarse FillBlock from burying the paths.
local materials,occupancy={},{}
for x=1,32 do materials[x]={};occupancy[x]={};for y=1,4 do materials[x][y]={};occupancy[x][y]={};for z=1,32 do
 local path=math.abs((-90+x*4)+24)<=6 or math.abs((-90+z*4)+24)<=6
 for _,r in {{-43,-33,7,4},{-5,-15,7,4},{-33,-45,4,7},{-15,-3,4,7},{-65,-5,7,4},{15,-42,7,4}} do if math.abs(-90+x*4-r[1])<=r[3] and math.abs(-90+z*4-r[2])<=r[4] then path=true end end
 materials[x][y][z]=y<3 and (path and Enum.Material.Ground or Enum.Material.Grass) or Enum.Material.Air;occupancy[x][y][z]=y==1 and 1 or y==2 and .75 or 0
end end end
workspace.Terrain:WriteVoxels(Region3.new(V(-88,-8,-88),V(40,8,40)),4,materials,occupancy)
for i,r in {{-42,-42},{-6,-42},{-42,-6},{-6,-6},{-77,-24},{29,-24},{-24,-77},{-24,29}} do
 local m=K.model(yard,"CourtyardPathLight")
 local pos=V(r[1],1.3,r[2])
 K.disc(m,"BaseFlange",CFrame.new(pos),1.25,.18,P.trim)
 K.rod(m,"LampPost",pos,pos+V(0,8.4,0),.18,P.trim)
 local globe=K.part(m,"WarmBulb",V(.85,.55,.85),CFrame.new(pos+V(0,8.2,0)),C(206,195,147),Enum.Material.Neon)
 K.part(m,"Downshade",V(1.5,.15,1.5),CFrame.new(pos+V(0,8.6,0)),P.trim,Enum.Material.Metal)
 local l=Instance.new("PointLight");l.Range=38;l.Brightness=1.4;l.Color=C(214,210,169);l.Shadows=true;l.Parent=globe
end
-- Low boundary curbs separate the planting from the maintained cross paths.
for _,x in {-30.2,-17.8} do K.part(yard,"PathEdging",V(.25,.25,128),V(x,1.4,-24),C(100,105,92),Enum.Material.Concrete) end
for _,z in {-30.2,-17.8} do for _,span in {{-88,-30.4},{-17.6,40}} do K.part(yard,"PathEdging",V(span[2]-span[1],.25,.25),V((span[1]+span[2])/2,1.4,z),C(100,105,92),Enum.Material.Concrete) end end
-- Tactile push plate and kick plate travel with the kitchen door leaf.
local d=root.RoomInteriors.CafeteriaKitchen.EnclosedKitchen.KitchenSwingDoor.Leaf
for i,z in {30,75,104} do
 local p=K.lamp(root.RoomInteriors.CafeteriaKitchen,V(195,15.7,z),3,i)
 local l=Instance.new("PointLight");l.Name="CeilingBounce";l.Range=23;l.Brightness=.7;l.Color=C(196,204,182);l.Shadows=true;l.Parent=p
end
for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
 local g=Instance.new("SurfaceGui");g.Face=face;g.CanvasSize=Vector2.new(480,535);g.Parent=d
 local kick=Instance.new("Frame");kick.BorderSizePixel=0;kick.Size=UDim2.fromScale(.95,.16);kick.Position=UDim2.fromScale(.025,.8);kick.BackgroundColor3=C(107,115,106);kick.Parent=g
 local push=Instance.new("TextLabel");push.Size=UDim2.fromScale(.15,.23);push.Position=UDim2.fromScale(.1,.4);push.BackgroundColor3=C(125,131,120);push.Text="PUSH";push.TextColor3=P.dark;push.TextSize=15;push.Parent=g
end
root:SetAttribute("ProductionPolished",true)
