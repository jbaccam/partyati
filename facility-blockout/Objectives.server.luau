-- Server-owned cooperative objective prototype. No persistent rewards or DataStores.
-- Sabotage integrates through a server-only bindable; it does not assign the Initiator role.
local root=workspace:WaitForChild("FacilityLayoutReview")
local rooms=root:WaitForChild("RoomInteriors");while not rooms:GetAttribute("Ready") do task.wait() end
while not root:GetAttribute("ProductionDressed") do task.wait() end
while not root:GetAttribute("ProductionPolished") do task.wait() end
while not root:GetAttribute("MapFinishReady") do task.wait() end
while not root:GetAttribute("ReadabilityReady") do task.wait() end
local Players=game:GetService("Players");local Run=game:GetService("RunService");local V=Vector3.new
local descriptions={StorageKey="Storage key",Cutters="Bolt cutters",Screwdriver="Screwdriver",Badge="Staff badge",Fuse="Fuse",Valve="Pump valve",RadioPart="Radio relay",Battery="Battery",Wire="Insulated wire"}
local labels={StorageLock={"Unlock","Stores / storage key"},EmergencyPhone={"Use phone","Emergency dispatch"},CommunicationsPanel={"Repair","Communications relay"},DrainPump={"Repair","Drainage pump"},WellGrate={"Open","Courtyard drainage well"},BathroomManhole={"Open","Maintenance manhole"},StaffVent={"Unscrew","Staff service vent"},StaffVentReturn={"Return","Staff service vent"},FrontExit={"Release","Chained front entrance"},StaffExit={"Unlock","Staff emergency exit"},MaintenanceTunnelExit={"Escape","Maintenance outfall"},WellDrainExit={"Escape","Courtyard outfall"}}
for _,l in root:GetDescendants() do if l:IsA("Light") then l.Shadows=true end end
for _,p in rooms:GetDescendants() do if p:IsA("ProximityPrompt") then
 local a=p.Parent;local kind,id=a:GetAttribute("InteractionKind"),a:GetAttribute("ObjectiveId")
 if labels[id] then p.ActionText=labels[id][1];p.ObjectText=labels[id][2] end
 if kind=="Generator" then p.ActionText="Repair generator";p.HoldDuration=3 end
 if kind=="Hide" then p.ActionText="Hide / leave";p.ObjectText="Under bed" end
end end
if not Run:IsRunning() then return end
local folder=Instance.new("Folder");folder.Name="FacilityObjectives";folder.Parent=game.ReplicatedStorage
local update=Instance.new("RemoteEvent");update.Name="Update";update.Parent=folder
local state=Instance.new("Folder");state.Name="ObjectiveState";state.Parent=root
local inventories,searched,busy,hidden,last={}, {}, {}, {}, {}
local progress={stores=false,chains=false,pump=false,manhole=false,well=false,vent=false,comms=false,phone=false,police=false}
local powered={true,true,true,true,true,true};local generatorModels={}
for i=1,6 do generatorModels[i]=rooms.GeneratorHall:WaitForChild("Generator_"..i) end
local function inventory(player) inventories[player]=inventories[player] or {};return inventories[player] end
local function tell(player,message)
 local list={};for id,n in inventory(player) do if n>0 then table.insert(list,(descriptions[id] or id)..(n>1 and " ×"..n or "")) end end;table.sort(list)
 update:FireClient(player,{message=message,items=list,escaped=player:GetAttribute("FacilityEscaped")==true})
end
local function all(message) for _,p in Players:GetPlayers() do tell(p,message) end end
local function has(p,id) return (inventory(p)[id] or 0)>0 end
local function take(p,id) if not has(p,id) then return false end;inventory(p)[id]-=1;return true end
local function need(p,id) if has(p,id) then return true end;tell(p,"Requires "..(descriptions[id] or id)..".");return false end
local function alive(p)
 local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
 if h and r and h.Health>0 and not p:GetAttribute("FacilityEscaped") then return c,h,r end
end
local function valid(p,a)
 local c,h,r=alive(p);if not c or hidden[p] then return false end
 if (r.Position-a.Position).Magnitude>9 then return false end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={c,a.Parent};rp.IgnoreWater=true
 local hit=workspace:Raycast(r.Position,a.Position-r.Position,rp)
 return not hit or (hit.Position-a.Position).Magnitude<.8
end
local zoneSector={MainNorthWest=1,MainNorthEast=3,MainSouthWest=4,MainSouthEast=2,BasementNorth=6,BasementSouth=6,BasementWest=5,BasementEast=6,WestStairs=6,EastStairs=6}
local function sectorOf(p)
 local q=p;while q and q~=root do local s=q:GetAttribute("PowerSector");if s then return s end;q=q.Parent end
 if p:IsDescendantOf(root.LibraryArt) then return 3 end
 if p:GetFullName():find("Washroom") then return 5 end
 return nil
end
local standalone={}
for _,l in root:GetDescendants() do if l:IsA("Light") and not l:IsDescendantOf(root.Hallways) then
 local s=sectorOf(l);if s then standalone[#standalone+1]={light=l,sector=s,brightness=l.Brightness,part=l.Parent,flicker=l.Parent:GetAttribute("Flickers")==true,nextDip=os.clock()+math.random(18,40),dipEnd=0} end
end end
local function setPower(i,on)
 powered[i]=on;generatorModels[i]:SetAttribute("Powered",on);state:SetAttribute("Sector"..i,on)
 for _,z in root.Hallways.PowerZones:GetChildren() do if zoneSector[z.Name]==i then z:SetAttribute("Powered",on) end end
 local w=root:FindFirstChild("WashroomRefinement");if i==5 and w and w:FindFirstChild("PowerZones") then for _,z in w.PowerZones:GetChildren() do z:SetAttribute("Powered",on) end end
 for _,p in generatorModels[i]:GetDescendants() do if p:GetAttribute("GeneratorStatus") then p.Color=on and Color3.fromRGB(111,164,97) or Color3.fromRGB(147,72,47);p.Material=on and Enum.Material.Neon or Enum.Material.SmoothPlastic end end
end
for i=1,6 do setPower(i,true) end
task.spawn(function() while root.Parent do
 local now=os.clock();for _,e in standalone do local on=powered[e.sector]
  if e.flicker and now>=e.nextDip then e.nextDip=now+math.random(22,48);e.dipEnd=now+.24 end
  e.light.Enabled=on;e.light.Brightness=e.brightness*(now<e.dipEnd and .22 or 1)
  if e.part:IsA("BasePart") and (e.part.Name=="Diffuser" or e.part.Name=="WarmBulb") then e.part.Material=on and now>=e.dipEnd and Enum.Material.Neon or Enum.Material.SmoothPlastic end
 end;task.wait(.15)
end end)
local sabotage=Instance.new("BindableFunction");sabotage.Name="FacilitySabotageSector";sabotage.Parent=game.ServerStorage
local charges,cooldown={},{}
sabotage.OnInvoke=function(p,i)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players or typeof(i)~="number" or i%1~=0 or i<1 or i>6 then return false,"Invalid request" end
 if p:GetAttribute("FacilityRole")~="Initiator" or not alive(p) then return false,"Initiator role required" end
 local now=os.clock();if now<(cooldown[p] or 0) or (charges[p] or 0)>=3 then return false,"Sabotage unavailable" end
 local panel=generatorModels[i]:FindFirstChild("Interaction_Generator_"..i,true)
 if not panel or not valid(p,panel) or not powered[i] then return false,"Must reach an active generator" end
 charges[p]=(charges[p] or 0)+1;cooldown[p]=now+45;setPower(i,false)
 state:SetAttribute("LastSabotageSector",i);state:SetAttribute("LastSabotageTime",workspace:GetServerTimeNow());all("Power failure: generator G0"..i.." needs repair.");return true
end
local function openNamed(parent,name)
 for _,p in parent:GetDescendants() do if p:IsA("BasePart") and p.Name==name then p.CanCollide=false;p.Transparency=1 end end
end
local function escape(p,id)
 local c,h,r=alive(p);if not c then return end;p:SetAttribute("FacilityEscaped",true);p:SetAttribute("FacilityEscapeRoute",id);p:SetAttribute("FacilityHidden",false)
 c:PivotTo(CFrame.new(-8,4,287));h.WalkSpeed=16;all(p.DisplayName.." escaped via "..id..".");tell(p,"Escaped — "..id..". No rewards are awarded in this prototype.")
end
local function move(p,pos) local c,h,r=alive(p);if c then r.AssemblyLinearVelocity=V.zero;c:PivotTo(CFrame.new(pos)) end end
local function route(p,id)
 if id=="StorageLock" then
  if not progress.stores then if not need(p,"StorageKey") then return end;take(p,"StorageKey");progress.stores=true;openNamed(rooms.Storage,"LockedStorageDoor");all("Stores unlocked. Bolt cutters are on the labelled hook board on the first rack.") else tell(p,"Stores are unlocked.") end
 elseif id=="FrontExit" then
  if not progress.stores then tell(p,"Front route 1/3: find the storage key in administration and unlock stores.");return end
  if not progress.chains then if not need(p,"Cutters") then return end;progress.chains=true;openNamed(rooms.EscapeRoutes.FrontExit,"SecurityChain");all("Front route 2/3: chains cut. Release the powered security latch.");return end
  if not powered[2] then tell(p,"Restore generator G02 to release the entrance latch.");return end
  openNamed(rooms.EscapeRoutes.FrontExit,"ExitLeaf");escape(p,"front entrance")
 elseif id=="DrainPump" then
  if not powered[5] then tell(p,"Restore generator G05 first.");return end
  if not progress.pump then if not need(p,"Valve") then return end;take(p,"Valve");progress.pump=true;all("Drainage restored. The maintenance and courtyard outfalls are passable.") else tell(p,"Drainage is already restored.") end
 elseif id=="BathroomManhole" then
  if not progress.pump or not powered[5] then tell(p,"Maintenance route 1/3: replace the pump valve and restore G05.");return end
  if not progress.manhole then if not need(p,"Cutters") then return end;progress.manhole=true;openNamed(rooms.BathroomUtilityDetails,"MaintenanceManhole");tell(p,"Maintenance route 2/3: hatch released. Follow the tunnel to its outfall.") end
  move(p,V(-164,-48,255))
 elseif id=="MaintenanceTunnelExit" then if progress.pump and progress.manhole then escape(p,"maintenance outfall") end
 elseif id=="WellGrate" then
  if not progress.well then if not need(p,"Cutters") then return end;progress.well=true;openNamed(rooms.Courtyard.DrainageWell,"WellGrate");tell(p,"Courtyard route 1/3: grate released. Restore the basement drainage pump.");return end
  if not progress.pump or not powered[5] then tell(p,"Courtyard route 2/3: the drain must be pumped before entering.");return end
  move(p,V(-24,-48,255));tell(p,"Courtyard route 3/3: reach the drainage outfall.")
 elseif id=="WellDrainExit" then if progress.well and progress.pump then escape(p,"courtyard drain") end
 elseif id=="StaffVent" then
  if not progress.vent then if not need(p,"Screwdriver") then return end;progress.vent=true;openNamed(rooms.Administration,"StaffVentPanel") end
  move(p,V(33,4,-230));tell(p,"Staff route 1/3: vent opened. Take the visible badge from the labelled staff-cabinet hook.")
 elseif id=="StaffVentReturn" then if progress.vent then move(p,V(17,4,-230)) end
 elseif id=="StaffExit" then
  if not progress.vent then tell(p,"Staff route 1/3: open the administration service vent with a screwdriver.");return end
  if not need(p,"Badge") then return end;openNamed(rooms.EscapeRoutes.StaffExit,"ExitLeaf");escape(p,"staff emergency exit")
 elseif id=="CommunicationsPanel" then
  if progress.comms then tell(p,"Communications relay is repaired.");return end
  if not powered[2] then tell(p,"Restore generator G02 first.");return end
  if not need(p,"RadioPart") then return end;take(p,"RadioPart");progress.comms=true;all("Police route 1/3: communications restored. Call from reception.")
 elseif id=="EmergencyPhone" then
  if not progress.comms or not powered[2] then tell(p,"Police route 1/3: repair the security communications relay and restore G02.");return end
  if progress.police then escape(p,"police rescue");return end
  if progress.phone then tell(p,"Police are responding. Hold out near reception.");return end
  progress.phone=true;state:SetAttribute("AlarmActive",true);state:SetAttribute("PoliceHoldoutActive",true);state:SetAttribute("PoliceHoldoutRemaining",90)
  all("Police route 2/3: call sent. Hold out for 90 powered seconds, then return to the phone.")
  task.spawn(function()
   local remaining=90;while remaining>0 and root.Parent do task.wait(1);if powered[2] then remaining-=1 end;state:SetAttribute("PoliceHoldoutRemaining",remaining) end
   progress.police=true;state:SetAttribute("PoliceHoldoutActive",false);all("Police route 3/3: rescue has arrived. Regroup at the reception phone.")
  end)
 end
 for key,value in progress do state:SetAttribute(key,value) end
end
local function leaveHide(p)
 local e=hidden[p];if not e then return end;hidden[p]=nil;p:SetAttribute("FacilityHidden",false)
 local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
 if r then r.Anchored=false end;if h then h.WalkSpeed=16;h.AutoRotate=true end
 if c then c:PivotTo(CFrame.new(e.exit)) end;tell(p,"Left hiding spot.")
end
local function interact(p,a)
 local kind,id=a:GetAttribute("InteractionKind"),a:GetAttribute("ObjectiveId")
 if kind=="Hide" and hidden[p] then if hidden[p].node==a then leaveHide(p) end;return end
 if not valid(p,a) then return end
 if kind=="Search" then
  if a:IsDescendantOf(rooms.Storage) and not progress.stores then tell(p,"Unlock stores first.");return end
  local item=a:GetAttribute("ItemId")
  if item=="Badge" and not progress.vent then tell(p,"Open the staff service vent first.");return end
  searched[p]=searched[p] or {};if searched[p][a] then tell(p,"You have already collected this supply.");return end
  local inv=inventory(p);local total=0;for _,n in inv do total+=n end
  if item and total>=12 then tell(p,"Supply capacity reached (12). Use a component before collecting more.");return end
  searched[p][a]=true
  if item then inv[item]=(inv[item] or 0)+1;tell(p,"Found "..descriptions[item]..(item=="Badge" and ". Staff route 2/3 complete." or ".")) else tell(p,"Only old supplies and paperwork here.") end
 elseif kind=="Generator" then
  local i=a:GetAttribute("GeneratorId");if powered[i] then tell(p,"G0"..i.." is running.");return end
  -- Basic restoration is always possible; scarce tools must not permanently soft-lock power.
  setPower(i,true);all("G0"..i.." repaired. Its rooms have power again.")
 elseif kind=="Route" then route(p,id)
 elseif kind=="Hide" then
  local c,h,r=alive(p);if not c then return end
  hidden[p]={node=a,exit=a:GetAttribute("ExitPosition")};p:SetAttribute("FacilityHidden",true)
  h.WalkSpeed=0;h.AutoRotate=false;c:PivotTo(CFrame.new(a:GetAttribute("HidePosition"))*CFrame.Angles(0,0,math.pi/2));r.Anchored=true;tell(p,"Hiding under the bed. Interact again to leave; enemies still need their AI integration.")
 end
end
for _,q in rooms:GetDescendants() do if q:IsA("ProximityPrompt") then
 local a=q.Parent;local held={}
 q.PromptButtonHoldBegan:Connect(function(p) if valid(p,a) or hidden[p] and hidden[p].node==a then held[p]={time=os.clock(),position=p.Character.HumanoidRootPart.Position} end end)
 q.Triggered:Connect(function(p)
  local now=os.clock();if busy[p] or now-(last[p] or 0)<.25 then return end
  local h=held[p];held[p]=nil
  if q.HoldDuration>0 and (not h or now-h.time<q.HoldDuration-.15) then return end
  if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then return end
  if h and (p.Character.HumanoidRootPart.Position-h.position).Magnitude>5 then return end
  busy[p]=true;last[p]=now;local ok,err=pcall(interact,p,a);busy[p]=nil;if not ok then warn("Facility objective: "..tostring(err)) end
 end)
end end
local function attach(p)
 p:SetAttribute("FacilityEscaped",false);p:SetAttribute("FacilityHidden",false)
 p.CharacterAdded:Connect(function(c) hidden[p]=nil;p:SetAttribute("FacilityHidden",false);p:SetAttribute("FacilityEscaped",false);local h=c:WaitForChild("Humanoid");h.Died:Connect(function() hidden[p]=nil;p:SetAttribute("FacilityHidden",false) end);task.delay(2,function() if p.Parent then tell(p,"Supplies are visible at fixed, labelled stations. Check reception's supply directory; ordinary trays and beds do not need searching.") end end) end)
end
Players.PlayerAdded:Connect(attach);for _,p in Players:GetPlayers() do attach(p) end
Players.PlayerRemoving:Connect(function(p) inventories[p]=nil;searched[p]=nil;hidden[p]=nil;last[p]=nil;busy[p]=nil;charges[p]=nil;cooldown[p]=nil end)
