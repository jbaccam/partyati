-- Server-owned anchored door motion; no physics solver or external assets required.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Runtime = { controllers = {} }
local bound = setmetatable({}, {__mode = "k"})

function Runtime.bind(house)
 if bound[house] then return bound[house] end
 local states = {}
 bound[house] = states
 for _,prompt in ipairs(house:GetDescendants()) do
  if not prompt:IsA("ProximityPrompt") then continue end
  local trigger = prompt.Parent
  local door = trigger and trigger.Parent
  if not trigger:IsA("BasePart") or not door:IsA("Model") then continue end
  local groups = {}
  for _,hinge in ipairs(door:GetChildren()) do
   if not hinge:IsA("BasePart") or not hinge.Name:match("^Hinge%d*$") then continue end
   local open = hinge:FindFirstChild("OpenPosition")
   local closed = hinge:FindFirstChild("ClosePosition")
   if not open or not closed or not open:IsA("BasePart") or not closed:IsA("BasePart") then continue end
   local parts, offsets, seen = {hinge}, {CFrame.identity}, {[hinge]=true}
   for _,joint in ipairs(hinge:GetChildren()) do
    if joint:IsA("Weld") then
     local part = joint.Part0 == hinge and joint.Part1 or joint.Part1 == hinge and joint.Part0
     if part and part ~= trigger and part:IsDescendantOf(door) and not seen[part] then
      seen[part] = true
      table.insert(parts, part)
      table.insert(offsets, hinge.CFrame:ToObjectSpace(part.CFrame))
     end
    end
   end
   for _,part in ipairs(parts) do part.Anchored = true end
   for _,marker in ipairs({open,closed,hinge}) do
    marker.Transparency=1 marker.CanCollide=false marker.CanTouch=false marker.CanQuery=false
   end
   table.insert(groups,{hinge=hinge,open=open.CFrame,closed=closed.CFrame,parts=parts,offsets=offsets})
  end
  if #groups==0 then continue end
  local state={door=door,prompt=prompt,groups=groups,opened=false,moving=false}
  local function move(alpha, starts, opening)
   local parts, frames = {}, {}
   for i,g in ipairs(groups) do
    local cf = starts[i]:Lerp(opening and g.open or g.closed,alpha)
    for j,part in ipairs(g.parts) do
     if part.Parent then table.insert(parts,part) table.insert(frames,cf*g.offsets[j]) end
    end
   end
   if #parts>0 then workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged) end
  end
  local starts={} for i,g in ipairs(groups) do starts[i]=g.hinge.CFrame end
  move(1,starts,false)
  prompt.ActionText="Open" prompt.ObjectText="Door" prompt.HoldDuration=0
  prompt.MaxActivationDistance=8 prompt.RequiresLineOfSight=false
  trigger.CanCollide=false trigger.CanTouch=false trigger.Transparency=1
  door:SetAttribute("DoorOpen",false)
  door:SetAttribute("DoorBusy",false)
  function state.toggle(player)
   if state.moving or not prompt.Enabled or not door:IsDescendantOf(workspace) then return false end
   if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false end
   local character=player.Character
   local root=character and character:FindFirstChild("HumanoidRootPart")
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not root or not humanoid or humanoid.Health<=0 or (root.Position-trigger.Position).Magnitude>prompt.MaxActivationDistance+1 then return false end
   if door:GetAttribute("Locked")==true or house:GetAttribute("Locked")==true then return false end
   local owner=door:GetAttribute("OwnerUserId")
   if type(owner)=="number" and owner>0 and owner~=player.UserId then return false end
   state.moving=true door:SetAttribute("DoorBusy",true)
   local opening=not state.opened
   local from={} for i,g in ipairs(groups) do from[i]=g.hinge.CFrame end
   task.spawn(function()
    local elapsed=0
    repeat
     elapsed+=RunService.Heartbeat:Wait()
     if not door:IsDescendantOf(workspace) then state.moving=false return end
     local t=math.min(elapsed/.55,1)
     move(t*t*(3-2*t),from,opening)
    until elapsed>=.55
    state.opened=opening state.moving=false
    door:SetAttribute("DoorOpen",opening) door:SetAttribute("DoorBusy",false)
    prompt.ActionText=opening and "Close" or "Open"
   end)
   return true
  end
  prompt.Triggered:Connect(state.toggle)
  table.insert(states,state)
  table.insert(Runtime.controllers,state)
 end
 return states
end
return Runtime
