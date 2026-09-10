local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Effects={}; Effects.__index=Effects
local GOLD=Color3.fromRGB(255,191,78)
local CYAN=Color3.fromRGB(105,222,255)
local function part(parent,name)
 local p=Instance.new("Part"); p.Name=name; p.Anchored=true
 p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false
 p.Material=Enum.Material.Neon; p.Parent=parent; return p
end
function Effects.new()
 local folder=Instance.new("Folder"); folder.Name="TungCombatEffects"; folder.Parent=workspace
 return setmetatable({folder=folder,rings={},bats={},tracked={},kick=0},Effects)
end
function Effects:Ring(position,radius,color,duration,inward)
 local segments={}
 for i=1,36 do
  local p=part(self.folder,"SoundRing"); p.Color=color; p.Transparency=0.1
  table.insert(segments,p); Debris:AddItem(p,duration+0.2)
 end
 table.insert(self.rings,{parts=segments,pos=position,radius=radius,at=os.clock(),duration=duration,inward=inward})
end
function Effects:Flash(position,color,size)
 local p=part(self.folder,"Impact"); p.Shape=Enum.PartType.Ball; p.Size=Vector3.one*0.5
 p.Color=color; p.CFrame=CFrame.new(position); p.Transparency=0.2
 TweenService:Create(p,TweenInfo.new(0.22),{Size=Vector3.one*size,Transparency=1}):Play()
 Debris:AddItem(p,0.3)
end
function Effects:Number(position,damage)
 local p=part(self.folder,"DamageNumber"); p.Transparency=1; p.Size=Vector3.one*0.1; p.Position=position+Vector3.yAxis*2.5
 local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(100,55); gui.AlwaysOnTop=true; gui.Parent=p
 local label=Instance.new("TextLabel"); label.BackgroundTransparency=1; label.Size=UDim2.fromScale(1,1)
 label.Text=string.format("%.1f",damage):gsub("%.0$",""); label.Font=Enum.Font.GothamBlack
 label.TextColor3=GOLD; label.TextStrokeTransparency=0.4; label.TextSize=28; label.Parent=gui
 TweenService:Create(p,TweenInfo.new(0.65),{Position=p.Position+Vector3.yAxis*2}):Play()
 TweenService:Create(label,TweenInfo.new(0.4,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.25),{TextTransparency=1,TextStrokeTransparency=1}):Play()
 Debris:AddItem(p,0.75)
end
function Effects:Sound(position,id,pitch,volume)
 local p=part(self.folder,"CombatSound"); p.Transparency=1; p.Size=Vector3.one*0.1; p.Position=position
 local sound=Instance.new("Sound"); sound.SoundId=id; sound.PlaybackSpeed=pitch or 1
 sound.Volume=volume or 0.3; sound.RollOffMaxDistance=80; sound.Parent=p; sound:Play()
 Debris:AddItem(p,3)
end
function Effects:Handle(kind,position,data)
 if kind=="Hit" then
  self:Flash(position,Color3.new(1,1,1),2.8); self:Number(position,data.damage)
  self:Burst(position,GOLD,9,4)
  if data.target then
   local highlight=Instance.new("Highlight"); highlight.Adornee=data.target
   highlight.FillColor=Color3.new(1,1,1); highlight.FillTransparency=0.15
   highlight.OutlineColor=GOLD; highlight.OutlineTransparency=0.1; highlight.Parent=self.folder
   TweenService:Create(highlight,TweenInfo.new(0.16),{FillTransparency=1,OutlineTransparency=1}):Play()
   Debris:AddItem(highlight,0.2)
  end
  local localCharacter=game.Players.LocalPlayer.Character
  if data.source==localCharacter or data.target==localCharacter then self.kick=math.max(self.kick,0.16) end
  self:Sound(position,"rbxasset://sounds/action_jump_land.mp3",0.85,0.35)
 elseif kind=="Swing" then
  self:Arc(position,data.aim,6.7,GOLD,false)
  self:Sound(position,"rbxasset://sounds/action_swim.mp3",0.65,0.4)
 elseif kind=="Slam" then
  self:Ring(position+Vector3.yAxis*0.15,9,GOLD,0.4,false)
  self:Flash(position,Color3.new(1,0.9,0.6),7)
  self:Burst(position+Vector3.yAxis*0.5,GOLD,22,9)
  if data.source==game.Players.LocalPlayer.Character then self.kick=0.3 end
  self:Sound(position,"rbxasset://sounds/action_jump_land.mp3",0.55,0.6)
 elseif kind=="AlarmWarn" then
  self:Ring(position-Vector3.yAxis*2.6,data.radius,GOLD,data.duration or 0.35,false)
  self.rings[#self.rings].fixed=true
 elseif kind=="AlarmBeat" or kind=="AlarmStrike" or kind=="AlarmFinal" then
  local final=kind=="AlarmFinal"
  local ground=position-Vector3.yAxis*2.6
  self:Ring(ground,data.radius,GOLD,final and 0.55 or 0.35,false)
  self:Ring(ground+Vector3.yAxis*0.35,data.radius,Color3.fromRGB(255,236,185),0.45,false)
  if kind=="AlarmBeat" then
   self:Flash(position+Vector3.yAxis*0.6,GOLD,3.5)
  else
   self:Arc(position,data.aim or Vector3.new(0,0,-1),final and 9 or 8,GOLD,final)
   self:Flash(final and ground or position,GOLD,final and 8 or 5)
  end
  self:Burst(final and ground or position,GOLD,final and 30 or 14,final and 12 or 6)
  local localCharacter=game.Players.LocalPlayer.Character
  local root=localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
  if root and (root.Position-position).Magnitude<=data.radius+8 then
   self.kick=math.max(self.kick,final and 0.4 or 0.2)
  end
  self:Sound(position,"rbxasset://sounds/action_jump_land.mp3",final and 0.45 or (kind=="AlarmStrike" and 0.6 or 0.75),final and 0.7 or 0.5)
 elseif kind=="Wave" or kind=="Toll" then
  self:Ring(position-Vector3.yAxis*2,data.radius,kind=="Toll" and GOLD or CYAN,0.65,false)
  if kind=="Wave" then self:Ring(position,data.radius,CYAN,0.65,true) end
  self:Flash(position,kind=="Toll" and GOLD or CYAN,kind=="Toll" and 10 or 4)
  self:Burst(position,kind=="Toll" and GOLD or CYAN,kind=="Toll" and 28 or 12,data.radius)
  if data.source==game.Players.LocalPlayer.Character then self.kick=kind=="Toll" and 0.4 or 0.15 end
  self:Sound(position,"rbxasset://sounds/volume_slider.ogg",kind=="Toll" and 0.5 or 0.75,0.6)
 elseif kind=="Core" or kind=="Jump" then
  self:Ring(position-Vector3.yAxis*2,kind=="Core" and 4 or 3,CYAN,0.3,false)
 elseif kind=="Cast" then
  if data.key=="M1" then
   task.delay(data.combo==3 and 0.135 or 0.105,function()
    if self.folder.Parent then
     local root=data.source and data.source:FindFirstChild("HumanoidRootPart")
     self:Arc(root and root.Position or position,data.aim,4.5,GOLD,data.combo==3)
    end
   end)
  elseif data.key=="R" then
   self:Ring(position,4,CYAN,0.4,false); self:Burst(position,CYAN,14,5)
   if data.source==game.Players.LocalPlayer.Character then self.kick=0.18 end
  elseif data.key=="E" then
   self:Ring(position-Vector3.yAxis*2,3,GOLD,0.2,true)
  end
  if data.key=="F" then self:Flash(position,GOLD,3) end
 end
end
function Effects:Step()
 local now=os.clock()
 for i=#self.rings,1,-1 do
  local r=self.rings[i]; local t=math.clamp((now-r.at)/r.duration,0,1)
  if t>=1 then
   for _,p in r.parts do p:Destroy() end; table.remove(self.rings,i)
  else
   local radius=math.max(0.1,r.radius*(r.fixed and 1 or (r.inward and (1-t) or (0.12+0.88*t))))
   for n,p in r.parts do
    local a=(n-1)*math.pi*2/#r.parts; local b=n*math.pi*2/#r.parts
    local from=r.pos+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius)
    local to=r.pos+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius)
    p.Size=Vector3.new(0.12+0.15*(1-t),0.12,(to-from).Magnitude+0.05)
    p.CFrame=CFrame.lookAt((from+to)/2,to); p.Transparency=0.15+t*0.85
   end
  end
 end
end

function Effects:Burst(position,color,count,radius)
 local random=Random.new()
 for i=1,count do
  local angle=i/count*math.pi*2+random:NextNumber(-0.15,0.15)
  local direction=Vector3.new(math.cos(angle),random:NextNumber(0.15,0.7),math.sin(angle)).Unit
  local shard=part(self.folder,"ImpactStreak"); shard.Color=color
  shard.Size=Vector3.new(0.1,0.1,random:NextNumber(0.6,1.7))
  shard.CFrame=CFrame.lookAt(position+direction*0.5,position+direction*2)
  TweenService:Create(shard,TweenInfo.new(0.28,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
   {CFrame=shard.CFrame+direction*radius,Transparency=1,Size=Vector3.new(0.015,0.015,0.2)}):Play()
  Debris:AddItem(shard,0.35)
 end
end
function Effects:Arc(position,aim,radius,color,vertical)
 local frame=CFrame.lookAt(position,position+aim)
 local function point(t)
  if vertical then return frame:PointToWorldSpace(Vector3.new(0.45,-1+math.sin(t*math.pi*0.8)*4,-0.7-t*3.5)) end
  local angle=math.rad(-85+t*170)
  return frame:PointToWorldSpace(Vector3.new(math.sin(angle)*radius,0.5,-math.cos(angle)*radius))
 end
 for i=1,18 do
  local a,b=point((i-1)/18),point(i/18)
  for layer=1,2 do
   local streak=part(self.folder,"StrikeArc")
   streak.Color=layer==1 and color or Color3.new(1,1,1)
   local width=math.sin(i/19*math.pi)*(layer==1 and 0.38 or 0.1)
   streak.Size=Vector3.new(width,width,(b-a).Magnitude+0.05)
   streak.CFrame=CFrame.lookAt((a+b)/2,b); streak.Transparency=layer==1 and 0.2 or 0
   TweenService:Create(streak,TweenInfo.new(0.19),{Transparency=1,Size=Vector3.new(0.015,0.015,streak.Size.Z)}):Play()
   Debris:AddItem(streak,0.23)
  end
 end
end
function Effects:TrackVisual(visual)
 local character=visual.Parent; if not character then return end
 local key=character:GetAttribute("CombatAction")
 local record=self.tracked[visual]
 if not record and key and key~="" then
  record={}; self.tracked[visual]=record
  for _,name in {"Bone.005","Bone.008"} do
   local bone=visual:FindFirstChild(name,true)
   if bone then
    local a=Instance.new("Attachment"); a.Name="CombatTrailA"; a.Position=Vector3.new(0,0,-0.28); a.Parent=bone
    local b=Instance.new("Attachment"); b.Name="CombatTrailB"; b.Position=Vector3.new(0,0,0.28); b.Parent=bone
    local trail=Instance.new("Trail"); trail.Name="FistTrail"; trail.Attachment0=a; trail.Attachment1=b
    trail.Color=ColorSequence.new(Color3.new(1,1,0.8),GOLD); trail.LightEmission=1
    trail.Lifetime=0.13; trail.MinLength=0.04; trail.FaceCamera=true
    trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.7,0.35),NumberSequenceKeypoint.new(1,1)})
    trail.Parent=self.folder
    table.insert(record,{a=a,b=b,trail=trail,name=name})
   end
  end
 end
 if record then
  local combo=character:GetAttribute("CombatCombo")
  for _,r in record do
   r.trail.Enabled=key=="Q" or key=="R" or key=="E" or key=="F" or
    (key=="M1" and ((combo==2 and r.name=="Bone.005") or (combo~=2 and r.name=="Bone.008")))
  end
 end
end
function Effects:ForgetVisual(visual)
 local record=self.tracked[visual]; if not record then return end
 for _,r in record do r.a:Destroy(); r.b:Destroy(); r.trail:Destroy() end
 self.tracked[visual]=nil
end
function Effects:Camera(dt)
 self.kick=(self.kick or 0)*math.exp(-23*dt)
 local camera=workspace.CurrentCamera
 if camera and self.kick>0.001 then
  local t=os.clock()*85
  camera.CFrame*=CFrame.new(math.sin(t)*self.kick*0.25,math.cos(t*1.2)*self.kick*0.35,0)
   *CFrame.Angles(self.kick*0.025,0,math.sin(t)*self.kick*0.015)
 end
end

return Effects
