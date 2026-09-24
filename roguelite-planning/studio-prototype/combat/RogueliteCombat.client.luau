local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local Input=game:GetService('UserInputService')
local combat=game:GetService('ReplicatedStorage'):WaitForChild('RogueliteCombat')
local Catalog=require(combat:WaitForChild('WeaponCatalog'))
local Motion=require(combat:WaitForChild('WeaponMotion'))
local Chains=require(combat:WaitForChild('ChainWeaponMotion'))
local Cards=require(combat:WaitForChild('CardPresentation'))
local templates=combat:WaitForChild('WeaponTemplates')
local states=combat:WaitForChild('PlayerStates')
local player=Players.LocalPlayer
local visuals=Instance.new('Folder');visuals.Name='RogueliteCombatVisuals';visuals.Parent=workspace
require(combat:WaitForChild('RocketVisuals')).mount(combat,visuals)
local bulletImpact=require(combat:WaitForChild('BulletImpactVisuals')).mount(visuals)
local muzzleFlash=require(combat:WaitForChild('MuzzleFlashVisuals')).mount(visuals)
local mobImpact=require(combat:WaitForChild('MobImpactVisuals')).mount(visuals)
local tracked={}
local ArcMotion=require(combat:WaitForChild('ArcMotion'))
require(combat:WaitForChild('ArcVisuals')).mount(combat,visuals,function(ownerId,index)
 local state=states:FindFirstChild(tostring(ownerId))
 local slot=state and state:FindFirstChild('Slot'..index)
 return slot and tracked[slot]
end)
require(combat:WaitForChild('SpecialWeaponVisuals')).mount(combat,visuals,function(owner,index)
 local state=states:FindFirstChild(tostring(owner));return state and tracked[state:FindFirstChild('Slot'..index)]
end)
local floats={}
RunService:BindToRenderStep('RogueliteWeapons',Enum.RenderPriority.Character.Value+1,function(dt)
 local now=workspace:GetServerTimeNow()
 local seen={}
 for _,state in states:GetChildren() do
  local owner=Players:GetPlayerByUserId(tonumber(state.Name));local character=owner and owner.Character
  local root=character and character:FindFirstChild('HumanoidRootPart');local hum=character and character:FindFirstChildOfClass('Humanoid')
  local float=floats[state]
  if root and hum and hum.Health>0 then
   if not float or float.root~=root then float=Motion.newFloat();float.root=root;floats[state]=float end
   Motion.stepFloat(float,root.CFrame,root.AssemblyLinearVelocity,dt)
  else floats[state]=nil;float=nil end
  for _,slot in state:GetChildren() do
   local id=slot:GetAttribute('WeaponId');local d=Catalog.ById[id]
   local v=tracked[slot];seen[slot]=true
   if v and v.id~=id then
    v.model:Destroy();tracked[slot]=nil;v=nil
    if float then float.slots[slot:GetAttribute('Index')]=nil end
   end
   local template=d and templates:FindFirstChild(id)
   if template and not v then
    local model=template:Clone();model.Name='Weapon_'..state.Name..'_'..slot.Name;model.Parent=visuals
    v={model=model,id=id,parts={},chain=Chains.bind(model,id),cards=Cards.bind(model,id)};tracked[slot]=v
    if id=='19' then
     v.gloves={}
     for _,part in model:GetDescendants() do if part:IsA('BasePart') then
      local localCF=model:GetPivot():ToObjectSpace(part.CFrame);table.insert(v.gloves,{part=part,localCF=localCF,side=localCF.X<0 and -1 or 1})
     end end
    end
    if id=='15' or id=='23' then
     v.reserves={}
     for i=2,3 do local copy=template:Clone();copy.Name='Reserve'..i;copy.Parent=model;v.reserves[i]=copy end
    end
    if id=='33' then v.lid=model:FindFirstChild('W33_Lid_Hinge',true) end
    for _,part in model:GetDescendants() do if part:IsA('BasePart') then
     part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
     table.insert(v.parts,part)
    end end
   end
   if v then
    local visible=root and hum and hum.Health>0 and state:GetAttribute('WeaponEnabled')
    if visible then
     local start=slot:GetAttribute('StartTime') or -1e6
     local rate=slot:GetAttribute('MotionRate') or 1
     local animationNow=start+(now-start)*rate
     local age=animationNow-start
     local kind=slot:GetAttribute('AttackKind') or d.kind
     local style=slot:GetAttribute('AttackStyle')
     local side=slot:GetAttribute('AttackSide') or 1
     local attackRoot=slot:GetAttribute('AttackRoot') or root.CFrame
     local _,activeEnd,duration=Motion.attackTiming(id,kind,style)
     local aim=slot:GetAttribute('AimPosition')
     if kind=='Melee' and age>=0 and age<duration then aim=slot:GetAttribute('AttackAim') end
     local radius=state:GetAttribute('RingRadius') or Motion.radius(root.Size,state:GetAttribute('EquippedCount'))
     local index=slot:GetAttribute('Index')
     local pose,idlePose
     if kind=='Melee' then
      -- Keep the follower running while the sword attacks. Recovery blends to
      -- its current moving position, so the cut snaps in but never snaps back.
      -- Rest/return facing belongs to the avatar, never the changing enemy.
      local idle=Motion.pose(root.CFrame,radius,index,nil,0,1e6,kind,id)
      if float then idle=Motion.floatPose(idle,root.CFrame,float,index,false,radius,false) end
      if v.gloves then idle*=CFrame.Angles(-math.pi/2,0,0) end
      pose=idle;idlePose=idle
      if age>=0 and age<duration then
       if not v.attackReturn or v.attackReturn.start~=start then
        v.attackReturn={start=start,entry=v.lastPose or idle,gloves={}}
        if v.gloves then for _,g in v.gloves do v.attackReturn.gloves[g.part]=g.part.CFrame end end
       end
       if v.chain then
        local cut=Chains.pose(v.chain,attackRoot,slot:GetAttribute('AttackDirection'),aim,math.min(age,activeEnd),slot:GetAttribute('SwingRange') or d.range,style,side)
        pose=age<=activeEnd and cut or Chains.swingReturn(v.chain,cut,idle,age,v.attackReturn)
       else
        local cut=Motion.pose(attackRoot,radius,index,aim,start,start+math.min(age,activeEnd),kind,id,
         slot:GetAttribute('AttackDirection'),slot:GetAttribute('SwingRange') or d.range,
         template:GetAttribute('BoundsSize'),template:GetAttribute('BoundsCenter'),style,side)
        pose=age<=activeEnd and cut or Motion.swingReturn(cut,idle,age,v.attackReturn,id,style)
       end
       if age<Motion.SwingHitStart then pose=v.attackReturn.entry:Lerp(pose,Motion.entryAlpha(age)) end
      else
       v.attackReturn=nil
      end
     else
      pose=Motion.pose(root.CFrame,radius,index,aim,start,animationNow,kind,id)
      if float then pose=Motion.floatPose(pose,root.CFrame,float,index,age>=0 and age<duration,radius,aim~=nil) end
     end
     if v.gloves then pose=idlePose or pose end
     v.lastPose=pose
     v.model:PivotTo(pose)
     if v.gloves then for _,g in v.gloves do g.part.CFrame=pose*g.localCF end end
     if v.gloves and age>=0 and age<duration then
      for _,g in v.gloves do
       local target=g.side==slot:GetAttribute('AttackHand') and aim or slot:GetAttribute('SecondAim')
       if target then
        local cut=Motion.glovePose(attackRoot,target,math.min(age,activeEnd),g.side,slot:GetAttribute('SwingRange') or d.range)
        local rest=pose*g.localCF
        local handPose=cut:Lerp(rest,Motion.swingRecovery(age))
        if age<Motion.SwingHitStart then handPose=(v.attackReturn.gloves[g.part] or rest):Lerp(handPose,Motion.entryAlpha(age))
        elseif age>activeEnd then handPose=CFrame.new(Motion.returnPosition(cut.Position,rest.Position,age))*handPose.Rotation end
        g.part.CFrame=handPose
       end
      end
     end
     if v.reserves then
      for i,copy in v.reserves do copy:PivotTo(pose*CFrame.new((i==2 and -1 or 1)*1.5,.35, .25)*CFrame.Angles(0,0,math.sin(now*3+i)*.12)) end
     end
     if id=='16' then
      local hitAge=now-(slot:GetAttribute('LastContact') or -1e6)
      if hitAge>=0 and hitAge<.3 then v.model:PivotTo(pose*CFrame.Angles(0,0,math.sin(hitAge*80)*.24*(1-hitAge/.3))) end
     end
     Chains.apply(v.chain,age)
     Cards.step(v.cards,now)
     if v.lid then v.lid.Transform=CFrame.Angles(0,-math.pi/2*ArcMotion.lid(now-start),0) end
    elseif float then
     float.slots[slot:GetAttribute('Index')]=nil
    end
    for _,part in v.parts do
     local reserve=part:FindFirstAncestor('Reserve2') and 2 or part:FindFirstAncestor('Reserve3') and 3 or 1
     local flying=v.flying and v.flying[reserve] and v.flying[reserve]>0
     part.LocalTransparencyModifier=visible and not flying and 0 or 1
    end
    if v.cards then
     for _,entry in v.cards.cards do
      for _,gui in entry.model:GetDescendants() do if gui:IsA('SurfaceGui') then gui.Enabled=visible and now>=(entry.flyingUntil or 0) end end
      if now<(entry.flyingUntil or 0) then
       for _,part in entry.model:GetDescendants() do if part:IsA('BasePart') then part.LocalTransparencyModifier=1 end end
      end
     end
    end
   end
  end
 end
 for slot,v in tracked do if not seen[slot] then v.model:Destroy();tracked[slot]=nil end end
 for state in floats do if state.Parent~=states then floats[state]=nil end end
end)
combat:WaitForChild('Shot').OnClientEvent:Connect(function(origin,finish,kind,id,thickness,blastRadius,contact,normal,ownerId,slotIndex,first,mobContact,shotId)
 if contact and kind=='Ranged' and not mobContact then bulletImpact(finish,normal) end
 if first and Motion.MuzzleOffsets[id] and ownerId and slotIndex then
  local state=states:FindFirstChild(tostring(ownerId))
  local slot=state and state:FindFirstChild('Slot'..slotIndex)
  local v=slot and tracked[slot]
  if v and v.id==id then
   origin=v.model:GetPivot():PointToWorldSpace(Motion.MuzzleOffsets[id])
   if shotId then muzzleFlash(v.model,id,Motion.MuzzleOffsets[id],shotId) end
  end
 end
 local distance=(finish-origin).Magnitude;if distance<.01 then return end
 local p=Instance.new('Part');p.Name='WeaponShot';p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p.Material=Enum.Material.Neon;p.Color=kind=='Blast' and Color3.fromRGB(242,164,71) or Color3.fromRGB(255,231,179)
 p.Size=Vector3.new(thickness or .07,thickness or .07,distance);p.CFrame=CFrame.lookAt((origin+finish)/2,finish);p.Parent=visuals
 TweenService:Create(p,TweenInfo.new(.12),{Transparency=1}):Play();Debris:AddItem(p,.14)
 if kind=='Blast' then
  local burst=Instance.new('Part');burst.Name='WeaponBlast';burst.Shape=Enum.PartType.Ball;burst.Size=Vector3.one
  burst.Anchored=true;burst.CanCollide=false;burst.CanTouch=false;burst.CanQuery=false;burst.Material=Enum.Material.Neon
  burst.Color=p.Color;burst.Transparency=.6;burst.Position=finish;burst.Parent=visuals
  TweenService:Create(burst,TweenInfo.new(.25),{Size=Vector3.one*(blastRadius or 7)*2,Transparency=1}):Play();Debris:AddItem(burst,.3)
 end
end)
local function damageNumber(position,damage,color,name)
 local anchor=Instance.new('Part');anchor.Name=name or 'DamageNumber';anchor.Size=Vector3.one*.1;anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Position=position+Vector3.new((math.random()-.5)*.8,0,0);anchor.Parent=visuals
 local gui=Instance.new('BillboardGui');gui.Size=UDim2.fromOffset(100,60);gui.AlwaysOnTop=true;gui.MaxDistance=100;gui.Parent=anchor
 local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text=tostring(math.round(damage));text.Font=Enum.Font.GothamBold;text.TextSize=30;text.TextColor3=color;text.TextStrokeColor3=Color3.fromRGB(28,22,20);text.TextStrokeTransparency=.12;text.Parent=gui
 local scale=Instance.new('UIScale');scale.Scale=.65;scale.Parent=text
 TweenService:Create(scale,TweenInfo.new(.13,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 TweenService:Create(anchor,TweenInfo.new(.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=anchor.Position+Vector3.new(0,2,0)}):Play()
 task.delay(.42,function()if text.Parent then TweenService:Create(text,TweenInfo.new(.3),{TextTransparency=1,TextStrokeTransparency=1}):Play()end end)
 Debris:AddItem(anchor,.85)
end

combat:WaitForChild('Hit').OnClientEvent:Connect(function(position,damage,npc,impactPosition,lethal,secondary)
 if not lethal then mobImpact.hit(impactPosition or position-Vector3.yAxis*2,npc,secondary) end
 damageNumber(position,damage,Color3.fromRGB(255,246,218),'DamageNumber')
 if npc and npc.Parent then
  local previous=npc:FindFirstChild('WeaponHitFlash');if previous then previous:Destroy() end
  local flash=Instance.new('Highlight');flash.Name='WeaponHitFlash';flash.FillColor=Color3.new(1,1,1)
  flash.FillTransparency=0;flash.OutlineTransparency=1;flash.DepthMode=Enum.HighlightDepthMode.Occluded;flash.Parent=npc
  task.delay(.045,function()
   if flash.Parent then TweenService:Create(flash,TweenInfo.new(.09),{FillTransparency=1}):Play() end
  end)
  Debris:AddItem(flash,.15)
 end
end)

combat:WaitForChild('PlayerDamaged').OnClientEvent:Connect(function(damage)
 if type(damage)~='number' or damage~=damage or damage<=0 then return end
 local character=player.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 if not root or not humanoid then return end
 damageNumber(root.Position+Vector3.new(0,2.5,0),damage,Color3.fromRGB(235,72,72),'PlayerDamageNumber')
end)

-- Detached from the destroyed NPC; the server emits this once per death.
combat:WaitForChild('ZombiePopped').OnClientEvent:Connect(function(position)
 mobImpact.death(position)
end)

if RunService:IsStudio()then
 local gui=Instance.new('ScreenGui');gui.Name='RogueliteCombatTestControls';gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild('PlayerGui')
 local frame=Instance.new('Frame');frame.Position=UDim2.fromOffset(14,258);frame.Size=UDim2.fromOffset(210,152);frame.BackgroundColor3=Color3.fromRGB(29,34,43);frame.BackgroundTransparency=.08;frame.Parent=gui;Instance.new('UICorner',frame).CornerRadius=UDim.new(0,8)
 local heading=Instance.new('TextLabel');heading.Position=UDim2.fromOffset(10,5);heading.Size=UDim2.new(1,-20,0,23);heading.Text='COMBAT TEST';heading.TextSize=13;heading.Font=Enum.Font.GothamBold;heading.TextXAlignment=Enum.TextXAlignment.Left;heading.BackgroundTransparency=1;heading.TextColor3=Color3.fromRGB(210,215,225);heading.Parent=frame
 local own=states:WaitForChild(tostring(player.UserId))
 local function toggle(key)
  local value=key=='Zombies'and combat:GetAttribute('ZombiesEnabled')or own:GetAttribute('WeaponEnabled')
  if key=='Zombies'then value=combat:GetAttribute('ZombiesEnabled')end
  combat.SetTestOption:FireServer(key,not value)
 end
 local function button(key,y,hotkey)
  local b=Instance.new('TextButton');b.Position=UDim2.fromOffset(8,y);b.Size=UDim2.new(1,-16,0,32);b.BackgroundColor3=Color3.fromRGB(51,62,76);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamMedium;b.TextSize=15;b.Parent=frame;Instance.new('UICorner',b).CornerRadius=UDim.new(0,5)
  b.Activated:Connect(function()toggle(key)end)
  local function refresh()local enabled;if key=='Zombies'then enabled=combat:GetAttribute('ZombiesEnabled')else enabled=own:GetAttribute('WeaponEnabled')end;b.Text=key..': '..(enabled and 'ON' or 'OFF')..'  ['..hotkey..']';b.BackgroundColor3=enabled and Color3.fromRGB(51,75,83)or Color3.fromRGB(64,56,59)end
  if key=='Zombies'then combat:GetAttributeChangedSignal('ZombiesEnabled'):Connect(refresh)else own:GetAttributeChangedSignal('WeaponEnabled'):Connect(refresh)end;refresh()
 end
 button('Zombies',33,'Z');button('Weapons',72,'K')
 local run=game.ReplicatedStorage:WaitForChild('RogueliteRunState')
 local stop=Instance.new('TextButton');stop.Name='StopWave';stop.Position=UDim2.fromOffset(8,111);stop.Size=UDim2.new(1,-16,0,32);stop.TextColor3=Color3.new(1,1,1);stop.Font=Enum.Font.GothamMedium;stop.TextSize=15;stop.Parent=frame;Instance.new('UICorner',stop).CornerRadius=UDim.new(0,5)
 local function stopWave() if run:GetAttribute('Phase')=='Combat' then combat.SetTestOption:FireServer('StopWave',true) end end
 local function refreshStop()
  local active=run:GetAttribute('Phase')=='Combat'
  stop.Interactable=active;stop.AutoButtonColor=active
  stop.Text=active and 'Stop wave  [X]' or 'No wave running'
  stop.BackgroundColor3=active and Color3.fromRGB(99,57,59) or Color3.fromRGB(48,50,56)
  stop.TextTransparency=active and 0 or .35
 end
 stop.Activated:Connect(stopWave);run:GetAttributeChangedSignal('Phase'):Connect(refreshStop);refreshStop()
 Input.InputBegan:Connect(function(input,processed)if processed or Input:GetFocusedTextBox()then return end;if input.KeyCode==Enum.KeyCode.Z then toggle('Zombies')elseif input.KeyCode==Enum.KeyCode.K then toggle('Weapons')elseif input.KeyCode==Enum.KeyCode.X then stopWave()end end)
end
