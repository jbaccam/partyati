-- Optional, Studio-only four-stock sparring island. No wins, currency or DataStores.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")
local package=game.ReplicatedStorage:WaitForChild("TungPrototype")
local Config=require(package.Config)
local Rules=require(package.PracticeStockRules)
if package:GetAttribute("PracticeEnabled")==false then return end
local name="BrainrotSmashPractice"
assert(not workspace:FindFirstChild(name),"Practice island already exists; refusing unrelated overwrite")
local world=Instance.new("Folder");world.Name=name;world:SetAttribute("Owner","BrainrotMVP");world.Parent=workspace
local center=Vector3.new(6000,1000,6000)
world:SetAttribute("Center",center);world:SetAttribute("RingOutY",center.Y-28)
local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
local home=spawn and spawn.Position or Vector3.zero
local members={};local returnPending={};local requestAt={}
local function part(label,size,position,color)
 local p=Instance.new("Part");p.Name=label;p.Anchored=true;p.Size=size;p.Position=position
 p.Color=color or Color3.fromRGB(73,99,108);p.Material=Enum.Material.SmoothPlastic;p.Parent=world;return p
end
local function label(p,text,width)
 local gui=Instance.new("BillboardGui");gui.Name="Label";gui.Size=UDim2.fromOffset(width or 290,72)
 gui.StudsOffset=Vector3.new(0,4,0);gui.MaxDistance=85;gui.AlwaysOnTop=false;gui.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=Color3.fromRGB(36,48,55)
 t.BackgroundTransparency=.1;t.TextColor3=Color3.fromRGB(250,242,219);t.Font=Enum.Font.GothamBold
 t.TextSize=15;t.TextWrapped=true;t.Text=text;t.Parent=gui
 local corner=Instance.new("UICorner",t);corner.CornerRadius=UDim.new(0,12)
end
local platform=part("Arena",Vector3.new(72,4,60),center)
part("LeftStep",Vector3.new(14,2,14),center+Vector3.new(-41,5,0),Color3.fromRGB(112,147,147))
part("RightStep",Vector3.new(14,2,14),center+Vector3.new(41,5,0),Color3.fromRGB(112,147,147))
for _,x in {-19,19} do
 part("Cover",Vector3.new(5,10,9),center+Vector3.new(x,7,-8),Color3.fromRGB(155,128,96))
end
local entry=part("EnterSmashPractice",Vector3.new(3,1,3),home+Vector3.new(-10,1.5,-15),Color3.fromRGB(107,190,174))
label(entry,"SMASH PRACTICE\n4 stocks / knockback / ring-outs\nOptional test island — no rewards")
local exit=part("LeaveSmashPractice",Vector3.new(3,1,3),center+Vector3.new(0,2.5,24),Color3.fromRGB(107,190,174))
label(exit,"LEAVE PRACTICE\nFalling costs a stock. At 0, a new practice set starts.\nB switches fighters outside combat",350)
local core=part("PracticeCore",Vector3.new(2,2,2),center+Vector3.new(0,4,-19),Color3.fromRGB(114,229,255))
core.Shape=Enum.PartType.Ball;core.Material=Enum.Material.Neon;core.CanCollide=false
core:SetAttribute("RespawnSeconds",12);CollectionService:AddTag(core,"BrainrotCore")
local function status(player,state)
 player:SetAttribute("SmashPracticeActive",state~=nil)
 player:SetAttribute("SmashStocks",state and state.stocks or nil)
 player:SetAttribute("SmashStatus",state and (state.stocks==0 and "Resetting" or "Fighting") or nil)
end
local function teleport(character,position)
 local root=character:FindFirstChild("HumanoidRootPart");if not root then return end
 character:PivotTo(CFrame.lookAt(position,Vector3.new(center.X,position.Y,center.Z)))
 root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
end
local function protect(character)
 character:SetAttribute("TungInvulnerableUntil",workspace:GetServerTimeNow()+2)
end
local function lose(player,character,serial)
 local state=members[player]
 if not state or player.Character~=character then return end
 if Rules.Lose(state,serial,workspace:GetServerTimeNow()) then status(player,state) end
end
local function placeCharacter(player,character)
 local h=character:WaitForChild("Humanoid",10);local root=character:WaitForChild("HumanoidRootPart",10)
 if not h or not root or player.Character~=character then return end
 local state=members[player]
 if not state then
  if returnPending[player] then returnPending[player]=nil;teleport(character,home+Vector3.new(0,5,0)) end
  return
 end
 -- CharacterAdded may run before Roblox applies its final SpawnLocation pivot.
 -- Do not expose the newly loaded character to ring-out accounting during that
 -- placement window, and supersede any older pending placement for this member.
 state.spawnTicket=(state.spawnTicket or 0)+1;local ticket=state.spawnTicket
 task.wait(.2)
 if members[player]~=state or player.Character~=character or state.spawnTicket~=ticket
  or not character.Parent or not root.Parent or h.Health<=0 then return end
 local now=workspace:GetServerTimeNow()
 if state.stocks==0 and now<(state.resetAt or 0) then
  character:SetAttribute("CombatDisabled",true);root.Anchored=true
  task.wait(math.min(Rules.ResetDelay,state.resetAt-now))
  if not character.Parent then return end
  root.Anchored=false;character:SetAttribute("CombatDisabled",nil)
  if members[player]~=state or player.Character~=character or state.spawnTicket~=ticket or h.Health<=0 then return end
 end
 local serial=Rules.Spawn(state,workspace:GetServerTimeNow());if not serial then return end
 state.character=character
 local spawnPosition=center+Vector3.new((player.UserId%3-1)*10,6,15)
 state.spawnGraceUntil=workspace:GetServerTimeNow()+.75
 teleport(character,spawnPosition);protect(character);status(player,state)
 h.Died:Once(function() lose(player,character,serial) end)
 task.delay(.3,function()
  if members[player]~=state or player.Character~=character or state.character~=character
   or state.serial~=serial or not state.alive or not root.Parent or h.Health<=0 then return end
  -- A late default-spawn placement is thousands of studs away; a genuine early
  -- drop below the arena is not corrected and still loses a stock after grace.
  if math.abs(root.Position.X-center.X)>110 or math.abs(root.Position.Z-center.Z)>110 then
   teleport(character,spawnPosition)
  end
 end)
end
local function prompt(p,text,callback)
 local pr=Instance.new("ProximityPrompt");pr.Name="Interact";pr.ActionText=text;pr.ObjectText="Smash Practice"
 pr.KeyboardKeyCode=Enum.KeyCode.G;pr.HoldDuration=.35;pr.RequiresLineOfSight=true;pr.MaxActivationDistance=8;pr.Parent=p
 pr.Triggered:Connect(function(player)
  local now=workspace:GetServerTimeNow();if now-(requestAt[player] or -math.huge)<1 then return end
  requestAt[player]=now
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
  if not h or h.Health<=0 or not r or (r.Position-p.Position).Magnitude>9 then return end
  local sight=RaycastParams.new();sight.FilterType=Enum.RaycastFilterType.Exclude
  sight.FilterDescendantsInstances={c};sight.RespectCanCollide=true
  local obstruction=workspace:Raycast(r.Position,p.Position-r.Position,sight)
  if obstruction and obstruction.Instance~=p then return end
  local canSwitch=require(package.FighterSelectionRules).CanSwitch(c,workspace,now)
  if not canSwitch then player:SetAttribute("FighterSelectionStatus","Finish combat and recharge before changing practice areas");player:SetAttribute("FighterSelectionAt",now);return end
  callback(player,c)
 end)
end
prompt(entry,"Enter 4-stock test",function(player,c)
 if members[player] then return end
 members[player]=Rules.New();placeCharacter(player,c)
end)
prompt(exit,"Return to gallery",function(player,c)
 if not members[player] then return end
 members[player]=nil;status(player,nil);teleport(c,home+Vector3.new(-10,5,-11));protect(c)
end)
local function addPlayer(player)
 player.CharacterAdded:Connect(function(c) task.spawn(placeCharacter,player,c) end)
 if player.Character then task.spawn(placeCharacter,player,player.Character) end
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(p) members[p]=nil;returnPending[p]=nil;requestAt[p]=nil end)
for _,p in Players:GetPlayers() do addPlayer(p) end

-- A physically movable target lets solo testers see actual launch and ring-outs.
local target,root,humanoid
local function createTarget()
 target=Instance.new("Model");target.Name="Smash Sparring Target"
 root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,2);root.Transparency=1
 root.Position=center+Vector3.new(0,5,-5);root.CanCollide=true;root.Parent=target
 humanoid=Instance.new("Humanoid");humanoid.RequiresNeck=false;humanoid.HipHeight=2
 humanoid.MaxHealth=130;humanoid.Health=130;humanoid.WalkSpeed=0;humanoid.DisplayName="Sparring Target";humanoid.Parent=target
 target.PrimaryPart=root;target:SetAttribute("FighterId","tung_sahur");target:SetAttribute("CombatWeight",1.1)
 local visual=package.Assets.TungSahur:Clone();visual.Name=Config.VisualName
 visual:PivotTo(root.CFrame*CFrame.new(0,visual.Mesh.Size.Y/2-3,0));visual.Parent=target
 for _,v in visual:GetDescendants() do if v:IsA("BasePart") then v.Anchored=false;v.CanCollide=false;v.CanQuery=false;v.Massless=true end end
 local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=visual.Mesh;weld.Parent=root
 target.Parent=world;root:SetNetworkOwner(nil)
 CollectionService:AddTag(visual,Config.VisualTag);CollectionService:AddTag(target,"BrainrotCombatTarget")
 label(root,"SPARRING TARGET\nLaunch me off the edge\nReturns after 4s without a hit",250)
end
createTarget()
local trainingDummy=require(script.Parent.TrainingDummy).new(target,{
 visualTag=Config.VisualTag,visualName=Config.VisualName,ringOutY=center.Y-28,
 outOfBounds=function(position) return Rules.OutOfBounds(position,center) end,
})
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.08 then return end;elapsed=0
 for player,state in members do
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
  if state.alive and state.character==c and h and r and workspace:GetServerTimeNow()>=(state.spawnGraceUntil or 0)
   and Rules.OutOfBounds(r.Position,center) then
   lose(player,c,state.serial);h.Health=0
  end
 end
end)
print("[SmashPractice] Optional four-stock island ready. G at the green gallery pad to enter. No persistent rewards.")
