local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local package=game.ReplicatedStorage:WaitForChild("TungPrototype")
local Config=require(package.Config)
local Service=require(script.Parent.TungCombatService)
local function remote(name)
 local object=package:FindFirstChild(name) or Instance.new("RemoteEvent")
 object.Name=name; object.Parent=package; return object
end
local input=remote("CombatInput")
local effects=remote("CombatFX")
local motion=remote("CombatMotion")
local sprint=remote("CombatSprint")
local moveIntent=remote("CombatMoveIntent")
local steer=remote("CombatSteer")
local allowed=RunService:IsStudio() or Config.EnablePublished
package:SetAttribute("CombatAvailable",allowed)
if not allowed then return end
local service=Service.new(workspace,function(kind,position,data)
 effects:FireAllClients(kind,position,data)
end,function(character,y,at,horizontal)
 local player=Players:GetPlayerFromCharacter(character)
 local root=character:FindFirstChild("HumanoidRootPart")
 if not player or not root or root:GetNetworkOwner()~=player then return false end
 motion:FireClient(player,character,y,at,horizontal)
 return true
end)
local watches={}
local function unwatch(character)
 local connections=watches[character]
 if connections then for _,c in connections do c:Disconnect() end end
 watches[character]=nil; service:Remove(character)
end
local function watch(character)
 if watches[character] then return end
 watches[character]={}
 task.spawn(function()
  local humanoid=character:WaitForChild("Humanoid",10)
  local root=character:WaitForChild("HumanoidRootPart",10)
  if not watches[character] or not character.Parent or not humanoid or not root then return end
  service:Register(character,character:GetAttribute("TungSahurActive")==true)
  character:SetAttribute("TungInvulnerableUntil",workspace:GetServerTimeNow()+2)
  table.insert(watches[character],character:GetAttributeChangedSignal("TungSahurActive"):Connect(function()
   service:SetActive(character,character:GetAttribute("TungSahurActive")==true)
  end))
  table.insert(watches[character],character:GetAttributeChangedSignal("FighterId"):Connect(function()
   service:SetActive(character,false)
   service:SetActive(character,character:GetAttribute("TungSahurActive")==true)
  end))
 end)
end
local playerConnections={}
local function addPlayer(player)
 playerConnections[player]={
  player.CharacterAdded:Connect(watch),
  player.CharacterRemoving:Connect(unwatch),
 }
 if player.Character then watch(player.Character) end
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
 if player.Character then unwatch(player.Character) end
 for _,c in playerConnections[player] or {} do c:Disconnect() end
 playerConnections[player]=nil
end)
for _,player in Players:GetPlayers() do addPlayer(player) end
input.OnServerEvent:Connect(function(player,key,aim,...)
 if select("#",...)~=0 or typeof(key)~="string" or #key>4 or typeof(aim)~="Vector3" then return end
 local character=player.Character
 if character then service:Request(character,key,aim,workspace:GetServerTimeNow()) end
end)
sprint.OnServerEvent:Connect(function(player,enabled,...)
 if select("#",...)~=0 or typeof(enabled)~="boolean" then return end
 if player.Character then service:SetSprint(player.Character,enabled,workspace:GetServerTimeNow()) end
end)
moveIntent.OnServerEvent:Connect(function(player,moving,...)
 if select("#",...)~=0 or typeof(moving)~="boolean" then return end
 if player.Character and service.SetMoveIntent then service:SetMoveIntent(player.Character,moving,workspace:GetServerTimeNow()) end
end)
steer.OnServerEvent:Connect(function(player,aim,...)
 if select("#",...)~=0 or typeof(aim)~="Vector3" then return end
 if player.Character then service:SetSteer(player.Character,aim,workspace:GetServerTimeNow()) end
end)
-- NPCs opt in explicitly; decorative marketplace models are never combat targets.
local function addTarget(target)
 if target:IsA("Model") then service:Register(target,false) end
end
CollectionService:GetInstanceAddedSignal("BrainrotCombatTarget"):Connect(addTarget)
CollectionService:GetInstanceRemovedSignal("BrainrotCombatTarget"):Connect(function(target)
 if not Players:GetPlayerFromCharacter(target) then service:Remove(target) end
end)
for _,target in CollectionService:GetTagged("BrainrotCombatTarget") do addTarget(target) end
local cores={}
local function addCore(part)
 if not part:IsA("BasePart") or cores[part] then return end
 local prompt=part:FindFirstChild("CollectCore") or Instance.new("ProximityPrompt")
 prompt.Name="CollectCore"; prompt.ActionText="Collect Core"; prompt.ObjectText="Fighter Ultimate"
 prompt.KeyboardKeyCode=Enum.KeyCode.G; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
 prompt.MaxActivationDistance=8; prompt.HoldDuration=0.35; prompt.RequiresLineOfSight=true; prompt.Parent=part
 cores[part]={prompt=prompt,readyAt=0,transparency=part.Transparency}
 cores[part].connection=prompt.Triggered:Connect(function(player)
  local entry=cores[part]; local now=workspace:GetServerTimeNow()
  local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart")
  if not entry or now<entry.readyAt or not root or (root.Position-part.Position).Magnitude>9 then return end
  if not service:Visible(root.Position,part.Position) or not service:GrantCore(character) then return end
  entry.readyAt=now+(part:GetAttribute("RespawnSeconds") or 30)
  prompt.Enabled=false; part.Transparency=0.85
 end)
end
CollectionService:GetInstanceAddedSignal("BrainrotCore"):Connect(addCore)
CollectionService:GetInstanceRemovedSignal("BrainrotCore"):Connect(function(part)
 local entry=cores[part]; if entry then entry.connection:Disconnect(); cores[part]=nil end
end)
for _,part in CollectionService:GetTagged("BrainrotCore") do addCore(part) end

local trainingDummy
if RunService:IsStudio() and package:GetAttribute("PracticeEnabled")~=false then
 local folder=Instance.new("Folder"); folder.Name="TungCombatPractice"; folder.Parent=workspace
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
 local origin=spawn and spawn.Position or Vector3.zero
 local pad=Instance.new("Part"); pad.Name="PracticePad"; pad.Size=Vector3.new(28,1,24)
 pad.Anchored=true; pad.Material=Enum.Material.Slate; pad.Color=Color3.fromRGB(38,43,51)
 pad.Position=origin+Vector3.new(0,0,-24); pad.Parent=folder
 local model=Instance.new("Model"); model.Name="Tung Practice Dummy"
 local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Size=Vector3.new(2,2,1)
 root.Anchored=true; root.Transparency=1; root.CanCollide=false
 root.CFrame=CFrame.new(pad.Position+Vector3.new(0,3.5,0))*CFrame.Angles(0,math.pi,0); root.Parent=model
 local humanoid=Instance.new("Humanoid"); humanoid.RequiresNeck=false
 humanoid.MaxHealth=115; humanoid.Health=115; humanoid.DisplayName="Practice Tung"; humanoid.WalkSpeed=0
 humanoid.Parent=model; model.PrimaryPart=root
 local visual=package.Assets.TungSahur:Clone(); visual.Name=Config.VisualName
 visual:PivotTo(root.CFrame*CFrame.new(0,-0.2,0))
 for _,obj in visual:GetDescendants() do
  if obj:IsA("BasePart") then obj.Anchored=true; obj.CanCollide=false; obj.CanQuery=false; obj.CanTouch=false end
 end
 visual.Parent=model; model.Parent=folder
 CollectionService:AddTag(visual,Config.VisualTag)
 CollectionService:AddTag(model,"BrainrotCombatTarget")
 local core=Instance.new("Part"); core.Name="Brainrot Core"; core.Shape=Enum.PartType.Ball
 core.Size=Vector3.new(2,2,2); core.Anchored=true; core.CanCollide=false; core.CanQuery=false
 core.Material=Enum.Material.Neon; core.Color=Color3.fromRGB(114,229,255)
 core.Position=pad.Position+Vector3.new(9,3,6); core:SetAttribute("RespawnSeconds",12); core.Parent=folder
 CollectionService:AddTag(core,"BrainrotCore")
 local light=Instance.new("PointLight"); light.Color=core.Color; light.Range=12; light.Brightness=1.2; light.Parent=core
 local board=Instance.new("BillboardGui"); board.Name="PracticeInstructions"; board.Size=UDim2.fromOffset(360,74)
 board.StudsOffset=Vector3.new(0,7,0); board.AlwaysOnTop=true; board.Parent=root
 local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=0.2
 label.BackgroundColor3=Color3.fromRGB(22,27,34); label.TextColor3=Color3.fromRGB(255,222,145)
 label.TextSize=17; label.Font=Enum.Font.GothamBold
 label.Text="SMASH / PRACTICE\nB choose fighter | M1 combo | Q / E attacks | R recover\nCollect the blue Core with G, then press F"
 label.Parent=board
 -- Real knockback, followed by an idle return; lethal hits rebuild a fresh target.
 trainingDummy=require(script.Parent.TrainingDummy).new(model,{visualTag=Config.VisualTag,visualName=Config.VisualName})
end
RunService.Heartbeat:Connect(function(dt)
 local now=workspace:GetServerTimeNow()
 service:Step(now,dt)
 for part,entry in cores do
  if not part.Parent then entry.connection:Disconnect(); cores[part]=nil
  elseif now>=entry.readyAt and not entry.prompt.Enabled then
   entry.prompt.Enabled=true; part.Transparency=entry.transparency
  end
 end
end)
package:SetAttribute("CombatVersion",3)
print("[TungCombat] Ready: M1 / Q / E / R / F, Beat passive, server cooldowns and Core pickup.")
