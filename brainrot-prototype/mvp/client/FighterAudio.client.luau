-- Locally replace default character audio only while a brainrot is active.
-- No global SoundService changes, no menu/audio-script disabling.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local package=game:GetService("ReplicatedStorage"):WaitForChild("TungPrototype")
local Audio=require(package:WaitForChild("CombatAudio"))
local folder=Instance.new("Folder");folder.Name="FighterMovementAudio";folder.Parent=workspace
Audio.Preload()
local defaults={Running=true,Jumping=true,Landing=true,FreeFalling=true,Climbing=true,Swimming=true,Splash=true,GettingUp=true,Died=true}
local records={}
local connections={}
local function active(character)
 return character:GetAttribute("TungSahurActive")==true
end
local function release(record)
 for sound,saved in record.muted do
  saved.connection:Disconnect()
  if sound.Parent then sound.Volume=saved.volume end
 end
 table.clear(record.muted)
 record.distance=0;record.airAt=nil;record.lastPosition=nil;record.grounded=nil;record.fallSpeed=0
end
local function mute(record,sound)
 if not (sound:IsA("Sound") or sound:IsA("AudioPlayer")) or not defaults[sound.Name] or sound:GetAttribute("BrainrotCustomAudio") then return end
 if record.muted[sound] then return end
 local saved={volume=sound.Volume}
 record.muted[sound]=saved
 saved.connection=sound:GetPropertyChangedSignal("Volume"):Connect(function()
  if sound.Volume~=0 then saved.volume=sound.Volume;sound.Volume=0 end
 end)
 sound.Volume=0
end
local function cue(record,kind,gain)
 local now=os.clock()
 if (kind=="Jump" or kind=="AirJump") and now-record.lastJump<.1 then return end
 if kind=="Jump" or kind=="AirJump" then record.lastJump=now end
 local root=record.character:FindFirstChild("HumanoidRootPart")
 if root then Audio.Play(folder,root.Position,kind,record.character:GetAttribute("FighterId"),gain) end
end
local function remove(character)
 local record=records[character];if not record then return end
 release(record);for _,connection in record.connections do connection:Disconnect() end
 records[character]=nil
end
local function attach(character)
 if records[character] then return end
 local record={character=character,muted={},connections={},distance=0,lastJump=-math.huge,lastLand=-math.huge,enabled=false}
 records[character]=record
 local function refresh()
  local enabled=active(character)
  if not enabled then release(record) end
  record.enabled=enabled
  if enabled then for _,object in character:GetDescendants() do mute(record,object) end end
 end
 table.insert(record.connections,character:GetAttributeChangedSignal("TungSahurActive"):Connect(refresh))
 table.insert(record.connections,character.DescendantAdded:Connect(function(object) if record.enabled then mute(record,object) end end))
 table.insert(record.connections,character:GetAttributeChangedSignal("TungAirJumpSerial"):Connect(function()
  if record.enabled and (character:GetAttribute("TungAirJumpSerial") or 0)>0 then cue(record,"AirJump") end
 end))
 table.insert(record.connections,character.AncestryChanged:Connect(function() if not character.Parent then remove(character) end end))
 refresh()
end
local function playerAdded(player)
 table.insert(connections,player.CharacterAdded:Connect(attach))
 table.insert(connections,player.CharacterRemoving:Connect(remove))
 if player.Character then attach(player.Character) end
end
for _,player in Players:GetPlayers() do playerAdded(player) end
table.insert(connections,Players.PlayerAdded:Connect(playerAdded))
table.insert(connections,RunService.Heartbeat:Connect(function()
 for character,record in records do
  local root=character:FindFirstChild("HumanoidRootPart")
  local humanoid=character:FindFirstChildOfClass("Humanoid")
  if not record.enabled or not root or not humanoid or humanoid.Health<=0 then record.lastPosition=nil;continue end
  local now=os.clock();local position=root.Position;local velocity=root.AssemblyLinearVelocity
  local isLocal=character==Players.LocalPlayer.Character
  local recentHit=workspace:GetServerTimeNow()-(character:GetAttribute("CombatHitAt") or -math.huge)<.35
  local grounded=humanoid.FloorMaterial~=Enum.Material.Air
  -- FloorMaterial is local-only for other players; confirm their support surface.
  if not grounded and not isLocal and velocity.Y<5 then
   local excluded={folder};for _,player in Players:GetPlayers() do if player.Character then table.insert(excluded,player.Character) end end
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=excluded;params.RespectCanCollide=true
   local floor=workspace:Raycast(position,-Vector3.yAxis*(humanoid.HipHeight+root.Size.Y*.5+.8),params)
   grounded=floor~=nil and floor.Normal.Y>.45
  end
  if record.grounded~=nil and record.grounded and not grounded then
   record.airAt=now
   if velocity.Y>10 and not recentHit and not character:GetAttribute("AbilityMotionMode") then cue(record,"Jump") end
  elseif grounded and record.grounded==false and record.airAt and now-record.airAt>.15 and now-record.lastLand>.2 then
   cue(record,"Land",math.clamp((record.fallSpeed or 0)/50,.5,1.3));record.lastLand=now;record.airAt=nil;record.fallSpeed=0
  end
  if not grounded then record.fallSpeed=math.max(record.fallSpeed or 0,-velocity.Y) end
  local delta=record.lastPosition and position-record.lastPosition or Vector3.zero
  local traveled=Vector3.new(delta.X,0,delta.Z).Magnitude
  local mode=character:GetAttribute("AbilityMotionMode")
  local moving=isLocal and humanoid.MoveDirection.Magnitude>.05 or not isLocal and Vector3.new(velocity.X,0,velocity.Z).Magnitude>3
  if grounded and moving and traveled<5 and not mode and not recentHit then
   record.distance+=traveled
   local stride=character:GetAttribute("FighterId")=="bombardiro" and 6.5 or 5.2
   if record.distance>=stride then record.distance%=stride;cue(record,"Step") end
  else record.distance=0 end
  record.grounded=grounded;record.lastPosition=position
 end
end))
script.Destroying:Connect(function()
 for character in records do remove(character) end
 for _,connection in connections do connection:Disconnect() end
 folder:Destroy()
end)
