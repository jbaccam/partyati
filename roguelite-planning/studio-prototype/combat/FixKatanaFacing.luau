-- One-time Edit migration for the existing combat copy. The display and
-- original KatanaTemplate remain unchanged; InstallLoadout handles new copies.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before applying')
local model=game.ReplicatedStorage.RogueliteCombat.WeaponTemplates['03']
if model:GetAttribute('KatanaEdgeForward') then return {alreadyApplied=true} end
local pivot=model:GetPivot()
local rotation=CFrame.Angles(0,-math.pi/2,0)
local center=model:GetAttribute('BoundsCenter')
local size=model:GetAttribute('BoundsSize')
assert(typeof(center)=='Vector3' and typeof(size)=='Vector3','Missing normalized bounds')
local poses={}
for _,part in model:GetDescendants() do
 if part:IsA('BasePart') then poses[part]=pivot*rotation*pivot:ToObjectSpace(part.CFrame) end
end
for part,pose in poses do part.CFrame=pose end
-- Preserve the original coordinate frame even if the model has a PrimaryPart.
if model.PrimaryPart then model.PrimaryPart.PivotOffset=model.PrimaryPart.CFrame:ToObjectSpace(pivot)
else model.WorldPivot=pivot end
model:SetAttribute('BoundsCenter',rotation:VectorToWorldSpace(center))
model:SetAttribute('BoundsSize',Vector3.new(size.Z,size.Y,size.X))
model:SetAttribute('KatanaEdgeForward',true)
return {rotatedDegrees=-90,bounds=model:GetAttribute('BoundsSize')}
