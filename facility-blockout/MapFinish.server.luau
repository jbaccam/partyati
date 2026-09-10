-- Map-only corrections: continuous stair circulation and visually legible furnishing.
local root=workspace:WaitForChild("FacilityLayoutReview")
while not root:GetAttribute("ProductionPolished") do task.wait() end
if root:GetAttribute("MapFinishReady") then return end
local V=Vector3.new;local C=Color3.fromRGB;local K=require(game.ServerScriptService.FacilityRoomKit);local P=K.colors
local rooms=root.RoomInteriors;local backup=Instance.new("Folder");backup.Name="Facility_MapFinishBackup";backup.Parent=game.ServerStorage
local function cf(x,y,z,a) return CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(a or 0),0) end
local function extent(p)
 local r,u,l=p.CFrame.RightVector,p.CFrame.UpVector,p.CFrame.LookVector;local s=p.Size
 return V(math.abs(r.X)*s.X+math.abs(u.X)*s.Y+math.abs(l.X)*s.Z,math.abs(r.Y)*s.X+math.abs(u.Y)*s.Y+math.abs(l.Y)*s.Z,math.abs(r.Z)*s.X+math.abs(u.Z)*s.Y+math.abs(l.Z)*s.Z)
end
local function clip(lo,hi,select)
 local list={};for _,p in root:GetDescendants() do if p:IsA("BasePart") and select(p) and math.abs(p.CFrame.UpVector.Y)>.999 then table.insert(list,p) end end
 for _,p in list do
  local s=extent(p);local a,b=p.Position-s/2,p.Position+s/2
  local c,d=V(math.max(a.X,lo.X),math.max(a.Y,lo.Y),math.max(a.Z,lo.Z)),V(math.min(b.X,hi.X),math.min(b.Y,hi.Y),math.min(b.Z,hi.Z))
  if c.X<d.X-.001 and c.Y<d.Y-.001 and c.Z<d.Z-.001 then
   for _,r in {{a,V(c.X,b.Y,b.Z)},{V(d.X,a.Y,a.Z),b},{V(c.X,a.Y,a.Z),V(d.X,c.Y,b.Z)},{V(c.X,d.Y,a.Z),V(d.X,b.Y,b.Z)},{V(c.X,c.Y,a.Z),V(d.X,d.Y,c.Z)},{V(c.X,c.Y,d.Z),V(d.X,d.Y,b.Z)}} do
    local size=r[2]-r[1];if math.min(size.X,size.Y,size.Z)>.002 then local q=p:Clone();q.Size=size;q.CFrame=CFrame.new((r[1]+r[2])/2);q.Parent=p.Parent end
   end
   p.Parent=backup
  end
 end
end
for _,x in {-144,96} do
 local shaft=root.ProductionLayout[x<0 and "WestServiceStair" or "EastServiceStair"]
 local face=x<0 and -136 or 88
 -- Hallway noticeboards and trim were attached to the wall before the new door was cut.
 for _,m in root.Hallways.WallFurniture:GetChildren() do if m:IsA("Model") then
  local box,size=m:GetBoundingBox();if math.abs(box.X-face)<2 and math.abs(box.Z-16)<10 then m.Parent=backup end
 end end
 clip(V(face-2,1,9.9),V(face+2,12,22.1),function(p) return p:IsDescendantOf(root.Hallways) and p.Position.Y>1.1 end)
 -- Structural floor AND decorative floor layers must be cut, not just the wall solids.
 clip(V(x-7.6,-.1,24),V(x+7.6,1.15,48),function(p) return not p:IsDescendantOf(shaft) and (p.Name:find("Floor")~=nil or p.Name=="RestoredRoomSlab") end)
 -- Remove the duplicate ceiling grids, light bars and hallway floor skins inside the enclosed shaft.
 clip(V(x-7.6,1.005,24),V(x+7.6,17,124),function(p) return p:IsDescendantOf(root.Hallways) and not p.Name:find("Wall") end)
 -- The lower portals previously retained BOTH non-colliding wall skins: visually a solid dead end.
 clip(V(x-7.6,-39.05,123),V(x+7.6,-23.1,125),function(p) return not p:IsDescendantOf(shaft) end)
 -- Trim all four sides of each lower aperture, using the adjoining wall's finish.
 for _,sg in {-1,1} do
  K.part(shaft,"BasementPortalJamb",V(.22,15.5,1.2),V(x+sg*7.7,-31.25,124),P.trim,Enum.Material.Metal,true)
 end
 K.part(shaft,"BasementPortalHeader",V(15.6,.22,1.2),V(x,-23.5,124),P.trim,Enum.Material.Metal,true)
 K.sign(shaft,cf(x,-25.5,124.7),"MAIN FLOOR / STAIRS",11,1)
 -- A clean sloping soffit closes the sightline to the upper-floor slabs and avoids a floating lid.
 local a,b=V(x,9.8,25),V(x,-23.1,94)
 local mid=(a+b)/2;local delta=b-a
 K.part(shaft,"ContinuousStairSoffit",V(15.1,.45,delta.Magnitude),CFrame.lookAt(mid,b)*CFrame.Angles(0,0,0),P.wall,Enum.Material.Concrete,true)
 -- Close the wedge ABOVE the sloped ceiling at its entry. No exposed floating slab edge.
 K.part(shaft,"StairCeilingTransitionHeader",V(15.4,7.2,1),V(x,13.4,24.5),P.wall,Enum.Material.Concrete,true)
 K.part(shaft,"StairCeilingTransitionTrim",V(15.4,.16,1.12),V(x,9.8,24),P.trim,Enum.Material.Metal)
 K.part(shaft,"LowerLandingCeiling",V(15.1,.4,30),V(x,-23.1,109),P.wall,Enum.Material.Concrete,true)
 -- Sloped underside lights are mounted below the soffit, not left on the old hallway ceiling.
 for _,m in shaft:GetChildren() do if m.Name=="CeilingLuminaire" then m.Parent=backup end end
 for i,z in {16,42,65,87,113} do
  local ceiling=z<24 and 14.5 or z<95 and 9.8-(z-25)*32.9/69-.6 or -25
  local p=K.lamp(shaft,V(x,ceiling,z),6,i)
  local fill=Instance.new("PointLight");fill.Name="CeilingBounce";fill.Range=19;fill.Brightness=.55;fill.Color=C(196,204,182);fill.Shadows=true;fill.Parent=p
 end
end
-- Beds are scenery and selected hiding cover, not dozens of identical loot rolls.
for _,name in {"Medical","Residential"} do
 local hide=0
 for _,p in rooms[name]:GetDescendants() do if p:IsA("ProximityPrompt") then
  local a=p.Parent;local kind=a:GetAttribute("InteractionKind")
  if kind=="Search" and tostring(a:GetAttribute("ObjectiveId")):find("Bedside") then p.Parent=backup
  elseif kind=="Hide" then hide+=1;if hide%4~=1 then p.Parent=backup end end
 end end
end
-- A few conspicuous supplies on open work surfaces replace invisible bedside searching.
for i,r in {{rooms.Medical,-196,-191},{rooms.Residential,-208,47}} do
 local m=K.tray(r[1],cf(r[2],1,r[3]),"Visible_Medical_Supplies_"..i,i==1 and "Fuse" or "Battery")
 local f=cf(r[2],4.8,r[3])
 local body=K.part(m,"VisibleSupplyCase",V(1.6,.65,.9),f,C(116,129,115),Enum.Material.Metal)
 K.part(m,"CaseHandle",V(.6,.12,.12),f*CFrame.new(0,.43,0),P.dark,Enum.Material.Metal)
 K.sign(m,f*CFrame.new(0,.03,.48),"SUPPLIES",1.3,.35)
end
-- Kitchen back-of-house: racks, trays, utensils, wash carts and ordered wall storage.
local kitchen=rooms.CafeteriaKitchen.EnclosedKitchen
for i,z in {27,51,75} do
 local frame=cf(246.6,1,z,-90)
 for _,y in {6.7,8} do
  K.part(kitchen,"OpenWallShelf",V(15,.18,1.8),frame*CFrame.new(0,y,0),P.metal,Enum.Material.Metal)
  for _,x in {-6,6} do K.rod(kitchen,"ShelfBracket",frame:PointToWorldSpace(V(x,y-.7,-.6)),frame:PointToWorldSpace(V(x,y,.8)),.08,P.metal) end
 end
 if z~=51 then for j=1,6 do
  local x=-6+(j-1)*2.3
  if j%3==0 then
   for h=1,5 do K.disc(kitchen,"StackedPlate",frame*CFrame.new(x,6.8+h*.07,.1),1.25,.06,P.paper) end
  else
   K.disc(kitchen,"KitchenCanister",frame*CFrame.new(x,7.3,0),.9,1.05,P.metal)
   K.disc(kitchen,"CanisterLid",frame*CFrame.new(x,7.87,0),.98,.1,P.trim)
  end
 end end
end
-- Dry goods and dish racks occupy the ends, leaving both work aisles clear.
for i,x in {212,229} do
 local f=cf(x,1,13);local m=K.shelf(kitchen,f,12,8,"Kitchen_Dry_Stores_"..i)
 for _,p in m:GetChildren() do if p.Name=="ArchiveCarton" or p.Name=="CartonLid" or p.Name=="IndexLabel" then p.Parent=backup end end
 for j=1,3 do
  for k=1,4 do K.disc(m,"CateringTin",f*CFrame.new((k-2.5)*2.2,.9+j*1.9,0),1.1,1.35,C(115,122,103)) end
 end
end
for _,r in {{210,92},{230,112}} do
 local f=cf(r[1],1,r[2]);local m=K.tray(kitchen,f,"DishReturn_"..r[1])
 for j=1,9 do K.part(m,"ReturnedMealTray",V(2.8,.07,2),f*CFrame.new(0,3.6+j*.09,0),P.metal,Enum.Material.Metal) end
end
local island=rooms.CafeteriaKitchen:FindFirstChild("CentralPrepIsland")
if island then
 for _,z in {58,77} do
  local f=cf(222,4.6,z)
  K.part(island,"PrepBoard",V(4,.16,3),f,P.wood,Enum.Material.Wood)
  K.rod(island,"RollingPin",V(220.8,4.94,z),V(223.2,4.94,z),.28,P.wood)
  K.part(island,"FoldedKitchenTowel",V(1.3,.16,2.2),f*CFrame.new(1.8,.15,2),P.paper,Enum.Material.Fabric)
 end
end
K.sign(kitchen,cf(245,11,27,-90),"WASH / SANITIZE",9,1)
K.sign(kitchen,cf(245,11,75,-90),"PREPARATION",9,1)
-- Existing progression is retained but this pass adds no new gameplay systems.
root:SetAttribute("MapFinishReady",true)
