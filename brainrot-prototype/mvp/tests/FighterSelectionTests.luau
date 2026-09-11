return function()
 local package=game.ReplicatedStorage.TungPrototype
 local rules=require(package.FighterSelectionRules)
 local roster=require(package.FighterDefinitions)
 local n=0
 for _,f in roster.List do if f.MVP then assert(rules.ValidateId(roster,f.Id)==f);n+=1 end end
 assert(n==5,"Exactly five MVP fighters")
 for _,id in {false,123,{},"unknown",string.rep("a",33)} do assert(not rules.ValidateId(roster,id),"Reject malformed/unavailable id") end
 local c=Instance.new("Model");local h=Instance.new("Humanoid",c)
 local root=Instance.new("Part",c);root.Name="HumanoidRootPart"
 local phase=nil;local ground=true
 local world={GetAttribute=function() return phase end,Raycast=function() return ground and {Normal=Vector3.yAxis} or nil end}
 local function allowed() return rules.CanSwitch(c,world,100) end
 assert(allowed());root.Anchored=true;assert(not allowed());root.Anchored=false
 c:SetAttribute("CombatDisabled",true);assert(not allowed());c:SetAttribute("CombatDisabled",nil)
 phase="Active";assert(not allowed());phase="Practice"
 assert(allowed());ground=false;assert(not allowed());ground=true
 for _,key in {"CooldownM1","CooldownQ","CooldownE","CooldownR","CooldownF","CombatBusyUntil","StunnedUntil"} do
  c:SetAttribute(key,101);assert(not allowed(),key);c:SetAttribute(key,nil)
 end
 c:SetAttribute("LastCombatAt",96);assert(not allowed());c:SetAttribute("LastCombatAt",94);assert(allowed())
 h.Sit=true;assert(not allowed());h.Sit=false
 h.Health=0;assert(not allowed());c:Destroy()
 assert(not rules.CanSwitch(nil,world,100))
 return "PASS: five ids, malformed ids, phase, grounded, all cooldowns, stun, combat timeout, sitting, death."
end
