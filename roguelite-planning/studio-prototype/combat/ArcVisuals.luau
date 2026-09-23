local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local Motion=require(script.Parent.ArcMotion)
local A={}
function A.mount(combat,folder,lookup)
 local active={}
 local function remove(id,impact,weapon,radius)
  local r=active[id]
  if r then
   if r.model then r.model:Destroy() end
   active[id]=nil
  end
  if impact and weapon=='33' then
   local burst=Instance.new('Part');burst.Name='PandoraImpact';burst.Shape=Enum.PartType.Ball
   burst.Anchored=true;burst.CanCollide=false;burst.CanTouch=false;burst.CanQuery=false
   burst.Material=Enum.Material.Neon;burst.Color=Color3.fromRGB(155,112,230);burst.Transparency=.55
   burst.Size=Vector3.one;burst.Position=impact;burst.Parent=folder
   TweenService:Create(burst,TweenInfo.new(.25),{Size=Vector3.one*math.min(5,(radius or 5)*.6),Transparency=1}):Play();Debris:AddItem(burst,.3)
  end
 end
 combat:WaitForChild('ArcShot').OnClientEvent:Connect(function(action,id,...)
  local a={...}
  if action=='End' then remove(id,a[1],a[2],a[3]);return end
  if action=='Redirect' then
   local r=active[id];if r then
    local visualPosition=r.model and r.model:GetPivot().Position
    r.origin=a[1];r.finish=a[2];r.started=a[3];r.duration=a[4];r.side=a[5];r.height=a[6];r.target=a[7];r.bend=a[8]
    r.offset=visualPosition and visualPosition-r.origin or Vector3.zero
    if r.entry then r.entry.flyingUntil=math.max(r.entry.flyingUntil or 0,r.started+r.duration+.12) end
   end
   return
  end
  if action~='Launch' then return end
  active[id]={weapon=a[1],owner=a[2],slot=a[3],index=a[4],origin=a[5],finish=a[6],started=a[7],duration=a[8],side=a[9],height=a[10],target=a[11],bend=a[12]}
 end)
 RunService.RenderStepped:Connect(function()
  local now=workspace:GetServerTimeNow()
  for id,r in active do
   if now<r.started then continue end
   if now>r.started+r.duration+1 then remove(id);continue end
   if not r.model then
    local v=lookup(r.owner,r.slot)
    if r.weapon=='18' and v and v.id=='18' and v.cards then
     local entry=v.cards.cards[(r.index-1)%3+1]
     r.model=entry.model:Clone();r.model.Name='FlyingCard';r.entry=entry
     r.offset=entry.model:GetPivot().Position-r.origin
     entry.flyingUntil=math.max(entry.flyingUntil or 0,r.started+r.duration+.12)
     for _,part in r.model:GetDescendants() do if part:IsA('BasePart') then part.LocalTransparencyModifier=0 elseif part:IsA('SurfaceGui') then part.Enabled=true end end
    else
     local m=Instance.new('Model');m.Name=r.weapon=='33' and 'PandoraMortarBall' or 'FlyingCard'
     local p=Instance.new('Part');p.Name='ReplaceableProjectile';p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
     p.Shape=r.weapon=='33' and Enum.PartType.Ball or Enum.PartType.Block
     p.Size=r.weapon=='33' and Vector3.one*.7 or Vector3.new(.5,.8,.04)
     p.Material=r.weapon=='33' and Enum.Material.Neon or Enum.Material.SmoothPlastic
     p.Color=r.weapon=='33' and Color3.fromRGB(167,132,232) or Color3.fromRGB(132,28,47)
     p.Parent=m;m.PrimaryPart=p;r.model=m;r.offset=Vector3.zero
     if r.weapon=='33' then
      local a0=Instance.new('Attachment');a0.Position=Vector3.new(-.18,0,0);a0.Parent=p
      local a1=Instance.new('Attachment');a1.Position=Vector3.new(.18,0,0);a1.Parent=p
      local trail=Instance.new('Trail');trail.Name='MortarTrail';trail.Attachment0=a0;trail.Attachment1=a1
      trail.Lifetime=.32;trail.MinLength=.05;trail.FaceCamera=true;trail.LightEmission=.7
      trail.Color=ColorSequence.new(Color3.fromRGB(202,174,255),Color3.fromRGB(104,74,181))
      trail.Transparency=NumberSequence.new(.15,1);trail.Parent=p
     end
    end
    r.model.Parent=folder
   end
   local t=math.clamp((now-r.started)/r.duration,0,1)
   if r.weapon=='18' and r.target and r.target.Parent then r.finish=r.target.Position end
   local pos=Motion.position(r.origin,r.finish,t,r.side,r.height,r.bend)+(r.offset or Vector3.zero)*(1-t)^2
   local nextPos=Motion.position(r.origin,r.finish,math.min(1,t+.01),r.side,r.height,r.bend)
   local tangent=nextPos-pos;if tangent.Magnitude<.001 then tangent=Vector3.new(0,-1,-.01) end
   local cf=CFrame.lookAt(pos,pos+tangent)
   if r.weapon=='18' then cf*=CFrame.Angles(math.pi/2+.2,0,(now-r.started)*math.pi*10+r.index) end
   r.model:PivotTo(cf)
  end
 end)
end
return A
