-- Selection is an out-of-combat action, never a heal/cooldown/air-recovery escape.
local Selection={}
function Selection.ValidateId(roster,id)
 if typeof(id)~="string" or #id>32 then return nil end
 local fighter=roster.ById[id]
 return fighter and fighter.MVP==true and fighter or nil
end
function Selection.CanSwitch(character,world,now)
 local h=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not h or not root or h.Health<=0 then return false,"Wait until you respawn" end
 if root.Anchored or character:GetAttribute("CombatDisabled")==true then return false,"Wait until you can move again" end
 if world:GetAttribute("CombatPhase")=="Active" then return false,"Choose fighters between rounds" end
 if h.Sit or h.PlatformStand then return false,"Stand up before switching" end
 if (character:GetAttribute("CombatBusyUntil") or 0)>now or (character:GetAttribute("StunnedUntil") or 0)>now then
  return false,"Finish your current move first"
 end
 if now-(character:GetAttribute("LastCombatAt") or -math.huge)<5 then return false,"Leave combat for 5 seconds first" end
 for _,key in {"M1","Q","E","R","F"} do
  if (character:GetAttribute("Cooldown"..key) or 0)>now then return false,"Wait for your moves to recharge" end
 end
 local distance=h.HipHeight+root.Size.Y*.5
 if h.RigType==Enum.HumanoidRigType.R6 then local leg=character:FindFirstChild("Left Leg");distance+=leg and leg.Size.Y or 2 end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={character};params.RespectCanCollide=true
 local hit=world:Raycast(root.Position,Vector3.new(0,-distance-.5,0),params)
 if not hit or hit.Normal.Y<.45 or math.abs(root.AssemblyLinearVelocity.Y)>8 then return false,"Land before switching fighters" end
 return true
end
return Selection
