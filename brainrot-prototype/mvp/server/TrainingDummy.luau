-- Explicitly attached Studio training targets only. Never scans arbitrary NPCs.
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Dummy={};Dummy.__index=Dummy
local function clearTags(model)
 for _,v in {model,table.unpack(model:GetDescendants())} do
  for _,tag in CollectionService:GetTags(v) do CollectionService:RemoveTag(v,tag) end
 end
end
function Dummy.new(target,options)
 assert(RunService:IsStudio(),"Training dummies are Studio-only")
 options=options or {}
 local root=assert(target:FindFirstChild("HumanoidRootPart"),"Dummy requires root")
 local template=target:Clone();clearTags(template)
 local self=setmetatable({template=template,parent=target.Parent,home=root.CFrame,
  idleSeconds=options.idleSeconds or 4,ringOutY=options.ringOutY or root.Position.Y-35,
  visualTag=options.visualTag,onSpawn=options.onSpawn,armed=false,options=options},Dummy)
 self:Bind(target)
 if options.autoStep~=false then
  self.connection=RunService.Heartbeat:Connect(function(dt)
   self.elapsed=(self.elapsed or 0)+dt
   if self.elapsed>=.1 then self.elapsed=0;self:Step(workspace:GetServerTimeNow()) end
  end)
 end
 return self
end
function Dummy:Bind(target)
 self.target=target;self.root=target.HumanoidRootPart;self.humanoid=target:FindFirstChildOfClass("Humanoid")
 local root,h=self.root,self.humanoid
 assert(h,"Dummy requires Humanoid")
 target:SetAttribute("TrainingDummy",true)
 target:SetAttribute("TrainingHome",self.home.Position)
 target:SetAttribute("TrainingResetDelay",self.idleSeconds)
 h.RequiresNeck=false;h.BreakJointsOnDeath=false;h.WalkSpeed=0;h.AutoRotate=false;h.HipHeight=2
 for _,v in target:GetDescendants() do
  if v:IsA("BasePart") then
   v.Anchored=false
   if v~=root then
    v.CanCollide=false;v.CanQuery=false;v.CanTouch=false;v.Massless=true
    local connected=false
    for _,joint in v:GetJoints() do
     if (joint.Part0==root and joint.Part1==v) or (joint.Part1==root and joint.Part0==v) then connected=true;break end
    end
    if not connected then local weld=Instance.new("WeldConstraint");weld.Name="TrainingDummyWeld";weld.Part0=root;weld.Part1=v;weld.Parent=v end
   end
  end
 end
 root.CanCollide=true;root.Massless=false
 pcall(function() root:SetNetworkOwner(nil) end)
 local previous=h.Health
 self.healthConnection=h.HealthChanged:Connect(function(health)
  if health<previous then self.lastHit=workspace:GetServerTimeNow();self.armed=true end
  previous=health
 end)
 if self.onSpawn then self.onSpawn(target) end
end
function Dummy:Respawn(now)
 if self.healthConnection then self.healthConnection:Disconnect() end
 clearTags(self.target);self.target:Destroy()
 local target=self.template:Clone()
 target:SetAttribute("LastCombatAt",nil);target:SetAttribute("CombatInvulnerable",nil)
 target:PivotTo(self.home*target.HumanoidRootPart.CFrame:Inverse()*target:GetPivot())
 target:FindFirstChildOfClass("Humanoid").Health=target:FindFirstChildOfClass("Humanoid").MaxHealth
 target.Parent=self.parent
 self.armed=false;self.lastHit=nil;self.resetAt=nil;self.seenHit=nil
 self:Bind(target)
 local visual=target:FindFirstChild("GalleryVisual") or target:FindFirstChild("TungVisual")
 if not visual and self.options.visualName then visual=target:FindFirstChild(self.options.visualName) end
 if visual and self.visualTag then CollectionService:AddTag(visual,self.visualTag) end
 CollectionService:AddTag(target,"BrainrotCombatTarget")
 target:SetAttribute("TrainingReturnedAt",now)
end
function Dummy:Step(now)
 if not self.parent.Parent then self:Destroy();return end
 if not self.target.Parent or not self.root.Parent then self:Respawn(now);return end
 local root,h,target=self.root,self.humanoid,self.target
 local outOfBounds=self.options.outOfBounds and self.options.outOfBounds(root.Position)
 if h.Health<=0 or root.Position.Y<self.ringOutY or (root.Position-self.home.Position).Magnitude>200 or outOfBounds then
  if not self.resetAt then self.resetAt=now+1;root.Anchored=true;target:SetAttribute("CombatInvulnerable",true) end
 end
 if self.resetAt then if now>=self.resetAt then self:Respawn(now) end;return end
 -- Combat owns knockback for its short impulse; release must not hand NPCs to a client.
 pcall(function() if root:GetNetworkOwnershipAuto() then root:SetNetworkOwner(nil) end end)
 local hitAt=target:GetAttribute("LastCombatAt")
 if type(hitAt)=="number" and hitAt~=self.seenHit then
  self.seenHit=hitAt;self.lastHit=math.max(self.lastHit or -math.huge,hitAt);self.armed=true
 end
 if not self.armed and (root.Position-self.home.Position).Magnitude>3 then self.armed=true;self.lastHit=now end
 if self.armed and now-(self.lastHit or now)>=self.idleSeconds then
  target:PivotTo(self.home*root.CFrame:Inverse()*target:GetPivot())
  root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  h.PlatformStand=false;h.Sit=false;h.Health=h.MaxHealth
  target:SetAttribute("StunnedUntil",nil);target:SetAttribute("TrainingReturnedAt",now)
  self.armed=false
 end
end
function Dummy:Destroy()
 if self.connection then self.connection:Disconnect();self.connection=nil end
 if self.healthConnection then self.healthConnection:Disconnect();self.healthConnection=nil end
 if self.template then self.template:Destroy();self.template=nil end
end
return Dummy
