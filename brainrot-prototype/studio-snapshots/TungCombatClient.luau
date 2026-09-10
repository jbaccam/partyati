local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local ContextActionService=game:GetService("ContextActionService")
local CollectionService=game:GetService("CollectionService")
local package=game.ReplicatedStorage:WaitForChild("TungPrototype")
local Config=require(package.Config)
local Fighter=require(package.FighterDefinitions).ById.tung_sahur
local Effects=require(package.CombatEffects)
local input=package:WaitForChild("CombatInput")
local fx=Effects.new()
local player=Players.LocalPlayer
local mouse=player:GetMouse()
-- Only the server can authorize a lift. Apply once on the existing physics owner,
-- retaining current horizontal velocity and the normal Humanoid steering.
package:WaitForChild("CombatMotion").OnClientEvent:Connect(function(character,y,at)
 if character~=player.Character or not character:GetAttribute("TungSahurActive") then return end
 if typeof(y)~="number" or typeof(at)~="number" or math.abs(workspace:GetServerTimeNow()-at)>0.75 then return end
 local root=character:FindFirstChild("HumanoidRootPart")
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 if not root or root.Anchored or not humanoid or humanoid.Health<=0 then return end
 if y>0 then humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end
 local velocity=root.AssemblyLinearVelocity
 root.AssemblyLinearVelocity=Vector3.new(velocity.X,y,velocity.Z)
end)
local function active()
 local c=player.Character
 return package:GetAttribute("CombatAvailable")==true and c and c:GetAttribute("TungSahurActive")==true
end
local function aim()
 local c=player.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
 if not root then return Vector3.new(0,0,-1) end
 local dir=root.CFrame.LookVector
 if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
  local delta=mouse.Hit.Position-root.Position
  if Vector3.new(delta.X,0,delta.Z).Magnitude>1 then dir=delta end
 else
  local h=c:FindFirstChildOfClass("Humanoid")
  if h and h.MoveDirection.Magnitude>0.1 then dir=h.MoveDirection end
 end
 dir=Vector3.new(dir.X,0,dir.Z)
 return dir.Magnitude>0.001 and dir.Unit or Vector3.new(0,0,-1)
end
local sprintRemote=package:WaitForChild("CombatSprint")
local sprintKeys={}
local sprintHeld=false
local function setSprint(enabled)
 if sprintHeld==enabled then return end
 sprintHeld=enabled
 sprintRemote:FireServer(enabled)
 local c=player.Character; local h=c and c:FindFirstChildOfClass("Humanoid")
 if h and active() then h.WalkSpeed=(enabled and 28 or Fighter.Stats.WalkSpeed)*(1+(c:GetAttribute("BeatStacks") or 0)*.04) end
end
ContextActionService:BindActionAtPriority("TungSprint",function(_,state,object)
 if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then
  sprintKeys[object.KeyCode]=nil
  setSprint(next(sprintKeys)~=nil)
 elseif state==Enum.UserInputState.Begin and active() and not UserInputService:GetFocusedTextBox() then
  sprintKeys[object.KeyCode]=true; setSprint(true)
 end
 return active() and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
end,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift)
UserInputService.WindowFocusReleased:Connect(function() table.clear(sprintKeys); setSprint(false); end)
local lastSent={}
local heldM1=false
local function send(key)
 if not active() or UserInputService:GetFocusedTextBox() then return end
 local now=os.clock()
 if now-(lastSent[key] or -math.huge)<0.12 then return end
 lastSent[key]=now
 input:FireServer(key,aim())
end
local bindings={
 {"M1",Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2},
 {"Q",Enum.KeyCode.Q,Enum.KeyCode.ButtonL1},
 {"E",Enum.KeyCode.E,Enum.KeyCode.ButtonR1},
 {"R",Enum.KeyCode.R,Enum.KeyCode.ButtonY},
 {"F",Enum.KeyCode.F,Enum.KeyCode.ButtonB},
}
for _,entry in bindings do
 ContextActionService:BindAction("TungCombat_"..entry[1],function(_,state)
  if not active() or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
  if entry[1]=="M1" then heldM1=state==Enum.UserInputState.Begin end
  if state==Enum.UserInputState.Begin then send(entry[1]) end
  return Enum.ContextActionResult.Sink
 end,false,entry[2],entry[3])
end
local freefallAt=0
local function jump()
 if not active() then return end
 local h=player.Character:FindFirstChildOfClass("Humanoid")
 if h and h:GetState()==Enum.HumanoidStateType.Freefall and os.clock()-freefallAt>0.12 then send("Jump") end
end
UserInputService.InputBegan:Connect(function(key,processed)
 if not processed and (key.KeyCode==Enum.KeyCode.Space or key.KeyCode==Enum.KeyCode.ButtonA) then jump() end
end)
UserInputService.JumpRequest:Connect(jump)
local charConnections={}
local function watch(character)
 table.clear(sprintKeys); sprintHeld=false
 for _,c in charConnections do c:Disconnect() end
 table.clear(charConnections); table.clear(lastSent); freefallAt=os.clock()
 local h=character:WaitForChild("Humanoid",10); if not h then return end
 table.insert(charConnections,character:GetAttributeChangedSignal("TungSahurActive"):Connect(function()
  if not active() then table.clear(sprintKeys); setSprint(false) end
 end))
 table.insert(charConnections,h.StateChanged:Connect(function(_,state)
  if state==Enum.HumanoidStateType.Freefall then freefallAt=os.clock() end
 end))
end
player.CharacterAdded:Connect(watch)
if player.Character then task.spawn(watch,player.Character) end

local gui=Instance.new("ScreenGui"); gui.Name="TungCombatHUD"; gui.ResetOnSpawn=false
gui.DisplayOrder=11; gui.Parent=player:WaitForChild("PlayerGui")
local INK=Color3.fromRGB(56,48,41)
local CREAM=Color3.fromRGB(255,247,225)
local AMBER=Color3.fromRGB(244,190,82)
local TEAL=Color3.fromRGB(71,168,148)
local MUTED=Color3.fromRGB(204,198,181)
local function round(object,radius)
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,radius);c.Parent=object
end
local function outline(object,color,width)
 local s=Instance.new("UIStroke");s.Color=color;s.Thickness=width or 2;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=object
end
local function box(name,parent,x,y,w,h,color,radius)
 local f=Instance.new("Frame");f.Name=name;f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h)
 f.BackgroundColor3=color;f.BorderSizePixel=0;f.Parent=parent
 if radius then round(f,radius) end
 return f
end
local function text(name,parent,position,size,font,textSize)
 local label=Instance.new("TextLabel");label.Name=name;label.BackgroundTransparency=1
 label.Position=position;label.Size=size;label.Font=font or Enum.Font.FredokaOne
 label.TextSize=textSize or 14;label.TextColor3=INK;label.TextXAlignment=Enum.TextXAlignment.Left
 label.Parent=parent;return label
end
local panel=Instance.new("Frame");panel.Name="AbilityBar";panel.AnchorPoint=Vector2.new(.5,1)
panel.Position=UDim2.new(.5,0,1,-16);panel.Size=UDim2.fromOffset(608,186)
panel.BackgroundTransparency=1;panel.Parent=gui
local scale=Instance.new("UIScale");scale.Parent=panel
local headerBase=box("HeaderBase",panel,0,4,608,43,INK,15)
local header=box("FighterStrip",panel,0,0,608,43,CREAM,15);outline(header,INK,2)
local title=text("Fighter",header,UDim2.fromOffset(14,3),UDim2.fromOffset(184,35),nil,22);title.Text="TUNG SAHUR"
local healthBg=box("HealthTrack",header,210,22,233,10,Color3.fromRGB(219,212,191),5)
local healthFill=box("HealthFill",healthBg,0,0,233,10,TEAL,5);healthFill.Size=UDim2.fromScale(1,1)
local stats=text("HealthBeat",header,UDim2.fromOffset(210,3),UDim2.fromOffset(233,18),nil,14)
stats.TextXAlignment=Enum.TextXAlignment.Center
local beatLabel=text("BeatTitle",header,UDim2.fromOffset(468,3),UDim2.fromOffset(124,17),nil,13)
beatLabel.Text="KEEP THE BEAT";beatLabel.TextXAlignment=Enum.TextXAlignment.Center
local beatPips={}
for i=1,3 do local pip=box("Beat"..i,header,482+(i-1)*32,24,24,10,MUTED,5);beatPips[i]=pip end
local keys={"M1","Q","E","R","F"}
local names={"Wooden Hands","Bat Beat","Sahur Slam","Dawn Call","Midnight Alarm"}
local pads={M1="RT",Q="LB",E="RB",R="Y",F="B"}
local buttons={}
local function icon(parent,key)
 local group=box("AbilityIcon",parent,47,9,51,32,INK);group.BackgroundTransparency=1
 local function shape(x,y,w,h,angle)
  local f=box("Shape",group,x,y,w,h,INK,3);f.Rotation=angle or 0;return f
 end
 if key=="M1" then
  shape(12,13,25,17);shape(6,19,10,9,-30)
  for n=0,3 do shape(10+n*7,4,6,14) end
 elseif key=="Q" or key=="F" then
  shape(20,1,12,23,35);shape(14,20,6,13,35);shape(10,28,11,4,35)
  if key=="F" then
   for n=1,2 do local ring=box("Echo",group,27+n*4,3-n*2,9+n*4,19+n*4,INK,12);ring.BackgroundTransparency=1;outline(ring,INK,2) end
  end
 elseif key=="E" then
  shape(22,0,7,19);shape(15,11,7,15,-45);shape(29,11,7,15,45)
  shape(5,27,16,4,-12);shape(29,27,16,4,12)
 else
  shape(22,8,7,22);shape(16,0,7,17,45);shape(28,0,7,17,-45)
  shape(7,16,4,13);shape(40,16,4,13)
 end
end
for i,key in keys do
 local x=(i-1)*124
 local base=box(key.."Base",panel,x,59,112,101,INK,15)
 local button=Instance.new("TextButton");button.Name=key
 button.Position=UDim2.fromOffset(x,53);button.Size=UDim2.fromOffset(112,101)
 button.BackgroundColor3=CREAM;button.BorderSizePixel=0;button.Text="";button.AutoButtonColor=false;button.Parent=panel
 round(button,15);outline(button,INK,2)
 local chip=box("KeyChip",button,8,8,31,29,INK,9)
 local hotkey=text("Key",chip,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),nil,16)
 hotkey.TextColor3=CREAM;hotkey.TextXAlignment=Enum.TextXAlignment.Center
 icon(button,key)
 local name=text("Name",button,UDim2.fromOffset(6,43),UDim2.fromOffset(100,33),nil,15)
 name.Text=names[i];name.TextWrapped=true;name.TextXAlignment=Enum.TextXAlignment.Center
 local status=text("Status",button,UDim2.fromOffset(5,79),UDim2.fromOffset(102,17),Enum.Font.GothamBold,10)
 status.TextXAlignment=Enum.TextXAlignment.Center
 local entry={button=button,key=hotkey,status=status,base=base,down=false}
 local function press(down)
  entry.down=down;button.Position=UDim2.fromOffset(x,down and 57 or 53)
 end
 button.MouseButton1Down:Connect(function() press(true) end)
 button.MouseButton1Up:Connect(function() press(false) end)
 button.MouseLeave:Connect(function() press(false) end)
 button.Activated:Connect(function() press(false);send(key) end)
 buttons[key]=entry
end
local helpBase=box("HelpPill",panel,59,168,490,18,INK,9)
local help=text("Help",helpBase,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),Enum.Font.GothamBold,10)
help.TextColor3=CREAM;help.TextXAlignment=Enum.TextXAlignment.Center
help.Text="SHIFT  RUN    /    HOLD M1  COMBO    /    SPACE  AIR JUMP    /    G  CORE"
local bats={}
local function removeBat(visual)
 if bats[visual] then bats[visual]:Destroy(); bats[visual]=nil end
end
CollectionService:GetInstanceRemovedSignal(Config.VisualTag):Connect(function(visual) removeBat(visual); fx:ForgetVisual(visual) end)
RunService:BindToRenderStep("TungCombatCamera",Enum.RenderPriority.Camera.Value+1,function(dt) fx:Camera(dt) end)
package:WaitForChild("CombatFX").OnClientEvent:Connect(function(kind,position,data)
 if typeof(position)~="Vector3" or typeof(data)~="table" then return end
 local camera=workspace.CurrentCamera
 if camera and (camera.CFrame.Position-position).Magnitude>220 then return end
 fx:Handle(kind,position,data)
end)
local elapsed=0
RunService.PreRender:Connect(function(dt)
 fx:Step()
 if heldM1 and active() then
  local c=player.Character
  if (c:GetAttribute("CooldownM1") or 0)-workspace:GetServerTimeNow()<=0.14 then send("M1") end
 end
 for _,visual in CollectionService:GetTagged(Config.VisualTag) do
  fx:TrackVisual(visual)
  local character=visual.Parent
  local key=character and character:GetAttribute("CombatAction")
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if (key=="Q" or key=="F") and character and character.Parent and humanoid and humanoid.Health>0 then
   local mesh=visual:FindFirstChild("Mesh")
   local hand=mesh and mesh:FindFirstChild("Bone.008",true)
   if hand then
    if not bats[visual] then
     local bat=package.Assets.WoodenBat:Clone(); bat.Name="BatBeatVisual"; bat.Parent=fx.folder; bats[visual]=bat
     local a=Instance.new("Attachment"); a.Position=bat:GetAttribute("TrailHandle"); a.Parent=bat
     local b=Instance.new("Attachment"); b.Position=bat:GetAttribute("TrailTip"); b.Parent=bat
     local trail=Instance.new("Trail"); trail.Name="BatSwingTrail"; trail.Enabled=false; trail.Attachment0=a; trail.Attachment1=b; trail.FaceCamera=true; trail.Lifetime=0.16
     trail.Color=ColorSequence.new(Color3.new(1,1,0.9),Color3.fromRGB(255,177,52)); trail.LightEmission=1; trail.Transparency=NumberSequence.new(0.15,1); trail.Parent=bat
    end
    local handFrame=hand.TransformedWorldCFrame
    local handGrip=hand:FindFirstChild("WeaponGrip")
    local bat=bats[visual]
    local trail=bat:FindFirstChild("BatSwingTrail")
    local age=workspace:GetServerTimeNow()-(character:GetAttribute("CombatActionAt") or 0)
    local swinging=key=="Q" and age>=0.14 and age<=0.34
    if key=="F" then
     for _,hit in Fighter.Ultimate.Hits do
      if age>=hit.At-0.16 and age<=hit.At+0.1 then swinging=true; break end
     end
    end
    if trail then
     if trail.Enabled and not swinging then trail:Clear() end
     trail.Enabled=swinging
    end
    local attachment=bat:FindFirstChild("BatGrip")
    if attachment and handGrip then
     -- Both position and rotation follow the hand's editable grip attachment.
     bat.CFrame=handFrame*handGrip.CFrame*attachment.CFrame:Inverse()
    end
   end
  else removeBat(visual) end
 end
 for visual in bats do if not visual.Parent then removeBat(visual) end end
 elapsed+=dt; if elapsed<0.05 then return end; elapsed=0
 gui.Enabled=active() and true or false
 if not gui.Enabled then return end
 local camera=workspace.CurrentCamera
 scale.Scale=math.clamp(camera and (camera.ViewportSize.X-24)/608 or 1,0.55,1)
 local character=player.Character; local h=character:FindFirstChildOfClass("Humanoid")
 if not h then return end
 local now=workspace:GetServerTimeNow(); local beat=character:GetAttribute("BeatStacks") or 0
 stats.Text=string.format("%d / %d HP",math.ceil(h.Health),h.MaxHealth)
 for i,pip in beatPips do pip.BackgroundColor3=i<=beat and AMBER or MUTED end
 if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
  help.Text="TAP AN ABILITY    /    COLLECT A CORE TO USE YOUR ULTIMATE"
 elseif UserInputService.GamepadEnabled then
  help.Text="RT  COMBO    /    A  AIR JUMP    /    COLLECT A CORE FOR YOUR ULTIMATE"
 else help.Text="SHIFT  RUN    /    HOLD M1  COMBO    /    SPACE  AIR JUMP    /    G  CORE" end
 healthFill.Size=UDim2.fromScale(math.clamp(h.Health/math.max(1,h.MaxHealth),0,1),1)
 for key,entry in buttons do
  local remaining=math.max(0,(character:GetAttribute("Cooldown"..key) or 0)-now)
  local ready=remaining==0
  local status="READY"
  if h.Health<=0 then status="RESPAWNING"; ready=false
  elseif key=="F" and character:GetAttribute("CombatAction")=="F" then status="BOOM TIME";ready=false
  elseif key=="F" and not character:GetAttribute("UltimateReady") then status="NEED CORE"; ready=false
  elseif remaining>0 then status=string.format("%.1fs",remaining)
  elseif key=="R" and character:GetAttribute("RecoveryUsed") then status="LAND TO RESET"; ready=false end
  entry.key.Text=UserInputService.GamepadEnabled and pads[key] or key
  entry.status.Text=status
  entry.status.TextColor3=ready and Color3.fromRGB(35,112,94) or Color3.fromRGB(91,84,71)
  entry.button.BackgroundColor3=ready and (key=="F" and AMBER or CREAM) or MUTED
 end
end)
