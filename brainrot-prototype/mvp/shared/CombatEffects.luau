local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Effects={}; Effects.__index=Effects
local GOLD=Color3.fromRGB(255,191,78)
local CYAN=Color3.fromRGB(105,222,255)
local MINT=Color3.fromRGB(133,211,162)
local ROSE=Color3.fromRGB(234,177,174)
local MOVE_ALIASES={PeelGlide="Glide",PoweredFlight="Flight"}
local CombatAudio=require(script.Parent.CombatAudio)
local function part(parent,name)
 local p=Instance.new("Part"); p.Name=name; p.Anchored=true
 p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false
 p.Material=Enum.Material.Neon; p.Parent=parent; return p
end
function Effects.new()
 local folder=Instance.new("Folder"); folder.Name="TungCombatEffects"; folder.Parent=workspace
 return setmetatable({folder=folder,rings={},bats={},tracked={},projectiles={},traps={},moves={},kick=0},Effects)
end
-- Project the reviewed visual's bounds onto the attack direction. The mouth is
-- several studs in front of the controller capsule on the long shark/croc rigs.
function Effects:JawFront(position,aim,source)
 local forward=3.2
 local visual=source and source:FindFirstChild("TungSahurVisual")
 if visual then
  local candidates=visual:IsA("BasePart") and {visual} or visual:GetDescendants()
  for _,p in candidates do
   if p:IsA("BasePart") then
    local cf,size=p.CFrame,p.Size*.5
    local extent=math.abs(aim:Dot(cf.RightVector))*size.X+math.abs(aim:Dot(cf.UpVector))*size.Y+math.abs(aim:Dot(cf.LookVector))*size.Z
    forward=math.max(forward,(p.Position-position):Dot(aim)+extent)
   end
  end
 end
 return position+aim*(math.clamp(forward,3.2,12)+.65)
end

local function roundedPiece(container,pieces,name,size,offset,color)
 local p=part(container,name);p.Material=Enum.Material.SmoothPlastic;p.Size=size;p.Color=color
 -- Ball Parts clamp the rendered sphere to the shortest axis. Sphere meshes
 -- honor all three dimensions, giving connected crescents and broad flat peels.
 local mesh=Instance.new("SpecialMesh");mesh.Name="EllipsoidSurface";mesh.MeshType=Enum.MeshType.Sphere;mesh.Scale=Vector3.one;mesh.Parent=p
 table.insert(pieces,{part=p,offset=offset});return p
end
local function bananaModel(container,pieces)
 -- Overlapping tapered ellipsoids form one continuous crescent, not flying cubes.
 for i=0,10 do
  local angle=math.rad(-72+i*14.4)
  local thickness=.19+.27*math.sin((i+1)/12*math.pi)
  roundedPiece(container,pieces,"BananaCurve",Vector3.new(thickness,.57,thickness),CFrame.new(math.cos(angle)*1.05-.6,math.sin(angle)*1.05,0)*CFrame.Angles(0,0,angle),Color3.fromRGB(255,216,65))
 end
 roundedPiece(container,pieces,"BananaStem",Vector3.new(.19,.43,.19),CFrame.new(-.30,1.16,0)*CFrame.Angles(0,0,-.8),Color3.fromRGB(103,73,38))
 roundedPiece(container,pieces,"BananaTip",Vector3.new(.18,.23,.18),CFrame.new(-.30,-1.08,0),Color3.fromRGB(103,73,38))
end
local function bombModel(container,pieces)
 roundedPiece(container,pieces,"BombBody",Vector3.new(1.15,1.55,1.15),CFrame.identity,Color3.fromRGB(57,70,57))
 roundedPiece(container,pieces,"BombNose",Vector3.new(.95,.5,.95),CFrame.new(0,-.64,0),Color3.fromRGB(34,41,35))
 for i=0,3 do
  local fin=part(container,"BombTailFin");fin.Material=Enum.Material.SmoothPlastic;fin.Color=Color3.fromRGB(195,112,62);fin.Size=Vector3.new(.1,.52,.65)
  table.insert(pieces,{part=fin,offset=CFrame.Angles(0,i*math.pi/2,0)*CFrame.new(0,.77,.35)})
 end
 roundedPiece(container,pieces,"BombFuse",Vector3.new(.14,.35,.14),CFrame.new(0,1.13,0),GOLD)
end
local function placePieces(pieces,frame)
 for _,piece in pieces do piece.part.CFrame=frame*piece.offset end
end
-- These are presentation only. Travel and hit detection remain on the server.
function Effects:Stroke(a,b,color,width,lifetime,name)
 if (b-a).Magnitude<.01 then return end
 local streak=part(self.folder,name or "FighterStreak")
 streak.Color=color;streak.Size=Vector3.new(width,width,(b-a).Magnitude)
 streak.CFrame=CFrame.lookAt((a+b)*.5,b);streak.Transparency=.15
 TweenService:Create(streak,TweenInfo.new(lifetime),{Transparency=1,Size=Vector3.new(.015,.015,streak.Size.Z)}):Play()
 Debris:AddItem(streak,lifetime+.05)
end
function Effects:FighterStrike(position,data)
 local aim=typeof(data.aim)=="Vector3" and data.aim or Vector3.new(0,0,-1)
 if aim.Magnitude<.01 then aim=Vector3.new(0,0,-1) end
 local frame=CFrame.lookAt(position,position+aim)
 local combo=data.combo or 1
 local id=data.fighterId or (data.source and data.source:GetAttribute("FighterId"))
 if id=="tralalero" or id=="bombardiro" then
  frame=CFrame.lookAt(self:JawFront(position,aim,data.source),self:JawFront(position,aim,data.source)+aim)
  -- Opposed, closing jaw curves: visibly a bite rather than a fist semicircle.
  local heavy=id=="bombardiro"
  local width=heavy and 1.9 or 1.35
  for side=-1,1,2 do
   for i=1,9 do
    local function point(t)
     return frame:PointToWorldSpace(Vector3.new((t-.5)*width*2,side*(.2+math.sin(t*math.pi)*.65),-math.sin(t*math.pi)*(heavy and 1.1 or .8)))
    end
    self:Stroke(point((i-1)/9),point(i/9),heavy and MINT or CYAN,.18,.2,"JawSnap")
   end
  end
  if combo==3 then self:Burst(frame.Position+aim*.5,heavy and MINT or CYAN,7,1.7) end
 elseif id=="ballerina" then
  -- A low shoe sweep, deliberately below the hand-height generic attack.
  local direction=combo==2 and -1 or 1
  for i=1,14 do
   local function point(t)
    local angle=(-1.2+t*2.4)*direction
    return frame:PointToWorldSpace(Vector3.new(math.sin(angle)*2.7,-1.65+(combo==3 and t*1.4 or .15),-math.cos(angle)*2.7))
   end
   self:Stroke(point((i-1)/14),point(i/14),ROSE,.16,.22,"ShoeSweep")
  end
 elseif id=="chimpanzini" then
  -- Compact curved banana lash; no impossible fist trail on a limbless rig.
  local sign=combo==2 and -1 or 1
  for i=1,12 do
   local function point(t)
    return frame:PointToWorldSpace(Vector3.new(sign*(-1.5+t*3),-.35+math.sin(t*math.pi)*.7,-1.6-math.sin(t*math.pi)*1.1))
   end
   self:Stroke(point((i-1)/12),point(i/12),GOLD,.22,.21,"BananaLash")
  end
 else self:Arc(position,aim,4.5,GOLD,combo==3) end
 self:Cue(position,id=="bombardiro" and "Chomp" or id=="tralalero" and "Bite" or "Whoosh",id)
end
function Effects:MoveBurst(position,data)
 local mode=MOVE_ALIASES[data.mode] or data.mode
 local modes={Torpedo=true,Porpoise=true,Glide=true,AirStep=true,Flight=true,PeelVault=true,TailLauncher=true,CarpetRun=true,Pirouette=true,FinishingKick=true,FrenzyBite=true}
 if not modes[mode] or not data.source then return end
 for i=#self.moves,1,-1 do if self.moves[i].source==data.source then table.remove(self.moves,i) end end
 local duration=math.clamp(tonumber(data.duration) or .6,.05,5)
 table.insert(self.moves,{source=data.source,mode=mode,at=data.at or workspace:GetServerTimeNow(),duration=duration,lastEmit=0})
 if mode=="AirStep" or mode=="Pirouette" then self:Ring(position-Vector3.yAxis*1.7,2.6,ROSE,.25,false)
 elseif mode=="Porpoise" or mode=="TailLauncher" then self:Ring(position-Vector3.yAxis*1.7,3,CYAN,.3,false)
 elseif mode=="PeelVault" or mode=="CarpetRun" then self:Ring(position-Vector3.yAxis*1.7,2.6,GOLD,.25,false) end
end
function Effects:Projectile(position,data)
 if typeof(data.velocity)~="Vector3" or typeof(data.duration)~="number" or typeof(data.at)~="number" then return end
 local duration=math.clamp(data.duration,.02,3)
 local container=Instance.new("Model");container.Name=data.kind=="Banana" and "BananaProjectile" or "CrocBombProjectile";container.Parent=self.folder
 local pieces={}
 if data.kind=="Banana" then bananaModel(container,pieces) else bombModel(container,pieces) end
 placePieces(pieces,CFrame.new(position))
 table.insert(self.projectiles,{container=container,pieces=pieces,id=data.id,source=data.source,origin=position,velocity=data.velocity,at=data.at,duration=duration,kind=data.kind})
 Debris:AddItem(container,duration+.15)
 self:Cue(position,data.kind=="Banana" and "Whoosh" or "Launch",data.fighterId)
end
function Effects:BombDrop(position,data)
 if typeof(data.target)~="Vector3" then return end
 local duration=math.clamp(tonumber(data.duration) or .35,.05,2)
 local container=Instance.new("Model");container.Name="FallingCrocBomb";container.Parent=self.folder
 local pieces={};bombModel(container,pieces);placePieces(pieces,CFrame.new(position))
 table.insert(self.projectiles,{container=container,pieces=pieces,id=data.id,source=data.source,origin=position,velocity=(data.target-position)/duration,at=data.at or workspace:GetServerTimeNow(),duration=duration,kind="Drop"})
 Debris:AddItem(container,duration+.15)
end
function Effects:PeelTrap(position,data)
 local container=Instance.new("Model");container.Name="BananaPeelTrap";container.Parent=self.folder
 local pieces={}
 roundedPiece(container,pieces,"PeelStem",Vector3.new(.32,.8,.32),CFrame.new(0,.45,0),GOLD)
 for strip=0,2 do
  local rotation=CFrame.Angles(0,strip*math.pi*2/3,0)
  for i=0,5 do
   local t=i/5
   local offset=rotation*CFrame.new(0,.14+math.sin(t*math.pi)*.45,-.2-t*1.65)*CFrame.Angles(math.cos(t*math.pi)*.5,0,0)
   roundedPiece(container,pieces,"PeelStrip",Vector3.new(.5*(1-t*.55),.16,.6),offset,Color3.fromRGB(255,214,66))
   roundedPiece(container,pieces,"PeelInside",Vector3.new(.32*(1-t*.55),.08,.5),offset+Vector3.yAxis*.075,Color3.fromRGB(255,240,179))
  end
 end
 placePieces(pieces,CFrame.new(position))
 local duration=math.clamp(tonumber(data.duration) or 8,.1,15)
 table.insert(self.traps,{container=container,source=data.source,expires=workspace:GetServerTimeNow()+duration})
 Debris:AddItem(container,duration+.1)
end
function Effects:EndProjectile(data)
 if data.id==nil then return end
 for i=#self.projectiles,1,-1 do
  local projectile=self.projectiles[i]
  if projectile.id==data.id and projectile.source==data.source then projectile.container:Destroy();table.remove(self.projectiles,i) end
 end
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
function Effects:Sound(position,id,pitch,volume,options)
 return CombatAudio.PlayRaw(self.folder,position,id,pitch,volume,options)
end
function Effects:Cue(position,kind,fighterId)
 return CombatAudio.Play(self.folder,position,kind,fighterId)
end
function Effects:UltimatePulse(position,data,final)
 local id=data.fighterId or (data.source and data.source:GetAttribute("FighterId"))
 if id=="tralalero" then
  local strike=table.clone(data);strike.combo=final and 3 or 1;strike.fighterId=id
  self:FighterStrike(position,strike)
  local aim=data.aim or Vector3.new(0,0,-1)
  for side=-1,1,2 do
   local frame=CFrame.lookAt(position,position+aim)
   for i=1,12 do
    local function point(t) return frame:PointToWorldSpace(Vector3.new(side*(1+math.sin(t*math.pi)*2),-.9+math.sin(t*math.pi)*1.5,2-t*9)) end
    self:Stroke(point((i-1)/12),point(i/12),CYAN,.25,.3,"FrenzyWaterCrest")
   end
  end
  self:Cue(position,"Splash",id)
 elseif id=="ballerina" then
  for band=1,2 do
   for i=1,30 do
    local function point(t)
     local a=t*math.pi*2+band*math.pi
     return position+Vector3.new(math.sin(a)*(final and 6.5 or 4.5),-1.8+t*3.8,math.cos(a)*(final and 6.5 or 4.5))
    end
    self:Stroke(point((i-1)/30),point(i/30),band==1 and ROSE or Color3.fromRGB(255,237,216),final and .28 or .17,.4,"BalletRibbon")
   end
  end
  self:Cue(position,final and "Slam" or "Whoosh",id)
 elseif id=="chimpanzini" then
  -- A peel-shaped halo announces the fruit volley without pretending to deal damage.
  for i=0,2 do
   local a=i*math.pi*2/3
   local from=position+Vector3.new(math.cos(a),.5,math.sin(a))
   self:Stroke(from,from+Vector3.new(math.cos(a)*2,2,math.sin(a)*2),GOLD,.25,.3,"BananaVolleyFan")
  end
  self:Cue(position,"Whoosh",id)
 else return false end
 return true
end
function Effects:Handle(kind,position,data)
 local fighterId=data.fighterId or (data.source and data.source:GetAttribute("FighterId")) or "tung_sahur"
 if kind=="FighterStrike" then
  self:FighterStrike(position,data)
 elseif kind=="MoveBurst" then
  self:MoveBurst(position,data)
 elseif kind=="TailSweep" then
  local aim=typeof(data.aim)=="Vector3" and data.aim or Vector3.new(0,0,-1)
  self:Arc(position-Vector3.yAxis*1.2,aim,data.radius or 4.5,CYAN,false)
  local frame=CFrame.lookAt(position,position+aim)
  for i=-1,1 do
   local p=frame:PointToWorldSpace(Vector3.new(i*1.2,-1.5,-3))
   self:Stroke(p,p+Vector3.yAxis*2.4,CYAN,.18,.3,"TailLiftFin")
  end
 elseif kind=="Projectile" then
  self:Projectile(position,data)
 elseif kind=="BombDrop" then
  self:BombDrop(position,data)
 elseif kind=="ProjectileEnd" then
  self:EndProjectile(data)
 elseif kind=="Counter" then
  self:Ring(position,4,CYAN,.3,false);self:Flash(position,CYAN,3)
 elseif kind=="Trap" then
  -- Persistent ring marks the exact server trigger area; one trap per source.
  self:Handle("TrapEnd",position,data)
  self:PeelTrap(position,data)
  self:Ring(position+Vector3.yAxis*.12,data.radius or 3.5,GOLD,data.duration or 8,false)
  local ring=self.rings[#self.rings];ring.fixed=true;ring.trapSource=data.source
 elseif kind=="TrapEnd" then
  for i=#self.traps,1,-1 do
   local trap=self.traps[i]
   if trap.source==data.source then trap.container:Destroy();table.remove(self.traps,i) end
  end
  for i=#self.rings,1,-1 do
   local ring=self.rings[i]
   if ring.trapSource and ring.trapSource==data.source then
    for _,p in ring.parts do p:Destroy() end;table.remove(self.rings,i)
   end
  end
 elseif kind=="Hit" then
  self:Flash(position,Color3.new(1,1,1),2.8); self:Number(position,data.damage)
  self:Burst(position,GOLD,9,4)
  if data.target then
   local highlight=Instance.new("Highlight"); highlight.Adornee=data.target
   highlight.FillColor=Color3.new(1,1,1); highlight.FillTransparency=0.15
   highlight.OutlineColor=GOLD; highlight.OutlineTransparency=0.1; highlight.Parent=self.folder
   TweenService:Create(highlight,TweenInfo.new(0.16),{FillTransparency=1,OutlineTransparency=1}):Play()
   Debris:AddItem(highlight,0.2)
  end
  local localCharacter=game.Players.LocalPlayer and game.Players.LocalPlayer.Character
  if data.source==localCharacter or data.target==localCharacter then self.kick=math.max(self.kick,0.16) end
  self:Cue(position,"Hit",fighterId)
 elseif kind=="Swing" then
  self:Arc(position,data.aim,6.7,GOLD,false)
  self:Cue(position,"Whoosh",fighterId)
 elseif kind=="Slam" then
  self:Ring(position+Vector3.yAxis*0.15,data.radius or 9,GOLD,0.4,false)
  self:Flash(position,Color3.new(1,0.9,0.6),7)
  self:Burst(position+Vector3.yAxis*0.5,GOLD,22,9)
  if fighterId=="bombardiro" then
   for i=1,5 do
    local puff=part(self.folder,"BombSmoke");puff.Shape=Enum.PartType.Ball;puff.Material=Enum.Material.SmoothPlastic;puff.Color=Color3.fromRGB(74,79,71);puff.Transparency=.35
    puff.Size=Vector3.one*.6;puff.Position=position+Vector3.new(math.sin(i*2.4)*1.2,.7,math.cos(i*2.4)*1.2)
    TweenService:Create(puff,TweenInfo.new(.65),{Position=puff.Position+Vector3.yAxis*(2+i*.2),Size=Vector3.one*(2+i*.25),Transparency=1}):Play();Debris:AddItem(puff,.7)
   end
  end
  if game.Players.LocalPlayer and data.source==game.Players.LocalPlayer.Character then self.kick=0.3 end
  self:Cue(position,fighterId=="bombardiro" and "Blast" or "Slam",fighterId)
 elseif kind=="AlarmWarn" then
  -- Bomber warnings already arrive at the server's ground impact point.
  self:Ring(position-Vector3.yAxis*(fighterId=="bombardiro" and 0 or 2.6),data.radius,fighterId=="ballerina" and ROSE or fighterId=="tralalero" and CYAN or GOLD,data.duration or 0.35,false)
  self.rings[#self.rings].fixed=true
 elseif kind=="AlarmBeat" or kind=="AlarmStrike" or kind=="AlarmFinal" then
  local final=kind=="AlarmFinal"
  if fighterId~="tung_sahur" and self:UltimatePulse(position,data,final) then return end
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
  local localCharacter=game.Players.LocalPlayer and game.Players.LocalPlayer.Character
  local root=localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
  if root and (root.Position-position).Magnitude<=data.radius+8 then
   self.kick=math.max(self.kick,final and 0.4 or 0.2)
  end
  self:Cue(position,final and "Slam" or "Beat",fighterId)
 elseif kind=="Wave" or kind=="Toll" then
  if fighterId~="tung_sahur" and self:UltimatePulse(position,data,false) then return end
  self:Ring(position-Vector3.yAxis*2,data.radius,kind=="Toll" and GOLD or CYAN,0.65,false)
  if kind=="Wave" then self:Ring(position,data.radius,CYAN,0.65,true) end
  self:Flash(position,kind=="Toll" and GOLD or CYAN,kind=="Toll" and 10 or 4)
  self:Burst(position,kind=="Toll" and GOLD or CYAN,kind=="Toll" and 28 or 12,data.radius)
  if game.Players.LocalPlayer and data.source==game.Players.LocalPlayer.Character then self.kick=kind=="Toll" and 0.4 or 0.15 end
  self:Cue(position,kind=="Toll" and "Slam" or "Beat",fighterId)
 elseif kind=="Core" or kind=="Jump" then
  self:Ring(position-Vector3.yAxis*2,kind=="Core" and 4 or 3,CYAN,0.3,false)
 elseif kind=="Cast" then
  local fighterId=data.fighterId or (data.source and data.source:GetAttribute("FighterId")) or "tung_sahur"
  if data.key=="M1" and fighterId=="tung_sahur" then
   task.delay(data.combo==3 and 0.135 or 0.105,function()
    if self.folder.Parent then
     local root=data.source and data.source:FindFirstChild("HumanoidRootPart")
     self:Arc(root and root.Position or position,data.aim,4.5,GOLD,data.combo==3)
     self:Cue(root and root.Position or position,"Whoosh",fighterId)
    end
   end)
  elseif data.key=="R" and fighterId=="tung_sahur" then
   self:Ring(position,4,CYAN,0.4,false); self:Burst(position,CYAN,14,5)
   if game.Players.LocalPlayer and data.source==game.Players.LocalPlayer.Character then self.kick=0.18 end
  elseif data.key=="E" and fighterId=="tung_sahur" then
   self:Ring(position-Vector3.yAxis*2,3,GOLD,0.2,true)
  end
  if data.key=="F" then
   if not self:UltimatePulse(position,data,false) then self:Flash(position,fighterId=="bombardiro" and MINT or GOLD,3);self:Cue(position,"Launch",fighterId) end
  end
 end
end
function Effects:Step()
 local now=os.clock()
 local serverNow=workspace:GetServerTimeNow()
 for i=#self.traps,1,-1 do
  local trap=self.traps[i]
  if serverNow>=trap.expires or not trap.container.Parent or (trap.source and not trap.source.Parent) then
   trap.container:Destroy();table.remove(self.traps,i)
  end
 end
 for i=#self.moves,1,-1 do
  local motion=self.moves[i]
  local root=motion.source.Parent and motion.source:FindFirstChild("HumanoidRootPart")
  local humanoid=motion.source:FindFirstChildOfClass("Humanoid")
  local authoritativeMode=motion.source:GetAttribute("AbilityMotionMode")
  authoritativeMode=MOVE_ALIASES[authoritativeMode] or authoritativeMode
  local authoritativeUntil=motion.source:GetAttribute("AbilityMotionUntil") or 0
  if authoritativeMode==motion.mode and authoritativeUntil>serverNow then motion.observed=true end
  -- Allow one replication beat for attributes to arrive, then obey cancellation
  -- immediately (wall impact, interruption, fighter swap), not just the timer.
  local cancelled=(motion.observed or serverNow-motion.at>.2) and (authoritativeMode~=motion.mode or authoritativeUntil<=serverNow)
  if not root or not humanoid or humanoid.Health<=0 or serverNow-motion.at>=motion.duration or cancelled then
   table.remove(self.moves,i)
  elseif now-motion.lastEmit>=.08 then
   motion.lastEmit=now
   local frame=root.CFrame
   local color=motion.mode=="Flight" and MINT or (motion.mode=="AirStep" or motion.mode=="Pirouette" or motion.mode=="FinishingKick") and ROSE or (motion.mode=="Glide" or motion.mode=="PeelVault" or motion.mode=="CarpetRun") and GOLD or CYAN
   local width=motion.mode=="Flight" and 2.8 or motion.mode=="Glide" and 1.8 or 1.1
   for side=-1,1,2 do
    local a=frame:PointToWorldSpace(Vector3.new(side*width,-.45,1))
    local b=frame:PointToWorldSpace(Vector3.new(side*width,-.6,3.4))
    self:Stroke(a,b,color,.12,.24,motion.mode.."Wake")
   end
  end
 end
 for i=#self.projectiles,1,-1 do
  local projectile=self.projectiles[i];local age=math.max(0,serverNow-projectile.at)
  if age>=projectile.duration or not projectile.container.Parent then
   projectile.container:Destroy();table.remove(self.projectiles,i)
  else
   local position=projectile.origin+projectile.velocity*age
   local direction=projectile.velocity.Magnitude>.01 and projectile.velocity.Unit or Vector3.new(0,0,-1)
   local frame
   if projectile.kind=="Drop" then frame=CFrame.new(position)*CFrame.Angles(0,age*2,0)
   elseif projectile.kind=="Banana" then frame=CFrame.lookAt(position,position+direction)*CFrame.Angles(0,0,age*13)
   else frame=CFrame.lookAt(position,position+direction)*CFrame.Angles(math.pi/2,age*2,0) end
   placePieces(projectile.pieces,frame)
  end
 end
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
 if (character:GetAttribute("FighterId") or visual:GetAttribute("FighterId") or "tung_sahur")~="tung_sahur" then return end
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
