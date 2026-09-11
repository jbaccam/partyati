-- Run as a ModuleScript in Studio; covers geometry dispatch and bounded cleanup.
return function()
 local Effects=require(game.ReplicatedStorage.TungPrototype.CombatEffects)
 local fx=Effects.new()
 local character=Instance.new("Model");character.Name="EffectTestFighter";character.Parent=workspace
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true;root.CanCollide=false;root.Parent=character
 local humanoid=Instance.new("Humanoid");humanoid.Parent=character
 local function count(name)
  local n=0;for _,p in fx.folder:GetDescendants() do if p.Name==name then n+=1 end end;return n
 end
 local ok,err=pcall(function()
  local args={source=character,aim=Vector3.new(0,0,-1),combo=1}
  args.fighterId="tralalero";fx:Handle("FighterStrike",Vector3.zero,args)
  assert(count("JawSnap")==18 and count("StrikeArc")==0,"Shark must bite, not display generic fist arc")
  args.fighterId="ballerina";fx:Handle("FighterStrike",Vector3.zero,args)
  assert(count("ShoeSweep")==14,"Ballerina must show low kicking arc")
  args.fighterId="chimpanzini";fx:Handle("FighterStrike",Vector3.zero,args)
  assert(count("BananaLash")==12,"Chimp must show curved banana lash")
  args.fighterId="bombardiro";fx:Handle("FighterStrike",Vector3.zero,args)
  assert(count("JawSnap")==36,"Croc must have a distinct broad jaw snap")
  fx:Handle("TailSweep",Vector3.zero,args)
  assert(count("TailLiftFin")==3,"Tail launcher lift direction must be legible")
  for _,mode in {"Torpedo","Porpoise","PeelGlide","PoweredFlight","AirStep"} do
   fx:Handle("MoveBurst",Vector3.zero,{source=character,mode=mode,duration=1,at=workspace:GetServerTimeNow()})
   assert(#fx.moves==1,"Only one movement wake per source")
  end
  fx:Step()
  for _,p in fx.folder:GetDescendants() do
   if p:IsA("BasePart") then assert(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch,"FX must never affect physics/hitboxes") end
  end
  fx.moves[1].at=workspace:GetServerTimeNow()-5;fx:Step()
  assert(#fx.moves==0,"Movement wake expires without animation/action changes")
  character:SetAttribute("AbilityMotionMode","Flight");character:SetAttribute("AbilityMotionUntil",workspace:GetServerTimeNow()+1)
  fx:Handle("MoveBurst",Vector3.zero,{source=character,mode="Flight",duration=1,at=workspace:GetServerTimeNow()})
  fx:Step();character:SetAttribute("AbilityMotionMode",nil);fx:Step()
  assert(#fx.moves==0,"Server cancellation must stop movement wake early")
  fx:Handle("MoveBurst",Vector3.zero,{source=character,mode="Flight",duration=1,at=workspace:GetServerTimeNow()})
  humanoid.Health=0;fx:Step();assert(#fx.moves==0,"Dead fighter cannot leave active movement wake")
 end)
 character:Destroy();fx.folder:Destroy()
 assert(ok,err)
 return "Distinct fighter FX dispatch, cosmetic-only parts, duration and death cleanup passed"
end
